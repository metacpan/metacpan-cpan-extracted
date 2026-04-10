use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Nats;

my $host = $ENV{TEST_NATS_HOST} || '127.0.0.1';
my $port = $ENV{TEST_NATS_PORT} || 4222;

my $sock = IO::Socket::INET->new(
    PeerAddr => $host,
    PeerPort => $port,
    Timeout  => 1,
);
unless ($sock) {
    plan skip_all => "NATS server not available at $host:$port";
}
close $sock;

plan tests => 4;

my $guard = EV::timer 15, 0, sub { fail 'timeout'; EV::break };

my $received = 0;
my $drained = 0;
my $disconnected = 0;

# Publisher connection
my $pub;
$pub = EV::Nats->new(
    host     => $host,
    port     => $port,
    on_error => sub { diag "pub error: @_" },
);

# Subscriber that drains mid-stream
my $sub;
$sub = EV::Nats->new(
    host     => $host,
    port     => $port,
    on_error => sub { diag "sub error: @_" },
    on_disconnect => sub { $disconnected = 1 },
);

my $ready; $ready = EV::timer 0.1, 0.1, sub {
    return unless $pub->is_connected && $sub->is_connected;
    undef $ready;

    $sub->subscribe('drain.load', sub {
        $received++;
    });

    my $go; $go = EV::timer 0.1, 0, sub {
        undef $go;

        # Start publishing continuously
        my $sent = 0;
        my $pub_timer; $pub_timer = EV::timer 0, 0.001, sub {
            $pub->publish('drain.load', "msg-" . ++$sent) for 1..10;
            if ($sent >= 500) {
                undef $pub_timer;
            }
        };

        # Drain the subscriber after some messages arrive
        my $drain_timer; $drain_timer = EV::timer 0.3, 0, sub {
            undef $drain_timer;
            ok $received > 0, "received $received msgs before drain";

            $sub->drain(sub {
                $drained = 1;
                pass 'drain callback fired under load';
            });

            my $check; $check = EV::timer 3, 0, sub {
                undef $check;
                ok $drained, 'drain completed';
                ok $disconnected, 'subscriber disconnected after drain';
                $pub->disconnect;
                EV::break;
            };
        };
    };
};

EV::run;
