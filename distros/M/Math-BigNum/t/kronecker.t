#!perl -T

use 5.006;
use strict;
use warnings;

use Test::More tests => 2 * 88;

use Math::BigNum;

my @rows = map { [split ' '] } split(/\R/, <<'EOT');
    1   2   3   4   5   6   7   8   9   10  11
23  1   1   1   1   -1  1   -1  1   1   -1  -1
24  1   0   0   0   1   0   1   0   0   0   1
25  1   1   1   1   0   1   1   1   1   0   1
26  1   0   -1  0   1   0   -1  0   1   0   1
27  1   -1  0   1   -1  0   1   -1  0   1   -1
28  1   0   -1  0   -1  0   0   0   1   0   1
29  1   -1  -1  1   1   1   1   -1  1   -1  -1
30  1   0   0   0   0   0   -1  0   0   0   1
EOT

my @nums = @{shift(@rows)};
my @primes = map { shift @$_ } @rows;

foreach my $i (0 .. $#nums) {
    my $k = $nums[$i];
    foreach my $j (0 .. $#primes) {
        my $p = $primes[$j];
        is(Math::BigNum->new($k)->kronecker($p),                    $rows[$j][$i]);
        is(Math::BigNum->new($k)->kronecker(Math::BigNum->new($p)), $rows[$j][$i]);
    }
}
