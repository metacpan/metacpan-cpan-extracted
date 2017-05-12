package HTML::Embedded::Turtle;

use 5.008;
use strict;
no warnings;

use Data::UUID;
use RDF::RDFa::Parser '1.093';
use RDF::TriN3;
use RDF::Trine qw[iri literal blank statement];

sub biri { $_[0] =~ /^_:(.*)$/ ? blank($1) : iri(@_) }

use namespace::clean;
use Object::AUTHORITY;

BEGIN {
  $HTML::Embedded::Turtle::VERSION   = '0.404';
  $HTML::Embedded::Turtle::AUTHORITY = 'cpan:TOBYINK';
}

my $xhv = 'RDF::Trine::Namespace'->new('http://www.w3.org/1999/xhtml/vocab#');

sub new
{
	my $class = shift;
	my ($markup, $base_uri, $options) = @_;
	
	my $self = bless {
		markup   => $markup ,
		options  => $options ,
	} => $class;
	
	my $cfg = 'RDF::RDFa::Parser::Config';
	$options->{rdfa_options} ||= $cfg->new(
		($options->{markup} =~ /x(ht)?ml/i)
			? ($cfg->HOST_XHTML, $cfg->RDFA_10)
			: ($cfg->HOST_HTML5, $cfg->RDFA_10)
	);
	
	my $rdfa_parser      =
	$self->{rdfa_parser} = 'RDF::RDFa::Parser'->new($markup, $base_uri, $options->{rdfa_options});
	$self->{dom}         = $rdfa_parser->dom;
	$self->{base_uri}    = $rdfa_parser->uri;

	$self->_find_endorsed->_extract_graphs;
}

sub _find_endorsed
{
	my $self = shift;
	my $rdfa_parser = $self->{rdfa_parser};

	foreach my $o ($rdfa_parser->graph->objects(iri($self->{base_uri}), $xhv->meta))
	{
		# Endorsements must be URIs.
		next unless $o->is_resource;
		
		# Endorsements must be fragments within this document.
		my $must_start_with    = $self->{base_uri} . '#';
		my $must_start_with_re = qr/^\Q$must_start_with\E/;
		next unless $o->uri =~ $must_start_with_re;
			
		push @{ $self->{endorsements} }, $o->uri;
	}
	
	return $self;
}

sub _extract_graphs
{
	my $self = shift;
	my $uuid = Data::UUID->new;
	
	my @scripts = $self->{'dom'}->getElementsByTagName('script');
	foreach my $script (@scripts)
	{
		my $parser = $self->_choose_parser_by_type($script->getAttribute('type'))
			|| $self->_choose_parser_by_language($script->getAttribute('language'));
		next unless $parser;
		
		my $data  = $script->textContent;
		my $model = 'RDF::Trine::Model'->temporary_model;
		$parser->parse_into_model($self->{base_uri}, $data, $model);
		
		my $graphname = $script->hasAttribute('id')
			? join('#', $self->{base_uri}, $script->getAttribute('id'))
			: sprintf('_:bn%s', substr $uuid->create_hex, 2);
		
		$self->{graphs}->{$graphname} = $model;
	}
	
	return $self;
}

sub _choose_parser_by_type
{
	shift;

	for ($_[0])
	{
		return 'RDF::Trine::Parser::Turtle'->new    if m'^\s*(application|text)/(x-)?turtle\b'i;
		return 'RDF::Trine::Parser::NTriples'->new  if m'^\s*text/plain\b'i;
		return 'RDF::Trine::Parser::Notation3'->new if m'^\s*(application|text)/(x-)?(rdf\+)?n3\b'i;
		return 'RDF::Trine::Parser::RDFXML'->new    if m'^\s*(application/rdf\+xml)|(text/rdf)\b'i;
		return 'RDF::Trine::Parser::RDFJSON'->new   if m'^\s*application/(x-)?(rdf\+)?json\b'i;
	}
	
	return undef;
}

sub _choose_parser_by_language
{
	shift;
	return scalar eval { 'RDF::Trine::Parser'->new(@_) };
}

sub graph
{
	my $self = shift;
	my ($graph) = @_;
	
	if (!defined $graph)
	{
		my $model = 'RDF::Trine::Model'->temporary_model;
		while (my ($graph, $graph_model) = each %{ $self->{graphs} })
		{
			$graph_model->as_stream->each(sub {
				my ($s, $p, $o) = $_[0]->nodes;
				$model->add_statement(statement($s, $p, $o), biri($graph));
			});
		}
		return $model;
	}
	elsif ($graph eq '::ENDORSED')
	{
		my $model = 'RDF::Trine::Model'->temporary_model;
		while (my ($graph, $graph_model) = each %{ $self->{graphs} })
		{
			next unless grep { $_ eq $graph } @{$self->{endorsements}};
			$graph_model->as_stream->each(sub {
				my ($s, $p, $o) = $_[0]->nodes;
				$model->add_statement(statement($s, $p, $o), biri($graph));
			});
		}
		return $model;
	}
	elsif (defined $self->{graphs}->{$graph})
	{
		return $self->{graphs}->{$graph};
	}
}

sub union_graph
{
	shift->graph;
}

sub endorsed_union_graph
{
	shift->graph('::ENDORSED');
}

sub graphs
{
	my $self = shift;
	my ($graph) = @_;
	
	if (!defined $graph)
	{
		my $rv = {};
		foreach my $graph (keys %{ $self->{graphs} })
		{
			$rv->{$graph} = $self->{graphs}->{$graph};
		}
		return $rv;
	}
	elsif ($graph == '::ENDORSED')
	{
		my $rv = {};
		foreach my $graph (@{ $self->{endorsements} })
		{
			if (defined $self->{graphs}->{$graph})
			{
				$rv->{$graph} = $self->{graphs}->{$graph};
			}
		}
		return $rv;
	}
	elsif (defined $self->{graphs}->{$graph})
	{
		return  { $graph => $self->{graphs}->{$graph} };
	}
}

sub all_graphs
{
	shift->graphs;	
}

sub endorsed_graphs
{
	shift->graphs('::ENDORSED');
}

sub endorsements
{
	@{ shift->{endorsements} };
}

sub dom
{
	shift->{dom}
}

sub uri
{
	shift->{rdfa_parser}->uri(@_);
}

1;

__END__

=head1 NAME

HTML::Embedded::Turtle - embedding RDF in HTML the crazy way

=head1 SYNOPSIS

 use HTML::Embedded::Turtle;
 
 my $het = HTML::Embedded::Turtle->new($html, $base_uri);
 foreach my $graph ($het->endorsements)
 {
   my $model = $het->graph($graph);
   
   # $model is an RDF::Trine::Model. Do something with it.
 }

=head1 DESCRIPTION

RDF can be embedded in (X)HTML using simple E<lt>scriptE<gt> tags. This is
described at L<http://esw.w3.org/N3inHTML>. This gives you a file format
that can contain multiple (optionally named) graphs. The document as a whole
can "endorse" a graph by including:

 <link rel="meta" href="#foo" />

Where "#foo" is a fragment identifier pointing to a graph.

 <script type="text/turtle" id="foo"> ... </script>

The rel="meta" stuff is parsed using an RDFa parser, so equivalent RDFa
works too.

This module parses HTML files containing graphs like these, and allows
you to access them each individually; as a union of all graphs on the page;
or as a union of just the endorsed graphs.

Despite the module name, this module supports a variety of
E<lt>script typeE<gt>s: text/turtle, application/turtle, application/x-turtle
text/plain (N-Triples), text/n3 (Notation 3), application/x-rdf+json (RDF/JSON),
application/json (RDF/JSON), and application/rdf+xml (RDF/XML).

The deprecated attribute "language" is also supported:

 <script language="Turtle" id="foo"> ... </script>

Languages supported are (case insensitive): "Turtle", "NTriples", "RDFJSON",
"RDFXML" and "Notation3".

=head2 Constructor

=over 4

=item C<< HTML::Embedded::Turtle->new($markup, $base_uri, \%opts) >>

Create a new object. $markup is the HTML or XHTML markup to parse;
$base_uri is the base URI to use for relative references.

Options include:

=over 4

=item * B<markup>

Choose which parser to use: 'html' or 'xml'. The former chooses
HTML::HTML5::Parser, which can handle tag soup; the latter chooses
XML::LibXML, which cannot. Defaults to 'html'.

=item * B<rdfa_options>

A set of options to be parsed to RDF::RDFa::Parser when looking for
endorsements. See L<RDF::RDFa::Parser::Config>. The default is
probably sensible.

=back

=back

=head2 Public Methods

=over 4

=item C<< union_graph >>

A union graph of all graphs found in the document, as an RDF::Trine::Model.
Note that the returned model contains quads.

=item C<< endorsed_union_graph >>

A union graph of only the endorsed graphs, as an RDF::Trine::Model.
Note that the returned model contains quads.

=item C<< graph($name) >>

A single graph from the page.

=item C<< graphs >>

=item C<< all_graphs >>

A hashref where the keys are graph names and the values are
RDF::Trine::Models. Some graph names will be URIs, and others
may be blank nodes (e.g. "_:foobar").

C<graphs> and C<all_graphs> are aliases for each other.

=item C<< endorsed_graphs >>

Like C<all_graphs>, but only returns endorsed graphs. Note that
all endorsed graphs will have graph names that are URIs.

=item C<< endorsements >>

Returns a list of URIs which are the names of endorsed graphs. Note that
the presence of a URI C<$x> in this list does not imply that
C<< $het->graph($x) >> will be defined.

=item C<< dom >>

Returns the page DOM.

=item C<< uri >>

Returns the page URI.

=back

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

Please forgive me in advance for inflicting this module upon you.

=head1 SEE ALSO

L<RDF::RDFa::Parser>, L<RDF::Trine>, L<RDF::TriN3>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2011, 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut
