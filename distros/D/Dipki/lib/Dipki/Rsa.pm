package Dipki::Rsa;
use strict;
use warnings;
use Win32::API;
use Carp qw(croak carp);

use Exporter qw(import);
our @EXPORT_OK = qw(ReadPrivateKey);

=head1 NAME

Dipki::Rsa - RSA Encryption and Public Key Functions. 

=cut

# Local constants
use constant _KEY_SECURE_OFF => 0x2000000;

sub ReadPrivateKey {
	croak "Missing input parameter" if (scalar(@_) < 1);
	my ($keyfileorstr) = shift;
	my ($password) = shift || "";
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "RSA_ReadAnyPrivateKey", "PnPPn", "i");
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
        "diCrPKI", "RSA_ReadAnyPublicKey", "PnPn", "i");
	die "Error: $^E" if ! $dllfunc;
	# NOTE: we turn off the key string encryption
	my $flags = _KEY_SECURE_OFF;
	my $nc = $dllfunc->Call("", 0, $keyfileorstr, $flags);
	croak Dipki::Err::FormatErrorMessage($nc) if $nc <= 0;
	my $buf = " " x ($nc+1);
	$nc = $dllfunc->Call($buf, $nc, $keyfileorstr, $flags);
	return substr($buf, 0, $nc);
}

sub KeyBits {
	croak "Missing input parameter" if (scalar(@_) < 1);
	my ($keystr) = shift;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "RSA_KeyBits", "P", "i");
	die "Error: $^E" if ! $dllfunc;
	my $n = $dllfunc->Call($keystr);
	croak Dipki::Err::FormatErrorMessage($n) if $n < 0;
	return $n;
}

sub KeyBytes {
	croak "Missing input parameter" if (scalar(@_) < 1);
	my ($keystr) = shift;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "RSA_KeyBytes", "P", "i");
	die "Error: $^E" if ! $dllfunc;
	my $n = $dllfunc->Call($keystr);
	croak Dipki::Err::FormatErrorMessage($n) if $n < 0;
	return $n;
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
