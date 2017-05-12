#define PERL_NO_GET_CONTEXT
#include <librdkafka/rdkafka.h>
#include <EXTERN.h>
#include <perl.h>

typedef struct rdkafka_s {
    rd_kafka_t* rk;
    IV thx;
} rdkafka_t;

rd_kafka_topic_partition_list_t* krd_parse_topic_partition_list(pTHX_ AV* tplist);
AV* krd_expand_topic_partition_list(pTHX_ rd_kafka_topic_partition_list_t* tpar);
rd_kafka_conf_t* krd_parse_config(pTHX_ rdkafka_t* krd, HV* params);
rd_kafka_topic_conf_t* krd_parse_topic_config(pTHX_ HV *params, char* errstr);
