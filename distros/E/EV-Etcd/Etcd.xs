#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* Use Perl EV's API for proper integration */
#include <EV/EVAPI.h>

#include <time.h>
#include <stdlib.h>
#include <unistd.h>

/* Include modular components */
#include "etcd_common.h"
#include "etcd_kv.h"
#include "etcd_watch.h"
#include "etcd_lease.h"
#include "etcd_maint.h"
#include "etcd_lock.h"
#include "etcd_election.h"
#include "etcd_cluster.h"
#include "etcd_txn.h"  /* For FREE_REQUEST_OPS macro */

/* Types and common functions defined in etcd_common.h */
/* KV handlers in etcd_kv.h, watch in etcd_watch.h, etc. */

/* Forward declarations for functions still in this file */
static void *cq_thread_func(void *arg);
static void cq_async_callback(EV_P_ ev_async *w, int revents);
static void process_grpc_event(pTHX_ ev_etcd_t *client, void *tag, int success);
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

/* Reconnect to the next endpoint (or same if only one) */
static void reconnect_channel(ev_etcd_t *client) {
    if (client->endpoint_count > 1)
        client->current_endpoint = (client->current_endpoint + 1) % client->endpoint_count;

    if (client->channel) {
        grpc_channel_destroy(client->channel);
        client->channel = NULL;
    }
    client->channel = etcd_create_insecure_channel(
        client->endpoints[client->current_endpoint], NULL);
}

/*
 * Compute range_end for prefix queries.
 * For a prefix, range_end is the key with the last byte incremented.
 * Handles trailing 0xFF bytes by truncating and incrementing.
 * Returns allocated buffer (caller must Safefree) and sets *out_len.
 * Returns NULL if key_len is 0.
 */
static char* compute_prefix_range_end(const char *key, size_t key_len, size_t *out_len) {
    if (key_len == 0) {
        *out_len = 0;
        return NULL;
    }

    /* Find first non-0xFF byte from end */
    size_t i = key_len;
    while (i > 0 && (unsigned char)key[i - 1] == 0xFF) {
        i--;
    }

    char *range_end;
    if (i == 0) {
        /* All bytes are 0xFF - use "\x00" for range_end (all keys >= key) */
        Newx(range_end, 1, char);
        range_end[0] = '\0';
        *out_len = 1;
    } else {
        /* Truncate trailing 0xFF bytes and increment last byte */
        Newx(range_end, i, char);
        memcpy(range_end, key, i);
        ((unsigned char *)range_end)[i - 1]++;
        *out_len = i;
    }

    return range_end;
}

/* Health timer callback - performs periodic health checks */
static void health_timer_callback(struct ev_loop *loop, ev_timer *w, int revents) {
    dTHX;
    ev_etcd_t *client = (ev_etcd_t *)((char *)w - offsetof(ev_etcd_t, health_timer));

    (void)loop;
    (void)revents;

    if (!client->active) {
        return;
    }

    /* Check channel connectivity state */
    grpc_connectivity_state state = grpc_channel_check_connectivity_state(client->channel, 0);

    int was_healthy = client->is_healthy;
    int is_healthy = (state == GRPC_CHANNEL_READY || state == GRPC_CHANNEL_IDLE);

    if (was_healthy != is_healthy) {
        client->is_healthy = is_healthy;

        /* If unhealthy, try reconnecting to next endpoint */
        if (!is_healthy && client->endpoint_count > 1) {
            reconnect_channel(client);
        }

        /* Call health callback if provided */
        if (client->health_callback) {
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            EXTEND(SP, 2);
            PUSHs(sv_2mortal(newSViv(is_healthy)));
            PUSHs(sv_2mortal(newSVpv(client->endpoints[client->current_endpoint], 0)));
            PUTBACK;
            client->in_callback = 1;
            CALL_SV_SAFE(client->health_callback, G_DISCARD);
            FREETMPS;
            LEAVE;
            client->in_callback = 0;
            if (!client->active) {
                finish_client_destroy(aTHX_ client);
                return;
            }
        }
    }
}

/*
 * gRPC completion queue thread function.
 * Runs in a separate thread, polls the CQ for events, and signals the main thread.
 */
static void *cq_thread_func(void *arg) {
    ev_etcd_t *client = (ev_etcd_t *)arg;

    while (client->thread_running) {
        /* Poll with 100ms timeout to allow checking thread_running periodically */
        gpr_timespec deadline = gpr_time_add(
            gpr_now(GPR_CLOCK_REALTIME),
            gpr_time_from_millis(100, GPR_TIMESPAN));

        grpc_event event = grpc_completion_queue_next(client->cq, deadline, NULL);

        if (event.type == GRPC_QUEUE_SHUTDOWN) {
            break;
        }

        if (event.type != GRPC_OP_COMPLETE) {
            continue;
        }

        /* Queue the event for the main thread */
        queued_event_t *qe = (queued_event_t *)malloc(sizeof(queued_event_t));
        if (!qe) {
            /* OOM is extremely rare but would cause callbacks to never fire.
             * Log to stderr since we can't call Perl from this thread. */
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

        /* Signal main thread */
        ev_async_send(EV_DEFAULT, &client->cq_async);
    }

    return NULL;
}

/*
 * Finish deferred client destruction.
 * Called after in_callback is cleared and client->active is false,
 * meaning DESTROY ran during a callback but deferred the final cleanup.
 */
void finish_client_destroy(pTHX_ ev_etcd_t *client) {
    /* Free any remaining call structures */
    while (client->pending_calls) {
        pending_call_t *pc = client->pending_calls;
        client->pending_calls = pc->next;
        grpc_metadata_array_destroy(&pc->initial_metadata);
        grpc_metadata_array_destroy(&pc->trailing_metadata);
        if (pc->recv_buffer) grpc_byte_buffer_destroy(pc->recv_buffer);
        grpc_slice_unref(pc->status_details);
        if (pc->call) grpc_call_unref(pc->call);
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

    /* Free client-level resources (mirrors free_perl_resources in DESTROY) */
    if (client->health_callback)
        SvREFCNT_dec(client->health_callback);
    if (client->auth_token) {
        memset(client->auth_token, 0, client->auth_token_len);
        Safefree(client->auth_token);
    }
    if (client->endpoints) {
        for (int i = 0; i < client->endpoint_count; i++)
            if (client->endpoints[i]) Safefree(client->endpoints[i]);
        Safefree(client->endpoints);
    }

    Safefree(client);
}

/*
 * ev_async callback - runs in main thread when signaled by gRPC thread.
 * Drains the event queue and processes each event.
 */
static void cq_async_callback(struct ev_loop *loop, ev_async *w, int revents) {
    dTHX;
    (void)loop;
    (void)revents;

    ev_etcd_t *client = (ev_etcd_t *)((char *)w - offsetof(ev_etcd_t, cq_async));

    /* Don't process if client is being destroyed */
    if (!client->active) {
        return;
    }

    /* Drain the queue under lock, then process without lock */
    pthread_mutex_lock(&client->queue_mutex);
    queued_event_t *queue = client->event_queue;
    client->event_queue = NULL;
    client->event_queue_tail = NULL;
    pthread_mutex_unlock(&client->queue_mutex);

    /* Guard against client being freed during event processing */
    client->in_callback = 1;

    /* Process all queued events */
    while (queue) {
        queued_event_t *qe = queue;
        queue = qe->next;

        /* Skip NULL tags (e.g., from watch cancel messages) */
        if (qe->tag) {
            process_grpc_event(aTHX_ client, qe->tag, qe->success);
        }

        free(qe);

        /* Check if client was destroyed during callback processing */
        if (!client->active) {
            /* Free remaining queued events */
            while (queue) {
                qe = queue;
                queue = qe->next;
                free(qe);
            }
            break;
        }
    }

    client->in_callback = 0;

    /* If DESTROY was called during event processing, finish the deferred cleanup */
    if (!client->active) {
        finish_client_destroy(aTHX_ client);
    }
}

/*
 * Process a single gRPC event. Called from the main thread.
 */
static void process_grpc_event(pTHX_ ev_etcd_t *client, void *tag, int success) {
    call_base_t *base = (call_base_t *)tag;

    if (base->type == CALL_TYPE_WATCH_RECV) {
            /* Watch receive completion */
            watch_call_t *wc = (watch_call_t *)base;

            if (success && wc->active) {
                    process_watch_response(aTHX_ wc);
                    if (!client->active) return; /* DESTROY called in callback */
                    /* Re-arm receive if still active */
                    if (wc->active) {
                        watch_rearm_recv(aTHX_ wc);
                    } else {
                        /* Response handler set active=0 (e.g., server cancel) */
                        cleanup_watch(aTHX_ wc);
                    }
                } else if (!success && wc->active) {
                    /* Stream ended or error - try to reconnect */
                    wc->active = 0;
                    /* Try automatic reconnection */
                    if (try_reconnect_watch(aTHX_ wc)) {
                        /* Reconnection initiated, don't notify callback yet */
                    } else {
                        /* Reconnection failed or disabled, notify callback and cleanup */
                        CALL_STATUS_ERROR_CALLBACK(wc->callback, GRPC_STATUS_UNAVAILABLE, "Watch stream ended", "watch");
                        if (!client->active) return; /* DESTROY called in callback */
                        cleanup_watch(aTHX_ wc);
                    }
                } else {
                    /* RECV completed but watch already inactive (user cancel) */
                    cleanup_watch(aTHX_ wc);
                }
            } else if (base->type == CALL_TYPE_WATCH) {
            /* Initial watch setup complete - process first message if any */
            watch_call_t *wc = (watch_call_t *)base;
            if (success) {
                    /* Process the first message that was received in the initial batch */
                    if (wc->recv_buffer && wc->active) {
                        process_watch_response(aTHX_ wc);
                        if (!client->active) return;
                    }
                    /* Re-arm to receive more messages */
                    if (wc->active) {
                        watch_rearm_recv(aTHX_ wc);
                    } else {
                        cleanup_watch(aTHX_ wc);
                    }
                } else {
                    if (wc->active) {
                        CALL_STATUS_ERROR_CALLBACK(wc->callback, GRPC_STATUS_INTERNAL, "Watch setup failed", "watch");
                        if (!client->active) return;
                    }
                    cleanup_watch(aTHX_ wc);
                }
            } else if (base->type == CALL_TYPE_LEASE_KEEPALIVE_RECV) {
            /* Keepalive receive completion */
            keepalive_call_t *kc = (keepalive_call_t *)base;

            if (success && kc->active) {
                    process_keepalive_response(aTHX_ kc);
                    if (!client->active) return;
                    /* Re-arm receive if still active */
                    if (kc->active) {
                        keepalive_rearm_recv(aTHX_ kc);
                    } else {
                        /* Response handler set active=0 (e.g., lease expired) */
                        cleanup_keepalive(aTHX_ kc);
                    }
                } else if (!success && kc->active) {
                    /* Stream ended or error - try to reconnect */
                    kc->active = 0;
                    /* Try automatic reconnection */
                    if (try_reconnect_keepalive(aTHX_ kc)) {
                        /* Reconnection initiated, don't notify callback yet */
                    } else {
                        /* Reconnection failed or disabled, notify callback and cleanup */
                        CALL_STATUS_ERROR_CALLBACK(kc->callback, GRPC_STATUS_UNAVAILABLE, "Keepalive stream ended", "keepalive");
                        if (!client->active) return;
                        cleanup_keepalive(aTHX_ kc);
                    }
                } else {
                    /* RECV completed but keepalive already inactive */
                    cleanup_keepalive(aTHX_ kc);
                }
            } else if (base->type == CALL_TYPE_LEASE_KEEPALIVE) {
            /* Initial keepalive setup complete - process first message if any */
            keepalive_call_t *kc = (keepalive_call_t *)base;
            if (success) {
                    /* Process the first message that was received in the initial batch */
                    if (kc->recv_buffer && kc->active) {
                        process_keepalive_response(aTHX_ kc);
                        if (!client->active) return;
                    }
                    /* Re-arm to receive more messages */
                    if (kc->active) {
                        keepalive_rearm_recv(aTHX_ kc);
                    } else {
                        /* First response set active=0 (e.g., lease already expired) */
                        cleanup_keepalive(aTHX_ kc);
                    }
                } else {
                    if (kc->active) {
                        CALL_STATUS_ERROR_CALLBACK(kc->callback, GRPC_STATUS_INTERNAL, "Keepalive setup failed", "keepalive");
                        if (!client->active) return;
                    }
                    cleanup_keepalive(aTHX_ kc);
                }
            } else if (base->type == CALL_TYPE_ELECTION_OBSERVE_RECV) {
            /* Election observe receive completion */
            observe_call_t *oc = (observe_call_t *)base;

            if (success && oc->active) {
                    process_observe_response(aTHX_ oc);
                    if (!client->active) return;
                    /* Re-arm receive if still active */
                    if (oc->active) {
                        observe_rearm_recv(aTHX_ oc);
                    } else {
                        /* Response handler set active=0 */
                        cleanup_observe(aTHX_ oc);
                    }
                } else if (!success && oc->active) {
                    /* Stream ended or error - try to reconnect */
                    oc->active = 0;
                    /* Try automatic reconnection */
                    if (try_reconnect_observe(aTHX_ oc)) {
                        /* Reconnection initiated, don't notify callback yet */
                    } else {
                        /* Reconnection failed or disabled, notify callback and cleanup */
                        CALL_STATUS_ERROR_CALLBACK(oc->callback, GRPC_STATUS_UNAVAILABLE, "Observe stream ended", "observe");
                        if (!client->active) return;
                        cleanup_observe(aTHX_ oc);
                    }
                } else {
                    /* RECV completed but observe already inactive */
                    cleanup_observe(aTHX_ oc);
                }
            } else if (base->type == CALL_TYPE_ELECTION_OBSERVE) {
            /* Initial observe setup complete - process first message if any */
            observe_call_t *oc = (observe_call_t *)base;
            if (success) {
                    /* Process the first message that was received in the initial batch */
                    if (oc->recv_buffer && oc->active) {
                        process_observe_response(aTHX_ oc);
                        if (!client->active) return;
                    }
                    /* Re-arm to receive more messages */
                    if (oc->active) {
                        observe_rearm_recv(aTHX_ oc);
                    } else {
                        /* First response set active=0 */
                        cleanup_observe(aTHX_ oc);
                    }
                } else {
                    if (oc->active) {
                        CALL_STATUS_ERROR_CALLBACK(oc->callback, GRPC_STATUS_INTERNAL, "Observe setup failed", "observe");
                        if (!client->active) return;
                    }
                    cleanup_observe(aTHX_ oc);
                }
            } else {
            /* Unary RPC completion */
            pending_call_t *pc = (pending_call_t *)base;

            /* Remove from pending list BEFORE calling handler to prevent
             * use-after-free if the callback triggers DESTROY */
            pending_call_t **pp = &client->pending_calls;
            while (*pp) {
                if (*pp == pc) {
                    *pp = pc->next;
                    break;
                }
                pp = &(*pp)->next;
            }

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
                    /* Call failed - use status code if available.
                     * If batch failed before status was populated, status remains
                     * GRPC_STATUS_OK (from Newxz zero-init) which is misleading.
                     * Use UNAVAILABLE as fallback for network-level failures. */
                    grpc_status_code effective_status = pc->status == GRPC_STATUS_OK
                        ? GRPC_STATUS_UNAVAILABLE : pc->status;
                    CALL_ERROR_CALLBACK(pc->callback, effective_status, pc->status_details, "grpc_call");
                }

                /* Cleanup unary call (already removed from pending list above) */
                grpc_metadata_array_destroy(&pc->initial_metadata);
                grpc_metadata_array_destroy(&pc->trailing_metadata);
                if (pc->recv_buffer) {
                    grpc_byte_buffer_destroy(pc->recv_buffer);
                }
                grpc_slice_unref(pc->status_details);
                grpc_call_unref(pc->call);
                SvREFCNT_dec(pc->callback);
                Safefree(pc);
            }
}

/* Helper to convert ResponseOp to hashref */
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
        hv_store(range, "count", 5, newSViv(rr->count), 0);

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

        hv_store(del, "deleted", 7, newSViv(dr->deleted), 0);

        if (dr->n_prev_kvs > 0) {
            AV *prev_kvs = newAV();
            av_extend(prev_kvs, dr->n_prev_kvs - 1);
            for (size_t i = 0; i < dr->n_prev_kvs; i++) {
                av_push(prev_kvs, kv_to_hashref(aTHX_ dr->prev_kvs[i]));
            }
            hv_store(del, "prev_kvs", 8, newRV_noinc((SV *)prev_kvs), 0);
        }

        hv_store(hv, "response_delete_range", 21, newRV_noinc((SV *)del), 0);
    }

    return newRV_noinc((SV *)hv);
}

/* Helper to parse Perl array of RequestOps into C structures */
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
        if (!elem || !SvROK(*elem) || SvTYPE(SvRV(*elem)) != SVt_PVHV) {
            Newxz((*dst_ops)[i], 1, Etcdserverpb__RequestOp);
            etcdserverpb__request_op__init((*dst_ops)[i]);
            continue;
        }

        HV *hv = (HV *)SvRV(*elem);
        Newxz((*dst_ops)[i], 1, Etcdserverpb__RequestOp);
        etcdserverpb__request_op__init((*dst_ops)[i]);

        /* Check for request_range / range */
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
                VALIDATE_KEY_SIZE(len);
                rr->key.data = (uint8_t *)str;
                rr->key.len = len;
            }
            SV **re = hv_fetch(rh, "range_end", 9, 0);
            if (re && SvOK(*re)) {
                STRLEN len;
                char *str = SvPV(*re, len);
                VALIDATE_KEY_SIZE(len);
                rr->range_end.data = (uint8_t *)str;
                rr->range_end.len = len;
            }
            (*dst_ops)[i]->request_case = ETCDSERVERPB__REQUEST_OP__REQUEST_REQUEST_RANGE;
            (*dst_ops)[i]->request_range = rr;
            continue;
        }

        /* Check for request_put / put */
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
                VALIDATE_KEY_SIZE(len);
                pr->key.data = (uint8_t *)str;
                pr->key.len = len;
            }
            SV **v = hv_fetch(ph, "value", 5, 0);
            if (v && SvOK(*v)) {
                STRLEN len;
                char *str = SvPV(*v, len);
                VALIDATE_VALUE_SIZE(len);
                pr->value.data = (uint8_t *)str;
                pr->value.len = len;
            }
            SV **l = hv_fetch(ph, "lease", 5, 0);
            if (l && SvOK(*l)) pr->lease = SvIV(*l);

            (*dst_ops)[i]->request_case = ETCDSERVERPB__REQUEST_OP__REQUEST_REQUEST_PUT;
            (*dst_ops)[i]->request_put = pr;
            continue;
        }

        /* Check for request_delete_range / delete */
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
                VALIDATE_KEY_SIZE(len);
                dr->key.data = (uint8_t *)str;
                dr->key.len = len;
            }
            SV **re = hv_fetch(dh, "range_end", 9, 0);
            if (re && SvOK(*re)) {
                STRLEN len;
                char *str = SvPV(*re, len);
                VALIDATE_KEY_SIZE(len);
                dr->range_end.data = (uint8_t *)str;
                dr->range_end.len = len;
            }
            (*dst_ops)[i]->request_case = ETCDSERVERPB__REQUEST_OP__REQUEST_REQUEST_DELETE_RANGE;
            (*dst_ops)[i]->request_delete_range = dr;
        }
    }
}

/* Process TxnResponse and call Perl callback */
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

/* Process AuthenticateResponse and call Perl callback */
static void process_auth_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "authenticate");

    Etcdserverpb__AuthenticateResponse *resp;
    UNPACK_RESPONSE(pc, resp, etcdserverpb__authenticate_response__unpack);

    /* Store the token in the client */
    ev_etcd_t *client = pc->client;
    if (resp->token) {
        size_t token_len = strlen(resp->token);
        if (token_len > 0) {
            /* Validate token size to prevent memory exhaustion */
            if (token_len > ETCD_MAX_VALUE_SIZE) {
                CALL_SIMPLE_ERROR_CALLBACK(pc->callback, "auth token too large");
                etcdserverpb__authenticate_response__free_unpacked(resp, NULL);
                return;
            }
            /* Securely free old token if exists */
            if (client->auth_token) {
                memset(client->auth_token, 0, client->auth_token_len);
                Safefree(client->auth_token);
            }
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

/* Helper macro for simple header-only responses */
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

/* auth_disable needs to clear the stored auth token */
static void process_auth_disable_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "auth_disable");

    Etcdserverpb__AuthDisableResponse *resp;
    UNPACK_RESPONSE(pc, resp, etcdserverpb__auth_disable_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);
    etcdserverpb__auth_disable_response__free_unpacked(resp, NULL);

    if (pc->client->auth_token) {
        memset(pc->client->auth_token, 0, pc->client->auth_token_len);
        Safefree(pc->client->auth_token);
        pc->client->auth_token = NULL;
        pc->client->auth_token_len = 0;
    }

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

/* Process role_get response - returns permissions */
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

/* Process role_list response - returns roles list */
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

/* Process user_get response - returns roles assigned to user */
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

/* Process user_list response - returns users list */
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
    grpc_init();
    init_method_slices();

EV::Etcd
ev_etcd_new(class, ...)
    char *class
CODE:
{
    ev_etcd_t *client;
    AV *endpoints_av = NULL;
    int timeout_seconds = 30;  /* Default timeout */
    int max_retries = 3;       /* Default max retries */
    int health_interval = 0;   /* Default: disabled */
    SV *health_callback = NULL;
    char *init_auth_token = NULL;
    STRLEN init_auth_token_len = 0;
    int i;

    /* Parse options */
    for (i = 1; i < items; i += 2) {
        if (i + 1 < items) {
            const char *key = SvPV_nolen(ST(i));
            if (strEQ(key, "endpoints")) {
                if (SvROK(ST(i + 1)) && SvTYPE(SvRV(ST(i + 1))) == SVt_PVAV) {
                    endpoints_av = (AV *)SvRV(ST(i + 1));
                }
            } else if (strEQ(key, "timeout")) {
                timeout_seconds = SvIV(ST(i + 1));
                if (timeout_seconds < 1) {
                    timeout_seconds = 1;  /* Minimum 1 second */
                }
            } else if (strEQ(key, "max_retries")) {
                max_retries = SvIV(ST(i + 1));
                if (max_retries < 0) {
                    max_retries = 0;
                }
            } else if (strEQ(key, "health_interval")) {
                health_interval = SvIV(ST(i + 1));
                if (health_interval < 0) {
                    health_interval = 0;
                }
            } else if (strEQ(key, "on_health_change")) {
                if (SvROK(ST(i + 1)) && SvTYPE(SvRV(ST(i + 1))) == SVt_PVCV) {
                    health_callback = ST(i + 1);
                }
            } else if (strEQ(key, "auth_token")) {
                if (SvPOK(ST(i + 1))) {
                    init_auth_token = SvPV(ST(i + 1), init_auth_token_len);
                }
            }
        }
    }

    /* Pre-validate endpoint URL sizes before allocating */
    if (endpoints_av && av_len(endpoints_av) >= 0) {
        int count = av_len(endpoints_av) + 1;
        for (i = 0; i < count; i++) {
            SV **ep = av_fetch(endpoints_av, i, 0);
            if (ep && SvPOK(*ep)) {
                VALIDATE_URL_SIZE(SvCUR(*ep));
            }
        }
    }

    Newxz(client, 1, ev_etcd_t);

    /* Store endpoints */
    if (endpoints_av && av_len(endpoints_av) >= 0) {
        int count = av_len(endpoints_av) + 1;
        Newx(client->endpoints, count, char *);
        client->endpoint_count = count;
        for (i = 0; i < count; i++) {
            SV **ep = av_fetch(endpoints_av, i, 0);
            if (ep && SvPOK(*ep)) {
                STRLEN len;
                const char *str = SvPV(*ep, len);
                Newx(client->endpoints[i], len + 1, char);
                Copy(str, client->endpoints[i], len + 1, char);
            } else {
                /* Default endpoint for invalid entries */
                client->endpoints[i] = savepv("127.0.0.1:2379");
            }
        }
    } else {
        /* Default single endpoint */
        Newx(client->endpoints, 1, char *);
        client->endpoints[0] = savepv("127.0.0.1:2379");
        client->endpoint_count = 1;
    }
    client->current_endpoint = 0;

    /* Create gRPC channel to first endpoint */
    client->channel = etcd_create_insecure_channel(client->endpoints[0], NULL);

    if (!client->channel) {
        for (int j = 0; j < client->endpoint_count; j++) {
            Safefree(client->endpoints[j]);
        }
        Safefree(client->endpoints);
        Safefree(client);
        croak("Failed to create gRPC channel");
    }

    /* Create completion queue for polling */
    client->cq = grpc_completion_queue_create_for_next(NULL);

    /* Initialize threading for hybrid gRPC/EV approach */
    pthread_mutex_init(&client->queue_mutex, NULL);
    client->event_queue = NULL;
    client->event_queue_tail = NULL;
    client->thread_running = 1;

    /* Initialize ev_async watcher for main thread notification */
    ev_async_init(&client->cq_async, cq_async_callback);
    ev_async_start(EV_DEFAULT, &client->cq_async);

    /* Start gRPC completion queue thread */
    if (pthread_create(&client->cq_thread, NULL, cq_thread_func, client) != 0) {
        ev_async_stop(EV_DEFAULT, &client->cq_async);
        pthread_mutex_destroy(&client->queue_mutex);
        grpc_completion_queue_shutdown(client->cq);
        while (grpc_completion_queue_next(client->cq,
               gpr_inf_past(GPR_CLOCK_REALTIME), NULL).type != GRPC_QUEUE_SHUTDOWN)
            ;
        grpc_completion_queue_destroy(client->cq);
        grpc_channel_destroy(client->channel);
        /* Free endpoints */
        for (int j = 0; j < client->endpoint_count; j++) {
            Safefree(client->endpoints[j]);
        }
        Safefree(client->endpoints);
        Safefree(client);
        croak("Failed to create gRPC completion queue thread");
    }

    client->pending_calls = NULL;
    client->watches = NULL;
    client->keepalives = NULL;
    client->observes = NULL;
    /* Store auth token if provided */
    if (init_auth_token && init_auth_token_len > 0) {
        Newx(client->auth_token, init_auth_token_len + 1, char);
        Copy(init_auth_token, client->auth_token, init_auth_token_len, char);
        client->auth_token[init_auth_token_len] = '\0';
        client->auth_token_len = init_auth_token_len;
    } else {
        client->auth_token = NULL;
        client->auth_token_len = 0;
    }
    client->timeout_seconds = timeout_seconds;
    client->active = 1;
    client->in_callback = 0;
    client->owner_pid = getpid();

    /* Retry configuration */
    client->max_retries = max_retries;

    /* Health monitoring */
    client->is_healthy = 1;  /* Assume healthy initially */
    if (health_callback) {
        client->health_callback = SvREFCNT_inc(health_callback);
    } else {
        client->health_callback = NULL;
    }

    /* Initialize health timer (stopped initially) */
    ev_timer_init(&client->health_timer, health_timer_callback, 0.0, 0.0);

    /* Start health monitoring if interval > 0 */
    if (health_interval > 0) {
        ev_timer_set(&client->health_timer, (double)health_interval, (double)health_interval);
        ev_timer_start(EV_DEFAULT, &client->health_timer);
    }

    RETVAL = client;
}
OUTPUT:
    RETVAL

void
ev_etcd_get(client, key, ...)
    EV::Etcd client
    SV *key
CODE:
{
    /* Parse arguments: get(key, [opts,] callback) */
    SV *opts = NULL;
    SV *callback;

    if (items == 3) {
        /* get(key, callback) */
        callback = ST(2);
    } else if (items == 4) {
        /* get(key, opts, callback) */
        opts = ST(2);
        callback = ST(3);
    } else {
        croak("Usage: $client->get($key, [\\%%opts,] $callback)");
    }

    VALIDATE_CALLBACK(callback);

    STRLEN key_len;
    const char *key_str = SvPV(key, key_len);
    VALIDATE_KEY_SIZE(key_len);

    /* Pre-validate option sizes before allocating pending call */
    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        SV **svp;
        if ((svp = hv_fetchs((HV *)SvRV(opts), "range_end", 0)) && SvOK(*svp))
            VALIDATE_KEY_SIZE(SvCUR(*svp));
    }

    /* Create pending call structure */
    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_RANGE, callback, client);

    /* Build RangeRequest */
    Etcdserverpb__RangeRequest req = ETCDSERVERPB__RANGE_REQUEST__INIT;
    req.key.data = (uint8_t *)key_str;
    req.key.len = key_len;

    /* Storage for range_end to ensure it persists through serialization */
    char *range_end_copy = NULL;

    /* Parse options if provided */
    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        HV *hv = (HV *)SvRV(opts);
        SV **svp;

        /* range_end - for range queries or prefix queries */
        if ((svp = hv_fetchs(hv, "range_end", 0)) && SvOK(*svp)) {
            STRLEN range_end_len;
            const char *range_end_str = SvPV(*svp, range_end_len);
            /* Already validated above */
            Newx(range_end_copy, range_end_len, char);
            memcpy(range_end_copy, range_end_str, range_end_len);
            req.range_end.data = (uint8_t *)range_end_copy;
            req.range_end.len = range_end_len;
        }

        /* prefix - convenience option to get all keys with given prefix */
        if ((svp = hv_fetchs(hv, "prefix", 0)) && SvTRUE(*svp)) {
            /* Don't override if range_end was explicitly provided */
            if (!range_end_copy && key_len > 0) {
                size_t range_len;
                range_end_copy = compute_prefix_range_end(key_str, key_len, &range_len);
                if (range_end_copy) {
                    req.range_end.data = (uint8_t *)range_end_copy;
                    req.range_end.len = range_len;
                }
            }
        }

        /* limit */
        if ((svp = hv_fetchs(hv, "limit", 0)) && SvOK(*svp)) {
            req.limit = SvIV(*svp);
        }

        /* revision */
        if ((svp = hv_fetchs(hv, "revision", 0)) && SvOK(*svp)) {
            req.revision = SvIV(*svp);
        }

        /* keys_only */
        if ((svp = hv_fetchs(hv, "keys_only", 0)) && SvTRUE(*svp)) {
            req.keys_only = 1;
        }

        /* count_only */
        if ((svp = hv_fetchs(hv, "count_only", 0)) && SvTRUE(*svp)) {
            req.count_only = 1;
        }

        /* serializable */
        if ((svp = hv_fetchs(hv, "serializable", 0)) && SvTRUE(*svp)) {
            req.serializable = 1;
        }

        /* sort_order: NONE=0, ASCEND=1, DESCEND=2 */
        if ((svp = hv_fetchs(hv, "sort_order", 0)) && SvOK(*svp)) {
            const char *order = SvPV_nolen(*svp);
            if (strEQ(order, "ascend") || strEQ(order, "ASCEND")) {
                req.sort_order = ETCDSERVERPB__RANGE_REQUEST__SORT_ORDER__ASCEND;
            } else if (strEQ(order, "descend") || strEQ(order, "DESCEND")) {
                req.sort_order = ETCDSERVERPB__RANGE_REQUEST__SORT_ORDER__DESCEND;
            }
        }

        /* sort_target: KEY=0, VERSION=1, CREATE=2, MOD=3, VALUE=4 */
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
            }
        }

        /* min_mod_revision */
        if ((svp = hv_fetchs(hv, "min_mod_revision", 0)) && SvOK(*svp)) {
            req.min_mod_revision = SvIV(*svp);
        }

        /* max_mod_revision */
        if ((svp = hv_fetchs(hv, "max_mod_revision", 0)) && SvOK(*svp)) {
            req.max_mod_revision = SvIV(*svp);
        }

        /* min_create_revision */
        if ((svp = hv_fetchs(hv, "min_create_revision", 0)) && SvOK(*svp)) {
            req.min_create_revision = SvIV(*svp);
        }

        /* max_create_revision */
        if ((svp = hv_fetchs(hv, "max_create_revision", 0)) && SvOK(*svp)) {
            req.max_create_revision = SvIV(*svp);
        }
    }

    /* Serialize request */
    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__range_request__get_packed_size,
        etcdserverpb__range_request__pack, &req);
    if (range_end_copy) {
        Safefree(range_end_copy);
    }
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    /* Create call */
    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    pc->call = grpc_channel_create_call(
        client->channel,
        NULL,  /* parent call */
        GRPC_PROPAGATE_DEFAULTS,
        client->cq,
        METHOD_KV_RANGE,
        NULL,  /* host */
        deadline,
        NULL   /* reserved */
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for range");
    }

    /* Set up operations */
    grpc_op ops[6] = {0};
    grpc_metadata auth_md;

    /* Send initial metadata (with auth token if available) */
    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);

    /* Send message */
    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;

    /* Send close */
    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;

    /* Receive initial metadata */
    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;

    /* Receive message */
    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;

    /* Receive status */
    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    /* Start batch */
    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);

    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        /* Cleanup on error */
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    /* Add to pending list */
    pc->next = client->pending_calls;
    client->pending_calls = pc;
}

void
ev_etcd_put(client, key, value, ...)
    EV::Etcd client
    SV *key
    SV *value
CODE:
{
    /* Parse arguments: put(key, value, [opts,] callback) */
    SV *opts = NULL;
    SV *callback;

    if (items == 4) {
        /* put(key, value, callback) */
        callback = ST(3);
    } else if (items == 5) {
        /* put(key, value, opts, callback) */
        opts = ST(3);
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

    /* Create pending call structure */
    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_PUT, callback, client);

    /* Build PutRequest */
    Etcdserverpb__PutRequest req = ETCDSERVERPB__PUT_REQUEST__INIT;
    req.key.data = (uint8_t *)key_str;
    req.key.len = key_len;
    req.value.data = (uint8_t *)value_str;
    req.value.len = value_len;

    /* Parse options if provided */
    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        HV *hv = (HV *)SvRV(opts);
        SV **svp;

        /* lease - lease ID to associate with key */
        if ((svp = hv_fetchs(hv, "lease", 0)) && SvOK(*svp)) {
            req.lease = SvIV(*svp);
        }

        /* prev_kv - return previous key-value pair */
        if ((svp = hv_fetchs(hv, "prev_kv", 0)) && SvTRUE(*svp)) {
            req.prev_kv = 1;
        }

        /* ignore_value - update lease without changing value */
        if ((svp = hv_fetchs(hv, "ignore_value", 0)) && SvTRUE(*svp)) {
            req.ignore_value = 1;
        }

        /* ignore_lease - update value without changing lease */
        if ((svp = hv_fetchs(hv, "ignore_lease", 0)) && SvTRUE(*svp)) {
            req.ignore_lease = 1;
        }
    }

    /* Serialize request */
    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__put_request__get_packed_size,
        etcdserverpb__put_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    /* Create call */
    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    pc->call = grpc_channel_create_call(
        client->channel,
        NULL,  /* parent call */
        GRPC_PROPAGATE_DEFAULTS,
        client->cq,
        METHOD_KV_PUT,
        NULL,  /* host */
        deadline,
        NULL   /* reserved */
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for put");
    }

    /* Set up operations */
    grpc_op ops[6] = {0};
    grpc_metadata auth_md;

    /* Send initial metadata (with auth token if available) */
    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);

    /* Send message */
    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;

    /* Send close */
    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;

    /* Receive initial metadata */
    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;

    /* Receive message */
    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;

    /* Receive status */
    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    /* Start batch */
    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);

    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        /* Cleanup on error */
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    /* Add to pending list */
    pc->next = client->pending_calls;
    client->pending_calls = pc;
}

void
ev_etcd_delete(client, key, ...)
    EV::Etcd client
    SV *key
CODE:
{
    /* Parse arguments: delete(key, [opts,] callback) */
    SV *opts = NULL;
    SV *callback;

    if (items == 3) {
        /* delete(key, callback) */
        callback = ST(2);
    } else if (items == 4) {
        /* delete(key, opts, callback) */
        opts = ST(2);
        callback = ST(3);
    } else {
        croak("Usage: $client->delete($key, [\\%%opts,] $callback)");
    }

    VALIDATE_CALLBACK(callback);

    STRLEN key_len;
    const char *key_str = SvPV(key, key_len);
    VALIDATE_KEY_SIZE(key_len);

    /* Pre-validate option sizes before allocating pending call */
    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        SV **svp;
        if ((svp = hv_fetchs((HV *)SvRV(opts), "range_end", 0)) && SvOK(*svp))
            VALIDATE_KEY_SIZE(SvCUR(*svp));
    }

    /* Create pending call structure */
    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_DELETE, callback, client);

    /* Build DeleteRangeRequest */
    Etcdserverpb__DeleteRangeRequest req = ETCDSERVERPB__DELETE_RANGE_REQUEST__INIT;
    req.key.data = (uint8_t *)key_str;
    req.key.len = key_len;

    /* Storage for range_end to ensure it persists through serialization */
    char *range_end_copy = NULL;

    /* Parse options if provided */
    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        HV *hv = (HV *)SvRV(opts);
        SV **svp;

        /* range_end - for range deletion */
        if ((svp = hv_fetchs(hv, "range_end", 0)) && SvOK(*svp)) {
            STRLEN range_end_len;
            const char *range_end_str = SvPV(*svp, range_end_len);
            /* Already validated above */
            Newx(range_end_copy, range_end_len, char);
            memcpy(range_end_copy, range_end_str, range_end_len);
            req.range_end.data = (uint8_t *)range_end_copy;
            req.range_end.len = range_end_len;
        }

        /* prefix - convenience option to delete all keys with given prefix */
        if ((svp = hv_fetchs(hv, "prefix", 0)) && SvTRUE(*svp)) {
            /* Don't override if range_end was explicitly provided */
            if (!range_end_copy && key_len > 0) {
                size_t range_len;
                range_end_copy = compute_prefix_range_end(key_str, key_len, &range_len);
                if (range_end_copy) {
                    req.range_end.data = (uint8_t *)range_end_copy;
                    req.range_end.len = range_len;
                }
            }
        }

        /* prev_kv - return deleted keys */
        if ((svp = hv_fetchs(hv, "prev_kv", 0)) && SvTRUE(*svp)) {
            req.prev_kv = 1;
        }
    }

    /* Serialize request */
    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__delete_range_request__get_packed_size,
        etcdserverpb__delete_range_request__pack, &req);
    if (range_end_copy) {
        Safefree(range_end_copy);
    }
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    /* Create call */
    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

    pc->call = grpc_channel_create_call(
        client->channel,
        NULL,  /* parent call */
        GRPC_PROPAGATE_DEFAULTS,
        client->cq,
        METHOD_KV_DELETE,
        NULL,  /* host */
        deadline,
        NULL   /* reserved */
    );

    if (!pc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to create gRPC call for delete");
    }

    /* Set up operations */
    grpc_op ops[6] = {0};
    grpc_metadata auth_md;

    /* Send initial metadata (with auth token if available) */
    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);

    /* Send message */
    ops[1].op = GRPC_OP_SEND_MESSAGE;
    ops[1].data.send_message.send_message = send_buffer;

    /* Send close */
    ops[2].op = GRPC_OP_SEND_CLOSE_FROM_CLIENT;

    /* Receive initial metadata */
    ops[3].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[3].data.recv_initial_metadata.recv_initial_metadata = &pc->initial_metadata;

    /* Receive message */
    ops[4].op = GRPC_OP_RECV_MESSAGE;
    ops[4].data.recv_message.recv_message = &pc->recv_buffer;

    /* Receive status */
    ops[5].op = GRPC_OP_RECV_STATUS_ON_CLIENT;
    ops[5].data.recv_status_on_client.trailing_metadata = &pc->trailing_metadata;
    ops[5].data.recv_status_on_client.status = &pc->status;
    ops[5].data.recv_status_on_client.status_details = &pc->status_details;

    /* Start batch */
    grpc_call_error err = grpc_call_start_batch(pc->call, ops, 6, &pc->base, NULL);

    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        /* Cleanup on error */
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    /* Add to pending list */
    pc->next = client->pending_calls;
    client->pending_calls = pc;
}

EV::Etcd::Watch
ev_etcd_watch(client, key, ...)
    EV::Etcd client
    SV *key
CODE:
{
    /* Parse arguments: watch(key, [opts,] callback) */
    SV *opts = NULL;
    SV *callback;

    if (items == 3) {
        /* watch(key, callback) */
        callback = ST(2);
    } else if (items == 4) {
        /* watch(key, opts, callback) */
        opts = ST(2);
        callback = ST(3);
    } else {
        croak("Usage: $client->watch($key, [\\%%opts,] $callback)");
    }

    VALIDATE_CALLBACK(callback);

    STRLEN key_len;
    const char *key_str = SvPV(key, key_len);
    VALIDATE_KEY_SIZE(key_len);

    /* Pre-validate range_end size before allocation to prevent croak leak */
    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        SV **svp = hv_fetchs((HV *)SvRV(opts), "range_end", 0);
        if (svp && SvOK(*svp)) {
            STRLEN re_len;
            (void)SvPV(*svp, re_len);
            VALIDATE_KEY_SIZE(re_len);
        }
    }

    /* Create watch structure */
    watch_call_t *wc;
    Newxz(wc, 1, watch_call_t);
    init_call_base(&wc->base, CALL_TYPE_WATCH);
    wc->callback = newSVsv(callback);
    wc->client = client;
    wc->active = 1;
    wc->watch_id = -1;
    grpc_metadata_array_init(&wc->initial_metadata);
    grpc_metadata_array_init(&wc->trailing_metadata);
    wc->recv_buffer = NULL;
    wc->status_details = grpc_empty_slice();

    /* Recovery fields */
    wc->auto_reconnect = 1;  /* Enable by default */
    wc->last_revision = 0;
    wc->reconnect_attempt = 0;

    /* Store key for recovery */
    Newx(wc->params.key, key_len + 1, char);
    Copy(key_str, wc->params.key, key_len, char);
    wc->params.key[key_len] = '\0';
    wc->params.key_len = key_len;
    wc->params.range_end = NULL;
    wc->params.range_end_len = 0;
    wc->params.start_revision = 0;
    wc->params.prev_kv = 0;
    wc->params.progress_notify = 0;

    /* Build WatchCreateRequest wrapped in WatchRequest */
    Etcdserverpb__WatchCreateRequest create_req = ETCDSERVERPB__WATCH_CREATE_REQUEST__INIT;
    create_req.key.data = (uint8_t *)key_str;
    create_req.key.len = key_len;

    /* Storage for range_end to ensure it persists through serialization */
    char *range_end_copy = NULL;

    /* Parse options if provided */
    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        HV *hv = (HV *)SvRV(opts);
        SV **svp;

        /* auto_reconnect - enable/disable automatic reconnection (default: true) */
        if ((svp = hv_fetchs(hv, "auto_reconnect", 0))) {
            wc->auto_reconnect = SvTRUE(*svp) ? 1 : 0;
        }

        /* range_end - explicit end of key range to watch */
        if ((svp = hv_fetchs(hv, "range_end", 0)) && SvOK(*svp)) {
            STRLEN range_end_len;
            const char *range_end_str = SvPV(*svp, range_end_len);
            Newx(range_end_copy, range_end_len, char);
            memcpy(range_end_copy, range_end_str, range_end_len);
            create_req.range_end.data = (uint8_t *)range_end_copy;
            create_req.range_end.len = range_end_len;
            /* Store for recovery */
            Newx(wc->params.range_end, range_end_len + 1, char);
            Copy(range_end_str, wc->params.range_end, range_end_len, char);
            wc->params.range_end[range_end_len] = '\0';
            wc->params.range_end_len = range_end_len;
        }

        /* prefix - convenience option to watch all keys with given prefix */
        if ((svp = hv_fetchs(hv, "prefix", 0)) && SvTRUE(*svp)) {
            /* Don't override if range_end was explicitly provided */
            if (!range_end_copy && key_len > 0) {
                size_t range_len;
                range_end_copy = compute_prefix_range_end(key_str, key_len, &range_len);
                if (range_end_copy) {
                    create_req.range_end.data = (uint8_t *)range_end_copy;
                    create_req.range_end.len = range_len;
                    /* Store for recovery */
                    Newx(wc->params.range_end, range_len + 1, char);
                    Copy(range_end_copy, wc->params.range_end, range_len, char);
                    wc->params.range_end[range_len] = '\0';
                    wc->params.range_end_len = range_len;
                }
            }
        }

        /* start_revision - watch from specific revision */
        if ((svp = hv_fetchs(hv, "start_revision", 0)) && SvOK(*svp)) {
            create_req.start_revision = SvIV(*svp);
            wc->params.start_revision = create_req.start_revision;
        }

        /* progress_notify - receive periodic progress notifications */
        if ((svp = hv_fetchs(hv, "progress_notify", 0)) && SvTRUE(*svp)) {
            create_req.progress_notify = 1;
            wc->params.progress_notify = 1;
        }

        /* prev_kv - include previous key-value in events */
        if ((svp = hv_fetchs(hv, "prev_kv", 0)) && SvTRUE(*svp)) {
            create_req.prev_kv = 1;
            wc->params.prev_kv = 1;
        }

        /* watch_id - optional explicit watch ID */
        if ((svp = hv_fetchs(hv, "watch_id", 0)) && SvOK(*svp)) {
            create_req.watch_id = SvIV(*svp);
            wc->params.watch_id = create_req.watch_id;
            wc->params.has_watch_id = 1;
        }
    }

    Etcdserverpb__WatchRequest req = ETCDSERVERPB__WATCH_REQUEST__INIT;
    req.request_union_case = ETCDSERVERPB__WATCH_REQUEST__REQUEST_UNION_CREATE_REQUEST;
    req.create_request = &create_req;

    /* Serialize request */
    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__watch_request__get_packed_size,
        etcdserverpb__watch_request__pack, &req);
    if (range_end_copy) Safefree(range_end_copy);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    /* Create streaming call */
    gpr_timespec deadline = gpr_inf_future(GPR_CLOCK_REALTIME);  /* No timeout for watch */

    wc->call = grpc_channel_create_call(
        client->channel,
        NULL,  /* parent call */
        GRPC_PROPAGATE_DEFAULTS,
        client->cq,
        METHOD_WATCH,
        NULL,  /* host */
        deadline,
        NULL   /* reserved */
    );

    if (!wc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        grpc_metadata_array_destroy(&wc->initial_metadata);
        grpc_metadata_array_destroy(&wc->trailing_metadata);
        grpc_slice_unref(wc->status_details);
        SvREFCNT_dec(wc->callback);
        if (wc->params.key) Safefree(wc->params.key);
        if (wc->params.range_end) Safefree(wc->params.range_end);
        Safefree(wc);
        croak("Failed to create gRPC call for watch");
    }

    /* Start the call with initial operations */
    grpc_op ops[4] = {0};
    grpc_metadata auth_md;

    /* Send initial metadata (with auth token if available) */
    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);

    /* Receive initial metadata */
    ops[1].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[1].data.recv_initial_metadata.recv_initial_metadata = &wc->initial_metadata;

    /* Send the watch create request */
    ops[2].op = GRPC_OP_SEND_MESSAGE;
    ops[2].data.send_message.send_message = send_buffer;

    /* Receive the first response (WatchResponse with created=true) */
    ops[3].op = GRPC_OP_RECV_MESSAGE;
    ops[3].data.recv_message.recv_message = &wc->recv_buffer;

    /* Start batch - status receive is handled separately when stream ends */
    grpc_call_error err = grpc_call_start_batch(wc->call, ops, 4, &wc->base, NULL);

    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        grpc_metadata_array_destroy(&wc->initial_metadata);
        grpc_metadata_array_destroy(&wc->trailing_metadata);
        grpc_slice_unref(wc->status_details);
        grpc_call_unref(wc->call);
        SvREFCNT_dec(wc->callback);
        /* Free watch params allocated for recovery */
        if (wc->params.key) {
            Safefree(wc->params.key);
        }
        if (wc->params.range_end) {
            Safefree(wc->params.range_end);
        }
        Safefree(wc);
        /* Note: range_end_copy already freed before call creation */
        croak("Failed to start watch call: %d", err);
    }

    /* Add to watches list */
    wc->next = client->watches;
    client->watches = wc;

    RETVAL = wc;
}
OUTPUT:
    RETVAL

void
ev_etcd_lease_grant(client, ttl, callback)
    EV::Etcd client
    IV ttl
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    /* Create pending call structure */
    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_LEASE_GRANT, callback, client);

    /* Build LeaseGrantRequest */
    Etcdserverpb__LeaseGrantRequest req = ETCDSERVERPB__LEASE_GRANT_REQUEST__INIT;
    req.ttl = ttl;

    /* Serialize request */
    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__lease_grant_request__get_packed_size,
        etcdserverpb__lease_grant_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    /* Create call */
    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

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

    /* Set up operations */
    grpc_op ops[6] = {0};
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);

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

    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
}

void
ev_etcd_lease_revoke(client, lease_id, callback)
    EV::Etcd client
    IV lease_id
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    /* Create pending call structure */
    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_LEASE_REVOKE, callback, client);

    /* Build LeaseRevokeRequest */
    Etcdserverpb__LeaseRevokeRequest req = ETCDSERVERPB__LEASE_REVOKE_REQUEST__INIT;
    req.id = lease_id;

    /* Serialize request */
    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__lease_revoke_request__get_packed_size,
        etcdserverpb__lease_revoke_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    /* Create call */
    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

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

    /* Set up operations */
    grpc_op ops[6] = {0};
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);

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

    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
}

void
ev_etcd_lease_time_to_live(client, lease_id, ...)
    EV::Etcd client
    IV lease_id
CODE:
{
    /* Parse arguments: lease_time_to_live(lease_id, [opts,] callback) */
    SV *opts = NULL;
    SV *callback;

    if (items == 3) {
        /* lease_time_to_live(lease_id, callback) */
        callback = ST(2);
    } else if (items == 4) {
        /* lease_time_to_live(lease_id, opts, callback) */
        opts = ST(2);
        callback = ST(3);
    } else {
        croak("Usage: $client->lease_time_to_live($lease_id, [\\%%opts,] $callback)");
    }

    VALIDATE_CALLBACK(callback);

    /* Create pending call structure */
    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_LEASE_TIME_TO_LIVE, callback, client);

    /* Build LeaseTimeToLiveRequest */
    Etcdserverpb__LeaseTimeToLiveRequest req = ETCDSERVERPB__LEASE_TIME_TO_LIVE_REQUEST__INIT;
    req.id = lease_id;

    /* Parse options if provided */
    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        HV *hv = (HV *)SvRV(opts);
        SV **svp;

        /* keys - if true, also return the keys attached to this lease */
        if ((svp = hv_fetchs(hv, "keys", 0)) && SvTRUE(*svp)) {
            req.keys = 1;
        }
    }

    /* Serialize request */
    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__lease_time_to_live_request__get_packed_size,
        etcdserverpb__lease_time_to_live_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    /* Create call */
    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

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

    /* Set up operations */
    grpc_op ops[6] = {0};
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);

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

    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
}

void
ev_etcd_lease_leases(client, callback)
    EV::Etcd client
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    /* Create pending call structure */
    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_LEASE_LEASES, callback, client);

    /* Build LeaseLeasesRequest (empty message) */
    Etcdserverpb__LeaseLeasesRequest req = ETCDSERVERPB__LEASE_LEASES_REQUEST__INIT;

    /* Serialize request */
    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__lease_leases_request__get_packed_size,
        etcdserverpb__lease_leases_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    /* Create call */
    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

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

    /* Set up operations */
    grpc_op ops[6] = {0};
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);

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

    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
}

void
ev_etcd_compact(client, revision, ...)
    EV::Etcd client
    IV revision
CODE:
{
    /* Parse arguments: compact(revision, [opts,] callback) */
    SV *opts = NULL;
    SV *callback;

    if (items == 3) {
        /* compact(revision, callback) */
        callback = ST(2);
    } else if (items == 4) {
        /* compact(revision, opts, callback) */
        opts = ST(2);
        callback = ST(3);
    } else {
        croak("Usage: $client->compact($revision, [\\%%opts,] $callback)");
    }

    VALIDATE_CALLBACK(callback);

    /* Create pending call structure */
    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_COMPACT, callback, client);

    /* Build CompactionRequest */
    Etcdserverpb__CompactionRequest req = ETCDSERVERPB__COMPACTION_REQUEST__INIT;
    req.revision = revision;

    /* Parse options if provided */
    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        HV *hv = (HV *)SvRV(opts);
        SV **svp;

        /* physical - if true, wait until compaction is physically applied */
        if ((svp = hv_fetchs(hv, "physical", 0)) && SvTRUE(*svp)) {
            req.physical = 1;
        }
    }

    /* Serialize request */
    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__compaction_request__get_packed_size,
        etcdserverpb__compaction_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    /* Create call */
    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

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

    /* Set up operations */
    grpc_op ops[6] = {0};
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);

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

    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
}

void
ev_etcd_status(client, callback)
    EV::Etcd client
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    /* Create pending call structure */
    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_STATUS, callback, client);

    /* Build StatusRequest (empty message) */
    Etcdserverpb__StatusRequest req = ETCDSERVERPB__STATUS_REQUEST__INIT;

    /* Serialize request */
    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__status_request__get_packed_size,
        etcdserverpb__status_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    /* Create call */
    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

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

    /* Set up operations */
    grpc_op ops[6] = {0};
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);

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

    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
}

EV::Etcd::Keepalive
ev_etcd_lease_keepalive(client, lease_id, ...)
    EV::Etcd client
    IV lease_id
CODE:
{
    /* Parse arguments: lease_keepalive(lease_id, [opts,] callback) */
    SV *opts = NULL;
    SV *callback;

    if (items == 3) {
        callback = ST(2);
    } else if (items == 4) {
        opts = ST(2);
        callback = ST(3);
    } else {
        croak("Usage: $client->lease_keepalive($lease_id, [\\%%opts,] $callback)");
    }

    VALIDATE_CALLBACK(callback);

    /* Create keepalive structure */
    keepalive_call_t *kc;
    Newxz(kc, 1, keepalive_call_t);
    init_call_base(&kc->base, CALL_TYPE_LEASE_KEEPALIVE);
    kc->callback = newSVsv(callback);
    kc->client = client;
    kc->active = 1;
    kc->auto_reconnect = 1;  /* Enable by default */
    kc->lease_id = lease_id;

    /* Process options */
    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        HV *hv = (HV *)SvRV(opts);
        SV **svp;

        if ((svp = hv_fetchs(hv, "auto_reconnect", 0)) && !SvTRUE(*svp)) {
            kc->auto_reconnect = 0;
        }
    }
    grpc_metadata_array_init(&kc->initial_metadata);
    grpc_metadata_array_init(&kc->trailing_metadata);
    kc->recv_buffer = NULL;
    kc->status_details = grpc_empty_slice();

    /* Build LeaseKeepAliveRequest */
    Etcdserverpb__LeaseKeepAliveRequest req = ETCDSERVERPB__LEASE_KEEP_ALIVE_REQUEST__INIT;
    req.id = lease_id;

    /* Serialize request */
    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__lease_keep_alive_request__get_packed_size,
        etcdserverpb__lease_keep_alive_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    /* Create streaming call */
    gpr_timespec deadline = gpr_inf_future(GPR_CLOCK_REALTIME);

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
        grpc_metadata_array_destroy(&kc->initial_metadata);
        grpc_metadata_array_destroy(&kc->trailing_metadata);
        grpc_slice_unref(kc->status_details);
        SvREFCNT_dec(kc->callback);
        Safefree(kc);
        croak("Failed to create gRPC call for lease_keepalive");
    }

    /* Start the call with initial operations */
    grpc_op ops[4] = {0};
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);

    ops[1].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[1].data.recv_initial_metadata.recv_initial_metadata = &kc->initial_metadata;

    ops[2].op = GRPC_OP_SEND_MESSAGE;
    ops[2].data.send_message.send_message = send_buffer;

    /* Receive the first response */
    ops[3].op = GRPC_OP_RECV_MESSAGE;
    ops[3].data.recv_message.recv_message = &kc->recv_buffer;

    grpc_call_error err = grpc_call_start_batch(kc->call, ops, 4, &kc->base, NULL);

    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        grpc_metadata_array_destroy(&kc->initial_metadata);
        grpc_metadata_array_destroy(&kc->trailing_metadata);
        grpc_slice_unref(kc->status_details);
        grpc_call_unref(kc->call);
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

    /* Pre-validate compare key/value sizes before allocating pending call */
    if (SvROK(compare_av) && SvTYPE(SvRV(compare_av)) == SVt_PVAV) {
        AV *av = (AV *)SvRV(compare_av);
        size_t n = av_len(av) + 1;
        for (size_t i = 0; i < n; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                HV *hv = (HV *)SvRV(*elem);
                SV **key_sv = hv_fetch(hv, "key", 3, 0);
                if (key_sv && SvOK(*key_sv)) {
                    VALIDATE_KEY_SIZE(SvCUR(*key_sv));
                }
                SV **value_sv = hv_fetch(hv, "value", 5, 0);
                if (value_sv && SvOK(*value_sv)) {
                    VALIDATE_VALUE_SIZE(SvCUR(*value_sv));
                }
            }
        }
    }

    /* Create pending call structure */
    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_TXN, callback, client);

    /* Build TxnRequest */
    Etcdserverpb__TxnRequest req = ETCDSERVERPB__TXN_REQUEST__INIT;

    /* Parse compare array */
    size_t n_compare = 0;
    Etcdserverpb__Compare **compares = NULL;

    if (SvROK(compare_av) && SvTYPE(SvRV(compare_av)) == SVt_PVAV) {
        AV *av = (AV *)SvRV(compare_av);
        n_compare = av_len(av) + 1;
        if (n_compare > 0) {
            Newxz(compares, n_compare, Etcdserverpb__Compare *);
            for (size_t i = 0; i < n_compare; i++) {
                SV **elem = av_fetch(av, i, 0);
                if (elem && SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
                    HV *hv = (HV *)SvRV(*elem);
                    Newxz(compares[i], 1, Etcdserverpb__Compare);
                    etcdserverpb__compare__init(compares[i]);

                    /* key */
                    SV **key_sv = hv_fetch(hv, "key", 3, 0);
                    if (key_sv && SvOK(*key_sv)) {
                        STRLEN len;
                        char *str = SvPV(*key_sv, len);
                        compares[i]->key.data = (uint8_t *)str;
                        compares[i]->key.len = len;
                    }

                    /* target: version, create, mod, value, lease */
                    SV **target_sv = hv_fetch(hv, "target", 6, 0);
                    if (target_sv && SvPOK(*target_sv)) {
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

                    /* result: =, !=, <, > */
                    SV **result_sv = hv_fetch(hv, "result", 6, 0);
                    if (result_sv && SvPOK(*result_sv)) {
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

                    /* target_union value based on target - auto-set target if not specified */
                    SV **version_sv = hv_fetch(hv, "version", 7, 0);
                    if (version_sv && SvOK(*version_sv)) {
                        compares[i]->target_union_case = ETCDSERVERPB__COMPARE__TARGET_UNION_VERSION;
                        compares[i]->version = SvIV(*version_sv);
                        if (!target_sv)
                            compares[i]->target = ETCDSERVERPB__COMPARE__COMPARE_TARGET__VERSION;
                    }

                    SV **create_rev_sv = hv_fetch(hv, "create_revision", 15, 0);
                    if (create_rev_sv && SvOK(*create_rev_sv)) {
                        compares[i]->target_union_case = ETCDSERVERPB__COMPARE__TARGET_UNION_CREATE_REVISION;
                        compares[i]->create_revision = SvIV(*create_rev_sv);
                        if (!target_sv)
                            compares[i]->target = ETCDSERVERPB__COMPARE__COMPARE_TARGET__CREATE;
                    }

                    SV **mod_rev_sv = hv_fetch(hv, "mod_revision", 12, 0);
                    if (mod_rev_sv && SvOK(*mod_rev_sv)) {
                        compares[i]->target_union_case = ETCDSERVERPB__COMPARE__TARGET_UNION_MOD_REVISION;
                        compares[i]->mod_revision = SvIV(*mod_rev_sv);
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
                        /* Auto-set target to VALUE if not explicitly specified */
                        if (!target_sv)
                            compares[i]->target = ETCDSERVERPB__COMPARE__COMPARE_TARGET__VALUE;
                    }

                    SV **lease_sv = hv_fetch(hv, "lease", 5, 0);
                    if (lease_sv && SvOK(*lease_sv)) {
                        compares[i]->target_union_case = ETCDSERVERPB__COMPARE__TARGET_UNION_LEASE;
                        compares[i]->lease = SvIV(*lease_sv);
                        /* Auto-set target to LEASE if not explicitly specified */
                        if (!target_sv)
                            compares[i]->target = ETCDSERVERPB__COMPARE__COMPARE_TARGET__LEASE;
                    }
                }
            }
        }
    }
    req.n_compare = n_compare;
    req.compare = compares;

    /* Parse success operations */
    size_t n_success;
    Etcdserverpb__RequestOp **success_ops;
    parse_request_ops(aTHX_ success_av, &success_ops, &n_success);
    req.n_success = n_success;
    req.success = success_ops;

    /* Parse failure operations */
    size_t n_failure;
    Etcdserverpb__RequestOp **failure_ops;
    parse_request_ops(aTHX_ failure_av, &failure_ops, &n_failure);
    req.n_failure = n_failure;
    req.failure = failure_ops;

    /* Serialize request directly to grpc_slice */
    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__txn_request__get_packed_size,
        etcdserverpb__txn_request__pack, &req);

    /* Free allocated structures (data pointers point to Perl SVs, don't free those) */
    for (size_t i = 0; i < n_compare; i++) {
        Safefree(compares[i]);
    }
    if (compares) Safefree(compares);

    /* Free request_ops arrays using helper macro */
    FREE_REQUEST_OPS(success_ops, n_success);
    FREE_REQUEST_OPS(failure_ops, n_failure);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    /* Create call */
    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

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

    /* Set up operations */
    grpc_op ops[6] = {0};
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);

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

    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
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

    VALIDATE_USERNAME_SIZE(user_len);
    VALIDATE_PASSWORD_SIZE(pass_len);

    /* Copy password to temporary buffer so we can zero it after use */
    char *pass_str;
    Newx(pass_str, pass_len + 1, char);
    Copy(pass_src, pass_str, pass_len, char);
    pass_str[pass_len] = '\0';

    /* Create pending call structure */
    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_AUTH, callback, client);

    /* Build AuthenticateRequest */
    Etcdserverpb__AuthenticateRequest req = ETCDSERVERPB__AUTHENTICATE_REQUEST__INIT;
    req.name = user_str;
    req.password = pass_str;

    /* Serialize request */
    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__authenticate_request__get_packed_size,
        etcdserverpb__authenticate_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    /* Zero and free password buffer */
    memset(pass_str, 0, pass_len);
    Safefree(pass_str);

    /* Create call */
    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

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

    /* Set up operations */
    grpc_op ops[6] = {0};
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);

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

    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
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

    VALIDATE_USERNAME_SIZE(user_len);
    VALIDATE_PASSWORD_SIZE(pass_len);

    /* Copy password to temporary buffer so we can zero it after use */
    char *pass_str;
    Newx(pass_str, pass_len + 1, char);
    Copy(pass_src, pass_str, pass_len, char);
    pass_str[pass_len] = '\0';

    /* Create pending call structure */
    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_USER_ADD, callback, client);

    /* Build AuthUserAddRequest */
    Etcdserverpb__AuthUserAddRequest req = ETCDSERVERPB__AUTH_USER_ADD_REQUEST__INIT;
    req.name = user_str;
    req.password = pass_str;

    /* Serialize request */
    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__auth_user_add_request__get_packed_size,
        etcdserverpb__auth_user_add_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    /* Zero and free password buffer */
    memset(pass_str, 0, pass_len);
    Safefree(pass_str);

    /* Create call */
    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

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

    /* Set up operations */
    grpc_op ops[6] = {0};
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);

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

    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
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
    VALIDATE_USERNAME_SIZE(user_len);

    /* Create pending call structure */
    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_USER_DELETE, callback, client);

    /* Build AuthUserDeleteRequest */
    Etcdserverpb__AuthUserDeleteRequest req = ETCDSERVERPB__AUTH_USER_DELETE_REQUEST__INIT;
    req.name = user_str;

    /* Serialize request */
    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__auth_user_delete_request__get_packed_size,
        etcdserverpb__auth_user_delete_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    /* Create call */
    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

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

    /* Set up operations */
    grpc_op ops[6] = {0};
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);

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

    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
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

    VALIDATE_USERNAME_SIZE(user_len);
    VALIDATE_PASSWORD_SIZE(pass_len);

    /* Copy password to temporary buffer so we can zero it after use */
    char *pass_str;
    Newx(pass_str, pass_len + 1, char);
    Copy(pass_src, pass_str, pass_len, char);
    pass_str[pass_len] = '\0';

    /* Create pending call structure */
    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_USER_CHANGE_PASSWORD, callback, client);

    /* Build AuthUserChangePasswordRequest */
    Etcdserverpb__AuthUserChangePasswordRequest req = ETCDSERVERPB__AUTH_USER_CHANGE_PASSWORD_REQUEST__INIT;
    req.name = user_str;
    req.password = pass_str;

    /* Serialize request */
    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__auth_user_change_password_request__get_packed_size,
        etcdserverpb__auth_user_change_password_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    /* Zero and free password buffer */
    memset(pass_str, 0, pass_len);
    Safefree(pass_str);

    /* Create call */
    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

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

    /* Set up operations */
    grpc_op ops[6] = {0};
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);

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

    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
}

void
ev_etcd_auth_enable(client, callback)
    EV::Etcd client
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    /* Create pending call structure */
    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_AUTH_ENABLE, callback, client);

    /* Build AuthEnableRequest (empty message) */
    Etcdserverpb__AuthEnableRequest req = ETCDSERVERPB__AUTH_ENABLE_REQUEST__INIT;

    /* Serialize request */
    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__auth_enable_request__get_packed_size,
        etcdserverpb__auth_enable_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    /* Create call */
    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

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

    /* Set up operations */
    grpc_op ops[6] = {0};
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);

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

    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
}

void
ev_etcd_auth_disable(client, callback)
    EV::Etcd client
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    /* Create pending call structure */
    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_AUTH_DISABLE, callback, client);

    /* Build AuthDisableRequest (empty message) */
    Etcdserverpb__AuthDisableRequest req = ETCDSERVERPB__AUTH_DISABLE_REQUEST__INIT;

    /* Serialize request */
    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__auth_disable_request__get_packed_size,
        etcdserverpb__auth_disable_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    /* Create call */
    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

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

    /* Set up operations */
    grpc_op ops[6] = {0};
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);

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

    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
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
    VALIDATE_USERNAME_SIZE(name_len);  /* Role names have same limits as usernames */

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_ROLE_ADD, callback, client);

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
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);
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
    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
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
    VALIDATE_USERNAME_SIZE(name_len);  /* Role names have same limits as usernames */

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_ROLE_DELETE, callback, client);

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
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);
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
    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
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
    VALIDATE_USERNAME_SIZE(name_len);  /* Role names have same limits as usernames */

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_ROLE_GET, callback, client);

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
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);
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
    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
}

void
ev_etcd_role_list(client, callback)
    EV::Etcd client
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_ROLE_LIST, callback, client);

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
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);
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
    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
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
    char *range_str = SvOK(range_end) ? SvPV(range_end, range_len) : NULL;
    VALIDATE_USERNAME_SIZE(name_len);  /* Role names have same limits as usernames */
    VALIDATE_KEY_SIZE(key_len);
    if (range_str) {
        VALIDATE_KEY_SIZE(range_len);
    }

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_ROLE_GRANT_PERMISSION, callback, client);

    /* Parse permission type */
    Etcdserverpb__Permission__Type pt = ETCDSERVERPB__PERMISSION__TYPE__READ;
    if (strEQ(type_str, "WRITE") || strEQ(type_str, "write")) {
        pt = ETCDSERVERPB__PERMISSION__TYPE__WRITE;
    } else if (strEQ(type_str, "READWRITE") || strEQ(type_str, "readwrite")) {
        pt = ETCDSERVERPB__PERMISSION__TYPE__READWRITE;
    }

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
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);
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
    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
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
    char *range_str = SvOK(range_end) ? SvPV(range_end, range_len) : NULL;
    VALIDATE_USERNAME_SIZE(name_len);  /* Role names have same limits as usernames */
    VALIDATE_KEY_SIZE(key_len);
    if (range_str) {
        VALIDATE_KEY_SIZE(range_len);
    }

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_ROLE_REVOKE_PERMISSION, callback, client);

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
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);
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
    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
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
    VALIDATE_USERNAME_SIZE(user_len);
    VALIDATE_USERNAME_SIZE(role_len);  /* Role names have same limits as usernames */

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_USER_GRANT_ROLE, callback, client);

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
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);
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
    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
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
    VALIDATE_USERNAME_SIZE(user_len);
    VALIDATE_USERNAME_SIZE(role_len);  /* Role names have same limits as usernames */

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_USER_REVOKE_ROLE, callback, client);

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
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);
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
    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
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
    VALIDATE_USERNAME_SIZE(name_len);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_USER_GET, callback, client);

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
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);
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
    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
}

void
ev_etcd_user_list(client, callback)
    EV::Etcd client
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_USER_LIST, callback, client);

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
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);
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
    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
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

    STRLEN name_len;
    const char *name_str = SvPV(name, name_len);
    VALIDATE_KEY_SIZE(name_len);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_LOCK, callback, client);

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

    /* Lock blocks until acquired — use infinite deadline */
    gpr_timespec deadline = gpr_inf_future(GPR_CLOCK_REALTIME);

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
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);
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
    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
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
    INIT_PENDING_CALL(pc, CALL_TYPE_UNLOCK, callback, client);

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
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);
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
    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
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

    STRLEN name_len, value_len;
    const char *name_str = SvPV(name, name_len);
    const char *value_str = SvPV(value, value_len);
    VALIDATE_KEY_SIZE(name_len);
    VALIDATE_VALUE_SIZE(value_len);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_ELECTION_CAMPAIGN, callback, client);

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

    /* Campaign blocks until elected — use infinite deadline */
    gpr_timespec deadline = gpr_inf_future(GPR_CLOCK_REALTIME);

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
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);
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
    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
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

    /* Extract and validate leader key fields before allocating */
    SV **sv_name = hv_fetch(leader_hv, "name", 4, 0);
    SV **sv_key = hv_fetch(leader_hv, "key", 3, 0);
    SV **sv_rev = hv_fetch(leader_hv, "rev", 3, 0);
    SV **sv_lease = hv_fetch(leader_hv, "lease", 5, 0);

    STRLEN name_len = 0, key_len = 0;
    const char *name_str = sv_name && *sv_name ? SvPV(*sv_name, name_len) : "";
    const char *key_str = sv_key && *sv_key ? SvPV(*sv_key, key_len) : "";
    VALIDATE_KEY_SIZE(name_len);
    VALIDATE_KEY_SIZE(key_len);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_ELECTION_PROCLAIM, callback, client);

    V3electionpb__LeaderKey lk = V3ELECTIONPB__LEADER_KEY__INIT;
    lk.name.data = (uint8_t *)name_str;
    lk.name.len = name_len;
    lk.key.data = (uint8_t *)key_str;
    lk.key.len = key_len;
    lk.rev = sv_rev && *sv_rev ? SvIV(*sv_rev) : 0;
    lk.lease = sv_lease && *sv_lease ? SvIV(*sv_lease) : 0;

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
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);
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
    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
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
    INIT_PENDING_CALL(pc, CALL_TYPE_ELECTION_LEADER, callback, client);

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
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);
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
    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
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

    /* Extract and validate leader key fields before allocating pending call */
    SV **sv_name = hv_fetch(leader_hv, "name", 4, 0);
    SV **sv_key = hv_fetch(leader_hv, "key", 3, 0);
    SV **sv_rev = hv_fetch(leader_hv, "rev", 3, 0);
    SV **sv_lease = hv_fetch(leader_hv, "lease", 5, 0);

    STRLEN name_len = 0, key_len = 0;
    const char *name_str = sv_name && *sv_name ? SvPV(*sv_name, name_len) : "";
    const char *key_str = sv_key && *sv_key ? SvPV(*sv_key, key_len) : "";
    VALIDATE_KEY_SIZE(name_len);
    VALIDATE_KEY_SIZE(key_len);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_ELECTION_RESIGN, callback, client);

    V3electionpb__LeaderKey lk = V3ELECTIONPB__LEADER_KEY__INIT;
    lk.name.data = (uint8_t *)name_str;
    lk.name.len = name_len;
    lk.key.data = (uint8_t *)key_str;
    lk.key.len = key_len;
    lk.rev = sv_rev && *sv_rev ? SvIV(*sv_rev) : 0;
    lk.lease = sv_lease && *sv_lease ? SvIV(*sv_lease) : 0;

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
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);
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
    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
}

EV::Etcd::Observe
ev_etcd_election_observe(client, name, ...)
    EV::Etcd client
    SV *name
CODE:
{
    /* Parse arguments: election_observe(name, [opts,] callback) */
    SV *opts = NULL;
    SV *callback;

    if (items == 3) {
        callback = ST(2);
    } else if (items == 4) {
        opts = ST(2);
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
        SV **sv_ar = hv_fetch(hv, "auto_reconnect", 14, 0);
        if (sv_ar && *sv_ar) {
            auto_reconnect = SvTRUE(*sv_ar);
        }
    }

    observe_call_t *oc;
    Newxz(oc, 1, observe_call_t);
    init_call_base(&oc->base, CALL_TYPE_ELECTION_OBSERVE);
    oc->callback = newSVsv(callback);
    oc->client = client;
    oc->active = 1;
    oc->auto_reconnect = auto_reconnect;
    oc->reconnect_attempt = 0;
    grpc_metadata_array_init(&oc->initial_metadata);
    grpc_metadata_array_init(&oc->trailing_metadata);
    oc->recv_buffer = NULL;
    oc->status_details = grpc_empty_slice();

    /* Save params for reconnection */
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

    /* Use infinite deadline for streaming call */
    gpr_timespec deadline = gpr_inf_future(GPR_CLOCK_REALTIME);

    oc->call = grpc_channel_create_call(
        client->channel, NULL, GRPC_PROPAGATE_DEFAULTS,
        client->cq, METHOD_ELECTION_OBSERVE, NULL, deadline, NULL
    );

    if (!oc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        grpc_metadata_array_destroy(&oc->initial_metadata);
        grpc_metadata_array_destroy(&oc->trailing_metadata);
        grpc_slice_unref(oc->status_details);
        SvREFCNT_dec(oc->callback);
        if (oc->params.name) Safefree(oc->params.name);
        Safefree(oc);
        croak("Failed to create gRPC call for election_observe");
    }

    grpc_op ops[4] = {0};
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);

    ops[1].op = GRPC_OP_RECV_INITIAL_METADATA;
    ops[1].data.recv_initial_metadata.recv_initial_metadata = &oc->initial_metadata;

    ops[2].op = GRPC_OP_SEND_MESSAGE;
    ops[2].data.send_message.send_message = send_buffer;

    ops[3].op = GRPC_OP_RECV_MESSAGE;
    ops[3].data.recv_message.recv_message = &oc->recv_buffer;

    grpc_call_error err = grpc_call_start_batch(oc->call, ops, 4, &oc->base, NULL);
    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        grpc_metadata_array_destroy(&oc->initial_metadata);
        grpc_metadata_array_destroy(&oc->trailing_metadata);
        grpc_slice_unref(oc->status_details);
        grpc_call_unref(oc->call);
        SvREFCNT_dec(oc->callback);
        if (oc->params.name) Safefree(oc->params.name);
        Safefree(oc);
        croak("Failed to start gRPC call: %d", err);
    }

    /* Add to observes list */
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
        opts = ST(1);
        callback = ST(2);
    } else {
        croak("Usage: $client->member_list([\\%%opts,] $callback)");
    }

    VALIDATE_CALLBACK(callback);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_MEMBER_LIST, callback, client);

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
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);
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
    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
}

void
ev_etcd_member_add(client, peer_urls, ...)
    EV::Etcd client
    SV *peer_urls
CODE:
{
    /* Parse arguments: member_add(peer_urls, [opts,] callback) */
    SV *opts = NULL;
    SV *callback;

    if (items == 3) {
        /* member_add(peer_urls, callback) */
        callback = ST(2);
    } else if (items == 4) {
        /* member_add(peer_urls, opts, callback) */
        opts = ST(2);
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
        SV **svp = hv_fetchs(hv, "is_learner", 0);
        if (svp && SvTRUE(*svp)) {
            is_learner = 1;
        }
    }

    /* Pre-validate URL sizes before allocating pending call */
    for (size_t i = 0; i < n_urls; i++) {
        SV **sv = av_fetch(urls_av, i, 0);
        if (sv && *sv) {
            STRLEN url_len;
            (void)SvPV(*sv, url_len);
            VALIDATE_URL_SIZE(url_len);
        }
    }

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_MEMBER_ADD, callback, client);

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
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);
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
    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
}

void
ev_etcd_member_remove(client, id, callback)
    EV::Etcd client
    UV id
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_MEMBER_REMOVE, callback, client);

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
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);
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
    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
}

void
ev_etcd_member_update(client, id, peer_urls, callback)
    EV::Etcd client
    UV id
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

    /* Pre-validate URL sizes before allocating pending call */
    for (size_t i = 0; i < n_urls; i++) {
        SV **sv = av_fetch(urls_av, i, 0);
        if (sv && *sv) {
            STRLEN url_len;
            (void)SvPV(*sv, url_len);
            VALIDATE_URL_SIZE(url_len);
        }
    }

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_MEMBER_UPDATE, callback, client);

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
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);
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
    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
}

void
ev_etcd_member_promote(client, id, callback)
    EV::Etcd client
    UV id
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_MEMBER_PROMOTE, callback, client);

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
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);
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
    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
}

void
ev_etcd_alarm(client, action, ...)
    EV::Etcd client
    char *action
CODE:
{
    /* Parse arguments: alarm(action, [opts,] callback) */
    SV *opts = NULL;
    SV *callback;

    if (items == 3) {
        /* alarm(action, callback) */
        callback = ST(2);
    } else if (items == 4) {
        /* alarm(action, opts, callback) */
        opts = ST(2);
        callback = ST(3);
    } else {
        croak("Usage: $client->alarm($action, [\\%%opts,] $callback)");
    }

    VALIDATE_CALLBACK(callback);

    /* Parse action before allocating to prevent croak leak */
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

    /* Create pending call structure */
    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_ALARM, callback, client);

    /* Build AlarmRequest */
    Etcdserverpb__AlarmRequest req = ETCDSERVERPB__ALARM_REQUEST__INIT;
    req.action = alarm_action;

    /* Parse options if provided */
    if (opts && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
        HV *hv = (HV *)SvRV(opts);
        SV **svp;

        /* member_id - optional member ID (0 means all members) */
        if ((svp = hv_fetchs(hv, "member_id", 0))) {
            req.memberid = SvUV(*svp);
        }

        /* alarm - alarm type (NOSPACE, CORRUPT) */
        if ((svp = hv_fetchs(hv, "alarm", 0))) {
            char *alarm_str = SvPV_nolen(*svp);
            if (strcasecmp(alarm_str, "NOSPACE") == 0) {
                req.alarm = ETCDSERVERPB__ALARM_TYPE__NOSPACE;
            } else if (strcasecmp(alarm_str, "CORRUPT") == 0) {
                req.alarm = ETCDSERVERPB__ALARM_TYPE__CORRUPT;
            } else if (strcasecmp(alarm_str, "NONE") == 0) {
                req.alarm = ETCDSERVERPB__ALARM_TYPE__NONE;
            }
        }
    }

    /* Serialize request */
    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__alarm_request__get_packed_size,
        etcdserverpb__alarm_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    /* Create call */
    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

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

    /* Set up operations */
    grpc_op ops[6] = {0};
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);

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

    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
}

void
ev_etcd_defragment(client, callback)
    EV::Etcd client
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    /* Create pending call structure */
    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_DEFRAGMENT, callback, client);

    /* Build DefragmentRequest (empty message) */
    Etcdserverpb__DefragmentRequest req = ETCDSERVERPB__DEFRAGMENT_REQUEST__INIT;

    /* Serialize request */
    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__defragment_request__get_packed_size,
        etcdserverpb__defragment_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    /* Create call */
    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

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

    /* Set up operations */
    grpc_op ops[6] = {0};
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);

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

    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
}

void
ev_etcd_hash_kv(client, ...)
    EV::Etcd client
CODE:
{
    /* Parse arguments: hash_kv([revision,] callback) */
    int64_t revision = 0;
    SV *callback;

    if (items == 2) {
        /* hash_kv(callback) */
        callback = ST(1);
    } else if (items == 3) {
        /* hash_kv(revision, callback) */
        revision = SvIV(ST(1));
        callback = ST(2);
    } else {
        croak("Usage: $client->hash_kv([$revision,] $callback)");
    }

    VALIDATE_CALLBACK(callback);

    /* Create pending call structure */
    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_HASH_KV, callback, client);

    /* Build HashKVRequest */
    Etcdserverpb__HashKVRequest req = ETCDSERVERPB__HASH_KV_REQUEST__INIT;
    req.revision = revision;

    /* Serialize request */
    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__hash_kv_request__get_packed_size,
        etcdserverpb__hash_kv_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    /* Create call */
    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

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

    /* Set up operations */
    grpc_op ops[6] = {0};
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);

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

    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
}

void
ev_etcd_move_leader(client, target_id, callback)
    EV::Etcd client
    UV target_id
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    /* Create pending call structure */
    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_MOVE_LEADER, callback, client);

    /* Build MoveLeaderRequest */
    Etcdserverpb__MoveLeaderRequest req = ETCDSERVERPB__MOVE_LEADER_REQUEST__INIT;
    req.targetid = target_id;

    /* Serialize request */
    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__move_leader_request__get_packed_size,
        etcdserverpb__move_leader_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    /* Create call */
    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

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

    /* Set up operations */
    grpc_op ops[6] = {0};
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);

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

    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
}

void
ev_etcd_auth_status(client, callback)
    EV::Etcd client
    SV *callback
CODE:
{
    VALIDATE_CALLBACK(callback);

    /* Create pending call structure */
    pending_call_t *pc;
    INIT_PENDING_CALL(pc, CALL_TYPE_AUTH_STATUS, callback, client);

    /* Build AuthStatusRequest (empty message) */
    Etcdserverpb__AuthStatusRequest req = ETCDSERVERPB__AUTH_STATUS_REQUEST__INIT;

    /* Serialize request */
    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__auth_status_request__get_packed_size,
        etcdserverpb__auth_status_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    /* Create call */
    gpr_timespec deadline = gpr_time_add(
        gpr_now(GPR_CLOCK_REALTIME),
        gpr_time_from_seconds(client->timeout_seconds, GPR_TIMESPAN)
    );

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

    /* Set up operations */
    grpc_op ops[6] = {0};
    grpc_metadata auth_md;

    ops[0].op = GRPC_OP_SEND_INITIAL_METADATA;
    setup_auth_metadata(client, &ops[0], &auth_md);

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

    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        CLEANUP_PENDING_CALL_ON_ERROR(pc);
        croak("Failed to start gRPC call: %d", err);
    }

    pc->next = client->pending_calls;
    client->pending_calls = pc;
}

void
ev_etcd_DESTROY(client)
    EV::Etcd client
CODE:
{
    /* Fork safety: in a child process, the gRPC thread and completion queue
     * are in undefined state. Skip gRPC cleanup, just free Perl-side resources. */
    if (client->owner_pid != getpid()) {
        warn("EV::Etcd: client destroyed in forked child (pid %d, created in %d)"
             " -- skipping gRPC cleanup", (int)getpid(), (int)client->owner_pid);

        /* Free SV callbacks and Safefree'd params only; don't touch gRPC objects */
        pending_call_t *pc = client->pending_calls;
        while (pc) {
            pending_call_t *next = pc->next;
            SvREFCNT_dec(pc->callback);
            Safefree(pc);
            pc = next;
        }
        watch_call_t *wc = client->watches;
        while (wc) {
            watch_call_t *next = wc->next;
            if (ev_is_active(&wc->reconnect_timer))
                ev_timer_stop(EV_DEFAULT, &wc->reconnect_timer);
            SvREFCNT_dec(wc->callback);
            if (wc->params.key) Safefree(wc->params.key);
            if (wc->params.range_end) Safefree(wc->params.range_end);
            Safefree(wc);
            wc = next;
        }
        keepalive_call_t *kc = client->keepalives;
        while (kc) {
            keepalive_call_t *next = kc->next;
            if (ev_is_active(&kc->reconnect_timer))
                ev_timer_stop(EV_DEFAULT, &kc->reconnect_timer);
            SvREFCNT_dec(kc->callback);
            Safefree(kc);
            kc = next;
        }
        observe_call_t *oc = client->observes;
        while (oc) {
            observe_call_t *next = oc->next;
            if (ev_is_active(&oc->reconnect_timer))
                ev_timer_stop(EV_DEFAULT, &oc->reconnect_timer);
            SvREFCNT_dec(oc->callback);
            if (oc->params.name) Safefree(oc->params.name);
            Safefree(oc);
            oc = next;
        }
        if (ev_is_active(&client->health_timer))
            ev_timer_stop(EV_DEFAULT, &client->health_timer);
        if (ev_is_active(&client->cq_async))
            ev_async_stop(EV_DEFAULT, &client->cq_async);
        goto free_perl_resources;
    }

    /* Mark client as inactive first to prevent callbacks from accessing freed memory */
    client->active = 0;

    /* Stop ev_async watcher */
    if (ev_is_active(&client->cq_async)) {
        ev_async_stop(EV_DEFAULT, &client->cq_async);
    }

    /* Signal the gRPC thread to stop and wait for it */
    client->thread_running = 0;

    /* Mark all watches and keepalives as inactive and cancel their gRPC calls.
     * This will cause pending operations to complete with success=0. */
    watch_call_t *wc = client->watches;
    while (wc) {
        wc->active = 0;
        if (ev_is_active(&wc->reconnect_timer))
            ev_timer_stop(EV_DEFAULT, &wc->reconnect_timer);
        if (wc->call) {
            grpc_call_cancel(wc->call, NULL);
        }
        wc = wc->next;
    }

    keepalive_call_t *kc = client->keepalives;
    while (kc) {
        kc->active = 0;
        if (ev_is_active(&kc->reconnect_timer))
            ev_timer_stop(EV_DEFAULT, &kc->reconnect_timer);
        if (kc->call) {
            grpc_call_cancel(kc->call, NULL);
        }
        kc = kc->next;
    }

    observe_call_t *oc = client->observes;
    while (oc) {
        oc->active = 0;
        if (ev_is_active(&oc->reconnect_timer))
            ev_timer_stop(EV_DEFAULT, &oc->reconnect_timer);
        if (oc->call) {
            grpc_call_cancel(oc->call, NULL);
        }
        oc = oc->next;
    }

    /* Cancel pending unary calls */
    pending_call_t *pc = client->pending_calls;
    while (pc) {
        if (pc->call) {
            grpc_call_cancel(pc->call, NULL);
        }
        pc = pc->next;
    }

    /* Shutdown the completion queue - this will cause the thread to exit */
    if (client->cq) {
        grpc_completion_queue_shutdown(client->cq);
    }

    /* Wait for the gRPC thread to finish */
    pthread_join(client->cq_thread, NULL);

    /* Clean up the event queue (any remaining queued events) */
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

    /* Destroy the mutex */
    pthread_mutex_destroy(&client->queue_mutex);

    /* Destroy the completion queue */
    if (client->cq) {
        grpc_completion_queue_destroy(client->cq);
    }

    /* Cleanup call structures - skip if called during event processing
     * (the currently-processing call struct would be a use-after-free).
     * Deferred to cq_async_callback when in_callback is set. */
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
            SvREFCNT_dec(pc->callback);
            Safefree(pc);
            pc = next;
        }

        wc = client->watches;
        while (wc) {
            watch_call_t *next = wc->next;
            grpc_metadata_array_destroy(&wc->initial_metadata);
            grpc_metadata_array_destroy(&wc->trailing_metadata);
            if (wc->recv_buffer) {
                grpc_byte_buffer_destroy(wc->recv_buffer);
            }
            grpc_slice_unref(wc->status_details);
            if (wc->call) {
                grpc_call_unref(wc->call);
            }
            SvREFCNT_dec(wc->callback);
            if (wc->params.key) {
                Safefree(wc->params.key);
            }
            if (wc->params.range_end) {
                Safefree(wc->params.range_end);
            }
            Safefree(wc);
            wc = next;
        }

        kc = client->keepalives;
        while (kc) {
            keepalive_call_t *next = kc->next;
            grpc_metadata_array_destroy(&kc->initial_metadata);
            grpc_metadata_array_destroy(&kc->trailing_metadata);
            if (kc->recv_buffer) {
                grpc_byte_buffer_destroy(kc->recv_buffer);
            }
            grpc_slice_unref(kc->status_details);
            if (kc->call) {
                grpc_call_unref(kc->call);
            }
            SvREFCNT_dec(kc->callback);
            Safefree(kc);
            kc = next;
        }

        oc = client->observes;
        while (oc) {
            observe_call_t *next = oc->next;
            grpc_metadata_array_destroy(&oc->initial_metadata);
            grpc_metadata_array_destroy(&oc->trailing_metadata);
            if (oc->recv_buffer) {
                grpc_byte_buffer_destroy(oc->recv_buffer);
            }
            grpc_slice_unref(oc->status_details);
            if (oc->call) {
                grpc_call_unref(oc->call);
            }
            SvREFCNT_dec(oc->callback);
            if (oc->params.name) {
                Safefree(oc->params.name);
            }
            Safefree(oc);
            oc = next;
        }
    }

    /* Stop health timer */
    ev_timer_stop(EV_DEFAULT, &client->health_timer);

    if (client->channel) {
        grpc_channel_destroy(client->channel);
    }

    free_perl_resources:
    /* Free health callback */
    if (client->health_callback) {
        SvREFCNT_dec(client->health_callback);
        client->health_callback = NULL;
    }

    /* Free auth token - securely zero before freeing */
    if (client->auth_token) {
        memset(client->auth_token, 0, client->auth_token_len);
        Safefree(client->auth_token);
        client->auth_token = NULL;
    }

    /* Free endpoints */
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

    /* If called during event processing, defer struct free to cq_async_callback */
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

    /* Stop reconnect timer unconditionally — may be pending even when active=0 */
    if (ev_is_active(&wc->reconnect_timer))
        ev_timer_stop(EV_DEFAULT, &wc->reconnect_timer);

    if (!wc->active) {
        CALL_SUCCESS_CALLBACK(callback, newHV());
        return;
    }

    wc->active = 0;

    /* If we have a watch_id, send cancel request */
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

        (void)grpc_call_start_batch(wc->call, &op, 1, NULL, NULL);
        grpc_byte_buffer_destroy(send_buffer);
    }

    /* Force pending RECV to complete immediately */
    if (wc->call)
        grpc_call_cancel(wc->call, NULL);

    CALL_SUCCESS_CALLBACK(callback, newHV());
}

void
ev_etcd_watch_DESTROY(watch)
    EV::Etcd::Watch watch
CODE:
{
    /* The watch_call_t is managed by the client's watches list.
     * DESTROY being called just means Perl lost its reference to the watch object,
     * but the watch is still active on the client side.
     * We intentionally do NOT deactivate the watch here.
     * If the user wants to stop the watch, they should call cancel().
     * The watch will be cleaned up when the client is destroyed. */
    (void)watch;  /* Silence unused parameter warning */
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

    /* Stop reconnect timer unconditionally — may be pending even when active=0 */
    if (ev_is_active(&kc->reconnect_timer))
        ev_timer_stop(EV_DEFAULT, &kc->reconnect_timer);

    if (!kc->active) {
        CALL_SUCCESS_CALLBACK(callback, newHV());
        return;
    }

    kc->active = 0;

    /* Force pending RECV to complete immediately */
    if (kc->call)
        grpc_call_cancel(kc->call, NULL);

    CALL_SUCCESS_CALLBACK(callback, newHV());
}

void
ev_etcd_keepalive_DESTROY(keepalive)
    EV::Etcd::Keepalive keepalive
CODE:
{
    (void)keepalive;
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

    /* Stop reconnect timer unconditionally — may be pending even when active=0 */
    if (ev_is_active(&oc->reconnect_timer))
        ev_timer_stop(EV_DEFAULT, &oc->reconnect_timer);

    if (!oc->active) {
        CALL_SUCCESS_CALLBACK(callback, newHV());
        return;
    }

    oc->active = 0;

    /* Force pending RECV to complete immediately */
    if (oc->call)
        grpc_call_cancel(oc->call, NULL);

    CALL_SUCCESS_CALLBACK(callback, newHV());
}

void
ev_etcd_observe_DESTROY(observe)
    EV::Etcd::Observe observe
CODE:
{
    (void)observe;
}

MODULE = EV::Etcd  PACKAGE = EV::Etcd  PREFIX = ev_etcd_

void
END()
CODE:
    grpc_shutdown();
