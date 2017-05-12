use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array;

is_deeply [ $arr->all ], [], 'empty array all() ok';

$arr->push( 1 .. 5 );
is_deeply [ $arr->all ], [ 1 .. 5 ], 'array all() ok';
is_deeply [ $arr->export ], [ 1 .. 5 ], 'array export() ok';
is_deeply [ $arr->elements ], [ 1 .. 5 ], 'array elements() ok';

done_testing;
