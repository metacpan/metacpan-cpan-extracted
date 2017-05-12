use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array( 1 .. 5 );
my $copy = $arr->copy;
ok $copy != $arr, 'copy returned new obj ok';
is_deeply [ $copy->all ], [ $arr->all ], 'copy ok';
is_deeply [ $arr->untyped->all ], [ $arr->all ], 'untyped ok';

ok array->copy->is_empty, 'empty array copy ok';

done_testing;
