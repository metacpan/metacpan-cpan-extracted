#!perl
use strict;
use utf8;
use Test::More 0.82;
use XML::Simple;
use Map::Tube::Beijing;

my $map = new_ok( 'Map::Tube::Beijing' );
my $xml = XMLin( $map->xml() , KeyAttr => [ ], KeepRoot => 1, );

for my $which( '', '_alt' ) {
  my(%lines, %stations);

  for my $line( @{ $xml->{'tube'}->{'lines'}->{'line'} } ) {
    my $id = $line->{'id'};
    my $name = $line->{'name'.$which};
    ok( !exists( $lines{$name} ), "Line name" . $which . " $name, id $id defined more than once" );
    $lines{$name} = 0;
  }

  for my $station( @{ $xml->{'tube'}->{'stations'}->{'station'} } ) {
    my $id    = $station->{'id'};
    my @lines = split( /,/, $station->{'line'.$which} );
    my @links = split( /,/, $station->{'link'} );

    isnt( scalar(@lines), 0, "Station id $id should have at least one line".$which );
    isnt( scalar(@links), 0, "Station id $id should have at least one link" );

    ok( !exists( $stations{$id} ), "Station id $id defined more than once" );

    $stations{$id}->{lines}->{$_}++ for @lines;
    $stations{$id}->{links}->{$_}++ for @links;

    ok( exists( $lines{$_} ), "Station id $id connected by undefined line".$which . "named $_" ) for @lines;

    $lines{$_}++ for @lines;
  }

  # Links should be symmetric: (not necessarily, but in our tube!)
  for my $id( keys %stations ) {
    ok( exists $stations{$_}->{links}->{$id}, "Station id $id linked to id $_ but not vice versa" ) for keys %{ $stations{$id}->{links} };
  }

  # Every line should have at least one station:
  isnt( $lines{$_}, 0, "Line named".$which . " $_ has no stations" ) for keys %lines;

}

done_testing();
