#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* okchr = %x21 / %x23-3c / %x3e-5b / %x5d-7e ; VCHAR minus \ and " and = */
PERL_STATIC_INLINE int
is_okchr(unsigned char c)
{
    return (c == 0x21 ||
            (c >= 0x23 && c <= 0x3C) ||
            (c >= 0x3E && c <= 0x5B) ||
            (c >= 0x5D && c <= 0x7E));
}

/* Check if string can be used as a bare logfmt value (matches KEY_RE) */
static int
is_bare_value(const char *s, STRLEN len)
{
    STRLEN i;
    if (len == 0)
        return 0;
    for (i = 0; i < len; i++) {
        if (!is_okchr((unsigned char)s[i]))
            return 0;
    }
    return 1;
}

/*
 * Check if a Unicode codepoint needs \x{XX} escaping.
 * This is called AFTER \, ", \t, \n, \r are handled.
 * Matches Perl's [\pC\v] — General Category C (Cc, Cf, Co, Cs) plus
 * vertical whitespace characters.
 */
static int
needs_escape(UV cp)
{
    /* Cc: C0 controls (0x00-0x1F) — includes \t, \n, \r but those are
     * already handled before this function is called */
    if (cp <= 0x1F)
        return 1;

    /* DEL */
    if (cp == 0x7F)
        return 1;

    /* C1 controls (0x80-0x9F), includes NEL (0x85) */
    if (cp >= 0x80 && cp <= 0x9F)
        return 1;

    /* Vertical whitespace not in Cc: LINE SEPARATOR, PARAGRAPH SEPARATOR */
    if (cp == 0x2028 || cp == 0x2029)
        return 1;

    /* Cf (format) characters — comprehensive list */
    if (cp == 0x00AD)   return 1;  /* SOFT HYPHEN */
    if (cp >= 0x0600 && cp <= 0x0605) return 1;
    if (cp == 0x061C)   return 1;
    if (cp == 0x06DD)   return 1;
    if (cp == 0x070F)   return 1;
    if (cp == 0x08E2)   return 1;
    if (cp == 0x180E)   return 1;
    if (cp >= 0x200B && cp <= 0x200F) return 1;  /* includes ZWJ (0x200D) */
    if (cp >= 0x202A && cp <= 0x202E) return 1;
    if (cp >= 0x2060 && cp <= 0x2064) return 1;
    if (cp >= 0x2066 && cp <= 0x206F) return 1;
    if (cp == 0xFEFF)   return 1;  /* BOM */
    if (cp >= 0xFFF9 && cp <= 0xFFFB) return 1;

    /* Co (private use) */
    if (cp >= 0xE000 && cp <= 0xF8FF) return 1;

    /* Cs (surrogates) — shouldn't appear in valid strings */
    if (cp >= 0xD800 && cp <= 0xDFFF) return 1;

    /* Higher plane Cf */
    if (cp == 0x110BD || cp == 0x110CD) return 1;
    if (cp >= 0x13430 && cp <= 0x1343F) return 1;
    if (cp >= 0x1BCA0 && cp <= 0x1BCA3) return 1;
    if (cp >= 0x1D173 && cp <= 0x1D17A) return 1;
    if (cp == 0xE0001)  return 1;
    if (cp >= 0xE0020 && cp <= 0xE007F) return 1;

    /* Higher plane Co (private use) */
    if (cp >= 0xF0000 && cp <= 0xFFFFD) return 1;
    if (cp >= 0x100000 && cp <= 0x10FFFD) return 1;

    /* Noncharacters (subset of Cn) */
    if ((cp & 0xFFFE) == 0xFFFE) return 1;
    if (cp >= 0xFDD0 && cp <= 0xFDEF) return 1;

    return 0;
}

/*
 * Quote a string value for logfmt output.
 * Input: a Perl SV (character string, may have UTF8 flag).
 * Output: a new SV containing the quoted byte string (no UTF8 flag),
 *         wrapped in double quotes, with proper escaping.
 */
static SV *
quote_string_xs(pTHX_ SV *input)
{
    STRLEN len;
    const char *s = SvPV(input, len);
    bool is_utf8 = cBOOL(SvUTF8(input));
    const char *end = s + len;
    SV *out;

    /* Optimistic pre-allocate: most chars pass through or become 2-char escapes */
    out = newSV(len * 2 + 3);
    SvPOK_on(out);
    sv_catpvn(out, "\"", 1);

    while (s < end) {
        UV cp;
        STRLEN char_len;

        if (is_utf8) {
            cp = utf8_to_uvchr_buf((const U8 *)s, (const U8 *)end, &char_len);
            if (char_len == 0) {
                /* Malformed UTF-8, skip byte */
                s++;
                continue;
            }
        } else {
            cp = (UV)(unsigned char)*s;
            char_len = 1;
        }

        if (cp == '\\') {
            sv_catpvn(out, "\\\\", 2);
        } else if (cp == '"') {
            sv_catpvn(out, "\\\"", 2);
        } else if (cp == '\t') {
            sv_catpvn(out, "\\t", 2);
        } else if (cp == '\n') {
            sv_catpvn(out, "\\n", 2);
        } else if (cp == '\r') {
            sv_catpvn(out, "\\r", 2);
        } else if (cp >= 0x20 && cp < 0x7F) {
            /* Common ASCII printable — pass through directly */
            sv_catpvn(out, s, 1);
        } else if (needs_escape(cp)) {
            /* Control, format, or vertical whitespace — \x{XX} each UTF-8 byte */
            U8 utf8buf[UTF8_MAXBYTES + 1];
            U8 *utf8end = uvchr_to_utf8(utf8buf, cp);
            STRLEN utf8len = utf8end - utf8buf;
            STRLEN j;
            for (j = 0; j < utf8len; j++) {
                char hexbuf[8];
                int hexlen = snprintf(hexbuf, sizeof(hexbuf), "\\x{%02x}", utf8buf[j]);
                sv_catpvn(out, hexbuf, hexlen);
            }
        } else {
            /* Safe non-ASCII (e.g. ë, ü) — output as UTF-8 bytes */
            if (is_utf8) {
                sv_catpvn(out, s, char_len);
            } else {
                /* Latin-1 codepoint → UTF-8 encode */
                U8 utf8buf[UTF8_MAXBYTES + 1];
                U8 *utf8end = uvchr_to_utf8(utf8buf, cp);
                sv_catpvn(out, (const char *)utf8buf, utf8end - utf8buf);
            }
        }

        s += char_len;
    }

    sv_catpvn(out, "\"", 1);
    /* Result is bytes — do NOT set UTF8 flag */
    return out;
}

/*
 * Sanitize a key: replace non-okchr characters with '?'.
 * Empty keys become '~'.
 * Returns a new mortal SV.
 */
static SV *
sanitize_key(pTHX_ SV *key_sv)
{
    STRLEN len;
    const char *key_s;
    SV *result;

    if (!SvOK(key_sv)) {
        return sv_2mortal(newSVpvn("~", 1));
    }

    key_s = SvPV(key_sv, len);
    if (len == 0) {
        return sv_2mortal(newSVpvn("~", 1));
    }

    if (SvUTF8(key_sv)) {
        /* Walk codepoint by codepoint */
        const char *s = key_s;
        const char *end = s + len;
        result = newSVpvn("", 0);
        while (s < end) {
            STRLEN char_len;
            UV cp = utf8_to_uvchr_buf((const U8 *)s, (const U8 *)end, &char_len);
            if (char_len == 0) { s++; continue; }
            if (cp <= 0x7E && is_okchr((unsigned char)cp)) {
                sv_catpvn(result, s, char_len);
            } else {
                sv_catpvn(result, "?", 1);
            }
            s += char_len;
        }
        return sv_2mortal(result);
    } else {
        /* Byte mode — modify in place on a copy */
        char *buf;
        STRLEN i;
        result = newSVpvn(key_s, len);
        buf = SvPVX(result);
        for (i = 0; i < len; i++) {
            if (!is_okchr((unsigned char)buf[i])) {
                buf[i] = '?';
            }
        }
        return sv_2mortal(result);
    }
}

/* Forward declaration */
static AV *
pairs_to_kvstr_impl(pTHX_ SV *self, AV *aref, HV *seen, SV *prefix);

/*
 * Core implementation of _pairs_to_kvstr_aref.
 * Returns a new (non-mortal) AV* of key=value strings.
 */
static AV *
pairs_to_kvstr_impl(pTHX_ SV *self, AV *aref, HV *seen, SV *prefix)
{
    AV *kvstrs = newAV();
    SSize_t alen = av_len(aref); /* last index, -1 if empty */
    SSize_t i;

    for (i = 0; i <= alen; i += 2) {
        SV **key_svp, **val_svp;
        SV *key, *value, *str;
        STRLEN val_len;
        const char *val_s;

        /* Get and sanitize key */
        key_svp = av_fetch(aref, i, 0);
        key = sanitize_key(aTHX_ key_svp ? *key_svp : &PL_sv_undef);

        /* Prepend prefix if defined */
        if (prefix && SvOK(prefix)) {
            SV *prefixed = sv_2mortal(newSVsv(prefix));
            sv_catpvn(prefixed, ".", 1);
            sv_catsv(prefixed, key);
            key = prefixed;
        }

        /* Build "key=" early so the fast path can just append */
        str = newSVsv(key);
        sv_catpvn(str, "=", 1);

        /* Get value */
        val_svp = (i + 1 <= alen) ? av_fetch(aref, i + 1, 0) : NULL;
        value = val_svp ? *val_svp : &PL_sv_undef;

        /* Fast path: defined non-ref scalar that's a bare value */
        if (SvOK(value) && !SvROK(value)) {
            val_s = SvPV(value, val_len);
            if (is_bare_value(val_s, val_len)) {
                sv_catpvn(str, val_s, val_len);
                av_push(kvstrs, str);
                continue;
            }
        }

        /* Handle coderef: call it to get the actual value */
        if (SvROK(value) && SvTYPE(SvRV(value)) == SVt_PVCV) {
            dSP;
            int count;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            PUTBACK;
            count = call_sv(value, G_SCALAR);
            SPAGAIN;
            if (count > 0) {
                value = SvREFCNT_inc(POPs);
            } else {
                value = &PL_sv_undef;
            }
            PUTBACK;
            FREETMPS;
            LEAVE;
            value = sv_2mortal(value);
        }

        /* Handle ref-to-ref: flog via String::Flogger */
        if (SvROK(value) && !sv_isobject(value) && SvROK(SvRV(value))) {
            dSP;
            int count;
            SV *flogger_class;
            SV *derefed = SvRV(value);
            AV *flog_args;
            SV *flog_args_ref;

            /* Call $self->string_flogger to get the class */
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(self);
            PUTBACK;
            count = call_method("string_flogger", G_SCALAR);
            SPAGAIN;
            flogger_class = (count > 0) ? POPs : &PL_sv_undef;
            SvREFCNT_inc(flogger_class);
            PUTBACK;
            FREETMPS;
            LEAVE;

            /* Call $flogger_class->flog([ '%s', $$value ]) */
            flog_args = newAV();
            av_push(flog_args, newSVpvn("%s", 2));
            av_push(flog_args, newSVsv(derefed));
            flog_args_ref = sv_2mortal(newRV_noinc((SV*)flog_args));

            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(sv_2mortal(flogger_class));
            XPUSHs(flog_args_ref);
            PUTBACK;
            count = call_method("flog", G_SCALAR);
            SPAGAIN;
            if (count > 0) {
                value = SvREFCNT_inc(POPs);
            } else {
                value = &PL_sv_undef;
            }
            PUTBACK;
            FREETMPS;
            LEAVE;
            value = sv_2mortal(value);
        }

        if (!SvOK(value)) {
            /* undef → ~missing~ */
            value = sv_2mortal(newSVpvn("~missing~", 9));
        } else if (SvROK(value)) {
            UV refaddr = PTR2UV(SvRV(value));
            char refaddr_str[32];
            int refaddr_len = snprintf(refaddr_str, sizeof(refaddr_str),
                                       "%" UVuf, refaddr);
            SV **seen_svp = hv_fetch(seen, refaddr_str, refaddr_len, 0);

            if (seen_svp && SvOK(*seen_svp)) {
                /* Already seen this ref — use the backreference */
                value = *seen_svp;
            } else if (!sv_isobject(value) &&
                       SvTYPE(SvRV(value)) == SVt_PVAV) {
                /* Unblessed arrayref — recurse */
                AV *arr = (AV*)SvRV(value);
                SSize_t arr_len = av_len(arr);
                AV *new_aref = newAV();
                AV *sub_kvstrs;
                SSize_t j, sub_len;
                SV *backref;

                /* Store backreference in seen */
                backref = newSVpvf("&%" SVf, SVfARG(key));
                hv_store(seen, refaddr_str, refaddr_len, backref, 0);

                /* Build pairs: [ 0 => arr[0], 1 => arr[1], ... ] */
                for (j = 0; j <= arr_len; j++) {
                    SV **elem = av_fetch(arr, j, 0);
                    av_push(new_aref, newSViv(j));
                    av_push(new_aref, elem ? newSVsv(*elem) : newSVsv(&PL_sv_undef));
                }

                sub_kvstrs = pairs_to_kvstr_impl(aTHX_ self, new_aref, seen, key);
                sub_len = av_len(sub_kvstrs);
                for (j = 0; j <= sub_len; j++) {
                    SV **svp = av_fetch(sub_kvstrs, j, 0);
                    if (svp) av_push(kvstrs, newSVsv(*svp));
                }
                SvREFCNT_dec(new_aref);
                SvREFCNT_dec(sub_kvstrs);
                SvREFCNT_dec(str);
                continue; /* next KEY */
            } else if (!sv_isobject(value) &&
                       SvTYPE(SvRV(value)) == SVt_PVHV) {
                /* Unblessed hashref — recurse with sorted keys */
                HV *hv = (HV*)SvRV(value);
                AV *sorted_keys;
                AV *new_aref;
                AV *sub_kvstrs;
                SSize_t j, nkeys, sub_len;
                SV *backref;
                HE *entry;

                /* Store backreference in seen */
                backref = newSVpvf("&%" SVf, SVfARG(key));
                hv_store(seen, refaddr_str, refaddr_len, backref, 0);

                /* Collect and sort keys */
                sorted_keys = newAV();
                hv_iterinit(hv);
                while ((entry = hv_iternext(hv))) {
                    av_push(sorted_keys, newSVsv(hv_iterkeysv(entry)));
                }
                nkeys = av_len(sorted_keys);
                if (nkeys >= 1) {
                    sortsv(AvARRAY(sorted_keys), nkeys + 1, Perl_sv_cmp);
                }

                /* Build pairs from sorted keys */
                new_aref = newAV();
                for (j = 0; j <= nkeys; j++) {
                    SV **kp = av_fetch(sorted_keys, j, 0);
                    if (kp) {
                        STRLEN klen;
                        const char *ks = SvPV(*kp, klen);
                        SV **vp = hv_fetch(hv, ks,
                                           SvUTF8(*kp) ? -(I32)klen : (I32)klen, 0);
                        av_push(new_aref, newSVsv(*kp));
                        av_push(new_aref, vp ? newSVsv(*vp) : newSVsv(&PL_sv_undef));
                    }
                }

                sub_kvstrs = pairs_to_kvstr_impl(aTHX_ self, new_aref, seen, key);
                sub_len = av_len(sub_kvstrs);
                for (j = 0; j <= sub_len; j++) {
                    SV **svp = av_fetch(sub_kvstrs, j, 0);
                    if (svp) av_push(kvstrs, newSVsv(*svp));
                }
                SvREFCNT_dec(sorted_keys);
                SvREFCNT_dec(new_aref);
                SvREFCNT_dec(sub_kvstrs);
                SvREFCNT_dec(str);
                continue; /* next KEY */
            } else {
                /* Other ref types — stringify */
                STRLEN slen;
                const char *ss;
                SV *strval = newSVpvn("", 0);
                sv_catsv(strval, value);
                value = sv_2mortal(strval);
            }
        }

        /* Append value (bare or quoted) to the "key=" we built earlier */
        val_s = SvPV(value, val_len);
        if (is_bare_value(val_s, val_len)) {
            sv_catpvn(str, val_s, val_len);
        } else {
            SV *quoted = quote_string_xs(aTHX_ value);
            sv_catsv(str, quoted);
            SvREFCNT_dec(quoted);
        }

        av_push(kvstrs, str);
    }

    return kvstrs;
}


MODULE = Log::Fmt::XS    PACKAGE = Log::Fmt::XS

PROTOTYPES: DISABLE

SV *
_pairs_to_kvstr_aref(self, aref_ref, ...)
    SV *self
    SV *aref_ref
  PREINIT:
    AV *aref;
    HV *seen;
    SV *prefix;
    AV *result;
  CODE:
    if (!SvROK(aref_ref) || SvTYPE(SvRV(aref_ref)) != SVt_PVAV) {
        croak("Second argument must be an array reference");
    }
    aref = (AV *)SvRV(aref_ref);

    /* Handle optional $seen hashref */
    if (items >= 3 && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVHV) {
        seen = (HV *)SvRV(ST(2));
    } else {
        seen = newHV();
        sv_2mortal((SV*)seen);
    }

    /* Handle optional $prefix */
    if (items >= 4 && SvOK(ST(3))) {
        prefix = ST(3);
    } else {
        prefix = NULL;
    }

    result = pairs_to_kvstr_impl(aTHX_ self, aref, seen, prefix);
    RETVAL = newRV_noinc((SV *)result);
  OUTPUT:
    RETVAL

SV *
_quote_string(input)
    SV *input
  CODE:
    RETVAL = quote_string_xs(aTHX_ input);
  OUTPUT:
    RETVAL
