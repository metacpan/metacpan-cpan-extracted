/*
 * etcd_lease.c - Lease operation handlers for EV::Etcd
 */
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "etcd_common.h"
#include "etcd_lease.h"

/* Process LeaseGrantResponse */
void process_lease_grant_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "lease_grant");

    Etcdserverpb__LeaseGrantResponse *resp;
    UNPACK_RESPONSE(pc, resp, etcdserverpb__lease_grant_response__unpack);

    if (resp->error && strlen(resp->error) > 0) {
        CALL_STATUS_ERROR_CALLBACK(pc->callback, GRPC_STATUS_INTERNAL, resp->error, "lease_grant");
        etcdserverpb__lease_grant_response__free_unpacked(resp, NULL);
        return;
    }

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);
    hv_store(result, "id", 2, newSViv(resp->id), 0);
    hv_store(result, "ttl", 3, newSViv(resp->ttl), 0);
    etcdserverpb__lease_grant_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}

/* Process LeaseRevokeResponse */
void process_lease_revoke_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "lease_revoke");

    Etcdserverpb__LeaseRevokeResponse *resp;
    UNPACK_RESPONSE(pc, resp, etcdserverpb__lease_revoke_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);
    etcdserverpb__lease_revoke_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}

/* Process LeaseTimeToLiveResponse */
void process_lease_time_to_live_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "lease_ttl");

    Etcdserverpb__LeaseTimeToLiveResponse *resp;
    UNPACK_RESPONSE(pc, resp, etcdserverpb__lease_time_to_live_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);
    hv_store(result, "id", 2, newSViv(resp->id), 0);
    hv_store(result, "ttl", 3, newSViv(resp->ttl), 0);
    hv_store(result, "granted_ttl", 11, newSViv(resp->grantedttl), 0);

    if (resp->n_keys > 0) {
        AV *keys_av = newAV();
        av_extend(keys_av, resp->n_keys - 1);
        for (size_t i = 0; i < resp->n_keys; i++) {
            /* Handle NULL data pointer for empty bytes field */
            av_push(keys_av, resp->keys[i].data
                ? newSVpvn((char *)resp->keys[i].data, resp->keys[i].len)
                : newSVpvn("", 0));
        }
        hv_store(result, "keys", 4, newRV_noinc((SV *)keys_av), 0);
    }

    etcdserverpb__lease_time_to_live_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}

/* Process LeaseLeasesResponse */
void process_lease_leases_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "lease_leases");

    Etcdserverpb__LeaseLeasesResponse *resp;
    UNPACK_RESPONSE(pc, resp, etcdserverpb__lease_leases_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);

    AV *leases_av = newAV();
    if (resp->n_leases > 0) {
        av_extend(leases_av, resp->n_leases - 1);
    }
    for (size_t i = 0; i < resp->n_leases; i++) {
        HV *lease_hv = newHV();
        hv_store(lease_hv, "id", 2, newSViv(resp->leases[i]->id), 0);
        av_push(leases_av, newRV_noinc((SV *)lease_hv));
    }
    hv_store(result, "leases", 6, newRV_noinc((SV *)leases_av), 0);

    etcdserverpb__lease_leases_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}

/* Re-arm keepalive to receive next message */
void keepalive_rearm_recv(pTHX_ keepalive_call_t *kc) {
    if (!kc->active) return;

    if (kc->recv_buffer) {
        grpc_byte_buffer_destroy(kc->recv_buffer);
        kc->recv_buffer = NULL;
    }

    kc->base.type = CALL_TYPE_LEASE_KEEPALIVE_RECV;

    grpc_op op;
    memset(&op, 0, sizeof(op));
    op.op = GRPC_OP_RECV_MESSAGE;
    op.data.recv_message.recv_message = &kc->recv_buffer;

    grpc_call_error err = grpc_call_start_batch(kc->call, &op, 1, &kc->base, NULL);
    if (err != GRPC_CALL_OK) {
        kc->active = 0;
        CALL_SIMPLE_ERROR_CALLBACK(kc->callback, "Keepalive rearm failed");
        cleanup_keepalive(aTHX_ kc);
    }
}

/* Cleanup keepalive and remove from client list */
void cleanup_keepalive(pTHX_ keepalive_call_t *kc) {
    ev_etcd_t *client = kc->client;

    keepalive_call_t **kp = &client->keepalives;
    while (*kp) {
        if (*kp == kc) {
            *kp = kc->next;
            break;
        }
        kp = &(*kp)->next;
    }

    if (ev_is_active(&kc->reconnect_timer))
        ev_timer_stop(EV_DEFAULT, &kc->reconnect_timer);
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
}

/* Process LeaseKeepAliveResponse */
void process_keepalive_response(pTHX_ keepalive_call_t *kc) {
    if (!kc->recv_buffer) {
        kc->active = 0;
        CALL_SIMPLE_ERROR_CALLBACK(kc->callback, "No keepalive response received");
        return;
    }

    grpc_byte_buffer_reader reader;
    if (!grpc_byte_buffer_reader_init(&reader, kc->recv_buffer)) {
        kc->active = 0;
        CALL_SIMPLE_ERROR_CALLBACK(kc->callback, "Failed to read keepalive response buffer");
        return;
    }

    grpc_slice slice = grpc_byte_buffer_reader_readall(&reader);
    grpc_byte_buffer_reader_destroy(&reader);

    Etcdserverpb__LeaseKeepAliveResponse *resp = etcdserverpb__lease_keep_alive_response__unpack(
        NULL, GRPC_SLICE_LENGTH(slice), GRPC_SLICE_START_PTR(slice));
    grpc_slice_unref(slice);

    if (!resp) {
        kc->active = 0;
        CALL_SIMPLE_ERROR_CALLBACK(kc->callback, "Failed to parse keepalive response");
        return;
    }

    kc->reconnect_attempt = 0;

    if (resp->ttl == 0) {
        kc->active = 0;
        CALL_STATUS_ERROR_CALLBACK(kc->callback, GRPC_STATUS_NOT_FOUND, "Lease expired", "keepalive");
        etcdserverpb__lease_keep_alive_response__free_unpacked(resp, NULL);
        return;
    }

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);
    hv_store(result, "id", 2, newSViv(resp->id), 0);
    hv_store(result, "ttl", 3, newSViv(resp->ttl), 0);
    etcdserverpb__lease_keep_alive_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(kc->callback, result);
}

/* Perform keepalive reconnection (called from timer callback) */
static void keepalive_reconnect_cb(struct ev_loop *loop, ev_timer *w, int revents) {
    dTHX;
    (void)loop;
    (void)revents;

    keepalive_call_t *kc = (keepalive_call_t *)((char *)w - offsetof(keepalive_call_t, reconnect_timer));
    ev_etcd_t *client = kc->client;

    if (!client->active) {
        cleanup_keepalive(aTHX_ kc);
        return;
    }

    /* Cleanup and reinitialize streaming state */
    STREAMING_CALL_CLEANUP(kc);
    STREAMING_CALL_REINIT(kc);

    /* Build keepalive request */
    Etcdserverpb__LeaseKeepAliveRequest keep_req = ETCDSERVERPB__LEASE_KEEP_ALIVE_REQUEST__INIT;
    keep_req.id = kc->lease_id;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        etcdserverpb__lease_keep_alive_request__get_packed_size,
        etcdserverpb__lease_keep_alive_request__pack, &keep_req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    /* Create call and setup ops */
    gpr_timespec deadline = gpr_inf_future(GPR_CLOCK_REALTIME);
    kc->call = grpc_channel_create_call(
        client->channel, NULL, GRPC_PROPAGATE_DEFAULTS,
        client->cq, METHOD_LEASE_KEEPALIVE, NULL, deadline, NULL);

    if (!kc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        kc->active = 0;
        client->in_callback = 1;
        CALL_SIMPLE_ERROR_CALLBACK(kc->callback, "Keepalive reconnect failed");
        client->in_callback = 0;
        if (!client->active) {
            finish_client_destroy(aTHX_ client);
            return;
        }
        cleanup_keepalive(aTHX_ kc);
        return;
    }

    grpc_op ops[4] = {0};
    grpc_metadata auth_md;
    STREAMING_CALL_SETUP_OPS(client, ops, auth_md, send_buffer, kc);

    init_call_base(&kc->base, CALL_TYPE_LEASE_KEEPALIVE);
    grpc_call_error err = grpc_call_start_batch(kc->call, ops, 4, &kc->base, NULL);
    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        STREAMING_CALL_BATCH_ERROR(kc);
        client->in_callback = 1;
        CALL_SIMPLE_ERROR_CALLBACK(kc->callback, "Keepalive reconnect batch failed");
        client->in_callback = 0;
        if (!client->active) {
            finish_client_destroy(aTHX_ client);
            return;
        }
        cleanup_keepalive(aTHX_ kc);
    }
}

int try_reconnect_keepalive(pTHX_ keepalive_call_t *kc) {
    ev_etcd_t *client = kc->client;

    if (!kc->auto_reconnect || !client->active || kc->lease_id <= 0) {
        return 0;
    }

    if (kc->reconnect_attempt >= client->max_retries) {
        return 0;
    }

    kc->reconnect_attempt++;

    ev_tstamp delay = RECONNECT_BACKOFF_SECONDS(kc->reconnect_attempt);
    ev_timer_init(&kc->reconnect_timer, keepalive_reconnect_cb, delay, 0.0);
    ev_timer_start(EV_DEFAULT, &kc->reconnect_timer);

    return 1;
}
