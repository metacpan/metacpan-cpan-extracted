use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

ok !defined []->get(1), 'boxed empty array get ok';

my $arr = [1 .. 3];
cmp_ok $arr->get(0), '==', 1, 'get 0 ok';
cmp_ok $arr->get(1), '==', 2, 'get 1 ok';
cmp_ok $arr->get(2), '==', 3, 'get 2 ok';
ok !defined $arr->get(3), 'get 3 undef ok';

done_testing;
