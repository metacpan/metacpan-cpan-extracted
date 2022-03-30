package Dipki::Gen;
use strict;
use warnings;
use Win32::API;

use Exporter qw(import);

our @EXPORT_OK = qw(Version ModuleName LicenceType Platform ModuleInfo CompileTime);

=head1 NAME

Dipki::Gen - General info about the core DLL. 

=cut

=head1 Version function

Get version number of the core native DLL as an integer value.

=cut
sub Version {
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "int PKI_Version()" );
	die "Error: $^E" if ! $dllfunc;
	my $ver = $dllfunc->Call();
	return $ver;
}

=head1 ModuleName function

Get full path name of the current process's core native DLL.

=cut
sub ModuleName {
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "PKI_ModuleName", "Pnn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $nc = $dllfunc->Call("", 0, 0);
	return "" if $nc <= 0;
	my $buf = " " x ($nc+1);
	$nc = $dllfunc->Call($buf, $nc, 0);
	return substr($buf, 0, $nc);
}

=head1 LicenceType function

Get licence type.

=cut
sub LicenceType {
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "PKI_LicenceType", "n", "i");
	die "Error: $^E" if ! $dllfunc;
	my $n = $dllfunc->Call(0);
	return chr($n);
}

=head1 Platform function

Get platform the core native DLL was compiled for.

=cut
sub Platform {
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "PKI_Platform", "Pn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $nc = $dllfunc->Call("", 0);
	return "" if $nc <= 0;
	my $buf = " " x ($nc+1);
	$nc = $dllfunc->Call($buf, $nc);
	return substr($buf, 0, $nc);
}

=head1 ModuleInfo function

Get information about the core module.

=cut
sub ModuleInfo {
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "PKI_ModuleInfo", "Pnn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $nc = $dllfunc->Call("", 0, 0);
	return "" if $nc <= 0;
	my $buf = " " x ($nc+1);
	$nc = $dllfunc->Call($buf, $nc, 0);
	return substr($buf, 0, $nc);
}

=head1 CompileTime function

Get date and time the core native DLL module was last compiled

=cut
sub CompileTime {
	my $dllfunc = Win32::API::More->new(
        "diCrPKI", "PKI_CompileTime", "Pn", "i");
	die "Error: $^E" if ! $dllfunc;
	my $nc = $dllfunc->Call("", 0);
	return "" if $nc <= 0;
	my $buf = " " x ($nc+1);
	$nc = $dllfunc->Call($buf, $nc);
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
