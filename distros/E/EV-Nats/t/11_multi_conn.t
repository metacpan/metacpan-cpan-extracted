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

plan tests => 6;

my $guard = EV::timer 10, 0, sub { fail 'timeout'; EV::break };

my ($a_ready, $b_ready, $c_ready) = (0, 0, 0);

# Three independent connections
my ($a, $b, $c);

$a = EV::Nats->new(
    host => $host, port => $port,
    on_error => sub { diag "A error: @_" },
    on_connect => sub { $a_ready = 1 },
);
$b = EV::Nats->new(
    host => $host, port => $port,
    on_error => sub { diag "B error: @_" },
    on_connect => sub { $b_ready = 1 },
);
$c = EV::Nats->new(
    host => $host, port => $port,
    on_error => sub { diag "C error: @_" },
    on_connect => sub { $c_ready = 1 },
);

my $poll; $poll = EV::timer 0.1, 0.1, sub {
    return unless $a_ready && $b_ready && $c_ready;
    undef $poll;

    pass 'all three connections established';

    my @got_b;
    my @got_c;

    # B and C subscribe to same subject
    $b->subscribe('multi.test', sub {
        my ($subj, $payload) = @_;
        push @got_b, $payload;
    });
    $c->subscribe('multi.test', sub {
        my ($subj, $payload) = @_;
        push @got_c, $payload;
    });

    # A publishes
    my $pub; $pub = EV::timer 0.1, 0, sub {
        undef $pub;
        $a->publish('multi.test', "from-a-$_") for 1..5;

        my $check; $check = EV::timer 0.5, 0, sub {
            undef $check;
            is scalar @got_b, 5, 'B received all 5 messages';
            is scalar @got_c, 5, 'C received all 5 messages';
            is $got_b[0], 'from-a-1', 'B got correct first message';
            is $got_c[4], 'from-a-5', 'C got correct last message';

            # Cross-connection request/reply: B responds, A requests
            $b->subscribe('multi.svc', sub {
                my ($subj, $payload, $reply) = @_;
                $b->publish($reply, "reply-from-b") if $reply;
            });

            my $req; $req = EV::timer 0.1, 0, sub {
                undef $req;
                $a->request('multi.svc', 'hello', sub {
                    my ($resp, $err) = @_;
                    is $resp, 'reply-from-b', 'cross-connection request/reply works';
                    $_->disconnect for $a, $b, $c;
                    EV::break;
                }, 5000);
            };
        };
    };
};

EV::run;
