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

my $area = $test->square(
    formula => 'area',
    side  => 5 
);
like( $area, qr/25/, 'calculation test' );

my $perimeter = $test->square(
    formula => 'perimeter',
    side  => 5
);
like( $perimeter, qr/20/, 'calculation test' );

throws_ok { $test->square( formula => 'foo', side => 15 ); }
qr/invalid formula name: foo specified/, 'valid formula name test';

throws_ok { $test->square( formula => 'area' ) }
qr/required parameter 'side' not defined/,
  'required parameter exception for side';

throws_ok { $test->square( formula => 'perimeter' ) }
qr/required parameter 'side' not defined/,
  'required parameter exception for side';

throws_ok { $test->square( formula => 'area', side => '5a' ); }
qr/parameter 'side' requires a numeric value/,
  'formula parameter side is numeric';

throws_ok { $test->square( formula => 'perimeter', side => '5a' ); }
qr/parameter 'side' requires a numeric value/,
  'formula parameter side is numeric';
