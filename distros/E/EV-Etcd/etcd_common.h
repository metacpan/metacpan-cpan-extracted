/*
 * etcd_common.h - Common types and declarations for EV::Etcd
 */
#ifndef ETCD_COMMON_H
#define ETCD_COMMON_H

/* Need EV types for ev_async in struct definitions */
#include <EV/EVAPI.h>

/* Threading support for hybrid gRPC/EV approach */
#include <pthread.h>

/* Reconnect backoff: 0.5s * attempt (capped at 5s) */
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

/*
 * gRPC channel creation compatibility.
 * - New API (>= ~1.42): grpc_insecure_credentials_create + grpc_channel_create
 * - Old API (< ~1.42):  grpc_insecure_channel_create
 */
static inline grpc_channel *
etcd_create_insecure_channel(const char *target, const grpc_channel_args *args) {
#ifdef HAVE_GRPC_NEW_CHANNEL_API
    grpc_channel_credentials *creds = grpc_insecure_credentials_create();
    grpc_channel *channel = grpc_channel_create(target, creds, args);
    grpc_channel_credentials_release(creds);
    return channel;
#else
    return grpc_insecure_channel_create(target, args, NULL);
#endif
}

#include "kv.pb-c.h"
#include "rpc.pb-c.h"
#include "lock.pb-c.h"
#include "election.pb-c.h"

/*
 * Size limits for keys and values.
 * etcd defaults: MaxRequestBytes = 1.5 MiB
 * We use slightly lower limits to leave room for protobuf overhead.
 */
#define ETCD_MAX_KEY_SIZE   (1024 * 1024)      /* 1 MiB max key size */
#define ETCD_MAX_VALUE_SIZE (1024 * 1024)      /* 1 MiB max value size */

/* Validation macros for input sizes */
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

/* Auth input limits - prevent DoS via oversized credentials */
#define ETCD_MAX_USERNAME_SIZE  256   /* Reasonable username limit */
#define ETCD_MAX_PASSWORD_SIZE  4096  /* Reasonable password limit */

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

/* URL limit for cluster member peer URLs */
#define ETCD_MAX_URL_SIZE  2048  /* Standard URL length limit */

#define VALIDATE_URL_SIZE(len) \
    do { \
        if ((len) > ETCD_MAX_URL_SIZE) { \
            croak("peer URL too large: %zu bytes (max %d)", (size_t)(len), ETCD_MAX_URL_SIZE); \
        } \
    } while (0)

/* Call types for tag identification */
typedef enum {
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

/* Forward declaration */
struct ev_etcd_struct;

/*
 * Queued event structure for passing gRPC completions from
 * the gRPC thread to the main EV thread.
 */
typedef struct queued_event {
    void *tag;              /* The tag from grpc_event */
    int success;            /* The success flag from grpc_event */
    struct queued_event *next;
} queued_event_t;

/*
 * Base structure for all call types - must be first in each call struct.
 * Used as the tag for gRPC operations.
 */
typedef struct call_base {
    call_type_t type;
} call_base_t;

/* Pending call structure (for unary RPCs) */
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

/* Watch recovery parameters */
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

/* Watch structure (for streaming watch) */
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
    ev_timer reconnect_timer;  /* Backoff timer for reconnection */
} watch_call_t;

/* Keepalive structure (for streaming lease keepalive) */
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
    ev_timer reconnect_timer;  /* Backoff timer for reconnection */
} keepalive_call_t;

/* Election observe parameters for reconnection */
typedef struct observe_params {
    char *name;
    size_t name_len;
} observe_params_t;

/* Election observe structure (for streaming election observe) */
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
    ev_timer reconnect_timer;  /* Backoff timer for reconnection */
    observe_params_t params;
} observe_call_t;

/* Client structure */
typedef struct ev_etcd_struct {
    grpc_channel *channel;
    grpc_completion_queue *cq;

    /* Hybrid threading: gRPC thread + ev_async for main thread notification */
    pthread_t cq_thread;        /* Thread running gRPC CQ loop */
    pthread_mutex_t queue_mutex; /* Protects event_queue */
    ev_async cq_async;          /* Async watcher to wake main thread */
    queued_event_t *event_queue; /* Queue of completed events */
    queued_event_t *event_queue_tail; /* Tail for O(1) append */
    volatile int thread_running; /* Flag to signal thread shutdown */

    pending_call_t *pending_calls;
    watch_call_t *watches;
    keepalive_call_t *keepalives;
    observe_call_t *observes;
    int active;
    int in_callback;  /* Guard against freeing client during event processing */
    char *auth_token;
    size_t auth_token_len;
    int timeout_seconds;

    /* Multiple endpoints for failover */
    char **endpoints;
    int endpoint_count;
    int current_endpoint;

    /* Retry configuration */
    int max_retries;

    /* Health monitoring */
    ev_timer health_timer;
    int is_healthy;
    SV *health_callback;
    pid_t owner_pid;  /* PID of process that created this client (fork safety) */
} ev_etcd_t;

typedef ev_etcd_t *EV__Etcd;
typedef watch_call_t *EV__Etcd__Watch;
typedef keepalive_call_t *EV__Etcd__Keepalive;
typedef observe_call_t *EV__Etcd__Observe;

/* Initialize a call's base structure */
static inline void init_call_base(call_base_t *base, call_type_t type) {
    base->type = type;
}

/* Helper macro to validate callback is a code reference */
#define VALIDATE_CALLBACK(cb) \
    do { \
        if (!SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV) { \
            croak("callback must be a code reference"); \
        } \
    } while (0)

/* Common utility functions */
const char* grpc_status_name(grpc_status_code code);
int is_retryable_status(grpc_status_code code);
SV* create_error_hv(pTHX_ grpc_status_code code, const char *message, size_t message_len, const char *source);

/* Helper functions */
SV* kv_to_hashref(pTHX_ Mvccpb__KeyValue *kv);
SV* event_to_hashref(pTHX_ Mvccpb__Event *event);
void add_header_to_hv(pTHX_ HV *result, Etcdserverpb__ResponseHeader *header);

/* Auth metadata helpers */
void setup_auth_metadata(ev_etcd_t *client, grpc_op *op, grpc_metadata *auth_md);
void cleanup_auth_metadata(ev_etcd_t *client, grpc_metadata *auth_md);

/*
 * Cached gRPC method slices - static strings don't need ref counting
 * These are initialized once and reused for all calls
 */
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

/* Initialize cached method slices (call once at module load) */
void init_method_slices(void);

/*
 * Helper macro to serialize protobuf and create grpc_slice in one allocation.
 * Uses grpc_slice_malloc to avoid double allocation.
 *
 * Usage:
 *   SERIALIZE_PROTOBUF_TO_SLICE(slice_var, get_packed_size_func, pack_func, &request);
 */
#define SERIALIZE_PROTOBUF_TO_SLICE(slice_var, size_func, pack_func, req_ptr) \
    do { \
        size_t _req_len = size_func(req_ptr); \
        slice_var = grpc_slice_malloc(_req_len); \
        pack_func(req_ptr, GRPC_SLICE_START_PTR(slice_var)); \
    } while (0)

/*
 * Helper macro to validate gRPC response status and buffer.
 * Must be used at the start of response handlers.
 * Defines _resp_slice variable for use with UNPACK_RESPONSE.
 *
 * Usage:
 *   BEGIN_RESPONSE_HANDLER(pc, "range");
 *   // _resp_slice is now available
 */
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

/*
 * Helper macro to unpack protobuf response from _resp_slice.
 * Must be used after BEGIN_RESPONSE_HANDLER.
 *
 * Usage:
 *   Etcdserverpb__PutResponse *resp;
 *   UNPACK_RESPONSE(pc, resp, etcdserverpb__put_response__unpack);
 */
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

/*
 * Helper macro for error callback with explicit status code and source.
 *
 * Usage:
 *   CALL_STATUS_ERROR_CALLBACK(callback, GRPC_STATUS_UNAVAILABLE, "Watch stream ended", "watch");
 */
#define CALL_STATUS_ERROR_CALLBACK(callback, status, message, source) \
    do { \
        dSP; \
        ENTER; SAVETMPS; PUSHMARK(SP); EXTEND(SP, 2); \
        PUSHs(&PL_sv_undef); \
        PUSHs(sv_2mortal(create_error_hv(aTHX_ status, \
            message, strlen(message), source))); \
        PUTBACK; CALL_SV_SAFE(callback, G_DISCARD); FREETMPS; LEAVE; \
    } while (0)

/*
 * Helper macro for simple string error callback (INTERNAL status).
 * Returns a structured error hashref consistent with CALL_ERROR_CALLBACK.
 *
 * Usage:
 *   CALL_SIMPLE_ERROR_CALLBACK(callback, "Error message");
 */
#define CALL_SIMPLE_ERROR_CALLBACK(callback, message) \
    CALL_STATUS_ERROR_CALLBACK(callback, GRPC_STATUS_INTERNAL, message, "internal")

/*
 * Helper macro for success callback with result hashref.
 *
 * Usage:
 *   CALL_SUCCESS_CALLBACK(callback, result_hv);
 */
#define CALL_SUCCESS_CALLBACK(callback, result_hv) \
    do { \
        dSP; \
        ENTER; SAVETMPS; PUSHMARK(SP); EXTEND(SP, 2); \
        PUSHs(sv_2mortal(newRV_noinc((SV *)result_hv))); \
        PUSHs(&PL_sv_undef); \
        PUTBACK; CALL_SV_SAFE(callback, G_DISCARD); FREETMPS; LEAVE; \
    } while (0)

/*
 * Helper macros for unary RPC pending call initialization and cleanup.
 * Reduces boilerplate across all unary RPC implementations.
 */

/*
 * Initialize a pending_call_t structure for a unary RPC.
 *
 * Usage:
 *   pending_call_t *pc;
 *   INIT_PENDING_CALL(pc, CALL_TYPE_RANGE, callback, client);
 */
#define INIT_PENDING_CALL(pc, call_type, callback_sv, client_ref) \
    do { \
        Newxz((pc), 1, pending_call_t); \
        init_call_base(&(pc)->base, (call_type)); \
        (pc)->callback = newSVsv((callback_sv)); \
        (pc)->client = (client_ref); \
        grpc_metadata_array_init(&(pc)->initial_metadata); \
        grpc_metadata_array_init(&(pc)->trailing_metadata); \
        (pc)->recv_buffer = NULL; \
        (pc)->status_details = grpc_empty_slice(); \
    } while (0)

/*
 * Cleanup a pending_call_t on error before it's added to the pending list.
 * Use this when grpc_call_start_batch fails.
 *
 * Usage:
 *   if (err != GRPC_CALL_OK) {
 *       CLEANUP_PENDING_CALL_ON_ERROR(pc);
 *       croak("Failed to start gRPC call: %d", err);
 *   }
 */
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

/*
 * Helper macros for streaming call reconnection to reduce code triplication
 * across watch, keepalive, and observe reconnect functions.
 */

/*
 * Cleanup old streaming call state before reconnection.
 * Works with any streaming call struct that has these fields.
 *
 * Usage:
 *   STREAMING_CALL_CLEANUP(wc);  // For watch_call_t
 *   STREAMING_CALL_CLEANUP(kc);  // For keepalive_call_t
 *   STREAMING_CALL_CLEANUP(oc);  // For observe_call_t
 */
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

/*
 * Reinitialize streaming call state for reconnection.
 *
 * Usage:
 *   STREAMING_CALL_REINIT(wc);
 */
#define STREAMING_CALL_REINIT(call_ptr) \
    do { \
        grpc_metadata_array_init(&(call_ptr)->initial_metadata); \
        grpc_metadata_array_init(&(call_ptr)->trailing_metadata); \
        (call_ptr)->status_details = grpc_empty_slice(); \
        (call_ptr)->active = 1; \
    } while (0)

/*
 * Setup standard 4-op batch for streaming call reconnection.
 * Requires: ops[4], auth_md, send_buffer, call_ptr all in scope.
 *
 * Usage:
 *   STREAMING_CALL_SETUP_OPS(client, ops, auth_md, send_buffer, wc);
 */
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

/*
 * Handle error after failed batch start for streaming reconnect.
 *
 * Usage:
 *   STREAMING_CALL_BATCH_ERROR(wc);
 */
#define STREAMING_CALL_BATCH_ERROR(call_ptr) \
    do { \
        (call_ptr)->active = 0; \
        if ((call_ptr)->call) { \
            grpc_call_unref((call_ptr)->call); \
            (call_ptr)->call = NULL; \
        } \
    } while (0)

/* Finish deferred client destruction after in_callback guard.
 * Called from cq_async_callback and timer callbacks when DESTROY was
 * invoked during a Perl callback (in_callback=1 prevented immediate free). */
void finish_client_destroy(pTHX_ ev_etcd_t *client);

#endif /* ETCD_COMMON_H */
