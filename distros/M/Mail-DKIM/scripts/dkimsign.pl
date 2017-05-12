#!/usr/bin/perl -I../lib
#
# Copyright (c) 2005-2007 Messiah College. This program is free software.
# You can redistribute it and/or modify it under the terms of the
# GNU Public License as found at http://www.fsf.org/copyleft/gpl.html.
#
# Written by Jason Long, jlong@messiah.edu.

use strict;
use warnings;

use Mail::DKIM::Signer;
use Mail::DKIM::TextWrap;
use Getopt::Long;
use Pod::Usage;

my $type = "dkim";
my $selector = "selector1";
my $algorithm = "rsa-sha1";
my $method = "simple";
my $domain; # undef => auto-select domain
my $expiration;
my $identity;
my $key_file = "private.key";
my $key_protocol;
my @extra_tag;
my $debug_canonicalization;
my $binary;
my $help;
GetOptions(
		"type=s" => \$type,
		"algorithm=s" => \$algorithm,
		"method=s" => \$method,
		"selector=s" => \$selector,
		"domain=s" => \$domain,
		"expiration=i" => \$expiration,
		"identity=s" => \$identity,
		"key=s" => \$key_file,
		"key-protocol=s" => \$key_protocol,
		"debug-canonicalization=s" => \$debug_canonicalization,
		"extra-tag=s" => \@extra_tag,
		"binary" => \$binary,
		"help|?" => \$help,
		)
	or pod2usage(2);
pod2usage(1) if $help;
pod2usage("Error: unrecognized argument(s)")
	unless (@ARGV == 0);

my $debugfh;
if (defined $debug_canonicalization)
{
	open $debugfh, ">", $debug_canonicalization
		or die "Error: cannot write $debug_canonicalization: $!\n";
}
if ($binary)
{
	binmode STDIN;
}

my $dkim = new Mail::DKIM::Signer(
		Policy => \&signer_policy,
		Algorithm => $algorithm,
		Method => $method,
		Selector => $selector,
		KeyFile => $key_file,
		Debug_Canonicalization => $debugfh,
		);

while (<STDIN>)
{
	unless ($binary)
	{
		chomp $_;
		s/\015?$/\015\012/s;
	}
	$dkim->PRINT($_);
}
$dkim->CLOSE;

if ($debugfh)
{
	close $debugfh;
	print STDERR "wrote canonicalized message to $debug_canonicalization\n";
}

print $dkim->signature->as_string . "\n";

sub signer_policy
{
	my $dkim = shift;

	use Mail::DKIM::DkSignature;

	$dkim->domain($domain || $dkim->message_sender->host);

	my $class = $type eq "domainkeys" ? "Mail::DKIM::DkSignature" :
			$type eq "dkim" ? "Mail::DKIM::Signature" :
				die "unknown signature type '$type'\n";
	my $sig = $class->new(
			Algorithm => $dkim->algorithm,
			Method => $dkim->method,
			Headers => $dkim->headers,
			Domain => $dkim->domain,
			Selector => $dkim->selector,
			defined($expiration) ? (Expiration => time() + $expiration) : (),
			defined($identity) ? (Identity => $identity) : (),
		);
	$sig->protocol($key_protocol) if defined $key_protocol;
	foreach my $extra (@extra_tag)
	{
		my ($n, $v) = split /=/, $extra, 2;
		$sig->set_tag($n, $v);
	}
	$dkim->add_signature($sig);
	return;
}

__END__

=head1 NAME

dkimsign.pl - computes a DKIM signature for an email message

=head1 SYNOPSIS

  dkimsign.pl [options] < original_email.txt
    options:
      --type=TYPE
      --method=METHOD
      --selector=SELECTOR
      --expiration=INTEGER
      --debug-canonicalization=FILE

  dkimsign.pl --help
    to see a full description of the various options

=head1 OPTIONS

=over

=item B<--expiration>

Optional. Specify the desired signature expiration, as a delta
from the signature timestamp.

=item B<--type>

Determines the desired signature. Use dkim for a DKIM-Signature, or
domainkeys for a DomainKey-Signature.

=item B<--method>

Determines the desired canonicalization method. Possible values are
simple, simple/simple, simple/relaxed, relaxed, relaxed/relaxed,
relaxed/simple.

=item B<--debug-canonicalization>

Outputs the canonicalized message to the specified file, in addition
to computing the DKIM signature. This is helpful for debugging
canonicalization methods.

=back

=head1 AUTHOR

Jason Long, E<lt>jlong@messiah.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2007 by Messiah College

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
