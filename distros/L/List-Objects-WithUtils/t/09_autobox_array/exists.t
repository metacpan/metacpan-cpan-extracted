use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [1 .. 3];

ok $arr->exists(0), 'boxed array->exists ok';
ok $arr->exists(1), 'boxed array exists(1) ok';
ok $arr->exists(2), 'boxed array exists(2) ok';
ok !$arr->exists(3), 'boxed !array->exists ok';

done_testing
