use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

is_deeply
  [ array->flatten_all ],
  [ ],
  'empty array flatten_all ok';

my $arr = array( 1, 2, [ 3, 4, [ 5, 6 ], 7 ] );
is_deeply
  [ $arr->flatten_all ],
  [ 1, 2, 3, 4, 5, 6, 7 ],
  'flatten_all on refs ok';

$arr = array( 1, 2, array(3, 4, array(5, 6) ), 7 );
is_deeply
  [ $arr->flatten_all ],
  [ 1, 2, 3, 4, 5, 6, 7 ],
  'flatten_all on objs ok';

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
  [ $arr->flatten_all ],
  [ 1, 2, 3, $foo, 4, 5, 6 ],
  'flatten_all skipped ARRAY-type obj ok';

done_testing;
