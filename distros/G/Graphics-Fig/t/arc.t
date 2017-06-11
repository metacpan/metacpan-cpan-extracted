use utf8;
use strict;
use warnings;
use File::Temp qw/ tempdir /;
use Test::More tests => 12;
use t::FigCmp;

my $dir = tempdir(CLEANUP => 1);
#my $dir = "/tmp";

#
# Test 1: load the module
#
BEGIN {
    use_ok('Graphics::Fig')
};

#
# Test 2: arc given radius only
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ], arrowMode => "forw" });
    $fig->arc(1);
    $fig->save("${dir}/arc2.fig");
    &FigCmp::figCmp("${dir}/arc2.fig", "t/arc2.fig") || die;
};
ok($@ eq "", "test2");

#
# Test 3: arc given radius and negative angle
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ], arrowMode => "forw" });
    $fig->arc(2, -120);
    $fig->save("${dir}/arc3.fig");
    &FigCmp::figCmp("${dir}/arc3.fig", "t/arc3.fig") || die;
};
ok($@ eq "", "test3");

#
# Test 4: arc given diameter, angle and rotation
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ], arrowMode => "forw" });
    $fig->arc({ d => 3, angle => 270, rotation => -90 });
    $fig->save("${dir}/arc4.fig");
    &FigCmp::figCmp("${dir}/arc4.fig", "t/arc4.fig") || die;
};
ok($@ eq "", "test4");

#
# Test 5: arc given radius, rotation and control angle
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ], arrowMode => "forw" });
    $fig->arc({ r => 1, rotation => 180, controlAngle => -30 });
    $fig->save("${dir}/arc5.fig");
    &FigCmp::figCmp("${dir}/arc5.fig", "t/arc5.fig") || die;
};
ok($@ eq "", "test5");

#
# Test 6: arc given radius, angle, rotation and control angle
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ], arrowMode => "forw" });
    $fig->arc({ radius => 1, Θ => 120, rotation => -180, controlAngle => 100 });
    $fig->save("${dir}/arc6.fig");
    &FigCmp::figCmp("${dir}/arc6.fig", "t/arc6.fig") || die;
};
ok($@ eq "", "test6");

#
# Test 7: arc given starting point, center, angle and direction
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ], arrowMode => "forw" });
    $fig->arc([2, 3], { center => [ 1, 2 ], Θ => 180, direction => "cw" });
    $fig->save("${dir}/arc7.fig");
    &FigCmp::figCmp("${dir}/arc7.fig", "t/arc7.fig") || die;
};
ok($@ eq "", "test7");

#
# Test 8: arc given starting point, final point and angle
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ], arrowMode => "forw" });
    $fig->arc([[3, 0], [0, 3]], { angle => 180 });
    $fig->save("${dir}/arc8.fig");
    &FigCmp::figCmp("${dir}/arc8.fig", "t/arc8.fig") || die;
};
ok($@ eq "", "test8");

#
# Test 9: arc given three points
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ], arrowMode => "forw" });
    $fig->arc({ points => [[ 0, 3 ], [ 1, 2 ], [ 3, 1 ]] });
    $fig->save("${dir}/arc9.fig");
    &FigCmp::figCmp("${dir}/arc9.fig", "t/arc9.fig") || die;
};
ok($@ eq "", "test9");

#
# Test 10: test extended arrow options
#
eval {
    my $fig = Graphics::Fig->new();
    $fig->arc({
	d => 3,
	direction => "ccw",
	arrowHeight => "0.2 inch",
	fArrowHeight => "0.4 inch",
	arrowMode => "both",
	arrowStyle => "filled-triangle",
	bArrowStyle => "filled-indented",
	arrowThickness => ".025 inch",
	fArrowThickness => ".035 inch",
	arrowWidth => "0.1 inch",
	bArrowWidth => "0.2 inch",
	color => "green",
	depth => 999,
	position => [ 5, 4 ],
	rotation => 90 });
    $fig->save("${dir}/arc10.fig");
    &FigCmp::figCmp("${dir}/arc10.fig", "t/arc10.fig") || die;
};
ok($@ eq "", "test10");

#
# Test 11: test remaining options
#
eval {
    my $fig = Graphics::Fig->new();
    $fig->arc({
	diameter => 5,
	direction => "ccw",
 	subtype => "closed",
 	areaFill => "full",
	capStyle => "projecting",
	color => "#4682B4",	# Steel Blue
	depth => 500,
	fillColor => "yellow",
	lineStyle => "dashed",
	lineThickness => 0.05,
	position => [ 1, 3 ],
	styleVal => 0.3,
	units => "2.0 inch" });
    $fig->save("${dir}/arc11.fig");
    &FigCmp::figCmp("${dir}/arc11.fig", "t/arc11.fig") || die;
};
ok($@ eq "", "test11");

#
# Test 12: translate, rotate, scale and bbox
#
eval {
    my $fig = Graphics::Fig->new();
    $fig->arc([[ 1/2, -1/2 ], [ 1, -1 ], [ 7/2, -1/2 ]]);
    $fig->polyline([[ 1, -1 ], [ 7/2, -1/2 ]]);
    $fig->translate([ 1, 2 ]);
    $fig->moveto([ 2, 1 ]);
    $fig->scale([ 2, 3 ]);
    $fig->rotate(-45);
    my $bb = $fig->getbbox();
    $fig->box($bb);
    $fig->save("${dir}/arc12.fig");
    &FigCmp::figCmp("${dir}/arc12.fig", "t/arc12.fig") || die;
};
ok($@ eq "", "test12");

exit(0);
