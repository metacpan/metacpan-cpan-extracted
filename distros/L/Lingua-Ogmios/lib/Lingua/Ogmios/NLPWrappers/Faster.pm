package Lingua::Ogmios::NLPWrappers::Faster;


our $VERSION='0.1';

use Lingua::Ogmios::NLPWrappers::Wrapper;
use Lingua::Ogmios::Annotations::DomainSpecificRelation;
use Lingua::Ogmios::Annotations::SemanticUnit;
use Data::Dumper;

use strict;
use warnings;


our @ISA = qw(Lingua::Ogmios::NLPWrappers::Wrapper);

sub new {
    my ($class, $config, $tmpfile_prefix, $logfile, $position, $no_standard_output) = @_;
    my $lang;
    my $lang2;

    warn "[LOG]    Creating a wrapper of the " .  $config->comments . "\n";
    
    my $Faster = $class->SUPER::new($config, $tmpfile_prefix, $logfile, $position, $no_standard_output);

    if (defined $Faster->_config->configuration->{'CONFIG'}) {
	foreach $lang (keys %{$Faster->_config->configuration->{'CONFIG'}}) {
	    if ($lang =~ /language=([\w]+)/io) {
		$lang2 = $1;
		$Faster->_setOption($lang2, "MODE", "mode", "free");
	    }
	}
    }
    $Faster->_FASTRTMP_dir($tmpfile_prefix . ".FASTER");
    $Faster->_input_filename($Faster->_FASTRTMP_dir . "/Faster.in");
    $Faster->_output_filename($Faster->_FASTRTMP_dir . "/Faster.out"); 

    $Faster->_output_hash({'term_idx' => {}});
#     $Faster->_output_hash({'sentence_idx' => {}});

    $Faster->_Corpus_filename($Faster->_FASTRTMP_dir . "/corpus_faster.in");
    $Faster->_tmp_filename($Faster->_FASTRTMP_dir . "/faster.tmp");
    $Faster->_ConvertCorpus_filename($Faster->_FASTRTMP_dir . "/corpus.fas");
    $Faster->_MetaRulesSW_filename($Faster->_FASTRTMP_dir . "/terms.R.w");
    $Faster->_MetaRulesTRM_filename($Faster->_FASTRTMP_dir . "/terms.R.t");

    mkdir $Faster->_FASTRTMP_dir;
    
    return($Faster);
}

sub _FASTRTMP_dir {
    my $self = shift;

    $self->{"FASTRTMP_DIR"} = shift if @_;

    return($self->{"FASTRTMP_DIR"});
}

sub _Corpus_filename {
    my $self = shift;

    $self->{"Corpus_filename"} = shift if @_;

    return($self->{"Corpus_filename"});
}

sub _tmp_filename {
    my $self = shift;

    $self->{"tmp_filename"} = shift if @_;

    return($self->{"tmp_filename"});
}

sub _ConvertCorpus_filename {
    my $self = shift;

    $self->{"convertCorpus_filename"} = shift if @_;

    return($self->{"convertCorpus_filename"});
}

sub _MetaRulesSW_filename {
    my $self = shift;

    $self->{"MetaRulesSW_filename"} = shift if @_;

    return($self->{"MetaRulesSW_filename"});
}

sub _MetaRulesTRM_filename {
    my $self = shift;

    $self->{"MetaRulesTRM_filename"} = shift if @_;

    return($self->{"MetaRulesTRM_filename"});
}


sub _exec_command {

    my ($self, $command) = @_;

    return($self->SUPER::_exec_command($command, 
				       {'FASTRBIN' => $self->_config->configuration->{'FASTRBIN'},
					'FASTRLIB' => $self->_config->configuration->{'FASTRLIB'},
					'FASTRTMP' => $self->_FASTRTMP_dir,
				       }));
}

sub _processFaster {
    my ($self, $lang) = @_;

    my $command_line;
    my $return_command_line;

    warn "[LOG] " . $self->_config->comments . "\n";

    $lang = $self->_documentSet->[0]->getAnnotations->getLanguage;

#     $self->setConvertCorpus_cmd($self->getConfig->{'NLP_tools'}->{'FASTER'}->{'COMMANDS'}->{"language=$language"}->{'CONVERTCORPUS_CMD'});
#     $self->setMakeMetaRulesSW_cmd($self->getConfig->{'NLP_tools'}->{'FASTER'}->{'COMMANDS'}->{"language=$language"}->{'MAKEMETARULES_SW_CMD'});
#     $self->setMakeMetaRulesTRM_cmd($self->getConfig->{'NLP_tools'}->{'FASTER'}->{'COMMANDS'}->{"language=$language"}->{'MAKEMETARULES_TRM_CMD'});
#     $self->setFastrbinary_cmd($self->getConfig->{'NLP_tools'}->{'FASTER'}->{'COMMANDS'}->{"language=$language"}->{'FASTR'});

    $command_line = $self->_defineCommandLine($self->_config->commands($lang)->{'CONVERTCORPUS_CMD'},
					      $self->_Corpus_filename, 
					      $self->_ConvertCorpus_filename);
    
    $return_command_line .= $self->_exec_command($command_line);
    $return_command_line .= "; ";

#	$mode = $self->{'mode'}->{$document->getAnnotations->getLanguage};

    $command_line = $self->_defineCommandLine($self->_config->commands($lang)->{'MAKEMETARULES_SW_CMD'}, $self->_input_filename, $self->_MetaRulesSW_filename);
    $return_command_line .= $self->_exec_command($command_line);
    $return_command_line .= "; ";

# #     warn "[FASTER LOG] Postprocessing single word rules\n";

    my $line;
    my $pos;


    if ($lang eq 'EN') {
	open SWR, $self->_MetaRulesSW_filename or warn "No such file " . $self->_MetaRulesSW_filename;
	while ((defined(<SWR>)) && ($line = <SWR>) && (($pos=index($line, "Word 'be' : <cat> = V")) == -1)) {};
	close SWR;
	if ($pos == -1) {
	    open SWR, ">>" .  $self->_MetaRulesSW_filename or die "No such file " . $self->_MetaRulesSW_filename; 
	    print SWR "Word 'be' : <cat> = V.\n";
	    close SWR;
	}
    }

    
    $command_line = $self->_defineCommandLine($self->_config->commands($lang)->{'MAKEMETARULES_TRM_CMD'}, $self->_input_filename, $self->_MetaRulesTRM_filename);
    $return_command_line .= $self->_exec_command($command_line);
    $return_command_line .= "; ";
    
    my $command_gen = $self->_config->commands($lang)->{'FASTR'} . " -C " . $self->_config->configuration->{'FASTREMPTYCONF'};

    warn "command_gen: $command_gen\n";
    $command_line = $self->_defineCommandLine($command_gen . " -z");
    warn "[FASTER LOG] command line : $command_line\n";
    $return_command_line .= $self->_exec_command($command_line);
    $return_command_line .= "; ";
    
    $command_gen = $self->_config->commands($lang)->{'FASTR'} . " -C " . $self->_config->configFile($lang)->{"FASTRCONF"};
    $command_line = $self->_defineCommandLine($command_gen . " -c " . $self->_MetaRulesSW_filename);
    warn "[FASTER LOG] command line : $command_line\n";
    $return_command_line .= $self->_exec_command($command_line);
    $return_command_line .= "; ";
    
    $command_line = $self->_defineCommandLine($command_gen . " -c " . $self->_MetaRulesTRM_filename);
    warn "[FASTER LOG] command line : $command_line\n";
    $return_command_line .= $self->_exec_command($command_line);
    $return_command_line .= "; ";
    
    $command_line = $self->_defineCommandLine("(" . $command_gen . " -i | " . $command_gen . 
					      " -s " . $self->_input_filename . " 2 )  < " . 
					      $self->_ConvertCorpus_filename . " > " . $self->_output_filename);
    warn "[FASTER LOG] command line : $command_line\n";
    warn $self->_config->configuration->{'FASTRBIN'} . "\n";
    $return_command_line .= $self->_exec_command($command_line);
    $return_command_line .= "; ";

    warn "[LOG]\n";
    return($return_command_line);
}

sub _inputFaster {
    my ($self) = @_;

    my $lang = $self->_documentSet->[0]->getAnnotations->getLanguage;
    my $doc_idx;
    my $document;
    my $semanticUnit;

    my $term_id;
    my $term_idx;
    my $term_lemma = "";
    my $term_postag = "";
    my $term_inflectedform = "";

    my $command_line;
    my $return_command_line;

    my $line;

    my $word = "";
    my $lemma = "";
    my $postag = "";

    my @corpus_in_t;

    warn "[LOG] Making input\n";

    warn "[LOG] Corpus\n";
    $self->_printTreeTaggerFormatOutput($self->_Corpus_filename, "LATIN1");

    warn "[LOG] Term List\n";
    warn "\tmode: " . $self->{'mode'}->{$lang} . "\n";

    if ($self->{'mode'}->{uc($lang)} eq "FREE") {
#    if (!defined $self->_config->configFile($lang)->{"CONTROLLED_TERMLIST"}) {
	warn "Making term list for free indexing\n";

	$term_idx = 0;
	foreach $document (@{$self->_documentSet}) {
	    warn $document->getId . "\n";
	    for($doc_idx = 0; $doc_idx < scalar(@{$document->getAnnotations->getSemanticUnitLevel->getElements});$doc_idx++) {
		$semanticUnit = $document->getAnnotations->getSemanticUnitLevel->getElements->[$doc_idx];
		$term_idx++;

		$term_lemma = undef;
		$term_postag = undef;

		if ($semanticUnit->isTerm) {
		    $self->_output_hash()->{'term_idx'}->{$term_idx} = $semanticUnit;
		    $term_id = sprintf("%05d", $term_idx);
		    if ($semanticUnit->reference_name eq "refid_word") {
			$term_lemma = $document->getAnnotations->getLemmaLevel->getElementFromIndex("refid_word", $semanticUnit->reference->getId)->[0]->canonical_form;
			$term_postag = $document->getAnnotations->getMorphosyntacticFeaturesLevel->getElementFromIndex("refid_word", $semanticUnit->reference->getId)->[0]->syntactic_category;
		    }

		    if ($semanticUnit->reference_name eq "refid_phrase") {
			($term_lemma, $term_postag) = $self->_getPhraseInfo($document, $semanticUnit->reference);
		    }

		    if ($semanticUnit->reference_name eq "list_refid_token") {
			warn "term $term_id is a list_refid_token\n";
			warn "Not done yet!\n"
		    }

		    if (defined $term_lemma) {
			my @tmp  = ($term_id, $term_lemma, $term_postag);
			push @corpus_in_t, \@tmp;
		    }

		}
	    }
	}
	warn "\tOpenning " . $self->_input_filename . "\n";

	open FILE_IN, ">" . $self->_input_filename or die "can't open " . $self->_input_filename . "\n";

	my $word_ref;
	foreach $word_ref (@corpus_in_t) {

	    if ($word_ref->[0] =~ s/ /_/go) {
		$word_ref->[2] =~ s/ /_/go;
	    }
	    print FILE_IN Encode::encode("iso-8859-1", join("\t",@$word_ref)) . "\n";
	}

	close FILE_IN;
    } elsif (defined $self->_config->configuration->{"RESOURCE"}->{"language=". uc($lang) }->{"CONTROLLED_TERMLIST"}) {
	warn "Making term list for controlled indexing\n";
	if ( ! -f $self->_config->configuration->{"RESOURCE"}->{"language=". uc($lang)}->{"CONTROLLED_TERMLIST"}) {
	    die "No such file " . $self->_config->configuration->{"RESOURCE"}->{"language=". uc($lang)}->{"CONTROLLED_TERMLIST"} . "\n";
	}

	$command_line = $self->_defineCommandLine($self->_config->commands($lang)->{'CONVERTTERMLIST_CMD'},
						  $self->_config->configuration->{"RESOURCE"}->{"language=". uc($lang)}->{"CONTROLLED_TERMLIST"}, 
						  $self->_tmp_filename);
	
	warn "[FASTER LOG] command line : $command_line\n";
	$return_command_line .= $self->_exec_command($command_line);
	$return_command_line .= "; ";

	$term_idx = 0;
	open TMPFILE, $self->_tmp_filename or die "No such file " . $self->_tmp_filename . "\n";
	binmode(TMPFILE, ":encoding(latin9)");

	warn "\tOpenning " . $self->_input_filename . "\n";
	open FILE_IN, ">" . $self->_input_filename or die "can't open " . $self->_input_filename . "\n";
#	binmode(FILE_IN, ":utf8");
	my $word_ref;

	while($line = <TMPFILE>) {
	    $term_idx++;
	    $term_id = sprintf("%05d", ($term_idx - 1));
	    print FILE_IN Encode::encode("iso-8859-1", join("\t",($term_id,$line)));
	}
	close FILE_IN;
	close TMPFILE;
    }

    
    warn "[LOG] done\n";
}

sub _getPhraseInfo {
    my ($self, $document, $phrase) = @_;

    my @term_lemmas;
    my @term_postags;
    my $term_lemma;
    my $term_postag;
    my $item;
    

    foreach $item (@{$phrase->list_refid_components}) {
# 	warn "\tterm is " . $item . "\n";
	if (ref($item) eq "Lingua::Ogmios::Annotations::Word")  {
	    #getElementFromIndex
	    #$term_lemma = $document->getAnnotations->getLemmaLevel $SemanticUnit
	    push @term_lemmas, $document->getAnnotations->getLemmaLevel->getElementFromIndex("refid_word", $item->getId)->[0]->canonical_form ;
	    push @term_postags, $document->getAnnotations->getMorphosyntacticFeaturesLevel->getElementFromIndex("refid_word", $item->getId)->[0]->syntactic_category;
	}
	if (ref($item) eq "Lingua::Ogmios::Annotations::Phrase")  {
	    ($term_lemma, $term_postag) = $self->_getphraseInfo($document,$item);
	    push @term_lemmas, $term_lemma;
	    push @term_postags, $term_postag; 
	}
    }
    $term_lemma = join(" ", @term_lemmas);
    $term_postag = join(" ", @term_postags);

    return($term_lemma, $term_postag);
}

sub _outputParsing {
    my ($self) = @_;

    my $line;
    my $sentence_id;
    my $term;
    my $term_id;
    my $term_variante;
    my $numeric_information;
    my $MSrelation_type;

    my $doc_idx;
    my $sent_idx;
    my $term_variante_clean;
    my $term_variante_unit;
    my $term_unit;

    my $document;

    my $domainSpecificRelation;
#     my $term_unit;

    warn "[LOG] . Parsing output Array\n";

    open FASTEROUTPUT, $self->_output_filename or warn "No such file " . $self->_output_filename;
#    binmode(FASTEROUTPUT, ":utf8");

    while($line = <FASTEROUTPUT>) {
	chomp $line;
# 	warn "$line\n";
	if ($line =~ /\tX[^\t]+$/) {
   	    warn "=> $line\n";
	    ($sentence_id, $term, $term_id, $term_variante, $numeric_information, $MSrelation_type) = split / ?\t ?/, $line;
	    # 1. check if the term_variante is already identify as a term
            # 2. (if no) create a new term 
	    $sentence_id += 0;
	    $term_id += 0;
	    $term_variante =~ s/^\s+//og;

	    # warn "$term_id\n";
	    # warn "$sentence_id\n";

	    $term_variante_clean = $term_variante;
	    $term_variante_clean =~ s/\[[^\]]+\]//og;

  	    # warn "Find the document/sentence\n";
	    $doc_idx = 0;
	    $sent_idx = $sentence_id;
 	    while(($doc_idx <= $#{$self->_documentSet}) && ($sent_idx > $self->_documentSet->[$doc_idx]->getAnnotations->getSentenceLevel->getSize)) {
  		warn "\t(sent_idx: $sent_idx, doc_idx = $doc_idx)\n";
		warn "\t(" . $self->_documentSet->[$doc_idx]->getAnnotations->getSentenceLevel->getSize . ")\n";
		$sent_idx -= $self->_documentSet->[$doc_idx]->getAnnotations->getSentenceLevel->getSize;
		$doc_idx++;
	    }
   	    warn "sent_idx: $sent_idx, doc_idx = $doc_idx\n";

	    $document = $self->_documentSet->[$doc_idx];
	    warn $document->getId . "\n";

 	    # warn "$term_variante_clean exists ?\n\n";
	    $term_variante_unit = undef;
	    my $sent = $document->getAnnotations->getSentenceLevel->getElement($sent_idx);
  	    # warn "sentence: $sent\n";
	    # warn "start token SENT: " . $sent->refid_start_token . "\n";
	    # warn "end token SENT: " . $sent->refid_end_token . "\n";
	    # warn "\t" . $sent->getForm . "\n\n";
	    if ($document->getAnnotations->getSemanticUnitLevel->existsElementFromIndex("form", $term_variante_clean)) {

		my $i = 0;
		do { 
		    $term_variante_unit = $document->getAnnotations->getSemanticUnitLevel->getElementFromIndex("form", $term_variante_clean)->[$i];
		    
#  		    warn "start token TU: " . $term_variante_unit->start_token . "\n";
#  		    warn "end token TU: " . $term_variante_unit->end_token . "\n";
		    $i++;
		} while((!(($sent->refid_start_token->getFrom <= $term_variante_unit->start_token->getFrom) && 
			   ($term_variante_unit->end_token->getTo <= $sent->refid_end_token->getFrom))) &&
			($i < scalar(@{$document->getAnnotations->getSemanticUnitLevel->getElementFromIndex("form", $term_variante_clean)})));
		if  (!(($sent->refid_start_token->getFrom <= $term_variante_unit->start_token->getFrom) && 
		       ($term_variante_unit->end_token->getTo <= $sent->refid_end_token->getFrom))) {
		    $term_variante_unit = undef;
 		# } else {
 		#     warn "Term variante already exists $term_variante_unit\n";
		}
 		# warn "End\n";
	    }
	    if (!defined $term_variante_unit) {
		# Creation of a new term
 		# warn "$term_variante_clean ($term_variante) doesn't exists\n";
 		# warn "building the token list\n";
		
		my @TV_words = split /\[[^\]]+\]/, $term_variante;
		# warn "TV words: " . join(":", @TV_words) . "\n";
		my $j;
		for($j = 2;$j < scalar(@TV_words);$j+=2) {
		    $TV_words[$j] =~ s/^ //o;
		}
 		# warn "\n" . $sent->getForm . "\n";
		my $word;
		my $i = 0;
		my $term_content;
		my @TermWords;
		do {
		    do {
			$word = $document->getAnnotations->getWordLevel->getElementFromIndex("form", $TV_words[0])->[$i];
			$i++;
			if (!defined $word) {
			    $sent_idx++;
			    $sent = $document->getAnnotations->getSentenceLevel->getElement($sent_idx);
			    $i = 0;
			} else {
			    # warn "word: $word"  . $word->getForm . "\n";
			}
		    } while((!defined $word) || ((defined $sent) && (!(($sent->refid_start_token->getFrom <= $word->start_token->getFrom) && 
						    ($word->end_token->getTo <= $sent->refid_end_token->getFrom))) &&
						 ($i < scalar($document->getAnnotations->getWordLevel->getElementFromIndex("form", $TV_words[0])))));
		    # if ((defined $word) && (!defined $sent)) {
		    # 	$sent_idx--;
		    # 	$sent = $document->getAnnotations->getSentenceLevel->getElement($sent_idx);
		    # 	warn "\t" . $sent->getForm . "\n";
		    # 	warn "word: $word"  . $word->getForm . "\n";
		    # }
		    $term_content = $word->getForm;
		    @TermWords = ();
		    # (defined $sent) && 
		    if ((($sent->refid_start_token->getFrom <= $word->start_token->getFrom) && 
			 ($word->end_token->getTo <= $sent->refid_end_token->getFrom))) {
			push @TermWords, $word;
			$j = 2; # first word already found
			do {
			    $word = $word->next;
			    $term_content .= " " . $word->getForm;
			    push @TermWords, $word;
			    $j+=2;
			} while (($TV_words[$j - 2] eq $word->getForm) && ($j < scalar(@TV_words)));
		    }
		} while(((!(($sent->refid_start_token->getFrom <= $word->start_token->getFrom) && 
			    ($word->end_token->getTo <= $sent->refid_end_token->getFrom)))) &&
			($term_content ne $term_variante_clean));
 		# warn "term content: $term_content\n";
		if (scalar(@TermWords) < 2) {
# 		    warn "Strange: multiword term is recognize has a word\n;";
		}
		if ($term_content eq $term_variante_clean) {
		    my $phrase = Lingua::Ogmios::Annotations::Phrase->new(
			{ 'refid_word' => \@TermWords,
			  'form' => $term_content,
			}
			);		    
		    $document->getAnnotations->addPhrase($phrase);
		    $term_variante_unit = Lingua::Ogmios::Annotations::SemanticUnit->newTerm(
			{'form' => $term_content,
			 'refid_phrase' => $phrase,
			 'canonical_form' => $term,
			});
		    $document->getAnnotations->addSemanticUnit($term_variante_unit);
		}
	    } 

	    if (defined $term_variante_unit) {
		warn "Add a domain specific relation $term_id\n";
		$term_variante_unit->canonical_form($term);
		if (exists $self->_output_hash()->{'term_idx'}->{$term_id}) {
		    my @tmp = ($self->_output_hash()->{'term_idx'}->{$term_id}, $term_variante_unit);

		    # warn  join(" : ", @tmp) . "\n";

		    $domainSpecificRelation = Lingua::Ogmios::Annotations::DomainSpecificRelation->new(
			{'domain_specific_relation_type' => $MSrelation_type,
			 'list_refid_semantic_unit' => \@tmp,
			});
# 		foreach my $field (@{$document->getAnnotations->getDomainSpecificRelationLevel->getIndexfields}) {
# 		    warn "$field\n";
# 		    my $value = $domainSpecificRelation->_getField($field);
# 		    warn ref($value) . "\n";
# # 		warn join(" : ", @$value) . "\n";
# 		}
# 		warn "add relation\n";
		    $document->getAnnotations->addDomainSpecificRelation($domainSpecificRelation);
		    # warn "end\n\n";
		} else {
		    # warn "term: $term\n";
		    # $document->getAnnotations->getSemanticUnitLevel->printIndex("form");
		    # warn scalar(@{$document->getAnnotations->getSemanticUnitLevel->getElementFromIndex("form", $term)}) . "\n";
		    foreach $term_unit (@{$document->getAnnotations->getSemanticUnitLevel->getElementFromIndex("form", $term)}) {
			my @tmp = ($term_unit, $term_variante_unit);

			# warn  join(" : ", @tmp) . "\n";

			$domainSpecificRelation = Lingua::Ogmios::Annotations::DomainSpecificRelation->new(
			    {'domain_specific_relation_type' => $MSrelation_type,
			     'list_refid_semantic_unit' => \@tmp,
			    });
			$document->getAnnotations->addDomainSpecificRelation($domainSpecificRelation);
			
		    }
		#     warn "$line not a term\n";
		}
	    }
	}
    }
    close FASTEROUTPUT;

    warn "[LOG] done\n";
}

sub run {
    my ($self, $documentSet) = @_;

    warn "*** TODO: check if the level exists\n";
    # Set variables according the the configuration

    $self->_documentSet($documentSet);

    warn "[LOG] " . $self->_config->comments . " ...     \n";

    $self->_inputFaster;

    my $command_line = $self->_processFaster;

    if (($self->_position eq "last") && ($self->_no_standard_output)) {
	warn "print no standard output\n";

	if (($self->_no_standard_output eq "TXT") || ($self->_no_standard_output == 5)){
	    $self->textoutput;
	}
    } else {
	$self->_outputParsing;
    }
#     # Put log information 

    my $information = { 'software_name' => $self->_config->name,
			'comments' => $self->_config->comments,
			'command_line' => $command_line,
			'list_modified_level' => ['phrase_level', 'semantic_unit_level', 'domain_specific_relation_level'],
    };
    $self->_log($information);


    warn "[LOG] done\n";
}

sub textoutput {
    my ($self) = @_;

    my $line;
    my $sentence_id;
    my $term;
    my $term_id;
    my $term_variante;
    my $numeric_information;
    my $MSrelation_type;
    my $term_variante_clean;

    binmode(STDOUT, ":utf8");
    open FASTEROUTPUT, $self->_output_filename or warn "No such file " . $self->_output_filename;
    binmode(FASTEROUTPUT, ":encoding(latin1)");

    while($line = <FASTEROUTPUT>) {
	chomp $line;
# 	warn "$line\n";
	if ($line =~ /\tX[^\t]+$/) {
#  	    warn "=> $line\n";
	    ($sentence_id, $term, $term_id, $term_variante, $numeric_information, $MSrelation_type) = split /\t/, $line;
	    $term_variante =~ s/^\s+//og;
	    $term_variante_clean = $term_variante;
	    $term_variante_clean =~ s/\[[^\]]+\]//og;

	    print "$term\t$term_variante_clean\t$MSrelation_type\n";
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

