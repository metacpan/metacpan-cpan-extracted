package Lingua::YaTeA::MultiWordTermCandidate;
use strict;
use warnings;
use Lingua::YaTeA::TermCandidate;
use Lingua::YaTeA::IndexSet;
use Data::Dumper;

use UNIVERSAL;
use Scalar::Util qw(blessed);

our @ISA = qw(Lingua::YaTeA::TermCandidate);
our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class) = @_;
    my $this = $class->SUPER::new;
  
    $this->{ROOT_HEAD} = ();
    $this->{ROOT_MODIFIER} = ();
    $this->{PREPOSITION} = ();
    $this->{DETERMINER} = ();
    $this->{MODIFIER_POSITION} = ();
    $this->{INDEX_SET} = Lingua::YaTeA::IndexSet->new;
    $this->{ISLANDS} = [];
    $this->{ISLAND_TYPE} = ();
    bless ($this,$class);
    return $this;
}

sub getRootHead
{
    my ($this) = @_;
    return $this->{ROOT_HEAD};
}

sub getIslandType
{
    my ($this) = @_;
    return $this->{ISLAND_TYPE};
}

sub getPreposition
{
    my ($this) = @_;
    return $this->{PREPOSITION};
}

sub getDeterminer
{
    my ($this) = @_;
    return $this->{DETERMINER};
}

sub getRootModifier
{
    my ($this) = @_;
    return $this->{ROOT_MODIFIER};
}

sub getModifierPosition
{
    my ($this) = @_;
    return $this->{MODIFIER_POSITION};
}

sub searchHead
{
    my ($this, $depth) = @_;
    my $head;

	    $depth++;

    # warn "REF: " . ref($this->getRootHead) . "\n";
    # warn "BLESSED: " . blessed($this->getRootHead) . "\n";
    if ((blessed($this->getRootHead)) && ($this->getRootHead->isa('Lingua::YaTeA::MonolexicalTermCandidate')))
    {
	$head = $this->getRootHead;	 
    }
    else
    {
	if ($depth < 40) {
	    $head = $this->getRootHead->searchHead ($depth);
	}
    }
    return $head;
}

sub setOccurrences
{
    my ($this,$phrase_occurrences_a,$offset,$maximal) = @_;
    my $phrase_occurrence;

    if($maximal == 1)
    {
	$this->{OCCURRENCES} = $phrase_occurrences_a;
	$this->{MNP_STATUS} = 1;
    }
    else
    {
	foreach $phrase_occurrence (@$phrase_occurrences_a)
	{
	    my $occurrence = Lingua::YaTeA::Occurrence->new;
	    $occurrence->{SENTENCE} =  $phrase_occurrence->getSentence;
	    $occurrence->{START_CHAR} = $phrase_occurrence->getStartChar + $offset;
	    $occurrence->{MAXIMAL} = 0;
	    $this->addOccurrence($occurrence);
	}
    }
}

sub completeOccurrences
{
    my ($this,$offset) = @_;
    my $occurrence;

#     print STDERR "---> " . $this->getID() . "\n";

    foreach $occurrence (@{$this->getOccurrences})
    {
# 	print STDERR $occurrence->{ID} . "\n";
# 	print STDERR $occurrence->{START_CHAR} . "\n";

	$occurrence->{END_CHAR} = $occurrence->getStartChar  + $offset - 1; #  + $offset 
# 	print STDERR $occurrence->{END_CHAR} . "\n";
    }
}

sub getIndexSet
{
    my ($this) = @_;
    return $this->{INDEX_SET};
}

sub addIndexSet
{
    my ($this,$index_set_to_add) = @_;
    $this->getIndexSet->mergeWith($index_set_to_add);
}


sub setIslands
{
    my ($this,$phrase_island_set,$left,$right) = @_;
    my $island;
    
    if((defined $phrase_island_set)
        &&
        ($phrase_island_set->size != 0)
 	)
    {
	foreach $island (values (%{$phrase_island_set->getIslands}))
	{
	    if($this->getIndexSet->contains($island->getIndexSet))
	    {
		# islands are recorded
		if
		    (
		     # if they are exogenous
		     ($island->getType ne 'endogenous' ) 
		     ||
		     # if they are endogenous and don't cover the full TC
		     ($this->getIndexSet->joinAll('-') ne $island->getIndexSet->joinAll('-'))
		    )
		{
		    $this->addIsland($island);
		}
	    }
	}
    }
}

sub addIsland
{
    my ($this,$island) = @_;
    
    push @{$this->getIslands}, $island;
}

sub adjustIslandReferences
{
    my ($this,$mapping_from_phrases_to_TCs_h) = @_;
    my $island;
    my $type;

    foreach $island (@{$this->getIslands})
    {
	$type = $island->getType;

	if
	    ($type eq 'endogenous')
	{
	    if(exists $mapping_from_phrases_to_TCs_h->{$island->getSource->getID})
	    {
		
		# the island is no longer linked to a phrase: it is now linked to a term candidate
		$island = $mapping_from_phrases_to_TCs_h->{$island->getSource->getID};
	    }
	    else
	    {
		die "y a  un blem\n";
	    }
	}
	else
	{
	    $island =  $island->getSource;
	} 
	$island->{ISLAND_TYPE} = $type;
    }
}



sub getIslands
{
    my ($this) = @_;
    return $this->{ISLANDS};
}



sub containsIslands
{
    my ($this) = @_;
    if(scalar @{$this->getIslands} > 0)
    {
	return 1;
    }
    return 0;
}

sub getHeadAndLinks
{
    my ($this,$LGPmapping_h,$chained_links) = @_;
    my $phrase = $this->getOriginalPhrase;
    my $head = $phrase->getWord($phrase->getTree(0)->getHead->getIndex);
    my $left;
    my $right;
    my $prep;
    my $det;
    my $node;
    my $link_key;
    my @links;
    my %first;
    my %second;

    
    foreach $node (@{$phrase->getTree(0)->getNodeSet->getNodes})
    {
	$left = $node->getLeftEdge->searchHead (0);	
	$right = $node->getRightEdge->searchHead (0);	
	$prep = $node->getPreposition;
	$det = $node->getDeterminer;

	if (defined $prep)
	{
	    $link_key = $left->getPOS($phrase->getWords) . "-" . $prep->getPOS($phrase->getWords);
	    $this->recordLink($link_key,$left,$prep,\@links,$LGPmapping_h);
	    push @{$first{$left->getIndex}}, $prep->getIndex;
	    push @{$second{$prep->getIndex}}, $left->getIndex;

	    $link_key = $prep->getPOS($phrase->getWords) . "-" . $right->getPOS($phrase->getWords);
	    $this->recordLink($link_key,$prep,$right,\@links,$LGPmapping_h);
	    push @{$first{$prep->getIndex}}, $right->getIndex;
	    push @{$second{$right->getIndex}}, $prep->getIndex;
	}
	else
	{
	    $link_key = $left->getPOS($phrase->getWords) . "-" . $right->getPOS($phrase->getWords);
	    $this->recordLink($link_key,$left,$right,\@links,$LGPmapping_h);
	    push @{$first{$left->getIndex}}, $right->getIndex;
	    push @{$second{$right->getIndex}}, $left->getIndex;
	}

	if (defined $det)
	{
	    $link_key = $det->getPOS($phrase->getWords) . "-" . $right->getPOS($phrase->getWords);
	    $this->recordLink($link_key,$det,$right,\@links,$LGPmapping_h);
	    push @{$first{$det->getIndex}}, $right->getIndex;
	    push @{$second{$right->getIndex}}, $det->getIndex;
	}
    }
    $this->adjustLinksHeight(\@links,\%first,\%second);
    @links = sort{$this->sortLinks($a,$b)} @links;
    if($chained_links  == 1)
    {
	$this->chainLinks(\@links);
    }
    return ($phrase->getWord($phrase->getTree(0)->getHead->getIndex),$phrase->getTree(0)->getHead->getIndex,\@links);
}

sub chainLinks
{
    my ($this,$links_a) = @_;
    my $link;
    my $links_sets_h = $this->getLinksSets($links_a);
    my @chained_links;
    my $set_a;
    my $left;
    my $right;
    my $height;
    my $type;
    my $i;
    my $search;
    my %recorded;
    my $updated_height;
    my $previous_right;
    foreach $set_a (values (%$links_sets_h))
    {
	if(scalar @$set_a > 1)
	{
	    while ( $link = pop @$set_a)
	    {
		$link =~ /\[([0-9]+) ([0-9]+) ([0-9]+) \(([^\)]+)\)\]/;
		$left = $1;
		$right = $2;
		$height = $3;
		$type = $4;
		if($type eq "CH")
		{
		    if($left < $right -1)
		    {
			$updated_height = 0;
			for ($i= $left+1; $i < $right; $i++)
			{
			    if(!defined $previous_right)
			    {
				$previous_right = $right;
			    }
			    $search = $i . " " . $previous_right ;
			     
			    if(exists $recorded{$search})
			    {
				    $right = $i;
				    $height = $updated_height;
				    last;
			    }
			    else
			    {
				$updated_height++;
			    }
			}
		    }
		    $recorded{$left . " " . $right}++;
		    $previous_right = $right;
		    $link = "[". $left . " " . $right . " " . $height . " (" . $type . ")]";
		}
		push @chained_links, $link;
	    }
	}
	else
	{
	    push @chained_links, @$set_a;
	}
    }
    @$links_a = sort{$this->sortLinks($a,$b)} @chained_links;
}

sub getLinksSets
{
    my ($this,$links_a) = @_;
    my %sets;
    my $link;
    foreach $link (@$links_a){
	$link =~ /\[([0-9]+) ([0-9]+) ([0-9]+) (\([^\)]+\)\])/;
	push @{$sets{$2}}, $link;
    }
    return \%sets;
}


sub sortLinks
{
    my ($this,$link1,$link2) = @_;
    my $first_element_of_link1;
    my $second_element_of_link1;
    my $first_element_of_link2;
    my $second_element_of_link2;

    $link1 =~ /\[([0-9]+) ([0-9]+) ([0-9]+) (\([^\)]+\)\])/;
    $first_element_of_link1 = $1;
    $second_element_of_link1 = $2;
    $link2 =~ /\[([0-9]+) ([0-9]+) ([0-9]+) (\([^\)]+\)\])/;
    $first_element_of_link2 = $1;
    $second_element_of_link2 = $2;

    if ($first_element_of_link1 != $first_element_of_link2){
	return ($first_element_of_link1 <=> $first_element_of_link2);
    }
    return ($second_element_of_link1 <=> $second_element_of_link2);
}

sub adjustLinksHeight
{
    my ($this,$links_a,$first_h,$second_h)  = @_;
    my $link;
    my $first_word;
    my $second_word;
    my $link_tag;
    my $height;
    my $first_word_of_other_link;
    my $second_word_of_other_link;

    if(scalar @$links_a > 1)
    {
	foreach $link (@$links_a){
	    $link =~ /\[([0-9]+) ([0-9]+) ([0-9]+) (\([^\)]+\)\])/;
	    $first_word = $1;
	    $second_word = $2;
	    $height = $3;
	    $link_tag = $4;
	    if(exists $first_h->{$first_word}){
		foreach $second_word_of_other_link (@{$first_h->{$first_word}}){
		    if($second_word_of_other_link < $second_word){
			$height++;
		    }
		}
	    }
	    if(exists $second_h->{$second_word}){
		foreach $first_word_of_other_link (@{$second_h->{$second_word}}){
		    if($first_word_of_other_link > $first_word){
			$height++;
		    }
		}
	    }
	    $link = "[".$first_word . " " . $second_word . " " .$height . " " . $link_tag;
	}
    }
}

sub recordLink
{
    my ($this,$link_key,$first_element,$second_element,$links_a,$LGPmapping_h) = @_;
    my $LGP_link;
    my %first_items;
    my %second_items;
    
    if(exists $LGPmapping_h->{$link_key}){
	$LGP_link = "[" .$first_element->getIndex . " " . $second_element->getIndex . " 0 (" .$LGPmapping_h->{$link_key} . ")]";
	push @$links_a, $LGP_link;
    }
    else{
	warn "Pas de mapping pour " . $link_key .  " (" .$this->getIF . ")\n";
    }
}


1;

__END__

=head1 NAME

Lingua::YaTeA::MultiWordTermCandidate - Perl extension for ???

=head1 SYNOPSIS

  use Lingua::YaTeA::MultiWordTermCandidate;
  Lingua::YaTeA::MultiWordTermCandidate->();

=head1 DESCRIPTION


=head1 METHODS


=head2 new()


=head2 getRootHead()


=head2 getIslandType()


=head2 getPreposition()


=head2 getDeterminer()


=head2 getRootModifier()


=head2 getModifierPosition()


=head2 searchHead()


=head2 setOccurrences()


=head2 completeOccurrences()


=head2 getIndexSet()


=head2 addIndexSet()


=head2 setIslands()


=head2 addIsland()


=head2 adjustIslandReferences()


=head2 getIslands()


=head2 containsIslands()


=head2 getHeadAndLinks()


=head2 chainLinks()


=head2 getLinksSets()


=head2 sortLinks()


=head2 adjustLinksHeight()


=head2 recordLink()


=head1 SEE ALSO

Sophie Aubin and Thierry Hamon. Improving Term Extraction with
Terminological Resources. In Advances in Natural Language Processing
(5th International Conference on NLP, FinTAL 2006). pages
380-387. Tapio Salakoski, Filip Ginter, Sampo Pyysalo, Tapio Pahikkala
(Eds). August 2006. LNAI 4139.


=head1 AUTHOR

Thierry Hamon <thierry.hamon@univ-paris13.fr> and Sophie Aubin <sophie.aubin@lipn.univ-paris13.fr>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Thierry Hamon and Sophie Aubin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
