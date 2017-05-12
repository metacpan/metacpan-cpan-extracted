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

my $area = $test->rectangle( formula => 'area', length => 5, width => 10 );
like( $area, qr/50/, 'calculation test' );

my $perimeter =
  $test->rectangle( formula => 'perimeter', length => 5, width => 10 );
like( $perimeter, qr/30/, 'calculation test' );

throws_ok { $test->rectangle( formula => 'foo', length => 5, width => 10 ); }
qr/invalid formula name: foo specified/, 'valid formula name test';

throws_ok { $test->rectangle( formula => 'area', length => 10 ) }
qr/required parameter 'width' not defined/,
  'required parameter exception for width';

throws_ok { $test->rectangle( formula => 'area', width => 10 ) }
qr/required parameter 'length' not defined/,
  'required parameter exception for length';

throws_ok { $test->rectangle( formula => 'perimeter', width => 10 ) }
qr/required parameter 'length' not defined/,
  'required parameter exception for b';

throws_ok { $test->rectangle( formula => 'perimeter', width => 10 ) }
qr/required parameter 'length' not defined/,
  'required parameter exception for a';

throws_ok {
    $test->rectangle( formula => 'area', length => '5a', width => '5' );
}
qr/parameter 'length' requires a numeric value/,
  'formula parameter length is numeric';

throws_ok {
    $test->rectangle( formula => 'area', length => '5', width => '5a' );
}
qr/parameter 'width' requires a numeric value/,
  'formula parameter width is numeric';

throws_ok {
    $test->rectangle( formula => 'perimeter', length => '5a', width => '5' );
}
qr/parameter 'length' requires a numeric value/, 'formula parameter a is numeric';

throws_ok {
    $test->rectangle( formula => 'perimeter', length => '5', width => '5a' );
}
qr/parameter 'width' requires a numeric value/, 'formula parameter b is numeric';

