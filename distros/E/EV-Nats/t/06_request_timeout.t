use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use NatsLive;
use EV;
use EV::Nats;

my ($host, $port) = nats_or_skip();

plan tests => 2;

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

    # request with no responder -should timeout
    $nats->request('nonexistent.service', 'hello', sub {
        my ($resp, $err) = @_;
        ok !defined $resp, 'response is undef on timeout';
        is $err, 'request timeout', 'got request timeout error';
        $nats->disconnect;
        EV::break;
    }, 500); # 500ms timeout
};

EV::run;
