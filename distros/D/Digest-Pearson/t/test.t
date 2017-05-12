BEGIN { $| = 1; print "1..3\n"; }
END   { print "not ok 1\n" unless $loaded; }

use Digest::Pearson;

$loaded = 1;

print "ok 1\n";

print "not " unless Digest::Pearson::pearson("abc123") == 225;
print "ok 2\n";

print "not " unless Digest::Pearson::pearson("abc123"x256) == 40;
print "ok 3\n";
