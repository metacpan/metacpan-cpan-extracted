use strict;
use warnings;
use Test::More;
use EV;
use EV::cares qw(:all);

# --- is_busy: idle resolver ---
{
    my $r = EV::cares->new;
    ok(!$r->is_busy, 'is_busy false on fresh resolver');
    is($r->active_queries, 0, 'active_queries matches');
}

# --- is_busy: with pending query ---
{
    my $r = EV::cares->new(timeout => 5, tries => 1);
    $r->resolve('unlikely-host-xyz.invalid', sub { });
    ok($r->is_busy, 'is_busy true while query pending');
    $r->cancel;
    # drain the cancellation callback
    EV::run(EV::RUN_NOWAIT) for 1..3;
    ok(!$r->is_busy, 'is_busy false after cancel drains');
}

# --- wait_idle: already idle returns immediately ---
{
    my $r = EV::cares->new;
    my $t0 = EV::time;
    my $drained = $r->wait_idle(5);
    ok($drained, 'wait_idle on idle resolver returns true');
    cmp_ok(EV::time - $t0, '<', 0.1, 'wait_idle on idle is immediate');
}

# --- wait_idle: drains pending queries (file lookup, fast) ---
{
    my $r = EV::cares->new(lookups => 'f');
    my @completed;
    for (1..3) {
        $r->resolve('localhost', sub { push @completed, $_[0] });
    }
    ok($r->is_busy || @completed == 3,
        'queries queued (or completed synchronously)');
    my $drained = $r->wait_idle(5);
    ok($drained, 'wait_idle returns true when channel drains');
    is(scalar @completed, 3, 'all 3 callbacks fired');
    ok(!$r->is_busy, 'resolver is idle after wait_idle');
}

# --- wait_idle: timeout when a query is genuinely in-flight ---
# 192.0.2.1 is RFC 5737 TEST-NET-1 — a guaranteed black-hole address that
# routes nowhere on the public Internet.  c-ares will sit on it until its
# own timeout fires.  If the platform refuses outbound traffic to TEST-NET
# instantly (some hardened firewalls), the query may complete fast — skip
# the timing assertions in that case.
{
    my $r = EV::cares->new(timeout => 10, tries => 1);
    $r->set_servers('192.0.2.1');
    my $done;
    $r->resolve('unlikely-name.invalid', sub { $done = 1 });
    SKIP: {
        skip 'query against TEST-NET resolved too fast on this platform', 2
            if $done || !$r->is_busy;
        my $t0 = EV::time;
        my $drained = $r->wait_idle(1);
        ok(!$drained, 'wait_idle returns false when timeout elapses');
        my $elapsed = EV::time - $t0;
        cmp_ok($elapsed, '>=', 0.9, "elapsed >=~1s (actual: ${elapsed}s)");
    }
    # clean up — query may still be in flight
    $r->cancel if $r->is_busy;
    $r->wait_idle(2);
}

# --- wait_idle: croaks on destroyed resolver ---
{
    my $r = EV::cares->new;
    $r->destroy;
    eval { $r->wait_idle(1) };
    like($@, qr/destroyed/, 'wait_idle croaks on destroyed resolver');
}

# --- wait_idle with custom EV::Loop ---
# Earlier versions used EV::run/EV::timer (default loop) regardless of
# whether the resolver was constructed with `loop => $custom`, which made
# wait_idle hang on custom-loop resolvers.  This test catches that.
{
    my $custom = EV::Loop->new;
    my $r = EV::cares->new(loop => $custom, lookups => 'f');
    is(ref $r->loop, 'EV::Loop', 'loop() returns the custom EV::Loop');

    my $r2 = EV::cares->new(lookups => 'f');
    ok(!defined $r2->loop, 'loop() is undef on default-loop resolver');

    my $fired;
    $r->resolve('localhost', sub { $fired = 1 });
    ok($r->is_busy || $fired, 'query pending or fired synchronously');
    my $drained = $r->wait_idle(3);
    ok($drained, 'wait_idle drains on a custom EV::Loop');
    ok($fired, 'callback ran during wait_idle on custom loop');
}

done_testing;
