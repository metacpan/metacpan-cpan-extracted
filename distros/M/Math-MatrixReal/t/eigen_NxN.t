use Test::More tests => 15;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;

do 'funcs.pl';

my $DEBUG2 = 0;
my $bigsize = 30; # Size of big matrix tests (be careful: n^3!)

# test on random bigger matrix
print "Matrix ".$bigsize."x$bigsize for eigenvalues & eigenvectors computation:\n" if $DEBUG;
# Creates a random matrix
my $big = Math::MatrixReal->new_random($bigsize, { symmetric => 1 });

# Tests eigenvalues & eigenvectors computation

print "Householder reduction...\n" if $DEBUG;
my ($Tbig, $Qbig) = $big->householder();
print "Is Qbig orthogonal?\n" if $DEBUG;
ok_matrix_orthogonal( $Qbig);
ok_matrix( $big, $Qbig * $Tbig * ~$Qbig);
print "Diagonalization of tridiagonal...\n" if $DEBUG;
my ($Lbig, $Vbig) = $Tbig->tri_diagonalize($Qbig);
ok_eigenvectors( $big, $Lbig, $Vbig);
ok_matrix_orthogonal( $Vbig);

print "Direct diagonalization...\n" if $DEBUG;
my ($Lbig_2, $Vbig_2) = $big->sym_diagonalize();
print "eigenvalues L:\n$Lbig_2 eigenvectors:\n$Vbig_2" if $DEBUG2;
ok_eigenvectors($big, $Lbig_2, $Vbig_2);
ok_matrix_orthogonal( $Vbig_2);
# Double check the equality
ok_matrix( $Lbig_2, $Lbig);
ok_matrix( $Vbig_2, $Vbig);

#
# Now test the eigenvalues only computations...
#
print "Recomputing: Eigenvalues only.\n ".$bigsize."x".$bigsize."\n" if $DEBUG;
my $altTbig = $big->householder_tridiagonal();
ok_matrix( $altTbig, $Tbig);
my $altLbig = $altTbig->tri_eigenvalues();
ok_matrix( $altLbig, $Lbig);
my $altLbig_2 = $big->sym_eigenvalues();
ok_matrix( $altLbig_2, $Lbig_2);

##############
#### lower tri
my $eigen = Math::MatrixReal->new_from_string(<<MAT);
[  0.000000000000E+00 ]
[  3.000000000000E+00 ]
[  4.000000000000E+00 ]
[  5.000000000000E+00 ]
[  1.000000000000E+00 ]
MAT
$matrix = Math::MatrixReal->new_from_string(<<"MATRIX");
[ 0 0 0 0 0 ]
[ 0 3 0 0 0 ]
[ 0 0 4 0 0 ]
[ 1 0 0 5 0 ]
[ 1 1 1 1 1 ]
MATRIX
ok_matrix( $eigen, $matrix->eigenvalues );

$matrix = $eigen->new_from_rows ( [[1,0,0],[0,2,0],[0,0,3]] );
$eigen = $eigen->new_from_string(<<MAT);
[ 1 ]
[ 2 ]
[ 3 ]
MAT
ok_matrix($eigen, $matrix->eigenvalues );

####################
## upper tri
$matrix = Math::MatrixReal->new_from_string(<<"MATRIX");
[ 1 0 0 0 1 ]
[ 0 2 0 0 2 ]
[ 0 0 3 0 0 ]
[ 0 0 0 4 0 ]
[ 0 0 0 0 5 ]
MATRIX
$eigen = Math::MatrixReal->new_from_string(<<MAT);
[ 1 ]
[ 2 ]
[ 3 ]
[ 4 ]
[ 5 ]
MAT

ok_matrix( $eigen, $matrix->eigenvalues );

######################
#### diag
$matrix = $matrix->new_diag ( [ 10, 20, 30 ] );
$eigen =  $matrix->new_from_cols ( [ [ 10, 20, 30 ] ] );
ok_matrix( $eigen, $matrix->eigenvalues );


