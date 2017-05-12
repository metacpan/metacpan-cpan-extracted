package Lingua::Ogmios::NLPWrappers::LexicalSyntacticPatterns;


our $VERSION='0.1';

use Data::Dumper;

use Lingua::Ogmios::NLPWrappers::Wrapper;

use strict;
use warnings;

our @ISA = qw(Lingua::Ogmios::NLPWrappers::Wrapper);

sub new {
    my ($class, $config, $tmpfile_prefix, $logfile, $position, $no_standard_output) = @_;

    my $resourcename;
    my $lang;
    my $lang2;

    warn "[LOG]    Creating a wrapper of the LexicalSyntacticPatterns\n";

    my $LexicalSyntacticPatterns = $class->SUPER::new($config, $tmpfile_prefix, $logfile, $position, $no_standard_output);

    $LexicalSyntacticPatterns->_input_filename($tmpfile_prefix . ".LexicalSyntacticPatterns.in");
    $LexicalSyntacticPatterns->_output_filename($tmpfile_prefix . ".LexicalSyntacticPatterns.out");
    $LexicalSyntacticPatterns->_input_hash({'sentences' => undef});

    $LexicalSyntacticPatterns->_addedElements_array([]);

    foreach $lang (keys %{$LexicalSyntacticPatterns->_config->configuration->{'RESOURCE'}}) {
	if ($lang =~ /language=([\w]+)/io) {
	    $lang2 = $1;
	    # if (defined $LexicalSyntacticPatterns->_config->configuration->{'RESOURCE'}->{$lang}->{"PATTERNS"}) {
	    foreach $resourcename (keys %{$LexicalSyntacticPatterns->_config->configuration->{'RESOURCE'}->{$lang}}) {
		warn "*** $resourcename\n";
		$LexicalSyntacticPatterns->addResource($lang2, $resourcename, $LexicalSyntacticPatterns->_config->configuration->{'RESOURCE'}->{$lang}->{$resourcename});
	    }

		# $LexicalSyntacticPatterns->{'PATTERNS'}->{$lang2} = $LexicalSyntacticPatterns->_config->configuration->{'RESOURCE'}->{$lang}->{"PATTERNS"};
	    # } else {
	    # 	warn "*** SENTENCESEPARATORCHARLIST is not set ***\n";
	    # }
	}
    }


    return($LexicalSyntacticPatterns);

}

sub _processLexicalSyntacticPatterns {
    my ($self) = @_;
    my $lang;
    my $pattern;
    my $sentence;
    my $term1;
    my $term2;
    my @terms1;
    my @terms2;
    my $document;
    my $relation;

    warn "[LOG] LexicalSyntacticPatterns\n";

    $lang = $self->_documentSet->[0]->getAnnotations->getLanguage;
    warn "open " . $self->_input_filename . " (2)\n";

    open FILEINPUT, "<:utf8", $self->_input_filename or die "No such file " . $self->_input_filename;

    # open FILEINPUT, "<:utf8", "/home/thierry/Recherche/Projets/2011AIR-REACH/Data/GuidesV2/ogmios.metis.30920.LexicalSyntacticPatterns.in" or die "No such file " . "/home/thierry/Recherche/Projets/2011AIR-REACH/Data/GuidesV2/ogmios.metis.30920.LexicalSyntacticPatterns.in";
    # open FILEINPUT, "<:utf8", "/export/home/limbio/hamon/Research/Projets/2011AIR-REACH/Data/GuidesV2/ogmios.metis.30920.LexicalSyntacticPatterns.in" or die "No such file " . "/export/home/limbio/hamon/Research/Projets/2011AIR-REACH/Data/GuidesV2/ogmios.metis.30920.LexicalSyntacticPatterns.in";

#	$lang = $self->_documentSet->[0]->getAnnotations->getLanguage;

    while ($sentence = <FILEINPUT>) {
	chomp $sentence;
	# warn "--> $sentence\n";
	foreach $pattern (@{$self->{"Resources"}->{$lang}->{"PATTERNS"}->[1]}) {
	    # warn $pattern->{'pattern'} . "\n";
	    # foreach $sentence (@{$self->_input_hash->{'sentences'}}) {
	    if ($sentence =~ m!$pattern->{'pattern'}!) {
		# warn "OK\n";
		# warn $pattern->{'element1'}->{'role'} . ": " . $+{$pattern->{'element1'}->{'ID'}} . "\n";
		# warn $pattern->{'element2'}->{'role'} . ": " . $+{$pattern->{'element2'}->{'ID'}} . "\n";
		if ($pattern->{'element1'}->{'type'} eq "list") {
		    ($document, @terms1) = $self->_extractTermsFromList($lang, $+{$pattern->{'element1'}->{'ID'}});
		} else {
		    ($term1, $document) = $self->_extractInfos($+{$pattern->{'element1'}->{'ID'}});
		    @terms1 = ($term1);
		}
		if ($pattern->{'element2'}->{'type'} eq "list") {
		    ($document, @terms2) = $self->_extractTermsFromList($lang, $+{$pattern->{'element2'}->{'ID'}});
		} else {
		    ($term2, $document) = $self->_extractInfos($+{$pattern->{'element2'}->{'ID'}});
		    @terms2 = ($term2);
		}
		foreach $term1 (@terms1) {
		    foreach $term2 (@terms2) {
			$relation = $self->_addRelation($document, $pattern->{'relation'} . " (" . $pattern->{'element1'}->{'role'} . "-" . $pattern->{'element2'}->{'role'} . ")", [$term1, $term2]);
			if (defined $relation) {
			    # warn "==>" . $relation->getId . " " . $pattern->{'relation'} . "\n";
			    push @{$self->_addedElements_array}, [$relation, $document->getId];
			}
		    }
		}
	    }
	}
    }
    close FILEINPUT;

    warn "[LOG]\n";
}

sub _extractInfos {
    my ($self, $string) = @_;

    my ($IF, $POSTAG, $LM, $ID, $DOCID, $SEMTAG) = split m!/!, $string;
    my $document;
    my $word;
    my $termUnit;

    $document = $self->_documentSet->[$DOCID];
    if ($POSTAG eq "term") {	
	$termUnit = $document->getAnnotations->getSemanticUnitLevel->getElementById($ID);
    } else {
	# creation of term
	$word = $document->getAnnotations->getWordLevel->getElementById($ID);
	$termUnit = Lingua::Ogmios::Annotations::SemanticUnit->newTerm(
	    {'form' => $word->getForm,
	     'refid_word' => $word,
	    });
	$document->getAnnotations->addSemanticUnit($termUnit);

    }
	return($termUnit, $document);


}

sub _extractTermsFromList {
    my ($self, $lang, $list) = @_;
    my $term_pattern = $self->{"Resources"}->{$lang}->{"PATTERNS"}->[2];
    my $term_string;
    my $term;
    my @terms;
    my $document;
    my $docid;

    while($list =~ / ?($term_pattern)/gc) {
#	warn "\t$1\n";
	$term_string = $1;
	($term, $document) = $self->_extractInfos($term_string);
	push @terms, $term;
#	$document = $self->_documentSet->[$docid]
#	print "\t" . &cleanBrillOutput($1) . "\n";
    }
    # warn "(0)$document\n";
    return($document, @terms);
}


sub _inputLexicalSyntacticPatterns {
    my ($self) = @_;

    $self->getTimer->startsLap("making input");
    warn "[LOG] making LexicalSyntacticPatterns input\n";

    $self->_input_hash->{'sentences'} = {};

    warn "open " . $self->_input_filename . "(1)\n";

    open FILEINPUT, ">:utf8", $self->_input_filename or die "No such file " . $self->_input_filename;

    $self->_makeTaggedSentences($self->_input_hash->{'sentences'}, \*FILEINPUT, "/", " ");

    close FILEINPUT;
#    $self->getTimer->_printTimesBySteps;
    
    warn "[LOG] done\n";
}


sub _outputLexicalSyntacticPatterns {
    my ($self) = @_;

    warn "[LOG] . Parsing " . $self->_output_filename . "\n";

    warn "[LOG] done\n";
}

sub printRelations {
    my ($self) = @_;
    my $rel_doc;
    my $docId;
    my $relationId;
    my $relation;
    my $document;
    my $term;

    foreach $rel_doc (@{$self->_addedElements_array}) {
	$relation = $rel_doc->[0];
	$docId = $rel_doc->[1];
	# warn "$docId -- $relation\n";
	$document = $self->getDocumentFromDocId($docId);
#	$relation = $document->getAnnotations->getDomainSpecificRelationLevel->getElementById($relationId);
	print "Doc $docId : " . $relation->getId ;
	foreach $term (@{$relation->list_refid_semantic_unit}) {
	    print " : " .  $term->getForm . " : ";
	    print $self->_getCanonicalForm($term, $document);
	    print " : ";
	    print $self->_getSyntacticCategory($term, $document);
	    # if (!defined $term->canonical_form) {
	    # } else {
	    # 	print $term->canonical_form ;
	    # }
	    print " : " . $term->getId ;
	}
	print " : " . $relation->domain_specific_relation_type . "\n";
    }
}

sub run {
    my ($self, $documentSet) = @_;

    # Set variables according the the configuration

    $self->_documentSet($documentSet);

    if (0 && ($documentSet->[0]->getAnnotations->existsSemanticUnitLevel) && 
	($documentSet->[0]->getAnnotations->getSemanticUnitLevel->existsElementFromIndex("type", "named_entity"))) {
	# warn "Named entities exist in the first document\n";
	# warn "  Assuming that no Named Entity idenfication is required for the current document set\n";
#	return(0);
    } else {
	warn "[LOG] " . $self->_config->comments . " ...     \n";

	$self->_inputLexicalSyntacticPatterns;
	my $command_line = $self->_processLexicalSyntacticPatterns;
	# $self->I2B2NER;

	# Put log information 
	my $information = { 'software_name' => $self->_config->name,
			    'comments' => $self->_config->comments,
			    'command_line' => "",
			    'list_modified_level' => [""],
	};
	$self->_log($information);
    }

#     if ($self->_position eq "last") {
# 	# TODO
    if (($self->_position eq "last") && ($self->_no_standard_output)) {
	warn "print no standard output\n";
	if ($self->_no_standard_output eq "TXT") {
	    $self->printRelations;
	}
    } else {
	$self->_outputLexicalSyntacticPatterns;
    }
#     $self->_outputParsing;

    # Put log information 

    # my $information = { 'software_name' => $self->_config->name,
    # 			'comments' => $self->_config->comments,
    # 			'command_line' => $command_line,
    # 			'list_modified_level' => [''],
    # };
    # $self->_log($information);

#     die "You call the 'rum' method of the wrapper class base\n
#          You should define a 'run' method for your wrapper\n";
    $self->getTimer->_printTimes;
    warn "[LOG] done\n";
}

sub _printTerms1 {
    my ($self) = @_;

    my $document;
    my $sentence;
    my $token;
    my $SemUnit;
    my %TermsNSemF;

    warn "[LOG] . Parsing " . $self->_output_filename . "\n";

    my $sentenceForm;
    foreach $document (@{$self->_documentSet}) {
	foreach $sentence (@{$document->getAnnotations->getSentenceLevel->getElements}) {
	    $sentenceForm =  $sentence->getForm;
	    # warn "$sentenceForm\n";
	    $sentenceForm =~ s/\n//;
	    %TermsNSemF = ();
	    $token = $sentence->refid_start_token;
	    while((defined $token) && ((!defined $token->previous) || (!$token->previous->equals($sentence->refid_end_token)))){
 		if (scalar(@{$document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)}) > 0) {
		    foreach $SemUnit (@{$document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)}) {
			if ($SemUnit->isNamedEntity) {
			    $TermsNSemF{$SemUnit->getForm . "/" . $SemUnit->NEtype}++;
			} elsif (($SemUnit->isTerm) && ($SemUnit->weight("relevance"))) {
			    my $semf = $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $SemUnit->getId)->[0];
			    if (defined $semf) {
				$TermsNSemF{$SemUnit->getForm . "/" . $semf->first_node_first_semantic_category}++;
			    } else {
				$TermsNSemF{$SemUnit->getForm . "/Unknown"}++;
			    }
			}
		    }
		}
		$token = $token->next;
	    }
	    print "$sentenceForm :";
	    if (scalar(keys %TermsNSemF) > 0) {
		print " " . join(", ", keys %TermsNSemF);
	    }
	    print "\n";
	}
    }
    warn "[LOG] done\n";
}

sub _printTerms2 {
    my $self = shift;
    my $encoding = "UTF-8";
    # my $printDocId = shift;

    my $document;
    my $doc_idx;
    my $token;
    my $word;
    my $lemma;
    my $MS_features;
    my $SemUnit;
    my @corpus_in_t;
    my $canonical_form;

    warn "[LOG] printing TreeTagger Like Output\n";

    foreach $document (@{$self->_documentSet}) {
	
	# my @tmp;
	# if ((!defined $printDocId) || ($printDocId)) {
	#     @tmp = ($document->getId, "DOCUMENT", $document->getId);
	#     push @corpus_in_t, \@tmp;
	# }
	$token = $document->getAnnotations->getTokenLevel->getElements->[0];
	while(defined ($token)) {
#	for($doc_idx = 0; $doc_idx < scalar(@{$document->getAnnotations->getTokenLevel->getElements});$doc_idx++) {
# 	    warn "doc_idx: $doc_idx\n";
	    # warn $token->getId . "\n";
#	    $token = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];
	    if (scalar(@{$document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)}) > 0) {
		$SemUnit = $self->_getLargerTerm($document->getAnnotations->getSemanticUnitLevel->getElementByToken($token));
		if ($SemUnit->isNamedEntity) {
		    # my @tmp  = ($SemUnit->getForm, $SemUnit->getId, "term", "");
		    # push @corpus_in_t, \@tmp;

		    if (!defined $SemUnit->canonical_form) {
			$canonical_form = "";
		    } else {
			$canonical_form = $SemUnit->canonical_form;
		    }
		    $self->_addInfosUnit(\@corpus_in_t, {"IF" => $SemUnit->getForm, 
							 "ID" => $SemUnit->getId, 
							 "POSTAG" => "named_entity", 
							 "LM" => $canonical_form, 
							 "SEMTAG" => $SemUnit->NEtype});
		    
		    # } elsif (($SemUnit->isTerm) && ($SemUnit->weight("relevance"))) {
		} elsif ($SemUnit->isTerm) {
		    my $semf = $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $SemUnit->getId)->[0];
		    if (defined $semf) {
			    # my @tmp  = ($SemUnit->getForm, $SemUnit->getId, "term", $semf->first_node_first_semantic_category);
			    # push @corpus_in_t, \@tmp;
			if (!defined $SemUnit->canonical_form) {
			    $canonical_form = "";
			} else {
			    $canonical_form = $SemUnit->canonical_form;
			}
			$self->_addInfosUnit(\@corpus_in_t, {"IF" => $SemUnit->getForm, 
							     "ID" => $SemUnit->getId, 
							     "POSTAG" => "term", 
							     "LM" => $canonical_form, 
							     "SEMTAG" => $semf->first_node_first_semantic_category});
		    } else {
			# my @tmp  = ($SemUnit->getForm, $SemUnit->getId, "term", "");
			# push @corpus_in_t, \@tmp;
			if (!defined $SemUnit->canonical_form) {
			    $canonical_form = "";
			} else {
			    $canonical_form = $SemUnit->canonical_form;
			}
			$self->_addInfosUnit(\@corpus_in_t, {"IF" => $SemUnit->getForm, 
							     "ID" => $SemUnit->getId, 
							     "POSTAG" => "term", 
							     "LM" => $canonical_form, 
							     "SEMTAG" => ""});
		    }
		}
		$token = $SemUnit->end_token;
	    } elsif ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
		$word = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];
		$lemma = $document->getAnnotations->getLemmaLevel->getElementFromIndex("refid_word", $word->getId)->[0];
		$MS_features = $document->getAnnotations->getMorphosyntacticFeaturesLevel->getElementFromIndex("refid_word", $word->getId)->[0];
		my $wordform = $word->getForm;
		$wordform =~ s/[\t\n]/ /gos;
		$wordform =~ s/  +/ /gos;
		
		# my @tmp  = ($wordform, $word->getId, $MS_features->syntactic_category, $lemma->canonical_form);
		# push @corpus_in_t, \@tmp;
		$self->_addInfosUnit(\@corpus_in_t, {"IF" => $wordform, 
						     "ID" => $word->getId, 
						     "POSTAG" => $MS_features->syntactic_category, 
						     "LM" => $lemma->canonical_form, 
						     "SEMTAG" => ""});

		# $doc_idx += $word->getReferenceSize - 1;
 		# $token = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];
		$token = $word->end_token;
		
	    } else {
		if (!($token->isSep)) {
		    # my @tmp = ($token->getContent, $token->getId, $token->getContent, $token->getContent);
		    # push @corpus_in_t, \@tmp;
		    $self->_addInfosUnit(\@corpus_in_t, {"IF" => $token->getContent, 
							 "ID" => $token->getId, 
							 "POSTAG" => $token->getContent, 
							 "LM" => $token->getContent, 
							 "SEMTAG" => ""});
		}
	    }
	    if ($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId)) {
		if ($token->isSymb) {
		    if (!($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId))) {
			# my @tmp = ($corpus_in_t[$#corpus_in_t]->[0] , $corpus_in_t[$#corpus_in_t]->[1], "SENT", $corpus_in_t[$#corpus_in_t]->[0]);
			# $corpus_in_t[$#corpus_in_t] = \@tmp;
			$self->_addInfosUnit(\@corpus_in_t, {"IF" => $corpus_in_t[$#corpus_in_t]->[0], 
							     "ID" => $corpus_in_t[$#corpus_in_t]->[1],
							     "POSTAG" => "SENT", 
							     "LM" => $corpus_in_t[$#corpus_in_t]->[0], 
							     "SEMTAG" => ""});
		    } else {
			# my @tmp = ($token->getContent, $token->getId, "SENT", $token->getContent);
			# push @corpus_in_t, \@tmp;
			$self->_addInfosUnit(\@corpus_in_t, {"IF" => $token->getContent, 
							     "ID" => $token->getId, 
							     "POSTAG" => "SENT", 
							     "LM" => $token->getContent, 
							     "SEMTAG" => ""});
		    }
		} else {
		    my @tmp = (".", $token->getId, "SENT", ".");
		    push @corpus_in_t, \@tmp;
		    $self->_addInfosUnit(\@corpus_in_t, {"IF" => ".", 
							 "ID" => $token->getId, 
							 "POSTAG" => "SENT", 
							 "LM" => ".", 
							 "SEMTAG" => ""});
		}
	    }
	    $token = $token->next;
	}
    }

    # warn "\tOpenning " . $filename . "\n";
    # if ($filename ne "stdout") {
    # 	open $fh_out, ">". $filename or die "can't open " . $filename . "\n";
    # } else {
    # 	$fh_out = \*STDOUT;
    # }

    my $word_ref;
    foreach $word_ref (@corpus_in_t) {

	# if ($word_ref->[0] =~ s/ /_/go) {
	#     $word_ref->[3] =~ s/ /_/go;
	# }
# Encode::encode("iso-8859-1", join("\n",@corpus_in_t), Encode::FB_DEFAULT);
	if ((!defined $encoding) || (uc($encoding) eq "UTF-8")) {
 	    print Encode::encode("UTF-8", join("/",@$word_ref)); # . "\n";
	} else {
	    if ((defined $encoding) && (uc($encoding) eq "LATIN1")) {
# 	print FILE_IN Encode::encode("iso-8859-1", join("\t",@$word_ref), Encode::FB_DEFAULT) . "\n";
		print Encode::encode("iso-8859-1", join("/",@$word_ref)); # . "\n";
	    } else {
		warn "[WRAPPER LOG] Unknown enconding charset\n";
	    }
	}
	print "/";
	if ($word_ref->[1] eq "SENT") {
	    print "\n";
	} else {
	    print " ";
	}
    }

#    close $fh_out;
    warn "[LOG] done\n";
}

sub _printTerms {
    my $self = shift;
    my $encoding = "UTF-8";

    my @sentences;

    warn "[LOG] printing TreeTagger Like Output\n";

#    $self->_makeTaggedSentences(\@sentences);

    print join("\n", @{$self->_input_hash->{'sentences'}}) . "/";
    print "\n";
    warn "[LOG] done\n";
}

sub _makeTaggedSentences1 {
    my $self = shift;
    my $encoding = "UTF-8";
    my $sentences = shift;
    # my $printDocId = shift;

    my $document;
    my $doc_idx;
    my $token;
    my $word;
    my $lemma;
    my $MS_features;
    my $SemUnit;
    my @corpus_in_t;
    my $canonical_form;
    my $taggedSentence;
    my $i;

    warn "[LOG] printing TreeTagger Like Output\n";

    for ($i = 0; $i < scalar(@{$self->_documentSet}); $i++) {
	$document = $self->_documentSet->[$i];
	$token = $document->getAnnotations->getTokenLevel->getElements->[0];
	while(defined ($token)) {
	    if (scalar(@{$document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)}) > 0) {
		$SemUnit = $self->_getLargerTerm($document->getAnnotations->getSemanticUnitLevel->getElementByToken($token));
		if ($SemUnit->isNamedEntity) {
		    if (!defined $SemUnit->canonical_form) {
			$canonical_form = "";
		    } else {
			$canonical_form = $SemUnit->canonical_form;
		    }
		    $self->_addInfosUnit(\@corpus_in_t, {"IF" => $SemUnit->getForm, 
							 "ID" => $SemUnit->getId, 
							 "POSTAG" => "named_entity", 
							 "LM" => $canonical_form, 
							 "SEMTAG" => $SemUnit->NEtype,
							     "DOCID" => $i,
					 });
		    
		} elsif ($SemUnit->isTerm) {
		    my $semf = $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $SemUnit->getId)->[0];
		    if (defined $semf) {
			if (!defined $SemUnit->canonical_form) {
			    $canonical_form = "";
			} else {
			    $canonical_form = $SemUnit->canonical_form;
			}
			$self->_addInfosUnit(\@corpus_in_t, {"IF" => $SemUnit->getForm, 
							     "ID" => $SemUnit->getId, 
							     "POSTAG" => "term", 
							     "LM" => $canonical_form, 
							     "SEMTAG" => $semf->first_node_first_semantic_category,
							     "DOCID" => $i,
					     });
		    } else {
			if (!defined $SemUnit->canonical_form) {
			    $canonical_form = "";
			} else {
			    $canonical_form = $SemUnit->canonical_form;
			}
			$self->_addInfosUnit(\@corpus_in_t, {"IF" => $SemUnit->getForm, 
							     "ID" => $SemUnit->getId, 
							     "POSTAG" => "term", 
							     "LM" => $canonical_form, 
							     "SEMTAG" => "",
							     "DOCID" => $i,
					     });
		    }
		}
		$token = $SemUnit->end_token;
	    } elsif ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
		$word = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];
		$lemma = $document->getAnnotations->getLemmaLevel->getElementFromIndex("refid_word", $word->getId)->[0];
		$MS_features = $document->getAnnotations->getMorphosyntacticFeaturesLevel->getElementFromIndex("refid_word", $word->getId)->[0];
		my $wordform = $word->getForm;
		$wordform =~ s/[\t\n]/ /gos;
		$wordform =~ s/  +/ /gos;
		
		$self->_addInfosUnit(\@corpus_in_t, {"IF" => $wordform, 
						     "ID" => $word->getId, 
						     "POSTAG" => $MS_features->syntactic_category, 
						     "LM" => $lemma->canonical_form, 
						     "SEMTAG" => "",
							     "DOCID" => $i,
					     });

		$token = $word->end_token;
		
	    } else {
		if (!($token->isSep)) {
		    $self->_addInfosUnit(\@corpus_in_t, {"IF" => $token->getContent, 
							 "ID" => $token->getId, 
							 "POSTAG" => $token->getContent, 
							 "LM" => $token->getContent, 
							 "SEMTAG" => "",
							     "DOCID" => $i,
					     });
		}
	    }
	    if ($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId)) {
		if ($token->isSymb) {
		    if (!($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId))) {
			$self->_addInfosUnit(\@corpus_in_t, {"IF" => $corpus_in_t[$#corpus_in_t]->[0], 
							     "ID" => $corpus_in_t[$#corpus_in_t]->[1],
							     "POSTAG" => "SENT", 
							     "LM" => $corpus_in_t[$#corpus_in_t]->[0], 
							     "SEMTAG" => "",
							     "DOCID" => $i,
					     });
		    } else {
			$self->_addInfosUnit(\@corpus_in_t, {"IF" => $token->getContent, 
							     "ID" => $token->getId, 
							     "POSTAG" => "SENT", 
							     "LM" => $token->getContent, 
							     "SEMTAG" => "",
							     "DOCID" => $i,
					     });
		    } 
		} else {
		    my @tmp = (".", $token->getId, "SENT", ".");
		    push @corpus_in_t, \@tmp;
		    $self->_addInfosUnit(\@corpus_in_t, {"IF" => ".", 
							 "ID" => $token->getId, 
							 "POSTAG" => "SENT", 
							 "LM" => ".", 
							 "SEMTAG" => "",
							     "DOCID" => $i,
					     });
		}
	    }
	    $token = $token->next;
	}
    }

    warn "open " . $self->_input_filename . "\n";
    open FILEINPUT, ">:utf8", $self->_input_filename or die "No such file " . $self->_input_filename;


    $taggedSentence = "";
    my $word_ref;
    foreach $word_ref (@corpus_in_t) {

	if ((!defined $encoding) || (uc($encoding) eq "UTF-8")) {
	    
 	    $taggedSentence .= Encode::encode("UTF-8", join("/",@$word_ref)); # . "\n";
	} else {
	    if ((defined $encoding) && (uc($encoding) eq "LATIN1")) {
		$taggedSentence .= Encode::encode("iso-8859-1", join("/",@$word_ref)); # . "\n";
	    } else {
		warn "[WRAPPER LOG] Unknown enconding charset\n";
	    }
	}
	$taggedSentence .= "/";
	if ($word_ref->[1] eq "SENT") {
#	    push @$sentences, $taggedSentence;
	    print FILEINPUT "$taggedSentence\n";;
	    $taggedSentence = "";
	} else {
	    $taggedSentence .= " ";
	}
    }
    close FILEINPUT;
    warn "[LOG] done\n";
}



sub addResource {
    my ($self, $lang, $type, $name) = @_;

    warn "Adding " . $name . "\n";

#    $self->{"Resources"}->{$type} = $name;

    # ($frequenciesRE, $FreqType, $I2B2Type)
#    my @tmp = ($name);
    $self->{"Resources"}->{$lang}->{$type} = [$name];
    $self->loadResource($lang, $name, $type);

#    $self->{"NEtypes"}->{$tmp[2]} = $type;
#    warn $self->{"Resources"}->{$type}->[3] . "\n";
    warn "Done\n";
}



sub loadResource {

    my ($self, $lang, $name, $type) = @_;

    my %resource;
    my $line;

    warn "Loadding " . $name . "\n";

    my $cg = new Config::General('-ConfigFile' => $name,
 				   '-InterPolateVars' => 1,
 				   '-InterPolateEnv' => 1,
				   '-CComments' => 0
	);

    %resource = $cg->getall;

    # warn ref($resource{'pattern'}) . "\n";

    # warn Dumper($resource{"pattern"})  . "\n";

    my @patterns;

    if (ref($resource{'pattern'}) eq "ARRAY") {
	push @patterns, @{$resource{'pattern'}};
    }
    if (ref($resource{'pattern'}) eq "HASH") {
	push @patterns, $resource{'pattern'};
    }

    warn "Done\n";

    push @{$self->{"Resources"}->{$lang}->{$type}}, \@patterns, $resource{'term'}, $resource{'termList'}, ; #, lc($resource{'TYPE'}), $resource{'I2B2Type'});

#    return(\@RE, $resource{'TYPE'}, $resource{'I2B2Type'});
}



1;


__END__

=head1 NAME

Lingua::Ogmios::NLPWrappers::??? - Perl extension for ???.

=head1 SYNOPSIS

use Lingua::Ogmios::NLPWrappers::???;

my %config = Lingua::Ogmios::NLPWrappers::???::load_config($rcfile);

$module = Lingua::Ogmios::NLPWrappers::???->new($config{"OPTIONS"}, \%config);

$module->function($corpus);


=head1 DESCRIPTION


=head1 METHODS

=head2 function()

    function($rcfile);

=head1 CONFIGURATION

=over

=item *


=back

=head1 NON STANDARD OUTPUT


=over

=item *


=back

=head1 REQUIRED ANNOTATIONS

=over

=item *


=back


=head1 SEE ALSO


=head1 AUTHORS

Thierry Hamon <thierry.hamon@limsi.fr>

=head1 LICENSE

Copyright (C) 2013 by Thierry Hamon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut

