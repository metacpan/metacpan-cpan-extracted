use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 65 }

use Math::Expression::Evaluator;

my $m = new Math::Expression::Evaluator;

# asin() seems to have a bad precision, so setting $epsilon
# to 1e-7 will cause a failure here. D'oh.
my $epsilon = 1e-6;

sub e {
    return $m->parse(shift)->val();
}

sub is_approx {
    my ($expr, $expected, $message) = @_;
    ok abs($m->parse($expr)->val()       - $expected) <= $epsilon, 
            $message;
    ok abs(&{$m->parse($expr)->compiled}() - $expected) <= $epsilon, 
            "$message (compiled)";
}

is_approx 'sqrt(4)',        2,          'sqrt';
is_approx 'sqrt(4,)',       2,          'sqrt'; # trailing comma allowed
is_approx 'pi()',           3.14159265, 'pi';
is_approx 'sin(pi())',      0,          'sin(pi())';
is_approx 'sin(pi()/2)',    1,          'sin(pi()/2)';
is_approx 'sin(0)',         0,          'sin(0)';
is_approx 'sin(sin(0.1))',  0.09966766, 'nested sin';
is_approx 'cos(0)',         1,          'cos(0)';
is_approx 'exp(0)',         1,          'exp(0)';
is_approx 'exp(3)',         20.085537,  'exp(3)';
is_approx 'log(exp(2))',    2,          'log(exp(2))';
is_approx 'log10(100)',     2,          'log10(100)';
is_approx 'log2(8)',        3,          'log2(8)';
is_approx 'sinh(0)',        0,          'sinh(0)';
is_approx 'sinh(1)',        1.1752012,  'sinh(1)';
is_approx 'sinh(sinh(1.1))',1.76973464, 'nested sinh';
is_approx 'cosh(0)',        1,          'cosh(0)';
is_approx 'cosh(1)',        1.5430806,  'cosh(1)';
is_approx 'theta(-3)',      0,          'theta(-3)';
is_approx 'theta(0)',       0,          'theta(0)';
is_approx 'theta(0.1)',     1,          'theta(0.1)';
is_approx 'asin(0.5)',      0.523599,   'asin(0.5)';
is_approx 'acos(0.5)',      1.0471976,  'acos(0.5)';
is_approx 'tan(0.5)',       0.54630249, 'tan(0.5)';
is_approx 'atan(0.5)',      0.46364761, 'atan(0.5)';
is_approx 'ceil(3)',        3,          'ceil(3)';
is_approx 'ceil(2.3)',      3,          'ceil(2.3)';
is_approx 'ceil(-2.3)',     -2,         'ceil(-2)';
is_approx 'floor(3)',       3,          'floor(3)';
is_approx 'floor(2.3)',     2,          'floor(2.3)';
is_approx 'floor(-2.3)',   -3,         'floor(-2.3)';

# parse test for a function with at least two arguments
# so far there is no such builtin, but it might be some time..
eval {
    $m->parse('foo(a, b, c)');
};
ok !$@, 'function call with multiple arguments parses';

eval {
    $m->val({ a => 1, b => 2, c => 3 });
};

ok $@, 'dies while calling undefined function';

eval {
    $m->compiled->({ a => 1, b => 2, c => 3 });
};

ok $@, 'dies while calling undefined function (compiled)';

