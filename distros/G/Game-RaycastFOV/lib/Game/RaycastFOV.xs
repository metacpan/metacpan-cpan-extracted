#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "math.h"

#define CALLTWOUP                                                              \
    ENTER;                                                                     \
    SAVETMPS;                                                                  \
    PUSHMARK(SP);                                                              \
    EXTEND(SP, 2)
#define TWOUPDONE                                                              \
    FREETMPS;                                                                  \
    LEAVE
#define CIRCLECB(x, y)                                                         \
    do {                                                                       \
        key = Perl_form(aTHX_ "%d,%d", x, y);                                  \
        len = strlen(key);                                                     \
        if(!hv_exists(seen, key, len)) {                                       \
            hv_store(seen, key, len, &PL_sv_yes, 0);                           \
            PUSHMARK(SP);                                                      \
            EXTEND(SP, 2);                                                     \
            mPUSHs(newSViv(x));                                                \
            mPUSHs(newSViv(y));                                                \
            PUTBACK;                                                           \
            call_sv(callback, G_DISCARD);                                      \
            SPAGAIN;                                                           \
        }                                                                      \
    } while (0)

MODULE = Game::RaycastFOV		PACKAGE = Game::RaycastFOV		
PROTOTYPES: ENABLE

void
bypair (callback, ...)
    SV *callback;
    PREINIT:
        int answer, i;
        SV *x, *y;
    PROTOTYPE: &@
    PPCODE:
        if (!(items & 1)) croak("uneven number of arguments");
        dSP;
        for (i = 1; i < items; i += 2) {
            x = ST(i);
            y = ST(i + 1);
            CALLTWOUP;
            PUSHs(x);
            PUSHs(y);
            PUTBACK;
            call_sv(callback, G_SCALAR);
            SPAGAIN;
            answer = POPi;
            TWOUPDONE;
            if (answer == -1) break;
        }

void
bypairall (callback, ...)
    SV *callback;
    PREINIT:
        int i;
        SV *x, *y;
    PROTOTYPE: &@
    PPCODE:
        if (!(items & 1)) croak("uneven number of arguments");
        dSP;
        for (i = 1; i < items; i += 2) {
            x = ST(i);
            y = ST(i + 1);
            CALLTWOUP;
            PUSHs(x);
            PUSHs(y);
            PUTBACK;
            call_sv(callback, G_DISCARD);
            SPAGAIN;
            TWOUPDONE;
        }

void
circle (callback, int x0, int y0, int radius)
    SV *callback;
    PREINIT:
        char *key;
        int f, ddF_x, ddF_y, x, y;
        HV* seen;
        STRLEN len;
    PROTOTYPE: &$$$
    PPCODE:
        dSP;
        ENTER;
        SAVETMPS;
        sv_2mortal((SV *)(seen = newHV()));
        f = 1 - radius;
        ddF_x = 0;
        ddF_y = -2 * radius;
        x = 0;
        y = radius;
        CIRCLECB(x0, y0 + radius);
        CIRCLECB(x0, y0 - radius);
        CIRCLECB(x0 + radius, y0);
        CIRCLECB(x0 - radius, y0);
        while (x < y) {
            if (f >= 0) {
                y--;
                ddF_y += 2;
                f += ddF_y;
            }
            x++;
            ddF_x += 2;
            f += ddF_x + 1;
            CIRCLECB(x0 + x, y0 + y);
            CIRCLECB(x0 - x, y0 + y);
            CIRCLECB(x0 + x, y0 - y);
            CIRCLECB(x0 - x, y0 - y);
            CIRCLECB(x0 + y, y0 + x);
            CIRCLECB(x0 - y, y0 + x);
            CIRCLECB(x0 + y, y0 - x);
            CIRCLECB(x0 - y, y0 - x);
        }
        FREETMPS;
        LEAVE;

void
line (callback, int x0, int y0, int x1, int y1)
    SV *callback;
    PREINIT:
        int answer, dx, dy, err, e2, sx, sy;
    PROTOTYPE: &$$$$
    PPCODE:
        dSP;
        dx = abs(x1 - x0);
        dy = abs(y1 - y0);
        sx = x0 < x1 ? 1 : -1;
        sy = y0 < y1 ? 1 : -1;
        err = (dx > dy ? dx : -dy) / 2;
        while (1) {
            CALLTWOUP;
            mPUSHs(newSViv(x0));
            mPUSHs(newSViv(y0));
            PUTBACK;
            call_sv(callback, G_SCALAR);
            SPAGAIN;
            answer = POPi;
            TWOUPDONE;
            if (answer == -1 || (x0 == x1 && y0 == y1)) break;
            e2 = err;
            if (e2 > -dx) {
                err -= dy;
                x0 += sx;
            }
            if (e2 < dy) {
                err += dx;
                y0 += sy;
            }
        }

void
sub_circle (callback, long x0, long y0, unsigned long radius, double swing, double angle, double max_angle)
    SV *callback;
    PREINIT:
        char *key;
        long newx, newy;
        HV* seen;
        STRLEN len;
    PROTOTYPE: &$$$$$$
    PPCODE:
        dSP;
        sv_2mortal((SV *)(seen = newHV()));
        while (angle < max_angle) {
            newx = x0 + lrint(radius * cos(angle));
            newy = y0 + lrint(radius * sin(angle));
            key = Perl_form(aTHX_ "%ld,%ld", newx, newy);
            len = strlen(key);
            if(!hv_exists(seen, key, len)) {
                hv_store(seen, key, len, &PL_sv_yes, 0);
                CALLTWOUP;
                mPUSHs(newSViv(newx));
                mPUSHs(newSViv(newy));
                PUTBACK;
                call_sv(callback, G_DISCARD);
                SPAGAIN;
                TWOUPDONE;
            }
            angle += swing;
        }
