#!/usr/bin/perl -I../lib

use strict;
use warnings;
use Test::Simple tests => 3;

use Mail::DKIM::Signer;

# in this test, instead of specifying a private key file,
# or a Mail::DKIM::PrivateKey object, we specify a custom class
# instead, one which performs the RSA-sign operation itself.
# In our case, we simply return a dummy value, so this test
# is to ensure that Mail::DKIM itself does not care about the
# format that is returned.

package MyCustomSigner;
sub sign_digest
{
	my $self = shift;
	my ($digest_type, $digest_binary) = @_;
	return "\0\0\0\0\0\0";
}

package main;
my $custom_signer = bless { }, "MyCustomSigner";
my $dkim = Mail::DKIM::Signer->new(
		Algorithm => "rsa-sha1",
		Method => "relaxed",
		Domain => "example.org",
		Selector => "test",
		Key => $custom_signer,
		);
ok($dkim, "new() works");

my $sample_email = <<END_OF_SAMPLE;
From: jason <jason\@example.org>
Subject: hi there
Comment: what is a comment

this is a sample message
END_OF_SAMPLE
$sample_email =~ s/\n/\015\012/gs;

$dkim->PRINT($sample_email);
$dkim->CLOSE;

my $signature = $dkim->signature;
ok($signature, "signature() works");

print "# signature=" . $signature->as_string . "\n";
ok($signature->as_string =~ /b=AAAAAAAA/,
	"got expected signature value");

