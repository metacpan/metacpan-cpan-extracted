use strict;
use warnings;
use Math::Permutation;
use Test::More tests => 8;
use v5.24.0;

my $id = Math::Permutation->cycles_with_len(5,[ () ]);
for (1..8) {
    my $a = Math::Permutation->random(5);
    my $b = Math::Permutation->init(5);
    $b->clone($a);
    my $o = $a->order;
    $a->comp($b) for (1..$o-1); 
    ok $a->eqv($id) == 1;
}

done_testing();
