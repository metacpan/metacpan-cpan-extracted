#!/bin/echo This is a perl module and should not be run

package Meta::Info::Account;

use strict qw(vars refs subs);
use Meta::Class::MethodMaker qw();

our($VERSION,@ISA);
$VERSION="0.02";
@ISA=qw();

#sub BEGIN();
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->new("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_name",
		-java=>"_type",
		-java=>"_user",
		-java=>"_password",
		-java=>"_system_name",
		-java=>"_system_url",
		-java=>"_mail",
		-java=>"_url",
		-java=>"_directory",
		-java=>"_ssh",
	);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Info::Account - Store a single account information on a system.

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

	MANIFEST: Account.pm
	PROJECT: meta
	VERSION: 0.02

=head1 SYNOPSIS

	package foo;
	use Meta::Info::Account qw();
	my($object)=Meta::Info::Account->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This class stores the details of a single account on a system.
The details include the user name, password, email on the system
and other information.

=head1 FUNCTIONS

	BEGIN()
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Bootstrap method for the Account class to set up accessors for the following
attributes:
0. "name" - name of the account.
1. "type" - type of the account.
2. "user" - user name at the account.
3. "password" - password at the account.
4. "system_name" - name of the entire system.
5. "system_url" - url of the entire system.
6. "mail" - email at the account.
7. "url" - personal url at the account.
8. "directory" - personal directory at the account.
9. "ssh" - ssh url for ssh access to the account.

=item B<TEST($)>

This is a testing suite for the Meta::Info::Account module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

This test currently does nothing.

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

	0.00 MV finish papers
	0.01 MV teachers project
	0.02 MV md5 issues

=head1 SEE ALSO

Meta::Class::MethodMaker(3), strict(3)

=head1 TODO

Nothing.
