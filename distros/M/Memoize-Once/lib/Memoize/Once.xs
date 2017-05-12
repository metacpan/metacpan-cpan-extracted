#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "callchecker0.h"
#include "XSUB.h"

static OP *mypp_readonly_or_assign(pTHX)
{
	dSP;
	return SvREADONLY(TOPs) ? PL_op->op_next : cLOGOP->op_other;
}

static OP *mypp_sassign_memo(pTHX)
{
	dSP;
	SV *val, *var;
	val = POPs;
	var = TOPs;
	PUTBACK;
	if(!SvREADONLY(var)) {
		sv_setsv(var, val);
		SvREADONLY_on(var);
	}
	return PL_op->op_next;
}

static OP *myck_entersub_once(pTHX_ OP *entersubop, GV *namegv, SV *protosv)
{
	OP *pushop, *thunkop, *storeop, *assignop, *memoop, *oraop;
	entersubop = ck_entersub_args_proto(entersubop, namegv, protosv);
	pushop = cUNOPx(entersubop)->op_first;
	if(!pushop->op_sibling) pushop = cUNOPx(pushop)->op_first;
	thunkop = pushop->op_sibling;
	if(!thunkop || !thunkop->op_sibling || thunkop->op_sibling->op_sibling)
		return entersubop;
	pushop->op_sibling = thunkop->op_sibling;
	thunkop->op_sibling = NULL;
	op_free(entersubop);
	storeop = newSVREF(newSVOP(OP_CONST, 0, newRV_noinc(newSV(0))));
	assignop = newUNOP(OP_SASSIGN, 0, thunkop);
	assignop->op_ppaddr = mypp_sassign_memo;
	memoop = newLOGOP(OP_ORASSIGN, 0, storeop, assignop);
	oraop = memoop->op_type == OP_ORASSIGN ? memoop :
		cUNOPx(memoop)->op_first;
	oraop->op_ppaddr = mypp_readonly_or_assign;
	return memoop;
}

MODULE = Memoize::Once PACKAGE = Memoize::Once

PROTOTYPES: DISABLE

BOOT:
{
	CV *once_cv = get_cv("Memoize::Once::once", 0);
	cv_set_call_checker(once_cv, myck_entersub_once, (SV*)once_cv);
}

void
once(...)
PROTOTYPE: $
CODE:
	PERL_UNUSED_VAR(items);
	croak("once called as a function");
