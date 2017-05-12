=head1 NAME

HTML::Microformats::Format::hMeasure - the hMeasure microformat

=head1 SYNOPSIS

 use HTML::Microformats::DocumentContext;
 use HTML::Microformats::Format::hMeasure;

 my $context = HTML::Microformats::DocumentContext->new($dom, $uri);
 my @objects = HTML::Microformats::Format::hMeasure->extract_all(
                   $dom->documentElement, $context);
 foreach my $m (@objects)
 {
   printf("%s %s\n", $m->get_number, $m->get_unit);
 }

=head1 DESCRIPTION

HTML::Microformats::Format::hMeasure inherits from HTML::Microformats::Format. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

=cut

package HTML::Microformats::Format::hMeasure;

use base qw(HTML::Microformats::Format HTML::Microformats::Mixin::Parser);
use strict qw(subs vars); no warnings;
use 5.010;

use HTML::Microformats::Utilities qw(searchClass stringify);
use HTML::Microformats::Datatype::String qw(isms);
use HTML::Microformats::Format::hCard;
#use HTML::Microformats::Format::hEvent;
use RDF::Trine;

my $_nonZeroDigit = '[1-9]';
my $_digit        = '\d';
my $_natural      = "($_nonZeroDigit)($_digit)*";
my $_integer      = "(0|(\\-|\x{2212})?($_natural)+)";
my $_decimal      = "($_integer)[\\.\\,]($_digit)*";
my $_mantissa     = "($_decimal|$_integer)";
my $_sciNumber    = "($_mantissa)[Ee]($_integer)";
my $_number       = "($_sciNumber|$_decimal|$_integer|\\x{00BC}|\\x{00BD}|\\x{00BE})";
my $_degree       = "($_number)(deg|\\x{00b0})";
my $_minute       = "($_number)(min|\\x{2032}|\\\')";
my $_second       = "($_number)(sec|\\x{2033}|\\\")";

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Format::hMeasure::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Format::hMeasure::VERSION   = '0.105';
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
		'id.qv'      => $context->make_bnode ,
		};
	
	bless $self, $class;
	
	my $clone = $element->cloneNode(1);	
	$self->_expand_patterns($clone);

	$self->{'DATA'}->{'class'} = 'hmeasure';
	$self->{'DATA'}->{'class'} = 'hangle'
		if $clone->getAttribute('class') =~ /\b(hangle)\b/;
	$self->{'DATA'}->{'class'} = 'hmoney'
		if $clone->getAttribute('class') =~ /\b(hmoney)\b/;
	
	$self->_extract_item($clone, 'vcard',  'HTML::Microformats::Format::hCard');
	$self->_extract_item($clone, 'vevent', 'HTML::Microformats::Format::hEvent');
	$self->_destroyer($clone);
	
	$self->_hmeasure_parse($clone);
	$self->_hmeasure_fallback($clone);
		
	$cache->set($context, $element, $class, $self)
		if defined $cache;

	return $self;
}

sub _extract_item
{
	my ($self, $root, $hclass, $package) = @_;
	
	return 1 if defined $self->{'DATA'}->{'item'};
	
	my @nested = searchClass($hclass, $root);

	foreach my $h (@nested)
	{
		next unless ref $h;
		
		if ($h->getAttribute('class') =~ /\bitem\b/)
		{
			$self->{'DATA'}->{'item'} = $package->new($h, $self->context);
			push @{ $self->{RemoveTheseNodes} }, $h;
			last;
		}
			
		my $newClass = $h->getAttribute('class');
		$newClass =~ s/\bitem\b//gix;
		$h->setAttribute('class', $newClass);
	}
	
	return (defined $self->{'DATA'}->{'item'}) ? 1 : 0;
}

sub _hmeasure_parse
{
	my ($self, $root) = @_;
	
	# Number
	my @nodes = searchClass('num', $root);
	my $str   = stringify($nodes[0], 'value');
	$self->{'DATA'}->{'num'} = $str
		if length $str;
	push @{ $self->{RemoveTheseNodes} }, $nodes[0] if @nodes;
	
	# Unit (except hAngle, as angles don't have units)
	unless ($self->{'DATA'}->{'class'} eq 'hangle')
	{
		@nodes = searchClass('unit', $root);
		$str   = stringify($nodes[0], 'value');
		$self->{'DATA'}->{'unit'} = $str
			if length $str;
		push @{ $self->{RemoveTheseNodes} }, $nodes[0] if @nodes;
	}

	# Type
	@nodes = searchClass('type', $root);
	$str   = stringify($nodes[0], 'value');
	$self->{'DATA'}->{'type'} = $str
		if length $str;
	push @{ $self->{RemoveTheseNodes} }, $nodes[0] if @nodes;

	# Item
	unless (defined $self->{'DATA'}->{'item'})
	{
		@nodes = searchClass('item', $root);
		if (@nodes)
		{
			my $node = $nodes[0];
			my $link;
			my $str  = stringify($node, 'value');
			
			$link = $node->getAttribute('data')
				if $node->hasAttribute('data');
			$link = $node->getAttribute('src')
				if $node->hasAttribute('src');
			$link = $node->getAttribute('href')
				if $node->hasAttribute('href');
			
			$self->{'DATA'}->{'item_link'}  = $link if defined $link;
			$self->{'DATA'}->{'item_label'} = $str  if length $str;
			
			$self->{'id.item'} = $self->context->make_bnode;
			
			push @{ $self->{RemoveTheseNodes} }, $node;
		}
	}
	
	# Tolerance
	@nodes = searchClass('tolerance', $root);
	$str   = stringify($nodes[0], 'value');
	if ($str =~ /^\s*($_number)\s*\%\s*$/)
	{
		# Construct another hMeasure for the tolerance!
		$self->{'DATA'}->{'tolerence'} = bless {
			'DATA' => {
				'class' => 'percentage' ,
				'num'   => $1 ,
				'unit'  => '%',
			},
			'element'    => $self->element ,
			'context'    => $self->context ,
			'cache'      => $self->context->cache ,
			'id'         => $self->context->make_bnode($nodes[0]) ,
			'id.qv'      => $self->context->make_bnode ,
		};
	}
	elsif ($nodes[0])
	{
		my $tolerance = HTML::Microformats::Format::hMeasure->new($nodes[0], $self->context);
		$self->{'DATA'}->{'tolerence'} = $tolerance
			if length $tolerance->data->{'num'};
	}
	push @{ $self->{RemoveTheseNodes} }, $nodes[0] if @nodes;
}

sub _hmeasure_fallback
{
	my ($self, $root) = @_;
	
	# Stringify the remainder of the hmeasure (stuff that wasn't
	# explicitly consumed by _hmeasure_parse).
	foreach my $node (@{ $self->{RemoveTheseNodes} })
		{ $node->parentNode->removeChild($node); }	
	my $str = stringify($root, 'value');
	
	# Extract tolerance based on presence of ± character.
	unless (defined $self->{'DATA'}->{'tolerence'})
	{
		my $tol;
		($str, $tol) = split /\x{2213}/, $str;
		$str =~ s/(^\s+)|(\s+$)//g;
		$tol =~ s/(^\s+)|(\s+$)//g;
		
		if (length $tol)
		{
			$tol =~ /$_number/;
			$self->{'DATA'}->{'tolerence'} = bless {
				'DATA' => {
					'class' => $self->{'DATA'}->{'class'} ,
					'num'   => $1 ,
				},
				'element'    => $self->element ,
				'context'    => $self->context ,
				'cache'      => $self->context->cache ,
				'id'         => $self->context->make_bnode ,
				'id.qv'      => $self->context->make_bnode ,
			};
			$tol =~ s/$_number//;
			$self->{'DATA'}->{'tolerence'}->{'DATA'}->{'unit'} = $tol;
		}
	}

	my $autounit = 0;

	# If this is an angle and we don't have a num, then the
	# remaining string must be the num.
	if ($self->{'DATA'}->{'class'} eq 'hangle'
	&& !defined $self->{'DATA'}->{'num'})
	{
		$self->{'DATA'}->{'num'} = $str;
	}
	
	# Otherwise, if we've got a num, but no unit, remainder
	# must be the unit.
	elsif (defined $self->{'DATA'}->{'num'}
	&& !defined $self->{'DATA'}->{'unit'})
	{
		$self->{'DATA'}->{'unit'} = $str;
		$autounit = 1;
	}
	
	# Otherwise, if we've got a unit but no number, find the number
	# using a regexp.
	elsif (defined $self->{'DATA'}->{'unit'}
	&& !defined $self->{'DATA'}->{'num'})
	{
		$str =~ s/\s+//g;
		$str =~ /$_number/;
		$self->{'DATA'}->{'num'} = $str;
	}
	
	# If neither the unit nor number have been found yet, then the
	# remaining string must contain both!
	elsif (!defined $self->{'DATA'}->{'num'}
	&& !defined $self->{'DATA'}->{'unit'})
	{
		$str =~ /$_number/;
		$self->{'DATA'}->{'num'} = $1;
		$str =~ s/\s*($_number)\s*//;
		$self->{'DATA'}->{'unit'} = $str;
		$autounit = 1;
	}

	# For hmoney, the unit is predictable - it's a currency
	# code or symbol, so make an effort to find it properly
	# using regexps.
	if ($self->{'DATA'}->{'class'} eq 'hmoney' and $autounit)
	{
		$self->{'DATA'}->{'unit'} =~ /(\b[A-Z]{3}\b|\x{20AC}|\x{00A3}|\x{00A5}|\x{0024})/i;
		$self->{'DATA'}->{'unit'} = uc $1 if length $1;
	}

	# Expand abbreviated currency units.
	if ($self->{'DATA'}->{'class'} eq 'hmoney')
	{
		$self->{'DATA'}->{'unit'} = 'EUR' if $self->{'DATA'}->{'unit'} =~ /^\x{20AC}$/;
		$self->{'DATA'}->{'unit'} = 'GBP' if $self->{'DATA'}->{'unit'} =~ /^\x{00A3}$/;
		$self->{'DATA'}->{'unit'} = 'JPY' if $self->{'DATA'}->{'unit'} =~ /^\x{00A5}$/;
		$self->{'DATA'}->{'unit'} = 'USD' if $self->{'DATA'}->{'unit'} =~ /^\x{0024}$/;
	}

	# Clean up punctuation in number.
	$self->{'DATA'}->{'num'} =~ s/\,/\./g;
	$self->{'DATA'}->{'num'} =~ s/\x{2212}/\-/g;
	
	# Angles might be given as degrees,minutes,seconds.
	if ($self->{'DATA'}->{'class'} eq 'hangle')
	{
		$str = $self->{'DATA'}->{'num'};
		
		$str =~ m/$_degree/;  $self->{'DATA'}->{'num_degree'} = $1 if length $1;
		$str =~ m/$_minute/;  $self->{'DATA'}->{'num_minute'} = $1 if length $1;
		$str =~ m/$_second/;  $self->{'DATA'}->{'num_second'} = $1 if length $1;

		if ($self->{'DATA'}->{'num_degree'} < 0)
		{
			$self->{'DATA'}->{'num_minute'} *= -1;
			$self->{'DATA'}->{'num_second'} *= -1;
		}
		elsif ($self->{'DATA'}->{'num_degree'} == 0 && $self->{'DATA'}->{'num_minute'} < 0)
		{
			$self->{'DATA'}->{'num_second'} *= -1;
		}
		
		$self->{'DATA'}->{'num'} = $self->{'DATA'}->{'num_degree'}
			+ ( $self->{'DATA'}->{'num_minute'} / 60 )
			+ ( $self->{'DATA'}->{'num_second'} / 3600 );

		$self->{'DATA'}->{'num_label'} = $str;
	}

	# If no unit given for tolerance, copy from base measurement.
	if ($self->{'DATA'}->{'class'} ne 'hangle'
	&& defined $self->{'DATA'}->{'tolerance'}
	&& !defined $self->{'DATA'}->{'tolerance'}->{'DATA'}->{'unit'})
	{
		$self->{'DATA'}->{'tolerance'}->{'DATA'}->{'unit'} =
			$self->{'DATA'}->{'unit'};
	}

}

sub profiles
{
	return qw(http://purl.org/uF/hMeasure/0.1/);
}

sub add_to_model
{
	my ($self, $model) = @_;

	my $mx = 'http://buzzword.org.uk/rdf/measure-aux#';

	$self->_simple_rdf($model);
	
	$model->add_statement(RDF::Trine::Statement->new(
		$self->id(1),
		RDF::Trine::Node::Resource->new("${mx}hasValue"),
		$self->id(1, 'qv'),
		));

	$model->add_statement(RDF::Trine::Statement->new(
		$self->id(1, 'qv'),
		RDF::Trine::Node::Resource->new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"),
		RDF::Trine::Node::Resource->new("${mx}QualifiedValue"),
		));

	$model->add_statement(RDF::Trine::Statement->new(
		$self->id(1, 'qv'),
		RDF::Trine::Node::Resource->new("http://www.w3.org/1999/02/22-rdf-syntax-ns#value"),
		RDF::Trine::Node::Literal->new($self->data->{'num'}),
		))
		if $self->data->{'num'};

	$model->add_statement(RDF::Trine::Statement->new(
		$self->id(1, 'qv'),
		RDF::Trine::Node::Resource->new("${mx}unit"),
		RDF::Trine::Node::Literal->new($self->data->{'unit'}),
		))
		if $self->data->{'unit'};

	my $dimension = $self->_dimension_uri;
	$model->add_statement(RDF::Trine::Statement->new(
		$self->id(1),
		RDF::Trine::Node::Resource->new("${mx}dimension"),
		RDF::Trine::Node::Resource->new($dimension),
		))
		if defined $dimension;

	my $item = $self->data->{'item'};
	if (ref $item and $item->isa('HTML::Microformats::Format::hCard'))
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${mx}item"),
			$item->id(1, 'holder'),
			));

		$model->add_statement(RDF::Trine::Statement->new(
			$item->id(1, 'holder'),
			RDF::Trine::Node::Resource->new($dimension),
			$self->id(1, 'qv'),
			))
			if defined $dimension;
	}
	elsif (defined $self->{'id.item'})
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${mx}item"),
			$self->id(1, 'item'),
			));

		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1, 'item'),
			RDF::Trine::Node::Resource->new($dimension),
			$self->id(1, 'qv'),
			))
			if defined $dimension;

		if (isms($self->data->{'item_label'}))
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, 'item'),
				RDF::Trine::Node::Resource->new("http://www.w3.org/2000/01/rdf-schema#label"),
				RDF::Trine::Node::Literal->new($self->data->{'item_label'}->to_string, $self->data->{'item_label'}->lang),
				));
		}
		elsif (defined $self->data->{'item_label'})
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, 'item'),
				RDF::Trine::Node::Resource->new("http://www.w3.org/2000/01/rdf-schema#label"),
				RDF::Trine::Node::Literal->new($self->data->{'item_label'}),
				));
		}
		
		if (defined $self->data->{'item_link'})
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, 'item'),
				RDF::Trine::Node::Resource->new("http://xmlns.com/foaf/0.1/page"),
				RDF::Trine::Node::Resource->new($self->data->{'item_link'}),
				));
		}
	}
	
	# TODO: handle tolerances. post-0.001

	return $model;
}

sub _dimension_uri
{
	my $self = shift;

	return 'http://purl.org/commerce#costs'
		if $self->data->{'class'} eq 'hmoney'
		&& !defined $self->data->{type};

	return unless defined $self->data->{type};

	my $dimension = lc $self->data->{'type'};
	$dimension =~ s/\s+/ /g;
	$dimension =~ s/[^a-z0-9 ]//g;
	$dimension =~ s/ ([a-z])/uc($1)/ge;

	return 'http://buzzword.org.uk/rdf/measure#'.$dimension;
}

sub format_signature
{
	return {
		'root'         => [qw(hmeasure hmoney hangle)] ,
		'classes'      => [
			['num',       '1'],
			['unit',      '?'],
			['item',      '?'],
			['type',      '?'],
			['tolerance', '?'],
			] ,
		'options'      => {} ,
		'rdf:type'     => ['http://buzzword.org.uk/rdf/measure-aux#Measurement'] ,
		'rdf:property' => {} ,
		};
}

1;

=head1 MICROFORMAT

HTML::Microformats::Format::hMeasure supports hMeasure as described at
L<http://microformats.org/wiki/hmeasure>.

=head1 RDF OUTPUT

This module outputs RDF using the Extensible Measurement Ontology
(L<http://buzzword.org.uk/rdf/measure#>).

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

