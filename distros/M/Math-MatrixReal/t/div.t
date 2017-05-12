use Test::Simple tests => 7;
use Math::MatrixReal;

my $div_mat_by_scalar=Math::MatrixReal->new_from_string(<<EOF);
[  1.500000000000E+00  2.420000000000E+00  5.000000000000E-01 ]
[  2.000000000000E+00  1.500000000000E+00  2.500000000000E+00 ]
[  5.000000000000E-01  1.000000000000E+00  1.500000000000E+00 ]
EOF


my $oneoverb = Math::MatrixReal->new_from_string(<<EOL);
[  4.300000000000E-01  0.000000000000E+00  0.000000000000E+00 ]
[  0.000000000000E+00  1.340000000000E+01  0.000000000000E+00 ]
[  0.000000000000E+00  0.000000000000E+00  1.110500000000E+03 ]
EOL

my $matdiv = Math::MatrixReal->new_from_string(<<EOF);
[  5.882352941176E+00  1.152380952381E+01  6.666666666667E+00 ]
[  7.843137254902E+00  7.142857142857E+00  3.333333333333E+01 ]
[  1.960784313725E+00  4.761904761905E+00  2.000000000000E+01 ]
EOF

my $a = Math::MatrixReal->new_diag([ 0.51, 0.420, 0.15] );
my $b = Math::MatrixReal->new_diag([ 0.43, 13.4, 1110.5] );
my $c = Math::MatrixReal->new_diag([ 2.3, 554.4, 30.5] );
my $eye = Math::MatrixReal->new_diag([ 1,1,1] );


my $full = Math::MatrixReal->new_from_string(<<MATRIX);
[ 3 4.84 1 ]
[ 4 3 5 ]
[ 1 2 3 ]
MATRIX

my $eps = 10^(-6);
my $half = $full / 2;
my $res = $half - $full/2;

ok(abs($res) < $eps,'Dividing a matrix by a scalar works' );

$res = (1/$b - $oneoverb);
ok( abs($res)  < $eps , '1/A returns A ** -1');

my $z =  $full / $a;
$res = $matdiv - $z;
ok(abs($res) < $eps, 'Matrix Division works');
ok( abs( $eye - $full/$full) < $eps, 'A/A returns identity');
ok( abs($eye) - 1 == 0, 'Identity is of unit norm');

my $stuff = Math::MatrixReal->new_from_string(<<MATRIX);
[ 3 4.84 1 0 ]
[ 4 3 5 1 ]
[ 1 2 3 9 ]
MATRIX

eval { $res =  1/$stuff; };
if ($@){
	ok( 1, '1/A only works for square matrix') ;
} else  {
	ok(0,' 1/A only works for square matrix');
}

my $colvec =  Math::MatrixReal->new_from_string(<<MATRIX);
[ 1 ]
[ 2 ]
[ 3 ]
MATRIX

#TODO:
#solve $full * x = $colvec 
#$res = $full / $colvec;
#print $res;

ok(1);
