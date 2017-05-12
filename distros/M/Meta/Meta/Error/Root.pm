#!/bin/echo This is a perl module and should not be run

package Meta::Error::Root;

use strict qw(vars refs subs);
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.00";
@ISA=qw(Error::Simple);

#sub BEGIN();
#sub stringify($@);
#sub TEST($);

#__DATA__

sub BEGIN() {
	$Error::Debug=1;
}

sub stringify($@) {
	my($self,@args)=@_;
#	return(CORE::join("\n",$self->text(),$self->stacktrace(),@args));
	return($self->stacktrace());
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Error::Root - extend Error::Root.

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

	MANIFEST: Root.pm
	PROJECT: meta
	VERSION: 0.00

=head1 SYNOPSIS

	package foo;
	use Meta::Error::Root qw();
	my($object)=Meta::Error::Root->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This class extends the functionality of Error::Root. Currently it
does nothing extra.

=head1 FUNCTIONS

	BEGIN()
	stringify($@)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Provides initialization code which makes the Error.pm module run in debug mode.

=item B<stringify($@)>

Overloads the default stringify method to make errors more verbose.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

Error::Simple(3)

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

-make a base class in Meta for errors (Meta::Error::Root) and have this class inherit from it. move the stringify method to that class.
