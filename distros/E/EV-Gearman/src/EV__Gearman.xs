#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "EVAPI.h"
#include "ngx-queue.h"

#include <sys/socket.h>
#include <sys/un.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <netdb.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <arpa/inet.h>

/* ================================================================
 * Gearman binary protocol constants
 *
 * Wire format (all integers big-endian):
 *   Bytes 0-3 : magic - "\0REQ" for client->server, "\0RES" for server->client
 *   Bytes 4-7 : command (uint32 BE)
 *   Bytes 8-11: data length (uint32 BE)
 *   Bytes 12+ : data, with NUL-separated args; final arg has no terminator
 * ================================================================ */

#define GM_MAGIC_REQ "\0REQ"
#define GM_MAGIC_RES "\0RES"
#define GM_HEADER_SIZE 12

#define GM_MAGIC_ALIVE 0xCA7C00FE
#define GM_MAGIC_FREED 0xDEAD0FF0

/* Commands (request: client/worker -> server) */
#define GM_CMD_CAN_DO              1
#define GM_CMD_CANT_DO             2
#define GM_CMD_RESET_ABILITIES     3
#define GM_CMD_PRE_SLEEP           4
#define GM_CMD_NOOP                6
#define GM_CMD_SUBMIT_JOB          7
#define GM_CMD_JOB_CREATED         8
#define GM_CMD_GRAB_JOB            9
#define GM_CMD_NO_JOB              10
#define GM_CMD_JOB_ASSIGN          11
#define GM_CMD_WORK_STATUS         12
#define GM_CMD_WORK_COMPLETE       13
#define GM_CMD_WORK_FAIL           14
#define GM_CMD_GET_STATUS          15
#define GM_CMD_ECHO_REQ            16
#define GM_CMD_ECHO_RES            17
#define GM_CMD_SUBMIT_JOB_BG       18
#define GM_CMD_ERROR               19
#define GM_CMD_STATUS_RES          20
#define GM_CMD_SUBMIT_JOB_HIGH     21
#define GM_CMD_SET_CLIENT_ID       22
#define GM_CMD_CAN_DO_TIMEOUT      23
#define GM_CMD_ALL_YOURS           24
#define GM_CMD_WORK_EXCEPTION      25
#define GM_CMD_OPTION_REQ          26
#define GM_CMD_OPTION_RES          27
#define GM_CMD_WORK_DATA           28
#define GM_CMD_WORK_WARNING        29
#define GM_CMD_GRAB_JOB_UNIQ       30
#define GM_CMD_JOB_ASSIGN_UNIQ     31
#define GM_CMD_SUBMIT_JOB_HIGH_BG  32
#define GM_CMD_SUBMIT_JOB_LOW      33
#define GM_CMD_SUBMIT_JOB_LOW_BG   34
#define GM_CMD_SUBMIT_JOB_SCHED    35
#define GM_CMD_SUBMIT_JOB_EPOCH    36
#define GM_CMD_GET_STATUS_UNIQUE   41
#define GM_CMD_STATUS_RES_UNIQUE   42

/* Internal request types (CB_*) — describe what we're waiting for */
#define CB_ECHO            1   /* expects ECHO_RES */
#define CB_SUBMIT          2   /* expects JOB_CREATED + work events */
#define CB_SUBMIT_BG       3   /* expects JOB_CREATED only */
#define CB_GET_STATUS      4   /* expects STATUS_RES */
#define CB_GET_STATUS_UNIQ 5   /* expects STATUS_RES_UNIQUE */
#define CB_OPTION          6   /* expects OPTION_RES */
#define CB_GRAB_JOB        7   /* expects JOB_ASSIGN | JOB_ASSIGN_UNIQ | NO_JOB */
#define CB_ADMIN           8   /* expects text-protocol response */

#define BUF_INIT_SIZE 16384
#define GM_MAX_PACKET (256u * 1024u * 1024u)  /* 256 MB sanity bound */
/* Once a buffer has fully drained, release it back to BUF_INIT_SIZE if
   it grew past this — a single large packet otherwise pins its
   high-water-mark allocation for the life of the connection. */
#define BUF_SHRINK_THRESHOLD (1u * 1024u * 1024u)

#define CLEAR_HANDLER(field) \
    do { if (NULL != (field)) { SvREFCNT_dec(field); (field) = NULL; } } while(0)

/* Silently drain an ngx_queue, freeing each entry via its cleanup
   function. Used during global destruction and DESTROY where invoking
   Perl callbacks would be unsafe / pointless. */
#define DRAIN_QUEUE_SILENT(qhead, type, cleanup) \
    while (!ngx_queue_empty(qhead)) { \
        ngx_queue_t *_q = ngx_queue_head(qhead); \
        type *_e = ngx_queue_data(_q, type, queue); \
        ngx_queue_remove(_q); \
        cleanup(aTHX_ _e); \
    }

#define GM_CROAK_UNLESS_ALIVE(self) \
    do { \
        if (!(self)->connected && !(self)->connecting && \
            !((self)->reconnect && (self)->reconnect_timer_active)) \
            croak("not connected"); \
    } while(0)

/* ================================================================
 * Type declarations
 * ================================================================ */

typedef struct ev_gm_s ev_gm_t;
typedef struct ev_gm_req_s ev_gm_req_t;
typedef struct ev_gm_wait_s ev_gm_wait_t;
typedef struct ev_gm_func_s ev_gm_func_t;
typedef struct ev_gm_active_s ev_gm_active_t;

typedef ev_gm_t* EV__Gearman;
typedef struct ev_loop* EV__Loop;

/* Request awaiting a response (FIFO). For SUBMIT_JOB, holds the
 * callback bundle that gets transferred to active_jobs once the
 * JOB_CREATED handle is known. */
struct ev_gm_req_s {
    ngx_queue_t queue;
    int kind;          /* CB_* */
    SV *cb;            /* primary callback (handle for BG, result for FG) */
    SV *on_data;
    SV *on_warning;
    SV *on_status;
    SV *on_exception;
    int admin_terminator; /* 0 = single-line; 1 = ".\n" terminator (status/workers) */
};

/* Pending packet awaiting connect / drain */
struct ev_gm_wait_s {
    ngx_queue_t queue;
    char *packet;
    size_t packet_len;
    /* if non-NULL, becomes a request entry on send */
    ev_gm_req_t *req;
};

/* Active foreground job (after JOB_CREATED) */
struct ev_gm_active_s {
    ngx_queue_t queue;
    char *handle;
    STRLEN handle_len;
    SV *on_complete;
    SV *on_data;
    SV *on_warning;
    SV *on_status;
    SV *on_exception;
};

/* Registered worker function */
struct ev_gm_func_s {
    ngx_queue_t queue;
    char *name;
    SV *cb;
    int async;     /* if 1, callback returns nothing; user calls $job->complete */
    int timeout;   /* seconds; 0 = no timeout */
};

struct ev_gm_s {
    unsigned int magic;
    struct ev_loop *loop;
    int fd;
    int connected;
    int connecting;

    /* IO watchers */
    ev_io rio, wio;
    int reading, writing;

    /* Buffers */
    char *rbuf;
    size_t rbuf_len, rbuf_cap;
    char *wbuf;
    size_t wbuf_len, wbuf_off, wbuf_cap;

    /* User-level callbacks */
    SV *on_error;
    SV *on_connect;
    SV *on_disconnect;

    /* FIFO of requests awaiting a binary response */
    ngx_queue_t cb_queue;
    int pending_count;

    /* Pending packets awaiting transmission (e.g. before connect) */
    ngx_queue_t wait_queue;
    int waiting_count;

    /* Active jobs (foreground) by handle */
    ngx_queue_t active_jobs;
    int active_count_cached;

    /* Worker state */
    ngx_queue_t functions;
    int worker_active;       /* in worker loop */
    int worker_sleeping;     /* PRE_SLEEP issued, awaiting NOOP */
    int worker_grab_inflight;/* GRAB_JOB[_UNIQ] in flight */
    int worker_grab_uniq;    /* prefer GRAB_JOB_UNIQ */
    SV *worker_on_idle;      /* fires when no jobs available */
    int worker_one_shot;     /* if 1, exit worker loop after first job */
    char *client_id;         /* for SET_CLIENT_ID */

    /* Connection target */
    char *host;
    int port;
    char *path;

    /* Reconnect */
    int reconnect;
    int reconnect_delay_ms;
    int max_reconnect_attempts;
    int reconnect_attempts;
    ev_timer reconnect_timer;
    int reconnect_timer_active;
    int intentional_disconnect;

    /* Timeouts */
    int connect_timeout_ms;
    ev_timer connect_timer;
    int connect_timer_active;
    int command_timeout_ms;
    ev_timer cmd_timer;
    int cmd_timer_active;

    /* Safety */
    int callback_depth;
    int in_cb_cleanup;
    int in_wait_cleanup;
    int in_active_cleanup;

    /* Options */
    int priority;
    int keepalive;

    /* Options sent on connect */
    int opt_exceptions;
};

/* ================================================================
 * Shared error strings
 * ================================================================ */

static SV *err_disconnected = NULL;

/* ================================================================
 * Forward declarations
 * ================================================================ */

static void io_cb(EV_P_ ev_io *w, int revents);
static void reconnect_timer_cb(EV_P_ ev_timer *w, int revents);
static void connect_timeout_cb(EV_P_ ev_timer *w, int revents);
static void cmd_timeout_cb(EV_P_ ev_timer *w, int revents);
static void start_reading(ev_gm_t *self);
static void stop_reading(ev_gm_t *self);
static void start_writing(ev_gm_t *self);
static void stop_writing(ev_gm_t *self);
static void start_connect(pTHX_ ev_gm_t *self);
static void cleanup_connection(pTHX_ ev_gm_t *self);
static void emit_error(pTHX_ ev_gm_t *self, const char *msg);
static void handle_disconnect(pTHX_ ev_gm_t *self, const char *reason);
static void schedule_reconnect(pTHX_ ev_gm_t *self);
static void apply_keepalive(ev_gm_t *self);
static void report_connect_error(pTHX_ ev_gm_t *self, const char *errbuf);
static void finish_connect_success(pTHX_ ev_gm_t *self);
static void stop_connect_timer(ev_gm_t *self);
static void stop_reconnect_timer(ev_gm_t *self);
static int  check_destroyed(ev_gm_t *self);
static void cancel_pending(pTHX_ ev_gm_t *self, SV *err_sv);
static void cancel_waiting(pTHX_ ev_gm_t *self, SV *err_sv);
static void cancel_active(pTHX_ ev_gm_t *self, SV *err_sv);
static void send_pending_waits(pTHX_ ev_gm_t *self);
static void arm_cmd_timer(ev_gm_t *self);
static void disarm_cmd_timer(ev_gm_t *self);
static void enqueue_packet(pTHX_ ev_gm_t *self,
    uint32_t cmd, const char *data, size_t data_len, ev_gm_req_t *req);
static void worker_continue(pTHX_ ev_gm_t *self);
static void worker_send_grab(pTHX_ ev_gm_t *self);
static void worker_send_pre_sleep(pTHX_ ev_gm_t *self);
static ev_gm_func_t* find_function(ev_gm_t *self, const char *name, STRLEN len);

/* ================================================================
 * Big-endian helpers (no unaligned access)
 * ================================================================ */

static void gm_write_u32(char *buf, uint32_t val) {
    val = htonl(val);
    memcpy(buf, &val, 4);
}

static uint32_t gm_read_u32(const char *buf) {
    uint32_t val;
    memcpy(&val, buf, 4);
    return ntohl(val);
}

/* atoi/strtol on a length-bounded ASCII run that may not be NUL-terminated
   (gm_arg's last field returns a pointer with no trailing NUL since the
   separator-NUL only lives between fields). Copies up to 31 bytes onto
   the stack first. */
static IV gm_atoi_n(const char *p, size_t len) {
    char buf[32];
    if (len > sizeof(buf) - 1) len = sizeof(buf) - 1;
    memcpy(buf, p, len);
    buf[len] = '\0';
    return (IV)atoi(buf);
}

/* ================================================================
 * Buffer management
 * ================================================================ */

static void buf_ensure_write(ev_gm_t *self, size_t needed) {
    /* Compact first to reclaim already-sent prefix. */
    if (self->wbuf_off > 0) {
        size_t live = self->wbuf_len - self->wbuf_off;
        if (live > 0)
            memmove(self->wbuf, self->wbuf + self->wbuf_off, live);
        self->wbuf_len = live;
        self->wbuf_off = 0;
    }
    size_t total = self->wbuf_len + needed;
    if (self->wbuf_cap >= total) return;
    size_t new_cap = self->wbuf_cap ? self->wbuf_cap : BUF_INIT_SIZE;
    while (new_cap < total) new_cap *= 2;
    Renew(self->wbuf, new_cap, char);
    self->wbuf_cap = new_cap;
}

static void buf_ensure_read(ev_gm_t *self, size_t needed) {
    size_t total = self->rbuf_len + needed;
    if (self->rbuf_cap >= total) return;
    size_t new_cap = self->rbuf_cap ? self->rbuf_cap : BUF_INIT_SIZE;
    while (new_cap < total) new_cap *= 2;
    Renew(self->rbuf, new_cap, char);
    self->rbuf_cap = new_cap;
}

static void buf_append_write(ev_gm_t *self, const char *data, size_t len) {
    buf_ensure_write(self, len);
    memcpy(self->wbuf + self->wbuf_len, data, len);
    self->wbuf_len += len;
}

/* Release an oversized, fully-drained buffer back to the initial size.
   Caller guarantees the buffer holds no live bytes. */
static void buf_maybe_shrink(char **buf, size_t *cap) {
    if (*cap > BUF_SHRINK_THRESHOLD) {
        Renew(*buf, BUF_INIT_SIZE, char);
        *cap = BUF_INIT_SIZE;
    }
}

/* ================================================================
 * Watcher helpers
 * ================================================================ */

static void start_reading(ev_gm_t *self) {
    if (!self->reading && self->fd >= 0) {
        ev_io_start(self->loop, &self->rio);
        self->reading = 1;
    }
}

static void stop_reading(ev_gm_t *self) {
    if (self->reading) {
        ev_io_stop(self->loop, &self->rio);
        self->reading = 0;
    }
}

static void start_writing(ev_gm_t *self) {
    if (!self->writing && self->fd >= 0) {
        ev_io_start(self->loop, &self->wio);
        self->writing = 1;
    }
}

static void stop_writing(ev_gm_t *self) {
    if (self->writing) {
        ev_io_stop(self->loop, &self->wio);
        self->writing = 0;
    }
}

static int check_destroyed(ev_gm_t *self) {
    if (self->magic == GM_MAGIC_FREED && self->callback_depth == 0) {
        Safefree(self);
        return 1;
    }
    return 0;
}

/* ================================================================
 * Callback invocation helpers
 * ================================================================ */

/* Invoke Perl callback with up to two args (any may be NULL = undef).
 * Mortal SV transfer: caller passes refcnt=1 SVs, we mortalize them. */
static void invoke_cb2(pTHX_ ev_gm_t *self, SV *cb, SV *a, SV *b) {
    if (!cb) {
        if (a) SvREFCNT_dec(a);
        if (b) SvREFCNT_dec(b);
        return;
    }
    self->callback_depth++;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 2);
    if (a) mPUSHs(a); else PUSHs(&PL_sv_undef);
    if (b) mPUSHs(b); else PUSHs(&PL_sv_undef);
    PUTBACK;
    call_sv(cb, G_DISCARD | G_EVAL);
    if (SvTRUE(ERRSV)) {
        warn("EV::Gearman: callback error: %s", SvPV_nolen(ERRSV));
        sv_setsv(ERRSV, &PL_sv_undef);
    }
    FREETMPS;
    LEAVE;
    self->callback_depth--;
}

/* Invoke a handler with at most one mortal arg; eat exceptions. */
static void invoke_handler(pTHX_ ev_gm_t *self, SV *cb, SV *arg, const char *label) {
    if (!cb) { if (arg) SvREFCNT_dec(arg); return; }
    self->callback_depth++;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    if (arg) XPUSHs(sv_2mortal(arg));
    PUTBACK;
    call_sv(cb, G_DISCARD | G_EVAL);
    if (SvTRUE(ERRSV)) {
        warn("EV::Gearman: %s callback error: %s", label, SvPV_nolen(ERRSV));
        sv_setsv(ERRSV, &PL_sv_undef);
    }
    FREETMPS;
    LEAVE;
    self->callback_depth--;
}

static void emit_error(pTHX_ ev_gm_t *self, const char *msg) {
    invoke_handler(aTHX_ self, self->on_error, newSVpv(msg, 0), "on_error");
}

static void emit_connect(pTHX_ ev_gm_t *self) {
    invoke_handler(aTHX_ self, self->on_connect, NULL, "on_connect");
}

static void emit_disconnect(pTHX_ ev_gm_t *self) {
    invoke_handler(aTHX_ self, self->on_disconnect, NULL, "on_disconnect");
}

static void apply_keepalive(ev_gm_t *self) {
    if (self->keepalive <= 0 || self->path) return;
    int one = 1;
    setsockopt(self->fd, SOL_SOCKET, SO_KEEPALIVE, &one, sizeof(one));
#ifdef TCP_KEEPIDLE
    setsockopt(self->fd, IPPROTO_TCP, TCP_KEEPIDLE,
               &self->keepalive, sizeof(self->keepalive));
#endif
}

/* Set O_NONBLOCK and FD_CLOEXEC on an already-open socket fd. The
   CLOEXEC step prevents the fd leaking into child processes spawned
   via fork+exec while the connection is up. Returns 0 on success,
   -1 on failure (caller should close and error out). */
static int gm_set_socket_flags(int fd) {
    int fl = fcntl(fd, F_GETFL);
    if (fl < 0 || fcntl(fd, F_SETFL, fl | O_NONBLOCK) < 0) return -1;
#ifdef FD_CLOEXEC
    fl = fcntl(fd, F_GETFD);
    if (fl >= 0) (void)fcntl(fd, F_SETFD, fl | FD_CLOEXEC);
#endif
    return 0;
}

/* Shared get/set body for on_error / on_connect / on_disconnect. */
static SV* handler_accessor(pTHX_ SV **slot, int items, SV *new_cb) {
    if (items > 1) {
        if (*slot) { SvREFCNT_dec(*slot); *slot = NULL; }
        if (SvOK(new_cb) && SvROK(new_cb) && SvTYPE(SvRV(new_cb)) == SVt_PVCV)
            *slot = newSVsv(new_cb);
    }
    return *slot ? newSVsv(*slot) : &PL_sv_undef;
}

/* ================================================================
 * Allocators / cleaners
 * ================================================================ */

/* Allocate a request entry with kind set; if cb_sv is a valid coderef,
   bumps its refcount into r->cb. Pass NULL (or a non-coderef) for no cb. */
static ev_gm_req_t* alloc_req(int kind, SV *cb_sv) {
    ev_gm_req_t *r;
    Newxz(r, 1, ev_gm_req_t);
    r->kind = kind;
    if (cb_sv && SvOK(cb_sv) && SvROK(cb_sv))
        r->cb = newSVsv(cb_sv);
    return r;
}

static void cleanup_req(pTHX_ ev_gm_req_t *r) {
    CLEAR_HANDLER(r->cb);
    CLEAR_HANDLER(r->on_data);
    CLEAR_HANDLER(r->on_warning);
    CLEAR_HANDLER(r->on_status);
    CLEAR_HANDLER(r->on_exception);
    Safefree(r);
}

static void cleanup_wait(pTHX_ ev_gm_wait_t *w) {
    Safefree(w->packet);
    if (w->req) cleanup_req(aTHX_ w->req);
    Safefree(w);
}

static void cleanup_active(pTHX_ ev_gm_active_t *a) {
    Safefree(a->handle);
    CLEAR_HANDLER(a->on_complete);
    CLEAR_HANDLER(a->on_data);
    CLEAR_HANDLER(a->on_warning);
    CLEAR_HANDLER(a->on_status);
    CLEAR_HANDLER(a->on_exception);
    Safefree(a);
}

static void cleanup_func(pTHX_ ev_gm_func_t *f) {
    Safefree(f->name);
    CLEAR_HANDLER(f->cb);
    Safefree(f);
}

/* ================================================================
 * Cancel queues
 * ================================================================ */

/* Drain a queue, firing each entry's user callback with err_sv before
   freeing it. Bails if a callback triggers DESTROY (magic flips to
   FREED). The flag prevents reentrancy if a callback also calls
   disconnect() while we are mid-loop. */
#define CANCEL_QUEUE(qhead, type, cleanup, counter, flag, cb_expr) do { \
    if (self->flag) break;                                              \
    self->flag = 1;                                                     \
    while (!ngx_queue_empty(qhead)) {                                   \
        ngx_queue_t *_q = ngx_queue_head(qhead);                        \
        type *_e = ngx_queue_data(_q, type, queue);                     \
        ngx_queue_remove(_q);                                           \
        self->counter--;                                                \
        if (cb_expr)                                                    \
            invoke_cb2(aTHX_ self, cb_expr, NULL, newSVsv(err_sv));     \
        if (self->magic == GM_MAGIC_FREED) {                            \
            cleanup(aTHX_ _e);                                          \
            self->flag = 0;                                             \
            return;                                                     \
        }                                                               \
        cleanup(aTHX_ _e);                                              \
    }                                                                   \
    self->flag = 0;                                                     \
} while (0)

static void cancel_pending(pTHX_ ev_gm_t *self, SV *err_sv) {
    CANCEL_QUEUE(&self->cb_queue, ev_gm_req_t, cleanup_req,
                 pending_count, in_cb_cleanup, _e->cb);
    self->pending_count = 0;
}

static void cancel_waiting(pTHX_ ev_gm_t *self, SV *err_sv) {
    CANCEL_QUEUE(&self->wait_queue, ev_gm_wait_t, cleanup_wait,
                 waiting_count, in_wait_cleanup,
                 (_e->req ? _e->req->cb : NULL));
    self->waiting_count = 0;
}

static void cancel_active(pTHX_ ev_gm_t *self, SV *err_sv) {
    CANCEL_QUEUE(&self->active_jobs, ev_gm_active_t, cleanup_active,
                 active_count_cached, in_active_cleanup, _e->on_complete);
    self->active_count_cached = 0;
}

/* ================================================================
 * Connection cleanup / disconnect
 * ================================================================ */

static void cleanup_connection(pTHX_ ev_gm_t *self) {
    stop_reading(self);
    stop_writing(self);
    stop_connect_timer(self);
    disarm_cmd_timer(self);

    if (self->fd >= 0) {
        close(self->fd);
        self->fd = -1;
    }
    self->connected = 0;
    self->connecting = 0;
    self->rbuf_len = 0;
    self->wbuf_len = 0;
    self->wbuf_off = 0;

    /* Worker state resets: a reconnect must re-issue CAN_DO and re-start
       the GRAB loop from scratch. Registered functions are kept. */
    self->worker_sleeping = 0;
    self->worker_grab_inflight = 0;
}

static void handle_disconnect(pTHX_ ev_gm_t *self, const char *reason) {
    int was_connected = self->connected;
    cleanup_connection(aTHX_ self);

    cancel_pending(aTHX_ self, err_disconnected);
    if (self->magic == GM_MAGIC_FREED) return;

    cancel_active(aTHX_ self, err_disconnected);
    if (self->magic == GM_MAGIC_FREED) return;

    cancel_waiting(aTHX_ self, err_disconnected);
    if (self->magic == GM_MAGIC_FREED) return;

    if (was_connected) {
        emit_disconnect(aTHX_ self);
        if (check_destroyed(self)) return;
    }

    if (reason) {
        emit_error(aTHX_ self, reason);
        if (check_destroyed(self)) return;
    }

    if (!self->intentional_disconnect && self->reconnect)
        schedule_reconnect(aTHX_ self);
}

static void schedule_reconnect(pTHX_ ev_gm_t *self) {
    if (self->reconnect_timer_active) return;
    if (self->max_reconnect_attempts > 0 &&
        self->reconnect_attempts >= self->max_reconnect_attempts) {
        emit_error(aTHX_ self, "max reconnect attempts reached");
        return;
    }
    self->reconnect_attempts++;
    ev_tstamp delay = (ev_tstamp)self->reconnect_delay_ms / 1000.0;
    if (delay < 0) delay = 0;
    ev_timer_init(&self->reconnect_timer, reconnect_timer_cb, delay, 0.0);
    self->reconnect_timer.data = (void *)self;
    ev_timer_start(self->loop, &self->reconnect_timer);
    self->reconnect_timer_active = 1;
}

static void stop_connect_timer(ev_gm_t *self) {
    if (self->connect_timer_active) {
        ev_timer_stop(self->loop, &self->connect_timer);
        self->connect_timer_active = 0;
    }
}

static void stop_reconnect_timer(ev_gm_t *self) {
    if (self->reconnect_timer_active) {
        ev_timer_stop(self->loop, &self->reconnect_timer);
        self->reconnect_timer_active = 0;
    }
}

static void arm_cmd_timer(ev_gm_t *self) {
    if (self->command_timeout_ms <= 0) return;
    if (!self->connected) return;
    ev_tstamp timeout = (ev_tstamp)self->command_timeout_ms / 1000.0;
    if (self->cmd_timer_active) {
        self->cmd_timer.repeat = timeout;
        ev_timer_again(self->loop, &self->cmd_timer);
    } else {
        ev_timer_init(&self->cmd_timer, cmd_timeout_cb, timeout, timeout);
        self->cmd_timer.data = (void *)self;
        ev_timer_start(self->loop, &self->cmd_timer);
        self->cmd_timer_active = 1;
    }
}

static void disarm_cmd_timer(ev_gm_t *self) {
    if (self->cmd_timer_active) {
        ev_timer_stop(self->loop, &self->cmd_timer);
        self->cmd_timer_active = 0;
    }
}

static void cmd_timeout_cb(EV_P_ ev_timer *w, int revents) {
    ev_gm_t *self = (ev_gm_t *)w->data;
    (void)loop; (void)revents;
    if (self->magic != GM_MAGIC_ALIVE) return;
    if (ngx_queue_empty(&self->cb_queue)) {
        disarm_cmd_timer(self);
        return;
    }
    disarm_cmd_timer(self);
    self->callback_depth++;
    handle_disconnect(aTHX_ self, "command timeout");
    self->callback_depth--;
    check_destroyed(self);
}

static void connect_timeout_cb(EV_P_ ev_timer *w, int revents) {
    ev_gm_t *self = (ev_gm_t *)w->data;
    (void)loop; (void)revents;
    if (self->magic != GM_MAGIC_ALIVE) return;
    self->connect_timer_active = 0;
    self->callback_depth++;
    handle_disconnect(aTHX_ self, "connect timeout");
    self->callback_depth--;
    check_destroyed(self);
}

static void reconnect_timer_cb(EV_P_ ev_timer *w, int revents) {
    ev_gm_t *self = (ev_gm_t *)w->data;
    (void)loop; (void)revents;
    if (self->magic != GM_MAGIC_ALIVE) return;
    self->reconnect_timer_active = 0;
    self->callback_depth++;
    start_connect(aTHX_ self);
    self->callback_depth--;
    check_destroyed(self);
}

/* ================================================================
 * Packet build/send
 * ================================================================ */

/* Pack a binary packet into a fresh buffer. Caller frees with Safefree. */
static char* gm_pack(uint32_t cmd, const char *data, size_t data_len, size_t *out_len) {
    size_t total = GM_HEADER_SIZE + data_len;
    char *p;
    Newx(p, total, char);
    memcpy(p, GM_MAGIC_REQ, 4);
    gm_write_u32(p + 4, cmd);
    gm_write_u32(p + 8, (uint32_t)data_len);
    if (data_len > 0) memcpy(p + 12, data, data_len);
    *out_len = total;
    return p;
}

/* Hand `pkt` (heap-allocated, plen bytes) to the write path. If
 * already connected, append to the write buffer and Safefree pkt;
 * otherwise transfer ownership to a new wait entry. If req is
 * non-NULL its ownership transfers too, into cb_queue or the wait
 * entry respectively. */
static void submit_bytes(pTHX_ ev_gm_t *self,
    char *pkt, size_t plen, ev_gm_req_t *req)
{
    if (self->connected) {
        buf_append_write(self, pkt, plen);
        Safefree(pkt);
        if (req) {
            ngx_queue_insert_tail(&self->cb_queue, &req->queue);
            self->pending_count++;
            arm_cmd_timer(self);
        }
        start_writing(self);
    } else {
        ev_gm_wait_t *w;
        Newxz(w, 1, ev_gm_wait_t);
        w->packet = pkt;
        w->packet_len = plen;
        w->req = req;
        ngx_queue_insert_tail(&self->wait_queue, &w->queue);
        self->waiting_count++;
    }
}

static void enqueue_packet(pTHX_ ev_gm_t *self,
    uint32_t cmd, const char *data, size_t data_len, ev_gm_req_t *req)
{
    size_t plen;
    char *pkt = gm_pack(cmd, data, data_len, &plen);
    submit_bytes(aTHX_ self, pkt, plen, req);
}

/* The wire length field is 32-bit and the peer caps reads at
   GM_MAX_PACKET; reject anything larger before it would truncate and
   desync the protocol. Callers validate at the point of entry (before
   allocating request state) so a croak here never leaks. */
static void gm_check_size(pTHX_ size_t len) {
    if (len > GM_MAX_PACKET)
        croak("EV::Gearman: payload too large (%zu bytes, max %u)",
              len, (unsigned)GM_MAX_PACKET);
}

static void send_pending_waits(pTHX_ ev_gm_t *self) {
    while (!ngx_queue_empty(&self->wait_queue) && self->connected) {
        ngx_queue_t *q = ngx_queue_head(&self->wait_queue);
        ev_gm_wait_t *w = ngx_queue_data(q, ev_gm_wait_t, queue);
        ngx_queue_remove(q);
        self->waiting_count--;

        buf_append_write(self, w->packet, w->packet_len);

        if (w->req) {
            ngx_queue_insert_tail(&self->cb_queue, &w->req->queue);
            self->pending_count++;
            w->req = NULL;
            arm_cmd_timer(self);
        }

        Safefree(w->packet); w->packet = NULL;
        Safefree(w);

        start_writing(self);
    }
}

/* ================================================================
 * Worker helpers (state machine for GRAB / NOOP / PRE_SLEEP)
 * ================================================================ */

static ev_gm_func_t* find_function(ev_gm_t *self, const char *name, STRLEN len) {
    ngx_queue_t *q;
    for (q = ngx_queue_head(&self->functions); q != ngx_queue_sentinel(&self->functions);
         q = ngx_queue_next(q))
    {
        ev_gm_func_t *f = ngx_queue_data(q, ev_gm_func_t, queue);
        if (strlen(f->name) == len && memcmp(f->name, name, len) == 0)
            return f;
    }
    return NULL;
}

static void worker_send_grab(pTHX_ ev_gm_t *self) {
    if (!self->connected) return;
    if (self->worker_grab_inflight) return;
    if (ngx_queue_empty(&self->functions)) return;
    self->worker_grab_inflight = 1;
    ev_gm_req_t *r = alloc_req(CB_GRAB_JOB, NULL);
    enqueue_packet(aTHX_ self,
        self->worker_grab_uniq ? GM_CMD_GRAB_JOB_UNIQ : GM_CMD_GRAB_JOB,
        NULL, 0, r);
}

static void worker_send_pre_sleep(pTHX_ ev_gm_t *self) {
    if (!self->connected) return;
    if (self->worker_sleeping) return;
    self->worker_sleeping = 1;
    enqueue_packet(aTHX_ self, GM_CMD_PRE_SLEEP, NULL, 0, NULL);
}

/* Drive the worker loop forward: if active and not busy, GRAB. */
static void worker_continue(pTHX_ ev_gm_t *self) {
    if (!self->worker_active || !self->connected) return;
    if (self->worker_grab_inflight || self->worker_sleeping) return;
    if (ngx_queue_empty(&self->functions)) return;
    worker_send_grab(aTHX_ self);
}

/* ================================================================
 * Connect-success path: re-register worker functions, drain queue
 * ================================================================ */

/* Send a WORK_* packet whose body is "handle" + optional "\0data".
   For WORK_FAIL pass dp=NULL; otherwise pass payload bytes. */
static void send_work_event(pTHX_ ev_gm_t *self, uint32_t cmd,
    const char *h, STRLEN hl, const char *dp, STRLEN dl)
{
    /* No size croak here: this runs on the worker completion / event
       path (worker_dispatch_job, $job->complete), where a longjmp would
       unwind the EV loop mid-iteration. A >4 GiB result is not a real
       concern (the worker would OOM building it first). */
    size_t plen = dp ? hl + 1 + dl : hl;
    char *body;
    Newx(body, plen ? plen : 1, char);
    memcpy(body, h, hl);
    if (dp) {
        body[hl] = '\0';
        if (dl) memcpy(body + hl + 1, dp, dl);
    }
    enqueue_packet(aTHX_ self, cmd, body, plen, NULL);
    Safefree(body);
}

/* Send CAN_DO[_TIMEOUT] for one function name. Builds the
   "name\0timeout" body on the heap to avoid the 512-byte stack-buffer
   truncation that the older inline pattern was prone to. */
static void send_can_do(pTHX_ ev_gm_t *self,
                        const char *name, STRLEN nlen, int timeout)
{
    if (!self->connected) return;
    if (timeout > 0) {
        char tbuf[16];
        int tlen = snprintf(tbuf, sizeof(tbuf), "%d", timeout);
        if (tlen <= 0) return;
        size_t plen = nlen + 1 + (size_t)tlen;
        char *body;
        Newx(body, plen, char);
        memcpy(body, name, nlen);
        body[nlen] = '\0';
        memcpy(body + nlen + 1, tbuf, tlen);
        enqueue_packet(aTHX_ self, GM_CMD_CAN_DO_TIMEOUT, body, plen, NULL);
        Safefree(body);
    } else {
        enqueue_packet(aTHX_ self, GM_CMD_CAN_DO, name, nlen, NULL);
    }
}

static void register_all_functions(pTHX_ ev_gm_t *self) {
    if (!self->connected) return;
    ngx_queue_t *q;
    for (q = ngx_queue_head(&self->functions); q != ngx_queue_sentinel(&self->functions);
         q = ngx_queue_next(q))
    {
        ev_gm_func_t *f = ngx_queue_data(q, ev_gm_func_t, queue);
        send_can_do(aTHX_ self, f->name, strlen(f->name), f->timeout);
    }
}

static void send_options_and_id(pTHX_ ev_gm_t *self) {
    if (self->client_id) {
        enqueue_packet(aTHX_ self, GM_CMD_SET_CLIENT_ID,
            self->client_id, strlen(self->client_id), NULL);
    }
    if (self->opt_exceptions) {
        const char *opt = "exceptions";
        ev_gm_req_t *r = alloc_req(CB_OPTION, NULL);
        enqueue_packet(aTHX_ self, GM_CMD_OPTION_REQ, opt, strlen(opt), r);
    }
}

static void report_connect_error(pTHX_ ev_gm_t *self, const char *errbuf) {
    self->callback_depth++;
    emit_error(aTHX_ self, errbuf);
    self->callback_depth--;
    if (check_destroyed(self)) return;
    if (!self->intentional_disconnect && self->reconnect)
        schedule_reconnect(aTHX_ self);
}

static void finish_connect_success(pTHX_ ev_gm_t *self) {
    self->reconnect_attempts = 0;

    start_reading(self);
    apply_keepalive(self);

    send_options_and_id(aTHX_ self);
    register_all_functions(aTHX_ self);

    emit_connect(aTHX_ self);
    if (check_destroyed(self)) return;

    send_pending_waits(aTHX_ self);
    if (check_destroyed(self)) return;

    worker_continue(aTHX_ self);
}

/* ================================================================
 * Response routing
 * ================================================================ */

/* Return pointer to first byte of the i-th NUL-separated argument
 * (zero-indexed) and its length in *out_len. Returns NULL if not
 * present. The final argument is whatever remains after the last
 * NUL — it may itself contain NUL bytes for binary data. */
static const char* gm_arg(const char *body, size_t body_len, int idx,
                          int total, size_t *out_len)
{
    /* Walk through, splitting by NUL. The (total-1) NULs separate
       total fields; the final field has no trailing NUL. */
    const char *p = body;
    const char *end = body + body_len;
    int cur = 0;
    while (cur < idx) {
        const char *nul = memchr(p, '\0', end - p);
        if (!nul) return NULL;
        p = nul + 1;
        cur++;
    }
    /* p is start of arg `idx`; find its length */
    if (idx == total - 1) {
        /* Last arg runs to end */
        *out_len = end - p;
    } else {
        const char *nul = memchr(p, '\0', end - p);
        if (!nul) return NULL;
        *out_len = nul - p;
    }
    return p;
}

static ev_gm_active_t* find_active_by_handle(ev_gm_t *self,
                                             const char *handle, STRLEN handle_len)
{
    ngx_queue_t *q;
    for (q = ngx_queue_head(&self->active_jobs); q != ngx_queue_sentinel(&self->active_jobs);
         q = ngx_queue_next(q))
    {
        ev_gm_active_t *a = ngx_queue_data(q, ev_gm_active_t, queue);
        if (a->handle_len == handle_len &&
            memcmp(a->handle, handle, handle_len) == 0)
            return a;
    }
    return NULL;
}

/* Pop the head request entry; returns NULL if queue empty. */
static ev_gm_req_t* pop_req(ev_gm_t *self) {
    if (ngx_queue_empty(&self->cb_queue)) return NULL;
    ngx_queue_t *q = ngx_queue_head(&self->cb_queue);
    ev_gm_req_t *r = ngx_queue_data(q, ev_gm_req_t, queue);
    ngx_queue_remove(q);
    self->pending_count--;
    return r;
}

/* Forward declare so handle_response_packet can call into worker job dispatch */
static void worker_dispatch_job(pTHX_ ev_gm_t *self, ev_gm_req_t *r,
    int with_unique, const char *body, size_t body_len);

/* Validate a job hashref and return its (live) client + handle bytes.
 * Croaks with op-prefixed messages on any inconsistency. */
static ev_gm_t* job_resolve(pTHX_ SV *job_sv, const char **h, STRLEN *hl,
                            const char *op)
{
    if (!SvROK(job_sv)) croak("%s: invalid job", op);
    HV *job = (HV *)SvRV(job_sv);
    SV **ptr_sv = hv_fetchs(job, "_client_ptr", 0);
    if (!ptr_sv || !SvIOK(*ptr_sv))
        croak("%s: stale job (no client pointer)", op);
    SV **handle_sv = hv_fetchs(job, "handle", 0);
    if (!handle_sv) croak("%s: missing handle", op);
    ev_gm_t *self = INT2PTR(ev_gm_t *, SvIV(*ptr_sv));
    if (!self || self->magic != GM_MAGIC_ALIVE)
        croak("%s: client destroyed", op);
    *h = SvPV(*handle_sv, *hl);
    return self;
}

static void handle_response_packet(pTHX_ ev_gm_t *self,
    uint32_t cmd, const char *body, size_t body_len)
{
    switch (cmd) {

    case GM_CMD_ECHO_RES: {
        ev_gm_req_t *r = pop_req(self);
        if (!r) return;
        if (r->cb)
            invoke_cb2(aTHX_ self, r->cb, newSVpvn(body, body_len), NULL);
        cleanup_req(aTHX_ r);
        break;
    }

    case GM_CMD_JOB_CREATED: {
        /* Match against next request that expects JOB_CREATED */
        ev_gm_req_t *r = pop_req(self);
        if (!r) return;
        SV *handle_sv = newSVpvn(body, body_len);
        if (r->kind == CB_SUBMIT_BG) {
            if (r->cb)
                invoke_cb2(aTHX_ self, r->cb, handle_sv, NULL);
            else
                SvREFCNT_dec(handle_sv);
            cleanup_req(aTHX_ r);
        } else if (r->kind == CB_SUBMIT) {
            /* Foreground: register active job, transfer callback bundle */
            ev_gm_active_t *a;
            Newxz(a, 1, ev_gm_active_t);
            Newx(a->handle, body_len, char);
            memcpy(a->handle, body, body_len);
            a->handle_len = body_len;
            a->on_complete  = r->cb;          r->cb = NULL;
            a->on_data      = r->on_data;     r->on_data = NULL;
            a->on_warning   = r->on_warning;  r->on_warning = NULL;
            a->on_status    = r->on_status;   r->on_status = NULL;
            a->on_exception = r->on_exception;r->on_exception = NULL;
            ngx_queue_insert_tail(&self->active_jobs, &a->queue);
            self->active_count_cached++;
            cleanup_req(aTHX_ r);
            SvREFCNT_dec(handle_sv);
        } else {
            SvREFCNT_dec(handle_sv);
            cleanup_req(aTHX_ r);
        }
        break;
    }

    case GM_CMD_WORK_COMPLETE: {
        size_t hl, dl;
        const char *h = gm_arg(body, body_len, 0, 2, &hl);
        const char *d = gm_arg(body, body_len, 1, 2, &dl);
        if (!h) return;
        ev_gm_active_t *a = find_active_by_handle(self, h, hl);
        if (!a) return;
        ngx_queue_remove(&a->queue);
        self->active_count_cached--;
        if (a->on_complete)
            invoke_cb2(aTHX_ self, a->on_complete,
                       d ? newSVpvn(d, dl) : newSVpvs(""), NULL);
        cleanup_active(aTHX_ a);
        break;
    }

    case GM_CMD_WORK_FAIL: {
        ev_gm_active_t *a = find_active_by_handle(self, body, body_len);
        if (!a) return;
        ngx_queue_remove(&a->queue);
        self->active_count_cached--;
        if (a->on_complete)
            invoke_cb2(aTHX_ self, a->on_complete, NULL, newSVpvs("job failed"));
        cleanup_active(aTHX_ a);
        break;
    }

    case GM_CMD_WORK_DATA:
    case GM_CMD_WORK_WARNING: {
        size_t hl, dl;
        const char *h = gm_arg(body, body_len, 0, 2, &hl);
        const char *d = gm_arg(body, body_len, 1, 2, &dl);
        if (!h) return;
        ev_gm_active_t *a = find_active_by_handle(self, h, hl);
        if (!a) return;
        SV *cb = (cmd == GM_CMD_WORK_DATA) ? a->on_data : a->on_warning;
        if (cb) {
            SV *arg = d ? newSVpvn(d, dl) : newSVpvn("", 0);
            invoke_handler(aTHX_ self, cb, arg, "on_data/on_warning");
        }
        break;
    }

    case GM_CMD_WORK_EXCEPTION: {
        /* gearmand calls fail() on the job after forwarding the
           exception data and does NOT emit a follow-up WORK_FAIL,
           so this packet is the terminal event for the active job:
           fire on_exception (informational) then on_complete with
           an "exception" error so the caller's terminal callback
           always runs. */
        size_t hl, dl;
        const char *h = gm_arg(body, body_len, 0, 2, &hl);
        const char *d = gm_arg(body, body_len, 1, 2, &dl);
        if (!h) return;
        ev_gm_active_t *a = find_active_by_handle(self, h, hl);
        if (!a) return;
        ngx_queue_remove(&a->queue);
        self->active_count_cached--;
        if (a->on_exception) {
            SV *arg = d ? newSVpvn(d, dl) : newSVpvs("");
            invoke_handler(aTHX_ self, a->on_exception, arg, "on_exception");
        }
        if (self->magic != GM_MAGIC_FREED && a->on_complete)
            invoke_cb2(aTHX_ self, a->on_complete, NULL, newSVpvs("exception"));
        cleanup_active(aTHX_ a);
        break;
    }

    case GM_CMD_WORK_STATUS: {
        size_t hl, nl, dl;
        const char *h = gm_arg(body, body_len, 0, 3, &hl);
        const char *n = gm_arg(body, body_len, 1, 3, &nl);
        const char *d = gm_arg(body, body_len, 2, 3, &dl);
        if (!h) return;
        ev_gm_active_t *a = find_active_by_handle(self, h, hl);
        if (!a) return;
        if (a->on_status)
            invoke_cb2(aTHX_ self, a->on_status,
                n ? newSVpvn(n, nl) : newSVpvs("0"),
                d ? newSVpvn(d, dl) : newSVpvs("0"));
        break;
    }

    case GM_CMD_STATUS_RES:
    case GM_CMD_STATUS_RES_UNIQUE: {
        /* Both arms decode HANDLE-or-UNIQUE then KNOWN, RUNNING, NUM,
           DENOM, with STATUS_RES_UNIQUE adding a final CLIENT_COUNT. */
        ev_gm_req_t *r = pop_req(self);
        if (!r) return;
        if (r->cb) {
            int with_count = (cmd == GM_CMD_STATUS_RES_UNIQUE);
            int total = with_count ? 6 : 5;
            size_t l[6];
            const char *p[6];
            int i;
            for (i = 0; i < total; i++)
                p[i] = gm_arg(body, body_len, i, total, &l[i]);
            HV *hv = newHV();
            if (p[0]) {
                if (with_count) hv_stores(hv, "unique", newSVpvn(p[0], l[0]));
                else            hv_stores(hv, "handle", newSVpvn(p[0], l[0]));
            }
            if (p[1]) hv_stores(hv, "known",       newSViv(gm_atoi_n(p[1], l[1])));
            if (p[2]) hv_stores(hv, "running",     newSViv(gm_atoi_n(p[2], l[2])));
            if (p[3]) hv_stores(hv, "numerator",   newSVpvn(p[3], l[3]));
            if (p[4]) hv_stores(hv, "denominator", newSVpvn(p[4], l[4]));
            if (with_count && p[5])
                hv_stores(hv, "client_count", newSViv(gm_atoi_n(p[5], l[5])));
            invoke_cb2(aTHX_ self, r->cb, newRV_noinc((SV*)hv), NULL);
        }
        cleanup_req(aTHX_ r);
        break;
    }

    case GM_CMD_OPTION_RES: {
        ev_gm_req_t *r = pop_req(self);
        if (!r) return;
        if (r->cb)
            invoke_cb2(aTHX_ self, r->cb, newSViv(1), NULL);
        cleanup_req(aTHX_ r);
        break;
    }

    case GM_CMD_NO_JOB: {
        ev_gm_req_t *r = pop_req(self);
        if (!r) return;
        self->worker_grab_inflight = 0;
        /* grab_job's caller registered a cb; fire it with "no job" so
           it knows to back off. The high-level work() loop never sets
           r->cb for its internal grabs, so this is a no-op there. */
        if (r->cb)
            invoke_cb2(aTHX_ self, r->cb, NULL, newSVpvs("no job"));
        cleanup_req(aTHX_ r);
        if (self->worker_active) {
            worker_send_pre_sleep(aTHX_ self);
            if (self->worker_on_idle)
                invoke_handler(aTHX_ self, self->worker_on_idle, NULL, "on_idle");
        }
        break;
    }

    case GM_CMD_JOB_ASSIGN:
    case GM_CMD_JOB_ASSIGN_UNIQ: {
        ev_gm_req_t *r = pop_req(self);
        if (!r) return;
        self->worker_grab_inflight = 0;
        worker_dispatch_job(aTHX_ self, r,
            cmd == GM_CMD_JOB_ASSIGN_UNIQ ? 1 : 0, body, body_len);
        cleanup_req(aTHX_ r);
        break;
    }

    case GM_CMD_NOOP: {
        self->worker_sleeping = 0;
        worker_continue(aTHX_ self);
        break;
    }

    case GM_CMD_ERROR: {
        /* ERRCODE\0ERR_TEXT — fail head request */
        size_t cl, tl;
        const char *c = gm_arg(body, body_len, 0, 2, &cl);
        const char *t = gm_arg(body, body_len, 1, 2, &tl);
        SV *err;
        if (c && t)
            err = newSVpvf("%.*s: %.*s", (int)cl, c, (int)tl, t);
        else
            err = newSVpvn(body, body_len);
        ev_gm_req_t *r = pop_req(self);
        if (r && r->cb) {
            invoke_cb2(aTHX_ self, r->cb, NULL, err);
        } else {
            emit_error(aTHX_ self, SvPV_nolen(err));
            SvREFCNT_dec(err);
        }
        if (r) cleanup_req(aTHX_ r);
        break;
    }

    default:
        break;
    }
}

/* Dispatch a JOB_ASSIGN[_UNIQ]: invoke registered function callback,
 * deliver result back to server (for sync mode). Async mode keeps a
 * job object alive in Perl-land until user invokes complete/fail. */
static void worker_dispatch_job(pTHX_ ev_gm_t *self, ev_gm_req_t *r,
    int with_unique, const char *body, size_t body_len)
{
    int total = with_unique ? 4 : 3;
    size_t hl, fl, ul, wl;
    const char *h = gm_arg(body, body_len, 0, total, &hl);
    const char *f = gm_arg(body, body_len, 1, total, &fl);
    const char *u = with_unique ? gm_arg(body, body_len, 2, total, &ul) : NULL;
    const char *w = gm_arg(body, body_len, with_unique ? 3 : 2, total, &wl);

    if (!h || !f) return;

    /* Build a job hashref blessed into EV::Gearman::Job. */
    HV *job = newHV();
    hv_stores(job, "handle",   newSVpvn(h, hl));
    hv_stores(job, "function", newSVpvn(f, fl));
    hv_stores(job, "unique",   u ? newSVpvn(u, ul) : newSVpvn("", 0));
    hv_stores(job, "workload", w ? newSVpvn(w, wl) : newSVpvn("", 0));
    /* Raw client pointer; we deliberately do NOT bump the client's
       refcount because $g is the unique T_PTROBJ owner — creating a
       second blessed RV would let DESTROY fire twice. Job methods
       check self->magic to detect a destroyed connection. */
    hv_stores(job, "_client_ptr", newSViv(PTR2IV(self)));

    SV *jobref = sv_2mortal(newRV_noinc((SV*)job));
    sv_bless(jobref, gv_stashpv("EV::Gearman::Job", GV_ADD));

    /* grab_job mode: caller supplied an explicit cb on the request,
       deliver the job to it instead of the registered-function path. */
    if (r->cb) {
        SvREFCNT_inc(jobref);   /* invoke_cb2 mortalizes its arg */
        invoke_cb2(aTHX_ self, r->cb, jobref, NULL);
        worker_continue(aTHX_ self);
        return;
    }

    ev_gm_func_t *fn = find_function(self, f, fl);
    if (!fn) {
        send_work_event(aTHX_ self, GM_CMD_WORK_FAIL, h, hl, NULL, 0);
        worker_continue(aTHX_ self);
        return;
    }

    /* Snapshot fn->async before invoking the user callback: the
       callback is allowed to call cant_do() or reset_abilities(),
       which would free `fn`, leaving us with a stale pointer. The
       SV behind fn->cb stays alive during call_sv via Perl's own
       sub-context refcount, so reading it is safe. */
    int is_async = fn->async;

    self->callback_depth++;
    dSP;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(jobref);
    PUTBACK;
    int count = call_sv(fn->cb, is_async ? (G_DISCARD | G_EVAL) : (G_SCALAR | G_EVAL));
    SPAGAIN;

    SV *retval = NULL;
    int had_error = SvTRUE(ERRSV) ? 1 : 0;
    SV *err_sv = had_error ? newSVsv(ERRSV) : NULL;
    if (had_error)
        sv_setsv(ERRSV, &PL_sv_undef);

    if (!is_async && count > 0) {
        retval = POPs;
        SvREFCNT_inc(retval);
    }
    PUTBACK;
    FREETMPS; LEAVE;
    self->callback_depth--;

    if (self->magic == GM_MAGIC_FREED) {
        if (retval) SvREFCNT_dec(retval);
        if (err_sv) SvREFCNT_dec(err_sv);
        return;
    }

    if (!is_async) {
        if (had_error) {
            /* WORK_EXCEPTION is terminal at the server (gearmand calls
               fail() on the job after forwarding the exception data),
               so send it INSTEAD OF WORK_FAIL when the option is on —
               sending both produces a JOB_NOT_FOUND error on the
               second packet. */
            if (self->opt_exceptions && err_sv) {
                STRLEN el; const char *ep = SvPV(err_sv, el);
                send_work_event(aTHX_ self, GM_CMD_WORK_EXCEPTION, h, hl, ep, el);
            } else {
                send_work_event(aTHX_ self, GM_CMD_WORK_FAIL, h, hl, NULL, 0);
            }
        } else {
            STRLEN dl = 0;
            const char *dp = "";
            if (retval && SvOK(retval))
                dp = SvPV(retval, dl);
            send_work_event(aTHX_ self, GM_CMD_WORK_COMPLETE, h, hl, dp, dl);
        }
    } else if (had_error && err_sv) {
        /* Async: the user keeps the job around and calls complete/fail
           later. We immediately grab the next job so async workers can
           process multiple jobs concurrently — bounded only by what the
           server has queued. Users who want a concurrency cap call
           work_stop in their callback (and work() again from
           complete()/fail() to resume). */
        warn("EV::Gearman: async worker callback raised: %s",
            SvPV_nolen(err_sv));
    }
    if (retval) SvREFCNT_dec(retval);
    if (err_sv) SvREFCNT_dec(err_sv);

    if (self->worker_one_shot) {
        self->worker_active = 0;
        self->worker_one_shot = 0;
    } else {
        worker_continue(aTHX_ self);
    }
}

/* ================================================================
 * Read path: parse binary or text-protocol responses
 *
 * The server may emit two stream styles:
 *   - Binary packets with magic "\0RES" (response to binary requests)
 *   - Text lines (response to admin commands like "status\n")
 *
 * We choose dispatch based on the head request kind: if head is
 * CB_ADMIN, we expect text; otherwise binary. If both styles are
 * intermixed we parse whichever the head expects.
 *
 * Admin replies: single-line commands ("version\n") return one
 * line; multi-line ("status\n", "workers\n") terminate with ".\n".
 * ================================================================ */

/* Returns 1 if a complete admin reply was parsed and consumed,
 * 0 if more bytes are needed, -1 on protocol error (head request
 * is not CB_ADMIN — caller should disconnect). */
static int parse_admin_response(pTHX_ ev_gm_t *self) {
    if (ngx_queue_empty(&self->cb_queue)) return -1;
    ngx_queue_t *q = ngx_queue_head(&self->cb_queue);
    ev_gm_req_t *r = ngx_queue_data(q, ev_gm_req_t, queue);
    if (r->kind != CB_ADMIN) return -1;

    size_t consumed = 0;
    size_t result_len = 0;
    if (r->admin_terminator) {
        /* Find ".\n" at start of a line. */
        const char *start = self->rbuf;
        const char *end = self->rbuf + self->rbuf_len;
        const char *p = start;
        const char *terminator = NULL;
        while (p < end) {
            if (p == start || *(p - 1) == '\n') {
                if (p[0] == '.' && (p + 1 < end) && p[1] == '\n') {
                    terminator = p;
                    break;
                }
            }
            p++;
        }
        if (!terminator) return 0;
        consumed = (terminator - start) + 2; /* include ".\n" */
        result_len = terminator - start;
    } else {
        const char *nl = memchr(self->rbuf, '\n', self->rbuf_len);
        if (!nl) return 0;
        consumed = (nl - self->rbuf) + 1;
        result_len = nl - self->rbuf;
    }

    ngx_queue_remove(&r->queue);
    self->pending_count--;
    /* invoke_cb2 dec's the SV when r->cb is NULL, so build it
       unconditionally and let the helper handle the no-cb case. */
    invoke_cb2(aTHX_ self, r->cb, newSVpvn(self->rbuf, result_len), NULL);
    cleanup_req(aTHX_ r);

    if (self->magic == GM_MAGIC_FREED) return 1;
    /* The callback may have called disconnect(), which zeroes rbuf_len
       via cleanup_connection. Bail before the bookkeeping below would
       underflow it (mirrors the binary path in process_responses). */
    if (!self->connected) return 1;

    self->rbuf_len -= consumed;
    if (self->rbuf_len > 0)
        memmove(self->rbuf, self->rbuf + consumed, self->rbuf_len);
    return 1;
}

static void process_responses(pTHX_ ev_gm_t *self) {
    int processed = 0;
    while (self->rbuf_len > 0) {
        /* Binary response packets start with "\0RES"; the text/admin
           protocol never emits a leading NUL, so the first byte is
           enough to pick a parser. */
        int is_admin = (self->rbuf[0] != '\0');

        if (is_admin) {
            int rv = parse_admin_response(aTHX_ self);
            if (rv == 0) break;                 /* need more bytes */
            if (rv < 0) {                       /* protocol error */
                handle_disconnect(aTHX_ self,
                    "unexpected admin response (queue head is not admin)");
                return;
            }
            if (self->magic == GM_MAGIC_FREED) return;
            if (!self->connected) return;
            processed++;
            continue;
        }

        if (self->rbuf_len < GM_HEADER_SIZE) break;
        if (memcmp(self->rbuf, GM_MAGIC_RES, 4) != 0) {
            handle_disconnect(aTHX_ self, "invalid response magic");
            return;
        }
        uint32_t cmd = gm_read_u32(self->rbuf + 4);
        uint32_t body_len = gm_read_u32(self->rbuf + 8);
        if (body_len > GM_MAX_PACKET) {
            handle_disconnect(aTHX_ self, "response packet too large");
            return;
        }
        size_t total = (size_t)GM_HEADER_SIZE + body_len;
        if (self->rbuf_len < total) break;

        /* rbuf is input-only — dispatch may grow wbuf but never rbuf,
           so the body pointer stays valid until the memmove below. */
        const char *body = self->rbuf + GM_HEADER_SIZE;
        handle_response_packet(aTHX_ self, cmd, body, body_len);
        if (self->magic == GM_MAGIC_FREED) return;
        if (!self->connected) return;

        self->rbuf_len -= total;
        if (self->rbuf_len > 0)
            memmove(self->rbuf, self->rbuf + total, self->rbuf_len);
        processed++;
    }

    if (processed > 0 && self->cmd_timer_active) {
        if (ngx_queue_empty(&self->cb_queue))
            disarm_cmd_timer(self);
        else
            arm_cmd_timer(self);
    }

    /* Fully consumed: release an oversized read buffer (e.g. after a
       single large packet) instead of pinning it for the connection's
       lifetime. */
    if (self->rbuf_len == 0)
        buf_maybe_shrink(&self->rbuf, &self->rbuf_cap);
}

/* ================================================================
 * Read/write IO
 * ================================================================ */

static void on_readable(pTHX_ ev_gm_t *self) {
    buf_ensure_read(self, 4096);
    ssize_t n = read(self->fd, self->rbuf + self->rbuf_len,
                     self->rbuf_cap - self->rbuf_len);
    if (n > 0) {
        self->rbuf_len += n;
        process_responses(aTHX_ self);
    } else if (n == 0) {
        handle_disconnect(aTHX_ self, "connection closed by server");
    } else {
        if (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR)
            return;
        char errbuf[128];
        snprintf(errbuf, sizeof(errbuf), "read error: %s", strerror(errno));
        handle_disconnect(aTHX_ self, errbuf);
    }
}

static int try_write(ev_gm_t *self) {
    while (self->wbuf_off < self->wbuf_len) {
        ssize_t n = write(self->fd, self->wbuf + self->wbuf_off,
                          self->wbuf_len - self->wbuf_off);
        if (n > 0) self->wbuf_off += n;
        else if (n < 0) {
            if (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR)
                return 0;
            return -1;
        }
    }
    self->wbuf_len = 0;
    self->wbuf_off = 0;
    buf_maybe_shrink(&self->wbuf, &self->wbuf_cap);
    stop_writing(self);
    return 1;
}

static void on_connect_complete(pTHX_ ev_gm_t *self) {
    int err = 0;
    socklen_t len = sizeof(err);
    if (getsockopt(self->fd, SOL_SOCKET, SO_ERROR, &err, &len) < 0 || err != 0) {
        char errbuf[128];
        snprintf(errbuf, sizeof(errbuf), "connect failed: %s",
                 strerror(err ? err : errno));
        close(self->fd);
        self->fd = -1;
        self->connecting = 0;
        stop_writing(self);
        stop_connect_timer(self);
        report_connect_error(aTHX_ self, errbuf);
        return;
    }
    self->connecting = 0;
    self->connected = 1;
    stop_writing(self);
    stop_connect_timer(self);
    finish_connect_success(aTHX_ self);
}

static void io_cb(EV_P_ ev_io *w, int revents) {
    ev_gm_t *self = (ev_gm_t *)w->data;
    (void)loop;
    if (self->magic != GM_MAGIC_ALIVE) return;
    self->callback_depth++;

    if (self->connecting) {
        if (revents & EV_WRITE) {
            on_connect_complete(aTHX_ self);
        }
        self->callback_depth--;
        check_destroyed(self);
        return;
    }

    if (revents & EV_READ) {
        on_readable(aTHX_ self);
        if (self->magic != GM_MAGIC_ALIVE) {
            self->callback_depth--;
            check_destroyed(self);
            return;
        }
    }
    if (revents & EV_WRITE) {
        int rv = try_write(self);
        if (rv < 0) {
            char errbuf[128];
            snprintf(errbuf, sizeof(errbuf), "write error: %s", strerror(errno));
            handle_disconnect(aTHX_ self, errbuf);
        }
    }
    self->callback_depth--;
    check_destroyed(self);
}

/* ================================================================
 * start_connect
 * ================================================================ */

static void start_connect(pTHX_ ev_gm_t *self) {
    int fd, ret;

    if (self->path) {
        struct sockaddr_un addr;
        memset(&addr, 0, sizeof(addr));
        addr.sun_family = AF_UNIX;
        if (strlen(self->path) >= sizeof(addr.sun_path)) {
            emit_error(aTHX_ self, "unix socket path too long");
            return;
        }
        strncpy(addr.sun_path, self->path, sizeof(addr.sun_path) - 1);

#ifdef SOCK_CLOEXEC
        fd = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
        if (fd < 0 && errno == EINVAL)  /* old kernels: fall back */
            fd = socket(AF_UNIX, SOCK_STREAM, 0);
#else
        fd = socket(AF_UNIX, SOCK_STREAM, 0);
#endif
        if (fd < 0) {
            char errbuf[128];
            snprintf(errbuf, sizeof(errbuf), "socket: %s", strerror(errno));
            emit_error(aTHX_ self, errbuf);
            return;
        }
        if (gm_set_socket_flags(fd) < 0) {
            close(fd);
            emit_error(aTHX_ self, "fcntl set socket flags failed");
            return;
        }
        self->fd = fd;
        ret = connect(fd, (struct sockaddr *)&addr, sizeof(addr));
    } else {
        struct addrinfo hints, *res = NULL;
        char port_str[16];
        snprintf(port_str, sizeof(port_str), "%d", self->port);
        memset(&hints, 0, sizeof(hints));
        hints.ai_family = AF_UNSPEC;
        hints.ai_socktype = SOCK_STREAM;

        ret = getaddrinfo(self->host, port_str, &hints, &res);
        if (ret != 0) {
            char errbuf[256];
            snprintf(errbuf, sizeof(errbuf), "getaddrinfo: %s", gai_strerror(ret));
            report_connect_error(aTHX_ self, errbuf);
            return;
        }
#ifdef SOCK_CLOEXEC
        fd = socket(res->ai_family, res->ai_socktype | SOCK_CLOEXEC, res->ai_protocol);
        if (fd < 0 && errno == EINVAL)
            fd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
#else
        fd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
#endif
        if (fd < 0) {
            freeaddrinfo(res);
            char errbuf[128];
            snprintf(errbuf, sizeof(errbuf), "socket: %s", strerror(errno));
            report_connect_error(aTHX_ self, errbuf);
            return;
        }
        if (gm_set_socket_flags(fd) < 0) {
            freeaddrinfo(res);
            close(fd);
            emit_error(aTHX_ self, "fcntl set socket flags failed");
            return;
        }
        int one = 1;
        setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &one, sizeof(one));
        self->fd = fd;
        ret = connect(fd, res->ai_addr, res->ai_addrlen);
        freeaddrinfo(res);
    }

    /* Watcher init is the same for the immediate-success and
       EINPROGRESS branches; only ev_io_start (via start_*) differs.
       Init'd-but-not-started watchers are inert, so it is safe to
       run this even in the failure branch which closes the fd. */
    ev_io_init(&self->rio, io_cb, self->fd, EV_READ);
    self->rio.data = (void *)self;
    ev_io_init(&self->wio, io_cb, self->fd, EV_WRITE);
    self->wio.data = (void *)self;
    ev_set_priority(&self->rio, self->priority);
    ev_set_priority(&self->wio, self->priority);

    if (ret == 0) {
        self->connected = 1;
        finish_connect_success(aTHX_ self);
        return;
    }
    if (errno != EINPROGRESS) {
        char errbuf[128];
        snprintf(errbuf, sizeof(errbuf), "connect: %s", strerror(errno));
        close(self->fd);
        self->fd = -1;
        report_connect_error(aTHX_ self, errbuf);
        return;
    }
    self->connecting = 1;
    start_writing(self);

    if (self->connect_timeout_ms > 0) {
        ev_tstamp delay = (ev_tstamp)self->connect_timeout_ms / 1000.0;
        ev_timer_init(&self->connect_timer, connect_timeout_cb, delay, 0.0);
        self->connect_timer.data = (void *)self;
        ev_timer_start(self->loop, &self->connect_timer);
        self->connect_timer_active = 1;
    }
}

/* ================================================================
 * Helper to encode a multi-arg body: NUL-separated.
 * ================================================================ */

/* Concatenate args with NUL separators into out (caller frees).
 * args: array of {ptr, len} pairs; n_args entries.
 * Returns total length in *out_len. NULL ptr is treated as empty. */
static char* gm_encode_args(int n_args, const char **ptrs, const STRLEN *lens, size_t *out_len) {
    size_t total = 0;
    int i;
    for (i = 0; i < n_args; i++) total += (ptrs[i] ? lens[i] : 0);
    if (n_args > 1) total += (n_args - 1);
    char *out;
    Newx(out, total ? total : 1, char);
    char *p = out;
    for (i = 0; i < n_args; i++) {
        if (i > 0) { *p++ = '\0'; }
        if (ptrs[i] && lens[i] > 0) {
            memcpy(p, ptrs[i], lens[i]);
            p += lens[i];
        }
    }
    *out_len = total;
    return out;
}

/* ================================================================
 * XS interface
 * ================================================================ */

MODULE = EV::Gearman  PACKAGE = EV::Gearman

BOOT:
{
    I_EV_API("EV::Gearman");
    err_disconnected = newSVpvs("disconnected");
    SvREADONLY_on(err_disconnected);
}

EV::Gearman
new(char *class, ...)
CODE:
{
    PERL_UNUSED_VAR(class);
    if ((items - 1) % 2 != 0) croak("odd number of arguments");

    Newxz(RETVAL, 1, ev_gm_t);
    RETVAL->magic = GM_MAGIC_ALIVE;
    RETVAL->fd = -1;
    RETVAL->port = 4730;
    ngx_queue_init(&RETVAL->cb_queue);
    ngx_queue_init(&RETVAL->wait_queue);
    ngx_queue_init(&RETVAL->active_jobs);
    ngx_queue_init(&RETVAL->functions);
    Newx(RETVAL->rbuf, BUF_INIT_SIZE, char);
    RETVAL->rbuf_cap = BUF_INIT_SIZE;
    Newx(RETVAL->wbuf, BUF_INIT_SIZE, char);
    RETVAL->wbuf_cap = BUF_INIT_SIZE;

    /* Default error handler. eval_pv hands back the result without
       transferring a reference we own (it stays mortal), so take one
       to keep the sub alive past the current statement. */
    RETVAL->on_error = eval_pv("sub { warn \"EV::Gearman error: @_\\n\" }", TRUE);
    SvREFCNT_inc_simple_void_NN(RETVAL->on_error);

    SV *host_sv = NULL, *path_sv = NULL;
    int port = 4730;
    int do_reconnect = 0, reconnect_delay = 1000, max_reconnect_attempts = 0;
    RETVAL->loop = EV_DEFAULT;

    int i;
    for (i = 1; i < items; i += 2) {
        const char *k = SvPV_nolen(ST(i));
        SV *v = ST(i + 1);

        if (strEQ(k, "host"))                           host_sv = v;
        else if (strEQ(k, "port"))                      port = SvIV(v);
        else if (strEQ(k, "path"))                      path_sv = v;
        else if (strEQ(k, "on_error")) {
            CLEAR_HANDLER(RETVAL->on_error);
            if (SvOK(v) && SvROK(v)) RETVAL->on_error = newSVsv(v);
        }
        else if (strEQ(k, "on_connect")) {
            if (SvOK(v) && SvROK(v)) RETVAL->on_connect = newSVsv(v);
        }
        else if (strEQ(k, "on_disconnect")) {
            if (SvOK(v) && SvROK(v)) RETVAL->on_disconnect = newSVsv(v);
        }
        else if (strEQ(k, "connect_timeout"))           RETVAL->connect_timeout_ms = SvIV(v);
        else if (strEQ(k, "command_timeout"))           RETVAL->command_timeout_ms = SvIV(v);
        else if (strEQ(k, "priority"))                  RETVAL->priority = SvIV(v);
        else if (strEQ(k, "keepalive"))                 RETVAL->keepalive = SvIV(v);
        else if (strEQ(k, "reconnect"))                 do_reconnect = SvTRUE(v) ? 1 : 0;
        else if (strEQ(k, "reconnect_delay"))           reconnect_delay = SvIV(v);
        else if (strEQ(k, "max_reconnect_attempts"))    max_reconnect_attempts = SvIV(v);
        else if (strEQ(k, "exceptions"))                RETVAL->opt_exceptions = SvTRUE(v) ? 1 : 0;
        else if (strEQ(k, "client_id")) {
            if (SvOK(v)) RETVAL->client_id = savepv(SvPV_nolen(v));
        }
        else if (strEQ(k, "grab_unique"))               RETVAL->worker_grab_uniq = SvTRUE(v) ? 1 : 0;
        else if (strEQ(k, "loop")) {
            RETVAL->loop = (struct ev_loop *)SvPVX(SvRV(v));
        }
    }

    if (host_sv && path_sv) {
        Safefree(RETVAL->rbuf);
        Safefree(RETVAL->wbuf);
        CLEAR_HANDLER(RETVAL->on_error);
        CLEAR_HANDLER(RETVAL->on_connect);
        CLEAR_HANDLER(RETVAL->on_disconnect);
        if (RETVAL->client_id) Safefree(RETVAL->client_id);
        Safefree(RETVAL);
        croak("cannot specify both 'host' and 'path'");
    }

    RETVAL->port = port;
    if (do_reconnect) {
        RETVAL->reconnect = 1;
        RETVAL->reconnect_delay_ms = reconnect_delay >= 0 ? reconnect_delay : 0;
        RETVAL->max_reconnect_attempts = max_reconnect_attempts >= 0 ? max_reconnect_attempts : 0;
    }

    if (host_sv && SvOK(host_sv)) {
        RETVAL->host = savepv(SvPV_nolen(host_sv));
        start_connect(aTHX_ RETVAL);
    } else if (path_sv && SvOK(path_sv)) {
        RETVAL->path = savepv(SvPV_nolen(path_sv));
        start_connect(aTHX_ RETVAL);
    }
}
OUTPUT:
    RETVAL

void
DESTROY(EV::Gearman self)
CODE:
{
    if (self->magic == GM_MAGIC_FREED) return;

    if (self->callback_depth > 0) {
        self->magic = GM_MAGIC_FREED;
        self->connected = 0;
        self->connecting = 0;
        stop_reading(self);
        stop_writing(self);
        stop_connect_timer(self);
        disarm_cmd_timer(self);
        stop_reconnect_timer(self);
        if (self->fd >= 0) { close(self->fd); self->fd = -1; }

        /* Drain queues firing user callbacks with the disconnect error.
           connected is cleared (so GM_CROAK_UNLESS_ALIVE makes any
           method called from a callback croak) and magic == FREED (so a
           nested DESTROY no-ops at the top of this function). cancel_*
           would bail on FREED, so drain inline. */
        while (!ngx_queue_empty(&self->cb_queue)) {
            ngx_queue_t *q = ngx_queue_head(&self->cb_queue);
            ev_gm_req_t *r = ngx_queue_data(q, ev_gm_req_t, queue);
            ngx_queue_remove(q);
            if (r->cb)
                invoke_cb2(aTHX_ self, r->cb, NULL, newSVsv(err_disconnected));
            cleanup_req(aTHX_ r);
        }
        while (!ngx_queue_empty(&self->active_jobs)) {
            ngx_queue_t *q = ngx_queue_head(&self->active_jobs);
            ev_gm_active_t *a = ngx_queue_data(q, ev_gm_active_t, queue);
            ngx_queue_remove(q);
            self->active_count_cached--;
            if (a->on_complete)
                invoke_cb2(aTHX_ self, a->on_complete, NULL, newSVsv(err_disconnected));
            cleanup_active(aTHX_ a);
        }
        while (!ngx_queue_empty(&self->wait_queue)) {
            ngx_queue_t *q = ngx_queue_head(&self->wait_queue);
            ev_gm_wait_t *w = ngx_queue_data(q, ev_gm_wait_t, queue);
            ngx_queue_remove(q);
            if (w->req && w->req->cb)
                invoke_cb2(aTHX_ self, w->req->cb, NULL, newSVsv(err_disconnected));
            cleanup_wait(aTHX_ w);
        }
        DRAIN_QUEUE_SILENT(&self->functions, ev_gm_func_t, cleanup_func);
        self->pending_count = 0;
        self->waiting_count = 0;
        self->active_count_cached = 0;
        CLEAR_HANDLER(self->on_error);
        CLEAR_HANDLER(self->on_connect);
        CLEAR_HANDLER(self->on_disconnect);
        CLEAR_HANDLER(self->worker_on_idle);
        Safefree(self->host);     self->host = NULL;
        Safefree(self->path);     self->path = NULL;
        Safefree(self->client_id);self->client_id = NULL;
        Safefree(self->rbuf);     self->rbuf = NULL;
        Safefree(self->wbuf);     self->wbuf = NULL;
        return;
    }

    stop_connect_timer(self);
    disarm_cmd_timer(self);
    stop_reconnect_timer(self);
    cleanup_connection(aTHX_ self);

    if (!PL_dirty) {
        self->callback_depth++;
        cancel_pending(aTHX_ self, err_disconnected);
        cancel_active(aTHX_ self, err_disconnected);
        cancel_waiting(aTHX_ self, err_disconnected);
        self->callback_depth--;
    } else {
        DRAIN_QUEUE_SILENT(&self->cb_queue,    ev_gm_req_t,    cleanup_req);
        DRAIN_QUEUE_SILENT(&self->wait_queue,  ev_gm_wait_t,   cleanup_wait);
        DRAIN_QUEUE_SILENT(&self->active_jobs, ev_gm_active_t, cleanup_active);
    }

    DRAIN_QUEUE_SILENT(&self->functions, ev_gm_func_t, cleanup_func);

    self->magic = GM_MAGIC_FREED;
    CLEAR_HANDLER(self->on_error);
    CLEAR_HANDLER(self->on_connect);
    CLEAR_HANDLER(self->on_disconnect);
    CLEAR_HANDLER(self->worker_on_idle);
    Safefree(self->host);
    Safefree(self->path);
    Safefree(self->client_id);
    Safefree(self->rbuf);
    Safefree(self->wbuf);
    Safefree(self);
}

void
connect(EV::Gearman self, const char *host, int port = 4730)
CODE:
{
    if (self->connected || self->connecting) croak("already connected");
    stop_reconnect_timer(self);
    Safefree(self->host); self->host = savepv(host);
    self->port = port;
    Safefree(self->path); self->path = NULL;
    self->intentional_disconnect = 0;
    start_connect(aTHX_ self);
}

void
connect_unix(EV::Gearman self, const char *path)
CODE:
{
    if (self->connected || self->connecting) croak("already connected");
    stop_reconnect_timer(self);
    Safefree(self->path); self->path = savepv(path);
    Safefree(self->host); self->host = NULL;
    self->intentional_disconnect = 0;
    start_connect(aTHX_ self);
}

void
disconnect(EV::Gearman self)
CODE:
{
    self->intentional_disconnect = 1;
    self->worker_active = 0;
    stop_reconnect_timer(self);
    self->callback_depth++;
    if (self->connected || self->connecting) {
        handle_disconnect(aTHX_ self, NULL);
    } else {
        cancel_waiting(aTHX_ self, err_disconnected);
    }
    self->callback_depth--;
    check_destroyed(self);
}

int
is_connected(EV::Gearman self)
CODE:
    RETVAL = self->connected || self->connecting;
OUTPUT:
    RETVAL

int
pending_count(EV::Gearman self)
CODE:
    RETVAL = self->pending_count;
OUTPUT:
    RETVAL

int
waiting_count(EV::Gearman self)
CODE:
    RETVAL = self->waiting_count;
OUTPUT:
    RETVAL

int
active_count(EV::Gearman self)
CODE:
    RETVAL = self->active_count_cached;
OUTPUT:
    RETVAL

# Internal: current (read, write) buffer capacities in bytes. Used by
# the test suite to assert that oversized buffers are released after a
# large packet drains. Not part of the public API.
void
_buf_caps(EV::Gearman self)
PPCODE:
{
    EXTEND(SP, 2);
    mPUSHu(self->rbuf_cap);
    mPUSHu(self->wbuf_cap);
}

SV *
on_error(EV::Gearman self, ...)
CODE:
    RETVAL = handler_accessor(aTHX_ &self->on_error, items,
                              items > 1 ? ST(1) : &PL_sv_undef);
OUTPUT:
    RETVAL

SV *
on_connect(EV::Gearman self, ...)
CODE:
    RETVAL = handler_accessor(aTHX_ &self->on_connect, items,
                              items > 1 ? ST(1) : &PL_sv_undef);
OUTPUT:
    RETVAL

SV *
on_disconnect(EV::Gearman self, ...)
CODE:
    RETVAL = handler_accessor(aTHX_ &self->on_disconnect, items,
                              items > 1 ? ST(1) : &PL_sv_undef);
OUTPUT:
    RETVAL

void
echo(EV::Gearman self, SV *data_sv, SV *cb_sv = &PL_sv_undef)
CODE:
{
    GM_CROAK_UNLESS_ALIVE(self);
    STRLEN dlen;
    const char *data = SvPV(data_sv, dlen);
    ev_gm_req_t *r = alloc_req(CB_ECHO, cb_sv);
    enqueue_packet(aTHX_ self, GM_CMD_ECHO_REQ, data, dlen, r);
}

void
_submit_internal(EV::Gearman self, int cmd_idx, SV *func_sv, SV *workload_sv, SV *unique_sv, SV *opts_sv, SV *cb_sv)
CODE:
{
    /* cmd_idx mapping: 0=submit_job, 1=high, 2=low,
                        3=submit_job_bg, 4=high_bg, 5=low_bg */
    static const uint32_t cmd_map[] = {
        GM_CMD_SUBMIT_JOB, GM_CMD_SUBMIT_JOB_HIGH, GM_CMD_SUBMIT_JOB_LOW,
        GM_CMD_SUBMIT_JOB_BG, GM_CMD_SUBMIT_JOB_HIGH_BG, GM_CMD_SUBMIT_JOB_LOW_BG
    };
    if (cmd_idx < 0 || cmd_idx > 5) croak("invalid submit cmd index");
    GM_CROAK_UNLESS_ALIVE(self);
    int is_bg = (cmd_idx >= 3);

    STRLEN flen, wlen, ulen = 0;
    const char *fname = SvPV(func_sv, flen);
    const char *wload = SvPV(workload_sv, wlen);
    const char *uniq = "";
    if (SvOK(unique_sv)) uniq = SvPV(unique_sv, ulen);

    /* Validate the eventual body size (3 args + 2 NUL separators)
       before allocating anything, so the croak can't leak r/body. */
    gm_check_size(aTHX_ flen + ulen + wlen + 2);

    ev_gm_req_t *r = alloc_req(is_bg ? CB_SUBMIT_BG : CB_SUBMIT, cb_sv);

    /* Optional callback bundle for foreground (opts_sv may be hashref) */
    if (!is_bg && SvROK(opts_sv) && SvTYPE(SvRV(opts_sv)) == SVt_PVHV) {
        HV *opts = (HV *)SvRV(opts_sv);
        SV **v;
        if ((v = hv_fetchs(opts, "on_data", 0))      && SvROK(*v)) r->on_data      = newSVsv(*v);
        if ((v = hv_fetchs(opts, "on_warning", 0))   && SvROK(*v)) r->on_warning   = newSVsv(*v);
        if ((v = hv_fetchs(opts, "on_status", 0))    && SvROK(*v)) r->on_status    = newSVsv(*v);
        if ((v = hv_fetchs(opts, "on_exception", 0)) && SvROK(*v)) r->on_exception = newSVsv(*v);
    }

    const char *ptrs[3] = { fname, uniq, wload };
    STRLEN lens[3] = { flen, ulen, wlen };
    size_t blen;
    char *body = gm_encode_args(3, ptrs, lens, &blen);
    enqueue_packet(aTHX_ self, cmd_map[cmd_idx], body, blen, r);
    Safefree(body);
}

void
_submit_epoch(EV::Gearman self, SV *func_sv, SV *workload_sv, SV *unique_sv, UV epoch, SV *cb_sv)
CODE:
{
    GM_CROAK_UNLESS_ALIVE(self);
    STRLEN flen, wlen, ulen = 0;
    const char *fname = SvPV(func_sv, flen);
    const char *wload = SvPV(workload_sv, wlen);
    const char *uniq = "";
    if (SvOK(unique_sv)) uniq = SvPV(unique_sv, ulen);

    char epoch_buf[32];
    int epoch_len = snprintf(epoch_buf, sizeof(epoch_buf), "%lu", (unsigned long)epoch);

    /* Validate body size (4 args + 3 NUL separators) before allocating. */
    gm_check_size(aTHX_ flen + ulen + (STRLEN)epoch_len + wlen + 3);

    ev_gm_req_t *r = alloc_req(CB_SUBMIT_BG, cb_sv);

    /* SUBMIT_JOB_EPOCH: FUNC\0UNIQ\0EPOCH\0DATA */
    const char *ptrs[4] = { fname, uniq, epoch_buf, wload };
    STRLEN lens[4] = { flen, ulen, (STRLEN)epoch_len, wlen };
    size_t blen;
    char *body = gm_encode_args(4, ptrs, lens, &blen);
    enqueue_packet(aTHX_ self, GM_CMD_SUBMIT_JOB_EPOCH, body, blen, r);
    Safefree(body);
}

void
get_status(EV::Gearman self, SV *handle_sv, SV *cb_sv = &PL_sv_undef)
CODE:
{
    GM_CROAK_UNLESS_ALIVE(self);
    STRLEN hlen;
    const char *h = SvPV(handle_sv, hlen);
    ev_gm_req_t *r = alloc_req(CB_GET_STATUS, cb_sv);
    enqueue_packet(aTHX_ self, GM_CMD_GET_STATUS, h, hlen, r);
}

void
get_status_unique(EV::Gearman self, SV *unique_sv, SV *cb_sv = &PL_sv_undef)
CODE:
{
    GM_CROAK_UNLESS_ALIVE(self);
    STRLEN ulen;
    const char *u = SvPV(unique_sv, ulen);
    ev_gm_req_t *r = alloc_req(CB_GET_STATUS_UNIQ, cb_sv);
    enqueue_packet(aTHX_ self, GM_CMD_GET_STATUS_UNIQUE, u, ulen, r);
}

void
option(EV::Gearman self, SV *name_sv, SV *cb_sv = &PL_sv_undef)
CODE:
{
    GM_CROAK_UNLESS_ALIVE(self);
    STRLEN nlen;
    const char *n = SvPV(name_sv, nlen);
    /* Track common options client-side */
    if (nlen == 10 && memcmp(n, "exceptions", 10) == 0)
        self->opt_exceptions = 1;
    ev_gm_req_t *r = alloc_req(CB_OPTION, cb_sv);
    enqueue_packet(aTHX_ self, GM_CMD_OPTION_REQ, n, nlen, r);
}

void
set_client_id(EV::Gearman self, SV *id_sv)
CODE:
{
    STRLEN ilen;
    const char *id = SvPV(id_sv, ilen);
    Safefree(self->client_id);
    self->client_id = savepv(id);
    if (self->connected)
        enqueue_packet(aTHX_ self, GM_CMD_SET_CLIENT_ID, id, ilen, NULL);
}

void
can_do(EV::Gearman self, SV *func_sv, ...)
CODE:
{
    STRLEN flen;
    const char *fname = SvPV(func_sv, flen);
    int timeout = 0;
    if (items > 2 && SvOK(ST(2))) timeout = SvIV(ST(2));

    /* Without a Perl handler the caller must use grab_job to receive
       jobs; the entry just records the ability so reconnect re-sends
       the CAN_DO. */
    ev_gm_func_t *existing = find_function(self, fname, flen);
    if (!existing) {
        ev_gm_func_t *f;
        Newxz(f, 1, ev_gm_func_t);
        f->name = savepv(fname);
        f->timeout = timeout;
        ngx_queue_insert_tail(&self->functions, &f->queue);
    } else {
        existing->timeout = timeout;
    }
    send_can_do(aTHX_ self, fname, flen, timeout);
}

void
cant_do(EV::Gearman self, SV *func_sv)
CODE:
{
    STRLEN flen;
    const char *fname = SvPV(func_sv, flen);
    /* Remove from registered functions */
    ngx_queue_t *q;
    for (q = ngx_queue_head(&self->functions); q != ngx_queue_sentinel(&self->functions); ) {
        ev_gm_func_t *f = ngx_queue_data(q, ev_gm_func_t, queue);
        ngx_queue_t *nx = ngx_queue_next(q);
        if (strlen(f->name) == flen && memcmp(f->name, fname, flen) == 0) {
            ngx_queue_remove(q);
            cleanup_func(aTHX_ f);
        }
        q = nx;
    }
    if (self->connected)
        enqueue_packet(aTHX_ self, GM_CMD_CANT_DO, fname, flen, NULL);
}

void
reset_abilities(EV::Gearman self)
CODE:
{
    DRAIN_QUEUE_SILENT(&self->functions, ev_gm_func_t, cleanup_func);
    if (self->connected)
        enqueue_packet(aTHX_ self, GM_CMD_RESET_ABILITIES, NULL, 0, NULL);
}

void
_register_function(EV::Gearman self, SV *name_sv, SV *cb_sv, int timeout, int async)
CODE:
{
    STRLEN nlen;
    const char *name = SvPV(name_sv, nlen);
    if (!SvROK(cb_sv) || SvTYPE(SvRV(cb_sv)) != SVt_PVCV)
        croak("register_function: callback must be a coderef");

    ev_gm_func_t *existing = find_function(self, name, nlen);
    if (existing) {
        CLEAR_HANDLER(existing->cb);
        existing->cb = newSVsv(cb_sv);
        existing->async = async ? 1 : 0;
        existing->timeout = timeout;
    } else {
        ev_gm_func_t *f;
        Newxz(f, 1, ev_gm_func_t);
        f->name = savepv(name);
        f->cb = newSVsv(cb_sv);
        f->async = async ? 1 : 0;
        f->timeout = timeout;
        ngx_queue_insert_tail(&self->functions, &f->queue);
    }

    send_can_do(aTHX_ self, name, nlen, timeout);
}

void
work(EV::Gearman self, ...)
CODE:
{
    /* Start (or restart) the worker GRAB loop */
    self->worker_active = 1;
    self->worker_one_shot = 0;
    if (items > 1 && SvOK(ST(1)) && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVCV) {
        CLEAR_HANDLER(self->worker_on_idle);
        self->worker_on_idle = newSVsv(ST(1));
    }
    worker_continue(aTHX_ self);
}

void
work_one(EV::Gearman self, SV *cb_sv = &PL_sv_undef)
CODE:
{
    SV *cb = (SvOK(cb_sv) && SvROK(cb_sv)) ? cb_sv : NULL;
    self->worker_active = 1;
    self->worker_one_shot = 1;
    if (cb) {
        CLEAR_HANDLER(self->worker_on_idle);
        self->worker_on_idle = newSVsv(cb);
    }
    worker_continue(aTHX_ self);
}

void
work_stop(EV::Gearman self)
CODE:
{
    self->worker_active = 0;
    self->worker_one_shot = 0;
}

void
grab_job(EV::Gearman self, SV *cb_sv)
CODE:
{
    GM_CROAK_UNLESS_ALIVE(self);
    if (!SvROK(cb_sv) || SvTYPE(SvRV(cb_sv)) != SVt_PVCV)
        croak("grab_job: callback required");
    self->worker_grab_inflight = 1;
    ev_gm_req_t *r = alloc_req(CB_GRAB_JOB, cb_sv);
    enqueue_packet(aTHX_ self,
        self->worker_grab_uniq ? GM_CMD_GRAB_JOB_UNIQ : GM_CMD_GRAB_JOB,
        NULL, 0, r);
}

void
all_yours(EV::Gearman self)
CODE:
{
    if (self->connected)
        enqueue_packet(aTHX_ self, GM_CMD_ALL_YOURS, NULL, 0, NULL);
}

void
admin(EV::Gearman self, SV *cmd_sv, ...)
CODE:
{
    GM_CROAK_UNLESS_ALIVE(self);
    STRLEN clen;
    const char *cmd = SvPV(cmd_sv, clen);
    SV *cb = NULL;
    if (items > 2 && SvOK(ST(items-1)) && SvROK(ST(items-1)) && SvTYPE(SvRV(ST(items-1))) == SVt_PVCV)
        cb = ST(items-1);

    /* Multi-line admin commands terminate with ".\n"; single-line ones don't. */
    int multi = 0;
    /* Strip trailing whitespace for matching */
    size_t cl = clen;
    while (cl > 0 && (cmd[cl-1] == '\n' || cmd[cl-1] == ' ' || cmd[cl-1] == '\t' || cmd[cl-1] == '\r'))
        cl--;
    if ((cl ==  6 && memcmp(cmd, "status",         6) == 0) ||
        (cl ==  7 && memcmp(cmd, "workers",        7) == 0) ||
        (cl == 14 && memcmp(cmd, "prioritystatus", 14) == 0))
        multi = 1;
    /* "shutdown" / "shutdown graceful" => single line ("OK\n" then disconnect) */
    /* "version" => single line */
    /* "maxqueue X N" => "OK\n" */

    /* Build full text command (must end in \n) */
    char *txt;
    size_t txt_len;
    int has_nl = (clen > 0 && cmd[clen-1] == '\n');
    txt_len = clen + (has_nl ? 0 : 1);
    Newx(txt, txt_len, char);
    memcpy(txt, cmd, clen);
    if (!has_nl) txt[txt_len - 1] = '\n';

    ev_gm_req_t *r = alloc_req(CB_ADMIN, cb);
    r->admin_terminator = multi;

    /* submit_bytes takes ownership of txt and Safefrees it. */
    submit_bytes(aTHX_ self, txt, txt_len, r);
}

int
connect_timeout(EV::Gearman self, ...)
CODE:
{
    if (items > 1) {
        self->connect_timeout_ms = SvIV(ST(1));
        if (self->connect_timeout_ms < 0) self->connect_timeout_ms = 0;
    }
    RETVAL = self->connect_timeout_ms;
}
OUTPUT:
    RETVAL

int
command_timeout(EV::Gearman self, ...)
CODE:
{
    if (items > 1) {
        self->command_timeout_ms = SvIV(ST(1));
        if (self->command_timeout_ms < 0) self->command_timeout_ms = 0;
        if (self->command_timeout_ms == 0)
            disarm_cmd_timer(self);
        else if (!ngx_queue_empty(&self->cb_queue))
            arm_cmd_timer(self);
    }
    RETVAL = self->command_timeout_ms;
}
OUTPUT:
    RETVAL

void
reconnect(EV::Gearman self, ...)
CODE:
{
    /* Optional args: only overwrite delay / max_attempts when the
       caller supplies them, so reconnect(1) re-enables without
       resetting the values configured at construction time. */
    if (items < 2) croak("reconnect: enable arg required");
    self->reconnect = SvTRUE(ST(1)) ? 1 : 0;
    if (items > 2) {
        int d = SvIV(ST(2));
        self->reconnect_delay_ms = d >= 0 ? d : 0;
    }
    if (items > 3) {
        int m = SvIV(ST(3));
        self->max_reconnect_attempts = m >= 0 ? m : 0;
    }
    if (!self->reconnect) {
        self->reconnect_attempts = 0;
        stop_reconnect_timer(self);
    }
}

int
reconnect_enabled(EV::Gearman self)
CODE:
    RETVAL = self->reconnect;
OUTPUT:
    RETVAL

int
priority(EV::Gearman self, ...)
CODE:
{
    if (items > 1) {
        self->priority = SvIV(ST(1));
        if (self->priority < -2) self->priority = -2;
        if (self->priority > 2) self->priority = 2;
        if (self->reading) {
            ev_io_stop(self->loop, &self->rio);
            ev_set_priority(&self->rio, self->priority);
            ev_io_start(self->loop, &self->rio);
        } else {
            ev_set_priority(&self->rio, self->priority);
        }
        if (self->writing) {
            ev_io_stop(self->loop, &self->wio);
            ev_set_priority(&self->wio, self->priority);
            ev_io_start(self->loop, &self->wio);
        } else {
            ev_set_priority(&self->wio, self->priority);
        }
    }
    RETVAL = self->priority;
}
OUTPUT:
    RETVAL

int
keepalive(EV::Gearman self, ...)
CODE:
{
    if (items > 1) {
        self->keepalive = SvIV(ST(1));
        if (self->keepalive < 0) self->keepalive = 0;
        if (self->connected && self->fd >= 0)
            apply_keepalive(self);
    }
    RETVAL = self->keepalive;
}
OUTPUT:
    RETVAL

# ===== Job object methods (called from Perl via $job->complete etc.) =====

MODULE = EV::Gearman  PACKAGE = EV::Gearman::Job

void
_send_event(SV *job_sv, int kind, SV *data_sv = &PL_sv_undef)
CODE:
{
    /* kind: 0=complete, 1=fail, 2=exception, 3=data, 4=warning */
    STRLEN hl;
    const char *h;
    ev_gm_t *self = job_resolve(aTHX_ job_sv, &h, &hl, "_send_event");

    STRLEN dl = 0;
    const char *dp = SvOK(data_sv) ? SvPV(data_sv, dl) : NULL;

    static const uint32_t cmds[] = {
        GM_CMD_WORK_COMPLETE, GM_CMD_WORK_FAIL,    GM_CMD_WORK_EXCEPTION,
        GM_CMD_WORK_DATA,     GM_CMD_WORK_WARNING,
    };
    if (kind < 0 || kind >= (int)(sizeof(cmds)/sizeof(cmds[0])))
        croak("_send_event: unknown kind %d", kind);

    /* WORK_FAIL takes no data; the rest take handle\0data even if data
       is empty (the trailing NUL is the separator, not a terminator). */
    send_work_event(aTHX_ self, cmds[kind], h, hl,
                    kind == 1 ? NULL : (dp ? dp : ""), dl);
}

void
_send_status(SV *job_sv, SV *num_sv, SV *denom_sv)
CODE:
{
    STRLEN hl;
    const char *h;
    ev_gm_t *self = job_resolve(aTHX_ job_sv, &h, &hl, "_send_status");

    STRLEN nl, dl;
    const char *n = SvPV(num_sv, nl);
    const char *d = SvPV(denom_sv, dl);
    const char *ptrs[3] = { h, n, d };
    STRLEN lens[3] = { hl, nl, dl };
    size_t blen;
    char *body = gm_encode_args(3, ptrs, lens, &blen);
    enqueue_packet(aTHX_ self, GM_CMD_WORK_STATUS, body, blen, NULL);
    Safefree(body);
}

