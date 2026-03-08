/*
 * etcd_common.c - Common utility functions for EV::Etcd
 */
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <EV/EVAPI.h>

#include "etcd_common.h"

/* gRPC status code names for error reporting - O(1) lookup table */
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

/* Check if a status code is retryable */
int is_retryable_status(grpc_status_code code) {
    switch (code) {
        case GRPC_STATUS_UNAVAILABLE:
        case GRPC_STATUS_RESOURCE_EXHAUSTED:
        case GRPC_STATUS_ABORTED:
        case GRPC_STATUS_INTERNAL:
        case GRPC_STATUS_DEADLINE_EXCEEDED:
            return 1;
        default:
            return 0;
    }
}

/* Create error hashref for callbacks */
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

/* Convert KeyValue protobuf to Perl hashref */
SV* kv_to_hashref(pTHX_ Mvccpb__KeyValue *kv) {
    HV *hv = newHV();

    /* Handle NULL data pointers for empty bytes fields */
    hv_store(hv, "key", 3,
             kv->key.data ? newSVpvn((char *)kv->key.data, kv->key.len) : newSVpvn("", 0), 0);
    hv_store(hv, "value", 5,
             kv->value.data ? newSVpvn((char *)kv->value.data, kv->value.len) : newSVpvn("", 0), 0);
    hv_store(hv, "create_revision", 15, newSViv(kv->create_revision), 0);
    hv_store(hv, "mod_revision", 12, newSViv(kv->mod_revision), 0);
    hv_store(hv, "version", 7, newSViv(kv->version), 0);
    hv_store(hv, "lease", 5, newSViv(kv->lease), 0);

    return newRV_noinc((SV *)hv);
}

/* Convert Event protobuf to Perl hashref */
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

/* Add ResponseHeader to a result hashref */
void add_header_to_hv(pTHX_ HV *result, Etcdserverpb__ResponseHeader *header) {
    if (!header) return;

    HV *hv = newHV();
    hv_store(hv, "cluster_id", 10, newSVuv(header->cluster_id), 0);
    hv_store(hv, "member_id", 9, newSVuv(header->member_id), 0);
    hv_store(hv, "revision", 8, newSViv(header->revision), 0);
    hv_store(hv, "raft_term", 9, newSVuv(header->raft_term), 0);
    hv_store(result, "header", 6, newRV_noinc((SV *)hv), 0);
}

/* Setup auth metadata for gRPC call */
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

/* Cleanup auth metadata after call start */
void cleanup_auth_metadata(ev_etcd_t *client, grpc_metadata *auth_md) {
    if (client->auth_token && client->auth_token_len > 0) {
        grpc_slice_unref(auth_md->value);
    }
}

/*
 * Cached gRPC method slices - initialized once, reused for all calls.
 * Static slices don't need reference counting.
 */
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

/* Initialize all cached method slices (called once from BOOT) */
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
