# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Mail::SpamCannibal::ParseMessage qw(
	headers
	get_MTAs
	firstremote
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

{
  package Mail::SpamCannibal::ParseMessage;

  my %nslookup = (
    'ns2.is.bizsystems.com'		=> '192.168.1.171',
    'bzs.org'				=> '69.3.95.130',
    'ns3.bizsystems.net'		=> '216.36.65.66',
    '213-96-98-101.uc.nombres.ttd.es'	=> '213.96.98.101',
    'k5jp.3de28.net'			=> '44.98.180.242',
    'bogus.uc.nombres.ttd.es'		=> '11.22.33.44',
  );

  no warnings;
  *_host2ip = sub {
    my($myhp,$lp) = @_;			# copy ptr, local ptr
    @$lp = ();
    foreach(@$myhp) {
      if ($_ !~ /[a-zA-Z]/) {		# if not named host
        push @$lp, $_;
        next;
      }
      push @$lp, $nslookup{$_};
    }
  };

  *nslookup = sub {
    my $host = shift;
    return $nslookup{$host};
  };
}

*nslookup = \&Mail::SpamCannibal::ParseMessage::nslookup;

#	our input record looks like this
my @lines = split(/\n/,q
|Return-Path: <ahb4raxc6qg@yahoo.com>
Received: from ns2.is.bizsystems.com (IDENT:root@ns2.is.bizsystems.com [192.168.1.171])
        by bzs.org (8.11.4/8.11.4) with ESMTP id h4SGfnW22444
        for <sysadm@bzs.org>; Wed, 28 May 2003 09:41:49 -0700
Received: from ns3.bizsystems.net (IDENT:root@ns3.bizsystems.net [216.36.65.66])
        by ns2.is.bizsystems.com (8.12.9/8.12.9) with ESMTP id h4SGfn58028338
        for <sysadm@bzs.org>; Wed, 28 May 2003 09:41:49 -0700
Received: from 213-96-98-101.uc.nombres.ttd.es (101.Red-213-96-98.pooles.rima-tde.net [213.96.98.101])
        by ns3.bizsystems.net (8.12.9/8.12.9) with SMTP id h4SGg3M7028130
        for <sysadm@bzs.org>; Wed, 28 May 2003 09:42:05 -0700
Received: from k5jp.3de28.net [44.98.180.242] by bogus.uc.nombres.ttd.es SMTP id 2uwk75xMshwF5Q; Thu, 29 May 2003 10:53:16 +0200
|);

## test 2 -- parse the headers
my @headers;
my $lines = 5;	# expected headers

$_ = headers(\@lines,\@headers);
print "expected $lines headers, got $_ headers\nnot "
	unless $lines == $_;
&ok;

## test 3 -- extract MTA's
$lines = 4;	# expected MTA lines
my @mtas;
my $mtas = get_MTAs(\@headers,\@mtas);
print "expected $lines MTA lines, got $mtas\nnot "
	unless $mtas == $lines;
&ok;

## test 4 -- check with real spam
my @myhosts = ();

my $from = firstremote(\@mtas,\@myhosts);
print "found bogus host $from\nnot "
	if $from;
&ok;

## test 5 --  should fail, local hosts are only checked, not auto address range
@myhosts = qw(  bzs.org );      # should fail
$from = firstremote(\@mtas,\@myhosts);
print "found bogus host $from\nnot "
	if $from;
&ok;

## test 6 -- remove auto exclude range, should see ns2
$expect = nslookup('ns2.is.bizsystems.com');

$from = firstremote(\@mtas,\@myhosts,1);
print "exp: $expect, got: $from\nnot "
        unless $from eq $expect;
&ok;

## test 7 --  should fail, local hosts are only checked, not auto address range
@myhosts = qw(	bzs.org ns2.is.bizsystems.com );	# should skip ns2, find ns3
my $expect = nslookup('ns3.bizsystems.net');

$from = firstremote(\@mtas,\@myhosts);
print "exp: $expect, got: $from\nnot "
	unless $from eq $expect;
&ok;

## test 8 -- add all my hosts to exclusion array
#		no auto exclude, all of our hosts are named
#		should find bad guy
@myhosts = qw( ns2.is.bizsystems.com  bzs.org ns3.bizsystems.net );
$expect = '213.96.98.101';

$from = firstremote(\@mtas,\@myhosts,1);
print "exp: $expect, got: $from\nnot "  
        unless $from eq $expect;
&ok;

## test 9 -- if we include the 'bad guy' in the exclusion list, 
#		the next IP should fail since the receiving MTA is unknown
push @myhosts, $expect;

$from = firstremote(\@mtas,\@myhosts,1);
print "exp: $expect, got: $from\nnot "  
	if $from;
&ok;
