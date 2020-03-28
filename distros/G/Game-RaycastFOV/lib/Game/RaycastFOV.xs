#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define CALLTWOUP                                                              \
    ENTER;                                                                     \
    SAVETMPS;                                                                  \
    PUSHMARK(SP);                                                              \
    EXTEND(SP, 2)
#define TWOUPDONE                                                              \
    FREETMPS;                                                                  \
    LEAVE
#define CIRCLECB(x, y)                                                         \
    PUSHMARK(SP);                                                              \
    EXTEND(SP, 2);                                                             \
    mPUSHs(newSViv(x));                                                        \
    mPUSHs(newSViv(y));                                                        \
    PUTBACK;                                                                   \
    call_sv(callback, G_DISCARD);                                              \
    SPAGAIN

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
circle(callback, int x0, int y0, int radius)
    SV *callback;
    PREINIT:
        int f, ddF_x, ddF_y, x, y;
    PROTOTYPE: &$$$
    PPCODE:
        dSP;
        ENTER;
        SAVETMPS;
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
