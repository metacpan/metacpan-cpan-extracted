MODULE = Hyperman		PACKAGE = Hyperman

PROTOTYPES: DISABLE

BOOT:
    hm_fq = newAV();

# Run the server. Key/value options as documented in Hyperman.pm:
# app (required), host, port (scalar or arrayref), listen (arrayref of
# per-listener hashrefs), workers, idle_timeout, header_timeout, max_pipeline,
# reuseport, access_log, max_requests_per_worker, shutdown_grace, affinity,
# http2, tls_*, redirect_https.
void
run(class, ...)
    SV *class
    CODE:
    {
        hm_worker_cfg cfg;
        hm_listener_spec dfl;     /* top-level defaults, seeded into each spec */
        SV *port_sv = NULL, *listen_sv = NULL;
        int i;
        PERL_UNUSED_VAR(class);

        if ((items - 1) % 2)
            croak("Hyperman->run: odd number of options");

        memset(&cfg, 0, sizeof(cfg));
        cfg.log_fd = -1;
        memset(&dfl, 0, sizeof(dfl));
        dfl.host = "0.0.0.0";
        dfl.port = 8080;

        for (i = 1; i + 1 < items; i += 2) {
            const char *key = SvPV_nolen(ST(i));
            SV *val = ST(i + 1);
            if (strEQ(key, "app"))                 cfg.app = val;
            else if (strEQ(key, "host"))           { if (SvOK(val)) dfl.host = SvPV_nolen(val); }
            else if (strEQ(key, "port"))           port_sv = val;
            else if (strEQ(key, "listen"))         listen_sv = SvOK(val) ? val : NULL;
            else if (strEQ(key, "workers"))        cfg.nworkers = (int)SvIV(val);
            else if (strEQ(key, "idle_timeout"))   cfg.idle_t = SvNV(val);
            else if (strEQ(key, "header_timeout")) cfg.header_t = SvNV(val);
            else if (strEQ(key, "max_pipeline"))   cfg.max_pipe = (int)SvIV(val);
            else if (strEQ(key, "reuseport"))      cfg.reuseport = SvTRUE(val) ? 1 : 0;
            else if (strEQ(key, "deny"))           { if (SvOK(val) && SvROK(val)) cfg.deny = val; }
            else if (strEQ(key, "deny_capacity"))  cfg.deny_cap = (unsigned)SvUV(val);
            else if (strEQ(key, "rate_capacity"))  cfg.rate_cap = (unsigned)SvUV(val);
            else if (strEQ(key, "access_log")) {
                /* coderef -> per-request Perl callback (as before);
                 * a filehandle or a path -> fast C-side Combined-log writer. */
                if (!SvOK(val)) {
                    cfg.log_cb = NULL;
                } else if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV) {
                    cfg.log_cb = val;
                } else {
                    SV *g = (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVGV)
                            ? SvRV(val) : val;
                    if (SvTYPE(g) == SVt_PVGV) {
                        IO     *io = GvIO((GV *)g);
                        PerlIO *fp = io ? (IoOFP(io) ? IoOFP(io) : IoIFP(io)) : NULL;
                        int raw = fp ? PerlIO_fileno(fp) : -1;
                        if (raw < 0)
                            croak("Hyperman->run: access_log handle has no fileno");
                        cfg.log_fd = dup(raw);   /* own it; freed with the loop */
                        if (cfg.log_fd < 0)
                            croak("Hyperman->run: dup access_log fd: %s",
                                  strerror(errno));
                    } else {
                        cfg.log_path = SvPV_nolen(val);   /* opened in the parent */
                    }
                }
            }
            else if (strEQ(key, "max_requests_per_worker"))
                                                   cfg.max_requests = SvUV(val);
            /* Response compression. Off by default: a server that starts
             * compressing on upgrade is a surprise. Accepted and inert on a
             * build without zlib, so a config is portable across them. */
            else if (strEQ(key, "compress"))       cfg.compress = SvTRUE(val) ? 1 : 0;
            else if (strEQ(key, "compress_min_length"))
                                                   cfg.compress_min = (size_t)SvUV(val);
            /* The request ceiling: headers plus body, buffered per
             * connection before the app is called. This is the only thing
             * bounding a worker's memory against a large POST, so 0 is
             * REFUSED rather than read as "unlimited" - an unbounded read
             * ceiling is a memory-exhaustion switch and must not be
             * reachable by a config typo that produces a falsy value. */
            else if (strEQ(key, "max_body")) {
                UV n = SvUV(val);
                if (!n)
                    croak("Hyperman->run: max_body must be a byte count - "
                          "0 would mean an unbounded request buffer, which "
                          "is a memory-exhaustion switch, not a setting");
                cfg.max_read = (size_t)n;
            }
            else if (strEQ(key, "compress_level")) {
                IV lv = SvIV(val);
                if (lv < 1 || lv > 9)
                    croak("Hyperman->run: compress_level must be 1..9");
                cfg.compress_level = (int)lv;
            }
            else if (strEQ(key, "shutdown_grace")) cfg.grace = SvNV(val);
            else if (strEQ(key, "affinity"))       cfg.affinity = SvTRUE(val) ? 1 : 0;
            else if (strEQ(key, "http2"))          dfl.http2 = SvTRUE(val) ? 1 : 0;
            else if (strEQ(key, "tls_cert"))       dfl.tls_cert = SvOK(val) ? SvPV_nolen(val) : NULL;
            else if (strEQ(key, "tls_key"))        dfl.tls_key  = SvOK(val) ? SvPV_nolen(val) : NULL;
            else if (strEQ(key, "tls_ca"))         dfl.tls_ca   = SvOK(val) ? SvPV_nolen(val) : NULL;
            else if (strEQ(key, "tls_sni"))        dfl.tls_sni  = SvOK(val) ? val : NULL;
            else if (strEQ(key, "redirect_https")) dfl.redirect_https = (int)SvIV(val);
            else if (strEQ(key, "tls_verify")) {
                const char *m = SvPV_nolen(val);
                if      (strEQ(m, "require"))  dfl.tls_verify = 2;
                else if (strEQ(m, "optional")) dfl.tls_verify = 1;
                else if (strEQ(m, "none"))     dfl.tls_verify = 0;
                else croak("Hyperman->run: tls_verify must be none/optional/require");
            }
            else croak("Hyperman->run: unknown option '%s'", key);
        }
        if (!(cfg.app && SvROK(cfg.app) && SvTYPE(SvRV(cfg.app)) == SVt_PVCV))
            croak("Hyperman->run: 'app' is required");
        if (dfl.redirect_https == 1) dfl.redirect_https = 443;

        /* Build the listener specs. Three shapes, most specific wins:
         *   listen => [ {..}, .. ]  - full per-listener control (incl. TLS)
         *   port   => [ N, M ]      - several plain listeners sharing defaults
         *   port   => N (or unset)  - one listener from the top-level options  */
        {
            hm_listener_spec *ls;
            int n, j;
            AV *lav = (listen_sv && SvROK(listen_sv)
                       && SvTYPE(SvRV(listen_sv)) == SVt_PVAV)
                      ? (AV *)SvRV(listen_sv) : NULL;
            AV *pav = (port_sv && SvROK(port_sv)
                       && SvTYPE(SvRV(port_sv)) == SVt_PVAV)
                      ? (AV *)SvRV(port_sv) : NULL;

            if (listen_sv && !lav)
                croak("Hyperman->run: 'listen' must be an arrayref of hashrefs");

            n = lav ? (int)(av_len(lav) + 1)
              : pav ? (int)(av_len(pav) + 1)
              : 1;
            if (n < 1) croak("Hyperman->run: 'listen'/'port' is empty");
            ls = (hm_listener_spec *)hm_xcalloc(n, sizeof(hm_listener_spec));

            for (j = 0; j < n; j++) {
                ls[j] = dfl;                       /* seed with top-level defaults */
                if (lav) {
                    SV **e = av_fetch(lav, j, 0);
                    if (!(e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVHV))
                        croak("Hyperman->run: listen[%d] must be a hashref", j);
                    hm_listener_from_hv(aTHX_ (HV *)SvRV(*e), &ls[j]);
                } else if (pav) {
                    SV **e = av_fetch(pav, j, 0);
                    if (e) ls[j].port = (int)SvIV(*e);
                } else if (port_sv && SvOK(port_sv)) {
                    ls[j].port = (int)SvIV(port_sv);
                }
                hm_check_listener(aTHX_ &ls[j]);
            }

            cfg.lspecs  = ls;
            cfg.nlspecs = n;
            hm_run_server(aTHX_ &cfg);   /* normally blocks until shutdown */
            free(ls);
        }
    }

# A Future resolved after $secs by the worker loop's timer watcher.
SV *
timer(class, secs)
    SV *class
    double secs
    CODE:
    {
        hm_loop *loop = hm_need_loop();
        SV *f = hmf_new(aTHX_ "Hyperman::Future");
        PERL_UNUSED_VAR(class);
        hm_add_timer_watch(aTHX_ loop, secs, f, HM_TW_FUTURE);
        RETVAL = f;
    }
    OUTPUT:
        RETVAL

# A Future resolved when $fh becomes readable ('r') or writable ('w'),
# so an app can do non-blocking I/O integrated with the worker's loop.
SV *
io_ready(class, fh, ...)
    SV *class
    SV *fh
    CODE:
    {
        hm_loop *loop = hm_need_loop();
        const char *mode = (items > 2 && SvOK(ST(2))) ? SvPV_nolen(ST(2)) : "r";
        SV *f = hmf_new(aTHX_ "Hyperman::Future");
        PERL_UNUSED_VAR(class);
        hm_add_io_watch(aTHX_ loop, hm_fd_of(aTHX_ fh), mode, f, 0);
        RETVAL = f;
    }
    OUTPUT:
        RETVAL

# Per-worker stats: requests/accepts/bytes_out/connections/backend/pid.
SV *
stats(...)
    CODE:
        PERL_UNUSED_VAR(items);
        if (!hm_cur_loop) {
            RETVAL = &PL_sv_undef;
        } else {
            HV *h = newHV();
            hv_stores(h, "requests",    newSVuv(hm_cur_loop->requests));
            hv_stores(h, "accepts",     newSVuv(hm_cur_loop->accepts));
            hv_stores(h, "denied",      newSVuv(hm_cur_loop->denied));
            hv_stores(h, "bytes_out",   newSVuv(hm_cur_loop->bytes_out));
            hv_stores(h, "connections", newSViv(hm_cur_loop->nconns));
            hv_stores(h, "backend",     newSVpv(hm_cur_loop->be->name, 0));
            hv_stores(h, "pid",         newSViv((IV)hm_os_getpid()));
            RETVAL = newRV_noinc((SV *)h);
        }
    OUTPUT:
        RETVAL

# True when HTTP/2 (h2c) support was built in (nghttp2 present).
int
has_http2(...)
    CODE:
        PERL_UNUSED_VAR(items);
        RETVAL = hm_h2_available();
    OUTPUT:
        RETVAL

# _accepts_gzip($header): the Accept-Encoding walk alone, for
# t/30-compress-accept.t. Author-facing, not documented.
int
_accepts_gzip(hdr)
        SV *hdr
    CODE:
    {
        STRLEN l = 0;
        const char *h = SvOK(hdr) ? SvPV_const(hdr, l) : NULL;
        RETVAL = hz_accepts_gzip(h, (size_t)l);
    }
    OUTPUT:
        RETVAL

# _gzip($bytes): the compressor alone, for t/31-compress.t - returns the
# gzip member, or undef without zlib or when the result would not be
# smaller. Author-facing, not documented.
SV *
_gzip(bytes)
        SV *bytes
    CODE:
    {
        STRLEN l = 0;
        const char *b = SvOK(bytes) ? SvPV_const(bytes, l) : NULL;
        char *out = NULL;
        size_t ol = 0;
        if (b && hz_gzip(b, (size_t)l, HZ_LEVEL, &out, &ol)) {
            RETVAL = newSVpvn(out, ol);
            Safefree(out);
        } else {
            RETVAL = newSV(0);
        }
    }
    OUTPUT:
        RETVAL

# True when response compression was built in (zlib present). Without it
# `compress => 1` is accepted and inert, so this is how a test skips
# honestly rather than guessing.
int
has_compression(...)
    CODE:
        PERL_UNUSED_VAR(items);
        RETVAL = hz_available();
    OUTPUT:
        RETVAL

# True when TLS/HTTPS support was built in (OpenSSL present).
int
has_tls(...)
    CODE:
        PERL_UNUSED_VAR(items);
        RETVAL = hm_tls_available();
    OUTPUT:
        RETVAL

# The runtime TLS library banner ("OpenSSL 3.0.13 30 Jan 2024",
# "LibreSSL 3.8.2"), or undef when TLS support was not built. The two
# stacks agree on the API but not on behaviour - LibreSSL has no TLS 1.3
# session resumption, for one - and this is how a caller tells them apart.
SV *
tls_library(...)
    PREINIT:
        const char *s;
    CODE:
        PERL_UNUSED_VAR(items);
        s = hm_tls_library();
        RETVAL = s ? newSVpv(s, 0) : newSV(0);
    OUTPUT:
        RETVAL

# Hyperman->tls_reload(\%sni) - replace this worker's TLS certificates
# without replacing the process.
#
# The context a listener serves is built once, in the parent, before the
# fork - so a certificate that arrives afterwards is not served until the
# process is restarted, and SIGHUP does not help because it re-forks from
# that same parent. This is the way to pick one up: called from inside a
# worker, it rebuilds that worker's contexts from the map given, on that
# worker's own loop, without unbinding anything.
#
# The map is the same shape `run` takes: { host => { cert => ..., key =>
# ... } }, paths not PEM bytes. Returns the number of listeners rebuilt -
# 0 outside a worker, 0 on a plain-only server, and 0 if the default
# certificate would not load, in which case what was being served still
# is.
int
tls_reload(class, sni = &PL_sv_undef)
    SV *class
    SV *sni
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = hm_cur_loop ? hm_tls_reload(aTHX_ hm_cur_loop, sni) : 0;
    OUTPUT:
        RETVAL

# The current worker's loop, or undef outside a running loop.
SV *
loop(...)
    CODE:
        PERL_UNUSED_VAR(items);
        if (hm_cur_loop) RETVAL = hm_loop_to_sv(aTHX_ hm_cur_loop);
        else             RETVAL = &PL_sv_undef;
    OUTPUT:
        RETVAL

# Hyperman::detach($env) - take this request's socket over for a protocol
# upgrade (WebSocket). Returns the client fd, now owned by the caller: the
# server has stopped watching it, forgotten the connection and will not
# close it. Watch it on psgix.loop, and close it when done.
IV
detach(env)
        SV *env
    CODE:
    {
        HV *ehv;
        SV **e;
        AV *cid;
        SV **fsv, **isv;
        int fd, rc;
        UV id;
        if (!hm_cur_loop)
            croak("Hyperman::detach: no running loop (call it from inside "
                  "a request)");
        if (!SvROK(env) || SvTYPE(SvRV(env)) != SVt_PVHV)
            croak("Hyperman::detach: give it the PSGI env hashref");
        ehv = (HV *)SvRV(env);
        e = hv_fetchs(ehv, "psgix.hyperman.conn", 0);
        if (!(e && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVAV))
            croak("Hyperman::detach: no psgix.hyperman.conn in this env "
                  "(HTTP/2 streams and non-Hyperman servers cannot detach)");
        cid = (AV *)SvRV(*e);
        fsv = av_fetch(cid, 0, 0);
        isv = av_fetch(cid, 1, 0);
        if (!(fsv && *fsv && isv && *isv))
            croak("Hyperman::detach: malformed psgix.hyperman.conn");
        fd = (int)SvIV(*fsv);
        id = SvUV(*isv);
        rc = hm_detach(aTHX_ hm_cur_loop, fd, id);
        switch (rc) {
            case  0: break;
            case -1: croak("Hyperman::detach: the connection is gone "
                           "(the client hung up, or this env is stale)");
            case -2: croak("Hyperman::detach: HTTP/2 connections cannot be "
                           "detached (streams share one socket)");
            case -3: croak("Hyperman::detach: TLS connections cannot be "
                           "detached (terminate TLS in front of Hyperman)");
            case -4: croak("Hyperman::detach: a response is still draining "
                           "on this connection");
            case -5: croak("Hyperman::detach: already detached");
            case -6: croak("Hyperman::detach: not supported on this "
                           "platform (it needs fork-style fd ownership)");
            default: croak("Hyperman::detach: failed (%d)", rc);
        }
        RETVAL = (IV)fd;
    }
    OUTPUT:
        RETVAL
