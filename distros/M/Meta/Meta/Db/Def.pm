#!/bin/echo This is a perl module and should not be run

package Meta::Db::Def;

use strict qw(vars refs subs);
use Meta::Sql::Stat qw();
use Meta::Xml::Parsers::Def qw();
use Meta::Db::Parents qw();
use Meta::Db::Sets qw();
use Meta::Db::Enums qw();
use Meta::Db::Tables qw();
use Meta::Db::Users qw();
use Meta::Ds::Connected qw();
use Meta::Db::Info qw();
use Meta::Xml::Writer qw();
use XML::DOM qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.47";
@ISA=qw(Meta::Ds::Connected);

#sub BEGIN();
#sub new($);
#sub init($);
#sub get_parents($);
#sub set_parents($$);
#sub get_sets($);
#sub set_sets($$);
#sub get_enums($);
#sub set_enums($$);
#sub get_tables($);
#sub set_tables($$);
#sub get_users($);
#sub set_users($$);
#sub print($$);
#sub printd($$);
#sub printx($$);
#sub getsql_create($$$);
#sub getsql_crea($$$);
#sub getsql_drop($$$$);
#sub getsql_clean($$$);
#sub getsql_select($$$);
#sub getsql_insert($$$);
#sub new_file($$);
#sub new_modu($$);
#sub has_table($$);
#sub has_field($$$);
#sub has_parent_table($$);
#sub get_table($$);
#sub get_field($$$);
#sub get_field_number($$$);
#sub add_deps($$$);
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
	$self->set_parents(Meta::Db::Parents->new());
	$self->set_sets(Meta::Db::Sets->new());
	$self->set_enums(Meta::Db::Enums->new());
	$self->set_tables(Meta::Db::Tables->new());
	$self->set_users(Meta::Db::Users->new());
	return($self);
}

sub init($) {
	my($self)=@_;
	$self->set_parents(Meta::Db::Parents->new());
	$self->set_sets(Meta::Db::Sets->new());
	$self->set_enums(Meta::Db::Enums->new());
	$self->set_tables(Meta::Db::Tables->new());
	$self->set_users(Meta::Db::Users->new());
	return($self);
}

sub get_parents($) {
	my($self)=@_;
	return($self->{PARENTS});
}

sub set_parents($$) {
	my($self,$parents)=@_;
	$self->{PARENTS}=$parents;
	$parents->set_container($self);
}

sub get_sets($) {
	my($self)=@_;
	return($self->{SETS});
}

sub set_sets($$) {
	my($self,$sets)=@_;
	$self->{SETS}=$sets;
	$sets->set_container($self);
}

sub get_enums($) {
	my($self)=@_;
	return($self->{ENUMS});
}

sub set_enums($$) {
	my($self,$enums)=@_;
	$self->{ENUMS}=$enums;
	$enums->set_container($self);
}

sub get_tables($) {
	my($self)=@_;
	return($self->{TABLES});
}

sub set_tables($$) {
	my($self,$tables)=@_;
	$self->{TABLES}=$tables;
	$tables->set_container($self);
}

sub get_users($) {
	my($self)=@_;
	return($self->{USERS});
}

sub set_users($$) {
	my($self,$users)=@_;
	$self->{USERS}=$users;
	$users->set_container($self);
}

sub print($$) {
	my($self,$file)=@_;
	print $file "def name is [".$self->get_name()."]\n";
	print $file "def description is [".$self->get_description()."]\n";
	$self->get_sets()->print($file);
	$self->get_enums()->print($file);
	$self->get_tables()->print($file);
	$self->get_users()->print($file);
	$self->get_parents()->print($file);
}

sub printd($$) {
	my($self,$writ)=@_;
	$writ->startTag("title");
	$writ->characters("The ");
	$writ->dataElement("database",$self->get_name(),"class"=>"name");
	$writ->characters(" database");
	$writ->endTag("title");
	$writ->startTag("section");
	$writ->dataElement("title","Description");
	$writ->dataElement("para",$self->get_description());
	$writ->endTag("section");
	$writ->startTag("section");
	$self->get_parents()->printd($writ);
	$writ->endTag("section");
	$writ->startTag("section");
	$self->get_sets()->printd($writ);
	$writ->endTag("section");
	$writ->startTag("section");
	$self->get_enums()->printd($writ);
	$writ->endTag("section");
	$writ->startTag("section");
	$self->get_tables()->printd($writ);
	$writ->endTag("section");
	$writ->startTag("section");
	$self->get_users()->printd($writ);
	$writ->endTag("section");
}

sub printx($$) {
	my($self,$writ)=@_;
	$writ->startTag("def");
	$writ->dataElement("name",$self->get_name());
	$writ->dataElement("description",$self->get_description());
	$self->get_parents()->printx($writ);
	$self->get_sets()->printx($writ);
	$self->get_enums()->printx($writ);
	$self->get_tables()->printx($writ);
	$self->get_users()->printx($writ);
	$writ->endTag("def");
}

sub printc($$) {
	my($self,$c)=@_;
	print $c->start_table();
	print $c->caption("This is the [".$self->get_name()."] database");
	print $c->Tr($c->th(['name','description']));
#	my($ret)=
#		$c->start_html().
#		$c->caption("This is the [".$self->get_name()."] database").
#		$c->Tr($c->th(['name','description']));
	my($tables)=$self->get_tables();
	for(my($i)=0;$i<$tables->size();$i++) {
		my($table)=$tables->elem($i);
		my($name)=$table->get_name();
		my($description)=$table->get_description();
		print $c->Tr($c->td([$name,$description]));
#		$ret.=$c->Tr($c->td([$name,$description]));
	}
	print $c->end_table();
#	$ret.=$c->end_html();
	my($ret)="";
	return($ret);
}

sub getsql_create($$$) {
	my($self,$stats,$info)=@_;
	my($stat)=Meta::Sql::Stat->new();
	$stat->set_text("CREATE DATABASE ".$info->get_name());
	$stats->push($stat);
	if($info->is_postgres()) {
		my($rstt)=Meta::Sql::Stat->new();
		$rstt->set_text("RECONNECT ".$info->get_name());
		$stats->push($rstt);
		my($stat)=Meta::Sql::Stat->new();
		$stat->set_text("COMMENT ON DATABASE ".$info->get_name()." IS \'".$self->get_description()."\'");
		$stats->push($stat);
	}
	$self->getsql_crea($stats,$info);
}

sub getsql_crea($$$) {
	my($self,$stats,$info)=@_;
	$self->get_parents()->getsql_crea($stats,$info);
	$self->get_sets()->getsql_create($stats,$info);
	$self->get_enums()->getsql_create($stats,$info);
	$self->get_tables()->getsql_create($stats,$info);
	$self->get_users()->getsql_create($stats,$info);
}

sub getsql_drop($$$$) {
	my($self,$stats,$info,$prim)=@_;
	if($prim) {
		my($stat)=Meta::Sql::Stat->new();
		$stat->set_text("DROP DATABASE ".$info->get_name());
		$stats->push($stat);
	}
	$self->get_parents()->getsql_drop($stats,$info,0);
	$self->get_sets()->getsql_drop($stats,$info);
	$self->get_enums()->getsql_drop($stats,$info);
	$self->get_tables()->getsql_drop($stats,$info);
	$self->get_users()->getsql_drop($stats,$info);
}

sub getsql_clean($$$) {
	my($self,$stats,$info)=@_;
	$self->get_parents()->getsql_clean($stats,$info);
	$self->get_sets()->getsql_clean($stats,$info);
	$self->get_enums()->getsql_clean($stats,$info);
	$self->get_tables()->getsql_clean($stats,$info);
	$self->get_users()->getsql_clean($stats,$info);
}

sub getsql_select($$$) {
	my($self,$info,$table)=@_;
	my(@arra);
	my($parents)=$self->get_parents();
	for(my($i)=0;$i<$parents->size();$i++) {
		my($curr)=$parents->elem($i);
		if($curr->has_table($table)) {
			push(@arra,$curr->getsql_select($info,$table));
		}
	}
#	if($self->has_parent_table($table)) {
#		push(@arra,$self->get_parents()->getsql_select($info,$table));
#	}
	if($self->get_tables()->has($table)) {
		my($tab)=$self->get_tables()->get($table);
		push(@arra,$tab->getsql_select($info));
	}
	return(join(",",@arra));
}

sub getsql_insert($$$) {
	my($self,$info,$table)=@_;
	my(@arra);
	my($parents)=$self->get_parents();
	for(my($i)=0;$i<$parents->size();$i++) {
		my($curr)=$parents->elem($i);
		if($curr->has_table($table)) {
			push(@arra,$curr->getsql_insert($info,$table));
		}
	}
#	if($self->has_parent_table($table)) {
#		push(@arra,$self->get_parents()->getsql_insert($info,$table));
#	}
	if($self->get_tables()->has($table)) {
		my($tab)=$self->get_tables()->get($table);
		push(@arra,$tab->getsql_insert($info));
	}
	return(join(",",@arra));
}

sub new_file($$) {
	my($class,$file)=@_;
	my($parser)=Meta::Xml::Parsers::Def->new();
	$parser->parsefile($file);
	return($parser->get_result());
}

sub new_modu($$) {
	my($class,$modu)=@_;
	return(&new_file($class,$modu->get_abs_path()));
}

sub has_table($$) {
	my($self,$name)=@_;
	my($parents)=$self->get_parents();
	for(my($i)=0;$i<$parents->size();$i++) {
		my($curr)=$parents->elem($i);
		if($curr->has_table($name)) {
			return(1);
		}
	}
	return($self->get_tables()->has($name));
}

sub has_field($$$) {
	my($self,$table,$field)=@_;
	my($parents)=$self->get_parents();
	for(my($i)=0;$i<$parents->size();$i++) {
		my($curr)=$parents->elem($i);
		if($curr->has_field($table,$field)) {
			return(1);
		}
	}
	if($self->get_tables()->has($table)) {
		return($self->get_tables()->get($table)->get_fields()->has($field));
	} else {
		return(0);
	}
}

sub has_parent_table($$) {
	my($self,$name)=@_;
	my($parents)=$self->get_parents();
	for(my($i)=0;$i<$parents->size();$i++) {
		my($curr)=$parents->elem($i);
		if($curr->has_table($name)) {
			return(1);
		}
	}
	return(0);
}

sub get_table($$) {
	my($self,$name)=@_;
	my($parents)=$self->get_parents();
	for(my($i)=0;$i<$parents->size();$i++) {
		my($curr)=$parents->elem($i);
		if($curr->has_table($name)) {
			return($curr->get_table($name));
		}
	}
	return($self->get_tables()->get($name));
}

sub get_field($$$) {
	my($self,$table,$field)=@_;
	my($parents)=$self->get_parents();
	for(my($i)=0;$i<$parents->size();$i++) {
		my($curr)=$parents->elem($i);
		if($curr->has_field($table,$field)) {
			return($curr->get_table($table)->get_fields()->get($field));
		}
	}
	return($self->get_tables()->get($table)->get_fields()->get($field));
}

sub get_field_number($$$) {
	my($self,$table,$field)=@_;
	my($parents)=$self->get_parents();
	my($numb)=0;
	for(my($i)=0;$i<$parents->size();$i++) {
		my($curr)=$parents->elem($i);
		if($curr->has_table($table)) {
			if($curr->has_field($table,$field)) {
				return($curr->get_field_number($table,$field));
			} else {
				$numb+=$curr->get_table($table)->get_fields()->size();
			}
		}
	}
	return($numb+$self->get_tables()->get($table)->get_fields()->get_elem_number($field));
}

sub add_deps($$$) {
	my($modu,$deps,$srcx)=@_;
	my($parser)=XML::DOM::Parser->new();
	my($doc)=$parser->parsefile($srcx);
	my($parents);#mind that this needs to be on a different line
	$parents=$doc->getElementsByTagName("parent");
	for(my($i)=0;$i<$parents->getLength();$i++) {
		my($current)=$parents->[$i];
		if($current->hasChildNodes()) {#check if authorizations has text at all
			my($name)=$current->getFirstChild()->getData();
			$deps->node_insert($name);
			$deps->edge_insert($modu,$name);
		} else {
			throw Meta::Error::Simple("no parent text ?");
		}
	}
}

sub TEST($) {
	my($context)=@_;
	my($module)=Meta::Development::Module->new_name("xmlx/def/pics.xml");
	my($def)=Meta::Db::Def->new_modu($module);

	my($info)=Meta::Db::Info->new();
	$info->set_type("mysql");
	$info->set_name($def->get_name());

	Meta::Utils::Output::print("select is [".$def->getsql_select($info,"item")."]\n");
	Meta::Utils::Output::print("insert is [".$def->getsql_insert($info,"item")."]\n");
	Meta::Utils::Output::print("has is [".$def->has_field("item","id")."]\n");
	Meta::Utils::Output::print("has is [".$def->has_field("foo","koo")."]\n");

	my($field)=$def->get_field("item","id");
	Meta::Utils::Output::print("field of item,id is [".$field."]\n");
	my($field_num)=$def->get_field_number("item","name");
	Meta::Utils::Output::print("field_num of item,name is [".$field_num."]\n");

	my($temp)=Meta::Utils::Utils::get_temp_file();
	my($outp)=IO::File->new("> ".$temp);
	my($writ)=Meta::Xml::Writer->new(OUTPUT=>$outp,DATA_INDENT=>1,DATA_MODE=>1,UNSAFE=>1);
	$writ->xmlDecl();
	$writ->comment(Meta::Lang::Docb::Params::get_comment());
	$writ->doctype(
		"section",
		Meta::Lang::Docb::Params::get_public()
	);
	$def->printd($writ);
	$writ->end();
	$outp->close();
	Meta::Utils::File::Remove::rm($temp);
	return(1);
}

1;

__END__

=head1 NAME

Meta::Db::Def - Object to store a definition for a database.

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

	MANIFEST: Def.pm
	PROJECT: meta
	VERSION: 0.47

=head1 SYNOPSIS

	package foo;
	use Meta::Db::Def qw();
	my($dbdef)=Meta::Db::Def->new();
	$dbdef->read($file);
	my($num_table)=$syntax->num_table();

=head1 DESCRIPTION

This is an object to let you read,write and manipulate a database definition.

=head1 FUNCTIONS

	BEGIN()
	new($)
	init($)
	get_parents($)
	set_parents($$)
	get_sets($)
	set_sets($$)
	get_enums($)
	set_enums($$)
	get_tables($)
	set_tables($$)
	get_users($)
	set_users($$)
	print($$)
	printd($$)
	printx($$)
	getsql_create($$$)
	getsql_crea($$$)
	getsql_drop($$$$)
	getsql_clean($$$)
	getsql_select($$$)
	getsql_insert($$$)
	new_file($$)
	new_modu($$)
	has_table($$)
	has_field($$$)
	has_parent_table($$)
	get_table($$)
	get_field($$$)
	get_field_number($$$)
	add_deps($$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This method creates the get/set methods for attributes:
"name", "description".
name - name for this database.
description - description of this database.

=item B<new($)>

Constructor for this class.

=item B<init($)>

This is an internal post construction tool.

=item B<get_parents($)>

This will give you the parents object of the current Def.

=item B<set_parents($$)>

This will set the parents object of the current Def.

=item B<get_sets($)>

This will give you the sets object of the current Def.

=item B<set_sets($$)>

This will set the sets object of the current Def.

=item B<get_enums($)>

This will give you the enums object of the current Def.

=item B<set_enums($$)>

This will set the enums object of the current Def.

=item B<get_tables($)>

This will give you the tables object for the current Def.

=item B<set_tables($$)>

This will set the tables object for the current Def.

=item B<get_users($)>

This will give you the users object of the current Def.

=item B<set_users($$)>

This will set the users object of the current Def.

=item B<print($$)>

This is a routine to printout this def object.

=item B<printd($$)>

This method will print the def object in docbook format.

=item B<printx($$)>

This will print the current object in the source XML format.

=item B<getsql_create($$$)>

This method accepts a Def object and a statement collection and adds to that
statement collection all the statements neccessary to create this database
in the SQL language.

=item B<getsql_crea($$$)>

This method accepts Def object and a statement collection and adds to that
statement collection all the statements neccessary to create this database
in the SQL language.

=item B<getsql_drop($$$$)>

This method accepts a Def object and a statement collection and adds to that
statement collection all the statements neccessary to drop this database
in the SQL language.

=item B<getsql_clean($$$)>

This method accepts a Def object, a statement collection and information
about the database that it wants cleaned and adds the statements regarding
the cleaning to the statements object.

=item B<getsql_select($$$)>

This method returns an SQL sniplet which can be used in SELECT type statements.

=item B<getsql_insert($$$)>

This method returns an SQL sniplet which can be used in INSERT type statements.

=item B<new_file($$)>

This method receives:
0. A class name.
1. A file to read the def object from.
This method returns:
0. A def file constructed from the content of the file.
How it does it:
The method uses the Meta::Xml::Parsers::Def expat parser to achieve this.
Remarks:
This method is static.

=item B<new_modu($$)>

This method receives:
0. A class name.
1. A development module.
This method returns:
0. An def object contructed from the content of that development module.
How it does it:
The method uses the new_file method to achieve this.
Remarks:
This method is static.

=item B<has_table($$)>

This method returns a true/false value according to whether you have
a certain table or not.

=item B<has_field($$$)>

This method returns a true/false value according to whether you have
a certain table with a certain field in it or not.

=item B<has_parent_table($$)>

This method returns a true/false value according to whether the object
in question has a parent with the table name given.

=item B<get_table($$)>

This method retrieve a table object (taking care of inheritance too).

=item B<get_field($$$)>

This method will retrieve a certain field in a certain table.

=item B<get_field_number($$$)>

This method will return the index number of a field in a table.

=item B<add_deps($$$)>

This method will add dependency info specific to the XML/DEF format to
a dependency storing object.

=item B<TEST($)>

Test suite for this object.
Currently this just reads a def file and prints out the result.

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
	0.02 MV get the databases to work
	0.03 MV this time really make the databases work
	0.04 MV ok. This is for real
	0.05 MV ok - this time I realy mean it
	0.06 MV make quality checks on perl code
	0.07 MV more perl checks
	0.08 MV check that all uses have qw
	0.09 MV fix todo items look in pod documentation
	0.10 MV more on tests/more checks to perl
	0.11 MV fix all tests change
	0.12 MV change new methods to have prototypes
	0.13 MV perl code quality
	0.14 MV more perl quality
	0.15 MV more perl quality
	0.16 MV perl documentation
	0.17 MV get graph stuff going
	0.18 MV more perl quality
	0.19 MV perl qulity code
	0.20 MV more perl code quality
	0.21 MV revision change
	0.22 MV pictures in docbooks
	0.23 MV revision in files
	0.24 MV languages.pl test online
	0.25 MV db stuff
	0.26 MV xml data sets
	0.27 MV more data sets
	0.28 MV perl packaging
	0.29 MV db inheritance
	0.30 MV PDMT
	0.31 MV tree type organization in databases
	0.32 MV some chess work
	0.33 MV md5 project
	0.34 MV database
	0.35 MV perl module versions in files
	0.36 MV movies and small fixes
	0.37 MV movie stuff
	0.38 MV graph visualization
	0.39 MV thumbnail user interface
	0.40 MV more thumbnail issues
	0.41 MV website construction
	0.42 MV web site development
	0.43 MV web site automation
	0.44 MV SEE ALSO section fix
	0.45 MV web site development
	0.46 MV teachers project
	0.47 MV md5 issues

=head1 SEE ALSO

Error(3), Meta::Db::Enums(3), Meta::Db::Info(3), Meta::Db::Parents(3), Meta::Db::Sets(3), Meta::Db::Tables(3), Meta::Db::Users(3), Meta::Ds::Connected(3), Meta::Sql::Stat(3), Meta::Xml::Parsers::Def(3), Meta::Xml::Writer(3), XML::DOM(3), strict(3)

=head1 TODO

Nothing.
