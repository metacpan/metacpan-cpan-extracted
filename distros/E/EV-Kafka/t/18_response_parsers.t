use strict;
use warnings;
use Test::More;
use EV::Kafka;

# These goldens are hand-built per the Kafka protocol spec rather than
# captured against a real broker — that way the test has no external
# dependency. Lengths are big-endian INT32; strings are length-prefixed
# with INT16. See https://kafka.apache.org/protocol.html.

plan tests => 29;

sub i32 { pack 'N',  $_[0] }
sub i16 { pack 'n',  $_[0] }
sub i64 { pack 'q>', $_[0] }
sub kstr { my $s = shift; i16(length $s) . $s }

# --- Produce response v0: throttle absent, response-time absent ---
{
    my $body =
          i32(1)               # topics array len
        . kstr('mytopic')
        . i32(1)               # partitions array len
        . i32(0)               # partition
        . i16(0)               # error_code
        . i64(42);             # base_offset
    my $r = EV::Kafka::_test_parse_response('produce', 0, $body);
    ok ref $r eq 'HASH', 'produce v0 response parses to hashref';
    is $r->{topics}[0]{topic}, 'mytopic',
        'produce v0 topic name decoded';
    is $r->{topics}[0]{partitions}[0]{base_offset}, 42,
        'produce v0 base_offset decoded';
}

# --- Metadata response v0: brokers + topics ---
{
    my $body =
          i32(1)               # brokers array len
        . i32(0)               # node_id
        . kstr('host1')
        . i32(9092)            # port
        . i32(1)               # topics array len
        . i16(0)               # topic error_code
        . kstr('mytopic')
        . i32(1)               # partitions array len
        . i16(0)               # partition error_code
        . i32(0)               # partition id
        . i32(0)               # leader id
        . i32(0)               # replicas array len
        . i32(0);              # isr array len
    my $r = EV::Kafka::_test_parse_response('metadata', 0, $body);
    ok ref $r eq 'HASH', 'metadata v0 parses';
    is scalar @{$r->{brokers}}, 1, 'one broker';
    is $r->{brokers}[0]{host}, 'host1', 'broker host decoded';
    is $r->{brokers}[0]{port}, 9092,    'broker port decoded';
    is $r->{topics}[0]{name}, 'mytopic', 'topic name decoded';
    is $r->{topics}[0]{partitions}[0]{leader}, 0, 'partition leader decoded';
}

# --- Truncated metadata response: should not crash, returns partial data ---
{
    my $body = i32(1);  # claims one broker but no broker bytes follow
    my $r = EV::Kafka::_test_parse_response('metadata', 0, $body);
    ok ref $r eq 'HASH', 'truncated metadata returns parsed-so-far hash';
    is scalar @{$r->{brokers} // []}, 0,
        'truncated metadata yields empty brokers list (parser bails on bounds check)';
}

# --- Heartbeat response v0: just throttle(?) + error_code ---
{
    my $body = i16(0);    # error_code = 0, no throttle in v0
    my $r = EV::Kafka::_test_parse_response('heartbeat', 0, $body);
    ok ref $r eq 'HASH', 'heartbeat v0 parses';
    is $r->{error_code}, 0, 'heartbeat error_code decoded';
}

# --- LeaveGroup response v0: error_code only ---
{
    my $body = i16(0);
    my $r = EV::Kafka::_test_parse_response('leave_group', 0, $body);
    ok ref $r eq 'HASH', 'leave_group v0 parses';
}

# --- EndTxn response v0: throttle_ms(i32) + error_code ---
{
    my $body = i32(0) . i16(0);
    my $r = EV::Kafka::_test_parse_response('end_txn', 0, $body);
    ok ref $r eq 'HASH', 'end_txn v0 parses';
}

# --- Find_coordinator response v0 ---
{
    my $body =
          i16(0)               # error_code
        . i32(7)               # node_id
        . kstr('coord-host')
        . i32(9092);           # port
    my $r = EV::Kafka::_test_parse_response('find_coordinator', 0, $body);
    is $r->{node_id}, 7, 'find_coordinator node_id';
    is $r->{host},    'coord-host', 'find_coordinator host';
}

# --- SyncGroup response v0: error_code + assignment(BYTES) ---
{
    my $assignment = "\x00\x01" .  # version
                     i32(0);       # zero topics
    my $body = i16(0) . i32(length $assignment) . $assignment;
    my $r = EV::Kafka::_test_parse_response('sync_group', 0, $body);
    ok ref $r eq 'HASH', 'sync_group v0 parses';
    is $r->{error_code}, 0, 'sync_group error_code decoded';
}

# --- OffsetFetch response v0: topics array with partitions ---
{
    my $body =
          i32(1)               # topics
        . kstr('mytopic')
        . i32(1)               # partitions
        . i32(0)               # partition
        . pack('q>', 100)      # offset
        . i16(-1)              # metadata len = -1 (null)
        . i16(0);              # error_code
    my $r = EV::Kafka::_test_parse_response('offset_fetch', 0, $body);
    is $r->{topics}[0]{partitions}[0]{offset}, 100,
        'offset_fetch decodes committed offset';
}

# --- JoinGroup response v0 (leader case) ---
{
    my $body =
          i16(0)               # error_code
        . i32(7)               # generation_id
        . kstr('range')        # protocol_name
        . kstr('me')           # leader
        . kstr('me')           # member_id
        . i32(1)               # members array
        . kstr('me')           # member_id
        . i32(0);              # metadata len = 0
    my $r = EV::Kafka::_test_parse_response('join_group', 0, $body);
    is $r->{generation_id}, 7,    'join_group generation_id';
    is $r->{leader},        'me', 'join_group leader';
    is $r->{member_id},     'me', 'join_group member_id';
}

# --- AddPartitionsToTxn response v0 ---
{
    my $body =
          i32(0)               # throttle_time_ms
        . i32(1)               # topics
        . kstr('mytopic')
        . i32(1)               # partitions
        . i32(0)               # partition
        . i16(0);              # error_code
    my $r = EV::Kafka::_test_parse_response('add_partitions_to_txn', 0, $body);
    ok ref $r eq 'HASH', 'add_partitions_to_txn v0 parses';
}

# --- TxnOffsetCommit response v0 ---
{
    my $body =
          i32(0)               # throttle_time_ms
        . i32(1)               # topics
        . kstr('mytopic')
        . i32(1)               # partitions
        . i32(0)               # partition
        . i16(0);              # error_code
    my $r = EV::Kafka::_test_parse_response('txn_offset_commit', 0, $body);
    ok ref $r eq 'HASH', 'txn_offset_commit v0 parses';
}

# --- CreateTopics response v0: topics array of (name, error) ---
{
    my $body =
          i32(1)               # topics
        . kstr('newtopic')
        . i16(36);             # error_code = TOPIC_ALREADY_EXISTS
    my $r = EV::Kafka::_test_parse_response('create_topics', 0, $body);
    ok ref $r eq 'HASH', 'create_topics v0 parses';
}

# --- DeleteTopics response v0 ---
{
    my $body =
          i32(1)               # topics
        . kstr('oldtopic')
        . i16(0);              # error_code = NONE
    my $r = EV::Kafka::_test_parse_response('delete_topics', 0, $body);
    ok ref $r eq 'HASH', 'delete_topics v0 parses';
}

# --- InitProducerId response v1: throttle prefix is added at v1+ ---
{
    my $body =
          i32(0)               # throttle_time_ms (v1+)
        . i16(0)               # error_code
        . pack('q>', 12345)    # producer_id
        . i16(0);              # producer_epoch
    my $r = EV::Kafka::_test_parse_response('init_producer_id', 1, $body);
    is $r->{producer_id},    12345, 'init_producer_id pid decoded';
    is $r->{producer_epoch}, 0,     'init_producer_id epoch decoded';
}
