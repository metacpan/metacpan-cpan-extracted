# -*- mode: perl; -*-

# Verify that the output is a Math::BigInt when the output is an integer.

use strict;
use warnings;

use Test::More;

use Math::BigInt;
use Math::BigFloat;

Math::BigInt -> upgrade("Math::BigFloat");

my ($x, $y, $test);

$test = '$x = Math::BigInt -> new(1); $x -> bcos(20);';

note "\n", $test, "\n\n";
$y = eval $test;
die $@ if $@;

subtest $test => sub {
    plan tests => 4;

    is(ref($x), "Math::BigFloat", 'class of $x');
    is($x, "0.54030230586813971740", 'value of $x');
    is($x -> accuracy(), 20, 'accuracy of $x');
    is($x -> precision(), undef, 'precision of $x');
};

$test = '$x = Math::BigInt -> new(1); $x -> bcos(undef, 1);';

note "\n", $test, "\n\n";
$y = eval $test;
die $@ if $@;

subtest $test => sub {
    plan tests => 4;

    is(ref($x), "Math::BigInt", 'class of $x');
    is($x, "1", 'value of $x');         # 0.54030... rounded to integer
    is($x -> accuracy(), undef, 'accuracy of $x');
    is($x -> precision(), 1, 'precision of $x');
};

$test = '$x = Math::BigInt -> new(1); $x -> accuracy(20); $x -> bcos()';

note "\n", $test, "\n\n";
$y = eval $test;
die $@ if $@;

subtest $test => sub {
    plan tests => 4;

    is(ref($x), "Math::BigFloat", 'class of $x');
    is($x, "0.54030230586813971740", 'value of $x');
    is($x -> accuracy(), 20, 'accuracy of $x');
    is($x -> precision(), undef, 'precision of $x');
};

$test = '$x = Math::BigInt -> new(1); $x -> precision(1); $x -> bcos();';

note "\n", $test, "\n\n";
$y = eval $test;
die $@ if $@;

subtest $test => sub {
    plan tests => 4;

    is(ref($x), "Math::BigInt", 'class of $x');
    is($x, "1", 'value of $x');         # 0.54030... rounded to integer
    is($x -> accuracy(), undef, 'accuracy of $x');
    is($x -> precision(), 1, 'precision of $x');
};

done_testing();
