use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array( 1 .. 10 );

my $halved = $arr->nsect(2);

isa_ok $halved, 'List::Objects::WithUtils::Array',
  'nsect returned array obj';

ok $halved->count == 2, 'nsect(2) returned two items';

ok $halved->get(0)->count == $halved->get(1)->count,
  'nsect(2) on even set returned even sets';

is_deeply [ $halved->get(0)->all ], [ 1 .. 5 ],
  'nsect(2) first set ok' or diag explain $halved;
is_deeply [ $halved->get(1)->all ], [ 6 .. 10 ],
  'nsect(2) second set ok' or diag explain $halved;

my $thrice = $arr->nsect(3);
is_deeply [ $thrice->get(0)->all ], [ 1 .. 4 ],
  'nsect(3) first set ok' or diag explain $thrice;
is_deeply [ $thrice->get(1)->all ], [ 5 .. 7 ],
  'nsect(3) second set ok' or diag explain $thrice;
is_deeply [ $thrice->get(2)->all ], [ 8 .. 10 ],
  'nsect(4) third set ok' or diag explain $thrice;

my $zeroarg = array(1..10)->nsect;
isa_ok $zeroarg, 'List::Objects::WithUtils::Array';
ok $zeroarg->is_empty, 'zero arg nsect produced empty array obj'
  or diag explain $zeroarg;

my $too_many = array(1..3)->nsect(5);
ok $too_many->count == 3, 'total sections limited to array count';

ok array->nsect(3)->is_empty, 'nsect on empty array returns empty array';

done_testing;
