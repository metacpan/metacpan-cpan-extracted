use Test::More tests => 8;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;

do 'funcs.pl';

###############################
## 2x2 inverse
$matrix = Math::MatrixReal->new_from_string(<<"MATRIX");
[  3.0  7.0  ]
[  2.0  5.0  ]
MATRIX
$inverse = Math::MatrixReal->new_from_string(<<"MATRIX");
[  5.0 -7.0 ]
[ -2.0  3.0 ]
MATRIX
my $b = Math::MatrixReal->new_random(20);
my $c = Math::MatrixReal->new_random(20);
my $randint = int(rand(50));

ok( similar( $matrix->trace() , 8), 'trace is correct' );
ok( similar($inverse->trace() , 8), 'trace is correct' );

$matrix->one();
ok( similar( $matrix->trace, 2), 'trace is correct' );

$matrix->zero();
ok( similar( $matrix->trace, 0), 'trace of zero matrix is 0' );

ok( similar( $b->trace, (~$b)->trace) , 'trace is conserved with respect to transpose' );
ok( similar( $randint*$b->trace, ($randint*$b)->trace) , 'trace is conserved with respect to scalar multiplication' );
ok( similar( ($c*$b)->trace, ($b*$c)->trace) , 'trace is conserved with respect to matrix multiplication' );
ok( similar( $c->trace + $b->trace, ($c + $b)->trace) , 'trace is conserved with respect to addition' );


