use Test::More tests => 3;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;

do 'funcs.pl';

### First, some preparation

my $DEBUG2 = 0;
# Set this one if you want the REAL benchmarking to be done!
my $REALBENCH = 0;
my $bigsize = 150; # Size of big matrix for estimation
                   # and REAL tests (be careful: n^3!)
use Benchmark;

### We should use the black magic now...

# Does estimation times for diagonalization
print "Diagonalization estimation...\n" if $DEBUG;
my ($bigdiago_time, $oneday_diago);
{ # Estimates the completion time...
    my $N1 = 10;
    my $N2 = 50;
    my $M1 = Math::MatrixReal->new_random($N1);
    $M1 = $M1 + ~$M1;
    my $bench1 = timeit(1, sub { $M1->sym_diagonalize(); });
    # HACK: We go into the Benchmark objects !!!
    my $t1 = $bench1->[1];
    print "bench1 (".$N1."x".$N1.") = ".timestr($bench1)."\n" if $DEBUG;
    my $M2 = Math::MatrixReal->new_random($N2);
    $M2 = $M2 + ~$M2;
    my $bench2 = timeit(1, sub { $M2->sym_diagonalize(); });
    # HACK: We go into the Benchmark objects !!!
    my $t2 = $bench2->[1];
    print "bench2 (".$N2."x".$N2.")= ".timestr($bench2)."\n" if $DEBUG;
    my $k3 = ($t1 - (($N1*$N1)/($N2*$N2)) * $t2) / ($N1*$N1*$N1 * (1-($N2/$N1)));
    my $k2 = ($t2 - (($N2*$N2*$N2)/($N1*$N1*$N1)) * $t1) / ($N2*$N2 * (1-($N2/$N1)));
    print "t1=$t1 t2=$t2 k3=$k3 k2=$k2\n" if $DEBUG;
    $bigdiago_time = $k3*($bigsize*$bigsize*$bigsize) + $k2*($bigsize*$bigsize);
# Grrr. I am unable to solve k3*N^3 + k2*N^2 = t with pen-and-paper...
# (Should go back to school!) Anyway, let's have the machine do it... :-(
    my $N = 1;
    my $day = 24 * 60 * 60; # 1 day in seconds
    # BTW: Furthermore that's a damn stupid solving...
    while (($k3 * ($N*$N*$N) + $k2 * ($N*$N)) <= $day) { $N++; }
    $oneday_diago = $N - 1;
}
# Output estimations...
printf STDERR "\n * Estimated diagonalization time for "
    .$bigsize."x".$bigsize." matrix: %5.2f s\n", $bigdiago_time;
printf STDERR "   Estimated biggest matrix diagonalisable within 1 day cpu: ".$oneday_diago."x".$oneday_diago."\n";

#
# Does estimation times for eigenvalues
#
print "Eigenvalues computation estimation...\n" if $DEBUG;
my ($bigeigen_time, $oneday_eigen);
{ # Estimates the completion time...
    my $N1 = 15;
    my $N2 = 65;
    my $M1 = Math::MatrixReal->new_random($N1);
    $M1 = $M1 + ~$M1;
    my $bench1 = timeit(1, sub { $M1->sym_eigenvalues(); });
    # HACK: We go into the Benchmark objects !!!
    my $t1 = $bench1->[1];
    print "bench1 (".$N1."x".$N1.") = ".timestr($bench1)."\n" if $DEBUG;
    my $M2 = Math::MatrixReal->new_random($N2);
    $M2 = $M2 + ~$M2;
    my $bench2 = timeit(1, sub { $M2->sym_eigenvalues(); });
    # HACK: We go into the Benchmark objects !!!
    my $t2 = $bench2->[1];
    print "bench2 (".$N2."x".$N2.")= ".timestr($bench2)."\n" if $DEBUG;
    my $k3 = ($t1 - (($N1*$N1)/($N2*$N2)) * $t2) / ($N1*$N1*$N1 * (1-($N2/$N1)));
    my $k2 = ($t2 - (($N2*$N2*$N2)/($N1*$N1*$N1)) * $t1) / ($N2*$N2 * (1-($N2/$N1)));
    print "t1=$t1 t2=$t2 k3=$k3 k2=$k2\n" if $DEBUG;
    $bigeigen_time = $k3*($bigsize*$bigsize*$bigsize) + $k2*($bigsize*$bigsize);
# Grrr. I am unable to solve k3*N^3 + k2*N^2 = t with pen-and-paper...
# (Should go back to school!) Anyway, let's have the machine do it... :-(
    my $N = 1;
    my $day = 24 * 60 * 60; # 1 day in seconds
    # BTW: Furthermore that's a damn stupid solving...
    while (($k3 * ($N*$N*$N) + $k2 * ($N*$N)) <= $day) { $N++; }
    $oneday_eigen = $N - 1;
}
# Output estimations...
printf STDERR " * Estimated eigenvalues-only computation time for "
    .$bigsize."x".$bigsize." matrix: %5.2f s\n", $bigeigen_time;
printf STDERR "   Estimated biggest matrix manageable within 1 day cpu: ".$oneday_eigen."x".$oneday_eigen."\n";

# Tired eh?
print STDERR " Btw, do you want to crunch such one now?  (no, just kidding...;-)\n";

ok(1 == 1, 'benchmark estimates');

#########################################
# REAL computation test for big matrix. #
#########################################
# Test real-world diagonalization
if ($REALBENCH)
{
    # Creates a random matrix
    my $big = Math::MatrixReal->new_random($bigsize);
    # test on random big matrix
    print "Matrix ".$bigsize."x$bigsize for eigenvalues & eigenvectors computation:\n" if $DEBUG;
    #
    # Benchmark eigenvalues & eigenvectors computation
    #
    $big = $big + ~$big;

    print "Direct diagonalization...\n" if $DEBUG;
    my ($Lbig_2, $Vbig_2);
    my $t = timeit(1, sub { ($Lbig_2, $Vbig_2) = $big->sym_diagonalize(); });
    print "Timing of ".$bigsize."x".$bigsize." direct diagonalization:\n  ".timestr($t)."\n";
    print "eigenvalues L:\n$Lbig_2 eigenvectors:\n$Vbig_2" if $DEBUG2;

    # We check the results anyway (just in case...)
    ok_eigenvectors($big, $Lbig_2, $Vbig_2, 'eigenvalues of large matrix are correct');

    #
    # Now test the eigenvalues only computations...
    #
    print "Recomputing: Eigenvalues only.\n ".$bigsize."x".$bigsize."\n" if $DEBUG;
    my $altLbig_2;
    my $tt = timeit(1, sub { $altLbig_2 = $big->sym_eigenvalues(); });
    print "Timing of ".$bigsize."x".$bigsize." direct eigenvalues computation:\n  ".timestr($tt)."\n";
    
    # We check the results anyway (just in case...)
    ok_matrix($altLbig_2, $Lbig_2, 'eigenvalues of large matrix are correct');
}
else
{
    # Tests are not really done, but we don't bother...
    # There are other test programs for checking accuracy... not time.
    ok(1 == 1,'benchmarch fake test' );
    ok(1 == 1,'benchmarch fake test' );
}



