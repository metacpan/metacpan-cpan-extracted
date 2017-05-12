# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Socket;
use Mail::SpamCannibal::ScriptSupport qw(
	SerialEntry
	TarpitEntry
	DNSBL_Entry
);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

## test 2	127.0.0.0
print "got: $_, exp: 127.0.0.0\nnot "
	unless ($_ = inet_ntoa(SerialEntry())) eq '127.0.0.0';
&ok;

## test 3	127.0.0.2
print "got: $_, exp: 127.0.0.2\nnot "
	unless ($_ = inet_ntoa(TarpitEntry())) eq '127.0.0.2';
&ok;

## test 4	127.0.0.3
print "got: $_, exp: 127.0.0.3\nnot "
	unless ($_ = inet_ntoa(DNSBL_Entry())) eq '127.0.0.3';
&ok;

