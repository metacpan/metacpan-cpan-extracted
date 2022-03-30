package Dipki::Err;
use strict;
use warnings;
use Win32::API;
use Carp qw(croak carp);

use Exporter qw(import);
our @EXPORT_OK = qw(ErrorLookup);

=head1 NAME

Dipki::Err - Details of errors returned by the core library. 

=head1 NOTE

Apart from C<ErrorLookup>, these only work internally. 

=cut

=head1 ErrorLookup function

Return a description of an error code. 

=head2 Parameters

=over 4

=item $errcode

Error code (required).

=back

=head2 Example

  use Dipki;
  $s = Dipki::Err::ErrorLookup(6);
  # Parameter is wrong or missing

=cut
sub ErrorLookup {
	croak "Missing input parameter" if (scalar(@_) < 1);
	my ($errcode) = shift;
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "PKI_ErrorLookup", "Pnn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $nc = $dllfunc->Call("", 0, $errcode);
	return "" if $nc <= 0;
	my $buf = " " x ($nc+1);
	$nc = $dllfunc->Call($buf, $nc, $errcode);
	return substr($buf, 0, $nc);
}

sub ErrorCode {
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "PKI_ErrorCode", "", "i");
	die "Error: $^E" if ! $dllfunc;
	my $r = $dllfunc->Call();
	return $r;
}

sub LastError {
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "PKI_LastError", "Pn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $nc = $dllfunc->Call("", 0);
	return "" if $nc <= 0;
	my $buf = " " x ($nc+1);
	$nc = $dllfunc->Call($buf, $nc);
	return substr($buf, 0, $nc);
}

sub FormatErrorMessage {
	my ($errcode) = shift || 0;
	my $errmsg = "";
	$errcode = -$errcode if ($errcode < 0);
	# Get last error, if available
	my $lasterror = LastError();
	my $lastcode = ErrorCode();
	# Return empty string if no error to report
	return "" if (0 == $errcode && $lastcode == 0 && length($lasterror) == 0);
	# Compose error message
	$errmsg = "ERROR";
	if ($errcode != 0) {
		$errmsg .= " ($errcode)";
	}
	# Get error message for code errcode
	my $error_lookup = ErrorLookup($errcode);
	if ($errcode != 0 && length($error_lookup) > 0) {
		$errmsg .= ": $error_lookup";
	}
	if ($lastcode != 0 && $errcode != $lastcode) {
		$errmsg .= ": " . ErrorLookup($lastcode);
	}
	# Append last error, if available
	if (length($lasterror) > 0) {
		$errmsg .= ": $lasterror";
	}
	return $errmsg;
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
