use utf8;
use strict;
use warnings;
use File::Temp qw/ tempdir /;
use Graphics::Fig;
use Test::More tests => 6;
use t::FigCmp;

#
# Create temp directory.
#
my $dir = tempdir(CLEANUP => 1);
#my $dir = "/tmp";


#
# Test 1: arcto given distance and heading
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 2, 1 ], arrowMode => "forw" });
    $fig->arcto(2 * sqrt(2), 135);
    $fig->arcto({ distance => 2 * sqrt(2), heading => 225 });
    $fig->save("${dir}/arcto1.fig");
    &FigCmp::figCmp("${dir}/arcto1.fig", "t/arcto1.fig") || die;
};
ok($@ eq "", "test1");

#
# Test 2: arcto given distance, heading and angle
#
eval {
    my $fig = Graphics::Fig->new({ position  => [ -1, 1 ],
    				   arrowMode => "forw" });
    $fig->arcto(2,    0, -270 );
    $fig->arcto({ distance => 2, heading => -180, angle => 180 });
    $fig->save("${dir}/arcto2.fig");
    &FigCmp::figCmp("${dir}/arcto2.fig", "t/arcto2.fig") || die;
};
ok($@ eq "", "test2");

#
# Test 3: arcto given center and direction
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 1, 1 ], arrowMode => "forw" });
    $fig->arcto({ center => [ 2, 1 ], direction => "ccw" });
    $fig->arcto({ center => [ 2, 3 ], direction => "cw" });
    $fig->save("${dir}/arcto3.fig");
    &FigCmp::figCmp("${dir}/arcto3.fig", "t/arcto3.fig") || die;
};
ok($@ eq "", "test3");

#
# Test 4: arcto given final point (and control angle)
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 4, 0 ], arrowMode => "forw" });
    $fig->arcto([  0, 3 ]);
    $fig->arcto([ -3, 1 ], { controlAngle => 30 });
    $fig->arcto({ point => [  4, 0 ] });
    $fig->save("${dir}/arcto4.fig");
    &FigCmp::figCmp("${dir}/arcto4.fig", "t/arcto4.fig") || die;
};
ok($@ eq "", "test4");

#
# Test 5: arcto given control-point, final-point
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 0, 4 ], arrowMode => "forw" });
    $fig->arcto([[  2,  3 ], [  3, -1 ]]);
    $fig->arcto([[  2,  1 ], [ -2,  3 ]]);
    $fig->arcto({ points => [[ -2, -2 ], [  1,  1 ]] });
    $fig->save("${dir}/arcto5.fig");
    &FigCmp::figCmp("${dir}/arcto5.fig", "t/arcto5.fig") || die;
};
ok($@ eq "", "test5");

#
# Test 6: arcto closed and filled
#
eval {
    my $fig = Graphics::Fig->new();
    $fig->arcto({ position => [ -1, 0 ], distance => 1, heading => 0,
                  angle => 180, subtype => "closed", areaFill => "saturated",
		  color => "blue", fillColor => "yellow" });
    $fig->arcto({ distance => 1, heading => 0,
                  angle => -180, subtype => "pie-wedge", areaFill => "full",
		  color => "red", fillColor => "magenta" });
    $fig->save("${dir}/arcto6.fig");
    &FigCmp::figCmp("${dir}/arcto6.fig", "t/arcto6.fig") || die;
};
ok($@ eq "", "test6");


exit(0);
