# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
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

my $config = './local/my.conf';

sub ok {
  print "ok $test\n";
  ++$test;
}

## test 2-3	suck in and check config file for domain1.com domain2.net
#	suppress 'once'
my $contents = DO($config,'once');
print "could not open configuration file $config\nnot "
	unless $contents;
&ok;

print "missing configuration file variables domain1.com, domain2.net\nnot "
	unless exists $contents->{'domain1.com'} && exists $contents->{'domain2.net'};
&ok;

# test 4 check is hash
print '$rv isa ',(ref $contents),"\nnot "
	unless ref $contents eq 'HASH';
&ok;

# test 5 check is OTHER
my $tv = bless $contents, 'OTHER';
print '$rv isa ',(ref $tv),"\nnot "
	unless ref $contents eq 'OTHER';
&ok;

# test 6 check is still HASH
print "\$rv is not a HASH \nnot "
	unless UNIVERSAL::isa($tv,'HASH');
&ok;

