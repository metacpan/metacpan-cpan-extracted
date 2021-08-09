use utf8;
use strict;
use warnings;
use Test::More tests => 1;
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
# Test 1: basic splineto test
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
    $fig->save("${dir}/splineto1.fig");
    &FigCmp::figCmp("${dir}/splineto1.fig", "t/splineto1.fig") || die;
};
ok($@ eq "", "test1");

exit(0);
