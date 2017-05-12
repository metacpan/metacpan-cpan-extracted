use lib qw(./blib/lib ../blib/lib);

use strict;
use Test;

BEGIN { $| = 1; print "1..6\n"; }
use Math::MatrixSparse;
my $loaded = 1;
END {print "not ok 1\n" unless $loaded;}
print "ok 1\n";


my $MW = Math::MatrixSparse->newmatrixmarket("t/ibm32.mtx");
$MW->_nonlowerpart();
my $mmread = 1;
print "ok 2\n";
END {print "not ok 2\n" unless $mmread;}
print "not " unless $MW->is_uppertriangular();
print "ok 3\n";

my $constspec=<<CONSPEC;
1 1 1
2 1 2
3 1 3
4 1 4
5 1 5
8 1 6
9 1 7
12 1 8
20 1 9
32 1 0
CONSPEC
    1;
my $constant = Math::MatrixSparse->newfromstring($constspec);
my $guess = Math::MatrixSparse->newrandom(32,1);
my $solve = $MW->jacobi($constant,$guess,1e-5,100);
END {print "not ok 4\n" unless defined $solve;}
exit unless defined $solve;
print "ok 4\n";

my $gssolve = $MW->gaussseidel($constant,$guess,1e-5,100);
END {print "not ok 5\n" unless defined $gssolve;}
exit unless defined $gssolve;
print "ok 5\n";

my $sorsolve = $MW->SOR($constant,$guess,.9,1e-5,100);
END {print "not ok 6\n" unless defined $sorsolve;}
exit unless defined $sorsolve;
print "ok 6\n";

