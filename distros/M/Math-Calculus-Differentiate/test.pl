# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test;
BEGIN { plan tests => 12 }
my $res;

## BASIC MODULE TESTS

# Check include of module works.
use Math::Calculus::Differentiate;
ok(1);

# Create object.
my $exp = Math::Calculus::Differentiate->new;
ok($exp);

# Add a variable.
$res = $exp->addVariable('x');
ok($res);


## REGRESSION TESTS

# d[x] = 1
$exp->setExpression('x');
$exp->differentiate('x');
$exp->simplify;
$res = $exp->getExpression;
ok($res eq '1');

# d[-x] = -1
$exp->setExpression('-x');
$exp->differentiate('x');
$exp->simplify;
$res = $exp->getExpression;
ok($res eq '-1');

# d[x^2 + 4*x + 5] = 2*x + 4
$exp->setExpression('x^2 + 4*x + 5');
$exp->differentiate('x');
$exp->simplify;
$res = $exp->getExpression;
ok($res eq '2*x + 4');

# d[sin(-2 * x)] = -2*cos(-2*x)
$exp->setExpression('sin(-2 * x)');
$exp->differentiate('x');
$exp->simplify;
$res = $exp->getExpression;
ok($res eq '-2*cos(-2*x)');

# d[asin(x)] = 1/(1 - x^2)^0.5
$exp->setExpression('asin(x)');
$exp->differentiate('x');
$exp->simplify;
$res = $exp->getExpression;
ok($res eq '1/(1 - x^2)^0.5');

# d[ln(x^2)] = (2*x)/x^2
$exp->setExpression('ln(x^2)');
$exp->differentiate('x');
$exp->simplify;
$res = $exp->getExpression;
ok($res eq '(2*x)/x^2');

# d[x^x] = exp(ln(x)*x)*(1 + ln(x))
$exp->setExpression('x^x');
$exp->differentiate('x');
$exp->simplify;
$res = $exp->getExpression;
ok($res eq 'exp(ln(x)*x)*(1 + ln(x))');

# d[x/x] = 0
$exp->setExpression('x/x');
$exp->differentiate('x');
$exp->simplify;
$res = $exp->getExpression;
ok($res eq '0');

# d[x - x] = 0
$exp->setExpression('x - x');
$exp->differentiate('x');
$exp->simplify;
$res = $exp->getExpression;
ok($res eq '0');

