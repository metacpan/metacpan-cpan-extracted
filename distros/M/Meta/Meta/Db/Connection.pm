#!/bin/echo This is a perl module and should not be run

package Meta::Db::Connection;

use strict qw(vars refs subs);
use Meta::Class::MethodMaker qw();

our($VERSION,@ISA);
$VERSION="0.37";
@ISA=qw();

#sub BEGIN();
#sub is_postgres($);
#sub is_mysql($);
#sub get_dsn($$);
#sub get_dsn_nodb($);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->new("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_name",
		-java=>"_type",
		-java=>"_use_host",
		-java=>"_host",
		-java=>"_use_port",
		-java=>"_port",
		-java=>"_use_user",
		-java=>"_user",
		-java=>"_use_password",
		-java=>"_password",
		-java=>"_use_default_db",
		-java=>"_default_db",
		-java=>"_use_extra_options",
		-java=>"_extra_options",
	);
}

sub is_postgres($) {
	my($self)=@_;
	return($self->get_type() eq "Pg");
}

sub is_mysql($) {
	my($self)=@_;
	return($self->get_type() eq "mysql");
}

sub get_dsn($$) {
	my($self,$name)=@_;
	my(@elems);
	push(@elems,"dbi");
	push(@elems,$self->get_type());
	if($self->get_use_host()) {
		push(@elems,"host=".$self->get_host());
	}
	if($self->get_use_port()) {
		push(@elems,"port=".$self->get_port());
	}
	if($self->is_postgres()) {
		push(@elems,"dbname=".$name);
	}
	if($self->is_mysql()) {
		push(@elems,"database=".$name);
	}
	if($self->get_use_extra_options()) {
		push(@elems,$self->get_extra_options());
	}
	return(CORE::join(':',@elems));
}

sub get_dsn_nodb($) {
	my($self)=@_;
	return($self->get_dsn($self->get_default_db()));
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Db::Connection - Object to store a definition of a connection to a database.

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

	MANIFEST: Connection.pm
	PROJECT: meta
	VERSION: 0.37

=head1 SYNOPSIS

	package foo;
	use Meta::Db::Connection qw();
	my($connection)=Meta::Db::Connection->new();
	$connection->set_host("www.gnu.org");

=head1 DESCRIPTION

This object will store everything you need to know in order to get a
connection to the database.

=head1 FUNCTIONS

	BEGIN()
	is_postgres($)
	is_mysql($)
	get_dsn($$)
	get_dsn_nodb($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Instantiates basic accessors.
Here they are: "name","type","host","port","user","password".

=item B<is_postgres($)>

This method will return TRUE iff the connection object is a PosgreSQL database.

=item B<is_mysql($)>

This method will return TRUE iff the connection object is a MySQL database.

=item B<get_dsn($$)>

This method will return a DSN according to perl DBI/DBD to connect to a database.
Unfortunately - connections to different Dbs have different DSNs.

=item B<get_dsn_nodb($)>

This method will return a DSN according to perl DBI/DBD with no db (just host connection).

=item B<TEST($)>

Test suite for this object.

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

	0.00 MV bring databases on line
	0.01 MV get the databases to work
	0.02 MV convert all database descriptions to XML
	0.03 MV make quality checks on perl code
	0.04 MV more perl checks
	0.05 MV check that all uses have qw
	0.06 MV fix todo items look in pod documentation
	0.07 MV more on tests/more checks to perl
	0.08 MV change new methods to have prototypes
	0.09 MV perl code quality
	0.10 MV more perl quality
	0.11 MV chess and code quality
	0.12 MV more perl quality
	0.13 MV perl documentation
	0.14 MV more perl quality
	0.15 MV perl qulity code
	0.16 MV more perl code quality
	0.17 MV revision change
	0.18 MV languages.pl test online
	0.19 MV perl packaging
	0.20 MV PDMT
	0.21 MV some chess work
	0.22 MV more movies
	0.23 MV md5 project
	0.24 MV database
	0.25 MV perl module versions in files
	0.26 MV movies and small fixes
	0.27 MV thumbnail project basics
	0.28 MV thumbnail user interface
	0.29 MV more thumbnail issues
	0.30 MV website construction
	0.31 MV improve the movie db xml
	0.32 MV web site development
	0.33 MV web site automation
	0.34 MV SEE ALSO section fix
	0.35 MV move tests to modules
	0.36 MV download scripts
	0.37 MV md5 issues

=head1 SEE ALSO

Meta::Class::MethodMaker(3), strict(3)

=head1 TODO

-support more databases in get_dsn.

-limit type of databases in set_type.

-have a method that will print this object in XML (automatically via Meta::Class::MethodMaker).
