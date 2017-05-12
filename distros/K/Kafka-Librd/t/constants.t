use strict;
use warnings;
use Test::More;
use Kafka::Librd qw(RD_KAFKA_RESP_ERR_NO_ERROR RD_KAFKA_RESP_ERR_REQUEST_TIMED_OUT);

is RD_KAFKA_RESP_ERR_NO_ERROR, 0, "NO ERROR code is 0";
is RD_KAFKA_RESP_ERR_REQUEST_TIMED_OUT, 7, "REQUEST TIMED OUT code is 7";
is Kafka::Librd::RD_KAFKA_RESP_ERR__NOT_IMPLEMENTED(), -170, "constants accessible w/o import";

done_testing;
