MODULE = Hyperman		PACKAGE = Hyperman

PROTOTYPES: DISABLE

BOOT:
    hm_fq = newAV();

# Run the server. Key/value options as documented in Hyperman.pm:
# app (required), host, port, workers, idle_timeout, header_timeout,
# max_pipeline, reuseport, access_log, max_requests_per_worker,
# shutdown_grace, affinity.
void
run(class, ...)
    SV *class
    CODE:
    {
        hm_worker_cfg cfg;
        SV *host_sv = NULL, *cert_sv = NULL, *key_sv = NULL;
        int i;
        PERL_UNUSED_VAR(class);

        if ((items - 1) % 2)
            croak("Hyperman->run: odd number of options");

        memset(&cfg, 0, sizeof(cfg));
        cfg.host = "0.0.0.0";
        cfg.port = 8080;
        cfg.log_fd = -1;

        for (i = 1; i + 1 < items; i += 2) {
            const char *key = SvPV_nolen(ST(i));
            SV *val = ST(i + 1);
            if (strEQ(key, "app"))                 cfg.app = val;
            else if (strEQ(key, "host"))           { host_sv = val; }
            else if (strEQ(key, "port"))           cfg.port = (int)SvIV(val);
            else if (strEQ(key, "workers"))        cfg.nworkers = (int)SvIV(val);
            else if (strEQ(key, "idle_timeout"))   cfg.idle_t = SvNV(val);
            else if (strEQ(key, "header_timeout")) cfg.header_t = SvNV(val);
            else if (strEQ(key, "max_pipeline"))   cfg.max_pipe = (int)SvIV(val);
            else if (strEQ(key, "reuseport"))      cfg.reuseport = SvTRUE(val) ? 1 : 0;
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
            else if (strEQ(key, "shutdown_grace")) cfg.grace = SvNV(val);
            else if (strEQ(key, "affinity"))       cfg.affinity = SvTRUE(val) ? 1 : 0;
            else if (strEQ(key, "http2"))          cfg.http2 = SvTRUE(val) ? 1 : 0;
            else if (strEQ(key, "tls_cert"))       cert_sv = SvOK(val) ? val : NULL;
            else if (strEQ(key, "tls_key"))        key_sv  = SvOK(val) ? val : NULL;
            else if (strEQ(key, "tls_ca"))
                cfg.tls_ca = SvOK(val) ? SvPV_nolen(val) : NULL;
            else if (strEQ(key, "tls_sni"))        cfg.tls_sni = SvOK(val) ? val : NULL;
            else if (strEQ(key, "tls_verify")) {
                const char *m = SvPV_nolen(val);
                if      (strEQ(m, "require"))  cfg.tls_verify = 2;
                else if (strEQ(m, "optional")) cfg.tls_verify = 1;
                else if (strEQ(m, "none"))     cfg.tls_verify = 0;
                else croak("Hyperman->run: tls_verify must be none/optional/require");
            }
            else croak("Hyperman->run: unknown option '%s'", key);
        }
        if (!(cfg.app && SvROK(cfg.app) && SvTYPE(SvRV(cfg.app)) == SVt_PVCV))
            croak("Hyperman->run: 'app' is required");
        if (host_sv && SvOK(host_sv)) cfg.host = SvPV_nolen(host_sv);
        if (cfg.http2 && !hm_h2_available())
            croak("Hyperman->run: http2 requested but nghttp2 support was not "
                  "built (install libnghttp2-dev and reinstall Hyperman)");
        if (cert_sv || key_sv || cfg.tls_ca || cfg.tls_sni || cfg.tls_verify) {
            if (!(cert_sv && key_sv))
                croak("Hyperman->run: tls_cert and tls_key must be given together");
            if (!hm_tls_available())
                croak("Hyperman->run: TLS requested but OpenSSL support was not "
                      "built (install libssl-dev and reinstall Hyperman)");
            if (cfg.tls_verify && !cfg.tls_ca)
                croak("Hyperman->run: tls_verify needs tls_ca (the CA to verify "
                      "client certificates against)");
            cfg.tls_cert = SvPV_nolen(cert_sv);
            cfg.tls_key  = SvPV_nolen(key_sv);
        }

        hm_run_server(aTHX_ &cfg);
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
            hv_stores(h, "bytes_out",   newSVuv(hm_cur_loop->bytes_out));
            hv_stores(h, "connections", newSViv(hm_cur_loop->nconns));
            hv_stores(h, "backend",     newSVpv(hm_cur_loop->be->name, 0));
            hv_stores(h, "pid",         newSViv((IV)getpid()));
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

# True when TLS/HTTPS support was built in (OpenSSL present).
int
has_tls(...)
    CODE:
        PERL_UNUSED_VAR(items);
        RETVAL = hm_tls_available();
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
