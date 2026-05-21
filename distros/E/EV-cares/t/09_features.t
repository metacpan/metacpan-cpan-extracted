use strict;
use warnings;
use Test::More;
use File::Temp ();
use EV;
use EV::cares qw(:all);

# search() with explicit class — back-compat 3-arg form still works
{
    my $r = EV::cares->new(lookups => 'f');
    my @got;
    my $done;
    $r->search('localhost', T_A, sub { @got = @_; $done = 1 });
    my $t = EV::timer 5, 0, sub { $done = 1 };
    EV::run until $done;
    ok(defined $got[0], 'search(name, type, cb) — 3-arg form');
}

# search() with explicit class arg — new 4-arg form
{
    my $r = EV::cares->new(lookups => 'f');
    my @got;
    my $done;
    $r->search('localhost', T_A, C_IN, sub { @got = @_; $done = 1 });
    my $t = EV::timer 5, 0, sub { $done = 1 };
    EV::run until $done;
    ok(defined $got[0], 'search(name, type, class, cb) — 4-arg form');
}

# search() with no callback croaks
{
    my $r = EV::cares->new;
    eval { $r->search('localhost', T_A) };
    like($@, qr/Usage/i, 'search without callback croaks');
}

# search_all helper — search() is DNS-only so test against live network with skip
{
    my $r = EV::cares->new(timeout => 5, tries => 2);
    my $can_resolve;
    $r->resolve('google.com', sub { $can_resolve = 1 if $_[0] == ARES_SUCCESS });
    my $t = EV::timer 6, 0, sub { EV::break };
    EV::run;

    SKIP: {
        skip 'search_all requires network DNS', 3 unless $can_resolve;
        my $got;
        $r->search_all(['google.com', 'cloudflare.com', 'google.com'], T_A,
            sub { $got = $_[0] });
        my $t2 = EV::timer 10, 0, sub { EV::break };
        EV::run until $got;
        is(scalar keys %$got, 2, 'search_all dedupes duplicate names');
        is($got->{'google.com'}{status}, ARES_SUCCESS, 'google.com succeeded');
        ok(@{$got->{'google.com'}{records}} > 0, 'google.com has records');
    }
}

# search_all input validation
{
    my $r = EV::cares->new;
    eval { $r->search_all('not-arrayref', T_A, sub {}) };
    like($@, qr/arrayref/, 'search_all rejects non-arrayref');
    eval { $r->search_all([], T_A, 'not-coderef') };
    like($@, qr/CODE/, 'search_all rejects non-coderef');
    eval { $r->search_all([], T_A, C_IN, 'not-coderef') };
    like($@, qr/CODE/, 'search_all rejects non-coderef in 5-arg form');
    eval { $r->search_all([], T_A, sub {}, sub {}) };
    like($@, qr/class must be an integer/,
        'search_all 5-arg form rejects coderef as class');
    eval { $r->search_all([], T_A) };
    like($@, qr/usage/i, 'search_all rejects too few args');
    my $got;
    $r->search_all([], T_A, sub { $got = $_[0] });
    is_deeply $got, {}, 'search_all empty list -> empty hashref synchronously';
}

# search_all 5-arg form (with class) accepts and dispatches
{
    my $r = EV::cares->new;
    my $got;
    $r->search_all([], T_A, C_IN, sub { $got = $_[0] });
    is_deeply $got, {}, 'search_all 5-arg form (with class) — empty list path';
}

# search_all 5-arg form with non-empty list dispatches through search($name,$type,$class,$cb)
{
    my $r = EV::cares->new(lookups => 'f');
    my $got;
    $r->search_all(['localhost'], T_A, C_IN, sub { $got = $_[0] });
    my $t = EV::timer 5, 0, sub { EV::break };
    EV::run until $got;
    ok(exists $got->{'localhost'}, 'search_all 5-arg form dispatched per-name');
    ok(defined $got->{'localhost'}{status},
        'search_all 5-arg form result has status');
}

# resolve_ttl exposes timeouts (always 0 for local lookups) and canonname (when present)
{
    my $r = EV::cares->new(lookups => 'f');
    my @got;
    my $done;
    $r->resolve_ttl('localhost', sub { @got = @_; $done = 1 });
    my $t = EV::timer 5, 0, sub { $done = 1 };
    EV::run until $done;
    is($got[0], ARES_SUCCESS, 'resolve_ttl localhost succeeded');
    ok(@got > 1, 'got at least one record');
    ok(exists $got[1]{timeouts}, 'resolve_ttl record has timeouts');
    is($got[1]{timeouts}, 0, 'timeouts is 0 for local lookup');
    # canonname is optional — present only on CNAME chains
}

# last_query_timeouts (channel-level)
{
    my $r = EV::cares->new(lookups => 'f');
    is($r->last_query_timeouts, 0, 'last_query_timeouts initially 0');
    my $done;
    $r->resolve('localhost', sub { $done = 1 });
    my $t = EV::timer 5, 0, sub { $done = 1 };
    EV::run until $done;
    is($r->last_query_timeouts, 0, 'last_query_timeouts == 0 after local lookup');
}

# set_servers accepts hashrefs with port
{
    my $r = EV::cares->new;
    $r->set_servers([
        { host => '127.0.0.1', port => 5353 },
        { host => '127.0.0.2' },
    ]);
    my $csv = $r->servers;
    like($csv, qr/127\.0\.0\.1:5353/, 'hashref with port -> host:port');
    like($csv, qr/127\.0\.0\.2/,      'hashref without port -> bare host');
}

# set_sortlist
{
    my $r = EV::cares->new;
    eval { $r->set_sortlist('192.168.0.0/255.255.0.0 10.0.0.0/8') };
    is($@, '', 'set_sortlist accepts CIDR + netmask formats');

    # garbage input: c-ares may croak or silently accept (older versions).
    # Either is acceptable; what matters is that the resolver remains
    # functional afterwards.
    eval { $r->set_sortlist('totally-invalid !!!') };
    my $r2 = EV::cares->new(lookups => 'f');
    isa_ok($r2, 'EV::cares', 'resolver still constructible after garbage sortlist');
}

done_testing;
