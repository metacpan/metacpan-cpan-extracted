#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* NOTE these MUST be kept in sync with similar in Xomb.pm */
#define MAP_COLS 78
#define MAP_ROWS 22

/* linecb - Bresenham with some features to keep it from going off
 * of the map and to skip the first point and abort should the
 * callback return -1
 * 
 * walkcb - linecb, but does not stop at x1,y1 */

MODULE = Game::Xomb             PACKAGE = Game::Xomb            
PROTOTYPES: ENABLE

void
linecb (callback, int x0, int y0, int x1, int y1)
    SV *callback;
    PREINIT:
        int answer, count, dx, dy, err, e2, sx, sy, online, iters;
    PROTOTYPE: &$$$$
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
                count = call_sv(callback, G_SCALAR);
                if (count != 1) croak("multiple return values from callback");
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

void
walkcb (callback, int x0, int y0, int x1, int y1)
    SV *callback;
    PREINIT:
        int answer, count, dx, dy, err, e2, sx, sy, online, iters;
    PROTOTYPE: &$$$$
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
                count = call_sv(callback, G_SCALAR);
                if (count != 1) croak("multiple return values from callback");
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
