
#ifdef  __MINGW32__
#ifndef __USE_MINGW_ANSI_STDIO
#define __USE_MINGW_ANSI_STDIO 1
#endif
#endif

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#include "../math_mpfr_include.h"

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

SV * Rmpfr_randinit_default(pTHX) {
  gmp_randstate_t * state;
  SV * obj_ref, * obj;

  Newx(state, 1, gmp_randstate_t);
  if(state == NULL) croak("Failed to allocate memory in Rmpfr_randinit_default function");
  obj_ref = newSV(0);
  obj = newSVrv(obj_ref, "Math::MPFR::Random");
  gmp_randinit_default(*state);

  sv_setiv(obj, INT2PTR(IV,state));
  SvREADONLY_on(obj);
  return obj_ref;
}

SV * Rmpfr_randinit_mt(pTHX) {
  gmp_randstate_t * rand_obj;
  SV * obj_ref, * obj;

  Newx(rand_obj, 1, gmp_randstate_t);
  if(rand_obj == NULL) croak("Failed to allocate memory in Math::MPFR::Random::Rmpfr_randinit_mt function");
  obj_ref = newSV(0);
  obj = newSVrv(obj_ref, "Math::MPFR::Random");
  gmp_randinit_mt(*rand_obj);

  sv_setiv(obj, INT2PTR(IV, rand_obj));
  SvREADONLY_on(obj);
  return obj_ref;
}

SV * Rmpfr_randinit_lc_2exp(pTHX_ SV * a, SV * c, SV * m2exp ) {
  gmp_randstate_t * state;
  mpz_t aa;
  SV * obj_ref, * obj;

  Newx(state, 1, gmp_randstate_t);
  if(state == NULL) croak("Failed to allocate memory in Rmpfr_randinit_lc_2exp function");
  obj_ref = newSV(0);
  obj = newSVrv(obj_ref, "Math::MPFR::Random");
  if(sv_isobject(a)) {
    const char* h = HvNAME(SvSTASH(SvRV(a)));

    if(strEQ(h, "Math::GMP") || strEQ(h, "GMP::Mpz") || strEQ(h, "Math::GMPz"))
      gmp_randinit_lc_2exp(*state, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), (unsigned long)SvUV(c), (unsigned long)SvUV(m2exp));
    else croak("First arg to Rmpfr_randinit_lc_2exp is of invalid type");
  }
  else {
    if(!mpz_init_set_str(aa, SvPV_nolen(a), 0)) {
      gmp_randinit_lc_2exp(*state, aa, (unsigned long)SvUV(c), (unsigned long)SvUV(m2exp));
      mpz_clear(aa);
    }
    else croak("Seedstring supplied to Rmpfr_randinit_lc_2exp is not a valid number");
  }

  sv_setiv(obj, INT2PTR(IV,state));
  SvREADONLY_on(obj);
  return obj_ref;
}

SV * Rmpfr_randinit_lc_2exp_size(pTHX_ SV * size) {
  gmp_randstate_t * state;
  SV * obj_ref, * obj;

  if(SvUV(size) > 128) croak("The argument supplied to Rmpfr_randinit_lc_2exp_size function is too large - ie greater than 128");

  Newx(state, 1, gmp_randstate_t);
  if(state == NULL) croak("Failed to allocate memory in Rmpfr_randinit_lc_2exp_size function");
  obj_ref = newSV(0);
  obj = newSVrv(obj_ref, "Math::MPFR::Random");

  if(gmp_randinit_lc_2exp_size(*state, (unsigned long)SvUV(size))) {
    sv_setiv(obj, INT2PTR(IV,state));
    SvREADONLY_on(obj);
    return obj_ref;
  }

  croak("Rmpfr_randinit_lc_2exp_size function failed");
}

/* Provide a duplicate of Math::MPFR::_MPFR_VERSION. *
 * This allows MPFR.pm to determine the value of     *
 * MPFR_VERSION at compile time.                     */

SV * _MPFR_VERSION(pTHX) {
#if defined(MPFR_VERSION)
  return newSVuv(MPFR_VERSION);
#else
  return &PL_sv_undef;
#endif
}

/* Provide a duplicate of Math::MPFR::_has_pv_nv_bug. *
 * This allows MPFR.pm to determine the value of      *
 * the constant MPFR_PV_NV_BUG at compile time.       */

int _has_pv_nv_bug(void) {
#if defined(MPFR_PV_NV_BUG)
  return 1;
#else
  return 0;
#endif
}

void DESTROY(gmp_randstate_t * p) {
  gmp_randclear(*p);
  Safefree(p);
}

int _is_NOK_and_POK(SV * in) {
  if(SvNOK(in) && SvPOK(in)) return 1;
  return 0;
}

int _win32_fmt_bug_ignore(void) {
#if defined(WIN32_FMT_BUG_IGNORE)
  return 1;
#else
  return 0;
#endif
}

SV * _gmp_cflags(pTHX) {
#if defined(__GMP_CFLAGS)
  return newSVpv(__GMP_CFLAGS, 0);
#else
  return &PL_sv_undef;
#endif
}

SV * _gmp_cc(pTHX) {
#if defined(__GMP_CC)
  return newSVpv(__GMP_CC, 0);
#else
  return &PL_sv_undef;
#endif
}



MODULE = Math::MPFR::Random  PACKAGE = Math::MPFR::Random

PROTOTYPES: DISABLE


SV *
Rmpfr_randinit_default ()
CODE:
  RETVAL = Rmpfr_randinit_default (aTHX);
OUTPUT:  RETVAL


SV *
Rmpfr_randinit_mt ()
CODE:
  RETVAL = Rmpfr_randinit_mt (aTHX);
OUTPUT:  RETVAL


SV *
Rmpfr_randinit_lc_2exp (a, c, m2exp)
	SV *	a
	SV *	c
	SV *	m2exp
CODE:
  RETVAL = Rmpfr_randinit_lc_2exp (aTHX_ a, c, m2exp);
OUTPUT:  RETVAL

SV *
Rmpfr_randinit_lc_2exp_size (size)
	SV *	size
CODE:
  RETVAL = Rmpfr_randinit_lc_2exp_size (aTHX_ size);
OUTPUT:  RETVAL

SV *
_MPFR_VERSION ()
CODE:
  RETVAL = _MPFR_VERSION (aTHX);
OUTPUT:  RETVAL


int
_has_pv_nv_bug ()


int
_is_NOK_and_POK (in)
	SV *	in

int
_win32_fmt_bug_ignore ()


SV *
_gmp_cflags ()
CODE:
  RETVAL = _gmp_cflags (aTHX);
OUTPUT:  RETVAL


SV *
_gmp_cc ()
CODE:
  RETVAL = _gmp_cc (aTHX);
OUTPUT:  RETVAL


