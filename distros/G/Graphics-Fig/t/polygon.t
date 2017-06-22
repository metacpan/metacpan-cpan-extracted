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

#
# Create temp directory.
#
my $dir = tempdir(CLEANUP => 1);
#my $dir = "/tmp";


#
# Test 1: polygon given n, radius
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ] });
    $fig->polygon(5, 2);
    $fig->save("${dir}/polygon1.fig");
    &FigCmp::figCmp("${dir}/polygon1.fig", "t/polygon1.fig") || die;
};
ok($@ eq "", "test1");

#
# Test 2: polygon given n, radius, rotation
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ] });
    $fig->polygon({ n => 3, radius => 2, color => "red" });
    $fig->polygon({ n => 3, radius => 2, color => "green", rotation => 40 });
    $fig->polygon({ n => 3, radius => 2, color => "blue",  rotation => 80 });
    $fig->save("${dir}/polygon2.fig");
    &FigCmp::figCmp("${dir}/polygon2.fig", "t/polygon2.fig") || die;
};
ok($@ eq "", "test2");

#
# Test 3: polygon given n, center, point
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ] });
    $fig->polygon({ n => 4, center => [ 5, 5 ], point => [ 4, 3 ] });
    $fig->save("${dir}/polygon3.fig");
    &FigCmp::figCmp("${dir}/polygon3.fig", "t/polygon3.fig") || die;
};
ok($@ eq "", "test3");

#
# Test 4: polygon given list of points
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ] });
    $fig->polygon([[ 1, 1 ], [ 2, 1 ], [ 2, 2 ], [ 3, 0 ]],
    		  { areaFill => "full", fillColor => "green" });
    $fig->save("${dir}/polygon4.fig");
    &FigCmp::figCmp("${dir}/polygon4.fig", "t/polygon4.fig") || die;
};
ok($@ eq "", "test4");

exit(0);
