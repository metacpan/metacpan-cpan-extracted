#!/bin/echo This is a perl module and should not be run

package Meta::Ds::Container;

use strict qw(vars refs subs);
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.00";
@ISA=qw();

#sub first($);
#sub over($);
#sub next($);
#sub foreach($$);
#sub TEST($);

#__DATA__

sub first($) {
	throw Meta::Error::Simple("must be overwridden");
}

sub over($) {
	throw Meta::Error::Simple("must be overwridden");
}

sub next($) {
	throw Meta::Error::Simple("must be overwridden");
}

sub foreach($$) {
	my($self,$code)=@_;
	for(my($obj)=$self->first();!$obj->over();$obj->next()) {
		&$code($obj);
	}
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Ds::Container - base class for all container classes.

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

	MANIFEST: Container.pm
	PROJECT: meta
	VERSION: 0.00

=head1 SYNOPSIS

	package foo;
	use Meta::Ds::Container qw();
	my($object)=Meta::Ds::Container->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This class is meant to be derived from by container classes of all types.
This class gives you a few abstract methods to override and thus comply
with the container definition. The bonus is getting method which perform
combinations of the methods you supplied.

Let me give a few examples:
1. You implement first, over and next and get foreach for free.
2. You call validate and the user of your container can make
	your container make sure that every object inserted is
	of a certain type.
More ideas will surely follow.

=head1 FUNCTIONS

	first($)
	over($)
	next($)
	foreach($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<first($)>

Method to be overwridden to supply the first element in the container.

=item B<over($)>

Method to be overwridden to return whether were done iterating the container.

=item B<next($)>

Method to be overwridden to move to the next element in the container.

=item B<TEST($)>

This is a testing suite for the Meta::Ds::Container module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.
Currently this test suite does nothing.

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

	0.00 MV md5 issues

=head1 SEE ALSO

Error(3), strict(3)

=head1 TODO

Nothing.
