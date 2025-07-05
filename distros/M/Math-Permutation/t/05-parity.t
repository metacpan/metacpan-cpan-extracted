use strict;
use warnings;
use Math::Permutation;
use Test::More tests => 8;
use v5.24.0;

for (1..8) {
    my $a = Math::Permutation->init(8);
    my $swaps = 1 + int rand() * 20;
    my $i = 1 + int rand() * 8;
    my $j = 1 + int rand() * 8;
    $j = $i % 8 + 1 if $i == $j;
    $a->swap($i, $j) for (1..$swaps);
    my $p = $a->is_odd; 
    ok( $p == ($swaps % 2) );
}

done_testing();
