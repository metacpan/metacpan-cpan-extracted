use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [ 1 .. 4 ];
my $deleted = $arr->delete(2);
cmp_ok $deleted, '==', 3, 'boxed delete returned correct value';
is_deeply [ $arr->all ], [ 1, 2, 4 ], 'value was deleted';

eval {; []->delete(1) };
ok $@, 'trying to delete nonexistant from boxed array dies';

done_testing;
