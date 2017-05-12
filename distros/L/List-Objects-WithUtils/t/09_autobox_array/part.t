use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my ($evens, $odds) = [ 1 .. 6 ]->part(sub { $_ & 1 })->all;

is_deeply 
  [ $evens->all ], 
  [ 2,4,6 ], 
  'boxed part ok';

done_testing;
