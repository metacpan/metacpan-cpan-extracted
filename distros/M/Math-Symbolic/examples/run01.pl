#!/usr/bin/perl
use strict;
use warnings;

use lib '../lib/';
use Data::Dumper;

use Math::Symbolic qw/:all/;

my $var = Math::Symbolic::Variable->new();
my $a   = $var->new( 'a' => 2 );

print "Vars: a=" . $a->value() . " (Value is optional)\n\n";

my $const = Math::Symbolic::Constant->new();
my $ten   = $const->new(10);

my $op   = Math::Symbolic::Operator->new();
my $mul1 = $op->new( '*', $a, $a );

my $exp = $op->new( '^', $ten, $mul1 );

print "Expression: 10^(a*a)\n\n";

print "prefix notation and evaluation:\n";
print $exp->to_string('prefix') . " = " . $exp->value() . "\n\n";

print "Now, we derive this partially to a: (prefix again)\n";

my $n_tree = $op->new(
    {
        type     => U_P_DERIVATIVE,
        operands => [ $exp, $a ],
    }
);

print $n_tree->to_string('prefix') . " = " . $n_tree->value() . "\n\n";

print "Now, we apply the derivative to the term: (infix)\n";
my $derived = $n_tree->apply_derivatives();

print "$derived = " . $derived->value() . "\n\n";

print "Finally, we simplify the derived term as much as possible:\n";
my $simplified = $derived->simplify();
print "$simplified = " . $derived->value() . "\n\n";
