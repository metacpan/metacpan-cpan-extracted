use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array( 1, 2, 3 );
ok $arr->end == 2, 'end ok';

ok array->end == -1, 'empty array end ok';

done_testing;
