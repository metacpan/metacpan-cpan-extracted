/*
 * Responsibility: graphql-perl mainline recursive-descent parser entrypoints
 * and legacy AST builders used by the active parser surface.
 */

static void
gql_skip_ignored(gql_parser_t *p) {
  while (p->pos < p->len) {
    unsigned char c = (unsigned char)p->src[p->pos];
    if (c == 0xEF && p->pos + 2 < p->len &&
        (unsigned char)p->src[p->pos + 1] == 0xBB &&
        (unsigned char)p->src[p->pos + 2] == 0xBF) {
      p->pos += 3;
      continue;
    }
    if (c == ',' || c == ' ' || c == '\t' || c == '\n' || c == '\r') {
      p->pos++;
      continue;
    }
    if (c == '#') {
      while (p->pos < p->len) {
        c = (unsigned char)p->src[p->pos];
        p->pos++;
        if (c == '\n' || c == '\r') {
          break;
        }
      }
      continue;
    }
    break;
  }
}

static void
gql_lex_token(pTHX_ gql_parser_t *p) {
  STRLEN start;
  unsigned char c;
  start = p->pos;
  p->tok_start = start;
  p->tok_end = start;
  p->val_start = start;
  p->val_end = start;
  if (start >= p->len) {
    p->kind = TOK_EOF;
    return;
  }
  /* Bound total tokens (S2): a real token follows, so count it before
   * lexing. EOF above is not counted. */
  if (++p->token_count > GQL_PARSER_MAX_TOKENS) {
    gql_throw_simple_error(aTHX_ "Document has too many tokens (exceeds maximum token count)");
  }
  c = (unsigned char)p->src[p->pos];
  switch (c) {
    case '!':
      p->kind = TOK_BANG;
      p->pos++;
      p->tok_end = p->pos;
      return;
    case '$':
      p->kind = TOK_DOLLAR;
      p->pos++;
      p->tok_end = p->pos;
      return;
    case '&':
      p->kind = TOK_AMP;
      p->pos++;
      p->tok_end = p->pos;
      return;
    case '(':
      p->kind = TOK_LPAREN;
      p->pos++;
      p->tok_end = p->pos;
      return;
    case ')':
      p->kind = TOK_RPAREN;
      p->pos++;
      p->tok_end = p->pos;
      return;
    case ':':
      p->kind = TOK_COLON;
      p->pos++;
      p->tok_end = p->pos;
      return;
    case '=':
      p->kind = TOK_EQUALS;
      p->pos++;
      p->tok_end = p->pos;
      return;
    case '@':
      p->kind = TOK_AT;
      p->pos++;
      p->tok_end = p->pos;
      return;
    case '[':
      p->kind = TOK_LBRACKET;
      p->pos++;
      p->tok_end = p->pos;
      return;
    case ']':
      p->kind = TOK_RBRACKET;
      p->pos++;
      p->tok_end = p->pos;
      return;
    case '{':
      p->kind = TOK_LBRACE;
      p->pos++;
      p->tok_end = p->pos;
      return;
    case '}':
      p->kind = TOK_RBRACE;
      p->pos++;
      p->tok_end = p->pos;
      return;
    case '|':
      p->kind = TOK_PIPE;
      p->pos++;
      p->tok_end = p->pos;
      return;
    case '.':
      if (p->pos + 2 < p->len && p->src[p->pos + 1] == '.' && p->src[p->pos + 2] == '.') {
        p->kind = TOK_SPREAD;
        p->pos += 3;
        p->tok_end = p->pos;
        return;
      }
      gql_throw(aTHX_ p, p->pos, "Expected \"...\"");
      break;
    case '"':
      if (p->pos + 2 < p->len && p->src[p->pos + 1] == '"' && p->src[p->pos + 2] == '"') {
        STRLEN scan = p->pos + 3;
        p->val_start = scan;
        while (scan < p->len) {
          if (scan + 2 < p->len && p->src[scan] == '"' && p->src[scan + 1] == '"' && p->src[scan + 2] == '"') {
            p->kind = TOK_BLOCK_STRING;
            p->val_end = scan;
            p->pos = scan + 3;
            p->tok_end = p->pos;
            return;
          }
          if ((unsigned char)p->src[scan] < 0x20 &&
              p->src[scan] != '\t' && p->src[scan] != '\n' && p->src[scan] != '\r') {
            gql_throw(aTHX_ p, scan, "Invalid character within block string");
          }
          if (scan + 3 < p->len &&
              p->src[scan] == '\\' &&
              p->src[scan + 1] == '"' &&
              p->src[scan + 2] == '"' &&
              p->src[scan + 3] == '"') {
            scan += 4;
            continue;
          }
          scan++;
        }
        gql_throw(aTHX_ p, p->tok_start, "Unterminated block string");
      } else {
        STRLEN scan = p->pos + 1;
        p->val_start = scan;
        while (scan < p->len) {
          unsigned char sc = (unsigned char)p->src[scan];
          if (p->src[scan] == '"') {
            p->kind = TOK_STRING;
            p->val_end = scan;
            p->pos = scan + 1;
            p->tok_end = p->pos;
            return;
          }
          if (p->src[scan] == '\\') {
            scan++;
            if (scan >= p->len) {
              gql_throw(aTHX_ p, p->tok_start, "Unterminated string");
            }
            if (strchr("\"\\/bfnrt", p->src[scan])) {
              scan++;
              continue;
            }
            if (p->src[scan] == 'u') {
              int i;
              for (i = 0; i < 4; i++) {
                scan++;
                if (scan >= p->len || !isXDIGIT((unsigned char)p->src[scan])) {
                  gql_throw(aTHX_ p, p->tok_start, "Invalid Unicode escape sequence");
                }
              }
              scan++;
              continue;
            }
            gql_throw(aTHX_ p, p->tok_start, "Invalid character escape sequence");
          }
          if (sc == '\n' || sc == '\r') {
            gql_throw(aTHX_ p, p->tok_start, "Unterminated string");
          }
          if (sc == 0x00 || sc < 0x20) {
            gql_throw(aTHX_ p, p->tok_start, "Invalid character within string");
          }
          scan++;
        }
        gql_throw(aTHX_ p, p->tok_start, "Unterminated string");
      }
      break;
    default:
      break;
  }

  if (c == '-' || isDIGIT(c)) {
    STRLEN scan = p->pos;
    bool is_float = 0;
    if (p->src[scan] == '-') {
      scan++;
      if (scan >= p->len || !isDIGIT((unsigned char)p->src[scan])) {
        gql_throw(aTHX_ p, p->tok_start, "Invalid number, expected digit after \"-\"");
      }
    }
    if (p->src[scan] == '0') {
      scan++;
      if (scan < p->len && isDIGIT((unsigned char)p->src[scan])) {
        gql_throw(aTHX_ p, scan, "Invalid number, unexpected digit after 0");
      }
    } else {
      while (scan < p->len && isDIGIT((unsigned char)p->src[scan])) {
        scan++;
      }
    }
    if (scan < p->len && p->src[scan] == '.') {
      is_float = 1;
      scan++;
      if (scan >= p->len || !isDIGIT((unsigned char)p->src[scan])) {
        gql_throw(aTHX_ p, scan - 1, "Invalid number, expected digit after decimal point");
      }
      while (scan < p->len && isDIGIT((unsigned char)p->src[scan])) {
        scan++;
      }
    }
    if (scan < p->len && (p->src[scan] == 'e' || p->src[scan] == 'E')) {
      STRLEN exp_pos = scan;
      bool had_sign = 0;
      is_float = 1;
      scan++;
      if (scan < p->len && (p->src[scan] == '+' || p->src[scan] == '-')) {
        had_sign = 1;
        scan++;
      }
      if (scan >= p->len || !isDIGIT((unsigned char)p->src[scan])) {
        STRLEN err_pos = exp_pos + 1;
        if (!had_sign && scan < p->len &&
            ((p->src[scan] >= 'A' && p->src[scan] <= 'Z') ||
             (p->src[scan] >= 'a' && p->src[scan] <= 'z') ||
             p->src[scan] == '_')) {
          err_pos = exp_pos + 2;
        }
        gql_throw(aTHX_ p, err_pos, "Invalid number, expected digit after exponent indicator");
      }
      while (scan < p->len && isDIGIT((unsigned char)p->src[scan])) {
        scan++;
      }
    }
    p->kind = is_float ? TOK_FLOAT : TOK_INT;
    p->pos = scan;
    p->tok_end = p->pos;
    p->val_start = p->tok_start;
    p->val_end = p->tok_end;
    return;
  }

  if (c == '_' || isALPHA(c)) {
    STRLEN scan = p->pos + 1;
    while (scan < p->len) {
      unsigned char nc = (unsigned char)p->src[scan];
      if (!(nc == '_' || isALNUM(nc))) {
        break;
      }
      scan++;
    }
    p->kind = TOK_NAME;
    p->pos = scan;
    p->tok_end = p->pos;
    p->val_start = p->tok_start;
    p->val_end = p->tok_end;
    return;
  }

  gql_throw_unexpected_character(aTHX_ p, p->pos, c);
}

static void
gql_advance(pTHX_ gql_parser_t *p) {
  if (p->tok_end > 0) {
    p->last_pos = p->tok_end - 1;
  }
  gql_skip_ignored(p);
  gql_lex_token(aTHX_ p);
}

static int
gql_peek_name(gql_parser_t *p, const char *name) {
  STRLEN len = strlen(name);
  return p->kind == TOK_NAME &&
    (p->tok_end - p->tok_start) == len &&
    memEQ(p->src + p->tok_start, name, len);
}

static void
gql_expect(pTHX_ gql_parser_t *p, gql_token_kind_t kind, const char *msg) {
  if (p->kind != kind) {
    if (msg) {
      gql_throw_expected_message(aTHX_ p, p->tok_start, msg);
    }
    gql_throw_expected_token(aTHX_ p, kind);
  }
  gql_advance(aTHX_ p);
}

static SV *
gql_parse_name(pTHX_ gql_parser_t *p, const char *msg) {
  SV *sv;
  if (p->kind != TOK_NAME) {
    gql_throw_expected_message(aTHX_ p, p->tok_start, msg);
  }
  sv = gql_copy_token_sv(aTHX_ p);
  gql_advance(aTHX_ p);
  return sv;
}

static SV *
gql_parse_fragment_name(pTHX_ gql_parser_t *p) {
  if (gql_peek_name(p, "on")) {
    gql_throw(aTHX_ p, p->tok_end, "Unexpected Name \"on\"");
  }
  return gql_parse_name(aTHX_ p, "Expected name");
}

static gql_ir_span_t
gql_ir_parse_name_span(pTHX_ gql_parser_t *p, const char *msg) {
  gql_ir_span_t span;

  if (p->kind != TOK_NAME) {
    gql_throw_expected_message(aTHX_ p, p->tok_start, msg);
  }
  span.start = (UV)p->tok_start;
  span.end = (UV)p->tok_end;
  gql_advance(aTHX_ p);
  return span;
}

static gql_ir_span_t
gql_ir_parse_fragment_name_span(pTHX_ gql_parser_t *p) {
  if (gql_peek_name(p, "on")) {
    gql_throw(aTHX_ p, p->tok_end, "Unexpected Name \"on\"");
  }
  return gql_ir_parse_name_span(aTHX_ p, "Expected name");
}

static void
gql_parser_init(pTHX_ gql_parser_t *p, SV *source_sv, int no_location) {
  STRLEN len;
  const char *src = SvPV(source_sv, len);
  STRLEN i;
  I32 line_cap = 16;
  I32 line_count = 1;

  p->src = src;
  p->len = len;
  p->pos = 0;
  p->last_pos = (STRLEN)-1;
  p->tok_start = 0;
  p->tok_end = 0;
  p->val_start = 0;
  p->val_end = 0;
  p->kind = TOK_EOF;
  p->is_utf8 = SvUTF8(source_sv) ? 1 : 0;
  p->no_location = no_location ? 1 : 0;
  p->line_starts = NULL;
  p->num_lines = 0;
  p->ir_arena = NULL;
  p->depth = 0;
  p->token_count = 0;
  p->validation_errors = NULL;

  if (p->no_location) {
    return;
  }

  Newx(p->line_starts, line_cap, UV);
  p->line_starts[0] = 0;

  for (i = 0; i < len; i++) {
    if (src[i] == '\n' || src[i] == '\r') {
      if (line_count == line_cap) {
        line_cap *= 2;
        Renew(p->line_starts, line_cap, UV);
      }
      if (src[i] == '\r' && i + 1 < len && src[i + 1] == '\n') {
        i++;
      }
      p->line_starts[line_count++] = (UV)(i + 1);
    }
  }

  p->num_lines = line_count;
  SAVEFREEPV(p->line_starts);
}

static void
gql_parser_invalidate(gql_parser_t *p) {
  /* line_starts is freed by SAVEFREEPV during FREETMPS/LEAVE.
   * This helper only clears borrowed pointers from the stack-local parser.
   */
  p->line_starts = NULL;
  p->num_lines = 0;
}

static void
gql_line_column_from_pos(gql_parser_t *p, STRLEN pos, IV *line, IV *column, int one_based) {
  I32 low;
  I32 high;
  I32 found;
  UV line_start;
  if (pos == (STRLEN)-1) {
    *line = 1;
    *column = 0;
    return;
  }
  if (!p->line_starts || p->num_lines <= 0) {
    *line = 1;
    *column = (IV)(pos + (one_based ? 1 : 0));
    return;
  }
  low = 0;
  high = p->num_lines - 1;
  found = 0;
  while (low <= high) {
    I32 mid = low + ((high - low) / 2);
    UV start = p->line_starts[mid];
    if (start <= (UV)pos) {
      found = mid;
      low = mid + 1;
    } else {
      high = mid - 1;
    }
  }
  line_start = p->line_starts[found];
  *line = found + 1;
  *column = (IV)(pos - line_start + (one_based ? 1 : 0));
}

static void
gql_line_column_from_last(gql_parser_t *p, IV *line, IV *column) {
  gql_line_column_from_pos(p, p->last_pos, line, column, 0);
}

static SV *
gql_make_location(pTHX_ gql_parser_t *p) {
  HV *hv = newHV();
  IV line;
  IV column;
  gql_line_column_from_last(p, &line, &column);
  gql_store_sv(hv, "line", newSViv(line));
  gql_store_sv(hv, "column", newSViv(column));
  return newRV_noinc((SV *)hv);
}

static SV *
gql_make_current_location(pTHX_ gql_parser_t *p) {
  HV *hv;
  IV line;
  IV column;
  if (p->kind == TOK_EOF && p->tok_start <= p->last_pos + 1) {
    return gql_make_location(aTHX_ p);
  }
  hv = newHV();
  gql_line_column_from_pos(p, p->tok_start, &line, &column, 1);
  gql_store_sv(hv, "line", newSViv(line));
  gql_store_sv(hv, "column", newSViv(column));
  return newRV_noinc((SV *)hv);
}

static void
gql_store_current_location(pTHX_ gql_parser_t *p, HV *hv) {
  if (p->no_location) {
    return;
  }
  gql_store_sv(hv, "location", gql_make_current_location(aTHX_ p));
}

static SV *
gql_make_endline_location(pTHX_ gql_parser_t *p) {
  HV *hv = newHV();
  IV line;
  IV column;
  gql_line_column_from_last(p, &line, &column);
  gql_store_sv(hv, "line", newSViv(line));
  gql_store_sv(hv, "column", newSViv(0));
  return newRV_noinc((SV *)hv);
}

static void
gql_store_endline_location(pTHX_ gql_parser_t *p, HV *hv) {
  if (p->no_location) {
    return;
  }
  gql_store_sv(hv, "location", gql_make_endline_location(aTHX_ p));
}

static SV *
gql_make_current_or_endline_location(pTHX_ gql_parser_t *p) {
  IV current_line;
  IV current_column;
  IV last_line;
  IV last_column;
  if (p->kind == TOK_EOF) {
    return gql_make_current_location(aTHX_ p);
  }
  gql_line_column_from_pos(p, p->tok_start, &current_line, &current_column, 1);
  gql_line_column_from_last(p, &last_line, &last_column);
  if (current_line == last_line) {
    return gql_make_current_location(aTHX_ p);
  }
  return gql_make_endline_location(aTHX_ p);
}

static void
gql_store_current_or_endline_location(pTHX_ gql_parser_t *p, HV *hv) {
  if (p->no_location) {
    return;
  }
  gql_store_sv(hv, "location", gql_make_current_or_endline_location(aTHX_ p));
}

static SV *
gql_make_type_wrapper(pTHX_ SV *type_sv, const char *kind) {
  AV *av = newAV();
  HV *inner = newHV();
  av_push(av, newSVpv(kind, 0));
  gql_store_sv(inner, "type", type_sv);
  av_push(av, newRV_noinc((SV *)inner));
  return newRV_noinc((SV *)av);
}

static SV *
gql_parse_list_value(pTHX_ gql_parser_t *p, int is_const) {
  AV *av;
  /* Input-value nesting recurses only through list/object values; guard
   * here so a deep [[[... cannot overflow the C stack (S1). */
  if (++p->depth > GQL_PARSER_MAX_DEPTH) {
    gql_throw(aTHX_ p, p->tok_start,
      "Value is too deeply nested (exceeds maximum nesting depth)");
  }
  av = newAV();
  gql_expect(aTHX_ p, TOK_LBRACKET, NULL);
  while (p->kind != TOK_RBRACKET) {
    av_push(av, gql_parse_value(aTHX_ p, is_const));
  }
  gql_expect(aTHX_ p, TOK_RBRACKET, NULL);
  p->depth--;
  return newRV_noinc((SV *)av);
}

static SV *
gql_parse_object_value(pTHX_ gql_parser_t *p, int is_const) {
  HV *hv;
  if (++p->depth > GQL_PARSER_MAX_DEPTH) {
    gql_throw(aTHX_ p, p->tok_start,
      "Value is too deeply nested (exceeds maximum nesting depth)");
  }
  hv = newHV();
  gql_expect(aTHX_ p, TOK_LBRACE, "Expected name");
  while (p->kind != TOK_RBRACE) {
    SV *name = gql_parse_name(aTHX_ p, "Expected name");
    gql_expect(aTHX_ p, TOK_COLON, NULL);
    if (p->validation_errors) {
      STRLEN name_len;
      const char *name_str = SvPV(name, name_len);
      if (hv_exists(hv, name_str, (I32)name_len)) {
        HV *error_hv = newHV();
        AV *locations_av = newAV();
        SV *message = newSVpvf("Input field '%s' is provided more than once.", name_str);
        gql_store_sv(error_hv, "message", message);
        av_push(locations_av, gql_make_current_location(aTHX_ p));
        gql_store_sv(error_hv, "locations", newRV_noinc((SV *)locations_av));
        av_push(p->validation_errors, newRV_noinc((SV *)error_hv));
      }
    }
    gql_store_sv(hv, SvPV_nolen(name), gql_parse_value(aTHX_ p, is_const));
    SvREFCNT_dec(name);
  }
  gql_expect(aTHX_ p, TOK_RBRACE, NULL);
  p->depth--;
  return newRV_noinc((SV *)hv);
}

static SV *
gql_parse_value(pTHX_ gql_parser_t *p, int is_const) {
  switch (p->kind) {
    case TOK_DOLLAR: {
      SV *name;
      if (is_const) {
        gql_throw(aTHX_ p, p->tok_start, "Expected name or constant");
      }
      gql_advance(aTHX_ p);
      name = gql_parse_name(aTHX_ p, "Expected name");
      return newRV_noinc(name);
    }
    case TOK_INT: {
      SV *sv = gql_copy_token_sv(aTHX_ p);
      sv_setiv(sv, SvIV(sv));
      gql_advance(aTHX_ p);
      return sv;
    }
    case TOK_FLOAT: {
      SV *sv = gql_copy_token_sv(aTHX_ p);
      sv_setnv(sv, SvNV(sv));
      gql_advance(aTHX_ p);
      return sv;
    }
    case TOK_STRING:
    case TOK_BLOCK_STRING: {
      SV *sv = gql_copy_value_sv(aTHX_ p);
      gql_advance(aTHX_ p);
      return sv;
    }
    case TOK_NAME: {
      if (gql_peek_name(p, "true")) {
        gql_advance(aTHX_ p);
        return gql_call_helper1(aTHX_ "GraphQL::Houtou::Parser::Internal::_make_bool", newSViv(1));
      }
      if (gql_peek_name(p, "false")) {
        gql_advance(aTHX_ p);
        return gql_call_helper1(aTHX_ "GraphQL::Houtou::Parser::Internal::_make_bool", newSViv(0));
      }
      if (gql_peek_name(p, "null")) {
        gql_advance(aTHX_ p);
        return newSV(0);
      }
      {
        SV *name = gql_copy_token_sv(aTHX_ p);
        SV *ref1 = newRV_noinc(name);
        gql_advance(aTHX_ p);
        return newRV_noinc(ref1);
      }
    }
    case TOK_LBRACKET:
      return gql_parse_list_value(aTHX_ p, is_const);
    case TOK_LBRACE:
      return gql_parse_object_value(aTHX_ p, is_const);
    default:
      gql_throw(aTHX_ p, p->tok_start, is_const ? "Expected name or constant" : "Expected value");
  }
  return &PL_sv_undef;
}

static SV *
gql_parse_arguments(pTHX_ gql_parser_t *p, int is_const) {
  HV *hv = newHV();
  gql_expect(aTHX_ p, TOK_LPAREN, NULL);
  if (p->kind == TOK_RPAREN) {
    gql_throw_expected_message(aTHX_ p, p->tok_start, "Expected name");
  }
  while (p->kind != TOK_RPAREN) {
    SV *name = gql_parse_name(aTHX_ p, "Expected name");
    gql_expect(aTHX_ p, TOK_COLON, NULL);
    if (p->validation_errors) {
      STRLEN name_len;
      const char *name_str = SvPV(name, name_len);
      if (hv_exists(hv, name_str, (I32)name_len)) {
        HV *error_hv = newHV();
        AV *locations_av = newAV();
        SV *message = newSVpvf("Argument '%s' is provided more than once.", name_str);
        gql_store_sv(error_hv, "message", message);
        av_push(locations_av, gql_make_current_location(aTHX_ p));
        gql_store_sv(error_hv, "locations", newRV_noinc((SV *)locations_av));
        av_push(p->validation_errors, newRV_noinc((SV *)error_hv));
      }
    }
    gql_store_sv(hv, SvPV_nolen(name), gql_parse_value(aTHX_ p, is_const));
    SvREFCNT_dec(name);
  }
  gql_expect(aTHX_ p, TOK_RPAREN, NULL);
  return newRV_noinc((SV *)hv);
}

static SV *
gql_parse_directive(pTHX_ gql_parser_t *p) {
  HV *hv = newHV();
  gql_expect(aTHX_ p, TOK_AT, NULL);
  gql_store_sv(hv, "name", gql_parse_name(aTHX_ p, "Expected name"));
  if (p->kind == TOK_LPAREN) {
    gql_store_sv(hv, "arguments", gql_parse_arguments(aTHX_ p, 0));
  }
  return newRV_noinc((SV *)hv);
}

static SV *
gql_parse_directives(pTHX_ gql_parser_t *p) {
  AV *av = newAV();
  while (p->kind == TOK_AT) {
    av_push(av, gql_parse_directive(aTHX_ p));
  }
  return newRV_noinc((SV *)av);
}

static SV *
gql_parse_const_directives(pTHX_ gql_parser_t *p) {
  AV *av = newAV();
  while (p->kind == TOK_AT) {
    HV *hv = newHV();
    gql_expect(aTHX_ p, TOK_AT, NULL);
    gql_store_sv(hv, "name", gql_parse_name(aTHX_ p, "Expected name"));
    if (p->kind == TOK_LPAREN) {
      gql_store_sv(hv, "arguments", gql_parse_arguments(aTHX_ p, 1));
    }
    av_push(av, newRV_noinc((SV *)hv));
  }
  return newRV_noinc((SV *)av);
}

static SV *
gql_parse_selection_set(pTHX_ gql_parser_t *p) {
  HV *hv;
  AV *av;
  if (++p->depth > GQL_PARSER_MAX_DEPTH) {
    gql_throw(aTHX_ p, p->tok_start,
      "Query is too deeply nested (exceeds maximum nesting depth)");
  }
  hv = newHV();
  av = newAV();
  gql_expect(aTHX_ p, TOK_LBRACE, "Expected name");
  if (p->kind == TOK_RBRACE) {
    gql_throw(aTHX_ p, p->tok_start, "Expected name");
  }
  while (p->kind != TOK_RBRACE) {
    av_push(av, gql_parse_selection(aTHX_ p));
  }
  gql_expect(aTHX_ p, TOK_RBRACE, NULL);
  gql_store_sv(hv, "selections", newRV_noinc((SV *)av));
  p->depth--;
  return newRV_noinc((SV *)hv);
}

static SV *
gql_parse_field(pTHX_ gql_parser_t *p) {
  HV *hv = newHV();
  int had_directives = 0;
  int had_selection_set = 0;
  SV *first = gql_parse_name(aTHX_ p, "Expected name");
  if (p->kind == TOK_COLON) {
    gql_store_sv(hv, "alias", first);
    gql_advance(aTHX_ p);
    gql_store_sv(hv, "name", gql_parse_name(aTHX_ p, "Expected name"));
  } else {
    gql_store_sv(hv, "name", first);
  }
  if (p->kind == TOK_LPAREN) {
    gql_store_sv(hv, "arguments", gql_parse_arguments(aTHX_ p, 0));
  }
  if (p->kind == TOK_AT) {
    had_directives = 1;
    gql_store_sv(hv, "directives", gql_parse_directives(aTHX_ p));
  }
  if (p->kind == TOK_LBRACE) {
    had_selection_set = 1;
    SV *sel = gql_parse_selection_set(aTHX_ p);
    HV *selhv = (HV *)SvRV(sel);
    SV **svp = hv_fetch(selhv, "selections", 10, 0);
    gql_store_sv(hv, "selections", newSVsv(*svp));
    SvREFCNT_dec(sel);
  }
  gql_store_sv(hv, "kind", newSVpv("field", 0));
  if (had_selection_set) {
    gql_store_current_location(aTHX_ p, hv);
  } else if (had_directives) {
    gql_store_current_or_endline_location(aTHX_ p, hv);
  } else {
    gql_store_current_location(aTHX_ p, hv);
  }
  return newRV_noinc((SV *)hv);
}

static SV *
gql_parse_selection(pTHX_ gql_parser_t *p) {
  if (p->kind == TOK_SPREAD) {
    HV *hv = newHV();
    gql_advance(aTHX_ p);
    if (gql_peek_name(p, "on")) {
      gql_parser_t lookahead = *p;
      gql_advance(aTHX_ &lookahead);
      if (lookahead.kind != TOK_NAME) {
        gql_throw(aTHX_ p, p->tok_start, "Unexpected Name \"on\"");
      }
      gql_advance(aTHX_ p);
      gql_store_sv(hv, "on", gql_parse_name(aTHX_ p, "Expected name"));
      if (p->kind == TOK_AT) {
        gql_store_sv(hv, "directives", gql_parse_directives(aTHX_ p));
      }
      {
        SV *sel = gql_parse_selection_set(aTHX_ p);
        HV *selhv = (HV *)SvRV(sel);
        SV **svp = hv_fetch(selhv, "selections", 10, 0);
        gql_store_sv(hv, "selections", newSVsv(*svp));
        SvREFCNT_dec(sel);
      }
      gql_store_sv(hv, "kind", newSVpv("inline_fragment", 0));
      gql_store_current_location(aTHX_ p, hv);
      return newRV_noinc((SV *)hv);
    }
    if (p->kind == TOK_LBRACE) {
      SV *sel = gql_parse_selection_set(aTHX_ p);
      HV *selhv = (HV *)SvRV(sel);
      SV **svp = hv_fetch(selhv, "selections", 10, 0);
      gql_store_sv(hv, "selections", newSVsv(*svp));
      SvREFCNT_dec(sel);
      gql_store_sv(hv, "kind", newSVpv("inline_fragment", 0));
      gql_store_current_location(aTHX_ p, hv);
      return newRV_noinc((SV *)hv);
    }
    if (p->kind == TOK_AT) {
      gql_store_sv(hv, "directives", gql_parse_directives(aTHX_ p));
      {
        SV *sel = gql_parse_selection_set(aTHX_ p);
        HV *selhv = (HV *)SvRV(sel);
        SV **svp = hv_fetch(selhv, "selections", 10, 0);
        gql_store_sv(hv, "selections", newSVsv(*svp));
        SvREFCNT_dec(sel);
      }
      gql_store_sv(hv, "kind", newSVpv("inline_fragment", 0));
      gql_store_current_location(aTHX_ p, hv);
      return newRV_noinc((SV *)hv);
    }
    gql_store_sv(hv, "name", gql_parse_fragment_name(aTHX_ p));
    if (p->kind == TOK_AT) {
      gql_store_sv(hv, "directives", gql_parse_directives(aTHX_ p));
      gql_store_sv(hv, "kind", newSVpv("fragment_spread", 0));
      gql_store_current_or_endline_location(aTHX_ p, hv);
      return newRV_noinc((SV *)hv);
    }
    gql_store_sv(hv, "kind", newSVpv("fragment_spread", 0));
    gql_store_current_location(aTHX_ p, hv);
    return newRV_noinc((SV *)hv);
  }
  return gql_parse_field(aTHX_ p);
}

static SV *
gql_parse_variable_definitions(pTHX_ gql_parser_t *p) {
  HV *hv = newHV();
  gql_expect(aTHX_ p, TOK_LPAREN, NULL);
  if (p->kind == TOK_RPAREN) {
    gql_throw(aTHX_ p, p->tok_start, "Expected $argument: Type");
  }
  while (p->kind != TOK_RPAREN) {
    SV *description = gql_parse_description(aTHX_ p);
    HV *def = newHV();
    SV *name;
    gql_expect(aTHX_ p, TOK_DOLLAR, NULL);
    name = gql_parse_name(aTHX_ p, "Expected name");
    gql_expect(aTHX_ p, TOK_COLON, NULL);
    gql_store_sv(def, "type", gql_parse_type_reference(aTHX_ p));
    if (p->kind == TOK_EQUALS) {
      gql_advance(aTHX_ p);
      gql_store_sv(def, "default_value", gql_parse_value(aTHX_ p, 1));
    }
    if (p->kind == TOK_AT) {
      gql_store_sv(def, "directives", gql_parse_const_directives(aTHX_ p));
    }
    if (SvOK(description)) {
      HV *description_hv = (HV *)SvRV(description);
      SV **description_svp = hv_fetch(description_hv, "description", 11, 0);
      gql_store_sv(def, "description", newSVsv(*description_svp));
      SvREFCNT_dec(description);
    }
    if (p->validation_errors) {
      STRLEN name_len;
      const char *name_str = SvPV(name, name_len);
      if (hv_exists(hv, name_str, (I32)name_len)) {
        HV *error_hv = newHV();
        AV *locations_av = newAV();
        SV *message = newSVpvf("Variable '$%s' is defined more than once.", name_str);
        gql_store_sv(error_hv, "message", message);
        av_push(locations_av, gql_make_current_location(aTHX_ p));
        gql_store_sv(error_hv, "locations", newRV_noinc((SV *)locations_av));
        av_push(p->validation_errors, newRV_noinc((SV *)error_hv));
      }
    }
    gql_store_sv(hv, SvPV_nolen(name), newRV_noinc((SV *)def));
    SvREFCNT_dec(name);
  }
  gql_expect(aTHX_ p, TOK_RPAREN, NULL);
  {
    HV *wrap = newHV();
    gql_store_sv(wrap, "variables", newRV_noinc((SV *)hv));
    return newRV_noinc((SV *)wrap);
  }
}

static SV *
gql_parse_type_reference(pTHX_ gql_parser_t *p) {
  SV *type_sv;
  if (p->kind == TOK_LBRACKET) {
    gql_advance(aTHX_ p);
    type_sv = gql_parse_type_reference(aTHX_ p);
    gql_expect(aTHX_ p, TOK_RBRACKET, NULL);
    type_sv = gql_make_type_wrapper(aTHX_ type_sv, "list");
  } else {
    type_sv = gql_parse_name(aTHX_ p, "Expected name");
  }
  if (p->kind == TOK_BANG) {
    gql_advance(aTHX_ p);
    type_sv = gql_make_type_wrapper(aTHX_ type_sv, "non_null");
  }
  return type_sv;
}

static SV *
gql_parse_operation_definition(pTHX_ gql_parser_t *p, SV *description) {
  HV *hv = newHV();
  if (p->kind == TOK_LBRACE) {
    SV *sel = gql_parse_selection_set(aTHX_ p);
    HV *selhv = (HV *)SvRV(sel);
    SV **svp = hv_fetch(selhv, "selections", 10, 0);
    gql_store_sv(hv, "selections", newSVsv(*svp));
    SvREFCNT_dec(sel);
    gql_store_sv(hv, "kind", newSVpv("operation", 0));
    gql_store_current_location(aTHX_ p, hv);
    return newRV_noinc((SV *)hv);
  }
  if (!(gql_peek_name(p, "query") || gql_peek_name(p, "mutation") || gql_peek_name(p, "subscription"))) {
    gql_throw(aTHX_ p, p->tok_start, "Expected executable definition");
  }
  gql_store_sv(hv, "operationType", gql_copy_token_sv(aTHX_ p));
  gql_advance(aTHX_ p);
  if (p->kind == TOK_NAME) {
    gql_store_sv(hv, "name", gql_parse_name(aTHX_ p, "Expected name"));
  }
  if (p->kind == TOK_LPAREN) {
    SV *vars = gql_parse_variable_definitions(aTHX_ p);
    HV *varhv = (HV *)SvRV(vars);
    SV **svp = hv_fetch(varhv, "variables", 9, 0);
    gql_store_sv(hv, "variables", newSVsv(*svp));
    SvREFCNT_dec(vars);
  }
  if (p->kind == TOK_AT) {
    gql_store_sv(hv, "directives", gql_parse_directives(aTHX_ p));
  }
  {
    SV *sel = gql_parse_selection_set(aTHX_ p);
    HV *selhv = (HV *)SvRV(sel);
    SV **svp = hv_fetch(selhv, "selections", 10, 0);
    gql_store_sv(hv, "selections", newSVsv(*svp));
    SvREFCNT_dec(sel);
  }
  if (SvOK(description)) {
    HV *description_hv = (HV *)SvRV(description);
    SV **description_svp = hv_fetch(description_hv, "description", 11, 0);
    gql_store_sv(hv, "description", newSVsv(*description_svp));
    SvREFCNT_dec(description);
  }
  gql_store_sv(hv, "kind", newSVpv("operation", 0));
  gql_store_current_location(aTHX_ p, hv);
  return newRV_noinc((SV *)hv);
}

static SV *
gql_parse_fragment_definition(pTHX_ gql_parser_t *p, SV *description) {
  HV *hv = newHV();
  gql_advance(aTHX_ p);
  gql_store_sv(hv, "name", gql_parse_fragment_name(aTHX_ p));
  if (!gql_peek_name(p, "on")) {
    gql_throw(aTHX_ p, p->tok_start, "Expected \"on\"");
  }
  gql_advance(aTHX_ p);
  gql_store_sv(hv, "on", gql_parse_name(aTHX_ p, "Expected name"));
  if (p->kind == TOK_AT) {
    gql_store_sv(hv, "directives", gql_parse_directives(aTHX_ p));
  }
  {
    SV *sel = gql_parse_selection_set(aTHX_ p);
    HV *selhv = (HV *)SvRV(sel);
    SV **svp = hv_fetch(selhv, "selections", 10, 0);
    gql_store_sv(hv, "selections", newSVsv(*svp));
    SvREFCNT_dec(sel);
  }
  if (SvOK(description)) {
    HV *description_hv = (HV *)SvRV(description);
    SV **description_svp = hv_fetch(description_hv, "description", 11, 0);
    gql_store_sv(hv, "description", newSVsv(*description_svp));
    SvREFCNT_dec(description);
  }
  gql_store_sv(hv, "kind", newSVpv("fragment", 0));
  gql_store_current_location(aTHX_ p, hv);
  return newRV_noinc((SV *)hv);
}

static SV *
gql_parse_description(pTHX_ gql_parser_t *p) {
  HV *hv;
  SV *desc;
  if (!(p->kind == TOK_STRING || p->kind == TOK_BLOCK_STRING)) {
    return &PL_sv_undef;
  }
  desc = gql_copy_value_sv(aTHX_ p);
  gql_advance(aTHX_ p);
  hv = newHV();
  gql_store_sv(hv, "description", desc);
  return newRV_noinc((SV *)hv);
}

static SV *
gql_parse_input_value_definition(pTHX_ gql_parser_t *p) {
  SV *description = gql_parse_description(aTHX_ p);
  HV *def = newHV();
  SV *name = gql_parse_name(aTHX_ p, "Expected name");
  gql_expect(aTHX_ p, TOK_COLON, NULL);
  gql_store_sv(def, "type", gql_parse_type_reference(aTHX_ p));
  if (p->kind == TOK_EQUALS) {
    gql_advance(aTHX_ p);
    gql_store_sv(def, "default_value", gql_parse_value(aTHX_ p, 1));
  }
  if (p->kind == TOK_AT) {
    gql_store_sv(def, "directives", gql_parse_const_directives(aTHX_ p));
  }
  if (SvOK(description)) {
    HV *dhv = (HV *)SvRV(description);
    SV **svp = hv_fetch(dhv, "description", 11, 0);
    gql_store_sv(def, "description", newSVsv(*svp));
  }
  {
    HV *wrap = newHV();
    gql_store_sv(wrap, SvPV_nolen(name), newRV_noinc((SV *)def));
    SvREFCNT_dec(name);
    if (SvOK(description)) {
      SvREFCNT_dec(description);
    }
    return newRV_noinc((SV *)wrap);
  }
}

static SV *
gql_parse_arguments_definition(pTHX_ gql_parser_t *p) {
  HV *args = newHV();
  gql_expect(aTHX_ p, TOK_LPAREN, NULL);
  if (p->kind == TOK_RPAREN) {
    gql_throw_expected_message(aTHX_ p, p->tok_start, "Expected name");
  }
  while (p->kind != TOK_RPAREN) {
    SV *item = gql_parse_input_value_definition(aTHX_ p);
    HV *ihv = (HV *)SvRV(item);
    hv_iterinit(ihv);
    HE *he = hv_iternext(ihv);
    if (p->validation_errors && hv_exists(args, HeKEY(he), HeKLEN(he))) {
      HV *error_hv = newHV();
      gql_store_sv(error_hv, "message", newSVpvf(
        "Argument '%s' is defined more than once.", HeKEY(he)
      ));
      av_push(p->validation_errors, newRV_noinc((SV *)error_hv));
    }
    gql_store_sv(args, HeKEY(he), newSVsv(HeVAL(he)));
    SvREFCNT_dec(item);
  }
  gql_expect(aTHX_ p, TOK_RPAREN, NULL);
  {
    HV *wrap = newHV();
    gql_store_sv(wrap, "args", newRV_noinc((SV *)args));
    return newRV_noinc((SV *)wrap);
  }
}

static SV *
gql_parse_field_definition(pTHX_ gql_parser_t *p) {
  SV *description = gql_parse_description(aTHX_ p);
  HV *def = newHV();
  SV *name = gql_parse_name(aTHX_ p, "Expected name");
  if (p->kind == TOK_LPAREN) {
    SV *args = gql_parse_arguments_definition(aTHX_ p);
    HV *ahv = (HV *)SvRV(args);
    SV **svp = hv_fetch(ahv, "args", 4, 0);
    gql_store_sv(def, "args", newSVsv(*svp));
    SvREFCNT_dec(args);
  }
  gql_expect(aTHX_ p, TOK_COLON, NULL);
  gql_store_sv(def, "type", gql_parse_type_reference(aTHX_ p));
  if (p->kind == TOK_AT) {
    gql_store_sv(def, "directives", gql_parse_const_directives(aTHX_ p));
  }
  if (SvOK(description)) {
    HV *dhv = (HV *)SvRV(description);
    SV **svp = hv_fetch(dhv, "description", 11, 0);
    gql_store_sv(def, "description", newSVsv(*svp));
  }
  {
    HV *wrap = newHV();
    gql_store_sv(wrap, SvPV_nolen(name), newRV_noinc((SV *)def));
    SvREFCNT_dec(name);
    if (SvOK(description)) {
      SvREFCNT_dec(description);
    }
    return newRV_noinc((SV *)wrap);
  }
}

static SV *
gql_parse_schema_definition(pTHX_ gql_parser_t *p) {
  return gql_parse_schema_definition_extended(aTHX_ p, 0);
}

static SV *
gql_parse_schema_definition_extended(pTHX_ gql_parser_t *p, int allow_empty_body) {
  HV *hv = newHV();
  int had_directives = 0;
  gql_advance(aTHX_ p);
  if (p->kind == TOK_AT) {
    had_directives = 1;
    gql_store_sv(hv, "directives", gql_parse_const_directives(aTHX_ p));
  }
  if (allow_empty_body && p->kind != TOK_LBRACE) {
    gql_store_sv(hv, "kind", newSVpv("schema", 0));
    if (had_directives) {
      gql_store_endline_location(aTHX_ p, hv);
    } else {
      gql_store_current_location(aTHX_ p, hv);
    }
    return newRV_noinc((SV *)hv);
  }
  gql_expect(aTHX_ p, TOK_LBRACE, NULL);
  if (p->kind == TOK_RBRACE) {
    gql_throw(aTHX_ p, p->tok_start, "Expected name");
  }
  while (p->kind != TOK_RBRACE) {
    SV *op_name = gql_parse_name(aTHX_ p, "Expected name");
    gql_expect(aTHX_ p, TOK_COLON, NULL);
    gql_store_sv(hv, SvPV_nolen(op_name), gql_parse_name(aTHX_ p, "Expected name"));
  }
  gql_expect(aTHX_ p, TOK_RBRACE, NULL);
  gql_store_sv(hv, "kind", newSVpv("schema", 0));
  gql_store_endline_location(aTHX_ p, hv);
  return newRV_noinc((SV *)hv);
}

static SV *
gql_parse_scalar_type_definition(pTHX_ gql_parser_t *p) {
  HV *hv = newHV();
  int had_directives = 0;
  gql_advance(aTHX_ p);
  gql_store_sv(hv, "name", gql_parse_name(aTHX_ p, "Expected name"));
  if (p->kind == TOK_AT) {
    had_directives = 1;
    gql_store_sv(hv, "directives", gql_parse_const_directives(aTHX_ p));
  }
  gql_store_sv(hv, "kind", newSVpv("scalar", 0));
  if (had_directives) {
    gql_store_endline_location(aTHX_ p, hv);
  } else {
    gql_store_current_location(aTHX_ p, hv);
  }
  return newRV_noinc((SV *)hv);
}

static SV *
gql_parse_object_type_definition(pTHX_ gql_parser_t *p, const char *kind) {
  HV *hv = newHV();
  int had_directives = 0;
  int had_body = 0;
  gql_advance(aTHX_ p);
  gql_store_sv(hv, "name", gql_parse_name(aTHX_ p, "Expected name"));
  if ((strcmp(kind, "type") == 0 || strcmp(kind, "interface") == 0)
      && gql_peek_name(p, "implements")) {
    AV *interfaces = newAV();
    gql_advance(aTHX_ p);
    if (p->kind == TOK_AMP) {
      gql_advance(aTHX_ p);
    }
    av_push(interfaces, gql_parse_name(aTHX_ p, "Expected name"));
    while (p->kind == TOK_AMP) {
      gql_advance(aTHX_ p);
      av_push(interfaces, gql_parse_name(aTHX_ p, "Expected name"));
    }
    gql_store_sv(hv, "interfaces", newRV_noinc((SV *)interfaces));
  }
  if (p->kind == TOK_AT) {
    had_directives = 1;
    gql_store_sv(hv, "directives", gql_parse_const_directives(aTHX_ p));
  }
  {
    HV *fields = newHV();
    if (p->kind == TOK_LBRACE) {
      had_body = 1;
      gql_advance(aTHX_ p);
      if (p->kind == TOK_RBRACE) {
        gql_throw(aTHX_ p, p->tok_start, "Expected name");
      }
      while (p->kind != TOK_RBRACE) {
        SV *item = (strcmp(kind, "input") == 0)
          ? gql_parse_input_value_definition(aTHX_ p)
          : gql_parse_field_definition(aTHX_ p);
        HV *ihv = (HV *)SvRV(item);
        hv_iterinit(ihv);
        HE *he = hv_iternext(ihv);
        if (p->validation_errors && hv_exists(fields, HeKEY(he), HeKLEN(he))) {
          HV *error_hv = newHV();
          gql_store_sv(error_hv, "message", newSVpvf(
            "%s field '%s' is defined more than once.",
            strcmp(kind, "input") == 0 ? "Input" : "Type", HeKEY(he)
          ));
          av_push(p->validation_errors, newRV_noinc((SV *)error_hv));
        }
        gql_store_sv(fields, HeKEY(he), newSVsv(HeVAL(he)));
        SvREFCNT_dec(item);
      }
      gql_expect(aTHX_ p, TOK_RBRACE, NULL);
    }
    gql_store_sv(hv, "fields", newRV_noinc((SV *)fields));
  }
  gql_store_sv(hv, "kind", newSVpv(kind, 0));
  if (had_directives || had_body) {
    gql_store_endline_location(aTHX_ p, hv);
  } else {
    gql_store_current_location(aTHX_ p, hv);
  }
  return newRV_noinc((SV *)hv);
}

static SV *
gql_parse_union_type_definition(pTHX_ gql_parser_t *p) {
  HV *hv = newHV();
  AV *types = newAV();
  int had_directives = 0;
  int had_members = 0;
  gql_advance(aTHX_ p);
  gql_store_sv(hv, "name", gql_parse_name(aTHX_ p, "Expected name"));
  if (p->kind == TOK_AT) {
    had_directives = 1;
    gql_store_sv(hv, "directives", gql_parse_const_directives(aTHX_ p));
  }
  if (p->kind == TOK_EQUALS) {
    had_members = 1;
    gql_advance(aTHX_ p);
    if (p->kind == TOK_PIPE) {
      gql_advance(aTHX_ p);
    }
    if (p->kind != TOK_NAME) {
      gql_throw_expected_message(aTHX_ p, p->tok_start, "Expected name");
    }
    av_push(types, gql_parse_name(aTHX_ p, "Expected name"));
    while (p->kind == TOK_PIPE) {
      gql_advance(aTHX_ p);
      av_push(types, gql_parse_name(aTHX_ p, "Expected name"));
    }
  }
  if (had_members) {
    gql_store_sv(hv, "types", newRV_noinc((SV *)types));
  } else {
    SvREFCNT_dec((SV *)types);
  }
  gql_store_sv(hv, "kind", newSVpv("union", 0));
  if (had_members) {
    gql_store_current_location(aTHX_ p, hv);
  } else if (had_directives) {
    gql_store_endline_location(aTHX_ p, hv);
  } else {
    gql_store_current_location(aTHX_ p, hv);
  }
  return newRV_noinc((SV *)hv);
}

static SV *
gql_parse_enum_type_definition(pTHX_ gql_parser_t *p) {
  HV *hv = newHV();
  HV *values = newHV();
  int had_directives = 0;
  int had_body = 0;
  gql_advance(aTHX_ p);
  gql_store_sv(hv, "name", gql_parse_name(aTHX_ p, "Expected name"));
  if (p->kind == TOK_AT) {
    had_directives = 1;
    gql_store_sv(hv, "directives", gql_parse_const_directives(aTHX_ p));
  }
  if (p->kind == TOK_LBRACE) {
    had_body = 1;
    gql_advance(aTHX_ p);
    if (p->kind == TOK_RBRACE) {
      gql_throw(aTHX_ p, p->tok_start, "Expected name");
    }
    while (p->kind != TOK_RBRACE) {
      SV *description = gql_parse_description(aTHX_ p);
      HV *value_hv = newHV();
      SV *name = gql_parse_name(aTHX_ p, "Expected name");
      const char *name_str = SvPV_nolen(name);
      if (strEQ(name_str, "true") || strEQ(name_str, "false") || strEQ(name_str, "null")) {
        gql_throw(aTHX_ p, p->tok_start > 0 ? p->tok_start - 1 : p->tok_start, "Invalid enum value");
      }
      if (p->kind == TOK_AT) {
        gql_store_sv(value_hv, "directives", gql_parse_const_directives(aTHX_ p));
      }
      if (p->validation_errors && hv_exists(values, name_str, (I32)SvCUR(name))) {
        HV *error_hv = newHV();
        gql_store_sv(error_hv, "message", newSVpvf(
          "Enum value '%s' is defined more than once.", name_str
        ));
        av_push(p->validation_errors, newRV_noinc((SV *)error_hv));
      }
      if (SvOK(description)) {
        HV *dhv = (HV *)SvRV(description);
        SV **svp = hv_fetch(dhv, "description", 11, 0);
        gql_store_sv(value_hv, "description", newSVsv(*svp));
      }
      gql_store_sv(values, name_str, newRV_noinc((SV *)value_hv));
      SvREFCNT_dec(name);
      if (SvOK(description)) {
        SvREFCNT_dec(description);
      }
    }
    gql_expect(aTHX_ p, TOK_RBRACE, NULL);
  }
  gql_store_sv(hv, "values", newRV_noinc((SV *)values));
  gql_store_sv(hv, "kind", newSVpv("enum", 0));
  if (had_directives || had_body) {
    gql_store_endline_location(aTHX_ p, hv);
  } else {
    gql_store_current_location(aTHX_ p, hv);
  }
  return newRV_noinc((SV *)hv);
}

static SV *
gql_parse_directive_definition(pTHX_ gql_parser_t *p) {
  HV *hv = newHV();
  AV *locations = newAV();
  gql_advance(aTHX_ p);
  gql_expect(aTHX_ p, TOK_AT, NULL);
  gql_store_sv(hv, "name", gql_parse_name(aTHX_ p, "Expected name"));
  if (p->kind == TOK_LPAREN) {
    SV *args = gql_parse_arguments_definition(aTHX_ p);
    HV *ahv = (HV *)SvRV(args);
    SV **svp = hv_fetch(ahv, "args", 4, 0);
    gql_store_sv(hv, "args", newSVsv(*svp));
    SvREFCNT_dec(args);
  }
  if (gql_peek_name(p, "repeatable")) {
    gql_store_sv(hv, "repeatable", newSViv(1));
    gql_advance(aTHX_ p);
  }
  if (!gql_peek_name(p, "on")) {
    gql_throw(aTHX_ p, p->tok_start, "Expected \"on\"");
  }
  gql_advance(aTHX_ p);
  if (p->kind == TOK_PIPE) {
    gql_advance(aTHX_ p);
  }
  if (p->kind != TOK_NAME) {
    gql_throw_expected_message(aTHX_ p, p->tok_start, "Expected name");
  }
  av_push(locations, gql_parse_name(aTHX_ p, "Expected name"));
  while (p->kind == TOK_PIPE) {
    gql_advance(aTHX_ p);
    av_push(locations, gql_parse_name(aTHX_ p, "Expected name"));
  }
  gql_store_sv(hv, "locations", newRV_noinc((SV *)locations));
  gql_store_sv(hv, "kind", newSVpv("directive", 0));
  gql_store_endline_location(aTHX_ p, hv);
  return newRV_noinc((SV *)hv);
}

static SV *
gql_parse_type_system_definition(pTHX_ gql_parser_t *p, SV *description) {
  SV *node;
  int is_extend = 0;
  if (gql_peek_name(p, "extend")) {
    is_extend = 1;
    gql_advance(aTHX_ p);
  }
  if (gql_peek_name(p, "schema")) {
    node = is_extend
      ? gql_parse_schema_definition_extended(aTHX_ p, 1)
      : gql_parse_schema_definition(aTHX_ p);
  } else if (gql_peek_name(p, "scalar")) {
    node = gql_parse_scalar_type_definition(aTHX_ p);
  } else if (gql_peek_name(p, "type")) {
    node = gql_parse_object_type_definition(aTHX_ p, "type");
  } else if (gql_peek_name(p, "interface")) {
    node = gql_parse_object_type_definition(aTHX_ p, "interface");
  } else if (gql_peek_name(p, "input")) {
    node = gql_parse_object_type_definition(aTHX_ p, "input");
  } else if (gql_peek_name(p, "union")) {
    node = gql_parse_union_type_definition(aTHX_ p);
  } else if (gql_peek_name(p, "enum")) {
    node = gql_parse_enum_type_definition(aTHX_ p);
  } else if (gql_peek_name(p, "directive")) {
    node = gql_parse_directive_definition(aTHX_ p);
  } else {
    gql_throw(aTHX_ p, p->tok_start, "Expected type system definition");
    return &PL_sv_undef;
  }
  if (is_extend) {
    HV *node_hv = (HV *)SvRV(node);
    SV **kind_svp = hv_fetch(node_hv, "kind", 4, 0);
    int has_content = 0;
    const char *array_keys[] = { "directives", "interfaces", "types" };
    const I32 array_lens[] = { 10, 10, 5 };
    const char *hash_keys[] = { "fields", "values" };
    const I32 hash_lens[] = { 6, 6 };
    int i;
    for (i = 0; i < 3 && !has_content; i++) {
      SV **svp = hv_fetch(node_hv, array_keys[i], array_lens[i], 0);
      has_content = svp && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVAV
        && av_len((AV *)SvRV(*svp)) >= 0;
    }
    for (i = 0; i < 2 && !has_content; i++) {
      SV **svp = hv_fetch(node_hv, hash_keys[i], hash_lens[i], 0);
      has_content = svp && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVHV
        && HvTOTALKEYS((HV *)SvRV(*svp)) > 0;
    }
    if (kind_svp && SvOK(*kind_svp) && strEQ(SvPV_nolen(*kind_svp), "schema")) {
      has_content = has_content || hv_exists(node_hv, "query", 5)
        || hv_exists(node_hv, "mutation", 8)
        || hv_exists(node_hv, "subscription", 12);
    }
    if (!has_content) {
      SvREFCNT_dec(node);
      gql_throw(aTHX_ p, p->tok_start, "Type system extension must add a directive or member");
    }
    gql_store_sv(node_hv, "extension", newSViv(1));
  }
  if (SvOK(description)) {
    HV *node_hv = (HV *)SvRV(node);
    HV *desc_hv = (HV *)SvRV(description);
    SV **svp = hv_fetch(desc_hv, "description", 11, 0);
    gql_store_sv(node_hv, "description", newSVsv(*svp));
  }
  if (SvOK(description)) {
    SvREFCNT_dec(description);
  }
  return node;
}

static SV *
gql_parse_definition(pTHX_ gql_parser_t *p) {
  if (p->kind == TOK_LBRACE) {
    return gql_parse_operation_definition(aTHX_ p, &PL_sv_undef);
  }
  if (p->kind == TOK_STRING || p->kind == TOK_BLOCK_STRING) {
    SV *description = gql_parse_description(aTHX_ p);
    if (gql_peek_name(p, "fragment")) {
      return gql_parse_fragment_definition(aTHX_ p, description);
    }
    if (gql_peek_name(p, "query") || gql_peek_name(p, "mutation") || gql_peek_name(p, "subscription")) {
      return gql_parse_operation_definition(aTHX_ p, description);
    }
    return gql_parse_type_system_definition(aTHX_ p, description);
  }
  if (gql_peek_name(p, "fragment")) {
    return gql_parse_fragment_definition(aTHX_ p, &PL_sv_undef);
  }
  if (gql_peek_name(p, "query") || gql_peek_name(p, "mutation") || gql_peek_name(p, "subscription")) {
    return gql_parse_operation_definition(aTHX_ p, &PL_sv_undef);
  }
  return gql_parse_type_system_definition(aTHX_ p, &PL_sv_undef);
}

static AV *
gql_parse_definitions(pTHX_ gql_parser_t *p) {
  AV *av = newAV();
  while (p->kind != TOK_EOF) {
    av_push(av, gql_parse_definition(aTHX_ p));
  }
  return av;
}

/* A token cannot occupy less than one source byte.  Only documents large
 * enough to possibly exceed the token cap need this allocation-free
 * preflight.  Without it, an extremely wide document can exhaust memory
 * building its AST before the incremental lexer limit is reached. */
static void
gql_preflight_token_limit(pTHX_ SV *source_sv) {
  gql_parser_t scan;

  if (SvCUR(source_sv) <= GQL_PARSER_MAX_TOKENS) {
    return;
  }

  gql_parser_init(aTHX_ &scan, source_sv, 1);
  do {
    gql_advance(aTHX_ &scan);
  } while (scan.kind != TOK_EOF);
  gql_parser_invalidate(&scan);
}

static SV *
gql_parse_document(pTHX_ SV *source_sv, SV *no_location_sv) {
  gql_parser_t p;
  SV *ret;

  ENTER;
  SAVETMPS;
  gql_preflight_token_limit(aTHX_ source_sv);
  gql_parser_init(aTHX_ &p, source_sv, SvTRUE(no_location_sv) ? 1 : 0);
  gql_advance(aTHX_ &p);
  ret = newRV_noinc((SV *)gql_parse_definitions(aTHX_ &p));
  gql_parser_invalidate(&p);
  FREETMPS;
  LEAVE;
  return ret;
}

static SV *
gql_parse_document_for_validation(
  pTHX_ SV *source_sv, SV *no_location_sv, AV *validation_errors
) {
  gql_parser_t p;
  SV *ret;

  ENTER;
  SAVETMPS;
  gql_preflight_token_limit(aTHX_ source_sv);
  gql_parser_init(aTHX_ &p, source_sv, SvTRUE(no_location_sv) ? 1 : 0);
  p.validation_errors = validation_errors;
  gql_advance(aTHX_ &p);
  ret = newRV_noinc((SV *)gql_parse_definitions(aTHX_ &p));
  gql_parser_invalidate(&p);
  FREETMPS;
  LEAVE;
  return ret;
}
