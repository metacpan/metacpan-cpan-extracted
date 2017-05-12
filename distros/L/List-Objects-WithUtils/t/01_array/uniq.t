use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array( 1, 2, 2, 3, 4, 5, 5 );
my $uniq = $arr->uniq;
is_deeply
  [ $uniq->sort->all ],
  [ 1, 2, 3, 4, 5 ],
  'uniq ok';

ok array->uniq->is_empty, 'empty array uniq ok';

done_testing;
