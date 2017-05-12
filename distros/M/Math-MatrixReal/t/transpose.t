use Test::More tests => 4;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;

do 'funcs.pl';

$matrix = Math::MatrixReal->new_diag( [ 1, 2, 3 ] );
$matrix2 = Math::MatrixReal->new_random(10);

ok_matrix(~$matrix, $matrix, 'transpose of a diagonal matrix is itself');
ok_matrix(~(~$matrix2), $matrix2, 'transpose twice = original' );
ok_matrix( ($matrix2 + ~$matrix2), ~($matrix2 + ~$matrix2), 'transpose commutes with addition' );
ok_matrix( ($matrix2 - ~$matrix2), -~($matrix2 - ~$matrix2), 'transpose commutes with subtraction' );

