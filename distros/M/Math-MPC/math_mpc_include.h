/*************************************************

Documentation of symbols defined by Math::MPC

NV_IS_DOUBLE             : Automatically defined by Makefile.PL iff
                           $Config{nvtype} is 'double'.

NV_IS_LONG_DOUBLE        : Automatically defined by Makefile.PL iff
                           $Config{nvtype} is 'long double'.

NV_IS_FLOAT128           : Automatically defined by Makefile.PL iff
                           $Config{nvtype} is __float128
                           If NV_IS_FLOAT128 is defined we include the
                           quadmath.h header.

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

MPC_CAN_PASS_FLOAT128    : Defined only when both MPFR_WANT_FLOAT128 and
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


MATH_MPC_NEED_LONG_LONG_INT
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
                           NaNs as (-)1.#IND and (-)1.#INF.

_Complex_I               : Defined by complex.h. Attempts to define _DO_COMPLEX
                           (see below) will not succeed if _Complex_I is not
                           defined.

_DO_COMPLEX              : Automatically defined if at least one of Math::Complex_C,
                           Math::Complex_C::L and Math::Complex_C::Q is installed.
                           complex.h will be included iff _DO_COMPLEX is defined.
                           Can also be defined in the Makefile.PL by setting
                           $do_complex_h to 1 - though I can't envisage a situation
                           where doing so will be advantageous.
                           (Will be automatically undefined if _Complex_I is not
                           defined following the inclusion of complex.h.)


*************************************************/

#include <stdio.h>

#ifndef _MSC_VER
#include <inttypes.h>
#include <limits.h>
#ifdef _DO_COMPLEX_H
#include <complex.h>
#endif
#endif

/*
 * In mpfr-4.1.0, the _Float128 type is exposed in mpfr.h if MPFR_WANT_FLOAT128 is defined.
 * We fall back to defining it to __float128 if the _Float128 type is unknown.
*/

#if defined(MPFR_WANT_FLOAT128) && defined(__GNUC__) && !defined(__FLT128_MAX__) && !defined(_BITS_FLOATN_H)
#define _Float128 __float128
#endif

#include <gmp.h>
#include <mpfr.h>
#include <mpc.h>

#include <float.h>

#if defined(MPFR_WANT_FLOAT128) || defined(NV_IS_FLOAT128)
#include <quadmath.h>
#if defined(NV_IS_FLOAT128) && defined(MPFR_WANT_FLOAT128) && defined(MPFR_VERSION) && MPFR_VERSION >= MPFR_VERSION_NUM(4,0,0)
#define MPC_CAN_PASS_FLOAT128
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

/* complex.h should have defined _Complex_I */
#ifndef _Complex_I
#undef _DO_COMPLEX_H
#endif

#ifdef _MSC_VER
#pragma warning(disable:4700 4715 4716)
#define intmax_t __int64
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

#if MPC_VERSION_MAJOR > 0 || MPC_VERSION_MINOR > 8
#define SIN_COS_AVAILABLE 1
#endif

#define NOK_POK_DUALVAR_CHECK \
        if(SvNOK(b)) { \
         nok_pok++; \
         if(SvIV(get_sv("Math::MPC::NOK_POK", 0))) \
           warn("Scalar passed to %s is both NV and PV. Using PV (string) value"

#define MPC_RE(x) ((x)->re)
#define MPC_IM(x) ((x)->im)

#define VOID_MPC_SET_X_Y(real_t, imag_t, z, real_value, imag_value, rnd)     \
   {                                                                     \
     int _inex_re, _inex_im;                                             \
     _inex_re = (mpfr_set_ ## real_t) (MPC_RE (z), (real_value), MPC_RND_RE (rnd)); \
     _inex_im = (mpfr_set_ ## imag_t) (MPC_IM (z), (imag_value), MPC_RND_IM (rnd)); \
   }

#define SV_MPC_SET_X_Y(real_t, imag_t, z, real_value, imag_value, rnd)     \
  {                                                                     \
    int _inex_re, _inex_im;                                             \
    _inex_re = (mpfr_set_ ## real_t) (mpc_realref (z), (real_value), MPC_RND_RE (rnd)); \
    _inex_im = (mpfr_set_ ## imag_t) (mpc_imagref (z), (imag_value), MPC_RND_IM (rnd)); \
    return newSViv(MPC_INEX (_inex_re, _inex_im));                               \
  }

