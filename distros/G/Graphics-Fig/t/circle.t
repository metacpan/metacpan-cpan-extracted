use utf8;
use strict;
use warnings;
use File::Temp qw/ tempdir /;
use Test::More tests => 6;
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
# Test 2: circle given diameter
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ] });
    $fig->circle(2);
    $fig->save("${dir}/circle2.fig");
    &FigCmp::figCmp("${dir}/circle2.fig", "t/circle2.fig") || die;
};
ok($@ eq "", "test2");

#
# Test 3: circle given center, radius
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ] });
    $fig->circle({ center => [ 2, 3 ], r => 3 });
    $fig->save("${dir}/circle3.fig");
    &FigCmp::figCmp("${dir}/circle3.fig", "t/circle3.fig") || die;
};
ok($@ eq "", "test3");

#
# Test 4: circle given center, diameter
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ] });
    $fig->circle({ center => [ -1, -2 ], d => 5 });
    $fig->save("${dir}/circle4.fig");
    &FigCmp::figCmp("${dir}/circle4.fig", "t/circle4.fig") || die;
};
ok($@ eq "", "test4");

#
# Test 5: circle given center, point
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ] });
    $fig->circle({ center => [ 2, 2 ], point => [ -1, 3 ],
    		   subtype => "diameter" });
    $fig->save("${dir}/circle5.fig");
    &FigCmp::figCmp("${dir}/circle5.fig", "t/circle5.fig") || die;
};
ok($@ eq "", "test5");

#
# Test 6: circle given three points
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ] });
    $fig->circle([[ 1, -1 ], [ -1, 2 ], [ 3, 3 ]]);
    $fig->save("${dir}/circle6.fig");
    &FigCmp::figCmp("${dir}/circle6.fig", "t/circle6.fig") || die;
};
ok($@ eq "", "test6");

exit(0);
