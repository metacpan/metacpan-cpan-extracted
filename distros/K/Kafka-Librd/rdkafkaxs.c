#include "rdkafkaxs.h"
#include "ppport.h"

#define ERRSTR_SIZE 1024

rd_kafka_topic_partition_list_t*
krd_parse_topic_partition_list(pTHX_ AV* tplist) {
    char errstr[ERRSTR_SIZE];
    rd_kafka_topic_partition_list_t* tpar;

    int tplen = av_len(tplist)+1;
    tpar = rd_kafka_topic_partition_list_new(tplen);
    int i;
    for (i=0; i<tplen; i++) {
        SV** elemr = av_fetch(tplist, i, 0);
        if (elemr == NULL)
            continue;
        SV* conf = *elemr;
        if (!SvROK(conf) || strncmp(sv_reftype(SvRV(conf), 0), "HASH", 5) != 0) {
            strncpy(errstr, "elements of topic partition list expected to be hashes", ERRSTR_SIZE);
            goto CROAK;
        }
        HV* confhv = (HV*)SvRV(conf);
        SV** topicsv = hv_fetch(confhv, "topic", 5, 0);
        if (topicsv == NULL) {
            snprintf(errstr, ERRSTR_SIZE, "topic is not specified for element %d of the list", i);
            goto CROAK;
        }
        STRLEN len;
        char* topic = SvPV(*topicsv, len);
        SV** partitionsv = hv_fetch(confhv, "partition", 9, 0);
        if (partitionsv == NULL) {
            snprintf(errstr, ERRSTR_SIZE, "partition is not specified for element %d of the list", i);
            goto CROAK;
        }
        int32_t partition = SvIV(*partitionsv);
        rd_kafka_topic_partition_t* tp = rd_kafka_topic_partition_list_add(tpar, topic, partition);
        hv_iterinit(confhv);
        HE* he;
        while ((he = hv_iternext(confhv)) != NULL) {
            char* key = HePV(he, len);
            SV* val = HeVAL(he);
            if (strncmp(key, "topic", 6) == 0 || strncmp(key, "partition", 10) == 0) {
                /* this we already handled */
                ;
            } else if (strncmp(key, "offset", 7) == 0) {
                tp->offset = SvIV(val);
            } else if (strncmp(key, "metadata", 9) == 0) {
                tp->metadata = SvPV(val, len);
                tp->metadata_size = len;
            } else {
                snprintf(errstr, ERRSTR_SIZE, "unknown option %s for element %d of the list", key, i);
                goto CROAK;
            }
        }
    }
    return tpar;

CROAK:
    rd_kafka_topic_partition_list_destroy(tpar);
    croak("%s", errstr);
    return NULL;
}

AV* krd_expand_topic_partition_list(pTHX_ rd_kafka_topic_partition_list_t* tpar) {
    AV* tplist = newAV();
    int i;
    for (i = 0; i < tpar->cnt; i++) {
        rd_kafka_topic_partition_t* elem = &(tpar->elems[i]);
        HV* tp = newHV();
        hv_stores(tp, "topic", newSVpv(elem->topic, 0));
        hv_stores(tp, "partition", newSViv(elem->partition));
        hv_stores(tp, "offset", newSViv(elem->offset));
        if(elem->metadata_size > 0) {
            hv_stores(tp, "metadata", newSVpvn(elem->metadata, elem->metadata_size));
        }
        av_push(tplist, newRV_noinc((SV*)tp));
    }
    return tplist;
}

rd_kafka_conf_t* krd_parse_config(pTHX_ rdkafka_t *krd, HV* params) {
    char errstr[ERRSTR_SIZE];
    rd_kafka_conf_t* krdconf;
    rd_kafka_conf_res_t res;
    HE *he;

    krdconf = rd_kafka_conf_new();
    rd_kafka_conf_set_opaque(krdconf, (void *)krd);
    hv_iterinit(params);
    while ((he = hv_iternext(params)) != NULL) {
        STRLEN len;
        char* key = HePV(he, len);
        SV* val = HeVAL(he);
        if (strncmp(key, "default_topic_config", len) == 0) {
            if (!SvROK(val) || strncmp(sv_reftype(SvRV(val), 0), "HASH", 5) != 0) {
                strncpy(errstr, "default_topic_config must be a hash reference", ERRSTR_SIZE);
                goto CROAK;
            }
            rd_kafka_topic_conf_t* topconf = krd_parse_topic_config(aTHX_ (HV*)SvRV(val), errstr);
            if (topconf == NULL) goto CROAK;
            rd_kafka_conf_set_default_topic_conf(krdconf, topconf);
        } else {
            /* set named configuration property */
            char *strval = SvPV(val, len);
            res = rd_kafka_conf_set(
                    krdconf,
                    key,
                    strval,
                    errstr,
                    ERRSTR_SIZE);
            if (res != RD_KAFKA_CONF_OK)
                goto CROAK;
        }
    }

    return krdconf;

CROAK:
    rd_kafka_conf_destroy(krdconf);
    croak("%s", errstr);
    return NULL;
}

rd_kafka_topic_conf_t* krd_parse_topic_config(pTHX_ HV *params, char* errstr) {
    rd_kafka_topic_conf_t* topconf = rd_kafka_topic_conf_new();
    rd_kafka_conf_res_t res;
    HE *he;

    hv_iterinit(params);
    while ((he = hv_iternext(params)) != NULL) {
        STRLEN len;
        char* key = HePV(he, len);
        SV* val = HeVAL(he);
        char *strval = SvPV(val, len);
        res = rd_kafka_topic_conf_set(
                topconf,
                key,
                strval,
                errstr,
                ERRSTR_SIZE);
        if (res != RD_KAFKA_CONF_OK) {
            rd_kafka_topic_conf_destroy(topconf);
            return NULL;
        }
    }

    return topconf;
}
