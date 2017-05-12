package Lingua::Ogmios::NLPWrappers::TermTagger;


our $VERSION='0.1';

use Lingua::Ogmios::NLPWrappers::Wrapper;
use Lingua::Ogmios::Annotations::SemanticUnit;
use Lingua::Ogmios::Annotations::SemanticFeatures;
use Lingua::Ogmios::Annotations::Phrase;

use XML::Entities;

use strict;
use warnings;

our @ISA = qw(Lingua::Ogmios::NLPWrappers::Wrapper);

sub new {
    my ($class, $config, $tmpfile_prefix, $logfile, $position, $no_standard_output) = @_;

    warn "[LOG]    Creating a wrapper of the " .  $config->comments . "\n";


    my $TermTagger = $class->SUPER::new($config, $tmpfile_prefix, $logfile, $position, $no_standard_output);

    my $lang;
    my $lang2;

#     my @tmpin;
#    my @tmpout;

    $TermTagger->_input_hash({});
    $TermTagger->_output_hash({"FF"=>{}, "LM" => {}});
#    $PorterStemmer->_output_array(\@tmpout);

    # if ((defined $TermTagger->_config->configuration->{'CONFIG'}->{"language=EN"}->{"MERGE_TERMS"}) &&
    # 	($TermTagger->_config->configuration->{'CONFIG'}->{"language=EN"}->{"MERGE_TERMS"} == 1)){
    # 	$TermTagger->{"MERGE_TERMS"} = 1;
    # } else {
    # 	$TermTagger->{"MERGE_TERMS"} = 0;
    # }
    if (defined $TermTagger->_config->configuration->{'CONFIG'}) {
	foreach $lang (keys %{$TermTagger->_config->configuration->{'CONFIG'}}) {
	    if ($lang =~ /language=([\w]+)/io) {
		$lang2 = $1;
		# warn "$lang2\n";
		$TermTagger->_setOption($lang2, "EXPAND_TERMS", "EXPAND_TERMS", 0);
		$TermTagger->_setOption($lang2, "MERGE_TERMS", "MERGE_TERMS", 0);
		$TermTagger->_setOption($lang2, "LEMMA", "lemma", 0);
		$TermTagger->_setOption($lang2, "TERMLEMMA", "termLemma", 0);
		if ($TermTagger->{"termLemma"}->{$lang2} != 0) {
		    $TermTagger->{"termLemma"}->{$lang2} = 3;
	        }
		# warn "--> " . $TermTagger->{"termLemma"}->{$lang2} . "\n";
		$TermTagger->_setOption($lang2, "CASE_SENSITIVE", "CaseSensitive", -1);
		$TermTagger->_setOption($lang2, "JOIN_COMPLEX_TERM", "JoinComplexTerm", 0);
		$TermTagger->_setOption($lang2, "TERMLEMMA_MIN_SIZE", "termLemma_min_size", 0);

		$TermTagger->_setOption($lang2, "OUTPUTDIR", "outputdir", undef);

		if (defined $TermTagger->_config->configuration->{'RESOURCE'}->{$lang}->{"SEMANTICTYPES2PRINT"}) {
		    $TermTagger->_loadList($TermTagger->_config->configuration->{'RESOURCE'}->{$lang}->{"SEMANTICTYPES2PRINT"}, $lang2, "SEMANTICTYPES2PRINT");
		}
		
	    }
	}
    } else {
	foreach $lang2 ("EN", "FR") {
		$TermTagger->_setOption($lang2, "EXPAND_TERMS", "EXPAND_TERMS", 0);
		$TermTagger->_setOption($lang2, "MERGE_TERMS", "MERGE_TERMS", 0);
		$TermTagger->_setOption($lang2, "LEMMA", "lemma", 0);
		$TermTagger->_setOption($lang2, "TERMLEMMA", "termLemma", 0);
		if ($TermTagger->{"termLemma"}->{$lang2} != 0) {
		    $TermTagger->{"termLemma"}->{$lang2} = 3;
	        }
		# warn "--> " . $TermTagger->{"termLemma"}->{$lang2} . "\n";
		$TermTagger->_setOption($lang2, "CASE_SENSITIVE", "CaseSensitive", -1);
		$TermTagger->_setOption($lang2, "JOIN_COMPLEX_TERM", "JoinComplexTerm", 0);
		$TermTagger->_setOption($lang2, "TERMLEMMA_MIN_SIZE", "termLemma_min_size", 0);

		$TermTagger->_setOption($lang2, "OUTPUTDIR", "outputdir", undef);

	}
    }
    return($TermTagger);

}

sub _processTermTagger {
    my ($self) = @_;

    my $term_list;
    my $termlist_in;
    my %corpus_index;
    my %lem_corpus_index;
    my %idtrm_select;
    my %lem_idtrm_select;
    my $lang;
#    my %sent_terms;

    warn "[LOG] " . $self->_config->comments . "\n";

    $lang = $self->_documentSet->[0]->getAnnotations->getLanguage;

    warn "Lang: $lang\n";

    my $perlModule = $self->_config->commands($lang)->{PerlModule};

    eval "require $perlModule";
    if ($@) {
	warn $@ . "\n";
	die "Problem while loading perlModule $perlModule - Abort\n\n";
    } else {
	warn "Run term tagging Module $perlModule\n";

	if ((!defined $term_list->{$lang}) || (scalar($term_list->{$lang}->{'termlist'}) == 0)) {
	    # warn $self->_config->commands($lang)->{TERMLIST} . "\n";
	    $term_list->{$lang}->{'termlist'} = [];
	    $term_list->{$lang}->{'termlistIdx'} = {};
	    $term_list->{$lang}->{'regex_termlist'} = [];
	    $term_list->{$lang}->{'regex_lem_termlist'} = [];
	    if (ref($self->_config->commands($lang)->{TERMLIST}) eq "ARRAY") {
		foreach $termlist_in (@{$self->_config->commands($lang)->{TERMLIST}}) {
		    warn "TERMLIST: $termlist_in\n";
		    Alvis::TermTagger::load_TermList($termlist_in, $term_list->{$lang}->{'termlist'},$term_list->{$lang}->{'termlistIdx'});
		}
	    } else {
		    warn "TERMLIST: " . $self->_config->commands($lang)->{TERMLIST} . "\n";
		Alvis::TermTagger::load_TermList($self->_config->commands($lang)->{TERMLIST},$term_list->{$lang}->{'termlist'},$term_list->{$lang}->{'termlistIdx'});
	    }

	    Alvis::TermTagger::get_Regex_TermList($term_list->{$lang}->{'termlist'}, $term_list->{$lang}->{'regex_termlist'}, $term_list->{$lang}->{'regex_lem_termlist'});
	}
 	Alvis::TermTagger::corpus_Indexing($self->_input_hash->{"lc_corpus"}, $self->_input_hash->{"corpus"}, \%corpus_index, $self->{"CaseSensitive"}->{$lang});
 	Alvis::TermTagger::term_Selection(\%corpus_index, $term_list->{$lang}->{'termlist'}, \%idtrm_select, $self->{"CaseSensitive"}->{$lang});
 	Alvis::TermTagger::term_tagging_offset_tab($term_list->{$lang}->{'termlist'}, $term_list->{$lang}->{'regex_termlist'}, \%idtrm_select, $self->_input_hash->{corpus}, $self->_output_hash->{"FF"}, $self->{"CaseSensitive"}->{$lang});
	warn "\tfound " . scalar(keys %{$self->_output_hash->{'FF'}}) . " terms (IF)\n";

	if ($self->{"lemma"}->{$lang} == 1) {
	    # warn "=> " .  $self->{'termLemma'}->{$lang} . "\n";
	    Alvis::TermTagger::corpus_Indexing($self->_input_hash->{"lc_lemmatised_corpus"}, $self->_input_hash->{"lemmatised_corpus"}, \%lem_corpus_index, $self->{"CaseSensitive"}->{$lang});
	    Alvis::TermTagger::term_Selection(\%lem_corpus_index, $term_list->{$lang}->{'termlist'}, \%lem_idtrm_select, $self->{"CaseSensitive"}->{$lang}, $self->{'termLemma'}->{$lang});
	    Alvis::TermTagger::term_tagging_offset_tab($term_list->{$lang}->{'termlist'}, $term_list->{$lang}->{'regex_lem_termlist'}, \%lem_idtrm_select, $self->_input_hash->{"lemmatised_corpus"}, $self->_output_hash->{"LM"}, $self->{"CaseSensitive"}->{$lang}, $self->{'termLemma'}->{$lang});
	    warn "\tfound " . scalar(keys %{$self->_output_hash->{'LM'}}) . " terms (LM)\n";
	}
    }
    warn "[LOG]\n";
    return($perlModule);
}

sub _inputTermTagger {
    my ($self) = @_;

    my $token;
    my $next_token;
    my $document;

    my $doc_sent_idx;
    my $sentence;

    my @docs_sent_offset;

    my @corpus_in_t;

    my %corpus;
    my %lc_corpus;
    my %lemmatised_corpus;
    my %lemmatised_corpus_offsets;
    my %lc_lemmatised_corpus;

    my $tokens;
    my $sentForm;

    my $word;
    warn "[LOG] making input\n";
    
    my $sent_offset = 0;

    foreach $document (@{$self->_documentSet}) {
 	for($doc_sent_idx = 0; $doc_sent_idx < scalar(@{$document->getAnnotations->getSentenceLevel->getElements});$doc_sent_idx++) {
	    $sentence = $document->getAnnotations->getSentenceLevel->getElements->[$doc_sent_idx];

	    # warn "Sentence: " . $sentence->getForm . "\n";
	    $corpus{$doc_sent_idx + $sent_offset} = XML::Entities::decode('all', $sentence->getForm);
	    $corpus{$doc_sent_idx + $sent_offset} =~ s/[\x{A0}\x{2000}-\x{200B}]/ /go;
	    $corpus{$doc_sent_idx + $sent_offset} =~ s/[\x{2019}]/'/go;
	    $lc_corpus{$doc_sent_idx + $sent_offset} = lc($corpus{$doc_sent_idx + $sent_offset});
	    if ($self->{"lemma"}->{$document->getAnnotations->getLanguage} == 1) {
		# warn "[LOG] Identification of term lemma\n";
		($sentForm, $tokens) = $self->_getLemmatisedSentence($document, $sentence->start_token, $sentence->end_token);
		# warn "  Lemmatized sentence:$sentForm\n";
		$lemmatised_corpus{$doc_sent_idx + $sent_offset} = XML::Entities::decode('all', $sentForm);
		$lemmatised_corpus{$doc_sent_idx + $sent_offset} =~ s/[\x{A0}\x{2000}-\x{200B}]/ /go;
		$lemmatised_corpus{$doc_sent_idx + $sent_offset} =~ s/[\x{2019}]/'/go;
		$lemmatised_corpus_offsets{$document->getId . "_" .$sentence->getId} = [$sentForm, $tokens];
		$lc_lemmatised_corpus{$doc_sent_idx + $sent_offset} = lc($lemmatised_corpus{$doc_sent_idx + $sent_offset});
	    }
	}
	$sent_offset += scalar(@{$document->getAnnotations->getSentenceLevel->getElements});

	push @docs_sent_offset, {"offset" => $sent_offset, #scalar(@{$document->getAnnotations->getSentenceLevel->getElements}),
				 "document" => $document,
	                        };
#	warn "[LOG] next sentence\n";
    }
    $self->_input_hash->{'corpus'} = \%corpus;
    $self->_input_hash->{'lc_corpus'} = \%lc_corpus;
    if ($self->{"lemma"}->{$self->_documentSet->[0]->getAnnotations->getLanguage} == 1) {
	$self->_input_hash->{'lemmatised_corpus'} = \%lemmatised_corpus;
	$self->_input_hash->{'lemmatised_corpus_offsets'} = \%lemmatised_corpus_offsets;
	$self->_input_hash->{'lc_lemmatised_corpus'} = \%lc_lemmatised_corpus;
    }
    $self->_input_hash->{'docs_sent_offset'} = \@docs_sent_offset;

    warn "[LOG] done\n";
}

sub getDocumentFromInputHash {
    my ($self, $sent_id) = @_;

    my $document;
    my $i = 0;
    while(($i < scalar(@{$self->_input_hash->{'docs_sent_offset'}})) && ($$sent_id > $self->_input_hash->{'docs_sent_offset'}->[$i]->{'offset'} - 1)) {
	$i++;
    }
    if ($i > 0) {
	$$sent_id -= $self->_input_hash->{'docs_sent_offset'}->[$i - 1]->{'offset'}
    }
    if ($i < scalar(@{$self->_input_hash->{'docs_sent_offset'}})) {
	$document = $self->_input_hash->{'docs_sent_offset'}->[$i]->{'document'};
    }
    return($document);
}

sub _outputParsing {
    my ($self) = @_;

     warn "[LOG] . Parsing output Array\n";

    my $key;
    my $sent_id;
    my $term;
    my $canonical_form;
    my $semtag;
    my $semtags;
    my $document;
    my $term_offset;
    my $i;
    my $sentence;

    my $offset;

    my $sentTokens;
    my $tokens;
    my $token;
    my $sentForm;

    my $termUnit;    
    my $semFeatures;

    my $lang = $self->_documentSet->[0]->getAnnotations->getLanguage;
    my $decoded_sentence;

    warn "[LOG] Number of identified terms: " . scalar((keys %{$self->_output_hash->{'FF'}})) . "\n";

    $self->getTimer->startsLap("output parsing");
    for $key (keys %{$self->_output_hash->{'FF'}}) {
	$self->getTimer->lapStartUserTimeBySteps;
	# $self->getTimer->startsLapByCategory('Setting');
	$sent_id = $self->_output_hash->{'FF'}->{$key}->[0];
	$term = $self->_output_hash->{'FF'}->{$key}->[1];
        $canonical_form = $self->_output_hash->{'FF'}->{$key}->[2];
        $semtags = $self->_output_hash->{'FF'}->{$key}->[3];
#	$term = $self->_output_hash->{'LM'}->{$key}->[scalar(@{$self->_output_hash->{'FF'}->{$key}})-1];
	# warn "\n>> $key / $term (FF) : $canonical_form : $semtags\n";

	$document = $self->getDocumentFromInputHash(\$sent_id);
	$decoded_sentence = XML::Entities::decode('all', $document->getAnnotations->getSentenceLevel->getElements->[$sent_id]->getForm);
	# warn "$decoded_sentence\n";
	# $self->getTimer->endsLapByCategory('Setting');
	# $self->getTimer->startsLapByCategory('Matching');
	# $self->getTimer->startsLapByCategory($term);
	while(((($self->{"CaseSensitive"}->{$lang} == 0) || (length($term) <= $self->{"CaseSensitive"}->{$lang})) && 
	       ($decoded_sentence =~ /\b\Q$term\E\b?/gc)) ||
	      ((($self->{"CaseSensitive"}->{$lang} < 0) || (length($term) > $self->{"CaseSensitive"}->{$lang})) && ($decoded_sentence =~ /\b\Q$term\E\b?/igc))) { # replace regex by index/subtring ?
	    # warn "ok\n";
	    $term_offset = length($`);
	    $offset = $term_offset + $document->getAnnotations->getSentenceLevel->getElements->[$sent_id]->{'refid_start_token'}->getFrom;
	    $token = undef;
	    if ($document->getAnnotations->getTokenLevel->existsElementFromIndex("from", $offset )) {
		$tokens = $document->getAnnotations->getTokenLevel->getElementFromIndex("from", $offset );
		my $term_content = "";
		my @TermTokens;
		if (defined $tokens) {
		    $token = $tokens->[0];
		    # warn $token->getId . "\n";
		    if ((!$document->getAnnotations->getSemanticUnitLevel->existsElementFromIndex("list_refid_token", $token->getId)) ||
			(!$document->getAnnotations->getSemanticUnitLevel->getElementFromIndex("list_refid_token", $token->getId)->[0]->isNamedEntity)) {
			# $self->getTimer->startsLapByCategory("getTo token ($term)");
			my $to = $token->getFrom + length($term);
			do  {
			    $term_content .= $token->getContent;
			    push @TermTokens, $token;
			    $token = $token->next;
			} while((defined $token) && ($token->getTo < $to));
			# $self->getTimer->endsLapByCategory("getTo token ($term)");
			# $self->getTimer->startsLapByCategory("Remaining ($term)");
			
			# TODO recode XML entities before sending to the term tagger
			# if (((($self->{"CaseSensitive"}->{$lang} == 0) || (length($term) <= $self->{"CaseSensitive"}->{$lang})) && 
			#    	 ($term_content eq $term)) ||
			# 	(lc($term_content) eq lc($term))) {

			# ($self->{"CaseSensitive"}->{$lang} == 0) && (lc($term_content) eq lc($term)) ||
			# 	((length($term) <= $self->{"CaseSensitive"}->{$lang}) && ($term_content eq $term))

			if (((($self->{"CaseSensitive"}->{$lang} == 0) || (length($term) <= $self->{"CaseSensitive"}->{$lang})) && 
			     ($term_content eq $term)) ||
			    ((($self->{"CaseSensitive"}->{$lang} < 0) || (length($term) > $self->{"CaseSensitive"}->{$lang})) && (lc($term_content) eq lc($term)))) {
			# $self->getTimer->startsLapByCategory("CreateTerms ($term)");
			    $termUnit = $self->_createTerm($document, \@TermTokens, $term_content);
			# $self->getTimer->endsLapByCategory("CreateTerms ($term)");

			# $self->getTimer->startsLapByCategory("Remaining2 ($term)");
			# $self->getTimer->startsLapByCategory("Canonical Form ($term)");
			    if ((defined $canonical_form) && ($canonical_form ne "")) {
				$termUnit->canonical_form($canonical_form)
			    };
			# $self->getTimer->endsLapByCategory("Canonical Form ($term)");
			# $self->getTimer->startsLapByCategory("Weight And Add SemUnit ($term)");
			    if (defined $termUnit) {
				# warn "\tAdd $term\n";
				# warn "\t    " . $termUnit->getForm . "\n";
				my %weights = ('relevance' => 2);
				$termUnit->weights(\%weights);
				$document->getAnnotations->addSemanticUnit($termUnit);
			    }
			# $self->getTimer->endsLapByCategory("Weight And Add SemUnit ($term)");
			# $self->getTimer->startsLapByCategory("semantic Features ($term)");
			    if (defined $semtags) {
				$semFeatures = $self->_createSemanticFeaturesFromString($semtags, $termUnit->getId);
				if (defined $semFeatures) {
				    $document->getAnnotations->addSemanticFeatures($semFeatures);
				}
			    }
			# $self->getTimer->endsLapByCategory("semantic Features ($term)");
			# $self->getTimer->endsLapByCategory("Remaining2 ($term)");
			    # if (defined $semtags) {
			    # 	foreach $semtag (split /;/, $semtags) {
			    # 	    # warn "\t$semtag\n";
			    # 	    my @semtags = split /\//, $semtag;
			    # 	    my @list_semtags;
			    # 	    push @list_semtags, \@semtags;
			    # 	    # TODO Check if the semtag already exists in order to avoid to create one another?
			    # 	    $semFeatures = Lingua::Ogmios::Annotations::SemanticFeatures->new(
			    # 		{ 'semantic_category' => \@list_semtags,
			    # 		  'refid_semantic_unit' => $termUnit->getId,
			    # 		});
			    # 	    $document->getAnnotations->addSemanticFeatures($semFeatures);
			    # 	}
			    # }
			# $self->getTimer->endsLapByCategory("Remaining ($term)");
			} else {
			    warn "term content ($term_content) doesn't match with the search term\n";
			}
		    } else {
			warn "Term in NE\n";
		    }
		}
	    } else {
		warn "term $term not found\n";
	    }
	# $self->getTimer->endsLapByCategory($term);
	#     $self->getTimer->endsLapByCategory('Matching');
	}
	$self->getTimer->lapEndUserTimeBySteps;
    }
    # $self->getTimer->_printTimeByCategory(0);
    # $self->getTimer->_printTimesBySteps;

    if ($self->{"termLemma"}->{$lang} != 0) {
	warn "with termLemma\n";
	for $key (keys %{$self->_output_hash->{'LM'}}) {
	    $self->getTimer->lapStartUserTimeBySteps;
	    $sent_id = $self->_output_hash->{'LM'}->{$key}->[0];
	    # $term = $self->_output_hash->{'LM'}->{$key}->[4];
	    $term = $self->_output_hash->{'LM'}->{$key}->[scalar(@{$self->_output_hash->{'LM'}->{$key}})-1];
	    warn "$term\n";
	    if (length($term) >= $self->{'termLemma_min_size'}->{$lang}) { 
		$canonical_form = $self->_output_hash->{'LM'}->{$key}->[2];
		$semtags = $self->_output_hash->{'LM'}->{$key}->[3];
		# warn "\n>> $key / $term (FF) : $canonical_form : $semtags\n";
		# print STDERR "\t" . $self->_output_hash->{'LM'}->{$key}->[4];
		# print STDERR join(' : ', @{$self->_output_hash->{'LM'}->{$key}}) . "\n";
		$document = $self->getDocumentFromInputHash(\$sent_id);
		
		($sentForm, $sentTokens) = $self->_getLemmatisedSentence($document, 
									 $document->getAnnotations->getSentenceLevel->getElements->[$sent_id]->start_token, 
									 $document->getAnnotations->getSentenceLevel->getElements->[$sent_id]->end_token);
		$decoded_sentence = XML::Entities::decode('all', $sentForm);
		# warn "$decoded_sentence\n";
		while(((($self->{"CaseSensitive"}->{$lang} == 0) || (length($term) <= $self->{"CaseSensitive"}->{$lang})) && 
		       ($decoded_sentence =~ /\b\Q$term\E\b/gc)) ||
		      ((($self->{"CaseSensitive"}->{$lang} < 0) || (length($term) > $self->{"CaseSensitive"}->{$lang})) && ($decoded_sentence =~ /\b\Q$term\E\b/igc))) { # replace regex by index/subtring ?
		    $term_offset = length($`);
		    $offset = $term_offset;
		    $token = $sentTokens->{$offset}->[0];
		    my $to = $sentTokens->{$term_offset + length($term)}->[0];
		    my @TermTokens;
		    my $term_content = "";
		    # warn "to: " . $to->getContent . "\n";
		    if ((defined $token) && (defined $to)) {
			do {
			    # warn "-> " . $token->getContent . "\n";
			    $term_content .= $token->getContent;
			    push @TermTokens, $token;
			    $token = $token->next;
			    
			} while((defined $token) &&($token->getFrom < $to->getFrom));
			# $offset = $term_offset + $document->getAnnotations->getSentenceLevel->getElements->[$sent_id]->{'refid_start_token'}->getFrom;
			# $token = undef;
			# if ($document->getAnnotations->getTokenLevel->existsElementFromIndex("from", $offset )) {
			# 	$tokens = $document->getAnnotations->getTokenLevel->getElementFromIndex("from", $offset );
			# 	my $term_content = "";
			# 	my @TermTokens;
			# 	if (defined $tokens) {
			# 	    $token = $tokens->[0];
			# 	    # warn $token->getId . "\n";
			# 	    if ((!$document->getAnnotations->getSemanticUnitLevel->existsElementFromIndex("list_refid_token", $token->getId)) ||
			# 		(!$document->getAnnotations->getSemanticUnitLevel->getElementFromIndex("list_refid_token", $token->getId)->[0]->isNamedEntity)) {
			# 		my $to = $token->getFrom + length($term);
			# 		do  {
			# 		    $term_content .= $token->getContent;
			# 		    push @TermTokens, $token;
			# 		    $token = $token->next;
			# 		} while((defined $token) && ($token->getTo < $to));

			# TODO recode XML entities before sending to the term tagger
			# if (((($self->{"CaseSensitive"}->{$lang} == 0) || (length($term) <= $self->{"CaseSensitive"}->{$lang})) && 
			#    	 ($term_content eq $term)) ||
			# 	(lc($term_content) eq lc($term))) {

			# ($self->{"CaseSensitive"}->{$lang} == 0) && (lc($term_content) eq lc($term)) ||
			# 	((length($term) <= $self->{"CaseSensitive"}->{$lang}) && ($term_content eq $term))

			# if (((($self->{"CaseSensitive"}->{$lang} == 0) || (length($term) <= $self->{"CaseSensitive"}->{$lang})) && 
			# 	 ($term_content eq $term)) ||
			# 	((($self->{"CaseSensitive"}->{$lang} < 0) || (length($term) > $self->{"CaseSensitive"}->{$lang})) && (lc($term_content) eq lc($term)))) {
			$termUnit = $self->_createTerm($document, \@TermTokens, $term_content);
			# warn "add " . $termUnit->getForm . "\n";

			if ((defined $canonical_form) && ($canonical_form ne "")) {
			    $termUnit->canonical_form($canonical_form)
			};
			if (defined $termUnit) {
			    # warn "\tAdd $term\n";
			    # warn "\t    " . $termUnit->getForm . "\n";
			    my %weights = ('relevance' => 2);
			    $termUnit->weights(\%weights);
			    $document->getAnnotations->addSemanticUnit($termUnit);
			}
			if (defined $semtags) {
			    foreach $semtag (split /;/, $semtags) {
				# warn "\t$semtag\n";
				my @semtags = split /\//, $semtag;
				my @list_semtags;
				push @list_semtags, \@semtags;
				# TODO Check if the semtag already exists in order to avoid to create one another?
				$semFeatures = Lingua::Ogmios::Annotations::SemanticFeatures->new(
				    { 'semantic_category' => \@list_semtags,
				      'refid_semantic_unit' => $termUnit->getId,
				    });
				$document->getAnnotations->addSemanticFeatures($semFeatures);
			    }
			}
			# } else {
			# 	warn "term content ($term_content) doesn't match with the search term\n";
			# }
			# } else {
			#     warn "Term in NE\n";
			# }
			# }
		    } else {
			warn "term $term not found\n";
		    }
		}
	    } else {
		warn "Remove $term (" . length($term) .  ")\n";
		delete($self->_output_hash->{'LM'}->{$key});
	    }
	    $self->getTimer->lapEndUserTimeBySteps;
	}
	
	$self->getTimer->_printTimesBySteps;
	
    } elsif ($self->{"lemma"}->{$lang} == 1) {
    warn "[LOG] Number of identified lemmatised terms: " . scalar((keys %{$self->_output_hash->{'LM'}})) . "\n";

	for $key (keys %{$self->_output_hash->{'LM'}}) {
	    $self->getTimer->lapStartUserTimeBySteps;
	    $sent_id = $self->_output_hash->{'LM'}->{$key}->[0];
#	    $term = $self->_output_hash->{'LM'}->{$key}->[1];
	    $canonical_form = $self->_output_hash->{'LM'}->{$key}->[2];
	    $semtags = $self->_output_hash->{'LM'}->{$key}->[3];
	    # warn "\n>> $key / $term (LM) : $canonical_form\n";
	    $term = $self->_output_hash->{'LM'}->{$key}->[scalar(@{$self->_output_hash->{'LM'}->{$key}})-1];

	    $document = $self->getDocumentFromInputHash(\$sent_id);
	    $sentence = $document->getAnnotations->getSentenceLevel->getElements->[$sent_id];
	    $decoded_sentence = XML::Entities::decode('all', $sentence->getForm);
	    # warn "\t" . $document->getId . "\n";

	    ($sentForm, $tokens) = @{$self->_input_hash->{'lemmatised_corpus_offsets'}->{$document->getId . "_" . $sentence->getId}};
	    $decoded_sentence = XML::Entities::decode('all', $sentForm);

	    while(((($self->{"CaseSensitive"}->{$lang} == 0) || (length($term) <= $self->{"CaseSensitive"}->{$lang})) && 
		   ($decoded_sentence =~ /\b\Q$term\E\b/gc)) ||
		  ((($self->{"CaseSensitive"}->{$lang} < 0)  || (length($term) > $self->{"CaseSensitive"}->{$lang})) && ($decoded_sentence =~ /\b\Q$term\E\b/igc))) { # replace regex by index/subtring ?
	    # while ($decoded_sentence =~ /\b\Q$term\E\b/igc) { # replace regex by index/subtring ?
		my $term_content = "";
		my @TermTokens;
		$term_offset = length($`);
		$token = undef;
		# warn "term_offset: $term_offset\n";
		if (defined $tokens->{$term_offset}) {
		    $token = $tokens->{$term_offset}->[0];
		    # warn $token->getContent . "\n";
		# } else { 
		#     $offset = $term_offset + $document->getAnnotations->getSentenceLevel->getElements->[$sent_id]->{'refid_start_token'}->getFrom;
		#     warn "offset: $offset\n";
		#     if ($document->getAnnotations->getTokenLevel->existsElementFromIndex("from", $offset )) {
		# 	$token = $document->getAnnotations->getTokenLevel->getElementFromIndex("from", $offset )->[0];
		# 	warn $token->getContent . "\n";
		    } else {
			$offset = $term_offset + $document->getAnnotations->getSentenceLevel->getElements->[$sent_id]->{'refid_start_token'}->getFrom;
			# warn "offset: $offset\n";
			if ($document->getAnnotations->getTokenLevel->existsElementFromIndex("from", $offset )) {
			    $token = $document->getAnnotations->getTokenLevel->getElementFromIndex("from", $offset )->[0];
			    # warn "token ID: " . $token->getId . "\n";
			    if ((!$document->getAnnotations->getSemanticUnitLevel->existsElementFromIndex("list_refid_token", $token->getId )) ||
				(!$document->getAnnotations->getSemanticUnitLevel->getElementFromIndex("list_refid_token", $token->getId)->[0]->isNamedEntity)) {
				# warn "Not in NE\n";
				$i = $term_offset;
				while(($i >= 0) && (!defined($tokens->{$i}))) {
				    $i--;
				}
				# warn $tokens->{$i}->[0]->getContent . " ($i)\n";
				my $j = 0;
				$offset = 0;
				while(($j < scalar(@{$tokens->{$i}})) && ($tokens->{$i}->[0]->getFrom  + $offset < $term_offset)) {
				    $offset += length($tokens->{$i}->[$j]->getContent);
				    $j++;
				}
				$token = $tokens->{$i}->[$j];
			    } else {
				$token = undef;
			    }
			} else {
			    $token = undef;
			}
		    }
		# }
		if (defined $token) {
		    my $to;
		    $i = $term_offset + length($term);
		    # warn "length($term): $term_offset + " . length($term) . " ($i)\n";
		    $to=0;
		    while(($i >= 0) && ((!defined($tokens->{$i})) || (scalar(@{$tokens->{$i}}) == 0))) {
			$i--;
		    }
		    # warn "=>i : $i\n";
		    $to = $tokens->{$i}->[scalar(@{$tokens->{$i}}) - 1]->getTo;
		    if ((defined($tokens->{$term_offset + length($term)})) && (scalar(@{$tokens->{$term_offset + length($term)}}) == 0)) {
		    	$to++;
		    }
		    # warn "To: $to\n";
		    # warn "    " . scalar(@{$tokens->{$i}}) . " |" . $tokens->{$i}->[scalar(@{$tokens->{$i}}) - 1]->getContent . "|\n";
		    do {
			$term_content .= $token->getContent;
			push @TermTokens, $token;
			# warn "+ " . $token->getContent . " / $term_content\n";
			$token = $token->next;
			# warn "===> " . ($document->getAnnotations->getSectionLevel->existsElementFromIndex("to", $token->getId) * 1) . "\n";
		    } while(defined $token) && (($token->getTo < $to));
			# warn "=======> " . ($document->getAnnotations->getSectionLevel->existsElementFromIndex("to", $token->getId) * 1) . "\n";
			# warn "? " . $token->getContent . " / $term_content " . $token->getTo . "\n";
		    # if (($token->getTo == $to) && ($document->getAnnotations->getSectionLevel->existsElementFromIndex("to", $token->getId))) {
		    # 	warn "Add Suppl\n";
		    # 	$term_content .= $token->getContent;
		    # 	push @TermTokens, $token;
		    # 	# warn "+ " . $token->getContent . " / $term_content\n";
		    # 	$token = $token->next;
		    # }
		    # TODO recode XML entities before sending to the term tagger
		    if (!$document->getAnnotations->getSemanticUnitLevel->existsElementByStartEndTokens($TermTokens[0], $TermTokens[$#TermTokens])) {
			$termUnit = $self->_createTerm($document, \@TermTokens, $term_content);
			if (defined $termUnit) {
			    # warn "\tAdd $term\n";
			    # warn "\t    " . $termUnit->getForm . "\n";
			    my %weights = ('relevance' => 1.5);
			    $termUnit->weights(\%weights);
			    $document->getAnnotations->addSemanticUnit($termUnit);
		    }
			
		    } else {
			$termUnit = $document->getAnnotations->getSemanticUnitLevel->getElementByStartEndTokens($TermTokens[0], $TermTokens[$#TermTokens]);
		    }
		    if ((defined $canonical_form) && ($canonical_form ne "") && (!defined $termUnit->canonical_form)) {
			# warn "==> $canonical_form\n";
			$termUnit->canonical_form($canonical_form)
		    };
		    if (defined $semtags) {
			# TODO Merge Semantic features?????
			if (!$document->getAnnotations->getSemanticFeaturesLevel->existsElementFromIndex('refid_semantic_unit',$termUnit->getId)) {
			foreach $semtag (split(/;/, $semtags)) {
			    my @semtags = split /\//, $semtag;
			    my @list_semtags;
			    push @list_semtags, \@semtags;
			    # TODO Check if the semtag already exists in order to avoid to create one another
			    $semFeatures = Lingua::Ogmios::Annotations::SemanticFeatures->new(
				{ 'semantic_category' => \@list_semtags,
				  'refid_semantic_unit' => $termUnit->getId,
				});
			    $document->getAnnotations->addSemanticFeatures($semFeatures);
			}
			}
		    }
		} else {
		    warn "*** undefined token\n";
		}
	    }
	    $self->getTimer->lapEndUserTimeBySteps;
	}
    $self->getTimer->_printTimesBySteps;
    }
    if (scalar((keys %{$self->_output_hash->{'FF'}})) > 0) {
	if ((!(defined($self->{"MERGE_TERMS"}->{$lang}))) || ($self->{"MERGE_TERMS"}->{$lang} == 1)) {
	    foreach $document (@{$self->_documentSet}) {
		$self->_mergeTerms($document);
		# TO REMOVe WHEN index deleting is OK
		$document->getAnnotations->getSemanticUnitLevel->rebuildIndex;
		$document->getAnnotations->getPhraseLevel->rebuildIndex;
		$document->getAnnotations->getSemanticUnitLevel->rebuildIndex;
	    }
	}
    }
    # }
    warn "[LOG] done\n";
}


sub run {
    my ($self, $documentSet) = @_;

    warn "*** TODO: check if the level exists\n";

    # Set variables according the the configuration

    $self->_documentSet($documentSet);

    warn "[LOG] " . $self->_config->comments . " ...     \n";

    $self->_inputTermTagger;

    my $command_line = $self->_processTermTagger;

#     if ($self->_position eq "last") {
# 	# TODO

    $self->_outputParsing;

    if (($self->_position eq "last") && ($self->_no_standard_output)) {
	warn "print no standard output\n";
	if ($self->_no_standard_output eq "HTML") {
            warn "print HTML output\n";
	    $self->HTMLoutput;
	}
	if ($self->_no_standard_output eq "TXT") {
            warn "print TXT output\n";
	    $self->_TXToutput;
	}
	if ($self->_no_standard_output eq "TAB") {
            warn "print TAB output\n";
	    $self->_TABoutput;
	}
	if ($self->_no_standard_output eq "BRAT") {
            warn "print BRAT output\n";
	    $self->_BRAToutput;
	}
	if ($self->_no_standard_output eq "TXTwSectionTitle") {
            warn "print TXT output\n";
	    $self->_TXToutputWithSectionTitle;
	}

	if ($self->_no_standard_output eq "TAGGEDSENT") {
            warn "print Tagged Sentence output (TAGGEDSENT)\n";
	    $self->_makeTaggedSentences({}, \*STDOUT, "/", " ");
	}

	if ($self->_no_standard_output eq "CRFINPUT") {
            warn "print Tagged Sentence output (CRFINPUT)\n";
	    $self->_makeTaggedSentences({}, \*STDOUT, "\t", "\n");
	}
	if ($self->_no_standard_output eq "QALD") {
	    warn "print Tagged Sentence output (QALD)\n";
	    $self->_QALDoutput(\*STDOUT);
	}
    }
#     $self->_outputParsing;

    # Put log information 

    my $information = { 'software_name' => $self->_config->name,
			'comments' => $self->_config->comments,
			'command_line' => $command_line,
			'list_modified_level' => ['semantic_unit_level', 'phrase_level', 'semantic_festures_level'],
    };

    
    $self->_log($information);

    $self->getTimer->_printTimesInLine($self->_config->name);

#     die "You call the 'rum' method of the wrapper class base\n
#          You should define a 'run' method for your wrapper\n";
    warn "[LOG] done\n";
}

sub _TXToutput {
    my ($self) = @_;

    my $key;
    my $sent_id;
    my $term;
    my $canonical_form;
    my $semtag;
    my $document;
    my $term_offset;
    my $i;

    my $tokens;
    my $token;

    my $termUnit;    
    my $semFeatures;

    my $decoded_sentence;

    warn "[LOG] Number of identified terms: " . scalar((keys %{$self->_output_hash->{'FF'}})) . "\n";

    for $key (keys %{$self->_output_hash->{'FF'}}) {
    	$sent_id = $self->_output_hash->{'FF'}->{$key}->[0];
    	$term = $self->_output_hash->{'FF'}->{$key}->[1];
        $canonical_form = $self->_output_hash->{'FF'}->{$key}->[2];
        $semtag = $self->_output_hash->{'FF'}->{$key}->[3];
    	$document = $self->getDocumentFromInputHash(\$sent_id);

    	print "$term\t";
    	if (defined ($canonical_form)) {
    	    print "$canonical_form\t";
    	}
    	if (defined ($semtag)) {
    	    print "$semtag\t";
    	}
    	print "$sent_id\t" . $document->getId . "\n";
    }

    for $key (keys %{$self->_output_hash->{'LM'}}) {
	$sent_id = $self->_output_hash->{'LM'}->{$key}->[0];
	$term = $self->_output_hash->{'LM'}->{$key}->[1];
        $canonical_form = $self->_output_hash->{'LM'}->{$key}->[2];
        $semtag = $self->_output_hash->{'LM'}->{$key}->[3];
	$document = $self->getDocumentFromInputHash(\$sent_id);

	print "$term\t";
	if (defined ($canonical_form)) {
	    print "$canonical_form\t";
	}
	if (defined ($semtag)) {
	    print "$semtag\t";
	}
	print "$sent_id\t" . $document->getId . "\n";
    }
}

# 

sub _BRAToutput {
    my $self = shift;

    my $document;
    my $term;
#    my $str;
    my $lang = $self->_documentSet->[0]->getAnnotations->getLanguage;
    # my $semTypes = ['food', 'drug', 'side_effect'];
#    my $semTypes = $self->_loadStopWords(,"semanticTypes2print",$self->_documentSet->[0]->getAnnotations->getLanguage);
    my $semf;
#    my %semF2terms;
    my @TermAndSemF;
    my $sentId;
    my $token;
    my $annId = 1;
    my $attrId = 1;
    my $content;
    warn "BRAT OUTPUT\n";
     foreach $document (@{$self->_documentSet}) {

	 warn $self->{'outputdir'}->{$lang} . "\n";
	 open ANNFILE, ">" . $self->{'outputdir'}->{$lang}  . "/" . $document->getId . ".ann" or die "no such directory " . $self->{'outputdir'}->{$lang} ;
	 binmode(ANNFILE, ":utf8");

	 # foreach $semf (@{$self->{"SEMANTICTYPES2PRINT"}->{$lang}}) {
	 #     $semF2terms{$semf} = {};
	 # }
#	 print $document->getId . "\t";

	 foreach $term (@{$document->getAnnotations->getSemanticUnitLevel->getElements}) {
	     # warn $term->getForm . "\n";
	     $sentId = $document->getAnnotations->getSentenceLevel->getElementByToken($term->start_token)->[0]->getId;
	     #print $document->getId . "\t$sentId\t";
#	     print $document->getId . "-$sentId\t";
	     if ($term->isNamedEntity) {
		 print ANNFILE "T$annId\t" . $term->NEtype . " " . $term->start_token->getFrom . " " . $term->end_token->getTo . "\t" . $term->getForm . "\n";
		 $annId++;
#		 $semF2terms{$document->getId . "-$sentId"}->{$term->NEtype}->{lc($term->getForm)}++;
	     } else {
		 if ($document->getAnnotations->getSemanticFeaturesLevel->existsElementFromIndex("refid_semantic_unit", $term->getId)) {
		     $semf = $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $term->getId)->[0];
		     # warn "semf: $semf\n";
		     if (defined $semf) {
			 print ANNFILE "T$annId\t" . $semf->first_node_first_semantic_category . " " . $term->start_token->getFrom . " " . ($term->end_token->getTo+1) . "\t" . $term->getForm . "\n";
			 #print ANNFILE "T$annId\t" . $semf->toString . " " . $term->start_token->getFrom . " " . ($term->end_token->getTo+1) . "\t" . $term->getForm . "\n";
			 $annId++;			 
#			 $semF2terms{$document->getId . "-$sentId"}->{$semf->first_node_first_semantic_category}->{lc($term->getForm)}++;
		     }
		 }
		 
	     }
	 }
	 close(ANNFILE);

	 open SENTFILE, ">" . $self->{'outputdir'}->{$lang}  . "/" . $document->getId . ".txt" or die "no such directory " . $self->{'outputdir'}->{$lang};
	 binmode(SENTFILE, ":utf8");

	 foreach $token (@{$document->getAnnotations->getTokenLevel->getElements}) {
	     if ((defined $token->previous) &&
		 ($document->getAnnotations->getSentenceLevel->existsElementFromIndex('refid_end_token', $token->previous->getId))
		 && ($token->getContent !~ /\n/o)) {
		 $content = $token->getContent;
		 $content =~ s/\s/\n/o;
		 print SENTFILE "$content";
	     } else {
		 print SENTFILE $token->getContent;
	     }

	 }
	 close SENTFILE;
# 	 foreach $sentId (keys %semF2terms) {
# 	     foreach $semf (@{$self->{"SEMANTICTYPES2PRINT"}->{$lang}}) {
# 		 $str = "";
# 		 foreach $term (keys %{$semF2terms{$sentId}->{$semf}}) {
# #		 foreach $sentId (keys %{$semF2terms{$semf}->{$term}}) {
# 		     $str = "$sentId\t$term\t$semf";
# 		     print "$str\n";
# 		 }
# 	     }
# 	     # $str = join(',', keys %{$semF2terms{$semf}});
# #	     print "$str\t";
# 	 }

 	# foreach my $Termtype (sort {$colorTypes{$b} cmp $colorTypes{$a}} keys %colorTypes) {
 	#     $idColor = $colorTypes{$Termtype};
	#     print "maketip('" . $idColor . "','Semantic type','" . $Termtype . "');\n"; 
 	# }

	# print '</SCRIPT>' . "\n";
	# print "<BR><B>document ID: " . $document->getId . "</B><BR>\n";
	# print "<HR>\n";
	# print "colors: <BR>\n<ul>\n";
	# $color = "FFCBDB"; # 0000FF
	# print "<li><a class=\"Terms\">Terms</a></li>\n";
	# foreach my $Termtype (sort {$colorTypes{$b} cmp $colorTypes{$a}} keys %colorTypes) {
	#     $idColor = $colorTypes{$Termtype};
	#     print "<li><a class=\"" . $idColor . "\">$Termtype = $idColor</a></li>\n";
	# }
	
	# print "</ul>\n<HR>\n";
	# print $doc_str;
#	print "\n";
    }    
}



sub _TABoutput {
    my $self = shift;

    my $document;
    my $term;
    my $str;
    my $lang = $self->_documentSet->[0]->getAnnotations->getLanguage;
    # my $semTypes = ['food', 'drug', 'side_effect'];
#    my $semTypes = $self->_loadStopWords(,"semanticTypes2print",$self->_documentSet->[0]->getAnnotations->getLanguage);
    my $semf;
    my %semF2terms;
    my $sentId;

     foreach $document (@{$self->_documentSet}) {
	 # foreach $semf (@{$self->{"SEMANTICTYPES2PRINT"}->{$lang}}) {
	 #     $semF2terms{$semf} = {};
	 # }
#	 print $document->getId . "\t";

	 foreach $term (@{$document->getAnnotations->getSemanticUnitLevel->getElements}) {
	     # warn $term->getForm . "\n";
	     $sentId = $document->getAnnotations->getSentenceLevel->getElementByToken($term->start_token)->[0]->getId;
	     #print $document->getId . "\t$sentId\t";
#	     print $document->getId . "-$sentId\t";
	     if ($term->isNamedEntity) {
		 $semF2terms{$document->getId . "-$sentId"}->{$term->NEtype}->{lc($term->getForm)}++;
	     } else {
		 if ($document->getAnnotations->getSemanticFeaturesLevel->existsElementFromIndex("refid_semantic_unit", $term->getId)) {
		     $semf = $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $term->getId)->[0];
		     # warn "semf: $semf\n";
		     if (defined $semf) {
			 $semF2terms{$document->getId . "-$sentId"}->{$semf->first_node_first_semantic_category}->{lc($term->getForm)}++;
		     }
		 }
		 
	     }
	 }
	 foreach $sentId (keys %semF2terms) {
	     foreach $semf (@{$self->{"SEMANTICTYPES2PRINT"}->{$lang}}) {
		 $str = "";
		 foreach $term (keys %{$semF2terms{$sentId}->{$semf}}) {
#		 foreach $sentId (keys %{$semF2terms{$semf}->{$term}}) {
		     $str = "$sentId\t$term\t$semf";
		     print "$str\n";
		 }
	     }
	     # $str = join(',', keys %{$semF2terms{$semf}});
#	     print "$str\t";
	 }

 	# foreach my $Termtype (sort {$colorTypes{$b} cmp $colorTypes{$a}} keys %colorTypes) {
 	#     $idColor = $colorTypes{$Termtype};
	#     print "maketip('" . $idColor . "','Semantic type','" . $Termtype . "');\n"; 
 	# }

	# print '</SCRIPT>' . "\n";
	# print "<BR><B>document ID: " . $document->getId . "</B><BR>\n";
	# print "<HR>\n";
	# print "colors: <BR>\n<ul>\n";
	# $color = "FFCBDB"; # 0000FF
	# print "<li><a class=\"Terms\">Terms</a></li>\n";
	# foreach my $Termtype (sort {$colorTypes{$b} cmp $colorTypes{$a}} keys %colorTypes) {
	#     $idColor = $colorTypes{$Termtype};
	#     print "<li><a class=\"" . $idColor . "\">$Termtype = $idColor</a></li>\n";
	# }
	
	# print "</ul>\n<HR>\n";
	# print $doc_str;
	print "\n";
    }    
}



sub _TXToutputWithSectionTitle {
    my ($self) = @_;

    my $document;
    my $term;
    my $section;

    foreach $document (@{$self->_documentSet}) {
	foreach $term (@{$document->getAnnotations->getSemanticUnitLevel->getElements}) {
	    $section = $document->getAnnotations->getSectionLevel->getElementByToken($term->start_token)->[0];
	    if ((defined $section) && (defined $section->title)){ 
		print $section->title;
	    }
	    print "\t";
	    print $term->getForm;
	    print "\t";
	    if ($term->canonical_form) {
		print $term->canonical_form;
	    }
	    print "\t";
	    my $semf = $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $term->getId)->[0];
	    if ((defined $semf) && ($semf->first_node_first_semantic_category))  {
		print $semf->first_node_first_semantic_category;
	    }
	    print "\n"
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

