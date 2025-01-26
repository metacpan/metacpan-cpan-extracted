#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Test::More;

use Geo::Location::IP::Record::Location;

my %fields = (
    accuracy_radius    => 5,
    average_income     => 23_952,
    latitude           => 52.52,
    longitude          => 13.41,
    metro_code         => undef,
    population_density => 4100,
    time_zone          => 'Europe/Berlin',
);

my $location = new_ok 'Geo::Location::IP::Record::Location' => [%fields];

can_ok $location, keys %fields;

cmp_ok $location->accuracy_radius, '==', $fields{accuracy_radius},
    'accuracy_radius matches';

cmp_ok $location->average_income, '==', $fields{average_income},
    'average_income matches';

cmp_ok $location->latitude, '==', $fields{latitude}, 'latitude matches';

cmp_ok $location->longitude, '==', $fields{longitude}, 'longitude matches';

ok !defined $location->metro_code, 'metro_code is undefined';

cmp_ok $location->population_density, '==', $fields{population_density},
    'population_density matches';

is $location->time_zone, $fields{time_zone}, 'time_zone matches';

done_testing;
