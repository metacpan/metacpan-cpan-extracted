#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use Test::More;

eval "use Map::Tube::Glasgow";
plan skip_all => "Map::Tube::Glasgow required for this test" if $@;

use_ok('Map::Tube::Generic');

diag( "Testing Map::Tube::Generic $Map::Tube::Generic::VERSION, Perl $], $^X" );

my $maps;
$maps = Map::Tube::Generic->list_maps( );
ok( exists $maps->{'Map::Tube::Glasgow'}, 'list of maps contains Glasgow map' );
$maps = Map::Tube::Generic->list_maps( namespace => 'Map::Tube' );
ok( exists $maps->{'Map::Tube::Glasgow'}, 'list of maps contains Glasgow map in namespace Map::Tube' );
$maps = Map::Tube::Generic->list_maps( namespace => 'Map::Tubexxx' );
ok( scalar(keys(%$maps)) == 0, 'no maps contained in namespace Map::Tubexxx' );
$maps = Map::Tube::Generic->list_maps( name => 'Glasgow' );
ok( scalar(keys(%$maps)) == 1, 'one map found matching Glasgow ' . scalar(keys(%$maps)) );
$maps = Map::Tube::Generic->list_maps(  name => 'GLASGOW' );
ok( scalar(keys(%$maps)) == 1, 'one map found matching GLASGOW' );
$maps = Map::Tube::Generic->list_maps(  pattern => 'G.*' );
ok( scalar(keys(%$maps)) >= 1, 'one map found matching G.*' );
$maps = Map::Tube::Generic->list_maps(  pattern => 'G.*', verify => 1 );
ok( scalar(keys(%$maps)) >= 1, 'one verified map found matching G.*' );

done_testing( );

