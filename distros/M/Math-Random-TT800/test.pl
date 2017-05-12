# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}
use Math::Random::TT800;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

#
#  Testing with default seed
#
$tt = new Math::Random::TT800;

(sprintf("%u",$tt->next_int()) eq "3169973338") or print "not ";
print "ok 2\n";

(abs($tt->next() - 0.63445952502881) < 0.0000001 ) or print "not ";
print "ok 3\n";

for (1..100) { $tt->next_int(); }

(sprintf("%u",$tt->next_int()) eq "3491672134") or print "not ";
print "ok 4\n";

(abs($tt->next() - 0.25527860719135) < 0.0000001 ) or print "not ";
print "ok 5\n";

#
#  Testing with custom seed
#
$tt = new Math::Random::TT800 42,1,8,1,4,131,91231,9173123;

(sprintf("%u",$tt->next_int()) eq "42010539") or print "not ";
print "ok 6\n";

(abs($tt->next() - 2.3283064370808e-10) < 0.0000001 ) or print "not ";
print "ok 7\n";

for (1..100) { $tt->next_int(); }

(sprintf("%u",$tt->next_int()) eq "2788880872") or print "not ";
print "ok 8\n";

(abs($tt->next() - 0.625562964851401) < 0.0000001 ) or print "not ";
print "ok 9\n";

