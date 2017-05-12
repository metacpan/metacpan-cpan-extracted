#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Jenkins Hash http://burtleburtle.net/bob/hash/doobs.html */

const int DEBUG = 0;

/* Need to constrain U32 to only 32 bits on 64 bit systems
 * For efficiency we only use the & 0xffffffff if required
 */
#if BYTEORDER > 0x4321 || defined(TRUNCATE_U32)
#define MIX(a,b,c) \
{ \
  a &= 0xffffffff; b &= 0xffffffff; c &= 0xffffffff; \
  a -= b; a -= c; a ^= (c>>13); a &= 0xffffffff; \
  b -= c; b -= a; b ^= (a<<8);  b &= 0xffffffff; \
  c -= a; c -= b; c ^= (b>>13); c &= 0xffffffff; \
  a -= b; a -= c; a ^= (c>>12); a &= 0xffffffff; \
  b -= c; b -= a; b ^= (a<<16); b &= 0xffffffff; \
  c -= a; c -= b; c ^= (b>>5);  c &= 0xffffffff; \
  a -= b; a -= c; a ^= (c>>3);  a &= 0xffffffff; \
  b -= c; b -= a; b ^= (a<<10); b &= 0xffffffff; \
  c -= a; c -= b; c ^= (b>>15); c &= 0xffffffff; \
}
#else
#define MIX(a,b,c) \
{ \
  a -= b; a -= c; a ^= (c>>13); \
  b -= c; b -= a; b ^= (a<<8);  \
  c -= a; c -= b; c ^= (b>>13); \
  a -= b; a -= c; a ^= (c>>12); \
  b -= c; b -= a; b ^= (a<<16); \
  c -= a; c -= b; c ^= (b>>5);  \
  a -= b; a -= c; a ^= (c>>3);  \
  b -= c; b -= a; b ^= (a<<10); \
  c -= a; c -= b; c ^= (b>>15); \
}
#endif

U32 jhash( SV* str )
{
    STRLEN rawlen;
    char* p;
    U32 a, b, c, len, length;

    /* extract the string data and string length from the perl scalar */
    p = (char*)SvPV(str, rawlen);
    length = len = (U32)rawlen;

    /* Test for undef or null string case and return 0 */
    if ( length == 0 ) {
        DEBUG && printf( "Recieved a null or undef string!\n" );
      return 0;
    }

    DEBUG && printf( "Received string '%.*s'.\n", (int)len, p );

    a = b = 0x9e3779b9;        /* golden ratio suggested by Jenkins */
    c = 0;
    while (len >= 12)
    {
        a += (p[0] + (((U32)p[1])<<8) + (((U32)p[2])<<16) +
              (((U32)p[3])<<24));
        b += (p[4] + (((U32)p[5])<<8) + (((U32)p[6])<<16) +
              (((U32)p[7])<<24));
        c += (p[8] + (((U32)p[9])<<8) + (((U32)p[10])<<16) +
              (((U32)p[11])<<24));
        MIX(a, b, c);
        p += 12;
        len -= 12;
    }
    c += length;
    switch(len) {
    case 11: c+=((U32)p[10]<<24);
    case 10: c+=((U32)p[9]<<16);
    case 9:  c+=((U32)p[8]<<8);
    case 8:  b+=((U32)p[7]<<24);
    case 7:  b+=((U32)p[6]<<16);
    case 6:  b+=((U32)p[5]<<8);
    case 5:  b+=((U32)p[4]);
    case 4:  a+=((U32)p[3]<<24);
    case 3:  a+=((U32)p[2]<<16);
    case 2:  a+=((U32)p[1]<<8);
    case 1:  a+=((U32)p[0]);
    }
    MIX(a, b, c);
    DEBUG && printf( "Hash value is %d.\n", (int)(c) );

    return(c);
}

MODULE = Digest::JHash        PACKAGE = Digest::JHash

PROTOTYPES: ENABLE

U32
jhash(str)
    SV*    str
