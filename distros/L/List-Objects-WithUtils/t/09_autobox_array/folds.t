use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $sum = sub { $_[0] + $_[1] };
my $arr = [1 .. 3];

cmp_ok $arr->reduce($sum), '==', 6, 'boxed reduce with positional args ok';
cmp_ok [1]->reduce($sum), '==', 1, 'boxed array with one element reduce ok';
ok !defined []->reduce($sum), 'boxed empty array reduce returns undef';
ok !defined []->foldr($sum), 'boxed empty array foldr ok';
cmp_ok [6, 3, 2]->foldl(sub { $a / $b }), '==', 1,
  'boxed foldl ok';
cmp_ok [2, 3, 6]->foldr(sub { $b / $a }), '==', 1,
  'boxed foldr ok';

done_testing;
