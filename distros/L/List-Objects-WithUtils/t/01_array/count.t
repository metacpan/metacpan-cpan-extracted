use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array;
ok $arr->count == 0, 'count returned 0 on empty array';
$arr->push( 1, 2, 3);
ok $arr->count == 3, 'count returned correct item count';

done_testing;
