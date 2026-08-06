#ifndef FT_ABI_H
#define FT_ABI_H

/* Fetch-side implementation of the shared C ABI (fetch_abi.h). Included by
 * Fetch.xs AFTER ft_ua.h / ft_future.h, so ft_ua_of, ft_follow and the hmf_*
 * future helpers are in scope. Everything here is private to Fetch's
 * translation unit; consumers reach it only through the FETCH_ABI table
 * returned by Fetch::_abi_ptr. */

#include "fetch_abi.h"

/* Construct a Fetch UA from flat key/value SV pairs (kv[0]=key, kv[1]=val,...);
 * the shared body of Fetch->new and the ABI ua_new. Blesses into `cls`. */
static SV *ft_ua_new(pTHX_ const char *cls, SV **kv, int nkv) {
    ft_ua *ua;
    SV *loop_arg = NULL, *headers_arg = NULL, *agent_arg = NULL, *jar_arg = NULL;
    int have_keep = 0, keep = 1, have_verify = 0, verify = 1;
    int have_maxr = 0, maxr = 5, pool_size = 32, simple = 0;
    double timeout = 0.0;
    int i;
    for (i = 0; i + 1 < nkv; i += 2) {
        const char *k = SvPV_nolen(kv[i]);
        SV *v = kv[i + 1];
        if      (strEQ(k, "loop"))            loop_arg = v;
        else if (strEQ(k, "headers"))         headers_arg = v;
        else if (strEQ(k, "agent"))           agent_arg = v;
        else if (strEQ(k, "cookie_jar"))      jar_arg = v;
        else if (strEQ(k, "keep_alive"))    { have_keep = 1;   keep = SvTRUE(v) ? 1 : 0; }
        else if (strEQ(k, "tls_verify"))    { have_verify = 1; verify = SvTRUE(v) ? 1 : 0; }
        else if (strEQ(k, "max_redirects")) { have_maxr = 1;   maxr = (int)SvIV(v); }
        else if (strEQ(k, "timeout"))         timeout = SvNV(v);
        else if (strEQ(k, "pool_size"))       pool_size = (int)SvIV(v);
        else if (strEQ(k, "simple_response")) simple = SvTRUE(v) ? 1 : 0;
    }
    Newxz(ua, 1, ft_ua);
    ua->loop = ft_resolve_loop(aTHX_ loop_arg);
    if (ft_obj_can(aTHX_ ua->loop, "install_await")) {
        dSP;
        ENTER; SAVETMPS; PUSHMARK(SP); XPUSHs(ua->loop); PUTBACK;
        call_method("install_await", G_DISCARD);
        FREETMPS; LEAVE;
    }
    /* Hyperman-direct mode: when the adapter is Fetch::Loop::Hyperman and
     * Hyperman's C ABI resolves (ft_hm.h), connections drive fd interest and
     * deadlines straight through the table. Absent/old Hyperman leaves both
     * NULL and the Perl _ft_arm/_ft_timer seam is used as before. */
    if (sv_isobject(ua->loop)
        && sv_derived_from(ua->loop, "Fetch::Loop::Hyperman")
        && SvTYPE(SvRV(ua->loop)) == SVt_PVHV) {
        const hm_abi *A = ft_hm(aTHX);
        SV **e = hv_fetchs((HV *)SvRV(ua->loop), "loop", 0);
        if (A && e && *e && sv_isobject(*e)
            && sv_derived_from(*e, "Hyperman::Loop")) {
            ua->hm_loop = A->loop_of_sv(aTHX_ *e);
            ua->hm      = A;
            /* C await: bridge + run_until instead of the Perl AWAIT sub */
            ft_hm_install_await(aTHX_ ua->loop, ua->hm_loop);
        }
    }
    ua->keep_alive = have_keep ? keep : 1;
    ua->simple_response = simple;
    if (jar_arg && SvOK(jar_arg)) {
        if (SvROK(jar_arg))       ua->cookie_jar = SvREFCNT_inc(jar_arg);
        else if (SvTRUE(jar_arg)) ua->cookie_jar = ft_load_new(aTHX_ "Fetch::CookieJar", NULL);
    }
    {
        AV *hav = newAV();
        if (headers_arg && SvOK(headers_arg))
            ft_hdr_pairs_into(aTHX_ hav, headers_arg);
        ua->headers = sv_bless(newRV_noinc((SV *)hav),
                               gv_stashpv("Fetch::Headers", GV_ADD));
    }
    if (agent_arg && SvOK(agent_arg)) {
        ua->agent = newSVsv(agent_arg);
    } else {
        SV *ver = get_sv("Fetch::VERSION", 0);
        ua->agent = newSVpvf("Fetch/%s", (ver && SvOK(ver)) ? SvPV_nolen(ver) : "0");
    }
    ua->tls_verify    = have_verify ? verify : 1;
    ua->max_redirects = have_maxr   ? maxr   : 5;
    ua->timeout       = timeout;
    if (ua->keep_alive) {
        ft_pool *p = ft_pool_new(pool_size > 0 ? pool_size : 32);
        if (!p) { SvREFCNT_dec(ua->loop); Safefree(ua); croak("Fetch: out of memory"); }
        ua->pool = sv_bless(newRV_noinc(newSViv(PTR2IV(p))),
                            gv_stashpv("Fetch::_Pool", GV_ADD));
    }
    return sv_bless(newRV_noinc(newSViv(PTR2IV(ua))), gv_stashpv(cls, GV_ADD));
}

static SV *ft_abi_ua_new(pTHX_ SV **kv, int nkv) {
    return ft_ua_new(aTHX_ "Fetch", kv, nkv);
}

/* carried through the upstream future to the completion callback */
typedef struct ft_abi_ctx { fetch_map_cb map; void *ud; } ft_abi_ctx;

/* Fires when the upstream request settles: read the response parts in C, let
 * the consumer's `map` shape the resolved value, settle the derived future
 * with it. Mirrors ft_redirect_cb's ownership (next lives in the closure). */
XS_INTERNAL(ft_abi_complete_cb);
XS_INTERNAL(ft_abi_complete_cb) {
    dXSARGS;
    hm_clos    *cl = hm_clos_of(aTHX_ cv);
    SV         *f, *next, *val, *err = NULL;
    ft_abi_ctx *ctx;
    int         ok = 0, status = 0;
    AV         *headers = NULL;
    SV         *body    = NULL;
    IV          st;
    if (!cl || items < 1) XSRETURN_EMPTY;
    f    = ST(0);
    next = cl->a;
    ctx  = INT2PTR(ft_abi_ctx *, cl->i);
    st   = hmf_state(aTHX_ f);
    if (st == HMF_DONE) {
        AV  *vals = hmf_values_av(aTHX_ f);
        SV **rp   = (vals && av_len(vals) >= 0) ? av_fetch(vals, 0, 0) : NULL;
        SV  *res  = rp ? *rp : NULL;
        if (res && SvROK(res) && SvTYPE(SvRV(res)) == SVt_PVHV) {
            HV  *h = (HV *)SvRV(res);
            SV **e;
            ok = 1;
            if ((e = hv_fetchs(h, "status", 0))  && *e) status = (int)SvIV(*e);
            if ((e = hv_fetchs(h, "headers", 0)) && *e && SvROK(*e)
                && SvTYPE(SvRV(*e)) == SVt_PVAV) headers = (AV *)SvRV(*e);
            if ((e = hv_fetchs(h, "content", 0)) && *e) body = *e;
        }
    } else if (st == HMF_FAILED) {
        AV  *vals = hmf_values_av(aTHX_ f);
        SV **e    = (vals && av_len(vals) >= 0) ? av_fetch(vals, 0, 0) : NULL;
        err = e ? *e : NULL;
    }
    val = ctx->map(aTHX_ ok, status, headers, body, err, ctx->ud);
    if (!val) val = newSV(0);
    hmf_settle(aTHX_ next, HMF_DONE, &val, 1);
    SvREFCNT_dec(val);
    Safefree(ctx);
    XSRETURN_EMPTY;
}

static SV *ft_abi_request(pTHX_ SV *ua_sv, const char *method, const char *url,
                          const fetch_hdr *hdrs, int nhdrs,
                          const char *body, STRLEN blen,
                          double timeout, int max_redirects,
                          fetch_map_cb map, void *ud) {
    ft_ua      *ua  = ft_ua_of(aTHX_ ua_sv);
    HV         *opt = newHV();
    SV         *f, *next, *cb;
    ft_abi_ctx *ctx;
    if (nhdrs > 0 && hdrs) {
        AV *hav = newAV();
        int i;
        for (i = 0; i < nhdrs; i++) {
            av_push(hav, newSVpvn(hdrs[i].name, hdrs[i].nlen));
            av_push(hav, newSVpvn(hdrs[i].val,  hdrs[i].vlen));
        }
        (void)hv_stores(opt, "headers", newRV_noinc((SV *)hav));
    }
    if (body)         (void)hv_stores(opt, "body",    newSVpvn(body, blen));
    if (timeout > 0)  (void)hv_stores(opt, "timeout", newSVnv(timeout));

    f = ft_follow(aTHX_ ua_sv, ua, method, url, opt,
                  max_redirects < 0 ? ua->max_redirects : (IV)max_redirects);
    SvREFCNT_dec((SV *)opt);

    next = hmf_new(aTHX_ hmf_class_of(aTHX_ f));
    Newxz(ctx, 1, ft_abi_ctx);
    ctx->map = map;
    ctx->ud  = ud;
    hmf_set_upstream(aTHX_ next, f);
    cb = hm_closure(aTHX_ ft_abi_complete_cb, next, NULL, NULL, NULL,
                    PTR2IV(ctx), 0);
    hmf_on_ready(aTHX_ f, cb);
    SvREFCNT_dec(cb);
    SvREFCNT_dec(f);                    /* the request keeps f alive */
    return next;
}

static void ft_abi_res_parts(pTHX_ SV *res, int *status, AV **headers,
                             SV **body) {
    HV  *h;
    SV **e;
    if (status)  *status  = 0;
    if (headers) *headers = NULL;
    if (body)    *body    = NULL;
    if (!res || !SvROK(res) || SvTYPE(SvRV(res)) != SVt_PVHV) return;
    h = (HV *)SvRV(res);
    if (status  && (e = hv_fetchs(h, "status", 0))  && *e) *status = (int)SvIV(*e);
    if (headers && (e = hv_fetchs(h, "headers", 0)) && *e && SvROK(*e)
        && SvTYPE(SvRV(*e)) == SVt_PVAV) *headers = (AV *)SvRV(*e);
    if (body    && (e = hv_fetchs(h, "content", 0)) && *e) *body = *e;
}

/* ---- streaming: wrap the consumer's C callbacks as Fetch's coderefs ------ */

typedef struct ft_abi_sctx {
    fetch_on_headers on_headers;
    fetch_on_body    on_body;
    fetch_on_done    on_done;
    void            *ud;
} ft_abi_sctx;

XS_INTERNAL(ft_abi_hdr_tramp);
XS_INTERNAL(ft_abi_hdr_tramp) {
    dXSARGS;
    hm_clos     *cl = hm_clos_of(aTHX_ cv);
    ft_abi_sctx *c  = cl ? INT2PTR(ft_abi_sctx *, cl->i) : NULL;
    int status = 0;
    AV *headers = NULL;
    if (c && c->on_headers) {
        if (items >= 1 && SvOK(ST(0))) status = (int)SvIV(ST(0));
        if (items >= 2 && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVAV)
            headers = (AV *)SvRV(ST(1));
        c->on_headers(aTHX_ status, headers, c->ud);
    }
    XSRETURN_EMPTY;
}

XS_INTERNAL(ft_abi_body_tramp);
XS_INTERNAL(ft_abi_body_tramp) {
    dXSARGS;
    hm_clos     *cl = hm_clos_of(aTHX_ cv);
    ft_abi_sctx *c  = cl ? INT2PTR(ft_abi_sctx *, cl->i) : NULL;
    if (c && c->on_body && items >= 1) {
        STRLEN l;
        const char *p = SvPV_const(ST(0), l);
        c->on_body(aTHX_ p, l, c->ud);
    }
    XSRETURN_EMPTY;
}

XS_INTERNAL(ft_abi_done_tramp);
XS_INTERNAL(ft_abi_done_tramp) {
    dXSARGS;
    hm_clos     *cl = hm_clos_of(aTHX_ cv);
    ft_abi_sctx *c  = cl ? INT2PTR(ft_abi_sctx *, cl->i) : NULL;
    SV  *f  = items >= 1 ? ST(0) : NULL;
    int  ok = 0;
    SV  *err = NULL;
    if (c) {
        IV st = f ? hmf_state(aTHX_ f) : HMF_FAILED;
        if (st == HMF_DONE) ok = 1;
        else if (st == HMF_FAILED) {
            AV  *v = f ? hmf_values_av(aTHX_ f) : NULL;
            SV **e = (v && av_len(v) >= 0) ? av_fetch(v, 0, 0) : NULL;
            err = e ? *e : NULL;
        }
        if (c->on_done) c->on_done(aTHX_ ok, err, c->ud);
        Safefree(c);                 /* last callback: release the context */
    }
    XSRETURN_EMPTY;
}

static SV *ft_abi_request_stream(pTHX_ SV *ua_sv, const char *method,
                                 const char *url, const fetch_hdr *hdrs,
                                 int nhdrs, const char *body, STRLEN blen,
                                 double timeout, int max_redirects,
                                 fetch_on_headers on_h, fetch_on_body on_b,
                                 fetch_on_done on_d, void *ud) {
    ft_ua       *ua  = ft_ua_of(aTHX_ ua_sv);
    HV          *opt = newHV();
    ft_abi_sctx *ctx;
    SV          *f, *hcb, *bcb, *dcb;
    if (nhdrs > 0 && hdrs) {
        AV *hav = newAV();
        int i;
        for (i = 0; i < nhdrs; i++) {
            av_push(hav, newSVpvn(hdrs[i].name, hdrs[i].nlen));
            av_push(hav, newSVpvn(hdrs[i].val,  hdrs[i].vlen));
        }
        (void)hv_stores(opt, "headers", newRV_noinc((SV *)hav));
    }
    if (body)        (void)hv_stores(opt, "body",    newSVpvn(body, blen));
    if (timeout > 0) (void)hv_stores(opt, "timeout", newSVnv(timeout));

    Newxz(ctx, 1, ft_abi_sctx);
    ctx->on_headers = on_h; ctx->on_body = on_b; ctx->on_done = on_d; ctx->ud = ud;
    hcb = hm_closure(aTHX_ ft_abi_hdr_tramp,  NULL, NULL, NULL, NULL, PTR2IV(ctx), 0);
    bcb = hm_closure(aTHX_ ft_abi_body_tramp, NULL, NULL, NULL, NULL, PTR2IV(ctx), 0);
    (void)hv_stores(opt, "on_headers", hcb);   /* hash takes the ref */
    (void)hv_stores(opt, "on_body",    bcb);

    f = ft_follow(aTHX_ ua_sv, ua, method, url, opt,
                  max_redirects < 0 ? ua->max_redirects : (IV)max_redirects);
    SvREFCNT_dec((SV *)opt);

    dcb = hm_closure(aTHX_ ft_abi_done_tramp, NULL, NULL, NULL, NULL, PTR2IV(ctx), 0);
    hmf_on_ready(aTHX_ f, dcb);
    SvREFCNT_dec(dcb);
    return f;                                  /* +1 owned by caller */
}

/* ---- raw blocking upstream connection (for a proxy's Upgrade tunnel) ----- *
 * A plain or TLS TCP connection Fetch owns, exposed for blocking read/write/
 * splice from C. TLS reuses Fetch's client SSL_CTX (SNI, optional verify), so
 * a consumer tunnels to a wss/https upstream without linking OpenSSL itself.
 * Pure C (no pTHX): usable directly in a consumer's splice loop. */
typedef struct ft_rawconn { int fd; void *ssl; } ft_rawconn;

static void *ft_abi_tunnel_connect(const char *host, int port, int tls, int verify) {
    struct addrinfo hints, *ai = NULL, *it;
    char portbuf[16];
    int fd = -1;
    ft_rawconn *rc;
    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_UNSPEC; hints.ai_socktype = SOCK_STREAM;
    snprintf(portbuf, sizeof portbuf, "%d", port);
    if (getaddrinfo(host, portbuf, &hints, &ai) != 0) return NULL;
    for (it = ai; it; it = it->ai_next) {
        fd = ft_os_socket(it->ai_family, it->ai_socktype, it->ai_protocol);
        if (fd < 0) continue;
        if (ft_os_connect(fd, it->ai_addr, (int)it->ai_addrlen) == 0) break;
        ft_os_close(fd); fd = -1;
    }
    freeaddrinfo(ai);
    if (fd < 0) return NULL;
    rc = (ft_rawconn *)calloc(1, sizeof(ft_rawconn));
    if (!rc) { ft_os_close(fd); return NULL; }
    rc->fd = fd; rc->ssl = NULL;
    if (tls) {
#if FT_TLS_AVAILABLE
        SSL_CTX *ctx = ft_client_ctx(verify);
        SSL *ssl;
        if (!ctx || !(ssl = SSL_new(ctx))) { ft_os_close(fd); free(rc); return NULL; }
        SSL_set_fd(ssl, FT_SSL_FD(fd));
        SSL_set_connect_state(ssl);
#ifdef SSL_set_tlsext_host_name
        SSL_set_tlsext_host_name(ssl, host);
#endif
        if (verify) {
            SSL_set1_host(ssl, host);
            SSL_set_hostflags(ssl, X509_CHECK_FLAG_NO_PARTIAL_WILDCARDS);
        }
        if (SSL_connect(ssl) != 1) { SSL_free(ssl); ft_os_close(fd); free(rc); return NULL; }
        rc->ssl = ssl;
#else
        ft_os_close(fd); free(rc); return NULL;      /* TLS asked for, unavailable */
#endif
    }
    return rc;
}

static int ft_abi_tunnel_fd(void *h) { return h ? ((ft_rawconn *)h)->fd : -1; }

static IV ft_abi_tunnel_read(void *h, char *buf, IV len) {
    ft_rawconn *rc = (ft_rawconn *)h;
    if (!rc) return -1;
#if FT_TLS_AVAILABLE
    if (rc->ssl) {
        int r = SSL_read((SSL *)rc->ssl, buf, (int)(len > INT_MAX ? INT_MAX : len));
        if (r > 0) return r;
        return (SSL_get_error((SSL *)rc->ssl, r) == SSL_ERROR_ZERO_RETURN) ? 0 : -1;
    }
#endif
    { ssize_t r; do { r = ft_os_recv(rc->fd, buf, (size_t)len, 0); }
      while (r < 0 && errno == EINTR); return (IV)r; }
}

static IV ft_abi_tunnel_write_all(void *h, const char *buf, IV len) {
    ft_rawconn *rc = (ft_rawconn *)h;
    IV off = 0;
    if (!rc) return -1;
    while (off < len) {
#if FT_TLS_AVAILABLE
        if (rc->ssl) {
            int w = SSL_write((SSL *)rc->ssl, buf + off,
                              (int)((len - off) > INT_MAX ? INT_MAX : (len - off)));
            if (w <= 0) return -1;
            off += w; continue;
        }
#endif
        { ssize_t w = ft_os_send(rc->fd, buf + off, (size_t)(len - off), 0);
          if (w < 0) { if (errno == EINTR) continue; return -1; }
          if (w == 0) return -1;
          off += w; }
    }
    return 0;
}

static int ft_abi_tunnel_pending(void *h) {
    ft_rawconn *rc = (ft_rawconn *)h;
#if FT_TLS_AVAILABLE
    if (rc && rc->ssl) return SSL_pending((SSL *)rc->ssl);
#endif
    (void)rc; return 0;
}

static void ft_abi_tunnel_close(void *h) {
    ft_rawconn *rc = (ft_rawconn *)h;
    if (!rc) return;
#if FT_TLS_AVAILABLE
    if (rc->ssl) SSL_free((SSL *)rc->ssl);
#endif
    if (rc->fd >= 0) ft_os_close(rc->fd);
    free(rc);
}

static const fetch_abi FETCH_ABI = {
    FETCH_ABI_VERSION,
    ft_abi_ua_new,
    ft_abi_request,
    ft_abi_res_parts,
    ft_abi_request_stream,
    ft_abi_tunnel_connect,
    ft_abi_tunnel_fd,
    ft_abi_tunnel_read,
    ft_abi_tunnel_write_all,
    ft_abi_tunnel_pending,
    ft_abi_tunnel_close,
};

#endif /* FT_ABI_H */
