#!perl -w
use strict;
use Math::LP qw(:types);
use Math::LP::Constraint qw(:types);
use Test;

BEGIN {
    plan(tests => 8);
}

my Math::LP $lp = new Math::LP;

# variables
my Math::LP::Variable $x1 = new Math::LP::Variable(name => 'x1');
my Math::LP::Variable $x2 = new Math::LP::Variable(name => 'x2', is_int => 1);

# objective function
$lp->maximize_for(make Math::LP::LinearCombination($x1,1,$x2,2));

# constraints
my Math::LP::Constraint $c1 = new Math::LP::Constraint(
    lhs  => make Math::LP::LinearCombination($x1,1,$x2,1),
    rhs  => 2.1,
    type => $LE,
);
$lp->add_constraint($c1);
my Math::LP::Constraint $c2 = new Math::LP::Constraint(
    lhs  => make Math::LP::LinearCombination($x1,1,$x2,2),
    rhs  => 4.5,
    type => $LE,
);
$lp->add_constraint($c2);

# solve the LP
ok($lp->solve()); # 1

# analyze the results
ok($lp->optimum(),           4.1); # 2
ok($x1->{value},             0.1); # 3
ok($x2->{value},             2.0); # 4
ok($c1->{slack},             0.0); # 5
ok($c2->{slack},             0.4); # 6
ok($c1->{dual_value},        1.0); # 7
ok($c2->{dual_value},        0.0); # 8

