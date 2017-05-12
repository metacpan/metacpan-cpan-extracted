#!perl -T

use strict;
use warnings;
use Geometry::Formula;
use Test::More tests => 4;

BEGIN {
    eval "use Test::Exception";
    plan skip_all => "Test::Exception needed" if $@;
}

my $test = Geometry::Formula->new;

my $area = $test->equilateral_triangle( formula => 'area', side => 5 );
like( $area, qr/10.82531/, 'calculation test' );

throws_ok { $test->equilateral_triangle( formula => 'foo', side => 5 ); }
qr/invalid formula name: foo specified/, 'valid formula name test';

throws_ok { $test->equilateral_triangle( formula => 'area' ) }
qr/required parameter 'side' not defined/,
  'required parameter exception for side';

throws_ok { $test->equilateral_triangle( formula => 'area', side => '1a' ); }
qr/parameter 'side' requires a numeric value/,
  'formula parameter side is numeric';
