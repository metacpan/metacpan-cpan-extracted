=head1 NAME

HTML::Microformats::Format::XFN - the XFN microformat

=head1 SYNOPSIS

 use Data::Dumper;
 use HTML::Microformats::DocumentContext;
 use HTML::Microformats::Format::XFN;

 my $context = HTML::Microformats::DocumentContext->new($dom, $uri);
 my @links   = HTML::Microformats::Format::XFN->extract_all(
                   $dom->documentElement, $context);
 foreach my $link (@links)
 {
   printf("<%s> %s\n", $link->get_href, join(" ", $link->get_rel));
 }

=head1 DESCRIPTION

HTML::Microformats::Format::XFN inherits from HTML::Microformats::Format. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

=cut

package HTML::Microformats::Format::XFN;

use base qw(HTML::Microformats::Format);
use strict qw(subs vars); no warnings;
use 5.010;

use HTML::Microformats::Utilities qw(stringify searchAncestorClass);
use HTML::Microformats::Format::hCard;
use RDF::Trine;

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Format::XFN::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Format::XFN::VERSION   = '0.105';
}

sub new
{
	my ($class, $element, $context) = @_;
	my $cache = $context->cache;
	
	return $cache->get($context, $element, $class)
		if defined $cache && $cache->get($context, $element, $class);
	
	my $self = bless {
		'element'    => $element ,
		'context'    => $context ,
		'cache'      => $cache ,
		}, $class;

	# Extract XFN-related @rel values.
	$self->_extract_xfn_relationships;
	
	# If none, then just return undef.
	return undef
		unless @{ $self->{'DATA'}->{'rel'} }
		||     @{ $self->{'DATA'}->{'rev'} };

	$self->{'DATA'}->{'href'}  = $context->uri( $element->getAttribute('href') );
	$self->{'DATA'}->{'label'} = stringify($element, 'value');
	$self->{'DATA'}->{'title'} = $element->hasAttribute('title')
	                           ? $element->getAttribute('title')
	                           : $self->{'DATA'}->{'label'};
										
	$self->{'id'}        = $self->{'DATA'}->{'href'};
	$self->{'id.person'} = $context->make_bnode;
	
	my $hcard_element = searchAncestorClass('vcard', $element, 0);
	if ($hcard_element)
	{
		$self->{'hcard'} = HTML::Microformats::Format::hCard->new($hcard_element, $context);
		if ($self->{'hcard'})
		{
			$self->{'id.person'} = $self->{'hcard'}->id(0, 'holder');
		}
	}
	
	$self->context->representative_hcard;

	$cache->set($context, $element, $class, $self)
		if defined $cache;
		
	return $self;
}

sub extract_all
{
	my ($class, $dom, $context) = @_;

	my @links  = $dom->getElementsByTagName('link');
	push @links, $dom->getElementsByTagName('a');
	push @links, $dom->getElementsByTagName('area');
	
	my @rv;
	foreach my $link (@links)
	{
		my $xfn = $class->new($link, $context);
		push @rv, $xfn if defined $xfn;
	}
	
	return @rv;
}

sub _extract_xfn_relationships
{
	my ($self) = @_;
	
	my $R = $self->_xfn_relationship_types;
	
	my $regexp = join '|', keys %$R;
	$regexp = "($regexp)";

	DIR: foreach my $direction (qw(rel rev))
	{
		if ($self->{'element'}->hasAttribute($direction))
		{
			my @matches = 
				grep { $_ =~ /^($regexp)$/ }
				split /\s+/, $self->{'element'}->getAttribute($direction);
			next DIR unless @matches;
			$self->{'DATA'}->{$direction} = [ map { lc $_ } @matches ];
		}
	}
}

sub add_to_model
{
	my ($self, $model) = @_;
	
	my $R = $self->_xfn_relationship_types;
	
	foreach my $r (@{ $self->data->{'rel'} })
	{
		next if lc $r eq 'me';

		my ($page_link, $person_link);
		my ($flags, $other) = split /\:/, $R->{$r}, 2;
		
		if ($flags =~ /E/i)
		{
			$page_link   = "http://buzzword.org.uk/rdf/xen#${r}-hyperlink";
			$person_link = "http://buzzword.org.uk/rdf/xen#${r}";
		}
		elsif ($flags =~ /R/i)
		{
			$page_link   = "http://vocab.sindice.com/xfn#human-relationship-hyperlink";
			$person_link = "http://purl.org/vocab/relationship/${r}";
		}
		else
		{
			$page_link   = "http://vocab.sindice.com/xfn#${r}-hyperlink";
			$person_link = "http://vocab.sindice.com/xfn#${r}";
		}
		
		$model->add_statement(RDF::Trine::Statement->new(
			RDF::Trine::Node::Resource->new( $self->context->document_uri ),
			RDF::Trine::Node::Resource->new( $page_link ),
			RDF::Trine::Node::Resource->new( $self->data->{'href'} ),
			));

		$model->add_statement(RDF::Trine::Statement->new(
			$self->context->representative_person_id(1),
			RDF::Trine::Node::Resource->new( $person_link ),
			$self->id(1, 'person'),
			));
		
		if ($flags =~ /K/i)
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->context->representative_person_id(1),
				RDF::Trine::Node::Resource->new( 'http://xmlns.com/foaf/0.1/knows' ),
				$self->id(1, 'person'),
				));
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, 'person'),
				RDF::Trine::Node::Resource->new( 'http://xmlns.com/foaf/0.1/knows' ),
				$self->context->representative_person_id(1),
				))
				if $flags =~ /S/i;
		}
		
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1, 'person'),
			RDF::Trine::Node::Resource->new( $person_link ),
			$self->context->representative_person_id(1),
			))
			if $flags =~ /S/i;
		
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1, 'person'),
			RDF::Trine::Node::Resource->new($other),
			$self->context->representative_person_id(1),
			))
			if $flags =~ /I/i && length $other;
	}

	foreach my $r (@{ $self->data->{'rev'} })
	{
		next if lc $r eq 'me';
		
		my $person_link;
		my ($flags, $other) = split /\:/, $R->{$r}, 2;
		
		if ($flags =~ /E/i)
		{
			$person_link = "http://buzzword.org.uk/rdf/xen#${r}";
		}
		elsif ($flags =~ /R/i)
		{
			$person_link = "http://purl.org/vocab/relationship/${r}";
		}
		else
		{
			$person_link = "http://vocab.sindice.com/xfn#${r}";
		}

		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1, 'person'),
			RDF::Trine::Node::Resource->new( $person_link ),
			$self->context->representative_person_id(1),
			));

		if ($flags =~ /K/i)
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, 'person'),
				RDF::Trine::Node::Resource->new( 'http://xmlns.com/foaf/0.1/knows' ),
				$self->context->representative_person_id(1),
				));
			$model->add_statement(RDF::Trine::Statement->new(
				$self->context->representative_person_id(1),
				RDF::Trine::Node::Resource->new( 'http://xmlns.com/foaf/0.1/knows' ),
				$self->id(1, 'person'),
				))
				if $flags =~ /S/i;
		}
		
		$model->add_statement(RDF::Trine::Statement->new(
			$self->context->representative_person_id(1),
			RDF::Trine::Node::Resource->new( $person_link ),
			$self->id(1, 'person'),
			))
			if $flags =~ /S/i;
		
		$model->add_statement(RDF::Trine::Statement->new(
			$self->context->representative_person_id(1),
			RDF::Trine::Node::Resource->new($other),
			$self->id(1, 'person'),
			))
			if $flags =~ /I/i && length $other;
	}

	$model->add_statement(RDF::Trine::Statement->new(
		$self->id(1, 'person'),
		RDF::Trine::Node::Resource->new( 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' ),
		RDF::Trine::Node::Resource->new( 'http://xmlns.com/foaf/0.1/Person' ),
		));

	$model->add_statement(RDF::Trine::Statement->new(
		$self->id(1, 'person'),
		RDF::Trine::Node::Resource->new( 'http://xmlns.com/foaf/0.1/'.($self->data->{'href'} =~ /^mailto:/i ? 'mbox' : 'page') ),
		RDF::Trine::Node::Resource->new( $self->data->{'href'} ),
		));

	$model->add_statement(RDF::Trine::Statement->new(
		RDF::Trine::Node::Resource->new( $self->data->{'href'} ),
		RDF::Trine::Node::Resource->new( 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' ),
		RDF::Trine::Node::Resource->new( 'http://xmlns.com/foaf/0.1/Document' ),
		))
		unless $self->data->{'href'} =~ /^mailto:/i;
	
	if (grep /^me$/i, @{ $self->data->{'rel'} })
	{
		$model->add_statement(RDF::Trine::Statement->new(
			RDF::Trine::Node::Resource->new( $self->context->document_uri ),
			RDF::Trine::Node::Resource->new( 'http://vocab.sindice.com/xfn#me-hyperlink' ),
			RDF::Trine::Node::Resource->new( $self->data->{'href'} ),
			));
	}
	if (grep /^me$/i, @{ $self->data->{'rev'} })
	{
		$model->add_statement(RDF::Trine::Statement->new(
			RDF::Trine::Node::Resource->new( $self->data->{'href'} ),
			RDF::Trine::Node::Resource->new( 'http://vocab.sindice.com/xfn#me-hyperlink' ),
			RDF::Trine::Node::Resource->new( $self->context->document_uri ),
			));
	}	
}

sub profiles
{
	my $class = shift;
	return qw(http://gmpg.org/xfn/11
		http://purl.org/uF/2008/03/
		http://gmpg.org/xfn/1
		http://microformats.org/profile/specs
		http://ufs.cc/x/specs
		http://xen.adactio.com/
		http://purl.org/vocab/relationship/);
}

sub id
{
	my ($self, $trine, $relation) = @_;
	
	if ($relation eq 'person')
	{
		if (grep /^me$/i, @{ $self->data->{'rel'} }
		or  grep /^me$/i, @{ $self->data->{'rev'} })
		{
			return $self->context->representative_person_id($trine);
		}
	}
	
	$self->SUPER::id($trine, $relation);
}


sub _xfn_relationship_types
{
	my ($self) = @_;
	
	# FLAGS
	# =====
	#
	# S = symmetric
	# K = foaf:knows
	# I = has inverse
	# T = transitive
	# E = enemies vocab
	# R = relationship vocab
	#
	
	my %xfn11 = (
		'contact'       => ':',
		'acquaintance'  => 'K:',
		'friend'        => 'K:',
		'met'           => 'SK:',
		'co-worker'     => 'S:',
		'colleague'     => 'S:',
		'co-resident'   => 'SKT:',
		'neighbor'      => 'S:',
		'child'         => 'I:http://vocab.sindice.com/xfn#parent',
		'parent'        => 'I:http://vocab.sindice.com/xfn#child',
		'sibling'       => 'S:',
		'spouse'        => 'SK:',
		'kin'           => 'S:',
		'muse'          => ':',
		'crush'         => 'K:',
		'date'          => 'SK:',
		'sweetheart'    => 'SK:',
		'me'            => 'S:',
	);
	
	my %R; # relationship types
	
	if ($self->context->has_profile('http://gmpg.org/xfn/11',
		'http://purl.org/uF/2008/03/'))
	{
		%R = %xfn11;
	}
	elsif ($self->context->has_profile('http://gmpg.org/xfn/1'))
	{
		%R = (
			'acquaintance'  => 'K:',
			'friend'        => 'K:',
			'met'           => 'SK:',
			'co-worker'     => 'S:',
			'colleague'     => 'S:',
			'co-resident'   => 'SKT:',
			'neighbor'      => 'S:',
			'child'         => 'I:http://vocab.sindice.com/xfn#parent',
			'parent'        => 'I:http://vocab.sindice.com/xfn#child',
			'sibling'       => 'S:',
			'spouse'        => 'SK:',
			'muse'          => ':',
			'crush'         => 'K:',
			'date'          => 'SK:',
			'sweetheart'    => 'SK:',
		);
	}

	if ($self->context->has_profile('http://xen.adactio.com/'))
	{
		$R{'nemesis'}    = 'SKE:';
		$R{'enemy'}      = 'KE:';
		$R{'nuisance'}   = 'KE:';
		$R{'evil-twin'}  = 'SE:';
		$R{'rival'}      = 'KE:';
		$R{'fury'}       = 'E:';
		$R{'creep'}      = 'E:';
	}

	if ($self->context->has_profile('http://purl.org/vocab/relationship/'))
	{
		$R{'acquaintanceOf'}    = 'KR:';
		$R{'ambivalentOf'}      = 'R:';
		$R{'ancestorOf'}        = 'RI:http://purl.org/vocab/relationship/descendantOf';
		$R{'antagonistOf'}      = 'KR:';
		$R{'apprenticeTo'}      = 'KR:';
		$R{'childOf'}           = 'KRI:http://purl.org/vocab/relationship/parentOf';
		$R{'closeFriendOf'}     = 'KR:';
		$R{'collaboratesWith'}  = 'SKR:';
		$R{'colleagueOf'}       = 'SKR:';
		$R{'descendantOf'}      = 'RI:http://purl.org/vocab/relationship/ancestorOf';
		$R{'employedBy'}        = 'KRI:http://purl.org/vocab/relationship/employerOf';
		$R{'employerOf'}        = 'KRI:http://purl.org/vocab/relationship/employedBy';
		$R{'enemyOf'}           = 'KR:';
		$R{'engagedTo'}         = 'SKR:';
		$R{'friendOf'}          = 'KR:';
		$R{'grandchildOf'}      = 'KRI:http://purl.org/vocab/relationship/grandparentOf';
		$R{'grandparentOf'}     = 'KRI:http://purl.org/vocab/relationship/grandchildOf';
		$R{'hasMet'}            = 'SKR:';
		$R{'influencedBy'}      = 'R:';
		$R{'knowsByReputation'} = 'R:';
		$R{'knowsInPassing'}    = 'KR:';
		$R{'knowsOf'}           = 'R:';
		$R{'lifePartnerOf'}     = 'SKR:';
		$R{'livesWith'}         = 'SKR:';
		$R{'lostContactWith'}   = 'KR:';
		$R{'mentorOf'}          = 'KR:';
		$R{'neighborOf'}        = 'SKR:';
		$R{'parentOf'}          = 'KRI:http://purl.org/vocab/relationship/childOf';
		$R{'siblingOf'}         = 'SKR:';
		$R{'spouseOf'}          = 'SKR:';
		$R{'worksWith'}         = 'SKR:';
		$R{'wouldLikeToKnow'}   = 'R:';
	}
	
	return \%R if %R;
	
	return \%xfn11;
}

=head2 Additional Public Methods

=over 4

=item C<< $xfn->subject_hcard >>

Returns the hCard for the subject of the relationship. e.g. if Mary has parent Sue, then
Mary is the subject.

If the subject could not be determined, may return undef.

=cut

sub subject_hcard
{
	my $self = shift;
	return $self->context->representative_hcard;
}

=item C<< $xfn->object_hcard >>

Returns the hCard for the object of the relationship. e.g. if Mary has parent Sue, then
Sue is the object.

The person that is the object of the relationship may not have an hCard on this page,
or the parser may not be able to determine the correct hCard, in which case, may return
undef.

=back

=cut

sub object_hcard
{
	my $self = shift;
	return $self->{'hcard'};
}


1;

=head1 MICROFORMAT

HTML::Microformats::Format::XFN supports XHTML Friends Network 1.0 and 1.1
as described at L<http://gmpg.org/xfn/1> and L<http://gmpg.org/xfn/11>; plus the
relationship profile described at L<http://purl.org/vocab/relationship/>;
and XHTML Enemies Network 1.0 as described at L<http://xen.adactio.com/>.

By default, only XFN 1.1 is parsed, but if the context has profiles matching the
other URIs above, then the other vocabularies are supported.

=head1 RDF OUTPUT

Data is returned using the DERI's XFN vocabulary
(L<http://vocab.sindice.com/xfn#>) and when appropriate, Ian Davis'
RDF relationship vocab (L<http://purl.org/vocab/relationship/>)
and Toby Inkster's XEN vocab (L<http://buzzword.org.uk/rdf/xen#>).

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats::Format>,
L<HTML::Microformats>,
L<HTML::Microformats::Format::hCard>.

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

