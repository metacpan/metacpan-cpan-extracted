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

#ifndef op_append_elem
# define op_append_elem(t, f, l) THX_op_append_elem(aTHX_ t, f, l)
static OP *THX_op_append_elem(pTHX_ I32 type, OP *first, OP *last)
{
	if(!first) return last;
	if(!last) return first;
	if(first->op_type != (unsigned)type ||
			(type == OP_LIST && (first->op_flags & OPf_PARENS)))
		return newLISTOP(type, 0, first, last);
	if(first->op_flags & OPf_KIDS) {
		cLISTOPx(first)->op_last->op_sibling = last;
	} else {
		first->op_flags |= OPf_KIDS;
		cLISTOPx(first)->op_first = last;
	}
	cLISTOPx(first)->op_last = last;
	return first;
}
#endif /* !op_append_elem */

#ifndef qerror
# define qerror(m) Perl_qerror(aTHX_ m)
#endif /* !qerror */

#define QPFX C8K61oRQKxigiqmUlVdk_
#define QPFXS STRINGIFY(QPFX)
#define QCONCAT0(a,b) a##b
#define QCONCAT1(a,b) QCONCAT0(a,b)
#define QPFXD(name) QCONCAT1(QPFX, name)

#if defined(WIN32) && PERL_VERSION_GE(5,13,6)
# define MY_BASE_CALLCONV EXTERN_C
# define MY_BASE_CALLCONV_S "EXTERN_C"
#else /* !(WIN32 && >= 5.13.6) */
# define MY_BASE_CALLCONV PERL_CALLCONV
# define MY_BASE_CALLCONV_S "PERL_CALLCONV"
#endif /* !(WIN32 && >= 5.13.6) */

#define MY_EXPORT_CALLCONV MY_BASE_CALLCONV

#if defined(WIN32) || defined(__CYGWIN__)
# define MY_IMPORT_CALLCONV_S MY_BASE_CALLCONV_S" __declspec(dllimport)"
#else
# define MY_IMPORT_CALLCONV_S MY_BASE_CALLCONV_S
#endif

static MGVTBL mgvtbl_parsecall;

typedef OP *(*Perl_call_parser)(pTHX_ GV *, SV *, U32 *);

#define CALLPARSER_PARENS    0x00000001
#define CALLPARSER_STATEMENT 0x00000002

#ifdef parse_fullexpr
# define Q_PARSER_AVAILABLE 1
#endif /* parse_fullexpr */

#if Q_PARSER_AVAILABLE

# define Perl_parse_args_parenthesised QPFXD(pac0)
# define parse_args_parenthesised(fp) Perl_parse_args_parenthesised(aTHX_ fp)
MY_EXPORT_CALLCONV OP *QPFXD(pac0)(pTHX_ U32 *flags_p)
{
	OP *argsop;
	lex_read_space(0);
	if(lex_peek_unichar(0) != '('/*)*/) {
		qerror(mess("syntax error"));
		return NULL;
	}
	lex_read_unichar(0);
	argsop = parse_fullexpr(PARSE_OPTIONAL);
	lex_read_space(0);
	if(lex_peek_unichar(0) != /*(*/')') {
		qerror(mess("syntax error"));
		return argsop;
	}
	lex_read_unichar(0);
	*flags_p |= CALLPARSER_PARENS;
	return argsop;
}

# define Perl_parse_args_nullary QPFXD(paz0)
# define parse_args_nullary(fp) Perl_parse_args_nullary(aTHX_ fp)
MY_EXPORT_CALLCONV OP *QPFXD(paz0)(pTHX_ U32 *flags_p)
{
	lex_read_space(0);
	if(lex_peek_unichar(0) == '('/*)*/)
		return parse_args_parenthesised(flags_p);
	return NULL;
}

# define Perl_parse_args_unary QPFXD(pau0)
# define parse_args_unary(fp) Perl_parse_args_unary(aTHX_ fp)
MY_EXPORT_CALLCONV OP *QPFXD(pau0)(pTHX_ U32 *flags_p)
{
	lex_read_space(0);
	if(lex_peek_unichar(0) == '('/*)*/)
		return parse_args_parenthesised(flags_p);
	return parse_arithexpr(PARSE_OPTIONAL);
}

# define Perl_parse_args_list QPFXD(pal0)
# define parse_args_list(fp) Perl_parse_args_list(aTHX_ fp)
MY_EXPORT_CALLCONV OP *QPFXD(pal0)(pTHX_ U32 *flags_p)
{
	lex_read_space(0);
	if(lex_peek_unichar(0) == '('/*)*/)
		return parse_args_parenthesised(flags_p);
	return parse_listexpr(PARSE_OPTIONAL);
}

# define Perl_parse_args_block_list QPFXD(pab0)
# define parse_args_block_list(fp) Perl_parse_args_block_list(aTHX_ fp)
MY_EXPORT_CALLCONV OP *QPFXD(pab0)(pTHX_ U32 *flags_p)
{
	OP *blkop, *argsop;
	I32 c;
	lex_read_space(0);
	c = lex_peek_unichar(0);
	if(c == '('/*)*/) return parse_args_parenthesised(flags_p);
	if(c == '{'/*}*/) {
		I32 floor = start_subparse(0, CVf_ANON);
		SAVEFREESV(PL_compcv);
		blkop = parse_block(0);
		SvREFCNT_inc_simple_void((SV*)PL_compcv);
		blkop = newANONATTRSUB(floor, NULL, NULL, blkop);
	} else {
		blkop = NULL;
	}
	argsop = parse_listexpr(PARSE_OPTIONAL);
	return op_prepend_elem(OP_LIST, blkop, argsop);
}

# define Perl_parse_args_proto QPFXD(pap0)
# define parse_args_proto(gv, sv, fp) Perl_parse_args_proto(aTHX_ gv, sv, fp)
MY_EXPORT_CALLCONV OP *QPFXD(pap0)(pTHX_ GV *namegv, SV *protosv, U32 *flags_p)
{
	STRLEN proto_len;
	char const *proto;
	PERL_UNUSED_ARG(namegv);
	if (SvTYPE(protosv) == SVt_PVCV ? !SvPOK(protosv) : !SvOK(protosv))
		croak("panic: parse_args_proto with no proto");
	/*
	 * There are variations between Perl versions in the syntactic
	 * interpretation of prototypes, which this code in principle
	 * needs to track.  However, from the introduction of the parser
	 * API functions required by this code (5.13.8) to the date
	 * of this note (5.14.0-RC0) there have been no such changes.
	 * With luck there may be no more before this function migrates
	 * into the core.
	 */
	proto = SvPV(protosv, proto_len);
	if(!proto_len) return parse_args_nullary(flags_p);
	while(*proto == ';') proto++;
	if(proto[0] == '&') return parse_args_block_list(flags_p);
	if(((proto[0] == '$' || proto[0] == '_' ||
					proto[0] == '*' || proto[0] == '+') &&
				!proto[1]) ||
			(proto[0] == '\\' && proto[1] && !proto[2]))
		return parse_args_unary(flags_p);
	if(proto[0] == '\\' && proto[1] == '['/*]*/) {
		proto += 2;
		while(*proto && *proto != /*[*/']') proto++;
		if(proto[0] == /*[*/']' && !proto[1])
			return parse_args_unary(flags_p);
	}
	return parse_args_list(flags_p);
}

# define Perl_parse_args_proto_or_list QPFXD(pan0)
# define parse_args_proto_or_list(gv, sv, fp) \
	Perl_parse_args_proto_or_list(aTHX_ gv, sv, fp)
MY_EXPORT_CALLCONV OP *QPFXD(pan0)(pTHX_ GV *namegv, SV *protosv, U32 *flags_p)
{
	if(SvTYPE(protosv) == SVt_PVCV ? SvPOK(protosv) : SvOK(protosv))
		return parse_args_proto(namegv, protosv, flags_p);
	else
		return parse_args_list(flags_p);
}

#endif /* Q_PARSER_AVAILABLE */

#ifndef mg_findext
# define mg_findext(sv, type, vtbl) THX_mg_findext(aTHX_ sv, type, vtbl)
static MAGIC *THX_mg_findext(pTHX_ SV *sv, int type, MGVTBL const *vtbl)
{
	MAGIC *mg;
	if(sv)
		for(mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic)
			if(mg->mg_type == type && mg->mg_virtual == vtbl)
				return mg;
	return NULL;
}
#endif /* !mg_findext */

#ifndef sv_unmagicext
# define sv_unmagicext(sv, type, vtbl) THX_sv_unmagicext(aTHX_ sv, type, vtbl)
static int THX_sv_unmagicext(pTHX_ SV *sv, int type, MGVTBL const *vtbl)
{
	MAGIC *mg, **mgp;
	if((vtbl && vtbl->svt_free) || type == PERL_MAGIC_regex_global)
		/* exceeded intended usage of this reserve implementation */
		return 0;
	if(SvTYPE(sv) < SVt_PVMG || !SvMAGIC(sv)) return 0;
	mgp = NULL;
	for(mg = mgp ? *mgp : SvMAGIC(sv); mg; mg = mgp ? *mgp : SvMAGIC(sv)) {
		if(mg->mg_type == type && mg->mg_virtual == vtbl) {
			if(mgp)
				*mgp = mg->mg_moremagic;
			else
				SvMAGIC_set(sv, mg->mg_moremagic);
			if(mg->mg_flags & MGf_REFCOUNTED)
				SvREFCNT_dec(mg->mg_obj);
			Safefree(mg);
		} else {
			mgp = &mg->mg_moremagic;
		}
	}
	SvMAGICAL_off(sv);
	mg_magical(sv);
	return 0;
}
#endif /* !sv_unmagicext */

MY_EXPORT_CALLCONV void QPFXD(gcp0)(pTHX_ CV *cv,
	Perl_call_parser *psfun_p, SV **psobj_p)
{
	MAGIC *callmg = SvMAGICAL((SV*)cv) ?
		mg_findext((SV*)cv, PERL_MAGIC_ext, &mgvtbl_parsecall) : NULL;
	if(callmg) {
		*psfun_p = DPTR2FPTR(Perl_call_parser, callmg->mg_ptr);
		*psobj_p = callmg->mg_obj;
	} else {
		*psfun_p = DPTR2FPTR(Perl_call_parser, NULL);
		*psobj_p = NULL;
	}
}

MY_EXPORT_CALLCONV void QPFXD(scp0)(pTHX_ CV *cv,
	Perl_call_parser psfun, SV *psobj)
{
	if(
		(!psfun && !psobj)
#if Q_PARSER_AVAILABLE
		|| (psfun == Perl_parse_args_proto_or_list && psobj == (SV*)cv)
#endif /* Q_PARSER_AVAILABLE */
	) {
		if(SvMAGICAL((SV*)cv))
			sv_unmagicext((SV*)cv, PERL_MAGIC_ext,
				&mgvtbl_parsecall);
	} else {
		MAGIC *callmg =
			mg_findext((SV*)cv, PERL_MAGIC_ext, &mgvtbl_parsecall);
		if(!callmg)
			callmg = sv_magicext((SV*)cv, &PL_sv_undef,
				PERL_MAGIC_ext, &mgvtbl_parsecall, NULL, 0);
		if(callmg->mg_flags & MGf_REFCOUNTED) {
			SvREFCNT_dec(callmg->mg_obj);
			callmg->mg_flags &= ~MGf_REFCOUNTED;
		}
		callmg->mg_ptr = FPTR2DPTR(char *, psfun);
		callmg->mg_obj = psobj;
		if(psobj != (SV*)cv) {
			SvREFCNT_inc(psobj);
			callmg->mg_flags |= MGf_REFCOUNTED;
		}
	}
}

#if Q_PARSER_AVAILABLE

MY_EXPORT_CALLCONV void QPFXD(gcp1)(pTHX_ CV *cv,
	Perl_call_parser *psfun_p, SV **psobj_p)
{
	QPFXD(gcp0)(aTHX_ cv, psfun_p, psobj_p);
	if(!*psfun_p && !*psobj_p) {
		*psfun_p = Perl_parse_args_proto_or_list;
		*psobj_p = (SV*)cv;
	}
}

MY_EXPORT_CALLCONV void QPFXD(scp1)(pTHX_ CV *cv,
	Perl_call_parser psfun, SV *psobj)
{
	if(!psobj) croak("null object for cv_set_call_parser");
	QPFXD(scp0)(aTHX_ cv, psfun, psobj);
}

#endif /* Q_PARSER_AVAILABLE */

static int (*next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);
static int my_keyword_plugin(pTHX_
	char *keyword_ptr, STRLEN keyword_len, OP **op_ptr)
{
	OP *nmop, *cvop, *argsop;
	CV *cv;
	GV *namegv;
	Perl_call_parser psfun;
	SV *psobj;
	U32 parser_flags;
	/*
	 * Creation of the rv2cv op below (or more precisely its gv op
	 * child created during checking) uses a pad slot under threads.
	 * Normally this is fine, but early versions of the padrange
	 * mechanism make assumptions about pad slots being contiguous
	 * that this breaks.  On the affected perl versions, therefore,
	 * we watch for the pad slot being consumed, and restore the
	 * pad's fill pointer if we throw the op away (upon declining
	 * to handle the keyword).
	 *
	 * The core bug was supposedly fixed in Perl 5.19.4, but actually
	 * that version exhibits a different bug also apparently related
	 * to padrange.  Restoring the pad's fill pointer works around
	 * this bug too.  So for now this workaround is used with no
	 * upper bound on the Perl version.
	 */
#define MUST_RESTORE_PAD_FILL PERL_VERSION_GE(5,17,6)
#if MUST_RESTORE_PAD_FILL
	I32 padfill = av_len(PL_comppad);
#endif /* MUST_RESTORE_PAD_FILL */
	/*
	 * If Devel::Declare happens to be loaded, it triggers magic
	 * upon building of an rv2cv op, assuming that it's being built
	 * by the lexer.  Since we're about to build such an op here,
	 * replicating what the lexer will normally do shortly after,
	 * there's a risk that Devel::Declare could fire here, ultimately
	 * firing twice for a single appearance of a name it's interested
	 * in.	To suppress Devel::Declare, therefore, we temporarily
	 * set PL_parser to null.  The same goes for Data::Alias and
	 * some other modules that use similar techniques.
	 *
	 * Unfortunately Devel::Declare prior to 0.006004 still does some
	 * work at the wrong time if PL_parser is null, and Data::Alias
	 * prior to 1.13 crashes if PL_parser is null.	So this module
	 * is not compatible with earlier versions of those modules,
	 * and can't be made compatible.
	 */
	ENTER;
	SAVEVPTR(PL_parser);
	PL_parser = NULL;
	nmop = newSVOP(OP_CONST, 0, newSVpvn(keyword_ptr, keyword_len));
	nmop->op_private = OPpCONST_BARE;
	cvop = newCVREF(0, nmop);
	LEAVE;
	if(!(cv = rv2cv_op_cv(cvop, 0))) {
		decline:
		op_free(cvop);
#if MUST_RESTORE_PAD_FILL
		av_fill(PL_comppad, padfill);
#endif /* MUST_RESTORE_PAD_FILL */
		return next_keyword_plugin(aTHX_
			keyword_ptr, keyword_len, op_ptr);
	}
	QPFXD(gcp0)(aTHX_ cv, &psfun, &psobj);
	if(!psfun && !psobj) goto decline;
	namegv = (GV*)rv2cv_op_cv(cvop,
			RV2CVOPCV_MARK_EARLY|RV2CVOPCV_RETURN_NAME_GV);
	parser_flags = 0;
	argsop = psfun(aTHX_ namegv, psobj, &parser_flags);
	if(!(parser_flags & CALLPARSER_PARENS))
		cvop->op_private |= OPpENTERSUB_NOPAREN;
	*op_ptr = newUNOP(OP_ENTERSUB, OPf_STACKED,
			op_append_elem(OP_LIST, argsop, cvop));
	return (parser_flags & CALLPARSER_STATEMENT) ?
		KEYWORD_PLUGIN_STMT : KEYWORD_PLUGIN_EXPR;
}

#define fmt_header(n, content) THX_fmt_header(aTHX_ n, content)
static SV *THX_fmt_header(pTHX_ char n, char const *content)
{
	return newSVpvf(
		"/* DO NOT EDIT -- generated "
			"by Devel::CallParser version "XS_VERSION" */\n"
		"#ifndef "QPFXS"INCLUDED_callparser%c\n"
		"#define "QPFXS"INCLUDED_callparser%c 1\n"
		"#ifndef PERL_VERSION\n"
		" #error you must include perl.h before callparser%c.h\n"
		"#elif !(PERL_REVISION == "STRINGIFY(PERL_REVISION)
			" && PERL_VERSION == "STRINGIFY(PERL_VERSION)
#if PERL_VERSION & 1
			" && PERL_SUBVERSION == "STRINGIFY(PERL_SUBVERSION)
#endif /* PERL_VERSION & 1 */
			")\n"
		" #error this callparser%c.h is for Perl "
			STRINGIFY(PERL_REVISION)"."STRINGIFY(PERL_VERSION)
#if PERL_VERSION & 1
			"."STRINGIFY(PERL_SUBVERSION)
#endif /* PERL_VERSION & 1 */
			" only\n"
		"#endif /* Perl version mismatch */\n"
		"%s"
		"#endif /* !"QPFXS"INCLUDED_callparser%c */\n",
		n, n, n, n, content, n);
}

#define DEFFN(RETTYPE, PUBNAME, PRIVNAME, ARGTYPES, ARGNAMES) \
	MY_IMPORT_CALLCONV_S" "RETTYPE" "QPFXS PRIVNAME"(pTHX_ "ARGTYPES");\n" \
	"#define Perl_"PUBNAME" "QPFXS PRIVNAME"\n" \
	"#define "PUBNAME"("ARGNAMES") Perl_"PUBNAME"(aTHX_ "ARGNAMES")\n"

#define DEFCALLBACK \
	"typedef OP *(*Perl_call_parser)(pTHX_ GV *, SV *, U32 *);\n" \
	"#define CALLPARSER_PARENS    0x00000001\n" \
	"#define CALLPARSER_STATEMENT 0x00000002\n"

MODULE = Devel::CallParser PACKAGE = Devel::CallParser

PROTOTYPES: DISABLE

BOOT:
	next_keyword_plugin = PL_keyword_plugin;
	PL_keyword_plugin = my_keyword_plugin;

SV *
callparser0_h()
CODE:
	RETVAL = fmt_header('0',
		DEFCALLBACK
		DEFFN("void", "cv_get_call_parser", "gcp0",
			"CV *, Perl_call_parser *, SV **", "cv, fp, op")
		DEFFN("void", "cv_set_call_parser", "scp0",
			"CV *, Perl_call_parser, SV *", "cv, f, o")
	);
OUTPUT:
	RETVAL

SV *
callparser1_h()
CODE:
#if Q_PARSER_AVAILABLE
	RETVAL = fmt_header('1',
		DEFFN("OP *", "parse_args_parenthesised", "pac0", "U32 *", "fp")
		DEFFN("OP *", "parse_args_nullary", "paz0", "U32 *", "fp")
		DEFFN("OP *", "parse_args_unary", "pau0", "U32 *", "fp")
		DEFFN("OP *", "parse_args_list", "pal0", "U32 *", "fp")
		DEFFN("OP *", "parse_args_block_list", "pab0", "U32 *", "fp")
		DEFFN("OP *", "parse_args_proto", "pap0",
			"GV *, SV *, U32 *", "gv, sv, fp")
		DEFFN("OP *", "parse_args_proto_or_list", "pan0",
			"GV *, SV *, U32 *", "gv, sv, fp")
		DEFCALLBACK
		DEFFN("void", "cv_get_call_parser", "gcp1",
			"CV *, Perl_call_parser *, SV **", "cv, fp, op")
		DEFFN("void", "cv_set_call_parser", "scp1",
			"CV *, Perl_call_parser, SV *", "cv, f, o")
	);
#else /* !Q_PARSER_AVAILABLE */
	croak("callparser1.h not available on this version of Perl");
#endif /* !Q_PARSER_AVAILABLE */
OUTPUT:
	RETVAL
