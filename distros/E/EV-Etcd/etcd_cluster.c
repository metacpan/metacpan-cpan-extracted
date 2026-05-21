/*
 * etcd_cluster.c - Cluster operation handlers for EV::Etcd
 */
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "etcd_common.h"
#include "etcd_cluster.h"

/* Helper to convert Member to hash */
HV *member_to_hv(pTHX_ Etcdserverpb__Member *member) {
    if (!member) return NULL;

    HV *hv = newHV();
    hv_store(hv, "id", 2, newSVu64(member->id), 0);
    if (member->name) {
        hv_store(hv, "name", 4, newSVpv(member->name, 0), 0);
    }
    hv_store(hv, "is_learner", 10, newSViv(member->is_learner ? 1 : 0), 0);

    /* peerURLs */
    AV *peer_urls = newAV();
    if (member->n_peer_urls > 0) {
        av_extend(peer_urls, member->n_peer_urls - 1);
        for (size_t i = 0; i < member->n_peer_urls; i++) {
            /* Handle NULL string in repeated field */
            av_push(peer_urls, member->peer_urls[i] ? newSVpv(member->peer_urls[i], 0) : newSVpvn("", 0));
        }
    }
    hv_store(hv, "peer_urls", 9, newRV_noinc((SV *)peer_urls), 0);

    /* clientURLs */
    AV *client_urls = newAV();
    if (member->n_client_urls > 0) {
        av_extend(client_urls, member->n_client_urls - 1);
        for (size_t i = 0; i < member->n_client_urls; i++) {
            /* Handle NULL string in repeated field */
            av_push(client_urls, member->client_urls[i] ? newSVpv(member->client_urls[i], 0) : newSVpvn("", 0));
        }
    }
    hv_store(hv, "client_urls", 11, newRV_noinc((SV *)client_urls), 0);

    return hv;
}

/* Helper to add members array to result */
static void add_members_to_hv(pTHX_ HV *result, Etcdserverpb__Member **members, size_t n_members) {
    AV *members_av = newAV();
    if (n_members > 0) {
        av_extend(members_av, n_members - 1);
        for (size_t i = 0; i < n_members; i++) {
            HV *member_hv = member_to_hv(aTHX_ members[i]);
            if (member_hv) {
                av_push(members_av, newRV_noinc((SV *)member_hv));
            }
        }
    }
    hv_store(result, "members", 7, newRV_noinc((SV *)members_av), 0);
}

/* Process MemberAddResponse */
void process_member_add_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "member_add");

    Etcdserverpb__MemberAddResponse *resp;
    UNPACK_RESPONSE(pc, resp, etcdserverpb__member_add_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);

    if (resp->member) {
        HV *member_hv = member_to_hv(aTHX_ resp->member);
        if (member_hv) {
            hv_store(result, "member", 6, newRV_noinc((SV *)member_hv), 0);
        }
    }

    add_members_to_hv(aTHX_ result, resp->members, resp->n_members);

    etcdserverpb__member_add_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}

/* Process MemberRemoveResponse */
void process_member_remove_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "member_remove");

    Etcdserverpb__MemberRemoveResponse *resp;
    UNPACK_RESPONSE(pc, resp, etcdserverpb__member_remove_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);
    add_members_to_hv(aTHX_ result, resp->members, resp->n_members);

    etcdserverpb__member_remove_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}

/* Process MemberUpdateResponse */
void process_member_update_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "member_update");

    Etcdserverpb__MemberUpdateResponse *resp;
    UNPACK_RESPONSE(pc, resp, etcdserverpb__member_update_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);
    add_members_to_hv(aTHX_ result, resp->members, resp->n_members);

    etcdserverpb__member_update_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}

/* Process MemberListResponse */
void process_member_list_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "member_list");

    Etcdserverpb__MemberListResponse *resp;
    UNPACK_RESPONSE(pc, resp, etcdserverpb__member_list_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);
    add_members_to_hv(aTHX_ result, resp->members, resp->n_members);

    etcdserverpb__member_list_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}

/* Process MemberPromoteResponse */
void process_member_promote_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "member_promote");

    Etcdserverpb__MemberPromoteResponse *resp;
    UNPACK_RESPONSE(pc, resp, etcdserverpb__member_promote_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);
    add_members_to_hv(aTHX_ result, resp->members, resp->n_members);

    etcdserverpb__member_promote_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}
