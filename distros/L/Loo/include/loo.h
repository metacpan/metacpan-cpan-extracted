#ifndef LOO_H
#define LOO_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

/* ── Global backward-compat macros ────────────────────────────── */

/* SVt_REGEXP appeared in 5.12.  Do NOT alias it to SVt_PVMG because
   that causes case-SVt_REGEXP in switches to match all PVMGs.
   Instead, code that handles regexes should use version guards. */

/* utf8_to_uvchr_buf appeared in 5.16; fall back to utf8_to_uvchr */
#ifndef utf8_to_uvchr_buf
#  define utf8_to_uvchr_buf(s, e, lenp) utf8_to_uvchr(s, lenp)
#endif

typedef struct {
    /* Data::Dumper compat options */
    int indent;           /* 0-3 */
    int indent_width;     /* chars per indent level (default 2) */
    char indent_char;     /* ' ' or '\t' (default ' ') */
    int maxdepth;         /* 0 = unlimited */
    int maxrecurse;       /* default 1000 */
    int terse;            /* omit $VARn = */
    int purity;           /* extra stmts for circular refs */
    int useqq;            /* double-quote strings */
    int quotekeys;        /* always quote hash keys */
    int sortkeys;         /* sort hash keys */
    SV *sortkeys_cb;      /* custom sort callback (CODE ref) */
    int trailingcomma;
    int deepcopy;
    int deparse;
    int sparseseen;
    const char *pad;
    const char *varname;
    const char *pair;     /* default " => " */
    const char *bless_str;
    const char *freezer;
    const char *toaster;

    /* Colour config — each is a pre-computed ANSI escape string */
    const char *c_string_fg;    const char *c_string_bg;
    const char *c_number_fg;    const char *c_number_bg;
    const char *c_key_fg;       const char *c_key_bg;
    const char *c_brace_fg;     const char *c_brace_bg;
    const char *c_bracket_fg;   const char *c_bracket_bg;
    const char *c_paren_fg;     const char *c_paren_bg;
    const char *c_arrow_fg;     const char *c_arrow_bg;
    const char *c_comma_fg;     const char *c_comma_bg;
    const char *c_undef_fg;     const char *c_undef_bg;
    const char *c_blessed_fg;   const char *c_blessed_bg;
    const char *c_regex_fg;     const char *c_regex_bg;
    const char *c_code_fg;      const char *c_code_bg;
    const char *c_variable_fg;  const char *c_variable_bg;
    const char *c_quote_fg;     const char *c_quote_bg;

    /* Deparse syntax highlighting colours */
    const char *c_keyword_fg;   const char *c_keyword_bg;
    const char *c_operator_fg;  const char *c_operator_bg;
    const char *c_comment_fg;   const char *c_comment_bg;

    const char *c_reset;        /* always "\033[0m" */
    int use_colour;             /* master on/off switch */

    /* Internal state */
    HV *seen;            /* refaddr -> [$name, $value] */
    int level;           /* current recursion depth */
    AV *post;            /* post-statements for Purity mode */
    SV *out;             /* output buffer */
} DDCStyle;

/* Forward declaration for cross-header references */
static SV * ddc_deparse_cv(pTHX_ CV *cv, DDCStyle *style, int depth);

/* ── Theme definitions ────────────────────────────────────────── */
/* 17 colour element names (fg only; _bg variants not set by themes) */

typedef struct {
    const char *name;       /* theme name */
    const char *string_fg;
    const char *number_fg;
    const char *key_fg;
    const char *brace_fg;
    const char *bracket_fg;
    const char *paren_fg;
    const char *arrow_fg;
    const char *comma_fg;
    const char *undef_fg;
    const char *blessed_fg;
    const char *regex_fg;
    const char *code_fg;
    const char *variable_fg;
    const char *quote_fg;
    const char *keyword_fg;
    const char *operator_fg;
    const char *comment_fg;
} LooTheme;

static const LooTheme loo_themes[] = {
    { "default",
      "green", "cyan", "magenta", "bright_white", "bright_white",
      "bright_white", "white", "white", "bright_red", "yellow",
      "bright_yellow", "bright_blue", "bright_cyan", "green",
      "bright_blue", "white", "bright_black" },
    { "light",
      "red", "blue", "magenta", "black", "black",
      "black", "black", "black", "red", "magenta",
      "green", "blue", "blue", "red",
      "blue", "black", "bright_black" },
    { "monokai",
      "yellow", "magenta", "bright_white", "bright_yellow", "bright_yellow",
      "bright_yellow", "bright_red", "white", "magenta", "bright_green",
      "yellow", "green", "bright_white", "yellow",
      "bright_red", "bright_red", "bright_black" },
    { "none",
      NULL, NULL, NULL, NULL, NULL,
      NULL, NULL, NULL, NULL, NULL,
      NULL, NULL, NULL, NULL,
      NULL, NULL, NULL },
    { NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
      NULL, NULL, NULL, NULL, NULL, NULL, NULL }
};

/* Find a theme by name; returns NULL if not found */
static const LooTheme *
loo_find_theme(const char *name)
{
    const LooTheme *t;
    for (t = loo_themes; t->name; t++) {
        if (strEQ(name, t->name))
            return t;
    }
    return NULL;
}

/* Apply a theme's colours into a Perl HV (the $self->{colour} hash) */
static void
loo_apply_theme(pTHX_ HV *colour_hv, const LooTheme *theme)
{
    hv_clear(colour_hv);
    if (!theme) return;

#define STORE_THEME_COLOUR(key, val) \
    if (val) hv_store(colour_hv, key, strlen(key), newSVpv(val, 0), 0)

    STORE_THEME_COLOUR("string_fg",   theme->string_fg);
    STORE_THEME_COLOUR("number_fg",   theme->number_fg);
    STORE_THEME_COLOUR("key_fg",      theme->key_fg);
    STORE_THEME_COLOUR("brace_fg",    theme->brace_fg);
    STORE_THEME_COLOUR("bracket_fg",  theme->bracket_fg);
    STORE_THEME_COLOUR("paren_fg",    theme->paren_fg);
    STORE_THEME_COLOUR("arrow_fg",    theme->arrow_fg);
    STORE_THEME_COLOUR("comma_fg",    theme->comma_fg);
    STORE_THEME_COLOUR("undef_fg",    theme->undef_fg);
    STORE_THEME_COLOUR("blessed_fg",  theme->blessed_fg);
    STORE_THEME_COLOUR("regex_fg",    theme->regex_fg);
    STORE_THEME_COLOUR("code_fg",     theme->code_fg);
    STORE_THEME_COLOUR("variable_fg", theme->variable_fg);
    STORE_THEME_COLOUR("quote_fg",    theme->quote_fg);
    STORE_THEME_COLOUR("keyword_fg",  theme->keyword_fg);
    STORE_THEME_COLOUR("operator_fg", theme->operator_fg);
    STORE_THEME_COLOUR("comment_fg",  theme->comment_fg);

#undef STORE_THEME_COLOUR
}

/* ── Colour element names for Colour() method ────────────────── */
static const char *loo_colour_elements[] = {
    "string", "number", "key", "brace", "bracket", "paren",
    "arrow", "comma", "undef", "blessed", "regex", "code",
    "variable", "quote", "keyword", "operator", "comment",
    NULL
};

/* ── _detect_colour helper ────────────────────────────────────── */
static int
loo_detect_colour(pTHX)
{
    SV *use_colour;
    SV **svp;
    HV *env_hv;

    /* Check $Loo::USE_COLOUR */
    use_colour = get_sv("Loo::USE_COLOUR", 0);
    if (use_colour && SvOK(use_colour))
        return SvTRUE(use_colour) ? 1 : 0;

    /* Check $ENV{NO_COLOR} */
    env_hv = get_hv("ENV", 0);
    if (env_hv) {
        if (hv_exists(env_hv, "NO_COLOR", 8))
            return 0;
        svp = hv_fetch(env_hv, "TERM", 4, 0);
        if (svp && SvOK(*svp) && strEQ(SvPV_nolen(*svp), "dumb"))
            return 0;
    }

    /* Check -t STDOUT */
    {
        PerlIO *fp = PerlIO_stdout();
        if (fp && PerlLIO_isatty(PerlIO_fileno(fp)))
            return 1;
    }
    return 0;
}

#include "loo_colour.h"
#include "loo_escape.h"
#include "loo_dump.h"
#include "loo_deparse.h"

#endif /* LOO_H */
