use utf8;
use strict;
use warnings;
use File::Temp qw/ tempdir /;
use Test::More tests => 5;
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
# Test 2: polygon given n, radius
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ] });
    $fig->polygon(5, 2);
    $fig->save("${dir}/polygon2.fig");
    &FigCmp::figCmp("${dir}/polygon2.fig", "t/polygon2.fig") || die;
};
ok($@ eq "", "test2");

#
# Test 3: polygon given n, radius, rotation
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ] });
    $fig->polygon({ n => 3, radius => 2, color => "red" });
    $fig->polygon({ n => 3, radius => 2, color => "green", rotation => 40 });
    $fig->polygon({ n => 3, radius => 2, color => "blue",  rotation => 80 });
    $fig->save("${dir}/polygon3.fig");
    &FigCmp::figCmp("${dir}/polygon3.fig", "t/polygon3.fig") || die;
};
ok($@ eq "", "test3");

#
# Test 4: polygon given n, center, point
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ] });
    $fig->polygon({ n => 4, center => [ 5, 5 ], point => [ 4, 3 ] });
    $fig->save("${dir}/polygon4.fig");
    &FigCmp::figCmp("${dir}/polygon4.fig", "t/polygon4.fig") || die;
};
ok($@ eq "", "test4");

#
# Test 5: polygon given list of points
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ] });
    $fig->polygon([[ 1, 1 ], [ 2, 1 ], [ 2, 2 ], [ 3, 0 ]],
    		  { areaFill => "full", fillColor => "green" });
    $fig->save("${dir}/polygon5.fig");
    &FigCmp::figCmp("${dir}/polygon5.fig", "t/polygon5.fig") || die;
};
ok($@ eq "", "test5");

exit(0);
