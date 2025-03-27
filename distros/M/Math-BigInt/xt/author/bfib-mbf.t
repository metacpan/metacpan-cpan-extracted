# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 74;

my $class = "Math::BigFloat";
use_ok($class);

my $x;

###############################################################################
# Scalar context.
###############################################################################

my $y;

my $cases =
  [
   [ "-20", "-6765" ],
   [ "-15", "610" ],
   [ "-2", "-1" ],
   [ "-1", "1" ],
   [ "0", "0" ],
   [ "1", "1" ],
   [ "2", "1" ],
   [ "15", "610" ],
   [ "20", "6765" ],
   [ "250", "7896325826131730509282738943634332893686268675876375" ],
   [ "inf", "inf" ],
   [ "-inf", "NaN" ],
   [ "NaN", "NaN" ],
  ];

# bfib() as instance method

for my $case (@$cases) {
    my ($in, $want) = @$case;
    my $test = qq|\$x = $class -> new("$in"); \$y = \$x -> bfib();|;
    note "\n$test\n\n";
    my ($x, $y);
    eval $test;
    die $@ if $@;
    is(ref($y), $class, "output class is $class");
    is($y, $want, "output value is $want");
}

# bfib() as class method

for my $case (@$cases) {
    my ($in, $want) = @$case;
    my $test = qq|\$y = $class -> bfib("$in");|;
    note "\n$test\n\n";
    my $y;
    eval $test;
    die $@ if $@;
    is(ref($y), $class, "output class is $class");
    is($y, $want, "output value is $want");
}

###############################################################################
# List context.
###############################################################################

for (my $k = 0 ; $k <= 10 ; $k++) {
    my $want = [ (0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55) [0 .. $k] ];
    my $test = qq|\@y = $class -> bfib("$k");|;
    note "\n$test\n\n";
    my @y;
    eval $test;
    die $@ if $@;
    is_deeply(\@y, $want, "output values") or diag(<<"EOF");

         got: ( @{[ join ", ", @y ]} )
    expected: ( @{[ join ", ", @$want ]} )

EOF
}

for (my $k = -1 ; $k >= -10 ; $k--) {
    my $want = [ (0, 1, -1, 2, -3, 5, -8, 13, -21, 34, -55) [0 .. -$k] ];
    my $test = qq|\@y = $class -> bfib("$k");|;
    note "\n$test\n\n";
    my @y;
    eval $test;
    die $@ if $@;
    is_deeply(\@y, $want, "output values");
}
