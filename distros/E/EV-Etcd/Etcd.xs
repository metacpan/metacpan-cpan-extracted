#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <EV/EVAPI.h>

#include <time.h>
#include <stdlib.h>
#include <unistd.h>

#include "etcd_common.h"
#include "etcd_kv.h"
#include "etcd_watch.h"
#include "etcd_lease.h"
#include "etcd_maint.h"
#include "etcd_lock.h"
#include "etcd_election.h"
#include "etcd_cluster.h"
#include "etcd_txn.h"

static void *cq_thread_func(void *arg);
static void cq_async_callback(EV_P_ ev_async *w, int revents);
static void process_grpc_event(pTHX_ ev_etcd_t *client, void *tag, int success);

/* gRPC runs only while a client exists: its threads don't survive fork() */
static int ev_etcd_grpc_users;
static int ev_etcd_grpc_held;      /* our grpc_init reference is taken */
static int ev_etcd_grpc_settling;  /* released, not yet seen fully shut down */
static int ev_etcd_grpc_stale;     /* still running at the last fork */
static pid_t ev_etcd_grpc_pid;

/* getpid() cached for the per-call fork check, refreshed in forked children */
static pid_t ev_etcd_pid;

/* Live clients of this process, so a forked child can disarm what it inherits */
static ev_etcd_t *ev_etcd_clients;

static void unregister_client(ev_etcd_t *client) {
    ev_etcd_t **pp = &ev_etcd_clients;
    while (*pp && *pp != client)
        pp = &(*pp)->next_live;
    if (*pp)
        *pp = client->next_live;
}

/* Newer gRPC finishes shutting down on its own threads: wait once per shutdown
 * and note whether it is still up. Never in a child: a lost thread may hold its lock */
static void ev_etcd_atfork_prepare(void) {
    if (ev_etcd_grpc_users || ev_etcd_grpc_pid != ev_etcd_pid)
        return;
    if (ev_etcd_grpc_settling) {
        for (int ms = 0; ms < 2000 && grpc_is_initialized(); ms++)
            usleep(1000);
        ev_etcd_grpc_settling = 0;
    }
    ev_etcd_grpc_stale = grpc_is_initialized();
}

/* Inherited watchers would drive gRPC on the parent's connections */
static void ev_etcd_atfork_child(void) {
    ev_etcd_pid = getpid();
    for (ev_etcd_t *c = ev_etcd_clients; c; c = c->next_live) {
        ev_timer_stop(EV_DEFAULT, &c->health_timer);
        ev_async_stop(EV_DEFAULT, &c->cq_async);
        for (watch_call_t *wc = c->watches; wc; wc = wc->next) {
            ev_timer_stop(EV_DEFAULT, &wc->reconnect_timer);
            ev_timer_stop(EV_DEFAULT, &wc->progress_timer);
        }
        for (keepalive_call_t *kc = c->keepalives; kc; kc = kc->next) {
            ev_timer_stop(EV_DEFAULT, &kc->reconnect_timer);
            ev_timer_stop(EV_DEFAULT, &kc->renew_timer);
        }
        for (observe_call_t *oc = c->observes; oc; oc = oc->next)
            ev_timer_stop(EV_DEFAULT, &oc->reconnect_timer);
    }
    ev_etcd_clients = NULL;
}

/* gRPC in a child runs on the parent's poller state and can break its connections */
static void croak_if_forked(pTHX_ pid_t owner_pid) {
    if (owner_pid != ev_etcd_pid)
        croak("EV::Etcd: a client created in process %d cannot be used in forked child %d",
              (int)owner_pid, (int)ev_etcd_pid);
}

#ifdef __APPLE__
/* gRPC threads running through exit() can crash it; the first shutdown is prompt */
static void grpc_shutdown_at_exit(void) {
    if (ev_etcd_grpc_held && !ev_etcd_grpc_users && ev_etcd_grpc_pid == getpid())
        grpc_shutdown_blocking();
}
#endif

static void grpc_acquire(pTHX) {
    if (ev_etcd_grpc_users > 0 && ev_etcd_grpc_pid != ev_etcd_pid)
        croak("EV::Etcd: gRPC was started by process %d, which forked this one"
              " while holding a client; a forked child cannot use it. Create"
              " clients only after fork(), or destroy every client before forking",
              (int)ev_etcd_grpc_pid);
    if (ev_etcd_grpc_stale && ev_etcd_grpc_pid != ev_etcd_pid)
        croak("EV::Etcd: gRPC in process %d was still running when it forked"
              " this one; a forked child cannot use it. Create clients only"
              " after fork()", (int)ev_etcd_grpc_pid);
    ev_etcd_grpc_users++;
    if (!ev_etcd_grpc_held) {
        WITH_SIGNALS_BLOCKED(grpc_init());
        ev_etcd_grpc_held = 1;
        ev_etcd_grpc_pid = ev_etcd_pid;
#ifdef __APPLE__
        atexit(grpc_shutdown_at_exit);
#endif
    }
}

/* Shutdown may finish on a background thread that fork() would catch mid-teardown.
 * macOS's is prompt only the first time and breaks if restarted meanwhile */
static void grpc_release(void) {
    if (--ev_etcd_grpc_users > 0)
        return;
#ifndef __APPLE__
    grpc_shutdown_blocking();
    ev_etcd_grpc_held = 0;
    ev_etcd_grpc_settling = 1;
#endif
}

/* Mortal, so a croak later in new() frees it */
static SV *slurp_pem(pTHX_ const char *opt, const char *path) {
    PerlIO *fp = PerlIO_open(path, "r");
    if (!fp)
        croak("EV::Etcd: cannot open %s '%s': %s", opt, path, Strerror(errno));
    SV *sv = sv_2mortal(newSVpvs(""));
    char buf[8192];
    SSize_t n;
    while ((n = PerlIO_read(fp, buf, sizeof buf)) > 0)
        sv_catpvn(sv, buf, n);
    int failed = n < 0 || PerlIO_error(fp);
    PerlIO_close(fp);
    if (failed)
        croak("EV::Etcd: cannot read %s '%s'", opt, path);
    return sv;
}

/* 0 for off (non-positive or NaN), else whole milliseconds capped at a day */
static int seconds_to_ms(NV seconds) {
    if (!(seconds > 0))
        return 0;
    if (seconds >= 86400)
        return 86400000;
    return seconds < 0.001 ? 1 : (int)(seconds * 1000);
}

/* A mortal copy: magic on a later option could change or free the original */
static char *option_pv(pTHX_ SV *val, STRLEN *len) {
    STRLEN l;
    const char *p = SvPV_nomg(val, l);
    if (len) *len = l;
    return SvPVX(sv_2mortal(newSVpvn(p, l)));
}

/* undef means no options; anything but a hash reference is a mistake */
static SV *opts_arg(pTHX_ SV *sv) {
    SvGETMAGIC(sv);
    if (!SvOK(sv))
        return NULL;
    if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVHV)
        croak("EV::Etcd: options must be a hash reference");
    return sv;
}

static int64_t hv_fetch_i64(pTHX_ HV *hv, const char *key, I32 klen) {
    SV **svp = hv_fetch(hv, key, klen, 0);
    if (!svp)
        return 0;
    SvGETMAGIC(*svp);
    return SvOK(*svp) ? SvI64_nomg(*svp) : 0;
}

static int endpoint_scheme_len(const char *ep, int *is_https) {
    *is_https = strnEQ(ep, "https://", 8);
    return *is_https ? 8 : strnEQ(ep, "http://", 7) ? 7 : 0;
}

static void process_txn_response(pTHX_ pending_call_t *pc);
static void process_auth_response(pTHX_ pending_call_t *pc);
static void process_user_add_response(pTHX_ pending_call_t *pc);
static void process_user_delete_response(pTHX_ pending_call_t *pc);
static void process_user_change_password_response(pTHX_ pending_call_t *pc);
static void process_auth_enable_response(pTHX_ pending_call_t *pc);
static void process_auth_disable_response(pTHX_ pending_call_t *pc);
static void process_role_add_response(pTHX_ pending_call_t *pc);
static void process_role_delete_response(pTHX_ pending_call_t *pc);
static void process_role_get_response(pTHX_ pending_call_t *pc);
static void process_role_list_response(pTHX_ pending_call_t *pc);
static void process_role_grant_permission_response(pTHX_ pending_call_t *pc);
static void process_role_revoke_permission_response(pTHX_ pending_call_t *pc);
static void process_user_grant_role_response(pTHX_ pending_call_t *pc);
static void process_user_revoke_role_response(pTHX_ pending_call_t *pc);
static void process_user_get_response(pTHX_ pending_call_t *pc);
static void process_user_list_response(pTHX_ pending_call_t *pc);
static SV* response_op_to_hashref(pTHX_ Etcdserverpb__ResponseOp *op);
static void parse_request_ops(pTHX_ SV *src_av, Etcdserverpb__RequestOp ***dst_ops, size_t *dst_n);

/* Caller must Safefree the result */
static char* compute_prefix_range_end(const char *key, size_t key_len, size_t *out_len) {
    size_t i = key_len;
    while (i > 0 && (unsigned char)key[i - 1] == 0xFF) {
        i--;
    }

    char *range_end;
    if (i == 0) {
        /* range_end "\0" means every key >= key */
        Newx(range_end, 1, char);
        range_end[0] = '\0';
        *out_len = 1;
    } else {
        Newx(range_end, i, char);
        memcpy(range_end, key, i);
        ((unsigned char *)range_end)[i - 1]++;
        *out_len = i;
    }

    return range_end;
}

static void health_timer_callback(struct ev_loop *loop, ev_timer *w, int revents) {
    dTHX;
    ev_etcd_t *client = (ev_etcd_t *)((char *)w - offsetof(ev_etcd_t, health_timer));

    (void)loop;
    (void)revents;

    if (!client->active) {
        return;
    }

    grpc_connectivity_state state = grpc_channel_check_connectivity_state(client->channel, 0);

    int was_healthy = client->is_healthy;
    int is_healthy = state != GRPC_CHANNEL_TRANSIENT_FAILURE && state != GRPC_CHANNEL_SHUTDOWN;
    int checked = client->current_endpoint;

    if (was_healthy != is_healthy) {
        client->is_healthy = is_healthy;

        if (!is_healthy && client->endpoint_count > 1) {
            etcd_rotate_endpoint(client);
        }

        if (client->health_callback) {
            dSP;
            CALLBACK_WINDOW_BEGIN(client);
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            EXTEND(SP, 2);
            PUSHs(sv_2mortal(newSViv(is_healthy)));
            PUSHs(sv_2mortal(newSVpv(client->endpoints[checked], 0)));
            PUTBACK;
            CALL_SV_SAFE(client->health_callback, G_DISCARD);
            FREETMPS;
            LEAVE;
            if (CALLBACK_WINDOW_END(client))
                return;
        }
    }
}

/* No Perl on this thread. Until GRPC_QUEUE_SHUTDOWN: unread completions keep gRPC up */
static void *cq_thread_func(void *arg) {
    ev_etcd_t *client = (ev_etcd_t *)arg;

    for (;;) {
        grpc_event event = grpc_completion_queue_next(client->cq,
            gpr_inf_future(GPR_CLOCK_REALTIME), NULL);

        if (event.type == GRPC_QUEUE_SHUTDOWN) {
            break;
        }

        if (event.type != GRPC_OP_COMPLETE) {
            continue;
        }

        queued_event_t *qe = (queued_event_t *)malloc(sizeof(queued_event_t));
        if (!qe) {
            fprintf(stderr, "EV::Etcd: CRITICAL - malloc failed in gRPC thread, event dropped\n");
            continue;
        }

        qe->tag = event.tag;
        qe->success = event.success;
        qe->next = NULL;

        pthread_mutex_lock(&client->queue_mutex);
        if (client->event_queue_tail) {
            client->event_queue_tail->next = qe;
        } else {
            client->event_queue = qe;
        }
        client->event_queue_tail = qe;
        pthread_mutex_unlock(&client->queue_mutex);

        ev_async_send(EV_DEFAULT, &client->cq_async);
    }

    return NULL;
}

/* A DESTROY deferred from inside a callback, once in_callback is back to 0 */
void finish_client_destroy(pTHX_ ev_etcd_t *client) {
    while (client->pending_calls) {
        pending_call_t *pc = client->pending_calls;
        client->pending_calls = pc->next;
        grpc_metadata_array_destroy(&pc->initial_metadata);
        grpc_metadata_array_destroy(&pc->trailing_metadata);
        if (pc->recv_buffer) grpc_byte_buffer_destroy(pc->recv_buffer);
        grpc_slice_unref(pc->status_details);
        if (pc->call) grpc_call_unref(pc->call);
        etcd_call_release(&pc->base);
        SvREFCNT_dec(pc->callback);
        Safefree(pc);
    }
    while (client->watches) {
        cleanup_watch(aTHX_ client->watches);
    }
    while (client->keepalives) {
        cleanup_keepalive(aTHX_ client->keepalives);
    }
    while (client->observes) {
        cleanup_observe(aTHX_ client->observes);
    }
    grpc_release();
    Safefree(client);
}

static void free_handled_call(pTHX_ void *p) {
    pending_call_t *pc = (pending_call_t *)p;
    /* A child forked in the callback and exiting must not touch gRPC */
    if (pc->client->owner_pid == ev_etcd_pid) {
        grpc_metadata_array_destroy(&pc->initial_metadata);
        grpc_metadata_array_destroy(&pc->trailing_metadata);
        if (pc->recv_buffer)
            grpc_byte_buffer_destroy(pc->recv_buffer);
        grpc_slice_unref(pc->status_details);
        grpc_call_unref(pc->call);
        etcd_call_release(&pc->base);
    }
    SvREFCNT_dec(pc->callback);
    Safefree(pc);
}

void etcd_leave_callback(pTHX_ void *p) {
    ev_etcd_t *client = (ev_etcd_t *)p;
    /* A child forked in the callback leaks the client, as its DESTROY does */
    if (!--client->in_callback && !client->active && client->owner_pid == ev_etcd_pid)
        finish_client_destroy(aTHX_ client);
}

static void cq_async_callback(struct ev_loop *loop, ev_async *w, int revents) {
    dTHX;
    (void)loop;
    (void)revents;

    ev_etcd_t *client = (ev_etcd_t *)((char *)w - offsetof(ev_etcd_t, cq_async));

    if (!client->active) {
        return;
    }

    /* Callbacks run without queue_mutex held */
    pthread_mutex_lock(&client->queue_mutex);
    queued_event_t *queue = client->event_queue;
    client->event_queue = NULL;
    client->event_queue_tail = NULL;
    pthread_mutex_unlock(&client->queue_mutex);

    /* Defers a DESTROY from any callback below to finish_client_destroy */
    CALLBACK_WINDOW_BEGIN(client);

    while (queue) {
        queued_event_t *qe = queue;
        queue = qe->next;
        void *tag = qe->tag;
        int success = qe->success;
        free(qe);   /* before the callbacks: exit() from one abandons this loop */

        /* Never NULL: fire-and-forget batches are tagged with cancel_sentinel */
        if (tag) {
            process_grpc_event(aTHX_ client, tag, success);
        }

        /* Destroyed by a callback, or a callback forked and this is the child */
        if (!client->active || client->owner_pid != ev_etcd_pid) {
            while (queue) {
                qe = queue;
                queue = qe->next;
                free(qe);
            }
            break;
        }
    }

    (void)CALLBACK_WINDOW_END(client);
}

/* Only read trailers after RECV ends: no extra batches on the message path.
 * Returns from the dispatcher while the final status is in flight. */
#define READ_STREAM_STATUS(call_ptr, status_type) \
    do { \
        grpc_op _op = {0}; \
        _op.op = GRPC_OP_RECV_STATUS_ON_CLIENT; \
        _op.data.recv_status_on_client.trailing_metadata = &(call_ptr)->trailing_metadata; \
        _op.data.recv_status_on_client.status = &(call_ptr)->status; \
        _op.data.recv_status_on_client.status_details = &(call_ptr)->status_details; \
        (call_ptr)->base.type = (status_type); \
        if (grpc_call_start_batch((call_ptr)->call, &_op, 1, &(call_ptr)->base, NULL) == GRPC_CALL_OK) \
            return; \
        (call_ptr)->status = GRPC_STATUS_INTERNAL; \
        (call_ptr)->status_details = grpc_slice_from_static_string("Failed to read stream status"); \
    } while (0)

#define PROCESS_STREAM_STATUS(func_name, call_struct, reconnect_func, cleanup_func, source) \
static void func_name(pTHX_ call_struct *stream) { \
    stream->active = 0; \
    if (!is_permanent_status(stream->status) && reconnect_func(aTHX_ stream)) \
        return; \
    if (stream->status == GRPC_STATUS_OK) { \
        CALL_STATUS_ERROR_CALLBACK(stream->callback, GRPC_STATUS_UNAVAILABLE, "Stream ended", source); \
    } else { \
        CALL_ERROR_CALLBACK(stream->callback, stream->status, stream->status_details, source); \
    } \
    if (!stream->client->active) return; \
    cleanup_func(aTHX_ stream); \
}

PROCESS_STREAM_STATUS(process_watch_status, watch_call_t, try_reconnect_watch, cleanup_watch, "watch")
PROCESS_STREAM_STATUS(process_keepalive_status, keepalive_call_t, try_reconnect_keepalive, cleanup_keepalive, "keepalive")
PROCESS_STREAM_STATUS(process_observe_status, observe_call_t, try_reconnect_observe, cleanup_observe, "observe")

static void process_grpc_event(pTHX_ ev_etcd_t *client, void *tag, int success) {
    call_base_t *base = (call_base_t *)tag;

    if (base->type == CALL_TYPE_NONE) return;

    if (base->type == CALL_TYPE_WATCH_STATUS) {
            watch_call_t *wc = (watch_call_t *)base;
            if (wc->active) process_watch_status(aTHX_ wc);
            else cleanup_watch(aTHX_ wc);
        } else if (base->type == CALL_TYPE_WATCH_RECV) {
            watch_call_t *wc = (watch_call_t *)base;

            if (success && wc->active && wc->recv_buffer) {
                    process_watch_response(aTHX_ wc);
                    if (!client->active) return; /* DESTROY called in callback */
                    if (wc->active) {
                        watch_rearm_recv(aTHX_ wc);
                    } else {
                        cleanup_watch(aTHX_ wc);
                    }
                } else if (wc->active) {
                    ev_timer_stop(EV_DEFAULT, &wc->progress_timer);
                    READ_STREAM_STATUS(wc, CALL_TYPE_WATCH_STATUS);
                    process_watch_status(aTHX_ wc);
                } else {
                    cleanup_watch(aTHX_ wc);
                }
            } else if (base->type == CALL_TYPE_WATCH) {
            watch_call_t *wc = (watch_call_t *)base;
            if (success) {
                    /* The setup batch also received the first message */
                    if (wc->recv_buffer && wc->active) {
                        process_watch_response(aTHX_ wc);
                        if (!client->active) return;
                    }
                    if (wc->active) {
                        watch_rearm_recv(aTHX_ wc);
                    } else {
                        cleanup_watch(aTHX_ wc);
                    }
                } else {
                    if (wc->active) {
                        ev_timer_stop(EV_DEFAULT, &wc->progress_timer);
                        READ_STREAM_STATUS(wc, CALL_TYPE_WATCH_STATUS);
                        process_watch_status(aTHX_ wc);
                    } else {
                        cleanup_watch(aTHX_ wc);
                    }
                }
            } else if (base->type == CALL_TYPE_LEASE_KEEPALIVE_STATUS) {
            keepalive_call_t *kc = (keepalive_call_t *)base;
            if (kc->active) process_keepalive_status(aTHX_ kc);
            else cleanup_keepalive(aTHX_ kc);
            } else if (base->type == CALL_TYPE_LEASE_KEEPALIVE_RECV) {
            keepalive_call_t *kc = (keepalive_call_t *)base;

            if (success && kc->active && kc->recv_buffer) {
                    process_keepalive_response(aTHX_ kc);
                    if (!client->active) return;
                    if (kc->active) {
                        keepalive_rearm_recv(aTHX_ kc);
                    } else {
                        cleanup_keepalive(aTHX_ kc);
                    }
                } else if (kc->active) {
                    ev_timer_stop(EV_DEFAULT, &kc->renew_timer);
                    READ_STREAM_STATUS(kc, CALL_TYPE_LEASE_KEEPALIVE_STATUS);
                    process_keepalive_status(aTHX_ kc);
                } else {
                    cleanup_keepalive(aTHX_ kc);
                }
            } else if (base->type == CALL_TYPE_LEASE_KEEPALIVE) {
            keepalive_call_t *kc = (keepalive_call_t *)base;
            if (success) {
                    if (kc->recv_buffer && kc->active) {
                        process_keepalive_response(aTHX_ kc);
                        if (!client->active) return;
                    }
                    if (kc->active) {
                        keepalive_rearm_recv(aTHX_ kc);
                    } else {
                        cleanup_keepalive(aTHX_ kc);
                    }
                } else {
                    if (kc->active) {
                        ev_timer_stop(EV_DEFAULT, &kc->renew_timer);
                        READ_STREAM_STATUS(kc, CALL_TYPE_LEASE_KEEPALIVE_STATUS);
                        process_keepalive_status(aTHX_ kc);
                    } else {
                        cleanup_keepalive(aTHX_ kc);
                    }
                }
            } else if (base->type == CALL_TYPE_ELECTION_OBSERVE_STATUS) {
            observe_call_t *oc = (observe_call_t *)base;
            if (oc->active) process_observe_status(aTHX_ oc);
            else cleanup_observe(aTHX_ oc);
            } else if (base->type == CALL_TYPE_ELECTION_OBSERVE_RECV) {
            observe_call_t *oc = (observe_call_t *)base;

            if (success && oc->active && oc->recv_buffer) {
                    process_observe_response(aTHX_ oc);
                    if (!client->active) return;
                    if (oc->active) {
                        observe_rearm_recv(aTHX_ oc);
                    } else {
                        cleanup_observe(aTHX_ oc);
                    }
                } else if (oc->active) {
                    READ_STREAM_STATUS(oc, CALL_TYPE_ELECTION_OBSERVE_STATUS);
                    process_observe_status(aTHX_ oc);
                } else {
                    cleanup_observe(aTHX_ oc);
                }
            } else if (base->type == CALL_TYPE_ELECTION_OBSERVE) {
            observe_call_t *oc = (observe_call_t *)base;
            if (success) {
                    if (oc->recv_buffer && oc->active) {
                        process_observe_response(aTHX_ oc);
                        if (!client->active) return;
                    }
                    if (oc->active) {
                        observe_rearm_recv(aTHX_ oc);
                    } else {
                        cleanup_observe(aTHX_ oc);
                    }
                } else {
                    if (oc->active) {
                        READ_STREAM_STATUS(oc, CALL_TYPE_ELECTION_OBSERVE_STATUS);
                        process_observe_status(aTHX_ oc);
                    } else {
                        cleanup_observe(aTHX_ oc);
                    }
                }
            } else {
            pending_call_t *pc = (pending_call_t *)base;

            /* Before the handler: a DESTROY from its callback frees what is still listed */
            unlink_pending_call(pc);

            /* Freed at scope end, which an exit() from the callback also reaches */
            ENTER;
            SAVEDESTRUCTOR_X(free_handled_call, pc);

            /* A failed batch can leave the zero-initialised GRPC_STATUS_OK */
            grpc_status_code status = !success && pc->status == GRPC_STATUS_OK
                ? GRPC_STATUS_UNAVAILABLE : pc->status;
            /* Before the callback, so a retry from it reaches the next endpoint */
            etcd_endpoint_failed(client, &pc->base, status, pc->status_details);

            if (success) {
                switch (pc->base.type) {
                        case CALL_TYPE_RANGE:
                            process_range_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_PUT:
                            process_put_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_DELETE:
                            process_delete_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_LEASE_GRANT:
                            process_lease_grant_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_LEASE_REVOKE:
                            process_lease_revoke_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_LEASE_TIME_TO_LIVE:
                            process_lease_time_to_live_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_LEASE_LEASES:
                            process_lease_leases_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_COMPACT:
                            process_compact_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_STATUS:
                            process_status_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_TXN:
                            process_txn_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_AUTH:
                            process_auth_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_USER_ADD:
                            process_user_add_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_USER_DELETE:
                            process_user_delete_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_USER_CHANGE_PASSWORD:
                            process_user_change_password_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_AUTH_ENABLE:
                            process_auth_enable_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_AUTH_DISABLE:
                            process_auth_disable_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_ROLE_ADD:
                            process_role_add_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_ROLE_DELETE:
                            process_role_delete_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_ROLE_GET:
                            process_role_get_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_ROLE_LIST:
                            process_role_list_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_ROLE_GRANT_PERMISSION:
                            process_role_grant_permission_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_ROLE_REVOKE_PERMISSION:
                            process_role_revoke_permission_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_USER_GRANT_ROLE:
                            process_user_grant_role_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_USER_REVOKE_ROLE:
                            process_user_revoke_role_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_USER_GET:
                            process_user_get_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_USER_LIST:
                            process_user_list_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_LOCK:
                            process_lock_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_UNLOCK:
                            process_unlock_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_ELECTION_CAMPAIGN:
                            process_campaign_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_ELECTION_PROCLAIM:
                            process_proclaim_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_ELECTION_LEADER:
                            process_leader_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_ELECTION_RESIGN:
                            process_resign_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_MEMBER_ADD:
                            process_member_add_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_MEMBER_REMOVE:
                            process_member_remove_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_MEMBER_UPDATE:
                            process_member_update_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_MEMBER_LIST:
                            process_member_list_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_MEMBER_PROMOTE:
                            process_member_promote_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_ALARM:
                            process_alarm_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_DEFRAGMENT:
                            process_defragment_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_HASH_KV:
                            process_hash_kv_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_MOVE_LEADER:
                            process_move_leader_response(aTHX_ pc);
                            break;
                        case CALL_TYPE_AUTH_STATUS:
                            process_auth_status_response(aTHX_ pc);
                            break;
                        default:
                            break;
                    }
                } else {
                    CALL_PENDING_ERROR_CALLBACK(pc, status, "grpc_call");
                }
                LEAVE;
            }
}

static SV* response_op_to_hashref(pTHX_ Etcdserverpb__ResponseOp *op) {
    HV *hv = newHV();

    if (op->response_case == ETCDSERVERPB__RESPONSE_OP__RESPONSE_RESPONSE_RANGE) {
        Etcdserverpb__RangeResponse *rr = op->response_range;
        HV *range = newHV();
        add_header_to_hv(aTHX_ range, rr->header);

        AV *kvs = newAV();
        for (size_t i = 0; i < rr->n_kvs; i++) {
            av_push(kvs, kv_to_hashref(aTHX_ rr->kvs[i]));
        }
        hv_store(range, "kvs", 3, newRV_noinc((SV *)kvs), 0);
        hv_store(range, "more", 4, newSViv(rr->more), 0);
        hv_store(range, "count", 5, newSVi64(rr->count), 0);

        hv_store(hv, "response_range", 14, newRV_noinc((SV *)range), 0);
    }
    else if (op->response_case == ETCDSERVERPB__RESPONSE_OP__RESPONSE_RESPONSE_PUT) {
        Etcdserverpb__PutResponse *pr = op->response_put;
        HV *put = newHV();
        add_header_to_hv(aTHX_ put, pr->header);

        if (pr->prev_kv) {
            hv_store(put, "prev_kv", 7, kv_to_hashref(aTHX_ pr->prev_kv), 0);
        }

        hv_store(hv, "response_put", 12, newRV_noinc((SV *)put), 0);
    }
    else if (op->response_case == ETCDSERVERPB__RESPONSE_OP__RESPONSE_RESPONSE_DELETE_RANGE) {
        Etcdserverpb__DeleteRangeResponse *dr = op->response_delete_range;
        HV *del = newHV();
        add_header_to_hv(aTHX_ del, dr->header);

        hv_store(del, "deleted", 7, newSVi64(dr->deleted), 0);

        AV *prev_kvs = newAV();
        for (size_t i = 0; i < dr->n_prev_kvs; i++) {
            av_push(prev_kvs, kv_to_hashref(aTHX_ dr->prev_kvs[i]));
        }
        hv_store(del, "prev_kvs", 8, newRV_noinc((SV *)prev_kvs), 0);

        hv_store(hv, "response_delete_range", 21, newRV_noinc((SV *)del), 0);
    }

    return newRV_noinc((SV *)hv);
}

static HV *txn_op_hash(pTHX_ SV *sv, const char *list, size_t i) {
    if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVHV)
        croak("txn: %s operation %d is not a hash reference", list, (int)i);
    return (HV *)SvRV(sv);
}

/* Before the caller allocates anything, as this croaks; SvCUR is wrong for non-POK */
static void validate_request_ops(pTHX_ SV *src_av, const char *list) {
    SvGETMAGIC(src_av);
    if (!SvOK(src_av)) return;
    if (!SvROK(src_av) || SvTYPE(SvRV(src_av)) != SVt_PVAV)
        croak("txn: %s must be an array reference", list);
    AV *av = (AV *)SvRV(src_av);
    size_t n = av_len(av) + 1;

    #define VALIDATE_HV_KEY(hv_in, name, len_check) do { \
        SV **_f = hv_fetch((hv_in), name, sizeof(name) - 1, 0); \
        if (_f && SvOK(*_f)) { STRLEN _l; (void)SvPV(*_f, _l); len_check(_l); } \
    } while (0)
    for (size_t i = 0; i < n; i++) {
        SV **elem = av_fetch(av, i, 0);
        HV *hv = txn_op_hash(aTHX_ elem ? *elem : &PL_sv_undef, list, i);
        SV **inner;

        VALIDATE_OPTS_KEYS(hv, "txn operation", "request_range", "range",
            "request_put", "put", "request_delete_range", "delete");
        if (HvUSEDKEYS(hv) != 1)
            croak("txn: %s operation %d needs exactly one of put, delete or range", list, (int)i);

        if ((inner = hv_fetch(hv, "request_range", 13, 0)) ||
            (inner = hv_fetch(hv, "range", 5, 0))) {
            HV *ih = txn_op_hash(aTHX_ *inner, list, i);
            VALIDATE_OPTS_KEYS(ih, "txn range", "key", "range_end");
            VALIDATE_HV_KEY(ih, "key", VALIDATE_KEY_SIZE);
            VALIDATE_HV_KEY(ih, "range_end", VALIDATE_KEY_SIZE);
        } else if ((inner = hv_fetch(hv, "request_put", 11, 0)) ||
                   (inner = hv_fetch(hv, "put", 3, 0))) {
            HV *ih = txn_op_hash(aTHX_ *inner, list, i);
            VALIDATE_OPTS_KEYS(ih, "txn put", "key", "value", "lease");
            VALIDATE_HV_KEY(ih, "key", VALIDATE_KEY_SIZE);
            VALIDATE_HV_KEY(ih, "value", VALIDATE_VALUE_SIZE);
        } else {
            inner = hv_fetch(hv, "request_delete_range", 20, 0);
            if (!inner) inner = hv_fetch(hv, "delete", 6, 0);
            HV *ih = txn_op_hash(aTHX_ inner ? *inner : &PL_sv_undef, list, i);
            VALIDATE_OPTS_KEYS(ih, "txn delete", "key", "range_end");
            VALIDATE_HV_KEY(ih, "key", VALIDATE_KEY_SIZE);
            VALIDATE_HV_KEY(ih, "range_end", VALIDATE_KEY_SIZE);
        }
    }
    #undef VALIDATE_HV_KEY
}

static void parse_request_ops(pTHX_ SV *src_av, Etcdserverpb__RequestOp ***dst_ops, size_t *dst_n) {
    *dst_n = 0;
    *dst_ops = NULL;

    if (!SvROK(src_av) || SvTYPE(SvRV(src_av)) != SVt_PVAV) {
        return;
    }

    AV *av = (AV *)SvRV(src_av);
    size_t n = av_len(av) + 1;
    if (n == 0) return;

    Newxz(*dst_ops, n, Etcdserverpb__RequestOp *);
    *dst_n = n;

    for (size_t i = 0; i < n; i++) {
        SV **elem = av_fetch(av, i, 0);
        Newxz((*dst_ops)[i], 1, Etcdserverpb__RequestOp);
        etcdserverpb__request_op__init((*dst_ops)[i]);
        if (!elem || !SvROK(*elem) || SvTYPE(SvRV(*elem)) != SVt_PVHV) continue;

        HV *hv = (HV *)SvRV(*elem);

        SV **range_sv = hv_fetch(hv, "request_range", 13, 0);
        if (!range_sv) range_sv = hv_fetch(hv, "range", 5, 0);
        if (range_sv && SvROK(*range_sv) && SvTYPE(SvRV(*range_sv)) == SVt_PVHV) {
            HV *rh = (HV *)SvRV(*range_sv);
            Etcdserverpb__RangeRequest *rr;
            Newxz(rr, 1, Etcdserverpb__RangeRequest);
            etcdserverpb__range_request__init(rr);

            SV **k = hv_fetch(rh, "key", 3, 0);
            if (k && SvOK(*k)) {
                STRLEN len;
                char *str = SvPV(*k, len);
                rr->key.data = (uint8_t *)str;
                rr->key.len = len;
            }
            SV **re = hv_fetch(rh, "range_end", 9, 0);
            if (re && SvOK(*re)) {
                STRLEN len;
                char *str = SvPV(*re, len);
                rr->range_end.data = (uint8_t *)str;
                rr->range_end.len = len;
            }
            (*dst_ops)[i]->request_case = ETCDSERVERPB__REQUEST_OP__REQUEST_REQUEST_RANGE;
            (*dst_ops)[i]->request_range = rr;
            continue;
        }

        SV **put_sv = hv_fetch(hv, "request_put", 11, 0);
        if (!put_sv) put_sv = hv_fetch(hv, "put", 3, 0);
        if (put_sv && SvROK(*put_sv) && SvTYPE(SvRV(*put_sv)) == SVt_PVHV) {
            HV *ph = (HV *)SvRV(*put_sv);
            Etcdserverpb__PutRequest *pr;
            Newxz(pr, 1, Etcdserverpb__PutRequest);
            etcdserverpb__put_request__init(pr);

            SV **k = hv_fetch(ph, "key", 3, 0);
            if (k && SvOK(*k)) {
                STRLEN len;
                char *str = SvPV(*k, len);
                pr->key.data = (uint8_t *)str;
                pr->key.len = len;
            }
            SV **v = hv_fetch(ph, "value", 5, 0);
            if (v && SvOK(*v)) {
                STRLEN len;
                char *str = SvPV(*v, len);
                pr->value.data = (uint8_t *)str;
                pr->value.len = len;
            }
            SV **l = hv_fetch(ph, "lease", 5, 0);
            if (l && SvOK(*l)) pr->lease = SvI64(*l);

            (*dst_ops)[i]->request_case = ETCDSERVERPB__REQUEST_OP__REQUEST_REQUEST_PUT;
            (*dst_ops)[i]->request_put = pr;
            continue;
        }

        SV **del_sv = hv_fetch(hv, "request_delete_range", 20, 0);
        if (!del_sv) del_sv = hv_fetch(hv, "delete", 6, 0);
        if (del_sv && SvROK(*del_sv) && SvTYPE(SvRV(*del_sv)) == SVt_PVHV) {
            HV *dh = (HV *)SvRV(*del_sv);
            Etcdserverpb__DeleteRangeRequest *dr;
            Newxz(dr, 1, Etcdserverpb__DeleteRangeRequest);
            etcdserverpb__delete_range_request__init(dr);

            SV **k = hv_fetch(dh, "key", 3, 0);
            if (k && SvOK(*k)) {
                STRLEN len;
                char *str = SvPV(*k, len);
                dr->key.data = (uint8_t *)str;
                dr->key.len = len;
            }
            SV **re = hv_fetch(dh, "range_end", 9, 0);
            if (re && SvOK(*re)) {
                STRLEN len;
                char *str = SvPV(*re, len);
                dr->range_end.data = (uint8_t *)str;
                dr->range_end.len = len;
            }
            (*dst_ops)[i]->request_case = ETCDSERVERPB__REQUEST_OP__REQUEST_REQUEST_DELETE_RANGE;
            (*dst_ops)[i]->request_delete_range = dr;
        }
    }
}

static void process_txn_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "txn");

    Etcdserverpb__TxnResponse *resp;
    UNPACK_RESPONSE(pc, resp, etcdserverpb__txn_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);

    hv_store(result, "succeeded", 9, newSViv(resp->succeeded), 0);

    AV *responses = newAV();
    for (size_t i = 0; i < resp->n_responses; i++) {
        av_push(responses, response_op_to_hashref(aTHX_ resp->responses[i]));
    }
    hv_store(result, "responses", 9, newRV_noinc((SV *)responses), 0);

    etcdserverpb__txn_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}

static void clear_auth_token(ev_etcd_t *client) {
    if (!client->auth_token)
        return;
    memset(client->auth_token, 0, client->auth_token_len);
    Safefree(client->auth_token);
    client->auth_token = NULL;
    client->auth_token_len = 0;
}

static void process_auth_response(pTHX_ pending_call_t *pc) {
    /* etcd before 3.4.28/3.5.10 still rejects a token auth_disable invalidated */
    if (pc->status == GRPC_STATUS_FAILED_PRECONDITION
        && grpc_slice_eq(pc->status_details,
            grpc_slice_from_static_string("etcdserver: authentication is not enabled")))
        clear_auth_token(pc->client);
    BEGIN_RESPONSE_HANDLER(pc, "authenticate");

    Etcdserverpb__AuthenticateResponse *resp;
    UNPACK_RESPONSE(pc, resp, etcdserverpb__authenticate_response__unpack);

    ev_etcd_t *client = pc->client;
    if (resp->token) {
        size_t token_len = strlen(resp->token);
        if (token_len > 0) {
            if (token_len > ETCD_MAX_VALUE_SIZE) {
                CALL_STATUS_ERROR_CALLBACK(pc->callback, GRPC_STATUS_INTERNAL, "auth token too large", "authenticate");
                etcdserverpb__authenticate_response__free_unpacked(resp, NULL);
                return;
            }
            clear_auth_token(client);
            client->auth_token_len = token_len;
            Newx(client->auth_token, token_len + 1, char);
            Copy(resp->token, client->auth_token, token_len + 1, char);
        }
    }

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);

    if (resp->token) {
        hv_store(result, "token", 5, newSVpv(resp->token, 0), 0);
    }

    etcdserverpb__authenticate_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}

#define PROCESS_HEADER_ONLY_RESPONSE(func_name, response_type, unpack_func, free_func, source) \
static void func_name(pTHX_ pending_call_t *pc) { \
    BEGIN_RESPONSE_HANDLER(pc, source); \
    \
    response_type *resp; \
    UNPACK_RESPONSE(pc, resp, unpack_func); \
    \
    HV *result = newHV(); \
    add_header_to_hv(aTHX_ result, resp->header); \
    free_func(resp, NULL); \
    \
    CALL_SUCCESS_CALLBACK(pc->callback, result); \
}

PROCESS_HEADER_ONLY_RESPONSE(process_user_add_response,
    Etcdserverpb__AuthUserAddResponse,
    etcdserverpb__auth_user_add_response__unpack,
    etcdserverpb__auth_user_add_response__free_unpacked, "user_add")

PROCESS_HEADER_ONLY_RESPONSE(process_user_delete_response,
    Etcdserverpb__AuthUserDeleteResponse,
    etcdserverpb__auth_user_delete_response__unpack,
    etcdserverpb__auth_user_delete_response__free_unpacked, "user_delete")

PROCESS_HEADER_ONLY_RESPONSE(process_user_change_password_response,
    Etcdserverpb__AuthUserChangePasswordResponse,
    etcdserverpb__auth_user_change_password_response__unpack,
    etcdserverpb__auth_user_change_password_response__free_unpacked, "user_change_password")

PROCESS_HEADER_ONLY_RESPONSE(process_auth_enable_response,
    Etcdserverpb__AuthEnableResponse,
    etcdserverpb__auth_enable_response__unpack,
    etcdserverpb__auth_enable_response__free_unpacked, "auth_enable")

static void process_auth_disable_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "auth_disable");

    Etcdserverpb__AuthDisableResponse *resp;
    UNPACK_RESPONSE(pc, resp, etcdserverpb__auth_disable_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);
    etcdserverpb__auth_disable_response__free_unpacked(resp, NULL);
    clear_auth_token(pc->client);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}

PROCESS_HEADER_ONLY_RESPONSE(process_role_add_response,
    Etcdserverpb__AuthRoleAddResponse,
    etcdserverpb__auth_role_add_response__unpack,
    etcdserverpb__auth_role_add_response__free_unpacked, "role_add")

PROCESS_HEADER_ONLY_RESPONSE(process_role_delete_response,
    Etcdserverpb__AuthRoleDeleteResponse,
    etcdserverpb__auth_role_delete_response__unpack,
    etcdserverpb__auth_role_delete_response__free_unpacked, "role_delete")

PROCESS_HEADER_ONLY_RESPONSE(process_role_grant_permission_response,
    Etcdserverpb__AuthRoleGrantPermissionResponse,
    etcdserverpb__auth_role_grant_permission_response__unpack,
    etcdserverpb__auth_role_grant_permission_response__free_unpacked, "role_grant_permission")

PROCESS_HEADER_ONLY_RESPONSE(process_role_revoke_permission_response,
    Etcdserverpb__AuthRoleRevokePermissionResponse,
    etcdserverpb__auth_role_revoke_permission_response__unpack,
    etcdserverpb__auth_role_revoke_permission_response__free_unpacked, "role_revoke_permission")

PROCESS_HEADER_ONLY_RESPONSE(process_user_grant_role_response,
    Etcdserverpb__AuthUserGrantRoleResponse,
    etcdserverpb__auth_user_grant_role_response__unpack,
    etcdserverpb__auth_user_grant_role_response__free_unpacked, "user_grant_role")

PROCESS_HEADER_ONLY_RESPONSE(process_user_revoke_role_response,
    Etcdserverpb__AuthUserRevokeRoleResponse,
    etcdserverpb__auth_user_revoke_role_response__unpack,
    etcdserverpb__auth_user_revoke_role_response__free_unpacked, "user_revoke_role")

static void process_role_get_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "role_get");

    Etcdserverpb__AuthRoleGetResponse *resp;
    UNPACK_RESPONSE(pc, resp, etcdserverpb__auth_role_get_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);

    AV *perms = newAV();
    for (size_t i = 0; i < resp->n_perm; i++) {
        Etcdserverpb__Permission *p = resp->perm[i];
        HV *perm = newHV();

        const char *perm_type;
        switch (p->permtype) {
            case ETCDSERVERPB__PERMISSION__TYPE__READ: perm_type = "READ"; break;
            case ETCDSERVERPB__PERMISSION__TYPE__WRITE: perm_type = "WRITE"; break;
            case ETCDSERVERPB__PERMISSION__TYPE__READWRITE: perm_type = "READWRITE"; break;
            default: perm_type = "UNKNOWN"; break;
        }
        hv_store(perm, "perm_type", 9, newSVpv(perm_type, 0), 0);

        if (p->key.data) {
            hv_store(perm, "key", 3, newSVpvn((char *)p->key.data, p->key.len), 0);
        }
        if (p->range_end.data) {
            hv_store(perm, "range_end", 9, newSVpvn((char *)p->range_end.data, p->range_end.len), 0);
        }

        av_push(perms, newRV_noinc((SV *)perm));
    }
    hv_store(result, "perm", 4, newRV_noinc((SV *)perms), 0);

    etcdserverpb__auth_role_get_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}

static void process_role_list_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "role_list");

    Etcdserverpb__AuthRoleListResponse *resp;
    UNPACK_RESPONSE(pc, resp, etcdserverpb__auth_role_list_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);

    AV *roles = newAV();
    for (size_t i = 0; i < resp->n_roles; i++) {
        av_push(roles, resp->roles[i] ? newSVpv(resp->roles[i], 0) : newSVpvn("", 0));
    }
    hv_store(result, "roles", 5, newRV_noinc((SV *)roles), 0);

    etcdserverpb__auth_role_list_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}

static void process_user_get_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "user_get");

    Etcdserverpb__AuthUserGetResponse *resp;
    UNPACK_RESPONSE(pc, resp, etcdserverpb__auth_user_get_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);

    AV *roles = newAV();
    for (size_t i = 0; i < resp->n_roles; i++) {
        av_push(roles, resp->roles[i] ? newSVpv(resp->roles[i], 0) : newSVpvn("", 0));
    }
    hv_store(result, "roles", 5, newRV_noinc((SV *)roles), 0);

    etcdserverpb__auth_user_get_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}

static void process_user_list_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "user_list");

    Etcdserverpb__AuthUserListResponse *resp;
    UNPACK_RESPONSE(pc, resp, etcdserverpb__auth_user_list_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);

    AV *users = newAV();
    for (size_t i = 0; i < resp->n_users; i++) {
        av_push(users, resp->users[i] ? newSVpv(resp->users[i], 0) : newSVpvn("", 0));
    }
    hv_store(result, "users", 5, newRV_noinc((SV *)users), 0);

    etcdserverpb__auth_user_list_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}

MODULE = EV::Etcd  PACKAGE = EV::Etcd  PREFIX = ev_etcd_

PROTOTYPES: DISABLE

BOOT:
    I_EV_API("EV::Etcd");
    watch_init_ev_api(aTHX);
    lease_init_ev_api(aTHX);
    election_init_ev_api(aTHX);
    init_method_slices();
    ev_etcd_pid = getpid();
    pthread_atfork(ev_etcd_atfork_prepare, NULL, ev_etcd_atfork_child);

SV *
ev_etcd_new(class, ...)
    char *class
CODE:
{
    ev_etcd_t *client;
    AV *endpoints_av = NULL;
    int timeout_seconds = 30;
    int max_retries = 30;
    NV health_interval = 0;
    NV keepalive_time = 10, keepalive_timeout = 10;
    SV *health_callback = NULL;
    char *init_auth_token = NULL;
    STRLEN init_auth_token_len = 0;
    int tls = 0, saw_http = 0;
    const char *tls_ca_file = NULL, *tls_cert_file = NULL, *tls_key_file = NULL;
    const char *tls_server_name = NULL;
    SV *ca_pem = NULL, *cert_pem = NULL, *key_pem = NULL;
    int i;

    if ((items - 1) % 2) croak("Odd number of options in EV::Etcd->new");

    for (i = 1; i < items; i += 2) {
        if (i + 1 < items) {
            const char *key = SvPV_nolen(ST(i));
            SV *val = ST(i + 1);
            SvGETMAGIC(val);
            if (strEQ(key, "endpoints")) {
                if (SvOK(val)) {
                    if (!SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVAV)
                        croak("EV::Etcd: endpoints must be an array reference");
                    endpoints_av = (AV *)sv_2mortal(SvREFCNT_inc(SvRV(val)));
                    if (av_len(endpoints_av) < 0)
                        croak("EV::Etcd: endpoints is empty");
                }
            } else if (strEQ(key, "timeout")) {
                if (SvOK(val)) {
                    IV v = SvIV_nomg(val);
                    timeout_seconds = v < 1 ? 1 : v > INT_MAX ? INT_MAX : (int)v;
                }
            } else if (strEQ(key, "max_retries")) {
                if (SvOK(val)) {
                    IV v = SvIV_nomg(val);
                    max_retries = v < 0 ? 0 : v > INT_MAX ? INT_MAX : (int)v;
                }
            } else if (strEQ(key, "health_interval")) {
                if (SvOK(val)) {
                    health_interval = SvNV_nomg(val);
                    if (!(health_interval > 0)) {
                        health_interval = 0;
                    }
                }
            } else if (strEQ(key, "on_health_change")) {
                if (SvOK(val)) {
                    if (!SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVCV)
                        croak("EV::Etcd: on_health_change must be a code reference");
                    health_callback = sv_2mortal(newRV_inc(SvRV(val)));
                }
            } else if (strEQ(key, "auth_token")) {
                if (SvOK(val)) {
                    STRLEN j;
                    init_auth_token = option_pv(aTHX_ val, &init_auth_token_len);
                    /* gRPC rejects other bytes in metadata, failing every call */
                    for (j = 0; j < init_auth_token_len; j++) {
                        if (init_auth_token[j] < 0x20 || init_auth_token[j] > 0x7E)
                            croak("EV::Etcd: auth_token must be printable ASCII");
                    }
                }
            } else if (strEQ(key, "tls")) {
                tls = SvTRUE_nomg(val);
            } else if (strEQ(key, "tls_ca_file")) {
                if (SvOK(val)) tls_ca_file = option_pv(aTHX_ val, NULL);
            } else if (strEQ(key, "tls_cert_file")) {
                if (SvOK(val)) tls_cert_file = option_pv(aTHX_ val, NULL);
            } else if (strEQ(key, "tls_key_file")) {
                if (SvOK(val)) tls_key_file = option_pv(aTHX_ val, NULL);
            } else if (strEQ(key, "tls_server_name")) {
                if (SvOK(val)) tls_server_name = option_pv(aTHX_ val, NULL);
            } else if (strEQ(key, "keepalive_time")) {
                if (SvOK(val)) keepalive_time = SvNV_nomg(val);
            } else if (strEQ(key, "keepalive_timeout")) {
                if (SvOK(val)) keepalive_timeout = SvNV_nomg(val);
            } else {
                croak("Unknown option '%s' in EV::Etcd->new", key);
            }
        }
    }

    /* Only these copies are used: a tied array could hand back something else */
    AV *checked = NULL;
    if (endpoints_av && av_len(endpoints_av) >= 0) {
        int count = av_len(endpoints_av) + 1;
        checked = (AV *)sv_2mortal((SV *)newAV());
        for (i = 0; i < count; i++) {
            SV **ep = av_fetch(endpoints_av, i, 0);
            STRLEN len;
            const char *str;
            int is_https, skip;
            if (ep)
                SvGETMAGIC(*ep);
            if (!ep || !SvOK(*ep))
                croak("EV::Etcd: endpoints element %d is undefined", i);
            str = SvPV_nomg(*ep, len);
            VALIDATE_URL_SIZE(len);
            VALIDATE_NO_NUL(str, len, "endpoint");
            skip = endpoint_scheme_len(str, &is_https);
            if (len <= (STRLEN)skip)
                croak("EV::Etcd: endpoints element %d is empty", i);
            av_push(checked, newSVpvn(str + skip, len - skip));
            if (!skip)
                continue;
            if (is_https)
                tls = 1;
            else
                saw_http = 1;
        }
    }

    if (tls_ca_file || tls_cert_file || tls_key_file || tls_server_name)
        tls = 1;
    if (tls && saw_http)
        croak("EV::Etcd: http:// endpoint on a TLS client");
    if (!tls_cert_file != !tls_key_file)
        croak("EV::Etcd: tls_cert_file and tls_key_file must be given together");
    if (tls_ca_file) ca_pem = slurp_pem(aTHX_ "tls_ca_file", tls_ca_file);
    if (tls_cert_file) cert_pem = slurp_pem(aTHX_ "tls_cert_file", tls_cert_file);
    if (tls_key_file) key_pem = slurp_pem(aTHX_ "tls_key_file", tls_key_file);

    /* Its fork-safety croak must come before anything is allocated */
    grpc_acquire(aTHX);
    Newxz(client, 1, ev_etcd_t);

    if (checked) {
        int count = av_len(checked) + 1;
        Newx(client->endpoints, count, char *);
        client->endpoint_count = count;
        for (i = 0; i < count; i++) {
            SV *ep = *av_fetch(checked, i, 0);
            client->endpoints[i] = savepvn(SvPVX(ep), SvCUR(ep));
        }
    } else {
        Newx(client->endpoints, 1, char *);
        client->endpoints[0] = savepv("127.0.0.1:2379");
        client->endpoint_count = 1;
    }
    client->current_endpoint = 0;
    client->keepalive_ms = seconds_to_ms(keepalive_time);
    client->keepalive_timeout_ms = seconds_to_ms(keepalive_timeout);
    if (!client->keepalive_timeout_ms)
        client->keepalive_timeout_ms = 10000;

    if (tls) {
        grpc_ssl_pem_key_cert_pair pair;
        if (cert_pem) {
            pair.private_key = SvPV_nolen(key_pem);
            pair.cert_chain = SvPV_nolen(cert_pem);
        }
        client->creds = grpc_ssl_credentials_create(
            ca_pem ? SvPV_nolen(ca_pem) : NULL, cert_pem ? &pair : NULL, NULL, NULL);
        if (!client->creds) {
            for (int j = 0; j < client->endpoint_count; j++) {
                Safefree(client->endpoints[j]);
            }
            Safefree(client->endpoints);
            Safefree(client);
            grpc_release();
            croak("EV::Etcd: failed to create TLS credentials");
        }
        if (key_pem)
            memset(SvPVX(key_pem), 0, SvCUR(key_pem));
        if (tls_server_name)
            client->tls_server_name = savepv(tls_server_name);
    }

    client->channel_ref = etcd_create_channel(client, client->endpoints[0]);

    if (!client->channel_ref) {
        for (int j = 0; j < client->endpoint_count; j++) {
            Safefree(client->endpoints[j]);
        }
        Safefree(client->endpoints);
        if (client->creds) grpc_channel_credentials_release(client->creds);
        Safefree(client->tls_server_name);
        Safefree(client);
        grpc_release();
        croak("Failed to create gRPC channel");
    }
    client->channel = client->channel_ref->channel;

    client->cq = grpc_completion_queue_create_for_next(NULL);

    pthread_mutex_init(&client->queue_mutex, NULL);

    ev_async_init(&client->cq_async, cq_async_callback);
    ev_async_start(EV_DEFAULT, &client->cq_async);

    int thread_error;
    WITH_SIGNALS_BLOCKED(thread_error = pthread_create(&client->cq_thread, NULL, cq_thread_func, client));
    if (thread_error) {
        ev_async_stop(EV_DEFAULT, &client->cq_async);
        pthread_mutex_destroy(&client->queue_mutex);
        grpc_completion_queue_shutdown(client->cq);
        while (grpc_completion_queue_next(client->cq,
               gpr_inf_past(GPR_CLOCK_REALTIME), NULL).type != GRPC_QUEUE_SHUTDOWN)
            ;
        grpc_completion_queue_destroy(client->cq);
        etcd_channel_release(client->channel_ref, 1);
        for (int j = 0; j < client->endpoint_count; j++) {
            Safefree(client->endpoints[j]);
        }
        Safefree(client->endpoints);
        if (client->creds) grpc_channel_credentials_release(client->creds);
        Safefree(client->tls_server_name);
        Safefree(client);
        grpc_release();
        croak("Failed to create gRPC completion queue thread");
    }

    if (init_auth_token && init_auth_token_len > 0) {
        Newx(client->auth_token, init_auth_token_len + 1, char);
        Copy(init_auth_token, client->auth_token, init_auth_token_len, char);
        client->auth_token[init_auth_token_len] = '\0';
        client->auth_token_len = init_auth_token_len;
    }
    client->timeout_seconds = timeout_seconds;
    client->active = 1;
    client->owner_pid = ev_etcd_pid;
    client->next_live = ev_etcd_clients;
    ev_etcd_clients = client;
    client->max_retries = max_retries;
    client->is_healthy = 1;
    if (health_callback)
        client->health_callback = newSVsv(health_callback);

    ev_timer_init(&client->health_timer, health_timer_callback, 0.0, 0.0);

    if (health_interval > 0) {
        ev_timer_set(&client->health_timer, health_interval, health_interval);
        ev_timer_start(EV_DEFAULT, &client->health_timer);
    }

    RETVAL = sv_setref_pv(newSV(0),
        sv_isobject(ST(0)) ? sv_reftype(SvRV(ST(0)), TRUE) : class, (void *)client);
}
OUTPUT:
    RETVAL

void
ev_etcd_get(client, key, ...)
    EV::Etcd client
    SV *key
CODE:
{
    SV *opts = NULL;
    SV *callback;

    if (items == 3) {
        callback = ST(2);
    } else if (items == 4) {
        opts = opts_arg(aTHX_ ST(2));
        callback = ST(3);
    } else {
        croak("Usage: $client->get($key, [\\%%opts,] $callback)");
    }

    VALIDATE_CALLBACK(callback);

    STRLEN key_len;
    const char *key_str = SvPV(key, key_len);
    VALIDATE_KEY_SIZE(key_len);

    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        SV **svp;
        VALIDATE_OPTS_KEYS((HV *)SvRV(opts), "get", "range_end", "prefix", "limit",
            "revision", "keys_only", "count_only", "serializable", "sort_order",
            "sort_target", "min_mod_revision", "max_mod_revision",
            "min_create_revision", "max_create_revision");
        if ((svp = hv_fetchs((HV *)SvRV(opts), "range_end", 0)) && SvOK(*svp)) {
            STRLEN _l;
            (void)SvPV(*svp, _l);
            VALIDATE_KEY_SIZE(_l);
        }
        if ((svp = hv_fetchs((HV *)SvRV(opts), "sort_order", 0)) && SvOK(*svp)) {
            const char *order = SvPV_nolen(*svp);
            if (!(strEQ(order, "ascend") || strEQ(order, "ASCEND")
                || strEQ(order, "descend") || strEQ(order, "DESCEND"))) {
                croak("Invalid sort_order: %s (expected ascend or descend)", order);
            }
        }
        if ((svp = hv_fetchs((HV *)SvRV(opts), "sort_target", 0)) && SvOK(*svp)) {
            const char *target = SvPV_nolen(*svp);
            if (!(strEQ(target, "key") || strEQ(target, "KEY")
                || strEQ(target, "version") || strEQ(target, "VERSION")
                || strEQ(target, "create") || strEQ(target, "CREATE")
                || strEQ(target, "mod") || strEQ(target, "MOD")
                || strEQ(target, "value") || strEQ(target, "VALUE"))) {
                croak("Invalid sort_target: %s (expected key, version, create, mod, or value)", target);
            }
        }
    }

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_RANGE, client);

    Etcdserverpb__RangeRequest req = ETCDSERVERPB__RANGE_REQUEST__INIT;
    req.key.data = (uint8_t *)key_str;
    req.key.len = key_len;

    char *range_end_copy = NULL;

    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        HV *hv = (HV *)SvRV(opts);
        SV **svp;

        if ((svp = hv_fetchs(hv, "range_end", 0)) && SvOK(*svp)) {
            STRLEN range_end_len;
            const char *range_end_str = SvPV(*svp, range_end_len);
            Newx(range_end_copy, range_end_len, char);
            memcpy(range_end_copy, range_end_str, range_end_len);
            req.range_end.data = (uint8_t *)range_end_copy;
            req.range_end.len = range_end_len;
        }

        if ((svp = hv_fetchs(hv, "prefix", 0)) && SvTRUE(*svp)) {
            if (!range_end_copy) {
                size_t range_len;
                range_end_copy = compute_prefix_range_end(key_str, key_len, &range_len);
                req.range_end.data = (uint8_t *)range_end_copy;
                req.range_end.len = range_len;
                if (!key_len) {
                    /* etcd rejects an empty key: "\0" up to "\0" is every key */
                    req.key.data = (uint8_t *)"";
                    req.key.len = 1;
                }
            }
        }

        if ((svp = hv_fetchs(hv, "limit", 0)) && SvOK(*svp)) {
            req.limit = SvI64(*svp);
        }

        if ((svp = hv_fetchs(hv, "revision", 0)) && SvOK(*svp)) {
            req.revision = SvI64(*svp);
        }

        if ((svp = hv_fetchs(hv, "keys_only", 0)) && SvTRUE(*svp)) {
            req.keys_only = 1;
        }

        if ((svp = hv_fetchs(hv, "count_only", 0)) && SvTRUE(*svp)) {
            req.count_only = 1;
        }

        if ((svp = hv_fetchs(hv, "serializable", 0)) && SvTRUE(*svp)) {
            req.serializable = 1;
        }

        if ((svp = hv_fetchs(hv, "sort_order", 0)) && SvOK(*svp)) {
            const char *order = SvPV_nolen(*svp);
            if (strEQ(order, "ascend") || strEQ(order, "ASCEND")) {
                req.sort_order = ETCDSERVERPB__RANGE_REQUEST__SORT_ORDER__ASCEND;
            } else if (strEQ(order, "descend") || strEQ(order, "DESCEND")) {
                req.sort_order = ETCDSERVERPB__RANGE_REQUEST__SORT_ORDER__DESCEND;
            }
        }

        if ((svp = hv_fetchs(hv, "sort_target", 0)) && SvOK(*svp)) {
            const char *target = SvPV_nolen(*svp);
            if (strEQ(target, "version") || strEQ(target, "VERSION")) {
                req.sort_target = ETCDSERVERPB__RANGE_REQUEST__SORT_TARGET__VERSION;
            } else if (strEQ(target, "create") || strEQ(target, "CREATE")) {
                req.sort_target = ETCDSERVERPB__RANGE_REQUEST__SORT_TARGET__CREATE;
            } else if (strEQ(target, "mod") || strEQ(target, "MOD")) {
                req.sort_target = ETCDSERVERPB__RANGE_REQUEST__SORT_TARGET__MOD;
            } else if (strEQ(target, "value") || strEQ(target, "VALUE")) {
                req.sort_target = ETCDSERVERPB__RANGE_REQUEST__SORT_TARGET__VALUE;
            } else if (strEQ(target, "key") || strEQ(target, "KEY")) {
                req.sort_target = ETCDSERVERPB__RANGE_REQUEST__SORT_TARGET__KEY;
            }
        }

        if ((svp = hv_fetchs(hv, "min_mod_revision", 0)) && SvOK(*svp)) {
            req.min_mod_revision = SvI64(*svp);
        }

        if ((svp = hv_fetchs(hv, "max_mod_revision", 0)) && SvOK(*svp)) {
            req.max_mod_revision = SvI64(*svp);
        }

        if ((svp = hv_fetchs(hv, "min_create_revision", 0)) && SvOK(*svp)) {
            req.min_create_revision = SvI64(*svp);
        }

        if ((svp = hv_fetchs(hv, "max_create_revision", 0)) && SvOK(*svp)) {
            req.max_create_revision = SvI64(*svp);
        }
    }

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__range_request__get_packed_size,
        etcdserverpb__range_request__pack, &req);
    if (range_end_copy) {
        Safefree(range_end_copy);
    }
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel,
        NULL,
        GRPC_PROPAGATE_DEFAULTS,
        client->cq,
        METHOD_KV_RANGE,
        NULL,
        deadline,
        NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for range");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);

    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;

    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;

    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;

    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;

    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);

    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_put(client, key, value, ...)
    EV::Etcd client
    SV *key
    SV *value
CODE:
{
    SV *opts = NULL;
    SV *callback;

    if (items == 4) {
        callback = ST(3);
    } else if (items == 5) {
        opts = opts_arg(aTHX_ ST(3));
        callback = ST(4);
    } else {
        croak("Usage: $client->put($key, $value, [\\%%opts,] $callback)");
    }

    VALIDATE_CALLBACK(callback);

    STRLEN key_len, value_len;
    const char *key_str = SvPV(key, key_len);
    const char *value_str = SvPV(value, value_len);
    VALIDATE_KEY_SIZE(key_len);
    VALIDATE_VALUE_SIZE(value_len);

    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        VALIDATE_OPTS_KEYS((HV *)SvRV(opts), "put", "lease", "prev_kv",
            "ignore_value", "ignore_lease");
    }

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_PUT, client);

    Etcdserverpb__PutRequest req = ETCDSERVERPB__PUT_REQUEST__INIT;
    req.key.data = (uint8_t *)key_str;
    req.key.len = key_len;
    req.value.data = (uint8_t *)value_str;
    req.value.len = value_len;

    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        HV *hv = (HV *)SvRV(opts);
        SV **svp;

        if ((svp = hv_fetchs(hv, "lease", 0)) && SvOK(*svp)) {
            req.lease = SvI64(*svp);
        }

        if ((svp = hv_fetchs(hv, "prev_kv", 0)) && SvTRUE(*svp)) {
            req.prev_kv = 1;
        }

        if ((svp = hv_fetchs(hv, "ignore_value", 0)) && SvTRUE(*svp)) {
            req.ignore_value = 1;
        }

        if ((svp = hv_fetchs(hv, "ignore_lease", 0)) && SvTRUE(*svp)) {
            req.ignore_lease = 1;
        }
    }

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__put_request__get_packed_size,
        etcdserverpb__put_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel,
        NULL,
        GRPC_PROPAGATE_DEFAULTS,
        client->cq,
        METHOD_KV_PUT,
        NULL,
        deadline,
        NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for put");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);

    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;

    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;

    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;

    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;

    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);

    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_delete(client, key, ...)
    EV::Etcd client
    SV *key
CODE:
{
    SV *opts = NULL;
    SV *callback;

    if (items == 3) {
        callback = ST(2);
    } else if (items == 4) {
        opts = opts_arg(aTHX_ ST(2));
        callback = ST(3);
    } else {
        croak("Usage: $client->delete($key, [\\%%opts,] $callback)");
    }

    VALIDATE_CALLBACK(callback);

    STRLEN key_len;
    const char *key_str = SvPV(key, key_len);
    VALIDATE_KEY_SIZE(key_len);

    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        SV **svp;
        VALIDATE_OPTS_KEYS((HV *)SvRV(opts), "delete", "range_end", "prefix", "prev_kv");
        if ((svp = hv_fetchs((HV *)SvRV(opts), "range_end", 0)) && SvOK(*svp)) {
            STRLEN _l;
            (void)SvPV(*svp, _l);
            VALIDATE_KEY_SIZE(_l);
        }
    }

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_DELETE, client);

    Etcdserverpb__DeleteRangeRequest req = ETCDSERVERPB__DELETE_RANGE_REQUEST__INIT;
    req.key.data = (uint8_t *)key_str;
    req.key.len = key_len;

    char *range_end_copy = NULL;

    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        HV *hv = (HV *)SvRV(opts);
        SV **svp;

        if ((svp = hv_fetchs(hv, "range_end", 0)) && SvOK(*svp)) {
            STRLEN range_end_len;
            const char *range_end_str = SvPV(*svp, range_end_len);
            Newx(range_end_copy, range_end_len, char);
            memcpy(range_end_copy, range_end_str, range_end_len);
            req.range_end.data = (uint8_t *)range_end_copy;
            req.range_end.len = range_end_len;
        }

        if ((svp = hv_fetchs(hv, "prefix", 0)) && SvTRUE(*svp)) {
            if (!range_end_copy) {
                size_t range_len;
                range_end_copy = compute_prefix_range_end(key_str, key_len, &range_len);
                req.range_end.data = (uint8_t *)range_end_copy;
                req.range_end.len = range_len;
                if (!key_len) {
                    req.key.data = (uint8_t *)"";
                    req.key.len = 1;
                }
            }
        }

        if ((svp = hv_fetchs(hv, "prev_kv", 0)) && SvTRUE(*svp)) {
            req.prev_kv = 1;
        }
    }

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__delete_range_request__get_packed_size,
        etcdserverpb__delete_range_request__pack, &req);
    if (range_end_copy) {
        Safefree(range_end_copy);
    }
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel,
        NULL,
        GRPC_PROPAGATE_DEFAULTS,
        client->cq,
        METHOD_KV_DELETE,
        NULL,
        deadline,
        NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for delete");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);

    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;

    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;

    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;

    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;

    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);

    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

EV::Etcd::Watch
ev_etcd_watch(client, key, ...)
    EV::Etcd client
    SV *key
CODE:
{
    SV *opts = NULL;
    SV *callback;

    if (items == 3) {
        callback = ST(2);
    } else if (items == 4) {
        opts = opts_arg(aTHX_ ST(2));
        callback = ST(3);
    } else {
        croak("Usage: $client->watch($key, [\\%%opts,] $callback)");
    }

    VALIDATE_CALLBACK(callback);

    STRLEN key_len;
    const char *key_str = SvPV(key, key_len);
    VALIDATE_KEY_SIZE(key_len);

    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        VALIDATE_OPTS_KEYS((HV *)SvRV(opts), "watch", "auto_reconnect", "range_end",
            "prefix", "start_revision", "progress_notify", "prev_kv", "watch_id");
        SV **svp = hv_fetchs((HV *)SvRV(opts), "range_end", 0);
        if (svp && SvOK(*svp)) {
            STRLEN re_len;
            (void)SvPV(*svp, re_len);
            VALIDATE_KEY_SIZE(re_len);
        }
    }

    watch_call_t *wc;
    Newxz(wc, 1, watch_call_t);
    init_call_base(&wc->base, CALL_TYPE_WATCH);
    wc->base.owner_pid = client->owner_pid;
    wc->client = client;
    wc->active = 1;
    wc->watch_id = -1;
    wc->auto_reconnect = 1;
    wc->client_owns = 1;
    wc->perl_owns = 1;
    grpc_metadata_array_init(&wc->initial_metadata);
    grpc_metadata_array_init(&wc->trailing_metadata);
    wc->status_details = grpc_empty_slice();

    Newx(wc->params.key, key_len + 1, char);
    Copy(key_str, wc->params.key, key_len, char);
    wc->params.key[key_len] = '\0';
    wc->params.key_len = key_len;

    Etcdserverpb__WatchCreateRequest create_req = ETCDSERVERPB__WATCH_CREATE_REQUEST__INIT;
    create_req.key.data = (uint8_t *)key_str;
    create_req.key.len = key_len;

    char *range_end_copy = NULL;

    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        HV *hv = (HV *)SvRV(opts);
        SV **svp;

        if ((svp = hv_fetchs(hv, "auto_reconnect", 0))) {
            wc->auto_reconnect = SvTRUE(*svp) ? 1 : 0;
        }

        if ((svp = hv_fetchs(hv, "range_end", 0)) && SvOK(*svp)) {
            STRLEN range_end_len;
            const char *range_end_str = SvPV(*svp, range_end_len);
            Newx(range_end_copy, range_end_len, char);
            memcpy(range_end_copy, range_end_str, range_end_len);
            create_req.range_end.data = (uint8_t *)range_end_copy;
            create_req.range_end.len = range_end_len;
            Newx(wc->params.range_end, range_end_len + 1, char);
            Copy(range_end_str, wc->params.range_end, range_end_len, char);
            wc->params.range_end[range_end_len] = '\0';
            wc->params.range_end_len = range_end_len;
        }

        if ((svp = hv_fetchs(hv, "prefix", 0)) && SvTRUE(*svp)) {
            if (!range_end_copy) {
                size_t range_len;
                range_end_copy = compute_prefix_range_end(key_str, key_len, &range_len);
                create_req.range_end.data = (uint8_t *)range_end_copy;
                create_req.range_end.len = range_len;
                Newx(wc->params.range_end, range_len + 1, char);
                Copy(range_end_copy, wc->params.range_end, range_len, char);
                wc->params.range_end[range_len] = '\0';
                wc->params.range_end_len = range_len;
                if (!key_len) {
                    /* params.key holds its terminating NUL */
                    create_req.key.data = (uint8_t *)wc->params.key;
                    create_req.key.len = wc->params.key_len = 1;
                }
            }
        }

        if ((svp = hv_fetchs(hv, "start_revision", 0)) && SvOK(*svp)) {
            create_req.start_revision = SvI64(*svp);
            wc->params.start_revision = create_req.start_revision;
            if (create_req.start_revision > 0)
                wc->last_revision = create_req.start_revision - 1;
        }

        if ((svp = hv_fetchs(hv, "progress_notify", 0)) && SvTRUE(*svp)) {
            create_req.progress_notify = 1;
            wc->params.progress_notify = 1;
        }

        if ((svp = hv_fetchs(hv, "prev_kv", 0)) && SvTRUE(*svp)) {
            create_req.prev_kv = 1;
            wc->params.prev_kv = 1;
        }

        if ((svp = hv_fetchs(hv, "watch_id", 0)) && SvOK(*svp)) {
            create_req.watch_id = SvI64(*svp);
            wc->params.watch_id = create_req.watch_id;
            wc->params.has_watch_id = 1;
        }
    }

    Etcdserverpb__WatchRequest req = ETCDSERVERPB__WATCH_REQUEST__INIT;
    req.request_union_case = ETCDSERVERPB__WATCH_REQUEST__REQUEST_UNION_CREATE_REQUEST;
    req.create_request = &create_req;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__watch_request__get_packed_size,
        etcdserverpb__watch_request__pack, &req);
    if (range_end_copy) Safefree(range_end_copy);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_inf_future(GPR_CLOCK_REALTIME);

    wc->callback = newSVsv(callback);
    etcd_call_acquire(client, &wc->base);
    wc->call = grpc_channel_create_call(
        client->channel,
        NULL,
        GRPC_PROPAGATE_DEFAULTS,
        client->cq,
        METHOD_WATCH,
        NULL,
        deadline,
        NULL
    );

    if (!wc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        etcd_call_release(&wc->base);
        grpc_metadata_array_destroy(&wc->initial_metadata);
        grpc_metadata_array_destroy(&wc->trailing_metadata);
        grpc_slice_unref(wc->status_details);
        SvREFCNT_dec(wc->callback);
        if (wc->params.key) Safefree(wc->params.key);
        if (wc->params.range_end) Safefree(wc->params.range_end);
        Safefree(wc);
        croak("Failed to create gRPC call for watch");
    }

    grpc_op ops[4] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_stream_metadata(client, &ops[0], &wc->base);

    ops[1].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[1].data.recv_initial_metadata.recv_initial_metadata = &wc->initial_metadata;

    ops[2].op = GRPC_OP_SEND_MESSAGE;
    ops[2].data.send_message.send_message = send_buffer;

    /* The first response is the WatchResponse with created=true */
    ops[3].op = GRPC_OP_RECV_MESSAGE;
    ops[3].data.recv_message.recv_message = &wc->recv_buffer;

    /* Stream end surfaces as a NULL RECV; read its status then. */
    grpc_call_error err = grpc_call_start_batch(wc->call, ops, 4, &wc->base, NULL);

    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        grpc_metadata_array_destroy(&wc->initial_metadata);
        grpc_metadata_array_destroy(&wc->trailing_metadata);
        grpc_slice_unref(wc->status_details);
        grpc_call_unref(wc->call);
        etcd_call_release(&wc->base);
        SvREFCNT_dec(wc->callback);
        if (wc->params.key) {
            Safefree(wc->params.key);
        }
        if (wc->params.range_end) {
            Safefree(wc->params.range_end);
        }
        Safefree(wc);
        /* range_end_copy was already freed after serializing */
        croak("Failed to start watch call: %d", err);
    }

    wc->next = client->watches;
    client->watches = wc;

    RETVAL = wc;
}
OUTPUT:
    RETVAL

void
ev_etcd_lease_grant(client, ttl, callback)
    EV::Etcd client
    int64_t ttl
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_LEASE_GRANT, client);

    Etcdserverpb__LeaseGrantRequest req = ETCDSERVERPB__LEASE_GRANT_REQUEST__INIT;
    req.ttl = ttl;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__lease_grant_request__get_packed_size,
        etcdserverpb__lease_grant_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel,
        NULL,
        GRPC_PROPAGATE_DEFAULTS,
        client->cq,
        METHOD_LEASE_GRANT,
        NULL,
        deadline,
        NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for lease_grant");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);

    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;

    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;

    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;

    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;

    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);

    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_lease_revoke(client, lease_id, callback)
    EV::Etcd client
    int64_t lease_id
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_LEASE_REVOKE, client);

    Etcdserverpb__LeaseRevokeRequest req = ETCDSERVERPB__LEASE_REVOKE_REQUEST__INIT;
    req.id = lease_id;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__lease_revoke_request__get_packed_size,
        etcdserverpb__lease_revoke_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel,
        NULL,
        GRPC_PROPAGATE_DEFAULTS,
        client->cq,
        METHOD_LEASE_REVOKE,
        NULL,
        deadline,
        NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for lease_revoke");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);

    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;

    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;

    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;

    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;

    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);

    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_lease_time_to_live(client, lease_id, ...)
    EV::Etcd client
    int64_t lease_id
CODE:
{
    SV *opts = NULL;
    SV *callback;

    if (items == 3) {
        callback = ST(2);
    } else if (items == 4) {
        opts = opts_arg(aTHX_ ST(2));
        callback = ST(3);
    } else {
        croak("Usage: $client->lease_time_to_live($lease_id, [\\%%opts,] $callback)");
    }

    VALIDATE_CALLBACK(callback);

    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        VALIDATE_OPTS_KEYS((HV *)SvRV(opts), "lease_time_to_live", "keys");
    }

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_LEASE_TIME_TO_LIVE, client);

    Etcdserverpb__LeaseTimeToLiveRequest req = ETCDSERVERPB__LEASE_TIME_TO_LIVE_REQUEST__INIT;
    req.id = lease_id;

    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        HV *hv = (HV *)SvRV(opts);
        SV **svp;

        if ((svp = hv_fetchs(hv, "keys", 0)) && SvTRUE(*svp)) {
            req.keys = 1;
        }
    }

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__lease_time_to_live_request__get_packed_size,
        etcdserverpb__lease_time_to_live_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel,
        NULL,
        GRPC_PROPAGATE_DEFAULTS,
        client->cq,
        METHOD_LEASE_TTL,
        NULL,
        deadline,
        NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for lease_ttl");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);

    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;

    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;

    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;

    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;

    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);

    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_lease_leases(client, callback)
    EV::Etcd client
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_LEASE_LEASES, client);

    Etcdserverpb__LeaseLeasesRequest req = ETCDSERVERPB__LEASE_LEASES_REQUEST__INIT;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__lease_leases_request__get_packed_size,
        etcdserverpb__lease_leases_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel,
        NULL,
        GRPC_PROPAGATE_DEFAULTS,
        client->cq,
        METHOD_LEASE_LEASES,
        NULL,
        deadline,
        NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for lease_leases");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);

    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;

    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;

    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;

    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;

    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);

    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_compact(client, revision, ...)
    EV::Etcd client
    int64_t revision
CODE:
{
    SV *opts = NULL;
    SV *callback;

    if (items == 3) {
        callback = ST(2);
    } else if (items == 4) {
        opts = opts_arg(aTHX_ ST(2));
        callback = ST(3);
    } else {
        croak("Usage: $client->compact($revision, [\\%%opts,] $callback)");
    }

    VALIDATE_CALLBACK(callback);

    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        VALIDATE_OPTS_KEYS((HV *)SvRV(opts), "compact", "physical");
    }

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_COMPACT, client);

    Etcdserverpb__CompactionRequest req = ETCDSERVERPB__COMPACTION_REQUEST__INIT;
    req.revision = revision;

    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        HV *hv = (HV *)SvRV(opts);
        SV **svp;

        if ((svp = hv_fetchs(hv, "physical", 0)) && SvTRUE(*svp)) {
            req.physical = 1;
        }
    }

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__compaction_request__get_packed_size,
        etcdserverpb__compaction_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel,
        NULL,
        GRPC_PROPAGATE_DEFAULTS,
        client->cq,
        METHOD_KV_COMPACT,
        NULL,
        deadline,
        NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for compact");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);

    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;

    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;

    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;

    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;

    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);

    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_status(client, callback)
    EV::Etcd client
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_STATUS, client);

    Etcdserverpb__StatusRequest req = ETCDSERVERPB__STATUS_REQUEST__INIT;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__status_request__get_packed_size,
        etcdserverpb__status_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel,
        NULL,
        GRPC_PROPAGATE_DEFAULTS,
        client->cq,
        METHOD_MAINTENANCE_STATUS,
        NULL,
        deadline,
        NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for status");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);

    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;

    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;

    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;

    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;

    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);

    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

EV::Etcd::Keepalive
ev_etcd_lease_keepalive(client, lease_id, ...)
    EV::Etcd client
    int64_t lease_id
CODE:
{
    SV *opts = NULL;
    SV *callback;

    if (items == 3) {
        callback = ST(2);
    } else if (items == 4) {
        opts = opts_arg(aTHX_ ST(2));
        callback = ST(3);
    } else {
        croak("Usage: $client->lease_keepalive($lease_id, [\\%%opts,] $callback)");
    }

    VALIDATE_CALLBACK(callback);

    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        VALIDATE_OPTS_KEYS((HV *)SvRV(opts), "lease_keepalive", "auto_reconnect");
    }

    keepalive_call_t *kc;
    Newxz(kc, 1, keepalive_call_t);
    init_call_base(&kc->base, CALL_TYPE_LEASE_KEEPALIVE);
    kc->base.owner_pid = client->owner_pid;
    kc->client = client;
    kc->active = 1;
    kc->auto_reconnect = 1;
    kc->lease_id = lease_id;
    kc->client_owns = 1;
    kc->perl_owns = 1;

    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        HV *hv = (HV *)SvRV(opts);
        SV **svp;

        if ((svp = hv_fetchs(hv, "auto_reconnect", 0)) && !SvTRUE(*svp)) {
            kc->auto_reconnect = 0;
        }
    }
    grpc_metadata_array_init(&kc->initial_metadata);
    grpc_metadata_array_init(&kc->trailing_metadata);
    kc->status_details = grpc_empty_slice();

    Etcdserverpb__LeaseKeepAliveRequest req = ETCDSERVERPB__LEASE_KEEP_ALIVE_REQUEST__INIT;
    req.id = lease_id;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__lease_keep_alive_request__get_packed_size,
        etcdserverpb__lease_keep_alive_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_inf_future(GPR_CLOCK_REALTIME);

    kc->callback = newSVsv(callback);
    etcd_call_acquire(client, &kc->base);
    kc->call = grpc_channel_create_call(
        client->channel,
        NULL,
        GRPC_PROPAGATE_DEFAULTS,
        client->cq,
        METHOD_LEASE_KEEPALIVE,
        NULL,
        deadline,
        NULL
    );

    if (!kc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        etcd_call_release(&kc->base);
        grpc_metadata_array_destroy(&kc->initial_metadata);
        grpc_metadata_array_destroy(&kc->trailing_metadata);
        grpc_slice_unref(kc->status_details);
        SvREFCNT_dec(kc->callback);
        Safefree(kc);
        croak("Failed to create gRPC call for lease_keepalive");
    }

    grpc_op ops[4] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_stream_metadata(client, &ops[0], &kc->base);

    ops[1].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[1].data.recv_initial_metadata.recv_initial_metadata = &kc->initial_metadata;

    ops[2].op = GRPC_OP_SEND_MESSAGE;
    ops[2].data.send_message.send_message = send_buffer;

    ops[3].op = GRPC_OP_RECV_MESSAGE;
    ops[3].data.recv_message.recv_message = &kc->recv_buffer;

    grpc_call_error err = grpc_call_start_batch(kc->call, ops, 4, &kc->base, NULL);

    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        grpc_metadata_array_destroy(&kc->initial_metadata);
        grpc_metadata_array_destroy(&kc->trailing_metadata);
        grpc_slice_unref(kc->status_details);
        grpc_call_unref(kc->call);
        etcd_call_release(&kc->base);
        SvREFCNT_dec(kc->callback);
        Safefree(kc);
        croak("Failed to start gRPC call: %d", err);
    }

    kc->next = client->keepalives;
    client->keepalives = kc;

    RETVAL = kc;
}
OUTPUT:
    RETVAL

void
ev_etcd_txn(client, compare_av, success_av, failure_av, callback)
    EV::Etcd client
    SV *compare_av
    SV *success_av
    SV *failure_av
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    SvGETMAGIC(compare_av);
    if (SvOK(compare_av) && !(SvROK(compare_av) && SvTYPE(SvRV(compare_av)) == SVt_PVAV))
        croak("txn: compare must be an array reference");
    if (SvROK(compare_av) && SvTYPE(SvRV(compare_av)) == SVt_PVAV) {
        AV *av = (AV *)SvRV(compare_av);
        size_t n = av_len(av) + 1;
        for (size_t i = 0; i < n; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (!elem || !SvROK(*elem) || SvTYPE(SvRV(*elem)) != SVt_PVHV)
                croak("txn: compare element %d is not a hash reference", (int)i);
            HV *hv = (HV *)SvRV(*elem);
            VALIDATE_OPTS_KEYS(hv, "txn compare", "key", "target", "result", "value",
                "version", "create_revision", "mod_revision", "lease");
            STRLEN _l;
            SV **key_sv = hv_fetch(hv, "key", 3, 0);
            if (key_sv && SvOK(*key_sv)) {
                (void)SvPV(*key_sv, _l);
                VALIDATE_KEY_SIZE(_l);
            }
            SV **value_sv = hv_fetch(hv, "value", 5, 0);
            if (value_sv && SvOK(*value_sv)) {
                (void)SvPV(*value_sv, _l);
                VALIDATE_VALUE_SIZE(_l);
            }
            SV **target_sv = hv_fetch(hv, "target", 6, 0);
            if (target_sv && SvOK(*target_sv)) {
                char *target = SvPV_nolen(*target_sv);
                if (!(strcmp(target, "version") == 0 || strcmp(target, "VERSION") == 0
                    || strcmp(target, "create") == 0 || strcmp(target, "CREATE") == 0
                    || strcmp(target, "mod") == 0 || strcmp(target, "MOD") == 0
                    || strcmp(target, "value") == 0 || strcmp(target, "VALUE") == 0
                    || strcmp(target, "lease") == 0 || strcmp(target, "LEASE") == 0)) {
                    croak("txn: invalid compare target '%s' (expected version, create, mod, value, or lease)", target);
                }
            }
            {
                /* The target and the field present must agree, or etcd
                 * compares against a default 0 */
                static const char *const fields[] = {
                    "value", "version", "create_revision", "mod_revision", "lease" };
                static const char *const targets[] = { "value", "version", "create", "mod", "lease" };
                static const char *const upper[] = { "VALUE", "VERSION", "CREATE", "MOD", "LEASE" };
                int nfields = 0, field = -1;
                for (int f = 0; f < 5; f++) {
                    SV **fsv = hv_fetch(hv, fields[f], strlen(fields[f]), 0);
                    if (fsv && SvOK(*fsv)) {
                        nfields++;
                        field = f;
                    }
                }
                if (nfields > 1)
                    croak("txn: compare element %d has more than one of value, version,"
                          " create_revision, mod_revision and lease", (int)i);
                if (field >= 0 && target_sv && SvOK(*target_sv)) {
                    const char *t = SvPV_nolen(*target_sv);
                    if (strNE(t, targets[field]) && strNE(t, upper[field]))
                        croak("txn: compare element %d has target '%s' but a %s field",
                              (int)i, t, fields[field]);
                }
            }
            SV **result_sv = hv_fetch(hv, "result", 6, 0);
            if (result_sv && SvOK(*result_sv)) {
                char *result = SvPV_nolen(*result_sv);
                if (!(strcmp(result, "=") == 0 || strcmp(result, "EQUAL") == 0
                    || strcmp(result, "!=") == 0 || strcmp(result, "NOT_EQUAL") == 0
                    || strcmp(result, "<") == 0 || strcmp(result, "LESS") == 0
                    || strcmp(result, ">") == 0 || strcmp(result, "GREATER") == 0)) {
                    croak("txn: invalid compare result '%s' (expected =, !=, <, >, EQUAL, NOT_EQUAL, LESS, or GREATER)", result);
                }
            }
        }
    }

    validate_request_ops(aTHX_ success_av, "success");
    validate_request_ops(aTHX_ failure_av, "failure");

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_TXN, client);

    Etcdserverpb__TxnRequest req = ETCDSERVERPB__TXN_REQUEST__INIT;

    size_t n_compare = 0;
    Etcdserverpb__Compare **compares = NULL;

    if (SvROK(compare_av) && SvTYPE(SvRV(compare_av)) == SVt_PVAV) {
        AV *av = (AV *)SvRV(compare_av);
        n_compare = av_len(av) + 1;
        if (n_compare > 0) {
            Newxz(compares, n_compare, Etcdserverpb__Compare *);
            for (size_t i = 0; i < n_compare; i++) {
                SV **elem = av_fetch(av, i, 0);
                /* Unconditionally: overload or tie code run by the checks above
                 * can change the array, and a NULL entry crashes the packer */
                Newxz(compares[i], 1, Etcdserverpb__Compare);
                etcdserverpb__compare__init(compares[i]);
                if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                    HV *hv = (HV *)SvRV(*elem);

                    SV **key_sv = hv_fetch(hv, "key", 3, 0);
                    if (key_sv && SvOK(*key_sv)) {
                        STRLEN len;
                        char *str = SvPV(*key_sv, len);
                        compares[i]->key.data = (uint8_t *)str;
                        compares[i]->key.len = len;
                    }

                    SV **target_sv = hv_fetch(hv, "target", 6, 0);
                    if (target_sv && !SvOK(*target_sv))
                        target_sv = NULL;
                    if (target_sv) {
                        char *target = SvPV_nolen(*target_sv);
                        if (strcmp(target, "version") == 0 || strcmp(target, "VERSION") == 0)
                            compares[i]->target = ETCDSERVERPB__COMPARE__COMPARE_TARGET__VERSION;
                        else if (strcmp(target, "create") == 0 || strcmp(target, "CREATE") == 0)
                            compares[i]->target = ETCDSERVERPB__COMPARE__COMPARE_TARGET__CREATE;
                        else if (strcmp(target, "mod") == 0 || strcmp(target, "MOD") == 0)
                            compares[i]->target = ETCDSERVERPB__COMPARE__COMPARE_TARGET__MOD;
                        else if (strcmp(target, "value") == 0 || strcmp(target, "VALUE") == 0)
                            compares[i]->target = ETCDSERVERPB__COMPARE__COMPARE_TARGET__VALUE;
                        else if (strcmp(target, "lease") == 0 || strcmp(target, "LEASE") == 0)
                            compares[i]->target = ETCDSERVERPB__COMPARE__COMPARE_TARGET__LEASE;
                    }

                    SV **result_sv = hv_fetch(hv, "result", 6, 0);
                    if (result_sv && SvOK(*result_sv)) {
                        char *result = SvPV_nolen(*result_sv);
                        if (strcmp(result, "=") == 0 || strcmp(result, "EQUAL") == 0)
                            compares[i]->result = ETCDSERVERPB__COMPARE__COMPARE_RESULT__EQUAL;
                        else if (strcmp(result, "!=") == 0 || strcmp(result, "NOT_EQUAL") == 0)
                            compares[i]->result = ETCDSERVERPB__COMPARE__COMPARE_RESULT__NOT_EQUAL;
                        else if (strcmp(result, "<") == 0 || strcmp(result, "LESS") == 0)
                            compares[i]->result = ETCDSERVERPB__COMPARE__COMPARE_RESULT__LESS;
                        else if (strcmp(result, ">") == 0 || strcmp(result, "GREATER") == 0)
                            compares[i]->result = ETCDSERVERPB__COMPARE__COMPARE_RESULT__GREATER;
                    }

                    SV **version_sv = hv_fetch(hv, "version", 7, 0);
                    if (version_sv && SvOK(*version_sv)) {
                        compares[i]->target_union_case = ETCDSERVERPB__COMPARE__TARGET_UNION_VERSION;
                        compares[i]->version = SvI64(*version_sv);
                        if (!target_sv)
                            compares[i]->target = ETCDSERVERPB__COMPARE__COMPARE_TARGET__VERSION;
                    }

                    SV **create_rev_sv = hv_fetch(hv, "create_revision", 15, 0);
                    if (create_rev_sv && SvOK(*create_rev_sv)) {
                        compares[i]->target_union_case = ETCDSERVERPB__COMPARE__TARGET_UNION_CREATE_REVISION;
                        compares[i]->create_revision = SvI64(*create_rev_sv);
                        if (!target_sv)
                            compares[i]->target = ETCDSERVERPB__COMPARE__COMPARE_TARGET__CREATE;
                    }

                    SV **mod_rev_sv = hv_fetch(hv, "mod_revision", 12, 0);
                    if (mod_rev_sv && SvOK(*mod_rev_sv)) {
                        compares[i]->target_union_case = ETCDSERVERPB__COMPARE__TARGET_UNION_MOD_REVISION;
                        compares[i]->mod_revision = SvI64(*mod_rev_sv);
                        if (!target_sv)
                            compares[i]->target = ETCDSERVERPB__COMPARE__COMPARE_TARGET__MOD;
                    }

                    SV **value_sv = hv_fetch(hv, "value", 5, 0);
                    if (value_sv && SvOK(*value_sv)) {
                        STRLEN len;
                        char *str = SvPV(*value_sv, len);
                        compares[i]->target_union_case = ETCDSERVERPB__COMPARE__TARGET_UNION_VALUE;
                        compares[i]->value.data = (uint8_t *)str;
                        compares[i]->value.len = len;
                        if (!target_sv)
                            compares[i]->target = ETCDSERVERPB__COMPARE__COMPARE_TARGET__VALUE;
                    }

                    SV **lease_sv = hv_fetch(hv, "lease", 5, 0);
                    if (lease_sv && SvOK(*lease_sv)) {
                        compares[i]->target_union_case = ETCDSERVERPB__COMPARE__TARGET_UNION_LEASE;
                        compares[i]->lease = SvI64(*lease_sv);
                        if (!target_sv)
                            compares[i]->target = ETCDSERVERPB__COMPARE__COMPARE_TARGET__LEASE;
                    }
                }
            }
        }
    }
    req.n_compare = n_compare;
    req.compare = compares;

    size_t n_success;
    Etcdserverpb__RequestOp **success_ops;
    parse_request_ops(aTHX_ success_av, &success_ops, &n_success);
    req.n_success = n_success;
    req.success = success_ops;

    size_t n_failure;
    Etcdserverpb__RequestOp **failure_ops;
    parse_request_ops(aTHX_ failure_av, &failure_ops, &n_failure);
    req.n_failure = n_failure;
    req.failure = failure_ops;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__txn_request__get_packed_size,
        etcdserverpb__txn_request__pack, &req);

    /* Structs only: their data pointers borrow the Perl SVs' buffers */
    for (size_t i = 0; i < n_compare; i++) {
        Safefree(compares[i]);
    }
    if (compares) Safefree(compares);

    FREE_REQUEST_OPS(success_ops, n_success);
    FREE_REQUEST_OPS(failure_ops, n_failure);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel,
        NULL,
        GRPC_PROPAGATE_DEFAULTS,
        client->cq,
        METHOD_KV_TXN,
        NULL,
        deadline,
        NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for txn");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);

    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;

    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;

    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;

    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;

    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);

    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_authenticate(client, username, password, callback)
    EV::Etcd client
    SV *username
    SV *password
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    STRLEN user_len, pass_len;
    char *user_str = SvPV(username, user_len);
    char *pass_src = SvPV(password, pass_len);

    VALIDATE_NAME(user_str, user_len);
    VALIDATE_PASSWORD(pass_src, pass_len);

    char *pass_str;
    Newx(pass_str, pass_len + 1, char);
    Copy(pass_src, pass_str, pass_len, char);
    pass_str[pass_len] = '\0';

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_AUTH, client);

    Etcdserverpb__AuthenticateRequest req = ETCDSERVERPB__AUTHENTICATE_REQUEST__INIT;
    req.name = user_str;
    req.password = pass_str;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__authenticate_request__get_packed_size,
        etcdserverpb__authenticate_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    memset(pass_str, 0, pass_len);
    Safefree(pass_str);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel,
        NULL,
        GRPC_PROPAGATE_DEFAULTS,
        client->cq,
        METHOD_AUTH_AUTHENTICATE,
        NULL,
        deadline,
        NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for authenticate");
    }

    grpc_op ops[6] = {0};

    /* No token: etcd before 3.4.28 checks it even here, so a stale one blocks this */
    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;

    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;

    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;

    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;

    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;

    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);

    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_user_add(client, username, password, callback)
    EV::Etcd client
    SV *username
    SV *password
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    STRLEN user_len, pass_len;
    char *user_str = SvPV(username, user_len);
    char *pass_src = SvPV(password, pass_len);

    VALIDATE_NAME(user_str, user_len);
    VALIDATE_PASSWORD(pass_src, pass_len);

    char *pass_str;
    Newx(pass_str, pass_len + 1, char);
    Copy(pass_src, pass_str, pass_len, char);
    pass_str[pass_len] = '\0';

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_USER_ADD, client);

    Etcdserverpb__AuthUserAddRequest req = ETCDSERVERPB__AUTH_USER_ADD_REQUEST__INIT;
    req.name = user_str;
    req.password = pass_str;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__auth_user_add_request__get_packed_size,
        etcdserverpb__auth_user_add_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    memset(pass_str, 0, pass_len);
    Safefree(pass_str);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel,
        NULL,
        GRPC_PROPAGATE_DEFAULTS,
        client->cq,
        METHOD_AUTH_USER_ADD,
        NULL,
        deadline,
        NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for user_add");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);

    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;

    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;

    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;

    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;

    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);

    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_user_delete(client, username, callback)
    EV::Etcd client
    SV *username
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    STRLEN user_len;
    char *user_str = SvPV(username, user_len);
    VALIDATE_NAME(user_str, user_len);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_USER_DELETE, client);

    Etcdserverpb__AuthUserDeleteRequest req = ETCDSERVERPB__AUTH_USER_DELETE_REQUEST__INIT;
    req.name = user_str;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__auth_user_delete_request__get_packed_size,
        etcdserverpb__auth_user_delete_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel,
        NULL,
        GRPC_PROPAGATE_DEFAULTS,
        client->cq,
        METHOD_AUTH_USER_DELETE,
        NULL,
        deadline,
        NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for user_delete");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);

    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;

    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;

    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;

    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;

    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);

    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_user_change_password(client, username, password, callback)
    EV::Etcd client
    SV *username
    SV *password
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    STRLEN user_len, pass_len;
    char *user_str = SvPV(username, user_len);
    char *pass_src = SvPV(password, pass_len);

    VALIDATE_NAME(user_str, user_len);
    VALIDATE_PASSWORD(pass_src, pass_len);

    char *pass_str;
    Newx(pass_str, pass_len + 1, char);
    Copy(pass_src, pass_str, pass_len, char);
    pass_str[pass_len] = '\0';

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_USER_CHANGE_PASSWORD, client);

    Etcdserverpb__AuthUserChangePasswordRequest req = ETCDSERVERPB__AUTH_USER_CHANGE_PASSWORD_REQUEST__INIT;
    req.name = user_str;
    req.password = pass_str;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__auth_user_change_password_request__get_packed_size,
        etcdserverpb__auth_user_change_password_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    memset(pass_str, 0, pass_len);
    Safefree(pass_str);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel,
        NULL,
        GRPC_PROPAGATE_DEFAULTS,
        client->cq,
        METHOD_AUTH_USER_CHANGE_PASSWORD,
        NULL,
        deadline,
        NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for user_change_password");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);

    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;

    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;

    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;

    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;

    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);

    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_auth_enable(client, callback)
    EV::Etcd client
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_AUTH_ENABLE, client);

    Etcdserverpb__AuthEnableRequest req = ETCDSERVERPB__AUTH_ENABLE_REQUEST__INIT;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__auth_enable_request__get_packed_size,
        etcdserverpb__auth_enable_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel,
        NULL,
        GRPC_PROPAGATE_DEFAULTS,
        client->cq,
        METHOD_AUTH_ENABLE,
        NULL,
        deadline,
        NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for auth_enable");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);

    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;

    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;

    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;

    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;

    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);

    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_auth_disable(client, callback)
    EV::Etcd client
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_AUTH_DISABLE, client);

    Etcdserverpb__AuthDisableRequest req = ETCDSERVERPB__AUTH_DISABLE_REQUEST__INIT;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__auth_disable_request__get_packed_size,
        etcdserverpb__auth_disable_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel,
        NULL,
        GRPC_PROPAGATE_DEFAULTS,
        client->cq,
        METHOD_AUTH_DISABLE,
        NULL,
        deadline,
        NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for auth_disable");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);

    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;

    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;

    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;

    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;

    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);

    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_role_add(client, role_name, callback)
    EV::Etcd client
    SV *role_name
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    STRLEN name_len;
    char *name_str = SvPV(role_name, name_len);
    VALIDATE_NAME(name_str, name_len);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_ROLE_ADD, client);

    Etcdserverpb__AuthRoleAddRequest req = ETCDSERVERPB__AUTH_ROLE_ADD_REQUEST__INIT;
    req.name = name_str;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__auth_role_add_request__get_packed_size,
        etcdserverpb__auth_role_add_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel, NULL, GRPC_PROPAGATE_DEFAULTS,
        client->cq, METHOD_AUTH_ROLE_ADD, NULL, deadline, NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for role_add");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);
    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;
    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;
    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;
    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;
    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_role_delete(client, role_name, callback)
    EV::Etcd client
    SV *role_name
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    STRLEN name_len;
    char *name_str = SvPV(role_name, name_len);
    VALIDATE_NAME(name_str, name_len);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_ROLE_DELETE, client);

    Etcdserverpb__AuthRoleDeleteRequest req = ETCDSERVERPB__AUTH_ROLE_DELETE_REQUEST__INIT;
    req.role = name_str;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__auth_role_delete_request__get_packed_size,
        etcdserverpb__auth_role_delete_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel, NULL, GRPC_PROPAGATE_DEFAULTS,
        client->cq, METHOD_AUTH_ROLE_DELETE, NULL, deadline, NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for role_delete");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);
    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;
    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;
    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;
    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;
    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_role_get(client, role_name, callback)
    EV::Etcd client
    SV *role_name
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    STRLEN name_len;
    char *name_str = SvPV(role_name, name_len);
    VALIDATE_NAME(name_str, name_len);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_ROLE_GET, client);

    Etcdserverpb__AuthRoleGetRequest req = ETCDSERVERPB__AUTH_ROLE_GET_REQUEST__INIT;
    req.role = name_str;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__auth_role_get_request__get_packed_size,
        etcdserverpb__auth_role_get_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel, NULL, GRPC_PROPAGATE_DEFAULTS,
        client->cq, METHOD_AUTH_ROLE_GET, NULL, deadline, NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for role_get");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);
    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;
    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;
    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;
    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;
    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_role_list(client, callback)
    EV::Etcd client
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_ROLE_LIST, client);

    Etcdserverpb__AuthRoleListRequest req = ETCDSERVERPB__AUTH_ROLE_LIST_REQUEST__INIT;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__auth_role_list_request__get_packed_size,
        etcdserverpb__auth_role_list_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel, NULL, GRPC_PROPAGATE_DEFAULTS,
        client->cq, METHOD_AUTH_ROLE_LIST, NULL, deadline, NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for role_list");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);
    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;
    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;
    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;
    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;
    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_role_grant_permission(client, role_name, perm_type, key, range_end, callback)
    EV::Etcd client
    SV *role_name
    SV *perm_type
    SV *key
    SV *range_end
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    STRLEN name_len, type_len, key_len, range_len = 0;
    char *name_str = SvPV(role_name, name_len);
    char *type_str = SvPV(perm_type, type_len);
    char *key_str = SvPV(key, key_len);
    SvGETMAGIC(range_end);
    char *range_str = SvOK(range_end) ? SvPV_nomg(range_end, range_len) : NULL;
    VALIDATE_NAME(name_str, name_len);
    VALIDATE_KEY_SIZE(key_len);
    if (range_str) {
        VALIDATE_KEY_SIZE(range_len);
    }

    Etcdserverpb__Permission__Type pt;
    if (strEQ(type_str, "READ") || strEQ(type_str, "read")) {
        pt = ETCDSERVERPB__PERMISSION__TYPE__READ;
    } else if (strEQ(type_str, "WRITE") || strEQ(type_str, "write")) {
        pt = ETCDSERVERPB__PERMISSION__TYPE__WRITE;
    } else if (strEQ(type_str, "READWRITE") || strEQ(type_str, "readwrite")) {
        pt = ETCDSERVERPB__PERMISSION__TYPE__READWRITE;
    } else {
        croak("Invalid permission type: %s (expected READ, WRITE, or READWRITE)", type_str);
    }

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_ROLE_GRANT_PERMISSION, client);

    Etcdserverpb__Permission perm = ETCDSERVERPB__PERMISSION__INIT;
    perm.permtype = pt;
    perm.key.data = (uint8_t *)key_str;
    perm.key.len = key_len;
    if (range_str) {
        perm.range_end.data = (uint8_t *)range_str;
        perm.range_end.len = range_len;
    }

    Etcdserverpb__AuthRoleGrantPermissionRequest req = ETCDSERVERPB__AUTH_ROLE_GRANT_PERMISSION_REQUEST__INIT;
    req.name = name_str;
    req.perm = &perm;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__auth_role_grant_permission_request__get_packed_size,
        etcdserverpb__auth_role_grant_permission_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel, NULL, GRPC_PROPAGATE_DEFAULTS,
        client->cq, METHOD_AUTH_ROLE_GRANT_PERM, NULL, deadline, NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for role_grant_permission");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);
    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;
    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;
    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;
    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;
    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_role_revoke_permission(client, role_name, key, range_end, callback)
    EV::Etcd client
    SV *role_name
    SV *key
    SV *range_end
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    STRLEN name_len, key_len, range_len = 0;
    char *name_str = SvPV(role_name, name_len);
    char *key_str = SvPV(key, key_len);
    SvGETMAGIC(range_end);
    char *range_str = SvOK(range_end) ? SvPV_nomg(range_end, range_len) : NULL;
    VALIDATE_NAME(name_str, name_len);
    VALIDATE_KEY_SIZE(key_len);
    if (range_str) {
        VALIDATE_KEY_SIZE(range_len);
    }

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_ROLE_REVOKE_PERMISSION, client);

    Etcdserverpb__AuthRoleRevokePermissionRequest req = ETCDSERVERPB__AUTH_ROLE_REVOKE_PERMISSION_REQUEST__INIT;
    req.role = name_str;
    req.key.data = (uint8_t *)key_str;
    req.key.len = key_len;
    if (range_str) {
        req.range_end.data = (uint8_t *)range_str;
        req.range_end.len = range_len;
    }

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__auth_role_revoke_permission_request__get_packed_size,
        etcdserverpb__auth_role_revoke_permission_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel, NULL, GRPC_PROPAGATE_DEFAULTS,
        client->cq, METHOD_AUTH_ROLE_REVOKE_PERM, NULL, deadline, NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for role_revoke_permission");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);
    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;
    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;
    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;
    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;
    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_user_grant_role(client, username, role_name, callback)
    EV::Etcd client
    SV *username
    SV *role_name
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    STRLEN user_len, role_len;
    char *user_str = SvPV(username, user_len);
    char *role_str = SvPV(role_name, role_len);
    VALIDATE_NAME(user_str, user_len);
    VALIDATE_NAME(role_str, role_len);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_USER_GRANT_ROLE, client);

    Etcdserverpb__AuthUserGrantRoleRequest req = ETCDSERVERPB__AUTH_USER_GRANT_ROLE_REQUEST__INIT;
    req.user = user_str;
    req.role = role_str;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__auth_user_grant_role_request__get_packed_size,
        etcdserverpb__auth_user_grant_role_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel, NULL, GRPC_PROPAGATE_DEFAULTS,
        client->cq, METHOD_AUTH_USER_GRANT_ROLE, NULL, deadline, NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for user_grant_role");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);
    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;
    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;
    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;
    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;
    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_user_revoke_role(client, username, role_name, callback)
    EV::Etcd client
    SV *username
    SV *role_name
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    STRLEN user_len, role_len;
    char *user_str = SvPV(username, user_len);
    char *role_str = SvPV(role_name, role_len);
    VALIDATE_NAME(user_str, user_len);
    VALIDATE_NAME(role_str, role_len);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_USER_REVOKE_ROLE, client);

    Etcdserverpb__AuthUserRevokeRoleRequest req = ETCDSERVERPB__AUTH_USER_REVOKE_ROLE_REQUEST__INIT;
    req.name = user_str;
    req.role = role_str;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__auth_user_revoke_role_request__get_packed_size,
        etcdserverpb__auth_user_revoke_role_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel, NULL, GRPC_PROPAGATE_DEFAULTS,
        client->cq, METHOD_AUTH_USER_REVOKE_ROLE, NULL, deadline, NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for user_revoke_role");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);
    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;
    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;
    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;
    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;
    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_user_get(client, username, callback)
    EV::Etcd client
    SV *username
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    STRLEN name_len;
    char *name_str = SvPV(username, name_len);
    VALIDATE_NAME(name_str, name_len);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_USER_GET, client);

    Etcdserverpb__AuthUserGetRequest req = ETCDSERVERPB__AUTH_USER_GET_REQUEST__INIT;
    req.name = name_str;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__auth_user_get_request__get_packed_size,
        etcdserverpb__auth_user_get_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel, NULL, GRPC_PROPAGATE_DEFAULTS,
        client->cq, METHOD_AUTH_USER_GET, NULL, deadline, NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for user_get");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);
    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;
    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;
    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;
    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;
    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_user_list(client, callback)
    EV::Etcd client
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_USER_LIST, client);

    Etcdserverpb__AuthUserListRequest req = ETCDSERVERPB__AUTH_USER_LIST_REQUEST__INIT;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__auth_user_list_request__get_packed_size,
        etcdserverpb__auth_user_list_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel, NULL, GRPC_PROPAGATE_DEFAULTS,
        client->cq, METHOD_AUTH_USER_LIST, NULL, deadline, NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for user_list");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);
    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;
    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;
    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;
    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;
    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_lock(client, name, lease_id, callback)
    EV::Etcd client
    SV *name
    int64_t lease_id
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);
    /* Without one etcd grants a 60 s lease that nothing keeps alive */
    if (lease_id <= 0)
        croak("lock: lease_id must be a granted lease");

    STRLEN name_len;
    const char *name_str = SvPV(name, name_len);
    VALIDATE_KEY_SIZE(name_len);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_LOCK, client);

    V3lockpb__LockRequest req = V3LOCKPB__LOCK_REQUEST__INIT;
    req.name.data = (uint8_t *)name_str;
    req.name.len = name_len;
    req.lease = lease_id;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        v3lockpb__lock_request__get_packed_size,
        v3lockpb__lock_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    /* Lock blocks until acquired, so no deadline */
    gpr_timespec deadline = gpr_inf_future(GPR_CLOCK_REALTIME);

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel, NULL, GRPC_PROPAGATE_DEFAULTS,
        client->cq, METHOD_LOCK, NULL, deadline, NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for lock");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);
    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;
    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;
    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;
    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;
    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_unlock(client, key, callback)
    EV::Etcd client
    SV *key
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    STRLEN key_len;
    const char *key_str = SvPV(key, key_len);
    VALIDATE_KEY_SIZE(key_len);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_UNLOCK, client);

    V3lockpb__UnlockRequest req = V3LOCKPB__UNLOCK_REQUEST__INIT;
    req.key.data = (uint8_t *)key_str;
    req.key.len = key_len;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        v3lockpb__unlock_request__get_packed_size,
        v3lockpb__unlock_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel, NULL, GRPC_PROPAGATE_DEFAULTS,
        client->cq, METHOD_UNLOCK, NULL, deadline, NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for unlock");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);
    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;
    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;
    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;
    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;
    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_election_campaign(client, name, lease_id, value, callback)
    EV::Etcd client
    SV *name
    int64_t lease_id
    SV *value
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);
    if (lease_id <= 0)
        croak("election_campaign: lease_id must be a granted lease");

    STRLEN name_len, value_len;
    const char *name_str = SvPV(name, name_len);
    const char *value_str = SvPV(value, value_len);
    VALIDATE_KEY_SIZE(name_len);
    VALIDATE_VALUE_SIZE(value_len);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_ELECTION_CAMPAIGN, client);

    V3electionpb__CampaignRequest req = V3ELECTIONPB__CAMPAIGN_REQUEST__INIT;
    req.name.data = (uint8_t *)name_str;
    req.name.len = name_len;
    req.lease = lease_id;
    req.value.data = (uint8_t *)value_str;
    req.value.len = value_len;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        v3electionpb__campaign_request__get_packed_size,
        v3electionpb__campaign_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    /* Campaign blocks until elected, so no deadline */
    gpr_timespec deadline = gpr_inf_future(GPR_CLOCK_REALTIME);

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel, NULL, GRPC_PROPAGATE_DEFAULTS,
        client->cq, METHOD_ELECTION_CAMPAIGN, NULL, deadline, NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for election_campaign");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);
    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;
    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;
    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;
    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;
    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_election_proclaim(client, leader, value, callback)
    EV::Etcd client
    SV *leader
    SV *value
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    STRLEN value_len;
    const char *value_str = SvPV(value, value_len);
    VALIDATE_VALUE_SIZE(value_len);

    if (!SvROK(leader) || SvTYPE(SvRV(leader)) != SVt_PVHV) {
        croak("leader must be a hash reference");
    }
    HV *leader_hv = (HV *)SvRV(leader);

    SV **sv_name = hv_fetch(leader_hv, "name", 4, 0);
    SV **sv_key = hv_fetch(leader_hv, "key", 3, 0);

    STRLEN name_len = 0, key_len = 0;
    const char *name_str = sv_name && *sv_name ? SvPV(*sv_name, name_len) : "";
    const char *key_str = sv_key && *sv_key ? SvPV(*sv_key, key_len) : "";
    VALIDATE_KEY_SIZE(name_len);
    VALIDATE_KEY_SIZE(key_len);
    int64_t rev = hv_fetch_i64(aTHX_ leader_hv, "rev", 3);
    int64_t lease = hv_fetch_i64(aTHX_ leader_hv, "lease", 5);
    /* Without its lease etcd would move the key to a 60 s one nothing renews */
    if (!key_len || rev <= 0 || lease <= 0)
        croak("election_proclaim: leader must be the hash election_campaign returned");

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_ELECTION_PROCLAIM, client);

    V3electionpb__LeaderKey lk = V3ELECTIONPB__LEADER_KEY__INIT;
    lk.name.data = (uint8_t *)name_str;
    lk.name.len = name_len;
    lk.key.data = (uint8_t *)key_str;
    lk.key.len = key_len;
    lk.rev = rev;
    lk.lease = lease;

    V3electionpb__ProclaimRequest req = V3ELECTIONPB__PROCLAIM_REQUEST__INIT;
    req.leader = &lk;
    req.value.data = (uint8_t *)value_str;
    req.value.len = value_len;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        v3electionpb__proclaim_request__get_packed_size,
        v3electionpb__proclaim_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel, NULL, GRPC_PROPAGATE_DEFAULTS,
        client->cq, METHOD_ELECTION_PROCLAIM, NULL, deadline, NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for election_proclaim");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);
    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;
    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;
    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;
    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;
    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_election_leader(client, name, callback)
    EV::Etcd client
    SV *name
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    STRLEN name_len;
    const char *name_str = SvPV(name, name_len);
    VALIDATE_KEY_SIZE(name_len);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_ELECTION_LEADER, client);

    V3electionpb__LeaderRequest req = V3ELECTIONPB__LEADER_REQUEST__INIT;
    req.name.data = (uint8_t *)name_str;
    req.name.len = name_len;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        v3electionpb__leader_request__get_packed_size,
        v3electionpb__leader_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel, NULL, GRPC_PROPAGATE_DEFAULTS,
        client->cq, METHOD_ELECTION_LEADER, NULL, deadline, NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for election_leader");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);
    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;
    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;
    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;
    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;
    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_election_resign(client, leader, callback)
    EV::Etcd client
    SV *leader
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    if (!SvROK(leader) || SvTYPE(SvRV(leader)) != SVt_PVHV) {
        croak("leader must be a hash reference");
    }
    HV *leader_hv = (HV *)SvRV(leader);

    SV **sv_name = hv_fetch(leader_hv, "name", 4, 0);
    SV **sv_key = hv_fetch(leader_hv, "key", 3, 0);

    STRLEN name_len = 0, key_len = 0;
    const char *name_str = sv_name && *sv_name ? SvPV(*sv_name, name_len) : "";
    const char *key_str = sv_key && *sv_key ? SvPV(*sv_key, key_len) : "";
    VALIDATE_KEY_SIZE(name_len);
    VALIDATE_KEY_SIZE(key_len);
    int64_t rev = hv_fetch_i64(aTHX_ leader_hv, "rev", 3);
    int64_t lease = hv_fetch_i64(aTHX_ leader_hv, "lease", 5);
    if (!key_len || rev <= 0 || lease <= 0)
        croak("election_resign: leader must be the hash election_campaign returned");

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_ELECTION_RESIGN, client);

    V3electionpb__LeaderKey lk = V3ELECTIONPB__LEADER_KEY__INIT;
    lk.name.data = (uint8_t *)name_str;
    lk.name.len = name_len;
    lk.key.data = (uint8_t *)key_str;
    lk.key.len = key_len;
    lk.rev = rev;
    lk.lease = lease;

    V3electionpb__ResignRequest req = V3ELECTIONPB__RESIGN_REQUEST__INIT;
    req.leader = &lk;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        v3electionpb__resign_request__get_packed_size,
        v3electionpb__resign_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel, NULL, GRPC_PROPAGATE_DEFAULTS,
        client->cq, METHOD_ELECTION_RESIGN, NULL, deadline, NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for election_resign");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);
    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;
    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;
    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;
    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;
    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

EV::Etcd::Observe
ev_etcd_election_observe(client, name, ...)
    EV::Etcd client
    SV *name
CODE:
{
    SV *opts = NULL;
    SV *callback;

    if (items == 3) {
        callback = ST(2);
    } else if (items == 4) {
        opts = opts_arg(aTHX_ ST(2));
        callback = ST(3);
    } else {
        croak("Usage: $client->election_observe($name, [\\%%opts,] $callback)");
    }

    VALIDATE_CALLBACK(callback);

    STRLEN name_len;
    const char *name_str = SvPV(name, name_len);
    VALIDATE_KEY_SIZE(name_len);

    int auto_reconnect = 1;
    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        HV *hv = (HV *)SvRV(opts);
        VALIDATE_OPTS_KEYS(hv, "election_observe", "auto_reconnect");
        SV **sv_ar = hv_fetch(hv, "auto_reconnect", 14, 0);
        if (sv_ar && *sv_ar) {
            auto_reconnect = SvTRUE(*sv_ar);
        }
    }

    observe_call_t *oc;
    Newxz(oc, 1, observe_call_t);
    init_call_base(&oc->base, CALL_TYPE_ELECTION_OBSERVE);
    oc->base.owner_pid = client->owner_pid;
    oc->callback = newSVsv(callback);
    oc->client = client;
    oc->active = 1;
    oc->auto_reconnect = auto_reconnect;
    oc->client_owns = 1;
    oc->perl_owns = 1;
    grpc_metadata_array_init(&oc->initial_metadata);
    grpc_metadata_array_init(&oc->trailing_metadata);
    oc->status_details = grpc_empty_slice();

    Newx(oc->params.name, name_len + 1, char);
    Copy(name_str, oc->params.name, name_len, char);
    oc->params.name[name_len] = '\0';
    oc->params.name_len = name_len;

    V3electionpb__LeaderRequest req = V3ELECTIONPB__LEADER_REQUEST__INIT;
    req.name.data = (uint8_t *)name_str;
    req.name.len = name_len;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        v3electionpb__leader_request__get_packed_size,
        v3electionpb__leader_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_inf_future(GPR_CLOCK_REALTIME);

    etcd_call_acquire(client, &oc->base);
    oc->call = grpc_channel_create_call(
        client->channel, NULL, GRPC_PROPAGATE_DEFAULTS,
        client->cq, METHOD_ELECTION_OBSERVE, NULL, deadline, NULL
    );

    if (!oc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        etcd_call_release(&oc->base);
        grpc_metadata_array_destroy(&oc->initial_metadata);
        grpc_metadata_array_destroy(&oc->trailing_metadata);
        grpc_slice_unref(oc->status_details);
        SvREFCNT_dec(oc->callback);
        if (oc->params.name) Safefree(oc->params.name);
        Safefree(oc);
        croak("Failed to create gRPC call for election_observe");
    }

    grpc_op ops[5] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_stream_metadata(client, &ops[0], &oc->base);

    ops[1].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[1].data.recv_initial_metadata.recv_initial_metadata = &oc->initial_metadata;

    ops[2].op = GRPC_OP_SEND_MESSAGE;
    ops[2].data.send_message.send_message = send_buffer;

    /* Server-streaming: no event until the client half-closes (bidi ones must not) */
    ops[3].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;

    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &oc->recv_buffer;

    grpc_call_error err = grpc_call_start_batch(oc->call, ops, 5, &oc->base, NULL);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        grpc_metadata_array_destroy(&oc->initial_metadata);
        grpc_metadata_array_destroy(&oc->trailing_metadata);
        grpc_slice_unref(oc->status_details);
        grpc_call_unref(oc->call);
        etcd_call_release(&oc->base);
        SvREFCNT_dec(oc->callback);
        if (oc->params.name) Safefree(oc->params.name);
        Safefree(oc);
        croak("Failed to start gRPC call: %d", err);
    }

    oc->next = client->observes;
    client->observes = oc;

    RETVAL = oc;
}
OUTPUT:
    RETVAL

void
ev_etcd_member_list(client, ...)
    EV::Etcd client
CODE:
{
    SV *opts = NULL;
    SV *callback;

    if (items == 2) {
        callback = ST(1);
    } else if (items == 3) {
        opts = opts_arg(aTHX_ ST(1));
        callback = ST(2);
    } else {
        croak("Usage: $client->member_list([\\%%opts,] $callback)");
    }

    VALIDATE_CALLBACK(callback);

    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        VALIDATE_OPTS_KEYS((HV *)SvRV(opts), "member_list", "linearizable");
    }

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_MEMBER_LIST, client);

    Etcdserverpb__MemberListRequest req = ETCDSERVERPB__MEMBER_LIST_REQUEST__INIT;

    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        HV *hv = (HV *)SvRV(opts);
        SV **svp;
        if ((svp = hv_fetchs(hv, "linearizable", 0)) && SvTRUE(*svp)) {
            req.linearizable = 1;
        }
    }

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__member_list_request__get_packed_size,
        etcdserverpb__member_list_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel, NULL, GRPC_PROPAGATE_DEFAULTS,
        client->cq, METHOD_CLUSTER_MEMBER_LIST, NULL, deadline, NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for member_list");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);
    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;
    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;
    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;
    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;
    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_member_add(client, peer_urls, ...)
    EV::Etcd client
    SV *peer_urls
CODE:
{
    SV *opts = NULL;
    SV *callback;

    if (items == 3) {
        callback = ST(2);
    } else if (items == 4) {
        opts = opts_arg(aTHX_ ST(2));
        callback = ST(3);
    } else {
        croak("Usage: $client->member_add(\\@peer_urls, [\\%%opts,] $callback)");
    }

    VALIDATE_CALLBACK(callback);

    if (!SvROK(peer_urls) || SvTYPE(SvRV(peer_urls)) != SVt_PVAV) {
        croak("peer_urls must be an array reference");
    }
    AV *urls_av = (AV *)SvRV(peer_urls);
    size_t n_urls = av_len(urls_av) + 1;

    int is_learner = 0;
    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        HV *hv = (HV *)SvRV(opts);
        VALIDATE_OPTS_KEYS(hv, "member_add", "is_learner");
        SV **svp = hv_fetchs(hv, "is_learner", 0);
        if (svp && SvTRUE(*svp)) {
            is_learner = 1;
        }
    }

    for (size_t i = 0; i < n_urls; i++) {
        SV **sv = av_fetch(urls_av, i, 0);
        if (sv && *sv) {
            STRLEN url_len;
            const char *url = SvPV(*sv, url_len);
            VALIDATE_URL_SIZE(url_len);
            VALIDATE_NO_NUL(url, url_len, "peer URL");
        }
    }

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_MEMBER_ADD, client);

    Etcdserverpb__MemberAddRequest req = ETCDSERVERPB__MEMBER_ADD_REQUEST__INIT;
    req.is_learner = is_learner;

    char **url_ptrs = NULL;
    if (n_urls > 0) {
        Newx(url_ptrs, n_urls, char *);
        for (size_t i = 0; i < n_urls; i++) {
            SV **sv = av_fetch(urls_av, i, 0);
            if (sv && *sv) {
                STRLEN url_len;
                url_ptrs[i] = SvPV(*sv, url_len);
            } else {
                url_ptrs[i] = "";
            }
        }
        req.n_peer_urls = n_urls;
        req.peer_urls = url_ptrs;
    }

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__member_add_request__get_packed_size,
        etcdserverpb__member_add_request__pack, &req);

    if (url_ptrs) Safefree(url_ptrs);

    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel, NULL, GRPC_PROPAGATE_DEFAULTS,
        client->cq, METHOD_CLUSTER_MEMBER_ADD, NULL, deadline, NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for member_add");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);
    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;
    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;
    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;
    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;
    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_member_remove(client, id, callback)
    EV::Etcd client
    uint64_t id
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_MEMBER_REMOVE, client);

    Etcdserverpb__MemberRemoveRequest req = ETCDSERVERPB__MEMBER_REMOVE_REQUEST__INIT;
    req.id = id;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__member_remove_request__get_packed_size,
        etcdserverpb__member_remove_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel, NULL, GRPC_PROPAGATE_DEFAULTS,
        client->cq, METHOD_CLUSTER_MEMBER_REMOVE, NULL, deadline, NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for member_remove");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);
    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;
    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;
    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;
    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;
    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_member_update(client, id, peer_urls, callback)
    EV::Etcd client
    uint64_t id
    SV *peer_urls
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    if (!SvROK(peer_urls) || SvTYPE(SvRV(peer_urls)) != SVt_PVAV) {
        croak("peer_urls must be an array reference");
    }
    AV *urls_av = (AV *)SvRV(peer_urls);
    size_t n_urls = av_len(urls_av) + 1;

    for (size_t i = 0; i < n_urls; i++) {
        SV **sv = av_fetch(urls_av, i, 0);
        if (sv && *sv) {
            STRLEN url_len;
            const char *url = SvPV(*sv, url_len);
            VALIDATE_URL_SIZE(url_len);
            VALIDATE_NO_NUL(url, url_len, "peer URL");
        }
    }

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_MEMBER_UPDATE, client);

    Etcdserverpb__MemberUpdateRequest req = ETCDSERVERPB__MEMBER_UPDATE_REQUEST__INIT;
    req.id = id;

    char **url_ptrs = NULL;
    if (n_urls > 0) {
        Newx(url_ptrs, n_urls, char *);
        for (size_t i = 0; i < n_urls; i++) {
            SV **sv = av_fetch(urls_av, i, 0);
            if (sv && *sv) {
                STRLEN url_len;
                url_ptrs[i] = SvPV(*sv, url_len);
            } else {
                url_ptrs[i] = "";
            }
        }
        req.n_peer_urls = n_urls;
        req.peer_urls = url_ptrs;
    }

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__member_update_request__get_packed_size,
        etcdserverpb__member_update_request__pack, &req);

    if (url_ptrs) Safefree(url_ptrs);

    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel, NULL, GRPC_PROPAGATE_DEFAULTS,
        client->cq, METHOD_CLUSTER_MEMBER_UPDATE, NULL, deadline, NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for member_update");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);
    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;
    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;
    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;
    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;
    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_member_promote(client, id, callback)
    EV::Etcd client
    uint64_t id
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_MEMBER_PROMOTE, client);

    Etcdserverpb__MemberPromoteRequest req = ETCDSERVERPB__MEMBER_PROMOTE_REQUEST__INIT;
    req.id = id;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__member_promote_request__get_packed_size,
        etcdserverpb__member_promote_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel, NULL, GRPC_PROPAGATE_DEFAULTS,
        client->cq, METHOD_CLUSTER_MEMBER_PROMOTE, NULL, deadline, NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for member_promote");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);
    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;
    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;
    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;
    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;
    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_alarm(client, action, ...)
    EV::Etcd client
    char *action
CODE:
{
    SV *opts = NULL;
    SV *callback;

    if (items == 3) {
        callback = ST(2);
    } else if (items == 4) {
        opts = opts_arg(aTHX_ ST(2));
        callback = ST(3);
    } else {
        croak("Usage: $client->alarm($action, [\\%%opts,] $callback)");
    }

    VALIDATE_CALLBACK(callback);

    Etcdserverpb__AlarmRequest__AlarmAction alarm_action;
    if (strcasecmp(action, "GET") == 0) {
        alarm_action = ETCDSERVERPB__ALARM_REQUEST__ALARM_ACTION__GET;
    } else if (strcasecmp(action, "ACTIVATE") == 0) {
        alarm_action = ETCDSERVERPB__ALARM_REQUEST__ALARM_ACTION__ACTIVATE;
    } else if (strcasecmp(action, "DEACTIVATE") == 0) {
        alarm_action = ETCDSERVERPB__ALARM_REQUEST__ALARM_ACTION__DEACTIVATE;
    } else {
        croak("Invalid alarm action: %s (expected GET, ACTIVATE, or DEACTIVATE)", action);
    }

    Etcdserverpb__AlarmType alarm_type = ETCDSERVERPB__ALARM_TYPE__NONE;
    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        SV **svp;
        VALIDATE_OPTS_KEYS((HV *)SvRV(opts), "alarm", "alarm", "member_id");
        if ((svp = hv_fetchs((HV *)SvRV(opts), "alarm", 0))) {
            char *alarm_str = SvPV_nolen(*svp);
            if (strcasecmp(alarm_str, "NOSPACE") == 0) {
                alarm_type = ETCDSERVERPB__ALARM_TYPE__NOSPACE;
            } else if (strcasecmp(alarm_str, "CORRUPT") == 0) {
                alarm_type = ETCDSERVERPB__ALARM_TYPE__CORRUPT;
            } else if (strcasecmp(alarm_str, "NONE") == 0) {
                alarm_type = ETCDSERVERPB__ALARM_TYPE__NONE;
            } else {
                croak("Invalid alarm type: %s (expected NOSPACE, CORRUPT, or NONE)", alarm_str);
            }
        }
    }

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_ALARM, client);

    Etcdserverpb__AlarmRequest req = ETCDSERVERPB__ALARM_REQUEST__INIT;
    req.action = alarm_action;
    req.alarm = alarm_type;

    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        HV *hv = (HV *)SvRV(opts);
        SV **svp;

        if ((svp = hv_fetchs(hv, "member_id", 0))) {
            req.memberid = SvU64(*svp);
        }
    }

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__alarm_request__get_packed_size,
        etcdserverpb__alarm_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel,
        NULL,
        GRPC_PROPAGATE_DEFAULTS,
        client->cq,
        METHOD_MAINTENANCE_ALARM,
        NULL,
        deadline,
        NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for alarm");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);

    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;

    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;

    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;

    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;

    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);

    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_defragment(client, callback)
    EV::Etcd client
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_DEFRAGMENT, client);

    Etcdserverpb__DefragmentRequest req = ETCDSERVERPB__DEFRAGMENT_REQUEST__INIT;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__defragment_request__get_packed_size,
        etcdserverpb__defragment_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel,
        NULL,
        GRPC_PROPAGATE_DEFAULTS,
        client->cq,
        METHOD_MAINTENANCE_DEFRAGMENT,
        NULL,
        deadline,
        NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for defragment");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);

    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;

    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;

    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;

    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;

    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);

    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_hash_kv(client, ...)
    EV::Etcd client
CODE:
{
    int64_t revision = 0;
    SV *callback;

    if (items == 2) {
        callback = ST(1);
    } else if (items == 3) {
        revision = SvI64(ST(1));
        callback = ST(2);
    } else {
        croak("Usage: $client->hash_kv([$revision,] $callback)");
    }

    VALIDATE_CALLBACK(callback);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_HASH_KV, client);

    Etcdserverpb__HashKVRequest req = ETCDSERVERPB__HASH_KV_REQUEST__INIT;
    req.revision = revision;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__hash_kv_request__get_packed_size,
        etcdserverpb__hash_kv_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel,
        NULL,
        GRPC_PROPAGATE_DEFAULTS,
        client->cq,
        METHOD_MAINTENANCE_HASH_KV,
        NULL,
        deadline,
        NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for hash_kv");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);

    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;

    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;

    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;

    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;

    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);

    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_move_leader(client, target_id, callback)
    EV::Etcd client
    uint64_t target_id
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_MOVE_LEADER, client);

    Etcdserverpb__MoveLeaderRequest req = ETCDSERVERPB__MOVE_LEADER_REQUEST__INIT;
    req.targetid = target_id;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__move_leader_request__get_packed_size,
        etcdserverpb__move_leader_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel,
        NULL,
        GRPC_PROPAGATE_DEFAULTS,
        client->cq,
        METHOD_MAINTENANCE_MOVE_LEADER,
        NULL,
        deadline,
        NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for move_leader");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);

    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;

    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;

    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;

    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;

    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);

    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_auth_status(client, callback)
    EV::Etcd client
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_AUTH_STATUS, client);

    Etcdserverpb__AuthStatusRequest req = ETCDSERVERPB__AUTH_STATUS_REQUEST__INIT;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__auth_status_request__get_packed_size,
        etcdserverpb__auth_status_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    START_PENDING_CALL(pc, callback, client);
    pc->call = grpc_channel_create_call(
        client->channel,
        NULL,
        GRPC_PROPAGATE_DEFAULTS,
        client->cq,
        METHOD_AUTH_STATUS,
        NULL,
        deadline,
        NULL
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for auth_status");
    }

    grpc_op ops[6] = {0};

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &pc->base);

    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;

    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;

    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;

    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;

    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);

    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    link_pending_call(client, pc);
}

void
ev_etcd_DESTROY(self)
    SV *self
CODE:
{
    /* Converted by hand: the EV::Etcd typemap refuses forked children */
    if (!(SvROK(self) && sv_derived_from(self, "EV::Etcd")))
        croak("client is not of type EV::Etcd");
    ev_etcd_t *client = INT2PTR(ev_etcd_t *, SvIV(SvRV(self)));
    if (!client)
        XSRETURN_EMPTY;
    sv_setiv(SvRV(self), 0);

    /* A forked child has no gRPC thread and must not touch gRPC objects */
    if (client->owner_pid != ev_etcd_pid) {
        warn("EV::Etcd: client destroyed in forked child (pid %d, created in %d)"
             " -- skipping gRPC cleanup", (int)ev_etcd_pid, (int)client->owner_pid);

        /* A callback that forked is still running on these structs; leak them */
        if (client->in_callback)
            XSRETURN_EMPTY;

        /* A stream struct whose Perl handle is still alive is left for its DESTROY */
        pending_call_t *pc = client->pending_calls;
        while (pc) {
            pending_call_t *next = pc->next;
            etcd_channel_release(pc->base.channel_ref, 0);
            SvREFCNT_dec(pc->callback);
            Safefree(pc);
            pc = next;
        }
        watch_call_t *wc = client->watches;
        while (wc) {
            watch_call_t *next = wc->next;
            ev_timer_stop(EV_DEFAULT, &wc->reconnect_timer);
            ev_timer_stop(EV_DEFAULT, &wc->progress_timer);
            etcd_channel_release(wc->base.channel_ref, 0);
            wc->base.channel_ref = NULL;
            SvREFCNT_dec(wc->callback);
            wc->callback = NULL;
            wc->client_owns = 0;
            if (!wc->perl_owns) {
                if (wc->params.key) Safefree(wc->params.key);
                if (wc->params.range_end) Safefree(wc->params.range_end);
                Safefree(wc);
            }
            wc = next;
        }
        keepalive_call_t *kc = client->keepalives;
        while (kc) {
            keepalive_call_t *next = kc->next;
            ev_timer_stop(EV_DEFAULT, &kc->reconnect_timer);
            ev_timer_stop(EV_DEFAULT, &kc->renew_timer);
            etcd_channel_release(kc->base.channel_ref, 0);
            kc->base.channel_ref = NULL;
            SvREFCNT_dec(kc->callback);
            kc->callback = NULL;
            kc->client_owns = 0;
            if (!kc->perl_owns) Safefree(kc);
            kc = next;
        }
        observe_call_t *oc = client->observes;
        while (oc) {
            observe_call_t *next = oc->next;
            ev_timer_stop(EV_DEFAULT, &oc->reconnect_timer);
            etcd_channel_release(oc->base.channel_ref, 0);
            oc->base.channel_ref = NULL;
            SvREFCNT_dec(oc->callback);
            oc->callback = NULL;
            oc->client_owns = 0;
            if (!oc->perl_owns) {
                if (oc->params.name) Safefree(oc->params.name);
                Safefree(oc);
            }
            oc = next;
        }
        if (ev_is_active(&client->health_timer))
            ev_timer_stop(EV_DEFAULT, &client->health_timer);
        if (ev_is_active(&client->cq_async))
            ev_async_stop(EV_DEFAULT, &client->cq_async);
        goto free_perl_resources;
    }

    /* First, so no callback reaches what is freed below */
    client->active = 0;
    unregister_client(client);

    if (ev_is_active(&client->cq_async)) {
        ev_async_stop(EV_DEFAULT, &client->cq_async);
    }

    /* Cancelled calls complete their pending batches promptly with success=0 */
    watch_call_t *wc = client->watches;
    while (wc) {
        wc->active = 0;
        ev_timer_stop(EV_DEFAULT, &wc->reconnect_timer);
        ev_timer_stop(EV_DEFAULT, &wc->progress_timer);
        if (wc->call) {
            grpc_call_cancel(wc->call, NULL);
        }
        wc = wc->next;
    }

    keepalive_call_t *kc = client->keepalives;
    while (kc) {
        kc->active = 0;
        ev_timer_stop(EV_DEFAULT, &kc->reconnect_timer);
        ev_timer_stop(EV_DEFAULT, &kc->renew_timer);
        if (kc->call) {
            grpc_call_cancel(kc->call, NULL);
        }
        kc = kc->next;
    }

    observe_call_t *oc = client->observes;
    while (oc) {
        oc->active = 0;
        ev_timer_stop(EV_DEFAULT, &oc->reconnect_timer);
        if (oc->call) {
            grpc_call_cancel(oc->call, NULL);
        }
        oc = oc->next;
    }

    pending_call_t *pc = client->pending_calls;
    while (pc) {
        if (pc->call) {
            grpc_call_cancel(pc->call, NULL);
        }
        pc = pc->next;
    }

    if (client->cq) {
        grpc_completion_queue_shutdown(client->cq);
    }

    pthread_join(client->cq_thread, NULL);

    pthread_mutex_lock(&client->queue_mutex);
    queued_event_t *qe = client->event_queue;
    while (qe) {
        queued_event_t *next = qe->next;
        free(qe);
        qe = next;
    }
    client->event_queue = NULL;
    client->event_queue_tail = NULL;
    pthread_mutex_unlock(&client->queue_mutex);

    pthread_mutex_destroy(&client->queue_mutex);

    if (client->cq) {
        grpc_completion_queue_destroy(client->cq);
    }

    /* Inside a callback, finish_client_destroy does this once it returns */
    if (!client->in_callback) {
        pc = client->pending_calls;
        while (pc) {
            pending_call_t *next = pc->next;
            grpc_metadata_array_destroy(&pc->initial_metadata);
            grpc_metadata_array_destroy(&pc->trailing_metadata);
            if (pc->recv_buffer) {
                grpc_byte_buffer_destroy(pc->recv_buffer);
            }
            grpc_slice_unref(pc->status_details);
            if (pc->call) {
                grpc_call_unref(pc->call);
            }
            etcd_call_release(&pc->base);
            SvREFCNT_dec(pc->callback);
            Safefree(pc);
            pc = next;
        }

        /* cleanup_* frees the struct only if its Perl handle is gone, else *_DESTROY does */
        while (client->watches) cleanup_watch(aTHX_ client->watches);
        while (client->keepalives) cleanup_keepalive(aTHX_ client->keepalives);
        while (client->observes) cleanup_observe(aTHX_ client->observes);
    }

    ev_timer_stop(EV_DEFAULT, &client->health_timer);

    etcd_channel_release(client->channel_ref, 1);
    client->channel_ref = NULL;
    client->channel = NULL;
    if (client->creds) {
        grpc_channel_credentials_release(client->creds);
        client->creds = NULL;
    }
    if (!client->in_callback)
        grpc_release();

    free_perl_resources:
    etcd_channel_release(client->channel_ref, 0);
    client->channel_ref = NULL;
    if (client->health_callback) {
        SvREFCNT_dec(client->health_callback);
        client->health_callback = NULL;
    }

    clear_auth_token(client);

    Safefree(client->tls_server_name);
    client->tls_server_name = NULL;

    if (client->endpoints) {
        int i;
        for (i = 0; i < client->endpoint_count; i++) {
            if (client->endpoints[i]) {
                Safefree(client->endpoints[i]);
            }
        }
        Safefree(client->endpoints);
        client->endpoints = NULL;
    }

    /* Inside a callback, finish_client_destroy frees it later */
    if (!client->in_callback) {
        Safefree(client);
    }
}

MODULE = EV::Etcd  PACKAGE = EV::Etcd::Watch  PREFIX = ev_etcd_watch_

void
ev_etcd_watch_cancel(watch, callback)
    EV::Etcd::Watch watch
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    watch_call_t *wc = watch;

    if (!wc->client_owns) {
        CALL_SYNC_SUCCESS_CALLBACK(callback, newHV());
        XSRETURN_EMPTY;
    }

    /* A fired timer stays pending until its callback: armed too, and must not resurrect */
    int timer_was_armed = ev_is_active(&wc->reconnect_timer)
                       || ev_is_pending(&wc->reconnect_timer);
    ev_timer_stop(EV_DEFAULT, &wc->reconnect_timer);
    ev_timer_stop(EV_DEFAULT, &wc->progress_timer);

    if (!wc->active) {
        /* In backoff nothing is in flight; otherwise the pending RECV cleans up */
        if (timer_was_armed)
            cleanup_watch(aTHX_ wc);
        CALL_SYNC_SUCCESS_CALLBACK(callback, newHV());
        XSRETURN_EMPTY;
    }

    wc->active = 0;

    if (wc->watch_id >= 0) {
        Etcdserverpb__WatchCancelRequest cancel_req = ETCDSERVERPB__WATCH_CANCEL_REQUEST__INIT;
        cancel_req.watch_id = wc->watch_id;

        Etcdserverpb__WatchRequest req = ETCDSERVERPB__WATCH_REQUEST__INIT;
        req.request_union_case = ETCDSERVERPB__WATCH_REQUEST__REQUEST_UNION_CANCEL_REQUEST;
        req.cancel_request = &cancel_req;

        grpc_slice req_slice;
        SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
            etcdserverpb__watch_request__get_packed_size,
            etcdserverpb__watch_request__pack, &req);
        grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
        grpc_slice_unref(req_slice);

        grpc_op op;
        memset(&op, 0, sizeof(op));
        op.op = GRPC_OP_SEND_MESSAGE;
        op.data.send_message.send_message = send_buffer;

        (void)grpc_call_start_batch(wc->call, &op, 1, &cancel_sentinel, NULL);
        grpc_byte_buffer_destroy(send_buffer);
    }

    if (wc->call)
        grpc_call_cancel(wc->call, NULL);

    CALL_SYNC_SUCCESS_CALLBACK(callback, newHV());
}

void
ev_etcd_watch_DESTROY(self)
    SV *self
CODE:
{
    if (!(SvROK(self) && sv_derived_from(self, "EV::Etcd::Watch")))
        croak("handle is not of type EV::Etcd::Watch");
    watch_call_t *watch = INT2PTR(watch_call_t *, SvIV(SvRV(self)));
    if (!watch)
        XSRETURN_EMPTY;
    sv_setiv(SvRV(self), 0);
    watch_call_perl_release(aTHX_ watch);
}

MODULE = EV::Etcd  PACKAGE = EV::Etcd::Keepalive  PREFIX = ev_etcd_keepalive_

void
ev_etcd_keepalive_cancel(keepalive, callback)
    EV::Etcd::Keepalive keepalive
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    keepalive_call_t *kc = keepalive;

    if (!kc->client_owns) {
        CALL_SYNC_SUCCESS_CALLBACK(callback, newHV());
        XSRETURN_EMPTY;
    }

    int timer_was_armed = ev_is_active(&kc->reconnect_timer)
                       || ev_is_pending(&kc->reconnect_timer);
    ev_timer_stop(EV_DEFAULT, &kc->reconnect_timer);
    ev_timer_stop(EV_DEFAULT, &kc->renew_timer);

    if (!kc->active) {
        if (timer_was_armed)
            cleanup_keepalive(aTHX_ kc);
        CALL_SYNC_SUCCESS_CALLBACK(callback, newHV());
        XSRETURN_EMPTY;
    }

    kc->active = 0;

    if (kc->call)
        grpc_call_cancel(kc->call, NULL);

    CALL_SYNC_SUCCESS_CALLBACK(callback, newHV());
}

void
ev_etcd_keepalive_DESTROY(self)
    SV *self
CODE:
{
    if (!(SvROK(self) && sv_derived_from(self, "EV::Etcd::Keepalive")))
        croak("handle is not of type EV::Etcd::Keepalive");
    keepalive_call_t *keepalive = INT2PTR(keepalive_call_t *, SvIV(SvRV(self)));
    if (!keepalive)
        XSRETURN_EMPTY;
    sv_setiv(SvRV(self), 0);
    keepalive_call_perl_release(aTHX_ keepalive);
}

MODULE = EV::Etcd  PACKAGE = EV::Etcd::Observe  PREFIX = ev_etcd_observe_

void
ev_etcd_observe_cancel(observe, callback)
    EV::Etcd::Observe observe
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    observe_call_t *oc = observe;

    if (!oc->client_owns) {
        CALL_SYNC_SUCCESS_CALLBACK(callback, newHV());
        XSRETURN_EMPTY;
    }

    int timer_was_armed = ev_is_active(&oc->reconnect_timer)
                       || ev_is_pending(&oc->reconnect_timer);
    ev_timer_stop(EV_DEFAULT, &oc->reconnect_timer);

    if (!oc->active) {
        if (timer_was_armed)
            cleanup_observe(aTHX_ oc);
        CALL_SYNC_SUCCESS_CALLBACK(callback, newHV());
        XSRETURN_EMPTY;
    }

    oc->active = 0;

    if (oc->call)
        grpc_call_cancel(oc->call, NULL);

    CALL_SYNC_SUCCESS_CALLBACK(callback, newHV());
}

void
ev_etcd_observe_DESTROY(self)
    SV *self
CODE:
{
    if (!(SvROK(self) && sv_derived_from(self, "EV::Etcd::Observe")))
        croak("handle is not of type EV::Etcd::Observe");
    observe_call_t *observe = INT2PTR(observe_call_t *, SvIV(SvRV(self)));
    if (!observe)
        XSRETURN_EMPTY;
    sv_setiv(SvRV(self), 0);
    observe_call_perl_release(aTHX_ observe);
}

