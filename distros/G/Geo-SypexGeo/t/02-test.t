use strict;
use warnings;
use utf8;

use Test::More tests => 4;

use Geo::SypexGeo;

my $geo = Geo::SypexGeo->new('data/SxGeoCity.dat');

my $info = $geo->parse('87.250.250.203');
is( $info->city(),    'Москва', 'City founded ok' );
is( $info->country(), 'ru',           'Country founded ok' );

## test for deprecated methods
my $city = $geo->get_city('87.250.250.203');
is( $city, 'Москва', 'City founded ok' );

## test for deprecated methods
my $country = $geo->get_country('87.250.250.203');
is( $country, 'ru', 'Country founded ok' );

