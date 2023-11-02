# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;

use Math::BigInt;

use Test::More;

my @x = (-20 .. 20);
my @y = (  0 .. 10);
my @b = (-10 .. 10);

my $cls = "Math::BigInt";

@x = ("-inf", @x, "inf", "NaN");
@y = ("-inf", @y, "inf", "NaN");
@b = ("-inf", @b, "inf", "NaN");

# Math::BigInt -> brsft($x, $y, $b)

for my $b (@b) {
    for my $x (@x) {
        for my $y (@y) {

            note "\n";
            note "\$z = $cls -> brsft(",
              ($x =~ /inf|nan/i ? qq|"$x"| : $x),
              ", ",
              ($y =~ /inf|nan/i ? qq|"$y"| : $y),
              ", ",
              ($b =~ /inf|nan/i ? qq|"$b"| : $b),
              ");";
            note "\n";

            my $zobj = eval { $cls -> brsft($x, $y, $b) };
            is($@, '', "eval succeeded");

            my $want = $y > 0 ? $cls -> new($x) -> bdiv($cls -> new($b) -> bpow($y))
                              : $cls -> new($x) -> bmul($cls -> new($b) -> bpow(-$y));

            is(ref($zobj), $cls, "output class is $cls");
            is($zobj, $want, "output value is $want");
        }
    }
}

# Math::BigInt -> new($x) -> brsft($y, $b)

for my $b (@b) {
    for my $x (@x) {
        for my $y (@y) {

            note "\n";
            note "\$x = $cls -> new(",
              ($x =~ /inf|nan/i ? qq|"$x"| : $x),
              "); \$z = \$x -> brsft(",
              ($y =~ /inf|nan/i ? qq|"$y"| : $y),
              ", ",
              ($b =~ /inf|nan/i ? qq|"$b"| : $b),
              ");";
            note "\n";

            my $xobj = $cls -> new($x);
            my $zobj = eval { $xobj -> brsft($y, $b) };
            is($@, '', "eval succeeded");

            my $want = $y > 0 ? $cls -> new($x) -> bdiv($cls -> new($b) -> bpow($y))
                              : $cls -> new($x) -> bmul($cls -> new($b) -> bpow(-$y));

            is(ref($zobj), $cls, "output class is $cls");
            is($zobj, $want, "output value is $want");
            is($xobj, $want, "invocand value $xobj is the output");
        }
    }
}

done_testing();
