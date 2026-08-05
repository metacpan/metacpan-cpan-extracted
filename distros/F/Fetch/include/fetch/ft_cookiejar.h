#ifndef FT_COOKIEJAR_H
#define FT_COOKIEJAR_H

/* Fetch::CookieJar - a cookie store, roughly RFC 6265. Parses Set-Cookie
 * response headers and produces the matching Cookie header for a request,
 * honouring domain (host-only + subdomain), path, expiry (Expires/Max-Age)
 * and the Secure flag. A cookie is identified by the triple (domain, path,
 * name); setting the same triple replaces it. The jar is a C struct behind a
 * blessed IV; xs/cookiejar.xs is a thin layer over these helpers. */

#include <string.h>
#include <strings.h>   /* strncasecmp */
#include <stdlib.h>
#include <ctype.h>
#include <time.h>

typedef struct {
    char  *name, *value, *domain, *path;
    int    secure, httponly, host_only;
    int    has_expires;
    time_t expires;
} ft_cookie;

typedef struct {
    ft_cookie *v;
    size_t     n, cap;
} ft_jar;

static ft_jar *ft_jar_new(void) {
    ft_jar *j = (ft_jar *)calloc(1, sizeof(ft_jar));
    return j;
}

static void ft_cookie_wipe(ft_cookie *c) {
    free(c->name); free(c->value); free(c->domain); free(c->path);
}

static void ft_jar_free(ft_jar *j) {
    size_t i;
    if (!j) return;
    for (i = 0; i < j->n; i++) ft_cookie_wipe(&j->v[i]);
    free(j->v);
    free(j);
}

/* unwrap the blessed IV a Fetch::CookieJar carries */
static ft_jar *ft_jar_of(pTHX_ SV *sv) {
    if (!(SvROK(sv) && SvIOK(SvRV(sv))))
        croak("Fetch::CookieJar: not a jar");
    return INT2PTR(ft_jar *, SvIV(SvRV(sv)));
}

static char *ft_strdup_n(const char *s, size_t n) {
    char *r = (char *)malloc(n + 1);
    if (r) { memcpy(r, s, n); r[n] = '\0'; }
    return r;
}
static char *ft_strdup0(const char *s) { return ft_strdup_n(s, strlen(s)); }

/* case-insensitive C-string equality */
static int ft_ci_streq(const char *a, const char *b) {
    while (*a && *b) {
        if (tolower((unsigned char)*a) != tolower((unsigned char)*b)) return 0;
        a++; b++;
    }
    return *a == *b;
}

/* --- date parsing (Expires) --------------------------------------------- */

/* days-since-epoch -> time_t for a UTC calendar date (mon 0-11, year full) */
static time_t ft_timegm(int sec, int min, int hour, int mday, int mon, int year) {
    static const int cum[12] = { 0,31,59,90,120,151,181,212,243,273,304,334 };
    long y = year, days, leaps = 0, yy;
    int is_leap;
    for (yy = 1970; yy < y; yy++)
        if ((yy % 4 == 0 && yy % 100 != 0) || yy % 400 == 0) leaps++;
    is_leap = (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;
    days = 365L * (y - 1970) + leaps + cum[mon] + (mday - 1);
    if (mon >= 2 && is_leap) days += 1;
    return (time_t)(days * 86400L + hour * 3600L + min * 60L + sec);
}

static const char *const ft_mon[12] = {
    "jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec"
};

/* Parse "DD Mon YYYY HH:MM:SS" / "DD-Mon-YY HH:MM:SS" anywhere in $s. Returns
 * 1 and *out on success, 0 otherwise. */
static int ft_parse_date(const char *s, time_t *out) {
    size_t len = strlen(s), i;
    for (i = 0; i < len; i++) {
        unsigned day = 0, year = 0, H = 0, M = 0, S = 0;
        char mon[8];
        int nfields = sscanf(s + i,
            "%2u%*[ -]%3[A-Za-z]%*[ -]%u %2u:%2u:%2u",
            &day, mon, &year, &H, &M, &S);
        if (nfields == 6) {
            int m;
            char lm[4];
            if (strlen(mon) != 3) continue;
            lm[0] = (char)tolower((unsigned char)mon[0]);
            lm[1] = (char)tolower((unsigned char)mon[1]);
            lm[2] = (char)tolower((unsigned char)mon[2]);
            lm[3] = '\0';
            for (m = 0; m < 12; m++) if (strcmp(lm, ft_mon[m]) == 0) break;
            if (m == 12) continue;
            if (year < 100) year += (year < 70 ? 2000 : 1900);
            if (day < 1 || day > 31 || H > 23 || M > 59 || S > 61) continue;
            *out = ft_timegm((int)S, (int)M, (int)H, (int)day, m, (int)year);
            return 1;
        }
    }
    return 0;
}

/* --- matching ----------------------------------------------------------- */

static int ft_domain_match(const char *host, const char *domain, int host_only) {
    size_t hl = strlen(host), dl = strlen(domain);
    if (host_only) return ft_ci_streq(host, domain);
    if (ft_ci_streq(host, domain)) return 1;
    /* subdomain: host ends with ".domain" (case-insensitive) */
    if (hl > dl + 1 && host[hl - dl - 1] == '.') {
        const char *tail = host + (hl - dl);
        return ft_ci_streq(tail, domain);
    }
    return 0;
}

static int ft_path_match(const char *req, const char *cookie) {
    size_t cl = strlen(cookie);
    if (strcmp(req, cookie) == 0) return 1;
    if (strncmp(req, cookie, cl) != 0) return 0;
    if (cl && cookie[cl - 1] == '/') return 1;
    return req[cl] == '/';
}

/* default-path per RFC 6265 5.1.4, from the request path (query stripped) */
static char *ft_default_path(const char *p) {
    const char *q = strchr(p, '?');
    size_t plen = q ? (size_t)(q - p) : strlen(p);
    const char *last;
    if (plen == 0 || p[0] != '/') return ft_strdup0("/");
    /* last '/' within [0,plen) */
    { size_t i; last = NULL; for (i = 0; i < plen; i++) if (p[i] == '/') last = p + i; }
    if (!last || last == p) return ft_strdup0("/");
    return ft_strdup_n(p, (size_t)(last - p));
}

/* --- store -------------------------------------------------------------- */

static int ft_cookie_same(const ft_cookie *c, const char *dom, const char *path,
                          const char *name) {
    return ft_ci_streq(c->domain, dom)
        && strcmp(c->path, path) == 0
        && strcmp(c->name, name) == 0;
}

/* index of the (domain,path,name) triple, or -1 */
static long ft_jar_find(ft_jar *j, const char *dom, const char *path,
                        const char *name) {
    size_t i;
    for (i = 0; i < j->n; i++)
        if (ft_cookie_same(&j->v[i], dom, path, name)) return (long)i;
    return -1;
}

static void ft_jar_delete_at(ft_jar *j, size_t idx) {
    ft_cookie_wipe(&j->v[idx]);
    if (idx < j->n - 1) j->v[idx] = j->v[j->n - 1];
    j->n--;
}

/* move ownership of *src into the store, replacing any same-triple cookie */
static void ft_jar_put(ft_jar *j, ft_cookie *src) {
    long idx = ft_jar_find(j, src->domain, src->path, src->name);
    if (idx >= 0) { ft_cookie_wipe(&j->v[idx]); j->v[idx] = *src; return; }
    if (j->n == j->cap) {
        size_t nc = j->cap ? j->cap * 2 : 8;
        ft_cookie *nv = (ft_cookie *)realloc(j->v, nc * sizeof(ft_cookie));
        if (!nv) { ft_cookie_wipe(src); return; }
        j->v = nv; j->cap = nc;
    }
    j->v[j->n++] = *src;
}

/* --- Set-Cookie parsing ------------------------------------------------- */

static void ft_trim(const char **ps, size_t *pn) {
    const char *s = *ps; size_t n = *pn;
    while (n && (s[0]==' '||s[0]=='\t'||s[0]=='\r'||s[0]=='\n'||s[0]=='\f')) { s++; n--; }
    while (n && (s[n-1]==' '||s[n-1]=='\t'||s[n-1]=='\r'||s[n-1]=='\n'||s[n-1]=='\f')) n--;
    *ps = s; *pn = n;
}

/* Parse one Set-Cookie value for request host/req_path and store or delete it.
 * Returns 1 if the jar was touched (stored or deleted), 0 on a malformed value
 * that was ignored. */
static int ft_jar_set_cookie(ft_jar *j, const char *str, const char *host,
                             const char *req_path) {
    ft_cookie c;
    const char *p, *end, *seg;
    const char *dom_attr = NULL; size_t dom_len = 0;
    const char *path_attr = NULL; size_t path_len = 0;
    int max_age_delete = 0;
    time_t now = time(NULL);
    int first = 1;

    if (!str || !*str) return 0;
    memset(&c, 0, sizeof c);

    p = str; end = str + strlen(str);
    while (p <= end) {
        const char *semi = memchr(p, ';', (size_t)(end - p));
        const char *sstart = p;
        size_t slen = semi ? (size_t)(semi - p) : (size_t)(end - p);
        seg = sstart;
        ft_trim(&seg, &slen);
        p = semi ? semi + 1 : end + 1;

        if (first) {
            /* name=value */
            const char *eq = memchr(seg, '=', slen);
            const char *nm, *vl; size_t nl, vln;
            first = 0;
            if (!eq) return 0;
            nm = seg; nl = (size_t)(eq - seg);
            vl = eq + 1; vln = slen - nl - 1;
            ft_trim(&nm, &nl); ft_trim(&vl, &vln);
            if (!nl) return 0;
            c.name  = ft_strdup_n(nm, nl);
            c.value = ft_strdup_n(vl, vln);
            continue;
        }
        if (!slen) continue;
        {
            const char *eq = memchr(seg, '=', slen);
            const char *kk = seg, *vv = NULL; size_t kl = slen, vl = 0;
            if (eq) { kl = (size_t)(eq - seg); vv = eq + 1; vl = slen - kl - 1;
                      ft_trim(&kk, &kl); ft_trim(&vv, &vl); }
            else    { ft_trim(&kk, &kl); }
            if (kl == 6 && strncasecmp(kk, "domain", 6) == 0) {
                if (vv) { if (vl && vv[0] == '.') { vv++; vl--; }
                          dom_attr = vv; dom_len = vl; }
            } else if (kl == 4 && strncasecmp(kk, "path", 4) == 0) {
                if (vv) { path_attr = vv; path_len = vl; }
            } else if (kl == 6 && strncasecmp(kk, "secure", 6) == 0) {
                c.secure = 1;
            } else if (kl == 8 && strncasecmp(kk, "httponly", 8) == 0) {
                c.httponly = 1;
            } else if (kl == 7 && strncasecmp(kk, "max-age", 7) == 0 && vv) {
                char *tmp = ft_strdup_n(vv, vl), *endp = NULL;
                if (tmp) {
                    long ma = strtol(tmp, &endp, 10);
                    if (endp && *endp == '\0' && endp != tmp) {
                        c.expires = now + ma; c.has_expires = 1;
                        if (ma <= 0) max_age_delete = 1;
                    }
                    free(tmp);
                }
            } else if (kl == 7 && strncasecmp(kk, "expires", 7) == 0
                       && vv && !c.has_expires) {
                char *tmp = ft_strdup_n(vv, vl);
                time_t t;
                if (tmp) {
                    if (ft_parse_date(tmp, &t)) { c.expires = t; c.has_expires = 1; }
                    free(tmp);
                }
            }
        }
    }

    /* domain: default to host (host-only); else must domain-match */
    if (dom_attr && dom_len) {
        c.host_only = 0;
        c.domain = ft_strdup_n(dom_attr, dom_len);
        /* Reject a single-label / public-suffix Domain (e.g. "com", ".com",
         * "localhost"): a cookie must not be scoped to a whole TLD, or it would
         * be sent to every host under it. Full Public Suffix List handling is
         * out of scope; requiring an interior dot blocks the blatant TLD
         * supercookie. */
        {
            const char *d = c.domain;
            if (*d == '.') d++;                    /* ignore a single leading dot */
            if (!strchr(d, '.')) { ft_cookie_wipe(&c); return 0; }
        }
        if (!ft_domain_match(host, c.domain, 0)) { ft_cookie_wipe(&c); return 0; }
    } else {
        c.host_only = 1;
        c.domain = ft_strdup0(host);
    }
    if (path_attr && path_len) c.path = ft_strdup_n(path_attr, path_len);
    else                       c.path = ft_default_path(req_path);

    if ((c.has_expires && c.expires <= now) || max_age_delete) {
        long idx = ft_jar_find(j, c.domain, c.path, c.name);
        if (idx >= 0) ft_jar_delete_at(j, (size_t)idx);
        ft_cookie_wipe(&c);
        return 1;
    }
    ft_jar_put(j, &c);
    return 1;
}

/* --- housekeeping ------------------------------------------------------- */

static void ft_jar_clear(ft_jar *j) {
    size_t i;
    for (i = 0; i < j->n; i++) ft_cookie_wipe(&j->v[i]);
    j->n = 0;
}

static int ft_jar_purge(ft_jar *j) {
    time_t now = time(NULL);
    size_t i = 0; int removed = 0;
    while (i < j->n) {
        if (j->v[i].has_expires && j->v[i].expires <= now) {
            ft_jar_delete_at(j, i); removed++;
        } else i++;
    }
    return removed;
}

/* longest-path-first ordering for the Cookie header (RFC 6265 5.4) */
typedef struct { size_t len; size_t i; } ft_match;
static int ft_match_cmp(const void *a, const void *b) {
    size_t la = ((const ft_match *)a)->len, lb = ((const ft_match *)b)->len;
    return (la < lb) - (la > lb);   /* descending */
}

/* Build the "n1=v1; n2=v2" Cookie header for a request, longest path first, or
 * NULL if nothing matches. Caller frees the returned buffer. */
static char *ft_jar_cookie_str(ft_jar *j, const char *host,
                               const char *req_path, int secure) {
    const char *q = strchr(req_path, '?');
    size_t plen = q ? (size_t)(q - req_path) : strlen(req_path);
    char *path = plen ? ft_strdup_n(req_path, plen) : ft_strdup0("/");
    time_t now = time(NULL);
    ft_match *ms;
    size_t m = 0, k, total = 0;
    char *out = NULL;

    ms = (ft_match *)malloc((j->n ? j->n : 1) * sizeof(ft_match));
    for (k = 0; k < j->n; k++) {
        ft_cookie *c = &j->v[k];
        if (c->secure && !secure) continue;
        if (c->has_expires && c->expires <= now) continue;
        if (!ft_domain_match(host, c->domain, c->host_only)) continue;
        if (!ft_path_match(path, c->path)) continue;
        ms[m].len = strlen(c->path);
        ms[m].i   = k;
        m++;
    }
    if (m) {
        char *p;
        qsort(ms, m, sizeof(ft_match), ft_match_cmp);
        for (k = 0; k < m; k++) {
            ft_cookie *c = &j->v[ms[k].i];
            total += strlen(c->name) + 1 + strlen(c->value);   /* name=value */
            if (k) total += 2;                                 /* "; " */
        }
        out = (char *)malloc(total + 1);
        p = out;
        for (k = 0; k < m; k++) {
            ft_cookie *c = &j->v[ms[k].i];
            size_t nl = strlen(c->name), vl = strlen(c->value);
            if (k) { *p++ = ';'; *p++ = ' '; }
            memcpy(p, c->name, nl);  p += nl;
            *p++ = '=';
            memcpy(p, c->value, vl); p += vl;
        }
        *p = '\0';
    }
    free(ms);
    free(path);
    return out;
}

#endif /* FT_COOKIEJAR_H */
