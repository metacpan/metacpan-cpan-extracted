#!/usr/bin/perl -I../../..

use strict;
use warnings;

use Mail::DKIM::Algorithm::rsa_sha1;
use Mail::DKIM::Canonicalization::nowsp;

unless (-f "private.key")
{
	die "File not found: private.key\n";
}

tie *rsa_sha1, "Mail::DKIM::Algorithm::rsa_sha1",
				"KeyFile" => "private.key";
my $nowsp = new Mail::DKIM::Canonicalization::nowsp(
				output_fh => *rsa_sha1);

while (<STDIN>)
{
	chomp;
	$nowsp->PRINT("$_\015\012");
}
$nowsp->CLOSE;

my $rsa_sha1 = tied *rsa_sha1;
print $rsa_sha1->sign;
print "\n";
