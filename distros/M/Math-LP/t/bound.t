#!perl -w
#
# min x1 + x2
# subject to
#   x1 > 0   # this way I want to test if the x1.lowerbound does not create difficulties
#
# WITH x1.lowerbound = - infinity and x2.lowerbound = -5 (the catch, of course)

use strict;
use Math::LP qw(:types);
use Math::LP::Constraint qw(:types);
use Test;

BEGIN {
    plan tests => 4;
}

my Math::LP $lp = new Math::LP;

# variables
my Math::LP::Variable $x1 = new Math::LP::Variable(name => 'x1');
my Math::LP::Variable $x2 = new Math::LP::Variable(name => 'x2', lower_bound => -5);

# objective function
$lp->minimize_for(make Math::LP::LinearCombination($x1,1,$x2,1));

# constraints
my Math::LP::Constraint $c1 = new Math::LP::Constraint(
    lhs  => make Math::LP::LinearCombination($x1,1),
    rhs  => 0.0,
    type => $GE,
);
$lp->add_constraint($c1);

# solve the LP
ok($lp->solve()); # 1

# analyze the results
ok($lp->optimum(), -5); # 2
ok($x1->{value},    0); # 3
ok($x2->{value},   -5); # 4
