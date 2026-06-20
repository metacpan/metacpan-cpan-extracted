use strict;
use warnings;
use Test::More;
use Destructure::Declare;

# undef placeholder skips a slot
let [$a, undef, $c] = [1, 2, 3];
is($a, 1, 'before hole');
is($c, 3, 'after hole indexed correctly');

# leading hole
let [undef, $second] = ['x', 'y'];
is($second, 'y', 'leading hole');

# consecutive holes
let [undef, undef, $third] = [1, 2, 3];
is($third, 3, 'consecutive holes');

# hole then nested
let [undef, [$x, $y]] = ['skip', [8, 9]];
is("$x$y", '89', 'hole before nested pattern');

done_testing;
