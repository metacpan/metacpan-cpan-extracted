use Test::More tests => 10;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;
my $DEBUG = 0;

do 'funcs.pl';

$matrix = Math::MatrixReal->new_from_string(<<"MATRIX");
[ 1 0 0 0 1 ]
[ 0 2 0 0 2 ]
[ 0 0 3 0 0 ]
[ 0 0 0 4 0 ]
[ 0 0 0 0 5 ]
MATRIX
ok( $matrix->is_upper_triangular(), 'is_upper_triangular seems to work' );
########################
$matrix = Math::MatrixReal->new_from_string(<<"MATRIX");
[ 1 0 0 0 0 ]
[ 0 3 0 0 0 ]
[ 0 0 4 0 0 ]
[ 1 0 0 5 0 ]
[ 1 1 1 1 1 ]
MATRIX
ok($matrix->is_lower_triangular(), 'is_lower_triangular seems to work' );
#############################
$matrix = Math::MatrixReal->new_from_string(<<MATRIX);
[ 1 2 ]
MATRIX
ok( ! $matrix->is_upper_triangular(), 'row vecs cannot be triangular' );
ok( ! $matrix->is_lower_triangular(), 'row vecs cannot be triangular');

$matrix = Math::MatrixReal->new_from_string(<<MATRIX);
[ 1 ]
[ 3 ]
[ 1 ]
MATRIX
ok( ! $matrix->is_upper_triangular(), 'col vecs cannot be triangular' );
ok( ! $matrix->is_lower_triangular(), 'col vecs cannot be triangular');

$matrix = Math::MatrixReal->new_from_string(<<"MATRIX");
[ 1 0 0 0 1 ]
[ 0 3 0 0 0 ]
[ 0 0 4 0 0 ]
[ 1 0 0 5 0 ]
[ 1 1 1 1 1 ]
MATRIX
ok(! $matrix->is_lower_triangular() );
ok(! $matrix->is_upper_triangular() );
################################
## diag matrices are both!
$matrix = Math::MatrixReal->new_diag( [ qw(1 2 4 5 5 45 45 5 4) ] );
ok($matrix->is_lower_triangular(), 'diagonal matrices are lower triangular' );
ok($matrix->is_upper_triangular(), 'diagonal matrices are upper triangular' );


