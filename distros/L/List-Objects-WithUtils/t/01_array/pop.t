use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

ok !defined array->pop, 'empty array pop ok';

my $arr = array( 1 .. 3 );
my $popped = $arr->pop;
ok $popped == 3, 'pop returned correct value';
is_deeply [ $arr->all ], [ 1, 2 ], 'pop removed correct value';

done_testing;
