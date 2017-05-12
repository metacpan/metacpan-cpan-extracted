=head1 NAME

HTML::Microformats::Format::hRecipe - the hRecipe microformat

=head1 SYNOPSIS

 use Data::Dumper;
 use HTML::Microformats::DocumentContext;
 use HTML::Microformats::Format::hRecipe;

 my $context = HTML::Microformats::DocumentContext->new($dom, $uri);
 my @recipes = HTML::Microformats::Format::hRecipe->extract_all(
                   $dom->documentElement, $context);
 foreach my $recipe (@recipes)
 {
   print $recipe->get_summary . "\n";
 }

=head1 DESCRIPTION

HTML::Microformats::Format::hRecipe inherits from HTML::Microformats::Format. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

=cut

package HTML::Microformats::Format::hRecipe;

use base qw(HTML::Microformats::Format HTML::Microformats::Mixin::Parser);
use strict qw(subs vars); no warnings;
use 5.010;

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Format::hRecipe::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Format::hRecipe::VERSION   = '0.105';
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

	$cache->set($context, $element, $class, $self)
		if defined $cache;

	return $self;
}

sub format_signature
{
	my $lr   = 'http://linkedrecipes.org/schema/';
	my $hr   = 'http://ontologi.es/hrecipe#';
	my $rdfs = 'http://www.w3.org/2000/01/rdf-schema#';
	
	return {
		'root' => 'hrecipe',
		'classes' => [
			['fn',            '1'],
			['ingredient',    '+'],
			['yield',         '?'],
			['instructions',  'H?'],
			['duration',      'D*'],
			['photo',         'u*'],
			['summary',       '?'],
			['author',        'M*', {embedded=>'hCard !person'}],
			['published',     'd?'],
			['nutrition',     '*'],
		],
		'options' => {
			'rel-tag' => 'tag',
		},
		'rdf:type' => ["${lr}Recipe"] ,
		'rdf:property' => {
			'fn'                => { 'literal'  => ["${rdfs}label"] } ,
			'yield'             => { 'literal'  => ["${lr}servings"] } ,
			'html_instructions' => { 'literal'  => ["${hr}instructions"], 'literal_datatype'=>'http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral' } ,
			'duration'          => { 'literal'  => ["${lr}time"] } ,
			'photo'             => { 'resource' => ['http://xmlns.com/foaf/0.1/depiction'] },
			'summary'           => { 'literal'  => ["${rdfs}comment"] } ,
			'published'         => { 'literal'  => ['http://purl.org/dc/terms/issued'] },
			'nutrition'         => { 'literal'  => ["${lr}dietaryInformation"] } ,
		},
	};
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;

	$self->_simple_rdf($model);

	my $lr   = 'http://linkedrecipes.org/schema/';
	my $hr   = 'http://ontologi.es/hrecipe#';
	my $rdfs = 'http://www.w3.org/2000/01/rdf-schema#';

	# Handle ingredients.
	my $i = 0;
	foreach my $ingredient (@{ $self->data->{'ingredient'} })
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${lr}ingredient"),
			$self->id(1, "ingredient.${i}"),
			));
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1, "ingredient.${i}"),
			RDF::Trine::Node::Resource->new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"),
			RDF::Trine::Node::Resource->new("${lr}IngredientPortion"),
			));
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1, "ingredient.${i}"),
			RDF::Trine::Node::Resource->new("${rdfs}label"),
			$self->_make_literal($ingredient),
			));
		
		$i++;
	}
	
	foreach my $author (@{ $self->data->{'author'} })
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("http://xmlns.com/foaf/0.1/maker"),
			$author->id(1, "holder"),
			));
		$author->add_to_model($model);
	}

	return $self;
}

sub profiles
{
	my $class = shift;
	return qw(http://purl.org/uF/hRecipe/0.23/);
}

1;

=head1 MICROFORMAT

HTML::Microformats::Format::hRecipe supports hRecipe 0.23 as described at
L<http://microformats.org/wiki/hrecipe>.

=head1 RDF OUTPUT

L<http://linkedrecipes.org/schema/>,
L<http://ontologi.es/hrecipe#>.

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

