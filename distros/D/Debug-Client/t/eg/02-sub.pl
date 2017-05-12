use strict;
use warnings;

$| = 1;

my $x = 11;
my $y = 22;
my $q = func1( $x, $y );
my $z = $x + $y;
my $t = func1( 19, 23 );
$t++;
$z++;


sub func1 {
  my ( $q, $w ) = @_;
  my $multi = $q * $w;
  my $add   = $q + $w;
  return $multi;
}
