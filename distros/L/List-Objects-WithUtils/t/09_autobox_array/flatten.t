use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

is_deeply
  [ []->flatten ],
  [ ],
  'boxed empty array flatten with no args ok';

is_deeply
  [ []->flatten(1) ],
  [ ],
  'boxed empty array flatten-to-depth ok';

my $arr = [ 1, 2, [ 3, 4, [ 5, 6 ], 7 ] ];
is_deeply
  [ $arr->flatten ],
  [ $arr->all ],
  'boxed flatten with no args same as all() ok';

is_deeply
  [ $arr->flatten(0) ],
  [ $arr->all ],
  'boxed flatten to depth 0 same as all() ok';

is_deeply
  [ $arr->flatten(-1) ],
  [ $arr->all ],
  'boxed flatten to negative depth same as all() ok';

is_deeply
  [ $arr->flatten(1) ],
  [ 1, 2, 3, 4, [ 5, 6 ], 7 ],
  'boxed flatten to depth 1 ok';

is_deeply
  [ $arr->flatten(2) ],
  [ 1, 2, 3, 4, 5, 6, 7 ],
  'boxed flatten to depth 2 ok';

$arr = [
  1, 2,
  [ 3, 4, [ 5, 6 ] ],
  [ 7, 8, [ 9, 10 ] ],
];

is_deeply
  [ $arr->flatten(1) ],
  [ 1, 2, 3, 4, [ 5, 6 ], 7, 8, [ 9, 10 ] ],
  'boxed flatten complex array ok';

done_testing;
