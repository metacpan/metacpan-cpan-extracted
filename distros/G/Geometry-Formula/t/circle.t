#!perl -T

use strict;
use warnings;
use Geometry::Formula;
use Test::More tests => 10;

BEGIN {
    eval "use Test::Exception";
    plan skip_all => "Test::Exception needed" if $@;
}

my $test = Geometry::Formula->new;

my $area = $test->circle( formula => 'area', radius => 5 );
like( $area, qr/78.539815/, 'calculation test' );

my $circumference = $test->circle( formula => 'circumference', radius => 5 );
like( $circumference, qr/31.415926/, 'calculation test' );

my $diameter = $test->circle( formula => 'diameter', radius => 5 );
like( $diameter, qr/10/, 'calculation test' );

throws_ok { $test->circle( formula => 'foo', radius => 10 ); }
qr/invalid formula name: foo specified/, 'valid formula name test';

throws_ok { $test->circle( formula => 'area', fail => 10 ) }
qr/required parameter 'radius' not defined/,
  'required parameter exception for radius';

throws_ok { $test->circle( formula => 'circumference', fail => 10 ) }
qr/required parameter 'radius' not defined/,
  'required parameter exception for radius';

throws_ok { $test->circle( formula => 'diameter', fail => 10 ) }
qr/required parameter 'radius' not defined/,
  'required parameter exception for radius';

throws_ok { $test->circle( formula => 'area', radius => '5a' ); }
qr/parameter 'radius' requires a numeric value/,
  'formula parameter radius is numeric';

throws_ok { $test->circle( formula => 'circumference', radius => '5a' ); }
qr/parameter 'radius' requires a numeric value/,
  'formula parameter radius is numeric';

throws_ok { $test->circle( formula => 'diameter', radius => '5a' ); }
qr/parameter 'radius' requires a numeric value/,
  'formula parameter radius is numeric';
