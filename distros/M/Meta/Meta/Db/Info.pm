#!/bin/echo This is a perl module and should not be run

package Meta::Db::Info;

use strict qw(vars refs subs);

our($VERSION,@ISA);
$VERSION="0.11";
@ISA=qw();

#sub new($);
#sub get_type($);
#sub set_type($$);
#sub get_name($);
#sub set_name($$);
#sub is_postgres($);
#sub is_mysql($);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)={};
	$self->{TYPE}=defined;
	$self->{NAME}=defined;
	bless($self,$class);
	return($self);
}

sub get_type($) {
	my($self)=@_;
	return($self->{TYPE});
}

sub set_type($$) {
	my($self,$val)=@_;
	$self->{TYPE}=$val;
}

sub get_name($) {
	my($self)=@_;
	return($self->{NAME});
}

sub set_name($$) {
	my($self,$val)=@_;
	$self->{NAME}=$val;
}

sub is_postgres($) {
	my($self)=@_;
	return($self->get_type() eq "Pg");
}

sub is_mysql($) {
	my($self)=@_;
	return($self->get_type() eq "mysql");
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Db::Info - info class needed for SQL operations.

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

	MANIFEST: Info.pm
	PROJECT: meta
	VERSION: 0.11

=head1 SYNOPSIS

	package foo;
	use Meta::Db::Info qw();
	my($object)=Meta::Db::Info->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This class accompanies SQL operations and is needed by classes which implement SQL operations to be able to work accross different database (because of SQL incompatibilities between databases).

=head1 FUNCTIONS

	new($)
	get_type($)
	set_type($$)
	get_name($)
	set_name($$)
	is_postgres($)
	is_mysql($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This is a constructor for the Meta::Db::Info object.

=item B<get_type($)>

This method will retrieve the type of database accessed.

=item B<set_type($$)>

This will set the type of the database for you.

=item B<get_name($)>

This method will retrieve the name of database accessed.

=item B<set_name($$)>

This will set the name of the database for you.

=item B<is_postgres($)>

This method will return true iff the database is PostgreSQL.

=item B<is_mysql($)>

This method will return true IFF the database is MySQL.

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

	0.00 MV PDMT
	0.01 MV some chess work
	0.02 MV md5 project
	0.03 MV database
	0.04 MV perl module versions in files
	0.05 MV movies and small fixes
	0.06 MV thumbnail user interface
	0.07 MV more thumbnail issues
	0.08 MV website construction
	0.09 MV web site automation
	0.10 MV SEE ALSO section fix
	0.11 MV md5 issues

=head1 SEE ALSO

strict(3)

=head1 TODO

Nothing.
