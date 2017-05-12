use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array(4);
my $unshifted = $arr->unshift( 1 .. 3 );
ok $unshifted == $arr, 'unshift returned self';
is_deeply
  [ $arr->all ],
  [ 1 .. 4 ],
  'unshift ok';

ok array->unshift(1)->count == 1, 'unshift to empty array ok';

done_testing;
