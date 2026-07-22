/*
 * Responsibility: low-level parser utilities, source preprocessing,
 * graphql-js metadata patching, and document-level location helpers.
 */
static void
gql_store_sv(HV *hv, const char *key, SV *value) {
  hv_store(hv, key, (I32)strlen(key), value, 0);
}

static SV *
gql_make_string_sv(pTHX_ gql_parser_t *p, STRLEN start, STRLEN end) {
  SV *sv = newSVpvn(p->src + start, end - start);
  if (p->is_utf8) {
    SvUTF8_on(sv);
  }
  return sv;
}

static SV *
gql_copy_token_sv(pTHX_ gql_parser_t *p) {
  return gql_make_string_sv(aTHX_ p, p->tok_start, p->tok_end);
}

static SV *
gql_call_helper1(pTHX_ const char *subname, SV *arg) {
  dSP;
  int count;
  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(arg);
  PUTBACK;
  count = call_pv(subname, G_SCALAR);
  SPAGAIN;
  if (count != 1) {
    PUTBACK;
    FREETMPS;
    LEAVE;
    croak("Helper %s did not return a scalar", subname);
  }
  SV *ret = newSVsv(POPs);
  PUTBACK;
  FREETMPS;
  LEAVE;
  return ret;
}

static SV *
gql_unescape_string_sv(pTHX_ SV *raw) {
  STRLEN len;
  const char *src = SvPV(raw, len);
  SV *out = newSVpvn("", 0);
  char *dst;
  STRLEN i;
  STRLEN out_len = 0;
  int needs_utf8 = SvUTF8(raw) ? 1 : 0;

  SvGROW(out, len + 1);
  dst = SvPVX(out);

  for (i = 0; i < len; i++) {
    if (src[i] == '\\' && i + 1 < len) {
      char decoded = '\0';
      switch (src[i + 1]) {
        case '"': decoded = '"'; break;
        case '\\': decoded = '\\'; break;
        case '/': decoded = '/'; break;
        case 'b': decoded = '\b'; break;
        case 'f': decoded = '\f'; break;
        case 'n': decoded = '\n'; break;
        case 'r': decoded = '\r'; break;
        case 't': decoded = '\t'; break;
        case 'u': {
          UV codepoint = 0;
          U8 *utf8_end;

          if (i + 5 < len) {
            if (!gql_hex4_to_uv(src + i + 2, &codepoint)) {
              croak("Invalid Unicode escape sequence");
            }

            if (codepoint >= 0xD800 && codepoint <= 0xDBFF &&
                i + 11 < len &&
                src[i + 6] == '\\' &&
                src[i + 7] == 'u') {
              UV low = 0;
              if (!gql_hex4_to_uv(src + i + 8, &low)) {
                croak("Invalid Unicode escape sequence");
              }
              if (low >= 0xDC00 && low <= 0xDFFF) {
                codepoint = 0x10000 + (((codepoint - 0xD800) << 10) | (low - 0xDC00));
                i += 6;
              }
            }

            utf8_end = uvchr_to_utf8((U8 *)(dst + out_len), codepoint);
            out_len += (STRLEN)(utf8_end - (U8 *)(dst + out_len));
            needs_utf8 = 1;
            i += 5;
            continue;
          }
          break;
        }
        default: break;
      }
      if (decoded != '\0') {
        dst[out_len++] = decoded;
        i++;
        continue;
      }
    }
    dst[out_len++] = src[i];
  }

  dst[out_len] = '\0';
  SvCUR_set(out, out_len);

  if (needs_utf8) {
    SvUTF8_on(out);
  }
  return out;
}

static int
gql_hex4_to_uv(const char *src, UV *value) {
  UV parsed = 0;
  I32 i;

  for (i = 0; i < 4; i++) {
    parsed <<= 4;
    if (src[i] >= '0' && src[i] <= '9') {
      parsed |= (UV)(src[i] - '0');
    } else if (src[i] >= 'A' && src[i] <= 'F') {
      parsed |= (UV)(src[i] - 'A' + 10);
    } else if (src[i] >= 'a' && src[i] <= 'f') {
      parsed |= (UV)(src[i] - 'a' + 10);
    } else {
      return 0;
    }
  }

  *value = parsed;
  return 1;
}

static SV *
gql_copy_value_sv(pTHX_ gql_parser_t *p) {
  SV *raw = gql_make_string_sv(aTHX_ p, p->val_start, p->val_end);
  SV *ret;
  if (p->kind == TOK_BLOCK_STRING) {
    ret = gql_call_helper1(aTHX_ "GraphQL::Houtou::Parser::Internal::_block_string_value", raw);
  } else {
    ret = gql_unescape_string_sv(aTHX_ raw);
  }
  SvREFCNT_dec(raw);
  return ret;
}

static void
gql_throw(pTHX_ gql_parser_t *p, STRLEN pos, const char *msg) {
  gql_throw_sv(aTHX_ p, pos, newSVpv(msg, 0));
}

static void
gql_throw_sv(pTHX_ gql_parser_t *p, STRLEN pos, SV *msg) {
  dSP;
  SV *source = gql_make_string_sv(aTHX_ p, 0, p->len);
  SV *err;
  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(source));
  XPUSHs(sv_2mortal(newSVuv((UV)pos)));
  XPUSHs(sv_2mortal(msg));
  PUTBACK;
  call_pv("GraphQL::Houtou::Parser::Internal::_format_error", G_SCALAR);
  SPAGAIN;
  err = newSVsv(POPs);
  PUTBACK;
  FREETMPS;
  LEAVE;
  croak_sv(err);
}

static void
gql_throw_simple_error(pTHX_ const char *msg) {
  HV *err_hv = newHV();
  SV *err_sv = newRV_noinc((SV *)err_hv);

  hv_stores(err_hv, "message", newSVpv(msg, 0));
  sv_bless(err_sv, gv_stashpv("GraphQL::Houtou::Error", GV_ADD));
  croak_sv(sv_2mortal(err_sv));
}

static const char *
gql_expected_token_label(gql_token_kind_t kind) {
  switch (kind) {
    case TOK_BANG: return "\"!\"";
    case TOK_DOLLAR: return "\"$\"";
    case TOK_AMP: return "\"&\"";
    case TOK_LPAREN: return "\"(\"";
    case TOK_RPAREN: return "\")\"";
    case TOK_SPREAD: return "\"...\"";
    case TOK_COLON: return "\":\"";
    case TOK_EQUALS: return "\"=\"";
    case TOK_AT: return "\"@\"";
    case TOK_LBRACKET: return "\"[\"";
    case TOK_RBRACKET: return "\"]\"";
    case TOK_LBRACE: return "\"{\"";
    case TOK_RBRACE: return "\"}\"";
    case TOK_PIPE: return "\"|\"";
    case TOK_NAME: return "name";
    case TOK_INT: return "int";
    case TOK_FLOAT: return "float";
    case TOK_STRING: return "string";
    case TOK_BLOCK_STRING: return "block string";
    case TOK_EOF: return "EOF";
  }
  return "token";
}

static SV *
gql_current_token_desc_sv(pTHX_ gql_parser_t *p) {
  switch (p->kind) {
    case TOK_NAME:
      return newSVpvf("Name \"%.*s\"", (int)(p->tok_end - p->tok_start), p->src + p->tok_start);
    case TOK_INT:
      return newSVpvf("Int \"%.*s\"", (int)(p->tok_end - p->tok_start), p->src + p->tok_start);
    case TOK_FLOAT:
      return newSVpvf("Float \"%.*s\"", (int)(p->tok_end - p->tok_start), p->src + p->tok_start);
    case TOK_STRING:
      return newSVpv("string", 0);
    case TOK_BLOCK_STRING:
      return newSVpv("block string", 0);
    default:
      return newSVpv(gql_expected_token_label(p->kind), 0);
  }
}

static void
gql_throw_expected_message(pTHX_ gql_parser_t *p, STRLEN pos, const char *msg) {
  SV *got = gql_current_token_desc_sv(aTHX_ p);
  SV *full_msg = newSVpvf("%s but got %s", msg, SvPV_nolen(got));
  SvREFCNT_dec(got);
  gql_throw_sv(aTHX_ p, pos, full_msg);
}

static void
gql_throw_expected_token(pTHX_ gql_parser_t *p, gql_token_kind_t kind) {
  char msg[64];

  my_snprintf(msg, sizeof(msg), "Expected %s", gql_expected_token_label(kind));
  gql_throw_expected_message(aTHX_ p, p->tok_start, msg);
}

static void
gql_throw_unexpected_character(pTHX_ gql_parser_t *p, STRLEN pos, unsigned char c) {
  if (c >= 0x20 && c <= 0x7E) {
    gql_throw_sv(aTHX_ p, pos, newSVpvf("Unexpected character \"%c\"", c));
  }
  gql_throw_sv(aTHX_ p, pos, newSVpvf("Unexpected character code %u", (unsigned int)c));
}

static void
gql_parser_skip_quoted_string_raw(const char *src, STRLEN len, STRLEN *pos) {
  if (*pos + 2 < len &&
      src[*pos] == '"' &&
      src[*pos + 1] == '"' &&
      src[*pos + 2] == '"') {
    *pos += 3;
    while (*pos + 2 < len) {
      if (src[*pos] == '"' && src[*pos + 1] == '"' && src[*pos + 2] == '"') {
        *pos += 3;
        return;
      }
      (*pos)++;
    }
    *pos = len;
    return;
  }

  (*pos)++;
  while (*pos < len) {
    char c = src[*pos];
    if (c == '\\') {
      *pos += 2;
      continue;
    }
    (*pos)++;
    if (c == '"') {
      return;
    }
  }
}

static void
gql_parser_skip_delimited_raw(const char *src, STRLEN len, STRLEN *pos, char open, char close) {
  if (*pos >= len || src[*pos] != open) {
    return;
  }

  (*pos)++;
  while (*pos < len) {
    char c = src[*pos];
    if (c == '#') {
      while (*pos < len && src[*pos] != '\n' && src[*pos] != '\r') {
        (*pos)++;
      }
      continue;
    }
    if (c == '"') {
      gql_parser_skip_quoted_string_raw(src, len, pos);
      continue;
    }
    if (c == open) {
      gql_parser_skip_delimited_raw(src, len, pos, open, close);
      continue;
    }
    if (c == '(' && open != '(') {
      gql_parser_skip_delimited_raw(src, len, pos, '(', ')');
      continue;
    }
    if (c == '[' && open != '[') {
      gql_parser_skip_delimited_raw(src, len, pos, '[', ']');
      continue;
    }
    if (c == '{' && open != '{') {
      gql_parser_skip_delimited_raw(src, len, pos, '{', '}');
      continue;
    }
    (*pos)++;
    if (c == close) {
      return;
    }
  }
}

static void
gql_parser_store_hash_key_sv(HV *hv, SV *key_sv, SV *value) {
  STRLEN key_len;
  const char *key = SvPV(key_sv, key_len);
  hv_store(hv, key, (I32)key_len, value, 0);
}

static SV *
gql_parser_clone_with_loc(pTHX_ SV *value, SV *loc_sv) {
  if (!SvROK(value)) {
    return newSVsv(value);
  }

  if (SvTYPE(SvRV(value)) == SVt_PVHV) {
    HV *src_hv = (HV *)SvRV(value);
    HV *dst_hv = newHV();
    HE *he;
    hv_iterinit(src_hv);
    while ((he = hv_iternext(src_hv))) {
      SV *key_sv = hv_iterkeysv(he);
      STRLEN key_len;
      const char *key = SvPV(key_sv, key_len);
      if (key_len == 3 && memcmp(key, "loc", 3) == 0) {
        continue;
      }
      gql_parser_store_hash_key_sv(dst_hv, key_sv, gql_parser_clone_with_loc(aTHX_ hv_iterval(src_hv, he), loc_sv));
    }
    if (loc_sv && SvOK(loc_sv)) {
      gql_store_sv(dst_hv, "loc", newSVsv(loc_sv));
    }
    return newRV_noinc((SV *)dst_hv);
  }

  if (SvTYPE(SvRV(value)) == SVt_PVAV) {
    AV *src_av = (AV *)SvRV(value);
    AV *dst_av = newAV();
    I32 i;
    for (i = 0; i <= av_len(src_av); i++) {
      SV **svp = av_fetch(src_av, i, 0);
      if (!svp) {
        continue;
      }
      av_push(dst_av, gql_parser_clone_with_loc(aTHX_ *svp, loc_sv));
    }
    return newRV_noinc((SV *)dst_av);
  }

  return newSVsv(value);
}

static void
gql_parser_set_loc_node(pTHX_ SV *node_sv, SV *loc_sv) {
  if (!node_sv || !loc_sv || !SvROK(node_sv) || SvTYPE(SvRV(node_sv)) != SVt_PVHV) {
    return;
  }
  hv_stores((HV *)SvRV(node_sv), "loc", SvREFCNT_inc_simple_NN(loc_sv));
}

static void
gql_parser_set_rewritten_loc_node(pTHX_ gql_parser_loc_context_t *ctx, SV *node_sv, UV rewritten_pos) {
  SV *loc_sv;

  if (!ctx || !node_sv) {
    return;
  }
  loc_sv = gql_parser_loc_from_rewritten_pos(aTHX_ ctx, rewritten_pos);
  gql_parser_set_loc_node(aTHX_ node_sv, loc_sv);
  SvREFCNT_dec(loc_sv);
}

static void
gql_parser_set_shared_rewritten_loc_nodes(pTHX_ gql_parser_loc_context_t *ctx, UV rewritten_pos, SV *left_sv, SV *right_sv) {
  SV *loc_sv;

  if (!ctx || !left_sv || !right_sv) {
    return;
  }
  loc_sv = gql_parser_loc_from_rewritten_pos(aTHX_ ctx, rewritten_pos);
  gql_parser_set_loc_node(aTHX_ left_sv, loc_sv);
  gql_parser_set_loc_node(aTHX_ right_sv, loc_sv);
  SvREFCNT_dec(loc_sv);
}
