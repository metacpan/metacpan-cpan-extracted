# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use File::Cat;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):


open DATA, ">testdata" or do {
	print "not ok 2\n";
	goto NEXT_TEST;
};
print DATA "1\n2\n3\n4\n";
close DATA;


TEST_2:

open TEST, ">File-Cat-test" or do {
	print "not ok 2\n";
	goto TEST_3;
};

cat 'testdata', \*TEST or do {
	print "not ok 2\n";
	goto TEST_3;     # I can't tell you how much I'm enjoying this...
};

close TEST;
open TEST, "File-Cat-test" or do {
	print "not ok 2\n";
	goto TEST_3;
};

if (scalar(<TEST>) =~ /^1/) {
	print "ok 2\n";

} else {
	print "not ok 2\n";
}

close TEST;


TEST_3:

open TEST, ">File-Cat-test" or do {
	print "not ok 3\n";
};

cattail 'testdata', \*TEST or do {
	print "not ok 3\n";
};

close TEST;
open TEST, "File-Cat-test" or do {
	print "not ok 3\n";
};

if (scalar(<TEST>) =~ /^4/) {
	print "ok 3\n";

} else {
	print "not ok 3\n";
}

close TEST;


END {
	unlink "File-Cat-test";
	unlink "testdata";
}
