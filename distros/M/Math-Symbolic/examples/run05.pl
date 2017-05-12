#!/usr/bin/perl
use strict;
use warnings;

use lib '../lib';
use Data::Dumper;

use Math::Symbolic qw/:all/;

my $var = Math::Symbolic::Variable->new();
my $a   = $var->new( 'x' => 2 );

print "Vars: x=" . $a->value() . " (Value is optional)\n\n";

my $op  = Math::Symbolic::Operator->new();
my $exp = $op->new( '^', $a, $a );

print "Expression: x^x\n\n";

print "prefix notation and evaluation:\n";
print $exp->to_string('prefix') . "\n\n";

print "Now, we derive this partially to x: (prefix again)\n";

my $n_tree = $op->new(
    {
        type     => U_P_DERIVATIVE,
        operands => [ $exp, $a ],
    }
);

print $n_tree->to_string('prefix') . "\n\n";

print "Now, we apply the derivative to the term: (infix)\n";
my $derived = $n_tree->apply_derivatives();

print "$derived\n\n";

print "Finally, we simplify the derived term as much as possible:\n";
my $simplified = $derived->simplify();
print "$simplified\n\n";
