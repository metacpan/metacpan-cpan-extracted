#!perl -T

use Test::More tests => 2;
use Data::Dumper;
use Geo::USCensus::Geocoding;

diag( "Testing lookup of a known good address" );
my $result = Geo::USCensus::Geocoding->query(
  street  => '1400 J St', # the Sacramento Convention Center
  city    => 'Sacramento',
  state   => 'CA',
  zip     => '95814',
);

ok( $result->is_match );
is( $result->error_message, '', 'error status' );
diag($result->address);
diag('Census tract '.$result->censustract);
diag('Latitude '.$result->latitude.', Longitude '.$result->longitude);

