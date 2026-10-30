#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <string.h>

MODULE = Developer::Dashboard    PACKAGE = Developer::Dashboard::HtmlEscape
PROTOTYPES: DISABLE

# _xs_escape_html(input)
# Escapes the three HTML body-sensitive ASCII bytes in one native pass.
# Input: an undefined or non-reference Perl scalar.
# Output: escaped scalar preserving the input UTF-8 and taint flags.
SV *
_xs_escape_html(input)
    SV *input
  CODE:
    if (!SvOK(input)) {
        RETVAL = newSVpvn("", 0);
    }
    else if (SvROK(input)) {
        croak("Native HTML escaping accepts only scalar values");
    }
    else {
        STRLEN length = 0;
        const char *source = SvPV(input, length);
        if (length > ((((STRLEN)-1) - 1) / 5)) {
            croak("HTML input is too large to escape safely");
        }

        RETVAL = newSVpvn("", 0);
        SvGROW(RETVAL, (length * 5) + 1);
        char *target = SvPVX(RETVAL);
        STRLEN written = 0;

        for (STRLEN index = 0; index < length; index++) {
            switch (source[index]) {
                case '&':
                    memcpy(target + written, "&amp;", 5);
                    written += 5;
                    break;
                case '<':
                    memcpy(target + written, "&lt;", 4);
                    written += 4;
                    break;
                case '>':
                    memcpy(target + written, "&gt;", 4);
                    written += 4;
                    break;
                default:
                    target[written++] = source[index];
                    break;
            }
        }

        target[written] = '\0';
        SvCUR_set(RETVAL, written);
        SvPOK_on(RETVAL);
        if (SvUTF8(input)) {
            SvUTF8_on(RETVAL);
        }
        if (SvTAINTED(input)) {
            SvTAINTED_on(RETVAL);
        }
    }
  OUTPUT:
    RETVAL

# _xs_escape_html_attr(input)
# Escapes all five HTML-sensitive bytes for a quoted attribute in one native pass.
# Input: an undefined or non-reference Perl scalar.
# Output: escaped scalar preserving the input UTF-8 and taint flags.
SV *
_xs_escape_html_attr(input)
    SV *input
  CODE:
    if (!SvOK(input)) {
        RETVAL = newSVpvn("", 0);
    }
    else if (SvROK(input)) {
        croak("Native HTML attribute escaping accepts only scalar values");
    }
    else {
        STRLEN length = 0;
        const char *source = SvPV(input, length);
        if (length > ((((STRLEN)-1) - 1) / 6)) {
            croak("HTML attribute input is too large to escape safely");
        }

        RETVAL = newSVpvn("", 0);
        SvGROW(RETVAL, (length * 6) + 1);
        char *target = SvPVX(RETVAL);
        STRLEN written = 0;

        for (STRLEN index = 0; index < length; index++) {
            switch (source[index]) {
                case '&':
                    memcpy(target + written, "&amp;", 5);
                    written += 5;
                    break;
                case '<':
                    memcpy(target + written, "&lt;", 4);
                    written += 4;
                    break;
                case '>':
                    memcpy(target + written, "&gt;", 4);
                    written += 4;
                    break;
                case '"':
                    memcpy(target + written, "&quot;", 6);
                    written += 6;
                    break;
                case '\'':
                    memcpy(target + written, "&#39;", 5);
                    written += 5;
                    break;
                default:
                    target[written++] = source[index];
                    break;
            }
        }

        target[written] = '\0';
        SvCUR_set(RETVAL, written);
        SvPOK_on(RETVAL);
        if (SvUTF8(input)) {
            SvUTF8_on(RETVAL);
        }
        if (SvTAINTED(input)) {
            SvTAINTED_on(RETVAL);
        }
    }
  OUTPUT:
    RETVAL

# _xs_escape_html_chunked(input)
# Escapes sparse HTML-sensitive bytes by copying intervening source spans.
# Input: an undefined or non-reference Perl scalar.
# Output: escaped scalar preserving the input UTF-8 and taint flags.
SV *
_xs_escape_html_chunked(input)
    SV *input
  CODE:
    if (!SvOK(input)) {
        RETVAL = newSVpvn("", 0);
    }
    else if (SvROK(input)) {
        croak("Native HTML escaping accepts only scalar values");
    }
    else {
        STRLEN length = 0;
        const char *source = SvPV(input, length);
        if (length > ((((STRLEN)-1) - 1) / 5)) {
            croak("HTML input is too large to escape safely");
        }

        RETVAL = newSVpvn("", 0);
        SvGROW(RETVAL, (length * 5) + 1);
        char *target = SvPVX(RETVAL);
        const char *cursor = source;
        STRLEN remaining = length;
        STRLEN written = 0;

        while (remaining) {
            const char *amp = (const char *)memchr(cursor, '&', remaining);
            const char *lt = (const char *)memchr(cursor, '<', remaining);
            const char *gt = (const char *)memchr(cursor, '>', remaining);
            const char *match = amp;
            if (!match || (lt && lt < match)) match = lt;
            if (!match || (gt && gt < match)) match = gt;
            if (!match) {
                memcpy(target + written, cursor, remaining);
                written += remaining;
                break;
            }

            STRLEN span = (STRLEN)(match - cursor);
            if (span) {
                memcpy(target + written, cursor, span);
                written += span;
            }
            if (*match == '&') {
                memcpy(target + written, "&amp;", 5);
                written += 5;
            }
            else if (*match == '<') {
                memcpy(target + written, "&lt;", 4);
                written += 4;
            }
            else {
                memcpy(target + written, "&gt;", 4);
                written += 4;
            }
            cursor = match + 1;
            remaining = length - (STRLEN)(cursor - source);
        }

        target[written] = '\0';
        SvCUR_set(RETVAL, written);
        SvPOK_on(RETVAL);
        if (SvUTF8(input)) {
            SvUTF8_on(RETVAL);
        }
        if (SvTAINTED(input)) {
            SvTAINTED_on(RETVAL);
        }
    }
  OUTPUT:
    RETVAL
