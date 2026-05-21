use strict;
use warnings;
use Test::More;
use File::Temp ();
use EV;
use EV::cares qw(:status);

# bad input croaks
{
    my $r = EV::cares->new;
    eval { $r->resolve_all('not-an-arrayref', sub {}) };
    like($@, qr/arrayref/, 'non-arrayref croaks');
    eval { $r->resolve_all(undef, sub {}) };
    like($@, qr/arrayref/, 'undef names croaks');
    eval { $r->resolve_all([], 'not-a-coderef') };
    like($@, qr/CODE reference/, 'non-coderef croaks');
}

# empty list fires immediately
{
    my $got;
    EV::cares->new(lookups => 'f')->resolve_all([], sub { $got = $_[0] });
    is_deeply $got, {}, 'empty list -> empty hashref synchronously';
}

# distinct names + duplicates: dedup, two entries for two unique names
{
    my $tmp = File::Temp->new(SUFFIX => '.hosts');
    print $tmp "10.0.0.1 alpha-host\n10.0.0.2 beta-host\n";
    close $tmp;

    my $r = EV::cares->new(lookups => 'f', hosts_file => $tmp->filename);
    my $got;
    $r->resolve_all(['alpha-host', 'beta-host', 'alpha-host'], sub { $got = $_[0] });

    my $t = EV::timer 5, 0, sub { EV::break };
    EV::run until $got;

    is(scalar keys %$got, 2, 'duplicate names dedup to one entry per unique name');
    is($got->{'alpha-host'}{status}, ARES_SUCCESS, 'alpha-host succeeded');
    is($got->{'beta-host'}{status},  ARES_SUCCESS, 'beta-host succeeded');
    ok(grep({ $_ eq '10.0.0.1' } @{$got->{'alpha-host'}{addrs}}), 'alpha resolves to 10.0.0.1');
    ok(grep({ $_ eq '10.0.0.2' } @{$got->{'beta-host'}{addrs}}),  'beta resolves to 10.0.0.2');
}

# arrayref with one name still fans out cleanly
{
    my $r = EV::cares->new(lookups => 'f');
    my $got;
    $r->resolve_all(['localhost'], sub { $got = $_[0] });

    my $t = EV::timer 5, 0, sub { EV::break };
    EV::run until $got;

    is(scalar keys %$got, 1, 'single-name list -> single entry');
    is($got->{localhost}{status}, ARES_SUCCESS, 'localhost succeeded');
}

# resolve_ttl_all: dedup + records (with TTL hashref shape) + multiple unique names
{
    my $tmp = File::Temp->new(SUFFIX => '.hosts');
    print $tmp "10.0.0.1 alpha-host\n10.0.0.2 beta-host\n";
    close $tmp;

    my $r = EV::cares->new(lookups => 'f', hosts_file => $tmp->filename);
    my $got;
    $r->resolve_ttl_all(['alpha-host', 'beta-host', 'alpha-host'],
        sub { $got = $_[0] });

    my $t = EV::timer 5, 0, sub { EV::break };
    EV::run until $got;

    is(scalar keys %$got, 2, 'resolve_ttl_all dedupes duplicate names');
    is($got->{'alpha-host'}{status}, ARES_SUCCESS, 'alpha succeeded');
    is($got->{'beta-host'}{status},  ARES_SUCCESS, 'beta succeeded');
    is(ref $got->{'alpha-host'}{records}, 'ARRAY',
        'records is an arrayref');
    ok(@{$got->{'alpha-host'}{records}} > 0, 'alpha has at least one record');
    is(ref $got->{'alpha-host'}{records}[0], 'HASH',
        'each record is a TTL hashref');
    ok(exists $got->{'alpha-host'}{records}[0]{addr},
        'TTL record has addr field');
    ok(exists $got->{'alpha-host'}{records}[0]{ttl},
        'TTL record has ttl field');
}

# resolve_ttl_all input validation
{
    my $r = EV::cares->new;
    eval { $r->resolve_ttl_all('not-arrayref', sub {}) };
    like($@, qr/arrayref/, 'resolve_ttl_all rejects non-arrayref');
    eval { $r->resolve_ttl_all([], 'not-coderef') };
    like($@, qr/CODE/, 'resolve_ttl_all rejects non-coderef');
    my $got;
    $r->resolve_ttl_all([], sub { $got = $_[0] });
    is_deeply $got, {}, 'resolve_ttl_all empty list -> empty hashref';
}

done_testing;
