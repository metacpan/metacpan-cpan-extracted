#!/usr/bin/perl -I../lib

use strict;
use warnings;
use Test::Simple tests => 8;

use Mail::DKIM::Signer;
use Mail::DKIM::DkSignature;

# The main purpose of this set of tests is to ensure that I am aware
# whenever a change in my code causes the generated signature to change
# for DomainKeys signatures. Generally this should never occur for a
# change in DomainKeys code. (In contrast to DKIM, where the generated
# signature gets included in the signature, so any changes to the format
# of the signature will cause the hash to change.)
# 

{
my %sig_args;
my $policyfn = sub {
		my $signer = shift;
		if ($sig_args{Headers} && $sig_args{Headers} eq "*")
		{
			$sig_args{Headers} = $signer->headers;
		}
		$signer->add_signature(Mail::DKIM::DkSignature->new(%sig_args));
		return;
	};
my $tdir = -f "t/test.key" ? "t" : ".";
my $keyfile = "$tdir/test.key";
my $sample_email = <<END_OF_SAMPLE;
From: jason <jlong\@messiah.edu>
Subject: hi there
Comment: what is a comment

this is a sample message
END_OF_SAMPLE
$sample_email =~ s/\n/\015\012/gs;

sub sign_sample_using_args
{
	%sig_args = (
		Algorithm => "rsa-sha1",
		Selector => "test8",
		Domain => "messiah.edu",
		@_,
		);
	my $dkim = Mail::DKIM::Signer->new(
		Policy => $policyfn,
		KeyFile => $keyfile,
		);
$dkim->PRINT($sample_email);
$dkim->CLOSE;

my $signature = $dkim->signature;
return $signature;
}
}

my $signature;
$signature = sign_sample_using_args(
		Method => "simple",
		);
ok($signature, "signature() works");
print "# " . $signature->as_string . "\n";
ok($signature->data =~ /^TL93PzPvedAijHChCAt/, "got expected signature");


$signature = sign_sample_using_args(
		Method => "simple",
		Headers => "*",
		);
ok($signature, "signature() works");
print "# " . $signature->as_string . "\n";
ok($signature->data =~ /^n\+qfVkhQPch80atOC7/, "got expected signature");

$signature = sign_sample_using_args(
		Method => "nofws",
		);
ok($signature, "signature() works");
print "# " . $signature->as_string . "\n";
ok($signature->data =~ /^JWzIzvCZBIYnoMebzKU/, "got expected signature");


$signature = sign_sample_using_args(
		Method => "nofws",
		Headers => "*",
		);
ok($signature, "signature() works");
print "# " . $signature->as_string . "\n";
ok($signature->data =~ /^fkDC8iF/, "got expected signature");

