
#ifdef  __MINGW32__
#ifndef __USE_MINGW_ANSI_STDIO
#define __USE_MINGW_ANSI_STDIO 1
#endif
#endif

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <mpc.h>
#include <inttypes.h>

/*********************
 If the mpc library is not at version 1.3.0 or higher, then
 we allow this XS file to compile, by specifying the following
 compltely bogus typedef - even though every function will
 croak() if called.
 TODO: Handle less insanely.
*********************/

#if MPC_VERSION < 66304
  typedef int mpcr_ptr;
#endif

SV * Rmpcr_init(pTHX) {
#if MPC_VERSION >= 66304
  mpcr_t * mpcr_t_obj;
  SV * obj_ref, * obj;

  New(1, mpcr_t_obj, 1, mpcr_t);
  if(mpcr_t_obj == NULL) croak("Failed to allocate memory in Rmpcr_init function");
  obj_ref = newSV(0);
  obj = newSVrv(obj_ref, "Math::MPC::Radius");
  mpcr_set_zero(*mpcr_t_obj);

  sv_setiv(obj, INT2PTR(IV,mpcr_t_obj));
  SvREADONLY_on(obj);
  return obj_ref;
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

SV * Rmpcr_init_nobless(pTHX) {
#if MPC_VERSION >= 66304
  mpcr_t * mpcr_t_obj;
  SV * obj_ref, * obj;

  New(1, mpcr_t_obj, 1, mpcr_t);
  if(mpcr_t_obj == NULL) croak("Failed to allocate memory in Rmpcr_init_nobless function");
  obj_ref = newSV(0);
  obj = newSVrv(obj_ref, NULL);
  mpcr_set_zero(*mpcr_t_obj);

  sv_setiv(obj, INT2PTR(IV,mpcr_t_obj));
  SvREADONLY_on(obj);
  return obj_ref;
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcr_set_str_2str(mpcr_ptr rop, char * mantissa, char* exponent) {
#if MPC_VERSION >= 66304
  int64_t m, e;
  char c;
  int scanned = sscanf(mantissa, "%" SCNd64 "%c", &m, &c);
  if(scanned < 1) croak("Scan of first input (%s) to Rmpc_set_str failed", mantissa);
  if(scanned > 1) warn("Extra data found in scan of first input (%s) to Rmpc_set_str", mantissa);

  scanned = sscanf(exponent, "%" SCNd64 "%c", &e, &c);
  if(scanned < 1) croak("Scan of second input (%s) to Rmpc_set_str failed", exponent);
  if(scanned > 1) warn("Extra data found in scan of second input (%s) to Rmpc_set_str", exponent);
  mpcr_set_ui64_2si64(rop, m, e);
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcr_clear(mpcr_ptr op) {
#if MPC_VERSION >= 66304
# ifdef MATH_MPC_DEBUG
  printf("Rmpcr_clear()ing mpcr_ptr\n");
# endif
  Safefree(op);
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void DESTROY(mpcr_ptr op) {
#if MPC_VERSION >= 66304
# ifdef MATH_MPC_DEBUG
  printf("DESTROYing mpcr_ptr\n");
# endif
  Safefree(op);
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

int Rmpcr_inf_p(mpcr_ptr op) {
#if MPC_VERSION >= 66304
   return mpcr_inf_p(op);
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

int Rmpcr_zero_p(mpcr_ptr op) {
#if MPC_VERSION >= 66304
   return mpcr_zero_p(op);
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

int Rmpcr_lt_half_p(mpcr_ptr op) {
#if MPC_VERSION >= 66304
   return mpcr_lt_half_p(op);
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

int Rmpcr_cmp(mpcr_ptr op1, mpcr_ptr op2) {
#if MPC_VERSION >= 66304
   return mpcr_cmp(op1, op2);
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcr_set_inf(mpcr_ptr op) {
#if MPC_VERSION >= 66304
  mpcr_set_inf(op);
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcr_set_zero(mpcr_ptr op) {
#if MPC_VERSION >= 66304
  mpcr_set_zero(op);
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcr_set_one(mpcr_ptr op) {
#if MPC_VERSION >= 66304
  mpcr_set_one(op);
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcr_set(mpcr_ptr rop, mpcr_ptr op) {
#if MPC_VERSION >= 66304
  mpcr_set(rop, op);
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcr_set_ui64_2si64(pTHX_ mpcr_ptr rop, UV mantissa, IV exponent) {
#if MPC_VERSION >= 66304
   mpcr_set_ui64_2si64(rop,mantissa, exponent);
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcr_max (mpcr_ptr rop, mpcr_ptr op1, mpcr_ptr op2) {
#if MPC_VERSION >= 66304
   mpcr_max(rop, op1, op2);
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

IV Rmpcr_get_exp (mpcr_ptr op) {
#if MPC_VERSION >= 66304
   int64_t ret;
   ret = mpcr_get_exp(op);
#  if IVSIZE < 8
   if(ret > IV_MAX || ret < IV_MIN) {
     warn("return value of Rmpcr_get_exp function overflows IV\n");
     croak("Use Rmpcr_get_exp_mpfr function instead");
   }
#  endif
   return (IV)ret;
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

SV * Rmpcr_get_exp_mpfr (pTHX_ mpcr_ptr op) {
#if MPC_VERSION >= 66304
  mpfr_t * mpfr_t_obj;
  SV * obj_ref, * obj;
  int64_t exponent;

  New(1, mpfr_t_obj, 1, mpfr_t);
  if(mpfr_t_obj == NULL) croak("Failed to allocate memory in Rmpcr_get_exp_mpfr function");
  obj_ref = newSV(0);
  obj = newSVrv(obj_ref, "Math::MPFR");
  exponent = mpcr_get_exp(op);
  mpfr_init2 (*mpfr_t_obj, 64);
  mpfr_set_sj(*mpfr_t_obj, exponent, 0); /* MPFR_RNDN */

  sv_setiv(obj, INT2PTR(IV,mpfr_t_obj));
  SvREADONLY_on(obj);
  return obj_ref;
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcr_out_str (pTHX_ FILE *stream, mpcr_ptr op) {
#if MPC_VERSION >= 66304
  mpcr_out_str(stream, op);
  fflush(stream);
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcr_out_str_win (pTHX_ FILE *stream, mpcr_ptr op) {
#if MPC_VERSION >= 66304
#  ifdef _WIN32
   int cp = GetConsoleOutputCP();
   SetConsoleOutputCP(65001);
   mpcr_out_str(stream, op);
   fflush(stream);
   SetConsoleOutputCP(cp);
#  else
   croak("Rmpcr_out_str_win is for MS Windows only");
#  endif
#else
   croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcr_print (pTHX_ mpcr_ptr op) {
#if MPC_VERSION >= 66304
 mpcr_out_str(stdout, op);
 fflush(stdout);
#else
 croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcr_print_win (pTHX_ mpcr_ptr op) {
#if MPC_VERSION >= 66304
#  ifdef _WIN32
   int cp = GetConsoleOutputCP();
   SetConsoleOutputCP(65001);
   mpcr_out_str(stdout, op);
   fflush(stdout);
   SetConsoleOutputCP(cp);
#  else
   croak("Rmpcr_print_win is for MS Windows only");
#  endif
#else
   croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcr_say (pTHX_ mpcr_ptr op) {
#if MPC_VERSION >= 66304
  mpcr_out_str(stdout, op);
  printf("\n");
  fflush(stdout);
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcr_say_win (pTHX_ mpcr_ptr op) {
#if MPC_VERSION >= 66304
#  ifdef _WIN32
   int cp = GetConsoleOutputCP();
   SetConsoleOutputCP(65001);
   mpcr_out_str(stdout, op);
   printf("\n");
   fflush(stdout);
   SetConsoleOutputCP(cp);
#  else
   croak("Rmpcr_say_win is for MS Windows only");
#  endif
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcr_add (mpcr_ptr rop, mpcr_ptr op1, mpcr_ptr op2) {
#if MPC_VERSION >= 66304
   mpcr_add(rop, op1, op2);
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcr_sub (mpcr_ptr rop, mpcr_ptr op1, mpcr_ptr op2) {
#if MPC_VERSION >= 66304
   mpcr_sub(rop, op1, op2);
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcr_mul (mpcr_ptr rop, mpcr_ptr op1, mpcr_ptr op2) {
#if MPC_VERSION >= 66304
   mpcr_mul(rop, op1, op2);
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcr_div (mpcr_ptr rop, mpcr_ptr op1, mpcr_ptr op2) {
#if MPC_VERSION >= 66304
   mpcr_div(rop, op1, op2);
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcr_mul_2ui (mpcr_ptr rop, mpcr_ptr op, unsigned long ui) {
#if MPC_VERSION >= 66304
   mpcr_mul_2ui(rop, op, ui);
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcr_div_2ui (mpcr_ptr rop, mpcr_ptr op, unsigned long ui) {
#if MPC_VERSION >= 66304
   mpcr_div_2ui(rop, op, ui);
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcr_sqr (mpcr_ptr rop, mpcr_ptr op) {
#if MPC_VERSION >= 66304
   mpcr_sqr(rop, op);
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcr_sqrt (mpcr_ptr rop, mpcr_ptr op) {
#if MPC_VERSION >= 66304
   mpcr_sqrt(rop, op);
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcr_sub_rnd (pTHX_ mpcr_ptr rop, mpcr_ptr op1, mpcr_ptr op2, SV * round) {
#if MPC_VERSION >= 66304
   mpcr_sub_rnd(rop, op1, op2, (mpfr_rnd_t)SvUV(round));
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcr_c_abs_rnd (pTHX_ mpcr_ptr rop, mpc_ptr mpc_op, SV * round) { /* mpc_ptr arg */
#if MPC_VERSION >= 66304
   mpcr_c_abs_rnd(rop, mpc_op, (mpfr_rnd_t)SvUV(round));
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcr_add_rounding_error (pTHX_ mpcr_ptr rop, SV * op, SV * round) {
#if MPC_VERSION >= 66304
   mpcr_add_rounding_error(rop, (mpfr_prec_t)SvUV(op), (mpfr_rnd_t)SvUV(round));
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcr_split(pTHX_  mpcr_ptr op) {
#if MPC_VERSION >= 66304
   dXSARGS;

   if(mpcr_zero_p(op)) {
     ST(0) = sv_2mortal(newSVuv(0));
     XSRETURN(1);
   }

   if(mpcr_inf_p(op)) {
     ST(0) = sv_2mortal(newSVpv("Inf", 0));
     XSRETURN(1);
   }

#  if IVSIZE < 8
   if(op->mant > UV_MAX) {
     warn("mantissa overflows UV in Rmpcr_split function\n");
     croak("Use Rmpcr_split_mpfr function instead");
   }

   if(op->exp > IV_MAX || op->exp < IV_MIN) {
     warn("exponent overflows IV in Rmpcr_split function\n");
     croak("Use Rmpcr_split_mpfr function instead");
   }
#  endif

   ST(0) = sv_2mortal(newSVuv(op->mant));
   ST(1) = sv_2mortal(newSViv(op->exp));
   XSRETURN(2);
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

SV * _get_radius_mantissa(pTHX_  mpcr_ptr op) {
#if MPC_VERSION >= 66304
  mpfr_t * mpfr_t_obj;
  SV * obj_ref, * obj;

  /* For use of Rmpcr_split_mpfr. Check that op is neither Inf nor 0 */
  if(mpcr_zero_p(op) || mpcr_inf_p(op)) croak("_get_radius_mantissa function does not handle Inf or 0");

  New(1, mpfr_t_obj, 1, mpfr_t);
  if(mpfr_t_obj == NULL) croak("Failed to allocate memory in Rmpcr_split_mpfr function");
  obj_ref = newSV(0);
  obj = newSVrv(obj_ref, "Math::MPFR");
  mpfr_init2 (*mpfr_t_obj, 64);
  mpfr_set_uj(*mpfr_t_obj, op->mant, 0); /* MPFR_RNDN */

  sv_setiv(obj, INT2PTR(IV,mpfr_t_obj));
  SvREADONLY_on(obj);
  return obj_ref;
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

SV * _get_radius_exponent(pTHX_  mpcr_ptr op) {
#if MPC_VERSION >= 66304
  mpfr_t * mpfr_t_obj;
  SV * obj_ref, * obj;

  /* For use of Rmpcr_split_mpfr. Check that op is neither Inf nor 0 */
  if(mpcr_zero_p(op) || mpcr_inf_p(op)) croak("_get_radius_exponent function does not handle Inf or 0");

  New(1, mpfr_t_obj, 1, mpfr_t);
  if(mpfr_t_obj == NULL) croak("Failed to allocate memory in Rmpcr_split_mpfr function");
  obj_ref = newSV(0);
  obj = newSVrv(obj_ref, "Math::MPFR");
  mpfr_init2 (*mpfr_t_obj, 64);
  mpfr_set_sj(*mpfr_t_obj, op->exp, 0); /* MPFR_RNDN */

  sv_setiv(obj, INT2PTR(IV,mpfr_t_obj));
  SvREADONLY_on(obj);
  return obj_ref;
#else
  croak("Rmpcr_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

MODULE = Math::MPC::Radius  PACKAGE = Math::MPC::Radius

PROTOTYPES: DISABLE


SV *
Rmpcr_init ()
CODE:
  RETVAL = Rmpcr_init (aTHX);
OUTPUT:  RETVAL

SV *
Rmpcr_init_nobless ()
CODE:
  RETVAL = Rmpcr_init_nobless (aTHX);
OUTPUT:  RETVAL

void
Rmpcr_set_str_2str (rop, mantissa, exponent)
	mpcr_ptr	rop
	char *	mantissa
	char *	exponent
        CODE:
        Rmpcr_set_str_2str(rop, mantissa, exponent);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpcr_clear (op)
	mpcr_ptr	op
        CODE:
        Rmpcr_clear(op);
        XSRETURN_EMPTY; /* return empty stack */

void
DESTROY (op)
	mpcr_ptr	op
        CODE:
        DESTROY(op);
        XSRETURN_EMPTY; /* return empty stack */

int
Rmpcr_inf_p (op)
	mpcr_ptr	op

int
Rmpcr_zero_p (op)
	mpcr_ptr	op

int
Rmpcr_lt_half_p (op)
	mpcr_ptr	op

int
Rmpcr_cmp (op1, op2)
	mpcr_ptr	op1
	mpcr_ptr	op2

void
Rmpcr_set_inf (op)
	mpcr_ptr	op
        CODE:
        Rmpcr_set_inf(op);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpcr_set_zero (op)
	mpcr_ptr	op
        CODE:
        Rmpcr_set_zero(op);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpcr_set_one (op)
	mpcr_ptr	op
        CODE:
        Rmpcr_set_one(op);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpcr_set (rop, op)
	mpcr_ptr	rop
	mpcr_ptr	op
        CODE:
        Rmpcr_set(rop, op);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpcr_set_ui64_2si64 (rop, mantissa, exponent)
	mpcr_ptr	rop
	UV	mantissa
	IV	exponent
        CODE:
        Rmpcr_set_ui64_2si64(aTHX_ rop, mantissa, exponent);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpcr_max (rop, op1, op2)
	mpcr_ptr	rop
	mpcr_ptr	op1
	mpcr_ptr	op2
        CODE:
        Rmpcr_max(rop, op1, op2);
        XSRETURN_EMPTY; /* return empty stack */

IV
Rmpcr_get_exp (op)
	mpcr_ptr	op

SV *
Rmpcr_get_exp_mpfr (op)
	mpcr_ptr	op
CODE:
  RETVAL = Rmpcr_get_exp_mpfr (aTHX_ op);
OUTPUT:  RETVAL

void
Rmpcr_out_str (stream, op)
	FILE *	stream
	mpcr_ptr	op
        CODE:
        Rmpcr_out_str(aTHX_ stream, op);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpcr_out_str_win (stream, op)
	FILE *	stream
	mpcr_ptr	op
        CODE:
        Rmpcr_out_str_win(aTHX_ stream, op);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpcr_print (op)
	mpcr_ptr	op
        CODE:
        Rmpcr_print(aTHX_ op);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpcr_print_win (op)
	mpcr_ptr	op
        CODE:
        Rmpcr_print_win(aTHX_ op);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpcr_say (op)
	mpcr_ptr	op
        CODE:
        Rmpcr_say(aTHX_ op);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpcr_say_win (op)
	mpcr_ptr	op
        CODE:
        Rmpcr_say_win(aTHX_ op);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpcr_add (rop, op1, op2)
	mpcr_ptr	rop
	mpcr_ptr	op1
	mpcr_ptr	op2
        CODE:
        Rmpcr_add(rop, op1, op2);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpcr_sub (rop, op1, op2)
	mpcr_ptr	rop
	mpcr_ptr	op1
	mpcr_ptr	op2
        CODE:
        Rmpcr_sub(rop, op1, op2);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpcr_mul (rop, op1, op2)
	mpcr_ptr	rop
	mpcr_ptr	op1
	mpcr_ptr	op2
        CODE:
        Rmpcr_mul(rop, op1, op2);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpcr_div (rop, op1, op2)
	mpcr_ptr	rop
	mpcr_ptr	op1
	mpcr_ptr	op2
        CODE:
        Rmpcr_div(rop, op1, op2);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpcr_mul_2ui (rop, op, ui)
	mpcr_ptr	rop
	mpcr_ptr	op
	unsigned long	ui
        CODE:
        Rmpcr_mul_2ui(rop, op, ui);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpcr_div_2ui (rop, op, ui)
	mpcr_ptr	rop
	mpcr_ptr	op
	unsigned long	ui
        CODE:
        Rmpcr_div_2ui(rop, op, ui);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpcr_sqr (rop, op)
	mpcr_ptr	rop
	mpcr_ptr	op
        CODE:
        Rmpcr_sqr(rop, op);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpcr_sqrt (rop, op)
	mpcr_ptr	rop
	mpcr_ptr	op
        CODE:
        Rmpcr_sqrt(rop, op);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpcr_sub_rnd (rop, op1, op2, round)
	mpcr_ptr	rop
	mpcr_ptr	op1
	mpcr_ptr	op2
	SV *	round
        CODE:
        Rmpcr_sub_rnd(aTHX_ rop, op1, op2, round);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpcr_c_abs_rnd (rop, mpc_op, round)
	mpcr_ptr	rop
	mpc_ptr	mpc_op
	SV *	round
        CODE:
        Rmpcr_c_abs_rnd(aTHX_ rop, mpc_op, round);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpcr_add_rounding_error (rop, op, round)
	mpcr_ptr	rop
	SV *	op
	SV *	round
        CODE:
        Rmpcr_add_rounding_error(aTHX_ rop, op, round);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpcr_split (op)
	mpcr_ptr	op
        CODE:
        PL_markstack_ptr++;
        Rmpcr_split(aTHX_ op);
        return; /* assume stack size is correct */

SV *
_get_radius_mantissa (op)
	mpcr_ptr	op
CODE:
  RETVAL = _get_radius_mantissa (aTHX_ op);
OUTPUT:  RETVAL

SV *
_get_radius_exponent (op)
	mpcr_ptr	op
CODE:
  RETVAL = _get_radius_exponent (aTHX_ op);
OUTPUT:  RETVAL

