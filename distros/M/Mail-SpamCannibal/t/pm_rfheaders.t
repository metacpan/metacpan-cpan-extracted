# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Mail::SpamCannibal::ParseMessage qw(
	limitread
	rfheaders
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
sub repeat {
  my ($file,$chars) = @_;
# parameters for spam1
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

## test 4 -- parse the headers
  my @headers;
  $lines = 12;	# expected headers

  $_ = rfheaders(\@lines,\@headers);
  print "expected $lines headers, got $_ headers\nnot "
	unless $lines == $_;
  &ok;

#foreach(@headers) {
#print "HEADER -> $_\n"
#}
#print "\n\n";

  @_ = split(/\n/, q
|Return-Path: <septictankclogvtgy@hotmail.com>
Received: from hotmail.com ([64.216.248.129]) by ns2.is.bizsystems.com (8.12.8/8.12.8) with SMTP id h2KIRcYC029373; Thu, 20 Mar 2003 10:27:39 -0800
Message-ID: <000201c7be87$bca28275$47542116@tkkemng.scx>
From: "SepticTank Clog" <septictankclogvtgy@hotmail.com>
To: Homeowner
Subject: F R E E Trial of SPC - the Proven Solution for Septic Tank Problems! 0923gcof1-277shTi6777a-21
Date: Thu, 20 Mar 2003 17:57:48 -0000
MIME-Version: 1.0
Content-Type: text/html; charset="iso-8859-1"
X-Priority: 3
X-Mailer: AOL 7.0 for Windows US sub 118
Importance: Normal
|);

## test 5 -- check expected text
  foreach(0..$#headers) {
    if ($headers[$_] ne $_[$_]) {
      print 'exp: '.$_[$_]."\ngot: ".$headers[$_]."\nnot ";
      last;
    }
  }
  &ok;
} # end repeat

repeat('./spam.lib/spam1',1628);
repeat('./spam.lib/spam10',1745);
