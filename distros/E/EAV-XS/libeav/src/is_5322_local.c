#include <eav.h>
#include <ctype.h>
#include <stdio.h>
#include <eav/private.h>

/*
 * local-part = dot-atom / quoted-string / obs-local-part
 * dot-atom = [CFWS] dot-atom-text [CFWS]
 * dot-atom-text = 1*atext *("." 1*atext)
 * atext = ALPHA / DIGIT /  ; Printable US-ASCII
            "!" / "#" /     ; characters not including
            "$" / "%" /     ; specials. Used for atoms.
            "&" / "’" /
            "*" / "+" /
            "-" / "/" /
            "=" / "?" /
            "^" / "_" /
            "‘" / "{" /
            "|" / "}" /
            "~"
 * quoted-string = [CFWS] DQUOTE *([FWS] qcontent) [FWS] DQUOTE [CFWS]
 * FWS = ([*WSP CRLF] 1*WSP) / obs-FWS
 * obs-FWS = 1*WSP *(CRLF 1*WSP)
 * qcontent = qtext / quoted-pair
 * qtext = %d33 / %d35-91 / %d93-126 / obs-qtext
 * obs-qtext = obs-NO-WS-CTL
 * obs-NO-WS-CTL = %d1-8 / %d11 / %d12 / %d14-31 / %d127
 * quoted-pair = ("\" (VCHAR / WSP)) / obs-qp
 * WSP = SP / HTAB
 * VCHAR = %x21-7E
 * obs-qp = "\" (%d0 / obs-NO-WS-CTL / LF / CR)
 */
extern int
is_5322_local (const char *start, const char *end)
{
    const char *cp;
    int ch;
    int qpair = 0;
    int quote = 0;


    if (start == end)
        return inverse(EEAV_LPART_EMPTY);

    for (cp = start; cp < end && (ch = *(unsigned char *) cp) != 0; cp++) {
        if (ch > 127)
            return inverse(EEAV_LPART_NOT_ASCII);
        /* rfc5322 allows next CTRLs in qtext:
         *    %d1-8 / %d11 / %d12 / %d14-31 / %d127
         * in quoted-pairs:
         *    %d0 / %d1-8 / %d11 / %d12 / %d14-31 / %d127 / LF / CR
         */
        if (ISCNTRL(ch) && !quote && !qpair)
            return inverse(EEAV_LPART_CTRL_CHAR);
        if (!quote) {
            switch (ch) {
            case '"': {
                /* quote-strings are allowed at the start
                 * or with preciding '.' only
                 */
                if (cp == start || cp[-1] == '.')
                    quote = 1;
                else
                    return inverse(EEAV_LPART_MISPLACED_QUOTE);
            } break;
            case '.': {
                /* '.' is allowed after an atom and only once */
                if (cp == start || ((cp + 1) < end && cp[1] == '.'))
                    return inverse(EEAV_LPART_TOO_MANY_DOTS);
            } break;
            /* specials & SPACE are not allowed outside quote-string */
            case '(': case ')': case '<': case '>': case '@':
            case ',': case ';': case ':': case '\\':
            case '[': case ']': case ' ':
                return inverse(EEAV_LPART_SPECIAL);
            }
        }
        else if (qpair) /* everything, even control chars */
            qpair = 0;
        else {
            switch (ch) {
            case '"':   quote = 0; break;
            case '\\':  qpair = 1; break;
            /* the next chars are not allowed in qtext: */
            /* 1) they must be in quoted-pair(s). */
            /* 2) either they are permitted right after first DQUOTE
             *    or before the last DQUOTE only.
             */
            case '\n': case '\r':
            case '\t': case ' ':
                switch (cp[-1]) {
                    case '"':
                    case '\n': case '\r': case '\t': case ' ':
                        goto next;
                }

                if (cp >= end - 1)
                    break;

                switch (cp[1]) {
                    case '"':
                    case '\n': case '\r': case '\t': case ' ':
                        break;
                    default:
                        return inverse(EEAV_LPART_UNQUOTED_FWS);
                }
next:
            break;
            } /* switch (ch) */
        } /* else */
    } /* for (cp = start; ... */

    /* local-part with open quote is not allowed */
    if (quote)
        return inverse(EEAV_LPART_UNQUOTED);

    return EEAV_NO_ERROR;
}
