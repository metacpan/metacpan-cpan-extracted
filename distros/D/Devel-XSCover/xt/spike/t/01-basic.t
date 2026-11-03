use strict;
use warnings;
use Test::More;
use Spike;

is(Spike::add(2, 3), 5, 'add');
is(Spike::plus(2, 3), 5, 'plus, the alias');
is(Spike::both(1, 1), 1, 'both true');
is(Spike::both(0, 1), 0, 'left false');
is(Spike::both(1, 0), 0, 'right false');
is(Spike::kind(0), 'zero', 'case 0');
is(Spike::kind(1), 'one', 'case 1');
is(Spike::kind(3), 'three', 'case 3');
is(Spike::kind(9), 'many', 'default');
is(Spike::twice_big(5), 5, 'small');
is(Spike::twice_big(20), 40, 'big');
is(Spike::inline_sq(-3), 9, 'the inline function from the xs');
is(Spike::helper_kind(0), 1, 'helper case 0');
is(Spike::helper_kind(1), 10, 'helper case 1');
is(Spike::helper_kind(7), 49, 'helper default');
is(Spike::guard(4), 4, 'guard passes');
is(Spike::More::triple(4), 12, 'the included xs');

done_testing;
