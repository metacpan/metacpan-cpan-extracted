use strict;
use warnings;
use Math::Permutation;
use Test::More tests => 24;
use List::Util qw/sum/;
use v5.24.0;

# from OEIS:A268532
my %perm = qw/
1234 0
1243 1
1324 1
2134 1
1342 2
1423 2
2143 2
2314 2
3124 2
1432 3
2341 3
2413 3
3142 3
3214 3
4123 3
2431 4
3241 4
3412 4
4132 4
4213 4
3421 5
4231 5
4312 5
4321 6 /;

for (keys %perm) {
    my $a = Math::Permutation->wrepr([split "", $_]);
    ok( $perm{$_} == sum($a->inversion->@*) );
}

done_testing();
