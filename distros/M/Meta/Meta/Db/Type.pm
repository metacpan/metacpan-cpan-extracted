#!/bin/echo This is a perl module and should not be run

package Meta::Db::Type;

use strict qw(vars refs subs);
use Meta::Ds::Connected qw();
use Meta::Class::MethodMaker qw();
use DBI qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.49";
@ISA=qw(Meta::Ds::Connected);

#sub BEGIN();
#sub is_prim($);
#sub is_inde($);
#sub is_set($);
#sub is_enum($);
#sub print($$);
#sub printd($$);
#sub printx($$);
#sub getsql_create($$$);
#sub getsql_drop($$$);
#sub getsql_names($$);
#sub getsql_bind($$);
#sub TEST($);

#__DATA__

our(%tran,%tran_pg,%tran_mysql);

sub BEGIN() {
	Meta::Class::MethodMaker->new("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_name",
		-java=>"_setref",
		-java=>"_enumref",
		-java=>"_tableref",
		-java=>"_fieldref",
		-java=>"_optimized",
		-java=>"_null",
		-java=>"_default",
	);
	%tran=(
		"index",defined,
		"enum",defined,
		"set",defined,
		"key",defined,
		"integer",defined,
		"posinteger",defined,
		"namestring",defined,
		"htmlstring",defined,
		"string",defined,
		"float",defined,
		"probfloat",defined,
		"positivefloat",defined,
		"boolean",defined,
		"lat",defined,
		"long",defined,
		"ip",defined,
		"ipmask",defined,
		"mac",defined,
		"money",defined,
		"url",defined,
		"year",defined,
		"month",defined,
		"weekday",defined,
		"hour",defined,
		"second",defined,
		"seconds",defined,
		"email",defined,
		"date",defined,
		"time",defined,
		"datetime",defined,
		"tinybinary",defined,
		"smallbinary",defined,
		"mediumbinary",defined,
		"largebinary",defined,
		"unlimitedbinary",defined,
		"smallpng",defined,
		"largepng",defined,
		"smalljpg",defined,
		"largejpg",defined,
		"smallpixmap",defined,
		"largepixmap",defined,
		"mp3",defined,
		"wav",defined,
		"geopoint",defined,
		"geoline",defined,
		"geobox",defined,
		"geocircle",defined,
		"geopolyline",defined,
		"geopolygon",defined,
		"geogrid",defined,
		"sgml",defined,
		"postscript",defined,
	);
	%tran_pg=(
		"index","INTEGER",
		"enum","CHAR(20)",
		"set","INTEGER",
		"key","SERIAL PRIMARY KEY",
		"integer","INTEGER",
		"posinteger","INTEGER",
		"namestring","CHAR(50)",
		"htmlstring","TEXT",
		"string","TEXT",
		"float","FLOAT",
		"probfloat","FLOAT",
		"positivefloat","FLOAT",
		"boolean","BOOLEAN",
		"lat","FLOAT",
		"long","FLOAT",
		"ip","CIDR",
		"ipmask","INET",
		"mac","MACADDR",
		"money","MONEY",
		"url","TEXT",
		"year","INTEGER",
		"month","INTEGER",
		"weekday","INTEGER",
		"hour","INTEGER",
		"second","INTEGER",
		"seconds","INTEGER",
		"email","TEXT",
		"date","DATE",
		"time","TIME",
		"datetime","DATETIME",
		"tinybinary","BYTEA",
		"smallbinary","BYTEA",
		"mediumbinary","BYTEA",
		"largebinary","BYTEA",
		"unlimitedbinary","BYTEA",
		"smallpng","BYTEA",
		"largepng","BYTEA",
		"smalljpg","BYTEA",
		"largejpg","BYTEA",
		"smallpixmap","BYTEA",
		"largepixmap","BYTEA",
		"mp3","BYTEA",
		"wav","BYTEA",
		"geopoint","POINT",
		"geoline","LINE",
		"geobox","BOX",
		"geocircle","CIRCLE",
		"geopolyline","PATH",
		"geopolygon","POLYGON",
		"geogrid","BYTEA",
		"sgml","BYTEA",
		"postscript","BYTEA",
	);
	%tran_mysql=(
		"index","INTEGER",
		"enum","ENUM",
		"set","SET",
		"key","INTEGER AUTO_INCREMENT PRIMARY KEY",
		"integer","INTEGER",
		"posinteger","INTEGER",
		"namestring","CHAR(50)",
		"htmlstring","TEXT",
		"string","TEXT",
		"float","FLOAT",
		"probfloat","FLOAT",
		"positivefloat","FLOAT",
		"boolean","ENUM('N','Y')",
		"lat","FLOAT",
		"long","FLOAT",
		"ip","TEXT",
		"ipmask","TEXT",
		"mac","TEXT",
		"money","FLOAT",
		"url","TEXT",
		"year","INTEGER",
		"month","INTEGER",
		"weekday","INTEGER",
		"hour","INTEGER",
		"second","INTEGER",
		"seconds","INTEGER",
		"email","TEXT",
		"date","DATE",
		"time","TIME",
		"datetime","DATETIME",
		"tinybinary","TINYBLOB",
		"smallbinary","BLOB",
		"mediumbinary","MEDIUMBLOB",
		"largebinary","LONGBLOB",
		"unlimitedbinary","LONGBLOB",
		"smallpng","BLOB",
		"largepng","MEDIUMBLOB",
		"smalljpg","BLOB",
		"largejpg","MEDIUMBLOB",
		"smallpixmap","BLOB",
		"largepixmap","MEDIUMBLOB",
		"mp3","MEDIUMBLOB",
		"wav","MEDIUMBLOB",
		"geopoint","BLOB",
		"geoline","BLOB",
		"geobox","BLOB",
		"geocircle","BLOB",
		"geopolyline","BLOB",
		"geopolygon","BLOB",
		"geogrid","BLOB",
		"sgml","BLOB",
		"postscript","BLOB",
	);
}

sub is_prim($) {
	my($self)=@_;
	my($name)=$self->get_name();
	return($name eq "key");
}

sub is_inde($) {
	my($self)=@_;
	my($name)=$self->get_name();
	return($name eq "index");
}

sub is_set($) {
	my($self)=@_;
	my($name)=$self->get_name();
	return($name eq "set");
}

sub is_enum($) {
	my($self)=@_;
	my($name)=$self->get_name();
	return($name eq "enum");
}

sub print($$) {
	my($self,$file)=@_;
	print $file "type info name=[".$self->get_name()."]\n";
	print $file "type info setref=[".$self->get_setref()."]\n";
	print $file "type info enumref=[".$self->get_enumref()."]\n";
	print $file "type info tableref=[".$self->get_tableref()."]\n";
	print $file "type info fieldref=[".$self->get_fieldref()."]\n";
	print $file "type info optimized=[".$self->get_optimized()."]\n";
	print $file "type info null=[".$self->get_null()."]\n";
	print $file "type info default=[".$self->get_default()."]\n";
	print $file "type info is_prim=[".$self->is_prim()."]\n";
	print $file "type info is_inde=[".$self->is_inde()."]\n";
	print $file "type info is_set=[".$self->is_set()."]\n";
	print $file "type info is_enum=[".$self->is_enum()."]\n";
}

sub printd($$) {
	my($self,$writ)=@_;
	$writ->dataElement("entry",$self->get_name());
	if($self->is_set()) {
		$writ->dataElement("entry",$self->get_setref());
	} else {
		$writ->dataElement("entry","Not Set");
	}
	if($self->is_enum()) {
		$writ->dataElement("entry",$self->get_enumref());
	} else {
		$writ->dataElement("entry","Not Enum");
	}
	if($self->is_inde()) {
		$writ->startTag("entry");
		$writ->dataElement("database",$self->get_tableref(),"class"=>"table");
		$writ->endTag("entry");
	} else {
		$writ->dataElement("entry","Not Fk");
	}
	if($self->is_inde()) {
		$writ->startTag("entry");
		$writ->dataElement("database",$self->get_fieldref(),"class"=>"field");
		$writ->endTag("entry");
	} else {
		$writ->dataElement("entry","Not Fk");
	}
	if($self->is_inde()) {
		$writ->dataElement("entry",$self->get_optimized());
	} else {
		$writ->dataElement("entry","Not Fk");
	}
}

sub printx($$) {
	my($self,$writ)=@_;
	$writ->dataElement("type",$self->get_name());
	if($self->is_inde()) {
		$writ->dataElement("tableref",$self->get_tableref());
		$writ->dataElement("fieldref",$self->get_fieldref());
		$writ->dataElement("optimized",$self->get_optimized());
		$writ->dataElement("null",$self->get_null());
		$writ->dataElement("default",$self->get_default());
	}
	if($self->is_set()) {
		$writ->dataElement("setref",$self->get_setref());
	}
	if($self->is_enum()) {
		$writ->dataElement("enumref",$self->get_enumref());
	}
}

sub getsql_create($$$) {
	my($self,$stats,$info)=@_;
	if($self->is_prim()) {
		if($info->is_postgres()) {
			#my($stat)=Meta::Sql::Stat->new();
			#my($fieldsqlname)=$self->get_container()->getsql_name($info);
			#my($sym_name)=$fieldsqlname;
			#$sym_name=~s/\./\_/g;#. is not allowed in index names
			#$sym_name.="_seq";
			#$stat->set_text("CREATE SEQUENCE ".$sym_name);
			#$stats->push($stat);
		}
	}
	if($self->get_optimized()) {
		my($stat)=Meta::Sql::Stat->new();
		my($fieldsqlname)=$self->get_container()->getsql_name($info);
		my($sym_name)=$fieldsqlname;
		$sym_name=~s/\./\_/g;#. is not allowed in index names
		$sym_name.="_index";
		my($fieldname)=$self->get_container()->get_name();
		my($tablesqlname)=$self->get_container()->get_container()->get_container()->getsql_name($info);
		$stat->set_text("CREATE INDEX ".$sym_name." ON ".$tablesqlname." (".$fieldname.")");
		$stats->push($stat);
	}
}

sub getsql_drop($$$) {
	my($self,$stats,$info)=@_;
}

sub getsql_names($$) {
	my($self,$info)=@_;
	my($type)=$self->get_name();
	my($ntyp)=undef;
	# handle the basic type name
	if($info->is_postgres()) {
		$ntyp=$tran_pg{$type};
	}
	if($info->is_mysql()) {
		$ntyp=$tran_mysql{$type};
	}
	if(!defined($ntyp)) {
		throw Meta::Error::Simple("unable to translate type [".$type."]");
	}
	# handle sets and enums
	if($info->is_mysql()) {
		if($type eq "set") {
			my($defx)=$self->get_container()->get_container()->get_container()->get_container()->get_container();
			my($set_obj)=$defx->get_sets()->get($self->get_setref());
			my($set_string)=$set_obj->get_string();
			$ntyp.="(".$set_string.")";
		}
		if($type eq "enum") {
			my($defx)=$self->get_container()->get_container()->get_container()->get_container()->get_container();
			my($enum_obj)=$defx->get_enums()->get($self->get_enumref());
			my($enum_string)=$enum_obj->get_string();
			$ntyp.="(".$enum_string.")";
		}
	}
	# handle null (not for primary keys since they can't be null anyway).
	if(!($self->is_prim())) {
		if($self->get_null()) {
			$ntyp.=" NULL";
		} else {
			# put this back once real creation in one statement is here
			if($info->is_mysql()) {
				$ntyp.=" NOT NULL";
			}
		}
	}
	# handle default values (not for primary keys since they are given explicitly).
	if(!($self->is_prim())) {
		if(defined($self->get_default())) {
			$ntyp.=" DEFAULT ".$self->get_default();
		}
	}
	# handle postgress sequence correct pointing
	if($self->is_prim()) {
		if($info->is_postgres()) {
			#my($fieldsqlname)=$self->get_container()->getsql_name($info);
			#my($sym_name)=$fieldsqlname;
			#$sym_name=~s/\./\_/g;#. is not allowed in index names
			#$sym_name.="_seq";
			#$ntyp.=" DEFAULT NEXTVAL('".$sym_name."')",
		}
	}
	# handle indices
	if($self->is_inde()) {
		if($info->is_mysql()) {
			$ntyp.=" REFERENCES ".$self->get_tableref();
		}
	}
	return($ntyp);
}

sub getsql_bind($$) {
	my($self,$info)=@_;
	if($info->is_postgres()) {
		my($type)=$self->get_name();
		if($type eq "tinybinary") {
			return(DBI::SQL_BINARY);
		}
		if($type eq "smallbinary") {
			return(DBI::SQL_BINARY);
		}
		if($type eq "mediumbinary") {
			return(DBI::SQL_BINARY);
		}
		if($type eq "largebinary") {
			return(DBI::SQL_BINARY);
		}
		if($type eq "unlimitedbinary") {
			return(DBI::SQL_BINARY);
		}
		if($type eq "smallpng") {
			return(DBI::SQL_BINARY);
		}
		if($type eq "largepng") {
			return(DBI::SQL_BINARY);
		}
		if($type eq "smalljpg") {
			return(DBI::SQL_BINARY);
		}
		if($type eq "largejpg") {
			return(DBI::SQL_BINARY);
		}
		if($type eq "smalljpg") {
			return(DBI::SQL_BINARY);
		}
		if($type eq "mp3") {
			return(DBI::SQL_BINARY);
		}
		if($type eq "wav") {
			return(DBI::SQL_BINARY);
		}
		if($type eq "sgml") {
			return(DBI::SQL_BINARY);
		}
		if($type eq "postscript") {
			return(DBI::SQL_BINARY);
		}
	}
	return(undef);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Db::Type - Object to store a database type information in it.

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

	MANIFEST: Type.pm
	PROJECT: meta
	VERSION: 0.49

=head1 SYNOPSIS

	package foo;
	use Meta::Db::Type qw();
	my($type)=Meta::Db::Type->new();
	$type->set("String",0,0,0,0);

=head1 DESCRIPTION

This is an object to store database type information in it.
All types of information are in here.

=head1 FUNCTIONS

	BEGIN()
	is_prim($)
	is_inde($)
	is_set($)
	is_enum($)
	print($$)
	printd($$)
	printx($$)
	getsql_create($$$)
	getsql_drop($$$)
	getsql_names($$)
	getsql_bind($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This method initializes the module for work. Do not use it directly.
The idea is that this module uses translation hashes of types extensivly and
we could build them once and use them many times. In addition this method
sets up accessor methods for the following attributes:
"name", "setref", "enumref", "tableref", "fieldref", "optimized", "null".

=item B<is_prim($)>

This returns whether the type is a primary key or not for this table.

=item B<is_inde($)>

This returns whether the type is an index to another table or not.

=item B<is_set($)>

This returns whether the type is a set type or not.

=item B<is_enum($)>

This returns whether the type is an enum type or not.

=item B<print($$)>

This prints out the current type object.

=item B<printd($$)>

This method prints out the object in DocBook XML format using the a writer
object received.

=item B<printx($$)>

This method prints out the object in XML format using the a writer
object received.

=item B<getsql_create($$$)>

This method will add SQL statements to a container of SQL statements which is
recevied which create this type on the database.

=item B<getsql_drop($$$)>

This method will add SQL statements to a container of SQL statements which is
recevied which drop this type on the database.

=item B<getsql_names($$)>

This method will return an SQL string which describes the type and which is
fit for inclusion in an SQL CREATE TABLE type statement.

=item B<getsql_bind($$)>

This method returns the DBI parameter suitable for inclusion in "bind_param" type DBI statements.

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
	0.21 MV web site stuff
	0.22 MV more data sets
	0.23 MV spelling and papers
	0.24 MV perl packaging
	0.25 MV PDMT
	0.26 MV pictures database
	0.27 MV tree type organization in databases
	0.28 MV some chess work
	0.29 MV more movies
	0.30 MV books XML into database
	0.31 MV md5 project
	0.32 MV database
	0.33 MV perl module versions in files
	0.34 MV movies and small fixes
	0.35 MV movie stuff
	0.36 MV md5 progress
	0.37 MV more Class method generation
	0.38 MV more thumbnail code
	0.39 MV more thumbnail stuff
	0.40 MV thumbnail user interface
	0.41 MV import tests
	0.42 MV more thumbnail issues
	0.43 MV paper writing
	0.44 MV website construction
	0.45 MV web site development
	0.46 MV web site automation
	0.47 MV SEE ALSO section fix
	0.48 MV download scripts
	0.49 MV md5 issues

=head1 SEE ALSO

DBI(3), Error(3), Meta::Class::MethodMaker(3), Meta::Ds::Connected(3), strict(3)

=head1 TODO

-add auto_increment ?!?

-IpMask and Ip types could limit the size of the text to some limit (12 bytes ? 15 bytes ?)

-make the null attribute a binary value.

-make the print to SGML method write the null and default stuff too (revamp it altogether).

-why is the index created separately ? can't I create it with CREATE TABLE ?
