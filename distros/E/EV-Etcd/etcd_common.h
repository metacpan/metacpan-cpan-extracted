#ifndef ETCD_COMMON_H
#define ETCD_COMMON_H

#include <EV/EVAPI.h>
#include <pthread.h>

#define RECONNECT_BACKOFF_SECONDS(attempt) \
    ((attempt) * 0.5 > 5.0 ? 5.0 : (attempt) * 0.5)

#include <grpc/grpc.h>
#ifdef HAVE_GRPC_CREDENTIALS_H
#include <grpc/credentials.h>
#else
#include <grpc/grpc_security.h>
#endif
#include <grpc/byte_buffer.h>
#include <grpc/byte_buffer_reader.h>

#include "kv.pb-c.h"
#include "rpc.pb-c.h"
#include "lock.pb-c.h"
#include "election.pb-c.h"

/* etcd's default MaxRequestBytes is 1.5 MiB */
#define ETCD_MAX_KEY_SIZE   (1024 * 1024)
#define ETCD_MAX_VALUE_SIZE (1024 * 1024)

#define VALIDATE_KEY_SIZE(key_len) \
    do { \
        if ((key_len) > ETCD_MAX_KEY_SIZE) { \
            croak("key too large: %zu bytes (max %d)", (size_t)(key_len), ETCD_MAX_KEY_SIZE); \
        } \
    } while (0)

#define VALIDATE_VALUE_SIZE(value_len) \
    do { \
        if ((value_len) > ETCD_MAX_VALUE_SIZE) { \
            croak("value too large: %zu bytes (max %d)", (size_t)(value_len), ETCD_MAX_VALUE_SIZE); \
        } \
    } while (0)

#define ETCD_MAX_USERNAME_SIZE  256
#define ETCD_MAX_PASSWORD_SIZE  4096

#define VALIDATE_USERNAME_SIZE(len) \
    do { \
        if ((len) > ETCD_MAX_USERNAME_SIZE) { \
            croak("username too large: %zu bytes (max %d)", (size_t)(len), ETCD_MAX_USERNAME_SIZE); \
        } \
    } while (0)

#define VALIDATE_PASSWORD_SIZE(len) \
    do { \
        if ((len) > ETCD_MAX_PASSWORD_SIZE) { \
            croak("password too large: %zu bytes (max %d)", (size_t)(len), ETCD_MAX_PASSWORD_SIZE); \
        } \
    } while (0)

#define ETCD_MAX_URL_SIZE  2048

#define VALIDATE_URL_SIZE(len) \
    do { \
        if ((len) > ETCD_MAX_URL_SIZE) { \
            croak("peer URL too large: %zu bytes (max %d)", (size_t)(len), ETCD_MAX_URL_SIZE); \
        } \
    } while (0)

typedef enum {
    CALL_TYPE_NONE = 0,
    CALL_TYPE_RANGE = 1,
    CALL_TYPE_PUT,
    CALL_TYPE_DELETE,
    CALL_TYPE_WATCH,
    CALL_TYPE_WATCH_RECV,
    CALL_TYPE_LEASE_GRANT,
    CALL_TYPE_LEASE_REVOKE,
    CALL_TYPE_LEASE_KEEPALIVE,
    CALL_TYPE_LEASE_KEEPALIVE_RECV,
    CALL_TYPE_LEASE_TIME_TO_LIVE,
    CALL_TYPE_LEASE_LEASES,
    CALL_TYPE_COMPACT,
    CALL_TYPE_STATUS,
    CALL_TYPE_TXN,
    CALL_TYPE_AUTH,
    CALL_TYPE_USER_ADD,
    CALL_TYPE_USER_DELETE,
    CALL_TYPE_USER_CHANGE_PASSWORD,
    CALL_TYPE_AUTH_ENABLE,
    CALL_TYPE_AUTH_DISABLE,
    CALL_TYPE_ROLE_ADD,
    CALL_TYPE_ROLE_DELETE,
    CALL_TYPE_ROLE_GET,
    CALL_TYPE_ROLE_LIST,
    CALL_TYPE_ROLE_GRANT_PERMISSION,
    CALL_TYPE_ROLE_REVOKE_PERMISSION,
    CALL_TYPE_USER_GRANT_ROLE,
    CALL_TYPE_USER_REVOKE_ROLE,
    CALL_TYPE_USER_GET,
    CALL_TYPE_USER_LIST,
    CALL_TYPE_LOCK,
    CALL_TYPE_UNLOCK,
    CALL_TYPE_ELECTION_CAMPAIGN,
    CALL_TYPE_ELECTION_PROCLAIM,
    CALL_TYPE_ELECTION_LEADER,
    CALL_TYPE_ELECTION_RESIGN,
    CALL_TYPE_ELECTION_OBSERVE,
    CALL_TYPE_ELECTION_OBSERVE_RECV,
    CALL_TYPE_MEMBER_ADD,
    CALL_TYPE_MEMBER_REMOVE,
    CALL_TYPE_MEMBER_UPDATE,
    CALL_TYPE_MEMBER_LIST,
    CALL_TYPE_MEMBER_PROMOTE,
    CALL_TYPE_ALARM,
    CALL_TYPE_DEFRAGMENT,
    CALL_TYPE_HASH_KV,
    CALL_TYPE_MOVE_LEADER,
    CALL_TYPE_AUTH_STATUS
} call_type_t;

struct ev_etcd_struct;

typedef struct queued_event {
    void *tag;
    int success;
    struct queued_event *next;
} queued_event_t;

/* First member of every call struct: the struct's address is its gRPC tag */
typedef struct call_base {
    call_type_t type;
    unsigned channel_gen;  /* client->channel_gen when the call was created */
    pid_t owner_pid;
} call_base_t;

/* Tag for fire-and-forget batches: GRPC_CQ_NEXT needs a non-NULL tag, and
 * process_grpc_event skips CALL_TYPE_NONE */
extern call_base_t cancel_sentinel;

typedef struct pending_call {
    call_base_t base;  /* Must be first */
    grpc_call *call;
    SV *callback;
    grpc_metadata_array initial_metadata;
    grpc_metadata_array trailing_metadata;
    grpc_byte_buffer *recv_buffer;
    grpc_status_code status;
    grpc_slice status_details;
    struct ev_etcd_struct *client;
    struct pending_call *next;
} pending_call_t;

typedef struct watch_params {
    char *key;
    size_t key_len;
    char *range_end;
    size_t range_end_len;
    int64_t start_revision;
    int prev_kv;
    int progress_notify;
    int64_t watch_id;
    int has_watch_id;
} watch_params_t;

typedef struct watch_call {
    call_base_t base;  /* Must be first */
    grpc_call *call;
    SV *callback;
    grpc_metadata_array initial_metadata;
    grpc_metadata_array trailing_metadata;
    grpc_byte_buffer *recv_buffer;
    grpc_slice status_details;
    int64_t watch_id;
    int active;
    struct ev_etcd_struct *client;
    struct watch_call *next;
    int auto_reconnect;
    int64_t last_revision;
    watch_params_t params;
    int reconnect_attempt;
    ev_timer reconnect_timer;
    /* Dual ownership: client cleanup frees the gRPC state, the last owner
     * frees the struct, so a Perl handle can outlive client cleanup */
    int client_owns;
    int perl_owns;
} watch_call_t;

typedef struct keepalive_call {
    call_base_t base;  /* Must be first */
    grpc_call *call;
    SV *callback;
    grpc_metadata_array initial_metadata;
    grpc_metadata_array trailing_metadata;
    grpc_byte_buffer *recv_buffer;
    grpc_slice status_details;
    int64_t lease_id;
    int active;
    struct ev_etcd_struct *client;
    struct keepalive_call *next;
    int auto_reconnect;
    int reconnect_attempt;
    ev_timer reconnect_timer;
    ev_timer renew_timer;
    int client_owns;           /* dual ownership, see watch_call_t */
    int perl_owns;
} keepalive_call_t;

typedef struct observe_params {
    char *name;
    size_t name_len;
} observe_params_t;

typedef struct observe_call {
    call_base_t base;  /* Must be first */
    grpc_call *call;
    SV *callback;
    grpc_metadata_array initial_metadata;
    grpc_metadata_array trailing_metadata;
    grpc_byte_buffer *recv_buffer;
    grpc_slice status_details;
    int active;
    struct ev_etcd_struct *client;
    struct observe_call *next;
    int auto_reconnect;
    int reconnect_attempt;
    ev_timer reconnect_timer;
    observe_params_t params;
    int client_owns;           /* dual ownership, see watch_call_t */
    int perl_owns;
} observe_call_t;

typedef struct ev_etcd_struct {
    grpc_channel *channel;
    grpc_completion_queue *cq;

    /* cq_thread hands completions to the EV thread via event_queue + cq_async */
    pthread_t cq_thread;
    pthread_mutex_t queue_mutex; /* Protects event_queue */
    ev_async cq_async;
    queued_event_t *event_queue;
    queued_event_t *event_queue_tail;

    pending_call_t *pending_calls;
    watch_call_t *watches;
    keepalive_call_t *keepalives;
    observe_call_t *observes;
    int active;
    int in_callback;  /* Guard against freeing client during event processing */
    char *auth_token;
    size_t auth_token_len;
    int timeout_seconds;

    char **endpoints;
    int endpoint_count;
    int current_endpoint;
    unsigned channel_gen;  /* bumped on every endpoint switch */
    /* Kept for one switch so calls queued on it end on their own terms
     * instead of failing with "Channel Destroyed" */
    grpc_channel *old_channel;

    grpc_channel_credentials *creds;  /* NULL = insecure */
    char *tls_server_name;
    int keepalive_ms;          /* 0 = no keepalive pings */
    int keepalive_timeout_ms;

    int max_retries;

    ev_timer health_timer;
    int is_healthy;
    SV *health_callback;
    pid_t owner_pid;
    struct ev_etcd_struct *next_live;  /* this process's live clients */
} ev_etcd_t;

typedef ev_etcd_t *EV__Etcd;
typedef watch_call_t *EV__Etcd__Watch;
typedef keepalive_call_t *EV__Etcd__Keepalive;
typedef observe_call_t *EV__Etcd__Observe;

static inline void init_call_base(call_base_t *base, call_type_t type) {
    base->type = type;
}

#define VALIDATE_CALLBACK(cb) \
    do { \
        if (!SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV) { \
            croak("callback must be a code reference"); \
        } \
    } while (0)

/* 32-bit IV perls go through NV, exact only to 2^53: fine for revisions,
 * lossy for lease, member and cluster ids, which use all 63/64 bits */
#if IVSIZE >= 8
#  define newSVi64(v) newSViv((IV)(v))
#  define newSVu64(v) newSVuv((UV)(v))
#  define SvI64(sv)   ((int64_t)SvIV(sv))
#  define SvU64(sv)   ((uint64_t)SvUV(sv))
#else
#  define newSVi64(v) newSVnv((NV)(v))
#  define newSVu64(v) newSVnv((NV)(v))
#  define SvI64(sv)   ((int64_t)SvNV(sv))
#  define SvU64(sv)   ((uint64_t)SvNV(sv))
#endif

const char* grpc_status_name(grpc_status_code code);
int is_retryable_status(grpc_status_code code);
SV* create_error_hv(pTHX_ grpc_status_code code, const char *message, size_t message_len, const char *source);

SV* kv_to_hashref(pTHX_ Mvccpb__KeyValue *kv);
SV* event_to_hashref(pTHX_ Mvccpb__Event *event);
void add_header_to_hv(pTHX_ HV *result, Etcdserverpb__ResponseHeader *header);

grpc_channel *etcd_create_channel(ev_etcd_t *client, const char *target);
void etcd_rotate_endpoint(ev_etcd_t *client);
void etcd_endpoint_failed(ev_etcd_t *client, unsigned channel_gen, grpc_status_code status);
void etcd_stream_failed(ev_etcd_t *client, unsigned channel_gen);

void setup_auth_metadata(ev_etcd_t *client, grpc_op *op, grpc_metadata *auth_md);
void cleanup_auth_metadata(ev_etcd_t *client, grpc_metadata *auth_md);

extern grpc_slice METHOD_KV_RANGE;
extern grpc_slice METHOD_KV_PUT;
extern grpc_slice METHOD_KV_DELETE;
extern grpc_slice METHOD_KV_COMPACT;
extern grpc_slice METHOD_KV_TXN;
extern grpc_slice METHOD_WATCH;
extern grpc_slice METHOD_LEASE_GRANT;
extern grpc_slice METHOD_LEASE_REVOKE;
extern grpc_slice METHOD_LEASE_KEEPALIVE;
extern grpc_slice METHOD_LEASE_TTL;
extern grpc_slice METHOD_LEASE_LEASES;
extern grpc_slice METHOD_MAINTENANCE_STATUS;
extern grpc_slice METHOD_AUTH_AUTHENTICATE;
extern grpc_slice METHOD_AUTH_USER_ADD;
extern grpc_slice METHOD_AUTH_USER_DELETE;
extern grpc_slice METHOD_AUTH_USER_CHANGE_PASSWORD;
extern grpc_slice METHOD_AUTH_USER_GET;
extern grpc_slice METHOD_AUTH_USER_LIST;
extern grpc_slice METHOD_AUTH_USER_GRANT_ROLE;
extern grpc_slice METHOD_AUTH_USER_REVOKE_ROLE;
extern grpc_slice METHOD_AUTH_ENABLE;
extern grpc_slice METHOD_AUTH_DISABLE;
extern grpc_slice METHOD_AUTH_ROLE_ADD;
extern grpc_slice METHOD_AUTH_ROLE_DELETE;
extern grpc_slice METHOD_AUTH_ROLE_GET;
extern grpc_slice METHOD_AUTH_ROLE_LIST;
extern grpc_slice METHOD_AUTH_ROLE_GRANT_PERM;
extern grpc_slice METHOD_AUTH_ROLE_REVOKE_PERM;
extern grpc_slice METHOD_LOCK;
extern grpc_slice METHOD_UNLOCK;
extern grpc_slice METHOD_ELECTION_CAMPAIGN;
extern grpc_slice METHOD_ELECTION_PROCLAIM;
extern grpc_slice METHOD_ELECTION_LEADER;
extern grpc_slice METHOD_ELECTION_RESIGN;
extern grpc_slice METHOD_ELECTION_OBSERVE;
extern grpc_slice METHOD_CLUSTER_MEMBER_ADD;
extern grpc_slice METHOD_CLUSTER_MEMBER_REMOVE;
extern grpc_slice METHOD_CLUSTER_MEMBER_UPDATE;
extern grpc_slice METHOD_CLUSTER_MEMBER_LIST;
extern grpc_slice METHOD_CLUSTER_MEMBER_PROMOTE;
extern grpc_slice METHOD_MAINTENANCE_ALARM;
extern grpc_slice METHOD_MAINTENANCE_DEFRAGMENT;
extern grpc_slice METHOD_MAINTENANCE_HASH_KV;
extern grpc_slice METHOD_MAINTENANCE_MOVE_LEADER;
extern grpc_slice METHOD_AUTH_STATUS;

void init_method_slices(void);

#define SERIALIZE_PROTOBUF_TO_SLICE(slice_var, size_func, pack_func, req_ptr) \
    do { \
        size_t _req_len = size_func(req_ptr); \
        slice_var = grpc_slice_malloc(_req_len); \
        pack_func(req_ptr, GRPC_SLICE_START_PTR(slice_var)); \
    } while (0)

/* Returns from the calling handler on error; declares _resp_slice */
#define BEGIN_RESPONSE_HANDLER(pc, source) \
    if ((pc)->status != GRPC_STATUS_OK) { \
        CALL_ERROR_CALLBACK((pc)->callback, (pc)->status, (pc)->status_details, source); \
        return; \
    } \
    if (!(pc)->recv_buffer) { \
        CALL_SIMPLE_ERROR_CALLBACK((pc)->callback, "No response received"); \
        return; \
    } \
    grpc_byte_buffer_reader _resp_reader; \
    if (!grpc_byte_buffer_reader_init(&_resp_reader, (pc)->recv_buffer)) { \
        CALL_SIMPLE_ERROR_CALLBACK((pc)->callback, "Failed to read response buffer"); \
        return; \
    } \
    grpc_slice _resp_slice = grpc_byte_buffer_reader_readall(&_resp_reader); \
    grpc_byte_buffer_reader_destroy(&_resp_reader)

/* Consumes _resp_slice; returns from the calling handler on a parse error */
#define UNPACK_RESPONSE(pc, resp_var, unpack_func) \
    resp_var = unpack_func(NULL, GRPC_SLICE_LENGTH(_resp_slice), GRPC_SLICE_START_PTR(_resp_slice)); \
    grpc_slice_unref(_resp_slice); \
    if (!(resp_var)) { \
        CALL_SIMPLE_ERROR_CALLBACK((pc)->callback, "Failed to parse response"); \
        return; \
    }

/* Safe call_sv wrapper: traps die() in callbacks to prevent longjmp over cleanup */
#define CALL_SV_SAFE(sv, flags) \
    do { \
        call_sv(sv, (flags) | G_EVAL); \
        if (SvTRUE(ERRSV)) { \
            warn("EV::Etcd: callback died: %" SVf, SVfARG(ERRSV)); \
            sv_setsv(ERRSV, &PL_sv_undef); \
        } \
    } while (0)

#define CALL_ERROR_CALLBACK(callback, status, status_details, source) \
    do { \
        dSP; \
        ENTER; SAVETMPS; PUSHMARK(SP); EXTEND(SP, 2); \
        PUSHs(&PL_sv_undef); \
        PUSHs(sv_2mortal(create_error_hv(aTHX_ status, \
            (const char *)GRPC_SLICE_START_PTR(status_details), \
            GRPC_SLICE_LENGTH(status_details), source))); \
        PUTBACK; CALL_SV_SAFE(callback, G_DISCARD); FREETMPS; LEAVE; \
    } while (0)

#define CALL_STATUS_ERROR_CALLBACK(callback, status, message, source) \
    do { \
        dSP; \
        ENTER; SAVETMPS; PUSHMARK(SP); EXTEND(SP, 2); \
        PUSHs(&PL_sv_undef); \
        PUSHs(sv_2mortal(create_error_hv(aTHX_ status, \
            message, strlen(message), source))); \
        PUTBACK; CALL_SV_SAFE(callback, G_DISCARD); FREETMPS; LEAVE; \
    } while (0)

#define CALL_SIMPLE_ERROR_CALLBACK(callback, message) \
    CALL_STATUS_ERROR_CALLBACK(callback, GRPC_STATUS_INTERNAL, message, "internal")

#define CALL_SUCCESS_CALLBACK(callback, result_hv) \
    do { \
        dSP; \
        ENTER; SAVETMPS; PUSHMARK(SP); EXTEND(SP, 2); \
        PUSHs(sv_2mortal(newRV_noinc((SV *)result_hv))); \
        PUSHs(&PL_sv_undef); \
        PUTBACK; CALL_SV_SAFE(callback, G_DISCARD); FREETMPS; LEAVE; \
    } while (0)

#define INIT_PENDING_CALL(pc, call_type, callback_sv, client_ref) \
    do { \
        Newxz((pc), 1, pending_call_t); \
        init_call_base(&(pc)->base, (call_type)); \
        (pc)->base.channel_gen = (client_ref)->channel_gen; \
        (pc)->callback = newSVsv((callback_sv)); \
        (pc)->client = (client_ref); \
        grpc_metadata_array_init(&(pc)->initial_metadata); \
        grpc_metadata_array_init(&(pc)->trailing_metadata); \
        (pc)->recv_buffer = NULL; \
        (pc)->status_details = grpc_empty_slice(); \
    } while (0)

/* Only for a call not yet linked into client->pending_calls */
#define CLEANUP_PENDING_CALL_ON_ERROR(pc) \
    do { \
        grpc_metadata_array_destroy(&(pc)->initial_metadata); \
        grpc_metadata_array_destroy(&(pc)->trailing_metadata); \
        if ((pc)->recv_buffer) grpc_byte_buffer_destroy((pc)->recv_buffer); \
        grpc_slice_unref((pc)->status_details); \
        if ((pc)->call) grpc_call_unref((pc)->call); \
        SvREFCNT_dec((pc)->callback); \
        Safefree((pc)); \
    } while (0)

#define STREAMING_CALL_CLEANUP(call_ptr) \
    do { \
        if ((call_ptr)->call) { \
            grpc_call_unref((call_ptr)->call); \
            (call_ptr)->call = NULL; \
        } \
        grpc_metadata_array_destroy(&(call_ptr)->initial_metadata); \
        grpc_metadata_array_destroy(&(call_ptr)->trailing_metadata); \
        if ((call_ptr)->recv_buffer) { \
            grpc_byte_buffer_destroy((call_ptr)->recv_buffer); \
            (call_ptr)->recv_buffer = NULL; \
        } \
        grpc_slice_unref((call_ptr)->status_details); \
    } while (0)

#define STREAMING_CALL_REINIT(call_ptr) \
    do { \
        grpc_metadata_array_init(&(call_ptr)->initial_metadata); \
        grpc_metadata_array_init(&(call_ptr)->trailing_metadata); \
        (call_ptr)->status_details = grpc_empty_slice(); \
        (call_ptr)->active = 1; \
    } while (0)

#define STREAMING_CALL_SETUP_OPS(client, ops, auth_md, send_buf, call_ptr) \
    do { \
        (ops)[0].op = GRPC_OP_SEND_INITIAL_METADATA; \
        setup_auth_metadata(client, &(ops)[0], &(auth_md)); \
        (ops)[1].op = GRPC_OP_RECV_INITIAL_METADATA; \
        (ops)[1].data.recv_initial_metadata.recv_initial_metadata = &(call_ptr)->initial_metadata; \
        (ops)[2].op = GRPC_OP_SEND_MESSAGE; \
        (ops)[2].data.send_message.send_message = (send_buf); \
        (ops)[3].op = GRPC_OP_RECV_MESSAGE; \
        (ops)[3].data.recv_message.recv_message = &(call_ptr)->recv_buffer; \
    } while (0)

/* Re-inits what it destroys: the cleanup_* that follows destroys them again */
#define STREAMING_CALL_BATCH_ERROR(call_ptr) \
    do { \
        (call_ptr)->active = 0; \
        if ((call_ptr)->call) { \
            grpc_call_unref((call_ptr)->call); \
            (call_ptr)->call = NULL; \
        } \
        grpc_metadata_array_destroy(&(call_ptr)->initial_metadata); \
        grpc_metadata_array_destroy(&(call_ptr)->trailing_metadata); \
        grpc_slice_unref((call_ptr)->status_details); \
        grpc_metadata_array_init(&(call_ptr)->initial_metadata); \
        grpc_metadata_array_init(&(call_ptr)->trailing_metadata); \
        (call_ptr)->status_details = grpc_empty_slice(); \
    } while (0)

void finish_client_destroy(pTHX_ ev_etcd_t *client);

#endif
