#!perl -T
use strict;
use utf8;
use Test::More 0.82;
use Map::Tube::Beijing;
eval 'use XML::Twig';
plan skip_all => 'XML::Twig required' if $@;

my $map = Map::Tube::Beijing->new( );
isa_ok( $map, 'Map::Tube::Beijing', "Map::Tube object without nametype" );

my $xml = XML::Twig->new( );
$xml->parsefile( $map->xml( ) );
my $root = $xml->root( );

my( %line_ids, %line_names, %stations, %station_names );

my $line = $root->first_child('lines')->first_child('line');
while ($line) {
  my $id = $line->att('id');
  my $name = $line->att('name');
  ok( !exists( $line_names{$name} ), "Line name (for id $id) defined more than once" );
  ok( !exists( $line_ids{$id}     ), "Line id $id defined more than once" );
  $line_ids{$id} = 0;
  $line_names{$name} = 0;
  $line = $line->next_sibling( );
}

my $station = $root->first_child('stations')->first_child('station');
while($station) {
  my $id    = $station->att('id');
  my $name  = $station->att('name');
  my @lines = map { ( split(/:/) )[0] } split( /,/, $station->att('line') );
  my @links = split( /,/, $station->att('link') );

  isnt( scalar(@lines), 0, "Station id $id should have at least one line" );
  isnt( scalar(@links), 0, "Station id $id should have at least one link" );

  ok( !exists( $station_names{$name} ), "Station name (for id $id) defined more than once" );
  ok( !exists( $stations{$id} ),        "Station id $id defined more than once" );

  $station_names{$name} = 0;
  $stations{$id}->{lines}->{$_}++ for @lines;
  $stations{$id}->{links}->{$_}++ for @links;

  ok( exists( $line_ids{$_} ), "Station id $id connected by undefined line named $_" ) for @lines;

  $line_ids{$_}++ for @lines;
  $station = $station->next_sibling( );
}

# Links should be symmetric: (not necessarily, but in our tube!)
for my $id( keys %stations ) {
  ok( exists $stations{$_}->{links}->{$id}, "Station id $id linked to id $_ but not vice versa" ) for keys %{ $stations{$id}->{links} };
}

# Every line should have at least one station:
isnt( $line_ids{$_}, 0, "Line with id $_ has no stations" ) for keys %line_ids;

done_testing( );
