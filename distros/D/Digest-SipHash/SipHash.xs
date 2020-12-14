/*
 * $Id: SipHash.xs,v 0.7 2020/12/11 18:06:57 dankogai Exp dankogai $
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "csiphash.c"

uint64_t siphash24_sv(SV *src, SV *seed) {
    STRLEN src_len;
    char * src_pv= SvPV(src,src_len);
    STRLEN seed_len;
    char *seed_pv= SvPV(seed,seed_len);
    assert(seed_len>=16);
    return siphash24(src_pv, src_len, seed_pv);
}

static SV *
siphash_as_av(SV *src, SV *seed) {
    uint64_t hash = siphash24_sv(src,seed);

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
    RETVAL = (UV)siphash24_sv(src, seed);
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
