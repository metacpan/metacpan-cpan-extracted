#ifndef HM_CORE_H
#define HM_CORE_H

/* Hyperman loop core: connections, HTTP parse and
 * serialize, PSGI dispatch (sync, streaming, Future), watchers, deferred
 * queue, timeouts/fairness, listener, workers, and the prefork supervisor.
 * Requires hm_future.h (futures + C closures) and hyperman.h (backends). */

#define HM_POOL_MAX     1024   /* pooled hm_conn structs kept per loop     */
#define HM_IOV_MAX      64     /* writev: header + up to 63 body chunks    */
#define HM_SWEEP_SECS   5.0    /* timeout sweep interval                    */
#define HM_HIDX_STACK   64     /* header-line index on the stack before
                                  falling back to the loop's growable one  */
#define HM_WB_HIWAT     (1 << 20)  /* queued response bytes a connection may
                                      hold before hm_process stops serving
                                      its pipeline until the client reads  */
#define HM_WB_KEEP      (1 << 20)  /* a pooled connection keeps a write
                                      buffer up to this; larger ones are
                                      freed, so one big response does not
                                      pin its buffer for the pool's life  */

#include "hm_win.h"     /* the socket/IO shim: hm_os_*, hm_iovec, hm_memmem.
                           First, so every later header sees the platform
                           headers it pulls; a passthrough on POSIX. */
#include "hm_parse.h"   /* hm_hline, hm_parse_index, hm_chunked_* */
#include "hm_proxy.h"   /* the PROXY protocol header, v1 and v2  */
#ifndef _WIN32
#include <pwd.h>        /* user => 'name' (hm_resolve_drop)        */
#include <grp.h>        /* group => 'name'                          */
#include <netdb.h>      /* getaddrinfo (hm_resolve)                 */
#include <sys/un.h>     /* path => listeners                        */
#include <sys/stat.h>
#endif
#include "hm_abi.h"     /* public C ABI: hm_abi table + callback typedefs */

#if defined(HM_HAVE_SENDFILE_LINUX)
#include <sys/sendfile.h>
#elif defined(HM_HAVE_SENDFILE_FREEBSD) || defined(HM_HAVE_SENDFILE_MACOS)
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/uio.h>
#endif

typedef struct hm_loop hm_loop;

/* A streaming response body (filehandle / IO-object PSGI bodies): instead
 * of slurping the whole file into one SV, the connection drains its write
 * buffer and refills it a chunk at a time - or hands the file straight to
 * sendfile(2) on a plaintext socket. `sv` keeps the body (and so its fd)
 * alive; kind 1 reads the fd at an explicit offset (pread), kind 2 pulls
 * a getline object. At most HM_BSRC_CHUNK response-body bytes are ever
 * buffered per connection. */
#define HM_BSRC_CHUNK    65536
#define HM_SENDFILE_MAX  (1 << 20)   /* bytes per sendfile(2) call */
typedef struct {
    int           kind;        /* 0 none, 1 regular-file fd, 2 getline    */
    int           fd;          /* kind 1: borrowed from the body's handle */
    off_t         off;         /* kind 1: next byte to read               */
    UV            remaining;   /* bytes still owed to the client          */
    SV           *sv;          /* the body, owned: keeps the fd alive     */
    unsigned char nosf;        /* sendfile(2) refused; use the read path  */
} hm_bsrc;
typedef struct hm_conn hm_conn;

/* A bound listening socket. The loop holds an array of these; a connection
 * remembers the one it was accepted on so TLS-wrap, SERVER_PORT, and the
 * built-in https redirect are all per-listener. */
typedef struct {
    int   fd;             /* bound listener fd, -1 until bound        */
    char *host;           /* bind host (owned)                        */
    int   port;
    void *tls_ctx;        /* SSL_CTX*; NULL = plain                   */
    int   http2;          /* per-listener h2 (h2c / ALPN)             */
    int   http3;          /* per-listener h3: a QUIC listener on the
                           * same host and port, over UDP. Intrinsically
                           * the same origin as the TLS listener it sits
                           * on - same certificate, same SNI registry -
                           * which is why it is a flag here rather than
                           * a listener of its own (hm_quic.h)        */
    int   redirect_https; /* 0 = off; else target https port for 301  */

    /* What the context above was built from, kept so a worker can build
     * another one. The spec these are copied from lives in the parent's
     * cfg, which a worker does not hold - and without them tls_reload
     * would have nothing to rebuild with. Owned copies: the spec's
     * strings belong to the parent's config and outlive nothing here. */
    char *tls_cert;       /* NULL on a plain listener                 */
    char *tls_key;
    char *tls_ca;         /* NULL unless client certs are verified    */
    int   tls_verify;
    SV   *tls_sni;        /* the SNI map run() was given, or NULL: a
                           * tls_reload with no map rebuilds from it   */

    /* The QUIC half, when http3 is on. It rides on this listener rather
     * than being one of its own because h3 is intrinsically the same origin
     * as the TLS listener it advertises from: same host, same port number,
     * same certificate, same SNI registry - only the transport differs. */
    int   udp_fd;         /* bound SOCK_DGRAM fd, or -1               */
    void *quic;           /* hm_quic_srv *, or NULL                   */
    void *quic_ctx;       /* the QUIC-side SSL_CTX                    */
    char *altsvc;         /* precomputed Alt-Svc value, or NULL       */
    int   starved;        /* accept hit EMFILE: read interest is off
                           * until a short timer puts it back        */
    int   is_unix;        /* a path listener: no peer address, no
                           * TCP options, SERVER_PORT 0              */
    int   proxy_protocol; /* a connection starts with a PROXY header
                           * (hm_proxy_readable), before any TLS     */
} hm_listener;

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
    SV      *cid_sv;        /* psgix.hyperman.conn: [fd, id], per conn */
    SV      *peer_sv;       /* cached env values, constant for the  */
    SV      *peer_host_sv;  /* life of the connection: REMOTE_ADDR, */
    SV      *peer_port_sv;  /* REMOTE_HOST, REMOTE_PORT,            */
    SV      *sname_sv;      /* SERVER_NAME,                         */
    SV      *sport_sv;      /* SERVER_PORT                          */
    SV      *resp_f;        /* pending response Future (awaiting)   */
    SV      *env_sv;        /* held while parked, for access_log    */
    void    *h2;            /* hm_h2_sess* when in HTTP/2 mode       */
    void    *ssl;           /* SSL* when this is a TLS connection    */
    const char *tls_proto;  /* SSL_PROTOCOL / SSL_CIPHER for $env.   */
    const char *tls_cipher; /* OpenSSL-owned, valid for the conn     */
    void    *tls_peer;      /* hm_tls_peer*, only if a client cert   */
    unsigned char tls_hs;         /* TLS handshake in progress       */
    unsigned char tls_r_wants_w;  /* SSL_read blocked wanting write  */
    unsigned char tls_failed;     /* SSL_new failed at accept: closed  */
    unsigned char stream_open;    /* a streamed response has begun and
                                   * not closed: one per request       */
    UV            body_rx;        /* body bytes since body_phase began */
    time_t        body_t0;        /* when body_phase began             */
    unsigned char tls_w_wants_r;  /* SSL_write blocked wanting read  */
    unsigned char ktls_tx;        /* TX offloaded to the kernel (reporting
                                   * only - the write paths ask OpenSSL
                                   * itself, see hm_ktls_tx)          */
    unsigned char recv_fallback;  /* this connection reads off readiness for
                                   * good: completion was unavailable or
                                   * refused once, and a persistent watcher
                                   * is armed                    */
    unsigned char recv_inflight;  /* a completion-mode recv is outstanding
                                   * into c->rbuf; the kernel may write to
                                   * it at any moment, so it must not be
                                   * grown, freed or reused until the
                                   * completion lands            */
    unsigned char recv_lent;      /* reading off a lent readiness watcher
                                   * while requests wait unconsumed in
                                   * rbuf (hm_recv_unsafe)        */
    unsigned char again_queued;   /* hm_again_push has it for the top of
                                   * the next turn (hm_run_again) */
    unsigned char detached;       /* app took the socket (see hm_detach) */
    unsigned char tunnel;         /* a 101 stream handle owns the bytes both
                                   * ways (hm_stream_open): what the peer
                                   * sends goes to the handle's read half,
                                   * never to the request parser         */
    unsigned char accepts_gzip;   /* this request's Accept-Encoding    */
    unsigned char cont_sent;      /* a 100 Continue has gone out for the
                                   * request being read. Per request, and
                                   * on the connection rather than on the
                                   * stack, because the headers stay in rbuf
                                   * and hm_process re-reads them on every
                                   * readable event until the body is whole */
    unsigned char is_head;        /* the request being answered is a HEAD:
                                   * the headers go out, the body does not */
    unsigned char in_app;         /* a synchronous handler for this
                                   * connection is on the C stack. A ->get
                                   * inside it pumps this same loop, so a
                                   * close asked for meanwhile is deferred
                                   * to the frame that called the app   */
    unsigned char close_deferred; /* hm_close was asked for while in_app */
    unsigned char read_paused;    /* read interest dropped while in_app with
                                   * a full buffer (hm_read_pause)       */
    unsigned char pp_wait;        /* awaiting the PROXY header: nothing
                                   * else reads this socket until it is
                                   * parsed (hm_proxy_readable)         */
    char     proxy_addr[INET6_ADDRSTRLEN]; /* the proxy that connected, once
                                   * the header named the real client */
    int      proxy_port;
    unsigned char backlogged;     /* hm_process stopped on a full write
                                   * buffer; the drain re-queues it     */
    unsigned char req_11;         /* the request on the plate is HTTP/1.1 */
    unsigned char stream_mode;    /* a streamed body's framing (HM_SM_*) */
    unsigned char stream_done;    /* a streamed body ended with keep-alive
                                   * on: the drain serves the pipeline   */
    UV       stream_serial; /* streamed responses begun on this conn; a
                             * Writer carries the one it belongs to, so a
                             * writer kept past its response cannot end
                             * the next one                              */
    UV       stream_left;   /* HM_SM_LENGTH: body octets still owed      */
    size_t   chunk_pos;     /* chunked body: octets validated so far, so
                             * a re-scan starts at the last chunk boundary
                             * rather than at the first chunk           */
    size_t   chunk_dec;     /* decoded octets up to chunk_pos           */
    hm_bsrc  bsrc;          /* streaming body being dripped, if any */
    int      last_status;   /* last response status/bytes (logging) */
    size_t   last_blen;
    char     peer[INET6_ADDRSTRLEN];  /* REMOTE_ADDR, filled at accept    */
    int      peer_port;               /* REMOTE_PORT, filled at accept    */
    time_t   last_active;
    time_t   req_start;     /* first byte of an incomplete request  */
    time_t   last_rx;       /* last read that delivered bytes: the body
                             * phase is timed from here, not from the
                             * request's first byte                  */
    unsigned char body_phase; /* headers complete, body still arriving:
                             * hm_sweep applies body_timeout        */
    /* A body being drained to a temp file rather than accumulated in rbuf.
     * -1 when not spilling. The fd becomes psgi.input and the handle owns it
     * from that moment; the file is unlinked at creation, so nothing is left
     * behind however the request ends. */
    int      spill_fd;
    long     spill_got;     /* body octets already written to it    */
    hm_conn *lru_prev, *lru_next;
    hm_conn *pool_next;
    hm_loop *loop;
    hm_listener *lst;       /* listener this conn was accepted on   */
};

/* QUIC's expiry min-heap. hm_quic.h owns every operation on it; the type is
 * here because hm_loop carries one BY VALUE, so the "has QUIC anything to do"
 * test on the loop's hot path is a load and a compare rather than a
 * dereference. ngtcp2 rearms a connection's expiry after essentially every
 * packet, and none of the backend timer vtables can carry that - see the
 * header comment in hm_quic.h for the costing. */
typedef struct hm_qconn hm_qconn;
typedef struct { hm_qconn **a; int n, cap; } hm_qheap;

/* app-owned fd watcher: a one-shot Future, a persistent Perl callback, or a
 * persistent C callback (the ABI path - dispatched with no Perl frame) */
typedef struct {
    SV            *sv;      /* future or Perl cb; NULL for a C watcher */
    unsigned char  is_cb;
    hm_abi_io_cb   c_cb;    /* C watcher; checked before sv            */
    void          *c_ud;
} hm_iow;

/* timer watcher */
#define HM_TW_FUTURE 0
#define HM_TW_CB     1
#define HM_TW_SWEEP  2
#define HM_TW_HARDSTOP 3
#define HM_TW_C      4      /* ABI: C callback, cancellable via handle */
typedef struct hm_tw_s {
    int kind;
    SV *sv;
    hm_loop *loop;
    hm_abi_timer_cb c_cb;   /* HM_TW_C only */
    void           *c_ud;
    double          due;    /* oneshot deadline, monotonic seconds; 0 = none */
    /* Cancelled, and waiting on the loop's graveyard to be freed. The
     * backends fill a whole event array before any of it is dispatched, so
     * a timer cancelled from an earlier event in the batch may still be
     * named by a later one; freeing it at once was a use after free. */
    unsigned char   dead;
    struct hm_tw_s *gy_next;
} hm_tw;

/* The deadline a oneshot is armed for, on the clock hm_dispatch checks it
 * against. The backend's own timer is a wake-up hint, not the deadline:
 * kqueue's EVFILT_TIMER on NetBSD is a callout in scheduler ticks, and in a
 * VM those ticks run ahead of CLOCK_MONOTONIC. */
#define hm_tw_due(secs) ((double)hm_now_ns() / 1e9 + (secs))

typedef struct { int fd; UV id; } hm_again;

/* One piece of an access-log line. The format string is compiled to these
 * once, in the parent, so writing a line is a walk over an array and never a
 * parse: a literal run, an $env value (the key SV carries its hash), or one
 * of the computed fields. */
#define HM_LT_LIT      0   /* literal bytes                                 */
#define HM_LT_ENV      1   /* $env->{key}, escaped; "-" when absent         */
#define HM_LT_DASH     2   /* %l: always "-"                                */
#define HM_LT_STATUS   3   /* %s, %>s                                       */
#define HM_LT_BYTES    4   /* %b: body bytes, "-" when there were none      */
#define HM_LT_BYTES0   5   /* %B: body bytes, "0" when there were none      */
#define HM_LT_TIME     6   /* %t: [dd/Mon/YYYY:HH:MM:SS +ZZZZ]              */
#define HM_LT_TIME_ISO 7   /* json: YYYY-MM-DDTHH:MM:SS+ZZZZ                */
#define HM_LT_REQLINE  8   /* %r: METHOD URI PROTO                          */
#define HM_LT_QUERY    9   /* %q: ?query, or nothing                        */
#define HM_LT_PID     10   /* %P                                            */
#define HM_LT_DUR_US  11   /* %D: microseconds since the request was built  */
#define HM_LT_DUR_S   12   /* %T: whole seconds of the same                 */
typedef struct {
    int     kind;
    char   *lit;        /* HM_LT_LIT: owned                                */
    size_t  litlen;
    SV     *key;        /* HM_LT_ENV: a shared-string SV, hash precomputed */
} hm_logtok;

struct hm_loop {
    int         pid;                /* the process that created this loop
                                     (hm_os_getpid: MSVC has no pid_t) */
    hm_backend *be;
    hm_conn   **conns;              /* [HM_MAXFD] */
    hm_iow     *io_r, *io_w;        /* [HM_MAXFD] app io watchers */
    AV         *deferred;           /* run-soon callbacks          */
    hm_again   *again;              /* conns with buffered requests */
    int         again_n, again_cap;
    hm_hline   *hidx;               /* header-line index overflow buffer */
    int         hidx_cap;
    hm_conn    *lru_head, *lru_tail;
    hm_conn    *pool; int pool_n;
    /* Completion-mode receive (io_uring only, opt-in). `completion` is set
     * once at loop start when the backend can do it and the operator asked.
     * `quar` holds read buffers belonging to connections that closed with a
     * recv still outstanding - see hm_quar_push. */
    int         completion;
    struct hm_quar *quar;
    hm_tw      *tw_gy;              /* cancelled timers, freed between batches */
    int         starved_retry;      /* a listener waits for hm_accept_unstarve */
    hm_tw      *sweep_tw;
    SV         *app;                /* server: PSGI app coderef     */
    hm_listener *listeners;         /* server: bound listeners      */
    int         nlisteners;
    int         attached;           /* server attached (>=1 listener) */
    int         nconns;
    int         stop;
    int         stopping;           /* graceful shutdown in progress */
    int         running;
    int         perl_owned;         /* created via Hyperman::Loop->new */
    time_t      now;
    double      idle_timeout;
    double      header_timeout;
    double      body_timeout;       /* a body stalled this long is closed */
    double      request_timeout;    /* whole request ceiling; 0 = none    */
    UV          body_min_rate;      /* bytes/s floor over a body; 0 = none */
    int         max_pipeline;       /* fairness: requests per conn per wakeup */
    size_t      max_read;           /* request size ceiling (headers + body) */
    int         compress;          /* gzip responses (0 = off, the default) */
    size_t      compress_min;      /* below this, gzip buys nothing         */
    int         compress_level;    /* gzip level; HZ_LEVEL by default       */
    SV         *compress_types;    /* AV of extra compressible media types  */
    SV         *self_sv;            /* cached psgix.loop wrapper */
    SV         *log_cb;             /* access_log coderef, or NULL */
    int         log_fd;             /* fast access-log fd (C writer), or -1 */
    char       *log_buf;            /* pending Combined-format log lines    */
    size_t      log_len, log_cap;
    time_t      log_ts_sec;         /* second the cached stamp below is for  */
    char        log_ts[32];         /* "dd/Mon/YYYY:HH:MM:SS +ZZZZ", 1Hz     */
    time_t      date_sec;           /* second the Date header below is for   */
    char        date_hdr[40];       /* "Date: <IMF-fixdate>\r\n", 1Hz        */
    hm_logtok  *logtok;             /* the compiled access_log_format        */
    int         nlogtok;
    int         log_json;           /* values escaped for JSON, not CLF      */
    int         log_wants_t0;       /* the format reads %D/%T: stamp requests */
    time_t      log_iso_sec;        /* second the ISO stamp below is for     */
    char        log_iso[40];        /* "YYYY-MM-DDTHH:MM:SS+ZZZZ", 1Hz        */
    UV          requests;           /* requests dispatched (stats)  */
    UV          accepts;            /* connections accepted (stats) */
    UV          denied;             /* connections dropped at accept, denylist */
    UV          bytes_out;          /* response bytes queued (stats) */
    UV          datagrams;          /* QUIC datagrams taken off the wire */
    UV          h3_conns;           /* QUIC handshakes completed         */
    UV          h3_live;            /* QUIC connections open now         */
    UV          h3_requests;        /* requests served over HTTP/3       */
    UV          datagrams_out;      /* QUIC datagrams sent (one sendto
                                     * each: no GSO anywhere yet)       */
    UV          http3_max_conns;    /* ceiling on h3_live, 0 = unlimited */
    hm_qheap    qheap;              /* QUIC expiry deadlines (hm_quic.h) */
    UV          max_requests;       /* recycle worker after N (0=off) */
    int         recycle_pending;    /* max_requests hit; drain at loop top */
    double      shutdown_grace;     /* graceful-drain bound (secs)   */
    hm_tw      *hardstop_tw;
};

/* One served request, counted, and max_requests tested - for every protocol
 * that finishes one. The bound belongs to the worker and not to HTTP/1: a
 * site whose browsers all negotiate h2 would otherwise never reach it, and
 * the worker it was meant to retire grows for as long as the box lets it.
 *
 * Not on the 101 paths (h2c upgrade, detach, tunnel), which count their
 * request and deliberately do not test: the socket there has just left this
 * loop for an application that means to hold it open, and a drain decided by
 * the request that handed it over is the one moment it must not happen.
 *
 * A function and not a macro because the argument is read five times. */
static void hm_count_request(hm_loop *loop) {
    loop->requests++;
    if (loop->max_requests && loop->requests >= loop->max_requests
        && !loop->stopping && loop->attached)
        loop->recycle_pending = 1;  /* drain at the loop iteration boundary */
}

/* Does a Hyperman::Writer's tag slot hold this string? The four-element
 * writer shapes (h2 and h3) have the same arity, so they are told apart by
 * the tag and never by length - a length test routes an HTTP/3 body into an
 * nghttp2 session. Used from xs/writer.xs. */
static int hm_writer_tag_is(pTHX_ AV *w, const char *want, STRLEN wantlen) {
    SV **t = av_fetch(w, 3, 0);
    STRLEN l;
    const char *p;
    if (!t || !*t || !SvOK(*t)) return 0;
    p = SvPV(*t, l);
    return l == wantlen && memcmp(p, want, l) == 0;
}

/* Find the listener owning a ready fd (listener count is tiny). */
static hm_listener *hm_listener_for_fd(hm_loop *loop, int fd) {
    int i;
    for (i = 0; i < loop->nlisteners; i++)
        if (loop->listeners[i].fd == fd) return &loop->listeners[i];
    return NULL;
}

/* The same, for the QUIC side. Separate rather than a flag on the above,
 * because a UDP listener fd is never in loop->conns[] and the caller wants
 * to know which of the two it has. */
static hm_listener *hm_listener_for_udp(hm_loop *loop, int fd) {
    int i;
    for (i = 0; i < loop->nlisteners; i++)
        if (loop->listeners[i].udp_fd >= 0 && loop->listeners[i].udp_fd == fd)
            return &loop->listeners[i];
    return NULL;
}

static SV      *hm_empty_input;     /* shared empty psgi.input */
static SV      *hm_empty_input_sv(pTHX);   /* ... checked still open */
#ifndef _WIN32
static pid_t    hm_children[1024];  /* the supervisor's pool (POSIX only) */
static time_t   hm_child_start[1024];
/* The WORKER INDEX each of those was forked with, which is not its position
 * here: this array is kept packed by swapping the last entry down over a
 * departed one, so a position means nothing beyond "somebody lives here". The
 * index is an identity - it picks the worker's waker slot and its CPU - so it
 * has to travel with the child rather than be recomputed from where the child
 * happens to sit. */
static int      hm_child_widx[1024];
static int      hm_nchildren = 0;
#endif
static UV       hm_id_counter = 0;

static SV *hm_loop_to_sv(pTHX_ hm_loop *loop);
static void hm_on_signal(pTHX_ hm_loop *loop);
static void hm_deliver(pTHX_ int fd, UV id, SV *resp);
static int hm_flush(pTHX_ hm_conn *c);
static void hm_process(pTHX_ hm_conn *c);
static int hm_queue_response(pTHX_ hm_conn *c, SV *resp);
static void hm_close(pTHX_ hm_loop *loop, hm_conn *c);
static void hm_wb_reserve(hm_conn *c, size_t need);
static void hm_wb_put(hm_conn *c, const char *p, size_t n);
static void hm_again_push(hm_loop *loop, hm_conn *c);
static void hm_tw_gy_sweep(hm_loop *loop);
static void hm_h2_free(pTHX_ void *h2);   /* defined in hm_http2.h */
static void hm_readable(pTHX_ hm_conn *c);
static void hm_read_resume(hm_loop *loop, hm_conn *c);

/* ABI v6 stream handles, defined in hm_stream.h (included below, after the
 * HTTP/1 and HTTP/2 halves it sits on top of). The two counters are read on
 * the close and flush paths rather than called into, because they are zero
 * for every connection that never opened a handle - which is nearly all of
 * them - and a list walk per flush is not free. */
static int  hm_stream_live_n   = 0;
static int  hm_stream_paused_n = 0;
static void hm_quic_readable(pTHX_ hm_loop *loop, hm_listener *lst); /* hm_quic.h */
static void hm_quic_expire(pTHX_ hm_loop *loop);                     /* hm_quic.h */
static void hm_quic_srv_attach(pTHX_ hm_loop *loop, hm_listener *lst, int widx);
static void hm_quic_srv_free(pTHX_ hm_listener *lst);
static void hm_quic_shutdown(pTHX_ hm_loop *loop);
static void hm_quic_ctx_swap(pTHX_ hm_listener *lst, void *fresh);
static uint64_t hm_quic_next_deadline(hm_loop *loop);
static void hm_quic_secret_init(void);
static void hm_stream_conn_gone(pTHX_ int fd, UV id);
static int  hm_stream_deliver(pTHX_ int fd, UV cid, int64_t sid,
                              const char *buf, STRLEN len, int fin);
static void hm_stream_h2_gone(pTHX_ int fd, UV id, int64_t sid);
static void hm_stream_drained(pTHX_ hm_conn *c);
static int  hm_h2_reentrant(hm_conn *c);  /* hm_http2.h */

#include "hm_tls.h"                        /* SSL_CTX, wrap, hm_cread/hm_cwrite */

/* ---- small utilities ----------------------------------------------------- */

static const char *hm_reason(int s) {
    switch (s) {
        case 100: return "Continue";      case 101: return "Switching Protocols";
        case 102: return "Processing";    case 103: return "Early Hints";
        case 200: return "OK";            case 201: return "Created";
        case 204: return "No Content";    case 301: return "Moved Permanently";
        case 302: return "Found";         case 304: return "Not Modified";
        case 400: return "Bad Request";   case 401: return "Unauthorized";
        case 403: return "Forbidden";     case 404: return "Not Found";
        case 405: return "Method Not Allowed";
        case 426: return "Upgrade Required";
        case 500: return "Internal Server Error";
        default:  return "OK";
    }
}

/* Tiny decimal formatters: snprintf's format parsing and locale machinery
 * are measurable at hot-path request rates. Return bytes written. */
static size_t hm_utoa(char *out, unsigned long v) {
    char tmp[20];
    size_t n = 0, i;
    do { tmp[n++] = (char)('0' + v % 10); v /= 10; } while (v);
    for (i = 0; i < n; i++) out[i] = tmp[n - 1 - i];
    return n;
}
static size_t hm_itoa(char *out, long v) {
    if (v < 0) { out[0] = '-'; return 1 + hm_utoa(out + 1, 0UL - (unsigned long)v); }
    return hm_utoa(out, (unsigned long)v);
}

/* Status line for the response: precomputed for the common statuses, built
 * into buf (>= 64 bytes) otherwise. Sets *len, returns the line. */
static const char *hm_status_line(int s, size_t *len, char *buf) {
#define HM_SL(str) do { *len = sizeof(str) - 1; return str; } while (0)
    switch (s) {
        case 200: HM_SL("HTTP/1.1 200 OK\r\n");
        case 201: HM_SL("HTTP/1.1 201 Created\r\n");
        case 204: HM_SL("HTTP/1.1 204 No Content\r\n");
        case 301: HM_SL("HTTP/1.1 301 Moved Permanently\r\n");
        case 302: HM_SL("HTTP/1.1 302 Found\r\n");
        case 304: HM_SL("HTTP/1.1 304 Not Modified\r\n");
        case 400: HM_SL("HTTP/1.1 400 Bad Request\r\n");
        case 401: HM_SL("HTTP/1.1 401 Unauthorized\r\n");
        case 403: HM_SL("HTTP/1.1 403 Forbidden\r\n");
        case 404: HM_SL("HTTP/1.1 404 Not Found\r\n");
        case 405: HM_SL("HTTP/1.1 405 Method Not Allowed\r\n");
        case 500: HM_SL("HTTP/1.1 500 Internal Server Error\r\n");
    }
#undef HM_SL
    {
        const char *r = hm_reason(s);
        size_t rl = strlen(r), n = 9;
        memcpy(buf, "HTTP/1.1 ", 9);
        n += hm_itoa(buf + n, (long)s);
        buf[n++] = ' ';
        memcpy(buf + n, r, rl); n += rl;
        buf[n++] = '\r'; buf[n++] = '\n';
        *len = n;
        return buf;
    }
}

/* Format a peer sockaddr into a printable REMOTE_ADDR string and its port ("" /
 * 0 on failure or for address families we don't serve). */
static void hm_fmt_peer(char *out, size_t outlen, int *port, const struct sockaddr *sa) {
    out[0] = '\0';
    if (port) *port = 0;
    if (!sa) return;
    if (sa->sa_family == AF_INET) {
        const struct sockaddr_in *s4 = (const struct sockaddr_in *)sa;
        inet_ntop(AF_INET, &s4->sin_addr, out, (socklen_t)outlen);
        if (port) *port = ntohs(s4->sin_port);
    } else if (sa->sa_family == AF_INET6) {
        const struct sockaddr_in6 *s6 = (const struct sockaddr_in6 *)sa;
        /* An IPv4 client of a dual-stack listener arrives as ::ffff:a.b.c.d.
         * Formatted as the IPv4 it is: the denylist and the rate limiter
         * key on the string, and "1.2.3.4" must be one client whichever
         * listener it came through. */
        if (IN6_IS_ADDR_V4MAPPED(&s6->sin6_addr))
            inet_ntop(AF_INET, ((const unsigned char *)&s6->sin6_addr) + 12,
                      out, (socklen_t)outlen);
        else
            inet_ntop(AF_INET6, &s6->sin6_addr, out, (socklen_t)outlen);
        if (port) *port = ntohs(s6->sin6_port);
    }
}

static void hm_set_nonblock(int fd) { hm_os_set_nonblock(fd); }

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

/* A read handle over an already-open descriptor, rewound. The handle owns the
 * descriptor from this point. */
static SV *hm_input_from_fd(pTHX_ int fd) {
    PerlIO *fp;
    GV *gv;
    IO *io;
    if (PerlLIO_lseek(fd, 0, SEEK_SET) < 0) { PerlLIO_close(fd); return NULL; }
    fp = PerlIO_fdopen(fd, "rb");
    if (!fp) { PerlLIO_close(fd); return NULL; }
    gv = hm_anon_glob(aTHX);
    if (!gv) { PerlIO_close(fp); return NULL; }
    io = GvIOn(gv);
    IoIFP(io) = fp;
    IoTYPE(io) = IoTYPE_RDONLY;
    return newRV_noinc((SV *)gv);
}

/* A temp file for a body being drained out of the read buffer.
 *
 * Unlinked the instant it exists, so the descriptor is its only reference: it
 * goes away when the request ends, when the handler dies, or when the worker
 * is killed, and there is no cleanup path anywhere to forget. Nothing is
 * inherited across a fork either, which is the failure this workspace keeps
 * meeting from the other direction. */
/* Where a body temp file goes. TMPDIR is the POSIX spelling of the question
 * and TEMP the Windows one - asking only the first left Windows falling back
 * to a "/tmp" that is not there, which is a failed mkstemp on every request
 * carrying a body. */
static const char *hm_tmpdir(void) {
    const char *d = getenv("TMPDIR");
    if (d && *d) return d;
#ifdef _WIN32
    if ((d = getenv("TEMP")) && *d) return d;
    if ((d = getenv("TMP"))  && *d) return d;
    return ".";
#else
    return "/tmp";
#endif
}

/* dir + "/hm-body-XXXXXX" into buf, or 0 if the directory will not fit. */
static int hm_body_tmppath(char *buf, size_t cap) {
    const char *dir = hm_tmpdir();
    size_t dl = strlen(dir);
    if (dl + sizeof("/hm-body-XXXXXX") > cap) return 0;
    my_strlcpy(buf, dir, cap);
    if (dl && dir[dl - 1] != '/' && dir[dl - 1] != '\\')
        my_strlcat(buf, "/", cap);
    my_strlcat(buf, "hm-body-XXXXXX", cap);
    return 1;
}

static int hm_body_tmpfile(void) {
    char path[512];
    int fd;
    if (!hm_body_tmppath(path, sizeof path)) return -1;
    fd = mkstemp(path);
    if (fd < 0) return -1;
    (void)unlink(path);
    return fd;
}

/* Above this, the body goes to a temp file instead of a second copy in
 * memory. Below it, the copy is cheaper than an inode and three syscalls. */
#ifndef HM_SPILL_BODY
#  define HM_SPILL_BODY (1024 * 1024)
#endif

/* psgi.input over a temp file, for a body large enough that a second copy in
 * memory is the wrong trade.
 *
 * The file is UNLINKED as soon as it is open, and the handle keeps it alive:
 * it vanishes when the handle is closed, whether that is a normal response, a
 * handler that died, or the worker being killed mid-request. There is no
 * cleanup path to forget and nothing on disk for another process to find.
 *
 * Returns NULL to fall back to the in-memory handle, because a server that
 * cannot make a temp file should still serve the request.
 */
static SV *hm_new_input_file(pTHX_ const char *body, STRLEN len) {
    char path[512];
    int fd;
    STRLEN off = 0;

    if (!hm_body_tmppath(path, sizeof path)) return NULL;

    fd = mkstemp(path);
    if (fd < 0) return NULL;
    (void)PerlLIO_unlink(path);          /* the handle is the only reference */

    while (off < len) {
        SSize_t n = PerlLIO_write(fd, body + off, len - off);
        if (n <= 0) { PerlLIO_close(fd); return NULL; }
        off += (STRLEN)n;
    }
    if (PerlLIO_lseek(fd, 0, SEEK_SET) < 0) { PerlLIO_close(fd); return NULL; }

    return hm_input_from_fd(aTHX_ fd);
}

/* psgi.input: an in-memory read handle over the request body, via the
 * PerlIO :scalar layer - the C equivalent of open($fh,'<',\$body).
 *
 * WINDOWS TAKES THE FILE AT EVERY SIZE. PerlIO_openn is declared in perlio.h
 * but is not among the symbols perl5xx.dll exports, so the :scalar layer
 * cannot be reached from XS there at all - it is a link error, which is what
 * the first Windows build of this core hit. The temp file needs nothing but
 * PerlIO_fdopen, which IS exported, and it is the path every platform
 * already runs for a body over HM_SPILL_BODY rather than a second one
 * written for this. The trade is an inode and three syscalls on a Windows
 * request that carries a body. */
static SV *hm_new_input(pTHX_ const char *body, STRLEN len) {
#ifdef _WIN32
    SV *f = hm_new_input_file(aTHX_ body, len);
    return f ? f : &PL_sv_undef;
#else
    static int layer_loaded = 0;
    SV *bufsv;
    if (len > HM_SPILL_BODY) {
        SV *f = hm_new_input_file(aTHX_ body, len);
        if (f) return f;
    }
    bufsv = newSVpvn(body, len);
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
#endif
}

/* The shared empty psgi.input, as every bodyless request gets it: one glob
 * for the whole worker, because a fresh :scalar handle per request is a
 * glob, an IO and a layer for a body that is not there. One check keeps the
 * sharing honest: an application that closed it (or re-opened it over
 * something else) left a handle with no input stream, and the next request
 * would read a closed filehandle. A new one replaces it then. */
static SV *hm_empty_input_sv(pTHX) {
    if (hm_empty_input && SvROK(hm_empty_input)) {
        SV *gv = SvRV(hm_empty_input);
        IO *io = SvTYPE(gv) == SVt_PVGV ? GvIO((GV *)gv) : NULL;
        if (io && IoIFP(io)) return SvREFCNT_inc(hm_empty_input);
        SvREFCNT_dec(hm_empty_input);
        hm_empty_input = NULL;
    }
    hm_empty_input = hm_new_input(aTHX_ "", 0);
    return SvREFCNT_inc(hm_empty_input);
}

/* psgix.io: a dup of the client socket, so an app that hijacks it keeps
 * the socket alive after the server side closes. Absent on Windows:
 * duplicating a socket there is WSADuplicateSocket, not dup(2), and the
 * result would have to be re-wrapped for perl's IO layer - unproven, and
 * psgix.io is optional in PSGI, so it is simply not offered. */
static SV *hm_fh_for_fd(pTHX_ int fd) {
#ifdef _WIN32
    (void)fd;
    return &PL_sv_undef;
#else
    int nfd = dup(fd);
    PerlIO *fp;
    GV *gv;
    IO *io;
    if (nfd < 0) return &PL_sv_undef;
    fp = PerlIO_fdopen(nfd, "r+");
    if (!fp) { hm_os_close(nfd); return &PL_sv_undef; }
    gv = hm_anon_glob(aTHX);
    io = GvIO(gv);
    IoIFP(io) = fp;
    IoOFP(io) = fp;
    IoTYPE(io) = IoTYPE_RDWR;
    return newRV_noinc((SV *)gv);
#endif
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
    } else if (SvROK(body) && (SvTYPE(SvRV(body)) == SVt_PVGV
                               || SvTYPE(SvRV(body)) == SVt_PVIO)) {
        /* sv_2io croaks on anything that is not a handle, and this is not
         * under an eval: a body of [200, [], {}] would unwind the loop */
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

/* ---- streaming body sources ---------------------------------------------- *
 * The lift: can this filehandle-ish body be streamed rather than slurped?
 *
 *   - a glob / IO ref over a regular file lifts to (fd, tell, remaining):
 *     remaining is the Content-Length header when the response carries one,
 *     else file-size minus position (which is then also what the auto
 *     Content-Length announces).
 *   - a blessed object lifts when it has BOTH getline and fileno over a
 *     regular file AND the response promises a Content-Length - the range
 *     contract Punk::SendFile::Reader satisfies; the raw fd position is
 *     taken as the read point, so hand over a handle that has not been
 *     buffer-read from. Without a usable fd, a getline object with a
 *     Content-Length still streams, one chunk per getline (kind 2).
 *
 * Anything else returns 0 and the caller slurps, exactly as before. */

static UV hm_bsrc_method_uv(pTHX_ SV *obj, const char *meth, int *ok) {
    dSP;
    UV out = 0;
    int n;
    *ok = 0;
    ENTER; SAVETMPS; PUSHMARK(SP);
    XPUSHs(obj);
    PUTBACK;
    n = call_method(meth, G_SCALAR | G_EVAL);
    SPAGAIN;
    if (n > 0) {
        SV *r = POPs;
        if (!SvTRUE(ERRSV) && SvOK(r) && SvIV(r) >= 0) {
            out = (UV)SvUV(r);
            *ok = 1;
        }
    }
    PUTBACK; FREETMPS; LEAVE;
    return out;
}

static int hm_bsrc_lift(pTHX_ SV *body, hm_bsrc *bs, int has_len, UV clen) {
    if (!SvROK(body)) return 0;

    if (sv_isobject(body)) {
        HV *stash = SvSTASH(SvRV(body));
        int fd = -1, ok = 0;
        if (!gv_fetchmethod_autoload(stash, "getline", 0)) return 0;
        if (!has_len) return 0;      /* no promised length, keep the slurp */
        if (gv_fetchmethod_autoload(stash, "fileno", 0)) {
            UV v = hm_bsrc_method_uv(aTHX_ body, "fileno", &ok);
            if (ok) fd = (int)v;
        }
        if (fd >= 0) {
            struct stat st;
            off_t pos;
            if (fstat(fd, &st) == 0 && S_ISREG(st.st_mode)
                && (pos = lseek(fd, 0, SEEK_CUR)) >= 0) {
                bs->kind = 1;
                bs->fd   = fd;
                bs->off  = pos;
                bs->remaining = clen;
                bs->sv = SvREFCNT_inc(body);
                return 1;
            }
        }
        bs->kind = 2;
        bs->remaining = clen;
        bs->sv = SvREFCNT_inc(body);
        return 1;
    }

    if (SvTYPE(SvRV(body)) == SVt_PVGV || SvTYPE(SvRV(body)) == SVt_PVIO) {
        IO *io = sv_2io(body);
        PerlIO *fp = io ? IoIFP(io) : NULL;
        struct stat st;
        int fd;
        off_t pos;
        if (!fp) return 0;
        fd = PerlIO_fileno(fp);
        if (fd < 0 || fstat(fd, &st) < 0 || !S_ISREG(st.st_mode)) return 0;
        pos = (off_t)PerlIO_tell(fp);
        if (pos < 0 || pos > st.st_size) return 0;
        bs->kind = 1;
        bs->fd   = fd;
        bs->off  = pos;
        bs->remaining = has_len ? clen : (UV)(st.st_size - pos);
        bs->sv = SvREFCNT_inc(body);
        return 1;
    }
    return 0;
}

/* Close out a source: the PSGI body contract says the server closes the
 * handle it was given (hm_slurp_body has always done so). Objects get
 * their close method; a glob's PerlIO is closed directly. */
static void hm_bsrc_release(pTHX_ hm_bsrc *bs) {
    if (!bs->kind) return;
    if (bs->sv) {
        if (sv_isobject(bs->sv)) {
            if (gv_fetchmethod_autoload(SvSTASH(SvRV(bs->sv)), "close", 0)) {
                dSP;
                ENTER; SAVETMPS; PUSHMARK(SP);
                XPUSHs(bs->sv);
                PUTBACK;
                call_method("close", G_DISCARD | G_EVAL);
                FREETMPS; LEAVE;
            }
        }
        else {
            IO *io = sv_2io(bs->sv);
            if (io && IoIFP(io)) {
                PerlIO_close(IoIFP(io));
                IoIFP(io) = NULL;
                IoOFP(io) = NULL;
            }
        }
        SvREFCNT_dec(bs->sv);
    }
    memset(bs, 0, sizeof(*bs));
}

/* Refill the write buffer with the next chunk of the source. Returns the
 * bytes added; 0 when the source is spent; -1 on a source that ended
 * early (file truncated under us, getline died or dried up) - the client
 * was promised more bytes than it will get, so the connection must not
 * be reused. */
static ssize_t hm_bsrc_fill(pTHX_ hm_conn *c) {
    hm_bsrc *bs = &c->bsrc;
    if (!bs->remaining) return 0;
    if (bs->kind == 1) {
        size_t want = bs->remaining < HM_BSRC_CHUNK
                          ? (size_t)bs->remaining : HM_BSRC_CHUNK;
        ssize_t n;
        hm_wb_reserve(c, want);
        n = hm_os_pread(bs->fd, c->wbuf + c->wlen, want, bs->off);
        if (n <= 0) { c->keepalive = 0; return -1; }
        c->wlen += (size_t)n;
        bs->off += n;
        bs->remaining -= (UV)n;
        return n;
    }
    for (;;) {                                   /* kind 2: one getline */
        dSP;
        SV *chunk;
        STRLEN l = 0;
        const char *p = NULL;
        int n;
        ENTER; SAVETMPS; PUSHMARK(SP);
        XPUSHs(bs->sv);
        PUTBACK;
        n = call_method("getline", G_SCALAR | G_EVAL);
        SPAGAIN;
        chunk = n > 0 ? POPs : NULL;
        if (SvTRUE(ERRSV) || !chunk || !SvOK(chunk)) {
            PUTBACK; FREETMPS; LEAVE;
            c->keepalive = 0;                    /* remaining > 0 here */
            return -1;
        }
        p = SvPV(chunk, l);
        if (l > bs->remaining) l = (STRLEN)bs->remaining;  /* hold the framing */
        if (l) hm_wb_put(c, p, l);
        bs->remaining -= (UV)l;
        PUTBACK; FREETMPS; LEAVE;
        if (l) return (ssize_t)l;
        if (!bs->remaining) return 0;
        /* an empty chunk with bytes still owed: ask again */
    }
}

/* Scan a header AV for Content-Length; fills *out and returns 1 if found. */
static int hm_hav_clen(pTHX_ AV *hav, UV *out) {
    SSize_t i, n;
    if (!hav) return 0;
    n = av_len(hav) + 1;
    for (i = 0; i + 1 < n; i += 2) {
        SV **k = av_fetch(hav, i, 0);
        STRLEN kl;
        const char *ks;
        if (!k || !*k) continue;
        ks = SvPV(*k, kl);
        if (kl == 14 && hm_strncasecmp(ks, "Content-Length", 14) == 0) {
            SV **v = av_fetch(hav, i + 1, 0);
            if (v && *v && SvOK(*v)) {
                /* Digits only. SvUV of "abc" is 0, which selected the
                 * counted mode with a length of nothing and cut the body
                 * at its first write; a value that is not a length is
                 * treated as absent, and the framing chosen without it. */
                STRLEN vl, j;
                const char *vs = SvPV(*v, vl);
                if (vl == 0 || vl > 19) return 0;
                for (j = 0; j < vl; j++)
                    if (vs[j] < '0' || vs[j] > '9') return 0;
                *out = (UV)SvUV(*v);
                return 1;
            }
        }
    }
    return 0;
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

/* Return a connection struct to the pool, or free it when the pool is full.
 * The buffers ride along so the steady state allocates nothing - but only
 * at their ordinary sizes. A read buffer grown for a 15MB body, or a write
 * buffer grown for one slow client, would otherwise stay that size for as
 * long as the pool held the struct, and a thousand of them is the whole
 * ceiling resident for nothing. */
static void hm_pool_conn(hm_loop *loop, hm_conn *c) {
    if (c->rbuf && c->rcap > HM_RBUF)    { free(c->rbuf); c->rbuf = NULL; c->rcap = 0; }
    if (c->wbuf && c->wcap > HM_WB_KEEP) { free(c->wbuf); c->wbuf = NULL; c->wcap = 0; }
    if (loop->pool_n < HM_POOL_MAX) {
        c->pool_next = loop->pool;
        loop->pool = c;
        loop->pool_n++;
    } else {
        if (c->wbuf) free(c->wbuf);
        if (c->rbuf) free(c->rbuf);
        free(c);
    }
}

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

/* ---- completion-mode receive ---------------------------------------------
 *
 * A readiness backend says "this fd has bytes" and the core reads them. A
 * completion backend is asked for the read UP FRONT and hands back bytes that
 * are already in the buffer - which is how the read syscall stops being a
 * syscall per request and becomes part of one batched submission per turn of
 * the loop.
 *
 * What that costs is that the kernel holds a pointer into c->rbuf for a while,
 * and the two things the core does casually with that buffer - GROW it, and
 * POOL it for the next connection - both become memory corruption if they
 * happen while a read is outstanding. Growth is handled by only ever growing
 * before arming (hm_arm_recv). Pooling is handled here.
 *
 * The identity problem is the other half. A completion can outlive the
 * connection that asked for it: hm_close closes the fd, the number is reused
 * by a new connection moments later, and the old read lands looking exactly
 * like the new one's. So every read carries a token of fd plus the
 * connection's generation id, and a completion whose token does not match the
 * connection now holding that fd is somebody else's. */

#define HM_RECV_TOKEN(c) \
    (((uint64_t)(c)->id << 17) | (uint64_t)(unsigned)(c)->fd)

/* A read buffer whose connection is gone but whose kernel read is not. Parked
 * under the token the kernel will hand back, and freed when it does. */
typedef struct hm_quar {
    uint64_t        token;
    char           *buf;
    struct hm_quar *next;
} hm_quar;

static void hm_quar_push(hm_loop *loop, uint64_t token, char *buf) {
    hm_quar *q;
    if (!buf) return;
    q = (hm_quar *)malloc(sizeof(hm_quar));
    /* Out of memory with a read outstanding: the buffer CANNOT be freed, so
     * it is leaked deliberately. One leaked read buffer beats handing the
     * kernel a pointer into the heap it no longer owns. */
    if (!q) return;
    q->token = token;
    q->buf   = buf;
    q->next  = loop->quar;
    loop->quar = q;
}

static void hm_quar_release(hm_loop *loop, uint64_t token) {
    hm_quar **pp = &loop->quar, *q;
    while ((q = *pp)) {
        if (q->token == token) { *pp = q->next; free(q->buf); free(q); return; }
        pp = &q->next;
    }
}

static void hm_quar_free_all(hm_loop *loop) {
    hm_quar *q = loop->quar, *n;
    while (q) { n = q->next; free(q->buf); free(q); q = n; }
    loop->quar = NULL;
}

/* Ask for this connection's next read. 1 if one is now outstanding, 0 if the
 * caller must fall back to a readiness watcher - which is always correct, so
 * every refusal here is a performance decision and never a correctness one. */
static int hm_arm_recv(hm_loop *loop, hm_conn *c) {
    size_t want;
    if (!loop->completion || !loop->be->submit_recv) return 0;
    /* TLS reads belong to OpenSSL: the bytes on the socket are ciphertext and
     * the engine may already hold plaintext this would never see. */
    if (c->ssl || c->recv_inflight || c->detached || c->pp_wait) return 0;
    if (c->rlen == c->rcap) {
        /* Grow BEFORE the kernel is given the pointer. Never while a read is
         * outstanding, which is why this cannot live in the completion. */
        size_t ncap;
        if (c->rcap >= loop->max_read) return 0;   /* the readiness path owns
                                                    * the oversize/413 answer */
        ncap = c->rcap * 2;
        if (ncap > loop->max_read) ncap = loop->max_read;
        c->rbuf = (char *)hm_xrealloc(c->rbuf, ncap);
        c->rcap = ncap;
    }
    want = c->rcap - c->rlen;
    if (loop->be->submit_recv(loop->be, c->fd, c->rbuf + c->rlen, want,
                              HM_RECV_TOKEN(c)) != 0)
        return 0;
    c->recv_inflight = 1;
    return 1;
}

static int  hm_read_lend(hm_loop *loop, hm_conn *c);
static void hm_read_unlend(hm_loop *loop, hm_conn *c);

/* Requests are waiting in rbuf behind a park, a streamed body or a full write
 * buffer, and whoever serves them will memmove the buffer down. A completion
 * armed now holds rbuf + rlen, and after the move it lands past the new rlen
 * while rlen counts it from the front: the parser re-reads the tail of the
 * request it already served and waits for the rest of it until the idle
 * sweep. (t/27 on every Linux smoker with liburing: the request after a
 * pipelined one behind a sendfile body was never read.) */
static int hm_recv_unsafe(hm_conn *c) {
    return c->rlen > 0
        && (c->again_queued || c->bsrc.kind || c->awaiting
            || c->backlogged || c->stream_open);
}

/* Arm the next read however this connection reads: a completion if it can,
 * a readiness watcher otherwise. */
static void hm_rearm_read(hm_loop *loop, hm_conn *c) {
    /* A readiness read happens at rlen as it stands at the time, so it is
     * safe across the move; given back once the buffer has been served. */
    if (c->recv_lent) {
        if (hm_recv_unsafe(c)) return;
        hm_read_unlend(loop, c);
        c->recv_lent = 0;
    }
    /* Already reading off readiness: the watcher is persistent and
     * level-triggered, so re-adding it would be a syscall per response on
     * epoll for no effect at all. */
    if (c->recv_fallback) return;
    /* A read is already outstanding: the kernel holds rbuf + rlen and will
     * complete into it. A readiness watcher added now would read the same
     * bytes into the same offset first. hm_arm_recv refuses for the same
     * reason, but its refusal is not a request to fall back. */
    if (c->recv_inflight) return;
    if (loop->completion && hm_recv_unsafe(c)) {
        if (hm_read_lend(loop, c)) c->recv_lent = 1;
        return;
    }
    if (hm_arm_recv(loop, c)) return;
    c->recv_fallback = 1;
    loop->be->add_io(loop->be, c->fd, HM_EV_READ, 0);
}

/* Lend a completion-mode connection a readiness watcher for as long as an
 * application call that may wait on it is on the stack: an HTTP/2 handler
 * waiting for its body to drain is waiting for window updates on this very
 * socket. No completion is outstanding then - HM_EV_RECV re-arms only after
 * hm_process returns, and arming one under it would let the kernel write into
 * a buffer nghttp2 is consuming - so without the watcher the handler pumps a
 * loop that never reads its connection. 1 if lent. */
static int hm_read_lend(hm_loop *loop, hm_conn *c) {
    if (!loop->completion || c->recv_fallback || c->recv_inflight) return 0;
    c->recv_fallback = 1;
    loop->be->add_io(loop->be, c->fd, HM_EV_READ, 0);
    return 1;
}

/* And take it back: the caller's hm_rearm_read returns it to completion. */
static void hm_read_unlend(hm_loop *loop, hm_conn *c) {
    if (!c->read_paused) loop->be->remove_io(loop->be, c->fd, HM_EV_READ);
    c->read_paused = 0;
    c->recv_fallback = 0;
}

static void hm_close(pTHX_ hm_loop *loop, hm_conn *c) {
    /* A synchronous handler for this connection is on the stack: its ->get
     * pumped this loop and the loop found the peer gone, or the sweep found
     * it idle. The frame that called the app still holds c and will finish
     * with it (hm_process's consumed/memmove, hm_queue_response), so the
     * struct cannot be pooled - the next accept would hand it to a new
     * client and the first client's response would land on the second's
     * socket. Stop reading, mark it, and let that frame close it. */
    if (c->in_app) {
        if (!c->close_deferred) {
            c->close_deferred = 1;
            loop->be->remove_io(loop->be, c->fd,
                                HM_EV_READ | (c->writing ? HM_EV_WRITE : 0));
            c->writing = 0;
        }
        return;
    }
    /* Stream handles open on this connection die with it. They are told
     * first, while the connection is still consistent, and they are only
     * marked dead - the handle itself belongs to whoever opened it until
     * it calls stream_close. */
    if (hm_stream_live_n) hm_stream_conn_gone(aTHX_ c->fd, c->id);
    /* Before anything else touches the buffers: if the kernel is still
     * holding a pointer into this connection's read buffer, take the buffer
     * away from the connection so the pooling below cannot hand it to the
     * next one. The connection is pooled with a NULL rbuf and hm_new_conn
     * allocates a fresh one. */
    /* c is never NULL here - every caller passes a live connection, and this
     * function dereferences it unconditionally a few lines down. The `c &&`
     * these two guards used to carry was dead, and it told a static analyser
     * the opposite of the truth: cppcheck reported four null dereferences
     * from it, all of them the guard's fault rather than the code's. */
    if (c->recv_inflight) {
        if (loop->be->cancel_recv) loop->be->cancel_recv(loop->be, c->fd);
        hm_quar_push(loop, HM_RECV_TOKEN(c), c->rbuf);
        c->rbuf = NULL;
        c->rcap = 0;
        c->rlen = 0;
        c->recv_inflight = 0;
    }
    if (c->spill_fd >= 0) {          /* a body was still draining */
        PerlLIO_close(c->spill_fd);
        c->spill_fd = -1;
        c->spill_got = 0;
    }
    int fd = c->fd;
    SV *pending = c->resp_f;      /* cancelled below, once state is consistent */
    c->resp_f = NULL;
    loop->be->remove_io(loop->be, fd, HM_EV_READ | (c->writing ? HM_EV_WRITE : 0));
    if (c->bsrc.kind) hm_bsrc_release(aTHX_ &c->bsrc);   /* mid-stream abort */
    if (c->ssl) hm_tls_conn_free(c);
    hm_os_close(fd);
    hm_lru_unlink(loop, c);
    loop->conns[fd] = NULL;
    loop->nconns--;
    if (c->io_sv)  { SvREFCNT_dec(c->io_sv);  c->io_sv = NULL; }
    if (c->cid_sv) { SvREFCNT_dec(c->cid_sv); c->cid_sv = NULL; }
    if (c->env_sv) { SvREFCNT_dec(c->env_sv); c->env_sv = NULL; }
    if (c->peer_sv)      { SvREFCNT_dec(c->peer_sv);      c->peer_sv = NULL; }
    if (c->peer_host_sv) { SvREFCNT_dec(c->peer_host_sv); c->peer_host_sv = NULL; }
    if (c->peer_port_sv) { SvREFCNT_dec(c->peer_port_sv); c->peer_port_sv = NULL; }
    if (c->sname_sv)     { SvREFCNT_dec(c->sname_sv);     c->sname_sv = NULL; }
    if (c->sport_sv)     { SvREFCNT_dec(c->sport_sv);     c->sport_sv = NULL; }
    /* Detached from the connection BEFORE it is torn down: freeing the
     * session cancels every stream's parked Future, and a continuation
     * that fires on that cancel looks the stream up through c->h2. */
    if (c->h2)     { void *h2 = c->h2; c->h2 = NULL; hm_h2_free(aTHX_ h2); }
    hm_pool_conn(loop, c);
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

/* ---- detach: hand a live HTTP/1 connection to the application ------------ *
 * The seam a protocol upgrade (WebSocket) needs: the socket stays open and
 * becomes the app's, while the server forgets it entirely so the app's own
 * io watchers on that fd fire (hm_dispatch routes to loop->io_r/io_w only
 * when conns[fd] is NULL).
 *
 * Two phases, because the callers of the app frame keep using the conn after
 * it returns (hm_process's consumed/memmove, hm_deliver's flush):
 *
 *   hm_detach        - immediate: validate, disarm the server's watchers so
 *                      no further bytes are pulled in, flag the conn.
 *   hm_conn_release  - deferred: hm_close minus the close(2) and minus the
 *                      watcher removal, run once the caller is done with the
 *                      conn. After it, conns[fd] is NULL and the fd is the
 *                      application's to own and to close.
 *
 * The app must not have produced any response bytes for this request, and
 * returns a sentinel (conventionally [101, [], []]) which is discarded. */
static int hm_detach(pTHX_ hm_loop *loop, int fd, UV id) {
    hm_conn *c;
#ifdef _WIN32
    /* The fd is a CRT wrapper around a SOCKET (hm_win.h). Handing that to
     * perl's IO layer to own, after this server stops watching it, has not
     * been proven on a real Windows box - so it is refused rather than
     * half-supported. A WebSocket tier over this server falls back to
     * psgi.streaming, which is its documented second transport. */
    (void)loop; (void)fd; (void)id; (void)c;
    return -6;
#else
    if (fd < 0 || fd >= HM_MAXFD) return -1;
    c = loop->conns[fd];
    if (!c || c->id != id)       return -1;   /* gone, or a stale ticket    */
    if (c->h2)                   return -2;   /* HTTP/2 streams share a conn */
    if (c->ssl)                  return -3;   /* TLS state cannot be handed on */
    if (c->wlen != c->woff
        || c->bsrc.kind)         return -4;   /* output still draining      */
    if (c->detached)             return -5;   /* already handed over        */
    loop->be->remove_io(loop->be, fd,
                        HM_EV_READ | (c->writing ? HM_EV_WRITE : 0));
    c->writing  = 0;
    c->detached = 1;
    return 0;
#endif
}

/* Deferred half of hm_detach: forget the connection without closing its fd. */
static void hm_conn_release(pTHX_ hm_loop *loop, hm_conn *c) {
    int fd = c->fd;
    SV *pending = c->resp_f;
    /* The fd survives, the connection object does not: a handle naming it
     * is as dead as it would be after a close. */
    if (hm_stream_live_n) hm_stream_conn_gone(aTHX_ c->fd, c->id);
    c->resp_f = NULL;
    if (c->bsrc.kind) hm_bsrc_release(aTHX_ &c->bsrc);
    hm_lru_unlink(loop, c);
    loop->conns[fd] = NULL;
    loop->nconns--;
    if (c->io_sv)  { SvREFCNT_dec(c->io_sv);  c->io_sv = NULL; }
    if (c->cid_sv) { SvREFCNT_dec(c->cid_sv); c->cid_sv = NULL; }
    if (c->env_sv) { SvREFCNT_dec(c->env_sv); c->env_sv = NULL; }
    if (c->peer_sv)      { SvREFCNT_dec(c->peer_sv);      c->peer_sv = NULL; }
    if (c->peer_host_sv) { SvREFCNT_dec(c->peer_host_sv); c->peer_host_sv = NULL; }
    if (c->peer_port_sv) { SvREFCNT_dec(c->peer_port_sv); c->peer_port_sv = NULL; }
    if (c->sname_sv)     { SvREFCNT_dec(c->sname_sv);     c->sname_sv = NULL; }
    if (c->sport_sv)     { SvREFCNT_dec(c->sport_sv);     c->sport_sv = NULL; }
    hm_pool_conn(loop, c);
    if (loop->stopping && loop->nconns == 0) loop->stop = 1;
    /* the request's own Future, if any, is simply dropped - the app owns
     * the socket now, so there is nothing left to cancel it for */
    if (pending) SvREFCNT_dec(pending);
}

static hm_conn *hm_new_conn(hm_loop *loop, int fd, hm_listener *lst) {
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
        c = (hm_conn *)hm_xcalloc(1, sizeof(hm_conn));
    }
    if (!c->rbuf) {
        c->rbuf = (char *)hm_xmalloc(HM_RBUF);
        c->rcap = HM_RBUF;
    }
    c->fd = fd;
    c->keepalive = 1;
    c->spill_fd = -1;          /* 0 is a real fd; the zeroed struct is not
                                * "not spilling" without this */
    c->spill_got = 0;
    c->id = ++hm_id_counter;
    c->loop = loop;
    c->lst = lst;
    c->last_active = loop->now;
    loop->conns[fd] = c;
    loop->nconns++;
#ifndef HM_HAVE_ACCEPT4
    hm_set_nonblock(fd);               /* accept4 did it where there is one */
#endif
    if (!(lst && lst->is_unix)) {
        int one = 1;
        hm_os_setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &one, sizeof(one));
    }
    if (lst && lst->proxy_protocol) {
        /* The PROXY header comes first, on the raw socket, before TLS can
         * wrap it and before any request byte is read. Readiness reads for
         * life (recv_fallback), the header-phase timeout from now, and no
         * TLS until hm_proxy_readable has the client's address. */
        c->pp_wait = 1;
        c->recv_fallback = 1;
        c->req_start = loop->now;
        loop->be->add_io(loop->be, fd, HM_EV_READ, 0);
    }
    else if (lst && lst->tls_ctx) {
        /* TLS wraps first: the handshake is driven off readiness, and
         * hm_arm_recv would decline a TLS connection anyway. The handshake
         * is timed as a request header is (req_start): a peer that opens a
         * socket and never finishes its ClientHello was holding a slot for
         * idle_timeout. A wrap that fails (SSL_new under memory pressure)
         * closes rather than serving plaintext on a TLS listener. */
        c->req_start = loop->now;
        if (hm_tls_wrap(c, lst->tls_ctx) < 0) {
            hm_errlog("Hyperman: TLS setup failed for a new connection; closed\n");
            c->tls_failed = 1;           /* hm_accept closes it, with aTHX */
        } else {
            loop->be->add_io(loop->be, fd, HM_EV_READ, 0);
        }
    }
    else hm_rearm_read(loop, c);
    /* append to LRU tail */
    c->lru_prev = loop->lru_tail;
    if (loop->lru_tail) loop->lru_tail->lru_next = c;
    loop->lru_tail = c;
    if (!loop->lru_head) loop->lru_head = c;
    return c;
}

/* ---- HTTP parse ---------------------------------------------------------- */

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
            && hm_strncasecmp(p, name, nlen) == 0) {
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
        if (hm_strncasecmp(hay + i, needle, nl) == 0) return 1;
    return 0;
}

/* ---- Expect: 100-continue (RFC 9110 10.1.1) -------------------------------
 * A client that expects to send a large body may ask permission first and
 * wait for an interim 100 before spending the upload. A server that never
 * answers does not break such a client - it stalls it, for however long the
 * client is prepared to wait (a second, in curl and in most of the Java
 * clients) on every request. So the answer is worth having for its own sake,
 * and the refusals are worth having more: a body over max_body is refused
 * here, on the headers, rather than after the client has sent it all.
 */
#define HM_EXPECT_NONE     0
#define HM_EXPECT_CONTINUE 1
#define HM_EXPECT_OTHER    2

/* The request line's HTTP version. Only "is it 1.1" is asked: 100-continue
 * is an HTTP/1.1 expectation and a 1.0 client's Expect MUST be ignored. */
static int hm_req_is_11(const char *head, size_t headlen) {
    const char *eol = (const char *)memchr(head, '\r', headlen);
    size_t ll = eol ? (size_t)(eol - head) : headlen;
    return ll >= 8 && memcmp(head + ll - 8, "HTTP/1.1", 8) == 0;
}

/* Classify the Expect field. The value is a list, and 100-continue is the
 * only member this server understands, so anything else - including
 * 100-continue with something else beside it - is an expectation it cannot
 * meet and earns a 417 rather than a silent promise it will not keep. */
static int hm_expectation(const char *head, size_t headlen) {
    size_t vl = 0;
    const char *v;
    if (!hm_req_is_11(head, headlen)) return HM_EXPECT_NONE;
    v = hm_find_header(head, headlen, "expect", 6, &vl);
    if (!v || !vl) return HM_EXPECT_NONE;
    if (vl == 12 && hm_strncasecmp(v, "100-continue", 12) == 0)
        return HM_EXPECT_CONTINUE;
    return HM_EXPECT_OTHER;
}

/* Send the interim response, once per request. Called only where the headers
 * have been accepted AND the body is not all here yet: a request already
 * carrying its whole body is answered with its final status instead, which
 * RFC 9110 allows and every client handles, and a request that is going to
 * be refused is refused before this is ever reached. */
static void hm_send_continue(hm_conn *c, int expect) {
    static const char cont[] = "HTTP/1.1 100 Continue\r\n\r\n";
    if (expect != HM_EXPECT_CONTINUE || c->cont_sent) return;
    c->cont_sent = 1;
    hm_wb_put(c, cont, sizeof(cont) - 1);
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

/* ---- $env fast path ------------------------------------------------------
 * The fixed $env keys as shared-string SVs: the hash is computed once and
 * cached in the shared string table, so hv_store_ent skips both the hashing
 * and the key copy on every request. Values that never vary per process
 * ([1,1], the 0/1 flags, psgi.errors) are read-only singletons shared by
 * refcount; per-connection constants (REMOTE_*, SERVER_*) are cached on the
 * connection. Anything a middleware conventionally assigns in place
 * (psgi.url_scheme, SCRIPT_NAME, PATH_INFO) stays a fresh SV per request. */

enum {
    HMK_REQUEST_METHOD, HMK_REQUEST_URI, HMK_PATH_INFO, HMK_QUERY_STRING,
    HMK_SERVER_PROTOCOL, HMK_SCRIPT_NAME, HMK_SERVER_NAME, HMK_SERVER_PORT,
    HMK_REMOTE_ADDR, HMK_REMOTE_HOST, HMK_REMOTE_PORT,
    HMK_PSGI_VERSION, HMK_PSGI_URL_SCHEME, HMK_PSGI_MULTITHREAD,
    HMK_PSGI_MULTIPROCESS, HMK_PSGI_RUN_ONCE, HMK_PSGI_STREAMING,
    HMK_PSGI_NONBLOCKING, HMK_PSGI_ERRORS, HMK_PSGIX_LOOP, HMK_PSGIX_IO,
    HMK_PSGI_INPUT, HMK_PSGIX_INPUT_BUFFERED, HMK_CONTENT_LENGTH,
    HMK_CONTENT_TYPE, HMK_PSGIX_HM_CONN, HMK_PSGIX_HM_STREAM, HMK_PSGIX_PROXY_ADDR,
    HMK_COUNT
};
static const char *const hm_env_key_name[HMK_COUNT] = {
    "REQUEST_METHOD", "REQUEST_URI", "PATH_INFO", "QUERY_STRING",
    "SERVER_PROTOCOL", "SCRIPT_NAME", "SERVER_NAME", "SERVER_PORT",
    "REMOTE_ADDR", "REMOTE_HOST", "REMOTE_PORT",
    "psgi.version", "psgi.url_scheme", "psgi.multithread",
    "psgi.multiprocess", "psgi.run_once", "psgi.streaming",
    "psgi.nonblocking", "psgi.errors", "psgix.loop", "psgix.io",
    "psgi.input", "psgix.input.buffered", "CONTENT_LENGTH",
    "CONTENT_TYPE", "psgix.hyperman.conn", "psgix.hyperman.stream",
    "psgix.proxy_addr"
};
static SV *hm_env_key[HMK_COUNT];
static SV *hm_env_zero, *hm_env_one;   /* read-only 0/1 flag values      */
static SV *hm_env_version;             /* read-only [1,1]                */
static SV *hm_env_errors;              /* read-only \*STDERR             */

/* The HTTP_* keys for the headers real traffic actually sends, as shared
 * key SVs made once. Storing with a plain char* key makes hv_common hash
 * the string and cut a fresh HEK against the shared string table on every
 * request, then release it again at env teardown; storing through a shared
 * SV reuses the precomputed hash and the one HEK for the process's life.
 * A browser request carries a dozen of these, so it pays per header, per
 * request. Anything not in this table just takes the char* path it always
 * took. Grouped by key length so the lookup is a couple of memcmps. */
static const char *const hm_hdrk_name[] = {
    "HTTP_TE",                                                     /*  7 */
    "HTTP_DNT",                                                    /*  8 */
    "HTTP_HOST",                                                   /*  9 */
    "HTTP_RANGE",                                                  /* 10 */
    "HTTP_ACCEPT", "HTTP_COOKIE", "HTTP_ORIGIN", "HTTP_PRAGMA",    /* 11 */
    "HTTP_REFERER", "HTTP_UPGRADE",                                /* 12 */
    "HTTP_USER_AGENT", "HTTP_CONNECTION",                          /* 15 */
    "HTTP_AUTHORIZATION", "HTTP_CACHE_CONTROL",
    "HTTP_IF_NONE_MATCH",                                          /* 18 */
    "HTTP_ACCEPT_ENCODING", "HTTP_ACCEPT_LANGUAGE",
    "HTTP_X_FORWARDED_FOR",                                        /* 20 */
    "HTTP_X_REQUESTED_WITH",                                       /* 21 */
    "HTTP_IF_MODIFIED_SINCE", "HTTP_X_FORWARDED_PROTO",
    "HTTP_SEC_WEBSOCKET_KEY",                                      /* 22 */
    "HTTP_SEC_WEBSOCKET_VERSION",                                  /* 26 */
    NULL
};
#define HM_HDRK_MAXLEN 26
#define HM_HDRK_PERLEN 5
static SV *hm_hdrk_sv[sizeof(hm_hdrk_name) / sizeof(char *)];
/* index+1 of each candidate, per key length; 0 ends the row */
static unsigned char hm_hdrk_by_len[HM_HDRK_MAXLEN + 1][HM_HDRK_PERLEN];

/* the cached key SV for keybuf/klen, or NULL for the char* fallback */
static SV *hm_hdrk_lookup(const char *keybuf, size_t klen) {
    const unsigned char *row;
    int i;
    if (klen > HM_HDRK_MAXLEN) return NULL;
    row = hm_hdrk_by_len[klen];
    for (i = 0; i < HM_HDRK_PERLEN && row[i]; i++) {
        int idx = row[i] - 1;
        if (memcmp(keybuf, hm_hdrk_name[idx], klen) == 0)
            return hm_hdrk_sv[idx];
    }
    return NULL;
}

/* The two bytes a repeated request header folds with. PSGI joins with the
 * comma of a list header (RFC 9110 5.3). Cookie is the one request header
 * whose list is "; " (RFC 6265 4.2.1), and an HTTP/2 client may send each
 * cookie as its own field (RFC 9113 8.2.3), which browsers do: folded with
 * a comma the session cookie's value grows a tail and its signature fails
 * on every request. The same fold serves HTTP/1.1, where a client that
 * splits Cookie is out of spec but the app is still owed one value. */
static const char *hm_hdr_join_sep(const char *keybuf, size_t klen) {
    return (klen == 11 && memcmp(keybuf, "HTTP_COOKIE", 11) == 0) ? "; " : ", ";
}

static void hm_env_init(pTHX) {
    int i;
    AV *ver;
    if (hm_env_key[0]) return;
    for (i = 0; i < HMK_COUNT; i++)
        hm_env_key[i] = newSVpvn_share(hm_env_key_name[i],
                                       strlen(hm_env_key_name[i]), 0);
    hm_env_zero = newSViv(0); SvREADONLY_on(hm_env_zero);
    hm_env_one  = newSViv(1); SvREADONLY_on(hm_env_one);
    ver = newAV();
    av_push(ver, newSViv(1)); av_push(ver, newSViv(1));
    SvREADONLY_on((SV *)ver);
    hm_env_version = newRV_noinc((SV *)ver); SvREADONLY_on(hm_env_version);
    hm_env_errors  = newRV_inc((SV *)PL_stderrgv); SvREADONLY_on(hm_env_errors);

    for (i = 0; hm_hdrk_name[i]; i++) {
        size_t l = strlen(hm_hdrk_name[i]);
        int j;
        hm_hdrk_sv[i] = newSVpvn_share(hm_hdrk_name[i], (I32)l, 0);
        for (j = 0; j < HM_HDRK_PERLEN; j++) {
            if (!hm_hdrk_by_len[l][j]) {
                hm_hdrk_by_len[l][j] = (unsigned char)(i + 1);
                break;
            }
        }
    }
}

#define hm_env_store(env, k, val) \
    (void)hv_store_ent((env), hm_env_key[(k)], (val), 0)

/* Build a full PSGI env from the request line, the header lines indexed by
 * idx (from hm_parse_index) and, if present, the request body. Sets
 * c->keepalive from the request. */
static HV *hm_build_env(pTHX_ char *head, size_t headlen,
                        const char *body, long clen, hm_conn *c,
                        const hm_hline *idx, int nlines) {
    HV *env = newHV();
    hm_env_init(aTHX);

    /* A fresh HV starts with 8 buckets and this function stores 25-odd keys
     * before the app adds its own, so left alone every request pays two
     * bucket-split reallocs (8 -> 16 -> 32) plus the rehash walk each one
     * does. Ask for the final size up front. 64 rather than 32: a typical
     * browser request carries a dozen HTTP_* headers on top of ours, and
     * middleware adds more. */
    hv_ksplit(env, 64);

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

    hm_env_store(env, HMK_REQUEST_METHOD,  newSVpvn(method, mlen));
    hm_env_store(env, HMK_REQUEST_URI,     newSVpvn(uri, ulen));
    hm_env_store(env, HMK_PATH_INFO,       hm_pct_decode(aTHX_ path, path_l));
    hm_env_store(env, HMK_QUERY_STRING,    newSVpvn(qs, qs_l));
    hm_env_store(env, HMK_SERVER_PROTOCOL, newSVpvn(proto, plen));
    hm_env_store(env, HMK_SCRIPT_NAME,     newSVpvs(""));
    c->is_head = (mlen == 4 && memcmp(method, "HEAD", 4) == 0);
    if (!c->sname_sv) {
        c->sname_sv = newSVpv(c->lst && c->lst->host ? c->lst->host : "0.0.0.0", 0);
        c->sport_sv = newSViv(c->lst ? c->lst->port : 0);
    }
    /* Copies, not the cached SVs themselves. `$env->{REMOTE_ADDR} = $ip`
     * - which is what a reverse-proxy middleware does - assigns INTO the
     * value SV, and a shared one would then carry the forwarded address
     * into every later request on this keep-alive connection, before any
     * middleware had run on them. newSVsv shares the buffer copy-on-write
     * on perls that can, so the copy costs an SV head and no string. */
    hm_env_store(env, HMK_SERVER_NAME, newSVsv(c->sname_sv));
    hm_env_store(env, HMK_SERVER_PORT, newSVsv(c->sport_sv));
    if (c->peer[0]) {
        if (!c->peer_sv) {
            c->peer_sv      = newSVpv(c->peer, 0);
            c->peer_host_sv = newSVpv(c->peer, 0);
        }
        hm_env_store(env, HMK_REMOTE_ADDR, newSVsv(c->peer_sv));
        hm_env_store(env, HMK_REMOTE_HOST, newSVsv(c->peer_host_sv));
    }
    if (c->peer_port) {
        if (!c->peer_port_sv) c->peer_port_sv = newSViv(c->peer_port);
        hm_env_store(env, HMK_REMOTE_PORT, newSVsv(c->peer_port_sv));
    }
    /* Per-request copies, not the shared read-only SVs: an assignment into
     * the slot writes INTO the SV there, and Plack::Middleware::BufferedStreaming
     * does `$env->{'psgi.streaming'} = 1`, which died "Modification of a
     * read-only value" and made every request a 500 under it. The version
     * copy is a fresh RV onto the one read-only array. */
    hm_env_store(env, HMK_PSGI_VERSION,      newSVsv(hm_env_version));
    hm_env_store(env, HMK_PSGI_URL_SCHEME,
                 c->ssl ? newSVpvs("https") : newSVpvs("http"));
    hm_env_store(env, HMK_PSGI_MULTITHREAD,  newSViv(0));
    hm_env_store(env, HMK_PSGI_MULTIPROCESS, newSViv(1));
    hm_env_store(env, HMK_PSGI_RUN_ONCE,     newSViv(0));
    hm_env_store(env, HMK_PSGI_STREAMING,    newSViv(1));
    hm_env_store(env, HMK_PSGI_NONBLOCKING,  newSViv(1));
    /* A copy: `$env->{'psgi.errors'} = $fh` is an assignment INTO the slot's
     * SV, and the shared one is read-only, so an application redirecting
     * its errors died with "Modification of a read-only value". */
    hm_env_store(env, HMK_PSGI_ERRORS,       newSVsv(hm_env_errors));
    if (c->loop->log_wants_t0)                /* %D / %T in the log format */
        (void)hv_stores(env, "psgix.request_start", newSVnv((NV)hm_now_ns() / 1e9));

    /* psgix.loop: this worker's loop, so apps/clients can create loop
     * Futures; psgix.io: the client socket, dup'd so an app that
     * hijacks it keeps the socket alive after we close our fd. */
    hm_env_store(env, HMK_PSGIX_LOOP, hm_loop_to_sv(aTHX_ c->loop));
    if (!c->io_sv) c->io_sv = hm_fh_for_fd(aTHX_ c->fd);
    hm_env_store(env, HMK_PSGIX_IO, SvREFCNT_inc(c->io_sv));
    /* psgix.hyperman.conn: [fd, generation id] - the ticket an app hands
     * back to Hyperman::detach (or the ABI's conn_detach) to take this
     * socket over for a protocol upgrade. HTTP/1 only; the generation id
     * makes a stale ticket a no-op rather than a wrong-connection hit. */
    if (!c->cid_sv) {
        AV *cid = newAV();
        av_extend(cid, 2);
        av_store(cid, 0, newSViv(c->fd));
        av_store(cid, 1, newSVuv(c->id));
        /* The third element is the stream id, and -1 is "the whole
         * connection is the stream" - which is what HTTP/1.1 is. It rides on
         * the same cached arrayref rather than a second one, so
         * psgix.hyperman.stream costs a store and not an allocation. */
        av_store(cid, 2, newSViv(-1));
        c->cid_sv = newRV_noinc((SV *)cid);
    }
    hm_env_store(env, HMK_PSGIX_HM_CONN,   SvREFCNT_inc(c->cid_sv));
    hm_env_store(env, HMK_PSGIX_HM_STREAM, SvREFCNT_inc(c->cid_sv));
    if (c->proxy_addr[0])                   /* the address that connected */
        hm_env_store(env, HMK_PSGIX_PROXY_ADDR, newSVpv(c->proxy_addr, 0));
    if (c->ssl) hm_tls_env(aTHX_ c, env);

    c->keepalive = (plen == 8 && memcmp(proto, "HTTP/1.1", 8) == 0);
    c->req_11    = c->keepalive;   /* before Connection: close can clear it */
    /* Per request, not per connection: a keep-alive connection may send a
     * different Accept-Encoding on its next request, and the response path
     * has no env to read by the time it needs this. One bit, set below. */
    c->accepts_gzip = 0;

    /* header lines, from the framing pass's index (no rescan) */
    char keybuf[300];
    int have_cl = 0;
    int li;
    for (li = 0; li < nlines; li++) {
        const char *p = head + idx[li].off;
        size_t nk = idx[li].klen;
        const char *vp = head + idx[li].voff;
        size_t nv = idx[li].vlen;

        if (nk + 5 >= sizeof(keybuf)) continue;   /* absurd name: not a header
                                                     we would have stored before
                                                     either */
        /* Fold to the canonical HTTP_ form first, then every name test below
         * is a memcmp on known-case bytes rather than a strncasecmp on the
         * wire bytes - three case-blind scans per header gone. The fold maps
         * '-' to '_', which would let a literal "Content_Length" alias the
         * real thing, so the special names also check the wire byte at the
         * hyphen position, exactly as the old raw-name compare required. */
        {
            size_t i;
            int underscore = 0;
            memcpy(keybuf, "HTTP_", 5);
            for (i = 0; i < nk; i++) {
                unsigned char ch = (unsigned char)p[i];
                if (ch >= 'a' && ch <= 'z') ch -= 32;
                else if (ch == '-') ch = '_';
                else if (ch == '_') underscore = 1;
                keybuf[5 + i] = (char)ch;
            }
            /* A wire name with an underscore folds to the same env key as
             * the hyphenated name, so "X_Forwarded_For" would land in
             * HTTP_X_FORWARDED_FOR beside - or instead of - the header a
             * proxy in front vetted. Proxies strip the hyphenated form and
             * pass the underscored one untouched, which is the whole
             * attack. Dropped, as nginx and Apache do. */
            if (underscore) continue;
        }
        /* Accept-Encoding is answered on this one pass and remembered as a
         * bit on the connection: hm_queue_response has no env to consult by
         * the time it must decide. Not an arm of the chain below - the
         * header is still stored as HTTP_ACCEPT_ENCODING like any other. */
        if (nk == 15 && p[6] == '-' && c->loop->compress
            && memEQ(keybuf + 5, "ACCEPT_ENCODING", 15))
            c->accepts_gzip = (unsigned char)hz_accepts_gzip(vp, nv);

        if (nk == 14 && p[7] == '-' && memEQ(keybuf + 5, "CONTENT_LENGTH", 14)) {
            hm_env_store(env, HMK_CONTENT_LENGTH, newSVpvn(vp, nv));
            have_cl = 1;
        } else if (nk == 12 && p[7] == '-'
                   && memEQ(keybuf + 5, "CONTENT_TYPE", 12)) {
            hm_env_store(env, HMK_CONTENT_TYPE, newSVpvn(vp, nv));
        } else if (nk == 17 && p[8] == '-'
                   && memEQ(keybuf + 5, "TRANSFER_ENCODING", 17)) {
            /* consumed by framing (already dechunked); not exposed to the
             * app, whose psgi.input is the decoded body with CONTENT_LENGTH */
        } else {
            {
                /* repeated header: join values (hm_hdr_join_sep) */
                SV *ksv = hm_hdrk_lookup(keybuf, nk + 5);
                if (ksv) {
                    /* a common header: the shared key SV carries its hash
                     * and its HEK, so no hashing and no HEK churn */
                    HE *he = hv_fetch_ent(env, ksv, 0, 0);
                    if (he) {
                        sv_catpvn(HeVAL(he), hm_hdr_join_sep(keybuf, nk + 5), 2);
                        sv_catpvn(HeVAL(he), vp, nv);
                    } else {
                        (void)hv_store_ent(env, ksv, newSVpvn(vp, nv), 0);
                    }
                } else {
                    SV **old = hv_fetch(env, keybuf, (I32)(nk + 5), 0);
                    if (old) {
                        sv_catpvn(*old, hm_hdr_join_sep(keybuf, nk + 5), 2);
                        sv_catpvn(*old, vp, nv);
                    } else {
                        hv_store(env, keybuf, (I32)(nk + 5), newSVpvn(vp, nv), 0);
                    }
                }
            }
            /* the name is already canonical; only the value keeps wire case */
            if (nk == 10 && memEQ(keybuf + 5, "CONNECTION", 10)) {
                if (nv >= 5 && hm_strncasecmp(vp, "close", 5) == 0) c->keepalive = 0;
                else if (nv >= 10 && hm_strncasecmp(vp, "keep-alive", 10) == 0) c->keepalive = 1;
            }
        }
    }
    /* dechunked request: no Content-Length header, but we know the decoded
     * length - present it so apps/middleware see the real body size */
    if (!have_cl && clen > 0)
        hm_env_store(env, HMK_CONTENT_LENGTH, newSViv((IV)clen));

    if (c && c->spill_fd >= 0) {
        /* The body was drained to a file as it arrived, so there is no body
         * pointer to copy from: the descriptor IS psgi.input. The handle owns
         * it from here, and the connection stops tracking it. */
        SV *in = hm_input_from_fd(aTHX_ c->spill_fd);
        c->spill_fd = -1;
        c->spill_got = 0;
        hm_env_store(env, HMK_PSGI_INPUT,
                     in ? in : hm_empty_input_sv(aTHX));
    }
    else if (clen > 0)
        hm_env_store(env, HMK_PSGI_INPUT, hm_new_input(aTHX_ body, (STRLEN)clen));
    else
        hm_env_store(env, HMK_PSGI_INPUT, hm_empty_input_sv(aTHX));
    hm_env_store(env, HMK_PSGIX_INPUT_BUFFERED, SvREFCNT_inc(hm_env_one));

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
    hm_warn_died(aTHX_ "application");
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
    hm_warn_died(aTHX_ "application");
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
        ssize_t n = hm_os_write_file(loop->log_fd, loop->log_buf + off,
                                     loop->log_len - off);
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
        loop->log_buf = (char *)hm_xrealloc(loop->log_buf, ncap);
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

/* The Date header (RFC 9110 6.6.1, IMF-fixdate), recomputed at most once a
 * second. Formatted by hand: strftime's %a and %b follow the locale, and
 * the wire wants English. 37 bytes, always: "Date: " + 29 + CRLF. */
#define HM_DATE_LEN 37
static const char *hm_date_header(hm_loop *loop) {
    if (loop->now != loop->date_sec) {
        static const char days[] = "SunMonTueWedThuFriSat";
        static const char mons[] = "JanFebMarAprMayJunJulAugSepOctNovDec";
        struct tm tm;
        time_t t = loop->now;
        char *d = loop->date_hdr;
        if (!hm_gmtime_r(&t, &tm)) return NULL;
        memcpy(d, "Date: ", 6); d += 6;
        memcpy(d, days + tm.tm_wday * 3, 3); d += 3;
        *d++ = ','; *d++ = ' ';
        *d++ = (char)('0' + tm.tm_mday / 10); *d++ = (char)('0' + tm.tm_mday % 10);
        *d++ = ' ';
        memcpy(d, mons + tm.tm_mon * 3, 3); d += 3;
        *d++ = ' ';
        {
            int y = tm.tm_year + 1900;
            *d++ = (char)('0' + y / 1000 % 10); *d++ = (char)('0' + y / 100 % 10);
            *d++ = (char)('0' + y / 10 % 10);   *d++ = (char)('0' + y % 10);
        }
        *d++ = ' ';
        *d++ = (char)('0' + tm.tm_hour / 10); *d++ = (char)('0' + tm.tm_hour % 10);
        *d++ = ':';
        *d++ = (char)('0' + tm.tm_min / 10);  *d++ = (char)('0' + tm.tm_min % 10);
        *d++ = ':';
        *d++ = (char)('0' + tm.tm_sec / 10);  *d++ = (char)('0' + tm.tm_sec % 10);
        memcpy(d, " GMT\r\n", 6);
        loop->date_sec = loop->now;
    }
    return loop->date_hdr;
}

/* Does an app-supplied header name or value carry a byte that would end
 * the field early? A CR, LF or NUL in either splits the response, so a
 * response carrying one is refused as a 500 rather than serialised: the
 * server is the last place the bug can be caught. */
static int hm_hdr_bytes_ok(const char *p, STRLEN n) {
    return !memchr(p, '\r', n) && !memchr(p, '\n', n) && !memchr(p, '\0', n);
}
static int hm_headers_ok(pTHX_ AV *hav) {
    SSize_t i, hn;
    if (!hav) return 1;
    hn = av_len(hav) + 1;
    for (i = 0; i < hn; i++) {
        SV **e = av_fetch(hav, i, 0);
        STRLEN l;
        const char *p;
        if (!e || !*e) continue;
        p = SvPV(*e, l);
        if (!hm_hdr_bytes_ok(p, l)) return 0;
    }
    return 1;
}

/* The same escape, for a value inside a JSON string. */
/* The length of a well-formed UTF-8 sequence starting at p (2..4), or 0 for
 * a byte that does not start one. Overlongs, surrogates and > U+10FFFF
 * are 0 too: the point is that what passes through is valid JSON text. */
static size_t hm_utf8_seq(const unsigned char *p, size_t n) {
    unsigned char c = p[0];
    size_t len, i;
    if (c >= 0xc2 && c <= 0xdf) len = 2;
    else if (c >= 0xe0 && c <= 0xef) len = 3;
    else if (c >= 0xf0 && c <= 0xf4) len = 4;
    else return 0;
    if (n < len) return 0;
    for (i = 1; i < len; i++) if ((p[i] & 0xc0) != 0x80) return 0;
    if (len == 3) {
        if (c == 0xe0 && p[1] < 0xa0) return 0;             /* overlong  */
        if (c == 0xed && p[1] >= 0xa0) return 0;            /* surrogate */
    } else if (len == 4) {
        if (c == 0xf0 && p[1] < 0x90) return 0;             /* overlong  */
        if (c == 0xf4 && p[1] >= 0x90) return 0;            /* > 10FFFF  */
    }
    return len;
}

static void hm_log_json_esc(hm_loop *loop, const char *p, size_t n) {
    static const char hex[] = "0123456789abcdef";
    size_t i, run = 0;
    if (!p) return;
    for (i = 0; i < n; i++) {
        unsigned char ch = (unsigned char)p[i];
        if (ch >= 0x80) {
            /* Valid UTF-8 passes; a stray high byte (a URI or User-Agent
             * that is not UTF-8) is escaped, so the line stays valid JSON
             * and a strict pipeline does not drop it - which was a way to
             * keep one's requests out of the log. */
            size_t sl = hm_utf8_seq((const unsigned char *)p + i, n - i);
            if (sl) { run += sl; i += sl - 1; continue; }
        }
        if (ch == '"' || ch == '\\' || ch < 0x20 || ch >= 0x80) {
            char e[6];
            if (run) { hm_log_raw(loop, p + i - run, run); run = 0; }
            if (ch == '"' || ch == '\\') {
                e[0] = '\\'; e[1] = (char)ch; hm_log_raw(loop, e, 2);
            } else {
                e[0] = '\\'; e[1] = 'u'; e[2] = '0'; e[3] = '0';
                e[4] = hex[ch >> 4]; e[5] = hex[ch & 0xf];
                hm_log_raw(loop, e, 6);
            }
        } else {
            run++;
        }
    }
    if (run) hm_log_raw(loop, p + n - run, run);
}

/* A value from $env, escaped the way this log's format wants. */
static void hm_log_esc(hm_loop *loop, const char *p, size_t n) {
    if (loop->log_json) hm_log_json_esc(loop, p, n);
    else                hm_log_quoted(loop, p, n);
}

/* Cached apache-style timestamp, recomputed at most once per second. */
static const char *hm_log_time(hm_loop *loop) {
    if (loop->now != loop->log_ts_sec) {
        struct tm tm;
        time_t t = loop->now;
        hm_localtime_r(&t, &tm);
        strftime(loop->log_ts, sizeof(loop->log_ts), "%d/%b/%Y:%H:%M:%S %z", &tm);
        loop->log_ts_sec = loop->now;
    }
    return loop->log_ts;
}

/* The ISO 8601 stamp the JSON format carries, cached the same way. */
static const char *hm_log_time_iso(hm_loop *loop) {
    if (loop->now != loop->log_iso_sec) {
        struct tm tm;
        time_t t = loop->now;
        hm_localtime_r(&t, &tm);
        strftime(loop->log_iso, sizeof(loop->log_iso), "%Y-%m-%dT%H:%M:%S%z", &tm);
        loop->log_iso_sec = loop->now;
    }
    return loop->log_iso;
}

/* ---- the access-log format compiler ----------------------------------------
 * Apache's directives, the ones a PSGI server can honour:
 *   %h %a REMOTE_ADDR   %l "-"           %u REMOTE_USER    %t [time]
 *   %r request line     %s %>s status    %b bytes or "-"   %B bytes or 0
 *   %D microseconds     %T seconds       %p SERVER_PORT    %m METHOD
 *   %U PATH_INFO        %q ?query        %H SERVER_PROTOCOL %v SERVER_NAME
 *   %P pid              %{Name}i request header   %{Name}e any $env key
 *   %% a literal percent sign
 * Returns 0, or -1 with the offending directive in err. Every value is
 * escaped (CLF or JSON), so no directive is a way to forge a line. */
#define HM_LOG_COMBINED "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\""

static void hm_logtok_push(hm_logtok **toks, int *n, int *cap, hm_logtok t) {
    if (*n == *cap) {
        *cap = *cap ? *cap * 2 : 16;
        *toks = (hm_logtok *)hm_xrealloc(*toks, (size_t)*cap * sizeof(hm_logtok));
    }
    (*toks)[(*n)++] = t;
}
static void hm_logtok_lit(hm_logtok **toks, int *n, int *cap, const char *p, size_t l) {
    hm_logtok t;
    if (!l) return;
    if (*n && (*toks)[*n - 1].kind == HM_LT_LIT) {   /* extend the last run */
        hm_logtok *last = &(*toks)[*n - 1];
        last->lit = (char *)hm_xrealloc(last->lit, last->litlen + l);
        memcpy(last->lit + last->litlen, p, l);
        last->litlen += l;
        return;
    }
    t.kind = HM_LT_LIT; t.lit = (char *)hm_xmalloc(l); memcpy(t.lit, p, l);
    t.litlen = l; t.key = NULL;
    hm_logtok_push(toks, n, cap, t);
}
static void hm_logtok_env(pTHX_ hm_logtok **toks, int *n, int *cap,
                          const char *key, size_t klen) {
    hm_logtok t;
    t.kind = HM_LT_ENV; t.lit = NULL; t.litlen = 0;
    t.key  = newSVpvn_share(key, (I32)klen, 0);    /* hash computed once */
    hm_logtok_push(toks, n, cap, t);
}
static void hm_logtok_kind(hm_logtok **toks, int *n, int *cap, int kind) {
    hm_logtok t;
    t.kind = kind; t.lit = NULL; t.litlen = 0; t.key = NULL;
    hm_logtok_push(toks, n, cap, t);
}

static int hm_logfmt_compile(pTHX_ const char *fmt, hm_logtok **out, int *nout,
                             int *wants_t0, char *err, size_t errlen) {
    hm_logtok *toks = NULL;
    int n = 0, cap = 0;
    const char *p = fmt, *lit = fmt;
    *wants_t0 = 0;
    while (*p) {
        char d;
        if (*p != '%') { p++; continue; }
        hm_logtok_lit(&toks, &n, &cap, lit, (size_t)(p - lit));
        p++;
        if (*p == '>') p++;                        /* %>s is %s */
        if (*p == '{') {
            const char *name = p + 1, *end = strchr(name, '}');
            char key[300];
            size_t nl, i;
            if (!end || (end[1] != 'i' && end[1] != 'e')) {
                snprintf(err, errlen, "%%{...}%c", end ? end[1] : '?');
                goto bad;
            }
            nl = (size_t)(end - name);
            if (nl == 0 || nl + 6 > sizeof(key)) { snprintf(err, errlen, "%%{%.*s}", (int)nl, name); goto bad; }
            if (end[1] == 'i') {
                memcpy(key, "HTTP_", 5);
                for (i = 0; i < nl; i++) {
                    unsigned char ch = (unsigned char)name[i];
                    if (ch >= 'a' && ch <= 'z') ch -= 32;
                    else if (ch == '-') ch = '_';
                    key[5 + i] = (char)ch;
                }
                hm_logtok_env(aTHX_ &toks, &n, &cap, key, nl + 5);
            } else {
                hm_logtok_env(aTHX_ &toks, &n, &cap, name, nl);
            }
            p = end + 2;
            lit = p;
            continue;
        }
        d = *p;
        switch (d) {
        case '%': hm_logtok_lit(&toks, &n, &cap, "%", 1); break;
        case 'h': case 'a': hm_logtok_env(aTHX_ &toks, &n, &cap, "REMOTE_ADDR", 11); break;
        case 'l': hm_logtok_kind(&toks, &n, &cap, HM_LT_DASH); break;
        case 'u': hm_logtok_env(aTHX_ &toks, &n, &cap, "REMOTE_USER", 11); break;
        case 't': hm_logtok_kind(&toks, &n, &cap, HM_LT_TIME); break;
        case 'r': hm_logtok_kind(&toks, &n, &cap, HM_LT_REQLINE); break;
        case 's': hm_logtok_kind(&toks, &n, &cap, HM_LT_STATUS); break;
        case 'b': hm_logtok_kind(&toks, &n, &cap, HM_LT_BYTES); break;
        case 'B': hm_logtok_kind(&toks, &n, &cap, HM_LT_BYTES0); break;
        case 'D': hm_logtok_kind(&toks, &n, &cap, HM_LT_DUR_US); *wants_t0 = 1; break;
        case 'T': hm_logtok_kind(&toks, &n, &cap, HM_LT_DUR_S);  *wants_t0 = 1; break;
        case 'p': hm_logtok_env(aTHX_ &toks, &n, &cap, "SERVER_PORT", 11); break;
        case 'm': hm_logtok_env(aTHX_ &toks, &n, &cap, "REQUEST_METHOD", 14); break;
        case 'U': hm_logtok_env(aTHX_ &toks, &n, &cap, "PATH_INFO", 9); break;
        case 'q': hm_logtok_kind(&toks, &n, &cap, HM_LT_QUERY); break;
        case 'H': hm_logtok_env(aTHX_ &toks, &n, &cap, "SERVER_PROTOCOL", 15); break;
        case 'v': hm_logtok_env(aTHX_ &toks, &n, &cap, "SERVER_NAME", 11); break;
        case 'P': hm_logtok_kind(&toks, &n, &cap, HM_LT_PID); break;
        default:
            snprintf(err, errlen, "%%%c", d ? d : '?');
            goto bad;
        }
        p++;
        lit = p;
    }
    hm_logtok_lit(&toks, &n, &cap, lit, (size_t)(p - lit));
    *out = toks; *nout = n;
    return 0;
bad:
    {
        int i;
        for (i = 0; i < n; i++) {
            if (toks[i].lit) free(toks[i].lit);
            if (toks[i].key) SvREFCNT_dec(toks[i].key);
        }
        if (toks) free(toks);
    }
    return -1;
}

/* The JSON shape: one object per line, fixed keys, numbers unquoted. */
static void hm_logfmt_json(pTHX_ hm_logtok **out, int *nout) {
    hm_logtok *toks = NULL;
    int n = 0, cap = 0;
#define HM_JL(s) hm_logtok_lit(&toks, &n, &cap, s, sizeof(s) - 1)
#define HM_JE(k) hm_logtok_env(aTHX_ &toks, &n, &cap, k, sizeof(k) - 1)
    HM_JL("{\"time\":\"");         hm_logtok_kind(&toks, &n, &cap, HM_LT_TIME_ISO);
    HM_JL("\",\"remote_addr\":\""); HM_JE("REMOTE_ADDR");
    HM_JL("\",\"user\":\"");       HM_JE("REMOTE_USER");
    HM_JL("\",\"method\":\"");     HM_JE("REQUEST_METHOD");
    HM_JL("\",\"uri\":\"");        HM_JE("REQUEST_URI");
    HM_JL("\",\"protocol\":\"");   HM_JE("SERVER_PROTOCOL");
    HM_JL("\",\"status\":");       hm_logtok_kind(&toks, &n, &cap, HM_LT_STATUS);
    HM_JL(",\"bytes\":");          hm_logtok_kind(&toks, &n, &cap, HM_LT_BYTES);
    HM_JL(",\"referer\":\"");      HM_JE("HTTP_REFERER");
    HM_JL("\",\"user_agent\":\""); HM_JE("HTTP_USER_AGENT");
    HM_JL("\",\"duration_us\":");  hm_logtok_kind(&toks, &n, &cap, HM_LT_DUR_US);
    HM_JL("}");
#undef HM_JL
#undef HM_JE
    *out = toks; *nout = n;
}

static const char *hm_env_str(pTHX_ HV *env, const char *key, I32 klen, STRLEN *lenp) {
    SV **s = hv_fetch(env, key, klen, 0);
    if (s && *s && SvOK(*s)) return SvPV(*s, *lenp);
    *lenp = 0;
    return NULL;
}

/* One $env value into the line, escaped; the "absent" spelling differs
 * between the two shapes ("-" in CLF, an empty string in JSON). */
static void hm_log_env_val(pTHX_ hm_loop *loop, HV *env, const hm_logtok *t) {
    HE *he = hv_fetch_ent(env, t->key, 0, 0);
    SV *v = he ? HeVAL(he) : NULL;
    if (v && SvOK(v)) {
        STRLEN n;
        const char *s = SvPV(v, n);
        if (n) { hm_log_esc(loop, s, n); return; }
    }
    if (!loop->log_json) hm_log_raw(loop, "-", 1);
}

/* Build one access-log line into the loop's log buffer by walking the
 * compiled format. The default compiles to Combined:
 *   host - user [time] "METHOD URI PROTO" status bytes "referer" "ua" */
static void hm_log_line(pTHX_ hm_loop *loop, SV *env_rv, int status, ssize_t blen) {
    HV *env;
    char num[32];
    int ln, i;

    if (!(env_rv && SvROK(env_rv) && SvTYPE(SvRV(env_rv)) == SVt_PVHV)) return;
    env = (HV *)SvRV(env_rv);

    for (i = 0; i < loop->nlogtok; i++) {
        const hm_logtok *t = &loop->logtok[i];
        switch (t->kind) {
        case HM_LT_LIT:  hm_log_raw(loop, t->lit, t->litlen); break;
        case HM_LT_ENV:  hm_log_env_val(aTHX_ loop, env, t); break;
        case HM_LT_DASH: hm_log_raw(loop, "-", 1); break;
        case HM_LT_STATUS:
            ln = (int)hm_itoa(num, (long)status); hm_log_raw(loop, num, (size_t)ln);
            break;
        case HM_LT_BYTES:
            if (blen >= 0) { ln = (int)hm_utoa(num, (unsigned long)blen);
                             hm_log_raw(loop, num, (size_t)ln); }
            else if (loop->log_json) hm_log_raw(loop, "null", 4);
            else                     hm_log_raw(loop, "-", 1);
            break;
        case HM_LT_BYTES0:
            ln = (int)hm_utoa(num, blen >= 0 ? (unsigned long)blen : 0UL);
            hm_log_raw(loop, num, (size_t)ln);
            break;
        case HM_LT_TIME: {
            const char *ts = hm_log_time(loop);
            hm_log_raw(loop, "[", 1); hm_log_raw(loop, ts, strlen(ts)); hm_log_raw(loop, "]", 1);
            break;
        }
        case HM_LT_TIME_ISO: {
            const char *ts = hm_log_time_iso(loop);
            hm_log_raw(loop, ts, strlen(ts));
            break;
        }
        case HM_LT_REQLINE: {
            const char *s; STRLEN n;
            s = hm_env_str(aTHX_ env, "REQUEST_METHOD", 14, &n);
            if (s && n) hm_log_esc(loop, s, n); else hm_log_raw(loop, "-", 1);
            hm_log_raw(loop, " ", 1);
            s = hm_env_str(aTHX_ env, "REQUEST_URI", 11, &n);
            if (s && n) hm_log_esc(loop, s, n); else hm_log_raw(loop, "-", 1);
            hm_log_raw(loop, " ", 1);
            s = hm_env_str(aTHX_ env, "SERVER_PROTOCOL", 15, &n);
            if (s && n) hm_log_esc(loop, s, n); else hm_log_raw(loop, "-", 1);
            break;
        }
        case HM_LT_QUERY: {
            const char *s; STRLEN n;
            s = hm_env_str(aTHX_ env, "QUERY_STRING", 12, &n);
            if (s && n) { hm_log_raw(loop, "?", 1); hm_log_esc(loop, s, n); }
            break;
        }
        case HM_LT_PID:
            ln = (int)hm_itoa(num, (long)hm_os_getpid()); hm_log_raw(loop, num, (size_t)ln);
            break;
        case HM_LT_DUR_US:
        case HM_LT_DUR_S: {
            SV **t0 = hv_fetch(env, "psgix.request_start", 19, 0);
            if (t0 && *t0 && SvOK(*t0)) {
                double el = (double)hm_now_ns() / 1e9 - SvNV(*t0);
                unsigned long v = el < 0 ? 0UL
                    : (unsigned long)(t->kind == HM_LT_DUR_US ? el * 1e6 : el);
                ln = (int)hm_utoa(num, v); hm_log_raw(loop, num, (size_t)ln);
            }
            else if (loop->log_json) hm_log_raw(loop, "null", 4);
            else                     hm_log_raw(loop, "-", 1);
            break;
        }
        }
    }
    hm_log_raw(loop, "\n", 1);

    if (loop->log_len >= HM_LOG_FLUSH_AT) hm_log_flush(loop);
}

/* Record one response. Fast path: format in C to the access-log fd. Else, if
 * a coderef was given, call $cb->($env, $status, $bytes); errors in the logger
 * are swallowed so they cannot take the loop down. */
static void hm_access_log(pTHX_ hm_loop *loop, SV *env_rv, int status, ssize_t blen) {
    dSP;
    if (loop->log_fd >= 0) { hm_log_line(aTHX_ loop, env_rv, status, blen); return; }
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
        c->wbuf = (char *)hm_xrealloc(c->wbuf, ncap);
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
    int status = 500, has_len = 0, has_conn = 0, has_date = 0;
    int gz_out = 0;
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
    if (s0 && *s0) status = (int)SvIV(*s0);
    if (s1 && *s1 && SvROK(*s1) && SvTYPE(SvRV(*s1)) == SVt_PVAV) hav = (AV *)SvRV(*s1);
    if (!hm_headers_ok(aTHX_ hav)) {
        hm_errlog("Hyperman: response header carries CR, LF or NUL; refused\n");
        hm_wb_put(c, HM_ERR500, sizeof(HM_ERR500) - 1);
        c->keepalive = 0;
        c->last_status = 500;
        c->last_blen = 21;
        return 0;
    }
    if (s2 && !*s2) s2 = NULL;

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
        /* filehandle or IO::Handle-like body: stream it when it lifts to
         * a byte-countable source, else slurp exactly as before */
        UV clv = 0;
        int cl_seen = hm_hav_clen(aTHX_ hav, &clv);
        if (!c->bsrc.kind && hm_bsrc_lift(aTHX_ *s2, &c->bsrc, cl_seen, clv))
            blen = (size_t)c->bsrc.remaining;
        else {
            fh_body = hm_slurp_body(aTHX_ *s2);
            { STRLEN l; (void)SvPV(fh_body, l); blen = l; }
        }
    }

    /* ---- compression decision, before a byte of the response is written --
     * Cheapest test first, and the whole block is skipped on a server that
     * did not ask for it. The rules, in order:
     *   1. enabled, and this request accepted gzip
     *   2. the response carries NO Content-Encoding. This one rule covers
     *      every hands-off case at once - a framework's precompressed file
     *      already says `gzip`, an opted-out route says `identity` (which
     *      we strip below), and anything else was encoded deliberately.
     *   3. a plain in-memory body, not a glob/reader/streamed source:
     *      compressing those would undo the 0.20 sendfile and drip paths.
     *   4. big enough to be worth a gzip member's header and trailer
     *   5. a status that carries an entity, and never 206 (a range
     *      describes offsets into the UNCOMPRESSED representation)
     *   6. a compressible media type, from an allowlist                   */
    if (loop->compress && c->accepts_gzip && bav && !c->bsrc.kind && !fh_body
        && blen >= loop->compress_min
        && (status == 200 || status == 203)) {
        const char *ct = NULL;
        STRLEN ctl = 0;
        int enc_seen = 0;
        SSize_t i, hn = hav ? av_len(hav) + 1 : 0;
        for (i = 0; i + 1 < hn; i += 2) {
            SV **k = av_fetch(hav, i, 0);
            STRLEN kl;
            const char *ks;
            if (!k || !*k) continue;
            ks = SvPV(*k, kl);
            /* A response that sets a cookie is one a BREACH-style attacker
             * would want compressed beside a reflected input; left alone,
             * as the no-transform contract for a Set-Cookie response. */
            if (kl == 10 && (ks[0] | 32) == 's'
                && hm_strncasecmp(ks, "Set-Cookie", 10) == 0) {
                enc_seen = 1;
                break;
            }
            if ((ks[0] | 32) != 'c') continue;
            if (kl == 16 && hm_strncasecmp(ks, "Content-Encoding", 16) == 0) {
                enc_seen = 1;
                break;
            }
            if (kl == 12 && hm_strncasecmp(ks, "Content-Type", 12) == 0) {
                SV **v = av_fetch(hav, i + 1, 0);
                if (v && *v) ct = SvPV(*v, ctl);
            }
        }
        if (!enc_seen && hz_type_ok(ct, ctl)) {
            /* one contiguous copy of the body, then one deflate */
            char *flat, *gz = NULL;
            size_t gzl = 0, off = 0;
            SSize_t j;
            Newx(flat, blen ? blen : 1, char);
            for (j = 0; j < bn; j++) {
                SV **e = av_fetch(bav, j, 0);
                if (e) {
                    STRLEN l;
                    const char *p = SvPV(*e, l);
                    /* Bounded by the length the first pass measured: an
                     * overloaded or tied element whose stringification grew
                     * between the two calls would otherwise run past flat. */
                    if (l > blen - off) l = blen - off;
                    if (l) { memcpy(flat + off, p, l); off += l; }
                }
            }
            if (hz_gzip(flat, off, loop->compress_level, &gz, &gzl)) {
                /* route it down the fh_body path: one SV, one copy into the
                 * write buffer. A response that just paid a deflate is not
                 * the one to spend the writev fast path on. */
                fh_body = newSVpvn(gz, gzl);
                Safefree(gz);
                bav = NULL; bn = 0;
                blen = gzl;
                c->last_blen = blen;
                gz_out = 1;
            }
            Safefree(flat);
        }
    }

    /* status line + headers */
    c->last_status = status;
    c->last_blen = blen;
    {
        size_t sll;
        const char *sl = hm_status_line(status, &sll, line);
        hm_wb_put(c, sl, sll);
    }
    if (hav) {
        SSize_t i, hn = av_len(hav) + 1;
        for (i = 0; i + 1 < hn; i += 2) {
            SV **k = av_fetch(hav, i, 0);
            SV **v = av_fetch(hav, i + 1, 0);
            STRLEN kl, vl;
            const char *ks, *vs;
            if (!k || !*k || !v || !*v) continue;   /* a hole in the array */
            ks = SvPV(*k, kl);
            vs = SvPV(*v, vl);
            if (kl == 4 && (ks[0] | 32) == 'd' && hm_strncasecmp(ks, "Date", 4) == 0)
                has_date = 1;
            /* both interesting names start with 'c', so one folded-byte test
             * skips the case-blind scans for every other header */
            if ((ks[0] | 32) == 'c') {
                if (kl == 14 && hm_strncasecmp(ks, "Content-Length", 14) == 0) {
                    has_len = 1;
                    /* the app's length describes the bytes we just replaced */
                    if (gz_out) { has_len = 0; continue; }
                }
                if (kl == 10 && hm_strncasecmp(ks, "Connection", 10) == 0)     has_conn = 1;
                /* `identity` is the documented way for anything above to opt
                 * a response out (see hm_compress.h). It has done its job by
                 * now; sending it on would be noise. */
                if (kl == 16 && vl == 8 && loop->compress
                    && hm_strncasecmp(ks, "Content-Encoding", 16) == 0
                    && hm_strncasecmp(vs, "identity", 8) == 0)
                    continue;
            }
            /* The layer that compressed must be the layer that fixes the
             * validator, or a cache serves these bytes to a client that
             * asked for none. nginx does the same; it is in the POD because
             * an app author will otherwise find it by debugging. */
            if (gz_out && kl == 4 && hm_strncasecmp(ks, "ETag", 4) == 0) {
                hm_wb_put(c, ks, kl);
                hm_wb_put(c, ": ", 2);
                if (vl > 1 && vs[vl - 1] == '"') {
                    hm_wb_put(c, vs, vl - 1);
                    hm_wb_put(c, "-gzip\"", 6);
                } else {
                    hm_wb_put(c, vs, vl);
                    hm_wb_put(c, "-gzip", 5);
                }
                hm_wb_put(c, "\r\n", 2);
                continue;
            }
            hm_wb_put(c, ks, kl);
            hm_wb_put(c, ": ", 2);
            hm_wb_put(c, vs, vl);
            hm_wb_put(c, "\r\n", 2);
        }
    }
    if (gz_out) {
        hm_wb_put(c, "Content-Encoding: gzip\r\n", 24);
        hm_wb_put(c, "Vary: Accept-Encoding\r\n", 23);
    }
    /* Alt-Svc: how a client finds out this origin also speaks HTTP/3. It is
     * advertised on the HTTP/1.1 and HTTP/2 responses and never on an h3 one,
     * where it would be telling a client what it is already using. The value
     * is precomputed per listener in hm_worker_listeners - never built from a
     * client-supplied Host, which would let a request choose the header. */
    if (c->lst && c->lst->altsvc) {
        hm_wb_put(c, "Alt-Svc: ", 9);
        hm_wb_put(c, c->lst->altsvc, strlen(c->lst->altsvc));
        hm_wb_put(c, "\r\n", 2);
    }
    /* 1xx/204/304 carry no entity: no Content-Length, no body (RFC 7230) */
    {
        int no_entity = (status < 200 || status == 204 || status == 304);
        if (no_entity) {
            if (fh_body) { SvREFCNT_dec(fh_body); fh_body = NULL; }
            if (c->bsrc.kind) hm_bsrc_release(aTHX_ &c->bsrc);
            bav = NULL; bn = 0; blen = 0;
        } else if (!has_len) {
            memcpy(line, "Content-Length: ", 16);
            ln = 16 + (int)hm_utoa(line + 16, (unsigned long)blen);
            line[ln++] = '\r'; line[ln++] = '\n';
            hm_wb_put(c, line, (size_t)ln);
        }
        /* HEAD: the headers of the GET, including its Content-Length, and
         * not one body byte - which the app, like most apps, produced
         * anyway. Sending it would be read as the start of the next
         * response on this connection. */
        if (!no_entity && c->is_head) {
            if (fh_body) { SvREFCNT_dec(fh_body); fh_body = NULL; }
            if (c->bsrc.kind) hm_bsrc_release(aTHX_ &c->bsrc);
            bav = NULL; bn = 0; blen = 0;
            c->last_blen = 0;
        }
    }
    if (!has_date) {
        const char *dh = hm_date_header(loop);
        if (dh) hm_wb_put(c, dh, HM_DATE_LEN);
    }
    if (!has_conn)
        hm_wb_put(c, c->keepalive ? "Connection: keep-alive\r\n" : "Connection: close\r\n",
                  c->keepalive ? 24 : 19);
    hm_wb_put(c, "\r\n", 2);

    loop->bytes_out += (c->wlen - hdr_start) + blen;

    /* fast path: nothing queued before this response -> writev header+body
     * straight from the response SVs, no body copy */
    if (hdr_start == 0 && c->woff == 0 && !c->writing && !fh_body
        && (!c->ssl || hm_ktls_tx(c))
        && !c->bsrc.kind && bav && bn >= 0 && bn < HM_IOV_MAX) {
        hm_iovec iov[HM_IOV_MAX];
        size_t total = c->wlen;
        int niov = 1;
        SSize_t i;
        ssize_t n;
        HM_IOV_SET(iov, 0, c->wbuf, c->wlen);
        for (i = 0; i < bn; i++) {
            SV **e = av_fetch(bav, i, 0);
            if (e) {
                STRLEN l; const char *p = SvPV(*e, l);
                if (l) {
                    HM_IOV_SET(iov, niov, p, l);
                    niov++;
                    total += l;
                }
            }
        }
        n = hm_os_writev(c->fd, iov, niov);
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
 * connection, -1 if it was closed. A streaming body source (c->bsrc) is
 * drained here: buffer empties, source refills it a chunk at a time - or
 * skips the buffer entirely via sendfile(2) on a plaintext socket - so a
 * large file response never holds more than one chunk in memory. */
static int hm_flush(pTHX_ hm_conn *c) {
    hm_loop *loop = c->loop;
    int src_done = 0;
    if (c->wlen == 0 && !c->bsrc.kind) {
        if (!c->keepalive && !c->awaiting) { hm_close(aTHX_ loop, c); return -1; }
        if (c->stream_done) {                    /* a streamed body ended
                                                  * with nothing to flush  */
            c->stream_done = 0;
            if (c->rlen > 0 || loop->completion) hm_again_push(loop, c);
        }
        return 0;
    }
    for (;;) {
        while (c->woff < c->wlen) {
            ssize_t n = hm_cwrite(c, c->wbuf + c->woff, c->wlen - c->woff);
            if (n > 0) {
                c->woff += (size_t)n;
            } else if (n < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
                /* arm a write watcher, unless the TLS engine is blocked
                 * wanting a read (the always-armed read watcher re-drives
                 * us then) */
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
        /* buffer drained; keep the capacity for the next round */
        c->wlen = c->woff = 0;
        if (!c->bsrc.kind) break;

#if defined(HM_HAVE_SENDFILE_LINUX) || defined(HM_HAVE_SENDFILE_FREEBSD) \
    || defined(HM_HAVE_SENDFILE_MACOS)
        /* file straight to a plaintext socket, no copy through userspace */
        if (c->bsrc.kind == 1 && (!c->ssl || hm_ktls_tx(c)) && !c->bsrc.nosf) {
            size_t want = c->bsrc.remaining < HM_SENDFILE_MAX
                              ? (size_t)c->bsrc.remaining : HM_SENDFILE_MAX;
            ssize_t sent = -1;
            int again = 0;
#if defined(HM_HAVE_SENDFILE_LINUX)
            off_t off = c->bsrc.off;
            sent = sendfile(c->fd, c->bsrc.fd, &off, want);
            again = (sent < 0 && (errno == EAGAIN || errno == EWOULDBLOCK));
#elif defined(HM_HAVE_SENDFILE_FREEBSD)
            off_t sbytes = 0;
            int r = sendfile(c->bsrc.fd, c->fd, c->bsrc.off, want,
                             NULL, &sbytes, 0);
            if (r == 0 || errno == EAGAIN || errno == EWOULDBLOCK) {
                sent = (ssize_t)sbytes;
                again = (r != 0);
            }
#elif defined(HM_HAVE_SENDFILE_MACOS)
            off_t len = (off_t)want;
            int r = sendfile(c->bsrc.fd, c->fd, c->bsrc.off, &len, NULL, 0);
            if (r == 0 || errno == EAGAIN || errno == EWOULDBLOCK) {
                sent = (ssize_t)len;
                again = (r != 0);
            }
#endif
            if (sent > 0) {
                c->bsrc.off += sent;
                c->bsrc.remaining -= (UV)sent;
            }
            if (c->bsrc.remaining == 0) {
                hm_bsrc_release(aTHX_ &c->bsrc);
                src_done = 1;
                break;
            }
            if (again || sent > 0) {
                if (again) {
                    if (!c->writing) {
                        loop->be->add_io(loop->be, c->fd, HM_EV_WRITE, 0);
                        c->writing = 1;
                    }
                    return 0;
                }
                continue;                    /* kernel took it all; try more */
            }
            /* sendfile refused this pairing (filesystem, socket state):
             * fall back to the read path for the rest of this body */
            c->bsrc.nosf = 1;
        }
#endif
        {
            ssize_t n = hm_bsrc_fill(aTHX_ c);
            if (n <= 0) {
                /* spent (0), or ended early (-1, keepalive already off) */
                hm_bsrc_release(aTHX_ &c->bsrc);
                src_done = 1;
                if (c->wlen) continue;       /* write what the fill added */
                break;
            }
        }
    }
    /* fully written; keep the buffer + capacity for the next response */
    c->wlen = c->woff = 0;
    if (c->writing) {
        loop->be->remove_io(loop->be, c->fd, HM_EV_WRITE);
        c->writing = 0;
    }
    /* A stream handle that was told to stop producing can start again. The
     * callback may write, and writing calls back in here, so re-read the
     * connection afterwards rather than deciding on what was true before. */
    if (hm_stream_paused_n) {
        int fd = c->fd;
        hm_stream_drained(aTHX_ c);
        if (loop->conns[fd] != c)      return -1;
        if (c->wlen || c->bsrc.kind)   return 0;
    }
    /* hm_process stopped on a full write buffer with requests still in the
     * read buffer: the client has now read, so serve the next of them. */
    if (c->backlogged) { c->backlogged = 0; hm_again_push(loop, c); }
    if (!c->keepalive && !c->awaiting) { hm_close(aTHX_ loop, c); return -1; }
    /* requests that pipelined in behind the stream were parked; pick them
     * up on the next loop turn */
    /* Pipelined requests behind the stream are picked up next turn - and in
     * completion mode the SAME push is what re-arms the read, which is why
     * an empty buffer is scheduled too. Without that a connection that
     * streamed a body would never be read from again. */
    if (c->stream_done) { c->stream_done = 0; src_done = 1; }
    if (src_done && (c->rlen > 0 || loop->completion)) hm_again_push(loop, c);
    return 0;
}

/* ---- async delivery (Future + streaming) --------------------------------- */

/* Deliver an async response to a parked connection. No-op if the
 * connection is gone or the fd was reused. */
static void hm_deliver(pTHX_ int fd, UV id, SV *resp) {
    hm_loop *loop = hm_cur_loop;
    hm_conn *c = (loop && fd >= 0 && fd < HM_MAXFD) ? loop->conns[fd] : NULL;
    if (!(c && c->id == id)) return;
    /* Only a parked connection is owed a response. A responder called a
     * second time, or the 500 for a streaming handler that died AFTER it
     * had already answered, would otherwise be serialised onto a live
     * keep-alive connection as the reply to its next request. */
    if (!c->awaiting) return;
    /* A streamed response is open on this connection: a stream handle
     * opened after the handler parked (the documented pattern), whose
     * Future has now resolved with a value that is not a response, or a
     * second response for one request. Serialising it here put a status
     * line inside a chunked body. The handle owns the response; this one
     * is dropped. (A handler that DIED with a writer alive is the other
     * case, and hm_delayed closes the connection for that.) */
    if (c->stream_open) {
        if (c->resp_f) { SvREFCNT_dec(c->resp_f); c->resp_f = NULL; }
        return;
    }
    /* detached from inside a Future continuation (async work before an
     * upgrade): the app owns the socket, so drop the response it resolved
     * with and forget the connection */
    if (c->detached) {
        c->awaiting = 0;
        if (c->env_sv) {
            hm_access_log(aTHX_ loop, c->env_sv, 101, -1);
            SvREFCNT_dec(c->env_sv);
            c->env_sv = NULL;
        }
        hm_conn_release(aTHX_ loop, c);
        return;
    }
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
        /* Parked connections have no read outstanding - the completion
         * handler skipped arming one while the response was being made - so
         * the re-arm is scheduled here, for the top of the next turn. */
        if (loop->conns[fd] == c && !c->awaiting && !c->bsrc.kind)
            hm_again_push(loop, c);
        return;
    }
    if (hm_queue_response(aTHX_ c, resp) == 0
        && loop->conns[fd] == c
        && hm_flush(aTHX_ c) == 0
        && loop->conns[fd] == c) {
        hm_process(aTHX_ c);
        if (loop->conns[fd] == c) hm_flush(aTHX_ c);
    }
    if (loop->conns[fd] == c && !c->awaiting && !c->bsrc.kind)
        hm_again_push(loop, c);
}

/* How a streamed HTTP/1.1 body is framed, decided once in hm_start_stream:
 *   EOF     - Connection: close, the body ends when the connection does. The
 *             only framing there was before 0.57, and still the one for
 *             HTTP/1.0, a request that asked to close, a 101 tunnel, an app
 *             that wrote its own Transfer-Encoding, and a draining server.
 *   CHUNKED - Transfer-Encoding: chunked, keep-alive kept. Every write is one
 *             chunk, close sends the last one, and the pipeline resumes.
 *   LENGTH  - the app gave Content-Length: bytes are counted; an overrun or
 *             a short body breaks the framing, so the connection closes.
 *   NOBODY  - 1xx, 204, 304: headers only, keep-alive kept. */
#define HM_SM_EOF     0
#define HM_SM_CHUNKED 1
#define HM_SM_LENGTH  2
#define HM_SM_NOBODY  3

/* Send status+headers for a streaming response; body follows via
 * hm_stream_write/hm_stream_close. */
/* 1 when the response was begun; 0 when it was refused because this
 * connection is not parked on a response, or one has already begun; -1
 * when the headers were refused (a 500 went out instead). Only a PARKED
 * connection with no response begun: a second responder call, or a stale
 * responder kept from an earlier request on this keep-alive connection,
 * otherwise wrote a status line and headers into the body being streamed,
 * or into the next request's response. */
static int hm_start_stream(pTHX_ int fd, UV id, int status, SV *headers) {
    hm_loop *loop = hm_cur_loop;
    hm_conn *c = (loop && fd >= 0 && fd < HM_MAXFD) ? loop->conns[fd] : NULL;
    char line[64];
    AV *hav = NULL;
    int has_date = 0, has_conn = 0, conn_close = 0, has_te = 0, has_len = 0;
    UV clen = 0;
    if (!(c && c->id == id)) return 0;
    if (!c->awaiting || c->stream_open) return 0;
    c->stream_open = 1;
    c->stream_serial++;
    c->stream_mode = HM_SM_EOF;
    c->stream_left = 0;
    c->stream_done = 0;
    if (c->env_sv) {
        hm_access_log(aTHX_ loop, c->env_sv, status, -1);
        SvREFCNT_dec(c->env_sv);
        c->env_sv = NULL;
    }
    if (headers && SvROK(headers) && SvTYPE(SvRV(headers)) == SVt_PVAV)
        hav = (AV *)SvRV(headers);
    if (!hm_headers_ok(aTHX_ hav)) {
        hm_errlog("Hyperman: response header carries CR, LF or NUL; refused\n");
        hm_wb_put(c, HM_ERR500, sizeof(HM_ERR500) - 1);
        c->last_status = 500;
        c->last_blen = 21;
        c->awaiting = 0;          /* nothing more is owed on this connection */
        c->stream_open = 0;
        hm_flush(aTHX_ c);
        return -1;
    }
    {
        size_t sll;
        const char *sl = hm_status_line(status, &sll, line);
        hm_wb_put(c, sl, sll);
    }
    if (hav) {
        SSize_t i, hn = av_len(hav) + 1;
        for (i = 0; i + 1 < hn; i += 2) {
            SV **k = av_fetch(hav, i, 0);
            SV **v = av_fetch(hav, i + 1, 0);
            STRLEN kl, vl;
            const char *ks, *vs;
            if (!k || !*k || !v || !*v) continue;
            ks = SvPV(*k, kl);
            vs = SvPV(*v, vl);
            if (kl == 4 && (ks[0] | 32) == 'd' && hm_strncasecmp(ks, "Date", 4) == 0)
                has_date = 1;
            else if (kl == 10 && (ks[0] | 32) == 'c'
                     && hm_strncasecmp(ks, "Connection", 10) == 0) {
                has_conn = 1;
                if (hm_ci_contains(vs, vl, "close")) conn_close = 1;
            }
            else if (kl == 14 && (ks[0] | 32) == 'c'
                     && hm_strncasecmp(ks, "Content-Length", 14) == 0)
                has_len = 1;
            else if (kl == 17 && (ks[0] | 32) == 't'
                     && hm_strncasecmp(ks, "Transfer-Encoding", 17) == 0)
                has_te = 1;
            hm_wb_put(c, ks, kl);
            hm_wb_put(c, ": ", 2);
            hm_wb_put(c, vs, vl);
            hm_wb_put(c, "\r\n", 2);
        }
    }
    if (!has_date) {
        const char *dh = hm_date_header(loop);
        if (dh) hm_wb_put(c, dh, HM_DATE_LEN);
    }
    if (has_len && !hm_hav_clen(aTHX_ hav, &clen)) has_len = 0;  /* unparseable */
    {
        int no_entity = (status < 200 || status == 204 || status == 304);
        if (status == 101 || loop->stopping || !c->req_11 || !c->keepalive
            || conn_close || has_te) {
            c->stream_mode = HM_SM_EOF;
            c->keepalive = 0;
        } else if (no_entity) {
            c->stream_mode = HM_SM_NOBODY;
        } else if (has_len) {
            c->stream_mode = HM_SM_LENGTH;
            c->stream_left = clen;
        } else {
            c->stream_mode = HM_SM_CHUNKED;
            hm_wb_put(c, "Transfer-Encoding: chunked\r\n", 28);
        }
    }
    /* A 101 is an upgrade: the caller's own Upgrade and Connection headers
     * are the response, and "close" would contradict them. The connection
     * still ends when the handle closes - keepalive is off above. */
    if (status == 101)                    hm_wb_put(c, "\r\n", 2);
    else if (c->stream_mode == HM_SM_EOF) hm_wb_put(c, "Connection: close\r\n\r\n", 21);
    else {
        if (!has_conn) hm_wb_put(c, "Connection: keep-alive\r\n", 24);
        hm_wb_put(c, "\r\n", 2);
    }
    hm_flush(aTHX_ c);
    return 1;
}

/* `serial` names the streamed response a Writer was handed out for; 0 skips
 * the check (the ABI stream handle has a registry of its own for that). A
 * writer kept past its response, or closed twice, must not touch the
 * response that followed on the same keep-alive connection. */
/* Queue body bytes on a streamed HTTP/1.1 response, framed as the mode says.
 * Shared by the Writer (hm_stream_write) and the ABI stream handle
 * (hm_stream.h), so the two cannot disagree about the framing. Returns the
 * octets queued: 0 when nothing was (HEAD, no body, past the end), and the
 * caller then has nothing to flush. */
static STRLEN hm_stream_body_put(pTHX_ hm_conn *c, const char *p, STRLEN l) {
    if (!c->awaiting && !c->tunnel) return 0;   /* the body has ended     */
    if (c->is_head && !c->tunnel) return 0;     /* HEAD: headers only     */
    if (c->stream_mode == HM_SM_NOBODY) return 0;
    if (c->stream_mode == HM_SM_LENGTH) {
        if (l > c->stream_left) {                /* overrun: the framing is
                                                  * broken, end the conn  */
            l = (STRLEN)c->stream_left;
            c->keepalive = 0;
        }
        c->stream_left -= l;
    }
    if (!l) return 0;                            /* a zero chunk ends a body */
    if (c->stream_mode == HM_SM_CHUNKED) {
        char sz[24];
        int n = snprintf(sz, sizeof(sz), "%" UVxf "\r\n", (UV)l);
        hm_wb_put(c, sz, (size_t)n);
        hm_wb_put(c, p, l);
        hm_wb_put(c, "\r\n", 2);
    } else {
        hm_wb_put(c, p, l);
    }
    c->loop->bytes_out += l;
    return l;
}

/* 1: queued, and the connection holds less than HM_WB_HIWAT unwritten.
 * 0: queued, but the connection is holding more than that - the producer
 *    should wait for a later write to answer 1 again before writing more
 *    (the Perl Writer's ->write hands this back; before 0.62 it returned
 *    nothing, and a producer feeding a slow reader grew the buffer without
 *    bound).
 * -1: not written: the writer is stale (closed, or from an earlier
 *    request on this connection). */
static int hm_stream_write(pTHX_ int fd, UV id, UV serial, SV *data) {
    hm_loop *loop = hm_cur_loop;
    hm_conn *c = (loop && fd >= 0 && fd < HM_MAXFD) ? loop->conns[fd] : NULL;
    STRLEN l;
    const char *p;
    if (!(c && c->id == id)) return -1;
    if (serial && c->stream_serial != serial) return -1;
    if (!c->awaiting && !c->tunnel) return -1;
    p = SvPV(data, l);
    if (hm_stream_body_put(aTHX_ c, p, l)) hm_flush(aTHX_ c);
    if (loop->conns[fd] != c) return -1;
    return (c->wlen - c->woff) > HM_WB_HIWAT ? 0 : 1;
}

static void hm_stream_close(pTHX_ int fd, UV id, UV serial) {
    hm_loop *loop = hm_cur_loop;
    hm_conn *c = (loop && fd >= 0 && fd < HM_MAXFD) ? loop->conns[fd] : NULL;
    if (!(c && c->id == id)) return;
    if (serial && c->stream_serial != serial) return;
    if (!c->awaiting) return;                    /* closed already         */
    c->stream_open = 0;
    if (c->stream_mode == HM_SM_CHUNKED && !c->is_head)
        hm_wb_put(c, "0\r\n\r\n", 5);
    else if (c->stream_mode == HM_SM_LENGTH && c->stream_left && !c->is_head)
        c->keepalive = 0;                        /* short body: cannot keep
                                                  * the connection in frame */
    c->stream_mode = HM_SM_EOF;
    c->stream_left = 0;
    c->awaiting = 0;
    if (c->keepalive) c->stream_done = 1;        /* hm_flush: serve the
                                                  * pipeline when drained  */
    hm_flush(aTHX_ c);   /* closes when drained if keepalive is off */
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
        hm_errlog("Hyperman: async response failed: %s%s",
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
        hm_conn *c = (hm_cur_loop && fd >= 0 && fd < HM_MAXFD)
                   ? hm_cur_loop->conns[fd] : NULL;
        if (c && c->id == id && c->stream_open)
            croak("Hyperman responder: a response has already been started "
                  "on this connection");
        hm_deliver(aTHX_ fd, id, r);
        XSRETURN_EMPTY;
    }
    if (n == 2) {
        SV **s0 = av_fetch(rav, 0, 0);
        SV **s1 = av_fetch(rav, 1, 0);
        AV *w = newAV();
        SV *wrv;
        int began = hm_start_stream(aTHX_ fd, id, s0 ? (int)SvIV(*s0) : 200,
                                    s1 ? *s1 : NULL);
        if (began == 0) {
            SvREFCNT_dec((SV *)w);
            croak("Hyperman responder: a response has already been started "
                  "on this connection");
        }
        if (began < 0) {
            SvREFCNT_dec((SV *)w);
            croak("Hyperman responder: a response header carries CR, LF or NUL");
        }
        av_push(w, newSViv(fd));
        av_push(w, newSVuv(id));
        /* the serial of the response just begun, read back from the conn
         * (hm_start_stream is a no-op on a stale ticket, so 0 then) */
        {
            hm_conn *c = (hm_cur_loop && fd >= 0 && fd < HM_MAXFD)
                       ? hm_cur_loop->conns[fd] : NULL;
            av_push(w, newSVuv(c && c->id == id ? c->stream_serial : 0));
        }
        av_push(w, newSVpvs("h1"));
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
    if (SvTRUE(ERRSV)) {
        hm_loop *loop = hm_cur_loop;
        hm_conn *c = (loop && fd >= 0 && fd < HM_MAXFD) ? loop->conns[fd] : NULL;
        if (c && c->id == id && c->awaiting && c->stream_open) {
            /* It answered through the responder, kept the writer alive, and
             * died with the body part written. A 500 cannot follow a status
             * line already sent, and ending the body as if complete would
             * hand the client a cut body it may cache: the connection ends
             * once what was written has drained, WITHOUT the terminating
             * chunk. (A writer that was a lexical has already been
             * destroyed by the unwind and ended the body itself, the
             * promise a dropped writer keeps.) */
            hm_warn_died(aTHX_ "streaming handler");
            c->stream_open = 0;
            c->stream_mode = HM_SM_EOF;
            c->stream_done = 0;
            c->keepalive = 0;
            c->awaiting = 0;
            if (c->resp_f) { SvREFCNT_dec(c->resp_f); c->resp_f = NULL; }
            hm_flush(aTHX_ c);
        } else {
            hm_deliver(aTHX_ fd, id, hm_500_resp(aTHX_ "Internal Server Error"));
        }
    }
    FREETMPS; LEAVE;
    SvREFCNT_dec(responder);
}

/* ---- HTTP/2 (h2c via nghttp2), reusing the helpers above ----------------- */

#include "hm_http2.h"

/* ---- ABI v6 stream handles, over both halves above ---------------------- */

#include "hm_stream.h"

/* ---- HTTP/3 over QUIC: the transport, then the semantics ---------------- */

#include "hm_quic.h"
#include "hm_http3.h"

/* ---- request processing -------------------------------------------------- */

static void hm_again_push(hm_loop *loop, hm_conn *c) {
    if (loop->again_n == loop->again_cap) {
        loop->again_cap = loop->again_cap ? loop->again_cap * 2 : 64;
        loop->again = (hm_again *)hm_xrealloc(loop->again,
                          loop->again_cap * sizeof(hm_again));
    }
    loop->again[loop->again_n].fd = c->fd;
    loop->again[loop->again_n].id = c->id;
    loop->again_n++;
    c->again_queued = 1;
}

/* Built-in https redirect: synthesize a 301 to the same host and target on
 * the https port, so a plain :80 listener can bounce browsers to :443 without
 * ever touching the app. Host comes from the request (its :port is stripped);
 * the target port is omitted when it is the standard 443. */
static SV *hm_redirect_response(pTHX_ HV *env, int https_port) {
    const char *host, *uri;
    STRLEN hlen, ulen;
    SV *loc;
    AV *rav, *hav, *bav;
    host = hm_env_str(aTHX_ env, "HTTP_HOST", 9, &hlen);
    uri  = hm_env_str(aTHX_ env, "REQUEST_URI", 11, &ulen);
    if (!uri) { uri = "/"; ulen = 1; }
    loc = newSVpvs("https://");
    /* Host and request-target are reflected into a response header, so stop at
     * the first control or space byte: a header value is only \r-delimited, so
     * a bare LF could otherwise smuggle a CRLF and inject/split the response.
     * A valid host[:port] / request-target contains no CTL or SP anyway. */
    if (host) {
        STRLEN i = 0;                                    /* host, up to :port */
        if (hlen && host[0] == '[') {                    /* [v6]:port: whole */
            while (i < hlen && (unsigned char)host[i] > ' ' && host[i] != ']') i++;
            if (i < hlen && host[i] == ']') i++;
        } else {
            while (i < hlen && (unsigned char)host[i] > ' ' && host[i] != ':') i++;
        }
        sv_catpvn(loc, host, i);
    }
    if (https_port != 443) sv_catpvf(loc, ":%d", https_port);
    {
        STRLEN i = 0;                                    /* request-target */
        while (i < ulen && (unsigned char)uri[i] > ' ') i++;
        sv_catpvn(loc, uri, i);
    }

    hav = newAV();
    av_push(hav, newSVpvs("Location"));       av_push(hav, loc);
    av_push(hav, newSVpvs("Content-Length")); av_push(hav, newSVpvs("0"));
    bav = newAV();
    rav = newAV();
    av_push(rav, newSViv(301));
    av_push(rav, newRV_noinc((SV *)hav));
    av_push(rav, newRV_noinc((SV *)bav));
    return newRV_noinc((SV *)rav);
}

/* Process complete requests buffered in c->rbuf, capped per wakeup so one
 * pipelined connection can't starve the others (fairness). */
static void hm_process(pTHX_ hm_conn *c) {
    hm_loop *loop = c->loop;
    int served = 0;

    /* HTTP/2: once a connection is in h2 mode, all bytes go to nghttp2.
     * On a fresh connection with http2 enabled, sniff the h2 preface. */
    if (c->h2) { hm_h2_input(aTHX_ c); return; }
    if (c->lst && c->lst->http2 && c->nreqs == 0 && c->rlen > 0) {
        if (hm_h2_detect(aTHX_ c) != 0) return;   /* started, or need more */
    }

    for (;;) {
        if (c->awaiting) break;   /* parked; resumes via hm_deliver */
        if (c->bsrc.kind) break;  /* a body is still streaming out; the
                                     flush that finishes it re-queues us */
        /* Responses the client has not read yet. A pipeline that never
         * reads would otherwise have every request in the read buffer
         * answered into a write buffer that only grows: hold the rest until
         * the drain re-queues this connection (hm_flush, backlogged). */
        if (c->wlen - c->woff > HM_WB_HIWAT) { c->backlogged = 1; break; }

        /* RFC 9112 2.2: at least one empty line before the request line is
         * ignored. Stripped here so the request line is the first line and
         * not an empty one with the real request line read as a header. */
        if (c->rlen >= 2 && c->rbuf[0] == '\r' && c->rbuf[1] == '\n') {
            size_t k = 0;
            while (k + 1 < c->rlen && c->rbuf[k] == '\r' && c->rbuf[k + 1] == '\n') k += 2;
            memmove(c->rbuf, c->rbuf + k, c->rlen - k);
            c->rlen -= k;
            if (c->rlen == 0) break;
        }

        char *end = (char *)hm_memmem(c->rbuf, c->rlen, "\r\n\r\n", 4);
        if (!end) break;

        if (served >= loop->max_pipeline) {     /* yield to other conns */
            hm_again_push(loop, c);
            break;
        }

        size_t headlen = (size_t)(end - c->rbuf);
        size_t bodystart = headlen + 4;

        /* one pass: framing decision + header-line index for the env build */
        hm_hline hidx_stack[HM_HIDX_STACK];
        const hm_hline *hidx = hidx_stack;
        int nhl = 0;
        long clen = 0;
        int frame = hm_parse_index(c->rbuf, headlen, &clen,
                                   hidx_stack, HM_HIDX_STACK, &nhl);
        if (frame == -2) {          /* > HM_HIDX_STACK header lines: rescan
                                       into the loop's growable index */
            if (nhl > loop->hidx_cap) {
                loop->hidx = (hm_hline *)hm_xrealloc(loop->hidx,
                                 (size_t)nhl * sizeof(hm_hline));
                loop->hidx_cap = nhl;
            }
            frame = hm_parse_index(c->rbuf, headlen, &clen,
                                   loop->hidx, loop->hidx_cap, &nhl);
            hidx = loop->hidx;
        }
        if (frame) {                            /* smuggling/framing: reject + close */
            if (frame == 501) {
                static const char e501[] =
                    "HTTP/1.1 501 Not Implemented\r\nContent-Length: 0\r\n"
                    "Connection: close\r\n\r\n";
                hm_wb_put(c, e501, sizeof(e501) - 1);
            } else {
                static const char e400[] =
                    "HTTP/1.1 400 Bad Request\r\nContent-Length: 0\r\n"
                    "Connection: close\r\n\r\n";
                hm_wb_put(c, e400, sizeof(e400) - 1);
            }
            c->keepalive = 0;
            break;
        }

        /* An expectation this server cannot meet is refused now, on the
         * headers alone - which is the answer the client asked for. */
        int expect = hm_expectation(c->rbuf, headlen);
        if (expect == HM_EXPECT_OTHER) {
            static const char e417[] =
                "HTTP/1.1 417 Expectation Failed\r\nContent-Length: 0\r\n"
                "Connection: close\r\n\r\n";
            hm_wb_put(c, e417, sizeof(e417) - 1);
            c->keepalive = 0;
            c->last_status = 417;
            break;
        }

        size_t body_consumed;   /* wire octets after the headers this request uses */
        if (clen < 0) {         /* chunked: validate, then decode in place */
            size_t enc = 0, dec = 0;
            int r = hm_chunked_scan_from(c->rbuf + bodystart, c->rlen - bodystart,
                                         &enc, &dec, loop->max_read,
                                         &c->chunk_pos, &c->chunk_dec);
            if (r == HM_CHUNKED_TOOBIG) {   /* well framed, just too large */
                static const char e413[] =
                    "HTTP/1.1 413 Payload Too Large\r\nContent-Length: 0\r\n"
                    "Connection: close\r\n\r\n";
                hm_wb_put(c, e413, sizeof(e413) - 1);
                c->keepalive = 0;
                c->last_status = 413;
                break;
            }
            if (r < 0) {                                 /* malformed chunked */
                static const char e400[] =
                    "HTTP/1.1 400 Bad Request\r\nContent-Length: 0\r\n"
                    "Connection: close\r\n\r\n";
                hm_wb_put(c, e400, sizeof(e400) - 1);
                c->keepalive = 0;
                break;
            }
            if (r == 0) {                                /* need more bytes */
                c->body_phase = 1;
                c->body_t0 = loop->now;
                c->body_rx = 0;
                if (c->rlen - bodystart >= loop->max_read) {   /* too big to fit */
                    static const char e413[] =
                        "HTTP/1.1 413 Payload Too Large\r\nContent-Length: 0\r\n"
                        "Connection: close\r\n\r\n";
                    hm_wb_put(c, e413, sizeof(e413) - 1);
                    c->keepalive = 0;
                }
                else hm_send_continue(c, expect);
                break;
            }
            hm_chunked_compact(c->rbuf + bodystart);     /* -> dec octets @ bodystart */
            clen = (long)dec;
            body_consumed = enc;
        } else {
            if (bodystart + (size_t)clen > loop->max_read) {   /* can never fit */
                static const char e413[] =
                    "HTTP/1.1 413 Payload Too Large\r\nContent-Length: 0\r\n"
                    "Connection: close\r\n\r\n";
                hm_wb_put(c, e413, sizeof(e413) - 1);
                c->keepalive = 0;
                break;
            }
            /* A large body is drained to a temp file as it arrives rather
             * than accumulated here. rbuf keeps the headers and whatever
             * arrived after the body; the file gets the body.
             *
             * Identity framing only. A chunked body has no Content-Length to
             * divert on and its decoder wants the octets contiguous, so those
             * still accumulate - documented rather than hidden.
             *
             * Nothing about the loop changes: this still `break`s to wait for
             * more, and is re-driven when the socket is readable again. What
             * changes is that the waiting no longer costs the body. */
            if ((long)clen > HM_SPILL_BODY) {
                size_t have = c->rlen - bodystart;
                if (c->spill_fd < 0 && (c->spill_fd = hm_body_tmpfile()) < 0)
                    goto hm_no_spill;           /* cannot: behave as before */
                if (have) {
                    size_t want = have;
                    size_t room = (size_t)(clen - c->spill_got);
                    if (want > room) want = room;   /* the rest is the next
                                                     * request, not this body */
                    if (want) {
                        ssize_t w = write(c->spill_fd, c->rbuf + bodystart, want);
                        if (w <= 0) { hm_close(aTHX_ loop, c); return; }
                        c->spill_got += w;
                        memmove(c->rbuf + bodystart, c->rbuf + bodystart + w,
                                c->rlen - bodystart - w);
                        c->rlen -= (size_t)w;
                    }
                }
                if (c->spill_got < (long)clen) {           /* await more */
                    c->body_phase = 1;
                    c->body_t0 = loop->now;
                    c->body_rx = 0;
                    hm_send_continue(c, expect);
                    break;
                }
                if (lseek(c->spill_fd, 0, SEEK_SET) < 0) {
                    hm_close(aTHX_ loop, c); return;
                }
                body_consumed = 0;              /* none of it is in rbuf */
                goto hm_have_body;
            }
        hm_no_spill:
            if (c->rlen - bodystart < (size_t)clen) {        /* await full body */
                c->body_phase = 1;
                c->body_t0 = loop->now;
                c->body_rx = 0;
                hm_send_continue(c, expect);
                break;
            }
            body_consumed = (size_t)clen;
        hm_have_body: ;
        }

#ifdef HM_HAVE_NGHTTP2
        /* HTTP/1.1 Upgrade: h2c (cleartext, first request only). h2c-over-TLS
         * is forbidden by RFC 7540; the TLS path uses ALPN. */
        if (c->lst && c->lst->http2 && !c->ssl && !c->h2 && c->nreqs == 0) {
            size_t ul = 0, sl = 0;
            const char *up = hm_find_header(c->rbuf, headlen, "upgrade", 7, &ul);
            const char *se = hm_find_header(c->rbuf, headlen, "http2-settings", 14, &sl);
            if (up && se && hm_ci_contains(up, ul, "h2c")) {
                static const char resp101[] =
                    "HTTP/1.1 101 Switching Protocols\r\n"
                    "Connection: Upgrade\r\nUpgrade: h2c\r\n\r\n";
                int is_head = (headlen >= 5 && hm_strncasecmp(c->rbuf, "HEAD ", 5) == 0);
                HV *env = hm_build_env(aTHX_ c->rbuf, headlen,
                                       c->rbuf + bodystart, clen, c, hidx, nhl);
                (void)hv_stores(env, "SERVER_PROTOCOL", newSVpvs("HTTP/2"));
                hm_wb_put(c, resp101, sizeof(resp101) - 1);
                {
                    size_t consumed = bodystart + body_consumed;
                    memmove(c->rbuf, c->rbuf + consumed, c->rlen - consumed);
                    c->rlen -= consumed;
                    c->nreqs++;
                    loop->requests++;
                    /* The request is consumed: the header and body clocks
                     * stop here, as they do for an ordinary request below.
                     * An h2 session never passes that point again, so one
                     * whose upgrade arrived in two reads was closed by the
                     * sweep as a slow request header_timeout later. */
                    c->req_start = 0;
                    c->body_phase = 0;
                    c->chunk_pos = c->chunk_dec = 0;
                }
                {
                    int rc;
                    c->in_app = 1;      /* the upgrade dispatches stream 1 */
                    rc = hm_h2_start_upgrade(aTHX_ c, se, sl, env, is_head);
                    c->in_app = 0;
                    if (rc < 0 || c->close_deferred) {
                        c->close_deferred = 0;
                        hm_close(aTHX_ loop, c);
                        return;
                    }
                    hm_read_resume(loop, c);
                }
                hm_h2_input(aTHX_ c);   /* client's h2 preface + frames, + flush */
                return;
            }
        }
#endif

        HV *env = hm_build_env(aTHX_ c->rbuf, headlen, c->rbuf + bodystart,
                               clen, c, hidx, nhl);
        SV *env_rv = NULL;
        SV *resp;
        c->in_app = 1;          /* see hm_close: a close meanwhile is deferred */
        if (c->lst && c->lst->redirect_https) {   /* built-in :80 -> :443 bounce */
            resp = hm_redirect_response(aTHX_ env, c->lst->redirect_https);
            if (hm_logging(loop)) env_rv = newRV_noinc((SV *)env);
            else                  SvREFCNT_dec((SV *)env);
        } else if (hm_logging(loop)) {      /* env survives for access_log */
            env_rv = newRV_noinc((SV *)env);
            resp = hm_call_app(aTHX_ loop, env_rv);
        } else {
            resp = hm_call_app0(aTHX_ loop, env);
        }
        c->in_app = 0;
        if (c->close_deferred) {
            /* The peer left, or the sweep gave up on it, while the handler
             * ran. Nothing it returned has anywhere to go. */
            c->close_deferred = 0;
            if (env_rv) SvREFCNT_dec(env_rv);
            if (resp)   SvREFCNT_dec(resp);
            hm_close(aTHX_ loop, c);
            return;
        }
        hm_read_resume(loop, c);

        /* The app called detach: the socket is its own now. Drop whatever it
         * returned (the sentinel), forget the connection, and do not touch c
         * again. Any bytes past this request are dropped with it - RFC 6455
         * forbids the client sending before the 101, so they are a protocol
         * violation, not data we owe anyone. */
        if (c->detached) {
            if (env_rv) {
                hm_access_log(aTHX_ loop, env_rv, 101, -1);
                SvREFCNT_dec(env_rv);
            }
            if (resp) SvREFCNT_dec(resp);
            c->nreqs++;
            loop->requests++;
            hm_conn_release(aTHX_ loop, c);
            return;
        }

        /* The app opened a 101 stream handle from inside the handler
         * (hm_stream_open): the connection is a tunnel now, its bytes
         * belong to the handle both ways, and the triplet the handler
         * returned is the same sentinel a detach leaves behind. Parked for
         * the life of the handle - stream_close unparks it, and the close
         * that follows (keepalive is off) ends the tunnel. Bytes that came
         * in with the request are the handle's too, so they are handed
         * over rather than parsed as a request that will never come. */
        if (c->tunnel == 2) {
            size_t consumed = bodystart + body_consumed;
            c->tunnel = 1;
            if (env_rv) {
                hm_access_log(aTHX_ loop, env_rv, 101, -1);
                SvREFCNT_dec(env_rv);
            }
            if (resp) SvREFCNT_dec(resp);
            memmove(c->rbuf, c->rbuf + consumed, c->rlen - consumed);
            c->rlen -= consumed;
            c->req_start = 0;
            c->nreqs++;
            loop->requests++;
            if (c->rlen) {
                size_t n = c->rlen;
                c->rlen = 0;
                if (!hm_stream_deliver(aTHX_ c->fd, c->id, -1, c->rbuf, n, 0)
                    && loop->conns[c->fd] == c)
                    c->rlen = n;        /* no read half yet: kept for it */
            }
            return;
        }

        size_t consumed = bodystart + body_consumed;
        memmove(c->rbuf, c->rbuf + consumed, c->rlen - consumed);
        c->rlen -= consumed;
        c->req_start = 0;
        c->body_phase = 0;
        c->chunk_pos = c->chunk_dec = 0;
        c->cont_sent = 0;       /* the next request on this connection asks
                                 * for itself */
        served++;
        c->nreqs++;
        hm_count_request(loop);

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

/* A tunnel's bytes belong to its handle, not the request parser: hand over
 * whatever the read left in rbuf, or keep it when no read half is registered
 * yet. ONE function for both ways a read completes - readiness (hm_readable)
 * and completion (HM_EV_RECV) - because the completion path once had no
 * tunnel branch at all and fed the bytes to hm_process, where they sat as
 * the start of a request that never came. Every Linux box with liburing
 * takes that path by default, and macOS never does, so the six smokers that
 * failed t/41 were the first time it ran. Returns 0 when the callback closed
 * the connection. */
static int hm_tunnel_bytes(pTHX_ hm_conn *c) {
    hm_loop *loop = c->loop;
    size_t have = c->rlen;
    c->rlen = 0;
    if (!hm_stream_deliver(aTHX_ c->fd, c->id, -1, c->rbuf, have, 0)) {
        if (loop->conns[c->fd] != c) return 0;
        c->rlen = have;         /* no read half yet: kept for it */
    }
    return loop->conns[c->fd] == c;
}

/* Stop and restart reading a connection whose buffer is full while a frame
 * on the stack still holds pointers into it (hm_readable, below). The
 * watcher is persistent and level-triggered, so leaving the bytes in the
 * socket without this would wake the loop every turn until the frame
 * returned. Readiness mode only: a completion-mode read is armed from the
 * top of a loop turn (hm_run_again), never from under a frame. */
static void hm_read_pause(hm_loop *loop, hm_conn *c) {
    if (c->read_paused) return;
    c->read_paused = 1;
    loop->be->remove_io(loop->be, c->fd, HM_EV_READ);
}
static void hm_read_resume(hm_loop *loop, hm_conn *c) {
    if (!c->read_paused) return;
    c->read_paused = 0;
    loop->be->add_io(loop->be, c->fd, HM_EV_READ, 0);
}

static void hm_readable(pTHX_ hm_conn *c) {
    hm_loop *loop = c->loop;
    for (;;) {
        if (c->rlen == c->rcap) {
            /* A synchronous handler on the stack (in_app) may be nghttp2
             * reading frames out of this very buffer, or hm_process holding
             * offsets into it: growing it here would move it from under
             * them. Leave the rest in the socket until that frame returns. */
            if (c->in_app && !hm_h2_reentrant(c)) {
                hm_read_pause(loop, c);
                break;
            }
            /* HTTP/2: the buffer holds frames, not a request, and nghttp2
             * parses them incrementally - a frame larger than the buffer is
             * consumed across reads. Hand over what is here and let the
             * level-triggered watcher bring the rest. The request ceiling
             * is per stream there (hm_h2_cb_data_chunk); applied to this
             * buffer it closed every upload over 16KB on a server whose
             * max_body was below that. */
            if (c->h2) break;
            /* The same, one read earlier: the preface is in the buffer but
             * hm_process has not run to detect it. Let it. */
            if (hm_h2_preface_pending(c)) break;
            /* grow for large bodies; unbounded headers are rejected */
            if (c->rcap >= loop->max_read
                || (c->rlen >= 65536 && !hm_memmem(c->rbuf, c->rlen, "\r\n\r\n", 4))) {
                /* The buffer is full and may not grow. Until max_body was
                 * configurable this only happened to a genuinely enormous
                 * request and a bare close was defensible; now that an
                 * operator can set the ceiling BELOW the initial buffer
                 * (HM_RBUF, 16KB), it is the ordinary way an oversize
                 * request ends - and dropping the connection with no
                 * response at all would leave every such client staring at
                 * a timeout rather than a 413. Answer, then close.
                 *
                 * Only for a request that at least has a complete header
                 * block: without one this is a client streaming garbage,
                 * which has earned nothing but the close it used to get. */
                if (c->rcap >= loop->max_read
                    && hm_memmem(c->rbuf, c->rlen, "\r\n\r\n", 4)) {
                    static const char e413[] =
                        "HTTP/1.1 413 Payload Too Large\r\nContent-Length: 0\r\n"
                        "Connection: close\r\n\r\n";
                    hm_wb_put(c, e413, sizeof(e413) - 1);
                    c->keepalive = 0;
                    c->last_status = 413;
                    c->last_blen = 0;
                    (void)hm_flush(aTHX_ c);
                    if (loop->conns[c->fd] != c) return;   /* flush closed it */
                }
                hm_close(aTHX_ loop, c);
                return;
            }
            {
                size_t ncap = c->rcap * 2;
                if (ncap > loop->max_read) ncap = loop->max_read;
                c->rbuf = (char *)hm_xrealloc(c->rbuf, ncap);
                c->rcap = ncap;
            }
        }
        size_t want = c->rcap - c->rlen;
        ssize_t n = hm_cread(c, c->rbuf + c->rlen, want);
        if (n > 0) {
            c->rlen += (size_t)n;
            c->last_rx = loop->now;
            c->body_rx += (UV)n;
            /* A tunnel (a 101 stream handle): the bytes are the handle's,
             * not a request. Handed up read by read, so the buffer never
             * grows toward the ceiling that ends an oversize request. The
             * callback may close the stream and with it the connection.
             * Only once SETTLED (1): at 2 the request line is still in
             * rbuf and the hm_process frame that opened the tunnel owns the
             * buffer, so the bytes wait for it (it hands them over itself). */
            if (c->tunnel == 1 && !hm_tunnel_bytes(aTHX_ c)) return;
            /* A SHORT read means the socket buffer is drained: the kernel
             * handed over everything it had, so the confirming read that
             * would follow can only return EAGAIN. Stopping here removes ONE
             * SYSCALL FROM EVERY REQUEST - measured, an ordinary keep-alive
             * request cost three (two reads and a writev) and the second read
             * was always the empty one.
             *
             * Safe because the backends are LEVEL-triggered - no EV_CLEAR, no
             * EPOLLET. Draining to EAGAIN is an edge-triggered obligation,
             * and under level triggering anything that arrived between the
             * read and this line simply reports the fd readable again on the
             * next turn of the loop. Nothing is lost, and nothing stalls.
             *
             * NOT for TLS: a short SSL_read says nothing about the socket,
             * because the engine may hold more plaintext than it just
             * returned, and stopping on it would leave that sitting in the
             * engine until the peer happened to send again. */
            if (!c->ssl && (size_t)n < want) {
                /* The disarm the EAGAIN branch below would have done. A write
                 * watcher left armed over an empty write buffer re-fires
                 * every turn and spins the worker at 100% CPU. */
                if (c->writing && c->woff == c->wlen) {
                    loop->be->remove_io(loop->be, c->fd, HM_EV_WRITE);
                    c->writing = 0;
                }
                break;
            }
        } else if (n == 0) {
            /* The peer half-closed a tunnel: the same thing a zero read
             * means to a socket owner, told to the handle as fin before
             * the connection goes and the abort callback says the rest. */
            if (c->tunnel) {
                (void)hm_stream_deliver(aTHX_ c->fd, c->id, -1, c->rbuf, 0, 1);
                if (loop->conns[c->fd] != c) return;
            }
            hm_close(aTHX_ loop, c);
            return;
        } else if (errno == EAGAIN || errno == EWOULDBLOCK) {
            /* TLS read blocked wanting writable: arm a write watcher so a
             * write-readiness event re-drives us. Once it unblocks, drop that
             * watcher again unless there is queued output still waiting on
             * it. The backends are level-triggered, so a watcher left armed
             * over an empty write buffer is not merely untidy - it re-fires
             * every turn of the loop and spins the worker at 100% CPU. */
            if (c->tls_r_wants_w) {
                if (!c->writing) {
                    loop->be->add_io(loop->be, c->fd, HM_EV_WRITE, 0);
                    c->writing = 1;
                }
            } else if (c->writing && c->woff == c->wlen) {
                loop->be->remove_io(loop->be, c->fd, HM_EV_WRITE);
                c->writing = 0;
            }
            break;
        } else {
            hm_close(aTHX_ loop, c);
            return;
        }
    }
    hm_lru_touch(loop, c);
    /* A tunnel carries no requests. A connection whose synchronous handler
     * is on the stack (its ->get pumped this loop) keeps the new bytes in
     * rbuf for the hm_process frame already running on it: a second frame
     * would consume the pipeline from under the first one's offsets. */
    /* HTTP/2 is the exception once nghttp2 has returned: a handler waiting
     * for its body to drain is waiting for the window updates in these very
     * bytes, and hm_h2_input takes them without starting another request. */
    if (!c->tunnel && (!c->in_app || hm_h2_reentrant(c))) hm_process(aTHX_ c);
    if (loop->conns[c->fd] == c) hm_flush(aTHX_ c);
}

static hm_tw *hm_add_timer_watch_c(hm_loop *loop, double secs,
                                   hm_abi_timer_cb cb, void *ud);
static void hm_tls_handshake(pTHX_ hm_conn *c);

/* The first bytes on a proxy_protocol listener. PEEK, so the header can be
 * parsed without taking anything behind it off the socket: a ClientHello or
 * an h2 preface in the same segment stays in the kernel for hm_tls_wrap and
 * hm_h2_detect, which then run exactly as on a listener without a proxy.
 * Only a complete header is consumed, by a read of exactly its length. A
 * partial one is re-peeked when the level-triggered watcher fires again;
 * one that never completes is closed by hm_sweep after header_timeout. */
/* A partial PROXY header: the bytes stay in the socket (peeked, not read)
 * and the watcher is level-triggered, so returning to the loop would wake
 * it again at once - a peer that sent "PROXY TCP4 1" and stopped had the
 * worker re-peeking at 100% CPU until header_timeout. Reading is paused
 * and resumed by this timer; the sweep still closes a header that never
 * completes. */
typedef struct { hm_loop *loop; int fd; UV id; } hm_pp_retry;
static void hm_proxy_retry(pTHX_ void *ud) {
    hm_pp_retry *r = (hm_pp_retry *)ud;
    hm_conn *c = (r->fd >= 0 && r->fd < HM_MAXFD) ? r->loop->conns[r->fd] : NULL;
    PERL_UNUSED_CONTEXT;
    if (c && c->id == r->id && c->pp_wait) hm_read_resume(r->loop, c);
    free(r);
}

static void hm_proxy_readable(pTHX_ hm_conn *c) {
    hm_loop *loop = c->loop;
    unsigned char buf[HM_PP_MAX];
    hm_pp_result r;
    ssize_t n;
    long len;
    n = hm_os_recv_peek(c->fd, buf, sizeof(buf));
    if (n == 0) { hm_close(aTHX_ loop, c); return; }
    if (n < 0) {
        if (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR) return;
        hm_close(aTHX_ loop, c); return;
    }
    len = hm_pp_parse(buf, (size_t)n, &r);
    if (len == 0) {                                     /* more to come */
        hm_pp_retry *rt;
        if ((size_t)n >= sizeof(buf)) { hm_close(aTHX_ loop, c); return; }
        rt = (hm_pp_retry *)hm_xmalloc(sizeof(*rt));
        rt->loop = loop; rt->fd = c->fd; rt->id = c->id;
        hm_read_pause(loop, c);
        if (!hm_add_timer_watch_c(loop, 0.05, hm_proxy_retry, rt)) {
            free(rt);                 /* no timer: level-triggered it is */
            hm_read_resume(loop, c);
        }
        return;
    }
    if (len < 0) { hm_close(aTHX_ loop, c); return; }   /* not a PROXY header */
    /* take exactly the header; what follows is the client's first bytes */
    {
        ssize_t got = hm_os_recv(c->fd, buf, (size_t)len);
        if (got != len) { hm_close(aTHX_ loop, c); return; }
    }
    c->pp_wait = 0;
    c->req_start = 0;
    /* The proxy's own address is kept for $env; the client's replaces the
     * peer, so REMOTE_ADDR, the access log, the rate limiter and the
     * denylist all see the client from here on. */
    memcpy(c->proxy_addr, c->peer, sizeof(c->proxy_addr));
    c->proxy_port = c->peer_port;
    if (r.family) {
        static const unsigned char v4map[12] =
            { 0,0,0,0, 0,0,0,0, 0,0,0xff,0xff };
        c->peer[0] = '\0';
        /* ::ffff:a.b.c.d is the IPv4 client it names (see hm_fmt_peer) */
        if (r.family == AF_INET6 && memcmp(r.src, v4map, 12) == 0)
            (void)inet_ntop(AF_INET, (const unsigned char *)r.src + 12,
                            c->peer, (socklen_t)sizeof(c->peer));
        else
            (void)inet_ntop(r.family, r.src, c->peer, (socklen_t)sizeof(c->peer));
        c->peer_port = r.src_port;
        /* the denylist, again, now for the real client; the accept-time
         * check saw the proxy */
        if (hm_sa_deny_check(c->peer)) {
            loop->denied++;
            hm_close(aTHX_ loop, c);
            return;
        }
    }
    /* distinct clients counts clients, not proxies, so the accept path
     * skipped it on this listener */
    if (hm_sa_hll && c->peer[0]) hm_sa_hll_add(c->peer);
    if (c->lst && c->lst->tls_ctx) {
        hm_tls_wrap(c, c->lst->tls_ctx);
        hm_tls_handshake(aTHX_ c);
    } else {
        hm_readable(aTHX_ c);
    }
}

/* accept(2) failed for want of a descriptor. The listener is level-readable
 * and stays so, so simply returning would wake the loop again at once and
 * spin the worker at 100% CPU until the table had room. Reclaim an idle
 * keep-alive connection when there is one; otherwise stop listening for a
 * tenth of a second and come back. */
/* Listeners whose starvation timer could not be armed (hm_accept_starved):
 * re-added from the top of a loop turn. */
static void hm_accept_unstarve(hm_loop *loop) {
    int i;
    loop->starved_retry = 0;
    for (i = 0; i < loop->nlisteners; i++) {
        hm_listener *l = &loop->listeners[i];
        if (l->starved != 2) continue;
        l->starved = 0;
        if (!loop->stopping && l->fd >= 0)
            loop->be->add_io(loop->be, l->fd, HM_EV_READ, 0);
    }
}

typedef struct { hm_loop *loop; hm_listener *lst; } hm_starve;
static void hm_accept_rearm(pTHX_ void *ud) {
    hm_starve *s = (hm_starve *)ud;
    s->lst->starved = 0;
    if (!s->loop->stopping && s->lst->fd >= 0)
        s->loop->be->add_io(s->loop->be, s->lst->fd, HM_EV_READ, 0);
    free(s);
}
static void hm_accept_starved(pTHX_ hm_loop *loop, hm_listener *lst) {
    hm_conn *c = loop->lru_head;           /* oldest activity first */
    while (c) {
        if (!c->awaiting && !c->in_app && !c->h2 && !c->tunnel && !c->tls_hs
            && c->rlen == 0 && c->wlen == c->woff && !c->bsrc.kind
            && c->nreqs > 0) {
            hm_close(aTHX_ loop, c);
            return;
        }
        c = c->lru_next;
    }
    if (lst->starved) return;
    {
        hm_starve *s = (hm_starve *)hm_xmalloc(sizeof(*s));
        s->loop = loop;
        s->lst  = lst;
        lst->starved = 1;
        loop->be->remove_io(loop->be, lst->fd, HM_EV_READ);
        if (!hm_add_timer_watch_c(loop, 0.1, hm_accept_rearm, s)) {
            /* No timer to be had: on epoll a timer IS a descriptor, and
             * this is the descriptor famine. Re-added from the top of a
             * later loop turn instead (hm_accept_unstarve) - the next close
             * wakes the loop, and the interval sweep does within five
             * seconds regardless. Before this the listener stayed removed
             * and the worker never accepted again. */
            free(s);
            lst->starved = 2;
            loop->starved_retry = 1;
        }
    }
}

static void hm_accept(pTHX_ hm_loop *loop, hm_listener *lst) {
    int batch = 0;
    if (loop->stopping) return;
    for (;;) {
        struct sockaddr_storage ss;
        socklen_t slen = sizeof(ss);
        hm_conn *c;
        char peer[INET6_ADDRSTRLEN];
        int  peer_port;
#ifdef HM_HAVE_ACCEPT4
        /* Non-blocking and close-on-exec in the accept itself: two fewer
         * syscalls per connection, and no window in which a fork from a
         * handler inherits a client socket. */
        int fd = accept4(lst->fd, (struct sockaddr *)&ss, &slen,
                         SOCK_NONBLOCK | SOCK_CLOEXEC);
#else
        int fd = hm_os_accept(lst->fd, (struct sockaddr *)&ss, &slen);
#endif
        if (fd < 0) {                          /* EAGAIN: drained */
            if (errno == EMFILE || errno == ENFILE)
                hm_accept_starved(aTHX_ loop, lst);
            break;
        }
        if (fd >= HM_MAXFD) { hm_os_close(fd); continue; }
#if !defined(HM_HAVE_ACCEPT4) && !defined(_WIN32)
        /* Not into anything the application execs: a child that kept a
         * client socket open held the client past the response, and could
         * write onto it (onto a TLS socket, raw). hm_new_conn sets
         * non-blocking. */
        (void)fcntl(fd, F_SETFD, fcntl(fd, F_GETFD, 0) | FD_CLOEXEC);
#endif
        /* Denylist: format the peer and drop a blocked IP HERE, before a
         * connection object is allocated or a byte is read - the cheapest
         * possible rejection. Fails open (no arena -> deny_check is 0). */
        hm_fmt_peer(peer, sizeof(peer), &peer_port, (struct sockaddr *)&ss);
        if (hm_sa_deny_check(peer)) { hm_os_close(fd); loop->denied++; continue; }
        /* Distinct clients, opt-in: with the sketch off this is one load of
         * a NULL, with it on a hash and a CAS-max on the peer string. */
        if (hm_sa_hll && peer[0] && !lst->proxy_protocol) hm_sa_hll_add(peer);
        c = hm_new_conn(loop, fd, lst);
        memcpy(c->peer, peer, sizeof(c->peer));
        c->peer_port = peer_port;
        loop->accepts++;
        if (c->tls_failed) { hm_close(aTHX_ loop, c); continue; }
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
        /* What the kernel took, for stats and tests. The write paths do NOT
         * read this - they ask OpenSSL again each time, because the answer
         * can change under them (see hm_ktls_tx). */
        c->ktls_tx = hm_ktls_tx(c) ? 1 : 0;
        if (c->writing) {
            loop->be->remove_io(loop->be, c->fd, HM_EV_WRITE);
            c->writing = 0;
        }
#ifdef HM_HAVE_NGHTTP2
        if (c->lst && c->lst->http2) {
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
static void hm_io_event(pTHX_ hm_loop *loop, int fd, int mask, hm_iow *slot) {
    SV *sv = slot->sv;
    PERL_UNUSED_VAR(loop);
    if (slot->c_cb) { slot->c_cb(aTHX_ fd, mask, slot->c_ud); return; }
    if (!sv) return;
    if (slot->is_cb) {
        dSP;
        ENTER; SAVETMPS; PUSHMARK(SP);
        PUTBACK;
        call_sv(sv, G_DISCARD | G_EVAL);
        hm_warn_died(aTHX_ "watch_io callback");
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
        /* in_app: a synchronous handler is running for it (and pumping
         * this loop); its request is in progress, not idle */
        if (!c->awaiting && !c->in_app) {
            double idle = difftime(now, c->last_active);
            /* Two guards for two phases. The header block is timed from the
             * request's first byte, which is the slowloris guard. Once the
             * headers are complete and a body is arriving, the clock is
             * progress: a body that has not delivered a byte for
             * body_timeout is dead, however long it has been coming - and
             * an upload slower than max_body in header_timeout is not. */
            int slow = c->req_start &&
                       (c->body_phase
                        ? difftime(now, c->last_rx)   > loop->body_timeout
                        : difftime(now, c->req_start) > loop->header_timeout);
            /* Two OPT-IN floors under the progress clock, for a deployment
             * that cannot afford a body dribbled a byte a minute for ever:
             * a minimum average rate over the body phase (judged after two
             * seconds, so a first slow segment is not a verdict), and a
             * ceiling on the whole request from its first byte. */
            if (!slow && c->req_start && c->body_phase && loop->body_min_rate) {
                double span = difftime(now, c->body_t0);
                if (span >= 2.0
                    && (double)c->body_rx / span < (double)loop->body_min_rate)
                    slow = 1;
            }
            if (!slow && c->req_start && loop->request_timeout > 0
                && difftime(now, c->req_start) > loop->request_timeout)
                slow = 1;
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
    {
        int i;
        for (i = 0; i < loop->nlisteners; i++) {
            if (loop->listeners[i].fd >= 0)
                loop->be->remove_io(loop->be, loop->listeners[i].fd, HM_EV_READ);
            /* Stop taking datagrams too. A QUIC connection already up is
             * not on this fd in any fd-indexed sense, so nothing else here
             * reaches it; draining those needs a graceful shutdown that
             * sends CONNECTION_CLOSE, which is not implemented. */
            if (loop->listeners[i].udp_fd >= 0)
                loop->be->remove_io(loop->be, loop->listeners[i].udp_fd, HM_EV_READ);
        }
    }
    hm_quic_shutdown(aTHX_ loop);
    c = loop->lru_head;
    while (c) {
        hm_conn *next = c->lru_next;
        if (!c->awaiting && !c->in_app && c->rlen == 0 && c->wlen == c->woff
            && c->nreqs > 0)
            hm_close(aTHX_ loop, c);
        c = next;
    }
    if (loop->nconns == 0) { loop->stop = 1; return; }
    if (!loop->hardstop_tw) {
        loop->hardstop_tw = (hm_tw *)hm_xcalloc(1, sizeof(hm_tw));
        loop->hardstop_tw->kind = HM_TW_HARDSTOP;
        loop->hardstop_tw->loop = loop;
        loop->hardstop_tw->due  = hm_tw_due(loop->shutdown_grace);
        if (loop->be->add_timer(loop->be, loop->shutdown_grace, 1, loop->hardstop_tw) < 0)
            hm_errlog("Hyperman: cannot arm the shutdown_grace timer: %s\n", strerror(errno));
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
        call_sv(cb, G_DISCARD | G_EVAL);
        hm_warn_died(aTHX_ "deferred callback");
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
        if (c && c->id == loop->again[i].id) c->again_queued = 0;
        if (c && c->id == loop->again[i].id && !c->awaiting
            && (!c->in_app || hm_h2_reentrant(c)) && !c->bsrc.kind) {
            hm_process(aTHX_ c);
            if (loop->conns[c->fd] == c) {
                hm_flush(aTHX_ c);
                /* THE re-arm point for completion mode, and the reason
                 * anything that wants a read armed calls hm_again_push
                 * rather than arming for itself: this runs at the top of a
                 * loop turn, so hm_process is not on the stack and growing
                 * the read buffer cannot pull the ground out from under the
                 * pointers it holds into it. */
                if (loop->conns[c->fd] == c) hm_rearm_read(loop, c);
            }
        }
    }
}

static void hm_dispatch(pTHX_ hm_loop *loop, hm_event *ev) {
    switch (ev->kind) {
    case HM_EV_TIMER: {
        hm_tw *tw = (hm_tw *)ev->udata;
        if (!tw || tw->dead) return;      /* cancelled earlier in this batch */
        if (tw->kind == HM_TW_SWEEP) { hm_sweep(aTHX_ loop); return; }
        /* A oneshot delivered before its deadline (NetBSD's kqueue timed a
         * 300ms Fetch request out at 246ms on a smoker) is re-armed for the
         * remainder and not fired. The backend has already dropped it, so the
         * same watcher is free to re-add; each re-arm is shorter, so a
         * backend that is always early still converges. Within a
         * millisecond is the backends' own rounding. */
        if (tw->due > 0) {
            double left = tw->due - (double)hm_now_ns() / 1e9;
            /* could not re-arm (no descriptor for a timerfd): early beats
             * never, so it fires now */
            if (left > 1e-3 && loop->be->add_timer(loop->be, left, 1, tw) == 0)
                return;
        }
        if (tw->kind == HM_TW_HARDSTOP) { loop->stop = 1; return; }
        if (tw->kind == HM_TW_C) {          /* ABI timer: no Perl frame */
            hm_abi_timer_cb cb = tw->c_cb;
            void *ud = tw->c_ud;
            free(tw);
            cb(aTHX_ ud);
            return;
        }
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
                call_sv(sv, G_DISCARD | G_EVAL);
                hm_warn_died(aTHX_ "timer callback");
                FREETMPS; LEAVE;
            }
            SvREFCNT_dec(sv);
        }
        return;
    }
    case HM_EV_SIGNAL:
        if (ev->fd == SIGUSR1) {
            /* With a scoreboard the supervisor prints every row itself and
             * never forwards USR1; this line is the no-arena fallback. */
            if (!hm_sa_board_live())
                hm_errlog("Hyperman worker %d: requests=%lu accepts=%lu conns=%d "
                    "bytes_out=%lu backend=%s%s\n",
                    hm_os_getpid(),
                    (unsigned long)loop->requests, (unsigned long)loop->accepts,
                    loop->nconns, (unsigned long)loop->bytes_out,
                    loop->be->name, loop->stopping ? " (draining)" : "");
            return;
        }
        hm_on_signal(aTHX_ loop);
        return;
    case HM_EV_RECV: {
        /* A read the core asked for has finished; the bytes are already in
         * the buffer it supplied. */
        int fd = ev->fd;
        hm_conn *c = (fd >= 0 && fd < HM_MAXFD) ? loop->conns[fd] : NULL;

        /* Is this OUR read? A completion can outlive its connection - the fd
         * may have been closed and reused since - and the token is the only
         * thing that can tell the difference. Anything that does not match
         * belongs to a connection that is gone, and the buffer it was reading
         * into is parked waiting for exactly this moment. */
        if (!c || !c->recv_inflight || HM_RECV_TOKEN(c) != ev->token) {
            hm_quar_release(loop, ev->token);
            return;
        }
        c->recv_inflight = 0;
        if (ev->res <= 0) {   /* EOF, error, or the cancel from a close */
            /* The peer half-closed a tunnel: fin to the handle first, as
             * hm_readable's zero read does, then the close says the rest. */
            if (c->tunnel && ev->res == 0) {
                (void)hm_stream_deliver(aTHX_ c->fd, c->id, -1, c->rbuf, 0, 1);
                if (loop->conns[fd] != c) return;
            }
            hm_close(aTHX_ loop, c);
            return;
        }
        c->rlen += (size_t)ev->res;
        c->last_rx = loop->now;
        c->body_rx += (UV)ev->res;
        c->last_active = loop->now;
        hm_lru_touch(loop, c);
        /* A tunnel carries no requests: its bytes go to the handle. The
         * parser would hold them as an unfinished request line forever. */
        if (c->tunnel == 1) { if (!hm_tunnel_bytes(aTHX_ c)) return; }
        /* The same rule hm_readable applies: a synchronous handler's frame
         * is on the stack for this connection (its ->get pumped the loop,
         * and this read was in flight when it was handed the pipeline), or
         * a tunnel was opened inside it and the request is still in rbuf.
         * That frame owns the buffer. The bytes wait in it, nothing is
         * dispatched or re-armed from under it, and whoever called that
         * frame re-arms when it returns (hm_deliver's hm_again_push, or the
         * re-arm below in the frame that called hm_process). Without this a
         * second hm_process re-parsed the request at rbuf[0], called the
         * application twice, and left the outer frame to memmove with a
         * consumed count larger than what remained. */
        else if (c->tunnel == 2 || (c->in_app && !hm_h2_reentrant(c))) return;
        else hm_process(aTHX_ c);
        if (loop->conns[fd] != c) return;      /* dispatch closed it */
        hm_flush(aTHX_ c);
        if (loop->conns[fd] != c) return;      /* flush closed it */
        /* Re-armed even while PARKED or streaming, and that is not an
         * optimisation - it is how a disconnect is noticed at all.
         *
         * A readiness backend keeps a persistent watcher on every connection,
         * so a client that walks away from a parked async request wakes the
         * loop with EOF and the response Future gets cancelled. Completion
         * mode has no such watcher: with no read outstanding the close is
         * simply never seen, the Future is never cancelled, and the
         * connection sits there until the idle sweep. t/13-async-psgi.t
         * catches exactly this.
         *
         * Safe because the request's bytes are gone from the buffer before it
         * parks - hm_process consumes them, and hm_new_input COPIES the body
         * into an SV - so nothing points into rbuf across a park, and the
         * kernel only ever writes past rlen. */
        hm_rearm_read(loop, c);
        return;
    }
    case HM_EV_READ: {
        int fd = ev->fd;
        hm_conn *c;
        hm_listener *lst;
        if ((lst = hm_listener_for_fd(loop, fd))) { hm_accept(aTHX_ loop, lst); return; }
        /* Between the two, because a UDP listener fd is never in conns[]:
         * QUIC multiplexes every connection over the one socket, so there is
         * nothing fd-indexed to find. */
        if ((lst = hm_listener_for_udp(loop, fd))) {
            hm_quic_readable(aTHX_ loop, lst);
            return;
        }
        if ((c = loop->conns[fd])) {
            if (c->pp_wait)             hm_proxy_readable(aTHX_ c);
            else if (c->tls_hs)         hm_tls_handshake(aTHX_ c);
            else                        hm_readable(aTHX_ c);
        }
        else if (loop->io_r[fd].sv || loop->io_r[fd].c_cb)
            hm_io_event(aTHX_ loop, fd, HM_EV_READ, &loop->io_r[fd]);
        return;
    }
    case HM_EV_WRITE: {
        int fd = ev->fd;
        hm_conn *c;
        if ((c = loop->conns[fd])) {
            /* TLS post-handshake: when the write watcher is armed because
             * SSL_read wanted a writable socket, route through hm_readable so
             * the blocked read is re-driven (it flushes pending output at the
             * end). Otherwise this is ordinary write backpressure and the
             * read side is not blocked at all - going through hm_readable
             * then costs an SSL_read that can only return EAGAIN, once per
             * writable wakeup for the whole of a large response. */
            if (c->tls_hs)                       hm_tls_handshake(aTHX_ c);
            else if (c->ssl && c->tls_r_wants_w) hm_readable(aTHX_ c);
            else                                 hm_flush(aTHX_ c);
        }
        else if (loop->io_w[fd].sv || loop->io_w[fd].c_cb)
            hm_io_event(aTHX_ loop, fd, HM_EV_WRITE, &loop->io_w[fd]);
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
    /* The fire queue is pumped by whoever enqueues, unless a pump is
     * already on the stack (hm_fq_active), which makes a continuation that
     * enqueues from inside a callback leave its work for the pump above
     * it. That pump is above THIS frame too when a handler reached through
     * the queue (a parked response delivering the next pipelined request)
     * calls ->get: the nested run here must pump for itself, or every
     * continuation it waits on - a ->then, a combinator - sits in the queue
     * until it returns, which is never. Restored on the way out; a croak
     * out of here leaves it 0, which only lets the outer pump be nested
     * once, and nesting a pump is safe (they share one queue). */
    int fq_was = hm_fq_active;
    hm_fq_active = 0;
    hm_cur_loop = loop;
    loop->running++;
    /* Cleared for the OUTERMOST run only. A nested run is a handler's ->get
     * pumping this loop, and a stop asked for while it runs - the second
     * TERM, the shutdown_grace hard-stop, the last connection closing while
     * draining - is the outer run's to act on: the nested one breaks and
     * leaves the flag set. Clearing it on exit, as this once did, swallowed
     * every stop that landed under a handler, and the hard-stop timer is
     * one-shot so the worker then never left. */
    if (loop->running == 1) loop->stop = 0;
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
        if (loop->starved_retry) hm_accept_unstarve(loop);
        if (loop->stop) break;
        if (until && hmf_state(aTHX_ until) != HMF_PENDING) break;
        if (av_len(loop->deferred) >= 0 || loop->again_n) timeout = 0.0;
        /* QUIC's deadlines do not live in the backend's timer list - see the
         * costing in hm_quic.h - so the wait is clamped to the nearest one
         * here instead. Rounding UP is correct: ngtcp2 copes with a late
         * expiry and not with an early one, and the backends already round
         * to milliseconds. One compare when there is no QUIC listener. */
        if (loop->qheap.n) {
            /* Through a function rather than reaching into the heap here:
             * hm_qconn is an opaque forward declaration on a build without
             * QUIC, and dereferencing it would compile only where the
             * feature is present - which is not where the mistake shows up. */
            uint64_t now_ns = hm_now_ns();
            uint64_t due    = hm_quic_next_deadline(loop);
            if (due != (uint64_t)-1) {
                double secs = due <= now_ns ? 0.0
                                            : (double)(due - now_ns) / 1e9;
                if (timeout < 0.0 || secs < timeout) timeout = secs;
            }
        }
        n = loop->be->wait(loop->be, evs, HM_MAXEV, timeout);
        if (n < 0) { if (errno == EINTR) continue; break; }
        for (i = 0; i < n; i++) hm_dispatch(aTHX_ loop, &evs[i]);
        if (loop->tw_gy && loop->running == 1) hm_tw_gy_sweep(loop);
        if (loop->qheap.n) hm_quic_expire(aTHX_ loop);
        if (loop->log_fd >= 0 && loop->log_len) hm_log_flush(loop);
        if (loop->stop) break;
        if (until && hmf_state(aTHX_ until) != HMF_PENDING) break;
    }
    if (loop->tw_gy && loop->running == 1) hm_tw_gy_sweep(loop);
    loop->running--;
    hm_cur_loop = prev;
    hm_fq_active = fq_was;
}

/* ---- loop lifecycle ------------------------------------------------------- */

static hm_loop *hm_loop_new(pTHX_ const char *backend_name) {
    hm_loop *loop = (hm_loop *)hm_xcalloc(1, sizeof(hm_loop));
    if (!loop) return NULL;
    if (!backend_name || !*backend_name)
        backend_name = getenv("HYPERMAN_BACKEND");
    loop->be = hm_backend_create(backend_name);
    if (!loop->be) { free(loop); return NULL; }
    loop->pid = hm_os_getpid();
    loop->conns = (hm_conn **)hm_xcalloc(HM_MAXFD, sizeof(hm_conn *));
    loop->io_r  = (hm_iow *)hm_xcalloc(HM_MAXFD, sizeof(hm_iow));
    loop->io_w  = (hm_iow *)hm_xcalloc(HM_MAXFD, sizeof(hm_iow));
    loop->deferred = newAV();
    loop->log_fd = -1;
    loop->now = time(NULL);
    loop->idle_timeout   = 60.0;
    loop->header_timeout = 30.0;
    loop->body_timeout   = 60.0;
    loop->max_pipeline   = 32;
    loop->max_read       = 16 * 1024 * 1024;   /* request ceiling */
    loop->compress       = 0;                  /* off by default */
    loop->compress_min   = HZ_MIN_LENGTH;
    loop->compress_level = HZ_LEVEL;
    loop->shutdown_grace = 30.0;
    /* Completion-mode reads, on wherever the backend can do them.
     *
     * That is io_uring alone, and io_uring IS auto-selected wherever
     * liburing was found at build time (the chooser goes kqueue, io_uring,
     * epoll, poll), so on such a Linux box this is the default read path -
     * which is why every change to how bytes ARRIVE lands on both the
     * readiness and the completion path (t/49 sweeps both).
     *
     * HYPERMAN_COMPLETION overrides, exactly as HYPERMAN_BACKEND overrides
     * the chooser; run(completion => ...) overrides both, being the most
     * specific thing the caller said. */
    loop->completion = loop->be->submit_recv ? 1 : 0;
    {
        const char *v = getenv("HYPERMAN_COMPLETION");
        if (v && *v)
            loop->completion =
                (*v != '0' && loop->be->submit_recv) ? 1 : 0;
    }
    return loop;
}

/* Free a loop.
 *
 * A loop belongs to the process that created it, and every DESCRIPTOR in it -
 * the backend's own (kqueue/epoll), the connection sockets, the log file -
 * belongs to that process too. A loop inherited across a fork is therefore
 * freed WITHOUT closing anything: the memory is ours to release, the fds are
 * not.
 *
 * Closing them is destructive, not merely untidy. kqueue descriptors do not
 * survive fork(2): the kernel invalidates the child's copy, so the number is
 * free and the child's very next kqueue() is handed it back - closing the
 * inherited loop then shuts the CHILD'S OWN queue and nothing it watches
 * fires again. The epoll and connection fds are the parent's, still live, and
 * closing our duplicates frees numbers the child immediately reuses. */
/* A loop inherited across a fork must never reach its backend. On Linux an
 * epoll INSTANCE is a shared kernel object: fork duplicates the fd but both
 * processes' epoll_ctl calls edit the SAME interest list, so a child
 * "cleaning up" inherited watchers silently deregisters the PARENT's fds -
 * the parent then waits on an empty set forever (the DBIx::Loop
 * disown-in-a-forked-child hang, Punk t/39). kqueue merely hands the child
 * a dead descriptor, which is why macOS never showed it. The copied
 * user-space tables are ours to update; the kernel object is not. */
#define HM_LOOP_INHERITED(loop) ((loop)->pid != hm_os_getpid())

static void hm_loop_free(pTHX_ hm_loop *loop) {
    int i;
    int owned;
    if (!loop) return;
    owned = (loop->pid == hm_os_getpid());
    /* Read buffers still parked for completions that will now never be
     * reaped. The ring is torn down with the backend below, so nothing can
     * be writing into them by the time this returns. */
    hm_quar_free_all(loop);
    hm_tw_gy_sweep(loop);
    for (i = 0; i < HM_MAXFD; i++) {
        if (loop->conns[i]) {
            hm_conn *c = loop->conns[i];
            if (owned) hm_os_close(c->fd);
            if (c->h2)     hm_h2_free(aTHX_ c->h2);
            if (c->io_sv)  SvREFCNT_dec(c->io_sv);
            if (c->resp_f) SvREFCNT_dec(c->resp_f);
            if (c->env_sv) SvREFCNT_dec(c->env_sv);
            if (c->peer_sv)      SvREFCNT_dec(c->peer_sv);
            if (c->peer_host_sv) SvREFCNT_dec(c->peer_host_sv);
            if (c->peer_port_sv) SvREFCNT_dec(c->peer_port_sv);
            if (c->sname_sv)     SvREFCNT_dec(c->sname_sv);
            if (c->sport_sv)     SvREFCNT_dec(c->sport_sv);
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
    if (loop->log_fd >= 0 && owned) { hm_log_flush(loop); hm_os_close(loop->log_fd); }
    if (loop->log_buf) free(loop->log_buf);
    for (i = 0; i < loop->nlisteners; i++) {
        /* Before the fds: freeing a connection writes a CONNECTION_CLOSE. */
        if (owned) hm_quic_srv_free(aTHX_ &loop->listeners[i]);
        if (loop->listeners[i].host)   free(loop->listeners[i].host);
        if (loop->listeners[i].altsvc) free(loop->listeners[i].altsvc);
        if (loop->listeners[i].tls_sni) SvREFCNT_dec(loop->listeners[i].tls_sni);
        /* `owned` for the same reason every other descriptor here is: a loop
         * belonging to another process holds fd NUMBERS that are ours, and
         * closing them would close whatever this process has since put
         * there. An inherited UDP listener is the third case of that, after
         * the backend descriptor and the connections. */
        if (loop->listeners[i].udp_fd >= 0 && owned)
            hm_os_close(loop->listeners[i].udp_fd);
    }
    if (loop->listeners) free(loop->listeners);
    /* A weak copy of the wrapper (hm_loop_to_sv): dropping it frees the RV
     * alone and runs no DESTROY. */
    if (loop->self_sv) {
        SV *self = loop->self_sv;
        loop->self_sv    = NULL;
        loop->perl_owned = 0;
        SvREFCNT_dec(self);
    }
    if (loop->log_cb)  SvREFCNT_dec(loop->log_cb);
    if (loop->app) SvREFCNT_dec(loop->app);
    SvREFCNT_dec((SV *)loop->deferred);
    if (loop->again) free(loop->again);
    if (loop->hidx) free(loop->hidx);
    if (loop->sweep_tw) free(loop->sweep_tw);
    if (loop->hardstop_tw) free(loop->hardstop_tw);
    if (loop->qheap.a) free(loop->qheap.a);
    /* destroy() releases the backend's memory either way; `foreign` is what
     * stops it closing descriptors that are not ours - see the note above */
    if (!owned) loop->be->foreign = 1;
    loop->be->destroy(loop->be);
    free(loop->conns);
    free(loop->io_r);
    free(loop->io_w);
    free(loop);
}

/* Attach the PSGI server to a loop: listener, shutdown/stats signals via
 * the backend's signal watcher, and the timeout sweep timer. */
static void hm_attach_server(pTHX_ hm_loop *loop, SV *app) {
    int i;
    loop->app = SvREFCNT_inc(app);
    loop->attached = 1;
    for (i = 0; i < loop->nlisteners; i++) {
        loop->be->add_io(loop->be, loop->listeners[i].fd, HM_EV_READ, 0);
        if (loop->listeners[i].udp_fd >= 0) {
            /* After the fork, in the worker that will serve: the SSL_CTX and
             * the CID table belong to this process alone. */
            hm_quic_srv_attach(aTHX_ loop, &loop->listeners[i], i);
            loop->be->add_io(loop->be, loop->listeners[i].udp_fd, HM_EV_READ, 0);
        }
    }
#ifndef _WIN32
    /* Ignore the default dispositions: these arrive through the backend's
     * signal watcher instead. Windows has no signal to ignore - the
     * WSAPoll backend's console handler is the only source there. */
    signal(SIGPIPE, SIG_IGN);
    signal(SIGTERM, SIG_IGN);
    signal(SIGINT,  SIG_IGN);
    signal(SIGUSR1, SIG_IGN);
#endif
    loop->be->add_signal(loop->be, SIGTERM);
    loop->be->add_signal(loop->be, SIGINT);
    loop->be->add_signal(loop->be, SIGUSR1);
    loop->sweep_tw = (hm_tw *)hm_xcalloc(1, sizeof(hm_tw));
    loop->sweep_tw->kind = HM_TW_SWEEP;
    loop->sweep_tw->loop = loop;
    if (loop->be->add_timer(loop->be, HM_SWEEP_SECS, 0, loop->sweep_tw) < 0)
        hm_errlog("Hyperman: cannot arm the timeout sweep: %s\n", strerror(errno));
}

/* register a timer watcher resolving a Future / running a callback */
static void hm_add_timer_watch(pTHX_ hm_loop *loop, double secs, SV *sv, int kind) {
    hm_tw *tw = (hm_tw *)hm_xcalloc(1, sizeof(hm_tw));
    tw->kind = kind;
    tw->sv   = SvREFCNT_inc(sv);
    tw->loop = loop;
    tw->due  = hm_tw_due(secs);
    /* A backend can refuse: on epoll every timer is a descriptor, so under
     * EMFILE there is none to be had. Silently dropping it left a ->get on
     * the timer's future pumping the loop for ever. */
    if (!HM_LOOP_INHERITED(loop) && loop->be->add_timer(loop->be, secs, 1, tw) < 0) {
        int e = errno;
        SvREFCNT_dec(sv);
        free(tw);
        croak("Hyperman: cannot arm a timer: %s", strerror(e));
    }
}

/* Let go of whatever a watcher slot held. A one-shot future that was still
 * pending is CANCELLED, not dropped: a `->get` waiting on it would otherwise
 * pump the loop for a readiness nothing is watching for any more. */
static void hm_iow_release_sv(pTHX_ SV *sv, int is_cb) {
    if (!sv) return;
    if (!is_cb && hmf_is_future(aTHX_ sv) && hmf_state(aTHX_ sv) == HMF_PENDING)
        hmf_cancel(aTHX_ sv);
    SvREFCNT_dec(sv);
}

/* The slot is EMPTIED before the old occupant is released, and the new
 * occupant (where there is one) is seated before that too: releasing a
 * pending future fires its callbacks, and one of those may watch this same
 * fd again. With the release first, that inner registration landed in the
 * slot and was then overwritten by the outer one - a future that never
 * fired - or, on the remove path, was left in a slot whose kind had been
 * reset, so the next event settled a callback CV as if it were a future. */
static void hm_iow_release(pTHX_ hm_iow *slot) {
    SV *sv = slot->sv;
    int is_cb = slot->is_cb;
    if (!sv) return;
    slot->sv = NULL;
    hm_iow_release_sv(aTHX_ sv, is_cb);
}

static void hm_add_io_watch(pTHX_ hm_loop *loop, int fd, const char *mode,
                            SV *sv, int is_cb) {
    hm_iow *slot;
    SV *old;
    int old_cb;
    int mask;
    if (fd < 0 || fd >= HM_MAXFD) croak("Hyperman: bad fd %d", fd);
    if (mode[0] == 'w') { slot = &loop->io_w[fd]; mask = HM_EV_WRITE; }
    else                { slot = &loop->io_r[fd]; mask = HM_EV_READ;  }
    old    = slot->sv;
    old_cb = slot->is_cb;
    slot->sv    = SvREFCNT_inc(sv);
    slot->is_cb = (unsigned char)is_cb;
    slot->c_cb  = NULL;
    slot->c_ud  = NULL;
    if (!HM_LOOP_INHERITED(loop))
        loop->be->add_io(loop->be, fd, mask, is_cb ? 0 : 1);
    hm_iow_release_sv(aTHX_ old, old_cb);
}

/* ABI: persistent C watcher, replacing whatever held the slot. */
static void hm_add_io_watch_c(pTHX_ hm_loop *loop, int fd, int mask,
                              hm_abi_io_cb cb, void *ud) {
    hm_iow *slot;
    SV *old;
    int old_cb;
    if (fd < 0 || fd >= HM_MAXFD) croak("Hyperman: bad fd %d", fd);
    slot = (mask & HM_EV_WRITE) ? &loop->io_w[fd] : &loop->io_r[fd];
    old    = slot->sv;
    old_cb = slot->is_cb;
    slot->sv    = NULL;
    slot->is_cb = 0;
    slot->c_cb  = cb;
    slot->c_ud  = ud;
    if (!HM_LOOP_INHERITED(loop))
        loop->be->add_io(loop->be, fd,
                         (mask & HM_EV_WRITE) ? HM_EV_WRITE : HM_EV_READ, 0);
    hm_iow_release_sv(aTHX_ old, old_cb);
}

/* Drop one direction's watcher (any kind); idempotent. */
static void hm_del_io_watch(pTHX_ hm_loop *loop, int fd, int mask) {
    hm_iow *slot;
    SV *old;
    int old_cb;
    if (fd < 0 || fd >= HM_MAXFD) return;
    slot = (mask & HM_EV_WRITE) ? &loop->io_w[fd] : &loop->io_r[fd];
    if (!slot->sv && !slot->c_cb) return;
    if (!HM_LOOP_INHERITED(loop))
        loop->be->remove_io(loop->be, fd,
                            (mask & HM_EV_WRITE) ? HM_EV_WRITE : HM_EV_READ);
    old    = slot->sv;
    old_cb = slot->is_cb;
    slot->sv    = NULL;
    slot->is_cb = 0;
    slot->c_cb  = NULL;
    slot->c_ud  = NULL;
    hm_iow_release_sv(aTHX_ old, old_cb);
}

/* ABI: one-shot C timer; the returned watcher doubles as the cancel handle
 * (freed on fire or on cancel, never both - single-threaded). */
static hm_tw *hm_add_timer_watch_c(hm_loop *loop, double secs,
                                   hm_abi_timer_cb cb, void *ud) {
    hm_tw *tw = (hm_tw *)hm_xcalloc(1, sizeof(hm_tw));
    tw->kind = HM_TW_C;
    tw->loop = loop;
    tw->c_cb = cb;
    tw->c_ud = ud;
    tw->due  = hm_tw_due(secs);
    if (loop->be->add_timer(loop->be, secs, 1, tw) < 0) {
        /* NULL, and a line in the log: the C callers (the scoreboard tick,
         * the bus poll, the accept re-arm) each have a fallback or a reason
         * to be loud, and an ABI consumer is told the handle is NULL. */
        hm_errlog("Hyperman: cannot arm a %.3fs timer: %s\n", secs, strerror(errno));
        free(tw);
        return NULL;
    }
    return tw;
}

static void hm_del_timer_watch(pTHX_ hm_loop *loop, hm_tw *tw) {
    if (!tw || tw->dead) return;
    if (!HM_LOOP_INHERITED(loop))
        loop->be->del_timer(loop->be, tw);
    if (tw->sv) { SvREFCNT_dec(tw->sv); tw->sv = NULL; }
    /* Not freed here: an event naming it may already be in the batch being
     * dispatched (see hm_tw.dead). hm_dispatch skips it; hm_tw_gy_sweep
     * frees it once the outermost loop's batch is done. */
    tw->dead = 1;
    tw->gy_next = loop->tw_gy;
    loop->tw_gy = tw;
}

/* Free the cancelled timers. Only between batches of the OUTERMOST loop
 * run: a nested run (a handler's ->get) sits inside one of the outer
 * batch's events, and the outer batch may still name any of them. */
static void hm_tw_gy_sweep(hm_loop *loop) {
    hm_tw *tw = loop->tw_gy, *n;
    loop->tw_gy = NULL;
    while (tw) { n = tw->gy_next; free(tw); tw = n; }
}

static hm_loop *hm_need_loop(void) {
    if (!hm_cur_loop)
        croak("Hyperman: no event loop is running in this process");
    return hm_cur_loop;
}

/* ---- listener + process model -------------------------------------------- */

/* Create, bind, and listen a non-blocking TCP socket. Returns fd or -1. */
/* Resolve a listen address ONCE, at startup: an IPv4 or IPv6 literal (with
 * or without brackets), a hostname, or nothing for every IPv4 interface.
 * getaddrinfo's first answer is taken. Failure is an error string for the
 * croak and never a silent fallback: a host that did not parse used to bind
 * INADDR_ANY, which exposed the service on every interface for a typo. */
static int hm_resolve(const char *host, int port, int socktype,
                      struct sockaddr_storage *out, socklen_t *outlen,
                      char *err, size_t errlen) {
    struct addrinfo hints, *res = NULL;
    char hbuf[256], pbuf[16];
    const char *h = host;
    int rc;
    if (!h || !*h) h = "0.0.0.0";
    if (h[0] == '[') {
        size_t l = strlen(h);
        if (l < 3 || h[l - 1] != ']' || l - 2 >= sizeof(hbuf)) {
            snprintf(err, errlen, "malformed bracketed address");
            return -1;
        }
        memcpy(hbuf, h + 1, l - 2);
        hbuf[l - 2] = '\0';
        h = hbuf;
    }
    memset(&hints, 0, sizeof(hints));
    hints.ai_family   = AF_UNSPEC;
    hints.ai_socktype = socktype;
    hints.ai_flags    = AI_NUMERICSERV | AI_PASSIVE;
    snprintf(pbuf, sizeof(pbuf), "%d", port);
    rc = getaddrinfo(h, pbuf, &hints, &res);
    if (rc != 0 || !res) {
        snprintf(err, errlen, "%s", rc ? gai_strerror(rc) : "no address");
        if (res) freeaddrinfo(res);
        return -1;
    }
    if (res->ai_addrlen > sizeof(*out)) { freeaddrinfo(res); snprintf(err, errlen, "address too long"); return -1; }
    memcpy(out, res->ai_addr, res->ai_addrlen);
    *outlen = (socklen_t)res->ai_addrlen;
    freeaddrinfo(res);
    return 0;
}

/* A unix-domain address. sun_path is 104 bytes on macOS and 108 on Linux,
 * and a path that does not fit is refused rather than truncated. */
static int hm_resolve_unix(const char *path, struct sockaddr_storage *out,
                           socklen_t *outlen, char *err, size_t errlen) {
#ifdef _WIN32
    (void)path; (void)out; (void)outlen;
    snprintf(err, errlen, "unix-domain listeners are not supported on Windows");
    return -1;
#else
    struct sockaddr_un *un = (struct sockaddr_un *)out;
    size_t l = strlen(path);
    if (l == 0 || l >= sizeof(un->sun_path)) {
        snprintf(err, errlen, "path is empty or longer than %d bytes",
                 (int)sizeof(un->sun_path) - 1);
        return -1;
    }
    memset(out, 0, sizeof(*out));
    un->sun_family = AF_UNIX;
    memcpy(un->sun_path, path, l + 1);
    *outlen = (socklen_t)(offsetof(struct sockaddr_un, sun_path) + l + 1);
    return 0;
#endif
}

/* An IPv6 listener is v6 ONLY, so `::` and `0.0.0.0` can both be listed on
 * one port; without it the second bind fails on Linux and the v4-mapped
 * addresses the dual-stack socket would report differ by platform. */
static void hm_v6only(int fd, const struct sockaddr *sa) {
#ifdef IPV6_V6ONLY
    if (sa->sa_family == AF_INET6) {
        int one = 1;
        hm_os_setsockopt(fd, IPPROTO_IPV6, IPV6_V6ONLY, &one, sizeof(one));
    }
#else
    (void)fd; (void)sa;
#endif
}

static int hm_make_listener(const struct sockaddr *sa, socklen_t salen, int reuseport) {
    int one = 1;
    int fd;
#ifndef _WIN32
    /* A path listener: a socket file left by an earlier run is replaced; a
     * regular file at the path is somebody else's and is refused. */
    if (sa->sa_family == AF_UNIX) {
        const char *p = ((const struct sockaddr_un *)sa)->sun_path;
        struct stat st;
        if (stat(p, &st) == 0) {
            int pfd;
            if (!S_ISSOCK(st.st_mode)) { errno = EEXIST; return -1; }
            /* Somebody answering at the path is a live server, and this
             * would have unlinked its socket from under it (a second
             * instance started by mistake took the path silently). Refused
             * as a TCP bind of a busy port is. */
            pfd = hm_os_socket(AF_UNIX, SOCK_STREAM, 0);
            if (pfd >= 0) {
                int alive = connect(pfd, sa, salen) == 0;
                hm_os_close(pfd);
                if (alive) { errno = EADDRINUSE; return -1; }
            }
            (void)unlink(p);
        }
    }
#endif
    fd = hm_os_socket(sa->sa_family, SOCK_STREAM, 0);
    if (fd < 0) return -1;
#ifndef _WIN32
    /* Not into anything the application execs. A re-exec successor is the
     * one program meant to inherit it, and hm_reexec clears this for that
     * child alone. */
    (void)fcntl(fd, F_SETFD, fcntl(fd, F_GETFD, 0) | FD_CLOEXEC);
#endif
    hm_v6only(fd, sa);
#ifdef _WIN32
    /* SO_REUSEADDR on Windows lets a second bind STEAL a live listener,
     * which is the opposite of the Unix meaning we want here (rebind a
     * TIME_WAIT port). SO_EXCLUSIVEADDRUSE is the flag that buys what
     * SO_REUSEADDR buys everywhere else. */
    hm_os_setsockopt(fd, SOL_SOCKET, SO_EXCLUSIVEADDRUSE, &one, sizeof(one));
#else
    hm_os_setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &one, sizeof(one));
#endif
#ifdef SO_REUSEPORT
    if (reuseport)
        hm_os_setsockopt(fd, SOL_SOCKET, SO_REUSEPORT, &one, sizeof(one));
#else
    (void)reuseport;
#endif
    if (hm_os_bind(fd, sa, salen) < 0) {
        hm_os_close(fd); return -1;
    }
    if (hm_os_listen(fd, SOMAXCONN) < 0) { hm_os_close(fd); return -1; }
    hm_set_nonblock(fd);
    return fd;
}

/* The QUIC listener: the same address as its TCP twin, over UDP. No
 * listen(2) - there is no accept queue, because there is no accept: one
 * socket carries every connection and the Destination Connection ID in each
 * packet says which (hm_quic.h). SO_REUSEPORT is honoured the same way, and
 * carries the same caveat the TCP side does not have: the kernel's UDP
 * reuseport hash is over the 4-tuple, so a client that migrates lands on a
 * different worker than the one holding its connection. That is why
 * migration is deferred rather than half-supported. */
static int hm_make_udp_listener(const struct sockaddr *sa, socklen_t salen, int reuseport) {
    int one = 1;
    int fd = hm_os_socket(sa->sa_family, SOCK_DGRAM, 0);
    if (fd < 0) return -1;
#ifndef _WIN32
    (void)fcntl(fd, F_SETFD, fcntl(fd, F_GETFD, 0) | FD_CLOEXEC);
#endif
    hm_v6only(fd, sa);
#ifdef _WIN32
    hm_os_setsockopt(fd, SOL_SOCKET, SO_EXCLUSIVEADDRUSE, &one, sizeof(one));
#else
    hm_os_setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &one, sizeof(one));
#endif
#ifdef SO_REUSEPORT
    if (reuseport)
        hm_os_setsockopt(fd, SOL_SOCKET, SO_REUSEPORT, &one, sizeof(one));
#else
    (void)reuseport;
#endif
    if (hm_os_bind(fd, sa, salen) < 0) {
        hm_os_close(fd); return -1;
    }
    hm_set_nonblock(fd);
    return fd;
}

/* ---- the supervisor half: POSIX only --------------------------------------
 * Everything from here to the end of hm_run_server's pool branch needs
 * fork(2), waitpid(2) and POSIX signal delivery. Windows has none of the
 * three, and perl's fork emulation is ithreads - N interpreters inside ONE
 * process, sharing the file-scope state this server keeps per process - so
 * a pool there would corrupt, not scale. Windows runs the single-worker
 * in-process path instead (hm_run_server, above the pool branch), and an
 * explicit workers > 1 is refused at boot. */
#ifndef _WIN32

/* Supervisor signal flags: TERM/INT = shut the pool down, HUP/USR2 =
 * recycle workers with zero downtime, USR1 = stats dump. */
static volatile sig_atomic_t hm_sup_term = 0;
static volatile sig_atomic_t hm_sup_hup  = 0;
static volatile sig_atomic_t hm_sup_usr1 = 0;
static volatile sig_atomic_t hm_sup_tick = 0;   /* ALRM: the liveness look */
static volatile sig_atomic_t hm_sup_usr2 = 0;   /* re-exec a successor     */
/* The successor supervisor a USR2 started, until it has taken over (it
 * TERMs us) or died trying (the reaper clears it). */
static pid_t hm_resup_pid = 0;
/* What this process was started as, for the exec: $^X and perl's argv from
 * the first argument on. Copied at BOOT, because `$0 = ...` on Linux writes
 * over the memory PL_origargv points into. */
static char **hm_boot_argv = NULL;
/* Set in a successor: the supervisor that handed its sockets over and is
 * told to drain once this pool is up. */
static pid_t hm_resup_old = 0;
/* An alarm the caller had pending when run() was called: the deadline it asked
 * for, and whether it has come due. The supervisor's tick owns SIGALRM, so the
 * caller's is carried rather than cancelled. */
static time_t hm_sup_alarm_at = 0;
static int    hm_sup_alarmed  = 0;
static void hm_sup_sig(int sig) {
    if      (sig == SIGHUP)              hm_sup_hup  = 1;
    else if (sig == SIGUSR2)             hm_sup_usr2 = 1;
    else if (sig == SIGUSR1)             hm_sup_usr1 = 1;
    else if (sig == SIGALRM)             hm_sup_tick = 1;
    else if (sig == SIGCHLD)             ;   /* no-op: just wakes sigsuspend() */
    else                                 hm_sup_term = 1;
}

/* Wedged is not dead. A worker that is alive but has stopped turning its
 * loop keeps its pid and its row; what stops is the row's `updated` stamp,
 * which the one-second tick moves. Three looks three seconds apart with the
 * stamp unmoved and the pid answering kill(0) is the signal, logged once per
 * episode. The respawn policy is untouched: this says, it does not act. */
#define HM_SUP_TICK_SECS   3
#define HM_SUP_WEDGED_TICKS 3
static uint64_t hm_child_seen[1024];
static int      hm_child_stale[1024];

static void hm_sup_watch_board(void) {
    int i;
    if (!hm_sa_board_live()) return;
    for (i = 0; i < hm_nchildren; i++) {
        sa_sb_reading rd;
        pid_t pid = hm_children[i];
        if (hm_sa_board_row_of((uint64_t)pid, &rd) < 0) { hm_child_stale[i] = 0; continue; }
        if (kill(pid, 0) != 0) continue;      /* gone: the reaper's business */
        if (rd.updated == hm_child_seen[i]) {
            if (++hm_child_stale[i] == HM_SUP_WEDGED_TICKS)
                hm_errlog("Hyperman: worker %d is alive but has not "
                        "updated its scoreboard row for %d seconds: wedged?\n",
                        (int)pid, HM_SUP_TICK_SECS * HM_SUP_WEDGED_TICKS);
        }
        else {
            hm_child_seen[i]  = rd.updated;
            hm_child_stale[i] = 0;
        }
    }
}

#endif /* !_WIN32 - the rest of this section is shared; hm_spawn and the
        * pool branch of hm_run_server re-open the guard below */

/* One listener as configured by run(): its bind address, optional TLS, h2,
 * and https-redirect target. The bound fd and built SSL_CTX are filled in by
 * hm_run_server before the workers fork. */
typedef struct {
    const char *host;
    int         port;
    const char *path;               /* a unix-domain listener instead of host:port */
    int         mode_set, mode;     /* its file mode, when given                 */
    int         inherit;            /* adopt this one from LISTEN_FDS            */
    int         proxy_protocol;     /* every connection opens with a PROXY header */
    const char *tls_cert, *tls_key, *tls_ca;
    int         tls_verify;
    SV         *tls_sni;
    int         http2;
    int         http3;
    int         redirect_https;
    int         fd;                 /* bound fd (parent), or -1 under reuseport */
    int         udp_fd;             /* the QUIC socket, same rules; -1 if no h3 */
    void       *tls_ctx;            /* built SSL_CTX*, or NULL for plain        */
    struct sockaddr_storage sa;     /* host:port resolved once, in the parent;  */
    socklen_t   salen;              /* what every bind, incl. a reuseport
                                     * rebind in a worker, binds             */
} hm_listener_spec;

/* Validate one listener's options at run() time (before any bind/fork). */
static void hm_check_listener(pTHX_ const hm_listener_spec *s) {
    if (s->tls_cert || s->tls_key || s->tls_ca || s->tls_sni || s->tls_verify) {
        if (!(s->tls_cert && s->tls_key))
            croak("Hyperman->run: tls_cert and tls_key must be given together");
        if (!hm_tls_available())
            croak("Hyperman->run: TLS requested but OpenSSL support was not "
                  "built (install libssl-dev and reinstall Hyperman)");
        if (s->tls_verify && !s->tls_ca)
            croak("Hyperman->run: tls_verify needs tls_ca (the CA to verify "
                  "client certificates against)");
    }
    if (s->http2 && !hm_h2_available())
        croak("Hyperman->run: http2 requested but nghttp2 support was not "
              "built (install libnghttp2-dev and reinstall Hyperman)");
    if (s->http3) {
        if (!hm_h3_available())
            croak("Hyperman->run: http3 requested but QUIC support was not "
                  "built (it needs ngtcp2, ngtcp2_crypto_ossl, nghttp3 and "
                  "OpenSSL 3.5 or newer - reinstall Hyperman once they are "
                  "installed)");
        /* There is no cleartext QUIC the way there is h2c: the transport's
         * handshake IS a TLS handshake, so a certificate is not optional. */
        if (!(s->tls_cert && s->tls_key))
            croak("Hyperman->run: http3 needs tls_cert and tls_key (QUIC has "
                  "no cleartext mode)");
    }
    if (s->redirect_https && (s->tls_cert || s->tls_key))
        croak("Hyperman->run: redirect_https on a TLS listener makes no sense");
    if (s->path) {
        if (s->http3)
            croak("Hyperman->run: http3 needs an IP listener; a path listener "
                  "has no UDP twin");
    }
    if (s->proxy_protocol && s->http3)
        warn("Hyperman->run: proxy_protocol applies to the TCP side of this "
             "listener only; QUIC has no byte stream before its handshake and "
             "reports real datagram sources");
}

/* Overlay per-listener options from a `listen => [ {..} ]` hashref onto a spec
 * pre-seeded with the top-level defaults. Unknown keys croak. A bare true
 * redirect_https means "the standard 443". */
static void hm_listener_from_hv(pTHX_ HV *h, hm_listener_spec *s) {
    HE *he;
    hv_iterinit(h);
    while ((he = hv_iternext(h))) {
        STRLEN klen; const char *k = HePV(he, klen); SV *v = HeVAL(he);
        if      (strEQ(k, "port"))     s->port = (int)SvIV(v);
        else if (strEQ(k, "host"))     { if (SvOK(v)) s->host = SvPV_nolen(v); }
        else if (strEQ(k, "path"))     { if (SvOK(v)) s->path = SvPV_nolen(v); }
        else if (strEQ(k, "inherit"))  s->inherit = SvTRUE(v) ? 1 : 0;
        else if (strEQ(k, "proxy_protocol")) s->proxy_protocol = SvTRUE(v) ? 1 : 0;
        else if (strEQ(k, "mode")) {
            if (SvOK(v)) {
                if (SvIOK(v) || SvNOK(v)) s->mode = (int)SvIV(v);
                else {
                    char *end;
                    const char *m = SvPV_nolen(v);
                    s->mode = (int)strtol(m, &end, 8);
                    if (*m == '\0' || *end != '\0')
                        croak("Hyperman->run: mode '%s' is not an octal number", m);
                }
                s->mode_set = 1;
            }
        }
        else if (strEQ(k, "tls_cert")) s->tls_cert = SvOK(v) ? SvPV_nolen(v) : NULL;
        else if (strEQ(k, "tls_key"))  s->tls_key  = SvOK(v) ? SvPV_nolen(v) : NULL;
        else if (strEQ(k, "tls_ca"))   s->tls_ca   = SvOK(v) ? SvPV_nolen(v) : NULL;
        else if (strEQ(k, "tls_sni"))  s->tls_sni  = SvOK(v) ? v : NULL;
        else if (strEQ(k, "http2"))    s->http2 = SvTRUE(v) ? 1 : 0;
        else if (strEQ(k, "http3"))    s->http3 = SvTRUE(v) ? 1 : 0;
        else if (strEQ(k, "redirect_https")) s->redirect_https = (int)SvIV(v);
        else if (strEQ(k, "tls_verify")) {
            const char *m = SvPV_nolen(v);
            if      (strEQ(m, "require"))  s->tls_verify = 2;
            else if (strEQ(m, "optional")) s->tls_verify = 1;
            else if (strEQ(m, "none"))     s->tls_verify = 0;
            else croak("Hyperman->run: tls_verify must be none/optional/require");
        }
        else croak("Hyperman->run: unknown listen option '%s'", k);
    }
    if (s->redirect_https == 1) s->redirect_https = 443;
    /* A path listener is seeded with the top-level host and port like every
     * other spec; the path is the address, so those defaults are dropped
     * rather than read as a contradiction. */
    if (s->path) { s->host = NULL; s->port = 0; }
}

/* Everything a worker needs; one struct so spawn plumbing stays sane. */
typedef struct {
    SV         *app;
    hm_listener_spec *lspecs;       /* one or more listeners                 */
    int         nlspecs;
    double      idle_t, header_t, body_t, request_t, grace;
    UV          body_min_rate;
    int         max_pipe, reuseport, affinity, nworkers;
    int         completion;        /* -1 = say nothing, 0/1 = force        */
    int         compress;
    size_t      compress_min;
    int         compress_level;
    size_t      max_read;          /* request ceiling; 16MB by default    */
    SV         *compress_types;
    UV          max_requests;
    SV         *log_cb;              /* access_log coderef, or NULL          */
    int         log_fd;             /* fast access-log fd, or -1            */
    const char *log_path;           /* access_log file to open (parent), or NULL */
    const char *log_format;         /* access_log_format, NULL = Combined   */
    hm_logtok  *logtok;             /* ... compiled, before the fork         */
    int         nlogtok, log_json, log_wants_t0;
    int         err_fd;             /* error_log fd, or -1 = stderr         */
    const char *err_path;           /* error_log file to open (parent), or NULL */
    /* Privileges, dropped in the parent after every bind and before the
     * first fork (hm_drop_privileges). Names are resolved FIRST, before the
     * bind, so an unknown user is a croak with the port still free. */
    const char *drop_user;          /* user => name or uid, or NULL          */
    const char *drop_group;         /* group => name or gid, or NULL         */
    const char *pid_path;           /* pid_file, or NULL                     */
    int         listen_fds;         /* adopt every listener from LISTEN_FDS  */
    int         umask_set;          /* umask => given                        */
    unsigned    umask_val;
    int         drop_uid_set, drop_gid_set;
    long        drop_uid, drop_gid;
    char        drop_name[64];      /* the user's name, for initgroups      */
    SV         *deny;               /* arrayref of IPs to denylist, or NULL */
    unsigned    deny_cap, rate_cap; /* arena table sizes, 0 = default        */
    unsigned    bus_slots, bus_slot_size, bus_groups;  /* 0 = default        */
    UV          http3_max_conns;    /* QUIC connection ceiling, 0 = off      */
    const char *arena_name;         /* Shared::Arena name, NULL = anonymous  */
    STRLEN      arena_name_len;
    UV          arena_size;         /* bytes, 0 = computed from the tenants  */
    int         distinct_clients;   /* count distinct peers at accept (HLL)  */
} hm_worker_cfg;

/* Populate the loop's listener array from the (already bound) specs. Under
 * reuseport each worker rebinds, so fds are passed in; otherwise they are the
 * parent's inherited fds. Returns 0, or -1 if a reuseport rebind failed. */
static int hm_worker_listeners(hm_loop *loop, const hm_worker_cfg *cfg,
                               const int *fds) {
    int i;
    loop->listeners = (hm_listener *)hm_xcalloc(cfg->nlspecs, sizeof(hm_listener));
    loop->nlisteners = cfg->nlspecs;
    for (i = 0; i < cfg->nlspecs; i++) {
        const hm_listener_spec *s = &cfg->lspecs[i];
        hm_listener *l = &loop->listeners[i];
        l->fd = fds ? fds[i] : s->fd;
        if (l->fd < 0) return -1;
        l->udp_fd = fds ? fds[cfg->nlspecs + i] : s->udp_fd;
        l->is_unix = s->path ? 1 : 0;
        l->proxy_protocol = s->proxy_protocol;
        l->host = strdup(s->path ? s->path
                         : s->host && *s->host ? s->host : "0.0.0.0");
        l->port = s->port;
        l->tls_ctx = s->tls_ctx;
        l->http2 = s->http2;
        l->http3 = s->http3;
        l->redirect_https = s->redirect_https;
        /* Copied, not borrowed: hm_tls_reload frees the context it
         * replaces, and a rebuild has to name the same cert and key. */
        l->tls_cert   = s->tls_cert ? strdup(s->tls_cert) : NULL;
        l->tls_key    = s->tls_key  ? strdup(s->tls_key)  : NULL;
        l->tls_ca     = s->tls_ca   ? strdup(s->tls_ca)   : NULL;
        l->tls_verify = s->tls_verify;
        l->tls_sni    = s->tls_sni ? SvREFCNT_inc(s->tls_sni) : NULL;
        /* Precomputed once here rather than per response: the value never
         * changes for the life of the listener, and a header built per
         * request would be built on the hot path for every request the
         * listener ever serves. */
        if (l->udp_fd >= 0) {
            char b[64];
            int n = snprintf(b, sizeof(b), "h3=\":%d\"; ma=86400", l->port);
            l->altsvc = (n > 0 && n < (int)sizeof(b)) ? strdup(b) : NULL;
        }
    }
    return 0;
}

/* Rebuild this worker's TLS contexts from a fresh SNI map.
 *
 * The listener array is the WORKER'S: hm_worker_listeners above ran after
 * the fork and copied the parent's tls_ctx pointer into it, so swapping
 * that pointer changes this process and nothing else. The listening fd is
 * not touched, so nothing is unbound and no connection is refused;
 * connections already handshook keep the SSL they hold, and the next one
 * this worker accepts uses the new context.
 *
 * NOTHING IS INSTALLED THAT SERVES LESS THAN WHAT IS RUNNING. Two ways a
 * rebuild can come back worse, and both keep the old context:
 *
 *   - the default certificate will not load. It is the one every
 *     hostname falls back to, so a fleet keeps serving the stale one
 *     rather than none.
 *   - a per-host certificate will not load. hm_tls_ctx_build skips it
 *     with a message and still returns a usable default, which is right
 *     at boot but silently drops that domain to the fallback here. So
 *     the built registry is counted against what was asked for, and a
 *     context carrying fewer hosts is thrown away. The cost is that one
 *     corrupt PEM defers everybody's update to the next poll, against
 *     installing a context that quietly stopped serving a domain.
 *
 * Returns the number of listeners rebuilt. */
static int hm_tls_reload(pTHX_ hm_loop *loop, SV *sni) {
    int i, done = 0;
    int given = sni && SvROK(sni) && SvTYPE(SvRV(sni)) == SVt_PVHV;
    if (!loop) return 0;

    for (i = 0; i < loop->nlisteners; i++) {
        hm_listener *l = &loop->listeners[i];
        void *fresh;
        unsigned char tkey[HM_TLS_TKEY_MAX];
        const unsigned char *tk = NULL;
        size_t tklen = 0;
        /* No map given: the listener's own, so a reload called for the
         * default certificate alone keeps every SNI host. Without this the
         * rebuilt context had no registry and the "fewer hosts" refusal
         * below did not apply to it, so every name fell to the default. */
        SV *use = given ? sni : l->tls_sni;
        int want = (use && SvROK(use) && SvTYPE(SvRV(use)) == SVt_PVHV)
                 ? (int)HvUSEDKEYS((HV *)SvRV(use)) : -1;
        if (!l->tls_ctx || !l->tls_cert || !l->tls_key) continue;  /* plain */

        /* Carry the running context's session-ticket key into the new one.
         * The boot-time contexts are built before the fork, so every worker
         * starts out able to decrypt every other worker's tickets - but this
         * reload runs independently in each of them, and SSL_CTX_new mints a
         * fresh random key. Left alone, the first rotation would leave a
         * ticket issued by one worker undecryptable by its siblings, and
         * every resumption a client attempted would quietly become a full
         * handshake: the signature and key exchange that tickets exist to
         * avoid, on a fleet that rotates certificates continuously. */
        if (hm_tls_get_ticket_key(l->tls_ctx, tkey, &tklen)) tk = tkey;

        fresh = hm_tls_ctx_build(aTHX_ l->tls_cert, l->tls_key, l->tls_ca,
                                 l->tls_verify, use, l->http2, tk, tklen);
        if (!fresh) continue;                   /* keep what we are serving */

        if (want > 0 && hm_tls_sni_count(fresh) < want) {
            hm_errlog("Hyperman TLS: reload built %d of %d SNI hosts; "
                            "keeping the running certificates\n",
                    hm_tls_sni_count(fresh), want);
            hm_tls_ctx_free(fresh);
            continue;
        }

        /* The QUIC context serves the SAME certificate over the same origin,
         * so it is rebuilt with the TCP one and the two are swapped together
         * or not at all. Swapping only the TCP side leaves a fleet serving a
         * fresh certificate over TCP and a stale one over QUIC - a mismatch
         * no TCP-only monitor can see, on the transport a browser prefers.
         *
         * The new QUIC context is built BEFORE either is installed, so a
         * failure to build it keeps both of the running pair rather than
         * leaving a half-swapped listener. */
        if (l->udp_fd >= 0 && l->quic) {
            void *qfresh = hm_tls_quic_ctx_build(l->tls_cert, l->tls_key,
                                                 l->tls_ca, l->tls_verify,
                                                 tk, tklen);
            if (!qfresh) {
                hm_errlog("Hyperman TLS: reload could not rebuild the "
                                "QUIC context; keeping both running "
                                "certificates\n");
                hm_tls_ctx_free(fresh);
                continue;
            }
            hm_quic_ctx_swap(aTHX_ l, qfresh);
        }

        hm_tls_ctx_free(l->tls_ctx);
        l->tls_ctx = fresh;
        done++;
    }
    return done;
}

/* The bus wakeup, on this worker's loop.
 *
 * Lives here rather than in hm_sa_bus.h because it is the one part that needs
 * both halves: hm_sa_bus.h deliberately knows nothing about the server, and
 * the loop knows nothing about the ring.
 *
 * The callback MUST NOT CROAK. It is called from the event loop with no Perl
 * frame around it, and a die from a subscriber would unwind through the loop
 * and take the worker with it - so the dispatch below is the only thing here,
 * and anything Perl-facing wraps itself in G_EVAL before it gets this far. */
static void hm_bus_wake_cb(pTHX_ int fd, int mask, void *ud) {
    PERL_UNUSED_ARG(fd);
    PERL_UNUSED_ARG(mask);
    PERL_UNUSED_ARG(ud);
    PERL_UNUSED_CONTEXT;
    /* Empty the pipe and clear the flag BEFORE dispatching, so a publish that
     * lands while we are dispatching sets it again and pokes afresh, rather
     * than being folded into a wakeup that has already been handled. The
     * order inside the ring's wake_drained matters too - see hm_sa_bus.h. */
    hm_sa_bus_waker_drained();
    (void)hm_sa_bus_dispatch();
}

/* The one-second tick: the loop's counters into this worker's scoreboard
 * row in one seqlock bracket, a heartbeat on the peer row, and the next
 * tick armed. A C timer is one-shot and freed on fire, so re-arming here is
 * the whole of the repetition. Stops with the loop: a draining worker keeps
 * mirroring until its last connection closes, and nothing here holds the
 * loop open once it wants to end. */
static void hm_board_tick(pTHX_ void *ud) {
    hm_loop *loop = (hm_loop *)ud;
    hm_sa_board_mirror((uint64_t)loop->requests, (uint64_t)loop->accepts,
                       (uint64_t)loop->denied, loop->nconns,
                       (uint64_t)loop->bytes_out, (uint64_t)loop->datagrams,
                       (uint64_t)loop->h3_requests);
    if (HM_SA && hm_sa_region) HM_SA->beat(hm_sa_region);
    if (!loop->stopping)
        (void)hm_add_timer_watch_c(loop, 1.0, hm_board_tick, loop);
}

/* The polling fallback's tick: drain the ring, re-arm. */
static void hm_bus_poll_cb(pTHX_ void *ud) {
    hm_loop *loop = (hm_loop *)ud;
    (void)hm_sa_bus_dispatch();
    if (!loop->stop) (void)hm_add_timer_watch_c(loop, 0.05, hm_bus_poll_cb, loop);
}

static void hm_bus_worker_attach(pTHX_ hm_loop *loop) {
    int fd;
    if (!hm_sa_bus_live()) return;
    /* A worker inherited the parent's cursors along with everything else, and
     * a cursor is a position in a stream this process has not been reading.
     * Left alone it either replays what the parent already handled or skips
     * what it has not. From now on. */
    hm_sa_bus_reset_cursors();

    /* THE LAST WORD ON WHETHER THIS PROCESS CAN BE WOKEN.
     *
     * hm_spawn asks for a slot by worker index, which is what keeps two
     * workers off one descriptor. It can come back empty-handed: the index it
     * asked for may still be held by a worker that is draining after a HUP,
     * and single-worker mode never goes through hm_spawn at all. Either way
     * the process ends up with no descriptor.
     *
     * Before this, that was the end of it - no watch was installed and this
     * worker never dispatched again, so a published invalidation or room
     * broadcast reached every worker but this one, for as long as it ran, with
     * nothing in any statistic to say so. Single-worker mode never delivered
     * to its own subscribers at all.
     *
     * So take whatever is going rather than go deaf. Which slot a worker holds
     * has never mattered; holding one is the whole of it. */
    fd = hm_sa_bus_waker_fd();
    if (fd < 0) {
        (void)hm_sa_bus_waker_take(-1);
        fd = hm_sa_bus_waker_fd();
    }
    if (fd < 0) {
        /* No descriptor: the slots were all held, or this process attached
         * the arena by name (a re-exec successor's pool does) and the pipes
         * in it belong to another process. Poll the ring instead, every
         * fifty milliseconds. Slower to notice a message than a poke, never
         * deaf. */
        hm_errlog("Hyperman: worker %d has no wakeup descriptor; polling the "
                  "bus every 50ms instead", hm_os_getpid());
        (void)hm_add_timer_watch_c(loop, 0.05, hm_bus_poll_cb, loop);
        return;
    }
    hm_add_io_watch_c(aTHX_ loop, fd, HM_EV_READ, hm_bus_wake_cb, NULL);
    /* Anything published between the fork and this attach is already on the
     * ring with no poke coming, because nothing was watching to be poked. */
    (void)hm_sa_bus_dispatch();
}

static void hm_worker(pTHX_ const hm_worker_cfg *cfg, const int *fds) {
    hm_loop *loop = hm_loop_new(aTHX_ NULL);
    if (!loop) croak("Hyperman: cannot create event loop");
    if (cfg->idle_t   > 0) loop->idle_timeout   = cfg->idle_t;
    if (cfg->header_t > 0) loop->header_timeout = cfg->header_t;
    if (cfg->body_t   > 0) loop->body_timeout   = cfg->body_t;
    if (cfg->request_t > 0) loop->request_timeout = cfg->request_t;
    if (cfg->body_min_rate) loop->body_min_rate  = cfg->body_min_rate;
    if (cfg->max_pipe > 0) loop->max_pipeline   = cfg->max_pipe;
    if (cfg->grace    > 0) loop->shutdown_grace = cfg->grace;
    loop->max_requests = cfg->max_requests;
    /* Only when the caller actually said so: -1 leaves whatever the loop
     * decided for itself from the backend and the environment. */
    if (cfg->completion >= 0)
        loop->completion = (cfg->completion && loop->be->submit_recv) ? 1 : 0;
    loop->compress      = cfg->compress;
    if (cfg->compress_min) loop->compress_min = cfg->compress_min;
    if (cfg->compress_level) loop->compress_level = cfg->compress_level;
    if (cfg->max_read) loop->max_read = cfg->max_read;
    loop->http3_max_conns = cfg->http3_max_conns;
    loop->compress_types = cfg->compress_types
                           ? SvREFCNT_inc(cfg->compress_types) : NULL;
    loop->logtok       = cfg->logtok;        /* compiled once, in the parent */
    loop->nlogtok      = cfg->nlogtok;
    loop->log_json     = cfg->log_json;
    loop->log_wants_t0 = cfg->log_wants_t0;
    if (hm_worker_listeners(loop, cfg, fds) < 0) {
        hm_loop_free(aTHX_ loop);
        _exit(1);
    }
    if (cfg->log_fd >= 0)
        loop->log_fd = cfg->log_fd;               /* fast C writer wins */
    else if (cfg->log_cb && SvOK(cfg->log_cb))
        loop->log_cb = SvREFCNT_inc(cfg->log_cb);
    hm_attach_server(aTHX_ loop, cfg->app);
    /* v4 on_worker_start: the loop exists and has not started turning, and in
     * a prefork server this is already the child. The one moment a consumer
     * can attach something loop-bound and have it belong to the process that
     * will actually serve. Fires here rather than at either call site so the
     * single-worker case, which never forks, gets it too. */
    hm_worker_hook_fire(aTHX_ (void *)loop);

    /* The bus wakeup. The descriptors were made before the fork; this worker
     * takes the one that is its own and puts it on the loop, so a publish from
     * a sibling returns this loop from epoll with the message already on the
     * ring rather than leaving it to be found whenever somebody next looks.
     *
     * After hm_worker_hook_fire, so an application's own on_worker_start has
     * already run and anything it subscribed is registered before the first
     * wakeup can arrive. */
    hm_bus_worker_attach(aTHX_ loop);
    /* A peer slot of this worker's own in the Shared::Arena, keyed on the
     * pid it has now rather than the one it inherited. */
    hm_sa_worker_join();
    /* This worker's scoreboard row, mirrored now and then once a second.
     * The tick also beats the peer row, so a worker that only ever receives
     * on the bus never looks dead to the ring's hole escalation. */
    if (hm_sa_board_live() && hm_sa_board_take() >= 0)
        hm_board_tick(aTHX_ loop);

    hm_loop_run(aTHX_ loop, NULL);
    hm_loop_free(aTHX_ loop);
}

#ifndef _WIN32
/* Fork one worker. With reuseport each worker binds its own listeners; with
 * affinity (Linux) worker widx is pinned to core widx % ncpu. */
static pid_t hm_spawn(pTHX_ const hm_worker_cfg *cfg, int widx) {
    pid_t pid = fork();
    if (pid == 0) {
        int  stackfds[8];
        int *fds = NULL;

        /* A RESPAWNED worker is forked from inside the supervisor's loop,
         * where the pool's signals are handled by hm_sup_sig and BLOCKED.
         * The child inherits both. Until the worker's own loop has taken
         * over its signals, a TERM landing here would run the supervisor's
         * handler and set a flag nobody in this process reads: the signal
         * is swallowed, the worker never learns the pool is shutting down,
         * and the supervisor waits for it for ever. Found by a test that
         * killed a worker and sent TERM the moment its replacement had a
         * scoreboard row. Default dispositions and an empty mask, so a
         * TERM in that window ends the child, which is what TERM means. */
        {
            sigset_t none;
            sigemptyset(&none);
            signal(SIGTERM, SIG_DFL); signal(SIGINT,  SIG_DFL);
            signal(SIGHUP,  SIG_DFL); signal(SIGUSR1, SIG_DFL);
            signal(SIGUSR2, SIG_DFL); signal(SIGCHLD, SIG_DFL);
            signal(SIGALRM, SIG_DFL);
            alarm(0);
            sigprocmask(SIG_SETMASK, &none, NULL);
        }

        /* Tell perl it has been forked. $$ is a plain SV that perl only
         * refreshes inside pp_fork; forking from C here happens behind its
         * back, so without this the worker keeps reporting the supervisor's
         * pid - and POSIX::getpid is `sub getpid { $$ }`, so that reads wrong
         * too. Anything in the application that names a log line, a temp file
         * or a pid file after $$ then collides across the whole pool. This is
         * what pp_fork itself does in the child. */
        {
            GV *pidgv = gv_fetchpvs("$", GV_ADD|GV_NOTQUAL, SVt_PV);
            if (pidgv) {
                SvREADONLY_off(GvSV(pidgv));
                sv_setiv(GvSV(pidgv), (IV)getpid());
                SvREADONLY_on(GvSV(pidgv));
            }
        }

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
            int i, n = cfg->nlspecs;
            /* Two descriptors per listener now, TCP in the first half and
             * QUIC in the second, so hm_worker_listeners reads fds[i] and
             * fds[n + i]. */
            fds = 2 * n <= (int)(sizeof(stackfds)/sizeof(stackfds[0]))
                  ? stackfds
                  : (int *)hm_xmalloc(sizeof(int) * 2 * n);
            for (i = 0; i < n; i++) {
                fds[i] = hm_make_listener((struct sockaddr *)&cfg->lspecs[i].sa,
                                          cfg->lspecs[i].salen, 1);
                if (fds[i] < 0) _exit(1);
                fds[n + i] = -1;
                if (cfg->lspecs[i].http3) {
                    fds[n + i] = hm_make_udp_listener((struct sockaddr *)&cfg->lspecs[i].sa,
                                                      cfg->lspecs[i].salen, 1);
                    if (fds[n + i] < 0) _exit(1);
                }
            }
        }
        /* This child's own waker slot, claimed before hm_worker so the
         * attach below finds it. Index by worker number, so two workers never
         * share a descriptor. */
        (void)hm_sa_bus_waker_take(widx);
        hm_worker(aTHX_ cfg, fds);
        _exit(0);
    }
    return pid;
}
#endif /* !_WIN32 */

/* The full server: validate + bind, then either run in-process (1 worker)
 * or supervise a pool (respawn with backoff, HUP/USR2 recycle, USR1 stats,
 * TERM/INT bounded drain). */
/* ---- privileges and the pid file ----------------------------------------- */

static int hm_all_digits(const char *s) {
    if (!*s) return 0;
    for (; *s; s++) if (*s < '0' || *s > '9') return 0;
    return 1;
}

/* Turn user/group names into ids. Called before anything is bound: a typo
 * in `user` must not leave a server listening as root. */
static void hm_resolve_drop(pTHX_ hm_worker_cfg *cfg) {
    if (!cfg->drop_user && !cfg->drop_group && !cfg->umask_set && !cfg->pid_path)
        return;
#ifdef _WIN32
    croak("Hyperman->run: user, group, umask and pid_file are not supported "
          "on Windows");
#else
    cfg->drop_name[0] = '\0';
    if (cfg->drop_user) {
        if (hm_all_digits(cfg->drop_user)) {
            struct passwd *pw;
            cfg->drop_uid = atol(cfg->drop_user);
            cfg->drop_uid_set = 1;
            pw = getpwuid((uid_t)cfg->drop_uid);
            if (pw) {
                strncpy(cfg->drop_name, pw->pw_name, sizeof(cfg->drop_name) - 1);
                if (!cfg->drop_group) { cfg->drop_gid = (long)pw->pw_gid; cfg->drop_gid_set = 1; }
            } else if (!cfg->drop_group) {
                /* No entry to take a group from: without one the workers
                 * would keep gid 0 and root's supplementary groups behind a
                 * harmless-looking uid. */
                croak("Hyperman->run: user %s has no passwd entry; name a "
                      "group => as well", cfg->drop_user);
            }
        } else {
            struct passwd *pw = getpwnam(cfg->drop_user);
            if (!pw) croak("Hyperman->run: user '%s': no such user", cfg->drop_user);
            cfg->drop_uid = (long)pw->pw_uid;
            cfg->drop_uid_set = 1;
            strncpy(cfg->drop_name, pw->pw_name, sizeof(cfg->drop_name) - 1);
            if (!cfg->drop_group) { cfg->drop_gid = (long)pw->pw_gid; cfg->drop_gid_set = 1; }
        }
    }
    if (cfg->drop_group) {
        if (hm_all_digits(cfg->drop_group)) {
            cfg->drop_gid = atol(cfg->drop_group);
        } else {
            struct group *gr = getgrnam(cfg->drop_group);
            if (!gr) croak("Hyperman->run: group '%s': no such group", cfg->drop_group);
            cfg->drop_gid = (long)gr->gr_gid;
        }
        cfg->drop_gid_set = 1;
    }
#endif
}

/* Group first, then the user: once the uid is gone the gid cannot follow.
 * Each step is checked and a failure CROAKS - a server that could not drop
 * must not go on serving as root as if it had. */
static void hm_drop_privileges(pTHX_ const hm_worker_cfg *cfg) {
#ifndef _WIN32
    if (cfg->umask_set) umask((mode_t)cfg->umask_val);
    /* Not root: a re-exec successor forked by a supervisor that had already
     * dropped. It cannot change its ids and need not, if it already has the
     * ones asked for; anything else is refused, as before. */
    if (geteuid() != 0 && (cfg->drop_uid_set || cfg->drop_gid_set)) {
        if (cfg->drop_uid_set && (getuid() != (uid_t)cfg->drop_uid
                                  || geteuid() != (uid_t)cfg->drop_uid))
            croak("Hyperman->run: not root, and not uid %ld either: cannot "
                  "become user '%s'", cfg->drop_uid, cfg->drop_user);
        if (cfg->drop_gid_set && getegid() != (gid_t)cfg->drop_gid)
            croak("Hyperman->run: not root, and not gid %ld either: cannot "
                  "change group", cfg->drop_gid);
        return;
    }
    if (cfg->drop_gid_set) {
        if (cfg->drop_name[0]) {
            if (initgroups(cfg->drop_name, (gid_t)cfg->drop_gid) < 0)
                croak("Hyperman->run: initgroups(%s): %s", cfg->drop_name, strerror(errno));
        } else {
            gid_t g = (gid_t)cfg->drop_gid;
            if (setgroups(1, &g) < 0)
                croak("Hyperman->run: setgroups: %s", strerror(errno));
        }
        if (setgid((gid_t)cfg->drop_gid) < 0)
            croak("Hyperman->run: setgid(%ld): %s", cfg->drop_gid, strerror(errno));
    }
    if (cfg->drop_uid_set) {
        if (setuid((uid_t)cfg->drop_uid) < 0)
            croak("Hyperman->run: setuid(%ld): %s", cfg->drop_uid, strerror(errno));
        if (cfg->drop_uid != 0 && (getuid() != (uid_t)cfg->drop_uid
                                   || geteuid() != (uid_t)cfg->drop_uid))
            croak("Hyperman->run: still not uid %ld after setuid", cfg->drop_uid);
    }
#else
    (void)cfg;
#endif
}

/* The pid file is written whole and renamed into place, so a reader never
 * sees it empty, and removed at exit ONLY if it still holds this pid: two
 * supervisors overlap during a re-exec reload, and the one leaving must not
 * take the other's file with it. */
#ifndef O_NOFOLLOW
#define O_NOFOLLOW 0
#endif
/* loud: a failure croaks (boot). Quiet: -1 and a log line, for the
 * supervisor re-asserting its own pid after a successor died. */
static int hm_write_pidfile_(pTHX_ const hm_worker_cfg *cfg, int loud) {
    const char *path = cfg->pid_path;
    char tmp[1024], num[32];
    int fd = -1, n, tries, in_place = 0;
    if (!path) return 0;
    /* The temporary is created EXCLUSIVELY and never through a symlink: it
     * is written as root, before the drop, in a directory others may be
     * able to write to, and a predictable name opened with O_TRUNC was an
     * invitation to point it at a file of theirs. The suffix is random too,
     * so a planted name is not even a denial of service. */
    for (tries = 0; tries < 8 && fd < 0; tries++) {
        unsigned long r = (unsigned long)(hm_now_ns() ^ ((uint64_t)hm_os_getpid() << 20));
        n = snprintf(tmp, sizeof(tmp), "%s.%lx.tmp", path, r + (unsigned long)tries * 7919UL);
        if (n <= 0 || n >= (int)sizeof(tmp))
            croak("Hyperman->run: pid_file path too long");
        fd = hm_os_open_file(tmp, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0644);
        if (fd < 0 && errno != EEXIST) break;
    }
    if (fd < 0 && (errno == EACCES || errno == EPERM) && geteuid() != 0) {
        /* A re-exec successor already running as the dropped user, in a
         * directory only root may create in (/run): the file itself was
         * chowned to that user when root wrote it, so it is rewritten in
         * place. Not atomic - a reader can catch it empty - but a pid file
         * the successor cannot update at all named a dead process. */
        fd = hm_os_open_file(path, O_WRONLY | O_TRUNC | O_NOFOLLOW | O_CLOEXEC, 0644);
        in_place = 1;
    }
    if (fd < 0) {
        if (loud) croak("Hyperman->run: pid_file '%s': %s", in_place ? path : tmp,
                        strerror(errno));
        hm_errlog("Hyperman: pid_file '%s': %s\n", path, strerror(errno));
        return -1;
    }
    n = (int)hm_itoa(num, (long)hm_os_getpid());
    num[n++] = '\n';
    if (hm_os_write_file(fd, num, (size_t)n) != n) {
        int e = errno;
        hm_os_close(fd);
        if (!in_place) (void)unlink(tmp);
        if (loud) croak("Hyperman->run: pid_file '%s': write: %s", path, strerror(e));
        hm_errlog("Hyperman: pid_file '%s': write: %s\n", path, strerror(e));
        return -1;
    }
#ifndef _WIN32
    /* Owned by the user the server will run as, so the successor of a
     * re-exec (born dropped) and the exit path can both still write it. */
    if (cfg->drop_uid_set && geteuid() == 0)
        (void)fchown(fd, (uid_t)cfg->drop_uid,
                     cfg->drop_gid_set ? (gid_t)cfg->drop_gid : (gid_t)-1);
#endif
    hm_os_close(fd);
    if (in_place) return 0;
    if (rename(tmp, path) < 0) {
        int e = errno;
        (void)unlink(tmp);
        if (loud) croak("Hyperman->run: pid_file '%s': rename: %s", path, strerror(e));
        hm_errlog("Hyperman: pid_file '%s': rename: %s\n", path, strerror(e));
        return -1;
    }
    return 0;
}
static void hm_write_pidfile(pTHX_ const hm_worker_cfg *cfg) {
    (void)hm_write_pidfile_(aTHX_ cfg, 1);
}

/* Removed at exit if it still holds this pid. A process that dropped
 * privileges may not unlink in the directory any more (/run is root's);
 * then the file is emptied instead, which is what a reader should take as
 * "not running", where a stale pid is a live lie. */
static void hm_unlink_pidfile(const char *path) {
    char buf[32];
    int fd, n;
    if (!path) return;
    fd = hm_os_open_file(path, O_RDONLY | O_NOFOLLOW, 0);
    if (fd < 0) return;
    n = (int)read(fd, buf, sizeof(buf) - 1);
    hm_os_close(fd);
    if (n <= 0) return;
    buf[n] = '\0';
    if (atol(buf) != (long)hm_os_getpid()) return;
    if (unlink(path) == 0) return;
    if (errno == EACCES || errno == EPERM) {
        fd = hm_os_open_file(path, O_WRONLY | O_TRUNC | O_NOFOLLOW, 0);
        if (fd >= 0) hm_os_close(fd);
    }
}

/* Remove a variable from the C environment AND perl's %ENV, which is a hash
 * of its own, filled at startup: unsetenv alone leaves the application
 * reading the old value from the hash. Deleting through the hash updates
 * the C side via its magic; the explicit unsetenv covers a perl built
 * without that. */
static void hm_env_unset(pTHX_ const char *name) {
    HV *penv = GvHV(PL_envgv);
    if (penv) (void)hv_delete(penv, name, (I32)strlen(name), G_DISCARD);
#ifndef _WIN32
    unsetenv(name);
#endif
}

/* Socket activation: a service manager that bound the sockets hands them
 * over as fds 3.., naming the count in LISTEN_FDS and this pid in
 * LISTEN_PID. Specs marked `inherit` (or all of them under listen_fds) take
 * them in order instead of binding. Each one is checked to be a listening
 * socket of the family the spec resolved to, and both variables are removed
 * at once so no worker - and no server an application forks - adopts them
 * again. The same helper will seat a re-exec successor (08). */
static void hm_adopt_fds(pTHX_ hm_worker_cfg *cfg) {
    const char *nfds = getenv("LISTEN_FDS"), *lpid = getenv("LISTEN_PID");
    int i, n, next = 3, want = 0;
    /* A spec that already holds a socket was seated by hm_adopt_env: a
     * re-exec successor of a socket-activated server. LISTEN_FDS was
     * removed from the environment at the first boot, so counting those
     * specs made every USR2 under systemd croak "not set". */
    for (i = 0; i < cfg->nlspecs; i++)
        if ((cfg->listen_fds || cfg->lspecs[i].inherit) && cfg->lspecs[i].fd < 0)
            want++;
    if (!want) return;
#ifdef _WIN32
    croak("Hyperman->run: socket activation is not supported on Windows");
#else
    if (!nfds || !lpid)
        croak("Hyperman->run: a listener asks to inherit a socket but LISTEN_FDS "
              "and LISTEN_PID are not set");
    if (atol(lpid) != (long)hm_os_getpid())
        croak("Hyperman->run: LISTEN_PID is %s, this is %d: the sockets were "
              "not handed to this process", lpid, hm_os_getpid());
    if (cfg->reuseport)
        croak("Hyperman->run: an inherited socket cannot be rebound per worker; "
              "drop reuseport");
    n = atoi(nfds);
    for (i = 0; i < cfg->nlspecs; i++) {
        hm_listener_spec *s = &cfg->lspecs[i];
        struct sockaddr_storage got;
        socklen_t gl = sizeof(got);
        int fd, acc = 0;
        socklen_t al = sizeof(acc);
        if (!(cfg->listen_fds || s->inherit) || s->fd >= 0) continue;
        if (next - 3 >= n)
            croak("Hyperman->run: LISTEN_FDS=%d but listener %d wants one too", n, i);
        fd = next++;
        if (s->http3)
            croak("Hyperman->run: an inherited listener cannot carry http3");
        if (getsockname(fd, (struct sockaddr *)&got, &gl) < 0)
            croak("Hyperman->run: inherited fd %d: getsockname: %s", fd, strerror(errno));
        if (got.ss_family != s->sa.ss_family)
            croak("Hyperman->run: inherited fd %d is address family %d, listener %d "
                  "resolved to %d", fd, (int)got.ss_family, i, (int)s->sa.ss_family);
        if (getsockopt(fd, SOL_SOCKET, SO_ACCEPTCONN, &acc, &al) == 0 && !acc)
            croak("Hyperman->run: inherited fd %d is not a listening socket", fd);
        hm_set_nonblock(fd);
        /* As a bound listener is (hm_make_listener): not into anything the
         * application execs; hm_reexec clears it for the successor alone. */
        (void)fcntl(fd, F_SETFD, fcntl(fd, F_GETFD, 0) | FD_CLOEXEC);
        s->fd = fd;
    }
    hm_env_unset(aTHX_ "LISTEN_FDS");
    hm_env_unset(aTHX_ "LISTEN_PID");
    hm_env_unset(aTHX_ "LISTEN_FDNAMES");
#endif
}

/* ---- re-exec reload (USR2) -------------------------------------------------
 *
 * HUP reforks the pool from this process, which still holds the application
 * as it was compiled at boot. USR2 starts a NEW supervisor - a fresh perl, a
 * fresh compile of the application - that takes the bound listeners over,
 * forks its own pool, and only then asks this one to drain. The listen fds
 * are held by one process or the other the whole time, so no connection is
 * refused. A successor that fails to start changes nothing here; this
 * supervisor keeps serving and says so.
 *
 * What crosses the exec: the listener fds, named in HYPERMAN_REEXEC by the
 * host:port (or path) each was bound for, so the successor's configuration
 * may reorder or add listeners; the arena NAME, when there is one, so both
 * pools share the one arena during the overlap; and the old supervisor's
 * pid, to TERM. An anonymous arena is not shared: it is a private mapping
 * with no name to attach to, and the successor starts a fresh one (the
 * denylist and the rate counters begin again at the handoff). */

#ifndef _WIN32
static void hm_reexec(pTHX_ const hm_worker_cfg *cfg, const sigset_t *orig) {
    char env[4096];
    size_t n = 0;
    int i, k;
    pid_t pid;
    SV *perl;
    if (hm_resup_pid > 0 && kill(hm_resup_pid, 0) == 0) {
        hm_errlog("Hyperman: USR2 ignored: successor %d is still starting",
                  (int)hm_resup_pid);
        return;
    }
    if (!hm_boot_argv || !hm_boot_argv[0]) {
        hm_errlog("Hyperman: USR2 ignored: no argv to re-exec with");
        return;
    }
    k = snprintf(env + n, sizeof(env) - n, "sup=%d", hm_os_getpid());
    if (k < 0 || (size_t)k >= sizeof(env) - n) return;
    n += (size_t)k;
    if (cfg->arena_name && cfg->arena_name_len) {
        k = snprintf(env + n, sizeof(env) - n, ";arena=%.*s",
                     (int)cfg->arena_name_len, cfg->arena_name);
        if (k < 0 || (size_t)k >= sizeof(env) - n) {
            hm_errlog("Hyperman: USR2 ignored: the arena name does not fit the "
                      "handover environment");
            return;
        }
        n += (size_t)k;
    }
    for (i = 0; i < cfg->nlspecs; i++) {
        const hm_listener_spec *s = &cfg->lspecs[i];
        if (s->fd < 0) continue;                  /* reuseport: nothing held */
        if (s->path)
            k = snprintf(env + n, sizeof(env) - n, ";u=%s|%d", s->path, s->fd);
        else
            k = snprintf(env + n, sizeof(env) - n, ";l=%s|%d|%d|%d",
                         s->host && *s->host ? s->host : "0.0.0.0", s->port,
                         s->fd, s->udp_fd);
        if (k < 0 || (size_t)k >= sizeof(env) - n) {
            hm_errlog("Hyperman: USR2 ignored: too many listeners to hand over");
            return;
        }
        n += (size_t)k;
    }
    perl = get_sv("\030", 0);                     /* $^X */
    if (!perl || !SvOK(perl)) {
        hm_errlog("Hyperman: USR2 ignored: $^X is not set");
        return;
    }
    pid = fork();
    if (pid < 0) {
        hm_errlog("Hyperman: USR2: fork: %s", strerror(errno));
        return;
    }
    if (pid == 0) {
        /* The supervisor runs with its signals BLOCKED and the mask survives
         * exec, as does a pending alarm: a successor born with either would
         * never wake in its own sigsuspend. */
        sigprocmask(SIG_SETMASK, orig, NULL);
        alarm(0);
        signal(SIGTERM, SIG_DFL); signal(SIGINT,  SIG_DFL);
        signal(SIGHUP,  SIG_DFL); signal(SIGUSR1, SIG_DFL);
        signal(SIGUSR2, SIG_DFL); signal(SIGCHLD, SIG_DFL);
        signal(SIGALRM, SIG_DFL);
        for (i = 0; i < cfg->nlspecs; i++) {
            const hm_listener_spec *s = &cfg->lspecs[i];
            if (s->fd >= 0)     (void)fcntl(s->fd,     F_SETFD, 0);
            if (s->udp_fd >= 0) (void)fcntl(s->udp_fd, F_SETFD, 0);
        }
        setenv("HYPERMAN_REEXEC", env, 1);
        execv(SvPV_nolen(perl), hm_boot_argv);
        _exit(127);
    }
    hm_resup_pid = pid;
    hm_errlog("Hyperman: USR2: successor %d started; serving until it takes over",
              (int)pid);
}

/* The successor's half: HYPERMAN_REEXEC names the sockets and the arena.
 * Runs after the addresses are resolved and before anything binds. */
static void hm_adopt_env(pTHX_ hm_worker_cfg *cfg) {
    const char *raw = getenv("HYPERMAN_REEXEC");
    char *buf, *tok, *save = NULL;
    int i;
    if (!raw || !*raw) return;
    buf = strdup(raw);
    if (!buf) return;
    hm_env_unset(aTHX_ "HYPERMAN_REEXEC");
    for (i = 0; i < cfg->nlspecs; i++) { cfg->lspecs[i].fd = -1; cfg->lspecs[i].udp_fd = -1; }
    for (tok = strtok_r(buf, ";", &save); tok; tok = strtok_r(NULL, ";", &save)) {
        if (strncmp(tok, "sup=", 4) == 0) {
            hm_resup_old = (pid_t)atol(tok + 4);
        } else if (strncmp(tok, "arena=", 6) == 0) {
            if (!cfg->arena_name || !cfg->arena_name_len) {
                cfg->arena_name     = strdup(tok + 6);    /* process lifetime */
                cfg->arena_name_len = strlen(tok + 6);
            }
        } else if (strncmp(tok, "l=", 2) == 0 || strncmp(tok, "u=", 2) == 0) {
            int unix_ = tok[0] == 'u';
            char *f1, *f2, *f3, *f4, *s2 = NULL;
            int fd = -1, udp = -1, port = 0, matched = 0;
            const char *name;
            f1 = strtok_r(tok + 2, "|", &s2);
            f2 = strtok_r(NULL, "|", &s2);
            f3 = strtok_r(NULL, "|", &s2);
            f4 = strtok_r(NULL, "|", &s2);
            if (!f1 || !f2) continue;
            name = f1;
            if (unix_) { fd = atoi(f2); }
            else { if (!f3) continue; port = atoi(f2); fd = atoi(f3); udp = f4 ? atoi(f4) : -1; }
            /* reuseport pools rebind per worker and hold nothing to adopt */
            if (!cfg->reuseport) {
                for (i = 0; i < cfg->nlspecs; i++) {
                    hm_listener_spec *s = &cfg->lspecs[i];
                    if (s->fd >= 0) continue;
                    if (unix_ ? (s->path && strcmp(s->path, name) == 0)
                              : (!s->path && s->port == port
                                 && strcmp(s->host && *s->host ? s->host : "0.0.0.0", name) == 0)) {
                        struct sockaddr_storage got;
                        socklen_t gl = sizeof(got);
                        int acc = 0;
                        socklen_t al = sizeof(acc);
                        if (getsockname(fd, (struct sockaddr *)&got, &gl) < 0
                            || got.ss_family != s->sa.ss_family
                            || (getsockopt(fd, SOL_SOCKET, SO_ACCEPTCONN, &acc, &al) == 0 && !acc))
                            croak("Hyperman->run: re-exec: handed fd %d for %s is not "
                                  "the listener it was said to be", fd, name);
                        hm_set_nonblock(fd);
                        (void)fcntl(fd, F_SETFD, fcntl(fd, F_GETFD, 0) | FD_CLOEXEC);
                        s->fd = fd;
                        if (udp >= 0 && s->http3) {
                            hm_set_nonblock(udp);
                            (void)fcntl(udp, F_SETFD, fcntl(udp, F_GETFD, 0) | FD_CLOEXEC);
                            s->udp_fd = udp;
                        } else if (udp >= 0) {
                            hm_os_close(udp);
                        }
                        matched = 1;
                        break;
                    }
                }
            }
            if (!matched) {                     /* a listener the new config dropped */
                if (fd >= 0)  hm_os_close(fd);
                if (udp >= 0) hm_os_close(udp);
            }
        }
    }
    free(buf);
    hm_errlog("Hyperman: re-exec successor %d: sockets adopted from supervisor %d",
              hm_os_getpid(), (int)hm_resup_old);
}

/* The successor's pool is up: tell the old supervisor to drain. Waited for a
 * scoreboard row per child (ten seconds at most), or one second flat when
 * there is no board, so the old pool is not torn down ahead of the new one
 * answering. */
static void hm_reexec_takeover(const pid_t *kids, int nkids) {
    int i, tries;
    if (hm_resup_old <= 0) return;
    if (hm_sa_board_live()) {
        for (tries = 0; tries < 100; tries++) {
            int ready = 1;
            for (i = 0; i < nkids; i++) {
                sa_sb_reading rd;
                if (hm_sa_board_row_of((uint64_t)kids[i], &rd) < 0) { ready = 0; break; }
            }
            if (ready) break;
            poll(NULL, 0, 100);
        }
    } else {
        poll(NULL, 0, 1000);
    }
    if (kill(hm_resup_old, SIGTERM) == 0)
        hm_errlog("Hyperman: re-exec: pool up, supervisor %d asked to drain",
                  (int)hm_resup_old);
    hm_resup_old = 0;
}
#endif /* !_WIN32 */

static void hm_run_server(pTHX_ hm_worker_cfg *cfg) {
    int workers = cfg->nworkers;

    /* Before the arena, before the bind: an unknown user or group is refused
     * while nothing is held, and on Windows the whole family is. */
    hm_resolve_drop(aTHX_ cfg);
#ifndef _WIN32
    /* The umask FIRST: it is asked for so that what the server creates - the
     * unix socket, the pid file, the logs - comes out with it, and all of
     * those are made below. Applied at the drop it reached only the files
     * the application made. */
    if (cfg->umask_set) (void)umask((mode_t)cfg->umask_val);
#endif
    /* Likewise every listen address: a host that does not resolve is a
     * croak here, never a bind of INADDR_ANY in its place. */
    {
        int i;
        char err[128];
        for (i = 0; i < cfg->nlspecs; i++) {
            hm_listener_spec *s = &cfg->lspecs[i];
            s->fd = -1;         /* calloc'd, and 0 is a descriptor */
            s->udp_fd = -1;
            if (s->path) {
                if (cfg->reuseport)
                    croak("Hyperman->run: reuseport cannot rebind a path listener "
                          "per worker (each rebind would unlink the other's socket)");
                if (hm_resolve_unix(s->path, &s->sa, &s->salen, err, sizeof(err)) < 0)
                    croak("Hyperman->run: listen path '%s': %s", s->path, err);
            }
            else if (hm_resolve(s->host, s->port, SOCK_STREAM, &s->sa, &s->salen,
                                err, sizeof(err)) < 0)
                croak("Hyperman->run: listen host '%s': %s",
                      s->host ? s->host : "", err);
        }
    }
#ifndef _WIN32
    hm_adopt_env(aTHX_ cfg);        /* a re-exec successor: the old sockets */
#endif
    hm_adopt_fds(aTHX_ cfg);

    if (!hm_empty_input)
        hm_empty_input = hm_new_input(aTHX_ "", 0);   /* inherited by workers */
    if (workers < 1)                       /* default: one per CPU */
        workers = hm_os_ncpu();               /* always 1 on Windows */
    cfg->nworkers = workers;

    /* The Shared::Arena, created HERE - before any worker forks - so every
     * worker inherits the one mapping, and from Perl, so Hyperman->arena is
     * the real object with every tenant on it. The denylist and the rate
     * counters are two maps in it; static `deny` entries are loaded now, in
     * the parent, so they are live from the first accepted connection.
     * Single-worker (dev) mode maps it too, so the ABI behaves the same
     * whether or not a supervisor forks. */
    hm_sa_open(aTHX_ cfg->arena_name, cfg->arena_name_len,
               cfg->arena_size ? cfg->arena_size
                               : hm_sa_bytes(cfg->deny_cap, cfg->rate_cap,
                                             cfg->bus_slots, cfg->bus_slot_size));
    {
        const char *which = NULL;
        int err = 0;
        if (hm_sa_abuse_open(cfg->deny_cap, cfg->rate_cap, &which, &err) < 0)
            warn("Hyperman: could not carve the \"%s\" map in the arena "
                 "(Shared::Arena error %d): the denylist and the rate "
                 "counters fail open; raise arena_size", which, err);
    }

    /* QUIC's stateless-reset and (later) Retry secret, generated HERE - once,
     * before any worker forks - for the same reason the TLS ticket key is:
     * under SO_REUSEPORT a client's token can land on a different worker than
     * the one that issued it, and a per-worker secret would make every such
     * token unverifiable. Inherited across the fork, so every worker agrees. */
    hm_quic_secret_init();

    /* The message bus, a ring in the same arena and for the same reason: a
     * ring created after the fork would be one ring per worker, which is a
     * bus that delivers to nobody. Opened even in single-worker mode, so the
     * ABI behaves the same whether or not a supervisor forks. */
    {
        int err = 0;
        if (hm_sa_bus_open(cfg->bus_slots, cfg->bus_slot_size, &err) < 0)
            warn("Hyperman: could not carve the bus ring in the arena "
                 "(Shared::Arena error %d): the bus is local-only; raise "
                 "arena_size", err);
    }
    /* ... and the wakeup descriptors, HERE for the same reason as the ring
     * and one more: a pipe created inside a worker is invisible to its
     * siblings, so a bus built after the fork delivers to some workers and
     * not others.
     *
     * TWO GENERATIONS' WORTH, plus the supervisor's own. A HUP or USR2 forks
     * the replacement pool while the old one is still draining, so both exist
     * at once and both want descriptors - and sized for one generation the
     * fresh workers found every slot held and came up deaf, which outlives the
     * recycle that caused it. Shared::Arena caps this at its own ceiling. */
    (void)hm_sa_bus_wake_init((uint32_t)(workers > 0 ? 2 * workers + 1 : 2));
    /* The worker scoreboard, one row per worker plus one, and the
     * distinct-client sketch when asked for. Neither is on a hot path by
     * default: the board is mirrored by a timer, the sketch is opt-in. */
    {
        int err = 0;
        /* Two generations' worth, like the wakers: a re-exec successor's
         * pool shares this board with the pool it replaces until that one
         * has drained, and a row is not reclaimable while its worker lives. */
        if (hm_sa_board_open((uint32_t)(workers > 0 ? 2 * workers + 2 : 2), &err) < 0)
            warn("Hyperman: could not carve the worker scoreboard in the arena "
                 "(Shared::Arena error %d): pool_stats is empty; raise "
                 "arena_size", err);
        if (cfg->distinct_clients && hm_sa_hll_open(&err) < 0)
            warn("Hyperman: could not carve the distinct-client sketch in the "
                 "arena (Shared::Arena error %d): distinct_clients is off", err);
    }
    if (cfg->deny && SvROK(cfg->deny) && SvTYPE(SvRV(cfg->deny)) == SVt_PVAV) {
        AV *av = (AV *)SvRV(cfg->deny);
        SSize_t i, n = av_len(av) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(av, i, 0);
            if (e && *e && SvOK(*e)) hm_sa_deny_add(SvPV_nolen(*e), 0);
        }
    }

#ifndef SO_REUSEPORT
    if (cfg->reuseport) croak("Hyperman: SO_REUSEPORT not supported on this platform");
#endif
#ifndef __linux__
    if (cfg->affinity) croak("Hyperman: CPU affinity is Linux-only");
#endif

    /* Per listener: build the TLS context before forking, so a bad cert/key
     * fails fast and the (read-only) SSL_CTX is shared copy-on-write across
     * workers. Then bind - in the parent, unless reuseport (each worker binds
     * its own). Under reuseport the parent still binds one probe fd so an
     * unusable address (e.g. a privileged port without root) fails fast. */
    {
        int i;
        for (i = 0; i < cfg->nlspecs; i++) {
            hm_listener_spec *s = &cfg->lspecs[i];
            if (s->tls_cert && s->tls_key) {
                s->tls_ctx = hm_tls_ctx_build(aTHX_ s->tls_cert, s->tls_key,
                                              s->tls_ca, s->tls_verify,
                                              s->tls_sni, s->http2, NULL, 0);
                if (!s->tls_ctx)
                    croak("Hyperman: TLS: could not initialise from cert '%s' "
                          "/ key '%s'", s->tls_cert, s->tls_key);
            }
        }
    }

    /* The access-log format, compiled once here so an unknown directive is a
     * croak before the fork and a line is a walk over an array after it. The
     * tokens are process-lifetime: every worker reads the parent's copy. */
    if (cfg->log_format && strcmp(cfg->log_format, "json") == 0) {
        hm_logfmt_json(aTHX_ &cfg->logtok, &cfg->nlogtok);
        cfg->log_json = 1;
        cfg->log_wants_t0 = 1;
    } else {
        char err[64];
        if (hm_logfmt_compile(aTHX_ cfg->log_format ? cfg->log_format : HM_LOG_COMBINED,
                              &cfg->logtok, &cfg->nlogtok, &cfg->log_wants_t0,
                              err, sizeof(err)) < 0)
            croak("Hyperman->run: access_log_format: unknown directive %s", err);
    }
    /* The error log, likewise opened once and inherited. */
    if (cfg->err_path && cfg->err_fd < 0) {
        cfg->err_fd = hm_os_open_file(cfg->err_path,
                           O_WRONLY | O_CREAT | O_APPEND | O_CLOEXEC, 0644);
        if (cfg->err_fd < 0)
            croak("Hyperman: open error_log '%s': %s", cfg->err_path, strerror(errno));
    }
    if (cfg->err_fd >= 0) hm_err_fd = cfg->err_fd;

    /* Open the access-log file once in the parent so all workers share (and
     * O_APPEND to) the same fd - whole-line writes stay atomic between them. */
    if (cfg->log_path && cfg->log_fd < 0) {
        cfg->log_fd = hm_os_open_file(cfg->log_path,
                           O_WRONLY | O_CREAT | O_APPEND | O_CLOEXEC, 0644);
        if (cfg->log_fd < 0)
            croak("Hyperman: open access_log '%s': %s",
                  cfg->log_path, strerror(errno));
    }

    {
        int i;
        for (i = 0; i < cfg->nlspecs; i++) {
            hm_listener_spec *s = &cfg->lspecs[i];
            if (s->fd >= 0) continue;           /* adopted from LISTEN_FDS */
#ifndef _WIN32
            /* `mode` through the umask around the bind, not a chmod of the
             * path afterwards: in a directory others can write to, the path
             * could be swapped for a symlink between the two and root would
             * chmod whatever it pointed at. A bind creates the socket with
             * 0777 less the umask, so the mask is the mode's complement. */
            mode_t saved_umask = 0;
            int have_saved = 0;
            if (s->path && s->mode_set) {
                saved_umask = umask((mode_t)(~(unsigned)s->mode & 0777u));
                have_saved = 1;
            }
#endif
            s->fd = hm_make_listener((struct sockaddr *)&s->sa, s->salen, cfg->reuseport);
#ifndef _WIN32
            if (have_saved) (void)umask(saved_umask);
#endif
            if (s->fd < 0)
                croak("Hyperman: bind %s%s:%d: %s", s->path ? s->path : "",
                      s->path ? "" : s->host, s->port, strerror(errno));
            s->udp_fd = -1;
            if (s->http3) {
                s->udp_fd = hm_make_udp_listener((struct sockaddr *)&s->sa, s->salen, cfg->reuseport);
                if (s->udp_fd < 0)
                    croak("Hyperman: bind udp %s:%d: %s", s->host, s->port,
                          strerror(errno));
            }
            if (cfg->reuseport) {                                    /* probe only */
                hm_os_close(s->fd); s->fd = -1;
                if (s->udp_fd >= 0) { hm_os_close(s->udp_fd); s->udp_fd = -1; }
            }
        }
    }

    /* Everything that needed root is held: the ports, the logs, the arena.
     * Record who we are, then stop being root, before the first fork so
     * every worker is born as the configured user. Under reuseport the
     * workers rebind their ports themselves, which needs the privilege for a
     * port below 1024; that pairing is refused rather than half-honoured. */
    if (cfg->reuseport && cfg->drop_uid_set) {
        int i;
        for (i = 0; i < cfg->nlspecs; i++)
            if (cfg->lspecs[i].port < 1024)
                croak("Hyperman->run: user => with reuseport => 1 cannot rebind "
                      "port %d as the dropped user; drop reuseport or use a "
                      "port above 1023", cfg->lspecs[i].port);
    }
    hm_write_pidfile(aTHX_ cfg);
    hm_drop_privileges(aTHX_ cfg);

    if (workers == 1) {
        /* dev mode: run the worker in this process, no supervisor. reuseport
         * needs a real bound fd here since there is no per-worker rebind. */
        if (cfg->reuseport) {
            int i;
            for (i = 0; i < cfg->nlspecs; i++) {
                hm_listener_spec *s = &cfg->lspecs[i];
                s->fd = hm_make_listener((struct sockaddr *)&s->sa, s->salen, 1);
                if (s->fd < 0)
                    croak("Hyperman: bind %s:%d: %s", s->host, s->port,
                          strerror(errno));
                if (s->http3) {
                    s->udp_fd = hm_make_udp_listener((struct sockaddr *)&s->sa, s->salen, 1);
                    if (s->udp_fd < 0)
                        croak("Hyperman: bind udp %s:%d: %s", s->host, s->port,
                              strerror(errno));
                }
            }
        }
        hm_worker(aTHX_ cfg, NULL);
        hm_unlink_pidfile(cfg->pid_path);
        return;
    }

#ifdef _WIN32
    /* Not a silent downgrade: an application sized for a pool is told, at
     * boot, in the log it already reads. */
    croak("Hyperman: a worker pool needs fork(2); Windows runs a single "
          "worker (workers => 1).");
#else
    {
        int i;
        int backoff = 0;
        struct sigaction sa;

        for (i = 0; i < workers; i++) {
            pid_t pid = hm_spawn(aTHX_ cfg, i);
            if (pid < 0) {
                /* take the pool down with us: croaking out of run() leaves
                 * nobody supervising the workers already forked, and they
                 * would keep the listening socket alive forever. */
                int j;
                for (j = 0; j < hm_nchildren; j++) kill(hm_children[j], SIGTERM);
                croak("Hyperman: fork: %s", strerror(errno));
            }
            hm_child_start[hm_nchildren] = time(NULL);
            hm_child_widx[hm_nchildren]  = i;
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
        /* ALRM is the supervisor's only clock: a look at the scoreboard every
         * few seconds for a worker that is alive and not moving.
         *
         * An alarm the CALLER already had pending is not ours to cancel. A
         * watchdog that says `alarm(120); $server->run` has asked to be killed
         * at that deadline, and taking SIGALRM over - a handler that only sets
         * a flag, re-armed every tick - silently turns that into a promise
         * nothing keeps, leaving an unsupervised pool running for ever.
         *
         * So the pending deadline is read out and carried on the tick, which
         * is armed for it even with no board to watch. Letting the signal
         * through unhandled instead would kill the supervisor where it stood
         * and leave the workers holding the listening socket with nobody to
         * shut them down - a watchdog that takes half the pool with it is not
         * one. The tick is three seconds, so the deadline is met to within
         * that, and what follows is the death the caller asked for. */
        hm_sup_alarm_at = 0;
        {
            unsigned pending = alarm(0);
            if (pending) hm_sup_alarm_at = time(NULL) + (time_t)pending;
            if (hm_sa_board_live() || hm_sup_alarm_at) {
                sigaction(SIGALRM, &sa, NULL);
                alarm(HM_SUP_TICK_SECS);
            }
        }

        /* A successor: the pool is forked and serving on the adopted sockets;
         * the supervisor that handed them over can drain now. AFTER the
         * handlers above: this waits up to ten seconds, and the pid file
         * already names this process, so a deploy script retrying its
         * `kill -USR2 $(cat pidfile)` into that window hit SIG_DFL and
         * killed the successor, orphaning its workers on the sockets. */
        hm_reexec_takeover(hm_children, hm_nchildren);

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
            sigaddset(&block, SIGALRM);
            sigprocmask(SIG_BLOCK, &block, &orig);

            for (;;) {
                int   st;
                pid_t pid;

                if (hm_sup_term) {
                    for (i = 0; i < hm_nchildren; i++)
                        kill(hm_children[i], SIGTERM);
                    /* workers self-bound their drain with shutdown_grace.
                     * Waited for BY PID: a re-exec successor is a child of
                     * this process too, and it does not exit - it is the
                     * one that asked us to; waitpid(-1) would wait for it
                     * for ever. */
                    for (i = 0; i < hm_nchildren; i++) {
                        while (waitpid(hm_children[i], &st, 0) < 0 && errno == EINTR) { }
                    }
                    break;
                }

                if (hm_sup_usr1) {
                    hm_sup_usr1 = 0;
                    /* With a scoreboard the supervisor has every worker's
                     * numbers already: one aggregate line and one per row,
                     * a dead row marked. Without one, each worker prints its
                     * own line as it always did. */
                    if (hm_sa_board_live()) hm_sa_board_print(stderr);
                    else
                        for (i = 0; i < hm_nchildren; i++)
                            kill(hm_children[i], SIGUSR1);
                }

                if (hm_sup_tick) {
                    hm_sup_tick = 0;
                    /* The caller's own deadline, if it had one: take the pool
                     * down and then let SIGALRM do what it would have done. */
                    if (hm_sup_alarm_at && time(NULL) >= hm_sup_alarm_at) {
                        hm_sup_alarmed = 1;
                        hm_sup_term    = 1;
                        continue;
                    }
                    hm_sup_watch_board();
                    alarm(HM_SUP_TICK_SECS);
                }

                if (hm_sup_usr2) {
                    hm_sup_usr2 = 0;
                    hm_reexec(aTHX_ cfg, &orig);
                }

                if (hm_sup_hup) {
                    pid_t  old[1024];
                    time_t old_start[1024];
                    int    old_widx[1024];
                    int nold = hm_nchildren, nfresh = 0;
                    memcpy(old, hm_children, nold * sizeof(pid_t));
                    memcpy(old_start, hm_child_start, nold * sizeof(time_t));
                    memcpy(old_widx, hm_child_widx, nold * sizeof(int));
                    hm_sup_hup = 0;
                    hm_nchildren = 0;
                    for (i = 0; i < workers; i++) {
                        /* a failed fork must never reach hm_children: -1 there
                         * turns the TERM sweep below into kill(-1, SIGTERM),
                         * which signals every process this uid owns. */
                        pid_t pid = hm_spawn(aTHX_ cfg, i);
                        if (pid < 0) continue;
                        hm_child_start[hm_nchildren] = time(NULL);
                        hm_child_widx[hm_nchildren]  = i;
                        hm_children[hm_nchildren++]  = pid;
                        nfresh++;
                    }
                    /* retire one old worker per fresh one. Short of processes
                     * the survivors stay in the live set, so a HUP under fork
                     * pressure shrinks the pool instead of emptying it. */
                    for (i = 0; i < nold; i++) {
                        if (i < nfresh) {
                            kill(old[i], SIGTERM);   /* drain gracefully */
                        } else {
                            hm_child_start[hm_nchildren] = old_start[i];
                            hm_child_widx[hm_nchildren]  = old_widx[i];
                            hm_children[hm_nchildren++]  = old[i];
                        }
                    }
                }

                /* reap every exited child without blocking, respawning the
                 * live set. Recycled workers exiting are expected; only a
                 * death in the live set is respawned. Abnormal quick deaths
                 * (crash loops) back off exponentially; clean exits respawn
                 * immediately. */
                while ((pid = waitpid(-1, &st, WNOHANG)) > 0) {
                    int live = 0;
                    int dead_widx = 0;
                    time_t started = 0;
                    if (pid == hm_resup_pid) {
                        /* It never took over (a successor that did would have
                         * TERMed us first). Nothing here changed, so nothing
                         * is undone: this pool serves on. Except the pid
                         * file, which it may have written before it died,
                         * and which would then name a dead process for the
                         * next `kill -USR2 $(cat pidfile)`: re-asserted. */
                        hm_errlog("Hyperman: re-exec successor %d exited (%s %d) "
                                  "before taking over; still serving", (int)pid,
                                  WIFEXITED(st) ? "status" : "signal",
                                  WIFEXITED(st) ? WEXITSTATUS(st) : WTERMSIG(st));
                        hm_resup_pid = 0;
                        (void)hm_write_pidfile_(aTHX_ cfg, 0);
                        continue;
                    }
                    for (i = 0; i < hm_nchildren; i++) {
                        if (hm_children[i] == pid) {
                            started   = hm_child_start[i];
                            dead_widx = hm_child_widx[i];
                            hm_nchildren--;
                            hm_children[i]    = hm_children[hm_nchildren];
                            hm_child_start[i] = hm_child_start[hm_nchildren];
                            hm_child_widx[i]  = hm_child_widx[hm_nchildren];
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
                        /* The replacement takes the DEAD worker's index, not
                         * the position it is about to occupy here.
                         *
                         * Those are different numbers, because the array above
                         * is kept packed by swapping the last entry down: kill
                         * the worker at position 0 of three and the survivor
                         * from position 2 moves into it, so the next free
                         * position is 2 - an index a LIVE worker still holds.
                         * Spawned with that, the replacement asked for a waker
                         * slot its own sibling owned, was refused, and ran
                         * deaf to the bus for the rest of its life while the
                         * slot its predecessor had died holding went spare. It
                         * was pinned to that sibling's CPU too.
                         *
                         * So identity comes from the child that left, and only
                         * the bookkeeping position is reused. */
                        int slot = hm_nchildren;
                        pid_t fresh = hm_spawn(aTHX_ cfg, dead_widx);
                        if (fresh > 0) {            /* never record a -1 */
                            hm_child_start[slot] = time(NULL);
                            hm_child_widx[slot]  = dead_widx;
                            hm_children[slot]    = fresh;
                            hm_nchildren = slot + 1;
                        }
                    }
                    if (hm_sup_term) break;   /* TERM arrived during backoff */
                }

                if (hm_sup_term) continue;    /* serviced at the top of the loop */

                /* atomically unblock and sleep until the next signal */
                sigsuspend(&orig);
            }

            sigprocmask(SIG_SETMASK, &orig, NULL);
            hm_unlink_pidfile(cfg->pid_path);

            /* The pool is down because the caller's own alarm came due, so
             * finish the job the alarm was set to do. */
            if (hm_sup_alarmed) {
                signal(SIGALRM, SIG_DFL);
                raise(SIGALRM);
            }
        }
    }
#endif /* !_WIN32 */
}

/* loop object <-> pointer */
static hm_loop *hm_loop_from_sv(pTHX_ SV *sv) {
    if (!(sv && SvROK(sv) && sv_derived_from(sv, "Hyperman::Loop")))
        croak("not a Hyperman::Loop");
    return INT2PTR(hm_loop *, SvIV(SvRV(sv)));
}

/* The Perl wrapper for a loop. ONE blessed referent per loop, however many
 * times this is asked: Hyperman::Loop->new, psgix.loop, Hyperman->loop and
 * the ABI's sv_of_loop used to each mint their own, and the first wrapper
 * whose refcount hit zero freed a Perl-owned loop under every other one.
 * The loop keeps a WEAK copy, so holding the wrapper is what keeps the loop,
 * and the loop holding its own wrapper keeps nothing alive. */
static SV *hm_loop_to_sv(pTHX_ hm_loop *loop) {
    SV *rv;
    if (loop->self_sv && SvROK(loop->self_sv)) return newSVsv(loop->self_sv);
    rv = newRV_noinc(newSViv(PTR2IV(loop)));
    sv_bless(rv, gv_stashpv("Hyperman::Loop", GV_ADD));
    if (loop->self_sv) SvREFCNT_dec(loop->self_sv);   /* a cleared weak ref */
    loop->self_sv = newSVsv(rv);
    sv_rvweaken(loop->self_sv);
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

/* A run() option that is a count: a non-negative number, never a string
 * that is not one ("10M" read as 10) and never a negative ("-1" read as
 * UV_MAX, which for max_body was an unbounded request buffer). */
static UV hm_opt_count(pTHX_ SV *val, const char *key) {
    if (!SvOK(val) || SvROK(val)
        || (!SvIOK(val) && !SvNOK(val) && !looks_like_number(val))
        || SvNV(val) < 0)
        croak("Hyperman->run: %s must be a non-negative number, not '%s'",
              key, SvOK(val) ? SvPV_nolen(val) : "undef");
    return SvUV(val);
}

#endif /* HM_CORE_H */
