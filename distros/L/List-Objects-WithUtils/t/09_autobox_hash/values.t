use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $hr = +{foo => 1, bar => 2, baz => 3};
is_deeply
  [ $hr->values->sort->all ],
  [ 1 .. 3 ],
  'boxed values ok';

done_testing;
