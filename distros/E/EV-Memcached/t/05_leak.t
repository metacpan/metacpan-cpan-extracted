use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Memcached;

eval { require Devel::Refcount };
if ($@) { plan skip_all => "Devel::Refcount not available" }

my $host = $ENV{TEST_MEMCACHED_HOST} || '127.0.0.1';
my $port = $ENV{TEST_MEMCACHED_PORT} || 11211;

my $sock = IO::Socket::INET->new(
    PeerAddr => $host, PeerPort => $port, Proto => 'tcp', Timeout => 1,
);
unless ($sock) { plan skip_all => "No memcached at $host:$port" }
close $sock;

sub run_ev {
    my $t = EV::timer 5, 0, sub { fail("timeout"); EV::break };
    EV::run;
}

# --- basic lifecycle: no leak ---
{
    my $mc = EV::Memcached->new(
        host => $host, port => $port,
        on_error => sub {},
    );
    $mc->on_connect(sub { EV::break });
    run_ev();

    is(Devel::Refcount::refcount($mc), 1, "refcount after connect: 1");

    $mc->set("leak_test", "val", sub {
        $mc->get("leak_test", sub {
            EV::break;
        });
    });
    run_ev();

    is(Devel::Refcount::refcount($mc), 1, "refcount after commands: 1");

    $mc->disconnect;
}

# --- connect/disconnect cycle: no leak ---
{
    for my $i (1..5) {
        my $mc = EV::Memcached->new(
            host => $host, port => $port,
            on_error => sub {},
        );
        $mc->on_connect(sub {
            $mc->set("cycle_$i", "v", sub {
                $mc->disconnect;
                EV::break;
            });
        });
        run_ev();
    }
    pass("5 connect/disconnect cycles without crash");
}

# --- mget lifecycle ---
{
    my $mc = EV::Memcached->new(
        host => $host, port => $port,
        on_error => sub {},
    );
    $mc->on_connect(sub { EV::break });
    run_ev();

    $mc->set("ml_1", "a");
    $mc->set("ml_2", "b");
    $mc->noop(sub {
        $mc->mget(["ml_1", "ml_2", "ml_3"], sub {
            my ($results, $err) = @_;
            is(scalar keys %$results, 2, "mget: 2 hits");
            is(Devel::Refcount::refcount($mc), 1, "refcount after mget: 1");
            $mc->disconnect;
            EV::break;
        });
    });
    run_ev();
}

# --- DESTROY with pending callbacks: every callback fires, no leak ---
# Regression for two distinct bugs:
#   1. cancel_pending_impl previously called check_destroyed unconditionally
#      when magic==FREED, which fired during DESTROY itself (where DESTROY
#      pre-set magic=FREED) and Safefree-d self mid-loop -> UAF.
#   2. DESTROY pre-setting magic=FREED before cancel_pending caused the
#      magic-check inside the loop to bail after the first callback,
#      leaking every remaining cb_queue entry's allocations and SV refs.
{
    my $mc = EV::Memcached->new(
        host => $host, port => $port,
        on_error => sub {},
    );
    $mc->on_connect(sub { EV::break });
    run_ev();

    # Queue multiple commands and break before any response is processed.
    my @fired;
    for my $i (1..5) {
        $mc->set("destroy_multi_$i", "v$i", sub {
            my ($res, $err) = @_;
            push @fired, [$i, $err // 'ok'];
        });
    }
    # Don't EV::run again — let $mc go out of scope with 5 cb_queue entries.
    undef $mc;

    is(scalar @fired, 5, "DESTROY: every pending callback fired, none leaked")
        or diag explain \@fired;
    is_deeply([sort map { $_->[0] } @fired], [1..5],
        "DESTROY: callbacks fired in order");
    is_deeply([map { $_->[1] } @fired], [('disconnected') x 5],
        "DESTROY: each pending callback received 'disconnected' error");
}

done_testing;
