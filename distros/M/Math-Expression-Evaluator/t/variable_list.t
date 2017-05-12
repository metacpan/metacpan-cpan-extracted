use strict;
use warnings;
use Test::More;
use Math::Expression::Evaluator;

# Test if the MEE->variables() list the correct variables

my @test = (
    ['a',               'a'],
    ['a^a',             'a'],
    ['a + b',           'a|b'],
    ['a * a + b',       'a|b'],
    ['2',               ''],
);

plan tests => scalar @test;
my $m = Math::Expression::Evaluator->new();

for (@test){
    $m->parse($_->[0]);
    is join('|', $m->variables()),$_->[1], "Extracted variables for '$_->[0]'";
}


# vim: sw=4 ts=4 expandtab syn=perl
