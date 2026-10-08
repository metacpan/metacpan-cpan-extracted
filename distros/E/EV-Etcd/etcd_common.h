#ifndef ETCD_COMMON_H
#define ETCD_COMMON_H

#include <EV/EVAPI.h>
#include <pthread.h>

#define RECONNECT_BACKOFF_SECONDS(attempt) \
    ((attempt) * 0.5 > 5.0 ? 5.0 : (attempt) * 0.5)

/* Retry pace after a member answered without a leader */
#define NO_LEADER_RETRY_SECONDS 1.0

/* Perl before 5.42 crashes running a %SIG handler on a thread without a Perl
 * context; threads inherit the starter's mask, so gRPC's and ours block all */
#define WITH_SIGNALS_BLOCKED(stmt) \
    do { \
        sigset_t _ws_all, _ws_old; \
        sigfillset(&_ws_all); \
        pthread_sigmask(SIG_SETMASK, &_ws_all, &_ws_old); \
        stmt; \
        pthread_sigmask(SIG_SETMASK, &_ws_old, NULL); \
    } while (0)

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

/* protobuf-c packs proto3 strings with strlen: a NUL would cut them short */
#define VALIDATE_NO_NUL(str, len, what) \
    do { \
        if (memchr((str), '\0', (len))) \
            croak("%s contains a NUL byte", what); \
    } while (0)

#define VALIDATE_NAME(str, len) \
    do { \
        if ((len) > ETCD_MAX_USERNAME_SIZE) { \
            croak("name too large: %zu bytes (max %d)", (size_t)(len), ETCD_MAX_USERNAME_SIZE); \
        } \
        VALIDATE_NO_NUL(str, len, "name"); \
    } while (0)

#define VALIDATE_PASSWORD(str, len) \
    do { \
        if ((len) > ETCD_MAX_PASSWORD_SIZE) { \
            croak("password too large: %zu bytes (max %d)", (size_t)(len), ETCD_MAX_PASSWORD_SIZE); \
        } \
        VALIDATE_NO_NUL(str, len, "password"); \
    } while (0)

#define ETCD_MAX_URL_SIZE  2048

#define VALIDATE_URL_SIZE(len) \
    do { \
        if ((len) > ETCD_MAX_URL_SIZE) { \
            croak("peer URL too large: %zu bytes (max %d)", (size_t)(len), ETCD_MAX_URL_SIZE); \
        } \
    } while (0)

/* Counts known keys first: iterating would reset the caller's each() */
#define VALIDATE_OPTS_KEYS(hv, op, ...) \
    do { \
        const char *_vk_valid[] = { __VA_ARGS__, NULL }; \
        I32 _vk_known = 0; \
        HE *_vk_he; \
        for (int _vk_n = 0; _vk_valid[_vk_n]; _vk_n++) { \
            if (hv_exists((hv), _vk_valid[_vk_n], strlen(_vk_valid[_vk_n]))) \
                _vk_known++; \
        } \
        if (!SvRMAGICAL(hv) && _vk_known == (I32)HvUSEDKEYS(hv)) \
            break; \
        hv_iterinit(hv); \
        while ((_vk_he = hv_iternext(hv)) != NULL) { \
            STRLEN _vk_len; \
            const char *_vk_key = HePV(_vk_he, _vk_len); \
            int _vk_ok = 0, _vk_i; \
            for (_vk_i = 0; _vk_valid[_vk_i] != NULL; _vk_i++) { \
                STRLEN _vk_vlen = strlen(_vk_valid[_vk_i]); \
                if (_vk_vlen == _vk_len && memcmp(_vk_valid[_vk_i], _vk_key, _vk_len) == 0) { \
                    _vk_ok = 1; \
                    break; \
                } \
            } \
            if (!_vk_ok) { \
                croak("Unknown option '%s' in $client->%s", _vk_key, op); \
            } \
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
    CALL_TYPE_AUTH_STATUS,
    CALL_TYPE_WATCH_STATUS,
    CALL_TYPE_LEASE_KEEPALIVE_STATUS,
    CALL_TYPE_ELECTION_OBSERVE_STATUS
} call_type_t;

struct ev_etcd_struct;

/* The client and each call keep the channel alive until their own cleanup. */
typedef struct channel_ref {
    grpc_channel *channel;
    unsigned refs;
} channel_ref_t;

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
    channel_ref_t *channel_ref;
    /* gRPC 1.30 links these into the call uncopied: keep until etcd_call_release */
    grpc_metadata send_md[2];
    int owns_auth_value;
} call_base_t;

/* Non-NULL tag for fire-and-forget batches; its CALL_TYPE_NONE is skipped */
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
    struct pending_call **pprev;  /* NULL once unlinked */
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
    grpc_status_code status;
    grpc_slice status_details;
    int64_t watch_id;
    int active;
    struct ev_etcd_struct *client;
    struct watch_call *next;
    int auto_reconnect;
    int established;           /* a response arrived on the current call */
    int64_t last_revision;
    watch_params_t params;
    int reconnect_attempt;
    unsigned attempt_epoch;    /* client->no_leader_epoch reconnect_attempt counts in */
    ev_timer reconnect_timer;
    ev_timer progress_timer;
    /* Client cleanup frees the gRPC state, the last owner the struct */
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
    grpc_status_code status;
    grpc_slice status_details;
    int64_t lease_id;
    int active;
    struct ev_etcd_struct *client;
    struct keepalive_call *next;
    int auto_reconnect;
    int established;
    int reconnect_attempt;
    unsigned attempt_epoch;
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
    grpc_status_code status;
    grpc_slice status_details;
    int active;
    struct ev_etcd_struct *client;
    struct observe_call *next;
    int auto_reconnect;
    int established;
    int reconnect_attempt;
    unsigned attempt_epoch;
    ev_timer reconnect_timer;
    observe_params_t params;
    int client_owns;           /* dual ownership, see watch_call_t */
    int perl_owns;
} observe_call_t;

typedef struct ev_etcd_struct {
    grpc_channel *channel;
    channel_ref_t *channel_ref;
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

    grpc_channel_credentials *creds;  /* NULL = insecure */
    char *tls_server_name;
    int keepalive_ms;          /* 0 = no keepalive pings */
    int keepalive_timeout_ms;

    int max_retries;
    /* Bumped by each answer without a leader: voids reconnects counted before it */
    unsigned no_leader_epoch;

    ev_timer health_timer;
    int is_healthy;
    SV *health_callback;
    pid_t owner_pid;
    struct ev_etcd_struct *next_live;  /* this process's live clients */
} ev_etcd_t;

static inline void link_pending_call(ev_etcd_t *client, pending_call_t *pc) {
    pc->next = client->pending_calls;
    if (pc->next)
        pc->next->pprev = &pc->next;
    pc->pprev = &client->pending_calls;
    client->pending_calls = pc;
}

static inline void unlink_pending_call(pending_call_t *pc) {
    if (!pc->pprev)
        return;
    *pc->pprev = pc->next;
    if (pc->next)
        pc->next->pprev = pc->pprev;
    pc->pprev = NULL;
}

typedef ev_etcd_t *EV__Etcd;
typedef watch_call_t *EV__Etcd__Watch;
typedef keepalive_call_t *EV__Etcd__Keepalive;
typedef observe_call_t *EV__Etcd__Observe;

static inline void init_call_base(call_base_t *base, call_type_t type) {
    base->type = type;
}

static inline void etcd_call_acquire(ev_etcd_t *client, call_base_t *base) {
    base->channel_gen = client->channel_gen;
    base->channel_ref = client->channel_ref;
    base->channel_ref->refs++;
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
#  define SvI64_nomg(sv) ((int64_t)SvIV_nomg(sv))
#  define SvU64(sv)   ((uint64_t)SvUV(sv))
#else
#  define newSVi64(v) newSVnv((NV)(v))
#  define newSVu64(v) newSVnv((NV)(v))
#  define SvI64(sv)   ((int64_t)SvNV(sv))
#  define SvI64_nomg(sv) ((int64_t)SvNV_nomg(sv))
#  define SvU64(sv)   ((uint64_t)SvNV(sv))
#endif

const char* grpc_status_name(grpc_status_code code);
int is_retryable_status(grpc_status_code code);
int is_permanent_status(grpc_status_code code);
int etcd_is_no_leader(grpc_status_code status, grpc_slice status_details);
SV* create_error_hv(pTHX_ grpc_status_code code, const char *message, size_t message_len, const char *source);
SV* create_pending_error_hv(pTHX_ pending_call_t *pc, grpc_status_code code, const char *source);

SV* kv_to_hashref(pTHX_ Mvccpb__KeyValue *kv);
SV* event_to_hashref(pTHX_ Mvccpb__Event *event);
void add_header_to_hv(pTHX_ HV *result, Etcdserverpb__ResponseHeader *header);

channel_ref_t *etcd_create_channel(ev_etcd_t *client, const char *target);
void etcd_channel_release(channel_ref_t *ref, int destroy);
void etcd_call_release(call_base_t *base);
void etcd_rotate_endpoint(ev_etcd_t *client);
void etcd_endpoint_failed(ev_etcd_t *client, const call_base_t *base,
                          grpc_status_code status, grpc_slice status_details);
void etcd_stream_failed(ev_etcd_t *client, unsigned channel_gen, int established,
                        grpc_status_code status, grpc_slice status_details);

void setup_auth_metadata(ev_etcd_t *client, grpc_op *op, call_base_t *base);
void setup_stream_metadata(ev_etcd_t *client, grpc_op *op, call_base_t *base);

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
        CALL_PENDING_ERROR_CALLBACK(pc, (pc)->status, source); \
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

/* No die may longjmp over the caller's cleanup: the report runs under G_EVAL
 * too, and SvROK tests a reference whose SvTRUE would call overloads */
#define CALL_SV_SAFE(sv, flags) \
    do { \
        call_sv(sv, (flags) | G_EVAL); \
        if (SvROK(ERRSV) || SvTRUE(ERRSV)) { \
            SV *_cb_err = sv_mortalcopy(ERRSV); \
            sv_setsv(ERRSV, &PL_sv_undef); \
            { \
                dSP; \
                ENTER; SAVETMPS; PUSHMARK(SP); \
                XPUSHs(_cb_err); \
                PUTBACK; \
                call_pv("EV::Etcd::_warn_callback_died", G_EVAL | G_DISCARD); \
                FREETMPS; LEAVE; \
                sv_setsv(ERRSV, &PL_sv_undef); \
            } \
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

#define CALL_PENDING_ERROR_CALLBACK(pc, status, source) \
    do { \
        dSP; \
        ENTER; SAVETMPS; PUSHMARK(SP); EXTEND(SP, 2); \
        PUSHs(&PL_sv_undef); \
        PUSHs(sv_2mortal(create_pending_error_hv(aTHX_ pc, status, source))); \
        PUTBACK; CALL_SV_SAFE((pc)->callback, G_DISCARD); FREETMPS; LEAVE; \
    } while (0)

#define CALL_PREBUILT_ERROR_CALLBACK(callback, err_sv) \
    do { \
        dSP; \
        ENTER; SAVETMPS; PUSHMARK(SP); EXTEND(SP, 2); \
        PUSHs(&PL_sv_undef); \
        PUSHs(sv_2mortal(err_sv)); \
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

/* Run inside the caller's statement, as cancel's is: its $@ must survive */
#define CALL_SYNC_SUCCESS_CALLBACK(callback, result_hv) \
    do { \
        ENTER; \
        save_scalar(PL_errgv); \
        CALL_SUCCESS_CALLBACK(callback, result_hv); \
        LEAVE; \
    } while (0)

#define INIT_PENDING_CALL(pc, call_type, client_ref) \
    do { \
        Newxz((pc), 1, pending_call_t); \
        init_call_base(&(pc)->base, (call_type)); \
        (pc)->client = (client_ref); \
        grpc_metadata_array_init(&(pc)->initial_metadata); \
        grpc_metadata_array_init(&(pc)->trailing_metadata); \
        (pc)->recv_buffer = NULL; \
        (pc)->status_details = grpc_empty_slice(); \
    } while (0)

/* After every argument conversion, so a croak cannot leak what this takes */
#define START_PENDING_CALL(pc, callback_sv, client_ref) \
    do { \
        (pc)->callback = newSVsv((callback_sv)); \
        etcd_call_acquire((client_ref), &(pc)->base); \
    } while (0)

/* Only for a call not yet linked into client->pending_calls */
#define CLEANUP_PENDING_CALL_ON_ERROR(pc) \
    do { \
        grpc_metadata_array_destroy(&(pc)->initial_metadata); \
        grpc_metadata_array_destroy(&(pc)->trailing_metadata); \
        if ((pc)->recv_buffer) grpc_byte_buffer_destroy((pc)->recv_buffer); \
        grpc_slice_unref((pc)->status_details); \
        if ((pc)->call) grpc_call_unref((pc)->call); \
        etcd_call_release(&(pc)->base); \
        SvREFCNT_dec((pc)->callback); \
        Safefree((pc)); \
    } while (0)

#define STREAMING_CALL_CLEANUP(call_ptr) \
    do { \
        if ((call_ptr)->call) { \
            grpc_call_unref((call_ptr)->call); \
            (call_ptr)->call = NULL; \
        } \
        etcd_call_release(&(call_ptr)->base); \
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
        (call_ptr)->status = GRPC_STATUS_OK; \
        (call_ptr)->status_details = grpc_empty_slice(); \
        (call_ptr)->active = 1; \
    } while (0)

#define STREAMING_CALL_SETUP_OPS(client, ops, send_buf, call_ptr) \
    do { \
        (ops)[0].op = GRPC_OP_SEND_INITIAL_METADATA; \
        setup_stream_metadata(client, &(ops)[0], &(call_ptr)->base); \
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
        etcd_call_release(&(call_ptr)->base); \
        grpc_metadata_array_destroy(&(call_ptr)->initial_metadata); \
        grpc_metadata_array_destroy(&(call_ptr)->trailing_metadata); \
        grpc_slice_unref((call_ptr)->status_details); \
        grpc_metadata_array_init(&(call_ptr)->initial_metadata); \
        grpc_metadata_array_init(&(call_ptr)->trailing_metadata); \
        (call_ptr)->status_details = grpc_empty_slice(); \
    } while (0)

void finish_client_destroy(pTHX_ ev_etcd_t *client);
void etcd_leave_callback(pTHX_ void *client);

/* A client DESTROY inside the window defers to its end. The end is a
 * save-stack destructor, so an exit() from a callback still reaches it. */
#define CALLBACK_WINDOW_BEGIN(client) \
    do { \
        ENTER; \
        (client)->in_callback++; \
        SAVEDESTRUCTOR_X(etcd_leave_callback, (client)); \
    } while (0)

/* Ends the window; true when the client was destroyed in it and is gone */
static inline int callback_window_end(pTHX_ ev_etcd_t *client) {
    int freed = client->in_callback == 1 && !client->active;
    LEAVE;
    return freed;
}
#define CALLBACK_WINDOW_END(client) callback_window_end(aTHX_ (client))

#endif
