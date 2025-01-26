#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Test::More;

use Geo::Location::IP::Model::Insights;

my $ip = '1.2.3.4';

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
    traits       => {domain => 'example.com', ip_address => $ip},
);

my $model = new_ok 'Geo::Location::IP::Model::Insights' => [
    raw        => \%fields,
    ip_address => undef,
    locales    => undef,
];

can_ok $model, keys %fields;

my $city = $model->city;
is $city->name, 'Berlin', 'city is Berlin';

my $traits     = $model->traits;
my $ip_address = $traits->ip_address;
is $ip_address, $ip, 'IP address matches';

done_testing;
