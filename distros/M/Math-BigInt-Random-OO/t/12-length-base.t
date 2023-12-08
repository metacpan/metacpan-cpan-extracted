# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 70;

use Math::BigInt::Random::OO;

use Math::BigInt;
use Math::BigFloat;

my $class = 'Math::BigInt::Random::OO';

for my $base (2, 4, 8, 10, 16, 25, 36) {
    for my $len (5, 10, 20, 50, 75) {
        for my $num (1, 50) {

            my $test = qq|\@x = $class -> new("length" => $len, |
                     . qq|"base" => $base) -> generate($num)|;

            my @x;
            note "\n", $test, "\n\n";
            eval $test;
            die "\nThe following code failed to eval():\n\n",
              "    ", $test, "\n\n", $@, "\n" if $@;

            subtest $test => sub {
                plan tests => 1 + 2 * @x;

                # Check number of output argument.

                cmp_ok(scalar(@x), "==", $num,
                       "Number of output arguments");

                # Check each output argument.

                for (my $i = 0 ; $i <= $#x ; ++$i) {
                    is(ref($x[$i]), "Math::BigInt",
                       "Output argument '\$x[$i]' is a 'Math::BigInt'");
                    my $str = $x[$i] -> to_base($base);
                    cmp_ok(length($str), '==', $len,
                           "Output argument '\$x[$i]' has the correct length")
                      or diag("  The value '\$x[$i]' in base '$base'\n",
                              "         got: '$str'\n",
                              "    expected: a $len-character string of",
                              " random base $base digits");
                }
            };
        }
    }
}
