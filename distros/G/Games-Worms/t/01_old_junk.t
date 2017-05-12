BEGIN { $| = 1; print "1..1\n"; }
END {print "BAD! 1\n" unless $loaded;}
use Games::Worms;
$loaded = 1;
print "ok 1\n";

