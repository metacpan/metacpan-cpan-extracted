# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Socket;
use Mail::SpamCannibal::ScriptSupport qw(
	is_GENERIC
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

my %config = (			# for consistency with config file
  'GENERIC'     => {
       ignore    => [
               'dsl-only',
       ],
        regexp    => [  # test for these regular expression (case insensitive)
                '\d+[a-zA-Z_\-\.]\d+[a-zA-Z_\-\.]\d+[a-zA-Z_\-\.]\d+|\d{12}', 
	],
  },
);

my @generic = qw(

	1.2.3.4.somewhere.com
);
my @ignore = (@generic,qw(1.2.3.4.dsl-only.com));

my @good = (@generic,qw(ns2.somewhere.com));	

## test 2	no pointers
my $gp = {};
print "should not be generic\nnot "
	if is_GENERIC($gp,@generic);
&ok;

## test 3	is generic
$gp = $config{GENERIC};
print "missed generic PTR's\nnot "
	unless is_GENERIC($gp,@generic);
&ok;

## test 4	is ignore
print "failed to ignore\nnot "
	if is_GENERIC($gp,@ignore);
&ok;

## test 5	is good
print "failed on good name\nnot "
	if is_GENERIC($gp,@good);
&ok;
