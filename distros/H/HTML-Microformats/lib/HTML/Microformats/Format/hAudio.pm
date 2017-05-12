=head1 NAME

HTML::Microformats::Format::hAudio - the hAudio microformat

=head1 SYNOPSIS

 use Data::Dumper;
 use HTML::Microformats::DocumentContext;
 use HTML::Microformats::Format::hAudio;

 my $context = HTML::Microformats::DocumentContext->new($dom, $uri);
 my @haudios = HTML::Microformats::Format::hAudio->extract_all(
                   $dom->documentElement, $context);
 foreach my $haudio (@haudios)
 {
   print $haudio->get_fn . "\n";
 }

=head1 DESCRIPTION

HTML::Microformats::Format::hAudio inherits from HTML::Microformats::Format. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

=cut

package HTML::Microformats::Format::hAudio;

use base qw(HTML::Microformats::Format HTML::Microformats::Mixin::Parser);
use strict qw(subs vars); no warnings;
use 5.010;

use HTML::Microformats::Utilities qw(searchClass stringify);

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Format::hAudio::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Format::hAudio::VERSION   = '0.105';
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
	
	# Items - too tricky for simple_parse() to handle!
	my ($this_item, $last_item);
	my @items = searchClass('item', $clone);
	foreach my $i (@items)
	{
		# Deal with ".haudio .item .item", etc! This shuld work...
		if (length $last_item)
		{
			$this_item = $i->getAttribute('data-cpan-html-microformats-nodepath');
			next if substr($this_item, 0, length $last_item) eq $last_item;
		}
		$last_item = $i->getAttribute('data-cpan-html-microformats-nodepath');
		
		my $I = $class->new($i, $context);
		$I->{'DATA'}->{'title'} = stringify($i, 'value')
			unless defined $I->{'DATA'}->{'fn'} || defined $I->{'DATA'}->{'album'};
		$I->{'related'}->{'parent'} = $self;
		push @{ $self->{'DATA'}->{'item'} }, $I;
		$self->_destroy_element($i);
	}

	$self->_simple_parse($clone);

	# Does this represent an album or a track?
	# http://microformats.org/wiki/haudio#More_Semantic_Equivalents
	if (defined $self->{'DATA'}->{'fn'} && defined $self->{'DATA'}->{'album'})
		{ $self->{'DATA'}->{'type'} = 'track'; }
	elsif (defined $self->{'DATA'}->{'album'})
		{ $self->{'DATA'}->{'type'} = 'album'; }
	else
		{ $self->{'DATA'}->{'type'} = 'track'; }
	
	$self->_do_inheritance;
	
	$cache->set($context, $element, $class, $self)
		if defined $cache;

	return $self;
}

sub _do_inheritance
{
	my $self = shift;
	
	ITEM: foreach my $item (@{ $self->{'DATA'}->{'item'} })
	{
		PROPERTY: foreach my $property (qw(album contributor category published photo))
		{
			next PROPERTY if defined $item->{'DATA'}->{$property};
			$item->{'DATA'}->{$property} = $self->{'DATA'}->{$property};
		}
		# Recursion.
		$item->_do_inheritance;
	}

	return $self;
}

sub format_signature
{
	my $media = 'http://purl.org/media#';
	my $audio = 'http://purl.org/media/audio#';
	my $comm  = 'http://purl.org/commerce#';
	my $dc    = 'http://purl.org/dc/terms/';
	my $rdf   = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
	
	return {
		'root' => 'haudio',
		'classes' => [
			['album',       '?'],
			['category',    '*'],
			['contributor', 'M*', {embedded=>'hCard'}],
			['description', '&'],
			['duration',    'D?'],
			['enclosure',   'ru*'],
			['fn',          '?'],
			['item',        '*#'],
			['payment',     'ru*'],
			['position',    'n?'],
			['photo',       'u*'],
			['price',       'M?', {embedded=>'hMeasure'}],
			['published',   'd*'],
			['publisher',   'M*', {embedded=>'hCard'}], # extension
			['sample',      'ru*'],
			['title',       '?',  {'use-key'=>'fn'}], # fallback (historical)
			['type',        '?#'],  # always inferred
			['url',         'u*']
		],
		'options' => {
			'rel-tag' => 'category',
		},
		'rdf:type' => [] ,
		'rdf:property' => {
			'category'    => { resource => ["{$dc}type"] , literal => ["{$dc}type"] } ,
			'contributor' => { resource => ["{$dc}contributor"] } ,
			'description' => { literal  => ["{$dc}description"] } ,
			'duration'    => { literal  => ["{$media}duration"] } ,
			'enclosure'   => { resource => ["{$media}download"] } ,
			'item'        => { resource => ["{$media}contains"] } ,
			'payment'     => { resource => ["{$comm}payment"] } ,
			'photo'       => { resource => ["{$media}depiction"] } ,
			'price'       => { literal  => ["{$comm}costs"] , resource => ['http://buzzword.org.uk/rdf/measure-aux#hasMeasurement'] } ,
			'publisher'   => { resource => ["{$dc}publisher"] } ,
			'published'   => { literal  => ["{$dc}published"] } ,
			'sample'      => { resource => ["{$media}sample"] } ,
			'url'         => { resource => ['http://xmlns.com/foaf/0.1/page'] },
		},
	};
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;

	$self->_simple_rdf($model);
	
	my $media = 'http://purl.org/media#';
	my $audio = 'http://purl.org/media/audio#';
	my $comm  = 'http://purl.org/commerce#';
	my $dc    = 'http://purl.org/dc/terms/';
	my $rdf   = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
	my $rdfs  = 'http://www.w3.org/2000/01/rdf-schema#';
	
	if ($self->get_type eq 'album')
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${rdf}type"),
			RDF::Trine::Node::Resource->new("${audio}Album"),
			));
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${rdfs}label"),
			$self->_make_literal($self->get_album),
			));
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${dc}title"),
			$self->_make_literal($self->get_album),
			));
	}
	elsif ($self->get_type eq 'track')
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${rdf}type"),
			RDF::Trine::Node::Resource->new("${audio}Recording"),
			));
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${rdfs}label"),
			$self->_make_literal($self->get_fn),
			));
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${dc}title"),
			$self->_make_literal($self->get_fn),
			));
		
		if (defined $self->get_album
		&& (!defined $self->{'related'}->{'parent'} || $self->{'related'}->{'parent'}->get_album ne $self->get_album))
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, 'album'),
				RDF::Trine::Node::Resource->new("${rdf}type"),
				RDF::Trine::Node::Resource->new("${audio}Album"),
				));
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, 'album'),
				RDF::Trine::Node::Resource->new("${rdfs}label"),
				$self->_make_literal($self->get_album),
				));
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, 'album'),
				RDF::Trine::Node::Resource->new("${dc}title"),
				$self->_make_literal($self->get_album),
				));
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, 'album'),
				RDF::Trine::Node::Resource->new("${media}contains"),
				$self->id(1),
				));
		}
	}

	return $self;
}

sub profiles
{
	my $class = shift;
	return qw(http://purl.org/uF/hAudio/0.9/
		http://purl.org/NET/haudio);
}

1;

=head1 MICROFORMAT

HTML::Microformats::Format::hAudio supports hAudio 0.91 as described at
L<http://microformats.org/wiki/hAudio>, plus:

=over 4

=item * 'publisher' property

A 'publisher' property with an embedded hCard can be used to indicate the
publisher of the audio item (e.g. record label).

=item * 'title' property

In earlier drafts pf hAudio, the 'fn' property was called 'title'. This module supports
the older class name for backwards compatibility. When both are provided, only
'fn' will be used.

=back

=head1 RDF OUTPUT

RDF output uses Manu Sporny's audio vocabulary L<http://purl.org/media/audio>.

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

