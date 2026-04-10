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

plan tests => 12;

my $guard = EV::timer 15, 0, sub { fail 'global timeout'; EV::break };

my $nats;
$nats = EV::Nats->new(
    host       => $host,
    port       => $port,
    on_error   => sub { diag "error: @_" },
    connect_timeout => 5000,
);

my $ready; $ready = EV::timer 0.1, 0.1, sub {
    return unless $nats->is_connected;
    undef $ready;

    # --- stats ---
    my %s0 = $nats->stats;
    is $s0{msgs_out}, 0, 'stats: msgs_out starts at 0';

    $nats->publish('stats.test', 'x' x 50) for 1..10;
    my %s1 = $nats->stats;
    is $s1{msgs_out}, 10, 'stats: 10 msgs_out';
    is $s1{bytes_out}, 500, 'stats: 500 bytes_out';
    $nats->reset_stats;
    my %s2 = $nats->stats;
    is $s2{msgs_out}, 0, 'stats: reset';

    # --- new_inbox ---
    my $inbox1 = $nats->new_inbox;
    my $inbox2 = $nats->new_inbox;
    ok $inbox1 ne $inbox2, 'new_inbox unique';
    like $inbox1, qr/^_INBOX\./, 'new_inbox prefix';

    # --- subscription_count ---
    my $s0c = $nats->subscription_count;
    my $sid_a = $nats->subscribe('sc.a', sub {});
    my $sid_b = $nats->subscribe('sc.b', sub {});
    is $nats->subscription_count, $s0c + 2, 'subscription_count';
    $nats->unsubscribe($sid_a);
    $nats->unsubscribe($sid_b);

    # --- wildcard * ---
    my @wc_star;
    my $wc_sid = $nats->subscribe('wc.*.end', sub { push @wc_star, $_[0] });

    # --- wildcard > ---
    my @wc_gt;
    my $gt_sid = $nats->subscribe('gt.>', sub { push @wc_gt, $_[0] });

    # --- flush with callback ---
    my $flushed = 0;

    my $t; $t = EV::timer 0.1, 0, sub {
        undef $t;
        $nats->publish('wc.a.end', '');
        $nats->publish('wc.b.end', '');
        $nats->publish('wc.a.b.end', '');  # no match for *
        $nats->publish('gt.a', '');
        $nats->publish('gt.a.b', '');
        $nats->publish('gt.a.b.c', '');

        $nats->flush(sub {
            $flushed = 1;
        });

        my $c; $c = EV::timer 0.5, 0, sub {
            undef $c;
            is scalar @wc_star, 2, 'wildcard *: matched 2';
            is scalar @wc_gt, 3, 'wildcard >: matched 3';
            ok $flushed, 'flush callback fired';

            # --- subscribe_max ---
            my $max_got = 0;
            $nats->subscribe_max('smax.test', sub { $max_got++ }, 3);
            my $p; $p = EV::timer 0.1, 0, sub {
                undef $p;
                $nats->publish('smax.test', 'x') for 1..10;
                my $d; $d = EV::timer 0.5, 0, sub {
                    undef $d;
                    is $max_got, 3, 'subscribe_max: got exactly 3';
                    is $nats->is_connected, 1, 'still connected';

                    $nats->disconnect;
                    EV::break;
                };
            };
        };
    };
};

EV::run;
