#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Lexical::Import PACKAGE = Lexical::Import

PROTOTYPES: DISABLE

bool
_glob_has_scalar(SV *gvref)
PROTOTYPE: $
PREINIT:
	GV *gv;
CODE:
	/*
	 * This function works around the fact that *foo{SCALAR}
	 * autovivifies the scalar slot (perl bug #73666).
	 */
	if(!(SvROK(gvref) && (gv = (GV*)SvRV(gvref)) &&
			SvTYPE((SV*)gv) == SVt_PVGV))
		croak("_glob_has_scalar needs a glob ref");
	RETVAL = isGV_with_GP(gv) && GvSV(gv);
OUTPUT:
	RETVAL
