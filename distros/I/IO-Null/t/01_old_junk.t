
# Time-stamp: "2004-12-29 22:23:48 AST"

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use IO::Null;
$loaded = 1;
print "ok 1\n";
my $x = IO::Null->new;
$^W = 0;
$x->print('not ok 2'); # should go nowhere and do nothing
print "ok 2\n";
$x->close(); # no-op
print "ok 3\n";

