/* -*- Mode: C -*- */

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_sv_2pvbyte
#define NEED_sv_2pv_flags
#include "ppport.h"

static int may_die_on_overflow;
static int may_use_native;

#ifdef HAS_STDINT_H
#include <stdint.h>
#endif

#define NV_0x1p15 ((NV)32768)
#define NV_0x1p16 ((NV)65536)
#define NV_0x1p31 (NV_0x1p16 * NV_0x1p15)
#define NV_0x1p32 (NV_0x1p16 * NV_0x1p16)
#define NV_0x1p63 (NV_0x1p32 * NV_0x1p31)
#define NV_0x1p64 (NV_0x1p32 * NV_0x1p32)

#ifdef _MSC_VER
#include <stdlib.h>

#ifndef INT64_MAX
#define INT64_MAX _I64_MAX
#endif
#ifndef INT64_MIN
#define INT64_MIN _I64_MIN
#endif
#ifndef UINT64_MAX
#define UINT64_MAX _UI64_MAX
#endif
#ifndef UINT32_MAX
#define UINT32_MAX _UI32_MAX
#endif

#endif

#ifdef USE_INT64_T
/* do nothing */

#elif defined(USE___INT64)
typedef __int64 int64_t;
typedef unsigned __int64 uint64_t;

#elif defined(USE_INT64_DI)
typedef int int64_t __attribute__ ((__mode__ (DI)));
typedef unsigned int uint64_t __attribute__ ((__mode__ (DTI)));

#else
#error "No int64 type define was passed to the compiler!"
#endif

#if ((defined _MSC_VER) || (defined INT64_MY_NV2U64))

/* Old MS compilers do not implement the double->uint64 conversion and
 * silently do a double->int64 conversion instead. See
 * http://connect.microsoft.com/VisualStudio/feedback/details/270762/error-in-converting-double-to-unsigned-long-long */

/* I don't trust atof, so I generate 2**-32 from simpler constants and
 * hope the optimizer will do its work properly */

#define NV_0x1p_4 ((NV)0.0625)
#define NV_0x1p_16 (NV_0x1p_4 * NV_0x1p_4 * NV_0x1p_4 * NV_0x1p_4)
#define NV_0x1p_32 (NV_0x1p_16 * NV_0x1p_16)

static uint64_t
nv2u64(NV nv) {
    if ((nv > 0.0) && (nv < NV_0x1p64)) {
        uint64_t h = nv * NV_0x1p_32;
        uint64_t l = nv - (NV)(int64_t)h * NV_0x1p32;
        return ((h << 32) + l);
    }
    return 0;
}
#define NV2U64(nv) nv2u64(nv)

#  if defined(_MSC_VER) && _MSC_VER >= 1300
#    define U642NV(u64) ((NV)(u64))
#  else
static NV
u642nv(uint64_t u64) {
    unsigned long h = u64 >> 32;
    unsigned long l = u64 & 0xffffffff;
    return (NV_0x1p32 * h) + (NV)l;
}
#    define U642NV(nv) u642nv(nv)
#  endif
#else
#define NV2U64(nv) ((uint64_t)(nv))
#define U642NV(u64) ((NV)(u64))
#endif

#if (PERL_VERSION >= 10)

#ifndef cop_hints_fetch_pvs
#define cop_hints_fetch_pvs(cop, key, flags) \
    Perl_refcounted_he_fetch(aTHX_ (cop)->cop_hints_hash, NULL, STR_WITH_LEN(key), (flags), 0)
#endif

static int
check_die_on_overflow_hint(pTHX) {
    SV *hint = cop_hints_fetch_pvs(PL_curcop, "Math::Int64::die_on_overflow", 0);
    return (hint && SvTRUE(hint));
}

static int
check_use_native_hint(pTHX) {
    SV *hint = cop_hints_fetch_pvs(PL_curcop, "Math::Int64::native_if_available", 0);
    return (hint && SvTRUE(hint));
}

#define use_native (may_use_native && check_use_native_hint(aTHX))

#else

static int
check_die_on_overflow_hint(pTHX) {
    return 1;
}

static int
check_use_native_hint(pTHX) {
    return 1;
}

#define use_native may_use_native

#endif

static void
overflow(pTHX_ const char *msg) {
    if (check_die_on_overflow_hint(aTHX))
        Perl_croak(aTHX_ "Math::Int64 overflow: %s", msg);
}

static const char *out_of_bounds_error_s  = "Number is out of bounds for int64_t conversion";
static const char *out_of_bounds_error_u  = "Number is out of bounds for uint64_t conversion";
static const char *mul_error              = "Multiplication overflows";
static const char *add_error              = "Addition overflows";
static const char *sub_error              = "Subtraction overflows";
static const char *inc_error              = "Increment operation wraps";
static const char *dec_error              = "Decrement operation wraps";
static const char *div_by_0_error         = "Illegal division by zero";
static const char *pow_error              = "Exponentiation overflows";
static const char *invalid_length_error_s = "Invalid length for int64";
static const char *invalid_length_error_u = "Invalid length for uint64";
static const char *invalid_BER_error      = "Invalid BER encoding";

static void croak_string(pTHX_ const char *str) {
    Perl_croak(aTHX_ "%s", str);
}

#include "strtoint64.h"
#include "isaac64.h"

#define MY_CXT_KEY "Math::Int64::isaac64_state" XS_VERSION
typedef struct {
    isaac64_state_t is;
} my_cxt_t;
START_MY_CXT

#if defined(INT64_BACKEND_NV)
#  define BACKEND "NV"
#  define SvI64Y SvNVX
#  define SvI64_onY SvNOK_on
#  define SVt_I64 SVt_NV
#elif defined(INT64_BACKEND_IV)
#  define BACKEND "IV"
#  define SvI64Y SvIVX
#  define SvI64_onY SvIOK_on
#  define SVt_I64 SVt_IV
#else
#  error "unsupported backend"
#endif

static int
SvI64OK(pTHX_ SV *sv) {
    if (SvROK(sv)) {
        SV *si64 = SvRV(sv);
        return (si64 && (SvTYPE(si64) >= SVt_I64) && sv_isa(sv, "Math::Int64"));
    }
    return 0;
}

static int
SvU64OK(pTHX_ SV *sv) {
    if (SvROK(sv)) {
        SV *su64 = SvRV(sv);
        return (su64 && (SvTYPE(su64) >= SVt_I64) && sv_isa(sv, "Math::UInt64"));
    }
    return 0;
}

static SV *
newSVi64(pTHX_ int64_t i64) {
    SV *sv;
    SV *si64 = newSV(0);
    SvUPGRADE(si64, SVt_I64);
    SvI64_onY(si64);
    sv = newRV_noinc(si64);
    sv_bless(sv, gv_stashpvs("Math::Int64", TRUE));
    *(int64_t*)(&(SvI64Y(si64))) = i64;
    SvREADONLY_on(si64);
    return sv;
}

static SV *
newSVu64(pTHX_ uint64_t u64) {
    SV *sv;
    SV *su64 = newSV(0);
    SvUPGRADE(su64, SVt_I64);
    SvI64_onY(su64);
    sv = newRV_noinc(su64);
    sv_bless(sv, gv_stashpvs("Math::UInt64", TRUE));
    *(int64_t*)(&(SvI64Y(su64))) = u64;
    SvREADONLY_on(su64);
    return sv;
}

#define SvI64X(sv) (*(int64_t*)(&(SvI64Y(SvRV(sv)))))
#define SvU64X(sv) (*(uint64_t*)(&(SvI64Y(SvRV(sv)))))

static SV *
SvSI64(pTHX_ SV *sv) {
    if (SvROK(sv)) {
        SV *si64 = SvRV(sv);
        if (si64 && (SvTYPE(si64) >= SVt_I64))
            return si64;
    }
    croak_string(aTHX_ "internal error: reference to NV expected");
    return NULL; /* this dead code is a workaround for OpenWatcom */
}

static SV *
SvSU64(pTHX_ SV *sv) {
    if (SvROK(sv)) {
        SV *su64 = SvRV(sv);
        if (su64 && (SvTYPE(su64) >= SVt_I64))
            return su64;
    }
    croak_string(aTHX_ "internal error: reference to NV expected");
    return NULL; /* this dead code is a workaround for OpenWatcom */
}

#define SvI64x(sv) (*(int64_t*)(&(SvI64Y(SvSI64(aTHX_ sv)))))
#define SvU64x(sv) (*(uint64_t*)(&(SvI64Y(SvSU64(aTHX_ sv)))))

static int64_t
SvI64(pTHX_ SV *sv) {
    if (SvROK(sv)) {
        SV *si64 = SvRV(sv);
        if (si64 && SvOBJECT(si64)) {
            GV *method;
            HV *stash = SvSTASH(si64);
            char const * classname = HvNAME_get(stash);
            if (memcmp(classname, "Math::", 6) == 0) {
                int u;
                if (classname[6] == 'U') {
                    u = 1;
                    classname += 7;
                }
                else {
                    u = 0;
                    classname += 6;
                }
                if (memcmp(classname, "Int64", 6) == 0) {
                    if (SvTYPE(si64) < SVt_I64)
                        Perl_croak(aTHX_ "Wrong internal representation for %s object", HvNAME_get(stash));
                    if (u) {
                        uint64_t u = *(uint64_t*)(&(SvI64Y(si64)));
                        if (may_die_on_overflow && (u > INT64_MAX)) overflow(aTHX_ out_of_bounds_error_s);
                        return u;
                    }
                    else {
                        return *(int64_t*)(&(SvI64Y(si64)));
                    }
                }
            }
            method = gv_fetchmethod(stash, "as_int64");
            if (method) {
                SV *result;
                int count;
                dSP;
                ENTER;
                SAVETMPS;
                PUSHSTACKi(PERLSI_MAGIC);
                PUSHMARK(SP);
                XPUSHs(sv);
                PUTBACK;
                count = perl_call_sv( (SV*)method, G_SCALAR );
                SPAGAIN;
                if (count != 1)
                    Perl_croak(aTHX_ "internal error: method call returned %d values, 1 expected", count);
                result = newSVsv(POPs);
                PUTBACK;
                POPSTACK;
                SPAGAIN;
                FREETMPS;
                LEAVE;
                return SvI64(aTHX_ sv_2mortal(result));
            }
        }
    }
    else {
        SvGETMAGIC(sv);
        if (SvIOK(sv)) {
            if (SvIOK_UV(sv)) {
                UV uv = SvUV(sv);
                if (may_die_on_overflow &&
                    (uv > INT64_MAX)) overflow(aTHX_ out_of_bounds_error_s);
                return uv;
            }
            return SvIV(sv);
        }
        if (SvNOK(sv)) {
            NV nv = SvNV(sv);
            if ( may_die_on_overflow &&
                 ((nv >= NV_0x1p63) || (nv < -NV_0x1p63)) ) overflow(aTHX_ out_of_bounds_error_s);
            return nv;
        }
    }
    return strtoint64(aTHX_ SvPV_nolen(sv), 10, 1);
}

static uint64_t
SvU64(pTHX_ SV *sv) {
    if (SvROK(sv)) {
        SV *su64 = SvRV(sv);
        if (su64 && SvOBJECT(su64)) {
            GV *method;
            HV *stash = SvSTASH(su64);
            char const * classname = HvNAME_get(stash);
            if (memcmp(classname, "Math::", 6) == 0) {
                int u;
                if (classname[6] == 'U') {
                    u = 1;
                    classname += 7;
                }
                else {
                    u = 0;
                    classname += 6;
                }
                if (memcmp(classname, "Int64", 6) == 0) {
                    if (SvTYPE(su64) < SVt_I64)
                        Perl_croak(aTHX_ "Wrong internal representation for %s object", HvNAME_get(stash));
                    if (u) {
                        return *(uint64_t*)(&(SvI64Y(su64)));
                    }
                    else {
                        int64_t i = *(int64_t*)(&(SvI64Y(su64)));
                        if (may_die_on_overflow && (i < 0)) overflow(aTHX_ out_of_bounds_error_u);
                        return i;
                    }
                }
            }
            method = gv_fetchmethod(SvSTASH(su64), "as_uint64");
            if (method) {
                SV *result;
                int count;
                dSP;
                ENTER;
                SAVETMPS;
                PUSHSTACKi(PERLSI_MAGIC);
                PUSHMARK(SP);
                XPUSHs(sv);
                PUTBACK;
                count = perl_call_sv( (SV*)method, G_SCALAR );
                SPAGAIN;
                if (count != 1)
                    Perl_croak(aTHX_ "internal error: method call returned %d values, 1 expected", count);
                result = newSVsv(POPs);
                PUTBACK;
                POPSTACK;
                SPAGAIN;
                FREETMPS;
                LEAVE;
                return SvU64(aTHX_ sv_2mortal(result));
            }
        }
    }
    else {
        SvGETMAGIC(sv);
        if (SvIOK(sv)) {
            if (SvIOK_UV(sv)) {
                return SvUV(sv);
            }
            else {
                IV iv = SvIV(sv);
                if (may_die_on_overflow &&
                    (iv < 0) ) overflow(aTHX_ out_of_bounds_error_u);
                return SvIV(sv);
            }
        }
        if (SvNOK(sv)) {
            NV nv = SvNV(sv);
            if (may_die_on_overflow &&
                ( (nv < 0) || (nv >= NV_0x1p64)) ) overflow(aTHX_ out_of_bounds_error_u);
            return NV2U64(nv);
        }
    }
    return strtoint64(aTHX_ SvPV_nolen(sv), 10, 0);
}

static SV *
si64_to_number(pTHX_ SV *sv) {
    int64_t i64 = SvI64(aTHX_ sv);
    if (i64 < 0) {
        IV iv = i64;
        if (iv == i64)
            return newSViv(iv);
    }
    else {
        UV uv = i64;
        if (uv == i64)
            return newSVuv(uv);
    }
    return newSVnv(i64);
}

static SV *
su64_to_number(pTHX_ SV *sv) {
    uint64_t u64 = SvU64(aTHX_ sv);
    UV uv = u64;
    if (uv == u64)
        return newSVuv(uv);
    return newSVnv(U642NV(u64));
}

#define I64STRLEN 65

static SV *
u64_to_string_with_sign(pTHX_ uint64_t u64, int base, int sign) {
    char str[I64STRLEN];
    int len = 0;
    if ((base > 36) || (base < 2))
        Perl_croak(aTHX_ "base %d out of range [2,36]", base);
    while (u64) {
        char c = u64 % base;
        u64 /= base;
        str[len++] = c + (c > 9 ? 'A' - 10 : '0');
    }
    if (len) {
        int i;
        int svlen = len + (sign ? 1 : 0);
        SV *sv = newSV(svlen);
        char *pv = SvPVX(sv);
        SvPOK_on(sv);
        SvCUR_set(sv, svlen);
        if (sign) *(pv++) = '-';
        for (i = len; i--;) *(pv++) = str[i];
        *pv = '\0';
        return sv;
    }
    else {
        return newSVpvs("0");
    }
}

static SV *
i64_to_string(pTHX_ int64_t i64, int base) {
    if (i64 < 0) {    
        return u64_to_string_with_sign(aTHX_ -i64, base, 1);
    }
    return u64_to_string_with_sign(aTHX_ i64, base, 0);
}

static uint64_t
randU64(pTHX) {
    dMY_CXT;
    return rand64(&(MY_CXT.is));
}

static void
mul_check_overflow(pTHX_ uint64_t a, uint64_t b, const char *error_str) {
    if (a < b) {
        uint64_t tmp = a;
        a = b; b = tmp;
    }
    if (b > UINT32_MAX) overflow(aTHX_ error_str);
    else {
        uint64_t rl, rh;
        rl = (a & UINT32_MAX) * b;
        rh = (a >> 32) * b + (rl >> 32);
        if (rh > UINT32_MAX) overflow(aTHX_ error_str);
    }
}

static uint64_t
powU64(pTHX_ uint64_t a, uint64_t b) {
    uint64_t r;
    int mdoo = may_die_on_overflow;
    if (b == 0) return 1;
    if (b == 1) return a;
    if (b == 2) {
        if (mdoo && (a > UINT32_MAX)) overflow(aTHX_ pow_error);
        return a*a;
    }
    if (a == 0) return 0;
    if (a == 1) return 1;
    if (a == 2) {
        if (b > 63) {
            if (mdoo) overflow(aTHX_ pow_error);
            return 0;
        }
        return (((uint64_t)1) << b);
    }
    if (mdoo) {
        r = ((b & 1) ? a : 1);
        while ((b >>= 1)) {
            if (a > UINT32_MAX) overflow(aTHX_ pow_error);
            a *= a;
            if (b & 1) {
                mul_check_overflow(aTHX_ r, a, pow_error);
                r *= a;
            }
        }
    }
    else {
        r = 1;
        while (b) {
            if (b & 1) r *= a;
            a *= a;
            b >>= 1;
        }
    }
    return r;
}

static SV *
uint64_to_BER(pTHX_ uint64_t a) {
    char buffer[10];
    char *top = buffer + sizeof(buffer);
    char *p = top;
    *(--p) = (a & 0x7f);
    while ((a >>= 7)) {
        *(--p) = (a & 0x7f) | 0x80;

    }
    return newSVpvn(p, top - p);
}

static SV *
int64_to_BER(pTHX_ int64_t a) {
    return uint64_to_BER(aTHX_
                         a < 0
                         ? ( ( ( ~(uint64_t)a) << 1 ) | 1 )
                         : ( ( (  (uint64_t)a) << 1 ) | 0 ) );
}

static uint64_t
BER_to_uint64(pTHX_ SV *sv) {
    STRLEN len;
    char *pv = SvPVbyte(sv, len);
    uint64_t a;
    IV i;
    for (i = 0, a = 0; i < len; i++) {
        if (may_die_on_overflow && (a > (((uint64_t)1) << (63 - 7))))
            overflow(aTHX_ out_of_bounds_error_u);
        a = (a << 7) | (pv[i] & 0x7f);
        if ((pv[i] & 0x80) == 0) {
            if (i + 1 != len) croak_string(aTHX_ invalid_BER_error);
            return a;
        }
    }
    croak_string(aTHX_ invalid_BER_error);
    return 0; /* this dead code is a workaround for OpenWatcom */
}

static int64_t
BER_to_int64(pTHX_ SV *sv) {
    uint64_t a = BER_to_uint64(aTHX_ sv);
    int64_t b = (int64_t)(a >> 1);
    return (a & 1 ? ~b : b);
}

static IV
BER_length(pTHX_ SV *sv) {
    STRLEN len;
    char *pv = SvPVbyte(sv, len);
    IV i;
    for (i = 0; i < len; i++) {
      if ((pv[i] & 0x80) == 0) return i + 1;
    }
    return -1;
}

#include "c_api.h"

MODULE = Math::Int64		PACKAGE = Math::Int64		PREFIX=miu64_
PROTOTYPES: DISABLE

BOOT:
{
    MY_CXT_INIT;
    randinit(&(MY_CXT.is), 0);
    may_die_on_overflow = 0;
    may_use_native = 0;
    INIT_C_API;
}

char *
miu64__backend()
CODE:
    RETVAL = BACKEND;
OUTPUT:
    RETVAL

void
miu64__set_may_die_on_overflow(v)
    int v
CODE:
    may_die_on_overflow = v;

void
miu64__set_may_use_native(v)
    int v;
CODE:
    may_use_native = v;

SV *
miu64_int64(value=&PL_sv_undef)
    SV *value;
CODE:
    RETVAL = (use_native
              ? newSViv(SvIV(value))
              : newSVi64(aTHX_ SvI64(aTHX_ value)));
OUTPUT:
    RETVAL

SV *
miu64_uint64(value=&PL_sv_undef)
    SV *value;
CODE:
    RETVAL = (use_native
              ? newSVuv(SvUV(value))
              : newSVu64(aTHX_ SvU64(aTHX_ value)));
OUTPUT:
    RETVAL

SV *
miu64_int64_to_number(self)
    SV *self
CODE:
    RETVAL = si64_to_number(aTHX_ self);
OUTPUT:
    RETVAL

SV *
miu64_uint64_to_number(self)
    SV *self
CODE:
    RETVAL = su64_to_number(aTHX_ self);
OUTPUT:
    RETVAL

SV *
miu64_net_to_int64(net)
    SV *net;
PREINIT:
    STRLEN len;
    unsigned char *pv = (unsigned char *)SvPVbyte(net, len);
    int64_t i64;
CODE:
    if (len != 8) croak_string(aTHX_ invalid_length_error_s);
    i64 = (((((((((((((((int64_t)pv[0]) << 8)
                      + (int64_t)pv[1]) << 8)
                    + (int64_t)pv[2]) << 8)
                  + (int64_t)pv[3]) << 8)
                + (int64_t)pv[4]) << 8)
              + (int64_t)pv[5]) << 8)
            + (int64_t)pv[6]) <<8)
        + (int64_t)pv[7];
    RETVAL = ( use_native
               ? newSViv(i64)
               : newSVi64(aTHX_ i64) );
OUTPUT:
    RETVAL

SV *
miu64_net_to_uint64(net)
    SV *net;
PREINIT:
    STRLEN len;
    unsigned char *pv = (unsigned char *)SvPVbyte(net, len);
    uint64_t u64;
CODE:
    if (len != 8)
        croak_string(aTHX_ invalid_length_error_u);
    u64 = (((((((((((((((uint64_t)pv[0]) << 8)
                      + (uint64_t)pv[1]) << 8)
                    + (uint64_t)pv[2]) << 8)
                  + (uint64_t)pv[3]) << 8)
                + (uint64_t)pv[4]) << 8)
              + (uint64_t)pv[5]) << 8)
            + (uint64_t)pv[6]) <<8)
        + (uint64_t)pv[7];
    RETVAL = ( use_native
               ? newSVuv(u64)
               : newSVu64(aTHX_ u64) );
OUTPUT:
    RETVAL

SV *
miu64_le_to_int64(net)
    SV *net;
PREINIT:
    STRLEN len;
    unsigned char *pv = (unsigned char *)SvPVbyte(net, len);
    int64_t i64;
CODE:
    if (len != 8) croak_string(aTHX_ invalid_length_error_s);
    i64 = (((((((((((((((int64_t)pv[7]) << 8)
                      + (int64_t)pv[6]) << 8)
                    + (int64_t)pv[5]) << 8)
                  + (int64_t)pv[4]) << 8)
                + (int64_t)pv[3]) << 8)
              + (int64_t)pv[2]) << 8)
            + (int64_t)pv[1]) <<8)
        + (int64_t)pv[0];
    RETVAL = ( use_native
              ? newSViv(i64)
              : newSVi64(aTHX_ i64) );
OUTPUT:
    RETVAL

SV *
miu64_le_to_uint64(net)
    SV *net;
PREINIT:
    STRLEN len;
    unsigned char *pv = (unsigned char *)SvPVbyte(net, len);
    uint64_t u64;
CODE:
    if (len != 8)
        croak_string(aTHX_ invalid_length_error_u);
    u64 = (((((((((((((((uint64_t)pv[7]) << 8)
                      + (uint64_t)pv[6]) << 8)
                    + (uint64_t)pv[5]) << 8)
                  + (uint64_t)pv[4]) << 8)
                + (uint64_t)pv[3]) << 8)
              + (uint64_t)pv[2]) << 8)
            + (uint64_t)pv[1]) <<8)
        + (uint64_t)pv[0];
    RETVAL = ( use_native
              ? newSVuv(u64)
              : newSVu64(aTHX_ u64) );
OUTPUT:
    RETVAL

SV *
miu64_int64_to_net(self)
    SV *self
PREINIT:
    char *pv;
    int64_t i64 = SvI64(aTHX_ self);
    int i;
CODE:
    RETVAL = newSV(8);
    SvPOK_on(RETVAL);
    SvCUR_set(RETVAL, 8);
    pv = SvPVX(RETVAL);
    pv[8] = '\0';
    for (i = 7; i >= 0; i--, i64 >>= 8)
        pv[i] = i64;
OUTPUT:
    RETVAL

SV *
miu64_uint64_to_net(self)
    SV *self
PREINIT:
    char *pv;
    uint64_t u64 = SvU64(aTHX_ self);
    int i;
CODE:
    RETVAL = newSV(8);
    SvPOK_on(RETVAL);
    SvCUR_set(RETVAL, 8);
    pv = SvPVX(RETVAL);
    pv[8] = '\0';
    for (i = 7; i >= 0; i--, u64 >>= 8)
        pv[i] = u64;
OUTPUT:
    RETVAL

SV *
miu64_int64_to_le(self)
    SV *self
PREINIT:
    char *pv;
    int64_t i64 = SvI64(aTHX_ self);
    int i;
CODE:
    RETVAL = newSV(8);
    SvPOK_on(RETVAL);
    SvCUR_set(RETVAL, 8);
    pv = SvPVX(RETVAL);
    pv[8] = '\0';
    for (i = 0; i <= 7; i++, i64 >>= 8)
        pv[i] = i64;
OUTPUT:
    RETVAL

SV *
miu64_uint64_to_le(self)
    SV *self
PREINIT:
    char *pv;
    uint64_t u64 = SvU64(aTHX_ self);
    int i;
CODE:
    RETVAL = newSV(8);
    SvPOK_on(RETVAL);
    SvCUR_set(RETVAL, 8);
    pv = SvPVX(RETVAL);
    pv[8] = '\0';
    for (i = 0; i <= 7; i++, u64 >>= 8)
        pv[i] = u64;
OUTPUT:
    RETVAL

SV *
miu64_BER_to_int64(ber)
    SV *ber
CODE:
    RETVAL = newSVi64(aTHX_ BER_to_int64(aTHX_ ber));
OUTPUT:
    RETVAL

SV *
miu64_BER_to_uint64(ber)
    SV *ber
CODE:
    RETVAL = newSVu64(aTHX_ BER_to_uint64(aTHX_ ber));
OUTPUT:
    RETVAL

SV *
miu64_int64_to_BER(self)
    SV *self
CODE:
    RETVAL = int64_to_BER(aTHX_ SvI64(aTHX_ self));
OUTPUT:
    RETVAL

SV *
miu64_uint64_to_BER(self)
    SV *self
CODE:
    RETVAL = uint64_to_BER(aTHX_ SvU64(aTHX_ self));
OUTPUT:
    RETVAL

SV *
miu64_native_to_int64(native)
    SV *native
PREINIT:
    STRLEN len;
    char *pv = SvPVbyte(native, len);
CODE:
    if (len != 8)
        croak_string(aTHX_ invalid_length_error_s);
    if (use_native) {
        RETVAL = newSViv(0);
        Copy(pv, &(SvIVX(RETVAL)), 8, char);
    }
    else {
        RETVAL = newSVi64(aTHX_ 0);
        Copy(pv, &(SvI64X(RETVAL)), 8, char);
    }
OUTPUT:
    RETVAL

SV *
BER_length(sv)
    SV *sv
PREINIT:
    IV len;
CODE:
    len = BER_length(aTHX_ sv);
    RETVAL = (len < 0 ? &PL_sv_undef : newSViv(len));
OUTPUT:
    RETVAL

SV *
miu64_native_to_uint64(native)
    SV *native
PREINIT:
    STRLEN len;
    char *pv = SvPVbyte(native, len);
CODE:
    if (len != 8)
        croak_string(aTHX_ invalid_length_error_u);
    if (use_native) {
        uint64_t tmp;
        Copy(pv, &tmp, 8, char);
        RETVAL = newSVuv(tmp);
    }
    else {
        RETVAL = newSVu64(aTHX_ 0);
        Copy(pv, &(SvU64X(RETVAL)), 8, char);
    }
OUTPUT:
    RETVAL

SV *
miu64_int64_to_native(self)
    SV *self
PREINIT:
    char *pv;
    int64_t i64 = SvI64(aTHX_ self);
CODE:
    RETVAL = newSV(9);
    SvPOK_on(RETVAL);
    SvCUR_set(RETVAL, 8);
    pv = SvPVX(RETVAL);
    Copy(&i64, pv, 8, char);
    pv[8] = '\0';
OUTPUT:
    RETVAL

SV *
miu64_uint64_to_native(self)
    SV *self
PREINIT:
    char *pv;
    uint64_t u64 = SvU64(aTHX_ self);
CODE:
    RETVAL = newSV(9);
    SvPOK_on(RETVAL);
    SvCUR_set(RETVAL, 8);
    pv = SvPVX(RETVAL);
    Copy(&u64, pv, 8, char);
    pv[8] = '\0';
OUTPUT:
    RETVAL

SV *
miu64_int64_to_string(self, base = 10)
    SV *self
    int base
CODE:
    RETVAL = i64_to_string(aTHX_ SvI64(aTHX_ self), base);
OUTPUT:
    RETVAL

SV *
miu64_uint64_to_string(self, base = 10)
    SV *self
    int base
CODE:
    RETVAL = u64_to_string_with_sign(aTHX_ SvU64(aTHX_ self), base, 0);
OUTPUT:
    RETVAL

SV *
miu64_int64_to_hex(self)
    SV *self
CODE:
    RETVAL = i64_to_string(aTHX_ SvI64(aTHX_ self), 16);
OUTPUT:
    RETVAL

SV *
miu64_uint64_to_hex(self)
    SV *self
CODE:
    RETVAL = u64_to_string_with_sign(aTHX_ SvU64(aTHX_ self), 16, 0);
OUTPUT:
    RETVAL

SV *
miu64_string_to_int64(str, base = 0)
    const char *str;
    int base;
CODE:
    RETVAL = ( use_native
               ? newSViv(strtoint64(aTHX_ str, base, 1))
               : newSVi64(aTHX_ strtoint64(aTHX_ str, base, 1)) );
OUTPUT:
    RETVAL

SV *
miu64_string_to_uint64(str, base = 0)
    const char *str;
    int base;
CODE:
    RETVAL = ( use_native
               ? newSVuv(strtoint64(aTHX_ str, base, 0))
               : newSVu64(aTHX_ strtoint64(aTHX_ str, base, 0)) );
OUTPUT:
    RETVAL

SV *
miu64_hex_to_int64(str)
    const char *str;
CODE:
    RETVAL = ( use_native
               ? newSViv(strtoint64(aTHX_ str, 16, 1))
               : newSVi64(aTHX_ strtoint64(aTHX_ str, 16, 1)) );
OUTPUT:
    RETVAL

SV *
miu64_hex_to_uint64(str)
    const char *str;
CODE:
    RETVAL = ( use_native
               ? newSVuv(strtoint64(aTHX_ str, 16, 0))
               : newSVu64(aTHX_ strtoint64(aTHX_ str, 16, 0)) );
OUTPUT:
    RETVAL


SV *
miu64_int64_rand()
PREINIT:
    dMY_CXT;
    int64_t i64 = rand64(&(MY_CXT.is));
CODE:
    RETVAL = ( use_native
               ? newSViv(i64)
               : newSVi64(aTHX_ i64) );
OUTPUT:
    RETVAL

SV *
miu64_uint64_rand()
PREINIT:
    dMY_CXT;
    uint64_t u64 = rand64(&(MY_CXT.is));
CODE:
    RETVAL = ( use_native
               ? newSViv(u64)
               : newSVu64(aTHX_ u64) );
OUTPUT:
    RETVAL

void
miu64_int64_srand(seed=&PL_sv_undef)
    SV *seed
PREINIT:
    dMY_CXT;
    isaac64_state_t *is;
CODE:
    is = &(MY_CXT.is);
    if (SvOK(seed) && SvCUR(seed)) {
        STRLEN len;
        const char *pv = SvPV_const(seed, len);
        char *shadow = (char*)is->randrsl;
        int i;
        if (len > sizeof(is->randrsl)) len = sizeof(is->randrsl);
        Zero(shadow, sizeof(is->randrsl), char);
        Copy(pv, shadow, len, char);

        /* make the seed endianness agnostic */
        for (i = 0; i < RANDSIZ; i++) {
            char *p = shadow + i * sizeof(uint64_t);
            is->randrsl[i] = (((((((((((((((uint64_t)p[0]) << 8) + p[1]) << 8) + p[2]) << 8) + p[3]) << 8) +
                                   p[4]) << 8) + p[5]) << 8) + p[6]) << 8) + p[7];
    }
        randinit(is, 1);
    }
    else
        randinit(is, 0);

MODULE = Math::Int64		PACKAGE = Math::Int64		PREFIX=mi64
PROTOTYPES: DISABLE

SV *
mi64_inc(self, other = NULL, rev = NULL)
    SV *self
    SV *other = NO_INIT
    SV *rev = NO_INIT
CODE:
    if (may_die_on_overflow && (SvI64x(self) == INT64_MAX)) overflow(aTHX_ inc_error);
    SvI64x(self)++;
    RETVAL = self;
    SvREFCNT_inc(RETVAL);
OUTPUT:
    RETVAL

SV *
mi64_dec(self, other = NULL, rev = NULL)
    SV *self
    SV *other = NO_INIT
    SV *rev = NO_INIT
CODE:
    if (may_die_on_overflow && (SvI64x(self) == INT64_MIN)) overflow(aTHX_ dec_error);
    SvI64x(self)--;
    RETVAL = self;
    SvREFCNT_inc(RETVAL);
OUTPUT:
    RETVAL

SV *
mi64_add(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
PREINIT:
    int64_t a = SvI64x(self);
    int64_t b = SvI64(aTHX_ other);
CODE:
    if ( may_die_on_overflow &&
         ( a > 0
           ? ( (b > 0) && (INT64_MAX - a < b) )
           : ( (b < 0) && (INT64_MIN - a > b) ) ) ) overflow(aTHX_ add_error);
    if (SvOK(rev))
        RETVAL = newSVi64(aTHX_ a + b);
    else {
        RETVAL = self;
        SvREFCNT_inc(RETVAL);
        SvI64x(self) = a + b;
    }
OUTPUT:
    RETVAL

SV *
mi64_sub(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
PREINIT:
    int64_t a = SvI64x(self);
    int64_t b = SvI64(aTHX_ other);
CODE:
    if (SvTRUE(rev)) {
        int64_t tmp = a;
        a = b; b = tmp;
    }
    if ( may_die_on_overflow &&
         ( a > 0
           ? ( ( b < 0) && (a - INT64_MAX > b) )
           : ( ( b > 0) && (a - INT64_MIN < b) ) ) ) overflow(aTHX_ sub_error);
    if (SvOK(rev))
        RETVAL = newSVi64(aTHX_ a - b);
    else {
        RETVAL = self;
        SvREFCNT_inc(RETVAL);
        SvI64x(self) = a - b;
    }
OUTPUT:
    RETVAL

SV *
mi64_mul(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
PREINIT:
    int64_t a1 = SvI64x(self);
    int64_t b1 = SvI64(aTHX_ other);
CODE:
    if (may_die_on_overflow) {
        int neg = 0;
        uint64_t a, b;
        if (a1 < 0) {
            a = -a1;
            neg ^= 1;
        }
        else a = a1;
        if (b1 < 0) {
            b = -b1;
            neg ^= 1;
        }
        else b = b1;
        mul_check_overflow(aTHX_ a, b, mul_error);
        if (a * b > (neg ? (~(uint64_t)INT64_MIN + 1) : INT64_MAX)) overflow(aTHX_ mul_error);
    }
    if (SvOK(rev))
        RETVAL = newSVi64(aTHX_ a1 * b1);
    else {
        RETVAL = self;
        SvREFCNT_inc(RETVAL);
        SvI64x(self) = a1 * b1;
    }
OUTPUT:
    RETVAL

SV *
mi64_div(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
PREINIT:
    int64_t up;
    int64_t down;
CODE:
    if (SvOK(rev)) {
        if (SvTRUE(rev)) {
            up = SvI64(aTHX_ other);
            down = SvI64x(self);
        }
        else {
            up = SvI64x(self);
            down = SvI64(aTHX_ other);
        }
        if (!down)
            croak_string(aTHX_ div_by_0_error);
        RETVAL = newSVi64(aTHX_ up/down);
    }
    else {
        down = SvI64(aTHX_ other);
        if (!down)
            croak_string(aTHX_ div_by_0_error);
        RETVAL = self;
        SvREFCNT_inc(RETVAL);
        SvI64x(self) /= down;
    }
OUTPUT:
    RETVAL

SV *
mi64_rest(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
PREINIT:
    int64_t up;
    int64_t down;
CODE:
    if (SvOK(rev)) {
        if (SvTRUE(rev)) {
            up = SvI64(aTHX_ other);
            down = SvI64x(self);
        }
        else {
            up = SvI64x(self);
            down = SvI64(aTHX_ other);
        }
        if (!down)
            croak_string(aTHX_ div_by_0_error);
        RETVAL = newSVi64(aTHX_ up % down);
    }
    else {
        down = SvI64(aTHX_ other);
        if (!down)
            croak_string(aTHX_ div_by_0_error);
        RETVAL = self;
        SvREFCNT_inc(RETVAL);
        SvI64x(self) %= down;
    }
OUTPUT:
    RETVAL

SV *
mi64_left(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
PREINIT:
    int64_t a, r;
    uint64_t b;
CODE:
    if (SvTRUE(rev)) {
        a = SvI64(aTHX_ other);
        b = SvU64x(self);
    }
    else {
        a = SvI64x(self);
        b = SvU64(aTHX_ other);
    }
    r = (b > 63 ? 0 : a << b);
    if (SvOK(rev))
        RETVAL = newSVi64(aTHX_ r);
    else {
        RETVAL = SvREFCNT_inc(self);
        SvI64x(self) = r;
    }
OUTPUT:
    RETVAL

SV *mi64_right(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
PREINIT:
    int64_t a, r;
    uint64_t b;
CODE:
    if (SvTRUE(rev)) {
        a = SvI64(aTHX_ other);
        b = SvU64x(self);
    }
    else {
        a = SvI64x(self);
        b = SvU64(aTHX_ other);
    }
    r = (b > 63 ? (a < 0 ? -1 : 0) : a >> b);
    if (SvOK(rev))
        RETVAL = newSVi64(aTHX_ r);
    else {
        RETVAL = SvREFCNT_inc(self);
        SvI64x(self) = r;
    }
OUTPUT:
    RETVAL

SV *
mi64_pow(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
PREINIT:
    int sign;
    uint64_t r;
    int64_t a, b;
CODE:
    if (SvTRUE(rev)) {
        a = SvI64(aTHX_ other);
        b = SvI64x(self);
    }
    else {
        a = SvI64x(self);
        b = SvI64(aTHX_ other);
    }
    if (a < 0) {
        sign = ((b & 1) ? -1 : 1);
        a = -a;
    }
    else sign = 1;
    if (b < 0) {
        if      (a == 0) croak_string(aTHX_ div_by_0_error);
        else if (a == 1) r = sign;
        else             r = 0;
    }
    else {
        uint64_t u = powU64(aTHX_ a, b);
        if (may_die_on_overflow && (u > ((sign < 0) ? (~(uint64_t)INT64_MIN + 1) : INT64_MAX))) overflow(aTHX_ pow_error);
        r = ((sign > 0) ? u : -u);
    }
    if (SvOK(rev))
        RETVAL = newSVi64(aTHX_ r);
    else {
        RETVAL = self;
        SvREFCNT_inc(RETVAL);
        SvI64x(self) = r;
    }
OUTPUT:
    RETVAL

int
mi64_spaceship(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
PREINIT:
    int64_t left;
    int64_t right;
CODE:
    if (SvTRUE(rev)) {
        left = SvI64(aTHX_ other);
        right = SvI64x(self);
    }
    else {
        left = SvI64x(self);
        right = SvI64(aTHX_ other);
    }
    RETVAL = (left < right ? -1 : left > right ? 1 : 0);
OUTPUT:
    RETVAL

SV *
mi64_eqn(self, other, rev = NULL)
    SV *self
    SV *other
    SV *rev = NO_INIT
CODE:
    RETVAL = ( SvI64x(self) == SvI64(aTHX_ other)
               ? &PL_sv_yes
               : &PL_sv_no );
OUTPUT:
    RETVAL

SV *
mi64_nen(self, other, rev = NULL)
    SV *self
    SV *other
    SV *rev = NO_INIT
CODE:
    RETVAL = ( SvI64x(self) != SvI64(aTHX_ other)
               ? &PL_sv_yes
               : &PL_sv_no );
OUTPUT:
    RETVAL

SV *
mi64_gtn(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
CODE:
    if (SvTRUE(rev))
        RETVAL = SvI64x(self) < SvI64(aTHX_ other) ? &PL_sv_yes : &PL_sv_no;
    else
        RETVAL = SvI64x(self) > SvI64(aTHX_ other) ? &PL_sv_yes : &PL_sv_no;
OUTPUT:
    RETVAL

SV *
mi64_ltn(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
CODE:
    if (SvTRUE(rev))
        RETVAL = SvI64x(self) > SvI64(aTHX_ other) ? &PL_sv_yes : &PL_sv_no;
    else
        RETVAL = SvI64x(self) < SvI64(aTHX_ other) ? &PL_sv_yes : &PL_sv_no;
OUTPUT:
    RETVAL

SV *
mi64_gen(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
CODE:
    if (SvTRUE(rev))
        RETVAL = SvI64x(self) <= SvI64(aTHX_ other) ? &PL_sv_yes : &PL_sv_no;
    else
        RETVAL = SvI64x(self) >= SvI64(aTHX_ other) ? &PL_sv_yes : &PL_sv_no;
OUTPUT:
    RETVAL

SV *
mi64_len(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
CODE:
    if (SvTRUE(rev))
        RETVAL = SvI64x(self) >= SvI64(aTHX_ other) ? &PL_sv_yes : &PL_sv_no;
    else
        RETVAL = SvI64x(self) <= SvI64(aTHX_ other) ? &PL_sv_yes : &PL_sv_no;
OUTPUT:
    RETVAL

SV *
mi64_and(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
CODE:
    if (SvOK(rev))
        RETVAL = newSVi64(aTHX_ SvI64x(self) & SvI64(aTHX_ other));
    else {
        RETVAL = self;
        SvREFCNT_inc(RETVAL);
        SvI64x(self) &= SvI64(aTHX_ other);
    }
OUTPUT:
    RETVAL

SV *
mi64_or(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
CODE:
    if (SvOK(rev))
        RETVAL = newSVi64(aTHX_ SvI64x(self) | SvI64(aTHX_ other));
    else {
        RETVAL = self;
        SvREFCNT_inc(RETVAL);
        SvI64x(self) |= SvI64(aTHX_ other);
    }
OUTPUT:
    RETVAL

SV *
mi64_xor(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
CODE:
    if (SvOK(rev))
        RETVAL = newSVi64(aTHX_ SvI64x(self) ^ SvI64(aTHX_ other));
    else {
        RETVAL = self;
        SvREFCNT_inc(RETVAL);
        SvI64x(self) ^= SvI64(aTHX_ other);
    }
OUTPUT:
    RETVAL

SV *
mi64_not(self, other = NULL, rev = NULL)
    SV *self
    SV *other = NO_INIT
    SV *rev = NO_INIT
CODE:
    RETVAL = SvI64x(self) ? &PL_sv_no : &PL_sv_yes;
OUTPUT:
    RETVAL

SV *
mi64_bnot(self, other = NULL, rev = NULL)
    SV *self
    SV *other = NO_INIT
    SV *rev = NO_INIT
CODE:
    RETVAL = newSVi64(aTHX_ ~SvI64x(self));
OUTPUT:
    RETVAL    

SV *
mi64_neg(self, other = NULL, rev = NULL)
    SV *self
    SV *other = NO_INIT
    SV *rev = NO_INIT
CODE:
    RETVAL = newSVi64(aTHX_ -SvI64x(self));
OUTPUT:
    RETVAL

SV *
mi64_bool(self, other = NULL, rev = NULL)
    SV *self
    SV *other = NO_INIT
    SV *rev = NO_INIT
CODE:
    RETVAL = SvI64x(self) ? &PL_sv_yes : &PL_sv_no;
OUTPUT:
    RETVAL

SV *
mi64_number(self, other = NULL, rev = NULL)
    SV *self
    SV *other = NO_INIT
    SV *rev = NO_INIT
CODE:
    RETVAL = si64_to_number(aTHX_ self);
OUTPUT:
    RETVAL

SV *
mi64_clone(self, other = NULL, rev = NULL)
    SV *self
    SV *other = NO_INIT
    SV *rev = NO_INIT
CODE:
    RETVAL = newSVi64(aTHX_ SvI64x(self));
OUTPUT:
    RETVAL

SV *
mi64_string(self, other = NULL, rev = NULL)
    SV *self
    SV *other = NO_INIT
    SV *rev = NO_INIT
CODE:
    RETVAL = i64_to_string(aTHX_ SvI64x(self), 10);
OUTPUT:
    RETVAL

void
mi64STORABLE_thaw(self, cloning, serialized, ...)
    SV *self
    SV *cloning = NO_INIT
    SV *serialized
CODE:
    if (SvROK(self) && sv_isa(self, "Math::Int64")) {
        SV *target = SvRV(self);
        SV *tmp = sv_2mortal(newSVu64(aTHX_ BER_to_int64(aTHX_ serialized)));
        sv_setsv(target, SvRV(tmp));
        SvREADONLY_on(target);
    }
    else
        croak_string(aTHX_ "Bad object for Math::Int64::STORABLE_thaw call");

SV *
mi64STORABLE_freeze(self, cloning = NULL)
    SV *self
    SV *cloning = NO_INIT
CODE:
    RETVAL = int64_to_BER(aTHX_ SvI64x(self));
OUTPUT:
    RETVAL

MODULE = Math::Int64		PACKAGE = Math::UInt64		PREFIX=mu64
PROTOTYPES: DISABLE

SV *
mu64_inc(self, other = NULL, rev = NULL)
    SV *self
    SV *other = NO_INIT
    SV *rev = NO_INIT
CODE:
    if (may_die_on_overflow && (SvU64x(self) == UINT64_MAX)) overflow(aTHX_ inc_error);
    SvU64x(self)++;
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL

SV *
mu64_dec(self, other = NULL, rev = NULL)
    SV *self
    SV *other = NO_INIT
    SV *rev = NO_INIT
CODE:
    if (may_die_on_overflow && (SvU64x(self) == 0)) overflow(aTHX_ dec_error);
    SvU64x(self)--;
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL

SV *
mu64_add(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
PREINIT:
    uint64_t a, b;
CODE:
    a = SvU64x(self);
    b = SvU64(aTHX_ other);
    if (may_die_on_overflow && (UINT64_MAX - a < b)) overflow(aTHX_ add_error);
    if (SvOK(rev)) 
        RETVAL = newSVu64(aTHX_ a + b);
    else {
        RETVAL = self;
        SvREFCNT_inc(RETVAL);
        SvU64x(self) = a + b;
    }
OUTPUT:
    RETVAL

SV *
mu64_sub(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
PREINIT:
    uint64_t a, b;
CODE:
    if (SvTRUE(rev)) {
        a = SvU64(aTHX_ other);
        b = SvU64x(self);
    }
    else {
        a = SvU64x(self);
        b = SvU64(aTHX_ other);
    }
    if (may_die_on_overflow && (b > a)) overflow(aTHX_ sub_error);
    if (SvOK(rev))
        RETVAL = newSVu64(aTHX_ a - b);
    else {
        RETVAL = SvREFCNT_inc(self);
        SvU64x(self) = a - b;
    }
OUTPUT:
    RETVAL

SV *
mu64_mul(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
PREINIT:
    uint64_t a, b;
CODE:
    a = SvU64x(self);
    b = SvU64(aTHX_ other);
    if (may_die_on_overflow) mul_check_overflow(aTHX_ a, b, mul_error);
    if (SvOK(rev))
        RETVAL = newSVu64(aTHX_ a * b);
    else {
        RETVAL = SvREFCNT_inc(self);
        SvU64x(self) = a * b;
    }
OUTPUT:
    RETVAL

SV *
mu64_div(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
PREINIT:
    uint64_t up, down;
CODE:
    if (SvOK(rev)) {
        if (SvTRUE(rev)) {
            up = SvU64(aTHX_ other);
            down = SvU64x(self);
        }
        else {
            up = SvU64x(self);
            down = SvU64(aTHX_ other);
        }
        if (!down)
            croak_string(aTHX_ div_by_0_error);
        RETVAL = newSVu64(aTHX_ up/down);
    }
    else {
        down = SvU64(aTHX_ other);
        if (!down)
            croak_string(aTHX_ div_by_0_error);
        RETVAL = self;
        SvREFCNT_inc(RETVAL);
        SvU64x(self) /= down;
    }
OUTPUT:
    RETVAL

SV *
mu64_rest(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
PREINIT:
    uint64_t up;
    uint64_t down;
CODE:
    if (SvOK(rev)) {
        if (SvTRUE(rev)) {
            up = SvU64(aTHX_ other);
            down = SvU64x(self);
        }
        else {
            up = SvU64x(self);
            down = SvU64(aTHX_ other);
        }
        if (!down)
            croak_string(aTHX_ div_by_0_error);
        RETVAL = newSVu64(aTHX_ up % down);
    }
    else {
        down = SvU64(aTHX_ other);
        if (!down)
            croak_string(aTHX_ div_by_0_error);
        RETVAL = self;
        SvREFCNT_inc(RETVAL);
        SvU64x(self) %= down;
    }
OUTPUT:
    RETVAL

SV *mu64_left(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
PREINIT:
    uint64_t a, b, r;
CODE:
    if (SvTRUE(rev)) {
        a = SvU64(aTHX_ other);
        b = SvU64x(self);
    }
    else {
        a = SvU64x(self);
        b = SvU64(aTHX_ other);
    }
    r = (b > 63 ? 0 : a << b);
    if (SvOK(rev))
        RETVAL = newSVu64(aTHX_ r);
    else {
        RETVAL = SvREFCNT_inc(self);
        SvU64x(self) = r;
    }
OUTPUT:
    RETVAL

SV *mu64_right(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
PREINIT:
    uint64_t a, b, r;
CODE:
    if (SvTRUE(rev)) {
        a = SvU64(aTHX_ other);
        b = SvU64x(self);
    }
    else {
        a = SvU64x(self);
        b = SvU64(aTHX_ other);
    }
    r = (b > 63 ? 0 : a >> b);
    if (SvOK(rev))
        RETVAL = newSVu64(aTHX_ r);
    else {
        RETVAL = SvREFCNT_inc(self);
        SvU64x(self) = r;
    }
OUTPUT:
    RETVAL

SV *
mu64_pow(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
PREINIT:
    uint64_t r;
    int64_t a, b;
CODE:
    if (SvTRUE(rev)) {
        a = SvU64(aTHX_ other);
        b = SvU64x(self);
    }
    else {
        a = SvU64x(self);
        b = SvU64(aTHX_ other);
    }
    r = powU64(aTHX_ a, b);
    if (SvOK(rev))
        RETVAL = newSVu64(aTHX_ r);
    else {
        RETVAL = self;
        SvREFCNT_inc(RETVAL);
        SvU64x(self) = r;
    }
OUTPUT:
    RETVAL

int
mu64_spaceship(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
PREINIT:
    uint64_t left;
    uint64_t right;
CODE:
    if (SvTRUE(rev)) {
        left = SvU64(aTHX_ other);
        right = SvU64x(self);
    }
    else {
        left = SvU64x(self);
        right = SvU64(aTHX_ other);
    }
    RETVAL = (left < right ? -1 : left > right ? 1 : 0);
OUTPUT:
    RETVAL

SV *
mu64_eqn(self, other, rev = NULL)
    SV *self
    SV *other
    SV *rev = NO_INIT
CODE:
    RETVAL = ( SvU64x(self) == SvU64(aTHX_ other)
               ? &PL_sv_yes
               : &PL_sv_no );
OUTPUT:
    RETVAL

SV *
mu64_nen(self, other, rev = NULL)
    SV *self
    SV *other
    SV *rev = NO_INIT
CODE:
    RETVAL = ( SvU64x(self) != SvU64(aTHX_ other)
               ? &PL_sv_yes
               : &PL_sv_no );
OUTPUT:
    RETVAL

SV *
mu64_gtn(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
CODE:
    if (SvTRUE(rev))
        RETVAL = SvU64x(self) < SvU64(aTHX_ other) ? &PL_sv_yes : &PL_sv_no;
    else
        RETVAL = SvU64x(self) > SvU64(aTHX_ other) ? &PL_sv_yes : &PL_sv_no;
OUTPUT:
    RETVAL

SV *
mu64_ltn(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
CODE:
    if (SvTRUE(rev))
        RETVAL = SvU64x(self) > SvU64(aTHX_ other) ? &PL_sv_yes : &PL_sv_no;
    else
        RETVAL = SvU64x(self) < SvU64(aTHX_ other) ? &PL_sv_yes : &PL_sv_no;
OUTPUT:
    RETVAL

SV *
mu64_gen(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
CODE:
    if (SvTRUE(rev))
        RETVAL = SvU64x(self) <= SvU64(aTHX_ other) ? &PL_sv_yes : &PL_sv_no;
    else
        RETVAL = SvU64x(self) >= SvU64(aTHX_ other) ? &PL_sv_yes : &PL_sv_no;
OUTPUT:
    RETVAL

SV *
mu64_len(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
CODE:
    if (SvTRUE(rev))
        RETVAL = SvU64x(self) >= SvU64(aTHX_ other) ? &PL_sv_yes : &PL_sv_no;
    else
        RETVAL = SvU64x(self) <= SvU64(aTHX_ other) ? &PL_sv_yes : &PL_sv_no;
OUTPUT:
    RETVAL

SV *
mu64_and(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
CODE:
    if (SvOK(rev))
        RETVAL = newSVu64(aTHX_ SvU64x(self) & SvU64(aTHX_ other));
    else {
        RETVAL = self;
        SvREFCNT_inc(RETVAL);
        SvU64x(self) &= SvU64(aTHX_ other);
    }
OUTPUT:
    RETVAL

SV *
mu64_or(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
CODE:
    if (SvOK(rev))
        RETVAL = newSVu64(aTHX_ SvU64x(self) | SvU64(aTHX_ other));
    else {
        RETVAL = self;
        SvREFCNT_inc(RETVAL);
        SvU64x(self) |= SvU64(aTHX_ other);
    }
OUTPUT:
    RETVAL

SV *
mu64_xor(self, other, rev = &PL_sv_no)
    SV *self
    SV *other
    SV *rev
CODE:
    if (SvOK(rev))
        RETVAL = newSVu64(aTHX_ SvU64x(self) ^ SvU64(aTHX_ other));
    else {
        RETVAL = self;
        SvREFCNT_inc(RETVAL);
        SvU64x(self) ^= SvU64(aTHX_ other);
    }
OUTPUT:
    RETVAL

SV *
mu64_not(self, other = NULL, rev = NULL)
    SV *self
    SV *other = NO_INIT
    SV *rev = NO_INIT
CODE:
    RETVAL = SvU64x(self) ? &PL_sv_no : &PL_sv_yes;
OUTPUT:
    RETVAL

SV *
mu64_bnot(self, other = NULL, rev = NULL)
    SV *self
    SV *other = NO_INIT
    SV *rev = NO_INIT
CODE:
    RETVAL = newSVu64(aTHX_ ~SvU64x(self));
OUTPUT:
    RETVAL    

SV *
mu64_neg(self, other = NULL, rev = NULL)
    SV *self
    SV *other = NO_INIT
    SV *rev = NO_INIT
CODE:
    RETVAL = newSVu64(aTHX_ ~(SvU64x(self)-1));
OUTPUT:
    RETVAL

SV *
mu64_bool(self, other = NULL, rev = NULL)
    SV *self
    SV *other = NO_INIT
    SV *rev = NO_INIT
CODE:
    RETVAL = SvU64x(self) ? &PL_sv_yes : &PL_sv_no;
OUTPUT:
    RETVAL

SV *
mu64_number(self, other = NULL, rev = NULL)
    SV *self
    SV *other = NO_INIT
    SV *rev = NO_INIT
CODE:
    RETVAL = su64_to_number(aTHX_ self);
OUTPUT:
    RETVAL

SV *
mu64_clone(self, other = NULL, rev = NULL)
    SV *self
    SV *other = NO_INIT
    SV *rev = NO_INIT
CODE:
    RETVAL = newSVu64(aTHX_ SvU64x(self));
OUTPUT:
    RETVAL

SV *
mu64_string(self, other = NULL, rev = NULL)
    SV *self
    SV *other = NO_INIT
    SV *rev = NO_INIT
CODE:
    RETVAL = u64_to_string_with_sign(aTHX_ SvU64x(self), 10, 0);
OUTPUT:
    RETVAL

void
mu64STORABLE_thaw(self, cloning, serialized, ...)
    SV *self
    SV *cloning = NO_INIT
    SV *serialized
CODE:
    if (SvROK(self) && sv_isa(self, "Math::UInt64")) {
        SV *target = SvRV(self);
        SV *tmp = sv_2mortal(newSVu64(aTHX_ BER_to_uint64(aTHX_ serialized)));
        sv_setsv(target, SvRV(tmp));
        SvREADONLY_on(target);
    }
    else
        croak_string(aTHX_ "Bad object for Math::UInt64::STORABLE_thaw call");

SV *
mu64STORABLE_freeze(self, cloning = NULL)
    SV *self
    SV *cloning = NO_INIT
CODE:
    RETVAL = uint64_to_BER(aTHX_ SvU64x(self));
OUTPUT:
    RETVAL

