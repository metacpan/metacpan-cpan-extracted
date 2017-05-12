use Test::More tests => 2;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;
do 'funcs.pl';
my $eps = 1e-8;

$vec1 = Math::MatrixReal->new_from_string(<<MAT);
[ 1 ]
[ 2 ]
[ 3 ]
MAT

$vec2 = Math::MatrixReal->new_from_string(<<MAT);
[ 4 ]
[ 5 ]
[ 6 ]
MAT

#orthogonal to both
$vec = $vec1->vector_product($vec2);
ok( $vec->scalar_product($vec1) < $eps, 'vector product is orthogonal' );
ok( $vec->scalar_product($vec2) < $eps ,'vector product is orthogonal');


