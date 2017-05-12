# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
use Mail::TieFolder;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use lib "t/";

print "ok 2\n" if Mail::TieFolder::supported("dummy");
print "ok 3\n" unless Mail::TieFolder::supported("badxxx");
print "ok 4\n" unless Mail::TieFolder::supported("baddummy");

my @supported = Mail::TieFolder::supported();
print "ok 5\n" if grep /^baddummy$/, @supported;
print "ok 6\n" if grep /^dummy$/, @supported;

