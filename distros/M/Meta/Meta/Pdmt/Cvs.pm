#!/bin/echo This is a perl module and should not be run

package Meta::Pdmt::Cvs;

use strict qw(vars refs subs);
use Meta::Class::MethodMaker qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.01";
@ISA=qw();

#sub BEGIN();
#sub add_all_nodes($$);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->new("new");
}

sub add_all_nodes($$) {
	my($self,$graph)=@_;
	throw Meta::Error::Simple("this is an abstract method and should not be called");
	return(0);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Pdmt::Cvs - Pdmt abstract interface to your SCS.

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

	MANIFEST: Cvs.pm
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	package foo;
	use Meta::Pdmt::Cvs qw();
	my($object)=Meta::Pdmt::Cvs->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This class is an abstract interface that Pdmt uses to talk with the source
control system. It will evolve with time.

=head1 FUNCTIONS

	BEGIN()
	add_all_nodes($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Boot strap the class. Currently only create a default constructor.

=item B<add_all_nodes($$)>

This method will add all nodes that the source control management system
knows about to the pdmt system.

=item B<TEST($)>

This is a testing suite for the Meta::Pdmt::Cvs module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

Currently this test does nothing.

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

	0.00 MV teachers project
	0.01 MV md5 issues

=head1 SEE ALSO

Error(3), Meta::Class::MethodMaker(3), strict(3)

=head1 TODO

-use Class::MethodMaker and make the methods here abstract using it and save coding.
