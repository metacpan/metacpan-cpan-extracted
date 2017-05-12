# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use File::SafeDO qw(
	DO
);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

my $config = './local/test.conf';

sub ok {
  print "ok $test\n";
  ++$test;
}

## test 2-3	suck in and check config file for domain1.com domain2.net

my $contents = DO($config);
print "could not open configuration file $config\nnot "
	unless $contents;
&ok;

print "missing configuration file variables domain1.com, domain2.net\nnot "
	unless exists $contents->{'domain1.com'} && exists $contents->{'domain2.net'};
&ok;

