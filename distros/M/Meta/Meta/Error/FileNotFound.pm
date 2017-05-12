#!/bin/echo This is a perl module and should not be run

package Meta::Error::FileNotFound;

use strict qw(vars refs subs);
use Meta::Error::Root qw();

our($VERSION,@ISA);
$VERSION="0.00";
@ISA=qw(Meta::Error::Root);

#sub TEST($);

#__DATA__

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Error::FileNotFound - Meta file not found errors.

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

	MANIFEST: FileNotFound.pm
	PROJECT: meta
	VERSION: 0.00

=head1 SYNOPSIS

	package foo;
	use Meta::Error::FileNotFound qw();
	my($object)=Meta::Error::FileNotFound->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This class extends the functionality of Error::FileNotFound. Currently it
does nothing extra.

=head1 FUNCTIONS

	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

Meta::Error::Root(3)

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

Meta::Error::Root(3), strict(3)

=head1 TODO

Nothing.
