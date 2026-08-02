MODULE = Fetch		PACKAGE = Fetch

PROTOTYPES: DISABLE

# ---- user agent ----------------------------------------------------------

# Fetch->new(%args): loop, headers, agent, tls_verify, max_redirects, timeout,
# keep_alive, cookie_jar, pool_size. The object is a blessed IV over an ft_ua.
SV *
new(class, ...)
    SV *class
    CODE:
    {
        const char *cls = (SvROK(class) && SvOBJECT(SvRV(class)))
                        ? HvNAME(SvSTASH(SvRV(class))) : SvPV_nolen(class);
        ft_ua *ua;
        SV *loop_arg = NULL, *headers_arg = NULL, *agent_arg = NULL, *jar_arg = NULL;
        int have_keep = 0, keep = 1, have_verify = 0, verify = 1;
        int have_maxr = 0, maxr = 5, pool_size = 32, simple = 0;
        double timeout = 0.0;
        int i;
        for (i = 1; i + 1 < items; i += 2) {
            const char *k = SvPV_nolen(ST(i));
            SV *v = ST(i + 1);
            if      (strEQ(k, "loop"))          loop_arg = v;
            else if (strEQ(k, "headers"))       headers_arg = v;
            else if (strEQ(k, "agent"))         agent_arg = v;
            else if (strEQ(k, "cookie_jar"))    jar_arg = v;
            else if (strEQ(k, "keep_alive"))  { have_keep = 1;   keep = SvTRUE(v) ? 1 : 0; }
            else if (strEQ(k, "tls_verify"))  { have_verify = 1; verify = SvTRUE(v) ? 1 : 0; }
            else if (strEQ(k, "max_redirects")){ have_maxr = 1;  maxr = (int)SvIV(v); }
            else if (strEQ(k, "timeout"))       timeout = SvNV(v);
            else if (strEQ(k, "pool_size"))     pool_size = (int)SvIV(v);
            else if (strEQ(k, "simple_response")) simple = SvTRUE(v) ? 1 : 0;
        }
        Newxz(ua, 1, ft_ua);
        ua->loop = ft_resolve_loop(aTHX_ loop_arg);
        if (ft_obj_can(aTHX_ ua->loop, "install_await")) {
            dSP;
            ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(ua->loop);
            PUTBACK;
            call_method("install_await", G_DISCARD);
            FREETMPS; LEAVE;
        }
        ua->keep_alive = have_keep ? keep : 1;
        ua->simple_response = simple;
        if (jar_arg && SvOK(jar_arg)) {
            if (SvROK(jar_arg))          ua->cookie_jar = SvREFCNT_inc(jar_arg);
            else if (SvTRUE(jar_arg))    ua->cookie_jar = ft_load_new(aTHX_ "Fetch::CookieJar", NULL);
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
            ua->agent = newSVpvf("Fetch/%s",
                                 (ver && SvOK(ver)) ? SvPV_nolen(ver) : "0");
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
        RETVAL = sv_bless(newRV_noinc(newSViv(PTR2IV(ua))),
                          gv_stashpv(cls, GV_ADD));
    }
    OUTPUT:
        RETVAL

void
DESTROY(self)
    SV *self
    CODE:
    {
        ft_ua *ua = ft_ua_of(aTHX_ self);
        if (ua) {
            /* Free the pool before the loop: parked connections stay armed for
             * READ (see ft_conn_park), so freeing them unwatches on the loop -
             * which must still be alive. A native loop's ft_loop* is owned by
             * ua->loop, so releasing it first would leave the pool's connections
             * unwatching a freed loop (use-after-free). */
            if (ua->pool)       SvREFCNT_dec(ua->pool);
            if (ua->loop)       SvREFCNT_dec(ua->loop);
            if (ua->headers)    SvREFCNT_dec(ua->headers);
            if (ua->agent)      SvREFCNT_dec(ua->agent);
            if (ua->cookie_jar) SvREFCNT_dec(ua->cookie_jar);
            Safefree(ua);
        }
    }

SV *
loop(self)
    SV *self
    CODE:
        RETVAL = newSVsv(ft_ua_of(aTHX_ self)->loop);
    OUTPUT:
        RETVAL

SV *
cookie_jar(self)
    SV *self
    CODE:
    {
        ft_ua *ua = ft_ua_of(aTHX_ self);
        RETVAL = (ua->cookie_jar && SvOK(ua->cookie_jar))
               ? newSVsv(ua->cookie_jar) : newSV(0);
    }
    OUTPUT:
        RETVAL

# $ua->request($method, $url, %opt) -> Fetch::Future
SV *
request(self, method, url, ...)
    SV         *self
    const char *method
    const char *url
    CODE:
        RETVAL = ft_dispatch(aTHX_ self, method, url, &ST(3), items - 3);
    OUTPUT:
        RETVAL

# verb helpers: $ua->get($url, %opt) etc.
SV *
get(self, url, ...)
    SV         *self
    const char *url
    ALIAS:
        head   = 1
        delete = 2
        post   = 3
        put    = 4
    CODE:
    {
        static const char *const M[5] = { "GET", "HEAD", "DELETE", "POST", "PUT" };
        RETVAL = ft_dispatch(aTHX_ self, M[ix], url, &ST(2), items - 2);
    }
    OUTPUT:
        RETVAL

# ---- introspection / internals ------------------------------------------

# True if built with OpenSSL (https support).
int
_tls_available()
    CODE:
        RETVAL = FT_TLS_AVAILABLE;
    OUTPUT:
        RETVAL

# True if built with nghttp2 (HTTP/2 support; needs TLS/ALPN too).
int
_h2_available()
    CODE:
        RETVAL = FT_H2_AVAILABLE;
    OUTPUT:
        RETVAL

# Start an HTTP/1.1 request on $loop to host:port with the pre-built request
# bytes; returns a pending Fetch::Future resolving to a Fetch::Response.
SV *
_request(loop, pool, host, port, req, tls, verify, timeout, method, scheme, authority, path, headers, body, on_body)
    SV         *loop
    SV         *pool
    const char *host
    const char *port
    SV         *req
    int         tls
    int         verify
    double      timeout
    SV         *method
    SV         *scheme
    SV         *authority
    SV         *path
    SV         *headers
    SV         *body
    SV         *on_body
    CODE:
    {
        /* A native Standalone loop is a blessed IV holding a ft_loop*; any
         * other object is a foreign adapter (IO::Async/AnyEvent/Hyperman)
         * whose _ft_arm method the C core calls to arm interest. */
        ft_loop    *l = NULL;
        SV         *lsv = NULL;
        ft_pool    *pl = ft_pool_from_sv(aTHX_ pool);
        STRLEN      len;
        const char *bytes;
        if (sv_isobject(loop) && sv_derived_from(loop, "Fetch::Loop::Standalone"))
            l = ft_loop_from_sv(aTHX_ loop);
        else
            lsv = loop;
        bytes = SvPV(req, len);
        RETVAL = ft_h1_start(aTHX_ l, lsv, pl, host, port, bytes, len, tls, verify,
                             timeout, method, scheme, authority, path, headers,
                             body, on_body, NULL);
    }
    OUTPUT:
        RETVAL

# Create a keep-alive connection pool (opaque handle); DESTROY frees it and
# every connection still parked in it.
SV *
_pool_new(max)
    int max
    CODE:
    {
        ft_pool *p = ft_pool_new(max);
        if (!p) croak("Fetch: out of memory");
        RETVAL = sv_bless(newRV_noinc(newSViv(PTR2IV(p))),
                          gv_stashpv("Fetch::_Pool", GV_ADD));
    }
    OUTPUT:
        RETVAL
