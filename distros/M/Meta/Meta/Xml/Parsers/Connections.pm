#!/bin/echo This is a perl module and should not be run

package Meta::Xml::Parsers::Connections;

use strict qw(vars refs subs);
use Meta::Db::Connections qw();
use Meta::Db::Connection qw();
use XML::Parser::Expat qw();

our($VERSION,@ISA);
$VERSION="0.37";
@ISA=qw(XML::Parser::Expat);

#sub new($);
#sub get_result($);
#sub handle_start($$);
#sub handle_end($$);
#sub handle_char($$);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)=XML::Parser::Expat->new();
	if(!$self) {
		throw Meta::Error::Simple("didnt get a parser");
	}
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
	return($self->{TEMP_CONNECTIONS});
}

sub handle_start($$) {
	my($self,$elem)=@_;
	my($context)=join(".",$self->context(),$elem);
	if($context eq "connections") {
		$self->{TEMP_CONNECTIONS}=Meta::Db::Connections->new();
	}
	if($context eq "connections.connection") {
		$self->{TEMP_CONNECTION}=Meta::Db::Connection->new();
	}
}

sub handle_end($$) {
	my($self,$elem)=@_;
	my($context)=join(".",$self->context(),$elem);
	if($context eq "connections.connection") {
		$self->{TEMP_CONNECTIONS}->insert($self->{TEMP_CONNECTION}->get_name(),$self->{TEMP_CONNECTION});
	}
}

sub handle_char($$) {
	my($self,$elem)=@_;
	my($context)=join(".",$self->context());
	if($context eq "connections.default") {
		$self->{TEMP_CONNECTIONS}->set_default($elem);
	}
	if($context eq "connections.connection.name") {
		$self->{TEMP_CONNECTION}->set_name($elem);
	}
	if($context eq "connections.connection.type") {
		$self->{TEMP_CONNECTION}->set_type($elem);
	}
	if($context eq "connections.connection.use_host") {
		$self->{TEMP_CONNECTION}->set_use_host($elem);
	}
	if($context eq "connections.connection.host") {
		$self->{TEMP_CONNECTION}->set_host($elem);
	}
	if($context eq "connections.connection.use_port") {
		$self->{TEMP_CONNECTION}->set_use_port($elem);
	}
	if($context eq "connections.connection.port") {
		$self->{TEMP_CONNECTION}->set_port($elem);
	}
	if($context eq "connections.connection.use_user") {
		$self->{TEMP_CONNECTION}->set_use_user($elem);
	}
	if($context eq "connections.connection.user") {
		$self->{TEMP_CONNECTION}->set_user($elem);
	}
	if($context eq "connections.connection.use_password") {
		$self->{TEMP_CONNECTION}->set_use_password($elem);
	}
	if($context eq "connections.connection.password") {
		$self->{TEMP_CONNECTION}->set_password($elem);
	}
	if($context eq "connections.connection.use_default_db") {
		$self->{TEMP_CONNECTION}->set_use_default_db($elem);
	}
	if($context eq "connections.connection.default_db") {
		$self->{TEMP_CONNECTION}->set_default_db($elem);
	}
	if($context eq "connections.connection.use_extra_options") {
		$self->{TEMP_CONNECTION}->set_use_extra_options($elem);
	}
	if($context eq "connections.connection.extra_options") {
		$self->{TEMP_CONNECTION}->set_extra_options($elem);
	}
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Xml::Parsers::Connections - Object to parse an XML definition of Connections object.

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

	MANIFEST: Connections.pm
	PROJECT: meta
	VERSION: 0.37

=head1 SYNOPSIS

	package foo;
	use Meta::Xml::Parsers::Connections qw();
	my($dbdef)=Meta::Xml::Parsers::Connections->new();
	$dbdef->parsefile($file);
	my($num_table)=$syntax->num_table();

=head1 DESCRIPTION

This object will create a Meta::Db::Connections for you from an xml definition
for list of connections to database servers.
This object extends XML::Parser and there is no doubt that this is the right
way to go about implementing such an object (all the handles get the parser
which is $self if you extend the parser which makes them methods and everything
is nice and clean from there on...). The problem with this approach is that
not the XML::Parser object is the one which is passed to the underlying
implementation but rather the XML::Parser::Expat object. So we inherit from
that.

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

This method retrieves the output of the parsing process.

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

XML::Parser::Expat(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV convert all database descriptions to XML
	0.01 MV make quality checks on perl code
	0.02 MV more perl checks
	0.03 MV make Meta::Utils::Opts object oriented
	0.04 MV check that all uses have qw
	0.05 MV fix todo items look in pod documentation
	0.06 MV more on tests/more checks to perl
	0.07 MV more perl code quality
	0.08 MV fix all tests change
	0.09 MV change new methods to have prototypes
	0.10 MV correct die usage
	0.11 MV perl code quality
	0.12 MV more perl quality
	0.13 MV more perl quality
	0.14 MV perl documentation
	0.15 MV more perl quality
	0.16 MV perl qulity code
	0.17 MV more perl code quality
	0.18 MV revision change
	0.19 MV languages.pl test online
	0.20 MV history change
	0.21 MV perl reorganization
	0.22 MV fix up xml parsers
	0.23 MV advance the contacts project
	0.24 MV perl packaging
	0.25 MV more perl packaging
	0.26 MV XSLT, website etc
	0.27 MV md5 project
	0.28 MV database
	0.29 MV perl module versions in files
	0.30 MV movies and small fixes
	0.31 MV thumbnail user interface
	0.32 MV more thumbnail issues
	0.33 MV website construction
	0.34 MV web site automation
	0.35 MV SEE ALSO section fix
	0.36 MV teachers project
	0.37 MV md5 issues

=head1 SEE ALSO

Meta::Db::Connection(3), Meta::Db::Connections(3), XML::Parser::Expat(3), strict(3)

=head1 TODO

Nothing.
