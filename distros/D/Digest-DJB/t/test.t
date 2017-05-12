BEGIN { $| = 1; print "1..2\n"; }
END   { print "not ok 1\n" unless $loaded; }

use Digest::DJB;

$loaded = 1;

print "ok 1\n";

print "not " unless sprintf("%u", Digest::DJB::djb("abc123")) eq 4048022465;
print "ok 2\n";
