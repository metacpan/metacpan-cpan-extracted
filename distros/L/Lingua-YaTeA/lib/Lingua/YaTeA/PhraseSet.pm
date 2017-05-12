package Lingua::YaTeA::PhraseSet;
use strict;
use warnings;
use Lingua::YaTeA::MultiWordPhrase;
use Lingua::YaTeA::MonolexicalPhrase;
use Lingua::YaTeA::XMLEntities;
use UNIVERSAL;
use Data::Dumper;
use Scalar::Util qw(blessed);

our $VERSION=$Lingua::YaTeA::VERSION;

use Encode qw(:fallbacks);;

sub new
{
    my ($class) = @_;
    my $this = {};
    bless ($this,$class);
    $this->{PHRASES} = {}; # contain MultiWordPhrase
    $this->{UNPARSED} = ();
    $this->{UNPARSABLE} = ();
    $this->{IF_ACCESS} = ();
    $this->{LF_ACCESS} = ();
    $this->{TERM_CANDIDATES} = {};
    return $this;
}

sub recordOccurrence
{
    my ($this,$words_a,$num_content_words,$tag_set,$parsing_pattern_set,$option_set,$term_frontiers_h,$testified_term_set,$lexicon,$sentence_set,$fh) = @_;
    my $phrase;
    my $key;
    my $complete = 0;
    my $corrected = 0;
    if(scalar @$words_a != 0)
    {
	if(scalar @$words_a > 0)
	{
	    if(scalar @$words_a == 1)
	    {
		$phrase = Lingua::YaTeA::MonolexicalPhrase->new(1,$words_a,$tag_set);
	    }
	    else
	    {
		$phrase = Lingua::YaTeA::MultiWordPhrase->new($num_content_words,$words_a,$tag_set);
	    }
	    $key = $phrase->buildKey;
	    
	    if(!exists $this->getPhrases->{$key})
	    {
		$this->addPhrase($key,$phrase);
		if
		    (
		     ($option_set->optionExists('termino'))
		     &&
		     (scalar keys(%$term_frontiers_h) > 0)
		    )
		    # add testified terms here
		    
		{
		    $phrase->addTestifiedTerms($term_frontiers_h,$testified_term_set,$fh);
		  
		    
		}
		if ((blessed($phrase)) && ($phrase->isa('Lingua::YaTeA::MultiWordPhrase')))
		{
		    if(!$phrase->checkMaximumLength($option_set->getMaxLength))
		    {
			$phrase->setTC(0);
			$this->addToUnparsable($phrase);
		    }
		    else
		    {
			if (defined $phrase->getTestifiedTerms)
			{
			    #($complete,$corrected) = $phrase->searchExogenousIslands($parsing_pattern_set,$tag_set,$option_set->getParsingDirection,$lexicon,$sentence_set);
			    $phrase->searchExogenousIslands($parsing_pattern_set,$tag_set,$option_set->getParsingDirection,$lexicon,$sentence_set);
			    if(defined $phrase->getIslandSet)
			    {
			#	($complete,$corrected) = $phrase->integrateIslands($chunking_data,$tag_set,$lexicon,$parsing_direction,$sentence_set,$fh);
				($complete,$corrected) = $phrase->integrateIslands($tag_set,$lexicon,$option_set->getParsingDirection,$sentence_set,$fh);
			    }
			    if($corrected == 1)
			    {
# 				print "reengistre\n";
				$phrase->{LF} = $phrase->getIndexSet->buildLFSequence($phrase->getWords,$tag_set);
				$phrase->{POS} = $phrase->getIndexSet->buildPOSSequence($phrase->getWords,$tag_set);
			    }
			    if($complete == 1)
			    {
				$phrase->setTC(1);
				$phrase->setParsingMethod('TESTIFIED_MATCHING');
				$this->giveAccess($phrase);
			    }
			}
			if($complete == 0)
			{
			    if($phrase->searchParsingPattern($parsing_pattern_set,$tag_set,$option_set->getParsingDirection))
			    {
				$phrase->setTC(1);
				$phrase->setParsingMethod('PATTERN_MATCHING');
				$this->giveAccess($phrase);
				
			    }
			    else
			    {
				$this->addToUnparsed($phrase);
				# $this->addToUnparsable($phrase);
			    }
			}
		    }
		}
		else
		{ 

		    if ((defined $option_set->getOption('monolexical-all')) && ($option_set->getOption('monolexical-all')->getValue() == 1))
		    {
			$phrase->setTC(1);
			$phrase->setParsingMethod('MONOLEXICAL');
			$this->giveAccess($phrase);	
		    }
		    else
		    {
			
			# monolexical phrases are added to the unparsable phrase set
			$this->addToUnparsable($phrase);
		    }
		}
	    }
	    else{
		# debaptiser le phrase qui vient d'etre construit
		$phrase = $this->getPhrases->{$key};
	    }
	    $phrase->addOccurrence($words_a,1,$fh);
	}
    }
}




sub addPhrase
{
    my ($this,$key,$phrase) = @_;
    $this->getPhrases->{$key} = $phrase;
    $Lingua::YaTeA::Phrase::counter++;
    if ((blessed($phrase)) && ($phrase->isa('Lingua::YaTeA::MultiWordPhrase')))
    {
	$Lingua::YaTeA::MultiWordPhrase::counter++;
    }
    else
    {
	$Lingua::YaTeA::MonolexicalPhrase::counter++;
    }
}



sub getPhrases
{
    my ($this) = @_;
    return $this->{PHRASES};
}



sub giveAccess
{
    my ($this,$phrase) = @_;
    push @{$this->{IF_ACCESS}->{$phrase->getIF}}, $phrase; 
  
    push @{$this->{LF_ACCESS}->{$phrase->getLF}}, $phrase; 
}


sub searchFromIF
{
    my ($this,$key) = @_;
    if(exists $this->{IF_ACCESS}->{$key})
    {
	return $this->{IF_ACCESS}->{$key};
    }
   
}


sub searchFromLF
{
    my ($this,$key) = @_;
    if(exists $this->{LF_ACCESS}->{$key})
    {
	return $this->{LF_ACCESS}->{$key};
    }
}


sub addToUnparsed
{
    my ($this,$phrase) = @_;

    push @{$this->{UNPARSED}},$phrase;
}

sub addToUnparsable
{
    my ($this,$phrase) = @_;

#    print STDERR "$phrase\n";

    push @{$this->{UNPARSABLE}},$phrase;
}

sub getUnparsed
{
    my ($this) = @_;
    return $this->{UNPARSED};
}



sub sortUnparsed
{
    my ($this) = @_;
    if(defined $this->{UNPARSED})
    {
	@{$this->{UNPARSED}} = sort{$b->getLength <=> $a->getLength} @{$this->{UNPARSED}}; 
    } else {
	my @tmp = ();
	return(\@tmp);
    }
}

sub parseProgressively
{
    my ($this,$tag_set,$parsing_direction,$parsing_pattern_set,$chunking_data,$lexicon,$sentence_set,$message_set,$display_language, $fh) = @_;
    my $phrase;
    my $counter = 0;
    my $complete;
    my $corrected = 0;
    #foreach $phrase (@{$this->getUnparsed})
   
    my $Unparsed_size;

    my $ref = $this->getUnparsed;
    #$fh = \*STDERR;
    if (!defined $ref) {
	return (0);
    }
    $Unparsed_size = scalar(@{$ref});

    if(defined $this->{UNPARSED})
    {
	while ($phrase = pop @{$this->getUnparsed})
	{ 
	    $counter++;
	    #print $fh "\n\n";
 	    #print $fh "COUNTER: " . $counter . " \t" . $phrase->{'IF'} . "\n";
	    #$phrase->print($fh);
 
#  	    if (($phrase->{'IF'} eq "fonction ventriculaire gauche globale") || ($phrase->{'IF'} eq "fonction ventriculaire gauche systolique globale")) {
# 		print STDERR Dumper($phrase);
# 	    }
	    $complete = 0;
	    $corrected = 0;
	    $phrase->searchEndogenousIslands($this,$chunking_data,$tag_set,$lexicon,$sentence_set,$fh);
	    if(defined $phrase->getIslandSet)
	    {
		#$phrase->printIslands($fh);
#		($complete,$corrected) = $phrase->integrateIslands($chunking_data,$tag_set,$lexicon,$parsing_direction,$sentence_set,$fh);
		
		($complete,$corrected) = $phrase->integrateIslands($tag_set,$lexicon,$parsing_direction,$sentence_set,$fh);
	    }
	    if($corrected == 1)
	    {
		$this->updateRecord($phrase,$tag_set);
	    }
	   if($complete == 1)
	   {
	       $phrase->setParsingMethod('PROGRESSIVE');
	       $phrase->setTC(1);
	       $this->giveAccess($phrase);
	   }
	    else
	    {
		$phrase->plugInternalFreeNodes($parsing_pattern_set,$parsing_direction,$tag_set,$fh);
	       
		if($phrase->parseProgressively($tag_set,$parsing_direction,$parsing_pattern_set,$fh))
	       {
		   $phrase->setParsingMethod('PROGRESSIVE');
		   $phrase->setTC(1);
		   $this->giveAccess($phrase);
	       }
	       else
	       {
		   $phrase->setTC(0);
		   $this->addToUnparsable($phrase);
		   # $phrase->print($fh);

	       }
	       #	    $phrase->printForestParenthesised($fh);
	       #  print $fh "\n\n";
	       printf STDERR $message_set->getMessage('UNPARSED_PHRASES')->getContent($display_language) . "... %0.1f%%   \r", (scalar(@{$this->getUnparsed}) / $Unparsed_size) * 100 ;
	   }
	}
	print STDERR "\n";
    }
    
}

sub updateRecord
{
    my ($this,$phrase,$tag_set) = @_;
    my $key;
    my $reference;
    
    $key = $phrase->buildKey;
    
    if(exists $this->getPhrases->{$key})
    {
	delete $this->getPhrases->{$key};

    }

    $phrase->buildLinguisticInfos($phrase->getWords,$tag_set);
    $key = $phrase->buildKey;
    
     if(exists $this->getPhrases->{$key})
    {
	$reference = $this->getPhrases->{$key};
	$reference->addOccurrences($phrase->getOccurrences);
	
    }
    else
    {
	$this->getPhrases->{$key} = $phrase;
    }
}


sub getUnparsable
{
    my ($this) = @_;
    return $this->{UNPARSABLE};
}



sub getIFaccess
{
    my ($this) = @_;
    return $this->{IF_ACCESS};
}

sub addTermCandidates
{
    my ($this,$option_set) = @_;
    my $phrase;
    my $phrase_set;
    my $term_candidate;
    my $tc_max_length = $option_set->getTCMaxLength;
    my %mapping_from_phrases_to_TCs_h;
    my %monolexical_transfer;
   
  
    if(defined $this->getIFaccess)
    {
	foreach $phrase_set (values (%{$this->getIFaccess}))
	{
	    foreach $phrase (@$phrase_set){
		$phrase->addTermCandidates($this->getTermCandidates,\%mapping_from_phrases_to_TCs_h,$tc_max_length,$option_set,$this->getPhrases,\%monolexical_transfer);
	    }
	}
    }
    foreach $term_candidate (values (%{$this->getTermCandidates}))
	{
	
	if(
	    ((blessed($term_candidate)) && ($term_candidate->isa('Lingua::YaTeA::MultiWordTermCandidate')))
	    &&
	    ($term_candidate->containsIslands)
	    )
	{
	    $term_candidate->adjustIslandReferences(\%mapping_from_phrases_to_TCs_h);
	}
    }
    if ((defined $option_set->getOption('monolexical-included')) && ($option_set->getOption('monolexical-included')->getValue() == 1))
    {
	$this->adjustMonolexicalPhrasesSet(\%monolexical_transfer);
    }
}



sub adjustMonolexicalPhrasesSet
{
    my ($this,$monolexical_transfer_h) = @_;
    my @adjusted_list;
    my $phrase;
   
    if(defined $this->{UNPARSABLE})
    {
	while ($phrase = pop @{$this->getUnparsable})
	{
	    if
		(
		 (((blessed($phrase)) && ($phrase->isa('Lingua::YaTeA::MultiWordPhrase'))))
		 ||
		 (!exists $monolexical_transfer_h->{$phrase->getID})
		)
	    {
		push @adjusted_list, $phrase;
	    }
	}
    }
    @{$this->{UNPARSABLE}} = @adjusted_list;
}

sub getTermCandidates
{
    my ($this) = @_;
    return $this->{TERM_CANDIDATES};
}


sub printBootstrapList
{
    my ($this,$file,$source) = @_;
    my $fh;
    if ($file eq "stdout") {
	$fh = \*STDOUT;
    } else {
	if ($file eq "stderr") {
	    $fh = \*STDERR;
	} else {
	$fh = FileHandle->new(">".$file->getPath);
	}
    }
    binmode($fh, ":utf8");
#     my $fh = FileHandle->new(">".$file->getPath);
    my $term_candidate;
    my $tree;
    my $parse;
     foreach $term_candidate ( sort ({&sortTermCandidates($a,$b, "Freq")} values(%{$this->getTermCandidates})))
   {
       $parse = "";
       if ((blessed($term_candidate)) && ($term_candidate->isa('Lingua::YaTeA::MultiWordTermCandidate'))) {

	   $parse = $term_candidate->getKey;
	   #print STDERR "B :: " . $parse. "\n";
	   $parse =~ s/(<=[MH])=[^>]+(>)/$1$2/g;
	   $parse =~ s/<=(IN|TO)=[^>]+>/<=P>/g;
#	   $parse =~ s/<=IN=[^>]+>/<=P>/g;
	   $parse =~ s/<=[A-Z\$]+=[^>]+>/<=D>/g;
	   print $fh $parse;
	   print $fh "\t" . $term_candidate->getIF;
	   print $fh "\t" . $term_candidate->getPOS;
	   print $fh "\t" . $term_candidate->getLF;
	   print $fh "\t" . $source . "\n";
	   
       }
   }
}


sub printTermList
{
    my ($this,$file,$term_list_style, $sorted_weight) = @_;

    my $term_candidate;
    my $mes;
    my @Measures;

    my $fh;
    if ($file eq "stdout") {
	$fh = \*STDOUT;
    } else {
	if ($file eq "stderr") {
	    $fh = \*STDERR;
	} else {
	    $fh = FileHandle->new(">".$file->getPath);
	}
    }
    binmode($fh, ":utf8");
    warn "(tL) term_list_style: $term_list_style\n";
    if (!defined $sorted_weight) {
	$sorted_weight = "Freq";
    }

    my @term_candidates = values(%{$this->getTermCandidates});

    my $header = "Inflected form\tFrequency"; 

    if (scalar(@term_candidates) > 0) {
	@Measures = sort {lc($a) cmp lc($b)} keys %{$term_candidates[0]->getWeights};
	foreach $mes (@Measures) {
	    $header .= "\t$mes";
	}
    } 
    print $fh "# $header\n";
   
#     warn "term_list_style: $term_list_style\n";
    my $printLine;
    foreach $term_candidate ( sort ({&sortTermCandidates($a,$b, $sorted_weight)} @term_candidates))
    {
	
# 	warn ($term_candidate->isTerm * 1) . "\n";
# 	warn "term_list_style: $term_list_style\n";
# 	warn $term_candidate->isa('Lingua::YaTeA::MultiWordTermCandidate') . "\n";
	if(
	    (
	     ($term_list_style eq "")
	     ||
	     ($term_list_style eq "all")
	     ||
	     (
	      ($term_list_style eq "multi") 
	      &&
	      ((blessed($term_candidate)) && ($term_candidate->isa('Lingua::YaTeA::MultiWordTermCandidate'))) 
	     )
	    )
	    )
	{
	    $printLine = $term_candidate->getIF. "\t" .  $term_candidate->getFrequency;
	    foreach $mes (@Measures) {
		if (defined $term_candidate->getWeight($mes)) {
		    $printLine .= "\t" . $term_candidate->getWeight($mes);
		}
	    }
	    print $fh "$printLine\n";
	}
    }
}

sub printTermAndHeadList
{
    my ($this,$file,$term_list_style, $sorted_weight) = @_;

    my $term_candidate;
    my $mes;

    my $fh;
    if ($file eq "stdout") {
	$fh = \*STDOUT;
    } else {
	if ($file eq "stderr") {
	    $fh = \*STDERR;
	} else {
	    $fh = FileHandle->new(">".$file->getPath);
	}
    }
    binmode($fh, ":utf8");
    warn "(tL) term_list_style: $term_list_style\n";
    if (!defined $sorted_weight) {
	$sorted_weight = "Freq";
    }

    my @term_candidates = values(%{$this->getTermCandidates});

    my $header = "Inflected form\tFrequency"; 

    my @Measures = keys %{$term_candidates[0]->getWeights};
    foreach $mes (@Measures) {
	$header .= "\t$mes";
    }
    print $fh "# $header\n";

    my $printLine;
    foreach $term_candidate ( sort ({&sortTermCandidates($a,$b, $sorted_weight)} @term_candidates))
    {
	if(
	    (
	     ($term_list_style eq "")
	     ||
	     ($term_list_style eq "all")
	     ||
	     (
	      ($term_list_style eq "multi") 
	      &&
	      ((blessed($term_candidate)) && ($term_candidate->isa('Lingua::YaTeA::MultiWordTermCandidate')))
	     )
	    )
	    )
	    
	{
	    $printLine = $term_candidate->getIF. "\t" .  $term_candidate->getHead->getIF;
# 	    foreach $mes (@Measures) {
# 		if (defined $term_candidate->getWeight($mes)) {
# 		    $printLine .= "\t" . $term_candidate->getWeight($mes);
# 		}
# 	    }
	    print $fh "$printLine\n";
	}
    }
}

sub printTermAndRootHeadList
{
    my ($this,$file,$term_list_style, $sorted_weight) = @_;

    my $term_candidate;
    my $mes;

    my $fh;
    if ($file eq "stdout") {
	$fh = \*STDOUT;
    } else {
	if ($file eq "stderr") {
	    $fh = \*STDERR;
	} else {
	    $fh = FileHandle->new(">".$file->getPath);
	}
    }
    binmode($fh, ":utf8");
    warn "(tL) term_list_style: $term_list_style\n";
    if (!defined $sorted_weight) {
	$sorted_weight = "Freq";
    }

    my @term_candidates = values(%{$this->getTermCandidates});

    my $header = "Inflected form\tFrequency"; 

    my @Measures = keys %{$term_candidates[0]->getWeights};
    foreach $mes (@Measures) {
	$header .= "\t$mes";
    }
    print $fh "# $header\n";

    my $printLine;
    foreach $term_candidate ( sort ({&sortTermCandidates($a,$b, $sorted_weight)} @term_candidates))
    {
	if(
	    (
	     ($term_list_style eq "")
	     ||
	     ($term_list_style eq "all")
	     ||
	     (
	      ($term_list_style eq "multi") 
	      &&
	      ((blessed($term_candidate)) && ($term_candidate->isa('Lingua::YaTeA::MultiWordTermCandidate')))
	     )
	    )
	    )
	    
	{
	    $printLine = $term_candidate->getIF. "\t" .  $term_candidate->getRootHead->getIF;
# 	    foreach $mes (@Measures) {
# 		if (defined $term_candidate->getWeight($mes)) {
# 		    $printLine .= "\t" . $term_candidate->getWeight($mes);
# 		}
# 	    }
	    print $fh "$printLine\n";
	}
    }
}

sub printTermCandidatesAndComponents {
    my ($this,$file,$term_list_style, $tagset) = @_;

    my $term_candidate;
    my $mes;

    my $fh;
    if ($file eq "stdout") {
	$fh = \*STDOUT;
    } else {
	if ($file eq "stderr") {
	    $fh = \*STDERR;
	} else {
	    $fh = FileHandle->new(">".$file->getPath);
	}
    }
    binmode($fh, ":utf8");
    # warn "(tL) term_list_style: $term_list_style\n";
    # if (!defined $sorted_weight) {
    # 	$sorted_weight = "Freq";
    # }
    
    my @term_candidates = values(%{$this->getTermCandidates});

    # my $header = "Inflected form\tFrequency"; 

    # my @Measures = keys %{$term_candidates[0]->getWeights};
    # foreach $mes (@Measures) {
    # 	$header .= "\t$mes";
    # }
    # print $fh "# $header\n";

    my $header = "Term inflected form\tTerm lemmatised form\tTerm frequency\t"; 
    $header .= "Head inflected form\tHead lemmatised form\tHead frequency\t"; 
    $header .= "Modifier inflected form\tModifier lemmatised form\tModifier frequency\t"; 
    print $fh "# $header\n";

    my $printLine;
    # foreach $term_candidate ( sort ({&sortTermCandidates($a,$b, $sorted_weight)} @term_candidates))
    foreach $term_candidate (@term_candidates) {
	if(
	    (
	     ($term_list_style eq "")
	     ||
	     ($term_list_style eq "all")
	     ||
	     (
	      ($term_list_style eq "multi") 
	      &&
	      ((blessed($term_candidate)) && ($term_candidate->isa('Lingua::YaTeA::MultiWordTermCandidate')))
	     )
	    )
	    ) {
	    $printLine = $term_candidate->getIF . "\t" . $term_candidate->getLF . "\t" .  $term_candidate->getFrequency . "\t" ;
	    if ((blessed($term_candidate)) && ($term_candidate->isa('Lingua::YaTeA::MultiWordTermCandidate'))) {
		$printLine .= $term_candidate->getRootHead->getIF . "\t" . $term_candidate->getRootHead->getLF . "\t" .  $term_candidate->getRootHead->getFrequency . "\t" ;
		$printLine .= $term_candidate->getRootModifier->getIF . "\t" . $term_candidate->getRootModifier->getLF . "\t" .  $term_candidate->getRootModifier->getFrequency . "\t" ;
	    } else {
		$printLine .= "\t\t\t\t";
	    }
# 	    foreach $mes (@Measures) {
# 		if (defined $term_candidate->getWeight($mes)) {
# 		    $printLine .= "\t" . $term_candidate->getWeight($mes);
# 		}
# 	    }
	    print $fh "$printLine\n";
	}
    }
}

sub sortTermCandidates
{
    my ($a,$b, $weight) = @_;

    if (!defined $b->getWeight($weight)) {
	return($b->getFrequency <=> $a->getFrequency);
    }

    if($b->getWeight($weight) == $a->getWeight($weight))
    {
	if($b->getReliability == $a->getReliability)
	{
	    return $b->getFrequency <=> $a->getFrequency;
	}
	else
	{
	    return $b->getReliability <=> $a->getReliability;
	}
    }
    else
    {
	return $b->getWeight($weight) <=> $a->getWeight($weight);
    }
}

sub printUnparsable
{
    my ($this,$file) = @_;
    my $phrase;
    my $fh;
    if ($file eq "stdout") {
	$fh = \*STDOUT;
    } else {
	if ($file eq "stderr") {
	    $fh = \*STDERR;
	} else {
#	    warn $file->getPath . "\n";
	    $fh = FileHandle->new(">".$file->getPath);
	}
    }
#    binmode($fh, ":utf8");
#     my $fh = FileHandle->new(">".$file->getPath);

    # We should test if there are unparsable or not.
    if (defined $this->getUnparsable) {
	foreach $phrase (@{$this->getUnparsable})
	{
	    if ((blessed($phrase)) && ($phrase->isa('Lingua::YaTeA::MultiWordPhrase')))
	    {
		print $fh Lingua::YaTeA::XMLEntities::encode(Encode::encode("UTF-8", $phrase->getIF . "\t" . $phrase->getPOS . "\n"));
	    }
	}
    }
    if (($file ne 'stdout') && ($file ne 'stderr')) {
	$fh->close;
    }
}



sub printUnparsed
{
    my ($this,$file) = @_;
    my $phrase;
    my $fh;
    if ($file eq "stdout") {
	$fh = \*STDOUT;
    } else {
	if ($file eq "stderr") {
	    $fh = \*STDERR;
	} else {
	    $fh = FileHandle->new(">".$file->getPath);
	}
    }
    # binmode($fh, ":utf8");
#     my $fh = FileHandle->new(">".$file->getPath);

    # We should test if there are unparsable or not.
    if (defined $this->getUnparsed) {
	foreach $phrase (@{$this->getUnparsed})
	{
	    if ((blessed($phrase)) && ($phrase->isa('Lingua::YaTeA::MultiWordPhrase')))
	    {
		print $fh $phrase->getIF . "\t" . $phrase->getPOS . "\n";
	    }
	}
    }
    if (($file ne 'stdout') && ($file ne 'stderr')) {
	$fh->close;
    }
}

sub printTermCandidatesTTG
{
    my ($this,$file,$ttg_style) = @_;
    
    my $fh;
    if ($file eq "stdout") {
	$fh = \*STDOUT;
    } else {
	if ($file eq "stderr") {
	    $fh = \*STDERR;
	} else {
	    $fh = FileHandle->new(">".$file->getPath);
	}
    }
    binmode($fh, ":utf8");
#     my $fh = FileHandle->new(">".$file->getPath);
    my $term_candidate;
    my $word;
    
    foreach $term_candidate (values(%{$this->getTermCandidates}))
    {
	if
	    (
	     ($ttg_style eq "")
	     ||
	     ($ttg_style eq "all")
	     ||
	     (
	      ($ttg_style eq "multi")
	      &&
	      ((blessed($term_candidate)) && ($term_candidate->isa('Lingua::YaTeA::MultiWordTermCandidate')))
	     )
	    )
	{
	    foreach $word (@{$term_candidate->getWords})
	    {
		print $fh $word->getIF . "\t" . $word->getPOS . "\t" . $word->getLF . "\n";
	    }
	    print $fh "\.\tSENT\t\.\n";
	}
    }
}

sub printTermCandidatesFFandTTG
{
    my ($this,$file,$ttg_style,$tagset) = @_;
    
    my $if;
    my $pos;
    my $lf;

    my $fh;
    if ($file eq "stdout") {
	$fh = \*STDOUT;
    } else {
	if ($file eq "stderr") {
	    $fh = \*STDERR;
	} else {
	    $fh = FileHandle->new(">".$file->getPath);
	}
    }
    binmode($fh, ":utf8");
#     my $fh = FileHandle->new(">".$file->getPath);
    my $term_candidate;
    my $word;
    
    foreach $term_candidate (values(%{$this->getTermCandidates}))
    {
	if
	    (
	     ($ttg_style eq "")
	     ||
	     ($ttg_style eq "all")
	     ||
	     (
	      ($ttg_style eq "multi")
	      &&
	      ((blessed($term_candidate)) && ($term_candidate->isa('Lingua::YaTeA::MultiWordTermCandidate')))
	     )
	    )
	{
	    ($if,$pos,$lf) = $term_candidate->buildLinguisticInfos($tagset);
	    Lingua::YaTeA::XMLEntities::encode($if);
	    Lingua::YaTeA::XMLEntities::encode($pos);
	    Lingua::YaTeA::XMLEntities::encode($lf);
	    print $fh "$if\t$lf\t$pos\n";
# 	    foreach $word (@{$term_candidate->getWords})
# 	    {
# 		print $fh $word->getIF . "\t" . $word->getPOS . "\t" . $word->getLF . "\n";
# 	    }
# 	    print $fh "\.\tSENT\t\.\n";
	}
    }
}

sub printTermCandidatesXML
{
    my ($this,$file,$tagset) = @_;
    
    my $fh;

    if ($file eq "stdout") {
	$fh = \*STDOUT;
    } else {
	if ($file eq "stderr") {
	    $fh = \*STDERR;
	} else {
	    $fh = FileHandle->new(">".$file->getPath);
	}
    }
    binmode($fh,":utf8");
    my $term_candidate;
    my $if;
    my $pos;
    my $lf;
    my $occurrence;
    my $island;
    my $position;

    # header
    print $fh "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    print $fh "<!DOCTYPE TERM_EXTRACTION_RESULTS SYSTEM \"yatea.dtd\">\n";
    print $fh "\n";
    print $fh "<TERM_EXTRACTION_RESULTS>\n";

    $this->printListTermCandidatesXML($file, $tagset, $fh);

    print $fh "</TERM_EXTRACTION_RESULTS>\n";
   
}


sub printListTermCandidatesXML {
    my ($this,$file,$tagset, $fh) = @_;

    if (!defined $fh) {
	if ($file eq "stdout") {
	    $fh = \*STDOUT;
	} else {
	    if ($file eq "stderr") {
		$fh = \*STDERR;
	    } else {
		$fh = FileHandle->new(">".$file->getPath);
	    }
	}
    }
    binmode($fh,":utf8");
#     my $fh = FileHandle->new(">".$file->getPath);
    my $term_candidate;
    my $word;
    my $if;
    my $pos;
    my $lf;
    my $occurrence;
    my $island;
    my $position;


    print $fh "  <LIST_TERM_CANDIDATES>\n";

    foreach $term_candidate (values(%{$this->getTermCandidates}))
    {
	($if,$pos,$lf) = $term_candidate->buildLinguisticInfos($tagset);
	Lingua::YaTeA::XMLEntities::encode($if);
	Lingua::YaTeA::XMLEntities::encode($pos);
	Lingua::YaTeA::XMLEntities::encode($lf);
	print $fh "    <TERM_CANDIDATE MNP_STATUS=\"" . $term_candidate->getMNPStatus . "\">\n";  # added by SA 13/02/2009
# 	print $fh "    <TERM_CANDIDATE>\n";
	print $fh "      <ID>term" . $term_candidate->getID . "</ID>\n";
	print $fh "      <FORM>" . $if . "</FORM>\n";
	print $fh "      <LEMMA>" . $lf . "</LEMMA>\n";
	print $fh "      <MORPHOSYNTACTIC_FEATURES>\n";
	print $fh "	    <SYNTACTIC_CATEGORY>" .$pos  . "</SYNTACTIC_CATEGORY>\n"; 
	print $fh "      </MORPHOSYNTACTIC_FEATURES>\n";
	print $fh "      <HEAD>term" . $term_candidate->getHead->getID . "</HEAD>\n";

	# occurrences
	print $fh "      <NUMBER_OCCURRENCES>". $term_candidate->getFrequency . "</NUMBER_OCCURRENCES>\n";
	print $fh "      <LIST_OCCURRENCES>\n";
	foreach $occurrence (@{$term_candidate->getOccurrences})
	{
	    print $fh "      <OCCURRENCE>\n";
	    print $fh "        <ID>occ" . $occurrence->getID . "</ID>\n";
	    print $fh "        <MNP>" . (($occurrence->isMaximal) * 1) .  "</MNP>\n"; #  && $term_candidate->isa('Lingua::YaTeA::MultiWordTermCandidate') -- remove by Thierry Hamon 29/09/2008
	    print $fh "        <DOC>" .$occurrence->getDocument->getID . "</DOC>\n";
	    print $fh "        <SENTENCE>" .$occurrence->getSentence->getInDocID . "</SENTENCE>\n";
	    print $fh "        <START_POSITION>";
	    print $fh $occurrence->getStartChar;
	    print $fh "</START_POSITION>\n";
	    print $fh "        <END_POSITION>";
	    print $fh $occurrence->getEndChar;
	    print $fh "</END_POSITION>\n";
	    print $fh "        </OCCURRENCE>\n";
	}
	print $fh "      </LIST_OCCURRENCES>\n";
	print $fh "      <TERM_CONFIDENCE>" . $term_candidate->getReliability . "</TERM_CONFIDENCE>\n"; 
	print $fh "      <TERM_WEIGHTS>\n";
	foreach my $weight ($term_candidate->getWeightNames) {
	    print $fh "            <WEIGHT name=\"$weight\">";
	    print $fh $term_candidate->getWeight($weight);
	    print $fh "</WEIGHT>\n";
	}
	print $fh "      </TERM_WEIGHTS>\n"; 

	# islands of reliability
	if(
	    ((blessed($term_candidate)) && ($term_candidate->isa('Lingua::YaTeA::MultiWordTermCandidate')))
	    &&
	    ($term_candidate->containsIslands)
	    )
	{
	    print $fh "      <LIST_RELIABLE_ANCHORS>\n";
	    foreach $island (@{$term_candidate->getIslands})
	    {
		print $fh "        <RELIABLE_ANCHOR>\n";
		if((blessed($island)) && ($island->isa('Lingua::YaTeA::TermCandidate')))
		{
		    print $fh "          <ID>term";
		    print $fh $island->getID;
		}
		else
		{
		    print $fh "          <ID>testified_term";
		    print $fh $island->getID;
		}
		print $fh "</ID>\n";
		print $fh "          <FORM>";
		$if = $island->getIF;
		Lingua::YaTeA::XMLEntities::encode($if);
		print $fh $if;
		print $fh "</FORM>\n";
		print $fh "          <ORIGIN>";
		print $fh $island->getIslandType;
		print $fh "</ORIGIN>\n";
		print $fh "        </RELIABLE_ANCHOR>\n";
	    }
	    print $fh "      </LIST_RELIABLE_ANCHORS>\n";
	}
	print $fh "      <LOG_INFORMATION>YaTeA</LOG_INFORMATION>\n";
	if ((blessed($term_candidate)) && ($term_candidate->isa('Lingua::YaTeA::MultiWordTermCandidate')))
	{
	    print $fh "      <SYNTACTIC_ANALYSIS>\n";
	    print $fh "        <HEAD>\n        term";
	    print $fh $term_candidate->getRootHead->getID;
	    print $fh "\n        </HEAD>\n";
	    print $fh "        <MODIFIER POSITION=\"";
	    print $fh $term_candidate->getModifierPosition;	
	    print $fh "\">\n        term";
	    print $fh $term_candidate->getRootModifier->getID;
	    print $fh "\n        </MODIFIER>\n";
	    if(defined $term_candidate->getPreposition)
	    {
		print $fh "        <PREP>\n        ";
		print $fh $term_candidate->getPreposition->getIF;
		print $fh "\n        </PREP>\n";
	    }
	    if(defined $term_candidate->getDeterminer)
	    {
		print $fh "        <DETERMINER>\n        ";
		print $fh $term_candidate->getDeterminer->getIF;
		print $fh "\n        </DETERMINER>\n";
	    }
	    print $fh "      </SYNTACTIC_ANALYSIS>\n";
	}
	print $fh "    </TERM_CANDIDATE>\n";
    }
    print $fh "  </LIST_TERM_CANDIDATES>\n";
    

}

sub printTermCandidatesDot2
{
    my ($this,$file,$tagset) = @_;
    
    my $fh;

    if ($file eq "stdout") {
	$fh = \*STDOUT;
    } else {
	if ($file eq "stderr") {
	    $fh = \*STDERR;
	} else {
	    $fh = FileHandle->new(">".$file->getPath);
	}
    }
    binmode($fh,":utf8");
    my $term_candidate;
    my $if;
    my $pos;
    my $lf;
    my $occurrence;
    my $island;
    my $position;

    # header
    print $fh "graph Terms {\n\n";
    print $fh "label=\"Full set of terms\"\n";
    print $fh "overlap=false\n";

    $this->printListTermCandidatesDot2($file, $tagset, $fh);

    print $fh "}\n";
   
}


sub printListTermCandidatesDot {
    my ($this,$tagset) = @_;

    my %term2CC;
    my %termLabel;
    my %CC2terms;
    my %CC2relations;
    my %relationLabel;
    my %relationLabelH;
    my $term;
    my $CC;
    my $fh;
    my $rel;
    my $oldCC;

    warn "Making dot files\n";
#     my $fh = FileHandle->new(">".$file->getPath);
    my $term_candidate;
    my $word;
    my $if;
    my $pos;
    my $lf;
    my $occurrence;
    my $island;
    my $position;

    foreach $term_candidate (values(%{$this->getTermCandidates}))
    {
	($if,$pos,$lf) = $term_candidate->buildLinguisticInfos($tagset);
	Lingua::YaTeA::XMLEntities::encode($if);
	Lingua::YaTeA::XMLEntities::encode($pos);
	Lingua::YaTeA::XMLEntities::encode($lf);

	if (!exists $term2CC{$term_candidate->getID}) {
	    $term2CC{$term_candidate->getID} = 'CC' . $term_candidate->getID;
	    $CC2terms{$term2CC{$term_candidate->getID}} = {$term_candidate->getID => 1};
	    $CC2relations{$term2CC{$term_candidate->getID}} = {};
# 	} else {
# 	    # merge
# 	    foreach $term (@{$CC2terms{$term_candidate->getID}}) {
# 		    $term2CC{$term} = $term_candidate->getID;
# 		    push @{$CC2terms{$term_candidate->getID}}, $term;
# 		    delete $term2CC{$term};
# 		}
# 		delete $CC2terms{$term_candidate->getHead->getID};
	}
	$termLabel{$term_candidate->getID} = "[label=\"" . $if . '\n(' . $term_candidate->getFrequency . ")\"]";
# 	print $fh $term_candidate->getID ;
# 	print $fh " [label=\"" . $if . "\"];\n";
	
 	if ($term_candidate->getID ne $term_candidate->getHead->getID) {
# # 	    print $fh $term_candidate->getID . " -- " . $term_candidate->getHead->getID . "[label=\"main head\" color=\"red\"];\n";
# 	    if (exists $term2CC{$term_candidate->getHead->getID}) {
# 		# merge
# # 		$oldCC = $term2CC{$term_candidate->getHead->getID};
# # 		foreach $term (keys %{$CC2terms{$oldCC}}) {
# # 		    $term2CC{$term} = $term2CC{$term_candidate->getID};
# # 		    $CC2terms{$term2CC{$term_candidate->getID}}->{$term}++;
# # 		    delete $term2CC{$term};
# # 		}
# # 		delete $CC2terms{$oldCC};

# # 		if (defined $CC2relations{$oldCC}) {
# # 		    foreach $rel (keys %{$CC2relations{$oldCC}}) {
# # 			$CC2relations{$oldCC}->{$rel}++;
# # 		    }
# # 		    delete $CC2relations{$oldCC};
# # 		}
# 	    } else {
# 		$term2CC{$term_candidate->getHead->getID} = $term2CC{$term_candidate->getID};
# 		$CC2terms{$term_candidate->getID}->{$term_candidate->getHead->getID}++;
# # 		if (defined $CC2relations{$term_candidate->getHead->getID}) {
# # 		    foreach $rel (keys %{$CC2relations{$term_candidate->getHead->getID}}) {
# # 			$CC2relations{$term2CC{$term_candidate->getID}}->{$rel}++;
# # 		    }
# # 		    delete $CC2relations{$term_candidate->getHead->getID};
# # 		}
# 	    }
	    $CC2relations{$term_candidate->getID}->{$term_candidate->getID . " -- " . $term_candidate->getHead->getID}++;
	    $relationLabelH{$term_candidate->getID . " -- " . $term_candidate->getHead->getID} = "[label=\"main head\" weight=1 color=\"yellow\"];";
 	}

	# occurrences
# 	print $fh "      <NUMBER_OCCURRENCES>". $term_candidate->getFrequency . "</NUMBER_OCCURRENCES>\n";
# 	print $fh "      <LIST_OCCURRENCES>\n";
# 	foreach $occurrence (@{$term_candidate->getOccurrences})
# 	{
# 	    print $fh "      <OCCURRENCE>\n";
# 	    print $fh "        <ID>occ" . $occurrence->getID . "</ID>\n";
# 	    print $fh "        <MNP>" . (($occurrence->isMaximal) * 1) .  "</MNP>\n"; #  && $term_candidate->isa('Lingua::YaTeA::MultiWordTermCandidate') -- remove by Thierry Hamon 29/09/2008
# 	    print $fh "        <DOC>" .$occurrence->getDocument->getID . "</DOC>\n";
# 	    print $fh "        <SENTENCE>" .$occurrence->getSentence->getInDocID . "</SENTENCE>\n";
# 	    print $fh "        <START_POSITION>";
# 	    print $fh $occurrence->getStartChar;
# 	    print $fh "</START_POSITION>\n";
# 	    print $fh "        <END_POSITION>";
# 	    print $fh $occurrence->getEndChar;
# 	    print $fh "</END_POSITION>\n";
# 	    print $fh "        </OCCURRENCE>\n";
# 	}
# 	print $fh "      </LIST_OCCURRENCES>\n";
# 	print $fh "      <TERM_CONFIDENCE>" . $term_candidate->getReliability . "</TERM_CONFIDENCE>\n"; 
# 	print $fh "      <TERM_WEIGHTS>\n";
# 	foreach my $weight ($term_candidate->getWeightNames) {
# 	    print $fh "            <WEIGHT name=\"$weight\">";
# 	    print $fh $term_candidate->getWeight($weight);
# 	    print $fh "</WEIGHT>\n";
# 	}
# 	print $fh "      </TERM_WEIGHTS>\n"; 

	# islands of reliability
# 	if(
# 	    ($term_candidate->isa('Lingua::YaTeA::MultiWordTermCandidate'))
# 	    &&
# 	    ($term_candidate->containsIslands)
# 	    )
# 	{
# 	    print $fh "      <LIST_RELIABLE_ANCHORS>\n";
# 	    foreach $island (@{$term_candidate->getIslands})
# 	    {
# 		print $fh "        <RELIABLE_ANCHOR>\n";
# 		if($island->isa('Lingua::YaTeA::TermCandidate'))
# 		{
# 		    print $fh "          <ID>term";
# 		    print $fh $island->getID;
# 		}
# 		else
# 		{
# 		    print $fh "          <ID>testified_term";
# 		    print $fh $island->getID;
# 		}
# 		print $fh "</ID>\n";
# 		print $fh "          <FORM>";
# 		$if = $island->getIF;
# 		Lingua::YaTeA::XMLEntities::encode($if);
# 		print $fh $if;
# 		print $fh "</FORM>\n";
# 		print $fh "          <ORIGIN>";
# 		print $fh $island->getIslandType;
# 		print $fh "</ORIGIN>\n";
# 		print $fh "        </RELIABLE_ANCHOR>\n";
# 	    }
# 	    print $fh "      </LIST_RELIABLE_ANCHORS>\n";
# 	}
# 	print $fh "      <LOG_INFORMATION>YaTeA</LOG_INFORMATION>\n";
	if ((blessed($term_candidate)) && ($term_candidate->isa('Lingua::YaTeA::MultiWordTermCandidate'))) {
# 	    print $fh "      <SYNTACTIC_ANALYSIS>\n";
#	    print $fh "        <HEAD>\n        term";

	    if ((exists $term2CC{$term_candidate->getRootHead->getID}) && ($term2CC{$term_candidate->getRootHead->getID} ne $term2CC{$term_candidate->getID})) {
		# merge
		$oldCC = $term2CC{$term_candidate->getRootHead->getID};
		foreach $term (keys %{$CC2terms{$term2CC{$term_candidate->getRootHead->getID}}}) {
		    $term2CC{$term} = $term2CC{$term_candidate->getID};
		    $CC2terms{$term2CC{$term_candidate->getID}}->{$term}++;
		}
		delete $CC2terms{$oldCC};
		if (defined $CC2relations{$oldCC}) {
		    foreach $rel (keys %{$CC2relations{$oldCC}}) {
			$CC2relations{$term2CC{$term_candidate->getID}}->{$rel}++;
		    }
		    delete $CC2relations{$oldCC};

# 		    push @{$CC2relations{$term_candidate->getID}},  @{$CC2relations{$term_candidate->getRootHead->getID}};
# 		    delete $CC2relations{$term_candidate->getRootHead->getID};
		}
	    } else {
		$term2CC{$term_candidate->getRootHead->getID} = $term2CC{$term_candidate->getID};
		$CC2terms{$term2CC{$term_candidate->getID}}->{$term_candidate->getRootHead->getID}++;
# 		if (defined $CC2relations{$term2CC{$term_candidate->getRootHead->getID}}) {
# 		    foreach $rel (keys %{$CC2relations{$term2CC{$term_candidate->getRootHead->getID}}}) {
# 			$CC2relations{$term2CC{$term_candidate->getID}}->{$rel}++;
# 		    }
# 		    delete $CC2relations{$term2CC{$term_candidate->getRootHead->getID}};

# # 		    push @{$CC2relations{$term_candidate->getID}},  @{$CC2relations{$term_candidate->getRootHead->getID}};
# # 		    delete $CC2relations{$term_candidate->getRootHead->getID};
# 		}
	    }

	    if ((exists $term2CC{$term_candidate->getRootModifier->getID}) && ($term2CC{$term_candidate->getRootModifier->getID} ne $term2CC{$term_candidate->getID})) {
		# merge
# 		warn "merge " . $term2CC{$term_candidate->getRootModifier->getID} . "\n";
		$oldCC = $term2CC{$term_candidate->getRootModifier->getID};
		foreach $term (keys %{$CC2terms{$term2CC{$term_candidate->getRootModifier->getID}}}) {
# 		    warn"\t$term\n";
		    $term2CC{$term} = $term2CC{$term_candidate->getID};
		    $CC2terms{$term2CC{$term_candidate->getID}}->{$term}++;
		}
		delete $CC2terms{$oldCC};
		if (defined $CC2relations{$oldCC}) {
		    foreach $rel (keys %{$CC2relations{$oldCC}}) {
			$CC2relations{$term2CC{$term_candidate->getID}}->{$rel}++;
		    }
		    delete $CC2relations{$term_candidate->getRootModifier->getID};

# 		    push @{$CC2relations{$term_candidate->getID}},  @{$CC2relations{$term_candidate->getRootModifier->getID}};
# 		    delete $CC2relations{$term_candidate->getRootModifier->getID};
		}
	    } else  {
		$term2CC{$term_candidate->getRootModifier->getID} = $term2CC{$term_candidate->getID};
		$CC2terms{$term2CC{$term_candidate->getID}}->{$term_candidate->getRootModifier->getID}++;
# 		if (defined $CC2relations{$term2CC{$term_candidate->getRootModifier->getID}}) {
# 		    foreach $rel (keys %{$CC2relations{$term2CC{$term_candidate->getRootModifier->getID}}}) {
# 			$CC2relations{$term2CC{$term_candidate->getID}}->{$rel}++;
# 		    }
# 		    delete $CC2relations{$term2CC{$term_candidate->getRootModifier->getID}};

# # 		    push @{$CC2relations{$term_candidate->getID}},  @{$CC2relations{$term_candidate->getRootModifier->getID}};
# # 		    delete $CC2relations{$term_candidate->getRootModifier->getID};
# 		}
	    }
# XX

# XX
 	    $CC2relations{$term2CC{$term_candidate->getID}}->{$term_candidate->getRootHead->getID . " -- " . $term_candidate->getRootModifier->getID}++;
	    $relationLabel{$term_candidate->getRootHead->getID . " -- " . $term_candidate->getRootModifier->getID} = "[label=\"head / modifier\" color=\"black\" weight=1]";


# 	    print $fh $term_candidate->getRootHead->getID;
# # 	    print $fh "\n        </HEAD>\n";
# 	    print $fh " -- ";
# # 	    print $fh $term_candidate->getModifierPosition;	
# 	    print $fh $term_candidate->getRootModifier->getID;
# 	    print $fh "[label=\"Head / Modifier\" color=\"black\" weight=1]\n";

 	    $CC2relations{$term2CC{$term_candidate->getID}}->{$term_candidate->getID . " -- " . $term_candidate->getRootHead->getID}++;
	    $relationLabel{$term_candidate->getID . " -- " . $term_candidate->getRootHead->getID} = "[label=\"term / head\" color=\"black\" weight=3]";
# 	    print $fh $term_candidate->getID ;
# 	    print $fh " -- ";
# 	    print $fh $term_candidate->getRootHead->getID;
# 	    print $fh "[label=\"Term / Head\" color=\"black\" weight=2]\n";

# XX
 	    $CC2relations{$term2CC{$term_candidate->getID}}->{$term_candidate->getID . " -- " . $term_candidate->getRootModifier->getID}++;
	    $relationLabel{$term_candidate->getID . " -- " . $term_candidate->getRootModifier->getID} = "[label=\"term / modifier\" color=\"black\" weight=3]";

# 	    print $fh $term_candidate->getID ;
# 	    print $fh " -- ";
# 	    print $fh $term_candidate->getRootModifier->getID;
# 	    print $fh "[label=\"Term / Modifier\" color=\"black\" weight=2]\n";

# 	    print $fh "\n        </MODIFIER>\n";
# 	    if(defined $term_candidate->getPreposition)
# 	    {
# 		print $fh "        <PREP>\n        ";
# 		print $fh $term_candidate->getPreposition->getIF;
# 		print $fh "\n        </PREP>\n";
# 	    }
# 	    if(defined $term_candidate->getDeterminer)
# 	    {
# 		print $fh "        <DETERMINER>\n        ";
# 		print $fh $term_candidate->getDeterminer->getIF;
# 		print $fh "\n        </DETERMINER>\n";
# 	    }
# 	    print $fh "      </SYNTACTIC_ANALYSIS>\n";
 	}
# 	print $fh "    </TERM_CANDIDATE>\n";
    }
#     print $fh "  </LIST_TERM_CANDIDATES>\n";

    foreach $CC (keys %CC2terms) {
	# my $filename = $file->getPath;
	# $filename =~ s/.xml//;
	# $fh = FileHandle->new(">" . $filename . "/$CC" . ".dot");
	$fh = FileHandle->new(">$CC" . ".dot");
	binmode($fh,":utf8");

	print $fh "graph Terms {\n\n";
	print $fh "label=\"Full set of terms $CC\"\n";
	print $fh "overlap=false\n";
	foreach $term (keys %{$CC2terms{$CC}}) {
	    print $fh $term . " " . $termLabel{$term} . "\n";
	}
	foreach $rel (keys %{$CC2relations{$CC}}) {
	    if (exists $relationLabel{$rel}) {
		print $fh $rel . " " . $relationLabel{$rel} . "\n";
	    }
	    if (exists $relationLabelH{$rel}) {
		print $fh $rel . " " . $relationLabelH{$rel} . "\n";
	    }
	}

	print $fh "}\n";
    }

}

sub printListTermCandidatesDot2 {
    my ($this,$file,$tagset, $fh) = @_;

    if (!defined $fh) {
	if ($file eq "stdout") {
	    $fh = \*STDOUT;
	} else {
	    if ($file eq "stderr") {
		$fh = \*STDERR;
	    } else {
		$fh = FileHandle->new(">".$file->getPath);
	    }
	}
	binmode($fh,":utf8");
    }
#     my $fh = FileHandle->new(">".$file->getPath);
    my $term_candidate;
    my $word;
    my $if;
    my $pos;
    my $lf;
    my $occurrence;
    my $island;
    my $position;


#     print $fh "  <LIST_TERM_CANDIDATES>\n";

    foreach $term_candidate (values(%{$this->getTermCandidates}))
    {
	($if,$pos,$lf) = $term_candidate->buildLinguisticInfos($tagset);
	Lingua::YaTeA::XMLEntities::encode($if);
	Lingua::YaTeA::XMLEntities::encode($pos);
	Lingua::YaTeA::XMLEntities::encode($lf);
# 	print $fh "    <TERM_CANDIDATE MNP_STATUS=\"" . $term_candidate->getMNPStatus . "\">\n";  # added by SA 13/02/2009
# 	print $fh "    <TERM_CANDIDATE>\n";
	print $fh $term_candidate->getID ;
	print $fh " [label=\"" . $if . "\"];\n";
# 	print $fh "      <LEMMA>" . $lf . "</LEMMA>\n";
# 	print $fh "      <MORPHOSYNTACTIC_FEATURES>\n";
# 	print $fh "	    <SYNTACTIC_CATEGORY>" .$pos  . "</SYNTACTIC_CATEGORY>\n"; 
# 	print $fh "      </MORPHOSYNTACTIC_FEATURES>\n";
	
	if ($term_candidate->getID ne $term_candidate->getHead->getID) {
	    print $fh $term_candidate->getID . " -- " . $term_candidate->getHead->getID . "[label=\"main head\" weight=1 color=\"yellow\"];\n";
	}
	# occurrences
# 	print $fh "      <NUMBER_OCCURRENCES>". $term_candidate->getFrequency . "</NUMBER_OCCURRENCES>\n";
# 	print $fh "      <LIST_OCCURRENCES>\n";
# 	foreach $occurrence (@{$term_candidate->getOccurrences})
# 	{
# 	    print $fh "      <OCCURRENCE>\n";
# 	    print $fh "        <ID>occ" . $occurrence->getID . "</ID>\n";
# 	    print $fh "        <MNP>" . (($occurrence->isMaximal) * 1) .  "</MNP>\n"; #  && $term_candidate->isa('Lingua::YaTeA::MultiWordTermCandidate') -- remove by Thierry Hamon 29/09/2008
# 	    print $fh "        <DOC>" .$occurrence->getDocument->getID . "</DOC>\n";
# 	    print $fh "        <SENTENCE>" .$occurrence->getSentence->getInDocID . "</SENTENCE>\n";
# 	    print $fh "        <START_POSITION>";
# 	    print $fh $occurrence->getStartChar;
# 	    print $fh "</START_POSITION>\n";
# 	    print $fh "        <END_POSITION>";
# 	    print $fh $occurrence->getEndChar;
# 	    print $fh "</END_POSITION>\n";
# 	    print $fh "        </OCCURRENCE>\n";
# 	}
# 	print $fh "      </LIST_OCCURRENCES>\n";
# 	print $fh "      <TERM_CONFIDENCE>" . $term_candidate->getReliability . "</TERM_CONFIDENCE>\n"; 
# 	print $fh "      <TERM_WEIGHTS>\n";
# 	foreach my $weight ($term_candidate->getWeightNames) {
# 	    print $fh "            <WEIGHT name=\"$weight\">";
# 	    print $fh $term_candidate->getWeight($weight);
# 	    print $fh "</WEIGHT>\n";
# 	}
# 	print $fh "      </TERM_WEIGHTS>\n"; 

	# islands of reliability
# 	if(
# 	    ($term_candidate->isa('Lingua::YaTeA::MultiWordTermCandidate'))
# 	    &&
# 	    ($term_candidate->containsIslands)
# 	    )
# 	{
# 	    print $fh "      <LIST_RELIABLE_ANCHORS>\n";
# 	    foreach $island (@{$term_candidate->getIslands})
# 	    {
# 		print $fh "        <RELIABLE_ANCHOR>\n";
# 		if($island->isa('Lingua::YaTeA::TermCandidate'))
# 		{
# 		    print $fh "          <ID>term";
# 		    print $fh $island->getID;
# 		}
# 		else
# 		{
# 		    print $fh "          <ID>testified_term";
# 		    print $fh $island->getID;
# 		}
# 		print $fh "</ID>\n";
# 		print $fh "          <FORM>";
# 		$if = $island->getIF;
# 		Lingua::YaTeA::XMLEntities::encode($if);
# 		print $fh $if;
# 		print $fh "</FORM>\n";
# 		print $fh "          <ORIGIN>";
# 		print $fh $island->getIslandType;
# 		print $fh "</ORIGIN>\n";
# 		print $fh "        </RELIABLE_ANCHOR>\n";
# 	    }
# 	    print $fh "      </LIST_RELIABLE_ANCHORS>\n";
# 	}
# 	print $fh "      <LOG_INFORMATION>YaTeA</LOG_INFORMATION>\n";
	if ((blessed($term_candidate)) && ($term_candidate->isa('Lingua::YaTeA::MultiWordTermCandidate')))
	{
# 	    print $fh "      <SYNTACTIC_ANALYSIS>\n";
#	    print $fh "        <HEAD>\n        term";
	    print $fh $term_candidate->getRootHead->getID;
# 	    print $fh "\n        </HEAD>\n";
	    print $fh " -- ";
# 	    print $fh $term_candidate->getModifierPosition;	
	    print $fh $term_candidate->getRootModifier->getID;
	    print $fh "[label=\"Head / Modifier\" color=\"black\" weight=1]\n";

	    print $fh $term_candidate->getID ;
	    print $fh " -- ";
	    print $fh $term_candidate->getRootHead->getID;
	    print $fh "[label=\"Term / Head\" color=\"black\" weight=3]\n";

	    print $fh $term_candidate->getID ;
	    print $fh " -- ";
	    print $fh $term_candidate->getRootModifier->getID;
	    print $fh "[label=\"Term / Modifier\" color=\"black\" weight=3]\n";

# 	    print $fh "\n        </MODIFIER>\n";
# 	    if(defined $term_candidate->getPreposition)
# 	    {
# 		print $fh "        <PREP>\n        ";
# 		print $fh $term_candidate->getPreposition->getIF;
# 		print $fh "\n        </PREP>\n";
# 	    }
# 	    if(defined $term_candidate->getDeterminer)
# 	    {
# 		print $fh "        <DETERMINER>\n        ";
# 		print $fh $term_candidate->getDeterminer->getIF;
# 		print $fh "\n        </DETERMINER>\n";
# 	    }
# 	    print $fh "      </SYNTACTIC_ANALYSIS>\n";
 	}
# 	print $fh "    </TERM_CANDIDATE>\n";
    }
#     print $fh "  </LIST_TERM_CANDIDATES>\n";
    

}



sub print
{
    my ($this,$fh) = @_;
    my $phrase;
      if(!defined $fh)
    {
	$fh = "STDOUT";
    }
    foreach $phrase (values(%{$this->getPhrases}))
    {
	print $fh "$phrase\n";
	$phrase->print($fh);
	print $fh "\n";
    }
}


sub printPhrases
{
    my ($this,$fh) = @_;
    my $phrase;
    
    if(!defined $fh)
    {
	$fh = \*STDERR;
    }
#    binmode($fh,":utf8");

    foreach $phrase (values(%{$this->getPhrases}))
    {
	$phrase->print($fh);
	print $fh "\n-----------------\n\n";
    }
}

sub printChunkingStatistics
{
    my ($this,$message_set,$display_language) = @_;
    print STDERR "\t" . $message_set->getMessage('PHRASES_NUMBER')->getContent($display_language) . $Lingua::YaTeA::Phrase::counter . "\n";
    print STDERR "\t  -" . $message_set->getMessage('MULTIWORDPHRASES_NUMBER')->getContent($display_language) . $Lingua::YaTeA::MultiWordPhrase::counter . "\n";
    print STDERR "\t  -" . $message_set->getMessage('MONOLEXICALPHRASES_NUMBER')->getContent($display_language) . $Lingua::YaTeA::MonolexicalPhrase::counter . "\n";
}

sub printParsingStatistics
{
    my ($this,$message_set,$display_language) = @_;
    print STDERR "\t" . $message_set->getMessage('PARSED_PHRASES_NUMBER')->getContent($display_language) . $Lingua::YaTeA::MultiWordPhrase::parsed . "\n";
}

1;

__END__

=head1 NAME

Lingua::YaTeA::PhraseSet - Perl extension for ???

=head1 SYNOPSIS

  use Lingua::YaTeA::PhraseSet;
  Lingua::YaTeA::PhraseSet->();

=head1 DESCRIPTION


=head1 METHODS


=head2 new()


=head2 recordOccurrence()


=head2 addPhrase()


=head2 getPhrases()


=head2 giveAccess()


=head2 searchFromIF()


=head2 searchFromLF()


=head2 addToUnparsed()


=head2 addToUnparsable()


=head2 getUnparsed()


=head2 sortUnparsed()


=head2 parseProgressively()


=head2 updateRecord()


=head2 getUnparsable()


=head2 getIFaccess()


=head2 addTermCandidates()


=head2 adjustMonolexicalPhrasesSet()


=head2 getTermCandidates()


=head2 printTermList()


=head2 printUnparsable()


=head2 printUnparsed()


=head2 printTermCandidatesTTG()


=head2 printTermCandidatesXML()


=head2 print()


=head2 printPhrases()


=head2 printChunkingStatistics()


=head2 printParsingStatistics()


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
