#!perl -T

use strict;
use warnings;
use Geometry::Formula;
use Test::More tests => 7;

BEGIN {
    eval "use Test::Exception";
    plan skip_all => "Test::Exception needed" if $@;
}

my $test = Geometry::Formula->new;

my $surface_area = $test->cube( formula => 'surface_area', a => 5 );
like( $surface_area, qr/60/, 'calculation test' );

my $volume = $test->cube( formula => 'volume', a => 5 );
like( $volume, qr/125/, 'calculation test' );

throws_ok { $test->cube( formula => 'foo', a => 10 ); }
qr/invalid formula name: foo specified/, 'valid formula name test';

throws_ok { $test->cube( formula => 'volume', b => 10 ) }
qr/required parameter 'a' not defined/, 'required parameter exception for a';

throws_ok { $test->cube( formula => 'surface_area', b => 10 ) }
qr/required parameter 'a' not defined/, 'required parameter exception for a';

throws_ok { $test->cube( formula => 'surface_area', a => '5a', ); }
qr/parameter 'a' requires a numeric value/, 'formula parameter a is numeric';

throws_ok { $test->cube( formula => 'volume', a => '5a', ); }
qr/parameter 'a' requires a numeric value/, 'formula parameter height is numeric';
