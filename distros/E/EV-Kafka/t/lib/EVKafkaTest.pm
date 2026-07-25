package EVKafkaTest;
use strict;
use warnings;
use IO::Socket::INET;
use Errno qw(EAGAIN EWOULDBLOCK);
use EV;
use Test::More ();

# Shared in-process mock-broker harness for the EV::Kafka test suite.
#
# The mock speaks just enough of the Kafka protocol for the XS handshake
# (ApiVersions) plus a small set of canned/default responders. It accepts
# MULTIPLE simultaneous client connections (the cluster client opens a
# bootstrap conn plus one conn per broker node, all to the same address
# in a test), logs every request frame, and lets individual tests override
# or defer any response.
#
# Adding a new API responder must not require reshaping the module:
# extend the version advertisement in apis_body(), then either add a
# built-in _<api>_handler next to the existing ones or pass
# respond => { $api_key => \&handler } from the test.

use Exporter 'import';
our @EXPORT = qw(
    i16 i32 i64 kstr
    apis_body metadata_v1
    mock_broker ready_conn timeout_w release_held_fetch
);

sub i16 { pack 'n',  $_[0] }
sub i32 { pack 'N',  $_[0] }
sub i64 { pack 'q>', $_[0] }

# Kafka STRING: i16 length + bytes.
sub kstr { my ($s) = @_; i16(length $s) . $s }

# ApiVersions v0 response body advertising the APIs with built-in mock
# responders. The XS clamps to these maxima, fixing the wire versions the
# parsers below must produce: Produce v7, Fetch v7, ListOffsets v1,
# Metadata v1, OffsetCommit v2, OffsetFetch v1, FindCoordinator v2,
# JoinGroup v1, Heartbeat v0, LeaveGroup v0, SyncGroup v0,
# InitProducerId v1, AddPartitionsToTxn v1, EndTxn v1, TxnOffsetCommit v0.
sub apis_body {
    return i16(0)          # no error
        . i32(16)          # 16 entries
        . i16(0)  . i16(0) . i16(7)   # API_PRODUCE v0..v7
        . i16(1)  . i16(0) . i16(7)   # API_FETCH   v0..v7
        . i16(2)  . i16(0) . i16(1)   # API_LIST_OFFSETS v0..v1
        . i16(3)  . i16(0) . i16(1)   # API_METADATA v0..v1
        . i16(8)  . i16(0) . i16(2)   # API_OFFSET_COMMIT v0..v2
        . i16(9)  . i16(0) . i16(1)   # API_OFFSET_FETCH v0..v1
        . i16(10) . i16(0) . i16(2)   # API_FIND_COORDINATOR v0..v2
        . i16(11) . i16(0) . i16(1)   # API_JOIN_GROUP v0..v1
        . i16(12) . i16(0) . i16(0)   # API_HEARTBEAT v0..v0
        . i16(13) . i16(0) . i16(0)   # API_LEAVE_GROUP v0..v0
        . i16(14) . i16(0) . i16(0)   # API_SYNC_GROUP v0..v0
        . i16(18) . i16(0) . i16(0)   # API_API_VERSIONS v0..v0
        . i16(22) . i16(0) . i16(1)   # API_INIT_PRODUCER_ID v0..v1
        . i16(24) . i16(0) . i16(1)   # API_ADD_PARTITIONS_TO_TXN v0..v1
        . i16(26) . i16(0) . i16(1)   # API_END_TXN v0..v1
        . i16(28) . i16(0) . i16(0);  # API_TXN_OFFSET_COMMIT v0..v0
}

# Metadata v1 response body.
#   brokers => [[node_id, host, port], ...]  (port 0 -> $opt{port})
#   topics  => { name => nparts }
#           or { name => { nparts => n, leader => node_id,
#                          error_code => code } }
sub metadata_v1 {
    my (%opt) = @_;
    my $port    = $opt{port} // 9092;
    my $topics  = $opt{topics} // {};
    my $brokers = $opt{brokers} // [[0, '127.0.0.1', $port]];

    my $body = i32(scalar @$brokers);
    for my $b (@$brokers) {
        my ($nid, $host, $bport) = @$b;
        $bport = $port if !$bport;
        $body .= i32($nid) . kstr($host) . i32($bport) . i16(-1);  # rack: null
    }
    $body .= i32($opt{controller_id} // 0);
    $body .= i32(scalar keys %$topics);
    for my $name (sort keys %$topics) {
        my $spec = $topics->{$name};
        $spec = { nparts => $spec } unless ref $spec;
        my $err = $spec->{error_code} // 0;
        my $np  = $err ? 0 : ($spec->{nparts} // 1);
        $body .= i16($err) . kstr($name) . chr(0);   # is_internal = 0
        $body .= i32($np);
        for my $pid (0 .. $np - 1) {
            my $leader = $spec->{leader} // 0;
            $body .= i16(0) . i32($pid) . i32($leader)
                  . i32(1) . i32($leader)     # replicas: [leader]
                  . i32(1) . i32($leader);    # isr:      [leader]
        }
    }
    return $body;
}

# --- Built-in responders ------------------------------------------------

# Produce v7: echo every topic/partition with a per topic:partition
# incrementing base_offset. Annotates the logged $req with producer_id,
# producer_epoch and base_sequence from the first RecordBatch header so
# tests can assert on idempotence fields. $ctx->{produce_error} may be a
# scalar error code (all partitions) or a coderef ($topic, $pid, $ctx)
# returning a per-response error code. Stays silent for acks == 0.
sub _produce_handler {
    my ($req, $send, $conn, $ctx) = @_;
    my $b   = $req->{body};
    my $pos = 0;
    if ($req->{version} >= 3) {                     # transactional_id
        my $l = unpack 'n', substr($b, $pos, 2); $pos += 2;
        $pos += $l if $l != 0xFFFF;
    }
    my $acks = unpack 'n', substr($b, $pos, 2);
    $pos += 2 + 4;                                  # acks, timeout_ms
    my $nt = unpack 'N', substr($b, $pos, 4); $pos += 4;
    my @topics;
    for (1 .. $nt) {
        my $tl = unpack 'n', substr($b, $pos, 2); $pos += 2;
        my $name = substr($b, $pos, $tl); $pos += $tl;
        my $np = unpack 'N', substr($b, $pos, 4); $pos += 4;
        my @parts;
        for (1 .. $np) {
            my $pid  = unpack 'N', substr($b, $pos, 4); $pos += 4;
            my $rlen = unpack 'N', substr($b, $pos, 4); $pos += 4;
            # RecordBatch v2 header: base_offset i64, batch_length i32,
            # leader_epoch i32, magic i8, crc i32, attributes i16,
            # last_offset_delta i32, first_ts i64, max_ts i64,
            # producer_id i64, producer_epoch i16, base_sequence i32
            if ($rlen >= 65 && !defined $req->{producer_id}) {
                my $rb = substr($b, $pos, $rlen);
                $req->{producer_id}    = unpack 'q>', substr($rb, 43, 8);
                $req->{producer_epoch} = unpack 'n',  substr($rb, 51, 2);
                $req->{base_sequence}  = unpack 'N',  substr($rb, 53, 4);
            }
            $pos += $rlen;
            push @parts, $pid;
        }
        push @topics, [$name, \@parts];
    }
    return undef if $acks == 0;
    my $perr = $ctx->{produce_error};
    my $resp = i32(scalar @topics);
    for my $t (@topics) {
        $resp .= kstr($t->[0]) . i32(scalar @{ $t->[1] });
        for my $pid (@{ $t->[1] }) {
            my $ec = !defined $perr ? 0
                : ref $perr eq 'CODE' ? $perr->($t->[0], $pid, $ctx)
                : $perr;
            my $off = $ec == 0 ? $ctx->{offsets}{"$t->[0]:$pid"}++
                             : ($ctx->{offsets}{"$t->[0]:$pid"} // 0);
            $resp .= i32($pid) . i16($ec) . i64($off)
                  .  i64(-1)                         # log_append_time
                  .  i64(0);                         # log_start_offset
        }
    }
    $resp .= i32(0);                                 # throttle_time_ms
    return $resp;
}

# Fetch v7: echo every topic/partition with the mock's per-partition
# high watermark. $ctx->{fetch_error} may be a scalar error code (all
# partitions) or a coderef ($topic, $pid, $fetch_offset, $ctx) returning
# one; error partitions carry an empty record set.
# $ctx->{fetch_records}{"topic:pid"} is an arrayref of record hashrefs:
# when a fetch asks for the mock's current offset counter, the records
# are served as a real RecordBatch (built via the XS test encoder, with
# base_offset patched in) and the counter advances — each record is
# served exactly once. $ctx->{hold_fetch} defers the response instead:
# the request is stashed in $ctx->{held_fetch} for release_held_fetch().
sub _fetch_handler {
    my ($req, $send, $conn, $ctx) = @_;
    if ($ctx->{hold_fetch}) {
        push @{$ctx->{held_fetch}}, [$req, $send, $conn];
        return undef;
    }
    my $b   = $req->{body};
    my $v   = $req->{version};
    my $pos = 12;                # replica_id, max_wait_ms, min_bytes
    $pos += 4 if $v >= 3;        # max_bytes
    $pos += 1 if $v >= 4;        # isolation_level
    $pos += 8 if $v >= 7;        # session_id, session_epoch
    my $nt = unpack 'N', substr($b, $pos, 4); $pos += 4;
    my @topics;
    for (1 .. $nt) {
        my $tl = unpack 'n', substr($b, $pos, 2); $pos += 2;
        my $name = substr($b, $pos, $tl); $pos += $tl;
        my $np = unpack 'N', substr($b, $pos, 4); $pos += 4;
        my @parts;
        for (1 .. $np) {
            my $pid  = unpack 'N',  substr($b, $pos, 4); $pos += 4;
            my $foff = unpack 'q>', substr($b, $pos, 8); $pos += 8;
            $pos += 8 if $v >= 5;                    # log_start_offset
            $pos += 4;                               # partition_max_bytes
            $req->{fetch_offsets}{"$name:$pid"} = $foff;
            push @parts, [$pid, $foff];
        }
        push @topics, [$name, \@parts];
    }
    my $ferr = $ctx->{fetch_error};
    my $resp = i32(0);                               # throttle_time_ms
    $resp .= i16(0) . i32(0) if $v >= 7;             # error_code, session_id
    $resp .= i32(scalar @topics);
    for my $t (@topics) {
        $resp .= kstr($t->[0]) . i32(scalar @{ $t->[1] });
        for my $p (@{ $t->[1] }) {
            my ($pid, $foff) = @$p;
            my $key = "$t->[0]:$pid";
            my $ec = !defined $ferr ? 0
                : ref $ferr eq 'CODE' ? $ferr->($t->[0], $pid, $foff, $ctx)
                : $ferr;
            my $record_set = '';
            my $recs = $ec == 0 ? $ctx->{fetch_records}{$key} : undef;
            if ($recs && @$recs && $foff == ($ctx->{offsets}{$key} // 0)) {
                $record_set = EV::Kafka::_test_encode_batch($recs);
                substr($record_set, 0, 8) = i64($foff);   # base_offset
                $ctx->{offsets}{$key} += scalar @$recs;
            }
            my $hw = $ctx->{offsets}{$key} // 0;
            $resp .= i32($pid) . i16($ec) . i64($hw);
            $resp .= i64($hw) if $v >= 4;            # last_stable_offset
            $resp .= i64(0)  if $v >= 5;             # log_start_offset
            $resp .= i32(-1) if $v >= 4;             # aborted_txns: null
            $resp .= i32(length $record_set) . $record_set;
        }
    }
    return $resp;
}

# Answer Fetch requests stashed via $ctx->{hold_fetch}. With $n, only the
# oldest $n held requests are released (the rest stay held). Returns the
# number released.
sub release_held_fetch {
    my ($ctx, $n) = @_;
    my $held = $ctx->{held_fetch} or return 0;
    my $count = 0;
    while (@$held && (!defined $n || $count < $n)) {
        my ($req, $send, $conn) = @{shift @$held};
        my $body = do { local $ctx->{hold_fetch} = 0;
                        _fetch_handler($req, $send, $conn, $ctx) };
        $send->($req->{corr}, $body) if defined $body;
        $count++;
    }
    return $count;
}

sub _metadata_handler {
    my ($req, $send, $conn, $ctx) = @_;
    return metadata_v1(
        port    => $ctx->{port},
        brokers => $ctx->{brokers},
        topics  => $ctx->{topics},
    );
}

# FindCoordinator v2: answer with the mock itself as coordinator (node 0).
# Annotates $req->{key_type} (0=group, 1=transaction).
# $ctx->{coordinator_error} may be a scalar error code override.
sub _find_coordinator_handler {
    my ($req, $send, $conn, $ctx) = @_;
    my $b   = $req->{body};
    my $klen = unpack 'n', substr($b, 0, 2);
    $req->{key} = substr($b, 2, $klen);
    $req->{key_type} = $req->{version} >= 1
        ? unpack('c', substr($b, 2 + $klen, 1)) : 0;
    my $ec = $ctx->{coordinator_error} // 0;
    return i32(0)                                # throttle_time_ms
        . i16($ec)
        . i16(-1)                                # error_message: null
        . i32(0)                                 # node_id
        . kstr('127.0.0.1')
        . i32($ctx->{port});
}

# InitProducerId v1: hand out increasing producer_ids, epoch 0.
# $ctx->{init_producer_error} may be a scalar error code override.
sub _init_producer_id_handler {
    my ($req, $send, $conn, $ctx) = @_;
    my $ec = $ctx->{init_producer_error} // 0;
    my $pid = $ec ? -1 : ($ctx->{_next_producer_id} //= 1000)++;
    return i32(0)                                # throttle_time_ms
        . i16($ec)
        . i64($pid)
        . i16(0);                                # producer_epoch
}

# AddPartitionsToTxn v1: echo the request's topics/partitions with error 0.
sub _add_partitions_to_txn_handler {
    my ($req, $send, $conn, $ctx) = @_;
    my $b   = $req->{body};
    my $pos = 0;
    my $tl  = unpack 'n', substr($b, $pos, 2); $pos += 2 + $tl;  # txn_id
    $pos += 8 + 2;                                     # producer_id, epoch
    my $nt  = unpack 'N', substr($b, $pos, 4); $pos += 4;
    my $resp = i32(0) . i32($nt);                      # throttle, topic count
    for (1 .. $nt) {
        my $l = unpack 'n', substr($b, $pos, 2); $pos += 2;
        my $name = substr($b, $pos, $l); $pos += $l;
        my $np = unpack 'N', substr($b, $pos, 4); $pos += 4;
        $resp .= kstr($name) . i32($np);
        for (1 .. $np) {
            my $pid = unpack 'N', substr($b, $pos, 4); $pos += 4;
            $resp .= i32($pid) . i16(0);
        }
    }
    return $resp;
}

# EndTxn v1: record the committed flag, answer error 0.
sub _end_txn_handler {
    my ($req, $send, $conn, $ctx) = @_;
    my $b   = $req->{body};
    my $tl  = unpack 'n', substr($b, 0, 2);
    $ctx->{end_txn_last_committed} =
        unpack('c', substr($b, 2 + $tl + 8 + 2, 1));
    return i32(0) . i16(0);                            # throttle, error
}

# ListOffsets v1: -2 (earliest) resolves to 0, -1 (latest) to the mock's
# per-partition high watermark; anything else also yields the watermark.
sub _list_offsets_handler {
    my ($req, $send, $conn, $ctx) = @_;
    my $b   = $req->{body};
    my $pos = 4;                                     # replica_id
    my $nt = unpack 'N', substr($b, $pos, 4); $pos += 4;
    my @topics;
    for (1 .. $nt) {
        my $tl = unpack 'n', substr($b, $pos, 2); $pos += 2;
        my $name = substr($b, $pos, $tl); $pos += $tl;
        my $np = unpack 'N', substr($b, $pos, 4); $pos += 4;
        my @parts;
        for (1 .. $np) {
            my $pid = unpack 'N',  substr($b, $pos, 4); $pos += 4;
            my $ts  = unpack 'q>', substr($b, $pos, 8); $pos += 8;
            push @parts, [$pid, $ts];
        }
        push @topics, [$name, \@parts];
    }
    my $resp = i32(scalar @topics);
    for my $t (@topics) {
        $resp .= kstr($t->[0]) . i32(scalar @{ $t->[1] });
        for my $p (@{ $t->[1] }) {
            my ($pid, $ts) = @$p;
            my $off = $ts == -2 ? 0 : ($ctx->{offsets}{"$t->[0]:$pid"} // 0);
            $resp .= i32($pid) . i16(0) . i64(-1) . i64($off);
        }
    }
    return $resp;
}

# OffsetFetch v1: committed offsets from $ctx->{committed}{"topic:pid"},
# default -1 (nothing committed).
sub _offset_fetch_handler {
    my ($req, $send, $conn, $ctx) = @_;
    my $b   = $req->{body};
    my $pos = 0;
    my $gl  = unpack 'n', substr($b, $pos, 2); $pos += 2 + $gl;  # group_id
    my $nt  = unpack 'N', substr($b, $pos, 4); $pos += 4;
    my @topics;
    for (1 .. $nt) {
        my $tl = unpack 'n', substr($b, $pos, 2); $pos += 2;
        my $name = substr($b, $pos, $tl); $pos += $tl;
        my $np = unpack 'N', substr($b, $pos, 4); $pos += 4;
        my @pids;
        for (1 .. $np) {
            push @pids, unpack 'N', substr($b, $pos, 4); $pos += 4;
        }
        push @topics, [$name, \@pids];
    }
    my $resp = i32(scalar @topics);
    for my $t (@topics) {
        $resp .= kstr($t->[0]) . i32(scalar @{ $t->[1] });
        for my $pid (@{ $t->[1] }) {
            my $off = $ctx->{committed}{"$t->[0]:$pid"} // -1;
            $resp .= i32($pid) . i64($off) . kstr('') . i16(0);
        }
    }
    return $resp;
}

# JoinGroup v1: assigns a member_id when empty, bumps the generation, and
# makes the (sole) member the leader with a one-entry member list.
# $ctx->{join_group_error} may be a scalar error code or coderef($req,$ctx).
sub _join_group_handler {
    my ($req, $send, $conn, $ctx) = @_;
    my $b   = $req->{body};
    my $pos = 0;
    my $gl  = unpack 'n', substr($b, $pos, 2); $pos += 2 + $gl;  # group_id
    $pos += 4;                                     # session_timeout_ms
    $pos += 4 if $req->{version} >= 1;             # rebalance_timeout_ms
    my $ml  = unpack 'n', substr($b, $pos, 2); $pos += 2;
    my $mid = substr($b, $pos, $ml);
    my $ec = $ctx->{join_group_error};
    $ec = $ec->($req, $ctx) if ref $ec eq 'CODE';
    $ec //= 0;
    return i16($ec) . i32(-1) . kstr('') . kstr('') . kstr('') . i32(0)
        if $ec;
    $mid = 'member-' . ++$ctx->{_member_seq} if $mid eq '';
    return i16(0) . i32(++$ctx->{_generation}) . kstr('sticky')
        . kstr($mid)                                 # leader
        . kstr($mid)                                 # member_id
        . i32(1) . kstr($mid) . i32(-1);             # members: null metadata
}

# SyncGroup v0: assigns every partition of every (healthy) mock topic to
# the member. $ctx->{sync_group_error} may be a scalar or coderef($req,$ctx).
sub _sync_group_handler {
    my ($req, $send, $conn, $ctx) = @_;
    my $ec = $ctx->{sync_group_error};
    $ec = $ec->($req, $ctx) if ref $ec eq 'CODE';
    $ec //= 0;
    return i16($ec) . i32(-1) if $ec;
    # ConsumerProtocol assignment: version 0, topics, null user_data.
    my $asn = i16(0);
    my @names = sort grep {
        my $s = $ctx->{topics}{$_};
        !(ref $s && $s->{error_code})
    } keys %{ $ctx->{topics} };
    $asn .= i32(scalar @names);
    for my $name (@names) {
        my $spec = $ctx->{topics}{$name};
        $spec = { nparts => $spec } unless ref $spec;
        $asn .= kstr($name) . i32(my $np = $spec->{nparts} // 1);
        $asn .= i32($_) for 0 .. $np - 1;
    }
    $asn .= i32(-1);                                 # user_data: null
    return i16(0) . i32(length $asn) . $asn;
}

# Heartbeat v0: $ctx->{heartbeat_error} may be a scalar error code or a
# coderef($req, $ctx) returning one.
sub _heartbeat_handler {
    my ($req, $send, $conn, $ctx) = @_;
    my $ec = $ctx->{heartbeat_error};
    $ec = $ec->($req, $ctx) if ref $ec eq 'CODE';
    return i16($ec // 0);
}

# OffsetCommit v2: store committed offsets into
# $ctx->{committed}{"topic:pid"} (same store OffsetFetch reads), echo
# every topic/partition with error 0. Annotates $req->{group_id}.
sub _offset_commit_handler {
    my ($req, $send, $conn, $ctx) = @_;
    my $b   = $req->{body};
    my $pos = 0;
    my $gl  = unpack 'n', substr($b, $pos, 2); $pos += 2;
    $req->{group_id} = substr($b, $pos, $gl); $pos += $gl;
    if ($req->{version} >= 1) {
        $pos += 4;                                   # generation_id
        my $ml = unpack 'n', substr($b, $pos, 2); $pos += 2 + $ml;
    }
    my $nt = unpack 'N', substr($b, $pos, 4); $pos += 4;
    my @topics;
    for (1 .. $nt) {
        my $tl = unpack 'n', substr($b, $pos, 2); $pos += 2;
        my $name = substr($b, $pos, $tl); $pos += $tl;
        my $np = unpack 'N', substr($b, $pos, 4); $pos += 4;
        my @pids;
        for (1 .. $np) {
            my $pid = unpack 'N',  substr($b, $pos, 4); $pos += 4;
            my $off = unpack 'q>', substr($b, $pos, 8); $pos += 8;
            $pos += 4 if $req->{version} >= 6;       # metadata (i32 len)
            $ctx->{committed}{"$name:$pid"} = $off;
            push @pids, $pid;
        }
        push @topics, [$name, \@pids];
    }
    my $resp = i32(scalar @topics);
    for my $t (@topics) {
        $resp .= kstr($t->[0]) . i32(scalar @{ $t->[1] });
        $resp .= i32($_) . i16(0) for @{ $t->[1] };
    }
    return $resp;
}

# LeaveGroup v0: error 0.
sub _leave_group_handler {
    my ($req, $send, $conn, $ctx) = @_;
    return i16(0);
}

# TxnOffsetCommit v0: record the transactional_id/group_id seen on the
# wire, echo topics/partitions with error 0.
sub _txn_offset_commit_handler {
    my ($req, $send, $conn, $ctx) = @_;
    my $b   = $req->{body};
    my $pos = 0;
    my $tl  = unpack 'n', substr($b, $pos, 2); $pos += 2;
    $req->{transactional_id} = substr($b, $pos, $tl); $pos += $tl;
    my $gl  = unpack 'n', substr($b, $pos, 2); $pos += 2;
    $req->{group_id} = substr($b, $pos, $gl); $pos += $gl;
    $pos += 8 + 2;                                   # producer_id, epoch
    if ($req->{version} >= 3) {
        $pos += 4;                                   # generation_id
        my $ml = unpack 'n', substr($b, $pos, 2); $pos += 2 + $ml;
    }
    my $nt = unpack 'N', substr($b, $pos, 4); $pos += 4;
    my @topics;
    for (1 .. $nt) {
        my $nl = unpack 'n', substr($b, $pos, 2); $pos += 2;
        my $name = substr($b, $pos, $nl); $pos += $nl;
        my $np = unpack 'N', substr($b, $pos, 4); $pos += 4;
        my @pids;
        for (1 .. $np) {
            my $pid = unpack 'N', substr($b, $pos, 4); $pos += 4;
            $ctx->{txn_committed}{"$name:$pid"} =
                unpack 'q>', substr($b, $pos, 8);
            $pos += 8;
            $pos += 4 if $req->{version} >= 2;       # metadata (i32 len)
            push @pids, $pid;
        }
        push @topics, [$name, \@pids];
    }
    my $resp = i32(scalar @topics);
    for my $t (@topics) {
        $resp .= kstr($t->[0]) . i32(scalar @{ $t->[1] });
        $resp .= i32($_) . i16(0) for @{ $t->[1] };
    }
    return $resp;
}

my %BUILTIN = (
    0  => \&_produce_handler,
    1  => \&_fetch_handler,
    2  => \&_list_offsets_handler,
    3  => \&_metadata_handler,
    8  => \&_offset_commit_handler,
    9  => \&_offset_fetch_handler,
    10 => \&_find_coordinator_handler,
    11 => \&_join_group_handler,
    12 => \&_heartbeat_handler,
    13 => \&_leave_group_handler,
    14 => \&_sync_group_handler,
    22 => \&_init_producer_id_handler,
    24 => \&_add_partitions_to_txn_handler,
    26 => \&_end_txn_handler,
    28 => \&_txn_offset_commit_handler,
);

# --- Request framing ----------------------------------------------------

# Parse one request frame (without the leading i32 size):
#   api_key i16, api_version i16, correlation_id i32,
#   client_id NULLABLE STRING, then the api-specific body.
sub _parse_request {
    my ($frame) = @_;
    return undef if length($frame) < 10;
    my $req = {
        api     => unpack('n', substr($frame, 0, 2)),
        version => unpack('n', substr($frame, 2, 2)),
        corr    => unpack('N', substr($frame, 4, 4)),
    };
    my $pos  = 8;
    my $clen = unpack 'n', substr($frame, $pos, 2); $pos += 2;
    $pos += $clen if $clen != 0xFFFF;
    $req->{body} = substr($frame, $pos);
    return $req;
}

sub _dispatch {
    my ($ctx, $conn, $req, $send) = @_;
    if (my $cb = $ctx->{on_request}) {
        $cb->($req, $send, $conn, $ctx);
        return;
    }
    return $send->($req->{corr}, apis_body()) if $req->{api} == 18;
    if (($ctx->{drop_on}{$req->{api}} // 0) > 0) {
        # broker-side conn drop without a response: the client's in-flight
        # request fails at the transport level
        $ctx->{drop_on}{$req->{api}}--;
        undef $conn->{read_w};
        close $conn->{fh} if $conn->{fh};
        undef $conn->{fh};
        return;
    }
    my $handler = exists $ctx->{respond}{$req->{api}}
        ? $ctx->{respond}{$req->{api}}
        : $BUILTIN{$req->{api}};
    return unless defined $handler;
    my $body = ref $handler eq 'CODE'
        ? $handler->($req, $send, $conn, $ctx)
        : $handler;
    $send->($req->{corr}, $body) if defined $body;
}

# Start a mock broker on a free port. Returns ($port, $ctx).
#
# Options:
#   topics     => { name => nparts | {nparts, leader, error_code} }
#   brokers    => [[node_id, host, port], ...]   (metadata broker list)
#   respond    => { api_key => $body_string | \&handler }
#                 handler: ($req, $send, $conn, $ctx) -> $body | undef
#                 return undef (or send via $send later) to defer/stay silent
#   on_request => \&handler   full dispatch override, same signature
#   drop_on    => { api_key => $count }  drop the client conn (no
#                 response) for the next $count requests of that api
#
# $ctx holds: server, port, accepts (count), conns, requests (logged
# $req hashes: {api, version, corr, body}), timers, topics (mutable —
# later Metadata responses reflect edits), offsets, close_all().
sub mock_broker {
    my (%opt) = @_;
    my $server = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Listen    => 5,
        Proto     => 'tcp',
        ReuseAddr => 1,
    ) or die "EVKafkaTest: cannot bind localhost listener: $!";
    $server->blocking(0);

    my $ctx = {
        server     => $server,
        port       => $server->sockport,
        accepts    => 0,
        conn_seq   => 0,
        conns      => [],
        requests   => [],
        timers     => [],
        topics     => ($opt{topics} // {}),
        brokers    => $opt{brokers},
        offsets    => {},
        respond    => ($opt{respond} // {}),
        drop_on    => ($opt{drop_on} // {}),
        on_request => $opt{on_request},
    };

    $ctx->{close_all} = sub {
        for my $c (@{ $ctx->{conns} }) {
            undef $c->{read_w};
            close $c->{fh} if $c->{fh};
            undef $c->{fh};
        }
    };

    # Drop every client conn AND stop accepting: the broker is "down".
    # The listener socket is closed so reconnect attempts get refused.
    $ctx->{shutdown} = sub {
        $ctx->{close_all}->();
        undef $ctx->{accept_w};
        close $ctx->{server} if $ctx->{server};
        undef $ctx->{server};
    };

    $ctx->{accept_w} = EV::io fileno($server), EV::READ, sub {
        my $fh = $server->accept or return;
        $fh->blocking(0);
        $ctx->{accepts}++;
        my $conn = { id => ++$ctx->{conn_seq}, fh => $fh, incoming => '' };
        push @{ $ctx->{conns} }, $conn;
        my $send = sub {
            my ($corr, $body) = @_;
            return unless $conn->{fh};
            my $payload = i32($corr) . $body;
            syswrite $conn->{fh}, i32(length $payload) . $payload;
        };
        $conn->{read_w} = EV::io fileno($fh), EV::READ, sub {
            my $buf;
            my $n = sysread $fh, $buf, 4096;
            if (!defined $n) {
                return if $!{EAGAIN} || $!{EWOULDBLOCK};
                undef $conn->{read_w};
                close $fh; undef $conn->{fh};
                return;
            }
            if ($n == 0) {
                undef $conn->{read_w};
                close $fh; undef $conn->{fh};
                return;
            }
            $conn->{incoming} .= $buf;
            while (length($conn->{incoming}) >= 4) {
                my $size = unpack 'N', substr($conn->{incoming}, 0, 4);
                last if length($conn->{incoming}) < 4 + $size;
                my $frame = substr($conn->{incoming}, 4, $size);
                substr($conn->{incoming}, 0, 4 + $size) = '';
                my $req = _parse_request($frame) or next;
                $req->{ts} = EV::now;
                push @{ $ctx->{requests} }, $req;
                _dispatch($ctx, $conn, $req, $send);
            }
        };
    };

    return ($ctx->{port}, $ctx);
}

# A hand-managed EV::Kafka::Conn with the handshake completed, against a
# fresh mock broker. Returns ($conn, $ctx).
sub ready_conn {
    my (%opt) = @_;
    my ($port, $broker) = mock_broker(%opt);
    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    my $ready = 0;
    $conn->on_error(sub { Test::More::diag "mock conn error: $_[0]"; EV::break });
    $conn->on_connect(sub { $ready = 1; EV::break });
    $conn->connect('127.0.0.1', $port, 5.0);
    my $t = timeout_w();
    EV::run;
    Test::More::BAIL_OUT('mock handshake failed') unless $ready;
    return ($conn, $broker);
}

sub timeout_w { EV::timer($_[0] // 5, 0, sub { Test::More::diag "test timed out"; EV::break }) }

1;
