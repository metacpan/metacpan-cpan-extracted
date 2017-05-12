#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
	PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
	(PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#ifndef hv_fetchs
# define hv_fetchs(hv, keystr, lval) \
		hv_fetch(hv, ""keystr"", sizeof(keystr)-1, lval)
#endif /* !hv_fetchs */

#ifndef hv_deletes
# define hv_deletes(hv, keystr, flags) \
		hv_delete(hv, ""keystr"", sizeof(keystr)-1, flags)
#endif /* !hv_deletes */

#ifndef newSVpvs
# define newSVpvs(string) newSVpvn(""string"", sizeof(string)-1)
#endif /* !newSVpvs */

#ifndef qerror
# define qerror(m) Perl_qerror(aTHX_ m)
#endif /* !qerror */

#ifndef GvNAMELEN_get
# define GvNAMELEN_get GvNAMELEN
#endif /* !GvNAMELEN_get */

#ifndef GvNAME_get
# define GvNAME_get GvNAME
#endif /* !GvNAME_get */

#if !PERL_VERSION_GE(5,9,3)
typedef OP *(*Perl_check_t)(pTHX_ OP *);
#endif /* <5.9.3 */

#if !PERL_VERSION_GE(5,10,1)
typedef unsigned Optype;
#endif /* <5.10.1 */

#ifndef wrap_op_checker
# define wrap_op_checker(c,n,o) THX_wrap_op_checker(aTHX_ c,n,o)
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
#endif /* !wrap_op_checker */

#define Q_HAVE_SAY PERL_VERSION_GE(5,9,3)

#define STRICT_HINT_KEY "IO::ExplicitHandle/strict"

#define in_strictexplicithandle() THX_in_strictexplicithandle(aTHX)
static bool THX_in_strictexplicithandle(pTHX)
{
	SV **svp = hv_fetchs(GvHV(PL_hintgv), STRICT_HINT_KEY, 0);
	return svp && SvTRUE(*svp);
}

#define qerror_implicit_op(c) THX_qerror_implicit_op(aTHX_ c)
static void THX_qerror_implicit_op(pTHX_ Optype opcode)
{
	qerror(mess("Implicit I/O handle in %s", PL_op_desc[opcode]));
}

#define EXPLICITHANDLE_OP_CHECKER(OPNAME, opname, is_bad) \
	static Perl_check_t nxck_##opname; \
	static OP *myck_##opname(pTHX_ OP *op) \
	{ \
		if(!in_strictexplicithandle()) \
			return nxck_##opname(aTHX_ op); \
		op = nxck_##opname(aTHX_ op); \
		if(op->op_type == OP_##OPNAME && (is_bad)) \
			qerror_implicit_op(OP_##OPNAME); \
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

static Perl_check_t nxck_rv2sv;
static OP *myck_rv2sv(pTHX_ OP *op)
{
	OP *rvop;
	GV *gv;
	if(!in_strictexplicithandle()) return nxck_rv2sv(aTHX_ op);
	op = nxck_rv2sv(aTHX_ op);
	if(op->op_type == OP_RV2SV && (op->op_flags & OPf_KIDS) &&
			(rvop = cUNOPx(op)->op_first) &&
			(rvop->op_type == OP_GV) && (gv = cGVOPx_gv(rvop)) &&
			GvNAMELEN_get(gv) == 1) {
		char nc = *GvNAME_get(gv);
		switch(nc) {
			case '|':
			case '^':
			case '~':
			case '=':
			case '-':
			case '%':
			case '.':
				qerror(mess("Implicit I/O handle in $%c", nc));
		}
	}
	return op;
}

MODULE = IO::ExplicitHandle PACKAGE = IO::ExplicitHandle

PROTOTYPES: DISABLE

BOOT:

	wrap_op_checker(OP_PRINT, myck_print, &nxck_print);
	wrap_op_checker(OP_PRTF, myck_prtf, &nxck_prtf);
#if Q_HAVE_SAY
	wrap_op_checker(OP_SAY, myck_say, &nxck_say);
#endif /* Q_HAVE_SAY */
	wrap_op_checker(OP_CLOSE, myck_close, &nxck_close);
	wrap_op_checker(OP_ENTERWRITE, myck_enterwrite, &nxck_enterwrite);
	wrap_op_checker(OP_EOF, myck_eof, &nxck_eof);
	wrap_op_checker(OP_TELL, myck_tell, &nxck_tell);
	wrap_op_checker(OP_RV2SV, myck_rv2sv, &nxck_rv2sv);

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
