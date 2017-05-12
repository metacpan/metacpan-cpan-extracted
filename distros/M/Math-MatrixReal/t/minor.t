use Test::More tests => 3;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;
do 'funcs.pl';

$matrix = Math::MatrixReal->new_diag( [ 1, 2, 3 ] );
$minor11 = Math::MatrixReal->new_from_rows ( [ [2,0],[0,3] ] );
$minor22 = Math::MatrixReal->new_from_rows ( [ [1,0],[0,3] ] );
$minor13 = Math::MatrixReal->new_from_rows ( [ [0,2],[0,0] ] );

ok_matrix($matrix->minor(1,1),$minor11);
ok_matrix($matrix->minor(2,2),$minor22);
ok_matrix($matrix->minor(1,3),$minor13);

