use Test::More tests => 1;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;

do 'funcs.pl';

$matrix = new Math::MatrixReal (10,10);
$matrix->one();
ok( $matrix->condition($matrix->inverse) - 1 < 1e-6, 'identity has condition number = 1' );

