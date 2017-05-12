#!/bin/echo This is a perl module and should not be run

package Meta::Db::Fields;

use strict qw(vars refs subs);
use Meta::Ds::Ochash qw();
use Meta::Ds::Connected qw();

our($VERSION,@ISA);
$VERSION="0.34";
@ISA=qw(Meta::Ds::Ochash Meta::Ds::Connected);

#sub printd($$);
#sub printx($$);
#sub getsql_create($$$);
#sub getsql_drop($$$);
#sub getsql_add_multiple($$$);
#sub getsql_names($$);
#sub getsql_add($$);
#sub getsql_select($$);
#sub getsql_insert($$);
#sub TEST($);

#__DATA__

sub printd($$) {
	my($self,$writ)=@_;
	for(my($i)=0;$i<$self->size();$i++) {
		$writ->startTag("row");
		my($curr)=$self->elem($i);
		$curr->printd($writ);
		$writ->endTag("row");
	}
}

sub printx($$) {
	my($self,$writ)=@_;
	if($self->size()>0) {
		$writ->startTag("fields");
		for(my($i)=0;$i<$self->size();$i++) {
			$self->elem($i)->printx($writ);
		}
		$writ->endTag("fields");
	}
}

sub getsql_create($$$) {
	my($self,$stats,$info)=@_;
	for(my($i)=0;$i<$self->size();$i++) {
		my($curr)=$self->elem($i);
		$curr->getsql_create($stats,$info);
	}
}

sub getsql_drop($$$) {
	my($self,$stats,$info)=@_;
	for(my($i)=0;$i<$self->size();$i++) {
		my($curr)=$self->elem($i);
		$curr->getsql_drop($stats,$info);
	}
}

sub getsql_add_multiple($$$) {
	my($self,$stats,$info)=@_;
	for(my($i)=0;$i<$self->size();$i++) {
		my($curr)=$self->elem($i);
		$curr->getsql_add_multiple($stats,$info);
	}
}

sub getsql_names($$) {
	my($self,$info)=@_;
	my(@arra);
	for(my($i)=0;$i<$self->size();$i++) {
		my($curr)=$self->elem($i);
		push(@arra,$curr->getsql_names($info));
	}
	return(join(",",@arra));
}

sub getsql_add($$) {
	my($self,$info)=@_;
	my(@arra);
	for(my($i)=0;$i<$self->size();$i++) {
		my($curr)=$self->elem($i);
		push(@arra,$curr->getsql_add($info));
	}
	return(join(",",@arra));
}

sub getsql_select($$) {
	my($self,$info)=@_;
	my(@arra);
	for(my($i)=0;$i<$self->size();$i++) {
		my($curr)=$self->elem($i);
		push(@arra,$curr->get_name());
	}
	return(join(",",@arra));
}

sub getsql_insert($$) {
	my($self,$info)=@_;
	my(@arra);
	for(my($i)=0;$i<$self->size();$i++) {
		push(@arra,"?");
	}
	return(join(",",@arra));
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Db::Fields - Object to store a hash of Enum objects for a database.

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

	MANIFEST: Fields.pm
	PROJECT: meta
	VERSION: 0.34

=head1 SYNOPSIS

	package foo;
	use Meta::Db::Fields qw();
	my($enums)=Meta::Db::Fields->new();
	my($user)=$users->get("mark");

=head1 DESCRIPTION

This is an object to store a list of Field objects for a database.

=head1 FUNCTIONS

	printd($$)
	printx($$)
	getsql_create($$$)
	getsql_drop($$$)
	getsql_add_multiple($$$)
	getsql_names($$)
	getsql_add($$)
	getsql_select($$)
	getsql_insert($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<printd($$)>

This will print the current object in SGML format.

=item B<printx($$)>

This will print the current object in XML format.

=item B<getsql_create($$$)>

This method will add SQL statements to a received statement list which are
needed to create these fields in the database.

=item B<getsql_drop($$$)>

This method will add SQL statements to a received statement list which are
needed to drop these fields in the database.

=item B<getsql_add_multiple($$$)>

This method will add each field on its own.

=item B<getsql_names($$)>

This method will return an SQL description which is good for things like
CREATE TABLE of the entire set of fields.

=item B<getsql_select($$)>

This method will retreive an SQL statement snipplet which is suitable for
inclusion in a "SELECT x0,x1,x2,...,xn from table;" statements.

=item B<getsql_insert($$)>

This method will retreive an SQL statement snipplet which is suitable for
inclusion in a "VALUES(?,?,?)" statement.

=item B<TEST($)>

Test suite for this object.

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

	0.00 MV ok. This is for real
	0.01 MV make quality checks on perl code
	0.02 MV more perl checks
	0.03 MV check that all uses have qw
	0.04 MV fix todo items look in pod documentation
	0.05 MV more on tests/more checks to perl
	0.06 MV fix all tests change
	0.07 MV change new methods to have prototypes
	0.08 MV perl code quality
	0.09 MV more perl quality
	0.10 MV more perl quality
	0.11 MV perl documentation
	0.12 MV get graph stuff going
	0.13 MV more perl quality
	0.14 MV perl qulity code
	0.15 MV more perl code quality
	0.16 MV revision change
	0.17 MV languages.pl test online
	0.18 MV db stuff
	0.19 MV xml data sets
	0.20 MV more data sets
	0.21 MV perl packaging
	0.22 MV PDMT
	0.23 MV some chess work
	0.24 MV md5 project
	0.25 MV database
	0.26 MV perl module versions in files
	0.27 MV movies and small fixes
	0.28 MV movie stuff
	0.29 MV thumbnail user interface
	0.30 MV more thumbnail issues
	0.31 MV website construction
	0.32 MV web site automation
	0.33 MV SEE ALSO section fix
	0.34 MV md5 issues

=head1 SEE ALSO

Meta::Ds::Connected(3), Meta::Ds::Ochash(3), strict(3)

=head1 TODO

-get insert is not implemented in the best way - improve it.
