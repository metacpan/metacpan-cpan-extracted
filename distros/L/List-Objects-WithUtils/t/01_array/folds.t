use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $sum = sub { $_[0] + $_[1] };
my $arr = array(1 .. 3);

cmp_ok $arr->reduce($sum), '==', 6, 'reduce with positional args ok';
cmp_ok array(1)->reduce($sum), '==', 1, 'array with one element reduce ok';
ok !defined array->reduce($sum), 'empty array reduce ok';

cmp_ok array(6, 3, 2)->reduce(sub { $a / $b }), '==', 1,
  'reduce folds left (with named args)';

cmp_ok array(6, 3, 2)->foldl(sub { $a / $b }), '==', 1,
  'foldl folds left';

cmp_ok array(6, 3, 2)->fold_left(sub { $a / $b }), '==', 1,
  'fold_left alias ok';

cmp_ok array(2, 3, 6)->foldr(sub { $b / $a }), '==', 1,
  'foldr folds right';

cmp_ok array(2, 3, 6)->fold_right(sub { $b / $a }), '==', 1,
  'fold_right alias ok';

ok !defined array->foldr($sum), 'empty array foldr ok';

done_testing;
