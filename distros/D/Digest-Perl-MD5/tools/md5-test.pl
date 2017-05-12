#!/usr/bin/perl -w
# $Id$

# Compare results from Digest::Perl::MD5 with Digest::MD5
# Press Ctrl-C to stop the test (on Unix)
# Move Mouse to upper left corner to stop the test (on Windows - you need Win32::API)
# prints 'ok' for every correct MD5 calculation and dies
# if the results are different

use strict;
use lib qw'./lib ../lib';
use Digest::Perl::MD5;
use Digest::MD5;

*pmd5 = \&Digest::Perl::MD5::md5_hex;
*xmd5 = \&Digest::MD5::md5_hex;
my ($count,$bytes) = 0;

my $mult = 10;

sub result { print "\n$count rounds\n$bytes Bytes\n"; exit; };

my $GetCursorPos;
if ($^O eq 'MSWin32') {
	eval {	require Win32::API; $GetCursorPos = new Win32::API("user32", "GetCursorPos", ['P'], 'V') };
} else {
	$SIG{INT} = \&result;
}



$|++;
while(1) {
	my $s = gen();
	my ($p,$x) = (pmd5($s),xmd5($s));
	if ($p ne $x) {
		print "\nFailure\n",
		      'Source: ',unpack('H*',$s),"\n",
		      "pmd5  : $p\n",
		      "xmd5  : $x\n";
	      exit;
	} else {
	print "ok ";
    }
    $count++; $bytes+=length $s;
    if (defined $GetCursorPos) {
	my $lpPoint = pack "LL", 0, 0;
	$GetCursorPos->Call($lpPoint);
	result() if $lpPoint eq "\0\0\0\0\0\0\0\0";
    }
}

sub gen {
	my $x;
	for (1 .. 1 + rand($count*$mult)) {
		$x .= pack 'C', rand 256;
	}
	$x;
}
