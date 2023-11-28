
#ifdef  __MINGW32__
#ifndef __USE_MINGW_ANSI_STDIO
#define __USE_MINGW_ANSI_STDIO 1
#endif
#endif

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "../math_ryu_include.h"
#include "../ryu_headers/ryu.h"
#include "../ryu_headers/ryu_parse.h"
#include "../ryu_headers/common.h"

/* s2d */

NV M_RYU_D_s2d(char * buffer) {
  NV nv;
  s2d(buffer, &nv);
  return nv;
}

/* End s2d */
/* d2s */

void M_RYU_D_d2s_buffered_n(pTHX_ SV * nv) {
  dXSARGS;
  int n;
  char * result;

  Newxz(result, D_BUF, char);

  n = d2s_buffered_n(SvNV(nv), result);
  ST(0) = MORTALIZED_PV(result);        /* defined in ../math_ryu_include.h */
  ST(1) = sv_2mortal(newSViv(n));

  Safefree(result);
  XSRETURN(2);
}

SV * M_RYU_D_d2s_buffered(pTHX_ SV * nv) {
  char * result;
  SV * outsv;

  Newxz(result, D_BUF, char);

  d2s_buffered(SvNV(nv), result);

  outsv = newSVpv(result, 0);
  Safefree(result);
  return outsv;
  }

SV * M_RYU_D_d2s(pTHX_ SV * nv) {
  return newSVpv(d2s(SvNV(nv)), 0);
}

/* End d2s */
/* d2fixed */

void M_RYU_D_d2fixed_buffered_n(pTHX_ SV * nv, SV * prec) {
  dXSARGS;
  int n;
  char * result;

  Newxz(result, D_BUF + SvUV(prec), char);

  n = d2fixed_buffered_n(SvNV(nv), SvUV(prec), result);

  ST(0) = MORTALIZED_PV(result);        /* defined in ../math_ryu_include.h */
  ST(1) = sv_2mortal(newSViv(n));
  Safefree(result);
  XSRETURN(2);
}

SV * M_RYU_D_d2fixed_buffered(pTHX_ SV * nv, SV * prec) {
  char * result;
  SV * outsv;

  Newxz(result, D_BUF + SvUV(prec), char);

  d2fixed_buffered(SvNV(nv), SvUV(prec), result);

  outsv = newSVpv(result, 0);
  Safefree(result);
  return outsv;
}

SV * M_RYU_D_d2fixed(pTHX_ SV * nv, SV * prec) {
  return newSVpv(d2fixed(SvNV(nv), SvUV(prec)), 0);
}

/*End d2fixed */
/* d2exp */

void M_RYU_D_d2exp_buffered_n(pTHX_ SV * nv, SV * exponent) {
  dXSARGS;
  int n;
  char * result;

  Newxz(result, D_BUF + SvUV(exponent), char);

  n = d2exp_buffered_n(SvNV(nv), SvUV(exponent), result);

  ST(0) = MORTALIZED_PV(result);        /* defined in ../math_ryu_include.h */
  ST(1) = sv_2mortal(newSViv(n));
  Safefree(result);
  XSRETURN(2);
}

SV * M_RYU_D_d2exp_buffered(pTHX_ SV * nv, SV * exponent) {
  char * result;
  SV * outsv;

  Newxz(result, D_BUF + SvUV(exponent), char);

  d2exp_buffered(SvNV(nv), SvUV(exponent), result);

  outsv = newSVpv(result, 0);
  Safefree(result);
  return outsv;
}

SV * M_RYU_D_d2exp(pTHX_ SV * nv, SV * exponent) {
  return newSVpv(d2exp(SvNV(nv), SvUV(exponent)), 0);
}

int _sis_perl_version(void) {
    return SIS_PERL_VERSION;
}

int M_RYU_D__has_uint128(void) {
    return _has_uint128();
}

/* End d2exp */


MODULE = Math::Ryu::Debug  PACKAGE = Math::Ryu::Debug  PREFIX = M_RYU_D_

PROTOTYPES: DISABLE


NV
M_RYU_D_s2d (buffer)
	char *	buffer

void
M_RYU_D_d2s_buffered_n (nv)
	SV *	nv
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        M_RYU_D_d2s_buffered_n(aTHX_ nv);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
M_RYU_D_d2s_buffered (nv)
	SV *	nv
CODE:
  RETVAL = M_RYU_D_d2s_buffered (aTHX_ nv);
OUTPUT:  RETVAL

SV *
M_RYU_D_d2s (nv)
	SV *	nv
CODE:
  RETVAL = M_RYU_D_d2s (aTHX_ nv);
OUTPUT:  RETVAL

void
M_RYU_D_d2fixed_buffered_n (nv, prec)
	SV *	nv
	SV *	prec
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        M_RYU_D_d2fixed_buffered_n(aTHX_ nv, prec);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
M_RYU_D_d2fixed_buffered (nv, prec)
	SV *	nv
	SV *	prec
CODE:
  RETVAL = M_RYU_D_d2fixed_buffered (aTHX_ nv, prec);
OUTPUT:  RETVAL

SV *
M_RYU_D_d2fixed (nv, prec)
	SV *	nv
	SV *	prec
CODE:
  RETVAL = M_RYU_D_d2fixed (aTHX_ nv, prec);
OUTPUT:  RETVAL

void
M_RYU_D_d2exp_buffered_n (nv, exponent)
	SV *	nv
	SV *	exponent
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        M_RYU_D_d2exp_buffered_n(aTHX_ nv, exponent);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
M_RYU_D_d2exp_buffered (nv, exponent)
	SV *	nv
	SV *	exponent
CODE:
  RETVAL = M_RYU_D_d2exp_buffered (aTHX_ nv, exponent);
OUTPUT:  RETVAL

SV *
M_RYU_D_d2exp (nv, exponent)
	SV *	nv
	SV *	exponent
CODE:
  RETVAL = M_RYU_D_d2exp (aTHX_ nv, exponent);
OUTPUT:  RETVAL

int
_sis_perl_version ()


int
M_RYU_D__has_uint128 ()


