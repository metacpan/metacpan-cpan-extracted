#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More tests => 23;
use Map::Tube::Paris;

my $map = new_ok( 'Map::Tube::Paris' );

# {
#   Optional additional debug output, helps to identify mistakes in per-line station indexes
#   (watch out for stations not showing up in the data -- they may have been unceremoniously dropped!)
#   my $stationref = $map->get_stations( );
#   my @stations = @{ $stationref };
#   print STDERR "\n*******\n";
#   print STDERR join("\n", sort map { $_->id( ) } @stations ), "\n";
#   print STDERR "*** ", scalar(@stations), "\n";
#   print STDERR "*******\n";
# }

is( $map->name( ), 'Paris Métro, RER, Transilien and Tram', 'Name of map does not match' );

eval { $map->get_node_by_name('XYZ'); };
like( $@, qr/\QMap::Tube::get_node_by_name(): ERROR: Invalid Station Name [XYZ]\E/, 'Node XYZ should not exist' );

{
  my $ret = $map->get_node_by_name('Odéon');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'p_416',                     'Node id not correct for Odéon' );
  is( $ret->name( ), 'Odéon',                    'Node name not correct for Odéon' );
  is( $ret->link( ), 'p_1013,p_1015,p_415,p_417', 'Links not correct for Odéon' );
  is( join( ',', sort map { $_->name( ) } @{ $ret->line( ) } ), '10,4', 'Lines not correct for Odéon'
    );
}

{
  my $ret = $map->get_node_by_id('p_416');
  isa_ok( $ret,      'Map::Tube::Node' );
  is( $ret->id( ),   'p_416',  'Node id not correct for p_416' );
  is( $ret->name( ), 'Odéon', 'Node name not correct for p_416' );
}

{
  my $stationref = $map->get_stations( );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]),  'Map::Tube::Node' );
  is( scalar(@stations), 968, 'Number of stations incorrect for map' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Abbesses.*Évry - Val de Seine$), 'Stations not correct for map' );
}

{
  my $stationref = $map->get_stations('4');
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( ref($stations[0]), 'Map::Tube::Node' );
  is( scalar(@stations), 29, 'Number of stations incorrect for line 4' );
  like( join( ',', sort map { $_->name( ) } @stations ),  qr(^Alésia.*Étienne Marcel$), 'Stations not correct for line 4' );
}

{
  my $stationref = $map->get_next_stations( 'Odéon' );
  isa_ok( $stationref, 'ARRAY' );
  my @stations = @{ $stationref };
  isa_ok( $stations[0], 'Map::Tube::Node' );
  is( scalar(@stations), 4, 'Number of neighbouring stations incorrect for Odéon' );
  like( join( ',', sort map { $_->name( ) } @stations ), qr(Cluny - La Sorbonne,Mabillon,Saint-Germain-des-Prés,Saint-Michel), 'Neighbouring stations not correct for Odéon' );
}

