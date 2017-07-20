#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
	PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
	(PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#ifndef cBOOL
# define cBOOL(x) ((bool)!!(x))
#endif /* !cBOOL */

#ifndef croak
# define croak Perl_croak_nocontext
#endif /* !croak */

#define Q_MUST_WORKAROUND (!PERL_VERSION_GE(5,12,0))
#define Q_HAVE_COP_HINTS_HASH PERL_VERSION_GE(5,9,4)

#if Q_MUST_WORKAROUND

# if !PERL_VERSION_GE(5,9,3)
typedef OP *(*Perl_check_t)(pTHX_ OP *);
# endif /* <5.9.3 */

# if !PERL_VERSION_GE(5,10,1)
typedef unsigned Optype;
# endif /* <5.10.1 */

# ifndef OpMORESIB_set
#  define OpMORESIB_set(o, sib) ((o)->op_sibling = (sib))
#  define OpLASTSIB_set(o, parent) ((o)->op_sibling = NULL)
#  define OpMAYBESIB_set(o, sib, parent) ((o)->op_sibling = (sib))
# endif /* !OpMORESIB_set */
# ifndef OpSIBLING
#  define OpHAS_SIBLING(o) (cBOOL((o)->op_sibling))
#  define OpSIBLING(o) (0 + (o)->op_sibling)
# endif /* !OpSIBLING */

# ifndef wrap_op_checker
#  define wrap_op_checker(c,n,o) THX_wrap_op_checker(aTHX_ c,n,o)
static void THX_wrap_op_checker(pTHX_ Optype opcode,
Perl_check_t new_checker, Perl_check_t *old_checker_p)
{
	if(*old_checker_p) return;
	OP_REFCNT_LOCK;
	if(!*old_checker_p) {
		*old_checker_p = PL_check[opcode];
		PL_check[opcode] = new_checker;
	}
	OP_REFCNT_UNLOCK;
}
# endif /* !wrap_op_checker */

# ifndef SvVOK
#  define SvVOK(sv) 0
# endif /* !SvVOK */

# define refcounted_he_free(he) Perl_refcounted_he_free(aTHX_ he)

# define newDEFSVOP() THX_newDEFSVOP(aTHX)
static OP *THX_newDEFSVOP(pTHX)
{
# if PERL_VERSION_GE(5,9,1)
	/* hope nothing overrides the meaning of defined() */
	OP *dop = newOP(OP_DEFINED, 0);
	if(dop->op_type == OP_DEFINED && (dop->op_flags & OPf_KIDS)) {
		OP *op = cUNOPx(dop)->op_first;
		if(OpHAS_SIBLING(op)) {
			cUNOPx(dop)->op_first = OpSIBLING(op);
		} else {
			cUNOPx(dop)->op_first = NULL;
			dop->op_flags &= ~OPf_KIDS;
		}
		OpLASTSIB_set(op, NULL);
		op_free(dop);
		return op;
	}
	op_free(dop);
# endif /* >=5.9.1 */
	return newSVREF(newGVOP(OP_GV, 0, PL_defgv));
}

# define op_scalar(op) THX_op_scalar(aTHX_ op)
static OP *THX_op_scalar(pTHX_ OP *op)
{
	OP *sop = newUNOP(OP_SCALAR, 0, op);
	if(!(sop->op_type == OP_SCALAR && (sop->op_flags & OPf_KIDS)))
		return sop;
	op = cUNOPx(sop)->op_first;
	if(OpHAS_SIBLING(op)) {
		cUNOPx(sop)->op_first = OpSIBLING(op);
	} else {
		cUNOPx(sop)->op_first = NULL;
		sop->op_flags &= ~OPf_KIDS;
	}
	OpLASTSIB_set(op, NULL);
	op_free(sop);
	return op;
}

# define pp_squashhints() THX_pp_squashhints(aTHX)
static OP *THX_pp_squashhints(pTHX)
{
	/*
	 * SAVEHINTS() won't actually localise %^H unless the
	 * HINT_LOCALIZE_HH bit is set.  Normally that bit would be set if
	 * there were anything in %^H, but when affected by [perl #73174]
	 * the core's swash-loading code clears $^H without changing
	 * %^H, so we set the bit here.  We localise $^H while doing this,
	 * in order to not clobber $^H across a normal require where the
	 * bit is legitimately clear, except on Perl 5.11, where the bit
	 * needs to stay set in order to get proper restoration of %^H.
	 */
# if !PERL_VERSION_GE(5,11,0)
	SAVEI32(PL_hints);
# endif /* <5.11.0 */
	PL_hints |= HINT_LOCALIZE_HH;
	SAVEHINTS();
	hv_clear(GvHV(PL_hintgv));
# if Q_HAVE_COP_HINTS_HASH
	if(PL_compiling.cop_hints_hash) {
		refcounted_he_free(PL_compiling.cop_hints_hash);
		PL_compiling.cop_hints_hash = NULL;
	}
# endif /* Q_HAVE_COP_HINTS_HASH */
	return PL_op->op_next;
}

# define newOP_squashhints() THX_newOP_squashhints(aTHX)
static OP *THX_newOP_squashhints(pTHX)
{
	OP *squashhints_op = newOP(OP_PUSHMARK, 0);
	squashhints_op->op_type = OP_RAND;
	squashhints_op->op_ppaddr = THX_pp_squashhints;
	return squashhints_op;
}

# define pp_maybesquashhints() THX_pp_maybesquashhints(aTHX)
static OP *THX_pp_maybesquashhints(pTHX)
{
	dSP;
	SV *arg = TOPs;
	return SvNIOKp(arg) || (PERL_VERSION_GE(5,9,2) && SvVOK(arg)) ?
		PL_op->op_next : pp_squashhints();
}

# define newOP_maybesquashhints(argop) THX_newOP_maybesquashhints(aTHX_ argop)
static OP *THX_newOP_maybesquashhints(pTHX_ OP *argop)
{
	OP *msh_op = newUNOP(OP_NULL, 0, argop);
	msh_op->op_type = OP_RAND;
	msh_op->op_ppaddr = THX_pp_maybesquashhints;
	return msh_op;
}

static OP *(*THX_nxck_require)(pTHX_ OP *op);

static OP *THX_myck_require(pTHX_ OP *op)
{
	OP *argop;
	if(!(op->op_flags & OPf_KIDS)) {
		/*
		 * We need to expand the implicit-parameter case
		 * to an explicit parameter that we can operate on.
		 * This duplicates what ck_fun() would do, including
		 * its invocation of a fresh chain of op checkers.
		 */
		op_free(op);
		return newUNOP(OP_REQUIRE, 0, newDEFSVOP());
	}
	argop = cUNOPx(op)->op_first;
	if(argop->op_type == OP_CONST && (argop->op_private & OPpCONST_BARE)) {
		/*
		 * Bareword argument gets special handling in standard
		 * checker, which we'd rather not interfere with by the
		 * process that we'd need to use a maybesquashhints op.
		 * Fortunately, we don't need access to the runtime
		 * argument in this case: we know it must be a module
		 * name, so we definitely want to squash hints at runtime.
		 * So build op tree with an unconditional squashhints op.
		 */
		op = THX_nxck_require(aTHX_ op);
		op = append_list(OP_LINESEQ, (LISTOP*)newOP_squashhints(),
						(LISTOP*)op);
	} else {
		/*
		 * Whether we want to squash hints depends on whether
		 * the argument at runtime is a version number or not.
		 * So we wrap the argument op, separating it from the
		 * require op.
		 */
		OP *sib = OpSIBLING(argop);
		OpLASTSIB_set(argop, NULL);
		argop = newOP_maybesquashhints(op_scalar(argop));
		OpMAYBESIB_set(argop, sib, op);
		cUNOPx(op)->op_first = argop;
	}
	op = prepend_elem(OP_LINESEQ, newOP(OP_ENTER, 0), op);
	op->op_type = OP_LEAVE;
	op->op_ppaddr = PL_ppaddr[OP_LEAVE];
	op->op_flags |= OPf_PARENS;
	return op;
}

#endif /* Q_MUST_WORKAROUND */

MODULE = Lexical::SealRequireHints PACKAGE = Lexical::SealRequireHints

PROTOTYPES: DISABLE

void
import(SV *classname)
CODE:
	PERL_UNUSED_VAR(classname);
#if Q_MUST_WORKAROUND
	wrap_op_checker(OP_REQUIRE, THX_myck_require, &THX_nxck_require);
#endif /* Q_MUST_WORKAROUND */

void
unimport(SV *classname, ...)
CODE:
	PERL_UNUSED_VAR(classname);
	croak("Lexical::SealRequireHints does not support unimportation");
