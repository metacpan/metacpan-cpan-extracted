/*
 * $Id: SipHash.xs,v 0.6 2016/03/04 13:06:00 dankogai Exp $
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "csiphash.c"

static SV *
siphash_as_av(SV *src, SV *seed) {
    uint64_t hash = siphash24(SvPV_nolen(src), SvCUR(src), SvPV_nolen(seed));
    AV *av = newAV();
    av_extend(av, 1);
    av_store(av, 0, newSVuv(hash & 0xffffffff));
    av_store(av, 1, newSVuv(hash >> 32));
    return newRV_noinc((SV *)av);
}

MODULE = Digest::SipHash  PACKAGE = Digest::SipHash

UV
_xs_siphash64(src, seed)
SV *src;
SV *seed;
CODE:
    RETVAL = (UV)siphash24(SvPV_nolen(src), SvCUR(src), SvPV_nolen(seed));
OUTPUT:
    RETVAL

SV *
_xs_siphash_av(src, seed)
SV *src;
SV *seed;
CODE:
    RETVAL = siphash_as_av(src, seed);
OUTPUT:
    RETVAL
