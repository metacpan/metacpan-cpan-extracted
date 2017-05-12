use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

ok !defined []->pop, 'boxed empty array pop ok';

my $arr = [ 1 .. 3 ];
my $popped = $arr->pop;
ok $popped == 3, 'boxed pop returned correct value';
is_deeply [ $arr->all ], [ 1, 2 ], 'boxed pop removed correct value';

done_testing;
