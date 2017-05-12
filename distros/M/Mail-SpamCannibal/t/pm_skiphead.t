# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}

use Mail::SpamCannibal::ParseMessage qw(
	limitread
	skiphead
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

local *T;
my $file = './spam.lib/spam1';
# parameters for spam1
my $chars	= 1628;	# total characters
my $lines	= 39;	# lines expected

my @lines;

open *T,$file or die "could not open test file $file\n";

## test 2 -- get the lines
$_ = limitread(*T,\@lines,2000);
close *T;
print "expected $chars characters, got $_ characters\nnot "
	unless $chars == $_;
&ok;

## test 3 -- number of lines
print "expected $lines headers, got ", (scalar @lines), " headers \nnot "
	unless $lines == @lines;
&ok;

## test 4 -- skip header
$lines = 22;
$_ = skiphead(\@lines);
print "exp: $lines remaining lines, got: $_\nnot "
	unless $lines == $_;
&ok;

## test 5 -- check next line in buffer
my $expect = q|<HTML><FONT COLOR="#fefefe" SIZE=1 FAMILY="SANSSERIF" FACE="Arial"|;
print 'exp: '.$expect."\ngot: ".$lines[0]."\nnot "
	unless $expect eq $lines[0];
&ok;
