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
plan tests => 1;

#
# Load modules.
#
use Graphics::Fig;
use File::Temp qw/ tempdir /;
use Math::Trig;

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
