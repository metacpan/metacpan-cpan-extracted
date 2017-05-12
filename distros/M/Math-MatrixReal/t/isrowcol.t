use Test::More tests => 7;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;
do 'funcs.pl';

$matrix1 = Math::MatrixReal->new_from_string(<<"MATRIX");
[ 1 0 0 0 ]
[ 0 2 0 0 ]
[ 0 0 3 0 ]
[ 0 0 0 4 ]
MATRIX

$matrix2 = Math::MatrixReal->new_from_string(<<"MATRIX");
[ 0 0 0 4 ]
[ 0 2 0 0 ]
[ 0 0 3 0 ]
[ 1 0 0 0 ]
MATRIX

$rowvec = $matrix1->row(1);
$colvec = $matrix2->column(2);
$s = $rowvec->column(1);

ok( ! $matrix1->is_row_vector );
ok( ! $matrix1->is_col_vector );
ok( ! $matrix2->is_row_vector );
ok( ! $matrix2->is_col_vector );
ok(  $rowvec->is_row_vector );
ok(  $colvec->is_col_vector );
ok( $s->is_row_vector && $s->is_col_vector );


