#ifndef LOO_DUMP_H
#define LOO_DUMP_H

/* ── Forward declarations ─────────────────────────────────────── */

static void  ddc_style_init(DDCStyle *style);
static void  ddc_style_from_hv(pTHX_ DDCStyle *style, HV *config);
static void  ddc_style_destroy(pTHX_ DDCStyle *style);
static SV *  ddc_dump(pTHX_ SV *val, const char *name, DDCStyle *style, int depth);
static void  ddc_dump_sv(pTHX_ SV *val, DDCStyle *style, int depth);
static void  ddc_dump_av(pTHX_ AV *av, DDCStyle *style, int depth);
static void  ddc_dump_hv(pTHX_ HV *hv, DDCStyle *style, int depth);
static void  ddc_dump_ref(pTHX_ SV *rv, DDCStyle *style, int depth);
static void  ddc_dump_glob(pTHX_ SV *val, DDCStyle *style, int depth);
static const char * ddc_indent_string(DDCStyle *style, int depth);
static int   ddc_seen_check(pTHX_ SV *val, const char *name, DDCStyle *style);
static void  ddc_emit_pad(pTHX_ DDCStyle *style);

/* ── Helpers ──────────────────────────────────────────────────── */

/* Fetch a string key from an HV, return NULL if missing */
static const char *
ddc_hv_fetch_pv(pTHX_ HV *hv, const char *key, STRLEN klen)
{
    SV **svp = hv_fetch(hv, key, klen, 0);
    if (svp && SvOK(*svp)) {
        STRLEN len;
        return SvPV(*svp, len);
    }
    return NULL;
}

/* Fetch an integer key from an HV, return default if missing */
static int
ddc_hv_fetch_iv(pTHX_ HV *hv, const char *key, STRLEN klen, int def)
{
    SV **svp = hv_fetch(hv, key, klen, 0);
    if (svp && SvOK(*svp))
        return SvIV(*svp);
    return def;
}

/* ── ddc_style_init ───────────────────────────────────────────── */

static void
ddc_style_init(DDCStyle *style)
{
    Zero(style, 1, DDCStyle);

    style->indent      = 2;
    style->indent_width = 2;
    style->indent_char = ' ';
    style->maxdepth    = 0;
    style->maxrecurse  = 1000;
    style->terse       = 0;
    style->purity      = 0;
    style->useqq       = 0;
    style->quotekeys   = 1;
    style->sortkeys    = 0;
    style->sortkeys_cb = NULL;
    style->trailingcomma = 0;
    style->deepcopy    = 0;
    style->deparse     = 0;
    style->sparseseen  = 0;
    style->pad         = "";
    style->varname     = "VAR";
    style->pair        = " => ";
    style->bless_str   = "bless";
    style->freezer     = "";
    style->toaster     = "";
    style->use_colour  = 0;
    style->c_reset     = "\033[0m";

    /* All colour pointers start NULL (no colour) */
    style->c_string_fg = NULL;   style->c_string_bg = NULL;
    style->c_number_fg = NULL;   style->c_number_bg = NULL;
    style->c_key_fg    = NULL;   style->c_key_bg    = NULL;
    style->c_brace_fg  = NULL;   style->c_brace_bg  = NULL;
    style->c_bracket_fg= NULL;   style->c_bracket_bg= NULL;
    style->c_paren_fg  = NULL;   style->c_paren_bg  = NULL;
    style->c_arrow_fg  = NULL;   style->c_arrow_bg  = NULL;
    style->c_comma_fg  = NULL;   style->c_comma_bg  = NULL;
    style->c_undef_fg  = NULL;   style->c_undef_bg  = NULL;
    style->c_blessed_fg= NULL;   style->c_blessed_bg= NULL;
    style->c_regex_fg  = NULL;   style->c_regex_bg  = NULL;
    style->c_code_fg   = NULL;   style->c_code_bg   = NULL;
    style->c_variable_fg=NULL;   style->c_variable_bg=NULL;
    style->c_quote_fg  = NULL;   style->c_quote_bg  = NULL;
    style->c_keyword_fg= NULL;   style->c_keyword_bg= NULL;
    style->c_operator_fg=NULL;   style->c_operator_bg=NULL;
    style->c_comment_fg= NULL;   style->c_comment_bg= NULL;

    /* Internal state — allocated lazily or in ddc_dump entry */
    style->seen  = NULL;
    style->level = 0;
    style->post  = NULL;
    style->out   = NULL;
}

/* ── ddc_style_from_hv ────────────────────────────────────────── */
/* Populate a DDCStyle from the Perl config hash passed by Loo.pm */

#define RESOLVE_COLOUR(field, key)                                        \
    do {                                                                  \
        SV **svp = hv_fetch(config, key, strlen(key), 0);                \
        style->field = (svp && SvOK(*svp))                               \
            ? ddc_resolve_colour(aTHX_ *svp, strstr(key, "_bg") != NULL) \
            : NULL;                                                       \
    } while(0)

static void
ddc_style_from_hv(pTHX_ DDCStyle *style, HV *config)
{
    const char *pv;
    SV **svp;

    ddc_style_init(style);

    /* Data::Dumper compat options */
    style->indent      = ddc_hv_fetch_iv(aTHX_ config, "indent", 6, 2);
    style->indent_width = ddc_hv_fetch_iv(aTHX_ config, "indent_width", 12, 2);
    style->indent_char = ddc_hv_fetch_iv(aTHX_ config, "usetabs", 7, 0) ? '\t' : ' ';
    style->maxdepth    = ddc_hv_fetch_iv(aTHX_ config, "maxdepth", 8, 0);
    style->maxrecurse  = ddc_hv_fetch_iv(aTHX_ config, "maxrecurse", 10, 1000);
    style->terse       = ddc_hv_fetch_iv(aTHX_ config, "terse", 5, 0);
    style->purity      = ddc_hv_fetch_iv(aTHX_ config, "purity", 6, 0);
    style->useqq       = ddc_hv_fetch_iv(aTHX_ config, "useqq", 5, 0);
    style->quotekeys   = ddc_hv_fetch_iv(aTHX_ config, "quotekeys", 9, 1);
    style->sortkeys    = ddc_hv_fetch_iv(aTHX_ config, "sortkeys", 8, 0);
    style->trailingcomma = ddc_hv_fetch_iv(aTHX_ config, "trailingcomma", 13, 0);
    style->deepcopy    = ddc_hv_fetch_iv(aTHX_ config, "deepcopy", 8, 0);
    style->deparse     = ddc_hv_fetch_iv(aTHX_ config, "deparse", 7, 0);
    style->sparseseen  = ddc_hv_fetch_iv(aTHX_ config, "sparseseen", 10, 0);
    style->use_colour  = ddc_hv_fetch_iv(aTHX_ config, "use_colour", 10, 0);

    pv = ddc_hv_fetch_pv(aTHX_ config, "pad", 3);
    if (pv) style->pad = pv;

    pv = ddc_hv_fetch_pv(aTHX_ config, "varname", 7);
    if (pv) style->varname = pv;

    pv = ddc_hv_fetch_pv(aTHX_ config, "pair", 4);
    if (pv) style->pair = pv;

    pv = ddc_hv_fetch_pv(aTHX_ config, "bless", 5);
    if (pv) style->bless_str = pv;

    pv = ddc_hv_fetch_pv(aTHX_ config, "freezer", 7);
    if (pv) style->freezer = pv;

    pv = ddc_hv_fetch_pv(aTHX_ config, "toaster", 7);
    if (pv) style->toaster = pv;

    /* Sortkeys coderef */
    svp = hv_fetch(config, "sortkeys_cb", 11, 0);
    if (svp && SvOK(*svp) && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVCV) {
        style->sortkeys_cb = *svp;
        SvREFCNT_inc_simple_void(style->sortkeys_cb);
    }

    /* Resolve all colour specs to ANSI escape strings */
    if (style->use_colour) {
        RESOLVE_COLOUR(c_string_fg,   "string_fg");
        RESOLVE_COLOUR(c_string_bg,   "string_bg");
        RESOLVE_COLOUR(c_number_fg,   "number_fg");
        RESOLVE_COLOUR(c_number_bg,   "number_bg");
        RESOLVE_COLOUR(c_key_fg,      "key_fg");
        RESOLVE_COLOUR(c_key_bg,      "key_bg");
        RESOLVE_COLOUR(c_brace_fg,    "brace_fg");
        RESOLVE_COLOUR(c_brace_bg,    "brace_bg");
        RESOLVE_COLOUR(c_bracket_fg,  "bracket_fg");
        RESOLVE_COLOUR(c_bracket_bg,  "bracket_bg");
        RESOLVE_COLOUR(c_paren_fg,    "paren_fg");
        RESOLVE_COLOUR(c_paren_bg,    "paren_bg");
        RESOLVE_COLOUR(c_arrow_fg,    "arrow_fg");
        RESOLVE_COLOUR(c_arrow_bg,    "arrow_bg");
        RESOLVE_COLOUR(c_comma_fg,    "comma_fg");
        RESOLVE_COLOUR(c_comma_bg,    "comma_bg");
        RESOLVE_COLOUR(c_undef_fg,    "undef_fg");
        RESOLVE_COLOUR(c_undef_bg,    "undef_bg");
        RESOLVE_COLOUR(c_blessed_fg,  "blessed_fg");
        RESOLVE_COLOUR(c_blessed_bg,  "blessed_bg");
        RESOLVE_COLOUR(c_regex_fg,    "regex_fg");
        RESOLVE_COLOUR(c_regex_bg,    "regex_bg");
        RESOLVE_COLOUR(c_code_fg,     "code_fg");
        RESOLVE_COLOUR(c_code_bg,     "code_bg");
        RESOLVE_COLOUR(c_variable_fg, "variable_fg");
        RESOLVE_COLOUR(c_variable_bg, "variable_bg");
        RESOLVE_COLOUR(c_quote_fg,    "quote_fg");
        RESOLVE_COLOUR(c_quote_bg,    "quote_bg");
        RESOLVE_COLOUR(c_keyword_fg,  "keyword_fg");
        RESOLVE_COLOUR(c_keyword_bg,  "keyword_bg");
        RESOLVE_COLOUR(c_operator_fg, "operator_fg");
        RESOLVE_COLOUR(c_operator_bg, "operator_bg");
        RESOLVE_COLOUR(c_comment_fg,  "comment_fg");
        RESOLVE_COLOUR(c_comment_bg,  "comment_bg");
    }
}

#undef RESOLVE_COLOUR

/* ── ddc_style_from_self ──────────────────────────────────────── */
/* Populate a DDCStyle directly from a blessed Loo hashref.
   Reads option fields from $self->{key} and colours from
   $self->{colour}{element_fg/bg}.  Eliminates the intermediate
   %config hash that the Perl-side Dump() used to build.          */

#define RESOLVE_COLOUR_SELF(field, key)                                   \
    do {                                                                  \
        SV **svp = hv_fetch(colour_hv, key, strlen(key), 0);             \
        style->field = (svp && SvOK(*svp))                               \
            ? ddc_resolve_colour(aTHX_ *svp, strstr(key, "_bg") != NULL) \
            : NULL;                                                       \
    } while(0)

static void
ddc_style_from_self(pTHX_ DDCStyle *style, HV *self)
{
    const char *pv;
    SV **svp;
    HV *colour_hv = NULL;

    ddc_style_init(style);

    /* Data::Dumper compat options */
    style->indent      = ddc_hv_fetch_iv(aTHX_ self, "indent", 6, 2);
    style->indent_width = ddc_hv_fetch_iv(aTHX_ self, "indent_width", 12, 2);
    style->indent_char = ddc_hv_fetch_iv(aTHX_ self, "usetabs", 7, 0) ? '\t' : ' ';
    style->maxdepth    = ddc_hv_fetch_iv(aTHX_ self, "maxdepth", 8, 0);
    style->maxrecurse  = ddc_hv_fetch_iv(aTHX_ self, "maxrecurse", 10, 1000);
    style->terse       = ddc_hv_fetch_iv(aTHX_ self, "terse", 5, 0);
    style->purity      = ddc_hv_fetch_iv(aTHX_ self, "purity", 6, 0);
    style->useqq       = ddc_hv_fetch_iv(aTHX_ self, "useqq", 5, 0);
    style->quotekeys   = ddc_hv_fetch_iv(aTHX_ self, "quotekeys", 9, 1);
    style->sortkeys    = ddc_hv_fetch_iv(aTHX_ self, "sortkeys", 8, 0);
    style->trailingcomma = ddc_hv_fetch_iv(aTHX_ self, "trailingcomma", 13, 0);
    style->deepcopy    = ddc_hv_fetch_iv(aTHX_ self, "deepcopy", 8, 0);
    style->deparse     = ddc_hv_fetch_iv(aTHX_ self, "deparse", 7, 0);
    style->sparseseen  = ddc_hv_fetch_iv(aTHX_ self, "sparseseen", 10, 0);
    style->use_colour  = ddc_hv_fetch_iv(aTHX_ self, "use_colour", 10, 0);

    pv = ddc_hv_fetch_pv(aTHX_ self, "pad", 3);
    if (pv) style->pad = pv;

    pv = ddc_hv_fetch_pv(aTHX_ self, "varname", 7);
    if (pv) style->varname = pv;

    pv = ddc_hv_fetch_pv(aTHX_ self, "pair", 4);
    if (pv) style->pair = pv;

    pv = ddc_hv_fetch_pv(aTHX_ self, "bless", 5);
    if (pv) style->bless_str = pv;

    pv = ddc_hv_fetch_pv(aTHX_ self, "freezer", 7);
    if (pv) style->freezer = pv;

    pv = ddc_hv_fetch_pv(aTHX_ self, "toaster", 7);
    if (pv) style->toaster = pv;

    /* Sortkeys coderef from $self->{sortkeys_cb} */
    svp = hv_fetch(self, "sortkeys_cb", 11, 0);
    if (svp && SvOK(*svp) && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVCV) {
        style->sortkeys_cb = *svp;
        SvREFCNT_inc_simple_void(style->sortkeys_cb);
    }

    /* Colour sub-hash: $self->{colour} */
    svp = hv_fetch(self, "colour", 6, 0);
    if (svp && SvOK(*svp) && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVHV)
        colour_hv = (HV *)SvRV(*svp);

    if (style->use_colour && colour_hv) {
        RESOLVE_COLOUR_SELF(c_string_fg,   "string_fg");
        RESOLVE_COLOUR_SELF(c_string_bg,   "string_bg");
        RESOLVE_COLOUR_SELF(c_number_fg,   "number_fg");
        RESOLVE_COLOUR_SELF(c_number_bg,   "number_bg");
        RESOLVE_COLOUR_SELF(c_key_fg,      "key_fg");
        RESOLVE_COLOUR_SELF(c_key_bg,      "key_bg");
        RESOLVE_COLOUR_SELF(c_brace_fg,    "brace_fg");
        RESOLVE_COLOUR_SELF(c_brace_bg,    "brace_bg");
        RESOLVE_COLOUR_SELF(c_bracket_fg,  "bracket_fg");
        RESOLVE_COLOUR_SELF(c_bracket_bg,  "bracket_bg");
        RESOLVE_COLOUR_SELF(c_paren_fg,    "paren_fg");
        RESOLVE_COLOUR_SELF(c_paren_bg,    "paren_bg");
        RESOLVE_COLOUR_SELF(c_arrow_fg,    "arrow_fg");
        RESOLVE_COLOUR_SELF(c_arrow_bg,    "arrow_bg");
        RESOLVE_COLOUR_SELF(c_comma_fg,    "comma_fg");
        RESOLVE_COLOUR_SELF(c_comma_bg,    "comma_bg");
        RESOLVE_COLOUR_SELF(c_undef_fg,    "undef_fg");
        RESOLVE_COLOUR_SELF(c_undef_bg,    "undef_bg");
        RESOLVE_COLOUR_SELF(c_blessed_fg,  "blessed_fg");
        RESOLVE_COLOUR_SELF(c_blessed_bg,  "blessed_bg");
        RESOLVE_COLOUR_SELF(c_regex_fg,    "regex_fg");
        RESOLVE_COLOUR_SELF(c_regex_bg,    "regex_bg");
        RESOLVE_COLOUR_SELF(c_code_fg,     "code_fg");
        RESOLVE_COLOUR_SELF(c_code_bg,     "code_bg");
        RESOLVE_COLOUR_SELF(c_variable_fg, "variable_fg");
        RESOLVE_COLOUR_SELF(c_variable_bg, "variable_bg");
        RESOLVE_COLOUR_SELF(c_quote_fg,    "quote_fg");
        RESOLVE_COLOUR_SELF(c_quote_bg,    "quote_bg");
        RESOLVE_COLOUR_SELF(c_keyword_fg,  "keyword_fg");
        RESOLVE_COLOUR_SELF(c_keyword_bg,  "keyword_bg");
        RESOLVE_COLOUR_SELF(c_operator_fg, "operator_fg");
        RESOLVE_COLOUR_SELF(c_operator_bg, "operator_bg");
        RESOLVE_COLOUR_SELF(c_comment_fg,  "comment_fg");
        RESOLVE_COLOUR_SELF(c_comment_bg,  "comment_bg");
    }
}

#undef RESOLVE_COLOUR_SELF

/* ── ddc_style_destroy ────────────────────────────────────────── */

static void
ddc_style_destroy(pTHX_ DDCStyle *style)
{
    if (style->sortkeys_cb) {
        SvREFCNT_dec(style->sortkeys_cb);
        style->sortkeys_cb = NULL;
    }
    if (style->seen) {
        SvREFCNT_dec((SV *)style->seen);
        style->seen = NULL;
    }
    if (style->post) {
        SvREFCNT_dec((SV *)style->post);
        style->post = NULL;
    }
    /* Note: style->out is returned to caller, not freed here */
}

/* ── ddc_emit_pad ─────────────────────────────────────────────── */

static void
ddc_emit_pad(pTHX_ DDCStyle *style)
{
    if (style->pad && style->pad[0])
        sv_catpv(style->out, style->pad);
}

/* ── ddc_indent_string ────────────────────────────────────────── */
/* Returns a temporary indent string for the given depth.
   indent=0 → no indent or newlines
   indent=1 → fixed 1-space indent
   indent=2 → 2-space-per-level (Data::Dumper default)
   indent=3 → like 2 but with variable name annotation */

static char indent_buf[256];

static const char *
ddc_indent_string(DDCStyle *style, int depth)
{
    int i, total;
    int width;
    char ch;

    if (style->indent == 0)
        return "";

    if (style->indent == 1) {
        /* Single space */
        indent_buf[0] = ' ';
        indent_buf[1] = '\0';
        return indent_buf;
    }

    /* indent 2 or 3: configurable width and character per level */
    width = style->indent_width > 0 ? style->indent_width : 2;
    ch    = style->indent_char ? style->indent_char : ' ';
    total = depth * width;
    if (total > 254) total = 254;
    for (i = 0; i < total; i++)
        indent_buf[i] = ch;
    indent_buf[total] = '\0';
    return indent_buf;
}

/* ── ddc_seen_check ───────────────────────────────────────────── */
/* Check if we've seen this reference before. Returns 1 if circular.
   If not seen, records it and returns 0. */

static int
ddc_seen_check(pTHX_ SV *val, const char *name, DDCStyle *style)
{
    UV addr;
    char addr_buf[32];
    STRLEN addr_len;
    SV **existing;

    if (!SvROK(val))
        return 0;

    addr = PTR2UV(SvRV(val));
    addr_len = snprintf(addr_buf, sizeof(addr_buf), "%"UVuf, addr);

    existing = hv_fetch(style->seen, addr_buf, addr_len, 0);

    if (existing && *existing && SvOK(*existing)) {
        /* Already seen — emit the name we recorded */
        sv_catpv(style->out, SvPV_nolen(*existing));
        return 1;
    }

    /* Record: addr → name */
    hv_store(style->seen, addr_buf, addr_len,
             newSVpv(name ? name : "$VAR", 0), 0);

    return 0;
}

/* ── ddc_dump_sv ──────────────────────────────────────────────── */
/* Dump a single scalar value (string, number, or undef). */

static void
ddc_dump_sv(pTHX_ SV *val, DDCStyle *style, int depth)
{
    const char *reset = style->use_colour ? style->c_reset : NULL;

    if (!SvOK(val)) {
        /* undef */
        if (style->use_colour) {
            ddc_colour_wrap(aTHX_ style->out,
                style->c_undef_fg, style->c_undef_bg,
                reset, "undef", 5);
        } else {
            sv_catpvn(style->out, "undef", 5);
        }
        return;
    }

    /* Number: has IOK or NOK set (and no string override),
       or looks numeric and has no PV */
    if ( (SvIOK(val) || SvNOK(val)) && !SvPOK(val) ) {
        SV *num = ddc_format_number(aTHX_ val);
        STRLEN len;
        const char *pv = SvPV(num, len);
        if (style->use_colour) {
            ddc_colour_wrap(aTHX_ style->out,
                style->c_number_fg, style->c_number_bg,
                reset, pv, len);
        } else {
            sv_catpvn(style->out, pv, len);
        }
        SvREFCNT_dec(num);
        return;
    }

    /* String value */
    {
        STRLEN slen;
        const char *spv = SvPV(val, slen);
        int is_utf8 = SvUTF8(val) ? 1 : 0;
        SV *escaped = ddc_escape_string(aTHX_ spv, slen, style->useqq, is_utf8);
        STRLEN elen;
        const char *epv = SvPV(escaped, elen);
        const char *q = style->useqq ? "\"" : "'";

        if (style->use_colour) {
            /* quote char */
            ddc_colour_wrap(aTHX_ style->out,
                style->c_quote_fg, style->c_quote_bg,
                reset, q, 1);
            /* string content */
            ddc_colour_wrap(aTHX_ style->out,
                style->c_string_fg, style->c_string_bg,
                reset, epv, elen);
            /* closing quote */
            ddc_colour_wrap(aTHX_ style->out,
                style->c_quote_fg, style->c_quote_bg,
                reset, q, 1);
        } else {
            sv_catpvn(style->out, q, 1);
            sv_catpvn(style->out, epv, elen);
            sv_catpvn(style->out, q, 1);
        }
        SvREFCNT_dec(escaped);
    }
}

/* ── ddc_dump_av ──────────────────────────────────────────────── */
/* Dump an array ref's contents. */

static void
ddc_dump_av(pTHX_ AV *av, DDCStyle *style, int depth)
{
    I32 len = av_len(av) + 1;
    I32 i;
    const char *indent_str = ddc_indent_string(style, depth + 1);
    const char *reset = style->use_colour ? style->c_reset : NULL;
    int need_newline = (style->indent > 0);

    /* Opening bracket */
    if (style->use_colour) {
        ddc_colour_wrap(aTHX_ style->out,
            style->c_bracket_fg, style->c_bracket_bg,
            reset, "[", 1);
    } else {
        sv_catpvn(style->out, "[", 1);
    }

    if (need_newline && len > 0)
        sv_catpvn(style->out, "\n", 1);

    for (i = 0; i < len; i++) {
        SV **elem = av_fetch(av, i, 0);

        if (need_newline) {
            ddc_emit_pad(aTHX_ style);
            sv_catpv(style->out, indent_str);
        }

        if (elem && *elem) {
            ddc_dump_ref(aTHX_ *elem, style, depth + 1);
        } else {
            /* undef element */
            if (style->use_colour) {
                ddc_colour_wrap(aTHX_ style->out,
                    style->c_undef_fg, style->c_undef_bg,
                    reset, "undef", 5);
            } else {
                sv_catpvn(style->out, "undef", 5);
            }
        }

        /* Comma */
        if (i < len - 1 || style->trailingcomma) {
            if (style->use_colour) {
                ddc_colour_wrap(aTHX_ style->out,
                    style->c_comma_fg, style->c_comma_bg,
                    reset, ",", 1);
            } else {
                sv_catpvn(style->out, ",", 1);
            }
        }

        if (need_newline)
            sv_catpvn(style->out, "\n", 1);
        else if (i < len - 1)
            sv_catpvn(style->out, " ", 1);
    }

    /* Closing bracket */
    if (need_newline && len > 0) {
        ddc_emit_pad(aTHX_ style);
        sv_catpv(style->out, ddc_indent_string(style, depth));
    }

    if (style->use_colour) {
        ddc_colour_wrap(aTHX_ style->out,
            style->c_bracket_fg, style->c_bracket_bg,
            reset, "]", 1);
    } else {
        sv_catpvn(style->out, "]", 1);
    }
}

/* ── ddc_dump_hv ──────────────────────────────────────────────── */
/* Dump a hash ref's contents. */

static void
ddc_dump_hv(pTHX_ HV *hv, DDCStyle *style, int depth)
{
    I32 count;
    AV *keys_av;
    I32 i, len;
    const char *indent_str = ddc_indent_string(style, depth + 1);
    const char *reset = style->use_colour ? style->c_reset : NULL;
    int need_newline = (style->indent > 0);

    /* Collect and optionally sort keys */
    keys_av = newAV();

    if (style->sortkeys && style->sortkeys_cb) {
        /* Custom sort callback: call Perl sub with the hash */
        dSP;
        SV *ret;
        I32 retcount;

        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newRV_inc((SV *)hv)));
        PUTBACK;
        retcount = call_sv(style->sortkeys_cb, G_SCALAR);
        SPAGAIN;
        if (retcount == 1) {
            ret = POPs;
            if (SvROK(ret) && SvTYPE(SvRV(ret)) == SVt_PVAV) {
                AV *sorted = (AV *)SvRV(ret);
                I32 slen = av_len(sorted) + 1;
                for (i = 0; i < slen; i++) {
                    SV **ksvp = av_fetch(sorted, i, 0);
                    if (ksvp)
                        av_push(keys_av, newSVsv(*ksvp));
                }
            }
        }
        PUTBACK;
        FREETMPS; LEAVE;
    } else {
        /* Collect all keys */
        HE *he;
        hv_iterinit(hv);
        while ((he = hv_iternext(hv))) {
            av_push(keys_av, newSVsv(hv_iterkeysv(he)));
        }

        /* Default sort if sortkeys=1 */
        if (style->sortkeys) {
            sortsv(AvARRAY(keys_av), av_len(keys_av) + 1, Perl_sv_cmp);
        }
    }

    len = av_len(keys_av) + 1;

    /* Opening brace */
    if (style->use_colour) {
        ddc_colour_wrap(aTHX_ style->out,
            style->c_brace_fg, style->c_brace_bg,
            reset, "{", 1);
    } else {
        sv_catpvn(style->out, "{", 1);
    }

    if (need_newline && len > 0)
        sv_catpvn(style->out, "\n", 1);

    for (i = 0; i < len; i++) {
        SV **key_svp = av_fetch(keys_av, i, 0);
        SV *key_sv;
        SV *val_sv;
        STRLEN klen;
        const char *kpv;

        if (!key_svp) continue;
        key_sv = *key_svp;
        kpv = SvPV(key_sv, klen);

        /* Fetch value */
        {
            SV **vp = hv_fetch(hv, kpv, klen, 0);
            val_sv = (vp && *vp) ? *vp : &PL_sv_undef;
        }

        if (need_newline) {
            ddc_emit_pad(aTHX_ style);
            sv_catpv(style->out, indent_str);
        }

        /* Key */
        if (style->quotekeys || ddc_key_needs_quote(kpv, klen)) {
            const char *q = style->useqq ? "\"" : "'";
            SV *escaped = ddc_escape_string(aTHX_ kpv, klen, style->useqq, SvUTF8(key_sv) ? 1 : 0);
            STRLEN elen;
            const char *epv = SvPV(escaped, elen);

            if (style->use_colour) {
                ddc_colour_wrap(aTHX_ style->out,
                    style->c_quote_fg, style->c_quote_bg,
                    reset, q, 1);
                ddc_colour_wrap(aTHX_ style->out,
                    style->c_key_fg, style->c_key_bg,
                    reset, epv, elen);
                ddc_colour_wrap(aTHX_ style->out,
                    style->c_quote_fg, style->c_quote_bg,
                    reset, q, 1);
            } else {
                sv_catpvn(style->out, q, 1);
                sv_catpvn(style->out, epv, elen);
                sv_catpvn(style->out, q, 1);
            }
            SvREFCNT_dec(escaped);
        } else {
            /* Bareword key */
            if (style->use_colour) {
                ddc_colour_wrap(aTHX_ style->out,
                    style->c_key_fg, style->c_key_bg,
                    reset, kpv, klen);
            } else {
                sv_catpvn(style->out, kpv, klen);
            }
        }

        /* Arrow / pair separator */
        if (style->use_colour) {
            ddc_colour_wrap(aTHX_ style->out,
                style->c_arrow_fg, style->c_arrow_bg,
                reset, style->pair, strlen(style->pair));
        } else {
            sv_catpv(style->out, style->pair);
        }

        /* Value */
        ddc_dump_ref(aTHX_ val_sv, style, depth + 1);

        /* Comma */
        if (i < len - 1 || style->trailingcomma) {
            if (style->use_colour) {
                ddc_colour_wrap(aTHX_ style->out,
                    style->c_comma_fg, style->c_comma_bg,
                    reset, ",", 1);
            } else {
                sv_catpvn(style->out, ",", 1);
            }
        }

        if (need_newline)
            sv_catpvn(style->out, "\n", 1);
        else if (i < len - 1)
            sv_catpvn(style->out, " ", 1);
    }

    /* Closing brace */
    if (need_newline && len > 0) {
        ddc_emit_pad(aTHX_ style);
        sv_catpv(style->out, ddc_indent_string(style, depth));
    }

    if (style->use_colour) {
        ddc_colour_wrap(aTHX_ style->out,
            style->c_brace_fg, style->c_brace_bg,
            reset, "}", 1);
    } else {
        sv_catpvn(style->out, "}", 1);
    }

    SvREFCNT_dec((SV *)keys_av);
}

/* ── ddc_dump_glob ────────────────────────────────────────────── */

static void
ddc_dump_glob(pTHX_ SV *val, DDCStyle *style, int depth)
{
    GV *gv = (GV *)val;
    const char *name = GvNAME(gv);
    HV *stash = GvSTASH(gv);
    const char *pkg = stash ? HvNAME(stash) : "main";

    sv_catpvf(style->out, "\\*%s::%s", pkg, name);
}

/* ── ddc_dump_ref ─────────────────────────────────────────────── */
/* Dispatch on value type — the core recursive workhorse. */

static void
ddc_dump_ref(pTHX_ SV *val, DDCStyle *style, int depth)
{
    const char *reset = style->use_colour ? style->c_reset : NULL;
    SV *inner;

    /* Depth limit check */
    if (style->maxdepth > 0 && depth >= style->maxdepth) {
        sv_catpvn(style->out, "'DUMMY'", 7);
        return;
    }

    /* Recursion limit check */
    style->level++;
    if (style->level > style->maxrecurse) {
        style->level--;
        croak("Recursion limit of %d exceeded", style->maxrecurse);
    }

    if (!SvOK(val) || val == &PL_sv_undef) {
        ddc_dump_sv(aTHX_ &PL_sv_undef, style, depth);
        style->level--;
        return;
    }

    /* Not a reference — dump as scalar */
    if (!SvROK(val)) {
        ddc_dump_sv(aTHX_ val, style, depth);
        style->level--;
        return;
    }

    /* It's a reference — check for circular refs */
    {
        char namebuf[64];
        snprintf(namebuf, sizeof(namebuf), "$%s%d", style->varname, (int)(depth + 1));
        if (ddc_seen_check(aTHX_ val, namebuf, style)) {
            style->level--;
            return;
        }
    }

    inner = SvRV(val);

    /* Check for blessed */
    if (SvOBJECT(inner)) {
        HV *stash = SvSTASH(inner);
        const char *classname = stash ? HvNAME(stash) : "???";
        STRLEN clen = strlen(classname);

        /* Special case: Regexp objects — emit as qr/pattern/flags.
           On 5.12+ the inner SV has SVt_REGEXP; on older perls it's a
           blessed PVMG whose class is "Regexp". */
#ifdef SVt_REGEXP
        if (SvTYPE(inner) == SVt_REGEXP) {
            REGEXP *re = (REGEXP *)inner;
            SV *wrapped = newSVpvs("qr/");

            /* Use RX_PRECOMP (the original pattern) and RX_EXTFLAGS */
            {
                STRLEN plen;
                const char *pat = RX_PRECOMP(re);
                plen = RX_PRELEN(re);
                U32 flags = RX_EXTFLAGS(re);

                if (pat && plen)
                    sv_catpvn(wrapped, pat, plen);
                sv_catpvn(wrapped, "/", 1);

                if (flags & RXf_PMf_FOLD)      sv_catpvn(wrapped, "i", 1);
                if (flags & RXf_PMf_MULTILINE)  sv_catpvn(wrapped, "m", 1);
                if (flags & RXf_PMf_SINGLELINE) sv_catpvn(wrapped, "s", 1);
                if (flags & RXf_PMf_EXTENDED)   sv_catpvn(wrapped, "x", 1);
            }

            {
                STRLEN wlen;
                const char *wpv = SvPV(wrapped, wlen);
                if (style->use_colour) {
                    ddc_colour_wrap(aTHX_ style->out,
                        style->c_regex_fg, style->c_regex_bg,
                        reset, wpv, wlen);
                } else {
                    sv_catpvn(style->out, wpv, wlen);
                }
            }
            SvREFCNT_dec(wrapped);
            style->level--;
            return;
        }
#else
        /* Pre-5.12: regex is a blessed PVMG; detect by class name
           OR by the presence of PERL_MAGIC_qr (for re-blessed regexes).
           Stringify with SvPV on the ref, giving (?flags:pattern). */
        if ((clen == 6 && strEQ(classname, "Regexp")) ||
            (SvMAGICAL(inner) && mg_find(inner, PERL_MAGIC_qr))) {
            int is_reblessed = !(clen == 6 && strEQ(classname, "Regexp"));
            const char *bfn;
            STRLEN rlen;
            const char *rpv = SvPV(val, rlen);
            SV *wrapped = newSVpvs("");

            if (is_reblessed) {
                bfn = (style->bless_str && style->bless_str[0])
                      ? style->bless_str : "bless";
                sv_catpvn(wrapped, bfn, strlen(bfn));
                sv_catpvn(wrapped, "( ", 2);
            }
            sv_catpvn(wrapped, "qr/", 3);
            if (rpv && rlen)
                sv_catpvn(wrapped, rpv, rlen);
            sv_catpvn(wrapped, "/", 1);
            if (is_reblessed) {
                sv_catpvn(wrapped, ", '", 3);
                sv_catpvn(wrapped, classname, clen);
                sv_catpvn(wrapped, "' )", 3);
            }

            {
                STRLEN wlen;
                const char *wpv = SvPV(wrapped, wlen);
                if (style->use_colour) {
                    ddc_colour_wrap(aTHX_ style->out,
                        style->c_regex_fg, style->c_regex_bg,
                        reset, wpv, wlen);
                } else {
                    sv_catpvn(style->out, wpv, wlen);
                }
            }
            SvREFCNT_dec(wrapped);
            style->level--;
            return;
        }
#endif

        /* Freezer callback */
        if (style->freezer && style->freezer[0]) {
            GV *method = gv_fetchmethod_autoload(stash, style->freezer, 0);
            if (method) {
                dSP;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(val);
                PUTBACK;
                call_sv((SV *)GvCV(method), G_DISCARD);
                FREETMPS; LEAVE;
            }
        }

        /* bless( */
        if (style->use_colour) {
            ddc_colour_wrap(aTHX_ style->out,
                style->c_blessed_fg, style->c_blessed_bg,
                reset, style->bless_str, strlen(style->bless_str));
            sv_catpvn(style->out, "( ", 2);
        } else {
            sv_catpv(style->out, style->bless_str);
            sv_catpvn(style->out, "( ", 2);
        }

        /* Dump the inner structure */
        switch (SvTYPE(inner)) {
            case SVt_PVAV:
                ddc_dump_av(aTHX_ (AV *)inner, style, depth);
                break;
            case SVt_PVHV:
                ddc_dump_hv(aTHX_ (HV *)inner, style, depth);
                break;
            default:
                /* Blessed scalar ref, etc. */
                sv_catpvn(style->out, "\\", 1);
                ddc_dump_ref(aTHX_ inner, style, depth + 1);
                break;
        }

        /* , 'classname' ) */
        if (style->use_colour) {
            sv_catpvn(style->out, ", ", 2);
            ddc_colour_wrap(aTHX_ style->out,
                style->c_quote_fg, style->c_quote_bg,
                reset, "'", 1);
            ddc_colour_wrap(aTHX_ style->out,
                style->c_blessed_fg, style->c_blessed_bg,
                reset, classname, clen);
            ddc_colour_wrap(aTHX_ style->out,
                style->c_quote_fg, style->c_quote_bg,
                reset, "'", 1);
            sv_catpvn(style->out, " )", 2);
        } else {
            sv_catpvf(style->out, ", '%s' )", classname);
        }

        /* Toaster callback */
        if (style->toaster && style->toaster[0]) {
            sv_catpvf(style->out, "->%s()", style->toaster);
        }

        style->level--;
        return;
    }

    /* Unblessed reference — dispatch on inner type */
    switch (SvTYPE(inner)) {
        case SVt_PVAV:
            ddc_dump_av(aTHX_ (AV *)inner, style, depth);
            break;
        case SVt_PVHV:
            ddc_dump_hv(aTHX_ (HV *)inner, style, depth);
            break;
        case SVt_PVCV: {
            /* Code ref */
            if (style->deparse) {
                SV *deparsed = ddc_deparse_cv(aTHX_ (CV *)inner, style, depth);
                if (deparsed) {
                    STRLEN dlen;
                    const char *dpv = SvPV(deparsed, dlen);
                    sv_catpvn(style->out, dpv, dlen);
                    SvREFCNT_dec(deparsed);
                } else {
                    if (style->use_colour) {
                        ddc_colour_wrap(aTHX_ style->out,
                            style->c_code_fg, style->c_code_bg,
                            reset, "sub { \"DUMMY\" }", 16);
                    } else {
                        sv_catpvn(style->out, "sub { \"DUMMY\" }", 16);
                    }
                }
            } else {
                if (style->use_colour) {
                    ddc_colour_wrap(aTHX_ style->out,
                        style->c_code_fg, style->c_code_bg,
                        reset, "sub { \"DUMMY\" }", 16);
                } else {
                    sv_catpvn(style->out, "sub { \"DUMMY\" }", 16);
                }
            }
            break;
        }
        case SVt_PVGV:
            /* Glob */
            ddc_dump_glob(aTHX_ inner, style, depth);
            break;
#ifdef SVt_REGEXP
        case SVt_REGEXP: {
            /* Regex (5.12+) */
            STRLEN rlen;
            const char *rpv;
            SV *pattern = (SV *)inner;
            rpv = SvPV(pattern, rlen);
            if (style->use_colour) {
                ddc_colour_wrap(aTHX_ style->out,
                    style->c_regex_fg, style->c_regex_bg,
                    reset, "qr/", 3);
                ddc_colour_wrap(aTHX_ style->out,
                    style->c_regex_fg, style->c_regex_bg,
                    reset, rpv, rlen);
                ddc_colour_wrap(aTHX_ style->out,
                    style->c_regex_fg, style->c_regex_bg,
                    reset, "/", 1);
            } else {
                sv_catpvn(style->out, "qr/", 3);
                sv_catpvn(style->out, rpv, rlen);
                sv_catpvn(style->out, "/", 1);
            }
            break;
        }
#endif
        default:
            /* Scalar ref (or ref-to-ref) */
            sv_catpvn(style->out, "\\", 1);
            ddc_dump_ref(aTHX_ inner, style, depth + 1);
            break;
    }

    style->level--;
}

/* ── ddc_dump ─────────────────────────────────────────────────── */
/* Top-level entry: dump one or more values with optional $VARn names. */

static SV *
ddc_dump(pTHX_ SV *val, const char *name, DDCStyle *style, int depth)
{
    /* This is used internally by the XSUB wrapper which handles
       the values/names arrays. Here we dump one value. */

    ddc_dump_ref(aTHX_ val, style, depth);

    return style->out;
}

/* ── ddc_dump_top ─────────────────────────────────────────────── */
/* Top-level entry called from the XSUB: handles the values/names arrays. */

static SV *
ddc_dump_top(pTHX_ AV *values, AV *names, HV *config)
{
    DDCStyle style;
    I32 i, len;
    SV *out;
    const char *reset;

    ddc_style_from_hv(aTHX_ &style, config);

    out = newSVpvs("");
    SvGROW(out, 256);
    style.out  = out;
    style.seen = newHV();
    style.post = newAV();

    reset = style.use_colour ? style.c_reset : NULL;
    len = av_len(values) + 1;

    for (i = 0; i < len; i++) {
        SV **val_svp = av_fetch(values, i, 0);
        SV *val_sv = (val_svp && *val_svp) ? *val_svp : &PL_sv_undef;
        SV **name_svp = av_fetch(names, i, 0);
        char namebuf[64];
        const char *var_name;
        int named_by_user = 0;

        /* Determine variable name */
        if (name_svp && SvOK(*name_svp)) {
            var_name = SvPV_nolen(*name_svp);
            named_by_user = 1;
        } else {
            snprintf(namebuf, sizeof(namebuf), "%s%d", style.varname, (int)(i + 1));
            var_name = namebuf;
        }

        if (!style.terse) {
            /* $VARn = */
            ddc_emit_pad(aTHX_ &style);
            if (style.use_colour) {
                SV *prefix;
                if (named_by_user && var_name[0] != '$') {
                    prefix = newSVpvf("$%s = ", var_name);
                } else if (!named_by_user) {
                    prefix = newSVpvf("$%s = ", var_name);
                } else {
                    prefix = newSVpvf("%s = ", var_name);
                }
                {
                    STRLEN plen;
                    const char *ppv = SvPV(prefix, plen);
                    ddc_colour_wrap(aTHX_ out,
                        style.c_variable_fg, style.c_variable_bg,
                        reset, ppv, plen);
                }
                SvREFCNT_dec(prefix);
            } else {
                if (named_by_user && var_name[0] != '$') {
                    sv_catpvf(out, "$%s = ", var_name);
                } else if (!named_by_user) {
                    sv_catpvf(out, "$%s = ", var_name);
                } else {
                    sv_catpvf(out, "%s = ", var_name);
                }
            }
        } else {
            ddc_emit_pad(aTHX_ &style);
        }

        /* Dump the value */
        ddc_dump_ref(aTHX_ val_sv, &style, 0);

        if (!style.terse)
            sv_catpvn(out, ";\n", 2);
        else
            sv_catpvn(out, "\n", 1);
    }

    /* Purity: append post-fix statements for circular refs */
    if (style.purity) {
        I32 plen = av_len(style.post) + 1;
        for (i = 0; i < plen; i++) {
            SV **ps = av_fetch(style.post, i, 0);
            if (ps && *ps) {
                STRLEN slen;
                const char *spv = SvPV(*ps, slen);
                sv_catpvn(out, spv, slen);
                sv_catpvn(out, "\n", 1);
            }
        }
    }

    ddc_style_destroy(aTHX_ &style);
    return out;
}

/* ── ddc_dump_self ────────────────────────────────────────────── */
/* Entry point that reads config directly from a blessed Loo HV.
   Replaces the Perl-side Dump() → _xs_dump() config-building path. */

static SV *
ddc_dump_self(pTHX_ HV *self)
{
    DDCStyle style;
    I32 i, len;
    SV *out;
    const char *reset;
    AV *values;
    AV *names;
    SV **svp;

    ddc_style_from_self(aTHX_ &style, self);

    /* Extract values and names arrays from $self */
    svp = hv_fetch(self, "values", 6, 0);
    if (svp && SvOK(*svp) && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVAV)
        values = (AV *)SvRV(*svp);
    else
        values = newAV(); /* empty fallback */

    svp = hv_fetch(self, "names", 5, 0);
    if (svp && SvOK(*svp) && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVAV)
        names = (AV *)SvRV(*svp);
    else
        names = newAV();

    out = newSVpvs("");
    SvGROW(out, 256);
    style.out  = out;
    style.seen = newHV();
    style.post = newAV();

    reset = style.use_colour ? style.c_reset : NULL;
    len = av_len(values) + 1;

    for (i = 0; i < len; i++) {
        SV **val_svp = av_fetch(values, i, 0);
        SV *val_sv = (val_svp && *val_svp) ? *val_svp : &PL_sv_undef;
        SV **name_svp = av_fetch(names, i, 0);
        char namebuf[64];
        const char *var_name;
        int named_by_user = 0;

        if (name_svp && SvOK(*name_svp)) {
            var_name = SvPV_nolen(*name_svp);
            named_by_user = 1;
        } else {
            snprintf(namebuf, sizeof(namebuf), "%s%d", style.varname, (int)(i + 1));
            var_name = namebuf;
        }

        if (!style.terse) {
            ddc_emit_pad(aTHX_ &style);
            if (style.use_colour) {
                SV *prefix;
                if (named_by_user && var_name[0] != '$')
                    prefix = newSVpvf("$%s = ", var_name);
                else if (!named_by_user)
                    prefix = newSVpvf("$%s = ", var_name);
                else
                    prefix = newSVpvf("%s = ", var_name);
                {
                    STRLEN plen;
                    const char *ppv = SvPV(prefix, plen);
                    ddc_colour_wrap(aTHX_ out,
                        style.c_variable_fg, style.c_variable_bg,
                        reset, ppv, plen);
                }
                SvREFCNT_dec(prefix);
            } else {
                if (named_by_user && var_name[0] != '$')
                    sv_catpvf(out, "$%s = ", var_name);
                else if (!named_by_user)
                    sv_catpvf(out, "$%s = ", var_name);
                else
                    sv_catpvf(out, "%s = ", var_name);
            }
        } else {
            ddc_emit_pad(aTHX_ &style);
        }

        ddc_dump_ref(aTHX_ val_sv, &style, 0);

        if (!style.terse)
            sv_catpvn(out, ";\n", 2);
        else
            sv_catpvn(out, "\n", 1);
    }

    if (style.purity) {
        I32 plen = av_len(style.post) + 1;
        for (i = 0; i < plen; i++) {
            SV **ps = av_fetch(style.post, i, 0);
            if (ps && *ps) {
                STRLEN slen;
                const char *spv = SvPV(*ps, slen);
                sv_catpvn(out, spv, slen);
                sv_catpvn(out, "\n", 1);
            }
        }
    }

    ddc_style_destroy(aTHX_ &style);
    return out;
}

#endif /* LOO_DUMP_H */
