#!perl -T

use strict;
use warnings;
use Geometry::Formula;
use Test::More tests => 22;

BEGIN {
    eval "use Test::Exception";
    plan skip_all => "Test::Exception needed" if $@;
}

my $test = Geometry::Formula->new;

my $lateral_surface_area = $test->frustum_of_right_circular_cone(
    formula      => 'lateral_surface_area',
    slant_height => 5,
    small_radius => 10,
    large_radius => 15
);
like( $lateral_surface_area, qr/555.36035/, 'calculation test' );

my $total_surface_area = $test->frustum_of_right_circular_cone(
    formula      => 'total_surface_area',
    height       => 5,
    small_radius => 10,
    large_radius => 15
);
like( $total_surface_area, qr/1576.37795279637/, 'calculation test' );

my $volume = $test->frustum_of_right_circular_cone(
    formula      => 'volume',
    height       => 5,
    small_radius => 10,
    large_radius => 15

);
like( $volume, qr/2487.09414166667/, 'calculation test' );

throws_ok {
    $test->frustum_of_right_circular_cone(
        formula      => 'foo',
        height       => 5,
        small_radius => 10,
        large_radius => 15
    );
}
qr/invalid formula name: foo specified/, 'valid formula name test';

throws_ok {
    $test->frustum_of_right_circular_cone(
        formula      => 'lateral_surface_area',
        small_radius => 5,
        large_radius => 10
    );
}
qr/required parameter 'slant_height' not defined/,
  'required parameter exception for slant_height';

throws_ok {
    $test->frustum_of_right_circular_cone(
        formula      => 'lateral_surface_area',
        slant_height => 5,
        large_radius => 10
    );
}
qr/required parameter 'small_radius' not defined/,
  'required parameter exception for small_radius';

throws_ok {
    $test->frustum_of_right_circular_cone(
        formula      => 'lateral_surface_area',
        slant_height => 5,
        small_radius => 10
    );
}
qr/required parameter 'large_radius' not defined/,
  'required parameter exception for large_radius';

throws_ok {
    $test->frustum_of_right_circular_cone(
        formula      => 'total_surface_area',
        small_radius => 5,
        large_radius => 10
    );
}
qr/required parameter 'height' not defined/,
  'required parameter exception for height';

throws_ok {
    $test->frustum_of_right_circular_cone(
        formula      => 'total_surface_area',
        height       => 5,
        large_radius => 10
    );
}
qr/required parameter 'small_radius' not defined/,
  'required parameter exception for small_radius';

throws_ok {
    $test->frustum_of_right_circular_cone(
        formula      => 'total_surface_area',
        height       => 5,
        small_radius => 10
    );
}
qr/required parameter 'large_radius' not defined/,
  'required parameter exception for large_radius';

throws_ok {
    $test->frustum_of_right_circular_cone(
        formula      => 'volume',
        small_radius => 5,
        large_radius => 10
    );
}
qr/required parameter 'height' not defined/,
  'required parameter exception for height';

throws_ok {
    $test->frustum_of_right_circular_cone(
        formula      => 'volume',
        height       => 5,
        large_radius => 10
    );
}
qr/required parameter 'small_radius' not defined/,
  'required parameter exception for small_radius';

throws_ok {
    $test->frustum_of_right_circular_cone(
        formula      => 'volume',
        height       => 5,
        small_radius => 10
    );
}
qr/required parameter 'large_radius' not defined/,
  'required parameter exception for large_radius';

throws_ok {
    $test->frustum_of_right_circular_cone(
        formula      => 'lateral_surface_area',
        slant_height => '5a',
        small_radius => 10,
        large_radius => 15
    );
}
qr/parameter 'slant_height' requires a numeric value/,
  'formula parameter slant_height is numeric';

throws_ok {
    $test->frustum_of_right_circular_cone(
        formula      => 'lateral_surface_area',
        slant_height => 5,
        small_radius => '10a',
        large_radius => 15
    );
}
qr/parameter 'small_radius' requires a numeric value/,
  'formula parameter small_radius is numeric';

throws_ok {
    $test->frustum_of_right_circular_cone(
        formula      => 'lateral_surface_area',
        slant_height => 5,
        small_radius => 10,
        large_radius => '15a'
    );
}
qr/parameter 'large_radius' requires a numeric value/,
  'formula parameter large_radius is numeric';

throws_ok {
    $test->frustum_of_right_circular_cone(
        formula      => 'total_surface_area',
        height       => '5a',
        small_radius => 10,
        large_radius => 15
    );
}
qr/parameter 'height' requires a numeric value/,
  'formula parameter height is numeric';

throws_ok {
    $test->frustum_of_right_circular_cone(
        formula      => 'total_surface_area',
        height       => 5,
        small_radius => '10a',
        large_radius => 15
    );
}
qr/parameter 'small_radius' requires a numeric value/,
  'formula parameter small_radius is numeric';

throws_ok {
    $test->frustum_of_right_circular_cone(
        formula      => 'total_surface_area',
        height       => 5,
        small_radius => 10,
        large_radius => '15a'
    );
}
qr/parameter 'large_radius' requires a numeric value/,
  'formula parameter large_radius is numeric';

throws_ok {
    $test->frustum_of_right_circular_cone(
        formula      => 'volume',
        height       => '5a',
        small_radius => 10,
        large_radius => 15
    );
}
qr/parameter 'height' requires a numeric value/,
  'formula parameter height is numeric';

throws_ok {
    $test->frustum_of_right_circular_cone(
        formula      => 'volume',
        height       => 5,
        small_radius => '10a',
        large_radius => 15
    );
}
qr/parameter 'small_radius' requires a numeric value/,
  'formula parameter small_radius is numeric';

throws_ok {
    $test->frustum_of_right_circular_cone(
        formula      => 'volume',
        height       => 5,
        small_radius => 10,
        large_radius => '15a'
    );
}
qr/parameter 'large_radius' requires a numeric value/,
  'formula parameter large_radius is numeric';
