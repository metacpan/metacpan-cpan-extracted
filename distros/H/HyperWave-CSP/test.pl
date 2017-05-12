# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}
use HyperWave::CSP;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $HyperWave = HyperWave::CSP->new("xanadu.net");
if ($HyperWave) {
   print "ok 2\n" 
} else {
   print "not ok 2\n" 
}

if ($document = $HyperWave->get_objnum_by_name("xanadu/resources.html")) {
   print "ok 3\n";
} else {
   print "not ok 3\n";
}

if ($document2 = $HyperWave->get_objnum_by_name("xanadu")) {
   print "ok 3\n";
} else {
   print "not ok 3\n";
}

if ($HyperWave->get_attributes($document)) {
   print "ok 4\n";
} else {
   print "not ok 4\n";
}

if ($HyperWave->get_anchors($document)) {
   print "ok 5\n";
} else {
   print "not ok 5\n";
}

if ($HyperWave->get_parents($document)) {
   print "ok 6\n";
} else {
   print "not ok 6\n";
}

if ($HyperWave->get_children($document2)) {
   print "ok 7\n";
} else {
   print "not ok 7\n";
}

if ($HyperWave->get_anchors($document)) {
   print "ok 8\n";
} else {
   print "not ok 8\n";
}

if ($HyperWave->get_text($document)) {
   print "ok 9\n";
} else {
   print "not ok 9\n";
}

if ($HyperWave->get_html($document)) {
   print "ok 10\n";
} else {
   print "not ok 10\n";
}

exit 0;
#
# End.
#
