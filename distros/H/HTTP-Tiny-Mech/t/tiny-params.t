
use strict;
use warnings;

use Test::More tests => 2 * 2;
use HTTP::Tiny::Mech;
use HTTP::Tiny 0.022;

my %test_map = (
  agent         => "Test::Version/1.0",
  local_address => "123.4.5.6",
);
for my $key ( sort keys %test_map ) {
  my $instance = HTTP::Tiny::Mech->new( $key => $test_map{$key} );
  can_ok( $instance, $key ) and is( $instance->$key(), $test_map{$key}, "Value pass through" );
}
