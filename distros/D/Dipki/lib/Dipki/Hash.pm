package Dipki::Hash;
use strict;
use warnings;
use Win32::API;
use Carp qw(croak carp);

use Exporter qw(import);
our @EXPORT_OK = qw(Data File HexFromData Double
	SHA1 SHA224 SHA256 SHA384 SHA512 MD5 RMD160 BTC160
);

=head1 NAME

Dipki::Hash - Message Digest Hash Functions. 

=cut

# Local constants
use constant SHA1   => 0;  #: SHA-1 (default)
use constant SHA224 => 6;  #: SHA-224
use constant SHA256 => 3;  #: SHA-256
use constant SHA384 => 4;  #: SHA-384
use constant SHA512 => 5;  #: SHA-512
use constant MD5    => 1;  #: MD5 (as per RFC 1321)
use constant RMD160 => 7;  #: RIPEMD-160
use constant BTC160 => 8;  #: RIPEMD-160 hash of a SHA-256 hash (C<RIPEMD160(SHA256(m))>)

=head1 Data function

Compute message digest as a byte array from bytes data

=head2 Synopsis

  $h = Dipki::Hash::Data($data, $alg);

=cut
sub Data {
	croak "Missing input parameter" if (scalar(@_) < 1);
	my ($data) = shift;
	my ($alg) = shift || 0;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "HASH_Bytes", "PnPnn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $flags = $alg;
	my $nb = $dllfunc->Call("", 0, $data, length($data), $flags);
	croak Dipki::Err::FormatErrorMessage($nb) if $nb < 0;
	return "" if $nb == 0;
	my $buf = " " x ($nb);
	$nb = $dllfunc->Call($buf, $nb, $data, length($data), $flags);
	return substr($buf, 0, $nb);
}

=head1 File function

Compute message digest of a binary file.

=head2 Synopsis

  $dig = Dipki::Hash::File($fname, $alg);

=cut
sub File {
	croak "Missing input parameter" if (scalar(@_) < 1);
	my ($fname) = shift;
	my ($alg) = shift || 0;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "HASH_File", "PnPn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $flags = $alg;
	my $nb = $dllfunc->Call("", 0, $fname, $flags);
	croak Dipki::Err::FormatErrorMessage($nb) if $nb < 0;
	return "" if $nb == 0;
	my $buf = " " x ($nb);
	$nb = $dllfunc->Call($buf, $nb, $fname, $flags);
	return substr($buf, 0, $nb);
}

=head1 HexFromData function

Compute message digest in hexadecimal format from binary data

=head2 Synopsis

  $s = Dipki::Hash::HexFromData($data, $alg);

=cut

sub HexFromData  {
	croak "Missing input parameter" if (scalar(@_) < 1);
	my ($data) = shift;
	my ($alg) = shift || 0;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "HASH_HexFromBytes", "PnPnn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $nc = $dllfunc->Call("", 0, $data, length($data), $alg);
	croak Dipki::Err::FormatErrorMessage($nc) if $nc < 0;
	return "" if $nc == 0;
	my $buf = " " x ($nc+1);
	$nc = $dllfunc->Call($buf, $nc, $data, length($data), $alg);
	return substr($buf, 0, $nc);
}

=head1 Double function

Compute double hash, i.e. hash of hash, in binary format from binary input.

=head2 Synopsis

  $dif = Dipki::Hash::Double($data, $alg);

=cut
sub Double {
	croak "Missing input parameter" if (scalar(@_) < 1);
	my ($data) = shift;
	my ($alg) = shift || 0;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "HASH_Bytes", "PnPnn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $_HASH_DOUBLE = 0x20000;
	my $flags = $alg | $_HASH_DOUBLE;
	my $nb = $dllfunc->Call("", 0, $data, length($data), $flags);
	croak Dipki::Err::FormatErrorMessage($nb) if $nb < 0;
	return "" if $nb == 0;
	my $buf = " " x ($nb);
	$nb = $dllfunc->Call($buf, $nb, $data, length($data), $flags);
	return substr($buf, 0, $nb);
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
