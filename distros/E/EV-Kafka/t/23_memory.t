use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Errno qw(EAGAIN EWOULDBLOCK);
use EV;
use EV::Kafka;

# Regression tests for:
#   M3  response parsers leak partially built HV/AV nodes on malformed
#       input (now born-mortal, reclaimed by the per-event tmps frame)
#   M4  kf_buf body leaks when argument validation croaks in fetch_multi,
#       add_partitions_to_txn, txn_offset_commit (now validated up front,
#       mirroring kf_encode_record_batch_multi's documented pattern)
#
# Memory growth is measured via /proc/self/status VmHWM (peak RSS,
# monotonic, low noise); those tests skip where /proc is unavailable.

plan tests => 9;

sub i16 { pack 'n', $_[0] }
sub i32 { pack 'N', $_[0] }

sub vmhwm_kb {
    open my $fh, '<', '/proc/self/status' or return undef;
    while (<$fh>) { return $1 if /^VmHWM:\s+(\d+)\s*kB/; }
    return undef;
}

my $apis_body =
      i16(0)         # no error
    . i32(2)         # 2 entries
    . i16(0) . i16(0) . i16(7)     # API_PRODUCE, v0..v7
    . i16(18) . i16(0) . i16(0);   # API_API_VERSIONS, v0..v0

# Mock broker, same pattern as t/22_lifecycle.t: completes the ApiVersions
# handshake, then answers each request with a minimal canned body for its
# API. Returns ($port, $ctx).
sub mock_broker {
    my (%opt) = @_;
    my $respond = $opt{respond} || {};   # api_key => response body
    my $server = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Listen    => 1,
        Proto     => 'tcp',
        ReuseAddr => 1,
    ) or BAIL_OUT "cannot bind localhost listener: $!";
    $server->blocking(0);

    my $ctx = { server => $server };
    $ctx->{accept_w} = EV::io fileno($server), EV::READ, sub {
        my $fh = $server->accept or return;
        $fh->blocking(0);
        $ctx->{client_fh} = $fh;
        my $incoming = '';
        $ctx->{read_w} = EV::io fileno($fh), EV::READ, sub {
            my $buf;
            my $n = sysread $fh, $buf, 4096;
            if (!defined $n) {
                return if $!{EAGAIN} || $!{EWOULDBLOCK};
                undef $ctx->{read_w};
                return;
            }
            if ($n == 0) { undef $ctx->{read_w}; return; }
            $incoming .= $buf;
            while (length($incoming) >= 4) {
                my $size = unpack 'N', substr($incoming, 0, 4);
                last if length($incoming) < 4 + $size;
                my $api  = unpack 'n', substr($incoming, 4, 2);
                my $corr = unpack 'N', substr($incoming, 8, 4);
                substr($incoming, 0, 4 + $size) = '';
                my $body = $api == 18 ? $apis_body : $respond->{$api};
                next unless defined $body;
                my $payload = i32($corr) . $body;
                syswrite $fh, i32(length $payload) . $payload;
            }
        };
    };

    return ($server->sockport, $ctx);
}

sub ready_conn {
    my (%opt) = @_;
    my ($port, $broker) = mock_broker(%opt);
    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    my $ready = 0;
    $conn->on_error(sub { diag "mock conn error: $_[0]"; EV::break });
    $conn->on_connect(sub { $ready = 1; EV::break });
    $conn->connect('127.0.0.1', $port, 5.0);
    my $t = EV::timer 5, 0, sub { diag "handshake timed out"; EV::break };
    EV::run;
    BAIL_OUT 'mock handshake failed' unless $ready;
    return ($conn, $broker);
}

# --- M4: croak messages survive the move to up-front validation -----------
{
    my ($conn, $broker) = ready_conn();

    like do { local $@; eval { $conn->fetch_multi({ t => 'x' }, sub {}) }; $@ },
        qr/^fetch_multi: value must be an arrayref/,
        'M4: fetch_multi validates partition array up front';
    like do { local $@; eval { $conn->fetch_multi({ t => ['x'] }, sub {}) }; $@ },
        qr/^fetch_multi: partition entry must be a hashref/,
        'M4: fetch_multi validates partition entries up front';
    like do { local $@; eval { $conn->add_partitions_to_txn('x', 1, 0, [{}], sub {}) }; $@ },
        qr/^add_partitions_to_txn: missing topic/,
        'M4: add_partitions_to_txn validates up front';
    like do { local $@; eval { $conn->txn_offset_commit('x', 'g', 1, 0, 1, 'm', [{ topic => 't', partitions => ['x'] }], sub {}) }; $@ },
        qr/^txn_offset_commit: bad partition/,
        'M4: txn_offset_commit validates partition records up front';

    $conn->DESTROY;
}

# --- M4: the encode paths still work after de-fanging the loops -----------
{
    my ($conn, $broker) = ready_conn(respond => {
        1  => i32(0) . i32(0),          # Fetch v4: throttle, 0 responses
        24 => i32(0) . i16(0),          # AddPartitionsToTxn v0: throttle, no error
        28 => i32(0) . i32(0),          # TxnOffsetCommit v0: throttle, 0 topics
    });

    my %fired;
    my $cb = sub {
        my ($api, $res, $err) = @_;
        $fired{$api} = [ defined $res ? 1 : 0, defined $err ? 1 : 0 ];
        EV::break if keys %fired == 3;
    };

    $conn->fetch_multi({ t => [{ partition => 0, offset => 0 }] },
        sub { $cb->('fetch_multi', @_) });
    $conn->add_partitions_to_txn('x', 1, 0, [{ topic => 't', partitions => [0] }],
        sub { $cb->('add_partitions_to_txn', @_) });
    $conn->txn_offset_commit('x', 'g', 1, 0, 1, 'm',
        [{ topic => 't', partitions => [{ partition => 0, offset => 0 }] }],
        sub { $cb->('txn_offset_commit', @_) });

    my $t = EV::timer 5, 0, sub { diag "roundtrip timed out"; EV::break };
    EV::run;

    is_deeply $fired{fetch_multi}, [1, 0],
        'M4: fetch_multi encodes and roundtrips valid args';
    is_deeply $fired{add_partitions_to_txn}, [1, 0],
        'M4: add_partitions_to_txn encodes and roundtrips valid args';
    is_deeply $fired{txn_offset_commit}, [1, 0],
        'M4: txn_offset_commit encodes and roundtrips valid args';

    $conn->DESTROY;
}

# --- M3: malformed responses do not leak partial HV/AV nodes --------------
SKIP: {
    skip 'VmHWM not available (/proc/self/status)', 1
        unless defined vmhwm_kb();

    # Metadata v9: 1 broker, body truncated mid-node.  Pre-fix this leaked
    # the in-flight broker HV at every call (goto done before adoption).
    my $trunc = i32(0)          # throttle_time_ms
              . "\x02"          # brokers: compact array, count+1 = 2 => 1 broker
              . i32(1);         # node_id ... then nothing: string read fails

    EV::Kafka::_test_parse_response('metadata', 9, $trunc) for 1..2000;
    my $hwm0 = vmhwm_kb();
    EV::Kafka::_test_parse_response('metadata', 9, $trunc) for 1..50000;
    my $hwm1 = vmhwm_kb();
    my $delta = $hwm1 - $hwm0;
    diag "M3 VmHWM delta over 50k malformed parses: ${delta} kB";
    ok $delta < 4096,
        'M3: malformed metadata responses do not leak partial structures';
}

# --- M4: croaking argument validation does not leak the body buffer -------
SKIP: {
    skip 'VmHWM not available (/proc/self/status)', 1
        unless defined vmhwm_kb();

    my ($conn, $broker) = ready_conn();

    my $loop = sub {
        eval { $conn->fetch_multi({ t => ['x'] }, sub {}) };
        eval { $conn->add_partitions_to_txn('x', 1, 0, [{}], sub {}) };
        eval { $conn->txn_offset_commit('x', 'g', 1, 0, 1, 'm', [{ topic => 't' }], sub {}) };
    };

    $loop->() for 1..200;
    my $hwm0 = vmhwm_kb();
    $loop->() for 1..20000;
    my $hwm1 = vmhwm_kb();
    my $delta = $hwm1 - $hwm0;
    diag "M4 VmHWM delta over 60k croaking calls: ${delta} kB";
    ok $delta < 4096,
        'M4: croaking validation does not leak the kf_buf body';

    $conn->DESTROY;
}
