#!perl
use strict;
use utf8;
use Test::More 0.82;
use XML::Simple;
use Map::Tube::Beijing;

my $map = new_ok( 'Map::Tube::Beijing' );
my $xml = XMLin( $map->xml( ) , KeyAttr => [ ], KeepRoot => 1, );

# This test operates on the original XML data, not the digested data
ok( exists $xml->{'tube'},               'There should be a <tube> tag at the top level' );
ok( exists $xml->{'tube'}->{'name'},     'There should be one <name> tag directly under the top level' );
ok( exists $xml->{'tube'}->{'name_alt'}, 'There should be one <name_alt> tag directly under the top level' );
ok( exists $xml->{'tube'}->{'lines'},    'There should be one <lines> tag directly under the top level' );
ok( exists $xml->{'tube'}->{'stations'}, 'There should be one <stations> tag directly under the top level' );

cmp_ok( scalar( @{ $xml->{'tube'}->{'stations'}->{'station'} } ), '>=', 5, 'There should be several <station> tags directly under <stations>' );
cmp_ok( scalar( @{ $xml->{'tube'}->{'lines'   }->{'line'   } } ), '>=', 5, 'There should be several <line> tags directly under <lines>' );

for my $station( @{ $xml->{'tube'}->{'stations'}->{'station'} } ) {
  ok( exists $station->{'id'},       '<station> tags should have an id attribute'  );
  ok( exists $station->{'name'},     '<station> tags should have a name attribute' );
  ok( exists $station->{'name_alt'}, '<station> tags should have a name_alt attribute' );
  ok( exists $station->{'line'},     '<station> tags should have a line attribute' );
  ok( exists $station->{'link'},     '<station> tags should have a link attribute' );
}

for my $line( @{ $xml->{'tube'}->{'lines'}->{'line'} } ) {
  ok( exists $line->{'id'},       '<line> tags should have an id attribute'   );
  ok( exists $line->{'name'},     '<line> tags should have a name attribute'  );
  ok( exists $line->{'name_alt'}, '<line> tags should have a name_alt attribute'  );
  ok( exists $line->{'color'},    '<line> tags should have a color attribute' );
}

done_testing();
