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

plan tests => 7;

my $nats;
$nats = EV::Nats->new(
    host       => $host,
    port       => $port,
    on_error   => sub { diag "error: @_"; EV::break },
    on_connect => sub { pass 'connected' },
    connect_timeout => 5000,
);

my $guard = EV::timer 10, 0, sub { fail 'timeout'; EV::break };

my @received;

my $nats_connected; $nats_connected = EV::timer 0.1, 0.1, sub {
    return unless $nats->is_connected;
    undef $nats_connected;

    my $sid;
    $sid = $nats->subscribe('test.>', sub {
        my ($subject, $payload, $reply) = @_;
        push @received, { subject => $subject, payload => $payload };

        if (@received == 3) {
            is scalar @received, 3, 'received 3 messages';
            is $received[0]{subject}, 'test.foo', 'subject 1';
            is $received[0]{payload}, 'hello', 'payload 1';
            is $received[1]{subject}, 'test.bar', 'subject 2';
            is $received[2]{payload}, 'three', 'payload 3';

            $nats->unsubscribe($sid);
            $nats->disconnect;
            EV::break;
        }
    });

    my $pub_timer; $pub_timer = EV::timer 0.1, 0, sub {
        undef $pub_timer;
        $nats->publish('test.foo', 'hello');
        $nats->publish('test.bar', 'world');
        $nats->publish('test.baz', 'three');
    };
};

EV::run;

ok @received >= 3, 'all messages received';
