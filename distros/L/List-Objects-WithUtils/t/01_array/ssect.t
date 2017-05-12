use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array( 1 .. 10 );

my $threeper = $arr->ssect(3);

ok $threeper->count == 4, 'ssect(3) returned four items';

is_deeply [ $threeper->get(0)->all ], [ 1 .. 3 ],
  'ssect(3) first set ok' or diag explain $threeper;
is_deeply [ $threeper->get(3)->all ], [ 10 ],
  'ssect(3) last set ok' or diag explain $threeper;

my $zeroarg = array(1..10)->ssect;
isa_ok $zeroarg, 'List::Objects::WithUtils::Array';
ok $zeroarg->is_empty, 'zero arg ssect produced empty array obj'
  or diag explain $zeroarg;

ok array->ssect(3)->is_empty, 'ssect on empty array produced empty array';

done_testing;
