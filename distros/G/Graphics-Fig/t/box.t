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
plan tests => 5;

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
# Test 1: box given width, height
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ] });
    $fig->box(3, 5);
    $fig->save("${dir}/box1.fig");
    &FigCmp::figCmp("${dir}/box1.fig", "t/box1.fig") || die;
};
ok($@ eq "", "test1");

#
# Test 2: box given width, height, center
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ] });
    $fig->box({ width => 3, height => 1, center => [ 2, 1 ] });
    $fig->save("${dir}/box2.fig");
    &FigCmp::figCmp("${dir}/box2.fig", "t/box2.fig") || die;
};
ok($@ eq "", "test2");

#
# Test 3: box given Q1, Q3 points
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ] });
    $fig->box([[ 2, 3 ], [ -3, -4 ]]);
    $fig->save("${dir}/box3.fig");
    &FigCmp::figCmp("${dir}/box3.fig", "t/box3.fig") || die;
};
ok($@ eq "", "test3");

#
# Test 4: box given Q4, T2 points
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ] });
    $fig->box({ points => [[ 1, -4 ], [ -2, 3 ]] });
    $fig->save("${dir}/box4.fig");
    &FigCmp::figCmp("${dir}/box4.fig", "t/box4.fig") || die;
};
ok($@ eq "", "test4");

#
# Test 5: translate, scale, rotate and getbbox
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 5.5, 4.5 ] });
    $fig->box({ width => 3, height => 2 });
    $fig->rotate(45);
    $fig->scale([ -3, 2 ]);
    $fig->translate([ 0, -0.5 ]);
    my $bb = $fig->getbbox();
    $fig->box($bb);
    $fig->save("${dir}/box5.fig");
    &FigCmp::figCmp("${dir}/box5.fig", "t/box5.fig") || die;
};
ok($@ eq "", "test5");

exit(0);
