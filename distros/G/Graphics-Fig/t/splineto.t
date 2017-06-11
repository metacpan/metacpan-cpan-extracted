use utf8;
use strict;
use warnings;
use File::Temp qw/ tempdir /;
use Test::More tests => 2;
use Math::Trig;
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
# Test 2: basic splineto test
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 1, 1 ], arrowMode => "forw" });
    $fig->splineto([ 2, 1 ], { subtype => "open-interpolated" });
    $fig->splineto([ 2, 2 ], { subtype => "open-interpolated" });

    #
    # Change of subtype starts a new spline.
    #
    $fig->splineto([ 3, 2 ]);
    $fig->splineto([ 3, 3 ]);
    $fig->splineto([ 4, 3 ]);

    #
    # Explicit new starts a new spline.  With only two points, it's
    # rendered as a polyline.
    #
    $fig->splineto([ 4, 4 ], { new => 1 });
    $fig->save("${dir}/splineto2.fig");
    &FigCmp::figCmp("${dir}/splineto2.fig", "t/splineto2.fig") || die;
};
ok($@ eq "", "test2");

exit(0);
