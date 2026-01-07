
#ifdef  __MINGW32__
#ifndef __USE_MINGW_ANSI_STDIO
#define __USE_MINGW_ANSI_STDIO 1
#endif
#endif

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


void dd_frexp(pTHX_ SV * nv) {
  dXSARGS;
  double frac;
  int exp;
  PERL_UNUSED_ARG(items);

  frac = frexp((double)SvNVX(nv), &exp);
  ST(0) = sv_2mortal(newSVnv(frac));
  ST(1) = sv_2mortal(newSViv(exp));
  XSRETURN(2);
}


MODULE = Math::FakeDD  PACKAGE = Math::FakeDD

PROTOTYPES: DISABLE


void
dd_frexp (nv)
	SV *	nv
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        dd_frexp(aTHX_ nv);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return;

