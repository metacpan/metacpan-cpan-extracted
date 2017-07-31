#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "callchecker0.h"
#include "XSUB.h"

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
	PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
	(PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#if !PERL_VERSION_GE(5,7,2)
# undef dNOOP
# define dNOOP extern int Perl___notused_func(void)
#endif /* <5.7.2 */

#ifndef cBOOL
# define cBOOL(x) ((bool)!!(x))
#endif /* !cBOOL */

#ifndef OpMORESIB_set
# define OpMORESIB_set(o, sib) ((o)->op_sibling = (sib))
# define OpLASTSIB_set(o, parent) ((o)->op_sibling = NULL)
# define OpMAYBESIB_set(o, sib, parent) ((o)->op_sibling = (sib))
#endif /* !OpMORESIB_set */
#ifndef OpSIBLING
# define OpHAS_SIBLING(o) (cBOOL((o)->op_sibling))
# define OpSIBLING(o) (0 + (o)->op_sibling)
#endif /* !OpSIBLING */

static OP *THX_pp_readonly_or_assign(pTHX)
{
	dSP;
	return SvREADONLY(TOPs) ? PL_op->op_next : cLOGOP->op_other;
}

static OP *THX_pp_sassign_memo(pTHX)
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

static OP *THX_ck_entersub_once(pTHX_ OP *entersubop, GV *namegv, SV *protosv)
{
	OP *pushop, *thunkop, *cvop, *storeop, *assignop, *memoop, *oraop;
	entersubop = ck_entersub_args_proto(entersubop, namegv, protosv);
	pushop = cUNOPx(entersubop)->op_first;
	if(!OpHAS_SIBLING(pushop)) pushop = cUNOPx(pushop)->op_first;
	thunkop = OpSIBLING(pushop);
	if(!thunkop || !(cvop = OpSIBLING(thunkop)) || OpHAS_SIBLING(cvop))
		return entersubop;
	OpMORESIB_set(pushop, cvop);
	OpLASTSIB_set(thunkop, NULL);
	op_free(entersubop);
	storeop = newSVREF(newSVOP(OP_CONST, 0, newRV_noinc(newSV(0))));
#if PERL_VERSION_GE(5,25,6)
	assignop = newBINOP(OP_SASSIGN, 0, thunkop, thunkop);
#else /* <5.25.6 */
	assignop = newUNOP(OP_SASSIGN, 0, thunkop);
#endif /* <5.25.6 */
	assignop->op_ppaddr = THX_pp_sassign_memo;
	memoop = newLOGOP(OP_ORASSIGN, 0, storeop, assignop);
	oraop = memoop->op_type == OP_ORASSIGN ? memoop :
		cUNOPx(memoop)->op_first;
	oraop->op_ppaddr = THX_pp_readonly_or_assign;
	return memoop;
}

MODULE = Memoize::Once PACKAGE = Memoize::Once

PROTOTYPES: DISABLE

BOOT:
{
	CV *once_cv = get_cv("Memoize::Once::once", 0);
	cv_set_call_checker(once_cv, THX_ck_entersub_once, (SV*)once_cv);
}

void
once(...)
PROTOTYPE: $
CODE:
	PERL_UNUSED_VAR(items);
	croak("once called as a function");
