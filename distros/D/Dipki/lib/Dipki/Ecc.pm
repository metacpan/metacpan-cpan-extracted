package Dipki::Ecc;
use strict;
use warnings;
use Win32::API;
use Carp qw(croak carp);

use Exporter qw(import);
our @EXPORT_OK = qw(ReadPrivateKey ReadPublicKey QueryKey);

=head1 NAME

Dipki::Ecc - Elliptic curve cryptography. 

=cut

# Local constants
use constant _KEY_SECURE_OFF => 0x2000000;

sub ReadPrivateKey {
	croak "Missing input parameter" if (scalar(@_) < 1);
	my ($keyfileorstr) = shift;
	my ($password) = shift || "";
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "ECC_ReadPrivateKey", "PnPPn", "i");
	die "Error: $^E" if ! $dllfunc;
	# NOTE: we turn off the key string encryption
	my $flags = _KEY_SECURE_OFF;
	my $nc = $dllfunc->Call("", 0, $keyfileorstr, $password, $flags);
	croak Dipki::Err::FormatErrorMessage($nc) if $nc <= 0;
	my $buf = " " x ($nc+1);
	$nc = $dllfunc->Call($buf, $nc, $keyfileorstr, $password, $flags);
	return substr($buf, 0, $nc);
}

sub ReadPublicKey {
	croak "Missing input parameter" if (scalar(@_) < 1);
	my ($keyfileorstr) = shift;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "ECC_ReadPublicKey", "PnPn", "i");
	die "Error: $^E" if ! $dllfunc;
	# NOTE: we turn off the key string encryption
	my $flags = _KEY_SECURE_OFF;
	my $nc = $dllfunc->Call("", 0, $keyfileorstr, $flags);
	croak Dipki::Err::FormatErrorMessage($nc) if $nc <= 0;
	my $buf = " " x ($nc+1);
	$nc = $dllfunc->Call($buf, $nc, $keyfileorstr, $flags);
	return substr($buf, 0, $nc);
}

sub QueryKey {
	croak "Missing input parameter" if (scalar(@_) < 2);
	my ($keystr) = shift;
	my ($query) = shift;
    my $_QUERY_GETTYPE = 0x100000;
    my $_QUERY_STRING = 2;
 	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "ECC_QueryKey", "PnPPn", "i");
	die "Error: $^E" if ! $dllfunc;
	# Find what type of result to expect: number or string (or error)
	my $n = $dllfunc->Call("", 0, $keystr, $query, $_QUERY_GETTYPE);
	croak Dipki::Err::FormatErrorMessage($n) if $n < 0;
	my $flags = 0;
	if ($_QUERY_STRING == $n) {
		my $nc = $dllfunc->Call("", 0, $keystr, $query, $flags);
		return "" if $nc == 0;
		croak Dipki::Err::FormatErrorMessage($nc) if $nc < 0;
		my $buf = " " x ($nc+1);
		$nc = $dllfunc->Call($buf, $nc, $keystr, $query, $flags);
		return substr($buf, 0, $nc);
	} else {
		$n = $dllfunc->Call("", 0, $keystr, $query, $flags);
		croak Dipki::Err::FormatErrorMessage($n) if $n < 0;
	}
	return $n;
}

sub KeyHashCode {
	croak "Missing input parameter" if (scalar(@_) < 1);
	my ($keystr) = shift;
 	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "ECC_KeyHashCode", "P", "i");
	die "Error: $^E" if ! $dllfunc;
	my $n = $dllfunc->Call($keystr);
	croak Dipki::Err::FormatErrorMessage($n) if $n == 0;
	return $n & 0xFFFFFFFF;	
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
