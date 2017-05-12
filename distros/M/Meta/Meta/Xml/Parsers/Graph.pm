#!/bin/echo This is a perl module and should not be run

package Meta::Xml::Parsers::Graph;

use strict qw(vars refs subs);
use Meta::Ds::Graph qw();
use XML::Parser::Expat qw();

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
	my($self)=XML::Parser::Expat->new();
	if(!$self) {
		throw Meta::Error::Simple("didn't get a parser");
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
	return($self->{GRAPH});
}

sub handle_start($$) {
	my($self,$elem)=@_;
	my($context)=join(".",$self->context(),$elem);
	if($context eq "graph") {
		$self->{GRAPH}=Meta::Ds::Graph->new();
	}
}

sub handle_end($$) {
	my($self,$elem)=@_;
	my($context)=join(".",$self->context(),$elem);
	if($context eq "graph.nodes.node") {
		$self->{GRAPH}->node_insert($self->{NODE});
	}
	if($context eq "graph.edges.edge") {
		$self->{GRAPH}->edge_insert($self->{NODE_FROM},$self->{NODE_TO});
	}
}

sub handle_char($$) {
	my($self,$elem)=@_;
	my($context)=join(".",$self->context());
	if($context eq "graph.nodes.node") {
		$self->{NODE}=$elem;
	}
	if($context eq "graph.edges.edge.from") {
		$self->{NODE_FROM}=$elem;
	}
	if($context eq "graph.edges.edge.to") {
		$self->{NODE_TO}=$elem;
	}
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Xml::Parsers::Graph - Object to parse an XML definition of a graph.

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

	MANIFEST: Graph.pm
	PROJECT: meta
	VERSION: 0.12

=head1 SYNOPSIS

	package foo;
	use Meta::Xml::Parsers::Graph qw();
	my($graph_parser)=Meta::Xml::Parsers::Graph->new();
	$graph_parser->parsefile($file);
	my($graph)=$graph_parser->get_result();

=head1 DESCRIPTION

This object will create a Meta::Ds::Graph for you from an xml definition for
a graph structure. 
This object extends XML::Parser and there is no doubt that this is the right
way to go about implementing such an object (all the handles get the parser
which is $self if you extend the parser which makes them methods and everything
is nice and clean from there on...).
The reason we dont inherit from XML::Parser is that the parser which actually
gets passed to the handlers is XML::Parser::Expat (which is the low level
object) and we inherit from that to get more object orientedness.

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

	0.00 MV c++ stuff
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

Meta::Ds::Graph(3), XML::Parser::Expat(3), strict(3)

=head1 TODO

Nothing.
