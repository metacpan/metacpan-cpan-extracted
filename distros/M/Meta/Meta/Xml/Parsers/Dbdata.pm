#!/bin/echo This is a perl module and should not be run

package Meta::Xml::Parsers::Dbdata;

use strict qw(vars refs subs);
use Meta::Utils::Output qw();
use Meta::Utils::System qw();
use Meta::Ds::Array qw();
use Meta::Db::Connections qw();
use Meta::Db::Info qw();
use Meta::Sql::Stats qw();
use Meta::Utils::File::File qw();
use Meta::Xml::Parsers::Base qw();
use Meta::Utils::Time qw();
use Meta::Development::Module qw();

our($VERSION,@ISA);
$VERSION="0.20";
@ISA=qw(Meta::Xml::Parsers::Base);

#sub new($);
#sub handle_start($$);
#sub handle_end($$);
#sub handle_char($$);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)=Meta::Xml::Parsers::Base->new();
	if(!$self) {
		throw Meta::Error::Simple("didn't get a parser");
	}
	$self->setHandlers(
		"Start"=>\&handle_start,
		"End"=>\&handle_end,
		"Char"=>\&handle_char,
	);
	bless($self,$class);
	$self->{CONNECTIONS}=defined;
	$self->{DEF}=defined;
	$self->{INFO}=Meta::Ds::Array->new();
	$self->{DBI}=Meta::Ds::Array->new();
	$self->{FIELD_NAME}=defined;
	$self->{FIELD_DATA}=defined;
	$self->{TABLE_NAME}=defined;
	$self->{STAT}=Meta::Ds::Array->new();
	return($self);
}

sub handle_start($$) {
	my($self,$elem)=@_;
	my($context)=join(".",$self->context(),$elem);
	if($context eq "dbdata.tables.table.records") {
		# prepare a new statement according to this table
		my($def)=$self->{DEF};
		my($info)=$self->{INFO};
		my($table)=$def->get_table($self->{TABLE_NAME});
		my($name)=$table->get_name();
		my($select)=$def->getsql_select($info,$name);
		my($insert)=$def->getsql_insert($info,$name);
		#Meta::Utils::Output::print("select is [".$select."]\n");
		#Meta::Utils::Output::print("insert is [".$insert."]\n");
		my($stat)=$self->{STAT};
		my($dbi)=$self->{DBI};
		for(my($i)=0;$i<$dbi->size();$i++) {
			my($dbi)=$dbi->getx($i);
			my($curr)=$dbi->prepare("INSERT INTO ".$name." (".$select.") VALUES (".$insert.");");
			$stat->setx($i,$curr);
		}
	}
	if($context eq "dbdata.tables.table.records.record.field") {
		# the field name better!!! be supplied or else!!!
		$self->{FIELD_NAME}=defined;
		# this next line is important. We do not put undef in FIELD_DATA since
		# if there are no characters in the xml file the callback will not be called
		# and we will be stuck with the value we put here.
		$self->{FIELD_DATA}="";
	}
}

sub handle_end($$) {
	my($self,$elem)=@_;
	my($context)=join(".",$self->context(),$elem);
	if($context eq "dbdata.def") {
		#connect to all databases
		my($connections)=$self->{CONNECTIONS};
		my($stat)=$self->{STAT};
		my($dbi)=$self->{DBI};
		my($def)=$self->{DEF};
		my($info)=$self->{INFO};
		for(my($i)=0;$i<$connections->size();$i++) {
			#Meta::Utils::Output::print("doing db [".$i."]\n");
			my($ccon)=$connections->elem($i);
			# clean the database
			my($cinf)=Meta::Db::Info->new();
			$cinf->set_name($def->get_name());
			$cinf->set_type($ccon->get_type());
			my($stats)=Meta::Sql::Stats->new();
			$def->getsql_clean($stats,$cinf);
			# connect to it via a DBI
			my($cdbi)=Meta::Db::Dbi->new();
			$cdbi->connect_name($ccon,$cinf->get_name());
			# clean out the content by excuting the appropriate statements
			$cdbi->execute($stats);
			$dbi->push($cdbi);
			$info->push($cinf);
			# put elements into the stat (to get the right array size)
			$stat->push(defined);
		}
	}
	if($context eq "dbdata.tables.table.records.record") {
		# this loops through all statements and executes them
		my($stat)=$self->{STAT};
		for(my($i)=0;$i<$stat->size();$i++) {
			my($curr_stat)=$stat->getx($i);
			$curr_stat->execute();
		}
	}
	if($context eq "dbdata.tables.table.records.record.field") {
		# bind the value for each of the statements
		my($def)=$self->{DEF};
		my($dbi)=$self->{DBI};
		my($info)=$self->{INFO};
		my($field_data)=$self->{FIELD_DATA};
		my($field)=$def->get_field($self->{TABLE_NAME},$self->{FIELD_NAME});
		# watch the +1 since bind works from 1 and up
		my($number)=$def->get_field_number($self->{TABLE_NAME},$self->{FIELD_NAME})+1;
		my($type)=$field->get_type();
		my($stat)=$self->{STAT};
#		Meta::Utils::Output::print("name is [".$type->get_name()."]\n");
		if($type->get_name() eq "datetime") {
#			Meta::Utils::Output::print("before [".$field_data."]\n");
			$field_data=Meta::Utils::Time::unixdate2mysql($field_data);
#			Meta::Utils::Output::print("after [".$field_data."]\n");
		}
		for(my($i)=0;$i<$stat->size();$i++) {
			my($curr_stat)=$stat->getx($i);
			my($curr_info)=$info->getx($i);
			my($curr_dbi)=$dbi->getx($i);
			my($bind)=$type->getsql_bind($curr_info);
			if(defined($bind)) {
				$curr_stat->bind_param($number,$field_data,{ TYPE=>$bind });
			} else {
				$curr_stat->bind_param($number,$field_data);
			}
		}
	}
}

sub handle_char($$) {
	my($self,$elem)=@_;
#	Meta::Utils::Output::print("in here with elem [".$elem."]\n");
	my($context)=join(".",$self->context());
	if($context eq "dbdata.connections") {
		my($module)=Meta::Development::Module->new_name($elem);
		$self->{CONNECTIONS}=Meta::Db::Connections->new_modu($module);
	}
	if($context eq "dbdata.def") {
		my($module)=Meta::Development::Module->new_name($elem);
		$self->{DEF}=Meta::Db::Def->new_modu($module);
	}
	if($context eq "dbdata.sets.set") {
		# import $elem into the database
		#Meta::Utils::Output::print("going to import set [".$elem."]\n");
	}
	if($context eq "dbdata.tables.table.name") {
		$self->{TABLE_NAME}=$elem;
	}
	if($context eq "dbdata.tables.table.records.record.field.name") {
		$self->{FIELD_NAME}=$elem;
	}
	if($context eq "dbdata.tables.table.records.record.field.data") {
		$self->{FIELD_DATA}=$elem;
	}
	if($context eq "dbdata.tables.table.records.record.field.filedata") {
		Meta::Utils::File::File::load($elem,\($self->{FIELD_DATA}));
	}
	if($context eq "dbdata.tables.table.records.record.field.devedata") {
		Meta::Utils::File::File::load_deve($elem,\($self->{FIELD_DATA}));
	}
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Xml::Parsers::Dbdata - parser which imports into a database.

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

	MANIFEST: Dbdata.pm
	PROJECT: meta
	VERSION: 0.20

=head1 SYNOPSIS

	package foo;
	use Meta::Xml::Parsers::Dbdata qw();
	my($def_parser)=Meta::Xml::Parsers::Dbdata->new();
	$def_parser->parsefile($file);

=head1 DESCRIPTION

This parser helps you with importing xml files into a database.
The reason that we use a parser and not a DOM type object is that, in theory,
xml files can be very large and we dont want to follow the naive algorithm
of: get the data into RAM and then import it because the ram requirements may
be heavy. Currently we do it record by record. The parser recognizes the end
of each record and then issues the insert statement.
Options that need to be added are:
0. insertion only at the end of the entire read (back to the DOM module) -
	a user could use this if he knows he has a small enough database
	to fit into RAM.
1. insertion after each field - a user could use this if he has tables in which
	each field is very large (I wonder if that is possible..:).
In addition to all of the above this implementation this parser prepares
the statements to be executed because each statement is executed many times
and it is much more efficient to do it that way.
A weird thing here is that the Expat parser will not call the 'Char' handler
if no data is in there. Maybe I should use another handler ?

* an important feature is that this does importing into a list of databases
handled by a connection object.

=head1 FUNCTIONS

	new($)
	handle_start($$)
	handle_end($$)
	handle_char($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This gives you a new object for a parser.

=item B<handle_start($$)>

This will handle start tags.
This will create new objects according to the context.

=item B<handle_end($$)>

This will handle end tags.
This currently does nothing.

=item B<handle_char($$)>

This will handle actual text.
This currently, according to context, sets attributes for the various objects.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

Meta::Xml::Parsers::Base(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV data sets
	0.01 MV PDMT
	0.02 MV pictures database
	0.03 MV tree type organization in databases
	0.04 MV more movies
	0.05 MV md5 project
	0.06 MV database
	0.07 MV perl module versions in files
	0.08 MV movies and small fixes
	0.09 MV movie stuff
	0.10 MV graph visualization
	0.11 MV more thumbnail stuff
	0.12 MV thumbnail user interface
	0.13 MV more thumbnail issues
	0.14 MV website construction
	0.15 MV web site automation
	0.16 MV SEE ALSO section fix
	0.17 MV download scripts
	0.18 MV weblog issues
	0.19 MV teachers project
	0.20 MV md5 issues

=head1 SEE ALSO

Meta::Db::Connections(3), Meta::Db::Info(3), Meta::Development::Module(3), Meta::Ds::Array(3), Meta::Sql::Stats(3), Meta::Utils::File::File(3), Meta::Utils::Output(3), Meta::Utils::System(3), Meta::Utils::Time(3), Meta::Xml::Parsers::Base(3), strict(3)

=head1 TODO

-move parser to new style (stop using context).

-remmember that the characters call back does not give you all the data since xml parsers are
supposed to be streamlined (inherit from a parser that does ?!?).

-start actually using the DEF object I got to do sanity testing (toggleble ofcourse).

-use bind with param type on all parameters (remove the version with no binding type and make sure all types are mapped right)
