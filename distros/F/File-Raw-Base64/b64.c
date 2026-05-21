/*
 * b64.c - Base64 encode/decode for File::Raw::Base64.
 *
 * Standard alphabet from RFC 4648,
 * URL-safe variant via opts.urlsafe. PEM envelope handling on top.
 *
 * Strict C89 compliant: every declaration at the top of its block
 * scope, no inline for-loop initialisers, no // comments. The dist
 * targets perl 5.8.3+ where the platform compiler may default to
 * C89 (e.g. GCC 4.2.1 on FreeBSD 9.x).
 */

#include "b64.h"

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

/* ------------------------------------------------------------
 * Alphabet tables
 * ------------------------------------------------------------ */

static const char ALPHA_STD[64] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

static const char ALPHA_URL[64] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

/* Reverse-lookup tables. -1 = not in alphabet. -2 = padding ('='). */
#define INVAL ((signed char)-1)
#define PAD   ((signed char)-2)

static signed char REV_STD[256];
static signed char REV_URL[256];
static int rev_initialised = 0;

static void
rev_init(void)
{
    int i;
    for (i = 0; i < 256; i++) { REV_STD[i] = INVAL; REV_URL[i] = INVAL; }
    for (i = 0; i < 64;  i++) {
        REV_STD[(unsigned char)ALPHA_STD[i]] = (signed char)i;
        REV_URL[(unsigned char)ALPHA_URL[i]] = (signed char)i;
    }
    REV_STD[(unsigned char)'='] = PAD;
    REV_URL[(unsigned char)'='] = PAD;
    rev_initialised = 1;
}

/* ------------------------------------------------------------
 * Output buffer growth
 * ------------------------------------------------------------ */

static int
out_reserve(void **out, size_t *out_cap, size_t need)
{
    size_t new_cap;
    void *new_buf;

    if (need <= *out_cap) return 0;

    new_cap = *out_cap ? *out_cap : 64;
    while (new_cap < need) {
        if (new_cap > (SIZE_MAX / 2)) { new_cap = need; break; }
        new_cap *= 2;
    }
    new_buf = realloc(*out, new_cap);
    if (!new_buf) return -1;
    *out = new_buf;
    *out_cap = new_cap;
    return 0;
}

/* ------------------------------------------------------------
 * Defaults
 * ------------------------------------------------------------ */

void
b64_options_init(b64_options_t *opts)
{
    memset(opts, 0, sizeof *opts);
    opts->padding   = 1;
    opts->pem_label = "DATA";
    opts->eol       = "\n";
    /* urlsafe, wrap, pem, strict default to 0 via memset */
}

/* ------------------------------------------------------------
 * Encode
 * ------------------------------------------------------------ */

static int
emit_eol(char **out, size_t *cap, size_t *len, const char *eol)
{
    size_t elen = strlen(eol);
    if (out_reserve((void **)out, cap, *len + elen) < 0) return B64_ERR_NOMEM;
    memcpy(*out + *len, eol, elen);
    *len += elen;
    return 0;
}

static int
emit_pem_header(char **out, size_t *cap, size_t *len,
                const char *kind, const char *label, const char *eol)
{
    /* "-----BEGIN $label-----$eol" */
    size_t llen = strlen(label);
    size_t elen = strlen(eol);
    size_t klen = strlen(kind);
    size_t need = *len + 5 + 1 + klen + 1 + llen + 5 + elen;
    char *p;

    if (out_reserve((void **)out, cap, need) < 0) return B64_ERR_NOMEM;
    p = *out + *len;
    memcpy(p, "-----", 5);   p += 5;
    memcpy(p, kind, klen);   p += klen;
    *p++ = ' ';
    memcpy(p, label, llen);  p += llen;
    memcpy(p, "-----", 5);   p += 5;
    memcpy(p, eol, elen);    p += elen;
    *len = (size_t)(p - *out);
    return 0;
}

int
b64_encode(const unsigned char *in, size_t in_len,
           const b64_options_t *opts,
           char **out, size_t *out_cap, size_t *out_len,
           size_t *err_offset)
{
    const char *alpha;
    const char *eol;
    int rc;
    size_t encoded_chars;
    size_t wrap_eols = 0;
    int wrap;
    size_t i;
    size_t tail;
    int wrap_col = 0;
    char *o;

    if (!rev_initialised) rev_init();
    if (err_offset) *err_offset = 0;

    alpha = opts->urlsafe ? ALPHA_URL : ALPHA_STD;
    eol   = opts->eol ? opts->eol : "\n";
    wrap  = opts->wrap;

    /* PEM begin. */
    if (opts->pem) {
        rc = emit_pem_header(out, out_cap, out_len,
                             "BEGIN", opts->pem_label, eol);
        if (rc) return rc;
    }

    /* Worst-case sizing: 4 chars per 3 input bytes, plus wrap eols. */
    encoded_chars = ((in_len + 2) / 3) * 4;
    if (wrap > 0 && encoded_chars > 0) {
        size_t elen = strlen(eol);
        wrap_eols = ((encoded_chars + (size_t)wrap - 1) / (size_t)wrap) * elen;
    }
    if (out_reserve((void **)out, out_cap,
                    *out_len + encoded_chars + wrap_eols) < 0)
        return B64_ERR_NOMEM;

    o = *out + *out_len;

#define EMIT(c) do { \
    *o++ = (c); \
    if (wrap > 0 && ++wrap_col == wrap) { \
        size_t cur = (size_t)(o - (*out)); \
        *out_len = cur; \
        rc = emit_eol(out, out_cap, out_len, eol); \
        if (rc) return rc; \
        o = *out + *out_len; \
        wrap_col = 0; \
    } \
} while (0)

    /* Main loop: 3 bytes -> 4 chars. */
    for (i = 0; i + 3 <= in_len; i += 3) {
        uint32_t triplet = ((uint32_t)in[i]   << 16)
                         | ((uint32_t)in[i+1] <<  8)
                         |  (uint32_t)in[i+2];
        EMIT(alpha[(triplet >> 18) & 0x3F]);
        EMIT(alpha[(triplet >> 12) & 0x3F]);
        EMIT(alpha[(triplet >>  6) & 0x3F]);
        EMIT(alpha[ triplet        & 0x3F]);
    }

    /* Tail: 1 or 2 leftover bytes. */
    tail = in_len - i;
    if (tail == 1) {
        uint32_t b = (uint32_t)in[i] << 16;
        EMIT(alpha[(b >> 18) & 0x3F]);
        EMIT(alpha[(b >> 12) & 0x3F]);
        if (opts->padding) { EMIT('='); EMIT('='); }
    } else if (tail == 2) {
        uint32_t b = ((uint32_t)in[i] << 16) | ((uint32_t)in[i+1] << 8);
        EMIT(alpha[(b >> 18) & 0x3F]);
        EMIT(alpha[(b >> 12) & 0x3F]);
        EMIT(alpha[(b >>  6) & 0x3F]);
        if (opts->padding) EMIT('=');
    }

#undef EMIT

    /* Final EOL after the body if we wrapped (so the trailing line
     * terminates) and no eol is already pending - wrap loop only emits
     * an eol when it just hit `wrap_col == wrap`, so a partial last
     * line still needs one. PEM mode also wants an EOL before END. */
    *out_len = (size_t)(o - *out);
    if ((wrap > 0 && wrap_col != 0) || opts->pem) {
        rc = emit_eol(out, out_cap, out_len, eol);
        if (rc) return rc;
    }

    if (opts->pem) {
        rc = emit_pem_header(out, out_cap, out_len,
                             "END", opts->pem_label, eol);
        if (rc) return rc;
    }

    return B64_OK;
}

/* ------------------------------------------------------------
 * Decode
 *
 * On PEM input, find the BEGIN/END markers and slice out the body
 * before running the regular decode loop on it.
 * ------------------------------------------------------------ */

/* Find a substring in [haystack, haystack+haystack_len). NULL if not
 * found. Standard memmem isn't portable, so roll our own. */
static const char *
mem_find(const char *haystack, size_t haystack_len,
         const char *needle, size_t needle_len)
{
    const char *limit;
    const char *p;

    if (needle_len == 0 || haystack_len < needle_len) return NULL;
    limit = haystack + (haystack_len - needle_len);
    for (p = haystack; p <= limit; p++) {
        if (memcmp(p, needle, needle_len) == 0) return p;
    }
    return NULL;
}

/* Locate PEM body. Returns 0 on success and writes [body_start,body_end)
 * into the out params. Returns negative b64_err_t on failure. */
static int
find_pem_body(const char *in, size_t in_len,
              const char **body_start, size_t *body_len,
              size_t *err_offset)
{
    static const char BEGIN_MARK[] = "-----BEGIN ";
    static const char END_MARK[]   = "-----END ";
    static const char DASH5[]      = "-----";

    const char *begin;
    const char *begin_label;
    const char *begin_close;
    const char *body;
    const char *end;
    const char *end_label;
    const char *end_close;
    size_t blab_len;
    size_t elab_len;

    begin = mem_find(in, in_len, BEGIN_MARK, sizeof BEGIN_MARK - 1);
    if (!begin) {
        if (err_offset) *err_offset = 0;
        return B64_ERR_PEM_NO_BEGIN;
    }
    begin_label = begin + sizeof BEGIN_MARK - 1;
    begin_close = mem_find(begin_label,
                           in_len - (size_t)(begin_label - in),
                           DASH5, 5);
    if (!begin_close) {
        if (err_offset) *err_offset = (size_t)(begin - in);
        return B64_ERR_PEM_NO_BEGIN;
    }

    /* Body starts right after BEGIN line's trailing dashes. Scan past
     * any immediate \r/\n. */
    body = begin_close + 5;
    while (body < in + in_len && (*body == '\r' || *body == '\n')) body++;

    end = mem_find(body, in_len - (size_t)(body - in),
                   END_MARK, sizeof END_MARK - 1);
    if (!end) {
        if (err_offset) *err_offset = (size_t)(begin - in);
        return B64_ERR_PEM_NO_END;
    }
    end_label = end + sizeof END_MARK - 1;
    end_close = mem_find(end_label,
                         in_len - (size_t)(end_label - in),
                         DASH5, 5);
    if (!end_close) {
        if (err_offset) *err_offset = (size_t)(end - in);
        return B64_ERR_PEM_NO_END;
    }

    /* Verify BEGIN and END labels match. */
    blab_len = (size_t)(begin_close - begin_label);
    elab_len = (size_t)(end_close - end_label);
    if (blab_len != elab_len
        || memcmp(begin_label, end_label, blab_len) != 0)
    {
        if (err_offset) *err_offset = (size_t)(end - in);
        return B64_ERR_PEM_LABEL;
    }

    *body_start = body;
    *body_len   = (size_t)(end - body);
    return 0;
}

int
b64_decode(const char *in, size_t in_len,
           const b64_options_t *opts,
           unsigned char **out, size_t *out_cap, size_t *out_len,
           size_t *err_offset)
{
    const signed char *rev;
    const char *body;
    size_t body_len;
    unsigned char *o;
    uint32_t buf = 0;
    int bits = 0;
    int saw_pad = 0;
    size_t i;

    if (!rev_initialised) rev_init();
    if (err_offset) *err_offset = 0;

    rev = opts->urlsafe ? REV_URL : REV_STD;

    /* PEM: peel envelope. */
    body = in;
    body_len = in_len;
    if (opts->pem) {
        int rc = find_pem_body(in, in_len, &body, &body_len, err_offset);
        if (rc) return rc;
    }

    /* Worst-case decode size: 3 bytes per 4 input chars. */
    if (out_reserve((void **)out, out_cap,
                    *out_len + (body_len / 4 + 1) * 3) < 0)
        return B64_ERR_NOMEM;

    o = *out + *out_len;

    for (i = 0; i < body_len; i++) {
        unsigned char c = (unsigned char)body[i];
        signed char v = rev[c];

        if (v == PAD) {
            saw_pad++;
            continue;
        }
        if (v == INVAL) {
            if (opts->strict) {
                if (err_offset) *err_offset =
                    (size_t)(body - in) + i;
                return B64_ERR_BAD_BYTE;
            }
            /* Lenient: skip silently. */
            continue;
        }
        if (saw_pad && opts->strict) {
            if (err_offset) *err_offset = (size_t)(body - in) + i;
            return B64_ERR_BAD_BYTE;  /* alphabet byte after padding */
        }

        buf = (buf << 6) | (uint32_t)v;
        bits += 6;
        if (bits >= 8) {
            bits -= 8;
            *o++ = (unsigned char)((buf >> bits) & 0xFF);
        }
    }

    /* Final bits: if exactly 8 bits remain we accept (one trailing
     * byte). 0 bits is fine. Anything else is truncation. */
    if (bits != 0 && bits != 2 && bits != 4) {
        /* 6 bits left over means an incomplete quartet (e.g. one
         * stray base64 char with no partner). 2/4 bits are normal
         * tails for length%3 == 1 / length%3 == 2. */
        return B64_ERR_TRUNCATED;
    }

    *out_len = (size_t)(o - *out);
    return B64_OK;
}

/* ------------------------------------------------------------
 * strerror
 * ------------------------------------------------------------ */

const char *
b64_strerror(int err)
{
    switch ((b64_err_t)err) {
    case B64_OK:               return "ok";
    case B64_ERR_NOMEM:        return "out of memory";
    case B64_ERR_BAD_BYTE:     return "non-alphabet byte in strict mode";
    case B64_ERR_TRUNCATED:    return "truncated base64 input";
    case B64_ERR_PEM_NO_BEGIN: return "PEM input missing BEGIN marker";
    case B64_ERR_PEM_NO_END:   return "PEM input missing END marker";
    case B64_ERR_PEM_LABEL:    return "PEM BEGIN and END labels disagree";
    }
    return "unknown error";
}
