# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 6 };
use Math::Curve::Hilbert;
ok(1); # If we made it this far, we're ok.

#########################

use Math::Curve::Hilbert;

# get array of coordinates to draw 8x8 curve in 160x160 pixels
# check that specific points are in correct places
my $hilbert = Math::Curve::Hilbert->new( direction=>'right', max=>3, clockwise=>1, step=>20);
ok(ref $hilbert eq 'Math::Curve::Hilbert');
ok($hilbert->PointFromCoordinates(40,40) == 2);
ok($hilbert->PointFromCoordinates(120,40) == 18);
ok($hilbert->PointFromCoordinates(40,120) == 56);
ok($hilbert->PointFromCoordinates(120,120) == 34);
