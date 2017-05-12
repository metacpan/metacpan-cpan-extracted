package Lingua::Ogmios::NLPWrappers::YaTeA;


our $VERSION='0.1';

use Lingua::Ogmios::NLPWrappers::Wrapper;
use Lingua::Ogmios::Annotations::SemanticUnit;
use Lingua::Ogmios::Annotations::SemanticFeatures;
use Lingua::Ogmios::Annotations::Phrase;

use Lingua::Ogmios::Annotations::SyntacticRelation;

use UNIVERSAL;
use Scalar::Util qw(blessed);

use Encode qw(:fallbacks);;

use XML::Entities;

use File::Basename;

# use File::Path 'remove_tree';

use strict;
use warnings;

our @ISA = qw(Lingua::Ogmios::NLPWrappers::Wrapper);

sub new {
    my ($class, $config, $tmpfile_prefix, $logfile, $position, $no_standard_output, $out_stream) = @_;
    
    warn "[LOG]    Creating a wrapper of the " .  $config->comments . "\n";
    
    my $lang;
    my $lang2;
    my $YaTeA = $class->SUPER::new($config, $tmpfile_prefix, $logfile, $position, $no_standard_output, $out_stream);

    if (defined $YaTeA->_config->configuration->{'CONFIG'}) {
	foreach $lang (keys %{$YaTeA->_config->configuration->{'CONFIG'}}) {
	    if ($lang =~ /language=([\w]+)/io) {
		$lang2 = $1;
		# $YaTeA->_setOption($lang2, "ONLY_SYNTACTIC_RELATIONS", "only_synt_rel", 0);
		$YaTeA->_setOption($lang2,"TAGGEDSENTFIELDS", "tagged_sent_fields", "IF:POSTAG:LM:ID:DOCID:SEMTAG");
		$YaTeA->_setOption($lang2,"TAGGEDSENTSEPINFOS", "tagged_sent_sep_infos", "/");
		$YaTeA->_setOption($lang2,"TAGGEDSENTSEPTERMCOMPONENTS", "tagged_sent_sep_term_components", " ");
		$YaTeA->_setOption($lang2,"TAGGEDSENTSEPWORDS", "tagged_sent_sep_words", " ");
		$YaTeA->_setOption($lang2,"TAGGEDSENTSEPSENTENCES", "tagged_sent_sep_sentences", "\n");
		$YaTeA->_setOption($lang2,"TAGGEDSENTSEPSECTIONS", "tagged_sent_sep_sections", "");
	    }
	    $YaTeA->_setGeneralOption("PRINTOUTPUTSECTION", "print_output_section", 0);
	}
    }

 

    $YaTeA->_input_filename($tmpfile_prefix . ".YaTeA.in");
    $YaTeA->_output_filename(dirname($tmpfile_prefix)); # . ".YaTeA.out"); 
    $YaTeA->_output_hash({'phrase_set' => undef});

    unlink($YaTeA->_input_filename);
    
    return($YaTeA);
}

sub _inputYaTeA {
    my ($self) = @_;

    warn "[LOG] Making input\n";

    $self->getTimer->startsLap("making input");
    
    $self->_printTreeTaggerFormatOutput($self->_input_filename);

    $self->getTimer->_printTimesBySteps;
    warn "[LOG] done\n";
}

sub _processYaTeA {
    my ($self, $lang) = @_;
    
    $self->getTimer->startsLap("Term extraction");
    warn "[LOG] " . $self->_config->comments . "\n";

    
    $lang = $self->_documentSet->[0]->getAnnotations->getLanguage;

    my $perlModule = $self->_config->commands($lang)->{PerlModule};

    eval "require $perlModule";
    if ($@) {
 	warn $@ . "\n";
 	die "Problem while loading perlModule $perlModule - Abort\n\n";
    } else {
	$self->getTimer->lapStartUserTimeBySteps;
 	warn "Run term extraction Module $perlModule\n";

	eval "require $perlModule" . "::Corpus";
	if ($@) {
	    warn $@ . "\n";
	    die "Problem while loading perlModule $perlModule - Abort\n\n";
	}
	my $configFile = $self->_config->configFile($lang)->{"YATEACONF"};
	
	warn "Loading $configFile\n";

 	my %config_yatea = Lingua::YaTeA::load_config($configFile);
 	my $yatea = Lingua::YaTeA->new($config_yatea{"OPTIONS"}, \%config_yatea);

	$self->_output_hash({'yatea' => $yatea});
	

	$yatea->getOptionSet->addOption("output-path", $self->_output_filename);

	my $corpus_path = $self->_input_filename;

	my $corpus = Lingua::YaTeA::Corpus->new($corpus_path,$yatea->getOptionSet,$yatea->getMessageSet);

	$self->_output_hash()->{'corpus'} = $corpus;

	my $sentence_boundary = $yatea->getOptionSet->getSentenceBoundary;
	my $document_boundary = $yatea->getOptionSet->getDocumentBoundary;

	$yatea->loadTestifiedTerms(\$Lingua::YaTeA::process_counter,$corpus,$sentence_boundary,$document_boundary,$yatea->getOptionSet->MatchTypeValue,$yatea->getMessageSet,$yatea->getOptionSet->getDisplayLanguage);

	print STDERR $Lingua::YaTeA::process_counter++ . ") " . ($yatea->getMessageSet->getMessage('LOAD_CORPUS')->getContent($yatea->getOptionSet->getDisplayLanguage)) . "\n";

	$corpus->read($sentence_boundary,$document_boundary,$yatea->getFSSet,$yatea->getTestifiedTermSet,$yatea->getOptionSet->MatchTypeValue,$yatea->getMessageSet,$yatea->getOptionSet->getDisplayLanguage, $yatea->getOptionSet->getLanguage);
	
	my $phrase_set = Lingua::YaTeA::PhraseSet->new;

	$self->_output_hash()->{'phrase_set'} = $phrase_set;
	
	print STDERR $Lingua::YaTeA::process_counter++ . ") " . ($yatea->getMessageSet->getMessage('CHUNKING')->getContent($yatea->getOptionSet->getDisplayLanguage)) . "\n";

	$corpus->chunk($phrase_set,$sentence_boundary,$document_boundary,$yatea->getChunkingDataSet,$yatea->getFSSet,$yatea->getTagSet,$yatea->getParsingPatternSet,$yatea->getTestifiedTermSet,$yatea->getOptionSet);
	$phrase_set->printChunkingStatistics($yatea->getMessageSet,$yatea->getOptionSet->getDisplayLanguage);

	$phrase_set->sortUnparsed;
	
	print STDERR $Lingua::YaTeA::process_counter++ . ") " . ($yatea->getMessageSet->getMessage('PARSING')->getContent($yatea->getOptionSet->getDisplayLanguage)) . "\n";
	
 	$phrase_set->parseProgressively($yatea->getTagSet,$yatea->getOptionSet->getParsingDirection,$yatea->getParsingPatternSet,$yatea->getChunkingDataSet,$corpus->getLexicon,$corpus->getSentenceSet,$yatea->getMessageSet,$yatea->getOptionSet->getDisplayLanguage,\*STDERR);
	
 	$phrase_set->addTermCandidates($yatea->getOptionSet);
	$corpus->termWeighting($phrase_set->getTermCandidates,\*STDERR);

	$corpus->termFiltering($phrase_set->getTermCandidates,\*STDERR, $yatea->getOptionSet->getOption("termFiltering")->getValue);
	$corpus->selectOnTermListStyle($phrase_set->getTermCandidates, $yatea->getOptionSet->getTermListStyle,\*STDERR);

 	print STDERR $Lingua::YaTeA::process_counter++ . ") " . ($yatea->getMessageSet->getMessage('RESULTS')->getContent($yatea->getOptionSet->getDisplayLanguage)) . "\n";
	
 	print STDERR "\t-" . ($yatea->getMessageSet->getMessage('DISPLAY_RAW')->getContent($yatea->getOptionSet->getDisplayLanguage)) . "\'". $corpus->getOutputFileSet->getFile('debug')->getPath . "'\n";
 	$phrase_set->printPhrases(FileHandle->new(">" . $corpus->getOutputFileSet->getFile('debug')->getPath));
 	$phrase_set->printUnparsable($corpus->getOutputFileSet->getFile('unparsable'));
 	$phrase_set->printUnparsed($corpus->getOutputFileSet->getFile('unparsed'));
	
	print STDERR "\t-" . ($yatea->getMessageSet->getMessage('DISPLAY_TERM_LIST')->getContent($yatea->getOptionSet->getDisplayLanguage)) . "\'". $corpus->getOutputFileSet->getFile('termList')->getPath . "'\n";
	$phrase_set->printTermList($corpus->getOutputFileSet->getFile('termList'),$yatea->getOptionSet->getTermListStyle, undef, $yatea->getOptionSet->getOption("sorting_weight")->getValue, $yatea->getOptionSet->getOption("termFiltering")->getValue);

	print STDERR "\t-" . ($yatea->getMessageSet->getMessage('DISPLAY_TC_XML')->getContent($yatea->getOptionSet->getDisplayLanguage)) . "\'". $corpus->getOutputFileSet->getFile('candidates')->getPath . "'\n";
	# to remove
#	$phrase_set->printTermCandidatesXML($corpus->getOutputFileSet->getFile("candidates"), $yatea->getTagSet);


	warn "\n";
	$self->getTimer->lapEndUserTimeBySteps;
    }

    $self->getTimer->_printTimesBySteps;
    warn "[LOG]\n";
    return($perlModule);
}

sub _outputParsing {
    my ($self) = @_;

    warn "[LOG] . Parsing output Array\n";

    my $phrase_set = $self->_output_hash()->{'phrase_set'};

    my $term_candidate;
    my $if;
    my $pos;
    my $lf;
    my $term;

    my $oldTermUnitId;

    my $canonical_form;
    my $termUnit;
    my $semanticFeaturesTermUnit;

    my $document;

    my $yatea = $self->_output_hash()->{'yatea'};

    my $tagset = $yatea->getTagSet;

    my %YateaTermOcc2OgmiosSemUnits;
    my $sem_unit_id;

    my $occurrence;

    my $weight;

    my $sent_id;
    my $term_offset;
    my $doc;
    my $token;
    my $word;
    my $sent_offset = 0;
    my $to;
    my $term_content = "";
    my $term_content2;
    my $term2;
    my $token_offset;
    my $phrase;
    my $head_occ;
    my $modifier_occ;
    my $syntacticRelation;

    my %compositeWeights = ('idf' => 1,
			    'tf'  => 1,
			    'tf-idf' => 1,
    );
    my @wperdoc;
    my $eltWperDoc;
    my $docW;
    my $valueW;

    $self->getTimer->startsLap("output Parsing - term recording");

    # if ($self->{"only_synt_rel"}->{$self->_documentSet->[0]->getAnnotations->getLanguage} == 0) {
    foreach $term_candidate (values(%{$phrase_set->getTermCandidates}))
    {
	$self->getTimer->startsLapByCategory('YaTeA');
	($if,$pos,$lf) = $term_candidate->buildLinguisticInfos($tagset);
	$self->getTimer->endsLapByCategory('YaTeA');

#	warn "==> $if : $pos : $lf\n";
	# work around for a yatea bug
	$if =~ s/\' /\'/go;
	$if =~ s/ \- /-/go;

	$self->getTimer->startsLapByCategory('XML::Entities');
	$term = XML::Entities::decode('all',$if);
	$self->getTimer->endsLapByCategory('XML::Entities');

	$self->getTimer->startsLapByCategory('processTerm');
	$canonical_form = $lf;
	$canonical_form =~ s/_/ /go;
	$self->getTimer->endsLapByCategory('processTerm');

	$self->getTimer->startsLapByCategory('weights');
	my %weights_gen;
	foreach $weight ($term_candidate->getWeightNames) {
	    $weights_gen{$weight} = $term_candidate->getWeight($weight);
	}
 	$weights_gen{'relevance'} = ( 1 * $term_candidate->isTerm);
	$self->getTimer->endsLapByCategory('weights');


	foreach $occurrence (@{$term_candidate->getOccurrences})
	{
	    $sent_id = $occurrence->getSentence->getInDocID;
	    $term_offset = $occurrence->getStartChar;
	    $document = $self->_documentSet()->[$occurrence->getDocument->getID ];
	    $doc = $occurrence->getDocument->getID;

	    $self->getTimer->startsLapByCategory('weights');
	    my %weights;
	    foreach $weight (keys %weights_gen) {
		# warn "==> $weight\n";
	    	if (exists $compositeWeights{lc($weight)}) {
	    	    @wperdoc = split /;/, $weights_gen{$weight};
	    	    foreach $eltWperDoc (@wperdoc) {
	    	    	($docW, $valueW) = split /:/, $eltWperDoc;
	    	    	if ($doc == $docW) {
	    	    	    $weights{$weight} = $valueW;
	    	    	}
	    	    }
#	    	    $weights{$weight} = $weights_gen{$weight};
	    	} else {
	    	    $weights{$weight} = $weights_gen{$weight};
	    	}
	    }
	    $self->getTimer->endsLapByCategory('weights');
	    
	    $token = $document->getAnnotations->getSentenceLevel->getElements->[$sent_id - 1]->{'refid_start_token'};

	    $sent_offset = 0;
	    # warn "---> $term_offset\n";
	    while ($sent_offset < $term_offset) {
		# warn "> " . $token->getContent . "\n";
		if ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
		    $word = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];
		    $sent_offset += length($word->getForm) + 1;
		    my @refs =  @{$word->getReference};
		    $token = $refs[$#refs]->next;
		    # warn $word->getForm . " : $sent_offset\n"; 
		} else {
		    if (!($token->isSep)) {
			if ($token->getContent =~ /[\x{2019}\x{2032}']/go) {
			    # warn "-------------\n";
			    $sent_offset--;
			}
			$sent_offset += length($token->getContent) + 1;
		    }
		    $token = $token->next;
		} 
	    }
	    # warn "out : $sent_offset\n";
	    $term_content = "";
	    my @TermTokens;
	    $to = $token->getFrom + length($term);
	    while ((defined $token->next) && ($token->isSep)) {
		$token = $token->next;
		$to = $token->getFrom + length($term);
	    }
	    do  {
		$term_content .= $token->getContent;
		push @TermTokens, $token;
		
		$token = $token->next;
		$term_content2 = $term_content;
		$term_content2 =~ s/_/ /go;
		if ($term_content2 =~ s/([ \n\t]+)/ /go) { $to += length($1);}
		if ($term_content2 =~ s/^( +)//go) {$to += length($1);};
		if ($term_content2 =~ s/([ \n\t]+)$//go) {$to += length($1);}
		$term2 = $term;
		$term2 =~ s/_/ /go;
		
	    } while((defined $token) && ((lc($term_content2) ne lc($term2)) && ($token->getTo <= $to)));


	    $termUnit = $document->getAnnotations->getSemanticUnitLevel->getElementByStartEndTokens($TermTokens[0], $TermTokens[$#TermTokens]);

	    $self->getTimer->startsLapByCategory('creation/branching objects');
	    # warn $termUnit->getForm . "(0 OK - $if)\n";
	    $semanticFeaturesTermUnit = undef;
	    $oldTermUnitId = -1;
	    if (defined $termUnit) {
		# warn "=> " . $termUnit->getForm . " already exists\n";
		if ($termUnit->isNamedEntity) {
		    # Keep it like this for the moment, when have time, convert in Term
		} elsif ($termUnit->isTerm) {
		    # warn $termUnit->getForm . "(0 OK - $if)\n";
		    $oldTermUnitId = $termUnit->getId;
		    # merge weights
		    # %weights
		    # $termUnit->weights
########################################################################
		    if (defined $termUnit->weights) {
			foreach $weight (keys %weights) {
#		    foreach $weight (keys %{$termUnit->weights}) {
			    if (!defined $termUnit->weight($weight)) {
				$termUnit->weight($weight,$weights{$weight});
			    }
			}
			# $weights{'relevance'} = $termUnit->weight("relevance");
			# $termUnit->weights(\%weights);
		    }
		    if ((defined $canonical_form) && (!defined $termUnit->canonical_form)) {$termUnit->canonical_form($canonical_form)};
		}
		$YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$occurrence->getID}->{'documentID'} = $occurrence->getDocument->getID;
		$YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$occurrence->getID}->{'offset_shift'} = $sent_offset;
		$YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$occurrence->getID}->{'sentence'} = $sent_id;
		$YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$occurrence->getID}->{'type'} = $termUnit->reference_name;
		if ($termUnit->reference_name eq 'list_refid_token') {
		    $YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$occurrence->getID}->{'list_refid_token'} = undef;
		} else { #if ($termUnit->reference_name eq 'refid_word') {
		    $YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$occurrence->getID}->{$termUnit->reference_name} = $termUnit->reference;
		}
		# } elsif ($termUnit->reference_name eq 'refid_phrase'){
		#     $YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$occurrence->getID}->{'refid_phrase'} = $termUnit->reference;
		# } els
		$YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$occurrence->getID}->{'semunit'} = $sem_unit_id;

########################################################################
		# warn "term $term already exists $oldTermUnitId\n";
		# if ($document->getAnnotations->getSemanticFeaturesLevel->existsElementFromIndex("refid_semantic_unit", $termUnit->getId)) {
		#     $semanticFeaturesTermUnit = $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $termUnit->getId)->[0];
		# }
	    } elsif (lc($term_content2) eq lc($term2)) {
		# TODO recode XML entities before sending to the term tagger
		## Word ?
		# warn "*** New term: $term2\n";
		$token_offset = $TermTokens[0];
		my @TermWords;
		do {
		    if ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token_offset->getId)) {
			## search the last word
			push @TermWords, $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token_offset->getId)->[0];
			$token_offset = $TermWords[$#TermWords]->getLastToken;
		    }
		    $token_offset = $token_offset->next;
		} while((defined $token_offset) && ((!defined $TermTokens[$#TermTokens]->next) || ($token_offset->getTo < $TermTokens[$#TermTokens]->next->getTo)));
		

		if ((scalar(@TermTokens) == 0) || (scalar(@TermWords) == 0) ||
		    ((defined $TermTokens[$#TermTokens]->next) && ($TermTokens[$#TermTokens]->getTo != $TermWords[$#TermWords]->getLastToken->getTo))) {
		    @TermWords = ();
		} 

		$YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$occurrence->getID}->{'documentID'} = $occurrence->getDocument->getID;
		$YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$occurrence->getID}->{'offset_shift'} = $sent_offset;
		$YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$occurrence->getID}->{'sentence'} = $sent_id;

#		$self->getTimer->startsLapByCategory('creation/branching objects');

		if (scalar @TermWords == 0) {
		    # term is a token list
		    # if (!defined $termUnit) {
		    $termUnit = Lingua::Ogmios::Annotations::SemanticUnit->newTerm(
			{'form' => $term_content,
			 'list_refid_token' => \@TermTokens,
			 "weights" => \%weights
			});
		    # } else {
		    # 	# warn "term $term already exists. Skip creation\n";
		    # 	$weights{'relevance'} = $termUnit->weight("relevance");
		    # 	$termUnit->weights(\%weights);
		    # 	$semanticFeaturesTermUnit = undef;
		    # }
		    $YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$occurrence->getID}->{'type'} = 'list_refid_token';
		    $YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$occurrence->getID}->{'list_refid_token'} = undef;
		}
		if (scalar @TermWords == 1) {
		    # term is a word
		    # if (defined $termUnit) {
		    # 	if (!$termUnit->isNamedEntity) {
		    # 	    # warn "term $term already exists. remove previous term and merge related information\n";
		    # 	    # warn "\t" . $termUnit->getId . "\n";
		    # 	    # warn $termUnit->getForm . "(OK)\n";
		    # 	    $weights{'relevance'} = $termUnit->weight("relevance");
		    # 	    if (!defined $semanticFeaturesTermUnit) {
		    # 		warn "semantic features not found\n";
		    # 	    }
		    # 	    $document->getAnnotations->delSemanticUnit($termUnit);
		    # 	}
		    # }
		    $termUnit = Lingua::Ogmios::Annotations::SemanticUnit->newTerm(
			{'form' => $term_content,
			 'refid_word' => $TermWords[0],
			 "weights" => \%weights
			});
		    $YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$occurrence->getID}->{'type'} = 'refid_word';
		    $YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$occurrence->getID}->{'refid_word'} = $TermWords[0];
		}
		if (scalar @TermWords > 1) {
		    # term is a phrase
		    $phrase = Lingua::Ogmios::Annotations::Phrase->new(
			{ 'refid_word' => \@TermWords,
			  'form' => $term_content,
			}
			);
		    $document->getAnnotations->addPhrase($phrase);

		    # if (defined $termUnit) {
		    # 	# warn "term $term already exists. remove previous term and merge related information\n";
		    # 	$weights{'relevance'} = $termUnit->weight("relevance");
		    # 	$document->getAnnotations->delSemanticUnit($termUnit);
		    # }

		    $termUnit = Lingua::Ogmios::Annotations::SemanticUnit->newTerm(
			{'form' => $term_content,
			 'refid_phrase' => $phrase,
			 "weights" => \%weights
			});
		    $YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$occurrence->getID}->{'type'} = 'refid_phrase';
		    $YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$occurrence->getID}->{'refid_phrase'} = $phrase;
		}

		if ((defined $canonical_form)  && (!defined $termUnit->canonical_form)) {$termUnit->canonical_form($canonical_form)};
		if (defined $termUnit) {
		    $sem_unit_id = $document->getAnnotations->addSemanticUnit($termUnit);
		    $YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$occurrence->getID}->{'semunit'} = $sem_unit_id;
		}
		# if (defined $semanticFeaturesTermUnit) {
		# 	# warn "reconnect semantic features to the right term $sem_unit_id (old: $oldTermUnitId)\n";
		# 	$document->getAnnotations->getSemanticFeaturesLevel->delElementFromIndex($oldTermUnitId, "refid_semantic_unit", $semanticFeaturesTermUnit);
		# 	$semanticFeaturesTermUnit->refid_semantic_unit($sem_unit_id);
		# 	$document->getAnnotations->getSemanticFeaturesLevel->addElementToIndex($semanticFeaturesTermUnit, "refid_semantic_unit");
		# 	$document->getAnnotations->delSemanticUnit($oldTermUnit);
		# }
	    # }
	    } else {
		# warn "term content ($term_content) doesn't match with the search term $term (term offset: $term_offset : sent_id: $sent_id : doc: $doc -- " . $document->getId . ")\n";
	    }
	    $self->getTimer->endsLapByCategory('creation/branching objects');
	}
    }
    $self->getTimer->_printTimeByCategory(0);
    $self->getTimer->_printTimesBySteps;
    # }
    $self->getTimer->startsLap("output Parsing - syntactic relation recording");
    warn "Add syntactic relations\n";
    # Second foreach to add syntactic relations

    foreach $term_candidate (values(%{$phrase_set->getTermCandidates}))
    {
	($if,$pos,$lf) = $term_candidate->buildLinguisticInfos($tagset);

#    	warn "term: $if\n";
	if((blessed($term_candidate)) &&($term_candidate->isa('Lingua::YaTeA::MultiWordTermCandidate'))) {
	    foreach $occurrence (@{$term_candidate->getOccurrences}) {
		if (exists ($YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$occurrence->getID})) {
		    if (($head_occ = $self->_getOccFromTermOcc($term_candidate->getRootHead->getKey, $phrase_set, $occurrence->getStartChar, $occurrence->getEndChar, $YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}, $YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$occurrence->getID}->{'sentence'})) == -1) {
			warn "Occurrence not found (H)\n";
		    }
# 		    if ($head_occ != -1) {
# 			warn $head_occ->{"documentID"} . "\n";
# 			warn "head_occ: $head_occ\n";
# 			warn "\t" . $head_occ->{$head_occ->{'type'}}->getId . "\n";
# 			warn "\t" . $head_occ->{$head_occ->{'type'}}->getForm . "\n";
# 		    }
# 		$term_refid_head = $YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$head_occ}->{'semunit'};

		    if (($modifier_occ = $self->_getOccFromTermOcc($term_candidate->getRootModifier->getKey, $phrase_set, $occurrence->getStartChar, $occurrence->getEndChar, $YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}, $YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$occurrence->getID}->{'sentence'})) == -1) {
			warn "Occurrence not found (M)\n";
		    }
# 		    if ($modifier_occ != -1) {
# 			warn $modifier_occ->{"documentID"} . "\n";
# 			warn "modifier_occ: $modifier_occ\n";
# 			warn "\t" . $modifier_occ->{$modifier_occ->{'type'}}->getId . "\n";
# 			warn "\t" . $modifier_occ->{$modifier_occ->{'type'}}->getForm . "\n";
# 		    }
# 		$term_refid_modifier = $YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$modifier_occ}->{'semunit'};

		    if (($head_occ == -1) || ($modifier_occ == -1)) {
			warn "head and/or Modifier not found\n";
			warn "\t Term " . $term_candidate->buildLinguisticInfos($tagset) . "\n";
		    } else {
# 			warn "head_occ: $head_occ\n";
# 			warn "\t" . $head_occ->{$head_occ->{'type'}}->getId . "\n";
# 			warn "\t" . $head_occ->{$head_occ->{'type'}}->getForm . "\n";
# 			warn "modifier_occ: $modifier_occ\n";
# 			warn "\t" . $modifier_occ->{$modifier_occ->{'type'}}->getId . "\n";
# 			warn "\t" . $modifier_occ->{$modifier_occ->{'type'}}->getForm . "\n";

			$document = $self->_documentSet->[$head_occ->{"documentID"}];

			# warn $head_occ->{$head_occ->{'type'}} . " == " .  $modifier_occ->{$modifier_occ->{'type'}} . "\n";
			if ((!defined $head_occ->{'type'}) || (!defined $modifier_occ->{'type'}) ||
			    (!exists $head_occ->{$head_occ->{'type'}}) || (!exists $modifier_occ->{$modifier_occ->{'type'}}) ||
			    ($head_occ->{$head_occ->{'type'}} eq "") || ($modifier_occ->{$modifier_occ->{'type'}} eq "") ||
			    ($head_occ->{$head_occ->{'type'}} == $modifier_occ->{$modifier_occ->{'type'}})
			    ) {
			    warn "Something wrong: head and modifier are equals or undefined?\n";
			    warn "\t Term " . $term_candidate->buildLinguisticInfos($tagset) . "\n";
			    next;
			}


# 			warn "Add Head_of\n";
# 			warn $YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$occurrence->getID}->{'type'} . "\n";
# 			warn $head_occ->{'type'} . "\n";
			$syntacticRelation = Lingua::Ogmios::Annotations::SyntacticRelation->new(
			    { 'syntactic_relation_type' => 'Head_of', 
			      $head_occ->{'type'} . '_head' => $head_occ->{$head_occ->{'type'}},
			      $YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$occurrence->getID}->{'type'} . '_modifier' => $YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$occurrence->getID}->{$YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$occurrence->getID}->{'type'}},
			    }
			    );
			$document->getAnnotations->addSyntacticRelation($syntacticRelation);

# 			warn "Add Modifier_of\n";
			$syntacticRelation = Lingua::Ogmios::Annotations::SyntacticRelation->new(
			    { 'syntactic_relation_type' => 'Modifier_of', 
			      $modifier_occ->{'type'} . '_head' => $modifier_occ->{$modifier_occ->{'type'}},
			      $head_occ->{'type'} . '_modifier' => $head_occ->{$head_occ->{'type'}},
			    }
			    );
			$document->getAnnotations->addSyntacticRelation($syntacticRelation);

# 			warn "Add Component_in_modifier_position\n";
			$syntacticRelation = Lingua::Ogmios::Annotations::SyntacticRelation->new(
			    { 'syntactic_relation_type' => 'Component_in_modifier_position', 
			      $modifier_occ->{'type'} . '_head' => $modifier_occ->{$modifier_occ->{'type'}},
			      $YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$occurrence->getID}->{'type'} . '_modifier' => $YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$occurrence->getID}->{$YateaTermOcc2OgmiosSemUnits{$occurrence->getDocument->getID}->{$occurrence->getID}->{'type'}},
			    }
			    );
			$document->getAnnotations->addSyntacticRelation($syntacticRelation);
# 			warn "done\n";
		    }
		}
	    }
	}
    }
    # $document->getAnnotations->getSemanticFeaturesLevel->printIndex("refid_semantic_unit");
    $self->getTimer->_printTimesBySteps;

    warn "[LOG] done\n";
}

sub _getOccFromTermOcc
{
    my ($self, $termKey, $phrase_set, $start_char, $end_char, $ref_YateaTermOcc2OgmiosSemUnits, $sent_id) = @_;

    my @occurrences;
    my $i;
    my $term_candidate = $phrase_set->getTermCandidates->{$termKey};

    @occurrences = @{$term_candidate->getOccurrences};

    $i = 0;
    while (($i<scalar(@occurrences)) && (($sent_id != $occurrences[$i]->getSentence->getInDocID) || ($start_char > $occurrences[$i]->getStartChar) || ($end_char < $occurrences[$i]->getStartChar))) {
	$i++;
    }
#     warn "i: $i\n";

    if ($i < scalar @occurrences) {
	if (defined $ref_YateaTermOcc2OgmiosSemUnits->{$occurrences[$i]->getID}) {
	    return($ref_YateaTermOcc2OgmiosSemUnits->{$occurrences[$i]->getID});
	} else {
	    return(-1);
	}
    }
    return(-1);
}


sub run {
    my ($self, $documentSet) = @_;

    warn "*** TODO: check if the level exists\n";
    # Set variables according the the configuration
    my $output;
    my @no_standard_output;
    $self->_documentSet($documentSet);

    warn "[LOG] " . $self->_config->comments . " ...     \n";

    $self->_inputYaTeA;

    my $command_line = $self->_processYaTeA;

    # warn "===> " . $self->_no_standard_output . "\n";
    # warn "\t" . $self->_position . "\n";

    my $fh = *STDOUT;
    if (defined($self->_out_stream)) {
	$fh = $self->_out_stream;
    }

    if (($self->_position eq "last") && ($self->_no_standard_output)) {
	if (ref($self->_no_standard_output) eq "ARRAY") {
	    # warn $self->_no_standard_output . "\n";
	    @no_standard_output = @{$self->_no_standard_output};
	} else {
	    push @no_standard_output, $self->_no_standard_output;
	}
	foreach $output (@no_standard_output) {
	    warn "print no standard output (" . $output . ")\n";
#	warn $self->_output_hash()->{'yatea'} . "\n";

	    if ($output eq "XML") {
		warn "print XML output\n";
		if ($self->{print_output_section}) {print $fh "==== XML ====\n";}
		$self->_output_hash()->{'phrase_set'}->printTermCandidatesXML("stdout",$self->_output_hash()->{'yatea'}->getTagSet,$fh);
	    }
	    if ($output eq "DOT") {
		warn "print dot output\n";
		if ($self->{print_output_section}) {print $fh "==== DOT ====\n";}
		$self->_output_hash()->{'phrase_set'}->printListTermCandidatesDot($self->_output_hash()->{'yatea'}->getTagSet,$fh);
# 	    $self->_output_hash()->{'phrase_set'}->printTermCandidatesDot2("stdout",$self->_output_hash()->{'yatea'}->getTagSet);
	    }
	    if ($output eq "TOPICDEFINITION") {
		if ($self->{print_output_section}) {print $fh "==== TOPICDEFINITION ====\n";}
		warn "print topic definition : (" . scalar(@{$self->_documentSet()}) . ")\n";
		my $line;
		my @parts;
		my @urls;
		my @ids;
		my $id;
		foreach $line (@{$self->_output_hash()->{'phrase_set'}->getTopicDefinition("all", "autonomy")}) {
# 		warn "$line\n";
# 	    $document = $self->_documentSet()->[$occurrence->getDocument->getID ];
		    @parts = split /:/, $line; # /
		    @ids = split /,/, pop @parts; # /
		    @urls = ();
		    foreach $id (@ids) {
#                      warn "-> $id\n";
#                      warn $self->getDocId2DocIndex->{$id} . "\n";
			push @urls, @{$self->_documentSet()->[$self->getDocId2DocIndex->{$id}]->getAnnotations->getURLs};
		    }
		    print join(":", @parts);
		    print "|";
		    print join(" ", @urls);
		    print "\n";
		}
#	    print "__END__\n";
	    }
	    if ($output eq "HTML") {
		if ($self->{print_output_section}) {print $fh "==== HTML ====\n";}
		$self->_outputParsing;
		$self->HTMLoutput;
	    }
	    if ($output eq "HTML2") {
		if ($self->{print_output_section}) {print $fh "==== HTML2 ====\n";}
		warn "print HTML output\n";
		$self->_output_hash()->{'corpus'}->printCandidatesAndUnparsedInCorpus(
		    $self->_output_hash()->{'phrase_set'}->getTermCandidates,
		    $self->_output_hash()->{'phrase_set'}->getUnparsable,
		    "stdout",
		    $self->_output_hash()->{'yatea'}->getOptionSet->getSentenceBoundary,
		    $self->_output_hash()->{'yatea'}->getOptionSet->getDocumentBoundary,
		    $self->_output_hash()->{'yatea'}->getOptionSet->getOption('COLOR_BLIND'),
		    $self->_output_hash()->{'yatea'}->getOptionSet->getOption('PARSED_COLOR'),
		    $self->_output_hash()->{'yatea'}->getOptionSet->getOption('UNPARSED_COLOR'),
		    );

# 		$self->_output_hash()->{'corpus'}->getOutputFileSet->getFile('candidatesAndUnparsedInCorpus'),

	    }
	    if ($output eq "TXT") {
		if ($self->{print_output_section}) {print $fh "==== TXT ====\n";}
		warn "==> print Text file in $fh\n";
		$self->_output_hash()->{'phrase_set'}->printTermList('stdout',$self->_output_hash()->{'yatea'}->getOptionSet->getTermListStyle,$fh);
	    }
	    if ($output eq "TERMANDHEAD") {
		if ($self->{print_output_section}) {print $fh "==== TERMANDHEAD ====\n";}
		warn "print Term->Head output\n";
		# mininal
		$self->_output_hash()->{'phrase_set'}->printTermAndHeadList('stdout',$self->_output_hash()->{'yatea'}->getOptionSet->getTermListStyle,$fh,undef,undef);
	    }
	    if ($output eq "TERMANDROOTHEAD") {
		# global
		if ($self->{print_output_section}) {print $fh "==== TERMANROOTDHEAD ====\n";}
		warn "print Term->RootHead output\n";
		$self->_output_hash()->{'phrase_set'}->printTermAndRootHeadList('stdout',$self->_output_hash()->{'yatea'}->getOptionSet->getTermListStyle,$fh,undef,undef);
	    }
	    if ($output eq "TTG") {
		if ($self->{print_output_section}) {print $fh "==== TTG ====\n";}
		warn "print TTG output\n";
		$self->_output_hash()->{'phrase_set'}->printTermCandidatesTTG('stdout',$self->_output_hash()->{'yatea'}->getOptionSet->getTTGStyle,$fh);
	    }
	    if ($output eq "FFTTG") {
		if ($self->{print_output_section}) {print $fh "==== FFTTG ====\n";}
		warn "print FF and TTG output on oneline\n";
		$self->_output_hash()->{'phrase_set'}->printTermCandidatesFFandTTG('stdout',$self->_output_hash()->{'yatea'}->getOptionSet->getTTGStyle,$self->_output_hash()->{'yatea'}->getTagSet,$fh);
	    }
	    if ($output eq "TermAndComp") {
		if ($self->{print_output_section}) {print $fh "==== TermAndComp ====\n";}
		warn "print Terms and Components on oneline\n";
		$self->_output_hash()->{'phrase_set'}->printTermCandidatesAndComponents('stdout',$self->_output_hash()->{'yatea'}->getOptionSet->getTTGStyle,$fh,$self->_output_hash()->{'yatea'}->getTagSet, undef);
	    }
	    if ($output eq "TAGGEDSENT") {
		if ($self->{print_output_section}) {print $fh "==== TAGGEDSENT ====\n";}
		warn "print Tagged Sentence output\n";
		$self->_outputParsing;
		my $lang = $self->_documentSet->[0]->getAnnotations->getLanguage;
		my @f = split /:/, $self->{"tagged_sent_fields"}->{$lang};
		my $rank = 1;
		my %fields = map { $_ => $rank++; } @f;
		$self->_makeTaggedSentences({}, $fh, $self->{"tagged_sent_sep_infos"}->{$lang}, $self->{"tagged_sent_sep_words"}->{$lang}, $self->{"tagged_sent_sep_sentences"}->{$lang}, $self->{"tagged_sent_sep_sections"}->{$lang}, $self->{"tagged_sent_sep_term_components"}->{$lang}, \%fields);
	    }
	    if ($output eq "TAGGEDSENTREC") {
		if ($self->{print_output_section}) {print $fh "==== TAGGEDSENTREC ====\n";}
		warn "print Tagged Sentence Recursive output\n";
		$self->_outputParsing;
		my $lang = $self->_documentSet->[0]->getAnnotations->getLanguage;
		my @f = split /:/, $self->{"tagged_sent_fields"}->{$lang};
		my $rank = 1;
		my %fields = map { $_ => $rank++; } @f;
		$self->_makeTaggedSentencesRec({}, $fh, $self->{"tagged_sent_sep_infos"}->{$lang}, $self->{"tagged_sent_sep_words"}->{$lang}, $self->{"tagged_sent_sep_sentences"}->{$lang}, $self->{"tagged_sent_sep_sections"}->{$lang}, $self->{"tagged_sent_sep_term_components"}->{$lang}, \%fields);
	    }
	    if ($output eq "CRFINPUT") {
		warn "print Tagged Sentence output (CRFINPUT)\n";
		$self->_outputParsing;
		$self->_makeTaggedSentences({}, $fh, "\t", "\n");
	    }
	    if ($output eq "QALD") {
		warn "print Tagged Sentence output (QALD)\n";
		$self->_outputParsing;
		$self->_QALDoutput(\*STDOUT);
	    }
	}
    } else {
#   	$self->_output_hash()->{'phrase_set'}->printTermCandidatesXML("stderr",$self->_output_hash()->{'yatea'}->getTagSet);
	$self->_outputParsing;
    }
#     # Put log information 
    my $information = { 'software_name' => $self->_config->name,
			'comments' => $self->_config->comments,
			'command_line' => $command_line,
			'list_modified_level' => ['phrase_level', 'semantic_unit_level', 'syntactic_relation_level'],
    };
    $self->_log($information);

    $self->getTimer->_printTimes;
    $self->getTimer->_printTimesInLine($self->_config->name);

    warn "[LOG] done\n";
}

sub _makeCRFINPUT {
    my ($self, $fh) = @_;

    my $phrase_set = $self->_output_hash()->{'phrase_set'};

    my $term_candidate;
    my $if;
    my $pos;
    my $lf;
    my $term;
    my $occurrence;
    my $sent_id;
    my $term_offset;
    my $doc;
    my $token;
    my $word;
    my $sent_offset = 0;
    my $to;
    my $term_content = "";
    my $term_content2;
    my $document;
    my $yatea = $self->_output_hash()->{'yatea'};
    my $tagset = $yatea->getTagSet;
    my $term2;
    my $termUnit;

    foreach $term_candidate (values(%{$phrase_set->getTermCandidates})) {
	($if,$pos,$lf) = $term_candidate->buildLinguisticInfos($tagset);

    	warn "term: $if\n";
	$term = XML::Entities::decode('all',$if);
    	warn "term: $if\n";
	foreach $occurrence (@{$term_candidate->getOccurrences}) {
	    if ($occurrence->isMaximal) {
	    $sent_id = $occurrence->getSentence->getInDocID;
	    $term_offset = $occurrence->getStartChar;
	    $document = $self->_documentSet()->[$occurrence->getDocument->getID ];
	    $doc = $occurrence->getDocument->getID;
		warn $occurrence->getStartChar . "\n";
		warn $occurrence->getEndChar . "\n";
	    }
	    $token = $document->getAnnotations->getSentenceLevel->getElements->[$sent_id - 1]->{'refid_start_token'};

	    $sent_offset = 0;
	    # warn "---> $term_offset\n";
	    while ($sent_offset < $term_offset) {
		# warn "> " . $token->getContent . "\n";
		if ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
		    $word = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];
		    $sent_offset += length($word->getForm) + 1;
		    my @refs =  @{$word->getReference};
		    $token = $refs[$#refs]->next;
		    # warn $word->getForm . " : $sent_offset\n"; 
		} else {
		    if (!($token->isSep)) {
			if ($token->getContent =~ /[\x{2019}\x{2032}']/go) {
			    # warn "-------------\n";
			    $sent_offset--;
			}
			$sent_offset += length($token->getContent) + 1;
		    }
		    $token = $token->next;
		} 
	    }
	    # warn "out : $sent_offset\n";
	    $term_content = "";
	    my @TermTokens;
	    $to = $token->getFrom + length($term);
	    while ($token->isSep) {
		$token = $token->next;
		$to = $token->getFrom + length($term);
	    }
	    do  {
		$term_content .= $token->getContent;
		push @TermTokens, $token;
		
		$token = $token->next;
		$term_content2 = $term_content;
		$term_content2 =~ s/_/ /go;
		if ($term_content2 =~ s/([ \n\t]+)/ /go) { $to += length($1);}
		if ($term_content2 =~ s/^( +)//go) {$to += length($1);};
		if ($term_content2 =~ s/([ \n\t]+)$//go) {$to += length($1);}
		$term2 = $term;
		$term2 =~ s/_/ /go;
		
	    } while((defined $token) && ((lc($term_content2) ne lc($term2)) && ($token->getTo <= $to)));

	    warn "EVENT=\"" . $term . "\" " . $TermTokens[0]->getFrom . " " . $TermTokens[$#TermTokens]->getTo . "\n";
#	    $termUnit = $document->getAnnotations->getSemanticUnitLevel->getElementByStartEndTokens($TermTokens[0], $TermTokens[$#TermTokens]);
	}
    }
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

