#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

use Math::BigNum;

sub is_prime {
    my ($n, $k) = @_;

    return 1 if $n == 2;
    return 0 if $n < 2 or $n % 2 == 0;

    my $d = $n - 1;
    my $s = 0;

    while (!($d % 2)) {
        $d >>= 1;
        $s++;
    }

  LOOP: for (1 .. $k) {
        my $a = Math::BigNum->new($n - 2)->irand->biadd(2);

        my $x = $a->modpow($d, $n);
        next if $x->is_one or $x == $n - 1;

        for (1 .. $s - 1) {
            $x = ($x * $x)->bimod($n);
            return 0  if $x->is_one;
            next LOOP if $x == $n - 1;
        }
        return 0;
    }
    return 1;
}

my $expect = join(' ', split(/\R/, <<'EOT'));
2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53,
59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113,
127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181,
191, 193, 197, 199, 211, 223, 227, 229, 233, 239, 241, 251,
257, 263, 269, 271, 277, 281, 283, 293, 307, 311, 313, 317,
331, 337, 347, 349, 353, 359, 367, 373, 379, 383, 389, 397
EOT

my $got = join ", ", grep { is_prime($_, 10) } (1 .. 400);

is($expect, $got);
