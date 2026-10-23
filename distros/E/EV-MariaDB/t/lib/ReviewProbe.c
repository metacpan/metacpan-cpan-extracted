#define VERSION "0"
#define XS_VERSION "0"
#include <sys/socket.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <mysql.h>

static int stmt_next_calls;
static int stmt_mode;
static int stmt_store_calls;
static int stmt_fetch_calls;
static MYSQL_BIND *stmt_bind;
static MYSQL_FIELD stmt_field;

static int probe_stmt_next_cont(int *ret, MYSQL_STMT *stmt, int events);

static int probe_stmt_next_start(int *ret, MYSQL_STMT *stmt) {
    stmt_next_calls++;
    if (stmt_mode == 4 || stmt_mode == 5)
        return probe_stmt_next_cont(ret, stmt, 0);
    return MYSQL_WAIT_TIMEOUT;
}

static int probe_stmt_next_cont(int *ret, MYSQL_STMT *stmt, int events) {
    (void)events;
    *ret = stmt_mode == 1;
    stmt->mysql->server_status = stmt_mode >= 2 && stmt_next_calls == 1
        ? SERVER_MORE_RESULTS_EXIST : 0;
    stmt->field_count = stmt_mode >= 2 && stmt_next_calls == 1 ? 1 : 0;
    if (*ret) {
        stmt->last_errno = 123;
        strcpy(stmt->last_error, "secondary result failed");
    }
    return 0;
}

static int probe_stmt_store_cont(int *ret, MYSQL_STMT *stmt, int events) {
    (void)events;
    *ret = stmt_mode == 3;
    if (*ret) {
        stmt->last_errno = 123;
        strcpy(stmt->last_error, "secondary store failed");
    }
    return 0;
}

static int probe_stmt_store_start(int *ret, MYSQL_STMT *stmt) {
    stmt_store_calls++;
    if (stmt_mode == 4 || stmt_mode == 6)
        return probe_stmt_store_cont(ret, stmt, 0);
    return MYSQL_WAIT_TIMEOUT;
}

static my_bool probe_stmt_bind_result(MYSQL_STMT *stmt, MYSQL_BIND *bind) {
    (void)stmt;
    stmt_bind = bind;
    return 0;
}

static int probe_stmt_fetch(MYSQL_STMT *stmt) {
    (void)stmt;
    if (stmt_fetch_calls++) return MYSQL_NO_DATA;
    memcpy(stmt_bind[0].buffer, "first", 5);
    *stmt_bind[0].length = 5;
    *stmt_bind[0].is_null = 0;
    return 0;
}

static my_bool probe_stmt_free_result(MYSQL_STMT *stmt) {
    (void)stmt;
    return 0;
}

static int shutdown_calls;
static int socket_override = -1;
static my_socket probe_get_socket(MYSQL *conn) {
    return socket_override >= 0 ? (my_socket)socket_override : mysql_get_socket(conn);
}
static int probe_shutdown(int fd, int how) {
    (void)fd;
    (void)how;
    shutdown_calls++;
    return 0;
}

#define shutdown probe_shutdown
#define mysql_get_socket probe_get_socket
#define mysql_stmt_next_result_start probe_stmt_next_start
#define mysql_stmt_next_result_cont probe_stmt_next_cont
#define mysql_stmt_store_result_start probe_stmt_store_start
#define mysql_stmt_store_result_cont probe_stmt_store_cont
#define mysql_stmt_bind_result probe_stmt_bind_result
#define mysql_stmt_fetch probe_stmt_fetch
#define mysql_stmt_free_result probe_stmt_free_result
#include "MariaDB.c"

static XS(probe_retired_connection) {
    dXSARGS;
    ev_mariadb_t *self = INT2PTR(ev_mariadb_t *, SvIV(SvRV(ST(0))));
    if (!self->conn) self->conn = mysql_init(NULL);
    if (!self->conn) croak("mysql_init failed");
    self->fd = 123;
    shutdown_calls = 0;
    XSRETURN_EMPTY;
}

static XS(probe_cleanup) {
    dXSARGS;
    ev_mariadb_t *self = INT2PTR(ev_mariadb_t *, SvIV(SvRV(ST(0))));
    cleanup_connection(self);
    socket_override = -1;
    ST(0) = sv_2mortal(newSViv(shutdown_calls));
    XSRETURN(1);
}

static XS(probe_socket_state) {
    dXSARGS;
    ev_mariadb_t *self = INT2PTR(ev_mariadb_t *, SvIV(SvRV(ST(0))));
    self->conn = mysql_init(NULL);
    if (!self->conn) croak("mysql_init failed");
    self->state = SvTRUE(ST(1)) ? STATE_CONNECTING : STATE_IDLE;
    socket_override = 123;
    shutdown_calls = 0;
    XSRETURN_EMPTY;
}

static XS(probe_mark_sent) {
    dXSARGS;
    ev_mariadb_t *self = INT2PTR(ev_mariadb_t *, SvIV(SvRV(ST(0))));
    ngx_queue_t *q = ngx_queue_head(&self->send_queue);
    ev_mariadb_send_t *send = ngx_queue_data(q, ev_mariadb_send_t, queue);
    ev_mariadb_cb_t *cbt;
    Newx(cbt, 1, ev_mariadb_cb_t);
    cbt->cb = send->cb;
    ngx_queue_remove(q);
    ngx_queue_insert_tail(&self->cb_queue, &cbt->queue);
    Safefree(send->sql);
    Safefree(send);
    self->send_count++;
    XSRETURN_EMPTY;
}

static XS(probe_execute_with_extra) {
    dXSARGS;
    ev_mariadb_t *self = INT2PTR(ev_mariadb_t *, SvIV(SvRV(ST(0))));
    ev_mariadb_stmt_t *ctx;
    if (!self->conn) self->conn = mysql_init(NULL);
    if (!self->conn) croak("mysql_init failed");
    mysql_options(self->conn, MYSQL_OPT_NONBLOCK, 0);
    Newxz(ctx, 1, ev_mariadb_stmt_t);
    ctx->stmt = mysql_stmt_init(self->conn);
    if (!ctx->stmt) croak("mysql_stmt_init failed");
    ctx->id = ++self->next_stmt_id;
    ctx->next = self->stmt_list;
    self->stmt_list = ctx;
    ctx->stmt->state = MYSQL_STMT_EXECUTED;
    ctx->stmt->upsert_status.affected_rows = 42;
    stmt_mode = (int)SvIV(ST(2));
    if (stmt_mode >= 2) {
        Zero(&stmt_field, 1, MYSQL_FIELD);
        stmt_field.name = "value";
        stmt_field.name_length = 5;
        stmt_field.max_length = 5;
        stmt_field.charsetnr = 8;
        stmt_field.type = MYSQL_TYPE_VAR_STRING;
        ctx->stmt->fields = &stmt_field;
        ctx->stmt->field_count = 1;
    }
    self->conn->server_status = stmt_mode == -1 ? 0 : SERVER_MORE_RESULTS_EXIST;
    self->op_stmt = ctx->stmt;
    self->op_stmt_ctx = ctx;
    self->op_ret = 0;
    stmt_next_calls = 0;
    stmt_store_calls = 0;
    stmt_fetch_calls = 0;
    push_cb(self, ST(1));
    on_stmt_execute_done(self);
    XSRETURN_EMPTY;
}

static XS(probe_send_failure) {
    dXSARGS;
    ev_mariadb_t *self = INT2PTR(ev_mariadb_t *, SvIV(SvRV(ST(0))));
    ngx_queue_t *q = ngx_queue_head(&self->send_queue);
    ev_mariadb_send_t *send = ngx_queue_data(q, ev_mariadb_send_t, queue);
    ngx_queue_remove(q);
    handle_send_failure(self, send);
    XSRETURN_EMPTY;
}

static XS(probe_resume_stmt) {
    dXSARGS;
    ev_mariadb_t *self = INT2PTR(ev_mariadb_t *, SvIV(SvRV(ST(0))));
    if (self->pending_count) continue_operation(self, MYSQL_WAIT_TIMEOUT);
    ST(0) = sv_2mortal(newSViv(stmt_next_calls));
    XSRETURN(1);
}

static XS(probe_store_calls) {
    dXSARGS;
    ST(0) = sv_2mortal(newSViv(stmt_store_calls));
    XSRETURN(1);
}

EXTERN_C XS(boot_ReviewProbe) {
    dXSARGS;
    I_EV_API("ReviewProbe");
    newXS("ReviewProbe::retired_connection", probe_retired_connection, __FILE__);
    newXS("ReviewProbe::cleanup", probe_cleanup, __FILE__);
    newXS("ReviewProbe::socket_state", probe_socket_state, __FILE__);
    newXS("ReviewProbe::mark_sent", probe_mark_sent, __FILE__);
    newXS("ReviewProbe::execute_with_extra", probe_execute_with_extra, __FILE__);
    newXS("ReviewProbe::resume_stmt", probe_resume_stmt, __FILE__);
    newXS("ReviewProbe::store_calls", probe_store_calls, __FILE__);
    newXS("ReviewProbe::send_failure", probe_send_failure, __FILE__);
    call_atexit(drain_freelists, NULL);
    XSRETURN_YES;
}
