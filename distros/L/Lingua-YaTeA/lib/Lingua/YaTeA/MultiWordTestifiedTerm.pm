package Lingua::YaTeA::MultiWordTestifiedTerm;
use strict;
use warnings;
use Lingua::YaTeA::TestifiedTerm;
use Lingua::YaTeA::MultiWordUnit;
# use UNIVERSAL;
# use Scalar::Util qw(blessed);
use NEXT;
use base qw(Lingua::YaTeA::TestifiedTerm Lingua::YaTeA::MultiWordPhrase);



our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class_or_object,$words_a,$source,$match_type,$num_content_words,$tag_set) = @_;
    my $this = shift;
    $this = bless {}, $this unless ref $this;
    $this->NEXT::new(@_);
    return $this;
}



sub getIslandType
{
    my ($this) = @_;
    return join(",",@{$this->getSource});
}

sub getIfParsable
{
    my ($this,$parsing_pattern_set,$tag_set,$parsing_direction) = @_;
    if (!defined $this->getForest)
    {
	if($this->searchParsingPattern($parsing_pattern_set,$parsing_direction))
	{
	    $this->setParsingMethod('PATTERN_MATCHING');
	    return 1;
	}
	else
	{
	    if($this->parseProgressively($tag_set,$parsing_direction,$parsing_pattern_set))
	    {
		$this->setParsingMethod('PROGRESSIVE');
		return 1;
	    }
	}
	
    }
    else
    {
	return 1;
    }
    return 0;
}


###################################
# Computation of BioLG-type links #
###################################

sub getHeadAndLinks
{
    my ($this,$LGPmapping_h,$chained_links) = @_;
    my @links;
    if(!defined $this->{FOREST})
    {
	return ($this->getWord($#{$this->getWords}),$#{$this->getWords},\@links);
    }
    else
    {

    }
    my $head = $this->getWord($this->getTree(0)->getHead->getIndex);
    my $left;
    my $right;
    my $prep;
    my $det;
    my $node;
    my $link_key;
    
    my %first;
    my %second;

   
    foreach $node (@{$this->getTree(0)->getNodeSet->getNodes})
    {
	$left = $node->getLeftEdge->searchHead (0);	
	$right = $node->getRightEdge->searchHead (0);	
	$prep = $node->getPreposition;
	$det = $node->getDeterminer;

	if (defined $prep)
	{
	    $link_key = $left->getPOS($this->getWords) . "-" . $prep->getPOS($this->getWords);
	    $this->recordLink($link_key,$left,$prep,\@links,$LGPmapping_h);
	    push @{$first{$left->getIndex}}, $prep->getIndex;
	    push @{$second{$prep->getIndex}}, $left->getIndex;

	    $link_key = $prep->getPOS($this->getWords) . "-" . $right->getPOS($this->getWords);
	    $this->recordLink($link_key,$prep,$right,\@links,$LGPmapping_h);
	    push @{$first{$prep->getIndex}}, $right->getIndex;
	    push @{$second{$right->getIndex}}, $prep->getIndex;
	}
	else
	{
	    $link_key = $left->getPOS($this->getWords) . "-" . $right->getPOS($this->getWords);
	    $this->recordLink($link_key,$left,$right,\@links,$LGPmapping_h);
	    push @{$first{$left->getIndex}}, $right->getIndex;
	    push @{$second{$right->getIndex}}, $left->getIndex;
	}

	if (defined $det)
	{
	    $link_key = $det->getPOS($this->getWords) . "-" . $right->getPOS($this->getWords);
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
    return ($this->getWord($this->getTree(0)->getHead->getIndex),$this->getTree(0)->getHead->getIndex,\@links);
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
	die "Pas de mapping pour " . $link_key .  " (" .$this->getIF . ")\n";
    }
}

sub setForest
{
    my ($this,$bracketed_parse) = @_;
    print STDERR $bracketed_parse . "\n";
}


1;

__END__

=head1 NAME

Lingua::YaTeA::MultiWordTestifiedTerm - Perl extension for multi-word testified terms

=head1 SYNOPSIS

  use Lingua::YaTeA::MultiWordTestifiedTerm;
  Lingua::YaTeA::MultiWordTestifiedTerm->new($words, $match_type, $num_content_words, $tag_set);

=head1 DESCRIPTION

The module implements a representation of the multi-word testified
terms, i.e. terms from a terminological resource. Those testified
terms are used to find corresponding terms in the corpus. Each
multi-word testified term inherits from the class
C<Lingua::YaTeA::MultiWordUnit>.


=head1 METHODS


=head2 new()

    new($words, $match_type, $num_content_words, $tag_set);

This method creates a new object representing a multi-wordtestified
term. C<$words_a> and C<$tag_set> are used to initialise the
lignuistic information (C<IF>, C<POS>, C<LF>). C<$source> initialises
the original terminology. C<$mach_type> defines the type of matching
for finding the terms in the corpus.


=head2 getIslandType()

    getIslandType();

The method returns the type of island correspoding to the multi-word
testified terms, in that case the original terminology.


=head2 getIfParsable()

    getIfParsable($parsing_pattern_set,$tag_set,$parsing_direction);

The method indicates if the mutli-word testitied term is parsable of
not according to one of the parsing patterns C<$parsing_pattern_set>
(and given a parsing direction C<$parsing_direction>), the
Part-of-Speech tags C<$tag_set>.

=head2 getHeadAndLinks()

    getHeadAndLinks($LGPmapping_h,$chained_links);

This method computes syntactic relations in the BioLG way (see
http://mars.cs.utu.fi/biolg/).

=head2 chainLinks()

    chainLinks($links_a);

The method is related to the output in the BioLG way. 

=head2 getLinksSets()

    getLinksSets($links_a);

The method is related to the output in the BioLG way. 

=head2 sortLinks()

    sortLinks($link1,$link2);

The method is related to the output in the BioLG way. 

=head2 adjustLinksHeight()

    adjustLinksHeight($links_a,$first_h,$second_h);

The method is related to the output in the BioLG way. 

=head2 recordLink()

    recordLink($link_key,$first_element,$second_element,$links_a,$LGPmapping_h);

The method is related to the output in the BioLG way. 

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
