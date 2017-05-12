#!perl
use strict;
use warnings;

use Test::More tests => 32;

BEGIN {
	use_ok('Math::Symbolic');
	use_ok('Math::Symbolic::VectorCalculus');
}

if ($ENV{TEST_YAPP_PARSER}) {
	require Math::Symbolic::Parser::Yapp;
	$Math::Symbolic::Parser = Math::Symbolic::Parser::Yapp->new();
}

use Math::Symbolic::ExportConstants qw/:all/;

my $var = Math::Symbolic::Variable->new();
ok( ref($var) eq 'Math::Symbolic::Variable', 'Variable prototype' );

my $a = $var->new( 'a' => 2 );
ok(
    ref($a) eq 'Math::Symbolic::Variable'
      && $a->value() == 2
      && $a->name() eq 'a',
    'Variable creation, value(), and name()'
);

my $b = $var->new( 'b' => 3 );
my $c = $var->new( 'c' => 4 );

print "Vars: a="
  . $a->value() . " b="
  . $b->value() . " c="
  . $c->value()
  . " (Values are optional)\n\n";

my $op = Math::Symbolic::Operator->new();
ok( ref($op) eq 'Math::Symbolic::Operator', 'Operator prototype' );

my $add1 = $op->new( '+', $a, $c );
ok( ref($add1) eq 'Math::Symbolic::Operator' && $add1->type() == B_SUM,
    'Operator creation, type()' );

my $mult1 = $op->new( '*', $a,    $b );
my $div1  = $op->new( '/', $add1, $mult1 );

print "Expression: (a+c)/(a*b)\n\n";

print "prefix notation and evaluation:\n";

eval <<'HERE';
print $div1->to_string('prefix') . " = " . $div1->value() . "\n\n";
HERE
ok( !$@, 'to_string("prefix") did not complain' );

print "Now, we derive this partially to a: (prefix again)\n";

my $n_tree;
eval <<'HERE';
$n_tree = $op->new( {
	type => U_P_DERIVATIVE,
	operands => [$div1, $a],
} );
HERE
ok( !$@, 'long-form partial derivative did not complain' );
ok(
    ref($n_tree) eq 'Math::Symbolic::Operator'
      && $n_tree->type() == U_P_DERIVATIVE,
    ,
    'long-form partial derivative returned derivative'
);

print $n_tree->to_string('prefix') . " = " . $n_tree->value() . "\n\n";

print "Now, we apply the derivative to the term: (infix)\n";

$@ = undef;
my $derived;
eval <<'HERE';
$derived = $n_tree->apply_derivatives();
HERE
ok( !$@, 'apply_derivatives() did not complain' );

print "$derived = " . $derived->value() . "\n\n";

print "Finally, we simplify the derived term as much as possible:\n";

$@ = undef;
my $simplified;
eval <<'HERE';
$simplified = $derived->simplify();
HERE
ok( !$@&&defined($simplified), 'simplify() did not complain' );

print "$simplified = " . $derived->value() . "\n\n";

ok( Math::Symbolic::AuxFunctions::binomial_coeff( 0, 0 ) == 1,
    'binomial_coeff(0, 0)' );

ok( Math::Symbolic::AuxFunctions::binomial_coeff( 1, 1 ) == 1,
    'binomial_coeff(1, 1)' );

ok( Math::Symbolic::AuxFunctions::binomial_coeff( 4, 2 ) == 6,
    'binomial_coeff(4, 2)' );

ok( Math::Symbolic::AuxFunctions::binomial_coeff( 5, 2 ) == 10,
    'binomial_coeff(5, 2)' );

ok( Math::Symbolic::AuxFunctions::binomial_coeff( 5, 4 ) == 5,
    'binomial_coeff(5, 4)' );

ok( Math::Symbolic::AuxFunctions::binomial_coeff( 2, 4 ) == 0,
    'binomial_coeff(2, 4)' );

ok( Math::Symbolic::AuxFunctions::binomial_coeff( 2, -1 ) == 0,
    'binomial_coeff(2, -1)' );

ok( !defined( Math::Symbolic::AuxFunctions::bell_number(-1) ),
    'bell_number(-1)' );

my @bell_numbers = ( 1, 1, 2, 5, 15, 52, 203, 877, 4140, 21147, 115975 );

ok( Math::Symbolic::AuxFunctions::bell_number($_) == $bell_numbers[$_],
    "bell_number($_)" )
  for 0 .. $#bell_numbers;

my $special_constant = Math::Symbolic::Constant->zero();
ok(
    (
        ref $special_constant              eq 'Math::Symbolic::Constant'
          and $special_constant->{special} eq 'zero'
    ),
    "Special attribute on constants set correctly."
);

$special_constant->value(1);
ok(
    (
        not defined $special_constant->{special}
          or $special_constant->{special} ne 'zero'
    ),
    "Special attribute on constans unset correctly on change of value."
);

