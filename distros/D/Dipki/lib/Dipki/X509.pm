package Dipki::X509;
use strict;
use warnings;
use Win32::API;
use Carp qw(croak carp);

use Exporter qw(import);
our @EXPORT_OK = qw(FORMAT_PEM LDAP DECIMAL ReadStringFromFile SaveFileFromString QueryCert TextDumpToString CertThumb);

=head1 NAME

Dipki::X509 - X.509 Certificate Functions.

=cut

use constant FORMAT_PEM  => 0x10000;  #: Create in PEM-encoded format (default for CSR)
use constant LDAP        => 0x1000;  #: Output distinguished name in LDAP string representation
use constant DECIMAL     => 0x8000;  #: Output serial number in decimal format [default = hex]

# HashAlg:
use constant SHA1   => 0;  #: SHA-1 (default)
use constant SHA224 => 6;  #: SHA-224
use constant SHA256 => 3;  #: SHA-256
use constant SHA384 => 4;  #: SHA-384
use constant SHA512 => 5;  #: SHA-512
use constant MD5    => 1;  #: MD5 (as per RFC 1321)

sub ReadStringFromFile {
	croak "Missing input parameter" if (scalar(@_) < 1);
	my ($certfilename) = shift;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "X509_ReadStringFromFile", "PnPn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $nc = $dllfunc->Call("", 0, $certfilename, 0);
	croak Dipki::Err::FormatErrorMessage($nc) if $nc <= 0;
	my $buf = " " x ($nc+1);
	$nc = $dllfunc->Call($buf, $nc, $certfilename, 0);
	return substr($buf, 0, $nc);
}

sub SaveFileFromString {
	croak "Missing input parameter" if (scalar(@_) < 2);
	my ($newcertfile) = shift;
	my ($certstring) = shift;
	my ($opts) = shift || 0x0;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "X509_SaveFileFromString", "PPn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $n = $dllfunc->Call($newcertfile, $certstring, $opts);
	croak Dipki::Err::FormatErrorMessage($n) if $n != 0;
	return $n;	# SUCCESS
}

sub QueryCert {
	croak "Missing input parameter" if (scalar(@_) < 2);
	my ($filename) = shift;
	my ($query) = shift;
	my ($opts) = shift || 0x0;
    my $_QUERY_GETTYPE = 0x100000;
    my $_QUERY_STRING = 2;
 	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "X509_QueryCert", "PnPPn", "i");
	die "Error: $^E" if ! $dllfunc;
	# Find what type of result to expect: number or string (or error)
	my $n = $dllfunc->Call("", 0, $filename, $query, $_QUERY_GETTYPE);
	croak Dipki::Err::FormatErrorMessage($n) if $n < 0;
	if ($_QUERY_STRING == $n) {
		my $nc = $dllfunc->Call("", 0, $filename, $query, $opts);
		return "" if $nc == 0;
		croak Dipki::Err::FormatErrorMessage($nc) if $nc < 0;
		my $buf = " " x ($nc+1);
		$nc = $dllfunc->Call($buf, $nc, $filename, $query, $opts);
		return substr($buf, 0, $nc);
	} else {
		$n = $dllfunc->Call("", 0, $filename, $query, $opts);
		croak Dipki::Err::FormatErrorMessage($n) if $n < 0;
	}
	return $n;
}

sub TextDumpToString {
	croak "Missing input parameter" if (scalar(@_) < 1);
	my ($certfilename) = shift;
	my ($opts) = shift || 0x0;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "X509_TextDumpToString", "PnPn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $nc = $dllfunc->Call("", 0, $certfilename, $opts);
	croak Dipki::Err::FormatErrorMessage($nc) if $nc <= 0;
	my $buf = " " x ($nc+1);
	$nc = $dllfunc->Call($buf, $nc, $certfilename, $opts);
	return substr($buf, 0, $nc);
}

sub CertThumb {
	croak "Missing input parameter" if (scalar(@_) < 1);
	my ($certfilename) = shift;
	my ($hashalg) = shift || 0x0;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "X509_CertThumb", "PPnn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $nc = $dllfunc->Call($certfilename, "", 0, $hashalg);
	croak Dipki::Err::FormatErrorMessage($nc) if $nc <= 0;
	my $buf = " " x ($nc+1);
	$nc = $dllfunc->Call($certfilename, $buf, $nc, $hashalg);
	return substr($buf, 0, $nc);
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
