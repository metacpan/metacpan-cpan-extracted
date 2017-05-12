# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}

use Mail::SpamCannibal::ParseMessage qw(
	limitread
	headers
	get_MTAs
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
my $file = './spam.lib/spam9';
# parameters for spam1
my $chars	= 4005;	# total characters
my $lines	= 82;	# lines expected

my @lines;

open *T,$file or die "could not open test file $file\n";

## test 2 -- get the lines
$_ = limitread(*T,\@lines,5000);
close *T;
print "expected $chars characters, got $_ characters\nnot "
	unless $chars == $_;
&ok;

## test 3 -- number of lines
print "expected $lines headers, got ", (scalar @lines), " headers \nnot "
	unless $lines == @lines;
&ok;

## test 4 -- parse the headers
my @headers;
$lines = 17;	# expected headers

$_ = headers(\@lines,\@headers);
print "expected $lines headers, got $_ headers\nnot "
	unless $lines == $_;
&ok;

## test 5 -- extract MTA's
$lines = 4;	# expected MTA lines
my @mtas;
my $mtas = get_MTAs(\@headers,\@mtas);
print "expected $lines MTA lines, got $mtas\nnot "
	unless $mtas == $lines;
&ok;

## test 6 -- check mta results
my @expect = (
	'192.168.1.171 -> bzs.org',
	'216.36.65.66 -> ns2.is.bizsystems.com',
	'213.96.98.101 -> ns3.bizsystems.net',
	'44.98.180.242 -> 213-96-98-101.uc.nombres.ttd.es'
);
foreach(0..$#mtas) {
  my $got = sprintf $mtas[$_]->{from}.' -> '.$mtas[$_]->{by};
  print "exp: $expect[$_]\ngot: $got\nnot "
	unless $expect[$_] eq $got;
}
&ok;
