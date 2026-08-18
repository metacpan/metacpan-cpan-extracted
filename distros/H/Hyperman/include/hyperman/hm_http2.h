#ifndef HM_HTTP2_H
#define HM_HTTP2_H

/* HTTP/2 (cleartext h2c) via nghttp2. Enabled by Makefile.PL when nghttp2 is
 * found (-DHM_HAVE_NGHTTP2, -lnghttp2); otherwise the entry points compile to
 * stubs and `http2 => 1` errors at runtime.
 *
 * Included from hm_core.h after the connection/HTTP/PSGI helpers it reuses
 * (hm_wb_put, hm_flush, hm_call_app, hm_new_input, hm_slurp_body,
 * hm_pct_decode, hm_access_log, hm_500_resp) and the Future machinery
 * (hm_closure, hm_any_on_ready, hm_any_state, hmf_*). A connection in h2 mode
 * holds one nghttp2 session; each stream is an independent request whose
 * response resolves through the same sync/Future/streaming paths as HTTP/1.1,
 * with nghttp2 owning framing, HPACK, flow control, and multiplexing. */

#ifdef HM_HAVE_NGHTTP2

#include <nghttp2/nghttp2.h>

typedef struct hm_h2_stream {
    int32_t  id;
    HV      *env;            /* being built (moved out at dispatch)   */
    SV      *env_rv;         /* kept while awaiting, for access_log   */
    SV      *body;           /* accumulating request body, or NULL    */
    SV      *resp_body;      /* response bytes the data provider feeds */
    size_t   resp_off;       /* data-provider read cursor             */
    SV      *src_sv;         /* streamed file body: owned, or NULL    */
    int      src_fd;         /* its fd, read at src_off               */
    off_t    src_off;
    UV       src_rem;        /* bytes still owed on the stream        */
    size_t   blen;           /* response body length (logging)        */
    int      status;         /* response status (logging)             */
    int      resp_status;    /* streaming: stashed until close        */
    SV      *resp_headers;   /* streaming: stashed headers arrayref   */
    int      awaiting;       /* parked on a Future                    */
    struct hm_h2_stream *next;
} hm_h2_stream;

typedef struct hm_h2_sess {
    nghttp2_session *session;
    hm_conn         *conn;
    hm_h2_stream    *streams;   /* singly-linked, for cleanup */
} hm_h2_sess;

static int  hm_h2_flush_send(pTHX_ hm_h2_sess *s);
static void hm_h2_respond(pTHX_ hm_h2_sess *s, hm_h2_stream *st, SV *resp);

/* the 24-byte HTTP/2 connection preface */
static const char HM_H2_PREFACE[24] =
    { 'P','R','I',' ','*',' ','H','T','T','P','/','2','.','0','\r','\n',
      '\r','\n','S','M','\r','\n','\r','\n' };

/* ---- request: headers -> $env ------------------------------------------- */

static void hm_h2_env_init(pTHX_ hm_h2_sess *s, HV *env) {
    hm_loop *loop = s->conn->loop;
    hm_listener *lst = s->conn->lst;
    AV *ver = newAV();
    /* the shared header-key table lives in hm_core.h and is filled by
     * hm_env_init; a process that only ever speaks HTTP/2 has to fill it
     * from here or hm_hdrk_lookup never engages (it would fall back
     * safely, just without the point of it) */
    hm_env_init(aTHX);
    av_push(ver, newSViv(1)); av_push(ver, newSViv(1));
    hv_stores(env, "SCRIPT_NAME",       newSVpvs(""));
    hv_stores(env, "SERVER_PROTOCOL",   newSVpvs("HTTP/2"));
    hv_stores(env, "SERVER_NAME",       newSVpv(lst && lst->host ? lst->host : "0.0.0.0", 0));
    hv_stores(env, "SERVER_PORT",       newSViv(lst ? lst->port : 0));
    if (s->conn->peer[0]) {
        hv_stores(env, "REMOTE_ADDR", newSVpv(s->conn->peer, 0));
        hv_stores(env, "REMOTE_HOST", newSVpv(s->conn->peer, 0));
    }
    if (s->conn->peer_port) hv_stores(env, "REMOTE_PORT", newSViv(s->conn->peer_port));
    hv_stores(env, "QUERY_STRING",      newSVpvs(""));
    hv_stores(env, "psgi.version",      newRV_noinc((SV *)ver));
    hv_stores(env, "psgi.url_scheme",   newSVpv(s->conn->ssl ? "https" : "http", 0));
    hv_stores(env, "psgi.multithread",  newSViv(0));
    hv_stores(env, "psgi.multiprocess", newSViv(1));
    hv_stores(env, "psgi.run_once",     newSViv(0));
    hv_stores(env, "psgi.streaming",    newSViv(1));
    hv_stores(env, "psgi.nonblocking",  newSViv(1));
    hv_stores(env, "psgi.errors",       newRV_inc((SV *)PL_stderrgv));
    if (!loop->self_sv) loop->self_sv = hm_loop_to_sv(aTHX_ loop);
    hv_stores(env, "psgix.loop",        SvREFCNT_inc(loop->self_sv));
}

static void hm_h2_add_header(pTHX_ hm_h2_stream *st,
                             const char *nm, size_t nl,
                             const char *vl, size_t vlen) {
    HV *env = st->env;
    if (nl && nm[0] == ':') {                       /* pseudo-headers */
        if (nl == 7 && memcmp(nm, ":method", 7) == 0)
            hv_stores(env, "REQUEST_METHOD", newSVpvn(vl, vlen));
        else if (nl == 7 && memcmp(nm, ":scheme", 7) == 0)
            hv_store(env, "psgi.url_scheme", 15, newSVpvn(vl, vlen), 0);
        else if (nl == 10 && memcmp(nm, ":authority", 10) == 0) {
            hv_stores(env, "HTTP_HOST",   newSVpvn(vl, vlen));
            hv_stores(env, "SERVER_NAME", newSVpvn(vl, vlen));
        }
        else if (nl == 5 && memcmp(nm, ":path", 5) == 0) {
            const char *q = (const char *)memchr(vl, '?', vlen);
            size_t pl = q ? (size_t)(q - vl) : vlen;
            hv_stores(env, "REQUEST_URI", newSVpvn(vl, vlen));
            hv_stores(env, "PATH_INFO",   hm_pct_decode(aTHX_ vl, pl));
            if (q) hv_stores(env, "QUERY_STRING",
                             newSVpvn(q + 1, vlen - pl - 1));
        }
        return;
    }
    if (nl == 14 && hm_strncasecmp(nm, "content-length", 14) == 0) {
        hv_stores(env, "CONTENT_LENGTH", newSVpvn(vl, vlen));
    } else if (nl == 12 && hm_strncasecmp(nm, "content-type", 12) == 0) {
        hv_stores(env, "CONTENT_TYPE", newSVpvn(vl, vlen));
    } else if (nl + 5 < 300) {
        char keybuf[300];
        size_t i;
        SV **old;
        memcpy(keybuf, "HTTP_", 5);
        for (i = 0; i < nl; i++) {
            unsigned char ch = (unsigned char)nm[i];
            if (ch >= 'a' && ch <= 'z') ch -= 32;
            else if (ch == '-') ch = '_';
            keybuf[5 + i] = (char)ch;
        }
        {   /* common headers store through the process-lifetime shared key
             * SVs (hm_core.h), skipping the per-request hash + HEK churn */
            SV *ksv = hm_hdrk_lookup(keybuf, nl + 5);
            if (ksv) {
                HE *he = hv_fetch_ent(env, ksv, 0, 0);
                if (he) { sv_catpvs(HeVAL(he), ", ");
                          sv_catpvn(HeVAL(he), vl, vlen); }
                else (void)hv_store_ent(env, ksv, newSVpvn(vl, vlen), 0);
            } else {
                old = hv_fetch(env, keybuf, (I32)(nl + 5), 0);
                if (old) { sv_catpvs(*old, ", "); sv_catpvn(*old, vl, vlen); }
                else hv_store(env, keybuf, (I32)(nl + 5), newSVpvn(vl, vlen), 0);
            }
        }
    }
}

/* ---- response ------------------------------------------------------------ */

static SV *hm_h2_body_sv(pTHX_ SV **s2, size_t *blen) {
    SV *out = newSVpvs("");
    if (s2 && SvROK(*s2) && SvTYPE(SvRV(*s2)) == SVt_PVAV) {
        AV *b = (AV *)SvRV(*s2);
        SSize_t i, n = av_len(b) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(b, i, 0);
            if (e) { STRLEN l; const char *p = SvPV(*e, l); sv_catpvn(out, p, l); }
        }
    } else if (s2 && SvROK(*s2)) {
        SV *slurp = hm_slurp_body(aTHX_ *s2);
        sv_catsv(out, slurp);
        SvREFCNT_dec(slurp);
    }
    { STRLEN l; (void)SvPV(out, l); *blen = l; }
    return out;
}

/* Move a liftable filehandle body onto the stream as an fd source the data
 * provider reads per window, instead of slurping it. Getline-only sources
 * stay on the slurp: the provider's buffer is fixed-size and a getline
 * chunk is not. Returns 1 when st owns a source. */
static int hm_h2_body_src(pTHX_ hm_h2_stream *st, SV **s2, AV *hav) {
    hm_bsrc bs;
    UV clv = 0;
    int cl_seen;
    if (!(s2 && SvROK(*s2)) || SvTYPE(SvRV(*s2)) == SVt_PVAV) return 0;
    cl_seen = hm_hav_clen(aTHX_ hav, &clv);
    memset(&bs, 0, sizeof bs);
    if (!hm_bsrc_lift(aTHX_ *s2, &bs, cl_seen, clv)) return 0;
    if (bs.kind != 1) { hm_bsrc_release(aTHX_ &bs); return 0; }
    st->src_sv  = bs.sv;                          /* ownership moves */
    st->src_fd  = bs.fd;
    st->src_off = bs.off;
    st->src_rem = bs.remaining;
    st->blen    = (size_t)bs.remaining;
    return 1;
}

static void hm_h2_src_free(pTHX_ hm_h2_stream *st) {
    hm_bsrc bs;
    if (!st->src_sv) return;
    memset(&bs, 0, sizeof bs);
    bs.kind = 1;
    bs.fd   = st->src_fd;
    bs.sv   = st->src_sv;
    hm_bsrc_release(aTHX_ &bs);
    st->src_sv = NULL;
    st->src_rem = 0;
}

static ssize_t hm_h2_data_read(nghttp2_session *ses, int32_t sid, uint8_t *buf,
                               size_t length, uint32_t *data_flags,
                               nghttp2_data_source *source, void *ud) {
    dTHX;
    hm_h2_stream *st = (hm_h2_stream *)source->ptr;
    STRLEN blen = 0;
    const char *bp = "";
    size_t remain, n;
    (void)ses; (void)sid; (void)ud;
    if (st->src_sv) {                 /* file source: read per window */
        size_t want = st->src_rem < length ? (size_t)st->src_rem : length;
        ssize_t got = want ? hm_os_pread(st->src_fd, buf, want, st->src_off) : 0;
        if (got < 0) got = 0;
        st->src_off += got;
        st->src_rem -= (UV)got;
        if (st->src_rem == 0 || got == 0) {
            /* spent - or truncated under us, in which case the promised
             * length cannot be met and ending the stream is all there is */
            st->src_rem = 0;
            *data_flags |= NGHTTP2_DATA_FLAG_EOF;
        }
        return (ssize_t)got;
    }
    if (st->resp_body) bp = SvPV(st->resp_body, blen);
    remain = blen - st->resp_off;
    n = remain < length ? remain : length;
    if (n) memcpy(buf, bp + st->resp_off, n);
    st->resp_off += n;
    if (st->resp_off >= blen) *data_flags |= NGHTTP2_DATA_FLAG_EOF;
    return (ssize_t)n;
}

static int hm_h2_hopbyhop(const char *n, size_t l) {
    return (l == 10 && memcmp(n, "connection", 10) == 0)
        || (l == 10 && memcmp(n, "keep-alive", 10) == 0)
        || (l == 16 && memcmp(n, "proxy-connection", 16) == 0)
        || (l == 17 && memcmp(n, "transfer-encoding", 17) == 0)
        || (l ==  7 && memcmp(n, "upgrade", 7) == 0)
        || (l ==  2 && memcmp(n, "te", 2) == 0);
}

/* Submit status + headers with a data provider over st->resp_body. */
static void hm_h2_submit_response(pTHX_ hm_h2_sess *s, hm_h2_stream *st,
                                  int status, AV *hav) {
    SSize_t hn = hav ? av_len(hav) + 1 : 0;
    size_t maxnv = 1 + (size_t)(hn / 2);
    nghttp2_nv *nva = (nghttp2_nv *)hm_xmalloc(maxnv * sizeof(nghttp2_nv));
    char **freelist = (char **)hm_xmalloc(maxnv * sizeof(char *));
    size_t nfree = 0, n = 0;
    char sbuf[8];
    int sl;
    nghttp2_data_provider prd;
    SSize_t i;

    sl = snprintf(sbuf, sizeof(sbuf), "%d", status);
    nva[n].name = (uint8_t *)":status"; nva[n].namelen = 7;
    nva[n].value = (uint8_t *)sbuf; nva[n].valuelen = (size_t)sl;
    nva[n].flags = NGHTTP2_NV_FLAG_NONE; n++;

    for (i = 0; i + 1 < hn; i += 2) {
        SV **k = av_fetch(hav, i, 0);
        SV **v = av_fetch(hav, i + 1, 0);
        STRLEN kl, vl; const char *ks, *vs;
        char *lname; STRLEN j;
        if (!k || !v) continue;
        ks = SvPV(*k, kl); vs = SvPV(*v, vl);
        lname = (char *)hm_xmalloc(kl ? kl : 1);
        for (j = 0; j < kl; j++) {
            unsigned char ch = (unsigned char)ks[j];
            lname[j] = (ch >= 'A' && ch <= 'Z') ? (char)(ch + 32) : (char)ch;
        }
        if (hm_h2_hopbyhop(lname, kl)) { free(lname); continue; }
        freelist[nfree++] = lname;
        nva[n].name = (uint8_t *)lname; nva[n].namelen = kl;
        nva[n].value = (uint8_t *)vs;   nva[n].valuelen = vl;
        nva[n].flags = NGHTTP2_NV_FLAG_NONE; n++;
    }

    st->status = status;
    st->resp_off = 0;
    prd.source.ptr = st;
    prd.read_callback = hm_h2_data_read;
    nghttp2_submit_response(s->session, st->id, nva, n, &prd);   /* copies nv */
    s->conn->loop->bytes_out += st->blen;

    for (n = 0; n < nfree; n++) free(freelist[n]);
    free(freelist);
    free(nva);
}

static void hm_h2_submit_status(pTHX_ hm_h2_sess *s, hm_h2_stream *st,
                                int status, const char *ctype) {
    AV *hav = newAV();
    av_push(hav, newSVpvs("content-type"));
    av_push(hav, newSVpv(ctype, 0));
    hm_h2_submit_response(aTHX_ s, st, status, hav);
    SvREFCNT_dec((SV *)hav);
}

/* psgi.streaming responder for h2: 3-arg delivers, 2-arg buffers via a
 * Hyperman::Writer (h2 form) that submits at close. */
XS_INTERNAL(hm_xs_h2responder);
XS_INTERNAL(hm_xs_h2responder) {
    dXSARGS;
    hm_clos *cl = hm_clos_of(aTHX_ cv);
    hm_loop *loop = hm_cur_loop;
    hm_conn *c;
    hm_h2_sess *s;
    hm_h2_stream *st;
    AV *rav, *hav = NULL;
    SSize_t n;
    SV **s0, **s1;
    int fd, status;
    UV gen;
    int32_t sid;
    if (!cl) XSRETURN_EMPTY;
    fd = (int)cl->i; gen = cl->u; sid = (int32_t)SvIV(cl->d);
    c = (loop && fd >= 0 && fd < HM_MAXFD) ? loop->conns[fd] : NULL;
    if (!(c && c->id == gen && c->h2)) XSRETURN_EMPTY;
    s = (hm_h2_sess *)c->h2;
    st = (hm_h2_stream *)nghttp2_session_get_stream_user_data(s->session, sid);
    if (!st) XSRETURN_EMPTY;
    if (items < 1 || !(SvROK(ST(0)) && SvTYPE(SvRV(ST(0))) == SVt_PVAV))
        croak("Hyperman responder expects an array reference");
    rav = (AV *)SvRV(ST(0));
    n = av_len(rav) + 1;
    s0 = av_fetch(rav, 0, 0);
    s1 = av_fetch(rav, 1, 0);
    status = s0 ? (int)SvIV(*s0) : 200;
    if (s1 && SvROK(*s1) && SvTYPE(SvRV(*s1)) == SVt_PVAV) hav = (AV *)SvRV(*s1);

    if (n >= 3) {
        SV **s2 = av_fetch(rav, 2, 0);
        if (st->resp_body) { SvREFCNT_dec(st->resp_body); st->resp_body = NULL; }
        hm_h2_src_free(aTHX_ st);
        if (!hm_h2_body_src(aTHX_ st, s2, hav))
            st->resp_body = hm_h2_body_sv(aTHX_ s2, &st->blen);
        hm_h2_submit_response(aTHX_ s, st, status, hav);
        hm_h2_flush_send(aTHX_ s);
        XSRETURN_EMPTY;
    }
    /* 2-arg: begin a streamed body, return a writer */
    st->resp_status = status;
    if (hav) st->resp_headers = newRV_inc((SV *)hav);
    if (!st->resp_body) st->resp_body = newSVpvs("");
    {
        AV *w = newAV();
        SV *wrv;
        av_push(w, newSViv(fd));
        av_push(w, newSVuv(gen));
        av_push(w, newSViv(sid));
        av_push(w, newSVpvs("h2"));
        wrv = newRV_noinc((SV *)w);
        sv_bless(wrv, gv_stashpv("Hyperman::Writer", GV_ADD));
        ST(0) = sv_2mortal(wrv);
        XSRETURN(1);
    }
}

static void hm_h2_run_delayed(pTHX_ hm_h2_sess *s, hm_h2_stream *st, SV *code) {
    SV *responder = hm_closure(aTHX_ hm_xs_h2responder, NULL, NULL, NULL,
                               sv_2mortal(newSViv(st->id)),
                               (IV)s->conn->fd, s->conn->id);
    dSP;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(responder);
    PUTBACK;
    call_sv(code, G_DISCARD | G_EVAL);
    if (SvTRUE(ERRSV)) {
        if (st->resp_body) SvREFCNT_dec(st->resp_body);
        st->resp_body = newSVpvs("Internal Server Error");
        st->blen = 21;
        hm_h2_submit_status(aTHX_ s, st, 500, "text/plain");
    }
    FREETMPS; LEAVE;
    SvREFCNT_dec(responder);
}

/* Writer (h2 form) called from xs/writer.xs. */
static void hm_h2_writer_write(pTHX_ int fd, UV gen, int32_t sid, SV *data) {
    hm_loop *loop = hm_cur_loop;
    hm_conn *c = (loop && fd >= 0 && fd < HM_MAXFD) ? loop->conns[fd] : NULL;
    hm_h2_sess *s;
    hm_h2_stream *st;
    if (!(c && c->id == gen && c->h2)) return;
    s = (hm_h2_sess *)c->h2;
    st = (hm_h2_stream *)nghttp2_session_get_stream_user_data(s->session, sid);
    if (!st) return;
    if (!st->resp_body) st->resp_body = newSVpvs("");
    sv_catsv(st->resp_body, data);
}

static void hm_h2_writer_close(pTHX_ int fd, UV gen, int32_t sid) {
    hm_loop *loop = hm_cur_loop;
    hm_conn *c = (loop && fd >= 0 && fd < HM_MAXFD) ? loop->conns[fd] : NULL;
    hm_h2_sess *s;
    hm_h2_stream *st;
    AV *hav;
    if (!(c && c->id == gen && c->h2)) return;
    s = (hm_h2_sess *)c->h2;
    st = (hm_h2_stream *)nghttp2_session_get_stream_user_data(s->session, sid);
    if (!st) return;
    { STRLEN l; if (st->resp_body) { (void)SvPV(st->resp_body, l); st->blen = l; } }
    hav = (st->resp_headers && SvROK(st->resp_headers))
        ? (AV *)SvRV(st->resp_headers) : NULL;
    hm_h2_submit_response(aTHX_ s, st, st->resp_status ? st->resp_status : 200, hav);
    hm_h2_flush_send(aTHX_ s);
}

/* sync array / streaming CV / invalid -> a response */
static void hm_h2_respond(pTHX_ hm_h2_sess *s, hm_h2_stream *st, SV *resp) {
    if (resp && SvROK(resp) && SvTYPE(SvRV(resp)) == SVt_PVAV) {
        AV *rav = (AV *)SvRV(resp);
        SV **s0 = av_fetch(rav, 0, 0);
        SV **s1 = av_fetch(rav, 1, 0);
        SV **s2 = av_fetch(rav, 2, 0);
        int status = s0 ? (int)SvIV(*s0) : 200;
        AV *hav = (s1 && SvROK(*s1) && SvTYPE(SvRV(*s1)) == SVt_PVAV)
                ? (AV *)SvRV(*s1) : NULL;
        if (st->resp_body) { SvREFCNT_dec(st->resp_body); st->resp_body = NULL; }
        hm_h2_src_free(aTHX_ st);
        if (!hm_h2_body_src(aTHX_ st, s2, hav))
            st->resp_body = hm_h2_body_sv(aTHX_ s2, &st->blen);
        hm_h2_submit_response(aTHX_ s, st, status, hav);
    } else if (resp && SvROK(resp) && SvTYPE(SvRV(resp)) == SVt_PVCV) {
        hm_h2_run_delayed(aTHX_ s, st, resp);
    } else {
        if (st->resp_body) SvREFCNT_dec(st->resp_body);
        st->resp_body = newSVpvs("Internal Server Error");
        st->blen = 21;
        hm_h2_submit_status(aTHX_ s, st, 500, "text/plain");
    }
}

/* Deliver a parked async response to a stream (from the Future continuation). */
static void hm_h2_deliver(pTHX_ int fd, UV gen, int32_t sid, SV *resp) {
    hm_loop *loop = hm_cur_loop;
    hm_conn *c = (loop && fd >= 0 && fd < HM_MAXFD) ? loop->conns[fd] : NULL;
    hm_h2_sess *s;
    hm_h2_stream *st;
    if (!(c && c->id == gen && c->h2)) return;
    s = (hm_h2_sess *)c->h2;
    st = (hm_h2_stream *)nghttp2_session_get_stream_user_data(s->session, sid);
    if (!st) return;
    st->awaiting = 0;
    hm_h2_respond(aTHX_ s, st, resp);
    if (hm_logging(loop) && st->env_rv)
        hm_access_log(aTHX_ loop, st->env_rv, st->status, (ssize_t)st->blen);
    hm_h2_flush_send(aTHX_ s);
}

XS_INTERNAL(hm_xs_h2park_cb);
XS_INTERNAL(hm_xs_h2park_cb) {
    dXSARGS;
    hm_clos *cl = hm_clos_of(aTHX_ cv);
    SV *f, *resp = NULL;
    IV st;
    int fd; UV gen; int32_t sid;
    if (!cl || items < 1) XSRETURN_EMPTY;
    f = ST(0);
    fd = (int)cl->i; gen = cl->u; sid = (int32_t)SvIV(cl->d);
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
            if (got) resp = sv_2mortal(got);
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
    hm_h2_deliver(aTHX_ fd, gen, sid, resp);
    XSRETURN_EMPTY;
}

/* ---- dispatch (a request stream is complete) ---------------------------- */

static void hm_h2_dispatch(pTHX_ hm_h2_sess *s, hm_h2_stream *st) {
    hm_conn *c = s->conn;
    hm_loop *loop = c->loop;
    HV *env = st->env;
    SV *env_rv, *resp;
    st->env = NULL;
    /* the h2c-upgrade stream arrives with psgi.input already set (built from
     * the original HTTP/1.1 request); normal streams get it from the body */
    if (!hv_exists(env, "psgi.input", 10)) {
        if (st->body)
            hv_stores(env, "psgi.input",
                      hm_new_input(aTHX_ SvPVX(st->body), SvCUR(st->body)));
        else
            hv_stores(env, "psgi.input", SvREFCNT_inc(hm_empty_input));
    }
    hv_stores(env, "psgix.input.buffered", newSViv(1));  /* :scalar handle, seekable */
    env_rv = newRV_noinc((SV *)env);
    resp = hm_call_app(aTHX_ loop, env_rv);
    loop->requests++;

    if (resp && hm_is_awaitable(aTHX_ resp)) {
        SV *cb = hm_closure(aTHX_ hm_xs_h2park_cb, NULL, NULL, NULL,
                            sv_2mortal(newSViv(st->id)), (IV)c->fd, c->id);
        st->awaiting = 1;
        st->env_rv = SvREFCNT_inc(env_rv);
        hm_any_on_ready(aTHX_ resp, cb);
        SvREFCNT_dec(cb);
        SvREFCNT_dec(resp);
        SvREFCNT_dec(env_rv);
        return;
    }

    hm_h2_respond(aTHX_ s, st, resp);
    if (hm_logging(loop))
        hm_access_log(aTHX_ loop, env_rv, st->status, (ssize_t)st->blen);
    if (resp) SvREFCNT_dec(resp);
    SvREFCNT_dec(env_rv);
}

/* ---- nghttp2 callbacks --------------------------------------------------- */

static ssize_t hm_h2_cb_send(nghttp2_session *ses, const uint8_t *data,
                             size_t length, int flags, void *ud) {
    dTHX;
    hm_h2_sess *s = (hm_h2_sess *)ud;
    (void)ses; (void)flags;
    hm_wb_put(s->conn, (const char *)data, length);
    return (ssize_t)length;
}

static int hm_h2_cb_begin_headers(nghttp2_session *ses,
                                  const nghttp2_frame *frame, void *ud) {
    dTHX;
    hm_h2_sess *s = (hm_h2_sess *)ud;
    hm_h2_stream *st;
    if (frame->hd.type != NGHTTP2_HEADERS
        || frame->headers.cat != NGHTTP2_HCAT_REQUEST)
        return 0;
    st = (hm_h2_stream *)hm_xcalloc(1, sizeof(hm_h2_stream));
    st->id = frame->hd.stream_id;
    st->env = newHV();
    /* pre-size past the ~25 fixed keys plus typical request headers, so no
     * request pays the 8 -> 16 -> 32 bucket splits (see hm_build_env) */
    hv_ksplit(st->env, 64);
    hm_h2_env_init(aTHX_ s, st->env);
    st->next = s->streams;
    s->streams = st;
    nghttp2_session_set_stream_user_data(ses, st->id, st);
    return 0;
}

static int hm_h2_cb_header(nghttp2_session *ses, const nghttp2_frame *frame,
                           const uint8_t *name, size_t namelen,
                           const uint8_t *value, size_t valuelen,
                           uint8_t flags, void *ud) {
    dTHX;
    hm_h2_stream *st;
    (void)ud; (void)flags;
    st = (hm_h2_stream *)nghttp2_session_get_stream_user_data(
             ses, frame->hd.stream_id);
    if (st && st->env)
        hm_h2_add_header(aTHX_ st, (const char *)name, namelen,
                         (const char *)value, valuelen);
    return 0;
}

static int hm_h2_cb_data_chunk(nghttp2_session *ses, uint8_t flags,
                               int32_t sid, const uint8_t *data,
                               size_t len, void *ud) {
    dTHX;
    hm_h2_stream *st;
    (void)ud; (void)flags;
    st = (hm_h2_stream *)nghttp2_session_get_stream_user_data(ses, sid);
    if (!st) return 0;
    if (!st->body) st->body = newSVpvn((const char *)data, len);
    else           sv_catpvn(st->body, (const char *)data, len);
    return 0;
}

static int hm_h2_cb_frame_recv(nghttp2_session *ses,
                               const nghttp2_frame *frame, void *ud) {
    dTHX;
    hm_h2_sess *s = (hm_h2_sess *)ud;
    if ((frame->hd.type == NGHTTP2_DATA || frame->hd.type == NGHTTP2_HEADERS)
        && (frame->hd.flags & NGHTTP2_FLAG_END_STREAM)) {
        hm_h2_stream *st = (hm_h2_stream *)nghttp2_session_get_stream_user_data(
                               ses, frame->hd.stream_id);
        if (st && st->env) hm_h2_dispatch(aTHX_ s, st);
    }
    return 0;
}

static void hm_h2_stream_free(pTHX_ hm_h2_sess *s, hm_h2_stream *st) {
    hm_h2_stream **pp = &s->streams;
    while (*pp) { if (*pp == st) { *pp = st->next; break; } pp = &(*pp)->next; }
    if (st->env)          SvREFCNT_dec((SV *)st->env);
    if (st->env_rv)       SvREFCNT_dec(st->env_rv);
    if (st->body)         SvREFCNT_dec(st->body);
    if (st->resp_body)    SvREFCNT_dec(st->resp_body);
    if (st->resp_headers) SvREFCNT_dec(st->resp_headers);
    hm_h2_src_free(aTHX_ st);
    free(st);
}

static int hm_h2_cb_stream_close(nghttp2_session *ses, int32_t sid,
                                 uint32_t error_code, void *ud) {
    dTHX;
    hm_h2_sess *s = (hm_h2_sess *)ud;
    hm_h2_stream *st = (hm_h2_stream *)nghttp2_session_get_stream_user_data(
                           ses, sid);
    (void)error_code;
    if (st) {
        nghttp2_session_set_stream_user_data(ses, sid, NULL);
        hm_h2_stream_free(aTHX_ s, st);
    }
    return 0;
}

/* ---- session lifecycle + loop entry points ------------------------------ */

static int hm_h2_flush_send(pTHX_ hm_h2_sess *s) {
    hm_conn *c = s->conn;
    if (nghttp2_session_send(s->session) != 0) {
        hm_close(aTHX_ c->loop, c);
        return -1;
    }
    if (c->loop->conns[c->fd] == c) return hm_flush(aTHX_ c);
    return -1;
}

/* Create the nghttp2 server session + callbacks and attach it to the
 * connection, without submitting SETTINGS yet (the upgrade path must call
 * nghttp2_session_upgrade2 in between). */
static int hm_h2_new_session(pTHX_ hm_conn *c) {
    hm_h2_sess *s = (hm_h2_sess *)hm_xcalloc(1, sizeof(hm_h2_sess));
    nghttp2_session_callbacks *cbs;
    if (!s) return -1;
    s->conn = c;
    if (nghttp2_session_callbacks_new(&cbs) != 0) { free(s); return -1; }
    nghttp2_session_callbacks_set_send_callback(cbs, hm_h2_cb_send);
    nghttp2_session_callbacks_set_on_begin_headers_callback(cbs, hm_h2_cb_begin_headers);
    nghttp2_session_callbacks_set_on_header_callback(cbs, hm_h2_cb_header);
    nghttp2_session_callbacks_set_on_data_chunk_recv_callback(cbs, hm_h2_cb_data_chunk);
    nghttp2_session_callbacks_set_on_frame_recv_callback(cbs, hm_h2_cb_frame_recv);
    nghttp2_session_callbacks_set_on_stream_close_callback(cbs, hm_h2_cb_stream_close);
    if (nghttp2_session_server_new(&s->session, cbs, s) != 0) {
        nghttp2_session_callbacks_del(cbs);
        free(s);
        return -1;
    }
    nghttp2_session_callbacks_del(cbs);
    c->h2 = s;
    c->keepalive = 1;             /* h2 connections are persistent */
    return 0;
}

static void hm_h2_submit_our_settings(hm_h2_sess *s) {
    nghttp2_settings_entry iv[1];
    iv[0].settings_id = NGHTTP2_SETTINGS_MAX_CONCURRENT_STREAMS;
    iv[0].value = 100;
    nghttp2_submit_settings(s->session, NGHTTP2_FLAG_NONE, iv, 1);
}

static int hm_h2_start(pTHX_ hm_conn *c) {
    if (hm_h2_new_session(aTHX_ c) < 0) return -1;
    hm_h2_submit_our_settings((hm_h2_sess *)c->h2);
    return 0;
}

/* base64url decode (no padding), RFC 7540's HTTP2-Settings encoding.
 * Returns decoded length, or -1 on a bad character / overflow. */
static int hm_b64url_decode(const char *in, size_t inlen,
                            unsigned char *out, size_t outcap) {
    static const signed char T[256] = {
        ['A']=0,['B']=1,['C']=2,['D']=3,['E']=4,['F']=5,['G']=6,['H']=7,
        ['I']=8,['J']=9,['K']=10,['L']=11,['M']=12,['N']=13,['O']=14,['P']=15,
        ['Q']=16,['R']=17,['S']=18,['T']=19,['U']=20,['V']=21,['W']=22,['X']=23,
        ['Y']=24,['Z']=25,['a']=26,['b']=27,['c']=28,['d']=29,['e']=30,['f']=31,
        ['g']=32,['h']=33,['i']=34,['j']=35,['k']=36,['l']=37,['m']=38,['n']=39,
        ['o']=40,['p']=41,['q']=42,['r']=43,['s']=44,['t']=45,['u']=46,['v']=47,
        ['w']=48,['x']=49,['y']=50,['z']=51,['0']=52,['1']=53,['2']=54,['3']=55,
        ['4']=56,['5']=57,['6']=58,['7']=59,['8']=60,['9']=61,['-']=62,['_']=63
    };
    unsigned int acc = 0; int bits = 0; size_t o = 0, i;
    for (i = 0; i < inlen; i++) {
        unsigned char ch = (unsigned char)in[i];
        signed char v;
        if (ch == '=' ) break;
        v = T[ch];
        if (v < 0) {
            if (ch == '\r' || ch == '\n' || ch == ' ' || ch == '\t') continue;
            return -1;
        }
        acc = (acc << 6) | (unsigned)v;
        bits += 6;
        if (bits >= 8) {
            bits -= 8;
            if (o >= outcap) return -1;
            out[o++] = (unsigned char)((acc >> bits) & 0xff);
        }
    }
    return (int)o;
}

/* HTTP/1.1 Upgrade: h2c. Called with the already-built PSGI env of the
 * original request (which carries method/path/headers/body via psgi.input)
 * and the raw base64url HTTP2-Settings value. Starts the session with
 * nghttp2_session_upgrade2 (the original request becomes stream 1) and
 * dispatches it. Caller has already written the 101 to the write buffer.
 * Returns 0 on success (connection is now in h2 mode), -1 on failure. */
static int hm_h2_start_upgrade(pTHX_ hm_conn *c, const char *settings,
                               size_t slen, HV *env, int is_head) {
    unsigned char sbuf[256];
    int n = hm_b64url_decode(settings, slen, sbuf, sizeof(sbuf));
    hm_h2_sess *s;
    hm_h2_stream *st;
    if (n < 0) return -1;
    if (hm_h2_new_session(aTHX_ c) < 0) return -1;
    s = (hm_h2_sess *)c->h2;
    st = (hm_h2_stream *)hm_xcalloc(1, sizeof(hm_h2_stream));
    st->id = 1;
    st->env = env;
    st->next = s->streams;
    s->streams = st;
    if (nghttp2_session_upgrade2(s->session, sbuf, (size_t)n, is_head, st) != 0)
        return -1;
    nghttp2_session_set_stream_user_data(s->session, 1, st);
    hm_h2_submit_our_settings(s);   /* server connection preface */
    hm_h2_dispatch(aTHX_ s, st);    /* env already carries psgi.input */
    return 0;
}

static void hm_h2_free(pTHX_ void *h2) {
    hm_h2_sess *s = (hm_h2_sess *)h2;
    if (!s) return;
    if (s->session) nghttp2_session_del(s->session);   /* fires stream_close */
    while (s->streams) hm_h2_stream_free(aTHX_ s, s->streams);
    free(s);
}

/* Feed buffered bytes to the session, flush output, close if finished. */
static void hm_h2_input(pTHX_ hm_conn *c) {
    hm_h2_sess *s = (hm_h2_sess *)c->h2;
    ssize_t rv = nghttp2_session_mem_recv(s->session,
                     (const uint8_t *)c->rbuf, c->rlen);
    if (rv < 0) { hm_close(aTHX_ c->loop, c); return; }
    if ((size_t)rv < c->rlen) memmove(c->rbuf, c->rbuf + rv, c->rlen - rv);
    c->rlen -= (size_t)rv;
    if (hm_h2_flush_send(aTHX_ s) < 0) return;
    if (!nghttp2_session_want_read(s->session)
        && !nghttp2_session_want_write(s->session))
        hm_close(aTHX_ c->loop, c);
}

/* On a new connection with http2 enabled: is this the h2 preface?
 * 1 = started (input already fed), -1 = matches, need more bytes, 0 = not h2. */
static int hm_h2_detect(pTHX_ hm_conn *c) {
    size_t n = c->rlen < sizeof(HM_H2_PREFACE)
             ? c->rlen : sizeof(HM_H2_PREFACE);
    if (memcmp(c->rbuf, HM_H2_PREFACE, n) != 0) return 0;
    if (n < sizeof(HM_H2_PREFACE)) return -1;
    if (hm_h2_start(aTHX_ c) < 0) { hm_close(aTHX_ c->loop, c); return 1; }
    hm_h2_input(aTHX_ c);       /* nghttp2 validates + consumes the preface */
    return 1;
}

static int hm_h2_available(void) { return 1; }

#else /* !HM_HAVE_NGHTTP2 */

static int  hm_h2_detect(pTHX_ hm_conn *c) { (void)c; return 0; }
static void hm_h2_input(pTHX_ hm_conn *c)  { (void)c; }
static void hm_h2_free(pTHX_ void *h2)     { (void)h2; }
static void hm_h2_writer_write(pTHX_ int fd, UV gen, int32_t sid, SV *d)
    { (void)fd; (void)gen; (void)sid; (void)d; }
static void hm_h2_writer_close(pTHX_ int fd, UV gen, int32_t sid)
    { (void)fd; (void)gen; (void)sid; }
static int  hm_h2_available(void) { return 0; }

#endif /* HM_HAVE_NGHTTP2 */

#endif /* HM_HTTP2_H */
