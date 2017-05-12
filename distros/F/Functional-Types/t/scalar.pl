use warnings;
use 5.016;
use Data::Dumper;

use Functional::Types;

my $ti = Int(42);
type my $ti2 = Int;
bind $ti2, $ti;
say untype $ti2;
say show $ti;
say show $ti2;

my $ti1 = Int(42);
type my $tf = Float;
bind $tf, $ti1;
say untype $tf;
