#ifndef EX_OP_KW_H
#define EX_OP_KW_H

/* The op keyword. It needs parse_block, so it is there from 5.14. */

#define EO_KW_KEY "Ex::Op/op"

#if PERL_VERSION_GE(5,14,0)

static Perl_keyword_plugin_t eo_next_keyword_plugin;

static bool
eo_kw_in_scope(pTHX)
{
    HV *hints = GvHV(PL_hintgv);
    SV **ent = hints ? hv_fetchs(hints, EO_KW_KEY, 0) : NULL;
    return ent && SvTRUE(*ent);
}

static bool
eo_kw_word_char(char c, bool utf8, bool first)
{
    if (utf8 && (U8)c >= 0x80)
        return TRUE;
    return first ? (isALPHA(c) || c == '_') : (isWORDCHAR(c) ? TRUE : FALSE);
}

/* A name, or a package-qualified name, at the parse position. NULL, with
 * nothing read, when there is none. */
static SV *
eo_kw_ident(pTHX_ bool qualified)
{
    char *s     = PL_parser->bufptr;
    char *start = s;
    char *end   = PL_parser->bufend;
    bool utf8   = lex_bufutf8() ? TRUE : FALSE;

    if (s >= end || !eo_kw_word_char(*s, utf8, TRUE))
        return NULL;
    while (s < end) {
        if (eo_kw_word_char(*s, utf8, FALSE)) {
            s++;
        }
        else if (qualified && s + 2 < end && s[0] == ':' && s[1] == ':'
                 && eo_kw_word_char(s[2], utf8, TRUE)) {
            s += 2;
        }
        else {
            break;
        }
    }
    lex_read_to(s);
    return newSVpvn_flags(start, s - start, SVs_TEMP | (utf8 ? SVf_UTF8 : 0));
}

static OP *
eo_kw_parse(pTHX_ SV *name)
{
    SV *text = sv_2mortal(newSVpvs("{"));
    AV *params = (AV *)sv_2mortal((SV *)newAV());
    HV *seen = (HV *)sv_2mortal((SV *)newHV());
    I32 floor, c;
    OP *body;
    CV *cv;

    if (lex_bufutf8())
        SvUTF8_on(text);

    lex_read_space(0);
    if (lex_peek_unichar(0) == '(') {
        lex_read_unichar(0);
        for (;;) {
            SV *pname;
            lex_read_space(0);
            c = lex_peek_unichar(0);
            if (c == ')') {
                lex_read_unichar(0);
                break;
            }
            if (c != '$')
                croak("Ex::Op: the parameters of op %" SVf " must be scalars, like $x",
                      SVfARG(name));
            lex_read_unichar(0);
            if (!(pname = eo_kw_ident(aTHX_ FALSE)))
                croak("Ex::Op: a parameter of op %" SVf " needs a name after the $",
                      SVfARG(name));
            if (hv_exists_ent(seen, pname, 0))
                croak("Ex::Op: op %" SVf " has the parameter $%" SVf " twice",
                      SVfARG(name), SVfARG(pname));
            (void)hv_store_ent(seen, pname, &PL_sv_yes, 0);
            av_push(params, newSVsv(pname));
            lex_read_space(0);
            c = lex_peek_unichar(0);
            if (c == ',') {
                lex_read_unichar(0);
                continue;
            }
            if (c == ')') {
                lex_read_unichar(0);
                break;
            }
            croak("Ex::Op: expected , or ) in the parameters of op %" SVf, SVfARG(name));
        }
    }

    lex_read_space(0);
    if (lex_peek_unichar(0) != '{')
        croak("Ex::Op: op %" SVf " needs a block", SVfARG(name));
    lex_read_unichar(0);

    if (av_len(params) >= 0) {
        SSize_t i, top = av_len(params);
        sv_catpvs(text, "my(");
        for (i = 0; i <= top; i++) {
            if (i)
                sv_catpvs(text, ",");
            sv_catpvs(text, "$");
            sv_catsv(text, *av_fetch(params, i, 0));
        }
        sv_catpvs(text, ")=@_;");
    }
    lex_stuff_sv(text, 0);

    floor = start_subparse(FALSE, 0);
    body  = parse_block(0);
    cv    = newATTRSUB(floor, newSVOP(OP_CONST, 0, newSVsv(name)), NULL, NULL, body);

    if (cv && !PL_parser->error_count) {
        eo_op_t *e = eo_register(aTHX_ cv);
        if (!e->accepted && eo_strict_on(aTHX))
            croak("%" SVf " cannot be an op: %s", SVfARG(name), e->why);
    }
    return newOP(OP_NULL, 0);
}

static int
eo_keyword_plugin(pTHX_ char *kw, STRLEN kwlen, OP **op_ptr)
{
    if (kwlen == 2 && kw[0] == 'o' && kw[1] == 'p' && eo_kw_in_scope(aTHX)) {
        SV *name;
        lex_read_space(0);
        if ((name = eo_kw_ident(aTHX_ TRUE))) {
            *op_ptr = eo_kw_parse(aTHX_ name);
            return KEYWORD_PLUGIN_STMT;
        }
    }
    return eo_next_keyword_plugin(aTHX_ kw, kwlen, op_ptr);
}

static void
eo_boot_keyword(pTHX)
{
#  if PERL_VERSION_GE(5,28,0)
    wrap_keyword_plugin(eo_keyword_plugin, &eo_next_keyword_plugin);
#  else
    eo_next_keyword_plugin = PL_keyword_plugin;
    PL_keyword_plugin = eo_keyword_plugin;
#  endif
}

#else

static void
eo_boot_keyword(pTHX)
{
    PERL_UNUSED_CONTEXT;
}

#endif

#endif
