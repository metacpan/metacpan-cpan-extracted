#ifndef FRX_ERR_H
#define FRX_ERR_H

/* The refusal shape.
 *
 * The core never croaks (rule 4). Every refusal fills an frx_err - a code,
 * the byte offset it was found at, and a static string saying what - and
 * the two boundaries render it: the Perl surface croaks with the message,
 * the ABI returns NULL and puts the message in a mortal SV. One formatter,
 * so the two cannot drift.
 *
 * The message is
 *
 *   File::Raw::XML: <what> at byte offset <N> near "<ctx>"
 *
 * or, when the offset is at or past the end, `... at end of input`. ctx is
 * up to sixteen bytes from the offset with anything outside printable
 * ASCII - and the quote and backslash - rendered \xNN, so a NUL in the
 * input cannot truncate the message and a binary byte never reaches a
 * %s. No snprintf: the number is rendered by hand, because the core is
 * perl-free and the family's memory about my_snprintf and a shadowed
 * `len` says to keep formatting out of the hot path anyway.
 *
 * Needs frx_abi.h, for frx_code and frx_err. */

/* frx_code and frx_err are frx_abi.h's: every core function that
 * refuses fills one, and the v2 table hands them to a consumer
 * directly rather than through a wrapper per entry. */

#define FRX_ERR_CONTEXT 16
#define FRX_ERR_PREFIX  "File::Raw::XML: "

static void
frx_err_set(frx_err *e, frx_code code, size_t offset, const char *what)
{
    e->code   = code;
    e->offset = offset;
    e->what   = what;
    e->enc    = NULL;
}

/* Append n bytes of s to out at *pos, bounded by cap - 1; *pos advances by
 * n regardless, so the caller learns the length that would have been
 * written, as snprintf reports it. */
static void
frx_err_put(char *out, size_t cap, size_t *pos, const char *s, size_t n)
{
    size_t i;
    for (i = 0; i < n; i++) {
        if (*pos + 1 < cap) out[*pos] = s[i];
        (*pos)++;
    }
}

static void
frx_err_put_num(char *out, size_t cap, size_t *pos, size_t v)
{
    char tmp[32];
    size_t n = 0;
    do {
        tmp[n++] = (char)('0' + (v % 10));
        v /= 10;
    } while (v && n < sizeof tmp);
    while (n) {
        n--;
        frx_err_put(out, cap, pos, &tmp[n], 1);
    }
}

/* The message over a window of the input: in holds the bytes from stream
 * offset in_base, which is 0 for a whole document and, for a streaming
 * reader that has dropped what it consumed, the offset of the first byte
 * it still holds. An offset outside the window is reported without
 * context; one at or past the end of a whole document is the end. */
static size_t
frx_err_format_at(const frx_err *e, const char *in, size_t len, size_t in_base,
                  char *out, size_t cap)
{
    static const char hex[] = "0123456789abcdef";
    size_t pos = 0;
    const char *what = e->what ? e->what : "parse error";

    frx_err_put(out, cap, &pos, FRX_ERR_PREFIX, sizeof FRX_ERR_PREFIX - 1);
    frx_err_put(out, cap, &pos, what, strlen(what));

    if (in_base && (!in || e->offset < in_base || e->offset - in_base >= len)) {
        frx_err_put(out, cap, &pos, " at byte offset ", 16);
        frx_err_put_num(out, cap, &pos, e->offset);
    } else if (!in || e->offset >= len) {
        frx_err_put(out, cap, &pos, " at end of input", 16);
    } else {
        size_t rel = e->offset - in_base;
        size_t i, n = len - rel;
        if (n > FRX_ERR_CONTEXT) n = FRX_ERR_CONTEXT;
        frx_err_put(out, cap, &pos, " at byte offset ", 16);
        frx_err_put_num(out, cap, &pos, e->offset);
        if (e->enc) {
            /* the offset is in the caller's bytes, which were transcoded */
            frx_err_put(out, cap, &pos, " of the ", 8);
            frx_err_put(out, cap, &pos, e->enc, strlen(e->enc));
            frx_err_put(out, cap, &pos, " input", 6);
        }
        frx_err_put(out, cap, &pos, " near \"", 7);
        for (i = 0; i < n; i++) {
            unsigned char c = (unsigned char)in[rel + i];
            if (c >= 0x20 && c < 0x7f && c != '"' && c != '\\') {
                frx_err_put(out, cap, &pos, (const char *)&c, 1);
            } else {
                char esc[4];
                esc[0] = '\\'; esc[1] = 'x';
                esc[2] = hex[c >> 4]; esc[3] = hex[c & 15];
                frx_err_put(out, cap, &pos, esc, 4);
            }
        }
        frx_err_put(out, cap, &pos, "\"", 1);
    }

    if (cap) out[pos < cap ? pos : cap - 1] = '\0';
    return pos < cap ? pos : cap - 1;
}

static size_t
frx_err_format(const frx_err *e, const char *in, size_t len, char *out, size_t cap)
{
    return frx_err_format_at(e, in, len, 0, out, cap);
}

#endif /* FRX_ERR_H */
