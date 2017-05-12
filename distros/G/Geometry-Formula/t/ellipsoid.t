#!perl -T

use strict;
use warnings;
use Geometry::Formula;
use Test::More tests => 8;

BEGIN {
    eval "use Test::Exception";
    plan skip_all => "Test::Exception needed" if $@;
}

my $test = Geometry::Formula->new;

my $volume = $test->ellipsoid( formula => 'volume', a => 5, b => 10, c => 15 );
like( $volume, qr/3141.5926/, 'calculation test' );

throws_ok { $test->ellipsoid( formula => 'foo', a => 1, b => 2, c => 3 ); }
qr/invalid formula name: foo specified/, 'valid formula name test';

throws_ok { $test->ellipsoid( formula => 'volume', b => 2, c => 3 ) }
qr/required parameter 'a' not defined/,
  'required parameter exception for a';

throws_ok { $test->ellipsoid( formula => 'volume', a => 1, c => 3 ) }
qr/required parameter 'b' not defined/,
  'required parameter exception for b';

throws_ok { $test->ellipsoid( formula => 'volume', a => 1, b => 2 ) }
qr/required parameter 'c' not defined/,
  'required parameter exception for c';

throws_ok { $test->ellipsoid( formula => 'volume', a => '1a', b => 2, c => 3 ); }
qr/parameter 'a' requires a numeric value/,
  'formula parameter a is numeric';

throws_ok { $test->ellipsoid( formula => 'volume', a => 1, b => '2a', c => 3 ); }
qr/parameter 'b' requires a numeric value/,
  'formula parameter b is numeric';

throws_ok { $test->ellipsoid( formula => 'volume', a => 1, b => 2, c => '3a' ); }
qr/parameter 'c' requires a numeric value/,
  'formula parameter c is numeric';

