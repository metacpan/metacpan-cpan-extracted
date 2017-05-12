use Test::More tests => 6;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;
do 'funcs.pl';

{
    ## compute a 2x2 inverse
    $matrix = Math::MatrixReal->new_from_string(<<"MATRIX");
[  3.0  7.0  ]
[  2.0  5.0  ]
MATRIX

    $inverse = Math::MatrixReal->new_from_string(<<"MATRIX");
[  5.0 -7.0 ]
[ -2.0  3.0 ]
MATRIX

    ok_matrix( $matrix ** -1 , $inverse, '** -1 = inverse ' );
}

{
    ## A*A^-1 should = indentity
    my $matrix = Math::MatrixReal->new_random(10);
    my $one = $matrix->clone();
    $one->one();

    ok_matrix($matrix * $matrix ** -1, $one );
}

{
    my $one = Math::MatrixReal->new(5,5);
    $one->one;
    ok_matrix( $one, $one ** -1, q{inverse of identity is identity} );

}

{
    my $matrix = Math::MatrixReal->new_random(3);
    ok_matrix( $matrix->inverse->inverse, $matrix );
}

{
    my $a = Math::MatrixReal->new_random(5);
    my $b = Math::MatrixReal->new_random(5);
    ok_matrix( ($a*$b)->inverse, ($b->inverse * $a->inverse) );

}

{
    my $x = 1 + int rand (10);
    my $a = Math::MatrixReal->new_from_rows ( [[ 1/$x ]] );
    my $inv = $a->inverse;
    ok_matrix( $a * $inv, $a->new_from_rows([[ 1 ]]), "inverting 1x1 matrices works" );

}
