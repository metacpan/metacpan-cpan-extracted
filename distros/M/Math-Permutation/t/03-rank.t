use strict;
use warnings;
use Math::Permutation;
use Test::More tests => 16;
use v5.24.0;

for (1..8) {
    my $a = Math::Permutation->random(9);
    my $x = $a->rank;
    $a->prev;
    my $y = $a->rank;
    SKIP: {
        skip "edge case", 1 if $x==1;
        ok ( $x-1 == $y  );
    };
}

for (1..8) {
    my $b = Math::Permutation->random(9);
    my $x = $b->rank;
    $b->nxt;
    my $y = $b->rank;
    SKIP: {
        skip "edge case", 1 if $x==362880;
        ok ( $x+1 == $y  );
    };
}


done_testing();
