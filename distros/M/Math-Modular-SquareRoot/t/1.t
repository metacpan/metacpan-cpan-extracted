use Test::More qw(no_plan);

use Math::Modular::SquareRoot qw(:msqrt);

# Uncomment imsqrt() to demonstrate how slow the unfactired version is 

 {my ($a, $b) = (1_000_037, 1_000_039);
  my $p       = $a*$b;       
  my $s = 243243;
  my $S = $s*$s%$p;
# ok $s == msqrt1($S, $p);
 }

ok 1 

