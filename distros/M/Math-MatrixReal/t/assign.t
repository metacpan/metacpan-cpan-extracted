use Test::Simple tests => 5;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;

do 'funcs.pl';

$matrix = Math::MatrixReal->new_from_string(<<MATRIX);
[  1 0 -1 0  3 ]
[ -1 0  1 1 -3 ]
[  2 0 -2 2  0 ]
MATRIX

$matrix2 = Math::MatrixReal->new_from_string(<<MATRIX);
[  1 0 -1 0  3 ]
[ -1 0  1 1 -3 ]
[  1 1  1 1  1 ]
MATRIX

{
    my $row = $matrix->new(1,5);
    $row = $row->each(sub{(shift)+1});
    my $result = $matrix->assign_row(3,$row);
    ok( ref $result eq 'Math::MatrixReal', 'assign_row returns a the correct object');
    ok( abs($matrix-$matrix2) < 1e-8, 'assign_row seems to work' );
}

{
    my $a = Math::MatrixReal->new_from_string(<<MATRIX);
[ 1 3 ]
MATRIX

    assert_dies( sub { $matrix->assign_row(3, $a) },
	             q{assign_row fails when number of cols don't match}
    );
}

{
    assert_dies( sub { $matrix->assign_row($a) }, 
	             'assign_row fails when not enough args');
}
{
    assert_dies( sub { $matrix->assign_row($a,3) },
	             'assign_row fails when args in wrong order' );
}
