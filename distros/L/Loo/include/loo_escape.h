#ifndef LOO_ESCAPE_H
#define LOO_ESCAPE_H

/* ── Forward declarations ─────────────────────────────────────── */

static SV * ddc_escape_string(pTHX_ const char *str, STRLEN len, int useqq, int is_utf8);
static int  ddc_key_needs_quote(const char *key, STRLEN len);
static SV * ddc_format_number(pTHX_ SV *sv);

/* ── ddc_key_needs_quote ──────────────────────────────────────── */
/* Returns 1 if the hash key must be quoted.
   Bareword-safe keys: /^[A-Za-z_][A-Za-z0-9_]*$/ that aren't
   purely numeric looking. */

static int
ddc_key_needs_quote(const char *key, STRLEN len)
{
    STRLEN i;
    if (len == 0) return 1;

    /* First char must be [A-Za-z_] */
    if (!isALPHA(key[0]) && key[0] != '_')
        return 1;

    for (i = 1; i < len; i++) {
        if (!isALNUM(key[i]))
            return 1;
    }

    /* A purely numeric-looking key like "0" would have failed the
       isALPHA check above, so no extra check needed. */
    return 0;
}

/* ── ddc_escape_string ────────────────────────────────────────── */
/* Escape a string value for dump output.
   useqq=0 → single-quoted with \\ and \' escapes
   useqq=1 → double-quoted with full \n \t \xHH \x{HHHH} escapes
   Returns a new SV containing the escaped content (WITHOUT surrounding quotes). */

static SV *
ddc_escape_string(pTHX_ const char *str, STRLEN len, int useqq, int is_utf8)
{
    SV *out;
    const char *p = str;
    const char *end = str + len;
    const char *seg_start;

    /* Pre-allocate generously */
    out = newSVpvs("");
    SvGROW(out, len + 16);

    if (!useqq) {
        /* Single-quote mode: only escape \ and ' */
        seg_start = p;
        while (p < end) {
            if (*p == '\\' || *p == '\'') {
                if (p > seg_start)
                    sv_catpvn(out, seg_start, p - seg_start);
                sv_catpvn(out, "\\", 1);
                sv_catpvn(out, p, 1);
                p++;
                seg_start = p;
            } else {
                p++;
            }
        }
        if (p > seg_start)
            sv_catpvn(out, seg_start, p - seg_start);
    } else {
        /* Double-quote mode: full escaping */
        while (p < end) {
            unsigned char c = (unsigned char)*p;

            if (c == '\\') {
                sv_catpvn(out, "\\\\", 2);
            } else if (c == '"') {
                sv_catpvn(out, "\\\"", 2);
            } else if (c == '$') {
                sv_catpvn(out, "\\$", 2);
            } else if (c == '@') {
                sv_catpvn(out, "\\@", 2);
            } else if (c == '\n') {
                sv_catpvn(out, "\\n", 2);
            } else if (c == '\r') {
                sv_catpvn(out, "\\r", 2);
            } else if (c == '\t') {
                sv_catpvn(out, "\\t", 2);
            } else if (c == '\f') {
                sv_catpvn(out, "\\f", 2);
            } else if (c == '\b') {
                sv_catpvn(out, "\\b", 2);
            } else if (c == '\a') {
                sv_catpvn(out, "\\a", 2);
            } else if (c == '\033') {
                sv_catpvn(out, "\\e", 2);
            } else if (c == '\0') {
                sv_catpvn(out, "\\0", 2);
            } else if (is_utf8 && c >= 0x80) {
                /* UTF-8 multi-byte sequence → decode and emit \x{HHHH} */
                STRLEN char_len;
                UV uv = utf8_to_uvchr_buf((const U8 *)p, (const U8 *)end, &char_len);
                if (char_len > 0 && uv != 0) {
                    if (uv > 0x7F) {
                        sv_catpvf(out, "\\x{%"UVxf"}", uv);
                    } else {
                        sv_catpvn(out, p, char_len);
                    }
                    p += char_len;
                    continue;
                } else {
                    /* Malformed: emit as \xHH */
                    sv_catpvf(out, "\\x%02x", c);
                }
            } else if (c < 0x20 || c == 0x7F) {
                /* Other control chars */
                sv_catpvf(out, "\\x%02x", c);
            } else if (!is_utf8 && c >= 0x80) {
                /* High-bit bytes in non-UTF8 string */
                sv_catpvf(out, "\\x%02x", c);
            } else {
                sv_catpvn(out, p, 1);
            }
            p++;
        }
    }

    if (is_utf8)
        SvUTF8_on(out);

    return out;
}

/* ── Portable infinity / NaN checks ───────────────────────────── */
/* Avoid Perl_isinf / Perl_isnan which are broken on Solaris
   with perl ≤ 5.14 (Perl_fp_class macro takes wrong arg count). */
#if defined(__GNUC__) || defined(__clang__)
#  define ddc_isinf(nv) __builtin_isinf(nv)
#  define ddc_isnan(nv) __builtin_isnan(nv)
#else
#  define ddc_isinf(nv) Perl_isinf(nv)
#  define ddc_isnan(nv) Perl_isnan(nv)
#endif

/* ── ddc_format_number ────────────────────────────────────────── */
/* Format a numeric SV. Returns a new SV with the formatted string.
   Detects integer vs float, handles inf/nan. */

static SV *
ddc_format_number(pTHX_ SV *sv)
{
    /* If the SV has only IOK (integer), format as integer */
    if (SvIOK(sv) && !SvNOK(sv)) {
        IV iv = SvIV(sv);
        return newSVpvf("%"IVdf, iv);
    }

    /* If the SV has NOK (float), format as float */
    if (SvNOK(sv)) {
        NV nv = SvNV(sv);
        /* Handle special values */
        if (ddc_isnan(nv))
            return newSVpvs("'NaN'");
        if (ddc_isinf(nv))
            return nv > 0 ? newSVpvs("'Inf'") : newSVpvs("'-Inf'");

        /* Use Perl's default stringification for NV */
        return newSVpvf("%"NVgf, nv);
    }

    /* String that looks numeric — use as-is */
    if (SvPOK(sv) && looks_like_number(sv)) {
        STRLEN len;
        const char *pv = SvPV(sv, len);
        return newSVpvn(pv, len);
    }

    /* Fallback: stringify */
    {
        STRLEN len;
        const char *pv = SvPV(sv, len);
        return newSVpvn(pv, len);
    }
}

#endif /* LOO_ESCAPE_H */
