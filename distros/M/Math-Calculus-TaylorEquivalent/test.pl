# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use Test;
BEGIN { plan tests => 8 };

use Math::Calculus::TaylorEquivalent;
ok(1);

my $exp1 = Math::Calculus::TaylorEquivalent->new;
ok(ref $exp1);

my $exp2 = Math::Calculus::TaylorEquivalent->new;
ok(ref $exp2);

$exp1->addVariable('x');
$exp1->setExpression('(x + 1)*(x - 1)') or die $exp1->getError;
ok($exp1->getExpression eq '(x + 1)*(x - 1)');

$exp2->addVariable('x');
$exp2->setExpression('x^2 - 1') or die $exp2->getError;
ok($exp2->getExpression eq 'x^2 - 1');
  
my $result = $exp1->taylorEquivalent($exp2, 'x', 0);
ok($result == 1);
  
$exp2->addVariable('x');
$exp2->setExpression('x^2 + 1') or die $exp2->getError;
ok($exp2->getExpression eq 'x^2 + 1');
  
$result = $exp1->taylorEquivalent($exp2, 'x', 0);
ok($result == 0);
