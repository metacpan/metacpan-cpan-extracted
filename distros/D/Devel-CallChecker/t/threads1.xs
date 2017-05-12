#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "threads1_callchecker0.h"
#include "XSUB.h"

MODULE = t::threads1 PACKAGE = t::threads1

PROTOTYPES: DISABLE

void
cv_set_call_checker_proto(CV *cv, SV *proto)
PROTOTYPE: $$
CODE:
	if (SvROK(proto))
		proto = SvRV(proto);
	cv_set_call_checker(cv, Perl_ck_entersub_args_proto, proto);
