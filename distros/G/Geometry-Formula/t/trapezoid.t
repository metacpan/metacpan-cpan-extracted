#!perl -T

use strict;
use warnings;
use Geometry::Formula;
use Test::More tests => 17;

BEGIN {
    eval "use Test::Exception";
    plan skip_all => "Test::Exception need" if $@; 
};

my $test = Geometry::Formula->new;

my $area = $test->trapezoid(
    formula => 'area',
    a       => 5,
    b       => 10,
    height  => 15
);
like( $area, qr/112.5/, 'calculation test' );

my $perimeter = $test->trapezoid(
    formula => 'perimeter',
    a       => 5,
    b       => 10,
    c       => 15,
    d       => 20
);
like( $perimeter, qr/50/, 'calculation test' );

throws_ok { $test->trapezoid( formula => 'foo', a => 5, b => 10, height => 15 ); }
qr/invalid formula name: foo specified/, 'valid formula name test';

throws_ok { $test->trapezoid( formula => 'area', a => 5, b => 10 ) }
qr/required parameter 'height' not defined/,
  'required parameter exception for height';

throws_ok { $test->trapezoid( formula => 'area', a => 5, height => 15 ) }
qr/required parameter 'b' not defined/,
  'required parameter exception for b';

throws_ok { $test->trapezoid( formula => 'area', b => 10, height => 15 ) }
qr/required parameter 'a' not defined/,
  'required parameter exception for a';

throws_ok { $test->trapezoid( formula => 'perimeter', b => 10, c => 15, d => 20 ) }
qr/required parameter 'a' not defined/,
  'required parameter exception for a';

throws_ok { $test->trapezoid( formula => 'perimeter', a => 5 , c => 15, d => 20) }
qr/required parameter 'b' not defined/,
  'required parameter exception for b';

throws_ok { $test->trapezoid( formula => 'perimeter', a => 5, b => 10, d => 20 ) }
qr/required parameter 'c' not defined/,
  'required parameter exception for c';

throws_ok { $test->trapezoid( formula => 'perimeter', a => 5, b => 10, c => 15 ) }
qr/required parameter 'd' not defined/,
  'required parameter exception for d';

throws_ok { $test->trapezoid( formula => 'area', a => '5a', b => 10, height => 15 ); }
qr/parameter 'a' requires a numeric value/,
  'formula parameter a is numeric';

throws_ok { $test->trapezoid( formula => 'area', a => '5', b => '10a', height => 15 ); }
qr/parameter 'b' requires a numeric value/,
  'formula parameter b is numeric';

throws_ok { $test->trapezoid( formula => 'area', a => '5', b => '10', height => '15a' ); }
qr/parameter 'height' requires a numeric value/,
  'formula parameter height is numeric';

throws_ok { $test->trapezoid( formula => 'perimeter', a => '5a', b => 10, c => 15, d => 20 ); }
qr/parameter 'a' requires a numeric value/,
  'formula parameter a is numeric';

throws_ok { $test->trapezoid( formula => 'perimeter', a => '5', b => '10a', c => 15, d => 20 ); }
qr/parameter 'b' requires a numeric value/,
  'formula parameter b is numeric';

throws_ok { $test->trapezoid( formula => 'perimeter', a => '5', b => 10, c => '15a', d => 20 ); }
qr/parameter 'c' requires a numeric value/,
  'formula parameter c is numeric';

throws_ok { $test->trapezoid( formula => 'perimeter', a => '5', b => '10', c => 15, d => '20a' ); }
qr/parameter 'd' requires a numeric value/,
  'formula parameter d is numeric';

