# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use Test;
BEGIN { plan tests => 6 };

use Math::Calculus::TaylorSeries;
ok(1);

my $exp = Math::Calculus::TaylorSeries->new;
ok(ref $exp);
  
$exp->addVariable('x');
$exp->setExpression('sin(x)');
ok($exp->getExpression, 'sin(x)');

my $result = $exp->taylorSeries('x', 5, 0);
ok(ref $result);

ok($result->getExpression, 'x - x^3/6 + x^5/120 - x^7/5040 + x^9/362880');

$exp->setExpression('x^2 + 2*x + 1');
$result = $exp->taylorSeries('x', 2, 0);
ok($result->getExpression, '1 + 2*x');
