use Test::More tests => 2;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;

my $DEBUG = 0;

do 'funcs.pl';

$matrix = Math::MatrixReal->new_diag( [ 1, 2, 3 ] );
$cofactor = Math::MatrixReal->new_from_string(<<MATRIX);
[  6.000000000000E+00 -0.000000000000E+00  0.000000000000E+00 ]
[ -0.000000000000E+00  3.000000000000E+00 -0.000000000000E+00 ]
[  0.000000000000E+00 -0.000000000000E+00  2.000000000000E+00 ]
MATRIX
ok_matrix($matrix->adjoint(), ~$cofactor, 'adjoint is the transpose of the cofactor');
# the same
$matrix = Math::MatrixReal->new_random(6);
ok_matrix($matrix->adjoint->inverse,$matrix->inverse->adjoint, 'inverse and adjoint operators are commutative');

