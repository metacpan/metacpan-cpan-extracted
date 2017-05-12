#!/usr/bin/perl
use strict;
use warnings;

use lib '../lib';
use Data::Dumper;

use Math::Symbolic qw/:all/;

my $var = Math::Symbolic::Variable->new();
my $a   = $var->new( 'x' => 3.14159 );

print "Vars: x=" . $a->value() . " (Value is optional)\n\n";

my $first  = $a * 2 + 1;      # x*2 + 1
my $second = $a * "2 + 1";    # x*3
my $third  = -$a;

print "Expression: x * 2 + 1, x * (2+1), -x\n\n";

print "prefix notation and evaluation:\n";
print $first->to_string('prefix') . " = " . $first->value() . "\n\n";
print $second->to_string('prefix') . " = " . $second->value() . "\n\n";
print $third->to_string('prefix') . " = " . $third->value() . "\n\n";

print "Now, we derive this partially to x: (prefix again)\n";

my $n_tree = Math::Symbolic::Operator->new(
    {
        type     => U_P_DERIVATIVE,
        operands => [ $first, $a ],
    }
);
my $n_tree2 = Math::Symbolic::Operator->new(
    {
        type     => U_P_DERIVATIVE,
        operands => [ $second, $a ],
    }
);
my $n_tree3 = Math::Symbolic::Operator->new(
    {
        type     => U_P_DERIVATIVE,
        operands => [ $third, $a ],
    }
);

print $n_tree->to_string('prefix') . " = " . $n_tree->value() . "\n\n";
print $n_tree2->to_string('prefix') . " = " . $n_tree2->value() . "\n\n";
print $n_tree3->to_string('prefix') . " = " . $n_tree3->value() . "\n\n";

print "Now, we apply the derivative to the terms: (infix)\n";
my $derived  = $n_tree->apply_derivatives();
my $derived2 = $n_tree2->apply_derivatives();
my $derived3 = $n_tree3->apply_derivatives();

print "$derived" . " = " . $derived->value() . "\n\n";
print "$derived2" . " = " . $derived2->value() . "\n\n";
print "$derived3" . " = " . $derived3->value() . "\n\n";

print "Finally, we simplify the derived term as much as possible:\n";
$derived = $derived->simplify();
print "$derived = " . $derived->value() . "\n\n";
$derived2 = $derived2->simplify();
print "$derived2 = " . $derived2->value() . "\n\n";
$derived3 = $derived3->simplify();
print "$derived3 = " . $derived3->value() . "\n\n";

