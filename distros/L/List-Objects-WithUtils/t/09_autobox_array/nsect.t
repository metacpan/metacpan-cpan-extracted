use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [ 1 .. 10 ];

my $halved = $arr->nsect(2);

isa_ok $halved, 'List::Objects::WithUtils::Array',
  'boxed nsect returned array obj';

ok $halved->count == 2, 'boxed nsect(2) returned two items';

ok $halved->get(0)->count == $halved->get(1)->count,
  'boxed nsect(2) on even set returned even sets';

is_deeply [ $halved->get(0)->all ], [ 1 .. 5 ],
  'boxed nsect(2) first set ok' or diag explain $halved;
is_deeply [ $halved->get(1)->all ], [ 6 .. 10 ],
  'boxed nsect(2) second set ok' or diag explain $halved;

done_testing;
