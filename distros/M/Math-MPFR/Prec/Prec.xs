
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

#ifdef OLDPERL
#define SvUOK SvIsUV
#endif

#ifndef Newx
#  define Newx(v,n,t) New(0,v,n,t)
#endif

#ifndef mp_prec_t
#define mp_prec_t mpfr_prec_t
#endif

SV * prec_cast(pTHX_ SV * iv) {
     mp_prec_t * p;
     SV * obj_ref, * obj;

     if(!SvIOK(iv)) croak("Arg supplied to Math::MPFR::Prec::prec_cast must be an IV/UV");

     Newx(p, 1, mp_prec_t);
     if(p == NULL) croak("Failed to allocate memory in Math::MPFR::Prec::prec_cast function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::MPFR::Prec");

     *p = (mp_prec_t)SvUVX(iv);

     sv_setiv(obj, INT2PTR(IV,p));
     SvREADONLY_on(obj);
     return obj_ref;
}

void DESTROY(pTHX_ SV *  rop) {
     Safefree(INT2PTR(mp_prec_t *, SvIVX(SvRV(rop))));
}


MODULE = Math::MPFR::Prec  PACKAGE = Math::MPFR::Prec

PROTOTYPES: DISABLE


SV *
prec_cast (iv)
	SV *	iv
CODE:
  RETVAL = prec_cast (aTHX_ iv);
OUTPUT:  RETVAL

void
DESTROY (rop)
	SV *	rop
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        DESTROY(aTHX_ rop);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

