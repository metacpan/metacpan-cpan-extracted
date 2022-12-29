
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

#ifndef MPC_RE
# define MPC_RE(x) ((x)->re)
#endif
#ifndef MPC_IM
# define MPC_IM(x) ((x)->im)
#endif

/*********************
 If the mpc library is not at version 1.3.0 or higher, then
 we allow this XS file to compile, by specifying the following
 compltely bogus typedefs - even though every function will
 croak() if called.
 TODO: Handle less insanely.
*********************/

#if MPC_VERSION < 66304
  typedef int mpcr_ptr;
  typedef double mpcb_t;
#endif

SV * Rmpcb_init(pTHX) {
#if MPC_VERSION >= 66304
  mpcb_t * mpcb_t_obj;
  SV * obj_ref, * obj;

  New(1, mpcb_t_obj, 1, mpcb_t);
  if(mpcb_t_obj == NULL) croak("Failed to allocate memory in Rmpcb_init function");
  obj_ref = newSV(0);
  obj = newSVrv(obj_ref, "Math::MPC::Ball");
  mpcb_init (*mpcb_t_obj);

  sv_setiv(obj, INT2PTR(IV,mpcb_t_obj));
  SvREADONLY_on(obj);
  return obj_ref;
#else
  croak("Rmpcb_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

SV * Rmpcb_init_nobless(pTHX) {
#if MPC_VERSION >= 66304
  mpcb_t * mpcb_t_obj;
  SV * obj_ref, * obj;

  New(1, mpcb_t_obj, 1, mpcb_t);
  if(mpcb_t_obj == NULL) croak("Failed to allocate memory in Rmpcb_init_nobless function");
  obj_ref = newSV(0);
  obj = newSVrv(obj_ref, NULL);
  mpcb_init (*mpcb_t_obj);

  sv_setiv(obj, INT2PTR(IV,mpcb_t_obj));
  SvREADONLY_on(obj);
  return obj_ref;
#else
  croak("Rmpcb_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void DESTROY(mpcb_t * p) {
#if MPC_VERSION >= 66304
     mpcb_clear(*p);
     Safefree(p);
#else
  croak("Rmpcb_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcb_clear(mpcb_t * p) {
#if MPC_VERSION >= 66304
     mpcb_clear(*p);
     Safefree(p);
#else
  croak("Rmpcb_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

SV *  Rmpcb_get_prec(pTHX_ mpcb_t * op) {
#if MPC_VERSION >= 66304
   return newSVuv(mpcb_get_prec(*op));
#else
  croak("Rmpcb_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcb_set(mpcb_t * rop, mpcb_t * op) {
#if MPC_VERSION >= 66304
   mpcb_set(*rop, *op);
#else
  croak("Rmpcb_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcb_set_inf(mpcb_t * op) {
#if MPC_VERSION >= 66304
   mpcb_set_inf(*op);
#else
  croak("Rmpcb_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcb_set_c(pTHX_ mpcb_t * rop, mpc_t * op, SV * prec, SV * err_re, SV * err_im) {
#if MPC_VERSION >= 66304
   mpcb_set_c(*rop, *op, (mpfr_prec_t)SvUV(prec),
              (unsigned long)SvUV(err_re), (unsigned long)SvUV(err_im));
#else
  croak("Rmpcb_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcb_set_ui_ui(pTHX_ mpcb_t * rop, SV * re, SV * im, SV * prec) {
#if MPC_VERSION >= 66304
   mpcb_set_ui_ui(*rop, (unsigned long)SvUV(re), (unsigned long)SvUV(im), (mpfr_prec_t)SvUV(prec));
#else
  croak("Rmpcb_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcb_neg(mpcb_t * rop, mpcb_t * op) {
#if MPC_VERSION >= 66304
   mpcb_neg(*rop, *op);
#else
  croak("Rmpcb_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcb_add(mpcb_t * rop, mpcb_t * op1, mpcb_t * op2) {
#if MPC_VERSION >= 66304
   mpcb_add(*rop, *op1, *op2);
#else
  croak("Rmpcb_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcb_mul(mpcb_t * rop, mpcb_t * op1, mpcb_t * op2) {
#if MPC_VERSION >= 66304
   mpcb_mul(*rop, *op1, *op2);
#else
  croak("Rmpcb_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcb_sqr(mpcb_t * rop, mpcb_t * op) {
#if MPC_VERSION >= 66304
   mpcb_sqr(*rop, *op);
#else
  croak("Rmpcb_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcb_pow_ui(pTHX_ mpcb_t * rop, mpcb_t * op, SV * ui) {
#if MPC_VERSION >= 66304
   mpcb_pow_ui(*rop, *op, (unsigned long)SvUV(ui));
#else
  croak("Rmpcb_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcb_sqrt(mpcb_t * rop, mpcb_t * op) {
#if MPC_VERSION >= 66304
   mpcb_sqrt(*rop, *op);
#else
  croak("Rmpcb_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcb_div(mpcb_t * rop, mpcb_t * op1, mpcb_t * op2) {
#if MPC_VERSION >= 66304
   mpcb_div(*rop, *op1, *op2);
#else
  croak("Rmpcb_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcb_div_2ui(pTHX_ mpcb_t * rop, mpcb_t * op, SV * ui) {
#if MPC_VERSION >= 66304
  mpcb_div_2ui(*rop, *op, (unsigned long)SvUV(ui));
#else
  croak("Rmpcb_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

int Rmpcb_can_round(pTHX_ mpcb_t * op, SV * prec_re, SV * prec_im, SV * round) {
#if MPC_VERSION >= 66304
  return mpcb_can_round(*op, (mpfr_prec_t)SvUV(prec_re), (mpfr_prec_t)SvUV(prec_im),
                        (mpc_rnd_t)SvUV(round));
#else
  croak("Rmpcb_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

int Rmpcb_round(pTHX_ mpc_t * rop, mpcb_t * op, SV * round) {
#if MPC_VERSION >= 66304
  return mpcb_round(*rop, *op, (mpc_rnd_t)SvUV(round));
#else
  croak("Rmpcb_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}

void Rmpcb_retrieve(mpc_t * rop1, mpcr_ptr rop2, mpcb_t * op) {
#if MPC_VERSION >= 66304
  mp_prec_t re, im;
  mpc_get_prec2(&re, &im, (*op)->c);
  mpfr_set_prec(MPC_RE(*rop1), re);
  mpfr_set_prec(MPC_IM(*rop1), im);
  mpc_set(*rop1, (*op)->c, MPC_RNDNN);
  mpcr_set(rop2, (*op)->r);
#else
  croak("Rmpcb_* functions need mpc-1.3.0. This is only mpc-%s", MPC_VERSION_STRING);
#endif
}





MODULE = Math::MPC::Ball  PACKAGE = Math::MPC::Ball

PROTOTYPES: DISABLE


SV *
Rmpcb_init ()
CODE:
  RETVAL = Rmpcb_init (aTHX);
OUTPUT:  RETVAL

SV *
Rmpcb_init_nobless ()
CODE:
  RETVAL = Rmpcb_init_nobless (aTHX);
OUTPUT:  RETVAL

void
DESTROY (p)
	mpcb_t *	p
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        DESTROY(p);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpcb_clear (p)
	mpcb_t *	p
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpcb_clear(p);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
Rmpcb_get_prec (op)
	mpcb_t *	op
CODE:
  RETVAL = Rmpcb_get_prec (aTHX_ op);
OUTPUT:  RETVAL

void
Rmpcb_set (rop, op)
	mpcb_t *	rop
	mpcb_t *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpcb_set(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpcb_set_inf (op)
	mpcb_t *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpcb_set_inf(op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpcb_set_c (rop, op, prec, err_re, err_im)
	mpcb_t *	rop
	mpc_t *	op
	SV *	prec
	SV *	err_re
	SV *	err_im
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpcb_set_c(aTHX_ rop, op, prec, err_re, err_im);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpcb_set_ui_ui (rop, re, im, prec)
	mpcb_t *	rop
	SV *	re
	SV *	im
	SV *	prec
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpcb_set_ui_ui(aTHX_ rop, re, im, prec);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpcb_neg (rop, op)
	mpcb_t *	rop
	mpcb_t *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpcb_neg(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpcb_add (rop, op1, op2)
	mpcb_t *	rop
	mpcb_t *	op1
	mpcb_t *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpcb_add(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpcb_mul (rop, op1, op2)
	mpcb_t *	rop
	mpcb_t *	op1
	mpcb_t *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpcb_mul(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpcb_sqr (rop, op)
	mpcb_t *	rop
	mpcb_t *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpcb_sqr(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpcb_pow_ui (rop, op, ui)
	mpcb_t *	rop
	mpcb_t *	op
	SV *	ui
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpcb_pow_ui(aTHX_ rop, op, ui);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpcb_sqrt (rop, op)
	mpcb_t *	rop
	mpcb_t *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpcb_sqrt(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpcb_div (rop, op1, op2)
	mpcb_t *	rop
	mpcb_t *	op1
	mpcb_t *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpcb_div(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpcb_div_2ui (rop, op, ui)
	mpcb_t *	rop
	mpcb_t *	op
	SV *	ui
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpcb_div_2ui(aTHX_ rop, op, ui);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
Rmpcb_can_round (op, prec_re, prec_im, round)
	mpcb_t *	op
	SV *	prec_re
	SV *	prec_im
	SV *	round
CODE:
  RETVAL = Rmpcb_can_round (aTHX_ op, prec_re, prec_im, round);
OUTPUT:  RETVAL

int
Rmpcb_round (rop, op, round)
	mpc_t *	rop
	mpcb_t *	op
	SV *	round
CODE:
  RETVAL = Rmpcb_round (aTHX_ rop, op, round);
OUTPUT:  RETVAL

void
Rmpcb_retrieve (rop1, rop2, op)
	mpc_t *	rop1
	mpcr_ptr	rop2
	mpcb_t *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpcb_retrieve(rop1, rop2, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

