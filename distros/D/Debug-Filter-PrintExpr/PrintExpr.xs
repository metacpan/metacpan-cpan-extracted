#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef USE_PPPORT_H
#  define NEED_sv_2pv_flags 1
#  define NEED_newSVpvn_flags 1
#  define NEED_sv_catpvn_flags
#  include "ppport.h"
#endif

MODULE = Debug::Filter::PrintExpr		PACKAGE = Debug::Filter::PrintExpr

PROTOTYPES: ENABLE

void
isstring(sv)
	SV *sv
PROTOTYPE: $
CODE:
	if(SvMAGICAL(sv))
		mg_get(sv);

	ST(0) = boolSV(SvPOK(sv) || SvPOKp(sv));
	XSRETURN(1);

void
isnumeric(sv)
	SV *sv
PROTOTYPE: $
CODE:
	if(SvMAGICAL(sv))
		mg_get(sv);

	ST(0) = boolSV(SvNIOK(sv) || SvNIOKp(sv));
	XSRETURN(1);

