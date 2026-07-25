use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Errno qw(EAGAIN EWOULDBLOCK);
use Scalar::Util qw(weaken);
use B;
use EV;
use EV::Kafka;

# Regression tests for connection object lifecycle and memory ownership:
#   M1  response mortals are reclaimed per event, not when EV::run returns
#   M2  DESTROY fires every pending callback (not just the first)
#   M5  a custom EV::Loop is refcounted by the conn
#   M6  explicit DESTROY inerts the blessed ref; stale use croaks
#   M7  conn_emit_error warns (not croaks) when no on_error is installed
#   M8  disconnect() from on_disconnect/on_error neither recurses nor
#       fires on_disconnect twice
#   M9  pending-request error callbacks fire before on_disconnect
#
# Uses the in-process mock-broker pattern from t/20_mock_conn.t — no live
# broker needed.

plan tests => 21;

sub i16 { pack 'n', $_[0] }
sub i32 { pack 'N', $_[0] }

my $apis_body =
      i16(0)         # no error
    . i32(2)         # 2 entries
    . i16(0) . i16(0) . i16(7)     # API_PRODUCE, v0..v7
    . i16(18) . i16(0) . i16(0);   # API_API_VERSIONS, v0..v0

# Start a mock broker on a free port. $on_request->($api_key, $corr_id,
# $send, $ctx) runs for each full request frame; $send->($corr, $body)
# frames and writes a response. $ctx keeps watchers/sockets/timers alive
# and offers $ctx->{close_client}. Returns ($port, $ctx).
sub mock_broker {
    my (%opt) = @_;
    my $server = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Listen    => 1,
        Proto     => 'tcp',
        ReuseAddr => 1,
    ) or BAIL_OUT "cannot bind localhost listener: $!";
    $server->blocking(0);

    my $ctx = { server => $server, timers => [] };
    my $on_request = $opt{on_request} || sub {
        my ($api, $corr, $send) = @_;
        $send->($corr, $apis_body) if $api == 18;
    };

    $ctx->{close_client} = sub {
        undef $ctx->{read_w};
        close $ctx->{client_fh} if $ctx->{client_fh};
        undef $ctx->{client_fh};
    };

    $ctx->{accept_w} = EV::io fileno($server), EV::READ, sub {
        my $fh = $server->accept or return;
        $fh->blocking(0);
        $ctx->{client_fh} = $fh;
        my $send = sub {
            my ($corr, $body) = @_;
            return unless $ctx->{client_fh};
            my $payload = i32($corr) . $body;
            syswrite $ctx->{client_fh}, i32(length $payload) . $payload;
        };
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
                $on_request->($api, $corr, $send, $ctx);
            }
        };
    };

    return ($server->sockport, $ctx);
}

sub timeout_w { EV::timer 5, 0, sub { diag "test timed out"; EV::break } }

# --- M1: a parsed response must not stay alive past its event -------------
# Broker answers the first Metadata request immediately and the second
# 0.2s later, so the two callbacks run in SEPARATE watcher events.  The
# first callback keeps only a weak ref to its result; if response mortals
# are pinned until EV::run returns (the bug), $saved is still defined when
# the second callback runs.
{
    my $meta_body = i32(0) . i32(1) . i32(0);  # v1: 0 brokers, controller 1, 0 topics
    my $meta_seen = 0;
    my ($port, $broker) = mock_broker(on_request => sub {
        my ($api, $corr, $send, $ctx) = @_;
        if ($api == 18) { $send->($corr, $apis_body); return; }
        if ($api == 3) {
            $meta_seen++;
            if ($meta_seen == 1) {
                $send->($corr, $meta_body);
            } else {
                push @{ $ctx->{timers} },
                    EV::timer(0.2, 0, sub { $send->($corr, $meta_body) });
            }
        }
    });

    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    my $saved;
    $conn->on_error(sub { diag "M1 error: $_[0]"; EV::break });
    $conn->on_connect(sub {
        $conn->metadata(undef, sub { $saved = $_[0]; weaken($saved); });
        $conn->metadata(undef, sub {
            ok !defined($saved),
                'M1: response mortal is reclaimed when its event ends';
            EV::break;
        });
    });
    $conn->connect('127.0.0.1', $port, 5.0);
    my $t = timeout_w();
    EV::run;
}

# --- M2: DESTROY must fire every pending callback -------------------------
{
    my ($port, $broker) = mock_broker();    # handshake only, swallows the rest
    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    my $ready = 0;
    $conn->on_error(sub { diag "M2 error: $_[0]"; EV::break });
    $conn->on_connect(sub { $ready = 1; EV::break });
    $conn->connect('127.0.0.1', $port, 5.0);
    my $t = timeout_w();
    EV::run;
    ok $ready, 'M2: handshake complete';

    my (@fired, @refs);
    for (1..3) {
        my $cb = sub { push @fired, $_[1] };
        push @refs, $cb;
        weaken($refs[-1]);
        $conn->metadata(undef, $cb);
    }
    is $conn->pending, 3, 'M2: three requests in flight';

    $conn->DESTROY;
    is scalar(@fired), 3, 'M2: DESTROY fires every pending callback';
    is_deeply \@fired, [('destroyed') x 3], 'M2: all report "destroyed"';
    is scalar(grep { defined } @refs), 0, 'M2: callback CVs are released';
}

# --- M5: custom EV::Loop is refcounted ------------------------------------
{
    my $loop = EV::Loop->new;
    my $rc0 = B::svref_2object($loop)->REFCNT;
    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', $loop);
    is B::svref_2object($loop)->REFCNT, $rc0 + 1,
        'M5: conn holds a ref on a custom EV::Loop';
    undef $conn;
    is B::svref_2object($loop)->REFCNT, $rc0,
        'M5: loop ref released at DESTROY';
}

# --- M6: destroyed conn is inert; stale use croaks ------------------------
{
    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    $conn->DESTROY;
    $conn->DESTROY;    # must be a no-op, not a use-after-free
    ok 1, 'M6: explicit double DESTROY survives';

    like do { local $@; eval { $conn->state }; $@ },
        qr/destroyed connection/, 'M6: state() on destroyed conn croaks';
    like do { local $@; eval { $conn->pending }; $@ },
        qr/destroyed connection/, 'M6: pending() on destroyed conn croaks';
    like do { local $@; eval { $conn->connect('127.0.0.1', 9092, 1.0) }; $@ },
        qr/destroyed connection/, 'M6: connect() on destroyed conn croaks';
    like do { local $@; eval { $conn->metadata(undef, sub {}) }; $@ },
        qr/destroyed connection/, 'M6: metadata() on destroyed conn croaks';
}

# --- M6: stale DESTROY must not tear down a conn that reused the heap -----
{
    my $victim = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    $victim->DESTROY;    # frees the block

    # Newxz very likely reuses victim's freed block for this conn.
    my ($port, $broker) = mock_broker();
    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    my $ready = 0;
    $conn->on_error(sub { diag "M6-reuse error: $_[0]"; EV::break });
    $conn->on_connect(sub { $ready = 1; EV::break });
    $conn->connect('127.0.0.1', $port, 5.0);
    my $t = timeout_w();
    EV::run;
    BAIL_OUT 'M6-reuse: handshake failed' unless $ready;

    my @fired;
    $conn->metadata(undef, sub { push @fired, 1 });

    $victim->DESTROY;    # stale: must be a no-op, must not cancel $conn's queue
    is scalar(@fired), 0,
        'M6: stale DESTROY does not tear down a live (reused) conn';
    $conn->DESTROY;
    is scalar(@fired), 1, 'M6: live conn still drains its own pending queue';
}

# --- M7: no on_error installed -> warn, not croak -------------------------
{
    my $sock = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 1,
        Proto => 'tcp', ReuseAddr => 1,
    ) or BAIL_OUT "cannot bind: $!";
    my $port = $sock->sockport;
    close $sock;    # nothing listening: connect will be refused

    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    my (@warnings, $disconnected);
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    $conn->on_disconnect(sub { $disconnected++; EV::break });
    $conn->connect('127.0.0.1', $port, 2.0);
    my $t = timeout_w();
    my $died = do { local $@; eval { EV::run; 1 } ? undef : $@ };
    ok !$died, 'M7: EV::run survives an error with no on_error installed'
        or diag $died;
    is $disconnected, 1, 'M7: on_disconnect still fires';
    like "@warnings", qr/EV::Kafka::Conn: connect/,
        'M7: error is warned, not croaked';
}

# --- M8: disconnect() from on_disconnect does not recurse -----------------
{
    my ($port, $broker) = mock_broker(on_request => sub {
        my ($api, $corr, $send, $ctx) = @_;
        if ($api == 18) {
            $send->($corr, $apis_body);
            push @{ $ctx->{timers} },
                EV::timer(0.1, 0, sub { $ctx->{close_client}->() });
        }
    });

    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    my $dc = 0;
    $conn->on_error(sub { diag "M8a error: $_[0]" });
    $conn->on_disconnect(sub {
        $dc++;
        $conn->disconnect() if $dc < 5;   # pre-fix: recursed; cap the damage
        EV::break;
    });
    $conn->connect('127.0.0.1', $port, 5.0);
    my $t = timeout_w();
    EV::run;
    is $dc, 1, 'M8: disconnect() inside on_disconnect fires it exactly once';
}

# --- M8: disconnect() from on_error must not fire on_disconnect twice -----
{
    my ($port, $broker) = mock_broker(on_request => sub {
        my ($api, $corr, $send, $ctx) = @_;
        if ($api == 18) {
            $send->($corr, $apis_body);
            push @{ $ctx->{timers} }, EV::timer(0.1, 0, sub {
                # invalid response size (> 256 MB): triggers on_error
                syswrite $ctx->{client_fh}, i32(0x7FFFFFFF)
                    if $ctx->{client_fh};
            });
        }
    });

    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    my $od = 0;
    $conn->on_error(sub { $conn->disconnect() });
    $conn->on_disconnect(sub { $od++; EV::break });
    $conn->connect('127.0.0.1', $port, 5.0);
    my $t = timeout_w();
    EV::run;
    is $od, 1, 'M8: disconnect() inside on_error fires on_disconnect once';
}

# --- M9: pending-request error callbacks fire before on_disconnect --------
{
    my ($port, $broker) = mock_broker(on_request => sub {
        my ($api, $corr, $send, $ctx) = @_;
        if ($api == 18) { $send->($corr, $apis_body); return; }
        if ($api == 3) {
            # swallow the Metadata request, then hang up on the client
            push @{ $ctx->{timers} },
                EV::timer(0.1, 0, sub { $ctx->{close_client}->() });
        }
    });

    my $conn = EV::Kafka::Conn::_new('EV::Kafka::Conn', undef);
    my @order;
    $conn->on_error(sub { diag "M9 error: $_[0]" });
    $conn->on_connect(sub {
        $conn->metadata(undef, sub { push @order, 'request-error' });
    });
    $conn->on_disconnect(sub { push @order, 'disconnect'; EV::break });
    $conn->connect('127.0.0.1', $port, 5.0);
    my $t = timeout_w();
    EV::run;
    is_deeply \@order, ['request-error', 'disconnect'],
        'M9: pending request errors fire before on_disconnect';
}
