#ifndef HM_CORE_H
#define HM_CORE_H

/* Hyperman loop core: connections, HTTP parse and
 * serialize, PSGI dispatch (sync, streaming, Future), watchers, deferred
 * queue, timeouts/fairness, listener, workers, and the prefork supervisor.
 * Requires hm_future.h (futures + C closures) and hyperman.h (backends). */

#define HM_POOL_MAX     1024   /* pooled hm_conn structs kept per loop     */
#define HM_IOV_MAX      64     /* writev: header + up to 63 body chunks    */
#define HM_SWEEP_SECS   5.0    /* timeout sweep interval                    */

typedef struct hm_loop hm_loop;
typedef struct hm_conn hm_conn;

struct hm_conn {
    int      fd;
    char    *rbuf;          /* owned; grows for large bodies, capacity kept */
    size_t   rlen, rcap;
    char    *wbuf;          /* owned; capacity kept across requests */
    size_t   wlen, woff, wcap;
    int      writing;       /* write watcher armed?                 */
    int      keepalive;
    int      awaiting;      /* parked on a pending Future?          */
    UV       id;            /* generation id, guards fd reuse       */
    UV       nreqs;         /* requests served on this connection   */
    SV      *io_sv;         /* psgix.io: dup'd filehandle, per conn */
    SV      *resp_f;        /* pending response Future (awaiting)   */
    SV      *env_sv;        /* held while parked, for access_log    */
    void    *h2;            /* hm_h2_sess* when in HTTP/2 mode       */
    void    *ssl;           /* SSL* when this is a TLS connection    */
    void    *tls_peer;      /* hm_tls_peer* (cert/cipher for $env)   */
    unsigned char tls_hs;         /* TLS handshake in progress       */
    unsigned char tls_r_wants_w;  /* SSL_read blocked wanting write  */
    unsigned char tls_w_wants_r;  /* SSL_write blocked wanting read  */
    int      last_status;   /* last response status/bytes (logging) */
    size_t   last_blen;
    char     peer[INET6_ADDRSTRLEN];  /* REMOTE_ADDR, filled at accept    */
    time_t   last_active;
    time_t   req_start;     /* first byte of an incomplete request  */
    hm_conn *lru_prev, *lru_next;
    hm_conn *pool_next;
    hm_loop *loop;
};

/* app-owned fd watcher: a one-shot Future or a persistent callback */
typedef struct { SV *sv; unsigned char is_cb; } hm_iow;

/* timer watcher */
#define HM_TW_FUTURE 0
#define HM_TW_CB     1
#define HM_TW_SWEEP  2
#define HM_TW_HARDSTOP 3
typedef struct { int kind; SV *sv; hm_loop *loop; } hm_tw;

typedef struct { int fd; UV id; } hm_again;

struct hm_loop {
    hm_backend *be;
    hm_conn   **conns;              /* [HM_MAXFD] */
    hm_iow     *io_r, *io_w;        /* [HM_MAXFD] app io watchers */
    AV         *deferred;           /* run-soon callbacks          */
    hm_again   *again;              /* conns with buffered requests */
    int         again_n, again_cap;
    hm_conn    *lru_head, *lru_tail;
    hm_conn    *pool; int pool_n;
    hm_tw      *sweep_tw;
    SV         *app;                /* server: PSGI app coderef     */
    int         listen_fd;          /* server: -1 when not attached */
    int         port;
    int         nconns;
    int         stop;
    int         stopping;           /* graceful shutdown in progress */
    int         running;
    int         perl_owned;         /* created via Hyperman::Loop->new */
    time_t      now;
    double      idle_timeout;
    double      header_timeout;
    int         max_pipeline;       /* fairness: requests per conn per wakeup */
    size_t      max_read;           /* request size ceiling (headers + body) */
    char       *host;               /* bind host, for SERVER_NAME */
    SV         *self_sv;            /* cached psgix.loop wrapper */
    SV         *log_cb;             /* access_log coderef, or NULL */
    int         log_fd;             /* fast access-log fd (C writer), or -1 */
    char       *log_buf;            /* pending Combined-format log lines    */
    size_t      log_len, log_cap;
    time_t      log_ts_sec;         /* second the cached stamp below is for  */
    char        log_ts[32];         /* "dd/Mon/YYYY:HH:MM:SS +ZZZZ", 1Hz     */
    UV          requests;           /* requests dispatched (stats)  */
    UV          accepts;            /* connections accepted (stats) */
    UV          bytes_out;          /* response bytes queued (stats) */
    UV          max_requests;       /* recycle worker after N (0=off) */
    int         recycle_pending;    /* max_requests hit; drain at loop top */
    double      shutdown_grace;     /* graceful-drain bound (secs)   */
    hm_tw      *hardstop_tw;
    int         http2;              /* enable HTTP/2 (h2c) detection */
    void       *tls_ctx;            /* SSL_CTX* when serving HTTPS    */
};

static SV      *hm_empty_input;     /* shared empty psgi.input */
static pid_t    hm_children[1024];
static time_t   hm_child_start[1024];
static int      hm_nchildren = 0;
static UV       hm_id_counter = 0;

static SV *hm_loop_to_sv(pTHX_ hm_loop *loop);
static void hm_on_signal(pTHX_ hm_loop *loop);
static void hm_deliver(pTHX_ int fd, UV id, SV *resp);
static int hm_flush(pTHX_ hm_conn *c);
static void hm_process(pTHX_ hm_conn *c);
static int hm_queue_response(pTHX_ hm_conn *c, SV *resp);
static void hm_close(pTHX_ hm_loop *loop, hm_conn *c);
static void hm_h2_free(pTHX_ void *h2);   /* defined in hm_http2.h */
static void hm_readable(pTHX_ hm_conn *c);

#include "hm_tls.h"                        /* SSL_CTX, wrap, hm_cread/hm_cwrite */

/* ---- small utilities ----------------------------------------------------- */

static const char *hm_reason(int s) {
    switch (s) {
        case 200: return "OK";            case 201: return "Created";
        case 204: return "No Content";    case 301: return "Moved Permanently";
        case 302: return "Found";         case 304: return "Not Modified";
        case 400: return "Bad Request";   case 401: return "Unauthorized";
        case 403: return "Forbidden";     case 404: return "Not Found";
        case 405: return "Method Not Allowed";
        case 500: return "Internal Server Error";
        default:  return "OK";
    }
}

/* Format a peer sockaddr into a printable REMOTE_ADDR string ("" on failure
 * or for address families we don't serve). */
static void hm_fmt_peer(char *out, size_t outlen, const struct sockaddr *sa) {
    out[0] = '\0';
    if (!sa) return;
    if (sa->sa_family == AF_INET)
        inet_ntop(AF_INET, &((const struct sockaddr_in *)sa)->sin_addr,
                  out, (socklen_t)outlen);
    else if (sa->sa_family == AF_INET6)
        inet_ntop(AF_INET6, &((const struct sockaddr_in6 *)sa)->sin6_addr,
                  out, (socklen_t)outlen);
}

static void hm_set_nonblock(int fd) {
    int fl = fcntl(fd, F_GETFL, 0);
    fcntl(fd, F_SETFL, fl | O_NONBLOCK);
}

/* fd of a filehandle / IO ref, or a plain fd number */
static int hm_fd_of(pTHX_ SV *sv) {
    if (SvROK(sv)) {
        IO *io = sv_2io(sv);
        if (io && IoIFP(io)) return PerlIO_fileno(IoIFP(io));
        croak("Hyperman: not an open filehandle");
    }
    return (int)SvIV(sv);
}

/* a fresh anonymous glob with an IO slot (standard idiom) */
static GV *hm_anon_glob(pTHX) {
    GV *gv = newGVgen("Hyperman");
    (void)GvIOn(gv);
    SvREFCNT_inc((SV *)gv);
    (void)hv_delete(GvSTASH(gv), GvNAME(gv), GvNAMELEN(gv), G_DISCARD);
    return gv;
}

/* psgi.input: an in-memory read handle over the request body, via the
 * PerlIO :scalar layer - the C equivalent of open($fh,'<',\$body). */
static SV *hm_new_input(pTHX_ const char *body, STRLEN len) {
    static int layer_loaded = 0;
    SV *bufsv = newSVpvn(body, len);
    SV *rv = sv_2mortal(newRV_noinc(bufsv));
    PerlIO *fp;
    GV *gv;
    IO *io;
    if (!layer_loaded) {
        load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("PerlIO::scalar"), NULL);
        layer_loaded = 1;
    }
    fp = PerlIO_openn(aTHX_ ":scalar", "r", -1, 0, 0, NULL, 1, &rv);
    if (!fp) return &PL_sv_undef;
    gv = hm_anon_glob(aTHX);
    io = GvIO(gv);
    IoIFP(io) = fp;
    IoTYPE(io) = IoTYPE_RDONLY;
    return newRV_noinc((SV *)gv);
}

/* psgix.io: a dup of the client socket, so an app that hijacks it keeps
 * the socket alive after the server side closes. */
static SV *hm_fh_for_fd(pTHX_ int fd) {
    int nfd = dup(fd);
    PerlIO *fp;
    GV *gv;
    IO *io;
    if (nfd < 0) return &PL_sv_undef;
    fp = PerlIO_fdopen(nfd, "r+");
    if (!fp) { close(nfd); return &PL_sv_undef; }
    gv = hm_anon_glob(aTHX);
    io = GvIO(gv);
    IoIFP(io) = fp;
    IoOFP(io) = fp;
    IoTYPE(io) = IoTYPE_RDWR;
    return newRV_noinc((SV *)gv);
}

/* Read out a filehandle / IO::Handle-like response body, honouring
 * ->getline/->close on objects (PSGI body protocol). Returns a PV SV. */
static SV *hm_slurp_body(pTHX_ SV *body) {
    SV *out = newSVpvs("");
    if (sv_isobject(body)
        && gv_fetchmethod_autoload(SvSTASH(SvRV(body)), "getline", 0)) {
        for (;;) {
            dSP;
            SV *chunk;
            int n;
            ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(body);
            PUTBACK;
            n = call_method("getline", G_SCALAR | G_EVAL);
            SPAGAIN;
            chunk = n ? POPs : NULL;
            if (SvTRUE(ERRSV) || !chunk || !SvOK(chunk)) {
                PUTBACK; FREETMPS; LEAVE;
                break;
            }
            sv_catsv(out, chunk);
            PUTBACK; FREETMPS; LEAVE;
        }
        if (gv_fetchmethod_autoload(SvSTASH(SvRV(body)), "close", 0)) {
            dSP;
            ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(body);
            PUTBACK;
            call_method("close", G_DISCARD | G_EVAL);
            FREETMPS; LEAVE;
        }
    } else if (SvROK(body)) {
        IO *io = sv_2io(body);
        if (io && IoIFP(io)) {
            char buf[8192];
            SSize_t got;
            while ((got = PerlIO_read(IoIFP(io), buf, sizeof(buf))) > 0)
                sv_catpvn(out, buf, got);
            PerlIO_close(IoIFP(io));
            IoIFP(io) = NULL;
            IoOFP(io) = NULL;
        }
    }
    return out;
}

/* a [500, [...], [$msg]] PSGI triple (mortal) */
static SV *hm_500_resp(pTHX_ const char *msg) {
    AV *resp = newAV();
    AV *hdrs = newAV();
    AV *body = newAV();
    av_push(hdrs, newSVpvs("Content-Type"));
    av_push(hdrs, newSVpvs("text/plain"));
    av_push(body, newSVpv(msg, 0));
    av_push(resp, newSViv(500));
    av_push(resp, newRV_noinc((SV *)hdrs));
    av_push(resp, newRV_noinc((SV *)body));
    return sv_2mortal(newRV_noinc((SV *)resp));
}

/* ---- connections --------------------------------------------------------- */

static void hm_lru_unlink(hm_loop *loop, hm_conn *c) {
    if (c->lru_prev) c->lru_prev->lru_next = c->lru_next;
    else if (loop->lru_head == c) loop->lru_head = c->lru_next;
    if (c->lru_next) c->lru_next->lru_prev = c->lru_prev;
    else if (loop->lru_tail == c) loop->lru_tail = c->lru_prev;
    c->lru_prev = c->lru_next = NULL;
}

static void hm_lru_touch(hm_loop *loop, hm_conn *c) {
    c->last_active = loop->now;
    if (loop->lru_tail == c) return;
    hm_lru_unlink(loop, c);
    c->lru_prev = loop->lru_tail;
    if (loop->lru_tail) loop->lru_tail->lru_next = c;
    loop->lru_tail = c;
    if (!loop->lru_head) loop->lru_head = c;
}

static void hm_close(pTHX_ hm_loop *loop, hm_conn *c) {
    int fd = c->fd;
    SV *pending = c->resp_f;      /* cancelled below, once state is consistent */
    c->resp_f = NULL;
    loop->be->remove_io(loop->be, fd, HM_EV_READ | (c->writing ? HM_EV_WRITE : 0));
    if (c->ssl) hm_tls_conn_free(c);
    close(fd);
    hm_lru_unlink(loop, c);
    loop->conns[fd] = NULL;
    loop->nconns--;
    if (c->io_sv)  { SvREFCNT_dec(c->io_sv);  c->io_sv = NULL; }
    if (c->env_sv) { SvREFCNT_dec(c->env_sv); c->env_sv = NULL; }
    if (c->h2)     { hm_h2_free(aTHX_ c->h2); c->h2 = NULL; }
    if (loop->pool_n < HM_POOL_MAX) {
        c->pool_next = loop->pool;
        loop->pool = c;
        loop->pool_n++;
    } else {
        if (c->wbuf) free(c->wbuf);
        if (c->rbuf) free(c->rbuf);
        free(c);
    }
    if (loop->stopping && loop->nconns == 0) loop->stop = 1;
    /* client went away while awaiting: cancel the response Future so
     * in-flight async work can abort (propagates up the then-chain) */
    if (pending) {
        dSP;
        ENTER; SAVETMPS; PUSHMARK(SP);
        XPUSHs(pending);
        PUTBACK;
        call_method("cancel", G_DISCARD | G_EVAL);
        FREETMPS; LEAVE;
        SvREFCNT_dec(pending);
    }
}

static hm_conn *hm_new_conn(hm_loop *loop, int fd) {
    hm_conn *c;
    if (loop->pool) {
        char  *wbuf, *rbuf; size_t wcap, rcap;
        c = loop->pool;
        loop->pool = c->pool_next;
        loop->pool_n--;
        wbuf = c->wbuf; wcap = c->wcap;      /* keep the buffers */
        rbuf = c->rbuf; rcap = c->rcap;
        memset(c, 0, sizeof(*c));
        c->wbuf = wbuf; c->wcap = wcap;
        c->rbuf = rbuf; c->rcap = rcap;
    } else {
        c = (hm_conn *)calloc(1, sizeof(hm_conn));
    }
    if (!c->rbuf) {
        c->rbuf = (char *)malloc(HM_RBUF);
        c->rcap = HM_RBUF;
    }
    c->fd = fd;
    c->keepalive = 1;
    c->id = ++hm_id_counter;
    c->loop = loop;
    c->last_active = loop->now;
    loop->conns[fd] = c;
    loop->nconns++;
    hm_set_nonblock(fd);
    { int one = 1; setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &one, sizeof(one)); }
    loop->be->add_io(loop->be, fd, HM_EV_READ, 0);
    if (loop->tls_ctx) hm_tls_wrap(c, loop->tls_ctx);   /* TLS: handshake first */
    /* append to LRU tail */
    c->lru_prev = loop->lru_tail;
    if (loop->lru_tail) loop->lru_tail->lru_next = c;
    loop->lru_tail = c;
    if (!loop->lru_head) loop->lru_head = c;
    return c;
}

/* ---- HTTP parse ---------------------------------------------------------- */

/* Scan the header block for Content-Length; return its value or 0. */
static long hm_scan_content_length(const char *head, size_t headlen) {
    const char *p = head, *hend = head + headlen;
    while (p < hend) {
        const char *eol = (const char *)memchr(p, '\n', hend - p);
        size_t len = eol ? (size_t)(eol - p) : (size_t)(hend - p);
        if (len >= 15 && strncasecmp(p, "Content-Length:", 15) == 0) {
            const char *v = p + 15;
            while (v < p + len && (*v == ' ' || *v == '\t')) v++;
            return strtol(v, NULL, 10);
        }
        p = eol ? eol + 1 : hend;
    }
    return 0;
}

/* Find a request header's value in the header block (case-insensitive name).
 * Returns a pointer to the (trimmed) value and sets *vlen, or NULL. */
static const char *hm_find_header(const char *head, size_t headlen,
                                  const char *name, size_t nlen, size_t *vlen) {
    const char *p = (const char *)memchr(head, '\n', headlen);   /* skip req line */
    const char *hend = head + headlen;
    if (!p) return NULL;
    p++;
    while (p < hend) {
        const char *eol = (const char *)memchr(p, '\r', hend - p);
        size_t len = eol ? (size_t)(eol - p) : (size_t)(hend - p);
        const char *colon = (const char *)memchr(p, ':', len);
        if (colon && (size_t)(colon - p) == nlen
            && strncasecmp(p, name, nlen) == 0) {
            const char *v = colon + 1;
            size_t vl = (size_t)((p + len) - v);
            while (vl && (*v == ' ' || *v == '\t')) { v++; vl--; }
            while (vl && (v[vl-1] == ' ' || v[vl-1] == '\t')) vl--;
            *vlen = vl;
            return v;
        }
        p = eol ? eol + 2 : hend;
    }
    return NULL;
}

/* case-insensitive substring search */
static int hm_ci_contains(const char *hay, size_t hl, const char *needle) {
    size_t nl = strlen(needle), i;
    if (nl > hl) return 0;
    for (i = 0; i + nl <= hl; i++)
        if (strncasecmp(hay + i, needle, nl) == 0) return 1;
    return 0;
}

/* Percent-decode a path once (RFC 3875 PATH_INFO): %XX only, no '+'. */
static SV *hm_pct_decode(pTHX_ const char *p, STRLEN n) {
    SV *sv = newSV(n + 1);
    char *d = SvPVX(sv);
    STRLEN i = 0, o = 0;
    SvPOK_on(sv);
    while (i < n) {
        if (p[i] == '%' && i + 2 < n
            && isxdigit((unsigned char)p[i+1]) && isxdigit((unsigned char)p[i+2])) {
            int hi = p[i+1], lo = p[i+2];
            hi = (hi <= '9') ? hi - '0' : (hi | 32) - 'a' + 10;
            lo = (lo <= '9') ? lo - '0' : (lo | 32) - 'a' + 10;
            d[o++] = (char)((hi << 4) | lo);
            i += 3;
        } else {
            d[o++] = p[i++];
        }
    }
    d[o] = 0;
    SvCUR_set(sv, o);
    return sv;
}

/* Build a full PSGI env from the header block (request line + headers) and,
 * if present, the request body. Sets c->keepalive from the request. */
static HV *hm_build_env(pTHX_ char *head, size_t headlen,
                        const char *body, long clen, hm_conn *c) {
    HV *env = newHV();
    AV *ver = newAV(); av_push(ver, newSViv(1)); av_push(ver, newSViv(1));

    /* request line */
    char *line_end = (char *)memchr(head, '\r', headlen);
    size_t ll = line_end ? (size_t)(line_end - head) : headlen;
    char *sp1 = (char *)memchr(head, ' ', ll);
    const char *method = head; STRLEN mlen = ll;
    const char *uri = "/"; STRLEN ulen = 1;
    const char *proto = "HTTP/1.0"; STRLEN plen = 8;
    if (sp1) {
        mlen = (STRLEN)(sp1 - head);
        char *u = sp1 + 1;
        char *sp2 = (char *)memchr(u, ' ', ll - (u - head));
        if (sp2) {
            uri = u; ulen = (STRLEN)(sp2 - u);
            proto = sp2 + 1; plen = (STRLEN)((head + ll) - (sp2 + 1));
        } else { uri = u; ulen = (STRLEN)((head + ll) - u); }
    }
    const char *qmark = (const char *)memchr(uri, '?', ulen);
    const char *path = uri; STRLEN path_l = ulen;
    const char *qs = ""; STRLEN qs_l = 0;
    if (qmark) { path_l = (STRLEN)(qmark - uri); qs = qmark + 1; qs_l = ulen - path_l - 1; }

    hv_stores(env, "REQUEST_METHOD",   newSVpvn(method, mlen));
    hv_stores(env, "REQUEST_URI",      newSVpvn(uri, ulen));
    hv_stores(env, "PATH_INFO",        hm_pct_decode(aTHX_ path, path_l));
    hv_stores(env, "QUERY_STRING",     newSVpvn(qs, qs_l));
    hv_stores(env, "SERVER_PROTOCOL",  newSVpvn(proto, plen));
    hv_stores(env, "SCRIPT_NAME",      newSVpvs(""));
    hv_stores(env, "SERVER_NAME",      newSVpv(c->loop->host ? c->loop->host : "0.0.0.0", 0));
    hv_stores(env, "SERVER_PORT",      newSViv(c->loop->port));
    if (c->peer[0]) hv_stores(env, "REMOTE_ADDR", newSVpv(c->peer, 0));
    hv_stores(env, "psgi.version",     newRV_noinc((SV *)ver));
    hv_stores(env, "psgi.url_scheme",  newSVpv(c->ssl ? "https" : "http", 0));
    hv_stores(env, "psgi.multithread", newSViv(0));
    hv_stores(env, "psgi.multiprocess",newSViv(1));
    hv_stores(env, "psgi.run_once",    newSViv(0));
    hv_stores(env, "psgi.streaming",   newSViv(1));
    hv_stores(env, "psgi.nonblocking", newSViv(1));
    hv_stores(env, "psgi.errors",      newRV_inc((SV *)PL_stderrgv));

    /* psgix.loop: this worker's loop, so apps/clients can create loop
     * Futures; psgix.io: the client socket, dup'd so an app that
     * hijacks it keeps the socket alive after we close our fd. */
    if (!c->loop->self_sv) c->loop->self_sv = hm_loop_to_sv(aTHX_ c->loop);
    hv_stores(env, "psgix.loop", SvREFCNT_inc(c->loop->self_sv));
    if (!c->io_sv) c->io_sv = hm_fh_for_fd(aTHX_ c->fd);
    hv_stores(env, "psgix.io", SvREFCNT_inc(c->io_sv));
    if (c->ssl) hm_tls_env(aTHX_ c, env);

    c->keepalive = (plen == 8 && memcmp(proto, "HTTP/1.1", 8) == 0);

    /* header lines */
    char *p = line_end ? line_end + 2 : head + headlen;
    char *hend = head + headlen;
    char keybuf[300];
    while (p < hend) {
        char *eol = (char *)memchr(p, '\r', hend - p);
        size_t len = eol ? (size_t)(eol - p) : (size_t)(hend - p);
        char *colon = (char *)memchr(p, ':', len);
        if (colon && colon > p) {
            size_t nk = (size_t)(colon - p);
            const char *vp = colon + 1;
            size_t nv = (size_t)((p + len) - vp);
            while (nv && (*vp == ' ' || *vp == '\t')) { vp++; nv--; }

            if (nk == 14 && strncasecmp(p, "Content-Length", 14) == 0) {
                hv_stores(env, "CONTENT_LENGTH", newSVpvn(vp, nv));
            } else if (nk == 12 && strncasecmp(p, "Content-Type", 12) == 0) {
                hv_stores(env, "CONTENT_TYPE", newSVpvn(vp, nv));
            } else if (nk + 5 < sizeof(keybuf)) {
                size_t i;
                memcpy(keybuf, "HTTP_", 5);
                for (i = 0; i < nk; i++) {
                    unsigned char ch = (unsigned char)p[i];
                    if (ch >= 'a' && ch <= 'z') ch -= 32;
                    else if (ch == '-') ch = '_';
                    keybuf[5 + i] = (char)ch;
                }
                {
                    /* repeated header: join values with ", " (PSGI) */
                    SV **old = hv_fetch(env, keybuf, (I32)(nk + 5), 0);
                    if (old) {
                        sv_catpvs(*old, ", ");
                        sv_catpvn(*old, vp, nv);
                    } else {
                        hv_store(env, keybuf, (I32)(nk + 5), newSVpvn(vp, nv), 0);
                    }
                }
                if (nk == 10 && strncasecmp(p, "Connection", 10) == 0) {
                    if (nv >= 5 && strncasecmp(vp, "close", 5) == 0) c->keepalive = 0;
                    else if (nv >= 10 && strncasecmp(vp, "keep-alive", 10) == 0) c->keepalive = 1;
                }
            }
        }
        p = eol ? eol + 2 : hend;
    }

    if (clen > 0) hv_stores(env, "psgi.input", hm_new_input(aTHX_ body, (STRLEN)clen));
    else          hv_stores(env, "psgi.input", SvREFCNT_inc(hm_empty_input));

    return env;
}

/* ---- app invocation ------------------------------------------------------ */

/* Call the app with an env we keep alive (access_log needs it afterwards). */
static SV *hm_call_app(pTHX_ hm_loop *loop, SV *env_rv) {
    dSP;
    SV *resp = NULL;
    int count;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(SvREFCNT_inc(env_rv)));
    PUTBACK;
    count = call_sv(loop->app, G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) {
        resp = POPs;
        SvREFCNT_inc(resp);
    } else if (count > 0) {
        (void)POPs;
    }
    PUTBACK;
    FREETMPS; LEAVE;
    return resp;
}

/* No-logger fast path: the env is handed to the call and freed with it. */
static SV *hm_call_app0(pTHX_ hm_loop *loop, HV *env) {
    dSP;
    SV *resp = NULL;
    int count;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newRV_noinc((SV *)env)));
    PUTBACK;
    count = call_sv(loop->app, G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) {
        resp = POPs;
        SvREFCNT_inc(resp);
    } else if (count > 0) {
        (void)POPs;
    }
    PUTBACK;
    FREETMPS; LEAVE;
    return resp;
}

/* Is any access logging configured for this loop? Guards the (small) cost of
 * keeping the env alive past the response purely for the logger. */
#define hm_logging(loop) ((loop)->log_cb || (loop)->log_fd >= 0)

/* ---- fast default access-log writer (Combined Log Format) ----------------
 * When access_log is a path/handle rather than a coderef, log lines are
 * formatted and buffered in C and flushed once per loop wakeup - no Perl
 * call on the hot path. The fd is shared (inherited) across workers and
 * opened O_APPEND, so whole-line writes stay atomic between them. */

#define HM_LOG_FLUSH_AT (32 * 1024)   /* flush the buffer once it grows past  */

static void hm_log_flush(hm_loop *loop) {
    size_t off = 0;
    if (loop->log_fd < 0 || loop->log_len == 0) return;
    while (off < loop->log_len) {
        ssize_t n = write(loop->log_fd, loop->log_buf + off, loop->log_len - off);
        if (n > 0) { off += (size_t)n; continue; }
        if (n < 0 && errno == EINTR) continue;
        break;   /* EAGAIN/error: keep the unwritten tail for the next flush */
    }
    if (off && off < loop->log_len)
        memmove(loop->log_buf, loop->log_buf + off, loop->log_len - off);
    loop->log_len -= off;
}

static void hm_log_raw(hm_loop *loop, const char *p, size_t n) {
    if (loop->log_len + n > loop->log_cap) {
        size_t ncap = loop->log_cap ? loop->log_cap : 8192;
        while (ncap < loop->log_len + n) ncap *= 2;
        loop->log_buf = (char *)realloc(loop->log_buf, ncap);
        loop->log_cap = ncap;
    }
    memcpy(loop->log_buf + loop->log_len, p, n);
    loop->log_len += n;
}

/* A plain token: '-' when empty (CLF uses '-' for missing fields). */
static void hm_log_tok(hm_loop *loop, const char *p, size_t n) {
    if (!p || n == 0) { hm_log_raw(loop, "-", 1); return; }
    hm_log_raw(loop, p, n);
}

/* A value going inside "quotes": escape ", \ and control bytes \xHH so a
 * hostile URI or User-Agent cannot forge or split a log line. */
static void hm_log_quoted(hm_loop *loop, const char *p, size_t n) {
    static const char hex[] = "0123456789abcdef";
    size_t i, run = 0;
    if (!p) return;
    for (i = 0; i < n; i++) {
        unsigned char ch = (unsigned char)p[i];
        if (ch == '"' || ch == '\\' || ch < 0x20 || ch == 0x7f) {
            char e[4];
            if (run) { hm_log_raw(loop, p + i - run, run); run = 0; }
            if (ch == '"' || ch == '\\') {
                e[0] = '\\'; e[1] = (char)ch; hm_log_raw(loop, e, 2);
            } else {
                e[0] = '\\'; e[1] = 'x'; e[2] = hex[ch >> 4]; e[3] = hex[ch & 0xf];
                hm_log_raw(loop, e, 4);
            }
        } else {
            run++;
        }
    }
    if (run) hm_log_raw(loop, p + n - run, run);
}

/* Cached apache-style timestamp, recomputed at most once per second. */
static const char *hm_log_time(hm_loop *loop) {
    if (loop->now != loop->log_ts_sec) {
        struct tm tm;
        time_t t = loop->now;
        localtime_r(&t, &tm);
        strftime(loop->log_ts, sizeof(loop->log_ts), "%d/%b/%Y:%H:%M:%S %z", &tm);
        loop->log_ts_sec = loop->now;
    }
    return loop->log_ts;
}

static const char *hm_env_str(pTHX_ HV *env, const char *key, I32 klen, STRLEN *lenp) {
    SV **s = hv_fetch(env, key, klen, 0);
    if (s && *s && SvOK(*s)) return SvPV(*s, *lenp);
    *lenp = 0;
    return NULL;
}

/* Build one Combined Log Format line into the loop's log buffer:
 *   host - user [time] "METHOD URI PROTO" status bytes "referer" "ua" */
static void hm_log_clf(pTHX_ hm_loop *loop, SV *env_rv, int status, ssize_t blen) {
    HV *env;
    const char *s; STRLEN n;
    char num[32];
    int ln;
    const char *ts;

    if (!(env_rv && SvROK(env_rv) && SvTYPE(SvRV(env_rv)) == SVt_PVHV)) return;
    env = (HV *)SvRV(env_rv);

    s = hm_env_str(aTHX_ env, "REMOTE_ADDR", 11, &n); hm_log_tok(loop, s, n);
    hm_log_raw(loop, " - ", 3);                        /* %l always '-' */
    s = hm_env_str(aTHX_ env, "REMOTE_USER", 11, &n); hm_log_tok(loop, s, n);
    hm_log_raw(loop, " [", 2);
    ts = hm_log_time(loop); hm_log_raw(loop, ts, strlen(ts));
    hm_log_raw(loop, "] \"", 3);
    s = hm_env_str(aTHX_ env, "REQUEST_METHOD", 14, &n); hm_log_quoted(loop, s, n);
    hm_log_raw(loop, " ", 1);
    s = hm_env_str(aTHX_ env, "REQUEST_URI", 11, &n);
    if (s) hm_log_quoted(loop, s, n); else hm_log_raw(loop, "-", 1);
    hm_log_raw(loop, " ", 1);
    s = hm_env_str(aTHX_ env, "SERVER_PROTOCOL", 15, &n); hm_log_quoted(loop, s, n);
    hm_log_raw(loop, "\" ", 2);
    ln = (int)snprintf(num, sizeof(num), "%d", status); hm_log_raw(loop, num, (size_t)ln);
    hm_log_raw(loop, " ", 1);
    if (blen >= 0) { ln = (int)snprintf(num, sizeof(num), "%ld", (long)blen);
                     hm_log_raw(loop, num, (size_t)ln); }
    else           hm_log_raw(loop, "-", 1);
    hm_log_raw(loop, " \"", 2);
    s = hm_env_str(aTHX_ env, "HTTP_REFERER", 12, &n);
    if (s) hm_log_quoted(loop, s, n); else hm_log_raw(loop, "-", 1);
    hm_log_raw(loop, "\" \"", 3);
    s = hm_env_str(aTHX_ env, "HTTP_USER_AGENT", 15, &n);
    if (s) hm_log_quoted(loop, s, n); else hm_log_raw(loop, "-", 1);
    hm_log_raw(loop, "\"\n", 2);

    if (loop->log_len >= HM_LOG_FLUSH_AT) hm_log_flush(loop);
}

/* Record one response. Fast path: format in C to the access-log fd. Else, if
 * a coderef was given, call $cb->($env, $status, $bytes); errors in the logger
 * are swallowed so they cannot take the loop down. */
static void hm_access_log(pTHX_ hm_loop *loop, SV *env_rv, int status, ssize_t blen) {
    dSP;
    if (loop->log_fd >= 0) { hm_log_clf(aTHX_ loop, env_rv, status, blen); return; }
    if (!loop->log_cb) return;
    ENTER; SAVETMPS; PUSHMARK(SP);
    XPUSHs(env_rv);
    XPUSHs(sv_2mortal(newSViv(status)));
    XPUSHs(blen >= 0 ? sv_2mortal(newSViv((IV)blen)) : &PL_sv_undef);
    PUTBACK;
    call_sv(loop->log_cb, G_DISCARD | G_EVAL);
    FREETMPS; LEAVE;
}

/* ---- response serialization ---------------------------------------------- */

/* Reusable per-connection write buffer: keep capacity across requests so the
 * steady-state response path does no malloc/free. */
static void hm_wb_reserve(hm_conn *c, size_t need) {
    if (c->wlen + need > c->wcap) {
        size_t ncap = c->wcap ? c->wcap : 4096;
        while (ncap < c->wlen + need) ncap *= 2;
        c->wbuf = (char *)realloc(c->wbuf, ncap);
        c->wcap = ncap;
    }
}
static void hm_wb_put(hm_conn *c, const char *p, size_t n) {
    hm_wb_reserve(c, n);
    memcpy(c->wbuf + c->wlen, p, n);
    c->wlen += n;
}

static const char HM_ERR500[] =
    "HTTP/1.1 500 Internal Server Error\r\nContent-Type: text/plain\r\n"
    "Content-Length: 21\r\nConnection: close\r\n\r\nInternal Server Error";

/* Serialize $resp: headers into c->wbuf, then try an immediate writev of
 * header + body chunks (zero-copy body). Whatever the kernel doesn't take
 * is buffered; a write watcher resumes it (backpressure). Falls back to
 * copy-into-buffer when bytes are already queued (pipelining) or the body
 * is a filehandle. Returns 0, or -1 if the connection was closed. */
static int hm_queue_response(pTHX_ hm_conn *c, SV *resp) {
    hm_loop *loop = c->loop;
    AV *rav, *hav = NULL;
    SV **s0, **s1, **s2;
    SV *fh_body = NULL;
    AV *bav = NULL;
    int status = 500, has_len = 0, has_conn = 0;
    size_t blen = 0;
    size_t hdr_start = c->wlen;
    SSize_t bn = 0;
    char line[64];
    int ln;

    if (loop->stopping) c->keepalive = 0;

    if (!(resp && SvROK(resp) && SvTYPE(SvRV(resp)) == SVt_PVAV)) {
        hm_wb_put(c, HM_ERR500, sizeof(HM_ERR500) - 1);
        c->keepalive = 0;
        c->last_status = 500;
        c->last_blen = 21;
        return 0;
    }
    rav = (AV *)SvRV(resp);
    s0 = av_fetch(rav, 0, 0);
    s1 = av_fetch(rav, 1, 0);
    s2 = av_fetch(rav, 2, 0);
    if (s0) status = (int)SvIV(*s0);
    if (s1 && SvROK(*s1) && SvTYPE(SvRV(*s1)) == SVt_PVAV) hav = (AV *)SvRV(*s1);

    /* body length (first pass, no copy) */
    if (s2 && SvROK(*s2) && SvTYPE(SvRV(*s2)) == SVt_PVAV) {
        SSize_t i;
        bav = (AV *)SvRV(*s2);
        bn = av_len(bav) + 1;
        for (i = 0; i < bn; i++) {
            SV **e = av_fetch(bav, i, 0);
            if (e) { STRLEN l; (void)SvPV(*e, l); blen += l; }
        }
    } else if (s2 && SvROK(*s2)) {
        /* filehandle or IO::Handle-like body */
        fh_body = hm_slurp_body(aTHX_ *s2);
        { STRLEN l; (void)SvPV(fh_body, l); blen = l; }
    }

    /* status line + headers */
    c->last_status = status;
    c->last_blen = blen;
    ln = snprintf(line, sizeof(line), "HTTP/1.1 %d %s\r\n", status, hm_reason(status));
    hm_wb_put(c, line, (size_t)ln);
    if (hav) {
        SSize_t i, hn = av_len(hav) + 1;
        for (i = 0; i + 1 < hn; i += 2) {
            SV **k = av_fetch(hav, i, 0);
            SV **v = av_fetch(hav, i + 1, 0);
            STRLEN kl, vl;
            const char *ks = SvPV(*k, kl);
            const char *vs = SvPV(*v, vl);
            if (kl == 14 && strncasecmp(ks, "Content-Length", 14) == 0) has_len = 1;
            if (kl == 10 && strncasecmp(ks, "Connection", 10) == 0)     has_conn = 1;
            hm_wb_put(c, ks, kl);
            hm_wb_put(c, ": ", 2);
            hm_wb_put(c, vs, vl);
            hm_wb_put(c, "\r\n", 2);
        }
    }
    /* 1xx/204/304 carry no entity: no Content-Length, no body (RFC 7230) */
    {
        int no_entity = (status < 200 || status == 204 || status == 304);
        if (no_entity) {
            if (fh_body) { SvREFCNT_dec(fh_body); fh_body = NULL; }
            bav = NULL; bn = 0; blen = 0;
        } else if (!has_len) {
            ln = snprintf(line, sizeof(line), "Content-Length: %lu\r\n", (unsigned long)blen);
            hm_wb_put(c, line, (size_t)ln);
        }
    }
    if (!has_conn)
        hm_wb_put(c, c->keepalive ? "Connection: keep-alive\r\n" : "Connection: close\r\n",
                  c->keepalive ? 24 : 19);
    hm_wb_put(c, "\r\n", 2);

    loop->bytes_out += (c->wlen - hdr_start) + blen;

    /* fast path: nothing queued before this response -> writev header+body
     * straight from the response SVs, no body copy */
    if (hdr_start == 0 && c->woff == 0 && !c->writing && !fh_body && !c->ssl
        && bav && bn >= 0 && bn < HM_IOV_MAX) {
        struct iovec iov[HM_IOV_MAX];
        size_t total = c->wlen;
        int niov = 1;
        SSize_t i;
        ssize_t n;
        iov[0].iov_base = c->wbuf;
        iov[0].iov_len  = c->wlen;
        for (i = 0; i < bn; i++) {
            SV **e = av_fetch(bav, i, 0);
            if (e) {
                STRLEN l; const char *p = SvPV(*e, l);
                if (l) {
                    iov[niov].iov_base = (void *)p;
                    iov[niov].iov_len  = l;
                    niov++;
                    total += l;
                }
            }
        }
        n = writev(c->fd, iov, niov);
        if (n < 0) {
            if (errno != EAGAIN && errno != EWOULDBLOCK) { hm_close(aTHX_ loop, c); return -1; }
            n = 0;
        }
        if ((size_t)n >= total) { c->wlen = 0; return 0; }   /* all written */
        /* partial: keep the unwritten remainder in wbuf */
        {
            size_t skip = (size_t)n;
            size_t hdrlen = c->wlen;
            if (skip < hdrlen) {
                memmove(c->wbuf, c->wbuf + skip, hdrlen - skip);
                c->wlen = hdrlen - skip;
                skip = 0;
            } else {
                skip -= hdrlen;
                c->wlen = 0;
            }
            for (i = 0; i < bn; i++) {
                SV **e = av_fetch(bav, i, 0);
                if (e) {
                    STRLEN l; const char *p = SvPV(*e, l);
                    if (skip >= l) { skip -= l; continue; }
                    hm_wb_put(c, p + skip, l - skip);
                    skip = 0;
                }
            }
        }
        loop->be->add_io(loop->be, c->fd, HM_EV_WRITE, 0);
        c->writing = 1;
        return 0;
    }

    /* slow path: copy the body into the write buffer */
    if (fh_body) {
        STRLEN l; const char *p = SvPV(fh_body, l);
        hm_wb_put(c, p, l);
        SvREFCNT_dec(fh_body);
    } else if (bav) {
        SSize_t i;
        for (i = 0; i < bn; i++) {
            SV **e = av_fetch(bav, i, 0);
            if (e) { STRLEN l; const char *p = SvPV(*e, l); hm_wb_put(c, p, l); }
        }
    }
    return 0;
}

/* Flush c->wbuf; on EAGAIN arm a write watcher. Returns 0 to keep the
 * connection, -1 if it was closed. */
static int hm_flush(pTHX_ hm_conn *c) {
    hm_loop *loop = c->loop;
    if (c->wlen == 0) {
        if (!c->keepalive && !c->awaiting) { hm_close(aTHX_ loop, c); return -1; }
        return 0;
    }
    while (c->woff < c->wlen) {
        ssize_t n = hm_cwrite(c, c->wbuf + c->woff, c->wlen - c->woff);
        if (n > 0) {
            c->woff += (size_t)n;
        } else if (n < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
            /* arm a write watcher, unless the TLS engine is blocked wanting a
             * read (the always-armed read watcher re-drives us then) */
            if (!c->writing && !c->tls_w_wants_r) {
                loop->be->add_io(loop->be, c->fd, HM_EV_WRITE, 0);
                c->writing = 1;
            }
            return 0;
        } else {
            hm_close(aTHX_ loop, c);
            return -1;
        }
    }
    /* fully written; keep the buffer + capacity for the next response */
    c->wlen = c->woff = 0;
    if (c->writing) {
        loop->be->remove_io(loop->be, c->fd, HM_EV_WRITE);
        c->writing = 0;
    }
    if (!c->keepalive && !c->awaiting) { hm_close(aTHX_ loop, c); return -1; }
    return 0;
}

/* ---- async delivery (Future + streaming) --------------------------------- */

/* Deliver an async response to a parked connection. No-op if the
 * connection is gone or the fd was reused. */
static void hm_deliver(pTHX_ int fd, UV id, SV *resp) {
    hm_loop *loop = hm_cur_loop;
    hm_conn *c = (loop && fd >= 0 && fd < HM_MAXFD) ? loop->conns[fd] : NULL;
    if (!(c && c->id == id)) return;
    c->awaiting = 0;
    if (c->resp_f) { SvREFCNT_dec(c->resp_f); c->resp_f = NULL; }
    if (c->env_sv) {
        SV *env_rv = c->env_sv;
        c->env_sv = NULL;
        if (hm_queue_response(aTHX_ c, resp) == 0 && loop->conns[fd] == c) {
            hm_access_log(aTHX_ loop, env_rv, c->last_status,
                          (ssize_t)c->last_blen);
            SvREFCNT_dec(env_rv);
            if (hm_flush(aTHX_ c) == 0 && loop->conns[fd] == c) {
                hm_process(aTHX_ c);
                if (loop->conns[fd] == c) hm_flush(aTHX_ c);
            }
        } else {
            SvREFCNT_dec(env_rv);
        }
        return;
    }
    if (hm_queue_response(aTHX_ c, resp) == 0
        && loop->conns[fd] == c
        && hm_flush(aTHX_ c) == 0
        && loop->conns[fd] == c) {
        hm_process(aTHX_ c);
        if (loop->conns[fd] == c) hm_flush(aTHX_ c);
    }
}

/* Send status+headers for a streaming response; body follows via
 * hm_stream_write/hm_stream_close. EOF-delimited, so the conn closes. */
static void hm_start_stream(pTHX_ int fd, UV id, int status, SV *headers) {
    hm_loop *loop = hm_cur_loop;
    hm_conn *c = (loop && fd >= 0 && fd < HM_MAXFD) ? loop->conns[fd] : NULL;
    char line[64];
    int ln;
    if (!(c && c->id == id)) return;
    c->keepalive = 0;
    if (c->env_sv) {
        hm_access_log(aTHX_ loop, c->env_sv, status, -1);
        SvREFCNT_dec(c->env_sv);
        c->env_sv = NULL;
    }
    ln = snprintf(line, sizeof(line), "HTTP/1.1 %d %s\r\n", status, hm_reason(status));
    hm_wb_put(c, line, (size_t)ln);
    if (headers && SvROK(headers) && SvTYPE(SvRV(headers)) == SVt_PVAV) {
        AV *hav = (AV *)SvRV(headers);
        SSize_t i, hn = av_len(hav) + 1;
        for (i = 0; i + 1 < hn; i += 2) {
            SV **k = av_fetch(hav, i, 0);
            SV **v = av_fetch(hav, i + 1, 0);
            STRLEN kl, vl;
            const char *ks = SvPV(*k, kl);
            const char *vs = SvPV(*v, vl);
            hm_wb_put(c, ks, kl);
            hm_wb_put(c, ": ", 2);
            hm_wb_put(c, vs, vl);
            hm_wb_put(c, "\r\n", 2);
        }
    }
    hm_wb_put(c, "Connection: close\r\n\r\n", 21);
    hm_flush(aTHX_ c);
}

static void hm_stream_write(pTHX_ int fd, UV id, SV *data) {
    hm_loop *loop = hm_cur_loop;
    hm_conn *c = (loop && fd >= 0 && fd < HM_MAXFD) ? loop->conns[fd] : NULL;
    if (c && c->id == id) {
        STRLEN l;
        const char *p = SvPV(data, l);
        hm_wb_put(c, p, l);
        c->loop->bytes_out += l;
        hm_flush(aTHX_ c);
    }
}

static void hm_stream_close(pTHX_ int fd, UV id) {
    hm_loop *loop = hm_cur_loop;
    hm_conn *c = (loop && fd >= 0 && fd < HM_MAXFD) ? loop->conns[fd] : NULL;
    if (c && c->id == id) {
        c->awaiting = 0;
        hm_flush(aTHX_ c);   /* closes when drained (keepalive is off) */
    }
}

/* The parked-Future continuation: when the response Future resolves,
 * deliver its result (or a 500 on failure, logged to psgi.errors). */
XS_INTERNAL(hm_xs_park_cb);
XS_INTERNAL(hm_xs_park_cb) {
    dXSARGS;
    hm_clos *cl = hm_clos_of(aTHX_ cv);
    SV *f, *resp = NULL;
    IV st;
    int fd;
    UV id;
    if (!cl || items < 1) XSRETURN_EMPTY;
    f = ST(0);
    fd = (int)cl->i;
    id = cl->u;
    st = hm_any_state(aTHX_ f);
    if (st == HMF_DONE) {
        if (hmf_is_future(aTHX_ f)) {
            AV *vals = hmf_values_av(aTHX_ f);
            SV **e = (vals && av_len(vals) >= 0) ? av_fetch(vals, 0, 0) : NULL;
            resp = e ? sv_mortalcopy(*e) : NULL;
        } else {
            dSP;
            SV *got = NULL;
            int n;
            ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(f);
            PUTBACK;
            n = call_method("get", G_SCALAR | G_EVAL);
            SPAGAIN;
            if (n && !SvTRUE(ERRSV)) got = newSVsv(POPs);
            else if (n) (void)POPs;
            PUTBACK; FREETMPS; LEAVE;
            if (got) resp = sv_2mortal(got);   /* mortal in the outer frame */
        }
    } else if (st == HMF_FAILED) {
        AV *errs = newAV();
        SV **e;
        STRLEN l;
        const char *msg = "unknown error";
        hm_any_values(aTHX_ f, st, errs);
        e = av_len(errs) >= 0 ? av_fetch(errs, 0, 0) : NULL;
        if (e && SvOK(*e)) msg = SvPV(*e, l);
        PerlIO_printf(PerlIO_stderr(), "Hyperman: async response failed: %s%s",
                      msg, (*msg && msg[strlen(msg)-1] == '\n') ? "" : "\n");
        SvREFCNT_dec((SV *)errs);
    }
    if (!(resp && SvROK(resp) && SvTYPE(SvRV(resp)) == SVt_PVAV))
        resp = hm_500_resp(aTHX_ st == HMF_DONE
                           ? "Bad async response" : "Internal Server Error");
    hm_deliver(aTHX_ fd, id, resp);
    XSRETURN_EMPTY;
}

/* Park a connection awaiting a pending Future. */
static void hm_park(pTHX_ hm_conn *c, SV *future) {
    SV *cb = hm_closure(aTHX_ hm_xs_park_cb, NULL, NULL, NULL, NULL,
                        (IV)c->fd, c->id);
    hm_any_on_ready(aTHX_ future, cb);
    SvREFCNT_dec(cb);
}

/* psgi.streaming responder: [$s,$h,$b] delivers now; [$s,$h] starts a
 * stream and returns a Hyperman::Writer. */
XS_INTERNAL(hm_xs_responder);
XS_INTERNAL(hm_xs_responder) {
    dXSARGS;
    hm_clos *cl = hm_clos_of(aTHX_ cv);
    SV *r;
    AV *rav;
    SSize_t n;
    int fd;
    UV id;
    if (!cl) XSRETURN_EMPTY;
    fd = (int)cl->i;
    id = cl->u;
    if (items < 1 || !(SvROK(ST(0)) && SvTYPE(SvRV(ST(0))) == SVt_PVAV))
        croak("Hyperman responder expects an array reference");
    r = ST(0);
    rav = (AV *)SvRV(r);
    n = av_len(rav) + 1;
    if (n >= 3) {
        hm_deliver(aTHX_ fd, id, r);
        XSRETURN_EMPTY;
    }
    if (n == 2) {
        SV **s0 = av_fetch(rav, 0, 0);
        SV **s1 = av_fetch(rav, 1, 0);
        AV *w = newAV();
        SV *wrv;
        hm_start_stream(aTHX_ fd, id, s0 ? (int)SvIV(*s0) : 200,
                        s1 ? *s1 : NULL);
        av_push(w, newSViv(fd));
        av_push(w, newSVuv(id));
        wrv = newRV_noinc((SV *)w);
        sv_bless(wrv, gv_stashpv("Hyperman::Writer", GV_ADD));
        ST(0) = sv_2mortal(wrv);
        XSRETURN(1);
    }
    croak("Hyperman responder expects [status, headers, body] or [status, headers]");
}

/* psgi.streaming: run the app's coderef with a responder. */
static void hm_delayed(pTHX_ hm_conn *c, SV *code) {
    SV *responder = hm_closure(aTHX_ hm_xs_responder, NULL, NULL, NULL, NULL,
                               (IV)c->fd, c->id);
    int fd = c->fd;
    UV id = c->id;
    dSP;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(responder);
    PUTBACK;
    call_sv(code, G_DISCARD | G_EVAL);
    if (SvTRUE(ERRSV))
        hm_deliver(aTHX_ fd, id, hm_500_resp(aTHX_ "Internal Server Error"));
    FREETMPS; LEAVE;
    SvREFCNT_dec(responder);
}

/* ---- HTTP/2 (h2c via nghttp2), reusing the helpers above ----------------- */

#include "hm_http2.h"

/* ---- request processing -------------------------------------------------- */

static void hm_again_push(hm_loop *loop, hm_conn *c) {
    if (loop->again_n == loop->again_cap) {
        loop->again_cap = loop->again_cap ? loop->again_cap * 2 : 64;
        loop->again = (hm_again *)realloc(loop->again,
                          loop->again_cap * sizeof(hm_again));
    }
    loop->again[loop->again_n].fd = c->fd;
    loop->again[loop->again_n].id = c->id;
    loop->again_n++;
}

/* Process complete requests buffered in c->rbuf, capped per wakeup so one
 * pipelined connection can't starve the others (fairness). */
static void hm_process(pTHX_ hm_conn *c) {
    hm_loop *loop = c->loop;
    int served = 0;

    /* HTTP/2: once a connection is in h2 mode, all bytes go to nghttp2.
     * On a fresh connection with http2 enabled, sniff the h2 preface. */
    if (c->h2) { hm_h2_input(aTHX_ c); return; }
    if (loop->http2 && c->nreqs == 0 && c->rlen > 0) {
        if (hm_h2_detect(aTHX_ c) != 0) return;   /* started, or need more */
    }

    for (;;) {
        if (c->awaiting) break;   /* parked; resumes via hm_deliver */

        char *end = (char *)memmem(c->rbuf, c->rlen, "\r\n\r\n", 4);
        if (!end) break;

        if (served >= loop->max_pipeline) {     /* yield to other conns */
            hm_again_push(loop, c);
            break;
        }

        size_t headlen = (size_t)(end - c->rbuf);
        size_t bodystart = headlen + 4;

        long clen = hm_scan_content_length(c->rbuf, headlen);
        if (clen < 0) clen = 0;
        if (bodystart + (size_t)clen > loop->max_read) {   /* can never fit */
            static const char e413[] =
                "HTTP/1.1 413 Payload Too Large\r\nContent-Length: 0\r\n"
                "Connection: close\r\n\r\n";
            hm_wb_put(c, e413, sizeof(e413) - 1);
            c->keepalive = 0;
            break;
        }
        if (c->rlen - bodystart < (size_t)clen) break;   /* await full body */

#ifdef HM_HAVE_NGHTTP2
        /* HTTP/1.1 Upgrade: h2c (cleartext, first request only). h2c-over-TLS
         * is forbidden by RFC 7540; the TLS path uses ALPN. */
        if (loop->http2 && !c->ssl && !c->h2 && c->nreqs == 0) {
            size_t ul = 0, sl = 0;
            const char *up = hm_find_header(c->rbuf, headlen, "upgrade", 7, &ul);
            const char *se = hm_find_header(c->rbuf, headlen, "http2-settings", 14, &sl);
            if (up && se && hm_ci_contains(up, ul, "h2c")) {
                static const char resp101[] =
                    "HTTP/1.1 101 Switching Protocols\r\n"
                    "Connection: Upgrade\r\nUpgrade: h2c\r\n\r\n";
                int is_head = (headlen >= 5 && strncasecmp(c->rbuf, "HEAD ", 5) == 0);
                HV *env = hm_build_env(aTHX_ c->rbuf, headlen,
                                       c->rbuf + bodystart, clen, c);
                (void)hv_stores(env, "SERVER_PROTOCOL", newSVpvs("HTTP/2"));
                hm_wb_put(c, resp101, sizeof(resp101) - 1);
                {
                    size_t consumed = bodystart + (size_t)clen;
                    memmove(c->rbuf, c->rbuf + consumed, c->rlen - consumed);
                    c->rlen -= consumed;
                    c->nreqs++;
                    loop->requests++;
                }
                if (hm_h2_start_upgrade(aTHX_ c, se, sl, env, is_head) < 0) {
                    hm_close(aTHX_ loop, c);
                    return;
                }
                hm_h2_input(aTHX_ c);   /* client's h2 preface + frames, + flush */
                return;
            }
        }
#endif

        HV *env = hm_build_env(aTHX_ c->rbuf, headlen, c->rbuf + bodystart, clen, c);
        SV *env_rv = NULL;
        SV *resp;
        if (hm_logging(loop)) {             /* env survives for access_log */
            env_rv = newRV_noinc((SV *)env);
            resp = hm_call_app(aTHX_ loop, env_rv);
        } else {
            resp = hm_call_app0(aTHX_ loop, env);
        }

        size_t consumed = bodystart + (size_t)clen;
        memmove(c->rbuf, c->rbuf + consumed, c->rlen - consumed);
        c->rlen -= consumed;
        c->req_start = 0;
        served++;
        c->nreqs++;
        loop->requests++;
        if (loop->max_requests && loop->requests >= loop->max_requests
            && !loop->stopping && loop->listen_fd >= 0)
            loop->recycle_pending = 1;  /* drain at the loop iteration boundary */

        /* async: handler returned a Future -> park and wait; hold the
         * future so a client disconnect can cancel it */
        if (resp && hm_is_awaitable(aTHX_ resp)) {
            c->awaiting = 1;
            c->resp_f = SvREFCNT_inc(resp);
            c->env_sv = env_rv;                 /* logged at delivery */
            hm_park(aTHX_ c, resp);
            SvREFCNT_dec(resp);
            if (loop->conns[c->fd] != c) return;   /* resolved + closed inline */
            break;
        }

        /* psgi.streaming: coderef response -> park, hand it a responder */
        if (resp && SvROK(resp) && SvTYPE(SvRV(resp)) == SVt_PVCV) {
            c->awaiting = 1;
            c->env_sv = env_rv;                 /* logged at respond time */
            hm_delayed(aTHX_ c, resp);
            SvREFCNT_dec(resp);
            if (loop->conns[c->fd] != c) return;   /* responder ran + closed */
            break;
        }

        {
            int rc = hm_queue_response(aTHX_ c, resp);
            if (resp) SvREFCNT_dec(resp);
            if (rc < 0) { if (env_rv) SvREFCNT_dec(env_rv); return; }
        }
        if (env_rv) {
            hm_access_log(aTHX_ loop, env_rv, c->last_status, (ssize_t)c->last_blen);
            SvREFCNT_dec(env_rv);
        }
        if (!c->keepalive) break;
    }
    if (loop->conns[c->fd] == c && c->rlen > 0 && !c->awaiting && !c->req_start)
        c->req_start = loop->now;
}

static void hm_readable(pTHX_ hm_conn *c) {
    hm_loop *loop = c->loop;
    for (;;) {
        if (c->rlen == c->rcap) {
            /* grow for large bodies; unbounded headers are rejected */
            if (c->rcap >= loop->max_read
                || (c->rlen >= 65536 && !memmem(c->rbuf, c->rlen, "\r\n\r\n", 4))) {
                hm_close(aTHX_ loop, c);
                return;
            }
            {
                size_t ncap = c->rcap * 2;
                if (ncap > loop->max_read) ncap = loop->max_read;
                c->rbuf = (char *)realloc(c->rbuf, ncap);
                c->rcap = ncap;
            }
        }
        ssize_t n = hm_cread(c, c->rbuf + c->rlen, c->rcap - c->rlen);
        if (n > 0) {
            c->rlen += (size_t)n;
        } else if (n == 0) {
            hm_close(aTHX_ loop, c);
            return;
        } else if (errno == EAGAIN || errno == EWOULDBLOCK) {
            /* TLS read blocked wanting writable: arm a write watcher so a
             * write-readiness event re-drives us */
            if (c->tls_r_wants_w && !c->writing) {
                loop->be->add_io(loop->be, c->fd, HM_EV_WRITE, 0);
                c->writing = 1;
            }
            break;
        } else {
            hm_close(aTHX_ loop, c);
            return;
        }
    }
    hm_lru_touch(loop, c);
    hm_process(aTHX_ c);
    if (loop->conns[c->fd] == c) hm_flush(aTHX_ c);
}

static void hm_accept(pTHX_ hm_loop *loop) {
    int batch = 0;
    if (loop->stopping) return;
    for (;;) {
        struct sockaddr_storage ss;
        socklen_t slen = sizeof(ss);
        hm_conn *c;
        int fd = accept(loop->listen_fd, (struct sockaddr *)&ss, &slen);
        if (fd < 0) break;                     /* EAGAIN: drained */
        if (fd >= HM_MAXFD) { close(fd); continue; }
        c = hm_new_conn(loop, fd);
        hm_fmt_peer(c->peer, sizeof(c->peer), (struct sockaddr *)&ss);
        loop->accepts++;
        /* fairness: don't grab the whole queue in one wakeup; the listener
         * stays level-readable, so the next iteration resumes */
        if (++batch >= 64) break;
    }
}

/* Drive the TLS handshake for a connection still in SSL_accept. On success,
 * switch to HTTP/2 if ALPN negotiated h2, then start serving. WANT_READ waits
 * on the always-armed read watcher; WANT_WRITE arms a write watcher. */
static void hm_tls_handshake(pTHX_ hm_conn *c) {
#ifdef HM_HAVE_OPENSSL
    hm_loop *loop = c->loop;
    SSL *ssl = (SSL *)c->ssl;
    int r;
    ERR_clear_error();
    r = SSL_accept(ssl);
    if (r == 1) {
        c->tls_hs = 0;
        hm_tls_capture_peer(c);       /* protocol/cipher + any client cert */
        if (c->writing) {
            loop->be->remove_io(loop->be, c->fd, HM_EV_WRITE);
            c->writing = 0;
        }
#ifdef HM_HAVE_NGHTTP2
        if (loop->http2) {
            const unsigned char *proto = NULL;
            unsigned int plen = 0;
            SSL_get0_alpn_selected(ssl, &proto, &plen);
            if (plen == 2 && memcmp(proto, "h2", 2) == 0
                && hm_h2_start(aTHX_ c) < 0) {
                hm_close(aTHX_ loop, c);
                return;
            }
        }
#endif
        hm_readable(aTHX_ c);   /* any early app data is already buffered */
        return;
    }
    {
        int e = SSL_get_error(ssl, r);
        if (e == SSL_ERROR_WANT_READ) return;   /* read watcher armed */
        if (e == SSL_ERROR_WANT_WRITE) {
            if (!c->writing) {
                loop->be->add_io(loop->be, c->fd, HM_EV_WRITE, 0);
                c->writing = 1;
            }
            return;
        }
        hm_close(aTHX_ loop, c);   /* handshake failed */
    }
#else
    (void)c;
#endif
}

/* ---- timeouts, shutdown, loop -------------------------------------------- */

/* Resolve an app io-readiness Future (fd became readable/writable), or run
 * a persistent watch_io callback. */
static void hm_io_event(pTHX_ hm_loop *loop, hm_iow *slot) {
    SV *sv = slot->sv;
    PERL_UNUSED_VAR(loop);
    if (!sv) return;
    if (slot->is_cb) {
        dSP;
        ENTER; SAVETMPS; PUSHMARK(SP);
        PUTBACK;
        call_sv(sv, G_DISCARD);
        FREETMPS; LEAVE;
    } else {
        slot->sv = NULL;                    /* one-shot */
        hmf_done0(aTHX_ sv);
        SvREFCNT_dec(sv);
    }
}

/* Timeout sweep: close idle keep-alive connections and slow/partial-request
 * (slowloris) connections. Runs on a periodic backend timer. */
static void hm_sweep(pTHX_ hm_loop *loop) {
    hm_conn *c = loop->lru_head;
    time_t now = time(NULL);
    loop->now = now;
    while (c) {
        hm_conn *next = c->lru_next;
        if (!c->awaiting) {
            double idle = difftime(now, c->last_active);
            int slow = c->req_start &&
                       difftime(now, c->req_start) > loop->header_timeout;
            if (idle > loop->idle_timeout || slow)
                hm_close(aTHX_ loop, c);
        }
        c = next;
    }
}

/* Graceful shutdown: stop accepting, close idle (served) connections,
 * finish in-flight work bounded by shutdown_grace; responses during
 * shutdown get Connection: close. */
static void hm_on_signal(pTHX_ hm_loop *loop) {
    hm_conn *c;
    if (loop->stopping) { loop->stop = 1; return; }   /* second signal: hard */
    loop->stopping = 1;
    if (loop->listen_fd >= 0)
        loop->be->remove_io(loop->be, loop->listen_fd, HM_EV_READ);
    c = loop->lru_head;
    while (c) {
        hm_conn *next = c->lru_next;
        if (!c->awaiting && c->rlen == 0 && c->wlen == c->woff && c->nreqs > 0)
            hm_close(aTHX_ loop, c);
        c = next;
    }
    if (loop->nconns == 0) { loop->stop = 1; return; }
    if (!loop->hardstop_tw) {
        loop->hardstop_tw = (hm_tw *)calloc(1, sizeof(hm_tw));
        loop->hardstop_tw->kind = HM_TW_HARDSTOP;
        loop->hardstop_tw->loop = loop;
        loop->be->add_timer(loop->be, loop->shutdown_grace, 1, loop->hardstop_tw);
    }
}

/* Drain a snapshot of the deferred (run-soon) queue. */
static void hm_run_deferred(pTHX_ hm_loop *loop) {
    SSize_t n = av_len(loop->deferred) + 1;
    SSize_t i;
    if (!n) return;
    ENTER; SAVETMPS;
    for (i = 0; i < n; i++) {
        SV *cb = sv_2mortal(av_shift(loop->deferred));
        dSP;
        PUSHMARK(SP);
        PUTBACK;
        call_sv(cb, G_DISCARD);
    }
    FREETMPS; LEAVE;
}

/* Re-process connections that hit the fairness cap with requests still
 * buffered, now that everyone else has been serviced. */
static void hm_run_again(pTHX_ hm_loop *loop) {
    int n = loop->again_n;
    int i;
    if (!n) return;
    loop->again_n = 0;
    for (i = 0; i < n; i++) {
        hm_conn *c = loop->conns[loop->again[i].fd];
        if (c && c->id == loop->again[i].id && !c->awaiting) {
            hm_process(aTHX_ c);
            if (loop->conns[c->fd] == c) hm_flush(aTHX_ c);
        }
    }
}

static void hm_dispatch(pTHX_ hm_loop *loop, hm_event *ev) {
    switch (ev->kind) {
    case HM_EV_TIMER: {
        hm_tw *tw = (hm_tw *)ev->udata;
        if (!tw) return;
        if (tw->kind == HM_TW_SWEEP) { hm_sweep(aTHX_ loop); return; }
        if (tw->kind == HM_TW_HARDSTOP) { loop->stop = 1; return; }
        {
            SV *sv = tw->sv;
            int kind = tw->kind;
            free(tw);
            if (kind == HM_TW_FUTURE) {
                hmf_done0(aTHX_ sv);
            } else {
                dSP;
                ENTER; SAVETMPS; PUSHMARK(SP);
                PUTBACK;
                call_sv(sv, G_DISCARD);
                FREETMPS; LEAVE;
            }
            SvREFCNT_dec(sv);
        }
        return;
    }
    case HM_EV_SIGNAL:
        if (ev->fd == SIGUSR1) {
            fprintf(stderr,
                "Hyperman worker %d: requests=%lu accepts=%lu conns=%d "
                "bytes_out=%lu backend=%s%s\n",
                (int)getpid(),
                (unsigned long)loop->requests, (unsigned long)loop->accepts,
                loop->nconns, (unsigned long)loop->bytes_out,
                loop->be->name, loop->stopping ? " (draining)" : "");
            return;
        }
        hm_on_signal(aTHX_ loop);
        return;
    case HM_EV_READ: {
        int fd = ev->fd;
        hm_conn *c;
        if (fd == loop->listen_fd)      { hm_accept(aTHX_ loop); return; }
        if ((c = loop->conns[fd])) {
            if (c->tls_hs)              hm_tls_handshake(aTHX_ c);
            else                        hm_readable(aTHX_ c);
        }
        else if (loop->io_r[fd].sv)     hm_io_event(aTHX_ loop, &loop->io_r[fd]);
        return;
    }
    case HM_EV_WRITE: {
        int fd = ev->fd;
        hm_conn *c;
        if ((c = loop->conns[fd])) {
            /* TLS post-handshake: route writes through hm_readable so a
             * blocked SSL op in either direction is re-driven (it flushes
             * pending output at the end); plain conns just flush. */
            if (c->tls_hs)              hm_tls_handshake(aTHX_ c);
            else if (c->ssl)            hm_readable(aTHX_ c);
            else                        hm_flush(aTHX_ c);
        }
        else if (loop->io_w[fd].sv)     hm_io_event(aTHX_ loop, &loop->io_w[fd]);
        return;
    }
    }
}

/* Run the loop until ->stop, or (when awaiting) until $until is ready.
 * Re-entrant: ->get/->await inside a handler pumps this same loop, so the
 * worker keeps serving other connections while awaiting. */
static void hm_loop_run(pTHX_ hm_loop *loop, SV *until) {
    hm_loop *prev = hm_cur_loop;
    hm_event evs[HM_MAXEV];
    hm_cur_loop = loop;
    loop->running++;
    loop->stop = 0;
    for (;;) {
        double timeout = -1.0;
        int n, i;
        loop->now = time(NULL);
        if (loop->recycle_pending && !loop->stopping) {
            loop->recycle_pending = 0;
            hm_on_signal(aTHX_ loop);   /* max_requests recycle: drain + exit */
        }
        hm_run_deferred(aTHX_ loop);
        hm_run_again(aTHX_ loop);
        if (loop->stop) break;
        if (until && hmf_state(aTHX_ until) != HMF_PENDING) break;
        if (av_len(loop->deferred) >= 0 || loop->again_n) timeout = 0.0;
        n = loop->be->wait(loop->be, evs, HM_MAXEV, timeout);
        if (n < 0) { if (errno == EINTR) continue; break; }
        for (i = 0; i < n; i++) hm_dispatch(aTHX_ loop, &evs[i]);
        if (loop->log_fd >= 0 && loop->log_len) hm_log_flush(loop);
        if (loop->stop) break;
        if (until && hmf_state(aTHX_ until) != HMF_PENDING) break;
    }
    loop->stop = 0;
    loop->running--;
    hm_cur_loop = prev;
}

/* ---- loop lifecycle ------------------------------------------------------- */

static hm_loop *hm_loop_new(pTHX_ const char *backend_name) {
    hm_loop *loop = (hm_loop *)calloc(1, sizeof(hm_loop));
    if (!loop) return NULL;
    if (!backend_name || !*backend_name)
        backend_name = getenv("HYPERMAN_BACKEND");
    loop->be = hm_backend_create(backend_name);
    if (!loop->be) { free(loop); return NULL; }
    loop->conns = (hm_conn **)calloc(HM_MAXFD, sizeof(hm_conn *));
    loop->io_r  = (hm_iow *)calloc(HM_MAXFD, sizeof(hm_iow));
    loop->io_w  = (hm_iow *)calloc(HM_MAXFD, sizeof(hm_iow));
    loop->deferred = newAV();
    loop->listen_fd = -1;
    loop->log_fd = -1;
    loop->now = time(NULL);
    loop->idle_timeout   = 60.0;
    loop->header_timeout = 30.0;
    loop->max_pipeline   = 32;
    loop->max_read       = 16 * 1024 * 1024;   /* request ceiling */
    loop->shutdown_grace = 30.0;
    return loop;
}

static void hm_loop_free(pTHX_ hm_loop *loop) {
    int i;
    if (!loop) return;
    for (i = 0; i < HM_MAXFD; i++) {
        if (loop->conns[i]) {
            hm_conn *c = loop->conns[i];
            close(c->fd);
            if (c->h2)     hm_h2_free(aTHX_ c->h2);
            if (c->io_sv)  SvREFCNT_dec(c->io_sv);
            if (c->resp_f) SvREFCNT_dec(c->resp_f);
            if (c->env_sv) SvREFCNT_dec(c->env_sv);
            if (c->wbuf) free(c->wbuf);
            if (c->rbuf) free(c->rbuf);
            free(c);
            loop->conns[i] = NULL;
        }
        if (loop->io_r[i].sv) SvREFCNT_dec(loop->io_r[i].sv);
        if (loop->io_w[i].sv) SvREFCNT_dec(loop->io_w[i].sv);
    }
    while (loop->pool) {
        hm_conn *c = loop->pool;
        loop->pool = c->pool_next;
        if (c->wbuf) free(c->wbuf);
        if (c->rbuf) free(c->rbuf);
        free(c);
    }
    if (loop->log_fd >= 0) { hm_log_flush(loop); close(loop->log_fd); }
    if (loop->log_buf) free(loop->log_buf);
    if (loop->host) free(loop->host);
    if (loop->self_sv) SvREFCNT_dec(loop->self_sv);
    if (loop->log_cb)  SvREFCNT_dec(loop->log_cb);
    if (loop->app) SvREFCNT_dec(loop->app);
    SvREFCNT_dec((SV *)loop->deferred);
    if (loop->again) free(loop->again);
    if (loop->sweep_tw) free(loop->sweep_tw);
    if (loop->hardstop_tw) free(loop->hardstop_tw);
    loop->be->destroy(loop->be);
    free(loop->conns);
    free(loop->io_r);
    free(loop->io_w);
    free(loop);
}

/* Attach the PSGI server to a loop: listener, shutdown/stats signals via
 * the backend's signal watcher, and the timeout sweep timer. */
static void hm_attach_server(pTHX_ hm_loop *loop, SV *app, int listen_fd,
                             const char *host, int port) {
    loop->app = SvREFCNT_inc(app);
    loop->listen_fd = listen_fd;
    loop->host = strdup(host && *host ? host : "0.0.0.0");
    loop->port = port;
    loop->be->add_io(loop->be, listen_fd, HM_EV_READ, 0);
    signal(SIGPIPE, SIG_IGN);
    signal(SIGTERM, SIG_IGN);      /* delivered through the backend instead */
    signal(SIGINT,  SIG_IGN);
    signal(SIGUSR1, SIG_IGN);
    loop->be->add_signal(loop->be, SIGTERM);
    loop->be->add_signal(loop->be, SIGINT);
    loop->be->add_signal(loop->be, SIGUSR1);
    loop->sweep_tw = (hm_tw *)calloc(1, sizeof(hm_tw));
    loop->sweep_tw->kind = HM_TW_SWEEP;
    loop->sweep_tw->loop = loop;
    loop->be->add_timer(loop->be, HM_SWEEP_SECS, 0, loop->sweep_tw);
}

/* register a timer watcher resolving a Future / running a callback */
static void hm_add_timer_watch(pTHX_ hm_loop *loop, double secs, SV *sv, int kind) {
    hm_tw *tw = (hm_tw *)calloc(1, sizeof(hm_tw));
    tw->kind = kind;
    tw->sv   = SvREFCNT_inc(sv);
    tw->loop = loop;
    loop->be->add_timer(loop->be, secs, 1, tw);
}

static void hm_add_io_watch(pTHX_ hm_loop *loop, int fd, const char *mode,
                            SV *sv, int is_cb) {
    hm_iow *slot;
    int mask;
    if (fd < 0 || fd >= HM_MAXFD) croak("Hyperman: bad fd %d", fd);
    if (mode[0] == 'w') { slot = &loop->io_w[fd]; mask = HM_EV_WRITE; }
    else                { slot = &loop->io_r[fd]; mask = HM_EV_READ;  }
    if (slot->sv) SvREFCNT_dec(slot->sv);
    slot->sv    = SvREFCNT_inc(sv);
    slot->is_cb = (unsigned char)is_cb;
    loop->be->add_io(loop->be, fd, mask, is_cb ? 0 : 1);
}

static hm_loop *hm_need_loop(void) {
    if (!hm_cur_loop)
        croak("Hyperman: no event loop is running in this process");
    return hm_cur_loop;
}

/* ---- listener + process model -------------------------------------------- */

/* Create, bind, and listen a non-blocking TCP socket. Returns fd or -1. */
static int hm_make_listener(const char *host, int port, int reuseport) {
    struct sockaddr_in addr;
    int one = 1;
    int fd = socket(PF_INET, SOCK_STREAM, 0);
    if (fd < 0) return -1;
    setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &one, sizeof(one));
#ifdef SO_REUSEPORT
    if (reuseport)
        setsockopt(fd, SOL_SOCKET, SO_REUSEPORT, &one, sizeof(one));
#else
    (void)reuseport;
#endif
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port   = htons((unsigned short)port);
    addr.sin_addr.s_addr = inet_addr(host);
    if (addr.sin_addr.s_addr == INADDR_NONE) addr.sin_addr.s_addr = htonl(INADDR_ANY);
    if (bind(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) { close(fd); return -1; }
    if (listen(fd, SOMAXCONN) < 0) { close(fd); return -1; }
    hm_set_nonblock(fd);
    return fd;
}

/* Supervisor signal flags: TERM/INT = shut the pool down, HUP/USR2 =
 * recycle workers with zero downtime, USR1 = stats dump. */
static volatile sig_atomic_t hm_sup_term = 0;
static volatile sig_atomic_t hm_sup_hup  = 0;
static volatile sig_atomic_t hm_sup_usr1 = 0;
static void hm_sup_sig(int sig) {
    if (sig == SIGHUP || sig == SIGUSR2) hm_sup_hup = 1;
    else if (sig == SIGUSR1)             hm_sup_usr1 = 1;
    else if (sig == SIGCHLD)             ;   /* no-op: just wakes sigsuspend() */
    else                                 hm_sup_term = 1;
}

/* Everything a worker needs; one struct so spawn plumbing stays sane. */
typedef struct {
    SV         *app;
    int         listen_fd;
    const char *host;
    int         port;
    double      idle_t, header_t, grace;
    int         max_pipe, reuseport, affinity, nworkers, http2;
    UV          max_requests;
    SV         *log_cb;              /* access_log coderef, or NULL          */
    int         log_fd;             /* fast access-log fd, or -1            */
    const char *log_path;           /* access_log file to open (parent), or NULL */
    const char *tls_cert, *tls_key, *tls_ca;
    int         tls_verify;
    SV         *tls_sni;
    void       *tls_ctx;
} hm_worker_cfg;

static void hm_worker(pTHX_ const hm_worker_cfg *cfg, int listen_fd) {
    hm_loop *loop = hm_loop_new(aTHX_ NULL);
    if (!loop) croak("Hyperman: cannot create event loop");
    if (cfg->idle_t   > 0) loop->idle_timeout   = cfg->idle_t;
    if (cfg->header_t > 0) loop->header_timeout = cfg->header_t;
    if (cfg->max_pipe > 0) loop->max_pipeline   = cfg->max_pipe;
    if (cfg->grace    > 0) loop->shutdown_grace = cfg->grace;
    loop->max_requests = cfg->max_requests;
    loop->http2 = cfg->http2;
    loop->tls_ctx = cfg->tls_ctx;
    if (cfg->log_fd >= 0)
        loop->log_fd = cfg->log_fd;               /* fast C writer wins */
    else if (cfg->log_cb && SvOK(cfg->log_cb))
        loop->log_cb = SvREFCNT_inc(cfg->log_cb);
    hm_attach_server(aTHX_ loop, cfg->app, listen_fd, cfg->host, cfg->port);
    hm_loop_run(aTHX_ loop, NULL);
    hm_loop_free(aTHX_ loop);
}

/* Fork one worker. With reuseport each worker binds its own listener; with
 * affinity (Linux) worker widx is pinned to core widx % ncpu. */
static pid_t hm_spawn(pTHX_ const hm_worker_cfg *cfg, int widx) {
    pid_t pid = fork();
    if (pid == 0) {
        int fd = cfg->listen_fd;
#if defined(__linux__) && defined(CPU_SET)
        if (cfg->affinity) {
            long ncpu = sysconf(_SC_NPROCESSORS_ONLN);
            if (ncpu > 0) {
                cpu_set_t set;
                CPU_ZERO(&set);
                CPU_SET((int)(widx % ncpu), &set);
                sched_setaffinity(0, sizeof(set), &set);
            }
        }
#else
        (void)widx;
#endif
        if (cfg->reuseport) {
            fd = hm_make_listener(cfg->host, cfg->port, 1);
            if (fd < 0) _exit(1);
        }
        hm_worker(aTHX_ cfg, fd);
        _exit(0);
    }
    return pid;
}

/* The full server: validate + bind, then either run in-process (1 worker)
 * or supervise a pool (respawn with backoff, HUP/USR2 recycle, USR1 stats,
 * TERM/INT bounded drain). */
static void hm_run_server(pTHX_ hm_worker_cfg *cfg) {
    int workers = cfg->nworkers;

    if (!hm_empty_input)
        hm_empty_input = hm_new_input(aTHX_ "", 0);   /* inherited by workers */
    if (workers < 1) {                     /* default: one per CPU */
        long n = sysconf(_SC_NPROCESSORS_ONLN);
        workers = n > 0 ? (int)n : 1;
    }
    cfg->nworkers = workers;
#ifndef SO_REUSEPORT
    if (cfg->reuseport) croak("Hyperman: SO_REUSEPORT not supported on this platform");
#endif
#ifndef __linux__
    if (cfg->affinity) croak("Hyperman: CPU affinity is Linux-only");
#endif

    /* build the TLS context before forking, so a bad cert/key fails fast and
     * the (read-only) SSL_CTX is shared copy-on-write across workers */
    if (cfg->tls_cert && cfg->tls_key) {
        cfg->tls_ctx = hm_tls_ctx_build(aTHX_ cfg->tls_cert, cfg->tls_key,
                                        cfg->tls_ca, cfg->tls_verify,
                                        cfg->tls_sni, cfg->http2);
        if (!cfg->tls_ctx)
            croak("Hyperman: TLS: could not initialise from cert '%s' / key '%s'",
                  cfg->tls_cert, cfg->tls_key);
    }

    /* Open the access-log file once in the parent so all workers share (and
     * O_APPEND to) the same fd - whole-line writes stay atomic between them. */
    if (cfg->log_path && cfg->log_fd < 0) {
        cfg->log_fd = open(cfg->log_path,
                           O_WRONLY | O_CREAT | O_APPEND | O_CLOEXEC, 0644);
        if (cfg->log_fd < 0)
            croak("Hyperman: open access_log '%s': %s",
                  cfg->log_path, strerror(errno));
    }

    cfg->listen_fd = hm_make_listener(cfg->host, cfg->port, cfg->reuseport);
    if (cfg->listen_fd < 0)
        croak("Hyperman: bind %s:%d: %s", cfg->host, cfg->port, strerror(errno));

    if (workers == 1) {
        /* dev mode: run the worker in this process, no supervisor */
        hm_worker(aTHX_ cfg, cfg->listen_fd);
        return;
    }

    {
        int i;
        int backoff = 0;
        struct sigaction sa;

        for (i = 0; i < workers; i++) {
            pid_t pid = hm_spawn(aTHX_ cfg, i);
            if (pid < 0) croak("Hyperman: fork: %s", strerror(errno));
            hm_child_start[hm_nchildren] = time(NULL);
            hm_children[hm_nchildren++] = pid;
        }

        memset(&sa, 0, sizeof(sa));
        sa.sa_handler = hm_sup_sig;      /* no SA_RESTART: waitpid must EINTR */
        sigemptyset(&sa.sa_mask);
        sigaction(SIGTERM, &sa, NULL);
        sigaction(SIGINT,  &sa, NULL);
        sigaction(SIGHUP,  &sa, NULL);
        sigaction(SIGUSR1, &sa, NULL);
        sigaction(SIGUSR2, &sa, NULL);
        /* SIGCHLD must be delivered so sigsuspend() below wakes when a worker
         * exits; hm_sup_sig() treats it as a no-op wakeup. */
        sigaction(SIGCHLD, &sa, NULL);

        /* Race-free supervision: keep the acted-on signals blocked, check the
         * flags, reap without blocking, then sigsuspend() to wait for the next
         * signal atomically. A plain blocking waitpid() has a lost-wakeup
         * window - a signal arriving between a flag check and re-entering
         * waitpid() goes unserviced until some child happens to exit, which
         * for USR1 (stats dump) on an otherwise idle pool could be never. */
        {
            sigset_t block, orig;
            sigemptyset(&block);
            sigaddset(&block, SIGTERM); sigaddset(&block, SIGINT);
            sigaddset(&block, SIGHUP);  sigaddset(&block, SIGUSR1);
            sigaddset(&block, SIGUSR2); sigaddset(&block, SIGCHLD);
            sigprocmask(SIG_BLOCK, &block, &orig);

            for (;;) {
                int   st;
                pid_t pid;

                if (hm_sup_term) {
                    for (i = 0; i < hm_nchildren; i++)
                        kill(hm_children[i], SIGTERM);
                    /* workers self-bound their drain with shutdown_grace */
                    while (waitpid(-1, &st, 0) > 0) { }
                    break;
                }

                if (hm_sup_usr1) {
                    hm_sup_usr1 = 0;
                    for (i = 0; i < hm_nchildren; i++)
                        kill(hm_children[i], SIGUSR1);
                }

                if (hm_sup_hup) {
                    pid_t old[1024];
                    int nold = hm_nchildren;
                    memcpy(old, hm_children, nold * sizeof(pid_t));
                    hm_sup_hup = 0;
                    hm_nchildren = 0;
                    for (i = 0; i < workers; i++) {
                        hm_child_start[hm_nchildren] = time(NULL);
                        hm_children[hm_nchildren++] = hm_spawn(aTHX_ cfg, i);
                    }
                    for (i = 0; i < nold; i++)
                        kill(old[i], SIGTERM);       /* drain gracefully */
                }

                /* reap every exited child without blocking, respawning the
                 * live set. Recycled workers exiting are expected; only a
                 * death in the live set is respawned. Abnormal quick deaths
                 * (crash loops) back off exponentially; clean exits respawn
                 * immediately. */
                while ((pid = waitpid(-1, &st, WNOHANG)) > 0) {
                    int live = 0;
                    time_t started = 0;
                    for (i = 0; i < hm_nchildren; i++) {
                        if (hm_children[i] == pid) {
                            started = hm_child_start[i];
                            hm_nchildren--;
                            hm_children[i]    = hm_children[hm_nchildren];
                            hm_child_start[i] = hm_child_start[hm_nchildren];
                            live = 1;
                            break;
                        }
                    }
                    if (!live) continue;

                    {
                        int crashed = !(WIFEXITED(st) && WEXITSTATUS(st) == 0);
                        if (crashed && time(NULL) - started < 5) {
                            backoff = backoff ? backoff * 2 : 1;
                            if (backoff > 30) backoff = 30;
                            /* keep TERM responsive during crash-loop backoff */
                            sigprocmask(SIG_SETMASK, &orig, NULL);
                            sleep((unsigned)backoff);
                            sigprocmask(SIG_BLOCK, &block, NULL);
                        } else if (!crashed || time(NULL) - started >= 5) {
                            backoff = 0;
                        }
                    }
                    {
                        int slot = hm_nchildren;
                        hm_child_start[slot] = time(NULL);
                        hm_children[slot] = hm_spawn(aTHX_ cfg, slot);
                        hm_nchildren = slot + 1;
                    }
                    if (hm_sup_term) break;   /* TERM arrived during backoff */
                }

                if (hm_sup_term) continue;    /* serviced at the top of the loop */

                /* atomically unblock and sleep until the next signal */
                sigsuspend(&orig);
            }

            sigprocmask(SIG_SETMASK, &orig, NULL);
        }
    }
}

/* loop object <-> pointer */
static hm_loop *hm_loop_from_sv(pTHX_ SV *sv) {
    if (!(sv && SvROK(sv) && sv_derived_from(sv, "Hyperman::Loop")))
        croak("not a Hyperman::Loop");
    return INT2PTR(hm_loop *, SvIV(SvRV(sv)));
}

static SV *hm_loop_to_sv(pTHX_ hm_loop *loop) {
    SV *rv = newRV_noinc(newSViv(PTR2IV(loop)));
    sv_bless(rv, gv_stashpv("Hyperman::Loop", GV_ADD));
    return rv;
}

/* install_await: $Hyperman::Future::AWAIT pumps this loop */
XS_INTERNAL(hm_xs_await_cb);
XS_INTERNAL(hm_xs_await_cb) {
    dXSARGS;
    hm_clos *cl = hm_clos_of(aTHX_ cv);
    if (!cl || items < 1) XSRETURN_EMPTY;
    hm_loop_run(aTHX_ hm_loop_from_sv(aTHX_ cl->a), ST(0));
    XSRETURN_EMPTY;
}

#endif /* HM_CORE_H */
