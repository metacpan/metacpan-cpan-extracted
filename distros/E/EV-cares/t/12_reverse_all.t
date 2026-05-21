use strict;
use warnings;
use Test::More;
use File::Temp ();
use EV;
use EV::cares qw(:status);

# empty list fires synchronously
{
    my $got;
    EV::cares->new->reverse_all([], sub { $got = $_[0] });
    is_deeply $got, {}, 'empty list -> empty hashref synchronously';
}

# input validation
{
    my $r = EV::cares->new;
    eval { $r->reverse_all('not-arrayref', sub {}) };
    like($@, qr/arrayref/, 'reverse_all rejects non-arrayref');
    eval { $r->reverse_all([], 'not-coderef') };
    like($@, qr/CODE/, 'reverse_all rejects non-coderef');
    eval { $r->reverse_all(['not-an-ip'], sub {}) };
    like($@, qr/invalid IP/, 'invalid IP propagates from reverse()');
}

# bulk with hosts file (deterministic, no network)
{
    my $tmp = File::Temp->new(SUFFIX => '.hosts');
    print $tmp "10.0.0.1 alpha-host\n10.0.0.2 beta-host\n";
    close $tmp;

    my $r = EV::cares->new(lookups => 'f', hosts_file => $tmp->filename);
    my $got;
    $r->reverse_all(['10.0.0.1', '10.0.0.2', '10.0.0.1'], sub { $got = $_[0] });

    my $t = EV::timer 5, 0, sub { EV::break };
    EV::run until $got;

    is(scalar keys %$got, 2, 'reverse_all dedupes duplicate IPs');
    is($got->{'10.0.0.1'}{status}, ARES_SUCCESS, '10.0.0.1 reverse succeeded');
    ok(grep({ $_ eq 'alpha-host' } @{$got->{'10.0.0.1'}{hosts}}),
        '10.0.0.1 -> alpha-host');
    is($got->{'10.0.0.2'}{status}, ARES_SUCCESS, '10.0.0.2 reverse succeeded');
}

# mid-list invalid IP must fail fast: if validation happens only inside the
# fan-out loop, queries 1..k-1 are dispatched, k croaks, and $cb is silently
# orphaned because $pending never reaches 0
{
    my $r = EV::cares->new;
    my $cb_called = 0;
    eval {
        $r->reverse_all(['127.0.0.1', '::1', 'not-an-ip', '10.0.0.1'],
            sub { $cb_called++ });
    };
    like($@, qr/invalid IP.*not-an-ip/, 'mid-list bad IP croaks');
    is($cb_called, 0, 'no partial dispatch -- $cb not called');
    is($r->active_queries, 0,
        'no queries dispatched before croak (active_queries == 0)');
}

# all-helpers croak on destroyed resolver instead of partial fan-out
{
    my $r = EV::cares->new;
    $r->destroy;
    eval { $r->resolve_all(['x'], sub {}) };
    like($@, qr/destroyed/, 'resolve_all croaks on destroyed');
    eval { $r->reverse_all(['127.0.0.1'], sub {}) };
    like($@, qr/destroyed/, 'reverse_all croaks on destroyed');
    eval { $r->search_all(['x'], 1, sub {}) };
    like($@, qr/destroyed/, 'search_all croaks on destroyed');
    eval { $r->resolve_ttl_all(['x'], sub {}) };
    like($@, qr/destroyed/, 'resolve_ttl_all croaks on destroyed');
}

done_testing;
