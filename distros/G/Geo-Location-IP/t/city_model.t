#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Test::More;

use Geo::Location::IP::Address;
use Geo::Location::IP::Network;
use Geo::Location::IP::Model::City;
use Scalar::Util qw(looks_like_number);

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
    city                => {names             => {en => 'Berlin'}},
    continent           => {names             => {en => 'Europe'}},
    country             => {names             => {en => 'Germany'}},
    location            => {latitude          => 52.52, longitude => 13.41},
    maxmind             => {queries_remaining => 9999},
    registered_country  => {names             => {en => 'Germany'}},
    represented_country => {
        names => {en => 'United States'},
        type  => 'military',
    },
    subdivisions => [{names => {en => 'Berlin'}, iso_code => 'BE'}],
    traits       => {domain => 'example.com'},
);

my $locales = ['en'];

my $model = Geo::Location::IP::Model::City->_from_hash(\%fields, $ip_address,
    $locales);

can_ok $model, keys %fields;

my $city = $model->city;
is $city->name, 'Berlin', 'city is Berlin';

my $continent = $model->continent;
is $continent->name, 'Europe', 'continent is Europe';

my $country = $model->country;
is $country->name, 'Germany', 'country is Germany';

my $location = $model->location;
ok looks_like_number($location->latitude),  'latitude is a number';
ok looks_like_number($location->longitude), 'latitude is a number';

my $maxmind = $model->maxmind;
cmp_ok $maxmind->queries_remaining, '==', 9999, 'queries remaining is 9999';

my $registered_country = $model->registered_country;
is $registered_country->name, 'Germany', 'registered_country is Germany';

my $represented_country = $model->represented_country;
is $represented_country->type, 'military', 'type is "military"';

my $subdivision = $model->most_specific_subdivision;
is $subdivision->iso_code, 'BE', 'ISO code is "BE"';

my $traits = $model->traits;
is $traits->domain, 'example.com', 'domain is "example.com"';

delete $fields{subdivisions};
$model = Geo::Location::IP::Model::City->_from_hash(\%fields, $ip_address,
    $locales);
ok !defined $model->most_specific_subdivision->name,
    'subdivision name is undefined';

done_testing;
