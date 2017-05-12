#!perl -T

use strict;
use warnings;
use Geometry::Formula;
use Test::More tests => 6;

BEGIN {
    eval "use Test::Exception";
    plan skip_all => "Test::Exception need" if $@;
};

my $test = Geometry::Formula->new;

my $area = $test->rhombus( formula => 'area', a => 5, b => 10 );
like( $area, qr/25/, 'calculation test' );

throws_ok { $test->rhombus( formula => 'foo', a => 5, b => 10 ); }
qr/invalid formula name: foo specified/, 'valid formula name test';

throws_ok { $test->rhombus( formula => 'area', b => 10 ) }
qr/required parameter 'a' not defined/,
  'required parameter exception for a';

throws_ok { $test->rhombus( formula => 'area', a => 5 ) }
qr/required parameter 'b' not defined/,
  'required parameter exception for b';

throws_ok { $test->rhombus( formula => 'area', a => '1a', b => 10 ); }
qr/parameter 'a' requires a numeric value/,
  'formula parameter a is numeric';

throws_ok { $test->rhombus( formula => 'area', a => '5', b => '1a' ); }
qr/parameter 'b' requires a numeric value/,
  'formula parameter b is numeric';
