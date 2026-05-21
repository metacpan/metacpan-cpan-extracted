/*
 * etcd_election.c - Election operation handlers for EV::Etcd
 */
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "etcd_common.h"
#include "etcd_election.h"

/* Helper to convert LeaderKey to hash */
HV *leader_key_to_hv(pTHX_ V3electionpb__LeaderKey *lk) {
    if (!lk) return NULL;

    HV *hv = newHV();
    /* Handle NULL data pointers for empty bytes fields */
    hv_store(hv, "name", 4,
             lk->name.data ? newSVpvn((const char *)lk->name.data, lk->name.len) : newSVpvn("", 0), 0);
    hv_store(hv, "key", 3,
             lk->key.data ? newSVpvn((const char *)lk->key.data, lk->key.len) : newSVpvn("", 0), 0);
    hv_store(hv, "rev", 3, newSVi64(lk->rev), 0);
    hv_store(hv, "lease", 5, newSVi64(lk->lease), 0);
    return hv;
}

/* Process CampaignResponse */
void process_campaign_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "campaign");

    V3electionpb__CampaignResponse *resp;
    UNPACK_RESPONSE(pc, resp, v3electionpb__campaign_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);

    if (resp->leader) {
        HV *leader_hv = leader_key_to_hv(aTHX_ resp->leader);
        hv_store(result, "leader", 6, newRV_noinc((SV *)leader_hv), 0);
    }

    v3electionpb__campaign_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}

/* Process ProclaimResponse */
void process_proclaim_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "proclaim");

    V3electionpb__ProclaimResponse *resp;
    UNPACK_RESPONSE(pc, resp, v3electionpb__proclaim_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);

    v3electionpb__proclaim_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}

/* Process LeaderResponse */
void process_leader_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "leader");

    V3electionpb__LeaderResponse *resp;
    UNPACK_RESPONSE(pc, resp, v3electionpb__leader_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);

    if (resp->kv) {
        hv_store(result, "kv", 2, kv_to_hashref(aTHX_ resp->kv), 0);
    }

    v3electionpb__leader_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}

/* Process ResignResponse */
void process_resign_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "resign");

    V3electionpb__ResignResponse *resp;
    UNPACK_RESPONSE(pc, resp, v3electionpb__resign_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);

    v3electionpb__resign_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}

/* === Election Observe (Streaming) Functions === */

/* Re-arm observe to receive next message */
void observe_rearm_recv(pTHX_ observe_call_t *oc) {
    if (!oc->active) return;

    if (oc->recv_buffer) {
        grpc_byte_buffer_destroy(oc->recv_buffer);
        oc->recv_buffer = NULL;
    }

    oc->base.type = CALL_TYPE_ELECTION_OBSERVE_RECV;

    grpc_op op;
    memset(&op, 0, sizeof(op));
    op.op = GRPC_OP_RECV_MESSAGE;
    op.data.recv_message.recv_message = &oc->recv_buffer;

    grpc_call_error err = grpc_call_start_batch(oc->call, &op, 1, &oc->base, NULL);
    if (err != GRPC_CALL_OK) {
        oc->active = 0;
        CALL_STATUS_ERROR_CALLBACK(oc->callback, GRPC_STATUS_INTERNAL, "Observe rearm failed", "observe");
        cleanup_observe(aTHX_ oc);
    }
}

static void observe_call_free(pTHX_ observe_call_t *oc) {
    if (oc->params.name) Safefree(oc->params.name);
    Safefree(oc);
}

/* See cleanup_watch — same dual-ownership pattern */
void cleanup_observe(pTHX_ observe_call_t *oc) {
    if (!oc->client_owns) return;

    ev_etcd_t *client = oc->client;
    observe_call_t **op = &client->observes;
    while (*op) {
        if (*op == oc) { *op = oc->next; break; }
        op = &(*op)->next;
    }

    if (ev_is_active(&oc->reconnect_timer))
        ev_timer_stop(EV_DEFAULT, &oc->reconnect_timer);
    grpc_metadata_array_destroy(&oc->initial_metadata);
    grpc_metadata_array_destroy(&oc->trailing_metadata);
    if (oc->recv_buffer) {
        grpc_byte_buffer_destroy(oc->recv_buffer);
        oc->recv_buffer = NULL;
    }
    grpc_slice_unref(oc->status_details);
    if (oc->call) {
        grpc_call_unref(oc->call);
        oc->call = NULL;
    }
    SvREFCNT_dec(oc->callback);
    oc->callback = NULL;
    oc->active = 0;
    oc->client_owns = 0;

    if (!oc->perl_owns) observe_call_free(aTHX_ oc);
}

void observe_call_perl_release(pTHX_ observe_call_t *oc) {
    oc->perl_owns = 0;
    if (!oc->client_owns) observe_call_free(aTHX_ oc);
}

/* Process LeaderResponse for observe stream */
void process_observe_response(pTHX_ observe_call_t *oc) {
    if (!oc->recv_buffer) {
        oc->active = 0;
        CALL_STATUS_ERROR_CALLBACK(oc->callback, GRPC_STATUS_INTERNAL, "No observe response received", "observe");
        return;
    }

    grpc_byte_buffer_reader reader;
    if (!grpc_byte_buffer_reader_init(&reader, oc->recv_buffer)) {
        oc->active = 0;
        CALL_STATUS_ERROR_CALLBACK(oc->callback, GRPC_STATUS_INTERNAL, "Failed to read observe response buffer", "observe");
        return;
    }

    grpc_slice slice = grpc_byte_buffer_reader_readall(&reader);
    grpc_byte_buffer_reader_destroy(&reader);

    V3electionpb__LeaderResponse *resp = v3electionpb__leader_response__unpack(
        NULL, GRPC_SLICE_LENGTH(slice), GRPC_SLICE_START_PTR(slice));
    grpc_slice_unref(slice);

    if (!resp) {
        oc->active = 0;
        CALL_STATUS_ERROR_CALLBACK(oc->callback, GRPC_STATUS_INTERNAL, "Failed to parse observe response", "observe");
        return;
    }

    /* Reset reconnect attempt on successful response */
    oc->reconnect_attempt = 0;

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);

    if (resp->kv) {
        hv_store(result, "kv", 2, kv_to_hashref(aTHX_ resp->kv), 0);
    }

    v3electionpb__leader_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(oc->callback, result);
}

/* Perform observe reconnection (called from timer callback) */
static void observe_reconnect_cb(struct ev_loop *loop, ev_timer *w, int revents) {
    dTHX;
    (void)loop;
    (void)revents;

    observe_call_t *oc = (observe_call_t *)((char *)w - offsetof(observe_call_t, reconnect_timer));
    ev_etcd_t *client = oc->client;

    if (!client->active) {
        cleanup_observe(aTHX_ oc);
        return;
    }

    /* Cleanup and reinitialize streaming state */
    STREAMING_CALL_CLEANUP(oc);
    STREAMING_CALL_REINIT(oc);

    /* Create LeaderRequest for observe */
    V3electionpb__LeaderRequest req = V3ELECTIONPB__LEADER_REQUEST__INIT;
    req.name.data = (uint8_t *)oc->params.name;
    req.name.len = oc->params.name_len;

    grpc_slice req_slice;
    SERIALIZE_PROTOBUF_TO_SLICE(req_slice,
        v3electionpb__leader_request__get_packed_size,
        v3electionpb__leader_request__pack, &req);
    grpc_byte_buffer *send_buffer = grpc_raw_byte_buffer_create(&req_slice, 1);
    grpc_slice_unref(req_slice);

    /* Create call and setup ops */
    gpr_timespec deadline = gpr_inf_future(GPR_CLOCK_REALTIME);
    oc->call = grpc_channel_create_call(
        client->channel, NULL, GRPC_PROPAGATE_DEFAULTS,
        client->cq, METHOD_ELECTION_OBSERVE, NULL, deadline, NULL);

    if (!oc->call) {
        grpc_byte_buffer_destroy(send_buffer);
        oc->active = 0;
        client->in_callback = 1;
        CALL_STATUS_ERROR_CALLBACK(oc->callback, GRPC_STATUS_INTERNAL, "Observe reconnect failed", "observe");
        client->in_callback = 0;
        if (!client->active) {
            finish_client_destroy(aTHX_ client);
            return;
        }
        cleanup_observe(aTHX_ oc);
        return;
    }

    grpc_op ops[4] = {0};
    grpc_metadata auth_md;
    STREAMING_CALL_SETUP_OPS(client, ops, auth_md, send_buffer, oc);

    init_call_base(&oc->base, CALL_TYPE_ELECTION_OBSERVE);
    grpc_call_error err = grpc_call_start_batch(oc->call, ops, 4, &oc->base, NULL);
    cleanup_auth_metadata(client, &auth_md);
    grpc_byte_buffer_destroy(send_buffer);

    if (err != GRPC_CALL_OK) {
        STREAMING_CALL_BATCH_ERROR(oc);
        client->in_callback = 1;
        CALL_STATUS_ERROR_CALLBACK(oc->callback, GRPC_STATUS_INTERNAL, "Observe reconnect batch failed", "observe");
        client->in_callback = 0;
        if (!client->active) {
            finish_client_destroy(aTHX_ client);
            return;
        }
        cleanup_observe(aTHX_ oc);
    }
}

int try_reconnect_observe(pTHX_ observe_call_t *oc) {
    ev_etcd_t *client = oc->client;

    if (!oc->auto_reconnect || !client->active) {
        return 0;
    }

    if (oc->reconnect_attempt >= client->max_retries) {
        return 0;
    }

    oc->reconnect_attempt++;

    ev_tstamp delay = RECONNECT_BACKOFF_SECONDS(oc->reconnect_attempt);
    ev_timer_init(&oc->reconnect_timer, observe_reconnect_cb, delay, 0.0);
    ev_timer_start(EV_DEFAULT, &oc->reconnect_timer);

    return 1;
}
