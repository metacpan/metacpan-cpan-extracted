use Test::More tests => 1;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;

do 'funcs.pl';
$eps = 1e-6;
my $A = Math::MatrixReal->new_from_string(<<"MATRIX");
[  1   2   3  ]
[  5   7  11  ]
[ 23  19  13  ]
MATRIX

$b  = Math::MatrixReal->new_from_cols([[0, 1, 29 ]] );
$x0 = Math::MatrixReal->new_from_cols([[1, 1, -1.1 ]] );
$sol = Math::MatrixReal->new_from_cols([[1, 1, -1 ]] );

SKIP : {
    skip  'solve_GSM ? ', 1;

if ( $xn = $A->solve_GSM($x0,$b,$eps) ) {
    print $xn;  
    ok( ($xn - $sol) < $eps, 'solve_GSM seems to work');
} else {
    ok( 0, 'solve_GSM' );
}

}
