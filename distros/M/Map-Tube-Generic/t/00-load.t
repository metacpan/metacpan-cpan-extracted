#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use Test::More;

eval "use Map::Tube::Glasgow";
plan skip_all => "Map::Tube::Glasgow required for this test" if $@;

use_ok('Map::Tube::Generic');

diag( "Testing Map::Tube::Generic $Map::Tube::Generic::VERSION, Perl $], $^X" );

run_test( 'Map::Tube::Glasgow', { location => 'Glasgow' }, 'Glasgow', 'Glasgow tube' );
run_test( 'Map::Tube::Glasgow', { location => 'glasgow' }, 'Glasgow', 'Glasgow tube' );
run_test( 'Map::Tube::Glasgow', { location => 'Map::Tube::Glasgow' }, 'Glasgow', 'Glasgow tube' );
run_test( 'Map::Tube::Glasgow', { location => 'Glasgow', namespace => 'Map::Tube' }, 'Glasgow', 'Glasgow tube' );
run_test( 'Map::Tube::Glasgow', { location => 'Glasgow', namespace => [ 'Map::Tube' ] }, 'Glasgow', 'Glasgow tube' );
run_test( 'Map::Tube::Glasgow', { map => Map::Tube::Glasgow->new( ) }, 'Glasgow', 'Glasgow tube' );
run_test( 'Map::Tube::Glasgow', { map => Map::Tube::Glasgow->new( ), location => 'London' }, 'Glasgow', 'Glasgow tube' );
Fails:
my $map;
eval { $map = Map::Tube::Generic->new( location => 'Glasgow', namespace => 'Map::TUBE' ) };
ok( !defined($map), 'Map not found in non-existent namespace' );
eval { $map = Map::Tube::Generic->new( location => 'Glasgowxxx' ) };
ok( !defined($map), 'Non-existent map not found' );
eval { $map = Map::Tube::Generic->new( ); };
ok( !defined($map), 'Missing specifications' );

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
ok( scalar(keys(%$maps)) == 1, 'one map found matching G.*' );
$maps = Map::Tube::Generic->list_maps(  pattern => 'G.*', verify => 1 );
ok( scalar(keys(%$maps)) == 1, 'one verified map found matching G.*' );

done_testing( );

sub run_test {
  my ( $mod_name, $args, $location, $map_name ) = @_;
  my $map = Map::Tube::Generic->new( %$args );
  isa_ok( $map, 'Map::Tube::Generic', 'class of outer map' );
  like( ref( $map->map( ) ), qr/$mod_name/, '(decorated) class of inner map' );
  for my $meth( qw( xml get_map_data name location list_maps ) ) {
    can_ok( $map, $meth );
  }
  ok( !$map->can('json'), 'does not support json( ) method' );
  like( $map->xml( ), qr/$location/i, 'map reference' );
  is( $map->name( ), $map_name, 'outer map name' );
  is( $map->map( )->name( ), $map_name, 'inner map name' );
  is( $map->location( ), $location, 'map location' );
}

