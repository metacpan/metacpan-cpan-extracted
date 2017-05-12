use Test::More tests => 2;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;
do 'funcs.pl';

###############################
$matrix = Math::MatrixReal->new_from_string(<<"MATRIX");
[ 1 0 0 0 0 ]
[ 0 2 0 0 0 ]
[ 0 0 3 0 0 ]
[ 0 0 0 4 0 ]
[ 0 0 0 0 5 ]
MATRIX
my $matrix_squared = $matrix->each_diag( sub { (shift)**2 } );;
ok_matrix( $matrix * $matrix, $matrix_squared, 'each_diag works' );
################################
$all_ones = Math::MatrixReal->new_from_string(<<"MATRIX");
[ 1 1 1 1 1 ]
[ 1 1 1 1 1 ]
[ 1 1 1 1 1 ]
[ 1 1 1 1 1 ]
[ 1 1 1 1 1 ]
MATRIX

$matrix->zero();
$matrix = $matrix->each ( sub { (shift) + 1 } );
ok_matrix($matrix, $all_ones, 'each works' );



