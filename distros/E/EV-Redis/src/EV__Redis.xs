#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "EVAPI.h"

#include <sys/un.h>
#include <fcntl.h>
#include <pthread.h>

#include "hiredis.h"
#include "async.h"
/* hiredis's own dict code for its subscription dicts; perl's headers have
 * already set the feature macros fmacros.h would */
#define __HIREDIS_FMACRO_H
#include "dict.c"
#include "libev_adapter.h"
#include "ngx-queue.h"

#ifdef EV_REDIS_SSL
#include "hiredis_ssl.h"
#include <openssl/err.h>
#endif

typedef struct ev_redis_s ev_redis_t;
typedef struct ev_redis_cb_s ev_redis_cb_t;
typedef struct ev_redis_wait_s ev_redis_wait_t;
typedef struct ev_redis_drain_s ev_redis_drain_t;
typedef struct ev_redis_txn_s ev_redis_txn_t;

typedef ev_redis_t* EV__Redis;
typedef struct ev_loop* EV__Loop;

/* SvIV, but values above IV_MAX saturate instead of wrapping negative */
typedef IV sat_iv;
static IV sv_to_sat_iv(SV* sv) {
    IV iv = SvIV(sv);
    return (SvIsUV(sv) && iv < 0) ? IV_MAX : iv;
}

#define EV_REDIS_MAGIC 0xDEADBEEF
#define EV_REDIS_FREED 0xFEEDFACE

/* nulls first: freeing it may run code that sets the field again */
#define CLEAR_HANDLER(field) \
    do { SV* old_ = (SV*)(field); (field) = NULL; if (NULL != old_) SvREFCNT_dec(old_); } while(0)

struct ev_redis_s {
    unsigned int magic;
    struct ev_loop* loop;
    SV* loop_sv; /* the EV::Loop object itself, not a reference to it */
    redisAsyncContext* ac;
    UV connection_gen; /* each attempt supersedes older draining contexts */
    SV* error_handler;
    SV* connect_handler;
    SV* disconnect_handler;
    SV* push_handler;
    struct timeval* connect_timeout;
    struct timeval* command_timeout;
    ngx_queue_t cb_queue;
    ngx_queue_t wait_queue;
    ngx_queue_t setup_queue; /* on_connect's delayed commands go first */
    ngx_queue_t resume_setup_queue; /* setup kept for a later connection */
    int pending_count;
    int pending_detached; /* of pending_count: owed by a context disconnect() replaced */
    int waiting_count;
    UV cb_seq;
    int max_pending; /* 0 = unlimited */
    ev_redis_cb_t* current_cb;
    int resume_waiting_on_reconnect;
    int waiting_timeout_ms; /* 0 = unlimited */
    ev_timer waiting_timer;
    int waiting_timer_active;

    char* host;
    int port;
    char* path;
    int reconnect;
    int reconnect_delay_ms;
    int max_reconnect_attempts; /* 0 = unlimited */
    int reconnect_attempts;
    ev_timer reconnect_timer;
    int reconnect_timer_active;
    int intentional_disconnect;
    int priority;
    int in_cb_cleanup;
    int in_wait_cleanup;
    int callback_depth; /* nonzero defers DESTROY's Safefree(self) to check_destroyed() */
    int in_connect_handler; /* setup commands go ahead of waiting ones */
    int monitoring;
    int in_multi; /* confirmed transaction state on ac */
    int pending_multi; /* transaction boundary replies still outstanding */
    ev_redis_txn_t* issued_txn;
    ev_tstamp barrier_since; /* the queue is held for those replies since; 0 = not held */
    int keepalive; /* seconds, 0 = disabled */
    int prefer_ipv4;
    int prefer_ipv6;
    char* source_addr;
    unsigned int tcp_user_timeout; /* ms, 0 = OS default */
    int cloexec;
    int reuseaddr;
    ngx_queue_t drain_queue;
#ifdef EV_REDIS_SSL
    redisSSLContext* ssl_ctx;
#endif
};

struct ev_redis_cb_s {
    SV* cb;
    redisAsyncContext* ac; /* owner: cb_queue is shared with draining old contexts */
    ngx_queue_t queue;
    ev_redis_txn_t* txn;
    UV seq; /* order of creation: skip_pending spares the newer ones */
    int sub_count; /* hiredis channel/pattern entries holding it; MONITOR: 1 */
    unsigned char persist;
    unsigned char monitor;
    unsigned char skipped;
    unsigned char running; /* its callback is on the stack: nested loops can run several */
    unsigned char detached; /* its context was replaced: it awaits the reply but holds no slot */
    unsigned char proto_cmd; /* HELLO or RESET: its reply tells the protocol now in use */
    unsigned char multi; /* transaction boundary, if any */
    unsigned char watch;
};

struct ev_redis_wait_s {
    char** argv;
    size_t* argvlen;
    int argc;
    SV* cb;
    int persist;
    ev_redis_txn_t* txn;
    ngx_queue_t queue;
    ev_tstamp queued_at;
};

struct ev_redis_drain_s {
    redisAsyncContext* ac;
    UV connection_gen;
    ngx_queue_t queue;
};

struct ev_redis_txn_s {
    unsigned int refs;
    int started;
    int multi;
    int multi_started;
    int watched;
    int closed;
};

static ev_redis_txn_t* txn_ref(ev_redis_txn_t* txn) {
    if (NULL != txn) txn->refs++;
    return txn;
}

static void txn_unref(ev_redis_txn_t* txn) {
    if (NULL != txn && 0 == --txn->refs) Safefree(txn);
}

static void txn_scope_free(pTHX_ void* ptr) {
    txn_unref((ev_redis_txn_t*)ptr);
}

static void free_cb_entry(ev_redis_cb_t* cbt) {
    txn_unref(cbt->txn);
    Safefree(cbt);
}

/* Bind the pointer to its original referent; copies lack this marker or
 * retain the original referent's address. No shared registry on the hot path. */
static MGVTBL ev_redis_object_vtbl = {0};

static void ev_redis_mark_sv(SV* sv) {
    SV* inner = SvRV(sv);
    MAGIC* mg = sv_magicext(inner, NULL, PERL_MAGIC_ext,
        &ev_redis_object_vtbl, NULL, 0);
    mg->mg_ptr = (char*)inner;
}

static int ev_redis_owns_sv(SV* inner) {
    MAGIC* mg;
    if (SvTYPE(inner) < SVt_PVMG) return 0;
    for (mg = SvMAGIC(inner); NULL != mg; mg = mg->mg_moremagic) {
        if (mg->mg_virtual == &ev_redis_object_vtbl) return mg->mg_ptr == (char*)inner;
    }
    return 0;
}

/* Each queue is FIFO by queued_at; setup priority does not change deadlines. */
static ngx_queue_t* oldest_waiting(EV__Redis self) {
    ngx_queue_t* q = ngx_queue_head(&self->wait_queue);
    ngx_queue_t* setup = ngx_queue_head(&self->setup_queue);
    ngx_queue_t* resume = ngx_queue_head(&self->resume_setup_queue);
    if (!ngx_queue_empty(&self->setup_queue)
            && (ngx_queue_empty(&self->wait_queue)
                || ngx_queue_data(setup, ev_redis_wait_t, queue)->queued_at
                    < ngx_queue_data(q, ev_redis_wait_t, queue)->queued_at)) q = setup;
    if (!ngx_queue_empty(&self->resume_setup_queue)
            && (q == ngx_queue_sentinel(&self->wait_queue)
                || ngx_queue_data(resume, ev_redis_wait_t, queue)->queued_at
                    < ngx_queue_data(q, ev_redis_wait_t, queue)->queued_at)) q = resume;
    return q;
}

/* A new connection's setup takes precedence over setup kept from an older one. */
static void demote_setup_waiters(EV__Redis self) {
    if (!ngx_queue_empty(&self->setup_queue)) {
        ngx_queue_add(&self->resume_setup_queue, &self->setup_queue);
        ngx_queue_init(&self->setup_queue);
    }
}

static SV* err_skipped = NULL;
static SV* err_waiting_timeout = NULL;
static SV* err_disconnected = NULL;

enum {
    EV_REDIS_MULTI = 1,
    EV_REDIS_EXEC,
    EV_REDIS_DISCARD,
    EV_REDIS_RESET
};

/* protocol tokens are ASCII: libc case folding differs under tr_TR */
static int ascii_strcasecmp(const char* a, const char* b) {
    int ca, cb;
    do {
        ca = (unsigned char)*a++;
        cb = (unsigned char)*b++;
        if (ca >= 'A' && ca <= 'Z') ca += 'a' - 'A';
        if (cb >= 'A' && cb <= 'Z') cb += 'a' - 'A';
        if (ca != cb) return ca - cb;
    } while (0 != ca);
    return 0;
}

static int transaction_command(const char* cmd) {
    char c = cmd[0];
    if ((c == 'm' || c == 'M') && 0 == ascii_strcasecmp(cmd, "multi")) return EV_REDIS_MULTI;
    if ((c == 'e' || c == 'E') && 0 == ascii_strcasecmp(cmd, "exec")) return EV_REDIS_EXEC;
    if ((c == 'd' || c == 'D') && 0 == ascii_strcasecmp(cmd, "discard")) return EV_REDIS_DISCARD;
    if ((c == 'r' || c == 'R') && 0 == ascii_strcasecmp(cmd, "reset")) return EV_REDIS_RESET;
    return 0;
}

/* these replies cannot safely be queued inside a transaction */
static int needs_transaction_reply(int persist, const char* cmd) {
    return persist || ((cmd[0] == 'h' || cmd[0] == 'H') && 0 == ascii_strcasecmp(cmd, "hello"));
}

/* errors after which the server holds no transaction (a cluster redirect, or
 * before 6.2 a demotion to read-only replica, discards it without EXECABORT) */
static int ends_transaction(const redisReply* err) {
    static const char* const prefix[] = {
        "EXECABORT", "MOVED ", "ASK ", "TRYAGAIN", "CLUSTERDOWN", "CROSSSLOT"
    };
    size_t i;
    for (i = 0; i < sizeof(prefix) / sizeof(prefix[0]); i++) {
        if (0 == strncmp(err->str, prefix[i], strlen(prefix[i]))) return 1;
    }
    return NULL != strstr(err->str, "without MULTI") || NULL != strstr(err->str, "EXEC aborted");
}

static int is_unsubscribe_command(const char* cmd) {
    char c = cmd[0];
    if (c == 'u' || c == 'U') return (0 == ascii_strcasecmp(cmd, "unsubscribe"));
    if (c == 'p' || c == 'P') return (0 == ascii_strcasecmp(cmd, "punsubscribe"));
    return 0;
}

/* hiredis treats SSUBSCRIBE as one-shot: an smessage then fails the
 * connection (RESP2) or is misrouted to on_push (RESP3). */
static int is_shard_pubsub_command(const char* cmd) {
    char c = cmd[0];
    if (c != 's' && c != 'S') return 0;
    return (0 == ascii_strcasecmp(cmd, "ssubscribe")) ||
           (0 == ascii_strcasecmp(cmd, "sunsubscribe"));
}

static int is_persistent_command(const char* cmd) {
    char c = cmd[0];

    if (c == 's' || c == 'S') {
        return (0 == ascii_strcasecmp(cmd, "subscribe"));
    }
    if (c == 'u' || c == 'U') {
        return (0 == ascii_strcasecmp(cmd, "unsubscribe"));
    }
    if (c == 'p' || c == 'P') {
        if (0 == ascii_strcasecmp(cmd, "psubscribe")) return 1;
        if (0 == ascii_strcasecmp(cmd, "punsubscribe")) return 1;
        return 0;
    }
    if (c == 'm' || c == 'M') {
        return (0 == ascii_strcasecmp(cmd, "monitor"));
    }

    return 0;
}

static int is_monitor_command(const char* cmd) {
    return (cmd[0] == 'm' || cmd[0] == 'M') && 0 == ascii_strcasecmp(cmd, "monitor");
}

/* the server answers neither it nor (SKIP) the next command, and hiredis
 * pairs replies with callbacks by order */
static int is_reply_suppressing(int argc, char** argv) {
    if (argc == 3 && 0 == ascii_strcasecmp(argv[0], "client") && 0 == ascii_strcasecmp(argv[1], "reply")) {
        return 0 == ascii_strcasecmp(argv[2], "off") || 0 == ascii_strcasecmp(argv[2], "skip");
    }
    if (0 == ascii_strcasecmp(argv[0], "replconf")) {
        /* the server takes option, value pairs in order */
        int j;
        for (j = 1; j < argc; j += 2) {
            if (0 == ascii_strcasecmp(argv[j], "ack") || 0 == ascii_strcasecmp(argv[j], "getack")) return 1;
        }
    }
    return 0;
}

/* hiredis keeps its subscription state through RESET, which ends it on the
 * server: later replies would be taken for messages or shift callbacks */
static int may_be_subscribed(EV__Redis self) {
    ngx_queue_t* q;
    int i;
    if (NULL != self->ac && (self->ac->c.flags & REDIS_SUBSCRIBED)) return 1;
    for (i = 0; i < 3; i++) {
        ngx_queue_t* list = i == 0 ? &self->wait_queue
            : i == 1 ? &self->setup_queue : &self->resume_setup_queue;
        for (q = ngx_queue_head(list); q != ngx_queue_sentinel(list); q = ngx_queue_next(q)) {
            ev_redis_wait_t* wt = ngx_queue_data(q, ev_redis_wait_t, queue);
            /* a queued unsubscribe removes subscriptions; it is not one */
            if (wt->persist && !is_unsubscribe_command(wt->argv[0])) return 1;
        }
    }
    return 0;
}

/* once hiredis has seen a push it no longer takes RESP2 arrays for pub/sub
 * messages; HELLO answers in the protocol it switched to, RESET with +RESET
 * (inside MULTI, +QUEUED switches nothing) */
static void note_protocol_reply(redisAsyncContext* c, const redisReply* reply) {
    if (reply->type == REDIS_REPLY_ARRAY
            || (reply->type == REDIS_REPLY_STATUS && 0 == ascii_strcasecmp(reply->str, "reset"))) {
        c->c.flags &= ~REDIS_SUPPORTS_PUSH;
    }
}

/* [type, channel, remaining_count] */
static int is_unsub_reply(redisReply* reply) {
    const char* s;

    if (reply->type != REDIS_REPLY_ARRAY && reply->type != REDIS_REPLY_PUSH) return 0;
    if (reply->elements < 3) return 0;
    if (NULL == reply->element[0]) return 0;
    if (reply->element[0]->type != REDIS_REPLY_STRING &&
        reply->element[0]->type != REDIS_REPLY_STATUS) return 0;

    s = reply->element[0]->str;
    if (s[0] == 'u' || s[0] == 'U') return (0 == ascii_strcasecmp(s, "unsubscribe"));
    if (s[0] == 'p' || s[0] == 'P') return (0 == ascii_strcasecmp(s, "punsubscribe"));
    if (s[0] == 's' || s[0] == 'S') return (0 == ascii_strcasecmp(s, "sunsubscribe"));
    return 0;
}

/* hiredis's callback dictionaries hash SDS bytes with dictGenHashFunction. */
static dictEntry* sub_entry(dict* d, const char* name, size_t len) {
    dictEntry* he;
    if (NULL == d || 0 == d->size) return NULL;
    for (he = d->table[dictGenHashFunction((const unsigned char*)name, (int)len) & d->sizemask];
         he; he = he->next) {
        sds key = (sds)dictGetEntryKey(he);
        if (sdslen(key) == len && 0 == memcmp(key, name, len)) return he;
    }
    return NULL;
}

/* The cbt hiredis delivers name to: a re-subscribe replaces the entry, and an
 * unsubscribe reply drops it only when no subscribe confirmation is pending. */
static ev_redis_cb_t* sub_owner(redisAsyncContext* ac, int pattern,
                                const char* name, size_t len, redisCallback** sub) {
    dict* d = pattern ? ac->sub.patterns : ac->sub.channels;
    dictEntry* he = sub_entry(d, name, len);

    if (NULL != sub) *sub = NULL;
    if (NULL != he) {
        redisCallback* cb = (redisCallback*)dictGetEntryVal(he);
        if (NULL != sub) *sub = cb;
        return (ev_redis_cb_t*)cb->privdata;
    }
    return NULL;
}

/* A persistent cbt got reply: count the hiredis entry it lost, if any. At
 * teardown hiredis calls it with NULL once per entry (MONITOR: once). */
static void sub_note_reply(redisAsyncContext* c, ev_redis_cb_t* cbt, redisReply* reply) {
    redisReply* name;
    ev_redis_cb_t* owner;
    redisCallback* sub;
    redisLibevEvents* e;
    int pattern;

    if (NULL == reply) {
        cbt->sub_count--;
        return;
    }
    if (!is_unsub_reply(reply)) return;
    name = reply->element[1];
    if (NULL == name || name->type != REDIS_REPLY_STRING) return;
    pattern = reply->element[0]->str[0] == 'p' || reply->element[0]->str[0] == 'P';
    owner = sub_owner(c, pattern, name->str, name->len, &sub);
    e = (redisLibevEvents*)c->ev.data;
    if (NULL != e && NULL != e->unsubs[pattern]) {
        HV* counts = e->unsubs[pattern];
        SV** count = hv_fetch(counts, name->str, (I32)name->len, 0);
        if (NULL != count) {
            IV n = SvIV(*count);
            if (n > 1) {
                sv_setiv(*count, n - 1);
                /* each extra unsubscribe kept the entry through this reply */
                if (NULL != sub) sub->pending_subs--;
            }
            else (void)hv_delete(counts, name->str, (I32)name->len, G_DISCARD);
        }
    }
    if (owner != cbt) cbt->sub_count--;
}

/* hiredis records a TLS failure as an I/O error with errno 0 ("Success"): name
 * the OpenSSL reason, kept in the context as a callback may clear the queue */
static const char* conn_errstr(const redisAsyncContext* c, const char* fallback) {
#ifdef EV_REDIS_SSL
    if (REDIS_ERR_IO == c->c.err && NULL != c->c.privctx
            && 0 == strcmp(c->c.errstr, strerror(0))) {
        const char* reason = ERR_reason_error_string(ERR_peek_last_error());
        if (NULL != reason) {
            char* errstr = (char*)c->c.errstr;
            strncpy(errstr, reason, sizeof(c->c.errstr) - 1);
            errstr[sizeof(c->c.errstr) - 1] = '\0';
        }
    }
#endif
    return c->errstr[0] ? c->errstr : fallback;
}

static HV* ev_redis_stash;

/* croak() names the XSUB's calling statement; inside our own subs (AUTOLOAD's
 * methods, new) name their caller. The catching eval restores PL_curcop. */
static COP* caller_cop(void) {
    I32 i;
    for (i = cxstack_ix; i >= 0; i--) {
        const PERL_CONTEXT* cx = &cxstack[i];
        if (CxTYPE(cx) != CXt_SUB) continue;
        {
            /* by name too: each ithread has its own stash */
            HV* stash = CvSTASH(cx->blk_sub.cv);
            const char* name = NULL == stash ? NULL : HvNAME_get(stash);
            int ours = stash == ev_redis_stash
                || (NULL != name && strEQ(name, "EV::Redis"));
            return ours ? cx->blk_oldcop : NULL;
        }
    }
    return NULL;
}

static void croak_caller(const char* pat, ...) {
    va_list args;
    SV* msg;
    COP* cop = caller_cop();
    if (NULL != cop) PL_curcop = cop;
    va_start(args, pat);
    msg = sv_2mortal(vnewSVpvf(pat, &args));
    va_end(args);
    Perl_croak(aTHX_ "%" SVf, SVfARG(msg));
}

/* hiredis and OpenSSL take C strings: a NUL would cut it short */
static const char* c_string(SV* sv, const char* what) {
    STRLEN len;
    const char* s = SvPV(sv, len);
    if (strlen(s) != len) croak_caller("%s contains a NUL byte", what);
    return s;
}

/* a UTF-8 lead byte of 0xC4 or more starts a character above 0xFF */
static int has_wide_char(SV* sv) {
    STRLEN len = SvCUR(sv);
    const U8* s = (const U8*)SvPVX(sv);
    while (len--) {
        if (*s++ >= 0xC4) return 1;
    }
    return 0;
}

static void print_error_line(const char* prefix, SV* sv) {
    STRLEN len;
    const char* s = SvPV(sv, len);
    PerlIO_puts(Perl_error_log, prefix);
    PerlIO_write(Perl_error_log, s, len);
    if (0 == len || '\n' != s[len - 1]) PerlIO_puts(Perl_error_log, "\n");
}

/* a die from $SIG{__WARN__} would unwind through hiredis and leave it in REDIS_IN_CALLBACK */
static void warn_exception(const char* what, SV* err) {
    dSP;
    SV* msg;
    ENTER;
    SAVETMPS;
    save_scalar(PL_errgv);  /* G_EVAL clears $@ in place, and err may be it */
    msg = sv_newmortal();
    PUSHMARK(SP);
    EXTEND(SP, 3);
    mPUSHp(what, strlen(what));
    PUSHs(err);
    PUSHs(msg);
    PUTBACK;
    call_pv("EV::Redis::_warn", G_DISCARD | G_EVAL);
    if (SvTRUE(ERRSV)) {
        if (SvOK(msg)) print_error_line("", msg);
        else PerlIO_printf(Perl_error_log, "EV::Redis: exception in %s\n", what);
        print_error_line("EV::Redis: reporting it died: ", ERRSV);
    }
    FREETMPS;
    LEAVE;
}

static void emit_error(EV__Redis self, SV* error) {
    SV* handler = self->error_handler;
    if (NULL == handler) return;
    /* pin: the handler may clear itself ($r->on_error(undef)) mid-call */
    SvREFCNT_inc_simple_void_NN(handler);

    dSP;

    ENTER;
    SAVETMPS;
    save_scalar(PL_errgv);  /* G_EVAL must not clobber the caller's $@ */

    PUSHMARK(SP);
    XPUSHs(error);
    PUTBACK;

    call_sv(handler, G_DISCARD | G_EVAL);
    if (SvTRUE(ERRSV)) {
        warn_exception("error handler", ERRSV);
    }

    FREETMPS;
    LEAVE;
    SvREFCNT_dec(handler);
}

static void emit_error_str(EV__Redis self, const char* error) {
    if (NULL == self->error_handler) return;
    emit_error(self, sv_2mortal(newSVpv(error, 0)));
}

static void invoke_callback_error(SV* cb, SV* error_sv) {
    dSP;
    ENTER;
    SAVETMPS;
    save_scalar(PL_errgv);
    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(sv_newmortal());  /* not &PL_sv_undef: $_[0] must be writable */
    /* newSVsv: sv_mortalcopy may steal a TEMP's string, and error_sv serves every
     * callback of a batch; a copy also keeps @_ off shared READONLY SVs */
    PUSHs(sv_2mortal(newSVsv(error_sv)));
    PUTBACK;
    call_sv(cb, G_DISCARD | G_EVAL);
    if (SvTRUE(ERRSV)) {
        warn_exception("command callback", ERRSV);
    }
    FREETMPS;
    LEAVE;
}

/* Call after callback_depth--; returns 1 if a deferred DESTROY freed self. */
static int check_destroyed(EV__Redis self) {
    if (self->magic == EV_REDIS_FREED &&
        self->callback_depth == 0 &&
        self->current_cb == NULL) {
        Safefree(self);
        return 1;
    }
    return 0;
}

static void free_c_fields(EV__Redis self) {
    txn_unref(self->issued_txn);
    self->issued_txn = NULL;
    if (NULL != self->host) { Safefree(self->host); self->host = NULL; }
    if (NULL != self->path) { Safefree(self->path); self->path = NULL; }
    if (NULL != self->source_addr) { Safefree(self->source_addr); self->source_addr = NULL; }
    if (NULL != self->connect_timeout) { Safefree(self->connect_timeout); self->connect_timeout = NULL; }
    if (NULL != self->command_timeout) { Safefree(self->command_timeout); self->command_timeout = NULL; }
#ifdef EV_REDIS_SSL
    if (NULL != self->ssl_ctx) { redisFreeSSLContext(self->ssl_ctx); self->ssl_ctx = NULL; }
#endif
}

/* Global destruction curses objects and clears RVs in arena order, so a
 * non-default loop may be gone first; the default loop never is. */
static int loop_alive(EV__Redis self) {
    if (NULL == self->loop) return 0;
    if (!PL_dirty || self->loop == EV_DEFAULT_UC) return 1;
    return NULL != self->loop_sv && SvOBJECT(self->loop_sv);
}

static void stop_waiting_timer(EV__Redis self) {
    if (self->waiting_timer_active && loop_alive(self)) {
        ev_timer_stop(self->loop, &self->waiting_timer);
        self->waiting_timer_active = 0;
    }
}

static void stop_reconnect_timer(EV__Redis self) {
    if (self->reconnect_timer_active && loop_alive(self)) {
        ev_timer_stop(self->loop, &self->reconnect_timer);
        self->reconnect_timer_active = 0;
    }
}

/* ~23 days; fits a 32-bit int */
#define MAX_TIMEOUT_MS 2000000000
/* Linux caps TCP_KEEPIDLE here, and an out-of-range setsockopt breaks the connection */
#define MAX_KEEPALIVE 32767

static void validate_timeout_ms(IV ms, const char* name) {
    if (ms < 0) croak_caller("%s must be non-negative", name);
    if (ms > MAX_TIMEOUT_MS) croak_caller("%s too large (max %d ms)", name, MAX_TIMEOUT_MS);
}

static SV* timeout_accessor(struct timeval** tv_ptr, SV* timeout_ms, const char* name) {
    if (NULL != timeout_ms && SvOK(timeout_ms)) {
        IV ms = sv_to_sat_iv(timeout_ms);
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

/* The old handler is handed back for the caller to release last: its closure
 * may hold the only strong reference to self. */
static SV* handler_accessor(SV** handler_ptr, SV* handler, int has_handler_arg, SV** old) {
    int is_code = has_handler_arg && NULL != handler
        && SvROK(handler) && SvTYPE(SvRV(handler)) == SVt_PVCV;

    /* before the swap: a die from $SIG{__WARN__} would leak *old */
    if (has_handler_arg && NULL != handler && SvOK(handler) && !is_code
        && ckWARN(WARN_MISC)) {
        Perl_warner(aTHX_ packWARN(WARN_MISC),
            "EV::Redis: handler is not a code reference, cleared");
    }

    *old = *handler_ptr;
    /* a copy: handler may be the caller's variable, reassigned later */
    *handler_ptr = is_code ? newSVsv(handler) : NULL;

    return (NULL != *handler_ptr)
        ? SvREFCNT_inc(*handler_ptr)
        : &PL_sv_undef;
}

/* Once the loop is destroyed nothing may touch it: adapters free themselves
 * without stopping watchers, and loop-bound methods croak. */
static void detach_dead_loop(EV__Redis self) {
    ngx_queue_t* q;
    if (NULL == self->loop || loop_alive(self)) return;
    if (NULL != self->ac && NULL != self->ac->ev.data) {
        ((redisLibevEvents*)self->ac->ev.data)->loop = NULL;
    }
    for (q = ngx_queue_head(&self->drain_queue);
         q != ngx_queue_sentinel(&self->drain_queue);
         q = ngx_queue_next(q)) {
        redisAsyncContext* dc = ngx_queue_data(q, ev_redis_drain_t, queue)->ac;
        if (NULL != dc->ev.data) ((redisLibevEvents*)dc->ev.data)->loop = NULL;
    }
    self->loop = NULL;
}

/* A method's invocant (typemap T_EVREDIS): a live object made by new */
static EV__Redis ev_redis_from_sv(SV* sv) {
    SV* inner;
    EV__Redis self;
    if (!SvROK(sv)) {
        croak_caller("not an EV::Redis object");
    }
    inner = SvRV(sv);
    if (!SvOBJECT(inner) || (SvSTASH(inner) != ev_redis_stash
            && !sv_derived_from(sv, "EV::Redis"))) {
        croak_caller("not an EV::Redis object");
    }
    if (SvTYPE(inner) >= SVt_PVAV || !SvOK(inner) || 0 == SvIV(inner)) {
        croak_caller("EV::Redis object is destroyed or was not made by new()");
    }
    if (!ev_redis_owns_sv(inner)) {
        croak_caller("EV::Redis object is destroyed or was not made by new()");
    }
    self = INT2PTR(EV__Redis, SvIV(inner));
    detach_dead_loop(self);
    /* Perl code re-entered mid-XSUB (warn hooks, magic) may drop the last
     * reference; hold the referent until the XSUB returns. */
    sv_2mortal(SvREFCNT_inc_simple_NN(SvRV(sv)));
    return self;
}

static void call_void_handler(SV* handler, const char* what) {
    dSP;
    if (NULL == handler) return;
    SvREFCNT_inc_simple_void_NN(handler);
    ENTER;
    SAVETMPS;
    save_scalar(PL_errgv);
    PUSHMARK(SP);
    PUTBACK;
    call_sv(handler, G_DISCARD | G_EVAL);
    if (SvTRUE(ERRSV))
        warn_exception(what, ERRSV);
    FREETMPS;
    LEAVE;
    SvREFCNT_dec(handler);
}

/* a context freed with data == NULL frees its cbts without unlinking them */
static void unlink_cbts_of(EV__Redis self, const redisAsyncContext* ac) {
    ngx_queue_t* q;
    ngx_queue_t* next;
    for (q = ngx_queue_head(&self->cb_queue);
         q != ngx_queue_sentinel(&self->cb_queue);
         q = next) {
        next = ngx_queue_next(q);
        if (ngx_queue_data(q, ev_redis_cb_t, queue)->ac == ac) {
            ngx_queue_remove(q);
            ngx_queue_init(q);
        }
    }
}

/* disconnect() replaced ac: its replies still arrive, but must not hold
 * max_pending slots of the next connection */
static void detach_pending_of(EV__Redis self, const redisAsyncContext* ac) {
    ngx_queue_t* q;
    for (q = ngx_queue_head(&self->cb_queue);
         q != ngx_queue_sentinel(&self->cb_queue);
         q = ngx_queue_next(q)) {
        ev_redis_cb_t* cbt = ngx_queue_data(q, ev_redis_cb_t, queue);
        if (cbt->ac != ac || cbt->persist || cbt->skipped || cbt->detached) continue;
        cbt->detached = 1;
        self->pending_detached++;
    }
}

static void drop_pending(EV__Redis self, const ev_redis_cb_t* cbt) {
    self->pending_count--;
    if (cbt->detached) self->pending_detached--;
}

/* a timeout sets err before hiredis fails the outstanding replies, an I/O
 * error DISCONNECTING */
static int ac_dying(const redisAsyncContext* ac) {
    return ac->c.err || (ac->c.flags & (REDIS_DISCONNECTING | REDIS_FREEING));
}

static int at_max_pending(const EV__Redis self) {
    return self->max_pending > 0
        && self->pending_count - self->pending_detached >= self->max_pending;
}

/* only_ac (NULL = all) spares cbts a draining old context still references.
 * Collected first: callbacks may modify cb_queue. */
static void remove_cb_queue_sv(EV__Redis self, SV* error_sv,
                               const redisAsyncContext* only_ac) {
    ngx_queue_t local_queue;
    ngx_queue_t* q;
    ngx_queue_t* next;
    ev_redis_cb_t* cbt;

    if (self->in_cb_cleanup) {
        return;
    }

    self->in_cb_cleanup = 1;

    ngx_queue_init(&local_queue);
    for (q = ngx_queue_head(&self->cb_queue);
         q != ngx_queue_sentinel(&self->cb_queue);
         q = next) {
        next = ngx_queue_next(q);
        cbt = ngx_queue_data(q, ev_redis_cb_t, queue);

        if (cbt->running) continue;
        if (NULL != only_ac && cbt->ac != only_ac) continue;

        ngx_queue_remove(q);
        ngx_queue_insert_tail(&local_queue, q);
        if (!cbt->persist) drop_pending(self, cbt);
    }

    while (!ngx_queue_empty(&local_queue)) {
        q = ngx_queue_head(&local_queue);
        cbt = ngx_queue_data(q, ev_redis_cb_t, queue);
        ngx_queue_remove(q);

        if (NULL != cbt->cb) {
            if (NULL != error_sv) {
                invoke_callback_error(cbt->cb, error_sv);
            }
            SvREFCNT_dec(cbt->cb);
        }
        free_cb_entry(cbt);
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
    txn_unref(wt->txn);
    Safefree(wt);
}

/* Moves the waiting commands to list; call it before any callback or handler
 * runs, so what those queue meanwhile stays queued, with a timer of its own. */
static void take_wait_queue(EV__Redis self, ngx_queue_t* list) {
    ngx_queue_t* q;
    while (self->waiting_count) {
        q = oldest_waiting(self);
        ngx_queue_remove(q);
        ngx_queue_insert_tail(list, q);
        self->waiting_count--;
    }
    stop_waiting_timer(self);
}

/* Shared by setup and backlog: only transactions with submitted commands fail. */
static void take_txn_wait_queue(EV__Redis self, ngx_queue_t* list) {
    ngx_queue_t* lists[3];
    ngx_queue_t* q;
    ngx_queue_t* next;
    ev_redis_wait_t* wt;
    int i;
    lists[0] = &self->wait_queue;
    lists[1] = &self->setup_queue;
    lists[2] = &self->resume_setup_queue;
    for (i = 0; i < 3; i++) {
        for (q = ngx_queue_head(lists[i]);
             q != ngx_queue_sentinel(lists[i]);
             q = next) {
            next = ngx_queue_next(q);
            wt = ngx_queue_data(q, ev_redis_wait_t, queue);
            if (NULL != wt->txn && wt->txn->started) {
                ngx_queue_remove(q);
                ngx_queue_insert_tail(list, q);
                self->waiting_count--;
            }
        }
    }
    if (!self->waiting_count) stop_waiting_timer(self);
}

/* A retained, open transaction still owns subsequent issued commands. */
static void rederive_span(EV__Redis self) {
    ngx_queue_t* lists[3];
    ngx_queue_t* q;
    int i;
    txn_unref(self->issued_txn);
    self->issued_txn = NULL;
    lists[0] = &self->wait_queue;
    lists[1] = &self->setup_queue;
    lists[2] = &self->resume_setup_queue;
    for (i = 0; i < 3; i++) {
        for (q = ngx_queue_head(lists[i]);
             q != ngx_queue_sentinel(lists[i]);
             q = ngx_queue_next(q)) {
            ev_redis_txn_t* txn = ngx_queue_data(q, ev_redis_wait_t, queue)->txn;
            if (NULL != txn && !txn->closed) {
                self->issued_txn = txn_ref(txn);
                return;
            }
        }
    }
}

/* in_wait_cleanup makes skip_waiting and skip_pending from these callbacks
 * leave the rest to this batch */
static void fail_wait_list(EV__Redis self, ngx_queue_t* list, SV* error_sv) {
    ngx_queue_t* q;
    ev_redis_wait_t* wt;
    int nested = self->in_wait_cleanup;

    self->in_wait_cleanup = 1;
    while (!ngx_queue_empty(list)) {
        q = ngx_queue_head(list);
        wt = ngx_queue_data(q, ev_redis_wait_t, queue);
        ngx_queue_remove(q);
        if (NULL != wt->cb) {
            invoke_callback_error(wt->cb, error_sv);
        }
        free_wait_entry(wt);
    }
    self->in_wait_cleanup = nested;
}

static void clear_wait_queue_sv(EV__Redis self, SV* error_sv) {
    ngx_queue_t list;
    ngx_queue_init(&list);
    take_wait_queue(self, &list);
    rederive_span(self);
    fail_wait_list(self, &list, error_sv);
}

/* redisFree() hook of a tracked context: hiredis hands back its own node */
static void drain_node_free(void* privdata) {
    ev_redis_drain_t* dn = (ev_redis_drain_t*)privdata;
    ngx_queue_remove(&dn->queue);
    Safefree(dn);
}

/* A context hiredis may tear down after self->ac is nulled (deferred
 * disconnect, failed connect); it still holds data == self and cbts. */
static void track_draining(EV__Redis self, redisAsyncContext* ac) {
    ev_redis_drain_t* dn;
    /* a handler run by the teardown may call disconnect() again */
    if (NULL != ac->c.privdata) return;
    Newx(dn, 1, ev_redis_drain_t);
    dn->ac = ac;
    dn->connection_gen = self->connection_gen;
    ngx_queue_insert_tail(&self->drain_queue, &dn->queue);
    ac->c.privdata = dn;
    ac->c.free_privdata = drain_node_free;
}

static void untrack_draining(redisAsyncContext* ac) {
    ev_redis_drain_t* dn = (ev_redis_drain_t*)ac->c.privdata;
    if (NULL == dn) return;
    ac->c.privdata = NULL;
    ac->c.free_privdata = NULL;
    drain_node_free(dn);
}

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
static SV* EV__redis_decode_reply(redisReply* reply, int* truncated);
/* bounds C-stack recursion on deeply nested replies from a hostile server */
#define EV_REDIS_MAX_REPLY_DEPTH 512
static SV* decode_reply_depth(redisReply* reply, int depth, int* truncated);

static void clear_connection_params(EV__Redis self) {
    if (NULL != self->host) { Safefree(self->host); self->host = NULL; }
    if (NULL != self->path) { Safefree(self->path); self->path = NULL; }
}

/* C-entry callbacks need their own ENTER/SAVETMPS, or mortals pile up until EV::run returns */

static void reconnect_timer_cb(EV_P_ ev_timer* w, int revents) {
    EV__Redis self = (EV__Redis)w->data;

    (void)loop;
    (void)revents;

    if (NULL == self || self->magic != EV_REDIS_MAGIC) return;

    ENTER;
    SAVETMPS;
    self->reconnect_timer_active = 0;
    self->callback_depth++;
    do_reconnect(self);
    self->callback_depth--;
    check_destroyed(self);
    FREETMPS;
    LEAVE;
}

static void schedule_reconnect(EV__Redis self) {
    ev_tstamp delay;

    if (!self->reconnect) return;
    if (self->intentional_disconnect) return;
    if (NULL == self->loop) return;
    /* a handler already connected again or scheduled this */
    if (NULL != self->ac || self->reconnect_timer_active) return;
    if (self->max_reconnect_attempts > 0 &&
        self->reconnect_attempts >= self->max_reconnect_attempts) {
        clear_wait_queue_sv(self, sv_2mortal(newSVpv("reconnect error: max attempts reached", 0)));
        emit_error_str(self, "reconnect error: max attempts reached");
        return;
    }

    self->reconnect_attempts++;
    delay = self->reconnect_delay_ms / 1000.0;

    ev_timer_init(&self->reconnect_timer, reconnect_timer_cb, delay, 0);
    self->reconnect_timer.data = (void*)self;
    /* failures and their handlers may have left the loop's clock stale */
    ev_now_update(self->loop);
    ev_timer_start(self->loop, &self->reconnect_timer);
    self->reconnect_timer_active = 1;
}

/* the next command to dispatch waits only for outstanding transaction replies */
static int barrier_holds(EV__Redis self) {
    ngx_queue_t* q;
    ev_redis_wait_t* wt;
    if (!self->pending_multi || !self->waiting_count || NULL == self->ac
            || !(self->ac->c.flags & REDIS_CONNECTED) || ac_dying(self->ac)) return 0;
    if (!ngx_queue_empty(&self->setup_queue)) q = ngx_queue_head(&self->setup_queue);
    else if (!ngx_queue_empty(&self->resume_setup_queue)) {
        q = ngx_queue_head(&self->resume_setup_queue);
    }
    else q = ngx_queue_head(&self->wait_queue);
    wt = ngx_queue_data(q, ev_redis_wait_t, queue);
    return needs_transaction_reply(wt->persist, wt->argv[0]);
}

/* Time held for transaction replies counts toward no waiting deadline: it is
 * added to every queued_at once the hold ends. Returns 1 while it holds, 2
 * when a hold has just ended; touches no timer. */
static int barrier_update(EV__Redis self) {
    ngx_queue_t* lists[3];
    ngx_queue_t* q;
    ev_tstamp now;
    int i;

    if (NULL == self->loop) return 0;
    if (barrier_holds(self)) {
        /* ev_now is stale outside ev_run; the end-of-hold math needs the truth */
        if (0 == self->barrier_since) {
            ev_now_update(self->loop);
            self->barrier_since = ev_now(self->loop);
        }
        return 1;
    }
    if (0 == self->barrier_since) return 0;
    ev_now_update(self->loop);
    now = ev_now(self->loop);
    lists[0] = &self->wait_queue;
    lists[1] = &self->setup_queue;
    lists[2] = &self->resume_setup_queue;
    for (i = 0; i < 3; i++) {
        for (q = ngx_queue_head(lists[i]); q != ngx_queue_sentinel(lists[i]); q = ngx_queue_next(q)) {
            ev_redis_wait_t* wt = ngx_queue_data(q, ev_redis_wait_t, queue);
            wt->queued_at += now - (wt->queued_at > self->barrier_since
                                    ? wt->queued_at : self->barrier_since);
        }
    }
    self->barrier_since = 0;
    return 2;
}

/* the waiting timer is not armed during a hold: re-arm it once one ends */
static int sync_barrier(EV__Redis self) {
    int state = barrier_update(self);
    if (2 == state) schedule_waiting_timer(self);
    return 1 == state;
}

/* Head refetch each iteration: callbacks may modify the queues. */
static void expire_waiting_commands(EV__Redis self) {
    ngx_queue_t* q;
    ev_redis_wait_t* wt;
    ev_tstamp now;
    ev_tstamp timeout;

    int nested = self->in_wait_cleanup;

    if (sync_barrier(self)) return;
    now = ev_now(self->loop);
    /* snapshot: callbacks may change waiting_timeout_ms mid-batch */
    timeout = self->waiting_timeout_ms / 1000.0;

    /* like fail_wait_list: skip_waiting and the waiting half of skip_pending
     * from these callbacks leave the rest to this batch */
    self->in_wait_cleanup = 1;
    while (self->waiting_count) {
        q = oldest_waiting(self);
        wt = ngx_queue_data(q, ev_redis_wait_t, queue);

        if (now - wt->queued_at >= timeout) {
            ngx_queue_remove(q);
            self->waiting_count--;

            if (NULL != wt->txn) rederive_span(self);
            if (NULL != wt->cb) {
                invoke_callback_error(wt->cb, err_waiting_timeout);
            }

            free_wait_entry(wt);
        }
        else {
            /* FIFO with monotonic queued_at: nothing later has expired */
            break;
        }
    }
    self->in_wait_cleanup = nested;
}

static void waiting_timer_cb(EV_P_ ev_timer* w, int revents) {
    EV__Redis self = (EV__Redis)w->data;

    (void)loop;
    (void)revents;

    if (NULL == self || self->magic != EV_REDIS_MAGIC) return;

    ENTER;
    SAVETMPS;
    self->waiting_timer_active = 0;
    self->callback_depth++;
    expire_waiting_commands(self);
    /* connect_cb sends the backlog once on_connect has run */
    if (self->magic == EV_REDIS_MAGIC && NULL != self->ac
            && (self->ac->c.flags & REDIS_CONNECTED)) send_next_waiting(self);
    schedule_waiting_timer(self);
    self->callback_depth--;
    check_destroyed(self);
    FREETMPS;
    LEAVE;
}

static void schedule_waiting_timer(EV__Redis self) {
    ngx_queue_t* q;
    ev_redis_wait_t* wt;
    ev_tstamp now, expires_at, delay;

    stop_waiting_timer(self);

    if (NULL == self->loop) return;
    if (self->waiting_timeout_ms <= 0) return;
    if (!self->waiting_count) return;
    if (1 == barrier_update(self)) return;

    q = oldest_waiting(self);
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
        return;
    }

    if (NULL != self->ac) {
        return;
    }

    self->intentional_disconnect = 0;
    self->monitoring = 0;
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
    ngx_queue_t doomed;
    int owned;

    if (NULL == self || self->magic != EV_REDIS_MAGIC) return;

    /* Not owned: disconnect() already tracked c; re-tracking would strand a
     * node, and touching self would clobber a replacement connection. */
    owned = (self->ac == c);

    ENTER;
    SAVETMPS;
    self->callback_depth++;

    if (REDIS_OK != status) {
        if (owned) {
            /* hiredis fires c's pending replies and frees it after we return */
            track_draining(self, c);
            self->ac = NULL;
            self->monitoring = 0;
            ngx_queue_init(&doomed);
            if (!self->reconnect || !self->resume_waiting_on_reconnect
                    || self->intentional_disconnect) {
                take_wait_queue(self, &doomed);
            }
            rederive_span(self);
            emit_error_str(self, conn_errstr(c, "connect failed"));
            fail_wait_list(self, &doomed, sv_2mortal(newSVpv(
                conn_errstr(c, "connect failed"), 0)));
            schedule_reconnect(self);
        }
    }
    else if (owned) {
        self->reconnect_attempts = 0;
        demote_setup_waiters(self);

        if (NULL != self->connect_handler) {
            int prev = self->in_connect_handler;
            ev_redis_txn_t* backlog_txn = self->issued_txn;
            self->issued_txn = NULL;
            self->in_connect_handler = 1;
            call_void_handler(self->connect_handler, "connect handler");
            self->in_connect_handler = prev;
            /* Fresh setup precedes, and is independent of, the retained backlog. */
            if (NULL == self->issued_txn && self->magic == EV_REDIS_MAGIC && self->ac == c) {
                rederive_span(self);
            }
            txn_unref(backlog_txn);
        }

        send_next_waiting(self);
    }

    redisLibevResumeParked(c);
    self->callback_depth--;
    check_destroyed(self);
    FREETMPS;
    LEAVE;
}

static void EV__redis_disconnect_cb(const redisAsyncContext* c, int status) {
    EV__Redis self = (EV__Redis)c->data;
    ev_redis_drain_t* dn;
    UV connection_gen;
    SV* error_sv;
    ngx_queue_t doomed;
    int should_reconnect = 0;
    int was_intentional;
    int will_reconnect;
    int keep;

    if (NULL == self || self->magic != EV_REDIS_MAGIC) return;

    dn = (ev_redis_drain_t*)c->c.privdata;
    connection_gen = NULL != dn ? dn->connection_gen : self->connection_gen;
    /* c is being freed: a DESTROY from on_disconnect must not free it again */
    untrack_draining((redisAsyncContext*)c);

    /* a replacement may already have failed, or been disconnected too: NULL
     * ac does not make an older draining context the current connection */
    if (connection_gen != self->connection_gen
            || (self->ac != NULL && self->ac != c)) {
        return;
    }

    was_intentional = self->intentional_disconnect;
    self->intentional_disconnect = 0;

    self->ac = NULL;
    self->monitoring = 0;
    (void)sync_barrier(self);
    ENTER;
    SAVETMPS;
    self->callback_depth++;

    if (REDIS_OK == status) {
        error_sv = err_disconnected;
    }
    else {
        error_sv = sv_2mortal(newSVpv(
            conn_errstr(c, "disconnected"), 0));
        if (!was_intentional) {
            should_reconnect = 1;
        }
    }

    /* the settings as the connection is lost decide what is kept; a
     * transaction does not survive it, so its waiting fragments fail with it
     * instead of replaying orphaned */
    ngx_queue_init(&doomed);
    keep = should_reconnect && self->reconnect && self->resume_waiting_on_reconnect;
    if (!keep) {
        take_wait_queue(self, &doomed);
    }
    else {
        take_txn_wait_queue(self, &doomed);
    }
    /* before any callback issues: it must see the span the takes left */
    rederive_span(self);

    if (REDIS_OK != status) {
        emit_error_str(self, conn_errstr(c, "disconnected"));
    }
    call_void_handler(self->disconnect_handler, "disconnect handler");

    /* a handler destroyed the object: only these are left to fail */
    if (self->magic != EV_REDIS_MAGIC) {
        fail_wait_list(self, &doomed, error_sv);
        self->callback_depth--;
        check_destroyed(self);
        FREETMPS;
        LEAVE;
        return;
    }

    /* a handler tried connecting again, even if that attempt already failed:
     * keep cb_queue and the commands queued since */
    if (connection_gen != self->connection_gen
            || (self->ac != NULL && self->ac != c)) {
        fail_wait_list(self, &doomed, error_sv);
        self->callback_depth--;
        check_destroyed(self);
        FREETMPS;
        LEAVE;
        return;
    }

    remove_cb_queue_sv(self, error_sv, c);

    will_reconnect = should_reconnect && !self->intentional_disconnect && self->reconnect;
    /* a handler called off the reconnect: the kept ones go too, before any
     * callback runs, so what the callbacks queue stays */
    if (keep && !will_reconnect) {
        take_wait_queue(self, &doomed);
        rederive_span(self);
    }
    fail_wait_list(self, &doomed, error_sv);

    if (will_reconnect) {
        schedule_reconnect(self);
    }

    self->callback_depth--;
    check_destroyed(self);
    FREETMPS;
    LEAVE;
}

static void EV__redis_push_cb(redisAsyncContext* ac, void* reply_ptr) {
    EV__Redis self = (EV__Redis)ac->data;
    redisReply* reply = (redisReply*)reply_ptr;

    if (NULL == self || self->magic != EV_REDIS_MAGIC) return;
    SV* handler = self->push_handler;
    if (NULL == handler || NULL == reply) return;
    SvREFCNT_inc_simple_void_NN(handler);

    self->callback_depth++;

    {
        dSP;

        ENTER;
        SAVETMPS;
        save_scalar(PL_errgv);

        int truncated = 0;
        SV* decoded = sv_2mortal(EV__redis_decode_reply(reply, &truncated));

        if (truncated) {
            /* on_push takes the message only, so a dropped one errors here */
            emit_error_str(self, "reply exceeds maximum nesting depth");
        }
        else {
            PUSHMARK(SP);
            XPUSHs(decoded);
            PUTBACK;

            call_sv(handler, G_DISCARD | G_EVAL);
            if (SvTRUE(ERRSV)) {
                warn_exception("push handler", ERRSV);
            }
        }

        FREETMPS;
        LEAVE;
    }

    SvREFCNT_dec(handler);
    redisLibevResumeParked(ac);
    self->callback_depth--;
    check_destroyed(self);
}

static void pre_connect_common(EV__Redis self, redisOptions* opts) {
    self->connection_gen++;
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
    /* not REDIS_OPT_SET_SOCK_CLOEXEC: its c->flags bit is REDIS_REUSEADDR, so
     * each would turn on the other; post_connect_setup sets FD_CLOEXEC */
    if (self->reuseaddr) {
        opts->options |= REDIS_OPT_REUSEADDR;
    }
    if (NULL != self->source_addr && NULL == self->path) {
        opts->endpoint.tcp.source_addr = self->source_addr;
    }
}

static int setup_failed(EV__Redis self, SV* err) {
    /* own copy: on_error's @_ aliases err, so the handler can change it */
    SV* wait_err = sv_2mortal(newSVsv(err));
    ngx_queue_t doomed;
    redisAsyncFree(self->ac);
    self->ac = NULL;
    ngx_queue_init(&doomed);
    if (!self->reconnect || !self->resume_waiting_on_reconnect
            || self->intentional_disconnect) {
        take_wait_queue(self, &doomed);
    }
    rederive_span(self);
    emit_error(self, err);
    fail_wait_list(self, &doomed, wait_err);
    return REDIS_ERR;
}

/* On failure: frees and nulls self->ac, then emits the error. */
static int post_connect_setup(EV__Redis self, const char* err_prefix) {
    self->ac->data = (void*)self;
    self->in_multi = 0;
    self->pending_multi = 0;
    (void)sync_barrier(self);
    if (self->ac->c.fd != REDIS_INVALID_FD) {
        fcntl(self->ac->c.fd, F_SETFD, self->cloexec ? FD_CLOEXEC : 0);
    }

    /* failed inside the connect call: fd may be -1, never hand it to libev */
    if (self->ac->err) {
        return setup_failed(self, sv_2mortal(newSVpvf("%s: %s",
            err_prefix, self->ac->errstr)));
    }

#ifdef EV_REDIS_SSL
    if (NULL != self->ssl_ctx
            && REDIS_OK != redisInitiateSSLWithContext(&self->ac->c, self->ssl_ctx)) {
        return setup_failed(self, sv_2mortal(newSVpvf("%s: SSL initiation failed: %s",
            err_prefix, self->ac->errstr[0] ? self->ac->errstr : "unknown error")));
    }
#endif

    /* on failure it sets c.err, which breaks the first write */
    if (self->keepalive > 0 && self->ac->c.connection_type == REDIS_CONN_TCP
            && REDIS_OK != redisEnableKeepAliveWithInterval(&self->ac->c, self->keepalive)) {
        return setup_failed(self, sv_2mortal(newSVpvf("%s: %s",
            err_prefix, self->ac->c.errstr)));
    }
    /* hiredis closes the fd when this fails */
    if (self->tcp_user_timeout > 0 && self->ac->c.connection_type == REDIS_CONN_TCP
            && REDIS_OK != redisSetTcpUserTimeout(&self->ac->c, self->tcp_user_timeout)) {
        return setup_failed(self, sv_2mortal(newSVpvf("%s: %s",
            err_prefix, self->ac->c.errstr)));
    }

    if (REDIS_OK != redisLibevAttach(self->loop, self->ac)) {
        return setup_failed(self, sv_2mortal(newSVpvf("%s: cannot attach libev",
            err_prefix)));
    }
    redisLibevUseNetWrite(&self->ac->c);

    if (self->priority != 0) {
        redisLibevSetPriority(self->ac, self->priority);
    }

    redisAsyncSetConnectCallbackNC(self->ac, EV__redis_connect_cb);
    redisAsyncSetDisconnectCallback(self->ac, EV__redis_disconnect_cb);
    if (NULL != self->push_handler) {
        redisAsyncSetPushCallback(self->ac, EV__redis_push_cb);
    }

    return REDIS_OK;
}

/* on_error may drop the last reference to self or connect again */
static void connect_setup_or_retry(EV__Redis self) {
    self->callback_depth++;
    if (REDIS_OK != post_connect_setup(self, "connect error")) {
        schedule_reconnect(self);
    }
    self->callback_depth--;
    check_destroyed(self);
}

static SV* decode_reply_depth(redisReply* reply, int depth, int* truncated) {
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
#if IVSIZE < 8
            /* a 32-bit IV: an NV stringifies with 15 digits, so from 1e15 on
             * only a string keeps every digit */
            if (reply->integer > IV_MAX || reply->integer < IV_MIN) {
                if (reply->integer >= 1000000000000000LL || reply->integer <= -1000000000000000LL) {
                    char buf[24];
                    snprintf(buf, sizeof(buf), "%lld", reply->integer);
                    res = newSVpv(buf, 0);
                }
                else {
                    res = newSVnv((NV)reply->integer);
                }
                break;
            }
#endif
            res = newSViv((IV)reply->integer);
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
                *truncated = 1;
                res = newRV_noinc((SV*)av);
                break;
            }
            if (reply->elements > 0) {
                av_extend(av, (SSize_t)(reply->elements - 1));
                for (i = 0; i < reply->elements; i++) {
                    if (NULL != reply->element[i]) {
                        av_push(av, decode_reply_depth(reply->element[i], depth + 1, truncated));
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

static SV* EV__redis_decode_reply(redisReply* reply, int* truncated) {
    *truncated = 0;
    return decode_reply_depth(reply, 0, truncated);
}

static void EV__redis_reply_cb_body(redisAsyncContext* c, void* reply, void* privdata) {
    EV__Redis self = (EV__Redis)c->data;
    ev_redis_cb_t* cbt;
    ev_redis_cb_t* prev_cb;
    SV* sv_reply;
    SV* sv_err;

    cbt = (ev_redis_cb_t*)privdata;
    if (cbt->persist) sub_note_reply(c, cbt, (redisReply*)reply);
    if (cbt->proto_cmd && NULL != reply) note_protocol_reply(c, (redisReply*)reply);
    /* a monitor stream holds no errors: the server refused MONITOR, and hiredis
     * must not re-queue the record for the next reply */
    if (cbt->monitor && NULL != reply && ((redisReply*)reply)->type == REDIS_REPLY_ERROR) {
        c->c.flags &= ~REDIS_MONITORING;
        cbt->sub_count = 0;
        if (NULL != self && self->magic == EV_REDIS_MAGIC && self->ac == c) self->monitoring = 0;
    }
    if (cbt->multi && NULL != self && self->magic == EV_REDIS_MAGIC && self->ac == c) {
        redisReply* rr = (redisReply*)reply;
        if (NULL != rr) {
            self->pending_multi--;
            if (!self->pending_multi) (void)sync_barrier(self);
            if (cbt->multi == EV_REDIS_MULTI) {
                if (rr->type == REDIS_REPLY_STATUS && 0 == ascii_strcasecmp(rr->str, "ok")) {
                    self->in_multi = 1;
                }
            }
            /* other refusals of EXEC, DISCARD or RESET leave it open */
            else if (rr->type != REDIS_REPLY_ERROR || ends_transaction(rr)) {
                self->in_multi = 0;
            }
        }
    }
    /* A refused first WATCH creates no state; earlier successful WATCHes remain. */
    if (cbt->watch && NULL != self && self->magic == EV_REDIS_MAGIC && self->ac == c
            && NULL != reply && NULL != cbt->txn) {
        if (((redisReply*)reply)->type != REDIS_REPLY_ERROR) {
            cbt->txn->watched = 1;
        }
        else if (!cbt->txn->watched && !cbt->txn->multi_started) {
            cbt->txn->started = 0;
            cbt->txn->closed = 1;
            if (self->issued_txn == cbt->txn) {
                txn_unref(self->issued_txn);
                self->issued_txn = NULL;
            }
        }
    }

    if (cbt->skipped) {
        int resume_waiting = cbt->multi && NULL != reply && NULL != self
            && self->magic == EV_REDIS_MAGIC && self->ac == c && !self->pending_multi;
        if (!cbt->persist || cbt->sub_count <= 0) free_cb_entry(cbt);
        if (resume_waiting) {
            self->callback_depth++;
            send_next_waiting(self);
            self->callback_depth--;
            check_destroyed(self);
        }
        return;
    }

    /* DESTROY detached this context */
    if (self == NULL) {
        if (NULL != cbt->cb) {
            invoke_callback_error(cbt->cb,
                sv_2mortal(newSVpv(conn_errstr(c, "disconnected"), 0)));
            SvREFCNT_dec(cbt->cb);
            cbt->cb = NULL;
        }
        if (!cbt->persist || cbt->sub_count <= 0) free_cb_entry(cbt);
        return;
    }

    if (self->magic == EV_REDIS_FREED) {
        if (NULL != cbt->cb) {
            self->callback_depth++;
            invoke_callback_error(cbt->cb, sv_2mortal(newSVpv(conn_errstr(c, "disconnected"), 0)));
            self->callback_depth--;
            SvREFCNT_dec(cbt->cb);
            cbt->cb = NULL;
        }
        if (!cbt->persist || cbt->sub_count <= 0) {
            ngx_queue_remove(&cbt->queue);
            free_cb_entry(cbt);
        }
        check_destroyed(self);
        return;
    }

    /* corrupt self: leave its queue alone */
    if (self->magic != EV_REDIS_MAGIC) {
        if (NULL != cbt->cb) SvREFCNT_dec(cbt->cb);
        free_cb_entry(cbt);
        return;
    }

    prev_cb = self->current_cb;
    self->current_cb = cbt;
    cbt->running = 1;
    self->callback_depth++;

    if (NULL != cbt->cb) {
        if (NULL == reply) {
            sv_err = sv_2mortal(newSVpv(
                conn_errstr(c, "disconnected"), 0));
            invoke_callback_error(cbt->cb, sv_err);
        }
        else {
            dSP;

            ENTER;
            SAVETMPS;
            save_scalar(PL_errgv);

            int truncated = 0;

            PUSHMARK(SP);
            EXTEND(SP, 2);
            sv_reply = sv_2mortal(EV__redis_decode_reply((redisReply*)reply, &truncated));
            if (((redisReply*)reply)->type == REDIS_REPLY_ERROR || truncated) {
                PUSHs(sv_newmortal());
                PUSHs(truncated
                    ? sv_2mortal(newSVpv("reply exceeds maximum nesting depth", 0))
                    : sv_reply);
            }
            else {
                PUSHs(sv_reply);
            }
            PUTBACK;

            call_sv(cbt->cb, G_DISCARD | G_EVAL);
            if (SvTRUE(ERRSV)) {
                warn_exception("command callback", ERRSV);
            }

            FREETMPS;
            LEAVE;
        }
    }

    self->callback_depth--;
    self->current_cb = prev_cb;
    cbt->running = 0;

    /* DESTROY ran in the callback: hiredis frees the context without repushing
     * this record */
    if (self->magic == EV_REDIS_FREED) {
        if (NULL != cbt->cb) {
            SvREFCNT_dec(cbt->cb);
            cbt->cb = NULL;
        }
        if (!cbt->persist || cbt->monitor || cbt->sub_count <= 0) free_cb_entry(cbt);
        check_destroyed(self);
        return;
    }

    /* disconnect() from the callback: hiredis frees c without re-queuing the
     * MONITOR record, so this is its last call */
    if (cbt->monitor && NULL != reply && (c->c.flags & REDIS_FREEING)) {
        ngx_queue_remove(&cbt->queue);
        self->callback_depth++;
        if (NULL != cbt->cb) {
            invoke_callback_error(cbt->cb, sv_2mortal(newSVpv(
                conn_errstr(c, "disconnected"), 0)));
            SvREFCNT_dec(cbt->cb);
        }
        free_cb_entry(cbt);
        self->callback_depth--;
        check_destroyed(self);
        return;
    }

    if (cbt->skipped) {
        /* skip_pending already reinitialised the node and adjusted pending_count */
        ngx_queue_remove(&cbt->queue);
        if (cbt->persist && cbt->sub_count > 0) return;
        free_cb_entry(cbt);
        self->callback_depth++;
        send_next_waiting(self);
        self->callback_depth--;
        check_destroyed(self);
        return;
    }

    if (cbt->persist) {
        if (cbt->sub_count <= 0) {
            ngx_queue_remove(&cbt->queue);
            self->callback_depth++;
            if (NULL != cbt->cb) SvREFCNT_dec(cbt->cb);
            free_cb_entry(cbt);
            self->callback_depth--;
            check_destroyed(self);
        }
        return;
    }

    if (0 == cbt->persist) {
        /* Unqueue before SvREFCNT_dec: freeing the closure may run DESTROY,
         * whose sweep would double-free a still-queued cbt. */
        ngx_queue_remove(&cbt->queue);
        drop_pending(self, cbt);
        self->callback_depth++;
        if (NULL != cbt->cb) SvREFCNT_dec(cbt->cb);
        free_cb_entry(cbt);
        /* NULL reply: connection dying, disconnect_cb owns the wait queue;
         * unless it is an older one and a newer connection took over */
        if (reply != NULL || (NULL != self->ac && self->ac != c)) {
            send_next_waiting(self);
        }
        self->callback_depth--;
        check_destroyed(self);
    }
}

static void EV__redis_reply_cb(redisAsyncContext* c, void* reply, void* privdata) {
    ENTER;
    SAVETMPS;
    EV__redis_reply_cb_body(c, reply, privdata);
    FREETMPS;
    LEAVE;
    redisLibevResumeParked(c);
}

/* A resubscribe replaces unsubscribe_sent: retain the confirmation still due. */
static void retain_unsubscribe(redisLibevEvents* e, int pattern,
                               const char* name, size_t len, redisCallback* sub) {
    HV* counts;
    if (!sub->unsubscribe_sent) return;
    counts = e->unsubs[pattern];
    if (NULL == counts) counts = e->unsubs[pattern] = newHV();
    if (!hv_exists(counts, name, (I32)len)) {
        (void)hv_store(counts, name, (I32)len, newSViv(1), 0);
    }
}

static void track_unsubscribe(redisLibevEvents* e, int pattern,
                              const char* name, size_t len, redisCallback* sub, int named) {
    HV* counts = e->unsubs[pattern];
    SV** count = NULL != counts ? hv_fetch(counts, name, (I32)len, 0) : NULL;
    if (NULL != count) {
        sv_setiv(*count, SvIV(*count) + 1);
        sub->pending_subs++;
    }
    else if (sub->unsubscribe_sent) {
        if (NULL == counts) counts = e->unsubs[pattern] = newHV();
        (void)hv_store(counts, name, (I32)len, newSViv(2), 0);
        sub->pending_subs++;
    }
    if (named) sub->unsubscribe_sent = 1;
}

/* Keep named confirmations in the dictionary even when no subscription exists.
 * Extra confirmations borrow pending_subs slots until their preceding reply. */
static int prepare_unsubscribe(EV__Redis self, int pattern,
                                int argc, const char** argv, const size_t* argvlen) {
    redisAsyncContext* ac = self->ac;
    redisLibevEvents* e = (redisLibevEvents*)ac->ev.data;
    dict* d = pattern ? ac->sub.patterns : ac->sub.channels;
    dictEntry* he;
    int i;

    if (argc == 1) {
        dictIterator it;
        dictInitIterator(&it, d);
        while (NULL != (he = dictNext(&it))) {
            redisCallback* sub = (redisCallback*)dictGetEntryVal(he);
            if (!sub->unsubscribe_sent) {
                sds key = (sds)dictGetEntryKey(he);
                track_unsubscribe(e, pattern, key, sdslen(key), sub, 0);
            }
        }
        return REDIS_OK;
    }

    for (i = 1; i < argc; i++) {
        he = sub_entry(d, argv[i], argvlen[i]);
        if (NULL == he) {
            ev_redis_cb_t* cbt;
            redisCallback stub;
            sds key = sdsnewlen(argv[i], argvlen[i]);
            if (NULL == key) goto oom;
            Newxz(cbt, 1, ev_redis_cb_t);
            cbt->ac = ac;
            cbt->persist = 1;
            cbt->sub_count = 1;
            cbt->seq = ++self->cb_seq;
            memset(&stub, 0, sizeof(stub));
            stub.fn = EV__redis_reply_cb;
            stub.privdata = (void*)cbt;
            if (DICT_OK != dictAdd(d, key, &stub)) {
                sdsfree(key);
                free_cb_entry(cbt);
                goto oom;
            }
            ngx_queue_insert_tail(&self->cb_queue, &cbt->queue);
            he = sub_entry(d, argv[i], argvlen[i]);
        }
        track_unsubscribe(e, pattern, argv[i], argvlen[i],
            (redisCallback*)dictGetEntryVal(he), 1);
    }
    return REDIS_OK;

oom:
    __redisSetError(&ac->c, REDIS_ERR_OOM, "Out of memory");
    ac->err = ac->c.err;
    ac->errstr = ac->c.errstr;
    return REDIS_ERR;
}

/* cbt must already be queued; on failure it is reported and freed. Sets
 * monitor and sub_count. */
static int submit_to_redis(EV__Redis self, ev_redis_cb_t* cbt,
                           int argc, const char** argv, const size_t* argvlen)
{
    redisCallbackFn* fn = EV__redis_reply_cb;
    void* privdata = (void*)cbt;
    const char* cmd = argv[0];
    ev_redis_cb_t** replaced = NULL;
    int nreplaced = 0, nsub = 0, i, r;
    int pattern = 0, fix_subs = 0;
    int named_unsubs = 0, pending_unsubs = 0;
    HV* seen = NULL;
    const char* refused = NULL;

    cbt->ac = self->ac;
    cbt->monitor = cbt->persist && is_monitor_command(cmd);
    cbt->watch = 0 == ascii_strcasecmp(cmd, "watch");
    cbt->sub_count = cbt->monitor ? 1 : 0;
    cbt->proto_cmd = 0 == ascii_strcasecmp(cmd, "hello") || 0 == ascii_strcasecmp(cmd, "reset");
    cbt->multi = transaction_command(cmd);

    /* queued, the server answers QUEUED, which hiredis would hand to the next
     * command's callback */
    if (cbt->persist && self->in_multi) {
        refused = "pub/sub and MONITOR are not supported inside MULTI";
    }
    /* its protocol switch would come inside EXEC's reply, unseen */
    else if (self->in_multi && 0 == ascii_strcasecmp(cmd, "hello")) {
        refused = "HELLO is not supported inside MULTI";
    }
    /* a RESET that waited may meet a subscription on_connect made since */
    else if (!cbt->persist && 0 == ascii_strcasecmp(cmd, "reset")
             && (self->ac->c.flags & REDIS_SUBSCRIBED)) {
        refused = "RESET is not supported on a subscribed connection";
    }
    /* like RESET: the server refuses it, which would kill the connection */
    else if (!cbt->persist && 0 == ascii_strcasecmp(cmd, "hello")
             && (self->ac->c.flags & REDIS_SUBSCRIBED)) {
        refused = "HELLO is not supported on a subscribed connection";
    }
    /* hiredis keeps no callback for unsubscribe (replies go to the subscribe
     * callback): pass NULL so it holds no dangling cbt. */
    else if (cbt->persist && is_unsubscribe_command(cmd)) {
        fn = NULL;
        privdata = NULL;
        if (self->ac->c.flags & REDIS_SUBSCRIBED) {
            pattern = cmd[0] == 'p' || cmd[0] == 'P';
            pending_unsubs = self->ac->sub.pending_unsubs;
            named_unsubs = argc > 1;
            if (REDIS_OK != prepare_unsubscribe(self, pattern, argc, argv, argvlen)) {
                refused = "Out of memory";
            }
        }
        else {
            /* hiredis refuses these without an error string */
            refused = "not subscribed";
        }
    }
    else if (cbt->persist && !cbt->monitor) {
        /* each distinct name gets one entry, taken over from any older cbt */
        pattern = (cmd[0] == 'p' || cmd[0] == 'P');
        seen = argc > 2 ? newHV() : NULL;
        ev_redis_cb_t* owner;
        redisCallback* sub;

        Newx(replaced, argc, ev_redis_cb_t*);
        for (i = 1; i < argc; i++) {
            if (NULL != seen) {
                SV** count = hv_fetch(seen, argv[i], (I32)argvlen[i], 0);
                if (NULL != count) {
                    IV n = SvIV(*count);
                    if (n > 0) {
                        (void)hv_store(seen, argv[i], (I32)argvlen[i], newSViv(n + 1), 0);
                        fix_subs = 1;
                    }
                    continue;
                }
            }
            nsub++;
            owner = sub_owner(self->ac, pattern, argv[i], argvlen[i], &sub);
            if (NULL != sub) {
                retain_unsubscribe((redisLibevEvents*)self->ac->ev.data,
                    pattern, argv[i], argvlen[i], sub);
            }
            if (NULL != seen) {
                int n = NULL != sub ? sub->pending_subs + 1 : 1;
                (void)hv_store(seen, argv[i], (I32)argvlen[i], newSViv(n), 0);
                if (n > 1) fix_subs = 1;
            }
            if (NULL != owner) replaced[nreplaced++] = owner;
        }
    }
    if (NULL != refused) {
        r = REDIS_ERR;
    }
    else {
        if (!cbt->persist || cbt->monitor) {
            redisLibevExpectNewReply(self->ac);
        }
        /* hiredis classifies these with locale-sensitive libc comparisons. */
        if (cbt->persist) {
            argv[0] = cbt->monitor ? "monitor" : fn == NULL
                ? (pattern ? "punsubscribe" : "unsubscribe")
                : (pattern ? "psubscribe" : "subscribe");
        }
        r = redisAsyncCommandArgv(self->ac, fn, privdata, argc, argv, argvlen);
        argv[0] = cmd;
    }

    if (REDIS_OK == r && cbt->multi) self->pending_multi++;
    if (REDIS_OK == r && NULL != cbt->txn) {
        cbt->txn->started = 1;
        if (cbt->multi == EV_REDIS_MULTI) cbt->txn->multi_started = 1;
    }
    /* Every named reply now has an entry; pending_unsubs counts only nil replies. */
    if (REDIS_OK == r && named_unsubs) self->ac->sub.pending_unsubs = pending_unsubs;

    /* hiredis carries a repeated name's pending_subs into later new names.
     * Restore each name's own count; ordinary new subscriptions need no pass. */
    if (REDIS_OK == r && fix_subs) {
        for (i = 1; i < argc; i++) {
            redisCallback* sub;
            SV** count = hv_fetch(seen, argv[i], (I32)argvlen[i], 0);
            (void)sub_owner(self->ac, pattern, argv[i], argvlen[i], &sub);
            if (NULL != sub && NULL != count && SvIV(*count) > 0) sub->pending_subs = (int)SvIV(*count);
        }
    }
    if (NULL != seen) SvREFCNT_dec((SV*)seen);

    if (REDIS_OK == r && NULL != replaced) {
        int ndone = 0;
        cbt->sub_count = nsub;
        /* counts are exact, so each old cbt reaches 0 once */
        for (i = 0; i < nreplaced; i++) {
            if (--replaced[i]->sub_count == 0) replaced[ndone++] = replaced[i];
        }
        for (i = 0; i < ndone; i++) {
            ev_redis_cb_t* old = replaced[i];
            if (old->running) continue;  /* reply_cb frees it once the callback returns */
            ngx_queue_remove(&old->queue);
            /* mortal: a DESTROY this triggers runs after the current statement */
            if (NULL != old->cb) sv_2mortal(old->cb);
            free_cb_entry(old);
        }
    }
    Safefree(replaced);

    if (REDIS_OK != r) {
        ngx_queue_remove(&cbt->queue);
        if (!cbt->persist) drop_pending(self, cbt);

        if (NULL != cbt->cb) {
            invoke_callback_error(cbt->cb, sv_2mortal(newSVpv(
                NULL != refused ? refused
                : (self->ac && self->ac->errstr[0]) ? self->ac->errstr : "command failed", 0)));
            SvREFCNT_dec(cbt->cb);
        }
        free_cb_entry(cbt);
    } else if (fn == NULL) {
        ngx_queue_remove(&cbt->queue);
        if (NULL != cbt->cb) SvREFCNT_dec(cbt->cb);
        free_cb_entry(cbt);
    }

    return r;
}

static void send_next_waiting(EV__Redis self) {
    ngx_queue_t* q;
    ev_redis_wait_t* wt;
    ev_redis_cb_t* cbt;

    /* setters and local cancellation must not send backlog before setup finishes */
    if (self->in_connect_handler) return;

    while (1) {
        /* a failed submit's callback may change any of these */
        if (NULL == self->ac || self->intentional_disconnect) return;
        /* dying (a timeout sets err before the flags): its disconnect_cb
         * decides which to keep */
        if ((self->ac->c.flags & (REDIS_DISCONNECTING | REDIS_FREEING))
                || self->ac->c.err) return;
        /* a failed attempt must keep them */
        if (!(self->ac->c.flags & REDIS_CONNECTED)
                && self->reconnect && self->resume_waiting_on_reconnect) return;
        if (!self->waiting_count) return;
        if (!ngx_queue_empty(&self->setup_queue)) q = ngx_queue_head(&self->setup_queue);
        else if (!ngx_queue_empty(&self->resume_setup_queue)) {
            q = ngx_queue_head(&self->resume_setup_queue);
        }
        else {
            if (at_max_pending(self)) return;
            q = ngx_queue_head(&self->wait_queue);
        }
        wt = ngx_queue_data(q, ev_redis_wait_t, queue);
        if (self->pending_multi && needs_transaction_reply(wt->persist, wt->argv[0])) {
            (void)sync_barrier(self);
            return;
        }
        (void)sync_barrier(self);
        ngx_queue_remove(q);
        self->waiting_count--;

        if (self->waiting_timeout_ms > 0 && NULL != self->loop) {
            ev_now_update(self->loop);
            if (ev_now(self->loop) - wt->queued_at >= self->waiting_timeout_ms / 1000.0) {
                if (NULL != wt->txn) rederive_span(self);
                if (NULL != wt->cb) invoke_callback_error(wt->cb, err_waiting_timeout);
                free_wait_entry(wt);
                continue;
            }
        }

        Newx(cbt, 1, ev_redis_cb_t);
        cbt->cb = wt->cb;
        wt->cb = NULL;
        cbt->skipped = 0;
        cbt->running = 0;
        cbt->detached = 0;
        cbt->seq = ++self->cb_seq;
        cbt->persist = wt->persist;
        cbt->txn = txn_ref(wt->txn);
        ngx_queue_init(&cbt->queue);
        ngx_queue_insert_tail(&self->cb_queue, &cbt->queue);
        if (!cbt->persist) self->pending_count++;

        (void)submit_to_redis(self, cbt, wt->argc,
            (const char**)wt->argv, wt->argvlen);
        free_wait_entry(wt);
    }
}

MODULE = EV::Redis PACKAGE = EV::Redis

BOOT:
{
    I_EV_API("EV::Redis");
    ev_redis_stash = gv_stashpvs("EV::Redis", GV_ADD);
    {
        static int atfork_registered = 0;
        if (!atfork_registered) {
            pthread_atfork(NULL, NULL, redisLibevAtforkChild);
            atfork_registered = 1;
        }
    }

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
    ngx_queue_init(&RETVAL->setup_queue);
    ngx_queue_init(&RETVAL->resume_setup_queue);
    ngx_queue_init(&RETVAL->drain_queue);
    RETVAL->loop = loop;
    /* pin: a dropped non-default loop would free the C loop under us */
    RETVAL->loop_sv = SvREFCNT_inc(SvRV(ST(1)));
    RETVAL->cloexec = 1;
    RETVAL->reconnect_delay_ms = 1000;
}
OUTPUT:
    RETVAL

void
DESTROY(SV* self_sv);
CODE:
{
    EV__Redis self;
    SV* inner;
    redisAsyncContext* ac_to_free;
    ngx_queue_t* dq;
    ev_redis_drain_t* dn;
    int skip_cb_cleanup = 0;

    /* quietly: a hash-based or already destroyed object has nothing to free */
    if (!SvROK(self_sv)) return;
    inner = SvRV(self_sv);
    if (SvTYPE(inner) >= SVt_PVAV || !SvOK(inner) || 0 == SvIV(inner)) return;
    /* quietly, like a destroyed object: a foreign copy has nothing of ours */
    if (!ev_redis_owns_sv(inner)) return;
    self = INT2PTR(EV__Redis, SvIV(inner));
    if (self->magic != EV_REDIS_MAGIC) return;

    /* first: blocks re-entrant DESTROY */
    self->magic = EV_REDIS_FREED;
    /* an explicit $obj->DESTROY does not pin the referent its callbacks may free */
    sv_2mortal(SvREFCNT_inc_simple_NN(inner));
    detach_dead_loop(self);

    stop_reconnect_timer(self);
    stop_waiting_timer(self);

    /* Global destruction: run no Perl handlers, but still free every hiredis
     * context, or its watchers stay registered with dangling data. */
    if (PL_dirty) {
        /* cbs may already be freed SVs: null them before any redisAsyncFree */
        {
            ngx_queue_t* q;
            for (q = ngx_queue_head(&self->cb_queue);
                 q != ngx_queue_sentinel(&self->cb_queue);
                 q = ngx_queue_next(q)) {
                ev_redis_cb_t* cbt = ngx_queue_data(q, ev_redis_cb_t, queue);
                cbt->cb = NULL;
            }
            /* the contexts free them without unlinking: a callback of ours on
             * the stack must not walk them afterwards */
            ngx_queue_init(&self->cb_queue);
        }
        /* detach draining contexts first, as in the non-dirty path below */
        for (dq = ngx_queue_head(&self->drain_queue);
             dq != ngx_queue_sentinel(&self->drain_queue);
             dq = ngx_queue_next(dq)) {
            dn = ngx_queue_data(dq, ev_redis_drain_t, queue);
            dn->ac->data = NULL;
        }
        if (NULL != self->ac) {
            self->ac->data = NULL;
            redisAsyncFree(self->ac);
            self->ac = NULL;
        }
        while (!ngx_queue_empty(&self->drain_queue)) {
            redisAsyncContext* dc;
            dq = ngx_queue_head(&self->drain_queue);
            dc = ngx_queue_data(dq, ev_redis_drain_t, queue)->ac;
            untrack_draining(dc);
            dc->data = NULL;
            redisAsyncFree(dc);
        }
        free_c_fields(self);
        while (self->waiting_count) {
            ngx_queue_t* q = oldest_waiting(self);
            ev_redis_wait_t* wt = ngx_queue_data(q, ev_redis_wait_t, queue);
            ngx_queue_remove(q);
            self->waiting_count--;
            wt->cb = NULL;
            free_wait_entry(wt);
        }
        sv_setiv(inner, 0);
        /* a callback of ours may be on the stack */
        self->loop = NULL;
        check_destroyed(self);
        return;
    }

    self->reconnect = 0;
    /* callbacks run below may reach self through a weak ref */
    self->callback_depth++;

    /* detach draining contexts before freeing self->ac runs any callback */
    for (dq = ngx_queue_head(&self->drain_queue);
         dq != ngx_queue_sentinel(&self->drain_queue);
         dq = ngx_queue_next(dq)) {
        dn = ngx_queue_data(dq, ev_redis_drain_t, queue);
        dn->ac->data = NULL;
        unlink_cbts_of(self, dn->ac);
    }

    /* Null self->ac before redisAsyncFree: its reply callbacks run
     * send_next_waiting, which would issue commands into the dying context. */
    self->loop = NULL;
    ac_to_free = self->ac;
    self->ac = NULL;
    if (NULL != ac_to_free) {
        /* Inside a hiredis callback the free is deferred and pending replies
         * fire later; null data so they take the self == NULL path. */
        if (ac_to_free->c.flags & REDIS_IN_CALLBACK) {
            ac_to_free->data = NULL;
            skip_cb_cleanup = 1;
        }
        redisAsyncFree(ac_to_free);
    }
    while (!ngx_queue_empty(&self->drain_queue)) {
        redisAsyncContext* dc;
        dq = ngx_queue_head(&self->drain_queue);
        dc = ngx_queue_data(dq, ev_redis_drain_t, queue)->ac;
        untrack_draining(dc);
        dc->data = NULL;
        redisAsyncFree(dc);
        skip_cb_cleanup = 1;
    }
    /* Inside a C callback, hiredis may still fire trailing replies for a
     * mid-teardown context (failed connect); reply_cb frees those cbts. */
    if (self->callback_depth > 1 || self->current_cb != NULL) {
        skip_cb_cleanup = 1;
    }
    CLEAR_HANDLER(self->error_handler);
    CLEAR_HANDLER(self->connect_handler);
    CLEAR_HANDLER(self->disconnect_handler);
    CLEAR_HANDLER(self->push_handler);
    /* all loop usage (timers, watcher teardown) is done */
    CLEAR_HANDLER(self->loop_sv);
    free_c_fields(self);

    /* even mid-batch: a batch owns only the commands it took */
    clear_wait_queue_sv(self, err_disconnected);
    if (!skip_cb_cleanup && !self->in_cb_cleanup) {
        remove_cb_queue_sv(self, NULL, NULL);
    }

    /* later method calls croak; a second DESTROY returns early */
    sv_setiv(inner, 0);
    /* again: those callbacks may have set handlers or options */
    CLEAR_HANDLER(self->error_handler);
    CLEAR_HANDLER(self->connect_handler);
    CLEAR_HANDLER(self->disconnect_handler);
    CLEAR_HANDLER(self->push_handler);
    free_c_fields(self);

    self->callback_depth--;
    check_destroyed(self);
}

void
connect(EV::Redis self, SV* host_sv, SV* port_sv = NULL);
CODE:
{
    redisOptions opts;
    const char* hostname;
    IV port;

    if (self->magic != EV_REDIS_MAGIC) {
        croak_caller("cannot connect: object is being destroyed");
    }
    if (NULL == self->loop) {
        croak_caller("cannot connect: the event loop is gone");
    }
    if (NULL != self->ac) {
        croak_caller("already connected");
    }
    /* omitted or undef means the default, like new()'s port */
    port = (NULL == port_sv || !SvOK(port_sv)) ? 6379 : sv_to_sat_iv(port_sv);
    if (port < 1 || port > 65535) {
        croak_caller("invalid port %" IVdf, port);
    }
    hostname = c_string(host_sv, "host name");

    self->intentional_disconnect = 0;
    self->reconnect_attempts = 0;
    stop_reconnect_timer(self);
    self->monitoring = 0;
    clear_connection_params(self);
    self->host = savepv(hostname);
    self->port = (int)port;

    memset(&opts, 0, sizeof(opts));
    pre_connect_common(self, &opts);
    REDIS_OPTIONS_SET_TCP(&opts, hostname, self->port);
    self->ac = redisAsyncConnectWithOptions(&opts);
    if (NULL == self->ac) {
        croak_caller("connect error: cannot allocate memory");
    }

    connect_setup_or_retry(self);
}

void
connect_unix(EV::Redis self, SV* path_sv);
CODE:
{
    redisOptions opts;
    const char* path;

    if (self->magic != EV_REDIS_MAGIC) {
        croak_caller("cannot connect: object is being destroyed");
    }
    if (NULL == self->loop) {
        croak_caller("cannot connect: the event loop is gone");
    }
    if (NULL != self->ac) {
        croak_caller("already connected");
    }
#ifdef EV_REDIS_SSL
    if (NULL != self->ssl_ctx) {
        croak_caller("TLS is not supported over unix sockets");
    }
#endif
    path = c_string(path_sv, "unix socket path");
    /* hiredis would cut it to fit sun_path and leave it unterminated */
    if (strlen(path) >= sizeof(((struct sockaddr_un*)0)->sun_path)) {
        croak_caller("unix socket path too long (max %d bytes)",
              (int)sizeof(((struct sockaddr_un*)0)->sun_path) - 1);
    }

    self->intentional_disconnect = 0;
    self->reconnect_attempts = 0;
    stop_reconnect_timer(self);
    self->monitoring = 0;
    clear_connection_params(self);
    self->path = savepv(path);

    memset(&opts, 0, sizeof(opts));
    pre_connect_common(self, &opts);
    REDIS_OPTIONS_SET_UNIX(&opts, path);
    self->ac = redisAsyncConnectWithOptions(&opts);
    if (NULL == self->ac) {
        croak_caller("connect error: cannot allocate memory");
    }

    connect_setup_or_retry(self);
}

void
disconnect(EV::Redis self);
CODE:
{
    self->intentional_disconnect = 1;
    stop_reconnect_timer(self);
    self->reconnect_attempts = 0;

    /* redisAsyncDisconnect defers unless outside a callback with no pending
     * replies; track c so DESTROY can free it (disconnect_cb untracks). */
    if (NULL != self->ac) {
        redisAsyncContext* c = self->ac;
        track_draining(self, c);
        self->callback_depth++;
        if (self->monitoring) {
            /* a monitor stream never drains: hiredis re-queues its record per line */
            redisAsyncFree(c);
        }
        else {
            redisAsyncDisconnect(c);
        }
        /* on_disconnect may have connected again, even into MONITOR */
        if (self->ac == c) {
            self->ac = NULL;
            self->monitoring = 0;
            detach_pending_of(self, c);
        }
        self->callback_depth--;
        if (check_destroyed(self)) return;
    }

    /* no disconnect_cb clears these for a deferred or still-connecting c */
    if (NULL == self->ac) {
        self->callback_depth++;
        clear_wait_queue_sv(self, err_disconnected);
        self->callback_depth--;
        check_destroyed(self);
    }
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
    if (NULL != timeout_ms && SvOK(timeout_ms) && NULL != self->ac && NULL != self->command_timeout) {
        redisAsyncSetTimeout(self->ac, *self->command_timeout);
        /* while connecting, the armed timer is the connect timeout */
        if (self->ac->c.flags & REDIS_CONNECTED) {
            redisLibevRefreshTimeout(self->ac, *self->command_timeout);
        }
    }
}
OUTPUT:
    RETVAL

SV*
on_error(EV::Redis self, SV* handler = NULL);
PREINIT:
    SV* old;
CODE:
{
    RETVAL = handler_accessor(&self->error_handler, handler, items > 1, &old);
    if (NULL != old) SvREFCNT_dec(old);
}
OUTPUT:
    RETVAL

SV*
on_connect(EV::Redis self, SV* handler = NULL);
PREINIT:
    SV* old;
CODE:
{
    RETVAL = handler_accessor(&self->connect_handler, handler, items > 1, &old);
    if (NULL != old) SvREFCNT_dec(old);
}
OUTPUT:
    RETVAL

SV*
on_disconnect(EV::Redis self, SV* handler = NULL);
PREINIT:
    SV* old;
CODE:
{
    RETVAL = handler_accessor(&self->disconnect_handler, handler, items > 1, &old);
    if (NULL != old) SvREFCNT_dec(old);
}
OUTPUT:
    RETVAL

SV*
on_push(EV::Redis self, SV* handler = NULL);
PREINIT:
    SV* old;
CODE:
{
    RETVAL = handler_accessor(&self->push_handler, handler, items > 1, &old);
    if (NULL != self->ac) {
        if (NULL != self->push_handler) {
            redisAsyncSetPushCallback(self->ac, EV__redis_push_cb);
        } else {
            redisAsyncSetPushCallback(self->ac, NULL);
        }
    }
    if (NULL != old) SvREFCNT_dec(old);
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
    ev_redis_txn_t* txn_now;
    ev_redis_cb_t* cbt;
    ev_redis_wait_t* wt;
    char* p;
CODE:
{
    if (items < 2) {
        croak_caller("Usage: command(\"command\", ..., [$callback])");
    }

    cb = ST(items - 1);
    if (SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV) {
        /* a copy: cb may be the caller's variable, reassigned before the reply */
        cb = sv_2mortal(newSVsv(cb));
        argc = items - 2;
    }
    else {
        cb = NULL;
        argc = items - 1;
    }

    if (argc < 1) {
        croak_caller("Usage: command(\"command\", ..., [$callback])");
    }
    if (self->magic != EV_REDIS_MAGIC) {
        croak_caller("cannot send commands: object is being destroyed");
    }
    if (NULL == self->loop) {
        croak_caller("cannot send commands: the event loop is gone");
    }

    /* hiredis monitor mode re-queues each just-run callback record; a freed
     * one-shot cbt would be re-fired as dangling privdata. */
    if (self->monitoring) {
        croak_caller("cannot send commands while MONITOR is active on this connection");
    }

    if (NULL == self->ac) {
        if (!self->reconnect_timer_active) {
            croak_caller("connection required before calling command");
        }
    }
    Newx(argv, argc, char*);
    SAVEFREEPV(argv);
    Newx(argvlen, argc, size_t);
    SAVEFREEPV(argvlen);

    {
        /* warnings from converting the arguments (undef) name the caller's
         * line and follow its lexical warnings */
        COP* saved = PL_curcop;
        COP* cop = caller_cop();
        if (NULL != cop) PL_curcop = cop;
        for (i = 0; i < argc; i++) {
            SV* arg = ST(i + 1);
            /* SvPVbyte's own croak would name a line of this module */
            if (SvPOK(arg) && SvUTF8(arg) && !SvGMAGICAL(arg) && has_wide_char(arg)) {
                croak_caller("Wide character in subroutine entry");
            }
            /* wire bytes must not depend on the UTF8 flag */
            argv[i] = SvPVbyte(arg, len);
            argvlen[i] = len;
        }
        PL_curcop = saved;
    }
    /* the command checks below stop at a NUL; hiredis and the server may not */
    if (NULL != memchr(argv[0], '\0', argvlen[0])) {
        croak_caller("command name contains a NUL byte");
    }

    if (is_shard_pubsub_command(argv[0])) {
        croak_caller("%s is not supported: bundled hiredis has no sharded pub/sub "
              "support (use spublish for publishing; subscribe via a plain "
              "subscribe on a non-cluster channel)", argv[0]);
    }
    /* hiredis drops a leading 'p' and would run it as MONITOR */
    if (0 == ascii_strcasecmp(argv[0], "pmonitor")) {
        croak_caller("%s is not supported", argv[0]);
    }
    if (is_reply_suppressing(argc, argv)) {
        if (0 == ascii_strcasecmp(argv[0], "client")) {
            croak_caller("CLIENT REPLY %s is not supported: replies are matched to "
                         "callbacks by their order", argv[2]);
        }
        croak_caller("REPLCONF ACK and GETACK are not supported: they get no reply");
    }
    /* the replication stream that follows is not one reply per command: the
     * first unexpected one trips hiredis's assert */
    if (0 == ascii_strcasecmp(argv[0], "sync") || 0 == ascii_strcasecmp(argv[0], "psync")) {
        croak_caller("%s is not supported: a replication stream follows", argv[0]);
    }
    if (0 == ascii_strcasecmp(argv[0], "reset") && may_be_subscribed(self)) {
        croak_caller("RESET is not supported on a subscribed connection");
    }

    persist = is_persistent_command(argv[0]);

    /* A channel-less subscribe is one-shot to hiredis but persistent to us:
     * the cbt would strand and double-fire at disconnect. */
    if (persist && argc < 2 &&
        !is_monitor_command(argv[0]) && !is_unsubscribe_command(argv[0])) {
        croak_caller("%s requires at least one channel", argv[0]);
    }

    if (is_monitor_command(argv[0])) {
        if (NULL == self->ac) {
            croak_caller("MONITOR requires an active connection");
        }
        /* pending commands would hit the same re-queue hazard; hiredis's own records
         * count too, as skip_pending unlinks commands still outstanding there.
         * Inside MULTI the submit fails through the callback instead, so the
         * idle check (which a reply callback of its own never passes) is skipped. */
        int busy = 0;
        ngx_queue_t* q;
        for (q = ngx_queue_head(&self->cb_queue);
             q != ngx_queue_sentinel(&self->cb_queue);
             q = ngx_queue_next(q)) {
            ev_redis_cb_t* cbt = ngx_queue_data(q, ev_redis_cb_t, queue);
            /* detached drained replies belong to a replaced connection */
            if (!cbt->detached && cbt->ac == self->ac) { busy = 1; break; }
        }
        if (!self->in_multi
                && (busy || self->waiting_count
                || NULL != self->ac->replies.head || NULL != self->ac->sub.replies.head
                || (self->ac->c.flags & REDIS_SUBSCRIBED))) {
            croak_caller("MONITOR requires an idle connection "
                  "(no pending, waiting, or subscribed commands)");
        }
    }

    /* Track a transaction across both waiting queues and submitted callbacks. */
    {
        int boundary = transaction_command(argv[0]);
        int opens = EV_REDIS_MULTI == boundary
            || 0 == ascii_strcasecmp(argv[0], "watch");
        if (opens && NULL == self->issued_txn) {
            Newxz(self->issued_txn, 1, ev_redis_txn_t);
            self->issued_txn->refs = 1;
        }
        txn_now = txn_ref(self->issued_txn);
        if (NULL != txn_now) {
            SAVEDESTRUCTOR_X(txn_scope_free, txn_now);
            if (EV_REDIS_MULTI == boundary) txn_now->multi = 1;
            if ((!opens && boundary) || (!txn_now->multi
                    && 0 == ascii_strcasecmp(argv[0], "unwatch"))) {
                txn_now->closed = 1;
                txn_unref(self->issued_txn);
                self->issued_txn = NULL;
            }
        }
    }

    /* Queued behind waiting commands, to keep order (on_connect's setup goes
     * first, past max_pending too); while connecting under resume_waiting_on_reconnect,
     * so a failed attempt keeps them; on a dying connection, where a retry-on-error
     * callback would recurse. MONITOR must mark the connection at once. */
    if (!is_monitor_command(argv[0]) &&
        (NULL == self->ac || ac_dying(self->ac) ||
         (self->pending_multi && needs_transaction_reply(persist, argv[0])) ||
         (!(self->ac->c.flags & REDIS_CONNECTED) &&
          self->reconnect && self->resume_waiting_on_reconnect) ||
         (self->in_connect_handler ? !ngx_queue_empty(&self->setup_queue)
          : (self->waiting_count || at_max_pending(self))))) {
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
        wt->txn = txn_ref(txn_now);
        /* ev_now is stale outside ev_run and would expire the command early */
        ev_now_update(self->loop);
        wt->queued_at = ev_now(self->loop);
        ngx_queue_init(&wt->queue);
        ngx_queue_insert_tail(self->in_connect_handler ? &self->setup_queue : &self->wait_queue,
            &wt->queue);
        self->waiting_count++;
        schedule_waiting_timer(self);
        RETVAL = REDIS_OK;
    }
    else {
        Newx(cbt, 1, ev_redis_cb_t);
        cbt->cb = SvREFCNT_inc(cb);
        cbt->skipped = 0;
        cbt->running = 0;
        cbt->detached = 0;
        cbt->seq = ++self->cb_seq;
        cbt->persist = persist;
        cbt->txn = txn_ref(txn_now);
        ngx_queue_init(&cbt->queue);
        ngx_queue_insert_tail(&self->cb_queue, &cbt->queue);
        if (!persist) self->pending_count++;

        /* a failed submit runs the callback, which may destroy self */
        self->callback_depth++;
        RETVAL = submit_to_redis(self, cbt,
            argc, (const char**)argv, argvlen);
        self->callback_depth--;
        if (self->magic == EV_REDIS_FREED) {
            check_destroyed(self);
        }
        else if (REDIS_OK == RETVAL && is_monitor_command(argv[0])) {
            self->monitoring = 1;
        }
    }
}
OUTPUT:
    RETVAL

void
reconnect(EV::Redis self, bool enable, SV* delay_ms = NULL, SV* max_attempts = NULL);
CODE:
{
    /* omitted restores the default; explicit undef keeps the current value */
    if (NULL == delay_ms) {
        self->reconnect_delay_ms = 1000;
    }
    else if (SvOK(delay_ms)) {
        IV delay = sv_to_sat_iv(delay_ms);
        validate_timeout_ms(delay, "reconnect_delay");
        self->reconnect_delay_ms = (int)delay;
    }
    if (NULL == max_attempts) {
        self->max_reconnect_attempts = 0;
    }
    else if (SvOK(max_attempts)) {
        IV attempts = sv_to_sat_iv(max_attempts);
        self->max_reconnect_attempts = attempts < 0 ? 0
            : attempts > INT_MAX ? INT_MAX : (int)attempts;
    }
    self->reconnect = enable ? 1 : 0;
    self->reconnect_attempts = 0;

    if (!enable) {
        stop_reconnect_timer(self);
        /* commands queued for the cancelled reconnect would hang forever */
        if (NULL == self->ac && self->waiting_count) {
            self->callback_depth++;
            clear_wait_queue_sv(self,
                sv_2mortal(newSVpv("reconnect disabled", 0)));
            self->callback_depth--;
            if (check_destroyed(self)) return;
        }
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
        IV val = sv_to_sat_iv(limit);
        if (val < 0) {
            croak_caller("max_pending must be non-negative");
        }
        self->max_pending = val > INT_MAX ? INT_MAX : (int)val;

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
        IV ms = sv_to_sat_iv(timeout_ms);
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
        IV prio = sv_to_sat_iv(value);
        if (prio < EV_MINPRI) prio = EV_MINPRI;
        if (prio > EV_MAXPRI) prio = EV_MAXPRI;
        self->priority = (int)prio;
        if (NULL != self->ac) {
            redisLibevSetPriority(self->ac, self->priority);
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
        IV interval = sv_to_sat_iv(value);
        if (interval < 0) croak_caller("keepalive interval must be non-negative");
        if (interval > MAX_KEEPALIVE) croak_caller("keepalive interval too large (max %d)", MAX_KEEPALIVE);
        if (NULL != self->ac && interval > 0
                && self->ac->c.connection_type == REDIS_CONN_TCP) {
            redisContext* rc = &self->ac->c;
            int saved_err = rc->err;
            char saved_errstr[sizeof(rc->errstr)];
            Copy(rc->errstr, saved_errstr, sizeof(saved_errstr), char);
            if (REDIS_OK != redisEnableKeepAliveWithInterval(rc, (int)interval)) {
                SV* msg = sv_2mortal(newSVpv(rc->errstr, 0));
                /* the socket still works: hiredis must not treat it as failed */
                rc->err = saved_err;
                Copy(saved_errstr, rc->errstr, sizeof(saved_errstr), char);
                croak_caller("keepalive: %" SVf, SVfARG(msg));
            }
        }
        self->keepalive = (int)interval;
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
            self->source_addr = savepv(c_string(value, "source_addr"));
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
        IV ms = sv_to_sat_iv(value);
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
    self->callback_depth++;

    if (self->in_wait_cleanup) {
        self->callback_depth--;
        check_destroyed(self);
        return;
    }

    clear_wait_queue_sv(self, err_skipped);

    self->callback_depth--;
    check_destroyed(self);
}

void
skip_pending(EV::Redis self);
CODE:
{
    ngx_queue_t local_queue;
    ngx_queue_t* q;
    ngx_queue_t* next;
    ev_redis_cb_t* cbt;
    /* commands the skipped callbacks issue are not skipped */
    UV issued_before = self->cb_seq;

    self->callback_depth++;

    if (!self->in_wait_cleanup) clear_wait_queue_sv(self, err_skipped);

    if (self->in_cb_cleanup) {
        self->callback_depth--;
        check_destroyed(self);
        return;
    }

    self->in_cb_cleanup = 1;

    ngx_queue_init(&local_queue);
    for (q = ngx_queue_head(&self->cb_queue);
         q != ngx_queue_sentinel(&self->cb_queue);
         q = next) {
        next = ngx_queue_next(q);
        cbt = ngx_queue_data(q, ev_redis_cb_t, queue);
        /* the monitor stream is not a pending command; the server has no off switch */
        if (cbt->running || cbt->monitor || cbt->seq > issued_before) continue;
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

        /* before invoking: a reply in a re-entered loop must find it skipped */
        cbt->skipped = 1;

        /* reply_cb's skipped path may unlink it again */
        ngx_queue_init(q);
        if (!cbt->persist) drop_pending(self, cbt);

        /* take cb first: reply_cb may free cbt while the callback runs */
        if (NULL != cbt->cb) {
            SV* cb_to_invoke = cbt->cb;
            cbt->cb = NULL;

            invoke_callback_error(cb_to_invoke, err_skipped);
            SvREFCNT_dec(cb_to_invoke);
        }
    }

    self->in_cb_cleanup = 0;

    /* skipping releases slots for commands the callbacks issued */
    if (self->magic == EV_REDIS_MAGIC) send_next_waiting(self);

    self->callback_depth--;
    check_destroyed(self);
}

void
_warn(const char* what, SV* err, SV* msg);
CODE:
    sv_setpvf(msg, "EV::Redis: exception in %s: %" SVf, what, SVfARG(err));
    warn("%" SVf, SVfARG(msg));

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
    redisSSLContext* new_ctx;
    redisSSLOptions ssl_opts;

    memset(&ssl_opts, 0, sizeof(ssl_opts));
    ssl_opts.cacert_filename = (SvOK(cacert)) ? c_string(cacert, "tls_ca") : NULL;
    ssl_opts.capath = (SvOK(capath)) ? c_string(capath, "tls_capath") : NULL;
    ssl_opts.cert_filename = (SvOK(cert)) ? c_string(cert, "tls_cert") : NULL;
    ssl_opts.private_key_filename = (SvOK(key)) ? c_string(key, "tls_key") : NULL;
    ssl_opts.server_name = (SvOK(server_name)) ? c_string(server_name, "tls_server_name") : NULL;
    ssl_opts.verify_mode = verify ? REDIS_SSL_VERIFY_PEER : REDIS_SSL_VERIFY_NONE;

    /* create first: a failed (eval-trapped) reconfigure must not leave
     * ssl_ctx NULL, or the next reconnect goes plaintext */
    new_ctx = redisCreateSSLContextWithOptions(&ssl_opts, &ssl_error);
    if (NULL == new_ctx) {
        croak_caller("SSL context creation failed: %s", redisSSLContextGetError(ssl_error));
    }

    if (NULL != self->ssl_ctx) {
        redisFreeSSLContext(self->ssl_ctx);
    }
    self->ssl_ctx = new_ctx;
}

#endif
