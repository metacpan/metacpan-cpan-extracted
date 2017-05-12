#!/bin/echo This is a perl module and should not be run

package Meta::Db::Table;

use strict qw(vars refs subs);
use Meta::Ds::Connected qw();
use Meta::Db::Fields qw();
use Meta::Db::Constraints qw();
use Meta::Class::MethodMaker qw();

our($VERSION,@ISA);
$VERSION="0.41";
@ISA=qw(Meta::Ds::Connected);

#sub BEGIN();
#sub new($);
#sub get_fields($);
#sub set_fields($$);
#sub get_constraints($);
#sub set_constraints($$);
#sub get_def($);
#sub print($$);
#sub printd($$);
#sub printx($$);
#sub getsql_create($$$);
#sub getsql_drop($$$);
#sub getsql_clean($$$);
#sub getsql_name($$);
#sub getsql_select($$);
#sub getsql_insert($$);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->get_set(
		-java=>"_name",
		-java=>"_description",
	);
}

sub new($) {
	my($class)=@_;
	my($self)=Meta::Ds::Connected->new();
	bless($self,$class);
	$self->set_fields(Meta::Db::Fields->new());
	$self->set_constraints(Meta::Db::Constraints->new());
	return($self);
}

sub get_fields($) {
	my($self)=@_;
	return($self->{FIELDS});
}

sub set_fields($$) {
	my($self,$val)=@_;
	$self->{FIELDS}=$val;
	$val->set_container($self);
}

sub get_constraints($) {
	my($self)=@_;
	return($self->{CONSTRAINTS});
}

sub set_constraints($$) {
	my($self,$val)=@_;
	$self->{CONSTRAINTS}=$val;
	$val->set_container($self);
}

sub get_def($) {
	my($self)=@_;
	return($self->get_container()->get_container());
}

sub print($$) {
	my($self,$file)=@_;
	print $file "table name is [".$self->get_name()."]\n";
	print $file "table description is [".$self->get_description()."]\n";
	$self->get_fields()->print($file);
	$self->get_constraints()->print($file);
}

sub printd($$) {
	my($self,$writ)=@_;
	$writ->startTag("formalpara");
	$writ->startTag("title");
	$writ->characters("The ");
	$writ->dataElement("database",$self->get_name(),"class"=>"table");
	$writ->characters(" table");
	$writ->endTag("title");
	$writ->startTag("para");
	$writ->characters($self->get_description());
	$writ->startTag("table","frame"=>"all");
	$writ->dataElement("title","Table fields");
	$writ->startTag("tgroup","cols"=>8);
	$writ->startTag("thead");
	$writ->startTag("row");
	$writ->dataElement("entry","Name");
	$writ->dataElement("entry","Description");
	$writ->dataElement("entry","Type Name");
	$writ->dataElement("entry","Set Name");
	$writ->dataElement("entry","Enum Name");
	$writ->dataElement("entry","Fk Table Name");
	$writ->dataElement("entry","Fk Field Name");
	$writ->dataElement("entry","Fk Optimized?");
	$writ->endTag("row");
	$writ->endTag("thead");
	$writ->startTag("tbody");
	$self->get_fields()->printd($writ);
	$self->get_constraints()->printd($writ);
	$writ->endTag("tbody");
	$writ->endTag("tgroup");
	$writ->endTag("table");
	$writ->endTag("para");
	$writ->endTag("formalpara");
}

sub printx($$) {
	my($self,$writ)=@_;
	$writ->startTag("table");
	$writ->dataElement("name",$self->get_name());
	$writ->dataElement("description",$self->get_description());
	$self->get_fields()->printx($writ);
	$self->get_constraints()->printx($writ);
	$writ->endTag("table");
}

sub getsql_create($$$) {
	my($self,$stats,$info)=@_;
	if($self->get_def()->has_parent_table($self->get_name())) {
		#only create the fields
		if($info->is_mysql()) {
			my($stat)=Meta::Sql::Stat->new();
			$stat->set_text("ALTER TABLE ".$self->getsql_name($info)." ".$self->get_fields()->getsql_add($info));
			$stats->push($stat);
		}
		if($info->is_postgres()) {
			#postgress can only handle one field addition at a time
			$self->get_fields()->getsql_add_multiple($stats,$info);
		}
	} else {
		#create the table and the fields
		if($info->is_postgres()) {
			#this creates postgress sequences one perl table. It is better
			#to do it in the Type.pm level so this code is out
			#my($rsts)=Meta::Sql::Stat->new();
			#$rsts->set_text("CREATE SEQUENCE ".$self->getsql_name($info)."_seq");
			#$stats->push($rsts);
			my($stat)=Meta::Sql::Stat->new();
			$stat->set_text("CREATE TABLE ".$self->getsql_name($info)." (".$self->get_fields()->getsql_names($info).")");
			$stats->push($stat);
			my($rstt)=Meta::Sql::Stat->new();
			$rstt->set_text("COMMENT ON TABLE ".$self->getsql_name($info)." IS \'".$self->get_description()."\'");
			$stats->push($rstt);
		}
		if($info->is_mysql()) {
			my($stat)=Meta::Sql::Stat->new();
			$stat->set_text("CREATE TABLE ".$self->getsql_name($info)." (".$self->get_fields()->getsql_names($info).") COMMENT=\"".$self->get_description()."\"");
			$stats->push($stat);
		}
	}
	$self->get_fields()->getsql_create($stats,$info);
	$self->get_constraints()->getsql_create($stats,$info);
}

sub getsql_drop($$$) {
	my($self,$stats,$info)=@_;
	$self->get_fields()->getsql_drop($stats,$info);
}

sub getsql_clean($$$) {
	my($self,$stats,$info)=@_;
	my($stat)=Meta::Sql::Stat->new();
	$stat->set_text("DELETE FROM ".$self->getsql_name($info));
	$stats->push($stat);
}

sub getsql_name($$) {
	my($self,$info)=@_;
	if($info->is_postgres()) {
		return($self->get_name());
	}
	if($info->is_mysql()) {
		return($info->get_name().".".$self->get_name());
	}
	throw Meta::Error::Simple("what kind of db is it ?");
}

sub getsql_select($$) {
	my($self,$info)=@_;
	return($self->get_fields()->getsql_select($info));
}

sub getsql_insert($$) {
	my($self,$info)=@_;
	return($self->get_fields()->getsql_insert($info));
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Db::Table - Object to store a definition of a table in a database.

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

	MANIFEST: Table.pm
	PROJECT: meta
	VERSION: 0.41

=head1 SYNOPSIS

	package foo;
	use Meta::Db::Table qw();
	my($table)=Meta::Db::Table->new();
	$table->parse($file);
	my($table)=$syntax->get_table_num();

=head1 DESCRIPTION

This is an object that stores the definition of a single table in a database.
This includes a hash of the current fields and their types.
This object inherits from the Ohash object.

=head1 FUNCTIONS

	BEGIN()
	new($)
	get_fields($)
	set_fields($$)
	get_def($)
	print($$)
	printd($$)
	printx($$)
	getsql_create($$$)
	getsql_drop($$$)
	getsql_clean($$$)
	getsql_name($$)
	getsql_select($$)
	getsql_insert($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This method will set up get/set methods for the following attributes:
name - the name of the table.
description - the description of the table.

=item B<new($)>

This gives you a new object for a table definitions.

=item B<get_fields($)>

This returns the fields of the current table.

=item B<set_fields($$)>

This will set the fields of the current table.

=item B<get_def($)>

This method will return the def object for the table.

=item B<print($$)>

This prints the table into a file.

=item B<printd($$)>

This method will print the object in DocBook XML format using a writer
object received.

=item B<printx($$)>

This method will print the object in XML format using a writer
object received.

=item B<getsql_create($$$)>

This method receives a Table object and a statement collection and add to
that statement collection a list of statements needed to create this object
over an SQL connection.

=item B<getsql_drop($$$)>

This method receives a Table object and a statement collection and add to
that statement collection a list of statements needed to drop this object
over an SQL connection.

=item B<getsql_clean($$$)>

This method receives a Table object and a statement collection and add to
that statement collection a list of statements needed to clean this object
over an SQL connection.

=item B<getsql_name($$)>

This method will return a name for this table which is prefixed by the given database name.

=item B<getsql_select($$)>

This method will return an SQL sniplet which can be used in SELECT type statements.

=item B<getsql_insert($$)>

This method will return an SQL sniplet which can be used in INSERT type statements.

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
	0.08 MV fix all tests change
	0.09 MV change new methods to have prototypes
	0.10 MV perl code quality
	0.11 MV more perl quality
	0.12 MV more perl quality
	0.13 MV perl documentation
	0.14 MV get graph stuff going
	0.15 MV more perl quality
	0.16 MV perl qulity code
	0.17 MV more perl code quality
	0.18 MV revision change
	0.19 MV languages.pl test online
	0.20 MV history change
	0.21 MV db stuff
	0.22 MV more data sets
	0.23 MV perl packaging
	0.24 MV db inheritance
	0.25 MV PDMT
	0.26 MV some chess work
	0.27 MV md5 project
	0.28 MV database
	0.29 MV perl module versions in files
	0.30 MV movies and small fixes
	0.31 MV movie stuff
	0.32 MV graph visualization
	0.33 MV more thumbnail stuff
	0.34 MV thumbnail user interface
	0.35 MV dbman package creation
	0.36 MV more thumbnail issues
	0.37 MV website construction
	0.38 MV web site development
	0.39 MV web site automation
	0.40 MV SEE ALSO section fix
	0.41 MV md5 issues

=head1 SEE ALSO

Meta::Class::MethodMaker(3), Meta::Db::Constraints(3), Meta::Db::Fields(3), Meta::Ds::Connected(3), strict(3)

=head1 TODO

Nothing.
