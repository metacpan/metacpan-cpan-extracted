use utf8;
use strict;
use warnings;
use Test::More tests => 6;
use File::Temp qw/ tempdir /;
use Graphics::Fig;
use t::FigCmp;

#
# Create temp directory.
#
my $dir = tempdir(CLEANUP => 1);
#my $dir = "/tmp";


#
# Test 1: ellipse given a, b
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ] });
    $fig->ellipse(5, 3);
    $fig->save("${dir}/ellipse1.fig");
    &FigCmp::figCmp("${dir}/ellipse1.fig", "t/ellipse1.fig") || die;
};
ok($@ eq "", "test1");

#
# Test 2: ellipse given a, b, rotation
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ] });
    $fig->ellipse(1, 5, 60);
    $fig->save("${dir}/ellipse2.fig");
    &FigCmp::figCmp("${dir}/ellipse2.fig", "t/ellipse2.fig") || die;
};
ok($@ eq "", "test2");

#
# Test 3: ellipse given center, two points (rotation from 1st point)
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ] });
    $fig->ellipse({ center => [ 2, 3 ], points => [[ 4, 1 ], [ 1, 5 ]],
                    subtype => "diameters" });
    $fig->save("${dir}/ellipse3.fig");
    &FigCmp::figCmp("${dir}/ellipse3.fig", "t/ellipse3.fig") || die;
};
ok($@ eq "", "test3");

#
# Test 4: ellipse given center and three points
#
#eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ] });
    $fig->ellipse({ position => [ 4, 4 ],
                    points => [[ 1, 3 ], [ 0, 5 ], [ 3, 2 ]] });
    $fig->save("${dir}/ellipse4.fig");
    &FigCmp::figCmp("${dir}/ellipse4.fig", "t/ellipse4.fig") || die;
#};
ok($@ eq "", "test4");

#
# Test 5: ellipse given five points
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ] });
    $fig->ellipse([[ -1, -1 ], [ 3, 0 ], [ 0, 2 ], [ 5, 3 ], [ 2, 3 ]]);
    $fig->save("${dir}/ellipse5.fig");
    &FigCmp::figCmp("${dir}/ellipse5.fig", "t/ellipse5.fig") || die;
};
ok($@ eq "", "test5");

#
# Test 6: scale, rotate and getbbox
#
eval {
    my $fig = Graphics::Fig->new({ position    => [ 4.5, 5.5 ],
    				   orientation => "portrait" });
    $fig->ellipse(2, 1);
    $fig->scale([ -3, 2 ]);
    $fig->rotate(-60);
    my $bb = $fig->getbbox();
    $fig->box($bb);
    $fig->save("${dir}/ellipse6.fig");
    &FigCmp::figCmp("${dir}/ellipse6.fig", "t/ellipse6.fig") || die;
};
ok($@ eq "", "test6");

exit(0);
