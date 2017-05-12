use lib qw(./blib/lib ../blib/lib);

use strict;
use Test;
BEGIN { $| = 1; print "1..1\n"; }
use Math::MatrixSparse;
my $loaded = 1;
END {print "not ok 1\n" unless $loaded;}
print "ok 1\n";


