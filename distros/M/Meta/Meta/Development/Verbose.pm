#!/bin/echo This is a perl module and should not be run

package Meta::Development::Verbose;

use strict qw(vars refs subs);
use Meta::Class::MethodMaker qw();
use Meta::Utils::Output qw();

our($VERSION,@ISA);
$VERSION="0.02";
@ISA=qw();

#sub BEGIN($);
#sub verbose($$);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->new("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_verbose",
	);
}

sub verbose($$) {
	my($self,$string)=@_;
	Meta::Utils::Output::verbose($self->get_verbose(),$string);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Development::Verbose - object to inherit verbose objects from.

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

	MANIFEST: Verbose.pm
	PROJECT: meta
	VERSION: 0.02

=head1 SYNOPSIS

	package foo;
	use Meta::Development::Verbose qw();
	my($object)=Meta::Development::Verbose->new();
	$object->verbose("Hello, World!\n");

=head1 DESCRIPTION

Inherit objects from this one and you get get/set verbose methods
and a method "verbose" which prints the string given to it
only if verbose is turned on.

The idea is to not write this kind of method again and again
in every object which is a drag and to make the code more
readable (not full of remarks).

=head1 FUNCTIONS

	BEGIN()
	verbose($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This is a setup method for the class which sets up the get_verbose
and set_verbose methods.

=item B<verbose($$)>

Call this method to output some text only if the verbose flag
is turned on.

=item B<TEST($)>

This is a testing suite for the Meta::Development::Verbose module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

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

	0.00 MV move tests to modules
	0.01 MV bring movie data
	0.02 MV md5 issues

=head1 SEE ALSO

Meta::Class::MethodMaker(3), Meta::Utils::Output(3), strict(3)

=head1 TODO

-be able to set the verbosity flag on construction according to reading the option from some kind of data base/config file according to the class name which is actually being constructed.
