package Dipki::Cnv;
use strict;
use warnings;
use Win32::API;
use Carp qw(croak carp);

use Exporter qw(import);
our @EXPORT_OK = qw(FromBase64 ToBase64 FromHex ToHex);

=head1 NAME

Dipki::Cnv - Character conversion routines. 

=head2 Notes

=over 4

=item C<Dipki::Cnv::ToHex($buf)> is equivalent to C<unpack('H*', $buf);>

=item C<Dipki::Cnv::FromHex($s)> is equivalent to C<pack('H*', $s);> but is more flexible.

=back

=cut

# EndianNess options
use constant BIG_ENDIAN    => 0x0;  #: Big-endian order (default)
use constant LITTLE_ENDIAN => 0x1;  #: Little-endian order


=head1 FromBase64 function

Decode a base64-encoded string into a byte array.

=head2 Warning

Whitespace characters are ignored, but other non-base64 characters will cause an error.

=cut
sub FromBase64 {
	croak "Missing input parameter" if (scalar(@_) < 1);
	my ($s) = shift;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "CNV_BytesFromB64Str", "PnP", "i");
	die "Error: $^E" if ! $dllfunc;
	my $nb = $dllfunc->Call(0, 0, $s);
	croak Dipki::Err::FormatErrorMessage($nb) if $nb < 0;
	return "" if $nb == 0;
	my $buf = " " x ($nb);
	$nb = $dllfunc->Call($buf, $nb, $s);
	return substr($buf, 0, $nb);
}

=head1 ToBase64 function

Encode binary data as a base64 string.

=cut
sub ToBase64 {
	croak "Missing input parameter" if (scalar(@_) < 1);
	my ($b) = shift;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "CNV_B64StrFromBytes", "PnPn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $nc = $dllfunc->Call("", 0, $b, length($b));
	croak Dipki::Err::FormatErrorMessage($nc) if $nc < 0;
	return "" if $nc == 0;
	my $buf = " " x ($nc+1);
	$nc = $dllfunc->Call($buf, $nc, $b, length($b));
	return substr($buf, 0, $nc);
}

=head1 FromHex function

Decode a hexadecimal-encoded string into a byte array

=head2 Warning

Whitespace and ASCII punctuation characters in the input are ignored, but other non-hex characters, e.g. [G-Zg-z], will cause an error.

=cut
sub FromHex {
	croak "Missing input parameter" if (scalar(@_) < 1);
	my ($s) = shift;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "CNV_BytesFromHexStr", "PnP", "i");
	die "Error: $^E" if ! $dllfunc;
	my $nb = $dllfunc->Call(0, 0, $s);
	croak Dipki::Err::FormatErrorMessage($nb) if $nb < 0;
	return "" if $nb == 0;
	my $buf = " " x ($nb);
	$nb = $dllfunc->Call($buf, $nb, $s);
	return substr($buf, 0, $nb);
}

=head1 ToHex function

Encode binary data as a hexadecimal string.

=cut
sub ToHex {
	croak "Missing input parameter" if (scalar(@_) < 1);
	my ($b) = shift;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "CNV_HexStrFromBytes", "PnPn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $nc = $dllfunc->Call("", 0, $b, length($b));
	croak Dipki::Err::FormatErrorMessage($nc) if $nc < 0;
	return "" if $nc == 0;
	my $buf = " " x ($nc+1);
	$nc = $dllfunc->Call($buf, $nc, $b, length($b));
	return substr($buf, 0, $nc);
}

=head1 ReverseBytes function

Reverse the order of a byte array.

=cut
sub ReverseBytes {
	croak "Missing input parameter" if (scalar(@_) < 1);
	my ($b) = shift;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "CNV_ReverseBytes", "PPn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $nb = length($b);
	my $buf = " " x ($nb);
	$dllfunc->Call($buf, $b, $nb);
	return $buf;
}

=head1 NumFromBytes function

Convert the leftmost four bytes of an array to a 32-bit integer.

=cut
sub NumFromBytes {
	croak "Missing input parameter" if (scalar(@_) < 1);
	my ($b) = shift;
	my ($endn) = shift || 0x0;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "CNV_NumFromBytes", "Pnn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $n = $dllfunc->Call($b, length($b), $endn);
	# Force number to be a positive 32-bit integer
	return $n & 0xFFFFFFFF;
}

=head1 NumToBytes function

Convert a 32-bit integer to an array of 4 bytes. 

=cut
sub NumToBytes {
	croak "Missing input parameter" if (scalar(@_) < 1);
	my ($num) = shift;
	my ($endn) = shift || 0x0;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "CNV_NumToBytes", "Pnnn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $nb = 4;
	my $buf = " " x ($nb);
	my $n = $dllfunc->Call($buf, $nb, ($num & 0xFFFFFFFF), $endn);
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
