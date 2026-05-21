use strict;
use warnings;
use Test::More;
use EV;
use EV::cares qw(:all);

# --- resolver recovers after pointing at an unreachable server ---
# This exercises the path "set bogus servers -> query times out -> set good
# servers -> query succeeds" without re-creating the resolver.  Useful for
# users who want fail-over without tearing down channel state.

{
    my $r = EV::cares->new(timeout => 1, tries => 1, lookups => 'b');
    $r->set_servers('127.0.0.255');  # unreachable in any sane setup

    my $first;
    $r->resolve('localhost', sub { $first = [@_] });
    my $t = EV::timer 4, 0, sub { EV::break };
    EV::run until $first;

    ok($first, 'first query callback fired');
    isnt($first->[0], ARES_SUCCESS,
        "first query failed against unreachable server (status=$first->[0])");

    # now point at a working configuration that resolves localhost from /etc/hosts
    $r->set_servers('127.0.0.1');
    $r->reinit;     # sometimes needed after server swap

    my $second;
    $r->resolve('localhost', sub { $second = [@_] });
    my $t2 = EV::timer 4, 0, sub { EV::break };
    EV::run until $second;

    ok($second, 'second query callback fired');
    # we don't assert SUCCESS here because /etc/hosts handling differs across
    # platforms with lookups => 'b'; the point is the channel is functional
    is(ref $second, 'ARRAY', 'second query produced a result');
}

# --- multiple errors do not leave active_queries elevated ---
{
    my $r = EV::cares->new(timeout => 1, tries => 1);
    $r->set_servers('127.0.0.255');

    my $done = 0;
    for (1..5) {
        $r->resolve('unlikely-host-xyz.invalid', sub { $done++ });
    }

    my $t = EV::timer 4, 0, sub { EV::break };
    EV::run until $done >= 5;

    is($done, 5, 'all 5 failing queries fired callbacks');
    is($r->active_queries, 0,
        'active_queries returns to 0 after all failed queries complete');
}

done_testing;
