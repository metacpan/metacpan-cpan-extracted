#!perl
use Test::More tests => 8;

use strict;
use warnings;

BEGIN {
	use_ok('Math::Symbolic');
}

if ($ENV{TEST_YAPP_PARSER}) {
	require Math::Symbolic::Parser::Yapp;
	$Math::Symbolic::Parser = Math::Symbolic::Parser::Yapp->new();
}

use Math::Symbolic::ExportConstants qw/:all/;

my $exp = Math::Symbolic->parse_from_string('10^(a(x)*a(x))');
ok( 1, 'Term creation from string did not complain.' );

print "Expression: 10^(a(x)*a(x))\n\n";
print "prefix notation and evaluation: (a=2)\n";
print $exp->to_string('prefix') . " = " . $exp->value( a => 2 ) . "\n\n";

print "Now, we derive this totally to a: (prefix again)\n";

my $n_tree = $exp->new( 'total_derivative', $exp, 'a' );
ok( 1, 'Total derivative did not complain.' );

print $n_tree->to_string('prefix') . " = " . $n_tree->value( a => 2 ) . "\n\n";

print "Now, we apply the derivative to the term: (infix)\n";
my $derived = $n_tree->apply_derivatives();
ok( 1, 'Application of total derivative did not complain' );

print "$derived = " . $derived->value( a => 2 ) . "\n\n";

print "Finally, we simplify the derived term as much as possible:\n";
my $simplified = $derived->simplify();
print "$simplified = " . $derived->value( a => 2 ) . "\n\n";
ok( 1, 'Simplification of result did not complain' );

print "For a change, we derive the term to x.\n";
$n_tree =
  Math::Symbolic->parse_from_string('total_derivative(10^(a(x)*a(x)), x)');
ok( 1, 'Parsing total derivative (to sig var) from string did not complain' );

$derived = $n_tree->apply_derivatives();
ok( 1, 'Applying total derivative (to sig var) did not complain' );

print "The derived term becomes:\n";
print "$derived\n";
ok( 1, 'Printing result does not complain' );

print "Which simplifies as:\n";
print $derived->simplify();

