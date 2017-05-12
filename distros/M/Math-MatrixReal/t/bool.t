use Test::More tests => 12;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;

do 'funcs.pl';

$matrix = Math::MatrixReal->new_from_string(<<"MATRIX");
[ 1 0 0 0 1 ]
[ 0 2 0 0 2 ]
[ 0 0 3 0 0 ]
[ 0 0 0 4 0 ]
[ 0 0 0 0 1 ]
MATRIX
ok(!$matrix->is_positive, 'matrices containing zeros are not considered positive' );
ok(!$matrix->is_negative, 'matrices containing zeros are not considered negative' );
ok($matrix, 'matrix returns true' );

########################
$matrix = Math::MatrixReal->new_from_string(<<"MATRIX");
[ 1 0 0 0 0 ]
[ 0 3 0 0 0 ]
[ 0 0 4 0 0 ]
[ 1 0 0 1 0 ]
[ 1 1 1 1 1 ]
MATRIX
$matrix = $matrix->each( sub { (shift)+1; } );
ok($matrix->is_positive, 'matrix is positive' );
ok(!$matrix->is_negative, 'matrix is not negative' );
ok($matrix, 'matrix returns true' );
$matrix = $matrix->each( sub { (shift)-11; } );
ok(!$matrix->is_positive );
ok($matrix->is_negative );
ok($matrix, 'matrix returns true' );
$matrix->zero;
ok(!$matrix->is_positive );
ok(!$matrix->is_negative );
ok(!$matrix );


