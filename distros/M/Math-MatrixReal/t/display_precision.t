use Test::More tests => 3;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;
do 'funcs.pl';

my $matrix  = Math::MatrixReal->new_diag([1,2,3,4]);
$matrix->display_precision(5);

my $correct =  Math::MatrixReal->new_from_string(<<END);
[  1.00000             0.00000             0.00000             0.00000            ]
[  0.00000             2.00000             0.00000             0.00000            ]
[  0.00000             0.00000             3.00000             0.00000            ]
[  0.00000             0.00000             0.00000             4.00000            ]
END
$correct->display_precision(5);

ok( "$matrix" eq "$correct", 'display_precision(n)' );

$matrix->display_precision(0);
$correct = Math::MatrixReal->new_from_string(<<END);
[  1           0           0           0          ]
[  0           2           0           0          ]
[  0           0           3           0          ]
[  0           0           0           4          ]
END
$correct->display_precision(0);
ok( "$matrix" eq "$correct", 'display_precision(0)' );

{
    assert_dies ( sub { Math::MatrixReal->new(5,5)->display_precision(-42) },
                'display_precision dies on negative arg, matey!' 
    );
}
