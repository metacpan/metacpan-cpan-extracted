use utf8;
use strict;
use warnings;
use Test::More;
use t::FigCmp;

#
# Skip tests if required modules are not available.
#
if (!eval { require File::Temp; 1 }) {
    plan skip_all => "File::Temp moduled required";
}
if (!eval { require Math::Trig; 1 }) {
    plan skip_all => "Math::Trig moduled required";
}
if (!eval { require Regexp::Common; 1 }) {
    plan skip_all => "Regexp::Common moduled required";
}
if (!eval { require Image::Info; 1 }) {
    plan skip_all => "Image::Info moduled required";
}
plan tests => 4;

#
# Load modules.
#
use Graphics::Fig;
use File::Temp qw/ tempdir /;
use Math::Trig;

#
# Create temp directory.
#
my $dir = tempdir(CLEANUP => 1);
#my $dir = "/tmp";


#
# Test 1: polyline given two points
#
eval {
    my $fig = Graphics::Fig->new();
    $fig->polyline([[ 1, 2 ], [ 3, 1 ]]);
    $fig->save("${dir}/polyline1.fig");
    &FigCmp::figCmp("${dir}/polyline1.fig", "t/polyline1.fig") || die;
};
ok($@ eq "", "test1");

#
# Test 2: polyline given each arrow mode and various arrow styles
#
eval {
    my $fig = Graphics::Fig->new();
    $fig->polyline({ points => [[ 1, 1 ], [ 3, 1 ]], arrowMode => "none" });
    $fig->polyline({ points => [[ 1, 2 ], [ 3, 2 ]], arrowMode => "forw",
    		     arrowStyle => "triangle", color => "red" });
    $fig->polyline({ points => [[ 1, 3 ], [ 3, 3 ]], arrowMode => "back",
    		     arrowStyle => "filled-pointed", color => "green" });
    $fig->polyline({ points => [[ 1, 4 ], [ 3, 4 ]], arrowMode => "both",
		     arrowStyle => "circle", color => "blue",
                     fArrowStyle => "filled-indented" });
    $fig->save("${dir}/polyline2.fig");
    &FigCmp::figCmp("${dir}/polyline2.fig", "t/polyline2.fig") || die;
};
ok($@ eq "", "test2");

#
# Test 3: polyline given three points and various line thicknesses and styles
#
eval {
    my $fig = Graphics::Fig->new();
    $fig->polyline({ points => [[ 1, 1 ], [ 5, 1 ]],
    	             lineThickness => "1.0 mm",
		     lineStyle => "solid" });
    $fig->polyline({ points => [[ 1, 2 ], [ 5, 2 ]],
    	             lineThickness => "2.0 mm",
		     lineStyle => "dashed" });
    $fig->polyline({ points => [[ 1, 3 ], [ 5, 3 ]],
    	             lineThickness => "3.0 mm",
		     lineStyle => "dotted",
		     styleVal => 0.25 });
    $fig->polyline({ points => [[ 1, 4 ], [ 5, 4 ]],
    	             lineThickness => "4.0 mm",
		     lineStyle => "dash-double-dotted",
		     styleVal => 0.5 });
    $fig->save("${dir}/polyline3.fig");
    &FigCmp::figCmp("${dir}/polyline3.fig", "t/polyline3.fig") || die;
};
ok($@ eq "", "test3");

#
# Test 4: polyline given list of points
#
eval {
    my $fig = Graphics::Fig->new({ areaFill => "full", fillColor => "gold" });
    my @points;
    for (my $i = 0; $i < 5; ++$i) {
	my $a = (72 - 90 + 144 * $i) * pi / 180.0;
	push(@points, [ 2 * (cos($a) + 1), 2 * (sin($a) + 1) ]);
    }
    $fig->polyline(\@points);
    $fig->save("${dir}/polyline4.fig");
    &FigCmp::figCmp("${dir}/polyline4.fig", "t/polyline4.fig") || die;
};
ok($@ eq "", "test4");

exit(0);
