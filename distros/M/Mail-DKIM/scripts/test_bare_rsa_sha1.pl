#!/usr/bin/perl -I../../..

use strict;
use warnings;

use Mail::DKIM::Algorithm::rsa_sha1;

unless (-f "private.key")
{
	die "File not found: private.key\n";
}

my $rsa_sha1 = new Mail::DKIM::Algorithm::rsa_sha1(
				KeyFile => "private.key");
while (<STDIN>)
{
	chomp;
	$rsa_sha1->PRINT("$_\015\012");
}
$rsa_sha1->CLOSE;

print $rsa_sha1->sign;
