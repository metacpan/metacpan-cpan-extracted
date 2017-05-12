use Test::More qw(no_plan);

use Math::Modular::SquareRoot qw(:msqrt);

 {my ($a, $b) = (1_000_037, 1_000_039);
  my $p       = $a*$b;       
  my $s = 243243;
  my $S = $s*$s%$p;
  ok "@{[qw(243243 243252243227 756823758219 1000075758200)]}" eq "@{[msqrt2($S,$a,$b)]}";
 } 

