#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "pcg.h"

MODULE = Math::Random::PCG32		PACKAGE = Math::Random::PCG32

PROTOTYPES: ENABLE

pcg32_random_t *
new(CLASS, initstate, initseq)
    char *CLASS
    UV initstate
    UV initseq
    CODE:
        Newxz(RETVAL, 1, pcg32_random_t);
        if (RETVAL == NULL)
            croak("Could not allocate state memory");
        pcg32_srandom_r(RETVAL, initstate, initseq);
    OUTPUT:
        RETVAL

UV
rand(pcg32_random_t *rng)
    CODE:
        RETVAL = pcg32_random_r(rng);
    OUTPUT:
        RETVAL

void
DESTROY(pcg32_random_t *rng)
    PPCODE:
        Safefree(rng);
