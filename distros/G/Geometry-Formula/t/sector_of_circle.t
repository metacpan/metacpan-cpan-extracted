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

my $area = $test->sector_of_circle( formula => 'area', theta => 5, radius => 10 );
like( $area, qr/4.36332305555556/, 'calculation test' );

throws_ok { $test->sector_of_circle( formula => 'foo', theta => 5, radius => 10 ); }
qr/invalid formula name: foo specified/, 'valid formula name test';

throws_ok { $test->sector_of_circle( formula => 'area', radius => 10 ) }
qr/required parameter 'theta' not defined/,
  'required parameter exception for theta';

throws_ok { $test->sector_of_circle( formula => 'area', theta => 5 ) }
qr/required parameter 'radius' not defined/,
  'required parameter exception for radius';

throws_ok { $test->sector_of_circle( formula => 'area', theta => '1a', radius => 10 ); }
qr/parameter 'theta' requires a numeric value/,
  'formula parameter theta is numeric';

throws_ok { $test->sector_of_circle( formula => 'area', theta => '5', radius => '1a' ); }
qr/parameter 'radius' requires a numeric value/,
  'formula parameter radius is numeric';
