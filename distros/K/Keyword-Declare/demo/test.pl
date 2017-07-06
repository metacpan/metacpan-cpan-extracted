#! /usr/bin/env polyperl

use 5.012; use warnings;

use lib qw< dlib ../dlib >;
use Test::Expr;

my $x = 3;
my $y = 'foo';
my @z = 1..3;

test length($y) == $x;
test length($x) == length($y) => 'Same length' ;
test $y.'d' ne 'food'         => 'Bad word' ;

for my $n (@z) {
    test $x == $n;
}

test $z[-$z[$x-3]] ne $x;

done_testing();
