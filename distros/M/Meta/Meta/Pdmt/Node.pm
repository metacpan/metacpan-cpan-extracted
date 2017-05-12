#!/bin/echo This is a perl module and should not be run

package Meta::Pdmt::Node;

use strict qw(vars refs subs);
use Meta::Class::MethodMaker qw();
use Meta::Utils::Output qw();

our($VERSION,@ISA);
$VERSION="0.12";
@ISA=qw();

#sub BEGIN();
#sub build($$);
#sub uptodate($$);
#sub mtime($);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->new("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_name",
	);
}

sub build($$) {
	my($self,$pdmt)=@_;
	throw Meta::Error::Simple("this build method must be over ridden");
	return(1);
}

sub uptodate($$) {
	my($self,$pdmt)=@_;
	throw Meta::Error::Simple("this uptodate method must be over ridden");
	return(1);
}

sub mtime($) {
	my($self)=@_;
	throw Meta::Error::Simple("this mtime method must be over ridden");
	return(1);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Pdmt::Node - A PDMT graph node.

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

	MANIFEST: Node.pm
	PROJECT: meta
	VERSION: 0.12

=head1 SYNOPSIS

	package foo;
	use Meta::Pdmt::Node qw();
	my($object)=Meta::Pdmt::Node->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This is a PDMT graph node. The node implements all the basic methods
that child nodes need to override.

Do not think of a node in PDMT as a file. Think of a node in PDMT
exactly as you think of this class: a collection of three things.
1. A method which knows how to build the node from it's ingredients.
2. A method which knows to tell if the node is up to date.
3. A method which reports the last modification time of the node.

You may rightly ask about why both the uptodate and the mtime functions
are needed. They are not. This class should be built as Node--TimeNode.
The mtime stuff should only be in the TimeNode. The reason that not
all nodes need the mtime stuff is that some nodes would rather just
always say thet they are up to date (primary source files are a good
example for that).

=head1 FUNCTIONS

	BEGIN()
	build($$)
	uptodate($$)
	mtime($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This is an initializer for the class. It takes care for a:
1. default constructor for the class.
2. accessor get_ set_ methods for the attribute name.

=item B<build($$)>

This method actually builds a node. In this generic node it does nothing
and must be overriden in inherited classes.

=item B<uptodate($$)>

This method should return whether the file is uptodate.
This method should be overriden by inherited classes.

=item B<mtime($)>

This method should return the modification date of this node.
This method should be overriden by inherited classes.

=item B<TEST($)>

Test suite for this module.
Currently this does nothing.

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

	0.00 MV spelling and papers
	0.01 MV perl packaging
	0.02 MV md5 project
	0.03 MV database
	0.04 MV perl module versions in files
	0.05 MV movies and small fixes
	0.06 MV thumbnail user interface
	0.07 MV more thumbnail issues
	0.08 MV website construction
	0.09 MV web site automation
	0.10 MV SEE ALSO section fix
	0.11 MV teachers project
	0.12 MV md5 issues

=head1 SEE ALSO

Meta::Class::MethodMaker(3), Meta::Utils::Output(3), strict(3)

=head1 TODO

Nothing.
