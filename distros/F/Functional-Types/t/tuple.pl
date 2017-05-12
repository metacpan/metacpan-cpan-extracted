use warnings;
use 5.016;
use Data::Dumper;

use Functional::Types;


# Try assigning bare array
type my $t2 = Tuple(String,Int,Bool);
say "TUPLE t2:".Dumper($t2);
bind $t2, ('1',2,1);
say show($t2);
say Dumper(untype($t2));

