use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

is_deeply
  [ []->flatten_all ],
  [ ],
  'boxed empty array flatten_all ok';

my $arr = [ 1, 2, [ 3, 4, [ 5, 6 ], 7 ] ];
is_deeply
  [ $arr->flatten_all ],
  [ 1, 2, 3, 4, 5, 6, 7 ],
  'boxed flatten_all on refs ok';

$arr = [ 1, 2, array(3, 4, array(5, 6) ), 7 ];
is_deeply
  [ $arr->flatten_all ],
  [ 1, 2, 3, 4, 5, 6, 7 ],
  'boxed flatten_all on objs ok';

done_testing;
