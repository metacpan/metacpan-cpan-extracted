# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 2 * 50;

use Math::BigInt;

while (<DATA>) {
    s/#.*$//;                   # remove comments
    s/\s+$//;                   # remove trailing whitespace
    next unless length;         # skip empty lines

    my ($x_str, $expected) = split /:/;
    my ($x, $str);

    for my $accu ("undef", "20") {
        my $test = qq|Math::BigInt -> accuracy($accu);|
                 . qq| \$x = Math::BigInt -> new("$x_str");|
                 . qq| \$str = \$x -> bfstr();|;

        note "\n$test\n\n";
        eval $test;
        die $@ if $@;           # should never happen

        is($str, $expected, qq|output is "$expected"|);
        if ($x_str eq 'NaN') {
            ok($x -> is_nan(), "input object is unmodified");
        } else {
            cmp_ok($x, "==", $x_str, "input object is unmodified");
        }
    }
}

__DATA__

NaN:NaN

inf:inf
-inf:-inf

0:0
-0:0

# positive numbers

1:1
12:12
123:123
1234:1234
12343:12343
123437:123437
1234375:1234375
12343750:12343750
123437500:123437500
1234375000:1234375000

# negative numbers

-1:-1
-12:-12
-123:-123
-1234:-1234
-12343:-12343
-123437:-123437
-1234375:-1234375
-12343750:-12343750
-123437500:-123437500
-1234375000:-1234375000
