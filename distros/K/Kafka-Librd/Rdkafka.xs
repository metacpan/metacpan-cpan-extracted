/* vim: set expandtab sts=4: */
#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "ppport.h"
#include "rdkafkaxs.h"

MODULE = Kafka::Librd    PACKAGE = Kafka::Librd    PREFIX = krd_
PROTOTYPES: DISABLE

INCLUDE: const_xs.inc

int
krd_rd_kafka_version()
    CODE:
        RETVAL = rd_kafka_version();
    OUTPUT:
        RETVAL

const char*
krd_rd_kafka_version_str()
    CODE:
        RETVAL = rd_kafka_version_str();
    OUTPUT:
        RETVAL

rdkafka_t*
krd__new(type, params)
        int type
        HV* params
    PREINIT:
        rd_kafka_conf_t* conf;
        rd_kafka_t* rk;
        char errstr[1024];
    CODE:
        Newx(RETVAL, 1, rdkafka_t);
        conf = krd_parse_config(aTHX_ RETVAL, params);
        rk = rd_kafka_new(type, conf, errstr, 1024);
        if (rk == NULL) {
            croak("%s", errstr);
        }
        RETVAL->rk = rk;
        RETVAL->thx = (IV)PERL_GET_THX;
    OUTPUT:
        RETVAL

int
krd_brokers_add(rdk, brokerlist)
        rdkafka_t* rdk
        char* brokerlist
    CODE:
        RETVAL = rd_kafka_brokers_add(rdk->rk, brokerlist);
    OUTPUT:
        RETVAL

int
krd_subscribe(rdk, topics)
        rdkafka_t* rdk
        AV* topics
    PREINIT:
        STRLEN strl;
        int i, len;
        rd_kafka_topic_partition_list_t* topic_list;
        char* topic;
        SV** topic_sv;
    CODE:
        len = av_len(topics) + 1;
        topic_list = rd_kafka_topic_partition_list_new(len);
        for (i=0; i < len; i++) {
            topic_sv = av_fetch(topics, i, 0);
            if (topic_sv != NULL) {
                topic = SvPV(*topic_sv, strl);
                rd_kafka_topic_partition_list_add(topic_list, topic, -1);
            }
        }
        RETVAL = rd_kafka_subscribe(rdk->rk, topic_list);
        rd_kafka_topic_partition_list_destroy(topic_list);
    OUTPUT:
        RETVAL

int
krd_unsubscribe(rdk)
        rdkafka_t* rdk
    CODE:
        RETVAL = rd_kafka_unsubscribe(rdk->rk);
    OUTPUT:
        RETVAL

SV*
krd_subscription(rdk)
        rdkafka_t* rdk
    PREINIT:
        rd_kafka_topic_partition_list_t* tpar;
        rd_kafka_resp_err_t err;
        AV* tp;
    CODE:
        err = rd_kafka_subscription(rdk->rk, &tpar);
        if (err != RD_KAFKA_RESP_ERR_NO_ERROR) {
            croak("Error retrieving subscriptions: %s", rd_kafka_err2str(err));
        }
        tp = krd_expand_topic_partition_list(aTHX_ tpar);
        rd_kafka_topic_partition_list_destroy(tpar);
        RETVAL = newRV_noinc((SV*)tp);
    OUTPUT:
        RETVAL

int
krd_assign(rdk, tplistsv = NULL)
        rdkafka_t* rdk
        SV* tplistsv
    PREINIT:
        AV* tplist;
        rd_kafka_topic_partition_list_t* tpar = NULL;
    CODE:
        if (tplistsv != NULL && SvOK(tplistsv)) {
            if (!SvROK(tplistsv) || strncmp(sv_reftype(SvRV(tplistsv), 0), "ARRAY", 6)) {
                croak("first argument must be an array reference");
            }
            tplist = (AV*)SvRV(tplistsv);
            tpar = krd_parse_topic_partition_list(aTHX_ tplist);
        }
        RETVAL = rd_kafka_assign(rdk->rk, tpar);
        if (tpar != NULL)
            rd_kafka_topic_partition_list_destroy(tpar);
    OUTPUT:
        RETVAL

SV*
krd_assignment(rdk)
        rdkafka_t *rdk
    PREINIT:
        rd_kafka_topic_partition_list_t* tpar;
        rd_kafka_resp_err_t err;
        AV* tp;
    CODE:
        err = rd_kafka_assignment(rdk->rk, &tpar);
        if (err != RD_KAFKA_RESP_ERR_NO_ERROR) {
            croak("Error retrieving assignments: %s", rd_kafka_err2str(err));
        }
        tp = krd_expand_topic_partition_list(aTHX_ tpar);
        rd_kafka_topic_partition_list_destroy(tpar);
        RETVAL = newRV_noinc((SV*)tp);
    OUTPUT:
        RETVAL

int
krd_commit(rdk, tplistsv = NULL, async = 0)
        rdkafka_t* rdk
        SV* tplistsv
        int async
    PREINIT:
        AV* tplist;
        rd_kafka_topic_partition_list_t* tpar = NULL;
    CODE:
        if (tplistsv != NULL && SvOK(tplistsv)) {
            if(!SvROK(tplistsv) || strncmp(sv_reftype(SvRV(tplistsv), 0), "ARRAY", 6)) {
            croak("first argument must be an array reference");
            }
            tplist = (AV*)SvRV(tplistsv);
            tpar = krd_parse_topic_partition_list(aTHX_ tplist);
        }
        RETVAL = rd_kafka_commit(rdk->rk, tpar, async);
        if (tpar != NULL)
            rd_kafka_topic_partition_list_destroy(tpar);
    OUTPUT:
        RETVAL

int
krd_commit_message(rdk, msg, async = 0)
        rdkafka_t* rdk
        rd_kafka_message_t* msg
        int async
    CODE:
        RETVAL = rd_kafka_commit_message(rdk->rk, msg, async);
    OUTPUT:
        RETVAL

SV*
krd_committed(rdk, tplistsv, timeout_ms)
        rdkafka_t* rdk
        SV* tplistsv
        int timeout_ms
    PREINIT:
        AV* tplist;
        rd_kafka_topic_partition_list_t* tpar = NULL;
        rd_kafka_resp_err_t err;
        AV* tp;
    CODE:
        if (!SvROK(tplistsv) || strncmp(sv_reftype(SvRV(tplistsv), 0), "ARRAY", 6)) {
            croak("first argument must be an array reference");
        }
        tplist = (AV*)SvRV(tplistsv);
        tpar = krd_parse_topic_partition_list(aTHX_ tplist);
        err = rd_kafka_committed(rdk->rk, tpar, timeout_ms);
        if (err != RD_KAFKA_RESP_ERR_NO_ERROR) {
            rd_kafka_topic_partition_list_destroy(tpar);
            croak("Error retrieving commited offsets: %s", rd_kafka_err2str(err));
        }
        tp = krd_expand_topic_partition_list(aTHX_ tpar);
        rd_kafka_topic_partition_list_destroy(tpar);
        RETVAL = newRV_noinc((SV*)tp);
    OUTPUT:
        RETVAL

SV*
krd_position(rdk, tplistsv)
        rdkafka_t* rdk
        SV* tplistsv
    PREINIT:
        AV* tplist;
        rd_kafka_topic_partition_list_t* tpar = NULL;
        rd_kafka_resp_err_t err;
        AV* tp;
    CODE:
        if (!SvROK(tplistsv) || strncmp(sv_reftype(SvRV(tplistsv), 0), "ARRAY", 6)) {
            croak("first argument must be an array reference");
        }
        tplist = (AV*)SvRV(tplistsv);
        tpar = krd_parse_topic_partition_list(aTHX_ tplist);
        err = rd_kafka_position(rdk->rk, tpar);
        if (err != RD_KAFKA_RESP_ERR_NO_ERROR) {
            rd_kafka_topic_partition_list_destroy(tpar);
            croak("Error retrieving positions: %s", rd_kafka_err2str(err));
        }
        tp = krd_expand_topic_partition_list(aTHX_ tpar);
        rd_kafka_topic_partition_list_destroy(tpar);
        RETVAL = newRV_noinc((SV*)tp);
    OUTPUT:
        RETVAL

rd_kafka_message_t*
krd_consumer_poll(rdk, timeout_ms)
        rdkafka_t* rdk
        int timeout_ms
    CODE:
        RETVAL = rd_kafka_consumer_poll(rdk->rk, timeout_ms);
    OUTPUT:
        RETVAL

int
krd_consumer_close(rdk)
        rdkafka_t* rdk
    CODE:
        RETVAL = rd_kafka_consumer_close(rdk->rk);
    OUTPUT:
        RETVAL

rd_kafka_topic_t*
krd_topic(rdk, topic, params)
        rdkafka_t* rdk
        char *topic
        HV* params
    PREINIT:
        rd_kafka_topic_conf_t* tcon;
        char errstr[1024];
    CODE:
        tcon = krd_parse_topic_config(aTHX_ params, errstr);
        if (tcon == NULL)
            croak("Couldn't parse topic config: %s", errstr);
        RETVAL = rd_kafka_topic_new(rdk->rk, topic, tcon);
        tcon = NULL;
    OUTPUT:
        RETVAL

int
krd_poll(rdk, timeout_ms)
        rdkafka_t* rdk
        int timeout_ms
    CODE:
        RETVAL = rd_kafka_poll(rdk->rk, timeout_ms);
    OUTPUT:
        RETVAL

int
krd_outq_len(rdk)
        rdkafka_t* rdk
    CODE:
        RETVAL = rd_kafka_outq_len(rdk->rk);
    OUTPUT:
        RETVAL

void
krd_DESTROY(rdk)
        rdkafka_t* rdk
    CODE:
        if (rdk->thx == (IV)PERL_GET_THX) {
            Safefree(rdk);
        }

void
krd_destroy(rdk)
        rdkafka_t* rdk
    CODE:
        rd_kafka_destroy(rdk->rk);

void
krd_dump(rdk)
        rdkafka_t* rdk
    CODE:
        rd_kafka_dump(stdout, rdk->rk);

int
krd_rd_kafka_wait_destroyed(timeout_ms)
        int timeout_ms
    CODE:
        RETVAL = rd_kafka_wait_destroyed(timeout_ms);
    OUTPUT:
        RETVAL

MODULE = Kafka::Librd    PACKAGE = Kafka::Librd::Topic    PREFIX = krdt_
PROTOTYPES: DISABLE

int
krdt_produce(rkt, partition, msgflags, payload, key)
        rd_kafka_topic_t* rkt
        int partition
        int msgflags
        SV* payload
        SV* key
    PREINIT:
        STRLEN plen, klen;
        char *plptr, *keyptr;
    CODE:
        plptr = SvPVbyte(payload, plen);
        if (SvOK(key)) {
            keyptr = SvPVbyte(key, klen);
        } else {
            keyptr = NULL;
            klen = 0;
        }
        RETVAL = rd_kafka_produce(rkt, partition, RD_KAFKA_MSG_F_COPY | msgflags, plptr, plen, keyptr, klen, NULL);
    OUTPUT:
        RETVAL

void
krdt_DESTROY(rkt)
        rd_kafka_topic_t* rkt
    CODE:
        rd_kafka_topic_destroy(rkt);

MODULE = Kafka::Librd    PACKAGE = Kafka::Librd::Message    PREFIX = krdm_
PROTOTYPES: DISABLE

int
krdm_err(msg)
        rd_kafka_message_t* msg
    CODE:
        RETVAL = msg->err;
    OUTPUT:
        RETVAL

int
krdm_partition(msg)
        rd_kafka_message_t* msg
    CODE:
        RETVAL = msg->partition;
    OUTPUT:
        RETVAL

const char*
krdm_topic(msg)
        rd_kafka_message_t* msg
    CODE:
        RETVAL = rd_kafka_topic_name(msg->rkt);
    OUTPUT:
        RETVAL

SV*
krdm_payload(msg)
        rd_kafka_message_t* msg
    CODE:
        RETVAL = newSVpvn(msg->payload, msg->len);
    OUTPUT:
        RETVAL

SV*
krdm_key(msg)
        rd_kafka_message_t* msg
    CODE:
        if (msg->err == 0) {
            RETVAL = newSVpvn(msg->key, msg->key_len);
        } else {
            RETVAL = &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

long
krdm_offset(msg)
        rd_kafka_message_t* msg
    CODE:
        /* that will truncate offset if perl doesn't support 64bit ints */
        RETVAL = msg->offset;
    OUTPUT:
        RETVAL

long
krdm_timestamp(msg,...)
        rd_kafka_message_t* msg
    CODE:
	rd_kafka_timestamp_type_t tstype;
        RETVAL = rd_kafka_message_timestamp(msg, &tstype);
	if (items > 1) {
	    if (!SvROK(ST(1)) || strncmp(sv_reftype(SvRV(ST(1)), 0), "SCALAR", 7)) {
		croak("second argument tstype must be a scalar reference");
	    }
	    sv_setiv(SvRV(ST(1)), tstype);
	}
    OUTPUT:
	RETVAL

void
krdm_DESTROY(msg)
        rd_kafka_message_t* msg
    CODE:
        rd_kafka_message_destroy(msg);

MODULE = Kafka::Librd    PACKAGE = Kafka::Librd::Error    PREFIX = krde_
PROTOTYPES: DISABLE

HV*
krde_rd_kafka_get_err_descs()
    PREINIT:
        const struct rd_kafka_err_desc* descs;
        size_t cnt;
        int i;
    CODE:
        rd_kafka_get_err_descs(&descs, &cnt);
        RETVAL = newHV();
        for (i = 0; i < cnt; i++) {
            if (descs[i].name != NULL) {
                hv_store(RETVAL, descs[i].name, strnlen(descs[i].name, 1024), newSViv(descs[i].code), 0);
            }
        }
    OUTPUT:
        RETVAL

const char*
krde_to_string(code)
        int code
    CODE:
        RETVAL = rd_kafka_err2str(code);
    OUTPUT:
        RETVAL

const char*
krde_to_name(code)
        int code
    CODE:
        RETVAL = rd_kafka_err2name(code);
    OUTPUT:
        RETVAL
