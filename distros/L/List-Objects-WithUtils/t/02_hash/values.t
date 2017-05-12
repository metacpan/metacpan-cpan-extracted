use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'hash';
my $hr = hash(foo => 1, bar => 2, baz => 3);
is_deeply
  [ $hr->values->sort->all ],
  [ 1 .. 3 ],
  'values ok';

done_testing;
