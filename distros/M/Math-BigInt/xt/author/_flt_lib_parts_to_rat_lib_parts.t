# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 13;

use Math::BigInt;

my $LIB = Math::BigInt -> config('lib');

sub try {
    my ($in0, $in1, $in2, $in3, $out0, $out1, $out2) = @_;

    my @out;
    my ($ms, $ma, $es, $ea);
    my $test = qq|\$ms = "$in0"; \$ma = $LIB->_new("$in1"); |
             . qq|\$es = "$in2"; \$ea = $LIB->_new("$in3"); |
             . q|@out = Math::BigInt -> _flt_lib_parts_to_rat_lib_parts|
             . q|($ms, $ma, $es, $ea)|;

    note "\n$test\n\n";
    eval $test;
    die $@ if $@;       # this should never happen

    subtest $test => sub {
        plan tests => 6;

        is(scalar(@out), 3, 'number of output arguments');
        is($out[0], $out0, 'sign of the significand');
        is($LIB -> _str($out[1]), $out1, 'absolute value of the numerator');
        is($LIB -> _str($out[2]), $out2, 'absolute value of the denominator');
        is($LIB -> _str($ma), $in1, 'abs value of mantissa has not changed');
        is($LIB -> _str($ea), $in3, 'abs value of exponent has not changed');
    };
}

try qw< + 0     + 0 >, qw< +  0  1 >;
try qw< + 1     + 0 >, qw< +  1  1 >;
try qw< + 1     + 1 >, qw< + 10  1 >;
try qw< + 1     - 1 >, qw< +  1 10 >;
try qw< + 5     - 1 >, qw< +  1  2 >;

try qw< + 78125 - 7 >, qw< +     1 128 >;
try qw< +   512 + 0 >, qw< +   512   1 >;

try qw< +   123 + 2 >, qw< + 12300   1 >;

try qw< +  6375 - 3 >, qw<  + 51     8 >;

try qw< -  4875 - 2 >, qw< - 195     4 >;

try qw< +          44403076171875 - 16 >, qw< +      291    65536 >;

try qw< + 87894499301910400390625 - 25 >, qw< +   294925 33554432 >;

try qw< -       18432003173828125 - 12 >, qw< - 75497485     4096 >;
