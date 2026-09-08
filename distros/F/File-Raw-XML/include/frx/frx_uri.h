#ifndef FRX_URI_H
#define FRX_URI_H

/* URI references: the parts, remove-dot-segments and the join of RFC 3986
 * section 5.2, in two forms that share one body.
 *
 * The plain form (c14n 0) is what resolves a system identifier against
 * the base of the entity that declared it (XML 1.0 section 4.2.2): a
 * relative reference joined to an absolute base, dot segments removed as
 * section 5.2.4 says, so a resolver sees one absolute identifier per
 * distinct target and the fetch cache keys on it.
 *
 * The Canonical XML 1.1 form (c14n 1) is what section 2.4 of that
 * Recommendation specifies for xml:base, which is the RFC's join with two
 * stated deviations: a base ending in ".." is treated as "../", and a
 * ".." that has nothing to remove in a relative path is kept rather than
 * dropped. Those two live behind the flag and nowhere else, so lifting
 * the code out of the canonicaliser moved no byte of its output; t/17's
 * xml:base cases are the guard.
 *
 * Needs frx_buf.h. */

/* the parts of a URI reference: scheme "x:", authority "//y", path, query */
typedef struct frx_uri {
    const char *scheme; size_t slen;     /* without the colon; NULL when absent */
    const char *auth;   size_t alen;     /* without the //; NULL when absent */
    const char *path;   size_t plen;
    const char *query;  size_t qlen;     /* without the ?; NULL when absent */
} frx_uri;

static void
frx_uri_parse(const char *p, size_t n, frx_uri *u)
{
    size_t i = 0;
    memset(u, 0, sizeof *u);
    /* scheme: ALPHA *( ALPHA / DIGIT / + / - / . ) ":" */
    if (n && ((p[0] >= 'A' && p[0] <= 'Z') || (p[0] >= 'a' && p[0] <= 'z'))) {
        size_t j = 1;
        while (j < n && ((p[j] >= 'A' && p[j] <= 'Z') || (p[j] >= 'a' && p[j] <= 'z')
                         || (p[j] >= '0' && p[j] <= '9') || p[j] == '+' || p[j] == '-' || p[j] == '.')) j++;
        if (j < n && p[j] == ':') { u->scheme = p; u->slen = j; i = j + 1; }
    }
    if (n - i >= 2 && p[i] == '/' && p[i + 1] == '/') {
        size_t j = i + 2;
        while (j < n && p[j] != '/' && p[j] != '?' && p[j] != '#') j++;
        u->auth = p + i + 2; u->alen = j - (i + 2); i = j;
    }
    {
        size_t j = i;
        while (j < n && p[j] != '?' && p[j] != '#') j++;
        u->path = p + i; u->plen = j - i; i = j;
    }
    if (i < n && p[i] == '?') {
        size_t j = i + 1;
        while (j < n && p[j] != '#') j++;
        u->query = p + i + 1; u->qlen = j - (i + 1);
    }
    /* the fragment is dropped: it never reaches a resolver, and Canonical
     * XML 1.1 section 2.4 drops it too */
}

/* remove-dot-segments (RFC 3986 section 5.2.4; as Canonical XML 1.1
 * section 2.4 modifies it when c14n is set) over a path already merged;
 * writes into out (which is reset) */
static int
frx_uri_remove_dots(frx_buf *out, const char *p, size_t n, int c14n)
{
    /* segments as (start, len) pairs in a growable array */
    struct seg { const char *s; size_t n; };
    struct seg *segs = NULL;
    int nseg = 0, cap = 0;
    int absolute = n > 0 && p[0] == '/';
    int trailing = 0;
    size_t i = absolute ? 1 : 0;
    int k;

    out->len = 0;
    while (i <= n) {
        size_t start = i;
        while (i < n && p[i] != '/') i++;
        {
            size_t len = i - start;
            int at_end = i >= n;
            /* a run of slashes is one slash; an empty middle segment is skipped */
            if (len == 0) {
                if (at_end && nseg) trailing = 1;
            } else if (len == 1 && p[start] == '.') {
                if (at_end) trailing = 1;
            } else if (len == 2 && p[start] == '.' && p[start + 1] == '.') {
                if (nseg && !(segs[nseg - 1].n == 2 && segs[nseg - 1].s[0] == '.' && segs[nseg - 1].s[1] == '.')) {
                    nseg--;
                    if (at_end) trailing = 1;
                } else if (absolute || !c14n) {
                    /* "/.." at the root, or a leading "../" in the RFC's
                     * form: nothing to pop, nothing kept */
                    if (at_end) trailing = absolute ? 1 : 0;
                } else {
                    if (nseg == cap) {
                        int ncap = cap ? cap * 2 : 8;
                        struct seg *ns = (struct seg *)realloc(segs, (size_t)ncap * sizeof *ns);
                        if (!ns) { free(segs); return 0; }
                        segs = ns; cap = ncap;
                    }
                    segs[nseg].s = p + start; segs[nseg].n = 2; nseg++;
                    if (at_end) trailing = 1;               /* a trailing ".." gets "/" */
                }
            } else {
                if (nseg == cap) {
                    int ncap = cap ? cap * 2 : 8;
                    struct seg *ns = (struct seg *)realloc(segs, (size_t)ncap * sizeof *ns);
                    if (!ns) { free(segs); return 0; }
                    segs = ns; cap = ncap;
                }
                segs[nseg].s = p + start; segs[nseg].n = len; nseg++;
                trailing = 0;
            }
        }
        i++;
    }
    if (absolute) frx_buf_append_ch(out, '/');
    for (k = 0; k < nseg; k++) {
        if (k) frx_buf_append_ch(out, '/');
        frx_buf_append_n(out, segs[k].s, segs[k].n);
    }
    if (trailing && nseg) frx_buf_append_ch(out, '/');
    free(segs);
    return !out->failed;
}

/* the join of section 5.2 into out; 0 on allocation failure */
static int
frx_uri_join(frx_buf *out, const char *base, size_t blen, const char *ref, size_t rlen, int c14n)
{
    frx_uri  b, r, t;
    frx_buf  merged, path;
    frx_buf  bfix;
    int      ok = 1;

    frx_buf_init(&merged);
    frx_buf_init(&path);
    frx_buf_init(&bfix);
    out->len = 0;

    /* Canonical XML 1.1's 5.2.1: a trailing ".." on the base becomes "../" */
    frx_buf_append_n(&bfix, base, blen);
    if (c14n && blen >= 2 && base[blen - 1] == '.' && base[blen - 2] == '.'
        && (blen == 2 || base[blen - 3] == '/'))
        frx_buf_append_ch(&bfix, '/');
    frx_uri_parse(bfix.p ? bfix.p : "", bfix.len, &b);
    frx_uri_parse(ref, rlen, &r);
    memset(&t, 0, sizeof t);

    /* 5.2.2 */
    if (r.scheme) {
        t = r;
        ok = frx_uri_remove_dots(&path, r.path, r.plen, c14n);
    } else {
        t.scheme = b.scheme; t.slen = b.slen;
        if (r.auth) {
            t.auth = r.auth; t.alen = r.alen;
            t.query = r.query; t.qlen = r.qlen;
            ok = frx_uri_remove_dots(&path, r.path, r.plen, c14n);
        } else {
            t.auth = b.auth; t.alen = b.alen;
            if (r.plen == 0) {
                frx_buf_append_n(&path, b.path, b.plen);
                if (r.query) { t.query = r.query; t.qlen = r.qlen; }
                else         { t.query = b.query; t.qlen = b.qlen; }
            } else {
                t.query = r.query; t.qlen = r.qlen;
                if (r.path[0] == '/') {
                    ok = frx_uri_remove_dots(&path, r.path, r.plen, c14n);
                } else {
                    /* 5.2.3 merge */
                    if (b.auth && b.plen == 0) {
                        frx_buf_append_ch(&merged, '/');
                    } else {
                        size_t k = b.plen;
                        while (k > 0 && b.path[k - 1] != '/') k--;
                        frx_buf_append_n(&merged, b.path, k);
                    }
                    frx_buf_append_n(&merged, r.path, r.plen);
                    ok = ok && !merged.failed
                         && frx_uri_remove_dots(&path, merged.p ? merged.p : "", merged.len, c14n);
                }
            }
        }
    }

    if (ok) {
        if (t.scheme) { frx_buf_append_n(out, t.scheme, t.slen); frx_buf_append_ch(out, ':'); }
        if (t.auth)   { frx_buf_append(out, "//"); frx_buf_append_n(out, t.auth, t.alen); }
        frx_buf_append_n(out, path.p ? path.p : "", path.len);
        if (t.query)  { frx_buf_append_ch(out, '?'); frx_buf_append_n(out, t.query, t.qlen); }
        ok = !out->failed;
    }
    frx_buf_free(&merged);
    frx_buf_free(&path);
    frx_buf_free(&bfix);
    return ok;
}

#endif /* FRX_URI_H */
