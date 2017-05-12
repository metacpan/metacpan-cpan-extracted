use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'array';

my $arr = array( 1 .. 7 );
my $itr = $arr->natatime(3);
is_deeply [ $itr->() ], [1, 2, 3], 'natatime itr() 1 ok';
is_deeply [ $itr->() ], [4, 5, 6], 'natatime itr() 2 ok';
is_deeply [ $itr->() ], [7], 'natatime itr() 3 ok';
ok !$itr->(), 'last itr returned false';

my $counted;
$arr->natatime(3, sub { ++$counted });
is $counted, 3, 'natatime with coderef ok';

$itr = array->natatime(2);
ok !defined $itr->(), 'empty array itr returned undef';

done_testing;
