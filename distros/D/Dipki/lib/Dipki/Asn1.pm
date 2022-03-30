package Dipki::Asn1;
use strict;
use warnings;
use Win32::API;
use Carp qw(croak carp);

use Exporter qw(import);
our @EXPORT_OK = qw(Type TextDumpToString TextDump NOCOMMENTS ADDLEVELS);

=head1 NAME

Dipki::Asn1 - ASN.1 utilities. 

=cut

# Option flags
use constant NOCOMMENTS => 0x100000;  #: Hide the comments
use constant ADDLEVELS => 0x800000;  #: Show level numbers

=head1 Type function

Describe the type of ASN.1 data.

=head2 Example

  use Dipki;
  $s = Dipki::Asn1::Type("AlicePrivRSASign.p8e");

=cut

sub Type {
	croak "Missing input parameter" if (scalar(@_) < 1);
	my ($asn1file) = shift;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "ASN1_Type", "PnPn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $nc = $dllfunc->Call("", 0, $asn1file, 0);
	croak Dipki::Err::FormatErrorMessage($nc) if $nc < 0;
	return "" if $nc == 0;
	my $buf = " " x ($nc+1);
	$nc = $dllfunc->Call($buf, $nc, $asn1file, 0);
	return substr($buf, 0, $nc);
}

=head1 TextDumpToString function

Dump details of ASN.1 formatted data to a string. 

=head2 Example

  use Dipki;
  $s = Dipki::Asn1::TextDumpToString($fname, Dipki::Asn1::NOCOMMENTS);

=cut

sub TextDumpToString {
	croak "Missing input parameter" if (scalar(@_) < 1);
	my ($asn1file) = shift;
	my ($opts) = shift || 0x0;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "ASN1_TextDumpToString", "PnPPn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $nc = $dllfunc->Call("", 0, $asn1file, "", $opts);
	croak Dipki::Err::FormatErrorMessage($nc) if $nc < 0;
	return "" if $nc == 0;
	my $buf = " " x ($nc+1);
	$nc = $dllfunc->Call($buf, $nc, $asn1file, "", $opts);
	return substr($buf, 0, $nc);
}

=head1 TextDump function

Dump details of an ASN.1 formatted data file to a text file. 

=head2 Example

  use Dipki;
  $n = Dipki::Asn1::TextDump($outfile, $fname, Dipki::Asn1::ADDLEVELS);

=cut

sub TextDump {
	croak "Missing input parameter" if (scalar(@_) < 2);
	my ($outputfile) = shift;
	my ($asn1file) = shift;
	my ($opts) = shift || 0x0;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "ASN1_TextDump", "PPn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $n = $dllfunc->Call($outputfile, $asn1file, $opts);
	croak Dipki::Err::FormatErrorMessage($n) if $n != 0;
	return $n;	# SUCCESS
}

1;
__END__

=head1 AUTHOR

David Ireland, L<https://www.cryptosys.net/contact/>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 David Ireland, DI Management Services Pty Limited,
L<https://www.di-mgt.com.au> L<https://www.cryptosys.net>.
The code in this module is licensed under the terms of the MIT license.  
For a copy, see L<http://opensource.org/licenses/MIT>

=cut
