#!perl

use Test::More tests => 15;

BEGIN { use_ok('Math::Geometry') }

ok(pi()>3.14 && pi()<3.15,'PI seems to be right-ish');

is(rad2deg(pi()),180,'rad2deg ok #1');
is(rad2deg(0),0,'rad2deg ok #2');

is(deg2rad(180),pi(),'deg2rad ok #1');
is(deg2rad(0),0,'deg2rad ok #2');


my @p1;
my @p2;

@p1 = (1,1,1);
@p2 =rotx(roty(rotz(@p1,pi()),pi()),pi());
is($p2[0],$p1[0]);
is($p2[1],$p1[1]);
is($p2[2],$p1[2]);

@p1 = (0,0,0);
@p2 =rotx(roty(rotz(@p1,pi()),pi()),pi());
is($p2[0],$p1[0]);
is($p2[1],$p1[1]);
is($p2[2],$p1[2]);

@p1 = (40,12,-13);
@p2 =rotx(roty(rotz(@p1,pi()),pi()),pi());
is($p2[0],$p1[0]);
is($p2[1],$p1[1]);
is($p2[2],$p1[2]);




__END__


#sub vector_product  {
#sub triangle_normal {
#sub zplane_project ($$$$) {

