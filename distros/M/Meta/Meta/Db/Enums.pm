#!/bin/echo This is a perl module and should not be run

package Meta::Db::Enums;

use strict qw(vars refs subs);
use Meta::Ds::Ochash qw();
use Meta::Ds::Connected qw();

our($VERSION,@ISA);
$VERSION="0.39";
@ISA=qw(Meta::Ds::Ochash Meta::Ds::Connected);

#sub printd($$);
#sub printx($$);
#sub getsql_create($$$);
#sub getsql_drop($$$);
#sub getsql_clean($$$);
#sub TEST($);

#__DATA__

sub printd($$) {
	my($self,$writ)=@_;
	$writ->dataElement("title","Enumerations");
	$writ->startTag("para");
	if($self->size()>0) {
		$writ->startTag("itemizedlist");
		for(my($i)=0;$i<$self->size();$i++) {
			$writ->startTag("listitem");
			$self->elem($i)->printd($writ);
			$writ->endTag("listitem");
		}
		$writ->endTag("itemizedlist");
	} else {
		$writ->characters("No enums are defined for this database");
	}
	$writ->endTag("para");
}

sub printx($$) {
	my($self,$writ)=@_;
	if($self->size()>0) {
		$writ->startTag("enums");
		for(my($i)=0;$i<$self->size();$i++) {
			$self->elem($i)->printx($writ);
		}
		$writ->endTag("enums");
	}
}

sub getsql_create($$$) {
	my($self,$stats,$info)=@_;
	for(my($i)=0;$i<$self->size();$i++) {
		$self->elem($i)->getsql_create($stats,$info);
	}
}

sub getsql_drop($$$) {
	my($self,$stats,$info)=@_;
	for(my($i)=0;$i<$self->size();$i++) {
		$self->elem($i)->getsql_drop($stats,$info);
	}
}

sub getsql_clean($$$) {
	my($self,$stats,$info)=@_;
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Db::Enums - Object to store a hash of Enum objects for a database.

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

	MANIFEST: Enums.pm
	PROJECT: meta
	VERSION: 0.39

=head1 SYNOPSIS

	package foo;
	use Meta::Db::Enums qw();
	my($enums)=Meta::Db::Enums->new();
	my($user)=$enums->get("Pieces");

=head1 DESCRIPTION

This is an object to store a list of Enum objects for a database.

=head1 FUNCTIONS

	printd($$)
	printx($$)
	getsql_create($$$)
	getsql_drop($$$)
	getsql_clean($$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<printd($$)>

This method will print the object in DocBook XML format using a writer
object received.

=item B<printx($$)>

This method will print the object in XML format through the a writer 
object received.

=item B<getsql_create($$$)>

This method receives a Enums object and a collection of Sql statements.
The method adds to that collection SQL statements to create this set of
enums.

=item B<getsql_drop($$$)>

This method receives a Enums object and a collection of Sql statements.
The method adds to that collection SQL statements to drop this set of
enums.

=item B<getsql_clean($$$)>

This method receives a Enums object and a collection of Sql statements.
The method adds to that collection SQL statements to clean this set of
enums.
Since the Enums object doesn't need any cleaning, this method does
nothing.

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

	0.00 MV this time really make the databases work
	0.01 MV ok. This is for real
	0.02 MV make quality checks on perl code
	0.03 MV more perl checks
	0.04 MV check that all uses have qw
	0.05 MV fix todo items look in pod documentation
	0.06 MV more on tests/more checks to perl
	0.07 MV fix all tests change
	0.08 MV change new methods to have prototypes
	0.09 MV perl code quality
	0.10 MV more perl quality
	0.11 MV more perl quality
	0.12 MV perl documentation
	0.13 MV get graph stuff going
	0.14 MV more perl quality
	0.15 MV perl qulity code
	0.16 MV more perl code quality
	0.17 MV revision change
	0.18 MV cook updates
	0.19 MV pictures in docbooks
	0.20 MV revision in files
	0.21 MV languages.pl test online
	0.22 MV history change
	0.23 MV db stuff
	0.24 MV more data sets
	0.25 MV spelling and papers
	0.26 MV perl packaging
	0.27 MV PDMT
	0.28 MV some chess work
	0.29 MV md5 project
	0.30 MV database
	0.31 MV perl module versions in files
	0.32 MV movies and small fixes
	0.33 MV movie stuff
	0.34 MV thumbnail user interface
	0.35 MV more thumbnail issues
	0.36 MV website construction
	0.37 MV web site automation
	0.38 MV SEE ALSO section fix
	0.39 MV md5 issues

=head1 SEE ALSO

Meta::Ds::Connected(3), Meta::Ds::Ochash(3), strict(3)

=head1 TODO

Nothing.
