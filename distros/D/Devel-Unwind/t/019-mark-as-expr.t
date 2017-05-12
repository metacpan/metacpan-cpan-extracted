use warnings;
use strict;

use Test::More;
use Devel::Unwind;

is(scalar(mark L {3}),3,"The value of mark in scalar context is correct");
is_deeply([mark L {1..10}],[1..10] ,"The value of mark in array context is correct");
is(0+defined mark L { unwind L; 1..10}, 0,  "The value of mark is undefined after unwind");

sub {
    my ($m1,@m2) = @_;
    is($m1, 2,  'The value of $m1 is undefined after unwind');
    is_deeply([@m2], [4..22],  'The value of $m2 asdf is undefined after unwind');
}->(
    mark L { unwind L },
    mark L { 2 },
    mark L { 4..22 }
);

pass "Execution resumed after mark block";
done_testing;
