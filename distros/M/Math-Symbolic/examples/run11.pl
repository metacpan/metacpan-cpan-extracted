#!/usr/bin/perl
use strict;
use warnings;

use lib '../lib';
use Data::Dumper;

use Math::Symbolic qw/:all/;

my $exp = Math::Symbolic->parse_from_string('10^(a(x)*a(x))');

print "Expression: 10^(a(x)*a(x))\n\n";
print "prefix notation and evaluation: (a=2)\n";
print $exp->to_string('prefix') . " = " . $exp->value( a => 2 ) . "\n\n";

print "Now, we derive this totally to a: (prefix again)\n";

my $n_tree = $exp->new( 'total_derivative', $exp, 'a' );

print $n_tree->to_string('prefix') . " = " . $n_tree->value( a => 2 ) . "\n\n";

print "Now, we apply the derivative to the term: (infix)\n";
my $derived = $n_tree->apply_derivatives();

print "$derived = " . $derived->value( a => 2 ) . "\n\n";

print "Finally, we simplify the derived term as much as possible:\n";
my $simplified = $derived->simplify();
print "$simplified = " . $derived->value( a => 2 ) . "\n\n";

print "For a change, we derive the term to x.\n";
$n_tree = $exp->new( 'total_derivative', $exp, 'x' );

print "$n_tree\n";

$derived = $n_tree->apply_derivatives();

print "The derived term becomes:\n";
print "$derived\n";

print "Which simplifies as:\n";
$derived = $derived->simplify();
print $derived, "\n\n";

print "But we're not satisfied. The total derivative cannot be applied to\n"
  . "'a' because a depends on 'x', but we don't know how. Let's implement 'a'\n"
  . "as 'x^2' and try again.\n";

$derived = $derived->implement( a => 'x^2' );

print "$derived\n\n";

print "Which ultimately becomes:\n";
$derived = $derived->apply_derivatives();
$derived = $derived->simplify();
print $derived, "\n";

