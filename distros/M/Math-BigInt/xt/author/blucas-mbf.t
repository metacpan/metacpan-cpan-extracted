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
   [ "-20", "-15127" ],
   [ "-15", "1364" ],
   [ "-2", "-3" ],
   [ "-1", "1" ],
   [ "0", "2" ],
   [ "1", "1" ],
   [ "2", "3" ],
   [ "15", "1364" ],
   [ "20", "15127" ],
   [ "250", "17656721319717734662791328845675730903632844218828123" ],
   [ "+inf", "inf" ],
   [ "-inf", "NaN" ],
   [ "NaN", "NaN" ],
  ];

# blucas() as instance method

for my $case (@$cases) {
    my ($in, $want) = @$case;
    my $test = qq|\$x = $class -> new("$in"); \$y = \$x -> blucas();|;
    note "\n$test\n\n";
    my ($x, $y);
    eval $test;
    die $@ if $@;
    is(ref($y), $class, "output class is $class");
    is($y, $want, "output value is $want");
}

# blucas() as class method

for my $case (@$cases) {
    my ($in, $want) = @$case;
    my $test = qq|\$y = $class -> blucas("$in");|;
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
    my $want = [ (2, 1, 3, 4, 7, 11, 18, 29, 47, 76, 123) [0 .. $k] ];
    my $test = qq|\@y = $class -> blucas("$k");|;
    note "\n$test\n\n";
    my @y;
    eval $test;
    die $@ if $@;
    is_deeply(\@y, $want, "output values");
}

for (my $k = -1 ; $k >= -10 ; $k--) {
    my $want = [ (2, 1, -3, 4, -7, 11, -18, 29, -47, 76, -123) [0 .. -$k] ];
    my $test = qq|\@y = $class -> blucas("$k");|;
    note "\n$test\n\n";
    my @y;
    eval $test;
    die $@ if $@;
    is_deeply(\@y, $want, "output values");
}
