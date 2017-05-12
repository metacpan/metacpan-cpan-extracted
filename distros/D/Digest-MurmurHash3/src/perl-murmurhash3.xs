
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* #include "ppport.h" */
#include "xshelper.h"
#include "MurmurHash3.h"

MODULE = Digest::MurmurHash3  PACKAGE = Digest::MurmurHash3 

PROTOTYPES: DISABLED

void
murmur32( char *key, UV seed = 0, IV length(key) )
    PREINIT:
        uint32_t out;
    PPCODE:
        MurmurHash3_x86_32( key, STRLEN_length_of_key, seed, &out );
        EXTEND(SP, 1);
        mXPUSHu( out );

void
murmur128_x86 ( char *key, UV seed = 0, IV length(key) )
    PREINIT:
        uint32_t out[4];
    PPCODE:
        MurmurHash3_x86_128( key, STRLEN_length_of_key, seed, &out );
        EXTEND(SP, 4);
        mXPUSHu( out[0] );
        mXPUSHu( out[1] );
        mXPUSHu( out[2] );
        mXPUSHu( out[3] );

#ifdef HAVE_64BITINT

void
murmur128_x64 ( char *key, UV seed = 0, IV length(key) )
    PREINIT:
        uint64_t out[2];
    PPCODE:
        MurmurHash3_x64_128( key, STRLEN_length_of_key, seed, &out );
        EXTEND(SP, 2);
        mXPUSHu( out[0] );
        mXPUSHu( out[1] );

#endif
