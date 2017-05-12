use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [ 1 .. 7 ];
my $tuples = $arr->tuples(2);
is_deeply
  [ $tuples->all ],
  [
    [ 1, 2 ],
    [ 3, 4 ],
    [ 5, 6 ],
    [ 7 ]
  ],
  'boxed tuples ok';

done_testing;
