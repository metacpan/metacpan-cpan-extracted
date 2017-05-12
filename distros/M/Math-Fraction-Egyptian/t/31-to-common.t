# $Id:$
# $Source:$

use strict;
use warnings;
use Data::Dumper;
use Test::More 'no_plan';

use_ok('Math::Fraction::Egyptian','to_common');

my @tests = (
    [ 2, 3 => 5, 6 ],           # 1/2 + 1/3 = 5/6
    [ 3, 4 => 7, 12 ],          # 1/3 + 1/4 = 7/12
    [ 2, 3, 16 => 43, 48 ],     # 1/2 + 1/3 + 1/16 = 43/48
    [ 5, 45 => 2, 9 ],
    [ 6, 18 => 2, 9 ],
    [ 8, 120 => 2, 15 ],
    [ 10, 30 => 2, 15 ],
    [ 2, 5, 11 => 87, 110 ],
);

for my $i (0 .. $#tests) {
    my @e = @{ $tests[$i] };
    my $d = pop @e;
    my $n = pop @e;
    is_deeply( [ to_common(@e) ], [$n,$d] );
}

