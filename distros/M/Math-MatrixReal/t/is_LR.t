use Test::More tests => 9;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;

do 'funcs.pl';

my $matrix = Math::MatrixReal->new_from_string(<<MATRIX);
[ 1 2 3 ]
[ 2 3 4 ]
[ 4 5 6 ]
MATRIX

my $LR = $matrix->decompose_LR;
ok($LR->is_LR);
my $a = $LR;
my $b = $LR;
$a+=$matrix;
ok( ! $a->is_LR);
ok( ! ($LR**2)->is_LR );
ok( ! (~$LR)->is_LR );
ok( ! $LR->inverse->is_LR );
ok( ! $LR->cofactor->is_LR );
ok( ! $LR->adjoint->is_LR );
ok( ! $LR->minor(1,1)->is_LR );
ok( $b->is_LR );
