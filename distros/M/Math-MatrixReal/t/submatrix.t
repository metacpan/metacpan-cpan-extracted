use Test::More tests => 4;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;
use strict;

do 'funcs.pl';
my $eps ||= 1e-8;

my $matrix = Math::MatrixReal->new_from_string(<<"MATRIX");
[ 1 2 3 ]
[ 4 5 6 ]
[ 7 8 9 ]
MATRIX

my $submatrix1 = $matrix->new_from_rows([ [5,6], [8,9] ]);
my $submatrix2 = $matrix->new_from_rows([ [5] ]);
ok_matrix($submatrix1, $matrix->submatrix(2,2,3,3) , "submatrix");
ok_matrix($submatrix2, $matrix->submatrix(2,2,2,2) , "submatrix");

#print $matrix->submatrix(3,3,2,2);
#ok_matrix($submatrix1, $matrix->submatrix(3,3,2,2) , "submatrix");

{
    assert_dies ( sub { $matrix->submatrix(0,1,2,3) } , q{indices must be > 0} );
}
{
    assert_dies ( sub { $matrix->submatrix(1,1,2,-3) }, q{indices cannot be negative} );
}
