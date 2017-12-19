#!/usr/bin/env perl -I../lib
#
# Copyright (c) 2005-2007 Messiah College. This program is free software.
# Copyright 2017 Standcore LLC. This program is free software.
# You can redistribute it and/or modify it under the terms of the
# GNU Public License as found at http://www.fsf.org/copyleft/gpl.html.
#
# Written by Jason Long, jlong@messiah.edu.

use strict;
use warnings;

use Mail::DKIM::ARC::Verifier;
use Net::DNS::Resolver::Mock;
use Mail::DKIM;
use Getopt::Long;
use Pod::Usage;

my ($as_canonicalization, $ams_canonicalization);
my ($details, $dns, $help);
my $FakeResolver;

GetOptions(
		"as-canonicalization=s" => \$as_canonicalization,
		"ams-canonicalization=s" => \$ams_canonicalization,
		"dns=s" => \$dns,
		"details" => \$details,
		"help" => \$help,
		)
	or pod2usage(2);
pod2usage(1) if $help or @ARGV > 0;

my ($asfh, $amsfh);
if (defined $as_canonicalization)
{
	open $asfh, ">", $as_canonicalization
		or die "Error: cannot write to $as_canonicalization: $!\n";
}

if (defined $ams_canonicalization)
{
	open $amsfh, ">", $ams_canonicalization
		or die "Error: cannot write to $ams_canonicalization: $!\n";
}

# use fake DNS records
if($dns) {
	open(DNSR, "<$dns") or die "cannot open $dns";
	my $dnsrecs = join("", <DNSR>);
	close DNSR;

	$FakeResolver = Net::DNS::Resolver::Mock->new();
	$FakeResolver->zonefile_parse( $dnsrecs );
} else {
# recommended, but may cause compatibility problems with old firewalls
	Mail::DKIM::DNS::enable_EDNS0;
}

my $arc = new Mail::DKIM::ARC::Verifier(
	AS_Canonicalization => $asfh,
	AMS_Canonicalization => $amsfh,
	);
Mail::DKIM::DNS::resolver( $FakeResolver ) if $FakeResolver;

my $msg = join("", <STDIN>);
$msg =~ s/\015?\012/\015\012/g;
$arc->PRINT($msg);
$arc->CLOSE;

print "RESULT: " . $arc->result . "\n";

if($details) {
	printf "DETAILS: %s\nRESULTS: %s\n", $arc->{details}, $arc->result_detail;

	my @sigs = @{$arc->{signatures}};

	foreach my $s (@sigs) {
		printf "SIG: %s by %s result %s\n", $s->domain , ref($s), $s->result || "";
	}

	my @algs = @{$arc->{algorithms}};

	foreach my $h (@algs) {
		printf "ALG: by %s result %s\n" , ref($h), $h->signature->result || "";
	}
}

__END__

=head1 NAME

arcverify.pl - verifies ARC signatures on an email message

=head1 SYNOPSIS

  arcverify.pl [options] < signed_email.txt
    options:
      --as-canonicalization=FILE
      --ams-canonicalization=FILE
      --dns=FILE
      --details

  arcverify.pl --help
    to see a full description of the various options

=head1 OPTIONS

=over

=item B<--as-canonicalization>
=item B<--ams-canonicalization>

Outputs the canonicalized message used for the ARC-Seal or ARC-Message-Signature
to the specified file, in addition
to computing the ARC signature. This is helpful for debugging
canonicalization methods.

=item B<--details>

Print details of ARC evaluation.

=item B<--dnsrecords=FILE>

Use DNS records from that file rather than the real DNS.

=back

=head1 AUTHOR

Jason Long, E<lt>jlong@messiah.eduE<gt>

John Levine, E<lt>john.levine@standcore.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2007 by Messiah College
Copyright 2017 by Standcore LLC

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
