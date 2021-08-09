use utf8;
use strict;
use warnings;
use Test::More tests => 10;
use File::Temp qw/ tempdir /;
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
# Test Parameters
#
my $test_image = "t/horse-2090626_640.jpg";
my $test_xpix  = 420;	# pixels
my $test_ypix  = 640;	# pixels
my $test_res   = 300;	# dpi


#
# Test 1: picture given file only
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ] });
    $fig->picture($test_image);
    $fig->box($test_xpix / $test_res, $test_ypix / $test_res,
    	{ lineThickness => 0.1, depth => 100 });
    $fig->save("${dir}/picture1.fig");
    &FigCmp::figCmp("${dir}/picture1.fig", "t/picture1.fig") || die;
};
ok($@ eq "", "test1");

#
# Test 2: picture given file, width
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ] });
    $fig->picture($test_image, 2.0);
    $fig->box(2.0, 2.0 * $test_ypix / $test_xpix,
    	{ lineThickness => 0.1, depth => 100 });
    $fig->save("${dir}/picture2.fig");
    &FigCmp::figCmp("${dir}/picture2.fig", "t/picture2.fig") || die;
};
ok($@ eq "", "test2");

#
# Test 3: picture given file, height, center
#
eval {
    my $fig = Graphics::Fig->new();
    $fig->picture({ filename => $test_image, height => 4.0,
    		    center => [ 3, 2 ] });
    $fig->box(4.0 * $test_xpix / $test_ypix, 4.0,
    	{ center => [ 3, 2 ], lineThickness => 0.1, depth => 100 });
    $fig->save("${dir}/picture3.fig");
    &FigCmp::figCmp("${dir}/picture3.fig", "t/picture3.fig") || die;
};
ok($@ eq "", "test3");

#
# Test 4: picture given file, width, height
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 1.5, 2.5 ] });
    $fig->picture($test_image, 3.0, 5.0);
    $fig->box(3.0, 5.0, { lineThickness => 0.1, depth => 100 });
    $fig->save("${dir}/picture4.fig");
    &FigCmp::figCmp("${dir}/picture4.fig", "t/picture4.fig") || die;
};
ok($@ eq "", "test4");

#
# Test 5: picture given file and two opposite corners
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 1.5, 2.5 ] });
    $fig->picture($test_image, [[ 1, 1 ], [ 3, 4 ]]);
    $fig->box([[ 1, 1 ], [ 3, 4 ]], { lineThickness => 0.1, depth => 100 });
    $fig->save("${dir}/picture5.fig");
    &FigCmp::figCmp("${dir}/picture5.fig", "t/picture5.fig") || die;
};
ok($@ eq "", "test5");

#
# Test 6: picture overriding resolution to force 1" x 1"
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 1.5, 2.5 ] });
    my $resolution = sprintf("%f / %f dpi", $test_xpix, $test_ypix);
    $fig->picture($test_image, { resolution => $resolution });
    $fig->box([[ 1, 2 ], [ 2, 3 ]], { lineThickness => 0.1, depth => 100 });
    $fig->save("${dir}/picture6.fig");
    &FigCmp::figCmp("${dir}/picture6.fig", "t/picture6.fig") || die;
};
ok($@ eq "", "test6");

#
# Test 7: picture overriding resolution, no units
#
eval {
    my $fig = Graphics::Fig->new();
    $fig->picture($test_image, { position => [ 2, 2 ], resolution => "3/2" });
    $fig->box($test_xpix / 300, $test_ypix / 200,
    	{ center => [ 2, 2 ], lineThickness => 0.1, depth => 100 });
    $fig->save("${dir}/picture7.fig");
    &FigCmp::figCmp("${dir}/picture7.fig", "t/picture7.fig") || die;
};
ok($@ eq "", "test7");

#
# Test 8: rotation by placing corners
#
eval {
    my $fig = Graphics::Fig->new({ position => [3, 3] });
    $fig->picture($test_image, [[ 0, 0 ], [ 2, 3 ]]);
    $fig->picture($test_image, [[ 6, 0 ], [ 3, 2 ]]);
    $fig->picture($test_image, [[ 6, 6 ], [ 4, 3 ]]);
    $fig->picture($test_image, [[ 0, 6 ], [ 3, 4 ]]);
    $fig->save("${dir}/picture8.fig");
    &FigCmp::figCmp("${dir}/picture8.fig", "t/picture8.fig") || die;
};
ok($@ eq "", "test8");

#
# Test 9: scale
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 4, 6 ] });
    $fig->picture($test_image, [[ 4, 3 ], [ 6, 6 ]]);
    $fig->scale([  2,  2 ]);
    $fig->begin();
    $fig->picture($test_image, [[ 4, 3 ], [ 6, 6 ]]);
    $fig->scale([ -2,  2 ]);
    $fig->end();
    $fig->begin();
    $fig->picture($test_image, [[ 4, 3 ], [ 6, 6 ]]);
    $fig->scale([  2, -2 ]);
    $fig->end();
    $fig->begin();
    $fig->picture($test_image, [[ 4, 3 ], [ 6, 6 ]]);
    $fig->scale([ -2, -2 ]);
    $fig->end();
    $fig->save("${dir}/picture9.fig");
    &FigCmp::figCmp("${dir}/picture9.fig", "t/picture9.fig") || die;
};
ok($@ eq "", "test9");

#
# Test 10: rotation and translation
#
eval {
    my $fig = Graphics::Fig->new();
    $fig->picture($test_image, [[ 3, 0 ], [ 5, 3 ]]);
    $fig->begin();
    $fig->picture($test_image, [[ 3, 0 ], [ 5, 3 ]]);
    $fig->rotate({ rotation => -90, center => [ 5, 3 ] });
    $fig->translate([  0,  2 ]);
    $fig->end();
    $fig->begin();
    $fig->picture($test_image, [[ 3, 0 ], [ 5, 3 ]]);
    $fig->rotate({ rotation => -90, center => [ 5, 3 ] });
    $fig->translate([  0,  2 ]);
    $fig->rotate({ rotation => -90, center => [ 5, 5 ] });
    $fig->translate([ -2,  0 ]);
    $fig->end();
    $fig->begin();
    $fig->picture($test_image, [[ 3, 0 ], [ 5, 3 ]]);
    $fig->rotate({ rotation => -90, center => [ 5, 3 ] });
    $fig->translate([  0,  2 ]);
    $fig->rotate({ rotation => -90, center => [ 5, 5 ] });
    $fig->translate([ -2,  0 ]);
    $fig->rotate({ rotation => -90, center => [ 3, 5 ] });
    $fig->translate([  0, -2 ]);
    $fig->end();
    $fig->save("${dir}/picture10.fig");
    &FigCmp::figCmp("${dir}/picture10.fig", "t/picture10.fig") || die;
};
ok($@ eq "", "test10");

exit(0);
