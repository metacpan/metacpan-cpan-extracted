# Check the 3 functions that return (respectively)
# pi, euler's constant and catalan's constant.

use strict;
use warnings;
use Math::FakeDD qw(:all);

use Test::More;

my $pi = dd_pi();
ok(lc("$pi") eq '[3.141592653589793 1.2246467991473532e-16]', 'pi ok');

my $euler = dd_euler();
ok(lc("$euler") eq '[0.5772156649015329 -4.942915152430645e-18]', "euler's constant ok");

my $catalan = dd_catalan();
ok(lc("$catalan") eq '[0.915965594177219 3.747558421514984e-18]', "catalan's constant ok");


done_testing();

__END__
