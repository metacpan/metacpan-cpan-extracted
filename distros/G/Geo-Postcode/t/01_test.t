#!/usr/bin/perl -w

use strict;
use warnings;

use DBI;
use Test::More;

$|++;

BEGIN {
    plan (tests => 38);
    use_ok('Geo::Postcode');
}



my $postcode = Geo::Postcode->new('la233pa');
isa_ok($postcode, 'Geo::Postcode', 'construction ok:');

is( $postcode->valid, 'LA23 3PA', "validation");
is( $postcode->area, 'LA', "area");
is( $postcode->district, 'LA23', "district");
is( $postcode->sector, 'LA23 3', "sector");
is( $postcode->unit, 'LA23 3PA', "unit");
is( scalar($postcode), 'LA23 3PA', "stringwise");
is_deeply( $postcode->analyse, ['LA23 3PA', 'LA23 3', 'LA23', 'LA'], "segmentation");

is (Geo::Postcode->sector('LA23 3PA'), 'LA23 3', "procedural interface");
is (Geo::Postcode->valid_fragment('LA23 3'), 1, "valid fragment");
is (Geo::Postcode->valid_fragment('LA233'), 1, "valid fragment");
is (Geo::Postcode->valid_fragment('Q23'), undef, "invalid fragment");

my @valid_postcodes = ('N12 0PJ','N20 0AD');

foreach my $valid (@valid_postcodes) {
    is(Geo::Postcode->valid($valid), $valid, "Valid: $valid");    
    my $no_space = $valid;
    $no_space =~ s/\s+//g;
    is(Geo::Postcode->valid($no_space), $valid, "Valid: $valid");    
}

my @invalid_postcodes = (
    '23 3PA', # Must start with character
    'QA23 3PA',
    'LZ23 3PA',
    'EC1Z 8PQ',
    'LA23 3KA',
    'LA23 3PK',
    'LAA23 3PA',
);

foreach my $invalid (@invalid_postcodes) {
    is (Geo::Postcode->valid($invalid), undef, "bad format:'$invalid' properly rejected");    
}

isa_ok($postcode->location, 'Geo::Postcode::Location', 'location object');
is($postcode->gridn, 497700, 'grid north');
is($postcode->gride, 340800, 'grid east');
is($postcode->lat, 54.371, 'grid latitude');
is($postcode->long, -2.911, 'grid longitude');

is($postcode->gridref, 'SD408977', 'OS gridref');

is($postcode->distance_from('EC1Y 8PQ'), 369, 'distance_from with string and defaults');

my $other = Geo::Postcode->new('ec1y8pq');

is($postcode->distance_from($other,'miles'), 229, 'distance_from with object and units');
is($postcode->distance_between($other,'miles'), 229, 'aka distance_between');
is($postcode->bearing_to($other,'miles'), 211, 'bearing_to');
is($postcode->friendly_bearing_to($other,'miles'), 'SSE', 'friendly_bearing_to');

my $hmm = Geo::Postcode->new('la233pa', {
	distance_units => 'm',
});

is($hmm->distance_from($other), 369069, 'units set at construction time');

my $hmmm = Geo::Postcode->new('la233pa', {
	location_class => 'My::Own',
});

is($hmmm->location_class, 'My::Own', 'location class set at construction time');

$hmmm->location_class('Geo::Postcode::Location');

is($hmmm->gridref, 'SD408977', 'location class mutator');
