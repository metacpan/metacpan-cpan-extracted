# -*- mode: perl; -*-

# Verify that the output is a Math::BigInt when the output is an integer.

use strict;
use warnings;

use Test::More;

use Math::BigInt;
use Math::BigFloat;

Math::BigInt -> upgrade("Math::BigFloat");

my $test;

$test = '$x = Math::BigInt -> new(1); $x -> bsin(20);';
note "\n", $test, "\n\n";

subtest $test => sub {
    plan tests => 4;

    my $x;
    my $y = eval $test;
    die $@ if $@;

    is(ref($x), "Math::BigFloat", 'class of $x');
    is($x, "0.84147098480789650665", 'value of $x');
    is($x -> accuracy(), 20, 'accuracy of $x');
    is($x -> precision(), undef, 'precision of $x');
};

$test = '$x = Math::BigInt -> new(1); $x -> bsin(undef, 1);';
note "\n", $test, "\n\n";

subtest $test => sub {
    plan tests => 4;

    my $x;
    my $y = eval $test;
    die $@ if $@;

    is(ref($x), "Math::BigInt", 'class of $x');
    is($x, "1", 'value of $x');         # 0.84147... rounded to integer
    is($x -> accuracy(), undef, 'accuracy of $x');
    is($x -> precision(), 1, 'precision of $x');
};

$test = '$x = Math::BigInt -> new(1); $x -> accuracy(20); $x -> bsin()';
note "\n", $test, "\n\n";

subtest $test => sub {
    plan tests => 4;

    my $x;
    my $y = eval $test;
    die $@ if $@;

    is(ref($x), "Math::BigFloat", 'class of $x');
    is($x, "0.84147098480789650665", 'value of $x');
    is($x -> accuracy(), 20, 'accuracy of $x');
    is($x -> precision(), undef, 'precision of $x');
};

$test = '$x = Math::BigInt -> new(1); $x -> precision(1); $x -> bsin();';
note "\n", $test, "\n\n";

subtest $test => sub {
    plan tests => 4;

    my $x;
    my $y = eval $test;
    die $@ if $@;

    is(ref($x), "Math::BigInt", 'class of $x');
    is($x, "1", 'value of $x');         # 0.84147... rounded to integer
    is($x -> accuracy(), undef, 'accuracy of $x');
    is($x -> precision(), 1, 'precision of $x');
};

done_testing();
