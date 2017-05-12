=head1 NAME

HTML::Microformats::Format::hListing - the hListing microformat

=head1 SYNOPSIS

 use HTML::Microformats::DocumentContext;
 use HTML::Microformats::Format::hListing;

 my $context = HTML::Microformats::DocumentContext->new($dom, $uri);
 my @objects = HTML::Microformats::Format::hListing->extract_all(
                   $dom->documentElement, $context);
 foreach my $x (@objects)
 {
   printf("%s <%s>\n", $x->get_summary, $x->get_permalink);
 }

=head1 DESCRIPTION

HTML::Microformats::Format::hListing inherits from HTML::Microformats::Format. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

=cut

package HTML::Microformats::Format::hListing;

use base qw(HTML::Microformats::Format::hReview);
use strict qw(subs vars); no warnings;
use 5.010;

use HTML::Microformats::Utilities qw(searchClass);

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Format::hListing::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Format::hListing::VERSION   = '0.105';
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

	$self->_fallback_item($clone)->_auto_detect_type;
	
	if ($element->getAttribute('class') =~ /\b(offer)\b/)
	{
		$self->{'DATA'}->{'action'} = 'offer';
	}
	elsif ($element->getAttribute('class') =~ /\b(wanted)\b/)
	{
		$self->{'DATA'}->{'action'} = 'wanted';
	}
	elsif (searchClass('offer', $element))
	{
		$self->{'DATA'}->{'action'} = 'offer';
	}
	elsif (searchClass('wanted', $element))
	{
		$self->{'DATA'}->{'action'} = 'wanted';
	}

	$cache->set($context, $element, $class, $self)
		if defined $cache;

	return $self;
}

sub format_signature
{
	my $gr   = 'http://purl.org/goodrelations/v1#';
	my $hl   = 'http://ontologi.es/hlisting-hproduct#';
	my $rdfs = 'http://www.w3.org/2000/01/rdf-schema#';
	
	return {
		'root' => 'hlisting',
		'classes' => [
			['version',        'n?'],
			['lister',         'm1',  {embedded=>'hCard !person'}],
			['dtlisted',       'd?'],
			['dtexpired',      'd?',  {'datetime-feedthrough'=>'dtlisted'}],
			['price',          '?',   {'value-title'=>'allow'}],
			['summary',        '?'],
			['description',    'h1'],
			['bookmark',       'ru?', {'use-key'=>'permalink'}],
			['type',           '?',   {'value-title'=>'allow'}],
			['action',         '#?'],
			['item',           'm1',  {'embedded'=>'hProduct hAudio hEvent hCard'}], # lowercase 'm' = don't try plain string.
		],
		'options' => {
			'rel-tag' => 'category',
		},
		'rdf:type' => ["${gr}Offering"] ,
		'rdf:property' => {
			'lister'          => { resource=>["${hl}contact"] } ,
			'type'            => { literal =>["${hl}type"] } ,
			'action'          => { literal =>["${hl}action"] } ,
			'dtlisted'        => { literal =>["${hl}dtlisted"] } ,
			'dtexpired'       => { literal =>["${hl}dtexpired"] } ,
			'summary'         => { literal =>["${rdfs}label", "${hl}summary"] },
			'description'     => { literal =>["${hl}description"] },
			'permalink'       => { resource=>["${rdfs}seeAlso"] },
			'category'        => { resource=>['http://www.holygoat.co.uk/owl/redwood/0.1/tags/taggedWithTag'] },
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
	my $rdf  = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';

	$self->_simple_rdf($model);

	if ($self->{'DATA'}->{'price'})
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${gr}hasPriceSpecification"),
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
	
	if ($self->_isa($self->{'DATA'}->{'item'}, 'HTML::Microformats::Format::hCard'))
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${hl}item"),
			$self->{'DATA'}->{'item'}->id(1, 'holder'),
			));
	}
	elsif ($self->_isa($self->{'DATA'}->{'item'}, 'HTML::Microformats::Format::hEvent'))
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${hl}item"),
			$self->{'DATA'}->{'item'}->id(1, 'event'),
			));
	}
	elsif ($self->_isa($self->{'DATA'}->{'item'}, 'HTML::Microformats::Format::hAudio'))
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${hl}item"),
			$self->{'DATA'}->{'item'}->id(1),
			));
	}
	else
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${hl}item"),
			$self->id(1, 'item'),
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

	if ($self->{'DATA'}->{'action'} =~ /^\s*(wanted|offer)\s*$/i
	&&  defined $self->{'DATA'}->{'lister'})
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->{'DATA'}->{'lister'}->id(1, 'holder'),
			RDF::Trine::Node::Resource->new(lc $1 eq 'wanted' ? "${gr}seeks" : "${gr}offers"),
			$self->id(1),
			));
	}
	
	return $self;
}

sub profiles
{
	my $class = shift;
	return qw(http://purl.org/uF/hListing/0.0/);
}

1;

=head1 MICROFORMAT

HTML::Microformats::Format::hListing supports hListing 0.0 as described at
L<http://microformats.org/wiki/hListing>, with the following additions:

=over 4

=item * Supports partial datetimes for 'dtexpired'.

If, say, only a time is provided, the date and timezone are filled
in from 'dtlisted'. This is similar to the behaviour of 'dtstart' and
'dtend' in hCalendar.

=back

=head1 RDF OUTPUT

Listing data is primarily output using GoodRelations v1
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

