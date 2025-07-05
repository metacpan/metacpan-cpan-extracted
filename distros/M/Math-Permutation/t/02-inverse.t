use strict;
use warnings;
use Math::Permutation;
use Test::More tests => 8;
use v5.24.0;

my $id = Math::Permutation->cycles_with_len(10,[ () ]);
for (1..8) {
    my $a = Math::Permutation->random(10);
    my $b = Math::Permutation->init(10);
    $b->clone($a);
    $b->inverse;
    $a->comp($b); 
    ok $a->eqv($id) == 1;
}

done_testing();
