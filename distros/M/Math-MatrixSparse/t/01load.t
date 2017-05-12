use lib qw(./blib/lib ../blib/lib);

use strict;
use Test;

BEGIN { $| = 1; print "1..5\n"; }
use Math::MatrixSparse;
my $loaded = 1;
END {print "not ok 1\n" unless $loaded;}
print "ok 1\n";

my $MW = Math::MatrixSparse->newmatrixmarket("t/ibm32.mtx");
my $mmread = 1;
print "ok 2\n";
END {print "not ok 2\n" unless $mmread;}

my $HB = Math::MatrixSparse->newharwellboeing("t/bcsstk06.rsa");
my $hbread = 1;
print "ok 3\n";
END {print "not ok 3\n" unless $hbread;}


my $mspec = <<MSPEC;
1 1 1
1 2 0
1 3 -1
10 1 3
19999 0 50
MSPEC
    1;

my $M = Math::MatrixSparse->newfromstring($mspec);
my $nfstr = 1;
print "ok 4\n";
END {print "not ok 4\n" unless $nfstr;}

my $Id = Math::MatrixSparse->newidentity(40,50);
my $idsuc=1;
print "ok 5\n";
END {print "not ok 5\n" unless $idsuc;}

