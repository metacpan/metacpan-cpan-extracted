/*
 * etcd_maint.c - Maintenance operation handlers for EV::Etcd
 */
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "etcd_common.h"
#include "etcd_maint.h"

/* Process StatusResponse */
void process_status_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "status");

    Etcdserverpb__StatusResponse *resp;
    UNPACK_RESPONSE(pc, resp, etcdserverpb__status_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);

    if (resp->version) {
        hv_store(result, "version", 7, newSVpv(resp->version, 0), 0);
    }
    hv_store(result, "db_size", 7, newSVi64(resp->dbsize), 0);
    hv_store(result, "leader", 6, newSVu64(resp->leader), 0);
    hv_store(result, "raft_index", 10, newSVu64(resp->raftindex), 0);
    hv_store(result, "raft_term", 9, newSVu64(resp->raftterm), 0);
    hv_store(result, "raft_applied_index", 18, newSVu64(resp->raftappliedindex), 0);
    hv_store(result, "db_size_in_use", 14, newSVi64(resp->dbsizeinuse), 0);
    hv_store(result, "is_learner", 10, newSViv(resp->islearner ? 1 : 0), 0);

    if (resp->n_errors > 0) {
        AV *errors_av = newAV();
        for (size_t i = 0; i < resp->n_errors; i++) {
            /* Handle NULL string in repeated field */
            av_push(errors_av, resp->errors[i] ? newSVpv(resp->errors[i], 0) : newSVpvn("", 0));
        }
        hv_store(result, "errors", 6, newRV_noinc((SV *)errors_av), 0);
    }

    etcdserverpb__status_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}

/* Helper to convert AlarmType enum to string */
static const char* alarm_type_name(Etcdserverpb__AlarmType type) {
    switch (type) {
        case ETCDSERVERPB__ALARM_TYPE__NONE: return "NONE";
        case ETCDSERVERPB__ALARM_TYPE__NOSPACE: return "NOSPACE";
        case ETCDSERVERPB__ALARM_TYPE__CORRUPT: return "CORRUPT";
        default: return "UNKNOWN";
    }
}

/* Process AlarmResponse */
void process_alarm_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "alarm");

    Etcdserverpb__AlarmResponse *resp;
    UNPACK_RESPONSE(pc, resp, etcdserverpb__alarm_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);

    AV *alarms_av = newAV();
    for (size_t i = 0; i < resp->n_alarms; i++) {
        HV *alarm_hv = newHV();
        hv_store(alarm_hv, "member_id", 9, newSVu64(resp->alarms[i]->memberid), 0);
        hv_store(alarm_hv, "alarm", 5, newSViv(resp->alarms[i]->alarm), 0);
        hv_store(alarm_hv, "alarm_type", 10,
                 newSVpv(alarm_type_name(resp->alarms[i]->alarm), 0), 0);
        av_push(alarms_av, newRV_noinc((SV *)alarm_hv));
    }
    hv_store(result, "alarms", 6, newRV_noinc((SV *)alarms_av), 0);

    etcdserverpb__alarm_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}

/* Process DefragmentResponse */
void process_defragment_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "defragment");

    Etcdserverpb__DefragmentResponse *resp;
    UNPACK_RESPONSE(pc, resp, etcdserverpb__defragment_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);

    etcdserverpb__defragment_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}

/* Process HashKVResponse */
void process_hash_kv_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "hash_kv");

    Etcdserverpb__HashKVResponse *resp;
    UNPACK_RESPONSE(pc, resp, etcdserverpb__hash_kv_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);
    hv_store(result, "hash", 4, newSVuv(resp->hash), 0);
    hv_store(result, "compact_revision", 16, newSVi64(resp->compact_revision), 0);

    etcdserverpb__hash_kv_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}

/* Process MoveLeaderResponse */
void process_move_leader_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "move_leader");

    Etcdserverpb__MoveLeaderResponse *resp;
    UNPACK_RESPONSE(pc, resp, etcdserverpb__move_leader_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);

    etcdserverpb__move_leader_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}

/* Process AuthStatusResponse */
void process_auth_status_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "auth_status");

    Etcdserverpb__AuthStatusResponse *resp;
    UNPACK_RESPONSE(pc, resp, etcdserverpb__auth_status_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);
    hv_store(result, "enabled", 7, newSViv(resp->enabled ? 1 : 0), 0);
    hv_store(result, "auth_revision", 13, newSVu64(resp->authrevision), 0);

    etcdserverpb__auth_status_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}
