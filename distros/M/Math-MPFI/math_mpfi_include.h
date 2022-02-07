/********************************************

Documentation of symbols defined by Math::MPFI

NV_IS_DOUBLE             : Automatically defined by Makefile.PL iff
                           $Config{nvtype} is 'double'.

NV_IS_LONG_DOUBLE        : Automatically defined by Makefile.PL iff
                           $Config{nvtype} is 'long double'.

NV_IS_FLOAT128           : Automatically defined by Makefile.PL iff
                           $Config{nvtype} is __float128
                           If NV_IS_FLOAT128 is defined we include the
                           quadmath.h header.
                           NOTE: mpfr_get/set_float128 are NOT necessarily
                                 available when this symbol is defined.

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
                           MPFR_WANT_FLOAT128 does not imply that NV_IS_FLOAT128
                           has been defined - perhaps we have defined
                           MPFR_WANT_FLOAT128 solely because we wish to make
                           use of the Math::Float128-Math::MPFR interface.

MPFI_CAN_PASS_FLOAT128     : Defined only when both MPFR_WANT_FLOAT128 and
                           NV_IS_FLOAT128 is defined, and then only if the mpfr
                           library is at version 4.0.0 or later. (There was no
                           __float128 support in the mpfr library prior to
                           4.0.0.)
                           DANGER: The assumption is that if MPFR_WANT_FLOAT128
                           is defined then the mpfr library has been built
                           with __float128 support, which won't be the case if
                           the mpfr library wasn't configured with
                           '--enable-float128'.
                           I haven't yet found a way of managing this - it's
                           instead left up to the person building Math::MPFR to
                           NOT define MATH_MPFR_WANT_FLOAT128 unless mpfr WAS
                           configured with --enable-float128.


MATH_MPFI_NEED_LONG_LONG_INT
                         : Defined by Makefile.PL if
                           $Config{ivsize} >= 8 && $Config{ivtype} is not
                           'long' && $use_64_bit_int (in the Makefile.PL)
                           has not been set to -1. This symbol will also be
                           defined if $use_64_bit_int is set to 1.
                           The setting of this symbol is taken to imply that
                           the mpc/mpfr _uj/_sj functions are needed for
                           converting mpfr integer values to perl integers.
                           Conversely, if the symbol is not defined, then
                           the implication is that the _uj/sj functions are
                           not needed (because the _ui/_si functions, which
                           are alway available) provide the same
                           functionality) - and therefore those _uj/_sj
                           functions are then not made available.

_WIN32_BIZARRE_INFNAN    : Defined (on Windows only) when the perl version
                           (as expressed by $]) is less than 5.022.
                           These earlier perl versions generally stringified
                           NaNs as (-)1.#IND and Infs as (-)1.#INF.

********************************************/

#if defined MATH_MPFI_NEED_LONG_LONG_INT
#ifndef _MSC_VER
#include <inttypes.h>
#endif
#endif

/*
 * In mpfr-4.1.0, the _Float128 type is exposed in mpfr.h if MPFR_WANT_FLOAT128 is defined.
 * We fall back to defining it to __float128 if the _Float128 type is unknown.
*/

#if defined(MPFR_WANT_FLOAT128) && defined(__GNUC__) && !defined(__FLT128_MAX__) && !defined(_BITS_FLOATN_H)
#define _Float128 __float128
#endif

#include <mpfi.h>
#include <mpfi_io.h>
#include <float.h>

#if defined(MPFR_WANT_FLOAT128) || defined(NV_IS_FLOAT128)
#include <quadmath.h>
#if defined(NV_IS_FLOAT128) && defined(MPFR_WANT_FLOAT128) && defined(MPFR_VERSION) && MPFR_VERSION >= MPFR_VERSION_NUM(4,0,0)
#define MPFI_CAN_PASS_FLOAT128
#endif
#if defined(__MINGW32__) && !defined(__MINGW64__)
typedef __float128 float128 __attribute__ ((aligned(32)));
#elif defined(__MINGW64__) || (defined(DEBUGGING) && defined(NV_IS_DOUBLE))
typedef __float128 float128 __attribute__ ((aligned(8)));
#else
typedef __float128 float128;
#endif
#endif

#if LDBL_MANT_DIG == 106
#define REQUIRED_LDBL_MANT_DIG 2098
#else
#define REQUIRED_LDBL_MANT_DIG LDBL_MANT_DIG
#endif

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
 *                                                           *
 * See See https://github.com/sisyphus/math-decimal64/pull/1 */

#if defined SvTRUE_nomg_NN
#define SWITCH_ARGS SvTRUE_nomg_NN(third)
#else
#define SWITCH_ARGS third==&PL_sv_yes
#endif

#ifndef __gmpfr_default_rounding_mode
#define __gmpfr_default_rounding_mode mpfr_get_default_rounding_mode()
#endif

#define SV_IS_IOK(x) \
     SvIOK(x)

#define SV_IS_POK(x) \
     SvPOK(x)

#define SV_IS_NOK(x) \
     SvNOK(x)

#define NOK_POK_DUALVAR_CHECK \
        if(SvNOK(b)) { \
         nok_pok++; \
         if(SvIV(get_sv("Math::MPFI::NOK_POK", 0))) \
           warn("Scalar passed to %s is both NV and PV. Using PV (string) value"


