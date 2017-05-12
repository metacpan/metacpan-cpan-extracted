#!/usr/bin/perl -I../../..

use strict;
use warnings;

use Getopt::Long;

my $headers;
GetOptions(
		"headers=s" => \$headers
	) or die "Error: invalid argument(s)\n";

my $canon_method = $ARGV[0]
	or die "Error: no canonicalization method specified\n";

use Mail::DKIM::Canonicalization::nowsp;
use Mail::DKIM::Canonicalization::relaxed;
use Mail::DKIM::Canonicalization::simple;
use Mail::DKIM::Signature;

my $crlf = "\015\012";

# read in headers
my @headers;
my @header_names;
while (<STDIN>)
{
	# standardize line terminators
	chomp;
	$_ .= $crlf;

	last if ($_ eq $crlf);

	if (/^\s/ && @headers)
	{
		# continues last header
		$headers[@headers - 1] .= $_;
	}
	else
	{
		# starts a new header
		push @headers, $_;
		if (/^(\S[^:\s]*)\s*:/)
		{
			push @header_names, $1;
		}
	}
}

# determine value of h= tag
unless (defined $headers)
{
	$headers = join(":", @header_names);
}

# create a dummy signature
my $signature = new Mail::DKIM::Signature(
		Algorithm => "rsa-sha1",
		Method => $canon_method,
		Domain => "example.org",
		Selector => "selector");
$signature->headerlist($headers);

# create a canonicalization object
my $canon_class = "Mail::DKIM::Canonicalization::$canon_method";
my $can = $canon_class->new(
				Signature => $signature,
				output_fh => *STDOUT);

# repeat the headers
foreach my $header (@headers)
{
	$can->add_header($header);
}
$can->finish_header;

# read the body
while (<STDIN>)
{
	chomp;
	$can->add_body("$_\015\012");
}
$can->finish_body;
