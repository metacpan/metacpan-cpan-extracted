#!/bin/echo This is a perl module and should not be run

package Meta::Projects::Movie::Participant;

use strict qw(vars refs subs);
use Meta::Class::DBI qw();
use base qw();

our($VERSION,@ISA);
$VERSION="0.01";
@ISA=qw(Meta::Class::DBI);

#sub BEGIN();
#sub TEST($);

#__DATA__

sub BEGIN() {
	base::import(__PACKAGE__,"Meta::Class::DBI");
	__PACKAGE__->table('participant');
	__PACKAGE__->columns('Primary'=>'id');
	__PACKAGE__->columns(All=>qw/id person movie role/);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Projects::Movie::Participant - Participant table OO wrapper for the movie project.

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

	MANIFEST: Participant.pm
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	package foo;
	use Meta::Projects::Movie::Participant qw();
	my($object)=Meta::Projects::Movie::Participant->new();
	my($result)=$object->method();

=head1 DESCRIPTION

Participant table OO wrapper for the movie project.

=head1 FUNCTIONS

	BEGIN()
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Standard DBI wrapper.

=item B<TEST($)>

This is a testing suite for the Meta::Projects::Movie::Participant module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

=back

=head1 SUPER CLASSES

Meta::Class::DBI(3)

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

Meta::Class::DBI(3), base(3), strict(3)

=head1 TODO

Nothing.
