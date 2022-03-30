package Dipki::Hmac;
use strict;
use warnings;
use Win32::API;
use Carp qw(croak carp);

use Exporter qw(import);
our @EXPORT_OK = qw(Data HexFromData
	SHA1 SHA224 SHA256 SHA384 SHA512 MD5
);

=head1 NAME

Dipki::Hmac - Compute keyed-hash based message authentication code (HMAC) values. 

=cut

# Local constants
use constant SHA1   => 0;  #: SHA-1 (default)
use constant SHA224 => 6;  #: SHA-224
use constant SHA256 => 3;  #: SHA-256
use constant SHA384 => 4;  #: SHA-384
use constant SHA512 => 5;  #: SHA-512
use constant MD5    => 1;  #: MD5 (as per RFC 1321)

=head1 Data function

Compute a keyed-hash based message authentication code (HMAC) as a byte array from bytes data.

=head2 Synopsis

  $h = Dipki::Hmac::Data($data, $key, $alg);

=cut
sub Data {
	croak "Missing input parameter" if (scalar(@_) < 2);
	my ($data) = shift;
    my ($key) = shift;
	my ($alg) = shift || 0;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "HMAC_Bytes", "PnPnPnn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $flags = $alg;
	my $nb = $dllfunc->Call("", 0, $data, length($data), $key, length($key), $flags);
	croak Dipki::Err::FormatErrorMessage($nb) if $nb < 0;
	return "" if $nb == 0;
	my $buf = " " x ($nb);
	$nb = $dllfunc->Call($buf, $nb, $data, length($data), $key, length($key), $flags);
	return substr($buf, 0, $nb);
}


=head1 HexFromData function

Compute message digest in hexadecimal format from binary data

=head2 Synopsis

  $s = Dipki::Hash::HexFromData($data, $alg);

=cut

sub HexFromData  {
	croak "Missing input parameter" if (scalar(@_) < 2);
	my ($data) = shift;
    my ($key) = shift;
	my ($alg) = shift || 0;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "HMAC_HexFromBytes", "PnPnPnn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $nc = $dllfunc->Call("", 0, $data, length($data), $key, length($key), $alg);
	croak Dipki::Err::FormatErrorMessage($nc) if $nc < 0;
	return "" if $nc == 0;
	my $buf = " " x ($nc+1);
	$nc = $dllfunc->Call($buf, $nc, $data, length($data), $key, length($key), $alg);
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
