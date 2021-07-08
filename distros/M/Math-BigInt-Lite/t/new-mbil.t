#!perl

use strict;
use warnings;

use Test::More tests => 27;

use Math::BigInt::Lite;

while (<DATA>) {
    s/#.*$//;                   # remove comments
    s/\s+$//;                   # remove trailing whitespace
    next unless length;         # skip empty lines

    my ($in, $want) = split /:/;
    my $got;
    my $test = qq|\$got = Math::BigInt::Lite -> new("$in")|;

    eval $test;
    die $@ if $@;       # this should never happen

    is($got -> bstr(), $want,
       "'$test' output arg has the right value");
}

__DATA__

Inf:inf
-Inf:-inf
+Inf:inf

inf:inf
-inf:-inf
+inf:inf

Infinity:inf
-Infinity:-inf
+Infinity:inf

infinity:inf
-infinity:-inf
+infinity:inf

NaN:NaN
+NaN:NaN
-NaN:NaN

# decimal numbers

123:123
1.23e2:123
12300e-2:123

# leading zeros are ignored, so these are also decimal numbers

01337:1337
01337:1337

# underscores are also ignored, so there are also decimal numbers

67_538_754:67538754

# hexadecimal numbers

0xcafe:51966
0XCAFE:51966

# octal numbers

0o1337:735
0O1337:735

# binary numbers

0b1101:13
0B1101:13
