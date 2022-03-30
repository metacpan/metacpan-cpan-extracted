package Dipki::Rng;
use strict;
use warnings;
use Win32::API;
use Carp qw(croak carp);

use Exporter qw(import);
our @EXPORT_OK = qw(Bytes Number Octet Guid Initialise);

=head1 NAME

Dipki::Rng - Random Number Generator to NIST SP800-90. 

=cut

sub Bytes {
	croak "Missing input parameter" if (scalar(@_) < 1);
	my ($n) = shift;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "RNG_Bytes", "PnPn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $buf = " " x ($n);
	$n = $dllfunc->Call($buf, $n, "", 0);
	return $buf;
}

sub Number {
	croak "Missing input parameter" if (scalar(@_) < 2);
	my ($lower) = shift;
	my ($upper) = shift;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "RNG_Number", "nn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $n = $dllfunc->Call($lower, $upper);
	return $n;
}

sub Octet {
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "RNG_Number", "nn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $n = $dllfunc->Call(0, 255);
	return $n;
}

sub Guid {
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "RNG_Guid", "Pnn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $nc = $dllfunc->Call("", 0, 0);
	return "" if $nc <= 0;
	my $buf = " " x ($nc+1);
	$nc = $dllfunc->Call($buf, $nc, 0);
	return $buf;
}

sub Initialise {
	croak "Missing input parameter" if (scalar(@_) < 1);
	my ($seedfile) = shift;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "RNG_Initialize", "Pn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $n = $dllfunc->Call($seedfile, 0);
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
