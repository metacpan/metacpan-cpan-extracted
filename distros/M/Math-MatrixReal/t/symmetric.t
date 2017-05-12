use Test::More tests => 8;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;

do 'funcs.pl';

$matrix = Math::MatrixReal->new_from_string(<<"MATRIX");
[ 1 0 0 0 1 ]
[ 0 2 0 0 0 ]
[ 0 0 3 0 0 ]
[ 0 0 0 4 0 ]
[ 1 0 0 0 5 ]
MATRIX
ok( $matrix->is_symmetric() );
########################
$matrix = Math::MatrixReal->new_from_string(<<"MATRIX");
[ 0 2 0 0 1 ]
[ 0 0 3 0 0 ]
[ 0 0 0 4 0 ]
[ 1 0 0 0 5 ]
MATRIX

ok(! $matrix->is_symmetric() );
#############################
$matrix = Math::MatrixReal->new_from_string(<<MATRIX);
[ 1 ]
MATRIX
ok($matrix->is_symmetric(), '1x1 matrix is symmetric' );
################
$matrix = $matrix->new_diag( [ 1, 2, 3, 4 ] );
ok( $matrix->is_skew_symmetric, 'diagonal matrix is skew symmetric' );
ok( $matrix->is_symmetric, 'diagonal matrix is symmetric' );
###########
$matrix = Math::MatrixReal->new_from_string(<<"MATRIX");
[ 1 0 0 0 1 ]
[ 0 2 0 0 0 ]
[ 0 0 3 0 0 ]
[ 0 0 0 4 0 ]
[ -1 0 0 0 5 ]
MATRIX
ok($matrix->is_skew_symmetric );
##########
$matrix->zero;
ok($matrix->is_skew_symmetric, 'zero matrix is skey symmetric');
############
$matrix = Math::MatrixReal->new_from_string(<<"MATRIX");
[ 0 2 0 0 1 ]
[ 0 0 3 0 0 ]
[ 0 0 0 4 0 ]
[ 1 0 0 0 5 ]
MATRIX
ok(! $matrix->is_skew_symmetric );
