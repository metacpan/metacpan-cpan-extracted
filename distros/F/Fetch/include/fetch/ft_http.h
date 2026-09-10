#ifndef FT_HTTP_H
#define FT_HTTP_H

/* HTTP/1.1 client: a non-blocking connection state machine driven by the loop
 * through a C-closure readiness callback (no Perl runs per event). Socket IO
 * and response parsing are all in C; the request resolves a Fetch::Future with
 * a Fetch::Response. This first cut handles GET/POST with Content-Length or
 * Connection: close bodies; chunked decoding and keep-alive pooling follow. */

#include <sys/types.h>
#include <string.h>
#include <stdlib.h>
/* Sockets, netdb, fcntl, unistd and errno come from ft_win.h (which maps to
 * Winsock on native Windows and to the POSIX headers everywhere else); the
 * socket/IO calls below go through its ft_os_* wrappers. */

#include "ft_dns.h"       /* name resolution, off the loop thread */
#include "ft_altsvc.h"    /* how an https:// URL ever learns h3 exists */

/* FT_RESOLVING comes first because a request in it has no socket yet: c->fd is
 * the resolver's pipe, so the arming, the deadline and the teardown all work
 * on it unchanged and a resolve that never answers times out like anything
 * else. See ft_dns.h. */
/* FT_QUIC_HANDSHAKING is HTTP/3's equivalent of FT_CONNECTING plus
 * FT_HANDSHAKING at once: QUIC carries its TLS handshake inside the transport
 * handshake, so there is no point between them where a connection is "up but
 * not secure". */
typedef enum { FT_RESOLVING, FT_CONNECTING, FT_HANDSHAKING, FT_WRITING,
               FT_READING, FT_PARKED, FT_QUIC_HANDSHAKING } ft_http_state;

typedef struct ft_conn {
    ft_loop      *loop;        /* native Standalone loop, or NULL if foreign */
    SV           *loop_sv;     /* foreign loop object (IO::Async/AnyEvent/
                                * Hyperman); interest is armed by calling its
                                * _ft_arm method. NULL for the native loop. */
    /* Hyperman-direct mode: when the foreign loop is a Fetch::Loop::Hyperman
     * and Hyperman's C ABI resolved (ft_hm.h), interest and deadlines go
     * straight through the table - no _ft_arm dispatch, no Perl frame per
     * readiness event. loop_sv is still held (it keeps the loop alive) but
     * its methods are never called while hm is set. */
    const hm_abi *hm;          /* the resolved table, or NULL       */
    void         *hm_loop;     /* opaque Hyperman loop handle       */
    hm_abi_timer *hm_timer;    /* pending deadline handle, or NULL  */
    int           fd;
    int           armed;       /* HM_EV_* currently watched */
    ft_http_state state;
    SV           *future;      /* Fetch::Future to resolve       */
    SV           *watcher;     /* the C-closure coderef (freed on close) */
    /* optional per-request deadline: fires ft_conn_timeout, which fails the
     * request and tears the socket down. timer (native) xor timer_h (foreign
     * loop handle) is set; timer_cb is our ref to the timeout closure. */
    ft_timer     *timer;
    SV           *timer_h;
    SV           *timer_cb;
    /* A SECOND, independent timer, for loss detection.
     *
     * The deadline above fires once and kills the request. QUIC's probe
     * timeout is the opposite shape: it is rearmed after almost every packet
     * sent or acknowledged, it fires many times over one request, and firing
     * is routine rather than fatal. Sharing one slot would mean a rearmed PTO
     * silently cancelling the caller's timeout, so it gets its own - same
     * three-way native/foreign/hm-direct split, no other difference. */
    ft_timer     *pto;
    SV           *pto_h;
    SV           *pto_cb;
    hm_abi_timer *hm_pto;
    /* what a fired PTO runs; `struct ft_conn` because the typedef is not
     * complete until this struct is */
    void        (*pto_fn)(pTHX_ struct ft_conn *c);
    /* TLS */
    void         *ssl;         /* SSL* when https, else NULL */
    int           tls;         /* request wants TLS */
    int           verify;      /* verify peer + hostname */
    char         *host;        /* SNI / verify host, and the redial target */
    char         *port;        /* service, kept for the keep-alive redial */
    ft_dns       *dns;         /* in-flight resolve (FT_RESOLVING), or NULL */
    /* HTTP/2 (nghttp2) - populated after ALPN negotiates h2 */
    void         *h2;          /* nghttp2_session* */
    int           is_h2;
    int           h2_done;     /* stream closed */
    /* HTTP/3 (ngtcp2 + nghttp3). One ft_qconn (ft_h3.h) holds the whole QUIC
     * connection AND its list of in-flight request streams - unlike h2, where
     * the connection and the one request it carries are the same object. */
    void         *h3;          /* ft_qconn*, or NULL */
    int           is_h3;
    /* structured request pieces, kept for the h2 nva (built after ALPN) */
    SV           *rq_method;   /* "GET" ...            */
    SV           *rq_scheme;   /* "http"/"https"       */
    SV           *rq_authority;/* host[:port]          */
    SV           *rq_path;     /* "/..."               */
    AV           *rq_headers;  /* [k,v,...] extra headers */
    SV           *rq_body;     /* request body or NULL */
    size_t        rq_body_off; /* h2 data-provider cursor */
    /* optional streaming sink: when set, each body chunk is handed to this
     * coderef as it arrives instead of being buffered, so large or endless
     * (SSE) bodies do not grow memory and the final Response body is empty. */
    SV           *on_body;
    SV           *on_headers;  /* fired once, ($status, [k,v,...]), before body */
    int           headers_fired;
    size_t        body_recv;   /* cumulative body bytes seen (streaming) */
    /* request (HTTP/1.1 serialized form) */
    char         *req;
    size_t        req_len, req_off;
    /* response accumulation + parse */
    char         *rbuf;
    size_t        rlen, rcap;
    int           have_headers;
    size_t        hdr_end;     /* offset just past the \r\n\r\n   */
    int           status;
    AV           *headers;     /* [k,v,k,v,...] */
    AV           *trailers;    /* [k,v,...] from a SECOND HEADERS frame (h2) */
    long          content_len; /* -1 = until close */
    int           want_close;  /* Connection: close */
    /* chunked transfer decoding */
    int           chunked;
    size_t        cpos;        /* decode cursor into rbuf         */
    long          chunk_left;  /* bytes left in chunk; -1 = need size line */
    int           chunk_done;  /* terminating 0-chunk seen        */
    char         *dbody;       /* decoded body                    */
    size_t        dblen, dbcap;
    /* keep-alive pooling: when this h1 connection may be reused, it is parked
     * (fd + TLS kept open) in the owning pool under poolkey instead of closed,
     * and revived for the next request to the same host. */
    struct ft_pool *pool;      /* owning pool (NULL = close-per-request) */
    char         *poolkey;     /* "proto:tls:host:port" identity for reuse */
    struct ft_conn *next_idle; /* pool free-list link while parked */
    int           reused;      /* revived from the pool this request */
    int           simple;      /* resolve with a raw hash, not a blessed
                                * Fetch::Response (Fetch->new(simple_response)) */
    /* WebSocket (RFC 6455): after a verified 101 the connection switches to
     * frame mode and stays open, owned by a Fetch::WebSocket object. */
    int           want_ws;     /* this request is a WebSocket upgrade */
    int           is_ws;       /* handshake done; in frame mode */
    int           ws_closed;   /* socket closed / closing */
    char         *ws_key;      /* Sec-WebSocket-Key we sent (verify Accept) */
    SV           *ws_on_message;
    SV           *ws_on_close;
    SV           *ws_waiter;   /* pending next_message future */
    AV           *ws_inbox;    /* messages arrived before a waiter */
    char         *ws_wbuf;     /* queued outbound frame bytes */
    size_t        ws_wlen, ws_wcap, ws_woff;
    char         *ws_msg;      /* inbound message reassembly (fragments) */
    size_t        ws_mlen, ws_mcap;
    int           ws_msg_opcode;
    size_t        ws_pos;      /* frame parse cursor into rbuf */
} ft_conn;

/* A per-UA keep-alive pool: a flat list of idle, revivable h1 connections.
 * Few distinct hosts in practice, so a linear scan by poolkey is fine. */
typedef struct ft_pool {
    ft_conn *idle;             /* head of the idle list (via next_idle) */
    int      count;
    int      max;              /* cap on parked connections */
} ft_pool;

#include "ft_tls.h"            /* operates on ft_conn (c->ssl, c->fd) */

static void ft_h2_free(ft_conn *c);   /* defined in ft_h2.h */
static void ft_h3_free(pTHX_ ft_conn *c);   /* defined in ft_h3.h */
static void ft_h3_step(pTHX_ ft_conn *c);   /* defined in ft_h3.h */
static void ft_loop_arm(pTHX_ ft_conn *c, int mask);       /* foreign, below */
static void ft_loop_untimer(pTHX_ ft_conn *c);             /* foreign, below */
static void ft_arm(pTHX_ ft_conn *c, int mask);            /* below */
static void ft_hm_ready(pTHX_ int fd, int mask, void *ud); /* hm-direct, below */
static void ft_conn_cancel_pto(pTHX_ ft_conn *c);          /* below */
/* The loss-detection timer, declared here because ft_h3.h is included before
 * it is defined and QUIC is the only thing that arms one. */
static void ft_conn_arm_pto(pTHX_ ft_conn *c, double secs,
                            void (*fn)(pTHX_ struct ft_conn *c));

/* Cancel a pending deadline timer (nothing to do if it already fired: the
 * fire path clears c->timer/c->timer_h/c->hm_timer before running). */
static void ft_conn_cancel_timer(pTHX_ ft_conn *c) {
    if (c->hm_timer) {
        if (!PL_dirty) c->hm->timer_cancel(aTHX_ c->hm_loop, c->hm_timer);
        c->hm_timer = NULL;
    }
    if (c->timer)   { ft_del_timer(aTHX_ c->loop, c->timer); c->timer = NULL; }
    if (c->timer_h) { ft_loop_untimer(aTHX_ c); }
}

/* Set by the UA immediately before ft_h1_start so a freshly created connection
 * inherits its simple_response mode (single-threaded loop; safe as a static). */
static int ft_conn_simple_next = 0;

/* Likewise the UA's Hyperman-direct mode (ft_hm.h): both set, or both NULL. */
static const hm_abi *ft_conn_hm_next = NULL;
static void *ft_conn_hm_loop_next = NULL;

/* Likewise for the optional on_headers callback (borrowed; consumed at conn
 * create/revive). Fired once, before the body, with ($status, [k,v,...]). */
static SV *ft_conn_on_headers_next = NULL;

/* The transport a request is being started on. It is part of the pool key
 * because an idle connection is only reusable by a request that speaks what
 * it speaks: handing an HTTP/3 connection to a request expecting to write
 * HTTP/1.1 bytes at a socket is not a subtle failure, it is a hang.
 *
 * The key names the protocol ASKED FOR, not the one negotiated. Those differ
 * on TLS, where ALPN can turn an intended h1 connection into h2 - but an h2
 * connection never parks (ft_conn_reusable), so nothing under the "h1" key is
 * ever anything else. Alt-Svc is what makes a request ask for h3 in the first
 * place, and it asks before the connection exists. */
#define FT_PROTO_H1 "h1"
#define FT_PROTO_H3 "h3"
static const char *ft_conn_proto_next = FT_PROTO_H1;

/* Hand the parsed status line + header list to the on_headers sink, once. */
static void ft_fire_headers(pTHX_ ft_conn *c) {
    dSP;
    SV *hrv = c->headers ? newRV_inc((SV *)c->headers)
                         : newRV_noinc((SV *)newAV());
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newSViv(c->status)));
    PUSHs(sv_2mortal(hrv));
    PUTBACK;
    call_sv(c->on_headers, G_DISCARD | G_EVAL);
    if (SvTRUE(ERRSV)) warn("Fetch: on_headers callback died: %s", SvPV_nolen(ERRSV));
    FREETMPS; LEAVE;
}

static void ft_conn_free(pTHX_ ft_conn *c) {
    if (!c) return;
    ft_conn_cancel_timer(aTHX_ c);
    ft_conn_cancel_pto(aTHX_ c);
    /* A resolve still in flight: drop this side's reference and go. The
     * thread cannot be stopped and is not waited for - it finishes into a
     * struct nobody is reading, finds itself holding the last reference and
     * frees it there. The pipe's read end is c->fd and is closed below. */
    if (c->dns) { ft_dns_unref(c->dns); c->dns = NULL; }
    ft_h2_free(c);
    ft_h3_free(aTHX_ c);
    ft_tls_free(c);
    if (c->fd >= 0) {
        if (c->armed) {
            if (c->hm) {
                if (!PL_dirty) {   /* at global destruction the loop may be gone */
                    if (c->armed & HM_EV_READ)
                        c->hm->io_unwatch(aTHX_ c->hm_loop, c->fd, HM_ABI_READ);
                    if (c->armed & HM_EV_WRITE)
                        c->hm->io_unwatch(aTHX_ c->hm_loop, c->fd, HM_ABI_WRITE);
                }
            }
            else if (c->loop_sv) ft_loop_arm(aTHX_ c, 0);
            else                 ft_unwatch_io(aTHX_ c->loop, c->fd, c->armed);
        }
        ft_os_close(c->fd);
    }
    if (c->on_body)      SvREFCNT_dec(c->on_body);
    if (c->on_headers)   SvREFCNT_dec(c->on_headers);
    if (c->ws_on_message) SvREFCNT_dec(c->ws_on_message);
    if (c->ws_on_close)   SvREFCNT_dec(c->ws_on_close);
    if (c->ws_waiter)     SvREFCNT_dec(c->ws_waiter);
    if (c->ws_inbox)      SvREFCNT_dec(c->ws_inbox);
    if (c->timer_cb)     SvREFCNT_dec(c->timer_cb);
    if (c->pto_cb)       SvREFCNT_dec(c->pto_cb);
    if (c->loop_sv)      SvREFCNT_dec(c->loop_sv);
    if (c->future)       SvREFCNT_dec(c->future);
    if (c->watcher)      SvREFCNT_dec(c->watcher);
    if (c->headers)      SvREFCNT_dec(c->headers);
    if (c->trailers)     SvREFCNT_dec(c->trailers);
    if (c->rq_method)    SvREFCNT_dec(c->rq_method);
    if (c->rq_scheme)    SvREFCNT_dec(c->rq_scheme);
    if (c->rq_authority) SvREFCNT_dec(c->rq_authority);
    if (c->rq_path)      SvREFCNT_dec(c->rq_path);
    if (c->rq_headers)   SvREFCNT_dec(c->rq_headers);
    if (c->rq_body)      SvREFCNT_dec(c->rq_body);
    Safefree(c->host);
    Safefree(c->port);
    Safefree(c->poolkey);
    Safefree(c->ws_key);
    Safefree(c->ws_wbuf);
    Safefree(c->ws_msg);
    Safefree(c->req);
    Safefree(c->rbuf);
    Safefree(c->dbody);
    Safefree(c);
}

/* --- keep-alive pool ------------------------------------------------------ */

static ft_pool *ft_pool_new(int max) {
    ft_pool *p = (ft_pool *)calloc(1, sizeof(ft_pool));
    if (!p) return NULL;
    p->max = max > 0 ? max : 32;
    return p;
}

/* Take the first idle connection matching key, unlinking it; NULL if none. */
static ft_conn *ft_pool_take(ft_pool *p, const char *key) {
    ft_conn **pp = &p->idle;
    while (*pp) {
        if ((*pp)->poolkey && strcmp((*pp)->poolkey, key) == 0) {
            ft_conn *c = *pp;
            *pp = c->next_idle;
            c->next_idle = NULL;
            p->count--;
            return c;
        }
        pp = &(*pp)->next_idle;
    }
    return NULL;
}

/* Find a connection under this key WITHOUT taking it out.
 *
 * The h1 pool holds only idle connections and hands one over exclusively,
 * because an HTTP/1.1 connection carries one request at a time. An HTTP/3
 * connection carries many, so it stays in the pool while it is in use and a
 * second request attaches to it rather than replacing it - which is the
 * difference between multiplexing and taking turns, and the reason this
 * exists beside ft_pool_take rather than instead of it. */
static ft_conn *ft_pool_peek(ft_pool *p, const char *key) {
    ft_conn *c;
    if (!p) return NULL;
    for (c = p->idle; c; c = c->next_idle)
        if (c->poolkey && strcmp(c->poolkey, key) == 0) return c;
    return NULL;
}

/* Park an idle connection for reuse, or free it if the pool is full. */
static void ft_pool_put(pTHX_ ft_pool *p, ft_conn *c) {
    if (p->count >= p->max) { ft_conn_free(aTHX_ c); return; }
    c->next_idle = p->idle;
    p->idle = c;
    p->count++;
}

static void ft_pool_free(pTHX_ ft_pool *p) {
    ft_conn *c;
    if (!p) return;
    for (c = p->idle; c; ) { ft_conn *n = c->next_idle; ft_conn_free(aTHX_ c); c = n; }
    free(p);
}

/* Unlink a parked connection from the idle list (before evicting/freeing it). */
static void ft_pool_remove(ft_pool *p, ft_conn *c) {
    ft_conn **pp;
    if (!p) return;
    for (pp = &p->idle; *pp; pp = &(*pp)->next_idle) {
        if (*pp == c) { *pp = c->next_idle; c->next_idle = NULL; p->count--; return; }
    }
}

/* Can this finished connection be parked and reused? Only a delimited h1
 * response on a pooled connection the server did not mark Connection: close
 * leaves the socket at a clean message boundary. */
static int ft_conn_reusable(ft_conn *c) {
    if (!c->pool || c->want_close || c->is_h2) return 0;
    if (c->chunked) return c->chunk_done;
    return c->content_len >= 0;
}

/* Park a finished connection: stop watching it, drop the request's per-call
 * state, keep the fd/TLS/buffers, and hand it to the pool for the next
 * request to the same host. */
static void ft_conn_park(pTHX_ ft_conn *c) {
    /* Stay armed for READ while idle instead of disarming now and re-arming on
     * the next request. A healthy keep-alive socket is quiet, so this costs
     * nothing; it saves the disarm+re-arm pair per reuse - two _ft_arm
     * crossings on a foreign loop, two epoll/kqueue syscalls on the native
     * one. If the server closes the idle connection it becomes readable and
     * ft_conn_ready_cb (seeing FT_PARKED) evicts it. */
    ft_arm(aTHX_ c, HM_EV_READ);        /* no-op: already READ-armed from recv */
    ft_conn_cancel_timer(aTHX_ c);
    if (c->future)  { SvREFCNT_dec(c->future);  c->future  = NULL; }
    if (c->on_body) { SvREFCNT_dec(c->on_body); c->on_body = NULL; }
    if (c->on_headers) { SvREFCNT_dec(c->on_headers); c->on_headers = NULL; }
    c->headers_fired = 0;
    if (c->headers) { SvREFCNT_dec(c->headers); c->headers = NULL; }
    if (c->trailers) { SvREFCNT_dec(c->trailers); c->trailers = NULL; }
    c->rlen = 0; c->have_headers = 0; c->hdr_end = 0; c->status = 0;
    c->content_len = -1; c->want_close = 0; c->chunked = 0;
    c->cpos = 0; c->chunk_left = 0; c->chunk_done = 0;
    c->dblen = 0; c->body_recv = 0; c->req_off = 0; c->reused = 0;
    c->state = FT_PARKED;
    ft_pool_put(aTHX_ c->pool, c);
}

/* resolve the request's future with a Fetch::Response, then park or free */
/* Build the response object and settle a future with it.
 *
 * Split out of ft_conn_finish because HTTP/3 finishes a REQUEST without
 * finishing the connection: several streams settle their own futures on one
 * connection, so the pieces come from a per-stream struct rather than from
 * the ft_conn. Everything a caller sees - the hash keys, the blessing, the
 * absent trailers key - is decided here and once, so the transports cannot
 * drift in what a Fetch::Response is. `body` is borrowed. */
static void ft_settle_response(pTHX_ SV *future, int status, AV *headers,
                               AV *trailers, const char *body, size_t blen,
                               int simple) {
    /* the Response stash never changes; look it up once per process */
    static HV *resp_stash = NULL;
    HV *resp = newHV();
    SV *rv, *fut;
    AV *vals;
    (void)hv_stores(resp, "status",  newSViv(status));
    (void)hv_stores(resp, "headers",
        headers ? newRV_inc((SV *)headers) : newRV_noinc((SV *)newAV()));
    /* Only when there were any: an HTTP/1 response has no trailers and should
     * not grow an empty key, and a consumer can tell "none were sent" from
     * "none were captured" by the absence. */
    if (trailers)
        (void)hv_stores(resp, "trailers", newRV_inc((SV *)trailers));
    (void)hv_stores(resp, "content", newSVpvn(body ? body : "", blen));
    if (simple) {
        rv = newRV_noinc((SV *)resp);        /* raw hash: no bless, no methods */
    } else {
        if (!resp_stash) resp_stash = gv_stashpv("Fetch::Response", GV_ADD);
        rv = sv_bless(newRV_noinc((SV *)resp), resp_stash);
    }
    /* hand the response straight to the future's value AV - no extra copy */
    fut  = SvREFCNT_inc(future);
    vals = newAV();
    av_push(vals, rv);                       /* transfers our ref */
    hmf_settle_av(aTHX_ fut, HMF_DONE, vals);
    SvREFCNT_dec(fut);
}

static void ft_conn_finish(pTHX_ ft_conn *c) {
    int reuse = ft_conn_reusable(c);
    /* Alt-Svc, on the way past. A response that arrived over TCP is the only
     * place an origin can say it also answers over QUIC, so this is where a
     * later request learns to try h3 - see ft_altsvc.h. */
    if (c->tls && c->host && c->headers)
        ft_altsvc_note(aTHX_ c->host, c->port ? atoi(c->port) : 443, c->headers);
    /* h2 and chunked decode into dbody; a plain h1 body is still in rbuf */
    const char *body = (c->is_h2 || c->chunked)
        ? (c->dbody ? c->dbody : "") : c->rbuf + c->hdr_end;
    size_t blen = (c->is_h2 || c->chunked)
        ? c->dblen : c->rlen - c->hdr_end;
    ft_settle_response(aTHX_ c->future, c->status, c->headers, c->trailers,
                       body, blen, c->simple);
    if (reuse) { ft_conn_park(aTHX_ c); return; }
    ft_conn_free(aTHX_ c);
}

static void ft_conn_fail(pTHX_ ft_conn *c, const char *msg) {
    /* An HTTP/3 connection has no future of its own: the futures belong to
     * its streams, and ft_h3_fail_all has already settled every one of them
     * before calling this to tear the connection down. Everywhere else there
     * is exactly one, and it is this. */
    if (c->future) {
        SV *e   = sv_2mortal(newSVpvf("Fetch: %s", msg));
        SV *fut = SvREFCNT_inc(c->future);
        if (hmf_state(aTHX_ fut) == HMF_PENDING)
            hmf_settle(aTHX_ fut, HMF_FAILED, &e, 1);
        SvREFCNT_dec(fut);
    }
    ft_conn_free(aTHX_ c);
}

/* case-insensitive search for "chunked" within [s, end) */
static int strncasestr_chunked(const char *s, const char *end) {
    while (s + 7 <= end) {
        if (strncasecmp(s, "chunked", 7) == 0) return 1;
        s++;
    }
    return 0;
}

/* parse status line + headers once the \r\n\r\n terminator is in rbuf */
static int ft_parse_headers(pTHX_ ft_conn *c) {
    char *p   = c->rbuf;
    char *end = ft_memmem(c->rbuf, c->rlen, "\r\n\r\n", 4);
    char *line_end;
    if (!end) return 0;                     /* need more bytes */
    c->hdr_end = (size_t)(end - c->rbuf) + 4;

    /* status line: HTTP/1.x SP code SP reason */
    line_end = memchr(p, '\r', c->rlen);
    if (!line_end) return -1;
    {
        char *sp = memchr(p, ' ', (size_t)(line_end - p));
        if (!sp) return -1;
        c->status = (int)strtol(sp + 1, NULL, 10);
    }
    p = line_end + 2;                        /* past CRLF */

    c->headers = newAV();
    c->content_len = -1;
    /* Header lines run up to the blank line; the last header's terminating CR
     * is the first CR of the closing \r\n\r\n (at `end`), so search that far
     * inclusive - stopping at `end` would silently drop the final header. */
    while (p < end) {
        char *eol = memchr(p, '\r', (size_t)((c->rbuf + c->hdr_end) - p));
        char *colon;
        if (!eol || eol == p) break;
        colon = memchr(p, ':', (size_t)(eol - p));
        if (colon) {
            char *vs = colon + 1;
            char *ve = eol;
            size_t klen;
            while (vs < ve && (*vs == ' ' || *vs == '\t')) vs++;
            klen = (size_t)(colon - p);
            av_push(c->headers, newSVpvn(p, klen));
            av_push(c->headers, newSVpvn(vs, (size_t)(ve - vs)));
            if (klen == 14 && strncasecmp(p, "Content-Length", 14) == 0)
                c->content_len = strtol(vs, NULL, 10);
            else if (klen == 10 && strncasecmp(p, "Connection", 10) == 0 &&
                     strncasecmp(vs, "close", 5) == 0)
                c->want_close = 1;
            else if (klen == 17 && strncasecmp(p, "Transfer-Encoding", 17) == 0 &&
                     strncasestr_chunked(vs, ve))
                c->chunked = 1;
        }
        p = eol + 2;
    }
    /* RFC 7230 3.3.3: Transfer-Encoding overrides Content-Length. A response
     * carrying both is a response-smuggling signal; frame strictly by the
     * chunked encoding and drop the ambiguous Content-Length so no code path
     * (ft_body_complete, keep-alive completion) can ever frame by it. */
    if (c->chunked) c->content_len = -1;
    /* RFC 7230 3.3.3: 1xx, 204 and 304 responses never carry a body, and a
     * server MUST NOT send Content-Length on 1xx/204 - without this a 204 on
     * a keep-alive connection would wait for close/timeout that never comes. */
    if (c->status == 204 || c->status == 304 ||
        (c->status >= 100 && c->status < 200)) {
        c->content_len = 0;
        c->chunked = 0;
    }
    c->have_headers = 1;
    c->cpos = c->hdr_end;       /* body decoding starts here */
    if (c->chunked) c->chunk_left = -1;
    return 1;
}

static void ft_emit_body(pTHX_ ft_conn *c, const char *buf, size_t len);

/* incrementally decode chunked body from rbuf[cpos..rlen] into dbody; sets
 * chunk_done when the terminating zero-size chunk arrives. */
static void ft_chunk_feed(pTHX_ ft_conn *c) {
    while (c->cpos < c->rlen && !c->chunk_done) {
        if (c->chunk_left < 0) {                /* need a chunk-size line */
            char  *base = c->rbuf + c->cpos;
            size_t rem  = c->rlen - c->cpos;
            char  *crlf = (char *)ft_memmem(base, rem, "\r\n", 2);
            long   sz;
            if (!crlf) return;                  /* size line incomplete */
            sz = strtol(base, NULL, 16);        /* hex; ignores ;extensions */
            c->cpos = (size_t)(crlf - c->rbuf) + 2;
            if (sz <= 0) { c->chunk_done = 1; return; }
            c->chunk_left = sz;
        } else if (c->chunk_left > 0) {         /* copy chunk data */
            size_t avail = c->rlen - c->cpos;
            size_t take  = (size_t)c->chunk_left < avail ? (size_t)c->chunk_left : avail;
            if (c->on_body) {                   /* stream: emit, do not buffer */
                ft_emit_body(aTHX_ c, c->rbuf + c->cpos, take);
                c->body_recv += take;
            } else {
                if (c->dblen + take > c->dbcap) {
                    c->dbcap = (c->dblen + take) * 2 + 64;
                    Renew(c->dbody, c->dbcap, char);
                }
                memcpy(c->dbody + c->dblen, c->rbuf + c->cpos, take);
                c->dblen  += take;
            }
            c->cpos       += take;
            c->chunk_left -= (long)take;
        } else {                                /* chunk_left == 0: trailing CRLF */
            if (c->rlen - c->cpos < 2) return;
            c->cpos      += 2;
            c->chunk_left = -1;
        }
    }
}

/* true when the full body has arrived */
static int ft_body_complete(ft_conn *c) {
    size_t body = c->rlen - c->hdr_end;
    if (c->content_len >= 0) return body >= (size_t)c->content_len;
    return 0;   /* until-close: completion is signalled by EOF */
}

/* hand one body chunk to the streaming sink; deaths become warnings */
/* One chunk to a streaming sink. Takes the coderef rather than the
 * connection, because on HTTP/3 the sink belongs to one of several streams on
 * a shared connection and there is no single c->on_body to reach for. */
static void ft_emit_body_sv(pTHX_ SV *on_body, const char *buf, size_t len) {
    dSP;
    if (!len || !on_body) return;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpvn(buf, len)));
    PUTBACK;
    call_sv(on_body, G_DISCARD | G_EVAL);
    if (SvTRUE(ERRSV)) warn("Fetch: on_body callback died: %s", SvPV_nolen(ERRSV));
    FREETMPS; LEAVE;
}

static void ft_emit_body(pTHX_ ft_conn *c, const char *buf, size_t len) {
    ft_emit_body_sv(aTHX_ c->on_body, buf, len);
}

/* Foreign loop: reconcile interest for c->fd to exactly `mask` by calling the
 * loop object's _ft_arm($fd, $mask, $cv). mask 0 removes; bits are HM_EV_READ
 * (0x1) / HM_EV_WRITE (0x2). The adapter fires c->watcher on readiness. */
static void ft_loop_arm(pTHX_ ft_conn *c, int mask) {
    /* Resolve _ft_arm once per adapter class and call the CV directly, rather
     * than re-resolving the method name on every arm. Real programs use one
     * adapter class, so this cache hits on essentially every call; a different
     * class just re-resolves. Falls back to call_method if resolution fails. */
    static HV *cached_stash = NULL;
    static CV *cached_cv = NULL;
    HV *stash = (SvROK(c->loop_sv) && SvOBJECT(SvRV(c->loop_sv)))
              ? SvSTASH(SvRV(c->loop_sv)) : NULL;
    CV *cv;
    dSP;
    if (stash && stash == cached_stash) {
        cv = cached_cv;
    } else {
        GV *gv = stash ? gv_fetchmethod_autoload(stash, "_ft_arm", FALSE) : NULL;
        cv = gv ? GvCV(gv) : NULL;
        cached_stash = stash;
        cached_cv = cv;
    }
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 4);
    PUSHs(c->loop_sv);
    PUSHs(sv_2mortal(newSViv(c->fd)));
    PUSHs(sv_2mortal(newSViv(mask)));
    PUSHs(c->watcher);
    PUTBACK;
    if (cv) call_sv((SV *)cv, G_VOID | G_DISCARD);
    else    call_method("_ft_arm", G_VOID | G_DISCARD);
    FREETMPS; LEAVE;
}

/* Foreign loop: schedule the deadline via _ft_timer($secs, $cv), keeping the
 * returned cancel handle in c->timer_h. */
static void ft_loop_timer(pTHX_ ft_conn *c, double secs) {
    dSP;
    int count;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 3);
    PUSHs(c->loop_sv);
    PUSHs(sv_2mortal(newSVnv(secs)));
    PUSHs(c->timer_cb);
    PUTBACK;
    count = call_method("_ft_timer", G_SCALAR);
    SPAGAIN;
    if (count > 0) { SV *h = POPs; if (SvOK(h)) c->timer_h = SvREFCNT_inc(h); }
    PUTBACK;
    FREETMPS; LEAVE;
}

/* Foreign loop: cancel the deadline via _ft_untimer($handle). */
static void ft_loop_untimer(pTHX_ ft_conn *c) {
    dSP;
    SV *h = c->timer_h;
    c->timer_h = NULL;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(c->loop_sv);
    PUSHs(sv_2mortal(h));      /* hand our ref over to be mortalised */
    PUTBACK;
    call_method("_ft_untimer", G_VOID | G_DISCARD);
    FREETMPS; LEAVE;
}

/* Re-arm the loop for the readiness direction(s) we currently need. */
static void ft_arm(pTHX_ ft_conn *c, int mask) {
    if (c->armed == mask) return;
    if (c->hm) {
        /* Hyperman-direct: reconcile per direction through the C ABI, so an
         * unchanged direction is left alone (no drop+re-add churn). */
        int drop = c->armed & ~mask, add = mask & ~c->armed;
        if (drop & HM_EV_READ)
            c->hm->io_unwatch(aTHX_ c->hm_loop, c->fd, HM_ABI_READ);
        if (drop & HM_EV_WRITE)
            c->hm->io_unwatch(aTHX_ c->hm_loop, c->fd, HM_ABI_WRITE);
        if (add & HM_EV_READ)
            c->hm->io_watch(aTHX_ c->hm_loop, c->fd, HM_ABI_READ, ft_hm_ready, c);
        if (add & HM_EV_WRITE)
            c->hm->io_watch(aTHX_ c->hm_loop, c->fd, HM_ABI_WRITE, ft_hm_ready, c);
    } else if (c->loop_sv) {
        ft_loop_arm(aTHX_ c, mask);
    } else {
        if (c->armed) ft_unwatch_io(aTHX_ c->loop, c->fd, c->armed);
        if (mask)     ft_watch_io(aTHX_ c->loop, c->fd, mask, c->watcher);
    }
    c->armed = mask;
}

/* IO wrappers dispatching TLS vs raw; on would-block *want gets the needed
 * readiness (HM_EV_READ/HM_EV_WRITE), else 0. */
static ssize_t ft_recv(ft_conn *c, void *buf, size_t n, int *want) {
    *want = 0;
    if (c->ssl) return ft_tls_read(c, buf, n, want);
    {
        ssize_t r = ft_os_recv(c->fd, buf, n, 0);
        if (r < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) *want = HM_EV_READ;
        return r;
    }
}
static ssize_t ft_send(ft_conn *c, const void *buf, size_t n, int *want) {
    *want = 0;
    if (c->ssl) return ft_tls_write(c, buf, n, want);
    {
        ssize_t r = ft_os_send(c->fd, buf, n, 0);
        if (r < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) *want = HM_EV_WRITE;
        return r;
    }
}

#include "ft_h2.h"   /* nghttp2 client; uses ft_recv/ft_send/ft_arm/finish/fail */
#include "ft_h3.h"   /* nghttp3 + ngtcp2 client, on the same seams */
#include "ft_ws.h"   /* WebSocket framing; uses ft_recv/ft_send/ft_arm */

/* Verify a 101 + Sec-WebSocket-Accept and switch into frame mode, resolving
 * the upgrade Future with a Fetch::WebSocket. Returns 1 on success, 0 if the
 * handshake was not a valid WebSocket upgrade. */
static int ft_ws_upgrade(pTHX_ ft_conn *c) {
    char expect[30];
    const char *got = NULL;
    STRLEN gotl = 0;
    SSize_t i, n;
    SV *ws, *fut;
    if (c->status != 101 || !c->ws_key) return 0;
    ft_ws_accept(c->ws_key, expect);
    n = c->headers ? av_len(c->headers) + 1 : 0;
    for (i = 0; i + 1 < n; i += 2) {
        SV **k = av_fetch(c->headers, i, 0);
        STRLEN kl;
        const char *kp;
        if (!k || !*k) continue;
        kp = SvPV(*k, kl);
        if (kl == 20 && strncasecmp(kp, "Sec-WebSocket-Accept", 20) == 0) {
            SV **v = av_fetch(c->headers, i + 1, 0);
            if (v && *v) got = SvPV(*v, gotl);
            break;
        }
    }
    if (!got || gotl != strlen(expect) || memcmp(got, expect, gotl) != 0)
        return 0;

    /* bytes past the header block are the first WebSocket frames */
    if (c->rlen > c->hdr_end)
        memmove(c->rbuf, c->rbuf + c->hdr_end, c->rlen - c->hdr_end);
    c->rlen   = c->rlen > c->hdr_end ? c->rlen - c->hdr_end : 0;
    c->ws_pos = 0;
    c->is_ws  = 1;

    ws  = sv_bless(newRV_noinc(newSViv(PTR2IV(c))),
                   gv_stashpv("Fetch::WebSocket", GV_ADD));
    fut = SvREFCNT_inc(c->future);
    SvREFCNT_dec(c->future); c->future = NULL;
    hmf_settle(aTHX_ fut, HMF_DONE, &ws, 1);
    SvREFCNT_dec(ws);
    SvREFCNT_dec(fut);

    ft_ws_feed(aTHX_ c);                 /* dispatch anything already buffered */
    if (!c->ws_closed) ft_ws_rearm(aTHX_ c);
    return 1;
}

/* RFC 7231 4.2.2: methods a client may replay without changing what the
 * request means. Read off the request line rather than c->rq_method, which
 * belongs to the request that first opened the connection, not this one. */
static int ft_req_idempotent(const char *req, size_t len) {
    static const char *const ok[] = { "GET", "HEAD", "PUT", "DELETE",
                                      "OPTIONS", "TRACE", NULL };
    size_t i = 0, n;
    const char *const *m;
    while (i < len && req[i] != ' ') i++;
    for (m = ok; *m; m++) {
        n = strlen(*m);
        if (n == i && strncmp(req, *m, n) == 0) return 1;
    }
    return 0;
}

/* A keep-alive connection revived from the pool can die under the very
 * request that revived it: the server had already decided to close it and the
 * FIN was still in flight when ft_conn_alive() peeked. That is not a request
 * failure, it is a lost race, and every request over a pool has to survive it
 * - so redial and send the same bytes again on a fresh socket.
 *
 * Only ever on a revived connection (c->reused, cleared here so one request
 * cannot loop), only while nothing of a response has arrived, and only for an
 * idempotent method - if any byte came back the server did answer, and a
 * replay would be a second POST rather than a retry.
 *
 * Returns 1 when the request is back in flight on a new socket. */
static int ft_conn_retry(pTHX_ ft_conn *c) {
    struct addrinfo hints, *ai = NULL, *rp;
    int fd = -1;

    if (!c->reused || c->have_headers || c->rlen || c->body_recv) return 0;
    if (c->is_h2 || c->is_ws || c->want_ws)                       return 0;
    if (!c->host || !c->port || !c->req)                          return 0;
    if (!ft_req_idempotent(c->req, c->req_len))                   return 0;

    memset(&hints, 0, sizeof(hints));
    hints.ai_family   = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    if (getaddrinfo(c->host, c->port, &hints, &ai) != 0) return 0;
    for (rp = ai; rp; rp = rp->ai_next) {
        fd = ft_os_socket(rp->ai_family, rp->ai_socktype, rp->ai_protocol);
        if (fd < 0) continue;
        ft_os_set_nonblock(fd);
        if (ft_os_connect(fd, rp->ai_addr, (int)rp->ai_addrlen) == 0
            || errno == EINPROGRESS)
            break;
        ft_os_close(fd); fd = -1;
    }
    freeaddrinfo(ai);
    if (fd < 0) return 0;               /* cannot redial: let the caller fail */

    ft_arm(aTHX_ c, 0);                 /* stop watching the dead fd first */
    ft_tls_free(c);
    if (c->fd >= 0) ft_os_close(c->fd);
    c->fd      = fd;
    c->state   = FT_CONNECTING;
    c->req_off = 0;
    c->reused  = 0;                     /* one redial per request */
    /* the deadline armed for this request keeps running: a redial buys
     * another socket, not more time. */
    ft_arm(aTHX_ c, HM_EV_WRITE);
    return 1;
}

/* One pass of the connection state machine. TLS handshake, request send, and
 * response recv+parse all re-arm the loop for whichever direction OpenSSL (or
 * the socket) next needs. */
/* Walk a resolved address list and start a non-blocking connect on the first
 * address that takes one. Returns the fd, or -1 with errno set by the last
 * attempt. Shared by the inline and the threaded resolve so the two cannot
 * drift in what "the first usable address" means. */
static int ft_conn_dial(struct addrinfo *ai) {
    struct addrinfo *rp;
    for (rp = ai; rp; rp = rp->ai_next) {
        int fd = ft_os_socket(rp->ai_family, rp->ai_socktype, rp->ai_protocol);
        if (fd < 0) continue;
        ft_os_set_nonblock(fd);
        if (ft_os_connect(fd, rp->ai_addr, (int)rp->ai_addrlen) == 0
            || errno == EINPROGRESS)
            return fd;
        ft_os_close(fd);
    }
    return -1;
}

static void ft_conn_step(pTHX_ ft_conn *c) {
    if (c->is_ws) { ft_ws_step(aTHX_ c); return; }
    if (c->is_h2) { ft_h2_step(aTHX_ c); return; }
    if (c->is_h3) { ft_h3_step(aTHX_ c); return; }

    if (c->state == FT_RESOLVING) {
        /* The resolver woke us. The byte carries nothing - the answer is in
         * the struct, and it is the write that made it visible here. */
        ft_dns *d = c->dns;
        char b;
        int fd;
        (void)!read(c->fd, &b, 1);
        /* Unarm BEFORE the fd changes: ft_arm reconciles against c->fd, so
         * dropping the watch afterwards would name the socket that is about
         * to take its place - or, once the number is recycled, somebody
         * else's. */
        ft_arm(aTHX_ c, 0);
        ft_os_close(c->fd);
        c->fd  = -1;
        c->dns = NULL;
        if (!d || d->gai != 0) {
            char msg[320];
            my_snprintf(msg, sizeof msg, "resolve %s:%s: %s",
                        c->host ? c->host : "?", c->port ? c->port : "?",
                        d ? gai_strerror(d->gai) : "no resolver");
            ft_dns_unref(d);
            ft_conn_fail(aTHX_ c, msg);
            return;
        }
        fd = ft_conn_dial(d->ai);
        ft_dns_unref(d);
        if (fd < 0) { ft_conn_fail(aTHX_ c, "connect failed"); return; }
        c->fd    = fd;
        c->state = FT_CONNECTING;
        ft_arm(aTHX_ c, HM_EV_WRITE);   /* wait for connect() to complete */
        return;
    }

    if (c->state == FT_CONNECTING) {
        int err = 0; socklen_t el = sizeof(err);
        if (ft_os_getsockopt(c->fd, SOL_SOCKET, SO_ERROR, &err, &el) < 0 || err) {
            ft_conn_fail(aTHX_ c, err ? strerror(err) : "connect failed");
            return;
        }
        if (c->tls) {
            if (!FT_TLS_AVAILABLE) {
                ft_conn_fail(aTHX_ c, "https requires OpenSSL (rebuild with libssl)");
                return;
            }
            if (ft_tls_start(c, c->host, c->verify) != 0) {
                ft_conn_fail(aTHX_ c, "TLS setup failed");
                return;
            }
            c->state = FT_HANDSHAKING;
        } else {
            c->state = FT_WRITING;
        }
    }

    if (c->state == FT_HANDSHAKING) {
        int want = HM_EV_READ;
        int r = ft_tls_handshake(c, &want);
        if (r < 0) { ft_conn_fail(aTHX_ c, "TLS handshake failed"); return; }
        if (r == 0) { ft_arm(aTHX_ c, want); return; }
        c->state = FT_WRITING;   /* handshake complete */

        /* ALPN may have negotiated h2: switch to the nghttp2 client. A
         * WebSocket upgrade stays on HTTP/1.1. */
        if (FT_H2_AVAILABLE && !c->want_ws && ft_tls_is_h2(c)) {
            if (ft_h2_init(aTHX_ c) != 0) { ft_conn_fail(aTHX_ c, "http/2 init failed"); return; }
            c->is_h2 = 1;
            ft_h2_step(aTHX_ c);
            return;
        }
    }

    if (c->state == FT_WRITING) {
        while (c->req_off < c->req_len) {
            int want = 0;
            ssize_t n = ft_send(c, c->req + c->req_off, c->req_len - c->req_off, &want);
            if (n > 0) { c->req_off += (size_t)n; continue; }
            if (n < 0 && want)          { ft_arm(aTHX_ c, want); return; }
            if (n < 0 && errno == EINTR) continue;
            if (ft_conn_retry(aTHX_ c)) return;   /* pooled socket died mid-send */
            ft_conn_fail(aTHX_ c, strerror(errno)); return;
        }
        c->state = FT_READING;
        ft_arm(aTHX_ c, HM_EV_READ);
    }

    if (c->state == FT_READING) {
        for (;;) {
            int want = 0; ssize_t n;
            if (c->rlen + 65536 > c->rcap) {
                c->rcap = c->rcap ? c->rcap * 2 : 65536;
                Renew(c->rbuf, c->rcap, char);
            }
            n = ft_recv(c, c->rbuf + c->rlen, c->rcap - c->rlen, &want);
            if (n > 0) {
                c->rlen += (size_t)n;
                if (!c->have_headers) {
                    int r = ft_parse_headers(aTHX_ c);
                    if (r < 0) { ft_conn_fail(aTHX_ c, "malformed response"); return; }
                }
                if (c->have_headers) {
                    if (c->want_ws) {          /* expecting 101 Switching Protocols */
                        if (ft_ws_upgrade(aTHX_ c)) return;
                        ft_conn_fail(aTHX_ c, "websocket upgrade rejected");
                        return;
                    }
                    if (c->on_headers && !c->headers_fired) {
                        c->headers_fired = 1;
                        ft_fire_headers(aTHX_ c);
                    }
                    if (c->chunked) {
                        ft_chunk_feed(aTHX_ c);
                        if (c->on_body && c->cpos > c->hdr_end) {   /* compact */
                            size_t keep = c->rlen - c->cpos;
                            memmove(c->rbuf + c->hdr_end, c->rbuf + c->cpos, keep);
                            c->rlen = c->hdr_end + keep;
                            c->cpos = c->hdr_end;
                        }
                        if (c->chunk_done) { ft_conn_finish(aTHX_ c); return; }
                    } else if (c->on_body) {
                        size_t blen = c->rlen - c->hdr_end;
                        if (blen) {
                            ft_emit_body(aTHX_ c, c->rbuf + c->hdr_end, blen);
                            c->body_recv += blen;
                            c->rlen = c->hdr_end;    /* drop, do not accumulate */
                        }
                        if (c->content_len >= 0 &&
                            c->body_recv >= (size_t)c->content_len) {
                            ft_conn_finish(aTHX_ c); return;
                        }
                    } else if (ft_body_complete(c)) {
                        ft_conn_finish(aTHX_ c); return;
                    }
                }
                continue;
            }
            if (n == 0) {
                if (c->have_headers && !c->chunked && c->content_len < 0)
                    ft_conn_finish(aTHX_ c);
                else if (ft_conn_retry(aTHX_ c))  /* server hung up on reuse */
                    ;
                else
                    ft_conn_fail(aTHX_ c, "connection closed before response was complete");
                return;
            }
            if (want)                    { ft_arm(aTHX_ c, want); return; }
            if (errno == EINTR) continue;
            if (ft_conn_retry(aTHX_ c)) return;   /* reset before any response */
            ft_conn_fail(aTHX_ c, strerror(errno)); return;
        }
    }
}

/* the loop's readiness callback: a C closure carrying the ft_conn* in cl->i */
XS_INTERNAL(ft_conn_ready_cb);
XS_INTERNAL(ft_conn_ready_cb) {
    dVAR; dXSARGS;
    hm_clos *cl = hm_clos_of(aTHX_ cv);
    ft_conn *c  = INT2PTR(ft_conn *, cl->i);
    PERL_UNUSED_VAR(items);
    if (c->state == FT_PARKED) {   /* readable while idle: the server hung up */
        if (c->pool) ft_pool_remove(c->pool, c);
        ft_conn_free(aTHX_ c);
        XSRETURN_EMPTY;
    }
    ft_conn_step(aTHX_ c);
    XSRETURN_EMPTY;
}

/* the deadline callback: the timer has fired (and been consumed by the loop),
 * so clear our handles before failing so teardown does not re-cancel it. */
XS_INTERNAL(ft_conn_timeout_cb);
XS_INTERNAL(ft_conn_timeout_cb) {
    dVAR; dXSARGS;
    hm_clos *cl = hm_clos_of(aTHX_ cv);
    ft_conn *c  = INT2PTR(ft_conn *, cl->i);
    PERL_UNUSED_VAR(items);
    c->timer = NULL;
    if (c->timer_h) { SvREFCNT_dec(c->timer_h); c->timer_h = NULL; }
    ft_conn_fail(aTHX_ c, "request timed out");
    XSRETURN_EMPTY;
}

/* Hyperman-direct (hm_abi) callbacks: same behavior as the closures above,
 * with the ft_conn as ud - no CV, no Perl call frame. */
static void ft_hm_ready(pTHX_ int fd, int mask, void *ud) {
    ft_conn *c = (ft_conn *)ud;
    PERL_UNUSED_VAR(fd);
    PERL_UNUSED_VAR(mask);
    if (c->state == FT_PARKED) {   /* readable while idle: the server hung up */
        if (c->pool) ft_pool_remove(c->pool, c);
        ft_conn_free(aTHX_ c);
        return;
    }
    ft_conn_step(aTHX_ c);
}

static void ft_hm_timeout(pTHX_ void *ud) {
    ft_conn *c = (ft_conn *)ud;
    c->hm_timer = NULL;            /* the handle died with the fire */
    ft_conn_fail(aTHX_ c, "request timed out");
}

/* ---- the loss-detection timer -------------------------------------------- */

XS_INTERNAL(ft_conn_pto_cb);
XS_INTERNAL(ft_conn_pto_cb) {
    dVAR; dXSARGS;
    hm_clos *cl = hm_clos_of(aTHX_ cv);
    ft_conn *c  = INT2PTR(ft_conn *, cl->i);
    PERL_UNUSED_VAR(items);
    c->pto = NULL;
    if (c->pto_h) { SvREFCNT_dec(c->pto_h); c->pto_h = NULL; }
    if (c->pto_fn) c->pto_fn(aTHX_ c);
    XSRETURN_EMPTY;
}

static void ft_hm_pto(pTHX_ void *ud) {
    ft_conn *c = (ft_conn *)ud;
    c->hm_pto = NULL;              /* the handle died with the fire */
    if (c->pto_fn) c->pto_fn(aTHX_ c);
}

static void ft_conn_cancel_pto(pTHX_ ft_conn *c) {
    if (c->hm_pto) {
        if (!PL_dirty) c->hm->timer_cancel(aTHX_ c->hm_loop, c->hm_pto);
        c->hm_pto = NULL;
    }
    if (c->pto) { ft_del_timer(aTHX_ c->loop, c->pto); c->pto = NULL; }
    if (c->pto_h) {
        /* the foreign-loop handle: cancelled the same way the deadline's is */
        SvREFCNT_dec(c->pto_h);
        c->pto_h = NULL;
    }
}

/* Can this connection carry a probe timeout at all?
 *
 * It needs a real one-shot timer. The native loop has them and the
 * Hyperman-direct path has them (hm->timer is a kernel timer with a C
 * callback). A FOREIGN Perl loop does not, necessarily: Fetch::Loop::Hyperman
 * without the C ABI deliberately keeps a list and sweeps it every 0.1s, which
 * is a sound trade for a request deadline measured in seconds and useless for
 * loss detection measured in milliseconds - a PTO quantised to 100ms is not a
 * PTO, it is a stall.
 *
 * So this is asked before a transport that needs one is chosen, and the honest
 * answer where it is false is to refuse that transport rather than to run it
 * badly. */
static int ft_conn_can_pto(ft_conn *c) {
    return c->hm != NULL || c->loop_sv == NULL;
}

/* (Re)arm the probe timeout. Unlike the deadline this is called constantly,
 * so it cancels whatever was pending first: the last call wins. */
static void ft_conn_arm_pto(pTHX_ ft_conn *c, double secs,
                            void (*fn)(pTHX_ struct ft_conn *c)) {
    ft_conn_cancel_pto(aTHX_ c);
    c->pto_fn = fn;
    if (secs <= 0 || !fn) return;
    if (c->hm) {
        c->hm_pto = c->hm->timer(aTHX_ c->hm_loop, secs, ft_hm_pto, c);
        return;
    }
    if (c->loop_sv) return;        /* refused above; nothing to arm */
    if (!c->pto_cb)
        c->pto_cb = hm_closure(aTHX_ ft_conn_pto_cb, NULL, NULL, NULL, NULL,
                               PTR2IV(c), 0);
    c->pto = ft_add_timer(aTHX_ c->loop, secs, c->pto_cb, 1);
}

/* Arm the per-request deadline (seconds). Native loop uses the C timer;
 * a foreign loop is asked via _ft_timer. */
static void ft_conn_arm_timeout(pTHX_ ft_conn *c, double secs) {
    if (secs <= 0) return;
    if (c->hm) {   /* precise one-shot kernel timer, C callback, cancellable */
        c->hm_timer = c->hm->timer(aTHX_ c->hm_loop, secs, ft_hm_timeout, c);
        return;
    }
    c->timer_cb = hm_closure(aTHX_ ft_conn_timeout_cb, NULL, NULL, NULL, NULL,
                             PTR2IV(c), 0);
    if (c->loop_sv) ft_loop_timer(aTHX_ c, secs);
    else            c->timer = ft_add_timer(aTHX_ c->loop, secs, c->timer_cb, 1);
}

/* A parked keep-alive connection may have been closed by the server while
 * idle. A one-byte MSG_PEEK distinguishes a healthy idle socket (EAGAIN, no
 * pending data) from a closed or confused one (0, unexpected data, or error). */
static int ft_conn_alive(ft_conn *c) {
    char b;
    ssize_t n = ft_os_recv(c->fd, &b, 1, MSG_PEEK);
    if (n < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) return 1;
    return 0;
}

/* Revive a parked connection for a new request: swap in the new request bytes,
 * future and streaming sink, then send straight away (fd + TLS already up). */
static void ft_conn_revive(pTHX_ ft_conn *c, const char *req_bytes, STRLEN req_len,
                           double timeout, SV *body, SV *on_body, SV *future) {
    c->state = FT_WRITING;
    Safefree(c->req);
    Newx(c->req, req_len, char);
    memcpy(c->req, req_bytes, req_len);
    c->req_len = req_len; c->req_off = 0;
    c->future  = SvREFCNT_inc(future);
    if (c->on_body) { SvREFCNT_dec(c->on_body); c->on_body = NULL; }
    if (on_body && SvOK(on_body) && SvROK(on_body)) c->on_body = SvREFCNT_inc(on_body);
    if (c->on_headers) { SvREFCNT_dec(c->on_headers); c->on_headers = NULL; }
    if (ft_conn_on_headers_next) c->on_headers = SvREFCNT_inc(ft_conn_on_headers_next);
    c->headers_fired = 0;
    if (c->rq_body) { SvREFCNT_dec(c->rq_body); c->rq_body = NULL; }
    if (SvOK(body)) c->rq_body = newSVsv(body);
    c->reused = 1;
    ft_conn_arm_timeout(aTHX_ c, timeout);
    /* The fd and TLS are already up and the socket is writable, and we are
     * still READ-armed from parking. Send now rather than waiting for a
     * writability callback: a complete send transitions to READING and leaves
     * us correctly armed with no re-arm crossing at all. (A rare short write
     * falls back to arming WRITE inside ft_conn_step.) */
    ft_conn_step(aTHX_ c);
}

/* Start a request. host/port already split; req_bytes is the full HTTP/1.1
 * request. Returns a Fetch::Future (pending) resolving to a Fetch::Response. */
static SV *ft_h1_start(pTHX_ ft_loop *loop, SV *loop_sv, ft_pool *pool,
                       const char *host, const char *port,
                       const char *req_bytes, STRLEN req_len,
                       int tls, int verify, double timeout,
                       SV *method, SV *scheme, SV *authority, SV *path,
                       SV *headers_av, SV *body, SV *on_body,
                       const char *ws_key) {
    struct addrinfo *ai = NULL;
    int fd = -1, dnsfd = -1;
    ft_dns *dns = NULL;
    ft_conn *c;
    char poolkey[300];
    SV *future = hmf_new(aTHX_ "Fetch::Future");

    /* reuse a live parked connection to the same host, if we have one */
    if (pool) {
        snprintf(poolkey, sizeof(poolkey), "%s:%d:%s:%s",
                 ft_conn_proto_next, tls ? 1 : 0, host, port);
        for (;;) {
            ft_conn *k = ft_pool_take(pool, poolkey);
            if (!k) break;
            if (!ft_conn_alive(k)) { k->pool = NULL; ft_conn_free(aTHX_ k); continue; }
            ft_conn_revive(aTHX_ k, req_bytes, req_len, timeout, body, on_body, future);
            return future;
        }
    }

    /* Three ways to get an address, in order of what costs least.
     *
     * A literal - which is every request in this dist's own tests, and every
     * request to a machine named by number - is a parse and nothing else, so
     * it connects here with no thread and no extra loop turn.
     *
     * A name goes to the resolver thread (ft_dns.h) and the connection starts
     * in FT_RESOLVING with the pipe as its fd. Only if that cannot be started
     * at all - no pthreads in the build, native Windows, or the process out
     * of threads - does this fall back to resolving inline, which is what
     * every request used to do and is the one thing here that can stall the
     * loop. */
    if (ft_dns_numeric(host, port, &ai)) {
        fd = ft_conn_dial(ai);
        freeaddrinfo(ai);
        ai = NULL;
        if (fd < 0) {
            SV *e = sv_2mortal(newSVpvf("Fetch: connect %s:%s: %s",
                                        host, port, strerror(errno)));
            hmf_settle(aTHX_ future, HMF_FAILED, &e, 1);
            return future;
        }
    }
    else if ((dnsfd = ft_dns_start(host, port, &dns)) < 0) {
        struct addrinfo hints;
        int gai;
        memset(&hints, 0, sizeof(hints));
        hints.ai_family   = AF_UNSPEC;
        hints.ai_socktype = SOCK_STREAM;
        gai = getaddrinfo(host, port, &hints, &ai);
        if (gai != 0) {
            SV *e = sv_2mortal(newSVpvf("Fetch: resolve %s:%s: %s",
                                        host, port, gai_strerror(gai)));
            hmf_settle(aTHX_ future, HMF_FAILED, &e, 1);
            return future;
        }
        fd = ft_conn_dial(ai);
        freeaddrinfo(ai);
        ai = NULL;
        if (fd < 0) {
            SV *e = sv_2mortal(newSVpvf("Fetch: connect %s:%s: %s",
                                        host, port, strerror(errno)));
            hmf_settle(aTHX_ future, HMF_FAILED, &e, 1);
            return future;
        }
    }

    Newxz(c, 1, ft_conn);
    c->loop    = loop;
    c->loop_sv = loop_sv ? SvREFCNT_inc(loop_sv) : NULL;
    if (pool) {
        c->pool = pool;
        Newx(c->poolkey, strlen(poolkey) + 1, char);
        memcpy(c->poolkey, poolkey, strlen(poolkey) + 1);
    }
    /* Either a socket mid-connect, or the resolver's pipe. The rest of the
     * machinery does not care which: it arms c->fd and waits. */
    c->fd     = dns ? dnsfd : fd;
    c->dns    = dns;
    c->state  = dns ? FT_RESOLVING : FT_CONNECTING;
    c->future = SvREFCNT_inc(future);
    c->simple = ft_conn_simple_next;   /* raw-hash response mode for this UA */
    c->content_len = -1;
    c->tls    = tls;
    c->verify = verify;
    if (ws_key && *ws_key) {
        size_t kl = strlen(ws_key);
        c->want_ws = 1;
        Newx(c->ws_key, kl + 1, char);
        memcpy(c->ws_key, ws_key, kl + 1);
    }
    /* host/port outlive the connect: SNI and verification need the host, and
     * ft_conn_retry needs both to redial a pooled socket the server closed. */
    { size_t hl = strlen(host); Newx(c->host, hl + 1, char); memcpy(c->host, host, hl + 1); }
    { size_t pl = strlen(port); Newx(c->port, pl + 1, char); memcpy(c->port, port, pl + 1); }
    /* structured pieces for a possible h2 upgrade - consumed only by the
     * nghttp2 path after ALPN, which happens on TLS. On a cleartext
     * connection h2 can never be negotiated, so skip storing them (the body
     * is already in req_bytes; the caller passes undef here). */
    if (tls) {
        c->rq_method    = newSVsv(method);
        c->rq_scheme    = newSVsv(scheme);
        c->rq_authority = newSVsv(authority);
        c->rq_path      = newSVsv(path);
        if (SvROK(headers_av) && SvTYPE(SvRV(headers_av)) == SVt_PVAV)
            c->rq_headers = (AV *)SvREFCNT_inc(SvRV(headers_av));
        if (SvOK(body)) c->rq_body = newSVsv(body);
    }
    if (on_body && SvOK(on_body) && SvROK(on_body)) c->on_body = SvREFCNT_inc(on_body);
    if (ft_conn_on_headers_next) c->on_headers = SvREFCNT_inc(ft_conn_on_headers_next);
    Newx(c->req, req_len, char);
    memcpy(c->req, req_bytes, req_len);
    c->req_len = req_len;

    c->hm      = ft_conn_hm_next;        /* Hyperman-direct mode, per UA */
    c->hm_loop = ft_conn_hm_loop_next;
    if (!c->hm)   /* the hm path never fires a coderef; skip building one */
        c->watcher = hm_closure(aTHX_ ft_conn_ready_cb, NULL, NULL, NULL, NULL,
                                PTR2IV(c), 0);
    /* Resolving waits to READ the answer; connecting waits for WRITE, which
     * is how a non-blocking connect reports itself finished. */
    ft_arm(aTHX_ c, dns ? HM_EV_READ : HM_EV_WRITE);
    (void)ft_pool_peek;   /* used by ft_h3_start below */
    /* The deadline covers the resolve as well as the request, which is the
     * point of putting the pipe in c->fd: a nameserver that never answers
     * fails with the timeout the caller asked for rather than hanging. */
    ft_conn_arm_timeout(aTHX_ c, timeout);
    return future;
}

/* Start a request over HTTP/3.
 *
 * The shape differs from ft_h1_start in one way that matters: a connection is
 * REUSED WHILE LIVE. ft_pool_peek finds an h3 connection to this origin
 * whether or not it is idle, and the request becomes another stream on it -
 * so N concurrent requests cost one handshake and one socket. Only when there
 * is none does this build one, and it is put in the pool immediately rather
 * than when it goes idle, so the requests started right after it find it.
 *
 * Returns a pending Fetch::Future, or one already failed when h3 cannot be
 * used at all - the caller (ft_ua.h) then has an ordinary answer to fall back
 * to TCP on rather than an exception. */
static SV *ft_h3_start(pTHX_ ft_loop *loop, SV *loop_sv, ft_pool *pool,
                       const char *host, const char *port,
                       int verify, double timeout,
                       SV *method, SV *scheme, SV *authority, SV *path,
                       SV *headers_av, SV *body, SV *on_body) {
    SV *future = hmf_new(aTHX_ "Fetch::Future");
    char poolkey[300];
    ft_conn *c = NULL;
    struct addrinfo *ai = NULL;
    int simple = ft_conn_simple_next;

    if (!FT_H3_AVAILABLE) {
        SV *e = sv_2mortal(newSVpvs("Fetch: HTTP/3 not built "
                                    "(need ngtcp2 + nghttp3)"));
        hmf_settle(aTHX_ future, HMF_FAILED, &e, 1);
        return future;
    }

    snprintf(poolkey, sizeof(poolkey), "%s:1:%s:%s", FT_PROTO_H3, host, port);
    if (pool) c = ft_pool_peek(pool, poolkey);
    if (c && ft_conn_alive_h3(c)) {
        ft_h3_request(aTHX_ c, future, method, scheme, authority, path,
                      headers_av, body, on_body, ft_conn_on_headers_next,
                      simple);
        return future;
    }
    if (c) {   /* it died since it was parked; do not hand it out again */
        ft_pool_remove(pool, c);
        c->pool = NULL;
        ft_conn_free(aTHX_ c);
        c = NULL;
    }

    Newxz(c, 1, ft_conn);
    c->loop    = loop;
    c->loop_sv = loop_sv ? SvREFCNT_inc(loop_sv) : NULL;
    c->fd      = -1;
    c->verify  = verify;
    c->tls     = 1;                       /* there is no cleartext QUIC */
    c->simple  = simple;
    c->content_len = -1;
    c->hm      = ft_conn_hm_next;
    c->hm_loop = ft_conn_hm_loop_next;
    { size_t l = strlen(host); Newx(c->host, l + 1, char); memcpy(c->host, host, l + 1); }
    { size_t l = strlen(port); Newx(c->port, l + 1, char); memcpy(c->port, port, l + 1); }

    /* Loss detection needs a real one-shot timer, and a foreign Perl loop
     * with only a coarse sweep has none. Refusing here is the honest answer
     * the caller can act on; running QUIC on a 100ms timer would look like a
     * network problem rather than a configuration one. */
    if (!ft_conn_can_pto(c)) {
        SV *e = sv_2mortal(newSVpvs("Fetch: HTTP/3 needs the standalone loop "
                                    "or Hyperman's C ABI - this loop has no "
                                    "timer fine enough for loss detection"));
        ft_conn_free(aTHX_ c);
        hmf_settle(aTHX_ future, HMF_FAILED, &e, 1);
        return future;
    }

    /* QUIC dials UDP, so the address is wanted here rather than handed to a
     * connect() the loop finishes. Resolution reuses ft_dns.h's inline path:
     * an h3 attempt follows an Alt-Svc header from a request that has already
     * resolved this origin, so the answer is in the system's cache. */
    {
        struct addrinfo hints;
        int gai;
        if (!ft_dns_numeric(host, port, &ai)) {
            memset(&hints, 0, sizeof hints);
            hints.ai_family   = AF_UNSPEC;
            hints.ai_socktype = SOCK_DGRAM;
            gai = getaddrinfo(host, port, &hints, &ai);
            if (gai != 0) {
                SV *e = sv_2mortal(newSVpvf("Fetch: resolve %s:%s: %s",
                                            host, port, gai_strerror(gai)));
                ft_conn_free(aTHX_ c);
                hmf_settle(aTHX_ future, HMF_FAILED, &e, 1);
                return future;
            }
        }
    }

    if (ft_h3_connect(aTHX_ c, ai) != 0) {
        freeaddrinfo(ai);
        {
            SV *e = sv_2mortal(newSVpvs("Fetch: HTTP/3 connect failed"));
            ft_conn_free(aTHX_ c);
            hmf_settle(aTHX_ future, HMF_FAILED, &e, 1);
        }
        return future;
    }
    freeaddrinfo(ai);

    if (pool) {
        c->pool = pool;
        Newx(c->poolkey, strlen(poolkey) + 1, char);
        memcpy(c->poolkey, poolkey, strlen(poolkey) + 1);
        /* In the pool from the start, not when it goes idle: the requests
         * issued in the same tick have to find it, or each opens its own
         * connection and the multiplexing never happens. */
        ft_pool_put(aTHX_ pool, c);
    }
    if (!c->hm)
        c->watcher = hm_closure(aTHX_ ft_conn_ready_cb, NULL, NULL, NULL, NULL,
                                PTR2IV(c), 0);
    ft_h3_request(aTHX_ c, future, method, scheme, authority, path,
                  headers_av, body, on_body, ft_conn_on_headers_next, simple);
    /* The handshake's first flight, and then wait for the peer. */
    ft_h3_step(aTHX_ c);
    /* The deadline is the CONNECTION's here, not the request's: several
     * requests share it and the last one to finish is what it has to cover.
     * A per-request deadline over a shared connection would kill the
     * connection out from under everybody else's request. */
    (void)timeout;
    return future;
}

#endif /* FT_HTTP_H */
