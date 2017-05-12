use Test::More tests => 2;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;

do 'funcs.pl';

my $a = Math::MatrixReal->new_from_rows([ [1, 2], [-2, 1] ] );
my $b = Math::MatrixReal->new_from_rows([ [1, 2], [3, 1] ] );

ok( $a->is_normal  , 'is_normal');
ok( !$b->is_normal , 'is_normal');

