package HTTP::LRDD;

use strict;
use 5.010;

use HTML::HTML5::Parser 0.107;
use HTML::HTML5::Sanity 0.102;
use HTTP::Link::Parser 0.102 qw(:all);
use HTTP::Status 0 qw(:constants);
use Object::AUTHORITY 0;
use RDF::TrineX::Functions 0 -shortcuts;
use RDF::RDFa::Parser 1.096;
use RDF::Query 2.900;
use Scalar::Util 0 qw(blessed);
use URI 0;
use URI::Escape 0;
use XML::Atom::OWL 0.100;
use XRD::Parser 0.101;

my (@Predicates, @_Predicates, @MediaTypes);

BEGIN
{
	$HTTP::LRDD::AUTHORITY = 'cpan:TOBYINK';
	$HTTP::LRDD::VERSION   = '0.106';
	
	@Predicates = (
		'describedby',
		'lrdd',
		'http://www.w3.org/2007/05/powder-s#describedby',
		'http://www.w3.org/1999/xhtml/vocab#meta',
		'http://www.w3.org/2000/01/rdf-schema#seeAlso',
	);
	@_Predicates = @Predicates;
	@MediaTypes = (
		'application/xrd+xml',
		'application/rdf+xml',
		'text/turtle',
		'application/atom+xml;q=0.9',
		'application/xhtml+xml;q=0.9',
		'text/html;q=0.9',
		'*/*;q=0.1',
	);
}

sub __rdf_query
{
	my ($sparql, $model) = @_;
	my $result = RDF::Query->new($sparql)->execute($model);
	
	if ($result->is_boolean)
		{ return $result->get_boolean }
	elsif ($result->is_bindings)
		{ return $result }
	
	$result->is_graph or die;
	
	my $return = RDF::Trine::Model->new;
	$return->add_hashref( $result->as_hashref );
	return $return;
}

sub import
{
	my $class   = shift;
	@Predicates = @_ if @_;
}

sub new
{
	my $class   = shift;
	my $self    = bless { }, $class;
	
	$self->{predicates} = @_ ? \@_ : \@Predicates;
	
	return $self;
}

sub new_strict
{
	my $class   = shift;
	return $class->new(qw(describedby lrdd));
}

sub new_default
{
	my $class   = shift;
	return $class->new(@_Predicates);
}

sub discover
{
	my $self = shift;
	my $uri  = shift;
	my $list = wantarray;
	
	$self = $self->new
		unless blessed($self) && $self->isa(__PACKAGE__);
	
	my (@results, $rdfa, $rdfx, $response);
	
	# STEP 1: check the HTTP headers for a descriptor link
	if ($uri =~ /^https?:/i)
	{
		$response = $self->_ua->head($uri);
		my $model    = rdf_parse();
		
		# Parse HTTP 'Link' headers.
		parse_links_into_model($response => $model);
		
		if ($response->code eq HTTP_SEE_OTHER) # 303 Redirect
		{
			my $seeother = URI->new_abs(
				$response->header('Location'),
				URI->new($uri));
			
			$model->add_hashref({
				$uri => {
					'http://www.w3.org/2000/01/rdf-schema#seeAlso' => [
						{ 'value' => "$seeother" , 'type' => 'uri' },
					],
				},
			});
		}
		
		my $iterator = __rdf_query($self->_make_sparql($uri, $list), $model);
		while (my $row = $iterator->next)
		{
			push @results, $row->{'descriptor'}->uri
				if defined $row->{'descriptor'}
				&& $row->{'descriptor'}->is_resource;
		}
		
		# Bypass further processing if we've got a result and we only wanted one!
		return $results[0] if @results && !$list;
	}
	
	# STEP 2: check the HTTP body (RDF) for a descriptor link
	if ($uri =~ /^https?:/i)
	{
		my $model = rdf_parse();
		
		# Parse as RDFa, if the response is RDFa.
		($response, $rdfa) = $self->_cond_parse_rdfa($response, $model, $uri);
		
		# If the response was not RDFa, try parsing as RDF.
		($response, $rdfx) = $self->_cond_parse_rdf($response, $model, $uri)
			unless defined $rdfa;
		
		my $iterator = __rdf_query($self->_make_sparql($uri, $list), $model);
		while (my $row = $iterator->next)
		{
			push @results, $row->{'descriptor'}->uri
				if defined $row->{'descriptor'}
				&& $row->{'descriptor'}->is_resource;
		}
		
		# Bypass further processing if we've got a result and we only wanted one!
		return $results[0] if @results && !$list;
	}
	
	# STEP 2a: AtomOWL doesn't use <id> as a subject URI.
	if (defined $rdfa && $rdfa->{'atom_parser'} && blessed($self->{'cache'}->{$uri}))
	{
		my $iterator = __rdf_query($self->_make_sparql_atomowl($uri, $list), $self->{'cache'}->{$uri});
		while (my $row = $iterator->next)
		{
			push @results, $row->{'descriptor'}->uri
				if defined $row->{'descriptor'}
				&& $row->{'descriptor'}->is_resource;
		}
		
		# Bypass further processing if we've got a result and we only wanted one!
		return $results[0] if @results && !$list;
	}
	
	# STEP 3: try host-meta.
	my $hostmeta_location = XRD::Parser::hostmeta_location($uri);
	unless (blessed($self->{'cache'}->{$hostmeta_location}))
	{
		eval
		{
			my $hm = XRD::Parser->hostmeta($uri);
			$hm->consume;
			$self->{'cache'}->{$hostmeta_location} = $hm->graph;
		};
	}
	if (blessed( $self->{'cache'}->{$hostmeta_location} ))
	{
		my $hm_graph = $self->{'cache'}->{$hostmeta_location};
		
		# First try original query.
		my $iterator = __rdf_query($self->_make_sparql($uri, $list), $hm_graph);
		while (my $row = $iterator->next)
		{
			push @results, $row->{'descriptor'}->uri
				if defined $row->{'descriptor'}
				&& $row->{'descriptor'}->is_resource;
		}
		
		# Then try using host-meta URI templates.
		$iterator = __rdf_query($self->_make_sparql_template($uri, $list), $hm_graph);
		while (my $row = $iterator->next)
		{
			if (defined $row->{'descriptor'}
			&&  $row->{'descriptor'}->is_literal
			&&  $row->{'descriptor'}->literal_datatype eq (XRD::Parser->URI_XRD.'URITemplate'))
			{
				my $u = $row->{'descriptor'}->literal_value;
				$u =~ s/\{uri\}/uri_escape($uri)/ie;
				push @results, $u;
			}
		}
	}
	
	# STEP 4: the resource may be self-describing
	if ($rdfa || $rdfx)
	{
		my $data = $self->parse($uri);
		
		# only add $uri to @results
		#    if we're completely desparate,
		#    or it seems to provide something useful.
		push @results, $uri
			if !@results
			|| $data->count_statements(RDF::Trine::Node::Resource->new($uri), undef, undef);
	}
	
	if (@results)
	{
		return $list ? @results : $results[0];
	}
	
	return;
}

sub parse
{
	my $self = shift;
	my $uri  = shift or return undef;
	
	$self = $self->new
		unless blessed($self) && $self->isa(__PACKAGE__);
	
	unless (blessed($self->{'cache'}{$uri})
	and $self->{'cache'}{$uri}->isa('RDF::Trine::Model'))
	{
		my $response = $self->_ua->get($uri);
		my $model    = rdf_parse();
		
		# Parse as RDFa, if the response is RDFa.
		($response, my $rdfa) = $self->_cond_parse_rdfa($response, $model, $uri);
		
		# If the response was not RDFa, try parsing as RDF.
		($response, my $rdfx) = $self->_cond_parse_rdf($response, $model, $uri)
			unless defined $rdfa;
			
		# If the response was not RDFa or another type of RDF, try parsing as XRD.
		($response, my $xrd) = $self->_cond_parse_xrd($response, $model, $uri)
			unless defined $rdfa || defined $rdfx;
	}
	
	return $self->{'cache'}{$uri};
}

sub process
{
	my $self = shift;
	my $uri  = shift;
	
	$self = $self->new
		unless blessed($self) && $self->isa(__PACKAGE__);
		
	my $descriptor = $self->discover($uri);
	return $self->parse($descriptor) // rdf_parse();
}

sub process_all
{
	my $self = shift;
	my $uri  = shift;
	
	$self = $self->new
		unless blessed($self) && $self->isa(__PACKAGE__);
	
	my @descriptors = $self->discover($uri);
	my $model       = $self->parse($uri) // rdf_parse();
	
	foreach my $descriptor (@descriptors)
	{
		my $description = $self->parse($descriptor);
		rdf_parse($description, model=>$model); # merge
	}
	
	return $model;
}

sub _make_sparql
{
	my ($self, $uri, $list) = @_;
	
	my @p;
	foreach my $p (@{ $self->{'predicates'} })
	{
		push @p, sprintf('{ <%s> <%s> ?descriptor . }',
			$uri, HTTP::Link::Parser::relationship_uri($p));
	}
	return $list ?
		'SELECT DISTINCT ?descriptor WHERE { '.(join ' UNION ', @p).' }' :
		'SELECT DISTINCT ?descriptor WHERE { OPTIONAL '.(join ' OPTIONAL ', @p).' }';
}

sub _make_sparql_atomowl
{
	my ($self, $uri, $list) = @_;
	
	my @p;
	foreach my $p (@{ $self->{'predicates'} })
	{
		push @p, sprintf('{ ?feed <%s> ?descriptor . }',
			HTTP::Link::Parser::relationship_uri($p));
	}
	
	# this can be ambiguous in the face of atom:source.
	return $list ?
		'SELECT DISTINCT ?descriptor WHERE { ?feed a <http://bblfish.net/work/atom-owl/2006-06-06/#Feed> . { '.(join ' UNION ', @p).'} }' :
		'SELECT DISTINCT ?descriptor WHERE { ?feed a <http://bblfish.net/work/atom-owl/2006-06-06/#Feed> . OPTIONAL '.(join ' OPTIONAL ', @p).' }';
}

sub _make_sparql_template
{
	my ($self, $uri, $list) = @_;
	my $hosturi = XRD::Parser::host_uri( $uri );
	my @p;
	foreach my $p (@{ $self->{'predicates'} })
	{
		push @p, sprintf('{ <%s> <%s> ?descriptor . }',
			$hosturi, XRD::Parser::template_uri(HTTP::Link::Parser::relationship_uri($p)));
	}
	return $list ?
		'SELECT DISTINCT ?descriptor WHERE { '.(join ' UNION ', @p).' }' :
		'SELECT DISTINCT ?descriptor WHERE { OPTIONAL '.(join ' OPTIONAL ', @p).' }';
}

sub _cond_parse_rdfa
{
	my ($self, $response, $model, $uri) = @_;
	
	my $rdfa_options;
	my $rdfa_input;
	
	if ($response->content_type =~ m'^(application/atom\+xml|image/svg\+xml|application/xhtml\+xml|text/html)'i)
	{
		if (uc $response->request->method ne 'GET')
		{
			$self->_ua->max_redirect(3);
			$response = $self->_ua->get($uri);
			$self->_ua->max_redirect(0);
		}
	}
	else
	{
		return ($response, undef);
	}
	
	$response->is_success or return ($response, undef);
	
	my $hostlang = RDF::RDFa::Parser::Config->host_from_media_type($response->content_type);
	$rdfa_options = RDF::RDFa::Parser::Config->new($hostlang, RDF::RDFa::Parser::Config->RDFA_GUESS,
		atom_parser => ($response->content_type =~ m'^application/atom\+xml'i ? 1 : 0),
		);
	
	if (defined $rdfa_options)
	{
		# Make sure any predicate keywords are recognised in @rel/@rev.
		# This can override some normal RDFa keywords in some cases.
		foreach my $attr (qw(rel rev))
		{
			foreach my $p (@{ $self->{'predicates'} })
			{
				$rdfa_options->{'keywords'}->{$attr}->{$p}
					= HTTP::Link::Parser::relationship_uri($p)
					unless $p =~ /:/;
				$rdfa_options->{'keywords'}->{'insensitive'}->{$attr}->{$p}
					= HTTP::Link::Parser::relationship_uri($p)
					unless $p =~ /:/;
			}
		}
		
		$rdfa_input = $response->decoded_content
			unless defined $rdfa_input;
		
		my $parser = RDF::RDFa::Parser->new($rdfa_input, $response->base, $rdfa_options, $model->_store);
		$parser->consume;
		$self->{'cache'}->{$uri} = $model;
		return ($response, $rdfa_options);
	}
	
	return ($response, undef);
}

sub _cond_parse_rdf
{
	my ($self, $response, $model, $uri) = @_;
	my $type;
	
	if ($response->content_type =~ m'^(application/rdf\+xml|(application|text)/(x-)?(rdf\+)?(turtle|n3|json))'i)
	{
		if (uc $response->request->method ne 'GET')
		{
			$self->_ua->max_redirect(3);
			$response = $self->_ua->get($uri);
			$self->_ua->max_redirect(0);
		}
		
		$type = 'Turtle';
		$type = 'RDFXML'  if $response->content_type =~ /rdf.xml/;
		$type = 'RDFJSON' if $response->content_type =~ /json/;
	}
	else
	{
		return ($response, undef);
	}
	
	$response->is_success or return ($response, undef);
	
	rdf_parse($response->decoded_content, type=>$type, model=>$model, base=>$response->base);
	$self->{'cache'}->{$uri} = $model;
	return ($response, 1);
}

sub _cond_parse_xrd
{
	my ($self, $response, $model, $uri) = @_;
	my $type;
	
	if ($response->content_type =~ m'^(text/plain|application/octet-stream|application/xrd\+xml|(application|text)/xml)'i)
	{
		if (uc $response->request->method ne 'GET')
		{
			$self->_ua->max_redirect(3);
			$response = $self->_ua->get($uri);
			$self->_ua->max_redirect(0);
		}
	}
	else
	{
		return ($response, undef);
	}
	
	$response->is_success or return ($response, undef);
	
	my $xrd = XRD::Parser->new($response->decoded_content, $response->base, {loose_mime=>1}, $model->_store);
	$xrd->consume;
	$self->{'cache'}->{$uri} = $model;
	return ($response, $xrd);
}

sub _ua
{
	my $self = shift;
	
	unless (defined $self->{ua})
	{
		$self->{ua} = LWP::UserAgent->new;
		$self->{ua}->agent(sprintf('%s/%s (%s) ', __PACKAGE__, __PACKAGE__->VERSION, __PACKAGE__->AUTHORITY));
		$self->{ua}->default_header(Accept => (join ', ', @MediaTypes));
		$self->{ua}->max_redirect(0);
	}
	
	return $self->{ua};
}

1;

=head1 NAME

HTTP::LRDD - link-based resource descriptor discovery

=head1 SYNOPSIS

 use HTTP::LRDD;
 
 my $lrdd        = HTTP::LRDD->new;
 my @descriptors = $lrdd->discover($resource);
 foreach my $descriptor (@descriptors)
 {
   my $description = $lrdd->parse($descriptor);
   # $description is an RDF::Trine::Model
 }
 
=head1 DESCRIPTION

Note: the LRDD specification has ceased to be, with some parts being merged into
the host-meta Internet Draft. This CPAN module will go in its own direction,
bundling up best-practice techniques for discovering links and descriptors for a
given URI.

=head2 Import Routine

=over 4

=item C<< use HTTP::LRDD (@predicates) >>

When importing HTTP::LRDD, you can optionally provide a list of
predicate URIs (i.e. the URIs which rel values expand to). This
may also include IANA-registered link types, which are short tokens
rather than full URIs. If you do not provide a list of predicate
URIs, then a sensible default set is used.

Because this configuration is global in nature, it is not recommended.
It is better to supply a list of predicates to the constructor
instead, or rely on the defaults. This feature should be regarded
as deprecated.

=back

=head2 Constructors

=over 4

=item C<< HTTP::LRDD->new(@predicates) >>

Create a new LRDD discovery object using the given predicate URIs.
If @predicates is omitted, then the predicates passed to the import
routine are used instead.

=item C<< HTTP::LRDD->new_strict >>

Create a new LRDD discovery object using the 'describedby' and
'lrdd' IANA-registered predicates.

=item C<< HTTP::LRDD->new_default >>

Create a new LRDD discovery object using the default set of
predicates ('describedby', 'lrdd', 'wdrs:describedby', 'xhv:meta'
and 'rdfs:seeAlso').

=back

=head2 Public Methods

=over 4

=item C<< $lrdd->discover($resource_uri) >>

Discovers a descriptor for the given resource; or if called in a list
context, a list of descriptors.

A descriptor is a resource that provides a description for something.
So, if the given resource URI was the web address for an image, then
the descriptor might be the web address for a metadata file about the
image. If the given URI was an e-mail address, then the descriptor
might be a profile document for the person to whom the address belongs.

The following sources are checked (in order) to find links to
descriptors.

=over 4

=item * HTTP response headers ("Link" header; "303 See Other" status)

=item * HTTP response message (RDF or RDFa)

=item * https://HOSTNAME/.well-known/host-meta

=item * http://HOSTNAME/.well-known/host-meta

=back

If none of the above is able to yield a link to a descriptor, then
the resource URI itself may be returned if it is in a self-describing
format (e.g. RDF).

There is no guaranteed file format for the descriptor, but it is
usually RDF, POWDER XML or XRD.

This method can also be called without an object (as a class method)
in which case, a temporary object is created automatically using
C<< new >>.

=item C<< $lrdd->parse($descriptor_uri) >>

Parses a descriptor in XRD or RDF (RDF/XML, RDFa, Turtle, etc).

Returns an RDF::Trine::Model or undef if unable to process.

This method can also be called without an object (as a class method)
in which case, a temporary object is created automatically using
C<< new >>.

=item C<< $lrdd->process($resource_uri) >>

Performs the equivalent of C<discover> and C<parse> in one easy step.

Calls C<discover> in a non-list context, so only the first descriptor
is used.

=item C<< $lrdd->process_all($resource_uri) >>

Performs the equivalent of C<discover> and C<parse> in one easy step.

Calls C<discover> in a list context, so multiple descriptors are
combined into the resulting graph.

=back

=head1 EXAMPLES

Discover the hub address (PubSubHubub) for a feed:

 my $lrdd = HTTP::LRDD->new('hub');
 my $hub  = $lrdd->discover('http://example.net/feed.atom');

Discover an author link (rel="author") from an HTML page:

 my $lrdd   = HTTP::LRDD->new('author');
 my $author = $lrdd->discover('http://example.com/page.html');

(For RDF people, you should note that rel="author" is not semantically
equivalent to the "foaf:maker" property but closer to the 
"foaf:maker/foaf:homepage" SPARQL 1.1 property path - i.e. the rel="author"
link destination is not a URI for the author themselves, but a page about
the author.)

If that author resource is in a machine-readable format (e.g. RDF), then
parse the data:

 my $author_data = $lrdd->parse($author);
 
Or, you can combine C<discover> and C<parse>:

 my $lrdd        = HTTP::LRDD->new('author');
 my $author_data = $lrdd->process('http://example.com/page.html');

Get metadata for an image:

 my $lrdd = HTTP::LRDD->new;
 my $data = $lrdd->process_all('http://example.org/flower.jpeg');

As we're not passing any arguments to the constructor, we can use a shortcut:

 my $data = HTTP::LRDD->process_all('http://example.org/flower.jpeg');
 
Find the title of the image:

 use RDF::QueryX::Lazy;
 
 my $image   = q<http://example.org/flower.jpeg>;
 my $results = RDF::QueryX::Lazy
   -> new("SELECT * WHERE { <$image> dc:title ?t }")
   -> execute( HTTP::LRDD->process_all($image) );

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

B<Note>: many problems can stem from servers that send incorrect
C<Content-Type> headers. If you send an XRD file as "text/html",
then this module will not guess what you're doing - it will assume
the file is really HTML, and inspect it for RDFa. For host-meta
files, this module is slightly more relaxed, as there's a strong
assumption that they are XRD... but YOU SHOULD NOT RELY ON THIS.
If you're running a server, use the correct media type.

=head1 SEE ALSO

L<HTTP::Link::Parser>, L<XRD::Parser>, L<XML::Atom::OWL>
L<WWW::Finger>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2010-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut
