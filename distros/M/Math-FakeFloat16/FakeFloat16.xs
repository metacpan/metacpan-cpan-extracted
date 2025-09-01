#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

SV * _itsa(SV * a) {
  if(SvIOK(a)) {
    return newSVuv(2);               /* IV */
  }
  if(SvPOK(a)) {
    return newSVuv(4);               /* PV */
  }
  if(SvNOK(a)) return newSVuv(3);    /* NV */
  if(sv_isobject(a)) {
    const char* h = HvNAME(SvSTASH(SvRV(a)));

    if(strEQ(h, "Math::MPFR")) return newSVuv(5);
    if(strEQ(h, "Math::GMPf")) return newSVuv(6);
    if(strEQ(h, "Math::GMPq")) return newSVuv(7);
    if(strEQ(h, "Math::FakeFloat16")) return newSVuv(31);
    croak("The Math::FakeFloat16::_itsa XSub does not accept %s objects.", h);
  }
  croak("The Math::FakeFloat16::_itsa XSub has been given an invalid argument (probably undefined)");
}

void _unpack_float(SV * in) {
  dXSARGS;
  int i;
  char * buff;
  float f = (float)SvNVX(in); /* f == SvNVX(in) */
  void * p = &f;

  Newx(buff, 4, char);
  if(buff == NULL) croak("Failed to allocate memory (in _unpack_float) inside unpack_f16_hex");

  sp = mark;

#ifdef WE_HAVE_BENDIAN /* Big Endian architecture */
  for (i = 0; i < 2; i++) {
#else
  for (i = 3; i >= 2; i--) {
#endif
    sprintf(buff, "%02X", ((unsigned char*)p)[i]);
    XPUSHs(sv_2mortal(newSVpv(buff, 0)));
  }
  PUTBACK;
  Safefree(buff);
  XSRETURN(2);
}
MODULE = Math::FakeFloat16  PACKAGE = Math::FakeFloat16

PROTOTYPES: DISABLE


SV *
_itsa (a)
	SV *	a

void
_unpack_float (in)
	SV *	in
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _unpack_float(in);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return;

