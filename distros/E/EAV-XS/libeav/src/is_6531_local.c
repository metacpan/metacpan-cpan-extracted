#include <stdio.h>
#include <eav.h>
#include <eav/private.h>
#include "utf8_decode.h"


/* is_6531_local: based on rfc5321 with additional notes:

    3.3. Extended Mailbox Address Syntax

    The definition of <atext> is extended to permit both the RFC 5321
    definition and a UTF-8 string. That string MUST NOT contain any
    of the ASCII graphics or control characters.
       ^^^^^^^^^^^^^^^^^^

 * See the mail archive of the Errata #4996 of RFC6531:
    https://www.rfc-editor.org/errata_search.php?rfc=6531&eid=4996
    https://www.ietf.org/mail-archive/web/ima/current/msg05506.html
 * According to RFC20, section "4.2", exclude next characters:
 * atext = ALPHA / DIGIT /
            "!" / "$" /
            "%" / "&" /
            "'" / "*" / 
            "+" / "-" / 
            "/" / "=" /
            "?" / "_"
 * So, exlcuded charactes are: "#", "^", "`", "{", "}", "|", "~"

 * sub-domain =/ U-label
 * atext =/ UTF8-non-ascii
    ; extend the implicit definition of atext in
    ; RFC 5321, Section 4.1.2, which ultimately points to
    ; the actual definition in RFC 5322, Section 3.2.3
 * qtextSMTP =/ UTF8-non-ascii
 */
extern int
is_6531_local (const char *start, const char *end)
{
    int qpair = 0;
    int quote = 0;
    int ch;
    int prev = 0; /* previous index of non-ASCII character */
    utf8_decode_t u;


    if (start == end)
        return inverse(EEAV_LPART_EMPTY);

    utf8_decode_init (start, end - start, &u);
    while ((ch = utf8_decode_next (&u)) >= 0) {
        /* skip non-ASCII characters */
        if (ch > 0x007f)
            continue;

        /* rfc5321 does not allow any CTRL chars */
#ifndef RFC6531_FOLLOW_RFC5322
        if (ISCNTRL(ch))
            return inverse(EEAV_LPART_CTRL_CHAR);
#endif

        if (!quote) {
#ifdef RFC6531_FOLLOW_RFC5322
            /* rfc5322 allows next CTRLs in qtext:
             *    %d1-8 / %d11 / %d12 / %d14-31 / %d127
             * in quoted-pairs:
             *    %d0 / %d1-8 / %d11 / %d12 / %d14-31 / %d127 / LF / CR
             */
            if (!qpair && ISCNTRL(ch))
                return inverse(EEAV_LPART_CTRL_CHAR);
#endif
            switch (ch) {
            case '"': {
                /* quote-strings are allowed at the start
                 * or with preciding '.' only
                 */
                if (prev == 0 || start[prev] == '.')
                    quote = 1;
                else
                    return inverse(EEAV_LPART_MISPLACED_QUOTE);
            } break;
            case '.': {
                /* '.' is allowed after an atom and only once */
                int pos = utf8_decode_at_byte(&u);
                if (pos >= 1 && start[prev] == '.')
                    return inverse(EEAV_LPART_TOO_MANY_DOTS);
                if (pos == 0 || (start + pos + 1) == end)
                    return inverse(EEAV_LPART_MISPLACED_DOT);
            } break;
            /* specials & SPACE are not allowed outside quote-string */
            case '(': case ')': case '<': case '>': case '@':
            case ',': case ';': case ':': case '\\':
            case '[': case ']': case ' ':
#ifdef RFC6531_FOLLOW_RFC20
            /* RFC20 */
            case '#': case '^': case '`': case '~':
            case '{': case '}': case '|':
#endif
                return inverse(EEAV_LPART_SPECIAL);
            }
        }
        else if (qpair) /* anything that is not control char. */
            qpair = 0;
        else {
            switch (ch) {
            case '"':   quote = 0; break;
            case '\\':  qpair = 1; break;
#ifdef RFC6531_FOLLOW_RFC5322
            /* the next chars are not allowed in qtext: */
            /* 1) they must be in quoted-pair(s). */
            /* 2) either they are permitted right after first DQUOTE
             *    or before the last DQUOTE only.
             */
            case '\n': case '\r': case '\t': case ' ': {
                switch (start[prev]) {
                    case '"':
                    case '\n': case '\r': case '\t': case ' ':
                        goto next;
                }

                if ((ch = utf8_decode_next (&u)) >= 0) {
                    if (ch > 0x007f)
                        break;

                    switch (ch) {
                        case '"':
                            quote = !quote;
                            break;
                        case '\n': case '\r': case '\t': case ' ':
                            break;
                        default:
                            return inverse(EEAV_LPART_UNQUOTED_FWS);
                    }
                }
            } break;
#endif
            } /* switch (ch) */
        } /* if (!quote) / else */
#ifdef RFC6531_FOLLOW_RFC5322
next:
#endif
        prev = utf8_decode_at_byte (&u);
    }

    /* invalid UTF-8 string */
    if (ch != UTF8_END)
        return inverse(EEAV_LPART_INVALID_UTF8);

    /* local-part with open quote is not allowed */
    if (quote)
        return inverse(EEAV_LPART_UNQUOTED);

    return EEAV_NO_ERROR;
}
