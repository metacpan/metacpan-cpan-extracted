#!perl -T

use strict;
use warnings;
use Geometry::Formula;
use Test::More tests => 15;

BEGIN {
    eval "use Test::Exception";
    plan skip_all => "Test::Exception need" if $@;
};

my $test = Geometry::Formula->new;

my $volume = $test->rectangular_solid(
    formula => 'volume',
    length  => 5,
    width   => 10,
    height  => 15
);
like( $volume, qr/750/, 'calculation test' );

my $surface_area = $test->rectangular_solid(
    formula => 'surface_area',
    length  => 5,
    width   => 10,
    height  => 15
);
like( $surface_area, qr/550/, 'calculation test' );

throws_ok {
    $test->rectangular_solid(
        formula => 'foo',
        length  => 5,
        width   => 10,
        height  => 15
    );
}
qr/invalid formula name: foo specified/, 'valid formula name test';

throws_ok { $test->rectangular_solid( formula => 'volume', length => 5, width => 10 ) }
qr/required parameter 'height' not defined/,
  'required parameter exception for height';

throws_ok { $test->rectangular_solid( formula => 'volume', width => 10, height => 15 ) }
qr/required parameter 'length' not defined/,
  'required parameter exception for length';

throws_ok { $test->rectangular_solid( formula => 'volume', length => 5, height => 15 ) }
qr/required parameter 'width' not defined/,
  'required parameter exception for width';

throws_ok { $test->rectangular_solid( formula => 'surface_area', length => 5, width => 10 ) }
qr/required parameter 'height' not defined/,
  'required parameter exception for height';

throws_ok { $test->rectangular_solid( formula => 'surface_area', width => 10, height => 15 ) }
qr/required parameter 'length' not defined/,
  'required parameter exception for length';

throws_ok { $test->rectangular_solid( formula => 'surface_area', length => 5, height => 15 ) }
qr/required parameter 'width' not defined/,
  'required parameter exception for width';


throws_ok {
    $test->rectangular_solid(
        formula => 'volume',
        length  => '5a',
        width   => '5',
        height  => '5'
    );
}
qr/parameter 'length' requires a numeric value/,
  'formula parameter length is numeric';

throws_ok {
    $test->rectangular_solid(
        formula => 'volume',
        length  => '5',
        width   => '5a',
        height  => '5'
    );
}
qr/parameter 'width' requires a numeric value/,
  'formula parameter width is numeric';

throws_ok {
    $test->rectangular_solid(
        formula => 'volume',
        length  => '5',
        width   => '5',
        height  => '5a'
    );
}
qr/parameter 'height' requires a numeric value/,
  'formula parameter height is numeric';

throws_ok {
    $test->rectangular_solid(
        formula => 'surface_area',
        length  => '5a',
        width   => '5',
        height  => '5'
    );
}
qr/parameter 'length' requires a numeric value/,
  'formula parameter length is numeric';

throws_ok {
    $test->rectangular_solid(
        formula => 'surface_area',
        length  => '5',
        width   => '5a',
        height  => '5'
    );
}
qr/parameter 'width' requires a numeric value/,
  'formula parameter width is numeric';

throws_ok {
    $test->rectangular_solid(
        formula => 'surface_area',
        length  => '5',
        width   => '5',
        height  => '5a'
    );
}
qr/parameter 'height' requires a numeric value/,
  'formula parameter height is numeric';
