use Test::More tests => 5;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;
do 'funcs.pl';
$eps ||= 1e-8;

$matrix = Math::MatrixReal->new_from_string(<<"MATRIX");
[ 1 2 2 ]
[ 2 1 -2 ]
[ -2 2 -1 ]
MATRIX

$matrix = $matrix->each( sub { (shift)/3; } );

ok( $matrix->is_orthogonal );
ok( ($matrix**2)->is_orthogonal );
ok( (~$matrix)->is_orthogonal );
ok( $matrix->inverse->is_orthogonal );
# det is +-1
ok( abs(abs($matrix->det) - 1) < $eps );
