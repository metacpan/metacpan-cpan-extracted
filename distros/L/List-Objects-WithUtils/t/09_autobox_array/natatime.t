use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $arr = [ 1 .. 7 ];
my $itr = $arr->natatime(3);
is_deeply [ $itr->() ], [1, 2, 3], 'boxed natatime itr() ok';

my $counted;
$arr->natatime(3, sub { ++$counted });
is $counted, 3, 'boxed natatime with coderef ok';

$itr = []->natatime(2);
ok !defined $itr->(), 'boxed empty array itr returned undef';

done_testing;
