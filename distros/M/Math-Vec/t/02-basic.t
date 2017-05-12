use strict;
use warnings;

use Test::More;
BEGIN { plan tests => 22 };
use Math::Vec qw(:terse NewVec);
ok(1, "use");

my $pt;
ok( $pt = Math::Vec->new(0,5), 'constructor');
ok( V($pt->ScalarMult(3)) == [0,15]  ,'multiplication');
# how to test for warnings on 2D vectors?
ok(scalar(@{V(0,1)}) == 3, 'auto-init');
my $v = V(1,1);
ok($v->isa('Math::Vec'), 'constructor');
ok(V(1,1) == V(1,1), 'comparison');
ok(V(1,1) != V(1,0), 'comparison');
ok(abs(V(3,4)) == 5, 'length');
my $qpi = atan2(1,1);
my $angs = V(V(1,1,1)->PlanarAngles());
ok($angs == [($qpi) x 3], 'angles');
ok(($v - [0,1]) == [1,0], 'subtraction');
ok($v + [4,5,1] == [5,6,1], 'addition');

ok(X == [1,0,0], 'X-axis');
ok(Y == [0,1,0], 'Y-axis');
ok(Z == [0,0,1], 'Z-axis');
ok(-$v == [-1,-1], 'negation');

# now to check the functional interface
$v = NewVec(0,1,2);
my @res = $v->Cross([1,2.5]);
ok(V(@res) == ($v x [1,2.5]), 'cross product');
my $p = NewVec(@res);
my $q = $p->Dot([0,1]);
ok($q == $p * [0,1], 'dot product');
my @proj = V(1,0)->Proj([1,1,1]);
ok(V(@proj) == V(1,0), 'vector projection');
ok(V(@proj) == V(1,1,1) >> [1,0], 'vector projection');

my $comp = V(1,0)->Comp([1,1,1]);
ok($comp == 1, 'scalar projection (component)');
ok($comp == abs(V(1,1,1) >> [1,0]), 'comp == abs(proj)');
ok(V(1,1,1) x Z() == [1,-1], 'perpendicular');
