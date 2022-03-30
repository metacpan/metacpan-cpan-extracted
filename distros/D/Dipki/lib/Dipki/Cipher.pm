package Dipki::Cipher;
use strict;
use warnings;
use Win32::API;
use Carp qw(croak carp);

use Exporter qw(import);
our @EXPORT_OK = qw(TDEA AES128 AES192 AES256 BlockBytes KeyBytes Encrypt Decrypt);

=head1 NAME

Dipki::Cipher - Generic Block Cipher functions. 

=cut

# Alg
use constant TDEA => 0x10;  #: Triple DES (3DES, des-ede3)
use constant AES128 => 0x20;  #: AES-128
use constant AES192 => 0x30;  #: AES-192
use constant AES256 => 0x40;  #: AES-256

# Mode
use constant ECB => 0;      #: Electronic Code Book mode (default)
use constant CBC => 0x100;  #: Cipher Block Chaining mode
use constant OFB => 0x200;  #: Output Feedback mode
use constant CFB => 0x300;  #: Cipher Feedback mode
use constant CTR => 0x400;  #: Counter mode

# Padding
use constant NOPAD        => 0x10000;  #: No padding is added
use constant PKCS5        => 0x20000;  #: Padding scheme in PKCS#5/#7
use constant ONEANDZEROES => 0x30000;  #: Pad with 0x80 followed by as many zero bytes necessary to fill the block
use constant ANSIX923     => 0x40000;  #: Padding scheme in ANSI X9.23
use constant W3C          => 0x50000;  #: Padding scheme in W3C XMLENC

# AEAD algs
use constant AES_128_GCM => 0x520;  #: Use the AEAD_AES_128_GCM authenticated encryption algorithm from RFC 5116.
use constant AES_192_GCM => 0x530;  #: Use the AES-192-GCM authenticated encryption algorithm in the same manner as RFC 5116.
use constant AES_256_GCM => 0x540;  #: Use the AEAD_AES_256_GCM authenticated encryption algorithm from RFC 5116.

# Opts
use constant PREFIXIV => 0x1000;  #:  Prepend the IV before the ciphertext in the output (ignored for ECB mode)

# Internal lookup (NB use commas here, not fat commas, as we want the integer value of the constants)
my %_blocksize = (TDEA, 8, AES128, 16, AES192, 16, AES256, 16);
my %_keysize = (TDEA, 24, AES128, 16, AES192, 24, AES256, 32);

=head1 BlockBytes function

Return the block size in bytes for a given cipher algorithm.

=head2 Example

  use Dipki;
  say Dipki::Cipher::BlockBytes(Dipki::Cipher::AES256);
  # 16

=cut
sub BlockBytes {
	croak "Missing input parameter" if (scalar(@_) < 1);
	my $alg = shift;
	return $_blocksize{$alg};
}

=head1 KeyBytes function

Return the key size in bytes for a given cipher algorithm.

=head2 Example

  use Dipki;
  say Dipki::Cipher::KeyBytes(Dipki::Cipher::AES256);
  # 32

=cut
sub KeyBytes {
	croak "Missing input parameter" if (scalar(@_) < 1);
	my $alg = shift;
	return $_keysize{$alg};
}

=head1 Encrypt function

Encrypt data in a byte array using the specified block cipher algorithm, mode and padding.

=head2 Synopsis

  $ct = Dipki::Cipher::Encrypt($data, $key, $iv, $algmodepad[, $opts]);

=cut
=head2 Parameters

=over 4

=item $data

Data to be encrypted.

=item $prikeyfile

Key of exact length for block cipher algorithm  (see L<Cipher::KeyBytes>).

=item $iv

Initialization Vector (IV) of exactly the block size (see L<Cipher::BlockBytes>) or C<""> for ECB mode.

=item $algmodepad

 String containing the block cipher algorithm, mode and padding, e.g. C<"Aes128/CBC/OneAndZeroes">.
 Alternatively, set $algmodepad as C<""> and use option flags for Alg, Mode and Padding in the $opts parameter.

=item $opts

Options. Add Cipher::PREFIXIV to prepend the IV to the output.

=back

=head2 Example

  use Dipki;
  $ct = Dipki::Cipher::Encrypt($pt, $key, $iv, "Aes128/CBC/OneAndZeroes", Dipki::Cipher::PREFIXIV);
  $ct = Dipki::Cipher::Encrypt($pt, $key, $iv, "", Dipki::Cipher::AES128 | Dipki::Cipher::CBC | Dipki::Cipher::ONEANDZEROES | Dipki::Cipher::PREFIXIV);

=cut
sub Encrypt {
	croak "Missing input parameter" if (scalar(@_) < 4);
	my ($data) = shift;
	my ($key) = shift;
	my ($iv) = shift;
	my ($algstr) = shift;
	my ($opts) = shift || 0;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "CIPHER_EncryptBytes", "PnPnPnPnPn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $nb = $dllfunc->Call(0, 0, $data, length($data), $key, length($key), $iv, length($iv), $algstr, $opts);
	croak Dipki::Err::FormatErrorMessage($nb) if $nb < 0;
	my $buf = " " x ($nb);
	$nb = $dllfunc->Call($buf, $nb, $data, length($data), $key, length($key), $iv, length($iv), $algstr, $opts);
	return $buf;
}

=head1 Decrypt function

Decrypt data in a byte array using the specified block cipher algorithm, mode and padding.

=head2 Synopsis

  $pt = Dipki::Cipher::Decrypt($data, $key, $iv, $algmodepad[, $opts]);

=cut
sub Decrypt {
	croak "Missing input parameter" if (scalar(@_) < 4);
	my ($data) = shift;
	my ($key) = shift;
	my ($iv) = shift;
	my ($algstr) = shift;
	my ($opts) = shift || 0;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "CIPHER_DecryptBytes", "PnPnPnPnPn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $nb = $dllfunc->Call(0, 0, $data, length($data), $key, length($key), $iv, length($iv), $algstr, $opts);
	croak Dipki::Err::FormatErrorMessage($nb) if $nb < 0;
	my $buf = " " x ($nb);
	$nb = $dllfunc->Call($buf, $nb, $data, length($data), $key, length($key), $iv, length($iv), $algstr, $opts);
	return $buf;
}

=head1 EncryptBlock function

Encrypt a block of data using a block cipher. 

=head2 Synopsis

  $ct = Dipki::Cipher::EncryptBlock($data, $key, $iv, $alg, $mode);

=head2 Notes

Input data must be an exact multiple of block length for ECB and CBC mode. 
Output is always the same length as the input.

=cut
sub EncryptBlock {
	croak "Missing input parameter" if (scalar(@_) < 5);
	my ($data) = shift;
	my ($key) = shift;
	my ($iv) = shift;
	my ($alg) = shift;
	my ($mode) = shift;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "CIPHER_EncryptBytes", "PnPnPnPnPn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $flags = $alg | $mode | NOPAD;
	my $nb = length($data);
	my $buf = " " x ($nb);
	$nb = $dllfunc->Call($buf, $nb, $data, length($data), $key, length($key), $iv, length($iv), "", $flags);
	croak Dipki::Err::FormatErrorMessage($nb) if $nb < 0;
	return $buf;
}

=head1 DecryptBlock function

Decrypt a block of data using a block cipher. 

=head2 Synopsis

  $pt = Dipki::Cipher::DecryptBlock($data, $key, $iv, $alg, $mode);

=head2 Notes

Input data must be an exact multiple of block length for ECB and CBC mode. 
Output is always the same length as the input.

=cut
sub DecryptBlock {
	croak "Missing input parameter" if (scalar(@_) < 5);
	my ($data) = shift;
	my ($key) = shift;
	my ($iv) = shift;
	my ($alg) = shift;
	my ($mode) = shift;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "CIPHER_DecryptBytes", "PnPnPnPnPn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $flags = $alg | $mode | NOPAD;
	my $nb = length($data);
	my $buf = " " x ($nb);
	$nb = $dllfunc->Call($buf, $nb, $data, length($data), $key, length($key), $iv, length($iv), "", $flags);
	croak Dipki::Err::FormatErrorMessage($nb) if $nb < 0;
	return $buf;
}

=head1 KeyWrap function

Wrap (encrypt) key material with a key-encryption key. 

=head2 Synopsis

  $wk = Dipki::Cipher::KeyWrap($data, $kek, $alg);

=cut
sub KeyWrap {
	croak "Missing input parameter" if (scalar(@_) < 3);
	my ($data) = shift;
	my ($kek) = shift;
	my ($alg) = shift;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "CIPHER_KeyWrap", "PnPnPnn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $nb = $dllfunc->Call(0, 0, $data, length($data), $kek, length($kek), $alg);
	croak Dipki::Err::FormatErrorMessage($nb) if $nb < 0;
	my $buf = " " x ($nb);
	$nb = $dllfunc->Call($buf, $nb, $data, length($data), $kek, length($kek), $alg);
	return $buf;
}

=head1 KeyUnwrap function

Unwrap (decrypt) key material with a key-encryption key. 

=head2 Synopsis

  $k = Dipki::Cipher::KeyUnwrap($data, $kek, $alg);

=cut
sub KeyUnwrap {
	croak "Missing input parameter" if (scalar(@_) < 3);
	my ($data) = shift;
	my ($kek) = shift;
	my ($alg) = shift;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "CIPHER_KeyUnwrap", "PnPnPnn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $nb = $dllfunc->Call(0, 0, $data, length($data), $kek, length($kek), $alg);
	croak Dipki::Err::FormatErrorMessage($nb) if $nb < 0;
	my $buf = " " x ($nb);
	$nb = $dllfunc->Call($buf, $nb, $data, length($data), $kek, length($kek), $alg);
	return $buf;
}

=head1 EncryptAEAD function

Encrypt data using the AES-GCM authenticated encryption algorithm. 

=head2 Synopsis

  $wk = Dipki::Cipher::EncryptAEAD($data, $key, $iv, $aeadalg[, $opts, $aad]);

=head2 NOTE

Note order of arguments with optional parameter $add last after $opts.

=cut
sub EncryptAEAD {
	croak "Missing input parameter" if (scalar(@_) < 4);
	my ($input) = shift;
	my ($key) = shift;
	my ($iv) = shift;
	my ($aeadalg) = shift;
	my ($opts) = shift || 0x0;
	my ($aad) = shift || "";
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "CIPHER_EncryptAEAD", "PnPnPnPnPnn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $flags = $aeadalg | $opts;
	my $nb = $dllfunc->Call(0, 0, $input, length($input), $key, length($key), $iv, length($iv), $aad, length($aad), $flags);
	croak Dipki::Err::FormatErrorMessage($nb) if $nb < 0;
	my $buf = " " x ($nb);
	$nb = $dllfunc->Call($buf, $nb, $input, length($input), $key, length($key), $iv, length($iv), $aad, length($aad), $flags);
	return $buf;
}

=head1 DecryptAEAD function

Decrypt data using the AES-GCM authenticated encryption algorithm. 

=head2 Synopsis

  $wk = Dipki::Cipher::DecryptAEAD($data, $key, $iv, $aeadalg[, $opts, $aad]);

=cut
sub DecryptAEAD {
	croak "Missing input parameter" if (scalar(@_) < 4);
	my ($input) = shift;
	my ($key) = shift;
	my ($iv) = shift;
	my ($aeadalg) = shift;
	my ($opts) = shift || 0x0;
	my ($aad) = shift || "";
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "CIPHER_DecryptAEAD", "PnPnPnPnPnn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $flags = $aeadalg | $opts;
	my $nb = $dllfunc->Call(0, 0, $input, length($input), $key, length($key), $iv, length($iv), $aad, length($aad), $flags);
	croak Dipki::Err::FormatErrorMessage($nb) if $nb < 0;
	my $buf = " " x ($nb);
	$nb = $dllfunc->Call($buf, $nb, $input, length($input), $key, length($key), $iv, length($iv), $aad, length($aad), $flags);
	return $buf;
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
