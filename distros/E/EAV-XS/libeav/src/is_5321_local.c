#include <eav.h>
#include <ctype.h>
#include <eav/private.h>

/*
 * Local-part = Dot-string / Quoted-string
 * Dot-string = Atom *("." Atom)
 * Atom = 1*atext
 *
 * <atext> is not defined in rfc5321, note:

   [...] Terminals not defined in
   this document, such as ALPHA, DIGIT, SP, CR, LF, CRLF, are as defined
   in the "core" syntax in Section 6 of RFC 5234 [7] or in the message
   format syntax in RFC 5322 [4].

 * (this taken from rfc5322)
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
 * Quoted-string = DQUOTE *QcontentSMTP DQUOTE
 * QcontentSMTP = qtextSMTP / quoted-pairSMTP
 * quoted-pairSMTP = %d92 %d32-126
 * qtextSMTP = %d32-33 / %d35-91 / %d93-126
 */
extern int
is_5321_local (const char *start, const char *end)
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
        /* rfc5321 does NOT allowing ANY control chars */
        if (ISCNTRL(ch))
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
                if (cp == start || (cp + 1) == end)
                    return inverse(EEAV_LPART_MISPLACED_DOT);
                if ((cp + 1) < end && (cp[1] == '.'))
                    return inverse(EEAV_LPART_TOO_MANY_DOTS);
            } break;
            /* specials & SPACE are not allowed outside quote-string */
            case '(': case ')': case '<': case '>': case '@':
            case ',': case ';': case ':': case '\\':
            case '[': case ']': case ' ':
                return inverse(EEAV_LPART_SPECIAL);
            }
        }
        else if (qpair) /* anything that is not control char. */
            qpair = 0;
        else {
            switch (ch) {
            case '"':   quote = 0; break;
            case '\\':  qpair = 1; break;
            }
        }
    }

    /* local-part with open quote is not allowed */
    if (quote)
        return inverse(EEAV_LPART_UNQUOTED);

    return EEAV_NO_ERROR;
}
