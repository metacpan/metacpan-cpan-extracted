package HTML::HTML5::Microdata::ToRDFa;

use 5.010;
use strict;

use HTML::HTML5::Microdata::Parser 0.100 qw();
use HTML::HTML5::Writer 0 qw();
use RDF::Prefixes 0.002 qw();
use Scalar::Util 0 qw(blessed);
use XML::LibXML 1.70 qw(:all);

BEGIN {
	$HTML::HTML5::Microdata::ToRDFa::AUTHORITY = 'cpan:TOBYINK';
	$HTML::HTML5::Microdata::ToRDFa::VERSION   = '0.100';
}

sub new
{
	my ($class, $html, $base, %options) = @_;
	
	my $self = bless {
		bnodes    => 0,
		dom       => undef,
		parser    => undef,
		prefix    => {},
		}, $class;
		
	my $popts = { strategy => ($options{strategy} // 'HTML::HTML5::Microdata::Strategy::Heuristic') };
	$self->{parser}   = HTML::HTML5::Microdata::Parser->new($html, $base, $popts);
	$self->{prefix}   = RDF::Prefixes->new;
	$self->{dom}      = $self->{parser}->dom;
	$self->{strategy} = do
		{
			my $S = $options{strategy}
				// 'HTML::HTML5::Microdata::Strategy::Heuristic';
			if (ref $S eq 'CODE')
				{ $S; }
			elsif (blessed($S) and $S->can('generate_uri'))
				{ sub { return $S->generate_uri(@_); } }
			elsif (length "$S")
				{ my $K = "$S"; sub { return $K->new->generate_uri(@_); } }
			else
				{ sub { return undef } }
		};
		
	return $self;
}

sub get_string
{
	my ($self, %options) = @_;
	
	my $advertisement = "\n";
	$advertisement = sprintf("\n<!--\n\t%s/%s\n\t%s/%s\n\t%s/%s\n\t%s/%s\n\t%s/%s\n -->\n",
		'HTML::HTML5::Microdata::ToRDFa'  => $HTML::HTML5::Microdata::ToRDFa::VERSION,
		'HTML::HTML5::Microdata::Parser'  => $HTML::HTML5::Microdata::Parser::VERSION,
		'HTML::HTML5::Writer'             => $HTML::HTML5::Writer::VERSION,
		'XML::LibXML'                     => $XML::LibXML::VERSION,
		'RDF::Prefixes'                   => $RDF::Prefixes::VERSION,
		)
		unless $options{no_advert};
	
	my $markup  = $options{markup} // 'xhtml';
	my $doctype = lc $markup eq 'html'
		? HTML::HTML5::Writer::DOCTYPE_HTML5
		: HTML::HTML5::Writer::DOCTYPE_XHTML_RDFA10;
	
	return HTML::HTML5::Writer
		->new(
			markup   => $markup,
			polyglot => 1,
			doctype  => $doctype.$advertisement,
			)
		->document($self->get_dom);
}

sub get_dom
{
	my ($self) = @_;
	my $clone;
	
	# Is there a better way to clone an XML::LibXML::Document?
	{
		my $parser = XML::LibXML->new();
		$clone = $parser->parse_string( $self->{'dom'}->toString );
	}
	
	$self->_process_element($clone->documentElement, undef, $self->{'parser'}->uri);
	
	return $clone;
}

sub _process_element
{
	my ($self, $elem, $subject, $rdfa_subject) = @_;	
	my ($new_subject, $new_rdfa_subject);
	
	if ($elem->hasAttribute('itemscope'))
	{
		if ($elem->hasAttribute('itemid'))
		{
			$new_subject = $elem->getAttribute('itemid');
		}
		else
		{
			$new_subject = $self->_bnode;
		}
	}

	unless (defined $subject || defined $new_subject)
	{
		foreach my $attr (qw(itemprop itemtype itemid itemref))
		{
			$elem->removeAttribute($attr)
				if $elem->hasAttribute($attr);
		}
	}

	# This is complicated and annoying, but it's good to handle @itemref.
	# This technique should work for the vast majority of cases.
	if ($elem->hasAttribute('itemref') and $elem->hasAttribute('itemscope'))
	{
		my @new_nodes;
		$self->{'parser'}->set_callbacks({'ontriple'=>sub {
			my $parser  = shift;
			my $node    = shift;
			my $triple  = shift;
			
			# if $node is an element outside of $elem
			if ((substr $node->nodePath, 0, length $elem->nodePath) ne $elem->nodePath)
			{
				my $new = $elem->addNewChild('http://www.w3.org/1999/xhtml', 'span');
				$new->setAttribute('class', 'microdata-to-rdfa--itemref');
				push @new_nodes, $new;
				
				if ($triple->subject->is_blank)
				{
					$new->setAttribute('about' => '_:'.$triple->subject->blank_identifier);
				}
				else
				{
					$new->setAttribute('about' => $triple->subject->uri);
				}
				if ($triple->object->is_literal)
				{
					$new->setAttribute('property' => $self->_super_split($new, $triple->predicate->uri));
					$new->setAttribute('content'  => $triple->object->literal_value);
					$new->setAttribute('datatype' => $self->_super_split($new, $triple->object->literal_datatype))
						if $triple->object->has_datatype;
					$new->setAttribute('xml:lang' => $triple->object->literal_value_language)
						if $triple->object->has_language;
				}
				else
				{
					$new->setAttribute('rel' => $self->_super_split($new, $triple->predicate->uri));
					if ($triple->object->is_blank)
					{
						$new->setAttribute('resource' => '_:'.$triple->object->blank_identifier);
					}
					else
					{
						$new->setAttribute('resource' => $triple->object->uri);
					}
				}
			}
			
			return 1;
			}});
		my $new_uri = $self->{'parser'}->consume_microdata_item( $self->_get_orig_node($elem) );
		
		# consume_microdata_item would have issued a new blank node identifier
		# for the item. Let's write over that.
		foreach my $node (@new_nodes)
		{
			$node->setAttribute('about' => $subject)
				if $node->getAttribute('about') eq $new_uri;
			$node->setAttribute('resource' => $subject)
				if $node->getAttribute('resource') eq $new_uri;
		}
		
		$elem->removeAttribute('itemref');
	}

	$elem->removeAttribute('itemscope')
		if $elem->hasAttribute('itemscope');

	# This copes with <a href="..."><span itemprop="...">...</span></a>
	# and related. The @href shouldn't set a new subject in Microdata.
	$new_rdfa_subject = $elem->getAttribute('href')
		if $elem->hasAttribute('href')
		&& !$elem->hasAttribute('itemprop');
	$new_rdfa_subject = $elem->getAttribute('src')
		if $elem->hasAttribute('src')
		&& !$elem->hasAttribute('itemprop');

	if (defined $new_subject && !$elem->hasAttribute('itemprop'))
	{
		$elem->setAttribute('about' => $new_subject);
		$elem->removeAttribute('itemid')
			if $elem->hasAttribute('itemid');
		
		if ($elem->hasAttribute('itemtype'))
		{
			my ($expand, $prefix, $suffix) = $self->_split($elem->getAttribute('itemtype'));
			$elem->setAttribute('typeof' => "$prefix:$suffix");
			$elem->setAttribute("xmlns:$prefix" => $expand);
			$elem->removeAttribute('itemtype');
		}
	}

	elsif (defined $new_subject && $elem->hasAttribute('itemprop'))
	{
		$elem->setAttribute('resource' => $new_subject);
		$elem->removeAttribute('itemid')
			if $elem->hasAttribute('itemid');
		
		$elem->setAttribute(
			'rel' => $self->_super_split($elem, $elem->getAttribute('itemprop'))
			);
		$elem->removeAttribute('itemprop');
		
		if ($elem->hasAttribute('itemtype'))
		{
			my $new = $elem->addNewChild('http://www.w3.org/1999/xhtml', 'span');
			$new->setAttribute('class', 'microdata-to-rdfa--itemtype');
			
			my ($expand, $prefix, $suffix) = $self->_split($elem->getAttribute('itemtype'));			
			$new->setAttribute('resource' => "[$prefix:$suffix]");
			$new->setAttribute("xmlns:$prefix" => $expand);

			($expand, $prefix, $suffix) = $self->_split('http://www.w3.org/1999/02/22-rdf-syntax-ns#type');
			$new->setAttribute('resource' => "[$prefix:$suffix]");
			$new->setAttribute("xmlns:$prefix" => $expand);
		}		
	}

	elsif ($elem->hasAttribute('itemprop'))
	{
		if ($elem->localname =~ /^(audio | embed | iframe | img | source | video)$/ix)
		{
			if ($elem->hasAttribute('src'))
			{
				$elem->setAttribute(
					'rel' => $self->_super_split($elem, $elem->getAttribute('itemprop'))
					);
				$elem->removeAttribute('itemprop');
				
				$elem->setAttribute('about' => $subject);
				$elem->setAttribute('resource' => $elem->getAttribute('src'));
			}
			else
			{
				$elem->setAttribute(
					'property' => $self->_super_split($elem, $elem->getAttribute('itemprop'))
					);
				$elem->removeAttribute('itemprop');
				
				$elem->setAttribute('about' => $subject);
				$elem->setAttribute('content' => '');
			}
		}
		elsif ($elem->localname =~ /^(a | area | link)$/ix)
		{
			if ($elem->hasAttribute('href'))
			{
				$elem->setAttribute(
					'rel' => $self->_super_split($elem, $elem->getAttribute('itemprop'))
					);
				$elem->removeAttribute('itemprop');
			}
			else
			{
				$elem->setAttribute(
					'property' => $self->_super_split($elem, $elem->getAttribute('itemprop'))
					);
				$elem->removeAttribute('itemprop');
				
				$elem->setAttribute('content' => '');
			}
		}
		elsif ($elem->localname =~ /^(object)$/ix)
		{
			if ($elem->hasAttribute('data'))
			{
				$elem->setAttribute(
					'rel' => $self->_super_split($elem, $elem->getAttribute('itemprop'))
					);
				$elem->removeAttribute('itemprop');
				$elem->setAttribute('resource' => $elem->getAttribute('data'));
			}
			else
			{
				$elem->setAttribute(
					'property' => $self->_super_split($elem, $elem->getAttribute('itemprop'))
					);
				$elem->removeAttribute('itemprop');
				$elem->setAttribute('content' => '');
			}
		}
		else
		{
			$elem->setAttribute(
				'property' => $self->_super_split($elem, $elem->getAttribute('itemprop'))
				);
			$elem->removeAttribute('itemprop');
			$elem->setAttribute('datatype' => '')
				if $elem->getChildrenByTagName('*');
		}
	}

	if ($subject ne $rdfa_subject
	and ($elem->hasAttribute('rel') || $elem->hasAttribute('property'))
	and !$elem->hasAttribute('about'))
	{
		$elem->setAttribute('about' => $subject);
	}
	
	foreach my $kid ($elem->getChildrenByTagName('*'))
	{
		$self->_process_element($kid, $new_subject||$subject, $new_rdfa_subject||$rdfa_subject);
	}
}

sub _split
{
	my ($self, $uri) = @_;
	
	my $curie = $self->{prefix}->get_curie($uri);
	my ($prefix, $suffix) = split /:/, $curie, 2;
	
	return ($self->{prefix}->to_hashref->{$prefix}, $prefix, $suffix);
}

sub _super_split
{
	my ($self, $elem, $str) = @_;
	
	my $type = $self->_get_node_type( $self->_get_orig_node($elem) );
	
	my @rv;
	my @props = split /\s+/, $str;
	
	foreach my $p (@props)
	{
		my $predicate_uri = $self->{strategy}->(
			name     => $p,
			type     => $type,
			element  => $elem,
			prefix_empty => 'tag:buzzword.org.uk,2011:md2rdfa:',
			);
		
		my ($expand, $prefix, $suffix) = $self->_split($predicate_uri);
		$elem->setAttribute("xmlns:$prefix" => $expand);
		push @rv, "$prefix:$suffix";
	}
	
	return join ' ', @rv;
}

sub _get_orig_node
{
	my ($self, $node) = @_;
	
	my @matches = $self->{'dom'}->documentElement->findnodes( $node->nodePath );
	return $matches[0];
}

sub _get_node_type
{
	my ($self, $node) = @_;
	
	return undef unless $node;
	return undef unless $node->nodeType == XML_ELEMENT_NODE;
	
	return $node->getAttribute('itemtype')
		if $node->hasAttribute('itemtype');
	
	return $self->_get_node_type($node->parentNode)
		if ($node != $self->{'dom'}->documentElement
		and defined $node->parentNode
		and $node->parentNode->nodeType == XML_ELEMENT_NODE);
	
	return undef;
}

sub _bnode
{
	my ($self) = @_;
	return sprintf('_:HTMLAutoNode%03d', $self->{bnodes}++);
}

1;

__DATA__
dcterms	http://purl.org/dc/terms/
eg	http://example.com/
foaf	http://xmlns.com/foaf/0.1/
md	http://www.w3.org/1999/xhtml/microdata#
og	http://ogp.me/ns#
owl	http://www.w3.org/2002/07/owl#
rdf	http://www.w3.org/1999/02/22-rdf-syntax-ns#
rdfs	http://www.w3.org/2000/01/rdf-schema#
rss	http://purl.org/rss/1.0/
schema	http://schema.org/
sioc	http://rdfs.org/sioc/ns#
skos	http://www.w3.org/2004/02/skos/core#
v	http://rdf.data-vocabulary.org/#
xhv	http://www.w3.org/1999/xhtml/vocab#
xsd	http://www.w3.org/2001/XMLSchema#
__END__

=head1 NAME

HTML::HTML5::Microdata::ToRDFa - rewrite HTML5+Microdata into XHTML+RDFa

=head1 SYNOPSIS

 use HTML::HTML5::Microdata::ToRDFa;
 my $rdfa = HTML::HTML5::Microdata::ToRDFa->new($html, $baseuri);
 print $rdfa->get_string;

=head1 DESCRIPTION

This module may be used to convert HTML documents marked up with Microdata
into XHTML+RDFa 1.0 (which is more widely implemented by consuming software).

If the input document uses a mixture of Microdata and RDFa, the semantics of the
output document may be incorrect.

=head2 Constructor

=over

=item C<< $rdfa = HTML::HTML5::Microdata::ToRDFa->new($html, $baseuri) >>

$html may be an HTML document (as a string) or an XML::LibXML::Document
object.

$baseuri is the base URI for resolving relative URI references. If $html is undefined,
then this module will fetch $baseuri to obtain the document to be converted.

=back

=head2 Public Methods

=over

=item C<< $rdfa->get_string >>

Get the document converted to RDFa as a string. This will be well-formed XML, but not
necessarily valid XHTML.

=item C<< $rdfa->get_dom >>

Get the document converted to XHTML+RDFa as an L<XML::LibXML::Document>
object.

Note that each time C<get_string> and C<get_dom> are called, the 
conversion process is run from scratch. Repeatedly calling these 
methods is wasteful.

=back

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::HTML5::Microdata::Parser>, L<RDF::RDFa::Parser>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2010-2011 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

