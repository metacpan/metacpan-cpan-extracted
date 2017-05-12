# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Socket;
use Mail::SpamCannibal::ScriptSupport qw(
	valid127
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

#	input		expect
my %testIP = ( qw(
	1.2.3.4		127.0.0.3
	127.0.0.2	127.0.0.3
	127.0.0.3	127.0.0.3
	127.0.0.4	127.0.0.4
	127.255.255.254	127.255.255.254
	127.255.255.255	127.255.255.255
	128.0.0.0	127.0.0.3
	192.168.1.1	127.0.0.3
));

## test 2-9	check boundries of 127.0.0.3
foreach my $IP (sort keys %testIP) {
  print "got: $_, exp: 127.0.0.3\nnot "
	unless ($_ = valid127($IP)) eq $testIP{"$IP"};
  &ok;
}
