#ifndef FT_H3_H
#define FT_H3_H

/* ft_h3.h - the HTTP/3 client, beside ft_h2.h.
 *
 * The h2 glue is 250 lines because nghttp2 does the work. This is longer for
 * one structural reason: nghttp2 PUSHES bytes at a send callback, while
 * nghttp3 is PULLED from, and the puller is ngtcp2, which also owns the loss
 * detection, the packet framing and the handshake. Two libraries stacked
 * where h2 has one, and the write half is a pump rather than a callback.
 *
 * ---- how a request flows --------------------------------------------------
 *
 *   ft_h3_connect      UDP socket, ngtcp2_conn_client_new, an SSL handed to
 *                      ngtcp2_crypto_ossl, ALPN "h3", SNI. The state becomes
 *                      FT_QUIC_HANDSHAKING.
 *   ft_h3_step         one readiness pass: drain datagrams into
 *                      ngtcp2_conn_read_pkt, then pump ft_h3_write until
 *                      ngtcp2 has nothing left, then rearm the probe timeout.
 *   handshake_completed  nghttp3_conn_client_new, the three unidirectional
 *                      streams QUIC requires (control, QPACK encoder, QPACK
 *                      decoder), then every request waiting on this
 *                      connection is submitted.
 *   ft_h3_write        nghttp3_conn_writev_stream -> ngtcp2_conn_writev_stream
 *                      -> sendto, in one loop, because ngtcp2 packs several
 *                      stream writes into one datagram and only it knows when
 *                      one is full.
 *
 * ---- multiplexing, which h2 here does not do ------------------------------
 *
 * Fetch does ONE request per HTTP/2 connection (ft_conn_reusable returns 0
 * for is_h2). That is not inherited: an h3 connection carrying one request
 * paid for a QUIC handshake to get less than keep-alive gives. So a request
 * is an ft_h3_stream and NOT an ft_conn - the connection holds a list of
 * them, each with its own future, headers and body, and each settles when
 * its own stream ends. The connection outlives all of them and is parked in
 * the pool under the "h3:" key that ft_http.h's pool gained for this.
 *
 * ---- what is deliberately not here ---------------------------------------
 *
 * Connection migration, 0-RTT, ECN, GSO, and the datagram extension. Each is
 * an optimisation or a feature on top of a connection that works; none of
 * them changes the shape above. Alt-Svc discovery is in ft_altsvc.h, because
 * it is HTTP/1 and HTTP/2 response parsing and has nothing to do with QUIC.
 *
 * Included from ft_http.h after ft_conn, ft_arm, ft_settle_response and
 * ft_conn_fail. Compiles to stubs without -DFT_HAVE_QUIC.
 */

#ifdef FT_HAVE_QUIC

#include <ngtcp2/ngtcp2.h>
#include <ngtcp2/ngtcp2_crypto.h>
#include <ngtcp2/ngtcp2_crypto_ossl.h>
#include <nghttp3/nghttp3.h>
#include <openssl/ssl.h>
#include <openssl/rand.h>

#define FT_H3_AVAILABLE 1
#define FT_H3_CIDLEN    16
#define FT_H3_MTU       1452         /* a conservative path MTU */

/* One request on a QUIC connection.
 *
 * Everything here is per-REQUEST and is what an ft_conn holds directly on the
 * other transports. It is split out because an h3 connection carries several
 * at once, which is the whole point of using it. */
typedef struct ft_h3_stream {
    int64_t   id;                /* -1 until submitted */
    SV       *future;
    SV       *on_body, *on_headers;
    int       headers_fired;
    int       status;
    AV       *headers, *trailers;
    char     *dbody;             /* response body, unless on_body streams it */
    size_t    dblen, dbcap;
    size_t    body_recv;
    /* the request, kept until submitted and while the body is being read */
    SV       *rq_method, *rq_scheme, *rq_authority, *rq_path;
    AV       *rq_headers;
    SV       *rq_body;
    size_t    rq_body_off;
    int       simple;
    int       submitted;
    struct ft_h3_stream *next;
} ft_h3_stream;

/* The QUIC half of an ft_conn. Hung off c->h3 so ft_conn needs no new
 * members: everything QUIC is behind this one pointer. */
typedef struct ft_qconn {
    ft_conn         *c;          /* the owning connection, for callbacks */
    ngtcp2_conn     *conn;
    nghttp3_conn    *h3;
    SSL             *ssl;
    ngtcp2_crypto_ossl_ctx *ossl;
    ngtcp2_crypto_conn_ref  conn_ref;
    ngtcp2_path_storage     path;
    struct sockaddr_storage peer;
    socklen_t        peerlen;
    ft_h3_stream    *streams;
    int              handshake_done;
    int              closing;     /* a fatal error is being reported */
    int              nstreams;    /* live streams, for pooling decisions */
} ft_qconn;

static int  ft_h3_write(pTHX_ ft_conn *c);
static int  ft_h3_submit(pTHX_ ft_conn *c, ft_h3_stream *st);
static void ft_h3_rearm(pTHX_ ft_conn *c);

/* The QUIC TLS context, separate from ft_tls.h's.
 *
 * QUIC is TLS 1.3 only - there is no QUIC over 1.2 - so the floor is raised
 * rather than inherited. Sharing ft_client_ctx would also mean sharing its
 * ALPN and its session cache with connections that are not QUIC at all, and
 * an SSL_CTX is cheap to have twice. */
static SSL_CTX *ft_h3_ctx(int verify) {
    static SSL_CTX *ctx_v = NULL, *ctx_n = NULL;
    static int inited = 0;
    SSL_CTX **slot = verify ? &ctx_v : &ctx_n;
    if (!inited) {
        /* Optional, and recommended by the library: without it the crypto
         * shim takes a slow path on every packet. Failing is not fatal. */
        (void)ngtcp2_crypto_ossl_init();
        inited = 1;
    }
    if (!*slot) {
        SSL_CTX *x = SSL_CTX_new(TLS_client_method());
        if (!x) return NULL;
        SSL_CTX_set_min_proto_version(x, TLS1_3_VERSION);
        SSL_CTX_set_max_proto_version(x, TLS1_3_VERSION);
        if (verify) {
            SSL_CTX_set_verify(x, SSL_VERIFY_PEER, NULL);
            SSL_CTX_set_default_verify_paths(x);
        } else {
            SSL_CTX_set_verify(x, SSL_VERIFY_NONE, NULL);
        }
        *slot = x;
    }
    return *slot;
}

/* ---- clock ---------------------------------------------------------------
 *
 * ngtcp2 measures everything in monotonic nanoseconds and compares the values
 * it is given against the ones it stored, so this must be the same clock
 * every time it is asked - never a wall clock, which steps. */
static ngtcp2_tstamp ft_h3_now(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (ngtcp2_tstamp)ts.tv_sec * NGTCP2_SECONDS + (ngtcp2_tstamp)ts.tv_nsec;
}

/* ---- streams ------------------------------------------------------------- */

static ft_h3_stream *ft_h3_stream_new(pTHX) {
    ft_h3_stream *st;
    Newxz(st, 1, ft_h3_stream);
    st->id = -1;
    return st;
}

static void ft_h3_stream_free(pTHX_ ft_h3_stream *st) {
    if (!st) return;
    if (st->future)       SvREFCNT_dec(st->future);
    if (st->on_body)      SvREFCNT_dec(st->on_body);
    if (st->on_headers)   SvREFCNT_dec(st->on_headers);
    if (st->headers)      SvREFCNT_dec((SV *)st->headers);
    if (st->trailers)     SvREFCNT_dec((SV *)st->trailers);
    if (st->rq_method)    SvREFCNT_dec(st->rq_method);
    if (st->rq_scheme)    SvREFCNT_dec(st->rq_scheme);
    if (st->rq_authority) SvREFCNT_dec(st->rq_authority);
    if (st->rq_path)      SvREFCNT_dec(st->rq_path);
    if (st->rq_headers)   SvREFCNT_dec((SV *)st->rq_headers);
    if (st->rq_body)      SvREFCNT_dec(st->rq_body);
    Safefree(st->dbody);
    Safefree(st);
}

static ft_h3_stream *ft_h3_find(ft_qconn *q, int64_t id) {
    ft_h3_stream *st;
    for (st = q->streams; st; st = st->next) if (st->id == id) return st;
    return NULL;
}

static void ft_h3_unlink(ft_qconn *q, ft_h3_stream *st) {
    ft_h3_stream **pp = &q->streams;
    while (*pp) {
        if (*pp == st) { *pp = st->next; q->nstreams--; return; }
        pp = &(*pp)->next;
    }
}

/* One finished request. The CONNECTION is untouched: its other streams are
 * still running and it stays poolable afterwards, which is the difference
 * from every other transport here.
 *
 * The future is settled here and the STRUCT IS NOT FREED. nghttp3 calls
 * end_stream and then stream_close, and both are handed the stream pointer as
 * user data - so freeing on the first is a use-after-free on the second. The
 * later of the two owns the memory; this one only owns the answer. */
static void ft_h3_stream_done(pTHX_ ft_qconn *q, ft_h3_stream *st) {
    (void)q;
    if (!st->future) return;                 /* already settled */
    ft_settle_response(aTHX_ st->future, st->status, st->headers, st->trailers,
                       st->dbody, st->dblen, st->simple);
    SvREFCNT_dec(st->future);
    st->future = NULL;
}

/* Fail every outstanding request on this connection with one message. A QUIC
 * connection dying takes all of its streams with it, and each is somebody's
 * pending future - leaving any of them unsettled is a caller that waits for
 * ever, which is worse than the error. */
static void ft_h3_fail_all(pTHX_ ft_conn *c, const char *msg) {
    ft_qconn *q = (ft_qconn *)c->h3;
    SV *e;
    if (!q || q->closing) return;
    q->closing = 1;
    e = sv_2mortal(newSVpvf("Fetch: %s", msg));
    while (q->streams) {
        ft_h3_stream *st = q->streams;
        q->streams = st->next;
        q->nstreams--;
        if (st->future && hmf_state(aTHX_ st->future) == HMF_PENDING)
            hmf_settle(aTHX_ st->future, HMF_FAILED, &e, 1);
        ft_h3_stream_free(aTHX_ st);
    }
    q->closing = 0;
    ft_conn_fail(aTHX_ c, msg);
}

/* ---- nghttp3 callbacks --------------------------------------------------- */

static int ft_h3_cb_begin_headers(nghttp3_conn *conn, int64_t sid,
                                  void *user, void *stream_user) {
    (void)conn; (void)sid; (void)user; (void)stream_user;
    return 0;
}

static int ft_h3_cb_recv_header(nghttp3_conn *conn, int64_t sid, int32_t token,
                                nghttp3_rcbuf *name, nghttp3_rcbuf *value,
                                uint8_t flags, void *user, void *stream_user) {
    ft_qconn *q = (ft_qconn *)user;
    ft_h3_stream *st = (ft_h3_stream *)stream_user;
    nghttp3_vec n = nghttp3_rcbuf_get_buf(name);
    nghttp3_vec v = nghttp3_rcbuf_get_buf(value);
    dTHX;
    (void)conn; (void)flags;
    if (!st) st = ft_h3_find(q, sid);
    if (!st) return 0;
    if (token == NGHTTP3_QPACK_TOKEN__STATUS) {
        st->status = (int)strtol((const char *)v.base, NULL, 10);
        return 0;
    }
    if (n.len && n.base[0] == ':') return 0;       /* other pseudo-headers */
    if (!st->headers) st->headers = newAV();
    av_push(st->headers, newSVpvn((const char *)n.base, n.len));
    av_push(st->headers, newSVpvn((const char *)v.base, v.len));
    return 0;
}

/* Trailers: a second header block, after the body. Kept apart from the
 * response headers for the reason ft_h2.h spells out - gRPC puts the call
 * status in them and nowhere else, and a consumer must be able to tell a
 * trailer from a header. */
static int ft_h3_cb_recv_trailer(nghttp3_conn *conn, int64_t sid, int32_t token,
                                 nghttp3_rcbuf *name, nghttp3_rcbuf *value,
                                 uint8_t flags, void *user, void *stream_user) {
    ft_qconn *q = (ft_qconn *)user;
    ft_h3_stream *st = (ft_h3_stream *)stream_user;
    nghttp3_vec n = nghttp3_rcbuf_get_buf(name);
    nghttp3_vec v = nghttp3_rcbuf_get_buf(value);
    dTHX;
    (void)conn; (void)flags; (void)token;
    if (!st) st = ft_h3_find(q, sid);
    if (!st || (n.len && n.base[0] == ':')) return 0;
    if (!st->trailers) st->trailers = newAV();
    av_push(st->trailers, newSVpvn((const char *)n.base, n.len));
    av_push(st->trailers, newSVpvn((const char *)v.base, v.len));
    return 0;
}

/* The response head is complete. This is where on_headers fires, before any
 * body, exactly as the other two transports do it. */
static int ft_h3_cb_end_headers(nghttp3_conn *conn, int64_t sid, int fin,
                                void *user, void *stream_user) {
    ft_qconn *q = (ft_qconn *)user;
    ft_h3_stream *st = (ft_h3_stream *)stream_user;
    dTHX;
    (void)conn; (void)fin;
    if (!st) st = ft_h3_find(q, sid);
    if (!st || st->headers_fired || !st->on_headers) return 0;
    st->headers_fired = 1;
    {
        dSP;
        SV *hrv = st->headers ? newRV_inc((SV *)st->headers)
                              : newRV_noinc((SV *)newAV());
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(st->status)));
        PUSHs(sv_2mortal(hrv));
        PUTBACK;
        call_sv(st->on_headers, G_DISCARD | G_EVAL);
        if (SvTRUE(ERRSV))
            warn("Fetch: on_headers callback died: %s", SvPV_nolen(ERRSV));
        FREETMPS; LEAVE;
    }
    return 0;
}

static int ft_h3_cb_recv_data(nghttp3_conn *conn, int64_t sid,
                              const uint8_t *data, size_t datalen,
                              void *user, void *stream_user) {
    ft_qconn *q = (ft_qconn *)user;
    ft_h3_stream *st = (ft_h3_stream *)stream_user;
    dTHX;
    (void)conn;
    if (!st) st = ft_h3_find(q, sid);
    if (!st) return 0;
    /* The flow-control window is credited here and in deferred_consume, and
     * NOT also in ngtcp2's recv_stream_data - crediting both opens the window
     * twice and lets the peer send past what was advertised. */
    ngtcp2_conn_extend_max_stream_offset(q->conn, sid, datalen);
    ngtcp2_conn_extend_max_offset(q->conn, datalen);
    if (st->on_body) {                   /* stream: emit, do not buffer */
        ft_emit_body_sv(aTHX_ st->on_body, (const char *)data, datalen);
        st->body_recv += datalen;
        return 0;
    }
    if (st->dblen + datalen > st->dbcap) {
        st->dbcap = (st->dblen + datalen) * 2 + 64;
        Renew(st->dbody, st->dbcap, char);
    }
    memcpy(st->dbody + st->dblen, data, datalen);
    st->dblen += datalen;
    return 0;
}

/* Bytes nghttp3 skipped over (frame headers, QPACK instructions). They came
 * out of the same window and have to be credited back too, or the peer runs
 * out of room by exactly the framing overhead and the transfer stalls. */
static int ft_h3_cb_deferred_consume(nghttp3_conn *conn, int64_t sid,
                                     size_t consumed, void *user,
                                     void *stream_user) {
    ft_qconn *q = (ft_qconn *)user;
    (void)conn; (void)stream_user;
    ngtcp2_conn_extend_max_stream_offset(q->conn, sid, consumed);
    ngtcp2_conn_extend_max_offset(q->conn, consumed);
    return 0;
}

static int ft_h3_cb_end_stream(nghttp3_conn *conn, int64_t sid,
                               void *user, void *stream_user) {
    ft_qconn *q = (ft_qconn *)user;
    ft_h3_stream *st = (ft_h3_stream *)stream_user;
    dTHX;
    (void)conn;
    if (!st) st = ft_h3_find(q, sid);
    if (st) ft_h3_stream_done(aTHX_ q, st);
    return 0;
}

static int ft_h3_cb_stream_close(nghttp3_conn *conn, int64_t sid,
                                 uint64_t app_error_code, void *user,
                                 void *stream_user) {
    ft_qconn *q = (ft_qconn *)user;
    ft_h3_stream *st = (ft_h3_stream *)stream_user;
    dTHX;
    if (!st) st = ft_h3_find(q, sid);
    if (!st) return 0;
    /* Closed with the response already delivered is the ordinary path and
     * end_stream has settled it. Closed while a future is still pending is a
     * reset: the caller gets an error rather than a truncated 200. */
    if (st->future) {
        SV *e = sv_2mortal(newSVpvf("Fetch: http/3 stream reset (0x%" UVxf ")",
                                    (UV)app_error_code));
        if (hmf_state(aTHX_ st->future) == HMF_PENDING)
            hmf_settle(aTHX_ st->future, HMF_FAILED, &e, 1);
        SvREFCNT_dec(st->future);
        st->future = NULL;
    }
    /* The last callback this stream gets, so it owns the memory. Clearing
     * the user data first is what stops a later ngtcp2 callback naming an
     * address this connection has since handed to something else. */
    nghttp3_conn_set_stream_user_data(conn, sid, NULL);
    ft_h3_unlink(q, st);
    ft_h3_stream_free(aTHX_ st);
    return 0;
}

static int ft_h3_cb_stop_sending(nghttp3_conn *conn, int64_t sid,
                                 uint64_t app_error_code, void *user,
                                 void *stream_user) {
    ft_qconn *q = (ft_qconn *)user;
    (void)conn; (void)stream_user;
    ngtcp2_conn_shutdown_stream_read(q->conn, 0, sid, app_error_code);
    return 0;
}

static int ft_h3_cb_reset_stream(nghttp3_conn *conn, int64_t sid,
                                 uint64_t app_error_code, void *user,
                                 void *stream_user) {
    ft_qconn *q = (ft_qconn *)user;
    (void)conn; (void)stream_user;
    ngtcp2_conn_shutdown_stream_write(q->conn, 0, sid, app_error_code);
    return 0;
}

static void ft_h3_cb_rand(uint8_t *dest, size_t destlen) {
    ft_os_random(dest, destlen);
}

/* The request body, pulled rather than pushed. nghttp3 keeps the POINTER, so
 * the SV must stay alive until the bytes are acknowledged - which is what
 * holding rq_body on the stream is for. */
static nghttp3_ssize ft_h3_read_body(nghttp3_conn *conn, int64_t sid,
                                     nghttp3_vec *vec, size_t veccnt,
                                     uint32_t *pflags, void *user,
                                     void *stream_user) {
    ft_h3_stream *st = (ft_h3_stream *)stream_user;
    ft_qconn *q = (ft_qconn *)user;
    STRLEN blen = 0;
    const char *b;
    dTHX;
    (void)conn; (void)veccnt;
    if (!st) st = ft_h3_find(q, sid);
    if (!st || !st->rq_body) { *pflags |= NGHTTP3_DATA_FLAG_EOF; return 0; }
    b = SvPV(st->rq_body, blen);
    if (st->rq_body_off >= blen) { *pflags |= NGHTTP3_DATA_FLAG_EOF; return 0; }
    vec[0].base = (uint8_t *)b + st->rq_body_off;
    vec[0].len  = blen - st->rq_body_off;
    st->rq_body_off = blen;
    *pflags |= NGHTTP3_DATA_FLAG_EOF;
    return 1;
}

/* ---- ngtcp2 callbacks ---------------------------------------------------- */

static ngtcp2_conn *ft_h3_get_conn(ngtcp2_crypto_conn_ref *ref) {
    return ((ft_qconn *)ref->user_data)->conn;
}

static void ft_h3_cb_qrand(uint8_t *dest, size_t destlen,
                           const ngtcp2_rand_ctx *ctx) {
    (void)ctx;
    ft_os_random(dest, destlen);
}

static int ft_h3_cb_get_new_cid(ngtcp2_conn *conn, ngtcp2_cid *cid,
                                uint8_t *token, size_t cidlen, void *user) {
    (void)conn; (void)user;
    ft_os_random(cid->data, cidlen);
    cid->datalen = cidlen;
    ft_os_random(token, NGTCP2_STATELESS_RESET_TOKENLEN);
    return 0;
}

static int ft_h3_cb_recv_stream_data(ngtcp2_conn *conn, uint32_t flags,
                                     int64_t sid, uint64_t offset,
                                     const uint8_t *data, size_t datalen,
                                     void *user, void *stream_user) {
    ft_qconn *q = (ft_qconn *)user;
    nghttp3_ssize n;
    dTHX;
    (void)conn; (void)offset; (void)stream_user;
    if (!q->h3) return 0;
    n = nghttp3_conn_read_stream(q->h3, sid, data, datalen,
                                 (flags & NGTCP2_STREAM_DATA_FLAG_FIN) ? 1 : 0);
    if (n < 0) return NGTCP2_ERR_CALLBACK_FAILURE;
    return 0;
}

static int ft_h3_cb_qstream_close(ngtcp2_conn *conn, uint32_t flags,
                                  int64_t sid, uint64_t app_error_code,
                                  void *user, void *stream_user) {
    ft_qconn *q = (ft_qconn *)user;
    (void)conn; (void)stream_user;
    if (!(flags & NGTCP2_STREAM_CLOSE_FLAG_APP_ERROR_CODE_SET))
        app_error_code = NGHTTP3_H3_NO_ERROR;
    if (q->h3 && nghttp3_conn_close_stream(q->h3, sid, app_error_code) != 0)
        return NGTCP2_ERR_CALLBACK_FAILURE;
    return 0;
}

static int ft_h3_cb_acked_stream_data(ngtcp2_conn *conn, int64_t sid,
                                      uint64_t offset, uint64_t datalen,
                                      void *user, void *stream_user) {
    ft_qconn *q = (ft_qconn *)user;
    (void)conn; (void)offset; (void)stream_user;
    if (q->h3 && nghttp3_conn_add_ack_offset(q->h3, sid, datalen) != 0)
        return NGTCP2_ERR_CALLBACK_FAILURE;
    return 0;
}

/* The peer opened a stream's send window again. Without telling nghttp3, a
 * stream it stopped offering when the window closed is never offered again
 * and the request simply stops - which only shows up under concurrency. */
static int ft_h3_cb_extend_max_stream_data(ngtcp2_conn *conn, int64_t sid,
                                           uint64_t max_data, void *user,
                                           void *stream_user) {
    ft_qconn *q = (ft_qconn *)user;
    (void)conn; (void)max_data; (void)stream_user;
    if (q->h3 && nghttp3_conn_unblock_stream(q->h3, sid) != 0)
        return NGTCP2_ERR_CALLBACK_FAILURE;
    return 0;
}

/* The TLS handshake finished, so HTTP/3 can start.
 *
 * The three unidirectional streams are not optional and not an optimisation:
 * RFC 9114 requires a control stream and the two QPACK streams before any
 * request, and a peer that never sees them closes the connection. */
static int ft_h3_cb_handshake_completed(ngtcp2_conn *conn, void *user) {
    ft_qconn *q = (ft_qconn *)user;
    nghttp3_callbacks cbs;
    nghttp3_settings settings;
    int64_t ctrl = -1, qenc = -1, qdec = -1;
    ft_h3_stream *st;
    dTHX;
    (void)conn;

    memset(&cbs, 0, sizeof cbs);
    cbs.begin_headers     = ft_h3_cb_begin_headers;
    cbs.recv_header       = ft_h3_cb_recv_header;
    cbs.end_headers       = ft_h3_cb_end_headers;
    cbs.recv_trailer      = ft_h3_cb_recv_trailer;
    cbs.recv_data         = ft_h3_cb_recv_data;
    cbs.deferred_consume  = ft_h3_cb_deferred_consume;
    cbs.end_stream        = ft_h3_cb_end_stream;
    cbs.stream_close      = ft_h3_cb_stream_close;
    cbs.stop_sending      = ft_h3_cb_stop_sending;
    cbs.reset_stream      = ft_h3_cb_reset_stream;
    cbs.rand              = ft_h3_cb_rand;

    nghttp3_settings_default(&settings);
    settings.qpack_max_dtable_capacity = 4096;
    settings.qpack_blocked_streams     = 100;

    if (nghttp3_conn_client_new(&q->h3, &cbs, &settings, NULL, q) != 0)
        return NGTCP2_ERR_CALLBACK_FAILURE;
    if (ngtcp2_conn_open_uni_stream(q->conn, &ctrl, NULL) != 0
        || nghttp3_conn_bind_control_stream(q->h3, ctrl) != 0
        || ngtcp2_conn_open_uni_stream(q->conn, &qenc, NULL) != 0
        || ngtcp2_conn_open_uni_stream(q->conn, &qdec, NULL) != 0
        || nghttp3_conn_bind_qpack_streams(q->h3, qenc, qdec) != 0)
        return NGTCP2_ERR_CALLBACK_FAILURE;

    q->handshake_done = 1;
    q->c->state = FT_WRITING;
    /* Everything queued while the handshake ran goes out now, in order. */
    for (st = q->streams; st; st = st->next)
        if (!st->submitted && ft_h3_submit(aTHX_ q->c, st) != 0)
            return NGTCP2_ERR_CALLBACK_FAILURE;
    return 0;
}

/* ---- the write pump ------------------------------------------------------
 *
 * QUIC PULLS. There is no send callback and no write buffer: bytes are asked
 * for and handed straight to sendto. ngtcp2 packs several stream writes into
 * one datagram and only it knows when one is full, which is why this is a
 * loop and not a call. 0 to carry on, -1 if the connection was failed. */
static int ft_h3_write(pTHX_ ft_conn *c) {
    ft_qconn *q = (ft_qconn *)c->h3;
    uint8_t buf[FT_H3_MTU];
    ngtcp2_path_storage ps;
    ngtcp2_pkt_info pi;
    for (;;) {
        nghttp3_vec vec[16];
        ngtcp2_ssize n, wrote = 0;
        nghttp3_ssize nvec = 0;
        int64_t sid = -1;
        int fin = 0;
        uint32_t flags = NGTCP2_WRITE_STREAM_FLAG_MORE;

        if (q->h3) {
            nvec = nghttp3_conn_writev_stream(q->h3, &sid, &fin, vec,
                                              sizeof(vec) / sizeof(vec[0]));
            if (nvec < 0) { ft_h3_fail_all(aTHX_ c, "http/3 write failed"); return -1; }
        }
        if (sid < 0)  flags = NGTCP2_WRITE_STREAM_FLAG_NONE;
        else if (fin) flags |= NGTCP2_WRITE_STREAM_FLAG_FIN;

        ngtcp2_path_storage_zero(&ps);
        n = ngtcp2_conn_writev_stream(q->conn, &ps.path, &pi, buf, sizeof buf,
                                      &wrote, flags, sid,
                                      (const ngtcp2_vec *)vec, (size_t)nvec,
                                      ft_h3_now());
        if (n < 0) {
            if (n == NGTCP2_ERR_WRITE_MORE) {
                /* taken into the packet being built but not yet framed out */
                if (wrote > 0 && q->h3
                    && nghttp3_conn_add_write_offset(q->h3, sid, (size_t)wrote) != 0) {
                    ft_h3_fail_all(aTHX_ c, "http/3 write offset failed");
                    return -1;
                }
                continue;
            }
            if (n == NGTCP2_ERR_STREAM_DATA_BLOCKED
                || n == NGTCP2_ERR_STREAM_SHUT_WR) {
                /* one stream cannot progress; the others still can */
                if (q->h3 && sid >= 0) nghttp3_conn_block_stream(q->h3, sid);
                continue;
            }
            ft_h3_fail_all(aTHX_ c, ngtcp2_strerror((int)n));
            return -1;
        }
        if (wrote > 0 && q->h3
            && nghttp3_conn_add_write_offset(q->h3, sid, (size_t)wrote) != 0) {
            ft_h3_fail_all(aTHX_ c, "http/3 write offset failed");
            return -1;
        }
        if (n == 0) break;                          /* nothing more to send */
        /* send, not sendto: the socket is connected to the one peer (see
         * ft_h3_connect), so there is no address to give and giving one is
         * EISCONN. */
        if (ft_os_send(c->fd, buf, (size_t)n, 0) < 0) {
            if (errno == EAGAIN || errno == EWOULDBLOCK) {
                ft_arm(aTHX_ c, HM_EV_READ | HM_EV_WRITE);
                return 0;
            }
            ft_h3_fail_all(aTHX_ c, strerror(errno));
            return -1;
        }
    }
    return 0;
}

/* The probe timeout fired. ngtcp2 decides what that means - a retransmit, a
 * PING, or the connection being dead - and writing is what carries it out. */
static void ft_h3_on_pto(pTHX_ ft_conn *c) {
    ft_qconn *q = (ft_qconn *)c->h3;
    if (!q || q->closing) return;
    if (ngtcp2_conn_handle_expiry(q->conn, ft_h3_now()) != 0) {
        ft_h3_fail_all(aTHX_ c, "http/3 connection timed out");
        return;
    }
    if (ft_h3_write(aTHX_ c) < 0) return;
    ft_h3_rearm(aTHX_ c);
}

/* Rearm the probe timeout wherever ngtcp2 has moved it to. Called after every
 * read and every write, because that is how often it moves. */
static void ft_h3_rearm(pTHX_ ft_conn *c) {
    ft_qconn *q = (ft_qconn *)c->h3;
    ngtcp2_tstamp t = ngtcp2_conn_get_expiry(q->conn);
    ngtcp2_tstamp now;
    double secs;
    if (t == UINT64_MAX) { ft_conn_cancel_pto(aTHX_ c); return; }
    now  = ft_h3_now();
    secs = (t <= now) ? 0.000001 : (double)(t - now) / (double)NGTCP2_SECONDS;
    ft_conn_arm_pto(aTHX_ c, secs, ft_h3_on_pto);
}

/* ---- submitting a request ------------------------------------------------ */

#define FT_H3_NV(NAME, VAL, VLEN) \
    { (uint8_t *)(NAME), (uint8_t *)(VAL), sizeof(NAME) - 1, (VLEN), \
      NGHTTP3_NV_FLAG_NONE }

static int ft_h3_submit(pTHX_ ft_conn *c, ft_h3_stream *st) {
    ft_qconn *q = (ft_qconn *)c->h3;
    nghttp3_nv *nva;
    int nvn = 0;
    STRLEN ml, sl, al, pl;
    const char *m  = SvPV(st->rq_method,    ml);
    const char *sc = SvPV(st->rq_scheme,    sl);
    const char *au = SvPV(st->rq_authority, al);
    const char *pa = SvPV(st->rq_path,      pl);
    SSize_t extra = st->rq_headers ? (av_len(st->rq_headers) + 1) / 2 : 0;
    nghttp3_data_reader dr, *drp = NULL;
    int64_t sid = -1;
    int rv;

    if (ngtcp2_conn_open_bidi_stream(q->conn, &sid, st) != 0) return -1;
    st->id = sid;

    Newx(nva, 4 + extra, nghttp3_nv);
    { nghttp3_nv a = FT_H3_NV(":method",    m,  ml); nva[nvn++] = a; }
    { nghttp3_nv a = FT_H3_NV(":scheme",    sc, sl); nva[nvn++] = a; }
    { nghttp3_nv a = FT_H3_NV(":authority", au, al); nva[nvn++] = a; }
    { nghttp3_nv a = FT_H3_NV(":path",      pa, pl); nva[nvn++] = a; }
    if (st->rq_headers) {
        SSize_t j;
        for (j = 0; j + 1 <= av_len(st->rq_headers); j += 2) {
            SV **ks = av_fetch(st->rq_headers, j, 0);
            SV **vs = av_fetch(st->rq_headers, j + 1, 0);
            STRLEN kl = 0, vl = 0;
            char *k = ks ? SvPV(*ks, kl) : (char *)"";
            char *v = vs ? SvPV(*vs, vl) : (char *)"";
            nva[nvn].name     = (uint8_t *)k; nva[nvn].namelen  = kl;
            nva[nvn].value    = (uint8_t *)v; nva[nvn].valuelen = vl;
            nva[nvn].flags    = NGHTTP3_NV_FLAG_NONE;
            nvn++;
        }
    }
    if (st->rq_body && SvOK(st->rq_body) && SvCUR(st->rq_body)) {
        dr.read_data = ft_h3_read_body;
        drp = &dr;
    }
    rv = nghttp3_conn_submit_request(q->h3, sid, nva, nvn, drp, st);
    Safefree(nva);
    if (rv != 0) return -1;
    st->submitted = 1;
    return 0;
}

/* ---- connect ------------------------------------------------------------- */

/* ALPN. QUIC's is inside the QUIC handshake and has nothing to do with the
 * TLS-over-TCP list in ft_tls.h, which stays as it is. */
static const unsigned char FT_H3_ALPN[] = { 2, 'h', '3' };

/* Open the QUIC connection. The socket is a UDP one, so nothing above this
 * changes: the loop watches an fd for readability either way. */
static int ft_h3_connect(pTHX_ ft_conn *c, struct addrinfo *ai) {
    ft_qconn *q;
    ngtcp2_callbacks cbs;
    ngtcp2_settings settings;
    ngtcp2_transport_params params;
    ngtcp2_cid dcid, scid;
    struct sockaddr_storage local;
    socklen_t locallen = sizeof local;
    SSL_CTX *ctx;
    int fd;

    fd = ft_os_socket(ai->ai_family, SOCK_DGRAM, 0);
    if (fd < 0) return -1;
    ft_os_set_nonblock(fd);

    Newxz(q, 1, ft_qconn);
    q->c = c;
    memcpy(&q->peer, ai->ai_addr, ai->ai_addrlen);
    q->peerlen = (socklen_t)ai->ai_addrlen;

    /* The local address is needed for the path, and a UDP socket has none
     * until it is bound - so connect() it, which binds it and also lets the
     * kernel filter datagrams from anyone else. */
    if (ft_os_connect(fd, (struct sockaddr *)&q->peer, (int)q->peerlen) != 0
        && errno != EINPROGRESS) {
        Safefree(q); ft_os_close(fd); return -1;
    }
    if (getsockname(fd, (struct sockaddr *)&local, &locallen) < 0) {
        Safefree(q); ft_os_close(fd); return -1;
    }
    ngtcp2_path_storage_init(&q->path, (struct sockaddr *)&local, locallen,
                             (struct sockaddr *)&q->peer, q->peerlen, NULL);

    ft_os_random(scid.data, FT_H3_CIDLEN); scid.datalen = FT_H3_CIDLEN;
    ft_os_random(dcid.data, FT_H3_CIDLEN); dcid.datalen = FT_H3_CIDLEN;

    memset(&cbs, 0, sizeof cbs);
    /* the eleven ngtcp2_crypto supplies ready-made (the client half) */
    cbs.client_initial            = ngtcp2_crypto_client_initial_cb;
    cbs.recv_crypto_data          = ngtcp2_crypto_recv_crypto_data_cb;
    cbs.encrypt                   = ngtcp2_crypto_encrypt_cb;
    cbs.decrypt                   = ngtcp2_crypto_decrypt_cb;
    cbs.hp_mask                   = ngtcp2_crypto_hp_mask_cb;
    cbs.update_key                = ngtcp2_crypto_update_key_cb;
    cbs.delete_crypto_aead_ctx    = ngtcp2_crypto_delete_crypto_aead_ctx_cb;
    cbs.delete_crypto_cipher_ctx  = ngtcp2_crypto_delete_crypto_cipher_ctx_cb;
    cbs.get_path_challenge_data   = ngtcp2_crypto_get_path_challenge_data_cb;
    cbs.version_negotiation       = ngtcp2_crypto_version_negotiation_cb;
    cbs.recv_retry                = ngtcp2_crypto_recv_retry_cb;
    /* ...and the glue that is ours */
    cbs.rand                      = ft_h3_cb_qrand;
    cbs.get_new_connection_id     = ft_h3_cb_get_new_cid;
    cbs.handshake_completed       = ft_h3_cb_handshake_completed;
    cbs.recv_stream_data          = ft_h3_cb_recv_stream_data;
    cbs.stream_close              = ft_h3_cb_qstream_close;
    cbs.acked_stream_data_offset  = ft_h3_cb_acked_stream_data;
    cbs.extend_max_stream_data    = ft_h3_cb_extend_max_stream_data;

    ngtcp2_settings_default(&settings);
    ngtcp2_transport_params_default(&params);
    settings.initial_ts = ft_h3_now();
    params.initial_max_stream_data_bidi_local  = 256 * 1024;
    params.initial_max_stream_data_bidi_remote = 256 * 1024;
    params.initial_max_stream_data_uni         = 256 * 1024;
    params.initial_max_data                    = 1024 * 1024;
    params.initial_max_streams_bidi            = 0;   /* a client accepts none */
    params.initial_max_streams_uni             = 8;   /* the server's control
                                                       * + QPACK streams */
    params.max_idle_timeout                    = 30 * NGTCP2_SECONDS;

    if (ngtcp2_conn_client_new(&q->conn, &dcid, &scid, &q->path.path,
                               NGTCP2_PROTO_VER_V1, &cbs, &settings, &params,
                               NULL, q) != 0) {
        Safefree(q); ft_os_close(fd); return -1;
    }

    ctx = ft_h3_ctx(c->verify);
    if (!ctx) { ngtcp2_conn_del(q->conn); Safefree(q); ft_os_close(fd); return -1; }
    q->ssl = SSL_new(ctx);
    if (!q->ssl
        || ngtcp2_crypto_ossl_ctx_new(&q->ossl, q->ssl) != 0
        || ngtcp2_crypto_ossl_configure_client_session(q->ssl) != 0) {
        if (q->ssl && !q->ossl) SSL_free(q->ssl);
        ngtcp2_conn_del(q->conn); Safefree(q); ft_os_close(fd);
        return -1;
    }
    q->conn_ref.get_conn  = ft_h3_get_conn;
    q->conn_ref.user_data = q;
    SSL_set_app_data(q->ssl, &q->conn_ref);
    /* ngtcp2 drives the handshake itself and never calls SSL_connect, so the
     * side has to be set here or the first Initial fails with a crypto error
     * and nothing in the error queue to explain it. */
    SSL_set_connect_state(q->ssl);
    SSL_set_alpn_protos(q->ssl, FT_H3_ALPN, sizeof FT_H3_ALPN);
    if (c->host && *c->host) {
        SSL_set_tlsext_host_name(q->ssl, c->host);
        if (c->verify) {
            SSL_set_hostflags(q->ssl, X509_CHECK_FLAG_NO_PARTIAL_WILDCARDS);
            SSL_set1_host(q->ssl, c->host);
            SSL_set_verify(q->ssl, SSL_VERIFY_PEER, NULL);
        }
    }
    ngtcp2_conn_set_tls_native_handle(q->conn, q->ossl);

    c->fd    = fd;
    c->h3    = q;
    c->is_h3 = 1;
    c->state = FT_QUIC_HANDSHAKING;
    return 0;
}

/* ---- the readiness pass -------------------------------------------------- */

static void ft_h3_step(pTHX_ ft_conn *c) {
    ft_qconn *q = (ft_qconn *)c->h3;
    uint8_t buf[65536];
    ngtcp2_pkt_info pi;
    for (;;) {
        /* recv, not recvfrom: the socket is connected, so the kernel has
         * already dropped anything from anyone else and the sender is always
         * q->peer. That connect() is also what gets this an ECONNREFUSED
         * when nothing is listening - an unconnected UDP socket is told
         * nothing and would wait out the idle timeout instead. */
        ssize_t n = ft_os_recv(c->fd, buf, sizeof buf, 0);
        if (n < 0) {
            if (errno == EAGAIN || errno == EWOULDBLOCK) break;
            if (errno == EINTR) continue;
            ft_h3_fail_all(aTHX_ c, strerror(errno));
            return;
        }
        memset(&pi, 0, sizeof pi);
        {
            if (ngtcp2_conn_read_pkt(q->conn, &q->path.path, &pi, buf,
                                     (size_t)n, ft_h3_now()) != 0) {
                ft_h3_fail_all(aTHX_ c, "http/3 connection error");
                return;
            }
        }
        /* A callback may have failed everything and freed the connection. */
        if (!c->h3) return;
    }
    if (ft_h3_write(aTHX_ c) < 0) return;
    ft_h3_rearm(aTHX_ c);
    /* Read is always wanted: the response, the acks and the peer's own
     * control stream all arrive that way. */
    if (!(c->armed & HM_EV_WRITE)) ft_arm(aTHX_ c, HM_EV_READ);
}

/* ---- the request entry point --------------------------------------------
 *
 * Attach one request to this connection. Submitted at once if the handshake
 * has finished, and queued for ft_h3_cb_handshake_completed if it has not -
 * which is what lets several requests be started before the connection is
 * even up, and is the difference between multiplexing and taking turns.
 *
 * The stream owns its own copies of everything: the caller's SVs go out of
 * scope while the response is still arriving. */
static void ft_h3_request(pTHX_ ft_conn *c, SV *future,
                          SV *method, SV *scheme, SV *authority, SV *path,
                          SV *headers_av, SV *body, SV *on_body,
                          SV *on_headers, int simple) {
    ft_qconn *q = (ft_qconn *)c->h3;
    ft_h3_stream *st = ft_h3_stream_new(aTHX);
    st->future       = SvREFCNT_inc(future);
    st->rq_method    = newSVsv(method);
    st->rq_scheme    = newSVsv(scheme);
    st->rq_authority = newSVsv(authority);
    st->rq_path      = newSVsv(path);
    st->simple       = simple;
    if (headers_av && SvROK(headers_av) && SvTYPE(SvRV(headers_av)) == SVt_PVAV)
        st->rq_headers = (AV *)SvREFCNT_inc(SvRV(headers_av));
    if (body && SvOK(body))            st->rq_body    = newSVsv(body);
    if (on_body && SvROK(on_body))     st->on_body    = SvREFCNT_inc(on_body);
    if (on_headers && SvROK(on_headers)) st->on_headers = SvREFCNT_inc(on_headers);
    st->next   = q->streams;
    q->streams = st;
    q->nstreams++;
    if (q->handshake_done && ft_h3_submit(aTHX_ c, st) != 0) {
        ft_h3_fail_all(aTHX_ c, "http/3 submit failed");
        return;
    }
    if (q->handshake_done) {
        if (ft_h3_write(aTHX_ c) < 0) return;
        ft_h3_rearm(aTHX_ c);
    }
}

/* Is this pooled connection still usable?
 *
 * The h1 pool asks with a one-byte MSG_PEEK, which says whether the socket is
 * still there. That question does not transfer: a QUIC connection can be dead
 * with its UDP socket perfectly healthy - the peer's idle timeout expired, or
 * it sent CONNECTION_CLOSE - so what is asked instead is whether ngtcp2 still
 * considers the connection open. */
static int ft_conn_alive_h3(ft_conn *c) {
    ft_qconn *q = (ft_qconn *)c->h3;
    if (!q || q->closing || !q->conn) return 0;
    if (ngtcp2_conn_in_closing_period2(q->conn)
        || ngtcp2_conn_in_draining_period2(q->conn)) return 0;
    return 1;
}

static void ft_h3_free(pTHX_ ft_conn *c) {
    ft_qconn *q = (ft_qconn *)c->h3;
    if (!q) return;
    c->h3 = NULL;
    while (q->streams) {
        ft_h3_stream *st = q->streams;
        q->streams = st->next;
        ft_h3_stream_free(aTHX_ st);
    }
    if (q->h3)   nghttp3_conn_del(q->h3);
    if (q->ossl) ngtcp2_crypto_ossl_ctx_del(q->ossl);   /* frees the SSL too */
    else if (q->ssl) SSL_free(q->ssl);
    if (q->conn) ngtcp2_conn_del(q->conn);
    Safefree(q);
}

#else  /* stubs: no ngtcp2/nghttp3, or an OpenSSL that cannot drive them */

/* Every entry point the h3 half offers, so ft_http.h compiles unchanged and
 * ft_h3_start's own FT_H3_AVAILABLE test is the ONE place that decides. A
 * caller never has to #ifdef, which is also why these are stubs rather than
 * absent: an absent function moves the decision into the preprocessor and
 * into every call site. */
#define FT_H3_AVAILABLE 0
typedef struct ft_h3_stream ft_h3_stream;
static int  ft_h3_connect(pTHX_ ft_conn *c, struct addrinfo *ai) {
    (void)c; (void)ai; return -1; }
static void ft_h3_step(pTHX_ ft_conn *c) {
    ft_conn_fail(aTHX_ c, "HTTP/3 not built (need ngtcp2 + nghttp3)"); }
static void ft_h3_free(pTHX_ ft_conn *c) { (void)c; }
static int  ft_conn_alive_h3(ft_conn *c) { (void)c; return 0; }
static void ft_h3_request(pTHX_ ft_conn *c, SV *future,
                          SV *method, SV *scheme, SV *authority, SV *path,
                          SV *headers_av, SV *body, SV *on_body,
                          SV *on_headers, int simple) {
    (void)c; (void)method; (void)scheme; (void)authority; (void)path;
    (void)headers_av; (void)body; (void)on_body; (void)on_headers;
    (void)simple;
    {   SV *e = sv_2mortal(newSVpvs("Fetch: HTTP/3 not built "
                                    "(need ngtcp2 + nghttp3)"));
        if (hmf_state(aTHX_ future) == HMF_PENDING)
            hmf_settle(aTHX_ future, HMF_FAILED, &e, 1);
    }
}

#endif /* FT_HAVE_QUIC */

#endif /* FT_H3_H */
