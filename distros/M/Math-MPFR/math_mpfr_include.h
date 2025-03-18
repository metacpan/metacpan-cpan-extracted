/*************************************************
Documentation of symbols defined by Math::MPFR

MPFR_WANT_FLOAT128       : Defined by Makefile.PL if $have_float128 is
                           set to a true value. $have_float128 can be set
                           to a true value by either editing the Makefile.PL
                           appropriately or by specifying F128=1 in the
                           Makefile.PL's @ARGV.
                           The quadmath.h header is included if this symbol
                           is defined.
                           NOTE: If MPFR_WANT_FLOAT128 is defined, it is
                           assumed that the mpfr library was built with
                           __float128 support - ie was configured with the
                           '--enable-float128' option.
                           MPFR_WANT_FLOAT128 must NOT be defined if the
                           mpfr library has NOT been built with __float128
                           support.
                           MPFR_WANT_FLOAT128 does not imply that nvtype is
                           __float128 - perhaps we have defined
                           MPFR_WANT_FLOAT128 solely because we wish to make
                           use of the Math::Float128-Math::MPFR interface.

CAN_PASS_FLOAT128        : Defined only when both MPFR_WANT_FLOAT128 and
                           USE_QUADMATH is defined, and then only if the mpfr
                           library is at version 4.0.0 or later. (There was no
                           __float128 support in the mpfr library prior to
                           4.0.0.)
                           DANGER: The assumption is that if MPFR_WANT_FLOAT128
                           is defined then the mpfr library has been built
                           with __float128 support, which may not be the case.
                           Hopefully the configure probing done by the
                           Makefile.PL will get it right.

MPFR_WANT_DECIMAL_FLOATS : The symbol needs to be defined (before mpfr.h is
                           included) in order to enable _Decimal64 and/or
                           _Decimal128 support.
                           Hence we define it in the Makefile.PL by setting
                           $have_decimal64 or setting $have_decimal128 to a true
                           value.
                           $have_decimal64 can be forcibly set to a true value by
                           specifying D64=1 in the Makefile.PL's @ARGV.
                           And $have_decimal128 can likewise be set to a true value
                           by specifying D128=1 in the Makefile.PL's @ARGV.
                           $have_decimal64 must not be set to a true value
                           if the mpfr library has not been built with
                           _Decimal64 support.
                           And $have_decimal128 must not be set to a true value
                           if the mpfr library has not been built with
                           _Decimal128 support.
                           We define the symbol solely to enable a Math::MPFR
                           interface with Math::Decimal64 and/or Math::Decimal128.
                           Otherwise there's no point (apparent to me) in defining
                           it.

MPFR_WANT_DECIMAL64      : Defined by the Makefile.PL only if support for the
                            _Decimal64 type in the mpfr library is detected.
                           Can be forcibly defined by specifying D64=1 in the
                           Makefile.PL's @ARGV.
                           Can be forcibly not defined by specifying D64=0
                           in the Makefile.PL's @ARGV.
                           We define the symbol solely to enable a
                           Math::Decimal64-Math::MPFR interface.

MPFR_WANT_DECIMAL128     : Defined by the Makefile.PL only if support for the
                           _Decimal128 type in the mpfr library is detected.
                           Can be forcibly defined by specifying D128=1 in the
                           Makefile.PL's @ARGV.
                           Can be forcibly not defined by specifying D128=0
                           in the Makefile.PL's @ARGV.
                           We define the symbol solely to enable a
                           Math::Decimal128-Math::MPFR interface.

HAVE_IEEE_754_LONG_DOUBLE :Used only by the test suite.
                           Defined by Makefile.PL if
                           ($Config{longdblkind} == 1 ||
                            $Config{longdblkind} == 2)
                           This implies that long double is the quad (128-bit)
                           long double.

HAVE_EXTENDED_PRECISION_LONG_DOUBLE :
                           Used only by the test suite.
                           Defined by Makefile.PL if
                           ($Config{longdblkind} == 3 ||
                            $Config{longdblkind} == 4)
                           This implies that nvtype is the extended
                           precision (80-bit) long double.

REQUIRED_LDBL_MANT_DIG   : Defined to float.h's LDBL_MANT_DIG unless
                           LDBL_MANT_DIG is 106 (ie long double is
                           double-double) - in which case it is defined to
                           be 2098.
                           This is needed to ensure that the mpfr value is
                           an accurate rendition of the double-double value.

CHECK_ROUNDING_VALUE     : Macro that checks (on pre-4.0.0 mpfr versions only)
                           that the rounding value provided is in the
                           allowable range of 0-4 inclusive.
                           (On 2.x.x versions the allowable range is only 0-3,
                           but we don't support those versions anyway.)

FAILS_CHECK_INPUT_BASE   : Macro that checks that the base (where specified)
                           is in the accepted range.

FAILS_CHECK_OUTPUT_BASE  : Macro that checks that the base (where specified)
                           is in the accepted range.

DEAL_WITH_NANFLAG_BUG    : Macro that corrects certain failures (in mpfr
                           versions prior to 3.1.4) to set the NaN flag.

DEAL_WITH_NANFLAG_BUG_OVERLOADED
                         : Another macro that corrects the same bug as
                           DEAL_WITH_NANFLAG_BUG - but recoded for the
                           overloaded operations affected by the bug.

MATH_MPFR_NEED_LONG_LONG_INT
                         : Defined by Makefile.PL if
                           $Config{ivsize} >= 8 && $Config{ivtype} is not
                           'long' && $use_64_bit_int (in the Makefile.PL)
                           has not been set to -1. This symbol will also be
                           defined if $use_64_bit_int is set to 1.
                           The setting of this symbol is taken to imply that
                           the mpfr _uj/_sj functions are needed for
                           converting mpfr integer values to perl integers.
                           Conversely, if the symbol is not defined, then
                           the implication is that the _uj/sj functions are
                           not needed (because the _ui/_si functions, which
                           are alway available) provide the same
                           functionality) - and therefore those _uj/_sj
                           functions are then not made available.

IVSIZE_BITS              : Defined only if MATH_MPFR_NEED_LONG_LONG_INT is
                           defined - whereupon it will be set to the bitsize
                           of the IV (perl's integer type).
                           Currently, I think this symbol will only ever be
                           either undefined or set to 64 - and I suspect
                           that it could (currently) be replaced with a hard
                           coded 64 wherever it occurs in the code.

NVSIZE_BITS              : Defined to the maximum number of bits effectively
                           representable by the NV. This will be either 53,
                           64, 113 or 2098 - depending on perl's NV type.

_WIN32_BIZARRE_INFNAN    : Defined (on Windows only) when the perl version
                           (as expressed by $]) is less than 5.022.
                           These earlier perl versions had bizarre strings
                           representing NaNs (eg 1.#IND) and Infs (eg 1.#INF)
                           on Win32.

LD_SUBNORMAL_BUG         : Defined for mpfr-3.1.4 and earlier if and only if
                           LDBL_MANT_DIG == 64
                           (The bug is in mpfr_get_ld)

FALLBACK_NOTIFY          : If defined, $Math::MPFR::doubletoa_fallback
                           (initially set to 0) will be incremented by 1 on
                           those rare occasions where grisu3 fails and
                           falls back to the fallback routine.
                           For more details, see the doubletoa documentation.

*************************************************/

#include <stdio.h>
#include <inttypes.h>

/*
 * In mpfr-4.1.0, the _Float128 type is exposed in mpfr.h if MPFR_WANT_FLOAT128 is defined.
 * We fall back to defining it to __float128 if the _Float128 type is unknown.
*/

#if defined(MPFR_WANT_FLOAT128) && defined(__GNUC__) && !defined(__FLT128_MAX__) && !defined(_BITS_FLOATN_H)
#define _Float128 __float128
#endif

#include <gmp.h>
#include <mpfr.h>
#include <float.h>

#if MPFR_VERSION_MAJOR < 3
#define mpfr_exp_t mp_exp_t
#endif

#if defined(MPFR_WANT_FLOAT128) || defined(USE_QUADMATH)
#include <quadmath.h>
#if defined(USE_QUADMATH) && defined(MPFR_WANT_FLOAT128) && defined(MPFR_VERSION) && MPFR_VERSION >= MPFR_VERSION_NUM(4,0,0)
#define CAN_PASS_FLOAT128
#endif
#if defined(__MINGW32__) && !defined(__MINGW64__)
typedef __float128 float128 __attribute__ ((aligned(32)));
#elif defined(__MINGW64__) || (defined(DEBUGGING) && NVSIZE == 8)
typedef __float128 float128 __attribute__ ((aligned(8)));
#else
typedef __float128 float128;
#endif
#endif

#if defined(MPFR_WANT_DECIMAL128)
#if defined(__MINGW64__) || (defined(DEBUGGING) && NVSIZE == 8)
typedef _Decimal128 D128 __attribute__ ((aligned(8)));
#else
typedef _Decimal128 D128;
#endif
#endif

#define SIS_PERL_VERSION PERL_REVISION*1000000+PERL_VERSION*1000+PERL_SUBVERSION

#if SIS_PERL_VERSION >= 5012000   /* perl-5.12.0 and later */
#  define MORTALIZED_PV(x) newSVpvn_flags(x,strlen(x),SVs_TEMP)
#else
#  define MORTALIZED_PV(x) sv_2mortal(newSVpv(x,0))
#endif

/* Facilitate altering the numeric flags that we *
 * look at (in case it becomes necessary)        */

#define SV_IS_IOK(x) \
     SvIOK(x)

#define SV_IS_POK(x) \
     SvPOK(x)

#define SV_IS_NOK(x) \
     SvNOK(x)

#if (!defined(MPFR_VERSION) || MPFR_VERSION <= 196868) && LDBL_MANT_DIG == 64
#define LD_SUBNORMAL_BUG 1
#endif

#if LDBL_MANT_DIG == 106
#define REQUIRED_LDBL_MANT_DIG 2098
#else
#define REQUIRED_LDBL_MANT_DIG LDBL_MANT_DIG
#endif

#define FAILS_CHECK_INPUT_BASE \
     !SV_IS_IOK(base) || SvIVX(base) < 0 || SvIVX(base) > 62 || SvIVX(base) == 1

#if MPFR_VERSION >= 262400 /* Allowable range of base has been expanded */
#define FAILS_CHECK_OUTPUT_BASE \
     !(SV_IS_IOK(base) && ((SvIVX(base) >= 2 && SvIVX(base) <= 62) || (SvIVX(base) >= -36 && SvIVX(base) <= -2)))
#else
#define FAILS_CHECK_OUTPUT_BASE \
     !(SV_IS_IOK(base) && SvIVX(base) >= 2 && SvIVX(base) <= 62)
#endif

/* Don't use CHECK_ROUNDING_VALUE macro with Rmpfr_set_NV      *
 * (as this function's "round" arg is "unsigned int", not SV*) */

#if MPFR_VERSION_MAJOR < 4
#define CHECK_ROUNDING_VALUE \
 if((mp_rnd_t)SvUV(round) > 4) \
  croak("Illegal rounding value supplied for this version (%s) of the mpfr library", MPFR_VERSION_STRING);

#else
#define CHECK_ROUNDING_VALUE
#endif

#define NOK_POK_DUALVAR_CHECK \
        if(SV_IS_NOK(b)) { \
         nok_pok++; \
         if(SvIV(get_sv("Math::MPFR::NOK_POK", 0))) \
           warn("Scalar passed to %s is both NV and PV. Using PV (string) value"

/* Don't use NON_NUMERIC_CHAR_CHECK macro with Rmpfr_inp_str as this *
 * function requires a different condition (!ret vs ret).            */

#define NON_NUMERIC_CHAR_CHECK(inputstr) \
       if(ret) { \
         nnum++; \
         if(SvIV(get_sv("Math::MPFR::NNW", 0))) \
           warn("string used (%s) in %s contains non-numeric characters", SvPV_nolen(inputstr)

#define BITSEARCH_4 \
          if(tmp & 8) {				\
            subnormal_prec_adjustment += 1;	\
            break;				\
          }					\
          if(tmp & 4) {				\
            subnormal_prec_adjustment += 2;	\
            break;				\
          }					\
          if(tmp & 2) {				\
            subnormal_prec_adjustment += 3;	\
            break;				\
          }					\
          subnormal_prec_adjustment += 4;


#define BITSEARCH_8 \
          if(tmp & 128) {			\
            subnormal_prec_adjustment += 1;	\
            break;				\
          }					\
          if(tmp & 64) {			\
            subnormal_prec_adjustment += 2;	\
            break;				\
          }					\
          if(tmp & 32) {			\
            subnormal_prec_adjustment += 3;	\
            break;				\
          }					\
          if(tmp & 16) {			\
            subnormal_prec_adjustment += 4;	\
            break;				\
          }					\
          if(tmp & 8) {				\
            subnormal_prec_adjustment += 5;	\
            break;				\
          }					\
          if(tmp & 4) {				\
            subnormal_prec_adjustment += 6;	\
            break;				\
          }					\
          if(tmp & 2) {				\
            subnormal_prec_adjustment += 7;	\
            break;				\
          }					\
          subnormal_prec_adjustment += 8;


#define NEG_ZERO_BUG 196866 /* A bug affecting mpfr_fits_u*_p functions         */
                            /* Fixed in mpfr after MPFR_VERSION 196866 (3.1.2)  */
                            /* For earlier versions of mpfr, we fix this bug in */
                            /* our own code                                     */

#define LNGAMMA_BUG 196867  /* lngamma(-0) set to NaN instead of +Inf           */
                            /* Fixed in mpfr after MPFR_VERSION 196867 (3.1.3)  */
                            /* For earlier versions of mpfr, we fix this bug in */
                            /* our own code                                     */

#define NANFLAG_BUG 196868  /* A bug affecting setting of the NaN flag          */
                            /* Fixed in mpfr after MPFR_VERSION 196868 (3.1.4)  */
                            /* For earlier versions of mpfr, we fix this bug in */
                            /* our own code                                     */

#define DD_INF_BUG 196869   /* mpfr_get_ld on (double-double platforms only)    */
                            /* might return NaN when it sould return Inf.       */
                            /* Presumably, this will be                         */
                            /* fixed in mpfr after MPFR_VERSION 196869 (3.1.5)  */
                            /* For earlier versions of mpfr, we fix this bug in */
                            /* our own code                                     */

#if  !defined(MPFR_VERSION) || (defined(MPFR_VERSION) && MPFR_VERSION <= NANFLAG_BUG)
#define DEAL_WITH_NANFLAG_BUG if(mpfr_nan_p(*b))mpfr_set_nanflag();
#define DEAL_WITH_NANFLAG_BUG_OVERLOADED if(mpfr_nan_p(*(INT2PTR(mpfr_t *,SvIVX(SvRV(a))))))mpfr_set_nanflag();
#else
#define DEAL_WITH_NANFLAG_BUG
#define DEAL_WITH_NANFLAG_BUG_OVERLOADED
#endif

/*
#ifdef _MSC_VER
#pragma warning(disable:4700 4715 4716)
#endif
*/

#ifdef OLDPERL
#define SvUOK SvIsUV
#endif

#ifndef Newx
#  define Newx(v,n,t) New(0,v,n,t)
#endif

#ifndef Newxz
#  define Newxz(v,n,t) Newz(0,v,n,t)
#endif

/* A perl bug in perl-5.20 onwards can break &PL_sv_yes and  *
 * &PL_sv_no. In the overload subs we therefore instead      *
 * use  SvTRUE_nomg_NN where possible, which is available    *
 * beginning with perl-5.18.0.                               *
 * Otherwise we continue using &PL_sv_yes as original        *
 * (&PL_sv_no is not used by this module.)                   *
 * See See https://github.com/sisyphus/math-decimal64/pull/1 */

#if defined SvTRUE_nomg_NN
#define SWITCH_ARGS SvTRUE_nomg_NN(third)
#define NO_SWITCH_ARGS !SvTRUE_nomg_NN(third)
#else
#define SWITCH_ARGS third==&PL_sv_yes
#define NO_SWITCH_ARGS third!=&PL_sv_yes
#endif

/* May one day be removed from mpfr.h */
#ifndef mp_rnd_t
# define mp_rnd_t  mpfr_rnd_t
#endif
#ifndef mp_prec_t
# define mp_prec_t mpfr_prec_t
#endif

#ifndef __gmpfr_default_rounding_mode
#define __gmpfr_default_rounding_mode mpfr_get_default_rounding_mode()
#endif

#if !defined(__GNU_MP_VERSION) || __GNU_MP_VERSION < 5
#define mp_bitcnt_t unsigned long int
#endif

/* For nvtoa() */
#if defined(MPFR_HAVE_BENDIAN)			/* big endian architecture - defined by Makefile.PL */
#define INC_OR_DEC(p) p++
#else						/* little endian */
#define INC_OR_DEC(p) p--
#endif

#if NVSIZE == 8
#define MATH_MPFR_MAX_DIG 17
#define NVSIZE_BITS 53
#define MATH_MPFR_NV_MAX 0x1.fffffffffffffp+1023 /* 32-bit Windows has a problem with evaluating the    *
                                                  * decimal form of this value if -std=c99 is specified */
#define MATH_MPFR_NORMAL_MIN 0x1p-1022

# if defined(MPFR_HAVE_BENDIAN)                /* big endian architecture - defined by Makefile.PL */

# define D_CONDITION_1(p) p<=7
# define DIND_0 0
# define DIND_1 1
# define DIND_2 2

# else						/* little endian architecture */

# define D_CONDITION_1(p) p>=0
# define DIND_0 7
# define DIND_1 6
# define DIND_2 5

# endif

#elif defined(USE_LONG_DOUBLE) && REQUIRED_LDBL_MANT_DIG == 64
#define MATH_MPFR_MAX_DIG 21
#define NVSIZE_BITS 64
#define MATH_MPFR_NV_MAX 0xf.fffffffffffffffp+16380L
#define MATH_MPFR_NORMAL_MIN 0x8p-16385L

# if defined(MPFR_HAVE_BENDIAN)                /* big endian architecture - defined by Makefile.PL */

# define LD_CONDITION_1(p) p<=9
# define LDIND_0 0
# define LDIND_1 1
# define LDIND_2 2

# else						/* little endian architecture */

# define LD_CONDITION_1(p) p>=0
# define LDIND_0 9
# define LDIND_1 8
# define LDIND_2 7

# endif

#elif defined(USE_LONG_DOUBLE) && REQUIRED_LDBL_MANT_DIG == 2098
#define MATH_MPFR_MAX_DIG 33
#define NVSIZE_BITS 2098
#define MATH_MPFR_NV_MAX 1.797693134862315807937289714053e+308L
#define MATH_MPFR_NORMAL_MIN 2.2250738585072014e-308

#else
#define MATH_MPFR_MAX_DIG 36
#define NVSIZE_BITS 113
#define MATH_MPFR_NV_MAX 0x1.ffffffffffffffffffffffffffffp+16383Q
#define MATH_MPFR_NORMAL_MIN 0x1p-16382Q       /* == 0x8p-16385 */

# if defined(MPFR_HAVE_BENDIAN)                /* big endian architecture - defined by Makefile.PL */

# define Q_CONDITION_1(p) p<=15
# define QIND_0 0
# define QIND_1 1
# define QIND_2 2

# else						/* little endian architecture */

# define Q_CONDITION_1(p) p>=0
# define QIND_0 15
# define QIND_1 14
# define QIND_2 13

# endif

#endif

/* End of defines for nvtoa() */

#define NEW_MATH_MPFR_OBJECT(PACNAME,FUNCNAME) \
     Newx(mpfr_t_obj, 1, mpfr_t);							\
     if(mpfr_t_obj == NULL) croak("Failed to allocate memory in FUNCNAME function");	\
     obj_ref = newSV(0);								\
     obj = newSVrv(obj_ref, PACNAME);

#define OBJ_READONLY_ON \
     sv_setiv(obj, INT2PTR(IV,mpfr_t_obj));	\
     SvREADONLY_on(obj);

#define RETURN_STACK_2 \
     ST(0) = sv_2mortal(obj_ref);	\
     ST(1) = sv_2mortal(newSViv(ret));	\
     XSRETURN(2);

