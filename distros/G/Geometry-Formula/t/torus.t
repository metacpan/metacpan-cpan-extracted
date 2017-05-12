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

my $surface_area = $test->torus(
    formula => 'surface_area',
    a       => 5,
    b       => 10
);
like( $surface_area, qr/1973.92081287495/, 'calculation test' );

my $volume = $test->torus(
    formula => 'volume',
    a       => 5,
    b       => 10
);
like( $volume, qr/4934.80203218738/, 'calculation test' );

throws_ok { $test->torus( formula => 'foo', a => 5, b => 10 ); }
qr/invalid formula name: foo specified/, 'valid formula name test';

throws_ok { $test->torus( formula => 'surface_area', b => 10 ) }
qr/required parameter 'a' not defined/,
  'required parameter exception for a';

throws_ok { $test->torus( formula => 'surface_area', a => 5 ) }
qr/required parameter 'b' not defined/,
  'required parameter exception for b';

throws_ok { $test->torus( formula => 'volume', b => 10 ) }
qr/required parameter 'a' not defined/,
  'required parameter exception for a';

throws_ok { $test->torus( formula => 'volume', a => 5 ) }
qr/required parameter 'b' not defined/,
  'required parameter exception for b';

throws_ok { $test->torus( formula => 'surface_area', a => '5a', b => 10 ); }
qr/parameter 'a' requires a numeric value/,
  'formula parameter a is numeric';

throws_ok { $test->torus( formula => 'surface_area', a => '5', b => '10a' ); }
qr/parameter 'b' requires a numeric value/,
  'formula parameter b is numeric';

throws_ok { $test->torus( formula => 'volume', a => '5a', b => 10 ); }
qr/parameter 'a' requires a numeric value/,
  'formula parameter a is numeric';

throws_ok { $test->torus( formula => 'volume', a => '5', b => '10a' ); }
qr/parameter 'b' requires a numeric value/,
  'formula parameter b is numeric';

