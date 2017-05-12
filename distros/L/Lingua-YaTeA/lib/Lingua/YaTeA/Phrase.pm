package Lingua::YaTeA::Phrase;
use strict;
use warnings;
use Lingua::YaTeA::Occurrence;
use Lingua::YaTeA::Island;
use Lingua::YaTeA::IslandSet;
use NEXT;
use UNIVERSAL;
use Scalar::Util qw(blessed);

use Data::Dumper;
our $counter = 0;

our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class_or_object,$num_content_words,$words_a,$tag_set) = @_;
    my $this = shift;
    $this = bless {}, $this unless ref $this;
    $this->{ID} = $counter;
    $this->{WORDS} = [];
    $this->{IF} = "";
    $this->{POS} = "";
    $this->{LF} = "";
    $this->{TC} = 0;
    $this->{FREQUENCY} = 0;
    $this->{OCCURRENCES} = [];
    $this->{RELIABILITY} = 0;
    $this->{TESTIFIED_TERMS} = ();
    $this->{INDEX_SET} = Lingua::YaTeA::IndexSet->new;
   
    $this->buildLinguisticInfos($words_a,$tag_set);
    $this->getIndexSet->fill($words_a);
    $this->NEXT::new(@_);
    
    return $this;
}


sub setTC
{
    my ($this,$status) = @_;
    $this->{TC} = $status;
}



sub buildLinguisticInfos
{
    my ($this,$words_a,$tag_set) = @_;
    my $word;
    my $lex;
    my $IF;
    my $POS;
    my $LF;
    my %prep = ("of"=>"of", "to"=>"to");
    
    foreach $word (@$words_a)
    {
	if ((blessed($word)) && ($word->isa("Lingua::YaTeA::WordFromCorpus")))
	{
	    $lex  = $word->getLexItem;
	    $IF .= $lex->getIF . " " ;
	    if ($tag_set->existTag('PREPOSITIONS',$lex->getIF))
	    {
		$POS .= $lex->getIF . " ";
	    }
	    else
	    {
		$POS .= $lex->getPOS . " ";
	    }
	    $LF .= $lex->getLF . " " ;
	    push @{$this->getWords}, $lex;
	}
	else
	{ # update existing linguistic info for a phrase
	    if((blessed($word)) && ($word->isa("Lingua::YaTeA::LexiconItem")))
	    {
		$IF .= $word->getIF . " " ;
		if ($tag_set->existTag('PREPOSITIONS',$word->getIF))
		{
		    $POS .= $word->getIF . " ";
		}
		else
		{
		    $POS .= $word->getPOS . " ";
		}
		$LF .= $word->getLF . " " ;
	    }
	    
	}
    }
    $IF =~ s/\s+$//o;
    $POS =~ s/\s+$//o;
    $LF =~ s/\s+$//o;
    $this->setIF($IF);
    $this->setPOS($POS);
    $this->setLF($LF);
}



sub addOccurrence
{
    my ($this,$words_a,$maximal,$fh) = @_;
    my $testified;
    my $testified_set_a;
    my $key;
    $this->incrementFrequency;
    my $occurrence = Lingua::YaTeA::Occurrence->new;
    $occurrence->setInfoForPhrase($words_a,$maximal);
    push @{$this->{OCCURRENCES}}, $occurrence; 
    if(defined $this->getTestifiedTerms)
    {
	while (($key,$testified_set_a) = each %{$this->getTestifiedTerms})
	{
	    foreach $testified (@{$testified_set_a})
	    {
		$testified->addOccurrence($occurrence,$this,$key,$fh);
	    }
	}
    }
}



sub incrementFrequency
{
    my ($this) = @_;
    $this->{FREQUENCY}++;
}

sub getWords
{
    my ($this) = @_;
    return $this->{WORDS};
}

sub setIF
{
    my ($this,$new) = @_;
    $this->{IF} = $new;
}

sub setPOS
{
    my ($this,$new) = @_;
    $this->{POS} = $new;
}

sub setLF
{
    my ($this,$new) = @_;
    $this->{LF} = $new;
}

sub getIF
{
    my ($this) = @_;
    return $this->{IF};
}

sub getPOS
{
    my ($this) = @_;
    return $this->{POS};
}

sub getLF
{
    my ($this) = @_;
    return $this->{LF};
}

sub buildKey
{
    my ($this) = @_;
    my $key = $this->{"IF"} . "~" . $this->{"POS"} . "~" . $this->{"LF"};
    return $key;
}


sub getWord
{
    my ($this,$index) = @_;
    return $this->getWords->[$index];

}

sub isTC
{
    my ($this) = @_;
    return $this->{TC};
}

sub getFrequency
{
    my ($this) = @_;
    return $this->{FREQUENCY};
}

sub getOccurrences
{
    my ($this) = @_;
    return $this->{OCCURRENCES};
}

sub addTermCandidates
{
    my ($this,$term_candidates_h,$mapping_from_phrases_to_TCs_h,$tc_max_length,$option_set,$phrase_set,$monolexical_transfer_h) = @_;
    my @term_candidates;
    my $tc;
    my $reference;
    my $occurrence;
    my $max_tc;
    my $mono;
    my $offset = 0;
    
   
    if ((blessed($this)) && ($this->isa('Lingua::YaTeA::MultiWordPhrase')))
    {
	$max_tc = $this->getTree(0)->getRoot->buildTermList(\@term_candidates,$this->getWords,$this->getOccurrences,$this->getIslandSet,\$offset,1);
    }
    else
    {
	$mono =  Lingua::YaTeA::MonolexicalTermCandidate->new;
	$mono->editKey("( " . $this->getWord(0)->getIF."<=S=".$this->getWord(0)->getPOS . "=" . $this->getWord(0)->getLF. "> )");
	push @{$mono->getWords},$this->getWord(0);

	$mono->setOccurrences($this->getOccurrences,$offset,$this->getWord(0)->getLength,1);
	push @term_candidates, $mono;
	$max_tc = $mono;
    }
    
    @term_candidates = sort ({$a->getLength <=> $b->getLength} @term_candidates);
   foreach $tc (@term_candidates)
   {
       #print STDERR $tc->getIF . " : " .$tc->getLength . " -> ";
       if($tc->getLength < $tc_max_length)
       {
	   #print STDERR " ajoute \n";
	   $tc->{ORIGINAL_PHRASE} = $this;
	   if(!exists $term_candidates_h->{$tc->getKey})
	   {	   
	       $tc->setHead;
	       # TODO: change the criteria for the relevance of the term
	       # currently: a tc receives the confidence rate of the groupe for which it is extracted
	       if ((blessed($this)) && ($this->isa('Lingua::YaTeA::MultiWordTermCandidate')))
	       {
		   $tc->setReliability($this->getTree(0)->getReliability);
	       }
	       else
	       {
		   $tc->setReliability(0.5);
	       }
	       $term_candidates_h->{$tc->getKey} = $tc;
	       $reference = $tc;
	       
	       
# Correction Sophie Aubin 11/16/2007
	       if
		   (
		    (defined $option_set->getOption('monolexical-included'))
		    &&
		    ($option_set->getOption('monolexical-included')->getValue() == 1)
		    &&
		    ((blessed($tc)) && ($tc->isa('Lingua::YaTeA::MonolexicalTermCandidate')))
		    &&
		    (
		     (!defined $option_set->getOption('monolexical-all'))
		     ||
		     ($option_set->getOption('monolexical-all')->getValue() == 0)
		    )
		   )
	       {
		   $tc->addMonolexicalOccurrences($phrase_set,$monolexical_transfer_h)
	       }
	   }
	   else
	   {
	       $reference =  $term_candidates_h->{$tc->getKey};
	       $reference->addOccurrences($tc->getOccurrences);
	       $this->adjustReferences(\@term_candidates,$tc,$reference); 
	       
	       # add a frequency creteria for the confidence rate of the tcs
	   }
	   
	   # record the link between this phrase and the TC that covers it completely
	   if($tc->getID == $max_tc->getID)
	   {
	       $mapping_from_phrases_to_TCs_h->{$this->getID} = $reference;
	       $reference->{ORIGINAL_PHRASE} = $this;
	   }
       }
       #else
       #{
	  # print STDERR " NON \n";
       #}
   }
}


sub getID
{
    my ($this) = @_;
    return $this->{ID};
}

sub getTestifiedTerms
{
    my ($this) = @_;
    return $this->{TESTIFIED_TERMS};
}

sub addTestifiedTerms
{
    my ($this,$term_frontiers_h,$testified_term_set,$fh) = @_;
    my $testified;
    my @index;
    my $index;
    my $key;
    $this->{TESTIFIED_TERMS} = {};
    foreach my $tt_mark (values (%$term_frontiers_h))
    {
	$index = $tt_mark->getStart;
	
	if (defined $index) {
	    while ($index < $tt_mark->getEnd)
	    {
		push @index, $index++;
	    }
	    $key = join("-",@index);
	    push @{$this->getTestifiedTerms->{$key}}, $testified_term_set->getTestifiedTerms->{$tt_mark->getTestifiedID};
	    @index = ();
	}
    }
   
}




sub getIndexSet
{
    my ($this) = @_;
    return $this->{INDEX_SET};
}


sub addOccurrences
{
    my ($this,$occurrences_a) = @_;
    my $occurrence;
  
    foreach $occurrence (@$occurrences_a)
    {
	if($occurrence->isMaximal)
	{
	    $this->{MNP_STATUS} = 1;  # added by SA 13/02/2009:: if at least one occurrence is a MNP, Phrase is a MNP
	}
	$this->addExistingOccurrence($occurrence);
    }
}

sub adjustReferences
{
    my ($this,$term_candidates_a,$current,$reference) = @_;
    my $term_candidate;
    my $island;
    
    foreach $term_candidate (@$term_candidates_a)
    {
	if ((blessed($term_candidate)) && ($term_candidate->isa('Lingua::YaTeA::MultiWordTermCandidate')))
	{
	    if($term_candidate->getRootHead->getID == $current->getID)
	    {
		$term_candidate->{ROOT_HEAD} = $reference;
		$reference->setROOT($term_candidate);
	    }
	    if($term_candidate->getRootModifier->getID == $current->getID)
	    {
		$term_candidate->{ROOT_MODIFIER} = $reference;
		$reference->setROOT($term_candidate);
	    }
	}
    }

}


sub addExistingOccurrence
{
    my ($this,$occurrence) = @_;
    push @{$this->{OCCURRENCES}}, $occurrence;
}


sub getWordIndex
{
    my ($this,$word) = @_;
    my $w;
    my $i = 0;
    foreach $w (@{$this->getWords})
    {
	if($w == $word)
	{
	    return $i;
	}
	$i++;
    }
}


1;

__END__

=head1 NAME

Lingua::YaTeA::Phrase - Perl extension for phrases corresponding to the parsed terms

=head1 SYNOPSIS

  use Lingua::YaTeA::Phrase;
  Lingua::YaTeA::Phrase->new($num_content_words,$words_a,$tag_set);

=head1 DESCRIPTION


=head1 METHODS

=head2 new()

    new($num_content_words,$words_a,$tag_set);

=head2 setTC()

    setTC($status);


=head2 buildLinguisticInfos()

    buildLinguisticInfos($words_a,$tag_set);


=head2 addOccurrence()

    addOccurrence($words_a,$maximal,$fh);

=head2 incrementFrequency()

    incrementFrequency();

=head2 getWords()

    getWords();


=head2 setIF()

    setIF($newIF);

=head2 setPOS()

    setPOS($newPOS)

=head2 setLF()

    setLF($newLemma);


=head2 getIF()

    getIF();

=head2 getPOS()

    getPOS();

=head2 getLF()

    getLF();

=head2 buildKey()

    buildKey();

=head2 getWord()

    getWord($index);

=head2 isTC()

    isTC();

=head2 getFrequency()

    getFrequency();

=head2 getOccurrences()

    getOccurrences();

=head2 addTermCandidates()

    addTermCandidates($term_candidates_h,$mapping_from_phrases_to_TCs_h,$tc_max_length,$option_set,$phrase_set,$monolexical_transfer_h);

=head2 getID()

    getID();

=head2 getTestifiedTerms()

    getTestifiedTerms();

=head2 addTestifiedTerms()

    addTestifiedTerms($term_frontiers_h,$testified_term_set,$fh);

=head2 getIndexSet()

    getIndexSet();

=head2 addOccurrences()

    addOccurrences($occurrences_a);

=head2 adjustReferences()

    adjustReferences($term_candidates_a,$current,$reference);

=head2 addExistingOccurrence()

    addExistingOccurrence($occurrence);

=head2 getWordIndex

    getWordIndex($word);


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
