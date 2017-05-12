use Test::More tests => 12;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;


do 'funcs.pl';

my $matrix = Math::MatrixReal->new_from_string(<<'MATRIX');
[  1  7  2  6  9  0  1  1 ]
[  0  5  0  0  0  0  0  0 ]
[  0  0  1  4  0  0  0  0 ]
[  0  0  0  1  0  0  0  0 ]
[  2  0  0  0  5  0  4  0 ]
[  0  3  0  8  0  1  0  0 ]
[  1  0  0  0  0  0 -5  0 ]
[  9  0  0  0  0  0 15  0 ]
MATRIX

ok( $matrix eq $matrix, 'eq overload works' );
ok( $matrix == $matrix, '== overload works' );
ok( $matrix != 2*$matrix, '!= overload works' );
ok( $matrix ne 2*$matrix, 'ne overload works' );
ok( ($matrix*1) == $matrix, '== overload works' );
ok( $matrix == ($matrix*1), '== overload works' );
ok( $matrix == ($matrix**1), '== overload works' );
ok( $matrix**0 == $matrix**0, '== overload works' );
{ no warnings;
eval{ $matrix != 1 };
ok( $@ , '!= dies when matrix compared to scalar' );

eval{ $matrix == 1 };
ok( $@ , '== dies when matrix compared to scalar' );
}
ok( $matrix->inverse == $matrix->inverse, '== overload works' );
ok( $matrix != $matrix->row(1), 'comparing square matrix to row vector works');
