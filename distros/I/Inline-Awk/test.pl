BEGIN { $| = 1; print "1..1\n"; }

END {print "not ok 1\n" unless $loaded;}

use Awk;

$loaded = 1;

print "ok 1\n";

# No tests here yet but there is a full regression test at:
# http://homepage.eircom.net/~jmcnamara/perl/iawk_regtest_0.03.tar.gz
