use strict;
use Math::Symbolic qw(:all);
use Math::Symbolic::Custom::CollectSimplify;

use Test::Simple 'no_plan';

# test the complexity function

my %tests = (
    '2'                 =>  1,
    'x'                 =>  1,
    '2*x'               =>  4,
    '2*x + 6'           =>  7,
    'x^2 + y^2'         =>  9,
    '(x+2)*(y-3)'       =>  9,
    '(6*x+2)*(4+x)'     =>  12,
    '3*x+(2*(x+1))'     =>  12,
);

TEST_COMPLEXITY: while ( my ($test, $c) = each %tests ) {

    my $f1 = parse_from_string($test);
    # can the parser parse the test string?
    ok(defined($f1), "parsing test string [$test]");
    if (!defined $f1) {
        next TEST_COMPLEXITY;
    }  

    my $score = Math::Symbolic::Custom::CollectSimplify::test_complexity($f1);

    ok($c == $score, "Complexity score for expression matches [$test] [$c] [$score]");
}

# test to see if the new simplify method actually works

my $f1 = parse_from_string('2*(x+3)');
my $f2 = parse_from_string('(6*x+2)*(4+x)');
my $f3 = parse_from_string('3*x+(2*(x+1))');

my $f4 = $f1 + $f2 + $f3;

my $f4_s1 = $f4->simplify(); # default simplify() method

Math::Symbolic::Custom::CollectSimplify->register();

my $f4_s2 = $f4->simplify(); # new simplify() method

ok(defined $f4_s2, "Simplify routine returns output");
ok(length($f4_s2->to_string()) < length($f4_s1->to_string()), "New simplify routine returns shorter string than default");


