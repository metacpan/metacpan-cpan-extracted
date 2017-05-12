#!/bin/echo This is a perl module and should not be run

package Meta::Info::Im;

use strict qw(vars refs subs);
use Meta::Class::MethodMaker qw();

our($VERSION,@ISA);
$VERSION="0.03";
@ISA=qw();

#sub BEGIN();
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->new("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_title",
		-java=>"_type",
		-java=>"_user",
		-java=>"_password",
		-java=>"_old_password",
		-java=>"_active",
		-java=>"_remark",
	);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Info::Im - Store a single system IM information for author.

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

	MANIFEST: Im.pm
	PROJECT: meta
	VERSION: 0.03

=head1 SYNOPSIS

	package foo;
	use Meta::Info::Im qw();
	my($object)=Meta::Info::Im->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This class stores the details of a single IM system a person is registered with.

=head1 FUNCTIONS

	BEGIN()
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Bootstrap method to set up accessors for the following attributes:
0. "title" - title for the IM address.
1. "type" - type of IM address.
2. "user" - user name of IM system.
3. "password" - password of IM system.
4. "old_password" - the old password of IM system.
5. "active" - is the address active.
6. "remark" - is the free text remark regarding the account.

=item B<TEST($)>

This is a testing suite for the Meta::Info::Im module.
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

	0.00 MV web site development
	0.01 MV finish papers
	0.02 MV teachers project
	0.03 MV md5 issues

=head1 SEE ALSO

Meta::Class::MethodMaker(3), strict(3)

=head1 TODO

Nothing.
