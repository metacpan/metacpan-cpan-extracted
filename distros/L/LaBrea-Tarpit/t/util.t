# Before ake install' is performed this script should be runnable with
# `make test'. After ake install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..15\n"; }
END {print "not ok 1\n" unless $loaded;}

require Time::Local;
require LaBrea::Tarpit;
import LaBrea::Tarpit qw(bandwidth timezone midnight tz2_sec);

$loaded = 1;
print "ok 1\n";


sub ok {
  print "ok $test\n";
  ++$test;
}

#### CHECK ALL THE UTILITY FUNCTIONS

my %tarpit;

#### check bandwidth
$test = 2;

my $bandwidth = bandwidth(\%tarpit);
print "bandwidth should be zero\nnot " if $bandwidth;
&ok;

## test 3
$tarpit{bw} = 5;
$bandwidth = bandwidth(\%tarpit);
print "bandwidth should be $tarpit{bw}\nnot "
	unless $bandwidth == 5;
&ok;

# Sat Dec  1 05:43:56 2001
my $time = Time::Local::timelocal(56,43,5,1,11,101);
# Sat Dec  1 00:00:00 2001
my $mid  = Time::Local::timelocal( 0, 0,0,1,11,101);

#### sorta check timezone

## test 4
my $tz = timezone($time);
print "bad timezone format $tz\nnot "
	unless $tz =~ /^[\+\-]\d\d\d\d$/;
&ok;

## test 5 - 12
my @tzi = qw( +0100 +0130 +0200 +0230 -0100 -0130 -0200 -0230 );
my @tzs = qw(  3600  5400  7200  9000 -3600 -5400 -7200 -9000 );

foreach( 0..$#tzi ) {
  my $rv = tz2_sec($tzi[$_]);
  print "tz $tzi[$_] is $rv, should be $tzs[$_]\nnot "
	unless $tzs[$_] == $rv;
  &ok;
}

#### check midnight
## test 13
$_ = midnight($time);
print "midnight not $mid, is $_\nnot "
	unless $_ == $mid;
&ok;

## check that tz works with midnight
## test 14
$_ = midnight($time,$tz);
print "midnight not $mid, is $_\nnot "
        unless $_ == $mid;
&ok;

## check NOW
## test 15
my ($sec,$min,$hr) = localtime(midnight(time));
print "$hr:$min:$sec is not zero\nnot "
	if $hr || $min || $sec;
&ok;
