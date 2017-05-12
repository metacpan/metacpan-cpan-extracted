use Test::More tests => 8;
use Math::MatrixReal;
use File::Spec;
use lib File::Spec->catfile("..","lib");

do 'funcs.pl';

##########################
## test to see if is_diagonal works
my $matrix = Math::MatrixReal->new_from_string(<<'MATRIX');
[  1  0  0  0  0  0  0  ]
[  0  5  0  0  0  0  0  ]
[  0  0  1  0  0  0  0  ]
[  0  0  0  1  0  0  0  ]
[  0  0  0  0  5  0  0  ]
[  0  0  0  0  0  1  0  ]
[  0  0  0  0  0  0 -5  ]
MATRIX
ok( $matrix->is_diagonal(), 'is_diagonal works' );
###############################
## make sure it recognizes a matrix that is not diagonal
$matrix = Math::MatrixReal->new_from_string(<<"MATRIX");
      [  3  0  1  ]
      [  0  3  0  ]
      [  0  0  3  ]
MATRIX
ok(! $matrix->is_diagonal() );
###############################
## see if knows that if it ain't square, it ain't diagonal
$matrix = Math::MatrixReal->new_from_string(<<"MATRIX");
[ 1  0 ]
[ 0  0 ]
[ 0  1 ]
MATRIX
ok( ! $matrix->is_diagonal(), 'nonsquare matrix is not diagonal' );
##############################
## 1x1 matrix is diagonal by definition
$matrix = Math::MatrixReal->new_from_string(<<"MATRIX");
[ 1 ]
MATRIX
ok( $matrix->is_diagonal() ,'1x1 matrix is diagonal by definition');
##############################
### see if is_tridiagonal works
$matrix = Math::MatrixReal->new_from_string(<<'MATRIX');
[  4  7  0  0  0  0  0  ]
[  1  5  2  0  0  0  0  ]
[  0  9  1  3  0  0  0  ]
[  0  0  5  1  8  0  0  ]
[  0  0  0  6  5  3  0  ]
[  0  0  0  0  7  1  4  ]
[  0  0  0  0  0  4 -5  ]
MATRIX
ok($matrix->is_tridiagonal() );
##############################
### this isn't tridiag
$matrix = Math::MatrixReal->new_from_string(<<'MATRIX');
[  2  4  0  0  0  0  9  ]
[  1  5  2  0  0  0  0  ]
[  0  3  1  3  0  0  0  ]
[  0  0  5  1  8  0  0  ]
[  0  0  0  6  5  3  0  ]
[  0  0  0  0  7  1  4  ]
[  0  0  0  0  0  4  2  ]
MATRIX
ok( ! $matrix->is_tridiagonal() );
##############################
$matrix = Math::MatrixReal->new_from_string(<<'MATRIX');
[ 1 1 ]
[ 1 1 ]
MATRIX
ok( $matrix->is_tridiagonal(), '2x2 is always tridiag' );
###############################
### not quadratic => not tridiag
$matrix = Math::MatrixReal->new_from_string(<<'MATRIX');
[  2  4  0  0  0  0 ]
[  1  5  2  0  0  0 ]
[  0  3  1  3  0  0 ]
[  0  0  5  1  8  0 ]
[  0  0  0  6  5  3 ]
[  0  0  0  0  7  1 ]
[  0  0  0  0  0  4 ]
MATRIX
ok(! $matrix->is_tridiagonal() );


