#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Test::More;

use Geo::Location::IP::Record::City;

my %fields = (
    names => {
        de => 'Köln',
        en => 'Cologne',
        ja => 'ケルン',
    },
    confidence => 100,
    geoname_id => 2886242,
);

my $city = new_ok 'Geo::Location::IP::Record::City' =>
    [%fields, locales => ['ja', 'en']];

can_ok $city, qw(name), keys %fields;

is $city->name, $fields{names}->{ja}, 'name is Japanese';

is_deeply $city->names, $fields{names}, 'names match';

cmp_ok $city->confidence, '==', $fields{confidence}, 'confidence matches';

cmp_ok $city->geoname_id, '==', $fields{geoname_id}, 'geoname_id matches';

done_testing;
