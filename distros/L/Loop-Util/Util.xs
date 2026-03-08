#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseKeyword.h"

static HV *looputil_state_hv(pTHX) {
  SV *sv = get_sv("Loop::Util::_STATE", GV_ADD);
  if (!SvOK(sv) || !SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVHV) {
    HV *hv = newHV();
    sv_setsv(sv, newRV_noinc((SV *)hv));
  }
  return (HV *)SvRV(sv);
}

static PERL_CONTEXT *looputil_find_loop_cx(pTHX) {
  I32 i;
  for (i = cxstack_ix; i >= 0; i--) {
    PERL_CONTEXT *cx = &cxstack[i];
    if (CxTYPE_is_LOOP(cx))
      return cx;
  }
  return NULL;
}

static int looputil_is_loop_context(PERL_CONTEXT *cx) {
	if ( !cx ) return 0;
	if ( CxTYPE_is_LOOP(cx) ) return 1;
	return 0;
}

static int looputil_state_key_for_cx(PERL_CONTEXT *cx, char prefix, char *kbuf, Size_t kbuf_sz) {
	UV key;

	if ( !cx ) return 0;

	key = PTR2UV(cx);
	return (int)my_snprintf(kbuf, kbuf_sz, "%c%" UVuf, prefix, key);
}

static void looputil_delete_state_for_cx(pTHX_ PERL_CONTEXT *cx) {
	HV *hv;
	char kbuf[64];
	int klen;

	if ( !cx ) return;

	hv = looputil_state_hv(aTHX);

	klen = looputil_state_key_for_cx(cx, 'I', kbuf, sizeof(kbuf));
	(void)hv_delete(hv, kbuf, klen, G_DISCARD);

	klen = looputil_state_key_for_cx(cx, 'F', kbuf, sizeof(kbuf));
	(void)hv_delete(hv, kbuf, klen, G_DISCARD);

	klen = looputil_state_key_for_cx(cx, 'L', kbuf, sizeof(kbuf));
	(void)hv_delete(hv, kbuf, klen, G_DISCARD);
}

static void looputil_set_state_iv_for_cx(pTHX_ PERL_CONTEXT *cx, char prefix, IV value) {
	HV *hv;
	char kbuf[64];
	int klen;

	if ( !cx ) return;

	hv = looputil_state_hv(aTHX);
	klen = looputil_state_key_for_cx(cx, prefix, kbuf, sizeof(kbuf));
	(void)hv_store(hv, kbuf, klen, newSViv(value), 0);
}

static int looputil_get_state_iv_for_cx(pTHX_ PERL_CONTEXT *cx, char prefix, IV *out) {
	HV *hv;
	char kbuf[64];
	int klen;
	SV **svp;

	if ( !cx ) return 0;

	hv = looputil_state_hv(aTHX);
	klen = looputil_state_key_for_cx(cx, prefix, kbuf, sizeof(kbuf));
	svp = hv_fetch(hv, kbuf, klen, 0);
	if ( !svp || !*svp ) return 0;

	*out = SvIV(*svp);
	return 1;
}

static void looputil_set_iteration_for_cx(pTHX_ PERL_CONTEXT *cx, IV iteration) {
	looputil_set_state_iv_for_cx(aTHX_ cx, 'I', iteration);
}

static int looputil_get_iteration_for_cx(pTHX_ PERL_CONTEXT *cx, IV *out) {
	return looputil_get_state_iv_for_cx(aTHX_ cx, 'I', out);
}

static void looputil_set_loopkind_for_cx(pTHX_ PERL_CONTEXT *cx, int is_finite, IV length) {
	if ( !cx ) return;

	looputil_set_state_iv_for_cx(aTHX_ cx, 'F', is_finite ? 1 : 0);
	if ( is_finite ) {
		looputil_set_state_iv_for_cx(aTHX_ cx, 'L', length);
	}
	else {
		HV *hv = looputil_state_hv(aTHX);
		char kbuf[64];
		int klen = looputil_state_key_for_cx(cx, 'L', kbuf, sizeof(kbuf));
		(void)hv_delete(hv, kbuf, klen, G_DISCARD);
	}
}

static int looputil_get_loopkind_for_cx(pTHX_ PERL_CONTEXT *cx, int *is_finite, IV *length) {
	IV finite_iv;

	if ( !looputil_get_state_iv_for_cx(aTHX_ cx, 'F', &finite_iv) ) return 0;

	*is_finite = finite_iv ? 1 : 0;
	if ( *is_finite ) {
		if ( !looputil_get_state_iv_for_cx(aTHX_ cx, 'L', length) ) {
			*length = 0;
		}
	}
	else {
		*length = 0;
	}

	return 1;
}

static int looputil_iteration_index_for_cx(pTHX_ PERL_CONTEXT *cx, IV *out) {

	U8 t;
	U8 flags;

	if ( !cx ) return 0;

	t = CxTYPE(cx);
	flags = (U8)(cx->cx_type & ( CXp_FOR_GV | CXp_FOR_PAD ));

	if ( !flags ) return 0;

	if ( t == CXt_LOOP_ARY ) {
		*out = cx->blk_loop.state_u.ary.ix;
		return 1;
	}

	if ( t == CXt_LOOP_LIST ) {
		*out = cx->blk_loop.state_u.stack.ix - 1;
		return 1;
	}

	if ( t == CXt_LOOP_LAZYIV ) {
		*out = cx->blk_loop.state_u.lazyiv.cur;
		return 1;
	}

	return 0;
}


static PERL_CONTEXT *looputil_find_labeled_loop_cx(pTHX_ SV *wanted_label) {
	I32 ix;
	I32 current_ix = -1;
	STRLEN wanted_len;
	const char *wanted = SvPV(wanted_label, wanted_len);

	for ( ix = cxstack_ix; ix >= 0; ix-- ) {
		PERL_CONTEXT *cur = &cxstack[ix];
		STRLEN label_len = 0;
		const char *label;

		if ( !looputil_is_loop_context(cur) ) continue;
		if ( current_ix < 0 ) current_ix = ix;
		if ( !cur->blk_oldcop ) continue;

		label = CxLABEL_len(cur, &label_len);
		if ( label && label_len == wanted_len && memEQ(label, wanted, wanted_len) ) {
			return cur;
		}
	}

	if ( current_ix >= 0 && wanted_len == 5 && memEQ(wanted, "OUTER", 5) ) {
		for ( ix = current_ix + 1; ix <= cxstack_ix; ix++ ) {
			PERL_CONTEXT *cur = &cxstack[ix];
			IV tmp = -1;

			if ( !looputil_is_loop_context(cur) ) continue;
			if ( looputil_iteration_index_for_cx(aTHX_ cur, &tmp) ) return cur;
			if ( looputil_get_iteration_for_cx(aTHX_ cur, &tmp) ) return cur;
		}

		for ( ix = current_ix - 1; ix >= 0; ix-- ) {
			PERL_CONTEXT *cur = &cxstack[ix];
			IV tmp = -1;

			if ( !looputil_is_loop_context(cur) ) continue;
			if ( looputil_iteration_index_for_cx(aTHX_ cur, &tmp) ) return cur;
			if ( looputil_get_iteration_for_cx(aTHX_ cur, &tmp) ) return cur;
		}
	}

	croak("could not find loop label '%" SVf "'", SVfARG(wanted_label));
}

static int looputil_resolve_iteration_for_cx(pTHX_ PERL_CONTEXT *cx, IV *out) {
	if ( looputil_iteration_index_for_cx(aTHX_ cx, out) ) return 1;
	if ( looputil_get_iteration_for_cx(aTHX_ cx, out) ) return 1;
	return 0;
}

static bool looputil_consume_word(pTHX_ const char *w) {
  const char *s;
  STRLEN n;

  if (!(PL_parser && PL_parser->bufptr)) return FALSE;

  lex_read_space(0);
  if (!(PL_parser && PL_parser->bufptr)) return FALSE;

  s = PL_parser->bufptr;

  n = (STRLEN)strlen(w);
  if (!(strnEQ(s, w, n) && !isWORDCHAR(s[n]))) return FALSE;

  (void)lex_read_to((char *)s + (I32)n);
  return TRUE;
}

static SV *looputil_parse_optional_label(pTHX) {
	const char *s;
	const char *p;

	lex_read_space(0);
	if ( !( PL_parser && PL_parser->bufptr ) ) return NULL;

	s = PL_parser->bufptr;
	if ( !isIDFIRST(*s) ) return NULL;

	p = s + 1;
	while ( isWORDCHAR(*p) ) p++;

	(void)lex_read_to((char *)p);
	lex_read_space(0);
	if ( !( PL_parser && PL_parser->bufptr ) ) return NULL;
	if ( *PL_parser->bufptr != '{' ) return NULL;

	return newSVpvn(s, (STRLEN)(p - s));
}

static OP *looputil_new_call_0(pTHX_ const char *name) {
  GV *gv = gv_fetchpv(name, GV_ADD, SVt_PVCV);
  OP *cv = newGVOP(OP_GV, 0, gv);
  OP *args = newOP(OP_NULL, 0);
  return newUNOP(OP_ENTERSUB, OPf_STACKED, op_append_elem(OP_LIST, args, cv));
}


static OP *looputil_new_call_1_sv(pTHX_ const char *name, SV *arg_sv) {
	GV *gv = gv_fetchpv(name, GV_ADD, SVt_PVCV);
	OP *cv = newGVOP(OP_GV, 0, gv);
	OP *arg = newSVOP(OP_CONST, 0, arg_sv);
	OP *args = op_append_elem(OP_LIST, newOP(OP_NULL, 0), arg);
	return newUNOP(OP_ENTERSUB, OPf_STACKED, op_append_elem(OP_LIST, args, cv));
}

static OP *looputil_wrap_if(pTHX_ const char *pred_pv, OP *thenop, OP *elseop) {
  OP *cond = looputil_new_call_0(aTHX_ pred_pv);

  if (!elseop) return newCONDOP(0, cond, thenop, newOP(OP_NULL, 0));
  return newCONDOP(0, cond, thenop, elseop);
}

static int looputil_kw_iffirst(pTHX_ OP **op_ptr, void *hookdata) {
  (void)hookdata;

	SV *label = looputil_parse_optional_label(aTHX);
  OP *thenop = parse_block(0);
  OP *elseop = NULL;
  OP *cond;

  if ( looputil_consume_word(aTHX_ "else") ) {
    elseop = parse_block(0);
  }

	if ( label ) {
		cond = looputil_new_call_1_sv(aTHX_ "Loop::Util::_looputil_is_first_label", label);
	}
	else {
		cond = looputil_new_call_0(aTHX_ "Loop::Util::_looputil_is_first");
	}

  if ( !elseop ) {
		*op_ptr = newCONDOP(0, cond, thenop, newOP(OP_NULL, 0));
	}
	else {
		*op_ptr = newCONDOP(0, cond, thenop, elseop);
	}
  return KEYWORD_PLUGIN_STMT;
}

static int looputil_kw_iflast(pTHX_ OP **op_ptr, void *hookdata) {
  (void)hookdata;

	SV *label = looputil_parse_optional_label(aTHX);
  OP *thenop = parse_block(0);
  OP *elseop = NULL;
  OP *cond;

  if ( looputil_consume_word(aTHX_ "else") ) {
    elseop = parse_block(0);
  }

	if ( label ) {
		cond = looputil_new_call_1_sv(aTHX_ "Loop::Util::_looputil_is_last_label", label);
	}
	else {
		cond = looputil_new_call_0(aTHX_ "Loop::Util::_looputil_is_last");
	}

  if ( !elseop ) {
		*op_ptr = newCONDOP(0, cond, thenop, newOP(OP_NULL, 0));
	}
	else {
		*op_ptr = newCONDOP(0, cond, thenop, elseop);
	}
  return KEYWORD_PLUGIN_STMT;
}

static int looputil_kw_ifodd(pTHX_ OP **op_ptr, void *hookdata) {
  (void)hookdata;

	SV *label = looputil_parse_optional_label(aTHX);
  OP *thenop = parse_block(0);
  OP *elseop = NULL;
  OP *cond;

  if ( looputil_consume_word(aTHX_ "else") ) {
    elseop = parse_block(0);
  }

	if ( label ) {
		cond = looputil_new_call_1_sv(aTHX_ "Loop::Util::_looputil_is_odd_label", label);
	}
	else {
		cond = looputil_new_call_0(aTHX_ "Loop::Util::_looputil_is_odd");
	}

  if ( !elseop ) {
		*op_ptr = newCONDOP(0, cond, thenop, newOP(OP_NULL, 0));
	}
	else {
		*op_ptr = newCONDOP(0, cond, thenop, elseop);
	}
  return KEYWORD_PLUGIN_STMT;
}

static int looputil_kw_ifeven(pTHX_ OP **op_ptr, void *hookdata) {
  (void)hookdata;

	SV *label = looputil_parse_optional_label(aTHX);
  OP *thenop = parse_block(0);
  OP *elseop = NULL;
  OP *cond;

  if ( looputil_consume_word(aTHX_ "else") ) {
    elseop = parse_block(0);
  }

	if ( label ) {
		cond = looputil_new_call_1_sv(aTHX_ "Loop::Util::_looputil_is_even_label", label);
	}
	else {
		cond = looputil_new_call_0(aTHX_ "Loop::Util::_looputil_is_even");
	}

  if ( !elseop ) {
		*op_ptr = newCONDOP(0, cond, thenop, newOP(OP_NULL, 0));
	}
	else {
		*op_ptr = newCONDOP(0, cond, thenop, elseop);
	}
  return KEYWORD_PLUGIN_STMT;
}

static int looputil_kw_ix(pTHX_ OP **op_ptr, void *hookdata) {
	(void)hookdata;

	*op_ptr = looputil_new_call_0(aTHX_ "Loop::Util::_looputil_ix");
	return KEYWORD_PLUGIN_EXPR;
}

static int looputil_parse_parenthesized_text(pTHX_ SV *out) {
	const char *s;
	const char *p;
	int depth = 0;

	lex_read_space(0);
	if ( !( PL_parser && PL_parser->bufptr ) ) return 0;

	s = PL_parser->bufptr;
	if ( *s != '(' ) return 0;

	p = s;
	while ( *p ) {
		if ( *p == '\\' ) {
			if ( p[1] ) p += 2;
			else p++;
			continue;
		}

		if ( *p == '\'' || *p == '"' ) {
			char q = *p++;
			while ( *p ) {
				if ( *p == '\\' && p[1] ) {
					p += 2;
					continue;
				}
				if ( *p == q ) {
					p++;
					break;
				}
				p++;
			}
			continue;
		}

		if ( *p == '(' ) depth++;
		else if ( *p == ')' ) {
			depth--;
			if ( depth == 0 ) {
				sv_setpvn(out, s + 1, (STRLEN)(p - s - 1));
				(void)lex_read_to((char *)p + 1);
				return 1;
			}
		}

		p++;
	}

	croak("loop count expression is missing closing ')' ");
}


static int looputil_parse_statement_text(pTHX_ SV *out) {
	const char *start;
	const char *cursor;
	OP *expr;

	lex_read_space(0);
	if ( !( PL_parser && PL_parser->bufptr ) ) return 0;

	start = PL_parser->bufptr;
	expr = parse_fullexpr(0);
	if ( !expr ) return 0;
	op_free(expr);

	lex_read_space(0);
	if ( !( PL_parser && PL_parser->bufptr ) ) return 0;
	cursor = PL_parser->bufptr;

	if ( cursor < start ) {
		STRLEN len = strlen(start);
		if ( len == 0 ) return 0;
		sv_setpvn(out, start, len);
		return 1;
	}

	if ( *cursor == ';' ) {
		sv_setpvn(out, start, (STRLEN)(cursor - start + 1));
		(void)lex_read_to((char *)cursor + 1);
		return 1;
	}

	if ( *cursor == '\0' ) {
		sv_setpvn(out, start, (STRLEN)(cursor - start));
		return 1;
	}

	return 0;
}

static int looputil_kw_loop(pTHX_ OP **op_ptr, void *hookdata) {
	(void)hookdata;


	SV *count_expr = newSVpvs("");
	SV *rewrite = newSVpvs("");

	lex_read_space(0);

	if ( PL_parser && PL_parser->bufptr && *PL_parser->bufptr == '(' ) {
		if ( !looputil_parse_parenthesized_text(aTHX_ count_expr) ) {
			SvREFCNT_dec(count_expr);
			SvREFCNT_dec(rewrite);
			croak("loop count requires parentheses");
		}

		sv_catpv(rewrite,
			"for ( local $Loop::Util::LOOPKIND = 'finite', "
			"local $Loop::Util::LENGTH = (");
		sv_catsv(rewrite, count_expr);
		sv_catpv(rewrite,
			"), local $Loop::Util::ITERATION = 0; "
			"( Loop::Util::_looputil_mark_iteration(), "
			"$Loop::Util::ITERATION < $Loop::Util::LENGTH ); "
			"$Loop::Util::ITERATION++ ) ");
	}
	else {
		sv_catpv(rewrite,
			"for ( local $Loop::Util::LOOPKIND = 'infinite', "
			"local $Loop::Util::LENGTH = undef, "
			"local $Loop::Util::ITERATION = 0; "
			"( Loop::Util::_looputil_mark_iteration(), 1 ); "
			"$Loop::Util::ITERATION++ ) ");
	}

	lex_read_space(0);
	if ( PL_parser && PL_parser->bufptr && *PL_parser->bufptr != '{' ) {
		SV *stmt_expr = newSVpvs("");
		if ( !looputil_parse_statement_text(aTHX_ stmt_expr) ) {
			SvREFCNT_dec(count_expr);
			SvREFCNT_dec(rewrite);
			SvREFCNT_dec(stmt_expr);
			croak("loop single-statement form requires trailing ';'");
		}
		sv_catpv(rewrite, "{ ");
		sv_catsv(rewrite, stmt_expr);
		sv_catpv(rewrite, " }");
		SvREFCNT_dec(stmt_expr);
	}

	lex_stuff_sv(rewrite, 0);
	*op_ptr = parse_fullstmt(0);

	SvREFCNT_dec(count_expr);
	SvREFCNT_dec(rewrite);

	return KEYWORD_PLUGIN_STMT;
}

MODULE = Loop::Util  PACKAGE = Loop::Util

PROTOTYPES: DISABLE

void
_looputil_mark_iteration()
  CODE:
    PERL_CONTEXT *cx = looputil_find_loop_cx(aTHX);
    SV *iter_sv = get_sv("Loop::Util::ITERATION", 0);
    SV *kind_sv = get_sv("Loop::Util::LOOPKIND", 0);
    SV *len_sv = get_sv("Loop::Util::LENGTH", 0);

    if ( cx && iter_sv && SvOK(iter_sv) ) {
      looputil_set_iteration_for_cx(aTHX_ cx, SvIV(iter_sv));
    }

    if ( cx && kind_sv && SvOK(kind_sv) ) {
      STRLEN klen;
      const char *kind = SvPV(kind_sv, klen);

      if ( strEQ(kind, "finite") ) {
        IV n = ( len_sv && SvOK(len_sv) ) ? SvIV(len_sv) : 0;
        looputil_set_loopkind_for_cx(aTHX_ cx, 1, n);
      }
      else if ( strEQ(kind, "infinite") ) {
        looputil_set_loopkind_for_cx(aTHX_ cx, 0, 0);
      }
    }

bool
_looputil_is_first()
  CODE:
    PERL_CONTEXT *cx = looputil_find_loop_cx(aTHX);
    SV *kind_sv = get_sv("Loop::Util::LOOPKIND", 0);
    SV *iter_sv = get_sv("Loop::Util::ITERATION", 0);
    IV i = -1;

    if ( kind_sv && SvOK(kind_sv) && iter_sv && SvOK(iter_sv) ) {
      RETVAL = ( SvIV(iter_sv) == 0 );
    }
    else if ( looputil_iteration_index_for_cx(aTHX_ cx, &i) ) RETVAL = ( i == 0 );
    else croak("iffirst only works in for/foreach loops over arrays or lists");
  OUTPUT:
    RETVAL

bool
_looputil_is_first_label(wanted_label)
  SV *wanted_label
  CODE:
    PERL_CONTEXT *found = looputil_find_labeled_loop_cx(aTHX_ wanted_label);
    IV i = -1;

    if ( looputil_resolve_iteration_for_cx(aTHX_ found, &i) ) RETVAL = ( i == 0 );
    else croak("iffirst with label only works in loop/for contexts with iteration indices");
  OUTPUT:
    RETVAL

bool
_looputil_is_last_label(wanted_label)
  SV *wanted_label
  CODE:
    PERL_CONTEXT *found = looputil_find_labeled_loop_cx(aTHX_ wanted_label);
    U8 t = CxTYPE(found);
    int is_finite = 0;
    IV length = 0;

    RETVAL = 0;

    if ( t == CXt_LOOP_ARY ) {
      AV *ary = found->blk_loop.state_u.ary.ary;
      IV ix = found->blk_loop.state_u.ary.ix;
      if ( ary ) {
        IV lastix = (IV)av_len(ary);
        RETVAL = ( ix >= lastix );
      }
    }
    else if ( t == CXt_LOOP_LIST ) {
      SSize_t basesp = found->blk_loop.state_u.stack.basesp;
      IV ix = found->blk_loop.state_u.stack.ix;
      SV **base = PL_stack_base + basesp;
      SV **top = PL_stack_sp;

      if ( top >= base ) {
        IV total = (IV)(top - base + 1);
        RETVAL = ( ix >= ( total - 1 ) );
      }
    }
    else if ( t == CXt_LOOP_LAZYIV ) {
      IV cur = found->blk_loop.state_u.lazyiv.cur;
      IV end = found->blk_loop.state_u.lazyiv.end;
      RETVAL = ( cur == end );
    }
    else if ( t == CXt_LOOP_LAZYSV ) {
      SV *cur = found->blk_loop.state_u.lazysv.cur;
      SV *end = found->blk_loop.state_u.lazysv.end;
      RETVAL = ( cur && end && sv_cmp(cur, end) == 0 );
    }
    else if ( looputil_get_loopkind_for_cx(aTHX_ found, &is_finite, &length) ) {
      IV i = -1;
      if ( !is_finite ) {
        croak("iflast called outside for loop");
      }
      if ( !looputil_get_iteration_for_cx(aTHX_ found, &i) ) {
        croak("iflast with label only works in loop/for contexts with iteration indices");
      }
      RETVAL = ( length > 0 && i >= ( length - 1 ) );
    }
    else {
      croak("iflast with label only works in loop/for contexts");
    }

    if ( RETVAL ) {
      looputil_delete_state_for_cx(aTHX_ found);
    }
  OUTPUT:
    RETVAL

bool
_looputil_is_odd_label(wanted_label)
  SV *wanted_label
  CODE:
    PERL_CONTEXT *found = looputil_find_labeled_loop_cx(aTHX_ wanted_label);
    IV i = -1;

    if ( looputil_resolve_iteration_for_cx(aTHX_ found, &i) ) RETVAL = ( ( i % 2 ) == 0 );
    else croak("ifodd with label only works in loop/for contexts with iteration indices");
  OUTPUT:
    RETVAL

bool
_looputil_is_even_label(wanted_label)
  SV *wanted_label
  CODE:
    PERL_CONTEXT *found = looputil_find_labeled_loop_cx(aTHX_ wanted_label);
    IV i = -1;

    if ( looputil_resolve_iteration_for_cx(aTHX_ found, &i) ) RETVAL = ( ( i % 2 ) != 0 );
    else croak("ifeven with label only works in loop/for contexts with iteration indices");
  OUTPUT:
    RETVAL

bool
_looputil_is_last()
  CODE:
    PERL_CONTEXT *cx = looputil_find_loop_cx(aTHX);
    SV *kind_sv = get_sv("Loop::Util::LOOPKIND", 0);
    SV *len_sv  = get_sv("Loop::Util::LENGTH", 0);
    SV *iter_sv = get_sv("Loop::Util::ITERATION", 0);

    if ( kind_sv && SvOK(kind_sv) ) {
      STRLEN klen;
      const char *kind = SvPV(kind_sv, klen);

      if ( strEQ(kind, "infinite") ) {
        croak("iflast called outside for loop");
      }

      if ( strEQ(kind, "finite") ) {
        IV i = ( iter_sv && SvOK(iter_sv) ) ? SvIV(iter_sv) : 0;
        IV n = ( len_sv && SvOK(len_sv) ) ? SvIV(len_sv) : 0;
        RETVAL = n > 0 && i >= ( n - 1 );
      }
      else {
        croak("iflast called outside for loop");
      }
    }
    else if (!cx) { croak("iflast called outside for loop"); }
    else {
      /*
        Determine "last" for foreach-style loops by inspecting cx->blk_loop state.
        We accept:
          CXt_LOOP_ARY    : for (@ary)
          CXt_LOOP_LIST   : for (list)      (best-effort via stack size)
          CXt_LOOP_LAZYIV : for (1..9)
          CXt_LOOP_LAZYSV : for ('a'..'z')
        Other loop kinds => false.
      */
      U8 t = CxTYPE(cx);
      RETVAL = 0;

      if (t == CXt_LOOP_ARY) {
        AV *ary = cx->blk_loop.state_u.ary.ary;
        IV ix   = cx->blk_loop.state_u.ary.ix;
        if (ary) {
          IV lastix = (IV)av_len(ary);
          if (ix >= lastix) RETVAL = 1;
        }
      }
      else if (t == CXt_LOOP_LIST) {
        SSize_t basesp = cx->blk_loop.state_u.stack.basesp;
        IV ix         = cx->blk_loop.state_u.stack.ix;

        SV **base = PL_stack_base + basesp;
        SV **top  = PL_stack_sp;

        if (top >= base) {
          IV total = (IV)(top - base + 1);
          if (ix >= (total - 1)) RETVAL = 1;
        }
      }
      else if (t == CXt_LOOP_LAZYIV) {
        IV cur = cx->blk_loop.state_u.lazyiv.cur;
        IV end = cx->blk_loop.state_u.lazyiv.end;
        if (cur == end) RETVAL = 1;
      }
      else if (t == CXt_LOOP_LAZYSV) {
        SV *cur = cx->blk_loop.state_u.lazysv.cur;
        SV *end = cx->blk_loop.state_u.lazysv.end;
        if (cur && end && sv_cmp(cur, end) == 0) RETVAL = 1;
      }

      if (RETVAL) {
        /* cleanup state on last iteration to avoid unbounded growth */
        looputil_delete_state_for_cx(aTHX_ cx);
      }
      else {
        if ( t != CXt_LOOP_ARY && t != CXt_LOOP_LIST &&
             t != CXt_LOOP_LAZYIV && t != CXt_LOOP_LAZYSV ) {
          croak("iflast called outside for loop");
        }
      }
    }
  OUTPUT:
    RETVAL

bool
_looputil_is_odd()
  CODE:
    PERL_CONTEXT *cx = looputil_find_loop_cx(aTHX);
    SV *kind_sv = get_sv("Loop::Util::LOOPKIND", 0);
    SV *iter_sv = get_sv("Loop::Util::ITERATION", 0);
    IV i = -1;

    if ( kind_sv && SvOK(kind_sv) && iter_sv && SvOK(iter_sv) ) {
      RETVAL = ( ( SvIV(iter_sv) % 2 ) == 0 );
    }
    else if ( looputil_iteration_index_for_cx(aTHX_ cx, &i) ) RETVAL = ( ( i % 2 ) == 0 );
    else croak("ifodd only works in for/foreach loops over arrays or lists");
  OUTPUT:
    RETVAL

bool
_looputil_is_even()
  CODE:
    PERL_CONTEXT *cx = looputil_find_loop_cx(aTHX);
    SV *kind_sv = get_sv("Loop::Util::LOOPKIND", 0);
    SV *iter_sv = get_sv("Loop::Util::ITERATION", 0);
    IV i = -1;

    if ( kind_sv && SvOK(kind_sv) && iter_sv && SvOK(iter_sv) ) {
      RETVAL = ( ( SvIV(iter_sv) % 2 ) != 0 );
    }
    else if ( looputil_iteration_index_for_cx(aTHX_ cx, &i) ) RETVAL = ( ( i % 2 ) != 0 );
    else croak("ifeven only works in for/foreach loops over arrays or lists");
  OUTPUT:
    RETVAL

SV *
_looputil_ix()
  CODE:
	PERL_CONTEXT *cx = looputil_find_loop_cx(aTHX);
	SV *kind_sv = get_sv("Loop::Util::LOOPKIND", 0);
	SV *iter_sv = get_sv("Loop::Util::ITERATION", 0);
	IV i = -1;
	U8 t = cx ? CxTYPE(cx) : 0;

	if ( kind_sv && SvOK(kind_sv) && iter_sv && SvOK(iter_sv) && t == CXt_LOOP_PLAIN ) {
		RETVAL = newSViv(SvIV(iter_sv));
	}
	else if ( looputil_iteration_index_for_cx(aTHX_ cx, &i) ) {
		RETVAL = newSViv(i);
	}
	else {
		RETVAL = &PL_sv_undef;
	}
  OUTPUT:
	RETVAL

BOOT:
  /*
    iffirst/iflast are statement keywords.
  */
  static struct XSParseKeywordHooks iffirst_hooks;
  static struct XSParseKeywordHooks iflast_hooks;
  static struct XSParseKeywordHooks ifodd_hooks;
  static struct XSParseKeywordHooks ifeven_hooks;
  static struct XSParseKeywordHooks loop_hooks;
  static struct XSParseKeywordHooks ix_hooks;

  iffirst_hooks.flags = XPK_FLAG_STMT | XPK_FLAG_PERMIT_LEXICAL;
  iffirst_hooks.permit_hintkey = "Loop::Util/iffirst";
  iffirst_hooks.parse = looputil_kw_iffirst;

  iflast_hooks.flags = XPK_FLAG_STMT | XPK_FLAG_PERMIT_LEXICAL;
  iflast_hooks.permit_hintkey = "Loop::Util/iflast";
  iflast_hooks.parse = looputil_kw_iflast;

  ifodd_hooks.flags = XPK_FLAG_STMT | XPK_FLAG_PERMIT_LEXICAL;
  ifodd_hooks.permit_hintkey = "Loop::Util/ifodd";
  ifodd_hooks.parse = looputil_kw_ifodd;

  ifeven_hooks.flags = XPK_FLAG_STMT | XPK_FLAG_PERMIT_LEXICAL;
  ifeven_hooks.permit_hintkey = "Loop::Util/ifeven";
  ifeven_hooks.parse = looputil_kw_ifeven;

  loop_hooks.flags = XPK_FLAG_STMT | XPK_FLAG_PERMIT_LEXICAL;
  loop_hooks.permit_hintkey = "Loop::Util/loop";
  loop_hooks.parse = looputil_kw_loop;

  ix_hooks.flags = XPK_FLAG_EXPR | XPK_FLAG_PERMIT_LEXICAL;
  ix_hooks.permit_hintkey = "Loop::Util/__IX__";
  ix_hooks.parse = looputil_kw_ix;

  boot_xs_parse_keyword(0);
  register_xs_parse_keyword("iffirst", &iffirst_hooks, NULL);
  register_xs_parse_keyword("iflast", &iflast_hooks, NULL);
  register_xs_parse_keyword("ifodd", &ifodd_hooks, NULL);
  register_xs_parse_keyword("ifeven", &ifeven_hooks, NULL);
  register_xs_parse_keyword("loop", &loop_hooks, NULL);
  register_xs_parse_keyword("__IX__", &ix_hooks, NULL);
