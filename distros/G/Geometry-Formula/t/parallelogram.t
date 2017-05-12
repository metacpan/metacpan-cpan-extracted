#!perl -T

use strict;
use warnings;
use Geometry::Formula;
use Test::More tests => 11;

BEGIN {
    eval "use Test::Exception";
    plan skip_all => "Test::Exception needed" if $@;
}

my $test = Geometry::Formula->new;

my $area = $test->parallelogram( formula => 'area', base => 5, height => 10 );
like( $area, qr/50/, 'calculation test' );

my $perimeter = $test->parallelogram( formula => 'perimeter', a => 5, b => 10 );
like( $perimeter, qr/30/, 'calculation test' );

throws_ok { $test->parallelogram( formula => 'foo', base => 5, height => 10 ); }
qr/invalid formula name: foo specified/, 'valid formula name test';

throws_ok { $test->parallelogram( formula => 'area', base => 10 ) }
qr/required parameter 'height' not defined/,
  'required parameter exception for height';

throws_ok { $test->parallelogram( formula => 'area', height => 10 ) }
qr/required parameter 'base' not defined/,
  'required parameter exception for base';

throws_ok { $test->parallelogram( formula => 'perimeter', a => 10 ) }
qr/required parameter 'b' not defined/,
  'required parameter exception for b';

throws_ok { $test->parallelogram( formula => 'perimeter', b => 10 ) }
qr/required parameter 'a' not defined/,
  'required parameter exception for a';

throws_ok {
    $test->parallelogram( formula => 'area', base => '5a', height => '5' );
}
qr/parameter 'base' requires a numeric value/,
  'formula parameter base is numeric';

throws_ok {
    $test->parallelogram( formula => 'area', base => '5', height => '5a' );
}
qr/parameter 'height' requires a numeric value/,
  'formula parameter height is numeric';

throws_ok {
    $test->parallelogram( formula => 'perimeter', a => '5a', b => '5' );
}
qr/parameter 'a' requires a numeric value/, 'formula parameter a is numeric';

throws_ok {
    $test->parallelogram( formula => 'perimeter', a => '5', b => '5a' );
}
qr/parameter 'b' requires a numeric value/, 'formula parameter b is numeric';

