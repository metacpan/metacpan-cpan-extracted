use Test::Simple tests =>7;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;

my $eye = Math::MatrixReal->new_diag([ 1,1,1] );
my $full = Math::MatrixReal->new_from_string(<<MATRIX);
[ 3 4 1 ]
[ 4 3 5 ]
[ 1 2 3 ]
MATRIX

my $fulleye = Math::MatrixReal->new_from_string(<<MATRIX);
[ 3 4 1 1 0 0 ]
[ 4 3 5 0 1 0 ]
[ 1 2 3 0 0 1 ]
MATRIX

my $eyefull = Math::MatrixReal->new_from_string(<<MATRIX);
[ 1 0 0 3 4 1 ]
[ 0 1 0 4 3 5 ]
[ 0 0 1 1 2 3 ]
MATRIX


my $eps = 1/1000;
my $concat = $eye . $full;
my $concat2= $full. $eye;

ok( ref $concat eq "Math::MatrixReal" , 'Concatenation returns the correct object');

my ($rows,$cols) = $concat->dim(); 
ok( $rows == 3, 'Concatenation preserves number of rows');
ok( $cols == 6, 'Concatenation does the right thing for cols');

my $res = $eyefull - $concat;
my $res2= $fulleye - $concat2;

ok(abs($res) < $eps ,'Left Concatenation of matrices with the same number of rows works' );
ok(abs($res2) < $eps,'Right Concatenation of matrices with the same number of rows works' );

my $a = Math::MatrixReal->new_diag([1, 2]);
my $b = Math::MatrixReal->new_diag([1, 2, 3]);
my $c;

eval { $c = $a . $b };
if ($@){
	ok(1, 'Concatenation of matrices with same number of rows only');
} else {
	ok(0, 'Concatenation of matrices with same number of rows only');
}

$c = Math::MatrixReal->new_from_string(<<MATRIX);
[ 3 4 1 9 ]
[ 4 3 5 9 ]
[ 1 2 3 0 ]
MATRIX
my $d = Math::MatrixReal->new_from_string(<<MATRIX);
[ 77 ]
[ 69 ]
[ 42 ]
MATRIX
my $dc = Math::MatrixReal->new_from_string(<<MATRIX);
[ 77 3 4 1 9 ]
[ 69 4 3 5 9 ]
[ 42 1 2 3 0 ]
MATRIX
$eps = 1e-8;
ok( abs( $dc - ($d.$c) ) < $eps, 'Concatenation of matrices with different number of columns works');


