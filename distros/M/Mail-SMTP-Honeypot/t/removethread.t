# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;

use Mail::SMTP::Honeypot;

*removethread = \&Mail::SMTP::Honeypot::removethread;

use Net::NBsocket qw(
	open_udpNB
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

sub next_sec {
  my ($then) = @_;
  $then = time unless $then;
  my $now;
# wait for epoch
  do { select(undef,undef,undef,0.1); $now = time }
        while ( $then >= $now );
  $now;
}

## test 2	set up parms for test
my $sock = open_udpNB();
print "could not open socket for testing\nnot "
	unless $sock;
&ok;

my $fileno = 123;
my($tp) = &Mail::SMTP::Honeypot::_trace;
my $conf = {};
Mail::SMTP::Honeypot::check_config($conf);
${$tp} = {
	$fileno => {
		sock	=> $sock,
	},
};

## test 3	check remove operation
removethread($fileno);
print "thread still exists\nnot "
	if exists ${$tp}->{$fileno};
&ok;

## test 4	check that socket closed
print "previous SOCK close failed\nnot "
	if eval { close $sock };
&ok;
