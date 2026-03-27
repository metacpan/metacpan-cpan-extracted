#ifndef LOO_COLOUR_H
#define LOO_COLOUR_H

/* ── Colour name → ANSI code lookup table ─────────────────────── */

typedef struct {
    const char *name;
    const char *fg;
    const char *bg;
} loo_colour_entry;

static const loo_colour_entry colour_table[] = {
    {"black",          "\033[30m", "\033[40m"},
    {"red",            "\033[31m", "\033[41m"},
    {"green",          "\033[32m", "\033[42m"},
    {"yellow",         "\033[33m", "\033[43m"},
    {"blue",           "\033[34m", "\033[44m"},
    {"magenta",        "\033[35m", "\033[45m"},
    {"cyan",           "\033[36m", "\033[46m"},
    {"white",          "\033[37m", "\033[47m"},
    {"bright_black",   "\033[90m", "\033[100m"},
    {"bright_red",     "\033[91m", "\033[101m"},
    {"bright_green",   "\033[92m", "\033[102m"},
    {"bright_yellow",  "\033[93m", "\033[103m"},
    {"bright_blue",    "\033[94m", "\033[104m"},
    {"bright_magenta", "\033[95m", "\033[105m"},
    {"bright_cyan",    "\033[96m", "\033[106m"},
    {"bright_white",   "\033[97m", "\033[107m"},
    {"bold",           "\033[1m",  "\033[1m"},
    {"dim",            "\033[2m",  "\033[2m"},
    {"italic",         "\033[3m",  "\033[3m"},
    {"underline",      "\033[4m",  "\033[4m"},
    {NULL, NULL, NULL}
};

/* ── Named colour lookup ─────────────────────────────────────── */

static const char *
ddc_resolve_colour_named(const char *name, int is_background)
{
    const loo_colour_entry *e;
    if (!name) return NULL;
    for (e = colour_table; e->name; e++) {
        if (strEQ(name, e->name))
            return is_background ? e->bg : e->fg;
    }
    return NULL;
}

/* ── Resolve Perl SV colour spec → ANSI escape string ────────── */

static const char *
ddc_resolve_colour(pTHX_ SV *colour_spec, int is_background)
{
    /* undef → no colour */
    if (!colour_spec || !SvOK(colour_spec))
        return NULL;

    /* Arrayref [R, G, B] → true colour */
    if (SvROK(colour_spec) && SvTYPE(SvRV(colour_spec)) == SVt_PVAV) {
        AV *rgb = (AV *)SvRV(colour_spec);
        SV **r_sv, **g_sv, **b_sv;
        int r, g, b;
        char *buf;

        if (av_len(rgb) < 2) return NULL;
        r_sv = av_fetch(rgb, 0, 0);
        g_sv = av_fetch(rgb, 1, 0);
        b_sv = av_fetch(rgb, 2, 0);
        if (!r_sv || !g_sv || !b_sv) return NULL;
        r = SvIV(*r_sv); g = SvIV(*g_sv); b = SvIV(*b_sv);

        /* "\033[38;2;R;G;Bm" or "\033[48;2;R;G;Bm" */
        Newx(buf, 32, char);
        snprintf(buf, 32, "\033[%d;2;%d;%d;%dm",
                 is_background ? 48 : 38, r, g, b);
        return buf;
    }

    /* Integer 0-255 → 256-colour */
    if (SvIOK(colour_spec) || (SvPOK(colour_spec) && looks_like_number(colour_spec))) {
        int idx = SvIV(colour_spec);
        if (idx >= 0 && idx <= 255) {
            char *buf;
            Newx(buf, 24, char);
            snprintf(buf, 24, "\033[%d;5;%dm",
                     is_background ? 48 : 38, idx);
            return buf;
        }
    }

    /* String name → table lookup */
    if (SvPOK(colour_spec)) {
        STRLEN len;
        const char *name = SvPV(colour_spec, len);
        return ddc_resolve_colour_named(name, is_background);
    }

    return NULL;
}

/* ── Colour wrap: emit fg + bg + text + reset ────────────────── */

static void
ddc_colour_wrap(pTHX_ SV *buf, const char *fg, const char *bg,
                const char *reset, const char *text, STRLEN len)
{
    if (fg) sv_catpv(buf, fg);
    if (bg) sv_catpv(buf, bg);
    sv_catpvn(buf, text, len);
    if ((fg || bg) && reset) sv_catpv(buf, reset);
}

/* ── Strip all ANSI escape sequences ─────────────────────────── */

static SV *
ddc_strip_colour(pTHX_ SV *input)
{
    STRLEN len;
    const char *src = SvPV(input, len);
    SV *out;
    const char *p = src;
    const char *end = src + len;
    const char *seg_start = src;

    out = newSVpvs("");
    SvGROW(out, len + 1);

    while (p < end) {
        if (*p == '\033' && p + 1 < end && *(p + 1) == '[') {
            /* flush segment before escape */
            if (p > seg_start)
                sv_catpvn(out, seg_start, p - seg_start);
            p += 2;
            while (p < end && *p != 'm')
                p++;
            if (p < end) p++; /* skip 'm' */
            seg_start = p;
        } else {
            p++;
        }
    }
    /* flush remaining */
    if (p > seg_start)
        sv_catpvn(out, seg_start, p - seg_start);

    if (SvUTF8(input))
        SvUTF8_on(out);
    return out;
}

#endif /* LOO_COLOUR_H */
