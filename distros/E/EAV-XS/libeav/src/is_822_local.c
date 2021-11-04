#include <eav.h>
#include <ctype.h>
#include <eav/private.h>

/*
 * local-part = word *("." word)
 * word = atom / quoted-string
 * atom = 1*<any CHAR except specials, SPACE and CTLs>
 * quoted-string = <"> *(qtext/quoted-pair) <">
 * qtext       =  <any CHAR excepting <">,     ; => may be folded
 *                 "\" & CR, and including
 *                 linear-white-space>
 * quoted-pair = "\" CHAR
 * CHAR = <any ASCII character> ; ( 0-177, 0.-127.)
 * specials = "(" / ")" / "<" / ">" / "@"   ; Must be in quoted-
 *          / "," / ";" / ":" / "\" / <">   ; string, to use
 *          / "." / "[" / "]"               ; within a word.
 * CTL = <any ASCII control     ; ( 0- 37, 0.- 31.)
 *        character and DEL>    ; ( 177, 127.)
 *
 *
 * CR          =  <ASCII CR, carriage return>  ; (     15,      13.)
 * CRLF        =  CR LF
 * HTAB        =  <ASCII HT, horizontal-tab>   ; (     11,       9.)
 * LF          =  <ASCII LF, linefeed>         ; (     12,      10.)
 * LWSP-char   =  SPACE / HTAB                 ; semantics = SPACE
 * linear-white-space =  1*([CRLF] LWSP-char)  ; semantics = SPACE
 *                                             ; CRLF => folding
 */
extern int
is_822_local (const char *start, const char *end)
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
        if (!quote) {
            /* SPACE and CTLs outside of quotes & quoted-pairs are forbidden.
             * See SPACE check below.
             */
            if (!qpair && ISCNTRL(ch))
                return inverse(EEAV_LPART_CTRL_CHAR);
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
        else if (qpair) {
            /* any CHAR is allowed in quote-pair */
            qpair = 0;
        }
        else {
            /* qtext = <any CHAR excepting <">, "\" & CR, and including linear-white-space> */
            switch (ch) {
            case '"':  { quote = 0; break; }
            case '\\': { qpair = 1; break; }
            /* excepting CR, and including linear-white-space> */
            case '\r': {
                /* allow folding, i.e. 1*([CRLF] LWSP-char) */
                if ((cp + 2) <= end && cp[1] == '\n' && (cp[2] == '\t' || cp[2] == ' '))
                    cp += 2;
                else /* invalid folding syntax */
                    return inverse(EEAV_LPART_INVALID_FOLDING);
                break;
            }
            /* XXX: there is should be a check for single LF ... */
            }
        }
    }

    /* local-part with open quote is not allowed */
    if (quote)
        return inverse(EEAV_LPART_UNQUOTED);

    return EEAV_NO_ERROR;
}
