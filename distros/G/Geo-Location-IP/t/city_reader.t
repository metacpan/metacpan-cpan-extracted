#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Test::More;

use File::Spec::Functions qw(catfile);
use Geo::Location::IP::Database::Reader;
use Scalar::Util qw(looks_like_number);

my $file    = catfile(qw(t data Test-City.mmdb));
my $locales = ['de', 'en'];

my $reader = new_ok 'Geo::Location::IP::Database::Reader' =>
    [file => $file, locales => $locales];
can_ok $reader, qw(city file locales metadata);
is $reader->file, $file, 'file matches';
is_deeply $reader->locales, $locales, 'locales match';
my $metadata = $reader->metadata;
like $metadata->database_type, qr{City}, 'is a City database';

ok !eval { $reader->city(ip => '192.0.2.1') },
    'no result for unknown IP address';

my $ip = '176.9.54.163';

my $model = $reader->city(ip => $ip);

my $city = $model->city;
is $city->name, 'Falkenstein', 'city name is "Falkenstein"';
isa_ok $city->names, 'HASH';
cmp_ok $city->confidence, '==', 100,     'city confidence is 100';
cmp_ok $city->geoname_id, '==', 2927913, 'city geoname_id is 2927913';

my $continent = $model->continent;
is $continent->name, 'Europa', 'continent name is "Europa"';
isa_ok $continent->names, 'HASH';
is $continent->code, 'EU', 'continent code is "EU"';
cmp_ok $continent->geoname_id, '==', 6255148,
    'continent geoname_id is 6255148';

my $country = $model->country;
is $country->name, 'Deutschland', 'country name is "Deutschland"';
isa_ok $country->names, 'HASH';
cmp_ok $country->confidence, '==', 100,     'country confidence is 100';
cmp_ok $country->geoname_id, '==', 2921044, 'country geoname_id is 2921044';
ok $country->is_in_european_union, 'country is in European union';
is $country->iso_code, 'DE', 'country code is "DE"';

my $location = $model->location;
cmp_ok $location->accuracy_radius, '==', 10,     'accuracy_radius is 10';
cmp_ok $location->average_income,  '==', 23_702, 'average_income is 23702';
ok looks_like_number($location->latitude),  'latitude is a number';
ok looks_like_number($location->longitude), 'longitude is a number';
cmp_ok $location->population_density, '==', 157, 'population_density is 157';
is $location->time_zone, 'Europe/Berlin', 'time_zone is "Europe/Berlin"';

my $postal = $model->postal;
is $postal->code, '08223', 'postal code is "08223"';
cmp_ok $postal->confidence, '==', 100, 'postal confidence is 100';

my $registered_country = $model->registered_country;
is $registered_country->name, 'Deutschland',
    'registered country is "Deutschland"';

my $represented_country = $model->represented_country;
is $represented_country->name, 'USA', 'represented country is "USA"';
isa_ok $represented_country->names, 'HASH';
cmp_ok $represented_country->confidence, '==', 0,
    'represented country confidence is 0';
cmp_ok $represented_country->geoname_id, '==', 6252001,
    'represented country geoname_id is 6252001';
ok !$represented_country->is_in_european_union,
    'represented country is not in European union';
is $represented_country->iso_code, 'US', 'represented country code is "US"';
is $represented_country->type, 'military',
    'represented country type is "military"';

my @subdivisions = $model->subdivisions;
cmp_ok scalar @subdivisions, '==', 2, 'location has two subdivisions';

is $subdivisions[0]->name, 'Sachsen', 'state is "Sachsen"';
cmp_ok $subdivisions[0]->confidence, '==', 100, 'state confidence is 100';
cmp_ok $subdivisions[0]->geoname_id, '==', 2842566,
    'state geoname_id is 2842566';
is $subdivisions[0]->iso_code, 'SN', 'state code is "SN"';

is $subdivisions[1]->name, 'Vogtlandkreis', 'county is "Vogtlandkreis"';
cmp_ok $subdivisions[1]->confidence, '==', 100, 'county confidence is 100';
cmp_ok $subdivisions[1]->geoname_id, '==', 6547384,
    'county geoname_id is 6547384';
ok !defined $subdivisions[1]->iso_code, 'county has no ISO code';

my $county = $model->most_specific_subdivision;
is $county->name, 'Vogtlandkreis',
    'most specific subdivision is "Vogtlandkreis"';

my $traits = $model->traits;
is $traits->domain, 'example.com', 'domain is "example.com"';

my $ip_address = $traits->ip_address;
is $ip_address, $ip, 'IP address matches';
cmp_ok $ip_address->version, '==', 4, 'is IPv4 address';

my $network = $ip_address->network;
is $network, '176.9.0.0/16', 'network is "176.9.0.0/16"';
cmp_ok $network->version, '==', 4, 'is IPv4 network';

done_testing;
