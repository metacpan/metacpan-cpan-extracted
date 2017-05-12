#!/bin/echo This is a perl module and should not be run

package Meta::Xml::Parsers::Defs;

use strict qw(vars refs subs);
use Meta::Db::Defs qw();
use Meta::Db::Def qw();
use Meta::Db::Set qw();
use Meta::Db::Enum qw();
use Meta::Db::Table qw();
use Meta::Db::Field qw();
use Meta::Db::User qw();
use Meta::Db::Member qw();
use Meta::Db::Constraint qw();
use Meta::Xml::Parsers::Base qw();
use Meta::Development::Module qw();

our($VERSION,@ISA);
$VERSION="0.02";
@ISA=qw(Meta::Xml::Parsers::Base);

#sub new($);
#sub get_result($);
#sub handle_start($$);
#sub handle_end($$);
#sub handle_char($$);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)=Meta::Xml::Parsers::Base->new();
	$self->setHandlers(
		"Start"=>\&handle_start,
		"End"=>\&handle_end,
		"Char"=>\&handle_char,
	);
	bless($self,$class);
	return($self);
}

sub get_result($) {
	my($self)=@_;
	return($self->{TEMP_DEFS});
}

sub handle_start($$) {
	my($self,$elem)=@_;
	if($self->in_context("defs",$elem)) {
		$self->{TEMP_DEFS}=Meta::Db::Defs->new();
	}
	if($self->in_context("defs.def",$elem)) {
		$self->{TEMP_DEF}=Meta::Db::Def->new();
		$self->{TEMP_PARENTS}=$self->{TEMP_DEF}->get_parents();
		$self->{TEMP_SETS}=$self->{TEMP_DEF}->get_sets();
		$self->{TEMP_ENUMS}=$self->{TEMP_DEF}->get_enums();
		$self->{TEMP_TABLES}=$self->{TEMP_DEF}->get_tables();
		$self->{TEMP_USERS}=$self->{TEMP_DEF}->get_users();
	}
	if($self->in_context("defs.def.parents.parent",$elem)) {
	}
	if($self->in_context("defs.def.sets.set",$elem)) {
		$self->{TEMP_SET}=Meta::Db::Set->new();
	}
	if($self->in_context("defs.def.sets.set.members.member",$elem)) {
		$self->{TEMP_SET_MEMBER}=Meta::Db::Member->new();
	}
	if($self->in_context("defs.def.enums.enum",$elem)) {
		$self->{TEMP_ENUM}=Meta::Db::Enum->new();
	}
	if($self->in_context("defs.def.enums.enum.members.member",$elem)) {
		$self->{TEMP_ENUM_MEMBER}=Meta::Db::Member->new();
	}
	if($self->in_context("defs.def.tables.table",$elem)) {
		$self->{TEMP_TABLE}=Meta::Db::Table->new();
	}
	if($self->in_context("defs.def.tables.table.fields",$elem)) {
		$self->{TEMP_FIELDS}=$self->{TEMP_TABLE}->get_fields();
	}
	if($self->in_context("defs.def.tables.table.fields.field",$elem)) {
		$self->{TEMP_FIELD}=Meta::Db::Field->new();
	}
	if($self->in_context("defs.def.tables.table.constraints.constraint",$elem)) {
		$self->{TEMP_CONSTRAINT}=Meta::Db::Constraint->new();
	}
	if($self->in_context("defs.def.users.user",$elem)) {
		$self->{TEMP_USER}=Meta::Db::User->new();
	}
}

sub handle_end($$) {
	my($self,$elem)=@_;
	if($self->in_context("defs.def",$elem)) {
		$self->{TEMP_DEFS}->insert($self->{TEMP_DEF});
	}
	if($self->in_context("defs.def.parents.parent",$elem)) {
		$self->{TEMP_PARENTS}->insert($self->{TEMP_PARENT}->get_name(),$self->{TEMP_PARENT});
	}
	if($self->in_context("defs.def.sets.set",$elem)) {
		$self->{TEMP_SETS}->insert($self->{TEMP_SET}->get_name(),$self->{TEMP_SET});
	}
	if($self->in_context("defs.def.sets.set.members.member",$elem)) {
		$self->{TEMP_SET}->insert($self->{TEMP_SET_MEMBER}->get_name(),$self->{TEMP_SET_MEMBER});
	}
	if($self->in_context("defs.def.enums.enum",$elem)) {
		$self->{TEMP_ENUMS}->insert($self->{TEMP_ENUM}->get_name(),$self->{TEMP_ENUM});
	}
	if($self->in_context("defs.def.enums.enum.members.member",$elem)) {
		$self->{TEMP_ENUM}->insert($self->{TEMP_ENUM_MEMBER}->get_name(),$self->{TEMP_ENUM_MEMBER});
	}
	if($self->in_context("defs.def.tables.table",$elem)) {
		$self->{TEMP_TABLES}->insert($self->{TEMP_TABLE}->get_name(),$self->{TEMP_TABLE});
	}
	if($self->in_context("defs.def.tables.table.fields.field",$elem)) {
		$self->{TEMP_FIELDS}->insert($self->{TEMP_FIELD}->get_name(),$self->{TEMP_FIELD});
	}
	if($self->in_context("defs.def.tables.table.contraints.constraint",$elem)) {
		$self->{TEMP_TABLE}->get_constraints()->insert($self->{TEMP_CONSTRAINT}->get_name(),$self->{TEMP_CONSTRAINT});
	}
	if($self->in_context("defs.def.users.user",$elem)) {
		$self->{TEMP_USERS}->insert($self->{TEMP_USER}->get_name(),$self->{TEMP_USER});
	}
}

sub handle_char($$) {
	my($self,$elem)=@_;
	if($self->in_abs_ccontext("defs.def.name")) {
		$self->{TEMP_DEF}->set_name($elem);
	}
	if($self->in_abs_ccontext("defs.def.description")) {
		$self->{TEMP_DEF}->set_description($elem);
	}
	if($self->in_ccontext("defs.def.parents.parent")) {
		my($module)=Meta::Development::Module->new_name($elem);
		$self->{TEMP_PARENT}=Meta::Db::Def->new_modu($module);
	}
	if($self->in_ccontext("defs.def.sets.set.name")) {
		$self->{TEMP_SET}->set_name($elem);
	}
	if($self->in_ccontext("defs.def.sets.set.description")) {
		$self->{TEMP_SET}->set_description($elem);
	}
	if($self->in_ccontext("defs.def.sets.set.members.member.name")) {
		$self->{TEMP_SET_MEMBER}->set_name($elem);
	}
	if($self->in_ccontext("defs.def.sets.set.members.member.description")) {
		$self->{TEMP_SET_MEMBER}->set_description($elem);
	}
	if($self->in_ccontext("defs.def.sets.set.members.member.default")) {
		$self->{TEMP_SET_MEMBER}->set_default($elem);
	}
	if($self->in_ccontext("defs.def.enums.enum.name")) {
		$self->{TEMP_ENUM}->set_name($elem);
	}
	if($self->in_ccontext("defs.def.enums.enum.description")) {
		$self->{TEMP_ENUM}->set_description($elem);
	}
	if($self->in_ccontext("defs.def.enums.enum.members.member.name")) {
		$self->{TEMP_ENUM_MEMBER}->set_name($elem);
	}
	if($self->in_ccontext("defs.def.enums.enum.members.member.description")) {
		$self->{TEMP_ENUM_MEMBER}->set_description($elem);
	}
	if($self->in_ccontext("defs.def.enums.enum.members.member.default")) {
		$self->{TEMP_ENUM_MEMBER}->set_default($elem);
	}
	if($self->in_ccontext("defs.def.tables.table.name")) {
		$self->{TEMP_TABLE}->set_name($elem);
	}
	if($self->in_ccontext("defs.def.tables.table.description")) {
		$self->{TEMP_TABLE}->set_description($elem);
	}
	if($self->in_ccontext("defs.def.tables.table.fields.field.name")) {
		$self->{TEMP_FIELD}->set_name($elem);
	}
	if($self->in_ccontext("defs.def.tables.table.fields.field.description")) {
		$self->{TEMP_FIELD}->set_description($elem);
	}
	if($self->in_ccontext("defs.def.tables.table.fields.field.type")) {
		$self->{TEMP_FIELD}->get_type()->set_name($elem);
	}
	if($self->in_ccontext("defs.def.tables.table.fields.field.tableref")) {
		$self->{TEMP_FIELD}->get_type()->set_tableref($elem);
	}
	if($self->in_ccontext("defs.def.tables.table.fields.field.fieldref")) {
		$self->{TEMP_FIELD}->get_type()->set_fieldref($elem);
	}
	if($self->in_ccontext("defs.def.tables.table.fields.field.optimized")) {
		$self->{TEMP_FIELD}->get_type()->set_optimized($elem);
	}
	if($self->in_ccontext("defs.def.tables.table.fields.field.setref")) {
		$self->{TEMP_FIELD}->get_type()->set_setref($elem);
	}
	if($self->in_ccontext("defs.def.tables.table.fields.field.enumref")) {
		$self->{TEMP_FIELD}->get_type()->set_enumref($elem);
	}
	if($self->in_ccontext("defs.def.tables.table.fields.field.null")) {
		$self->{TEMP_FIELD}->get_type()->set_null($elem);
	}
	if($self->in_ccontext("defs.def.tables.table.fields.field.default")) {
		$self->{TEMP_FIELD}->get_type()->set_default($elem);
	}
	if($self->in_ccontext("defs.def.tables.table.constraints.constraint.name")) {
		$self->{TEMP_CONSTRAINT}->set_name($elem);
	}
	if($self->in_ccontext("defs.def.tables.table.constraints.constraint.description")) {
		$self->{TEMP_CONSTRAINT}->set_description($elem);
	}
	if($self->in_ccontext("defs.def.tables.table.constraints.constraint.type")) {
		$self->{TEMP_CONSTRAINT}->set_type($elem);
	}
	if($self->in_ccontext("defs.def.tables.table.constraints.constraint.fieldrefs.fieldref")) {
		$self->{TEMP_CONSTRAINT}->insert($elem);
	}
	if($self->in_ccontext("defs.def.users.user.name")) {
		$self->{TEMP_USER}->set_name($elem);
	}
	if($self->in_ccontext("defs.def.users.user.description")) {
		$self->{TEMP_USER}->set_description($elem);
	}
	if($self->in_ccontext("defs.def.users.user.password")) {
		$self->{TEMP_USER}->set_password($elem);
	}
	if($self->in_ccontext("defs.def.users.user.func")) {
		$self->{TEMP_USER}->set_func($elem);
	}
	if($self->in_ccontext("defs.def.users.user.tabs")) {
		$self->{TEMP_USER}->set_tabs($elem);
	}
	if($self->in_ccontext("defs.def.users.user.host")) {
		$self->{TEMP_USER}->set_host($elem);
	}
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Xml::Parsers::Defs - Object to parse an many XML definition of a database.

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

	MANIFEST: Defs.pm
	PROJECT: meta
	VERSION: 0.02

=head1 SYNOPSIS

	package foo;
	use Meta::Xml::Parsers::Def qw();
	my($def_parser)=Meta::Xml::Parsers::Def->new();
	$def_parser->parsefile($file);
	my($def)=$def_parser->get_result();

=head1 DESCRIPTION

This object will create a Meta::Db::Defs for you from an xml definition for
a database structure.
This object extends XML::Parser and there is no doubt that this is the right
way to go about implementing such an object (all the handles get the parser
which is $self if you extend the parser which makes them methods and everything
is nice and clean from there on...).
The reason we dont inherit from XML::Parser is that the parser which actually
gets passed to the handlers is XML::Parser::Expat (which is the low level
object) and we inherit from that to get more object orientedness.

An issue to be considered is what happens if some elements are missing (the author
wants to put them in). For this case we create the basic object at the begining.

=head1 FUNCTIONS

	new($)
	get_result($)
	handle_start($$)
	handle_end($$)
	handle_char($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This gives you a new object for a parser.

=item B<get_result($)>

This method will retrieve the result of the parsing process.

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

	0.00 MV web site development
	0.01 MV teachers project
	0.02 MV md5 issues

=head1 SEE ALSO

Meta::Db::Constraint(3), Meta::Db::Def(3), Meta::Db::Defs(3), Meta::Db::Enum(3), Meta::Db::Field(3), Meta::Db::Member(3), Meta::Db::Set(3), Meta::Db::Table(3), Meta::Db::User(3), Meta::Development::Module(3), Meta::Xml::Parsers::Base(3), strict(3)

=head1 TODO

Nothing.
