#!perl -T

use strict;
use warnings;
use Geometry::Formula;
use Test::More tests => 13;

BEGIN {
    eval "use Test::Exception";
    plan skip_all => "Test::Exception need" if $@;
};

my $test = Geometry::Formula->new;

my $area = $test->triangle(
    formula => 'area',
    base    => 5,
    height  => 10,
);
like( $area, qr/25/, 'calculation test' );

my $perimeter = $test->triangle(
    formula => 'perimeter',
    a       => 5,
    b       => 10,
    c       => 15,
);
like( $perimeter, qr/30/, 'calculation test' );

throws_ok {
    $test->triangle( formula => 'foo', a => 5, b => 10, height => 15 );
}
qr/invalid formula name: foo specified/, 'valid formula name test';

throws_ok { $test->triangle( formula => 'area', base => 5 ) }
qr/required parameter 'height' not defined/,
  'required parameter exception for height';

throws_ok { $test->triangle( formula => 'area', height => 10 ) }
qr/required parameter 'base' not defined/,
  'required parameter exception for base';

throws_ok {
    $test->triangle( formula => 'perimeter', b => 10, c => 15 );
}
qr/required parameter 'a' not defined/, 'required parameter exception for a';

throws_ok {
    $test->triangle( formula => 'perimeter', a => 5, c => 15 );
}
qr/required parameter 'b' not defined/, 'required parameter exception for b';

throws_ok {
    $test->triangle( formula => 'perimeter', a => 5, b => 10 );
}
qr/required parameter 'c' not defined/, 'required parameter exception for c';

throws_ok { $test->triangle( formula => 'area', base => '5a', height => 10 ); }
qr/parameter 'base' requires a numeric value/,
  'formula parameter base is numeric';

throws_ok {
    $test->triangle( formula => 'area', base => '5', height => '10a' );
}
qr/parameter 'height' requires a numeric value/,
  'formula parameter height is numeric';

throws_ok {
    $test->triangle(
        formula => 'perimeter',
        a       => '5a',
        b       => 10,
        c       => 15,
    );
}
qr/parameter 'a' requires a numeric value/, 'formula parameter a is numeric';

throws_ok {
    $test->triangle(
        formula => 'perimeter',
        a       => '5',
        b       => '10a',
        c       => 15,
    );
}
qr/parameter 'b' requires a numeric value/, 'formula parameter b is numeric';

throws_ok {
    $test->triangle(
        formula => 'perimeter',
        a       => '5',
        b       => 10,
        c       => '15a',
    );
}
qr/parameter 'c' requires a numeric value/, 'formula parameter c is numeric';
