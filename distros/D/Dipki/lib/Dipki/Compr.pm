package Dipki::Compr;
use strict;
use warnings;
use Win32::API;
use Carp qw(croak carp);

use Exporter qw(import);
our @EXPORT_OK = qw(Compress Uncompress);

=head1 NAME

Dipki::Compr - Compression utilities.

=cut

=head1 Compress function

Compress data using zlib compression

=head2 Synopsis

  $pt = Dipki::Cipher::Compress($data);

=cut
sub Compress {
	croak "Missing input parameter" if (scalar(@_) < 1);
	my ($data) = shift;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "COMPR_Compress", "PnPnn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $flags = 0;
	my $nb = $dllfunc->Call("", 0, $data, length($data), $flags);
	croak Dipki::Err::FormatErrorMessage($nb) if $nb < 0;
	return "" if $nb == 0;
	my $buf = " " x ($nb);
	$nb = $dllfunc->Call($buf, $nb, $data, length($data), $flags);
	return substr($buf, 0, $nb);
}

=head1 Uncompress function

Uncompress data using zlib compression

=head2 Synopsis

  $pt = Dipki::Cipher::Uncompress($data);

=cut
sub Uncompress {
	croak "Missing input parameter" if (scalar(@_) < 1);
	my ($data) = shift;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "COMPR_Uncompress", "PnPnn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $flags = 0;
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
