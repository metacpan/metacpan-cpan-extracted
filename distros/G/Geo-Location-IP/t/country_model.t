#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Test::More;

use Geo::Location::IP::Address;
use Geo::Location::IP::Network;
use Geo::Location::IP::Model::Country;

my $ip = '1.2.3.4';

my $network = Geo::Location::IP::Network->new(
    address   => $ip,
    prefixlen => 24,
);

my $ip_address = Geo::Location::IP::Address->new(
    address => $ip,
    network => $network,
);

my %fields = (
    continent           => {names             => {en => 'Europe'}},
    country             => {names             => {en => 'Germany'}},
    maxmind             => {queries_remaining => 9999},
    registered_country  => {names             => {en => 'Germany'}},
    represented_country => {
        names => {en => 'United States'},
        type  => 'military',
    },
    traits => {domain => 'example.com'},
);

my $model = new_ok 'Geo::Location::IP::Model::Country' => [
    raw        => \%fields,
    ip_address => $ip_address,
    locales    => ['en']
];

can_ok $model, keys %fields;

my $continent = $model->continent;
is $continent->name, 'Europe', 'continent is Europe';

my $country = $model->country;
is $country->name, 'Germany', 'country is Germany';

my $maxmind = $model->maxmind;
cmp_ok $maxmind->queries_remaining, '==', 9999, 'queries remaining is 9999';

my $registered_country = $model->registered_country;
is $registered_country->name, 'Germany', 'registered_country is Germany';

my $represented_country = $model->represented_country;
is $represented_country->type, 'military', 'type is "military"';

my $traits = $model->traits;
is $traits->domain, 'example.com', 'domain is "example.com"';

done_testing;
