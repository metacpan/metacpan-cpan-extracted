#!perl -T

use strict;
use warnings;
use Geometry::Formula;
use Test::More tests => 7;

BEGIN {
    eval "use Test::Exception";
    plan skip_all => "Test::Exception need" if $@;
};

my $test = Geometry::Formula->new;

my $surface_area = $test->sphere(
    formula => 'surface_area',
    radius  => 5
);
like( $surface_area, qr/314.15926/, 'calculation test' );

my $volume = $test->sphere(
    formula => 'volume',
    radius  => 5
);
like( $volume, qr/523.598766666667/, 'calculation test' );

throws_ok { $test->sphere( formula => 'foo', radius => 15 ); }
qr/invalid formula name: foo specified/, 'valid formula name test';

throws_ok { $test->sphere( formula => 'volume' ) }
qr/required parameter 'radius' not defined/,
  'required parameter exception for radius';

throws_ok { $test->sphere( formula => 'surface_area' ) }
qr/required parameter 'radius' not defined/,
  'required parameter exception for radius';

throws_ok { $test->sphere( formula => 'volume', radius => '5a' ); }
qr/parameter 'radius' requires a numeric value/,
  'formula parameter radius is numeric';

throws_ok { $test->sphere( formula => 'surface_area', radius => '5a' ); }
qr/parameter 'radius' requires a numeric value/,
  'formula parameter radius is numeric';
