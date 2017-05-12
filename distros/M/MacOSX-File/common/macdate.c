/*
 * $Id: macdate.c,v 0.70 2005/08/09 15:47:00 dankogai Exp $
 */

#include <DateTimeUtils.h>
# include <math.h>

#define EPOCH_DELTA 2082844800

/*
 *  I HATE TINKERING WITH BITS!
 */

static double 
UDT2D(UTCDateTime *u){
    SInt64 q;
    double d;
    q  = u->highSeconds;              q <<= 32;
    q += u->lowSeconds - EPOCH_DELTA; q <<= 16; 
    q += u->fraction;
    d = q;
    return (d / 65536);
}

static UTCDateTime *
D2UDT(double d, UTCDateTime *u){
    SInt64 q = (d + EPOCH_DELTA) * 65536;

    u->highSeconds =  q >> 48;
    u->lowSeconds  = (q & 0x0000ffffffff0000) >> 16;
    u->fraction    =  q & 0x000000000000ffff;

    /* fprintf(stderr, "%f-> %qd -> %u,%u,%u\n", d, q, u->highSeconds, u->lowSeconds, u->fraction); */

    return u;
}
