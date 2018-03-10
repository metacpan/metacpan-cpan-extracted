#include <ctype.h>
#include <memory.h>
#include <stdio.h>
#include "buffer.h"
#include "uri.h"
#include "date.h"
#include "cookie.h"

/*
 * This file is generated automatically with program "encode".
 * We include it because we will do our own URL decoding.
 */
#include "uri_tables.h"

static Buffer* cookie_put_value(Buffer* cookie,
                                const char* name, int nlen,
                                const char* value, int vlen,
                                int boolean, int enc_nam, int enc_val)
{
    Buffer dnam;
    Buffer dval;
    buffer_wrap(&dnam, name , nlen);
    buffer_wrap(&dval, value, vlen);

    /* output each part into the cookie */
    do {
        if (cookie->wpos > 0) {
            buffer_append_str(cookie, "; ", 2);
        }

        if (!enc_nam) {
            buffer_append_buf(cookie, &dnam);
        } else {
            url_encode(&dnam, cookie);
        }

        if (boolean) {
            break;
        }

        buffer_append_str(cookie, "=", 1);

        if (!enc_val) {
            buffer_append_buf(cookie, &dval);
        } else {
            url_encode(&dval, cookie);
        }
    } while (0);

    return cookie;
}

Buffer* cookie_put_string(Buffer* cookie,
                          const char* name, int nlen,
                          const char* value, int vlen,
                          int enc_nam, int enc_val)
{
    return cookie_put_value(cookie, name, nlen, value, vlen, 0, enc_nam, enc_val);
}

Buffer* cookie_put_date(Buffer* cookie,
                        const char* name, int nlen,
                        const char* value, int vlen)
{
    Buffer format;

    double date = date_compute(value, vlen);
    if (date < 0) {
        return cookie_put_value(cookie, name, nlen, value, vlen, 0, 0, 0);
    }

    buffer_init(&format, 0);
    date_format(date, &format);
    cookie_put_value(cookie, name, nlen, format.data, format.wpos, 0, 0, 0);
    buffer_fini(&format);

    return cookie;
}

Buffer* cookie_put_integer(Buffer* cookie,
                           const char* name, int nlen,
                           long value)
{
    char buf[50]; /* FIXED BUFFER OK: to format a long */
    int blen = 0;

    sprintf(buf, "%ld", value);
    blen = strlen(buf);
    return cookie_put_value(cookie, name, nlen, buf, blen, 0, 0, 0);
}

Buffer* cookie_put_boolean(Buffer* cookie,
                           const char* name, int nlen,
                           int value)
{
    char buf[50]; /* FIXED BUFFER OK: to format a boolean */
    int blen = 0;

    if (!value) {
        return cookie;
    }

    strcpy(buf, "1");
    blen = strlen(buf);
    return cookie_put_value(cookie, name, nlen, buf, blen, 1, 0, 0);
}

/*
 * Given a buffer that holds a cookie (and therefore has an idea
 * of the current position within the cookie), parse the next
 * name / value pair out of it.
 *
 * A cookie will have the form:
 *
 *   name1 = value1; name2=value2;name3 =value3;...
 *
 * As the example shows, there may be annoying whitespace embedded
 * within the name=value components.  What we do here is to run a
 * state machine that keeps track of the following states:
 *
 *   URI_STATE_START  Start parsing
 *   URI_STATE_NAME   Parsing name component
 *   URI_STATE_EQUALS Just saw the '=' between name and value
 *   URI_STATE_VALUE  Parsing the value component
 *   URI_STATE_END    End parsing
 *   URI_STATE_ERROR  Error while parsing
 *
 * In order to achieve the maximum performance, this state machine
 * is represented in a precomputed table called uri_state_tbl[c][s],
 * whose values depend on the current character and current state.
 * This table (as well as the other tables that ease the process
 * of URL encoding and decoding) was generated with a C program,
 * which can be found in tools/encode/encode.
 */
int cookie_get_pair(Buffer* cookie,
                    Buffer* name, Buffer* value)
{
    int norig = name->wpos;
    int vorig = value->wpos;
    int vend = 0;
    int state = 0;
    int current = 0;
    int equals = 0;

    /* State machine starts in URI_STATE_START state and
     * will loop until we enter any state that is
     * >= URI_STATE_TERMINATE */
    for (state = URI_STATE_START; state < URI_STATE_TERMINATE; ) {
        /* Switch to next state based on last character read
         * and current state. */
        current = cookie->data[cookie->rpos];
        state = uri_state_tbl[current][state];

        switch (state) {
            /* If we are reading the name part, add the current
             * character (possibly URL-decoded) */
            case URI_STATE_NAME:
                buffer_ensure_unused(name, 1);
                if (current == '%' &&
                    isxdigit(cookie->data[cookie->rpos+1]) &&
                    isxdigit(cookie->data[cookie->rpos+2])) {
                    /* put a byte together from the next two hex digits */
                    name->data[name->wpos++] = MAKE_BYTE(uri_decode_tbl[(int)cookie->data[cookie->rpos+1]],
                                                         uri_decode_tbl[(int)cookie->data[cookie->rpos+2]]);
                    cookie->rpos += 3;
                } else {
                    /* just copy current character */
                    name->data[name->wpos++] = current;
                    ++cookie->rpos;
                }
                break;

            case URI_STATE_EQUALS:
                equals = 1;
                ++cookie->rpos;
                break;

            /* If we are reading the value part, add the current
             * character (possibly URL-decoded) */
            case URI_STATE_VALUE:
                buffer_ensure_unused(value, 1);
                if (current == '%' &&
                    isxdigit(cookie->data[cookie->rpos+1]) &&
                    isxdigit(cookie->data[cookie->rpos+2])) {
                    /* put a byte together from the next two hex digits */
                    value->data[value->wpos++] = MAKE_BYTE(uri_decode_tbl[(int)cookie->data[cookie->rpos+1]],
                                                           uri_decode_tbl[(int)cookie->data[cookie->rpos+2]]);
                    cookie->rpos += 3;
                    vend = value->wpos;
                } else {
                    /* just copy current character */
                    value->data[value->wpos++] = current;
                    ++cookie->rpos;
                    if (!isspace(current)) {
                        vend = value->wpos;
                    }
                }
                break;

            /* Any other state, just move to the next position. */
            default:
                ++cookie->rpos;
                break;
        }
    }

    /* If last character seen was EOS, we have already incremented
     * the buffer position once too many; correct that. */
    if (current == '\0') {
        --cookie->rpos;
    }
    /* If we didn't end in URI_STATE_END, reset buffers. */
    if (state != URI_STATE_END) {
        name->wpos = norig;
        value->wpos = vorig;
    } else {
        /* Maybe correct end position for value. */
        if (vend) {
            value->wpos = vend;
        }
    }

    return equals;
}
