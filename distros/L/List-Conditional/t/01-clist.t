#!perl -T

use Test::More tests => 4;

use List::Conditional;

my @list = clist(1 => 'a', 0 => 'b', 1 => 'c');
is(int @list, 2, 'two elements included');
is($list[0], 'a', '"a" is first element');
is($list[1], 'c', '"c" is second element');

# test fail with odd elements
eval { clist(1 => 'a', 0 => 'b', 1) };
ok($@, 'should fail with odd elements');

