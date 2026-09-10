#ifndef HM_STREAM_H
#define HM_STREAM_H

/* ABI v6 stream handles: one transport-neutral way to write a response body
 * a piece at a time.
 *
 * hm_detach hands over a file descriptor, and that is why it refuses HTTP/2
 * and TLS. Those refusals are right, not gaps: an h2 stream is one of many on
 * a shared connection, so no fd means "this stream", and a TLS session's
 * state belongs to the server rather than to the socket. The seam that works
 * on every transport is therefore a HANDLE, and this file is it - one
 * registry with a transport branch inside, so a caller never tests the
 * protocol.
 *
 * Included from hm_core.h after hm_http2.h, because it is built on both
 * halves: hm_start_stream / hm_stream_write / hm_stream_close for HTTP/1.1
 * and the nghttp2 data provider for HTTP/2.
 *
 * The handle belongs to whoever opened it, from stream_open until
 * stream_close. Nothing else ever frees one - a connection that goes away
 * only MARKS its handles dead and fires their abort callbacks, so a write
 * arriving afterwards is an error return and not a read of freed memory.
 * Every entry point validates the pointer by finding it on the live list
 * first, which is also what keeps a recycled address from being mistaken for
 * the handle that used to live there. */

#define HM_STREAM_H1 0
#define HM_STREAM_H2 1

typedef struct hm_stream {
    UV        serial;          /* names the handle in diagnostics; the list
                                * membership is what proves it is live   */
    hm_loop  *loop;
    int       fd;
    UV        cid;             /* connection generation (the detach ticket) */
    int64_t   sid;             /* h2 stream id, or -1 for HTTP/1.1       */
    unsigned char kind;        /* HM_STREAM_H1 / HM_STREAM_H2            */
    unsigned char dead;        /* the stream is gone                     */
    unsigned char paused;      /* over the high-water mark               */
    unsigned char aborted;     /* the abort callback has already fired   */
    hm_abi_stream_cb drain_cb; void *drain_ud;
    hm_abi_stream_cb abort_cb; void *abort_ud;
    hm_abi_stream_data_cb data_cb; void *data_ud;   /* v8, the read half */
    struct hm_stream *next;
} hm_stream;

static hm_stream *hm_streams        = NULL;
static UV         hm_stream_serials = 0;

/* Live iff it is on the list. A pointer that is not is either already
 * closed or was never a handle, and either way must not be dereferenced. */
static hm_stream *hm_stream_of(void *h) {
    hm_stream *s;
    if (!h) return NULL;
    for (s = hm_streams; s; s = s->next) if ((void *)s == h) return s;
    return NULL;
}

/* The connection this handle names, or NULL if it has been closed or the fd
 * was reused - the generation check is the whole point of carrying cid. */
static hm_conn *hm_stream_conn(hm_stream *s) {
    hm_conn *c;
    if (!s->loop || s->fd < 0 || s->fd >= HM_MAXFD) return NULL;
    c = s->loop->conns[s->fd];
    return (c && c->id == s->cid && !c->detached) ? c : NULL;
}

static void hm_stream_mark_dead(hm_stream *s) {
    if (s->dead) return;
    s->dead = 1;
    if (s->paused) { s->paused = 0; hm_stream_paused_n--; }
}

/* Fire every pending abort callback. Each one may close its own handle, or
 * anyone else's, so the list is re-scanned from the top after every call
 * rather than walked with a saved next pointer. */
static void hm_stream_fire_aborts(pTHX) {
    int again = 1;
    while (again) {
        hm_stream *s;
        again = 0;
        for (s = hm_streams; s; s = s->next) {
            if (s->dead && !s->aborted && s->abort_cb) {
                hm_abi_stream_cb cb = s->abort_cb;
                void *ud = s->abort_ud;
                s->aborted = 1;
                cb(aTHX_ (void *)s, ud);
                again = 1;
                break;
            }
        }
    }
}

/* A whole connection went away (close, or a detach handing the fd on). */
static void hm_stream_conn_gone(pTHX_ int fd, UV id) {
    hm_stream *s;
    if (!hm_stream_live_n) return;
    for (s = hm_streams; s; s = s->next)
        if (s->fd == fd && s->cid == id) hm_stream_mark_dead(s);
    hm_stream_fire_aborts(aTHX);
}

/* One h2 stream out of many went away - the peer reset it, or it finished. */
static void hm_stream_h2_gone(pTHX_ int fd, UV id, int64_t sid) {
    hm_stream *s;
    if (!hm_stream_live_n) return;
    for (s = hm_streams; s; s = s->next)
        if (s->fd == fd && s->cid == id && s->sid == sid) hm_stream_mark_dead(s);
    hm_stream_fire_aborts(aTHX);
}

/* Output that was over the high-water mark has gone out. Same re-scan rule
 * as the aborts: a drain callback's whole job is to write more. */
static void hm_stream_drained(pTHX_ hm_conn *c) {
    int again = 1;
    while (again) {
        hm_stream *s;
        again = 0;
        for (s = hm_streams; s; s = s->next) {
            if (s->paused && s->fd == c->fd && s->cid == c->id) {
                hm_abi_stream_cb cb = s->drain_cb;
                void *ud = s->drain_ud;
                s->paused = 0;
                hm_stream_paused_n--;
                again = 1;
                if (cb) cb(aTHX_ (void *)s, ud);
                break;
            }
        }
    }
}

/* Take a handle off the registry without freeing it. Ending a body can close
 * the connection underneath us - EOF-delimited HTTP/1.1 always does - and a
 * handle that is deliberately finishing must not then be told its stream went
 * away. So stream_close unlinks first, ends the body, and frees afterwards. */
static void hm_stream_unlink(hm_stream *s) {
    hm_stream **pp = &hm_streams;
    while (*pp) {
        if (*pp == s) { *pp = s->next; break; }
        pp = &(*pp)->next;
    }
    s->next = NULL;
    if (s->paused) { s->paused = 0; hm_stream_paused_n--; }
    hm_stream_live_n--;
}

/* ---- the HTTP/2 half ---------------------------------------------------- */

#ifdef HM_HAVE_NGHTTP2

static hm_h2_stream *hm_stream_h2_st(hm_conn *c, int64_t sid) {
    hm_h2_sess *s;
    if (!c->h2 || sid < 0 || sid > 0x7fffffff) return NULL;
    s = (hm_h2_sess *)c->h2;
    return (hm_h2_stream *)nghttp2_session_get_stream_user_data(s->session,
                                                               (int32_t)sid);
}

/* Submit status + headers now, with a data provider that defers until there
 * are bytes. hm_h2_submit_response already drops hop-by-hop names and hands
 * the rest to nghttp2 as nghttp2_nv[], which is why headers travel as a list
 * all the way down here instead of as a byte string. */
static int hm_stream_h2_begin(pTHX_ hm_conn *c, int64_t sid, int status,
                              SV *headers) {
    hm_h2_sess *s = (hm_h2_sess *)c->h2;
    hm_h2_stream *st = hm_stream_h2_st(c, sid);
    AV *hav = (headers && SvROK(headers) && SvTYPE(SvRV(headers)) == SVt_PVAV)
            ? (AV *)SvRV(headers) : NULL;
    if (!st) return 0;
    if (st->status) return 0;      /* a response has already been submitted */
    if (st->resp_body) { SvREFCNT_dec(st->resp_body); st->resp_body = NULL; }
    hm_h2_src_free(aTHX_ st);
    st->resp_body = newSVpvs("");
    st->blen      = 0;
    st->producing = 1;
    st->prod_done = 0;
    hm_h2_submit_response(aTHX_ s, st, status, hav);
    hm_h2_flush_send(aTHX_ s);
    return 1;
}

static int hm_stream_h2_feed(pTHX_ hm_conn *c, int64_t sid,
                             const char *buf, STRLEN len, int done) {
    hm_h2_sess *s = (hm_h2_sess *)c->h2;
    hm_h2_stream *st = hm_stream_h2_st(c, sid);
    if (!st) return 0;
    if (len) {
        sv_catpvn(st->resp_body, buf, len);
        st->blen += len;
        c->loop->bytes_out += len;
    }
    if (done) st->prod_done = 1;
    nghttp2_session_resume_data(s->session, (int32_t)sid);
    hm_h2_flush_send(aTHX_ s);
    return 1;
}

/* Kill one stream and leave the rest of the connection alone. INTERNAL_ERROR
 * is the code for "the server failed", which is what an aborted producer is;
 * a client that has already had the headers reports the response as
 * incomplete rather than as a short success. */
static int hm_stream_h2_reset(pTHX_ hm_conn *c, int64_t sid) {
    hm_h2_sess *s = (hm_h2_sess *)c->h2;
    hm_h2_stream *st = hm_stream_h2_st(c, sid);
    if (!st) return 0;
    st->producing = 0;             /* the data provider must stop deferring */
    st->prod_done = 1;
    nghttp2_submit_rst_stream(s->session, NGHTTP2_FLAG_NONE, (int32_t)sid,
                              NGHTTP2_INTERNAL_ERROR);
    hm_h2_flush_send(aTHX_ s);
    return 1;
}

#else  /* !HM_HAVE_NGHTTP2: there is no h2 transport to branch to */

static int hm_stream_h2_begin(pTHX_ hm_conn *c, int64_t sid, int status,
                              SV *headers) {
    PERL_UNUSED_CONTEXT;
    (void)c; (void)sid; (void)status; (void)headers;
    return 0;
}
static int hm_stream_h2_feed(pTHX_ hm_conn *c, int64_t sid,
                             const char *buf, STRLEN len, int done) {
    PERL_UNUSED_CONTEXT;
    (void)c; (void)sid; (void)buf; (void)len; (void)done;
    return 0;
}
static int hm_stream_h2_reset(pTHX_ hm_conn *c, int64_t sid) {
    PERL_UNUSED_CONTEXT;
    (void)c; (void)sid;
    return 0;
}

#endif /* HM_HAVE_NGHTTP2 */

/* psgix.hyperman.stream -> (fd, generation, stream id). 1 if the env carried
 * a well-formed ticket. Shared by the two doors so they cannot drift. */
static int hm_stream_ticket(pTHX_ SV *env, int *fd, UV *id, int64_t *sid) {
    HV *ehv;
    AV *tick;
    SV **e, **fsv, **isv, **ssv;
    if (!(env && SvROK(env) && SvTYPE(SvRV(env)) == SVt_PVHV)) return 0;
    ehv = (HV *)SvRV(env);
    e = hv_fetchs(ehv, "psgix.hyperman.stream", 0);
    if (!(e && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVAV)) return 0;
    tick = (AV *)SvRV(*e);
    fsv = av_fetch(tick, 0, 0);
    isv = av_fetch(tick, 1, 0);
    ssv = av_fetch(tick, 2, 0);
    if (!(fsv && *fsv && isv && *isv)) return 0;
    *fd  = (int)SvIV(*fsv);
    *id  = SvUV(*isv);
    *sid = (ssv && *ssv) ? (int64_t)SvIV(*ssv) : -1;
    return 1;
}

/* ---- the entry points behind the ABI table ------------------------------ */

static void *hm_stream_open(pTHX_ void *vl, int fd, UV id, int64_t sid,
                            int status, SV *headers) {
    hm_loop *loop = vl ? (hm_loop *)vl : hm_cur_loop;
    hm_conn *c = (loop && fd >= 0 && fd < HM_MAXFD) ? loop->conns[fd] : NULL;
    hm_stream *s;
    if (!(c && c->id == id) || c->detached) return NULL;
    if (sid >= 0) {
        if (!c->h2) return NULL;                  /* not a multiplexed conn */
        if (!hm_stream_h2_begin(aTHX_ c, sid, status, headers)) return NULL;
    } else {
        if (c->h2) return NULL;                   /* h2 needs a stream id   */
        /* The response has to be deferred already - a psgi.streaming
         * coderef, or a handler parked on a Future. A synchronous handler's
         * return value is still coming, and it would be serialised on top of
         * the body being streamed here; refusing is the only honest answer,
         * and it is one the caller can act on. */
        if (!c->awaiting) return NULL;
        hm_start_stream(aTHX_ fd, id, status, headers);
    }
    if (loop->conns[fd] != c) return NULL;        /* the flush closed it    */
    s = (hm_stream *)hm_xcalloc(1, sizeof(hm_stream));
    s->serial = ++hm_stream_serials;
    s->loop   = loop;
    s->fd     = fd;
    s->cid    = id;
    s->sid    = sid;
    s->kind   = sid >= 0 ? HM_STREAM_H2 : HM_STREAM_H1;
    s->next   = hm_streams;
    hm_streams = s;
    hm_stream_live_n++;
    return (void *)s;
}

/* Backpressure is measured on the connection's unwritten output, which is
 * the same quantity on both transports: for h2 nghttp2 has already framed
 * what it could and the rest is sitting in the same wbuf. */
static int hm_stream_pressure(hm_stream *s, hm_conn *c) {
    if (c->wlen - c->woff <= (size_t)HM_ABI_STREAM_HIWAT)
        return HM_ABI_STREAM_OK;
    if (!s->paused) { s->paused = 1; hm_stream_paused_n++; }
    return HM_ABI_STREAM_FULL;
}

static int hm_stream_write_h(pTHX_ void *h, const char *buf, STRLEN len) {
    hm_stream *s = hm_stream_of(h);
    hm_conn *c;
    if (!s)             return HM_ABI_STREAM_STALE;
    if (!buf && len)    return HM_ABI_STREAM_ARG;
    if (s->dead)        return HM_ABI_STREAM_GONE;
    c = hm_stream_conn(s);
    if (!c) { hm_stream_mark_dead(s); return HM_ABI_STREAM_GONE; }
    if (s->kind == HM_STREAM_H2) {
        if (!hm_stream_h2_feed(aTHX_ c, s->sid, buf, len, 0)) {
            hm_stream_mark_dead(s);
            return HM_ABI_STREAM_GONE;
        }
    } else if (len) {
        hm_wb_put(c, buf, len);
        c->loop->bytes_out += len;
        hm_flush(aTHX_ c);
    }
    /* Either flush can close the connection; re-read it rather than trusting
     * the pointer we came in with. */
    c = hm_stream_conn(s);
    if (!c) { hm_stream_mark_dead(s); return HM_ABI_STREAM_GONE; }
    return hm_stream_pressure(s, c);
}

static int hm_stream_close_h(pTHX_ void *h) {
    hm_stream *s = hm_stream_of(h);
    hm_conn *c;
    int r = HM_ABI_STREAM_OK;
    if (!s) return HM_ABI_STREAM_STALE;
    c = s->dead ? NULL : hm_stream_conn(s);
    hm_stream_unlink(s);
    if (!c) r = HM_ABI_STREAM_GONE;
    else if (s->kind == HM_STREAM_H2) {
        if (!hm_stream_h2_feed(aTHX_ c, s->sid, NULL, 0, 1))
            r = HM_ABI_STREAM_GONE;
    } else {
        hm_stream_close(aTHX_ s->fd, s->cid);   /* unparks, then drains */
    }
    free(s);
    return r;
}

/* The other ending: stop the body in a way the peer can tell apart from
 * having finished. See stream_abort in hm_abi.h for why a clean close is the
 * wrong answer for a producer that failed.
 *
 * Unlinked before anything is sent, for the same reason stream_close is:
 * resetting fires the machinery that reports a stream as gone, and a handle
 * deliberately ending must not be told its stream went away. */
static int hm_stream_abort_h(pTHX_ void *h) {
    hm_stream *s = hm_stream_of(h);
    hm_conn *c;
    int r = HM_ABI_STREAM_OK;
    if (!s) return HM_ABI_STREAM_STALE;
    c = s->dead ? NULL : hm_stream_conn(s);
    hm_stream_unlink(s);
    if (!c) r = HM_ABI_STREAM_GONE;
    else if (s->kind == HM_STREAM_H2) {
        if (!hm_stream_h2_reset(aTHX_ c, s->sid)) r = HM_ABI_STREAM_GONE;
    }
    else {
        /* An EOF-delimited body ends at the close, so a graceful close is
         * indistinguishable from success and a reset is the only signal
         * left. SO_LINGER with a zero timeout is what turns close(2) into
         * an RST; queued output goes with it, which is the cost of being
         * able to say the response is not to be trusted. */
        struct linger lg;
        lg.l_onoff  = 1;
        lg.l_linger = 0;
        (void)hm_os_setsockopt(s->fd, SOL_SOCKET, SO_LINGER, &lg,
                               (socklen_t)sizeof lg);
        c->keepalive = 0;
        c->awaiting  = 0;      /* it is not waiting for a response any more */
        hm_close(aTHX_ s->loop, c);
    }
    free(s);
    return r;
}

static int hm_stream_on_drain(pTHX_ void *h, hm_abi_stream_cb cb, void *ud) {
    hm_stream *s = hm_stream_of(h);
    PERL_UNUSED_CONTEXT;
    if (!s) return HM_ABI_STREAM_STALE;
    s->drain_cb = cb;
    s->drain_ud = ud;
    return HM_ABI_STREAM_OK;
}

static int hm_stream_on_data(pTHX_ void *h, hm_abi_stream_data_cb cb, void *ud) {
    hm_stream *s = hm_stream_of(h);
    PERL_UNUSED_CONTEXT;
    if (!s) return HM_ABI_STREAM_STALE;
    s->data_cb = cb;
    s->data_ud = ud;
    return HM_ABI_STREAM_OK;
}

/* Request bytes for a stream, if a handle on it wants them. 1 when one took
 * them, so the transport knows not to buffer into psgi.input as well - a
 * tunnelled stream never ends, and buffering it would grow forever.
 *
 * Looked up by (fd, generation, stream id) rather than held on the h2/h3
 * stream, so the transports need to know nothing about handles. */
static int hm_stream_deliver(pTHX_ int fd, UV cid, int64_t sid,
                             const char *buf, STRLEN len, int fin) {
    hm_stream *s;
    if (!hm_stream_live_n) return 0;
    for (s = hm_streams; s; s = s->next) {
        if (s->fd == fd && s->cid == cid && s->sid == sid && s->data_cb) {
            hm_abi_stream_data_cb cb = s->data_cb;
            void *ud = s->data_ud;
            cb(aTHX_ (void *)s, buf, len, fin, ud);
            return 1;
        }
    }
    return 0;
}

static int hm_stream_on_abort(pTHX_ void *h, hm_abi_stream_cb cb, void *ud) {
    hm_stream *s = hm_stream_of(h);
    if (!s) return HM_ABI_STREAM_STALE;
    s->abort_cb = cb;
    s->abort_ud = ud;
    /* Already dead: fire now rather than never. Same contract as
     * future_on_ready on a settled future - registering after the event is
     * not a way to miss it. */
    if (cb && s->dead && !s->aborted) {
        s->aborted = 1;
        cb(aTHX_ (void *)s, ud);
    }
    return HM_ABI_STREAM_OK;
}

#endif /* HM_STREAM_H */
