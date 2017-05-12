use lib qw(./blib/lib ../blib/lib);

use strict;
use Test;

BEGIN { $| = 1; print "1..12\n"; }
use Math::MatrixSparse;
my $loaded = 1;
END {print "not ok 1\n" unless $loaded;}
print "ok 1\n";


my $aspec=<<ASPEC;
    1 1 1
    1 2 1
    1 3 1
    1 10 1
    2 1 1
    10 1 1
ASPEC
    1;

my $bspec=<<BSPEC;
    1 1 2
    1 2 2
    1 3 2
    1 10 2
    2 1 2
    10 1 2
BSPEC
    1;

my $cspec=<<CSPEC;
    1 1 3
    1 2 3
    1 3 3
    1 10 3
    2 1 3
    10 1 3
CSPEC
    1;

my $pspec=<<PSPEC;
1 1 6
1 2 2
1 3 2
1 10 2
2 1 2
2 2 2
2 3 2
2 10 2
10 1 2
10 2 2
10 3 2
10 10 2
PSPEC
    1;

my $A=Math::MatrixSparse->newfromstring($aspec);
my $B=Math::MatrixSparse->newfromstring($bspec);
my $C=Math::MatrixSparse->newfromstring($cspec);
my $P=Math::MatrixSparse->newfromstring($pspec);

my $D = $A+$B;
my $diff = $D->equals($C);
print "ok 2\n" if $diff;
END {print "not ok 2\n" unless $diff};

my $sm = $B->equals(2*$A);
print "ok 3\n" if $sm;
END {print "not ok 3\n" unless $sm};

my $mm = $P->equals($A*$B);
print "ok 4\n" if $sm;
END {print "not ok 4\n" unless $sm};


 $D = Math::MatrixSparse->newrandom(100,100,300,1);
my $E = Math::MatrixSparse->newrandom(100,100,300,1);
my $F= $D*$E;
my $G = $E*$D;

print "ok 5\n" if defined $F;
print "ok 6\n" if defined $G;

END {print "not ok 5\n" unless defined $F};
END {print "not ok 6\n" unless defined $G};

my $Dn = $D**3;
print "ok 7\n" if defined $Dn;
END {print "not ok 7\n" unless defined $Dn};

my $Dbig = $D->largeexponentiate(8);
print "ok 8\n" if defined $Dbig;
END {print "not ok 8\n" unless defined $Dbig};


my $Dno = $Dn->equals($D->largeexponentiate(3));
print "ok 9\n" if $Dno;
END {print "not ok 9\n" unless  $Dno;};



my $I10 = Math::MatrixSparse->newidentity(100);
my $EI = $E*$I10;
my $IE = $I10*$E;
my $eei = $E->equals($EI);
print "ok 10\n" if $Dno;
END {print "not ok 10\n" unless  $eei;};


my $eie = $E->equals($IE);
print "ok 11\n" if $Dno;
END {print "not ok 11\n" unless  $eie;};


my $itr = $I10->trace() == 100;
print "ok 12\n" if $itr;
END {print "not ok 12\n" unless  $itr;};

