#!/bin/echo This is a perl module and should not be run

package Meta::Baseline::Test;

use strict qw(vars refs subs);
use Meta::Baseline::Aegis qw();
use Meta::Utils::Utils qw();
use XML::Simple qw();
use Meta::Utils::Output qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.32";
@ISA=qw();

#sub BEGIN();

#sub redirect_on();
#sub redirect_off();

#sub set_vars_for($$);

#sub get_user();
#sub get_password();
#sub get_host();
#sub get_domain();

#sub TEST($);

#__DATA__

our($config);

sub BEGIN() {
	my($file)=Meta::Baseline::Aegis::which("xmlx/configs/test.xml");
	$config=XML::Simple::XMLin($file);
}

sub redirect_on() {
	my($temp_stde)="/dev/null";
	my($temp_stdo)="/dev/null";
#	my($temp_stde)=Meta::Utils::Utils::get_file_temp();
#	my($temp_stdo)=Meta::Utils::Utils::get_file_temp();
	open(STDERR,"> ".$temp_stde) || throw Meta::Error::Simple("unable to redirect stderr to [".$temp_stdo."]");
	open(STDOUT,"> ".$temp_stdo) || throw Meta::Error::Simple("unable to redirect stdout to [".$temp_stde."]");
}

sub redirect_off() {
	close(STDERR) || throw Meta::Error::Simple("unable to close stderr");
	close(STDOUT) || throw Meta::Error::Simple("unable to close stdout");
#	Meta::Utils::File::rm($temp_stde);
#	Meta::Utils::File::rm($temp_stdo);
}

sub set_vars_for($$) {
	my($plat,$arch)=@_;
	my($list)=Meta::Baseline::Aegis::search_path_list();
	for(my($i)=0;$i<=$#$list;$i++) {
		$list->[$i].="/dlls/".$plat."/".$arch;
	}
	my($addx)=join(":",@$list);
	Meta::Utils::Env::add("LD_LIBRARY_PATH",":",$addx);
}

sub get_user() {
	return($config->{"config"}->{"user"}->{"value"});
}

sub get_password() {
	return($config->{"config"}->{"password"}->{"value"});
}

sub get_host() {
	return($config->{"config"}->{"host"}->{"value"});
}

sub get_domain() {
	return($config->{"config"}->{"domain"}->{"value"});
}

sub TEST($) {
	my($context)=@_;
	Meta::Utils::Output::print("user is [".Meta::Baseline::Test::get_user()."]\n");
	Meta::Utils::Output::print("password is [".Meta::Baseline::Test::get_password()."]\n");
	Meta::Utils::Output::print("host is [".Meta::Baseline::Test::get_host()."]\n");
	Meta::Utils::Output::print("domain is [".Meta::Baseline::Test::get_domain()."]\n");
	return(1);
}

1;

__END__

=head1 NAME

Meta::Baseline::Test - library to help you with testing.

=head1 COPYRIGHT

Copyright (C) 2001, 2002 Mark Veltzer;
All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111, USA.

=head1 DETAILS

	MANIFEST: Test.pm
	PROJECT: meta
	VERSION: 0.32

=head1 SYNOPSIS

	package foo;
	use Meta::Baseline::Test qw();
	Meta::Baseline::Test::redirect_on();

=head1 DESCRIPTION

SPECIAL STDERR FILE

This library is intended to give you services for writing nice testing
scripts for the system. Have fun.

=head1 FUNCTIONS

	BEGIN()
	redirect_on()
	redirect_off()
	set_vars_for($$)
	get_user()
	get_password()
	get_host()
	get_domain()
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This method inits the testing module by reading its XML configuration file.

=item B<redirect_on()>

This will block stdout and stderr output so tests wont be messy.

=item B<redirect_off()>

This will release the stdout and stderr blocks.

=item B<set_vars_for($$)>

This will set the LD_LIBRARY_PATH variable for running C++ code to the
given platform/architecture combination.

=item B<get_user()>

This method will return a user name of a user that can be abused in tests.

=item B<get_password()>

This method will return the password of the user which can be abused in tests.

=item B<get_host($)>

This method will return the hostname of a machine that can be abused in tests.

=item B<get_domain($)>

This method will return a valid domain name which can be used in tests.

=item B<TEST($)>

Test suite for this module.
Currently this method just prints out the various configuration variables.

=back

=head1 SUPER CLASSES

None.

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV initial code brought in
	0.01 MV make quality checks on perl code
	0.02 MV more perl checks
	0.03 MV check that all uses have qw
	0.04 MV fix todo items look in pod documentation
	0.05 MV more on tests/more checks to perl
	0.06 MV more perl quality
	0.07 MV cleanup tests change
	0.08 MV correct die usage
	0.09 MV perl code quality
	0.10 MV more perl quality
	0.11 MV more perl quality
	0.12 MV perl documentation
	0.13 MV more perl quality
	0.14 MV perl qulity code
	0.15 MV more perl code quality
	0.16 MV more perl quality
	0.17 MV revision change
	0.18 MV languages.pl test online
	0.19 MV perl packaging
	0.20 MV md5 project
	0.21 MV database
	0.22 MV perl module versions in files
	0.23 MV movies and small fixes
	0.24 MV thumbnail user interface
	0.25 MV more thumbnail issues
	0.26 MV website construction
	0.27 MV improve the movie db xml
	0.28 MV web site automation
	0.29 MV SEE ALSO section fix
	0.30 MV bring movie data
	0.31 MV teachers project
	0.32 MV md5 issues

=head1 SEE ALSO

Error(3), Meta::Baseline::Aegis(3), Meta::Utils::Output(3), Meta::Utils::Utils(3), XML::Simple(3), strict(3)

=head1 TODO

-turn this package to an object and use it as an object with an constructor
	which will read all data (user,host,connection) from an XML file.

-the redirection routines dont really work as they do not restore the old settings for stdout and stderr (what about STDLOG ?). fix that.

-make this module just hold a connection object which will be read from somewhere which describes a connection to a database which can be abused.

-make the redirection routine save the stderr and stdout to files and print them if something goes wrong.
