#!perl

# TODO Depends on List::Utils version

use List::Util qw( reduce );

$| = 1;

sub sum {
  my ( $x, $y ) = @_;
  return $x + $y;
}

sub total {
  my @l = @_;
  my $t = reduce { sum( $a, $b ) } @l;
  return $t;
}

my $tot = total( 1, 2, 4, 18 );

# The expected output. ':tail:' means match only the tail of the output.
# We need that because we can't predict what the output from use
# List::Utils will look like.
__DATA__
:tail:
ENTRY(total, t/scripts/xs.pl, 18)
ENTRY(sum, t/scripts/xs.pl, 14)
RETURN(sum, t/scripts/xs.pl, 14)
ENTRY(sum, t/scripts/xs.pl, 14)
RETURN(sum, t/scripts/xs.pl, 14)
ENTRY(sum, t/scripts/xs.pl, 14)
RETURN(sum, t/scripts/xs.pl, 14)
RETURN(total, t/scripts/xs.pl, 18)
