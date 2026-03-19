#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "EVAPI.h"
#include <mysql.h>

#include "ngx_queue.h"

typedef struct ev_mariadb_s ev_mariadb_t;
typedef struct ev_mariadb_cb_s ev_mariadb_cb_t;
typedef struct ev_mariadb_send_s ev_mariadb_send_t;
typedef struct ev_mariadb_stmt_s ev_mariadb_stmt_t;

typedef ev_mariadb_t* EV__MariaDB;
typedef struct ev_loop* EV__Loop;

#define EV_MARIADB_MAGIC 0xDEADBEEF
#define EV_MARIADB_FREED 0xFEEDFACE

enum ev_mariadb_state {
    STATE_IDLE,
    STATE_CONNECTING,
    STATE_SEND,
    STATE_READ_RESULT,
    STATE_STORE_RESULT,
    STATE_NEXT_RESULT,
    STATE_PING,
    STATE_CHANGE_USER,
    STATE_SELECT_DB,
    STATE_RESET_CONNECTION,
    STATE_SET_CHARSET,
    STATE_COMMIT,
    STATE_ROLLBACK,
    STATE_AUTOCOMMIT,
    STATE_STMT_PREPARE,     /* boundary: states >= here block query queueing */
    STATE_STMT_EXECUTE,
    STATE_STMT_STORE,
    STATE_STMT_CLOSE,
    STATE_STMT_RESET,
    STATE_STMT_SEND_LONG_DATA,
    STATE_REAL_QUERY,
    STATE_STREAM_FETCH,
    STATE_CLOSE,
};

struct ev_mariadb_s {
    unsigned int magic;
    struct ev_loop *loop;
    MYSQL *conn;

    ev_io    rio, wio;
    ev_timer timer;
    int      reading, writing, timing;
    int      fd;

    enum ev_mariadb_state state;
    char    *host, *user, *password, *database, *unix_socket;
    unsigned int port;

    ngx_queue_t cb_queue;       /* callbacks for sent queries (awaiting results) */
    ngx_queue_t send_queue;     /* queries waiting to be sent */
    int         pending_count;  /* total: send_queue + cb_queue */
    int         send_count;     /* queries sent, results not yet read */
    int         draining;       /* draining multi-result extras */

    /* current operation context */
    int          op_ret;
    MYSQL_RES   *op_result;
    MYSQL_STMT  *op_stmt;
    ev_mariadb_stmt_t *op_stmt_ctx;  /* per-stmt wrapper for bind_params cleanup */
    ev_mariadb_stmt_t *stmt_list;    /* all allocated stmt wrappers */
    MYSQL       *op_conn_ret;
    my_bool      op_bool_ret;
    MYSQL_ROW    op_row;        /* for streaming fetch_row result */
    SV          *stream_cb;     /* streaming per-row callback */
    char        *op_data_ptr;   /* copied data buffer for send_long_data */

    SV *on_connect;
    SV *on_error;

    int callback_depth;
    pid_t connect_pid;      /* PID at connect time, for fork detection */

    /* connection options (applied before mysql_real_connect_start) */
    unsigned int connect_timeout;
    unsigned int read_timeout;
    unsigned int write_timeout;
    int          compress;
    int          multi_statements;
    int          found_rows;
    char        *charset;
    char        *init_command;
    char        *ssl_key;
    char        *ssl_cert;
    char        *ssl_ca;
    char        *ssl_capath;
    char        *ssl_cipher;
    int          ssl_verify_server_cert;
    int          utf8;  /* auto-flag result strings as UTF-8 */
    unsigned long client_flags;
};

struct ev_mariadb_cb_s {
    SV          *cb;
    ngx_queue_t  queue;
};

struct ev_mariadb_send_s {
    char        *sql;
    unsigned long sql_len;
    SV          *cb;
    ngx_queue_t  queue;
};

struct ev_mariadb_stmt_s {
    MYSQL_STMT  *stmt;
    MYSQL_BIND  *bind_params;
    int          bind_param_count;
    int          closed;      /* invalidated by cleanup_connection */
    ev_mariadb_stmt_t *next;  /* linked list of all stmts on this connection */
};

#define MAX_PIPELINE_DEPTH 64
#define MAX_FREELIST_DEPTH 64

#define COPY_ERROR(buf, src) do { \
    strncpy((buf), (src), sizeof(buf) - 1); \
    (buf)[sizeof(buf) - 1] = '\0'; \
} while (0)

#define SET_STR_OPTION(field) do { \
    if (self->field) Safefree(self->field); \
    self->field = SvOK(value) ? safe_strdup(SvPV_nolen(value)) : NULL; \
} while (0)

#define IS_FORKED(self) \
    ((self)->connect_pid != 0 && (self)->connect_pid != getpid())

#define CHECK_READY(self, cb) \
    do { \
        if (NULL == (self)->conn || (self)->state == STATE_CONNECTING) \
            croak("not connected"); \
        if (IS_FORKED(self)) \
            croak("connection not valid after fork"); \
        if ((self)->state != STATE_IDLE) \
            croak("another operation is in progress"); \
        if ((self)->send_count > 0) \
            croak("cannot start operation while pipeline results are pending"); \
        if (!(SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV)) \
            croak("callback must be a CODE reference"); \
    } while (0)

#define CHECK_STMT(ctx) \
    do { \
        if (!(ctx)) \
            croak("invalid statement handle"); \
        if ((ctx)->closed) \
            croak("statement handle is no longer valid (connection was reset)"); \
    } while (0)

static void io_cb(EV_P_ ev_io *w, int revents);
static void timer_cb(EV_P_ ev_timer *w, int revents);
static void continue_operation(ev_mariadb_t *self, int events);
static void pipeline_advance(ev_mariadb_t *self);
static void on_next_result_done(ev_mariadb_t *self);
static void start_reading(ev_mariadb_t *self);
static void stop_reading(ev_mariadb_t *self);
static void start_writing(ev_mariadb_t *self);
static void stop_writing(ev_mariadb_t *self);
static void free_stmt_bind_params(ev_mariadb_stmt_t *ctx);
static int  is_utf8_charset(unsigned int charsetnr);
static void start_timer(ev_mariadb_t *self);
static void stop_timer(ev_mariadb_t *self);
static void update_watchers(ev_mariadb_t *self, int status);
static void emit_error(ev_mariadb_t *self, const char *msg);
static void cleanup_connection(ev_mariadb_t *self);
static int  check_destroyed(ev_mariadb_t *self);
static void drain_multi_result(ev_mariadb_t *self);
static AV*  build_field_names(MYSQL *conn, MYSQL_FIELD *fields, unsigned int ncols);
static void on_real_query_done(ev_mariadb_t *self);
static void on_stream_fetch_done(ev_mariadb_t *self);
static void on_close_done(ev_mariadb_t *self);

static void maybe_pipeline(ev_mariadb_t *self) {
    if (self->state == STATE_IDLE && !ngx_queue_empty(&self->send_queue))
        pipeline_advance(self);
    else if (self->state == STATE_IDLE) {
        stop_reading(self);
        stop_writing(self);
        stop_timer(self);
    }
}

/* --- freelist for cb_queue entries --- */

static ev_mariadb_cb_t *cbt_freelist = NULL;
static int cbt_freelist_size = 0;

static ev_mariadb_cb_t* alloc_cbt(void) {
    ev_mariadb_cb_t *cbt;
    if (cbt_freelist) {
        cbt = cbt_freelist;
        cbt_freelist = *(ev_mariadb_cb_t **)cbt;
        cbt_freelist_size--;
    } else {
        Newx(cbt, 1, ev_mariadb_cb_t);
    }
    return cbt;
}

static void release_cbt(ev_mariadb_cb_t *cbt) {
    if (cbt_freelist_size >= MAX_FREELIST_DEPTH) {
        Safefree(cbt);
        return;
    }
    *(ev_mariadb_cb_t **)cbt = cbt_freelist;
    cbt_freelist = cbt;
    cbt_freelist_size++;
}

/* --- freelist for send_queue entries --- */

static ev_mariadb_send_t *send_freelist = NULL;
static int send_freelist_size = 0;

static ev_mariadb_send_t* alloc_send(void) {
    ev_mariadb_send_t *s;
    if (send_freelist) {
        s = send_freelist;
        send_freelist = *(ev_mariadb_send_t **)s;
        send_freelist_size--;
    } else {
        Newx(s, 1, ev_mariadb_send_t);
    }
    return s;
}

static void release_send(ev_mariadb_send_t *s) {
    if (send_freelist_size >= MAX_FREELIST_DEPTH) {
        Safefree(s);
        return;
    }
    *(ev_mariadb_send_t **)s = send_freelist;
    send_freelist = s;
    send_freelist_size++;
}

static void push_send(ev_mariadb_t *self, const char *sql, STRLEN sql_len, SV *cb) {
    char *sql_copy;
    ev_mariadb_send_t *s;
    Newx(sql_copy, sql_len + 1, char);
    Copy(sql, sql_copy, sql_len + 1, char);

    s = alloc_send();
    s->sql = sql_copy;
    s->sql_len = (unsigned long)sql_len;
    s->cb = SvREFCNT_inc(cb);
    ngx_queue_insert_tail(&self->send_queue, &s->queue);
    self->pending_count++;
}

static void drain_queues_silent(ev_mariadb_t *self) {
    while (!ngx_queue_empty(&self->send_queue)) {
        ngx_queue_t *q = ngx_queue_head(&self->send_queue);
        ev_mariadb_send_t *send = ngx_queue_data(q, ev_mariadb_send_t, queue);
        ngx_queue_remove(q);
        Safefree(send->sql);
        SvREFCNT_dec(send->cb);
        release_send(send);
        self->pending_count--;
    }
    while (!ngx_queue_empty(&self->cb_queue)) {
        ngx_queue_t *q = ngx_queue_head(&self->cb_queue);
        ev_mariadb_cb_t *cbt = ngx_queue_data(q, ev_mariadb_cb_t, queue);
        ngx_queue_remove(q);
        SvREFCNT_dec(cbt->cb);
        release_cbt(cbt);
        self->pending_count--;
    }
}

/* --- watcher helpers --- */

static void start_reading(ev_mariadb_t *self) {
    if (!self->reading && self->fd >= 0) {
        ev_io_start(self->loop, &self->rio);
        self->reading = 1;
    }
}

static void stop_reading(ev_mariadb_t *self) {
    if (self->reading) {
        ev_io_stop(self->loop, &self->rio);
        self->reading = 0;
    }
}

static void start_writing(ev_mariadb_t *self) {
    if (!self->writing && self->fd >= 0) {
        ev_io_start(self->loop, &self->wio);
        self->writing = 1;
    }
}

static void stop_writing(ev_mariadb_t *self) {
    if (self->writing) {
        ev_io_stop(self->loop, &self->wio);
        self->writing = 0;
    }
}

static void start_timer(ev_mariadb_t *self) {
    if (!self->timing) {
        unsigned int ms = mysql_get_timeout_value_ms(self->conn);
        if (ms > 0) {
            ev_timer_set(&self->timer, ms / 1000.0, 0.0);
            ev_timer_start(self->loop, &self->timer);
            self->timing = 1;
        }
    }
}

static void stop_timer(ev_mariadb_t *self) {
    if (self->timing) {
        ev_timer_stop(self->loop, &self->timer);
        self->timing = 0;
    }
}

static void update_watchers(ev_mariadb_t *self, int status) {
    if (status & (MYSQL_WAIT_READ | MYSQL_WAIT_EXCEPT)) start_reading(self); else stop_reading(self);
    if (status & MYSQL_WAIT_WRITE) start_writing(self); else stop_writing(self);
    if (status & MYSQL_WAIT_TIMEOUT) start_timer(self); else stop_timer(self);
}

static void init_io_watchers(ev_mariadb_t *self) {
    ev_io_init(&self->rio, io_cb, self->fd, EV_READ);
    self->rio.data = (void *)self;
    ev_io_init(&self->wio, io_cb, self->fd, EV_WRITE);
    self->wio.data = (void *)self;
}

static int check_destroyed(ev_mariadb_t *self) {
    if (self->magic == EV_MARIADB_FREED &&
        self->callback_depth == 0) {
        Safefree(self);
        return 1;
    }
    return 0;
}

static void emit_error(ev_mariadb_t *self, const char *msg) {
    SV *cb;
    if (NULL == self->on_error) return;
    cb = sv_2mortal(SvREFCNT_inc_simple_NN(self->on_error));

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(msg, 0)));
    PUTBACK;

    call_sv(cb, G_DISCARD | G_EVAL);
    if (SvTRUE(ERRSV)) {
        warn("EV::MariaDB: exception in error handler: %s", SvPV_nolen(ERRSV));
        sv_setpvn(ERRSV, "", 0);
    }

    FREETMPS;
    LEAVE;
}

/* Pop and return the head callback from cb_queue. Caller must SvREFCNT_dec. */
static SV* pop_cb(ev_mariadb_t *self) {
    ngx_queue_t *q;
    ev_mariadb_cb_t *cbt;
    SV *cb;

    if (ngx_queue_empty(&self->cb_queue)) return NULL;

    q = ngx_queue_head(&self->cb_queue);
    cbt = ngx_queue_data(q, ev_mariadb_cb_t, queue);

    cb = cbt->cb;
    ngx_queue_remove(q);
    self->pending_count--;
    release_cbt(cbt);

    return cb;
}

/* Invoke a callback with (undef, errmsg). Decrements cb refcount. */
static void invoke_error_cb(SV *cb, const char *errmsg) {
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    PUSHs(&PL_sv_undef);
    PUSHs(sv_2mortal(newSVpv(errmsg, 0)));
    PUTBACK;
    call_sv(cb, G_DISCARD | G_EVAL);
    if (SvTRUE(ERRSV)) {
        warn("EV::MariaDB: exception in callback: %s", SvPV_nolen(ERRSV));
        sv_setpvn(ERRSV, "", 0);
    }
    SvREFCNT_dec(cb);
    FREETMPS;
    LEAVE;
}

/* Invoke a callback with (undef) — EOF signal. Decrements cb refcount. */
static void invoke_eof_cb(SV *cb) {
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    PUSHs(&PL_sv_undef);
    PUTBACK;
    call_sv(cb, G_DISCARD | G_EVAL);
    if (SvTRUE(ERRSV)) {
        warn("EV::MariaDB: exception in stream callback: %s", SvPV_nolen(ERRSV));
        sv_setpvn(ERRSV, "", 0);
    }
    SvREFCNT_dec(cb);
    FREETMPS;
    LEAVE;
}

/* Invoke a callback SV with args already on the stack. Decrements refcount. */
static void invoke_cb(SV *cb) {
    call_sv(cb, G_DISCARD | G_EVAL);
    if (SvTRUE(ERRSV)) {
        warn("EV::MariaDB: exception in callback: %s", SvPV_nolen(ERRSV));
        sv_setpvn(ERRSV, "", 0);
    }
    SvREFCNT_dec(cb);
}

/* Returns 1 if self was freed (caller must not touch self). */
static int deliver_result(ev_mariadb_t *self) {
    MYSQL_RES *res = self->op_result;
    SV *cb = pop_cb(self);

    if (cb == NULL) {
        if (res) {
            mysql_free_result(res);
            self->op_result = NULL;
        }
        return 0;
    }

    self->callback_depth++;

    {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);

        if (res == NULL && mysql_field_count(self->conn) > 0) {
            PUSHs(&PL_sv_undef);
            PUSHs(sv_2mortal(newSVpv(mysql_error(self->conn), 0)));
        }
        else if (res != NULL) {
            my_ulonglong nrows = mysql_num_rows(res);
            unsigned int ncols = mysql_num_fields(res);
            MYSQL_FIELD *fields = mysql_fetch_fields(res);
            AV *rows = newAV();
            AV *fnames;
            MYSQL_ROW row;
            unsigned long *lengths;

            if (nrows > 0) av_extend(rows, (SSize_t)(nrows < (my_ulonglong)SSize_t_MAX ? nrows - 1 : SSize_t_MAX));
            while ((row = mysql_fetch_row(res)) != NULL) {
                AV *r = newAV();
                unsigned int c;
                lengths = mysql_fetch_lengths(res);
                if (ncols > 0) av_extend(r, ncols - 1);
                for (c = 0; c < ncols; c++) {
                    if (row[c] == NULL) {
                        av_push(r, newSV(0));
                    } else {
                        SV *val = newSVpvn(row[c], lengths[c]);
                        if (self->utf8 && is_utf8_charset(fields[c].charsetnr))
                            SvUTF8_on(val);
                        av_push(r, val);
                    }
                }
                av_push(rows, newRV_noinc((SV*)r));
            }
            /* build field names before freeing result */
            fnames = build_field_names(self->conn, fields, ncols);
            mysql_free_result(res);
            self->op_result = NULL;
            PUSHs(sv_2mortal(newRV_noinc((SV*)rows)));
            PUSHs(&PL_sv_undef);
            PUSHs(sv_2mortal(newRV_noinc((SV*)fnames)));
        }
        else {
            my_ulonglong affected = mysql_affected_rows(self->conn);
            PUSHs(sv_2mortal(newSVuv((UV)affected)));
        }

        PUTBACK;
        invoke_cb(cb);
        FREETMPS;
        LEAVE;
    }

    self->callback_depth--;
    return check_destroyed(self);
}

/* Returns 1 if self was freed. */
static int deliver_error(ev_mariadb_t *self, const char *errmsg) {
    SV *cb = pop_cb(self);
    if (cb == NULL) return 0;

    self->callback_depth++;
    invoke_error_cb(cb, errmsg);
    self->callback_depth--;
    return check_destroyed(self);
}

/* Returns 1 if self was freed. Caller passes a non-mortal SV; ownership is
   transferred — deliver_value will sv_2mortal inside its SAVETMPS scope so
   FREETMPS correctly frees it (avoids mortal leak when sv_2mortal is called
   before SAVETMPS). */
static int deliver_value(ev_mariadb_t *self, SV *val) {
    SV *cb = pop_cb(self);
    if (cb == NULL) {
        SvREFCNT_dec(val);
        return 0;
    }

    self->callback_depth++;

    {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        PUSHs(sv_2mortal(val));
        PUTBACK;
        invoke_cb(cb);
        FREETMPS;
        LEAVE;
    }

    self->callback_depth--;
    return check_destroyed(self);
}

static void cleanup_connection(ev_mariadb_t *self) {
    int saved_fd = self->fd;
    int is_fork = IS_FORKED(self);

    stop_reading(self);
    stop_writing(self);
    stop_timer(self);
    self->fd = -1;
    self->state = STATE_IDLE;
    self->send_count = 0;
    self->draining = 0;

    if (self->op_data_ptr) {
        Safefree(self->op_data_ptr);
        self->op_data_ptr = NULL;
    }

    self->op_stmt_ctx = NULL;

    /* Invalidate all tracked stmt wrappers (don't free — user may hold handles) */
    {
        ev_mariadb_stmt_t *ctx = self->stmt_list;
        while (ctx) {
            free_stmt_bind_params(ctx);
            if (!is_fork && ctx->stmt) {
                if (ctx->stmt == self->op_stmt)
                    self->op_stmt = NULL;  /* avoid double-close below */
                mysql_stmt_close(ctx->stmt);
            }
            ctx->stmt = NULL;
            ctx->closed = 1;
            ctx = ctx->next;
        }
        /* keep stmt_list linked for close_stmt to unlink+free later */
    }

    if (is_fork) {
        self->op_result = NULL;
        self->op_stmt = NULL;
        self->conn = NULL;
    } else {
        if (self->op_result && saved_fd >= 0)
            shutdown(saved_fd, SHUT_RDWR);
        /* Close op_stmt if not tracked in stmt_list (e.g., in-flight prepare) */
        if (self->op_stmt) {
            mysql_stmt_close(self->op_stmt);
        }
        self->op_stmt = NULL;
        if (self->op_result) {
            mysql_free_result(self->op_result);
            self->op_result = NULL;
        }
        if (self->conn) {
            MYSQL *conn = self->conn;
            self->conn = NULL;
            mysql_close(conn);
        }
    }
}

static void cancel_pending(ev_mariadb_t *self, const char *errmsg) {
    ngx_queue_t local_send;
    ngx_queue_t local_cb;

    ngx_queue_init(&local_send);
    ngx_queue_init(&local_cb);

    if (!ngx_queue_empty(&self->send_queue)) {
        ngx_queue_add(&local_send, &self->send_queue);
        ngx_queue_init(&self->send_queue);
    }

    if (!ngx_queue_empty(&self->cb_queue)) {
        ngx_queue_add(&local_cb, &self->cb_queue);
        ngx_queue_init(&self->cb_queue);
    }

    self->send_count = 0;
    self->callback_depth++;

    /* cancel active stream if any */
    if (self->stream_cb) {
        SV *cb = self->stream_cb;
        self->stream_cb = NULL;
        self->pending_count--;
        invoke_error_cb(cb, errmsg);
    }

    /* cancel unsent queries */
    while (!ngx_queue_empty(&local_send)) {
        ngx_queue_t *q = ngx_queue_head(&local_send);
        ev_mariadb_send_t *send = ngx_queue_data(q, ev_mariadb_send_t, queue);
        SV *cb = send->cb;
        ngx_queue_remove(q);
        Safefree(send->sql);
        release_send(send);
        self->pending_count--;

        invoke_error_cb(cb, errmsg);
    }

    /* cancel sent-but-not-received */
    while (!ngx_queue_empty(&local_cb)) {
        ngx_queue_t *q = ngx_queue_head(&local_cb);
        ev_mariadb_cb_t *cbt = ngx_queue_data(q, ev_mariadb_cb_t, queue);
        SV *cb = cbt->cb;
        ngx_queue_remove(q);
        self->pending_count--;
        release_cbt(cbt);

        invoke_error_cb(cb, errmsg);
    }

    self->callback_depth--;
}

static void push_cb(ev_mariadb_t *self, SV *cb) {
    ev_mariadb_cb_t *cbt = alloc_cbt();
    cbt->cb = SvREFCNT_inc(cb);
    ngx_queue_insert_tail(&self->cb_queue, &cbt->queue);
    self->pending_count++;
}

/* Push cb to cb_queue, transferring ownership (no extra SvREFCNT_inc). */
static void push_cb_owned(ev_mariadb_t *self, SV *cb) {
    ev_mariadb_cb_t *cbt = alloc_cbt();
    cbt->cb = cb;
    ngx_queue_insert_tail(&self->cb_queue, &cbt->queue);
    /* pending_count was incremented by push_send; ownership transfers from send_queue to cb_queue */
}

static SV* handler_accessor(SV **slot, SV *handler, int has_arg) {
    if (has_arg) {
        if (NULL != *slot) {
            SvREFCNT_dec(*slot);
            *slot = NULL;
        }
        if (NULL != handler && SvOK(handler) &&
            SvROK(handler) && SvTYPE(SvRV(handler)) == SVt_PVCV) {
            *slot = SvREFCNT_inc(handler);
        }
    }

    return (NULL != *slot)
        ? SvREFCNT_inc(*slot)
        : &PL_sv_undef;
}

/* --- Multi-result drain --- */

static void drain_multi_result(ev_mariadb_t *self) {
    int status;

    self->draining = 1;
    status = mysql_next_result_start(&self->op_ret, self->conn);
    if (status != 0) {
        self->state = STATE_NEXT_RESULT;
        update_watchers(self, status);
        return;
    }
    on_next_result_done(self);
}

static void on_next_result_done(ev_mariadb_t *self) {
    int status;

    for (;;) {
        if (self->op_ret > 0) {
            /* error in secondary result set — report and stop draining */
            self->draining = 0;
            self->state = STATE_IDLE;
            self->callback_depth++;
            emit_error(self, mysql_error(self->conn));
            self->callback_depth--;
            if (check_destroyed(self)) return;
            if (self->state != STATE_IDLE) return;
            if (self->conn && mysql_more_results(self->conn)) {
                drain_multi_result(self);
                return;
            }
            pipeline_advance(self);
            return;
        }

        if (self->op_ret == -1) {
            /* no more results */
            break;
        }

        /* op_ret == 0: another result set is available */
        if (mysql_field_count(self->conn) > 0) {
            status = mysql_store_result_start(&self->op_result, self->conn);
            if (status != 0) {
                self->state = STATE_STORE_RESULT;
                update_watchers(self, status);
                return;
            }
            /* synchronous store — free and continue drain */
            if (self->op_result) {
                mysql_free_result(self->op_result);
                self->op_result = NULL;
            }
        }

        /* DML result or sync store done — check for more */
        if (!mysql_more_results(self->conn))
            break;

        status = mysql_next_result_start(&self->op_ret, self->conn);
        if (status != 0) {
            self->state = STATE_NEXT_RESULT;
            update_watchers(self, status);
            return;
        }
        /* synchronous completion — loop instead of recursing */
    }

    self->draining = 0;
    self->state = STATE_IDLE;
    pipeline_advance(self);
}

/* --- Pipeline: send_query + read_query_result state machine --- */

static void handle_send_failure(ev_mariadb_t *self, ev_mariadb_send_t *send) {
    char errbuf[512];
    SV *cb = send->cb;
    Safefree(send->sql);
    release_send(send);
    self->pending_count--;

    COPY_ERROR(errbuf, mysql_error(self->conn));

    self->state = STATE_IDLE;
    self->callback_depth++;
    invoke_error_cb(cb, errbuf);
    self->callback_depth--;
    if (check_destroyed(self)) return;
    if (self->state != STATE_IDLE) return;
    cancel_pending(self, "send failed");
    if (check_destroyed(self)) return;
    if (self->state != STATE_IDLE) return;
    drain_queues_silent(self);
    cleanup_connection(self);
}

static void on_send_done(ev_mariadb_t *self) {
    ngx_queue_t *q = ngx_queue_head(&self->send_queue);
    ev_mariadb_send_t *send = ngx_queue_data(q, ev_mariadb_send_t, queue);
    ngx_queue_remove(q);

    if (self->op_ret != 0) {
        handle_send_failure(self, send);
        return;
    }

    push_cb_owned(self, send->cb);
    Safefree(send->sql);
    release_send(send);
    self->send_count++;

    self->state = STATE_IDLE;
    pipeline_advance(self);
}

static void on_read_result_done(ev_mariadb_t *self) {
    int status;

    if (self->op_bool_ret != 0) {
        /* query returned an error */
        self->send_count--;
        self->state = STATE_IDLE;
        if (deliver_error(self, mysql_error(self->conn))) return;
        if (self->state != STATE_IDLE) return;
        /* drain any remaining result sets */
        if (self->conn && mysql_more_results(self->conn)) {
            drain_multi_result(self);
            return;
        }
        pipeline_advance(self);
        return;
    }

    if (mysql_field_count(self->conn) > 0) {
        /* has result set — store it */
        status = mysql_store_result_start(&self->op_result, self->conn);
        if (status != 0) {
            self->state = STATE_STORE_RESULT;
            update_watchers(self, status);
            return;
        }
        /* synchronous store completion — fall through below */
    }

    /* DML or synchronous store_result completion */
    {
        self->send_count--;
        self->state = STATE_IDLE;
        if (deliver_result(self)) return;
        if (self->state != STATE_IDLE) return;
        /* drain any extra result sets from multi-result queries */
        if (self->conn && mysql_more_results(self->conn)) {
            drain_multi_result(self);
            return;
        }
        pipeline_advance(self);
    }
}

/* Called when store_result_cont completes (pipeline text query path) */
static void on_store_result_done(ev_mariadb_t *self) {
    if (self->draining) {
        MYSQL_RES *res = self->op_result;
        self->op_result = NULL;
        /* draining multi-result: free and continue */
        if (res) mysql_free_result(res);
        if (self->conn && mysql_more_results(self->conn)) {
            int status = mysql_next_result_start(&self->op_ret, self->conn);
            if (status != 0) {
                self->state = STATE_NEXT_RESULT;
                update_watchers(self, status);
                return;
            }
            on_next_result_done(self);
            return;
        }
        self->draining = 0;
        self->state = STATE_IDLE;
        pipeline_advance(self);
        return;
    }

    self->send_count--;
    self->state = STATE_IDLE;

    if (deliver_result(self)) return;
    if (self->state != STATE_IDLE) return;
    /* drain any extra result sets */
    if (self->conn && mysql_more_results(self->conn)) {
        drain_multi_result(self);
        return;
    }
    pipeline_advance(self);
}

/*
 * Pipeline orchestrator. Called when state == IDLE.
 * Phase 1: send all queued queries via mysql_send_query.
 * Phase 2: read next result via mysql_read_query_result.
 */
static void pipeline_advance(ev_mariadb_t *self) {
    int status;

    /* Ensure clean watcher state — previous operations may have left
     * watchers active after completing synchronously within their
     * done handlers. Without this, subsequent operations that need
     * the same watcher direction would skip ev_io_start. */
    stop_reading(self);
    stop_writing(self);
    stop_timer(self);

send_phase:
    /* Phase 1: send up to MAX_PIPELINE_DEPTH queries */
    while (!ngx_queue_empty(&self->send_queue) &&
           self->send_count < MAX_PIPELINE_DEPTH) {
        ngx_queue_t *q = ngx_queue_head(&self->send_queue);
        ev_mariadb_send_t *send = ngx_queue_data(q, ev_mariadb_send_t, queue);

        status = mysql_send_query_start(&self->op_ret, self->conn,
            send->sql, send->sql_len);

        if (status != 0) {
            /* need async IO to finish sending */
            self->state = STATE_SEND;
            update_watchers(self, status);
            return;
        }

        /* synchronous send completion */
        ngx_queue_remove(q);

        if (self->op_ret != 0) {
            handle_send_failure(self, send);
            return;
        }

        push_cb_owned(self, send->cb);
        Safefree(send->sql);
        release_send(send);
        self->send_count++;
    }

    /* Phase 2: read next result */
    while (self->send_count > 0) {
        status = mysql_read_query_result_start(&self->op_bool_ret, self->conn);

        if (status != 0) {
            self->state = STATE_READ_RESULT;
            update_watchers(self, status);
            return;
        }

        /* synchronous read completion */
        if (self->op_bool_ret != 0) {
            /* query error */
            self->send_count--;
            if (deliver_error(self, mysql_error(self->conn))) return;
            /* callback may have started a new operation */
            if (self->state != STATE_IDLE) return;
            if (self->conn && mysql_more_results(self->conn)) {
                drain_multi_result(self);
                return;
            }
            if (!ngx_queue_empty(&self->send_queue)) goto send_phase;
            continue;
        }

        if (mysql_field_count(self->conn) > 0) {
            /* has result set */
            status = mysql_store_result_start(&self->op_result, self->conn);
            if (status != 0) {
                self->state = STATE_STORE_RESULT;
                update_watchers(self, status);
                return;
            }
        }

        {
            self->send_count--;
            if (deliver_result(self)) return;
            /* callback may have started a new operation */
            if (self->state != STATE_IDLE) return;
            if (self->conn && mysql_more_results(self->conn)) {
                drain_multi_result(self);
                return;
            }
            /* loop back to check send_queue (callback may have queued more) */
            if (!ngx_queue_empty(&self->send_queue)) goto send_phase;
        }
    }

    self->state = STATE_IDLE;
}

/* --- Connection --- */

static void on_connect_done(ev_mariadb_t *self) {
    self->state = STATE_IDLE;

    if (self->op_conn_ret == NULL) {
        char errbuf[512];
        COPY_ERROR(errbuf, mysql_error(self->conn));
        self->callback_depth++;
        emit_error(self, errbuf);
        self->callback_depth--;
        if (check_destroyed(self)) return;
        /* on_error handler may have called reset(), starting a new connection;
           if state is no longer IDLE, don't touch the new connection */
        if (self->state != STATE_IDLE) return;
        cancel_pending(self, errbuf);
        if (check_destroyed(self)) return;
        if (self->state != STATE_IDLE) return;
        drain_queues_silent(self);
        cleanup_connection(self);
        return;
    }

    /* connected — reinit watchers for normal IO */
    stop_reading(self);
    stop_writing(self);
    stop_timer(self);

    self->fd = mysql_get_socket(self->conn);

    if (self->fd < 0) {
        self->callback_depth++;
        emit_error(self, "mysql_get_socket returned invalid fd");
        self->callback_depth--;
        if (check_destroyed(self)) return;
        if (self->state != STATE_IDLE) return;
        cancel_pending(self, "invalid fd");
        if (check_destroyed(self)) return;
        if (self->state != STATE_IDLE) return;
        drain_queues_silent(self);
        cleanup_connection(self);
        return;
    }

    init_io_watchers(self);

    if (NULL != self->on_connect) {
        SV *cb = sv_2mortal(SvREFCNT_inc_simple_NN(self->on_connect));
        self->callback_depth++;

        {
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            PUTBACK;

            call_sv(cb, G_DISCARD | G_EVAL);
            if (SvTRUE(ERRSV)) {
                warn("EV::MariaDB: exception in connect handler: %s", SvPV_nolen(ERRSV));
                sv_setpvn(ERRSV, "", 0);
            }

            FREETMPS;
            LEAVE;
        }

        self->callback_depth--;
        if (check_destroyed(self)) return;
    }

    /* start pipeline if queries were queued during connection */
    maybe_pipeline(self);
}

/* --- Prepared statements --- */

static void on_stmt_prepare_done(ev_mariadb_t *self) {
    MYSQL_STMT *stmt = self->op_stmt;
    self->op_stmt = NULL;
    self->state = STATE_IDLE;

    if (self->op_ret != 0) {
        char errbuf[512];
        COPY_ERROR(errbuf, mysql_stmt_error(stmt));
        mysql_stmt_close(stmt);
        if (deliver_error(self, errbuf)) return;
        maybe_pipeline(self);
        return;
    }

    {
        ev_mariadb_stmt_t *ctx;
        Newxz(ctx, 1, ev_mariadb_stmt_t);
        ctx->stmt = stmt;
        ctx->next = self->stmt_list;
        self->stmt_list = ctx;
        if (deliver_value(self, newSViv(PTR2IV(ctx)))) return;
    }
    maybe_pipeline(self);
}

static void on_stmt_execute_done(ev_mariadb_t *self) {
    MYSQL_STMT *stmt = self->op_stmt;
    self->op_stmt = NULL;
    self->state = STATE_IDLE;

    if (self->op_ret != 0) {
        if (deliver_error(self, mysql_stmt_error(stmt))) return;
        maybe_pipeline(self);
        return;
    }

    {
        MYSQL_RES *meta;
        SV *cb;
        meta = mysql_stmt_result_metadata(stmt);
        self->op_result = meta;
        cb = pop_cb(self);
        if (cb == NULL) {
            if (self->op_result) {
                mysql_free_result(self->op_result);
                self->op_result = NULL;
            }
            maybe_pipeline(self);
            return;
        }

        self->callback_depth++;
        {
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);

            if (self->op_result == NULL) {
                my_ulonglong affected = mysql_stmt_affected_rows(stmt);
                PUSHs(sv_2mortal(newSVuv((UV)affected)));
            }
            else {
                unsigned int ncols = mysql_num_fields(self->op_result);
                MYSQL_FIELD *fields = mysql_fetch_fields(self->op_result);
                MYSQL_BIND *bind;
                unsigned long *lengths;
                my_bool *is_null;
                char **buffers;
                unsigned int c;
                AV *rows = newAV();
                int fetch_ret;

                Newxz(bind, ncols, MYSQL_BIND);
                SAVEFREEPV(bind);
                Newx(lengths, ncols, unsigned long);
                SAVEFREEPV(lengths);
                Newx(is_null, ncols, my_bool);
                SAVEFREEPV(is_null);
                Newx(buffers, ncols, char *);
                SAVEFREEPV(buffers);

                for (c = 0; c < ncols; c++) {
                    unsigned long buflen = fields[c].max_length;
                    if (buflen < 256) buflen = 256;
                    Newx(buffers[c], buflen, char);
                    SAVEFREEPV(buffers[c]);
                    bind[c].buffer_type = MYSQL_TYPE_STRING;
                    bind[c].buffer = buffers[c];
                    bind[c].buffer_length = buflen;
                    bind[c].length = &lengths[c];
                    bind[c].is_null = &is_null[c];
                }

                if (mysql_stmt_bind_result(stmt, bind)) {
                    mysql_stmt_free_result(stmt);
                    mysql_free_result(self->op_result);
                    self->op_result = NULL;
                    SvREFCNT_dec((SV*)rows);

                    PUSHs(&PL_sv_undef);
                    PUSHs(sv_2mortal(newSVpv(mysql_stmt_error(stmt), 0)));
                    goto invoke;
                }

                while ((fetch_ret = mysql_stmt_fetch(stmt)) == 0) {
                    AV *row = newAV();
                    if (ncols > 0) av_extend(row, ncols - 1);
                    for (c = 0; c < ncols; c++) {
                        if (is_null[c]) {
                            av_push(row, newSV(0));
                        } else {
                            SV *val = newSVpvn(buffers[c], lengths[c]);
                            if (self->utf8 && is_utf8_charset(fields[c].charsetnr))
                                SvUTF8_on(val);
                            av_push(row, val);
                        }
                    }
                    av_push(rows, newRV_noinc((SV*)row));
                }

                if (fetch_ret != 0 && fetch_ret != MYSQL_NO_DATA) {
                    mysql_free_result(self->op_result);
                    self->op_result = NULL;
                    mysql_stmt_free_result(stmt);
                    SvREFCNT_dec((SV*)rows);
                    PUSHs(&PL_sv_undef);
                    if (fetch_ret == MYSQL_DATA_TRUNCATED)
                        PUSHs(sv_2mortal(newSVpvs("data truncated")));
                    else
                        PUSHs(sv_2mortal(newSVpv(mysql_stmt_error(stmt), 0)));
                } else {
                    AV *fnames = build_field_names(self->conn, fields, ncols);
                    mysql_free_result(self->op_result);
                    self->op_result = NULL;
                    mysql_stmt_free_result(stmt);
                    PUSHs(sv_2mortal(newRV_noinc((SV*)rows)));
                    PUSHs(&PL_sv_undef);
                    PUSHs(sv_2mortal(newRV_noinc((SV*)fnames)));
                }
            }

        invoke:
            PUTBACK;
            invoke_cb(cb);
            FREETMPS;
            LEAVE;
        }
        self->callback_depth--;
        if (check_destroyed(self)) return;
        maybe_pipeline(self);
    }
}

static void on_stmt_store_done(ev_mariadb_t *self) {
    if (self->op_ret != 0) {
        MYSQL_STMT *stmt = self->op_stmt;
        self->op_stmt = NULL;
        self->state = STATE_IDLE;
        if (deliver_error(self, mysql_stmt_error(stmt))) return;
        maybe_pipeline(self);
        return;
    }
    on_stmt_execute_done(self);
}

static void unlink_stmt(ev_mariadb_t *self, ev_mariadb_stmt_t *ctx) {
    ev_mariadb_stmt_t **pp = &self->stmt_list;
    while (*pp) {
        if (*pp == ctx) { *pp = ctx->next; return; }
        pp = &(*pp)->next;
    }
}

static void on_stmt_close_done(ev_mariadb_t *self) {
    self->op_stmt = NULL;  /* stmt freed by mysql_stmt_close */
    if (self->op_stmt_ctx) {
        unlink_stmt(self, self->op_stmt_ctx);
        Safefree(self->op_stmt_ctx);
        self->op_stmt_ctx = NULL;
    }
    self->state = STATE_IDLE;
    if (self->op_bool_ret != 0) {
        if (deliver_error(self, mysql_error(self->conn))) return;
    } else {
        if (deliver_value(self, newSViv(1))) return;
    }
    maybe_pipeline(self);
}

static void on_stmt_reset_done(ev_mariadb_t *self) {
    MYSQL_STMT *stmt = self->op_stmt;
    self->op_stmt = NULL;
    self->state = STATE_IDLE;
    if (self->op_bool_ret != 0) {
        if (deliver_error(self, mysql_stmt_error(stmt))) return;
    } else {
        if (deliver_value(self, newSViv(1))) return;
    }
    maybe_pipeline(self);
}

/* --- Async utility operation done handler --- */

static void on_utility_done(ev_mariadb_t *self, int failed) {
    self->state = STATE_IDLE;
    if (failed) {
        if (deliver_error(self, mysql_error(self->conn))) return;
    } else {
        if (deliver_value(self, newSViv(1))) return;
    }
    maybe_pipeline(self);
}

static void free_stmt_bind_params(ev_mariadb_stmt_t *ctx) {
    int i;
    if (!ctx->bind_params) return;
    for (i = 0; i < ctx->bind_param_count; i++) {
        Safefree(ctx->bind_params[i].buffer);
    }
    Safefree(ctx->bind_params);
    ctx->bind_params = NULL;
    ctx->bind_param_count = 0;
}

static void transition_to_stmt_store(ev_mariadb_t *self) {
    int status;
    self->op_stmt_ctx = NULL;  /* bind_params live in wrapper, not freed here */
    if (self->op_ret != 0) {
        on_stmt_execute_done(self);
    } else {
        self->state = STATE_STMT_STORE;
        status = mysql_stmt_store_result_start(&self->op_ret, self->op_stmt);
        if (status == 0) {
            on_stmt_store_done(self);
        } else {
            update_watchers(self, status);
        }
    }
}

/* --- Streaming query (mysql_use_result + fetch_row) --- */

static void stream_error(ev_mariadb_t *self) {
    SV *cb = self->stream_cb;
    char errbuf[512];
    COPY_ERROR(errbuf, mysql_error(self->conn));
    self->stream_cb = NULL;
    self->state = STATE_IDLE;
    self->pending_count--;
    self->callback_depth++;
    invoke_error_cb(cb, errbuf);
    self->callback_depth--;
}

static void on_real_query_done(ev_mariadb_t *self) {
    int status;

    if (self->op_ret != 0) {
        stream_error(self);
        if (check_destroyed(self)) return;
        maybe_pipeline(self);
        return;
    }

    self->op_result = mysql_use_result(self->conn);
    if (!self->op_result) {
        const char *err = mysql_error(self->conn);
        if (err && err[0]) {
            stream_error(self);
            if (check_destroyed(self)) return;
        } else {
            /* DML or no-result query: deliver EOF to stream callback */
            SV *cb = self->stream_cb;
            self->stream_cb = NULL;
            self->state = STATE_IDLE;
            self->pending_count--;
            self->callback_depth++;
            invoke_eof_cb(cb);
            self->callback_depth--;
            if (check_destroyed(self)) return;
        }
        maybe_pipeline(self);
        return;
    }

    status = mysql_fetch_row_start(&self->op_row, self->op_result);
    if (status == 0) {
        on_stream_fetch_done(self);
    } else {
        self->state = STATE_STREAM_FETCH;
        update_watchers(self, status);
    }
}

static void on_stream_fetch_done(ev_mariadb_t *self) {
    MYSQL_FIELD *fields = (self->utf8 && self->op_result)
        ? mysql_fetch_fields(self->op_result) : NULL;

    for (;;) {
        MYSQL_ROW row = self->op_row;

        if (row == NULL) break;

        /* deliver row to callback */
        {
            unsigned int ncols = mysql_num_fields(self->op_result);
            unsigned long *lengths = mysql_fetch_lengths(self->op_result);
            AV *r = newAV();
            unsigned int c;

            if (ncols > 0) av_extend(r, ncols - 1);
            for (c = 0; c < ncols; c++) {
                if (row[c] == NULL) {
                    av_push(r, newSV(0));
                } else {
                    SV *val = newSVpvn(row[c], lengths[c]);
                    if (fields && is_utf8_charset(fields[c].charsetnr))
                        SvUTF8_on(val);
                    av_push(r, val);
                }
            }

            /* Detach stream_cb before invoking: prevents cancel_pending
               from double-firing the callback if finish() is called inside */
            {
                SV *saved_cb = self->stream_cb;
                self->stream_cb = NULL;
                self->pending_count--;

                self->callback_depth++;
                {
                    SV *cb = sv_2mortal(SvREFCNT_inc_simple_NN(saved_cb));
                    dSP;
                    ENTER;
                    SAVETMPS;
                    PUSHMARK(SP);
                    PUSHs(sv_2mortal(newRV_noinc((SV*)r)));
                    PUTBACK;
                    call_sv(cb, G_DISCARD | G_EVAL);
                    if (SvTRUE(ERRSV)) {
                        warn("EV::MariaDB: exception in stream callback: %s", SvPV_nolen(ERRSV));
                        sv_setpvn(ERRSV, "", 0);
                    }
                    FREETMPS;
                    LEAVE;
                }
                self->callback_depth--;
                if (check_destroyed(self)) {
                    SvREFCNT_dec(saved_cb);
                    return;
                }

                /* Was stream cancelled (finish/reset from callback)? */
                if (self->stream_cb != NULL) {
                    /* callback started a new stream — don't touch */
                    SvREFCNT_dec(saved_cb);
                } else if (self->conn == NULL || self->op_result == NULL) {
                    /* connection torn down — stream is over */
                    SvREFCNT_dec(saved_cb);
                    return;
                } else {
                    /* normal: restore for next row */
                    self->stream_cb = saved_cb;
                    self->pending_count++;
                }
            }
        }

        /* fetch next row */
        {
            int status = mysql_fetch_row_start(&self->op_row, self->op_result);
            if (status != 0) {
                self->state = STATE_STREAM_FETCH;
                update_watchers(self, status);
                return;
            }
        }
    }

    /* row == NULL: EOF or error */
    {
        SV *cb = self->stream_cb;
        char errbuf[512];
        const char *err = mysql_error(self->conn);
        int has_error = (err && err[0]);
        if (has_error) COPY_ERROR(errbuf, err);

        self->stream_cb = NULL;
        mysql_free_result(self->op_result);
        self->op_result = NULL;
        self->state = STATE_IDLE;
        self->pending_count--;

        self->callback_depth++;
        if (has_error) {
            invoke_error_cb(cb, errbuf);
        } else {
            invoke_eof_cb(cb);
        }
        self->callback_depth--;
        if (check_destroyed(self)) return;
        /* drain any secondary result sets from multi_statements */
        if (self->conn && mysql_more_results(self->conn)) {
            drain_multi_result(self);
            return;
        }
        maybe_pipeline(self);
    }
}

/* --- Async close --- */

static void on_close_done(ev_mariadb_t *self) {
    SV *cb;

    /* conn was freed by mysql_close */
    self->conn = NULL;
    self->fd = -1;
    stop_reading(self);
    stop_writing(self);
    stop_timer(self);
    self->state = STATE_IDLE;

    /* pop our callback before cancel_pending fires errors for remaining items */
    cb = pop_cb(self);

    /* cancel any items queued from within a callback before close_async */
    cancel_pending(self, "connection closed");
    if (check_destroyed(self)) {
        SvREFCNT_dec(cb);
        return;
    }

    if (cb) {
        SV *val = newSViv(1);
        self->callback_depth++;
        {
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            PUSHs(sv_2mortal(val));
            PUTBACK;
            invoke_cb(cb);
            FREETMPS;
            LEAVE;
        }
        self->callback_depth--;
        if (check_destroyed(self)) return;
    }
    /* no maybe_pipeline: conn is NULL, nothing can be sent */
}

/* --- Send long data done --- */

static void on_send_long_data_done(ev_mariadb_t *self) {
    MYSQL_STMT *stmt = self->op_stmt;

    if (self->op_data_ptr) {
        Safefree(self->op_data_ptr);
        self->op_data_ptr = NULL;
    }
    self->op_stmt = NULL;
    self->state = STATE_IDLE;

    if (self->op_bool_ret != 0) {
        if (deliver_error(self, mysql_stmt_error(stmt))) return;
    } else {
        if (deliver_value(self, newSViv(1))) return;
    }
    maybe_pipeline(self);
}

/* --- Main continuation dispatcher --- */

static void continue_operation(ev_mariadb_t *self, int events) {
    int status;

    switch (self->state) {
    case STATE_CONNECTING:
        status = mysql_real_connect_cont(&self->op_conn_ret, self->conn, events);
        if (status == 0) {
            on_connect_done(self);
        } else {
            update_watchers(self, status);
        }
        break;

    case STATE_SEND:
        status = mysql_send_query_cont(&self->op_ret, self->conn, events);
        if (status == 0) {
            on_send_done(self);
        } else {
            update_watchers(self, status);
        }
        break;

    case STATE_READ_RESULT:
        status = mysql_read_query_result_cont(&self->op_bool_ret, self->conn, events);
        if (status == 0) {
            on_read_result_done(self);
        } else {
            update_watchers(self, status);
        }
        break;

    case STATE_STORE_RESULT:
        status = mysql_store_result_cont(&self->op_result, self->conn, events);
        if (status == 0) {
            on_store_result_done(self);
        } else {
            update_watchers(self, status);
        }
        break;

    case STATE_NEXT_RESULT:
        status = mysql_next_result_cont(&self->op_ret, self->conn, events);
        if (status == 0) {
            on_next_result_done(self);
        } else {
            update_watchers(self, status);
        }
        break;

    case STATE_STMT_PREPARE:
        status = mysql_stmt_prepare_cont(&self->op_ret, self->op_stmt, events);
        if (status == 0) {
            on_stmt_prepare_done(self);
        } else {
            update_watchers(self, status);
        }
        break;

    case STATE_STMT_EXECUTE:
        status = mysql_stmt_execute_cont(&self->op_ret, self->op_stmt, events);
        if (status == 0) {
            transition_to_stmt_store(self);
        } else {
            update_watchers(self, status);
        }
        break;

    case STATE_STMT_STORE:
        status = mysql_stmt_store_result_cont(&self->op_ret, self->op_stmt, events);
        if (status == 0) {
            on_stmt_store_done(self);
        } else {
            update_watchers(self, status);
        }
        break;

    case STATE_STMT_CLOSE:
        status = mysql_stmt_close_cont(&self->op_bool_ret, self->op_stmt, events);
        if (status == 0) {
            on_stmt_close_done(self);
        } else {
            update_watchers(self, status);
        }
        break;

    case STATE_STMT_RESET:
        status = mysql_stmt_reset_cont(&self->op_bool_ret, self->op_stmt, events);
        if (status == 0) {
            on_stmt_reset_done(self);
        } else {
            update_watchers(self, status);
        }
        break;

    case STATE_PING:
        status = mysql_ping_cont(&self->op_ret, self->conn, events);
        if (status == 0) {
            on_utility_done(self, self->op_ret != 0);
        } else {
            update_watchers(self, status);
        }
        break;

    case STATE_CHANGE_USER:
        status = mysql_change_user_cont(&self->op_bool_ret, self->conn, events);
        if (status == 0) {
            on_utility_done(self, self->op_bool_ret != 0);
        } else {
            update_watchers(self, status);
        }
        break;

    case STATE_SELECT_DB:
        status = mysql_select_db_cont(&self->op_ret, self->conn, events);
        if (status == 0) {
            on_utility_done(self, self->op_ret != 0);
        } else {
            update_watchers(self, status);
        }
        break;

    case STATE_RESET_CONNECTION:
        status = mysql_reset_connection_cont(&self->op_ret, self->conn, events);
        if (status == 0) {
            on_utility_done(self, self->op_ret != 0);
        } else {
            update_watchers(self, status);
        }
        break;

    case STATE_SET_CHARSET:
        status = mysql_set_character_set_cont(&self->op_ret, self->conn, events);
        if (status == 0) {
            on_utility_done(self, self->op_ret != 0);
        } else {
            update_watchers(self, status);
        }
        break;

    case STATE_COMMIT:
        status = mysql_commit_cont(&self->op_bool_ret, self->conn, events);
        if (status == 0) {
            on_utility_done(self, self->op_bool_ret != 0);
        } else {
            update_watchers(self, status);
        }
        break;

    case STATE_ROLLBACK:
        status = mysql_rollback_cont(&self->op_bool_ret, self->conn, events);
        if (status == 0) {
            on_utility_done(self, self->op_bool_ret != 0);
        } else {
            update_watchers(self, status);
        }
        break;

    case STATE_AUTOCOMMIT:
        status = mysql_autocommit_cont(&self->op_bool_ret, self->conn, events);
        if (status == 0) {
            on_utility_done(self, self->op_bool_ret != 0);
        } else {
            update_watchers(self, status);
        }
        break;

    case STATE_STMT_SEND_LONG_DATA:
        status = mysql_stmt_send_long_data_cont(&self->op_bool_ret, self->op_stmt, events);
        if (status == 0) {
            on_send_long_data_done(self);
        } else {
            update_watchers(self, status);
        }
        break;

    case STATE_REAL_QUERY:
        status = mysql_real_query_cont(&self->op_ret, self->conn, events);
        if (status == 0) {
            on_real_query_done(self);
        } else {
            update_watchers(self, status);
        }
        break;

    case STATE_STREAM_FETCH:
        status = mysql_fetch_row_cont(&self->op_row, self->op_result, events);
        if (status == 0) {
            on_stream_fetch_done(self);
        } else {
            update_watchers(self, status);
        }
        break;

    case STATE_CLOSE:
        status = mysql_close_cont(self->conn, events);
        if (status == 0) {
            on_close_done(self);
        } else {
            update_watchers(self, status);
        }
        break;

    default:
        warn("EV::MariaDB: unexpected state %d in continue_operation", self->state);
        break;
    }
}

static void io_cb(EV_P_ ev_io *w, int revents) {
    ev_mariadb_t *self = (ev_mariadb_t *)w->data;
    int events = 0;
    (void)loop;

    if (self == NULL || self->magic != EV_MARIADB_MAGIC) return;
    if (NULL == self->conn) return;

    if (revents & EV_READ)  events |= MYSQL_WAIT_READ | MYSQL_WAIT_EXCEPT;
    if (revents & EV_WRITE) events |= MYSQL_WAIT_WRITE;

    continue_operation(self, events);
}

static void timer_cb(EV_P_ ev_timer *w, int revents) {
    ev_mariadb_t *self = (ev_mariadb_t *)w->data;
    (void)loop;
    (void)revents;

    if (self == NULL || self->magic != EV_MARIADB_MAGIC) return;
    if (NULL == self->conn) return;

    self->timing = 0;
    continue_operation(self, MYSQL_WAIT_TIMEOUT);
}

static char* safe_strdup(const char *s) {
    char *d;
    size_t len;
    if (!s) return NULL;
    len = strlen(s);
    Newx(d, len + 1, char);
    Copy(s, d, len + 1, char);
    return d;
}

static void free_connect_strings(ev_mariadb_t *self) {
    if (self->host)        { Safefree(self->host);        self->host = NULL; }
    if (self->user)        { Safefree(self->user);        self->user = NULL; }
    if (self->password)    { Safefree(self->password);    self->password = NULL; }
    if (self->database)    { Safefree(self->database);    self->database = NULL; }
    if (self->unix_socket) { Safefree(self->unix_socket); self->unix_socket = NULL; }
}

static void free_option_strings(ev_mariadb_t *self) {
    if (self->charset)     { Safefree(self->charset);     self->charset = NULL; }
    if (self->init_command) { Safefree(self->init_command); self->init_command = NULL; }
    if (self->ssl_key)     { Safefree(self->ssl_key);     self->ssl_key = NULL; }
    if (self->ssl_cert)    { Safefree(self->ssl_cert);    self->ssl_cert = NULL; }
    if (self->ssl_ca)      { Safefree(self->ssl_ca);      self->ssl_ca = NULL; }
    if (self->ssl_capath)  { Safefree(self->ssl_capath);  self->ssl_capath = NULL; }
    if (self->ssl_cipher)  { Safefree(self->ssl_cipher);  self->ssl_cipher = NULL; }
}

static void apply_options(ev_mariadb_t *self) {
    MYSQL *conn = self->conn;
    unsigned long flags = self->client_flags;

    if (self->connect_timeout > 0)
        mysql_options(conn, MYSQL_OPT_CONNECT_TIMEOUT, &self->connect_timeout);
    if (self->read_timeout > 0)
        mysql_options(conn, MYSQL_OPT_READ_TIMEOUT, &self->read_timeout);
    if (self->write_timeout > 0)
        mysql_options(conn, MYSQL_OPT_WRITE_TIMEOUT, &self->write_timeout);
    if (self->compress)
        mysql_options(conn, MYSQL_OPT_COMPRESS, NULL);
    if (self->charset)
        mysql_options(conn, MYSQL_SET_CHARSET_NAME, self->charset);
    if (self->init_command)
        mysql_options(conn, MYSQL_INIT_COMMAND, self->init_command);
    if (self->ssl_ca || self->ssl_capath || self->ssl_cert || self->ssl_key || self->ssl_cipher)
        mysql_ssl_set(conn, self->ssl_key, self->ssl_cert, self->ssl_ca, self->ssl_capath, self->ssl_cipher);
    if (self->ssl_verify_server_cert) {
        my_bool val = 1;
        mysql_options(conn, MYSQL_OPT_SSL_VERIFY_SERVER_CERT, &val);
    }
    if (self->multi_statements)
        flags |= CLIENT_MULTI_STATEMENTS | CLIENT_MULTI_RESULTS;
    if (self->found_rows)
        flags |= CLIENT_FOUND_ROWS;

    self->client_flags = flags;
}

static int is_utf8_charset(unsigned int charsetnr) {
    /* utf8mb3 collations: 33, 83, 192-211 */
    /* utf8mb4 collations: 45, 46, 224-247, 255, 256-309 */
    /* MariaDB 10.10+ uca1400: utf8mb3 2048-2303, utf8mb4 2304-2559 */
    /* (2560+ are ucs2/utf16/utf32 uca1400 — NOT UTF-8) */
    return charsetnr == 33 || charsetnr == 83
        || (charsetnr >= 192 && charsetnr <= 211)
        || charsetnr == 45 || charsetnr == 46
        || (charsetnr >= 224 && charsetnr <= 247)
        || charsetnr == 255
        || (charsetnr >= 256 && charsetnr <= 309)
        || (charsetnr >= 2048 && charsetnr <= 2559);
}

static int conn_charset_is_utf8(MYSQL *conn) {
    const char *cs;
    if (!conn) return 0;
    cs = mysql_character_set_name(conn);
    return (cs && strncmp(cs, "utf8", 4) == 0);
}

static AV* build_field_names(MYSQL *conn, MYSQL_FIELD *fields, unsigned int ncols) {
    AV *fnames = newAV();
    unsigned int i;
    int utf8_names = conn_charset_is_utf8(conn);
    if (ncols > 0) av_extend(fnames, ncols - 1);
    for (i = 0; i < ncols; i++) {
        SV *name = newSVpvn(fields[i].name, fields[i].name_length);
        if (utf8_names)
            SvUTF8_on(name);
        av_push(fnames, name);
    }
    return fnames;
}

static void setup_bind_params(ev_mariadb_stmt_t *ctx, AV *params) {
    int nparams = (int)(av_len(params) + 1);
    MYSQL_BIND *bp;
    int i;

    {
        unsigned long expected = mysql_stmt_param_count(ctx->stmt);
        if ((unsigned long)nparams != expected)
            croak("parameter count mismatch: got %d, expected %lu", nparams, expected);
    }

    if (nparams == 0) return;

    free_stmt_bind_params(ctx);

    Newxz(bp, nparams, MYSQL_BIND);
    ctx->bind_params = bp;
    ctx->bind_param_count = nparams;

    for (i = 0; i < nparams; i++) {
        SV **svp = av_fetch(params, i, 0);
        if (svp && SvOK(*svp)) {
            if (SvIOK(*svp)) {
                long long *val;
                Newx(val, 1, long long);
                if (SvIsUV(*svp)) {
                    *val = (long long)(unsigned long long)SvUV(*svp);
                    bp[i].is_unsigned = 1;
                } else {
                    *val = (long long)SvIV(*svp);
                    bp[i].is_unsigned = 0;
                }
                bp[i].buffer_type = MYSQL_TYPE_LONGLONG;
                bp[i].buffer = (void *)val;
            } else if (SvNOK(*svp)) {
                double *val;
                Newx(val, 1, double);
                *val = (double)SvNV(*svp);
                bp[i].buffer_type = MYSQL_TYPE_DOUBLE;
                bp[i].buffer = (void *)val;
            } else {
                STRLEN len;
                const char *s = SvPV(*svp, len);
                char *copy;
                Newx(copy, len + 1, char);
                Copy(s, copy, len, char);
                copy[len] = '\0';
                bp[i].buffer_type = MYSQL_TYPE_STRING;
                bp[i].buffer = (void *)copy;
                bp[i].buffer_length = (unsigned long)len;
                bp[i].length = &bp[i].buffer_length;
            }
        } else {
            bp[i].buffer_type = MYSQL_TYPE_NULL;
        }
    }

    if (mysql_stmt_bind_param(ctx->stmt, bp)) {
        char errbuf[512];
        COPY_ERROR(errbuf, mysql_stmt_error(ctx->stmt));
        free_stmt_bind_params(ctx);
        croak("%s", errbuf);
    }
}

static void start_connect(ev_mariadb_t *self) {
    int status;

    self->conn = mysql_init(NULL);
    if (NULL == self->conn) {
        croak("mysql_init failed");
    }

    self->connect_pid = getpid();
    mysql_options(self->conn, MYSQL_OPT_NONBLOCK, 0);
    apply_options(self);

    self->state = STATE_CONNECTING;
    status = mysql_real_connect_start(&self->op_conn_ret, self->conn,
        self->host, self->user, self->password, self->database,
        self->port, self->unix_socket, self->client_flags);

    if (status == 0) {
        on_connect_done(self);
    } else {
        self->fd = mysql_get_socket(self->conn);
        if (self->fd < 0) {
            mysql_close(self->conn);
            self->conn = NULL;
            self->state = STATE_IDLE;
            croak("mysql_get_socket returned invalid fd");
        }

        init_io_watchers(self);

        update_watchers(self, status);
    }
}

MODULE = EV::MariaDB  PACKAGE = EV::MariaDB

BOOT:
{
    I_EV_API("EV::MariaDB");
}

EV::MariaDB
_new(char *class, EV::Loop loop)
CODE:
{
    PERL_UNUSED_VAR(class);
    Newxz(RETVAL, 1, ev_mariadb_t);
    RETVAL->magic = EV_MARIADB_MAGIC;
    RETVAL->loop = loop;
    RETVAL->fd = -1;
    RETVAL->state = STATE_IDLE;
    ngx_queue_init(&RETVAL->cb_queue);
    ngx_queue_init(&RETVAL->send_queue);

    ev_init(&RETVAL->timer, timer_cb);
    RETVAL->timer.data = (void *)RETVAL;
}
OUTPUT:
    RETVAL

void
DESTROY(EV::MariaDB self)
CODE:
{
    if (self->magic != EV_MARIADB_MAGIC)
        return;

    self->magic = EV_MARIADB_FREED;

    stop_reading(self);
    stop_writing(self);
    stop_timer(self);

    if (PL_dirty) {
        /* global destruction — free C resources only; skip SvREFCNT_dec
           to avoid cascading destructors in torn-down interpreter */
        int is_fork = IS_FORKED(self);
        while (!ngx_queue_empty(&self->send_queue)) {
            ngx_queue_t *q = ngx_queue_head(&self->send_queue);
            ev_mariadb_send_t *s = ngx_queue_data(q, ev_mariadb_send_t, queue);
            ngx_queue_remove(q);
            Safefree(s->sql);
            Safefree(s);
        }
        while (!ngx_queue_empty(&self->cb_queue)) {
            ngx_queue_t *q = ngx_queue_head(&self->cb_queue);
            ev_mariadb_cb_t *cbt = ngx_queue_data(q, ev_mariadb_cb_t, queue);
            ngx_queue_remove(q);
            Safefree(cbt);
        }
        if (self->op_data_ptr) Safefree(self->op_data_ptr);
        self->stream_cb = NULL;
        {
            ev_mariadb_stmt_t *ctx = self->stmt_list;
            while (ctx) {
                ev_mariadb_stmt_t *next = ctx->next;
                free_stmt_bind_params(ctx);
                if (!is_fork && ctx->stmt) mysql_stmt_close(ctx->stmt);
                Safefree(ctx);
                ctx = next;
            }
        }
        if (!is_fork) {
            if (self->op_result) mysql_free_result(self->op_result);
            if (self->conn) mysql_close(self->conn);
        }
        free_connect_strings(self);
        free_option_strings(self);
        Safefree(self);
        return;
    }

    cancel_pending(self, "object destroyed");

    /* safety net: callbacks during cancel_pending could re-queue entries */
    drain_queues_silent(self);

    if (self->op_data_ptr) {
        Safefree(self->op_data_ptr);
        self->op_data_ptr = NULL;
    }

    /* Free all tracked stmt wrappers and connection resources */
    {
        int is_fork = IS_FORKED(self);
        ev_mariadb_stmt_t *ctx = self->stmt_list;
        while (ctx) {
            ev_mariadb_stmt_t *next = ctx->next;
            free_stmt_bind_params(ctx);
            if (!is_fork && ctx->stmt) mysql_stmt_close(ctx->stmt);
            Safefree(ctx);
            ctx = next;
        }
        self->stmt_list = NULL;
        /* Close op_stmt if not tracked in stmt_list (e.g., in-flight prepare) */
        if (!is_fork && self->op_stmt && !self->op_stmt_ctx) {
            mysql_stmt_close(self->op_stmt);
        }
        self->op_stmt = NULL;
        self->op_stmt_ctx = NULL;

        if (is_fork) {
            self->op_result = NULL;
            self->conn = NULL;
        } else {
            if (self->op_result) {
                mysql_free_result(self->op_result);
                self->op_result = NULL;
            }
            {
                MYSQL *conn = self->conn;
                self->conn = NULL;
                if (conn) mysql_close(conn);
            }
        }
        self->loop = NULL;
        self->fd = -1;
    }

    if (NULL != self->on_connect) {
        SvREFCNT_dec(self->on_connect);
        self->on_connect = NULL;
    }
    if (NULL != self->on_error) {
        SvREFCNT_dec(self->on_error);
        self->on_error = NULL;
    }
    free_connect_strings(self);
    free_option_strings(self);

    /* deferred free: check_destroyed will Safefree when depth hits 0 */
    if (self->callback_depth == 0)
        Safefree(self);
}

void
connect(EV::MariaDB self, const char *host, const char *user, const char *password, const char *database, unsigned int port = 3306, SV *unix_socket_sv = NULL)
CODE:
{
    if (NULL != self->conn) {
        croak(self->state == STATE_CONNECTING
              ? "connection already in progress"
              : "already connected");
    }

    free_connect_strings(self);

    self->host = safe_strdup(host);
    self->user = safe_strdup(user);
    self->password = safe_strdup(password);
    self->database = safe_strdup(database);
    self->port = port;
    self->unix_socket = NULL;

    if (unix_socket_sv && SvOK(unix_socket_sv)) {
        self->unix_socket = safe_strdup(SvPV_nolen(unix_socket_sv));
    }

    start_connect(self);
}

void
reset(EV::MariaDB self)
CODE:
{
    if (NULL == self->host) {
        croak("no previous connection to reset");
    }

    cleanup_connection(self);
    cancel_pending(self, "connection reset");
    if (check_destroyed(self)) return;
    if (self->state != STATE_IDLE) return;

    start_connect(self);
}

void
finish(EV::MariaDB self)
CODE:
{
    cleanup_connection(self);
    cancel_pending(self, "connection finished");
    if (check_destroyed(self)) return;
}

SV*
on_connect(EV::MariaDB self, SV *handler = NULL)
CODE:
{
    RETVAL = handler_accessor(&self->on_connect, handler, items > 1);
}
OUTPUT:
    RETVAL

SV*
on_error(EV::MariaDB self, SV *handler = NULL)
CODE:
{
    RETVAL = handler_accessor(&self->on_error, handler, items > 1);
}
OUTPUT:
    RETVAL

void
query(EV::MariaDB self, SV *sql_sv, SV *cb)
CODE:
{
    STRLEN sql_len;
    const char *sql;

    if (NULL == self->conn) {
        croak("not connected");
    }
    if (IS_FORKED(self)) {
        croak("connection not valid after fork");
    }
    if (self->state >= STATE_STMT_PREPARE) {
        croak("cannot queue query: exclusive operation in progress");
    }
    if (!(SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV)) {
        croak("callback must be a CODE reference");
    }

    sql = SvPV(sql_sv, sql_len);
    push_send(self, sql, sql_len, cb);

    if (self->state == STATE_IDLE && self->callback_depth == 0)
        pipeline_advance(self);
}

void
prepare(EV::MariaDB self, SV *sql_sv, SV *cb)
PREINIT:
    STRLEN sql_len;
    const char *sql;
CODE:
{
    int status;
    MYSQL_STMT *stmt;

    CHECK_READY(self, cb);

    stmt = mysql_stmt_init(self->conn);
    if (NULL == stmt) {
        croak("mysql_stmt_init failed");
    }
    {
        my_bool update_max = 1;
        mysql_stmt_attr_set(stmt, STMT_ATTR_UPDATE_MAX_LENGTH, &update_max);
    }

    sql = SvPV(sql_sv, sql_len);
    push_cb(self, cb);
    self->op_stmt = stmt;

    self->state = STATE_STMT_PREPARE;
    status = mysql_stmt_prepare_start(&self->op_ret, stmt, sql, (unsigned long)sql_len);
    if (status == 0) {
        on_stmt_prepare_done(self);
    } else {
        update_watchers(self, status);
    }
}

void
execute(EV::MariaDB self, IV stmt_iv, SV *params_ref, SV *cb)
PREINIT:
    ev_mariadb_stmt_t *ctx;
    int status;
CODE:
{
    CHECK_READY(self, cb);

    ctx = INT2PTR(ev_mariadb_stmt_t *, stmt_iv);
    CHECK_STMT(ctx);

    if (SvOK(params_ref)) {
        if (!SvROK(params_ref) || SvTYPE(SvRV(params_ref)) != SVt_PVAV)
            croak("params must be an ARRAY reference or undef");
        setup_bind_params(ctx, (AV *)SvRV(params_ref));
    }

    push_cb(self, cb);
    self->op_stmt = ctx->stmt;
    self->op_stmt_ctx = ctx;

    self->state = STATE_STMT_EXECUTE;
    status = mysql_stmt_execute_start(&self->op_ret, ctx->stmt);
    if (status == 0) {
        transition_to_stmt_store(self);
    } else {
        update_watchers(self, status);
    }
}

void
bind_params(EV::MariaDB self, IV stmt_iv, SV *params_ref)
PREINIT:
    ev_mariadb_stmt_t *ctx;
CODE:
{
    if (NULL == self->conn || self->state == STATE_CONNECTING)
        croak("not connected");
    if (IS_FORKED(self))
        croak("connection not valid after fork");
    if (self->state != STATE_IDLE)
        croak("another operation is in progress");
    if (!SvROK(params_ref) || SvTYPE(SvRV(params_ref)) != SVt_PVAV)
        croak("params must be an ARRAY reference");

    ctx = INT2PTR(ev_mariadb_stmt_t *, stmt_iv);
    CHECK_STMT(ctx);
    setup_bind_params(ctx, (AV *)SvRV(params_ref));
}

void
close_stmt(EV::MariaDB self, IV stmt_iv, SV *cb)
PREINIT:
    ev_mariadb_stmt_t *ctx;
    int status;
CODE:
{
    CHECK_READY(self, cb);

    ctx = INT2PTR(ev_mariadb_stmt_t *, stmt_iv);
    if (ctx->closed) {
        /* already closed by cleanup_connection — just free the wrapper */
        unlink_stmt(self, ctx);
        Safefree(ctx);
        push_cb(self, cb);
        if (deliver_value(self, newSViv(1))) return;
        maybe_pipeline(self);
        return;
    }
    free_stmt_bind_params(ctx);
    push_cb(self, cb);
    self->op_stmt = ctx->stmt;
    self->op_stmt_ctx = ctx;

    self->state = STATE_STMT_CLOSE;
    status = mysql_stmt_close_start(&self->op_bool_ret, ctx->stmt);
    if (status == 0) {
        on_stmt_close_done(self);
    } else {
        update_watchers(self, status);
    }
}

void
stmt_reset(EV::MariaDB self, IV stmt_iv, SV *cb)
PREINIT:
    ev_mariadb_stmt_t *ctx;
    int status;
CODE:
{
    CHECK_READY(self, cb);

    ctx = INT2PTR(ev_mariadb_stmt_t *, stmt_iv);
    CHECK_STMT(ctx);
    push_cb(self, cb);
    self->op_stmt = ctx->stmt;

    self->state = STATE_STMT_RESET;
    status = mysql_stmt_reset_start(&self->op_bool_ret, ctx->stmt);
    if (status == 0) {
        on_stmt_reset_done(self);
    } else {
        update_watchers(self, status);
    }
}

void
ping(EV::MariaDB self, SV *cb)
PREINIT:
    int status;
CODE:
{
    CHECK_READY(self, cb);

    push_cb(self, cb);

    self->state = STATE_PING;
    status = mysql_ping_start(&self->op_ret, self->conn);
    if (status == 0) {
        on_utility_done(self, self->op_ret != 0);
    } else {
        update_watchers(self, status);
    }
}

void
change_user(EV::MariaDB self, const char *user, const char *password, SV *db_sv, SV *cb)
PREINIT:
    int status;
    const char *db;
CODE:
{
    CHECK_READY(self, cb);

    db = (SvOK(db_sv)) ? SvPV_nolen(db_sv) : NULL;

    /* Update cached credentials so reset() reconnects with the new ones */
    if (self->user) Safefree(self->user);
    self->user = safe_strdup(user);
    if (self->password) Safefree(self->password);
    self->password = safe_strdup(password);
    if (db) {
        if (self->database) Safefree(self->database);
        self->database = safe_strdup(db);
    }
    /* if db is NULL (undef), keep self->database for reset() */

    push_cb(self, cb);

    self->state = STATE_CHANGE_USER;
    status = mysql_change_user_start(&self->op_bool_ret, self->conn, user, password, db);
    if (status == 0) {
        on_utility_done(self, self->op_bool_ret != 0);
    } else {
        update_watchers(self, status);
    }
}

void
select_db(EV::MariaDB self, const char *db, SV *cb)
PREINIT:
    int status;
CODE:
{
    CHECK_READY(self, cb);

    /* Update cached database so reset() reconnects to the right one */
    if (self->database) Safefree(self->database);
    self->database = safe_strdup(db);

    push_cb(self, cb);

    self->state = STATE_SELECT_DB;
    status = mysql_select_db_start(&self->op_ret, self->conn, db);
    if (status == 0) {
        on_utility_done(self, self->op_ret != 0);
    } else {
        update_watchers(self, status);
    }
}

void
reset_connection(EV::MariaDB self, SV *cb)
PREINIT:
    int status;
CODE:
{
    CHECK_READY(self, cb);

    push_cb(self, cb);

    self->state = STATE_RESET_CONNECTION;
    status = mysql_reset_connection_start(&self->op_ret, self->conn);
    if (status == 0) {
        on_utility_done(self, self->op_ret != 0);
    } else {
        update_watchers(self, status);
    }
}

void
set_charset(EV::MariaDB self, const char *charset, SV *cb)
PREINIT:
    int status;
CODE:
{
    CHECK_READY(self, cb);

    /* Update cached charset so reset() reconnects with the right one */
    if (self->charset) Safefree(self->charset);
    self->charset = safe_strdup(charset);

    push_cb(self, cb);

    self->state = STATE_SET_CHARSET;
    status = mysql_set_character_set_start(&self->op_ret, self->conn, charset);
    if (status == 0) {
        on_utility_done(self, self->op_ret != 0);
    } else {
        update_watchers(self, status);
    }
}

void
commit(EV::MariaDB self, SV *cb)
PREINIT:
    int status;
CODE:
{
    CHECK_READY(self, cb);

    push_cb(self, cb);

    self->state = STATE_COMMIT;
    status = mysql_commit_start(&self->op_bool_ret, self->conn);
    if (status == 0) {
        on_utility_done(self, self->op_bool_ret != 0);
    } else {
        update_watchers(self, status);
    }
}

void
rollback(EV::MariaDB self, SV *cb)
PREINIT:
    int status;
CODE:
{
    CHECK_READY(self, cb);

    push_cb(self, cb);

    self->state = STATE_ROLLBACK;
    status = mysql_rollback_start(&self->op_bool_ret, self->conn);
    if (status == 0) {
        on_utility_done(self, self->op_bool_ret != 0);
    } else {
        update_watchers(self, status);
    }
}

void
autocommit(EV::MariaDB self, int mode, SV *cb)
PREINIT:
    int status;
CODE:
{
    CHECK_READY(self, cb);

    push_cb(self, cb);

    self->state = STATE_AUTOCOMMIT;
    status = mysql_autocommit_start(&self->op_bool_ret, self->conn, (my_bool)(mode ? 1 : 0));
    if (status == 0) {
        on_utility_done(self, self->op_bool_ret != 0);
    } else {
        update_watchers(self, status);
    }
}

void
query_stream(EV::MariaDB self, SV *sql_sv, SV *cb)
PREINIT:
    STRLEN sql_len;
    const char *sql;
    int status;
CODE:
{
    CHECK_READY(self, cb);

    sql = SvPV(sql_sv, sql_len);
    self->stream_cb = SvREFCNT_inc(cb);
    self->pending_count++;

    self->state = STATE_REAL_QUERY;
    status = mysql_real_query_start(&self->op_ret, self->conn, sql, (unsigned long)sql_len);
    if (status == 0) {
        on_real_query_done(self);
    } else {
        update_watchers(self, status);
    }
}

void
close_async(EV::MariaDB self, SV *cb)
PREINIT:
    int status;
CODE:
{
    CHECK_READY(self, cb);

    push_cb(self, cb);

    self->state = STATE_CLOSE;
    status = mysql_close_start(self->conn);
    if (status == 0) {
        on_close_done(self);
    } else {
        update_watchers(self, status);
    }
}

void
send_long_data(EV::MariaDB self, IV stmt_iv, unsigned int param_idx, SV *data_sv, SV *cb)
PREINIT:
    ev_mariadb_stmt_t *ctx;
    STRLEN data_len;
    char *data;
    int status;
CODE:
{
    CHECK_READY(self, cb);

    ctx = INT2PTR(ev_mariadb_stmt_t *, stmt_iv);
    CHECK_STMT(ctx);
    {
        const char *src = SvPV(data_sv, data_len);
        Newx(data, data_len > 0 ? data_len : 1, char);
        Copy(src, data, data_len, char);
    }
    push_cb(self, cb);
    self->op_stmt = ctx->stmt;
    self->op_data_ptr = data;

    self->state = STATE_STMT_SEND_LONG_DATA;
    status = mysql_stmt_send_long_data_start(&self->op_bool_ret, ctx->stmt,
        param_idx, data, (unsigned long)data_len);
    if (status == 0) {
        on_send_long_data_done(self);
    } else {
        update_watchers(self, status);
    }
}

void
_set_option(EV::MariaDB self, const char *key, SV *value)
CODE:
{
    if (strcmp(key, "connect_timeout") == 0) {
        self->connect_timeout = SvUV(value);
    } else if (strcmp(key, "read_timeout") == 0) {
        self->read_timeout = SvUV(value);
    } else if (strcmp(key, "write_timeout") == 0) {
        self->write_timeout = SvUV(value);
    } else if (strcmp(key, "compress") == 0) {
        self->compress = SvTRUE(value) ? 1 : 0;
    } else if (strcmp(key, "multi_statements") == 0) {
        self->multi_statements = SvTRUE(value) ? 1 : 0;
    } else if (strcmp(key, "found_rows") == 0) {
        self->found_rows = SvTRUE(value) ? 1 : 0;
    } else if (strcmp(key, "charset") == 0) {
        SET_STR_OPTION(charset);
    } else if (strcmp(key, "init_command") == 0) {
        SET_STR_OPTION(init_command);
    } else if (strcmp(key, "ssl_key") == 0) {
        SET_STR_OPTION(ssl_key);
    } else if (strcmp(key, "ssl_cert") == 0) {
        SET_STR_OPTION(ssl_cert);
    } else if (strcmp(key, "ssl_ca") == 0) {
        SET_STR_OPTION(ssl_ca);
    } else if (strcmp(key, "ssl_capath") == 0) {
        SET_STR_OPTION(ssl_capath);
    } else if (strcmp(key, "ssl_cipher") == 0) {
        SET_STR_OPTION(ssl_cipher);
    } else if (strcmp(key, "ssl_verify_server_cert") == 0) {
        self->ssl_verify_server_cert = SvTRUE(value) ? 1 : 0;
    } else if (strcmp(key, "utf8") == 0) {
        self->utf8 = SvTRUE(value) ? 1 : 0;
    } else {
        croak("unknown option: %s", key);
    }
}

int
is_connected(EV::MariaDB self)
CODE:
{
    RETVAL = (NULL != self->conn && self->state != STATE_CONNECTING) ? 1 : 0;
}
OUTPUT:
    RETVAL

SV*
error_message(EV::MariaDB self)
CODE:
{
    if (NULL != self->conn) {
        const char *msg = mysql_error(self->conn);
        RETVAL = (msg && msg[0]) ? newSVpv(msg, 0) : &PL_sv_undef;
    }
    else {
        RETVAL = &PL_sv_undef;
    }
}
OUTPUT:
    RETVAL

unsigned int
error_number(EV::MariaDB self)
CODE:
{
    RETVAL = (NULL != self->conn) ? mysql_errno(self->conn) : 0;
}
OUTPUT:
    RETVAL

SV*
sqlstate(EV::MariaDB self)
CODE:
{
    if (NULL != self->conn) {
        const char *s = mysql_sqlstate(self->conn);
        RETVAL = (s && s[0]) ? newSVpv(s, 0) : &PL_sv_undef;
    }
    else {
        RETVAL = &PL_sv_undef;
    }
}
OUTPUT:
    RETVAL

SV*
insert_id(EV::MariaDB self)
CODE:
{
    if (NULL != self->conn) {
        my_ulonglong id = mysql_insert_id(self->conn);
        RETVAL = newSVuv((UV)id);
    }
    else {
        RETVAL = &PL_sv_undef;
    }
}
OUTPUT:
    RETVAL

unsigned int
warning_count(EV::MariaDB self)
CODE:
{
    RETVAL = (NULL != self->conn) ? mysql_warning_count(self->conn) : 0;
}
OUTPUT:
    RETVAL

SV*
info(EV::MariaDB self)
CODE:
{
    if (NULL != self->conn) {
        const char *i = mysql_info(self->conn);
        RETVAL = (i && i[0]) ? newSVpv(i, 0) : &PL_sv_undef;
    }
    else {
        RETVAL = &PL_sv_undef;
    }
}
OUTPUT:
    RETVAL

UV
server_version(EV::MariaDB self)
CODE:
{
    RETVAL = (NULL != self->conn) ? (UV)mysql_get_server_version(self->conn) : 0;
}
OUTPUT:
    RETVAL

SV*
server_info(EV::MariaDB self)
CODE:
{
    if (NULL != self->conn) {
        const char *info = mysql_get_server_info(self->conn);
        RETVAL = (info && info[0]) ? newSVpv(info, 0) : &PL_sv_undef;
    }
    else {
        RETVAL = &PL_sv_undef;
    }
}
OUTPUT:
    RETVAL

UV
thread_id(EV::MariaDB self)
CODE:
{
    RETVAL = (NULL != self->conn) ? (UV)mysql_thread_id(self->conn) : 0;
}
OUTPUT:
    RETVAL

SV*
host_info(EV::MariaDB self)
CODE:
{
    if (NULL != self->conn) {
        const char *info = mysql_get_host_info(self->conn);
        RETVAL = (info && info[0]) ? newSVpv(info, 0) : &PL_sv_undef;
    }
    else {
        RETVAL = &PL_sv_undef;
    }
}
OUTPUT:
    RETVAL

SV*
character_set_name(EV::MariaDB self)
CODE:
{
    if (NULL != self->conn) {
        const char *cs = mysql_character_set_name(self->conn);
        RETVAL = (cs && cs[0]) ? newSVpv(cs, 0) : &PL_sv_undef;
    }
    else {
        RETVAL = &PL_sv_undef;
    }
}
OUTPUT:
    RETVAL

int
socket(EV::MariaDB self)
CODE:
{
    RETVAL = (NULL != self->conn) ? (int)mysql_get_socket(self->conn) : -1;
}
OUTPUT:
    RETVAL

SV*
affected_rows(EV::MariaDB self)
CODE:
{
    if (NULL != self->conn) {
        my_ulonglong rows = mysql_affected_rows(self->conn);
        RETVAL = (rows == (my_ulonglong)-1) ? &PL_sv_undef : newSVuv((UV)rows);
    }
    else {
        RETVAL = &PL_sv_undef;
    }
}
OUTPUT:
    RETVAL

SV*
escape(EV::MariaDB self, SV *str)
PREINIT:
    STRLEN len;
    const char *s;
    unsigned long elen;
CODE:
{
    if (NULL == self->conn || self->state == STATE_CONNECTING
        || self->state == STATE_CLOSE
        || IS_FORKED(self)) {
        croak("not connected");
    }
    s = SvPV(str, len);
    if (SvUTF8(str)) {
        const char *cs = mysql_character_set_name(self->conn);
        if (!cs || (strncmp(cs, "utf8", 4) != 0)) {
            warn("EV::MariaDB: escaping a UTF-8 string on a non-utf8 connection (%s) may cause corruption or injection vulnerabilities", cs ? cs : "unknown");
        }
    }
    RETVAL = newSV(len * 2 + 1);
    SvPOK_on(RETVAL);
    elen = mysql_real_escape_string(self->conn, SvPVX(RETVAL), s, (unsigned long)len);
    if (elen == (unsigned long)-1) {
        SvREFCNT_dec(RETVAL);
        croak("mysql_real_escape_string failed");
    }
    SvCUR_set(RETVAL, elen);
    *SvEND(RETVAL) = '\0';
}
OUTPUT:
    RETVAL

int
pending_count(EV::MariaDB self)
CODE:
{
    RETVAL = self->pending_count;
}
OUTPUT:
    RETVAL

void
skip_pending(EV::MariaDB self)
CODE:
{
    if (self->state != STATE_IDLE || self->send_count > 0) {
        cleanup_connection(self);
    }
    cancel_pending(self, "skipped");
    if (check_destroyed(self)) return;
}

UV
lib_version(char *class)
CODE:
{
    PERL_UNUSED_VAR(class);
    RETVAL = (UV)mysql_get_client_version();
}
OUTPUT:
    RETVAL

SV*
lib_info(char *class)
CODE:
{
    PERL_UNUSED_VAR(class);
    RETVAL = newSVpv(mysql_get_client_info(), 0);
}
OUTPUT:
    RETVAL
