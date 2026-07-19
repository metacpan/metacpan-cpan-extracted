/*
 * Parser-internal AST runtime layer only.
 *
 * Responsibility: parser AST helpers for lazy arrays,
 * location context management, and token-driven AST node location assignment.
 *
 * This header is not part of the runtime/VM mainline. It exists only because
 * the public parser surface still returns graphql-perl-compatible AST while
 * some parser internals continue to use parser-shaped node helpers.
 */
static HV *
gql_parser_node_hv(SV *node_sv) {
  if (!node_sv || !SvROK(node_sv) || SvTYPE(SvRV(node_sv)) != SVt_PVHV) {
    return NULL;
  }
  return (HV *)SvRV(node_sv);
}

static SV *
gql_parser_fetch_sv(HV *hv, const char *key) {
  SV **svp;
  if (!hv) {
    return NULL;
  }
  svp = hv_fetch(hv, key, (I32)strlen(key), 0);
  return svp ? *svp : NULL;
}

static AV *
gql_parser_fetch_array(HV *hv, const char *key) {
  SV *sv = gql_parser_fetch_sv(hv, key);
  AV *av;
  MAGIC *mg;
  if (!sv || !SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVAV) {
    return NULL;
  }
  av = (AV *)SvRV(sv);
  mg = mg_find((SV *)av, PERL_MAGIC_tied);
  if (mg && mg->mg_obj) {
    HV *tied_hv = NULL;
    SV *data_sv = NULL;
    SV *state_sv = NULL;
    SV *ptr_sv = NULL;
    SV *kind_sv = NULL;

    if (SvROK(mg->mg_obj) && SvTYPE(SvRV(mg->mg_obj)) == SVt_PVHV) {
      tied_hv = (HV *)SvRV(mg->mg_obj);
      /* These hash keys are part of the XS fast-path contract with
       * GraphQL::Houtou::XS::LazyArray::*::TIEARRAY. Keep tests in sync if
       * they ever change. */
      data_sv = gql_parser_fetch_sv(tied_hv, "data");
      if (data_sv && SvROK(data_sv) && SvTYPE(SvRV(data_sv)) == SVt_PVAV) {
        return (AV *)SvRV(data_sv);
      }
      state_sv = gql_parser_fetch_sv(tied_hv, "state");
      ptr_sv = gql_parser_fetch_sv(tied_hv, "ptr");
      kind_sv = gql_parser_fetch_sv(tied_hv, "kind");
      if (state_sv && ptr_sv && kind_sv && SvIOK(ptr_sv) && SvIOK(kind_sv)) {
        AV *materialized_av = gql_parser_materialize_lazy_array(aTHX_ state_sv, SvUV(ptr_sv), SvIV(kind_sv));
        hv_stores(tied_hv, "data", newRV_noinc((SV *)materialized_av));
        return materialized_av;
      }
    }
    {
      dSP;
      SV *materialized_sv;

      ENTER;
      SAVETMPS;
      PUSHMARK(SP);
      XPUSHs(sv_2mortal(newSVsv(mg->mg_obj)));
      PUTBACK;
      call_method("_materialize", G_SCALAR);
      SPAGAIN;
      materialized_sv = newSVsv(POPs);
      PUTBACK;
      FREETMPS;
      LEAVE;

      if (!materialized_sv || !SvROK(materialized_sv) || SvTYPE(SvRV(materialized_sv)) != SVt_PVAV) {
        SvREFCNT_dec(materialized_sv);
        croak("parser lazy array materialization returned a non-array reference");
      }
      av = (AV *)SvRV(materialized_sv);
      SvREFCNT_dec(materialized_sv);
    }
  }
  return av;
}

static const char *
gql_parser_fetch_kind(HV *hv) {
  SV *sv = gql_parser_fetch_sv(hv, "kind");
  STRLEN len;
  if (!sv) {
    return NULL;
  }
  return SvPV(sv, len);
}

static const char *
gql_parser_name_value(SV *node_sv) {
  HV *hv = gql_parser_node_hv(node_sv);
  HV *name_hv;
  SV *value_sv;
  STRLEN len;

  if (!hv) {
    return NULL;
  }

  value_sv = gql_parser_fetch_sv(hv, "value");
  if (value_sv && !SvROK(value_sv)) {
    return SvPV(value_sv, len);
  }

  value_sv = gql_parser_fetch_sv(hv, "name");
  if (value_sv && SvROK(value_sv) && SvTYPE(SvRV(value_sv)) == SVt_PVHV) {
    name_hv = (HV *)SvRV(value_sv);
    value_sv = gql_parser_fetch_sv(name_hv, "value");
    if (value_sv) {
      return SvPV(value_sv, len);
    }
  }

  return NULL;
}

static SV *
gql_parser_find_named_node(AV *av, const char *name) {
  I32 i;
  if (!av || !name) {
    return NULL;
  }
  for (i = 0; i <= av_len(av); i++) {
    SV **svp = av_fetch(av, i, 0);
    const char *node_name;
    if (!svp) {
      continue;
    }
    node_name = gql_parser_name_value(*svp);
    if (node_name && strcmp(node_name, name) == 0) {
      return *svp;
    }
  }
  return NULL;
}

static SV *
gql_parser_find_named_node_sv(AV *av, SV *name_sv) {
  STRLEN len;
  const char *name;

  if (!name_sv) {
    return NULL;
  }
  name = SvPV(name_sv, len);
  return gql_parser_find_named_node(av, name);
}

static SV *
gql_parser_new_loc_sv(pTHX_ IV line, IV column) {
  HV *loc_hv = newHV();
  hv_ksplit(loc_hv, 2);
  hv_stores(loc_hv, "line", newSViv(line));
  hv_stores(loc_hv, "column", newSViv(column));
  return newRV_noinc((SV *)loc_hv);
}

static SV *
gql_parser_new_lazy_loc_sv(pTHX_ UV start) {
  AV *loc_av = newAV();
  HV *stash = gv_stashpv("GraphQL::Houtou::Parser::Internal::LazyLoc", GV_ADD);
  SV *loc_sv;

  av_push(loc_av, newSVuv(start));
  loc_sv = newRV_noinc((SV *)loc_av);
  return sv_bless(loc_sv, stash);
}

static int
gql_parser_magic_free_state(pTHX_ SV *sv, MAGIC *mg) {
  SV *state_sv = mg && mg->mg_ptr ? (SV *)mg->mg_ptr : NULL;

  if (state_sv) {
    SvREFCNT_dec(state_sv);
    mg->mg_ptr = NULL;
  }
  return 0;
}

static MGVTBL gql_parser_lazy_state_vtbl = {
  NULL,
  NULL,
  NULL,
  NULL,
  gql_parser_magic_free_state
#if PERL_VERSION_GE(5, 15, 0)
  ,NULL
  ,NULL
  ,NULL
#endif
};

static void
gql_parser_lazy_state_destroy(gql_parser_lazy_state_t *state) {
  if (!state) {
    return;
  }
  if (state->source_sv) {
    SvREFCNT_dec(state->source_sv);
    state->source_sv = NULL;
  }
  if (state->has_ctx) {
    gql_parser_loc_context_destroy(&state->ctx);
    state->has_ctx = 0;
  }
  if (state->document) {
    gql_ir_free_document(state->document);
    state->document = NULL;
  }
  Safefree(state);
}

static gql_parser_lazy_state_t *
gql_parser_lazy_state_from_sv(SV *state_sv) {
  SV *inner_sv;

  if (!state_sv || !SvROK(state_sv)) {
    croak("expected GraphQL::Houtou::XS::LazyState object");
  }
  inner_sv = SvRV(state_sv);
  if (!SvIOK(inner_sv)) {
    croak("invalid GraphQL::Houtou::XS::LazyState payload");
  }
  return INT2PTR(gql_parser_lazy_state_t *, SvUV(inner_sv));
}

static AV *
gql_parser_materialize_lazy_array(pTHX_ SV *state_sv, UV ptr, IV kind) {
  gql_parser_lazy_state_t *lazy_state = gql_parser_lazy_state_from_sv(state_sv);
  gql_parser_loc_context_t *ctx = lazy_state->has_ctx ? &lazy_state->ctx : NULL;

  switch (kind) {
    case GQLJS_LAZY_ARRAY_ARGUMENTS:
      return gql_parser_build_arguments_from_ir(
        aTHX_ ctx,
        lazy_state->document,
        INT2PTR(gql_ir_ptr_array_t *, ptr),
        state_sv
      );
    case GQLJS_LAZY_ARRAY_DIRECTIVES:
      return gql_parser_build_directives_from_ir(
        aTHX_ ctx,
        lazy_state->document,
        INT2PTR(gql_ir_ptr_array_t *, ptr),
        state_sv
      );
    case GQLJS_LAZY_ARRAY_VARIABLE_DEFINITIONS:
      return gql_parser_build_variable_definitions_from_ir(
        aTHX_ ctx,
        lazy_state->document,
        INT2PTR(gql_ir_ptr_array_t *, ptr),
        state_sv
      );
    case GQLJS_LAZY_ARRAY_OBJECT_FIELDS:
      return gql_parser_build_object_fields_from_ir(
        aTHX_ ctx,
        lazy_state->document,
        INT2PTR(gql_ir_ptr_array_t *, ptr),
        state_sv
      );
  }

  croak("Unknown parser lazy array kind %" IVdf, kind);
  return NULL;
}

static SV *
gql_parser_new_lazy_arguments_sv(pTHX_ SV *state_sv, gql_ir_ptr_array_t *arguments) {
  dSP;
  SV *ret_sv;

  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSVsv(state_sv)));
  XPUSHs(sv_2mortal(newSVuv(PTR2UV(arguments))));
  PUTBACK;
  call_pv("GraphQL::Houtou::Parser::Internal::LazyArray::Arguments::_new", G_SCALAR);
  SPAGAIN;
  ret_sv = newSVsv(POPs);
  PUTBACK;
  FREETMPS;
  LEAVE;

  return ret_sv;
}

static SV *
gql_parser_new_lazy_directives_sv(pTHX_ SV *state_sv, gql_ir_ptr_array_t *directives) {
  dSP;
  SV *ret_sv;

  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSVsv(state_sv)));
  XPUSHs(sv_2mortal(newSVuv(PTR2UV(directives))));
  PUTBACK;
  call_pv("GraphQL::Houtou::Parser::Internal::LazyArray::Directives::_new", G_SCALAR);
  SPAGAIN;
  ret_sv = newSVsv(POPs);
  PUTBACK;
  FREETMPS;
  LEAVE;

  return ret_sv;
}

static SV *
gql_parser_new_lazy_object_fields_sv(pTHX_ SV *state_sv, gql_ir_ptr_array_t *fields) {
  dSP;
  SV *ret_sv;

  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSVsv(state_sv)));
  XPUSHs(sv_2mortal(newSVuv(PTR2UV(fields))));
  PUTBACK;
  call_pv("GraphQL::Houtou::Parser::Internal::LazyArray::ObjectFields::_new", G_SCALAR);
  SPAGAIN;
  ret_sv = newSVsv(POPs);
  PUTBACK;
  FREETMPS;
  LEAVE;

  return ret_sv;
}

static UV
gql_parser_original_pos_from_rewritten_pos(gql_parser_loc_context_t *ctx, UV rewritten_pos) {
  UV original_pos = rewritten_pos;

  if (!ctx) {
    return rewritten_pos;
  }

  if (ctx->rewrite_index_count > 0) {
    IV rewritten_iv = (IV)rewritten_pos;
    I32 low = 0;
    I32 high = ctx->rewrite_index_count - 1;
    I32 match = -1;

    while (low <= high) {
      I32 mid = low + ((high - low) / 2);
      gql_parser_rewrite_index_t *entry = &ctx->rewrite_index[mid];
      if (entry->rewritten_start <= rewritten_iv) {
        match = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    if (match >= 0) {
      gql_parser_rewrite_index_t *entry = &ctx->rewrite_index[match];
      if (rewritten_iv < entry->rewritten_end) {
        original_pos = entry->original_start;
      } else {
        original_pos = (UV)(rewritten_iv + entry->delta_after);
      }
    }
  }

  return original_pos;
}

static SV *
gql_parser_loc_from_rewritten_pos(pTHX_ gql_parser_loc_context_t *ctx, UV rewritten_pos) {
  UV original_pos;
  I32 line_index;
  SV *loc_sv;

  if (!ctx) {
    return &PL_sv_undef;
  }

  original_pos = gql_parser_original_pos_from_rewritten_pos(ctx, rewritten_pos);

  if (ctx->num_lines <= 0) {
    return ctx->lazy_location
      ? gql_parser_new_lazy_loc_sv(aTHX_ original_pos)
      : gql_parser_new_loc_sv(aTHX_ 1, (IV)(original_pos + 1));
  }

  if (ctx->has_last_line_index
      && original_pos >= ctx->line_starts[ctx->last_line_index]
      && (ctx->last_line_index + 1 >= ctx->num_lines
          || original_pos < ctx->line_starts[ctx->last_line_index + 1])) {
    line_index = ctx->last_line_index;
  } else if (ctx->has_last_line_index && original_pos >= ctx->last_original_pos) {
    line_index = ctx->last_line_index;
    while (line_index + 1 < ctx->num_lines && ctx->line_starts[line_index + 1] <= original_pos) {
      line_index++;
    }
  } else {
    I32 low = 0;
    I32 high = ctx->num_lines - 1;
    line_index = 0;

    while (low <= high) {
      I32 mid = low + ((high - low) / 2);
      if (ctx->line_starts[mid] <= original_pos) {
        line_index = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
  }
  ctx->last_original_pos = original_pos;
  ctx->last_line_index = line_index;
  ctx->has_last_line_index = 1;

  if (ctx->lazy_location) {
    loc_sv = gql_parser_new_lazy_loc_sv(aTHX_ original_pos);
  } else {
    loc_sv = gql_parser_new_loc_sv(
      aTHX_
      (IV)(line_index + 1),
      (IV)(original_pos - ctx->line_starts[line_index] + 1)
    );
  }
  return loc_sv;
}

static void
gql_parser_loc_context_destroy(gql_parser_loc_context_t *ctx) {
  if (ctx->line_starts) {
    Safefree(ctx->line_starts);
  }
  if (ctx->rewrite_index) {
    Safefree(ctx->rewrite_index);
  }
  ctx->line_starts = NULL;
  ctx->num_lines = 0;
  ctx->rewrite_index = NULL;
  ctx->rewrite_index_count = 0;
  ctx->last_original_pos = 0;
  ctx->last_line_index = 0;
  ctx->has_last_line_index = 0;
  ctx->lazy_location = 0;
  ctx->compact_location = 0;
}

static SV *
gql_parser_locate_name_node(pTHX_ gql_parser_t *p, SV *node_sv) {
  SV *loc;
  if (p->kind != TOK_NAME) {
    gql_throw_expected_token(aTHX_ p, TOK_NAME);
  }
  loc = sv_2mortal(gql_make_current_location(aTHX_ p));
  gql_parser_set_loc_node(aTHX_ node_sv, loc);
  gql_advance(aTHX_ p);
  return loc;
}

static SV *
gql_parser_locate_type_node(pTHX_ gql_parser_t *p, SV *node_sv) {
  HV *hv = gql_parser_node_hv(node_sv);
  const char *kind = gql_parser_fetch_kind(hv);
  SV *loc;

  if (!kind) {
    croak("parser executable loc expected type node");
  }

  if (strcmp(kind, "NamedType") == 0) {
    loc = gql_parser_locate_name_node(aTHX_ p, gql_parser_fetch_sv(hv, "name"));
    gql_parser_set_loc_node(aTHX_ node_sv, loc);
    return loc;
  }
  if (strcmp(kind, "ListType") == 0) {
    loc = sv_2mortal(gql_make_current_location(aTHX_ p));
    gql_expect(aTHX_ p, TOK_LBRACKET, NULL);
    gql_parser_set_loc_node(aTHX_ node_sv, loc);
    gql_parser_locate_type_node(aTHX_ p, gql_parser_fetch_sv(hv, "type"));
    gql_expect(aTHX_ p, TOK_RBRACKET, NULL);
    return loc;
  }
  if (strcmp(kind, "NonNullType") == 0) {
    loc = gql_parser_locate_type_node(aTHX_ p, gql_parser_fetch_sv(hv, "type"));
    gql_expect(aTHX_ p, TOK_BANG, NULL);
    gql_parser_set_loc_node(aTHX_ node_sv, loc);
    return loc;
  }

  croak("Unsupported parser executable type node %s", kind);
}

static SV *
gql_parser_locate_value_node(pTHX_ gql_parser_t *p, SV *node_sv) {
  HV *hv = gql_parser_node_hv(node_sv);
  const char *kind = gql_parser_fetch_kind(hv);
  SV *loc;
  AV *av;
  I32 i;

  if (!kind) {
    croak("parser executable loc expected value node");
  }

  if (strcmp(kind, "Variable") == 0) {
    loc = sv_2mortal(gql_make_current_location(aTHX_ p));
    gql_expect(aTHX_ p, TOK_DOLLAR, NULL);
    gql_parser_set_loc_node(aTHX_ node_sv, loc);
    gql_parser_locate_name_node(aTHX_ p, gql_parser_fetch_sv(hv, "name"));
    return loc;
  }
  if (strcmp(kind, "IntValue") == 0 || strcmp(kind, "FloatValue") == 0) {
    if (p->kind != TOK_INT && p->kind != TOK_FLOAT) {
      gql_throw_expected_message(aTHX_ p, p->tok_start, "Expected numeric token");
    }
    loc = sv_2mortal(gql_make_current_location(aTHX_ p));
    gql_parser_set_loc_node(aTHX_ node_sv, loc);
    gql_advance(aTHX_ p);
    return loc;
  }
  if (strcmp(kind, "StringValue") == 0) {
    if (p->kind != TOK_STRING && p->kind != TOK_BLOCK_STRING) {
      gql_throw(aTHX_ p, p->tok_start, "Expected string token");
    }
    loc = sv_2mortal(gql_make_current_location(aTHX_ p));
    gql_parser_set_loc_node(aTHX_ node_sv, loc);
    gql_advance(aTHX_ p);
    return loc;
  }
  if (strcmp(kind, "BooleanValue") == 0 || strcmp(kind, "NullValue") == 0 || strcmp(kind, "EnumValue") == 0) {
    loc = sv_2mortal(gql_make_current_location(aTHX_ p));
    gql_expect(aTHX_ p, TOK_NAME, NULL);
    gql_parser_set_loc_node(aTHX_ node_sv, loc);
    return loc;
  }
  if (strcmp(kind, "ListValue") == 0) {
    loc = sv_2mortal(gql_make_current_location(aTHX_ p));
    gql_expect(aTHX_ p, TOK_LBRACKET, NULL);
    gql_parser_set_loc_node(aTHX_ node_sv, loc);
    av = gql_parser_fetch_array(hv, "values");
    if (av) {
      for (i = 0; i <= av_len(av); i++) {
        SV **svp = av_fetch(av, i, 0);
        if (svp) {
          gql_parser_locate_value_node(aTHX_ p, *svp);
        }
      }
    }
    gql_expect(aTHX_ p, TOK_RBRACKET, NULL);
    return loc;
  }
  if (strcmp(kind, "ObjectValue") == 0) {
    loc = sv_2mortal(gql_make_current_location(aTHX_ p));
    gql_expect(aTHX_ p, TOK_LBRACE, NULL);
    gql_parser_set_loc_node(aTHX_ node_sv, loc);
    av = gql_parser_fetch_array(hv, "fields");
    while (p->kind != TOK_RBRACE) {
      SV *name_sv = sv_2mortal(newSVpvn(p->src + p->tok_start, p->tok_end - p->tok_start));
      SV *field_sv = gql_parser_find_named_node_sv(av, name_sv);
      HV *field_hv;
      SV *field_loc;
      if (!field_sv) {
        croak("Missing object field node");
      }
      field_hv = gql_parser_node_hv(field_sv);
      field_loc = sv_2mortal(gql_make_current_location(aTHX_ p));
      gql_parser_set_loc_node(aTHX_ field_sv, field_loc);
      gql_parser_locate_name_node(aTHX_ p, gql_parser_fetch_sv(field_hv, "name"));
      gql_expect(aTHX_ p, TOK_COLON, NULL);
      gql_parser_locate_value_node(aTHX_ p, gql_parser_fetch_sv(field_hv, "value"));
    }
    gql_expect(aTHX_ p, TOK_RBRACE, NULL);
    return loc;
  }

  croak("Unsupported parser executable value node %s", kind);
}

static void
gql_parser_locate_arguments_nodes(pTHX_ gql_parser_t *p, AV *av) {
  if (!av || av_len(av) < 0) {
    return;
  }
  gql_expect(aTHX_ p, TOK_LPAREN, NULL);
  while (p->kind != TOK_RPAREN) {
    SV *name_sv = sv_2mortal(newSVpvn(p->src + p->tok_start, p->tok_end - p->tok_start));
    SV *node_sv = gql_parser_find_named_node_sv(av, name_sv);
    HV *node_hv;
    SV *loc;
    if (!node_sv) {
      croak("Missing argument node");
    }
    node_hv = gql_parser_node_hv(node_sv);
    loc = sv_2mortal(gql_make_current_location(aTHX_ p));
    gql_parser_set_loc_node(aTHX_ node_sv, loc);
    gql_parser_locate_name_node(aTHX_ p, gql_parser_fetch_sv(node_hv, "name"));
    gql_expect(aTHX_ p, TOK_COLON, NULL);
    gql_parser_locate_value_node(aTHX_ p, gql_parser_fetch_sv(node_hv, "value"));
  }
  gql_expect(aTHX_ p, TOK_RPAREN, NULL);
}

static void
gql_parser_locate_directives_nodes(pTHX_ gql_parser_t *p, AV *av) {
  I32 i;
  if (!av || av_len(av) < 0) {
    return;
  }
  for (i = 0; i <= av_len(av); i++) {
    SV **svp = av_fetch(av, i, 0);
    HV *hv;
    SV *loc;
    if (!svp) {
      continue;
    }
    hv = gql_parser_node_hv(*svp);
    if (!hv) {
      continue;
    }
    loc = sv_2mortal(gql_make_current_location(aTHX_ p));
    gql_expect(aTHX_ p, TOK_AT, NULL);
    gql_parser_set_loc_node(aTHX_ *svp, loc);
    gql_parser_locate_name_node(aTHX_ p, gql_parser_fetch_sv(hv, "name"));
    gql_parser_locate_arguments_nodes(aTHX_ p, gql_parser_fetch_array(hv, "arguments"));
  }
}

static SV *
gql_parser_locate_selection_set_node(pTHX_ gql_parser_t *p, SV *node_sv) {
  HV *hv = gql_parser_node_hv(node_sv);
  AV *av = gql_parser_fetch_array(hv, "selections");
  I32 i;
  SV *loc = sv_2mortal(gql_make_current_location(aTHX_ p));
  gql_expect(aTHX_ p, TOK_LBRACE, NULL);
  gql_parser_set_loc_node(aTHX_ node_sv, loc);
  if (av) {
    for (i = 0; i <= av_len(av); i++) {
      SV **svp = av_fetch(av, i, 0);
      if (svp) {
        gql_parser_locate_selection_node(aTHX_ p, *svp);
      }
    }
  }
  gql_expect(aTHX_ p, TOK_RBRACE, NULL);
  return loc;
}

static void
gql_parser_locate_selection_node(pTHX_ gql_parser_t *p, SV *node_sv) {
  HV *hv = gql_parser_node_hv(node_sv);
  const char *kind = gql_parser_fetch_kind(hv);
  SV *loc;

  if (!kind) {
    croak("parser executable loc expected selection node");
  }

  if (strcmp(kind, "Field") == 0) {
    loc = sv_2mortal(gql_make_current_location(aTHX_ p));
    if (gql_parser_fetch_sv(hv, "alias")) {
      gql_parser_locate_name_node(aTHX_ p, gql_parser_fetch_sv(hv, "alias"));
      gql_expect(aTHX_ p, TOK_COLON, NULL);
      gql_parser_locate_name_node(aTHX_ p, gql_parser_fetch_sv(hv, "name"));
    } else {
      gql_parser_locate_name_node(aTHX_ p, gql_parser_fetch_sv(hv, "name"));
    }
    gql_parser_set_loc_node(aTHX_ node_sv, loc);
    gql_parser_locate_arguments_nodes(aTHX_ p, gql_parser_fetch_array(hv, "arguments"));
    gql_parser_locate_directives_nodes(aTHX_ p, gql_parser_fetch_array(hv, "directives"));
    if (gql_parser_fetch_sv(hv, "selectionSet")) {
      gql_parser_locate_selection_set_node(aTHX_ p, gql_parser_fetch_sv(hv, "selectionSet"));
    }
    return;
  }
  if (strcmp(kind, "FragmentSpread") == 0) {
    loc = sv_2mortal(gql_make_current_location(aTHX_ p));
    gql_expect(aTHX_ p, TOK_SPREAD, NULL);
    gql_parser_set_loc_node(aTHX_ node_sv, loc);
    gql_parser_locate_name_node(aTHX_ p, gql_parser_fetch_sv(hv, "name"));
    gql_parser_locate_directives_nodes(aTHX_ p, gql_parser_fetch_array(hv, "directives"));
    return;
  }
  if (strcmp(kind, "InlineFragment") == 0) {
    loc = sv_2mortal(gql_make_current_location(aTHX_ p));
    gql_expect(aTHX_ p, TOK_SPREAD, NULL);
    gql_parser_set_loc_node(aTHX_ node_sv, loc);
    if (gql_parser_fetch_sv(hv, "typeCondition")) {
      gql_expect(aTHX_ p, TOK_NAME, NULL);
      gql_parser_locate_type_node(aTHX_ p, gql_parser_fetch_sv(hv, "typeCondition"));
    }
    gql_parser_locate_directives_nodes(aTHX_ p, gql_parser_fetch_array(hv, "directives"));
    gql_parser_locate_selection_set_node(aTHX_ p, gql_parser_fetch_sv(hv, "selectionSet"));
    return;
  }

  croak("Unsupported parser executable selection node %s", kind);
}
