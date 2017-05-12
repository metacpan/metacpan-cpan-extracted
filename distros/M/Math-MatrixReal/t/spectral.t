use Test::More tests => 5;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;

do 'funcs.pl';

$matrix = Math::MatrixReal->new_from_string(<<"MATRIX");
[ 1 0 0 0 1 ]
[ 0 2 0 0 2 ]
[ 0 0 3 0 0 ]
[ 0 0 0 4 0 ]
[ 0 0 0 0 5 ]
MATRIX
ok( $matrix->spectral_radius == 5 );
$matrix->zero();
ok($matrix->spectral_radius == 0, 'zero matrix has spectral radius=0' );
$matrix->one();
ok($matrix->spectral_radius == 1, 'identity has spectral radius=1' );
$matrix = $matrix->new_from_rows( [ [3,-1],[-1,3] ] );
ok( similar($matrix->spectral_radius,4) );
$matrix = $matrix->new_from_rows( [ [1.5,0.5],[.5,1.5] ] );
ok(similar($matrix->spectral_radius,2) );



