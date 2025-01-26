#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Test::More;

use Geo::Location::IP::Record::Continent;

my %fields = (
    names => {
        de      => 'Europa',
        en      => 'Europe',
        'zh-CN' => '欧洲',
    },
    geoname_id => 6255148,
    code       => 'EU',
);

my $continent = new_ok 'Geo::Location::IP::Record::Continent' =>
    [%fields, locales => ['zh-CN', 'en']];

can_ok $continent, qw(name), keys %fields;

is $continent->name, $fields{names}->{'zh-CN'}, 'name is Chinese';

is_deeply $continent->names, $fields{names}, 'names match';

cmp_ok $continent->geoname_id, '==', $fields{geoname_id},
    'geoname_id matches';

is $continent->code, $fields{code}, 'code is "EU"';

done_testing;
