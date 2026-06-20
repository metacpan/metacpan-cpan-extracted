#ifndef DD_DESTRUCTURE_H
#define DD_DESTRUCTURE_H

#define DD_MAX_ELEMS 4096
/* ---- pattern model ---------------------------------------------------------
 *
 * A `let` PATTERN is a tree. Each element is one of:
 *   DD_SCALAR  - bind a $var (optionally with a // default expr)
 *   DD_HOLE    - `undef` placeholder; consume a slot, bind nothing
 *   DD_SLURPY  - trailing @rest / %rest
 *   DD_NESTED  - a nested [..] / {..} pattern
 *
 * A pattern node is either an array pattern (keyed by position) or a hash
 * pattern (keyed by name). Hash-pattern elements additionally carry `key`.
 */

#define DD_ARRAY 0   /* [ ... ] over an arrayref          */
#define DD_HASH  1   /* { ... } over a hashref            */
#define DD_LIST  2   /* ( ... ) over a list (list-context RHS) */

/* Array-indexed shapes (positional element access): everything but a hash. */
#define DD_IS_ARRAYLIKE(shape) ((shape) != DD_HASH)

#define DD_SCALAR 0
#define DD_HOLE   1
#define DD_SLURPY 2
#define DD_NESTED 3

struct dd_pat;  /* fwd */

typedef struct dd_elem {
	int            kind;     /* DD_SCALAR / DD_HOLE / DD_SLURPY / DD_NESTED */
	SV            *name;     /* DD_SCALAR/DD_SLURPY: the lexical name incl. sigil */
	char           sigil;    /* DD_SLURPY: '@' or '%' */
	SV            *key;      /* hash-pattern element: the key (string), else NULL */
	OP            *deflt;    /* DD_SCALAR: optional default expr op, else NULL */
	struct dd_pat *nested;   /* DD_NESTED: child pattern, else NULL */
} dd_elem;

typedef struct dd_pat {
	int      shape;          /* DD_ARRAY / DD_HASH / DD_LIST */
	int      n;
	dd_elem  elems[DD_MAX_ELEMS];
} dd_pat;


/* Read a bareword identifier from the lexer (or NULL if none). */
static SV *dd_lex_ident(pTHX) {
	SV *buf = newSVpvs("");
	I32 c;
	while (1) {
		c = lex_peek_unichar(0);
		if (c == -1) break;
		if (!isALNUM(c) && c != '_') break;
		sv_catpvf(buf, "%c", (int)c);
		lex_read_unichar(0);
	}
	if (SvCUR(buf) == 0) { SvREFCNT_dec(buf); return NULL; }
	return buf;
}

/* Hand-lex a quoted string literal ('...' or "..."), basic backslash escapes. */
static SV *dd_lex_string(pTHX) {
	I32 quote = lex_read_unichar(0);
	SV *sv = newSVpvs("");
	I32 c;
	while (1) {
		c = lex_read_unichar(0);
		if (c == -1) croak("let: unterminated string in pattern key");
		if (c == '\\') {
			I32 next = lex_read_unichar(0);
			if (next == -1) croak("let: unterminated string in pattern key");
			if (quote == '"') {
				switch (next) {
					case 'n': sv_catpvs(sv, "\n"); break;
					case 't': sv_catpvs(sv, "\t"); break;
					case 'r': sv_catpvs(sv, "\r"); break;
					case '0': sv_catpvs(sv, "\0"); break;
					default:  sv_catpvf(sv, "%c", (int)next); break;
				}
			} else {
				if (next != '\\' && next != '\'')
					sv_catpvf(sv, "%c", '\\');
				sv_catpvf(sv, "%c", (int)next);
			}
		} else if (c == quote) {
			break;
		} else {
			sv_catpvf(sv, "%c", (int)c);
		}
	}
	return sv;
}

/* Read a sigil'd variable name ($foo, @foo, %foo) into an SV including the
 * sigil; returns the sigil char via *sigil. Croaks if not a variable. */
static SV *dd_lex_var(pTHX_ char *sigil) {
	I32 c = lex_peek_unichar(0);
	SV *name, *id;
	if (c != '$' && c != '@' && c != '%')
		croak("let: expected a variable in pattern");
	*sigil = (char)c;
	lex_read_unichar(0);
	id = dd_lex_ident(aTHX);
	if (!id) croak("let: expected an identifier after '%c'", (int)*sigil);
	name = newSVpvf("%c%" SVf, (int)*sigil, SVfARG(id));
	SvREFCNT_dec(id);
	return name;
}

/* A fresh PADSV read op for the pad slot `off`. */
static OP *dd_padsv(pTHX_ PADOFFSET off) {
	OP *o = newOP(OP_PADSV, 0);
	o->op_targ = off;
	return o;
}

/* `$src->[idx]` : aelem over rv2av(OPf_REF, padsv(src)). */
static OP *dd_aelem(pTHX_ PADOFFSET src, IV idx) {
	OP *deref = newUNOP(OP_RV2AV, OPf_REF, dd_padsv(aTHX_ src));
	OP *key   = newSVOP(OP_CONST, 0, newSViv(idx));
	return newBINOP(OP_AELEM, 0, deref, key);
}

/* `$src->{key}` : helem over rv2hv(OPf_REF, padsv(src)). */
static OP *dd_helem(pTHX_ PADOFFSET src, SV *key) {
	OP *deref = newUNOP(OP_RV2HV, OPf_REF, dd_padsv(aTHX_ src));
	OP *kop   = newSVOP(OP_CONST, 0, newSVsv(key));
	return newBINOP(OP_HELEM, 0, deref, kop);
}

/* ---- tail() custom op ------------------------------------------------------
 * A trailing `@rest` in an array pattern binds the elements of the source aref
 * from index N onward. Rather than hand-wire a fragile range/slice optree, it
 * is a self-contained custom op (same family as Switch::Declare's reftype op):
 * evaluate the aref and N onto the stack, then replace them with the tail list.
 * A non-aref source yields the empty list (no warning). */
static XOP dd_tail_xop;

static OP *dd_pp_tail(pTHX) {
	dSP;
	IV n   = POPi;          /* second child: the start index */
	SV *rv = POPs;          /* first child:  the source ref  */
	AV *av;
	IV i, top;
	if (!SvROK(rv) || SvTYPE(SvRV(rv)) != SVt_PVAV) {
		RETURN;             /* not an aref -> empty list */
	}
	av  = (AV *)SvRV(rv);
	top = av_len(av);       /* last valid index, -1 if empty */
	if (n < 0) n = 0;
	EXTEND(SP, top - n + 1);
	for (i = n; i <= top; i++) {
		SV **el = av_fetch(av, i, 0);
		PUSHs(el ? *el : &PL_sv_undef);
	}
	RETURN;
}

/* @{$src}[idx .. end] as a custom op: NULL->CUSTOM over (padsv(src), const idx). */
static OP *dd_tail_op(pTHX_ PADOFFSET src, IV idx) {
	OP *o = newBINOP(OP_NULL, OPf_WANT_LIST,
	                 dd_padsv(aTHX_ src),
	                 newSVOP(OP_CONST, 0, newSViv(idx)));
	o->op_type   = OP_CUSTOM;
	o->op_ppaddr = dd_pp_tail;
	return o;
}

/* ---- hash %rest custom op --------------------------------------------------
 * A trailing `%rest` in a hash pattern binds every key of the source hashref
 * that was NOT named by an earlier element. Built as a list-shaped custom op:
 *   ( PUSHMARK, padsv(src), const key1, const key2, ... )
 * At run time the source ref is the first stack item above the mark and the
 * named keys follow; we replace them all with the surviving key => value list.
 * A non-href source yields the empty list (no warning). */
static XOP dd_hrest_xop;

static OP *dd_pp_hrest(pTHX) {
	dSP; dMARK;
	SV **items = MARK + 1;
	IV  nitems = (IV)(SP - MARK);      /* href + excluded keys */
	SV  *rv    = nitems > 0 ? items[0] : &PL_sv_undef;
	IV   nexcl = nitems > 0 ? nitems - 1 : 0;
	SV **excl  = items + 1;            /* still valid until we overwrite below */
	HV  *hv;
	HE  *he;

	if (!SvROK(rv) || SvTYPE(SvRV(rv)) != SVt_PVHV) {
		SP = MARK;                     /* not a href -> empty list */
		PUTBACK;
		return NORMAL;
	}
	hv = (HV *)SvRV(rv);

	/* Copy the excluded-key SV pointers out before we reset SP over them. */
	{
		IV i;
		SV **keep = NULL;
		Newx(keep, nexcl ? nexcl : 1, SV *);
		for (i = 0; i < nexcl; i++) keep[i] = excl[i];

		SP = MARK;                     /* drop href + excluded keys */
		EXTEND(SP, 2 * (IV)HvUSEDKEYS(hv));
		hv_iterinit(hv);
		while ((he = hv_iternext(hv))) {
			SV *k = hv_iterkeysv(he);  /* mortal */
			int skip = 0;
			for (i = 0; i < nexcl; i++) {
				if (sv_eq(k, keep[i])) { skip = 1; break; }
			}
			if (skip) continue;
			PUSHs(k);
			PUSHs(hv_iterval(hv, he));
		}
		Safefree(keep);
	}
	PUTBACK;
	return NORMAL;
}

/* Build the %rest op for hash pattern `pat`, reading from `src`, excluding the
 * keys of every non-slurpy element. */
static OP *dd_hrest_op(pTHX_ PADOFFSET src, dd_pat *pat) {
	OP *list;
	int i;
	list = op_prepend_elem(OP_LIST, newOP(OP_PUSHMARK, 0), dd_padsv(aTHX_ src));
	for (i = 0; i < pat->n; i++) {
		dd_elem *el = &pat->elems[i];
		if (el->kind == DD_SLURPY) continue;
		if (el->key)
			list = op_append_elem(OP_LIST, list,
			                      newSVOP(OP_CONST, 0, newSVsv(el->key)));
	}
	list->op_type   = OP_CUSTOM;
	list->op_ppaddr = dd_pp_hrest;
	list->op_flags |= OPf_WANT_LIST;
	return list;
}

/* ---- the parser ------------------------------------------------------------ */

static void dd_parse_pattern(pTHX_ dd_pat *pat);

/* Parse one element of an array/hash pattern into *el. `shape` says which. */
static void dd_parse_elem(pTHX_ dd_elem *el, int shape) {
	I32 c;
	el->kind = DD_SCALAR;
	el->name = NULL; el->key = NULL; el->deflt = NULL; el->nested = NULL;
	el->sigil = 0;

	lex_read_space(0);

	/* hash pattern: either a trailing %rest slurpy, or KEY => ... */
	if (shape == DD_HASH) {
		SV *key;
		c = lex_peek_unichar(0);
		if (c == '%') {                 /* %rest: remaining keys */
			char sigil;
			el->name  = dd_lex_var(aTHX_ &sigil);
			el->sigil = sigil;
			el->kind  = DD_SLURPY;
			return;
		}
		if (c == '"' || c == '\'')
			key = dd_lex_string(aTHX);
		else {
			key = dd_lex_ident(aTHX);
			if (!key) croak("let: expected a key in hash pattern");
		}
		el->key = key;
		lex_read_space(0);
		/* expect => (fat comma) */
		if (lex_peek_unichar(0) != '=' ||
		    PL_parser->bufptr[1] != '>')
			croak("let: expected '=>' after key '%" SVf "'", SVfARG(key));
		lex_read_unichar(0);   /* = */
		lex_read_unichar(0);   /* > */
		lex_read_space(0);
	}

	c = lex_peek_unichar(0);

	/* nested pattern */
	if (c == '[' || c == '{') {
		Newxz(el->nested, 1, dd_pat);
		el->kind = DD_NESTED;
		dd_parse_pattern(aTHX_ el->nested);
		return;
	}

	/* hole: `undef` (positional patterns only - a hash key with no binding
	 * makes no sense) */
	if (DD_IS_ARRAYLIKE(shape) && (c == 'u')) {
		/* peek the word `undef` */
		if (strnEQ(PL_parser->bufptr, "undef", 5)) {
			char after = PL_parser->bufptr[5];
			if (!isALNUM(after) && after != '_') {
				int i;
				for (i = 0; i < 5; i++) lex_read_unichar(0);
				el->kind = DD_HOLE;
				return;
			}
		}
	}

	/* a variable: $x (scalar, with optional default) or @rest/%rest (slurpy) */
	{
		char sigil;
		el->name = dd_lex_var(aTHX_ &sigil);
		el->sigil = sigil;
		if (sigil == '@' || sigil == '%') {
			el->kind = DD_SLURPY;
			return;
		}
		/* scalar - optional `= DEFAULT` (but not the `=>` of the next pair) */
		lex_read_space(0);
		c = lex_peek_unichar(0);
		if (c == '=' && PL_parser->bufptr[1] != '>') {
			lex_read_unichar(0);   /* = */
			lex_read_space(0);
			el->deflt = parse_termexpr(0);
		}
	}
}

/* Parse a whole [..] or {..} pattern (leading bracket at the cursor). */
static void dd_parse_pattern(pTHX_ dd_pat *pat) {
	I32 open, close;
	pat->n = 0;
	lex_read_space(0);
	open = lex_peek_unichar(0);
	if (open == '[')      { pat->shape = DD_ARRAY; close = ']'; }
	else if (open == '{') { pat->shape = DD_HASH;  close = '}'; }
	else if (open == '(') { pat->shape = DD_LIST;  close = ')'; }
	else croak("let: expected '[', '{' or '(' to open a pattern");
	lex_read_unichar(0);

	lex_read_space(0);
	if (lex_peek_unichar(0) == close) { lex_read_unichar(0); return; }

	while (1) {
		dd_elem *el;
		I32 c;
		if (pat->n >= DD_MAX_ELEMS) croak("let: too many pattern elements");
		el = &pat->elems[pat->n];
		dd_parse_elem(aTHX_ el, pat->shape);
		pat->n++;

		/* a slurpy @rest / %rest must be the final element */
		if (el->kind == DD_SLURPY) {
			lex_read_space(0);
			if (lex_peek_unichar(0) != close)
				croak("let: slurpy '%" SVf "' must be the last pattern element",
				      SVfARG(el->name));
			lex_read_unichar(0);
			return;
		}

		lex_read_space(0);
		c = lex_peek_unichar(0);
		if (c == ',') {
			lex_read_unichar(0);
			lex_read_space(0);
			if (lex_peek_unichar(0) == close) { lex_read_unichar(0); return; }
			continue;
		}
		if (c == close) { lex_read_unichar(0); return; }
		croak("let: expected ',' or '%c' in pattern", (int)close);
	}
}

/* ---- codegen ---------------------------------------------------------------
 *
 * Emit binding statements for `pat`, reading from the pad temp `src` (which
 * already holds the arrayref/hashref to destructure). Appends OP_LINESEQ
 * STATEOPs onto *seqp. `uniq` is bumped to make hidden temp names unique. */

static unsigned long dd_seq = 0;

static OP *dd_make_my(pTHX_ SV *name, OP *rhs) {
	PADOFFSET off = pad_add_name_pvn(SvPVX(name), SvCUR(name), 0, NULL, NULL);
	OP *lhs;
	/* For @/% the lvalue is a PADAV/PADHV; for $ a PADSV. */
	char sigil = SvPVX(name)[0];
	if (sigil == '@')      { lhs = newOP(OP_PADAV, 0); }
	else if (sigil == '%') { lhs = newOP(OP_PADHV, 0); }
	else                   { lhs = newOP(OP_PADSV, 0); }
	lhs->op_targ = off;
	lhs->op_private |= OPpLVAL_INTRO;   /* my */
	return newASSIGNOP(OPf_STACKED, lhs, 0, rhs);
}

/* Allocate an unnamed (user-invisible) pad temp and return its offset. */
static PADOFFSET dd_temp(pTHX) {
	char buf[64];
	int n = my_snprintf(buf, sizeof(buf), "$_Destructure_Declare_t%lu", dd_seq++);
	return pad_add_name_pvn(buf, (STRLEN)n, 0, NULL, NULL);
}

static void dd_emit(pTHX_ dd_pat *pat, PADOFFSET src, OP **seqp);

/* Build the RHS op that reads pattern element `el` (at array index `idx`)
 * from source ref `src`, applying any default. */
static OP *dd_elem_rhs(pTHX_ dd_pat *pat, dd_elem *el, IV idx, PADOFFSET src) {
	OP *get = DD_IS_ARRAYLIKE(pat->shape) ? dd_aelem(aTHX_ src, idx)
	                                      : dd_helem(aTHX_ src, el->key);
	if (el->deflt) {
		/* $src->[idx] // DEFAULT */
		get = newLOGOP(OP_DOR, 0, get, el->deflt);
		el->deflt = NULL;  /* consumed */
	}
	return get;
}

/* Slurpy RHS: the remaining contents as a list.
 *   array/list @rest : the tail elements from `idx` onward
 *   array/list %rest : the same tail, assigned as key => value pairs
 *   hash       %rest : every source key not named by an earlier element
 *   hash       @rest : meaningless (a hash has no positional tail) -> error
 */
static OP *dd_slurpy_rhs(pTHX_ dd_pat *pat, dd_elem *el, IV idx, PADOFFSET src) {
	if (pat->shape == DD_HASH) {
		if (el->sigil == '%')
			return dd_hrest_op(aTHX_ src, pat);
		croak("let: '%" SVf "' is invalid in a hash pattern (use a %%rest slurpy)",
		      SVfARG(el->name));
	}
	/* array / list: @rest or %rest both take the positional tail. */
	return dd_tail_op(aTHX_ src, idx);
}

static void dd_emit(pTHX_ dd_pat *pat, PADOFFSET src, OP **seqp) {
	int i;
	IV idx = 0;
	for (i = 0; i < pat->n; i++) {
		dd_elem *el = &pat->elems[i];
		switch (el->kind) {
		case DD_HOLE:
			idx++;
			break;
		case DD_SCALAR: {
			OP *rhs = dd_elem_rhs(aTHX_ pat, el, idx, src);
			OP *stmt = newSTATEOP(0, NULL, dd_make_my(aTHX_ el->name, rhs));
			*seqp = op_append_list(OP_LINESEQ, *seqp, stmt);
			idx++;
			break;
		}
		case DD_SLURPY: {
			OP *rhs = dd_slurpy_rhs(aTHX_ pat, el, idx, src);
			OP *stmt = newSTATEOP(0, NULL, dd_make_my(aTHX_ el->name, rhs));
			*seqp = op_append_list(OP_LINESEQ, *seqp, stmt);
			break;
		}
		case DD_NESTED: {
			/* my $tN = $src->[idx] (or ->{key});  then recurse with src=$tN */
			PADOFFSET t = dd_temp(aTHX);
			OP *get = DD_IS_ARRAYLIKE(pat->shape) ? dd_aelem(aTHX_ src, idx)
			                                      : dd_helem(aTHX_ src, el->key);
			OP *lhs = dd_padsv(aTHX_ t);
			OP *stmt;
			lhs->op_private |= OPpLVAL_INTRO;
			stmt = newSTATEOP(0, NULL, newASSIGNOP(OPf_STACKED, lhs, 0, get));
			*seqp = op_append_list(OP_LINESEQ, *seqp, stmt);
			dd_emit(aTHX_ el->nested, t, seqp);
			idx++;
			break;
		}
		}
	}
}

static void dd_free_pat(pTHX_ dd_pat *pat) {
	int i;
	for (i = 0; i < pat->n; i++) {
		dd_elem *el = &pat->elems[i];
		if (el->name) SvREFCNT_dec(el->name);
		if (el->key)  SvREFCNT_dec(el->key);
		if (el->deflt) op_free(el->deflt);
		if (el->nested) { dd_free_pat(aTHX_ el->nested); Safefree(el->nested); }
	}
}

/* ---- fast path: flat patterns lower to one native list-assignment ----------
 *
 * A flat array/list pattern - every element a plain scalar or `undef` hole,
 * with at most one trailing slurpy, and no defaults or nested patterns - is
 * exactly what a single `my (...) = ...` list-assignment expresses. Emitting
 * that one aassign (instead of a temp plus N per-element scalar assignments)
 * matches hand-written native speed. Hash patterns, defaults and nesting still
 * take the general per-element dd_emit() path. */
static int dd_is_listassign(dd_pat *pat) {
	int i;
	if (pat->shape == DD_HASH) return 0;
	for (i = 0; i < pat->n; i++) {
		dd_elem *el = &pat->elems[i];
		if (el->kind == DD_SCALAR) { if (el->deflt) return 0; }
		else if (el->kind == DD_HOLE) { /* -> undef in the LHS list */ }
		else if (el->kind == DD_SLURPY) { if (i != pat->n - 1) return 0; }
		else return 0;   /* DD_NESTED */
	}
	return 1;
}

/* Build the `my (LHS)` list: padsv/padav/padhv with OPpLVAL_INTRO, OP_UNDEF for
 * holes, the whole list flagged OPf_PARENS so newASSIGNOP makes a list assign. */
static OP *dd_listassign_lhs(pTHX_ dd_pat *pat) {
	OP *list = newLISTOP(OP_LIST, 0, NULL, NULL);
	int i;
	for (i = 0; i < pat->n; i++) {
		dd_elem *el = &pat->elems[i];
		OP *v;
		if (el->kind == DD_HOLE) {
			v = newOP(OP_UNDEF, 0);
		} else {
			PADOFFSET off = pad_add_name_pvn(SvPVX(el->name), SvCUR(el->name),
			                                 0, NULL, NULL);
			char sigil = SvPVX(el->name)[0];
			if (sigil == '@')      v = newOP(OP_PADAV, 0);
			else if (sigil == '%') v = newOP(OP_PADHV, 0);
			else                   v = newOP(OP_PADSV, 0);
			v->op_targ = off;
			v->op_private |= OPpLVAL_INTRO;
		}
		list = op_append_elem(OP_LIST, list, v);
	}
	list->op_flags |= OPf_PARENS;
	return list;
}

/* An empty arrayref `[]`, used to guard an undef array source so that, like the
 * per-element path, an undef source binds empties rather than dying on @{undef}. */
static OP *dd_empty_aref(pTHX) {
	return op_convert_list(OP_ANONLIST, OPf_SPECIAL, NULL);
}

#endif /* DD_DESTRUCTURE_H */
