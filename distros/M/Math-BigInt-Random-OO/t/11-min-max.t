# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 264;

use Math::BigInt::Random::OO;

use Math::BigInt;
use Math::BigFloat;

my $class = 'Math::BigInt::Random::OO';

my @contexts = ('scalar', 'list');

# Classes (reference types, actually) for the input arguments.

my @refs = ('', 'Math::BigInt', 'Math::BigFloat');

# Values for the 'min' and 'max' parameters to the 'new' method.

my @minmax =
  (
   [  0,  0 ],

   [  0,  1 ],
   [  1,  2 ],
   [  0,  2 ],
   [ -1,  2 ],

   [ -1,  0 ],
   [ -2, -1 ],
   [ -2,  0 ],
   [ -2,  1 ],

   [ '-2e20', '-2e20' ],
   [  '5e20',  '5e20' ],
   [ '-2e20',  '5e20' ],

  );

# Arguments to the 'generate' method.

my @genargs = ([ ],
               [1],
               [2],
               [3],
             );

for my $context (@contexts) {
    for my $ref (@refs) {
        for (my $i = 0 ; $i <= $#minmax ; ++ $i) {
            for (my $j = 0 ; $j <= $#genargs ; ++ $j) {

                # Arguments to new().

                my $min = $minmax[$i][0];
                my $max = $minmax[$i][1];

                # Don't use Perl scalars with large absolute values.

                next if $ref eq '' && (abs($min) > 2147483647 ||
                                       abs($max) > 2147483647);

                # Arguments to generate().

                my $genargs = $genargs[$j];

                # Build a string with the test.

                my $test = $context eq 'scalar' ? '$x = ' : '@x = ';
                $test .= qq|$class -> new("min" => |;
                $test .= $ref ? qq|$ref -> new("$min")| : $min;
                $test .= qq|, "max" => |;
                $test .= $ref ? qq|$ref -> new("$max")| : $max;
                $test .= ") -> generate(@$genargs)";

                my ($x, @x);
                note "\n", $test, "\n\n";
                eval $test;
                die "\nThe following code failed to eval():\n\n",
                  "    ", $test, "\n\n", $@, "\n" if $@;

                if ($context eq 'scalar') {

                    subtest $test => sub {
                        plan tests => 3;

                        is(ref($x), "Math::BigInt",
                           "Output is a 'Math::BigInt'");
                        cmp_ok($x, ">=", $min,
                               "Output arg \$x is >= the min value");
                        cmp_ok($x, "<=", $max,
                               "Output arg \$ is <= the max value");
                    };

                } else {

                    my $n_out_expected = @$genargs ? $genargs->[0] : 1;
                    subtest $test => sub {
                        plan tests => 1 + 3 * $n_out_expected;

                        # Check number of output argument.

                        cmp_ok(scalar(@x), "==", $n_out_expected,
                               "Number of output arguments");

                        # Check each output argument.

                        for (my $i = 0 ; $i <= $#x ; ++$i) {
                            is(ref($x[$i]), "Math::BigInt",
                               "Output argument '\$x[$i]' is a 'Math::BigInt'");
                            cmp_ok($x[$i], ">=", $min,
                                   "Output arg '\$x[$i]' is >= the min value");
                            cmp_ok($x[$i], "<=", $max,
                                   "Output arg '\$x[$i]' is <= the max value");
                        }
                    };

                }
            }
        }
    }
}
