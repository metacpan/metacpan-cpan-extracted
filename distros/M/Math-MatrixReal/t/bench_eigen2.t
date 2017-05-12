use Test::More tests => 3;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;
do 'funcs.pl';

my $DEBUG2 = 0;
# Set this one if you want the REAL benchmarking to be done!
my $REALBENCH = 1;
my $bigsize = 25; # Size of big matrix REAL tests (be careful: n^3!)
my $howmany = 30;

use Benchmark;

if ($REALBENCH)
{
    print "Matrix ".$bigsize."x$bigsize for eigenvalues & eigenvectors computation:\n" if $DEBUG;
    my $big = Math::MatrixReal->new_random($bigsize, { symmetric => 1 } );

    # Benchmark eigenvalues & eigenvectors computation
    print "Householder reduction...\n" if $DEBUG;
    my ($Tbig, $Qbig);
    my $t = timeit($howmany, sub { ($Tbig, $Qbig) = $big->householder(); });
    print "Timing of ".$bigsize."x".$bigsize." Householder transformation:\n  ".timestr($t)."\n" if $DEBUG;
    print "Is Qbig orthogonal?\n" if $DEBUG;
    print "Diagonalization of tridiagonal...\n" if $DEBUG;
    my ($Lbig, $Vbig);
    my $t2 = timeit($howmany, sub { ($Lbig, $Vbig) = $Tbig->tri_diagonalize($Qbig); });
    print "Timing of ".$bigsize."x".$bigsize." QL-implicit diagonalization:\n  ".timestr($t2)."\n" if $DEBUG;

    # We check the results anyway (just in case...:-)
    ok_eigenvectors( $big, $Lbig, $Vbig);

    # Now test the eigenvalues only computations...
    print "Recomputing: Eigenvalues only.\n ".$bigsize."x".$bigsize."\n" if $DEBUG;
    my $altTbig;
    my $t3 = timeit($howmany, sub { $altTbig = $big->householder_tridiagonal(); });
    print "Timing of ".$bigsize."x".$bigsize." Householder transformation (tridiag. only):\n  ".timestr($t3)."\n" if $DEBUG;
    my $altLbig;
    my $t4 = timeit($howmany, sub { $altLbig = $altTbig->tri_eigenvalues(); });
    print "Timing of ".$bigsize."x".$bigsize." QL-implicit eigenvalues computation:\n  ".timestr($t4)."\n" if $DEBUG;

    # We check the results anyway (just in case...:-)
    ok_matrix( $altTbig, $Tbig, "$bigsize x $bigsize householder triadiag");
    ok_matrix( $altLbig, $Lbig, "$bigsize x $bigsize QL-implicit eigenvalues");
}
else
{
	SKIP: { skip "because", 3; };
}


