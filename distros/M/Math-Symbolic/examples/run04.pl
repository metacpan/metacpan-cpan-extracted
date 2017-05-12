#!/usr/bin/perl
use strict;
use warnings;

use lib '../lib';

use Math::Symbolic qw/:all/;
use Benchmark;

my $var = Math::Symbolic::Variable->new();
my $a   = $var->new( 'a' => 2 );

my $c   = Math::Symbolic::Constant->new();
my $e   = $c->euler();
my $two = $c->new(2);

print "Vars: a=" . $a->value() . " (Values are optional)\n\n";

my $op   = Math::Symbolic::Operator->new();
my $mul1 = $op->new( '*', $two, $a );
my $exp1 = $op->new( '^', $e, $mul1 );

print "prefix notation and evaluation:\n";
print $exp1->to_string('prefix') . " = " . $exp1->value() . "\n\n";

print "Now, we derive this partially to a (20 times): (infix)\n";

use Time::HiRes qw/time/;

my $n_tree = $op->new(
    {
        type     => U_P_DERIVATIVE,
        operands => [ $exp1, $a ],
    }
);
foreach ( 1 .. 100 ) {
    print "$_\n";
    $n_tree = $op->new(
        {
            type     => U_P_DERIVATIVE,
            operands => [ $n_tree, $a ],
        }
    );
    $n_tree = $n_tree->apply_derivatives();
    $n_tree = $n_tree->simplify();
}

print $n_tree->to_string('infix') . " = " . $n_tree->value() . "\n\n";

