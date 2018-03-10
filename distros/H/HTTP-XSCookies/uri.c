#include <ctype.h>
#include <string.h>
#include "uri.h"

/*
 * This file is generated automatically with program "encode".
 */
#include "uri_tables.h"

/*
 * We need to mask the index to character arrays in case of platforms with more
 * than 8-bit chars since our table only has sufficient characters for that
 * many conversions.  Results could potentially be wrong in that case, but at
 * least we won't crash.
 */
#define CAST_INDEX(x) (((unsigned char) (x)) & 0xff)

Buffer* url_decode(Buffer* src, Buffer* tgt)
{
    unsigned int s = src->rpos;
    unsigned int t = tgt->wpos;

    /* check and maybe increase space in target */
    buffer_ensure_unused(tgt, buffer_used(src));

    while (s < src->wpos) {
        if (src->data[s] == '%' &&
            isxdigit(src->data[s+1]) &&
            isxdigit(src->data[s+2])) {
            /* put a byte together from the next two hex digits */
            tgt->data[t++] = MAKE_BYTE(uri_decode_tbl[CAST_INDEX(src->data[s+1])],
                                       uri_decode_tbl[CAST_INDEX(src->data[s+2])]);
            /* we used up 3 characters (%XY) from source */
            s += 3;
        } else {
            tgt->data[t++] = src->data[s++];
        }
    }

    /* null-terminate target and return src as was left */
    src->rpos = s;
    tgt->wpos = t;
    return src;
}

Buffer* url_encode(Buffer* src, Buffer* tgt)
{
    unsigned int s = src->rpos;
    unsigned int t = tgt->wpos;

    /* check and maybe increase space in target */
    buffer_ensure_unused(tgt, 3 * buffer_used(src));

    while (s < src->wpos) {
        char* v = uri_encode_tbl[CAST_INDEX(src->data[s])];

        /* if current source character doesn't need to be encoded,
           just copy it to target*/
        if (!v) {
            tgt->data[t++] = src->data[s++];
            continue;
        }

        /* copy encoded character from our table */
        memcpy(tgt->data + t, v, 3);

        /* we used up 3 characters (%XY) in target
         * and 1 character from source */
        t += 3;
        ++s;
    }

    /* null-terminate target and return src as was left */
    src->rpos = s;
    tgt->wpos = t;
    return src;
}
