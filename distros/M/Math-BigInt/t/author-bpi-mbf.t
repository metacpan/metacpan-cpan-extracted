#!perl

BEGIN {
    unless ($ENV{AUTHOR_TESTING}) {
        print "1..0 # SKIP these tests are for testing by the author";
        exit;
    }
}

use strict;
use warnings;

use Test::More tests => 9;

use Math::BigFloat;

my $pi = {
          16 => '3.141592653589793',
          40 => '3.141592653589793238462643383279502884197',
         };

subtest "Called as class method without argument.", sub {
    plan tests => 5;

    my $x;
    my $test = '$x = Math::BigFloat -> bpi()';

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    isa_ok($x, 'Math::BigFloat');
    is($x,         $pi -> {40}, "'$test' gives correct output");
    is($x -> {_a}, undef,       "'$test' gives correct accuracy");
    is($x -> {_p}, undef,       "'$test' gives correct precision");
};

subtest "Called as class method with scalar argument.", sub {
    plan tests => 5;

    my $x;
    my $test = '$x = Math::BigFloat -> bpi(16);';

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    isa_ok($x, 'Math::BigFloat');
    is($x,         $pi -> {16}, "'$test' gives correct output");
    is($x -> {_a}, 16,          "'$test' gives correct accuracy");
    is($x -> {_p}, undef,       "'$test' gives correct precision");
};

subtest "Called as class method with class argument.", sub {
    plan tests => 5;

    my ($n, $x);
    my $test = '$n = Math::BigFloat -> new("16"); '
             . '$x = Math::BigFloat -> bpi($n);';

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    isa_ok($x, 'Math::BigFloat');
    is($x,         $pi -> {16}, "'$test' gives correct output");
    is($x -> {_a}, 16,          "'$test' gives correct accuracy");
    is($x -> {_p}, undef,       "'$test' gives correct precision");
};

subtest "Called as instance method without argument.", sub {
    plan tests => 5;

    my $x;
    my $test = '$x = Math::BigFloat -> bnan(); $x -> bpi();';

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    isa_ok($x, 'Math::BigFloat');
    is($x,         $pi -> {40}, "'$test' gives correct output");
    is($x -> {_a}, undef,       "'$test' gives correct accuracy");
    is($x -> {_p}, undef,       "'$test' gives correct precision");
};

subtest "Called as instance method with scalar argument.", sub {
    plan tests => 5;

    my $x;
    my $test = '$x = Math::BigFloat -> bnan(); $x -> bpi(16);';

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    isa_ok($x, 'Math::BigFloat');
    is($x,         $pi -> {16}, "'$test' gives correct output");
    is($x -> {_a}, 16,          "'$test' gives correct accuracy");
    is($x -> {_p}, undef,       "'$test' gives correct precision");
};

subtest "Called as instance method with instance argument.", sub {
    plan tests => 5;

    my ($n, $x);
    my $test = '$n = Math::BigFloat -> new("16"); '
             . '$x = Math::BigFloat -> bnan(); '
             . '$x -> bpi($n);';

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    isa_ok($x, 'Math::BigFloat');
    is($x,         $pi -> {16}, "'$test' gives correct output");
    is($x -> {_a}, 16,          "'$test' gives correct accuracy");
    is($x -> {_p}, undef,       "'$test' gives correct precision");
};

subtest "Called as function without argument.", sub {
    plan tests => 5;

    my $x;
    my $test = '$x = Math::BigFloat::bpi();';

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    isa_ok($x, 'Math::BigFloat');
    is($x,         $pi -> {40}, "'$test' gives correct output");
    is($x -> {_a}, undef,       "'$test' gives correct accuracy");
    is($x -> {_p}, undef,       "'$test' gives correct precision");
};

subtest "Called as function with scalar argument.", sub {
    plan tests => 5;

    my $x;
    my $test = '$x = Math::BigFloat::bpi(16);';

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    isa_ok($x, 'Math::BigFloat');
    is($x,         $pi -> {16}, "'$test' gives correct output");
    is($x -> {_a}, 16,          "'$test' gives correct accuracy");
    is($x -> {_p}, undef,       "'$test' gives correct precision");
};

# The following is an ambiguous case. The argument list to bpi() is ($n), which
# is assumed to mean $n->bpi(), since we favour the OO-style. So in the test
# below, $n is assigned the value of pi with the default number of digits, and
# then $n is assigned to $x.

subtest "Called as function with instance argument.", sub {
    plan tests => 9;

    my ($n, $x);
    my $test = '$n = Math::BigFloat -> new("16"); '
             . '$x = Math::BigFloat::bpi($n);';

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    isa_ok($x, 'Math::BigFloat');
    is($x,         $pi -> {40}, "'$test' gives correct output");
    is($x -> {_a}, undef,       "'$test' gives correct accuracy");
    is($x -> {_p}, undef,       "'$test' gives correct precision");

    isa_ok($n, 'Math::BigFloat');
    is($n,         $pi -> {40}, "'$test' gives correct output");
    is($n -> {_a}, undef,       "'$test' gives correct accuracy");
    is($n -> {_p}, undef,       "'$test' gives correct precision");
};
