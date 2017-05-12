=head1 NAME

HTML::Microformats::Format::figure - the figure microformat

=head1 SYNOPSIS

 use HTML::Microformats::DocumentContext;
 use HTML::Microformats::Format::figure;
 use Scalar::Util qw(blessed);

 my $context = HTML::Microformats::DocumentContext->new($dom, $uri);
 my @objects = HTML::Microformats::Format::figure->extract_all(
                   $dom->documentElement, $context);
 foreach my $fig (@objects)
 {
   printf("<%s> %s\n", $fig->get_image, $fig->get_legend->[0]);
   foreach my $maker ($p->get_credit)
   {
     if (blessed($maker))
     {
       printf("  - by %s\n", $maker->get_fn);
     }
     else
     {
       printf("  - by %s\n", $maker);
     }
   }
 }

=head1 DESCRIPTION

HTML::Microformats::Format::figure inherits from HTML::Microformats::Format. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

=cut

package HTML::Microformats::Format::figure;

use base qw(HTML::Microformats::Format HTML::Microformats::Mixin::Parser);
use strict qw(subs vars); no warnings;
use 5.010;

use HTML::Microformats::Utilities qw(searchClass searchID stringify);
use HTML::Microformats::Datatype::String qw(ms);
use Locale::Country qw(country2code LOCALE_CODE_ALPHA_2);

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Format::figure::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Format::figure::VERSION   = '0.105';
}

sub new
{
	my ($class, $element, $context) = @_;
	my $cache = $context->cache;
	
	return $cache->get($context, $element, $class)
		if defined $cache && $cache->get($context, $element, $class);
	
	my $self = {
		'element'    => $element ,
		'context'    => $context ,
		'cache'      => $cache ,
		};
	
	bless $self, $class;
	
	my $clone = $element->cloneNode(1);	
	$self->_expand_patterns($clone);
	$self->_figure_parse($clone);
	
	if (defined $self->{'DATA'}->{'image'})
	{
		$self->{'id'} = $self->{'DATA'}->{'image'};
	}
	else
	{
		return undef;
	}

	$cache->set($context, $element, $class, $self)
		if defined $cache;

	return $self;
}

sub _figure_parse
{
	my ($self, $elem) = @_;
	
	my ($desc_node, $image_node);
	
	if ($elem->localname eq 'img' && $elem->getAttribute('class')=~/\b(image)\b/)
	{
		$image_node = $elem;
	}
	else
	{
		my @images = searchClass('image', $elem);
		@images = $elem->getElementsByTagName('img') unless @images;
		$image_node = $images[0] if @images;
	}
	
	if ($elem->localname eq 'img')
	{
		$image_node ||= $elem;
	}
	
	if ($image_node)
	{
		$self->{'DATA'}->{'image'} = $self->context->uri($image_node->getAttribute('src'));
		$self->{'DATA'}->{'alt'}   = ms($image_node->getAttribute('alt'), $image_node)
			if $image_node->hasAttribute('alt');
		$self->{'DATA'}->{'title'} = ms($image_node->getAttribute('title'), $image_node)
			if $image_node->hasAttribute('title');
		
		if ($image_node->getAttribute('longdesc') =~ m'^#(.+)$')
		{
			$desc_node = searchID($1, $self->context->dom->documentElement);
			
			my $dnp = $desc_node->getAttribute('data-cpan-html-microformats-nodepath');
			my $rnp = $elem->getAttribute('data-cpan-html-microformats-nodepath');
			unless ($rnp eq substr $dnp, 0, length $rnp)
			{
				$elem->addChild($desc_node->clone(1));
			}
		}
	}
	
	# Just does class=credit, class=subject and rel=tag.
	$self->_simple_parse($elem);
	
	my @legends;
	push @legends, $elem if $elem->getAttribute('class')=~/\b(legend)\b/;
	push @legends, searchClass('legend', $elem);
	foreach my $l ($elem->getElementsByTagName('legend'))
	{
		push @legends, $l
			unless $l->getAttribute('class')=~/\b(legend)\b/; # avoid duplicates
	}
	
	foreach my $legend_node (@legends)
	{
		my $legend;
		if ($legend_node == $image_node)
		{
			$legend = ms($legend_node->getAttribute('title'), $legend_node)
				if $legend_node->hasAttribute('title');
		}
		else
		{
			$legend = stringify($legend_node, 'value');
		}
		
		push @{ $self->{'DATA'}->{'legend'} }, $legend if defined $legend;
	}
}

sub extract_all
{
	my ($class, $dom, $context, %options) = @_;
	my @rv;

	my @elements = searchClass('figure', $dom);
	foreach my $f ($dom->getElementsByTagName('figure'))
	{
		push @elements, $f
			unless $f->getAttribute('class')=~/\b(figure)\b/;
	}
	
	foreach my $e (@elements)
	{
		my $object = $class->new($e, $context, %options);
		next unless $object;
		next if grep { $_->id eq $object->id } @rv; # avoid duplicates
		push @rv, $object if ref $object;
	}
		
	return @rv;
}

sub format_signature
{
	my $vcard = 'http://www.w3.org/2006/vcard/ns#';
	my $geo   = 'http://www.w3.org/2003/01/geo/wgs84_pos#';
	my $foaf  = 'http://xmlns.com/foaf/0.1/';

	return {
		'root' => 'figure',
		'classes' => [
			['image',            '1u#'],
			['legend',           '+#'],
			['credit',           'M*', {embedded=>'hCard'}],
			['subject',          'M*', {embedded=>'hCard adr geo hEvent'}],
		],
		'options' => {
			'rel-tag' => 'category',
		},
		'rdf:type' => ["${foaf}Image"] ,
		'rdf:property' => {
			'legend'   => { literal  => ['http://purl.org/dc/terms/description'] },
			'category' => { resource => ['http://www.holygoat.co.uk/owl/redwood/0.1/tags/taggedWithTag'] },
		},
	};
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;

	$self->_simple_rdf($model);
	
	my $i = 0;
	foreach my $subject (@{ $self->{'DATA'}->{'subject'} })
	{
		if ($self->_isa($subject, 'HTML::Microformats::Format::hCard'))
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1),
				RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/depicts'),
				$subject->id(1, 'holder'),
				));
		}

		elsif ($self->_isa($subject, 'HTML::Microformats::Format::adr'))
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1),
				RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/depicts'),
				$subject->id(1, 'place'),
				));
		}

		elsif ($self->_isa($subject, 'HTML::Microformats::Format::geo'))
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1),
				RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/depicts'),
				$subject->id(1, 'location'),
				));
		}

		elsif ($self->_isa($subject, 'HTML::Microformats::Format::hEvent'))
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1),
				RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/depicts'),
				$subject->id(1, 'event'),
				));
		}
		else
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1),
				RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/depicts'),
				$self->id(1, "subject.${i}"),
				));
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, "subject.${i}"),
				RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/name'),
				$self->_make_literal($subject)));
		}
		$i++;
	}

	$i = 0;
	foreach my $credit (@{ $self->{'DATA'}->{'credit'} })
	{
		if ($self->_isa($credit, 'HTML::Microformats::Format::hCard'))
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1),
				RDF::Trine::Node::Resource->new('http://purl.org/dc/terms/contributor'),
				$credit->id(1, 'holder'),
				));
		}
		else
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1),
				RDF::Trine::Node::Resource->new('http://purl.org/dc/terms/contributor'),
				$self->id(1, "credit.${i}"),
				));
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, "credit.${i}"),
				RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/name'),
				$self->_make_literal($credit)));
		}
		$i++;
	}

	return $self;
}

sub profiles
{
	my $class = shift;
	return qw(http://purl.org/uF/figure/draft);
}

1;

=head1 MICROFORMAT

HTML::Microformats::Format::figure supports figure as described at
L<http://microformats.org/wiki/figure>.

=head1 RDF OUTPUT

Data is returned using Dublin Core and FOAF.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

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

