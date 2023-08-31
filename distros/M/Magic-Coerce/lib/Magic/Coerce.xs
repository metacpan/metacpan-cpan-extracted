#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static int int_set(pTHX_ SV* sv, MAGIC* magic) {
	if (!SvIOK(sv))
		sv_setiv(sv, SvIV_nomg(sv));
	return 0;
}
static const MGVTBL int_table = { NULL, int_set };

static int float_set(pTHX_ SV* sv, MAGIC* magic) {
	if (!SvNOK(sv))
		sv_setnv(sv, SvNV_nomg(sv));
	return 0;
}
static const MGVTBL float_table = { NULL, float_set };

static int string_set(pTHX_ SV* sv, MAGIC* magic) {
	if (!SvPOK(sv))
		SvPV_force_nomg_nolen(sv);
	return 0;
}
static const MGVTBL string_table = { NULL, string_set };

static int callback_set(pTHX_ SV* sv, MAGIC* magic) {
	dSP;
	ENTER;
	PUSHSTACKi(PERLSI_MAGIC);
	SAVETMPS;
	PUSHMARK(SP);
	XPUSHs(sv);
	PUTBACK;
	call_sv(magic->mg_obj, G_SCALAR);
	SPAGAIN;
	SV* result = POPs;
	if (!(result == sv || (SvROK(result) && SvROK(sv) && SvRV(result) == SvRV(sv))))
		SvSetSV(sv, result);
	FREETMPS;
	POPSTACK;
	LEAVE;
	return 0;
}
static const MGVTBL callback_table = { NULL, callback_set };

MODULE = Magic::Coerce				PACKAGE = Magic::Coerce

PROTOTYPES: DISABLED

void coerce_int(SV* sv)
CODE:
	sv_magicext(sv, NULL, PERL_MAGIC_ext, &int_table, NULL, 0);
	if (!SvOK(sv))
		sv_setiv(sv, 0);
	else
		SvSETMAGIC(sv);

void coerce_float(SV* sv)
CODE:
	sv_magicext(sv, NULL, PERL_MAGIC_ext, &float_table, NULL, 0);
	if (!SvOK(sv))
		sv_setnv(sv, 0.0);
	else
		SvSETMAGIC(sv);

void coerce_string(SV* sv)
CODE:
	sv_magicext(sv, NULL, PERL_MAGIC_ext, &string_table, NULL, 0);
	if (!SvOK(sv))
		sv_setpvn(sv, "", 0);
	else
		SvSETMAGIC(sv);

void coerce_callback(SV* sv, CV* callback, bool delayed = FALSE)
CODE:
	sv_magicext(sv, (SV*)callback, PERL_MAGIC_ext, &callback_table, NULL, 0);
	if (!delayed)
		SvSETMAGIC(sv);
