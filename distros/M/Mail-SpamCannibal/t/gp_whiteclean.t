# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}

use Mail::SpamCannibal::ParseMessage qw(
	string2array
	array2string
);
use Mail::SpamCannibal::GoodPrivacy qw(
	whiteclean
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

my $msg = q|
once upon
a time
there were three little bears
more
|;

# has three or more white spaces after lines 2,4,5
my $whitemsg = q|
once upon   
a time
there were three little bears     
more  
|;

## test 2 -- check for split
my @out;
my $count = string2array($msg,\@out);

print "bad line count\nnot "
	unless $count == 5;
&ok;

## test 3 -- test it that does strings
print "string has trailing white space\nnot "
	unless $msg eq ($_ = whiteclean($whitemsg));
&ok;

## test 4 -- test that it does arrays. 2,4,5 end in white space
#	that's index 1,3,4
my @array;
string2array(\$whitemsg,\@array);
print "whitespace disappeared\nnot "
	unless	$array[1] =~ /\s+$/ &&
		$array[1] =~ /\s+$/ &&
		$array[1] =~ /\s+$/;
&ok;

## test 5 -- clean array
whiteclean(\@array);
foreach(@array) {
  if ($_ =~ /\s+$/) {
    print "whitespace still present\nnot ";
    last;
  }
}
&ok;

# test 6 -- belt and suspenders
my $clean = array2string(\@array);
print "clean string ne \$msg\nnot "
	unless $clean eq $msg;
&ok;
