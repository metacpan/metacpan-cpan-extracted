// Disables the implicit 'pTHX_' context pointer argument, which is good practice for
// modern Perl XS code that uses the 'aTHX_' macro explicitly.
#define PERL_NO_GET_CONTEXT 1
#include <EXTERN.h>
#include <perl.h>
// Disables Perl's internal locking mechanisms for certain structures.
// This is often used when the XS module manages its own thread safety.
#define NO_XSLOCKS
#include <XSUB.h>

#include <inttypes.h>
#include <string.h>

#ifdef __MINGW32__
#include <stdint.h>
#endif

#ifdef _MSC_VER
#include <stdlib.h>
typedef __int64 int64_t;
typedef unsigned __int64 uint64_t;
#endif

#define MATH_INT64_NATIVE_IF_AVAILABLE

#include "perl_math_int64.h"

#define XXH_STATIC_LINKING_ONLY
#include "xxhash.h"

#define XXH_TYPE_XXH32 0
#define XXH_TYPE_XXH64 1
#define XXH_TYPE_XXH3_64 2
#define XXH_TYPE_XXH3_128 3

static const char hex_chars[16] = "0123456789abcdef";

#if defined(__GNUC__)
#define FORCE_INLINE static inline __attribute__((always_inline))
#elif defined(_MSC_VER)
#define FORCE_INLINE static inline __forceinline
#else
#define FORCE_INLINE static inline
#endif

FORCE_INLINE void write_hex32(char * buf, uint32_t val) {
    buf[0] = hex_chars[(val >> 28) & 0xf];
    buf[1] = hex_chars[(val >> 24) & 0xf];
    buf[2] = hex_chars[(val >> 20) & 0xf];
    buf[3] = hex_chars[(val >> 16) & 0xf];
    buf[4] = hex_chars[(val >> 12) & 0xf];
    buf[5] = hex_chars[(val >> 8) & 0xf];
    buf[6] = hex_chars[(val >> 4) & 0xf];
    buf[7] = hex_chars[(val) & 0xf];
}

FORCE_INLINE void write_hex64(char * buf, uint64_t val) {
    buf[0] = hex_chars[(val >> 60) & 0xf];
    buf[1] = hex_chars[(val >> 56) & 0xf];
    buf[2] = hex_chars[(val >> 52) & 0xf];
    buf[3] = hex_chars[(val >> 48) & 0xf];
    buf[4] = hex_chars[(val >> 44) & 0xf];
    buf[5] = hex_chars[(val >> 40) & 0xf];
    buf[6] = hex_chars[(val >> 36) & 0xf];
    buf[7] = hex_chars[(val >> 32) & 0xf];
    buf[8] = hex_chars[(val >> 28) & 0xf];
    buf[9] = hex_chars[(val >> 24) & 0xf];
    buf[10] = hex_chars[(val >> 20) & 0xf];
    buf[11] = hex_chars[(val >> 16) & 0xf];
    buf[12] = hex_chars[(val >> 12) & 0xf];
    buf[13] = hex_chars[(val >> 8) & 0xf];
    buf[14] = hex_chars[(val >> 4) & 0xf];
    buf[15] = hex_chars[(val) & 0xf];
}

#ifndef PERL_UNUSED_VAR
#define PERL_UNUSED_VAR(var) \
    if (0)                   \
    var = var
#endif

#ifndef dVAR
#define dVAR dNOOP
#endif

#undef XS_INTERNAL
#if defined(PERL_EUPXS_ALWAYS_EXPORT)
#define XS_INTERNAL(name) XS_EXTERNAL(name)
#else
#define XS_INTERNAL(name) XS(name)
#endif

#ifndef PERL_ARGS_ASSERT_CROAK_XS_USAGE
#define PERL_ARGS_ASSERT_CROAK_XS_USAGE \
    assert(cv);                         \
    assert(params)

STATIC void S_croak_xs_usage(const CV * const cv, const char * const params);

STATIC void S_croak_xs_usage(const CV * const cv, const char * const params) {
    const GV * const gv = CvGV(cv);
    PERL_ARGS_ASSERT_CROAK_XS_USAGE;
    if (gv) {
        const char * const gvname = GvNAME(gv);
        const HV * const stash = GvSTASH(gv);
        const char * const hvname = stash ? HvNAME(stash) : NULL;
        if (hvname)
            Perl_croak_nocontext("Usage: %s::%s(%s)", hvname, gvname, params);
        else
            Perl_croak_nocontext("Usage: %s(%s)", gvname, params);
    }
    else {
        Perl_croak_nocontext("Usage: CODE(0x%" UVxf ")(%s)", PTR2UV(cv), params);
    }
}
#undef PERL_ARGS_ASSERT_CROAK_XS_USAGE
#define croak_xs_usage S_croak_xs_usage
#endif

#ifdef newXS_flags
#define newXSproto_portable(name, c_impl, file) newXS_flags(name, c_impl, file, NULL, 0)
#else
#define newXSproto_portable(name, c_impl, file) (PL_Sv = (SV *)newXS(name, c_impl, file), (CV *)PL_Sv)
#endif

XS_INTERNAL(Digest_xxHash_xxhash32) {
    dXSARGS;
    if (items != 2)
        croak_xs_usage(cv, "input, seed");
    {
        dXSTARG;
        STRLEN len;
        const char * input = SvPV(ST(0), len);
        UV seed = SvUV(ST(1));
        TARGu((UV)XXH32(input, len, seed), 1);
        ST(0) = TARG;
    }
    XSRETURN(1);
}

XS_INTERNAL(Digest_xxHash_xxhash64) {
    dXSARGS;
    if (items != 2)
        croak_xs_usage(cv, "input, seed");
    {
        dXSTARG;
        STRLEN len;
        const char * input = SvPV(ST(0), len);
        UV seed = SvUV(ST(1));
        TARGu((UV)XXH64(input, len, seed), 1);
        ST(0) = TARG;
    }
    XSRETURN(1);
}

XS_INTERNAL(Digest_xxHash_xxh3_64) {
    dXSARGS;
    if (items != 2)
        croak_xs_usage(cv, "input, seed");
    {
        dXSTARG;
        STRLEN len;
        const char * input = SvPV(ST(0), len);
        UV seed = SvUV(ST(1));
        TARGu((UV)XXH3_64bits_withSeed(input, len, seed), 1);
        ST(0) = TARG;
    }
    XSRETURN(1);
}

XS_INTERNAL(Digest_xxHash_xxhash32_hex) {
    dXSARGS;
    if (items != 2)
        croak_xs_usage(cv, "input, seed");
    {
        dXSTARG;
        STRLEN len;
        const char * input = SvPV(ST(0), len);
        UV seed = SvUV(ST(1));
        char * buf;
        sv_setpvn(TARG, "", 0);
        buf = SvGROW(TARG, 9);
        write_hex32(buf, (uint32_t)XXH32(input, len, seed));
        SvCUR_set(TARG, 8);
        ST(0) = TARG;
    }
    XSRETURN(1);
}

XS_INTERNAL(Digest_xxHash_xxhash64_hex) {
    dXSARGS;
    if (items != 2)
        croak_xs_usage(cv, "input, seed");
    {
        dXSTARG;
        STRLEN len;
        const char * input = SvPV(ST(0), len);
        UV seed = SvUV(ST(1));
        char * buf;
        sv_setpvn(TARG, "", 0);
        buf = SvGROW(TARG, 17);
        write_hex64(buf, (uint64_t)XXH64(input, len, seed));
        SvCUR_set(TARG, 16);
        ST(0) = TARG;
    }
    XSRETURN(1);
}

XS_INTERNAL(Digest_xxHash_xxh3_64_hex) {
    dXSARGS;
    if (items != 2)
        croak_xs_usage(cv, "input, seed");
    {
        dXSTARG;
        STRLEN len;
        const char * input = SvPV(ST(0), len);
        UV seed = SvUV(ST(1));
        char * buf;
        sv_setpvn(TARG, "", 0);
        buf = SvGROW(TARG, 17);
        write_hex64(buf, (uint64_t)XXH3_64bits_withSeed(input, len, seed));
        SvCUR_set(TARG, 16);
        ST(0) = TARG;
    }
    XSRETURN(1);
}

XS_INTERNAL(Digest_xxHash_xxh3_128) {
    dXSARGS;
    if (items != 2)
        croak_xs_usage(cv, "input, seed");
    PERL_UNUSED_VAR(ax);
    SP -= items;
    {
        STRLEN len;
        const char * input = SvPV(ST(0), len);
        UV seed = SvUV(ST(1));
        XXH128_hash_t h = XXH3_128bits_withSeed(input, len, seed);
        XPUSHs(sv_2mortal(newSVu64(h.low64)));
        XPUSHs(sv_2mortal(newSVu64(h.high64)));
        PUTBACK;
        return;
    }
}

XS_INTERNAL(Digest_xxHash_xxh3_128_hex) {
    dXSARGS;
    if (items != 2)
        croak_xs_usage(cv, "input, seed");
    {
        dXSTARG;
        STRLEN len;
        const char * input = SvPV(ST(0), len);
        UV seed = SvUV(ST(1));
        XXH128_hash_t h = XXH3_128bits_withSeed(input, len, seed);
        char * buf;
        sv_setpvn(TARG, "", 0);
        buf = SvGROW(TARG, 33);
        write_hex64(buf, (uint64_t)h.high64);
        write_hex64(buf + 16, (uint64_t)h.low64);
        SvCUR_set(TARG, 32);
        ST(0) = TARG;
    }
    XSRETURN(1);
}

XS_INTERNAL(Digest_xxHash_xxh3_generate_secret_from_seed) {
    dXSARGS;
    if (items != 1)
        croak_xs_usage(cv, "seed");
    PERL_UNUSED_VAR(ax);
    SP -= items;
    {
        UV seed = SvUV(ST(0));
        unsigned char secret[XXH3_SECRET_DEFAULT_SIZE];
        XXH3_generateSecret_fromSeed(secret, seed);
        XPUSHs(sv_2mortal(newSVpvn((const char *)secret, XXH3_SECRET_DEFAULT_SIZE)));
        PUTBACK;
        return;
    }
}

/* ========================================================================
 * CONSOLIDATED INTERNAL API — no argument checks, type-dispatched in C
 * ======================================================================== */

XS_INTERNAL(Digest_xxHash_xxxh_create) {
    dXSARGS;
    dXSTARG;
    UV type_code = SvUV(ST(0));
    IV ctx;
    switch (type_code) {
    case XXH_TYPE_XXH32:
        ctx = PTR2IV(XXH32_createState());
        break;
    case XXH_TYPE_XXH64:
        ctx = PTR2IV(XXH64_createState());
        break;
    default:
        ctx = PTR2IV(XXH3_createState());
        break;
    }
    TARGi(ctx, 1);
    ST(0) = TARG;
    XSRETURN(1);
}

XS_INTERNAL(Digest_xxHash_xxxh_free) {
    dXSARGS;
    IV ctx = SvIV(ST(0));
    UV type_code = SvUV(ST(1));
    switch (type_code) {
    case XXH_TYPE_XXH32:
        XXH32_freeState(INT2PTR(XXH32_state_t *, ctx));
        break;
    case XXH_TYPE_XXH64:
        XXH64_freeState(INT2PTR(XXH64_state_t *, ctx));
        break;
    default:
        XXH3_freeState(INT2PTR(XXH3_state_t *, ctx));
        break;
    }
    XSRETURN_EMPTY;
}

XS_INTERNAL(Digest_xxHash_xxxh_copy) {
    dXSARGS;
    IV dst = SvIV(ST(0));
    IV src = SvIV(ST(1));
    UV type_code = SvUV(ST(2));
    switch (type_code) {
    case XXH_TYPE_XXH32:
        XXH32_copyState(INT2PTR(XXH32_state_t *, dst), INT2PTR(const XXH32_state_t *, src));
        break;
    case XXH_TYPE_XXH64:
        XXH64_copyState(INT2PTR(XXH64_state_t *, dst), INT2PTR(const XXH64_state_t *, src));
        break;
    default:
        XXH3_copyState(INT2PTR(XXH3_state_t *, dst), INT2PTR(const XXH3_state_t *, src));
        break;
    }
    XSRETURN_EMPTY;
}

XS_INTERNAL(Digest_xxHash_xxxh_reset) {
    dXSARGS;
    IV ctx = SvIV(ST(0));
    UV type_code = SvUV(ST(1));
    UV seed = SvUV(ST(2));
    switch (type_code) {
    case XXH_TYPE_XXH32:
        XXH32_reset(INT2PTR(XXH32_state_t *, ctx), (XXH32_hash_t)seed);
        break;
    case XXH_TYPE_XXH64:
        XXH64_reset(INT2PTR(XXH64_state_t *, ctx), seed);
        break;
    case XXH_TYPE_XXH3_64:
        XXH3_64bits_reset_withSeed(INT2PTR(XXH3_state_t *, ctx), seed);
        break;
    case XXH_TYPE_XXH3_128:
        XXH3_128bits_reset_withSeed(INT2PTR(XXH3_state_t *, ctx), seed);
        break;
    }
    XSRETURN_EMPTY;
}

XS_INTERNAL(Digest_xxHash_xxxh_reset_withSecret) {
    dXSARGS;
    IV ctx = SvIV(ST(0));
    UV type_code = SvUV(ST(1));
    STRLEN len;
    const char * secret = SvPV(ST(2), len);
    if (type_code == XXH_TYPE_XXH3_64)
        XXH3_64bits_reset_withSecret(INT2PTR(XXH3_state_t *, ctx), secret, len);
    else
        XXH3_128bits_reset_withSecret(INT2PTR(XXH3_state_t *, ctx), secret, len);
    XSRETURN_EMPTY;
}

XS_INTERNAL(Digest_xxHash_xxxh_update) {
    dXSARGS;
    IV ctx = SvIV(ST(0));
    STRLEN len;
    const char * input = SvPV(ST(1), len);
    UV type_code = SvUV(ST(2));
    switch (type_code) {
    case XXH_TYPE_XXH32:
        XXH32_update(INT2PTR(XXH32_state_t *, ctx), input, len);
        break;
    case XXH_TYPE_XXH64:
        XXH64_update(INT2PTR(XXH64_state_t *, ctx), input, len);
        break;
    case XXH_TYPE_XXH3_64:
        XXH3_64bits_update(INT2PTR(XXH3_state_t *, ctx), input, len);
        break;
    case XXH_TYPE_XXH3_128:
        XXH3_128bits_update(INT2PTR(XXH3_state_t *, ctx), input, len);
        break;
    }
    XSRETURN_EMPTY;
}

XS_INTERNAL(Digest_xxHash_xxxh_digest) {
    dXSARGS;
    IV ctx = SvIV(ST(0));
    UV type_code = SvUV(ST(1));
#if !MATH_INT64_NATIVE
    PERL_MATH_INT64_LOAD;
#endif
    switch (type_code) {
    case XXH_TYPE_XXH32:
        ST(0) = sv_2mortal(newSVuv((UV)XXH32_digest(INT2PTR(const XXH32_state_t *, ctx))));
        break;
    case XXH_TYPE_XXH64:
        ST(0) = sv_2mortal(newSVu64(XXH64_digest(INT2PTR(const XXH64_state_t *, ctx))));
        break;
    case XXH_TYPE_XXH3_64:
        ST(0) = sv_2mortal(newSVu64(XXH3_64bits_digest(INT2PTR(const XXH3_state_t *, ctx))));
        break;
    case XXH_TYPE_XXH3_128:
        {
            XXH128_hash_t h = XXH3_128bits_digest(INT2PTR(const XXH3_state_t *, ctx));
            char buf[16];
            memcpy(buf, &h.low64, 8);
            memcpy(buf + 8, &h.high64, 8);
            ST(0) = sv_2mortal(newSVpvn(buf, 16));
            break;
        }
    }
    XSRETURN(1);
}

XS_INTERNAL(Digest_xxHash_xxxh_hex) {
    dXSARGS;
    dXSTARG;
    IV ctx = SvIV(ST(0));
    UV type_code = SvUV(ST(1));
    sv_setpvn(TARG, "", 0);
    switch (type_code) {
    case XXH_TYPE_XXH32:
        {
            char * buf = SvGROW(TARG, 9);
            write_hex32(buf, (uint32_t)XXH32_digest(INT2PTR(const XXH32_state_t *, ctx)));
            SvCUR_set(TARG, 8);
            break;
        }
    case XXH_TYPE_XXH64:
        {
            char * buf = SvGROW(TARG, 17);
            write_hex64(buf, (uint64_t)XXH64_digest(INT2PTR(const XXH64_state_t *, ctx)));
            SvCUR_set(TARG, 16);
            break;
        }
    case XXH_TYPE_XXH3_64:
        {
            char * buf = SvGROW(TARG, 17);
            write_hex64(buf, (uint64_t)XXH3_64bits_digest(INT2PTR(const XXH3_state_t *, ctx)));
            SvCUR_set(TARG, 16);
            break;
        }
    case XXH_TYPE_XXH3_128:
        {
            XXH128_hash_t h = XXH3_128bits_digest(INT2PTR(const XXH3_state_t *, ctx));
            char * buf = SvGROW(TARG, 33);
            write_hex64(buf, (uint64_t)h.high64);
            write_hex64(buf + 16, (uint64_t)h.low64);
            SvCUR_set(TARG, 32);
            break;
        }
    }
    ST(0) = TARG;
    XSRETURN(1);
}

void boot_Digest__xxHash(pTHX_ CV * cv) {
    dVAR;
    dXSBOOTARGSXSAPIVERCHK;
    PERL_UNUSED_VAR(cv);
    PERL_UNUSED_VAR(items);

    (void)newXSproto_portable("Digest::xxHash::xxhash32", Digest_xxHash_xxhash32, __FILE__);
    (void)newXSproto_portable("Digest::xxHash::xxhash64", Digest_xxHash_xxhash64, __FILE__);
    (void)newXSproto_portable("Digest::xxHash::xxh3_64", Digest_xxHash_xxh3_64, __FILE__);
    (void)newXSproto_portable("Digest::xxHash::xxhash32_hex", Digest_xxHash_xxhash32_hex, __FILE__);
    (void)newXSproto_portable("Digest::xxHash::xxhash64_hex", Digest_xxHash_xxhash64_hex, __FILE__);
    (void)newXSproto_portable("Digest::xxHash::xxh3_64_hex", Digest_xxHash_xxh3_64_hex, __FILE__);
    (void)newXSproto_portable("Digest::xxHash::xxh3_128", Digest_xxHash_xxh3_128, __FILE__);
    (void)newXSproto_portable("Digest::xxHash::xxh3_128_hex", Digest_xxHash_xxh3_128_hex, __FILE__);
    (void)newXSproto_portable(
        "Digest::xxHash::xxh3_generate_secret_from_seed", Digest_xxHash_xxh3_generate_secret_from_seed, __FILE__);
    (void)newXSproto_portable("Digest::xxHash::_xxxh_create", Digest_xxHash_xxxh_create, __FILE__);
    (void)newXSproto_portable("Digest::xxHash::_xxxh_free", Digest_xxHash_xxxh_free, __FILE__);
    (void)newXSproto_portable("Digest::xxHash::_xxxh_copy", Digest_xxHash_xxxh_copy, __FILE__);
    (void)newXSproto_portable("Digest::xxHash::_xxxh_reset", Digest_xxHash_xxxh_reset, __FILE__);
    (void)newXSproto_portable("Digest::xxHash::_xxxh_reset_withSecret", Digest_xxHash_xxxh_reset_withSecret, __FILE__);
    (void)newXSproto_portable("Digest::xxHash::_xxxh_update", Digest_xxHash_xxxh_update, __FILE__);
    (void)newXSproto_portable("Digest::xxHash::_xxxh_digest", Digest_xxHash_xxxh_digest, __FILE__);
    (void)newXSproto_portable("Digest::xxHash::_xxxh_hex", Digest_xxHash_xxxh_hex, __FILE__);
    Perl_xs_boot_epilog(aTHX_ ax);
}
