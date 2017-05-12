#!/bin/echo This is a perl module and should not be run

package Meta::Tool::Perl;

use strict qw(vars refs subs);
use Meta::Utils::File::Patho qw();

our($VERSION,@ISA);
$VERSION="0.00";
@ISA=qw();

#sub BEGIN();
#sub TEST($);

#__DATA__

our($tool_path);

sub BEGIN() {
	my($patho)=Meta::Utils::File::Patho->new_path();
	$tool_path=$patho->resolve("perl");
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Tool::Perl - run the perl interpreter for you.

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

	MANIFEST: Perl.pm
	PROJECT: meta
	VERSION: 0.00

=head1 SYNOPSIS

	package foo;
	use Meta::Tool::Perl qw();
	my($object)=Meta::Tool::Perl->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This module will help you to run the perl interpreter for you.
You could find out things like what is the search path of the
interpreter, where is the interpreter binary and what is
the version of the interpreter installed.

=head1 FUNCTIONS

	BEGIN()
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This is a bootstrap method to find the actual interpreter.

=item B<TEST($)>

This is a testing suite for the Meta::Tool::Perl module.
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

Meta::Utils::File::Patho(3), strict(3)

=head1 TODO

Nothing.
