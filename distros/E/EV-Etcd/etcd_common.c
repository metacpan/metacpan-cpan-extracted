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

static void set_int_arg(grpc_arg *arg, const char *key, int value) {
    arg->type = GRPC_ARG_INTEGER;
    arg->key = (char *)key;
    arg->value.integer = value;
}

grpc_channel *etcd_create_channel(ev_etcd_t *client, const char *target) {
    grpc_arg arg[7];
    grpc_channel_args args = { 0, arg };
    if (client->tls_server_name) {
        arg[args.num_args].type = GRPC_ARG_STRING;
        arg[args.num_args].key = (char *)"grpc.ssl_target_name_override";
        arg[args.num_args++].value.string = client->tls_server_name;
    }
    if (client->keepalive_ms) {
        /* Pings only with calls open: etcd's default enforcement (5s min time,
         * none without streams) answers others with a too_many_pings GOAWAY.
         * max_pings_without_data/min_time lift gRPC's own throttles that would
         * hide a dead idle watch; newer gRPC times a ping out by
         * ping_timeout_ms (default 60s), not keepalive_timeout_ms. */
        set_int_arg(&arg[args.num_args++], "grpc.keepalive_time_ms", client->keepalive_ms);
        set_int_arg(&arg[args.num_args++], "grpc.keepalive_timeout_ms", client->keepalive_timeout_ms);
        set_int_arg(&arg[args.num_args++], "grpc.keepalive_permit_without_calls", 0);
        set_int_arg(&arg[args.num_args++], "grpc.http2.max_pings_without_data", 0);
        set_int_arg(&arg[args.num_args++], "grpc.http2.min_time_between_pings_ms", client->keepalive_ms);
        set_int_arg(&arg[args.num_args++], "grpc.http2.ping_timeout_ms", client->keepalive_timeout_ms);
    }
    /* grpc_channel_create/grpc_insecure_credentials_create arrived in gRPC ~1.42;
     * older releases have the per-security-mode channel constructors */
#ifdef HAVE_GRPC_NEW_CHANNEL_API
    if (client->creds)
        return grpc_channel_create(target, client->creds, &args);
    grpc_channel_credentials *creds = grpc_insecure_credentials_create();
    grpc_channel *channel = grpc_channel_create(target, creds, &args);
    grpc_channel_credentials_release(creds);
    return channel;
#else
    if (client->creds)
        return grpc_secure_channel_create(client->creds, target, &args, NULL);
    return grpc_insecure_channel_create(target, &args, NULL);
#endif
}

void etcd_rotate_endpoint(ev_etcd_t *client) {
    if (client->endpoint_count > 1)
        client->current_endpoint = (client->current_endpoint + 1) % client->endpoint_count;

    if (client->old_channel)
        grpc_channel_destroy(client->old_channel);
    client->old_channel = client->channel;
    client->channel = etcd_create_channel(client, client->endpoints[client->current_endpoint]);
    client->channel_gen++;
}

static int failed_on_current(ev_etcd_t *client, unsigned channel_gen) {
    return client->endpoint_count > 1 && channel_gen == client->channel_gen;
}

static int connected(ev_etcd_t *client) {
    return grpc_channel_check_connectivity_state(client->channel, 0) == GRPC_CHANNEL_READY;
}

/* Calls made on an older channel are ignored, so a burst of failures from one
 * dead endpoint moves the client once. DEADLINE_EXCEEDED on a connected channel
 * is a slow request, not a dead endpoint. */
void etcd_endpoint_failed(ev_etcd_t *client, unsigned channel_gen, grpc_status_code status) {
    if (!failed_on_current(client, channel_gen))
        return;
    if (status == GRPC_STATUS_UNAVAILABLE
        || (status == GRPC_STATUS_DEADLINE_EXCEEDED && !connected(client)))
        etcd_rotate_endpoint(client);
}

/* Streams end without a status; one that ends while the connection is still
 * up was ended by the server (auth, oversized message), not by the endpoint */
void etcd_stream_failed(ev_etcd_t *client, unsigned channel_gen) {
    if (failed_on_current(client, channel_gen) && !connected(client))
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
    hv_store(err, "retryable", 9, newSViv(is_retryable_status(code)), 0);
    return newRV_noinc((SV *)err);
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

void setup_auth_metadata(ev_etcd_t *client, grpc_op *op, grpc_metadata *auth_md) {
    if (client->auth_token && client->auth_token_len > 0) {
        auth_md->key = grpc_slice_from_static_string("authorization");
        auth_md->value = grpc_slice_from_copied_buffer(client->auth_token, client->auth_token_len);
        op->data.send_initial_metadata.count = 1;
        op->data.send_initial_metadata.metadata = auth_md;
    } else {
        op->data.send_initial_metadata.count = 0;
        op->data.send_initial_metadata.metadata = NULL;
    }
}

void cleanup_auth_metadata(ev_etcd_t *client, grpc_metadata *auth_md) {
    if (client->auth_token && client->auth_token_len > 0) {
        grpc_slice_unref(auth_md->value);
    }
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
