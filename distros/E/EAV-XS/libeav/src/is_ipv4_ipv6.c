/* This part was taken from postfix 3.2.0.
 *
 * License:
 * The Secure Mailer license must be distributed with this software.
 *
 * Author:
 * Wietse Venema
 * IBM T.J. Watson Research
 * P.O. Box 704
 * Yorktown Heights, NY 10598, USA
 */
#include <stdio.h>
#include <eav.h>
#include <string.h>
#include <eav/private.h>


extern int
is_ipv4 (const char *start, const char *end)
{
    const char *cp;
    int ch;
    int in_byte = 0;
    int byte_val = 0;
    int byte_count = 0;
#define BYTES_NEEDED 4


    for (cp = start; cp < end && (ch = *(unsigned const char *) cp) != 0; cp++) {
        if (ISDIGIT(ch)) {
            if (in_byte == 0) {
                in_byte = 1;
                byte_val = 0;
                byte_count++;
            }
            byte_val *= 10;
            byte_val += ch - '0';
            if (byte_val > 255) {
                /* invalid octet */
                return (NO);
            }
        }
        else if (ch == '.') {
            if (in_byte == 0 || cp[1] == 0) {
                /* misplaced dot */
                return (NO);
            }
            /* XXX Allow 0.0.0.0 but not 0.1.2.3 */
            if (byte_count == 1 && byte_val == 0 && start[strspn(start, "0.")]) {
                return (NO);
            }
            /* try next byte */
            in_byte = 0;
        }
        else {
            /* invalid character */
            return (NO);
        }
    }

    if (byte_count != BYTES_NEEDED) {
        /* invalid octet count */
        return (NO);
    }

    return (YES);
}


extern int
is_ipv6 (const char *start, const char *end)
{
    int     null_field = 0;
    int     field = 0;
    unsigned char *cp = (unsigned char *) start;
    int     len = 0;


    for ( ; cp < (unsigned char *) end; ) {
        switch (*cp) {
        case 0:
            /* Terminate the loop. */
            if (field < 2) {
                /* too few `:' in IPv6 address*/
                return (NO);
            }
            else if (len == 0 && null_field != field - 1) {
                /* bad null last field in IPv6 address */
                return (NO);
            }
            else
                return (YES);
        case '.':
            /* Terminate the loop. */
            if (field < 2 || field > 6) {
                /* malformed IPv4-in-IPv6 address */
                return (NO);
            }
            else
        		/* NOT: Avoid recursion. */
                return (is_ipv4 ((char *) cp - len, end));
        case ':': {
            /* Advance by exactly 1 character position or terminate. */
            if (field == 0 && len == 0 && ISALNUM(cp[1])) {
                /* bad null first field in IPv6 address */
                return (NO);
            }
            field++;
            if (field > 7) {
                /* too many `:' in IPv6 address */
                return (NO);
            }
            cp++;
            len = 0;
            if (*cp == ':') {
                if (null_field > 0) {
                    /* too many `::' in IPv6 address */
                    return (NO);
                }
                null_field = field;
            }
        } break;
        default: {
            /* Advance by at least 1 character position or terminate. */
            len = strspn ((char *) cp, "0123456789abcdefABCDEF");
            if (len /* - strspn((char *) cp, "0") */ > 4) {
                /* malformed IPv6 address */
                return (NO);
            }
            if (len <= 0) {
                /* invalid character in IPv6 address */
                return (NO);
            }
            cp += len;
        } break;
        } /* switch */
    } /* for (;;) */

    return (YES);
}


extern int
is_ipaddr (const char *start, const char *end)
{
#ifdef _DEBUG
    printf ("!!! %.*s\n", end - start, start);
#endif

    if (strchr(start, ':') != NULL)
        return is_ipv6 (start, end);
    else
        return is_ipv4 (start, end);
}
