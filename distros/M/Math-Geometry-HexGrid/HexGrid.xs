#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "hexgrid.h"

MODULE = Math::Geometry::HexGrid    PACKAGE = Math::Geometry::HexGrid

PROTOTYPES: DISABLE

void
oddr_to_cube(int col, int row)
    PPCODE:
        HexOddr o = { col, row };
        HexCube c = hex_oddr_to_cube(o);
        EXTEND(SP, 3);
        PUSHs(sv_2mortal(newSViv(c.q)));
        PUSHs(sv_2mortal(newSViv(c.r)));
        PUSHs(sv_2mortal(newSViv(c.s)));
        XSRETURN(3);

void
cube_to_oddr(int q, int r, int s)
    PPCODE:
        HexCube c = { q, r, s };
        HexOddr o = hex_cube_to_oddr(c);
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(o.col)));
        PUSHs(sv_2mortal(newSViv(o.row)));
        XSRETURN(2);

int
hex_distance(int col1, int row1, int col2, int row2)
    CODE:
        HexOddr a = { col1, row1 };
        HexOddr b = { col2, row2 };
        RETVAL = hex_distance(a, b);
    OUTPUT:
        RETVAL

bool
hex_is_collinear(int col1, int row1, int col2, int row2)
    CODE:
        HexOddr a = { col1, row1 };
        HexOddr b = { col2, row2 };
        RETVAL = hex_is_collinear(a, b);
    OUTPUT:
        RETVAL

void
hex_neighbors(int col, int row)
    PPCODE:
        HexOddr o = { col, row };
        HexOddr nbs[6];
        hex_neighbors(o, nbs);

        EXTEND(SP, 6);
        for (int i = 0; i < 6; i++) {
            AV* av = newAV();
            av_push(av, newSViv(nbs[i].col));
            av_push(av, newSViv(nbs[i].row));
            PUSHs(sv_2mortal(newRV_noinc((SV*)av)));
        }
        XSRETURN(6);

void
hex_collinear_ray(int col1, int row1, int col2, int row2, int max_length = 100)
    PPCODE:
        HexOddr from = { col1, row1 };
        HexOddr to   = { col2, row2 };

        if (max_length <= 0) XSRETURN_EMPTY;

        HexOddr stack_buf[128];
        HexOddr* buf = (max_length <= 128) ? stack_buf : (HexOddr*)malloc(max_length * sizeof(HexOddr));

        int count = hex_collinear_ray(from, to, buf, max_length);
        if (count <= 0) {
            if (buf != stack_buf) free(buf);
            XSRETURN_EMPTY;
        }

        EXTEND(SP, count);
        for (int i = 0; i < count; i++) {
            AV* av = newAV();
            av_push(av, newSViv(buf[i].col));
            av_push(av, newSViv(buf[i].row));
            PUSHs(sv_2mortal(newRV_noinc((SV*)av)));
        }

        if (buf != stack_buf) free(buf);
        XSRETURN(count);


MODULE = Math::Geometry::HexGrid    PACKAGE = Math::Geometry::HexGrid::Hex

SV*
new(const char* class, int col, int row)
    CODE:
        AV* av = newAV();
        av_push(av, newSViv(col));
        av_push(av, newSViv(row));
        SV* rv = newRV_noinc((SV*)av);
        RETVAL = sv_bless(rv, gv_stashpv(class, GV_ADD));
    OUTPUT:
        RETVAL

int
col(SV* self)
    CODE:
        if (!sv_isobject(self)) croak("col called on non-object");
        AV* av = (AV*)SvRV(self);
        RETVAL = SvIV(*av_fetch(av, 0, 0));
    OUTPUT:
        RETVAL

int
row(SV* self)
    CODE:
        if (!sv_isobject(self)) croak("row called on non-object");
        AV* av = (AV*)SvRV(self);
        RETVAL = SvIV(*av_fetch(av, 1, 0));
    OUTPUT:
        RETVAL

void
to_cube(SV* self)
    PPCODE:
        if (!sv_isobject(self)) croak("to_cube called on non-object");
        AV* av = (AV*)SvRV(self);
        HexOddr o = { SvIV(*av_fetch(av, 0, 0)), SvIV(*av_fetch(av, 1, 0)) };
        HexCube c = hex_oddr_to_cube(o);
        EXTEND(SP, 3);
        PUSHs(sv_2mortal(newSViv(c.q)));
        PUSHs(sv_2mortal(newSViv(c.r)));
        PUSHs(sv_2mortal(newSViv(c.s)));
        XSRETURN(3);

int
distance_to(SV* self, SV* other)
    CODE:
        if (!sv_isobject(self) || !sv_isobject(other))
            croak("distance_to called on non-object");
        AV* av_self  = (AV*)SvRV(self);
        AV* av_other = (AV*)SvRV(other);
        HexOddr a = { SvIV(*av_fetch(av_self, 0, 0)),  SvIV(*av_fetch(av_self, 1, 0)) };
        HexOddr b = { SvIV(*av_fetch(av_other, 0, 0)), SvIV(*av_fetch(av_other, 1, 0)) };
        RETVAL = hex_distance(a, b);
    OUTPUT:
        RETVAL

bool
is_collinear_with(SV* self, SV* other)
    CODE:
        if (!sv_isobject(self) || !sv_isobject(other))
            croak("is_collinear_with called on non-object");
        AV* av_self  = (AV*)SvRV(self);
        AV* av_other = (AV*)SvRV(other);
        HexOddr a = { SvIV(*av_fetch(av_self, 0, 0)),  SvIV(*av_fetch(av_self, 1, 0)) };
        HexOddr b = { SvIV(*av_fetch(av_other, 0, 0)), SvIV(*av_fetch(av_other, 1, 0)) };
        RETVAL = hex_is_collinear(a, b);
    OUTPUT:
        RETVAL

bool
equals(SV* self, SV* other, ...)
    CODE:
        if (!sv_isobject(self) || !sv_isobject(other)) {
            RETVAL = false;
        } else {
            AV* av_self  = (AV*)SvRV(self);
            AV* av_other = (AV*)SvRV(other);
            IV c1 = SvIV(*av_fetch(av_self, 0, 0));
            IV r1 = SvIV(*av_fetch(av_self, 1, 0));
            IV c2 = SvIV(*av_fetch(av_other, 0, 0));
            IV r2 = SvIV(*av_fetch(av_other, 1, 0));
            RETVAL = (c1 == c2 && r1 == r2);
        }
    OUTPUT:
        RETVAL

const char*
to_string(SV* self, ...)
    PREINIT:
        static char buf[64];
    CODE:
        if (!sv_isobject(self)) croak("to_string called on non-object");
        AV* av = (AV*)SvRV(self);
        IV c = SvIV(*av_fetch(av, 0, 0));
        IV r = SvIV(*av_fetch(av, 1, 0));
        snprintf(buf, sizeof(buf), "%ld,%ld", (long)c, (long)r);
        RETVAL = buf;
    OUTPUT:
        RETVAL
