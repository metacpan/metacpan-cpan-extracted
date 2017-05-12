use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

ok !defined array->shift, 'empty array shift ok';

my $arr = array( 1 .. 3 );
my $shifted = $arr->shift;
ok $shifted == 1, 'shifted value ok';
is_deeply [ $arr->all ], [ 2, 3 ], 'shift removed correct value';

done_testing;
