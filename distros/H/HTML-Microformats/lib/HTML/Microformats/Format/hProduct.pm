=head1 NAME

HTML::Microformats::Format::hProduct - the hProduct microformat

=head1 SYNOPSIS

 use HTML::Microformats::DocumentContext;
 use HTML::Microformats::Format::hProduct;

 my $context = HTML::Microformats::DocumentContext->new($dom, $uri);
 my @objects = HTML::Microformats::Format::hProduct->extract_all(
                   $dom->documentElement, $context);
 foreach my $p (@objects)
 {
   printf("%s\n", $m->get_fn);
   if ($p->get_review)
   {
     foreach my $r ($p->get_review)
     {
       printf("  - reviewed by %s\n", $r->get_reviewer->get_fn);
     }
   }
   else
   {
     print "    (no reviews yet)\n";
   }
 }

=head1 DESCRIPTION

HTML::Microformats::Format::hProduct inherits from HTML::Microformats::Format. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

=cut

package HTML::Microformats::Format::hProduct;

use base qw(HTML::Microformats::Format HTML::Microformats::Mixin::Parser);
use strict qw(subs vars); no warnings;
use 5.010;

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Format::hProduct::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Format::hProduct::VERSION   = '0.105';
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
		'id'         => $context->make_bnode($element) ,
		};
	
	bless $self, $class;
	
	my $clone = $element->cloneNode(1);	
	$self->_expand_patterns($clone);
	$self->_simple_parse($clone);
	
	foreach my $review (@{ $self->{'DATA'}->{'review'} })
	{
		$review->{'DATA'}->{'item'} = $self
			unless $review->{'DATA'}->{'item'};
	}

	foreach my $listing (@{ $self->{'DATA'}->{'listing'} })
	{
		$listing->{'DATA'}->{'item'} = $self
			unless $listing->{'DATA'}->{'item'};
	}

	##TODO: class=identifier (type+value)    post-0.001

	$cache->set($context, $element, $class, $self)
		if defined $cache;

	return $self;
}

sub format_signature
{
	my $gr   = 'http://purl.org/goodrelations/v1#';
	my $hl   = 'http://ontologi.es/hlisting-hproduct#';
	my $rdfs = 'http://www.w3.org/2000/01/rdf-schema#';
	my $foaf = 'http://xmlns.com/foaf/0.1/';
	my $dc   = 'http://purl.org/dc/terms/';

	return {
		'root' => 'hproduct',
		'classes' => [
			['brand',            'M?', {'embedded'=>'hCard'}],
			['category',         '*'],
			['price',            '?',  {'value-title'=>'allow'}],
			['description',      '?'],
			['fn',               '1'],
			['photo',            'u*'],
			['url',              'u?'],
			['review',           'm*', {'embedded'=>'hReview hReviewAggregate'}],
			['listing',          'm*', {'embedded'=>'hListing'}],
		],
		'options' => {
			'rel-tag' => 'category',
		},
		'rdf:type' => ["${gr}ProductOrService"] ,
		'rdf:property' => {
			'brand'           => { literal =>["${hl}brand"] },
			'category'        => { resource=>['http://www.holygoat.co.uk/owl/redwood/0.1/tags/taggedWithTag'] },
			'description'     => { literal =>["${dc}description"] },
			'fn'              => { literal =>["${rdfs}label"] },
			'photo'           => { resource=>["${foaf}depiction"] },
			'url'             => { resource=>["${foaf}page", "${rdfs}seeAlso"] },
			'review'          => { resource=>['http://purl.org/stuff/rev#hasReview'] },
			'listing'         => { rev     =>["${hl}listing"] },
		},
	};
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;

	my $gr   = 'http://purl.org/goodrelations/v1#';
	my $hl   = 'http://ontologi.es/hlisting-hproduct#';
	my $rdfs = 'http://www.w3.org/2000/01/rdf-schema#';
	my $foaf = 'http://xmlns.com/foaf/0.1/';
	my $rdf  = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
	
	$self->_simple_rdf($model);

	if ($self->_isa($self->{'DATA'}->{'brand'}, 'HTML::Microformats::Format::hCard'))
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${hl}brand"),
			$self->{'DATA'}->{'brand'}->id(1, 'holder'),
			));
	}

	if ($self->{'DATA'}->{'price'})
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${hl}price"),
			$self->id(1, 'price'),
			));
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1, 'price'),
			RDF::Trine::Node::Resource->new("${rdf}type"),
			RDF::Trine::Node::Resource->new("${gr}PriceSpecification"),
			));
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1, 'price'),
			RDF::Trine::Node::Resource->new("${rdfs}comment"),
			$self->_make_literal($self->{'DATA'}->{'price'}),
			));

		my ($curr, $val);
		if ($self->{'DATA'}->{'price'} =~ /^\s*([a-z]{3})\s*(\d*(?:[\,\.]\d\d))\s*$/i)
		{
			($curr, $val) = ($1, $2);
		}
		elsif ($self->{'DATA'}->{'price'} =~ /^\s*(\d*(?:[\,\.]\d\d))\s*([a-z]{3})\s*$/i)
		{
			($curr, $val) = ($2, $1);
		}
		
		if (defined $curr && defined $val)
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, 'price'),
				RDF::Trine::Node::Resource->new("${gr}hasCurrency"),
				$self->_make_literal($curr, 'string'),
				));
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, 'price'),
				RDF::Trine::Node::Resource->new("${gr}hasCurrencyValue"),
				$self->_make_literal($val, 'float'),
				));
		}
	}

	return $self;
}

sub profiles
{
	my $class = shift;
	return qw(http://purl.org/uF/hProduct/0.3/);
}

1;

=head1 MICROFORMAT

HTML::Microformats::Format::hProduct supports hProduct 0.3 as described at
L<http://microformats.org/wiki/hProduct>, with the following additions:

=over 4

=item * 'item' propagation.

If 'review' and 'listing' objects don't have an 'item' set, then their
'item' property is set to this object.

=back

=head1 RDF OUTPUT

Product data is primarily output using GoodRelations v1
(L<http://purl.org/goodrelations/v1#>).

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

