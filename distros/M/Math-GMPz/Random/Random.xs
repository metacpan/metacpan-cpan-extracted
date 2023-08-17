
#ifdef  __MINGW32__
#ifndef __USE_MINGW_ANSI_STDIO
#define __USE_MINGW_ANSI_STDIO 1
#endif
#endif

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <stdlib.h>
#include <gmp.h>

#if !defined(__GNU_MP_VERSION) || __GNU_MP_VERSION < 5
#define mp_bitcnt_t unsigned long int
#endif

#ifndef Newx
#  define Newx(v,n,t) New(0,v,n,t)
#endif

#ifndef Newxz
#  define Newxz(v,n,t) Newz(0,v,n,t)
#endif

SV * Rgmp_randinit_default(pTHX) {
     gmp_randstate_t * rand_obj;
     SV * obj_ref, * obj;

     New(1, rand_obj, 1, gmp_randstate_t);
     if(rand_obj == NULL) croak("Failed to allocate memory in Math::GMPz::Random::Rgmp_randinit_default function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPz::Random");
     gmp_randinit_default(*rand_obj);

     sv_setiv(obj, INT2PTR(IV, rand_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * Rgmp_randinit_mt(pTHX) {
     gmp_randstate_t * rand_obj;
     SV * obj_ref, * obj;

     New(1, rand_obj, 1, gmp_randstate_t);
     if(rand_obj == NULL) croak("Failed to allocate memory in Math::GMPz::Random::Rgmp_randinit_mt function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPz::Random");
     gmp_randinit_mt(*rand_obj);

     sv_setiv(obj, INT2PTR(IV, rand_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * Rgmp_randinit_lc_2exp(pTHX_ mpz_t* a, SV * c, SV * m2exp) {
     gmp_randstate_t * rand_obj;
     SV * obj_ref, * obj;

     New(1, rand_obj, 1, gmp_randstate_t);
     if(rand_obj == NULL) croak("Failed to allocate memory in Math::GMPz::Random::Rgmp_randinit_lc_2exp function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPz::Random");
     gmp_randinit_lc_2exp(*rand_obj, *a, (unsigned long)SvUV(c), (mp_bitcnt_t)SvUV(m2exp));

     sv_setiv(obj, INT2PTR(IV, rand_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * Rgmp_randinit_lc_2exp_size(pTHX_ SV * size) {
     gmp_randstate_t * rand_obj, t;
     SV * obj_ref, * obj;
     int ret;

     /* Check that 'size' is not too large ... and croak immediately if it is. */
     /* This way we should be able to croak cleanly. If we croak near the end of the sub */
     /* we're liable to get strange segfaults and/or free to wrong pool errors */
     ret = gmp_randinit_lc_2exp_size(t,(mp_bitcnt_t)SvUV(size));
     if(!ret) croak ("gmp_randinit_lc_2exp_size function failed. Did you specify a value for 'size'that is bigger than the table provides ?");
     gmp_randclear(t); /* Served it's purpose ... no longer needed */

     New(1, rand_obj, 1, gmp_randstate_t);
     if(rand_obj == NULL) croak("Failed to allocate memory in Math::GMPz::Random::Rgmp_randinit_lc_2exp_size function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPz::Random");
     ret = gmp_randinit_lc_2exp_size(*rand_obj,(mp_bitcnt_t)SvUV(size));
     sv_setiv(obj, INT2PTR(IV, rand_obj));
     SvREADONLY_on(obj);
     if(!ret) croak ("Second call to gmp_randinit_lc_2exp_size function failed. Did you specify a value for 'size'that is bigger than the table provides ?");
     return obj_ref;
}

SV * Rgmp_randinit_set(pTHX_ gmp_randstate_t * op) {
     gmp_randstate_t * rand_obj;
     SV * obj_ref, * obj;

     New(1, rand_obj, 1, gmp_randstate_t);
     if(rand_obj == NULL) croak("Failed to allocate memory in Math::GMPz::Random::Rgmp_randinit_set function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPz::Random");
     gmp_randinit_set(*rand_obj, *op);

     sv_setiv(obj, INT2PTR(IV, rand_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * Rgmp_urandomb_ui(pTHX_ gmp_randstate_t * state, SV * n) {
     unsigned int max, req = (unsigned int)SvUV(n);
     max = sizeof(unsigned long) * 8;
     if(req > max) croak("In Math::GMPz::Random::Rgmp_urandomb_ui, requested %u bits, but %u is the maximum allowed", req, max);
     return newSVuv(gmp_urandomb_ui(*state, req));
}

SV * Rgmp_urandomm_ui(pTHX_ gmp_randstate_t * state, SV * n) {
     return newSVuv(gmp_urandomm_ui(*state, (unsigned long)SvUV(n)));
}

/*##########################################*/

SV * Rgmp_randinit_default_nobless(pTHX) {
     gmp_randstate_t * rand_obj;
     SV * obj_ref, * obj;

     New(1, rand_obj, 1, gmp_randstate_t);
     if(rand_obj == NULL) croak("Failed to allocate memory in Math::GMPz::Random::Rgmp_randinit_default_nobless function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, NULL);
     gmp_randinit_default(*rand_obj);

     sv_setiv(obj, INT2PTR(IV, rand_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * Rgmp_randinit_mt_nobless(pTHX) {
     gmp_randstate_t * rand_obj;
     SV * obj_ref, * obj;

     New(1, rand_obj, 1, gmp_randstate_t);
     if(rand_obj == NULL) croak("Failed to allocate memory in Math::GMPz::Random::Rgmp_randinit_mt_nobless function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, NULL);
     gmp_randinit_mt(*rand_obj);

     sv_setiv(obj, INT2PTR(IV, rand_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * Rgmp_randinit_lc_2exp_nobless(pTHX_ mpz_t* a, SV * c, SV * m2exp) {
     gmp_randstate_t * rand_obj;
     SV * obj_ref, * obj;

     New(1, rand_obj, 1, gmp_randstate_t);
     if(rand_obj == NULL) croak("Failed to allocate memory in Math::GMPz::Random::Rgmp_randinit_lc_2exp_nobless function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, NULL);
     gmp_randinit_lc_2exp(*rand_obj, *a, (unsigned long)SvUV(c), (mp_bitcnt_t)SvUV(m2exp));

     sv_setiv(obj, INT2PTR(IV, rand_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * Rgmp_randinit_lc_2exp_size_nobless(pTHX_ SV * size) {
     gmp_randstate_t * rand_obj;
     SV * obj_ref, * obj;
     int ret;

     New(1, rand_obj, 1, gmp_randstate_t);
     if(rand_obj == NULL) croak("Failed to allocate memory in Math::GMPz::Random::Rgmp_randinit_lc_2exp_size_nobless function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, NULL);
     ret = gmp_randinit_lc_2exp_size(*rand_obj,(mp_bitcnt_t)SvUV(size));
     if(!ret) croak ("gmp_randinit_lc_2exp_size_nobless function failed. Did you specify a value for 'size'that is bigger than the table provides ?");

     sv_setiv(obj, INT2PTR(IV, rand_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * Rgmp_randinit_set_nobless(pTHX_ gmp_randstate_t * op) {
     gmp_randstate_t * rand_obj;
     SV * obj_ref, * obj;

     New(1, rand_obj, 1, gmp_randstate_t);
     if(rand_obj == NULL) croak("Failed to allocate memory in Math::GMPz::Random::Rgmp_randinit_set_nobless function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, NULL);
     gmp_randinit_set(*rand_obj, *op);

     sv_setiv(obj, INT2PTR(IV, rand_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

/*##########################################*/

void Rgmp_randseed(pTHX_ gmp_randstate_t * state, mpz_t * seed) {
     gmp_randseed(*state, *seed);
}

void Rgmp_randseed_ui(pTHX_ gmp_randstate_t * state, SV * seed) {
     gmp_randseed_ui(*state, (unsigned long int)SvUV(seed));
}

void DESTROY(pTHX_ gmp_randstate_t * p) {
/*     printf("Destroying gmp_randstate "); */
     gmp_randclear(*p);
/*     printf("...cleared "); */
     Safefree(p);
/*     printf("...destroyed\n"); */
}

void Rgmp_randclear(pTHX_ gmp_randstate_t * p) {
/* clear gmp_randstate_t and free the perl object */
     gmp_randclear(*p);
     Safefree(p);
}

void Rgmp_randclear_state(pTHX_ gmp_randstate_t * p) {
/* clear gmp_randstate_t only */
     gmp_randclear(*p);
}

void Rgmp_randclear_ptr(pTHX_ gmp_randstate_t * p) {
/* free perl object only */
     Safefree(p);
}

SV * _wrap_count(pTHX) {
     return newSVuv(PL_sv_count);
}

/* Provide a duplicate of Math::GMPz::_has_pv_nv_bug. *
 * This allows GMPz.pm to determine the value of      *
 * the constant GMPZ_PV_NV_BUG at compile time.       */

int _has_pv_nv_bug(void) {
#if defined(GMPZ_PV_NV_BUG)
     return 1;
#else
     return 0;
#endif
}


MODULE = Math::GMPz::Random  PACKAGE = Math::GMPz::Random

PROTOTYPES: DISABLE


SV *
Rgmp_randinit_default ()
CODE:
  RETVAL = Rgmp_randinit_default (aTHX);
OUTPUT:  RETVAL


SV *
Rgmp_randinit_mt ()
CODE:
  RETVAL = Rgmp_randinit_mt (aTHX);
OUTPUT:  RETVAL


SV *
Rgmp_randinit_lc_2exp (a, c, m2exp)
	mpz_t *	a
	SV *	c
	SV *	m2exp
CODE:
  RETVAL = Rgmp_randinit_lc_2exp (aTHX_ a, c, m2exp);
OUTPUT:  RETVAL

SV *
Rgmp_randinit_lc_2exp_size (size)
	SV *	size
CODE:
  RETVAL = Rgmp_randinit_lc_2exp_size (aTHX_ size);
OUTPUT:  RETVAL

SV *
Rgmp_randinit_set (op)
	gmp_randstate_t *	op
CODE:
  RETVAL = Rgmp_randinit_set (aTHX_ op);
OUTPUT:  RETVAL

SV *
Rgmp_urandomb_ui (state, n)
	gmp_randstate_t *	state
	SV *	n
CODE:
  RETVAL = Rgmp_urandomb_ui (aTHX_ state, n);
OUTPUT:  RETVAL

SV *
Rgmp_urandomm_ui (state, n)
	gmp_randstate_t *	state
	SV *	n
CODE:
  RETVAL = Rgmp_urandomm_ui (aTHX_ state, n);
OUTPUT:  RETVAL

SV *
Rgmp_randinit_default_nobless ()
CODE:
  RETVAL = Rgmp_randinit_default_nobless (aTHX);
OUTPUT:  RETVAL


SV *
Rgmp_randinit_mt_nobless ()
CODE:
  RETVAL = Rgmp_randinit_mt_nobless (aTHX);
OUTPUT:  RETVAL


SV *
Rgmp_randinit_lc_2exp_nobless (a, c, m2exp)
	mpz_t *	a
	SV *	c
	SV *	m2exp
CODE:
  RETVAL = Rgmp_randinit_lc_2exp_nobless (aTHX_ a, c, m2exp);
OUTPUT:  RETVAL

SV *
Rgmp_randinit_lc_2exp_size_nobless (size)
	SV *	size
CODE:
  RETVAL = Rgmp_randinit_lc_2exp_size_nobless (aTHX_ size);
OUTPUT:  RETVAL

SV *
Rgmp_randinit_set_nobless (op)
	gmp_randstate_t *	op
CODE:
  RETVAL = Rgmp_randinit_set_nobless (aTHX_ op);
OUTPUT:  RETVAL

void
Rgmp_randseed (state, seed)
	gmp_randstate_t *	state
	mpz_t *	seed
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rgmp_randseed(aTHX_ state, seed);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rgmp_randseed_ui (state, seed)
	gmp_randstate_t *	state
	SV *	seed
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rgmp_randseed_ui(aTHX_ state, seed);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
DESTROY (p)
	gmp_randstate_t *	p
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        DESTROY(aTHX_ p);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rgmp_randclear (p)
	gmp_randstate_t *	p
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rgmp_randclear(aTHX_ p);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rgmp_randclear_state (p)
	gmp_randstate_t *	p
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rgmp_randclear_state(aTHX_ p);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rgmp_randclear_ptr (p)
	gmp_randstate_t *	p
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rgmp_randclear_ptr(aTHX_ p);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
_wrap_count ()
CODE:
  RETVAL = _wrap_count (aTHX);
OUTPUT:  RETVAL


int
_has_pv_nv_bug ()


