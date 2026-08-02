#ifndef FT_UA_H
#define FT_UA_H

/* The Fetch user agent, fully in C. A Fetch object is a blessed IV holding an
 * ft_ua*; new() resolves the event-loop adapter and builds the default header
 * set / cookie jar / connection pool, and request()/get()/... run the HTTP
 * exchange - URL parsing, header merge, cookie application, request
 * serialisation, and redirect following (a Future chain built with the C
 * Future API in ft_future.h). The foreign event-loop adapters stay in Perl;
 * everything else here is C.
 *
 * Included from Fetch.xs after the ft_loop_from_sv / ft_pool_from_sv /
 * ft_obj_can statics it depends on. */

typedef struct {
    SV     *loop;         /* resolved Fetch::Loop adapter */
    SV     *pool;         /* Fetch::_Pool, or NULL when keep_alive is off */
    SV     *headers;      /* default headers, a Fetch::Headers */
    SV     *agent;        /* User-Agent string */
    SV     *cookie_jar;   /* Fetch::CookieJar, or NULL */
    int     tls_verify;
    int     max_redirects;
    int     keep_alive;
    int     simple_response;   /* resolve to a raw hash, not a Fetch::Response */
    double  timeout;
} ft_ua;

static ft_ua *ft_ua_of(pTHX_ SV *sv) {
    if (!(SvROK(sv) && SvIOK(SvRV(sv))))
        croak("Fetch: not a Fetch user agent");
    return INT2PTR(ft_ua *, SvIV(SvRV(sv)));
}

/* ---- URL parsing -------------------------------------------------------- */

typedef struct { char *scheme, *host, *path; int port; } ft_url;

static void ft_url_free(ft_url *u) {
    free(u->scheme); free(u->host); free(u->path);
    u->scheme = u->host = u->path = NULL;
}

/* Parse scheme://host[:port][path]. Mirrors Fetch::_parse_url; returns 1 on
 * success (fields malloc'd), 0 if there is no "://". */
static int ft_parse_url(const char *url, ft_url *u) {
    const char *sep = strstr(url, "://");
    const char *h, *p, *rest;
    size_t i;
    memset(u, 0, sizeof *u);
    if (!sep) return 0;
    u->scheme = ft_lc_dup(url, (STRLEN)(sep - url));
    h = sep + 3;
    p = h;
    while (*p && *p != '/' && *p != ':' && *p != '?' && *p != '#') p++;
    u->host = ft_strdup_n(h, (size_t)(p - h));
    if (*p == ':') {
        p++;
        u->port = 0;
        while (*p >= '0' && *p <= '9') { u->port = u->port * 10 + (*p - '0'); p++; }
    } else {
        u->port = 0;
    }
    if (u->port == 0)
        u->port = (strcmp(u->scheme, "https") == 0) ? 443 : 80;
    rest = p;
    u->path = (*rest) ? ft_strdup0(rest) : ft_strdup0("/");
    if (!u->path[0]) { free(u->path); u->path = ft_strdup0("/"); }
    (void)i;
    return 1;
}

/* authority for the Host header / :authority: host, or host:port off-default */
static char *ft_authority(const char *host, int port, int tls) {
    if (port == (tls ? 443 : 80)) return ft_strdup0(host);
    {
        char buf[300];
        snprintf(buf, sizeof buf, "%s:%d", host, port);
        return ft_strdup0(buf);
    }
}

/* ---- redirect helpers --------------------------------------------------- */

/* 307/308 keep method+body; 303 or POST become GET without a body; otherwise
 * the method (and body) are preserved. Returns the (possibly new) method and
 * sets *drop_body when the body must be dropped. */
static const char *ft_redirect_method(const char *method, int status,
                                      int *drop_body) {
    *drop_body = 0;
    if (status == 307 || status == 308) return method;
    if (status == 303 || strcasecmp(method, "POST") == 0) {
        *drop_body = 1;
        return "GET";
    }
    return method;
}

/* Resolve a Location against the request URL (absolute / scheme-relative /
 * root-relative / path-relative). Returns a fresh SV. */
static SV *ft_resolve_location(pTHX_ const char *base, SV *loc_sv) {
    STRLEN ll;
    const char *loc = SvPV_const(loc_sv, ll);
    ft_url u;
    char *authority;
    SV *out;

    /* absolute: scheme://... */
    {
        const char *s = loc;
        if (isALPHA((unsigned char)*s)) {
            const char *q = s + 1;
            while (*q && (isALNUM((unsigned char)*q) || *q=='+' || *q=='.' || *q=='-')) q++;
            if (q[0]==':' && q[1]=='/' && q[2]=='/')
                return newSVpvn(loc, ll);
        }
    }
    if (!ft_parse_url(base, &u)) return newSVpvn(loc, ll);
    authority = ft_authority(u.host, u.port, strcmp(u.scheme, "https") == 0);

    if (ll >= 2 && loc[0]=='/' && loc[1]=='/') {          /* scheme-relative */
        out = newSVpvf("%s:%.*s", u.scheme, (int)ll, loc);
    } else if (ll >= 1 && loc[0]=='/') {                  /* root-relative */
        out = newSVpvf("%s://%s%.*s", u.scheme, authority, (int)ll, loc);
    } else {                                              /* path-relative */
        /* dir = request path up to and including the last '/' before any '?' */
        const char *q = strchr(u.path, '?');
        size_t plen = q ? (size_t)(q - u.path) : strlen(u.path);
        long last = -1; size_t i;
        for (i = 0; i < plen; i++) if (u.path[i] == '/') last = (long)i;
        out = newSVpvf("%s://%s", u.scheme, authority);
        if (last <= 0) sv_catpvs(out, "/");
        else sv_catpvn(out, u.path, (STRLEN)(last + 1));
        sv_catpvn(out, loc, ll);
    }
    free(authority);
    ft_url_free(&u);
    return out;
}

/* ---- request serialisation --------------------------------------------- */

/* Serialize the HTTP/1.1 request bytes from the merged header list. */
static SV *ft_build_request(pTHX_ ft_ua *ua, const char *method,
                            const char *host, int port, const char *path,
                            AV *hav, SV *body) {
    SV *req = newSV(256);   /* preallocate: most request heads fit, no realloc */
    SSize_t n, i;
    SvPOK_on(req);
    SvCUR_set(req, 0);
    *SvPVX(req) = '\0';
    sv_catpv(req, method); sv_catpvs(req, " ");
    sv_catpv(req, path);   sv_catpvs(req, " HTTP/1.1\r\n");
    if (!ft_hdr_exists(aTHX_ hav, "Host", 4)) {
        if (port == 80 || port == 443) {
            sv_catpvs(req, "Host: "); sv_catpv(req, host); sv_catpvs(req, "\r\n");
        } else {
            sv_catpvf(req, "Host: %s:%d\r\n", host, port);
        }
    }
    if (!ua->keep_alive && !ft_hdr_exists(aTHX_ hav, "Connection", 10))
        sv_catpvs(req, "Connection: close\r\n");
    if (body && SvOK(body)) {
        STRLEN bl; (void)SvPV(body, bl);
        if (bl && !ft_hdr_exists(aTHX_ hav, "Content-Length", 14))
            sv_catpvf(req, "Content-Length: %lu\r\n", (unsigned long)bl);
    }
    n = av_len(hav) + 1;
    for (i = 0; i + 1 < n; i += 2) {
        SV **k = av_fetch(hav, i, 0);
        SV **v = av_fetch(hav, i + 1, 0);
        STRLEN kl, vl;
        const char *ks = (k && *k) ? SvPV_const(*k, kl) : (kl = 0, "");
        const char *vs = (v && *v) ? SvPV_const(*v, vl) : (vl = 0, "");
        sv_catpvn(req, ks, kl); sv_catpvs(req, ": ");
        sv_catpvn(req, vs, vl); sv_catpvs(req, "\r\n");
    }
    sv_catpvs(req, "\r\n");
    if (body && SvOK(body)) sv_catsv(req, body);
    return req;
}

/* ---- response peeking (for redirects/cookies) --------------------------- */

static int ft_response_status(pTHX_ SV *res) {
    if (res && SvROK(res) && SvTYPE(SvRV(res)) == SVt_PVHV) {
        SV **e = hv_fetchs((HV *)SvRV(res), "status", 0);
        if (e && *e) return (int)SvIV(*e);
    }
    return 0;
}

/* borrowed value SV of the first matching header, or NULL */
static SV *ft_response_header(pTHX_ SV *res, const char *name, STRLEN nl) {
    if (res && SvROK(res) && SvTYPE(SvRV(res)) == SVt_PVHV) {
        SV **hp = hv_fetchs((HV *)SvRV(res), "headers", 0);
        if (hp && *hp && SvROK(*hp) && SvTYPE(SvRV(*hp)) == SVt_PVAV) {
            AV *av = (AV *)SvRV(*hp);
            SSize_t idx = ft_hdr_find(aTHX_ av, name, nl);
            if (idx >= 0) { SV **v = av_fetch(av, idx + 1, 0); return (v && *v) ? *v : NULL; }
        }
    }
    return NULL;
}

/* ---- loop resolution + object construction ------------------------------ */

static SV *ft_load_new(pTHX_ const char *class, SV *arg) {
    SV *obj;
    dSP;
    int n;
    load_module(PERL_LOADMOD_NOIMPORT, newSVpv(class, 0), NULL);
    ENTER; SAVETMPS; PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(class, 0)));
    if (arg) XPUSHs(arg);
    PUTBACK;
    n = call_method("new", G_SCALAR);
    SPAGAIN;
    obj = n ? SvREFCNT_inc(POPs) : newSV(0);   /* survive the FREETMPS below */
    PUTBACK; FREETMPS; LEAVE;
    return obj;
}

/* Turn whatever was passed as `loop` into a Fetch::Loop adapter (see
 * Fetch::_resolve_loop). Returns an owned reference. */
static SV *ft_resolve_loop(pTHX_ SV *loop) {
    if (!loop || !SvOK(loop))
        return ft_load_new(aTHX_ "Fetch::Loop::Standalone", NULL);
    if (sv_isobject(loop)) {
        if (sv_derived_from(loop, "Fetch::Loop::Standalone")
            || sv_derived_from(loop, "Fetch::Loop"))
            return SvREFCNT_inc(loop);
        if (sv_derived_from(loop, "IO::Async::Loop"))
            return ft_load_new(aTHX_ "Fetch::Loop::IOAsync", loop);
        if (sv_derived_from(loop, "Hyperman::Loop"))
            return ft_load_new(aTHX_ "Fetch::Loop::Hyperman", loop);
        if (ft_obj_can(aTHX_ loop, "_ft_arm"))
            return SvREFCNT_inc(loop);
        croak("Fetch: don't know how to drive loop '%s'",
              sv_reftype(SvRV(loop), 1));
    }
    if (SvPOK(loop) && strEQ(SvPV_nolen(loop), "AnyEvent"))
        return ft_load_new(aTHX_ "Fetch::Loop::AnyEvent", NULL);
    croak("Fetch: unrecognised loop '%s'", SvPV_nolen(loop));
}

/* forward declarations for the redirect chain */
static SV *ft_request_once(pTHX_ SV *self_sv, ft_ua *ua, const char *method,
                           const char *url, HV *opt);
static SV *ft_follow(pTHX_ SV *self_sv, ft_ua *ua, const char *method,
                     const char *url, HV *opt, IV left);

/* ---- cookie-extract continuation (attached like Perl's on_done) --------- */

XS_INTERNAL(ft_extract_cb);
XS_INTERNAL(ft_extract_cb) {
    dXSARGS;
    hm_clos *cl = hm_clos_of(aTHX_ cv);
    SV *f;
    if (!cl || items < 1) XSRETURN_EMPTY;
    f = ST(0);
    if (hmf_state(aTHX_ f) == HMF_DONE) {
        AV *vals = hmf_values_av(aTHX_ f);
        SV **rp = (vals && av_len(vals) >= 0) ? av_fetch(vals, 0, 0) : NULL;
        SV *res = rp ? *rp : NULL;
        if (res && SvROK(res) && SvTYPE(SvRV(res)) == SVt_PVHV) {
            ft_jar *j = ft_jar_of(aTHX_ cl->a);
            const char *host = SvPV_nolen(cl->b);
            const char *path = SvPV_nolen(cl->c);
            SV **hp = hv_fetchs((HV *)SvRV(res), "headers", 0);
            if (hp && *hp && SvROK(*hp) && SvTYPE(SvRV(*hp)) == SVt_PVAV) {
                AV *av = (AV *)SvRV(*hp);
                SSize_t n = av_len(av) + 1, i;
                for (i = 0; i + 1 < n; i += 2) {
                    SV **k = av_fetch(av, i, 0);
                    if (k && *k) {
                        STRLEN kl;
                        const char *ks = SvPV_const(*k, kl);
                        if (ft_ci_eq(ks, kl, "set-cookie", 10)) {
                            SV **v = av_fetch(av, i + 1, 0);
                            if (v && *v) {
                                STRLEN vl;
                                const char *vs = SvPV_const(*v, vl);
                                if (vl) ft_jar_set_cookie(j, vs, host, path);
                            }
                        }
                    }
                }
            }
        }
    }
    XSRETURN_EMPTY;
}

/* ---- one request (no redirect) ------------------------------------------ */

static SV *ft_request_once(pTHX_ SV *self_sv, ft_ua *ua, const char *method,
                           const char *url, HV *opt) {
    ft_url u;
    int tls, verify;
    double timeout;
    AV *hav, *h2;
    char *authority;
    char portbuf[16];
    SV *req, *hdrs2_rv, *m_sv, *sc_sv, *au_sv, *pa_sv, *f;
    SV *body = NULL, *on_body = NULL, *json_body = NULL;
    ft_loop *l = NULL; SV *lsv = NULL;
    ft_pool *pl;
    SSize_t n, i;

    if (!ft_parse_url(url, &u))
        croak("Fetch: cannot parse URL '%s'", url);
    if (strcmp(u.scheme, "http") != 0 && strcmp(u.scheme, "https") != 0) {
        SV *fu = hmf_new(aTHX_ "Fetch::Future");
        SV *e  = sv_2mortal(newSVpvf("Fetch: unsupported scheme '%s'\n", u.scheme));
        hmf_settle(aTHX_ fu, HMF_FAILED, &e, 1);
        ft_url_free(&u);
        return fu;
    }
    tls    = (strcmp(u.scheme, "https") == 0);
    verify = ua->tls_verify;
    if (opt) {
        SV **tv = hv_fetchs(opt, "tls_verify", 0);
        if (tv && *tv) verify = SvTRUE(*tv) ? 1 : 0;
    }

    /* merged headers: defaults, overlaid with this request's headers */
    hav = newAV();
    sv_2mortal((SV *)hav);
    ft_hdr_pairs_into(aTHX_ hav, ua->headers);
    if (opt) {
        SV **oh = hv_fetchs(opt, "headers", 0);
        if (oh && *oh) ft_hdr_merge(aTHX_ hav, *oh);
    }
    if (!ft_hdr_exists(aTHX_ hav, "User-Agent", 10)) {
        av_push(hav, newSVpvs("User-Agent"));
        av_push(hav, newSVsv(ua->agent));
    }
    if (ua->cookie_jar && SvOK(ua->cookie_jar)
        && !ft_hdr_exists(aTHX_ hav, "Cookie", 6)) {
        char *ck = ft_jar_cookie_str(ft_jar_of(aTHX_ ua->cookie_jar),
                                     u.host, u.path, tls);
        if (ck && *ck) {
            av_push(hav, newSVpvs("Cookie"));
            av_push(hav, newSVpv(ck, 0));
        }
        free(ck);
    }

    /* json => $data: encode to the body and default Content-Type. Done before
     * the h2 list so the header is carried on either protocol. */
    if (opt) {
        SV **jp = hv_fetchs(opt, "json", 0);
        if (jp && *jp && SvOK(*jp)) {
            json_body = sv_2mortal(ft_json_encode(aTHX_ *jp));
            if (!ft_hdr_exists(aTHX_ hav, "Content-Type", 12)) {
                av_push(hav, newSVpvs("Content-Type"));
                av_push(hav, newSVpvs("application/json"));
            }
        }
    }

    /* h2 header list (lowercased names, minus hop-by-hop/length fields): only
     * consumed if ALPN negotiates h2, which can only happen on TLS. Skip the
     * whole thing - a full second pass over the headers - for cleartext. */
    h2 = NULL;
    if (tls) {
        h2 = newAV();
        n = av_len(hav) + 1;
        for (i = 0; i + 1 < n; i += 2) {
            SV **k = av_fetch(hav, i, 0);
            SV **v = av_fetch(hav, i + 1, 0);
            STRLEN kl;
            const char *ks = (k && *k) ? SvPV_const(*k, kl) : (kl = 0, "");
            if (ft_ci_eq(ks, kl, "host", 4) || ft_ci_eq(ks, kl, "connection", 10)
                || ft_ci_eq(ks, kl, "content-length", 14)
                || ft_ci_eq(ks, kl, "transfer-encoding", 17))
                continue;
            {
                char *lc = ft_lc_dup(ks, kl);
                av_push(h2, newSVpvn(lc, kl));
                free(lc);
                av_push(h2, (v && *v) ? newSVsv(*v) : newSV(0));
            }
        }
    }

    timeout = ua->timeout;
    if (opt) {
        SV **to = hv_fetchs(opt, "timeout", 0);
        if (to && *to) timeout = SvNV(*to);
        body    = hv_fetchs(opt, "body", 0)    ? *hv_fetchs(opt, "body", 0)    : NULL;
        on_body = hv_fetchs(opt, "on_body", 0) ? *hv_fetchs(opt, "on_body", 0) : NULL;
        if (body && !SvOK(body)) body = NULL;
    }
    if (json_body) body = json_body;   /* json => wins over an explicit body */

    req = sv_2mortal(ft_build_request(aTHX_ ua, method, u.host, u.port, u.path,
                                      hav, body));
    snprintf(portbuf, sizeof portbuf, "%d", u.port);

    if (sv_isobject(ua->loop) && sv_derived_from(ua->loop, "Fetch::Loop::Standalone"))
        l = ft_loop_from_sv(aTHX_ ua->loop);
    else
        lsv = ua->loop;
    pl = ua->pool ? ft_pool_from_sv(aTHX_ ua->pool) : NULL;

    /* the pseudo-header pieces (method/scheme/:authority/path) and the h2 nva
     * are h2-only too; pass undef for cleartext so ft_h1_start stores nothing. */
    authority = NULL;
    if (tls) {
        authority = ft_authority(u.host, u.port, tls);
        m_sv  = sv_2mortal(newSVpv(method, 0));
        sc_sv = sv_2mortal(newSVpv(u.scheme, 0));
        au_sv = sv_2mortal(newSVpv(authority, 0));
        pa_sv = sv_2mortal(newSVpv(u.path, 0));
        hdrs2_rv = sv_2mortal(newRV_noinc((SV *)h2));
    } else {
        m_sv = sc_sv = au_sv = pa_sv = hdrs2_rv = &PL_sv_undef;
    }

    {
        STRLEN rl;
        const char *rb = SvPV_const(req, rl);
        ft_conn_simple_next = ua->simple_response;   /* inherited by a fresh conn */
        f = ft_h1_start(aTHX_ l, lsv, pl, u.host, portbuf, rb, rl, tls, verify,
                        timeout, m_sv, sc_sv, au_sv, pa_sv, hdrs2_rv,
                        body ? body : &PL_sv_undef,
                        on_body ? on_body : &PL_sv_undef, NULL);
    }

    /* store any Set-Cookie before the caller/redirect-follower runs */
    if (ua->cookie_jar && SvOK(ua->cookie_jar)) {
        SV *hostsv = newSVpv(u.host, 0);
        SV *pathsv = newSVpv(u.path, 0);
        SV *cb = hm_closure(aTHX_ ft_extract_cb, ua->cookie_jar, hostsv, pathsv,
                            NULL, 0, 0);
        SvREFCNT_dec(hostsv);
        SvREFCNT_dec(pathsv);
        hmf_on_ready(aTHX_ f, cb);
        SvREFCNT_dec(cb);
    }

    free(authority);
    ft_url_free(&u);
    return f;
}

/* ---- redirect continuation ---------------------------------------------- */

XS_INTERNAL(ft_redirect_cb);
XS_INTERNAL(ft_redirect_cb) {
    dXSARGS;
    hm_clos *cl = hm_clos_of(aTHX_ cv);
    SV *f, *next, *self_sv;
    AV *pack;
    IV left, st;
    const char *method, *url;
    HV *opt = NULL;
    if (!cl || items < 1) XSRETURN_EMPTY;
    f       = ST(0);
    next    = cl->a;
    self_sv = cl->b;
    pack    = (AV *)SvRV(cl->c);
    left    = cl->i;
    method  = SvPV_nolen(*av_fetch(pack, 0, 0));
    url     = SvPV_nolen(*av_fetch(pack, 1, 0));
    {
        SV **op = av_fetch(pack, 2, 0);
        if (op && *op && SvROK(*op) && SvTYPE(SvRV(*op)) == SVt_PVHV)
            opt = (HV *)SvRV(*op);
    }

    st = hmf_state(aTHX_ f);
    if (st != HMF_DONE) {                       /* propagate failure/cancel */
        if (st == HMF_FAILED) {
            AV *vals = hmf_values_av(aTHX_ f);
            SSize_t n = vals ? av_len(vals) + 1 : 0, i;
            AV *out = newAV();
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(vals, i, 0);
                av_push(out, e ? newSVsv(*e) : newSV(0));
            }
            hmf_settle_av(aTHX_ next, HMF_FAILED, out);
        } else {
            hmf_cancel(aTHX_ next);
        }
        XSRETURN_EMPTY;
    }

    {
        AV *vals = hmf_values_av(aTHX_ f);
        SV **rp = (vals && av_len(vals) >= 0) ? av_fetch(vals, 0, 0) : NULL;
        SV *res = rp ? *rp : &PL_sv_undef;
        int status = ft_response_status(aTHX_ res);
        SV *loc = (status >= 300 && status < 400)
                ? ft_response_header(aTHX_ res, "location", 8) : NULL;

        if (!(loc && SvOK(loc) && SvCUR(loc) > 0)) {   /* not a redirect */
            SV *cp = newSVsv(res);
            hmf_settle(aTHX_ next, HMF_DONE, &cp, 1);
            SvREFCNT_dec(cp);
            XSRETURN_EMPTY;
        }
        {
            int drop_body;
            const char *m2 = ft_redirect_method(method, status, &drop_body);
            SV *u2 = ft_resolve_location(aTHX_ url, loc);
            HV *o2 = newHV();
            SV *child, *cb2;
            if (opt) {
                HE *he;
                hv_iterinit(opt);
                while ((he = hv_iternext(opt))) {
                    I32 kl;
                    char *k = hv_iterkey(he, &kl);
                    (void)hv_store(o2, k, kl, newSVsv(hv_iterval(opt, he)), 0);
                }
            }
            if (drop_body) (void)hv_delete(o2, "body", 4, G_DISCARD);

            child = ft_follow(aTHX_ self_sv, ft_ua_of(aTHX_ self_sv),
                              m2, SvPV_nolen(u2), o2, left - 1);
            cb2 = hm_closure(aTHX_ hm_xs_chain_cb, next, NULL, NULL, NULL, 0, 0);
            hm_any_on_ready(aTHX_ child, cb2);
            SvREFCNT_dec(cb2);
            SvREFCNT_dec(child);
            SvREFCNT_dec(u2);
            SvREFCNT_dec((SV *)o2);
        }
    }
    XSRETURN_EMPTY;
}

/* ---- follow: request, then chain a redirect if there are hops left ------ */

static SV *ft_follow(pTHX_ SV *self_sv, ft_ua *ua, const char *method,
                     const char *url, HV *opt, IV left) {
    SV *f = ft_request_once(aTHX_ self_sv, ua, method, url, opt);
    if (left <= 0) return f;
    {
        SV *next = hmf_new(aTHX_ hmf_class_of(aTHX_ f));
        AV *pack = newAV();
        SV *pack_rv, *cb;
        av_push(pack, newSVpv(method, 0));
        av_push(pack, newSVpv(url, 0));
        av_push(pack, opt ? newRV_inc((SV *)opt) : newSV(0));
        pack_rv = newRV_noinc((SV *)pack);
        hmf_set_upstream(aTHX_ next, f);
        cb = hm_closure(aTHX_ ft_redirect_cb, next, self_sv, pack_rv, NULL,
                        left, 0);
        SvREFCNT_dec(pack_rv);              /* hm_closure took its own ref */
        hmf_on_ready(aTHX_ f, cb);
        SvREFCNT_dec(cb);
        SvREFCNT_dec(f);                    /* the connection keeps f alive */
        return next;
    }
}

/* ---- verb dispatch ------------------------------------------------------ */

static SV *ft_dispatch(pTHX_ SV *self_sv, const char *method, const char *url,
                       SV **opt_args, int nopt) {
    HV *opt = newHV();
    ft_ua *ua = ft_ua_of(aTHX_ self_sv);
    IV max;
    int i;
    SV *f;
    for (i = 0; i + 1 < nopt; i += 2) {
        STRLEN kl;
        const char *k = SvPV_const(opt_args[i], kl);
        (void)hv_store(opt, k, (I32)kl, newSVsv(opt_args[i + 1]), 0);
    }
    if (hv_exists(opt, "max_redirects", 13)) {
        SV **m = hv_fetchs(opt, "max_redirects", 0);
        max = (m && *m && SvOK(*m)) ? SvIV(*m) : 0;
    } else {
        max = ua->max_redirects;
    }
    if (max < 0) max = 0;
    f = ft_follow(aTHX_ self_sv, ua, method, url, opt, max);
    SvREFCNT_dec((SV *)opt);
    return f;
}

/* ---- WebSocket ---------------------------------------------------------- */

/* the ft_conn behind a Fetch::WebSocket (a blessed IV over the connection) */
static ft_conn *ft_ws_of(pTHX_ SV *sv) {
    if (!(SvROK(sv) && SvIOK(SvRV(sv))))
        croak("Fetch::WebSocket: not a websocket");
    return INT2PTR(ft_conn *, SvIV(SvRV(sv)));
}

/* Open a WebSocket: send the HTTP/1.1 Upgrade handshake with a fresh key and
 * return a Future resolving to a Fetch::WebSocket once the 101 is verified.
 * Accepts ws:// wss:// http:// https:// (ws/http cleartext, wss/https TLS). */
static SV *ft_websocket(pTHX_ ft_ua *ua, const char *url, HV *opt) {
    ft_url u;
    int tls, verify;
    double timeout;
    AV *hav;
    char portbuf[16], wskey[25];
    char *authority;
    SV *req, *m_sv, *sc_sv, *au_sv, *pa_sv, *empty_rv, *f;
    ft_loop *l = NULL; SV *lsv = NULL;

    if (!ft_parse_url(url, &u))
        croak("Fetch: cannot parse URL '%s'", url);
    tls = (strcmp(u.scheme, "wss") == 0 || strcmp(u.scheme, "https") == 0);
    if (strcmp(u.scheme, "ws") && strcmp(u.scheme, "wss")
        && strcmp(u.scheme, "http") && strcmp(u.scheme, "https")) {
        SV *fu = hmf_new(aTHX_ "Fetch::Future");
        SV *e  = sv_2mortal(newSVpvf("Fetch: not a websocket URL scheme '%s'\n", u.scheme));
        hmf_settle(aTHX_ fu, HMF_FAILED, &e, 1);
        ft_url_free(&u);
        return fu;
    }
    if (tls && u.port == 80) u.port = 443;   /* default wss/https port */

    verify  = ua->tls_verify;
    timeout = ua->timeout;
    if (opt) {
        SV **tv = hv_fetchs(opt, "tls_verify", 0);
        SV **to = hv_fetchs(opt, "timeout", 0);
        if (tv && *tv) verify = SvTRUE(*tv) ? 1 : 0;
        if (to && *to) timeout = SvNV(*to);
    }

    ft_ws_genkey(wskey);

    hav = newAV();
    sv_2mortal((SV *)hav);
    ft_hdr_pairs_into(aTHX_ hav, ua->headers);
    if (opt) {
        SV **oh = hv_fetchs(opt, "headers", 0);
        if (oh && *oh) ft_hdr_merge(aTHX_ hav, *oh);
    }
    if (!ft_hdr_exists(aTHX_ hav, "User-Agent", 10)) {
        av_push(hav, newSVpvs("User-Agent")); av_push(hav, newSVsv(ua->agent));
    }
    if (!ft_hdr_exists(aTHX_ hav, "Upgrade", 7)) {
        av_push(hav, newSVpvs("Upgrade"));    av_push(hav, newSVpvs("websocket"));
    }
    if (!ft_hdr_exists(aTHX_ hav, "Connection", 10)) {
        av_push(hav, newSVpvs("Connection")); av_push(hav, newSVpvs("Upgrade"));
    }
    av_push(hav, newSVpvs("Sec-WebSocket-Key"));     av_push(hav, newSVpv(wskey, 0));
    av_push(hav, newSVpvs("Sec-WebSocket-Version")); av_push(hav, newSVpvs("13"));

    req = sv_2mortal(ft_build_request(aTHX_ ua, "GET", u.host, u.port, u.path,
                                      hav, NULL));
    authority = ft_authority(u.host, u.port, tls);
    snprintf(portbuf, sizeof portbuf, "%d", u.port);

    if (sv_isobject(ua->loop) && sv_derived_from(ua->loop, "Fetch::Loop::Standalone"))
        l = ft_loop_from_sv(aTHX_ ua->loop);
    else
        lsv = ua->loop;

    m_sv  = sv_2mortal(newSVpvs("GET"));
    sc_sv = sv_2mortal(newSVpv(u.scheme, 0));
    au_sv = sv_2mortal(newSVpv(authority, 0));
    pa_sv = sv_2mortal(newSVpv(u.path, 0));
    empty_rv = sv_2mortal(newRV_noinc((SV *)newAV()));

    {
        STRLEN rl;
        const char *rb = SvPV_const(req, rl);
        /* pool = NULL (never pooled); ws_key drives want_ws + the 101 check */
        f = ft_h1_start(aTHX_ l, lsv, NULL, u.host, portbuf, rb, rl, tls, verify,
                        timeout, m_sv, sc_sv, au_sv, pa_sv, empty_rv,
                        &PL_sv_undef, &PL_sv_undef, wskey);
    }

    free(authority);
    ft_url_free(&u);
    return f;
}

#endif /* FT_UA_H */
