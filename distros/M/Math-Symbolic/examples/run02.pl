#!/usr/bin/perl
use strict;
use warnings;

use lib '../lib/';
use Data::Dumper;

use Math::Symbolic qw/:all/;

my $var = Math::Symbolic::Variable->new();
my $a   = $var->new( 'a' => 2 );
my $b   = $var->new( 'b' => 3 );
my $c   = $var->new( 'c' => 4 );

print "Vars: a="
  . $a->value() . " b="
  . $b->value() . " c="
  . $c->value()
  . " (Values are optional)\n\n";

my $op    = Math::Symbolic::Operator->new();
my $add1  = $op->new( '+', $a, $c );
my $mult1 = $op->new( '*', $a, $b );
my $div1  = $op->new( '/', $add1, $mult1 );

print "Expression: (a+c)/(a*b)\n\n";

print "prefix notation and evaluation:\n";
print $div1->to_string('prefix') . " = " . $div1->value() . "\n\n";

print "Now, we derive this partially to a: (prefix again)\n";

my $n_tree = $op->new(
    {
        type     => U_P_DERIVATIVE,
        operands => [ $div1, $a ],
    }
);
print $n_tree->to_string('prefix') . " = " . $n_tree->value() . "\n\n";

print "Now, we apply the derivative to the term: (infix)\n";
my $derived = $n_tree->apply_derivatives();
print "$derived = " . $derived->value() . "\n\n";

print "Finally, we simplify the derived term as much as possible:\n";
my $simplified = $derived->simplify();
print "$simplified = " . $derived->value() . "\n\n";

