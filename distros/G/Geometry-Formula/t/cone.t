#!perl -T

use strict;
use warnings;
use Geometry::Formula;
use Test::More tests => 6;

BEGIN {
    eval "use Test::Exception";
    plan skip_all => "Test::Exception needed" if $@;
}

my $test = Geometry::Formula->new;

my $volume = $test->cone( formula => 'volume', base => 5, height => 5 );
like( $volume, qr/8.333333/, 'calculation test' );

throws_ok { $test->cone( formula => 'foo', radius => 10 ); }
qr/invalid formula name: foo specified/, 'valid formula name test';

throws_ok { $test->cone( formula => 'volume', base => 10 ) }
qr/required parameter 'height' not defined/,
  'required parameter exception for height';

throws_ok { $test->cone( formula => 'volume', height => 10 ) }
qr/required parameter 'base' not defined/,
  'required parameter exception for base';

throws_ok { $test->cone( formula => 'volume', base => '5a', height => '5' ); }
qr/parameter 'base' requires a numeric value/,
  'formula parameter base is numeric';

throws_ok { $test->cone( formula => 'volume', base => '5', height => '5a' ); }
qr/parameter 'height' requires a numeric value/,
  'formula parameter height is numeric';
