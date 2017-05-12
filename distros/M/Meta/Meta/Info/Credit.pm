#!/bin/echo This is a perl module and should not be run

package Meta::Info::Credit;

use strict qw(vars refs subs);
use Meta::Class::MethodMaker qw();
use Meta::Ds::Array qw();

our($VERSION,@ISA);
$VERSION="0.06";
@ISA=qw();

#sub BEGIN();
#sub init($);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->new_with_init("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_author",
		-java=>"_items",
	);
}

sub init($) {
	my($self)=@_;
	$self->set_author(Meta::Info::Author->new());
	$self->set_items(Meta::Ds::Array->new());
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Info::Credit - credit information about a piece of work.

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

	MANIFEST: Credit.pm
	PROJECT: meta
	VERSION: 0.06

=head1 SYNOPSIS

	package foo;
	use Meta::Info::Credit qw();
	my($object)=Meta::Info::Credit->new();
	my($result)=$object->method();

=head1 DESCRIPTION

Whenever a group of people collaborate on a work then each has
done many things in the package. Look at the Linux kernel for
instance - it has many contributors and each contributor contributed
many things to the package. The idea is that you will have a perl
object which can store all of that information - meaning many
authors and each has many contribution. What can you do with
it ? Well - you can maintain it in an XML file (which is
more robust than maintaining it in a text file) and then:
1. print it as a chapter in Docbook.
2. convert it into VCARD which you can import into your email
	client.
3. find out who did something (search).
4. print it in various formats for various purposes.
5. send test emails to those emails periodically to make
	sure that all the authors are responsive.

=head1 FUNCTIONS

	BEGIN()
	init($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This is an initialization method which creates get/set methods
for these attributes:
author - the author involved.
items - the items this author is responsible for.

=item B<init($)>

This is an internal post-constructor method.

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

	0.00 MV import tests
	0.01 MV more thumbnail issues
	0.02 MV website construction
	0.03 MV web site development
	0.04 MV web site automation
	0.05 MV SEE ALSO section fix
	0.06 MV md5 issues

=head1 SEE ALSO

Meta::Class::MethodMaker(3), Meta::Ds::Array(3), strict(3)

=head1 TODO

Nothing.
