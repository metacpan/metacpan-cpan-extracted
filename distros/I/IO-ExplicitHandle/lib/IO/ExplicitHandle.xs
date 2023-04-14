#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define Q_PERL_VERSION_DECIMAL(r,v,s) ((r)*1000000 + (v)*1000 + (s))
#define Q_PERL_DECIMAL_VERSION \
	Q_PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define Q_PERL_VERSION_GE(r,v,s) \
	(Q_PERL_DECIMAL_VERSION >= Q_PERL_VERSION_DECIMAL(r,v,s))
#define Q_PERL_VERSION_LT(r,v,s) \
	(Q_PERL_DECIMAL_VERSION < Q_PERL_VERSION_DECIMAL(r,v,s))

#if Q_PERL_VERSION_LT(5,7,2)
# undef dNOOP
# define dNOOP extern int Perl___notused_func(void)
#endif /* <5.7.2 */

#if (Q_PERL_VERSION_GE(5,17,6) && Q_PERL_VERSION_LT(5,17,11)) || \
	(Q_PERL_VERSION_GE(5,19,3) && Q_PERL_VERSION_LT(5,21,1))
PERL_STATIC_INLINE void suppress_unused_warning(void)
{
	(void) S_croak_memory_wrap;
}
#endif /* (>=5.17.6 && <5.17.11) || (>=5.19.3 && <5.21.1) */

#ifndef SVfARG
# define SVfARG(p) ((void *)(p))
#endif /* !SVfARG */

#ifndef hv_fetchs
# define hv_fetchs(hv, keystr, lval) \
		hv_fetch(hv, "" keystr "", sizeof(keystr)-1, lval)
#endif /* !hv_fetchs */

#ifndef hv_deletes
# define hv_deletes(hv, keystr, flags) \
		hv_delete(hv, "" keystr "", sizeof(keystr)-1, flags)
#endif /* !hv_deletes */

#ifndef newSVpvs
# define newSVpvs(string) newSVpvn("" string "", sizeof(string)-1)
#endif /* !newSVpvs */

#if Q_PERL_VERSION_GE(5,9,5)
# ifndef qerror
#  define qerror(m) Perl_qerror(aTHX_ m)
# endif /* !qerror */
#else /* <5.9.5 */
# undef qerror
# define qerror(m) THX_qerror(aTHX_ m)
static void THX_qerror(pTHX_ SV *msg)
{
	if(PL_in_eval)
		sv_catsv(ERRSV, msg);
	else if(PL_errors)
		sv_catsv(PL_errors, msg);
	else
		Perl_warn(aTHX_ "%" SVf "", SVfARG(msg));
	PL_error_count++;
}
#endif /* <5.9.5 */

#ifndef GvNAMELEN_get
# define GvNAMELEN_get GvNAMELEN
#endif /* !GvNAMELEN_get */

#ifndef GvNAME_get
# define GvNAME_get GvNAME
#endif /* !GvNAME_get */

#if Q_PERL_VERSION_LT(5,9,3)
typedef OP *(*Perl_check_t)(pTHX_ OP *);
#endif /* <5.9.3 */

#if Q_PERL_VERSION_LT(5,10,1)
typedef unsigned Optype;
#endif /* <5.10.1 */

#if Q_PERL_VERSION_GE(5,7,3)
# define PERL_UNUSED_THX() NOOP
#else /* <5.7.3 */
# define PERL_UNUSED_THX() ((void)(aTHX+0))
#endif /* <5.7.3 */

#ifndef wrap_op_checker
# define wrap_op_checker(c,n,o) THX_wrap_op_checker(aTHX_ c,n,o)
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
#endif /* !wrap_op_checker */

#define Q_HAVE_SAY Q_PERL_VERSION_GE(5,9,3)

#define STRICT_HINT_KEY "IO::ExplicitHandle/strict"

#define in_strictexplicithandle() THX_in_strictexplicithandle(aTHX)
static bool THX_in_strictexplicithandle(pTHX)
{
	SV **svp = hv_fetchs(GvHV(PL_hintgv), STRICT_HINT_KEY, 0);
	return svp && SvTRUE(*svp);
}

#define qerror_unspec_handle_op(c) THX_qerror_unspec_handle_op(aTHX_ c)
static void THX_qerror_unspec_handle_op(pTHX_ Optype opcode)
{
	qerror(mess("Unspecified I/O handle in %s", PL_op_desc[opcode]));
}

#define EXPLICITHANDLE_OP_CHECKER(OPNAME, opname, is_bad) \
	static Perl_check_t THX_nxck_##opname; \
	static OP *THX_myck_##opname(pTHX_ OP *op) \
	{ \
		if(!in_strictexplicithandle()) \
			return THX_nxck_##opname(aTHX_ op); \
		op = THX_nxck_##opname(aTHX_ op); \
		if(op->op_type == OP_##OPNAME && (is_bad)) \
			qerror_unspec_handle_op(OP_##OPNAME); \
		return op; \
	}

EXPLICITHANDLE_OP_CHECKER(PRINT, print, !(op->op_flags & OPf_STACKED))

EXPLICITHANDLE_OP_CHECKER(PRTF, prtf, !(op->op_flags & OPf_STACKED))

#if Q_HAVE_SAY
EXPLICITHANDLE_OP_CHECKER(SAY, say, !(op->op_flags & OPf_STACKED))
#endif /* Q_HAVE_SAY */

EXPLICITHANDLE_OP_CHECKER(CLOSE, close, !(op->op_private & 15))

EXPLICITHANDLE_OP_CHECKER(ENTERWRITE, enterwrite, !(op->op_private & 15))

EXPLICITHANDLE_OP_CHECKER(EOF, eof,
	!(op->op_private & 15) && !(op->op_flags & OPf_SPECIAL))

EXPLICITHANDLE_OP_CHECKER(TELL, tell, !(op->op_private & 15))

static Perl_check_t THX_nxck_rv2sv;
static OP *THX_myck_rv2sv(pTHX_ OP *op)
{
	OP *rvop;
	GV *gv;
	if(!in_strictexplicithandle()) return THX_nxck_rv2sv(aTHX_ op);
	op = THX_nxck_rv2sv(aTHX_ op);
	if(op->op_type == OP_RV2SV && (op->op_flags & OPf_KIDS) &&
			(rvop = cUNOPx(op)->op_first) &&
			(rvop->op_type == OP_GV) && (gv = cGVOPx_gv(rvop)) &&
			isGV((SV*)gv) && GvNAMELEN_get(gv) == 1) {
		char nc = *GvNAME_get(gv);
		switch(nc) {
			case '|':
			case '^':
			case '~':
			case '=':
			case '-':
			case '%':
			case '.':
				qerror(mess("Unspecified I/O handle in $%c",
						nc));
		}
	}
	return op;
}

MODULE = IO::ExplicitHandle PACKAGE = IO::ExplicitHandle

PROTOTYPES: DISABLE

BOOT:

	wrap_op_checker(OP_PRINT, THX_myck_print, &THX_nxck_print);
	wrap_op_checker(OP_PRTF, THX_myck_prtf, &THX_nxck_prtf);
#if Q_HAVE_SAY
	wrap_op_checker(OP_SAY, THX_myck_say, &THX_nxck_say);
#endif /* Q_HAVE_SAY */
	wrap_op_checker(OP_CLOSE, THX_myck_close, &THX_nxck_close);
	wrap_op_checker(OP_ENTERWRITE, THX_myck_enterwrite,
		&THX_nxck_enterwrite);
	wrap_op_checker(OP_EOF, THX_myck_eof, &THX_nxck_eof);
	wrap_op_checker(OP_TELL, THX_myck_tell, &THX_nxck_tell);
	wrap_op_checker(OP_RV2SV, THX_myck_rv2sv, &THX_nxck_rv2sv);

void
import(SV *classname)
PREINIT:
	SV *val;
CODE:
	PERL_UNUSED_VAR(classname);
	PL_hints |= HINT_LOCALIZE_HH;
	gv_HVadd(PL_hintgv);
	val = newSVsv(&PL_sv_yes);
	if(hv_store_ent(GvHV(PL_hintgv), sv_2mortal(newSVpvs(STRICT_HINT_KEY)),
			val, 0)) {
		SvSETMAGIC(val);
	} else {
		SvREFCNT_dec(val);
	}

void
unimport(SV *classname)
CODE:
	PERL_UNUSED_VAR(classname);
	PL_hints |= HINT_LOCALIZE_HH;
	gv_HVadd(PL_hintgv);
	(void) hv_deletes(GvHV(PL_hintgv), STRICT_HINT_KEY, G_DISCARD);
