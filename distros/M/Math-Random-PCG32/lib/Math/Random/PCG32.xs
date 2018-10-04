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
irand(pcg32_random_t *rng)
    CODE:
        RETVAL = pcg32_random_r(rng);
    OUTPUT:
        RETVAL

double
rand(pcg32_random_t *rng, ...)
    PROTOTYPE: $;$
    PREINIT:
        double factor;
    CODE:
        if (items > 1) {
            if (!SvIOK(ST(1)) && !SvNOK(ST(1)))
                croak("factor must be a number");
            factor = SvNV(ST(1));
        } else
            factor = 1.0;
        RETVAL = pcg32_random_r(rng) / 4294967296.0 * factor;
    OUTPUT:
        RETVAL

SV *
rand_elm(pcg32_random_t *rng, avref)
    AV *avref;
    PREINIT:
        int len;
        SV **svp;
    CODE:
        len = av_len(avref) + 1;
        if (len == 0)
            XSRETURN_UNDEF;
        else
            svp = av_fetch(avref, pcg32_random_r(rng) % len, FALSE);
            SvREFCNT_inc(*svp);
            RETVAL = *svp;
    OUTPUT:
        RETVAL

UV
rand_idx(pcg32_random_t *rng, avref)
    AV *avref;
    PREINIT:
        int len;
    CODE:
        len = av_len(avref) + 1;
        if (len == 0)
            XSRETURN_UNDEF;
        else
            RETVAL = pcg32_random_r(rng) % len;
    OUTPUT:
        RETVAL

void
DESTROY(pcg32_random_t *rng)
    PPCODE:
        Safefree(rng);
