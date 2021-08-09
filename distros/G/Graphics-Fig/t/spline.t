use utf8;
use strict;
use warnings;
use Test::More tests => 4;
use File::Temp qw/ tempdir /;
use Math::Trig;
use lib "lib";
use Graphics::Fig;
use lib "t";
use FigCmp;

#
# Create temp directory.
#
my $dir = tempdir(CLEANUP => 1);
#my $dir = "/tmp";


#
# Test 1: spline given three points
#
eval {
    my $fig = Graphics::Fig->new();
    $fig->spline([[ 2, 0 ], [ 1, 1 ], [ 3, 2 ]]);
    $fig->save("${dir}/spline1.fig");
    &FigCmp::figCmp("${dir}/spline1.fig", "t/spline1.fig") || die;
};
ok($@ eq "", "test1");

#
# Test 2: superimposed spline subtypes
#
eval {
    my $fig = Graphics::Fig->new();
    my $points = [[ 0, 1 ], [ 1, 1 ], [ 2, 2 ], [ 3, 1 ]];
    $fig->spline({ points => $points, subtype => "open-approximated",
                   color => "red" });
    $fig->spline({ points => $points, subtype => "open-interpolated",
                   color => "green" });
    $fig->spline({ points => $points, subtype => "closed-approximated",
                   color => "blue" });
    $fig->spline({ points => $points, subtype => "closed-interpolated",
                   color => "magenta" });
    $fig->save("${dir}/spline2.fig");
    &FigCmp::figCmp("${dir}/spline2.fig", "t/spline2.fig") || die;
};
ok($@ eq "", "test2");

#
# Test 3: superimposed open x-splines with different shape factors
#
eval {
    my $fig = Graphics::Fig->new();
    my $points = [[ 0, 1 ], [ 1, 1 ], [ 2, 2 ], [ 3, 1 ]];
    $fig->spline({ points => $points, subtype => "open-x",
    		   shapeFactor => -0.75, color => "red" });
    $fig->spline({ points => $points, subtype => "open-x",
    		   shapeFactor => -0.5, color => "gold" });
    $fig->spline({ points => $points, subtype => "open-x",
    		   shapeFactor => -0.25, color => "yellow" });
    $fig->spline({ points => $points, subtype => "open-x",
    		   shapeFactor => 0.0, color => "green" });
    $fig->spline({ points => $points, subtype => "open-x",
    		   shapeFactor => 0.25, color => "blue" });
    $fig->spline({ points => $points, subtype => "open-x",
    		   shapeFactor => 0.5, color => "magenta" });
    $fig->spline({ points => $points, subtype => "open-x",
    		   shapeFactor => 0.75, color => "#bebebe" });
    $fig->save("${dir}/spline3.fig");
    &FigCmp::figCmp("${dir}/spline3.fig", "t/spline3.fig") || die;
};
ok($@ eq "", "test3");

#
# Test 4: closed x-spline with per-point shape factors
#
eval {
    my $fig = Graphics::Fig->new();
    $fig->spline({ points => [[ 1, 0 ], [ 2, 1 ], [ 1, 2 ], [ 0, 1 ]],
		   subtype => "closed-x",
                   shapeFactors => [ -2/3, -1/3, 1/3, 2/3 ] });
    $fig->save("${dir}/spline4.fig");
    &FigCmp::figCmp("${dir}/spline4.fig", "t/spline4.fig") || die;
};
ok($@ eq "", "test4");

exit(0);
