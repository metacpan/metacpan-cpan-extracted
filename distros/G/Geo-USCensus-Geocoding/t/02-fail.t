#!perl -T

use Test::More tests => 1;
use Data::Dumper;
use Geo::USCensus::Geocoding;

diag( "Testing lookup of a known nonexistent address" );
my $result = Geo::USCensus::Geocoding->query(
  street  => '1000 Z St', # there is no Z street
  city    => 'Sacramento',
  state   => 'CA',
  zip     => '95814',
);

ok( !$result->is_match );
diag( $result->content );

