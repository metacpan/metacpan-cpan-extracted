#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

int is_ok(SV * in) {

  if( sv_isobject(in) ) {
    const char* h = HvNAME( SvSTASH(SvRV(in)) );
    if(strEQ(h, "Math::NumOnly")) return 1;
  }

  if( !(SvPOK(in)) && (SvIOK(in) || SvNOK(in)) ) return 2;

  return 0;
}


MODULE = Math::NumOnly PACKAGE = Math::NumOnly

PROTOTYPES: DISABLE

int
is_ok (in)
	SV *	in

