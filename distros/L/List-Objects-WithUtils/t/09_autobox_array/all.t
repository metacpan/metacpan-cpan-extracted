use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [];

is_deeply [ $arr->all ], [], 'boxed empty array all() ok';

$arr->push( 1 .. 5 );
is_deeply [ $arr->all ], [ 1 .. 5 ], 'boxed array all() ok';
is_deeply [ $arr->export ], [ 1 .. 5 ], 'boxed array export() ok';
is_deeply [ $arr->elements ], [ 1 .. 5 ], 'boxed array elements() ok';

done_testing;
