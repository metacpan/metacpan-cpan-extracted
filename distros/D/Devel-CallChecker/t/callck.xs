#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "callck_callchecker0.h"
#include "XSUB.h"

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
	PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
	(PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#ifndef PERL_UNUSED_VAR
# define PERL_UNUSED_VAR(x) ((void)x)
#endif /* !PERL_UNUSED_VAR */

#ifndef PERL_UNUSED_ARG
# define PERL_UNUSED_ARG(x) PERL_UNUSED_VAR(x)
#endif /* !PERL_UNUSED_ARG */

#ifndef FPTR2DPTR
# define FPTR2DPTR(t,x) ((t)(UV)(x))
#endif /* !FPTR2DPTR */

#ifndef OpSIBLING
# ifdef PERL_OP_PARENT
#  define OpHAS_SIBLING(o) (!(o)->op_lastsib)
#  define OpSIBLING(o) ((o)->op_lastsib ? (OP*)NULL : 0 + (o)->op_sibling)
#  define OpSIBLING_set(o, sib) ((o)->op_sibling = (sib))
# else /* !PERL_OP_PARENT */
#  define OpHAS_SIBLING(o) (!!(o)->op_sibling)
#  define OpSIBLING(o) (0 + (o)->op_sibling)
#  define OpSIBLING_set(o, sib) ((o)->op_sibling = (sib))
# endif /* !PERL_OP_PARENT */
#endif /* !OpSIBLING */

#ifndef OpMORESIB_set
# if PERL_VERSION_GE(5,21,2)
#  define OpMORESIB_set(o, sib) ((o)->op_lastsib = 0, (o)->op_sibling = (sib))
# else /* <5.21.2 */
#  define OpMORESIB_set(o, sib) ((o)->op_sibling = (sib))
# endif /* <5.21.2 */
#endif /* !OpMORESIB_set */

#ifndef OpLASTSIB_set
# ifdef PERL_OP_PARENT
#  define OpLASTSIB_set(o, parent) \
	((o)->op_lastsib = 1, (o)->op_sibling = (parent))
# elif PERL_VERSION_GE(5,21,2)
#  define OpLASTSIB_set(o, parent) ((o)->op_lastsib = 1, (o)->op_sibling = NULL)
# else /* <5.21.2 */
#  define OpLASTSIB_set(o, parent) ((o)->op_sibling = NULL)
# endif /* <5.21.2 */
#endif /* !OpLASTSIB_set */

#ifndef OpMAYBESIB_set
# ifdef PERL_OP_PARENT
#  define OpMAYBESIB_set(o, sib, parent) \
	((o)->op_sibling = ((o)->op_lastsib = !(sib)) ? (parent) : (sib))
# elif PERL_VERSION_GE(5,21,2)
#  define OpMAYBESIB_set(o, sib, parent) \
	((o)->op_lastsib = !(sib), (o)->op_sibling = (sib))
# else /* <5.21.2 */
#  define OpMAYBESIB_set(o, sib, parent) ((o)->op_sibling = (sib))
# endif /* <5.21.2 */
#endif /* !OpMAYBESIB_set */

#ifndef op_contextualize
# define op_contextualize(o, c) THX_op_contextualize(aTHX_ o, c)
static OP *THX_op_contextualize(pTHX_ OP *o, I32 c)
{
	if(c == G_SCALAR) {
		OP *sib, *assop, *nullop;
		sib = o->op_sibling;
		o->op_sibling = NULL;
		assop = newASSIGNOP(0, newOP(OP_NULL, 0), 0, o);
		o = cBINOPx(assop)->op_first;
		nullop = newOP(OP_NULL, 0);
		nullop->op_sibling = o->op_sibling;
		cBINOPx(assop)->op_first = nullop;
		if(!nullop->op_sibling) cBINOPx(assop)->op_last = nullop;
		op_free(assop);
		o->op_sibling = sib;
		return o;
	} else {
		croak("reserve op_contextualize abused");
	}
}
#endif /* !op_contextualize */

static OP *THX_ck_entersub_args_lists(pTHX_ OP *entersubop,
	GV *namegv, SV *ckobj)
{
	PERL_UNUSED_ARG(namegv);
	PERL_UNUSED_ARG(ckobj);
	return ck_entersub_args_list(entersubop);
}

static OP *THX_ck_entersub_args_scalars(pTHX_ OP *entersubop,
	GV *namegv, SV *ckobj)
{
	OP *aop = cUNOPx(entersubop)->op_first;
	PERL_UNUSED_ARG(namegv);
	PERL_UNUSED_ARG(ckobj);
	if (!OpHAS_SIBLING(aop))
		aop = cUNOPx(aop)->op_first;
	for (aop = OpSIBLING(aop); OpHAS_SIBLING(aop); aop = OpSIBLING(aop)) {
		op_contextualize(aop, G_SCALAR);
	}
	return entersubop;
}

static OP *THX_ck_entersub_multi_sum(pTHX_ OP *entersubop,
	GV *namegv, SV *ckobj)
{
	OP *sumop = NULL;
	OP *pushop = cUNOPx(entersubop)->op_first;
	PERL_UNUSED_ARG(namegv);
	PERL_UNUSED_ARG(ckobj);
	if (!OpHAS_SIBLING(pushop))
		pushop = cUNOPx(pushop)->op_first;
	while (1) {
		OP *aop = OpSIBLING(pushop);
		OP *as;
		if (!OpHAS_SIBLING(aop)) break;
		as = OpSIBLING(aop);
		OpMORESIB_set(pushop, as);
		OpLASTSIB_set(aop, NULL);
		op_contextualize(aop, G_SCALAR);
		if (sumop) {
			sumop = newBINOP(OP_ADD, 0, sumop, aop);
		} else {
			sumop = aop;
		}
	}
	if (!sumop)
		sumop = newSVOP(OP_CONST, 0, newSViv(0));
	op_free(entersubop);
	return sumop;
}

MODULE = t::callck PACKAGE = t::callck

PROTOTYPES: DISABLE

void
test_cv_getset_call_checker()
PROTOTYPE:
PREINIT:
	CV *t0_cv, *t1_cv;
	Perl_call_checker ckfun;
	SV *ckobj;
CODE:
#define croak_fail() croak("fail at " __FILE__ " line %d", __LINE__)
#define croak_fail_ne(h, w) \
	croak("fail %p!=%p at " __FILE__ " line %d", (h), (w), __LINE__)
#define check_cc(cv, xckfun, xckobj) \
	do { \
		cv_get_call_checker((cv), &ckfun, &ckobj); \
		if (ckfun != (xckfun)) \
			croak_fail_ne(FPTR2DPTR(void *, ckfun), xckfun); \
		if (ckobj != (xckobj)) \
			croak_fail_ne(FPTR2DPTR(void *, ckobj), xckobj); \
	} while(0)
	t0_cv = get_cv("t::callck::t0", 0);
	t1_cv = get_cv("t::callck::t1", 0);
	check_cc(t0_cv, Perl_ck_entersub_args_proto_or_list, (SV*)t0_cv);
	check_cc(t1_cv, Perl_ck_entersub_args_proto_or_list, (SV*)t1_cv);
	cv_set_call_checker(t1_cv, Perl_ck_entersub_args_proto_or_list,
				&PL_sv_yes);
	check_cc(t0_cv, Perl_ck_entersub_args_proto_or_list, (SV*)t0_cv);
	check_cc(t1_cv, Perl_ck_entersub_args_proto_or_list, &PL_sv_yes);
	cv_set_call_checker(t0_cv, THX_ck_entersub_args_scalars, &PL_sv_no);
	check_cc(t0_cv, THX_ck_entersub_args_scalars, &PL_sv_no);
	check_cc(t1_cv, Perl_ck_entersub_args_proto_or_list, &PL_sv_yes);
	cv_set_call_checker(t1_cv, Perl_ck_entersub_args_proto_or_list,
				(SV*)t1_cv);
	check_cc(t0_cv, THX_ck_entersub_args_scalars, &PL_sv_no);
	check_cc(t1_cv, Perl_ck_entersub_args_proto_or_list, (SV*)t1_cv);
	cv_set_call_checker(t0_cv, Perl_ck_entersub_args_proto_or_list,
				(SV*)t0_cv);
	check_cc(t0_cv, Perl_ck_entersub_args_proto_or_list, (SV*)t0_cv);
	check_cc(t1_cv, Perl_ck_entersub_args_proto_or_list, (SV*)t1_cv);
	if (SvMAGICAL((SV*)t0_cv) || SvMAGIC((SV*)t0_cv)) croak_fail();
	if (SvMAGICAL((SV*)t1_cv) || SvMAGIC((SV*)t1_cv)) croak_fail();
#undef check_cc
#undef croak_fail_ne
#undef croak_fail

void
t0()
PROTOTYPE:
CODE:
	;

void
t1()
PROTOTYPE:
CODE:
	;

void
cv_set_call_checker_lists(CV *cv)
PROTOTYPE: $
CODE:
	cv_set_call_checker(cv, THX_ck_entersub_args_lists, &PL_sv_undef);

void
cv_set_call_checker_scalars(CV *cv)
PROTOTYPE: $
CODE:
	cv_set_call_checker(cv, THX_ck_entersub_args_scalars, &PL_sv_undef);

void
cv_set_call_checker_proto(CV *cv, SV *proto)
PROTOTYPE: $$
CODE:
	if (SvROK(proto))
		proto = SvRV(proto);
	cv_set_call_checker(cv, Perl_ck_entersub_args_proto, proto);

void
cv_set_call_checker_proto_or_list(CV *cv, SV *proto)
PROTOTYPE: $$
CODE:
	if (SvROK(proto))
		proto = SvRV(proto);
	cv_set_call_checker(cv, Perl_ck_entersub_args_proto_or_list, proto);

void
cv_set_call_checker_multi_sum(CV *cv)
PROTOTYPE: $
CODE:
	cv_set_call_checker(cv, THX_ck_entersub_multi_sum, &PL_sv_undef);
