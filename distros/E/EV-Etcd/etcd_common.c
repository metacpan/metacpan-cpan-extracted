#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <EV/EVAPI.h>

#include "etcd_common.h"

call_base_t cancel_sentinel = { CALL_TYPE_NONE };

static const char * const grpc_status_names[] = {
    [GRPC_STATUS_OK] = "OK",
    [GRPC_STATUS_CANCELLED] = "CANCELLED",
    [GRPC_STATUS_UNKNOWN] = "UNKNOWN",
    [GRPC_STATUS_INVALID_ARGUMENT] = "INVALID_ARGUMENT",
    [GRPC_STATUS_DEADLINE_EXCEEDED] = "DEADLINE_EXCEEDED",
    [GRPC_STATUS_NOT_FOUND] = "NOT_FOUND",
    [GRPC_STATUS_ALREADY_EXISTS] = "ALREADY_EXISTS",
    [GRPC_STATUS_PERMISSION_DENIED] = "PERMISSION_DENIED",
    [GRPC_STATUS_RESOURCE_EXHAUSTED] = "RESOURCE_EXHAUSTED",
    [GRPC_STATUS_FAILED_PRECONDITION] = "FAILED_PRECONDITION",
    [GRPC_STATUS_ABORTED] = "ABORTED",
    [GRPC_STATUS_OUT_OF_RANGE] = "OUT_OF_RANGE",
    [GRPC_STATUS_UNIMPLEMENTED] = "UNIMPLEMENTED",
    [GRPC_STATUS_INTERNAL] = "INTERNAL",
    [GRPC_STATUS_UNAVAILABLE] = "UNAVAILABLE",
    [GRPC_STATUS_DATA_LOSS] = "DATA_LOSS",
    [GRPC_STATUS_UNAUTHENTICATED] = "UNAUTHENTICATED",
};
#define GRPC_STATUS_COUNT (sizeof(grpc_status_names) / sizeof(grpc_status_names[0]))

const char* grpc_status_name(grpc_status_code code) {
    if (code >= 0 && (size_t)code < GRPC_STATUS_COUNT && grpc_status_names[code]) {
        return grpc_status_names[code];
    }
    return "UNKNOWN_CODE";
}

int is_retryable_status(grpc_status_code code) {
    switch (code) {
        case GRPC_STATUS_UNAVAILABLE:
        case GRPC_STATUS_RESOURCE_EXHAUSTED:
        case GRPC_STATUS_ABORTED:
        case GRPC_STATUS_DEADLINE_EXCEEDED:
            return 1;
        default:
            return 0;
    }
}

/* Statuses a reconnect cannot fix; streams retry on any other end */
int is_permanent_status(grpc_status_code code) {
    switch (code) {
        case GRPC_STATUS_INVALID_ARGUMENT:
        case GRPC_STATUS_NOT_FOUND:
        case GRPC_STATUS_ALREADY_EXISTS:
        case GRPC_STATUS_PERMISSION_DENIED:
        case GRPC_STATUS_FAILED_PRECONDITION:
        case GRPC_STATUS_OUT_OF_RANGE:
        case GRPC_STATUS_UNIMPLEMENTED:
        case GRPC_STATUS_UNAUTHENTICATED:
            return 1;
        default:
            return 0;
    }
}

int etcd_is_no_leader(grpc_status_code status, grpc_slice status_details) {
    return status == GRPC_STATUS_UNAVAILABLE
        && grpc_slice_eq(status_details, grpc_slice_from_static_string("etcdserver: no leader"));
}

static void set_int_arg(grpc_arg *arg, const char *key, int value) {
    arg->type = GRPC_ARG_INTEGER;
    arg->key = (char *)key;
    arg->value.integer = value;
}

channel_ref_t *etcd_create_channel(ev_etcd_t *client, const char *target) {
    grpc_arg arg[9];
    grpc_channel_args args = { 0, arg };
    /* gRPC caps messages at 4 MiB; a watch replay or a range can be larger */
    set_int_arg(&arg[args.num_args++], "grpc.max_receive_message_length", -1);
    /* gRPC's default is 120 s, shared by every channel to the target */
    set_int_arg(&arg[args.num_args++], "grpc.max_reconnect_backoff_ms", 5000);
    if (client->tls_server_name) {
        arg[args.num_args].type = GRPC_ARG_STRING;
        arg[args.num_args].key = (char *)"grpc.ssl_target_name_override";
        arg[args.num_args++].value.string = client->tls_server_name;
    }
    if (client->keepalive_ms) {
        /* etcd GOAWAYs pings without calls; gRPC's own throttles would hide a dead
         * idle watch, and newer gRPC times pings out by ping_timeout_ms */
        set_int_arg(&arg[args.num_args++], "grpc.keepalive_time_ms", client->keepalive_ms);
        set_int_arg(&arg[args.num_args++], "grpc.keepalive_timeout_ms", client->keepalive_timeout_ms);
        set_int_arg(&arg[args.num_args++], "grpc.keepalive_permit_without_calls", 0);
        set_int_arg(&arg[args.num_args++], "grpc.http2.max_pings_without_data", 0);
        set_int_arg(&arg[args.num_args++], "grpc.http2.min_time_between_pings_ms", client->keepalive_ms);
        set_int_arg(&arg[args.num_args++], "grpc.http2.ping_timeout_ms", client->keepalive_timeout_ms);
    }
    /* grpc_channel_create arrived in gRPC 1.45 */
    grpc_channel *channel;
#ifdef HAVE_GRPC_NEW_CHANNEL_API
    grpc_channel_credentials *creds = client->creds
        ? client->creds : grpc_insecure_credentials_create();
    WITH_SIGNALS_BLOCKED(channel = grpc_channel_create(target, creds, &args));
    if (!client->creds) grpc_channel_credentials_release(creds);
#else
    WITH_SIGNALS_BLOCKED(channel = client->creds
        ? grpc_secure_channel_create(client->creds, target, &args, NULL)
        : grpc_insecure_channel_create(target, &args, NULL));
#endif
    if (!channel) return NULL;

    channel_ref_t *ref;
    Newx(ref, 1, channel_ref_t);
    ref->channel = channel;
    ref->refs = 1;
    return ref;
}

void etcd_channel_release(channel_ref_t *ref, int destroy) {
    if (ref && !--ref->refs) {
        /* A forked child discards only our wrapper, without touching gRPC. */
        if (destroy) grpc_channel_destroy(ref->channel);
        Safefree(ref);
    }
}

static void release_send_metadata(call_base_t *base) {
    if (base->owns_auth_value) {
        grpc_slice_unref(base->send_md[0].value);
        base->owns_auth_value = 0;
    }
}

void etcd_call_release(call_base_t *base) {
    etcd_channel_release(base->channel_ref, 1);
    base->channel_ref = NULL;
    release_send_metadata(base);
}

static void cancel_blocking_calls(ev_etcd_t *client, unsigned channel_gen, const char *message) {
    for (pending_call_t *pc = client->pending_calls; pc; pc = pc->next) {
        if (pc->call && pc->base.channel_gen == channel_gen
            && (pc->base.type == CALL_TYPE_LOCK || pc->base.type == CALL_TYPE_ELECTION_CAMPAIGN))
            grpc_call_cancel_with_status(pc->call, GRPC_STATUS_UNAVAILABLE, message, NULL);
    }
}

static void check_leader_failure(ev_etcd_t *client, unsigned channel_gen,
                                grpc_status_code status, grpc_slice status_details) {
    if (etcd_is_no_leader(status, status_details)) {
        /* Retired channels too: another failure may have moved the client already */
        cancel_blocking_calls(client, channel_gen, "etcdserver: no leader");
    }
}

void etcd_rotate_endpoint(ev_etcd_t *client) {
    int next = client->current_endpoint;
    if (client->endpoint_count > 1)
        next = (next + 1) % client->endpoint_count;

    channel_ref_t *ref = etcd_create_channel(client, client->endpoints[next]);
    if (!ref) return;

    channel_ref_t *old = client->channel_ref;
    unsigned old_gen = client->channel_gen;
    int was_ready = grpc_channel_check_connectivity_state(old->channel, 0) == GRPC_CHANNEL_READY;
    client->channel_ref = ref;
    client->channel = ref->channel;
    client->current_endpoint = next;
    client->channel_gen++;

    /* Calls without a deadline must not stay queued on a dead connection */
    if (!was_ready) {
        cancel_blocking_calls(client, old_gen, "Endpoint changed");
        for (watch_call_t *wc = client->watches; wc; wc = wc->next) {
            if (wc->active && wc->auto_reconnect && wc->call && wc->base.channel_gen == old_gen)
                grpc_call_cancel_with_status(wc->call, GRPC_STATUS_UNAVAILABLE, "Endpoint changed", NULL);
        }
        for (keepalive_call_t *kc = client->keepalives; kc; kc = kc->next) {
            if (kc->active && kc->auto_reconnect && kc->call && kc->base.channel_gen == old_gen)
                grpc_call_cancel_with_status(kc->call, GRPC_STATUS_UNAVAILABLE, "Endpoint changed", NULL);
        }
        for (observe_call_t *oc = client->observes; oc; oc = oc->next) {
            if (oc->active && oc->auto_reconnect && oc->call && oc->base.channel_gen == old_gen)
                grpc_call_cancel_with_status(oc->call, GRPC_STATUS_UNAVAILABLE, "Endpoint changed", NULL);
        }
    }
    etcd_channel_release(old, 1);
}

/* From a working member during a leader change: any other would answer the same */
static int cluster_wide_unavailable(grpc_status_code status, grpc_slice details) {
    static const char *const messages[] = {
        "etcdserver: leader changed",
        "etcdserver: request timed out, possibly due to previous leader failure",
        NULL
    };
    if (status != GRPC_STATUS_UNAVAILABLE)
        return 0;
    for (int i = 0; messages[i]; i++) {
        if (grpc_slice_eq(details, grpc_slice_from_static_string(messages[i])))
            return 1;
    }
    return 0;
}

static int failed_on_current(ev_etcd_t *client, unsigned channel_gen) {
    return client->endpoint_count > 1 && channel_gen == client->channel_gen;
}

static int connected(ev_etcd_t *client) {
    return grpc_channel_check_connectivity_state(client->channel, 0) == GRPC_CHANNEL_READY;
}

/* etcd's own request timeout on a member without a leader, not the client's deadline */
static int member_timed_out(grpc_status_code status, grpc_slice details) {
    if ((status == GRPC_STATUS_DEADLINE_EXCEEDED || status == GRPC_STATUS_UNKNOWN)
        && grpc_slice_eq(details, grpc_slice_from_static_string("context deadline exceeded")))
        return 1;
    return status == GRPC_STATUS_UNKNOWN
        && (grpc_slice_eq(details, grpc_slice_from_static_string("etcdserver: request timed out"))
            || grpc_slice_eq(details, grpc_slice_from_static_string(
                "etcdserver: request timed out, possibly due to connection lost")));
}

/* Only failures on the current channel rotate, so a burst moves the client once */
void etcd_endpoint_failed(ev_etcd_t *client, const call_base_t *base,
                          grpc_status_code status, grpc_slice status_details) {
    /* A lock or campaign ended by the sweep carries the same message */
    if (base->type != CALL_TYPE_LOCK && base->type != CALL_TYPE_ELECTION_CAMPAIGN)
        check_leader_failure(client, base->channel_gen, status, status_details);
    if (etcd_is_no_leader(status, status_details))
        client->no_leader_epoch++;
    if (!failed_on_current(client, base->channel_gen))
        return;
    if ((status == GRPC_STATUS_UNAVAILABLE && !cluster_wide_unavailable(status, status_details))
        || (status == GRPC_STATUS_DEADLINE_EXCEEDED && !connected(client))
        || member_timed_out(status, status_details))
        etcd_rotate_endpoint(client);
}

/* etcd refuses new streams during any election, but ends an established one
 * only after several election timeouts without a leader */
void etcd_stream_failed(ev_etcd_t *client, unsigned channel_gen, int established,
                        grpc_status_code status, grpc_slice status_details) {
    if (established)
        check_leader_failure(client, channel_gen, status, status_details);
    if (etcd_is_no_leader(status, status_details))
        client->no_leader_epoch++;
    if (failed_on_current(client, channel_gen)
        && ((status == GRPC_STATUS_UNAVAILABLE && !cluster_wide_unavailable(status, status_details))
            || !connected(client)))
        etcd_rotate_endpoint(client);
}

SV* create_error_hv(pTHX_ grpc_status_code code, const char *message, size_t message_len, const char *source) {
    HV *err = newHV();
    hv_store(err, "code", 4, newSViv(code), 0);
    hv_store(err, "status", 6, newSVpv(grpc_status_name(code), 0), 0);
    if (message && message_len > 0) {
        hv_store(err, "message", 7, newSVpvn(message, message_len), 0);
    } else {
        hv_store(err, "message", 7, newSVpv("", 0), 0);
    }
    hv_store(err, "source", 6, newSVpv(source, 0), 0);
    /* The one RESOURCE_EXHAUSTED that passes by itself */
    int retryable = is_retryable_status(code)
        && (code != GRPC_STATUS_RESOURCE_EXHAUSTED
            || (message_len == sizeof("etcdserver: too many requests") - 1
                && memEQ(message, "etcdserver: too many requests", message_len)));
    hv_store(err, "retryable", 9, newSViv(retryable), 0);
    return newRV_noinc((SV *)err);
}

SV* create_pending_error_hv(pTHX_ pending_call_t *pc, grpc_status_code code, const char *source) {
    SV *err = create_error_hv(aTHX_ code,
        (const char *)GRPC_SLICE_START_PTR(pc->status_details),
        GRPC_SLICE_LENGTH(pc->status_details), source);
    /* Late server cleanup of the lease-derived key would delete a same-lease retry's */
    if (pc->base.type == CALL_TYPE_LOCK || pc->base.type == CALL_TYPE_ELECTION_CAMPAIGN)
        hv_store((HV *)SvRV(err), "retryable", 9, newSViv(0), 0);
    return err;
}

SV* kv_to_hashref(pTHX_ Mvccpb__KeyValue *kv) {
    HV *hv = newHV();

    /* protobuf-c leaves .data NULL for empty bytes, and newSVpvn(NULL, 0) is undef */
    hv_store(hv, "key", 3,
             kv->key.data ? newSVpvn((char *)kv->key.data, kv->key.len) : newSVpvn("", 0), 0);
    hv_store(hv, "value", 5,
             kv->value.data ? newSVpvn((char *)kv->value.data, kv->value.len) : newSVpvn("", 0), 0);
    hv_store(hv, "create_revision", 15, newSVi64(kv->create_revision), 0);
    hv_store(hv, "mod_revision", 12, newSVi64(kv->mod_revision), 0);
    hv_store(hv, "version", 7, newSVi64(kv->version), 0);
    hv_store(hv, "lease", 5, newSVi64(kv->lease), 0);

    return newRV_noinc((SV *)hv);
}

SV* event_to_hashref(pTHX_ Mvccpb__Event *event) {
    HV *hv = newHV();

    const char *type_str = (event->type == MVCCPB__EVENT__EVENT_TYPE__PUT) ? "PUT" : "DELETE";
    hv_store(hv, "type", 4, newSVpv(type_str, 0), 0);

    if (event->kv) {
        hv_store(hv, "kv", 2, kv_to_hashref(aTHX_ event->kv), 0);
    }

    if (event->prev_kv) {
        hv_store(hv, "prev_kv", 7, kv_to_hashref(aTHX_ event->prev_kv), 0);
    }

    return newRV_noinc((SV *)hv);
}

void add_header_to_hv(pTHX_ HV *result, Etcdserverpb__ResponseHeader *header) {
    if (!header) return;

    HV *hv = newHV();
    hv_store(hv, "cluster_id", 10, newSVu64(header->cluster_id), 0);
    hv_store(hv, "member_id", 9, newSVu64(header->member_id), 0);
    hv_store(hv, "revision", 8, newSVi64(header->revision), 0);
    hv_store(hv, "raft_term", 9, newSVu64(header->raft_term), 0);
    hv_store(result, "header", 6, newRV_noinc((SV *)hv), 0);
}

void setup_auth_metadata(ev_etcd_t *client, grpc_op *op, call_base_t *base) {
    release_send_metadata(base);
    memset(base->send_md, 0, sizeof base->send_md);
    op->data.send_initial_metadata.count = 0;
    op->data.send_initial_metadata.metadata = base->send_md;
    if (client->auth_token && client->auth_token_len > 0) {
        base->send_md[0].key = grpc_slice_from_static_string("authorization");
        base->send_md[0].value = grpc_slice_from_copied_buffer(client->auth_token, client->auth_token_len);
        base->owns_auth_value = 1;
        op->data.send_initial_metadata.count = 1;
    }
}

/* Auth, if any, and etcd's hasleader, which ends streams on a partitioned member */
void setup_stream_metadata(ev_etcd_t *client, grpc_op *op, call_base_t *base) {
    setup_auth_metadata(client, op, base);
    grpc_metadata *leader = &base->send_md[op->data.send_initial_metadata.count++];
    leader->key = grpc_slice_from_static_string("hasleader");
    leader->value = grpc_slice_from_static_string("true");
}

grpc_slice METHOD_KV_RANGE;
grpc_slice METHOD_KV_PUT;
grpc_slice METHOD_KV_DELETE;
grpc_slice METHOD_KV_COMPACT;
grpc_slice METHOD_KV_TXN;
grpc_slice METHOD_WATCH;
grpc_slice METHOD_LEASE_GRANT;
grpc_slice METHOD_LEASE_REVOKE;
grpc_slice METHOD_LEASE_KEEPALIVE;
grpc_slice METHOD_LEASE_TTL;
grpc_slice METHOD_LEASE_LEASES;
grpc_slice METHOD_MAINTENANCE_STATUS;
grpc_slice METHOD_AUTH_AUTHENTICATE;
grpc_slice METHOD_AUTH_USER_ADD;
grpc_slice METHOD_AUTH_USER_DELETE;
grpc_slice METHOD_AUTH_USER_CHANGE_PASSWORD;
grpc_slice METHOD_AUTH_USER_GET;
grpc_slice METHOD_AUTH_USER_LIST;
grpc_slice METHOD_AUTH_USER_GRANT_ROLE;
grpc_slice METHOD_AUTH_USER_REVOKE_ROLE;
grpc_slice METHOD_AUTH_ENABLE;
grpc_slice METHOD_AUTH_DISABLE;
grpc_slice METHOD_AUTH_ROLE_ADD;
grpc_slice METHOD_AUTH_ROLE_DELETE;
grpc_slice METHOD_AUTH_ROLE_GET;
grpc_slice METHOD_AUTH_ROLE_LIST;
grpc_slice METHOD_AUTH_ROLE_GRANT_PERM;
grpc_slice METHOD_AUTH_ROLE_REVOKE_PERM;
grpc_slice METHOD_LOCK;
grpc_slice METHOD_UNLOCK;
grpc_slice METHOD_ELECTION_CAMPAIGN;
grpc_slice METHOD_ELECTION_PROCLAIM;
grpc_slice METHOD_ELECTION_LEADER;
grpc_slice METHOD_ELECTION_RESIGN;
grpc_slice METHOD_ELECTION_OBSERVE;
grpc_slice METHOD_CLUSTER_MEMBER_ADD;
grpc_slice METHOD_CLUSTER_MEMBER_REMOVE;
grpc_slice METHOD_CLUSTER_MEMBER_UPDATE;
grpc_slice METHOD_CLUSTER_MEMBER_LIST;
grpc_slice METHOD_CLUSTER_MEMBER_PROMOTE;
grpc_slice METHOD_MAINTENANCE_ALARM;
grpc_slice METHOD_MAINTENANCE_DEFRAGMENT;
grpc_slice METHOD_MAINTENANCE_HASH_KV;
grpc_slice METHOD_MAINTENANCE_MOVE_LEADER;
grpc_slice METHOD_AUTH_STATUS;

void init_method_slices(void) {
    static int initialized = 0;
    if (initialized) return;
    initialized = 1;

    METHOD_KV_RANGE = grpc_slice_from_static_string("/etcdserverpb.KV/Range");
    METHOD_KV_PUT = grpc_slice_from_static_string("/etcdserverpb.KV/Put");
    METHOD_KV_DELETE = grpc_slice_from_static_string("/etcdserverpb.KV/DeleteRange");
    METHOD_KV_COMPACT = grpc_slice_from_static_string("/etcdserverpb.KV/Compact");
    METHOD_KV_TXN = grpc_slice_from_static_string("/etcdserverpb.KV/Txn");
    METHOD_WATCH = grpc_slice_from_static_string("/etcdserverpb.Watch/Watch");
    METHOD_LEASE_GRANT = grpc_slice_from_static_string("/etcdserverpb.Lease/LeaseGrant");
    METHOD_LEASE_REVOKE = grpc_slice_from_static_string("/etcdserverpb.Lease/LeaseRevoke");
    METHOD_LEASE_KEEPALIVE = grpc_slice_from_static_string("/etcdserverpb.Lease/LeaseKeepAlive");
    METHOD_LEASE_TTL = grpc_slice_from_static_string("/etcdserverpb.Lease/LeaseTimeToLive");
    METHOD_LEASE_LEASES = grpc_slice_from_static_string("/etcdserverpb.Lease/LeaseLeases");
    METHOD_MAINTENANCE_STATUS = grpc_slice_from_static_string("/etcdserverpb.Maintenance/Status");
    METHOD_AUTH_AUTHENTICATE = grpc_slice_from_static_string("/etcdserverpb.Auth/Authenticate");
    METHOD_AUTH_USER_ADD = grpc_slice_from_static_string("/etcdserverpb.Auth/UserAdd");
    METHOD_AUTH_USER_DELETE = grpc_slice_from_static_string("/etcdserverpb.Auth/UserDelete");
    METHOD_AUTH_USER_CHANGE_PASSWORD = grpc_slice_from_static_string("/etcdserverpb.Auth/UserChangePassword");
    METHOD_AUTH_USER_GET = grpc_slice_from_static_string("/etcdserverpb.Auth/UserGet");
    METHOD_AUTH_USER_LIST = grpc_slice_from_static_string("/etcdserverpb.Auth/UserList");
    METHOD_AUTH_USER_GRANT_ROLE = grpc_slice_from_static_string("/etcdserverpb.Auth/UserGrantRole");
    METHOD_AUTH_USER_REVOKE_ROLE = grpc_slice_from_static_string("/etcdserverpb.Auth/UserRevokeRole");
    METHOD_AUTH_ENABLE = grpc_slice_from_static_string("/etcdserverpb.Auth/AuthEnable");
    METHOD_AUTH_DISABLE = grpc_slice_from_static_string("/etcdserverpb.Auth/AuthDisable");
    METHOD_AUTH_ROLE_ADD = grpc_slice_from_static_string("/etcdserverpb.Auth/RoleAdd");
    METHOD_AUTH_ROLE_DELETE = grpc_slice_from_static_string("/etcdserverpb.Auth/RoleDelete");
    METHOD_AUTH_ROLE_GET = grpc_slice_from_static_string("/etcdserverpb.Auth/RoleGet");
    METHOD_AUTH_ROLE_LIST = grpc_slice_from_static_string("/etcdserverpb.Auth/RoleList");
    METHOD_AUTH_ROLE_GRANT_PERM = grpc_slice_from_static_string("/etcdserverpb.Auth/RoleGrantPermission");
    METHOD_AUTH_ROLE_REVOKE_PERM = grpc_slice_from_static_string("/etcdserverpb.Auth/RoleRevokePermission");
    METHOD_LOCK = grpc_slice_from_static_string("/v3lockpb.Lock/Lock");
    METHOD_UNLOCK = grpc_slice_from_static_string("/v3lockpb.Lock/Unlock");
    METHOD_ELECTION_CAMPAIGN = grpc_slice_from_static_string("/v3electionpb.Election/Campaign");
    METHOD_ELECTION_PROCLAIM = grpc_slice_from_static_string("/v3electionpb.Election/Proclaim");
    METHOD_ELECTION_LEADER = grpc_slice_from_static_string("/v3electionpb.Election/Leader");
    METHOD_ELECTION_RESIGN = grpc_slice_from_static_string("/v3electionpb.Election/Resign");
    METHOD_ELECTION_OBSERVE = grpc_slice_from_static_string("/v3electionpb.Election/Observe");
    METHOD_CLUSTER_MEMBER_ADD = grpc_slice_from_static_string("/etcdserverpb.Cluster/MemberAdd");
    METHOD_CLUSTER_MEMBER_REMOVE = grpc_slice_from_static_string("/etcdserverpb.Cluster/MemberRemove");
    METHOD_CLUSTER_MEMBER_UPDATE = grpc_slice_from_static_string("/etcdserverpb.Cluster/MemberUpdate");
    METHOD_CLUSTER_MEMBER_LIST = grpc_slice_from_static_string("/etcdserverpb.Cluster/MemberList");
    METHOD_CLUSTER_MEMBER_PROMOTE = grpc_slice_from_static_string("/etcdserverpb.Cluster/MemberPromote");
    METHOD_MAINTENANCE_ALARM = grpc_slice_from_static_string("/etcdserverpb.Maintenance/Alarm");
    METHOD_MAINTENANCE_DEFRAGMENT = grpc_slice_from_static_string("/etcdserverpb.Maintenance/Defragment");
    METHOD_MAINTENANCE_HASH_KV = grpc_slice_from_static_string("/etcdserverpb.Maintenance/HashKV");
    METHOD_MAINTENANCE_MOVE_LEADER = grpc_slice_from_static_string("/etcdserverpb.Maintenance/MoveLeader");
    METHOD_AUTH_STATUS = grpc_slice_from_static_string("/etcdserverpb.Auth/AuthStatus");
}
