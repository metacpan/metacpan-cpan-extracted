# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Mail::SpamCannibal::WebService qw(
	get_query
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

local $ENV{QUERY_STRING} = 'zap=one&zap=2&zap=THREE&other=hello';

my %query = get_query();

## test 2	# of keys
my $keys = keys %query;
my $exp = 2;
print "got: $keys, exp: $exp keys for query\nnot "
	unless $keys == $exp;
&ok;

## test 3	check values
my $val = '';
foreach(sort keys %query) {
  @_ = split("\0",$query{$_});
  $val .= "$_ => @_, ";
}

$exp = "other => hello, zap => one 2 THREE, ";
print "got: $val\nexp: $exp\nnot "
	unless $val eq $exp;
&ok;
