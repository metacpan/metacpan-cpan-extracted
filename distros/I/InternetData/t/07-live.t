use strict;
use warnings;

use Test::More;
use InternetData;

# Hits production, so it costs quota and is skipped by default:
#
#   INTERNETDATA_LIVE=1 ./scripts/test.sh t/07-live.t
#
# It exists for the one claim a stub cannot make honestly: that a lookup without
# a key really does omit the fields a key adds rather than answering false.
plan skip_all => 'set INTERNETDATA_LIVE=1 to run the live checks'
    unless $ENV{INTERNETDATA_LIVE};

my $client = InternetData->new(
    $ENV{INTERNETDATA_API_KEY} ? (api_key => $ENV{INTERNETDATA_API_KEY}) : (),
);

subtest 'a known address' => sub {
    my $result = $client->lookup('146.70.116.130');
    is($result->ip, '146.70.116.130', 'the address comes back normalized');
    is($result->is_bogon, 0, 'served, and no bogon');
    is($result->asn->{asn}, 9009, 'announced by its AS');
    ok(length $result->company->{name}, 'and held by a company');
};

subtest 'an ordinary public address, an AS and a domain without a key' => sub {
    plan skip_all => 'a key raises the plan, so the shape without one no longer applies'
        if $ENV{INTERNETDATA_API_KEY};

    my $result = $client->lookup('1.1.1.1');
    is($result->has('is_anycast'), 1, 'is_anycast is on every answer');
    is($result->has('is_hosting'), 0, 'the hosting flag is ABSENT without a key');
    is($result->is_hosting, undef, 'so it reads as undef, not as false');
    is($result->is_hosting // 0, 0, 'and as false only when you ask for that');
    is($result->has('vpn'), 0, 'and so is the VPN detail');
    ok(!exists $result->location->{city}, 'and the city inside location');

    my $as = $client->lookup_asn(9009);
    is($as->name, 'M247 Europe SRL', 'an AS answers its operator');
    is($as->has('type'), 0, 'and not its type');
    my $domain = $client->lookup_domain('example.com');
    is($domain->is_registered, 1, 'a domain answers whether it is registered');
    is($domain->has('dns'), 0, 'and not its records');
};

subtest 'a batch mixes served and local answers' => sub {
    # A client of its own and no cache, so no answer comes from the lookups above.
    my $fresh = InternetData->new(
        cache_size => 0,
        $ENV{INTERNETDATA_API_KEY} ? (api_key => $ENV{INTERNETDATA_API_KEY}) : (),
    );
    my $answers = $fresh->lookup_batch(['146.70.116.130', '8.8.8.8', '10.0.0.1', '146.70.116.130']);
    is(scalar keys %$answers, 3, 'the duplicate collapsed');
    is($answers->{'10.0.0.1'}->is_bogon, 1, 'the local answer');
    if ($ENV{INTERNETDATA_API_KEY}) {
        my $served = $answers->{'146.70.116.130'};
        ok($served->isa('InternetData::Result') || $served->kind eq 'bad_request',
            'the served answer, or the refusal a free plan gets');
        return;
    }
    # POST /batch needs a key on a paid plan, so without one every address sent to it is refused.
    my $refused = $answers->{'146.70.116.130'};
    isa_ok($refused, 'InternetData::Error');
    is($refused->kind, 'unauthorized', 'a batch without a key is refused');
    is($refused->status, 401, 'with a 401');
};

done_testing();
