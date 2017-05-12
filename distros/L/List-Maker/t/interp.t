use Test::More 'no_plan';

use List::Maker;

my ($from, $to, $by) = (1,10,2);

is_deeply [<$to..$from>], [10,9,8,7,6,5,4,3,2,1]    => '<$to..$from>';
is_deeply [<$from..$to x $by>],  [1,3,5,7,9]        => '<$from..$to x $by>';
is_deeply [<$from, $by..$to>],   [1..10]            => '<$from, $by,..$to>';

is_deeply [<10..$from>], [10,9,8,7,6,5,4,3,2,1]     => '<10..$from>';

my $range = '2..7x2';
is_deeply [< $range >], [2,4,6]                     => '< $range >';
