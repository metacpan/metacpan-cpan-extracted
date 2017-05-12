use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [ 1 .. 5 ];
my $copy = $arr->copy;
ok $copy != $arr, 'boxed copy returned new obj ok';
is_deeply [ $copy->all ], [ $arr->all ], 'copy ok';
is_deeply [ $arr->untyped->all ], [ $arr->all ], 'boxed untyped ok';

done_testing;
