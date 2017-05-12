use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [];
ok $arr->count == 0, 'boxed count returned 0 on empty array';
$arr->push( 1, 2, 3);
ok $arr->count == 3, 'boxed count returned correct item count';

done_testing;
