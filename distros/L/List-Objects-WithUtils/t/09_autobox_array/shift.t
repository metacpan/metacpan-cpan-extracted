use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

ok !defined []->shift, 'boxed empty array shift ok';

my $arr = [ 1 .. 3 ];
my $shifted = $arr->shift;
ok $shifted == 1, 'boxed shift ok';
is_deeply [ $arr->all ], [ 2, 3 ], 'boxed shift removed correct value';

done_testing;
