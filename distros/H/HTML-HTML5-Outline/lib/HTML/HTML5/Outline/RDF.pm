package HTML::HTML5::Outline::RDF;

use 5.008;
use strict;

use base qw[Exporter];

use constant NMTOKEN        => 'http://www.w3.org/2001/XMLSchema#NMTOKEN';
use constant PROP_TITLE     => 'http://purl.org/dc/terms/title';
use constant PROP_TAG       => 'http://ontologi.es/outline#tag';
use constant RDF_FIRST      => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#first';
use constant RDF_REST       => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#rest';
use constant RDF_NIL        => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#nil';
use constant REL_ASIDE      => 'http://ontologi.es/outline#aside';
use constant REL_BQ         => 'http://ontologi.es/outline#blockquote';
use constant REL_FIGURE     => 'http://ontologi.es/outline#figure';
use constant REL_HEADING    => 'http://ontologi.es/outline#heading';
use constant REL_IPART      => 'http://ontologi.es/outline#ipart';
use constant REL_PART       => 'http://ontologi.es/outline#part';
use constant REL_PARTLIST   => 'http://ontologi.es/outline#part-list';
use constant REL_SECTION    => 'http://ontologi.es/outline#section';
use constant REL_TYPE       => 'http://purl.org/dc/terms/type';
use constant TYPE_DATASET   => 'http://purl.org/dc/dcmitype/Dataset';
use constant TYPE_IMAGE     => 'http://purl.org/dc/dcmitype/Image';
use constant TYPE_TEXT      => 'http://purl.org/dc/dcmitype/Text';

our $VERSION = '0.006';

our (@EXPORT, %EXPORT_TAGS, @EXPORT_OK);
BEGIN
{
	@EXPORT = qw();
	%EXPORT_TAGS = ('constants' => [qw(NMTOKEN PROP_TITLE PROP_TAG
		RDF_FIRST RDF_REST RDF_NIL TYPE_DATASET TYPE_IMAGE TYPE_TEXT
		REL_ASIDE REL_BQ REL_FIGURE REL_HEADING REL_IPART REL_PART
		REL_PARTLIST REL_SECTION REL_TYPE)]);
	@EXPORT_OK = @{$EXPORT_TAGS{'constants'}};
}

package HTML::HTML5::Outline;

use strict;
use RDF::Trine;
BEGIN { HTML::HTML5::Outline::RDF->import(':constants'); }

sub to_rdf
{
	my ($self) = @_;
	return $self->{model} if defined $self->{model};
	
	$self->{model}   = RDF::Trine::Model->temporary_model;
	
	my $page_url     = $self->{options}->{uri};
	my $outline      = $self->primary_outlinee;
	my $outline_node = $outline->add_to_model($self->{model});

	$self->{model}->add_statement(RDF::Trine::Statement->new(
		RDF::Trine::Node::Resource->new($page_url),
		RDF::Trine::Node::Resource->new(REL_IPART),
		$outline_node,
		))
		unless ($outline_node->is_resource and $outline_node->uri eq $page_url);
	
	return $self->{model};
}

sub _add_partlist_to_model
{
	my ($self, $section, $model, @partlist) = @_;
	return if $self->{options}->{suppress_collections};
	
	if (!@partlist)
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$section->{trine_node},
			RDF::Trine::Node::Resource->new(REL_PARTLIST),
			RDF::Trine::Node::Resource->new(RDF_NIL),
			));
		return;
	}
	
	my @sorted = reverse sort { $a->order <=> $b->order } @partlist;

	my $rest = RDF::Trine::Node::Resource->new(RDF_NIL);
	foreach my $item (@sorted)
	{
		my $list = RDF::Trine::Node::Blank->new;
		
		$model->add_statement(RDF::Trine::Statement->new(
			$list,
			RDF::Trine::Node::Resource->new(RDF_FIRST),
			$item->{trine_node},
			));
		$model->add_statement(RDF::Trine::Statement->new(
			$list,
			RDF::Trine::Node::Resource->new(RDF_REST),
			$rest,
			));
		
		$rest = $list;
	}

	$model->add_statement(RDF::Trine::Statement->new(
		$section->{trine_node},
		RDF::Trine::Node::Resource->new(REL_PARTLIST),
		$rest,
		));
}

sub _node_for_element
{
	my ($self, $element) = @_;
	
	my $np = $element->nodePath;
	
	unless ($self->{element_subjects}{$np})
	{
		$self->{element_subjects}{$np} = 
			$element->hasAttribute('id') && length $element->getAttribute('id')
				? RDF::Trine::Node::Resource->new($self->{options}{uri}.'#'.$element->getAttribute('id'))
				: RDF::Trine::Node::Blank->new;
	}
	
	if (!ref $self->{element_subjects}{$np})
	{
		if ($self->{element_subjects}{$np} =~ /^_:(.+)$/)
		{
			$self->{element_subjects}{$np} = RDF::Trine::Node::Blank->new($1);
		}
		else
		{
			$self->{element_subjects}{$np} = RDF::Trine::Node::Resource->new($self->{element_subjects}{$np});
		}
	}
	
	return $self->{element_subjects}{$np};
}

package HTML::HTML5::Outline::Section;

use strict;
use RDF::Trine;
BEGIN { HTML::HTML5::Outline::RDF->import(':constants'); }

sub add_to_model
{
	my ($self, $model) = @_;

	$self->{trine_node}            = my $self_node   = RDF::Trine::Node::Blank->new;
	$self->{trine_node_for_header} = my $header_node = $self->outliner->_node_for_element($self->header);

	$model->add_statement(RDF::Trine::Statement->new(
		$self_node,
		RDF::Trine::Node::Resource->new(PROP_TITLE),
		RDF::Trine::Node::Literal->new($self->heading, $self->outliner->_node_lang($self->header)),
		));

	$model->add_statement(RDF::Trine::Statement->new(
		$self_node,
		RDF::Trine::Node::Resource->new(REL_TYPE),
		RDF::Trine::Node::Resource->new(TYPE_TEXT),
		));
	
	$model->add_statement(RDF::Trine::Statement->new(
		$self_node,
		RDF::Trine::Node::Resource->new(REL_HEADING),
		$header_node,
		));
		
	$model->add_statement(RDF::Trine::Statement->new(
		$header_node,
		RDF::Trine::Node::Resource->new(PROP_TAG),
		RDF::Trine::Node::Literal->new($self->header->tagName, undef, NMTOKEN),
		));

	my @partlist;
	foreach my $child (@{$self->{sections}})
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self_node,
			RDF::Trine::Node::Resource->new(REL_PART),
			$child->add_to_model($model),
			));
		push @partlist, $child;
	}

	foreach my $e (@{$self->{elements}})
	{
		my $E = HTML::HTML5::Outline::k($e);
		
		if ($self->outliner->{outlines}->{$E})
		{
			my $rel = REL_IPART;
			$rel = REL_ASIDE   if lc $e->tagName eq 'aside';
			$rel = REL_BQ      if lc $e->tagName eq 'blockquote';
			$rel = REL_FIGURE  if lc $e->tagName eq 'figure';
			$rel = REL_SECTION if lc $e->tagName eq 'section';
			
			$model->add_statement(RDF::Trine::Statement->new(
				$self_node,
				RDF::Trine::Node::Resource->new($rel),
				$self->outliner->{outlines}->{$E}->add_to_model($model),
				));
				
			push @partlist, $self->outliner->{outlines}->{$E};
		}
	}

	$self->outliner->_add_partlist_to_model($self, $model, @partlist);

	return $self_node;
}

package HTML::HTML5::Outline::Outlinee;

use strict;
use RDF::Trine;
BEGIN { HTML::HTML5::Outline::RDF->import(':constants'); }

sub add_to_model
{
	my ($self, $model) = @_;

	my $rdf_type = TYPE_TEXT;
	
	if ($self->element->localname eq 'figure'
	||  ($self->element->getAttribute('class')||'') =~ /\bfigure\b/)
	{
		$rdf_type = TYPE_IMAGE;
	}
	elsif ($self->element->localname =~ /^(ul|ol)$/i
	&&     ($self->element->getAttribute('class')||'') =~ /\bxoxo\b/)
	{
		$rdf_type = TYPE_DATASET;
	}

	my $self_node = $self->outliner->_node_for_element($self->element);
	$self->{trine_node} = $self_node;
	
	if ($self->element->localname =~ /^(body|html)$/i) 
	{
		$self_node = RDF::Trine::Node::Resource->new($self->outliner->{options}->{uri});
	}
	
	$model->add_statement(RDF::Trine::Statement->new(
		$self_node,
		RDF::Trine::Node::Resource->new(PROP_TAG),
		RDF::Trine::Node::Literal->new($self->element->localname, undef, NMTOKEN),
		))
		unless $self->element->localname =~ /^(body|html)$/i;

	$model->add_statement(RDF::Trine::Statement->new(
		$self_node,
		RDF::Trine::Node::Resource->new(REL_TYPE),
		RDF::Trine::Node::Resource->new($rdf_type),
		));
		
	my @partlist;
	foreach my $section (@{$self->{sections}})
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self_node,
			RDF::Trine::Node::Resource->new(REL_PART),
			$section->add_to_model($model),
			));
		push @partlist, $section;
	}
	$self->outliner->_add_partlist_to_model($self, $model, @partlist);

	return $self_node;
}

1;

__END__

=head1 NAME

HTML::HTML5::Outline::RDF - RDF-related methods

=head1 DESCRIPTION

Some of the RDF-related functionality of C<HTML::HTML5::Outline> is split
out into this module so that the basic outline functionality can still be
used if C<RDF::Trine> is not installed.

RDF support can be disabled using:

	use HTML::HTML5::Outline rdf => 0;

No user-servicable parts within.

=head1 SEE ALSO

L<HTML::HTML5::Outline>.

L<RDF::Trine>, L<RDF::RDFa::Parser>, L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster, E<lt>tobyink@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2008-2011 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
