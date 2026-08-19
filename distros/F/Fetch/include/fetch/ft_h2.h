#ifndef FT_H2_H
#define FT_H2_H

/* HTTP/2 client via nghttp2: one connection carries one request stream (for
 * now - multiplexing across a pooled connection comes later). nghttp2 owns
 * framing, HPACK and flow control; we feed it received bytes and flush its
 * output through the same (possibly TLS) socket. The response resolves the
 * connection's Fetch::Future with a Fetch::Response.
 *
 * Included from ft_http.h after ft_recv/ft_send/ft_conn_finish/ft_conn_fail.
 * Compiles to stubs without -DFT_HAVE_NGHTTP2. */

#ifdef FT_HAVE_NGHTTP2

#include <nghttp2/nghttp2.h>

/* nghttp2 wants our socket writes here; return bytes sent or a would-block. */
static ssize_t ft_h2_send_cb(nghttp2_session *s, const uint8_t *data,
                             size_t length, int flags, void *user) {
    ft_conn *c = (ft_conn *)user;
    int want = 0;
    ssize_t n;
    dTHX;
    (void)s; (void)flags;
    n = ft_send(c, data, length, &want);
    if (n > 0) return n;
    if (n < 0 && want) return NGHTTP2_ERR_WOULDBLOCK;
    return NGHTTP2_ERR_CALLBACK_FAILURE;
}

static int ft_h2_header_cb(nghttp2_session *s, const nghttp2_frame *frame,
                          const uint8_t *name, size_t namelen,
                          const uint8_t *value, size_t valuelen,
                          uint8_t flags, void *user) {
    ft_conn *c = (ft_conn *)user;
    dTHX;
    (void)s; (void)flags;
    if (frame->hd.type != NGHTTP2_HEADERS) return 0;

    /* TRAILERS: a second HEADERS frame, after the DATA.
     *
     * These used to be discarded along with everything that was not
     * HCAT_RESPONSE, which is fine for ordinary HTTP - almost nothing uses
     * trailers - and fatal for gRPC, where the CALL STATUS lives in them and
     * nowhere else. A gRPC response is HTTP 200 whether it succeeded or
     * failed; a client that cannot read trailers can only ever report
     * success. Hence a separate list rather than merging them into the
     * response headers: a trailer arrived after the body and a consumer that
     * cares about the difference must be able to tell. */
    if (frame->headers.cat == NGHTTP2_HCAT_HEADERS) {
        if (namelen && name[0] != ':') {
            if (!c->trailers) c->trailers = newAV();
            av_push(c->trailers, newSVpvn((const char *)name, namelen));
            av_push(c->trailers, newSVpvn((const char *)value, valuelen));
        }
        return 0;
    }
    if (frame->headers.cat != NGHTTP2_HCAT_RESPONSE) return 0;

    if (namelen == 7 && memcmp(name, ":status", 7) == 0) {
        c->status = (int)strtol((const char *)value, NULL, 10);
    } else if (namelen && name[0] != ':') {         /* skip other pseudo-headers */
        if (!c->headers) c->headers = newAV();
        av_push(c->headers, newSVpvn((const char *)name, namelen));
        av_push(c->headers, newSVpvn((const char *)value, valuelen));
    }
    return 0;
}

static int ft_h2_data_cb(nghttp2_session *s, uint8_t flags, int32_t stream_id,
                        const uint8_t *data, size_t len, void *user) {
    ft_conn *c = (ft_conn *)user;
    dTHX;
    (void)s; (void)flags; (void)stream_id;
    if (c->on_body) {                    /* stream: emit, do not buffer */
        ft_emit_body(aTHX_ c, (const char *)data, len);
        c->body_recv += len;
        return 0;
    }
    if (c->dblen + len > c->dbcap) {
        c->dbcap = (c->dblen + len) * 2 + 64;
        Renew(c->dbody, c->dbcap, char);
    }
    memcpy(c->dbody + c->dblen, data, len);
    c->dblen += len;
    return 0;
}

static int ft_h2_stream_close_cb(nghttp2_session *s, int32_t stream_id,
                                uint32_t error_code, void *user) {
    ft_conn *c = (ft_conn *)user;
    (void)s; (void)stream_id; (void)error_code;
    c->h2_done = 1;
    return 0;
}

/* request-body data provider for POST/PUT over h2 */
static ssize_t ft_h2_body_read(nghttp2_session *s, int32_t stream_id,
                              uint8_t *buf, size_t length, uint32_t *data_flags,
                              nghttp2_data_source *source, void *user) {
    ft_conn *c = (ft_conn *)user;
    STRLEN blen = 0;
    const char *b;
    size_t take;
    dTHX;
    (void)s; (void)stream_id; (void)source;
    if (!c->rq_body) { *data_flags |= NGHTTP2_DATA_FLAG_EOF; return 0; }
    b = SvPV(c->rq_body, blen);
    take = (blen - c->rq_body_off < length) ? (blen - c->rq_body_off) : length;
    memcpy(buf, b + c->rq_body_off, take);
    c->rq_body_off += take;
    if (c->rq_body_off >= blen) *data_flags |= NGHTTP2_DATA_FLAG_EOF;
    return (ssize_t)take;
}

#define FT_NV(NAME, VAL, VLEN) \
    { (uint8_t *)(NAME), (uint8_t *)(VAL), sizeof(NAME) - 1, (VLEN), \
      NGHTTP2_NV_FLAG_NONE }

/* Initialise the h2 session and submit the request. Returns 0 / -1. */
static int ft_h2_init(pTHX_ ft_conn *c) {
    nghttp2_session_callbacks *cbs;
    nghttp2_session *sess;
    nghttp2_nv *nva;
    int nvn = 0, i, rv;
    STRLEN ml, sl, al, pl;
    const char *m = SvPV(c->rq_method,    ml);
    const char *sc= SvPV(c->rq_scheme,    sl);
    const char *au= SvPV(c->rq_authority, al);
    const char *pa= SvPV(c->rq_path,      pl);
    SSize_t extra = c->rq_headers ? (av_len(c->rq_headers) + 1) / 2 : 0;
    int32_t sid;
    nghttp2_data_provider prd, *prdp = NULL;

    nghttp2_session_callbacks_new(&cbs);
    nghttp2_session_callbacks_set_send_callback(cbs, ft_h2_send_cb);
    nghttp2_session_callbacks_set_on_header_callback(cbs, ft_h2_header_cb);
    nghttp2_session_callbacks_set_on_data_chunk_recv_callback(cbs, ft_h2_data_cb);
    nghttp2_session_callbacks_set_on_stream_close_callback(cbs, ft_h2_stream_close_cb);
    rv = nghttp2_session_client_new(&sess, cbs, c);
    nghttp2_session_callbacks_del(cbs);
    if (rv != 0) return -1;
    c->h2 = sess;

    /* The client connection preface is the 24-byte magic (nghttp2 emits it
     * automatically) followed by a SETTINGS frame, which we must submit
     * ourselves - without it the peer sees magic then HEADERS and aborts
     * with "SETTINGS expected". */
    {
        nghttp2_settings_entry iv[1] = {
            { NGHTTP2_SETTINGS_MAX_CONCURRENT_STREAMS, 100 }
        };
        if (nghttp2_submit_settings(sess, NGHTTP2_FLAG_NONE, iv, 1) != 0)
            return -1;
    }

    Newx(nva, 4 + extra, nghttp2_nv);
    { nghttp2_nv a = FT_NV(":method", m, ml); nva[nvn++] = a; }
    { nghttp2_nv a = FT_NV(":scheme", sc, sl); nva[nvn++] = a; }
    { nghttp2_nv a = FT_NV(":authority", au, al); nva[nvn++] = a; }
    { nghttp2_nv a = FT_NV(":path", pa, pl); nva[nvn++] = a; }
    if (c->rq_headers) {
        SSize_t j;
        for (j = 0; j + 1 <= av_len(c->rq_headers); j += 2) {
            SV **ks = av_fetch(c->rq_headers, j, 0);
            SV **vs = av_fetch(c->rq_headers, j + 1, 0);
            STRLEN kl, vl;
            char *k = ks ? SvPV(*ks, kl) : (char *)"";
            char *v = vs ? SvPV(*vs, vl) : (char *)"";
            if (!ks) kl = 0; if (!vs) vl = 0;
            nva[nvn].name = (uint8_t *)k; nva[nvn].namelen = kl;
            nva[nvn].value = (uint8_t *)v; nva[nvn].valuelen = vl;
            nva[nvn].flags = NGHTTP2_NV_FLAG_NONE;
            nvn++;
        }
    }
    if (c->rq_body && SvOK(c->rq_body) && SvCUR(c->rq_body)) {
        prd.source.ptr = NULL;
        prd.read_callback = ft_h2_body_read;
        prdp = &prd;
    }
    sid = nghttp2_submit_request(sess, NULL, nva, nvn, prdp, c);
    Safefree(nva);
    (void)i;
    if (sid < 0) return -1;
    return 0;
}

/* Flush pending frames; arm the loop for what nghttp2 wants next. Returns
 * 0 keep going, -1 fatal. */
static int ft_h2_flush(pTHX_ ft_conn *c) {
    nghttp2_session *s = (nghttp2_session *)c->h2;
    int rv = nghttp2_session_send(s);
    if (rv != 0) return -1;
    {
        int mask = 0;
        if (nghttp2_session_want_read(s))  mask |= HM_EV_READ;
        if (nghttp2_session_want_write(s)) mask |= HM_EV_WRITE;
        if (!mask) mask = HM_EV_READ;   /* awaiting the response */
        ft_arm(aTHX_ c, mask);
    }
    return 0;
}

/* Drive one readiness pass in h2 mode. */
static void ft_h2_step(pTHX_ ft_conn *c) {
    /* write out anything pending first (also flushes the request) */
    if (ft_h2_flush(aTHX_ c) < 0) { ft_conn_fail(aTHX_ c, "http/2 send failed"); return; }
    for (;;) {
        int want = 0;
        ssize_t n;
        unsigned char buf[65536];
        n = ft_recv(c, buf, sizeof(buf), &want);
        if (n > 0) {
            ssize_t rd = nghttp2_session_mem_recv((nghttp2_session *)c->h2,
                                                  buf, (size_t)n);
            if (rd < 0) { ft_conn_fail(aTHX_ c, "http/2 protocol error"); return; }
            if (ft_h2_flush(aTHX_ c) < 0) { ft_conn_fail(aTHX_ c, "http/2 send failed"); return; }
            if (c->h2_done) { ft_conn_finish(aTHX_ c); return; }
            continue;
        }
        if (n == 0) {
            if (c->h2_done) ft_conn_finish(aTHX_ c);
            else ft_conn_fail(aTHX_ c, "connection closed before the h2 stream completed");
            return;
        }
        if (want) { ft_arm(aTHX_ c, want); return; }
        if (errno == EINTR) continue;
        ft_conn_fail(aTHX_ c, strerror(errno));
        return;
    }
}

static void ft_h2_free(ft_conn *c) {
    if (c->h2) { nghttp2_session_del((nghttp2_session *)c->h2); c->h2 = NULL; }
}

#define FT_H2_AVAILABLE 1

#else  /* stubs */

static int  ft_h2_init(pTHX_ ft_conn *c) { (void)c; return -1; }
static void ft_h2_step(pTHX_ ft_conn *c) {
    ft_conn_fail(aTHX_ c, "HTTP/2 not built (need nghttp2)"); }
static void ft_h2_free(ft_conn *c) { (void)c; }
#define FT_H2_AVAILABLE 0

#endif

#endif /* FT_H2_H */
