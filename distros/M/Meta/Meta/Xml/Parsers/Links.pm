#!/bin/echo This is a perl module and should not be run

package Meta::Xml::Parsers::Links;

use strict qw(vars refs subs);
use XML::Parser::Expat qw();
use Meta::Development::Links qw();
use Meta::Development::Link qw();
use Meta::Utils::Output qw();

our($VERSION,@ISA);
$VERSION="0.12";
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
	my($self)=XML::Parser::Expat->new(ParseParamEnt=>0);
	if(!$self) {
		throw Meta::Error::Simple("didn't get a parser");
	}
	#Meta::Utils::Output::print("in here");
	$self->setHandlers(
		"Start"=>\&handle_start,
		"End"=>\&handle_end,
		"Char"=>\&handle_char,
	);
	bless($self,$class);
	return($self);
}

sub get_result($$) {
	my($self)=@_;
	return($self->{RESULT});
}

sub handle_start($$) {
	my($self,$elem)=@_;
	my($context)=join(".",$self->context(),$elem);
	if($context eq "links") {
		$self->{TEMP_LINKS}=Meta::Development::Links->new();
	}
	if($context eq "links.link") {
		$self->{TEMP_LINK}=Meta::Development::Link->new();
	}
}

sub handle_end($$) {
	my($self,$elem)=@_;
	my($context)=join(".",$self->context(),$elem);
	if($context eq "links") {
		$self->{RESULT}=$self->{TEMP_LINKS};
	}
	if($context eq "links.link") {
		$self->{TEMP_LINKS}->push($self->{TEMP_LINK});
	}
}

sub handle_char($$) {
	my($self,$elem)=@_;
	my($context)=join(".",$self->context());
	if($context eq "links.link.name") {
		$self->{TEMP_LINK}->set_name($elem);
	}
	if($context eq "links.link.description") {
		$self->{TEMP_LINK}->set_description($elem);
	}
	if($context eq "links.link.longdescription") {
		$self->{TEMP_LINK}->set_longdescription($elem);
	}
	if($context eq "links.link.version") {
		$self->{TEMP_LINK}->set_version($elem);
	}
	if($context eq "links.link.platforms.platform") {
		$self->{TEMP_LINK}->get_platforms()->push($elem);
	}
	if($context eq "links.link.objects.object") {
		$self->{TEMP_LINK}->get_objects()->push($elem);
	}
	if($context eq "links.link.libraries.library") {
		$self->{TEMP_LINK}->get_libraries()->push($elem);
	}
	if($context eq "links.link.elibraries.elibrary") {
		$self->{TEMP_LINK}->get_elibraries()->push($elem);
	}
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Xml::Parsers::Links - parser for XML/links files.

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

	MANIFEST: Links.pm
	PROJECT: meta
	VERSION: 0.12

=head1 SYNOPSIS

	package foo;
	use Meta::Xml::Parsers::Links qw();
	my($deps_parser)=Meta::Xml::Parsers::Links->new();
	$deps_parser->parsefile($file);
	my($deps)=$desp_parser->get_result();

=head1 DESCRIPTION

This is a parser which parses an XML/links file and constructs
a Meta::Development::Links object out of it.

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

This will return the dependency object which is the result of the parse.

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

	0.00 MV XML rules
	0.01 MV perl packaging
	0.02 MV more perl packaging
	0.03 MV md5 project
	0.04 MV database
	0.05 MV perl module versions in files
	0.06 MV movies and small fixes
	0.07 MV thumbnail user interface
	0.08 MV more thumbnail issues
	0.09 MV website construction
	0.10 MV web site automation
	0.11 MV SEE ALSO section fix
	0.12 MV md5 issues

=head1 SEE ALSO

Meta::Development::Link(3), Meta::Development::Links(3), Meta::Utils::Output(3), XML::Parser::Expat(3), strict(3)

=head1 TODO

Nothing.
