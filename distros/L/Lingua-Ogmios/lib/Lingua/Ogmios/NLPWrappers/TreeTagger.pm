package Lingua::Ogmios::NLPWrappers::TreeTagger;


our $VERSION='0.1';

use utf8;

use Lingua::Ogmios::NLPWrappers::Wrapper;

use Lingua::Ogmios::Annotations::MorphosyntacticFeatures;
use Lingua::Ogmios::Annotations::Lemma;

use Encode qw(:fallbacks);;


use strict;
use warnings;

our @ISA = qw(Lingua::Ogmios::NLPWrappers::Wrapper);

sub new {
    my ($class, $config, $tmpfile_prefix, $logfile, $position, $no_standard_output) = @_;

    warn "[LOG]    Creating a wrapper of the TreeTagger\n";


    my $TreeTagger = $class->SUPER::new($config, $tmpfile_prefix, $logfile, $position, $no_standard_output);

    $TreeTagger->_input_filename($tmpfile_prefix . ".TreeTagger.in");
    $TreeTagger->_output_filename($tmpfile_prefix . ".TreeTagger.out");

    unlink($TreeTagger->_input_filename);
    unlink($TreeTagger->_output_filename);

    return($TreeTagger);

}

sub _processTreeTagger {
    my ($self, $lang) = @_;

    warn "[LOG] POS tagger\n";

    $lang = $self->_documentSet->[0]->getAnnotations->getLanguage;

    return($self->_exec_command($self->_defineCommandLine($self->_config->commands($lang)->{TreeTagger_CMD} . " < " . $self->_input_filename . ">" . $self->_output_filename)));

    warn "[LOG]\n";
}

sub _inputTreeTagger {
    my ($self) = @_;

    my $token;
    my $next_token;
#     my $corpus_in = "";
    my $document;
    my $doc_idx;
    my $previously_end_sentence = 0;
    my $docId;
    my @corpus_in_t;
    my @elementRef;

    my $word;
    warn "[LOG] making Decision TreeTagger input\n";
    
#    foreach $document (@{$self->_documentSet}) {
    for($docId = 0; $docId < scalar(@{$self->_documentSet});$docId++) {
	$document = $self->_documentSet->[$docId];
	$previously_end_sentence = 0;
	for($doc_idx = 0; $doc_idx < scalar(@{$document->getAnnotations->getTokenLevel->getElements});$doc_idx++) {
	    $token = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];
	    # warn "$doc_idx: " . $token->getContent . "\n";
	    if ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
		# WORD
		$word = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];
		my $wordform = $word->getForm;
		$wordform =~ s/[\t\n]/ /gos;
		$wordform =~ s/  +/ /gos;
		push @corpus_in_t, "$wordform";
		push @elementRef, ["word", $docId, [$word->getId]];
		$previously_end_sentence = 0;

		$doc_idx += $word->getReferenceSize - 1;
 		$token = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];
	    # warn "$doc_idx: " . $token->getContent . "\n";
	    } else {
		if (!($token->isSep)) {
		    if (($token->getContent =~ /[\x{2019}\x{2032}']/go) && ($previously_end_sentence == 0) && ($#corpus_in_t > -1) ) {
			# (!$document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->previous->getId))) {
			$corpus_in_t[$#corpus_in_t] .= $token->getContent;
			push @{$elementRef[$#elementRef]->[2]}, $token->getId;
		    } else {
			push @corpus_in_t, $token->getContent;
			push @elementRef, ["token", $docId, [$token->getId]];
			$previously_end_sentence = 0;
		    }
		}
	    }
	    if ($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId)) {
		if ($token->isSymb) {
		    if (!($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId))) {
			$corpus_in_t[$#corpus_in_t] .= "\tSENT";
		    } else {
			push @corpus_in_t, $token->getContent . "\tSENT";
			push @elementRef, ["token", $docId, [$token->getId]];
		    }
		} else {
		    push @corpus_in_t, ".\tSENT";
		    push @elementRef, ["empty",$docId,[]];
		}
		$previously_end_sentence = 1;
	    }

	}
    }
    $self->_input_array(\@elementRef);
    warn "elementRef: " . scalar(@elementRef) . "\n";
    warn "corpus_in_t: " . scalar(@corpus_in_t) . "\n";
    open FILE_IN, ">" . $self->_input_filename;
    
#      print FILE_IN Encode::encode("iso-8859-1", $corpus_in, Encode::FB_DEFAULT); #$corpus_in;
    map {$_ =~ s/[\x{2019}\x{2032}]/\'/go} @corpus_in_t;

    print FILE_IN Encode::encode("iso-8859-1", join("\n",@corpus_in_t), Encode::FB_DEFAULT); #$corpus_in;
    print FILE_IN "\n";
    close FILE_IN;
    
    warn "[LOG] done\n";


}

sub _outputParsing {
    my ($self) = @_;
    my $line;
    my @TreeTaggerOutput;

    warn "[LOG] . Parsing " . $self->_output_filename . "\n";

    open FILE_OUT, $self->_output_filename or warn "Can't open the file " . $self->_output_filename;;
#    binmode(FILE_OUT, ":utf8");

    while($line = <FILE_OUT>) {
	chomp $line;
	if ($line ne "") {
	    # $line =~ s/œ/oe/go;
	    # $line =~ s//oe/go;
	    my @tmp = split /\t/, $line;
	    # work around some strange tagging 
	    if (!defined $tmp[1]) {
		$tmp[1] = "SYM";
	    }
	    if ((!defined $tmp[2]) || ($tmp[2] eq '@card@') || ($tmp[2] eq '@ord@')) {
		$tmp[2] = $tmp[0];
	    }
#	    warn "$line\n";
	    push @TreeTaggerOutput, \@tmp;
	}

    }
    close FILE_OUT;

    warn "TT output size: " . scalar(@TreeTaggerOutput) . "\n";

    my $TreeTaggerOutput_idx = 0;
#    my $TreeTaggerInput_idx = 0;
    my $docId;
    my $document;
    my $word;
    my $posInLemma;
    my $posInWord;
    my $substringBefore;
    my $substringAfter;

    
    for($TreeTaggerOutput_idx = 0; $TreeTaggerOutput_idx < scalar(@{$self->_input_array}) ; $TreeTaggerOutput_idx++) {
	$document = $self->_documentSet->[$self->_input_array->[$TreeTaggerOutput_idx]->[1]];
	# warn join("\t", @{$TreeTaggerOutput[$TreeTaggerOutput_idx]}) . "\n";
	if ($self->_input_array->[$TreeTaggerOutput_idx]->[0] eq "word") {
	    # warn "=>word\n";
	    $word = $document->getAnnotations->getWordLevel->getElementById($self->_input_array->[$TreeTaggerOutput_idx]->[2]->[0]);

	    # Correct POSTag if it's named entity
	    if ($word->isNE) {
		$TreeTaggerOutput[$TreeTaggerOutput_idx]->[1] = "NP";
#  		    warn "Remove _ if it's a complex word i.e. a named entity\n";

		# Remove _ if it's a complex word i.e. a named entity

########################################################################
		# $posInLemma = 0;
		# do {
		#     if ((($posInLemma = index($TreeTaggerOutput[$TreeTaggerOutput_idx]->[2], "_"), $posInLemma) != -1) &&
		# 	((($posInWord = index($TreeTaggerOutput[$TreeTaggerOutput_idx]->[0], "_", $posInLemma)) == -1) || 
		# 	 ($posInLemma != $posInWord))) {
		# 	# warn "lemma to correct : " . $TreeTaggerOutput[$TreeTaggerOutput_idx]->[2] . "\n";
		# 	$substringBefore = substr($TreeTaggerOutput[$TreeTaggerOutput_idx]->[2], 0, $posInLemma);
		# 	$substringAfter = substr($TreeTaggerOutput[$TreeTaggerOutput_idx]->[2], $posInLemma + 1);
			
		# 	# warn "New lemma : $substringBefore $substringAfter ($posInLemma)\n";
		# 	$TreeTaggerOutput[$TreeTaggerOutput_idx]->[2] = "$substringBefore $substringAfter";
		# 	$posInLemma++;
		#     }
		# } while (($posInLemma != -1) && ($posInLemma != $posInWord) && ($posInLemma < length($TreeTaggerOutput[$TreeTaggerOutput_idx]->[2])));
########################################################################
	    }

	    # work around some strange tagging 
	    # warn "TreeTaggerOutput_idx: $TreeTaggerOutput_idx\n";
	    if (!defined $TreeTaggerOutput[$TreeTaggerOutput_idx]->[1]) {
		warn "** POSTAG not defined for $TreeTaggerOutput_idx (" . $TreeTaggerOutput[$TreeTaggerOutput_idx]->[0] .  ")\n";
		$TreeTaggerOutput[$TreeTaggerOutput_idx]->[1] = "SYM";
	    } else {
		if ($TreeTaggerOutput[$TreeTaggerOutput_idx]->[1] eq "SENT") {
		    $TreeTaggerOutput[$TreeTaggerOutput_idx]->[1] = "NP";
		}
	    }
	    # warn join("\t", @{$TreeTaggerOutput[$TreeTaggerOutput_idx]}) . "\n";

	    my $MSFeatures = Lingua::Ogmios::Annotations::MorphosyntacticFeatures->new(
		{'refid_word' => $word,
		 'syntactic_category' => $TreeTaggerOutput[$TreeTaggerOutput_idx]->[1],
		});
	    $document->getAnnotations->addMorphosyntacticFeatures($MSFeatures);
		

	    my $Lemma = Lingua::Ogmios::Annotations::Lemma->new(
		{'refid_word' => $word,
		 'canonical_form' => $TreeTaggerOutput[$TreeTaggerOutput_idx]->[2],
		});
	    $document->getAnnotations->addLemma($Lemma);

	} else {
	    # warn "=>other\n";
#	    $TreeTaggerOutput_idx++;

	}
    }

#    foreach $document (@{$self->_documentSet}) {


    warn "[LOG] done\n";
}


sub _outputParsing2 {
    my ($self) = @_;
    warn "[LOG] . Parsing " . $self->_output_filename . "\n";

    $self->_parseTreeTaggerFormatOutput($self->_output_filename, 0);

    warn "[LOG] done\n";
}


sub _outputParsing1 {
    my ($self) = @_;


    my $line;
    my @TreeTaggerOutput;

    my $doc_idx;
    my $word_idx;
    my $document;

    my $word;
    my $token;

    my $posInWord;
    my $posInLemma;
    my $tmpStr = "";
    my $substringBefore;
    my $substringAfter;
    my $previously_end_sentence = 0;

    warn "[LOG] . Parsing " . $self->_output_filename . "\n";

    open FILE_OUT, $self->_output_filename or warn "Can't open the file " . $self->_output_filename;;
#    binmode(FILE_OUT, ":utf8");

    while($line = <FILE_OUT>) {
	chomp $line;
	if ($line ne "") {
	    # $line =~ s/œ/oe/go;
	    # $line =~ s//oe/go;
	    my @tmp = split /\t/, $line;
	    # work around some strange tagging 
	    if (!defined $tmp[1]) {
		$tmp[1] = "SYM";
	    }
	    if ((!defined $tmp[2]) || ($tmp[2] eq '@card@') || ($tmp[2] eq '@ord@')) {
		$tmp[2] = $tmp[0];
	    }
#	    warn "$line\n";
	    push @TreeTaggerOutput, \@tmp;
	}

    }
    close FILE_OUT;

#      warn "TT output size: " . scalar(@TreeTaggerOutput) . "\n";

    my $TreeTaggerOutput_idx = 0;

    foreach $document (@{$self->_documentSet}) {
	$tmpStr = "";
	for($doc_idx = 0; $doc_idx < scalar(@{$document->getAnnotations->getTokenLevel->getElements});$doc_idx++) {
	    $token = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];
	    # warn "TOK: " . $token->getContent . "\n";
	    # warn "TreeTaggerOutput_idx: $TreeTaggerOutput_idx\n";
	    if ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
		$previously_end_sentence = 0;
		$word = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];

   		# warn "WORD: " . $word->getForm . " (" . $word->getId . ") " . $TreeTaggerOutput[$TreeTaggerOutput_idx]->[0] . "\n";

		# Correct POSTag if it's named entity
		if ($word->isNE) {
		    $TreeTaggerOutput[$TreeTaggerOutput_idx]->[1] = "NP";
#  		    warn "Remove _ if it's a complex word i.e. a named entity\n";

		# Remove _ if it's a complex word i.e. a named entity

		    $posInLemma = 0;
		    do {
			if ((($posInLemma = index($TreeTaggerOutput[$TreeTaggerOutput_idx]->[2], "_"), $posInLemma) != -1) &&
			    ((($posInWord = index($TreeTaggerOutput[$TreeTaggerOutput_idx]->[0], "_", $posInLemma)) == -1) || 
			     ($posInLemma != $posInWord))) {
   			    # warn "lemma to correct : " . $TreeTaggerOutput[$TreeTaggerOutput_idx]->[2] . "\n";
			    $substringBefore = substr($TreeTaggerOutput[$TreeTaggerOutput_idx]->[2], 0, $posInLemma);
			    $substringAfter = substr($TreeTaggerOutput[$TreeTaggerOutput_idx]->[2], $posInLemma + 1);
			    
   			    # warn "New lemma : $substringBefore $substringAfter ($posInLemma)\n";
			    $TreeTaggerOutput[$TreeTaggerOutput_idx]->[2] = "$substringBefore $substringAfter";
			    $posInLemma++;
			}
		    } while (($posInLemma != -1) && ($posInLemma != $posInWord) && ($posInLemma < length($TreeTaggerOutput[$TreeTaggerOutput_idx]->[2])));
		}

		# work around some strange tagging 
 		# warn "TreeTaggerOutput_idx: $TreeTaggerOutput_idx\n";
		if (!defined $TreeTaggerOutput[$TreeTaggerOutput_idx]->[1]) {
		    warn "** POSTAG not defined for $TreeTaggerOutput_idx (" . $TreeTaggerOutput[$TreeTaggerOutput_idx]->[0] .  ")\n";
		    $TreeTaggerOutput[$TreeTaggerOutput_idx]->[1] = "SYM";
		} else {
		    if ($TreeTaggerOutput[$TreeTaggerOutput_idx]->[1] eq "SENT") {
			$TreeTaggerOutput[$TreeTaggerOutput_idx]->[1] = "NP";
		    }
		}

		my $MSFeatures = Lingua::Ogmios::Annotations::MorphosyntacticFeatures->new(
		    {'refid_word' => $word,
		     'syntactic_category' => $TreeTaggerOutput[$TreeTaggerOutput_idx]->[1],
		    });
		$document->getAnnotations->addMorphosyntacticFeatures($MSFeatures);
		

		my $Lemma = Lingua::Ogmios::Annotations::Lemma->new(
		    {'refid_word' => $word,
		     'canonical_form' => $TreeTaggerOutput[$TreeTaggerOutput_idx]->[2],
		    });
		$document->getAnnotations->addLemma($Lemma);

		# warn "===> " . $MSFeatures->syntactic_category . " : " . $Lemma->canonical_form . "\n";

		$TreeTaggerOutput_idx++;

		$doc_idx += $word->getReferenceSize - 1;
 		$token = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];

	    } else {
		# warn "here (1)\n";
		# if ((!($token->isSep)) && (($token->getContent !~ /[\x{2019}\x{2032}']/go) || 
					   
		# 	((defined $token->previous) && 

		# 	 ($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->previous->getId))))) {
		#     $TreeTaggerOutput_idx++;
		# }
		if (!($token->isSep)) {
		    if (($token->getContent !~ /[\x{2019}\x{2032}']/go) || (length($TreeTaggerOutput[$TreeTaggerOutput_idx]->[0]) == 1)) {
			# warn "here (2) : $previously_end_sentence\n";
			$tmpStr .= $token->getContent;
			# warn $TreeTaggerOutput[$TreeTaggerOutput_idx]->[0] . "  /  " . $tmpStr . ";(1)\n";
			if (length($TreeTaggerOutput[$TreeTaggerOutput_idx]->[0]) == length($tmpStr)) {
			    # warn "=> new treetagger line\n";
			    $TreeTaggerOutput_idx++;
			    $tmpStr = "";
			}
		    } else {
			# warn ">> " . $token->previous->getContent . ":: $previously_end_sentence\n";
			# if (($previously_end_sentence) || ((defined $token->previous) && 
			#     ($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->previous->getId)))) {
			if ($previously_end_sentence) {
			    # warn ">>>> ===\n";
			    $TreeTaggerOutput_idx++;
			    $previously_end_sentence = 0;
			}
		if ($tmpStr ne "") {
		    $tmpStr .= $token->getContent;
		    # warn $TreeTaggerOutput[$TreeTaggerOutput_idx]->[0] . "  /  " . $tmpStr . ";(2)\n";
		    if (length($TreeTaggerOutput[$TreeTaggerOutput_idx]->[0]) == length($tmpStr)) {
			# warn "=> new treetagger line\n";
			$TreeTaggerOutput_idx++;
			$tmpStr = "";
		    }
		}
		    }
		}
		# warn $token->getContent . " (" . $token->getId . ") " . $TreeTaggerOutput[$TreeTaggerOutput_idx]->[0] . "\n";
	    }
	    if ($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId)) {
		$previously_end_sentence = 1;
		if ($token->isSymb) {
		    if ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
			
# 		    } else {
			$TreeTaggerOutput_idx++;
 			# warn $token->getContent . " (" . $token->getId . ") " . $TreeTaggerOutput[$TreeTaggerOutput_idx]->[0] . " 0 \n";
		    }
		} else {
		    $TreeTaggerOutput_idx++;
 		    # warn $token->getContent . "(.) ( 000 ) " . $TreeTaggerOutput[$TreeTaggerOutput_idx]->[0] . "\n";
		}
	    } else {
		$previously_end_sentence = 0;
		# warn "here (3)\n";
	    }
	}
    }
    warn "[LOG] done\n";
}

sub run {
    my ($self, $documentSet) = @_;

    my $line;

    # Set variables according the the configuration
    $self->_documentSet($documentSet);

    if ($documentSet->[0]->getAnnotations->existsLemmaLevel) {
	warn "lemmas exist in the first document\n";
	warn "  Assuming that no lemma idenfication is required for the current document set\n";
#	return(0);
    } else {
	if ($documentSet->[0]->getAnnotations->existsMorphosyntacticFeaturesLevel) {
	    warn "MorphosyntacticFeaturres exist in the first document\n";
	    warn "  Assuming that no Part-of-Speech tagging is required for the current document set\n";
#	return(0);
	} else {
	    warn "[LOG] POS tagger ...     \n";
	    $self->_inputTreeTagger;
	    
	    my $command_line = $self->_processTreeTagger;

	    $self->_outputParsing;
	    # Put log information 
	    my $information = { 'software_name' => 'Decision TreeTagger',
				'comments' => 'POS tagging\n',
				'command_line' => $command_line,
				'list_modified_level' => ['morphosyntactic_features_level', 'lemma_level'],
	    };

	    $self->_log($information);
	    my $document;
	    foreach $document (@{$documentSet}) {
		$document->getAnnotations->addLogProcessing(
		    Lingua::Ogmios::Annotations::LogProcessing->new(
			{ 'comments' => 'Found ' . $document->getAnnotations->getLemmaLevel->getSize . ' lemma\n',
			}
		    )
		    );
		$document->getAnnotations->addLogProcessing(
		    Lingua::Ogmios::Annotations::LogProcessing->new(
			{ 'comments' => 'Found ' . $document->getAnnotations->getMorphosyntacticFeaturesLevel->getSize . ' morphosyntactic features\n',
			}
		    )
		    );
		# basic check 
		if ($document->getAnnotations->getLemmaLevel->getSize != $document->getAnnotations->getWordLevel->getSize) {
		    warn "Document " . $document->getId . ": there is difference between word and lemma size\n";
		}
		if ($document->getAnnotations->getMorphosyntacticFeaturesLevel->getSize != $document->getAnnotations->getWordLevel->getSize) {
		    warn "Document " . $document->getId . ": there is difference between word and morphosyntactic feature size\n";
		}
	    }    

	}
    }
    
    if (($self->_position eq "last") && ($self->_no_standard_output)) {
	if (($self->_no_standard_output eq "IFPOSLM") || ($self->_no_standard_output == 1) || ($self->_no_standard_output == 2) || ($self->_no_standard_output == 3)) {

	    $self->_printTreeTaggerFormatOutput('stdout', 'LATIN1',0);
	}
	if ($self->_no_standard_output eq "IFPOSLMLINE") {
	    my $document;
	    my $word;
	    my $MS_features;
	    my $lemma;
	    my $sentence;
	    my $token_start;
	    my $token_end;
	    my $token;

	    my @word_set;
	    my @MS_features_set;
	    my @lemma_set;
	    
	    foreach $document (@{$documentSet}) {
		foreach $sentence (@{$document->getAnnotations->getSentenceLevel->getElements}) {
		    @word_set = ();
		    @MS_features_set = ();
		    @lemma_set = ();
		    $token_start = $sentence->refid_start_token;
		    $token = $token_start;
		    $token_end = $sentence->refid_end_token;
		    # do {
		    # 	if ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
		    # 	    $word = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];
		    # 	    $lemma = $document->getAnnotations->getLemmaLevel->getElementFromIndex("refid_word", $word->getId)->[0];
		    # 	    $MS_features = $document->getAnnotations->getMorphosyntacticFeaturesLevel->getElementFromIndex("refid_word", $word->getId)->[0];
		    # 	    push @word_set, $word->getForm;
		    # 	    push @MS_features_set, $MS_features->syntactic_category;
		    # 	    push @lemma_set, $lemma->canonical_form;
		    # 	    $token = $word->end_token;
		    # 	}
		    # 	if (!$token->equals($token_end)) {
		    # 	    $token = $token->next;
		    # 	}
		    # } while (!$token->equals($token_end));
			if ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
			    $word = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];
			    $lemma = $document->getAnnotations->getLemmaLevel->getElementFromIndex("refid_word", $word->getId)->[0];
			    $MS_features = $document->getAnnotations->getMorphosyntacticFeaturesLevel->getElementFromIndex("refid_word", $word->getId)->[0];
			    push @word_set, $word->getForm;
			    push @MS_features_set, $MS_features->syntactic_category;
			    push @lemma_set, $lemma->canonical_form;
			    $token = $word->end_token;
			}
		    while (!$token->equals($token_end)) {
			    $token = $token->next;
			    # warn $token->getContent . "\n";
			if ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
			    # warn "add\n";
			    $word = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];
			    $lemma = $document->getAnnotations->getLemmaLevel->getElementFromIndex("refid_word", $word->getId)->[0];
			    $MS_features = $document->getAnnotations->getMorphosyntacticFeaturesLevel->getElementFromIndex("refid_word", $word->getId)->[0];
			    push @word_set, $word->getForm;
			    push @MS_features_set, $MS_features->syntactic_category;
			    push @lemma_set, $lemma->canonical_form;
			    $token = $word->end_token;
			} else {
			    if (!$token->isSep) {
				push @word_set, $token->getContent;
				push @MS_features_set, "SYM";
				push @lemma_set, $token->getContent;
			    }
			}
		    }
		    print join(" ", @word_set);
		    print "\t";
		    print join(" ", @MS_features_set);
		    print "\t";
		    print join(" ", @lemma_set);
		    print "\n";
		}
	    }
	}
	if ($self->_no_standard_output eq "VOCABULARY") {
	    $self->_printVocabulary;
	}
	if ($self->_no_standard_output eq "VOCABULARY_ALL") {
	    binmode(STDOUT, ":utf8");
	    print "#####################\n";
	    print "# FF\n";
	    $self->_printVocabulary_FF;
	    print "#####################\n";
	    print "# LM\n";
	    $self->_printVocabulary_LM;
	    print "#####################\n";
	    print "# TAGSET\n";
	    $self->_printTagSet;
	}
	if ($self->_no_standard_output eq "TAGSET") {
	    $self->_printTagSet;
	}
    }

#     } else {
#     }

#     die "You call the 'rum' method of the wrapper class base\n
#          You should define a 'run' method for your wrapper\n";
    $self->getTimer->_printTimesInLine($self->_config->name);
    warn "[LOG] done\n";
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
