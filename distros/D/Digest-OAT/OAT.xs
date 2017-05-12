#include <stdint.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "const-c.inc"

/* Bob Jenkin's one at a time hash, has good avalanche behavior */
unsigned oat ( SV* key ) {

    /* Perl Stuff */
    int len = 0;
    unsigned char* p = SvPV( key, len );
    /* End Perl Stuff */

    /* unsigned char *p = str; */
    uint32_t h = 0;
    int i;

    for ( i = 0; i < len; i++ ) {
        h += p[i];
        h += ( h << 10 );
        h ^= ( h >> 6 );
    }

    h += ( h << 3 );
    h ^= ( h >> 11 );
    h += ( h << 15 );

    return h;
}

MODULE = Digest::OAT		PACKAGE = Digest::OAT		

INCLUDE: const-xs.inc

U32
oat (key)
    SV *    key
