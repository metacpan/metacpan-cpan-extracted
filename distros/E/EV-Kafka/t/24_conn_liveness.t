use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Errno qw(EAGAIN EWOULDBLOCK);
use EV;
use EV::Kafka;

# Regression tests for connection liveness:
#   L1  handshake phases (ApiVersions/TLS/SASL) are covered by the connect
#       timer — a peer that accepts but stays silent fails the conn
#   L2  auto_reconnect keeps retrying after a SYNCHRONOUS connect failure
#   L5  SASL config errors ("unsupported mechanism", "username required")
#       disconnect instead of wedging the state machine
#   L9  undef/empty SASL credentials are stored as NULL, not ""
#   L6  acks=0 produce callbacks fire (empty success = handed to socket)
#   L10 reconnect uses capped exponential backoff with jitter, first retry
#       still exactly reconnect_delay_ms
#
# Mock-broker pattern as in t/20-t/23 — no live broker needed.

plan tests => 15;

sub i16 { pack 'n', $_[0] }
sub i32 { pack 'N', $_[0] }

my $apis_body =
      i16(0)
    . i32(2)
    . i16(0) . i16(0) . i16(7)     # API_PRODUCE, v0..v7
    . i16(18) . i16(0) . i16(0);   # API_API_VERSIONS, v0..v0

# SaslHandshake v1 success: no error, mechanisms = ["PLAIN"]
my $sasl_handshake_body = i16(0) . i32(1) . i16(5) . 'PLAIN';

sub mock_broker {
    my (%opt) = @_;
    my $respond = $opt{respond} || {};
    my $server = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 1,
        Proto => 'tcp', ReuseAddr => 1,
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

sub free_port {
    my $sock = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 1,
        Proto => 'tcp', ReuseAddr => 1,
    ) or BAIL_OUT "cannot bind: $!";
    my $port = $sock->sockport;
    close $sock;
    return $port;
}

# --- L1: a peer that accepts but stays silent fails the handshake ---------
{
    my $server = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 1,
        Proto => 'tcp', ReuseAddr => 1,
    ) or BAIL_OUT "cannot bind: $!";
    $server->blocking(0);
    my ($fh, $accept_w);
    $accept_w = EV::io fileno($server), EV::READ, sub {
        $fh = $server->accept;    # accept and stay silent forever
    };

    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    my ($err, $disconnected);
    $conn->on_error(sub { $err = $_[0]; });
    $conn->on_disconnect(sub { $disconnected++; EV::break });
    $conn->connect('127.0.0.1', $server->sockport, 0.3);
    my $safety = EV::timer 4, 0, sub { diag "L1 timed out"; EV::break };
    EV::run;

    like $err, qr/handshake timeout/,
        'L1: silent peer fails with handshake timeout';
    is $disconnected, 1, 'L1: conn disconnects after handshake timeout';

    close $server;
}

# --- L5/L9: SASL config errors disconnect instead of wedging --------------
for my $case (
    # [mechanism, username, password, expected error]
    ['GSSAPI', 'u', 'p', 'unsupported SASL mechanism'],
    ['SCRAM-SHA-256', undef, undef, 'SCRAM: username required'],
    ['SCRAM-SHA-256', '', '', 'SCRAM: username required'],   # L9: '' == undef
) {
    my ($mech, $user, $pass, $expect) = @$case;
    my ($port, $broker) = mock_broker(respond => { 17 => $sasl_handshake_body });

    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    my ($err, $disconnected);
    $conn->on_error(sub { $err = $_[0]; });
    $conn->on_disconnect(sub { $disconnected++; EV::break });
    $conn->sasl($mech, $user, $pass);
    $conn->connect('127.0.0.1', $port, 5.0);
    my $safety = EV::timer 4, 0, sub { diag "L5 case $mech timed out"; EV::break };
    EV::run;

    like $err, qr/^\Q$expect\E/, "L5: $mech config error surfaces";
    is $disconnected, 1, "L5: $mech config error disconnects the conn";
    $conn->DESTROY;
}

# --- L6: acks=0 produce callback fires with empty success -----------------
{
    my ($conn, $broker) = ready_conn();

    my ($fired, $res, $error);
    $conn->produce('t', 0, 'k', 'v', { acks => 0 }, sub {
        $fired++;
        ($res, $error) = @_;
    });
    is $fired, 1,
        'L6: acks=0 callback fires immediately (handed to the socket)';
    ok((ref $res eq 'HASH' && !keys %$res), 'L6: empty success result');
    ok !defined($error), 'L6: no error';

    $conn->DESTROY;
}

# --- L2: auto_reconnect survives a synchronous connect failure ------------
{
    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    my @errors;
    $conn->auto_reconnect(1, 100);
    $conn->on_error(sub { push @errors, $_[0]; EV::break if @errors >= 2 });
    $conn->connect('x' x 300, 9092, 1.0);   # getaddrinfo fails synchronously
    my $safety = EV::timer 3, 0, sub { EV::break };
    EV::run;

    is(scalar(@errors) >= 2 ? 2 : scalar(@errors), 2,
        'L2: auto_reconnect keeps retrying after synchronous resolve failure');
    like $errors[0], qr/^resolve:/, 'L2: error mentions resolve';

    $conn->DESTROY;
}

# --- L10: reconnect backoff, first retry unchanged -------------------------
{
    my $port = free_port();    # nothing listening: connection refused
    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    my @times;
    $conn->auto_reconnect(1, 200);
    $conn->on_error(sub { push @times, EV::now; EV::break if @times >= 4 });
    $conn->connect('127.0.0.1', $port, 1.0);
    my $safety = EV::timer 4, 0, sub { EV::break };
    EV::run;

    # failures: e0 ~ 0 (refused), e1 ~ 0.2s (first retry, exact base),
    # e2 ~ 0.6s, e3 ~ 1.4s with 2x/4x backoff and +/-25% jitter
    cmp_ok scalar(@times), '>=', 4, 'L10: four failures observed';
    cmp_ok $times[3] - $times[0], '>', 1.0,
        'L10: retries back off exponentially (fixed delay would give ~0.6s)';

    $conn->DESTROY;
}
