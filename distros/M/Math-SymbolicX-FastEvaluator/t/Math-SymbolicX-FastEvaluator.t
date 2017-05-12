use strict;
use warnings;
use Test::More;
use vars '$tests';
plan tests => $tests;

use Math::Symbolic qw/:all/;

use aliased 'Math::SymbolicX::FastEvaluator';
use aliased 'Math::SymbolicX::FastEvaluator::Expression';
use aliased 'Math::SymbolicX::FastEvaluator::Op';
use Math::Symbolic::Custom::DumpToFastEval;

my $fe = FastEvaluator->new();
isa_ok($fe, 'Math::SymbolicX::FastEvaluator');
my $exp = Expression->new();
isa_ok($exp, 'Math::SymbolicX::FastEvaluator::Expression');
my $op = Op->new();
isa_ok($op, 'Math::SymbolicX::FastEvaluator::Op');
BEGIN {$tests += 3}

SCOPE: {
  #diag('testing simple, constant tree');
  my $tree = parse_from_string("1.+cos(3.14159)*2.");
  can_ok($tree, 'to_fasteval');
  my $expr = $tree->to_fasteval();
  isa_ok($expr, 'Math::SymbolicX::FastEvaluator::Expression');
  is($expr->GetNVars(), 0, 'no variables in simple expr');
  ok(_eq($tree->value(), $fe->Evaluate($expr)), 'simple expr, value() eq fasteval');
  eval { $fe->Evaluate($expr, [1,2,3,4,5]) };
  ok($@, 'bad number of vars to Evaluate dies');
  BEGIN {$tests += 5}
}

SCOPE: {
  #diag('testing with variables');
  my $tree = parse_from_string("1.+cos(3.14159)*2.+a/b");
  can_ok($tree, 'to_fasteval');
  my $expr = $tree->to_fasteval();
  isa_ok($expr, 'Math::SymbolicX::FastEvaluator::Expression');
  is($expr->GetNVars(), 2, 'two variables in var expr');
  ok(_eq($tree->value(a=>3.,b=>1.), $fe->Evaluate($expr, [3., 1.])), 'var expr, value() eq fasteval');
  eval { $fe->Evaluate($expr, []) };
  ok($@, 'bad number of vars to Evaluate dies');
  BEGIN {$tests += 5}
}


SCOPE: {
  #diag('testing Expr->Evaluate');
  my $tree = parse_from_string("1.+cos(3.14159)*2.+a/b");
  can_ok($tree, 'to_fasteval');
  my $expr = $tree->to_fasteval();
  isa_ok($expr, 'Math::SymbolicX::FastEvaluator::Expression');
  is($expr->GetNVars(), 2, 'two variables in var expr');
  ok(_eq($tree->value(a=>3.,b=>1.), $expr->Evaluate([3., 1.])), 'var expr, value() eq fasteval');
  eval { $expr->Evaluate([]) };
  ok($@, 'bad number of vars to Evaluate dies');
  BEGIN {$tests += 5}
}


sub _eq {
  return (
    @_ > 2
      ? ($_[0]+$_[2] > $_[1] and $_[0]-$_[2] < $_[1])
      : ($_[0]+1.e-9 > $_[1] and $_[0]-1.e-9 < $_[1])
  );
}

__END__

my $fe = Math::SymbolicX::FastEvaluator->new();


my $exp = Math::SymbolicX::FastEvaluator::Expression->new();

my $op = Math::SymbolicX::FastEvaluator::Op->new();
$op->SetValue(1.3);
$op->SetOpType(B_SUM);

foreach (1..300000) {
  print "i\n" if not $_% 10000;
  $exp->AddOp($op);
}
undef $op;
undef $exp;

print "one:\n";
my $t = <STDIN>;

foreach (1..100) {
  my $exp = Math::SymbolicX::FastEvaluator::Expression->new();

  my $op = Math::SymbolicX::FastEvaluator::Op->new();
  $op->SetValue(1.3);
  $op->SetOpType(B_SUM);

  foreach (1..300000) {
    print "i\n" if not $_% 10000;
    $exp->AddOp($op);
  }
  undef $op;
  undef $exp;
}

print "two:\n";
$t = <STDIN>;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

