/* Xomb.xs - line drawing and random number generation utility functions */

#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "jsf.h"

/* NOTE these MUST be kept in sync with similar in Xomb.pm */
#define MAP_COLS 78
#define MAP_ROWS 22

MODULE = Game::Xomb             PACKAGE = Game::Xomb            
PROTOTYPES: DISABLE

void
bypair (callback, ...)
    SV *callback;
    PREINIT:
        int i;
        SV *x, *y;
    PPCODE:
        if (!(items & 1)) croak("uneven number of arguments");
        dSP;
        for (i = 1; i < items; i += 2) {
            x = ST(i);
            y = ST(i + 1);
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            EXTEND(SP, 2);
            PUSHs(x);
            PUSHs(y);
            PUTBACK;
            call_sv(callback, G_DISCARD);
            SPAGAIN;
            FREETMPS;
            LEAVE;
        }

UV
coinflip ()
    CODE:
        RETVAL = ranval() & 1;
    OUTPUT:
        RETVAL

# NOTE this distance differs from the iters count in linecb() as that
# function can do [0,0] .. [3,3] in 3 steps while this will calculate
# 4.24, lround'd to 4
UV
distance (uint32_t x0, uint32_t y0, uint32_t x1, uint32_t y1)
    PREINIT:
        int dx, dy;
    CODE:
        dx = x1 - x0;
        dy = y1 - y0;
        RETVAL = lround(sqrt(dx*dx + dy*dy));
    OUTPUT:
        RETVAL

# splice a random element out of an array reference
# NOTE this does not preserve the order of the array as that requires a
# series of copies anytime an item is extracted from not the end which
# for large lists will be most of the time (previous versions of this
# code did such a waterfall copy)
SV *
extract (avref)
    AV *avref;
    PREINIT:
        SSize_t i, len, rnd;
        SV *dunno, **swap;
    CODE:
        len = av_len(avref) + 1;
        if (len == 0) XSRETURN_UNDEF;
        rnd = ranval() % len;
        dunno = av_delete(avref, rnd, 0);
        if (rnd != len - 1) {
            swap = av_fetch(avref, len - 1, FALSE);
            av_store(avref, rnd, *swap);
            AvFILLp(avref) -= 1;
            AvMAX(avref) -= 1;
        }
        SvREFCNT_inc(dunno);
        RETVAL = dunno;
    OUTPUT:
        RETVAL

# init_jsf - setup the RNG (see src/jsf.*)
void
init_jsf (seed)
    UV seed
    PPCODE:
        raninit(seed);

UV
irand (uint32_t max)
    CODE:
        RETVAL = ranval() % max;
    OUTPUT:
        RETVAL

# linecb - Bresenham with some features to keep it from going off of
# the map and to skip the first point and abort should the callback
# return -1
void
linecb (callback, int x0, int y0, int x1, int y1)
    SV *callback;
    PREINIT:
        int answer, dx, dy, err, e2, sx, sy, online, iters;
    PPCODE:
        dSP;
        dx = abs(x1 - x0);
        dy = abs(y1 - y0);
        sx = x0 < x1 ? 1 : -1;
        sy = y0 < y1 ? 1 : -1;
        err = (dx > dy ? dx : -dy) / 2;
        iters = 0;
        online = 0;
        while (1) {
            if (x0 < 0 || x0 >= MAP_COLS || y0 < 0 || y0 >= MAP_ROWS) break;
            if (online) {
                ENTER;
                SAVETMPS;
                PUSHMARK(SP);
                EXTEND(SP, 3);
                mPUSHs(newSViv(x0));
                mPUSHs(newSViv(y0));
                mPUSHs(newSViv(iters));
                PUTBACK;
                call_sv(callback, G_SCALAR);
                SPAGAIN;
                answer = POPi;
                FREETMPS;
                LEAVE;
                if (answer == -1) break;
            }
            if (x0 == x1 && y0 == y1) break;
            e2 = err;
            if (e2 > -dx) {
                err -= dy;
                x0 += sx;
            }
            if (e2 < dy) {
                err += dx;
                y0 += sy;
            }
            online = 1;
            iters++;
        }

UV
onein (uint32_t N)
    CODE:
        RETVAL = 0 == ranval() % N;
    OUTPUT:
        RETVAL

UV
roll (uint32_t count, uint32_t sides)
    PREINIT:
        uint32_t sum;
    CODE:
        sum = count;
        while (count--) sum += ranval() % sides;
        RETVAL = sum;
    OUTPUT:
        RETVAL

# pick a random element of an array ref
SV *
pick (avref)
    AV *avref;
    PREINIT:
        SSize_t len, rnd;
        SV **svp;
    CODE:
        len = av_len(avref) + 1;
        if (len == 0) XSRETURN_UNDEF;
        rnd = ranval() % len;
        svp = av_fetch(avref, rnd, FALSE);
        SvREFCNT_inc(*svp);
        RETVAL = *svp;
    OUTPUT:
        RETVAL

# walkcb - linecb, but does not stop at x1,y1. used by Trolls to find
# what gets busted, which may or may not be the player
void
walkcb (callback, int x0, int y0, int x1, int y1)
    SV *callback;
    PREINIT:
        int answer, dx, dy, err, e2, sx, sy, online, iters;
    PPCODE:
        dSP;
        dx = abs(x1 - x0);
        dy = abs(y1 - y0);
        sx = x0 < x1 ? 1 : -1;
        sy = y0 < y1 ? 1 : -1;
        err = (dx > dy ? dx : -dy) / 2;
        iters = 0;
        online = 0;
        while (1) {
            if (x0 < 0 || x0 >= MAP_COLS || y0 < 0 || y0 >= MAP_ROWS) break;
            if (online) {
                ENTER;
                SAVETMPS;
                PUSHMARK(SP);
                EXTEND(SP, 3);
                mPUSHs(newSViv(x0));
                mPUSHs(newSViv(y0));
                mPUSHs(newSViv(iters));
                PUTBACK;
                call_sv(callback, G_SCALAR);
                SPAGAIN;
                answer = POPi;
                FREETMPS;
                LEAVE;
                if (answer == -1) break;
            }
            e2 = err;
            if (e2 > -dx) {
                err -= dy;
                x0 += sx;
            }
            if (e2 < dy) {
                err += dx;
                y0 += sy;
            }
            online = 1;
            iters++;
        }
