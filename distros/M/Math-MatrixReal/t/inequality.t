use Test::More tests => 10;
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

ok( $matrix <= $matrix, '<= overload works' );
ok( $matrix >= $matrix, '>= overload works' );
ok( $matrix le $matrix, 'le overload works' );
ok( $matrix ge $matrix, 'ge overload works' );


ok( $matrix->row(2) < $matrix->row(1), '< overloading to norm works for row vector');
ok( $matrix->row(3) > $matrix->row(4), '> overloading to norm works for row vector');

ok( $matrix->row(2) lt $matrix->row(1), 'lt overloading to norm works for row vector');
ok( $matrix->row(3) gt $matrix->row(4), 'gt overloading to norm works for row vector');

ok( $matrix->col(2) > $matrix->col(1), '< overloading to norm works for col vector');
ok( $matrix->col(3) < $matrix->col(4), '> overloading to norm works for col vector');

