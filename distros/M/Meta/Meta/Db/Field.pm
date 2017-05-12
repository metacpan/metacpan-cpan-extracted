#!/bin/echo This is a perl module and should not be run

package Meta::Db::Field;

use strict qw(vars refs subs);
use Meta::Ds::Connected qw();
use Meta::Db::Type qw();

our($VERSION,@ISA);
$VERSION="0.36";
@ISA=qw(Meta::Ds::Connected);

#sub BEGIN();
#sub new($);
#sub init($);
#sub get_type($);
#sub set_type($$);
#sub print($$);
#sub printd($$);
#sub printx($$);
#sub getsql_name($$);
#sub getsql_create($$$);
#sub getsql_drop($$$);
#sub getsql_add_multiple($$$);
#sub getsql_names($$);
#sub getsql_add($$);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Class::MethodMaker->get_set(
		-java=>"_name",
		-java=>"_description",
	);
}

sub new($) {
	my($class)=@_;
	my($self)=Meta::Ds::Connected->new();
	bless($self,$class);
	$self->init();
	return($self);
}

sub init($) {
	my($self)=@_;
	$self->set_type(Meta::Db::Type->new());
}

sub get_type($) {
	my($self)=@_;
	return($self->{TYPE});
}

sub set_type($$) {
	my($self,$type)=@_;
	$self->{TYPE}=$type;
	$type->set_container($self);
}

sub print($$) {
	my($self,$file)=@_;
	print $file "name is [".$self->get_name()."]\n";
	print $file "description is [".$self->get_description()."]\n";
	print $file "type is [".$self->get_type()->print($file)."]\n";
}

sub printd($$) {
	my($self,$writ)=@_;
	$writ->startTag("entry");
	$writ->dataElement("database",$self->get_name(),"class"=>"field");
	$writ->endTag("entry");
	$writ->dataElement("entry",$self->get_description());
	$self->get_type()->printd($writ);
}

sub printx($$) {
	my($self,$writ)=@_;
	$writ->startTag("field");
	$writ->dataElement("name",$self->get_name());
	$writ->dataElement("description",$self->get_description());
	$self->get_type()->printx($writ);
	$writ->endTag("field");
}

sub getsql_name($$) {
	my($self,$info)=@_;
	return($self->get_container()->get_container()->getsql_name($info).".".$self->get_name());
}

sub getsql_create($$$) {
	my($self,$stats,$info)=@_;
	$self->get_type()->getsql_create($stats,$info);
}

sub getsql_drop($$$) {
	my($self,$stats,$info)=@_;
	$self->get_type()->getsql_drop($stats,$info);
}

sub getsql_add_multiple($$$) {
	my($self,$stats,$info)=@_;
	my($stat)=Meta::Sql::Stat->new();
	$stat->set_text("ALTER TABLE ".$self->get_container()->get_container()->getsql_name($info)." ADD ".$self->get_name()." ".$self->get_type()->getsql_names($info));
	$stats->push($stat);
}

sub getsql_names($$) {
	my($self,$info)=@_;
	return($self->get_name()." ".$self->get_type()->getsql_names($info));
}

sub getsql_add($$) {
	my($self,$info)=@_;
	return("ADD ".$self->get_name()." ".$self->get_type()->getsql_names($info));
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Db::Field - Object to store a definition of a field in a database.

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

	MANIFEST: Field.pm
	PROJECT: meta
	VERSION: 0.36

=head1 SYNOPSIS

	package foo;
	use Meta::Db::Field qw();
	my($field)=Meta::Db::Field->new();
	$field->set("String");
	my($field)=Meta::Db::Field->new();
	$field->set("number",$field);

=head1 DESCRIPTION

This is an object to store the definition of a single field in the database
in. It will store the name of the field and its type as a 2-tuple.

=head1 FUNCTIONS

	BEGIN()
	new($)
	init($)
	get_type($)
	set_type($$)
	print($$)
	printd($$)
	printx($$)
	getsql_name($$)
	getsql_create($$$)
	getsql_drop($$$)
	getsql_add_multiple($$$)
	getsql_names($$)
	getsql_add($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This method creates the get/set methods for the following attributes:
"name", "description".
"type" is not auto created because of the connectivity features.

=item B<new($)>

Constructor for this class.

=item B<init($)>

This is an internal post constructor method.

=item B<get_type($)>

This gives you the type of the field.

=item B<set_type($$)>

This will set the type of the field for you.

=item B<print($$)>

This will print the current field for you.

=item B<printd($$)>

This method will print the object in DocBook XML format using a writer
object received.

=item B<printx($$)>

This method will print the object in XML format using a writer
object received.

=item B<getsql_name($$)>

This method will give you the fields full name (including the table and
database names...).

=item B<getsql_create($$$)>

This method will add SQL statements to a container of SQL statements which is
received which create this field entry in the database.

=item B<getsql_drop($$$)>

This method will add SQL statements to a container of SQL statements which is
received which drop this field entry in the database.

=item B<getsql_add_multiple($$$)>

This method will add a statement to add the specific field.

=item B<getsql_names($$)>

This method will return an SQL string which is suitable for things like
CREATE TABLE.

=item B<getsql_add($$)>

This methdd will return an SQL string which is suitable for things like
ALTER TABLE ADD d int; statements.

=item B<TEST($)>

Test suite for this object.

=back

=head1 SUPER CLASSES

Meta::Ds::Connected(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV initial code brought in
	0.01 MV bring databases on line
	0.02 MV ok. This is for real
	0.03 MV make quality checks on perl code
	0.04 MV more perl checks
	0.05 MV check that all uses have qw
	0.06 MV fix todo items look in pod documentation
	0.07 MV more on tests/more checks to perl
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
	0.18 MV languages.pl test online
	0.19 MV history change
	0.20 MV db stuff
	0.21 MV more data sets
	0.22 MV perl packaging
	0.23 MV db inheritance
	0.24 MV PDMT
	0.25 MV some chess work
	0.26 MV md5 project
	0.27 MV database
	0.28 MV perl module versions in files
	0.29 MV movies and small fixes
	0.30 MV movie stuff
	0.31 MV thumbnail user interface
	0.32 MV more thumbnail issues
	0.33 MV website construction
	0.34 MV web site automation
	0.35 MV SEE ALSO section fix
	0.36 MV md5 issues

=head1 SEE ALSO

Meta::Db::Type(3), Meta::Ds::Connected(3), strict(3)

=head1 TODO

Nothing.
