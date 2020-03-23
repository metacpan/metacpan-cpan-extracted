#ifndef MAIN_H
#define MAIN_H

#include <stdio.h>
#include <string.h>
#include <assert.h>
#include "utf8_decode.h"

#define msg_warn(...)   fprintf (stderr, __VA_ARGS__)
#define msg_ok(...)     fprintf (stdout, __VA_ARGS__)


const char *
sanitize (const char *str, size_t length)
{
    const char *end = str + length;
    size_t len = 0;
    static char result[1024];
    char buf[32];

    /* XXX no critic; for tests only */
    for (; str < end; str++) {
        if (*str < 0x20 || *str == 0x7f) {
            sprintf (buf, "0x%02x", *str);
            size_t x = strlen (buf);
            memcpy (result + len, buf, x);
            len += x;
        }
        else {
            memcpy (result + len, str, 1);
            len += 1;
        }
    }

    result[len] = '\0';
    return result;
}


const char *
sanitize_utf8 (const char *text, size_t length)
{
#define TEXT_SIZE 2048

    int c1 = 0, c2 = 0; /* characters */
    int p1 = 0, p2 = 0; /* byte position of characters */
    int pos = 0;        /* position in sanitized array */
    static char sanitized[TEXT_SIZE];
    char buf[32];


/* html data contain some unneccessary characters:
 * 1) such characters as '&lrm;' and '&rlm;' broke encoding to punycode;
 * 2) we don't want any '\r', '\n' characters in the output CSV file.
 */
#define SKIP(c, p, l) do { \
    if ((c) < 0x0020 || (c) == 0x007f) { \
        sprintf (buf, "0x%02x", c); \
        size_t x = strlen (buf); \
        memcpy (sanitized + pos, buf, x); \
        pos += x; \
    } \
    else { \
        assert (pos < TEXT_SIZE); \
        memcpy (sanitized + pos, text + p, l); \
        pos += l; \
    } \
} while (0)


    utf8_decode_init ((char *) text, length);
    /* look forward for characters and their lengths.
     * Such way (may be ugly) helps us avoid creation of utf8_encode() func.
     */
    for (;;) {
        c1 = utf8_decode_next ();
        p1 = utf8_decode_at_byte ();

        if (c1 < 0) {
            if (c2 > 0) { /* it is possible that we miss something */
                /* at p2, length: len - p2 */
                SKIP(c2, p2, length - p2);
            }
            break;
        }

        if (p2 > 0) { /* previous character */
            /* at p2, length: p1 - p2 */
            SKIP(c2, p2, p1 - p2);
        }

        /* look forward */
        c2 = utf8_decode_next ();
        p2 = utf8_decode_at_byte ();

        if (c2 > 0) {
            /* at p1, length: p2 - p1 */
            SKIP(c1, p1, p2 - p1);
        }
        else {
            /* it possible that we read everything; does not work always. */
            /* at p1, length: len - p2 */
            SKIP(c1, p1, length - p1);
        }
    }

    assert (c1 == UTF8_END);
    sanitized[pos] = '\0';

    return sanitized;
}

#endif /* MAIN_H */
