# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
use Lingua::ZH::HanConvert qw(trad simple);
use utf8;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use vars qw($testno);
$testno = 2;

sub test_eq {
    if(exists $ENV{TEST_VERBOSE} and $ENV{TEST_VERBOSE}) {
	print qq(testing whether "$_[0]" eq "$_[1]"\n);
    }
    print ((($_[0] eq $_[1]) ? "ok " : "not ok ") , $testno++, "\n");
}

# 1-1 test
test_eq( simple("萬與專個"), "万与专个" );

# 1-many test
test_eq( trad  ("万与专个"), "[万萬][与與]專個");

# custom brackets test
test_eq( trad  ("万与丑专个", "<", ">"), "<万萬><与與><丑醜>專個");

# non-chinese tests
test_eq( simple("hello"), "hello" );
test_eq( trad("hello"),   "hello" );

