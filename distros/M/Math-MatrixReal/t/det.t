use Test::More tests => 13;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;
do 'funcs.pl';
my $eps ||= 1e-8;

$matrix = Math::MatrixReal->new_from_string(<<"MATRIX");
[ 1 0 0 0 1 ]
[ 0 2 0 0 2 ]
[ 0 0 3 0 0 ]
[ 0 0 0 4 0 ]
[ 0 0 0 0 1 ]
MATRIX
ok( similar( $matrix->det(), 24), 'det works' );
########################
$matrix = Math::MatrixReal->new_from_string(<<"MATRIX");
[ 1 0 0 0 0 ]
[ 0 3 0 0 0 ]
[ 0 0 4 0 0 ]
[ 1 0 0 1 0 ]
[ 1 1 1 1 1 ]
MATRIX
ok( similar( $matrix->det(), 12)  );
###############################

$matrix = Math::MatrixReal->new_from_string(<<"MATRIX");
[ 1 0 0 0 0 ]
[ 0 1 0 0 0 ]
[ 0 0 4 0 0 ]
[ 0 0 0 5 0 ]
[ 0 0 0 0 1 ]
MATRIX
ok( similar( $matrix->det, 20)  );

$matrix = Math::MatrixReal->new_from_string(<<"MATRIX");
[ 0 0 0 0 0 ]
[ 0 1 0 0 0 ]
[ 0 0 4 0 0 ]
[ 0 0 0 5 0 ]
[ 0 0 0 0 1 ]
MATRIX
ok($matrix->det() == 0, 'diagonal matrix with 0 on diagonal has det=0');
##################
$eps=1e-6;

$matrix = Math::MatrixReal->new_random(5, {bounded_by=>[1,10],
			integer => 1, symmetric => 1} ) ;
	my $det1 = (~$matrix)->det;
	my $det2 = $matrix->det;
	ok( abs($det1-$det2) < $eps, sprintf("%.12f =? %.12f",$det1,$det2) );


############
my($r,$c) = $matrix->dim;
ok( $r == 5 && $c == 5, 'new_random returns square matrix');
$inverse = $matrix->inverse();
$det = $matrix->det();
$det1=1/$det;
$det2=$inverse->det();
ok( abs($det1-$det2) < $eps , sprintf("%.12f =? %.12f",$det1,$det2) );


############
## det(A) = product of eigenvalues
my $opts = { bounded_by => [-1,1], integer    => 1, symmetric => 1 };
my $b = Math::MatrixReal->new_random(5, $opts);
ok( $matrix->is_symmetric, 'new_random returns symmetric matrix');

for ( 1 .. 5 ){
	$b->new_random(5, $opts);
	$det1 = $b->det();
	my $ev = $b->sym_eigenvalues;
	$det2=1;
	$ev->each( sub { $det2*=(shift); } );
	ok( similar( $det1, $det2,$eps), 'product of eigenvalues equals the determinant');
}


