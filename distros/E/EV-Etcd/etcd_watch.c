#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "etcd_common.h"
#include "etcd_watch.h"

/* GEVAPI is static per translation unit: unbound, ev_* calls dereference NULL */
void watch_init_ev_api(pTHX) {
    I_EV_API("EV::Etcd");
}

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

static void watch_call_free(pTHX_ watch_call_t *wc) {
    if (wc->params.key) Safefree(wc->params.key);
    if (wc->params.range_end) Safefree(wc->params.range_end);
    Safefree(wc);
}

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
    ev_timer_stop(EV_DEFAULT, &wc->progress_timer);
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
    etcd_call_release(&wc->base);
    SvREFCNT_dec(wc->callback);
    wc->callback = NULL;
    wc->active = 0;
    wc->client_owns = 0;

    if (!wc->perl_owns) watch_call_free(aTHX_ wc);
}

void watch_call_perl_release(pTHX_ watch_call_t *wc) {
    wc->perl_owns = 0;
    if (!wc->client_owns) watch_call_free(aTHX_ wc);
}

static void watch_progress_cb(struct ev_loop *loop, ev_timer *w, int revents) {
    (void)revents;
    watch_call_t *wc = (watch_call_t *)((char *)w - offsetof(watch_call_t, progress_timer));
    if (!wc->active) return;

    Etcdserverpb__WatchProgressRequest progress = ETCDSERVERPB__WATCH_PROGRESS_REQUEST__INIT;
    Etcdserverpb__WatchRequest req = ETCDSERVERPB__WATCH_REQUEST__INIT;
    req.request_union_case = ETCDSERVERPB__WATCH_REQUEST__REQUEST_UNION_PROGRESS_REQUEST;
    req.progress_request = &progress;

    grpc_slice slice;
    SERIALIZE_PROTOBUF_TO_SLICE(slice,
        etcdserverpb__watch_request__get_packed_size,
        etcdserverpb__watch_request__pack, &req);
    grpc_byte_buffer *buffer = grpc_raw_byte_buffer_create(&slice, 1);
    grpc_slice_unref(slice);

    grpc_op op = {0};
    op.op = GRPC_OP_SEND_MESSAGE;
    op.data.send_message.send_message = buffer;
    (void)grpc_call_start_batch(wc->call, &op, 1, &cancel_sentinel, NULL);
    grpc_byte_buffer_destroy(buffer);

    /* etcd 3.5.8-3.5.12 ignores repeats until the watch sends something; after
     * about 13 s connected, a quiet watch counts as recovered */
    if (w->repeat < 5.0) {
        w->repeat *= 2;
        ev_timer_again(loop, w);
    } else {
        ev_timer_stop(loop, w);
        wc->reconnect_attempt = 0;
    }
}

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

    wc->established = 1;

    if (resp->created) {
        wc->watch_id = resp->watch_id;
        /* Only an initial watch at HEAD has no history to replay */
        if (!wc->last_revision && wc->params.start_revision <= 0 && resp->header)
            wc->last_revision = resp->header->revision;
    }

    if (resp->canceled) {
        wc->active = 0;
        const char *reason = (resp->cancel_reason && strlen(resp->cancel_reason) > 0)
            ? resp->cancel_reason : "Watch cancelled";
        SV *err = create_error_hv(aTHX_ GRPC_STATUS_CANCELLED,
            reason, strlen(reason), "watch");
        hv_store((HV *)SvRV(err), "compact_revision", 16,
            newSVi64(resp->compact_revision), 0);
        CALL_PREBUILT_ERROR_CALLBACK(wc->callback, err);
        etcdserverpb__watch_response__free_unpacked(resp, NULL);
        return;
    }

    if (resp->created && wc->reconnect_attempt && resp->header) {
        if (resp->header->revision <= wc->last_revision) {
            wc->reconnect_attempt = 0;
        } else {
            /* Created is not caught up: etcd 3.5.8+ answers a progress request once it is */
            ev_timer_init(&wc->progress_timer, watch_progress_cb, 0.1, 0.1);
            ev_timer_start(EV_DEFAULT, &wc->progress_timer);
        }
    }
    if (!resp->created) {
        wc->reconnect_attempt = 0;
        ev_timer_stop(EV_DEFAULT, &wc->progress_timer);
    }

    int64_t revision = wc->last_revision;
    if (!resp->created && !resp->n_events && resp->header)
        revision = resp->header->revision;

    if (!resp->created && !resp->n_events && resp->watch_id == -1) {
        /* Our own progress request's reply. Before 3.4.25/3.5.8 it can overtake
         * the replay, so it must never move the resume point */
        etcdserverpb__watch_response__free_unpacked(resp, NULL);
        return;
    }

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);

    hv_store(result, "watch_id", 8, newSVi64(resp->watch_id), 0);
    hv_store(result, "created", 7, newSViv(resp->created ? 1 : 0), 0);

    AV *events = newAV();
    if (resp->n_events > 0) {
        av_extend(events, resp->n_events - 1);
    }
    for (size_t i = 0; i < resp->n_events; i++) {
        if (resp->events[i]->kv && resp->events[i]->kv->mod_revision > revision)
            revision = resp->events[i]->kv->mod_revision;
        av_push(events, event_to_hashref(aTHX_ resp->events[i]));
    }
    hv_store(result, "events", 6, newRV_noinc((SV *)events), 0);

    if (revision > wc->last_revision) {
        wc->last_revision = revision;
    }

    etcdserverpb__watch_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(wc->callback, result);
}

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

    STREAMING_CALL_CLEANUP(wc);
    STREAMING_CALL_REINIT(wc);

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

    gpr_timespec deadline = gpr_inf_future(GPR_CLOCK_REALTIME);
    etcd_call_acquire(client, &wc->base);
    /* Within gRPC's own backoff the attempt would fail on the last connect error */
    grpc_channel_reset_connect_backoff(client->channel);
    wc->call = grpc_channel_create_call(
        client->channel, NULL, GRPC_PROPAGATE_DEFAULTS,
        client->cq, METHOD_WATCH, NULL, deadline, NULL);

    if (!wc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        wc->active = 0;
        CALLBACK_WINDOW_BEGIN(client);
        CALL_STATUS_ERROR_CALLBACK(wc->callback, GRPC_STATUS_INTERNAL, "Watch reconnect failed", "watch");
        if (CALLBACK_WINDOW_END(client))
            return;
        cleanup_watch(aTHX_ wc);
        return;
    }

    grpc_op ops[4] = {0};
    STREAMING_CALL_SETUP_OPS(client, ops, send_buffer, wc);

    init_call_base(&wc->base, CALL_TYPE_WATCH);
    grpc_call_error err = grpc_call_start_batch(wc->call, ops, 4, &wc->base, NULL);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        STREAMING_CALL_BATCH_ERROR(wc);
        CALLBACK_WINDOW_BEGIN(client);
        CALL_STATUS_ERROR_CALLBACK(wc->callback, GRPC_STATUS_INTERNAL, "Watch reconnect batch failed", "watch");
        if (CALLBACK_WINDOW_END(client))
            return;
        cleanup_watch(aTHX_ wc);
    }
}

int try_reconnect_watch(pTHX_ watch_call_t *wc) {
    ev_etcd_t *client = wc->client;

    if (!client->active) {
        return 0;
    }

    etcd_stream_failed(client, wc->base.channel_gen, wc->established, wc->status, wc->status_details);
    wc->established = 0;
    if (wc->attempt_epoch != client->no_leader_epoch) {
        wc->attempt_epoch = client->no_leader_epoch;
        wc->reconnect_attempt = 0;
    }

    if (!wc->auto_reconnect || wc->reconnect_attempt >= client->max_retries) {
        return 0;
    }

    int no_leader = etcd_is_no_leader(wc->status, wc->status_details);
    if (!no_leader) wc->reconnect_attempt++;
    ev_tstamp delay = no_leader ? NO_LEADER_RETRY_SECONDS
        : RECONNECT_BACKOFF_SECONDS(wc->reconnect_attempt);
    ev_timer_init(&wc->reconnect_timer, watch_reconnect_cb, delay, 0.0);
    ev_timer_start(EV_DEFAULT, &wc->reconnect_timer);

    return 1;
}
