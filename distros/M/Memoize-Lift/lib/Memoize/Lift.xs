#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "callparser1.h"
#include "XSUB.h"

static OP *myck_entersub_lift(pTHX_ OP *entersubop, GV *namegv, SV *protosv)
{
	OP *pushop, *constop;
	entersubop = ck_entersub_args_proto(entersubop, namegv, protosv);
	pushop = cUNOPx(entersubop)->op_first;
	if(!pushop->op_sibling) pushop = cUNOPx(pushop)->op_first;
	constop = pushop->op_sibling;
	if(!constop || !constop->op_sibling ||
			constop->op_sibling->op_sibling ||
			constop->op_type != OP_CONST)
		return entersubop;
	pushop->op_sibling = constop->op_sibling;
	constop->op_sibling = NULL;
	op_free(entersubop);
	return constop;
}

#define gvcroak(namegv, fmt) THX_gvcroak(aTHX_ namegv, fmt)
static OP *THX_gvcroak(pTHX_ GV *namegv, char const *fmt)
{
	SV *namesv = sv_newmortal();
	gv_efullname3(namesv, namegv, NULL);
	croak(fmt, SvPV_nolen(namesv));
}

static OP *myparse_args_lift(pTHX_ GV *namegv, SV *psobj, U32 *flagsp)
{
	I32 sub_floor;
	OP *arglistop, *bodyop;
	CV *cv;
	SV *value;
	int old_error_count;
	PERL_UNUSED_ARG(namegv);
	PERL_UNUSED_ARG(psobj);
	sub_floor = start_subparse(0, CVf_ANON);
	sv_2mortal((SV*)PL_compcv);
	CvSPECIAL_on(PL_compcv);
	old_error_count = PL_parser->error_count;
	arglistop = parse_args_unary(flagsp);
	if(PL_parser->error_count != old_error_count) {
		op_free(arglistop);
		arglistop = newOP(OP_NULL, 0);
	}
	if(!arglistop) gvcroak(namegv, "Not enough arguments for %s");
	if(arglistop->op_type == OP_LIST &&
			!(arglistop->op_flags & OPf_PARENS)) {
		OP *pushop = cLISTOPx(arglistop)->op_first;
		bodyop = pushop->op_sibling;
		if(!bodyop) {
			op_free(arglistop);
			gvcroak(namegv, "Not enough arguments for %s");
		}
		if(bodyop->op_sibling) {
			op_free(arglistop);
			gvcroak(namegv, "Too many arguments for %s");
		}
		pushop->op_sibling = NULL;
		cLISTOPx(arglistop)->op_last = pushop;
		op_free(arglistop);
	} else {
		bodyop = arglistop;
	}
	bodyop = newSTATEOP(0, NULL, bodyop);
	cv = newATTRSUB(sub_floor, NULL, NULL, NULL, bodyop);
	if(CvCLONE(cv))
		gvcroak(namegv,
			"reference to external lexical from %s subexpression");
	if(!CvROOT(cv) && PL_parser->error_count) return newOP(OP_NULL, 0);
	ENTER;
	{
		dSP;
		PUSHMARK(SP);
		call_sv((SV*)cv, G_SCALAR|G_NOARGS);
		SPAGAIN;
		value = POPs;
		PUTBACK;
	}
	LEAVE;
	return newSVOP(OP_CONST, 0, newSVsv(value));
}

MODULE = Memoize::Lift PACKAGE = Memoize::Lift

PROTOTYPES: DISABLE

BOOT:
{
	CV *lift_cv = get_cv("Memoize::Lift::lift", 0);
	cv_set_call_parser(lift_cv, myparse_args_lift, (SV*)lift_cv);
	cv_set_call_checker(lift_cv, myck_entersub_lift, (SV*)lift_cv);
}

void
lift(...)
PROTOTYPE: $
CODE:
	PERL_UNUSED_VAR(items);
	croak("lift called as a function");
