#!perl
use strict;
use warnings;

use Test::More tests => 4;

#use lib 'lib';

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

my $c   = Math::Symbolic::Constant->zero();
my $e   = $c->euler();
my $two = $c->new(2);

print "Vars: a=" . $a->value() . " (Values are optional)\n\n";

my $op   = Math::Symbolic::Operator->new();
my $mul1 = $op->new( '*', $two, $a );
my $exp1 = $op->new( '^', $e, $mul1 );

print "prefix notation and evaluation:\n";
print $exp1->to_string('prefix') . " = " . $exp1->value() . "\n\n";

print "Now, we derive this partially to 'a' (10 times): (infix)\n";

my $n_tree = $op->new(
    {
        type     => U_P_DERIVATIVE,
        operands => [ $exp1, $a ],
    }
);
foreach ( 1 .. 10 ) {
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

ok( abs($n_tree->op1()->value()-2048)<1e-10 , 'Large coefficient and op1() method' );
ok( $n_tree->op2()->op2()->op1()->value() == 2, 'op2() method' );
ok(
    $n_tree->op2()->op1()->{special} eq 'euler',
    'op2() method, special euler trait'
);

