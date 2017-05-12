use Test::More tests => 2;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;
do 'funcs.pl';

my ($a,$b);
$a = Math::MatrixReal->new_from_cols([[ 1.41E-05, 6.82E-06, 3.18E-06 ],[1,3,4]]);
like( $a->as_matlab,qr/\[.*;.*;.*\]/s, 'matlab output looks right');

$b = Math::MatrixReal->new_from_cols([[ 1.234, 5.678, 9.1011],[1,2,3]] );
my $s = $b->as_matlab( ( format => "%5.8s", name => "A" ) );
like( $s, qr/A = /, 'name argument respected');
