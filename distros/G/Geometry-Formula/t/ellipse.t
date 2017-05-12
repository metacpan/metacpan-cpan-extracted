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

my $area = $test->ellipse( formula => 'area', a => 5, b => 10 );
like( $area, qr/157.07963/, 'calculation test' );

my $perimeter = $test->ellipse( formula => 'perimeter', a => 5, b => 10 );
like( $perimeter, qr/49.672940/, 'calculation test' );

throws_ok { $test->ellipse( formula => 'foo', a => 10 ); }
qr/invalid formula name: foo specified/, 'valid formula name test';

throws_ok { $test->ellipse( formula => 'area', d => 10, b => 10 ) }
qr/required parameter 'a' not defined/, 'required parameter exception';

throws_ok { $test->ellipse( formula => 'area', a => 10, c => 10 ) }
qr/required parameter 'b' not defined/, 'required parameter exception';

throws_ok { $test->ellipse( formula => 'perimeter', d => 10, b => 10 ) }
qr/required parameter 'a' not defined/, 'required parameter exception';

throws_ok { $test->ellipse( formula => 'perimeter', a => 10, c => 10 ) }
qr/required parameter 'b' not defined/, 'required parameter exception';

throws_ok { $test->ellipse( formula => 'area', a => '5a', b => '5' ); }
qr/parameter 'a' requires a numeric value/, 'formula parameter a is numeric';

throws_ok { $test->ellipse( formula => 'area', b => '5a', a => '5' ); }
qr/parameter 'b' requires a numeric value/, 'formula parameter b is numeric';

throws_ok { $test->ellipse( formula => 'perimeter', a => '5a', b => '5' ); }
qr/parameter 'a' requires a numeric value/, 'formula parameter a is numeric';

throws_ok { $test->ellipse( formula => 'perimeter', b => '5a', a => '5' ); }
qr/parameter 'b' requires a numeric value/, 'formula parameter b is numeric';
