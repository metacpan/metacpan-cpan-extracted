#!/bin/echo This is a perl module and should not be run

package Meta::Db::Enum;

use strict qw(vars refs subs);
use Meta::Ds::Ochash qw();
use Meta::Ds::Connected qw();

our($VERSION,@ISA);
$VERSION="0.36";
@ISA=qw(Meta::Ds::Ochash Meta::Ds::Connected);

#sub BEGIN();
#sub new($);
#sub print($$);
#sub printd($$);
#sub printx($$);
#sub getsql_create($$$);
#sub getsql_drop($$$);
#sub get_string($);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Class::MethodMaker->get_set(
		-java=>"_name",
		-java=>"_description",
		-java=>"_default",
	);
}

sub new($) {
	my($class)=@_;
	my($self)=Meta::Ds::Ochash->new();
	bless($self,$class);
	return($self);
}

sub print($$) {
	my($self,$file)=@_;
	print $file "enum name is [".$self->get_name()."]\n";
	print $file "enum description is [".$self->get_description()."]\n";
	print $file "enum default is [".$self->get_default()."]\n";
	print $file "enum members are [".$self->size()."]\n";
}

sub printd($$) {
	my($self,$writ)=@_;
	$writ->startTag("formalpara");
	$writ->startTag("title");
	$writ->characters("The ");
	$writ->dataElement("database",$self->get_name());
	$writ->characters(" enumeration");
	$writ->endTag("title");
	$writ->startTag("para");
	$writ->characters($self->get_description());
	$writ->startTag("table","frame"=>"all");
	$writ->dataElement("title","Enumeration members");
	$writ->startTag("tgroup","cols"=>2);
	$writ->startTag("thead");
	$writ->startTag("row");
	$writ->dataElement("entry","Name");
	$writ->dataElement("entry","Description");
	$writ->endTag("row");
	$writ->endTag("thead");
	$writ->startTag("tbody");
	for(my($i)=0;$i<$self->size();$i++) {
		$self->elem($i)->printd($writ);
	}
	$writ->endTag("tbody");
	$writ->endTag("tgroup");
	$writ->endTag("table");
	$writ->endTag("para");
	$writ->endTag("formalpara");
}

sub printx($$) {
	my($self,$writ)=@_;
	$writ->startTag("enum");
	$writ->dataElement("name",$self->get_name());
	$writ->dataElement("description",$self->get_description());
	$writ->dataElement("default",$self->get_default());
	$writ->startTag("members");
	for(my($i)=0;$i<$self->size();$i++) {
		$self->elem($i)->printx($writ);
	}
	$writ->endTag("members");
	$writ->endTag("enum");
}

sub getsql_create($$$) {
	my($self,$stats,$info)=@_;
}

sub getsql_drop($$$) {
	my($self,$stats,$info)=@_;
}

sub get_string($) {
	my($self)=@_;
	my($resu)="";
	for(my($i)=0;$i<$self->size();$i++) {
		$resu.="\"".$self->elem($i)->get_name()."\"";
		if($i<$self->size()-1) {
			$resu.=",";
		}
	}
	return($resu);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Db::Enum - Object to store enumeration data.

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

	MANIFEST: Enum.pm
	PROJECT: meta
	VERSION: 0.36

=head1 SYNOPSIS

	package foo;
	use Meta::Db::Enum qw();
	my($pieces)=Meta::Db::Enum->new();
	$pieces->push("Pawn");
	$pieces->push("Rook");
	$pieces->push("Knight");
	$pieces->push("Bishop");
	$pieces->push("King");
	$pieces->push("Queen");

=head1 DESCRIPTION

This is an object to store a the definition for an enumeration type.

=head1 FUNCTIONS

	BEGIN()
	new($)
	print($$)
	printd($$)
	printx($$)
	getsql_create($$$)
	getsql_drop($$$)
	get_string($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Create get/set methods for the following attributes:
"name", "description", "default".
name - name for this enumerated type.
description - description of this enumerated type.
default - default value for this enumerated type.

=item B<new($)>

A constructor for this class.

=item B<print($$)>

This will print the current enum value to the prescribed file.

=item B<printd($$)>

This method will print the object in DocBook XML format using the a writer
object received.

=item B<printx($$)>

This will print the current object in XML DocBook format using the a writer
object received.

=item B<getsql_create($$$)>

This method receives an Enum object and a statement collection and add to
that statement collection a list of statements needed to create this object
over an SQL connection.

=item B<getsql_drop($$$)>

This method receives an Enum object and a statement collection and add to
that statement collection a list of statements needed to drop this object
over an SQL connection.

=item B<get_string($)>

This will give you a string which catenates all the members with ",".

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
	0.02 MV ok - this time I realy mean it
	0.03 MV c++ and perl code quality checks
	0.04 MV make quality checks on perl code
	0.05 MV more perl checks
	0.06 MV check that all uses have qw
	0.07 MV fix todo items look in pod documentation
	0.08 MV more on tests/more checks to perl
	0.09 MV fix all tests change
	0.10 MV change new methods to have prototypes
	0.11 MV perl code quality
	0.12 MV more perl quality
	0.13 MV more perl quality
	0.14 MV perl documentation
	0.15 MV get graph stuff going
	0.16 MV more perl quality
	0.17 MV perl qulity code
	0.18 MV more perl code quality
	0.19 MV revision change
	0.20 MV languages.pl test online
	0.21 MV history change
	0.22 MV db stuff
	0.23 MV more data sets
	0.24 MV perl packaging
	0.25 MV PDMT
	0.26 MV some chess work
	0.27 MV md5 project
	0.28 MV database
	0.29 MV perl module versions in files
	0.30 MV movies and small fixes
	0.31 MV thumbnail user interface
	0.32 MV more thumbnail issues
	0.33 MV website construction
	0.34 MV web site automation
	0.35 MV SEE ALSO section fix
	0.36 MV md5 issues

=head1 SEE ALSO

Meta::Ds::Connected(3), Meta::Ds::Ochash(3), strict(3)

=head1 TODO

-descripbe the default in the SGML output
