use strict;
use warnings;
use Test::More;
use EV;
use EV::Memcached;
use FindBin;
use lib "$FindBin::Bin/lib";
use FakeMemcached;

# Queue accounting, teardown signals, constructor clamping. All synchronous.

# --- 1. an mget counts as one command in both queues ---
# Entries are internal fan-out; only the fence counts (pending already
# works this way via counted=0).
{
    my $srv = FakeMemcached->new(script => sub { sleep 5 });
    my $mc = EV::Memcached->new(
        path => $srv->path, max_pending => 1, on_error => sub {});
    # Issued while connecting -> all parked in the waiting queue.
    $mc->get('blocker', sub {});
    $mc->mget(['a', 'b'], sub {});
    is($mc->waiting_count, 2, 'waiting: blocker + mget fence');
    is($mc->pending_count, 0, 'pending: nothing sent yet');
    $srv->finish;
}

# --- 2. disconnect() while connecting fires on_disconnect ---
# POD promises disconnect fires on_disconnect; a cancelled in-progress
# connect must signal completion the same way an established one does.
{
    my $srv = FakeMemcached->new(script => sub { sleep 5 });
    my ($fired_disc, @errors);
    my $mc = EV::Memcached->new(on_error => sub { push @errors, "@_" });
    $mc->on_disconnect(sub { $fired_disc = 1 });
    $mc->connect_unix($srv->path);
    ok($mc->is_connected, 'connect in progress reads connected');
    $mc->disconnect;
    ok($fired_disc, 'on_disconnect fired for cancelled connect');
    is(scalar @errors, 0, 'intentional teardown stays silent');
    ok(!$mc->is_connected, 'disconnected after teardown');
    $srv->finish;
}

# --- 3. constructor clamps priority like the setter ---
{
    my $hi = EV::Memcached->new(priority => 100, on_error => sub {});
    is($hi->priority, 2, 'priority clamped to +2');
    my $lo = EV::Memcached->new(priority => -100, on_error => sub {});
    is($lo->priority, -2, 'priority clamped to -2');
}

done_testing();
