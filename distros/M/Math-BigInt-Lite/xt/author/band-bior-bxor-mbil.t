# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 735;

use Math::BigInt::Lite;

use Math::Complex;
my $inf = $Math::Complex::Inf;
my $nan = $inf - $inf;

# There seems to be a discrepancey between what you get with these two
#
#     $z1 = $x & $y
#     $z2 = Math::BigInt -> new($x) -> band($y)
#
# when $x and/or $y are negative or +/-inf. Ditto for inclusive or and
# excluseive or. Fixme!

#my @num = ($nan, -$inf, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, $inf);
#my @num = ($nan, -$inf, 0, 1, 2, 3, 4, 5, $inf);
my @num = ($nan, 0, 1, 2, 3, 4, 5);

my @ref = ('Math::BigInt::Lite',
           'Math::BigInt',
           'Math::BigFloat',
           'Math::BigRat',
           '',                          # scalar
          );

my $pinf_lim = +2e+9;     # anything larger is considered +inf
my $ninf_lim = -2e+9;     # anything larger is considered -inf

if (0) {
    my %seen;
    while (@num < 100) {
        my $rand = 6 + int rand(1e+9 - 6);
        $rand = -$rand if rand() < 0.5;
        next if $seen{$rand}++;
        push @num, $rand;
    }
}

for my $class (@ref) {

    if ($class) {
        eval "require $class";
        die $@ if $@;
    }

    for my $method ('band', 'bior', 'bxor') {

        for my $xnum (@num) {
            for my $ynum (@num) {

                my $znum = $xnum != $xnum    ? $nan
                         : $ynum != $ynum    ? $nan
                         : $method eq 'band' ? $xnum & $ynum
                         : $method eq 'bior' ? $xnum | $ynum
                         : $method eq 'bxor' ? $xnum ^ $ynum
                         : die "internal error";

                my $xstr = $xnum == -$inf ? "-inf"
                         : $xnum == +$inf ? "+inf"
                         : $xnum != $xnum ? "NaN"
                         : $xnum;

                my $ystr = $ynum == -$inf ? "-inf"
                         : $ynum == +$inf ? "+inf"
                         : $ynum != $ynum ? "NaN"
                         : $ynum;

                my $zstr = $znum < $ninf_lim ? "-inf"
                         : $znum > $pinf_lim ? "+inf"
                         : $znum != $znum    ? "NaN"
                         : $znum;

                my ($x, $y, $z);

                my $test = qq|\$x = Math::BigInt::Lite -> new("$xstr"); |;
                if ($class) {
                    $test .= qq|\$y = $class -> new("$ystr"); |;
                } else {
                    if ($ystr =~ /\+?inf/i) {
                        $test .= q|$y = $inf; |;
                    } elsif ($ystr =~ /-inf/i) {
                        $test .= q|$y = -$inf; |;
                    } elsif ($ystr =~ /nan/i) {
                        $test .= q|$y = $nan; |;
                    } else {
                        $test .= qq|\$y = $ystr; |;
                    }
                }
                $test .= qq|\$z = \$x -> $method(\$y);|;

                note("\n$test\n\n");
                eval $test;
                die $@ if $@;           # this should never happen

                subtest $test, sub {
                    plan tests => 1;

                    is($z, $zstr, 'output arg has the right value');
                };
            }

        }
    }
}
