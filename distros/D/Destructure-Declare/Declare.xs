#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"  /* backports OpSIBLING / pad_add_name_pvn etc. to 5.14-5.20 */

/* pad_add_name_pvn was a 5.15.1 rename of pad_add_name; the 5.14 function has
 * the identical (name, len, flags, typestash, ourstash) signature. */
#if PERL_VERSION < 16
#  define pad_add_name_pvn(name, len, flags, typestash, ourstash) \
       Perl_pad_add_name(aTHX_ (name), (len), (flags), (typestash), (ourstash))
#endif

/* Previous keyword plugin in the chain. */
static int (*dd_next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);

/* The destructuring pattern engine (parser, codegen, custom ops). Canonical
 * source for this dist and, via ExtUtils::Depends, for consumers. */
#include "destructure.h"

/* True if the Destructure::Declare lexical pragma is in scope here. */
static int dd_in_scope(pTHX) {
	HV *hints = GvHV(PL_hintgv);
	SV **ent;
	if (!hints) return 0;
	ent = hv_fetchs(hints, "Destructure::Declare", 0);
	return ent && SvTRUE(*ent);
}

/* ---- the keyword entry point ----------------------------------------------- */

static OP *dd_parse_let(pTHX) {
	dd_pat pat;
	OP *rhs, *seq, *store, *lhs;
	PADOFFSET src;
	I32 c;

	lex_read_space(0);
	dd_parse_pattern(aTHX_ &pat);

	lex_read_space(0);
	c = lex_peek_unichar(0);
	if (c != '=' || PL_parser->bufptr[1] == '>')
		croak("let: expected '=' after pattern");
	lex_read_unichar(0);
	lex_read_space(0);

	rhs = parse_fullexpr(0);

	/* consume the terminating ';' */
	lex_read_space(0);
	if (lex_peek_unichar(0) == ';') lex_read_unichar(0);

	/* Fast path: a flat array/list pattern is a single native list-assignment.
	 * A bare constant array source (let [$x] = "str") is excluded: @{CONST}
	 * constant-folds to a symbolic deref that dies at compile time under strict;
	 * it falls through to the per-element path, which gives the usual runtime
	 * "Can't use string as an ARRAY reference" instead. (DD_LIST has no deref.) */
	if (dd_is_listassign(&pat)
	    && !(pat.shape == DD_ARRAY && rhs->op_type == OP_CONST)) {
		OP *llist = dd_listassign_lhs(aTHX_ &pat);
		OP *rv;
		if (pat.shape == DD_LIST) {
			rv = rhs;                                  /* my (LHS) = LIST   */
		} else {
			/* my (LHS) = @{ SRC // [] }; the // [] keeps an undef source
			 * yielding empties (no warning), matching the per-element path. */
			rv = newUNOP(OP_RV2AV, 0,
			             newLOGOP(OP_DOR, 0, rhs, dd_empty_aref(aTHX)));
		}
		dd_free_pat(aTHX_ &pat);
		return newSTATEOP(0, NULL,
		                  newASSIGNOP(OPf_STACKED, llist, 0, rv));
	}

	/* A ( ... ) pattern destructures a *list*: evaluate the RHS in list
	 * context and capture it into an anonymous arrayref, then reuse the exact
	 * positional codegen as for an [ ... ] arrayref pattern. */
	if (pat.shape == DD_LIST)
		rhs = op_convert_list(OP_ANONLIST, OPf_SPECIAL, rhs);   /* [ LIST ] */

	/* my $src = RHS;  (the once-only source ref) */
	src = dd_temp(aTHX);
	lhs = dd_padsv(aTHX_ src);
	lhs->op_private |= OPpLVAL_INTRO;
	store = newSTATEOP(0, NULL, newASSIGNOP(OPf_STACKED, lhs, 0, rhs));

	seq = store;
	dd_emit(aTHX_ &pat, src, &seq);

	dd_free_pat(aTHX_ &pat);

	/* No op_scope: the introduced lexicals must remain visible in the
	 * enclosing block, exactly like `my`. */
	return seq;
}

static int dd_keyword_plugin(pTHX_ char *kw, STRLEN kwlen, OP **op_ptr) {
	if (kwlen == 3 && memEQ(kw, "let", 3) && dd_in_scope(aTHX)) {
		*op_ptr = dd_parse_let(aTHX);
		return KEYWORD_PLUGIN_STMT;
	}
	return dd_next_keyword_plugin(aTHX_ kw, kwlen, op_ptr);
}

MODULE = Destructure::Declare  PACKAGE = Destructure::Declare
PROTOTYPES: DISABLE

BOOT:
	dd_next_keyword_plugin = PL_keyword_plugin;
	PL_keyword_plugin = dd_keyword_plugin;
	XopENTRY_set(&dd_tail_xop, xop_name, "dd_tail");
	XopENTRY_set(&dd_tail_xop, xop_desc, "Destructure::Declare slurpy tail");
	XopENTRY_set(&dd_tail_xop, xop_class, OA_BINOP);
	Perl_custom_op_register(aTHX_ dd_pp_tail, &dd_tail_xop);
	XopENTRY_set(&dd_hrest_xop, xop_name, "dd_hrest");
	XopENTRY_set(&dd_hrest_xop, xop_desc, "Destructure::Declare hash %rest");
	XopENTRY_set(&dd_hrest_xop, xop_class, OA_LISTOP);
	Perl_custom_op_register(aTHX_ dd_pp_hrest, &dd_hrest_xop);
