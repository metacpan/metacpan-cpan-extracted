use strict;
use Test::More;

use Math::GF;

my $GF4 = Math::GF->new(order => 4);

my $u = $GF4->multiplicative_neutral;
isa_ok $u, 'Math::GF::Extension';
is $u->p, 2, 'p is fine';
is $u->n, 2, 'n is fine';
is $u->v, 1, 'v is fine';
is $u->i, 1, 'i is fine';
is $u->o, 1, 'o is fine';

my $two = $GF4->e(2);
my $three = $GF4->e(3);
my $r = $u + $two;
is $r, $three, '[1] + [2] -> [3] in GF(2^2)';

$r = $r + $two;
is $r, $u, '[3] + [2] -> [1] in GF(2^2)';

my $prod = $two * $three;
is $prod, $u, '[2] * [3] -> [1] in GF(2^2)';
$prod = $three * $two;
is $prod, $u, '[3] * [2] -> [1] in GF(2^2)';

is $two->inv, $three, 'inv([2]) -> [3] in GF(2^2)';
is $u->inv, $u, 'inv([1]) -> [1] in GF(2^2)';

ok $three != $two, '[3] != [2] in GF(2^2)';
is $two ** 3, $u, '[2]^3 -> [1] in GF(2^2)';

is $two->stringify, "2", 'stringify, direct call';
is "$two", "2", 'stringify, via overloaded operator';

ok !(__PACKAGE__->can('GF_2_2')), 'sub GF(2^2) does not previously exist';
Math::GF->import_builder(4);
ok __PACKAGE__->can('GF_2_2'), 'sub GF(2^2) was imported';

my $zero = GF_2_2(0);
is $zero, $GF4->additive_neutral, 'zero is... zero';
my $one = GF_2_2(1);
is $one, $u, 'one is... one';
is GF_2_2(2), $two, 'two is... two';
is GF_2_2(3), $three, 'three is... three';

is $zero / $two, $zero, '[0] / [2] -> [0] in GF(2^2)';
is $one / $two, $three, '[1] / [2] -> [3] in GF(2^2)';
is $two / $two, $one, '[2] / [2] -> [1] in GF(2^2)';
is $three / $two, $two, '[3] / [2] -> [2] in GF(2^2)';

is $three - $two, $one, '[3] - [2] -> [1] in GF(2^2)';
is $two - $three, $one, '[2] - [3] -> [1] in GF(2^2)';

done_testing;
