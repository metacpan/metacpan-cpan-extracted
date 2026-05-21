#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "EVAPI.h"

#include "hiredis.h"
#include "async.h"
#include "libev_adapter.h"
#include "ngx-queue.h"

#ifdef EV_REDIS_SSL
#include "hiredis_ssl.h"
#endif

typedef struct ev_redis_s ev_redis_t;
typedef struct ev_redis_cb_s ev_redis_cb_t;
typedef struct ev_redis_wait_s ev_redis_wait_t;

typedef ev_redis_t* EV__Redis;
typedef struct ev_loop* EV__Loop;

#define EV_REDIS_MAGIC 0xDEADBEEF
#define EV_REDIS_FREED 0xFEEDFACE

#define CLEAR_HANDLER(field) \
    do { if (NULL != (field)) { SvREFCNT_dec(field); (field) = NULL; } } while(0)

struct ev_redis_s {
    unsigned int magic;  /* Set to EV_REDIS_MAGIC when alive */
    struct ev_loop* loop;
    redisAsyncContext* ac;
    SV* error_handler;
    SV* connect_handler;
    SV* disconnect_handler;
    SV* push_handler;
    struct timeval* connect_timeout;
    struct timeval* command_timeout;
    ngx_queue_t cb_queue;
    ngx_queue_t wait_queue;
    int pending_count;
    int waiting_count;
    int max_pending; /* 0 = unlimited */
    ev_redis_cb_t* current_cb; /* callback currently executing */
    int resume_waiting_on_reconnect; /* keep waiting queue on disconnect */
    int waiting_timeout_ms; /* max ms in waiting queue, 0 = unlimited */
    ev_timer waiting_timer;
    int waiting_timer_active;

    /* Reconnect settings */
    char* host;
    int port;
    char* path;
    int reconnect;              /* 0 = disabled, 1 = enabled */
    int reconnect_delay_ms;     /* delay between reconnect attempts */
    int max_reconnect_attempts; /* 0 = unlimited */
    int reconnect_attempts;     /* current attempt count */
    ev_timer reconnect_timer;
    int reconnect_timer_active;
    int intentional_disconnect; /* set before explicit disconnect() */
    int priority; /* libev watcher priority, default 0 */
    int in_cb_cleanup; /* prevent re-entrant cb_queue modification */
    int in_wait_cleanup; /* prevent re-entrant wait_queue modification */
    int callback_depth; /* nesting depth of C-level callbacks invoking Perl code */
    int keepalive; /* TCP keepalive interval in seconds, 0 = disabled */
    int prefer_ipv4; /* prefer IPv4 DNS resolution */
    int prefer_ipv6; /* prefer IPv6 DNS resolution */
    char* source_addr; /* local address to bind to */
    unsigned int tcp_user_timeout; /* TCP_USER_TIMEOUT in ms, 0 = OS default */
    int cloexec; /* set SOCK_CLOEXEC on socket */
    int reuseaddr; /* set SO_REUSEADDR on socket */
    redisAsyncContext* ac_saved; /* saved ac pointer for deferred disconnect cleanup */
#ifdef EV_REDIS_SSL
    redisSSLContext* ssl_ctx;
#endif
};

struct ev_redis_cb_s {
    SV* cb;
    ngx_queue_t queue;
    int persist;
    int skipped;
    int sub_count; /* subscription channels remaining (for persistent commands) */
};

struct ev_redis_wait_s {
    char** argv;
    size_t* argvlen;
    int argc;
    SV* cb;
    int persist;
    ngx_queue_t queue;
    ev_tstamp queued_at;
};

/* Shared error strings (initialized in BOOT) */
static SV* err_skipped = NULL;
static SV* err_waiting_timeout = NULL;
static SV* err_disconnected = NULL;

/* Check for unsubscribe-family commands. These are persistent (stay in cb_queue)
 * but hiredis ignores their callbacks — replies go through the subscribe callback. */
static int is_unsubscribe_command(const char* cmd) {
    char c = cmd[0];
    if (c == 'u' || c == 'U') return (0 == strcasecmp(cmd, "unsubscribe"));
    if (c == 'p' || c == 'P') return (0 == strcasecmp(cmd, "punsubscribe"));
    if (c == 's' || c == 'S') return (0 == strcasecmp(cmd, "sunsubscribe"));
    return 0;
}

static int is_persistent_command(const char* cmd) {
    char c = cmd[0];

    if (c == 's' || c == 'S') {
        if (0 == strcasecmp(cmd, "subscribe")) return 1;
        if (0 == strcasecmp(cmd, "ssubscribe")) return 1;
        if (0 == strcasecmp(cmd, "sunsubscribe")) return 1;
        return 0;
    }
    if (c == 'u' || c == 'U') {
        return (0 == strcasecmp(cmd, "unsubscribe"));
    }
    if (c == 'p' || c == 'P') {
        if (0 == strcasecmp(cmd, "psubscribe")) return 1;
        if (0 == strcasecmp(cmd, "punsubscribe")) return 1;
        return 0;
    }
    if (c == 'm' || c == 'M') {
        return (0 == strcasecmp(cmd, "monitor"));
    }

    return 0;
}

/* Detect unsubscribe-type replies that indicate end of a subscription channel.
 * Format: [type_string, channel, remaining_count]
 * Returns 1 if the reply is an unsubscribe/punsubscribe/sunsubscribe message. */
static int is_unsub_reply(redisReply* reply) {
    const char* s;

    if (reply->type != REDIS_REPLY_ARRAY && reply->type != REDIS_REPLY_PUSH) return 0;
    if (reply->elements < 3) return 0;
    if (NULL == reply->element[0]) return 0;
    if (reply->element[0]->type != REDIS_REPLY_STRING &&
        reply->element[0]->type != REDIS_REPLY_STATUS) return 0;

    s = reply->element[0]->str;
    if (s[0] == 'u' || s[0] == 'U') return (0 == strcasecmp(s, "unsubscribe"));
    if (s[0] == 'p' || s[0] == 'P') return (0 == strcasecmp(s, "punsubscribe"));
    if (s[0] == 's' || s[0] == 'S') return (0 == strcasecmp(s, "sunsubscribe"));
    return 0;
}

static void emit_error(EV__Redis self, SV* error) {
    if (NULL == self->error_handler) return;

    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(error);
    PUTBACK;

    call_sv(self->error_handler, G_DISCARD | G_EVAL);
    if (SvTRUE(ERRSV)) {
        warn("EV::Redis: exception in error handler: %s", SvPV_nolen(ERRSV));
    }

    FREETMPS;
    LEAVE;
}

static void emit_error_str(EV__Redis self, const char* error) {
    if (NULL == self->error_handler) return;
    emit_error(self, sv_2mortal(newSVpv(error, 0)));
}

static void invoke_callback_error(SV* cb, SV* error_sv) {
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(&PL_sv_undef);
    PUSHs(error_sv);
    PUTBACK;
    call_sv(cb, G_DISCARD | G_EVAL);
    if (SvTRUE(ERRSV)) {
        warn("EV::Redis: exception in command callback: %s", SvPV_nolen(ERRSV));
    }
    FREETMPS;
    LEAVE;
}

/* Check if DESTROY was called during a callback and deferred Safefree.
 * Call after decrementing callback_depth. Returns 1 if self was freed
 * (caller MUST NOT access self afterward). */
static int check_destroyed(EV__Redis self) {
    if (self->magic == EV_REDIS_FREED &&
        self->callback_depth == 0 &&
        self->current_cb == NULL) {
        Safefree(self);
        return 1;
    }
    return 0;
}

/* Free C-allocated fields (used by both PL_dirty and normal DESTROY paths) */
static void free_c_fields(EV__Redis self) {
    if (NULL != self->host) { Safefree(self->host); self->host = NULL; }
    if (NULL != self->path) { Safefree(self->path); self->path = NULL; }
    if (NULL != self->source_addr) { Safefree(self->source_addr); self->source_addr = NULL; }
    if (NULL != self->connect_timeout) { Safefree(self->connect_timeout); self->connect_timeout = NULL; }
    if (NULL != self->command_timeout) { Safefree(self->command_timeout); self->command_timeout = NULL; }
#ifdef EV_REDIS_SSL
    if (NULL != self->ssl_ctx) { redisFreeSSLContext(self->ssl_ctx); self->ssl_ctx = NULL; }
#endif
}

static void stop_waiting_timer(EV__Redis self) {
    if (self->waiting_timer_active && NULL != self->loop && !PL_dirty) {
        ev_timer_stop(self->loop, &self->waiting_timer);
        self->waiting_timer_active = 0;
    }
}

static void stop_reconnect_timer(EV__Redis self) {
    if (self->reconnect_timer_active && NULL != self->loop && !PL_dirty) {
        ev_timer_stop(self->loop, &self->reconnect_timer);
        self->reconnect_timer_active = 0;
    }
}

/* Maximum timeout: ~23 days (fits safely in 32-bit calculations) */
#define MAX_TIMEOUT_MS 2000000000

static void validate_timeout_ms(IV ms, const char* name) {
    if (ms < 0) croak("%s must be non-negative", name);
    if (ms > MAX_TIMEOUT_MS) croak("%s too large (max %d ms)", name, MAX_TIMEOUT_MS);
}

static SV* timeout_accessor(struct timeval** tv_ptr, SV* timeout_ms, const char* name) {
    if (NULL != timeout_ms && SvOK(timeout_ms)) {
        IV ms = SvIV(timeout_ms);
        validate_timeout_ms(ms, name);
        if (NULL == *tv_ptr) {
            Newx(*tv_ptr, 1, struct timeval);
        }
        (*tv_ptr)->tv_sec = (long)(ms / 1000);
        (*tv_ptr)->tv_usec = (long)((ms % 1000) * 1000);
    }

    if (NULL != *tv_ptr) {
        return newSViv((IV)(*tv_ptr)->tv_sec * 1000 + (*tv_ptr)->tv_usec / 1000);
    }
    return &PL_sv_undef;
}

/* Helper to set/clear a callback handler field.
 * If called without handler (items == 1), clears the handler.
 * If called with handler, sets it (or clears if handler is undef/not CODE).
 * Returns the current handler (with refcount incremented) or undef. */
static SV* handler_accessor(SV** handler_ptr, SV* handler, int has_handler_arg) {
    /* Clear existing handler first - both no-arg calls and set calls clear first */
    if (NULL != *handler_ptr) {
        SvREFCNT_dec(*handler_ptr);
        *handler_ptr = NULL;
    }

    /* If a handler argument was provided and it's a valid CODE ref, set it */
    if (has_handler_arg && NULL != handler && SvOK(handler) && SvROK(handler) &&
        SvTYPE(SvRV(handler)) == SVt_PVCV) {
        *handler_ptr = SvREFCNT_inc(handler);
    }

    return (NULL != *handler_ptr)
        ? SvREFCNT_inc(*handler_ptr)
        : &PL_sv_undef;
}

/* Uses in_cb_cleanup flag to prevent re-entrant queue modification from
 * user callbacks (e.g., if callback calls skip_pending). */
static void remove_cb_queue_sv(EV__Redis self, SV* error_sv) {
    ngx_queue_t* q;
    ev_redis_cb_t* cbt;

    if (self->in_cb_cleanup) {
        return;
    }

    self->in_cb_cleanup = 1;

    /* Use while loop with re-fetch of head each iteration.
     * This is safe against re-entrant modifications because we
     * re-check the queue state after each callback invocation. */
    while (!ngx_queue_empty(&self->cb_queue)) {
        q = ngx_queue_head(&self->cb_queue);
        cbt = ngx_queue_data(q, ev_redis_cb_t, queue);

        if (cbt == self->current_cb) {
            /* Skip current_cb - it is owned by an in-flight reply_cb. */
            if (ngx_queue_next(q) == ngx_queue_sentinel(&self->cb_queue)) {
                break;
            }
            q = ngx_queue_next(q);
            cbt = ngx_queue_data(q, ev_redis_cb_t, queue);
        }

        ngx_queue_remove(q);
        if (!cbt->persist) self->pending_count--;

        if (NULL != cbt->cb) {
            if (NULL != error_sv) {
                invoke_callback_error(cbt->cb, error_sv);
            }
            SvREFCNT_dec(cbt->cb);
        }
        Safefree(cbt);
    }

    self->in_cb_cleanup = 0;
}

static void free_wait_entry(ev_redis_wait_t* wt) {
    int i;
    for (i = 0; i < wt->argc; i++) {
        Safefree(wt->argv[i]);
    }
    Safefree(wt->argv);
    Safefree(wt->argvlen);
    if (NULL != wt->cb) {
        SvREFCNT_dec(wt->cb);
    }
    Safefree(wt);
}

/* Uses in_wait_cleanup flag to prevent re-entrant queue modification. */
static void clear_wait_queue_sv(EV__Redis self, SV* error_sv) {
    ngx_queue_t* q;
    ev_redis_wait_t* wt;

    if (self->in_wait_cleanup) {
        return;
    }

    /* Protect against re-entrancy: if a callback invokes skip_waiting() or
     * skip_pending(), they should no-op since we're already clearing. */
    self->in_wait_cleanup = 1;

    while (!ngx_queue_empty(&self->wait_queue)) {
        q = ngx_queue_head(&self->wait_queue);
        wt = ngx_queue_data(q, ev_redis_wait_t, queue);
        ngx_queue_remove(q);
        self->waiting_count--;

        if (NULL != error_sv && NULL != wt->cb) {
            invoke_callback_error(wt->cb, error_sv);
        }

        free_wait_entry(wt);
    }

    self->in_wait_cleanup = 0;
}

/* Forward declarations */
static void pre_connect_common(EV__Redis self, redisOptions* opts);
static int  post_connect_setup(EV__Redis self, const char* err_prefix);
static void do_reconnect(EV__Redis self);
static void send_next_waiting(EV__Redis self);
static void schedule_waiting_timer(EV__Redis self);
static void expire_waiting_commands(EV__Redis self);
static void schedule_reconnect(EV__Redis self);
static void EV__redis_connect_cb(redisAsyncContext* c, int status);
static void EV__redis_disconnect_cb(const redisAsyncContext* c, int status);
static void EV__redis_push_cb(redisAsyncContext* ac, void* reply_ptr);
static SV* EV__redis_decode_reply(redisReply* reply);
/* Recursion limit for nested array/map/set replies. Bounds C-stack growth
 * when decoding maliciously deep replies from an untrusted server. */
#define EV_REDIS_MAX_REPLY_DEPTH 512
static SV* decode_reply_depth(redisReply* reply, int depth);

static void clear_connection_params(EV__Redis self) {
    if (NULL != self->host) { Safefree(self->host); self->host = NULL; }
    if (NULL != self->path) { Safefree(self->path); self->path = NULL; }
}

static void reconnect_timer_cb(EV_P_ ev_timer* w, int revents) {
    EV__Redis self = (EV__Redis)w->data;

    (void)loop;
    (void)revents;

    if (NULL == self || self->magic != EV_REDIS_MAGIC) return;

    self->reconnect_timer_active = 0;
    self->callback_depth++;
    do_reconnect(self);
    self->callback_depth--;
    if (check_destroyed(self)) return;
}

static void schedule_reconnect(EV__Redis self) {
    ev_tstamp delay;

    if (!self->reconnect) return;
    if (self->intentional_disconnect) return;
    if (NULL == self->loop) return;
    stop_reconnect_timer(self);
    if (self->max_reconnect_attempts > 0 &&
        self->reconnect_attempts >= self->max_reconnect_attempts) {
        /* Clear waiting queue that was preserved for reconnect - reconnect has
         * permanently failed, so these commands will never be sent. */
        clear_wait_queue_sv(self, sv_2mortal(newSVpv("reconnect error: max attempts reached", 0)));
        stop_waiting_timer(self);
        emit_error_str(self, "reconnect error: max attempts reached");
        return;
    }

    self->reconnect_attempts++;
    delay = self->reconnect_delay_ms / 1000.0;

    ev_timer_init(&self->reconnect_timer, reconnect_timer_cb, delay, 0);
    self->reconnect_timer.data = (void*)self;
    ev_timer_start(self->loop, &self->reconnect_timer);
    self->reconnect_timer_active = 1;
}

/* Expire waiting commands that have exceeded waiting_timeout.
 * Uses head-refetch iteration pattern which is safe against re-entrant
 * queue modification (e.g., if a callback calls skip_waiting). */
static void expire_waiting_commands(EV__Redis self) {
    ngx_queue_t* q;
    ev_redis_wait_t* wt;
    ev_tstamp now;
    ev_tstamp timeout;

    now = ev_now(self->loop);
    /* Capture timeout at start - callbacks may modify self->waiting_timeout_ms
     * and we need consistent behavior for the entire batch. */
    timeout = self->waiting_timeout_ms / 1000.0;

    /* Use while loop with re-fetch of head each iteration.
     * This is safe against re-entrant modifications. */
    while (!ngx_queue_empty(&self->wait_queue)) {
        q = ngx_queue_head(&self->wait_queue);
        wt = ngx_queue_data(q, ev_redis_wait_t, queue);

        if (now - wt->queued_at >= timeout) {
            ngx_queue_remove(q);
            self->waiting_count--;

            if (NULL != wt->cb) {
                invoke_callback_error(wt->cb, err_waiting_timeout);
            }

            free_wait_entry(wt);
        }
        else {
            /* Queue is FIFO with monotonically increasing queued_at times.
             * If this entry hasn't expired, neither have any following entries. */
            break;
        }
    }
}

static void waiting_timer_cb(EV_P_ ev_timer* w, int revents) {
    EV__Redis self = (EV__Redis)w->data;

    (void)loop;
    (void)revents;

    if (NULL == self || self->magic != EV_REDIS_MAGIC) return;

    self->waiting_timer_active = 0;
    self->callback_depth++;
    expire_waiting_commands(self);
    schedule_waiting_timer(self);
    self->callback_depth--;
    if (check_destroyed(self)) return;
}

static void schedule_waiting_timer(EV__Redis self) {
    ngx_queue_t* q;
    ev_redis_wait_t* wt;
    ev_tstamp now, expires_at, delay;

    /* Use helper which includes NULL loop check */
    stop_waiting_timer(self);

    if (NULL == self->loop) return;
    if (self->waiting_timeout_ms <= 0) return;
    if (ngx_queue_empty(&self->wait_queue)) return;

    q = ngx_queue_head(&self->wait_queue);
    wt = ngx_queue_data(q, ev_redis_wait_t, queue);

    now = ev_now(self->loop);
    expires_at = wt->queued_at + self->waiting_timeout_ms / 1000.0;
    delay = expires_at - now;
    if (delay < 0) delay = 0;

    ev_timer_init(&self->waiting_timer, waiting_timer_cb, delay, 0);
    self->waiting_timer.data = (void*)self;
    ev_timer_start(self->loop, &self->waiting_timer);
    self->waiting_timer_active = 1;
}

static void do_reconnect(EV__Redis self) {
    redisOptions opts;
    memset(&opts, 0, sizeof(opts));

    if (NULL == self->loop) {
        /* Object is being destroyed */
        return;
    }

    if (NULL != self->ac) {
        /* Already connected or connecting */
        return;
    }

    self->intentional_disconnect = 0;
    pre_connect_common(self, &opts);

    if (NULL != self->path) {
        REDIS_OPTIONS_SET_UNIX(&opts, self->path);
    }
    else if (NULL != self->host) {
        REDIS_OPTIONS_SET_TCP(&opts, self->host, self->port);
    }
    else {
        emit_error_str(self, "reconnect error: no connection parameters");
        return;
    }

    self->ac = redisAsyncConnectWithOptions(&opts);
    if (NULL == self->ac) {
        emit_error_str(self, "reconnect error: cannot allocate memory");
        schedule_reconnect(self);
        return;
    }

    if (REDIS_OK != post_connect_setup(self, "reconnect error")) {
        schedule_reconnect(self);
        return;
    }
}

static void EV__redis_connect_cb(redisAsyncContext* c, int status) {
    EV__Redis self = (EV__Redis)c->data;

    if (NULL == self || self->magic != EV_REDIS_MAGIC) return;

    self->callback_depth++;

    if (REDIS_OK != status) {
        self->ac = NULL;
        emit_error_str(self, c->errstr[0] ? c->errstr : "connect failed");
        if (!self->reconnect || !self->resume_waiting_on_reconnect
                || self->intentional_disconnect) {
            clear_wait_queue_sv(self, sv_2mortal(newSVpv(
                c->errstr[0] ? c->errstr : "connect failed", 0)));
            stop_waiting_timer(self);
        }
        schedule_reconnect(self);
    }
    else {
        self->reconnect_attempts = 0;

        if (NULL != self->connect_handler) {
            dSP;

            ENTER;
            SAVETMPS;

            PUSHMARK(SP);
            PUTBACK;

            call_sv(self->connect_handler, G_DISCARD | G_EVAL);
            if (SvTRUE(ERRSV)) {
                warn("EV::Redis: exception in connect handler: %s", SvPV_nolen(ERRSV));
            }

            FREETMPS;
            LEAVE;
        }

        send_next_waiting(self);
    }

    self->callback_depth--;
    check_destroyed(self);
}

static void EV__redis_disconnect_cb(const redisAsyncContext* c, int status) {
    EV__Redis self = (EV__Redis)c->data;
    SV* error_sv;
    int should_reconnect = 0;
    int was_intentional;
    int will_reconnect;

    if (NULL == self || self->magic != EV_REDIS_MAGIC) return;

    /* Stale disconnect callback: user already established a new connection
     * (e.g., called disconnect() then connect() before the old deferred
     * disconnect fired). Old pending callbacks were already processed by
     * reply_cb. Skip all cleanup to avoid clobbering the new connection.
     * Clear ac_saved if it points to this old context to prevent dangling. */
    if (self->ac != NULL && self->ac != c) {
        if (self->ac_saved == c) self->ac_saved = NULL;
        return;
    }

    was_intentional = self->intentional_disconnect;
    self->intentional_disconnect = 0;

    self->ac = NULL;
    self->ac_saved = NULL; /* disconnect callback fired normally */
    self->callback_depth++;

    if (REDIS_OK == status) {
        error_sv = err_disconnected;
    }
    else {
        error_sv = sv_2mortal(newSVpv(
            c->errstr[0] ? c->errstr : "disconnected", 0));
        emit_error_str(self, c->errstr[0] ? c->errstr : "disconnected");
        if (!was_intentional) {
            should_reconnect = 1;
        }
    }

    if (NULL != self->disconnect_handler) {
        dSP;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        PUTBACK;

        call_sv(self->disconnect_handler, G_DISCARD | G_EVAL);
        if (SvTRUE(ERRSV)) {
            warn("EV::Redis: exception in disconnect handler: %s", SvPV_nolen(ERRSV));
        }

        FREETMPS;
        LEAVE;

        /* Re-check: user's handler might have called connect() or reconnect()
         * establishing a new ac. If so, skip clearing cb_queue to avoid
         * freeing new commands; still honour resume_waiting_on_reconnect=0
         * by clearing the old wait queue (its entries belong to the prior
         * connection, not the new one). ac_saved is already handled or NULL. */
        if (self->ac != NULL && self->ac != c) {
            if (!self->resume_waiting_on_reconnect) {
                clear_wait_queue_sv(self, error_sv);
                stop_waiting_timer(self);
            }
            self->callback_depth--;
            check_destroyed(self);
            return;
        }
    }

    remove_cb_queue_sv(self, error_sv);

    will_reconnect = should_reconnect && !self->intentional_disconnect && self->reconnect;
    if (!self->resume_waiting_on_reconnect || was_intentional || !will_reconnect) {
        clear_wait_queue_sv(self, error_sv);
        stop_waiting_timer(self);
    }

    if (will_reconnect) {
        schedule_reconnect(self);
    }

    self->callback_depth--;
    check_destroyed(self);
}

static void EV__redis_push_cb(redisAsyncContext* ac, void* reply_ptr) {
    EV__Redis self = (EV__Redis)ac->data;
    redisReply* reply = (redisReply*)reply_ptr;

    if (NULL == self || self->magic != EV_REDIS_MAGIC) return;
    if (NULL == self->push_handler || NULL == reply) return;

    self->callback_depth++;

    {
        dSP;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        XPUSHs(sv_2mortal(EV__redis_decode_reply(reply)));
        PUTBACK;

        call_sv(self->push_handler, G_DISCARD | G_EVAL);
        if (SvTRUE(ERRSV)) {
            warn("EV::Redis: exception in push handler: %s", SvPV_nolen(ERRSV));
        }

        FREETMPS;
        LEAVE;
    }

    self->callback_depth--;
    check_destroyed(self);
}

static void pre_connect_common(EV__Redis self, redisOptions* opts) {
    if (NULL != self->connect_timeout) {
        opts->connect_timeout = self->connect_timeout;
    }
    if (NULL != self->command_timeout) {
        opts->command_timeout = self->command_timeout;
    }
    if (self->prefer_ipv4) {
        opts->options |= REDIS_OPT_PREFER_IPV4;
    }
    else if (self->prefer_ipv6) {
        opts->options |= REDIS_OPT_PREFER_IPV6;
    }
    if (self->cloexec) {
        opts->options |= REDIS_OPT_SET_SOCK_CLOEXEC;
    }
    if (self->reuseaddr) {
        opts->options |= REDIS_OPT_REUSEADDR;
    }
    if (NULL != self->source_addr && NULL == self->path) {
        opts->endpoint.tcp.source_addr = self->source_addr;
    }
}

/* Set up a newly allocated redisAsyncContext: SSL, keepalive, libev, callbacks.
 * On failure: frees ac, nulls self->ac, emits error with err_prefix. */
static int post_connect_setup(EV__Redis self, const char* err_prefix) {
    self->ac_saved = NULL;
    self->ac->data = (void*)self;

#ifdef EV_REDIS_SSL
    if (NULL != self->ssl_ctx) {
        if (REDIS_OK != redisInitiateSSLWithContext(&self->ac->c, self->ssl_ctx)) {
            SV* err = sv_2mortal(newSVpvf("%s: SSL initiation failed: %s",
                err_prefix, self->ac->errstr[0] ? self->ac->errstr : "unknown error"));
            redisAsyncFree(self->ac);
            self->ac = NULL;
            emit_error(self, err);
            return REDIS_ERR;
        }
    }
#endif

    if (self->keepalive > 0) {
        redisEnableKeepAliveWithInterval(&self->ac->c, self->keepalive);
    }
    if (self->tcp_user_timeout > 0) {
        redisSetTcpUserTimeout(&self->ac->c, self->tcp_user_timeout);
    }

    if (REDIS_OK != redisLibevAttach(self->loop, self->ac)) {
        SV* err = sv_2mortal(newSVpvf("%s: cannot attach libev", err_prefix));
        redisAsyncFree(self->ac);
        self->ac = NULL;
        emit_error(self, err);
        return REDIS_ERR;
    }

    if (self->priority != 0) {
        redisLibevSetPriority(self->ac, self->priority);
    }

    redisAsyncSetConnectCallbackNC(self->ac, EV__redis_connect_cb);
    redisAsyncSetDisconnectCallback(self->ac, EV__redis_disconnect_cb);
    if (NULL != self->push_handler) {
        redisAsyncSetPushCallback(self->ac, EV__redis_push_cb);
    }

    if (self->ac->err) {
        SV* err = sv_2mortal(newSVpvf("%s: %s", err_prefix, self->ac->errstr));
        redisAsyncFree(self->ac);
        self->ac = NULL;
        emit_error(self, err);
        return REDIS_ERR;
    }

    return REDIS_OK;
}

static SV* decode_reply_depth(redisReply* reply, int depth) {
    SV* res;

    switch (reply->type) {
        case REDIS_REPLY_STRING:
        case REDIS_REPLY_ERROR:
        case REDIS_REPLY_STATUS:
        case REDIS_REPLY_BIGNUM:
        case REDIS_REPLY_VERB:
            res = newSVpvn(reply->str, reply->len);
            break;

        case REDIS_REPLY_INTEGER:
            res = newSViv(reply->integer);
            break;

        case REDIS_REPLY_DOUBLE:
            res = newSVnv(reply->dval);
            break;

        case REDIS_REPLY_BOOL:
            res = newSViv(reply->integer ? 1 : 0);
            break;

        case REDIS_REPLY_NIL:
            res = newSV(0);
            break;

        case REDIS_REPLY_ARRAY:
        case REDIS_REPLY_MAP:
        case REDIS_REPLY_SET:
        case REDIS_REPLY_ATTR:
        case REDIS_REPLY_PUSH: {
            AV* av = newAV();
            size_t i;
            if (depth >= EV_REDIS_MAX_REPLY_DEPTH) {
                /* Stop recursing: an empty array placeholder bounds C-stack
                 * usage against a hostile server replying with deep nesting. */
                res = newRV_noinc((SV*)av);
                break;
            }
            if (reply->elements > 0) {
                av_extend(av, (SSize_t)(reply->elements - 1));
                for (i = 0; i < reply->elements; i++) {
                    if (NULL != reply->element[i]) {
                        av_push(av, decode_reply_depth(reply->element[i], depth + 1));
                    }
                    else {
                        av_push(av, newSV(0));
                    }
                }
            }
            res = newRV_noinc((SV*)av);
            break;
        }

        default:
            res = newSV(0);
            break;
    }

    return res;
}

static SV* EV__redis_decode_reply(redisReply* reply) {
    return decode_reply_depth(reply, 0);
}

static void EV__redis_reply_cb(redisAsyncContext* c, void* reply, void* privdata) {
    EV__Redis self = (EV__Redis)c->data;
    ev_redis_cb_t* cbt;
    SV* sv_reply;
    SV* sv_err;

    cbt = (ev_redis_cb_t*)privdata;

    if (cbt->skipped) {
        if (!cbt->persist || NULL == reply) {
            /* Multi-channel persistent: hiredis fires once per channel with
             * same cbt. Decrement sub_count, free only on last call. */
            if (cbt->persist && NULL == reply && cbt->sub_count > 1) {
                cbt->sub_count--;
                return;
            }
            Safefree(cbt);
        }
        else if (cbt->persist && reply != NULL && is_unsub_reply((redisReply*)reply)) {
            cbt->sub_count--;
            if (cbt->sub_count <= 0) {
                Safefree(cbt);
            }
        }
        return;
    }

    /* self is NULL when DESTROY nulled ac->data (deferred free inside
     * REDIS_IN_CALLBACK) or during PL_dirty. Still invoke the callback
     * with a disconnect error so users can clean up resources. The hiredis
     * context (c) is still alive here — safe to read c->errstr.
     * cb may be NULL during PL_dirty where we pre-null it.
     * For persistent commands (multi-channel subscribe), hiredis fires
     * reply_cb once per channel with the same cbt. Invoke the callback
     * only once (null cb after), use sub_count to track when to free. */
    if (self == NULL) {
        if (NULL != cbt->cb) {
            invoke_callback_error(cbt->cb,
                sv_2mortal(newSVpv(c->errstr[0] ? c->errstr : "disconnected", 0)));
            SvREFCNT_dec(cbt->cb);
            cbt->cb = NULL;
        }
        if (cbt->persist && reply == NULL && cbt->sub_count > 1) {
            cbt->sub_count--;
            return;
        }
        Safefree(cbt);
        return;
    }

    /* If self is marked as freed (during DESTROY), we still invoke the
     * callback with an error, but skip any self->field access afterward.
     * For persistent commands, don't free cbt here — leave it in the queue
     * for remove_cb_queue_sv to clean up after redisAsyncFree returns. */
    if (self->magic == EV_REDIS_FREED) {
        if (NULL != cbt->cb) {
            self->callback_depth++;
            invoke_callback_error(cbt->cb, sv_2mortal(newSVpv(c->errstr[0] ? c->errstr : "disconnected", 0)));
            self->callback_depth--;
            SvREFCNT_dec(cbt->cb);
            cbt->cb = NULL;
        }
        if (!cbt->persist) {
            ngx_queue_remove(&cbt->queue);
            Safefree(cbt);
        }
        check_destroyed(self);
        return;
    }

    /* Unknown magic - memory corruption, skip.
     * Don't touch queue pointers (self's memory may be garbage).
     * Always decrement refcount since callback will never be invoked again. */
    if (self->magic != EV_REDIS_MAGIC) {
        if (NULL != cbt->cb) SvREFCNT_dec(cbt->cb);
        Safefree(cbt);
        return;
    }

    self->current_cb = cbt;
    self->callback_depth++;

    if (NULL != cbt->cb) {
        if (NULL == reply) {
            sv_err = sv_2mortal(newSVpv(
                c->errstr[0] ? c->errstr : "disconnected", 0));
            invoke_callback_error(cbt->cb, sv_err);
        }
        else {
            dSP;

            ENTER;
            SAVETMPS;

            PUSHMARK(SP);
            EXTEND(SP, 2);
            sv_reply = sv_2mortal(EV__redis_decode_reply((redisReply*)reply));
            if (((redisReply*)reply)->type == REDIS_REPLY_ERROR) {
                PUSHs(&PL_sv_undef);
                PUSHs(sv_reply);
            }
            else {
                PUSHs(sv_reply);
            }
            PUTBACK;

            call_sv(cbt->cb, G_DISCARD | G_EVAL);
            if (SvTRUE(ERRSV)) {
                warn("EV::Redis: exception in command callback: %s", SvPV_nolen(ERRSV));
            }

            FREETMPS;
            LEAVE;
        }
    }

    self->callback_depth--;
    self->current_cb = NULL;

    /* If DESTROY was called during our callback (e.g., user undef'd $redis),
     * self->magic is EV_REDIS_FREED but self is still valid (DESTROY defers
     * Safefree when callback_depth > 0). Complete cleanup here.
     * For persistent commands (multi-channel subscribe), hiredis will fire
     * reply_cb again for remaining channels via __redisAsyncFree. Null the
     * callback to prevent double invocation, but leave cbt alive so those
     * later calls see it and can track sub_count for proper cleanup. */
    if (self->magic == EV_REDIS_FREED) {
        if (NULL != cbt->cb) {
            SvREFCNT_dec(cbt->cb);
            cbt->cb = NULL;
        }
        if (!cbt->persist) {
            Safefree(cbt);
        }
        check_destroyed(self);
        return;
    }

    if (cbt->skipped) {
        /* Defensive check: handles edge case where callback is marked skipped
         * during its own execution (e.g., via reentrant event loop where a
         * nested callback overwrites current_cb, allowing skip_pending to
         * process this callback). ngx_queue_remove is safe here due to
         * ngx_queue_init in skip_pending. Don't decrement pending_count since
         * skip_pending already did when it set skipped=1. */
        ngx_queue_remove(&cbt->queue);
        /* For persistent commands (e.g., SUBSCRIBE), hiredis fires reply_cb
         * once per subscribed channel during disconnect. Only free cbt on the
         * last channel to prevent use-after-free. */
        if (cbt->persist && cbt->sub_count > 1) {
            cbt->sub_count--;
            return;
        }
        Safefree(cbt);
        self->callback_depth++;
        send_next_waiting(self);
        self->callback_depth--;
        check_destroyed(self);
        return;
    }

    /* Detect end of persistent subscription: when all channels from a
     * SUBSCRIBE command have been unsubscribed, hiredis removes its internal
     * callback entry. Clean up our cbt to prevent orphaned queue entries. */
    if (cbt->persist && reply != NULL && is_unsub_reply((redisReply*)reply)) {
        cbt->sub_count--;
        if (cbt->sub_count <= 0) {
            /* All channels unsubscribed — persistent commands are not counted
             * in pending_count, so don't decrement it. */
            ngx_queue_remove(&cbt->queue);
            self->callback_depth++;
            if (NULL != cbt->cb) SvREFCNT_dec(cbt->cb);
            Safefree(cbt);
            self->callback_depth--;
            check_destroyed(self);
            return;
        }
    }

    /* Connection teardown with active subscription: hiredis fires reply_cb
     * once per subscribed channel (from dict iteration in __redisAsyncFree).
     * Track sub_count and remove from queue on last channel to prevent
     * disconnect_cb's remove_cb_queue_sv from invoking the callback again. */
    if (cbt->persist && NULL == reply) {
        if (cbt->sub_count > 1) {
            cbt->sub_count--;
        } else {
            ngx_queue_remove(&cbt->queue);
            self->callback_depth++;
            if (NULL != cbt->cb) SvREFCNT_dec(cbt->cb);
            Safefree(cbt);
            self->callback_depth--;
            check_destroyed(self);
        }
        return;
    }

    if (0 == cbt->persist) {
        /* Remove from queue BEFORE SvREFCNT_dec. The SvREFCNT_dec may free a
         * closure that holds the last reference to this object, triggering
         * DESTROY. If cbt is still in the queue, DESTROY's remove_cb_queue_sv
         * would double-free it. Wrapping in callback_depth defers DESTROY's
         * Safefree(self) so we can safely access self afterward. */
        ngx_queue_remove(&cbt->queue);
        self->pending_count--;
        self->callback_depth++;
        if (NULL != cbt->cb) SvREFCNT_dec(cbt->cb);
        Safefree(cbt);
        /* Don't drain waiting queue when reply is NULL (connection dying) —
         * disconnect_cb will handle reconnect and wait queue preservation. */
        if (reply != NULL) {
            send_next_waiting(self);
        }
        self->callback_depth--;
        check_destroyed(self);
    }
}

/* Submit a cbt (already in cb_queue) to Redis. On failure, removes cbt from
 * queue, invokes error callback, and frees cbt. Returns REDIS_OK or REDIS_ERR. */
static int submit_to_redis(EV__Redis self, ev_redis_cb_t* cbt,
                           int argc, const char** argv, const size_t* argvlen)
{
    redisCallbackFn* fn = EV__redis_reply_cb;
    void* privdata = (void*)cbt;
    const char* cmd = argv[0];

    /* Hiredis does not store callbacks for unsubscribe commands — replies are
     * routed through the original subscribe callback. Pass NULL so hiredis
     * doesn't hold a dangling reference; we clean up our cbt below. */
    if (cbt->persist && is_unsubscribe_command(cmd)) {
        fn = NULL;
        privdata = NULL;
    }

    int r = redisAsyncCommandArgv(
        self->ac, fn, privdata,
        argc, argv, argvlen
    );

    if (REDIS_OK != r) {
        ngx_queue_remove(&cbt->queue);
        if (!cbt->persist) self->pending_count--;

        if (NULL != cbt->cb) {
            invoke_callback_error(cbt->cb, sv_2mortal(newSVpv(
                (self->ac && self->ac->errstr[0]) ? self->ac->errstr : "command failed", 0)));
            SvREFCNT_dec(cbt->cb);
        }
        Safefree(cbt);
    } else if (fn == NULL) {
        /* Successfully sent an unsubscribe command. Since hiredis won't 
         * call us back, we must clean up our tracking 'cbt' now. */
        ngx_queue_remove(&cbt->queue);
        if (NULL != cbt->cb) SvREFCNT_dec(cbt->cb);
        Safefree(cbt);
    }

    return r;
}

/* Send waiting commands to Redis. Uses iterative loop instead of recursion
 * to avoid stack overflow when many commands fail consecutively. */
static void send_next_waiting(EV__Redis self) {
    ngx_queue_t* q;
    ev_redis_wait_t* wt;
    ev_redis_cb_t* cbt;

    while (1) {
        /* Check preconditions each iteration - they may change after callbacks */
        if (NULL == self->ac || self->intentional_disconnect) return;
        if (ngx_queue_empty(&self->wait_queue)) return;
        if (self->max_pending > 0 && self->pending_count >= self->max_pending) return;

        q = ngx_queue_head(&self->wait_queue);
        wt = ngx_queue_data(q, ev_redis_wait_t, queue);
        ngx_queue_remove(q);
        self->waiting_count--;

        Newx(cbt, 1, ev_redis_cb_t);
        cbt->cb = wt->cb;
        wt->cb = NULL;
        cbt->skipped = 0;
        cbt->persist = wt->persist;
        cbt->sub_count = wt->persist ? wt->argc - 1 : 0;
        ngx_queue_init(&cbt->queue);
        ngx_queue_insert_tail(&self->cb_queue, &cbt->queue);
        if (!cbt->persist) self->pending_count++;

        /* Ignore submit_to_redis return: on failure it invokes cbt's error
         * callback and frees cbt, so the loop continues to try the next entry. */
        (void)submit_to_redis(self, cbt, wt->argc,
            (const char**)wt->argv, wt->argvlen);
        free_wait_entry(wt);
    }
}

MODULE = EV::Redis PACKAGE = EV::Redis

BOOT:
{
    I_EV_API("EV::Redis");

    /* Initialize shared error strings */
    err_skipped = newSVpvs_share("skipped");
    SvREADONLY_on(err_skipped);

    err_waiting_timeout = newSVpvs_share("waiting timeout");
    SvREADONLY_on(err_waiting_timeout);

    err_disconnected = newSVpvs_share("disconnected");
    SvREADONLY_on(err_disconnected);
#ifdef EV_REDIS_SSL
    redisInitOpenSSL();
#endif
}

EV::Redis
_new(char* class, EV::Loop loop);
CODE:
{
    PERL_UNUSED_VAR(class);
    Newxz(RETVAL, 1, ev_redis_t);
    RETVAL->magic = EV_REDIS_MAGIC;
    ngx_queue_init(&RETVAL->cb_queue);
    ngx_queue_init(&RETVAL->wait_queue);
    RETVAL->loop = loop;
    RETVAL->cloexec = 1;
}
OUTPUT:
    RETVAL

void
DESTROY(EV::Redis self);
CODE:
{
    redisAsyncContext* ac_to_free;
    int skip_cb_cleanup = 0;

    /* Check for use-after-free: if magic number is wrong, this object
     * was already freed and memory is being reused. Skip cleanup. */
    if (self->magic != EV_REDIS_MAGIC) {
        if (self->magic == EV_REDIS_FREED) {
            /* Already destroyed - this is a double-free at Perl level */
            return;
        }
        /* Unknown magic - memory corruption or uninitialized */
        return;
    }

    /* Mark as freed FIRST to prevent re-entrant DESTROY */
    self->magic = EV_REDIS_FREED;

    /* Stop timers BEFORE PL_dirty check. Timer callbacks have self as data
     * pointer, so we must stop them before freeing self to prevent UAF.
     * The stop helpers check for NULL loop, so this is safe even if loop
     * is already destroyed. */
    stop_reconnect_timer(self);
    stop_waiting_timer(self);

    /* During global destruction (PL_dirty), the EV loop and other Perl
     * objects may already be destroyed. Clean up hiredis and our own memory
     * but don't invoke Perl-level handlers.
     * CRITICAL: We must call redisAsyncFree to stop the libev adapter's
     * watchers and free the redisAsyncContext. Without this, the adapter's
     * ev_io/ev_timer watchers remain registered in the EV loop with dangling
     * data pointers, causing SEGV during process cleanup. */
    if (PL_dirty) {
        if (NULL != self->ac) {
            /* Null cb_queue callbacks before redisAsyncFree to prevent
             * SvREFCNT_dec on potentially-freed SVs during global destruction.
             * (Same pattern as wait_queue below.) */
            {
                ngx_queue_t* q;
                for (q = ngx_queue_head(&self->cb_queue);
                     q != ngx_queue_sentinel(&self->cb_queue);
                     q = ngx_queue_next(q)) {
                    ev_redis_cb_t* cbt = ngx_queue_data(q, ev_redis_cb_t, queue);
                    cbt->cb = NULL;
                }
            }
            self->ac->data = NULL;  /* prevent callbacks from accessing self */
            redisAsyncFree(self->ac);
            self->ac = NULL;
        }
        if (NULL != self->ac_saved) {
            self->ac_saved->data = NULL;
            self->ac_saved = NULL;
        }
        free_c_fields(self);
        /* Free wait_queue C memory (skip Perl callbacks during global destruction) */
        while (!ngx_queue_empty(&self->wait_queue)) {
            ngx_queue_t* q = ngx_queue_head(&self->wait_queue);
            ev_redis_wait_t* wt = ngx_queue_data(q, ev_redis_wait_t, queue);
            ngx_queue_remove(q);
            wt->cb = NULL;  /* skip SvREFCNT_dec during PL_dirty */
            free_wait_entry(wt);
        }
        Safefree(self);
        return;
    }

    self->reconnect = 0;

    /* CRITICAL: Set self->ac to NULL BEFORE calling redisAsyncFree.
     * redisAsyncFree triggers reply callbacks, which call send_next_waiting,
     * which checks self->ac != NULL before issuing commands. If we don't
     * clear self->ac first, send_next_waiting will try to call
     * redisAsyncCommandArgv during the teardown, causing heap corruption. */
    self->loop = NULL;
    ac_to_free = self->ac;
    self->ac = NULL;
    if (NULL != ac_to_free) {
        /* If inside a hiredis callback (REDIS_IN_CALLBACK), redisAsyncFree
         * will be deferred. hiredis will fire pending reply callbacks later
         * via __redisAsyncFree. NULL ac->data so those callbacks see NULL self
         * and handle cleanup without accessing freed memory. */
        if (ac_to_free->c.flags & REDIS_IN_CALLBACK) {
            ac_to_free->data = NULL;
            skip_cb_cleanup = 1;
        }

        /* Protect against premature free in disconnect_cb if triggered synchronously */
        self->callback_depth++;
        redisAsyncFree(ac_to_free);
        self->callback_depth--;
    }
    /* If disconnect() was called from inside a callback, ac_saved points to
     * the deferred async context. NULL its data pointer to prevent the
     * deferred disconnect callback from accessing freed self. */
    if (self->ac_saved != NULL) {
        self->ac_saved->data = NULL;
        self->ac_saved = NULL;
        skip_cb_cleanup = 1;
    }
    CLEAR_HANDLER(self->error_handler);
    CLEAR_HANDLER(self->connect_handler);
    CLEAR_HANDLER(self->disconnect_handler);
    CLEAR_HANDLER(self->push_handler);
    free_c_fields(self);

    if (!self->in_wait_cleanup) {
        clear_wait_queue_sv(self, err_disconnected);
    }
    if (!skip_cb_cleanup && !self->in_cb_cleanup) {
        /* Safe to free cbts ourselves — hiredis has no deferred references. */
        remove_cb_queue_sv(self, NULL);
    }
    /* else: hiredis still holds references to our cbts (deferred free/disconnect).
     * reply_cb will handle cbt cleanup when called with self == NULL. */

    /* Defer Safefree if inside a callback — check_destroyed() handles it */
    if (self->current_cb == NULL && self->callback_depth == 0) {
        Safefree(self);
    }
}

void
connect(EV::Redis self, char* hostname, int port = 6379);
CODE:
{
    redisOptions opts;

    if (NULL != self->ac) {
        croak("already connected");
    }

    self->intentional_disconnect = 0;
    self->reconnect_attempts = 0;
    clear_connection_params(self);
    self->host = savepv(hostname);
    self->port = port;

    memset(&opts, 0, sizeof(opts));
    pre_connect_common(self, &opts);
    REDIS_OPTIONS_SET_TCP(&opts, hostname, port);
    self->ac = redisAsyncConnectWithOptions(&opts);
    if (NULL == self->ac) {
        croak("connect error: cannot allocate memory");
    }

    (void)post_connect_setup(self, "connect error");
}

void
connect_unix(EV::Redis self, const char* path);
CODE:
{
    redisOptions opts;

    if (NULL != self->ac) {
        croak("already connected");
    }

    self->intentional_disconnect = 0;
    self->reconnect_attempts = 0;
    clear_connection_params(self);
    self->path = savepv(path);

    memset(&opts, 0, sizeof(opts));
    pre_connect_common(self, &opts);
    REDIS_OPTIONS_SET_UNIX(&opts, path);
    self->ac = redisAsyncConnectWithOptions(&opts);
    if (NULL == self->ac) {
        croak("connect error: cannot allocate memory");
    }

    (void)post_connect_setup(self, "connect error");
}

void
disconnect(EV::Redis self);
CODE:
{
    /* Stop any pending reconnect timer on explicit disconnect */
    self->intentional_disconnect = 1;
    stop_reconnect_timer(self);
    self->reconnect_attempts = 0;

    if (NULL == self->ac) {
        /* Already disconnected — still stop waiting timer and clear
         * wait queue (e.g., resume_waiting_on_reconnect kept them alive
         * after a connection drop, but user now explicitly disconnects). */
        stop_waiting_timer(self);
        if (!ngx_queue_empty(&self->wait_queue)) {
            self->callback_depth++;
            clear_wait_queue_sv(self, err_disconnected);
            self->callback_depth--;
            check_destroyed(self);
        }
        return;
    }
    /* Save ac pointer for deferred disconnect: when inside a hiredis
     * callback, redisAsyncDisconnect only sets REDIS_DISCONNECTING and
     * returns. DESTROY needs ac_saved to NULL ac->data if the Perl object
     * is freed before the deferred disconnect completes.
     * Only set when REDIS_IN_CALLBACK: in the synchronous path,
     * disconnect_cb fires during redisAsyncDisconnect and clears ac_saved;
     * but if DESTROY fires nested during that processing (SvREFCNT_dec
     * dropping last ref), it would NULL ac->data, causing disconnect_cb to
     * skip cleanup, leaving ac_saved dangling after ac is freed. */
    if (self->ac->c.flags & REDIS_IN_CALLBACK) {
        self->ac_saved = self->ac;
    }
    /* Protect against Safefree(self) if disconnect_cb fires synchronously
     * and user's on_disconnect handler drops the last Perl reference. */
    self->callback_depth++;
    redisAsyncDisconnect(self->ac);
    self->ac = NULL;
    self->callback_depth--;
    if (check_destroyed(self)) return;
}

int
is_connected(EV::Redis self);
CODE:
{
    RETVAL = (NULL != self->ac) ? 1 : 0;
}
OUTPUT:
    RETVAL

SV*
connect_timeout(EV::Redis self, SV* timeout_ms = NULL);
CODE:
{
    RETVAL = timeout_accessor(&self->connect_timeout, timeout_ms, "connect_timeout");
}
OUTPUT:
    RETVAL

SV*
command_timeout(EV::Redis self, SV* timeout_ms = NULL);
CODE:
{
    RETVAL = timeout_accessor(&self->command_timeout, timeout_ms, "command_timeout");
    /* Apply to active connection immediately */
    if (NULL != timeout_ms && SvOK(timeout_ms) && NULL != self->ac && NULL != self->command_timeout) {
        redisAsyncSetTimeout(self->ac, *self->command_timeout);
    }
}
OUTPUT:
    RETVAL

SV*
on_error(EV::Redis self, SV* handler = NULL);
CODE:
{
    RETVAL = handler_accessor(&self->error_handler, handler, items > 1);
}
OUTPUT:
    RETVAL

SV*
on_connect(EV::Redis self, SV* handler = NULL);
CODE:
{
    RETVAL = handler_accessor(&self->connect_handler, handler, items > 1);
}
OUTPUT:
    RETVAL

SV*
on_disconnect(EV::Redis self, SV* handler = NULL);
CODE:
{
    RETVAL = handler_accessor(&self->disconnect_handler, handler, items > 1);
}
OUTPUT:
    RETVAL

SV*
on_push(EV::Redis self, SV* handler = NULL);
CODE:
{
    RETVAL = handler_accessor(&self->push_handler, handler, items > 1);
    /* Sync push callback with hiredis if connected */
    if (NULL != self->ac) {
        if (NULL != self->push_handler) {
            redisAsyncSetPushCallback(self->ac, EV__redis_push_cb);
        } else {
            redisAsyncSetPushCallback(self->ac, NULL);
        }
    }
}
OUTPUT:
    RETVAL

int
command(EV::Redis self, ...);
PREINIT:
    SV* cb;
    char** argv;
    size_t* argvlen;
    STRLEN len;
    int argc, i, persist;
    ev_redis_cb_t* cbt;
    ev_redis_wait_t* wt;
    char* p;
CODE:
{
    if (items < 2) {
        croak("Usage: command(\"command\", ..., [$callback])");
    }

    cb = ST(items - 1);
    if (SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV) {
        argc = items - 2; /* last arg is callback */
    }
    else {
        cb = NULL;         /* fire-and-forget: no callback */
        argc = items - 1;
    }

    if (argc < 1) {
        croak("Usage: command(\"command\", ..., [$callback])");
    }

    if (NULL == self->ac) {
        if (!self->reconnect_timer_active) {
            croak("connection required before calling command");
        }
        /* Reconnect in progress — fall through to queue in wait_queue */
    }
    Newx(argv, argc, char*);
    SAVEFREEPV(argv);
    Newx(argvlen, argc, size_t);
    SAVEFREEPV(argvlen);

    for (i = 0; i < argc; i++) {
        argv[i] = SvPV(ST(i + 1), len);
        argvlen[i] = len;
    }

    persist = is_persistent_command(argv[0]);

    if (NULL == self->ac ||
        (self->max_pending > 0 && self->pending_count >= self->max_pending)) {
        Newx(wt, 1, ev_redis_wait_t);
        Newx(wt->argv, argc, char*);
        Newx(wt->argvlen, argc, size_t);
        for (i = 0; i < argc; i++) {
            Newx(p, argvlen[i] + 1, char);
            Copy(argv[i], p, argvlen[i], char);
            p[argvlen[i]] = '\0';
            wt->argv[i] = p;
            wt->argvlen[i] = argvlen[i];
        }
        wt->argc = argc;
        wt->cb = SvREFCNT_inc(cb);
        wt->persist = persist;
        /* Refresh ev_now: command() may be called outside an ev_run iteration
         * (e.g. during initial setup), where the cached time is stale. Without
         * this, queued_at reflects an old time base and a later expire check
         * against the up-to-date ev_now would compute an inflated elapsed. */
        ev_now_update(self->loop);
        wt->queued_at = ev_now(self->loop);
        ngx_queue_init(&wt->queue);
        ngx_queue_insert_tail(&self->wait_queue, &wt->queue);
        self->waiting_count++;
        schedule_waiting_timer(self);
        RETVAL = REDIS_OK;
    }
    else {
        Newx(cbt, 1, ev_redis_cb_t);
        cbt->cb = SvREFCNT_inc(cb);
        cbt->skipped = 0;
        cbt->persist = persist;
        cbt->sub_count = persist ? argc - 1 : 0;
        ngx_queue_init(&cbt->queue);
        ngx_queue_insert_tail(&self->cb_queue, &cbt->queue);
        if (!persist) self->pending_count++;

        RETVAL = submit_to_redis(self, cbt,
            argc, (const char**)argv, argvlen);
    }
}
OUTPUT:
    RETVAL

void
reconnect(EV::Redis self, int enable, int delay_ms = 1000, int max_attempts = 0);
CODE:
{
    validate_timeout_ms(delay_ms, "reconnect_delay");
    self->reconnect = enable ? 1 : 0;
    self->reconnect_delay_ms = delay_ms;
    self->max_reconnect_attempts = max_attempts >= 0 ? max_attempts : 0;
    self->reconnect_attempts = 0;

    if (!enable) {
        stop_reconnect_timer(self);
    }
}

int
reconnect_enabled(EV::Redis self);
CODE:
{
    RETVAL = self->reconnect;
}
OUTPUT:
    RETVAL

int
pending_count(EV::Redis self);
CODE:
{
    RETVAL = self->pending_count;
}
OUTPUT:
    RETVAL

int
waiting_count(EV::Redis self);
CODE:
{
    RETVAL = self->waiting_count;
}
OUTPUT:
    RETVAL

int
max_pending(EV::Redis self, SV* limit = NULL);
CODE:
{
    if (NULL != limit && SvOK(limit)) {
        int val = SvIV(limit);
        if (val < 0) {
            croak("max_pending must be non-negative");
        }
        self->max_pending = val;

        /* When limit is increased or removed, send waiting commands.
         * callback_depth protects against DESTROY if a failed command's
         * error callback drops the last Perl reference to self. */
        self->callback_depth++;
        send_next_waiting(self);
        self->callback_depth--;
        if (check_destroyed(self)) XSRETURN_IV(0);
    }
    RETVAL = self->max_pending;
}
OUTPUT:
    RETVAL

SV*
waiting_timeout(EV::Redis self, SV* timeout_ms = NULL);
CODE:
{
    if (NULL != timeout_ms && SvOK(timeout_ms)) {
        IV ms = SvIV(timeout_ms);
        validate_timeout_ms(ms, "waiting_timeout");
        self->waiting_timeout_ms = (int)ms;
        schedule_waiting_timer(self);
    }

    RETVAL = newSViv((IV)self->waiting_timeout_ms);
}
OUTPUT:
    RETVAL

int
resume_waiting_on_reconnect(EV::Redis self, SV* value = NULL);
CODE:
{
    if (NULL != value && SvOK(value)) {
        self->resume_waiting_on_reconnect = SvTRUE(value) ? 1 : 0;
    }
    RETVAL = self->resume_waiting_on_reconnect;
}
OUTPUT:
    RETVAL

int
priority(EV::Redis self, SV* value = NULL);
CODE:
{
    if (NULL != value && SvOK(value)) {
        int prio = SvIV(value);
        if (prio < EV_MINPRI) prio = EV_MINPRI;
        if (prio > EV_MAXPRI) prio = EV_MAXPRI;
        self->priority = prio;
        if (NULL != self->ac) {
            redisLibevSetPriority(self->ac, prio);
        }
    }
    RETVAL = self->priority;
}
OUTPUT:
    RETVAL

int
keepalive(EV::Redis self, SV* value = NULL);
CODE:
{
    if (NULL != value && SvOK(value)) {
        int interval = SvIV(value);
        if (interval < 0) croak("keepalive interval must be non-negative");
        if (interval > MAX_TIMEOUT_MS / 1000) croak("keepalive interval too large");
        self->keepalive = interval;
        if (NULL != self->ac && interval > 0) {
            redisEnableKeepAliveWithInterval(&self->ac->c, interval);
        }
    }
    RETVAL = self->keepalive;
}
OUTPUT:
    RETVAL

int
prefer_ipv4(EV::Redis self, SV* value = NULL);
CODE:
{
    if (NULL != value && SvOK(value)) {
        self->prefer_ipv4 = SvTRUE(value) ? 1 : 0;
        if (self->prefer_ipv4) self->prefer_ipv6 = 0;
    }
    RETVAL = self->prefer_ipv4;
}
OUTPUT:
    RETVAL

int
prefer_ipv6(EV::Redis self, SV* value = NULL);
CODE:
{
    if (NULL != value && SvOK(value)) {
        self->prefer_ipv6 = SvTRUE(value) ? 1 : 0;
        if (self->prefer_ipv6) self->prefer_ipv4 = 0;
    }
    RETVAL = self->prefer_ipv6;
}
OUTPUT:
    RETVAL

SV*
source_addr(EV::Redis self, SV* value = NULL);
CODE:
{
    if (items > 1) {
        if (NULL != self->source_addr) {
            Safefree(self->source_addr);
            self->source_addr = NULL;
        }
        if (NULL != value && SvOK(value)) {
            self->source_addr = savepv(SvPV_nolen(value));
        }
    }
    if (NULL != self->source_addr) {
        RETVAL = newSVpv(self->source_addr, 0);
    } else {
        RETVAL = &PL_sv_undef;
    }
}
OUTPUT:
    RETVAL

unsigned int
tcp_user_timeout(EV::Redis self, SV* value = NULL);
CODE:
{
    if (NULL != value && SvOK(value)) {
        IV ms = SvIV(value);
        validate_timeout_ms(ms, "tcp_user_timeout");
        self->tcp_user_timeout = (unsigned int)ms;
    }
    RETVAL = self->tcp_user_timeout;
}
OUTPUT:
    RETVAL

int
cloexec(EV::Redis self, SV* value = NULL);
CODE:
{
    if (NULL != value && SvOK(value)) {
        self->cloexec = SvTRUE(value) ? 1 : 0;
    }
    RETVAL = self->cloexec;
}
OUTPUT:
    RETVAL

int
reuseaddr(EV::Redis self, SV* value = NULL);
CODE:
{
    if (NULL != value && SvOK(value)) {
        self->reuseaddr = SvTRUE(value) ? 1 : 0;
    }
    RETVAL = self->reuseaddr;
}
OUTPUT:
    RETVAL

void
skip_waiting(EV::Redis self);
CODE:
{
    /* Protect self from destruction during queue iteration */
    self->callback_depth++;

    /* If cleanup is already in progress (e.g., during expire_waiting_commands
     * or disconnect callback), don't modify the wait_queue. */
    if (self->in_wait_cleanup) {
        self->callback_depth--;
        check_destroyed(self);
        return;
    }

    clear_wait_queue_sv(self, err_skipped);
    stop_waiting_timer(self);

    self->callback_depth--;
    check_destroyed(self);
}

void
skip_pending(EV::Redis self);
CODE:
{
    ngx_queue_t local_queue;
    ngx_queue_t* q;
    ev_redis_cb_t* cbt;

    /* Protect self from destruction during queue iteration */
    self->callback_depth++;

    /* Always attempt to clear waiting queue (handles its own re-entrancy) */
    clear_wait_queue_sv(self, err_skipped);
    stop_waiting_timer(self);

    /* If cb_queue cleanup is already in progress, stop here. */
    if (self->in_cb_cleanup) {
        self->callback_depth--;
        check_destroyed(self);
        return;
    }

    /* Protect cb_queue iteration from re-entrancy. If a user callback
     * calls skip_pending() again, the in_cb_cleanup check above will return. */
    self->in_cb_cleanup = 1;

    ngx_queue_init(&local_queue);
    while (!ngx_queue_empty(&self->cb_queue)) {
        q = ngx_queue_head(&self->cb_queue);
        cbt = ngx_queue_data(q, ev_redis_cb_t, queue);

        if (cbt == self->current_cb) {
            /* If current_cb is at head — if it's the only item, we're done */
            if (ngx_queue_next(q) == ngx_queue_sentinel(&self->cb_queue)) {
                break;
            }
            q = ngx_queue_next(q);
            cbt = ngx_queue_data(q, ev_redis_cb_t, queue);
        }

        ngx_queue_remove(q);
        ngx_queue_insert_tail(&local_queue, q);
    }

    while (!ngx_queue_empty(&local_queue)) {
        if (self->magic == EV_REDIS_FREED) {
            break;
        }

        q = ngx_queue_head(&local_queue);
        cbt = ngx_queue_data(q, ev_redis_cb_t, queue);
        ngx_queue_remove(q);

        /* Mark as skipped FIRST to prevent double callback invocation if
         * invoke_callback_error re-enters the event loop. */
        cbt->skipped = 1;

        /* Re-initialize queue node so any subsequent remove (from reply_cb's
         * skipped path on re-entry) is safe. */
        ngx_queue_init(q);
        if (!cbt->persist) self->pending_count--;

        /* Save and clear callback BEFORE invoking — if the user callback
         * re-enters and a Redis reply arrives, reply_cb sees skipped=1
         * and frees cbt. Clearing cb first avoids use-after-free. */
        if (NULL != cbt->cb) {
            SV* cb_to_invoke = cbt->cb;
            cbt->cb = NULL;

            invoke_callback_error(cb_to_invoke, err_skipped);
            SvREFCNT_dec(cb_to_invoke);
        }
    }

    self->in_cb_cleanup = 0;

    self->callback_depth--;
    check_destroyed(self);
}

int
has_ssl(char* class);
CODE:
{
    PERL_UNUSED_VAR(class);
#ifdef EV_REDIS_SSL
    RETVAL = 1;
#else
    RETVAL = 0;
#endif
}
OUTPUT:
    RETVAL

#ifdef EV_REDIS_SSL

void
_setup_ssl_context(EV::Redis self, SV* cacert, SV* capath, SV* cert, SV* key, SV* server_name, int verify = 1);
CODE:
{
    redisSSLContextError ssl_error = REDIS_SSL_CTX_NONE;
    redisSSLOptions ssl_opts;

    memset(&ssl_opts, 0, sizeof(ssl_opts));
    ssl_opts.cacert_filename = (SvOK(cacert)) ? SvPV_nolen(cacert) : NULL;
    ssl_opts.capath = (SvOK(capath)) ? SvPV_nolen(capath) : NULL;
    ssl_opts.cert_filename = (SvOK(cert)) ? SvPV_nolen(cert) : NULL;
    ssl_opts.private_key_filename = (SvOK(key)) ? SvPV_nolen(key) : NULL;
    ssl_opts.server_name = (SvOK(server_name)) ? SvPV_nolen(server_name) : NULL;
    ssl_opts.verify_mode = verify ? REDIS_SSL_VERIFY_PEER : REDIS_SSL_VERIFY_NONE;

    if (NULL != self->ssl_ctx) {
        redisFreeSSLContext(self->ssl_ctx);
        self->ssl_ctx = NULL;
    }

    self->ssl_ctx = redisCreateSSLContextWithOptions(&ssl_opts, &ssl_error);

    if (NULL == self->ssl_ctx) {
        croak("SSL context creation failed: %s", redisSSLContextGetError(ssl_error));
    }
}

#endif
