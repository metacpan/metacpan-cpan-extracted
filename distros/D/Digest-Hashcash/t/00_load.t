BEGIN { $| = 1; print "1..174\n"; }
END {print "not ok 1\n" unless $loaded;}
use Digest::Hashcash;
$loaded = 1;
print "ok 1\n";

$c = new Digest::Hashcash
   size => 16,
   uid => "pcg\@goof.com";

$token = $c->hash ("proprietary\@is.evil");

print $token =~ /pcg\@goof.com/ ? "ok 2\n" : "not ok 2\n";
print $token =~ /proprietary\@is.evil/ ? "ok 3\n" : "not ok 3\n";
print $c->verify ($token) ? "ok 4\n" : "not ok 4\n";

print $c->resource ($token) eq "proprietary\@is.evil" ? "ok 5\n" : "not ok 5\n";

$t = $c->timestamp ($token);

print $t <= time ? "ok 6\n" : "not ok 6\n";
print $t > time - 3600 ? "ok 7\n" : "not ok 7\n";

$m = Digest::Hashcash::estimate_time 30;
print $m > 2 ? "ok 8\n" : "not ok 8\n";
$m = Digest::Hashcash::estimate_size $m, 29;
print $m == 30 ? "ok 9\n" : "not ok 9\n";

print $c->verify ("0:020814:foo:4333957e84db47f6") == 33 ? "ok 10\n" : "not ok 10\n";
print $c->verify ("0:030907:taz:663c4027c724de49") == 16 ? "ok 11\n" : "not ok 11\n";
print $c->verify ("0:030907:taz:3e0374e8cb3d95a7") == 20 ? "ok 12\n" : "not ok 12\n";
print $c->verify ("0:030907:tazhashcashhashcashhashcashhashcashhashcashhashcashhashcashhashcashhashcashhashcashhashcashhashcashhashcash:89e748cf94ef1871") == 20 ? "ok 13\n" : "not ok 13\n";

$c = new Digest::Hashcash size => 50;
$t = 14;

for (0 .. 160) {
   my $token = $c->hash ("x" x $_, extrarand => $_ / 4, size => 10);
   $c->verify ($token, size => 10) or print "not ";
   print "ok $t\n";
   $t++;
}
