#ifndef HM_HTTP3_H
#define HM_HTTP3_H

/* HTTP/3 (nghttp3) over the QUIC transport in hm_quic.h. Built under the
 * same -DHM_HAVE_HTTP3 as the transport, because neither is useful alone.
 *
 * Included from hm_core.h after hm_quic.h. Requests arriving here resolve
 * through the same sync / Future / streaming paths as HTTP/1.1 and HTTP/2:
 * nghttp3 owns framing and QPACK, ngtcp2 owns loss recovery and flow
 * control, and the application sees a PSGI env either way.
 *
 * hm_http2.h is the template throughout, and where a piece of it is already
 * transport-independent this file CALLS it rather than copying it:
 * hm_h2_add_header (retargeted onto an HV so both can use it),
 * hm_h2_hopbyhop, hm_h2_body_sv. Two implementations of header mangling
 * would be two implementations to keep in step.
 *
 * Two things here are genuinely not h2 transliterations:
 *
 *   - The send half is NOT here. QUIC pulls rather than pushes, so what
 *     would be hm_h2_flush_send's counterpart lives in hm_quic.h with the
 *     socket - see the header comment there.
 *   - The data provider fills an IOVEC ARRAY and the buffers it points at
 *     must stay alive until acked_stream_data. nghttp2's model, a memcpy
 *     into a window ngtcp2 owns, does not port. */

#ifdef HM_HAVE_HTTP3

typedef struct hm_h3_stream {
    int64_t  id;
    HV      *env;            /* being built (moved out at dispatch)    */
    SV      *env_rv;         /* kept while awaiting, for access_log    */
    SV      *body;           /* accumulating request body, or NULL     */
    SV      *resp_body;      /* response bytes the data reader feeds   */
    size_t   resp_off;       /* how much has been HANDED to nghttp3    */
    size_t   resp_acked;     /* ...and how much it has finished with   */
    SV      *src_sv;         /* streamed file body: owned, or NULL     */
    int      src_fd;
    off_t    src_off;
    UV       src_rem;
    char    *src_buf;        /* bounce buffer for the file source      */
    size_t   src_buflen;
    size_t   blen;           /* response body length (logging)         */
    int      status;
    int      resp_status;    /* streaming: stashed until close         */
    SV      *resp_headers;
    int      awaiting;       /* parked on a Future                     */
    unsigned char fin;       /* the request stream ended               */
    unsigned char dispatched;
    struct hm_h3_stream *next;
} hm_h3_stream;

static void hm_h3_respond(pTHX_ hm_qconn *qc, hm_h3_stream *st, SV *resp);
static int  hm_h3_resume(pTHX_ hm_qconn *qc, int64_t sid);
static void hm_h3_dispatch(pTHX_ hm_qconn *qc, hm_h3_stream *st);

static int hm_h3_available(void) { return 1; }

/* ---- streams ------------------------------------------------------------- */

static hm_h3_stream *hm_h3_stream_new(pTHX_ hm_qconn *qc, int64_t id) {
    hm_h3_stream *st = (hm_h3_stream *)hm_xcalloc(1, sizeof(hm_h3_stream));
    st->id = id;
    st->env = newHV();
    /* Same reason as the h2 path: a request env holds a few dozen keys and
     * growing the hash one rehash at a time is measurable per request. */
    hv_ksplit(st->env, 64);
    st->next = (hm_h3_stream *)qc->h3_streams;
    qc->h3_streams = st;
    return st;
}

static hm_h3_stream *hm_h3_stream_find(hm_qconn *qc, int64_t id) {
    hm_h3_stream *st;
    for (st = (hm_h3_stream *)qc->h3_streams; st; st = st->next)
        if (st->id == id) return st;
    return NULL;
}

static void hm_h3_src_free(pTHX_ hm_h3_stream *st) {
    hm_bsrc bs;
    if (st->src_buf) { free(st->src_buf); st->src_buf = NULL; st->src_buflen = 0; }
    if (!st->src_sv) return;
    memset(&bs, 0, sizeof bs);
    bs.kind = 1;
    bs.fd   = st->src_fd;
    bs.sv   = st->src_sv;
    hm_bsrc_release(aTHX_ &bs);
    st->src_sv  = NULL;
    st->src_rem = 0;
}

static void hm_h3_stream_free(pTHX_ hm_qconn *qc, hm_h3_stream *st) {
    hm_h3_stream **pp = (hm_h3_stream **)&qc->h3_streams;
    while (*pp) { if (*pp == st) { *pp = st->next; break; } pp = &(*pp)->next; }
    if (st->env)          SvREFCNT_dec((SV *)st->env);
    if (st->env_rv)       SvREFCNT_dec(st->env_rv);
    if (st->body)         SvREFCNT_dec(st->body);
    if (st->resp_body)    SvREFCNT_dec(st->resp_body);
    if (st->resp_headers) SvREFCNT_dec(st->resp_headers);
    hm_h3_src_free(aTHX_ st);
    free(st);
}

/* ---- request: headers -> $env -------------------------------------------- */

static void hm_h3_env_init(pTHX_ hm_qconn *qc, HV *env) {
    hm_loop *loop = qc->srv->loop;
    hm_listener *lst = qc->srv->lst;
    AV *ver = newAV();
    /* Fills the shared header-key table. A process that only ever speaks
     * HTTP/3 has to do this from here or hm_hdrk_lookup never engages - it
     * would fall back safely, just without the point of it. */
    hm_env_init(aTHX);
    av_push(ver, newSViv(1)); av_push(ver, newSViv(1));
    hv_stores(env, "SCRIPT_NAME",       newSVpvs(""));
    /* "HTTP/3", matching h2's "HTTP/2" rather than a dotted form. */
    hv_stores(env, "SERVER_PROTOCOL",   newSVpvs("HTTP/3"));
    hv_stores(env, "SERVER_NAME",       newSVpv(lst && lst->host ? lst->host : "0.0.0.0", 0));
    hv_stores(env, "SERVER_PORT",       newSViv(lst ? lst->port : 0));
    if (qc->peer_str[0]) {
        hv_stores(env, "REMOTE_ADDR", newSVpv(qc->peer_str, 0));
        hv_stores(env, "REMOTE_HOST", newSVpv(qc->peer_str, 0));
    }
    if (qc->peer_port) hv_stores(env, "REMOTE_PORT", newSViv(qc->peer_port));
    hv_stores(env, "QUERY_STRING",      newSVpvs(""));
    hv_stores(env, "psgi.version",      newRV_noinc((SV *)ver));
    /* QUIC has no cleartext mode, so this is https before :scheme is even
     * read - and :scheme may still override it, as on h2. */
    hv_stores(env, "psgi.url_scheme",   newSVpvs("https"));
    hv_stores(env, "psgi.multithread",  newSViv(0));
    hv_stores(env, "psgi.multiprocess", newSViv(1));
    hv_stores(env, "psgi.run_once",     newSViv(0));
    hv_stores(env, "psgi.streaming",    newSViv(1));
    hv_stores(env, "psgi.nonblocking",  newSViv(1));
    hv_stores(env, "psgi.errors",       newRV_inc((SV *)PL_stderrgv));
    /* Honest here: dispatch is on stream end, so the whole body is in hand
     * before the application sees it. Without this an application cannot
     * tell that a bodied request with no content-length - which is what h3
     * sends for a streamed upload - can be read to EOF safely. */
    hv_stores(env, "psgix.input.buffered", newSViv(1));
    /* HTTPS, SSL_PROTOCOL, SSL_CIPHER and the SSL_CLIENT_* family, through the
     * same function the TCP side uses - so mTLS reports identically on every
     * transport instead of working on one and silently not on the other.
     * SSL_KTLS is passed 0 because there is no kernel record layer for QUIC,
     * which is a fact about the transport and not an absent value. */
    hm_tls_env_from(aTHX_ env, qc->tls_proto, qc->tls_cipher, qc->tls_peer, 0);
    /* psgix.hyperman.stream, the ticket ABI v6's stream_open takes. Not
     * psgix.hyperman.conn: that names a descriptor an application may take
     * over, and HTTP/3 has nothing to put behind it - which is what makes
     * Hyperman::detach croak here, as it already does on HTTP/2. */
    if (!loop->self_sv) loop->self_sv = hm_loop_to_sv(aTHX_ loop);
    hv_stores(env, "psgix.loop",        SvREFCNT_inc(loop->self_sv));
}

/* ---- nghttp3 callbacks --------------------------------------------------- */

static int hm_h3_cb_begin_headers(nghttp3_conn *conn, int64_t stream_id,
                                  void *conn_user_data, void *stream_user_data) {
    dTHX;
    hm_qconn *qc = (hm_qconn *)conn_user_data;
    hm_h3_stream *st;
    (void)stream_user_data;
    st = hm_h3_stream_find(qc, stream_id);
    if (!st) st = hm_h3_stream_new(aTHX_ qc, stream_id);
    hm_h3_env_init(aTHX_ qc, st->env);
    nghttp3_conn_set_stream_user_data(conn, stream_id, st);
    return 0;
}

static int hm_h3_cb_recv_header(nghttp3_conn *conn, int64_t stream_id,
                                int32_t token, nghttp3_rcbuf *name,
                                nghttp3_rcbuf *value, uint8_t flags,
                                void *conn_user_data, void *stream_user_data) {
    dTHX;
    hm_h3_stream *st = (hm_h3_stream *)stream_user_data;
    nghttp3_vec n, v;
    (void)conn; (void)stream_id; (void)token; (void)flags; (void)conn_user_data;
    if (!st || !st->env) return 0;
    n = nghttp3_rcbuf_get_buf(name);
    v = nghttp3_rcbuf_get_buf(value);
    /* The h2 implementation, shared rather than copied: HTTP/3's
     * pseudo-headers are HTTP/2's and QPACK yields the same lowercase pairs. */
    hm_h2_add_header(aTHX_ st->env, (const char *)n.base, n.len,
                     (const char *)v.base, v.len);
    return 0;
}

/* The h3 counterpart of the HTTP/2 rule: an Extended CONNECT stream is
 * dispatched when its headers are complete, because it has no end for
 * end_stream to fire on. */
static int hm_h3_cb_end_headers(nghttp3_conn *conn, int64_t stream_id,
                                int fin, void *conn_user_data,
                                void *stream_user_data) {
    dTHX;
    hm_qconn *qc = (hm_qconn *)conn_user_data;
    hm_h3_stream *st = (hm_h3_stream *)stream_user_data;
    (void)conn; (void)stream_id; (void)fin;
    if (!st || st->dispatched || !st->env) return 0;
    if (!hm_h2_is_connect(aTHX_ st->env)) return 0;
    hm_h3_dispatch(aTHX_ qc, st);
    return 0;
}

static int hm_h3_cb_recv_data(nghttp3_conn *conn, int64_t stream_id,
                              const uint8_t *data, size_t datalen,
                              void *conn_user_data, void *stream_user_data) {
    dTHX;
    hm_qconn *qc = (hm_qconn *)conn_user_data;
    hm_h3_stream *st = (hm_h3_stream *)stream_user_data;
    (void)conn; (void)stream_id;
    /* Same rule as the h2 path: a handle with a read callback takes these
     * bytes, because an Extended CONNECT stream never ends and buffering it
     * would grow forever. */
    if (!hm_stream_deliver(aTHX_ qc->srv->lst->udp_fd, qc->id, stream_id,
                           (const char *)data, (STRLEN)datalen, 0)
        && st) {
        if (!st->body) st->body = newSVpvs("");
        sv_catpvn(st->body, (const char *)data, datalen);
    }
    /* Flow control is ngtcp2's here, not nghttp3's - the opposite of h2,
     * where nghttp2 owned it and there was nothing to do. Forgetting this
     * stalls any upload larger than the initial window. */
    ngtcp2_conn_extend_max_stream_offset(qc->conn, stream_id, datalen);
    ngtcp2_conn_extend_max_offset(qc->conn, datalen);
    return 0;
}

/* Bytes nghttp3 consumed off a stream without handing them to recv_data -
 * QPACK and control-stream traffic. The window has to be reopened for those
 * too, or the peer's encoder stream stalls and every later request blocks. */
static int hm_h3_cb_deferred_consume(nghttp3_conn *conn, int64_t stream_id,
                                     size_t consumed, void *conn_user_data,
                                     void *stream_user_data) {
    hm_qconn *qc = (hm_qconn *)conn_user_data;
    (void)conn; (void)stream_user_data;
    ngtcp2_conn_extend_max_stream_offset(qc->conn, stream_id, consumed);
    ngtcp2_conn_extend_max_offset(qc->conn, consumed);
    return 0;
}

static int hm_h3_cb_end_stream(nghttp3_conn *conn, int64_t stream_id,
                               void *conn_user_data, void *stream_user_data) {
    dTHX;
    hm_qconn *qc = (hm_qconn *)conn_user_data;
    hm_h3_stream *st = (hm_h3_stream *)stream_user_data;
    (void)conn; (void)stream_id;
    if (!st || st->dispatched) return 0;
    st->fin = 1;
    hm_h3_dispatch(aTHX_ qc, st);
    return 0;
}

static int hm_h3_cb_stream_close(nghttp3_conn *conn, int64_t stream_id,
                                 uint64_t app_error_code,
                                 void *conn_user_data, void *stream_user_data) {
    dTHX;
    hm_qconn *qc = (hm_qconn *)conn_user_data;
    hm_h3_stream *st = (hm_h3_stream *)stream_user_data;
    (void)app_error_code;
    /* A peer can reset one stream out of many; a stream handle open on it
     * has to hear about that before st is freed underneath it. */
    hm_stream_h2_gone(aTHX_ qc->srv->lst->udp_fd, qc->id, stream_id);
    if (st) {
        nghttp3_conn_set_stream_user_data(conn, stream_id, NULL);
        hm_h3_stream_free(aTHX_ qc, st);
    }
    return 0;
}

/* nghttp3 has finished with the first n bytes it was handed: they can be
 * released. This is the half nghttp2 did not need, because there the bytes
 * were memcpy'd into a window the library owned. */
static int hm_h3_cb_acked_stream_data(nghttp3_conn *conn, int64_t stream_id,
                                      uint64_t datalen, void *conn_user_data,
                                      void *stream_user_data) {
    hm_h3_stream *st = (hm_h3_stream *)stream_user_data;
    (void)conn; (void)stream_id; (void)conn_user_data;
    if (st) st->resp_acked += (size_t)datalen;
    return 0;
}

static int hm_h3_cb_stop_sending(nghttp3_conn *conn, int64_t stream_id,
                                 uint64_t app_error_code, void *conn_user_data,
                                 void *stream_user_data) {
    hm_qconn *qc = (hm_qconn *)conn_user_data;
    (void)conn; (void)stream_user_data;
    ngtcp2_conn_shutdown_stream_read(qc->conn, 0, stream_id, app_error_code);
    return 0;
}

static int hm_h3_cb_reset_stream(nghttp3_conn *conn, int64_t stream_id,
                                 uint64_t app_error_code, void *conn_user_data,
                                 void *stream_user_data) {
    hm_qconn *qc = (hm_qconn *)conn_user_data;
    (void)conn; (void)stream_user_data;
    ngtcp2_conn_shutdown_stream_write(qc->conn, 0, stream_id, app_error_code);
    return 0;
}

static void hm_h3_cb_rand(uint8_t *dest, size_t destlen) {
    hm_quic_rand_bytes(dest, destlen);
}

/* ---- response ------------------------------------------------------------ */

/* The data reader. It hands back POINTERS, and everything they point at must
 * stay valid until acked_stream_data says otherwise - which is why the SV is
 * held with an explicit reference and the file source has a bounce buffer
 * that is not refilled until the previous fill is acked.
 *
 * The in-memory case points straight into the SV: zero-copy, and strictly
 * better than the h2 path's memcpy. It is safe because a Writer buffers to
 * close and never appends to a body with bytes in flight.
 *
 * sendfile cannot be used anywhere here: these bytes have to be encrypted
 * into QUIC packets in userspace, so there is no kernel path for them. */
static nghttp3_ssize hm_h3_read_data(nghttp3_conn *conn, int64_t stream_id,
                                     nghttp3_vec *vec, size_t veccnt,
                                     uint32_t *pflags, void *conn_user_data,
                                     void *stream_user_data) {
    dTHX;
    hm_h3_stream *st = (hm_h3_stream *)stream_user_data;
    (void)conn; (void)stream_id; (void)conn_user_data;
    if (!st || veccnt == 0) { *pflags |= NGHTTP3_DATA_FLAG_EOF; return 0; }

    if (st->src_sv) {                        /* a file body */
        size_t want;
        ssize_t got;
        /* Not refilled while the previous fill is unacked: nghttp3 still
         * holds a pointer into this buffer. */
        if (st->resp_off > st->resp_acked) return NGHTTP3_ERR_WOULDBLOCK;
        if (st->src_rem == 0) { *pflags |= NGHTTP3_DATA_FLAG_EOF; return 0; }
        if (!st->src_buf) {
            st->src_buflen = HM_BSRC_CHUNK;
            st->src_buf = (char *)hm_xmalloc(st->src_buflen);
        }
        want = st->src_rem < st->src_buflen ? (size_t)st->src_rem
                                            : st->src_buflen;
        got = hm_os_pread(st->src_fd, st->src_buf, want, st->src_off);
        if (got <= 0) {                      /* truncated under us */
            st->src_rem = 0;
            *pflags |= NGHTTP3_DATA_FLAG_EOF;
            return 0;
        }
        st->src_off += got;
        st->src_rem -= (UV)got;
        st->resp_off += (size_t)got;
        vec[0].base = (uint8_t *)st->src_buf;
        vec[0].len  = (size_t)got;
        if (st->src_rem == 0) *pflags |= NGHTTP3_DATA_FLAG_EOF;
        return 1;
    }

    {
        STRLEN blen = 0;
        const char *bp = "";
        if (st->resp_body) bp = SvPV(st->resp_body, blen);
        if (st->resp_off >= blen) { *pflags |= NGHTTP3_DATA_FLAG_EOF; return 0; }
        vec[0].base = (uint8_t *)(bp + st->resp_off);
        vec[0].len  = blen - st->resp_off;
        st->resp_off = blen;
        *pflags |= NGHTTP3_DATA_FLAG_EOF;
        return 1;
    }
}

static void hm_h3_submit_response(pTHX_ hm_qconn *qc, hm_h3_stream *st,
                                  int status, AV *hav) {
    SSize_t hn = hav ? av_len(hav) + 1 : 0;
    size_t maxnv = 1 + (size_t)(hn / 2);
    nghttp3_nv *nva = (nghttp3_nv *)hm_xmalloc(maxnv * sizeof(nghttp3_nv));
    char **freelist = (char **)hm_xmalloc(maxnv * sizeof(char *));
    size_t nfree = 0, n = 0;
    char sbuf[8];
    int sl;
    nghttp3_data_reader dr;
    SSize_t i;

    sl = snprintf(sbuf, sizeof(sbuf), "%d", status);
    nva[n].name = (uint8_t *)":status"; nva[n].namelen = 7;
    nva[n].value = (uint8_t *)sbuf; nva[n].valuelen = (size_t)sl;
    nva[n].flags = NGHTTP3_NV_FLAG_NONE; n++;

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
        /* HTTP/3 forbids the same set HTTP/2 does, so this is hm_http2.h's
         * predicate rather than a second copy of the list. */
        if (hm_h2_hopbyhop(lname, kl)) { free(lname); continue; }
        freelist[nfree++] = lname;
        nva[n].name = (uint8_t *)lname; nva[n].namelen = kl;
        nva[n].value = (uint8_t *)vs;   nva[n].valuelen = vl;
        nva[n].flags = NGHTTP3_NV_FLAG_NONE; n++;
    }

    st->status   = status;
    st->resp_off = 0;
    st->resp_acked = 0;
    dr.read_data = hm_h3_read_data;
    /* nva is copied by nghttp3 unless NO_COPY is asked for, so the freelist
     * below is safe - the same contract hm_h2_submit_response relies on. */
    nghttp3_conn_submit_response((nghttp3_conn *)qc->h3, st->id, nva, n, &dr);
    /* NOT counted here. The h2 path adds the body length at submit
     * because that is its only chance, but on QUIC every datagram is
     * counted as it is actually sent - adding it here as well counts
     * the same bytes twice. */

    for (n = 0; n < nfree; n++) free(freelist[n]);
    free(freelist);
    free(nva);
}

static void hm_h3_submit_status(pTHX_ hm_qconn *qc, hm_h3_stream *st,
                                int status, const char *ctype) {
    AV *hav = newAV();
    av_push(hav, newSVpvs("content-type"));
    av_push(hav, newSVpv(ctype, 0));
    hm_h3_submit_response(aTHX_ qc, st, status, hav);
    SvREFCNT_dec((SV *)hav);
}

/* A file body onto the stream, read per window rather than slurped. */
static int hm_h3_body_src(pTHX_ hm_h3_stream *st, SV **s2, AV *hav) {
    hm_bsrc bs;
    UV clv = 0;
    int cl_seen;
    if (!(s2 && SvROK(*s2)) || SvTYPE(SvRV(*s2)) == SVt_PVAV) return 0;
    cl_seen = hm_hav_clen(aTHX_ hav, &clv);
    memset(&bs, 0, sizeof bs);
    if (!hm_bsrc_lift(aTHX_ *s2, &bs, cl_seen, clv)) return 0;
    if (bs.kind != 1) { hm_bsrc_release(aTHX_ &bs); return 0; }
    st->src_sv  = bs.sv;
    st->src_fd  = bs.fd;
    st->src_off = bs.off;
    st->src_rem = bs.remaining;
    st->blen    = (size_t)bs.remaining;
    return 1;
}

/* ---- the streaming writer ------------------------------------------------ */

static hm_qconn *hm_h3_qconn(int fd, UV qid) {
    hm_loop *loop = hm_cur_loop;
    hm_listener *lst = loop ? hm_listener_for_udp(loop, fd) : NULL;
    hm_quic_srv *srv = lst ? (hm_quic_srv *)lst->quic : NULL;
    return srv ? hm_quic_conn_by_id(srv, qid) : NULL;
}

static void hm_h3_writer_write(pTHX_ int fd, UV qid, int64_t sid, SV *data) {
    hm_qconn *qc = hm_h3_qconn(fd, qid);
    hm_h3_stream *st = qc ? hm_h3_stream_find(qc, sid) : NULL;
    if (!st) return;
    if (!st->resp_body) st->resp_body = newSVpvs("");
    sv_catsv(st->resp_body, data);
}

static void hm_h3_writer_close(pTHX_ int fd, UV qid, int64_t sid) {
    hm_qconn *qc = hm_h3_qconn(fd, qid);
    hm_h3_stream *st = qc ? hm_h3_stream_find(qc, sid) : NULL;
    AV *hav;
    if (!st) return;
    { STRLEN l; if (st->resp_body) { (void)SvPV(st->resp_body, l); st->blen = l; } }
    hav = (st->resp_headers && SvROK(st->resp_headers))
        ? (AV *)SvRV(st->resp_headers) : NULL;
    hm_h3_submit_response(aTHX_ qc, st, st->resp_status ? st->resp_status : 200,
                          hav);
    hm_quic_write(aTHX_ qc);
}

/* psgi.streaming responder for h3: 3-arg delivers, 2-arg buffers via a
 * Hyperman::Writer (h3 form) that submits at close. */
XS_INTERNAL(hm_xs_h3responder);
XS_INTERNAL(hm_xs_h3responder) {
    dXSARGS;
    hm_clos *cl = hm_clos_of(aTHX_ cv);
    hm_qconn *qc;
    hm_h3_stream *st;
    AV *rav, *hav = NULL;
    SSize_t n;
    SV **s0, **s1;
    int fd, status;
    UV qid;
    int64_t sid;
    if (!cl) XSRETURN_EMPTY;
    fd = (int)cl->i; qid = cl->u; sid = (int64_t)SvIV(cl->d);
    qc = hm_h3_qconn(fd, qid);
    st = qc ? hm_h3_stream_find(qc, sid) : NULL;
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
        hm_h3_src_free(aTHX_ st);
        if (!hm_h3_body_src(aTHX_ st, s2, hav))
            st->resp_body = hm_h2_body_sv(aTHX_ s2, &st->blen);
        hm_h3_submit_response(aTHX_ qc, st, status, hav);
        hm_quic_write(aTHX_ qc);
        XSRETURN_EMPTY;
    }
    st->resp_status = status;
    if (hav) st->resp_headers = newRV_inc((SV *)hav);
    if (!st->resp_body) st->resp_body = newSVpvs("");
    {
        AV *w = newAV();
        SV *wrv;
        av_push(w, newSViv(fd));
        av_push(w, newSVuv(qid));
        av_push(w, newSViv((IV)sid));
        av_push(w, newSVpvs("h3"));
        wrv = newRV_noinc((SV *)w);
        sv_bless(wrv, gv_stashpv("Hyperman::Writer", GV_ADD));
        ST(0) = sv_2mortal(wrv);
        XSRETURN(1);
    }
}

static void hm_h3_run_delayed(pTHX_ hm_qconn *qc, hm_h3_stream *st, SV *code) {
    SV *responder = hm_closure(aTHX_ hm_xs_h3responder, NULL, NULL, NULL,
                               sv_2mortal(newSViv((IV)st->id)),
                               (IV)qc->srv->lst->udp_fd, qc->id);
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
        hm_h3_submit_status(aTHX_ qc, st, 500, "text/plain");
    }
    FREETMPS; LEAVE;
    SvREFCNT_dec(responder);
}

/* sync array / streaming CV / invalid -> a response */
static void hm_h3_respond(pTHX_ hm_qconn *qc, hm_h3_stream *st, SV *resp) {
    if (resp && SvROK(resp) && SvTYPE(SvRV(resp)) == SVt_PVAV) {
        AV *rav = (AV *)SvRV(resp);
        SV **s0 = av_fetch(rav, 0, 0);
        SV **s1 = av_fetch(rav, 1, 0);
        SV **s2 = av_fetch(rav, 2, 0);
        int status = s0 ? (int)SvIV(*s0) : 200;
        AV *hav = (s1 && SvROK(*s1) && SvTYPE(SvRV(*s1)) == SVt_PVAV)
                ? (AV *)SvRV(*s1) : NULL;
        if (st->resp_body) { SvREFCNT_dec(st->resp_body); st->resp_body = NULL; }
        hm_h3_src_free(aTHX_ st);
        if (!hm_h3_body_src(aTHX_ st, s2, hav))
            st->resp_body = hm_h2_body_sv(aTHX_ s2, &st->blen);
        hm_h3_submit_response(aTHX_ qc, st, status, hav);
    } else if (resp && SvROK(resp) && SvTYPE(SvRV(resp)) == SVt_PVCV) {
        hm_h3_run_delayed(aTHX_ qc, st, resp);
    } else {
        if (st->resp_body) SvREFCNT_dec(st->resp_body);
        st->resp_body = newSVpvs("Internal Server Error");
        st->blen = 21;
        hm_h3_submit_status(aTHX_ qc, st, 500, "text/plain");
    }
}

/* Deliver a parked response once its Future settles. */
XS_INTERNAL(hm_xs_h3park_cb);
XS_INTERNAL(hm_xs_h3park_cb) {
    dXSARGS;
    hm_clos *cl = hm_clos_of(aTHX_ cv);
    hm_qconn *qc;
    hm_h3_stream *st;
    SV *f, *resp = NULL;
    IV state;
    int fd;
    UV qid;
    int64_t sid;
    if (!cl || items < 1) XSRETURN_EMPTY;
    f = ST(0);
    fd = (int)cl->i; qid = cl->u; sid = (int64_t)SvIV(cl->d);
    qc = hm_h3_qconn(fd, qid);
    st = qc ? hm_h3_stream_find(qc, sid) : NULL;
    if (!st) XSRETURN_EMPTY;
    state = hm_any_state(aTHX_ f);
    if (state == HMF_DONE) {
        AV *vals = newAV();
        SV **e;
        hm_any_values(aTHX_ f, state, vals);
        e = av_len(vals) >= 0 ? av_fetch(vals, 0, 0) : NULL;
        if (e) resp = sv_mortalcopy(*e);
        SvREFCNT_dec((SV *)vals);
    }
    st->awaiting = 0;
    hm_h3_respond(aTHX_ qc, st, resp);
    if (hm_logging(qc->srv->loop) && st->env_rv)
        hm_access_log(aTHX_ qc->srv->loop, st->env_rv, st->status,
                      (ssize_t)st->blen);
    hm_quic_write(aTHX_ qc);
    XSRETURN_EMPTY;
}

static void hm_h3_dispatch(pTHX_ hm_qconn *qc, hm_h3_stream *st) {
    hm_loop *loop = qc->srv->loop;
    HV *env = st->env;
    SV *env_rv, *resp;
    st->dispatched = 1;
    st->env = NULL;
    if (!hv_exists(env, "psgi.input", 10)) {
        if (st->body)
            hv_stores(env, "psgi.input",
                      hm_new_input(aTHX_ SvPVX(st->body), SvCUR(st->body)));
        else
            hv_stores(env, "psgi.input", SvREFCNT_inc(hm_empty_input));
    }
    /* The stream ticket, built here because it needs the stream id. */
    {
        AV *tick = newAV();
        av_extend(tick, 2);
        av_store(tick, 0, newSViv(qc->srv->lst->udp_fd));
        av_store(tick, 1, newSVuv(qc->id));
        av_store(tick, 2, newSViv((IV)st->id));
        hv_stores(env, "psgix.hyperman.stream", newRV_noinc((SV *)tick));
    }
    env_rv = newRV_noinc((SV *)env);
    resp = hm_call_app(aTHX_ loop, env_rv);
    loop->requests++;
    loop->h3_requests++;

    if (resp && hm_is_awaitable(aTHX_ resp)) {
        SV *cb = hm_closure(aTHX_ hm_xs_h3park_cb, NULL, NULL, NULL,
                            sv_2mortal(newSViv((IV)st->id)),
                            (IV)qc->srv->lst->udp_fd, qc->id);
        st->awaiting = 1;
        st->env_rv = SvREFCNT_inc(env_rv);
        hm_any_on_ready(aTHX_ resp, cb);
        SvREFCNT_dec(cb);
        SvREFCNT_dec(resp);
        SvREFCNT_dec(env_rv);
        return;
    }

    /* Same rule as the h2 path: a stream handle already answered, so the
     * application's return value is a sentinel and submitting it would be a
     * second response on one stream. */
    if (st->status) {
        if (resp) SvREFCNT_dec(resp);
        SvREFCNT_dec(env_rv);
        return;
    }
    hm_h3_respond(aTHX_ qc, st, resp);
    if (hm_logging(loop))
        hm_access_log(aTHX_ loop, env_rv, st->status, (ssize_t)st->blen);
    if (resp) SvREFCNT_dec(resp);
    SvREFCNT_dec(env_rv);
}

/* ---- session ------------------------------------------------------------- */

/* Built from the QUIC handshake_completed callback: the control and QPACK
 * streams cannot be opened before there is a connection to open them on. */
static int hm_h3_session_start(pTHX_ hm_qconn *qc) {
    nghttp3_callbacks cbs;
    nghttp3_settings settings;
    nghttp3_conn *h3 = NULL;
    int64_t ctrl = -1, qenc = -1, qdec = -1;

    memset(&cbs, 0, sizeof(cbs));
    cbs.begin_headers      = hm_h3_cb_begin_headers;
    cbs.recv_header        = hm_h3_cb_recv_header;
    cbs.end_headers        = hm_h3_cb_end_headers;
    cbs.recv_data          = hm_h3_cb_recv_data;
    cbs.deferred_consume   = hm_h3_cb_deferred_consume;
    cbs.end_stream         = hm_h3_cb_end_stream;
    cbs.stream_close       = hm_h3_cb_stream_close;
    cbs.acked_stream_data  = hm_h3_cb_acked_stream_data;
    cbs.stop_sending       = hm_h3_cb_stop_sending;
    cbs.reset_stream       = hm_h3_cb_reset_stream;
    cbs.rand               = hm_h3_cb_rand;

    nghttp3_settings_default(&settings);
    settings.qpack_max_dtable_capacity = 4096;
    settings.qpack_blocked_streams     = 100;
    /* RFC 9220 Extended CONNECT, the HTTP/3 spelling of the HTTP/2 setting
     * in hm_h2_submit_our_settings. Same purpose: a client will not try a
     * WebSocket over h3 unless the server has said it understands
     * :protocol. */
    settings.enable_connect_protocol   = 1;

    if (nghttp3_conn_server_new(&h3, &cbs, &settings, NULL, qc) != 0) return -1;

    if (ngtcp2_conn_open_uni_stream(qc->conn, &ctrl, NULL) != 0
        || nghttp3_conn_bind_control_stream(h3, ctrl) != 0
        || ngtcp2_conn_open_uni_stream(qc->conn, &qenc, NULL) != 0
        || ngtcp2_conn_open_uni_stream(qc->conn, &qdec, NULL) != 0
        || nghttp3_conn_bind_qpack_streams(h3, qenc, qdec) != 0) {
        nghttp3_conn_del(h3);
        return -1;
    }
    qc->h3 = h3;
    return 0;
}

static void hm_h3_session_free(pTHX_ hm_qconn *qc) {
    if (!qc->h3) return;
    while (qc->h3_streams)
        hm_h3_stream_free(aTHX_ qc, (hm_h3_stream *)qc->h3_streams);
    nghttp3_conn_del((nghttp3_conn *)qc->h3);
    qc->h3 = NULL;
}

/* ---- the seams the transport reaches up through ------------------------- */

/* Stream bytes off ngtcp2 into nghttp3. The window is credited from
 * recv_data and deferred_consume between them, so nothing is credited here.
 * 0 to carry on, -1 to kill the connection. */
static int hm_h3_recv_stream(pTHX_ hm_qconn *qc, int64_t sid,
                             const uint8_t *data, size_t datalen, int fin) {
    nghttp3_ssize n;
    PERL_UNUSED_CONTEXT;
    if (!qc->h3) return 0;
    n = nghttp3_conn_read_stream((nghttp3_conn *)qc->h3, sid, data, datalen, fin);
    return n < 0 ? -1 : 0;
}

/* ngtcp2 says a stream is finished. nghttp3 has to be told, or its own
 * bookkeeping keeps the stream alive forever. */
static int hm_h3_stream_gone(pTHX_ hm_qconn *qc, int64_t sid,
                             uint64_t app_error_code) {
    PERL_UNUSED_CONTEXT;
    if (!qc->h3) return 0;
    if (nghttp3_conn_close_stream((nghttp3_conn *)qc->h3, sid,
                                  app_error_code) != 0)
        return -1;
    return 0;
}

static int hm_h3_acked(pTHX_ hm_qconn *qc, int64_t sid, uint64_t n) {
    PERL_UNUSED_CONTEXT;
    if (!qc->h3) return 0;
    if (nghttp3_conn_add_ack_offset((nghttp3_conn *)qc->h3, sid, n) != 0)
        return -1;
    /* The bounce buffer a file source handed out is free again, so a reader
     * that deferred on it can be asked once more. */
    return hm_h3_resume(aTHX_ qc, sid);
}

/* What HTTP/3 wants sent next, as an iovec the transport hands to ngtcp2.
 * This is the pull the h2 template has no equivalent of. */
static nghttp3_ssize hm_h3_pull(pTHX_ hm_qconn *qc, int64_t *psid, int *pfin,
                                nghttp3_vec *vec, size_t veccnt) {
    nghttp3_ssize n;
    PERL_UNUSED_CONTEXT;
    *psid = -1; *pfin = 0;
    if (!qc->h3) return 0;
    n = nghttp3_conn_writev_stream((nghttp3_conn *)qc->h3, psid, pfin,
                                   vec, veccnt);
    if (n < 0) { *psid = -1; return -1; }
    return n;
}

/* The peer granted more room on a stream that had run out. Without this a
 * stream blocked once by flow control is blocked FOREVER: nghttp3 stops
 * offering it and nothing ever puts it back. It shows up as a hang only
 * under concurrency, when the connection window is exhausted - a single
 * large response never reaches it. */
static int hm_h3_unblock(pTHX_ hm_qconn *qc, int64_t sid) {
    PERL_UNUSED_CONTEXT;
    if (!qc->h3) return 0;
    return nghttp3_conn_unblock_stream((nghttp3_conn *)qc->h3, sid) == 0
           ? 0 : -1;
}

/* A deferred data reader can be asked again. The file source returns
 * WOULDBLOCK while its bounce buffer is still unacked, so an ack is exactly
 * when it becomes worth retrying. */
static int hm_h3_resume(pTHX_ hm_qconn *qc, int64_t sid) {
    PERL_UNUSED_CONTEXT;
    if (!qc->h3) return 0;
    return nghttp3_conn_resume_stream((nghttp3_conn *)qc->h3, sid) == 0
           ? 0 : -1;
}

/* How much of what was pulled the transport actually took. */
static int hm_h3_wrote(pTHX_ hm_qconn *qc, int64_t sid, size_t n) {
    PERL_UNUSED_CONTEXT;
    if (!qc->h3 || sid < 0) return 0;
    return nghttp3_conn_add_write_offset((nghttp3_conn *)qc->h3, sid, n) == 0
           ? 0 : -1;
}

#else /* !HM_HAVE_HTTP3 */

static int hm_h3_available(void) { return 0; }
static void hm_h3_writer_write(pTHX_ int fd, UV qid, int64_t sid, SV *d)
    { PERL_UNUSED_CONTEXT; (void)fd; (void)qid; (void)sid; (void)d; }
static void hm_h3_writer_close(pTHX_ int fd, UV qid, int64_t sid)
    { PERL_UNUSED_CONTEXT; (void)fd; (void)qid; (void)sid; }

#endif /* HM_HAVE_HTTP3 */

#endif /* HM_HTTP3_H */
