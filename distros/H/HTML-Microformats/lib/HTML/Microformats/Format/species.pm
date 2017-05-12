=head1 NAME

HTML::Microformats::Format::species - the species microformat

=head1 SYNOPSIS

 use HTML::Microformats::DocumentContext;
 use HTML::Microformats::Format::hCard;

 my $context = HTML::Microformats::DocumentContext->new($dom, $uri);
 my @objects = HTML::Microformats::Format::species->extract_all(
                   $dom->documentElement, $context);
 foreach my $species (@objects)
 {
   print $species->get_binomial . "\n";
 }

=head1 DESCRIPTION

HTML::Microformats::Format::species inherits from HTML::Microformats::Format. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

=cut

package HTML::Microformats::Format::species;

use base qw(HTML::Microformats::Format HTML::Microformats::Mixin::Parser);
use strict qw(subs vars); no warnings;
use 5.010;

use HTML::Microformats::Datatype::String qw(isms);
use HTML::Microformats::Utilities qw(searchClass stringify);
use RDF::Trine;

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Format::species::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Format::species::VERSION   = '0.105';
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
	$self->_species_parse($clone);

	$cache->set($context, $element, $class, $self)
		if defined $cache;

	return $self;
}

sub format_signature
{
	my $class = shift;
	my $ranks = $class->_ranks;
	
	my $biol = 'http://purl.org/NET/biol/ns#';

	my $rv = {
		'root' => 'biota',
		'classes' => [
			['binomial',         '*'],
			['trinomial',        '*'],
			['authority',        '*'],
			['common-name',      '*'],
		],
		'options' => {},
		'rdf:type' => ["${biol}Taxonomy"] ,
		'rdf:property' => {},
	};
	
	foreach my $term (keys %{ $ranks->{Terms} })
	{
		push @{ $rv->{'classes'} }, [$term, '?'];
	}
	
	return $rv;
}

sub profiles
{
	# placeholder
	return qw(http://purl.org/NET/cpan-uri/dist/HTML-Microformats/profile-species);
}

sub add_to_model
{
	my ($self, $model) = @_;
	my $ranks = $self->_ranks;
	
	foreach my $term (keys %{ $ranks->{Terms} })
	{
		next if $term eq 'rank'; # handle later.
		
		if (defined $self->data->{$term})
		{
			my $prefuri;
			if ($self->{'type'} eq 'B')
			{
				$prefuri = $ranks->{'Terms'}->{$term}->{'URI.C'}
					|| $ranks->{'Terms'}->{$term}->{'URI.B'}
					|| $ranks->{'Terms'}->{$term}->{'URI.Z'};
			}
			else
			{
				$prefuri = $ranks->{'Terms'}->{$term}->{'URI.C'}
					|| $ranks->{'Terms'}->{$term}->{'URI.Z'}
					|| $ranks->{'Terms'}->{$term}->{'URI.B'};
			}
			
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1),
				RDF::Trine::Node::Resource->new( $prefuri ),
				RDF::Trine::Node::Literal->new(''.$self->data->{$term}),
				));
		}
	}
	
	my %uri = (
		authority  => 'http://purl.org/NET/biol/ns#authority',
		commonName => 'http://purl.org/NET/biol/ns#commonName',
		binomial   => 'http://purl.org/NET/biol/ns#name',
		trinomial  => 'http://purl.org/NET/biol/ns#name',
		rank       => 'http://purl.org/NET/biol/ns#rank',
		);

	foreach my $term (qw(rank binomial trinomial))
	{
		foreach my $value (@{ $self->data->{$term} })
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1),
				RDF::Trine::Node::Resource->new($uri{$term}),
				RDF::Trine::Node::Literal->new("$value"),
				));
		}
	}

	# Handle these separately, so that we can preserve language code.
	foreach my $term (qw(authority common-name))
	{
		foreach my $value (@{ $self->data->{$term} })
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1),
				RDF::Trine::Node::Resource->new($uri{$term}),
				$self->_make_literal($value),
				));
		}
	}
	
	if ($self->{'type'} eq 'Z')
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
			RDF::Trine::Node::Resource->new('http://purl.org/NET/biol/ns#ZooTaxonomy'),
			));
	}
	elsif ($self->{'type'} eq 'B')
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
			RDF::Trine::Node::Resource->new('http://purl.org/NET/biol/ns#BotTaxonomy'),
			));
	}
	$model->add_statement(RDF::Trine::Statement->new(
		$self->id(1),
		RDF::Trine::Node::Resource->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
		RDF::Trine::Node::Resource->new('http://purl.org/NET/biol/ns#Taxonomy'),
		));
}

sub _species_parse
{
	my ($self, $root) = @_;
	my $ranks = $self->_ranks;
	
	my $implied_bot = 0;
	my $implied_zoo = 0;
	my $compact     = 1;
	
	$self->_destroyer($root);
	
	foreach my $term (keys %{ $ranks->{Terms} })
	{
		my @nodes = searchClass($term, $root, 'taxo');
		
		# class=species has alias class=specific.
		push @nodes, searchClass('specific', $root, 'taxo')
			if $term eq 'species';
			
		next unless @nodes;
		
		$compact = 0;
		$implied_bot = 1 if ($ranks->{Terms}->{$term}->{Type} eq 'B');
		$implied_zoo = 1 if ($ranks->{Terms}->{$term}->{Type} eq 'Z');
		
		$self->{'DATA'}->{$term} = stringify($nodes[0], 'value');
	}
	
	foreach my $term (qw(binomial trinomial authority rank))
	{
		my @nodes = searchClass($term, $root, 'taxo');
		next unless @nodes;
		
		$compact = 0;
		foreach my $n (@nodes)
			{ push @{$self->{'DATA'}->{$term}}, stringify($n, 'value'); }
	}

	foreach my $term (qw(vernacular common-name cname fn))
	{
		my @nodes = searchClass($term, $root, 'taxo');
		next unless @nodes;

		$compact = 0;
		foreach my $n (@nodes)
			{ push @{$self->{'DATA'}->{'common-name'}}, stringify($n, 'value'); }
	}

	if ($compact)
	{
		$compact =  stringify($root, 'value');
		$compact =~ s/(^\s+|\s+$)//g;
		$compact =~ s/\s+/ /g;
		$self->{'DATA'}->{'binomial'} = [ $compact ] if length $compact;
	}
	
	if ($root->getAttribute('class') =~ /\b(zoology)\b/)
		{ $self->{'type'} = 'Z'; }
	elsif ($root->getAttribute('class') =~ /\b(botany)\b/)
		{ $self->{'type'} = 'B'; }
	elsif ($implied_zoo && !$implied_bot)
		{ $self->{'type'} = 'Z'; }
	elsif ($implied_bot && !$implied_zoo)
		{ $self->{'type'} = 'B'; }
}

sub _ranks
{
	my $plain_n3 = '';
	while (<DATA>)
	{
		chomp;
		next unless /[A-Za-z0-9]/;
		next if /^\s*\#/;
		$plain_n3 .= "$_\n";
	}
	
	my $data = {};
	foreach (split /\s+\.\s+/, $plain_n3)
	{
		s/(^\s+|\s+$)//g;
		s/\s+/ /g;
		my @word = split / /;
		
		if ($word[0] eq '@prefix')
		{
			my $code = $word[1];
			my $uri  = $word[2];
			$code =~ s/\:$//;
			$uri  =~ s/(^\<|\>$)//g;
			
			$data->{Prefixes}->{$code} = $uri;
		}
		
		elsif ($word[1] eq 'a' && $word[2] eq 'owl:DatatypeProperty')
		{
			my ($code, $term) = split /\:/, $word[0];
			my $uri = $data->{Prefixes}->{$code} . $term;
			
			my $type = 'C';
			$type = 'B' if ($uri =~ /botany/);
			$type = 'Z' if ($uri =~ /zoology/);
			
			my $hyphen = $term;
			$hyphen =~ s/([A-Z])/'-'.lc($1)/eg;
			
			$data->{Terms}->{$hyphen}->{Type}       .= $type;
			$data->{Terms}->{$hyphen}->{Camel}       = $term;
			$data->{Terms}->{$hyphen}->{Hyphen}      = $hyphen;
			$data->{Terms}->{$hyphen}->{"URI.$type"} = $uri;
		}
	}

#	foreach my $term (sort keys %{$data->{Terms}})
#	{
#		my $classes = '';
#		$classes .= "core " if ($data->{Terms}->{$term}->{Type} =~ /C/);
#		$classes .= "botany " if ($data->{Terms}->{$term}->{Type} =~ /B/);
#		$classes .= "zoology " if ($data->{Terms}->{$term}->{Type} =~ /Z/);
#		$classes .= "botany-only " if ($data->{Terms}->{$term}->{Type} =~ /^[CB]*$/);
#		$classes .= "zoology-only " if ($data->{Terms}->{$term}->{Type} =~ /^[CZ]*$/);
#		print "<li><code class=\"$classes\">$term</code></li>\n";
#	}
	
	return $data;
}

1;

=head1 MICROFORMAT

The species documentation at L<http://microformats.org/wiki/species> is very
sketchy. This module aims to be roughly compatible with the implementation
of species in the Operator extension for Firefox, and data published by the BBC
and Wikipedia. Here are some brief notes on how is has been impemented:

=over 4

=item * The root class name is 'biota'.

=item * Important properties are 'vernacular' (alias 'common-name', 'cname' or 'fn'),
'binomial', 'trinomial', 'authority'.

=item * Also recognised are 'class', 'division', 'family', 'genus', 'kingdom', 'order',
'phylum', 'species' and various other ranks.

=item * Because some of these property names are fairly generic, you can alternatively
use them in a prefixed form: 'taxo-class', 'taxo-division', etc.

=item * If an element with class 'biota' has no recognised properties within it, the
entire contents of the element are taken to be a binomial name. This allows for
very simple markup:

  <i class="biota">Homo sapiens</i>

=item * The meaning of some terminology differs when used by botanists and zoologists.
You can add the class 'botany' or 'zoology' to the root element to clarify your usage. e.g.

  <i class="biota zoology">Homo sapiens</i>

=back

An example:

  <span class="biota zoology">
    <i class="binomial">
      <span class="genus">Homo</span>
      <span class="species">sapiens</span>
      <span class="subspecies">sapiens</span>
    </i>
    (<span class="authority">Linnaeus, 1758</span>)
    a.k.a. <span class="vernacular">Humans</span>
  </span>

=head1 RDF OUTPUT

RDF output uses the Biological Taxonomy Vocabulary 0.2
(L<http://purl.org/NET/biol/ns#>).

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


__DATA__

# OK - the module doesn't really parse all this N3 properly. It only really
# uses the prefixes, plus the property lists, and it's very sensitive to
# whitespace changes.

\@prefix	core:	<http://purl.org/NET/biol/ns#> .
\@prefix	bot:	<http://purl.org/NET/biol/botany#> .
\@prefix	zoo:	<http://purl.org/NET/biol/zoology#> .
\@prefix	owl:	<http://www.w3.org/2002/07/owl#> .

# Core
core:class	a owl:DatatypeProperty .
core:division	a owl:DatatypeProperty .
core:family	a owl:DatatypeProperty .
core:genus	a owl:DatatypeProperty .
core:kingdom	a owl:DatatypeProperty .
core:order	a owl:DatatypeProperty .
core:phylum	a owl:DatatypeProperty .
core:rank	a owl:DatatypeProperty .
core:species	a owl:DatatypeProperty .

# Botany
bot:aberration	a owl:DatatypeProperty .
bot:aggregate	a owl:DatatypeProperty .
bot:biovar	a owl:DatatypeProperty .
bot:branch	a owl:DatatypeProperty .
bot:breed	a owl:DatatypeProperty .
bot:class	a owl:DatatypeProperty .
bot:claudius	a owl:DatatypeProperty .
bot:cohort	a owl:DatatypeProperty .
bot:complex	a owl:DatatypeProperty .
bot:convariety	a owl:DatatypeProperty .
bot:cultivar	a owl:DatatypeProperty .
bot:cultivarGroup	a owl:DatatypeProperty .
bot:division	a owl:DatatypeProperty .
bot:domain	a owl:DatatypeProperty .
bot:empire	a owl:DatatypeProperty .
bot:falanx	a owl:DatatypeProperty .
bot:family	a owl:DatatypeProperty .
bot:familyGroup	a owl:DatatypeProperty .
bot:form	a owl:DatatypeProperty .
bot:genus	a owl:DatatypeProperty .
bot:genusGroup	a owl:DatatypeProperty .
bot:gigaorder	a owl:DatatypeProperty .
bot:grade	a owl:DatatypeProperty .
bot:grandorder	a owl:DatatypeProperty .
bot:group	a owl:DatatypeProperty .
bot:groupOfBreeds	a owl:DatatypeProperty .
bot:hybrid	a owl:DatatypeProperty .
bot:hyperorder	a owl:DatatypeProperty .
bot:infraclass	a owl:DatatypeProperty .
bot:infradomain	a owl:DatatypeProperty .
bot:infrafamily	a owl:DatatypeProperty .
bot:infraform	a owl:DatatypeProperty .
bot:infragenus	a owl:DatatypeProperty .
bot:infrakingdom	a owl:DatatypeProperty .
bot:infralegion	a owl:DatatypeProperty .
bot:infraorder	a owl:DatatypeProperty .
bot:infraphylum	a owl:DatatypeProperty .
bot:infrasection	a owl:DatatypeProperty .
bot:infraseries	a owl:DatatypeProperty .
bot:infraspecies	a owl:DatatypeProperty .
bot:infratribe	a owl:DatatypeProperty .
bot:infravariety	a owl:DatatypeProperty .
bot:interkingdom	a owl:DatatypeProperty .
bot:kingdom	a owl:DatatypeProperty .
bot:klepton	a owl:DatatypeProperty .
bot:legion	a owl:DatatypeProperty .
bot:lusus	a owl:DatatypeProperty .
bot:magnorder	a owl:DatatypeProperty .
bot:megaorder	a owl:DatatypeProperty .
bot:microspecies	a owl:DatatypeProperty .
bot:midkingdom	a owl:DatatypeProperty .
bot:midphylum	a owl:DatatypeProperty .
bot:mirorder	a owl:DatatypeProperty .
bot:nation	a owl:DatatypeProperty .
bot:order	a owl:DatatypeProperty .
bot:parvclass	a owl:DatatypeProperty .
bot:parvorder	a owl:DatatypeProperty .
bot:pathovar	a owl:DatatypeProperty .
bot:phylum	a owl:DatatypeProperty .
bot:population	a owl:DatatypeProperty .
bot:section	a owl:DatatypeProperty .
bot:sectionOfBreeds	a owl:DatatypeProperty .
bot:series	a owl:DatatypeProperty .
bot:serogroup	a owl:DatatypeProperty .
bot:serovar	a owl:DatatypeProperty .
bot:species	a owl:DatatypeProperty .
bot:speciesGroup	a owl:DatatypeProperty .
bot:speciesSubgroup	a owl:DatatypeProperty .
bot:strain	a owl:DatatypeProperty .
bot:subclass	a owl:DatatypeProperty .
bot:subcohort	a owl:DatatypeProperty .
bot:subdivision	a owl:DatatypeProperty .
bot:subdomain	a owl:DatatypeProperty .
bot:subfamily	a owl:DatatypeProperty .
bot:subfamilyGroup	a owl:DatatypeProperty .
bot:subform	a owl:DatatypeProperty .
bot:subgenus	a owl:DatatypeProperty .
bot:subgroup	a owl:DatatypeProperty .
bot:subkingdom	a owl:DatatypeProperty .
bot:sublegion	a owl:DatatypeProperty .
bot:suborder	a owl:DatatypeProperty .
bot:subphylum	a owl:DatatypeProperty .
bot:subsection	a owl:DatatypeProperty .
bot:subseries	a owl:DatatypeProperty .
bot:subspecies	a owl:DatatypeProperty .
bot:subtribe	a owl:DatatypeProperty .
bot:subvariety	a owl:DatatypeProperty .
bot:superclass	a owl:DatatypeProperty .
bot:supercohort	a owl:DatatypeProperty .
bot:superdomain	a owl:DatatypeProperty .
bot:superfamily	a owl:DatatypeProperty .
bot:superform	a owl:DatatypeProperty .
bot:supergenus	a owl:DatatypeProperty .
bot:superkingdom	a owl:DatatypeProperty .
bot:superlegion	a owl:DatatypeProperty .
bot:superorder	a owl:DatatypeProperty .
bot:superphylum	a owl:DatatypeProperty .
bot:supersection	a owl:DatatypeProperty .
bot:superseries	a owl:DatatypeProperty .
bot:superspecies	a owl:DatatypeProperty .
bot:supertribe	a owl:DatatypeProperty .
bot:supervariety	a owl:DatatypeProperty .
bot:suprakingdom	a owl:DatatypeProperty .
bot:supraphylum	a owl:DatatypeProperty .
bot:synklepton	a owl:DatatypeProperty .
bot:tribe	a owl:DatatypeProperty .
bot:variety	a owl:DatatypeProperty .

# Zoology
zoo:aberration	a owl:DatatypeProperty .
zoo:aggregate	a owl:DatatypeProperty .
zoo:biovar	a owl:DatatypeProperty .
zoo:branch	a owl:DatatypeProperty .
zoo:breed	a owl:DatatypeProperty .
zoo:class	a owl:DatatypeProperty .
zoo:claudius	a owl:DatatypeProperty .
zoo:cohort	a owl:DatatypeProperty .
zoo:complex	a owl:DatatypeProperty .
zoo:convariety	a owl:DatatypeProperty .
zoo:cultivar	a owl:DatatypeProperty .
zoo:cultivarGroup	a owl:DatatypeProperty .
zoo:division	a owl:DatatypeProperty .
zoo:domain	a owl:DatatypeProperty .
zoo:empire	a owl:DatatypeProperty .
zoo:falanx	a owl:DatatypeProperty .
zoo:family	a owl:DatatypeProperty .
zoo:familyGroup	a owl:DatatypeProperty .
zoo:form	a owl:DatatypeProperty .
zoo:genus	a owl:DatatypeProperty .
zoo:genusGroup	a owl:DatatypeProperty .
zoo:gigaorder	a owl:DatatypeProperty .
zoo:grade	a owl:DatatypeProperty .
zoo:grandorder	a owl:DatatypeProperty .
zoo:group	a owl:DatatypeProperty .
zoo:groupOfBreeds	a owl:DatatypeProperty .
zoo:hybrid	a owl:DatatypeProperty .
zoo:hyperorder	a owl:DatatypeProperty .
zoo:infraclass	a owl:DatatypeProperty .
zoo:infradomain	a owl:DatatypeProperty .
zoo:infrafamily	a owl:DatatypeProperty .
zoo:infraform	a owl:DatatypeProperty .
zoo:infragenus	a owl:DatatypeProperty .
zoo:infrakingdom	a owl:DatatypeProperty .
zoo:infralegion	a owl:DatatypeProperty .
zoo:infraorder	a owl:DatatypeProperty .
zoo:infraphylum	a owl:DatatypeProperty .
zoo:infraspecies	a owl:DatatypeProperty .
zoo:infratribe	a owl:DatatypeProperty .
zoo:infravariety	a owl:DatatypeProperty .
zoo:interkingdom	a owl:DatatypeProperty .
zoo:kingdom	a owl:DatatypeProperty .
zoo:klepton	a owl:DatatypeProperty .
zoo:legion	a owl:DatatypeProperty .
zoo:lusus	a owl:DatatypeProperty .
zoo:magnorder	a owl:DatatypeProperty .
zoo:megaorder	a owl:DatatypeProperty .
zoo:microspecies	a owl:DatatypeProperty .
zoo:midkingdom	a owl:DatatypeProperty .
zoo:midphylum	a owl:DatatypeProperty .
zoo:mirorder	a owl:DatatypeProperty .
zoo:nation	a owl:DatatypeProperty .
zoo:order	a owl:DatatypeProperty .
zoo:parvclass	a owl:DatatypeProperty .
zoo:parvorder	a owl:DatatypeProperty .
zoo:pathovar	a owl:DatatypeProperty .
zoo:phylum	a owl:DatatypeProperty .
zoo:population	a owl:DatatypeProperty .
zoo:section	a owl:DatatypeProperty .
zoo:sectionOfBreeds	a owl:DatatypeProperty .
zoo:series	a owl:DatatypeProperty .
zoo:serogroup	a owl:DatatypeProperty .
zoo:serovar	a owl:DatatypeProperty .
zoo:species	a owl:DatatypeProperty .
zoo:speciesGroup	a owl:DatatypeProperty .
zoo:speciesSubgroup	a owl:DatatypeProperty .
zoo:strain	a owl:DatatypeProperty .
zoo:subclass	a owl:DatatypeProperty .
zoo:subcohort	a owl:DatatypeProperty .
zoo:subdivision	a owl:DatatypeProperty .
zoo:subdomain	a owl:DatatypeProperty .
zoo:subfamily	a owl:DatatypeProperty .
zoo:subfamilyGroup	a owl:DatatypeProperty .
zoo:subform	a owl:DatatypeProperty .
zoo:subgenus	a owl:DatatypeProperty .
zoo:subgroup	a owl:DatatypeProperty .
zoo:subkingdom	a owl:DatatypeProperty .
zoo:sublegion	a owl:DatatypeProperty .
zoo:suborder	a owl:DatatypeProperty .
zoo:subphylum	a owl:DatatypeProperty .
zoo:subsection	a owl:DatatypeProperty .
zoo:subseries	a owl:DatatypeProperty .
zoo:subspecies	a owl:DatatypeProperty .
zoo:subtribe	a owl:DatatypeProperty .
zoo:subvariety	a owl:DatatypeProperty .
zoo:superclass	a owl:DatatypeProperty .
zoo:supercohort	a owl:DatatypeProperty .
zoo:superdivision	a owl:DatatypeProperty .
zoo:superdomain	a owl:DatatypeProperty .
zoo:superfamily	a owl:DatatypeProperty .
zoo:superform	a owl:DatatypeProperty .
zoo:supergenus	a owl:DatatypeProperty .
zoo:superkingdom	a owl:DatatypeProperty .
zoo:superlegion	a owl:DatatypeProperty .
zoo:superorder	a owl:DatatypeProperty .
zoo:superphylum	a owl:DatatypeProperty .
zoo:superspecies	a owl:DatatypeProperty .
zoo:supertribe	a owl:DatatypeProperty .
zoo:supervariety	a owl:DatatypeProperty .
zoo:suprakingdom	a owl:DatatypeProperty .
zoo:supraphylum	a owl:DatatypeProperty .
zoo:synklepton	a owl:DatatypeProperty .
zoo:tribe	a owl:DatatypeProperty .
zoo:variety	a owl:DatatypeProperty .
