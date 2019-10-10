#!/usr/bin/perl -I../lib
#
# Copyright (c) 2005-2007 Messiah College. This program is free software.
# Copyright (c) 2017 Standcore LLC. This program is free software.
# You can redistribute it and/or modify it under the terms of the
# GNU Public License as found at http://www.fsf.org/copyleft/gpl.html.
#
# Written by Jason Long, jlong@messiah.edu.

use strict;
use warnings;

use Mail::DKIM::ARC::Signer;
use Getopt::Long;
use Pod::Usage;

my $selector = "selector1";
my $algorithm = "rsa-sha256";
my $chain = "ar";
my $domain; # undef => auto-select domain
my $srvid;
my $key_file = "private.key";
my $timestamp = 12345;
my @extra_tag;
my $debug_canonicalization;
my $binary;
my $help;
my $wrap;
GetOptions(
		"selector=s" => \$selector,
		"domain=s" => \$domain,
		"srvid=s" => \$srvid,
		"chain=s" => \$chain,
		"key=s" => \$key_file,
		"debug-canonicalization=s" => \$debug_canonicalization,
	        "timestamp=i" => \$timestamp,
		"extra-tag=s" => \@extra_tag,
		"binary" => \$binary,
	        "wrap" => \$wrap,
		"help|?" => \$help,
		)
	or pod2usage(2);
pod2usage(1) if $help;
pod2usage("Error: unrecognized argument(s)")
	unless (@ARGV == 0);

eval "use Mail::DKIM::TextWrap;" if($wrap);

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

my $arc = new Mail::DKIM::ARC::Signer(
		Domain => $domain,
		SrvId => $srvid,
		Chain => $chain,
		Algorithm => $algorithm,
		Selector => $selector,
		KeyFile => $key_file,
		Debug_Canonicalization => $debugfh,
		Timestamp => $timestamp
		);

while (<STDIN>)
{
	unless ($binary)
	{
		chomp $_;
		s/\015?$/\015\012/s;
	}
	$arc->PRINT($_);
}
$arc->CLOSE;

if ($debugfh)
{
	close $debugfh;
	print STDERR "wrote canonicalized message to $debug_canonicalization\n";
}

print "RESULT IS " . $arc->result() . "\n";

if( $arc->result eq "sealed") {
	print join("\n",$arc->as_strings) . "\n";
} else {
	print "REASON IS " . $arc->{details} . "\n";
}

__END__

=head1 NAME

arcsign.pl - computes ARC signatures for an email message

=head1 SYNOPSIS

  arcsign.pl [options] < original_email.txt
    options:
      --chain=pass|fail|none|ar
      --domain=DOMAIN
      --srvid=DOMAIN
      --selector=SELECTOR
      --key=FILE
      --debug-canonicalization=FILE
      --timestamp=INTEGER
      --wrap

  arcsign.pl --help
    to see a full description of the various options

=head1 OPTIONS

=over

=item B<--chain>

Chain value.  "ar" means pick it up from Authentication-Results header.
 
=item B<--key>
 
File containing private key, without BEGIN or END lines.

=item B<--domain>

Signing domain

=item B<--srvid>

Authentication-Results server domain, defaults to signing domain.

=item B<--debug-canonicalization>

Outputs the canonicalized message to the specified file, in addition
to computing the DKIM signature. This is helpful for debugging
canonicalization methods.

=back

=head1 AUTHORS

Jason Long, E<lt>jlong@messiah.eduE<gt>

John Levine, E<lt>john.levine@standcore.comE<gt>
 
=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2007 by Messiah College
Copyright 2017 by Standcore LLC

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
