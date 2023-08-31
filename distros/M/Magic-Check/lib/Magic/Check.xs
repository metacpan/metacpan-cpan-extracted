#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

static int magic_set(pTHX_ SV* sv, MAGIC* magic)
{
	dSP;
	PUSHSTACKi(PERLSI_MAGIC);

	PUSHMARK(SP);
	EXTEND(SP, 2);
	PUSHs((SV*)magic->mg_ptr);
	PUSHs(sv);
	PUTBACK;
	call_method("validate", G_SCALAR);
	SPAGAIN;
	SV* result = POPs;

	POPSTACK;

	if (SvOK(result)) {
		sv_setsv(sv, magic->mg_obj);
		croak_sv(result);
	} else
		sv_setsv(magic->mg_obj, sv);
}

static const MGVTBL magic_table = { NULL, magic_set };

MODULE = Magic::Check				PACKAGE = Magic::Check

PROTOTYPES: DISABLED

void check_variable(SV* variable, SV* checker)
	CODE:
	SV* copy = sv_mortalcopy(variable);
	sv_magicext(variable, copy, PERL_MAGIC_ext, &magic_table, (char*)checker, HEf_SVKEY);
