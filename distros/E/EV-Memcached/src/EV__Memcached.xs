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
#include <arpa/inet.h>

/* ================================================================
 * Constants
 * ================================================================ */

#define MC_MAGIC_ALIVE 0xCAFEBEEF
#define MC_MAGIC_FREED 0xDEADCAFE

#define MC_REQ_MAGIC 0x80
#define MC_RES_MAGIC 0x81
#define MC_HEADER_SIZE 24

/* Opcodes */
#define MC_OP_GET        0x00
#define MC_OP_SET        0x01
#define MC_OP_ADD        0x02
#define MC_OP_REPLACE    0x03
#define MC_OP_DELETE     0x04
#define MC_OP_INCR       0x05
#define MC_OP_DECR       0x06
#define MC_OP_QUIT       0x07
#define MC_OP_FLUSH      0x08
#define MC_OP_NOOP       0x0A
#define MC_OP_VERSION    0x0B
#define MC_OP_GETKQ      0x0D
#define MC_OP_APPEND     0x0E
#define MC_OP_PREPEND    0x0F
#define MC_OP_STAT       0x10
#define MC_OP_SETQ       0x11
#define MC_OP_FLUSHQ     0x18
#define MC_OP_TOUCH           0x1C
#define MC_OP_GAT             0x1D
#define MC_OP_SASL_LIST_MECHS 0x20
#define MC_OP_SASL_AUTH       0x21
#define MC_OP_SASL_STEP       0x22

/* Status codes */
#define MC_STATUS_OK              0x0000
#define MC_STATUS_KEY_NOT_FOUND   0x0001
#define MC_STATUS_KEY_EXISTS      0x0002
#define MC_STATUS_VALUE_TOO_LARGE 0x0003
#define MC_STATUS_INVALID_ARGS    0x0004
#define MC_STATUS_NOT_STORED      0x0005
#define MC_STATUS_NON_NUMERIC     0x0006
#define MC_STATUS_AUTH_ERROR      0x0020
#define MC_STATUS_AUTH_CONTINUE   0x0021
#define MC_STATUS_UNKNOWN_CMD     0x0081
#define MC_STATUS_OUT_OF_MEMORY   0x0082

#define BUF_INIT_SIZE 16384
#define MC_MAX_KEY_LEN 250

/* Callback command types */
#define CB_CMD_GET         0   /* get - return value only */
#define CB_CMD_GETS        1   /* gets - return {value, flags, cas} */
#define CB_CMD_STORE       2   /* set/add/replace/append/prepend - return 1 */
#define CB_CMD_DELETE      3   /* delete - return 1 */
#define CB_CMD_ARITH       4   /* incr/decr - return new value */
#define CB_CMD_TOUCH       5   /* touch - return 1 */
#define CB_CMD_GAT         6   /* gat - return value */
#define CB_CMD_GATS        7   /* gats - return {value, flags, cas} */
#define CB_CMD_VERSION     8   /* version - return string */
#define CB_CMD_NOOP        9   /* noop - return 1 */
#define CB_CMD_FLUSH      10   /* flush - return 1 */
#define CB_CMD_STATS      11   /* stats - accumulate, return hash */
#define CB_CMD_MGET_ENTRY  12   /* individual GETKQ in mget */
#define CB_CMD_MGET_FENCE  13   /* NOOP fence in mget */
#define CB_CMD_QUIT        14   /* quit */
#define CB_CMD_MGETS_ENTRY 15   /* individual GETKQ in mgets (full info) */
#define CB_CMD_MGETS_FENCE 16   /* NOOP fence in mgets */
#define CB_CMD_SASL_LIST   17   /* sasl_list_mechs - return string */
#define CB_CMD_SASL_AUTH   18   /* sasl_auth - return 1 on success */

#define CLEAR_HANDLER(field) \
    do { if (NULL != (field)) { SvREFCNT_dec(field); (field) = NULL; } } while(0)

#define MC_CROAK_UNLESS_CONNECTED(self) \
    do { \
        if (!(self)->connected && !(self)->connecting && \
            !((self)->reconnect && (self)->reconnect_timer_active)) \
            croak("not connected"); \
    } while(0)

/* ================================================================
 * Type declarations
 * ================================================================ */

typedef struct ev_mc_s ev_mc_t;
typedef struct ev_mc_cb_s ev_mc_cb_t;
typedef struct ev_mc_wait_s ev_mc_wait_t;

typedef ev_mc_t* EV__Memcached;
typedef struct ev_loop* EV__Loop;

/* ================================================================
 * Data structures
 * ================================================================ */

struct ev_mc_cb_s {
    SV *cb;               /* Perl callback (NULL for fire-and-forget / mget entries) */
    ngx_queue_t queue;
    uint32_t opaque;
    int cmd;              /* CB_CMD_* */
    int quiet;            /* 1 = quiet variant, may not get response */
    int counted;          /* 1 = contributes to pending_count */
    int skipped;
    HV *stats_hv;         /* for CB_CMD_STATS: accumulated hash */
    HV *mget_results;     /* for CB_CMD_MGET_ENTRY: shared hash (borrowed) */
                          /* for CB_CMD_MGET_FENCE: owned hash */
};

struct ev_mc_wait_s {
    char *packet;
    size_t packet_len;
    SV *cb;
    int cmd;
    int quiet;
    uint32_t opaque;
    HV *stats_hv;
    HV *mget_results;     /* borrowed for MGET_ENTRY, owned for MGET_FENCE */
    int counted;
    int no_response;      /* 1: fire-and-forget, drain to wbuf only, no cb_queue entry */
    ngx_queue_t queue;
    ev_tstamp queued_at;
};

struct ev_mc_s {
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

    /* Callbacks */
    SV *on_error;
    SV *on_connect;
    SV *on_disconnect;

    /* Command queue */
    ngx_queue_t cb_queue;
    ngx_queue_t wait_queue;
    int pending_count;
    int waiting_count;
    int max_pending;       /* 0 = unlimited */
    uint32_t next_opaque;

    /* Reconnection */
    char *host;
    int port;
    char *path;
    int reconnect;
    int reconnect_delay_ms;
    int max_reconnect_attempts;
    int reconnect_attempts;
    ev_timer reconnect_timer;
    int reconnect_timer_active;
    int intentional_disconnect;
    int resume_waiting_on_reconnect;

    /* Timeouts */
    int connect_timeout_ms;
    ev_timer connect_timer;
    int connect_timer_active;
    int command_timeout_ms;
    ev_timer cmd_timer;
    int cmd_timer_active;

    /* Flow control */
    int waiting_timeout_ms;
    ev_timer waiting_timer;
    int waiting_timer_active;

    /* Safety */
    int callback_depth;
    int in_cb_cleanup;
    int in_wait_cleanup;

    /* Options */
    int priority;
    int keepalive;

    /* SASL auth */
    char *username;
    char *password;
};

/* ================================================================
 * Shared error strings (initialized in BOOT)
 * ================================================================ */

static SV *err_skipped = NULL;
static SV *err_disconnected = NULL;
static SV *err_waiting_timeout = NULL;

/* ================================================================
 * Forward declarations
 * ================================================================ */

static void io_cb(EV_P_ ev_io *w, int revents);
static void reconnect_timer_cb(EV_P_ ev_timer *w, int revents);
static void waiting_timer_cb(EV_P_ ev_timer *w, int revents);
static void connect_timeout_cb(EV_P_ ev_timer *w, int revents);
static void cmd_timeout_cb(EV_P_ ev_timer *w, int revents);
static void arm_cmd_timer(ev_mc_t *self);
static void disarm_cmd_timer(ev_mc_t *self);
static uint32_t mc_enqueue_cmd(pTHX_ ev_mc_t *self,
    uint8_t opcode, const char *key, STRLEN key_len,
    const char *value, STRLEN value_len,
    const char *extras, uint8_t extras_len,
    uint64_t cas, int cmd, int quiet, SV *cb);
static void start_reading(ev_mc_t *self);
static void stop_reading(ev_mc_t *self);
static void start_writing(ev_mc_t *self);
static void stop_writing(ev_mc_t *self);
static void start_connect(pTHX_ ev_mc_t *self);
static void cleanup_connection(pTHX_ ev_mc_t *self);
static void emit_error(pTHX_ ev_mc_t *self, const char *msg);
static void handle_disconnect(pTHX_ ev_mc_t *self, const char *reason);
static void schedule_reconnect(pTHX_ ev_mc_t *self);
static void apply_keepalive(ev_mc_t *self);
static void report_connect_error(pTHX_ ev_mc_t *self, const char *errbuf);
static void finish_connect_success(pTHX_ ev_mc_t *self);
static void mc_send_sasl_auth(pTHX_ ev_mc_t *self, SV *cb);
static void stop_connect_timer(ev_mc_t *self);
static void stop_reconnect_timer(ev_mc_t *self);
static void stop_waiting_timer(ev_mc_t *self);
static void send_next_waiting(pTHX_ ev_mc_t *self);
static int check_destroyed(ev_mc_t *self);
static void cancel_pending(pTHX_ ev_mc_t *self, SV *err_sv);
static void cancel_waiting(pTHX_ ev_mc_t *self, SV *err_sv);

/* ================================================================
 * Binary protocol helpers (portable, no unaligned access)
 * ================================================================ */

static void mc_write_u16(char *buf, uint16_t val) {
    val = htons(val);
    memcpy(buf, &val, 2);
}

static void mc_write_u32(char *buf, uint32_t val) {
    val = htonl(val);
    memcpy(buf, &val, 4);
}

static void mc_write_u64(char *buf, uint64_t val) {
    uint32_t hi = htonl((uint32_t)(val >> 32));
    uint32_t lo = htonl((uint32_t)(val & 0xFFFFFFFF));
    memcpy(buf, &hi, 4);
    memcpy(buf + 4, &lo, 4);
}

static uint16_t mc_read_u16(const char *buf) {
    uint16_t val;
    memcpy(&val, buf, 2);
    return ntohs(val);
}

static uint32_t mc_read_u32(const char *buf) {
    uint32_t val;
    memcpy(&val, buf, 4);
    return ntohl(val);
}

static uint64_t mc_read_u64(const char *buf) {
    uint32_t hi, lo;
    memcpy(&hi, buf, 4);
    memcpy(&lo, buf + 4, 4);
    return ((uint64_t)ntohl(hi) << 32) | ntohl(lo);
}

static void mc_encode_header(char *buf, uint8_t opcode, uint16_t key_len,
    uint8_t extras_len, uint32_t body_len, uint32_t opaque, uint64_t cas)
{
    buf[0] = MC_REQ_MAGIC;
    buf[1] = opcode;
    mc_write_u16(buf + 2, key_len);
    buf[4] = extras_len;
    buf[5] = 0; /* data_type = raw */
    mc_write_u16(buf + 6, 0); /* vbucket / reserved */
    mc_write_u32(buf + 8, body_len);
    mc_write_u32(buf + 12, opaque);
    mc_write_u64(buf + 16, cas);
}

/* ================================================================
 * Status code to string
 * ================================================================ */

static const char* mc_status_str(uint16_t status) {
    switch (status) {
        case MC_STATUS_OK:              return "OK";
        case MC_STATUS_KEY_NOT_FOUND:   return "NOT_FOUND";
        case MC_STATUS_KEY_EXISTS:      return "EXISTS";
        case MC_STATUS_VALUE_TOO_LARGE: return "VALUE_TOO_LARGE";
        case MC_STATUS_INVALID_ARGS:    return "INVALID_ARGUMENTS";
        case MC_STATUS_NOT_STORED:      return "NOT_STORED";
        case MC_STATUS_NON_NUMERIC:     return "NON_NUMERIC_VALUE";
        case MC_STATUS_AUTH_ERROR:      return "AUTH_ERROR";
        case MC_STATUS_AUTH_CONTINUE:   return "AUTH_CONTINUE";
        case MC_STATUS_UNKNOWN_CMD:     return "UNKNOWN_COMMAND";
        case MC_STATUS_OUT_OF_MEMORY:   return "OUT_OF_MEMORY";
        default:                        return "UNKNOWN_ERROR";
    }
}

/* ================================================================
 * Buffer management
 * ================================================================ */

static void buf_ensure_write(ev_mc_t *self, size_t needed) {
    /* Compact first: reclaim any already-sent prefix. The capacity check
       below short-circuits the "compaction alone sufficed" case. */
    if (self->wbuf_off > 0) {
        size_t live = self->wbuf_len - self->wbuf_off;
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

static void buf_ensure_read(ev_mc_t *self, size_t needed) {
    size_t total = self->rbuf_len + needed;
    if (self->rbuf_cap >= total) return;
    size_t new_cap = self->rbuf_cap ? self->rbuf_cap : BUF_INIT_SIZE;
    while (new_cap < total) new_cap *= 2;
    Renew(self->rbuf, new_cap, char);
    self->rbuf_cap = new_cap;
}

static void buf_append_write(ev_mc_t *self, const char *data, size_t len) {
    buf_ensure_write(self, len);
    memcpy(self->wbuf + self->wbuf_len, data, len);
    self->wbuf_len += len;
}

/* ================================================================
 * Watcher helpers
 * ================================================================ */

static void start_reading(ev_mc_t *self) {
    if (!self->reading && self->fd >= 0) {
        ev_io_start(self->loop, &self->rio);
        self->reading = 1;
    }
}

static void stop_reading(ev_mc_t *self) {
    if (self->reading) {
        ev_io_stop(self->loop, &self->rio);
        self->reading = 0;
    }
}

static void start_writing(ev_mc_t *self) {
    if (!self->writing && self->fd >= 0) {
        ev_io_start(self->loop, &self->wio);
        self->writing = 1;
    }
}

static void stop_writing(ev_mc_t *self) {
    if (self->writing) {
        ev_io_stop(self->loop, &self->wio);
        self->writing = 0;
    }
}

static int check_destroyed(ev_mc_t *self) {
    if (self->magic == MC_MAGIC_FREED && self->callback_depth == 0) {
        Safefree(self);
        return 1;
    }
    return 0;
}

/* ================================================================
 * Callback invocation
 * ================================================================ */

/* Invoke Perl callback with two arguments.
 * result and error are newly created SVs (refcount=1) that become mortal.
 * Pass NULL for undef. */
static void invoke_cb(pTHX_ ev_mc_t *self, SV *cb, SV *result, SV *error) {
    if (!cb) return;

    self->callback_depth++;

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 2);
    if (result)
        mPUSHs(result);
    else
        PUSHs(&PL_sv_undef);
    if (error)
        mPUSHs(error);
    else
        PUSHs(&PL_sv_undef);
    PUTBACK;
    call_sv(cb, G_DISCARD | G_EVAL);
    if (SvTRUE(ERRSV)) {
        warn("EV::Memcached: callback error: %s", SvPV_nolen(ERRSV));
        sv_setsv(ERRSV, &PL_sv_undef);
    }
    FREETMPS;
    LEAVE;

    self->callback_depth--;
}

/* Invoke a user handler with at most one mortal arg; catch exceptions
   so a die in user code can't unwind through libev. */
static void invoke_handler(pTHX_ ev_mc_t *self, SV *cb, SV *arg, const char *label) {
    if (NULL == cb) { if (arg) SvREFCNT_dec(arg); return; }

    self->callback_depth++;

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    if (arg) XPUSHs(sv_2mortal(arg));
    PUTBACK;
    call_sv(cb, G_DISCARD | G_EVAL);
    if (SvTRUE(ERRSV)) {
        warn("EV::Memcached: %s callback error: %s", label, SvPV_nolen(ERRSV));
        sv_setsv(ERRSV, &PL_sv_undef);
    }
    FREETMPS;
    LEAVE;

    self->callback_depth--;
}

static void emit_error(pTHX_ ev_mc_t *self, const char *msg) {
    invoke_handler(aTHX_ self, self->on_error, newSVpv(msg, 0), "on_error");
}

static void emit_connect(pTHX_ ev_mc_t *self) {
    invoke_handler(aTHX_ self, self->on_connect, NULL, "on_connect");
}

static void emit_disconnect(pTHX_ ev_mc_t *self) {
    invoke_handler(aTHX_ self, self->on_disconnect, NULL, "on_disconnect");
}

static void apply_keepalive(ev_mc_t *self) {
    if (self->keepalive <= 0 || self->path) return;
    int one = 1;
    setsockopt(self->fd, SOL_SOCKET, SO_KEEPALIVE, &one, sizeof(one));
#ifdef TCP_KEEPIDLE
    setsockopt(self->fd, IPPROTO_TCP, TCP_KEEPIDLE,
               &self->keepalive, sizeof(self->keepalive));
#endif
}

/* Common tail for synchronous connect-failure paths in start_connect:
   emit error, run pending callbacks, and arm reconnect if configured.
   Caller returns immediately after invoking. */
static void report_connect_error(pTHX_ ev_mc_t *self, const char *errbuf) {
    self->callback_depth++;
    emit_error(aTHX_ self, errbuf);
    self->callback_depth--;
    if (check_destroyed(self)) return;
    if (!self->intentional_disconnect && self->reconnect)
        schedule_reconnect(aTHX_ self);
}

/* Shared post-connect-success path used by both on_connect_complete (after
   async EINPROGRESS resolves) and start_connect (when connect(2) returns
   immediately). Caller must already have set self->connected = 1 and
   stopped/initialized the io watchers as required by its path. */
static void finish_connect_success(pTHX_ ev_mc_t *self) {
    self->reconnect_attempts = 0;

    start_reading(self);
    apply_keepalive(self);

    mc_send_sasl_auth(aTHX_ self, NULL);

    emit_connect(aTHX_ self);
    if (check_destroyed(self)) return;

    /* Drain wait_queue immediately unless we are waiting for SASL_AUTH
       to complete; the SASL response handler calls send_next_waiting. */
    if (!self->username || !self->password)
        send_next_waiting(aTHX_ self);
}

/* ================================================================
 * Callback entry management
 * ================================================================ */

static ev_mc_cb_t* alloc_cbt(void) {
    ev_mc_cb_t *cbt;
    Newxz(cbt, 1, ev_mc_cb_t);
    return cbt;
}

static void cleanup_cbt(pTHX_ ev_mc_cb_t *cbt) {
    CLEAR_HANDLER(cbt->cb);
    if (cbt->stats_hv) {
        SvREFCNT_dec((SV*)cbt->stats_hv);
        cbt->stats_hv = NULL;
    }
    if ((cbt->cmd == CB_CMD_MGET_FENCE || cbt->cmd == CB_CMD_MGETS_FENCE) && cbt->mget_results) {
        SvREFCNT_dec((SV*)cbt->mget_results);
        cbt->mget_results = NULL;
    }
    /* MGET_ENTRY has borrowed ref - don't decrement */
    Safefree(cbt);
}

static void cleanup_wait(pTHX_ ev_mc_wait_t *wt) {
    CLEAR_HANDLER(wt->cb);
    if (wt->packet) { Safefree(wt->packet); wt->packet = NULL; }
    if (wt->stats_hv) {
        SvREFCNT_dec((SV*)wt->stats_hv);
        wt->stats_hv = NULL;
    }
    if ((wt->cmd == CB_CMD_MGET_FENCE || wt->cmd == CB_CMD_MGETS_FENCE) && wt->mget_results) {
        SvREFCNT_dec((SV*)wt->mget_results);
        wt->mget_results = NULL;
    }
    Safefree(wt);
}

/* ================================================================
 * Cancel pending/waiting commands (on disconnect)
 * ================================================================ */

/* mark_skipped: if true, set cbt->skipped=1 and invoke ALL callbacks (skip_pending behavior).
 * if false, only invoke non-skipped callbacks (cancel_pending behavior).
 *
 * Callers MUST bump callback_depth before calling this (and call
 * check_destroyed after) — DESTROY sets magic=FREED before running
 * us, so an unconditional check_destroyed here would Safefree(self)
 * mid-loop. The depth bump pins self until the caller is done. */
static void cancel_pending_impl(pTHX_ ev_mc_t *self, SV *err_sv, int mark_skipped) {
    if (self->in_cb_cleanup) return;
    self->in_cb_cleanup = 1;

    while (!ngx_queue_empty(&self->cb_queue)) {
        ngx_queue_t *q = ngx_queue_head(&self->cb_queue);
        ev_mc_cb_t *cbt = ngx_queue_data(q, ev_mc_cb_t, queue);
        ngx_queue_remove(q);
        if (cbt->counted) self->pending_count--;

        int already_skipped = cbt->skipped;
        if (mark_skipped) cbt->skipped = 1;
        if (cbt->cb && !already_skipped) {
            invoke_cb(aTHX_ self, cbt->cb, NULL, newSVsv(err_sv));
            if (self->magic == MC_MAGIC_FREED) {
                cleanup_cbt(aTHX_ cbt);
                self->in_cb_cleanup = 0;
                return;
            }
        }
        cleanup_cbt(aTHX_ cbt);
    }
    self->pending_count = 0;
    self->in_cb_cleanup = 0;
}

static void cancel_pending(pTHX_ ev_mc_t *self, SV *err_sv) {
    cancel_pending_impl(aTHX_ self, err_sv, 0);
}

static void cancel_waiting(pTHX_ ev_mc_t *self, SV *err_sv) {
    if (self->in_wait_cleanup) return;
    self->in_wait_cleanup = 1;

    while (!ngx_queue_empty(&self->wait_queue)) {
        ngx_queue_t *q = ngx_queue_head(&self->wait_queue);
        ev_mc_wait_t *wt = ngx_queue_data(q, ev_mc_wait_t, queue);
        ngx_queue_remove(q);
        self->waiting_count--;

        if (wt->cb) {
            invoke_cb(aTHX_ self, wt->cb, NULL, newSVsv(err_sv));
            if (self->magic == MC_MAGIC_FREED) {
                cleanup_wait(aTHX_ wt);
                self->in_wait_cleanup = 0;
                /* Caller bumps depth before calling us (disconnect XS,
                   skip_waiting XS, or io_cb path), so check_destroyed
                   here would prematurely free during DESTROY where
                   magic is already FREED before we run. */
                return;
            }
        }
        cleanup_wait(aTHX_ wt);
    }
    self->waiting_count = 0;
    self->in_wait_cleanup = 0;
}

/* ================================================================
 * Connection cleanup and disconnect handling
 * ================================================================ */

static void cleanup_connection(pTHX_ ev_mc_t *self) {
    stop_reading(self);
    stop_writing(self);

    stop_connect_timer(self);
    disarm_cmd_timer(self);
    stop_waiting_timer(self);

    if (self->fd >= 0) {
        close(self->fd);
        self->fd = -1;
    }

    self->connected = 0;
    self->connecting = 0;
    self->rbuf_len = 0;
    self->wbuf_len = 0;
    self->wbuf_off = 0;
}

static void handle_disconnect(pTHX_ ev_mc_t *self, const char *reason) {
    int was_connected = self->connected;

    cleanup_connection(aTHX_ self);

    /* Cancel pending commands */
    cancel_pending(aTHX_ self, err_disconnected);
    if (self->magic == MC_MAGIC_FREED) return;

    if (!self->resume_waiting_on_reconnect) {
        cancel_waiting(aTHX_ self, err_disconnected);
        if (self->magic == MC_MAGIC_FREED) return;
    }

    if (was_connected) {
        emit_disconnect(aTHX_ self);
        if (check_destroyed(self)) return;
    }

    if (reason) {
        emit_error(aTHX_ self, reason);
        if (check_destroyed(self)) return;
    }

    if (!self->intentional_disconnect && self->reconnect) {
        schedule_reconnect(aTHX_ self);
    }
}

/* ================================================================
 * Reconnection
 * ================================================================ */

static void schedule_reconnect(pTHX_ ev_mc_t *self) {
    if (self->reconnect_timer_active) return;
    if (self->max_reconnect_attempts > 0 &&
        self->reconnect_attempts >= self->max_reconnect_attempts) {
        emit_error(aTHX_ self, "max reconnect attempts reached");
        return;
    }

    self->reconnect_attempts++;

    /* Always defer through a timer (even with delay==0) so that an
       immediate connect failure cannot recurse:
       schedule_reconnect -> start_connect -> report_connect_error ->
       schedule_reconnect -> ... blowing the C stack. */
    ev_tstamp delay = (ev_tstamp)self->reconnect_delay_ms / 1000.0;
    if (delay < 0) delay = 0;
    ev_timer_init(&self->reconnect_timer, reconnect_timer_cb, delay, 0.0);
    self->reconnect_timer.data = (void *)self;
    ev_timer_start(self->loop, &self->reconnect_timer);
    self->reconnect_timer_active = 1;
}

static void arm_cmd_timer(ev_mc_t *self) {
    if (self->command_timeout_ms <= 0) return;
    if (!self->connected) return;
    ev_tstamp timeout = (ev_tstamp)self->command_timeout_ms / 1000.0;
    if (self->cmd_timer_active) {
        /* Adjust repeat in-place; ev_timer_again restarts using the new value.
           ev_timer_set is forbidden on an active watcher per libev docs. */
        self->cmd_timer.repeat = timeout;
        ev_timer_again(self->loop, &self->cmd_timer);
    } else {
        ev_timer_init(&self->cmd_timer, cmd_timeout_cb, timeout, timeout);
        self->cmd_timer.data = (void *)self;
        ev_timer_start(self->loop, &self->cmd_timer);
        self->cmd_timer_active = 1;
    }
}

static void disarm_cmd_timer(ev_mc_t *self) {
    if (self->cmd_timer_active) {
        ev_timer_stop(self->loop, &self->cmd_timer);
        self->cmd_timer_active = 0;
    }
}

static void stop_connect_timer(ev_mc_t *self) {
    if (self->connect_timer_active) {
        ev_timer_stop(self->loop, &self->connect_timer);
        self->connect_timer_active = 0;
    }
}

static void stop_reconnect_timer(ev_mc_t *self) {
    if (self->reconnect_timer_active) {
        ev_timer_stop(self->loop, &self->reconnect_timer);
        self->reconnect_timer_active = 0;
    }
}

static void stop_waiting_timer(ev_mc_t *self) {
    if (self->waiting_timer_active) {
        ev_timer_stop(self->loop, &self->waiting_timer);
        self->waiting_timer_active = 0;
    }
}

static void cmd_timeout_cb(EV_P_ ev_timer *w, int revents) {
    ev_mc_t *self = (ev_mc_t *)w->data;
    (void)loop; (void)revents;

    if (self->magic != MC_MAGIC_ALIVE) return;

    if (ngx_queue_empty(&self->cb_queue)) {
        disarm_cmd_timer(self);
        return;
    }

    /* Stop the repeating timer before disconnect */
    disarm_cmd_timer(self);
    self->callback_depth++;
    handle_disconnect(aTHX_ self, "command timeout");
    self->callback_depth--;
    check_destroyed(self);
}

/* Send SASL PLAIN auth. If cb is NULL, creates an internal callback
 * that disconnects on auth failure. */
static void mc_send_sasl_auth(pTHX_ ev_mc_t *self, SV *cb) {
    if (!self->username || !self->password) return;

    size_t ulen = strlen(self->username);
    size_t plen = strlen(self->password);
    size_t vlen = 1 + ulen + 1 + plen;
    char *authdata;
    Newx(authdata, vlen, char);
    authdata[0] = '\0';
    memcpy(authdata + 1, self->username, ulen);
    authdata[1 + ulen] = '\0';
    memcpy(authdata + 2 + ulen, self->password, plen);

    mc_enqueue_cmd(aTHX_ self, MC_OP_SASL_AUTH, "PLAIN", 5,
                   authdata, vlen, NULL, 0, 0, CB_CMD_SASL_AUTH, 0, cb);
    Safefree(authdata);
}

static void connect_timeout_cb(EV_P_ ev_timer *w, int revents) {
    ev_mc_t *self = (ev_mc_t *)w->data;
    (void)loop; (void)revents;

    if (self->magic != MC_MAGIC_ALIVE) return;

    self->connect_timer_active = 0;
    self->callback_depth++;
    handle_disconnect(aTHX_ self, "connect timeout");
    self->callback_depth--;
    check_destroyed(self);
}

static void reconnect_timer_cb(EV_P_ ev_timer *w, int revents) {
    ev_mc_t *self = (ev_mc_t *)w->data;
    (void)loop; (void)revents;

    if (self->magic != MC_MAGIC_ALIVE) return;

    self->reconnect_timer_active = 0;
    self->callback_depth++;
    start_connect(aTHX_ self);
    self->callback_depth--;
    check_destroyed(self);
}

/* ================================================================
 * Flow control: waiting timer
 * ================================================================ */

static void schedule_waiting_timer(ev_mc_t *self);

static void expire_waiting_commands(pTHX_ ev_mc_t *self) {
    ev_tstamp now = ev_now(self->loop);
    ev_tstamp timeout = (ev_tstamp)self->waiting_timeout_ms / 1000.0;

    while (!ngx_queue_empty(&self->wait_queue)) {
        ngx_queue_t *q = ngx_queue_head(&self->wait_queue);
        ev_mc_wait_t *wt = ngx_queue_data(q, ev_mc_wait_t, queue);

        if (wt->queued_at + timeout > now) break; /* not expired yet */

        ngx_queue_remove(q);
        self->waiting_count--;

        if (wt->cb) {
            invoke_cb(aTHX_ self, wt->cb, NULL, newSVsv(err_waiting_timeout));
            if (self->magic == MC_MAGIC_FREED) {
                cleanup_wait(aTHX_ wt);
                return;
            }
        }
        cleanup_wait(aTHX_ wt);
    }
}

static void waiting_timer_cb(EV_P_ ev_timer *w, int revents) {
    ev_mc_t *self = (ev_mc_t *)w->data;
    (void)loop; (void)revents;

    if (self->magic != MC_MAGIC_ALIVE) return;

    self->waiting_timer_active = 0;
    self->callback_depth++;
    expire_waiting_commands(aTHX_ self);
    self->callback_depth--;
    if (check_destroyed(self)) return;

    if (!ngx_queue_empty(&self->wait_queue) && self->waiting_timeout_ms > 0)
        schedule_waiting_timer(self);
}

static void schedule_waiting_timer(ev_mc_t *self) {
    if (self->waiting_timer_active) return;
    if (self->waiting_timeout_ms <= 0) return;
    if (ngx_queue_empty(&self->wait_queue)) return;

    ngx_queue_t *q = ngx_queue_head(&self->wait_queue);
    ev_mc_wait_t *wt = ngx_queue_data(q, ev_mc_wait_t, queue);
    ev_tstamp timeout = (ev_tstamp)self->waiting_timeout_ms / 1000.0;
    ev_tstamp delay = (wt->queued_at + timeout) - ev_now(self->loop);
    if (delay < 0.0) delay = 0.0;

    ev_timer_init(&self->waiting_timer, waiting_timer_cb, delay, 0.0);
    self->waiting_timer.data = (void *)self;
    ev_timer_start(self->loop, &self->waiting_timer);
    self->waiting_timer_active = 1;
}

/* ================================================================
 * Send next waiting command
 * ================================================================ */

static void send_next_waiting(pTHX_ ev_mc_t *self) {
    while (!ngx_queue_empty(&self->wait_queue) && self->connected) {
        ngx_queue_t *q = ngx_queue_head(&self->wait_queue);
        ev_mc_wait_t *wt = ngx_queue_data(q, ev_mc_wait_t, queue);

        /* max_pending gates only counted entries; mc_enqueue_cmd uses the
           same exception (|| !counted). Fire-and-forget (no_response) and
           mget GETKQ entries are uncounted and must not be blocked. */
        if (self->max_pending > 0 && self->pending_count >= self->max_pending
            && !wt->no_response && wt->counted)
            break;

        ngx_queue_remove(q);
        self->waiting_count--;

        /* Append packet to write buffer */
        buf_append_write(self, wt->packet, wt->packet_len);

        if (!wt->no_response) {
            ev_mc_cb_t *cbt = alloc_cbt();
            cbt->cb = wt->cb; wt->cb = NULL;
            cbt->opaque = wt->opaque;
            cbt->cmd = wt->cmd;
            cbt->quiet = wt->quiet;
            cbt->counted = wt->counted;
            cbt->stats_hv = wt->stats_hv; wt->stats_hv = NULL;
            cbt->mget_results = wt->mget_results; wt->mget_results = NULL;
            ngx_queue_insert_tail(&self->cb_queue, &cbt->queue);
            if (cbt->counted) self->pending_count++;
            arm_cmd_timer(self);
        }

        Safefree(wt->packet);
        Safefree(wt);

        start_writing(self);
    }
}

/* ================================================================
 * Build and enqueue a command
 * ================================================================ */

/* Allocate the next opaque, skipping 0 across wraparound (0 is reserved
 * for fire-and-forget commands so error responses don't get matched to
 * the wrong cb_queue head). */
static uint32_t mc_next_opaque(ev_mc_t *self) {
    uint32_t op = self->next_opaque++;
    if (self->next_opaque == 0) self->next_opaque = 1;
    return op;
}

/* Encode a complete request packet (header + extras + key + value) into
 * the caller-supplied buffer p, which must be at least
 * MC_HEADER_SIZE + extras_len + key_len + value_len bytes. */
static void mc_pack(char *p, uint8_t opcode,
    const char *key, uint16_t key_len,
    const char *value, uint32_t value_len,
    const char *extras, uint8_t extras_len,
    uint32_t opaque, uint64_t cas)
{
    uint32_t body_len = (uint32_t)extras_len + (uint32_t)key_len + value_len;
    mc_encode_header(p, opcode, key_len, extras_len, body_len, opaque, cas);
    p += MC_HEADER_SIZE;
    if (extras_len > 0) { memcpy(p, extras, extras_len); p += extras_len; }
    if (key_len > 0)    { memcpy(p, key, key_len); p += key_len; }
    if (value_len > 0)  { memcpy(p, value, value_len); }
}

/* Fire-and-forget using a quiet opcode (SETQ/FLUSHQ/...). No cb_queue
 * entry; opaque is always 0 (server only responds on error and that
 * response is silently discarded by handle_response_packet). */
static void mc_fire_and_forget(pTHX_ ev_mc_t *self,
    uint8_t opcode, const char *key, STRLEN key_len,
    const char *value, STRLEN value_len,
    const char *extras, uint8_t extras_len,
    uint64_t cas)
{
    if (key_len > MC_MAX_KEY_LEN)
        croak("key too long (%d bytes, max %d)", (int)key_len, MC_MAX_KEY_LEN);

    uint32_t body_len = extras_len + (uint32_t)key_len + (uint32_t)value_len;
    size_t packet_len = MC_HEADER_SIZE + body_len;

    if (self->connected) {
        buf_ensure_write(self, packet_len);
        mc_pack(self->wbuf + self->wbuf_len, opcode,
                key, (uint16_t)key_len, value, (uint32_t)value_len,
                extras, extras_len, 0, cas);
        self->wbuf_len += packet_len;
        start_writing(self);
    } else {
        /* Not yet connected (or reconnecting): queue and drain after connect. */
        ev_mc_wait_t *wt;
        Newxz(wt, 1, ev_mc_wait_t);
        Newx(wt->packet, packet_len, char);
        wt->packet_len = packet_len;
        mc_pack(wt->packet, opcode,
                key, (uint16_t)key_len, value, (uint32_t)value_len,
                extras, extras_len, 0, cas);
        wt->no_response = 1;
        wt->queued_at = ev_now(self->loop);
        ngx_queue_insert_tail(&self->wait_queue, &wt->queue);
        self->waiting_count++;
        if (self->waiting_timeout_ms > 0)
            schedule_waiting_timer(self);
    }
}

/* Build a binary protocol packet and enqueue for sending.
 * Returns the assigned opaque. */
static uint32_t mc_enqueue_cmd(pTHX_ ev_mc_t *self,
    uint8_t opcode, const char *key, STRLEN key_len,
    const char *value, STRLEN value_len,
    const char *extras, uint8_t extras_len,
    uint64_t cas, int cmd, int quiet, SV *cb)
{
    if (key_len > MC_MAX_KEY_LEN)
        croak("key too long (%d bytes, max %d)", (int)key_len, MC_MAX_KEY_LEN);

    uint32_t opaque = mc_next_opaque(self);
    uint32_t body_len = extras_len + (uint32_t)key_len + (uint32_t)value_len;
    size_t packet_len = MC_HEADER_SIZE + body_len;

    int counted = (cmd != CB_CMD_MGET_ENTRY && cmd != CB_CMD_MGETS_ENTRY);

    /* Check if we can send immediately */
    int can_send = self->connected &&
        (self->max_pending <= 0 || self->pending_count < self->max_pending || !counted);

    if (can_send) {
        buf_ensure_write(self, packet_len);
        mc_pack(self->wbuf + self->wbuf_len, opcode,
                key, (uint16_t)key_len, value, (uint32_t)value_len,
                extras, extras_len, opaque, cas);
        self->wbuf_len += packet_len;

        ev_mc_cb_t *cbt = alloc_cbt();
        if (cb) { cbt->cb = newSVsv(cb); }
        cbt->opaque = opaque;
        cbt->cmd = cmd;
        cbt->quiet = quiet;
        cbt->counted = counted;
        if (cmd == CB_CMD_STATS) {
            cbt->stats_hv = newHV();
        }
        ngx_queue_insert_tail(&self->cb_queue, &cbt->queue);
        if (counted) self->pending_count++;

        arm_cmd_timer(self);
        start_writing(self);
    } else {
        /* Queue for later */
        ev_mc_wait_t *wt;
        Newxz(wt, 1, ev_mc_wait_t);
        Newx(wt->packet, packet_len, char);
        wt->packet_len = packet_len;
        mc_pack(wt->packet, opcode,
                key, (uint16_t)key_len, value, (uint32_t)value_len,
                extras, extras_len, opaque, cas);

        if (cb) { wt->cb = newSVsv(cb); }
        wt->opaque = opaque;
        wt->cmd = cmd;
        wt->quiet = quiet;
        wt->counted = counted;
        wt->queued_at = ev_now(self->loop);
        if (cmd == CB_CMD_STATS) {
            wt->stats_hv = newHV();
        }

        ngx_queue_insert_tail(&self->wait_queue, &wt->queue);
        self->waiting_count++;

        if (self->waiting_timeout_ms > 0)
            schedule_waiting_timer(self);
    }

    return opaque;
}

/* ================================================================
 * Multi-get: GETKQ + NOOP fence
 * ================================================================ */

/* full_info: 0 = mget (key=>value), 1 = mgets (key=>{value,flags,cas}) */
static void mc_enqueue_mget(pTHX_ ev_mc_t *self, AV *keys_av, SV *cb, int full_info) {
    SSize_t count = av_len(keys_av) + 1;
    if (count <= 0) {
        if (cb) {
            HV *hv = newHV();
            self->callback_depth++;
            invoke_cb(aTHX_ self, cb, newRV_noinc((SV*)hv), NULL);
            self->callback_depth--;
            check_destroyed(self);
        }
        return;
    }

    int entry_cmd = full_info ? CB_CMD_MGETS_ENTRY : CB_CMD_MGET_ENTRY;
    int fence_cmd = full_info ? CB_CMD_MGETS_FENCE : CB_CMD_MGET_FENCE;

    SSize_t i;

    /* Pre-validate all key lengths before mutating wbuf / queues / refcounts.
       Croaking mid-loop would leave half-built GETKQ packets queued without
       a NOOP fence, corrupting opaque ordering on the wire. */
    for (i = 0; i < count; i++) {
        SV **sv = av_fetch(keys_av, i, 0);
        if (!sv || !SvOK(*sv)) continue;
        STRLEN key_len;
        (void)SvPV(*sv, key_len);
        if (key_len > MC_MAX_KEY_LEN)
            croak("mget key too long (%d bytes, max %d)", (int)key_len, MC_MAX_KEY_LEN);
    }

    HV *results = newHV();

    for (i = 0; i < count; i++) {
        SV **sv = av_fetch(keys_av, i, 0);
        if (!sv || !SvOK(*sv)) continue;

        STRLEN key_len;
        const char *key = SvPV(*sv, key_len);

        uint32_t opaque = mc_next_opaque(self);
        uint32_t body_len = (uint32_t)key_len;
        size_t packet_len = MC_HEADER_SIZE + body_len;

        int can_send = self->connected;

        if (can_send) {
            buf_ensure_write(self, packet_len);
            char *p = self->wbuf + self->wbuf_len;
            mc_encode_header(p, MC_OP_GETKQ, (uint16_t)key_len, 0, body_len, opaque, 0);
            memcpy(p + MC_HEADER_SIZE, key, key_len);
            self->wbuf_len += packet_len;

            ev_mc_cb_t *cbt = alloc_cbt();
            cbt->opaque = opaque;
            cbt->cmd = entry_cmd;
            cbt->quiet = 1;
            cbt->counted = 0;
            cbt->mget_results = results;
            ngx_queue_insert_tail(&self->cb_queue, &cbt->queue);
        } else {
            ev_mc_wait_t *wt;
            Newxz(wt, 1, ev_mc_wait_t);
            Newx(wt->packet, packet_len, char);
            wt->packet_len = packet_len;
            mc_encode_header(wt->packet, MC_OP_GETKQ, (uint16_t)key_len, 0, body_len, opaque, 0);
            memcpy(wt->packet + MC_HEADER_SIZE, key, key_len);
            wt->opaque = opaque;
            wt->cmd = entry_cmd;
            wt->quiet = 1;
            wt->counted = 0;
            wt->mget_results = results;
            wt->queued_at = ev_now(self->loop);
            ngx_queue_insert_tail(&self->wait_queue, &wt->queue);
            self->waiting_count++;
        }
    }

    /* NOOP fence */
    {
        uint32_t opaque = mc_next_opaque(self);
        size_t packet_len = MC_HEADER_SIZE;
        int can_send = self->connected;

        if (can_send) {
            buf_ensure_write(self, packet_len);
            char *p = self->wbuf + self->wbuf_len;
            mc_encode_header(p, MC_OP_NOOP, 0, 0, 0, opaque, 0);
            self->wbuf_len += packet_len;

            ev_mc_cb_t *cbt = alloc_cbt();
            if (cb) { cbt->cb = newSVsv(cb); }
            cbt->opaque = opaque;
            cbt->cmd = fence_cmd;
            cbt->quiet = 0;
            cbt->counted = 1;
            cbt->mget_results = results;
            SvREFCNT_inc_simple_void_NN((SV*)results);
            ngx_queue_insert_tail(&self->cb_queue, &cbt->queue);
            self->pending_count++;

            arm_cmd_timer(self);
            start_writing(self);
        } else {
            ev_mc_wait_t *wt;
            Newxz(wt, 1, ev_mc_wait_t);
            Newx(wt->packet, packet_len, char);
            wt->packet_len = packet_len;
            mc_encode_header(wt->packet, MC_OP_NOOP, 0, 0, 0, opaque, 0);
            if (cb) { wt->cb = newSVsv(cb); }
            wt->opaque = opaque;
            wt->cmd = fence_cmd;
            wt->quiet = 0;
            wt->counted = 1;
            wt->mget_results = results; /* owned ref */
            SvREFCNT_inc_simple_void_NN((SV*)results);
            wt->queued_at = ev_now(self->loop);
            ngx_queue_insert_tail(&self->wait_queue, &wt->queue);
            self->waiting_count++;
        }
    }

    /* results starts with refcnt=1, fence owns +1 = total 2.
     * Drop our initial ref, fence now owns it (refcnt=1) */
    SvREFCNT_dec((SV*)results);

    if (self->waiting_timeout_ms > 0)
        schedule_waiting_timer(self);
}

/* ================================================================
 * Response processing
 * ================================================================ */

/* Drain quiet entries before the given opaque.
 * Quiet entries that got no response are "quiet success":
 * - MGET_ENTRY: miss (nothing to do)
 * - Other quiet commands: invoke callback with success */
static void drain_quiet_before(pTHX_ ev_mc_t *self, uint32_t opaque) {
    while (!ngx_queue_empty(&self->cb_queue)) {
        ngx_queue_t *q = ngx_queue_head(&self->cb_queue);
        ev_mc_cb_t *cbt = ngx_queue_data(q, ev_mc_cb_t, queue);

        /* Use signed comparison to handle wraparound */
        if ((int32_t)(cbt->opaque - opaque) >= 0) break;
        if (!cbt->quiet) break; /* non-quiet should always get response */

        ngx_queue_remove(q);
        if (cbt->counted) self->pending_count--;

        /* Quiet success: for storage = stored, for MGET_ENTRY = miss */
        if (cbt->cb && !cbt->skipped &&
            cbt->cmd != CB_CMD_MGET_ENTRY && cbt->cmd != CB_CMD_MGETS_ENTRY) {
            invoke_cb(aTHX_ self, cbt->cb, newSViv(1), NULL);
            if (self->magic == MC_MAGIC_FREED) {
                cleanup_cbt(aTHX_ cbt);
                return;
            }
        }
        cleanup_cbt(aTHX_ cbt);
    }
}

static void handle_response_packet(pTHX_ ev_mc_t *self) {
    const char *pkt = self->rbuf;
    uint16_t key_len = mc_read_u16(pkt + 2);
    uint8_t extras_len = (uint8_t)pkt[4];
    uint16_t status = mc_read_u16(pkt + 6);
    uint32_t body_len = mc_read_u32(pkt + 8);
    uint32_t opaque = mc_read_u32(pkt + 12);
    uint64_t cas = mc_read_u64(pkt + 16);

    const char *body = pkt + MC_HEADER_SIZE;

    if ((uint32_t)extras_len + key_len > body_len) {
        handle_disconnect(aTHX_ self, "malformed response: body too short");
        return;
    }

    const char *extras = body;
    const char *key_ptr = body + extras_len;
    const char *value_ptr = body + extras_len + key_len;
    uint32_t value_len = body_len - extras_len - key_len;

    /* Drain quiet entries that were skipped (no response) */
    drain_quiet_before(aTHX_ self, opaque);
    if (self->magic == MC_MAGIC_FREED) return;

    /* Find matching callback entry */
    if (ngx_queue_empty(&self->cb_queue)) {
        /* Stray response (e.g., quiet opcode error) — discard */
        return;
    }

    ngx_queue_t *q = ngx_queue_head(&self->cb_queue);
    ev_mc_cb_t *cbt = ngx_queue_data(q, ev_mc_cb_t, queue);

    if (cbt->opaque != opaque) {
        /* opaque=0 is fire-and-forget error response — discard silently */
        if (opaque == 0) return;
        char errbuf[128];
        snprintf(errbuf, sizeof(errbuf),
            "protocol error: expected opaque %u, got %u", cbt->opaque, opaque);
        handle_disconnect(aTHX_ self, errbuf);
        return;
    }

    /* STAT accumulation: don't remove from queue until terminator */
    if (cbt->cmd == CB_CMD_STATS && status == MC_STATUS_OK && key_len > 0) {
        if (cbt->stats_hv) {
            hv_store(cbt->stats_hv, key_ptr, key_len,
                     newSVpvn(value_ptr, value_len), 0);
        }
        return; /* wait for more stats or terminator */
    }

    /* Remove from queue */
    ngx_queue_remove(q);
    if (cbt->counted) self->pending_count--;

    /* Handle error status */
    if (status != MC_STATUS_OK) {
        /* GET/GETS/GAT/GATS miss: return (undef, undef) */
        if (status == MC_STATUS_KEY_NOT_FOUND &&
            (cbt->cmd == CB_CMD_GET || cbt->cmd == CB_CMD_GETS ||
             cbt->cmd == CB_CMD_GAT || cbt->cmd == CB_CMD_GATS)) {
            if (cbt->cb && !cbt->skipped)
                invoke_cb(aTHX_ self, cbt->cb, NULL, NULL);
        }
        else if (cbt->cmd == CB_CMD_MGET_ENTRY || cbt->cmd == CB_CMD_MGETS_ENTRY) {
            /* mget miss — nothing to add */
        }
        /* SASL auth failure: disconnect (auto-auth) or report to callback */
        else if (cbt->cmd == CB_CMD_SASL_AUTH) {
            if (cbt->cb && !cbt->skipped) {
                const char *errstr = mc_status_str(status);
                if (value_len > 0)
                    invoke_cb(aTHX_ self, cbt->cb, NULL,
                        newSVpvf("%s: %.*s", errstr, (int)value_len, value_ptr));
                else
                    invoke_cb(aTHX_ self, cbt->cb, NULL, newSVpv(errstr, 0));
            } else if (!cbt->cb) {
                /* Auto-auth failed — disconnect with error */
                char errbuf[256];
                if (value_len > 0)
                    snprintf(errbuf, sizeof(errbuf), "SASL auth failed: %.*s",
                             (int)value_len, value_ptr);
                else
                    snprintf(errbuf, sizeof(errbuf), "SASL auth failed: %s",
                             mc_status_str(status));
                cleanup_cbt(aTHX_ cbt);
                handle_disconnect(aTHX_ self, errbuf);
                return;
            }
        }
        else {
            /* Real error */
            if (cbt->cb && !cbt->skipped) {
                const char *errstr = mc_status_str(status);
                /* Include server error message if present */
                if (value_len > 0)
                    invoke_cb(aTHX_ self, cbt->cb, NULL,
                        newSVpvf("%s: %.*s", errstr, (int)value_len, value_ptr));
                else
                    invoke_cb(aTHX_ self, cbt->cb, NULL, newSVpv(errstr, 0));
            }
        }
        if (self->magic != MC_MAGIC_FREED) {
            cleanup_cbt(aTHX_ cbt);
            send_next_waiting(aTHX_ self);
        } else {
            cleanup_cbt(aTHX_ cbt);
        }
        return;
    }

    /* Handle success */
    if (cbt->skipped) {
        cleanup_cbt(aTHX_ cbt);
        send_next_waiting(aTHX_ self);
        return;
    }

    switch (cbt->cmd) {
    case CB_CMD_GET:
    case CB_CMD_GAT:
        if (cbt->cb)
            invoke_cb(aTHX_ self, cbt->cb, newSVpvn(value_ptr, value_len), NULL);
        break;

    case CB_CMD_GETS:
    case CB_CMD_GATS:
        if (cbt->cb) {
            HV *hv = newHV();
            hv_stores(hv, "value", newSVpvn(value_ptr, value_len));
            if (extras_len >= 4)
                hv_stores(hv, "flags", newSVuv(mc_read_u32(extras)));
            hv_stores(hv, "cas", newSVuv(cas));
            invoke_cb(aTHX_ self, cbt->cb, newRV_noinc((SV*)hv), NULL);
        }
        break;

    case CB_CMD_STORE:
    case CB_CMD_DELETE:
    case CB_CMD_TOUCH:
    case CB_CMD_FLUSH:
    case CB_CMD_NOOP:
    case CB_CMD_QUIT:
        if (cbt->cb)
            invoke_cb(aTHX_ self, cbt->cb, newSViv(1), NULL);
        break;

    case CB_CMD_ARITH:
        if (cbt->cb) {
            uint64_t new_val = mc_read_u64(value_ptr);
            invoke_cb(aTHX_ self, cbt->cb, newSVuv((UV)new_val), NULL);
        }
        break;

    case CB_CMD_VERSION:
    case CB_CMD_SASL_LIST:
        if (cbt->cb)
            invoke_cb(aTHX_ self, cbt->cb, newSVpvn(value_ptr, value_len), NULL);
        break;

    case CB_CMD_SASL_AUTH:
        if (cbt->cb)
            invoke_cb(aTHX_ self, cbt->cb, newSViv(1), NULL);
        /* Auto-auth (cb==NULL): wait queue is drained by the common
           send_next_waiting call at the end of this switch. */
        break;

    case CB_CMD_STATS:
        /* Terminator (key_len==0): deliver accumulated stats */
        if (cbt->cb && cbt->stats_hv) {
            SV *rv = newRV_noinc((SV*)cbt->stats_hv);
            cbt->stats_hv = NULL; /* transferred ownership */
            invoke_cb(aTHX_ self, cbt->cb, rv, NULL);
        }
        break;

    case CB_CMD_MGET_ENTRY:
        if (cbt->mget_results && key_len > 0) {
            hv_store(cbt->mget_results, key_ptr, key_len,
                     newSVpvn(value_ptr, value_len), 0);
        }
        break;

    case CB_CMD_MGETS_ENTRY:
        if (cbt->mget_results && key_len > 0) {
            HV *info = newHV();
            hv_stores(info, "value", newSVpvn(value_ptr, value_len));
            if (extras_len >= 4)
                hv_stores(info, "flags", newSVuv(mc_read_u32(extras)));
            hv_stores(info, "cas", newSVuv(cas));
            hv_store(cbt->mget_results, key_ptr, key_len,
                     newRV_noinc((SV*)info), 0);
        }
        break;

    case CB_CMD_MGET_FENCE:
    case CB_CMD_MGETS_FENCE:
        if (cbt->cb && cbt->mget_results) {
            SV *rv = newRV_noinc((SV*)cbt->mget_results);
            cbt->mget_results = NULL;
            invoke_cb(aTHX_ self, cbt->cb, rv, NULL);
        }
        break;
    }

    if (self->magic != MC_MAGIC_FREED) {
        cleanup_cbt(aTHX_ cbt);
        send_next_waiting(aTHX_ self);
    } else {
        cleanup_cbt(aTHX_ cbt);
    }
}

static void process_responses(pTHX_ ev_mc_t *self) {
    int processed = 0;
    while (self->rbuf_len >= MC_HEADER_SIZE) {
        /* Verify magic byte */
        if ((uint8_t)self->rbuf[0] != MC_RES_MAGIC) {
            handle_disconnect(aTHX_ self, "invalid response magic byte");
            return;
        }

        uint32_t body_len = mc_read_u32(self->rbuf + 8);
        /* Sanity bound: memcached's hard limit is 128 MB; cap at 256 MB to
           catch garbage/MITM responses without rejecting any real reply.
           Also avoids size_t overflow on 32-bit perls when MC_HEADER_SIZE
           is added below. */
        if (body_len > 0x10000000u) {
            handle_disconnect(aTHX_ self, "response body too large");
            return;
        }
        size_t total_len = (size_t)MC_HEADER_SIZE + body_len;

        if (self->rbuf_len < total_len) break; /* incomplete packet */

        handle_response_packet(aTHX_ self);
        if (self->magic == MC_MAGIC_FREED) return;
        if (!self->connected) return; /* disconnect() called from callback */

        /* Consume from buffer */
        self->rbuf_len -= total_len;
        if (self->rbuf_len > 0)
            memmove(self->rbuf, self->rbuf + total_len, self->rbuf_len);
        processed++;
    }

    /* Reset command timeout on activity */
    if (processed > 0 && self->cmd_timer_active) {
        if (ngx_queue_empty(&self->cb_queue))
            disarm_cmd_timer(self);
        else
            arm_cmd_timer(self);
    }
}

/* ================================================================
 * IO callbacks
 * ================================================================ */

static void on_readable(pTHX_ ev_mc_t *self) {
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

static int try_write(ev_mc_t *self) {
    while (self->wbuf_off < self->wbuf_len) {
        ssize_t n = write(self->fd, self->wbuf + self->wbuf_off,
                          self->wbuf_len - self->wbuf_off);
        if (n > 0) {
            self->wbuf_off += n;
        } else if (n < 0) {
            if (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR)
                return 0; /* try again later */
            return -1; /* error */
        }
    }
    /* All written */
    self->wbuf_len = 0;
    self->wbuf_off = 0;
    stop_writing(self);
    return 1;
}

static void on_connect_complete(pTHX_ ev_mc_t *self) {
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
    ev_mc_t *self = (ev_mc_t *)w->data;
    (void)loop;

    if (self->magic != MC_MAGIC_ALIVE) return;

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
        if (self->magic != MC_MAGIC_ALIVE) {
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
 * Connection
 * ================================================================ */

static void start_connect(pTHX_ ev_mc_t *self) {
    int fd, ret;

    if (self->path) {
        /* Unix socket */
        struct sockaddr_un addr;
        memset(&addr, 0, sizeof(addr));
        addr.sun_family = AF_UNIX;
        if (strlen(self->path) >= sizeof(addr.sun_path)) {
            emit_error(aTHX_ self, "unix socket path too long");
            return;
        }
        strncpy(addr.sun_path, self->path, sizeof(addr.sun_path) - 1);

        fd = socket(AF_UNIX, SOCK_STREAM, 0);
        if (fd < 0) {
            char errbuf[128];
            snprintf(errbuf, sizeof(errbuf), "socket: %s", strerror(errno));
            emit_error(aTHX_ self, errbuf);
            return;
        }

        /* non-blocking */
        {
            int fl = fcntl(fd, F_GETFL);
            if (fl < 0 || fcntl(fd, F_SETFL, fl | O_NONBLOCK) < 0) {
                close(fd);
                emit_error(aTHX_ self, "fcntl O_NONBLOCK failed");
                return;
            }
        }

        self->fd = fd;
        ret = connect(fd, (struct sockaddr *)&addr, sizeof(addr));
    } else {
        /* TCP */
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

        fd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
        if (fd < 0) {
            freeaddrinfo(res);
            char errbuf[128];
            snprintf(errbuf, sizeof(errbuf), "socket: %s", strerror(errno));
            report_connect_error(aTHX_ self, errbuf);
            return;
        }

        /* non-blocking */
        {
            int fl = fcntl(fd, F_GETFL);
            if (fl < 0 || fcntl(fd, F_SETFL, fl | O_NONBLOCK) < 0) {
                freeaddrinfo(res);
                close(fd);
                emit_error(aTHX_ self, "fcntl O_NONBLOCK failed");
                return;
            }
        }

        /* TCP_NODELAY */
        {
            int one = 1;
            setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &one, sizeof(one));
        }

        self->fd = fd;
        ret = connect(fd, res->ai_addr, res->ai_addrlen);
        freeaddrinfo(res);
    }

    if (ret == 0) {
        /* Connected immediately (localhost) */
        self->connected = 1;
        ev_io_init(&self->rio, io_cb, self->fd, EV_READ);
        self->rio.data = (void *)self;
        ev_io_init(&self->wio, io_cb, self->fd, EV_WRITE);
        self->wio.data = (void *)self;
        ev_set_priority(&self->rio, self->priority);
        ev_set_priority(&self->wio, self->priority);

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

    /* In progress - wait for writability */
    self->connecting = 1;
    ev_io_init(&self->rio, io_cb, self->fd, EV_READ);
    self->rio.data = (void *)self;
    ev_io_init(&self->wio, io_cb, self->fd, EV_WRITE);
    self->wio.data = (void *)self;
    ev_set_priority(&self->rio, self->priority);
    ev_set_priority(&self->wio, self->priority);
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
 * XS interface
 * ================================================================ */

MODULE = EV::Memcached  PACKAGE = EV::Memcached

BOOT:
{
    I_EV_API("EV::Memcached");
    err_skipped = newSVpvs("skipped");
    SvREADONLY_on(err_skipped);
    err_disconnected = newSVpvs("disconnected");
    SvREADONLY_on(err_disconnected);
    err_waiting_timeout = newSVpvs("waiting timeout");
    SvREADONLY_on(err_waiting_timeout);
}

EV::Memcached
new(char *class, ...)
CODE:
{
    PERL_UNUSED_VAR(class);
    if ((items - 1) % 2 != 0) croak("odd number of arguments");

    Newxz(RETVAL, 1, ev_mc_t);
    RETVAL->magic = MC_MAGIC_ALIVE;
    RETVAL->fd = -1;
    RETVAL->port = 11211;
    RETVAL->next_opaque = 1; /* reserve 0 for fire-and-forget quiet ops */
    ngx_queue_init(&RETVAL->cb_queue);
    ngx_queue_init(&RETVAL->wait_queue);
    Newx(RETVAL->rbuf, BUF_INIT_SIZE, char);
    RETVAL->rbuf_cap = BUF_INIT_SIZE;
    Newx(RETVAL->wbuf, BUF_INIT_SIZE, char);
    RETVAL->wbuf_cap = BUF_INIT_SIZE;

    /* Default error handler: warn. Callback exceptions are caught by
       G_EVAL in emit_error, so a `die` would be demoted to a warning
       anyway — emit it directly and avoid the double prefix. */
    RETVAL->on_error = eval_pv("sub { warn \"EV::Memcached error: @_\\n\" }", TRUE);
    SvREFCNT_inc_simple_void_NN(RETVAL->on_error);

    /* Parse options */
    SV *host_sv = NULL, *path_sv = NULL;
    int port = 11211;
    int do_reconnect = 0, reconnect_delay = 1000, max_reconnect_attempts = 0;
    RETVAL->loop = EV_DEFAULT;
    int i;

    for (i = 1; i < items; i += 2) {
        const char *k = SvPV_nolen(ST(i));
        SV *v = ST(i + 1);

        if (strEQ(k, "host"))                        host_sv = v;
        else if (strEQ(k, "port"))                   port = SvIV(v);
        else if (strEQ(k, "path"))                   path_sv = v;
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
        else if (strEQ(k, "max_pending"))            RETVAL->max_pending = SvIV(v);
        else if (strEQ(k, "waiting_timeout"))        RETVAL->waiting_timeout_ms = SvIV(v);
        else if (strEQ(k, "connect_timeout"))        RETVAL->connect_timeout_ms = SvIV(v);
        else if (strEQ(k, "command_timeout"))        RETVAL->command_timeout_ms = SvIV(v);
        else if (strEQ(k, "resume_waiting_on_reconnect")) RETVAL->resume_waiting_on_reconnect = SvTRUE(v) ? 1 : 0;
        else if (strEQ(k, "priority"))               RETVAL->priority = SvIV(v);
        else if (strEQ(k, "keepalive"))              RETVAL->keepalive = SvIV(v);
        else if (strEQ(k, "reconnect"))              do_reconnect = SvTRUE(v) ? 1 : 0;
        else if (strEQ(k, "reconnect_delay"))        reconnect_delay = SvIV(v);
        else if (strEQ(k, "max_reconnect_attempts")) max_reconnect_attempts = SvIV(v);
        else if (strEQ(k, "username")) {
            if (SvOK(v)) RETVAL->username = savepv(SvPV_nolen(v));
        }
        else if (strEQ(k, "password")) {
            if (SvOK(v)) RETVAL->password = savepv(SvPV_nolen(v));
        }
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
        if (RETVAL->username) Safefree(RETVAL->username);
        if (RETVAL->password) Safefree(RETVAL->password);
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
    }
    else if (path_sv && SvOK(path_sv)) {
        RETVAL->path = savepv(SvPV_nolen(path_sv));
        start_connect(aTHX_ RETVAL);
    }
}
OUTPUT:
    RETVAL

void
DESTROY(EV::Memcached self)
CODE:
{
    if (self->magic == MC_MAGIC_FREED) return;

    /* If we're inside a callback, defer destruction.
     * check_destroyed() in io_cb/timer_cb will Safefree after unwind. */
    if (self->callback_depth > 0) {
        self->magic = MC_MAGIC_FREED;

        /* Stop watchers */
        stop_reading(self);
        stop_writing(self);
        stop_connect_timer(self);
        disarm_cmd_timer(self);
        stop_reconnect_timer(self);
        stop_waiting_timer(self);
        if (self->fd >= 0) { close(self->fd); self->fd = -1; }

        /* Clean up queues without invoking Perl callbacks */
        while (!ngx_queue_empty(&self->cb_queue)) {
            ngx_queue_t *q = ngx_queue_head(&self->cb_queue);
            ev_mc_cb_t *cbt = ngx_queue_data(q, ev_mc_cb_t, queue);
            ngx_queue_remove(q);
            cleanup_cbt(aTHX_ cbt);
        }
        while (!ngx_queue_empty(&self->wait_queue)) {
            ngx_queue_t *q = ngx_queue_head(&self->wait_queue);
            ev_mc_wait_t *wt = ngx_queue_data(q, ev_mc_wait_t, queue);
            ngx_queue_remove(q);
            cleanup_wait(aTHX_ wt);
        }
        self->pending_count = 0;
        self->waiting_count = 0;

        CLEAR_HANDLER(self->on_error);
        CLEAR_HANDLER(self->on_connect);
        CLEAR_HANDLER(self->on_disconnect);
        Safefree(self->host);     self->host = NULL;
        Safefree(self->path);     self->path = NULL;
        Safefree(self->username); self->username = NULL;
        Safefree(self->password); self->password = NULL;
        Safefree(self->rbuf);     self->rbuf = NULL;
        Safefree(self->wbuf);     self->wbuf = NULL;
        return;
    }

    /* Stop timers */
    stop_connect_timer(self);
    disarm_cmd_timer(self);
    stop_reconnect_timer(self);
    stop_waiting_timer(self);

    cleanup_connection(aTHX_ self);

    /* Cancel pending/waiting with disconnected error.
       Don't pre-set magic=FREED here: cancel_pending_impl bails its
       loop on FREED, which would leak every entry past the first if
       any callback was set. Bump callback_depth so any nested DESTROY
       (e.g. a callback drops a separate strong ref) takes the deferred
       path at the top of this function. */
    if (!PL_dirty) {
        self->callback_depth++;
        cancel_pending(aTHX_ self, err_disconnected);
        cancel_waiting(aTHX_ self, err_disconnected);
        self->callback_depth--;
    } else {
        /* Global destruction: free entries without calling Perl */
        while (!ngx_queue_empty(&self->cb_queue)) {
            ngx_queue_t *q = ngx_queue_head(&self->cb_queue);
            ev_mc_cb_t *cbt = ngx_queue_data(q, ev_mc_cb_t, queue);
            ngx_queue_remove(q);
            cleanup_cbt(aTHX_ cbt);
        }
        while (!ngx_queue_empty(&self->wait_queue)) {
            ngx_queue_t *q = ngx_queue_head(&self->wait_queue);
            ev_mc_wait_t *wt = ngx_queue_data(q, ev_mc_wait_t, queue);
            ngx_queue_remove(q);
            cleanup_wait(aTHX_ wt);
        }
    }

    self->magic = MC_MAGIC_FREED;

    CLEAR_HANDLER(self->on_error);
    CLEAR_HANDLER(self->on_connect);
    CLEAR_HANDLER(self->on_disconnect);

    Safefree(self->host);
    Safefree(self->path);
    Safefree(self->username);
    Safefree(self->password);
    Safefree(self->rbuf);
    Safefree(self->wbuf);

    Safefree(self);
}

void
connect(EV::Memcached self, const char *host, int port = 11211)
CODE:
{
    if (self->connected || self->connecting)
        croak("already connected");

    /* An auto-reconnect timer may be pending; cancel it to avoid a
       second start_connect when the timer fires. */
    stop_reconnect_timer(self);

    Safefree(self->host);
    self->host = savepv(host);
    self->port = port;
    Safefree(self->path); self->path = NULL;
    self->intentional_disconnect = 0;

    start_connect(aTHX_ self);
}

void
connect_unix(EV::Memcached self, const char *path)
CODE:
{
    if (self->connected || self->connecting)
        croak("already connected");

    stop_reconnect_timer(self);

    Safefree(self->path);
    self->path = savepv(path);
    Safefree(self->host); self->host = NULL;
    self->intentional_disconnect = 0;

    start_connect(aTHX_ self);
}

void
disconnect(EV::Memcached self)
CODE:
{
    self->intentional_disconnect = 1;

    stop_reconnect_timer(self);

    /* Pin the object across pending-callback dispatch so that an
       `undef $mc` from a callback defers DESTROY rather than freeing
       us mid-call; check_destroyed below handles the deferred free. */
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
is_connected(EV::Memcached self)
CODE:
    RETVAL = self->connected || self->connecting;
OUTPUT:
    RETVAL

SV *
on_error(EV::Memcached self, ...)
CODE:
{
    if (items > 1) {
        CLEAR_HANDLER(self->on_error);
        if (SvOK(ST(1)) && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVCV) {
            self->on_error = newSVsv(ST(1));
        }
    }
    RETVAL = self->on_error ? newSVsv(self->on_error) : &PL_sv_undef;
}
OUTPUT:
    RETVAL

SV *
on_connect(EV::Memcached self, ...)
CODE:
{
    if (items > 1) {
        CLEAR_HANDLER(self->on_connect);
        if (SvOK(ST(1)) && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVCV) {
            self->on_connect = newSVsv(ST(1));
        }
    }
    RETVAL = self->on_connect ? newSVsv(self->on_connect) : &PL_sv_undef;
}
OUTPUT:
    RETVAL

SV *
on_disconnect(EV::Memcached self, ...)
CODE:
{
    if (items > 1) {
        CLEAR_HANDLER(self->on_disconnect);
        if (SvOK(ST(1)) && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVCV) {
            self->on_disconnect = newSVsv(ST(1));
        }
    }
    RETVAL = self->on_disconnect ? newSVsv(self->on_disconnect) : &PL_sv_undef;
}
OUTPUT:
    RETVAL

void
set(EV::Memcached self, SV *key_sv, SV *value_sv, ...)
ALIAS:
    add = 1
    replace = 2
CODE:
{
    static const uint8_t opcodes[] = { MC_OP_SET, MC_OP_ADD, MC_OP_REPLACE };
    MC_CROAK_UNLESS_CONNECTED(self);

    STRLEN key_len, value_len;
    const char *key = SvPV(key_sv, key_len);
    const char *value = SvPV(value_sv, value_len);

    int extra = items - 3;
    SV *cb = NULL;
    if (extra > 0 && SvROK(ST(items-1)) && SvTYPE(SvRV(ST(items-1))) == SVt_PVCV) {
        cb = ST(items-1);
        extra--;
    }
    UV expiry = extra > 0 ? SvUV(ST(3)) : 0;
    UV flags  = extra > 1 ? SvUV(ST(4)) : 0;

    char extras[8];
    mc_write_u32(extras, (uint32_t)flags);
    mc_write_u32(extras + 4, (uint32_t)expiry);

    /* SET fire-and-forget uses SETQ (quiet) — server suppresses response.
     * ADD/REPLACE can fail, so they always use normal opcodes. */
    if (!cb && ix == 0) {
        mc_fire_and_forget(aTHX_ self, MC_OP_SETQ, key, key_len, value, value_len,
                           extras, 8, 0);
    } else {
        mc_enqueue_cmd(aTHX_ self, opcodes[ix], key, key_len, value, value_len,
                       extras, 8, 0, CB_CMD_STORE, 0, cb);
    }
}

void
cas(EV::Memcached self, SV *key_sv, SV *value_sv, SV *cas_sv, ...)
CODE:
{
    MC_CROAK_UNLESS_CONNECTED(self);

    STRLEN key_len, value_len;
    const char *key = SvPV(key_sv, key_len);
    const char *value = SvPV(value_sv, value_len);
    uint64_t cas_val = SvUV(cas_sv);

    int extra = items - 4;
    SV *cb = NULL;
    if (extra > 0 && SvROK(ST(items-1)) && SvTYPE(SvRV(ST(items-1))) == SVt_PVCV) {
        cb = ST(items-1);
        extra--;
    }
    UV expiry = extra > 0 ? SvUV(ST(4)) : 0;
    UV flags  = extra > 1 ? SvUV(ST(5)) : 0;

    char extras[8];
    mc_write_u32(extras, (uint32_t)flags);
    mc_write_u32(extras + 4, (uint32_t)expiry);

    mc_enqueue_cmd(aTHX_ self, MC_OP_SET, key, key_len, value, value_len,
                   extras, 8, cas_val, CB_CMD_STORE, 0, cb);
}

void
get(EV::Memcached self, SV *key_sv, SV *cb_sv = &PL_sv_undef)
ALIAS:
    gets = 1
CODE:
{
    MC_CROAK_UNLESS_CONNECTED(self);

    STRLEN key_len;
    const char *key = SvPV(key_sv, key_len);
    SV *cb = (SvOK(cb_sv) && SvROK(cb_sv)) ? cb_sv : NULL;

    mc_enqueue_cmd(aTHX_ self, MC_OP_GET, key, key_len, NULL, 0,
                   NULL, 0, 0, ix == 0 ? CB_CMD_GET : CB_CMD_GETS, 0, cb);
}

void
delete(EV::Memcached self, SV *key_sv, SV *cb_sv = &PL_sv_undef)
CODE:
{
    MC_CROAK_UNLESS_CONNECTED(self);

    STRLEN key_len;
    const char *key = SvPV(key_sv, key_len);
    SV *cb = (SvOK(cb_sv) && SvROK(cb_sv)) ? cb_sv : NULL;

    mc_enqueue_cmd(aTHX_ self, MC_OP_DELETE, key, key_len, NULL, 0,
                   NULL, 0, 0, CB_CMD_DELETE, 0, cb);
}

void
incr(EV::Memcached self, SV *key_sv, ...)
ALIAS:
    decr = 1
CODE:
{
    MC_CROAK_UNLESS_CONNECTED(self);

    STRLEN key_len;
    const char *key = SvPV(key_sv, key_len);

    int extra = items - 2;
    SV *cb = NULL;
    if (extra > 0 && SvROK(ST(items-1)) && SvTYPE(SvRV(ST(items-1))) == SVt_PVCV) {
        cb = ST(items-1);
        extra--;
    }
    UV delta   = extra > 0 ? SvUV(ST(2)) : 1;
    UV initial = extra > 1 ? SvUV(ST(3)) : 0;
    UV expiry  = extra > 2 ? SvUV(ST(4)) : 0xFFFFFFFF;

    char extras[20];
    mc_write_u64(extras, (uint64_t)delta);
    mc_write_u64(extras + 8, (uint64_t)initial);
    mc_write_u32(extras + 16, (uint32_t)expiry);

    mc_enqueue_cmd(aTHX_ self, ix == 0 ? MC_OP_INCR : MC_OP_DECR,
                   key, key_len, NULL, 0, extras, 20, 0, CB_CMD_ARITH, 0, cb);
}

void
append(EV::Memcached self, SV *key_sv, SV *value_sv, SV *cb_sv = &PL_sv_undef)
ALIAS:
    prepend = 1
CODE:
{
    MC_CROAK_UNLESS_CONNECTED(self);

    STRLEN key_len, value_len;
    const char *key = SvPV(key_sv, key_len);
    const char *value = SvPV(value_sv, value_len);
    SV *cb = (SvOK(cb_sv) && SvROK(cb_sv)) ? cb_sv : NULL;

    mc_enqueue_cmd(aTHX_ self, ix == 0 ? MC_OP_APPEND : MC_OP_PREPEND,
                   key, key_len, value, value_len, NULL, 0, 0, CB_CMD_STORE, 0, cb);
}

void
touch(EV::Memcached self, SV *key_sv, UV expiry, SV *cb_sv = &PL_sv_undef)
ALIAS:
    gat = 1
    gats = 2
CODE:
{
    MC_CROAK_UNLESS_CONNECTED(self);

    STRLEN key_len;
    const char *key = SvPV(key_sv, key_len);
    SV *cb = (SvOK(cb_sv) && SvROK(cb_sv)) ? cb_sv : NULL;

    char extras[4];
    mc_write_u32(extras, (uint32_t)expiry);

    static const int cmds[]    = { CB_CMD_TOUCH, CB_CMD_GAT, CB_CMD_GATS };
    static const uint8_t ops[] = { MC_OP_TOUCH, MC_OP_GAT, MC_OP_GAT };

    mc_enqueue_cmd(aTHX_ self, ops[ix], key, key_len, NULL, 0,
                   extras, 4, 0, cmds[ix], 0, cb);
}

void
flush(EV::Memcached self, ...)
CODE:
{
    MC_CROAK_UNLESS_CONNECTED(self);

    int extra = items - 1;
    SV *cb = NULL;
    if (extra > 0 && SvROK(ST(items-1)) && SvTYPE(SvRV(ST(items-1))) == SVt_PVCV) {
        cb = ST(items-1);
        extra--;
    }
    UV expiry = extra > 0 ? SvUV(ST(1)) : 0;

    char extras[4];
    const char *xp = NULL;
    uint8_t xl = 0;
    if (expiry > 0) {
        mc_write_u32(extras, (uint32_t)expiry);
        xp = extras;
        xl = 4;
    }

    if (cb)
        mc_enqueue_cmd(aTHX_ self, MC_OP_FLUSH, NULL, 0, NULL, 0,
                       xp, xl, 0, CB_CMD_FLUSH, 0, cb);
    else
        mc_fire_and_forget(aTHX_ self, MC_OP_FLUSHQ, NULL, 0, NULL, 0,
                           xp, xl, 0);
}

void
version(EV::Memcached self, SV *cb_sv = &PL_sv_undef)
ALIAS:
    noop = 1
    quit = 2
CODE:
{
    MC_CROAK_UNLESS_CONNECTED(self);

    SV *cb = (SvOK(cb_sv) && SvROK(cb_sv)) ? cb_sv : NULL;

    static const uint8_t ops[] = { MC_OP_VERSION, MC_OP_NOOP, MC_OP_QUIT };
    static const int cmds[]    = { CB_CMD_VERSION, CB_CMD_NOOP, CB_CMD_QUIT };

    mc_enqueue_cmd(aTHX_ self, ops[ix], NULL, 0, NULL, 0,
                   NULL, 0, 0, cmds[ix], 0, cb);
}

void
stats(EV::Memcached self, ...)
CODE:
{
    MC_CROAK_UNLESS_CONNECTED(self);

    int extra = items - 1;
    SV *cb = NULL;
    if (extra > 0 && SvROK(ST(items-1)) && SvTYPE(SvRV(ST(items-1))) == SVt_PVCV) {
        cb = ST(items-1);
        extra--;
    }

    STRLEN name_len = 0;
    const char *name = NULL;
    if (extra > 0 && SvOK(ST(1))) {
        name = SvPV(ST(1), name_len);
    }

    mc_enqueue_cmd(aTHX_ self, MC_OP_STAT, name, name_len, NULL, 0,
                   NULL, 0, 0, CB_CMD_STATS, 0, cb);
}

void
mget(EV::Memcached self, SV *keys_sv, SV *cb_sv = &PL_sv_undef)
ALIAS:
    mgets = 1
CODE:
{
    MC_CROAK_UNLESS_CONNECTED(self);

    if (!SvROK(keys_sv) || SvTYPE(SvRV(keys_sv)) != SVt_PVAV)
        croak("mget requires an array reference");

    SV *cb = (SvOK(cb_sv) && SvROK(cb_sv)) ? cb_sv : NULL;
    AV *keys_av = (AV *)SvRV(keys_sv);

    mc_enqueue_mget(aTHX_ self, keys_av, cb, ix);
}

void
sasl_auth(EV::Memcached self, SV *user_sv, SV *pass_sv, SV *cb_sv = &PL_sv_undef)
CODE:
{
    MC_CROAK_UNLESS_CONNECTED(self);

    STRLEN ulen, plen;
    const char *user = SvPV(user_sv, ulen);
    const char *pass = SvPV(pass_sv, plen);
    SV *cb = (SvOK(cb_sv) && SvROK(cb_sv)) ? cb_sv : NULL;

    size_t vlen = 1 + ulen + 1 + plen;
    char *authdata;
    Newx(authdata, vlen, char);
    authdata[0] = '\0';
    memcpy(authdata + 1, user, ulen);
    authdata[1 + ulen] = '\0';
    memcpy(authdata + 2 + ulen, pass, plen);

    mc_enqueue_cmd(aTHX_ self, MC_OP_SASL_AUTH, "PLAIN", 5, authdata, vlen,
                   NULL, 0, 0, CB_CMD_SASL_AUTH, 0, cb);
    Safefree(authdata);
}

void
sasl_list_mechs(EV::Memcached self, SV *cb_sv = &PL_sv_undef)
CODE:
{
    MC_CROAK_UNLESS_CONNECTED(self);

    SV *cb = (SvOK(cb_sv) && SvROK(cb_sv)) ? cb_sv : NULL;

    mc_enqueue_cmd(aTHX_ self, MC_OP_SASL_LIST_MECHS, NULL, 0, NULL, 0,
                   NULL, 0, 0, CB_CMD_SASL_LIST, 0, cb);
}

int
pending_count(EV::Memcached self)
CODE:
    RETVAL = self->pending_count;
OUTPUT:
    RETVAL

int
waiting_count(EV::Memcached self)
CODE:
    RETVAL = self->waiting_count;
OUTPUT:
    RETVAL

int
max_pending(EV::Memcached self, ...)
CODE:
{
    if (items > 1) {
        int old = self->max_pending;
        self->max_pending = SvIV(ST(1));
        if (self->max_pending < 0) self->max_pending = 0;
        /* If limit increased, drain waiting queue */
        if (self->connected && self->max_pending > old)
            send_next_waiting(aTHX_ self);
    }
    RETVAL = self->max_pending;
}
OUTPUT:
    RETVAL

int
waiting_timeout(EV::Memcached self, ...)
CODE:
{
    if (items > 1) {
        self->waiting_timeout_ms = SvIV(ST(1));
        if (self->waiting_timeout_ms < 0) self->waiting_timeout_ms = 0;
    }
    RETVAL = self->waiting_timeout_ms;
}
OUTPUT:
    RETVAL

int
resume_waiting_on_reconnect(EV::Memcached self, ...)
CODE:
{
    if (items > 1) {
        self->resume_waiting_on_reconnect = SvTRUE(ST(1)) ? 1 : 0;
    }
    RETVAL = self->resume_waiting_on_reconnect;
}
OUTPUT:
    RETVAL

int
connect_timeout(EV::Memcached self, ...)
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
command_timeout(EV::Memcached self, ...)
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
reconnect(EV::Memcached self, int enable, int delay_ms = 1000, int max_attempts = 0)
CODE:
{
    self->reconnect = enable ? 1 : 0;
    self->reconnect_delay_ms = delay_ms >= 0 ? delay_ms : 0;
    self->max_reconnect_attempts = max_attempts >= 0 ? max_attempts : 0;
    if (!enable) {
        self->reconnect_attempts = 0;
        stop_reconnect_timer(self);
    }
}

int
reconnect_enabled(EV::Memcached self)
CODE:
    RETVAL = self->reconnect;
OUTPUT:
    RETVAL

int
priority(EV::Memcached self, ...)
CODE:
{
    if (items > 1) {
        self->priority = SvIV(ST(1));
        if (self->priority < -2) self->priority = -2;
        if (self->priority > 2) self->priority = 2;
        /* Apply to active watchers */
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
keepalive(EV::Memcached self, ...)
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

void
skip_pending(EV::Memcached self)
CODE:
{
    self->callback_depth++;
    cancel_pending_impl(aTHX_ self, err_skipped, 1);
    self->callback_depth--;
    check_destroyed(self);
}

void
skip_waiting(EV::Memcached self)
CODE:
{
    self->callback_depth++;
    cancel_waiting(aTHX_ self, err_skipped);
    self->callback_depth--;
    check_destroyed(self);
}
