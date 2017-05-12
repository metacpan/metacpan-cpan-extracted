use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array( 1 .. 10 );
ok $arr->clear == $arr, 'clear() returned self';
ok $arr->is_empty, 'array is_empty after clear';
ok array->clear->is_empty, 'empty array clear() ok';

done_testing;
