#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "mt.h"


typedef struct mt * Math__Random__MT;

void * U32ArrayPtr ( int n ) {
    SV * sv = sv_2mortal( NEWSV( 0, n*sizeof(U32) ) );
    return SvPVX(sv);
}

MODULE = Math::Random::MT   PACKAGE = Math::Random::MT  PREFIX = mt_
PROTOTYPES: DISABLE

Math::Random::MT
mt_init()
    CODE:
        RETVAL = mt_init();
    OUTPUT:
        RETVAL

void
mt_init_seed(self, seed)
    Math::Random::MT self
    U32     seed
    CODE:
        mt_init_seed(self, seed);

void
mt_setup_array(self, array, ...)
    Math::Random::MT self;
    U32 * array = U32ArrayPtr( items );
    PREINIT:
        U32 ix_array = 0;
    CODE:
        items--;
        while ( items--) {
            array[ix_array] = (U32)SvIV(ST(ix_array+1));
            ix_array++;
        }
        mt_setup_array(self, (uint32_t*)array, ix_array);

void
mt_DESTROY(self)
    Math::Random::MT self
    CODE:
        mt_free(self);

U32
mt_get_seed(self)
    Math::Random::MT self
    CODE:
        RETVAL = mt_get_seed(self);
    OUTPUT:
        RETVAL

double
mt_genrand(self)
    Math::Random::MT self
    CODE:
        RETVAL = mt_genrand(self);
    OUTPUT:
        RETVAL

U32
mt_genirand(self)
    Math::Random::MT self
    CODE:
        RETVAL = mt_genirand(self);
    OUTPUT:
        RETVAL
