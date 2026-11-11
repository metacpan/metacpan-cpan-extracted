#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use Test::More;

eval "require Map::Tube::Plugin::FuzzyFind";
plan skip_all => "Map::Tube::Plugin::FuzzyFind required for this test" if $@;
eval "use Map::Tube::Glasgow";
plan skip_all => "Map::Tube::Glasgow required for this test" if $@;
plan tests => 7;

use_ok('Map::Tube::Generic');

diag( "Testing Map::Tube::Generic $Map::Tube::Generic::VERSION, Perl $], $^X" );

my $map = Map::Tube::Generic->new( { location => 'Glasgow', nametype => 'alt' } );
can_ok( $map, qw(fuzzy_find) );

my $station;

$station = $map->fuzzy_find( search => 'Ibrox', objects => 'stations' );
is( $station, 'Ibrox (SPT)', 'Full match' );

$station = $map->fuzzy_find( search => 'rox', objects => 'stations' );
ok( !$station, 'Failing full match' );

$station = $map->fuzzy_find( search => 'Ibr', objects => 'stations', method => 'start' );
is( $station, 'Ibrox (SPT)', 'Start' );

$station = $map->fuzzy_find( search => 'rox', objects => 'stations', method => 'in' );
is( $station, 'Ibrox (SPT)', 'In' );

$station = $map->fuzzy_find( search => 'Yprox', objects => 'stations', method => 'Levenshtein' );
is( $station, 'Ibrox (SPT)', 'Levenshtein' );

done_testing;
