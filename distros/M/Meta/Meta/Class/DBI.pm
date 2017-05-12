#!/bin/echo This is a perl module and should not be run

package Meta::Class::DBI;

use strict qw(vars refs subs);
use Class::DBI qw();
use base qw();

our($VERSION,@ISA);
$VERSION="0.01";
@ISA=qw(Class::DBI);

#sub BEGIN();
#sub set_connection($$);
#sub TEST($);

#__DATA__

#sub BEGIN() {
#	base::import(__PACKAGE__,"Class::DBI");
#}

sub set_connection($$) {
	my($connection,$dbname)=@_;
	__PACKAGE__->set_db(
		'Main',
		$connection->get_dsn($dbname),
		$connection->get_user(),
		$connection->get_password()
	);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Class::DBI - extend Class::DBI for more high level needs.

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

	MANIFEST: DBI.pm
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	package foo;
	use Meta::Class::DBI qw();
	my($object)=Meta::Class::DBI->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This class extends the CPAN Class::DBI code. The idea is to use more high
level object to configure Class::DBI (like object which already know
the structure of the database and the connection info). Currently the class
only implements the connection info configuration through the
Meta::Db::Connection class.

=head1 FUNCTIONS

	BEGIN()
	set_connection($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

=item B<set_connection($$)>

Static method to set the connection data. Works by calling set_db.

=item B<TEST($)>

This is a testing suite for the Meta::Class::DBI module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

=back

=head1 SUPER CLASSES

Class::DBI(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV download scripts
	0.01 MV md5 issues

=head1 SEE ALSO

Class::DBI(3), base(3), strict(3)

=head1 TODO

Nothing.
