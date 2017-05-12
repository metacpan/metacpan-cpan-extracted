package Lingua::YaTeA::MultiWordUnit;
use strict;
use warnings;
use NEXT;
use Data::Dumper;
use UNIVERSAL;
use Scalar::Util qw(blessed);
use Lingua::YaTeA::MultiWordPhrase;

our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class_or_object,$num_content_words,$words_a) = @_;
    my $this = shift;
    $this = bless {}, $this unless ref $this;
    $this->{FOREST} = ();
    $this->{CONTENT_WORDS} = $num_content_words;
    $this->{PARSING_METHOD} = ();
    $this->{LENGTH} = scalar @$words_a;
    $this->NEXT::new(@_);
    return $this;
}



sub getContentWordNumber
{
    my ($this) = @_;
    return $this->{CONTENT_WORDS};
}

sub getLength
{
    my ($this) = @_;
    return $this->{LENGTH};
}

sub addTree
{
    my ($this,$tree) = @_;
    push @{$this->{FOREST}}, $tree;
}

sub getForest
{
    my ($this) = @_;
    return $this->{FOREST};
} 

sub forestSize
{
    my ($this) = @_;
    return scalar @{$this->getForest};
}

sub emptyForest
{
    my ($this) = @_;
    @{$this->getForest} = ();
}

sub getTree
{
    my ($this,$index) = @_;
    return $this->getForest->[$index];
}


sub exportNodeSets
{
    my ($this) = @_;
    my $tree;
    my @node_sets;
    foreach $tree (@{$this->getForest})
    {
	push @node_sets, $tree->getNodeSet->copy;
    }
    return \@node_sets;
}


sub searchParsingPattern
{
    my ($this,$parsing_pattern_set,$tag_set,$parsing_direction) = @_;
    my $record;
    my $simplified_pos;
    my $tree;

  #   if ($this->{CONTENT_WORDS} <= $Lingua::YaTeA::ParsingPatternRecordSet::max_content_words)  # commented by SA: limite l'analyse le terme a deja ete simplifie par un ilot
#     {
	
	if(!defined $this->getForest)
	{
	    if ($record = $parsing_pattern_set->existRecord($this->getPOS))
	    {
		return $this->getParseFromPattern($record,$tag_set);
	    }
	    return;
	}
	# exogenous islands were found (used for Phrases only)
	else
	{
	    foreach $tree (@{$this->getForest})
	    {
		$simplified_pos = $tree->getSimplifiedIndexSet->buildPOSSequence($this->getWords,$tag_set);
		
		if ($record = $parsing_pattern_set->existRecord($simplified_pos))
		{
		    return $this->getParseFromPattern($record,$parsing_direction,$tag_set);
		}
	    }
	}
    #}
    return;
}


sub getParseFromPattern
{
    my ($this,$pattern_record,$parsing_direction,$tag_set) = @_;
    my $pattern;
    my $node_set;
    my $tree;
    my @concurrent_trees;
    my $parsed = 0;
    
    if(
	(defined $this->{FOREST})
	&& 
	($this->forestSize > 0)
	)
    {
	$pattern = $this->chooseBestPattern($pattern_record->{PARSING_PATTERNS},$parsing_direction);
	foreach $tree (@{$this->{FOREST}})
	 {
	     $node_set = $pattern->getNodeSet->copy;
	     $node_set->fillNodeLeaves($tree->getSimplifiedIndexSet);

	     if($tree->append($node_set,$tree->getSimplifiedIndexSet,\@concurrent_trees,$this->getWords,$tag_set) == 1)
	     {
		 $tree->setHead;
		 $parsed = 1;
	     }
	 }
     }
     else 
     {
	 foreach $pattern (@{$pattern_record->{PARSING_PATTERNS}})
	 {
	     $tree = Lingua::YaTeA::Tree->new;
	     $tree->{INDEX_SET} = $this->getIndexSet;
	     $tree->{NODE_SET} = $pattern->getNodeSet->copy;
	     $tree->fillNodeLeaves;
	     
	     if($tree->check($this))
	     {
		 $tree->setReliability(1);
		 $tree->setHead;
		 $this->addTree($tree);
		 $parsed = 1;
	     }
	 }
     }
    return $parsed;
}



sub getPartialPattern
{
   my ($this,$simplified_index_set,$tag_set,$parsing_direction,$parsing_pattern_set,$fh) = @_;
   my $pattern;
   my $position;
   my $POS  = $simplified_index_set->buildPOSSequence($this->getWords,$tag_set);
#   print $fh "pos: ". $POS . "\n";
   if($parsing_direction eq "LEFT")
   {
       ($pattern,$position) = $this->getPatternsLeftFirst($POS,$parsing_pattern_set,$parsing_direction);
   }
   else{
       ($pattern,$position) = $this->getPatternsRightFirst($POS,$parsing_pattern_set,$parsing_direction);
   }
   return ($pattern,$position);
}


sub getPatternsLeftFirst
{
    my ($this,$POS,$parsing_pattern_set,$parsing_direction) = @_;
    my $pattern;
    my $position = "LEFT";
    $pattern = $this->getPatternOnTheLeft($POS,$parsing_pattern_set,$parsing_direction);
    if (!((blessed($pattern)) && ($pattern->isa('Lingua::YaTeA::ParsingPattern')))) {
	$pattern = $this->getPatternOnTheRight($POS,$parsing_pattern_set,$parsing_direction);
	$position = "RIGHT";
    }
    return ($pattern,$position);
}

sub getPatternsRightFirst
{
    my ($this,$POS,$parsing_pattern_set,$parsing_direction) = @_;
    my $pattern;
    my $position = "RIGHT";
  
    $pattern = $this->getPatternOnTheRight($POS,$parsing_pattern_set,$parsing_direction);
    if (!((blessed($pattern)) && ($pattern->isa('Lingua::YaTeA::ParsingPattern'))))
    {
	$pattern = $this->getPatternOnTheLeft($POS,$parsing_pattern_set,$parsing_direction);
	$position = "LEFT";
    }
    return ($pattern,$position);
}

sub getPatternOnTheLeft
{
    my ($this,$POS,$parsing_pattern_set,$parsing_direction) = @_;
    my @selection;
    my $key;
    my $record;
    my $pattern;
    my $bounded_key;
    my $qm_key;
    my $bounded_POS = "-" . $POS . "-";
    $bounded_POS =~ s/ /-/g;
    while (($key,$record) = each %{$parsing_pattern_set->getRecordSet})
    {
	$bounded_key = "-" . $key . "-";
	$bounded_key =~ s/ /-/g;
	$qm_key = quotemeta($bounded_key);
	if ($bounded_POS =~ /^$qm_key/)
	{
	    foreach $pattern (@{$record->getPatterns})
	    {
		push @selection, $pattern;
	    }
	}
    }
    $pattern = $this->chooseBestPattern(\@selection,$parsing_direction);
    return $pattern;
}

sub getPatternOnTheRight
{
    my ($this,$POS,$parsing_pattern_set,$parsing_direction) = @_;
    my @selection;
    my $key;
    my $record;
    my $pattern;
    my $bounded_key;
    my $qm_key;
    
    my $bounded_POS = "-" . $POS . "-";
    $bounded_POS =~ s/ /-/g;
    while (($key,$record) = each %{$parsing_pattern_set->getRecordSet})
    {
	$bounded_key = "-" . $key . "-";
	$bounded_key =~ s/ /-/g;
	$qm_key = quotemeta($bounded_key);
	if ($bounded_POS =~ /$qm_key$/)
	{
	    foreach $pattern (@{$record->getPatterns})
	    {
		push @selection, $pattern;
	    }
	}
    }
    $pattern = $this->chooseBestPattern(\@selection,$parsing_direction);
    return $pattern;
}




sub chooseBestPattern
{
    my ($this,$patterns_a,$parsing_direction) = @_;
    
    my @tmp = sort {$this->sortPatternsByPriority($a,$b,$parsing_direction)} @$patterns_a;
  
    my @sorted = @tmp;

    return $sorted[0];
}

sub sortPatternsByPriority
{
    my ($this,$first,$second,$parsing_direction) = @_;

    if($first->getDirection eq $parsing_direction)
    {
	if($second->getDirection eq $parsing_direction)
	{
	    if($first->getNumContentWords > $second->getNumContentWords)
	    {
		return -1;
	    }
	    else
	    {
		if($first->getNumContentWords < $second->getNumContentWords)
		{
		    return 1;
		}
		else
		{
		    return ($second->getPriority <=> $first->getPriority);
		}
	    }
	}
	else
	{
	    return -1;
	}
    }
    else
    {
	if($second->getDirection eq $parsing_direction)
	{
	    return 1;
	}
	else
	{
	    if($first->getNumContentWords > $second->getNumContentWords)
	    {
		return -1;
	    }
	    else
	    {
		if($first->getNumContentWords < $second->getNumContentWords)
		{
		    return 1;
		}
		else
		{
		    return ($second->getPriority <=> $first->getPriority);
		}
	    }
	}
    }
}


sub setParsingMethod
{
    my ($this,$method) = @_;
    if ((blessed($this)) && ($this->isa('Lingua::YaTeA::Phrase')))
    {
	$Lingua::YaTeA::MultiWordPhrase::parsed++;
    }
    $this->{PARSING_METHOD} = $method;
}


sub getParsingMethod
{
    my ($this) = @_;
    if(defined $this->{PARSING_METHOD})
    {
	return $this->{PARSING_METHOD};
    }
    else
    {
	return "UNPARSED";
    }
}


sub parseProgressively
{
    my ($this,$tag_set,$parsing_direction,$parsing_pattern_set, $fh) = @_;
    my $tree;
    my $pattern;
    my $position;
    my $partial_index_set;
    my $node_set;
    my @concurrent_trees;
    my $parsed = 0;
    
#    print $fh "parseProgressively\n";
#     print $fh $this->getIF . "\n";

    if(!defined $this->getForest)
    {
	$tree = Lingua::YaTeA::Tree->new;
	$tree->setSimplifiedIndexSet($this->getIndexSet);
	push @concurrent_trees, $tree;
    }
    else
    {
	@concurrent_trees = @{$this->getForest};
	# print $fh scalar  @concurrent_trees . " arbres\n";
	$this->emptyForest;
    }
    while (scalar @concurrent_trees != 0)
    {
	foreach ($tree = pop (@concurrent_trees))
	{
#	    print $fh "TREE parse\n";
#	    $tree->print($this->getWords,$fh);
	    if($tree->getSimplifiedIndexSet->getSize == 1)
	    {
		if($tree->check($this))
		{
		    $parsed = 1;
		    $tree->setHead;
		    $tree->setReliability(2);
		    $this->addTree($tree);
		}
	    }
	    else
	    {
#		$tree->getSimplifiedIndexSet->print($fh);
#		print $fh "\n";
		($pattern,$position) = $this->getPartialPattern($tree->getSimplifiedIndexSet,$tag_set,$parsing_direction,$parsing_pattern_set,$fh);
#		$tree->getSimplifiedIndexSet->print($fh);
		if ((blessed($pattern)) && ($pattern->isa('Lingua::YaTeA::ParsingPattern'))) {
#		    print $fh "trouve partial pattern\n";
		    $partial_index_set = $tree->getSimplifiedIndexSet->getPartial($pattern->getLength,$position);
		    $node_set = $pattern->getNodeSet->copy;
		    $node_set->fillNodeLeaves($partial_index_set);
		     
		    if ($tree->append($node_set,$partial_index_set,\@concurrent_trees,$this->getWords,$tag_set,$fh) == -1) {
#			print $fh "termine append avec -1\n";
			return 0;
		    }
		}
		else
		{
		    next; 
		}
	    }
	}
    }
    #$this->printDebug($fh);
    return $parsed;
}




sub printForest
{
    my ($this,$fh) = @_;
    my $tree;
#    print "FOREST\n";
    if(defined $this->getForest)
    {
	#print "Taille de la foret: " . $this->forestSize . "\n";
	foreach $tree (@{$this->getForest})
	{
	    $tree->print($this->getWords,$fh);
	}
    }
    else
    {
	print  "Pas d'analyse\n";
    }
}


sub printForestParenthesised
{
    my ($this,$fh) = @_;
    my $tree;
    my $tree_counter = 1;
    
    if(defined $fh)
    {
	if(defined $this->getForest)
	{
	    print $fh " number of trees: " . scalar @{$this->getForest} . "\n";
	    foreach $tree (@{$this->getForest})
	    {
#	    print STDERR "$tree\n";
		print $fh "\tT" . $tree_counter++ .": ";
		$tree->printParenthesised($this->getWords,$fh);
	    }
	}
	else
	{
	    print $fh "Pas d'analyse\n";
	}
    }
    else
    {
	if(defined $this->getForest)
	{
	    print " : number of trees" . scalar @{$this->getForest} . "\n";
	    foreach $tree (@{$this->getForest})
	    {
		$tree->printParenthesised($this->getWords);
	    }
	}
	else
	{
	    print "Pas d'analyse\n";
	}
    }
}

sub printDebug
{
    my ($this, $fh) = @_;

    print $fh "\n\n";
    print $fh "$this\n";
    print $fh $this->{'IF'} . "\n";
    $this->print($fh);
    $this->printForestParenthesised($fh);
    print $fh "\n\n";

}


1;

__END__

=head1 NAME

Lingua::YaTeA::MultiWordUnit - Perl extension for ???

=head1 SYNOPSIS

  use Lingua::YaTeA::MultiWordUnit;
  Lingua::YaTeA::MultiWordUnit->();

=head1 DESCRIPTION


=head1 METHODS

=head2 new()


=head2 getContentWordNumber()


=head2 getLength()


=head2 addTree()


=head2 getForest()


=head2 forestSize()


=head2 emptyForest()


=head2 getTree()


=head2 exportNodeSets()


=head2 searchParsingPattern()


=head2 getParseFromPattern()


=head2 getPartialPattern()


=head2 getPatternsLeftFirst()


=head2 getPatternsRightFirst()


=head2 getPatternOnTheLeft()


=head2 getPatternOnTheRight()


=head2 chooseBestPattern()


=head2 sortPatternsByPriority()


=head2 setParsingMethod()


=head2 getParsingMethod()


=head2 parseProgressively()


=head2 printForest()


=head2 printForestParenthesised()



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
