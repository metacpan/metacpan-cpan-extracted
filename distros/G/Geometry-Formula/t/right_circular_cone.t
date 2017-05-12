#!perl -T

use strict;
use warnings;
use Geometry::Formula;
use Test::More tests => 11;

BEGIN {
    eval "use Test::Exception";
    plan skip_all => "Test::Exception need" if $@;
};

my $test = Geometry::Formula->new;

my $lateral_surface_area = $test->right_circular_cone(
    formula => 'lateral_surface_area',
    radius  => 5,
    height  => 10
);
like( $lateral_surface_area, qr/175.620365280258/, 'calculation test' );

my $volume = $test->right_circular_cone(
    formula => 'volume',
    radius  => 5,
    height  => 10
);
like( $volume, qr/261.799383333333/, 'calculation test' );

throws_ok {
    $test->right_circular_cone(
        formula => 'foo',
        radius  => 10,
        height  => 15
    );
}
qr/invalid formula name: foo specified/, 'valid formula name test';

throws_ok {
    $test->right_circular_cone( formula => 'volume', radius => 10 );
}
qr/required parameter 'height' not defined/,
  'required parameter exception for height';

throws_ok {
    $test->right_circular_cone( formula => 'volume', height => 15 );
}
qr/required parameter 'radius' not defined/,
  'required parameter exception for radius';

throws_ok {
    $test->right_circular_cone(
        formula => 'lateral_surface_area',
        radius  => 10
    );
}
qr/required parameter 'height' not defined/,
  'required parameter exception for height';

throws_ok {
    $test->right_circular_cone(
        formula => 'lateral_surface_area',
        height  => 15
    );
}
qr/required parameter 'radius' not defined/,
  'required parameter exception for radius';

throws_ok {
    $test->right_circular_cone(
        formula => 'volume',
        radius  => '5a',
        height  => '5'
    );
}
qr/parameter 'radius' requires a numeric value/,
  'formula parameter radius is numeric';

throws_ok {
    $test->right_circular_cone(
        formula => 'volume',
        radius  => '5',
        height  => '5a'
    );
}
qr/parameter 'height' requires a numeric value/,
  'formula parameter height is numeric';

throws_ok {
    $test->right_circular_cone(
        formula => 'lateral_surface_area',
        radius  => '5a',
        height  => '5'
    );
}
qr/parameter 'radius' requires a numeric value/,
  'formula parameter radius is numeric';

throws_ok {
    $test->right_circular_cone(
        formula => 'lateral_surface_area',
        radius  => '5',
        height  => '5a'
    );
}
qr/parameter 'height' requires a numeric value/,
  'formula parameter height is numeric';
