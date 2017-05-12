#!/bin/echo This is a perl module and should not be run

package Meta::Init;

use strict qw(vars refs subs);
#use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.00";
@ISA=qw();

#sub BEGIN();
#sub TEST($);

#__DATA__

sub BEGIN() {
	#$Error::Debug=1;
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Init - perform various initialization tasks.

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

	MANIFEST: Init.pm
	PROJECT: meta
	VERSION: 0.00

=head1 SYNOPSIS

	package foo;
	use Meta::Init qw();

=head1 DESCRIPTION

This module performs system wide initializations. This includes setting
global variables for stuff beyond our control, changing environment
variables etc...

Currently it just configures Error.pm to print stack trace with thrown
errors.

=head1 FUNCTIONS

	BEGIN()
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This is where the action for this module takes place as there are no other
methods/functions in this module that the user is supposed to call.

=item B<TEST($)>

This is a testing suite for the Meta::Init module.
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

strict(3)

=head1 TODO

Nothing.
