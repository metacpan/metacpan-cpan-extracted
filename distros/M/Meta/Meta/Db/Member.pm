#!/bin/echo This is a perl module and should not be run

package Meta::Db::Member;

use strict qw(vars refs subs);
use Meta::Ds::Connected qw();

our($VERSION,@ISA);
$VERSION="0.13";
@ISA=qw(Meta::Ds::Connected);

#sub BEGIN();
#sub new($);
#sub printd($$);
#sub printx($$);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Class::MethodMaker->get_set(
		-java=>"_name",
		-java=>"_description",
	);
}

sub new($) {
	my($class)=@_;
	my($self)=Meta::Ds::Connected->new();
	bless($self,$class);
	return($self);
}

sub printd($$) {
	my($self,$writ)=@_;
	$writ->startTag("row");
	$writ->dataElement("entry",$self->get_name());
	$writ->dataElement("entry",$self->get_description());
	$writ->endTag("row");
}

sub printx($$) {
	my($self,$writ)=@_;
	$writ->startTag("member");
	$writ->dataElement("name",$self->get_name());
	$writ->dataElement("description",$self->get_description());
	$writ->endTag("member");
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Db::Member - Enum or Set member.

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

	MANIFEST: Member.pm
	PROJECT: meta
	VERSION: 0.13

=head1 SYNOPSIS

	package foo;
	use Meta::Db::Member qw();
	my($object)=Meta::Db::Member->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This is an object to encapsulate an enumeration or set member for a database
definition. It has a name and a description.

=head1 FUNCTIONS

	BEGIN()
	new($)
	printd($$)
	printx($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This method will create the get/set method for the following attributes:
"name", "description".

=item B<new($)>

A constructor for this class.

=item B<printd($$)>

This method will print the current member in SGML format.

=item B<printx($$)>

This method will print the current member in XML format.

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

	0.00 MV db stuff
	0.01 MV perl packaging
	0.02 MV PDMT
	0.03 MV some chess work
	0.04 MV md5 project
	0.05 MV database
	0.06 MV perl module versions in files
	0.07 MV movies and small fixes
	0.08 MV thumbnail user interface
	0.09 MV more thumbnail issues
	0.10 MV website construction
	0.11 MV web site automation
	0.12 MV SEE ALSO section fix
	0.13 MV md5 issues

=head1 SEE ALSO

Meta::Ds::Connected(3), strict(3)

=head1 TODO

Nothing.
