#!perl
use strict;
use warnings;

use Test::More tests => 4;

BEGIN {
	use_ok('Math::Symbolic');
}

if ($ENV{TEST_YAPP_PARSER}) {
	require Math::Symbolic::Parser::Yapp;
	$Math::Symbolic::Parser = Math::Symbolic::Parser::Yapp->new();
}

use Math::Symbolic::ExportConstants qw/:all/;

my $var = Math::Symbolic::Variable->new();
my $a   = $var->new( 'a' => 2 );

print "Vars: a=" . $a->value() . " (Value is optional)\n\n";

my $const = Math::Symbolic::Constant->zero();
my $ten   = $const->new(10);

my $op   = Math::Symbolic::Operator->new();
my $mul1 = $op->new( '*', $a, $a );

my $exp = $op->new( '^', $ten, $mul1 );
ok( ref($exp) eq 'Math::Symbolic::Operator' && $exp->type() == B_EXP,
    'Creation of exponentiation' );

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
$@ = undef;
my $derived;
eval <<'HERE';
$derived = $n_tree->apply_derivatives();
HERE
ok( !$@, 'apply_derivatives() did not complain' );

print "$derived\n";

print "$derived = " . $derived->value() . "\n\n";

print "Finally, we simplify the derived term as much as possible:\n";

$@ = undef;
my $simplified;
eval <<'HERE';
$simplified = $derived->simplify();
HERE
ok( !$@, 'simplify() did not complain' );

print "$simplified = " . $derived->value() . "\n\n";

