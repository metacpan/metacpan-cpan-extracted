#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "etcd_common.h"
#include "etcd_lock.h"

void process_lock_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "lock");

    V3lockpb__LockResponse *resp;
    UNPACK_RESPONSE(pc, resp, v3lockpb__lock_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);
    hv_store(result, "key", 3,
             resp->key.data ? newSVpvn((const char *)resp->key.data, resp->key.len) : newSVpvn("", 0), 0);

    v3lockpb__lock_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}

void process_unlock_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "unlock");

    V3lockpb__UnlockResponse *resp;
    UNPACK_RESPONSE(pc, resp, v3lockpb__unlock_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);

    v3lockpb__unlock_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}
