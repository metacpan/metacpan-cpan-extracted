use lib qw(./blib/lib ../blib/lib);

use strict;
use Test;

BEGIN { $| = 1; print "1..3\n"; }
use Math::MatrixSparse;
my $loaded = 1;
END {print "not ok 1\n" unless $loaded;}
print "ok 1\n";

my $A = new Math::MatrixSparse;

for my $n (1..100) {
    $A->assign(int(100000*rand),int(100000*rand),rand);
}
my $succ = 1;
END {print "not ok 2\n" unless $succ;}
print "ok 2\n" if $succ;

for my $n (1..100) {
    $A->element(int(100000*rand),int(100000*rand));
}
$succ = 1;
END {print "not ok 3\n" unless $succ;}
print "ok 3\n" if $succ;

