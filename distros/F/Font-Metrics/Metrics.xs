#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef WIN32
#  undef malloc
#  undef calloc
#  undef realloc
#  undef free
#endif

#include "fm.h"

static fm_font_t *
fm_from_sv(pTHX_ SV *self) {
    return INT2PTR(fm_font_t *, SvIV(SvRV(self)));
}

MODULE = Font::Metrics  PACKAGE = Font::Metrics

PROTOTYPES: DISABLE

BOOT:
    fm_std14_init();

SV *
new(class, ...)
    SV *class
    CODE:
    {
        fm_font_t  *fm;
        SV         *obj;
        const char *name = NULL;
        const char *file = NULL;
        int         i;

        PERL_UNUSED_VAR(class);

        for (i = 1; i + 1 < items; i += 2) {
            const char *key = SvPV_nolen(ST(i));
            SV         *val = ST(i + 1);
            if      (strEQ(key, "name")) name = SvPV_nolen(val);
            else if (strEQ(key, "file")) file = SvPV_nolen(val);
        }

        fm = (fm_font_t *)calloc(1, sizeof(fm_font_t));
        if (!fm) croak("Font::Metrics: out of memory");

        if (file) {
            fm_font_t *ttf = fm_load_truetype(file);
            if (!ttf) {
                free(fm);
                croak("Font::Metrics: cannot load TrueType font '%s'", file);
            }
            *fm = *ttf;
            free(ttf);
        } else {
            int idx = name ? fm_std14_index(name) : -1;
            if (idx < 0) {
                free(fm);
                croak("Font::Metrics: unknown font '%s'", name ? name : "(none)");
            }
            fm->type      = FM_STD14;
            fm->std14_idx = idx;
        }

        obj    = newSV(0);
        sv_setiv(obj, PTR2IV(fm));
        RETVAL = sv_bless(newRV_noinc(obj), gv_stashsv(class, GV_ADD));
    }
    OUTPUT: RETVAL

float
char_width(self, chr, size)
    SV    *self
    SV    *chr
    double size
    CODE:
    {
        STRLEN       len;
        const char  *s  = SvPV(chr, len);
        unsigned int cp;
        if (SvUTF8(chr) && len > 0) {
            cp = (unsigned int)fm_utf8_decode(&s);
        } else {
            cp = (len > 0) ? (unsigned char)s[0] : 0;
        }
        RETVAL = fm_char_width(fm_from_sv(aTHX_ self), cp, (float)size);
    }
    OUTPUT: RETVAL

float
string_width(self, text, size)
    SV    *self
    SV    *text
    double size
    CODE:
    {
        const char *s = SvPV_nolen(text);
        RETVAL = SvUTF8(text)
            ? fm_string_width_utf8(fm_from_sv(aTHX_ self), s, (float)size)
            : fm_string_width    (fm_from_sv(aTHX_ self), s, (float)size);
    }
    OUTPUT: RETVAL

float
ascender(self, size)
    SV    *self
    double size
    CODE:
        RETVAL = fm_ascender(fm_from_sv(aTHX_ self), (float)size);
    OUTPUT: RETVAL

float
descender(self, size)
    SV    *self
    double size
    CODE:
        RETVAL = fm_descender(fm_from_sv(aTHX_ self), (float)size);
    OUTPUT: RETVAL

float
cap_height(self, size)
    SV    *self
    double size
    CODE:
        RETVAL = fm_cap_height(fm_from_sv(aTHX_ self), (float)size);
    OUTPUT: RETVAL

float
x_height(self, size)
    SV    *self
    double size
    CODE:
        RETVAL = fm_x_height(fm_from_sv(aTHX_ self), (float)size);
    OUTPUT: RETVAL

float
line_height(self, size)
    SV    *self
    double size
    CODE:
        RETVAL = fm_line_height(fm_from_sv(aTHX_ self), (float)size);
    OUTPUT: RETVAL

float
kern_pair(self, chr1, chr2, size)
    SV    *self
    SV    *chr1
    SV    *chr2
    double size
    CODE:
    {
        STRLEN       l1, l2;
        const char  *s1 = SvPV(chr1, l1);
        const char  *s2 = SvPV(chr2, l2);
        unsigned int cp1, cp2;
        cp1 = (SvUTF8(chr1) && l1 > 0) ? (unsigned int)fm_utf8_decode(&s1)
                                        : (l1 > 0) ? (unsigned char)s1[0] : 0;
        cp2 = (SvUTF8(chr2) && l2 > 0) ? (unsigned int)fm_utf8_decode(&s2)
                                        : (l2 > 0) ? (unsigned char)s2[0] : 0;
        RETVAL = fm_kern_pair(fm_from_sv(aTHX_ self), cp1, cp2, (float)size);
    }
    OUTPUT: RETVAL

void
DESTROY(self)
    SV *self
    CODE:
        fm_free(fm_from_sv(aTHX_ self));
