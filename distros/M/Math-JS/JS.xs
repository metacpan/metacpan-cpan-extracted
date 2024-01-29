 #include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

int _is_ok(SV * in) {

  if(!SvOK(in)) return 0;

  if( sv_isobject(in) ) {
    const char* h = HvNAME( SvSTASH(SvRV(in)) );
    if(strEQ(h, "Math::JS")) return 1;
  }

  if(SvIOK(in) || SvNOK(in)) return 2;
  return 0;
}

double _fmod(double n, double d) {
  return fmod(n, d);
}


MODULE = Math::JS PACKAGE = Math::JS

PROTOTYPES: DISABLE

int
_is_ok (in)
	SV *	in

double
_fmod (n, d)
	double	n
	double	d
