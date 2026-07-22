/*
 * etcd_watch.c - Watch operation handlers for EV::Etcd
 */
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "etcd_common.h"
#include "etcd_watch.h"

/* EVAPI.h's GEVAPI function table is a per-translation-unit static: every
 * file that calls into EV must bind its own copy, or ev_timer_start & co
 * dereference a NULL table. Called once from BOOT in Etcd.xs. */
void watch_init_ev_api(pTHX) {
    I_EV_API("EV::Etcd");
}

/* Re-arm watch to receive next message */
void watch_rearm_recv(pTHX_ watch_call_t *wc) {
    if (!wc->active) return;

    if (wc->recv_buffer) {
        grpc_byte_buffer_destroy(wc->recv_buffer);
        wc->recv_buffer = NULL;
    }

    wc->base.type = CALL_TYPE_WATCH_RECV;

    grpc_op op;
    memset(&op, 0, sizeof(op));
    op.op = GRPC_OP_RECV_MESSAGE;
    op.data.recv_message.recv_message = &wc->recv_buffer;

    grpc_call_error err = grpc_call_start_batch(wc->call, &op, 1, &wc->base, NULL);
    if (err != GRPC_CALL_OK) {
        wc->active = 0;
        CALL_STATUS_ERROR_CALLBACK(wc->callback, GRPC_STATUS_INTERNAL, "Watch rearm failed", "watch");
        cleanup_watch(aTHX_ wc);
    }
}

/* Free struct memory and key buffers — final step once both owners released */
static void watch_call_free(pTHX_ watch_call_t *wc) {
    if (wc->params.key) Safefree(wc->params.key);
    if (wc->params.range_end) Safefree(wc->params.range_end);
    Safefree(wc);
}

/* Client-side cleanup: free gRPC state, unlink from list, drop client ownership.
 * If Perl side already released, free the struct. Otherwise leave it alive and
 * inert for the Perl handle's DESTROY to free later — prevents UAF when the
 * user holds the handle past cancellation. */
void cleanup_watch(pTHX_ watch_call_t *wc) {
    if (!wc->client_owns) return;

    ev_etcd_t *client = wc->client;
    watch_call_t **wp = &client->watches;
    while (*wp) {
        if (*wp == wc) { *wp = wc->next; break; }
        wp = &(*wp)->next;
    }

    /* Unconditional: also clears an inactive-but-pending fired timer */
    ev_timer_stop(EV_DEFAULT, &wc->reconnect_timer);
    grpc_metadata_array_destroy(&wc->initial_metadata);
    grpc_metadata_array_destroy(&wc->trailing_metadata);
    if (wc->recv_buffer) {
        grpc_byte_buffer_destroy(wc->recv_buffer);
        wc->recv_buffer = NULL;
    }
    grpc_slice_unref(wc->status_details);
    if (wc->call) {
        grpc_call_unref(wc->call);
        wc->call = NULL;
    }
    SvREFCNT_dec(wc->callback);
    wc->callback = NULL;
    wc->active = 0;
    wc->client_owns = 0;

    if (!wc->perl_owns) watch_call_free(aTHX_ wc);
}

/* Perl-side cleanup: drop perl ownership; free struct if client side already done */
void watch_call_perl_release(pTHX_ watch_call_t *wc) {
    wc->perl_owns = 0;
    if (!wc->client_owns) watch_call_free(aTHX_ wc);
}

/* Process WatchResponse and call Perl callback */
void process_watch_response(pTHX_ watch_call_t *wc) {
    if (!wc->recv_buffer) {
        wc->active = 0;
        CALL_STATUS_ERROR_CALLBACK(wc->callback, GRPC_STATUS_INTERNAL, "No watch response received", "watch");
        return;
    }

    grpc_byte_buffer_reader reader;
    if (!grpc_byte_buffer_reader_init(&reader, wc->recv_buffer)) {
        wc->active = 0;
        CALL_STATUS_ERROR_CALLBACK(wc->callback, GRPC_STATUS_INTERNAL, "Failed to read watch response buffer", "watch");
        return;
    }

    grpc_slice slice = grpc_byte_buffer_reader_readall(&reader);
    grpc_byte_buffer_reader_destroy(&reader);

    Etcdserverpb__WatchResponse *resp = etcdserverpb__watch_response__unpack(
        NULL, GRPC_SLICE_LENGTH(slice), GRPC_SLICE_START_PTR(slice));
    grpc_slice_unref(slice);

    if (!resp) {
        wc->active = 0;
        CALL_STATUS_ERROR_CALLBACK(wc->callback, GRPC_STATUS_INTERNAL, "Failed to parse watch response", "watch");
        return;
    }

    if (resp->created) {
        wc->watch_id = resp->watch_id;
        wc->reconnect_attempt = 0;
    }

    if (resp->header && resp->header->revision > wc->last_revision) {
        wc->last_revision = resp->header->revision;
        wc->reconnect_attempt = 0;
    }

    if (resp->canceled) {
        wc->active = 0;
        const char *reason = (resp->cancel_reason && strlen(resp->cancel_reason) > 0)
            ? resp->cancel_reason : "Watch cancelled";
        CALL_STATUS_ERROR_CALLBACK(wc->callback, GRPC_STATUS_CANCELLED, reason, "watch");
        etcdserverpb__watch_response__free_unpacked(resp, NULL);
        return;
    }

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);

    hv_store(result, "watch_id", 8, newSVi64(resp->watch_id), 0);
    hv_store(result, "created", 7, newSViv(resp->created ? 1 : 0), 0);
    /* canceled / compact_revision are server-cancellation signals — handled
     * via the early-return error path above (resp->canceled) and never
     * appear in the success hash, so we don't store them here. */

    AV *events = newAV();
    if (resp->n_events > 0) {
        av_extend(events, resp->n_events - 1);
    }
    for (size_t i = 0; i < resp->n_events; i++) {
        av_push(events, event_to_hashref(aTHX_ resp->events[i]));
    }
    hv_store(result, "events", 6, newRV_noinc((SV *)events), 0);

    etcdserverpb__watch_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(wc->callback, result);
}

/* Perform the actual watch reconnection (called from timer callback) */
static void watch_reconnect_cb(struct ev_loop *loop, ev_timer *w, int revents) {
    dTHX;
    (void)loop;
    (void)revents;

    watch_call_t *wc = (watch_call_t *)((char *)w - offsetof(watch_call_t, reconnect_timer));
    ev_etcd_t *client = wc->client;

    if (!client->active) {
        cleanup_watch(aTHX_ wc);
        return;
    }

    /* Cleanup and reinitialize streaming state */
    STREAMING_CALL_CLEANUP(wc);
    STREAMING_CALL_REINIT(wc);

    /* Build watch create request */
    Etcdserverpb__WatchCreateRequest create_req = ETCDSERVERPB__WATCH_CREATE_REQUEST__INIT;
    create_req.key.data = (uint8_t *)wc->params.key;
    create_req.key.len = wc->params.key_len;

    if (wc->params.range_end && wc->params.range_end_len > 0) {
        create_req.range_end.data = (uint8_t *)wc->params.range_end;
        create_req.range_end.len = wc->params.range_end_len;
    }

    if (wc->last_revision > 0) {
        create_req.start_revision = wc->last_revision + 1;
    } else if (wc->params.start_revision > 0) {
        create_req.start_revision = wc->params.start_revision;
    }

    create_req.prev_kv = wc->params.prev_kv;
    create_req.progress_notify = wc->params.progress_notify;
    if (wc->params.has_watch_id)
        create_req.watch_id = wc->params.watch_id;

    Etcdserverpb__WatchRequest req = ETCDSERVERPB__WATCH_REQUEST__INIT;
    req.request_union_case = ETCDSERVERPB__WATCH_REQUEST__REQUEST_UNION_CREATE_REQUEST;
    req.create_request = &create_req;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__watch_request__get_packed_size,
        etcdserverpb__watch_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    /* Create call and setup ops */
    gpr_timespec deadline = gpr_inf_future(GPR_CLOCK_REALTIME);
    wc->call = grpc_channel_create_call(
        client->channel, NULL, GRPC_PROPAGATE_DEFAULTS,
        client->cq, METHOD_WATCH, NULL, deadline, NULL);

    if (!wc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        wc->active = 0;
        client->in_callback = 1;
        CALL_STATUS_ERROR_CALLBACK(wc->callback, GRPC_STATUS_INTERNAL, "Watch reconnect failed", "watch");
        client->in_callback = 0;
        if (!client->active) {
            finish_client_destroy(aTHX_ client);
            return;
        }
        cleanup_watch(aTHX_ wc);
        return;
    }

    grpc_op ops[4] = {0};
    grpc_metadata auth_md;
    STREAMING_CALL_SETUP_OPS(client, ops, auth_md, send_buffer, wc);

    init_call_base(&wc->base, CALL_TYPE_WATCH);
    grpc_call_error err = grpc_call_start_batch(wc->call, ops, 4, &wc->base, NULL);
    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        STREAMING_CALL_BATCH_ERROR(wc);
        client->in_callback = 1;
        CALL_STATUS_ERROR_CALLBACK(wc->callback, GRPC_STATUS_INTERNAL, "Watch reconnect batch failed", "watch");
        client->in_callback = 0;
        if (!client->active) {
            finish_client_destroy(aTHX_ client);
            return;
        }
        cleanup_watch(aTHX_ wc);
    }
}

/* Try to reconnect a watch after stream ended (with backoff delay) */
int try_reconnect_watch(pTHX_ watch_call_t *wc) {
    ev_etcd_t *client = wc->client;

    if (!wc->auto_reconnect || !client->active) {
        return 0;
    }

    if (wc->reconnect_attempt >= client->max_retries) {
        return 0;
    }

    wc->reconnect_attempt++;

    ev_tstamp delay = RECONNECT_BACKOFF_SECONDS(wc->reconnect_attempt);
    ev_timer_init(&wc->reconnect_timer, watch_reconnect_cb, delay, 0.0);
    ev_timer_start(EV_DEFAULT, &wc->reconnect_timer);

    return 1;
}
