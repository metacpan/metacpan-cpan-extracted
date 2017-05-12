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
my Math::LP::Variable $x2 = new Math::LP::Variable(name => 'x2');

# objective function
$lp->maximize_for(make Math::LP::LinearCombination($x1,1,$x2,2));

# constraints
my Math::LP::Constraint $c1 = new Math::LP::Constraint(
    lhs  => make Math::LP::LinearCombination($x1,1,$x2,1),
    rhs  => 0.002,
    type => $LE,
);
$lp->add_constraint($c1);
my Math::LP::Constraint $c2 = new Math::LP::Constraint(
    lhs  => make Math::LP::LinearCombination($x1,1,$x2,2),
    rhs  => 0.003,
    type => $LE,
);
$lp->add_constraint($c2);

# solve the LP
ok($lp->solve()); # 1

# analyze the results
ok($lp->optimum(),           0.003 ); # 2
ok($x1->{value},             0.0   ); # 3
ok($x2->{value},             0.0015); # 4
ok($c1->{slack},             0.0005); # 5
ok($c2->{slack},             0.0   ); # 6
ok($c1->{dual_value},        0.0   ); # 7
ok($c2->{dual_value},        1.0   ); # 8

