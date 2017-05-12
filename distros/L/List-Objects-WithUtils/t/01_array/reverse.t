use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

ok array->reverse->is_empty, 'empty array reverse ok';

my $arr = array( 1, 2, 3);
my $reverse = $arr->reverse;
is_deeply
  [ $reverse->all ],
  [ 3, 2, 1 ],
  'reverse ok';

is_deeply
  [ $arr->all ],
  [ 1, 2, 3 ],
  'original intact';

done_testing;
