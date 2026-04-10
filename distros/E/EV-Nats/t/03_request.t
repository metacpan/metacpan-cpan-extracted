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

my $nats;
$nats = EV::Nats->new(
    host       => $host,
    port       => $port,
    on_error   => sub { diag "error: @_"; EV::break },
    connect_timeout => 5000,
);

my $guard = EV::timer 10, 0, sub { fail 'timeout'; EV::break };

my $ready; $ready = EV::timer 0.1, 0.1, sub {
    return unless $nats->is_connected;
    undef $ready;

    $nats->subscribe('echo', sub {
        my ($subject, $payload, $reply) = @_;
        pass 'responder received request';
        is $payload, 'ping', 'request payload';
        $nats->publish($reply, 'pong') if $reply;
    });

    my $req_timer; $req_timer = EV::timer 0.1, 0, sub {
        undef $req_timer;
        $nats->request('echo', 'ping', sub {
            my ($response, $err) = @_;
            ok !$err, 'no error';
            is $response, 'pong', 'got reply';
            $nats->disconnect;
            EV::break;
        }, 5000);
    };
};

EV::run;
