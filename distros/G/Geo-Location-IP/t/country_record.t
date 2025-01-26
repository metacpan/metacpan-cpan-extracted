#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Test::More;

use Geo::Location::IP::Record::Country;

my %fields = (
    names => {
        de => 'Deutschland',
        en => 'Germany',
        fr => 'Allemagne',
    },
    confidence           => 100,
    geoname_id           => 2921044,
    is_in_european_union => 1,
    iso_code             => 'DE',
);

my $country = new_ok 'Geo::Location::IP::Record::Country' =>
    [%fields, locales => ['fr', 'en']];

can_ok $country, qw(name), keys %fields;

is $country->name, $fields{names}->{fr}, 'name is French';

is_deeply $country->names, $fields{names}, 'names match';

cmp_ok $country->confidence, '==', $fields{confidence}, 'confidence matches';

cmp_ok $country->geoname_id, '==', $fields{geoname_id}, 'geoname_id matches';

ok $country->is_in_european_union, 'country is in European Union';

is $country->iso_code, $fields{iso_code}, 'country code matches';

done_testing;
