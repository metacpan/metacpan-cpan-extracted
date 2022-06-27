# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 62;

use Math::BigRat;

while (<DATA>) {
    s/#.*$//;                   # remove comments
    s/\s+$//;                   # remove trailing whitespace
    next unless length;         # skip empty lines

    my ($x_str, $expected) = split /:/;
    my ($x, $str);

    my $test = qq|\$x = Math::BigRat -> new("$x_str");|
             . qq| \$str = \$x -> bfstr();|;

    note "\n$test\n\n";
    eval $test;
    die $@ if $@;               # should never happen

    is($str, $expected, qq|output is "$expected"|);
    if ($x_str eq 'NaN') {
        ok($x -> is_nan(), "input object is unmodified");
    } else {
        cmp_ok($x, "==", $x_str, "input object is unmodified");
    }
}

__DATA__

NaN:NaN

inf:inf
-inf:-inf

0:0
-0:0

# positive numbers

0.001234375:79/64000
0.01234375:79/6400
0.1234375:79/640
1.234375:79/64
12.34375:395/32
123.4375:1975/16
1234.375:9875/8
12343.75:49375/4
123437.5:246875/2
1234375:1234375
12343750:12343750
123437500:123437500
1234375000:1234375000

# negative numbers

-0.001234375:-79/64000
-0.01234375:-79/6400
-0.1234375:-79/640
-1.234375:-79/64
-12.34375:-395/32
-123.4375:-1975/16
-1234.375:-9875/8
-12343.75:-49375/4
-123437.5:-246875/2
-1234375:-1234375
-12343750:-12343750
-123437500:-123437500
-1234375000:-1234375000
