use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Kafka;

# Regression tests for malformed wire data and unvalidated XSUB arguments.
# Parser goldens are hand-built per the Kafka protocol spec, in the style of
# t/18_response_parsers.t — no broker dependency. The XSUB argument tests
# use an in-process mock handshake (as in t/20_mock_conn.t) to reach
# CONN_READY, because the "not connected" guard fires before argument
# validation otherwise.

plan tests => 12;

sub i32 { pack 'N',  $_[0] }
sub i16 { pack 'n',  $_[0] }
sub i64 { pack 'q>', $_[0] }
sub kstr { my $s = shift; i16(length $s) . $s }

# --- Fetch v4 with a record batch length of 0x7FFFFFF9 ---
# 12 + bl used to be computed in 32-bit int and wrap negative, handing the
# batch decoder a ~2GB length over a handful of real bytes (segfault in
# crc32c). Must now be rejected by a 64-bit bounds check.
{
    my $batch = i64(0) . i32(0x7FFFFFF9); # base_offset + malicious batch_length
    my $body =
          i32(0)               # throttle_time_ms (v1+)
        . i32(1)               # responses: 1 topic
        . kstr('t')
        . i32(1)               # partitions: 1
        . i32(0)               # partition id
        . i16(0)               # error_code
        . i64(0)               # high_watermark
        . i64(0)               # last_stable_offset (v4+)
        . i32(0)               # aborted_transactions count (v4+)
        . i32(length $batch)   # record_set BYTES size
        . $batch;
    my $r = EV::Kafka::_test_parse_response('fetch', 4, $body);
    ok ref $r eq 'HASH',
        'fetch v4 with batch_length 0x7FFFFFF9 returns without crashing';
    is_deeply $r->{topics}[0]{partitions}[0]{records}, [],
        'oversized batch_length rejected, no records decoded';
}

# --- Metadata v9 with a hostile compact-string length for broker host ---
# uvarint 80 80 80 80 10 decodes to raw = 2^32; len = raw - 1 used to wrap
# to -1 in the int32_t cast, escaping as a negative strlen
# (panic: sv_setpvn_fresh called with negative strlen -1).
{
    my $body =
          i32(0)               # throttle_time_ms
        . "\x02"               # brokers: compact array, count+1 = 2 => 1 broker
        . i32(1)               # node_id
        . "\x80\x80\x80\x80\x10" # host: compact string, raw uvarint = 2^32
        . i32(9092)            # port
        . "\x00"               # rack: null
        . "\x00";              # tagged fields
    my $r = EV::Kafka::_test_parse_response('metadata', 9, $body);
    ok ref $r eq 'HASH',
        'metadata v9 with host uvarint 2^32 returns without negative-strlen panic';
    is scalar @{$r->{brokers} // []}, 0,
        'host length 2^32-1 rejected (len would wrap to -1)';
}

# Same idea, larger wrap: 81 80 80 80 08 decodes to raw = 0x80000001,
# len = 0x80000000 => INT32_MIN.
{
    my $body =
          i32(0)
        . "\x02"
        . i32(1)
        . "\x81\x80\x80\x80\x08" # host: compact string, raw uvarint = 0x80000001
        . i32(9092)
        . "\x00"
        . "\x00";
    my $r = EV::Kafka::_test_parse_response('metadata', 9, $body);
    ok ref $r eq 'HASH',
        'metadata v9 with host uvarint 0x80000001 returns without crashing';
    is scalar @{$r->{brokers} // []}, 0,
        'host length 0x80000000 rejected (len would wrap to INT32_MIN)';
}

# --- XSUB argument validation ---
# join_group, offset_commit, offset_fetch, create_topics and delete_topics
# used to dereference SvRV() with no SvROK/SvTYPE check: a plain string was
# treated as an AV* (segfault). They must now croak like their siblings.
{
    # In-process mock broker answering the ApiVersions handshake, so the
    # conn reaches CONN_READY and the argument guards (which follow the
    # "not connected" croak) are what is actually exercised.
    my $server = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Listen    => 1,
        Proto     => 'tcp',
        ReuseAddr => 1,
    ) or BAIL_OUT "cannot bind localhost listener: $!";
    $server->blocking(0);
    my $port = $server->sockport;

    my $apis_body =
          i16(0)
        . i32(2)
        . i16(0) . i16(0) . i16(7)     # API_PRODUCE, v0..v7
        . i16(18) . i16(0) . i16(0);   # API_API_VERSIONS, v0..v0

    my ($client_fh, $client_read_w);
    my $accept_w = EV::io fileno($server), EV::READ, sub {
        $client_fh = $server->accept or return;
        $client_fh->blocking(0);
        my $incoming = '';
        $client_read_w = EV::io fileno($client_fh), EV::READ, sub {
            my $buf;
            my $n = sysread $client_fh, $buf, 4096;
            if (!defined $n || $n == 0) { undef $client_read_w; return; }
            $incoming .= $buf;
            return if length($incoming) < 4;
            my $size = unpack 'N', substr($incoming, 0, 4);
            return if length($incoming) < 4 + $size;
            my $corr_id = unpack 'N', substr($incoming, 4 + 2 + 2, 4);
            my $payload = i32($corr_id) . $apis_body;
            syswrite $client_fh, i32(length $payload) . $payload;
            undef $client_read_w;
        };
    };

    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    my $connected = 0;
    $conn->on_connect(sub { $connected = 1; EV::break });
    $conn->on_error(sub { diag "mock handshake error: $_[0]"; EV::break });
    $conn->connect('127.0.0.1', $port, 5.0);
    my $timeout = EV::timer 5, 0, sub { diag "mock handshake timed out"; EV::break };
    EV::run;

    ok $connected && $conn->connected, 'mock handshake: conn reached CONN_READY';

    my @cases = (
        [offset_fetch  => sub { $_[0]->offset_fetch('g', 'not-a-ref', sub {}) }],
        [join_group    => sub { $_[0]->join_group('g', 'm', 'not-a-ref', sub {}) }],
        [offset_commit => sub { $_[0]->offset_commit('g', 1, 'm', 'not-a-ref', sub {}) }],
        [create_topics => sub { $_[0]->create_topics('not-a-ref', 1000, sub {}) }],
        [delete_topics => sub { $_[0]->delete_topics('not-a-ref', 1000, sub {}) }],
    );
    for my $case (@cases) {
        my ($name, $call) = @$case;
        my $err = do {
            local $@;
            eval { $call->($conn) };
            $@;
        };
        like $err, qr/^\Q$name: expected arrayref\E/,
            "$name croaks on non-arrayref argument instead of segfaulting";
    }

    eval { $conn->disconnect; };
    close $server;
}
