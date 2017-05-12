# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Mail::SpamCannibal::WebService qw(
	http_date
	cookie_date
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

my $time = 1061444137;
my $cookietime = 'Thu, 21-Aug-2003 05:35:37 GMT';
my $httptime = 'Thu, 21 Aug 2003 05:35:37 GMT';

## test 2	cookie
print "got: $_, exp: $cookietime\nnot "
	unless ($_ = cookie_date($time)) eq $cookietime;
&ok;

## test 3	http
print "got: $_, exp: $httptime\nnot "
	unless ($_ = http_date($time)) eq $httptime;
&ok;
