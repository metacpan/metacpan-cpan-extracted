use strict;
use warnings;
use Test::More;
use EV;
use EV::cares qw(:all);

# resolve_ttl returns hashrefs with addr/family/ttl
{
    my $r = EV::cares->new(lookups => 'f');
    my @got;
    my $done;
    $r->resolve_ttl('localhost', sub { @got = @_; $done = 1 });

    my $t = EV::timer 5, 0, sub { $done = 1 };
    EV::run until $done;

    is($got[0], ARES_SUCCESS, 'resolve_ttl localhost succeeded');
    ok(@got > 1, 'got at least one record');
    isa_ok($got[1], 'HASH', 'first record is a hashref');
    ok(exists $got[1]{addr},   'addr present');
    ok(exists $got[1]{family}, 'family present');
    ok(exists $got[1]{ttl},    'ttl present');
    like($got[1]{family}, qr/^\d+$/, 'family is numeric');

    # localhost resolves to both 127.0.0.1 and ::1 — verify family field
    # is the right value per record (not just present)
    my @records = @got[1..$#got];
    for my $rec (@records) {
        if ($rec->{addr} =~ /:/) {
            is($rec->{family}, AF_INET6, "$rec->{addr} -> family AF_INET6");
        } else {
            is($rec->{family}, AF_INET,  "$rec->{addr} -> family AF_INET");
        }
    }
}

# getaddrinfo with ttl => 1 in hints
{
    my $r = EV::cares->new(lookups => 'f');
    my @got;
    my $done;
    $r->getaddrinfo('localhost', undef, { family => AF_INET, ttl => 1 }, sub {
        @got = @_; $done = 1;
    });

    my $t = EV::timer 5, 0, sub { $done = 1 };
    EV::run until $done;

    is($got[0], ARES_SUCCESS, 'getaddrinfo+ttl localhost succeeded');
    ok(@got > 1, 'got results');
    isa_ok($got[1], 'HASH', 'result is hashref when ttl=>1');
    is($got[1]{family}, AF_INET, 'AF_INET hint honored');
}

# getaddrinfo without ttl returns scalars (regression check)
{
    my $r = EV::cares->new(lookups => 'f');
    my @got;
    my $done;
    $r->getaddrinfo('localhost', undef, { family => AF_INET }, sub {
        @got = @_; $done = 1;
    });

    my $t = EV::timer 5, 0, sub { $done = 1 };
    EV::run until $done;

    is($got[0], ARES_SUCCESS, 'getaddrinfo localhost succeeded');
    ok(!ref $got[1], 'result is scalar without ttl flag');
}

done_testing;
