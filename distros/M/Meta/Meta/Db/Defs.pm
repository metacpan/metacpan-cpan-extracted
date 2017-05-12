#!/bin/echo This is a perl module and should not be run

package Meta::Db::Defs;

use strict qw(vars refs subs);
use Meta::Ds::Ochash qw();
use Meta::Ds::Connected qw();

our($VERSION,@ISA);
$VERSION="0.01";
@ISA=qw(Meta::Ds::Ochash Meta::Ds::Connected);

#sub TEST($);

#__DATA__

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Db::Defs - a collection of database definitions.

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

	MANIFEST: Defs.pm
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	package foo;
	use Meta::Db::Defs qw();
	my($object)=Meta::Db::Defs->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This is a collection of database definitions.

=head1 FUNCTIONS

	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This is a constructor for the Meta::Db::Defs object.

=item B<method($)>

This is an object method.

=item B<TEST($)>

This is a testing suite for the Meta::Db::Defs module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

=back

=head1 SUPER CLASSES

Meta::Ds::Ochash(3), Meta::Ds::Connected(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV web site development
	0.01 MV md5 issues

=head1 SEE ALSO

Meta::Ds::Connected(3), Meta::Ds::Ochash(3), strict(3)

=head1 TODO

Nothing.
