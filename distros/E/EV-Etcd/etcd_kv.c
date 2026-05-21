/*
 * etcd_kv.c - KV operation response handlers for EV::Etcd
 */
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "etcd_common.h"
#include "etcd_kv.h"

/* Process RangeResponse (get) and call Perl callback */
void process_range_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "range");

    Etcdserverpb__RangeResponse *resp;
    UNPACK_RESPONSE(pc, resp, etcdserverpb__range_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);

    AV *kvs = newAV();
    if (resp->n_kvs > 0) {
        av_extend(kvs, resp->n_kvs - 1);
    }
    for (size_t i = 0; i < resp->n_kvs; i++) {
        av_push(kvs, kv_to_hashref(aTHX_ resp->kvs[i]));
    }
    hv_store(result, "kvs", 3, newRV_noinc((SV *)kvs), 0);
    hv_store(result, "more", 4, newSViv(resp->more), 0);
    hv_store(result, "count", 5, newSVi64(resp->count), 0);

    etcdserverpb__range_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}

/* Process PutResponse and call Perl callback */
void process_put_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "put");

    Etcdserverpb__PutResponse *resp;
    UNPACK_RESPONSE(pc, resp, etcdserverpb__put_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);

    if (resp->prev_kv) {
        hv_store(result, "prev_kv", 7, kv_to_hashref(aTHX_ resp->prev_kv), 0);
    }

    etcdserverpb__put_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}

/* Process DeleteRangeResponse and call Perl callback */
void process_delete_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "delete");

    Etcdserverpb__DeleteRangeResponse *resp;
    UNPACK_RESPONSE(pc, resp, etcdserverpb__delete_range_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);

    hv_store(result, "deleted", 7, newSVi64(resp->deleted), 0);

    if (resp->n_prev_kvs > 0) {
        AV *prev_kvs = newAV();
        av_extend(prev_kvs, resp->n_prev_kvs - 1);
        for (size_t i = 0; i < resp->n_prev_kvs; i++) {
            av_push(prev_kvs, kv_to_hashref(aTHX_ resp->prev_kvs[i]));
        }
        hv_store(result, "prev_kvs", 8, newRV_noinc((SV *)prev_kvs), 0);
    }

    etcdserverpb__delete_range_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}

/* Process CompactionResponse and call Perl callback */
void process_compact_response(pTHX_ pending_call_t *pc) {
    BEGIN_RESPONSE_HANDLER(pc, "compact");

    Etcdserverpb__CompactionResponse *resp;
    UNPACK_RESPONSE(pc, resp, etcdserverpb__compaction_response__unpack);

    HV *result = newHV();
    add_header_to_hv(aTHX_ result, resp->header);

    etcdserverpb__compaction_response__free_unpacked(resp, NULL);

    CALL_SUCCESS_CALLBACK(pc->callback, result);
}
