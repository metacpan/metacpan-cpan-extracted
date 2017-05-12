use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array(1 .. 4);
my $left = $arr->rotate;
is_deeply
  [ $left->all ],
  [ 2, 3, 4, 1 ],
  'rotate default opts ok';
is_deeply
  [ $arr->all ],
  [ 1, 2, 3, 4 ],
  'original array intact';

is_deeply
  [ $arr->rotate(left => 1)->all ],
  [ 2, 3, 4, 1 ],
  'rotate leftwards ok';
is_deeply
  [ $arr->rotate(right => 1)->all ],
  [ 4, 1, 2, 3 ],
  'rotate rightwards ok';

$arr = array(1 .. 2);
$left = $arr->rotate;
is_deeply [ $left->all ], [ 2, 1 ],
  'rotated leftwards once';
$left = $left->rotate;
is_deeply [ $left->all ], [ 1, 2 ],
  'rotated full-circle (left)';

my $right = $arr->rotate(right => 1);
is_deeply [ $right->all ], [ 2, 1 ],
  'rotated rightwards once';
$right = $right->rotate;
is_deeply [ $right->all ], [ 1, 2 ],
  'rotated full-circle (right)';

ok array->rotate(left => 1)->is_empty,  'empty array rotate left ok';
ok array->rotate(right => 1)->is_empty, 'empty array rotate right ok';

eval {; $arr->rotate(left => 1, right => 1) };
like $@, qr/direction/, 'bad opts die ok';

done_testing
