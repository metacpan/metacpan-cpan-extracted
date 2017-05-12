=head1 NAME

HTML::Microformats::Format::hReview - the hReview and xFolk microformats

=head1 SYNOPSIS

 use HTML::Microformats::DocumentContext;
 use HTML::Microformats::Format::hReview;

 my $context = HTML::Microformats::DocumentContext->new($dom, $uri);
 my @reviews = HTML::Microformats::Format::hReview->extract_all(
                   $dom->documentElement, $context);
 foreach my $review (@reviews)
 {
   print $review->get_reviewer->get_fn . "\n";
 }

=head1 DESCRIPTION

HTML::Microformats::Format::hReview inherits from HTML::Microformats::Format. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

=cut

package HTML::Microformats::Format::hReview;

use base qw(HTML::Microformats::Format HTML::Microformats::Mixin::Parser);
use strict qw(subs vars); no warnings;
use 5.010;

use HTML::Microformats::Utilities qw(stringify searchClass);
use HTML::Microformats::Format::hReview::rating;

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Format::hReview::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Format::hReview::VERSION   = '0.105';
}

sub new
{
	my ($class, $element, $context, %options) = @_;
	my $cache = $context->cache;
	
	return $cache->get($context, $element, $class)
		if defined $cache && $cache->get($context, $element, $class);
	
	my $self = {
		'element'    => $element ,
		'context'    => $context ,
		'cache'      => $cache ,
		'id'         => $context->make_bnode($element) ,
		'id.holder'  => $context->make_bnode ,
		};
	
	bless $self, $class;
	
	my $clone = $element->cloneNode(1);	
	$self->_expand_patterns($clone);
	
	$self->_xfolk_stuff($clone);
	
	$self->_simple_parse($clone);
	
	$self->{'DATA'}->{'version'} ||= '0.3'
		if $element->getAttribute('class') =~ /\b(hreview)\b/;
		
	##TODO post-0.001
	# If no "reviewer" is found inside the hReview, parsers should look 
	# outside the hReview, in the context of the page, for the "reviewer". 
	# If there is no "reviewer" outside either, then parsers should use the
	# author defined by the containing document language, e.g. for HTML
	# documents, the <address> contact info for the page (which is ideally
	# marked up as an hCard as well)

	$self->_fallback_item($clone)->_auto_detect_type;

	$self->{'DATA'}->{'rating'} =
		[ HTML::Microformats::Format::hReview::rating->extract_all($clone, $context) ];

	$cache->set($context, $element, $class, $self)
		if defined $cache;
	
	return $self;
}

sub _xfolk_stuff
{
	my ($self, $element) = @_;
	
	# Handle xFolk.
	if ($element->getAttribute('class') =~ /\b(xfolkentry)\b/)
	{
		my @tl = searchClass('taggedlink', $element);
		return unless @tl;
		
		my ($item_url, $item_img);

		if ($tl[0]->localname eq 'a' || $tl[0]->localname eq 'area')
			{ $item_url = $self->context->uri($tl[0]->getAttribute('href')); }
		elsif ($tl[0]->localname eq 'img')
			{ $item_img = $self->context->uri($tl[0]->getAttribute('src')); }
		elsif ($tl[0]->localname eq 'object')
			{ $item_url = $self->context->uri($tl[0]->getAttribute('data')); }

		$self->{'DATA'}->{'item'}->{'fn'}    = stringify($tl[0], 'value');
		$self->{'DATA'}->{'item'}->{'url'}   = [$item_url];
		$self->{'DATA'}->{'item'}->{'photo'} = [$item_img];
		$self->{'DATA'}->{'type'} = 'url';
	}

	return $self;
}

sub _fallback_item
{
	my ($self, $element) = @_;
	
	my @items = searchClass('item', $element);
	return $self unless @items;
	my $item = $items[0];
	
	my @fns  = searchClass('fn', $item);
	unless (@fns)
	{
		my ($item_url, $item_img);

		if ($item->localname eq 'a' || $item->localname eq 'area')
			{ $item_url = $self->context->uri($item->getAttribute('href')); }
		elsif ($item->localname eq 'img')
			{ $item_img = $self->context->uri($item->getAttribute('src')); }
		elsif ($item->localname eq 'object')
			{ $item_url = $self->context->uri($item->getAttribute('data')); }

		$self->{'DATA'}->{'item'}->{'fn'}    = stringify($item, 'value');
		$self->{'DATA'}->{'item'}->{'url'}   = [$item_url];
		$self->{'DATA'}->{'item'}->{'photo'} = [$item_img];
		
		return $self;
	}
	
	$self->{'DATA'}->{'item'}->{'fn'} = stringify($fns[0], 'value');
	
	foreach my $property (qw(url photo))
	{
		my @urls = searchClass($property, $item);
		foreach my $url (@urls)
		{
			if ($item->localname eq 'a' || $item->localname eq 'area')
			{
				push @{$self->{'DATA'}->{'item'}->{$property}},
					$self->context->uri($item->getAttribute('href'));
			}
			elsif ($item->localname eq 'img')
			{
				push @{$self->{'DATA'}->{'item'}->{$property}},
					$self->context->uri($item->getAttribute('src'));
			}
			elsif ($item->localname eq 'object')
			{
				push @{$self->{'DATA'}->{'item'}->{$property}},
					$self->context->uri($item->getAttribute('data'));
			}
		}
	}
	
	return $self;
}

sub _auto_detect_type
{
	my $self = shift;
	
	if ($self->_isa($self->{'DATA'}->{'item'}, 'HTML::Microformats::Format::hCard')
	&&  !defined $self->{'DATA'}->{'type'})
	{
		my $item_type = $self->{'DATA'}->{'item'}->get_kind . '';
		
		if (lc $item_type eq 'individual')
		{
			$self->{'DATA'}->{'type'} = 'person';
		}
		elsif ($item_type =~ m'^(group|org)$'i)
		{
			$self->{'DATA'}->{'type'} = 'business';
		}
		elsif (lc $item_type eq 'location')
		{
			$self->{'DATA'}->{'type'} = 'place';
		}
		else
		{
			$self->{'DATA'}->{'type'} = $item_type;
		}
	}
	elsif ($self->_isa($self->{'DATA'}->{'item'}, 'HTML::Microformats::Format::hAudio')
	&&     !defined $self->{'DATA'}->{'type'})
	{
		$self->{'DATA'}->{'type'} = 'product';
	}
	elsif ($self->_isa($self->{'DATA'}->{'item'}, 'HTML::Microformats::Format::hEvent')
	&&     !defined $self->{'DATA'}->{'type'})
	{
		$self->{'DATA'}->{'type'} = 'event';
	}

	return $self;
}

sub format_signature
{
	my $self  = shift;
	
	my $rev     = 'http://www.purl.org/stuff/rev#';
	my $hreview = 'http://ontologi.es/hreview#';

	my $rv = {
		'root'    => [qw(hreview xfolkentry)],
		'classes' => [
			['reviewer',    'M*',   {'embedded'=>'hCard !person'}],
			# Note: for item we try hAudio first, as it will likely contain an hCard,
			# Then hEvent, as it may contain an hCard. Lastly try hCard, as it's unlikely
			# to contain anything else.
			['item',        'm1',   {'embedded'=>'hProduct hAudio hEvent hCard'}], # lowercase 'm' = don't try plain string.
			['version',     'n?'],
			['summary',     '1'],
			['type',        '?'],
			['bookmark',    'ru?',  {'use-key'=>'permalink'}],
			['description', 'H*'],
			['dtreviewed',  'd?'],
			['rating',      '*#'],
		],
		'options' => {
			'rel-tag'     => 'tag',
			'rel-license' => 'license',
		},
		'rdf:type' => ["${rev}Review"] ,
		'rdf:property' => {
			'description'   => { 'literal'  => ["${rev}text"] },
			'type'          => { 'literal'  => ["${rev}type"] },
			'summary'       => { 'literal'  => ["${rev}title", "http://www.w3.org/2000/01/rdf-schema#label"] },
			'rating'        => { 'resource' => ["${hreview}rating"] },
			'version'       => { 'literal'  => ["${hreview}version"], 'literal_datatype'=>'decimal' },
			'tag'           => { 'resource' => ['http://www.holygoat.co.uk/owl/redwood/0.1/tags/taggedWithTag'] },
			'license'       => { 'resource' => ["http://www.iana.org/assignments/relation/license", "http://creativecommons.org/ns#license"] },
			'permalink'     => { 'resource' => ["http://www.iana.org/assignments/relation/self"] },
			'dtreviewed'    => { 'literal'  => ["http://purl.org/dc/terms/created"] },
		},
	};
		
	return $rv;
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;

	my $rev = 'http://www.purl.org/stuff/rev#';
	
	$self->_simple_rdf($model);
	
	foreach my $reviewer (@{$self->{'DATA'}->{'reviewer'}})
	{
		if ($self->_isa($reviewer, 'HTML::Microformats::Format::hCard'))
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1),
				RDF::Trine::Node::Resource->new("${rev}reviewer"),
				$reviewer->id(1, 'holder'),
				));
		}
	}
	
	if ($self->_isa($self->{'DATA'}->{'item'}, 'HTML::Microformats::Format::hCard'))
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->{'DATA'}->{'item'}->id(1, 'holder'),
			RDF::Trine::Node::Resource->new("${rev}hasReview"),
			$self->id(1),
			));
	}
	elsif ($self->_isa($self->{'DATA'}->{'item'}, 'HTML::Microformats::Format::hEvent'))
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->{'DATA'}->{'item'}->id(1, 'event'),
			RDF::Trine::Node::Resource->new("${rev}hasReview"),
			$self->id(1),
			));
	}
	elsif ($self->_isa($self->{'DATA'}->{'item'}, 'HTML::Microformats::Format::hAudio'))
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->{'DATA'}->{'item'}->id(1),
			RDF::Trine::Node::Resource->new("${rev}hasReview"),
			$self->id(1),
			));
	}
	else
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1, 'item'),
			RDF::Trine::Node::Resource->new("${rev}hasReview"),
			$self->id(1),
			));
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1, 'item'),
			RDF::Trine::Node::Resource->new("http://www.w3.org/2000/01/rdf-schema#label"),
			$self->_make_literal($self->{'DATA'}->{'item'}->{'fn'}),
			))
			if defined $self->{'DATA'}->{'item'}->{'fn'};
		foreach my $url (@{$self->{'DATA'}->{'item'}->{'url'}})
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, 'item'),
				RDF::Trine::Node::Resource->new("http://xmlns.com/foaf/0.1/page"),
				RDF::Trine::Node::Resource->new($url),
				));
		}
		foreach my $photo (@{$self->{'DATA'}->{'item'}->{'photo'}})
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, 'item'),
				RDF::Trine::Node::Resource->new("http://xmlns.com/foaf/0.1/depiction"),
				RDF::Trine::Node::Resource->new($photo),
				));
		}
	}
	
	foreach my $rating (@{$self->{'DATA'}->{'rating'}})
	{
		if ($rating->get_best==5.0 && $rating->get_worst==0.0)
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1),
				RDF::Trine::Node::Resource->new("${rev}rating"),
				$self->_make_literal($rating->get_value, 'decimal'),
				));
		}
	}
	
	return $self;
}

sub profiles
{
	my $class = shift;
	return qw(http://microformats.org/profile/hreview
		http://ufs.cc/x/hreview
		http://microformats.org/profile/xfolk
		http://ufs.cc/x/xfolk
		http://www.purl.org/stuff/rev#
		http://microformats.org/wiki/xfolk-profile);
}

1;

=head1 MICROFORMAT

HTML::Microformats::Format::hReview supports hReview 0.3 and xFolk as described at
L<http://microformats.org/wiki/hreview> and L<http://microformats.org/wiki/xfolk>,
with the following differences:

=over 4

=item * hAudio

hAudio microformats can be used as the reviewed item.

(At the time of writing this documentation however, HTML::Microformats didn't
support hAudio!)

=item * Jumbled-up

Support for xFolk and hReview are bundled together, so properties are usually
supported in both, even if only defined by one microformat spec. (e.g. reviewer
is defined by hReview, but this module supports it in xFolk entries.)

=back

=head1 RDF OUTPUT

L<http://www.purl.org/stuff/rev#>, L<http://ontologi.es/hreview#>.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

Known limitations:

=over 4

=item * If no "reviewer" is found inside the hReview, parsers should look 
outside the hReview, in the context of the page, for the "reviewer". 
If there is no "reviewer" outside either, then parsers should use the
author defined by the containing document language, e.g. for HTML
documents, the <address> contact info for the page (which is ideally
marked up as an hCard as well).

=back

=head1 SEE ALSO

L<HTML::Microformats::Format>,
L<HTML::Microformats>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2008-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


=cut

