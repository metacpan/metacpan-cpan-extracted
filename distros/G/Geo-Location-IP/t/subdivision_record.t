#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Test::More;

use Geo::Location::IP::Record::Subdivision;

my %fields = (
    names => {
        de => 'Baden-Württemberg',
        en => 'Baden-Württemberg',
        fr => 'Bade-Wurtemberg',
    },
    confidence => 100,
    geoname_id => 2953481,
    iso_code   => 'BW',
);

my $subdivision = new_ok 'Geo::Location::IP::Record::Subdivision' =>
    [%fields, locales => ['de', 'en']];

can_ok $subdivision, qw(name), keys %fields;

is $subdivision->name, $fields{names}->{de}, 'name is German';

is_deeply $subdivision->names, $fields{names}, 'names match';

cmp_ok $subdivision->confidence, '==', $fields{confidence},
    'confidence matches';

cmp_ok $subdivision->geoname_id, '==', $fields{geoname_id},
    'geoname_id matches';

is $subdivision->iso_code, $fields{iso_code}, 'subdivision code matches';

done_testing;
