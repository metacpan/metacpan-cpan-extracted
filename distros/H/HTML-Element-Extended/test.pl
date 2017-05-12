# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use HTML::ElementSuper;
$loaded = 1;
print "HTML::ElementSuper ok\n";

use HTML::ElementGlob;
$loaded = 1;
print "HTML::ElementGlob ok\n";

use HTML::ElementRaw;
$loaded = 1;
print "HTML::ElementRaw ok\n";

use HTML::ElementTable;
$loaded = 1;
print "HTML::ElementTable ok\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

