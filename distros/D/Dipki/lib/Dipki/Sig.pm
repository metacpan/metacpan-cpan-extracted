package Dipki::Sig;
use strict;
use warnings;
use Win32::API;
use Carp qw(croak carp);

use Exporter qw(import);
our @EXPORT_OK = qw(SignData SignDigest SignFile VerifyData VerifyDigest VerifyFile RSA_SHA1 RSA_SHA256);

=head1 NAME

Dipki::Sig - Signature creation and verification 

=cut

# SigAlg constants
use constant RSA_SHA1   => "sha1WithRSAEncryption";  #: Use sha1WithRSAEncryption (rsa-sha1) signature algorithm
use constant RSA_SHA224 => "sha224WithRSAEncryption"; #: Use sha224WithRSAEncryption (rsa-sha224) signature algorithm
use constant RSA_SHA256 => "sha256WithRSAEncryption"; #: Use sha256WithRSAEncryption (rsa-sha256) signature algorithm [minimum recommended]
use constant RSA_SHA384 => "sha384WithRSAEncryption"; #: Use sha384WithRSAEncryption (rsa-sha384) signature algorithm
use constant RSA_SHA512 => "sha512WithRSAEncryption"; #: Use sha512WithRSAEncryption (rsa-sha512) signature algorithm
use constant RSA_MD5 => "md5WithRSAEncryption"; #: Use md5WithRSAEncryption (rsa-md5) signature algorithm [ legacy applications only]
use constant ECDSA_SHA1 => "ecdsaWithSHA1"; #: Use ecdsaWithSHA1 (ecdsa-sha1) signature algorithm
use constant ECDSA_SHA224 => "ecdsaWithSHA224"; #: Use ecdsaWithSHA224 (ecdsa-sha224) signature algorithm
use constant ECDSA_SHA256 => "ecdsaWithSHA256"; #: Use ecdsaWithSHA256 (ecdsa-sha256) signature algorithm
use constant ECDSA_SHA384 => "ecdsaWithSHA384"; #: Use ecdsaWithSHA384 (ecdsa-sha384) signature algorithm
use constant ECDSA_SHA512 => "ecdsaWithSHA512"; #: Use ecdsaWithSHA512 (ecdsa-sha512) signature algorithm
use constant RSA_PSS_SHA1 => "RSA-PSS-SHA1"; #: Use RSA-PSS signature algorithm with SHA-1
use constant RSA_PSS_SHA224 => "RSA-PSS-SHA224"; #: Use RSA-PSS signature algorithm with SHA-224
use constant RSA_PSS_SHA256 => "RSA-PSS-SHA256"; #: Use RSA-PSS signature algorithm with SHA-256
use constant RSA_PSS_SHA384 => "RSA-PSS-SHA384"; #: Use RSA-PSS signature algorithm with SHA-384
use constant RSA_PSS_SHA512 => "RSA-PSS-SHA512"; #: Use RSA-PSS signature algorithm with SHA-512
use constant ED25519 => "Ed25519"; #: Use Ed25519, the Edwards-curve Digital Signature Algorithm (EdDSA) as per [RFC8032]

# Options
use constant DETERMINISTIC => 0x2000;  #: ECDSA only: Use the deterministic digital signature generation procedure of [RFC6979] for ECDSA signature [default=random k]
use constant ASN1DER => 0x4000;  #: ECDSA only: Form ECDSA signature value as a DER-encoded ASN.1 structure [default= ``r||s``].
use constant PSS_SALTLEN_HLEN => 0x000000;  #: RSA-PSS only: Set the salt length to hLen, the length of the output of the hash function [default].
use constant PSS_SALTLEN_MAX => 0x200000;   #: RSA-PSS only: Set the salt length to the maximum possible (like OpenSSL).
use constant PSS_SALTLEN_20 => 0x300000;    #: RSA-PSS only: Set the salt length to be exactly 20 bytes regardless of the hash algorithm.
use constant PSS_SALTLEN_ZERO => 0x400000;  #: RSA-PSS only: Set the salt length to be zero.
use constant MGF1SHA1 => 0x800000;  #: RSA-PSS only: Force the MGF hash function to be SHA-1 [default = same as signature hash algorithm].

# Encoding options
use constant BASE64    => 0;   #: Base64 encoding (default)
use constant HEX       => 0x30000;  #: Hexadecimal encoding
use constant BASE64URL => 0x40000;  #: URL-safe base64 encoding as in section 5 of [RFC4648]

# Local constants
use constant _USE_DIGEST => 0x1000;
use constant _SIGNATURE_ERROR => -22;

=head1 SignData function

Compute a signature value over binary data.

=head2 Synopsis

  $s = Dipki::Sig::SignData($data, $prikeyfile, $password, $sigalg [, $sigopts, $sigenc]);

=head2 Parameters

=over 4

=item $data

Data to be signed.

=item $prikeyfile

Private key file (or string containing key in PEM format).

=item $password

Password for private key (use C<""> if no password).

=item $sigalg

Signature algorithm.

=item $sigopts

Options for signature (optional).

=item $sigenc

Encoding for signature output (optional). Default is base64.

=back

=head2 Example

  use Dipki;
  $s = Dipki::Sig::SignData($data, 'AlicePrivRSASign.p8e', "password", Dipki::Sig::RSA_SHA256);

=cut

sub SignData {
	croak "Missing input parameter" if (scalar(@_) < 4);
	my ($data) = shift;
	my ($prikeyfile) = shift;
	my ($password) = shift;
	my ($sigalg) = shift;
	my ($sigopts) = shift || 0x0;
	my ($sigenc) = shift || 0x0;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "SIG_SignData", "PnPnPPPn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $flags = $sigopts | $sigenc;
	my $nc = $dllfunc->Call("", 0, $data, length($data), $prikeyfile, $password, $sigalg, $flags);
	croak Dipki::Err::FormatErrorMessage($nc) if $nc <= 0;
	my $buf = " " x ($nc+1);
	$nc = $dllfunc->Call($buf, $nc, $data, length($data), $prikeyfile, $password, $sigalg, $flags);
	return substr($buf, 0, $nc);
}

=head1 SignDigest function

Compute a signature value over a message digest value.

=head2 Example

  use Dipki;
  $s = Dipki::Sig::SignDigest(Dipki::Cnv::FromBase64("ZZ8hkDeug1S+bd4IZiPVQLCTtLg13mJ7/E7i8muYFd4="), 'AlicePrivRSASign.p8e', "password", Dipki::Sig::RSA_SHA256);

=cut

sub SignDigest {
	croak "Missing input parameter" if (scalar(@_) < 4);
	my ($digest) = shift;
	my ($prikeyfile) = shift;
	my ($password) = shift;
	my ($sigalg) = shift;
	my ($sigopts) = shift || 0x0;
	my ($sigenc) = shift || 0x0;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "SIG_SignData", "PnPnPPPn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $flags = _USE_DIGEST | $sigopts | $sigenc;
	my $nc = $dllfunc->Call("", 0, $digest, length($digest), $prikeyfile, $password, $sigalg, $flags);
	croak Dipki::Err::FormatErrorMessage($nc) if $nc <= 0;
	my $buf = " " x ($nc+1);
	$nc = $dllfunc->Call($buf, $nc, $digest, length($digest), $prikeyfile, $password, $sigalg, $flags);
	return substr($buf, 0, $nc);
}

=head1 SignFile function

Compute a signature value over binary data in a file. 

=head2 Example

  use Dipki;
  $s = Dipki::Sig::SignFile($fname, 'AlicePrivRSASign.p8e', "password", Dipki::Sig::RSA_SHA256);

=cut

sub SignFile {
	croak "Missing input parameter" if (scalar(@_) < 4);
	my ($datafile) = shift;
	my ($prikeyfile) = shift;
	my ($password) = shift;
	my ($sigalg) = shift;
	my ($sigopts) = shift || 0x0;
	my ($sigenc) = shift || 0x0;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "SIG_SignFile", "PnPPPPn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $flags = $sigopts | $sigenc;
	my $nc = $dllfunc->Call("", 0, $datafile, $prikeyfile, $password, $sigalg, $flags);
	croak Dipki::Err::FormatErrorMessage($nc) if $nc <= 0;
	my $buf = " " x ($nc+1);
	$nc = $dllfunc->Call($buf, $nc, $datafile, $prikeyfile, $password, $sigalg, $flags);
	return substr($buf, 0, $nc);
}

=head1 VerifyData function

Verify a signature value over data in a byte array.

=head2 Syntax

  $f =  Dipki::Sig::VerifyData($sigval, $data, $certorkeyfile, $sigalg [, $verifyopts]);

=head2 Returns

True (1) if the signature is valid, False (0) if invalid.

=cut
sub VerifyData {
	croak "Missing input parameter" if (scalar(@_) < 4);
	my ($sigval) = shift;
	my ($data) = shift;
	my ($certorkeyfile) = shift;
	my ($sigalg) = shift;
	my ($verifyopts) = shift || 0x0;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "SIG_VerifyData", "PPnPPn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $flags = $verifyopts;
	my $n = $dllfunc->Call($sigval, $data, length($data), $certorkeyfile, $sigalg, $flags);
	return 0 if _SIGNATURE_ERROR == $n;	# FALSE
	croak Dipki::Err::FormatErrorMessage($n) if $n != 0;
	return 1;	# TRUE
}

=head1 VerifyDigest function

Verify a signature value over a message digest value of data.

=head2 Syntax

  $f =  Dipki::Sig::VerifyDigest($sigval, $digest, $certorkeyfile, $sigalg [, $verifyopts]);

=head2 Returns

True (1) if the signature is valid, False (0) if invalid.

=cut
sub VerifyDigest {
	croak "Missing input parameter" if (scalar(@_) < 4);
	my ($sigval) = shift;
	my ($digest) = shift;
	my ($certorkeyfile) = shift;
	my ($sigalg) = shift;
	my ($verifyopts) = shift || 0x0;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "SIG_VerifyData", "PPnPPn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $flags = _USE_DIGEST | $verifyopts;
	my $n = $dllfunc->Call($sigval, $digest, length($digest), $certorkeyfile, $sigalg, $flags);
	return 0 if _SIGNATURE_ERROR == $n;	# FALSE
	croak Dipki::Err::FormatErrorMessage($n) if $n != 0;
	return 1;	# TRUE
}

=head1 VerifyFile function

Verify a signature value over data in a file. 

=head2 Syntax

  $f =  Dipki::Sig::VerifyFile($sigval, $datafile, $certorkeyfile, $sigalg [, $verifyopts]);

=head2 Returns

True (1) if the signature is valid, False (0) if invalid.

=cut
sub VerifyFile {
	croak "Missing input parameter" if (scalar(@_) < 4);
	my ($sigval) = shift;
	my ($datafile) = shift;
	my ($certorkeyfile) = shift;
	my ($sigalg) = shift;
	my ($verifyopts) = shift || 0x0;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "SIG_VerifyFile", "PPPPn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $flags = $verifyopts;
	my $n = $dllfunc->Call($sigval, $datafile, $certorkeyfile, $sigalg, $flags);
	return 0 if _SIGNATURE_ERROR == $n;	# FALSE
	croak Dipki::Err::FormatErrorMessage($n) if $n != 0;
	return 1;	# TRUE
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
