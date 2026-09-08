#ifndef FRX_BUF_H
#define FRX_BUF_H

/* Output bytes.
 *
 * A growable byte buffer for canonicalisation and text output: the core
 * writes into it and the SV layer wraps the finished bytes once. Doubling
 * realloc, always NUL-terminated at len, and a failure flag the caller
 * checks once at the end rather than on every append - after a failed
 * grow every later append is a no-op, so the flag is the whole story.
 *
 * malloc, realloc and free by rule 3. Needs nothing. */

typedef struct frx_buf {
    char  *p;
    size_t len;
    size_t cap;
    int    failed;
} frx_buf;

static void
frx_buf_init(frx_buf *b)
{
    b->p      = NULL;
    b->len    = 0;
    b->cap    = 0;
    b->failed = 0;
}

/* room for extra more bytes plus the NUL; 0 on failure, and failed is set */
static int
frx_buf_reserve(frx_buf *b, size_t extra)
{
    size_t need;
    if (b->failed) return 0;
    need = b->len + extra + 1;
    if (need < extra) { b->failed = 1; return 0; }     /* wrapped */
    if (need > b->cap) {
        size_t ncap = b->cap ? b->cap : 256;
        char *np;
        while (ncap < need) {
            size_t grown = ncap * 2;
            if (grown < ncap) { b->failed = 1; return 0; }
            ncap = grown;
        }
        np = (char *)realloc(b->p, ncap);
        if (!np) { b->failed = 1; return 0; }
        b->p   = np;
        b->cap = ncap;
    }
    return 1;
}

static void
frx_buf_append_n(frx_buf *b, const char *s, size_t n)
{
    if (!frx_buf_reserve(b, n)) return;
    if (n) memcpy(b->p + b->len, s, n);
    b->len += n;
    b->p[b->len] = '\0';
}

static void
frx_buf_append(frx_buf *b, const char *s)
{
    frx_buf_append_n(b, s, strlen(s));
}

static void
frx_buf_append_ch(frx_buf *b, char c)
{
    frx_buf_append_n(b, &c, 1);
}

static void
frx_buf_free(frx_buf *b)
{
    free(b->p);
    frx_buf_init(b);
}

#endif /* FRX_BUF_H */
