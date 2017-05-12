#!/bin/echo This is a perl module and should not be run

package Meta::Development::TestInfo;

use strict qw(vars refs subs);
use Meta::Class::MethodMaker qw();
use XML::Simple qw();
use Meta::Utils::Output qw();
use Meta::Development::Module qw();

our($VERSION,@ISA);
$VERSION="0.03";
@ISA=qw();

#sub new($);
#sub read($$);
#sub read_deve($$);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->new("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_user",
		-java=>"_password",
		-java=>"_host",
		-java=>"_domain",
		-java=>"_temp_directory",
	);
}

sub read($$) {
	my($self,$file)=@_;
	my($config)=XML::Simple::XMLin($file);
	$self->set_user($config->{"config"}->{"user"}->{"value"});
	$self->set_password($config->{"config"}->{"password"}->{"value"});
	$self->set_host($config->{"config"}->{"host"}->{"value"});
	$self->set_domain($config->{"config"}->{"domain"}->{"value"});
	$self->set_temp_directory($config->{"config"}->{"temp_directory"}->{"value"});
}

sub read_modu($$) {
	my($self,$modu)=@_;
	$self->read($modu->get_abs_path());
}

sub TEST($) {
	my($context)=@_;
	my($new_object)=__PACKAGE__->new();
	my($module)=Meta::Development::Module->new_name("xmlx/configs/test.xml");
	$new_object->read_modu($module);
	Meta::Utils::Output::dump($new_object);
	return(1);
}

1;

__END__

=head1 NAME

Meta::Development::TestInfo - provide information about the testing environment.

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

	MANIFEST: TestInfo.pm
	PROJECT: meta
	VERSION: 0.03

=head1 SYNOPSIS

	package foo;
	use Meta::Development::TestInfo qw();
	my($object)=Meta::Development::TestInfo->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This method will provide whatever information modules need in order to perform
testing. This could be a very wide array of information:
1. Valid user on the current machine.
2. Valid ftp site (host,user and password) on which ftp operations could be performed.
3. Temporary directory where temp files can be stored.
4. Http site from which to perform HTTP queries.
5. Access information to various databases.
6. Verbosity level while testing.
7. Depth of testing to be performed.
etc...

Feel free to add more information to this object as it becomes neccessary.

=head1 FUNCTIONS

	BEGIN()
	read($$)
	read_modu($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This method sets up accessor methods to the following attributes:
1. user
2. password
3. host
4. domain
5. mysqldsn
6. mysqluser
7. mysqlpass

=item B<read($$)>

This method reads the TestInfo object from an XML config file.
The method uses the XML::Simple parser to do it's work.

=item B<read_modu($$)>

This method is exactly like the above read method except the input
file is relative to the development system.

=item B<TEST($)>

Test suite for this module.

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

	0.00 MV web site automation
	0.01 MV SEE ALSO section fix
	0.02 MV teachers project
	0.03 MV md5 issues

=head1 SEE ALSO

Meta::Class::MethodMaker(3), Meta::Development::Module(3), Meta::Utils::Output(3), XML::Simple(3), strict(3)

=head1 TODO

Nothing.
