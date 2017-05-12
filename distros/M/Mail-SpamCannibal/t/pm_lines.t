# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}

use Mail::SpamCannibal::ParseMessage qw(
	string2array
	array2string
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
more|;

## test 2 -- check for split
my @out;
my $count = string2array($msg,\@out);

print "bad line count\nnot "
	unless $count == 5;
&ok;

## test 3 -- check join, has extra endline added to msg below
my $result = array2string(\@out);
print "result does not match original\nnot "
	unless $result eq $msg ."\n";
&ok;

## test 4 -- test first line extraction;
my $expect = 'first line';
$out[0] = $expect;
$result = array2string(\@out,0,0);
print "got: $result exp: $expect\nnot "
	unless $result eq $expect."\n";
&ok;

## test 5 -- extract 2 lines in the middle
$expect = qq|once upon\na time\n|;
$result = array2string(\@out,1,2);
print "got: $result exp: $expect\nnot "
        unless $result eq $expect;
&ok;

## test 6 -- pluck last line
$expect = 'more';
$result = array2string(\@out,$#out,$#out);
print "got: $result exp: $expect\nnot "
        unless $result eq $expect."\n";
&ok;

## test 7 -- return empty string
$result = array2string(\@out,3,2);
print "expected empty string, got: $result\nnot "
        if $result;   
&ok;
