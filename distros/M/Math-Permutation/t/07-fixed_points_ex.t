use strict;
use warnings;
use Math::Permutation;
use Test::More tests => 40;
use v5.24.0;

# from OEIS:A320588
my @derangements = qw/21
231
312
2143
2341
2413
3142
3412
3421
4123
4312
4321
21453
21534
23154
23451
23514
24153
24513
24531
25134
25413
25431
31254
31452
31524
34152
34251
34512
34521
35124
35214
35412
35421
41253
41523
41532
43152
43251
43512/;

for (0..39) {
    my $a = Math::Permutation->wrepr([split "", $derangements[$_]]);
    ok( 0 == scalar $a->fixed_points->@* );
}

done_testing();
