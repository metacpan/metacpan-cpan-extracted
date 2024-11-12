#!perl
use strict;
use utf8;
use Test::More 0.82;
use XML::Simple;
use Map::Tube::Beijing;

my $map = Map::Tube::Beijing->new( nametype => 'alt' );

isa_ok( $map, 'Map::Tube::Beijing', "Map::Tube object for nametype='alt'" );
my $xml = XMLin( $map->xml( ) , KeyAttr => [ ], KeepRoot => 1, );

my( %line_ids, %line_names, %stations );

for my $line( @{ $xml->{'tube'}->{'lines'}->{'line'} } ) {
  my $id = $line->{'id'};
  my $name = $line->{ 'name_alt'};
  ok( !exists( $line_names{$name} ), "Line name $name (id $id) defined more than once" );
  ok( !exists( $line_ids{$name}   ), "Line id $id (name $name) defined more than once" );
  $line_ids{$id} = 0;
  $line_names{$name} = 0;
}

for my $station( @{ $xml->{'tube'}->{'stations'}->{'station'} } ) {
  my $id    = $station->{'id'};
  my @lines = map { ( split(/:/) )[0] } split( /,/, $station->{'line'} );
  my @links = split( /,/, $station->{'link'} );

  isnt( scalar(@lines), 0, "Station id $id should have at least one line" );
  isnt( scalar(@links), 0, "Station id $id should have at least one link" );

  ok( !exists( $stations{$id} ), "Station id $id defined more than once" );

  $stations{$id}->{lines}->{$_}++ for @lines;
  $stations{$id}->{links}->{$_}++ for @links;

  ok( exists( $line_ids{$_} ), "Station id $id connected by undefined line named $_" ) for @lines;

  $line_ids{$_}++ for @lines;
}

# Links should be symmetric: (not necessarily, but in our tube!)
for my $id( keys %stations ) {
  ok( exists $stations{$_}->{links}->{$id}, "Station id $id linked to id $_ but not vice versa" ) for keys %{ $stations{$id}->{links} };
}

# Every line should have at least one station:
isnt( $line_ids{$_}, 0, "Line with id $_ has no stations" ) for keys %line_ids;

done_testing( );
