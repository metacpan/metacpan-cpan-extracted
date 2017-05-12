use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [1..10];
ok $arr->clear == $arr, 'boxed clear returned original';
ok $arr->is_empty, 'boxed array is_empty after clear';

done_testing;
