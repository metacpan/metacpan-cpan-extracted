#!perl -T

use strict;
use warnings;
use Geometry::Formula;
use Test::More tests => 6;

BEGIN {
    eval "use Test::Exception";
    plan skip_all => "Test::Exception needed" if $@;
}

my $test = Geometry::Formula->new;

my $annulus =
  $test->annulus( formula => 'area', inner_radius => 5, outer_radius => 10 );
like( $annulus, qr/235.619445/, 'calculation test' );

throws_ok {
    $test->annulus( formula => 'test', outer_radius => 10, inner_radius => 5 );
}
qr/invalid formula name: test specified/, 'valid formula name test';

throws_ok { $test->annulus( formula => 'area', outer_radius => 10 ) }
qr/required parameter 'inner_radius' not defined/,
  'required parameter exception for inner_radius';

throws_ok { $test->annulus( formula => 'area', inner_radius => 10 ) }
qr/required parameter 'outer_radius' not defined/,
  'required parameter exception for outer_radius';

throws_ok {
    $test->annulus(
        formula      => 'area',
        outer_radius => '10',
        inner_radius => '5a'
    );
}
qr/parameter 'inner_radius' requires a numeric value/,
  'formula parameter inner_radius is numeric';

throws_ok {
    $test->annulus(
        formula      => 'area',
        outer_radius => '345a',
        inner_radius => 5
    );
}
qr/parameter 'outer_radius' requires a numeric value/,
  'formula parameter outer_radius is numeric';
