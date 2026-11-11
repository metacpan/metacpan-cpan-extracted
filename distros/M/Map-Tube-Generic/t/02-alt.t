#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use Test::More;

eval "use Map::Tube::Brussels";
plan skip_all => "Map::Tube::Brussels required for this test" if $@;
eval "use Map::Tube::Glasgow";
plan skip_all => "Map::Tube::Glasgow required for this test" if $@;

use_ok('Map::Tube::Generic');

diag( "Testing Map::Tube::Generic $Map::Tube::Generic::VERSION, Perl $], $^X" );

my( $map, @stations );
$map = Map::Tube::Generic->new( { location => 'Brussels' } );
@stations = ( sort @{ $map->get_stations( ) } )[0..2];
is( join( ' ', @stations), 'Abbaye (8, 93) Acacias (81) Albert (10, 18, 4)', 'Brussels standard names' );

$map = Map::Tube::Generic->new( { location => 'Brussels', nametype => 'alt' } );
@stations = ( sort @{ $map->get_stations( ) } )[0..2];
is( join( ' ', @stations), 'Abdij (8, 93) Acacia (81) Albert (10, 18, 4)', 'Brussels alt names' );

$map = Map::Tube::Generic->new( { location => 'Glasgow', nametype => 'alt' } );
@stations = ( sort @{ $map->get_stations( ) } )[0..2];
is( join( ' ', @stations), 'Bridge Street (SPT) Buchanan Street (SPT) Cessnock (SPT)', 'Glasgow "alt" names' );

done_testing;
