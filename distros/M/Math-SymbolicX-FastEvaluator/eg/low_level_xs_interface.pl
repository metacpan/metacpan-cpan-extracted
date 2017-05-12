use strict;
use warnings;
use Math::SymbolicX::FastEvaluator;
use Math::Symbolic qw/:all/;

my $eval = Math::SymbolicX::FastEvaluator->new(); 
my $expr = Math::SymbolicX::FastEvaluator::Expression->new(); 
my $op   = Math::SymbolicX::FastEvaluator::Op->new(); 

# This is RPN based: Essentially, compute "a+b^2"
$op->SetVariable();
$op->SetValue(1.0); # first variable (aka a)
$expr->AddOp($op);

$op->SetVariable();
$op->SetValue(2.0); # second variable (aka b)
$expr->AddOp($op);

$op->SetNumber();
$op->SetValue(2.0); # the exponent
$expr->AddOp($op);

$op->SetOpType(B_EXP); # see Math::Symbolic for this constant
$expr->AddOp($op);     # I.e. b^2

$op->SetOpType(U_SUM); # see Math::Symbolic for this constant
$expr->AddOp($op);     # I.e. a + (b^2)

$expr->SetNVars(2);

# Insert variables 1 and 2 (a and b) and evaluate:
print "The value is: " . $eval->Evaluate($expr, [3.1, 2.5]);
# should be 3.1+2.5**2 == 9.35

