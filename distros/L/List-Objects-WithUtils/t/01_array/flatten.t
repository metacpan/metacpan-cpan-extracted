use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

is_deeply
  [ array->flatten ],
  [ ],
  'empty array flatten with no args ok';

is_deeply
  [ array->flatten(1) ],
  [ ],
  'empty array flatten-to-depth ok';

my $arr = array( 1, 2, [ 3, 4, [ 5, 6 ], 7 ] );
is_deeply
  [ $arr->flatten ],
  [ $arr->all ],
  'flatten with no args same as all() ok';

is_deeply
  [ $arr->flatten(0) ],
  [ $arr->all ],
  'flatten to depth 0 same as all() ok';

is_deeply
  [ $arr->flatten(-1) ],
  [ $arr->all ],
  'flatten to negative depth same as all() ok';

is_deeply
  [ $arr->flatten(1) ],
  [ 1, 2, 3, 4, [ 5, 6 ], 7 ],
  'flatten to depth 1 ok';

is_deeply
  [ $arr->flatten(2) ],
  [ 1, 2, 3, 4, 5, 6, 7 ],
  'flatten to depth 2 ok';

$arr = array(
  1, 2,
  [ 3, 4, [ 5, 6 ] ],
  [ 7, 8, [ 9, 10 ] ],
);

is_deeply
  [ $arr->flatten(1) ],
  [ 1, 2, 3, 4, [ 5, 6 ], 7, 8, [ 9, 10 ] ],
  'flatten complex array ok';

{ package My::ArrayType;
  use strict; use warnings FATAL => 'all';
  sub new { bless [1], shift }
}

my $foo = My::ArrayType->new;
$arr = array(
  array(1, 2, 3),
  $foo,
  [ 4, 5, 6 ],
);

is_deeply
  [ $arr->flatten(1) ],
  [ 1, 2, 3, $foo, 4, 5, 6 ],
  'flatten skipped ARRAY-type obj ok';

done_testing;
