use Test::More tests => 4;

use strict;
use warnings;
use Config;

use_ok('Math::BaseCalc');

if ($Config{use64bitint} eq 'define') {
  my $x = do {use integer; 2**63-1};
  roundtrip36( $x, '1y2p0ij32e8e7' );
} else {
  my $x = do {use integer; 2**31-1};
  roundtrip36( $x, 'zik0zj' );
}

sub roundtrip36 {
  my ($int, $int_base36) = @_;

  my $calc36 = new Math::BaseCalc(digits=>[0..9,'a'..'z']);
  my $base36 = $calc36->to_base($int);
  is($base36, $int_base36, "to_base has done proper conversion of $int");
  my $int2 = $calc36->from_base($base36);
  is($int2, $int, "$int has roundtripped");
  $int2 = $calc36->from_base($int_base36);
  is($int2, $int, "from_base correct for $int_base36 ($int)");
}
