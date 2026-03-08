#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "EVAPI.h"
#include <libpq-fe.h>
#include <limits.h>
#include <errno.h>

#include "ngx_queue.h"

typedef struct ev_pg_s ev_pg_t;
typedef struct ev_pg_cb_s ev_pg_cb_t;

typedef ev_pg_t* EV__Pg;
typedef struct ev_loop* EV__Loop;

#define EV_PG_MAGIC 0xDEADBEEF
#define EV_PG_FREED 0xFEEDFACE

struct ev_pg_s {
    unsigned int magic;
    struct ev_loop *loop;
    PGconn *conn;

    ev_io    rio, wio;
    int      reading, writing;
    int      rio_unref;
    int      fd;

    int      connecting;
    char    *conninfo;

    ngx_queue_t cb_queue;
    int         pending_count;
    int         copy_mode;
    int         draining_single_row;
    PGresult   *pending_result;
    ev_pg_cb_t *delivering_cbt;

    SV *on_connect;
    SV *on_error;
    SV *on_notify;
    SV *on_notice;
    SV *on_drain;

    int callback_depth;

    HV    *last_error_fields;
    HV    *last_result_meta;
    FILE  *trace_fp;

#ifdef LIBPQ_HAS_ASYNC_CANCEL
    PGcancelConn *cancel_conn;
    ev_io  cancel_rio, cancel_wio;
    int    cancel_reading, cancel_writing;
    int    cancel_fd;
    SV    *cancel_cb;
#endif
};

struct ev_pg_cb_s {
    SV          *cb;
    ngx_queue_t  queue;
    int          is_pipeline_sync;
    int          is_describe;
};

static void connect_poll_cb(EV_P_ ev_io *w, int revents);
static void io_read_cb(EV_P_ ev_io *w, int revents);
static void io_write_cb(EV_P_ ev_io *w, int revents);
static void start_reading(ev_pg_t *self);
static void stop_reading(ev_pg_t *self);
static void start_writing(ev_pg_t *self);
static void stop_writing(ev_pg_t *self);
static void drain_notifies(ev_pg_t *self);
static int  deliver_result(ev_pg_t *self, PGresult *res);
static void process_results(ev_pg_t *self);
static void check_flush(ev_pg_t *self);
static void emit_error(ev_pg_t *self, const char *msg);
static void cleanup_connection(ev_pg_t *self);
static HV*  build_error_fields(PGresult *res);
static HV*  build_result_meta(PGresult *res);
static void cancel_pending(ev_pg_t *self, const char *errmsg);
static int  check_destroyed(ev_pg_t *self);
static int  handle_conn_loss(ev_pg_t *self);

#define REQUIRE_CONN(self) \
    if (NULL == (self)->conn || (self)->connecting) croak("not connected")

#define REQUIRE_CB(cb) \
    if (!(SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV)) \
        croak("callback must be a CODE reference")

#define CALL_SV_GUARDED(sv, label) \
    STMT_START { \
        SV *_guarded_sv = SvREFCNT_inc_simple_NN(sv); \
        sv_setpvs(ERRSV, ""); \
        call_sv(_guarded_sv, G_DISCARD | G_EVAL); \
        if (SvTRUE(ERRSV)) \
            warn("EV::Pg: exception in " label ": %s", SvPV_nolen(ERRSV)); \
        SvREFCNT_dec(_guarded_sv); \
    } STMT_END

#define RELEASE_HANDLER(slot) \
    STMT_START { if (NULL != (slot)) { SvREFCNT_dec(slot); (slot) = NULL; } } STMT_END

#define STORE_LAST_HV(slot, val) \
    STMT_START { \
        if ((slot)) SvREFCNT_dec((SV*)(slot)); \
        (slot) = (val); \
    } STMT_END

#define RELEASE_LAST_HV(slot) \
    STMT_START { \
        if ((slot)) { SvREFCNT_dec((SV*)(slot)); (slot) = NULL; } \
    } STMT_END

static ev_pg_cb_t *cbt_freelist = NULL;

/* Freelist: reuses first pointer-sized bytes as the next-link */
static ev_pg_cb_t* alloc_cbt(void) {
    ev_pg_cb_t *cbt;
    if (cbt_freelist) {
        cbt = cbt_freelist;
        cbt_freelist = *(ev_pg_cb_t **)cbt;
    } else {
        Newx(cbt, 1, ev_pg_cb_t);
    }
    return cbt;
}

static void release_cbt(ev_pg_cb_t *cbt) {
    *(ev_pg_cb_t **)cbt = cbt_freelist;
    cbt_freelist = cbt;
}

static void start_reading(ev_pg_t *self) {
    if (!self->reading && self->fd >= 0) {
        ev_io_start(self->loop, &self->rio);
        self->reading = 1;
    }
}

static void stop_reading(ev_pg_t *self) {
    if (self->reading) {
        if (self->rio_unref) {
            ev_ref(self->loop);
            self->rio_unref = 0;
        }
        ev_io_stop(self->loop, &self->rio);
        self->reading = 0;
    }
}

/* Call after pending_count changes or connection completes.
 * Keeps the read watcher unref'd when idle (no pending queries,
 * not connecting) so EV::run can exit. */
static void update_idle_ref(ev_pg_t *self) {
    int want_unref;
    if (NULL == self->loop) return;
    want_unref = self->reading && !self->connecting
                 && self->pending_count == 0 && !self->copy_mode
                 && !self->draining_single_row;
    if (want_unref && !self->rio_unref) {
        ev_unref(self->loop);
        self->rio_unref = 1;
    }
    else if (!want_unref && self->rio_unref) {
        ev_ref(self->loop);
        self->rio_unref = 0;
    }
}

static void start_writing(ev_pg_t *self) {
    if (!self->writing && self->fd >= 0) {
        ev_io_start(self->loop, &self->wio);
        self->writing = 1;
    }
}

static void stop_writing(ev_pg_t *self) {
    if (self->writing) {
        ev_io_stop(self->loop, &self->wio);
        self->writing = 0;
    }
}

#ifdef LIBPQ_HAS_ASYNC_CANCEL

static void cancel_poll_cb(EV_P_ ev_io *w, int revents);

static void start_cancel_reading(ev_pg_t *self) {
    if (!self->cancel_reading && self->cancel_fd >= 0) {
        ev_io_start(self->loop, &self->cancel_rio);
        self->cancel_reading = 1;
    }
}

static void stop_cancel_reading(ev_pg_t *self) {
    if (self->cancel_reading) {
        ev_io_stop(self->loop, &self->cancel_rio);
        self->cancel_reading = 0;
    }
}

static void start_cancel_writing(ev_pg_t *self) {
    if (!self->cancel_writing && self->cancel_fd >= 0) {
        ev_io_start(self->loop, &self->cancel_wio);
        self->cancel_writing = 1;
    }
}

static void stop_cancel_writing(ev_pg_t *self) {
    if (self->cancel_writing) {
        ev_io_stop(self->loop, &self->cancel_wio);
        self->cancel_writing = 0;
    }
}

static void cleanup_cancel(ev_pg_t *self) {
    stop_cancel_reading(self);
    stop_cancel_writing(self);
    self->cancel_fd = -1;
    if (self->cancel_conn) {
        PQcancelFinish(self->cancel_conn);
        self->cancel_conn = NULL;
    }
    RELEASE_HANDLER(self->cancel_cb);
}

static void cancel_poll_cb(EV_P_ ev_io *w, int revents) {
    ev_pg_t *self = (ev_pg_t *)w->data;
    PostgresPollingStatusType st;
    (void)loop;
    (void)revents;

    if (self == NULL || self->magic != EV_PG_MAGIC) return;
    if (!self->cancel_conn) return;

    self->callback_depth++;

    st = PQcancelPoll(self->cancel_conn);

    switch (st) {
    case PGRES_POLLING_READING:
        start_cancel_reading(self);
        stop_cancel_writing(self);
        break;

    case PGRES_POLLING_WRITING:
        stop_cancel_reading(self);
        start_cancel_writing(self);
        break;

    case PGRES_POLLING_OK: {
        SV *cb = self->cancel_cb;
        self->cancel_cb = NULL;  /* prevent cleanup_cancel from decref */
        cleanup_cancel(self);

        if (cb) {
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            /* success: no args (Perl sees ($err) = @_ → $err = undef) */
            PUTBACK;
            CALL_SV_GUARDED(cb, "cancel_async callback");
            FREETMPS;
            LEAVE;
            SvREFCNT_dec(cb);
        }
        break;
    }

    case PGRES_POLLING_FAILED: {
        const char *err = PQcancelErrorMessage(self->cancel_conn);
        SV *errsv = newSVpv(err ? err : "cancel failed", 0);
        SV *cb = self->cancel_cb;
        self->cancel_cb = NULL;
        cleanup_cancel(self);

        if (cb) {
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(sv_2mortal(errsv));
            PUTBACK;
            CALL_SV_GUARDED(cb, "cancel_async callback");
            FREETMPS;
            LEAVE;
            SvREFCNT_dec(cb);
        } else {
            SvREFCNT_dec(errsv);
        }
        break;
    }

    default:
        break;
    }

    self->callback_depth--;
    check_destroyed(self);
}

#define CLEANUP_CANCEL(self) cleanup_cancel(self)
#else
#define CLEANUP_CANCEL(self) ((void)0)
#endif /* LIBPQ_HAS_ASYNC_CANCEL */

static int check_destroyed(ev_pg_t *self) {
    if (self->magic == EV_PG_FREED &&
        self->callback_depth == 0) {
        Safefree(self);
        return 1;
    }
    return 0;
}

static void emit_error(ev_pg_t *self, const char *msg) {
    if (NULL == self->on_error) return;

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(msg, 0)));
    PUTBACK;

    CALL_SV_GUARDED(self->on_error, "error handler");

    FREETMPS;
    LEAVE;
}

/* Takes ownership of res.  Returns 1 if the cbt was already
 * removed from the queue (e.g. cancel_pending ran inside callback). */
static int deliver_result(ev_pg_t *self, PGresult *res) {
    ngx_queue_t *q;
    ev_pg_cb_t *cbt;
    ExecStatusType st;

    if (ngx_queue_empty(&self->cb_queue)) {
        PQclear(res);
        return 0;
    }

    q = ngx_queue_head(&self->cb_queue);
    cbt = ngx_queue_data(q, ev_pg_cb_t, queue);

    st = PQresultStatus(res);

    self->callback_depth++;
    self->delivering_cbt = cbt;

    {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, 2);

        if (st == PGRES_FATAL_ERROR || st == PGRES_PIPELINE_ABORTED ||
            st == PGRES_BAD_RESPONSE || st == PGRES_EMPTY_QUERY) {
            const char *errmsg = PQresultErrorMessage(res);
            const char *msg = (errmsg && errmsg[0])
                ? errmsg
                : st == PGRES_PIPELINE_ABORTED ? "pipeline aborted"
                : st == PGRES_BAD_RESPONSE     ? "bad server response"
                : st == PGRES_EMPTY_QUERY      ? "empty query"
                : "unknown error";
            if (st == PGRES_FATAL_ERROR)
                STORE_LAST_HV(self->last_error_fields,
                              build_error_fields(res));
            PUSHs(&PL_sv_undef);
            PUSHs(sv_2mortal(newSVpv(msg, 0)));
        }
        else if (st == PGRES_PIPELINE_SYNC) {
            PUSHs(sv_2mortal(newSViv(1)));
        }
        else if (st == PGRES_COPY_IN || st == PGRES_COPY_OUT || st == PGRES_COPY_BOTH) {
            const char *tag = (st == PGRES_COPY_IN) ? "COPY_IN"
                            : (st == PGRES_COPY_OUT) ? "COPY_OUT"
                            : "COPY_BOTH";
            PUSHs(sv_2mortal(newSVpv(tag, 0)));
        }
        else if (cbt->is_describe) {
            HV *meta = newHV();
            int nf = PQnfields(res);
            int np = PQnparams(res);
            int i;

            (void)hv_store(meta, "nfields", 7, newSViv(nf), 0);
            (void)hv_store(meta, "nparams", 7, newSViv(np), 0);

            if (nf > 0) {
                AV *fields = newAV();
                av_extend(fields, nf - 1);
                for (i = 0; i < nf; i++) {
                    HV *fld = newHV();
                    (void)hv_store(fld, "name", 4, newSVpv(PQfname(res, i), 0), 0);
                    (void)hv_store(fld, "type", 4, newSVuv(PQftype(res, i)), 0);
                    av_push(fields, newRV_noinc((SV*)fld));
                }
                (void)hv_store(meta, "fields", 6, newRV_noinc((SV*)fields), 0);
            }

            if (np > 0) {
                AV *ptypes = newAV();
                av_extend(ptypes, np - 1);
                for (i = 0; i < np; i++) {
                    av_push(ptypes, newSVuv(PQparamtype(res, i)));
                }
                (void)hv_store(meta, "paramtypes", 10, newRV_noinc((SV*)ptypes), 0);
            }

            PUSHs(sv_2mortal(newRV_noinc((SV*)meta)));
        }
        else if (st == PGRES_TUPLES_OK || st == PGRES_SINGLE_TUPLE
#ifdef LIBPQ_HAS_CHUNK_MODE
                 || st == PGRES_TUPLES_CHUNK
#endif
                ) {
            int nrows = PQntuples(res);
            int ncols = PQnfields(res);
            AV *rows = newAV();
            int r, c;
            /* Metadata is identical for every row in streaming mode;
             * only rebuild on TUPLES_OK or first delivery */
            if (st == PGRES_TUPLES_OK || !self->last_result_meta)
                STORE_LAST_HV(self->last_result_meta,
                              build_result_meta(res));
            if (nrows > 0) av_extend(rows, nrows - 1);
            for (r = 0; r < nrows; r++) {
                AV *row = newAV();
                if (ncols > 0) av_extend(row, ncols - 1);
                for (c = 0; c < ncols; c++) {
                    if (PQgetisnull(res, r, c)) {
                        av_push(row, newSV(0));
                    } else {
                        av_push(row, newSVpvn(PQgetvalue(res, r, c),
                                              PQgetlength(res, r, c)));
                    }
                }
                av_push(rows, newRV_noinc((SV*)row));
            }
            PUSHs(sv_2mortal(newRV_noinc((SV*)rows)));
        }
        else {
            /* COMMAND_OK — pass cmd_tuples string */
            const char *ct = PQcmdTuples(res);
            STORE_LAST_HV(self->last_result_meta, build_result_meta(res));
            PUSHs(sv_2mortal(newSVpv(ct ? ct : "", 0)));
        }

        PUTBACK;
        CALL_SV_GUARDED(cbt->cb, "callback");
        FREETMPS;
        LEAVE;
    }

    PQclear(res);
    {
        int consumed = (self->delivering_cbt == NULL);
        self->delivering_cbt = NULL;
        self->callback_depth--;
        return consumed;
    }
}

static void advance_cb_queue(ev_pg_t *self) {
    ngx_queue_t *q;
    ev_pg_cb_t *cbt;

    if (ngx_queue_empty(&self->cb_queue)) return;

    q = ngx_queue_head(&self->cb_queue);
    cbt = ngx_queue_data(q, ev_pg_cb_t, queue);

    ngx_queue_remove(q);
    self->pending_count--;
    SvREFCNT_dec(cbt->cb);
    release_cbt(cbt);
    update_idle_ref(self);
}

static void drain_notifies(ev_pg_t *self) {
    PGnotify *notify;

    if (NULL == self->on_notify) return;

    while (self->conn && self->on_notify &&
           (notify = PQnotifies(self->conn)) != NULL) {
        self->callback_depth++;

        {
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(sv_2mortal(newSVpv(notify->relname, 0)));
            XPUSHs(sv_2mortal(newSVpv(notify->extra, 0)));
            XPUSHs(sv_2mortal(newSViv(notify->be_pid)));
            PUTBACK;

            CALL_SV_GUARDED(self->on_notify, "notify handler");

            FREETMPS;
            LEAVE;
        }

        PQfreemem(notify);

        self->callback_depth--;
        if (self->magic != EV_PG_MAGIC) return;
    }
}

static void process_results(ev_pg_t *self) {
    PGresult *res;
    PGresult *last_res = self->pending_result;
    self->pending_result = NULL;

    while (self->conn && !PQisBusy(self->conn)) {
        res = PQgetResult(self->conn);

        /* Discard residual single-row results after stream abort */
        if (self->draining_single_row) {
            if (NULL == res) {
                self->draining_single_row = 0;
                update_idle_ref(self);
            } else {
                PQclear(res);
            }
            continue;
        }

        if (NULL == res) {
            /* Deliver AFTER consuming NULL so conn is ready for new queries in callback */
            if (last_res != NULL) {
                int consumed;
                self->copy_mode = 0;
                consumed = deliver_result(self, last_res);
                last_res = NULL;
                if (self->magic != EV_PG_MAGIC) return;

                if (!consumed && !ngx_queue_empty(&self->cb_queue)) {
                    ngx_queue_t *q = ngx_queue_head(&self->cb_queue);
                    ev_pg_cb_t *cbt = ngx_queue_data(q, ev_pg_cb_t, queue);
                    if (!cbt->is_pipeline_sync) {
                        advance_cb_queue(self);
                    } else {
                        update_idle_ref(self);
                    }
                } else {
                    update_idle_ref(self);
                }
            }

            if (self->copy_mode) break;

            if (ngx_queue_empty(&self->cb_queue)) break;
            continue;
        }

        {
            ExecStatusType st = PQresultStatus(res);
            if (st == PGRES_PIPELINE_SYNC) {
                int consumed = deliver_result(self, res);
                if (self->magic != EV_PG_MAGIC) {
                    if (last_res) PQclear(last_res);
                    return;
                }
                if (!consumed) advance_cb_queue(self);
                continue;
            }
            if (st == PGRES_COPY_IN || st == PGRES_COPY_OUT || st == PGRES_COPY_BOTH) {
                self->copy_mode = 1;
                {
                    int consumed = deliver_result(self, res);
                    if (self->magic != EV_PG_MAGIC) {
                        if (last_res) PQclear(last_res);
                        return;
                    }
                    if (consumed) {
                        self->copy_mode = 0;
                        update_idle_ref(self);
                    }
                }
                if (last_res) { PQclear(last_res); last_res = NULL; }
                break;
            }
            if (st == PGRES_SINGLE_TUPLE
#ifdef LIBPQ_HAS_CHUNK_MODE
                || st == PGRES_TUPLES_CHUNK
#endif
               ) {
                PGconn *orig_conn = self->conn;
                int consumed = deliver_result(self, res);
                if (self->magic != EV_PG_MAGIC) {
                    if (last_res) PQclear(last_res);
                    return;
                }
                if (consumed) {
                    /* Stream aborted (skip_pending/finish/reset from callback).
                     * Drain remaining results without delivering.
                     * Only drain if conn hasn't been replaced by reset. */
                    int drained = 0;
                    while (self->conn == orig_conn && !PQisBusy(self->conn)) {
                        PGresult *drain = PQgetResult(self->conn);
                        if (NULL == drain) { drained = 1; break; }
                        PQclear(drain);
                    }
                    if (!drained && self->conn == orig_conn) {
                        /* PQisBusy interrupted drain; residual results
                         * remain in libpq buffer — flag for later. */
                        self->draining_single_row = 1;
                    }
                    if (last_res != NULL) {
                        PQclear(last_res);
                        last_res = NULL;
                    }
                    break;
                }
                continue;
            }
            /* Trailing semicolons produce PGRES_EMPTY_QUERY — skip if we
             * already have a meaningful result (e.g. "SELECT 1;") */
            if (st == PGRES_EMPTY_QUERY && last_res != NULL) {
                PQclear(res);
                continue;
            }
        }

        if (last_res != NULL) {
            PQclear(last_res);
        }
        last_res = res;
    }

    if (last_res != NULL && NULL == self->conn) {
        PQclear(last_res);
        last_res = NULL;
    }
    self->pending_result = last_res;
}

/* emit error, tear down connection, cancel queued callbacks.
 * Manages its own callback_depth.  Returns 1 if self was freed. */
static int handle_conn_loss(ev_pg_t *self) {
    PGconn *old_conn = self->conn;
    self->callback_depth++;
    emit_error(self, PQerrorMessage(self->conn));
    self->callback_depth--;
    if (check_destroyed(self)) return 1;
    /* If on_error called reset/finish, conn has already changed */
    if (self->conn == old_conn) {
        cleanup_connection(self);
        cancel_pending(self, "connection lost");
    }
    return check_destroyed(self);
}

static void check_flush(ev_pg_t *self) {
    int ret = PQflush(self->conn);
    if (ret == 1) {
        start_writing(self);
    }
    else if (ret == -1) {
        handle_conn_loss(self);
    }
    else {
        stop_writing(self);
    }
}

static void io_read_cb(EV_P_ ev_io *w, int revents) {
    ev_pg_t *self = (ev_pg_t *)w->data;
    (void)loop;
    (void)revents;

    if (self == NULL || self->magic != EV_PG_MAGIC) return;
    if (self->conn == NULL) return;

    self->callback_depth++;

    if (!PQconsumeInput(self->conn)) {
        self->callback_depth--;
        handle_conn_loss(self);
        return;
    }

    drain_notifies(self);
    if (self->magic != EV_PG_MAGIC) {
        self->callback_depth--;
        check_destroyed(self);
        return;
    }

    process_results(self);
    if (self->magic != EV_PG_MAGIC) {
        self->callback_depth--;
        check_destroyed(self);
        return;
    }

    if (self->conn && !self->connecting) check_flush(self);
    if (self->magic != EV_PG_MAGIC) {
        self->callback_depth--;
        check_destroyed(self);
        return;
    }

    self->callback_depth--;
    check_destroyed(self);
}

static void io_write_cb(EV_P_ ev_io *w, int revents) {
    ev_pg_t *self = (ev_pg_t *)w->data;
    int ret;
    (void)loop;
    (void)revents;

    if (self == NULL || self->magic != EV_PG_MAGIC) return;
    if (self->conn == NULL) return;

    self->callback_depth++;

    ret = PQflush(self->conn);
    if (ret == 0) {
        stop_writing(self);
        if (self->copy_mode && self->on_drain != NULL) {
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            PUTBACK;
            CALL_SV_GUARDED(self->on_drain, "drain handler");
            FREETMPS;
            LEAVE;
            if (self->magic != EV_PG_MAGIC) {
                self->callback_depth--;
                check_destroyed(self);
                return;
            }
        }
    }
    else if (ret == -1) {
        self->callback_depth--;
        handle_conn_loss(self);
        return;
    }

    self->callback_depth--;
    check_destroyed(self);
}

static void reinit_io_watchers(ev_pg_t *self) {
    stop_reading(self);
    stop_writing(self);

    self->fd = PQsocket(self->conn);
    if (self->fd < 0) return;

    ev_io_init(&self->rio, io_read_cb, self->fd, EV_READ);
    self->rio.data = (void *)self;
    ev_io_init(&self->wio, io_write_cb, self->fd, EV_WRITE);
    self->wio.data = (void *)self;

    start_reading(self);
    update_idle_ref(self);
    check_flush(self);
}

static void connect_poll_cb(EV_P_ ev_io *w, int revents) {
    ev_pg_t *self = (ev_pg_t *)w->data;
    PostgresPollingStatusType poll_status;
    (void)loop;
    (void)revents;

    if (self == NULL || self->magic != EV_PG_MAGIC) return;

    self->callback_depth++;

    poll_status = PQconnectPoll(self->conn);

    /* notice_receiver may fire during PQconnectPoll and destroy us */
    if (self->magic != EV_PG_MAGIC) goto out;

    switch (poll_status) {
    case PGRES_POLLING_READING:
        start_reading(self);
        stop_writing(self);
        break;

    case PGRES_POLLING_WRITING:
        stop_reading(self);
        start_writing(self);
        break;

    case PGRES_POLLING_OK:
        self->connecting = 0;
        reinit_io_watchers(self);
        if (self->magic != EV_PG_MAGIC || NULL == self->conn
            || self->connecting) break;

        if (NULL != self->on_connect) {
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            PUTBACK;

            CALL_SV_GUARDED(self->on_connect, "connect handler");

            FREETMPS;
            LEAVE;
            if (self->magic != EV_PG_MAGIC) break;
        }
        break;

    case PGRES_POLLING_FAILED: {
        PGconn *old_conn = self->conn;
        self->connecting = 0;
        emit_error(self, PQerrorMessage(self->conn));
        if (self->magic != EV_PG_MAGIC) break;
        /* If on_error called reset, conn has already changed */
        if (self->conn == old_conn) {
            cleanup_connection(self);
            cancel_pending(self, "connection failed");
        }
        break;
    }

    default:
        break;
    }

out:
    self->callback_depth--;
    check_destroyed(self);
}

static void cleanup_connection(ev_pg_t *self) {
    PGconn *conn;

    stop_reading(self);
    stop_writing(self);
    self->fd = -1;
    self->connecting = 0;
    self->copy_mode = 0;
    self->draining_single_row = 0;
    CLEANUP_CANCEL(self);

    if (self->pending_result) {
        PQclear(self->pending_result);
        self->pending_result = NULL;
    }

    if (self->trace_fp) {
        if (self->conn) PQuntrace(self->conn);
        fclose(self->trace_fp);
        self->trace_fp = NULL;
    }

    conn = self->conn;
    self->conn = NULL;
    if (conn) {
        PQfinish(conn);
    }
}

static void cancel_pending(ev_pg_t *self, const char *errmsg) {
    ngx_queue_t *q;
    ev_pg_cb_t *cbt;
    unsigned int entry_magic = self->magic;

    self->callback_depth++;

    while (!ngx_queue_empty(&self->cb_queue)) {
        q = ngx_queue_head(&self->cb_queue);
        cbt = ngx_queue_data(q, ev_pg_cb_t, queue);

        if (cbt == self->delivering_cbt) {
            /* Currently being delivered; remove without re-firing */
            ngx_queue_remove(q);
            self->pending_count--;
            if (NULL != cbt->cb) SvREFCNT_dec(cbt->cb);
            release_cbt(cbt);
            self->delivering_cbt = NULL;
            continue;
        }

        ngx_queue_remove(q);
        self->pending_count--;

        if (NULL != cbt->cb) {
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            EXTEND(SP, 2);
            PUSHs(&PL_sv_undef);
            PUSHs(sv_2mortal(newSVpv(errmsg, 0)));
            PUTBACK;
            CALL_SV_GUARDED(cbt->cb, "callback during cancel");
            FREETMPS;
            LEAVE;

            SvREFCNT_dec(cbt->cb);
        }
        release_cbt(cbt);

        if (self->magic != entry_magic) {
            /* DESTROY fired from inside callback; drain remaining silently */
            while (!ngx_queue_empty(&self->cb_queue)) {
                q = ngx_queue_head(&self->cb_queue);
                cbt = ngx_queue_data(q, ev_pg_cb_t, queue);
                ngx_queue_remove(q);
                self->pending_count--;
                if (NULL != cbt->cb) SvREFCNT_dec(cbt->cb);
                release_cbt(cbt);
            }
            break;
        }
    }

    self->callback_depth--;
    update_idle_ref(self);
}

static ev_pg_cb_t* push_cb(ev_pg_t *self, SV *cb, int is_sync) {
    ev_pg_cb_t *cbt = alloc_cbt();
    cbt->cb = SvREFCNT_inc(cb);
    cbt->is_pipeline_sync = is_sync;
    cbt->is_describe = 0;
    ngx_queue_insert_tail(&self->cb_queue, &cbt->queue);
    self->pending_count++;
    update_idle_ref(self);
    return cbt;
}

static SV* handler_accessor(SV **slot, SV *handler, int has_arg) {
    if (has_arg) {
        if (NULL != *slot) {
            SvREFCNT_dec(*slot);
            *slot = NULL;
        }
        if (NULL != handler && SvOK(handler)) {
            if (!SvROK(handler) || SvTYPE(SvRV(handler)) != SVt_PVCV)
                croak("handler must be a CODE reference or undef");
            *slot = SvREFCNT_inc(handler);
        }
    }

    return (NULL != *slot)
        ? SvREFCNT_inc(*slot)
        : &PL_sv_undef;
}

static void notice_receiver(void *arg, const PGresult *res) {
    ev_pg_t *self = (ev_pg_t *)arg;
    const char *msg;

    if (self->magic != EV_PG_MAGIC) return;
    if (NULL == self->on_notice) return;

    msg = PQresultErrorMessage(res);
    if (!msg || !msg[0]) return;

    self->callback_depth++;
    {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv(msg, 0)));
        PUTBACK;

        CALL_SV_GUARDED(self->on_notice, "notice handler");

        FREETMPS;
        LEAVE;
    }
    self->callback_depth--;
    check_destroyed(self);
}


static SV* conn_str_or_undef(const char *val) {
    return val ? newSVpv(val, 0) : &PL_sv_undef;
}

static HV* build_error_fields(PGresult *res) {
    HV *hv = newHV();
    static const struct { const char *key; int keylen; int code; } diag[] = {
        {"severity",          8,  PG_DIAG_SEVERITY},
        {"sqlstate",          8,  PG_DIAG_SQLSTATE},
        {"primary",           7,  PG_DIAG_MESSAGE_PRIMARY},
        {"detail",            6,  PG_DIAG_MESSAGE_DETAIL},
        {"hint",              4,  PG_DIAG_MESSAGE_HINT},
        {"position",          8,  PG_DIAG_STATEMENT_POSITION},
        {"internal_position", 17, PG_DIAG_INTERNAL_POSITION},
        {"internal_query",    14, PG_DIAG_INTERNAL_QUERY},
        {"context",           7,  PG_DIAG_CONTEXT},
        {"schema",            6,  PG_DIAG_SCHEMA_NAME},
        {"table",             5,  PG_DIAG_TABLE_NAME},
        {"column",            6,  PG_DIAG_COLUMN_NAME},
        {"datatype",          8,  PG_DIAG_DATATYPE_NAME},
        {"constraint",        10, PG_DIAG_CONSTRAINT_NAME},
        {"source_file",       11, PG_DIAG_SOURCE_FILE},
        {"source_line",       11, PG_DIAG_SOURCE_LINE},
        {"source_function",   15, PG_DIAG_SOURCE_FUNCTION},
    };
    int i;
    for (i = 0; i < (int)(sizeof(diag)/sizeof(diag[0])); i++) {
        const char *val = PQresultErrorField(res, diag[i].code);
        if (val)
            (void)hv_store(hv, diag[i].key, diag[i].keylen,
                           newSVpv(val, 0), 0);
    }
    return hv;
}

static HV* build_result_meta(PGresult *res) {
    HV *hv = newHV();
    int nf = PQnfields(res);
    int i;
    const char *cs = PQcmdStatus(res);

    (void)hv_store(hv, "nfields", 7, newSViv(nf), 0);
    (void)hv_store(hv, "cmd_status", 10,
                   newSVpv(cs ? cs : "", 0), 0);

    {
        Oid oid = PQoidValue(res);
        if (oid != InvalidOid)
            (void)hv_store(hv, "inserted_oid", 12, newSVuv(oid), 0);
    }

    if (nf > 0) {
        AV *fields = newAV();
        av_extend(fields, nf - 1);
        for (i = 0; i < nf; i++) {
            HV *f = newHV();
            (void)hv_store(f, "name", 4,
                           newSVpv(PQfname(res, i), 0), 0);
            (void)hv_store(f, "type", 4,
                           newSVuv(PQftype(res, i)), 0);
            (void)hv_store(f, "ftable", 6,
                           newSVuv(PQftable(res, i)), 0);
            (void)hv_store(f, "ftablecol", 9,
                           newSViv(PQftablecol(res, i)), 0);
            (void)hv_store(f, "fformat", 7,
                           newSViv(PQfformat(res, i)), 0);
            (void)hv_store(f, "fsize", 5,
                           newSViv(PQfsize(res, i)), 0);
            (void)hv_store(f, "fmod", 4,
                           newSViv(PQfmod(res, i)), 0);
            av_push(fields, newRV_noinc((SV*)f));
        }
        (void)hv_store(hv, "fields", 6,
                       newRV_noinc((SV*)fields), 0);
    }

    return hv;
}

static void setup_new_conn(ev_pg_t *self, const char *what) {
    if (NULL == self->conn) {
        croak("cannot allocate PGconn");
    }

    if (PQstatus(self->conn) == CONNECTION_BAD) {
        SV *errsv = newSVpv(PQerrorMessage(self->conn), 0);
        SAVEFREESV(errsv);
        PQfinish(self->conn);
        self->conn = NULL;
        croak("%s failed: %s", what, SvPV_nolen(errsv));
    }

    if (PQsetnonblocking(self->conn, 1) != 0) {
        SV *errsv = newSVpv(PQerrorMessage(self->conn), 0);
        SAVEFREESV(errsv);
        PQfinish(self->conn);
        self->conn = NULL;
        croak("PQsetnonblocking failed: %s", SvPV_nolen(errsv));
    }
    PQsetNoticeReceiver(self->conn, notice_receiver, self);

    self->connecting = 1;
    self->fd = PQsocket(self->conn);

    if (self->fd < 0) {
        PQfinish(self->conn);
        self->conn = NULL;
        self->connecting = 0;
        croak("PQsocket returned invalid fd");
    }

    ev_io_init(&self->rio, connect_poll_cb, self->fd, EV_READ);
    self->rio.data = (void *)self;
    ev_io_init(&self->wio, connect_poll_cb, self->fd, EV_WRITE);
    self->wio.data = (void *)self;

    start_writing(self);
}

static void begin_connect(ev_pg_t *self, const char *conninfo,
                          const char *what) {
    self->conn = PQconnectStart(conninfo);
    setup_new_conn(self, what);
}

static const char** marshal_params(AV *params, int nparams,
                                    const char *stack_buf[]) {
    const char **pv;
    int i;

    if (nparams <= 16) {
        Zero(stack_buf, nparams, const char *);
        pv = stack_buf;
    } else {
        Newxz(pv, nparams, const char *);
    }

    for (i = 0; i < nparams; i++) {
        SV **svp = av_fetch(params, i, 0);
        if (svp) {
            SvGETMAGIC(*svp);
            if (SvOK(*svp))
                pv[i] = SvPV_nolen(*svp);
        }
    }

    return pv;
}

MODULE = EV::Pg  PACKAGE = EV::Pg

BOOT:
{
    I_EV_API("EV::Pg");
}

EV::Pg
_new(char *class, EV::Loop loop)
CODE:
{
    PERL_UNUSED_VAR(class);
    Newxz(RETVAL, 1, ev_pg_t);
    RETVAL->magic = EV_PG_MAGIC;
    RETVAL->loop = loop;
    RETVAL->fd = -1;
#ifdef LIBPQ_HAS_ASYNC_CANCEL
    RETVAL->cancel_fd = -1;
#endif
    ngx_queue_init(&RETVAL->cb_queue);
}
OUTPUT:
    RETVAL

void
DESTROY(EV::Pg self)
CODE:
{
    if (self->magic != EV_PG_MAGIC) return;

    self->magic = EV_PG_FREED;

    stop_reading(self);
    stop_writing(self);

    if (PL_dirty) {
#ifdef LIBPQ_HAS_ASYNC_CANCEL
        stop_cancel_reading(self);
        stop_cancel_writing(self);
        if (self->cancel_conn) PQcancelFinish(self->cancel_conn);
        if (self->cancel_cb) SvREFCNT_dec(self->cancel_cb);
#endif
        if (self->pending_result) PQclear(self->pending_result);
        if (self->trace_fp) {
            if (self->conn) PQuntrace(self->conn);
            fclose(self->trace_fp);
        }
        if (self->conn) PQfinish(self->conn);
        if (NULL != self->conninfo) Safefree(self->conninfo);
        RELEASE_HANDLER(self->on_connect);
        RELEASE_HANDLER(self->on_error);
        RELEASE_HANDLER(self->on_notify);
        RELEASE_HANDLER(self->on_notice);
        RELEASE_HANDLER(self->on_drain);
        RELEASE_LAST_HV(self->last_error_fields);
        RELEASE_LAST_HV(self->last_result_meta);
        while (!ngx_queue_empty(&self->cb_queue)) {
            ngx_queue_t *q = ngx_queue_head(&self->cb_queue);
            ev_pg_cb_t *cbt = ngx_queue_data(q, ev_pg_cb_t, queue);
            ngx_queue_remove(q);
            if (cbt->cb) SvREFCNT_dec(cbt->cb);
            Safefree(cbt);
        }
        Safefree(self);
        return;
    }

    if (self->pending_result) {
        PQclear(self->pending_result);
        self->pending_result = NULL;
    }
    CLEANUP_CANCEL(self);

    {
        PGconn *conn = self->conn;
        self->conn = NULL;
        self->loop = NULL;
        self->fd = -1;
        if (conn) PQfinish(conn);
    }

    cancel_pending(self, "object destroyed");

    RELEASE_HANDLER(self->on_connect);
    RELEASE_HANDLER(self->on_error);
    RELEASE_HANDLER(self->on_notify);
    RELEASE_HANDLER(self->on_notice);
    RELEASE_HANDLER(self->on_drain);
    RELEASE_LAST_HV(self->last_error_fields);
    RELEASE_LAST_HV(self->last_result_meta);
    if (self->trace_fp) { fclose(self->trace_fp); self->trace_fp = NULL; }
    if (NULL != self->conninfo) {
        Safefree(self->conninfo);
        self->conninfo = NULL;
    }

    if (self->callback_depth == 0)
        Safefree(self);
    /* else: deferred free via check_destroyed */
}

void
connect(EV::Pg self, const char *conninfo)
CODE:
{
    if (NULL != self->conn) {
        croak("already connected");
    }

    if (NULL != self->conninfo) Safefree(self->conninfo);
    self->conninfo = savepv(conninfo);

    begin_connect(self, conninfo, "connection");
}

void
connect_params(EV::Pg self, HV *params, int expand_dbname = 0)
CODE:
{
    HE *entry;
    int n, i;
    const char **keywords;
    const char **values;

    if (NULL != self->conn) {
        croak("already connected");
    }

    n = hv_iterinit(params);
    Newx(keywords, n + 1, const char *);
    Newx(values, n + 1, const char *);

    i = 0;
    while ((entry = hv_iternext(params)) != NULL) {
        keywords[i] = HePV(entry, PL_na);
        values[i] = SvPV_nolen(HeVAL(entry));
        i++;
    }
    keywords[i] = NULL;
    values[i] = NULL;

    if (NULL != self->conninfo) Safefree(self->conninfo);
    self->conninfo = NULL;

    self->conn = PQconnectStartParams(keywords, values, expand_dbname);
    Safefree(keywords);
    Safefree(values);
    setup_new_conn(self, "connection");

    /* store conninfo for reset — reconstruct from live connection */
    {
        PQconninfoOption *opts = PQconninfo(self->conn);
        if (opts) {
            SV *buf = newSVpvs("");
            PQconninfoOption *o;
            for (o = opts; o->keyword; o++) {
                if (o->val && o->val[0]) {
                    if (SvCUR(buf) > 0) sv_catpvs(buf, " ");
                    sv_catpv(buf, o->keyword);
                    sv_catpvs(buf, "=");
                    sv_catpvs(buf, "'");
                    /* escape single quotes in value */
                    {
                        const char *p = o->val;
                        while (*p) {
                            if (*p == '\'') sv_catpvs(buf, "\\'");
                            else if (*p == '\\') sv_catpvs(buf, "\\\\");
                            else sv_catpvn(buf, p, 1);
                            p++;
                        }
                    }
                    sv_catpvs(buf, "'");
                }
            }
            PQconninfoFree(opts);
            self->conninfo = savepv(SvPV_nolen(buf));
            SvREFCNT_dec(buf);
        }
    }
}

void
reset(EV::Pg self)
CODE:
{
    PGconn *old_conn;

    if (NULL == self->conninfo) {
        croak("no previous connection to reset");
    }

    old_conn = self->conn;
    cancel_pending(self, "connection reset");
    if (self->magic != EV_PG_MAGIC) {
        check_destroyed(self);
        return;
    }
    /* If a cancel callback already called reset, conn has changed */
    if (self->conn == old_conn) {
        cleanup_connection(self);
        begin_connect(self, self->conninfo, "reset");
    }
}

void
finish(EV::Pg self)
CODE:
{
    cancel_pending(self, "connection finished");
    if (self->magic != EV_PG_MAGIC) {
        check_destroyed(self);
        return;
    }
    cleanup_connection(self);
}

SV*
on_connect(EV::Pg self, SV *handler = NULL)
CODE:
{
    RETVAL = handler_accessor(&self->on_connect, handler, items > 1);
}
OUTPUT:
    RETVAL

SV*
on_error(EV::Pg self, SV *handler = NULL)
CODE:
{
    RETVAL = handler_accessor(&self->on_error, handler, items > 1);
}
OUTPUT:
    RETVAL

SV*
on_notify(EV::Pg self, SV *handler = NULL)
CODE:
{
    RETVAL = handler_accessor(&self->on_notify, handler, items > 1);
}
OUTPUT:
    RETVAL

SV*
on_notice(EV::Pg self, SV *handler = NULL)
CODE:
{
    RETVAL = handler_accessor(&self->on_notice, handler, items > 1);
}
OUTPUT:
    RETVAL

SV*
on_drain(EV::Pg self, SV *handler = NULL)
CODE:
{
    RETVAL = handler_accessor(&self->on_drain, handler, items > 1);
}
OUTPUT:
    RETVAL

void
query(EV::Pg self, const char *sql, SV *cb)
CODE:
{
    REQUIRE_CONN(self);
    REQUIRE_CB(cb);

    if (PQpipelineStatus(self->conn) != PQ_PIPELINE_OFF) {
        croak("query() not allowed in pipeline mode; use query_params()");
    }

    if (!PQsendQuery(self->conn, sql)) {
        croak("PQsendQuery failed: %s", PQerrorMessage(self->conn));
    }

    push_cb(self, cb, 0);
    check_flush(self);
}

void
query_params(EV::Pg self, const char *sql, SV *params_ref, SV *cb)
PREINIT:
    AV *params;
    int nparams;
    const char *stack_pv[16];
    const char **pv;
CODE:
{
    REQUIRE_CONN(self);
    REQUIRE_CB(cb);
    if (!SvROK(params_ref) || SvTYPE(SvRV(params_ref)) != SVt_PVAV) {
        croak("params must be an ARRAY reference");
    }

    params = (AV *)SvRV(params_ref);
    nparams = (int)(av_len(params) + 1);
    pv = nparams ? marshal_params(params, nparams, stack_pv) : NULL;

    if (!PQsendQueryParams(self->conn, sql, nparams, NULL, pv, NULL, NULL, 0)) {
        if (pv && pv != stack_pv) Safefree(pv);
        croak("PQsendQueryParams failed: %s", PQerrorMessage(self->conn));
    }
    if (pv && pv != stack_pv) Safefree(pv);

    push_cb(self, cb, 0);
    check_flush(self);
}

void
prepare(EV::Pg self, const char *name, const char *sql, SV *cb)
CODE:
{
    REQUIRE_CONN(self);
    REQUIRE_CB(cb);

    if (!PQsendPrepare(self->conn, name, sql, 0, NULL)) {
        croak("PQsendPrepare failed: %s", PQerrorMessage(self->conn));
    }

    push_cb(self, cb, 0);
    check_flush(self);
}

void
query_prepared(EV::Pg self, const char *name, SV *params_ref, SV *cb)
PREINIT:
    AV *params;
    int nparams;
    const char *stack_pv[16];
    const char **pv;
CODE:
{
    REQUIRE_CONN(self);
    REQUIRE_CB(cb);
    if (!SvROK(params_ref) || SvTYPE(SvRV(params_ref)) != SVt_PVAV) {
        croak("params must be an ARRAY reference");
    }

    params = (AV *)SvRV(params_ref);
    nparams = (int)(av_len(params) + 1);
    pv = nparams ? marshal_params(params, nparams, stack_pv) : NULL;

    if (!PQsendQueryPrepared(self->conn, name, nparams, pv, NULL, NULL, 0)) {
        if (pv && pv != stack_pv) Safefree(pv);
        croak("PQsendQueryPrepared failed: %s", PQerrorMessage(self->conn));
    }
    if (pv && pv != stack_pv) Safefree(pv);

    push_cb(self, cb, 0);
    check_flush(self);
}

void
describe_prepared(EV::Pg self, const char *name, SV *cb)
CODE:
{
    REQUIRE_CONN(self);
    REQUIRE_CB(cb);

    if (!PQsendDescribePrepared(self->conn, name)) {
        croak("PQsendDescribePrepared failed: %s", PQerrorMessage(self->conn));
    }

    push_cb(self, cb, 0)->is_describe = 1;
    check_flush(self);
}

void
describe_portal(EV::Pg self, const char *name, SV *cb)
CODE:
{
    REQUIRE_CONN(self);
    REQUIRE_CB(cb);

    if (!PQsendDescribePortal(self->conn, name)) {
        croak("PQsendDescribePortal failed: %s", PQerrorMessage(self->conn));
    }

    push_cb(self, cb, 0)->is_describe = 1;
    check_flush(self);
}

void
enter_pipeline(EV::Pg self)
CODE:
{
    REQUIRE_CONN(self);
    if (!PQenterPipelineMode(self->conn)) {
        croak("PQenterPipelineMode failed: %s", PQerrorMessage(self->conn));
    }
}

void
exit_pipeline(EV::Pg self)
CODE:
{
    REQUIRE_CONN(self);
    if (!PQexitPipelineMode(self->conn)) {
        croak("PQexitPipelineMode failed: %s", PQerrorMessage(self->conn));
    }
}

int
pipeline_status(EV::Pg self)
CODE:
{
    if (NULL == self->conn) {
        RETVAL = 0;
    }
    else {
        RETVAL = (int)PQpipelineStatus(self->conn);
    }
}
OUTPUT:
    RETVAL

void
pipeline_sync(EV::Pg self, SV *cb)
CODE:
{
    REQUIRE_CONN(self);
    REQUIRE_CB(cb);

    if (!PQpipelineSync(self->conn)) {
        croak("PQpipelineSync failed: %s", PQerrorMessage(self->conn));
    }

    push_cb(self, cb, 1);
    check_flush(self);
}

void
send_flush_request(EV::Pg self)
CODE:
{
    REQUIRE_CONN(self);
    if (!PQsendFlushRequest(self->conn)) {
        croak("PQsendFlushRequest failed: %s", PQerrorMessage(self->conn));
    }
    check_flush(self);
}

int
set_single_row_mode(EV::Pg self)
CODE:
{
    REQUIRE_CONN(self);
    RETVAL = PQsetSingleRowMode(self->conn);
}
OUTPUT:
    RETVAL

int
put_copy_data(EV::Pg self, SV *data)
PREINIT:
    STRLEN len;
    const char *buf;
CODE:
{
    REQUIRE_CONN(self);
    buf = SvPV(data, len);
    if (len > (STRLEN)INT_MAX)
        croak("put_copy_data: data too large");
    RETVAL = PQputCopyData(self->conn, buf, (int)len);
    if (RETVAL >= 0) {
        check_flush(self);
    }
}
OUTPUT:
    RETVAL

int
put_copy_end(EV::Pg self, SV *errmsg = NULL)
CODE:
{
    const char *msg = NULL;
    REQUIRE_CONN(self);
    if (errmsg && SvOK(errmsg)) {
        msg = SvPV_nolen(errmsg);
    }
    RETVAL = PQputCopyEnd(self->conn, msg);
    if (RETVAL >= 0) {
        check_flush(self);
    }
}
OUTPUT:
    RETVAL

SV*
get_copy_data(EV::Pg self)
CODE:
{
    char *buf = NULL;
    int len;

    REQUIRE_CONN(self);

    len = PQgetCopyData(self->conn, &buf, 1);
    if (len > 0) {
        RETVAL = newSVpvn(buf, len);
        PQfreemem(buf);
    }
    else if (len == -1) {
        /* COPY OUT complete; synthetically trigger io_read_cb so
         * process_results picks up the final COMMAND_OK result
         * (no new socket data will arrive to trigger it). */
        RETVAL = newSViv(-1);
        if (self->loop)
            ev_invoke(self->loop, &self->rio, EV_READ);
    }
    else if (len == -2) {
        croak("PQgetCopyData failed: %s", PQerrorMessage(self->conn));
    }
    else {
        RETVAL = &PL_sv_undef;
    }
}
OUTPUT:
    RETVAL

int
status(EV::Pg self)
CODE:
{
    RETVAL = (NULL != self->conn) ? (int)PQstatus(self->conn) : (int)CONNECTION_BAD;
}
OUTPUT:
    RETVAL

SV*
error_message(EV::Pg self)
CODE:
{
    if (NULL != self->conn) {
        const char *msg = PQerrorMessage(self->conn);
        RETVAL = (msg && msg[0]) ? newSVpv(msg, 0) : &PL_sv_undef;
    }
    else {
        RETVAL = &PL_sv_undef;
    }
}
OUTPUT:
    RETVAL

int
transaction_status(EV::Pg self)
CODE:
{
    RETVAL = (NULL != self->conn) ? (int)PQtransactionStatus(self->conn) : (int)PQTRANS_UNKNOWN;
}
OUTPUT:
    RETVAL

SV*
parameter_status(EV::Pg self, const char *name)
CODE:
{
    RETVAL = conn_str_or_undef(self->conn ? PQparameterStatus(self->conn, name) : NULL);
}
OUTPUT:
    RETVAL

int
socket(EV::Pg self)
CODE:
{
    RETVAL = (NULL != self->conn) ? PQsocket(self->conn) : -1;
}
OUTPUT:
    RETVAL

int
backend_pid(EV::Pg self)
CODE:
{
    RETVAL = (NULL != self->conn) ? PQbackendPID(self->conn) : 0;
}
OUTPUT:
    RETVAL

int
server_version(EV::Pg self)
CODE:
{
    RETVAL = (NULL != self->conn) ? PQserverVersion(self->conn) : 0;
}
OUTPUT:
    RETVAL

SV*
db(EV::Pg self)
CODE:
{
    RETVAL = conn_str_or_undef(self->conn ? PQdb(self->conn) : NULL);
}
OUTPUT:
    RETVAL

SV*
user(EV::Pg self)
CODE:
{
    RETVAL = conn_str_or_undef(self->conn ? PQuser(self->conn) : NULL);
}
OUTPUT:
    RETVAL

SV*
host(EV::Pg self)
CODE:
{
    RETVAL = conn_str_or_undef(self->conn ? PQhost(self->conn) : NULL);
}
OUTPUT:
    RETVAL

SV*
port(EV::Pg self)
CODE:
{
    RETVAL = conn_str_or_undef(self->conn ? PQport(self->conn) : NULL);
}
OUTPUT:
    RETVAL

int
is_connected(EV::Pg self)
CODE:
{
    RETVAL = (NULL != self->conn && !self->connecting &&
              PQstatus(self->conn) == CONNECTION_OK) ? 1 : 0;
}
OUTPUT:
    RETVAL

int
ssl_in_use(EV::Pg self)
CODE:
{
    RETVAL = (NULL != self->conn) ? PQsslInUse(self->conn) : 0;
}
OUTPUT:
    RETVAL

SV*
ssl_attribute(EV::Pg self, const char *name)
CODE:
{
    RETVAL = conn_str_or_undef(self->conn ? PQsslAttribute(self->conn, name) : NULL);
}
OUTPUT:
    RETVAL

SV*
escape_literal(EV::Pg self, SV *str)
PREINIT:
    STRLEN len;
    const char *s;
    char *escaped;
CODE:
{
    REQUIRE_CONN(self);
    s = SvPV(str, len);
    escaped = PQescapeLiteral(self->conn, s, len);
    if (NULL == escaped) {
        croak("PQescapeLiteral failed: %s", PQerrorMessage(self->conn));
    }
    RETVAL = newSVpv(escaped, 0);
    PQfreemem(escaped);
}
OUTPUT:
    RETVAL

SV*
escape_identifier(EV::Pg self, SV *str)
PREINIT:
    STRLEN len;
    const char *s;
    char *escaped;
CODE:
{
    REQUIRE_CONN(self);
    s = SvPV(str, len);
    escaped = PQescapeIdentifier(self->conn, s, len);
    if (NULL == escaped) {
        croak("PQescapeIdentifier failed: %s", PQerrorMessage(self->conn));
    }
    RETVAL = newSVpv(escaped, 0);
    PQfreemem(escaped);
}
OUTPUT:
    RETVAL

int
pending_count(EV::Pg self)
CODE:
{
    RETVAL = self->pending_count;
}
OUTPUT:
    RETVAL

void
skip_pending(EV::Pg self)
CODE:
{
    cancel_pending(self, "skipped");
    check_destroyed(self);
}

int
lib_version(char *class)
CODE:
{
    PERL_UNUSED_VAR(class);
    RETVAL = PQlibVersion();
}
OUTPUT:
    RETVAL

SV*
conninfo_parse(char *class, const char *conninfo)
CODE:
{
    PQconninfoOption *opts, *o;
    char *errmsg = NULL;
    HV *hv;

    PERL_UNUSED_VAR(class);
    opts = PQconninfoParse(conninfo, &errmsg);
    if (!opts) {
        if (errmsg) {
            SV *errsv = newSVpv(errmsg, 0);
            SAVEFREESV(errsv);
            PQfreemem(errmsg);
            croak("PQconninfoParse failed: %s", SvPV_nolen(errsv));
        }
        croak("PQconninfoParse failed");
    }

    hv = newHV();
    for (o = opts; o->keyword; o++) {
        if (o->val)
            (void)hv_store(hv, o->keyword, strlen(o->keyword),
                           newSVpv(o->val, 0), 0);
    }
    PQconninfoFree(opts);
    RETVAL = newRV_noinc((SV*)hv);
}
OUTPUT:
    RETVAL

SV*
cancel(EV::Pg self)
PREINIT:
    PGcancel *cn;
    char errbuf[256];
CODE:
{
    REQUIRE_CONN(self);
    cn = PQgetCancel(self->conn);
    if (NULL == cn) {
        croak("PQgetCancel failed");
    }
    {
        int ok = PQcancel(cn, errbuf, sizeof(errbuf));
        PQfreeCancel(cn);
        RETVAL = ok ? &PL_sv_undef : newSVpv(errbuf, 0);
    }
}
OUTPUT:
    RETVAL

#ifdef LIBPQ_HAS_ASYNC_CANCEL

void
cancel_async(EV::Pg self, SV *cb)
CODE:
{
    REQUIRE_CONN(self);
    REQUIRE_CB(cb);

    if (self->cancel_conn)
        croak("cancel already in progress");

    self->cancel_conn = PQcancelCreate(self->conn);
    if (!self->cancel_conn)
        croak("PQcancelCreate failed");

    if (!PQcancelStart(self->cancel_conn)) {
        const char *err = PQcancelErrorMessage(self->cancel_conn);
        PQcancelFinish(self->cancel_conn);
        self->cancel_conn = NULL;
        croak("PQcancelStart failed: %s", err);
    }

    self->cancel_fd = PQcancelSocket(self->cancel_conn);
    if (self->cancel_fd < 0) {
        PQcancelFinish(self->cancel_conn);
        self->cancel_conn = NULL;
        croak("PQcancelSocket returned invalid fd");
    }

    self->cancel_cb = SvREFCNT_inc(cb);

    ev_io_init(&self->cancel_rio, cancel_poll_cb, self->cancel_fd, EV_READ);
    self->cancel_rio.data = (void *)self;
    ev_io_init(&self->cancel_wio, cancel_poll_cb, self->cancel_fd, EV_WRITE);
    self->cancel_wio.data = (void *)self;

    start_cancel_writing(self);
}

#endif

SV*
escape_bytea(EV::Pg self, SV *data)
PREINIT:
    STRLEN len;
    const unsigned char *buf;
    unsigned char *escaped;
    size_t escaped_len;
CODE:
{
    REQUIRE_CONN(self);
    buf = (const unsigned char *)SvPV(data, len);
    escaped = PQescapeByteaConn(self->conn, buf, len, &escaped_len);
    if (NULL == escaped) {
        croak("PQescapeByteaConn failed: %s", PQerrorMessage(self->conn));
    }
    RETVAL = newSVpvn((char *)escaped, escaped_len - 1);
    PQfreemem(escaped);
}
OUTPUT:
    RETVAL

SV*
unescape_bytea(char *class, SV *data)
PREINIT:
    STRLEN len;
    const unsigned char *buf;
    unsigned char *unescaped;
    size_t unescaped_len;
CODE:
{
    PERL_UNUSED_VAR(class);
    buf = (const unsigned char *)SvPV(data, len);
    unescaped = PQunescapeBytea(buf, &unescaped_len);
    if (NULL == unescaped) {
        croak("PQunescapeBytea failed");
    }
    RETVAL = newSVpvn((char *)unescaped, unescaped_len);
    PQfreemem(unescaped);
}
OUTPUT:
    RETVAL

SV*
client_encoding(EV::Pg self)
CODE:
{
    REQUIRE_CONN(self);
    RETVAL = newSVpv(pg_encoding_to_char(PQclientEncoding(self->conn)), 0);
}
OUTPUT:
    RETVAL

void
set_client_encoding(EV::Pg self, const char *encoding)
CODE:
{
    REQUIRE_CONN(self);
    if (self->pending_count > 0)
        croak("set_client_encoding: cannot call with pending queries");
    if (PQsetClientEncoding(self->conn, encoding) != 0) {
        croak("PQsetClientEncoding failed: %s", PQerrorMessage(self->conn));
    }
}

int
set_error_verbosity(EV::Pg self, int verbosity)
CODE:
{
    REQUIRE_CONN(self);
    RETVAL = (int)PQsetErrorVerbosity(self->conn, (PGVerbosity)verbosity);
}
OUTPUT:
    RETVAL

SV*
error_fields(EV::Pg self)
CODE:
{
    if (self->last_error_fields)
        RETVAL = newRV_inc((SV*)self->last_error_fields);
    else
        RETVAL = &PL_sv_undef;
}
OUTPUT:
    RETVAL

SV*
result_meta(EV::Pg self)
CODE:
{
    if (self->last_result_meta)
        RETVAL = newRV_inc((SV*)self->last_result_meta);
    else
        RETVAL = &PL_sv_undef;
}
OUTPUT:
    RETVAL

#ifdef LIBPQ_HAS_CHUNK_MODE

int
set_chunked_rows_mode(EV::Pg self, int chunk_size)
CODE:
{
    REQUIRE_CONN(self);
    RETVAL = PQsetChunkedRowsMode(self->conn, chunk_size);
}
OUTPUT:
    RETVAL

#endif

#ifdef LIBPQ_HAS_CLOSE_PREPARED

void
close_prepared(EV::Pg self, const char *name, SV *cb)
CODE:
{
    REQUIRE_CONN(self);
    REQUIRE_CB(cb);
    if (!PQsendClosePrepared(self->conn, name)) {
        croak("PQsendClosePrepared failed: %s", PQerrorMessage(self->conn));
    }
    push_cb(self, cb, 0);
    check_flush(self);
}

void
close_portal(EV::Pg self, const char *name, SV *cb)
CODE:
{
    REQUIRE_CONN(self);
    REQUIRE_CB(cb);
    if (!PQsendClosePortal(self->conn, name)) {
        croak("PQsendClosePortal failed: %s", PQerrorMessage(self->conn));
    }
    push_cb(self, cb, 0);
    check_flush(self);
}

#endif

#ifdef LIBPQ_HAS_SEND_PIPELINE_SYNC

void
send_pipeline_sync(EV::Pg self, SV *cb)
CODE:
{
    REQUIRE_CONN(self);
    REQUIRE_CB(cb);
    if (!PQsendPipelineSync(self->conn)) {
        croak("PQsendPipelineSync failed: %s", PQerrorMessage(self->conn));
    }
    push_cb(self, cb, 1);
    /* no check_flush — that's the point */
}

#endif

int
set_error_context_visibility(EV::Pg self, int visibility)
CODE:
{
    REQUIRE_CONN(self);
    RETVAL = (int)PQsetErrorContextVisibility(self->conn, (PGContextVisibility)visibility);
}
OUTPUT:
    RETVAL

SV*
conninfo(EV::Pg self)
CODE:
{
    PQconninfoOption *opts, *o;
    HV *hv;

    REQUIRE_CONN(self);
    opts = PQconninfo(self->conn);
    if (!opts)
        croak("PQconninfo failed");

    hv = newHV();
    for (o = opts; o->keyword; o++) {
        if (o->val)
            (void)hv_store(hv, o->keyword, strlen(o->keyword),
                           newSVpv(o->val, 0), 0);
    }
    PQconninfoFree(opts);
    RETVAL = newRV_noinc((SV*)hv);
}
OUTPUT:
    RETVAL

int
connection_used_password(EV::Pg self)
CODE:
{
    RETVAL = (NULL != self->conn) ? PQconnectionUsedPassword(self->conn) : 0;
}
OUTPUT:
    RETVAL

int
connection_used_gssapi(EV::Pg self)
CODE:
{
    RETVAL = (NULL != self->conn) ? PQconnectionUsedGSSAPI(self->conn) : 0;
}
OUTPUT:
    RETVAL

int
connection_needs_password(EV::Pg self)
CODE:
{
    RETVAL = (NULL != self->conn) ? PQconnectionNeedsPassword(self->conn) : 0;
}
OUTPUT:
    RETVAL

SV*
hostaddr(EV::Pg self)
CODE:
{
    RETVAL = conn_str_or_undef(self->conn ? PQhostaddr(self->conn) : NULL);
}
OUTPUT:
    RETVAL

void
ssl_attribute_names(EV::Pg self)
PPCODE:
{
    const char * const *names;
    AV *av;
    int i;

    if (!self->conn) XSRETURN_UNDEF;
    names = PQsslAttributeNames(self->conn);
    if (!names) XSRETURN_UNDEF;

    av = newAV();
    for (i = 0; names[i]; i++)
        av_push(av, newSVpv(names[i], 0));
    PUSHs(sv_2mortal(newRV_noinc((SV*)av)));
    XSRETURN(1);
}

int
protocol_version(EV::Pg self)
CODE:
{
    RETVAL = self->conn ? PQprotocolVersion(self->conn) : 0;
}
OUTPUT:
    RETVAL

SV*
encrypt_password(EV::Pg self, const char *password, const char *user, ...)
CODE:
{
    const char *algorithm;
    char *enc;

    REQUIRE_CONN(self);
    algorithm = (items > 3 && SvOK(ST(3))) ? SvPV_nolen(ST(3)) : NULL;
    enc = PQencryptPasswordConn(self->conn, password, user, algorithm);
    if (!enc)
        croak("PQencryptPasswordConn failed: %s", PQerrorMessage(self->conn));
    RETVAL = newSVpv(enc, 0);
    PQfreemem(enc);
}
OUTPUT:
    RETVAL

void
trace(EV::Pg self, const char *filename)
CODE:
{
    REQUIRE_CONN(self);
    if (self->trace_fp) {
        PQuntrace(self->conn);
        fclose(self->trace_fp);
        self->trace_fp = NULL;
    }
    self->trace_fp = fopen(filename, "w");
    if (!self->trace_fp)
        croak("cannot open %s: %s", filename, strerror(errno));
    PQtrace(self->conn, self->trace_fp);
}

void
untrace(EV::Pg self)
CODE:
{
    if (self->conn) PQuntrace(self->conn);
    if (self->trace_fp) {
        fclose(self->trace_fp);
        self->trace_fp = NULL;
    }
}

#ifdef LIBPQ_HAS_TRACE_FLAGS

void
set_trace_flags(EV::Pg self, int flags)
CODE:
{
    REQUIRE_CONN(self);
    PQsetTraceFlags(self->conn, flags);
}

#endif

