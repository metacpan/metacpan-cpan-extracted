#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "EVAPI.h"

#include <mysql.h>
#include <errmsg.h>
#include <mysql_version.h>
#if MYSQL_VERSION_ID < 80016
#error "EV::mysql requires libmysqlclient >= 8.0.16 (mysql_*_nonblocking API)"
#endif
#include <poll.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <unistd.h>
#include <stdint.h>
#include <limits.h>
#include <string.h>
#include <stdlib.h>
#include <stddef.h>

#include "ngx_queue.h"

#define EV_MYSQL_CONTAINER(ptr, type, member) \
    ((type *)((char *)(ptr) - offsetof(type, member)))

/* Keep $self's referent alive through the enclosing caller's FREETMPS so tied
 * FETCH or overload evaluation that undefs the sole Perl ref cannot free self
 * mid-XSUB while callback_depth == 0. */
#define HOLD_SELF_ST() STMT_START { \
    if (SvROK(ST(0))) sv_2mortal(newRV_inc(SvRV(ST(0)))); \
} STMT_END

#define EV_MYSQL_MAX_IO_RETRIES 8
#define EV_MYSQL_OP_INLINE_SQL  128
#define EV_MYSQL_OP_INLINE_PARAMS 4
#define EV_MYSQL_OP_FREELIST_MAX 16

typedef enum {
    STATE_DISCONNECTED = 0,
    STATE_CONNECTING,
    STATE_IDLE,
    STATE_REAL_QUERY,
    STATE_STORE_RESULT,
    STATE_NEXT_RESULT,
    STATE_STREAM_QUERY,
    STATE_STREAM_FETCH,
    STATE_STREAM_FREE_RESULT,
    STATE_STREAM_NEXT_RESULT,
    STATE_RESET_CONNECTION,
    STATE_DEFERRED_OP
} conn_state_t;

typedef enum {
    OP_QUERY = 1,
    OP_STREAM,
    OP_PING,
    OP_SELECT_DB,
    OP_COMMIT,
    OP_ROLLBACK,
    OP_AUTOCOMMIT,
    OP_RESET_CONNECTION,
    OP_SET_CHARSET,
    OP_CHANGE_USER,
    OP_CLOSE_ASYNC,
    OP_PREPARE,
    OP_EXECUTE,
    OP_SEND_LONG_DATA,
    OP_STMT_RESET,
    OP_CLOSE_STMT
} op_type_t;

typedef enum {
    PARAM_NULL = 0,
    PARAM_IV,
    PARAM_UV,
    PARAM_NV,
    PARAM_STR
} param_kind_t;

typedef struct ev_mysql_param_s {
    param_kind_t kind;
    union {
        int64_t  iv;
        uint64_t uv;
        double   nv;
        struct {
            char  *ptr;
            STRLEN len;
        } str;
    } u;
} ev_mysql_param_t;

typedef struct ev_mysql_op_s {
    ngx_queue_t       queue;
    op_type_t         type;
    SV               *cb;
    char             *sql;
    STRLEN            sql_len;
    char             *arg1;
    char             *arg2;
    char             *arg3;
    int               has_arg3;
    IV                iv_arg;
    UV                uv_arg;
    ev_mysql_param_t *params;
    unsigned int      param_count;
    int               has_params;
    uint64_t          seq;
    char              sql_inline[EV_MYSQL_OP_INLINE_SQL];
    ev_mysql_param_t  params_inline[EV_MYSQL_OP_INLINE_PARAMS];
} ev_mysql_op_t;

typedef struct ev_mysql_stmt_s {
    struct ev_mysql_stmt_s *next;
    IV            id;
    MYSQL_STMT   *stmt;
    int           closing;
    int           stale;
    MYSQL_BIND   *in_binds;
    unsigned long *in_lengths;
    unsigned long *in_buf_cap;
    bool         *in_is_null;
    unsigned int  in_cap;
    unsigned int  param_count;
    int           has_manual_bind;
    bool         *long_data_sent;
    MYSQL_BIND   *out_binds;
    unsigned long *out_len;
    bool         *out_null;
    bool         *out_err;
    unsigned int  out_cap;
} ev_mysql_stmt_t;

typedef struct ev_mysql_s {
    struct ev_loop *loop;
    SV          *loop_sv;
    ev_io        io;
    ev_timer     timeout_timer;
    ev_timer     poll_timer;
    ev_timer     deferred_timer;
    int          io_active;
    int          io_events;
    int          fd;

    MYSQL       *conn;
    conn_state_t state;
    int          connected;
    int          closing;
    int          timed_out;
    int          destroyed;
    int          in_sync_connect;
    int          deferred_connect_ok;
    int          reset_aborted;
    unsigned int reset_gen;
    int          in_fail_queue;
    int          callback_depth;
    pid_t        pid;
    char        *deferred_connect_err;

    /* Connection target */
    char        *host;
    char        *user;
    char        *password;
    char        *database;
    unsigned int port;
    char        *unix_socket;

    /* Connection options */
    unsigned int connect_timeout;
    unsigned int read_timeout;
    unsigned int write_timeout;
    char        *charset;
    char        *init_command;
    int          compress;
    int          multi_statements;
    int          utf8;
    int          found_rows;
    char        *ssl_key;
    char        *ssl_cert;
    char        *ssl_ca;
    char        *ssl_capath;
    char        *ssl_cipher;
    int          ssl_verify_server_cert; /* -1 unset, 0 off, 1 on */
    int          ssl_mode_set;
    unsigned int ssl_mode;

    /* Callbacks */
    SV          *on_connect;
    SV          *on_error;

    /* Operation queue */
    ngx_queue_t    op_queue;
    ev_mysql_op_t *current_op;
    ev_mysql_op_t *op_freelist;
    int            op_freelist_count;
    unsigned int   pending_count;
    uint64_t       next_op_seq;

    /* In-flight query/stream state */
    MYSQL_RES   *op_res;
    SV          *op_result_sv;
    SV          *op_fields_sv;
    char        *op_err;
    unsigned int op_errno;

    MYSQL_RES   *stream_res;
    SV          *stream_fields;
    char        *stream_err;
    unsigned int stream_errno;
    int          stream_eof_sent;
    int          stream_first_done;
    uint64_t     stream_utf8_mask;

    /* Prepared statements */
    ev_mysql_stmt_t *stmt_list;
    IV               next_stmt_id;

    /* Cached server/status metadata (preserved after disconnect) */
    my_ulonglong last_affected_rows;
    my_ulonglong last_insert_id;
    unsigned int last_warning_count;
    char        *last_info;
    unsigned int last_errno;
    char        *last_error;
    char         last_sqlstate[SQLSTATE_LENGTH + 1];
    unsigned long last_thread_id;
} ev_mysql_t;

typedef ev_mysql_t *     EV__mysql;
typedef struct ev_loop * EV__Loop;

static void start_next_op(pTHX_ ev_mysql_t *self);
static void drive_state_machine(pTHX_ ev_mysql_t *self);
static void cleanup_connection(pTHX_ ev_mysql_t *self, int keep_error);
static void arm_watchers(pTHX_ ev_mysql_t *self);
static int  check_fork_safety(pTHX_ ev_mysql_t *self);

/* ------------------------------------------------------------------ */
/* Helpers: strings, charsets, error caching                          */
/* ------------------------------------------------------------------ */

static void replace_str(char **dst, const char *src) {
    if (*dst) {
        Safefree(*dst);
        *dst = NULL;
    }
    if (src) *dst = savepv(src);
}

/* Snapshot a scalar value once (invoking tie/get-magic at most once) into a
 * non-magical mortal SV so downstream SvOK/SvPV/SvIV/SvUV/SvNV/SvTRUE never
 * trigger a second FETCH. */
static SV *sv_nomg_copy(pTHX_ SV *sv) {
    SV *copy;
    if (!sv) return NULL;
    SvGETMAGIC(sv);
    copy = sv_2mortal(newSV(0));
    sv_setsv_flags(copy, sv, 0);
    return copy;
}

/* Snapshot SV string into a mortal SV after triggering get-magic/overloading so
 * exceptions thrown by later argument evaluations cannot leak C-heap buffers. */
static const char *sv_to_temp_pv(pTHX_ SV *sv, STRLEN *out_len) {
    STRLEN len;
    const char *p;
    SV *nomg;
    SV *tmp;
    if (!sv) {
        if (out_len) *out_len = 0;
        return NULL;
    }
    nomg = sv_nomg_copy(aTHX_ sv);
    if (!SvOK(nomg)) {
        if (out_len) *out_len = 0;
        return NULL;
    }
    p = SvPV(nomg, len);
    tmp = sv_2mortal(newSVpvn(p, len));
    if (out_len) *out_len = len;
    return SvPVX_const(tmp);
}

static void replace_str_from_sv(pTHX_ char **dst, SV *value) {
    STRLEN len = 0;
    const char *tmp = sv_to_temp_pv(aTHX_ value, &len);
    char *copy = tmp ? savepvn(tmp, len) : NULL;
    if (*dst) Safefree(*dst);
    *dst = copy;
}

static SV *sv_to_mortal_sql(pTHX_ ev_mysql_t *self, SV *sv) {
    SV *nomg = sv_nomg_copy(aTHX_ sv);
    SV *tmp;
    if (!nomg || !SvOK(nomg)) return NULL;
    tmp = sv_2mortal(newSVpvs(""));
    sv_catsv(tmp, nomg);
    if (self->utf8 || SvUTF8(tmp)) {
        (void)SvPVutf8_nolen(tmp);
    } else {
        (void)SvPV_nolen(tmp);
    }
    return tmp;
}

static IV sv_to_stmt_id(pTHX_ SV *stmt_sv) {
    SV *nomg = sv_nomg_copy(aTHX_ stmt_sv);
    if (!nomg || !SvOK(nomg)) return 0;
    return SvIV(nomg);
}

static int is_utf8_charset(unsigned int charsetnr) {
    /* All MySQL utf8mb3 (legacy utf8) and utf8mb4 collation IDs */
    if (charsetnr == 33 || charsetnr == 45 || charsetnr == 46 ||
        charsetnr == 76 || charsetnr == 83 || charsetnr == 223)
        return 1;
    if (charsetnr >= 192 && charsetnr <= 215) return 1;
    if (charsetnr >= 224 && charsetnr <= 247) return 1;
    if (charsetnr >= 255 && charsetnr <= 300) return 1;
    if (charsetnr >= 303 && charsetnr <= 323) return 1;
    return 0;
}

static int is_conn_utf8(ev_mysql_t *self) {
    const char *cs;
    if (!self->conn) return 0;
    cs = mysql_character_set_name(self->conn);
    return cs && cs[0] == 'u' && cs[1] == 't' && cs[2] == 'f' && cs[3] == '8';
}

static void cache_conn_status(ev_mysql_t *self) {
    const char *inf;
    if (!self->conn) return;
    self->last_affected_rows = mysql_affected_rows(self->conn);
    self->last_insert_id     = mysql_insert_id(self->conn);
    self->last_warning_count = mysql_warning_count(self->conn);
    inf = mysql_info(self->conn);
    if (inf || self->last_info) replace_str(&self->last_info, inf);
}

static void cache_conn_error(ev_mysql_t *self) {
    const char *err;
    const char *st;
    if (!self->conn) return;
    self->last_errno = mysql_errno(self->conn);
    err = mysql_error(self->conn);
    replace_str(&self->last_error, (err && *err) ? err : NULL);
    st = mysql_sqlstate(self->conn);
    if (st) {
        strncpy(self->last_sqlstate, st, SQLSTATE_LENGTH);
        self->last_sqlstate[SQLSTATE_LENGTH] = '\0';
    }
}

static void cache_stmt_error(ev_mysql_t *self, MYSQL_STMT *stmt) {
    const char *err;
    const char *st;
    if (!stmt) return;
    self->last_errno = mysql_stmt_errno(stmt);
    err = mysql_stmt_error(stmt);
    replace_str(&self->last_error, (err && *err) ? err : NULL);
    st = mysql_stmt_sqlstate(stmt);
    if (st) {
        strncpy(self->last_sqlstate, st, SQLSTATE_LENGTH);
        self->last_sqlstate[SQLSTATE_LENGTH] = '\0';
    }
}

static void set_custom_error(ev_mysql_t *self, unsigned int errnum, const char *msg) {
    self->last_errno = errnum;
    replace_str(&self->last_error, msg);
    strncpy(self->last_sqlstate, "HY000", SQLSTATE_LENGTH);
    self->last_sqlstate[SQLSTATE_LENGTH] = '\0';
}

static int is_fatal_conn_errno(unsigned int e) {
    return e == CR_SERVER_GONE_ERROR ||
           e == CR_SERVER_LOST ||
           e == CR_CONNECTION_ERROR ||
           e == CR_CONN_HOST_ERROR ||
           e == CR_UNKNOWN_HOST ||
           e == CR_SOCKET_CREATE_ERROR ||
           e == CR_IPSOCK_ERROR ||
           e == CR_NET_PACKET_TOO_LARGE;
}

static int mysql_sock_fd(MYSQL *conn) {
    if (!conn || !conn->net.vio) return -1;
    return (int)conn->net.fd;
}

/* ------------------------------------------------------------------ */
/* Memory cleanup helpers                                             */
/* ------------------------------------------------------------------ */

static void clear_op_fields(pTHX_ ev_mysql_op_t *op) {
    if (op->cb && !PL_dirty) SvREFCNT_dec(op->cb);
    if (op->params) {
        unsigned int i;
        uintptr_t lo = (uintptr_t)op->sql_inline;
        uintptr_t hi = lo + EV_MYSQL_OP_INLINE_SQL;
        for (i = 0; i < op->param_count; i++) {
            if (op->params[i].kind == PARAM_STR && op->params[i].u.str.ptr) {
                uintptr_t addr = (uintptr_t)op->params[i].u.str.ptr;
                if (addr < lo || addr >= hi) Safefree(op->params[i].u.str.ptr);
            }
        }
        if (op->params != op->params_inline) Safefree(op->params);
    }
    if (op->sql && op->sql != op->sql_inline) Safefree(op->sql);
    if (op->arg1) Safefree(op->arg1);
    if (op->arg2) Safefree(op->arg2);
    if (op->arg3) Safefree(op->arg3);
}

static void free_op(pTHX_ ev_mysql_op_t *op) {
    if (!op) return;
    clear_op_fields(aTHX_ op);
    Safefree(op);
}

static void release_op(pTHX_ ev_mysql_t *self, ev_mysql_op_t *op) {
    if (!op) return;
    clear_op_fields(aTHX_ op);
    if (self && !self->destroyed && self->op_freelist_count < EV_MYSQL_OP_FREELIST_MAX) {
        op->queue.next = (ngx_queue_t *)self->op_freelist;
        self->op_freelist = op;
        self->op_freelist_count++;
    } else {
        Safefree(op);
    }
}

static void clear_op_scratch(pTHX_ ev_mysql_t *self) {
    if (self->op_res) {
        mysql_free_result(self->op_res);
        self->op_res = NULL;
    }
    if (self->op_result_sv) {
        if (!PL_dirty) SvREFCNT_dec(self->op_result_sv);
        self->op_result_sv = NULL;
    }
    if (self->op_fields_sv) {
        if (!PL_dirty) SvREFCNT_dec(self->op_fields_sv);
        self->op_fields_sv = NULL;
    }
    if (self->op_err) {
        Safefree(self->op_err);
        self->op_err = NULL;
    }
    self->op_errno = 0;

    if (self->stream_res) {
        mysql_free_result(self->stream_res);
        self->stream_res = NULL;
    }
    if (self->stream_fields) {
        if (!PL_dirty) SvREFCNT_dec(self->stream_fields);
        self->stream_fields = NULL;
    }
    if (self->stream_err) {
        Safefree(self->stream_err);
        self->stream_err = NULL;
    }
    self->stream_errno = 0;
    self->stream_eof_sent = 0;
    self->stream_first_done = 0;
    self->stream_utf8_mask = 0;
}

static void free_stmt_bind_storage(ev_mysql_stmt_t *ctx) {
    unsigned int i;
    if (!ctx) return;
    if (ctx->in_binds) {
        for (i = 0; i < ctx->in_cap; i++) {
            if (ctx->in_binds[i].buffer) {
                Safefree(ctx->in_binds[i].buffer);
                ctx->in_binds[i].buffer = NULL;
            }
        }
        Safefree(ctx->in_binds);
        ctx->in_binds = NULL;
    }
    if (ctx->in_lengths) {
        Safefree(ctx->in_lengths);
        ctx->in_lengths = NULL;
    }
    if (ctx->in_buf_cap) {
        Safefree(ctx->in_buf_cap);
        ctx->in_buf_cap = NULL;
    }
    if (ctx->in_is_null) {
        Safefree(ctx->in_is_null);
        ctx->in_is_null = NULL;
    }
    if (ctx->long_data_sent) {
        Safefree(ctx->long_data_sent);
        ctx->long_data_sent = NULL;
    }
    ctx->in_cap = 0;
    ctx->has_manual_bind = 0;

    if (ctx->out_binds) {
        for (i = 0; i < ctx->out_cap; i++) {
            if (ctx->out_binds[i].buffer) {
                Safefree(ctx->out_binds[i].buffer);
                ctx->out_binds[i].buffer = NULL;
            }
        }
        Safefree(ctx->out_binds);
        ctx->out_binds = NULL;
    }
    if (ctx->out_len) {
        Safefree(ctx->out_len);
        ctx->out_len = NULL;
    }
    if (ctx->out_null) {
        Safefree(ctx->out_null);
        ctx->out_null = NULL;
    }
    if (ctx->out_err) {
        Safefree(ctx->out_err);
        ctx->out_err = NULL;
    }
    ctx->out_cap = 0;
}

static void invalidate_all_stmts(ev_mysql_t *self, int close_handles) {
    ev_mysql_stmt_t *cur = self->stmt_list;
    while (cur) {
        cur->stale = 1;
        cur->closing = 0;
        if (close_handles && cur->stmt) {
            mysql_stmt_close(cur->stmt);
            cur->stmt = NULL;
        }
        free_stmt_bind_storage(cur);
        cur = cur->next;
    }
}

static void free_all_stmts(ev_mysql_t *self, int close_handles) {
    ev_mysql_stmt_t *cur = self->stmt_list;
    self->stmt_list = NULL;
    while (cur) {
        ev_mysql_stmt_t *next = cur->next;
        if (close_handles && cur->stmt) {
            mysql_stmt_close(cur->stmt);
            cur->stmt = NULL;
        }
        free_stmt_bind_storage(cur);
        Safefree(cur);
        cur = next;
    }
}

static ev_mysql_stmt_t *find_stmt(ev_mysql_t *self, IV id) {
    ev_mysql_stmt_t *cur = self->stmt_list;
    if (id <= 0) return NULL;
    while (cur) {
        if (cur->id == id) return cur;
        cur = cur->next;
    }
    return NULL;
}

static void remove_stmt(ev_mysql_t *self, ev_mysql_stmt_t *target) {
    ev_mysql_stmt_t **pp = &self->stmt_list;
    while (*pp) {
        if (*pp == target) {
            *pp = target->next;
            free_stmt_bind_storage(target);
            Safefree(target);
            return;
        }
        pp = &(*pp)->next;
    }
}

static void free_self_final(pTHX_ ev_mysql_t *self) {
    if (!self) return;
    free_all_stmts(self, 0);
    clear_op_scratch(aTHX_ self);

    if (self->current_op) {
        free_op(aTHX_ self->current_op);
        self->current_op = NULL;
    }
    while (!ngx_queue_empty(&self->op_queue)) {
        ngx_queue_t *q = ngx_queue_head(&self->op_queue);
        ev_mysql_op_t *op = ngx_queue_data(q, ev_mysql_op_t, queue);
        ngx_queue_remove(q);
        free_op(aTHX_ op);
    }
    while (self->op_freelist) {
        ev_mysql_op_t *op = self->op_freelist;
        self->op_freelist = (ev_mysql_op_t *)op->queue.next;
        Safefree(op);
    }
    self->op_freelist_count = 0;

    replace_str(&self->host, NULL);
    replace_str(&self->user, NULL);
    replace_str(&self->password, NULL);
    replace_str(&self->database, NULL);
    replace_str(&self->unix_socket, NULL);
    replace_str(&self->charset, NULL);
    replace_str(&self->init_command, NULL);
    replace_str(&self->ssl_key, NULL);
    replace_str(&self->ssl_cert, NULL);
    replace_str(&self->ssl_ca, NULL);
    replace_str(&self->ssl_capath, NULL);
    replace_str(&self->ssl_cipher, NULL);
    replace_str(&self->last_info, NULL);
    replace_str(&self->last_error, NULL);
    replace_str(&self->deferred_connect_err, NULL);
    self->deferred_connect_ok = 0;

    if (!PL_dirty) {
        if (self->on_connect) { SvREFCNT_dec(self->on_connect); self->on_connect = NULL; }
        if (self->on_error)   { SvREFCNT_dec(self->on_error);   self->on_error = NULL; }
        if (self->loop_sv)    { SvREFCNT_dec(self->loop_sv);    self->loop_sv = NULL; }
    }
    Safefree(self);
}

static int check_destroyed(pTHX_ ev_mysql_t *self) {
    if (self->destroyed && self->callback_depth == 0) {
        free_self_final(aTHX_ self);
        return 1;
    }
    return self->destroyed;
}

/* ------------------------------------------------------------------ */
/* Watcher management                                                 */
/* ------------------------------------------------------------------ */

static int loop_is_alive(ev_mysql_t *self) {
    if (!self->loop) return 0;
    if (!PL_dirty) return 1;
    if (self->loop == EV_DEFAULT_UC) return 1;
    if (self->loop_sv && SvROK(self->loop_sv) && SvOBJECT(SvRV(self->loop_sv))) return 1;
    return 0;
}

static void stop_io(ev_mysql_t *self) {
    if (self->io_active && loop_is_alive(self)) {
        ev_io_stop(self->loop, &self->io);
        self->io_active = 0;
        self->io_events = 0;
    } else if (self->io_active) {
        self->io_active = 0;
        self->io_events = 0;
    }
}

static void stop_all_watchers(ev_mysql_t *self) {
    stop_io(self);
    if (loop_is_alive(self)) {
        ev_timer_stop(self->loop, &self->timeout_timer);
        ev_timer_stop(self->loop, &self->poll_timer);
        ev_timer_stop(self->loop, &self->deferred_timer);
    }
}

static void schedule_deferred(ev_mysql_t *self) {
    if (!loop_is_alive(self) || self->destroyed) return;
    if (ev_is_active(&self->deferred_timer)) ev_timer_stop(self->loop, &self->deferred_timer);
    ev_timer_set(&self->deferred_timer, 0., 0.);
    ev_timer_start(self->loop, &self->deferred_timer);
}

static void arm_timeout(ev_mysql_t *self, unsigned int secs) {
    if (secs == 0) {
        if (ev_is_active(&self->timeout_timer) && loop_is_alive(self)) {
            ev_timer_stop(self->loop, &self->timeout_timer);
        }
        return;
    }
    if (!loop_is_alive(self) || self->destroyed) return;
    ev_timer_stop(self->loop, &self->timeout_timer);
    ev_timer_set(&self->timeout_timer, (ev_tstamp)secs, 0.);
    ev_timer_start(self->loop, &self->timeout_timer);
}

static void stop_timeout(ev_mysql_t *self) {
    if (ev_is_active(&self->timeout_timer) && loop_is_alive(self)) {
        ev_timer_stop(self->loop, &self->timeout_timer);
    }
}

/* ------------------------------------------------------------------ */
/* Callback invocation helpers (ERRSV + lifetime safe)                */
/* ------------------------------------------------------------------ */

static SV *take_op_cb(ev_mysql_op_t *op) {
    if (op->cb && !PL_dirty && (SvTYPE(op->cb) == SVt_PVCV || SvOK(op->cb))) {
        return SvREFCNT_inc(op->cb);
    }
    return NULL;
}

static void call_sv_eval_safe(pTHX_ SV *cb, int argc, SV **argv) {
    int i;
    dSP;
    PUSHMARK(SP);
    if (argc > 0) {
        EXTEND(SP, argc);
        for (i = 0; i < argc; i++) {
            PUSHs(argv[i] ? argv[i] : &PL_sv_undef);
        }
    }
    PUTBACK;
    call_sv(cb, G_DISCARD | G_EVAL);
    if (SvTRUE(ERRSV)) {
        warn("EV::mysql callback died: %s", SvPV_nolen(ERRSV));
        sv_setsv(ERRSV, &PL_sv_undef);
    }
}

static void call_perl_cb(pTHX_ ev_mysql_t *self, SV *cb, int argc, SV **argv) {
    SV *cb_hold;
    if (!cb || PL_dirty || (SvTYPE(cb) != SVt_PVCV && !SvOK(cb))) return;
    cb_hold = SvREFCNT_inc(cb);
    self->callback_depth++;

    ENTER;
    SAVETMPS;
    call_sv_eval_safe(aTHX_ cb_hold, argc, argv);
    FREETMPS;
    LEAVE;

    self->callback_depth--;
    SvREFCNT_dec(cb_hold);
}

static void invoke_on_connect(pTHX_ ev_mysql_t *self) {
    if (!self->on_connect) return;
    call_perl_cb(aTHX_ self, self->on_connect, 0, NULL);
}

static void invoke_on_error(pTHX_ ev_mysql_t *self, const char *err) {
    SV *arg;
    if (!self->on_error) return;
    ENTER;
    SAVETMPS;
    arg = sv_2mortal(newSVpv(err ? err : "Unknown MySQL error", 0));
    call_perl_cb(aTHX_ self, self->on_error, 1, &arg);
    FREETMPS;
    LEAVE;
}

static void finish_current_op(pTHX_ ev_mysql_t *self, SV *res_sv, const char *err_str, SV *fields_sv) {
    ev_mysql_op_t *op = self->current_op;
    SV *cb_copy;
    SV *args[3];
    int argc;

    if (!op) return;
    self->current_op = NULL;
    if (self->pending_count > 0) self->pending_count--;

    cb_copy = take_op_cb(op);
    release_op(aTHX_ self, op);

    if (!cb_copy) {
        if (res_sv && res_sv != &PL_sv_yes) SvREFCNT_dec(res_sv);
        if (fields_sv) SvREFCNT_dec(fields_sv);
        return;
    }

    /* Keep callback_depth > 0 across FREETMPS and SvREFCNT_dec(cb_copy) so
     * freeing mortal args or closures holding the last ref to $self defers safely. */
    self->callback_depth++;
    ENTER;
    SAVETMPS;
    if (err_str) {
        if (res_sv && res_sv != &PL_sv_yes) SvREFCNT_dec(res_sv);
        if (fields_sv) SvREFCNT_dec(fields_sv);
        args[0] = &PL_sv_undef;
        args[1] = sv_2mortal(newSVpv(err_str, 0));
        argc = 2;
    } else if (fields_sv) {
        args[0] = sv_2mortal(res_sv);
        args[1] = &PL_sv_undef;
        args[2] = sv_2mortal(fields_sv);
        argc = 3;
    } else {
        args[0] = (res_sv && res_sv != &PL_sv_yes) ? sv_2mortal(res_sv) : &PL_sv_yes;
        args[1] = &PL_sv_undef;
        argc = 2;
    }

    call_sv_eval_safe(aTHX_ cb_copy, argc, args);
    FREETMPS;
    LEAVE;
    SvREFCNT_dec(cb_copy);
    self->callback_depth--;
    check_destroyed(aTHX_ self);
}

static int fail_queued_ops(pTHX_ ev_mysql_t *self, const char *err_str) {
    const char *msg = (err_str && *err_str) ? err_str : "connection finished";
    unsigned int gen = self->reset_gen;
    uint64_t cutoff_seq = self->next_op_seq;

    self->callback_depth++;
    self->in_fail_queue++;

    if (self->current_op) {
        if (self->current_op->type == OP_STREAM && !self->stream_eof_sent) {
            self->stream_eof_sent = 1;
        }
        finish_current_op(aTHX_ self, NULL, msg, NULL);
    }

    while (self->reset_gen == gen && !ngx_queue_empty(&self->op_queue)) {
        ngx_queue_t *q = ngx_queue_head(&self->op_queue);
        ev_mysql_op_t *op = ngx_queue_data(q, ev_mysql_op_t, queue);
        SV *cb_copy = NULL;
        SV *args[2];

        if (!self->destroyed && self->conn && self->state != STATE_DISCONNECTED && op->seq > cutoff_seq) {
            break;
        }

        ngx_queue_remove(q);
        if (self->pending_count > 0) self->pending_count--;

        cb_copy = take_op_cb(op);
        free_op(aTHX_ op);

        if (cb_copy) {
            ENTER;
            SAVETMPS;
            args[0] = &PL_sv_undef;
            args[1] = sv_2mortal(newSVpv(msg, 0));
            call_perl_cb(aTHX_ self, cb_copy, 2, args);
            FREETMPS;
            LEAVE;
            SvREFCNT_dec(cb_copy);
        }
    }
    if (self->reset_gen == gen && ngx_queue_empty(&self->op_queue) && !self->current_op) {
        self->pending_count = 0;
    }
    self->in_fail_queue--;
    self->callback_depth--;
    return check_destroyed(aTHX_ self);
}

static void cleanup_connection(pTHX_ ev_mysql_t *self, int keep_error) {
    int same_pid = (self->pid == getpid());
    int force_shutdown = same_pid && self->conn &&
        (self->stream_res != NULL ||
         (self->state != STATE_IDLE && self->state != STATE_DISCONNECTED &&
          self->state != STATE_CONNECTING));

    stop_all_watchers(self);

    if (!same_pid && self->conn) {
        /* Forked child: replace the inherited socket fd with O_RDONLY /dev/null
         * so cleanup (COM_STMT_CLOSE / COM_QUIT / close) fails with EBADF/EOF
         * on the child descriptor alone without affecting the parent's socket. */
        int fd = mysql_sock_fd(self->conn);
        if (fd >= 0) {
            int dn = open("/dev/null", O_RDONLY);
            if (dn >= 0) {
                dup2(dn, fd);
                close(dn);
            } else {
                close(fd);
            }
        }
    } else if (force_shutdown) {
        int fd = mysql_sock_fd(self->conn);
        if (fd >= 0) shutdown(fd, SHUT_RDWR);
    }

    clear_op_scratch(aTHX_ self);

    invalidate_all_stmts(self, self->conn != NULL);

    if (self->conn) {
        mysql_close(self->conn);
        self->conn = NULL;
    }

    if (!keep_error) {
        self->last_errno = 0;
        replace_str(&self->last_error, NULL);
        self->last_sqlstate[0] = '\0';
    }
    replace_str(&self->deferred_connect_err, NULL);
    self->deferred_connect_ok = 0;

    self->fd        = -1;
    self->state     = STATE_DISCONNECTED;
    self->connected = 0;
    self->closing   = 0;
    self->timed_out = 0;
}

static void abort_connection_with_error(pTHX_ ev_mysql_t *self, const char *msg, unsigned int errnum) {
    char *copy = savepv(msg ? msg : "Lost connection to MySQL server");
    unsigned int gen = self->reset_gen;
    self->callback_depth++;
    set_custom_error(self, errnum ? errnum : CR_SERVER_LOST, copy);
    cleanup_connection(aTHX_ self, 1);
    fail_queued_ops(aTHX_ self, copy);
    if (!self->destroyed && self->reset_gen == gen && self->state == STATE_DISCONNECTED) {
        invoke_on_error(aTHX_ self, copy);
    }
    Safefree(copy);
    self->callback_depth--;
    check_destroyed(aTHX_ self);
}

static void finish_or_abort_sync_op(pTHX_ ev_mysql_t *self, unsigned int eno, const char *msg) {
    const char *m = (msg && *msg) ? msg : "MySQL operation failed";
    if (is_fatal_conn_errno(eno) || !self->conn || mysql_sock_fd(self->conn) < 0) {
        abort_connection_with_error(aTHX_ self, m, eno);
    } else {
        finish_current_op(aTHX_ self, NULL, m, NULL);
    }
}

static void fail_stmt_sync_op(pTHX_ ev_mysql_t *self, MYSQL_STMT *stmt, const char *fallback) {
    unsigned int e;
    char *msg;
    if (stmt) cache_stmt_error(self, stmt);
    e = self->last_errno;
    msg = savepv(self->last_error ? self->last_error : fallback);
    finish_or_abort_sync_op(aTHX_ self, e, msg);
    Safefree(msg);
}

/* ------------------------------------------------------------------ */
/* Result / field building                                            */
/* ------------------------------------------------------------------ */

static SV *build_fields_av(pTHX_ ev_mysql_t *self, MYSQL_FIELD *fields, unsigned int nf) {
    AV *fav = newAV();
    if (nf > 0) {
        unsigned int c;
        SV **arr;
        int conn_utf8 = self->utf8 && is_conn_utf8(self);
        av_extend(fav, nf - 1);
        arr = AvARRAY(fav);
        for (c = 0; c < nf; c++) {
            SV *name_sv = newSVpvn(fields[c].name ? fields[c].name : "", fields[c].name_length);
            if (self->utf8 && (conn_utf8 || is_utf8_charset(fields[c].charsetnr))) {
                SvUTF8_on(name_sv);
            }
            arr[c] = name_sv;
        }
        AvFILLp(fav) = (SSize_t)nf - 1;
    }
    return newRV_noinc((SV *)fav);
}

static SV *build_row_av_mask(pTHX_ ev_mysql_t *self, MYSQL_ROW row, unsigned long *lengths,
                             MYSQL_FIELD *fields, unsigned int nf, uint64_t utf8_mask, int use_mask) {
    AV *rav = newAV();
    if (nf > 0) {
        unsigned int c;
        SV **arr;
        int do_utf8 = self->utf8;
        av_extend(rav, nf - 1);
        arr = AvARRAY(rav);
        for (c = 0; c < nf; c++) {
            if (!row[c]) {
                arr[c] = newSV(0);
            } else {
                SV *val = newSVpvn(row[c], lengths ? lengths[c] : strlen(row[c]));
                if (do_utf8) {
                    int is_u8 = (use_mask && c < 64)
                        ? (int)((utf8_mask >> c) & 1)
                        : (fields && is_utf8_charset(fields[c].charsetnr));
                    if (is_u8) SvUTF8_on(val);
                }
                arr[c] = val;
            }
        }
        AvFILLp(rav) = (SSize_t)nf - 1;
    }
    return newRV_noinc((SV *)rav);
}

static void append_row_fast(pTHX_ AV *rows_av, SV ***rows_arr_p, my_ulonglong *row_idx_p,
                            my_ulonglong cap, SV *row_rv) {
    if (*rows_arr_p && *row_idx_p < cap) {
        (*rows_arr_p)[(*row_idx_p)++] = row_rv;
        return;
    }
    if (*rows_arr_p) {
        if (*row_idx_p > 0) AvFILLp(rows_av) = (SSize_t)(*row_idx_p - 1);
        *rows_arr_p = NULL;
    }
    av_push(rows_av, row_rv);
}

static void build_stored_result(pTHX_ ev_mysql_t *self, MYSQL_RES *res, SV **out_rows, SV **out_fields) {
    AV *rows_av = newAV();
    unsigned int nf = mysql_num_fields(res);
    MYSQL_FIELD *fields = mysql_fetch_fields(res);
    my_ulonglong nr = mysql_num_rows(res);
    SV **rows_arr = NULL;
    my_ulonglong row_idx = 0;
    MYSQL_ROW row;

    if (nr > 0) {
        av_extend(rows_av, (SSize_t)(nr - 1));
        rows_arr = AvARRAY(rows_av);
    }
    if (self->utf8 && fields && nr > 1 && nf > 0) {
        unsigned char col_utf8_stack[64];
        unsigned char *col_utf8 = col_utf8_stack;
        unsigned int c;
        if (nf > 64) Newx(col_utf8, nf, unsigned char);
        for (c = 0; c < nf; c++) {
            col_utf8[c] = is_utf8_charset(fields[c].charsetnr) ? 1 : 0;
        }
        while ((row = mysql_fetch_row(res)) != NULL) {
            unsigned long *lengths = mysql_fetch_lengths(res);
            AV *rav = newAV();
            SV **r_arr;
            av_extend(rav, nf - 1);
            r_arr = AvARRAY(rav);
            for (c = 0; c < nf; c++) {
                if (!row[c]) {
                    r_arr[c] = newSV(0);
                } else {
                    SV *val = newSVpvn(row[c], lengths ? lengths[c] : strlen(row[c]));
                    if (col_utf8[c]) SvUTF8_on(val);
                    r_arr[c] = val;
                }
            }
            AvFILLp(rav) = (SSize_t)nf - 1;
            append_row_fast(aTHX_ rows_av, &rows_arr, &row_idx, nr, newRV_noinc((SV *)rav));
        }
        if (col_utf8 != col_utf8_stack) Safefree(col_utf8);
    } else {
        while ((row = mysql_fetch_row(res)) != NULL) {
            unsigned long *lengths = mysql_fetch_lengths(res);
            SV *row_rv = build_row_av_mask(aTHX_ self, row, lengths, fields, nf, 0, 0);
            append_row_fast(aTHX_ rows_av, &rows_arr, &row_idx, nr, row_rv);
        }
    }
    if (rows_arr && row_idx > 0) {
        AvFILLp(rows_av) = (SSize_t)(row_idx - 1);
    }

    *out_rows   = newRV_noinc((SV *)rows_av);
    *out_fields = build_fields_av(aTHX_ self, fields, nf);
}

/* ------------------------------------------------------------------ */
/* Prepared statements: bind & execute                                */
/* ------------------------------------------------------------------ */

static void ensure_stmt_in_binds(ev_mysql_stmt_t *ctx, int init_null) {
    if (ctx->in_cap < ctx->param_count) {
        free_stmt_bind_storage(ctx);
        ctx->in_cap = ctx->param_count;
        Newxz(ctx->in_binds,       ctx->in_cap, MYSQL_BIND);
        Newxz(ctx->in_lengths,     ctx->in_cap, unsigned long);
        Newxz(ctx->in_buf_cap,     ctx->in_cap, unsigned long);
        Newxz(ctx->in_is_null,     ctx->in_cap, bool);
        Newxz(ctx->long_data_sent, ctx->in_cap, bool);
        if (init_null) {
            unsigned int k;
            for (k = 0; k < ctx->param_count; k++) {
                ctx->in_binds[k].buffer_type = MYSQL_TYPE_NULL;
                ctx->in_is_null[k] = 1;
                ctx->in_binds[k].is_null = &ctx->in_is_null[k];
                ctx->in_binds[k].length  = &ctx->in_lengths[k];
            }
        }
    }
}

static void *reuse_stmt_in_buf(ev_mysql_stmt_t *ctx, unsigned int i, unsigned long need) {
    if (ctx->in_binds[i].buffer && ctx->in_buf_cap[i] >= need) {
        return ctx->in_binds[i].buffer;
    }
    if (ctx->in_binds[i].buffer) {
        Safefree(ctx->in_binds[i].buffer);
    }
    Newx(ctx->in_binds[i].buffer, need, char);
    ctx->in_buf_cap[i] = need;
    return ctx->in_binds[i].buffer;
}

static int bind_stmt_from_c_params(pTHX_ ev_mysql_t *self, ev_mysql_stmt_t *ctx,
                                   const ev_mysql_param_t *params, unsigned int nparams, char **err_out) {
    unsigned int i;

    if (nparams != ctx->param_count) {
        *err_out = savepv(form("Parameter count mismatch: expected %u, got %u",
                               ctx->param_count, nparams));
        return -1;
    }
    if (ctx->param_count == 0) return 0;

    ensure_stmt_in_binds(ctx, 0);

    for (i = 0; i < ctx->param_count; i++) {
        const ev_mysql_param_t *p = &params[i];
        void *saved_buf = ctx->in_binds[i].buffer;

        Zero(&ctx->in_binds[i], 1, MYSQL_BIND);
        ctx->in_binds[i].buffer  = saved_buf;
        ctx->in_binds[i].length  = &ctx->in_lengths[i];
        ctx->in_binds[i].is_null = &ctx->in_is_null[i];
        ctx->long_data_sent[i] = 0;

        switch (p->kind) {
        case PARAM_NULL:
            ctx->in_binds[i].buffer_type = MYSQL_TYPE_NULL;
            ctx->in_is_null[i] = 1;
            ctx->in_lengths[i] = 0;
            break;
        case PARAM_IV: {
            int64_t *buf = (int64_t *)reuse_stmt_in_buf(ctx, i, (unsigned long)sizeof(int64_t));
            *buf = p->u.iv;
            ctx->in_binds[i].buffer_type   = MYSQL_TYPE_LONGLONG;
            ctx->in_binds[i].is_unsigned   = 0;
            ctx->in_binds[i].buffer_length = sizeof(int64_t);
            ctx->in_is_null[i] = 0;
            ctx->in_lengths[i] = sizeof(int64_t);
            break;
        }
        case PARAM_UV: {
            uint64_t *buf = (uint64_t *)reuse_stmt_in_buf(ctx, i, (unsigned long)sizeof(uint64_t));
            *buf = p->u.uv;
            ctx->in_binds[i].buffer_type   = MYSQL_TYPE_LONGLONG;
            ctx->in_binds[i].is_unsigned   = 1;
            ctx->in_binds[i].buffer_length = sizeof(uint64_t);
            ctx->in_is_null[i] = 0;
            ctx->in_lengths[i] = sizeof(uint64_t);
            break;
        }
        case PARAM_NV: {
            double *buf = (double *)reuse_stmt_in_buf(ctx, i, (unsigned long)sizeof(double));
            *buf = p->u.nv;
            ctx->in_binds[i].buffer_type   = MYSQL_TYPE_DOUBLE;
            ctx->in_binds[i].buffer_length = sizeof(double);
            ctx->in_is_null[i] = 0;
            ctx->in_lengths[i] = sizeof(double);
            break;
        }
        case PARAM_STR: {
            STRLEN len = p->u.str.len;
            char *buf = (char *)reuse_stmt_in_buf(ctx, i, (unsigned long)(len > 0 ? len : 1));
            if (len > 0) Copy(p->u.str.ptr, buf, len, char);
            ctx->in_binds[i].buffer_type   = MYSQL_TYPE_STRING;
            ctx->in_binds[i].buffer_length = (unsigned long)len;
            ctx->in_is_null[i] = 0;
            ctx->in_lengths[i] = (unsigned long)len;
            break;
        }
        }
    }

    if (mysql_stmt_bind_param(ctx->stmt, ctx->in_binds)) {
        cache_stmt_error(self, ctx->stmt);
        *err_out = savepv(self->last_error ? self->last_error : "mysql_stmt_bind_param failed");
        return -1;
    }
    return 0;
}

static void exec_stmt_sync(pTHX_ ev_mysql_t *self, ev_mysql_op_t *op) {
    ev_mysql_stmt_t *ctx = find_stmt(self, op->iv_arg);
    MYSQL_RES *meta = NULL;
    MYSQL_FIELD *fields = NULL;
    unsigned int nf = 0;
    SV *result_sv = NULL;
    SV *fields_sv = NULL;
    char *err_msg = NULL;
    unsigned int err_eno = 0;
    unsigned int c;
    MYSQL_BIND *out_binds = NULL;
    unsigned long *out_len = NULL;
    bool *out_null = NULL;
    bool *out_err = NULL;

    if (!self->conn || !self->connected) {
        finish_current_op(aTHX_ self, NULL, "Not connected", NULL);
        return;
    }
    if (!ctx || !ctx->stmt) {
        finish_current_op(aTHX_ self, NULL, "Invalid or closed statement handle", NULL);
        return;
    }

    if (op->has_params) {
        if (bind_stmt_from_c_params(aTHX_ self, ctx, op->params, op->param_count, &err_msg) != 0) {
            finish_current_op(aTHX_ self, NULL, err_msg, NULL);
            Safefree(err_msg);
            return;
        }
    } else if (ctx->param_count > 0 && !ctx->has_manual_bind) {
        finish_current_op(aTHX_ self, NULL, "Missing parameters for prepared statement", NULL);
        return;
    } else if (ctx->has_manual_bind && ctx->in_binds) {
        int any_long_data = 0;
        for (c = 0; c < ctx->param_count; c++) {
            if (ctx->long_data_sent && ctx->long_data_sent[c]) {
                any_long_data = 1;
                break;
            }
        }
        /* Re-bind only when no send_long_data chunks are active so
         * mysql_stmt_bind_param cannot clear stmt->params[c].long_data_used. */
        if (!any_long_data && !ctx->stmt->bind_param_done) {
            if (mysql_stmt_bind_param(ctx->stmt, ctx->in_binds)) {
                cache_stmt_error(self, ctx->stmt);
                finish_current_op(aTHX_ self, NULL, self->last_error ? self->last_error : "mysql_stmt_bind_param failed", NULL);
                return;
            }
        }
    }

    if (mysql_stmt_execute(ctx->stmt) != 0) {
        if (ctx->long_data_sent && ctx->in_cap > 0) {
            Zero(ctx->long_data_sent, ctx->in_cap, bool);
        }
        fail_stmt_sync_op(aTHX_ self, ctx->stmt, "mysql_stmt_execute failed");
        return;
    }

    if (ctx->long_data_sent && ctx->in_cap > 0) {
        Zero(ctx->long_data_sent, ctx->in_cap, bool);
    }

    cache_conn_status(self);
    nf = mysql_stmt_field_count(ctx->stmt);

    if (nf > 0) {
        AV *rows_av;
        MYSQL_FIELD *meta_fields = NULL;
        if (mysql_stmt_store_result(ctx->stmt) != 0) {
            fail_stmt_sync_op(aTHX_ self, ctx->stmt, "mysql_stmt_store_result failed");
            return;
        }
        rows_av = newAV();

        /* Prefer conn->fields when field_count matches: libmysqlclient updates
         * conn->fields on every execute, whereas stmt->fields from
         * mysql_stmt_result_metadata() can keep a prior CALL's last result.
         * Only allocate result metadata when conn->fields does not match. */
        if (self->conn->fields && self->conn->field_count == nf) {
            meta_fields = self->conn->fields;
        } else {
            meta = mysql_stmt_result_metadata(ctx->stmt);
            if (meta) fields = mysql_fetch_fields(meta);
            meta_fields = fields;
        }

        if (nf > ctx->out_cap) {
            unsigned int old_cap = ctx->out_cap;
            if (ctx->out_binds) {
                for (c = 0; c < old_cap; c++) {
                    if (ctx->out_binds[c].buffer) Safefree(ctx->out_binds[c].buffer);
                }
                Safefree(ctx->out_binds);
                Safefree(ctx->out_len);
                Safefree(ctx->out_null);
                Safefree(ctx->out_err);
            }
            Newxz(ctx->out_binds, nf, MYSQL_BIND);
            Newxz(ctx->out_len,   nf, unsigned long);
            Newxz(ctx->out_null,  nf, bool);
            Newxz(ctx->out_err,   nf, bool);
            ctx->out_cap = nf;
            for (c = 0; c < nf; c++) {
                ctx->out_binds[c].buffer_type = MYSQL_TYPE_STRING;
                ctx->out_binds[c].length      = &ctx->out_len[c];
                ctx->out_binds[c].is_null     = &ctx->out_null[c];
                ctx->out_binds[c].error       = &ctx->out_err[c];
            }
        }
        out_binds = ctx->out_binds;
        out_len   = ctx->out_len;
        out_null  = ctx->out_null;
        out_err   = ctx->out_err;

        for (c = 0; c < nf; c++) {
            unsigned long blen = (meta_fields && meta_fields[c].max_length > 0) ? meta_fields[c].max_length : 64;
            if (blen < 64) blen = 64;
            if (blen > 1048576UL) blen = 1048576UL;
            out_null[c] = 0;
            out_err[c]  = 0;
            out_len[c]  = 0;
            if (!out_binds[c].buffer || out_binds[c].buffer_length < blen) {
                if (out_binds[c].buffer) Safefree(out_binds[c].buffer);
                Newx(out_binds[c].buffer, blen, char);
                out_binds[c].buffer_length = blen;
            }
        }

        if (mysql_stmt_bind_result(ctx->stmt, out_binds) != 0) {
            cache_stmt_error(self, ctx->stmt);
            err_eno = self->last_errno;
            err_msg = savepv(self->last_error ? self->last_error : "mysql_stmt_bind_result failed");
        } else {
            my_ulonglong nr = mysql_stmt_num_rows(ctx->stmt);
            SV **rows_arr = NULL;
            my_ulonglong row_idx = 0;
            unsigned char col_utf8_stack[64];
            unsigned char *col_utf8 = col_utf8_stack;
            int do_utf8 = self->utf8 && meta_fields;
            int use_col_utf8 = 0;
            int frc;
            if (nr > 0) {
                av_extend(rows_av, (SSize_t)(nr - 1));
                rows_arr = AvARRAY(rows_av);
            }
            if (do_utf8 && nr > 1) {
                if (nf > 64) Newx(col_utf8, nf, unsigned char);
                for (c = 0; c < nf; c++) {
                    col_utf8[c] = is_utf8_charset(meta_fields[c].charsetnr) ? 1 : 0;
                }
                use_col_utf8 = 1;
            }
            while (1) {
                AV *row_av;
                SV **r_arr;
                frc = mysql_stmt_fetch(ctx->stmt);
                if (frc == MYSQL_NO_DATA) break;
                if (frc == 1) {
                    cache_stmt_error(self, ctx->stmt);
                    err_eno = self->last_errno;
                    err_msg = savepv(self->last_error ? self->last_error : "mysql_stmt_fetch failed");
                    break;
                }
                row_av = newAV();
                av_extend(row_av, nf - 1);
                r_arr = AvARRAY(row_av);
                for (c = 0; c < nf; c++) {
                    if (out_null[c]) {
                        r_arr[c] = newSV(0);
                    } else if (frc == MYSQL_DATA_TRUNCATED && out_err[c]) {
                        unsigned long full_len = out_len[c];
                        char *big;
                        MYSQL_BIND col_bind;
                        Zero(&col_bind, 1, MYSQL_BIND);
                        Newx(big, full_len > 0 ? full_len : 1, char);
                        col_bind.buffer_type   = MYSQL_TYPE_STRING;
                        col_bind.buffer        = big;
                        col_bind.buffer_length = full_len;
                        col_bind.length        = &out_len[c];
                        col_bind.is_null       = &out_null[c];
                        if (mysql_stmt_fetch_column(ctx->stmt, &col_bind, c, 0) == 0 && !out_null[c]) {
                            SV *val = newSVpvn(big, full_len);
                            if (do_utf8 && (use_col_utf8 ? col_utf8[c] : is_utf8_charset(meta_fields[c].charsetnr))) {
                                SvUTF8_on(val);
                            }
                            r_arr[c] = val;
                        } else {
                            r_arr[c] = newSV(0);
                        }
                        Safefree(big);
                    } else {
                        SV *val = newSVpvn((const char *)out_binds[c].buffer, out_len[c]);
                        if (do_utf8 && (use_col_utf8 ? col_utf8[c] : is_utf8_charset(meta_fields[c].charsetnr))) {
                            SvUTF8_on(val);
                        }
                        r_arr[c] = val;
                    }
                }
                AvFILLp(row_av) = (SSize_t)nf - 1;
                append_row_fast(aTHX_ rows_av, &rows_arr, &row_idx, nr, newRV_noinc((SV *)row_av));
            }
            if (rows_arr && row_idx > 0) {
                AvFILLp(rows_av) = (SSize_t)(row_idx - 1);
            }
            if (use_col_utf8 && col_utf8 != col_utf8_stack) Safefree(col_utf8);
        }

        if (!err_msg) {
            result_sv = newRV_noinc((SV *)rows_av);
            if (meta_fields) {
                fields_sv = build_fields_av(aTHX_ self, meta_fields, nf);
            } else {
                fields_sv = newRV_noinc((SV *)newAV());
            }
        } else {
            SvREFCNT_dec((SV *)rows_av);
        }
        if (meta) mysql_free_result(meta);
        mysql_stmt_free_result(ctx->stmt);
    } else {
        my_ulonglong aff = mysql_stmt_affected_rows(ctx->stmt);
        self->last_affected_rows = aff;
        self->last_insert_id     = mysql_stmt_insert_id(ctx->stmt);
        result_sv = newSViv((IV)aff);
    }

    /* Drain any additional result sets (e.g. stored procedure CALL) */
    while (self->conn && mysql_more_results(self->conn)) {
        int nrc = mysql_stmt_next_result(ctx->stmt);
        if (nrc > 0) {
            if (!err_msg) {
                cache_stmt_error(self, ctx->stmt);
                err_eno = self->last_errno;
                err_msg = savepv(self->last_error ? self->last_error : "mysql_stmt_next_result failed");
            }
            /* Reset stmt metadata cursor after mid-CALL failure so subsequent
             * executions do not inherit stale secondary result metadata. */
            mysql_stmt_reset(ctx->stmt);
            break;
        }
        if (nrc < 0) break;
        if (mysql_stmt_field_count(ctx->stmt) > 0) {
            if (mysql_stmt_store_result(ctx->stmt) != 0) {
                if (!err_msg) {
                    cache_stmt_error(self, ctx->stmt);
                    err_eno = self->last_errno;
                    err_msg = savepv(self->last_error ? self->last_error : "mysql_stmt_store_result failed");
                }
                mysql_stmt_reset(ctx->stmt);
                break;
            }
            mysql_stmt_free_result(ctx->stmt);
        }
    }

    /* Clear long_data_sent flags for next execution unless bound again */
    if (ctx->long_data_sent) {
        Zero(ctx->long_data_sent, ctx->in_cap, bool);
    }

    if (err_msg) {
        if (result_sv) SvREFCNT_dec(result_sv);
        if (fields_sv) SvREFCNT_dec(fields_sv);
        finish_or_abort_sync_op(aTHX_ self, err_eno, err_msg);
        Safefree(err_msg);
    } else {
        finish_current_op(aTHX_ self, result_sv, NULL, fields_sv);
    }
}

/* ------------------------------------------------------------------ */
/* Apply options & start connection                                   */
/* ------------------------------------------------------------------ */

static void apply_mysql_options(ev_mysql_t *self) {
    MYSQL *c = self->conn;
    bool arg_true = 1;

    if (self->connect_timeout > 0) {
        unsigned int t = self->connect_timeout;
        mysql_options(c, MYSQL_OPT_CONNECT_TIMEOUT, &t);
    }
    if (self->read_timeout > 0) {
        unsigned int t = self->read_timeout;
        mysql_options(c, MYSQL_OPT_READ_TIMEOUT, &t);
    }
    if (self->write_timeout > 0) {
        unsigned int t = self->write_timeout;
        mysql_options(c, MYSQL_OPT_WRITE_TIMEOUT, &t);
    }
    if (self->compress) {
        mysql_options(c, MYSQL_OPT_COMPRESS, NULL);
    }
    if (self->charset) {
        mysql_options(c, MYSQL_SET_CHARSET_NAME, self->charset);
    }
    if (self->init_command) {
        mysql_options(c, MYSQL_INIT_COMMAND, self->init_command);
    }
    if (self->ssl_key)    mysql_options(c, MYSQL_OPT_SSL_KEY, self->ssl_key);
    if (self->ssl_cert)   mysql_options(c, MYSQL_OPT_SSL_CERT, self->ssl_cert);
    if (self->ssl_ca)     mysql_options(c, MYSQL_OPT_SSL_CA, self->ssl_ca);
    if (self->ssl_capath) mysql_options(c, MYSQL_OPT_SSL_CAPATH, self->ssl_capath);
    if (self->ssl_cipher) mysql_options(c, MYSQL_OPT_SSL_CIPHER, self->ssl_cipher);

    if (self->ssl_mode_set) {
        unsigned int m = self->ssl_mode;
        mysql_options(c, MYSQL_OPT_SSL_MODE, &m);
    } else if (self->ssl_verify_server_cert == 1) {
        unsigned int m = SSL_MODE_VERIFY_IDENTITY;
        mysql_options(c, MYSQL_OPT_SSL_MODE, &m);
    } else if (self->ssl_verify_server_cert == 0 && (self->ssl_ca || self->ssl_capath)) {
        unsigned int m = SSL_MODE_REQUIRED;
        mysql_options(c, MYSQL_OPT_SSL_MODE, &m);
    }

    PERL_UNUSED_VAR(arg_true);
}

static unsigned long build_client_flags(ev_mysql_t *self) {
    unsigned long flags = CLIENT_REMEMBER_OPTIONS | CLIENT_MULTI_RESULTS;
    if (self->multi_statements) flags |= CLIENT_MULTI_STATEMENTS;
    if (self->found_rows)       flags |= CLIENT_FOUND_ROWS;
    return flags;
}

/* ------------------------------------------------------------------ */
/* Non-blocking state machine core                                    */
/* ------------------------------------------------------------------ */

static void start_next_op(pTHX_ ev_mysql_t *self) {
    ngx_queue_t *q;
    ev_mysql_op_t *op;

    if (self->destroyed || !self->conn || !self->connected) return;
    if (self->state != STATE_IDLE || self->current_op) return;
    if (ngx_queue_empty(&self->op_queue)) return;

    q = ngx_queue_head(&self->op_queue);
    ngx_queue_remove(q);
    op = ngx_queue_data(q, ev_mysql_op_t, queue);
    self->current_op = op;
    clear_op_scratch(aTHX_ self);

    switch (op->type) {
    case OP_QUERY:
    case OP_PING:
    case OP_SELECT_DB:
    case OP_COMMIT:
    case OP_ROLLBACK:
    case OP_AUTOCOMMIT:
        self->state = STATE_REAL_QUERY;
        arm_timeout(self, self->read_timeout);
        drive_state_machine(aTHX_ self);
        break;

    case OP_STREAM:
        self->state = STATE_STREAM_QUERY;
        arm_timeout(self, self->read_timeout);
        drive_state_machine(aTHX_ self);
        break;

    case OP_RESET_CONNECTION:
        self->state = STATE_RESET_CONNECTION;
        arm_timeout(self, self->read_timeout);
        drive_state_machine(aTHX_ self);
        break;

    case OP_PREPARE:
    case OP_EXECUTE:
    case OP_SEND_LONG_DATA:
    case OP_STMT_RESET:
    case OP_CLOSE_STMT:
    case OP_SET_CHARSET:
    case OP_CHANGE_USER:
    case OP_CLOSE_ASYNC:
        /* Defer synchronous libmysqlclient calls by one 0-delay EV tick
         * so callbacks always run from EV::run and never synchronously inside
         * the Perl caller frame. */
        if (self->io_active) stop_io(self);
        self->state = STATE_DEFERRED_OP;
        schedule_deferred(self);
        break;
    }
}

static void get_query_sql(ev_mysql_op_t *op, const char **out_sql, unsigned long *out_len) {
    switch (op->type) {
    case OP_PING:
        *out_sql = "do 1";
        *out_len = 4;
        break;
    case OP_COMMIT:
        *out_sql = "commit";
        *out_len = 6;
        break;
    case OP_ROLLBACK:
        *out_sql = "rollback";
        *out_len = 8;
        break;
    case OP_AUTOCOMMIT:
        if (op->iv_arg) {
            *out_sql = "set autocommit=1";
            *out_len = 16;
        } else {
            *out_sql = "set autocommit=0";
            *out_len = 16;
        }
        break;
    default:
        *out_sql = op->sql ? op->sql : "";
        *out_len = (unsigned long)op->sql_len;
        break;
    }
}

static void handle_query_error(pTHX_ ev_mysql_t *self) {
    unsigned int e;
    char *msg;
    stop_timeout(self);
    cache_conn_error(self);
    e = self->last_errno;
    msg = savepv(self->last_error ? self->last_error : "MySQL query failed");
    clear_op_scratch(aTHX_ self);

    if (is_fatal_conn_errno(e) || mysql_sock_fd(self->conn) < 0) {
        stop_io(self);
        abort_connection_with_error(aTHX_ self, msg, e);
        Safefree(msg);
        return;
    }

    self->callback_depth++;
    self->state = STATE_IDLE;
    finish_current_op(aTHX_ self, NULL, msg, NULL);
    Safefree(msg);
    if (!self->destroyed && self->connected && self->state == STATE_IDLE) {
        start_next_op(aTHX_ self);
    }
    if (!self->destroyed && self->state == STATE_IDLE) stop_io(self);
    self->callback_depth--;
    check_destroyed(aTHX_ self);
}

static void complete_query_op(pTHX_ ev_mysql_t *self) {
    ev_mysql_op_t *op = self->current_op;
    SV *res_sv = self->op_result_sv;
    SV *fld_sv = self->op_fields_sv;
    char *sec_err = self->op_err;
    unsigned int eno = self->op_errno;
    unsigned int gen = self->reset_gen;
    int fatal = sec_err && (is_fatal_conn_errno(eno) || !self->conn || mysql_sock_fd(self->conn) < 0);

    self->callback_depth++;
    self->op_result_sv = NULL;
    self->op_fields_sv = NULL;
    self->op_err = NULL;
    stop_timeout(self);

    if (op && op->type == OP_SELECT_DB && op->arg1 && !sec_err) {
        replace_str(&self->database, op->arg1);
    }
    if (op && (op->type == OP_PING || op->type == OP_SELECT_DB ||
               op->type == OP_COMMIT || op->type == OP_ROLLBACK ||
               op->type == OP_AUTOCOMMIT)) {
        if (res_sv) SvREFCNT_dec(res_sv);
        if (fld_sv) SvREFCNT_dec(fld_sv);
        res_sv = &PL_sv_yes;
        fld_sv = NULL;
    }

    if (res_sv) {
        /* First result succeeded: deliver it cleanly even if a secondary
         * statement in a multi-statement batch errored or killed the link. */
        if (fatal) {
            set_custom_error(self, eno ? eno : CR_SERVER_LOST, sec_err);
            cleanup_connection(aTHX_ self, 1);
        } else {
            self->state = STATE_IDLE;
        }
        finish_current_op(aTHX_ self, res_sv, NULL, fld_sv);
        if (!self->destroyed && sec_err && self->reset_gen == gen) {
            if (fatal) {
                fail_queued_ops(aTHX_ self, sec_err);
                if (!self->destroyed && self->reset_gen == gen) {
                    invoke_on_error(aTHX_ self, sec_err);
                }
            } else {
                invoke_on_error(aTHX_ self, sec_err);
            }
        }
        if (sec_err) Safefree(sec_err);
    } else if (sec_err) {
        if (fatal) {
            abort_connection_with_error(aTHX_ self, sec_err, eno);
            Safefree(sec_err);
            self->callback_depth--;
            check_destroyed(aTHX_ self);
            return;
        }
        self->state = STATE_IDLE;
        finish_current_op(aTHX_ self, NULL, sec_err, NULL);
        Safefree(sec_err);
    } else {
        self->state = STATE_IDLE;
        finish_current_op(aTHX_ self, NULL, NULL, NULL);
    }

    if (!self->destroyed && self->connected && self->state == STATE_IDLE) {
        start_next_op(aTHX_ self);
    }
    if (!self->destroyed && self->state == STATE_IDLE) stop_io(self);
    self->callback_depth--;
    check_destroyed(aTHX_ self);
}

static void finish_stream_op(pTHX_ ev_mysql_t *self, const char *err_str) {
    ev_mysql_op_t *op = self->current_op;
    SV *cb_copy = NULL;
    SV *args[2];
    int argc;
    char *sec_err = NULL;
    unsigned int eno = self->stream_errno;
    unsigned int gen = self->reset_gen;
    int fatal;

    self->callback_depth++;
    stop_timeout(self);

    if (self->stream_res) {
        mysql_free_result(self->stream_res);
        self->stream_res = NULL;
    }
    if (self->stream_fields) {
        if (!PL_dirty) SvREFCNT_dec(self->stream_fields);
        self->stream_fields = NULL;
    }

    if (self->stream_err) {
        sec_err = savepv(self->stream_err);
        Safefree(self->stream_err);
        self->stream_err = NULL;
    }
    self->stream_errno = 0;

    fatal = sec_err && (is_fatal_conn_errno(eno) || !self->conn || mysql_sock_fd(self->conn) < 0);

    if (op) {
        self->current_op = NULL;
        if (self->pending_count > 0) self->pending_count--;
        cb_copy = take_op_cb(op);
        release_op(aTHX_ self, op);
    }

    if (fatal) {
        set_custom_error(self, eno ? eno : CR_SERVER_LOST, sec_err);
        cleanup_connection(aTHX_ self, 1);
    } else {
        self->state = STATE_IDLE;
    }

    if (cb_copy) {
        ENTER;
        SAVETMPS;
        if (err_str && !self->stream_first_done) {
            args[0] = &PL_sv_undef;
            args[1] = sv_2mortal(newSVpv(err_str, 0));
            argc = 2;
        } else {
            args[0] = &PL_sv_undef;
            argc = 1;
        }
        call_perl_cb(aTHX_ self, cb_copy, argc, args);
        FREETMPS;
        LEAVE;
        SvREFCNT_dec(cb_copy);
    }

    if (!self->destroyed && sec_err && self->reset_gen == gen) {
        if (fatal) {
            fail_queued_ops(aTHX_ self, sec_err);
        }
        if (!self->destroyed && self->reset_gen == gen) {
            invoke_on_error(aTHX_ self, sec_err);
        }
    }
    if (sec_err) Safefree(sec_err);

    if (!self->destroyed && self->connected && self->state == STATE_IDLE) {
        start_next_op(aTHX_ self);
    }
    if (!self->destroyed && self->state == STATE_IDLE) stop_io(self);
    self->callback_depth--;
    check_destroyed(aTHX_ self);
}

static void handle_stream_error(pTHX_ ev_mysql_t *self) {
    unsigned int e;
    char *msg;
    cache_conn_error(self);
    e = self->last_errno;
    msg = savepv(self->last_error ? self->last_error : "MySQL stream query failed");
    if (self->stream_res) {
        mysql_free_result(self->stream_res);
        self->stream_res = NULL;
    }
    if (is_fatal_conn_errno(e) || mysql_sock_fd(self->conn) < 0) {
        abort_connection_with_error(aTHX_ self, msg, e);
        Safefree(msg);
        return;
    }
    finish_stream_op(aTHX_ self, msg);
    Safefree(msg);
}

static int drive_once(pTHX_ ev_mysql_t *self) {
    /* Return: 1 = made progress / continue immediately, 0 = NET_ASYNC_NOT_READY, -1 = finished or destroyed */
    enum net_async_status st;

    if (self->destroyed || !self->conn) return -1;

    switch (self->state) {
    case STATE_CONNECTING: {
        if (self->deferred_connect_ok) {
            self->deferred_connect_ok = 0;
            self->callback_depth++;
            stop_timeout(self);
            stop_io(self);
            if (self->loop) ev_timer_stop(self->loop, &self->poll_timer);
            self->fd = mysql_sock_fd(self->conn);
            self->last_thread_id = mysql_thread_id(self->conn);
            self->connected = 1;
            self->state = STATE_IDLE;
            invoke_on_connect(aTHX_ self);
            if (!self->destroyed && self->connected && self->state == STATE_IDLE) {
                start_next_op(aTHX_ self);
            }
            self->callback_depth--;
            check_destroyed(aTHX_ self);
            return -1;
        }
        if (self->deferred_connect_err) {
            char *err = savepv(self->deferred_connect_err);
            unsigned int gen = self->reset_gen;
            self->callback_depth++;
            stop_timeout(self);
            stop_io(self);
            if (self->loop) ev_timer_stop(self->loop, &self->poll_timer);
            cleanup_connection(aTHX_ self, 1);
            fail_queued_ops(aTHX_ self, err);
            if (!self->destroyed && self->reset_gen == gen &&
                self->state == STATE_DISCONNECTED) {
                invoke_on_error(aTHX_ self, err);
            }
            Safefree(err);
            self->callback_depth--;
            check_destroyed(aTHX_ self);
            return -1;
        }
        errno = 0;
        st = mysql_real_connect_nonblocking(
            self->conn,
            self->host,
            self->user,
            self->password,
            self->database,
            self->port,
            self->unix_socket,
            build_client_flags(self)
        );
        if (st == NET_ASYNC_NOT_READY) return 0;

        stop_timeout(self);
        stop_io(self);
        if (self->loop) ev_timer_stop(self->loop, &self->poll_timer);

        if (st == NET_ASYNC_ERROR) {
            cache_conn_error(self);
            if (self->in_sync_connect) {
                char *err = savepv(self->last_error ? self->last_error : "MySQL connection failed");
                if (self->unix_socket) {
                    cleanup_connection(aTHX_ self, 1);
                    self->in_sync_connect = 0;
                    SAVEFREEPV(err);
                    croak("connect failed: %s", err);
                }
                /* Defer TCP connect errors to EV::run so callers can still attach
                 * on_error / queue ops / call finish() after connect(). */
                replace_str(&self->deferred_connect_err, err);
                Safefree(err);
                if (self->loop) {
                    ev_timer_stop(self->loop, &self->poll_timer);
                    ev_timer_set(&self->poll_timer, 0., 0.);
                    ev_timer_start(self->loop, &self->poll_timer);
                }
                return -1;
            }
            {
                char *err = savepv(self->last_error ? self->last_error : "MySQL connection failed");
                unsigned int gen = self->reset_gen;
                self->callback_depth++;
                cleanup_connection(aTHX_ self, 1);
                fail_queued_ops(aTHX_ self, err);
                if (!self->destroyed && self->reset_gen == gen &&
                    self->state == STATE_DISCONNECTED) {
                    invoke_on_error(aTHX_ self, err);
                }
                Safefree(err);
                self->callback_depth--;
                check_destroyed(aTHX_ self);
                return -1;
            }
        }

        /* NET_ASYNC_COMPLETE */
        self->fd = mysql_sock_fd(self->conn);
        self->last_thread_id = mysql_thread_id(self->conn);
        if (self->in_sync_connect && self->loop) {
            /* Defer on_connect to EV::run so callers assigning `$m = EV::mysql->new(...)`
             * or chaining `$m->connect(...); $m->on_connect(...)` see the new object. */
            self->deferred_connect_ok = 1;
            ev_timer_stop(self->loop, &self->poll_timer);
            ev_timer_set(&self->poll_timer, 0., 0.);
            ev_timer_start(self->loop, &self->poll_timer);
            return -1;
        }
        self->callback_depth++;
        self->connected = 1;
        self->state = STATE_IDLE;

        invoke_on_connect(aTHX_ self);
        if (!self->destroyed && self->connected && self->state == STATE_IDLE) {
            start_next_op(aTHX_ self);
        }
        self->callback_depth--;
        check_destroyed(aTHX_ self);
        return -1;
    }

    case STATE_REAL_QUERY: {
        const char *sql;
        unsigned long len;
        if (!self->current_op) { self->state = STATE_IDLE; return -1; }
        get_query_sql(self->current_op, &sql, &len);
        st = mysql_real_query_nonblocking(self->conn, sql, len);
        if (st == NET_ASYNC_NOT_READY) return 0;
        if (st == NET_ASYNC_ERROR) {
            handle_query_error(aTHX_ self);
            return -1;
        }
        /* NET_ASYNC_COMPLETE */
        cache_conn_status(self);
        if (mysql_field_count(self->conn) > 0) {
            self->state = STATE_STORE_RESULT;
            return 1;
        }
        self->op_result_sv = newSViv((IV)self->last_affected_rows);
        if (mysql_more_results(self->conn)) {
            self->state = STATE_NEXT_RESULT;
            return 1;
        }
        complete_query_op(aTHX_ self);
        return -1;
    }

    case STATE_STORE_RESULT: {
        st = mysql_store_result_nonblocking(self->conn, &self->op_res);
        if (st == NET_ASYNC_NOT_READY) return 0;
        if (st == NET_ASYNC_ERROR) {
            if (self->op_result_sv) {
                if (!self->op_err) {
                    cache_conn_error(self);
                    self->op_errno = self->last_errno;
                    self->op_err = savepv(self->last_error ? self->last_error : "MySQL store_result failed");
                }
                complete_query_op(aTHX_ self);
                return -1;
            }
            handle_query_error(aTHX_ self);
            return -1;
        }
        if (self->op_res) {
            if (!self->op_result_sv) {
                build_stored_result(aTHX_ self, self->op_res, &self->op_result_sv, &self->op_fields_sv);
            }
            mysql_free_result(self->op_res);
            self->op_res = NULL;
        } else if (!self->op_result_sv) {
            cache_conn_status(self);
            self->op_result_sv = newSViv((IV)self->last_affected_rows);
        }
        if (mysql_more_results(self->conn)) {
            self->state = STATE_NEXT_RESULT;
            return 1;
        }
        complete_query_op(aTHX_ self);
        return -1;
    }

    case STATE_NEXT_RESULT: {
        st = mysql_next_result_nonblocking(self->conn);
        if (st == NET_ASYNC_NOT_READY) return 0;
        if (st == NET_ASYNC_ERROR) {
            if (!self->op_err) {
                cache_conn_error(self);
                self->op_errno = self->last_errno;
                self->op_err = savepv(self->last_error ? self->last_error : "MySQL next_result failed");
            }
            complete_query_op(aTHX_ self);
            return -1;
        }
        if (st == NET_ASYNC_COMPLETE_NO_MORE_RESULTS) {
            complete_query_op(aTHX_ self);
            return -1;
        }
        /* Another result exists */
        if (mysql_field_count(self->conn) > 0) {
            self->state = STATE_STORE_RESULT;
            return 1;
        }
        if (mysql_more_results(self->conn)) {
            return 1;
        }
        complete_query_op(aTHX_ self);
        return -1;
    }

    case STATE_STREAM_QUERY: {
        if (!self->current_op) { self->state = STATE_IDLE; return -1; }
        st = mysql_real_query_nonblocking(
            self->conn,
            self->current_op->sql ? self->current_op->sql : "",
            (unsigned long)self->current_op->sql_len
        );
        if (st == NET_ASYNC_NOT_READY) return 0;
        if (st == NET_ASYNC_ERROR) {
            handle_stream_error(aTHX_ self);
            return -1;
        }
        cache_conn_status(self);
        if (mysql_field_count(self->conn) == 0) {
            self->stream_first_done = 1;
            if (mysql_more_results(self->conn)) {
                self->state = STATE_STREAM_NEXT_RESULT;
                return 1;
            }
            finish_stream_op(aTHX_ self, NULL);
            return -1;
        }
        self->stream_res = mysql_use_result(self->conn);
        if (!self->stream_res) {
            handle_stream_error(aTHX_ self);
            return -1;
        }
        {
            MYSQL_FIELD *sfields = mysql_fetch_fields(self->stream_res);
            unsigned int snf = mysql_num_fields(self->stream_res);
            uint64_t mask = 0;
            if (self->utf8 && sfields) {
                unsigned int c;
                unsigned int limit = snf < 64 ? snf : 64;
                for (c = 0; c < limit; c++) {
                    if (is_utf8_charset(sfields[c].charsetnr)) {
                        mask |= ((uint64_t)1 << c);
                    }
                }
            }
            self->stream_utf8_mask = mask;
            self->stream_fields = build_fields_av(aTHX_ self, sfields, snf);
        }
        self->state = STATE_STREAM_FETCH;
        return 1;
    }

    case STATE_STREAM_FETCH: {
        MYSQL_ROW row = NULL;
        if (!self->stream_res || !self->current_op) {
            self->state = STATE_IDLE;
            return -1;
        }
        st = mysql_fetch_row_nonblocking(self->stream_res, &row);
        if (st == NET_ASYNC_NOT_READY) return 0;
        if (st == NET_ASYNC_ERROR) {
            handle_stream_error(aTHX_ self);
            return -1;
        }
        if (!row) {
            /* EOF on primary result set */
            self->stream_first_done = 1;
            self->state = STATE_STREAM_FREE_RESULT;
            return 1;
        }
        /* Deliver row to user callback */
        {
            unsigned int nf = mysql_num_fields(self->stream_res);
            MYSQL_FIELD *fields = mysql_fetch_fields(self->stream_res);
            unsigned long *lengths = mysql_fetch_lengths(self->stream_res);
            SV *row_sv;
            SV *args[3];
            SV *cb_ref = self->current_op->cb;
            SV *cb_hold = (cb_ref && !PL_dirty && (SvTYPE(cb_ref) == SVt_PVCV || SvOK(cb_ref)))
                ? SvREFCNT_inc(cb_ref) : NULL;
            ev_mysql_op_t *expected_op = self->current_op;

            self->callback_depth++;
            if (cb_hold) {
                ENTER;
                SAVETMPS;
                row_sv = build_row_av_mask(aTHX_ self, row, lengths, fields, nf, self->stream_utf8_mask, 1);
                args[0] = sv_2mortal(row_sv);
                args[1] = &PL_sv_undef;
                args[2] = (self->stream_fields && SvROK(self->stream_fields))
                    ? sv_2mortal(newRV_inc(SvRV(self->stream_fields))) : &PL_sv_undef;
                call_sv_eval_safe(aTHX_ cb_hold, 3, args);
                FREETMPS;
                LEAVE;
                SvREFCNT_dec(cb_hold);
            }
            self->callback_depth--;
            if (check_destroyed(aTHX_ self)) return -1;

            /* Re-validate state after user callback (user may have called finish/reset/skip_pending) */
            if (!self->connected || self->state != STATE_STREAM_FETCH ||
                self->current_op != expected_op || !self->stream_res) {
                return -1;
            }
            /* Re-arm timeout per fetched row */
            arm_timeout(self, self->read_timeout);
            return 1;
        }
    }

    case STATE_STREAM_FREE_RESULT: {
        if (!self->stream_res) {
            if (self->conn && mysql_more_results(self->conn)) {
                self->state = STATE_STREAM_NEXT_RESULT;
                return 1;
            }
            finish_stream_op(aTHX_ self, NULL);
            return -1;
        }
        st = mysql_free_result_nonblocking(self->stream_res);
        if (st == NET_ASYNC_NOT_READY) return 0;
        self->stream_res = NULL;
        if (st == NET_ASYNC_ERROR) {
            cache_conn_error(self);
            if (!self->stream_err) {
                self->stream_errno = self->last_errno;
                self->stream_err = savepv(self->last_error ? self->last_error : "MySQL free_result failed");
            }
            finish_stream_op(aTHX_ self, NULL);
            return -1;
        }
        if (mysql_more_results(self->conn)) {
            self->state = STATE_STREAM_NEXT_RESULT;
            return 1;
        }
        finish_stream_op(aTHX_ self, NULL);
        return -1;
    }

    case STATE_STREAM_NEXT_RESULT: {
        st = mysql_next_result_nonblocking(self->conn);
        if (st == NET_ASYNC_NOT_READY) return 0;
        if (st == NET_ASYNC_ERROR) {
            cache_conn_error(self);
            if (!self->stream_err) {
                self->stream_errno = self->last_errno;
                self->stream_err = savepv(self->last_error ? self->last_error : "MySQL next_result failed");
            }
            finish_stream_op(aTHX_ self, NULL);
            return -1;
        }
        if (st == NET_ASYNC_COMPLETE_NO_MORE_RESULTS) {
            finish_stream_op(aTHX_ self, NULL);
            return -1;
        }
        if (mysql_field_count(self->conn) > 0) {
            /* Drain secondary result sets after primary stream without emitting extra rows */
            self->stream_res = mysql_use_result(self->conn);
            if (self->stream_res) {
                self->state = STATE_STREAM_FREE_RESULT;
                return 1;
            }
            if (mysql_errno(self->conn)) {
                cache_conn_error(self);
                if (!self->stream_err) {
                    self->stream_errno = self->last_errno;
                    self->stream_err = savepv(self->last_error ? self->last_error : "mysql_use_result failed");
                }
                finish_stream_op(aTHX_ self, NULL);
                return -1;
            }
        }
        if (mysql_more_results(self->conn)) return 1;
        finish_stream_op(aTHX_ self, NULL);
        return -1;
    }

    case STATE_RESET_CONNECTION: {
        st = mysql_reset_connection_nonblocking(self->conn);
        if (st == NET_ASYNC_NOT_READY) return 0;
        stop_timeout(self);
        stop_io(self);
        self->callback_depth++;
        if (st == NET_ASYNC_ERROR) {
            unsigned int e;
            char *err;
            cache_conn_error(self);
            e = self->last_errno;
            err = savepv(self->last_error ? self->last_error : "mysql_reset_connection failed");
            if (is_fatal_conn_errno(e) || mysql_sock_fd(self->conn) < 0) {
                abort_connection_with_error(aTHX_ self, err, e);
            } else {
                self->state = STATE_IDLE;
                finish_current_op(aTHX_ self, NULL, err, NULL);
                if (!self->destroyed && self->connected && self->state == STATE_IDLE) {
                    start_next_op(aTHX_ self);
                }
            }
            Safefree(err);
            self->callback_depth--;
            check_destroyed(aTHX_ self);
            return -1;
        }
        invalidate_all_stmts(self, 1);
        self->state = STATE_IDLE;
        finish_current_op(aTHX_ self, newSViv(1), NULL, NULL);
        if (!self->destroyed && self->connected && self->state == STATE_IDLE) {
            start_next_op(aTHX_ self);
        }
        self->callback_depth--;
        check_destroyed(aTHX_ self);
        return -1;
    }

    default:
        return -1;
    }
}

static void arm_watchers(pTHX_ ev_mysql_t *self) {
    int fd;
    int want = EV_READ;

    if (self->destroyed || !self->conn || self->state == STATE_IDLE ||
        self->state == STATE_DISCONNECTED || self->state == STATE_DEFERRED_OP) {
        stop_io(self);
        return;
    }

    if (self->state == STATE_CONNECTING) {
        enum connect_stage stage = mysql_get_connect_nonblocking_stage(self->conn);
        if (stage == CONNECT_STAGE_NET_BEGIN_CONNECT ||
            stage == CONNECT_STAGE_NET_WAIT_CONNECT ||
            mysql_sock_fd(self->conn) < 0) {
            self->fd = -1;
            stop_io(self);
            ev_timer_stop(self->loop, &self->poll_timer);
            ev_timer_set(&self->poll_timer, 0.0005, 0.);
            ev_timer_start(self->loop, &self->poll_timer);
            return;
        }
        ev_timer_stop(self->loop, &self->poll_timer);
    }

    fd = mysql_sock_fd(self->conn);
    self->fd = fd;
    if (fd < 0) {
        stop_io(self);
        return;
    }

    /* Disambiguate EV_READ vs EV_WRITE for bidirectional states since libmysqlclient
     * does not expose mysql_get_socket wait_status flags like libmariadb. */
    if (self->state == STATE_CONNECTING || self->state == STATE_REAL_QUERY ||
        self->state == STATE_STREAM_QUERY || self->state == STATE_RESET_CONNECTION) {
        struct pollfd pfd;
        pfd.fd = fd;
        pfd.events = POLLOUT | POLLIN;
        pfd.revents = 0;
        if (poll(&pfd, 1, 0) >= 0) {
            if (!(pfd.revents & POLLOUT)) {
                want = EV_WRITE;
            } else {
                want = EV_READ;
            }
        }
    }

    if ((self->state == STATE_REAL_QUERY || self->state == STATE_STREAM_QUERY ||
         self->state == STATE_RESET_CONNECTION) &&
        want == EV_WRITE && self->write_timeout > 0) {
        arm_timeout(self, self->write_timeout);
    } else if (self->state != STATE_CONNECTING && want == EV_READ &&
               self->io_active && self->io_events == EV_WRITE &&
               self->write_timeout > 0) {
        /* Restore read_timeout once the socket finishes flushing writes,
         * including when write completion advances directly to a result state. */
        if (self->read_timeout > 0) {
            arm_timeout(self, self->read_timeout);
        } else {
            stop_timeout(self);
        }
    }

    if (self->io_active && self->io.fd == fd && self->io_events == want) {
        return;
    }
    stop_io(self);
    self->io_events = want;
    ev_io_set(&self->io, fd, want);
    ev_io_start(self->loop, &self->io);
    self->io_active = 1;
}

static void drive_state_machine(pTHX_ ev_mysql_t *self) {
    int spins = 0;
    while (!self->destroyed && self->conn &&
           self->state != STATE_IDLE && self->state != STATE_DISCONNECTED &&
           self->state != STATE_DEFERRED_OP) {
        int rc = drive_once(aTHX_ self);
        if (rc < 0) return;
        if (rc == 0) {
            int saved_errno = errno;
            /* If socket already has readable bytes without an EAGAIN return
             * (or during libmysqlclient auth transitions), retry bounded times
             * before yielding to EV. */
            if (saved_errno != EAGAIN && saved_errno != EWOULDBLOCK && spins < EV_MYSQL_MAX_IO_RETRIES) {
                int fd = mysql_sock_fd(self->conn);
                if (fd >= 0 &&
                    (self->state != STATE_CONNECTING ||
                     mysql_get_connect_nonblocking_stage(self->conn) > CONNECT_STAGE_NET_WAIT_CONNECT)) {
                    struct pollfd pfd;
                    /* libmysqlclient auth transitions (e.g. caching_sha2_password
                     * CHALLENGE_RESPONSE -> SEND_PLAIN_PASSWORD) return NET_ASYNC_NOT_READY
                     * without hitting socket EAGAIN. */
                    if (self->state == STATE_CONNECTING && saved_errno != EINPROGRESS) {
                        spins++;
                        continue;
                    }
                    pfd.fd = fd;
                    pfd.events = POLLIN;
                    pfd.revents = 0;
                    if (poll(&pfd, 1, 0) > 0 && (pfd.revents & (POLLIN | POLLERR | POLLHUP))) {
                        spins++;
                        continue;
                    }
                }
            }
            arm_watchers(aTHX_ self);
            return;
        }
        spins = 0;
    }
}

/* ------------------------------------------------------------------ */
/* EV callbacks                                                       */
/* ------------------------------------------------------------------ */

static void io_cb(EV_P_ ev_io *w, int revents) {
    dTHX;
    ev_mysql_t *self = EV_MYSQL_CONTAINER(w, ev_mysql_t, io);
    PERL_UNUSED_ARG(revents);
    PERL_UNUSED_ARG(loop);
    if (self->destroyed || check_fork_safety(aTHX_ self)) return;
    if (self->state == STATE_IDLE || self->state == STATE_DISCONNECTED ||
        self->state == STATE_DEFERRED_OP) {
        stop_io(self);
        return;
    }
    drive_state_machine(aTHX_ self);
}

static void poll_timer_cb(EV_P_ ev_timer *w, int revents) {
    dTHX;
    ev_mysql_t *self = EV_MYSQL_CONTAINER(w, ev_mysql_t, poll_timer);
    PERL_UNUSED_ARG(revents);
    PERL_UNUSED_ARG(loop);
    if (self->destroyed || check_fork_safety(aTHX_ self)) return;
    drive_state_machine(aTHX_ self);
}

static void timeout_timer_cb(EV_P_ ev_timer *w, int revents) {
    dTHX;
    ev_mysql_t *self = EV_MYSQL_CONTAINER(w, ev_mysql_t, timeout_timer);
    const char *msg;
    PERL_UNUSED_ARG(revents);
    PERL_UNUSED_ARG(loop);
    if (self->destroyed || check_fork_safety(aTHX_ self)) return;
    if (self->state == STATE_IDLE || self->state == STATE_DISCONNECTED) return;

    self->timed_out = 1;
    msg = (self->state == STATE_CONNECTING)
        ? "MySQL connection timed out"
        : "MySQL operation timed out";
    abort_connection_with_error(aTHX_ self, msg, CR_SERVER_LOST);
}

static void deferred_timer_cb(EV_P_ ev_timer *w, int revents) {
    dTHX;
    ev_mysql_t *self = EV_MYSQL_CONTAINER(w, ev_mysql_t, deferred_timer);
    ev_mysql_op_t *op = self->current_op;
    PERL_UNUSED_ARG(revents);
    PERL_UNUSED_ARG(loop);

    if (self->destroyed || check_fork_safety(aTHX_ self)) return;
    op = self->current_op;
    if (self->state != STATE_DEFERRED_OP || !op) return;
    self->state = STATE_IDLE;
    self->callback_depth++;

    switch (op->type) {
    case OP_PREPARE: {
        MYSQL_STMT *stmt;
        ev_mysql_stmt_t *ctx;
        bool update_max = 1;
        if (!self->conn || !self->connected) {
            finish_current_op(aTHX_ self, NULL, "Not connected", NULL);
            break;
        }
        stmt = mysql_stmt_init(self->conn);
        if (!stmt) {
            cache_conn_error(self);
            finish_or_abort_sync_op(aTHX_ self, self->last_errno,
                                    self->last_error ? self->last_error : "mysql_stmt_init failed");
            break;
        }
        if (mysql_stmt_prepare(stmt, op->sql ? op->sql : "", (unsigned long)op->sql_len) != 0) {
            cache_stmt_error(self, stmt);
            mysql_stmt_close(stmt);
            fail_stmt_sync_op(aTHX_ self, NULL, "mysql_stmt_prepare failed");
            break;
        }
        mysql_stmt_attr_set(stmt, STMT_ATTR_UPDATE_MAX_LENGTH, &update_max);
        Newxz(ctx, 1, ev_mysql_stmt_t);
        ctx->id          = ++self->next_stmt_id;
        ctx->stmt        = stmt;
        ctx->param_count = (unsigned int)mysql_stmt_param_count(stmt);
        ctx->next        = self->stmt_list;
        self->stmt_list  = ctx;
        finish_current_op(aTHX_ self, newSViv(ctx->id), NULL, NULL);
        break;
    }

    case OP_EXECUTE:
        exec_stmt_sync(aTHX_ self, op);
        break;

    case OP_SEND_LONG_DATA: {
        ev_mysql_stmt_t *ctx = find_stmt(self, op->iv_arg);
        unsigned int pidx;
        if (!self->conn || !self->connected) {
            finish_current_op(aTHX_ self, NULL, "Not connected", NULL);
            break;
        }
        if (!ctx || !ctx->stmt) {
            finish_current_op(aTHX_ self, NULL, "Invalid or closed statement handle", NULL);
            break;
        }
        if (op->uv_arg >= (UV)ctx->param_count) {
            finish_current_op(aTHX_ self, NULL, "Parameter index out of range", NULL);
            break;
        }
        pidx = (unsigned int)op->uv_arg;
        ensure_stmt_in_binds(ctx, 1);
        if (ctx->in_binds[pidx].buffer) {
            Safefree(ctx->in_binds[pidx].buffer);
            ctx->in_binds[pidx].buffer = NULL;
            ctx->in_buf_cap[pidx] = 0;
        }
        ctx->in_binds[pidx].buffer_type   = MYSQL_TYPE_LONG_BLOB;
        ctx->in_binds[pidx].buffer_length = 0;
        ctx->in_binds[pidx].long_data_used = 1;
        ctx->in_lengths[pidx]             = 0;
        ctx->in_is_null[pidx]             = 0;
        /* Ensure libmysqlclient has params bound once, without resetting
         * long_data_used on subsequent chunks. */
        if (!ctx->stmt->bind_param_done ||
            (ctx->stmt->params && ctx->stmt->params[pidx].buffer_type != MYSQL_TYPE_LONG_BLOB)) {
            if (mysql_stmt_bind_param(ctx->stmt, ctx->in_binds) != 0) {
                fail_stmt_sync_op(aTHX_ self, ctx->stmt, "mysql_stmt_bind_param failed");
                break;
            }
            /* mysql_stmt_bind_param clears params[k].long_data_used for every param;
             * restore it for any other parameter that already streamed long data. */
            if (ctx->stmt->params && ctx->long_data_sent) {
                unsigned int k;
                for (k = 0; k < ctx->param_count; k++) {
                    if (ctx->long_data_sent[k] && k != pidx) {
                        ctx->stmt->params[k].long_data_used = 1;
                    }
                }
            }
        }

        if (mysql_stmt_send_long_data(ctx->stmt, pidx,
                                      op->sql ? op->sql : "",
                                      (unsigned long)op->sql_len) != 0) {
            fail_stmt_sync_op(aTHX_ self, ctx->stmt, "mysql_stmt_send_long_data failed");
            break;
        }
        ctx->long_data_sent[pidx] = 1;
        ctx->has_manual_bind      = 1;
        finish_current_op(aTHX_ self, newSViv(1), NULL, NULL);
        break;
    }

    case OP_STMT_RESET: {
        ev_mysql_stmt_t *ctx = find_stmt(self, op->iv_arg);
        if (!self->conn || !self->connected) {
            finish_current_op(aTHX_ self, NULL, "Not connected", NULL);
            break;
        }
        if (!ctx || !ctx->stmt) {
            finish_current_op(aTHX_ self, NULL, "Invalid or closed statement handle", NULL);
            break;
        }
        if (ctx->long_data_sent) Zero(ctx->long_data_sent, ctx->in_cap, bool);
        if (mysql_stmt_reset(ctx->stmt) != 0) {
            fail_stmt_sync_op(aTHX_ self, ctx->stmt, "mysql_stmt_reset failed");
            break;
        }
        finish_current_op(aTHX_ self, newSViv(1), NULL, NULL);
        break;
    }

    case OP_CLOSE_STMT: {
        ev_mysql_stmt_t *ctx = find_stmt(self, op->iv_arg);
        if (!self->conn || !self->connected) {
            finish_current_op(aTHX_ self, NULL, "Not connected", NULL);
            break;
        }
        if (!ctx) {
            finish_current_op(aTHX_ self, NULL, "Invalid or closed statement handle", NULL);
            break;
        }
        if (ctx->stale || !ctx->stmt) {
            remove_stmt(self, ctx);
            finish_current_op(aTHX_ self, newSViv(1), NULL, NULL);
            break;
        }
        if (mysql_stmt_close(ctx->stmt) != 0) {
            unsigned int e;
            char *msg;
            cache_conn_error(self);
            e = self->last_errno;
            msg = savepv(self->last_error ? self->last_error : "mysql_stmt_close failed");
            ctx->stmt = NULL;
            remove_stmt(self, ctx);
            finish_or_abort_sync_op(aTHX_ self, e, msg);
            Safefree(msg);
            break;
        }
        ctx->stmt = NULL;
        remove_stmt(self, ctx);
        finish_current_op(aTHX_ self, newSViv(1), NULL, NULL);
        break;
    }

    case OP_SET_CHARSET: {
        if (!self->conn || !self->connected) {
            finish_current_op(aTHX_ self, NULL, "Not connected", NULL);
            break;
        }
        if (mysql_set_character_set(self->conn, op->arg1 ? op->arg1 : "") != 0) {
            unsigned int e;
            char *msg;
            cache_conn_error(self);
            e = self->last_errno;
            msg = savepv(self->last_error ? self->last_error : "mysql_set_character_set failed");
            finish_or_abort_sync_op(aTHX_ self, e, msg);
            Safefree(msg);
            break;
        }
        replace_str(&self->charset, op->arg1);
        finish_current_op(aTHX_ self, newSViv(1), NULL, NULL);
        break;
    }

    case OP_CHANGE_USER: {
        const char *db_arg;
        if (!self->conn || !self->connected) {
            finish_current_op(aTHX_ self, NULL, "Not connected", NULL);
            break;
        }
        db_arg = op->has_arg3 ? op->arg3 : self->database;
        if (mysql_change_user(self->conn,
                              op->arg1 ? op->arg1 : "",
                              op->arg2 ? op->arg2 : "",
                              db_arg) != 0) {
            unsigned int e;
            char *msg;
            cache_conn_error(self);
            e = self->last_errno;
            msg = savepv(self->last_error ? self->last_error : "mysql_change_user failed");
            finish_or_abort_sync_op(aTHX_ self, e, msg);
            Safefree(msg);
            break;
        }
        /* Changing user invalidates server-side prepared statements */
        invalidate_all_stmts(self, 1);
        replace_str(&self->user, op->arg1);
        replace_str(&self->password, op->arg2);
        if (op->has_arg3) replace_str(&self->database, op->arg3);
        finish_current_op(aTHX_ self, newSViv(1), NULL, NULL);
        break;
    }

    case OP_CLOSE_ASYNC: {
        SV *cb_copy = NULL;
        SV *args[2];
        self->current_op = NULL;
        if (self->pending_count > 0) self->pending_count--;
        cb_copy = take_op_cb(op);
        free_op(aTHX_ op);
        cleanup_connection(aTHX_ self, 0);
        fail_queued_ops(aTHX_ self, "connection finished");
        if (!self->destroyed && cb_copy) {
            args[0] = &PL_sv_yes;
            args[1] = &PL_sv_undef;
            call_perl_cb(aTHX_ self, cb_copy, 2, args);
        }
        if (cb_copy) SvREFCNT_dec(cb_copy);
        break;
    }

    default:
        break;
    }

    if (!self->destroyed && self->connected && self->state == STATE_IDLE) {
        start_next_op(aTHX_ self);
    }
    if (!self->destroyed && self->state == STATE_IDLE) stop_io(self);
    self->callback_depth--;
    check_destroyed(aTHX_ self);
}

/* ------------------------------------------------------------------ */
/* Queueing & entry guards                                            */
/* ------------------------------------------------------------------ */

static int check_fork_safety(pTHX_ ev_mysql_t *self) {
    pid_t cur = getpid();
    if (self->pid != cur) {
        self->callback_depth++;
        self->reset_gen++;
        self->reset_aborted = 1;
        /* Run cleanup_connection while self->pid != cur so !same_pid closes/replaces
         * the inherited fd instead of calling shutdown() or COM_QUIT on parent's socket. */
        cleanup_connection(aTHX_ self, 0);
        self->pid = cur;
        fail_queued_ops(aTHX_ self, "Connection reset after fork");
        self->callback_depth--;
        return check_destroyed(aTHX_ self);
    }
    return 0;
}

static ev_mysql_op_t *alloc_op_cv(pTHX_ ev_mysql_t *self, op_type_t type, SV *cv) {
    ev_mysql_op_t *op;
    if (self && self->op_freelist) {
        op = self->op_freelist;
        self->op_freelist = (ev_mysql_op_t *)op->queue.next;
        self->op_freelist_count--;
        memset(op, 0, offsetof(ev_mysql_op_t, sql_inline));
    } else {
        Newx(op, 1, ev_mysql_op_t);
        memset(op, 0, offsetof(ev_mysql_op_t, sql_inline));
    }
    op->type = type;
    op->cb   = SvREFCNT_inc(cv);
    return op;
}

static ev_mysql_op_t *alloc_op(pTHX_ op_type_t type, SV *cb) {
    if (cb) SvGETMAGIC(cb);
    if (!cb || !SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV) {
        croak("callback must be a CODE reference");
    }
    return alloc_op_cv(aTHX_ NULL, type, SvRV(cb));
}

static int is_ascii_bytes(const char *s, STRLEN len) {
    STRLEN i;
    for (i = 0; i < len; i++) {
        if ((unsigned char)s[i] >= 0x80) return 0;
    }
    return 1;
}

static void set_op_sql_bytes(ev_mysql_op_t *op, const char *p, STRLEN len) {
    if (len < EV_MYSQL_OP_INLINE_SQL) {
        if (len > 0) memcpy(op->sql_inline, p, len);
        op->sql_inline[len] = '\0';
        op->sql = op->sql_inline;
    } else {
        op->sql = savepvn(p, len);
    }
    op->sql_len = len;
}

static void enqueue_op(pTHX_ ev_mysql_t *self, ev_mysql_op_t *op) {
    op->seq = ++self->next_op_seq;
    ngx_queue_insert_tail(&self->op_queue, &op->queue);
    self->pending_count++;
    if (self->callback_depth == 0 && self->connected &&
        self->state == STATE_IDLE && !self->current_op) {
        start_next_op(aTHX_ self);
    }
}

static void ensure_state_can_queue(pTHX_ ev_mysql_t *self) {
    if (check_fork_safety(aTHX_ self) || self->destroyed) {
        croak("not connected");
    }
    if (self->closing) {
        croak("connection is closing");
    }
    if ((!self->conn || self->state == STATE_DISCONNECTED) && !self->in_fail_queue) {
        croak("not connected");
    }
}

static SV *ensure_can_queue(pTHX_ ev_mysql_t *self, SV *cb) {
    SV *cb_snap;
    if (check_fork_safety(aTHX_ self) || self->destroyed) {
        croak("not connected");
    }
    if (cb) SvGETMAGIC(cb);
    if (!cb || !SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV) {
        croak("callback must be a CODE reference");
    }
    cb_snap = sv_2mortal(newRV_inc(SvRV(cb)));
    ensure_state_can_queue(aTHX_ self);
    return cb_snap;
}

static SV *validate_cb_for_queue(pTHX_ ev_mysql_t *self, SV *cb) {
    if (check_fork_safety(aTHX_ self) || self->destroyed) {
        croak("not connected");
    }
    if (cb && !SvGMAGICAL(cb)) {
        if (!SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV) {
            croak("callback must be a CODE reference");
        }
        if (self->closing) croak("connection is closing");
        if ((!self->conn || self->state == STATE_DISCONNECTED) && !self->in_fail_queue) {
            croak("not connected");
        }
        return SvRV(cb);
    } else {
        SV *cb_snap = ensure_can_queue(aTHX_ self, cb);
        return SvRV(cb_snap);
    }
}

static void queue_simple_op(pTHX_ ev_mysql_t *self, op_type_t type, SV *cb) {
    SV *cb_snap = ensure_can_queue(aTHX_ self, cb);
    enqueue_op(aTHX_ self, alloc_op(aTHX_ type, cb_snap));
}

static void queue_sql_op(pTHX_ ev_mysql_t *self, op_type_t type, SV *sql_sv, SV *cb, const char *undef_msg) {
    ev_mysql_op_t *op;
    SV *cv;
    const char *p;
    STRLEN len;

    cv = validate_cb_for_queue(aTHX_ self, cb);

    if (type != OP_PREPARE && self->current_op && self->current_op->type == OP_STREAM) {
        croak(type == OP_QUERY
            ? "cannot queue query while streaming is active"
            : "cannot queue query_stream while streaming is active");
    }

    if (sql_sv && SvPOK(sql_sv) && !SvGMAGICAL(sql_sv) && !SvAMAGIC(sql_sv)) {
        p = SvPVX_const(sql_sv);
        len = SvCUR(sql_sv);
        if (!self->utf8 || SvUTF8(sql_sv) || is_ascii_bytes(p, len)) {
            op = alloc_op_cv(aTHX_ self, type, cv);
            set_op_sql_bytes(op, p, len);
            enqueue_op(aTHX_ self, op);
            return;
        }
    }

    {
        SV *cb_hold = sv_2mortal(newRV_inc(cv));
        SV *sql_snap = sv_to_mortal_sql(aTHX_ self, sql_sv);
        if (!sql_snap) croak("%s", undef_msg);
        ensure_state_can_queue(aTHX_ self);
        if (type != OP_PREPARE && self->current_op && self->current_op->type == OP_STREAM) {
            croak(type == OP_QUERY
                ? "cannot queue query while streaming is active"
                : "cannot queue query_stream while streaming is active");
        }
        len = SvCUR(sql_snap);
        op = alloc_op_cv(aTHX_ self, type, SvRV(cb_hold));
        set_op_sql_bytes(op, SvPVX_const(sql_snap), len);
        enqueue_op(aTHX_ self, op);
    }
}

static ev_mysql_stmt_t *require_live_stmt(pTHX_ ev_mysql_t *self, IV stmt_iv) {
    ev_mysql_stmt_t *ctx = find_stmt(self, stmt_iv);
    if (!ctx || ctx->closing) {
        if (!self->conn || !self->connected) croak("not connected");
        croak("invalid statement handle");
    }
    if (ctx->stale || !ctx->stmt) {
        croak("statement handle is no longer valid");
    }
    return ctx;
}

static SV **resolve_bind_params_svs(pTHX_ ev_mysql_t *self, AV *av, unsigned int param_count,
                                    SV **stack_buf, unsigned int stack_cap, int *ran_magic_out) {
    SV **out;
    unsigned int i;
    int av_magical = av && (SvGMAGICAL((SV *)av) || SvRMAGICAL((SV *)av));
    SSize_t nparams;

    if (ran_magic_out) *ran_magic_out = av_magical ? 1 : 0;
    nparams = av ? (av_len(av) + 1) : 0;
    if (nparams < 0 || (size_t)nparams != (size_t)param_count) {
        croak("parameter count mismatch: expected %u, got %ld",
              param_count, (long)nparams);
    }
    if (param_count == 0) return stack_buf;

    if (param_count <= stack_cap) {
        out = stack_buf;
    } else {
        Newx(out, param_count, SV *);
        SAVEFREEPV(out);
    }

    if (!av_magical) {
        SV **raws = AvARRAY(av);
        for (i = 0; i < param_count; i++) {
            SV *raw = raws[i] ? raws[i] : &PL_sv_undef;
            if (SvGMAGICAL(raw) || SvAMAGIC(raw)) goto slow_freeze;
            if (!SvOK(raw) || ((SvIOK(raw) || SvNOK(raw)) && !SvPOK(raw))) {
                out[i] = raw;
            } else if (SvPOK(raw) && (!self->utf8 || SvUTF8(raw) || is_ascii_bytes(SvPVX_const(raw), SvCUR(raw)))) {
                out[i] = raw;
            } else {
                goto slow_freeze;
            }
        }
        return out;
    }

slow_freeze:
    if (ran_magic_out) *ran_magic_out = 1;
    for (i = 0; i < param_count; i++) {
        SV **elem = av_fetch(av, i, 0);
        SV *raw = (elem && *elem) ? *elem : &PL_sv_undef;
        SV *val = raw;
        if (SvGMAGICAL(raw) || SvAMAGIC(raw)) {
            val = sv_nomg_copy(aTHX_ raw);
        }
        if (!val || !SvOK(val)) {
            out[i] = &PL_sv_undef;
        } else if ((SvIOK(val) || SvNOK(val)) && !SvPOK(val)) {
            out[i] = (val == raw) ? sv_2mortal(newSVsv(val)) : val;
        } else if (SvPOK(val)) {
            const char *p = SvPVX_const(val);
            STRLEN plen = SvCUR(val);
            if (!self->utf8 || SvUTF8(val) || is_ascii_bytes(p, plen)) {
                if (val == raw) {
                    SV *s = sv_2mortal(newSVpvn(p, plen));
                    if (SvUTF8(val)) SvUTF8_on(s);
                    out[i] = s;
                } else {
                    out[i] = val;
                }
            } else {
                SV *snap = sv_to_mortal_sql(aTHX_ self, val);
                out[i] = snap ? snap : &PL_sv_undef;
            }
        } else {
            SV *snap = sv_to_mortal_sql(aTHX_ self, val);
            out[i] = snap ? snap : &PL_sv_undef;
        }
    }
    return out;
}

static void fill_c_param_from_plain_sv(pTHX_ ev_mysql_param_t *dst, SV *v, ev_mysql_op_t *op) {
    if (!v || !SvOK(v)) {
        dst->kind = PARAM_NULL;
    } else if (SvIOK(v) && !SvPOK(v)) {
        if (SvIsUV(v)) {
            dst->kind = PARAM_UV;
            dst->u.uv = (uint64_t)SvUVX(v);
        } else {
            dst->kind = PARAM_IV;
            dst->u.iv = (int64_t)SvIVX(v);
        }
    } else if (SvNOK(v) && !SvPOK(v)) {
        dst->kind = PARAM_NV;
        dst->u.nv = (double)SvNVX(v);
    } else {
        const char *p = SvPVX_const(v);
        STRLEN len = SvCUR(v);
        dst->kind = PARAM_STR;
        dst->u.str.len = len;
        if (op) {
            if (len < EV_MYSQL_OP_INLINE_SQL - op->sql_len) {
                char *buf = op->sql_inline + op->sql_len;
                if (len > 0) memcpy(buf, p, len);
                buf[len] = '\0';
                op->sql_len += len + 1;
                dst->u.str.ptr = buf;
            } else {
                dst->u.str.ptr = savepvn(p, len);
            }
        } else {
            dst->u.str.ptr = (char *)p;
        }
    }
}

static void pack_op_params(pTHX_ ev_mysql_op_t *op, SV *const *vals, unsigned int nparams) {
    unsigned int i;
    op->has_params = 1;
    op->param_count = nparams;
    if (nparams == 0) return;
    if (nparams <= EV_MYSQL_OP_INLINE_PARAMS) {
        op->params = op->params_inline;
    } else {
        Newx(op->params, nparams, ev_mysql_param_t);
    }
    op->sql_len = 0;
    for (i = 0; i < nparams; i++) {
        fill_c_param_from_plain_sv(aTHX_ &op->params[i], vals[i], op);
    }
}

static ev_mysql_stmt_t *require_can_bind_params(pTHX_ ev_mysql_t *self, IV stmt_iv) {
    ngx_queue_t *q;
    if (check_fork_safety(aTHX_ self) || !self->conn || !self->connected) {
        croak("not connected");
    }
    if (self->current_op || (self->state != STATE_IDLE && self->state != STATE_CONNECTING)) {
        croak("another operation is in progress");
    }
    for (q = ngx_queue_head(&self->op_queue); q != ngx_queue_sentinel(&self->op_queue); q = ngx_queue_next(q)) {
        ev_mysql_op_t *qop = ngx_queue_data(q, ev_mysql_op_t, queue);
        if (qop->type != OP_QUERY) {
            croak("another operation is in progress");
        }
    }
    return require_live_stmt(aTHX_ self, stmt_iv);
}

static char *escape_ident_sql(const char *prefix, const char *ident, STRLEN *out_len) {
    size_t plen = strlen(prefix);
    size_t ilen = ident ? strlen(ident) : 0;
    size_t extra = 0;
    size_t i;
    char *buf, *p;
    for (i = 0; i < ilen; i++) {
        if (ident[i] == '`') extra++;
    }
    Newx(buf, plen + 1 + ilen + extra + 2, char);
    Copy(prefix, buf, plen, char);
    p = buf + plen;
    *p++ = '`';
    for (i = 0; i < ilen; i++) {
        if (ident[i] == '`') *p++ = '`';
        *p++ = ident[i];
    }
    *p++ = '`';
    *p = '\0';
    *out_len = (STRLEN)(p - buf);
    return buf;
}

static void start_connecting(pTHX_ ev_mysql_t *self) {
    if (self->destroyed) return;
    if (self->conn) {
        cleanup_connection(aTHX_ self, 0);
    }
    self->pid = getpid();
    self->conn = mysql_init(NULL);
    if (!self->conn) {
        croak("mysql_init failed");
    }
    apply_mysql_options(self);
    self->state = STATE_CONNECTING;
    self->connected = 0;
    self->closing = 0;
    self->timed_out = 0;
    if (self->connect_timeout > 0) {
        arm_timeout(self, self->connect_timeout);
    }
    self->in_sync_connect = 1;
    drive_state_machine(aTHX_ self);
    self->in_sync_connect = 0;
}

static unsigned int parse_ssl_mode(const char *s) {
    if (!s) croak("ssl_mode cannot be undef");
    if (strEQ(s, "DISABLED"))        return SSL_MODE_DISABLED;
    if (strEQ(s, "PREFERRED"))       return SSL_MODE_PREFERRED;
    if (strEQ(s, "REQUIRED"))        return SSL_MODE_REQUIRED;
    if (strEQ(s, "VERIFY_CA"))       return SSL_MODE_VERIFY_CA;
    if (strEQ(s, "VERIFY_IDENTITY")) return SSL_MODE_VERIFY_IDENTITY;
    croak("invalid ssl_mode '%s'", s);
    return SSL_MODE_PREFERRED;
}

MODULE = EV::mysql  PACKAGE = EV::mysql

PROTOTYPES: DISABLE

BOOT:
    if (mysql_library_init(0, NULL, NULL) != 0) {
        croak("mysql_library_init failed");
    }

SV *
_new(char *class_name, EV::Loop loop)
PREINIT:
    ev_mysql_t *self;
    SV *rv;
CODE:
    PERL_UNUSED_VAR(class_name);
    I_EV_API("EV::mysql");
    Newxz(self, 1, ev_mysql_t);
    self->loop    = loop;
    self->loop_sv = newSVsv(ST(1));
    self->fd      = -1;
    self->port    = 3306;
    self->pid     = getpid();
    self->state   = STATE_DISCONNECTED;
    self->ssl_verify_server_cert = -1;
    ngx_queue_init(&self->op_queue);

    ev_init(&self->io, io_cb);
    ev_init(&self->timeout_timer, timeout_timer_cb);
    ev_init(&self->poll_timer, poll_timer_cb);
    ev_init(&self->deferred_timer, deferred_timer_cb);

    rv = newSV(0);
    sv_setref_pv(rv, class_name, (void *)self);
    RETVAL = rv;
OUTPUT:
    RETVAL

void
DESTROY(EV::mysql self)
CODE:
    self->destroyed = 1;
    self->callback_depth++;
    stop_all_watchers(self);
    if (!PL_dirty) {
        fail_queued_ops(aTHX_ self, "connection finished");
    }
    cleanup_connection(aTHX_ self, 0);
    self->callback_depth--;
    if (self->callback_depth == 0) {
        free_self_final(aTHX_ self);
    }

void
connect(EV::mysql self, SV *host_sv, SV *user_sv, SV *password_sv = &PL_sv_undef, SV *database_sv = &PL_sv_undef, SV *port_sv = &PL_sv_undef, SV *unix_socket_sv = &PL_sv_undef)
PREINIT:
    unsigned int gen;
    const char *thost;
    const char *tuser;
    const char *tpw;
    const char *tdb;
    const char *tsock;
    STRLEN hlen;
    STRLEN ulen;
    STRLEN pwlen;
    STRLEN dblen;
    STRLEN slen;
    char *nhost;
    char *nuser;
    char *npw;
    char *ndb;
    char *nsock;
    unsigned int nport = 3306;
CODE:
    HOLD_SELF_ST();
    if (check_fork_safety(aTHX_ self)) XSRETURN_EMPTY;
    if (self->connected || self->state == STATE_CONNECTING) {
        croak("already connected or connecting");
    }
    if (port_sv) {
        SV *pv_sv = sv_nomg_copy(aTHX_ port_sv);
        if (SvOK(pv_sv)) {
            NV nvp = SvNV(pv_sv);
            UV pv;
            if ((SvIOK(pv_sv) && !SvIsUV(pv_sv) && SvIVX(pv_sv) < 0) ||
                !(nvp >= 0.0 && nvp <= 65535.0)) {
                croak("port out of range: %.0f", (double)nvp);
            }
            pv = SvUV(pv_sv);
            if ((NV)pv != nvp) {
                croak("port out of range: non-integer %g", (double)nvp);
            }
            if (pv > 0 && pv <= 65535) {
                nport = (unsigned int)pv;
            } else if (pv > 65535) {
                croak("port out of range: %" UVuf, pv);
            }
        }
    }
    thost = sv_to_temp_pv(aTHX_ host_sv, &hlen);
    tuser = sv_to_temp_pv(aTHX_ user_sv, &ulen);
    tpw   = sv_to_temp_pv(aTHX_ password_sv, &pwlen);
    tdb   = sv_to_temp_pv(aTHX_ database_sv, &dblen);
    tsock = sv_to_temp_pv(aTHX_ unix_socket_sv, &slen);

    if (check_fork_safety(aTHX_ self)) XSRETURN_EMPTY;
    if (self->connected || self->state == STATE_CONNECTING) {
        croak("already connected or connecting");
    }

    nhost = thost ? savepvn(thost, hlen) : NULL;
    nuser = tuser ? savepvn(tuser, ulen) : NULL;
    npw   = tpw   ? savepvn(tpw, pwlen)  : NULL;
    ndb   = tdb   ? savepvn(tdb, dblen)  : NULL;
    nsock = tsock ? savepvn(tsock, slen) : NULL;

    gen = ++self->reset_gen;
    self->reset_aborted = 0;
    self->callback_depth++;
    cleanup_connection(aTHX_ self, 0);
    fail_queued_ops(aTHX_ self, "Connection reset");
    if (self->destroyed || self->reset_aborted || self->reset_gen != gen ||
        self->conn || self->state != STATE_DISCONNECTED) {
        if (nhost) Safefree(nhost);
        if (nuser) Safefree(nuser);
        if (npw)   Safefree(npw);
        if (ndb)   Safefree(ndb);
        if (nsock) Safefree(nsock);
        self->callback_depth--;
        check_destroyed(aTHX_ self);
        XSRETURN_EMPTY;
    }

    replace_str(&self->host, NULL);
    replace_str(&self->user, NULL);
    replace_str(&self->password, NULL);
    replace_str(&self->database, NULL);
    replace_str(&self->unix_socket, NULL);

    self->host        = nhost;
    self->user        = nuser;
    self->password    = npw;
    self->database    = ndb;
    self->port        = nport;
    self->unix_socket = nsock;

    self->callback_depth--;
    start_connecting(aTHX_ self);

void
reset(EV::mysql self)
PREINIT:
    unsigned int gen;
CODE:
    HOLD_SELF_ST();
    if (check_fork_safety(aTHX_ self)) XSRETURN_EMPTY;
    if (!self->host && !self->unix_socket) {
        croak("no previous connection");
    }
    gen = ++self->reset_gen;
    self->reset_aborted = 0;
    self->callback_depth++;
    cleanup_connection(aTHX_ self, 0);
    fail_queued_ops(aTHX_ self, "Connection reset");
    if (self->destroyed || self->reset_aborted || self->reset_gen != gen ||
        self->conn || self->state != STATE_DISCONNECTED) {
        self->callback_depth--;
        check_destroyed(aTHX_ self);
        XSRETURN_EMPTY;
    }
    self->callback_depth--;
    start_connecting(aTHX_ self);

void
finish(EV::mysql self)
CODE:
    HOLD_SELF_ST();
    self->reset_gen++;
    self->reset_aborted = 1;
    self->callback_depth++;
    cleanup_connection(aTHX_ self, 0);
    fail_queued_ops(aTHX_ self, "connection finished");
    self->callback_depth--;
    check_destroyed(aTHX_ self);

SV *
on_connect(EV::mysql self, SV *handler = NULL)
CODE:
    HOLD_SELF_ST();
    if (items > 1) {
        SV *new_cb = NULL;
        SV *old_cb;
        if (handler) SvGETMAGIC(handler);
        if (handler && SvOK(handler) && SvROK(handler) && SvTYPE(SvRV(handler)) == SVt_PVCV) {
            new_cb = newRV_inc(SvRV(handler));
        }
        old_cb = self->on_connect;
        self->on_connect = new_cb;
        if (old_cb) SvREFCNT_dec(old_cb);
    }
    RETVAL = self->on_connect ? newRV_inc(SvRV(self->on_connect)) : &PL_sv_undef;
OUTPUT:
    RETVAL

SV *
on_error(EV::mysql self, SV *handler = NULL)
CODE:
    HOLD_SELF_ST();
    if (items > 1) {
        SV *new_cb = NULL;
        SV *old_cb;
        if (handler) SvGETMAGIC(handler);
        if (handler && SvOK(handler) && SvROK(handler) && SvTYPE(SvRV(handler)) == SVt_PVCV) {
            new_cb = newRV_inc(SvRV(handler));
        }
        old_cb = self->on_error;
        self->on_error = new_cb;
        if (old_cb) SvREFCNT_dec(old_cb);
    }
    RETVAL = self->on_error ? newRV_inc(SvRV(self->on_error)) : &PL_sv_undef;
OUTPUT:
    RETVAL

void
query(EV::mysql self, SV *sql_sv, SV *cb)
CODE:
    HOLD_SELF_ST();
    queue_sql_op(aTHX_ self, OP_QUERY, sql_sv, cb, "query string cannot be undef");

void
query_stream(EV::mysql self, SV *sql_sv, SV *cb)
CODE:
    HOLD_SELF_ST();
    queue_sql_op(aTHX_ self, OP_STREAM, sql_sv, cb, "query string cannot be undef");

void
prepare(EV::mysql self, SV *sql_sv, SV *cb)
CODE:
    HOLD_SELF_ST();
    queue_sql_op(aTHX_ self, OP_PREPARE, sql_sv, cb, "SQL string cannot be undef");

void
execute(EV::mysql self, SV *stmt_sv, SV *params_or_cb, SV *cb = NULL)
PREINIT:
    IV stmt_iv;
    SV *actual_cb;
    SV *cb_cv;
    SV *params_ref = NULL;
    ev_mysql_op_t *op;
    ev_mysql_stmt_t *ctx;
CODE:
    HOLD_SELF_ST();
    if (items == 3) {
        actual_cb = params_or_cb;
    } else {
        params_ref = params_or_cb;
        actual_cb  = cb;
    }
    cb_cv = validate_cb_for_queue(aTHX_ self, actual_cb);

    if (stmt_sv && !SvGMAGICAL(stmt_sv) && !SvAMAGIC(stmt_sv)) {
        stmt_iv = SvOK(stmt_sv) ? SvIV(stmt_sv) : 0;
    } else {
        (void)sv_2mortal(newRV_inc(cb_cv));
        stmt_iv = sv_to_stmt_id(aTHX_ stmt_sv);
        ensure_state_can_queue(aTHX_ self);
    }
    ctx = require_live_stmt(aTHX_ self, stmt_iv);

    if (params_ref && (SvGMAGICAL(params_ref) || SvAMAGIC(params_ref))) {
        (void)sv_2mortal(newRV_inc(cb_cv));
        params_ref = sv_nomg_copy(aTHX_ params_ref);
        ensure_state_can_queue(aTHX_ self);
        ctx = require_live_stmt(aTHX_ self, stmt_iv);
    } else if (params_ref && SvOK(params_ref)) {
        (void)sv_2mortal(newRV_inc(cb_cv));
    }
    if (params_ref && SvOK(params_ref)) {
        SV *vals_stack[16];
        SV **vals;
        int param_magic = 0;
        if (!SvROK(params_ref) || SvTYPE(SvRV(params_ref)) != SVt_PVAV) {
            croak("params must be an ARRAY reference");
        }
        vals = resolve_bind_params_svs(aTHX_ self, (AV *)SvRV(params_ref),
                                       ctx->param_count, vals_stack, 16, &param_magic);
        if (param_magic) {
            ensure_state_can_queue(aTHX_ self);
            ctx = require_live_stmt(aTHX_ self, stmt_iv);
        }
        op = alloc_op_cv(aTHX_ self, OP_EXECUTE, cb_cv);
        op->iv_arg = stmt_iv;
        pack_op_params(aTHX_ op, vals, ctx->param_count);
    } else {
        op = alloc_op_cv(aTHX_ self, OP_EXECUTE, cb_cv);
        op->iv_arg = stmt_iv;
    }
    enqueue_op(aTHX_ self, op);

void
bind_params(EV::mysql self, SV *stmt_sv, SV *params_ref)
PREINIT:
    IV stmt_iv;
    ev_mysql_stmt_t *ctx;
    SV *vals_stack[16];
    SV **vals;
    ev_mysql_param_t c_stack[16];
    ev_mysql_param_t *c_params;
    unsigned int nparams;
    unsigned int i;
    char *err = NULL;
CODE:
    HOLD_SELF_ST();
    if (check_fork_safety(aTHX_ self) || !self->conn || !self->connected) {
        croak("not connected");
    }
    stmt_iv = sv_to_stmt_id(aTHX_ stmt_sv);
    ctx = require_can_bind_params(aTHX_ self, stmt_iv);
    if (params_ref) params_ref = sv_nomg_copy(aTHX_ params_ref);
    if (!params_ref || !SvROK(params_ref) || SvTYPE(SvRV(params_ref)) != SVt_PVAV) {
        croak("params must be an ARRAY reference");
    }
    vals = resolve_bind_params_svs(aTHX_ self, (AV *)SvRV(params_ref),
                                   ctx->param_count, vals_stack, 16, NULL);
    ctx = require_can_bind_params(aTHX_ self, stmt_iv);
    nparams = ctx->param_count;
    if (nparams <= 16) {
        c_params = c_stack;
    } else {
        Newx(c_params, nparams, ev_mysql_param_t);
        SAVEFREEPV(c_params);
    }
    for (i = 0; i < nparams; i++) {
        fill_c_param_from_plain_sv(aTHX_ &c_params[i], vals[i], NULL);
    }
    if (bind_stmt_from_c_params(aTHX_ self, ctx, c_params, nparams, &err) != 0) {
        char *copy = savepv(err ? err : "bind_params failed");
        if (err) Safefree(err);
        SAVEFREEPV(copy);
        croak("%s", copy);
    }
    ctx->has_manual_bind = 1;

void
send_long_data(EV::mysql self, SV *stmt_sv, SV *param_idx_sv, SV *data_sv, SV *cb)
PREINIT:
    IV stmt_iv;
    STRLEN len;
    const char *p;
    UV param_idx;
    SV *cb_snap;
    ev_mysql_op_t *op;
CODE:
    HOLD_SELF_ST();
    cb_snap = ensure_can_queue(aTHX_ self, cb);
    stmt_iv = sv_to_stmt_id(aTHX_ stmt_sv);
    ensure_state_can_queue(aTHX_ self);
    (void)require_live_stmt(aTHX_ self, stmt_iv);
    param_idx_sv = sv_nomg_copy(aTHX_ param_idx_sv);
    if (!param_idx_sv || !SvOK(param_idx_sv)) croak("param_idx cannot be undef");
    if ((SvIOK(param_idx_sv) && !SvIsUV(param_idx_sv) && SvIVX(param_idx_sv) < 0) ||
        SvNV(param_idx_sv) < 0 ||
        (SvNOK(param_idx_sv) && SvNVX(param_idx_sv) > (NV)UINT_MAX)) {
        param_idx = UV_MAX;
    } else {
        param_idx = SvUV(param_idx_sv);
    }
    p = sv_to_temp_pv(aTHX_ data_sv, &len);
    if (!p) croak("data cannot be undef");
    ensure_state_can_queue(aTHX_ self);
    (void)require_live_stmt(aTHX_ self, stmt_iv);
    op = alloc_op(aTHX_ OP_SEND_LONG_DATA, cb_snap);
    op->iv_arg   = stmt_iv;
    op->uv_arg   = param_idx;
    op->sql      = len > 0 ? savepvn(p, len) : savepv("");
    op->sql_len  = len;
    enqueue_op(aTHX_ self, op);

void
stmt_reset(EV::mysql self, SV *stmt_sv, SV *cb)
PREINIT:
    IV stmt_iv;
    SV *cb_snap;
    ev_mysql_op_t *op;
CODE:
    HOLD_SELF_ST();
    cb_snap = ensure_can_queue(aTHX_ self, cb);
    stmt_iv = sv_to_stmt_id(aTHX_ stmt_sv);
    ensure_state_can_queue(aTHX_ self);
    (void)require_live_stmt(aTHX_ self, stmt_iv);
    op = alloc_op(aTHX_ OP_STMT_RESET, cb_snap);
    op->iv_arg = stmt_iv;
    enqueue_op(aTHX_ self, op);

void
close_stmt(EV::mysql self, SV *stmt_sv, SV *cb)
PREINIT:
    IV stmt_iv;
    SV *cb_snap;
    ev_mysql_stmt_t *ctx;
    ev_mysql_op_t *op;
CODE:
    HOLD_SELF_ST();
    cb_snap = ensure_can_queue(aTHX_ self, cb);
    stmt_iv = sv_to_stmt_id(aTHX_ stmt_sv);
    ensure_state_can_queue(aTHX_ self);
    ctx = find_stmt(self, stmt_iv);
    if (!ctx || ctx->closing) {
        if (!self->conn || !self->connected) croak("not connected");
        croak("invalid statement handle");
    }
    if (ctx->stale || !ctx->stmt) {
        SV *args[2];
        if (self->current_op) croak("cannot close_stmt: another operation is in progress");
        remove_stmt(self, ctx);
        args[0] = &PL_sv_yes;
        args[1] = &PL_sv_undef;
        self->callback_depth++;
        call_perl_cb(aTHX_ self, cb_snap, 2, args);
        if (!self->destroyed && self->connected && self->state == STATE_IDLE &&
            self->callback_depth == 1) {
            start_next_op(aTHX_ self);
        }
        self->callback_depth--;
        check_destroyed(aTHX_ self);
        XSRETURN_EMPTY;
    }
    ctx->closing = 1;
    op = alloc_op(aTHX_ OP_CLOSE_STMT, cb_snap);
    op->iv_arg = stmt_iv;
    enqueue_op(aTHX_ self, op);

void
ping(EV::mysql self, SV *cb)
CODE:
    HOLD_SELF_ST();
    queue_simple_op(aTHX_ self, OP_PING, cb);

void
select_db(EV::mysql self, SV *db_sv, SV *cb)
PREINIT:
    const char *db;
    STRLEN dblen;
    SV *cb_snap;
    ev_mysql_op_t *op;
CODE:
    HOLD_SELF_ST();
    cb_snap = ensure_can_queue(aTHX_ self, cb);
    db = sv_to_temp_pv(aTHX_ db_sv, &dblen);
    if (!db) croak("database cannot be undef");
    if (memchr(db, '\0', dblen) != NULL) croak("database cannot contain NUL bytes");
    ensure_state_can_queue(aTHX_ self);
    op = alloc_op(aTHX_ OP_SELECT_DB, cb_snap);
    op->arg1 = savepvn(db, dblen);
    op->sql  = escape_ident_sql("use ", op->arg1, &op->sql_len);
    enqueue_op(aTHX_ self, op);

void
reset_connection(EV::mysql self, SV *cb)
CODE:
    HOLD_SELF_ST();
    queue_simple_op(aTHX_ self, OP_RESET_CONNECTION, cb);

void
set_charset(EV::mysql self, SV *charset_sv, SV *cb)
PREINIT:
    const char *tcs;
    STRLEN cslen;
    SV *cb_snap;
    ev_mysql_op_t *op;
CODE:
    HOLD_SELF_ST();
    cb_snap = ensure_can_queue(aTHX_ self, cb);
    tcs = sv_to_temp_pv(aTHX_ charset_sv, &cslen);
    if (!tcs) croak("charset cannot be undef");
    ensure_state_can_queue(aTHX_ self);
    op = alloc_op(aTHX_ OP_SET_CHARSET, cb_snap);
    op->arg1 = savepvn(tcs, cslen);
    enqueue_op(aTHX_ self, op);

void
change_user(EV::mysql self, SV *user_sv, SV *password_sv, SV *db_sv, SV *cb)
PREINIT:
    const char *tuser;
    const char *tpw;
    const char *tdb;
    STRLEN ulen;
    STRLEN pwlen;
    STRLEN dblen;
    SV *cb_snap;
    ev_mysql_op_t *op;
CODE:
    HOLD_SELF_ST();
    cb_snap = ensure_can_queue(aTHX_ self, cb);
    tuser = sv_to_temp_pv(aTHX_ user_sv, &ulen);
    tpw   = sv_to_temp_pv(aTHX_ password_sv, &pwlen);
    tdb   = sv_to_temp_pv(aTHX_ db_sv, &dblen);
    ensure_state_can_queue(aTHX_ self);
    op = alloc_op(aTHX_ OP_CHANGE_USER, cb_snap);
    op->arg1 = tuser ? savepvn(tuser, ulen) : NULL;
    op->arg2 = tpw   ? savepvn(tpw, pwlen)  : NULL;
    if (tdb) {
        op->arg3 = savepvn(tdb, dblen);
        op->has_arg3 = 1;
    } else {
        op->has_arg3 = 0;
    }
    enqueue_op(aTHX_ self, op);

void
commit(EV::mysql self, SV *cb)
CODE:
    HOLD_SELF_ST();
    queue_simple_op(aTHX_ self, OP_COMMIT, cb);

void
rollback(EV::mysql self, SV *cb)
CODE:
    HOLD_SELF_ST();
    queue_simple_op(aTHX_ self, OP_ROLLBACK, cb);

void
autocommit(EV::mysql self, SV *mode, SV *cb)
PREINIT:
    SV *cb_snap;
    IV mode_val;
    ev_mysql_op_t *op;
CODE:
    HOLD_SELF_ST();
    cb_snap = ensure_can_queue(aTHX_ self, cb);
    mode = sv_nomg_copy(aTHX_ mode);
    mode_val = SvTRUE(mode) ? 1 : 0;
    ensure_state_can_queue(aTHX_ self);
    op = alloc_op(aTHX_ OP_AUTOCOMMIT, cb_snap);
    op->iv_arg = mode_val;
    enqueue_op(aTHX_ self, op);

void
close_async(EV::mysql self, SV *cb)
PREINIT:
    SV *cb_snap;
    ev_mysql_op_t *op;
CODE:
    HOLD_SELF_ST();
    cb_snap = ensure_can_queue(aTHX_ self, cb);
    op = alloc_op(aTHX_ OP_CLOSE_ASYNC, cb_snap);
    self->closing = 1;
    enqueue_op(aTHX_ self, op);

void
_set_option(EV::mysql self, SV *key_sv, SV *value)
PREINIT:
    const char *key;
CODE:
    HOLD_SELF_ST();
    key = sv_to_temp_pv(aTHX_ key_sv, NULL);
    if (!key) croak("option key cannot be undef");
    value = sv_nomg_copy(aTHX_ value);
    if (strEQ(key, "connect_timeout") || strEQ(key, "read_timeout") || strEQ(key, "write_timeout")) {
        unsigned int tv = 0;
        if (value && SvOK(value)) {
            NV nv;
            UV uv;
            if (SvIOK(value) && !SvIsUV(value) && SvIVX(value) < 0) {
                croak("%s cannot be negative", key);
            }
            nv = SvNV(value);
            if (nv < 0) {
                croak("%s cannot be negative", key);
            }
            if (!(nv <= (NV)UINT_MAX)) {
                croak("%s out of range: %.0f", key, (double)nv);
            }
            uv = SvUV(value);
            if ((NV)uv != nv) {
                croak("%s out of range: non-integer %g", key, (double)nv);
            }
            if (uv > (UV)UINT_MAX) {
                croak("%s out of range: %" UVuf, key, uv);
            }
            tv = (unsigned int)uv;
        }
        if (strEQ(key, "connect_timeout")) {
            self->connect_timeout = tv;
        } else if (strEQ(key, "read_timeout")) {
            self->read_timeout = tv;
        } else {
            self->write_timeout = tv;
        }
    } else if (strEQ(key, "compress")) {
        self->compress = SvTRUE(value) ? 1 : 0;
    } else if (strEQ(key, "multi_statements")) {
        self->multi_statements = SvTRUE(value) ? 1 : 0;
    } else if (strEQ(key, "utf8")) {
        self->utf8 = SvTRUE(value) ? 1 : 0;
    } else if (strEQ(key, "found_rows")) {
        self->found_rows = SvTRUE(value) ? 1 : 0;
    } else if (strEQ(key, "ssl_verify_server_cert")) {
        self->ssl_verify_server_cert = (value && SvOK(value)) ? (SvTRUE(value) ? 1 : 0) : -1;
    } else if (strEQ(key, "ssl_mode")) {
        const char *mode_str = sv_to_temp_pv(aTHX_ value, NULL);
        if (mode_str) {
            self->ssl_mode = parse_ssl_mode(mode_str);
            self->ssl_mode_set = 1;
        } else {
            self->ssl_mode_set = 0;
        }
    } else if (strEQ(key, "charset")) {
        replace_str_from_sv(aTHX_ &self->charset, value);
    } else if (strEQ(key, "init_command")) {
        replace_str_from_sv(aTHX_ &self->init_command, value);
    } else if (strEQ(key, "ssl_key")) {
        replace_str_from_sv(aTHX_ &self->ssl_key, value);
    } else if (strEQ(key, "ssl_cert")) {
        replace_str_from_sv(aTHX_ &self->ssl_cert, value);
    } else if (strEQ(key, "ssl_ca")) {
        replace_str_from_sv(aTHX_ &self->ssl_ca, value);
    } else if (strEQ(key, "ssl_capath")) {
        replace_str_from_sv(aTHX_ &self->ssl_capath, value);
    } else if (strEQ(key, "ssl_cipher")) {
        replace_str_from_sv(aTHX_ &self->ssl_cipher, value);
    } else {
        croak("unknown option: %s", key);
    }

int
is_connected(EV::mysql self)
CODE:
    RETVAL = self->connected ? 1 : 0;
OUTPUT:
    RETVAL

int
is_connecting(EV::mysql self)
CODE:
    RETVAL = self->state == STATE_CONNECTING ? 1 : 0;
OUTPUT:
    RETVAL

SV *
error_message(EV::mysql self)
CODE:
    if (self->conn) {
        const char *e = mysql_error(self->conn);
        if (e && *e) RETVAL = newSVpv(e, 0);
        else RETVAL = (self->last_error && *self->last_error) ? newSVpv(self->last_error, 0) : &PL_sv_undef;
    } else {
        RETVAL = (self->last_error && *self->last_error) ? newSVpv(self->last_error, 0) : &PL_sv_undef;
    }
OUTPUT:
    RETVAL

unsigned int
error_number(EV::mysql self)
CODE:
    if (self->conn) {
        unsigned int e = mysql_errno(self->conn);
        RETVAL = e ? e : self->last_errno;
    } else {
        RETVAL = self->last_errno;
    }
OUTPUT:
    RETVAL

SV *
sqlstate(EV::mysql self)
CODE:
    if (self->conn && self->connected) {
        const char *s = mysql_sqlstate(self->conn);
        RETVAL = (s && *s) ? newSVpv(s, 0) : &PL_sv_undef;
    } else if (self->last_sqlstate[0]) {
        RETVAL = newSVpv(self->last_sqlstate, 0);
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

SV *
insert_id(EV::mysql self)
CODE:
    if (self->conn && self->connected) {
        RETVAL = newSVuv((UV)self->last_insert_id);
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

unsigned int
warning_count(EV::mysql self)
CODE:
    RETVAL = self->conn ? mysql_warning_count(self->conn) : self->last_warning_count;
OUTPUT:
    RETVAL

SV *
info(EV::mysql self)
CODE:
    if (self->conn) {
        const char *inf = mysql_info(self->conn);
        if (inf) RETVAL = newSVpv(inf, 0);
        else RETVAL = self->last_info ? newSVpv(self->last_info, 0) : &PL_sv_undef;
    } else {
        RETVAL = self->last_info ? newSVpv(self->last_info, 0) : &PL_sv_undef;
    }
OUTPUT:
    RETVAL

UV
server_version(EV::mysql self)
CODE:
    RETVAL = (self->conn && self->connected) ? (UV)mysql_get_server_version(self->conn) : 0;
OUTPUT:
    RETVAL

SV *
server_info(EV::mysql self)
CODE:
    if (self->conn && self->connected) {
        const char *s = mysql_get_server_info(self->conn);
        RETVAL = s ? newSVpv(s, 0) : &PL_sv_undef;
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

UV
thread_id(EV::mysql self)
CODE:
    if (self->conn && self->connected) {
        RETVAL = (UV)mysql_thread_id(self->conn);
    } else {
        RETVAL = (UV)self->last_thread_id;
    }
OUTPUT:
    RETVAL

SV *
host_info(EV::mysql self)
CODE:
    if (self->conn && self->connected) {
        const char *s = mysql_get_host_info(self->conn);
        RETVAL = s ? newSVpv(s, 0) : &PL_sv_undef;
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

SV *
character_set_name(EV::mysql self)
CODE:
    if (self->conn && self->connected) {
        const char *s = mysql_character_set_name(self->conn);
        RETVAL = s ? newSVpv(s, 0) : &PL_sv_undef;
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

int
socket(EV::mysql self)
CODE:
    RETVAL = (self->conn && self->state != STATE_DISCONNECTED) ? mysql_sock_fd(self->conn) : -1;
OUTPUT:
    RETVAL

IV
affected_rows(EV::mysql self)
CODE:
    RETVAL = (IV)self->last_affected_rows;
OUTPUT:
    RETVAL

SV *
escape(EV::mysql self, SV *str)
PREINIT:
    STRLEN len;
    const char *in;
    char *out;
    unsigned long elen;
    int is_u8;
    SV *str_snap;
CODE:
    HOLD_SELF_ST();
    if (check_fork_safety(aTHX_ self)) croak("not connected");
    if (!self->conn || !self->connected) croak("not connected");
    if (self->closing) croak("connection is closing");
    str_snap = sv_to_mortal_sql(aTHX_ self, str);
    if (!str_snap) croak("cannot escape undef");

    if (check_fork_safety(aTHX_ self)) croak("not connected");
    if (!self->conn || !self->connected) croak("not connected");
    if (self->closing) croak("connection is closing");

    is_u8 = SvUTF8(str_snap) ? 1 : 0;
    if ((is_u8 || self->utf8) && !is_conn_utf8(self)) {
        const char *cs = mysql_character_set_name(self->conn);
        warn("EV::mysql: escaping a UTF-8 string on a non-utf8 connection (%s) may cause corruption or injection vulnerabilities",
             cs ? cs : "unknown");
    }
    in = SvPVX_const(str_snap);
    len = SvCUR(str_snap);
    if (len > (STRLEN)(ULONG_MAX / 2 - 1)) croak("string too large to escape");

    RETVAL = newSV(len * 2 + 1);
    SvPOK_on(RETVAL);
    out = SvPVX(RETVAL);
    elen = mysql_real_escape_string(self->conn, out, in, (unsigned long)len);
    if (elen == (unsigned long)-1) {
        SvREFCNT_dec(RETVAL);
        croak("mysql_real_escape_string failed");
    }
    SvCUR_set(RETVAL, elen);
    if ((is_u8 || self->utf8) && is_conn_utf8(self)) SvUTF8_on(RETVAL);
OUTPUT:
    RETVAL

unsigned int
pending_count(EV::mysql self)
CODE:
    RETVAL = self->pending_count;
OUTPUT:
    RETVAL

void
skip_pending(EV::mysql self)
PREINIT:
    int in_cb;
CODE:
    HOLD_SELF_ST();
    if (check_fork_safety(aTHX_ self)) XSRETURN_EMPTY;
    if (self->pending_count == 0 && !self->current_op) XSRETURN_EMPTY;
    in_cb = (self->callback_depth > 0);
    self->callback_depth++;
    if (self->current_op && self->current_op->type == OP_STREAM && in_cb) {
        /* Inside stream row callback: free in-flight stream op silently so the
         * currently executing callback is not re-invoked with "skipped". */
        ev_mysql_op_t *sop = self->current_op;
        self->current_op = NULL;
        if (self->pending_count > 0) self->pending_count--;
        free_op(aTHX_ sop);
    }
    if (self->state == STATE_CONNECTING) {
        /* Spare an embryonic handshake; only cancel queued operations. */
        ev_mysql_stmt_t *s;
        self->closing = 0;
        for (s = self->stmt_list; s; s = s->next) s->closing = 0;
    } else if (self->state != STATE_IDLE && self->state != STATE_DISCONNECTED &&
               self->state != STATE_DEFERRED_OP) {
        /* An operation already sent bytes on the wire; close the socket cleanly
         * so remaining responses do not corrupt future requests. */
        cleanup_connection(aTHX_ self, 0);
    } else {
        ev_mysql_stmt_t *s;
        stop_timeout(self);
        if (loop_is_alive(self)) {
            ev_timer_stop(self->loop, &self->deferred_timer);
        }
        if (self->state != STATE_DISCONNECTED) {
            self->state = STATE_IDLE;
        }
        self->closing = 0;
        for (s = self->stmt_list; s; s = s->next) s->closing = 0;
    }
    fail_queued_ops(aTHX_ self, "skipped");
    if (!self->destroyed && self->connected && self->state == STATE_IDLE &&
        self->callback_depth == 1) {
        start_next_op(aTHX_ self);
    }
    self->callback_depth--;
    check_destroyed(aTHX_ self);

UV
lib_version(char *class_name)
CODE:
    PERL_UNUSED_VAR(class_name);
    RETVAL = (UV)mysql_get_client_version();
OUTPUT:
    RETVAL

SV *
lib_info(char *class_name)
CODE:
    PERL_UNUSED_VAR(class_name);
    RETVAL = newSVpv(mysql_get_client_info(), 0);
OUTPUT:
    RETVAL
