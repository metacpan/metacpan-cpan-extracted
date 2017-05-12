#!/bin/echo This is a perl module and should not be run

package Meta::Db::User;

use strict qw(vars refs subs);
use Meta::Ds::Connected qw();
use Meta::Class::MethodMaker qw();

our($VERSION,@ISA);
$VERSION="0.37";
@ISA=qw(Meta::Ds::Connected);

#sub BEGIN();
#sub printd($$);
#sub printx($$);
#sub getsql_create($$$);
#sub getsql_drop($$$);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->get_set(
		-java=>"_name",
		-java=>"_description",
		-java=>"_password",
		-java=>"_func",
		-java=>"_tabs",
		-java=>"_host",
	);
	Meta::Class::MethodMaker->print(
		[
			"name",
			"description",
			"password",
			"func",
			"tabs",
			"host",
		]
	);
}

sub printd($$) {
	my($self,$writ)=@_;
	$writ->startTag("para");
	$writ->characters("name is [".$self->get_name()."].");
	$writ->characters("description is [".$self->get_description()."].");
	$writ->characters("password is [".$self->get_password()."].");
	$writ->characters("func is [".$self->get_func()."].");
	$writ->characters("tabs is [".$self->get_tabs()."].");
	$writ->characters("host is [".$self->get_host()."].");
	$writ->endTag("para");
}

sub printx($$) {
	my($self,$writ)=@_;
	$writ->startTag("user");
	$writ->dataElement("name",$self->get_name());
	$writ->dataElement("description",$self->get_description());
	$writ->dataElement("password",$self->get_password());
	$writ->dataElement("func",$self->get_func());
	$writ->dataElement("tabs",$self->get_tabs());
	$writ->dataElement("host",$self->get_host());
	$writ->endTag("user");
}

sub getsql_create($$$) {
	my($self,$stats,$info)=@_;
}

sub getsql_drop($$$) {
	my($self,$stats,$info)=@_;
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Db::User - Object to store a definition for a database user.

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
	VERSION: 0.37

=head1 SYNOPSIS

	package foo;
	use Meta::Db::User qw();
	my($user)=Meta::Db::User->new();
	$user->set_name($name);
	$user->set_password($name);

=head1 DESCRIPTION

This is an object to store a definition for a database user and all of its
permisitons.

=head1 FUNCTIONS

	BEGIN()
	printd($$)
	printx($$)
	getsql_create($$$)
	getsql_drop($$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This creates accessor methods for the following attributes:
"name", "description", "password", "func", "tabs", "host".
name - name of the user.
description - intended role for this database user.
password - database password for this user.
func - which types of functions is the user allowed to perform.
tabs - what tables does the user control.
host - from which hosts is the connection allowed.

This also sets up the following methods:
1. print - prints out the object.

=item B<printd($$)>

This will print the current object in XML DocBook format using the a writer
object received.

=item B<printx($$)>

This will print the current object in XML format using the a writer
object received.

=item B<getsql_create($$$)>

This method receives a User object and a statement collection and add to
that statement collection a list of statements needed to create this object
over an SQL connection.

=item B<getsql_drop($$$)>

This method receives a User object and a statement collection and add to
that statement collection a list of statements needed to drop this object
over an SQL connection.

=item B<TEST($)>

Test suite for this object.

=back

=head1 SUPER CLASSES

Meta::Ds::Connected(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV get the databases to work
	0.01 MV ok. This is for real
	0.02 MV make quality checks on perl code
	0.03 MV more perl checks
	0.04 MV check that all uses have qw
	0.05 MV fix todo items look in pod documentation
	0.06 MV more on tests/more checks to perl
	0.07 MV fix all tests change
	0.08 MV change new methods to have prototypes
	0.09 MV perl code quality
	0.10 MV more perl quality
	0.11 MV more perl quality
	0.12 MV perl documentation
	0.13 MV more perl quality
	0.14 MV perl qulity code
	0.15 MV more perl code quality
	0.16 MV revision change
	0.17 MV cook updates
	0.18 MV languages.pl test online
	0.19 MV history change
	0.20 MV db stuff
	0.21 MV more data sets
	0.22 MV perl packaging
	0.23 MV db inheritance
	0.24 MV PDMT
	0.25 MV some chess work
	0.26 MV md5 project
	0.27 MV database
	0.28 MV perl module versions in files
	0.29 MV movies and small fixes
	0.30 MV more thumbnail stuff
	0.31 MV thumbnail user interface
	0.32 MV more thumbnail issues
	0.33 MV website construction
	0.34 MV web site development
	0.35 MV web site automation
	0.36 MV SEE ALSO section fix
	0.37 MV md5 issues

=head1 SEE ALSO

Meta::Class::MethodMaker(3), Meta::Ds::Connected(3), strict(3)

=head1 TODO

-put all the permissions in here.

-do the actual granting of permissions to users (and removing them).
