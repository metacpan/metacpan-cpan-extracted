use strict;
use warnings;
use Test::More;
use EV::Kafka;

plan tests => 10;

is EV::Kafka::_error_name(0),  'NONE',                       'error 0';
is EV::Kafka::_error_name(1),  'OFFSET_OUT_OF_RANGE',        'error 1';
is EV::Kafka::_error_name(3),  'UNKNOWN_TOPIC_OR_PARTITION', 'error 3';
is EV::Kafka::_error_name(6),  'NOT_LEADER_OR_FOLLOWER',     'error 6';
is EV::Kafka::_error_name(15), 'COORDINATOR_NOT_AVAILABLE',  'error 15';
is EV::Kafka::_error_name(16), 'NOT_COORDINATOR',            'error 16';
is EV::Kafka::_error_name(27), 'REBALANCE_IN_PROGRESS',      'error 27';
is EV::Kafka::_error_name(36), 'TOPIC_ALREADY_EXISTS',        'error 36';
is EV::Kafka::_error_name(79), 'MEMBER_ID_REQUIRED',          'error 79';
is EV::Kafka::_error_name(999), 'UNKNOWN',                    'unknown code';
