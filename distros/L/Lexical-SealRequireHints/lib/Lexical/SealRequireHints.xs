#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define Q_PERL_VERSION_DECIMAL(r,v,s) ((r)*1000000 + (v)*1000 + (s))
#define Q_PERL_DECIMAL_VERSION \
	Q_PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define Q_PERL_VERSION_GE(r,v,s) \
	(Q_PERL_DECIMAL_VERSION >= Q_PERL_VERSION_DECIMAL(r,v,s))

#if !Q_PERL_VERSION_GE(5,7,2)
# undef dNOOP
# define dNOOP extern int Perl___notused_func(void)
#endif /* <5.7.2 */

#ifndef cBOOL
# define cBOOL(x) ((bool)!!(x))
#endif /* !cBOOL */

#ifndef croak
# define croak Perl_croak_nocontext
#endif /* !croak */

#ifndef hv_existss
# define hv_existss(hv, key) hv_exists(hv, "" key "", sizeof(key)-1)
#endif /* !hv_existss */

#ifndef hv_stores
# define hv_stores(hv, key, val) hv_store(hv, "" key "", sizeof(key)-1, val, 0)
#endif /* !hv_stores */

#define Q_MUST_WORKAROUND (!Q_PERL_VERSION_GE(5,12,0))
#define Q_HAVE_COP_HINTS_HASH Q_PERL_VERSION_GE(5,9,4)

#if Q_MUST_WORKAROUND

# if !Q_PERL_VERSION_GE(5,9,3)
typedef OP *(*Perl_check_t)(pTHX_ OP *);
# endif /* <5.9.3 */

# if !Q_PERL_VERSION_GE(5,10,1)
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

# if Q_PERL_VERSION_GE(5,7,3)
#  define PERL_UNUSED_THX() NOOP
# else /* <5.7.3 */
#  define PERL_UNUSED_THX() ((void)(aTHX+0))
# endif /* <5.7.3 */

# ifndef wrap_op_checker
#  define wrap_op_checker(c,n,o) THX_wrap_op_checker(aTHX_ c,n,o)
static void THX_wrap_op_checker(pTHX_ Optype opcode,
	Perl_check_t new_checker, Perl_check_t *old_checker_p)
{
	PERL_UNUSED_THX();
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
# if Q_PERL_VERSION_GE(5,9,1)
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

# define Q_MODGLOBAL_WORKAROUND_KEY \
	"Lexical::SealRequireHints/applying_workaround"

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
# if !Q_PERL_VERSION_GE(5,11,0)
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

# define newOP_nullarysquashhints() THX_newOP_nullarysquashhints(aTHX)
static OP *THX_newOP_nullarysquashhints(pTHX)
{
	OP *nsh_op = newOP(OP_PUSHMARK, 0);
	nsh_op->op_type = OP_RAND;
	nsh_op->op_ppaddr = THX_pp_squashhints;
	return nsh_op;
}

# define newOP_unarysquashhints(argop) THX_newOP_unarysquashhints(aTHX_ argop)
static OP *THX_newOP_unarysquashhints(pTHX_ OP *argop)
{
	OP *ush_op = newUNOP(OP_NULL, 0, argop);
	ush_op->op_type = OP_RAND;
	ush_op->op_ppaddr = THX_pp_squashhints;
	return ush_op;
}

# define pp_maybesquashhints() THX_pp_maybesquashhints(aTHX)
static OP *THX_pp_maybesquashhints(pTHX)
{
	dSP;
	SV *arg = TOPs;
	return SvNIOKp(arg) || (Q_PERL_VERSION_GE(5,9,2) && SvVOK(arg)) ?
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
	if(!hv_existss(PL_modglobal, Q_MODGLOBAL_WORKAROUND_KEY))
		return THX_nxck_require(aTHX_ op);
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
		op = append_list(OP_LINESEQ,
			(LISTOP*)newOP_nullarysquashhints(), (LISTOP*)op);
	} else {
		/*
		 * Whether we want to squash hints depends on whether
		 * the argument at runtime is a version number or not.
		 * So we wrap the argument op, separating it from the
		 * require op.
		 */
		OP *standinop = newOP(OP_NULL, 0);
		OP *sib = OpSIBLING(argop);
		OpLASTSIB_set(argop, NULL);
		OpMAYBESIB_set(standinop, sib, op);
		cUNOPx(op)->op_first = standinop;
		argop = newOP_maybesquashhints(op_scalar(argop));
		OpLASTSIB_set(standinop, NULL);
		OpMAYBESIB_set(argop, sib, op);
		cUNOPx(op)->op_first = argop;
		op_free(standinop);
	}
	op = prepend_elem(OP_LINESEQ, newOP(OP_ENTER, 0), op);
	op->op_type = OP_LEAVE;
	op->op_ppaddr = PL_ppaddr[OP_LEAVE];
	op->op_flags |= OPf_PARENS;
	return op;
}

static OP *(*THX_nxck_dofile)(pTHX_ OP *op);

static OP *THX_myck_dofile(pTHX_ OP *op)
{
	OP *argop, *standinop, *sib;
	if(!hv_existss(PL_modglobal, Q_MODGLOBAL_WORKAROUND_KEY))
		return THX_nxck_dofile(aTHX_ op);
	if(!(op->op_flags & OPf_KIDS))
		return THX_nxck_dofile(aTHX_ op);
	argop = cUNOPx(op)->op_first;
	standinop = newOP(OP_NULL, 0);
	sib = OpSIBLING(argop);
	OpLASTSIB_set(argop, NULL);
	OpMAYBESIB_set(standinop, sib, op);
	cUNOPx(op)->op_first = standinop;
	argop = newOP_unarysquashhints(op_scalar(argop));
	OpLASTSIB_set(standinop, NULL);
	OpMAYBESIB_set(argop, sib, op);
	cUNOPx(op)->op_first = argop;
	op_free(standinop);
	op = prepend_elem(OP_LINESEQ, newOP(OP_ENTER, 0), op);
	op->op_type = OP_LEAVE;
	op->op_ppaddr = PL_ppaddr[OP_LEAVE];
	op->op_flags |= OPf_PARENS;
	return op;
}

static OP *(*THX_nxck_entersub)(pTHX_ OP *op);

static OP *THX_myck_entersub(pTHX_ OP *op)
{
	OP *pushop, *argop, *cvop, *gvop, *standinop;
	GV *gv;
	char *name;
	pushop = cUNOPx(op)->op_first;
	if(!OpHAS_SIBLING(pushop)) pushop = cUNOPx(pushop)->op_first;
	if(!((argop = OpSIBLING(pushop)) && (cvop = OpSIBLING(argop)) &&
			!OpHAS_SIBLING(cvop) && cvop->op_type == OP_RV2CV &&
			!(cvop->op_private & OPpENTERSUB_AMPER) &&
			(cvop->op_flags & OPf_KIDS) &&
			(gvop = cUNOPx(cvop)->op_first,
				gvop->op_type == OP_GV) &&
			(gv = cGVOPx_gv(gvop),
				SvTYPE((SV*)gv) == SVt_PVGV) &&
			GvSTASH(gv) == PL_globalstash && GvNAMELEN(gv) == 2 &&
			(name = GvNAME(gv), name[0] == 'd' && name[1] == 'o')))
		return THX_nxck_entersub(aTHX_ op);
	standinop = newOP(OP_NULL, 0);
	OpLASTSIB_set(argop, NULL);
	OpMORESIB_set(standinop, cvop);
	OpMORESIB_set(pushop, standinop);
	argop = newOP_unarysquashhints(op_scalar(argop));
	OpLASTSIB_set(standinop, NULL);
	OpMORESIB_set(argop, cvop);
	OpMORESIB_set(pushop, argop);
	op_free(standinop);
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
_install_compilation_workaround()
CODE:
#if Q_MUST_WORKAROUND
	wrap_op_checker(OP_REQUIRE, THX_myck_require, &THX_nxck_require);
	wrap_op_checker(OP_DOFILE, THX_myck_dofile, &THX_nxck_dofile);
	wrap_op_checker(OP_ENTERSUB, THX_myck_entersub, &THX_nxck_entersub);
	(void) hv_stores(PL_modglobal, Q_MODGLOBAL_WORKAROUND_KEY, &PL_sv_yes);
#endif /* Q_MUST_WORKAROUND */
