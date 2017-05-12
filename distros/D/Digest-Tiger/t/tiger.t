# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
use Digest::Tiger;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my $tc = 2;

if (Digest::Tiger::hexhash('') eq '3293AC630C13F0245F92BBB1766E16167A4E58492DDE73F3') {
  print 'ok ' . $tc++ . "\n";
}
else {
  print 'not ok ' . $tc++ . "\n";
}

if (Digest::Tiger::hexhash('abc') eq '2AAB1484E8C158F2BFB8C5FF41B57A525129131C957B5F93') {
  print 'ok ' . $tc++ . "\n";
}
else {
  print 'not ok ' . $tc++ . "\n";
}

if (Digest::Tiger::hexhash('Tiger') eq 'DD00230799F5009FEC6DEBC838BB6A27DF2B9D6F110C7937') {
  print 'ok ' . $tc++ . "\n";
}
else {
  print 'not ok ' . $tc++ . "\n";
}

if (Digest::Tiger::hexhash('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-') eq 'F71C8583902AFB879EDFE610F82C0D4786A3A534504486B5') {
  print 'ok ' . $tc++ . "\n";
}
else {
  print 'not ok ' . $tc++ . "\n";
}

if (Digest::Tiger::hexhash('Tiger - A Fast New Hash Function, by Ross Anderson and Eli Biham') eq '8A866829040A410C729AD23F5ADA711603B3CDD357E4C15E') {
  print 'ok ' . $tc++ . "\n";
}
else {
  print 'not ok ' . $tc++ . "\n";
}

