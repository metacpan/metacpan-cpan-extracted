#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

typedef struct {
    AV  *grid;
    int rows;
    int columns;
    int dirty;
} grid_t;

typedef grid_t *Grid__Transform;

/* The dimensions or array may be changed by the user at any time, so this
   must alway be called before making use of the grid's array to ensure it is
   rectangular. */
#define FIX_DIRTY_GRID(g)                                                      \
    if ((g)->dirty) {                                                          \
        IV len = av_len((g)->grid);                                            \
        IV add = (g)->rows * (g)->columns - len - 1;                           \
        av_fill((g)->grid, len + add);                                         \
        if (add > 0) {                                                         \
            IV i;                                                              \
            /* Find position after last extra element. */                      \
            /* TODO: binary search? */                                         \
            for (i=0; i<add; i++) {                                            \
                if (! av_exists((g)->grid, len + 1 + i)) break;                \
            }                                                                  \
            for (; i<add; i++) {                                               \
                AvARRAY((g)->grid)[len + 1 + i] = newSVpvn("", 0);             \
            }                                                                  \
        }                                                                      \
       (g)->dirty = 0;                                                         \
    }

#define SWAP(type,a,b)                                                         \
    STMT_START {                                                               \
        type tmp = (a);                                                        \
        (a) = (b);                                                             \
        (b) = tmp;                                                             \
    } STMT_END

#define REVERSE_AV(av)                                                         \
    STMT_START {                                                               \
        SV **s = AvARRAY((av));                                                \
        SV **e = s + av_len((av));                                             \
        while (s < e) {                                                        \
            SV *tmp = *s;                                                      \
            *s++ = *e;                                                         \
            *e-- = tmp;                                                        \
        }                                                                      \
  } STMT_END

MODULE = Grid::Transform  PACKAGE = Grid::Transform

Grid::Transform
new (class, aref, ...)
    char *class
    SV *aref
PROTOTYPE: $\@$$;$$
PREINIT:
    AV *av;
    grid_t *self;
    IV i, len, add = 0;
CODE:
    av = (AV *)SvRV(aref);
    if (! (SvRV(aref) && SvTYPE(SvRV(aref)) == SVt_PVAV)) {
        croak ("reference to an array expected");
    }

    New(0, self, 1, grid_t);

    self->rows = 0;
    self->columns = 0;
    self->dirty = 0;

    for (i=2; i<items; i+=2) {
        char *key = SvPV(ST(i), PL_na);
        if (strEQ(key, "rows")) {
            self->rows = SvIV(ST(i+1));
        }
        else if (strEQ(key, "columns")) {
            self->columns = SvIV(ST(i+1));
        }
        else {
            croak("unknown key in parameter list: %s", key);
        }
    }

    len = av_len(av);

    if (! self->rows && ! self->columns) {
        croak("no \"rows\" or \"columns\"");
    }
    /* Determine missing dimension. */
    else if (! self->rows) {
        self->rows = (len+1) / self->columns + ((len+1) % self->columns ? 1 : 0);
    }
    else if (! self->columns) {
        self->columns = (len+1) / self->rows + ((len+1) % self->rows ? 1 : 0);
    }
    /* Add or remove extra elements to ensure a rectangular grid. */
    add = self->rows * self->columns - len - 1;

    self->grid = newAV();
    /* add may be negative, so ensure it does't decrease the size of the
       original array. */
    av_fill(self->grid, len + (add > 0 ? add : 0));

    /* Copy original array. */
    for (i=0; i<=len; i++) {
        AvARRAY(self->grid)[i] = newSVsv(AvARRAY(av)[i]);
    }
    /* Add extra empty elements. */
    for (i=add+len; i>len; i--) {
        AvARRAY(self->grid)[i] = newSVpvn("", 0);
    }
    RETVAL = self;
OUTPUT:
    RETVAL

Grid::Transform
copy (self)
    Grid::Transform self
PROTOTYPE: $
PREINIT:
    grid_t *copy;
CODE:
    New(0, copy, 1, grid_t);
    copy->grid = av_make(av_len(self->grid)+1, AvARRAY(self->grid));
    copy->rows = self->rows;
    copy->columns = self->columns;
    copy->dirty = self->dirty;
    RETVAL = copy;
OUTPUT:
    RETVAL

IV
rows (self, rows=0)
    Grid::Transform self
    IV rows
PROTOTYPE: $;$
CODE:
    if (items == 2) {
        self->rows = rows;
        self->dirty = 1;
    }
    RETVAL = self->rows;
OUTPUT:
    RETVAL

IV
columns (self, columns=0)
    Grid::Transform self
    IV columns
PROTOTYPE: $;$
ALIAS:
    cols = 1
CODE:
    if (items == 2) {
        self->columns = columns;
        self->dirty = 1;
    }
    RETVAL = self->columns;
OUTPUT:
    RETVAL

void
grid (self, aref=0)
    Grid::Transform self
    SV *aref
PROTOTYPE: $;\@
PPCODE:
    if (items == 2) {
        AV *av = (AV *)SvRV(aref);
        if (! (SvRV(aref) && SvTYPE(SvRV(aref)) == SVt_PVAV)) {
            croak ("reference to an array expected");
        }

        SvREFCNT_dec(self->grid);
        self->grid = av_make(av_len(av)+1, AvARRAY(av));
        self->dirty = 1;
    }
    if (GIMME_V != G_VOID) {
        FIX_DIRTY_GRID(self);
        if (GIMME_V == G_ARRAY) {
            IV i, len = av_len(self->grid);
            EXTEND(SP, len + 1);
            for (i=0; i<=len; i++) {
                PUSHs(sv_2mortal(SvREFCNT_inc(AvARRAY(self->grid)[i])));
            }
        }
        else {
            PUSHs(sv_2mortal(newRV_inc((SV *)self->grid)));
        }
    }

void
rotate_180 (self)
    Grid::Transform self
PROTOTYPE: $
ALIAS:
    rotate180 = 1
PPCODE:
    FIX_DIRTY_GRID(self);
    REVERSE_AV(self->grid);
    XSRETURN(1);

void
rotate_90 (self)
    Grid::Transform self
PROTOTYPE: $
ALIAS:
    rotate90 = 1
PREINIT:
    SV **tmp;
    IV n, i, row, col;
PPCODE:
    FIX_DIRTY_GRID(self);
    n = self->rows * self->columns;
    New(0, tmp, n, SV*);
    for (i=0, col=0; col<self->columns; col++) {
        for (row=self->rows-1; row>=0; row--, i++) {
            tmp[i] = AvARRAY(self->grid)[col + row * self->columns];
        }
    }
    for (i=0; i<n; i++) {
        AvARRAY(self->grid)[i] = tmp[i];
    }
    Safefree(tmp);
    SWAP(IV, self->rows, self->columns);
    XSRETURN(1);

void
rotate_270 (self)
    Grid::Transform self
PROTOTYPE: $
ALIAS:
    rotate270 = 1
PREINIT:
    SV **tmp;
    IV n, i, row, col;
PPCODE:
    FIX_DIRTY_GRID(self);
    n = self->rows * self->columns;
    New(0, tmp, n, SV*);
    for (i=0, col=self->columns-1; col>=0; col--) {
        for (row=0; row<self->rows; row++, i++) {
            tmp[i] = AvARRAY(self->grid)[col + row * self->columns];
        }
    }
    for (i=0; i<n; i++) {
        AvARRAY(self->grid)[i] = tmp[i];
    }
    Safefree(tmp);
    SWAP(IV, self->rows, self->columns);
    XSRETURN(1);

void
transpose (self)
    Grid::Transform self
PROTOTYPE: $
PREINIT:
    SV **tmp;
    IV n, i, row, col;
PPCODE:
    FIX_DIRTY_GRID(self);
    n = self->rows * self->columns;
    New(0, tmp, n, SV*);
    for (i=0, col=self->columns-1; col>=0; col--) {
        for (row=self->rows-1; row>=0; row--, i++) {
            tmp[i] = AvARRAY(self->grid)[col + row * self->columns];
        }
    }
    for (i=0; i<n; i++) {
        AvARRAY(self->grid)[i] = tmp[i];
    }
    Safefree(tmp);
    SWAP(IV, self->rows, self->columns);
    XSRETURN(1);

void
counter_transpose (self)
    Grid::Transform self
PROTOTYPE: $
ALIAS:
    countertranspose = 1
PREINIT:
    SV **tmp;
    IV n, i, row, col;
PPCODE:
    FIX_DIRTY_GRID(self);
    n = self->rows * self->columns;
    New(0, tmp, n, SV*);
    for (i=0, col=0; col<self->columns; col++) {
        for (row=0; row<self->rows; row++, i++) {
            tmp[i] = AvARRAY(self->grid)[col + row * self->columns];
        }
    }
    for (i=0; i<n; i++) {
        AvARRAY(self->grid)[i] = tmp[i];
    }
    Safefree(tmp);
    SWAP(IV, self->rows, self->columns);
    XSRETURN(1);

void
flip_horizontal (self)
    Grid::Transform self
PROTOTYPE: $
ALIAS:
    mirror_horizontal = 1
PREINIT:
    IV row, lcol, rcol;
PPCODE:
    FIX_DIRTY_GRID(self);
    for (row=0; row<self->rows; row++) {
        for (lcol=0, rcol=self->columns-1; lcol<rcol; lcol++, rcol--) {
            SWAP(SV*, AvARRAY(self->grid)[lcol + row * self->columns],
                      AvARRAY(self->grid)[rcol + row * self->columns]);
        }
    }
    XSRETURN(1);

void
flip_vertical (self)
    Grid::Transform self
PROTOTYPE: $
ALIAS:
    mirror_vertical = 1
PREINIT:
    IV col, trow, brow;
PPCODE:
    FIX_DIRTY_GRID(self);
    for (col=0; col<self->columns; col++) {
        for (trow=0, brow=self->rows-1; trow<brow; trow++, brow--) {
            SWAP(SV*, AvARRAY(self->grid)[col + trow * self->columns],
                      AvARRAY(self->grid)[col + brow * self->columns]);
        }
    }
    XSRETURN(1);

void fold_right (self)
    Grid::Transform self
PROTOTYPE: $
PREINIT:
    SV **tmp;
    IV n, i, row, col, h;
PPCODE:
    FIX_DIRTY_GRID(self);
    n = self->rows * self->columns;
    New(0, tmp, n, SV*);
    h = self->columns >> 1;
    for (i=0, row=0; row<self->rows; row++) {
        IV cn = row * self->columns;
        if (self->columns & 1) {
            tmp[i++] = AvARRAY(self->grid)[h + cn];
        }
        for (col=h-1; col>=0; col--) {
            tmp[i++] = AvARRAY(self->grid)[col + cn];
            tmp[i++] = AvARRAY(self->grid)[self->columns - 1 - col + cn];
        }
    }
    for (i=0; i<n; i++) {
        AvARRAY(self->grid)[i] = tmp[i];
    }
    Safefree(tmp);
    XSRETURN(1);

void fold_left (self)
    Grid::Transform self
PROTOTYPE: $
PREINIT:
    SV **tmp;
    IV n, i, row, col, h;
PPCODE:
    FIX_DIRTY_GRID(self);
    n = self->rows * self->columns;
    New(0, tmp, n, SV*);
    h = self->columns >> 1;
    for (i=0, row=0; row<self->rows; row++) {
        IV cn = row * self->columns;
        for (col=0; col<h; col++) {
            tmp[i++] = AvARRAY(self->grid)[self->columns - 1 - col + cn];
            tmp[i++] = AvARRAY(self->grid)[col + cn];
        }
        if (self->columns & 1) {
            tmp[i++] = AvARRAY(self->grid)[h + cn];
        }
    }
    for (i=0; i<n; i++) {
        AvARRAY(self->grid)[i] = tmp[i];
    }
    Safefree(tmp);
    XSRETURN(1);

void alternate_row_direction (self)
    Grid::Transform self
PROTOTYPE: $
ALIAS:
    alt_row_dir = 1
PREINIT:
    IV row, lcol, rcol;
PPCODE:
    FIX_DIRTY_GRID(self);
    for (row=1; row<self->rows; row+=2) {
        for (lcol=0, rcol=self->columns-1; lcol<rcol; lcol++, rcol--) {
            SWAP(SV*, AvARRAY(self->grid)[lcol + row * self->columns],
                      AvARRAY(self->grid)[rcol + row * self->columns]);
        }
    }
    XSRETURN(1);

void spiral (self)
    Grid::Transform self
PROTOTYPE: $
PREINIT:
    SV **tmp;
    IV n, i, idx, top, bottom, left, right;
PPCODE:
    FIX_DIRTY_GRID(self);
    n = self->rows * self->columns;
    New(0, tmp, n, SV*);
    idx = 0;
    top = 0;
    bottom = self->rows-1;
    left = 0;
    right = self->columns-1;

    while (1) {
        for (i=left; i<=right; i++) {
            tmp[idx++] = AvARRAY(self->grid)[i + top * self->columns];
        }
        if (++top > bottom) break;

        for (i=top; i<=bottom; i++) {
            tmp[idx++] = AvARRAY(self->grid)[right + i * self->columns];
        }
        if (--right < left) break;

        for (i=right; i>=left; i--) {
            tmp[idx++] = AvARRAY(self->grid)[i + bottom * self->columns];
        }
        if (--bottom < top) break;

        for (i=bottom; i>=top; i--) {
            tmp[idx++] = AvARRAY(self->grid)[left + i * self->columns];
        }
        if (++left > right) break;
    }
    for (i=0; i<n; i++) {
        AvARRAY(self->grid)[i] = tmp[i];
    }
    Safefree(tmp);
    XSRETURN(1);

void
DESTROY (self)
    Grid::Transform self
CODE:
    if (self->grid) {
        SvREFCNT_dec(self->grid);
    }
    Safefree(self);
