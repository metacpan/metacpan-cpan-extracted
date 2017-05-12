#!/bin/echo This is a perl module and should not be run

package Meta::Xml::Parsers::Collector;

use strict qw(vars refs subs);
use Meta::Xml::Parsers::Base qw();
#use Meta::Utils::Output qw();

our($VERSION,@ISA);
$VERSION="0.02";
@ISA=qw(Meta::Xml::Parsers::Base);

#sub new($);
#sub handle_start($$);
#sub handle_end($$);
#sub handle_char($$);
#sub handle_endchar($$$);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)=Meta::Xml::Parsers::Base->new();
	$self->setHandlers(
		'Start'=>\&handle_start,
		'End'=>\&handle_end,
		'Char'=>\&handle_char,
	);
	bless($self,$class);
	$self->{TEMP}=defined;
	return($self);
}

sub handle_start($$) {
	my($self,$elem)=@_;
	$self->{TEMP}="";
}

sub handle_end($$) {
	my($self,$elem)=@_;
#	Meta::Utils::Output::print("value is [".$self->{TEMP}."]\n");
	$self->handle_endchar($self->{TEMP},$elem);
}

sub handle_char($$) {
	my($self,$elem)=@_;
	$self->{TEMP}.=$elem;
}

sub handle_endchar($$$) {
	my($self,$elem,$name)=@_;
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Xml::Parsers::Collector - Object to collect full XML elements.

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

	MANIFEST: Collector.pm
	PROJECT: meta
	VERSION: 0.02

=head1 SYNOPSIS

	package foo;
	use Meta::Xml::Parsers::Collector qw();
	my($parser)=Meta::Xml::Parsers::Collector->new();
	$parser->parsefile($file);

=head1 DESCRIPTION

The orignal XML::Parser gives you character information bit by bit and there
is no way to tell it to give you the whole content at a single instant. This parser
is defined to make life easier for you to do that. All you need to do is:
1. inherit from this parser instead of XML::Parser.
2. override the handle_endchar method (just like any other handler override for
XML::Parser) and the element you get there is the entire content.

A default handler for endchar is installed with this parser and does nothing.

Be aware that by inheriting from this parser you are assuming that all the char
data in your XML files is small enough to fit easily in RAM. The XML::Parser is
designed to do it's stuff the way it is for a reason (parsing xml files with very
large binary data in them etc...). If this is your need you better use the original
XML::Parser.

I do intend to make some extensions for this parser whereby you could say which elements
you want to handle piece by piece and which it can just gallop down but this is currently
unimplemented.

Take care to either not to override the handle_char method or to call your super class
implementation of it because this parser does stuff in there too.

You don't HAVE to overrider the handle_endchar method. You can write your parser and grow
with it. When you need it it will be there for you.

=head1 FUNCTIONS

	new($)
	handle_start($$)
	handle_end($$)
	handle_char($$)
	handle_endchar($$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This gives you a new parser object.

=item B<handle_start($$)>

This will handle start tags. Currently it just null the string collected.

=item B<handle_end($$)>

This will handle end tags.
This handler actually calls the handle_endchar which you have overriden (hopefully).

=item B<handle_char($$)>

This will handle actual text. This accumulates the snipplet given to it by XML::Parser
into the string.

=item B<handle_endchar($$$)>

This is the handle you need to override to get the entire element.
In this parser this does nothing.

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

	0.00 MV web site automation
	0.01 MV SEE ALSO section fix
	0.02 MV md5 issues

=head1 SEE ALSO

Meta::Xml::Parsers::Base(3), strict(3)

=head1 TODO

Nothing.
