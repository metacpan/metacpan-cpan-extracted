#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "EVAPI.h"

#include <libwebsockets.h>
#include <string.h>
#include <stddef.h>

/* Magic numbers for use-after-free detection */
#define EV_WS_CTX_MAGIC  0xDEADBEEF
#define EV_WS_CTX_FREED  0xFEEDFACE
#define EV_WS_CONN_MAGIC 0xCAFEBABE
#define EV_WS_CONN_FREED 0xBADC0FFE

/* Forward declarations */
typedef struct ev_ws_ctx_s ev_ws_ctx_t;
typedef struct ev_ws_conn_s ev_ws_conn_t;
typedef struct ev_ws_fd_s ev_ws_fd_t;

#define EV_WS_SRV_MAGIC 0xFEEDCAFE
#define EV_WS_SRV_FREED 0xFEEDDEAD

typedef struct ev_ws_server_s {
    unsigned int magic;
    SV* on_connect;
    SV* on_message;
    SV* on_close;
    SV* on_error;
    SV* on_pong;
    SV* on_drain;
    SV* on_handshake;
    HV* response_headers; /* headers to inject into upgrade response */
    size_t max_message_size;
    char* protocol_name;
    struct lws_protocols vhost_protocols[2];
} ev_ws_server_t;

typedef ev_ws_ctx_t* EV__Websockets__Context;
typedef ev_ws_conn_t* EV__Websockets__Connection;
typedef struct ev_loop* EV__Loop;

/* File descriptor watcher tracking */
struct ev_ws_fd_s {
    ev_io io;
    ev_ws_ctx_t* ctx;
    int fd;
    int poll_events; /* registered POLLIN/POLLOUT interest mask */
};

/* Send buffer node for pending writes (FAM: data follows the struct) */
typedef struct ev_ws_send_s {
    struct ev_ws_send_s* next;
    size_t len;
    enum lws_write_protocol write_mode;
    char data[1]; /* C89-compatible flexible array; LWS_PRE + payload */
} ev_ws_send_t;

/* Context structure - manages lws_context and connections */
struct ev_ws_ctx_s {
    unsigned int magic;
    int refcnt;      /* lifecycle refcount: Perl + each in-flight lws_service */
    int* alive_flag; /* points to caller's stack variable during lws_service */
    struct ev_loop* loop;
    struct lws_context* lws_ctx;
    ev_ws_conn_t* connections;
    ev_ws_conn_t* flush_head; /* conns with a buffered, fully-received message
                                 awaiting delivery once the service call drains */
    ev_ws_fd_t** fd_table;
    int fd_table_size;
    ev_timer timer;
};

/* Connection structure */
struct ev_ws_conn_s {
    unsigned int magic;
    ev_ws_ctx_t* ctx;
    struct lws* wsi;
    ev_ws_conn_t* next;  /* linked list */
    ev_ws_conn_t* prev;

    int refcnt;
    SV* perl_self; /* non-owning ptr to the blessed RV's target; its existence
                      holds one refcnt (added in get_conn_sv, dropped in DESTROY) */

    /* Callbacks */
    SV* on_connect;
    SV* on_message;
    SV* on_close;
    SV* on_error;
    SV* on_pong;
    SV* on_drain;

    /* Custom Headers */
    HV* custom_headers;

    /* Response Headers (client: response headers; server: request headers) */
    HV* response_headers;

    /* Receive buffer for reassembling a message across callbacks */
    char* recv_buf;
    size_t recv_len;
    size_t recv_alloc;
    int recv_is_binary;
    int recv_complete;       /* buffered message is fully received (final frame) */
    ev_ws_conn_t* flush_next; /* link in ctx->flush_head while pending delivery */
    int on_flush;            /* already queued on ctx->flush_head (dedup) */
    size_t max_message_size;

    /* Send queue */
    ev_ws_send_t* send_head;
    ev_ws_send_t* send_tail;
    size_t send_queue_bytes;

    /* Adopted file handle (prevents Perl from closing the fd) */
    SV* adopted_fh;

    /* Connect timeout */
    ev_timer connect_timer;
    int connect_timer_active;
    struct ev_loop* loop;

    /* Fragmented send state */
    int in_fragmented_send;

    /* Per-connection metadata */
    HV* stash;

    /* State */
    int connected;
    int closing;
};

#define EV_WS_PROTOCOL_NAME "ev-websockets"

/* Extensions support (compression) */
#ifdef LWS_HAS_EXTENSIONS
static const struct lws_extension extensions[] = {
    {
        "permessage-deflate",
        lws_extension_callback_pm_deflate,
        "permessage-deflate; client_no_context_takeover; client_max_window_bits"
    },
    { NULL, NULL, NULL }
};
#endif

static int ev_ws_debug = 0;

/* Bridges userdata into ws_callback() before lws_adopt returns. */
static ev_ws_conn_t* pending_adoption = NULL;
static HV* handshake_headers_map = NULL; /* wsi-ptr → per-conn response headers HV */
static struct lws_context* ssl_keepalive_ctx = NULL; /* see ensure_ssl_keepalive() */

/* Copy an lws header token into a fresh SV, or return NULL if absent/empty */
static SV* hdr_to_sv(struct lws *wsi, enum lws_token_indexes tok) {
    int total = lws_hdr_total_length(wsi, tok);
    if (total > 0) {
        char *buf;
        int n;
        Newx(buf, total + 1, char);
        n = lws_hdr_copy(wsi, buf, total + 1, tok);
        if (n > 0) {
            SV *val = newSVpvn(buf, n);
            Safefree(buf);
            return val;
        }
        Safefree(buf);
    }
    return NULL;
}

/* Capture a header value into an HV under the given key */
static void capture_header(struct lws *wsi, HV *hv, enum lws_token_indexes tok,
                           const char *name, STRLEN nlen) {
    SV *val = hdr_to_sv(wsi, tok);
    if (val && !hv_store(hv, name, nlen, val, 0))
        SvREFCNT_dec(val);
}

typedef struct { enum lws_token_indexes tok; const char *name; STRLEN nlen; } header_def_t;

static const header_def_t request_hdrs[] = {
    { WSI_TOKEN_GET_URI, "Path", 4 },
    { WSI_TOKEN_HOST, "Host", 4 },
    { WSI_TOKEN_ORIGIN, "Origin", 6 },
    { WSI_TOKEN_HTTP_COOKIE, "Cookie", 6 },
    { WSI_TOKEN_HTTP_AUTHORIZATION, "Authorization", 13 },
    { WSI_TOKEN_PROTOCOL, "Sec-WebSocket-Protocol", 22 },
    { WSI_TOKEN_HTTP_USER_AGENT, "User-Agent", 10 },
    { WSI_TOKEN_X_FORWARDED_FOR, "X-Forwarded-For", 15 },
};
#define N_REQUEST_HDRS (int)(sizeof(request_hdrs)/sizeof(request_hdrs[0]))

static void capture_request_headers(struct lws *wsi, HV *hv) {
    int i;
    for (i = 0; i < N_REQUEST_HDRS; i++)
        capture_header(wsi, hv, request_hdrs[i].tok,
                       request_hdrs[i].name, request_hdrs[i].nlen);
}

/* Inject all key/value pairs from an HV as HTTP headers via lws.
   Returns -1 if lws rejected a header (client path aborts the handshake);
   server callers ignore the result and simply stop adding. */
static int inject_headers(struct lws *wsi, HV *hv,
                          unsigned char **p, unsigned char *end) {
    HE *entry;
    char kbuf[256];
    hv_iterinit(hv);
    while ((entry = hv_iternext(hv))) {
        I32 klen;
        const char *key = hv_iterkey(entry, &klen);
        SV *val_sv;
        STRLEN vlen;
        const char *val;
        if (klen >= 254) continue;
        val_sv = hv_iterval(hv, entry);
        val = SvPV(val_sv, vlen);
        memcpy(kbuf, key, klen);
        kbuf[klen] = ':';
        kbuf[klen + 1] = '\0';
        if (lws_add_http_header_by_name(wsi, (unsigned char *)kbuf,
                (unsigned char *)val, vlen, p, end))
            return -1;
    }
    return 0;
}

/* Format a wsi pointer as the lookup key for handshake_headers_map.
   Callers must pass a buffer of at least 32 bytes; returns the key length. */
static int wsi_key(char *buf, struct lws *wsi) {
    return snprintf(buf, 32, "%p", (void*)wsi);
}

#define DEBUG_LOG(fmt, ...) do { if (ev_ws_debug) fprintf(stderr, "[EV::WS] " fmt "\n", ##__VA_ARGS__); } while(0)

static void ctx_ref(ev_ws_ctx_t* ctx) {
    ctx->refcnt++;
}

static void ctx_unref(ev_ws_ctx_t* ctx) {
    if (--ctx->refcnt == 0) {
        Safefree(ctx);
    }
}

/* Schedule the next lws housekeeping wake-up.

   lws_service_adjust_timeout returns the ms until lws next needs servicing; 0
   means "service as soon as possible". This timer only paces lws's time-based
   work (connection/handshake timeouts, TLS cert aging, draining buffered rx) --
   socket readability/writability is driven by the per-fd io watcher, not here.
   We deliberately floor the delay at 1ms rather than arming an ev_idle watcher
   on 0: do_lws_service is now non-blocking, so an always-ready idle watcher
   would busy-spin at 100% CPU whenever lws keeps asking for immediate service.
   A 1ms floor lets the loop block briefly so every other EV watcher still
   fires, at negligible latency for this coarse, time-based work. */
static void schedule_timeout(ev_ws_ctx_t* ctx) {
    int delay_ms = lws_service_adjust_timeout(ctx->lws_ctx, 1000, 0);
    double delay_s;

    if (delay_ms < 1) delay_ms = 1;
    delay_s = (double)delay_ms / 1000.0;

    ev_timer_stop(ctx->loop, &ctx->timer);
    ev_timer_set(&ctx->timer, delay_s, 0.);
    ev_timer_start(ctx->loop, &ctx->timer);
}

static void flush_recv_messages(ev_ws_ctx_t* ctx);

static void do_lws_service(ev_ws_ctx_t* ctx) {
    if (ctx && ctx->magic == EV_WS_CTX_MAGIC && ctx->lws_ctx) {
        int alive = 1;
        int* prev_flag = ctx->alive_flag;
        ctx->alive_flag = &alive;
        ctx_ref(ctx);
        /* "Forced service": drive connections that need servicing with no
           pending socket event -- rx already read into lws's buflist, plus any
           due lws_sul timeouts. Counterintuitively a timeout_ms of 0 is NOT
           non-blocking here: lws maps it to its maximum internal poll wait, so
           the old lws_service(ctx, 0) blocked for seconds on an idle connection
           and starved every other EV watcher. A negative timeout_ms clamps the
           wait to 0, servicing only ready + forced-service work and returning at
           once (see the lws_service_adjust_timeout docs). lws_service_fd(ctx,
           NULL) is invalid since lws 3.2 and never drains buflists. Per-fd I/O
           is driven by io_cb via lws_service_fd(&pollfd). */
        lws_service_tsi(ctx->lws_ctx, -1, 0);
        if (alive)
            flush_recv_messages(ctx); /* deliver messages reassembled above */
        if (alive) {
            ctx->alive_flag = prev_flag;
            schedule_timeout(ctx);
        } else if (prev_flag) {
            *prev_flag = 0; /* propagate destruction up the alive_flag chain */
        }
        ctx_unref(ctx);
    }
}

static void timer_cb(EV_P_ ev_timer* w, int revents) {
    (void)loop; (void)revents;
    do_lws_service((ev_ws_ctx_t*)w->data);
}

/* Forward declarations */
static void io_cb(EV_P_ ev_io* w, int revents);
static void add_fd_watcher(ev_ws_ctx_t* ctx, int fd, int events);
static void change_fd_watcher(ev_ws_ctx_t* ctx, int fd, int events);
static void conn_ref(ev_ws_conn_t* conn);
static void conn_unref(ev_ws_conn_t* conn);

static SV* get_conn_sv(ev_ws_conn_t* conn) {
    if (conn->perl_self) {
        SV* rv = newRV_inc(conn->perl_self);
        sv_bless(rv, gv_stashpv("EV::Websockets::Connection", 1));
        return rv;
    }
    SV* rv = newSV(0);
    sv_setref_pv(rv, "EV::Websockets::Connection", (void*)conn);
    conn->perl_self = SvRV(rv);
    
    /* We are creating a new Perl owner for this connection.
       Increment refcnt so DESTROY doesn't kill it prematurely if LWS still needs it. */
    conn_ref(conn);
    
    return rv;
}

/* All emit_* callbacks share this skeleton: guard on a registered handler,
   ref the conn across the call (a callback may close/destroy it), push $conn
   plus handler-specific args, invoke under G_EVAL, and warn — without
   recursing — on a die.  EMIT_BEGIN opens a block that EMIT_END closes;
   handler-specific args are XPUSHs'd in between. */
#define EMIT_BEGIN(conn, cb_field)                          \
    if ((conn) == NULL || (conn)->cb_field == NULL) return; \
    {                                                       \
        SV* _emit_cb = (conn)->cb_field;                    \
        dSP;                                                \
        ENTER;                                              \
        SAVETMPS;                                           \
        PUSHMARK(SP);                                       \
        conn_ref(conn);                                     \
        XPUSHs(sv_2mortal(get_conn_sv(conn)));

#define EMIT_END(conn, label)                               \
        PUTBACK;                                            \
        sv_setsv(ERRSV, &PL_sv_undef);                      \
        call_sv(_emit_cb, G_DISCARD | G_EVAL);              \
        if (SvTRUE(ERRSV))                                  \
            warn("EV::Websockets: exception in " label ": %s", SvPV_nolen(ERRSV)); \
        FREETMPS;                                           \
        LEAVE;                                              \
        conn_unref(conn);                                   \
    }

/* Guard shared by the send_* methods: croak if the connection has been
   destroyed or is not currently open for writing. */
#define CHECK_CONN_OPEN(self) STMT_START {                          \
        if ((self)->magic != EV_WS_CONN_MAGIC)                      \
            croak("Connection has been destroyed");                 \
        if (!(self)->wsi || !(self)->connected || (self)->closing)  \
            croak("Connection is not open");                        \
    } STMT_END

/* Guard for send/send_binary: a whole-message write must not interleave with
   an in-progress fragmented message. */
#define CHECK_NOT_FRAGMENTING(self) STMT_START {                    \
        if ((self)->in_fragmented_send)                             \
            croak("Cannot send while a fragmented message is in progress; " \
                  "finish the fragment with send_fragment(..., is_final => 1) first"); \
    } STMT_END

static void emit_error(ev_ws_conn_t* conn, const char* error) {
    EMIT_BEGIN(conn, on_error);
    XPUSHs(sv_2mortal(newSVpv(error, 0)));
    EMIT_END(conn, "error handler");
}

static void emit_connect(ev_ws_conn_t* conn) {
    EMIT_BEGIN(conn, on_connect);
    if (conn->response_headers)
        XPUSHs(sv_2mortal(newRV_inc((SV*)conn->response_headers)));
    else
        XPUSHs(&PL_sv_undef);
    EMIT_END(conn, "connect handler");
}

static void emit_message(ev_ws_conn_t* conn, const char* data, size_t len, int is_binary, int is_final) {
    EMIT_BEGIN(conn, on_message);
    XPUSHs(sv_2mortal(newSVpvn(data, len)));
    XPUSHs(sv_2mortal(newSViv(is_binary)));
    XPUSHs(sv_2mortal(newSViv(is_final)));
    EMIT_END(conn, "message handler");
}

/* Deliver buffered, fully-received messages once an lws service call has
   drained all currently-available input. The receive path reassembles a
   message across callbacks (necessary because permessage-deflate inflates one
   frame into several callbacks, each reporting lws_is_final_fragment() == 1)
   and queues the connection here; we emit only complete messages. The ref taken
   when queuing keeps each conn alive across its callback, so it is safe to
   touch conn after emit_message returns. */
static void flush_recv_messages(ev_ws_ctx_t* ctx) {
    ev_ws_conn_t* conn = ctx->flush_head;
    ctx->flush_head = NULL;
    while (conn) {
        ev_ws_conn_t* next = conn->flush_next;
        conn->flush_next = NULL;
        conn->on_flush = 0;
        if (conn->magic == EV_WS_CONN_MAGIC && conn->recv_complete) {
            /* recv_complete (not recv_len>0): a zero-length message is a valid
               complete message and must still be delivered. */
            emit_message(conn, conn->recv_buf ? conn->recv_buf : "", conn->recv_len, conn->recv_is_binary, 1);
            if (conn->magic == EV_WS_CONN_MAGIC) {
                conn->recv_len = 0;
                conn->recv_complete = 0;
            }
        }
        conn_unref(conn); /* release the flush-list ref */
        conn = next;
    }
}

static void emit_close(ev_ws_conn_t* conn, int code, const char* reason) {
    EMIT_BEGIN(conn, on_close);
    XPUSHs(sv_2mortal(newSViv(code)));
    XPUSHs(reason ? sv_2mortal(newSVpv(reason, 0)) : &PL_sv_undef);
    EMIT_END(conn, "close handler");
}

static void emit_pong(ev_ws_conn_t* conn, const char* data, size_t len) {
    EMIT_BEGIN(conn, on_pong);
    XPUSHs(sv_2mortal(newSVpvn(data ? data : "", len)));
    EMIT_END(conn, "pong handler");
}

static void emit_drain(ev_ws_conn_t* conn) {
    EMIT_BEGIN(conn, on_drain);
    EMIT_END(conn, "drain handler");
}

/* Stop the connect-timeout watcher if it is running */
static void stop_connect_timer(ev_ws_conn_t* conn) {
    if (conn->connect_timer_active && conn->loop) {
        ev_timer_stop(conn->loop, &conn->connect_timer);
        conn->connect_timer_active = 0;
    }
}

/* Drop references to the (up to seven) callback SVs collected while parsing
   options, on an error path that croaks before they are owned elsewhere.
   Pass NULL for absent slots; SvREFCNT_dec of NULL is guarded out. */
static void free_cb_svs(SV* on_connect, SV* on_message, SV* on_close,
                        SV* on_error, SV* on_pong, SV* on_drain,
                        SV* on_handshake) {
    if (on_connect)   SvREFCNT_dec(on_connect);
    if (on_message)   SvREFCNT_dec(on_message);
    if (on_close)     SvREFCNT_dec(on_close);
    if (on_error)     SvREFCNT_dec(on_error);
    if (on_pong)      SvREFCNT_dec(on_pong);
    if (on_drain)     SvREFCNT_dec(on_drain);
    if (on_handshake) SvREFCNT_dec(on_handshake);
}

/* Drop the server's callback/header SV references (not protocol_name, which the
   live vhost still points at, nor the struct itself). Idempotent via NULL-out. */
static void free_server_svs(ev_ws_server_t* srv) {
    if (srv->on_connect)   { SvREFCNT_dec(srv->on_connect);   srv->on_connect = NULL; }
    if (srv->on_message)   { SvREFCNT_dec(srv->on_message);   srv->on_message = NULL; }
    if (srv->on_close)     { SvREFCNT_dec(srv->on_close);     srv->on_close = NULL; }
    if (srv->on_error)     { SvREFCNT_dec(srv->on_error);     srv->on_error = NULL; }
    if (srv->on_pong)      { SvREFCNT_dec(srv->on_pong);      srv->on_pong = NULL; }
    if (srv->on_drain)     { SvREFCNT_dec(srv->on_drain);     srv->on_drain = NULL; }
    if (srv->on_handshake) { SvREFCNT_dec(srv->on_handshake); srv->on_handshake = NULL; }
    if (srv->response_headers) {
        SvREFCNT_dec((SV*)srv->response_headers);
        srv->response_headers = NULL;
    }
}

/* Free a connection's resources (not the struct itself) */
static void free_conn_resources(ev_ws_conn_t* conn) {
    ev_ws_send_t* send;
    ev_ws_send_t* next_send;

    DEBUG_LOG("Freeing connection resources: conn=%p", conn);

    stop_connect_timer(conn);

    if (conn->on_connect) { SvREFCNT_dec(conn->on_connect); conn->on_connect = NULL; }
    if (conn->on_message) { SvREFCNT_dec(conn->on_message); conn->on_message = NULL; }
    if (conn->on_close) { SvREFCNT_dec(conn->on_close); conn->on_close = NULL; }
    if (conn->on_error) { SvREFCNT_dec(conn->on_error); conn->on_error = NULL; }
    if (conn->on_pong) { SvREFCNT_dec(conn->on_pong); conn->on_pong = NULL; }
    if (conn->on_drain) { SvREFCNT_dec(conn->on_drain); conn->on_drain = NULL; }

    if (conn->custom_headers) {
        SvREFCNT_dec((SV*)conn->custom_headers);
        conn->custom_headers = NULL;
    }

    if (conn->response_headers) {
        SvREFCNT_dec((SV*)conn->response_headers);
        conn->response_headers = NULL;
    }

    if (conn->stash) { SvREFCNT_dec((SV*)conn->stash); conn->stash = NULL; }

    if (conn->adopted_fh) { SvREFCNT_dec(conn->adopted_fh); conn->adopted_fh = NULL; }

    if (conn->recv_buf) { Safefree(conn->recv_buf); conn->recv_buf = NULL; conn->recv_alloc = 0; }

    for (send = conn->send_head; send != NULL; send = next_send) {
        next_send = send->next;
        Safefree(send);
    }
    conn->send_head = NULL;
    conn->send_tail = NULL;
    conn->send_queue_bytes = 0;
}

static void conn_ref(ev_ws_conn_t* conn) {
    conn->refcnt++;
    DEBUG_LOG("conn_ref: %p refcnt=%d", conn, conn->refcnt);
}

static void conn_unref(ev_ws_conn_t* conn) {
    DEBUG_LOG("conn_unref: %p refcnt=%d", conn, conn->refcnt);
    if (--conn->refcnt == 0) {
        DEBUG_LOG("Actually freeing conn: %p", conn);
        free_conn_resources(conn);
        conn->magic = EV_WS_CONN_FREED;
        Safefree(conn);
    }
}

static void link_conn(ev_ws_ctx_t* ctx, ev_ws_conn_t* conn) {
    conn->ctx = ctx;
    conn->next = ctx->connections;
    if (ctx->connections) {
        ctx->connections->prev = conn;
    }
    ctx->connections = conn;
}

static void unlink_conn(ev_ws_conn_t* conn) {
    if (conn->ctx == NULL) return;

    if (conn->prev) {
        conn->prev->next = conn->next;
    } else {
        conn->ctx->connections = conn->next;
    }
    if (conn->next) {
        conn->next->prev = conn->prev;
    }
    conn->prev = NULL;
    conn->next = NULL;
    conn->ctx = NULL;
}

static void queue_send(ev_ws_conn_t* conn, const char* data, size_t len, enum lws_write_protocol write_mode) {
    int was_empty = (conn->send_head == NULL);
    size_t alloc = offsetof(ev_ws_send_t, data) + LWS_PRE + len;
    ev_ws_send_t* send = (ev_ws_send_t*)safemalloc(alloc);

    if (data && len > 0) {
        memcpy(send->data + LWS_PRE, data, len);
    }
    send->len = len;
    send->write_mode = write_mode;
    send->next = NULL;

    if (conn->send_tail) {
        conn->send_tail->next = send;
        conn->send_tail = send;
    } else {
        conn->send_head = send;
        conn->send_tail = send;
    }
    conn->send_queue_bytes += len;

    if (was_empty && conn->wsi) {
        lws_callback_on_writable(conn->wsi);
    }
}

static void io_cb(EV_P_ ev_io* w, int revents) {
    ev_ws_fd_t* fdw = (ev_ws_fd_t*)w;
    ev_ws_ctx_t* ctx = fdw->ctx;
    struct lws_pollfd pollfd;

    (void)loop;

    if (ctx == NULL || ctx->magic != EV_WS_CTX_MAGIC || ctx->lws_ctx == NULL) {
        return;
    }

    pollfd.fd = fdw->fd;
    pollfd.events = fdw->poll_events;
    pollfd.revents = 0;

    if (revents & EV_READ)  pollfd.revents |= POLLIN;
    if (revents & EV_WRITE) pollfd.revents |= POLLOUT;
    if (revents & EV_ERROR) pollfd.revents |= POLLERR | POLLHUP;

    {
        int alive = 1;
        int* prev_flag = ctx->alive_flag;
        ctx->alive_flag = &alive;
        ctx_ref(ctx);
        lws_service_fd(ctx->lws_ctx, &pollfd);
        if (alive)
            flush_recv_messages(ctx); /* deliver messages reassembled above */
        if (alive) {
            ctx->alive_flag = prev_flag;
            schedule_timeout(ctx);
        } else if (prev_flag) {
            *prev_flag = 0; /* propagate destruction up the alive_flag chain */
        }
        ctx_unref(ctx);
    }
}

#define FD_TABLE_INIT_SIZE 64

static void fd_table_grow(ev_ws_ctx_t* ctx, int needed) {
    int new_size = ctx->fd_table_size ? ctx->fd_table_size : FD_TABLE_INIT_SIZE;
    while (new_size <= needed) new_size *= 2;
    Renew(ctx->fd_table, new_size, ev_ws_fd_t*);
    Zero(ctx->fd_table + ctx->fd_table_size, new_size - ctx->fd_table_size, ev_ws_fd_t*);
    ctx->fd_table_size = new_size;
}

static void add_fd_watcher(ev_ws_ctx_t* ctx, int fd, int events) {
    ev_ws_fd_t* fdw;
    int ev_events = 0;

    if (fd < 0) return;
    if (fd >= ctx->fd_table_size) fd_table_grow(ctx, fd);

    fdw = ctx->fd_table[fd];
    if (fdw != NULL) {
        change_fd_watcher(ctx, fd, events);
        return;
    }

    Newxz(fdw, 1, ev_ws_fd_t);
    fdw->ctx = ctx;
    fdw->fd = fd;
    fdw->poll_events = events;

    if (events & POLLIN) ev_events |= EV_READ;
    if (events & POLLOUT) ev_events |= EV_WRITE;

    DEBUG_LOG("add_fd_watcher: fd=%d poll_events=%d ev_events=%d", fd, events, ev_events);

    ev_io_init(&fdw->io, io_cb, fd, ev_events ? ev_events : EV_READ);
    if (ev_events)
        ev_io_start(ctx->loop, &fdw->io);

    ctx->fd_table[fd] = fdw;
}

static void del_fd_watcher(ev_ws_ctx_t* ctx, int fd) {
    ev_ws_fd_t* fdw;
    if (fd < 0 || fd >= ctx->fd_table_size) return;
    fdw = ctx->fd_table[fd];
    if (fdw == NULL) return;

    ev_io_stop(ctx->loop, &fdw->io);
    ctx->fd_table[fd] = NULL;
    Safefree(fdw);
}

static void change_fd_watcher(ev_ws_ctx_t* ctx, int fd, int events) {
    ev_ws_fd_t* fdw;
    int ev_events = 0;

    if (fd < 0) return;
    if (fd >= ctx->fd_table_size) {
        add_fd_watcher(ctx, fd, events);
        return;
    }
    fdw = ctx->fd_table[fd];
    if (fdw == NULL) {
        add_fd_watcher(ctx, fd, events);
        return;
    }

    fdw->poll_events = events;

    if (events & POLLIN) ev_events |= EV_READ;
    if (events & POLLOUT) ev_events |= EV_WRITE;

    DEBUG_LOG("change_fd_watcher: fd=%d poll_events=%d ev_events=%d", fd, events, ev_events);

    ev_io_stop(ctx->loop, &fdw->io);
    if (ev_events == 0) return;
    ev_io_set(&fdw->io, fd, ev_events);
    ev_io_start(ctx->loop, &fdw->io);
}

static void free_all_fd_watchers(ev_ws_ctx_t* ctx) {
    int i;
    for (i = 0; i < ctx->fd_table_size; i++) {
        ev_ws_fd_t* fdw = ctx->fd_table[i];
        if (fdw) {
            if (ctx->loop) ev_io_stop(ctx->loop, &fdw->io);
            Safefree(fdw);
            ctx->fd_table[i] = NULL;
        }
    }
    Safefree(ctx->fd_table);
    ctx->fd_table = NULL;
    ctx->fd_table_size = 0;
}

static void connect_timeout_cb(EV_P_ ev_timer* w, int revents) {
    ev_ws_conn_t* conn = (ev_ws_conn_t*)w->data;
    (void)loop; (void)revents;
    conn->connect_timer_active = 0;
    conn->closing = 1;
    conn_ref(conn);
    emit_error(conn, "connect timeout");
    if (conn->magic == EV_WS_CONN_MAGIC && conn->wsi)
        lws_callback_on_writable(conn->wsi);
    conn_unref(conn);
}

/* libwebsockets callback */
static int ws_callback(struct lws* wsi, enum lws_callback_reasons reason,
                       void* user, void* in, size_t len) {
    struct lws_context* lws_ctx = wsi ? lws_get_context(wsi) : NULL;
    ev_ws_ctx_t* ctx = lws_ctx ? (ev_ws_ctx_t*)lws_context_user(lws_ctx) : NULL;
    ev_ws_conn_t* conn = (ev_ws_conn_t*)user;

    if (!conn && wsi && pending_adoption) {
        DEBUG_LOG("Associating pending adoption: conn=%p", pending_adoption);
        lws_set_wsi_user(wsi, pending_adoption);
        conn = pending_adoption;
        if (!conn->wsi) conn->wsi = wsi;
    }

    if (ctx && ctx->magic != EV_WS_CTX_MAGIC) {
        /* Context is being destroyed. Only handle cleanup callbacks. */
        if (reason != LWS_CALLBACK_WSI_DESTROY &&
            reason != LWS_CALLBACK_PROTOCOL_DESTROY) {
            return 0;
        }
    }

    DEBUG_LOG("callback reason=%d user=%p ctx=%p wsi=%p conn=%p", (int)reason, user, ctx, wsi, conn);

    switch (reason) {
        /* Poll fd management callbacks */
        case LWS_CALLBACK_ADD_POLL_FD: {
            struct lws_pollargs* pa = (struct lws_pollargs*)in;
            DEBUG_LOG("ADD_POLL_FD: ctx=%p fd=%d events=%d", ctx, pa->fd, pa->events);
            if (ctx && ctx->magic == EV_WS_CTX_MAGIC) {
                add_fd_watcher(ctx, pa->fd, pa->events);
            }
            break;
        }

        case LWS_CALLBACK_DEL_POLL_FD: {
            struct lws_pollargs* pa = (struct lws_pollargs*)in;
            if (ctx && ctx->magic == EV_WS_CTX_MAGIC) {
                del_fd_watcher(ctx, pa->fd);
            }
            break;
        }

        case LWS_CALLBACK_CHANGE_MODE_POLL_FD: {
            struct lws_pollargs* pa = (struct lws_pollargs*)in;
            if (ctx && ctx->magic == EV_WS_CTX_MAGIC) {
                change_fd_watcher(ctx, pa->fd, pa->events);
            }
            break;
        }

        case LWS_CALLBACK_CLIENT_APPEND_HANDSHAKE_HEADER: {
            if (conn && conn->custom_headers) {
                unsigned char **p = (unsigned char **)in;
                unsigned char *end = (*p) + len;
                if (inject_headers(wsi, conn->custom_headers, p, end))
                    return -1;
            }
            break;
        }
        
        case LWS_CALLBACK_CLIENT_FILTER_PRE_ESTABLISH: {
            if (conn && conn->magic == EV_WS_CONN_MAGIC) {
                static const header_def_t resp_hdrs[] = {
                    { WSI_TOKEN_HTTP_SET_COOKIE, "Set-Cookie", 10 },
                    { WSI_TOKEN_HTTP_CONTENT_TYPE, "Content-Type", 12 },
                    { WSI_TOKEN_HTTP_SERVER, "Server", 6 },
                    { WSI_TOKEN_PROTOCOL, "Sec-WebSocket-Protocol", 22 },
#ifdef WSI_TOKEN_HTTP_LOCATION
                    { WSI_TOKEN_HTTP_LOCATION, "Location", 8 },
#endif
#ifdef WSI_TOKEN_HTTP_WWW_AUTHENTICATE
                    { WSI_TOKEN_HTTP_WWW_AUTHENTICATE, "WWW-Authenticate", 16 },
#endif
                };
                int hi;
                if (!conn->response_headers) conn->response_headers = newHV();
                for (hi = 0; hi < (int)(sizeof(resp_hdrs)/sizeof(resp_hdrs[0])); hi++) {
                    capture_header(wsi, conn->response_headers, resp_hdrs[hi].tok,
                                   resp_hdrs[hi].name, resp_hdrs[hi].nlen);
                }
            }
            break;
        }

        case LWS_CALLBACK_FILTER_PROTOCOL_CONNECTION: {
            struct lws_vhost *vh = lws_get_vhost(wsi);
            ev_ws_server_t *srv = vh ? (ev_ws_server_t *)lws_get_vhost_user(vh) : NULL;
            if (srv && srv->magic == EV_WS_SRV_MAGIC && srv->on_handshake) {
                HV *hdrs = newHV();
                int count;
                SV *result;
                capture_request_headers(wsi, hdrs);

                dSP;
                ENTER;
                SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(sv_2mortal(newRV_noinc((SV*)hdrs)));
                PUTBACK;
                sv_setsv(ERRSV, &PL_sv_undef);
                count = call_sv(srv->on_handshake, G_SCALAR | G_EVAL);
                SPAGAIN;
                if (SvTRUE(ERRSV)) {
                    warn("EV::Websockets: exception in on_handshake: %s", SvPV_nolen(ERRSV));
                    if (count) POPs;
                    PUTBACK;
                    FREETMPS;
                    LEAVE;
                    return -1;
                }
                result = count ? POPs : &PL_sv_undef;
                if (!SvTRUE(result)) {
                    PUTBACK;
                    FREETMPS;
                    LEAVE;
                    return -1;
                }
                if (SvROK(result) && SvTYPE(SvRV(result)) == SVt_PVHV) {
                    char key[32];
                    int klen = wsi_key(key, wsi);
                    SV *val = newRV_inc(SvRV(result));
                    if (!handshake_headers_map)
                        handshake_headers_map = newHV();
                    if (!hv_store(handshake_headers_map, key, klen, val, 0))
                        SvREFCNT_dec(val);
                }
                PUTBACK;
                FREETMPS;
                LEAVE;
            }
            break;
        }

        /* Connection callbacks */
        case LWS_CALLBACK_ESTABLISHED:
            if (!conn) {
                struct lws_vhost *vh = lws_get_vhost(wsi);
                ev_ws_server_t *srv = vh ? (ev_ws_server_t *)lws_get_vhost_user(vh) : NULL;
                if (ctx && srv && srv->magic == EV_WS_SRV_MAGIC) {
                    ev_ws_conn_t *c;
                    Newxz(c, 1, ev_ws_conn_t);
                    c->magic = EV_WS_CONN_MAGIC;
                    c->wsi = wsi;
                    c->refcnt = 1; /* For LWS */
                    c->max_message_size = srv->max_message_size;
                    c->loop = ctx->loop;
                    link_conn(ctx, c);
                    c->on_connect = srv->on_connect ? SvREFCNT_inc(srv->on_connect) : NULL;
                    c->on_message = srv->on_message ? SvREFCNT_inc(srv->on_message) : NULL;
                    c->on_close = srv->on_close ? SvREFCNT_inc(srv->on_close) : NULL;
                    c->on_error = srv->on_error ? SvREFCNT_inc(srv->on_error) : NULL;
                    c->on_pong = srv->on_pong ? SvREFCNT_inc(srv->on_pong) : NULL;
                    c->on_drain = srv->on_drain ? SvREFCNT_inc(srv->on_drain) : NULL;

                    c->response_headers = newHV();
                    capture_request_headers(wsi, c->response_headers);

                    lws_set_wsi_user(wsi, c);
                    conn = c;
                }
            }
            /* fallthrough */
        case LWS_CALLBACK_CLIENT_ESTABLISHED:
            if (conn && conn->magic == EV_WS_CONN_MAGIC) {
                DEBUG_LOG("Connected (reason %d): conn=%p", (int)reason, conn);
                stop_connect_timer(conn);
                conn->connected = 1;
                emit_connect(conn);
            }
            break;

        case LWS_CALLBACK_ADD_HEADERS: {
            struct lws_process_html_args *args = (struct lws_process_html_args *)in;
            unsigned char *p_end = (unsigned char *)args->p + args->max_len;
            struct lws_vhost *vh = lws_get_vhost(wsi);
            ev_ws_server_t *srv = vh ? (ev_ws_server_t *)lws_get_vhost_user(vh) : NULL;
            if (srv && srv->magic == EV_WS_SRV_MAGIC && srv->response_headers)
                inject_headers(wsi, srv->response_headers,
                               (unsigned char **)&args->p, p_end);
            if (handshake_headers_map) {
                char key[32];
                int klen = wsi_key(key, wsi);
                SV *val = hv_delete(handshake_headers_map, key, klen, 0);
                if (val && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV)
                    inject_headers(wsi, (HV*)SvRV(val), (unsigned char **)&args->p, p_end);
            }
            break;
        }

        case LWS_CALLBACK_RECEIVE_PONG:
        case LWS_CALLBACK_CLIENT_RECEIVE_PONG:
            if (conn && conn->magic == EV_WS_CONN_MAGIC) {
                emit_pong(conn, (const char *)in, len);
            }
            break;

        case LWS_CALLBACK_RECEIVE:
        case LWS_CALLBACK_CLIENT_RECEIVE:
            if (conn && conn->magic == EV_WS_CONN_MAGIC) {
                int is_final = lws_is_final_fragment(wsi);
                int is_binary = lws_frame_is_binary(wsi);
                DEBUG_LOG("Received data (reason %d): len=%zu final=%d binary=%d", (int)reason, len, is_final, is_binary);

                if (lws_is_first_fragment(wsi)) {
                    /* A new message begins. If a completed message is still
                       buffered, deliver it first: with permessage-deflate lws
                       inflates one frame into several callbacks each flagged
                       "final", so we must reassemble across callbacks rather
                       than treat every final callback as a whole message. */
                    if (conn->recv_complete) {
                        conn_ref(conn);
                        emit_message(conn, conn->recv_buf ? conn->recv_buf : "", conn->recv_len, conn->recv_is_binary, 1);
                        if (conn->magic != EV_WS_CONN_MAGIC) { conn_unref(conn); break; }
                        conn_unref(conn);
                    }
                    conn->recv_len = 0;
                    conn->recv_complete = 0;
                    conn->recv_is_binary = is_binary;
                }

                /* Enforce max message size */
                if (conn->max_message_size > 0 && conn->recv_len + len > conn->max_message_size) {
                    conn_ref(conn);
                    emit_error(conn, "message exceeds max_message_size");
                    if (conn->magic == EV_WS_CONN_MAGIC) {
                        Safefree(conn->recv_buf);
                        conn->recv_buf = NULL;
                        conn->recv_len = 0;
                        conn->recv_alloc = 0;
                        conn->recv_complete = 0;
                    }
                    conn_unref(conn);
                    return -1;
                }

                /* Accumulate data */
                if (conn->recv_len + len > conn->recv_alloc) {
                    size_t new_alloc = conn->recv_alloc ? conn->recv_alloc * 2 : 4096;
                    while (new_alloc < conn->recv_len + len) new_alloc *= 2;
                    if (conn->max_message_size > 0 && new_alloc > conn->max_message_size)
                        new_alloc = conn->max_message_size;
                    Renew(conn->recv_buf, new_alloc, char);
                    conn->recv_alloc = new_alloc;
                }
                if (len) /* guard: recv_buf may still be NULL for an empty frame */
                    memcpy(conn->recv_buf + conn->recv_len, in, len);
                conn->recv_len += len;
                conn->recv_complete = is_final;

                /* Queue the connection so its completed message is delivered
                   once the current lws service call drains all available input
                   (see flush_recv_messages). is_final alone is unreliable under
                   permessage-deflate, so we defer delivery: a fully-received
                   message (recv_complete) is emitted either in the first-fragment
                   branch above when the next message starts, or at flush time.
                   The flush-list ref keeps conn alive until then. */
                if (!conn->on_flush) {
                    conn_ref(conn);
                    conn->flush_next = conn->ctx->flush_head;
                    conn->ctx->flush_head = conn;
                    conn->on_flush = 1;
                }
            }
            break;

        case LWS_CALLBACK_SERVER_WRITEABLE:
        case LWS_CALLBACK_CLIENT_WRITEABLE:
            if (conn && conn->magic == EV_WS_CONN_MAGIC) {
                ev_ws_send_t* send;
                int n;
                while (conn->send_head) {
                    send = conn->send_head;
                    DEBUG_LOG("Writing data: len=%zu mode=%d", send->len, (int)send->write_mode);
                    n = lws_write(wsi, (unsigned char*)send->data + LWS_PRE, send->len, send->write_mode);

                    if (n < 0) {
                        lws_set_wsi_user(wsi, NULL);
                        conn->wsi = NULL;
                        conn->connected = 0;
                        conn->in_fragmented_send = 0;
                        unlink_conn(conn);
                        conn_ref(conn);
                        emit_error(conn, "write failed");
                        conn_unref(conn);
                        conn_unref(conn); /* drop wsi ref */
                        return -1;
                    }

                    conn->send_head = send->next;
                    if (conn->send_head == NULL) {
                        conn->send_tail = NULL;
                    }
                    conn->send_queue_bytes -= send->len;
                    Safefree(send);

                    if (lws_send_pipe_choked(wsi)) {
                        lws_callback_on_writable(wsi);
                        break;
                    }
                }
                if (conn->closing && conn->send_head == NULL) {
                    DEBUG_LOG("Closing connection via writeable callback");
                    return -1;
                }
                if (conn->send_head == NULL) {
                    emit_drain(conn); /* self-guards on a registered on_drain */
                }
            }
            break;

        case LWS_CALLBACK_CLIENT_CONNECTION_ERROR:
            DEBUG_LOG("CLIENT_CONNECTION_ERROR: conn=%p", conn);
            if (conn && conn->magic == EV_WS_CONN_MAGIC) {
                const char* err = in ? (const char*)in : "connection error";
                stop_connect_timer(conn);
                /* Clear wsi user pointer so WSI_DESTROY (which follows) sees NULL
                   and skips — we handle cleanup here to avoid double conn_unref
                   if Context::DESTROY fires from within the callback. */
                lws_set_wsi_user(wsi, NULL);
                conn->wsi = NULL;
                conn->connected = 0;
                unlink_conn(conn);
                conn_ref(conn);
                emit_error(conn, err);
                conn_unref(conn);
                conn_unref(conn); /* drop wsi ref */
            }
            break;

        case LWS_CALLBACK_CLIENT_CLOSED:
        case LWS_CALLBACK_CLOSED:
            DEBUG_LOG("CLOSED: conn=%p", conn);
            if (conn && conn->magic == EV_WS_CONN_MAGIC) {
                int close_code = 1000;
                stop_connect_timer(conn);
                const char* close_reason = NULL;
                char reason_buf[126];

                if (in && len >= 2) {
                    close_code = ((unsigned char *)in)[0] << 8 | ((unsigned char *)in)[1];
                    if (len > 2) {
                        size_t rlen = len - 2;
                        if (rlen > sizeof(reason_buf) - 1) rlen = sizeof(reason_buf) - 1;
                        memcpy(reason_buf, (char *)in + 2, rlen);
                        reason_buf[rlen] = '\0';
                        close_reason = reason_buf;
                    }
                }

                DEBUG_LOG("Emitting close: code=%d", close_code);
                lws_set_wsi_user(wsi, NULL);
                conn->connected = 0;
                conn->wsi = NULL;
                unlink_conn(conn);
                conn_ref(conn);
                /* Deliver a fully-received-but-not-yet-flushed message before
                   on_close, so on_message precedes on_close even when the data
                   and the close arrive in the same lws service pass (delivery is
                   otherwise deferred to flush_recv_messages, which runs after the
                   service returns -- i.e. after this CLOSED callback). */
                if (conn->recv_complete) {
                    emit_message(conn, conn->recv_buf ? conn->recv_buf : "", conn->recv_len, conn->recv_is_binary, 1);
                    if (conn->magic == EV_WS_CONN_MAGIC) { conn->recv_len = 0; conn->recv_complete = 0; }
                }
                if (conn->magic == EV_WS_CONN_MAGIC)
                    emit_close(conn, close_code, close_reason);
                conn_unref(conn);
                conn_unref(conn); /* drop wsi ref */
            }
            break;

        case LWS_CALLBACK_PROTOCOL_DESTROY: {
            struct lws_vhost *vh = wsi ? lws_get_vhost(wsi) : NULL;
            if (vh) {
                ev_ws_server_t *srv = (ev_ws_server_t *)lws_get_vhost_user(vh);
                if (srv && (srv->magic == EV_WS_SRV_MAGIC || srv->magic == EV_WS_SRV_FREED)) {
                    /* SRV_FREED means a failed listen() already dropped the SV
                       refs but deliberately left protocol_name alive (the vhost
                       still pointed at it); free it here, once, at teardown. */
                    if (srv->magic == EV_WS_SRV_MAGIC)
                        free_server_svs(srv);
                    if (srv->protocol_name) Safefree(srv->protocol_name);
                    Safefree(srv);
                }
            }
            break;
        }

        case LWS_CALLBACK_WSI_DESTROY:
            if (handshake_headers_map) {
                char key[32];
                int klen = wsi_key(key, wsi);
                hv_delete(handshake_headers_map, key, klen, G_DISCARD);
            }
            if (conn && conn->magic == EV_WS_CONN_MAGIC) {
                DEBUG_LOG("WSI destroyed: conn=%p", conn);
                conn->wsi = NULL;
                conn->connected = 0;
                unlink_conn(conn);
                conn_unref(conn); /* drop wsi ref; frees resources when refcnt hits 0 */
            }
            break;

        default:
            break;
    }

    return 0;
}

static const struct lws_protocols protocols[] = {
    {
        EV_WS_PROTOCOL_NAME,
        ws_callback,
        0,
        65536, /* rx buffer size */
        0,
        NULL,
        0
    },
    { NULL, NULL, 0, 0, 0, NULL, 0 }
};

/* Pin libwebsockets' global TLS init for the whole process.

   lws refcounts the global OpenSSL init across contexts created with
   LWS_SERVER_OPTION_DO_SSL_GLOBAL_INIT. When that refcount falls to zero (the
   last such context is destroyed) lws runs OPENSSL_cleanup(), which OpenSSL
   1.1+/3.x cannot undo: creating another TLS context then fails, and lws's own
   error reporting dereferences torn-down state and crashes. So a program that
   destroys its TLS context and makes a new one (reconnect-with-fresh-ctx,
   worker recycling, test suites) would break.

   A TLS-using context still needs its own GLOBAL_INIT flag for its TLS to work
   (the flag is per-context: "initialize the SSL library at all"); we keep that.
   This keepalive is a single extra flagged context, created on first TLS use
   and never destroyed or serviced, that holds the refcount floor at >= 1 so no
   user context's teardown can trigger the cleanup. Returns 1 if held.

   Idempotent; single-threaded use only (like the rest of this module). */
static int ensure_ssl_keepalive(void) {
    struct lws_context_creation_info info;
    if (ssl_keepalive_ctx)
        return 1;
    memset(&info, 0, sizeof(info));
    info.port = CONTEXT_PORT_NO_LISTEN;
    info.protocols = protocols;
    info.gid = -1;
    info.uid = -1;
    info.options = LWS_SERVER_OPTION_DO_SSL_GLOBAL_INIT;
    ssl_keepalive_ctx = lws_create_context(&info);
    return ssl_keepalive_ctx != NULL;
}

MODULE = EV::Websockets  PACKAGE = EV::Websockets

BOOT:
{
    I_EV_API("EV::Websockets");
    lws_set_log_level(LLL_ERR | LLL_WARN, NULL);
}

void
_set_debug(int enable);
CODE:
{
    ev_ws_debug = enable;
    if (enable)
        lws_set_log_level(LLL_ERR | LLL_WARN | LLL_NOTICE | LLL_INFO | LLL_DEBUG, NULL);
    else
        lws_set_log_level(LLL_ERR | LLL_WARN, NULL);
}

MODULE = EV::Websockets  PACKAGE = EV::Websockets::Context

EV::Websockets::Context
_new(char* class, EV::Loop loop, const char* proxy = NULL, int proxy_port = 0, const char* ssl_cert = NULL, const char* ssl_key = NULL, const char* ssl_ca = NULL, int ssl_init = -1);
CODE:
{
    struct lws_context_creation_info info;
    void* foreign_loops[1];

    PERL_UNUSED_VAR(class);

    Newxz(RETVAL, 1, ev_ws_ctx_t);
    RETVAL->magic = EV_WS_CTX_MAGIC;
    RETVAL->refcnt = 1; /* Perl owns the context */
    RETVAL->loop = loop;

    foreign_loops[0] = loop;

    memset(&info, 0, sizeof(info));
    info.port = CONTEXT_PORT_NO_LISTEN;
    info.protocols = protocols;
#ifdef LWS_HAS_EXTENSIONS
    info.extensions = extensions;
#endif
    info.gid = -1;
    info.uid = -1;
    /* ssl_init: -1 = manage OpenSSL init (default); 1 = force; 0 = coexist
       (leave it to another TLS library). When we manage it, flag this context
       so its own TLS works, and also pin the global init in a process-lifetime
       keepalive so destroying this context can't drop lws's TLS refcount to
       zero (which would run OPENSSL_cleanup() and break later TLS use). */
    info.options = 0;
    if (ssl_init != 0) {
        info.options = LWS_SERVER_OPTION_DO_SSL_GLOBAL_INIT;
        ensure_ssl_keepalive();
    }
    info.user = RETVAL;
    info.foreign_loops = foreign_loops;
    info.vhost_name = "default";
    
    if (proxy && strlen(proxy) > 0) {
        DEBUG_LOG("Context using proxy: %s:%d", proxy, proxy_port);
        info.http_proxy_address = proxy;
        info.http_proxy_port = proxy_port;
    }

    if (ssl_cert && strlen(ssl_cert) > 0) {
        info.ssl_cert_filepath = ssl_cert;
        info.ssl_private_key_filepath = ssl_key;
        if (ssl_ca && strlen(ssl_ca) > 0)
            info.ssl_ca_filepath = ssl_ca;
    }

    DEBUG_LOG("Creating context (manual integration)");

    RETVAL->lws_ctx = lws_create_context(&info);
    if (RETVAL->lws_ctx == NULL) {
        Safefree(RETVAL);
        croak("Failed to create libwebsockets context");
    }
    ev_timer_init(&RETVAL->timer, timer_cb, 0.00001, 0.);
    RETVAL->timer.data = (void*)RETVAL;

    schedule_timeout(RETVAL);

    DEBUG_LOG("Context created successfully");
}
OUTPUT:
    RETVAL

void
DESTROY(EV::Websockets::Context self);
CODE:
{
    ev_ws_conn_t* conn;
    ev_ws_conn_t* next;

    if (self->magic != EV_WS_CTX_MAGIC) return;

    self->magic = EV_WS_CTX_FREED;

    ev_timer_stop(self->loop, &self->timer);

    free_all_fd_watchers(self);

    /* Release connections still queued for message delivery (no delivery during
       teardown); each holds a flush-list ref. They remain in self->connections
       and are torn down by the loop below. */
    while (self->flush_head) {
        conn = self->flush_head;
        self->flush_head = conn->flush_next;
        conn->on_flush = 0;
        conn->flush_next = NULL;
        conn_unref(conn); /* release the flush-list ref */
    }

    /* Close all connections */
    for (conn = self->connections; conn != NULL; conn = next) {
        next = conn->next;
        conn->ctx = NULL;
        conn->prev = NULL;
        conn->next = NULL;
        if (conn->wsi) {
            lws_set_wsi_user(conn->wsi, NULL);
            conn->wsi = NULL;
        }
        conn_unref(conn); /* drop wsi ref — may free conn */
    }
    self->connections = NULL;

    if (self->lws_ctx) {
        lws_context_destroy(self->lws_ctx);
        self->lws_ctx = NULL;
    }

    self->loop = NULL;
    if (self->alive_flag) *self->alive_flag = 0;
    ctx_unref(self); /* drops Perl ref; Safefree happens when refcnt==0 */
}

EV::Websockets::Connection
connect(EV::Websockets::Context self, ...);
PREINIT:
    struct lws_client_connect_info ccinfo;
    const char* url = NULL;
    const char* protocol = NULL;
    char* host = NULL;
    char* host_header = NULL; /* for IPv6: "[::1]" form */
    char* path = NULL;
    int port = 80;
    int use_ssl = 0;
    int ssl_verify = 1;
    char* url_copy = NULL;
    char* p;
    char* path_start;
    SV* on_connect = NULL;
    SV* on_message = NULL;
    SV* on_close = NULL;
    SV* on_error = NULL;
    SV* on_pong = NULL;
    SV* on_drain = NULL;
    SV* headers_hv = NULL;
    size_t max_message_size = 0;
    double connect_timeout = 0;
    int i;
CODE:
{
    if (self->magic != EV_WS_CTX_MAGIC) {
        croak("Context has been destroyed");
    }

    for (i = 1; i < items; i += 2) {
        if (i + 1 >= items) break;
        const char* key = SvPV_nolen(ST(i));
        SV* val = ST(i + 1);

        if (strcmp(key, "url") == 0) {
            url = SvPV_nolen(val);
        } else if (strcmp(key, "protocol") == 0) {
            protocol = SvPV_nolen(val);
        } else if (strcmp(key, "ssl_verify") == 0) {
            ssl_verify = SvTRUE(val);
        } else if (strcmp(key, "max_message_size") == 0) {
            max_message_size = (size_t)SvUV(val);
        } else if (strcmp(key, "connect_timeout") == 0) {
            connect_timeout = SvNV(val);
        } else if (strcmp(key, "headers") == 0 && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV) {
            headers_hv = val;
        } else if (strcmp(key, "on_connect") == 0 && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV) {
            on_connect = SvREFCNT_inc(val);
        } else if (strcmp(key, "on_message") == 0 && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV) {
            on_message = SvREFCNT_inc(val);
        } else if (strcmp(key, "on_close") == 0 && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV) {
            on_close = SvREFCNT_inc(val);
        } else if (strcmp(key, "on_error") == 0 && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV) {
            on_error = SvREFCNT_inc(val);
        } else if (strcmp(key, "on_pong") == 0 && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV) {
            on_pong = SvREFCNT_inc(val);
        } else if (strcmp(key, "on_drain") == 0 && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV) {
            on_drain = SvREFCNT_inc(val);
        }
    }

    if (url == NULL) {
        free_cb_svs(on_connect, on_message, on_close, on_error, on_pong, on_drain, NULL);
        croak("url parameter is required");
    }

    Newx(url_copy, strlen(url) + 1, char);
    strcpy(url_copy, url);

    if (strncasecmp(url_copy, "wss://", 6) == 0) {
        use_ssl = LCCSCF_USE_SSL;
        if (!ssl_verify) {
            use_ssl |= LCCSCF_ALLOW_SELFSIGNED
                     | LCCSCF_SKIP_SERVER_CERT_HOSTNAME_CHECK
                     | LCCSCF_ALLOW_INSECURE;
        }
        port = 443;
        host = url_copy + 6;
    } else if (strncasecmp(url_copy, "ws://", 5) == 0) {
        host = url_copy + 5;
    } else {
        Safefree(url_copy);
        free_cb_svs(on_connect, on_message, on_close, on_error, on_pong, on_drain, NULL);
        croak("URL must start with ws:// or wss://");
    }

    path_start = strchr(host, '/');
    if (path_start) {
        /* Allocate separate path string */
        Newx(path, strlen(path_start) + 1, char);
        strcpy(path, path_start);
        *path_start = '\0';  /* Terminate host */
    } else {
        Newx(path, 2, char);
        strcpy(path, "/");
    }

    /* Find port in host (handle IPv6 bracket notation) */
    if (host[0] == '[') {
        p = strchr(host, ']');
        if (p) {
            size_t iplen = p - host - 1;
            int hport = 0;
            host++;    /* skip '[' */
            if (*(p + 1) == ':') {
                hport = atoi(p + 2);
                port = hport;
            }
            *p = '\0'; /* terminate IPv6 address */
            Newx(host_header, iplen + 10, char); /* [addr]:port\0 */
            if (hport && hport != (use_ssl ? 443 : 80))
                snprintf(host_header, iplen + 10, "[%s]:%d", host, hport);
            else
                snprintf(host_header, iplen + 10, "[%s]", host);
        }
    } else {
        p = strchr(host, ':');
        if (p) {
            *p = '\0';
            port = atoi(p + 1);
        }
    }

    Newxz(RETVAL, 1, ev_ws_conn_t);
    RETVAL->magic = EV_WS_CONN_MAGIC;
    RETVAL->refcnt = 2; /* wsi ref + sentinel (protects against sync WSI_DESTROY) */
    RETVAL->on_connect = on_connect;
    RETVAL->on_message = on_message;
    RETVAL->on_close = on_close;
    RETVAL->on_error = on_error;
    RETVAL->on_pong = on_pong;
    RETVAL->on_drain = on_drain;
    RETVAL->max_message_size = max_message_size;
    RETVAL->loop = self->loop;

    link_conn(self, RETVAL);

    memset(&ccinfo, 0, sizeof(ccinfo));
    ccinfo.context = self->lws_ctx;
    ccinfo.address = host;
    ccinfo.port = port;
    ccinfo.path = path;
    ccinfo.host = host_header ? host_header : host;
    ccinfo.origin = host_header ? host_header : host;
    ccinfo.protocol = protocol;
#ifdef LWS_HAS_EXTENSIONS
    ccinfo.client_exts = extensions;
#endif
    ccinfo.ssl_connection = use_ssl;
    ccinfo.userdata = RETVAL;

    if (headers_hv) {
        RETVAL->custom_headers = (HV*)SvREFCNT_inc(SvRV(headers_hv));
    }

    RETVAL->wsi = lws_client_connect_via_info(&ccinfo);

    Safefree(path);
    Safefree(host_header);
    Safefree(url_copy);

    if (RETVAL->wsi == NULL) {
        unlink_conn(RETVAL);
        if (RETVAL->perl_self == NULL) {
            free_conn_resources(RETVAL);
            RETVAL->magic = EV_WS_CONN_FREED;
            Safefree(RETVAL);
        } else {
            conn_unref(RETVAL); /* drop sentinel; Perl DESTROY will handle final cleanup */
        }
        croak("Failed to initiate WebSocket connection");
    }
    conn_unref(RETVAL); /* drop sentinel */

    if (connect_timeout > 0) {
        ev_timer_init(&RETVAL->connect_timer, connect_timeout_cb, connect_timeout, 0.);
        RETVAL->connect_timer.data = (void*)RETVAL;
        ev_timer_start(self->loop, &RETVAL->connect_timer);
        RETVAL->connect_timer_active = 1;
    }
}
OUTPUT:
    RETVAL

int
listen(EV::Websockets::Context self, ...);
PREINIT:
    struct lws_context_creation_info info;
    int port = 0;
    const char *name = "server";
    const char *ssl_cert = NULL;
    const char *ssl_key = NULL;
    const char *ssl_ca = NULL;
    SV* on_connect = NULL;
    SV* on_message = NULL;
    SV* on_close = NULL;
    SV* on_error = NULL;
    SV* on_pong = NULL;
    SV* on_drain = NULL;
    SV* on_handshake = NULL;
    SV* headers_hv = NULL;
    size_t max_message_size = 0;
    const char *protocol_name = NULL;
    ev_ws_server_t *srv;
    struct lws_vhost *vh;
    int i;
CODE:
{
    if (self->magic != EV_WS_CTX_MAGIC) {
        croak("Context has been destroyed");
    }

    for (i = 1; i < items; i += 2) {
        if (i + 1 >= items) break;
        const char* key = SvPV_nolen(ST(i));
        SV* val = ST(i + 1);

        if (strcmp(key, "port") == 0) {
            port = SvIV(val);
        } else if (strcmp(key, "name") == 0) {
            name = SvPV_nolen(val);
        } else if (strcmp(key, "protocol") == 0) {
            protocol_name = SvPV_nolen(val);
        } else if (strcmp(key, "ssl_cert") == 0) {
            ssl_cert = SvPV_nolen(val);
        } else if (strcmp(key, "ssl_key") == 0) {
            ssl_key = SvPV_nolen(val);
        } else if (strcmp(key, "ssl_ca") == 0) {
            ssl_ca = SvPV_nolen(val);
        } else if (strcmp(key, "max_message_size") == 0) {
            max_message_size = (size_t)SvUV(val);
        } else if (strcmp(key, "headers") == 0 && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV) {
            headers_hv = val;
        } else if (strcmp(key, "on_connect") == 0 && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV) {
            on_connect = SvREFCNT_inc(val);
        } else if (strcmp(key, "on_message") == 0 && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV) {
            on_message = SvREFCNT_inc(val);
        } else if (strcmp(key, "on_close") == 0 && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV) {
            on_close = SvREFCNT_inc(val);
        } else if (strcmp(key, "on_error") == 0 && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV) {
            on_error = SvREFCNT_inc(val);
        } else if (strcmp(key, "on_pong") == 0 && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV) {
            on_pong = SvREFCNT_inc(val);
        } else if (strcmp(key, "on_drain") == 0 && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV) {
            on_drain = SvREFCNT_inc(val);
        } else if (strcmp(key, "on_handshake") == 0 && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV) {
            on_handshake = SvREFCNT_inc(val);
        }
    }

    if (strcmp(name, "default") == 0) {
        free_cb_svs(on_connect, on_message, on_close, on_error, on_pong, on_drain, on_handshake);
        croak("listen: vhost name 'default' is reserved");
    }

    Newxz(srv, 1, ev_ws_server_t);
    srv->magic = EV_WS_SRV_MAGIC;
    srv->on_connect = on_connect;
    srv->on_message = on_message;
    srv->on_close = on_close;
    srv->on_error = on_error;
    srv->on_pong = on_pong;
    srv->on_drain = on_drain;
    srv->on_handshake = on_handshake;
    srv->max_message_size = max_message_size;
    if (headers_hv)
        srv->response_headers = (HV*)SvREFCNT_inc(SvRV(headers_hv));

    if (protocol_name) {
        STRLEN pnlen = strlen(protocol_name);
        Newx(srv->protocol_name, pnlen + 1, char);
        memcpy(srv->protocol_name, protocol_name, pnlen + 1);
        srv->vhost_protocols[0] = protocols[0];
        srv->vhost_protocols[0].name = srv->protocol_name;
        srv->vhost_protocols[1] = protocols[1];
    }

    memset(&info, 0, sizeof(info));
    info.port = port;
    info.protocols = srv->protocol_name ? srv->vhost_protocols : protocols;
    info.vhost_name = name;
    info.user = srv;
    info.options = 0;

    if (ssl_cert && ssl_key) {
        info.ssl_cert_filepath = ssl_cert;
        info.ssl_private_key_filepath = ssl_key;
        if (ssl_ca)
            info.ssl_ca_filepath = ssl_ca;
        info.options |= LWS_SERVER_OPTION_DO_SSL_GLOBAL_INIT;
        ensure_ssl_keepalive(); /* pin global init so vhost/context teardown won't OPENSSL_cleanup */
    }

    vh = lws_create_vhost(self->lws_ctx, &info);
    if (vh == NULL) {
        free_server_svs(srv);
        if (srv->protocol_name) Safefree(srv->protocol_name);
        Safefree(srv);
        croak("Failed to create vhost for listening");
    }
    
    RETVAL = lws_get_vhost_listen_port(vh);
    if (RETVAL <= 0) {
        /* Vhost created but port bind failed. Release the SV refs now, but
           leave protocol_name alive — the live vhost still points at it via
           vhost_protocols[0].name, so freeing it here would dangle. Do NOT
           Safefree(srv): the vhost retains the pointer. PROTOCOL_DESTROY frees
           protocol_name and srv at context teardown; the SRV_FREED sentinel
           tells it to skip the (already-released) SV refs. */
        free_server_svs(srv);
        srv->magic = EV_WS_SRV_FREED;
        croak("listen: failed to bind port");
    }
    DEBUG_LOG("Server listening on port %d", RETVAL);
}
OUTPUT:
    RETVAL

EV::Websockets::Connection
adopt(EV::Websockets::Context self, ...);
PREINIT:
    int fd = -1;
    SV* fh_sv = NULL;
    SV* initial_data_sv = NULL;
    SV* on_connect = NULL;
    SV* on_message = NULL;
    SV* on_close = NULL;
    SV* on_error = NULL;
    SV* on_pong = NULL;
    SV* on_drain = NULL;
    size_t max_message_size = 0;
    int i;
CODE:
{
    if (self->magic != EV_WS_CTX_MAGIC) {
        croak("Context has been destroyed");
    }

    for (i = 1; i < items; i += 2) {
        if (i + 1 >= items) break;
        const char* key = SvPV_nolen(ST(i));
        SV* val = ST(i + 1);

        if (strcmp(key, "fh") == 0) {
            fh_sv = val;
        } else if (strcmp(key, "initial_data") == 0) {
            initial_data_sv = val;
        } else if (strcmp(key, "max_message_size") == 0) {
            max_message_size = (size_t)SvUV(val);
        } else if (strcmp(key, "on_connect") == 0 && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV) {
            on_connect = SvREFCNT_inc(val);
        } else if (strcmp(key, "on_message") == 0 && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV) {
            on_message = SvREFCNT_inc(val);
        } else if (strcmp(key, "on_close") == 0 && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV) {
            on_close = SvREFCNT_inc(val);
        } else if (strcmp(key, "on_error") == 0 && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV) {
            on_error = SvREFCNT_inc(val);
        } else if (strcmp(key, "on_pong") == 0 && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV) {
            on_pong = SvREFCNT_inc(val);
        } else if (strcmp(key, "on_drain") == 0 && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV) {
            on_drain = SvREFCNT_inc(val);
        }
    }

    if (fh_sv == NULL) {
        free_cb_svs(on_connect, on_message, on_close, on_error, on_pong, on_drain, NULL);
        croak("fh parameter is required");
    }

    IO* io = sv_2io(fh_sv);
    PerlIO *ifp = io ? IoIFP(io) : NULL;
    if (!ifp || (fd = PerlIO_fileno(ifp)) < 0) {
        free_cb_svs(on_connect, on_message, on_close, on_error, on_pong, on_drain, NULL);
        croak("Invalid filehandle");
    }

    Newxz(RETVAL, 1, ev_ws_conn_t);
    RETVAL->magic = EV_WS_CONN_MAGIC;
    RETVAL->refcnt = 2; /* wsi ref + sentinel (protects against sync WSI_DESTROY) */
    RETVAL->on_connect = on_connect;
    RETVAL->on_message = on_message;
    RETVAL->on_close = on_close;
    RETVAL->on_error = on_error;
    RETVAL->on_pong = on_pong;
    RETVAL->on_drain = on_drain;
    RETVAL->max_message_size = max_message_size;
    RETVAL->loop = self->loop;
    /* Hold a reference to the underlying glob/IO to prevent Perl
     * from closing the fd while lws owns it.  For blessed glob refs
     * (IO::Socket etc.) we ref the glob itself so framework DESTROY
     * methods see it as still alive. */
    RETVAL->adopted_fh = SvROK(fh_sv) ? newRV_inc(SvRV(fh_sv))
                                       : SvREFCNT_inc(fh_sv);

    link_conn(self, RETVAL);

    {
        struct lws_vhost *vh = lws_get_vhost_by_name(self->lws_ctx, "server");
        if (!vh) {
            /* Auto-create a server vhost for adoption (no listener needed) */
            struct lws_context_creation_info vinfo;
            memset(&vinfo, 0, sizeof(vinfo));
            vinfo.port = CONTEXT_PORT_NO_LISTEN_SERVER;
            vinfo.protocols = protocols;
            vinfo.vhost_name = "server";
            vh = lws_create_vhost(self->lws_ctx, &vinfo);
        }
        if (!vh) {
            unlink_conn(RETVAL);
            free_conn_resources(RETVAL);
            RETVAL->magic = EV_WS_CONN_FREED;
            Safefree(RETVAL);
            croak("Failed to create vhost for adoption");
        }
        pending_adoption = RETVAL;
        if (initial_data_sv && SvOK(initial_data_sv)) {
            STRLEN rdlen;
            const char *rdbuf = SvPV(initial_data_sv, rdlen);
            RETVAL->wsi = lws_adopt_socket_vhost_readbuf(vh,
                (lws_sockfd_type)fd, rdbuf, rdlen);
        } else {
            RETVAL->wsi = lws_adopt_socket_vhost(vh, (lws_sockfd_type)fd);
        }
        pending_adoption = NULL;
    }

    if (RETVAL->wsi == NULL) {
        unlink_conn(RETVAL);
        if (RETVAL->perl_self == NULL) {
            free_conn_resources(RETVAL);
            RETVAL->magic = EV_WS_CONN_FREED;
            Safefree(RETVAL);
        } else {
            conn_unref(RETVAL);
        }
        croak("Failed to adopt socket");
    }
    conn_unref(RETVAL); /* drop sentinel */

    /* Kick lws to process the adopted socket's readbuf (needed for lws 4.5+).
     * Use the same non-blocking forced-service call as do_lws_service: the
     * readbuf is pending work, so lws_service_tsi(ctx, -1, 0) drains it without
     * blocking. A plain lws_service(ctx, 0) would block the EV loop here when a
     * socket is adopted with no immediately-pending data.
     * Guard with extra refs: the service call may synchronously fire
     * error/destroy callbacks that would free RETVAL or ctx. */
    {
        int rejected, alive = 1;
        int* prev_flag = self->alive_flag;
        conn_ref(RETVAL);
        ctx_ref(self);
        self->alive_flag = &alive;
        lws_service_tsi(self->lws_ctx, -1, 0);
        if (alive)
            flush_recv_messages(self); /* deliver any reassembled message */
        if (alive) {
            self->alive_flag = prev_flag;
            schedule_timeout(self);
        } else if (prev_flag) {
            /* Context destroyed during inner lws_service.
               Propagate destruction up the alive_flag chain. */
            *prev_flag = 0;
        }
        rejected = (RETVAL->wsi == NULL);
        conn_unref(RETVAL);
        ctx_unref(self);
        if (rejected)
            croak("Failed to adopt socket");
    }
}
OUTPUT:
    RETVAL

void
connections(EV::Websockets::Context self);
PPCODE:
{
    ev_ws_conn_t* conn;
    if (self->magic != EV_WS_CTX_MAGIC) XSRETURN_EMPTY;
    for (conn = self->connections; conn != NULL; conn = conn->next) {
        /* "connected" stays set during the "closing" drain (close() never
           clears it), and is cleared together with wsi on teardown — so this
           single predicate covers both the "connected" and "closing" states. */
        if (conn->magic == EV_WS_CONN_MAGIC && conn->connected) {
            XPUSHs(sv_2mortal(get_conn_sv(conn)));
        }
    }
}

MODULE = EV::Websockets  PACKAGE = EV::Websockets::Connection

void
DESTROY(EV::Websockets::Connection self);
CODE:
{
    if (self->magic != EV_WS_CONN_MAGIC) return;

    DEBUG_LOG("Perl object DESTROY: self=%p wsi=%p", self, self->wsi);

    /* Clear the cached Perl object pointer in the C struct */
    self->perl_self = NULL;

    conn_unref(self); /* drop Perl ref */
}

void
send(EV::Websockets::Connection self, SV* data);
CODE:
{
    STRLEN len;
    const char* buf;

    CHECK_CONN_OPEN(self);
    CHECK_NOT_FRAGMENTING(self);

    buf = SvPV(data, len);
    queue_send(self, buf, len, LWS_WRITE_TEXT);
}

void
send_binary(EV::Websockets::Connection self, SV* data);
CODE:
{
    STRLEN len;
    const char* buf;

    CHECK_CONN_OPEN(self);
    CHECK_NOT_FRAGMENTING(self);

    buf = SvPV(data, len);
    queue_send(self, buf, len, LWS_WRITE_BINARY);
}

void
send_ping(EV::Websockets::Connection self, SV* data = NULL);
CODE:
{
    STRLEN len = 0;
    const char* buf = NULL;
    
    CHECK_CONN_OPEN(self);
    
    if (data && SvOK(data)) {
        buf = SvPV(data, len);
        if (len > 125) len = 125; /* PING payload limit */
    }
    
    queue_send(self, buf, len, LWS_WRITE_PING);
}

SV*
get_protocol(EV::Websockets::Connection self);
CODE:
{
    SV* val = NULL;
    if (self->magic == EV_WS_CONN_MAGIC && self->wsi)
        val = hdr_to_sv(self->wsi, WSI_TOKEN_PROTOCOL);
    RETVAL = val ? val : newSV(0);
}
OUTPUT:
    RETVAL

SV*
peer_address(EV::Websockets::Connection self);
CODE:
{
    char buf[128];
    buf[0] = '\0';
    RETVAL = newSV(0);
    if (self->magic == EV_WS_CONN_MAGIC && self->wsi) {
        lws_get_peer_simple(self->wsi, buf, sizeof(buf));
        if (buf[0])
            sv_setpv(RETVAL, buf);
    }
}
OUTPUT:
    RETVAL

void
send_pong(EV::Websockets::Connection self, SV* data = NULL);
CODE:
{
    STRLEN len = 0;
    const char* buf = NULL;

    CHECK_CONN_OPEN(self);

    if (data && SvOK(data)) {
        buf = SvPV(data, len);
        if (len > 125) len = 125;
    }

    queue_send(self, buf, len, LWS_WRITE_PONG);
}

void
pause_recv(EV::Websockets::Connection self);
CODE:
{
    if (self->magic == EV_WS_CONN_MAGIC && self->wsi && self->connected)
        lws_rx_flow_control(self->wsi, 0);
}

void
resume_recv(EV::Websockets::Connection self);
CODE:
{
    if (self->magic == EV_WS_CONN_MAGIC && self->wsi && self->connected)
        lws_rx_flow_control(self->wsi, 1);
}

void
close(EV::Websockets::Connection self, int code = 1000, const char* reason = NULL);
CODE:
{
    if (self->magic != EV_WS_CONN_MAGIC) {
        return;
    }
    if (!self->wsi || !self->connected || self->closing) {
        return;
    }

    DEBUG_LOG("Closing connection: code=%d reason=%s", code, reason ? reason : "none");
    if (self->in_fragmented_send) {
        queue_send(self, NULL, 0, LWS_WRITE_CONTINUATION);
        self->in_fragmented_send = 0;
    }
    self->closing = 1;
    lws_close_reason(self->wsi, (enum lws_close_status)code,
                     reason ? (unsigned char*)reason : NULL,
                     reason ? strlen(reason) : 0);
    lws_callback_on_writable(self->wsi);
}

int
is_connected(EV::Websockets::Connection self);
CODE:
{
    RETVAL = (self->magic == EV_WS_CONN_MAGIC && self->wsi != NULL && self->connected) ? 1 : 0;
}
OUTPUT:
    RETVAL

int
is_connecting(EV::Websockets::Connection self);
CODE:
{
    RETVAL = (self->magic == EV_WS_CONN_MAGIC && self->wsi != NULL && !self->connected && !self->closing) ? 1 : 0;
}
OUTPUT:
    RETVAL

const char*
state(EV::Websockets::Connection self);
CODE:
{
    if (self->magic != EV_WS_CONN_MAGIC) RETVAL = "destroyed";
    else if (!self->wsi) RETVAL = "closed";
    else if (self->closing) RETVAL = "closing";
    else if (self->connected) RETVAL = "connected";
    else RETVAL = "connecting";
}
OUTPUT:
    RETVAL

UV
send_queue_size(EV::Websockets::Connection self);
CODE:
{
    RETVAL = (self->magic == EV_WS_CONN_MAGIC) ? (UV)self->send_queue_bytes : 0;
}
OUTPUT:
    RETVAL

void
send_fragment(EV::Websockets::Connection self, SV* data, int is_binary = 0, int is_final = 1);
CODE:
{
    STRLEN len;
    const char* buf;
    enum lws_write_protocol mode;

    CHECK_CONN_OPEN(self);

    buf = SvPV(data, len);

    if (!self->in_fragmented_send) {
        mode = is_binary ? LWS_WRITE_BINARY : LWS_WRITE_TEXT;
        if (!is_final) {
            mode |= LWS_WRITE_NO_FIN;
            self->in_fragmented_send = 1;
        }
    } else {
        mode = LWS_WRITE_CONTINUATION;
        if (!is_final) {
            mode |= LWS_WRITE_NO_FIN;
        } else {
            self->in_fragmented_send = 0;
        }
    }

    queue_send(self, buf, len, mode);
}

SV*
stash(EV::Websockets::Connection self);
CODE:
{
    if (self->magic != EV_WS_CONN_MAGIC)
        croak("Connection has been destroyed");
    if (!self->stash)
        self->stash = newHV();
    RETVAL = newRV_inc((SV*)self->stash);
}
OUTPUT:
    RETVAL
