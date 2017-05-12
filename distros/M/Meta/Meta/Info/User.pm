#!/bin/echo This is a perl module and should not be run

package Meta::Info::User;

use strict qw(vars refs subs);
use Meta::Xml::Parsers::User qw();
use Meta::Class::MethodMaker qw();

our($VERSION,@ISA);
$VERSION="0.04";
@ISA=qw();

#sub BEGIN();
#sub new_file($);
#sub new_modu($);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->new("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_name",
		-java=>"_firstname",
		-java=>"_surname",
		-java=>"_email",
		-java=>"_password",
	);
}

sub new_file($$) {
	my($class,$file)=@_;
	my($parser)=Meta::Xml::Parsers::User->new();
	$parser->parsefile($file);
	return($parser->get_result());
}

sub new_modu($) {
	my($class,$modu)=@_;
	return(&new_file($class,$modu->get_abs_path()));
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Info::User - object oriented user information.

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

	MANIFEST: User.pm
	PROJECT: meta
	VERSION: 0.04

=head1 SYNOPSIS

	package foo;
	use Meta::Info::User qw();
	my($object)=Meta::Info::User->new();
	my($result)=$object->set_name("mark");

=head1 DESCRIPTION

This class provides user information according to the users/DTD.

=head1 FUNCTIONS

	BEGIN()
	new_file($)
	new_modu($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This method builds the attribute access method for this class.
The attributes are:
0. "name" - name of the user (username).
1. "firstname" - first name of the user.
2. "surname" - sur name of the user.
3. "email" - email of the user.
4. "password" - password of the user.

=item B<new_file($)>

This method creates a new user object from a file.

=item B<new_modu($)>

This method creates a new user object from a development module.

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

	0.00 MV web site development
	0.01 MV web site automation
	0.02 MV SEE ALSO section fix
	0.03 MV teachers project
	0.04 MV md5 issues

=head1 SEE ALSO

Meta::Class::MethodMaker(3), Meta::Xml::Parsers::User(3), strict(3)

=head1 TODO

Nothing.
