#!perl -w
use strict;
use Math::LP qw(:types);
use Math::LP::Constraint qw(:types);
use Getopt::Long;
use Test;
our($debugging);

BEGIN {
    plan(tests => 14);
}

GetOptions(
   "debug" => \$debugging,
);

my Math::LP $lp = new Math::LP;

# variables
my @var_names = qw(
  %bbox.x1 %bbox.x2 %bbox.y1 %bbox.y2 
  b1.x1 b1.x2 b1.y1 b1.y2 
  b2.x1 b2.x2 b2.y1 b2.y2
);
my %var = map {
    $_ => new Math::LP::Variable(name => $_)
} @var_names;

# objective function
# min: -2 bbox.x1 +2 bbox.x2 -2 bbox.y1 +2 bbox.y2;
$lp->minimize_for(Math::LP::LinearCombination->make($var{'%bbox.x1'},-2,$var{'%bbox.x2'},2,$var{'%bbox.y1'},-2,$var{'%bbox.y2'},2));

# Constraints
# +1 b1.x1 -1 b1.x2 < 0;
$lp->add_constraint(new Math::LP::Constraint(
  lhs  => Math::LP::LinearCombination->make($var{'b1.x1'},1,$var{'b1.x2'},-1),
  rhs  => 0.0,
  type => $LE,
));
# +1 b1.y1 -1 b1.y2 < 0 ;
$lp->add_constraint(new Math::LP::Constraint(
  lhs  => Math::LP::LinearCombination->make($var{'b1.y1'},1,$var{'b1.y2'},-1),
  rhs  => 0.0,
  type => $LE,
));
# +1 b2.x1 -1 b2.x2 < 0 ;
$lp->add_constraint(new Math::LP::Constraint(
  lhs  => Math::LP::LinearCombination->make($var{'b2.x1'},1,$var{'b2.x2'},-1),
  rhs  => 0.0,
  type => $LE,
));
# +1 b2.y1 -1 b2.y2 < 0 ;
$lp->add_constraint(new Math::LP::Constraint(
  lhs  => Math::LP::LinearCombination->make($var{'b2.y1'},1,$var{'b2.y2'},-1),
  rhs  => 0.0,
  type => $LE,
));
# +1 bbox.x1 -1 bbox.x2 < 0 ;
$lp->add_constraint(new Math::LP::Constraint(
  lhs  => Math::LP::LinearCombination->make($var{'%bbox.x1'},1,$var{'%bbox.x2'},-1),
  rhs  => 0.0,
  type => $LE,
));
# +1 bbox.y1 -1 bbox.y2 < 0 ;
$lp->add_constraint(new Math::LP::Constraint(
  lhs  => Math::LP::LinearCombination->make($var{'%bbox.y1'},1,$var{'%bbox.y2'},-1),
  rhs  => 0.0,
  type => $LE,
));
# +1 bbox.x1 -1 b1.x1 < 0 ;
$lp->add_constraint(new Math::LP::Constraint(
  lhs  => Math::LP::LinearCombination->make($var{'%bbox.x1'},1,$var{'b1.x1'},-1),
  rhs  => 0.0,
  type => $LE,
));
# -1 bbox.x2 +1 b1.x2 < 0 ;
$lp->add_constraint(new Math::LP::Constraint(
  lhs  => Math::LP::LinearCombination->make($var{'%bbox.x2'},-1,$var{'b1.x2'},1),
  rhs  => 0.0,
  type => $LE,
));
# +1 bbox.x1 -1 b2.x1 < 0 ;
$lp->add_constraint(new Math::LP::Constraint(
  lhs  => Math::LP::LinearCombination->make($var{'%bbox.x1'},1,$var{'b2.x1'},-1),
  rhs  => 0.0,
  type => $LE,
));
# -1 bbox.x2 +1 b2.x2 < 0 ;
$lp->add_constraint(new Math::LP::Constraint(
  lhs  => Math::LP::LinearCombination->make($var{'%bbox.x2'},-1,$var{'b2.x2'},1),
  rhs  => 0.0,
  type => $LE,
));
# +1 bbox.y1 -1 b1.y1 < 0 ;
$lp->add_constraint(new Math::LP::Constraint(
  lhs  => Math::LP::LinearCombination->make($var{'%bbox.y1'},1,$var{'b1.y1'},-1),
  rhs  => 0.0,
  type => $LE,
));
# -1 bbox.y2 +1 b1.y2 < 0 ;
$lp->add_constraint(new Math::LP::Constraint(
  lhs  => Math::LP::LinearCombination->make($var{'%bbox.y2'},-1,$var{'b1.y2'},1),
  rhs  => 0.0,
  type => $LE,
));
# +1 bbox.y1 -1 b2.y1 < 0 ;
$lp->add_constraint(new Math::LP::Constraint(
  lhs  => Math::LP::LinearCombination->make($var{'%bbox.y1'},1,$var{'b2.y1'},-1),
  rhs  => 0.0,
  type => $LE,
));
# -1 bbox.y2 +1 b2.y2 < 0 ;
$lp->add_constraint(new Math::LP::Constraint(
  lhs  => Math::LP::LinearCombination->make($var{'%bbox.y2'},-1,$var{'b2.y2'},1),
  rhs  => 0.0,
  type => $LE,
));
# +1 b1.x1 -1 b1.x2 < -0.7 ;
$lp->add_constraint(new Math::LP::Constraint(
  lhs  => Math::LP::LinearCombination->make($var{'b1.x1'},1,$var{'b1.x2'},-1),
  rhs  => -0.7,
  type => $LE,
));
# +1 b1.y1 -1 b1.y2 < -0.7 ;
$lp->add_constraint(new Math::LP::Constraint(
  lhs  => Math::LP::LinearCombination->make($var{'b1.y1'},1,$var{'b1.y2'},-1),
  rhs  => -0.7,
  type => $LE,
));
# +1 b2.x1 -1 b2.x2 < -0.7 ;
$lp->add_constraint(new Math::LP::Constraint(
  lhs  => Math::LP::LinearCombination->make($var{'b2.x1'},1,$var{'b2.x2'},-1),
  rhs  => -0.7,
  type => $LE,
));
# +1 b2.y1 -1 b2.y2 < -0.7 ;
$lp->add_constraint(new Math::LP::Constraint(
  lhs  => Math::LP::LinearCombination->make($var{'b2.y1'},1,$var{'b2.y2'},-1),
  rhs  => -0.7,
  type => $LE,
));
# -1 b1.x1 +1 b1.x2 < 10 ;
$lp->add_constraint(new Math::LP::Constraint(
  lhs  => Math::LP::LinearCombination->make($var{'b1.x1'},-1,$var{'b1.x2'},1),
  rhs  => 10.0,
  type => $LE,
));
# -1 b1.y1 +1 b1.y2 < 10 ;
$lp->add_constraint(new Math::LP::Constraint(
  lhs  => Math::LP::LinearCombination->make($var{'b1.y1'},-1,$var{'b1.y2'},1),
  rhs  => 10.0,
  type => $LE,
));
# -1 b2.x1 +1 b2.x2 < 10 ;
$lp->add_constraint(new Math::LP::Constraint(
  lhs  => Math::LP::LinearCombination->make($var{'b2.x1'},-1,$var{'b2.x2'},1),
  rhs  => 10.0,
  type => $LE,
));
# -1 b2.y1 +1 b2.y2 < 10 ;
$lp->add_constraint(new Math::LP::Constraint(
  lhs  => Math::LP::LinearCombination->make($var{'b2.y1'},-1,$var{'b2.y2'},1),
  rhs  => 10.0,
  type => $LE,
));
# +1 b1.x2 -1 b2.x1 < -1 ;
$lp->add_constraint(new Math::LP::Constraint(
  lhs  => Math::LP::LinearCombination->make($var{'b1.x2'},1,$var{'b2.x1'},-1),
  rhs  => -1.0,
  type => $LE,
));

# print the LP
#print STDERR $lp->stringify();

# solve the LP
ok($lp->solve()); # 1

# dump the LP
if($debugging) {
    my $lp_file = 'wim_dt_06.lp';
    my $lprec = $lp->{lprec};
    my $fd = &Math::LP::Solve::open_file($lp_file, "w");
    &Math::LP::Solve::write_LP($lprec,$fd);
    &Math::LP::Solve::close_file($fd);
    print STDERR "# Wrote LP to `$lp_file'\n";
}

# print the solution
#print STDERR $lp->stringify_solution();

# check the results
ok($lp->optimum,6.2); # 2
ok($var{'b1.x1'}->{'value'},0.0); # 3
ok($var{'b1.x2'}->{'value'},0.7); # 4
ok($var{'b1.y1'}->{'value'},0.0); # 5
ok($var{'b1.y2'}->{'value'},0.7); # 6
ok($var{'b2.x1'}->{'value'},1.7); # 7
ok($var{'b2.x2'}->{'value'},2.4); # 8
ok($var{'b2.y1'}->{'value'},0.0); # 9
ok($var{'b2.y2'}->{'value'},0.7); # 10
ok($var{'%bbox.x1'}->{'value'},0.0); # 11
ok($var{'%bbox.x2'}->{'value'},2.4); # 12
ok($var{'%bbox.y1'}->{'value'},0.0); # 13
ok($var{'%bbox.y2'}->{'value'},0.7); # 14

# check the slacks
# ...

# check the dual prices
# ...
