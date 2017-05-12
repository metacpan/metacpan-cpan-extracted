package Lingua::Ogmios::NLPWrappers::Wrapper;


our $VERSION='0.1';

use utf8;

use Config::General;

use Data::Dumper;

use Lingua::Ogmios::NLPWrappers::PatternParser;

use Lingua::Ogmios::Annotations::Phrase;
use Lingua::Ogmios::Annotations::SemanticUnit;
use Lingua::Ogmios::Annotations::SemanticFeatures;
use Lingua::Ogmios::Annotations::LogProcessing;
use Lingua::Ogmios::Timer;
use Lingua::Ogmios::LearningDataSet;
use Lingua::Ogmios::LearningDataSet::Attribute;
use Lingua::Ogmios::LearningDataSet::Data;

use strict;
use warnings;
sub new {
    my ($class, $config, $tmpfile_prefix, $logfile, $position, $no_standard_output, $out_stream) = @_;

    my $wrapper = {
	"config" => $config,
	"tmpfile_prefix" => $tmpfile_prefix,
	"documentSet" => undef,
	"input_filename" => undef,
	"tmp_filename" => undef,
	"output_filename" => undef,
	"logfile" => $logfile,
	"position" => $position, # position in the NL line processing
	"no_standard_output" => $no_standard_output,
	"timer" => Lingua::Ogmios::Timer->new(),
	"currentDocument" => undef,
	"out_stream" => $out_stream,
    };

    bless $wrapper, $class;

    $wrapper->{"timer"}->start;

#     die "You call the 'new' method of the wrapper class base\n
#          You should define a 'new' method for your wrapper\n";

    return($wrapper);
}

# sub _logfile {
#     my ($self) = @_;

#     die "You call the '_logfile' method of the wrapper class base\n
#          You should define a '_logfile' method for your wrapper\n";
# }


sub run {
    my ($self, $documentSet) = @_;

    die "You call the 'rum' method of the wrapper class base\n
         You should define a 'run' method for your wrapper\n";
}

sub _defineCommandLine {
    my ($self, $cmd, $input, $output) = @_;

    my $command_line;
    
    $command_line = "(";
    $command_line .= $cmd;
    $command_line .= ") "; 
    if (defined $input) {
	$command_line .= " < ";
	$command_line .= $input;
    } 
    if (defined $output) {
	$command_line .= " > ";
	$command_line .= $output;
    }
    $command_line .= " 2>> " . $self->_logfile;
    warn "[LOG] command line : $command_line\n";
    return($command_line);
}


sub _exec_command {

    my ($self, $command, $env_vars) = @_;
    my $cmd_withEnvVar = "";
    my $var;


    foreach $var (keys %$env_vars) {
	$cmd_withEnvVar .= "export " . $var . "=" . $env_vars->{$var} . " ; ";
    }
    $cmd_withEnvVar .= $command;
#      warn "Running $cmd_withEnvVar\n";
    `$cmd_withEnvVar`;

    return($cmd_withEnvVar);
}

sub _log {
    my ($self, $information) = @_;

    my $document;
    foreach $document (@{$self->_documentSet}) {
	$document->getAnnotations->addLogProcessing(Lingua::Ogmios::Annotations::LogProcessing->new($information));
    }    
}

sub _input_filename {
    my $self = shift;

    $self->{"input_filename"} = shift if @_;

    return($self->{"input_filename"});

}

sub _tmp_filename {
    my $self = shift;

    $self->{"input_filename"} = shift if @_;

    return($self->{"input_filename"});
}

sub _output_filename {
    my $self = shift;

    $self->{"output_filename"} = shift if @_;

    return($self->{"output_filename"});
}

sub _out_stream {
    my $self = shift;

    $self->{"out_stream"} = shift if @_;

    return($self->{"out_stream"});
}

sub _input_array {
    my $self = shift;

    $self->{"input_array"} = shift if @_;

    return($self->{"input_array"});
}

sub _output_array {
    my $self = shift;

    $self->{"output_array"} = shift if @_;

    return($self->{"output_array"});
}

sub _addedElements_array {
    my $self = shift;

    $self->{"addedElements_array"} = shift if @_;

    return($self->{"addedElements_array"});
}

sub _input_hash {
    my $self = shift;

    $self->{"input_hash"} = shift if @_;

    return($self->{"input_hash"});
}

sub _output_hash {
    my $self = shift;

    $self->{"output_hash"} = shift if @_;

    return($self->{"output_hash"});
}

sub _config {
    my $self = shift;

    $self->{"config"} = shift if @_;

    return($self->{"config"});

}
sub _position {
    my $self = shift;

    $self->{"position"} = shift if @_;

    return($self->{"position"});
}

sub _no_standard_output {
    my $self = shift;

    $self->{"no_standard_output"} = shift if @_;

    return($self->{"no_standard_output"});
}

sub _tmpfile_prefix {
    my $self = shift;

    $self->{"tmpfile_prefix"} = shift if @_;

#     warn "tmpfile_prefix:" . $self->{"tmpfile_prefix"} . "\n";

    return($self->{"tmpfile_prefix"});

}

sub _logfile {
    my $self = shift;

    $self->{"logfile"} = shift if @_;

    return($self->{"logfile"});
}

sub _documentSet {
    my $self = shift;

    if (@_) {
	$self->{'documentSet'} = shift;

	$self->setDocIndex2DocId;
	$self->setDocId2DocIndex;
    }
    return($self->{'documentSet'});
}

sub setDocIndex2DocId {

    my ($self) = @_;

    my $i;
    my @DocIndex2DocId;

    for($i=0;$i < scalar(@{$self->{'documentSet'}}); $i++) {
	$DocIndex2DocId[$i] = $self->{'documentSet'}->[$i]->getId;
    }

    $self->{DocIndex2DocId} = \@DocIndex2DocId;
}

sub setDocId2DocIndex {

    my ($self) = @_;

    my $i;
    my %DocId2DocIndex;

#     warn "In setDocId2Index\n";

    for($i=0;$i < scalar(@{$self->{'documentSet'}}); $i++) {
# 	warn $self->{'documentSet'}->[$i]->getId . " => $i\n";
	$DocId2DocIndex{$self->{'documentSet'}->[$i]->getId} = $i;
    }

    $self->{DocId2DocIndex} = \%DocId2DocIndex;

}

sub getDocId2DocIndex {

    my ($self) = @_;

    return($self->{DocId2DocIndex});
}

sub getDocIndex2DocId {

    my ($self) = @_;

    return($self->{DocIndex2DocId});
}

sub getDocumentFromDocId {

    my ($self, $docId) = @_;

    return($self->_documentSet->[$self->getDocId2DocIndex->{$docId}]);

}

sub getDocumentFromRank {

    my ($self, $rank) = @_;

    return($self->_documentSet->[$rank]);

}

sub _getLemmatisedSentence {
    my ($self, $document, $refid_start_token, $refid_end_token) = @_;

    my $word;
    my $lemma;

    my $sentLemma = "";;
    my $token = $refid_start_token;

    my $token_prec = 0;
    my %offsets;

    if (defined $token) {
	do {
	    # warn $token->getContent . "\n";
	    if ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
		$word = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];
		$lemma = $document->getAnnotations->getLemmaLevel->getElementFromIndex("refid_word", $word->getId)->[0];
# 	    $MS_features = $document->getAnnotations->getMorphosyntacticFeaturesLevel->getElementFromIndex("refid_word", $word->getId)->[0];
		# warn $word->getFrom . " : " . $lemma->canonical_form . " : " . length($sentLemma) . "($sentLemma)\n";
		$offsets{length($sentLemma)} = $word->reference;
		if (defined $lemma) {
		    $sentLemma .= $lemma->canonical_form;
		} else {
		    $sentLemma .= $word->getForm;
		}
		if (index($word->getForm, "'") == length($word->getForm) - 1) {
		    $sentLemma .= " ";
		}
		$token = $word->end_token;
		$token_prec = 0;
	    } else {
		$offsets{length($sentLemma)} = [$token];
		$sentLemma .= $token->getContent;
		$token_prec = 1;
	    }
	    if (defined $token) { #   {
		$token = $token->next;
	    }

	    # warn "=> " . length($sentLemma) . " ($sentLemma)\n";
	} while((defined $token) && (!($token->previous->equals($refid_end_token))));
    }
    # warn (length($sentLemma) - length($token->previous->getContent)) . "\n";
    # warn scalar(@{$offsets{length($sentLemma) - length($token->previous->getContent)}}) . " -- \n";
    # warn $offsets{length($sentLemma) - length($token->previous->getContent)}->[0]->getContent . "\n";
    # warn "-> $token_prec\n";
    # warn join(";", sort({$a <=> $b} keys %offsets)) . "\n";
    if (($token_prec == 0) && ($document->getAnnotations->getSectionLevel->existsElementFromIndex("to", $refid_end_token->getId))) {
	# warn "Add empty\n";
	$offsets{length($sentLemma)} = [];	
    }
    # warn join(";", sort({$a <=> $b} keys %offsets)) . "\n";
    # warn join(";", values %offsets) . "\n";

    # if ((defined $token) && ($token->isSymb)) {
    # 	if ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
    # 	    $offsets{length($sentLemma)} = $token;
    # 	    $sentLemma .= $token->getContent;
    # 	}
    # }
#    $sentLemma =~ s/ +/ /go;
    return($sentLemma, \%offsets);
}


sub _printTreeTaggerFormatOutput {
    my $self = shift;
    my $filename = shift;
    my $encoding = shift;
    my $printDocId = shift;

    my $fh_out;
    my $document;
    my $doc_idx;
    my $token;
    my $word;
    my $lemma;
    my $MS_features;
    my @corpus_in_t;

    warn "[LOG] printing TreeTagger Like Output\n";

    my $i = 0;
    foreach $document (@{$self->_documentSet}) {
	warn "$i : " . $document->getId . "\n";	
	$i++;
	my @tmp;
	if ((!defined $printDocId) || ($printDocId)) {
	    @tmp = ($document->getId, "DOCUMENT", $document->getId);
	    push @corpus_in_t, \@tmp;
	}
	
	for($doc_idx = 0; $doc_idx < scalar(@{$document->getAnnotations->getTokenLevel->getElements});$doc_idx++) {
# 	    warn "doc_idx: $doc_idx\n";
	    $token = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];
	    if ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
		$word = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];
		$lemma = $document->getAnnotations->getLemmaLevel->getElementFromIndex("refid_word", $word->getId)->[0];
		$MS_features = $document->getAnnotations->getMorphosyntacticFeaturesLevel->getElementFromIndex("refid_word", $word->getId)->[0];
		my $wordform = $word->getForm;
		$wordform =~ s/[\t\n]/ /gos;
		$wordform =~ s/  +/ /gos;
		
		my @tmp  = ($wordform, $MS_features->syntactic_category, $lemma->canonical_form);

		push @corpus_in_t, \@tmp;

		$doc_idx += $word->getReferenceSize - 1;
# 		warn "doc_idx (new value): $doc_idx\n";
 		$token = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];
		
	    } else {
		if (!($token->isSep)) {
		    if ($token->getContent =~ /[\x{2019}\x{2032}']/go) {
			$corpus_in_t[$#corpus_in_t]->[0] .= $token->getContent;
		    } else {
			my @tmp = ($token->getContent, $token->getContent, $token->getContent);
			push @corpus_in_t, \@tmp;
		    }
		}
	    }
	    if ($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId)) {
		if ($token->isSymb) {
		    if (!($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId))) {
			my @tmp = ($corpus_in_t[$#corpus_in_t]->[0] , "SENT", $corpus_in_t[$#corpus_in_t]->[0]);
			$corpus_in_t[$#corpus_in_t] = \@tmp;
		    } else {
			my @tmp = ($token->getContent, "SENT", $token->getContent);
			push @corpus_in_t, \@tmp;
		    }
		} else {
		    my @tmp = (".", "SENT", ".");
		    push @corpus_in_t, \@tmp;
		}
	    }
	}
    }

    warn "\tOpenning " . $filename . "\n";
    if ($filename ne "stdout") {
	open $fh_out, ">". $filename or die "can't open " . $filename . "\n";
    } else {
	$fh_out = \*STDOUT;
    }


    my $word_ref;
    foreach $word_ref (@corpus_in_t) {

	if ($word_ref->[0] =~ s/ /_/go) {
	    $word_ref->[2] =~ s/ /_/go;
	}

	if ($word_ref->[0] =~ s/[\x{2019}\x{2032}]/\'/go) {
	    $word_ref->[1] =~ s/[\x{2019}\x{2032}]/\'/go;
	    $word_ref->[2] =~ s/[\x{2019}\x{2032}]/\'/go;
	}

# Encode::encode("iso-8859-1", join("\n",@corpus_in_t), Encode::FB_DEFAULT);
	if ((!defined $encoding) || (uc($encoding) eq "UTF-8")) {
 	    print $fh_out Encode::encode("UTF-8", join("\t",@$word_ref)) . "\n";
	} else {
	    if ((defined $encoding) && (uc($encoding) eq "LATIN1")) {
# 	print FILE_IN Encode::encode("iso-8859-1", join("\t",@$word_ref), Encode::FB_DEFAULT) . "\n";
		print $fh_out Encode::encode("iso-8859-1", join("\t",@$word_ref)) . "\n";
	    } else {
		warn "[WRAPPER LOG] Unknown enconding charset\n";
	    }
	}
    }

    close $fh_out;
    warn "[LOG] done\n";
}


sub _createTermFromStartEndTokens {
    my ($self, $document, $token_start, $token_end) = @_;

    my @tokens;

    my $term_content = "";

    my $token = $token_start;

    # warn "start_token: " . $token->getFrom . " (" . $token->getContent . ")\n";
    $term_content = $token->getContent;

    push @tokens, $token;
    while((defined $token) && (!$token->equals($token_end))) {
	$token = $token->next;
	$term_content .= $token->getContent;
	push @tokens, $token;
    }
#    warn "term_content: $term_content\n";
    return($self->_createTerm($document, \@tokens, $term_content));

}

sub _changeSemanticFeatures {
    my ($self, $document, $oldTerm1, $oldTerm2, $newTerm) = @_;

    my $semf;

    if (defined $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $oldTerm1->getId)->[0]) {
	if ((defined $oldTerm2) && (defined $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $oldTerm2->getId)->[0])) {
	    my $semFeatures = Lingua::Ogmios::Annotations::SemanticFeatures->new(
		{ 'semantic_category' => $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $self->_getLargerTerm([$oldTerm1, $oldTerm2])->getId)->[0]->semantic_category,
		  'refid_semantic_unit' => $newTerm->getId,
		});
	    $document->getAnnotations->addSemanticFeatures($semFeatures);
	    
	    
	} else {
	    my $semFeatures = Lingua::Ogmios::Annotations::SemanticFeatures->new(
		{ 'semantic_category' => $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $oldTerm1->getId)->[0]->semantic_category,
		  'refid_semantic_unit' => $newTerm->getId,
		});
	    $document->getAnnotations->addSemanticFeatures($semFeatures);
	} 
    } else {
	if ((defined $oldTerm2) && (defined $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $oldTerm2->getId)->[0])) {
	    my $semFeatures = Lingua::Ogmios::Annotations::SemanticFeatures->new(
		{ 'semantic_category' => $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $oldTerm2->getId)->[0]->semantic_category,
		  'refid_semantic_unit' => $newTerm->getId,
		});
	    $document->getAnnotations->addSemanticFeatures($semFeatures);
	}
    }
}

sub _getLargerTerm {
    my ($self, $terms) = @_;

    my $largerTerm;
    my $tmpTerm;

    $largerTerm = $terms->[0];

    foreach $tmpTerm (@$terms) {
	if (!$tmpTerm->equals($largerTerm))  {
	    if (($tmpTerm->start_token->getFrom < $largerTerm->start_token->getFrom  ) ||
		($largerTerm->end_token->getTo  < $tmpTerm->end_token->getTo)) {
		$largerTerm = $tmpTerm
	    }
	}
    }
    return($largerTerm);
}



sub _createTerm {
    my ($self, $document, $termTokens, $term_content, $termType) = @_;

    my $token_offset = $termTokens->[0];
    my @termWords;

    my $termUnit;

    $termUnit = $document->getAnnotations->getSemanticUnitLevel->getElementByStartEndTokens($termTokens->[0], $termTokens->[scalar(@$termTokens) - 1]);

    if (!defined $termUnit) {
	do {
	    if ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token_offset->getId)) {
		## search the last word
		push @termWords, $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token_offset->getId)->[0];
		$token_offset = $termWords[$#termWords]->getLastToken;
	    }
	    $token_offset = $token_offset->next;
	} while((defined $token_offset) && ($token_offset->getTo < $termTokens->[$#$termTokens]->next->getTo));

	if ((scalar @termWords != 0) && 
	    (($termTokens->[$#$termTokens]->getTo != $termWords[$#termWords]->getLastToken->getTo) ||
	     ($termTokens->[0]->getFrom != $termWords[0]->start_token->getFrom))) {
	    @termWords = ();
	}
	if (scalar @termWords == 0) {
	    # term is a token list
	    my @localTermTokens = @$termTokens;
	    if ((!defined($termType)) || ($termType eq "term")) {
		$termUnit = Lingua::Ogmios::Annotations::SemanticUnit->newTerm(
		    {'form' => $term_content,
		     'list_refid_token' => \@localTermTokens,
		    });
		# warn "create Term (a)\n";
	    } else {
		if ($termType eq "named_entity") {
		    $termUnit = Lingua::Ogmios::Annotations::SemanticUnit->newNamedEntity(
			{'form' => $term_content,
			 'list_refid_token' => \@localTermTokens,
			 'named_entity_type' => "",
			});
		    # warn "create Named Entity (a)\n";
		}
	    }
	}
	if (scalar @termWords == 1) {
	    # term is a word
	    $term_content = $termWords[0]->getForm;
	    if ((!defined($termType)) || ($termType eq "term")) {
		$termUnit = Lingua::Ogmios::Annotations::SemanticUnit->newTerm(
		    {'form' => $term_content,
		     'refid_word' => $termWords[0],
		    });
		# warn "create Term (b)\n";
	    } else {
		if ($termType eq "named_entity") {
		    $termUnit = Lingua::Ogmios::Annotations::SemanticUnit->newNamedEntity(
			{'form' => $term_content,
			 'refid_word' => $termWords[0],
			 'named_entity_type' => "",
			});
		    # warn "create Named Entity (b)\n";
		}
	    }
	}
	if (scalar @termWords > 1) {
	    # term is a phrase
	    my $phrase = Lingua::Ogmios::Annotations::Phrase->new(
		{ 'refid_word' => \@termWords,
		  'form' => $term_content,
		}
		);

	    $document->getAnnotations->addPhrase($phrase);
	    if ((!defined($termType)) || ($termType eq "term")) {
		$termUnit = Lingua::Ogmios::Annotations::SemanticUnit->newTerm(
		    {'form' => $term_content,
		     'refid_phrase' => $phrase,
		    });
		# warn "create Term (c)\n";
	    } else {
		if ($termType eq "named_entity") {
		    $termUnit = Lingua::Ogmios::Annotations::SemanticUnit->newNamedEntity(
			{'form' => $term_content,
			 'refid_phrase' => $phrase,
			 'named_entity_type' => "",
			});
		    # warn "create Named Entity (c)\n";
		}
	    }
	}
    } else {
	warn "$term_content already exists\n";
	
    }
    return($termUnit);
}

sub HTMLoutput {
    my $self = shift;

    my $document;
    my $doc_token_idx;
    my $token;
    my $word;
    my $term;
    my $phrase;
    my $doc_str;
    my $i;
    my $phraseWords;
    my $termToken;
    my %NEtypeColor;
    my $sentId;
    my %colorTypes;
#     my %TermtypeColor = ("test", "0000FF", "problem", "FF0000", "treatment" , "00FF00") ;

    my $TermtypeColor = $self->_loadColors; #  OR ("test", "0000FF", "problem", "FF0000", "treatment" , "00FF00") ;
    
#    %NEtypeColor = %$TermtypeColor;

    my $semf;
    my $idColor;

    my $color = "FFCBDB";


    my $headerStart = << 'EOH';
<html>
<head>
<title>Tagged term candidates</title>
<link href="i2b2Style.css" rel="stylesheet" type="text/css"/>
<SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="infobox.js"></SCRIPT>
EOH

    my $headerEnd = << 'EOH';
</head><body>
EOH


    my $footer = << 'EOF';
</body></html>
EOF

     foreach $document (@{$self->_documentSet}) {
	$doc_str = "";
 	for($doc_token_idx = 0; $doc_token_idx < scalar(@{$document->getAnnotations->getTokenLevel->getElements});$doc_token_idx++) {
	    $token = $document->getAnnotations->getTokenLevel->getElements->[$doc_token_idx];

	    if ($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_start_token", $token->getId)) {
		$sentId = $document->getAnnotations->getSentenceLevel->getElementFromIndex("refid_start_token", $token->getId)->[0]->getId;
		$doc_str .= "<div id=\"" . $document->getId . "-$sentId" . "\" style=\"display:block\">\n";
	    }
	    $color = "FFCBDB";
	    # warn $token->getContent . "\n";
	    # if ($document->getAnnotations->getSemanticUnitLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
	    if ($document->getAnnotations->getSemanticUnitLevel->existsElementByToken($token)) {
		$term = $self->_getLargerTerm($document->getAnnotations->getSemanticUnitLevel->getElementByToken($token));
#		warn "TermForm: " . $term->getForm . "\n";
		if ($term->isNamedEntity) {
		    $idColor = $self->_getIdColor($term->NEtype, \%colorTypes);

		} else {
		    if ($document->getAnnotations->getSemanticFeaturesLevel->existsElementFromIndex("refid_semantic_unit", $term->getId)) {
			$semf = $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $term->getId)->[0];
			if (defined $semf) {
			    $idColor = $self->_getIdColor($semf->first_node_first_semantic_category, \%colorTypes);
			}
		    }
		}
		$doc_str .= $self->_genHTMLTagSemUnit_start($idColor);
		$termToken = $term->start_token;
		while(!$termToken->equals($token)) {
		    $termToken = $termToken->next;
		}
		while(!$termToken->equals($term->end_token)) {
		    $doc_str .= $termToken->getContent;
		    $termToken = $termToken->next;
		}
		if (defined $termToken) {
		    $doc_str .= $termToken->getContent;
		}
		$doc_str .= $self->_genHTMLTagSemUnit_end;
		# warn "Size: " . $term->getReferenceTokenSize . " $doc_str\n";
		$doc_token_idx += $term->getReferenceTokenSize - 1; 
	#	next;
# 	    } elsif ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
#  		$word = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];
# 		warn "passe" . $word->getForm . "\n";
# 		if ($document->getAnnotations->getPhraseLevel->existsElementFromIndex("refid_word", $word->getId)) {
# 		    $phrase = $document->getAnnotations->getPhraseLevel->getElementFromIndex("refid_word", $word->getId)->[0];
# 		    if ($document->getAnnotations->getSemanticUnitLevel->existsElementFromIndex("refid_phrase", $phrase->getId)) {
# 			$term = $document->getAnnotations->getSemanticUnitLevel->getElementFromIndex("refid_phrase", $phrase->getId)->[0];
# 			if ($term->isNamedEntity) {
# 			    $idColor = $self->_getIdColor($term->NEtype, \%colorTypes);
# 			} else {
# 			    if ($document->getAnnotations->getSemanticFeaturesLevel->existsElementFromIndex("refid_semantic_unit", $term->getId)) {
# 				$semf = $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $term->getId)->[0];
# 				$idColor = $self->_getIdColor($semf->first_node_first_semantic_category, \%colorTypes);
# 			    }
# 			}
# 			$doc_str .= $self->_genHTMLTagSemUnit_start($idColor);
# 			$i = 0;
# 			$phraseWords = $phrase->reference;
# 			while(($i < scalar(@$phraseWords)) && (!$word->equals($phraseWords->[$i]))) {
# 			    $i++;
# 			}
# 			while($i < scalar(@$phraseWords)) {
# 			    $doc_str .= $phraseWords->[$i]->getForm;
# 			    $i++;
# 			}
# 			$doc_str .= $self->_genHTMLTagSemUnit_end;
# 			$doc_token_idx += $phrase->getReferenceSize - 1; 
# #			next;		    
# 		    }
# 		} else {
# 		    if ($document->getAnnotations->getSemanticUnitLevel->existsElementFromIndex("refid_word", $word->getId)) {
# 			$term = $document->getAnnotations->getSemanticUnitLevel->getElementFromIndex("refid_word", $word->getId)->[0];
# 			if ($term->isNamedEntity) {
# 			    $idColor = $self->_getIdColor($term->NEtype, \%colorTypes);
# 			} else {
# 			    if ($document->getAnnotations->getSemanticFeaturesLevel->existsElementFromIndex("refid_semantic_unit", $term->getId)) {
# 				$semf = $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $term->getId)->[0];

#  				$idColor = $self->_getIdColor($semf->first_node_first_semantic_category, \%colorTypes);

# 			    }
# 			}
# 			$doc_str .= $self->_genHTMLTagSemUnit($idColor, $term->getForm);
# 			$doc_token_idx += $word->getReferenceSize - 1; 
# #			next;		    
# 		    }
# 		}
	    } else {
		$doc_str .= $token->getContent;
	    }
	    if ($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId)) {
		$doc_str .= "<\/div>\n<p/>\n";
	    }
	}
	$doc_str =~ s/\n/\n<P>\n/go;

	print "$headerStart\n";

	print "$headerEnd\n";
	print '<DIV ID="infodiv" STYLE="position:absolute; visibility:hidden; z-index:20; top:0px; left:0px;"></DIV>' . "\n";
	print '<SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript">' . "\n";
	print "maketip('Terms','Semantic type','Untagged Terms');\n"; 

 	foreach my $Termtype (sort {$colorTypes{$b} cmp $colorTypes{$a}} keys %colorTypes) {
 	    $idColor = $colorTypes{$Termtype};
	    print "maketip('" . $idColor . "','Semantic type','" . $Termtype . "');\n"; 
 	}

	print '</SCRIPT>' . "\n";
	print "<BR><B>document ID: " . $document->getId . "</B><BR>\n";
	print "<HR>\n";
	print "colors: <BR>\n<ul>\n";
	$color = "FFCBDB"; # 0000FF
	print "<li><a class=\"Terms\">Terms</a></li>\n";
	foreach my $Termtype (sort {$colorTypes{$b} cmp $colorTypes{$a}} keys %colorTypes) {
	    $idColor = $colorTypes{$Termtype};
	    print "<li><a class=\"" . $idColor . "\">$Termtype = $idColor</a></li>\n";
	}
	
	print "</ul>\n<HR>\n";
	print $doc_str;
	print "\n<HR>\n";
    }    
    print  "\n$footer\n"
}

sub HTMLoutputOld {
    my $self = shift;

    my $document;
    my $doc_token_idx;
    my $token;
    my $word;
    my $term;
    my $phrase;
    my $doc_str;
    my $i;
    my $phraseWords;
    my $termToken;
    my %NEtypeColor;

#     my %TermtypeColor = ("test", "0000FF", "problem", "FF0000", "treatment" , "00FF00") ;

    my $TermtypeColor = $self->_loadColors; #  OR ("test", "0000FF", "problem", "FF0000", "treatment" , "00FF00") ;
    
#    %NEtypeColor = %$TermtypeColor;

    my $semf;
    my $color = "FFCBDB";

    my $header = << 'EOH';
<html>
<head>
<title>Tagged term candidates</title>
</head><body>
EOH

    my $footer = << 'EOF';
</body></html>
EOF

print "$header\n";
     foreach $document (@{$self->_documentSet}) {
	$doc_str = "";
 	for($doc_token_idx = 0; $doc_token_idx < scalar(@{$document->getAnnotations->getTokenLevel->getElements});$doc_token_idx++) {
	    $token = $document->getAnnotations->getTokenLevel->getElements->[$doc_token_idx];
	    $color = "FFCBDB";
	    if ($document->getAnnotations->getSemanticUnitLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
		$term = $document->getAnnotations->getSemanticUnitLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];
		if ($term->isNamedEntity) {
		    $color = $self->_determinedColor($term->NEtype, $TermtypeColor);

		} else {
		    if ($document->getAnnotations->getSemanticFeaturesLevel->existsElementFromIndex("refid_semantic_unit", $term->getId)) {
			$semf = $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $term->getId)->[0];
			$color = $self->_determinedColor($semf->first_node_first_semantic_category, $TermtypeColor);
		    }
		}
		# $doc_str .= "<B><FONT COLOR =\"$color\">" . $term->getForm . "</FONT></B>";
		$doc_str .= "<B><FONT COLOR =\"$color\">";
#		$doc_str .= $term->getForm;
		$termToken = $term->start_token;
		while(!$termToken->equals($token)) {
		    $termToken = $termToken->next;
		}
		while(!$termToken->equals($term->end_token)) {
		    $doc_str .= $termToken->getContent;
		    $termToken = $termToken->next;
		}
		if (defined $termToken) {
		    $doc_str .= $termToken->getContent;
		}
		$doc_str .= "</FONT></B>";
		$doc_token_idx += $term->getReferenceSize - 1; 
		next;
	    }
	    if ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
 		$word = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];
		if ($document->getAnnotations->getPhraseLevel->existsElementFromIndex("refid_word", $word->getId)) {
		    $phrase = $document->getAnnotations->getPhraseLevel->getElementFromIndex("refid_word", $word->getId)->[0];
		    if ($document->getAnnotations->getSemanticUnitLevel->existsElementFromIndex("refid_phrase", $phrase->getId)) {
			$term = $document->getAnnotations->getSemanticUnitLevel->getElementFromIndex("refid_phrase", $phrase->getId)->[0];
			if ($term->isNamedEntity) {
			    $color = $self->_determinedColor($term->NEtype, $TermtypeColor);
			} else {
			    if ($document->getAnnotations->getSemanticFeaturesLevel->existsElementFromIndex("refid_semantic_unit", $term->getId)) {
				$semf = $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $term->getId)->[0];
				$color = $self->_determinedColor($semf->first_node_first_semantic_category, $TermtypeColor);
			    }
			}
			# $doc_str .= "<B><FONT COLOR =\"$color\">" . $term->getForm . "</FONT></B>";
			$doc_str .= "<B><FONT COLOR =\"$color\">";
			$i = 0;
			$phraseWords = $phrase->reference;
			while(($i < scalar(@$phraseWords)) && (!$word->equals($phraseWords->[$i]))) {
			    $i++;
			}
			while($i < scalar(@$phraseWords)) {
			    $doc_str .= $phraseWords->[$i]->getForm;
			    $i++;
			}
			$doc_str .=  "</FONT></B>";
			$doc_token_idx += $phrase->getReferenceSize - 1; 
			next;		    
		    }
		} else {
		    if ($document->getAnnotations->getSemanticUnitLevel->existsElementFromIndex("refid_word", $word->getId)) {
			$term = $document->getAnnotations->getSemanticUnitLevel->getElementFromIndex("refid_word", $word->getId)->[0];
			if ($term->isNamedEntity) {
			    $color = $self->_determinedColor($term->NEtype, $TermtypeColor);
			} else {
			    if ($document->getAnnotations->getSemanticFeaturesLevel->existsElementFromIndex("refid_semantic_unit", $term->getId)) {
				$semf = $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $term->getId)->[0];

# 				$color = $self->_determinedColor("medication", $TermtypeColor);
 				$color = $self->_determinedColor($semf->first_node_first_semantic_category, $TermtypeColor);

			    }
			}
			$doc_str .= "<B><FONT COLOR =\"$color\">" . $term->getForm . "</FONT></B>";
			$doc_token_idx += $word->getReferenceSize - 1; 
			next;		    
		    }
		}
	    }
	    $doc_str .= $token->getContent;
	    if ($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId)) {
		$doc_str .= "\n<p/>\n";
	    }
	}
	$doc_str =~ s/\n/\n<P>\n/go;

#	warn $document->getId . "\n";
	print "<BR><B>document ID: " . $document->getId . "</B><BR>\n";
	print "<HR>\n";
	print "colors: <BR>\n<ul>\n";
	# foreach my $NEtype (keys %NEtypeColor) {
	#     $color = $NEtypeColor{$NEtype};
	#     print "<LI><b><FONT COLOR=\"" . $color . "\">$NEtype = $color</FONT></b></LI>\n";
	# }
	$color = "FFCBDB"; # 0000FF
	print "<LI><b><FONT COLOR=\"" . $color . "\">Terms = $color</FONT></b></LI>\n";
	foreach my $Termtype (sort {$TermtypeColor->{$b} cmp $TermtypeColor->{$a}} keys %$TermtypeColor) {
	    $color = $TermtypeColor->{$Termtype};
	    print "<LI><b><FONT COLOR=\"" . $color . "\">$Termtype = $color</FONT></b></LI>\n";
	}
	
	print "</ul>\n<HR>\n";
	print $doc_str;
	print "\n<HR>\n";
    }    
    print  "\n$footer\n"
}

sub _loadColors {
    my ($self) = @_;

    my $cg = new Config::General('-ConfigFile' => $self->_config->configuration->{'RESOURCE'}->{"language=EN"}->{'COLORFILE'},
				 '-InterPolateVars' => 1,
				 '-InterPolateEnv' => 1,
	);
    
    my %colors = $cg->getall;
    
    return(\%colors);
}


sub _genHTMLTagSemUnit_start {
    my ($self, $idColor) = @_;

# onMouseOver="tip('alpha')" onMouseOut="untip()"
# <a href="#"style="text-decoration:none"  onMouseOver="tip('alpha')" onMouseOut="untip()">


    my $str = "<a class=\"$idColor\" href='#' onMouseOver=\"tip('$idColor')\" onMouseOut=\"untip()\">";
    return($str);
}

sub _genHTMLTagSemUnit_end {
    my ($self) = @_;

    my $str = "</a>";
    return($str);
}

sub _genHTMLTagSemUnit {
    my ($self, $idColor, $term_str) = @_;

    my $str;

    $str = $self->_genHTMLTagSemUnit_start($idColor);
    $str .= $term_str;
    $str .= $self->_genHTMLTagSemUnit_end;
    
    return($str);
}


sub _getIdColor {
    my ($self, $type, $typeColor) = @_ ;

    my $color;

#    warn "$type\n";
    if (!exists $typeColor->{$type}) {
	$typeColor->{$type} = lc($type);
#	$typeColor->{$type} =~ s/\-/_/go;
    } else {
#	$color = $typeColor->{$type}
    }
    return($typeColor->{$type});

}

sub _determinedColor {
    my ($self, $type, $typeColor) = @_ ;

    my $color;

    if (!exists $typeColor->{$type}) {
#     $color = "FF" . sprintf("%X", (ord(substr($type, 0, 1)) % 16)) . "0" . sprintf("%X", (ord(substr($type, 1, 1)) % 16)) . "0";
 	$color = "FFCBDB";
	$typeColor->{$type} = $color;
    } else {
	$color = $typeColor->{$type};
    }
    return($color);
#     return("FFCBDB");
}


sub _getEndForm {

    my ($self, $nextTerm, $document, $end_form, $endTokens) = @_;

    my $token;

    $token = $nextTerm->end_token;
    while ((defined $token->next) &&
 	   (($token->next->isSep) || ($token->next->isSymb)) &&
# 	   (index($token->getContent, ")") == -1) &&
 	   (!$document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId))
	) {
	$token = $token->next;
	push @$endTokens, $token;
    }

    $token = $$endTokens[$#$endTokens];
    while((scalar(@$endTokens) > 0) && ($token->isSep)) {
	pop @$endTokens;
	$token = $$endTokens[$#$endTokens];
    }
    foreach $token (@$endTokens) {
	$$end_form .= $token->getContent;
    }
    return($$endTokens[$#$endTokens]);
}


# Take into account the sem tag
sub _semanticUnitMerging {
    my ($self, $document, $firstTerm, $secondTerm, $sepForm, $sepTokens, $endForm, $endTokens) = @_;

    my @Term2tokens;
    my $token;
    my $term_form;
    my $id;
    my $newTerm;

    # warn "Merging " . $firstTerm->getForm . " : " . $firstTerm->type . "\n";

    # if (defined $secondTerm) {
    # warn "    with " . $secondTerm->getForm . " : " . $secondTerm->type. "\n";
    # }
    # if (defined $endForm) {
    # 	warn "    with $endForm\n";
    # }
#    warn "Merging " . $firstTerm->getForm . " and " . $secondTerm->getForm . "\n";

    # Merge Term if same type
#     warn "in _semanticUnitMerging\n";

#     warn $firstTerm->reference_name . "\n";
#     warn $firstTerm->reference . "\n";

    $token = $firstTerm->start_token;
    push @Term2tokens, $token;
    while(!$token->equals($firstTerm->end_token)) {
	$token = $token->next;
	push @Term2tokens, $token;	    
    };
    $term_form = $firstTerm->getForm;

    if (defined $sepForm) {
	push @Term2tokens, @$sepTokens;
	$term_form .= $sepForm;
	$token = $sepTokens->[$#$sepTokens];
    } else {
	$token = $firstTerm->end_token;
    }
    if (defined $secondTerm) {
	while(!($token->equals($secondTerm->end_token))) {
	    $token = $token->next;
	    push @Term2tokens, $token;
	    $term_form .= $token->getContent;
	}
    }

    if (defined $endForm) {
	push @Term2tokens, @$endTokens;
	$term_form .= $endForm;
    }

    $newTerm = $self->_createTerm($document, \@Term2tokens, $term_form, $firstTerm->type);
    if ($newTerm->getId == -1) {
	# Add semantic Modification
	$id = $document->getAnnotations->addSemanticUnit($newTerm);
	# warn "\tnewTerm: " . $newTerm->getForm . " ($id)\n";
	my $semf;
	if ($firstTerm->isTerm) {
	    if (defined $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $firstTerm->getId)->[0]) {
		my $semFeatures = Lingua::Ogmios::Annotations::SemanticFeatures->new(
		    { 'semantic_category' => [@{$document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $firstTerm->getId)->[0]->semantic_category}],
		      'refid_semantic_unit' => $newTerm->getId,
		    });
		$document->getAnnotations->addSemanticFeatures($semFeatures);
	    } 
	    # if (!$firstTerm->equals($newTerm)) {
	    #     warn "del1a\n";
	    #     $document->getAnnotations->delSemanticUnit($firstTerm);
	    # }
	} elsif ($firstTerm->isNamedEntity) {
	    # warn $firstTerm->NEtype . "\n";
	    $newTerm->NEtype($firstTerm->NEtype);
	    # if (!$firstTerm->equals($newTerm)) {
	    # 	$document->getAnnotations->delSemanticUnit($firstTerm);
	    # }
	}
    }

    if (!$firstTerm->equals($newTerm)) {
	# warn "del1b\n";
	$document->getAnnotations->delSemanticUnit($firstTerm);
    }
    if ((defined $secondTerm) && ($secondTerm->isTerm)) {
	if (!$secondTerm->equals($newTerm)) {
            # warn "del2\n";
	    $document->getAnnotations->delSemanticUnit($secondTerm);
	}
    }
    return($newTerm);

}


sub _loadResource {
    my ($self, $resourceRC, $name) = @_;

#     warn "$resourceRC : $name : " . $resourceRC->{$name} . "\n";

    my $cg = new Config::General('-ConfigFile' => $resourceRC->{$name},
				 '-InterPolateVars' => 1,
				 '-InterPolateEnv' => 1
	);
    
    my %resource = $cg->getall;



#      foreach my $type (keys %resource) {
#  	warn "$type : " . $resource{$type} . "\n**\n";
# 	foreach my $elt (keys %{$resource{$type}}) {
# 	    warn "\t" . $elt . " : " . $resource{$type}->{$elt} . "\n";
# 	}
#      }
    $self->{$name} = \%resource;
}

sub _loadRCFile {
    my ($self, $file, $fields) = @_;

    my $field;
    my $cg = new Config::General('-ConfigFile' => $file,
				 '-InterPolateVars' => 1,
				 '-InterPolateEnv' => 1,
				 # '-NoEscape' => 1,
				 # '-BackslashEscape' => 1,
	);
    
    my %resource = $cg->getall;

    foreach $field (@$fields) {

	if (exists $resource{$field}) {
	    $self->{$field} = $resource{$field};
	    $self->{$field} = $resource{$field};
	} else {
	    warn "*** $field not found ***\n";
	}
    }
}


sub LoadMorphoSemanticMarkResource {
    my ($self, $fieldGroup) = @_;

    if (defined $self->_config->configuration->{'RESOURCE'}->{"language=EN"}->{"AFFIXLIST"}) {
	my $filename = $self->_config->configuration->{'RESOURCE'}->{"language=EN"}->{"AFFIXLIST"};

	warn "Reading file containing marks $filename\n";

	my $affix;
	my $type;

	my %problems_lexical;
	my %tests_lexical;
	my %treatments_lexical;

	my %problems_morphologic;
	my %tests_morphologic;
	my %treatments_morphologic;

	my $line;
	my $field;

	foreach $field (keys %{$self->{$fieldGroup}}) {
	    my %tmp;
	    $self->{"RESOURCES"}->{$field . "_lexical"} = \%tmp;
	    my %tmp2;
	    $self->{"RESOURCES"}->{$field . "_adjectival"} = \%tmp;
	    my %tmp3;
	    $self->{"RESOURCES"}->{$field . "_morphological"} = \%tmp2;
	}

	open (AFFIXFILE, $filename) || die "file not found ($filename)\n";

	while ($line = <AFFIXFILE>) {
	    chomp $line;
	    if (($line !~ /\s*#/o) && ($line !~ /^\s*$/o)) {
		($affix, $type) = split / : *: /, $line; # /
# 		warn "affix: $affix ; type: $type\n";
		    if (exists $self->{$fieldGroup}->{$type}) {
			$self->{"RESOURCES"}->{$type . "_lexical"}->{$affix} = "l";
		} elsif (($type =~ s/\-a$//) &&(exists $self->{$fieldGroup}->{$type})) {
		    $self->{"RESOURCES"}->{$type . "_adjectival"}->{$affix} = "a";
		} elsif ($type =~ /\-(m(-[ps])?)$/) {
		    $self->{"RESOURCES"}->{$` . "_morphological"}->{$affix} = "$1";
		} else {
		    warn "type not found\n";
		}
	    }
	}
    }
}


sub _addSemanticFeature {
    my ($self, $termUnit, $semtag, $document) = @_;

    my $semFeatures;

    if (defined $semtag) {
	my @semtags;
	if (ref($semtag) ne "ARRAY") {
	    @semtags = split /\//, $semtag;
	} else {
	    @semtags = @$semtag;
	}
	my @list_semtags;
	push @list_semtags, \@semtags;
	# TODO Check if the semtag already exists in order to avoid to create one another
	$semFeatures = Lingua::Ogmios::Annotations::SemanticFeatures->new(
	    { 'semantic_category' => \@list_semtags,
	      'refid_semantic_unit' => $termUnit->getId,
	    });
	$document->getAnnotations->addSemanticFeatures($semFeatures);
    } else {
	warn "Semtag not defined\n";
    }

}

sub _split_RE {
    my ($self, $RE) = @_;

    my $pos_start = 0;
    my $pos = 0;
    my $str;
    my $i;
    my @pattern_tab;

    my ($pattern, $rel_type) = split /\|\|/, $RE;
    
    push @pattern_tab, $rel_type;
    do {
	$pos = index($pattern, '@', $pos_start);
	if ($pos > -1) {
	    if ($pos != 0) {
		$str = substr($pattern, $pos_start, $pos - $pos_start);
		my %tmp = ("mark" => $str);
		push @pattern_tab, \%tmp;
	    }
	    $str = substr($pattern, $pos+1, 2);

	    my %tmp;
	    if (exists $self->{"SEMANTICTYPES"}->{$str}) {
		%tmp = ("semtype" => $str);
	    }
	    if (!exists $self->{"SEMANTICTYPES"}->{$str}) {
		%tmp = ("postag" => $str);
	    }
	    push @pattern_tab, \%tmp ;
	    $pos_start = $pos + 3;
	}
    } while(($pos > -1) && ($pos < length($pattern)));
    $str = substr($pattern, $pos_start);

    if ($str ne "") {
	my %tmp = ("mark" => $str);
	push @pattern_tab, \%tmp;
    }

    for($i = 1; $i < scalar(@pattern_tab);$i++) {
	$pattern = $pattern_tab[$i];
    }
    return(\@pattern_tab);
}



sub patternSearch {
    my ($self, $function_pointer, $args) = @_;

    my $document;
    my $sentence;
    my $sentenceLemma;
    my $sentenceLemma2;
#    my $sentenceForm;
    my $REtype;
    my $RELtype;
    my $pattern;
    
    my $sentence_start_token;
    my $sentence_end_token;

    my $i;
    my $j;
    my $regexp;

    my $offset_refs;

    my $wordLimit = 10;
    my $POSTAGwordLimit = 10;
    my $tokenLimit;

    my $semfGuessing = 0;

    my $word;
    my $domainSpecificRelation;
    
    my $start_mark_token;
    my $end_mark_token;

    my $found;
    my @terms;
    my $term;

#     warn "pattternSearch\n";

    foreach $document (@{$self->_documentSet}) {
	foreach $sentence (@{$document->getAnnotations->getSentenceLevel->getElements}) {
	    $sentence_start_token = $sentence->refid_start_token;
	    $sentence_end_token = $sentence->refid_end_token;

#  	    warn "==> " . $sentence->getForm . "\n";
	    ($sentenceLemma, $offset_refs) = $self->_getLemmatisedSentence($document, $sentence_start_token, $sentence_end_token);
	    foreach $REtype (keys %{$self->{'Resources'}}) {
#  		warn "REType: $REtype\n";
		$RELtype = $self->{'Resources'}->{$REtype}->[2];
		for($i=0; $i < scalar(@{$self->{'Resources'}->{$REtype}->[4]});$i++) {
# 		    warn "==>?PATTERN: " . $self->{'Resources'}->{$REtype}->[1]->[$i] . "\n";
		    $pattern = $self->{'Resources'}->{$REtype}->[4]->[$i];
#		foreach $pattern (@{$self->{'Resources'}->{$REtype}->[4]}) {
# 		    warn "$pattern\n";
#  		    warn "relation type: " . $pattern->[0] . "\n";
		    $tokenLimit = $sentence_start_token;
		    $start_mark_token = $sentence_start_token;
		    $end_mark_token = $sentence_end_token;
# 		    warn "+++>" . scalar(@{$pattern}) . "\n";
		    @terms = ();
#		    $sentenceLemma2 = $sentenceLemma;
#		    $sentenceLemma =~ /^/go;

		    $sentenceLemma =~ /^/go;
		    $found = 0;
		    for($j = 1; $j < scalar(@{$pattern}); $j++) {
			if (exists $pattern->[$j]->{'mark'}) {
# 			    warn "mark ($j): " . $pattern->[$j]->{'mark'} .  "\n";
			    $regexp = $pattern->[$j]->{'mark'}; 
			    
# 			    warn "SENTENCE => $sentenceLemma\n";
			    if ($sentenceLemma =~ /$regexp/gcsi) {
# 				warn "=============\n";
# 				warn "SENTENCE => $sentenceForm\n";
# 				warn "SENTENCE => $sentenceLemma\n";
# 				warn "PATTERN: " . $self->{'Resources'}->{$REtype}->[1]->[$i] . "\n";
# 				warn "\tMATCH $& " . (length($`)) . "\n";
				$start_mark_token = undef;
				if (exists $offset_refs->{length($`)}) {
#  				    warn "$` " . length($`) . " / " . $offset_refs->{length($`)}->getContent . "\n";
				    $start_mark_token = $offset_refs->{length($`)};
				}
# 				warn "$' " . (length($` . $&))  . "\n"; # ' #
				$end_mark_token = undef;
				if (exists $offset_refs->{length($` . $&)}) {
# 				    warn "$' " . (length($` . $&)) . " / " . $offset_refs->{length($` . $&)}->getContent . "\n"; # ' #
				    $end_mark_token = $offset_refs->{length($` . $&)};
				    $end_mark_token = $end_mark_token->previous;
				} elsif (exists $offset_refs->{length($` . $&) - 1}) {
#   				    warn ">>>$' " . (length($` . $&) - 1) . " / " . $offset_refs->{length($` . $&) - 1}->getContent . "\n"; # ' #
				    $end_mark_token = $offset_refs->{length($` . $&) - 1};
				    $end_mark_token = $end_mark_token->previous;
				}

# 				if ((defined $start_mark_token) && ()) {
				
				if ((defined $end_mark_token) && ($j > 1)) {
# 				if ((defined $start_mark_token) && (defined $end_mark_token) && ($j > 1)) {
				    if (exists $pattern->[$j - 1]->{'semtype'}) {
					if ($term = $self->_searchConceptBefore($document, $tokenLimit, $sentence_end_token, $pattern->[$j - 1]->{"semtype"}, $end_mark_token, $wordLimit, $semfGuessing)) {
#  					    warn "Found term " . $term->getId . " / " . $term->getForm . " and store it\n";
					    push @terms, $term;
					    $tokenLimit = $end_mark_token;
# 					    $tokenLimit = $start_mark_token;
					} else {
# 					    warn "concept not found\n";
# 					    warn "pattern not complete\n";
					    #$j = scalar(@{$pattern}) + 1 ;
					    last;
					}
				    } else {
#  					warn "(3) pattern not complete\n";
					#$j = scalar(@{$pattern}) + 1 ;
					last;
				    }
				} else {
# 				    warn "(2) pattern not complete\n";
				    #$j = scalar(@{$pattern}) + 1 ;
# 				    if ($j > 1) {
					last;
# 				    }
				}
			    } else {
# 				warn "(1) pattern not complete\n";
				#$j = scalar(@{$pattern}) + 1 ;
				last;
			    }
			} elsif (exists $pattern->[$j]->{'semtype'}) {
# 			    warn "semtype ($j)\n";
			} elsif (exists $pattern->[$j]->{'postag'}) {
			    # POSTAG
# 			    warn "postag ($j)\n";
			    if ($word = $self->_searchPOSTagBefore($document, $tokenLimit, $sentence_end_token, $pattern->[$j]->{"postag"}, $end_mark_token, $POSTAGwordLimit)) {
# 				warn "found postag ($word)\n";
			    } else {
# 				warn "postag not found\n";
				last;
			    }
			}
		    }
# 		    warn "j = $j\n";
# 		    warn "\t" . scalar(@{$pattern}) . "\n";
		    if ($j == scalar(@{$pattern})) {
			if ((defined $end_mark_token) && (exists $pattern->[$j - 1]->{'semtype'})) {
			    $found = 0;
			   if ($term = $self->_searchConceptAfter($document, $tokenLimit, $sentence_end_token, $pattern->[$j - 1]->{"semtype"}, $end_mark_token, $wordLimit, $semfGuessing)) {
#  			    warn "Found term " . $term->getId . " / " . $term->getForm . " and store it\n";
			    push @terms, $term;
			    $found = 1;
			   }
			} elsif (exists $pattern->[$j - 1]->{'postag'}) {
			    # POSTAG
# 			    warn "postag ($j)\n";
			    if ($word = $self->_searchPOSTagAfter($document, $tokenLimit, $sentence_end_token, $pattern->[$j - 1]->{"postag"}, $end_mark_token, $POSTAGwordLimit)) {
# 				warn "found postag ($word)\n";
			    } else {
# 				warn "postag not found\n";
				last;
			    }
			    
			}
			if ($found == 1) {
#			    $tokenLimit = $start_mark_token;
#  			    warn "\tFind a relation (" .  (scalar(@terms)) . ")\n";
#  			    warn "\tCreation of the relation " . $pattern->[0] . "\n";
			    
#			warn "$self\n";
			    &$function_pointer($document, $pattern->[0], \@terms, $args);
#			$self->_addRelation($document, $pattern->[0], \@terms);
			}
		    }
		}
	     }
	 }
    }
#     warn "Done\n";
}

sub _searchConceptBefore {
    my ($self, $document, $sentence_start_token, $sentence_end_token, $semtypeAcr, $start_mark_token, $tokenLimit, $semfGuessing) = @_;


    my $token = $start_mark_token;
    my $term;

    my $windowSize = 0;

    my %words;

    my $semtype = $self->{"SEMANTICTYPES"}->{$semtypeAcr};

#     warn "in _searchConceptBefore (" . $start_mark_token->getFrom . ") " . $sentence_start_token->getId . " $semtype\n";

    do {
	my @words = @{$document->getAnnotations->getWordLevel->getElementByToken($token)}; 
	if (scalar(@words) > 0) {
	    $words{$words[0]->getId}++;
	    $windowSize = scalar(keys %words);
	}
#    	    warn "(0) Id: " . $token->getId . " token: " . $token->getContent . " ( $windowSize / $tokenLimit)\n";
#  	    warn "\t" . scalar(@{$document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)}) . "\n";
#	foreach $term (@{$document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)}) {
# 	while((defined $token) && (($token->isSep) && (!$token->equals($sentence_start_token))) ) {
# 	    $token = $token->previous;
# 	} ;

# 	if (defined($token)) {
#    	    warn "(a) Id: " . $token->getId . "token: " . $token->getContent . " ( $tokenLimit / $windowSize)\n";
#  	    warn "\t" . scalar(@{$document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)}) . "\n";
# 	    $windowSize++;

 	    if (scalar(@{$document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)}) > 0) {
# 		warn "---\n";
	    if ($semfGuessing) {
# # 		    $term = $document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)->[0];
		
		if (($term->isTerm) && (!defined($term->getSemanticFeatureFC($document)))) {
# 			warn "Guessing $semtype\n";
		    $self->_addSemanticFeature($term, $semtype, $document);
		}
	    } else {
		    $term = $document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)->[0];
		if ($term->isTerm) {
# 			warn 'Term: ' . $term->getForm . "\n";
#  			warn "Semf: " . $term->getSemanticFeatureFC($document) . "\n";
		    if ($term->getSemanticFeatureFC($document) eq $semtype) {
#   			    warn "found concept with the right semtype ($semtype)\n";
			return($term);
		    }
		}
	    }
	}
# 	if (!$token->equals($sentence_start_token)) {
	    $token = $token->previous;
# 	}
#   	    warn "(b) Id: " . $token->getId . "token: " . $token->getContent . " ( $tokenLimit / $windowSize)\n";
    } while(($windowSize < $tokenLimit) && (defined $token) && ($token->getTo >= $sentence_start_token->getFrom));
#     warn "+++\n";
    return(0);
}


sub _searchConceptAfter {
    my ($self, $document, $sentence_start_token, $sentence_end_token, $semtypeAcr, $start_mark_token, $tokenLimit, $semfGuessing) = @_;


    my $token = $start_mark_token;
    my $term;

    my $word;

    my $windowSize = 0;
    my $semtype = $self->{"SEMANTICTYPES"}->{$semtypeAcr};
    my %words;

#         warn "in _searchConceptAfter (" . $start_mark_token->getFrom . ") " . $sentence_start_token->getId . " $semtype\n";
#     warn "in _searchConceptAfter (" . $start_mark_token->getFrom . ")\n";

    do {

	my @words = @{$document->getAnnotations->getWordLevel->getElementByToken($token)}; 
	if (scalar(@words) > 0) {
	    $words{$words[0]->getId}++;
	    $windowSize = scalar(keys %words);
	}
	foreach $term (@{$document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)}) {


# # 	while((defined $token) && (($token->isSep) && (!$token->equals($sentence_end_token))) ) {
# # 	    $token = $token->next;
# # 	} ;
# # 	if ((defined($token)) && (!$token->equals($sentence_end_token))) {
# # #   	    warn "(a) Id: " . $token->getId . "token: " . $token->getContent . " ( $tokenLimit / $windowSize)\n";
# # 	    $windowSize++;
# # 	    if (scalar(@{$document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)}) > 0) {
# # # 		warn "---\n";
	    if ($semfGuessing) {
# # 		$term = $document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)->[0];
		if (($term->isTerm) && (!defined($term->getSemanticFeatureFC($document)))) {
# 			warn "Guessing $semtype\n";
		    $self->_addSemanticFeature($term, $semtype, $document);			
		}		    
	    } else {
# # 		$term = $document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)->[0];
# 		    warn 'Term: ' . $term->getForm . "\n";
# 		    warn "Semf: " . $term->getSemanticFeatureFC($document) . "\n";
		if ($term->isTerm) {
		    if ($term->getSemanticFeatureFC($document) eq $semtype) {
#   			    warn "found concept with the right semtype ($semtype)\n";
			return($term);
		    }
		}
	    }
	}
# 	if (!$token->equals($sentence_end_token)) {
	    $token = $token->next;
# 	}
#   	    warn "(b) Id: " . $token->getId . "token: " . $token->getContent . " ( $tokenLimit / $windowSize)\n";
    } while(($windowSize < $tokenLimit) && (defined $token) && ($token->getFrom <= $sentence_end_token->getTo));

    return(0);
}

########################################################################

sub _searchPOSTagBefore {
    my ($self, $document, $sentence_start_token, $sentence_end_token, $POSTagAcr, $start_mark_token, $tokenLimit) = @_;


    my $token = $start_mark_token;
    my $word;

    my $windowSize = 0;

#      warn "in _searchPOSTagBefore (" . $start_mark_token->getFrom . ")\n";

    my $POSTag;
    if (defined $self->{"POSTAGS"}->{$POSTagAcr}) {
	$POSTag = $self->{"POSTAGS"}->{$POSTagAcr};
    } else {
	$POSTag = $POSTagAcr;
    }
#    my $semtype = $self->{"SEMANTICTYPES"}->{$POSTag};

    do {
	while((defined $token) && (($token->isSep) && (!$token->equals($sentence_start_token))) ) {
	    $token = $token->previous;
	} ;

	if ((defined($token))#  && (!$token->equals($sentence_start_token))
	    ) {
#  	    warn "token: " . $token->getContent . "\n";
# 	    warn "\t" . scalar(@{$document->getAnnotations->getWordLevel->getElementByToken($token)}) . "\n";
	    $windowSize++;

	    if (scalar(@{$document->getAnnotations->getWordLevel->getElementByToken($token)}) > 0) {
		$word = $document->getAnnotations->getWordLevel->getElementByToken($token)->[0];
		if ($word->getMorphoSyntacticFeatures($document)->syntactic_category eq $POSTag) {
# 		    warn "found word with rigt POSTAG ($POSTag)\n";
		    return($word);
		}
	    }
	    if (!$token->equals($sentence_start_token)) {
		$token = $token->previous;
	    }
# 	    $token = $token->previous;
#  	    warn "token: " . $token->getContent . "\n";
	} 
    } while(($windowSize < $tokenLimit) && (defined $token) && (!$token->equals($sentence_start_token)));
    
    return(0);
    
}


sub _searchPOSTagAfter {
    my ($self, $document, $sentence_start_token, $sentence_end_token, $POSTagAcr, $start_mark_token, $tokenLimit) = @_;


    my $token = $start_mark_token;
    my $word;

    my $windowSize = 0;
    my $POSTag;
    if (defined $self->{"POSTAGS"}->{$POSTagAcr}) {
	$POSTag = $self->{"POSTAGS"}->{$POSTagAcr};
    } else {
	$POSTag = $POSTagAcr;
    }
#     my $POSTag = $self->{"POSTAGS"}->{$POSTagAcr};
#    my $semtype = $self->{"SEMANTICTYPES"}->{$semtypeAcr};

#     warn "in _searchPOSTagAfter (" . $start_mark_token->getFrom . ")\n";

    do {
	while((defined $token) && (($token->isSep) && (!$token->equals($sentence_end_token))) ) {
	    $token = $token->next;
	} ;
	if ((defined($token)) && (!$token->equals($sentence_end_token))) {
	    $windowSize++;
	    if (scalar(@{$document->getAnnotations->getWordLevel->getElementByToken($token)}) > 0) {
		$word = $document->getAnnotations->getWordLevel->getElementByToken($token)->[0];
		if ($word->getMorphoSyntacticFeatures($document)->syntactic_category eq $POSTag) {
		    return($word);
		}
	    }
	    if (!$token->equals($sentence_end_token)) {
		$token = $token->next;
	    }
	} 
    } while(($windowSize < $tokenLimit) && (defined $token) && (!$token->equals($sentence_end_token)));

    return(0);
}


########################################################################
########################################################################

sub _searchConceptBefore1 {
    my ($self, $document, $sentence_start_token, $sentence_end_token, $semtypeAcr, $start_mark_token, $tokenLimit, $semfGuessing) = @_;


    my $token = $start_mark_token;
    my $term;

    my $windowSize = 0;

#       warn "in _searchConceptBefore (" . $start_mark_token->getFrom . ")\n";

    my $semtype = $self->{"SEMANTICTYPES"}->{$semtypeAcr};

    do {
	while((defined $token) && (($token->isSep) && (!$token->equals($sentence_start_token))) ) {
	    $token = $token->previous;
	} ;

	if ((defined($token)) && (!$token->equals($sentence_start_token))) {
#  	    warn "token: " . $token->getContent . "\n";
# 	    warn "\t" . scalar(@{$document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)}) . "\n";
	    $windowSize++;

	    if (scalar(@{$document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)}) > 0) {
		if ($semfGuessing) {
		    $term = $document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)->[0];
		    
		    if (($term->isTerm) && (!defined($term->getSemanticFeatureFC($document)))) {
# 			warn "Guessing $semtype\n";
			$self->_addSemanticFeature($term, $semtype, $document);
		    }
		} else {
		    $term = $document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)->[0];
		    if ($term->isTerm) {
			if ($term->getSemanticFeatureFC($document) eq $semtype) {
#  			    warn "found concept with the right semtype ($semtype)\n";
			    return($term);
			}
		    }
		}
	    }
	    $token = $token->previous;
#  	    warn "token: " . $token->getContent . "\n";
	} 
    } while(($windowSize < $tokenLimit) && (defined $token) && (!$token->equals($sentence_start_token)));
    
    return(0);
    
}


sub _searchConceptAfter1 {
    my ($self, $document, $sentence_start_token, $sentence_end_token, $semtypeAcr, $start_mark_token, $tokenLimit, $semfGuessing) = @_;


    my $token = $start_mark_token;
    my $term;

    my $windowSize = 0;
    my $semtype = $self->{"SEMANTICTYPES"}->{$semtypeAcr};

#     warn "in _searchConceptAfter (" . $start_mark_token->getFrom . ")\n";

    do {
	while((defined $token) && (($token->isSep) && (!$token->equals($sentence_end_token))) ) {
	    $token = $token->next;
	} ;
	if ((defined($token)) && (!$token->equals($sentence_end_token))) {
	    $windowSize++;
	    if (scalar(@{$document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)}) > 0) {
		if ($semfGuessing) {
		    $term = $document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)->[0];
		    if (($term->isTerm) && (!defined($term->getSemanticFeatureFC($document)))) {
# 			warn "Guessing $semtype\n";
			$self->_addSemanticFeature($term, $semtype, $document);			
		    }		    
		} else {
		    $term = $document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)->[0];
		    if ($term->isTerm) {
			if ($term->getSemanticFeatureFC($document) eq $semtype) {
			    return($term);
			}
		    }
		}
	    }
	    $token = $token->next;
	} 
    } while(($windowSize < $tokenLimit) && (defined $token) && (!$token->equals($sentence_end_token)));

    return(0);
}

########################################################################

sub _searchPOSTagBefore1 {
    my ($self, $document, $sentence_start_token, $sentence_end_token, $POSTagAcr, $start_mark_token, $tokenLimit) = @_;


    my $token = $start_mark_token;
    my $word;

    my $windowSize = 0;

#      warn "in _searchPOSTagBefore (" . $start_mark_token->getFrom . ")\n";

    my $POSTag;
    if (defined $self->{"POSTAGS"}->{$POSTagAcr}) {
	$POSTag = $self->{"POSTAGS"}->{$POSTagAcr};
    } else {
	$POSTag = $POSTagAcr;
    }
#    my $semtype = $self->{"SEMANTICTYPES"}->{$POSTag};

    do {
	while((defined $token) && (($token->isSep) && (!$token->equals($sentence_start_token))) ) {
	    $token = $token->previous;
	} ;

	if ((defined($token)) && (!$token->equals($sentence_start_token))) {
#  	    warn "token: " . $token->getContent . "\n";
# 	    warn "\t" . scalar(@{$document->getAnnotations->getWordLevel->getElementByToken($token)}) . "\n";
	    $windowSize++;

	    if (scalar(@{$document->getAnnotations->getWordLevel->getElementByToken($token)}) > 0) {
		$word = $document->getAnnotations->getWordLevel->getElementByToken($token)->[0];
		if ($word->getMorphoSyntacticFeatures($document) eq $POSTag) {
# 		    warn "found word with rigt POSTAG ($POSTag)\n";
		    return($word);
		}
	    }
	    $token = $token->previous;
#  	    warn "token: " . $token->getContent . "\n";
	} 
    } while(($windowSize < $tokenLimit) && (defined $token) && (!$token->equals($sentence_start_token)));
    
    return(0);
    
}


sub _searchPOSTagAfter1 {
    my ($self, $document, $sentence_start_token, $sentence_end_token, $POSTagAcr, $start_mark_token, $tokenLimit) = @_;


    my $token = $start_mark_token;
    my $word;

    my $windowSize = 0;
    my $POSTag;
    if (defined $self->{"POSTAGS"}->{$POSTagAcr}) {
	$POSTag = $self->{"POSTAGS"}->{$POSTagAcr};
    } else {
	$POSTag = $POSTagAcr;
    }
    do {
	while((defined $token) && (($token->isSep) && (!$token->equals($sentence_end_token))) ) {
	    $token = $token->next;
	} ;
	if ((defined($token)) && (!$token->equals($sentence_end_token))) {
	    $windowSize++;
	    if (scalar(@{$document->getAnnotations->getWordLevel->getElementByToken($token)}) > 0) {
		$word = $document->getAnnotations->getWordLevel->getElementByToken($token)->[0];
		if ($word->getMorphoSyntacticFeatures($document) eq $POSTag) {
		    return($word);
		}
	    }
	    $token = $token->next;
	} 
    } while(($windowSize < $tokenLimit) && (defined $token) && (!$token->equals($sentence_end_token)));

    return(0);
}

sub loadSynPatterns
{
    my ($self) = @_;

    # $self->_documentSet->[0]->getAnnotations->getLanguage;

    if (defined $self->_config->configuration->{'RESOURCE'}->{"language=EN"}->{"PATTERNSSYN"}) {
# 	warn "**** FILE value to CHANGE *****";
#     open FILE, "/home/thierry/Recherche/Challenges/I2B2-2010/Resources/structure_syntaxique-nf.txt" or die "No such file\n";
#     open FILE, "/export/home/limbio/hamon/Research/Challenges/I2B2-2010/Resources/structure_syntaxique-test.txt";

	if (!open FILE, $self->_config->configuration->{'RESOURCE'}->{"language=EN"}->{"PATTERNSSYN"}) {
	    warn "No such file" . $self->_config->configuration->{'RESOURCE'}->{"language=EN"}->{"PATTERNSSYN"} ."\n";
	    return(0);
	}
    } else {
	warn "No Pattern FileName specified\n";
	return(0);
    }

    my $parser = Lingua::Ogmios::NLPWrappers::PatternParser->new();

    $parser->YYData->{PPRS} = $self;
    $parser->YYData->{FH} = \*FILE;
    
    $parser->YYParse(yylex => \&Lingua::Ogmios::NLPWrappers::PatternParser::_Lexer, yyerror => \&Lingua::Ogmios::NLPWrappers::PatternParser::_Error);

    close FILE;
}

sub addSynPattern {
    my ($self, $node_set, $action, $distance) = @_;

    my @nodes = @{$node_set};
    push @{$self->{'SYN_PATTERNS'}}, {'pattern' => \@nodes,
				      'action' => $action,
				      'distance' => $distance};
}

sub getSynPatterns {
    my ($self) = @_;

    return $self->{SYN_PATTERNS};
}

sub synPatternSearch {
    my ($self, $function_pointer, $args) = @_;

    warn "start synPatternSearch\n";

    $self->{"SYN_PATTERNS"} = [];

    if ($self->loadSynPatterns() == 0) {
	return(0);
    }

    my $document;
    my $sentence;

    my $sentence_start_token;
    my $sentence_end_token;

    my $pattern;
    my $synPattern;

    my $term;
    my $word;

    my $sentenceLemma;
    my $sentenceLemma2;

    my $REtype;
    my $RELtype;

    my $i;

    my $semfGuessing = 0;
    my $wordSize = 5;

    my $j;
    my $regexp;

    my $offset_refs;

    my $POSTAGwordLimit = 10;
    my $tokenLimit;

    my $domainSpecificRelation;
    
    my $start_token;
    my $start_token_origin;
    my $end_mark_token;

    my $found;
    my @terms;

    my $word_re_start_token;
    my $word_re_end_token;

    my $element;
    my $selectedSentences;

#    print Dumper($self->{SYN_PATTERNS});

#     warn "start Search\n";

    foreach $document (@{$self->_documentSet}) {
	foreach $synPattern (@{$self->getSynPatterns}) {
	    # $pattern = $synPattern->{'pattern'};
	    foreach $sentence (@{$document->getAnnotations->getSentenceLevel->getElements}) {
		$selectedSentences->{$sentence->refid_start_token} = {'sentence' => $sentence,
								      'first_item' => []
		};
	    }
# 	    print STDERR "Select sentences\n";
#  	    print STDERR Dumper $synPattern->{'pattern'};
	    $selectedSentences = $self->_selectSentencesFromPattern($synPattern->{'pattern'}, $selectedSentences, $document, 0);

#  	    print STDERR "================\n";
	    foreach $sentence (values %$selectedSentences) {
# 		print "sentenceID: " . $sentence->{'sentence'}->getId . "\n";
#    		print STDERR "Scanning sentence " .  $sentence->{'sentence'}->getId . "\n";
		foreach $element (@{$sentence->{'first_item'}}) {
# 		    print STDERR '>>>' . $element->getForm . "\n";

		    $start_token = $element->start_token;
# 		    if ($synPattern->{'pattern'}->[0]->{'type'} eq "word_re") {
# 			$start_token = $sentence->{'sentence'}->refid_start_token;
# 		    }
		    $sentence_end_token = $sentence->{'sentence'}->refid_end_token;
		    $wordSize = $synPattern->{'distance'};

		    my @terms;
		    $self->_searchPattern($document, \$start_token, $sentence_end_token, $synPattern, $wordSize, $semfGuessing, 0, \@terms, $function_pointer, $args);

		}
# 		print STDERR  "-----\n";
	    }
# 	    print STDERR "************************\n";
	}
    }
#     warn "end Search\n";
    return (0);
}

sub _searchPattern {
    my ($self, $document, $start_token, $sentence_end_token, $synPattern, $wordSize, $semfGuessing, $level, $terms, $function_pointer, $args) = @_;

    my $word;
    my $term;
    my $word_re_start_token;
    my $word_re_end_token;
    my $found = 0;
    my $i;

    my $pattern = $synPattern->{"pattern"};

    my $syndep_start_token = $$start_token;

#     my @terms;

#     my $start_token_orig = $$start_token;

    my @patternElements;

#     print STDERR "level = $level\n";

#     print STDERR Dumper $pattern;


#     if ((scalar(@$pattern) == 1) && ($pattern->[0]->{'type'} eq "chunk")) {
# 	$level = -1;
#     }

    for($i = 0; $i < scalar(@$pattern); $i++) {
#			print "i = $i (" . $pattern->[$i]->{'type'} . ")\n";
# 	print "$$start_token\n";
# 	print $$start_token->getId . " : " . $$start_token->getFrom . "\n";
	if (!defined $$start_token) {
	    $found = 0;
	    last;
	}
	if ($pattern->[$i]->{'type'} eq "semtype") {
	    # 	    print "i = $i (" . $pattern->[$i]->{'type'} . ")\n";
	    if ($term = $self->_searchSemType($document, $$start_token, $sentence_end_token, $pattern->[$i]->{"semtype"}, $wordSize, $semfGuessing)) {
#      		print STDERR "found " . $term->getForm . " : " . $term->end_token->getId . "(SEMTYPE)\n";
		push @patternElements, $term;
		# temporary
		if ($level == 0) {
		    push @$terms, $term;
		}
 		$$start_token = $term->end_token->next;
		$found = 1;
# 				next;
	    } else {
# 		print "term not found\n";
		$found = 0;
		last;
	    }
	}
	if ($pattern->[$i]->{'type'} eq "postag") {
# 	    print "i = $i (" . $pattern->[$i]->{'type'} . ")\n";
	    if ($word = $self->_searchPOSTAG($document, $$start_token, $sentence_end_token, $pattern->[$i]->{"postag"}, $wordSize)) {
#     		print STDERR "found " . $word->getForm . "(POSTAG)\n";
		push @patternElements, $word;
		$$start_token = $word->end_token->next;
		$found = 1;
# 				next;
	    } else {
# 		print "postag not found\n";
		$found = 0;
		last;
	    }
	}
	if ($pattern->[$i]->{'type'} eq "word") {
	    if ($word = $self->_searchWord($document, $$start_token, $sentence_end_token, $pattern->[$i]->{"word"}, $wordSize)) {
#    		print STDERR "found " . $word->getForm . " " . $word->start_token->getFrom . " (WORD)\n";
		push @patternElements, $word;
		$$start_token = $word->end_token->next;
		$found = 1;
# 				next;
	    } else {
# 				print "word not found\n";
		$found = 0;
		last;
	    }
	}
	if ($pattern->[$i]->{'type'} eq "word_re") {
# 	    $$start_token = $start_token_orig;
	    ($word_re_start_token, $word_re_end_token) = $self->_searchWordRE($document, $$start_token, $sentence_end_token, $pattern->[$i]->{"word_re"}, $wordSize);
	    if ((defined $word_re_start_token) && (defined $word_re_end_token)) {
# 		print STDERR "found " . $word_re_end_token->getContent . "(WORDRE)\n";
##		push @patternElements, $term;
		$$start_token = $word_re_end_token->next;
		$found = 1;
# 				next;
	    } else {
# 				print "word not found\n";
		$found = 0;
		last;
	    }
	}
	if ($pattern->[$i]->{'type'} eq "term") {
	    if ($term = $self->_searchTerm($document, $$start_token, $sentence_end_token, $wordSize)) {
# 		print STDERR "found " . $word->getForm . "(TERM)\n";
		push @patternElements, $term;
		$$start_token = $term->end_token->next;
		$found = 1;
# 				next;
	    } else {
# 				print "word not found\n";
		$found = 0;
		last;
	    }
	}
	if ($pattern->[$i]->{'type'} eq "termContent") {
	    if ($term = $self->_searchTermContent($document, $$start_token, $sentence_end_token, $pattern->[$i]->{"termContent"}, $wordSize)) {
# 		print STDERR "found " . $word->getForm . "(TERMCONTENT)\n";
		push @patternElements, $term;
		$$start_token = $term->end_token->next;
		$found = 1;
# 				next;
	    } else {
# 				print "word not found\n";
		$found = 0;
		last;
	    }
	}
	if ($pattern->[$i]->{'type'} eq "chunk") {
# 	    print "i = $i (" . $pattern->[$i]->{'type'} . ")\n";
	    if ($found = $self->_searchPattern($document, $start_token, $sentence_end_token, {'pattern' => $pattern->[$i]->{"chunk"}}, $wordSize, $semfGuessing, $level + 1, $terms, $function_pointer, $args)) {
##		push @patternElements, $term;
 		$found = 1;
#    		print STDERR "chunk found $found\n";
	    } else {
# 		print "chunk not found\n";
		$found = 0;
		last;
	    }
	}
	if ($pattern->[$i]->{'type'} eq "syndep") {
	    if (scalar (@patternElements) > 0) {
		$syndep_start_token = $patternElements[0]->start_token;
	    }

 	    if ($self->_searchSynDep($document, $syndep_start_token, $sentence_end_token, $pattern->[$i]->{'syndep'}, $wordSize, \@patternElements, $terms)) {
# 		print STDERR "syndep found\n";
		$found = 1;
	    } else {
# 	    print "i = $i (" . $pattern->[$i]->{'type'} . ")\n";
 		$found = 0;
 		last;
	    }
	}
    }
#      print STDERR "($level - $found)\n";
    if (($level == 0) && ($found == 1)) { # ($i == scalar(@$pattern)) {
#      if ($found == 1) { # ($i == scalar(@$pattern)) {
#     	print STDERR "PATTERN FOUND ($level - $found) - " .  $synPattern->{"action"} . "\n";
#	my @tmp = split m!/!, $synPattern->{"action"};
	&$function_pointer($document, $synPattern->{"action"}, $terms, $args);
# 	&$function_pointer($document, $synPattern->{"action"}, \@terms, $args);
    }
    return($found);
}

sub _searchSynDep {
    my ($self, $document, $start_token, $end_token, $syndep, $WindowSize, $patternElements, $terms) = @_;

    my $token = $start_token;
    my $synrel;
    my $currentWindowSize = 0;
    my $phrase;

    if (scalar(@$terms) == 0) {
	return(0);
    }

    my $term_start_token = $terms->[0]->start_token;
    my $term_end_token = $terms->[0]->end_token;

    my %postags = ("DT" => 1, "IN" => 1);

#     warn "====> " . $terms->[0]->getForm . "\n";

    if (ref($terms->[0]) eq "Lingua::Ogmios::Annotations::SemanticUnit") {
	if (($terms->[0]->reference_name eq "refid_word") || 
	    ($terms->[0]->reference_name eq "refid_phrase")) {
	    $phrase = $terms->[0]->reference;
	} elsif ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $terms->[0]->start_token->getId)) {
	    $phrase = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $terms->[0]->start_token->getId)->[0];
	}
    }

#     warn "phrase: " . $phrase->getForm . "\n";

    foreach $synrel (@{$document->getAnnotations->getSyntacticRelationLevel->getElementFromIndex('syntactic_relation_type', $syndep)}) {
#     foreach $synrel (@{$document->getAnnotations->getSyntacticRelationLevel->getElementFromIndex2('refid_head', $phrase)}) {
#     foreach $synrel (@{$document->getAnnotations->getSyntacticRelationLevel->getElements}) {
# 	if ($synrel->syntactic_relation_type eq $syndep) {
# 	print $start_token->getFrom . " <= " .  $synrel->refid_modifier->[0]->start_token->getFrom . "\n";
# 	print  $synrel->refid_modifier->[0]->end_token->getTo . " <= "  . $end_token->getTo . "\n";

# 	print STDERR "syndep\n";

# 	my %tmp = (ref($synrel->refid_head->[0]) . $synrel->refid_head->[0]->getId => $synrel->refid_head->[0]);
# 	my @elementChunk = $self->_getChunkFromElement($document, $synrel->refid_modifier->[0], $synrel->refid_head->[0], \%tmp);
# 	my $elt;
# 	warn "===\n";
# 	foreach $elt (keys %tmp) {
# 	    print STDERR "\t$elt : " . $tmp{$elt}->getForm . "\n";
# 	}

	# ? check if the head of syndep is in the found elements at the level n-1
# 	my $i = -1;
# 	my $refPatElmt;
# 	for($i = 0; $i < scalar(@$patternelments); $i++) {
# 	    if ((($refPatElmt eq "Lingua::Ogmios::Annotations::Word" ) ||
# 		($refPatElmt eq "Lingua::Ogmios::Annotations::Phrase" )) &&
# 		(!exists $tmp{$refPatElmt . $patternelments->[$i]->getId})) {
# 		return(0);
# 	    }
# 	}
# 	return(1);

# 	do {
# 	    $i++;
# 	    if ($i < scalar(@$patternElements)) {
# 		$refPatElmt = ref($patternElements->[$i]);
# 	    print STDERR "($i)" . $refPatElmt . $patternElements->[$i]->getId . "\n";
# 		if ($refPatElmt eq "Lingua::Ogmios::Annotations::Word" ) {
# 	    print STDERR "\t" . $patternElements->[$i]->getMorphoSyntacticFeatures($document)->syntactic_category . "\n";
# 		}
# 	    }
# 	} while(($i < scalar(@$patternElements)) &&
# 		(($refPatElmt eq "Lingua::Ogmios::Annotations::Word" ) ||
# 		 ($refPatElmt eq "Lingua::Ogmios::Annotations::Phrase" )) &&
# 		((($refPatElmt eq "Lingua::Ogmios::Annotations::Word" ) && 
# 		  (exists $postags{$patternElements->[$i]->getMorphoSyntacticFeatures($document)->syntactic_category})) ||
# 		 (exists $tmp{$refPatElmt . $patternElements->[$i]->getId})));
# 	warn "i = $i\n";
# 	if ($i == scalar(@$patternElements)) {
#  	    print STDERR "==>FOUND (" . $terms->[0]->getForm . ")\n";
#  	    print "==>FOUND (" . $terms->[0]->getForm . ")\n";
# 	    return(1);
# 	}

	# search in syndep is in the found elements
	if (($start_token->getFrom <= $synrel->refid_modifier->[0]->start_token->getFrom) &&
	    ($synrel->refid_modifier->[0]->end_token->getTo <= $end_token->getTo)) {

# # 	if ((($start_token->getFrom <= $synrel->refid_modifier->[0]->start_token->getFrom) &&
# # 		    ($synrel->refid_modifier->[0]->end_token->getTo <= $end_token->getTo)) &&
# # 	    (($term_start_token->getFrom <= $synrel->refid_head->[0]->start_token->getFrom) &&
# # 		    ($synrel->refid_head->[0]->end_token->getTo <= $term_end_token->getTo))) {

#  	    print STDERR "==>FOUND (" . $terms->[0]->getForm . ")\n";
#  	    print "==>FOUND (" . $terms->[0]->getForm . ")\n";
	    return(1);

	    # check if all the the elements are in the chunk

	}
    }
#     warn "syndep not found\n";
#     print "search Concept\n";

#     do {
# 	my @words = @{$document->getAnnotations->getWordLevel->getElementByToken($token)}; 
# 	if (scalar(@words) > 0) {
# 	    $words{$words[0]->getId}++;
# 	    $currentWindowSize = scalar(keys %words);
# 	}
# 	foreach $term (@{$document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)}) {
# 	    if ($semfGuessing) {
# 		if (($term->isTerm) && (!defined($term->getSemanticFeatureFC($document)))) {
# 		    $self->_addSemanticFeature($term, $semtype, $document);			
# 		}		    
# 	    } else {
# 		if ($term->isTerm) {
# 		    if ($term->getSemanticFeatureFC($document) eq $semtype) {
# 			return($term);
# 		    }
# 		}
# 	    }
# 	}
# 	$token = $token->next;
#     } while(($currentWindowSize < $WindowSize) && (defined $token) && ($token->getFrom <= $end_token->getTo));

    return(0);
}

sub _searchSynDep2 {
    my ($self, $document, $start_token, $end_token, $syndep, $WindowSize, $patternElements, $terms) = @_;

    my $token = $start_token;
    my $synrel;
    my $currentWindowSize = 0;
    my $phrase;

    my $term_start_token = $terms->[0]->start_token;
    my $term_end_token = $terms->[0]->end_token;

    my %postags = ("DT" => 1, "IN" => 1);

#    warn "====> " . $terms->[0]->getForm . "\n";

    if (ref($terms->[0]) eq "Lingua::Ogmios::Annotations::SemanticUnit") {
	if (($terms->[0]->reference_name eq "refid_word") || 
	    ($terms->[0]->reference_name eq "refid_phrase")) {
	    $phrase = $terms->[0]->reference;
	} elsif ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $terms->[0]->start_token->getId)) {
	    $phrase = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $terms->[0]->start_token->getId)->[0];
	}
    }

    warn "phrase: " . $phrase->getForm . "\n";

#     foreach $synrel (@{$document->getAnnotations->getSyntacticRelationLevel->getElementFromIndex('syntactic_relation_type', $syndep)}) {
    foreach $synrel (@{$document->getAnnotations->getSyntacticRelationLevel->getElementFromIndex2('refid_head', $phrase)}) {
#     foreach $synrel (@{$document->getAnnotations->getSyntacticRelationLevel->getElements}) {
# 	if ($synrel->syntactic_relation_type eq $syndep) {
# 	print $start_token->getFrom . " <= " .  $synrel->refid_modifier->[0]->start_token->getFrom . "\n";
# 	print  $synrel->refid_modifier->[0]->end_token->getTo . " <= "  . $end_token->getTo . "\n";

	print STDERR "syndep\n";

	my %tmp = (ref($synrel->refid_head->[0]) . $synrel->refid_head->[0]->getId => $synrel->refid_head->[0]);
	my @elementChunk = $self->_getChunkFromElement($document, $synrel->refid_modifier->[0], $synrel->refid_head->[0], \%tmp);
	my $elt;
	warn "===\n";
	foreach $elt (keys %tmp) {
	    print STDERR "\t$elt : " . $tmp{$elt}->getForm . "\n";
	}

	# ? check if the head of syndep is in the found elements at the level n-1
	my $i = -1;
	my $refPatElmt;
# 	for($i = 0; $i < scalar(@$patternelments); $i++) {
# 	    if ((($refPatElmt eq "Lingua::Ogmios::Annotations::Word" ) ||
# 		($refPatElmt eq "Lingua::Ogmios::Annotations::Phrase" )) &&
# 		(!exists $tmp{$refPatElmt . $patternelments->[$i]->getId})) {
# 		return(0);
# 	    }
# 	}
# 	return(1);
	do {
	    $i++;
	    if ($i < scalar(@$patternElements)) {
		$refPatElmt = ref($patternElements->[$i]);
	    print STDERR "($i)" . $refPatElmt . $patternElements->[$i]->getId . "\n";
		if ($refPatElmt eq "Lingua::Ogmios::Annotations::Word" ) {
	    print STDERR "\t" . $patternElements->[$i]->getMorphoSyntacticFeatures($document)->syntactic_category . "\n";
		}
	    }
	} while(($i < scalar(@$patternElements)) &&
		(($refPatElmt eq "Lingua::Ogmios::Annotations::Word" ) ||
		 ($refPatElmt eq "Lingua::Ogmios::Annotations::Phrase" )) &&
		((($refPatElmt eq "Lingua::Ogmios::Annotations::Word" ) && 
		  (exists $postags{$patternElements->[$i]->getMorphoSyntacticFeatures($document)->syntactic_category})) ||
		 (exists $tmp{$refPatElmt . $patternElements->[$i]->getId})));
	warn "i = $i\n";
	if ($i == scalar(@$patternElements)) {
 	    print STDERR "==>FOUND (" . $terms->[0]->getForm . ")\n";
 	    print "==>FOUND (" . $terms->[0]->getForm . ")\n";
	    return(1);
	}

	# search in syndep is in the found elements
# 	if (($start_token->getFrom <= $synrel->refid_modifier->[0]->start_token->getFrom) &&
# 	    ($synrel->refid_modifier->[0]->end_token->getTo <= $end_token->getTo)) {

# # 	if ((($start_token->getFrom <= $synrel->refid_modifier->[0]->start_token->getFrom) &&
# # 		    ($synrel->refid_modifier->[0]->end_token->getTo <= $end_token->getTo)) &&
# # 	    (($term_start_token->getFrom <= $synrel->refid_head->[0]->start_token->getFrom) &&
# # 		    ($synrel->refid_head->[0]->end_token->getTo <= $term_end_token->getTo))) {

#  	    print STDERR "==>FOUND (" . $terms->[0]->getForm . ")\n";
#  	    print "==>FOUND (" . $terms->[0]->getForm . ")\n";
# 	    return(1);

# 	    # check if all the the elements are in the chunk

# 	}
    }
    warn "syndep not found\n";
#     print "search Concept\n";

#     do {
# 	my @words = @{$document->getAnnotations->getWordLevel->getElementByToken($token)}; 
# 	if (scalar(@words) > 0) {
# 	    $words{$words[0]->getId}++;
# 	    $currentWindowSize = scalar(keys %words);
# 	}
# 	foreach $term (@{$document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)}) {
# 	    if ($semfGuessing) {
# 		if (($term->isTerm) && (!defined($term->getSemanticFeatureFC($document)))) {
# 		    $self->_addSemanticFeature($term, $semtype, $document);			
# 		}		    
# 	    } else {
# 		if ($term->isTerm) {
# 		    if ($term->getSemanticFeatureFC($document) eq $semtype) {
# 			return($term);
# 		    }
# 		}
# 	    }
# 	}
# 	$token = $token->next;
#     } while(($currentWindowSize < $WindowSize) && (defined $token) && ($token->getFrom <= $end_token->getTo));

    return(0);
}

sub _searchSemType {
    my ($self, $document, $start_token, $end_token, $semtypeAcr, $WindowSize, $semfGuessing) = @_;

    my $token = $start_token;
    my $term;
    my $word;
    my $currentWindowSize = 0;
    my $semtype = $self->{"SEMANTICTYPES"}->{$semtypeAcr};
    my %words;

#      print STDERR "search SemType\n";

    do {
	my @words = @{$document->getAnnotations->getWordLevel->getElementByToken($token)}; 
	if (scalar(@words) > 0) {
	    $words{$words[0]->getId}++;
	    $currentWindowSize = scalar(keys %words);
	}
	foreach $term (@{$document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)}) {
	    if ($semfGuessing) {
		if (($term->isTerm) && (!defined($term->getSemanticFeatureFC($document)))) {
		    $self->_addSemanticFeature($term, $semtype, $document);			
		}		    
	    } else {
		if ($term->isTerm) {
		    if ($term->getSemanticFeatureFC($document) eq $semtype) {
			return($term);
		    }
		}
	    }
	}
	$token = $token->next;
    } while(($currentWindowSize < $WindowSize) && (defined $token) && ($token->getFrom <= $end_token->getTo));

    return(0);
}

sub _searchTermContent {
    my ($self, $document, $start_token, $end_token, $termcontent, $WindowSize) = @_;

    my $token = $start_token;
    my $term;
    my $word;
    my $currentWindowSize = 0;
    my %words;

#      print STDERR "search term content\n";

    do {
	my @words = @{$document->getAnnotations->getWordLevel->getElementByToken($token)}; 
	if (scalar(@words) > 0) {
	    $words{$words[0]->getId}++;
	    $currentWindowSize = scalar(keys %words);
	}
	foreach $term (@{$document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)}) {
	    if ($term->isTerm) {
		if ($term->getForm eq $termcontent) {
		    return($term);
		}
	    }
	}
	$token = $token->next;
    } while(($currentWindowSize < $WindowSize) && (defined $token) && ($token->getFrom <= $end_token->getTo));

    return(0);
}

sub _searchTerm {
    my ($self, $document, $start_token, $end_token, $WindowSize) = @_;

    my $token = $start_token;
    my $term;
    my $word;
    my $currentWindowSize = 0;
    my %words;

#      print STDERR "search Term\n";

    do {
	my @words = @{$document->getAnnotations->getWordLevel->getElementByToken($token)}; 
	if (scalar(@words) > 0) {
	    $words{$words[0]->getId}++;
	    $currentWindowSize = scalar(keys %words);
	}
	foreach $term (@{$document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)}) {
	    if ($term->isTerm) {
		    return($term);
	    }
	}
	$token = $token->next;
    } while(($currentWindowSize < $WindowSize) && (defined $token) && ($token->getFrom <= $end_token->getTo));

    return(0);
}

sub _searchPOSTAG {
    my ($self, $document, $start_token, $end_token, $POSTAG, $WindowSize) = @_;

    my $token = $start_token;
    my $currentWindowSize = 0;
    my %words;

#       print STDERR "search POSTAG ($POSTAG - $WindowSize)\n";
    do {
# 	print $token->getContent . "\n";
	my @words = @{$document->getAnnotations->getWordLevel->getElementByToken($token)}; 
	if (scalar(@words) > 0) {
	    $words{$words[0]->getId}++;
	    $currentWindowSize = scalar(keys %words);
#  	    print STDERR "word : " . $words[0]->getMorphoSyntacticFeatures($document) . "\n";
#  	    print STDERR "word : " . $words[0]->getMorphoSyntacticFeatures($document)->syntactic_category . "\n";

	    if ($words[0]->getMorphoSyntacticFeatures($document)->syntactic_category eq $POSTAG) {
		return($words[0]);
	    }
	}
	$token = $token->next;
    } while(($currentWindowSize < $WindowSize) && (defined $token) && ($token->getFrom <= $end_token->getTo));

    return(0);
}

sub _searchWordRE {
    my ($self, $document, $start_token, $end_token, $wordRegExp, $WindowSize) = @_;

    my $sentenceLemma;
    my $offset_refs;
#     print STDERR "in wordRE: $wordRegExp (" . $start_token->getContent . ")\n";

    my $word_re_start_token = undef;
    my $word_re_end_token = undef;
    my $currentWindowSize = 0;
    my %words;
    my $token = $start_token;

    do {
	my @words = @{$document->getAnnotations->getWordLevel->getElementByToken($token)}; 
	if (scalar(@words) > 0) {
	    $words{$words[0]->getId}++;
	    $currentWindowSize = scalar(keys %words);
	}
	$token = $token->next;
    } while(($currentWindowSize < $WindowSize) && (defined $token) && ($token->getFrom <= $end_token->getTo));


    ($sentenceLemma, $offset_refs) = $self->_getLemmatisedSentence($document, $start_token, $token->previous);

#     print STDERR $sentenceLemma . ";\n";

    while(($sentenceLemma =~ /$wordRegExp/gcsi) && (!defined $word_re_end_token)){
# 	print STDERR "match\n";
	$word_re_start_token = undef;
	if (exists $offset_refs->{length($`)}) {
	    $word_re_start_token = $offset_refs->{length($`)};
	}
	$word_re_end_token = undef;
	if (exists $offset_refs->{length($` . $&)}) {
	    $word_re_end_token = $offset_refs->{length($` . $&)};
	    $word_re_end_token = $word_re_end_token->previous;
	} elsif (exists $offset_refs->{length($` . $&) - 1}) {
	    $word_re_end_token = $offset_refs->{length($` . $&) - 1};
	    $word_re_end_token = $word_re_end_token->previous;
	}
	
    }

    return($word_re_start_token, $word_re_end_token);
}
sub _searchWord {
    my ($self, $document, $start_token, $end_token, $wordForm, $WindowSize) = @_;

    my $token = $start_token;
    my $currentWindowSize = 0;
    my %words;

#      print STDERR "search Word\n";

    do {
# 	print $token->getContent . "\n";
	my @words = @{$document->getAnnotations->getWordLevel->getElementByToken($token)}; 
	if (scalar(@words) > 0) {
	    $words{$words[0]->getId}++;
	    $currentWindowSize = scalar(keys %words);
	    if ((lc($words[0]->getForm) eq lc($wordForm)) || (lc($words[0]->getLemma($document)->canonical_form) eq lc($wordForm))) {
		return($words[0]);
	    }
	}
	$token = $token->next;
    } while(($currentWindowSize < $WindowSize) && (defined $token) && ($token->getFrom <= $end_token->getTo));

    return(0);
}

sub _selectSentencesFromPattern {
    my ($self, $pattern, $selectedSentences, $document, $level) = @_;

#     print STDERR "===\n";
#     my $pattern = $synPattern->{"pattern"};
    my $i;
    my $sentence;
    for($i = 0; $i < scalar(@$pattern); $i++) {
#  	print STDERR "i: $i " .  $pattern->[$i]->{'type'} . "\n";
# 	foreach $sentence (values %$selectedSentences) {
# 	    print STDERR "sentenceID: " . $sentence->{'sentence'}->getId . "\n";
# 	}
	# selection of the sentence containing $pattern->[$i] (Semtype) according to %selectedSentences
	if ($pattern->[$i]->{'type'} eq "semtype") {
	    $selectedSentences = $self->_selectSentencesFromSemType($pattern->[$i]->{'semtype'}, $selectedSentences, $i + $level, $document);
	}
	# selection of the sentence containing $pattern->[$i] (termcontent) according to %selectedSentences
	if ($pattern->[$i]->{'type'} eq "termcontent") {
	    $selectedSentences = $self->_selectSentencesFromTermContent($pattern->[$i]->{'termcontent'}, $selectedSentences, $i + $level, $document);
	}
	# selection of the sentence containing $pattern->[$i] (term) according to %selectedSentences
	if ($pattern->[$i]->{'type'} eq "term") {
	    $selectedSentences = $self->_selectSentencesFromTerm($selectedSentences, $i + $level, $document);
	}
	# selection of the sentence containing $pattern->[$i] (postag) according to %selectedSentences
	if ($pattern->[$i]->{'type'} eq "postag") {
	    $selectedSentences = $self->_selectSentencesFromPOSTAG($pattern->[$i]->{'postag'}, $selectedSentences, $i + $level, $document);
	}
	# selection of the sentence containing $pattern->[$i] (word) according to %selectedSentences
	if ($pattern->[$i]->{'type'} eq "word") {
	    $selectedSentences = $self->_selectSentencesFromWord($pattern->[$i]->{'word'}, $selectedSentences, $i + $level, $document);
	}
	
	# selection of the sentence containing $pattern->[$i] (word_re) according to %selectedSentences
	if ($pattern->[$i]->{'type'} eq "word_re") {
	    $selectedSentences = $self->_selectSentencesFromWordRE($pattern->[$i]->{'word_re'}, $selectedSentences, $i + $level, $document);
	}

	# selection of the sentence containing $pattern->[$i] (syndep) according to %selectedSentences
	if ($pattern->[$i]->{'type'} eq "syndep") {
	    $selectedSentences = $self->_selectSentencesFromSynDep($pattern->[$i]->{'syndep'}, $selectedSentences, $i + $level, $document);
	}
	# if chunk, go inside the chunk
	if ($pattern->[$i]->{'type'} eq "chunk") {
	    $selectedSentences = $self->_selectSentencesFromPattern($pattern->[$i]->{'chunk'}, $selectedSentences, $document, $level + 1);
	}
#     foreach $sentence (values %$selectedSentences) {
# 	print STDERR "sentenceID: " . $sentence->{'sentence'}->getId . "\n";
# # 	print STDERR Dumper($sentence->{'first_item'});
#     }
    }
#     print STDERR "----\n";
    return($selectedSentences);
}

# selection of the sentence containing $pattern->[$i] (Semtype) according to %selectedSentences

sub _selectSentencesFromSemType {
    my ($self, $semtypeAcr, $selectedSentences, $i, $document) = @_;

    my %newSelectedSentences;
    my $term;
    my $sentence;
    my $semtype = $self->{"SEMANTICTYPES"}->{$semtypeAcr};

#      print STDERR "select semtype: $semtype\n";
    foreach $term (@{$document->getAnnotations->getSemanticUnitLevel->getElements}) {
# 	if ($term->isTerm) {
# 	print STDERR "    " . $term->getForm . "\n";
#  	    print STDERR "FC: " . $term->getSemanticFeatureFC($document) . "\n";
# 	}
	if (($term->isTerm) && ((defined($term->getSemanticFeatureFC($document))) && ($term->getSemanticFeatureFC($document) eq $semtype))) {
	    foreach $sentence (values %$selectedSentences) {
		if (($sentence->{'sentence'}->refid_start_token->getFrom <= $term->start_token->getFrom) &&
		    ($term->end_token->getTo <= $sentence->{'sentence'}->refid_end_token->getTo)) {
#   		    print STDERR "==>sentenceID: " . $sentence->{'sentence'}->getId . "$term (" . $term->getForm . ")\n";
 		    if (($i == 0) || (scalar(@{$sentence->{'first_item'}}) == 0)) {
# 		    if ($i == 0) {
			$newSelectedSentences{$sentence->{'sentence'}->refid_start_token}->{'sentence'} = $sentence->{'sentence'};
			push @{$newSelectedSentences{$sentence->{'sentence'}->refid_start_token}->{'first_item'}}, $term;
		    } else {
			$newSelectedSentences{$sentence->{'sentence'}->refid_start_token} = $sentence;
		    }
		}
	    }
	}	
    }
    $selectedSentences = \%newSelectedSentences;
    return(\%newSelectedSentences);
}

# selection of the sentence containing $pattern->[$i] (termcontent) according to %selectedSentences

sub _selectSentencesFromTermContent {
    my ($self, $termcontent, $selectedSentences, $i, $document) = @_;

    my %newSelectedSentences;
    my $term;
    my $sentence;


#      print STDERR "select termcontent: $termcontent\n";
    foreach $term (@{$document->getAnnotations->getSemanticUnitLevel->getElements}) {
# 	if ($term->isTerm) {
# 	    print "FC: " . $term->getSemanticFeatureFC($document) . "\n";
# 	}
	if (($term->isTerm) && ($term->getForm eq $termcontent)) {
	    foreach $sentence (values %$selectedSentences) {
		if (($sentence->{'sentence'}->refid_start_token->getFrom <= $term->start_token->getFrom) &&
		    ($term->end_token->getTo <= $sentence->{'sentence'}->refid_end_token->getTo)) {
# 		    print "==>sentenceID: " . $sentence->{'sentence'}->getId . "\n";
  		    if (($i == 0) || (scalar(@{$sentence->{'first_item'}}) == 0)) {
# 		    if ($i == 0) {
			$newSelectedSentences{$sentence->{'sentence'}->refid_start_token}->{'sentence'} = $sentence->{'sentence'};
			push @{$newSelectedSentences{$sentence->{'sentence'}->refid_start_token}->{'first_item'}}, $term;
		    } else {
			$newSelectedSentences{$sentence->{'sentence'}->refid_start_token} = $sentence;
		    }
		}
	    }
	}	
    }
    $selectedSentences = \%newSelectedSentences;
    return(\%newSelectedSentences);
}

# selection of the sentence containing $pattern->[$i] (term) according to %selectedSentences

sub _selectSentencesFromTerm {
    my ($self, $selectedSentences, $i, $document) = @_;

    my %newSelectedSentences;
    my $term;
    my $sentence;

#      print STDERR "select term exists ?\n";
    foreach $term (@{$document->getAnnotations->getSemanticUnitLevel->getElements}) {
# 	if ($term->isTerm) {
# 	    print "FC: " . $term->getSemanticFeatureFC($document) . "\n";
# 	}
	if ($term->isTerm) {
	    foreach $sentence (values %$selectedSentences) {
		if (($sentence->{'sentence'}->refid_start_token->getFrom <= $term->start_token->getFrom) &&
		    ($term->end_token->getTo <= $sentence->{'sentence'}->refid_end_token->getTo)) {
# 		    print "==>sentenceID: " . $sentence->{'sentence'}->getId . "\n";
 		    if (($i == 0) || (scalar(@{$sentence->{'first_item'}}) == 0)) {
# 		    if ($i == 0) {
			$newSelectedSentences{$sentence->{'sentence'}->refid_start_token}->{'sentence'} = $sentence->{'sentence'};
			push @{$newSelectedSentences{$sentence->{'sentence'}->refid_start_token}->{'first_item'}}, $term;
		    } else {
			$newSelectedSentences{$sentence->{'sentence'}->refid_start_token} = $sentence;
		    }
		}
	    }
	}	
    }
    $selectedSentences = \%newSelectedSentences;
    return(\%newSelectedSentences);
}

# selection of the sentence containing $pattern->[$i] (postag) according to %selectedSentences

sub _selectSentencesFromPOSTAG {
    my ($self, $postag, $selectedSentences, $i, $document) = @_;

    my %newSelectedSentences;
    my $word;
    my $sentence;

#      print STDERR "select postag; $postag\n";

    foreach $word (@{$document->getAnnotations->getWordLevel->getElements}) {
	if ($word->getMorphoSyntacticFeatures($document)->syntactic_category eq $postag) {
	    foreach $sentence (values %$selectedSentences) {
		if (($sentence->{'sentence'}->refid_start_token->getFrom <= $word->start_token->getFrom) &&
		    ($word->end_token->getTo <= $sentence->{'sentence'}->refid_end_token->getTo)) {
 		    if (($i == 0) || (scalar(@{$sentence->{'first_item'}}) == 0)) {
# 		    if ($i == 0) {
			$newSelectedSentences{$sentence->{'sentence'}->refid_start_token}->{'sentence'} = $sentence->{'sentence'};
			push @{$newSelectedSentences{$sentence->{'sentence'}->refid_start_token}->{'first_item'}}, $word;
		    } else {
			$newSelectedSentences{$sentence->{'sentence'}->refid_start_token} = $sentence;
		    }
		}
	    }
	}	
    }
    $selectedSentences = \%newSelectedSentences;
    return(\%newSelectedSentences);
}

# selection of the sentence containing $pattern->[$i] (word) according to %selectedSentences

sub _selectSentencesFromWord {
    my ($self, $wordForm, $selectedSentences, $i, $document) = @_;

    my %newSelectedSentences;
    my $word;
    my $sentence;

#      print STDERR "select word: $wordForm\n";

    foreach $word (@{$document->getAnnotations->getWordLevel->getElements}) {
	if ((lc($word->getForm) eq lc($wordForm)) || (lc($word->getLemma($document)->canonical_form) eq lc($wordForm))) {
# 	    warn "\t> " . $word->getForm . "\n";
	    foreach $sentence (values %$selectedSentences) {
# 		print STDERR "\tsentenceID: " . $sentence->{'sentence'}->getId . "\n";
		if (($sentence->{'sentence'}->refid_start_token->getFrom <= $word->start_token->getFrom) &&
		    ($word->end_token->getTo <= $sentence->{'sentence'}->refid_end_token->getTo)) {
 		    if (($i == 0) || (scalar(@{$sentence->{'first_item'}}) == 0)) {
# 		    if ($i == 0) {
# 			warn "go there (1)\n";
			$newSelectedSentences{$sentence->{'sentence'}->refid_start_token}->{'sentence'} = $sentence->{'sentence'};
			push @{$newSelectedSentences{$sentence->{'sentence'}->refid_start_token}->{'first_item'}}, $word;
		    } else {
# 			warn "go there (2)\n";
			$newSelectedSentences{$sentence->{'sentence'}->refid_start_token} = $sentence;
		    }
		}
	    }
	}	
    }
    $selectedSentences = \%newSelectedSentences;
    return(\%newSelectedSentences);
}


# selection of the sentence containing $pattern->[$i] (word_re) according to %selectedSentences

sub _selectSentencesFromWordRE {
    my ($self, $wordRegExp, $selectedSentences, $i, $document) = @_;

    my %newSelectedSentences;
    my $word;
    my $sentence;
    my $sentenceLemma;
    my $offset_refs;
    my $word_re_start_token;

#      print STDERR "select word_re: $wordRegExp\n";

    foreach $sentence (values %$selectedSentences) {
# 	print STDERR "\tsentenceID: " . $sentence->{'sentence'}->getId . "\n";
	($sentenceLemma, $offset_refs) = $self->_getLemmatisedSentence($document, $sentence->{'sentence'}->refid_start_token, $sentence->{'sentence'}->refid_end_token);

# 	print STDERR "\t$sentenceLemma\n";

	$word_re_start_token = undef;
 	while($sentenceLemma =~ /$wordRegExp/gcsi){
# 	    print STDERR "MATCH\n";
	    $word_re_start_token = undef;
	    if (exists $offset_refs->{length($`)}) {
		$word_re_start_token = $offset_refs->{length($`)};
	    }
	    
 	}
	if (defined $word_re_start_token) {
	    $word = $document->getAnnotations->getWordLevel->getElementByToken($word_re_start_token)->[0];
	    
# 	if (($sentence->{'sentence'}->refid_start_token->getFrom <= $word->start_token->getFrom) &&
# 	    ($word->end_token->getTo <= $sentence->{'sentence'}->refid_end_token->getTo)) {
	    if (($i == 0) || (scalar(@{$sentence->{'first_item'}}) == 0)) {
# 		    if ($i == 0) {
# 		warn "go there (1)\n";
		$newSelectedSentences{$sentence->{'sentence'}->refid_start_token}->{'sentence'} = $sentence->{'sentence'};
		push @{$newSelectedSentences{$sentence->{'sentence'}->refid_start_token}->{'first_item'}}, $word;
	    } else {
# 		warn "go there (2)\n";
		$newSelectedSentences{$sentence->{'sentence'}->refid_start_token} = $sentence;
	    }
# 	}
	}
    }
    $selectedSentences = \%newSelectedSentences;
    return(\%newSelectedSentences);
}



# selection of the sentence containing $pattern->[$i] (syndep) according to %selectedSentences

sub _selectSentencesFromSynDep {
    my ($self, $syndep, $selectedSentences, $i, $document) = @_;

    my %newSelectedSentences;
    my $synrel;
    my $sentence;

#      print STDERR "select syndep: $syndep\n";

    foreach $synrel (@{$document->getAnnotations->getSyntacticRelationLevel->getElementFromIndex('syntactic_relation_type', $syndep)}) {
#     foreach $synrel (@{$document->getAnnotations->getSyntacticRelationLevel->getElements}) {
# 	if ($synrel->syntactic_relation_type eq $syndep) {
	    foreach $sentence (values %$selectedSentences) {
		if (($sentence->{'sentence'}->refid_start_token->getFrom <= $synrel->refid_head->[0]->start_token->getFrom) &&
		    ($synrel->refid_head->[0]->end_token->getTo <= $sentence->{'sentence'}->refid_end_token->getTo)) {
 		    if (($i == 0) || (scalar(@{$sentence->{'first_item'}}) == 0)) {
# 		    if ($i == 0) {
			$newSelectedSentences{$sentence->{'sentence'}->refid_start_token}->{'sentence'} = $sentence->{'sentence'};
			if ($synrel->refid_head->[0]->start_token->getFrom < $synrel->refid_modifier->[0]->start_token->getFrom) {
			    push @{$newSelectedSentences{$sentence->{'sentence'}->refid_start_token}->{'first_item'}}, $synrel->refid_head->[0];
			} else {
			    push @{$newSelectedSentences{$sentence->{'sentence'}->refid_start_token}->{'first_item'}}, $synrel->refid_modifier->[0];
			}
		    } else {
			$newSelectedSentences{$sentence->{'sentence'}->refid_start_token} = $sentence;
		    }
		}
	    }
# 	}	
    }
    $selectedSentences = \%newSelectedSentences;
    return(\%newSelectedSentences);
}


sub _parseTreeTaggerFormatOutput {
    my ($self, $output_filename, $replace) = @_;
# ($self->_output_filename);

    my $line;
    my @TreeTaggerOutput;

    my $doc_idx;
    my $word_idx;
    my $document;

    my $word;
    my $token;

    my $posInWord;
    my $posInLemma;

    my $substringBefore;
    my $substringAfter;

    my $MSFeatures;
    my $Lemma;

    warn "[LOG] . Parsing " . $self->_output_filename . "\n";

    open FILE_OUT, $output_filename or warn "Can't open the file " . $output_filename;;
#     binmode(FILE_OUT, ":utf8");

    while($line = <FILE_OUT>) {
	chomp $line;
#	if ($line ne "") {
# 	    my @tmp = split /[\t\|]/, $line;
	    my @tmp = split /\t| ?\| ?/, $line; #/
	    # warn "$line : " . join(':', @tmp) . "\n";
	    if (scalar(@tmp) >= 3) {
		if ($tmp[1] ne "DOCUMENT") {
		    # work around some strange tagging 
		    if (!defined $tmp[1]) {
			$tmp[1] = "SYM";
		    }
		    if (!defined $tmp[2]) {
			$tmp[2] = $tmp[0];
		    }
		    push @TreeTaggerOutput, \@tmp;
		}
	    } else {
		# if (scalar(@tmp) != 0) {
		    push @TreeTaggerOutput, \@tmp;
		# }
	    }
#	}

    }
    close FILE_OUT;

#      warn "TT output size: " . scalar(@TreeTaggerOutput) . "\n";

#     warn "\n\n";
    my $TreeTaggerOutput_idx = 0;

    foreach $document (@{$self->_documentSet}) {
# 	warn $document->getId . "\n";
	for($doc_idx = 0; $doc_idx < scalar(@{$document->getAnnotations->getTokenLevel->getElements});$doc_idx++) {
	    # if ((!defined $TreeTaggerOutput[$TreeTaggerOutput_idx]) || (scalar(@{$TreeTaggerOutput[$TreeTaggerOutput_idx]}) == 0)) {
	    # 	$TreeTaggerOutput_idx++;
	    # }
	    $token = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];
	    if ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
		$word = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];

     		# warn $word->getForm . " (" . $word->getId . ") " . $TreeTaggerOutput[$TreeTaggerOutput_idx]->[0] . " : " . $TreeTaggerOutput[$TreeTaggerOutput_idx]->[1] . " : " . $TreeTaggerOutput[$TreeTaggerOutput_idx]->[2] . "\n";

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
#   			    warn "lemma to correct : " . $TreeTaggerOutput[$TreeTaggerOutput_idx]->[2] . "\n";
			    $substringBefore = substr($TreeTaggerOutput[$TreeTaggerOutput_idx]->[2], 0, $posInLemma);
			    $substringAfter = substr($TreeTaggerOutput[$TreeTaggerOutput_idx]->[2], $posInLemma + 1);
			    
#   			    warn "New lemma : $substringBefore $substringAfter ($posInLemma)\n";
			    $TreeTaggerOutput[$TreeTaggerOutput_idx]->[2] = "$substringBefore $substringAfter";
			    $posInLemma++;
			}
		    } while (($posInLemma != -1) && ($posInLemma != $posInWord) && ($posInLemma < length($TreeTaggerOutput[$TreeTaggerOutput_idx]->[2])));
		}

		# work around some strange tagging 
# 		warn "TreeTaggerOutput_idx: $TreeTaggerOutput_idx\n";
		if ((defined $TreeTaggerOutput[$TreeTaggerOutput_idx]->[1]) && ($TreeTaggerOutput[$TreeTaggerOutput_idx]->[1] eq "SENT")) {
		    $TreeTaggerOutput[$TreeTaggerOutput_idx]->[1] = "NP";
		}

		# if (scalar(@{$TreeTaggerOutput[$TreeTaggerOutput_idx]}) >= 0) {
		    if ($replace == 1) {
			# Correction bug
			my $ttg_syntactic_category = $word->getMorphoSyntacticFeatures($document)->syntactic_category;
			my $ttg_lemma = $word->getLemma($document)->canonical_form;

			# if (! defined $TreeTaggerOutput[$TreeTaggerOutput_idx]->[0]) {
			#     warn "(0) " . join(';', @{$TreeTaggerOutput[$TreeTaggerOutput_idx]}) . " $ttg_lemma\n";
			# }
			# if (scalar(@{$TreeTaggerOutput[$TreeTaggerOutput_idx]}) == 0) {
			# 	@{$TreeTaggerOutput[$TreeTaggerOutput_idx]} = ($ttg_lemma, $ttg_syntactic_category, $ttg_lemma);
			# }
			

			if ((defined $ttg_syntactic_category) && (defined $ttg_lemma) && 
			    (defined ($TreeTaggerOutput[$TreeTaggerOutput_idx]->[0])) &&
			    ($TreeTaggerOutput[$TreeTaggerOutput_idx]->[0] =~ /^:Vm\-\-/o)) {
# 			warn "Passe ici\n";
			    if ($ttg_syntactic_category eq "ADJ") {
				$TreeTaggerOutput[$TreeTaggerOutput_idx]->[1] = "ADJ:A---s--";
				$TreeTaggerOutput[$TreeTaggerOutput_idx]->[2] = $ttg_lemma;
			    } else {
# 			    warn "et ici\n";
				$TreeTaggerOutput[$TreeTaggerOutput_idx]->[1] = "NOM:Nc-s--";
				$TreeTaggerOutput[$TreeTaggerOutput_idx]->[2] = $ttg_lemma;
			    }
			}
			if ((defined $ttg_syntactic_category) && (defined $ttg_lemma)){
			    
			    # if (! defined $TreeTaggerOutput[$TreeTaggerOutput_idx]->[1]) {
			    # 	warn "(1) " . join(';', @{$TreeTaggerOutput[$TreeTaggerOutput_idx]}) . " $ttg_lemma\n";
			    # }
			    #(scalar(@{$TreeTaggerOutput[$TreeTaggerOutput_idx]}) == 0) || 
			    
			    if ((!defined $TreeTaggerOutput[$TreeTaggerOutput_idx]->[1]) || 
				($TreeTaggerOutput[$TreeTaggerOutput_idx]->[1] eq "")) {
				$TreeTaggerOutput[$TreeTaggerOutput_idx]->[1] = $ttg_syntactic_category;
#			    $TreeTaggerOutput[$TreeTaggerOutput_idx]->[0] = $FF;
				$TreeTaggerOutput[$TreeTaggerOutput_idx]->[2] = $ttg_lemma;
			    }
			    # if (! defined $TreeTaggerOutput[$TreeTaggerOutput_idx]->[2]) {
			    # warn "(2) " . join(';', @{$TreeTaggerOutput[$TreeTaggerOutput_idx]}) . " $ttg_lemma\n";
			    # }
			    if ((!defined $TreeTaggerOutput[$TreeTaggerOutput_idx]->[2]) || ($TreeTaggerOutput[$TreeTaggerOutput_idx]->[2] eq "\n")) {
				$TreeTaggerOutput[$TreeTaggerOutput_idx]->[2] = $ttg_lemma;
			    }
			}
			$word->getMorphoSyntacticFeatures($document)->syntactic_category($TreeTaggerOutput[$TreeTaggerOutput_idx]->[1]);

			$word->getLemma($document)->canonical_form($TreeTaggerOutput[$TreeTaggerOutput_idx]->[2]);

		    } else {

			$MSFeatures = Lingua::Ogmios::Annotations::MorphosyntacticFeatures->new(
			    {'refid_word' => $word,
			     'syntactic_category' => $TreeTaggerOutput[$TreeTaggerOutput_idx]->[1],
			    });
			$document->getAnnotations->addMorphosyntacticFeatures($MSFeatures);
			
			$Lemma = Lingua::Ogmios::Annotations::Lemma->new(
			    {'refid_word' => $word,
			     'canonical_form' => $TreeTaggerOutput[$TreeTaggerOutput_idx]->[2],
			    });
			$document->getAnnotations->addLemma($Lemma);
		    }
		    $doc_idx += $word->getReferenceSize - 1;
		    $token = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];
		# }
		$TreeTaggerOutput_idx++;

	    } else {
		if ((!($token->isSep)) && ($token->getContent !~ /[\x{2019}\x{2032}']/go)) {
#		if (!($token->isSep)) {
		    $TreeTaggerOutput_idx++;
 		    # warn $token->getContent . " (" . $token->getId . ") " . $TreeTaggerOutput[$TreeTaggerOutput_idx]->[0] . "\n";
		}
	    }
	    if ($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId)) {
		if ($token->isSymb) {
		    if ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
			
# 		    } else {
			$TreeTaggerOutput_idx++;
# 			warn $token->getContent . " (" . $token->getId . ") " . $TreeTaggerOutput[$TreeTaggerOutput_idx]->[0] . " 0 \n";
		    }
		} else {
		    $TreeTaggerOutput_idx++;
# 		    warn ". ( 000 ) " . $TreeTaggerOutput[$TreeTaggerOutput_idx++]->[0] . "\n";
		}
	    }
	    # if (scalar(@{$TreeTaggerOutput[$TreeTaggerOutput_idx]}) == 0) {
	    # 	$TreeTaggerOutput_idx++;
	    # }

	}
    }

}

sub propagateSemanticFeatures {
    my ($self) = @_;

    my $document;
    my $syntactic_relation;
    my $head_term;
    my $term;

    warn "[LOG] propagateSemanticFeatures\n";

    foreach $document (@{$self->_documentSet}) {
	foreach $syntactic_relation (@{$document->getAnnotations->getSyntacticRelationLevel->getElements}) {
	    # warn $syntactic_relation->getId . "\n";
	    # warn $syntactic_relation->syntactic_relation_type . "\n";
	    if ($syntactic_relation->syntactic_relation_type eq "Head_of") {
		# warn "\t" . $syntactic_relation->refid_head->[0] . "\n";
		# warn "\t" . $syntactic_relation->reference_name_head . "\n";
		$head_term = $document->getAnnotations->getSemanticUnitLevel->getElementFromIndex($syntactic_relation->reference_name_head, $syntactic_relation->refid_head->[0]->getId)->[0];
		# warn "===\n";
		# warn "\t" . $syntactic_relation->refid_modifier->[0] . "\n";
		# warn "\t" . $syntactic_relation->reference_name_modifier . "\n";
		$term = $document->getAnnotations->getSemanticUnitLevel->getElementFromIndex($syntactic_relation->reference_name_modifier, $syntactic_relation->refid_modifier->[0]->getId)->[0];
		# warn "===\n";

		# warn "head = " . $head_term->getForm . "\n";
		# warn "head = " . $head_term->getId . "\n";
		# warn "term = " . $term->getForm . "\n";
		# warn "term = " . $term->getId . "\n";
		if (($document->getAnnotations->getSemanticFeaturesLevel->existsElementFromIndex("refid_semantic_unit", $head_term->getId)) &&
		   (!($document->getAnnotations->getSemanticFeaturesLevel->existsElementFromIndex("refid_semantic_unit", $term->getId)))) {
#		    $document->getAnnotations->getSemanticFeaturesLevel->addSemanticFeature
		    # warn "head = " . $head_term->getId . "\n";
		    # warn "term = " . $term->getId . "\n";
		    # warn "semf = " . $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $head_term->getId)->[0]->getId . "\n";
		    # warn "add a semantic Feature to the term " . $term->getId . "(" . $term->getForm . ")\n";
		    $self->_addSemanticFeature($term, $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $head_term->getId)->[0]->semantic_category, $document);
# _addSemanticFeature {
#     my ($self, $termUnit, $semtag, $document) = @_;
		}
	    }
	}
    }    

    warn "done\n";
}

sub _addRelation {
#    my $self;

#    warn join(" : ", (caller(1))) . "\n";

    # warn $_[0] . " : " . __PACKAGE__ . " : " . ref($_[0]) . "\n";

    # if (index($_[0], __PACKAGE__) == 0){
    # 	$self = shift;
    # }
    my ($self, $document, $reltype, $list_refid) = @_;

    my $domainSpecificRelation;
    my @tmpTerms;
    my $i;
    my $rel;
    my $rel1;
    my $rel2;
    my %hrel1;

    push @tmpTerms, @$list_refid;

    # warn $tmpTerms[0]->getForm . "\n";
    # warn $tmpTerms[1]->getForm . "\n";

    $i = 0;
    if (!$tmpTerms[0]->equals($tmpTerms[1])) {
	if ((defined $document->getAnnotations->getDomainSpecificRelationLevel->getElementFromIndex("list_refid_semantic_unit", $tmpTerms[0]->getId)) && 
	    (defined $document->getAnnotations->getDomainSpecificRelationLevel->getElementFromIndex("list_refid_semantic_unit", $tmpTerms[1]->getId))){
	    $rel1 = $document->getAnnotations->getDomainSpecificRelationLevel->getElementFromIndex("list_refid_semantic_unit", $tmpTerms[0]->getId);
	    $rel2 = $document->getAnnotations->getDomainSpecificRelationLevel->getElementFromIndex("list_refid_semantic_unit", $tmpTerms[1]->getId);

	    foreach $rel (@$rel1) {
		$hrel1{$rel} = 0;
	    }
	    $i = 0;
	    while(($i < scalar(@$rel2)) && (!exists($hrel1{$rel2->[$i]}))) {
		$i++;
	    }
	}
	if (((!defined $rel2) || ($i == scalar(@$rel2))) ) {
#  	    warn "add a relation\n";
	    $domainSpecificRelation = Lingua::Ogmios::Annotations::DomainSpecificRelation->new(
		{'domain_specific_relation_type' => $reltype,
		 'list_refid_semantic_unit' => \@tmpTerms,
		});
	    $document->getAnnotations->addDomainSpecificRelation($domainSpecificRelation);
	    return($domainSpecificRelation);
	} else {
  	    warn "Relationalready exists\n";
	    return(undef);
	}
    } else {
	warn "term1 == term2\n";
	return(undef);
    }
}

sub getTimer {
    my ($self) = @_;

    return($self->{'timer'});
}

sub currentDocument {
    my $self = shift;

    $self->{'currentDocument'} = shift if @_;
    return $self->{'currentDocument'};

}

sub _loadStopWords {
    my ($self, $filename, $lang, $name) = @_;
    my %resource;

    if (defined $self->{$name}) {
	%resource = %{$self->{$name}->{$lang}};
    }
    
    my $line;
        if (!(open FILE, $filename)) {
	    warn "No such file " . $filename . "\n";
	    return(-1);
	}
    while ($line = <FILE>) {
	chomp $line;
	if (($line !~ /^\s*$/o) && ($line !~ /^\s*\#$/o)){
   	    $resource{$line} = 0;
        }

    }
    close FILE;

    $self->{$name}->{$lang} = \%resource;
}

sub _loadList {
    my ($self, $filename, $lang, $name) = @_;
    my @resource;

    if (defined $self->{$name}) {
	@resource = @{$self->{$name}->{$lang}};
    }
    
    my $line;
        if (!(open FILE, $filename)) {
	    warn "No such file " . $filename . "\n";
	    return(-1);
	}
    while ($line = <FILE>) {
	chomp $line;
	if (($line !~ /^\s*$/o) && ($line !~ /^\s*\#$/o)){
   	    push @resource, $line;
        }

    }
    close FILE;

    $self->{$name}->{$lang} = \@resource;
}


sub _setOption {
    my ($self, $lang2, $optionRC, $option, $defaultValue, $defaultType) = @_;
    my $item;

    # warn "==> $lang2\n";
    my $lang = "language=" . uc($lang2);

    
    if (defined $self->_config->configuration->{'CONFIG'}->{$lang}->{$optionRC}) {

	# warn $self->_config->configuration->{'CONFIG'}->{$lang}->{$optionRC} . "\n";
	if (ref($self->_config->configuration->{'CONFIG'}->{$lang}->{$optionRC}) eq "ARRAY") {
	    $self->{$option}->{$lang2} = {};
	    foreach $item (@{$self->_config->configuration->{'CONFIG'}->{$lang}->{$optionRC}}) {
		$self->{$option}->{$lang2}->{$item}++;
	    }
	} else {
	    if ((defined $defaultType) && ($defaultType eq "HASH")) {
		$self->{$option}->{$lang2}->{$self->_config->configuration->{'CONFIG'}->{$lang}->{$optionRC}}++;
	    } else {
		# warn "ok ($optionRC)\n";
		if ($self->_config->configuration->{'CONFIG'}->{$lang}->{$optionRC} eq '\n') {
		    $self->_config->configuration->{'CONFIG'}->{$lang}->{$optionRC} = "\n";
		} elsif ($self->_config->configuration->{'CONFIG'}->{$lang}->{$optionRC} eq '\t') {
		    $self->_config->configuration->{'CONFIG'}->{$lang}->{$optionRC} = "\t";
		}
		$self->{$option}->{$lang2} = $self->_config->configuration->{'CONFIG'}->{$lang}->{$optionRC};
	    }
	}
    } else {
	$self->{$option}->{$lang2} = $defaultValue;
    }
}

sub _setGeneralOption {
    my ($self, $optionRC, $option, $defaultValue, $defaultType) = @_;
    my $item;

    # warn "==> $lang2\n";

    
    if (defined $self->_config->configuration->{'CONFIG'}->{$optionRC}) {

	# warn $self->_config->configuration->{'CONFIG'}->{$lang}->{$optionRC} . "\n";
	if (ref($self->_config->configuration->{'CONFIG'}->{$optionRC}) eq "ARRAY") {
	    $self->{$option} = {};
	    foreach $item (@{$self->_config->configuration->{'CONFIG'}->{$optionRC}}) {
		$self->{$option}->{$item}++;
	    }
	} else {
	    if ((defined $defaultType) && ($defaultType eq "HASH")) {
		$self->{$option}->{$self->_config->configuration->{'CONFIG'}->{$optionRC}}++;
	    } else {
		# warn "ok ($optionRC)\n";
		$self->{$option} = $self->_config->configuration->{'CONFIG'}->{$optionRC};
	    }
	}
    } else {
	$self->{$option} = $defaultValue;
    }
}

sub _getCanonicalForm {
    my ($self, $term, $document) = @_;

    my $canForm;
    my $elmt;

    # warn ">> " . $term->getForm . "\n";
    if (!defined $term->canonical_form) {
	if ($term->reference_name eq "refid_word") {
	    $canForm = $term->reference->getLemma($document)->canonical_form;
	} elsif ($term->reference_name eq "refid_phrase") {
	    $canForm = "";
	    foreach $elmt ($term->reference->getElementList) {
		# warn "$elmt\n";
		if (ref($elmt) eq "Lingua::Ogmios::Annotations::Word") {
		    $canForm .= $elmt->getLemma($document)->canonical_form . " ";
		} else {
		    $canForm .= $elmt->getContent;
		}
	    }
	    $canForm =~ s/ +$//go;
	} else {
	    foreach $elmt (@{$term->reference}) {
		$canForm .= $elmt->getContent;		    
	    }		
	}
    } else {
	$canForm = $term->canonical_form;
	# warn "===> $canForm\n";
    }
    # warn ">> " . $term->getForm . ": $canForm\n";
    return($canForm);
}

sub _getSyntacticCategory {
    my ($self, $term, $document) = @_;

    my $syntCat;
    my $elmt;

    if ($term->reference_name eq "refid_word") {
	$syntCat = $term->reference->getMorphoSyntacticFeatures($document)->syntactic_category;
    } elsif ($term->reference_name eq "refid_phrase") {
	$syntCat = "";
	foreach $elmt ($term->reference->getElementList) {
	    if (ref($elmt) eq "Lingua::Ogmios::Annotations::Word") {
		    $syntCat .= $elmt->getMorphoSyntacticFeatures($document)->syntactic_category . " ";
		} else {
		    $syntCat .= $elmt->getContent;
		}
	    }
	    $syntCat =~ s/ +$//go;
    } else {
	foreach $elmt (@{$term->reference}) {
	    $syntCat .= $elmt->getContent;		    
	}		
    }
    return($syntCat);
}

sub _printCRFInput {
    my ($self, $fh, $fields) = @_;

    $self->_makeTaggedSentencesCRF("", $fh, "\t", "\n", $fields);
}

sub _getValidation {
    my ($self, $SemUnit) = @_;

    return('-');

}
sub _makeTaggedSentencesCRF {
    my ($self, $sentences, $fh, $sepInfo, $sepUnit, $fields) = @_;

    if (!defined $fh) {
	$fh = *STDOUT;
    }

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
    my $semf;
    my $wordform;
    my $lang;
    my $lineNb;
#    my $validatedTerms;
    my $terms;
    my $numberOfWeights;
    my $validation = 0;
    my @weights;
    my @emptyWeights;
    my $sortedFields = [sort {$fields->{$a}->{'ORDER'} <=> $fields->{$b}->{'ORDER'}} keys(%$fields)];
    my $weight;

    if (exists $fields->{'WEIGHTS'}) {
	# Get number of weigts
	# my @terms = @{$self->_documentSet->[0]->getAnnotations->getSemanticUnitLevel->getElements};
	# $i = 0;
	# while(($i < scalar(@terms)) && (!$terms[$i]->isTerm)) { $i++; };
	# if ($i < scalar(@terms)) {
	#     $numberOfWeights = $terms[$i]->numberOfWeights;
	# } else {
	#     $numberOfWeights = 0;
	# }
	$numberOfWeights = scalar(@{$fields->{'WEIGHTS'}->{'LIST'}});
	warn "Number of weights: $numberOfWeights\n";
	# warn "  List of weights: " . join(':', keys(%{$terms[$i]->weights})) . "\n";
	for($i=0;$i < $numberOfWeights; $i++) {
	    $emptyWeights[$i] = -1;
	}
    }

    $self->getTimer->startsLap("making tagged sentences");
    warn "[LOG] printing Tagged Sentences\n";

    # warn "open " . $self->_input_filename . "(1)\n";

    # open FILEINPUT, ">:utf8", $self->_input_filename or die "No such file " . $self->_input_filename;

    for ($i = 0; $i < scalar(@{$self->_documentSet}); $i++) {
	$self->getTimer->startsLapByCategory('document');

	$document = $self->_documentSet->[$i];
	$lang = $document->getAnnotations->getLanguage;

	# if ((exists $fields->{"VALIDATION"}) && (defined $keywordProperty)) {
	#     # if (!defined $validatedTerms) {
	# 	$keywords = $self->_getCorrectKeywords($document, $keywordProperty);
	#     # }
	# }
	# warn "$keywordProperty: " . join(":", %$validatedTerms) . "\n";

	# if (defined $termField) {
	    
	# }

	$self->getTimer->startsLapByCategory('token');

	$token = $document->getAnnotations->getTokenLevel->getElements->[0];

	$self->getTimer->endsLapByCategory('token');
	while(defined ($token)) {
	    $self->getTimer->startsLapByCategory('token2');
	    $terms = $document->getAnnotations->getSemanticUnitLevel->getElementByToken($token);

	    if (scalar(@$terms) > 0) {
		$self->getTimer->startsLapByCategory('semUnit');

		$self->getTimer->startsLapByCategory('LargerSemUnit');
		$SemUnit = $self->_getLargerTerm($terms);
		$self->getTimer->endsLapByCategory('LargerSemUnit');

		# warn "OK\n";
		if ($SemUnit->isNamedEntity) {
		    $canonical_form = $self->_getCanonicalForm($SemUnit, $document);
		    # if (!defined $SemUnit->canonical_form) {
		    # 	$canonical_form = "";
		    # } else {
		    # 	$canonical_form = $SemUnit->canonical_form;
		    # }
		    @weights = ();
		    foreach $weight (@{$fields->{'WEIGHTS'}->{'LIST'}}) {
			if ($weight eq "position") {
			    push  @weights, $SemUnit->start_token->getFrom;
			} elsif ($weight eq "wordLength") {
				push  @weights, $SemUnit->getReferenceWordSize;
			} else {
			    push @weights, -1;
			}
		    }

		    $self->_addInfosUnit($lang, \$lineNb, \@corpus_in_t, {"IF" => $SemUnit->getForm, 
							 "ID" => $SemUnit->getId, 
							 "POSTAG" => "named_entity", 
							 "LM" => $canonical_form, 
							 "SEMTAG" => $SemUnit->NEtype,
							 "DOCID" => $document->getId,
							 "WEIGHTS" => [@weights],
							 "VALIDATION" => "-",
					 }, $sortedFields);
		    
		} elsif ($SemUnit->isTerm) {
		    $semf = $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $SemUnit->getId)->[0];
		    # warn "OK2";
		    if (defined $semf) {
		    # warn "OK2b";
			$canonical_form = $self->_getCanonicalForm($SemUnit, $document);
			# if (!defined $SemUnit->canonical_form) {
			#     $canonical_form = "";
			# } else {
			#     $canonical_form = $SemUnit->canonical_form;
			# }
			$validation = $self->_getValidation($SemUnit, $document);
			my $weight;
			@weights = ();
			foreach $weight (@{$fields->{'WEIGHTS'}->{'LIST'}}) {
			    # warn $weight . "\n";
			    if ($SemUnit->existsWeight($weight)) {
				push  @weights, $SemUnit->weight($weight);
			    } elsif ($weight eq "position") {
				push  @weights, $SemUnit->start_token->getFrom;
			    } elsif ($weight eq "wordLength") {
				push  @weights, $SemUnit->getReferenceWordSize;
			    } else {
				push  @weights, 0;
			    }

			}

			$self->_addInfosUnit($lang, \$lineNb, \@corpus_in_t, {"IF" => $SemUnit->getForm, 
							     "ID" => $SemUnit->getId, 
							     "POSTAG" => "term", 
							     "LM" => $canonical_form, 
							     "SEMTAG" => $semf->first_node_first_semantic_category,
							     "DOCID" => $document->getId,
							     "WEIGHTS" => [@weights],
							     "VALIDATION" => $validation,
					     }, $sortedFields);
			$self->{'ML_termlist'}->{$lineNb} = [$i, $SemUnit];
			# warn "$lineNb: " . $SemUnit->getForm . "\n";
		    } else {
		    # warn "OK2c";
			$canonical_form = $self->_getCanonicalForm($SemUnit, $document);
			# if (!defined $SemUnit->canonical_form) {
			#     $canonical_form = "";
			# } else {
			#     $canonical_form = $SemUnit->canonical_form;
			# }
			# warn "OK\n";
			$self->_addInfosUnit($lang, \$lineNb, \@corpus_in_t, {"IF" => $SemUnit->getForm, 
							     "ID" => $SemUnit->getId, 
							     "POSTAG" => "term", 
							     "LM" => $canonical_form, 
							     "SEMTAG" => "NOSEMTAG",
							     "DOCID" => $document->getId,
							     "WEIGHTS" => [@emptyWeights],
							     "VALIDATION" => "-",
					     }, $sortedFields);
		    }
		}
		$token = $SemUnit->end_token;
		$self->getTimer->endsLapByCategory('semUnit');
	    } elsif ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
		$self->getTimer->startsLapByCategory('word');
		$word = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];
		$lemma = $document->getAnnotations->getLemmaLevel->getElementFromIndex("refid_word", $word->getId)->[0];
		$MS_features = $document->getAnnotations->getMorphosyntacticFeaturesLevel->getElementFromIndex("refid_word", $word->getId)->[0];
		$wordform = $word->getForm;
		$wordform =~ s/[\t\n]/ /gos;
		$wordform =~ s/  +/ /gos;

		@weights = ();
		foreach $weight (@{$fields->{'WEIGHTS'}->{'LIST'}}) {
		    if ($weight eq "position") {
			push  @weights, $word->start_token->getFrom;
		    } elsif ($weight eq "wordLength") {
			push  @weights, $word->getReferenceSize;
		    } else {
			push @weights, -1;
		    }
		}
		
		$self->_addInfosUnit($lang, \$lineNb, \@corpus_in_t, {"IF" => $wordform, 
						     "ID" => $word->getId, 
						     "POSTAG" => $MS_features->syntactic_category, 
						     "LM" => $lemma->canonical_form, 
						     "SEMTAG" => "NOSEMTAG",
						     "DOCID" => $document->getId,
						     "WEIGHTS" => [@weights],
						     "VALIDATION" => "-",
					     }, $sortedFields);

		$token = $word->end_token;
		
		$self->getTimer->endsLapByCategory('word');
	    } else {
		$self->getTimer->startsLapByCategory('separator');
		if ((!($token->isSep)) && (!($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId)))){
		    $self->_addInfosUnit($lang, \$lineNb, \@corpus_in_t, {"IF" => $token->getContent, 
							 "ID" => $token->getId, 
							 "POSTAG" => $token->getContent, 
							 "LM" => $token->getContent, 
							 "SEMTAG" => "NOSEMTAG",
							 "DOCID" => $document->getId,
							 "WEIGHTS" => [@emptyWeights],
							 "VALIDATION" => "-",
					     }, $sortedFields);
		}
		$self->getTimer->endsLapByCategory('separator');
	    }
	    $self->getTimer->startsLapByCategory('end sentence');
	    if ($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId)) {
		if ($token->isSymb) {
		    if (!($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId))) {
			$self->_addInfosUnit($lang, \$lineNb, \@corpus_in_t, {"IF" => $token->getContent, 
							     "ID" => $token->getId,
							     "POSTAG" => "SENT", 
							     "LM" => $token->getContent, 
							     "SEMTAG" => "NOSEMTAG",
							     "DOCID" => $document->getId,
							     "WEIGHTS" => [@emptyWeights],
							     "VALIDATION" => "-",
					     }, $sortedFields);
			$self->_printTaggedSentence($fh, \@corpus_in_t, $sepInfo, $sepUnit);
			@corpus_in_t = ();
		    } else {
			$self->_addInfosUnit($lang, \$lineNb, \@corpus_in_t, {"IF" => $token->getContent, 
							     "ID" => $token->getId, 
							     "POSTAG" => "SENT", 
							     "LM" => $token->getContent, 
							     "SEMTAG" => "NOSEMTAG",
							     "DOCID" => $document->getId,
							     "WEIGHTS" => [@emptyWeights],
							     "VALIDATION" => "-",
					     }, $sortedFields);
			$self->_printTaggedSentence($fh, \@corpus_in_t, $sepInfo, $sepUnit);
			@corpus_in_t = ();
		    } 
		} else {
		    # my @tmp = (".", $token->getId, "SENT", ".");
		    # push @corpus_in_t, \@tmp;
		    $self->_addInfosUnit($lang, \$lineNb, \@corpus_in_t, {"IF" => ".", 
							 "ID" => $token->getId, 
							 "POSTAG" => "SENT", 
							 "LM" => ".", 
							 "SEMTAG" => "NOSEMTAG",
							 "DOCID" => $document->getId,
							 "WEIGHTS" => [@emptyWeights],
							 "VALIDATION" => "-",
					     }, $sortedFields);
		    $self->_printTaggedSentence($fh, \@corpus_in_t, $sepInfo, $sepUnit);
		    @corpus_in_t = ();
		}
		$self->getTimer->endsLapByCategory('end sentence');
	    }
	    $token = $token->next;
	    $self->getTimer->endsLapByCategory('token2');
	}
	$self->getTimer->endsLapByCategory('token');

	$self->getTimer->endsLapByCategory('document');
    }
    # close FILEINPUT;
    $self->getTimer->_printTimeByCategory(0);
    $self->getTimer->_printTimesBySteps;
    warn "[LOG] done\n";
}

sub _QALDoutput {
    my ($self, $fh) = @_;

    my $document;
    my $i;
    my $lang;
    my $sentence;
    my $SemUnit;
    my $semf;
    my $semfString;
    my %fields = ("IF" => 1, 
		  "POSTAG" => 2, 
		  "LM" => 3,
		  # "ID" => 4, 
		  # "DOCID" => 5, 
		  # "SEMTAG" => 6, 
		  "OFFSET" => 4
	);

    if (!defined $fh) {
	$fh = $self->_out_stream;
	if (!defined $fh) {
	    $fh = \*STDOUT;
	}
    }

    for ($i = 0; $i < scalar(@{$self->_documentSet}); $i++) {
	$self->getTimer->startsLapByCategory('document');

	$document = $self->_documentSet->[$i];
	$lang = $document->getAnnotations->getLanguage;
	print $fh "DOC: " . $document->getId . "\n";
	print $fh "language: $lang\n\n";
	print $fh "sentence: \n";
	print $fh "# sentence form (ended by _END_SENT_)\n";
	foreach $sentence (@{$document->getAnnotations->getSentenceLevel->getElements}) {
	    print $fh XML::Entities::decode('all', $sentence->getForm) . "\n_END_SENT_\n";
	}
	print $fh "\n";
	print $fh "word information:\n";
	print $fh "# Inflected form<tab>POSTAG<tab>Lemma<tab>offset (ended by _END_POSTAG_)\n";
	$self->_makeOneTaggedSentence($document, \*STDOUT, "\t", "\n", "\n", "", " ", \%fields);
	print $fh "_END_POSTAG_\n";
	print $fh "\n";
	print $fh "semantic units:\n";
	print $fh "# term form<tab>term canonical form<tab>semantic features<tab>offset start<tab>offset end<tab>negation indication (ended by _END_SEM_UNIT_)\n";
	foreach $SemUnit (@{$document->getAnnotations->getSemanticUnitLevel->getElements}) {
	    # warn "==> " . $SemUnit->getForm . "\n";
	    print $fh $SemUnit->getForm . "\t" . $self->_getCanonicalForm($SemUnit, $document) . "\t";
	    $semfString = "";
	    foreach $semf (@{$document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $SemUnit->getId)}) {
		$semfString .= $semf->toString . ":";
	    }
	    chop($semfString);
	    print $fh $semfString . "\t" . $SemUnit->start_token->getFrom . "\t" . $SemUnit->end_token->getTo . "\t";
	    if (defined $SemUnit->negation) {
		print $fh $SemUnit->negation;
	    }
	    print $fh "\n";
	}
	print $fh "_END_SEM_UNIT_\n";
	print $fh "\n_END_DOC_\n\n";
    }
}

sub _makeOneTaggedSentence {
    my ($self, $document, $fh, $sepInfo, $sepUnit, $sepSent, $sepSect, $sepTermComp, $fields) = @_;

#    warn "in _makeOneTaggedSentence $sepInfo, $sepUnit\n";

    if (!defined $fh) {
	$fh = *STDOUT;
    }
    if (!defined $fields) {
	$fields = {"IF" => 1, 
		   "POSTAG" => 2, 
		   "LM" => 3,
		   "ID" => 4, 
		   "DOCID" => 5, 
		   "SEMTAG" => 6, 
		   "OFFSET" => 7,
	};
    }
    my $doc_idx;
    my $token;
    my $word;
    my $lemma;
    my $MS_features;
    my $SemUnit;
    my $semForm;
    my @corpus_in_t;
    my $canonical_form;
    my $taggedSentence;
    my $id;
    my $lineNb = 0;
    my $semf;
    my $wordform;
    my $lang;
    my $terms = [];
    my $inSentence = 0;

    if (!defined $sepSect) {
	$sepSect = "";
    }

    $self->getTimer->startsLap("making tagged sentences");
    warn "[LOG] printing Tagged Sentences\n";

    $self->getTimer->startsLapByCategory('document');
    $id = $document->getId;
    $lang = $document->getAnnotations->getLanguage;

    $self->getTimer->startsLapByCategory('token');

    $token = $document->getAnnotations->getTokenLevel->getElements->[0];

    $self->getTimer->endsLapByCategory('token');
    while(defined ($token)) {
	$self->getTimer->startsLapByCategory('token2');
	if ($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_start_token", $token->getId)) {
	    $inSentence = 1;
	}
	# if ((exists $fields->{"SEMTAG"}) && ($fields->{"SEMTAG"} > 0)) {
	    $terms = $document->getAnnotations->getSemanticUnitLevel->getElementByToken($token);
	# } else {
	#     $terms = [];
	# }


	if (scalar(@$terms) > 0) {
	    $self->getTimer->startsLapByCategory('semUnit');

	    $self->getTimer->startsLapByCategory('LargerSemUnit');
	    $SemUnit = $self->_getLargerTerm($terms);
	    $self->getTimer->endsLapByCategory('LargerSemUnit');

	    if ($SemUnit->isNamedEntity) {
		$semForm = $SemUnit->getForm;
		$canonical_form = $self->_getCanonicalForm($SemUnit, $document);
		if ($sepTermComp ne "") {
		    $semForm =~ s/ /$sepTermComp/g;
		    $canonical_form =~ s/ /$sepTermComp/g;
		}
		$self->_addInfosUnit($lang, \$lineNb, \@corpus_in_t, {"IF" => $semForm, 
								      "ID" => "S". $SemUnit->getId, 
								      "POSTAG" => "named_entity", 
								      "LM" => $canonical_form, 
								      "SEMTAG" => $SemUnit->NEtype,
								      "DOCID" => $id,
								      "OFFSET" => $SemUnit->start_token->getFrom,
				     }, $fields);
		
	    } elsif ($SemUnit->isTerm) {
		$semf = $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $SemUnit->getId)->[0];
		if (defined $semf) {
		    $semForm = $SemUnit->getForm;
		    $canonical_form = $self->_getCanonicalForm($SemUnit, $document);
		    if ($sepTermComp ne "") {
			$semForm =~ s/ /$sepTermComp/g;
			$canonical_form =~ s/ /$sepTermComp/g;
		    }
		    $self->_addInfosUnit($lang, \$lineNb, \@corpus_in_t, {"IF" => $semForm, 
									  "ID" => "S". $SemUnit->getId, 
									  "POSTAG" => "term", 
									  "LM" => $canonical_form, 
									  "SEMTAG" => $semf->first_node_first_semantic_category,
									  "DOCID" => $id,
									  "OFFSET" => $SemUnit->start_token->getFrom,
					 }, $fields);
		} else {
		    $semForm = $SemUnit->getForm;
		    $canonical_form = $self->_getCanonicalForm($SemUnit, $document);
		    if ($sepTermComp ne "") {
			$semForm =~ s/ /$sepTermComp/g;
			$canonical_form =~ s/ /$sepTermComp/g;
		    }
		    $self->_addInfosUnit($lang, \$lineNb, \@corpus_in_t, {"IF" => $semForm, 
									  "ID" => "S". $SemUnit->getId, 
									  "POSTAG" => "term", 
									  "LM" => $canonical_form, 
									  "SEMTAG" => "",
									  "DOCID" => $id,
									  "OFFSET" => $SemUnit->start_token->getFrom,
					 }, $fields);
		}
	    }
	    $token = $SemUnit->end_token;
	    $self->getTimer->endsLapByCategory('semUnit');
	} elsif ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
	    $self->getTimer->startsLapByCategory('word');
	    $word = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];
	    $lemma = $document->getAnnotations->getLemmaLevel->getElementFromIndex("refid_word", $word->getId)->[0];
	    $MS_features = $document->getAnnotations->getMorphosyntacticFeaturesLevel->getElementFromIndex("refid_word", $word->getId)->[0];
	    $wordform = $word->getForm;
	    $wordform =~ s/[\t\n]/ /gos;
	    $wordform =~ s/  +/ /gos;
	    
	    $self->_addInfosUnit($lang, \$lineNb, \@corpus_in_t, {"IF" => $wordform, 
								  "ID" => "W". $word->getId, 
								  "POSTAG" => $MS_features->syntactic_category, 
								  "LM" => $lemma->canonical_form, 
								  "SEMTAG" => "",
								  "DOCID" => $id,
								  "OFFSET" => $word->start_token->getFrom,
				 }, $fields);

	    $token = $word->end_token;
	    
	    $self->getTimer->endsLapByCategory('word');
	} else {
	    $self->getTimer->startsLapByCategory('separator');
	    if ((!($token->isSep)) && (!($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId)))){
		$self->_addInfosUnit($lang, \$lineNb, \@corpus_in_t, {"IF" => $token->getContent, 
								      "ID" => "T". $token->getId, 
								      "POSTAG" => $token->getContent, 
								      "LM" => $token->getContent, 
								      "SEMTAG" => "",
								      "DOCID" => $id,
								      "OFFSET" => $token->getFrom,
				     }, $fields);
	    } elsif (($token->isSep) && ($inSentence) && ($sepUnit eq "")) {
		$self->_addInfosUnit($lang, \$lineNb, \@corpus_in_t, {"TYPE" => "SEP", 
								      "CONTENT" => $token->getContent, 
				     }, $fields);
	    }
	    $self->getTimer->endsLapByCategory('separator');
	}
	$self->getTimer->startsLapByCategory('end sentence');
	if ($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId)) {
	    if ($token->isSymb) {
		if (!($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId))) {
		    $self->_addInfosUnit($lang, \$lineNb, \@corpus_in_t, {"IF" => $token->getContent, 
									  "ID" => "T" . $token->getId,
									  "POSTAG" => "SENT", 
									  "LM" => $token->getContent, 
									  "SEMTAG" => "",
									  "DOCID" => $id,
									  "OFFSET" => $token->getFrom,
					 }, $fields);
		    $self->_printTaggedSentence($fh, \@corpus_in_t, $sepInfo, $sepUnit, $sepSent, $fields);
		    @corpus_in_t = ();
		} else {
		    $self->_addInfosUnit($lang, \$lineNb, \@corpus_in_t, {"IF" => $token->getContent, 
									  "ID" => "T" . $token->getId, 
									  "POSTAG" => "SENT", 
									  "LM" => $token->getContent, 
									  "SEMTAG" => "",
									  "DOCID" => $id,
									  "OFFSET" => $token->getFrom,
					 }, $fields);
		    $self->_printTaggedSentence($fh, \@corpus_in_t, $sepInfo, $sepUnit, $sepSent, $fields);
		    @corpus_in_t = ();
		} 
	    } else {
		$self->_addInfosUnit($lang, \$lineNb, \@corpus_in_t, {"IF" => ".", 
								      "ID" => "T" . $token->getId, 
								      "POSTAG" => "SENT", 
								      "LM" => ".", 
								      "SEMTAG" => "",
								      "DOCID" => $id,
								      "OFFSET" => $token->getFrom,
				     }, $fields);
		$self->_printTaggedSentence($fh, \@corpus_in_t, $sepInfo, $sepUnit, $sepSent, $fields);
		@corpus_in_t = ();
	    }
	    $self->getTimer->endsLapByCategory('end sentence');
	    $inSentence = 0;
	}
	if ($document->getAnnotations->getSectionLevel->existsElementFromIndex("to", $token->getId)) {
	    print $fh $sepSect;
	}
	$token = $token->next;
	$self->getTimer->endsLapByCategory('token2');
    }
    $self->getTimer->endsLapByCategory('token');

    $self->getTimer->endsLapByCategory('document');
    $self->getTimer->_printTimeByCategory(0);
    $self->getTimer->_printTimesBySteps;
    warn "[LOG] done\n";
}

sub _makeTaggedSentences {
    my ($self, $sentences, $fh, $sepInfo, $sepUnit, $sepSent, $sepSect, $sepTermComp, $fields) = @_;

    if (!defined $fh) {
	$fh = *STDOUT;
    }
    # my $printDocId = shift;
    if (!defined $fields) {
	$fields = {"IF" => 1, 
		   "POSTAG" => 2, 
		   "LM" => 3,
		   "ID" => 4, 
		   "DOCID" => 5, 
		   "SEMTAG" => 6, 
#		   "OFFSET" => 7,
	};
    }
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
    my $lineNb = 0;
    my $semf;
    my $wordform;
    my $lang;
    my $terms = [];

    $self->getTimer->startsLap("making tagged sentences");
    warn "[LOG] printing Tagged Sentences\n";

    # warn "open " . $self->_input_filename . "(1)\n";

    # open FILEINPUT, ">:utf8", $self->_input_filename or die "No such file " . $self->_input_filename;

    # warn join('//', keys(%$fields)) . "\n";

    for ($i = 0; $i < scalar(@{$self->_documentSet}); $i++) {
	$self->getTimer->startsLapByCategory('document0');
	$document = $self->_documentSet->[$i];

	$self->_makeOneTaggedSentence($document, $fh, $sepInfo, $sepUnit, $sepSent, $sepSect, $sepTermComp, $fields);
	

	$self->getTimer->endsLapByCategory('document0');
    }
    # close FILEINPUT;
    $self->getTimer->_printTimeByCategory(0);
    $self->getTimer->_printTimesBySteps;
    warn "[LOG] done\n";
}

sub _makeTaggedSentencesRec {
    my ($self, $sentences, $fh, $sepInfo, $sepUnit, $sepSent, $sepSect, $sepTermComp, $fields) = @_;

    if (!defined $fh) {
	$fh = *STDOUT;
    }
    # my $printDocId = shift;
    if (!defined $fields) {
	$fields = {"IF" => 1, 
		   "POSTAG" => 2, 
		   "LM" => 3,
		   "ID" => 4, 
		   "DOCID" => 5, 
		   "SEMTAG" => 6, 
#		   "OFFSET" => 7,
	};
    }
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
    my $lineNb = 0;
    my $semf;
    my $wordform;
    my $lang;
    my $terms = [];

    $self->getTimer->startsLap("making tagged sentences");
    warn "[LOG] printing Tagged Sentences\n";

    # warn "open " . $self->_input_filename . "(1)\n";

    # open FILEINPUT, ">:utf8", $self->_input_filename or die "No such file " . $self->_input_filename;

    # warn join('//', keys(%$fields)) . "\n";

    for ($i = 0; $i < scalar(@{$self->_documentSet}); $i++) {
	$self->getTimer->startsLapByCategory('document0');
	$document = $self->_documentSet->[$i];

	$self->_makeOneTaggedSentenceRec($document, $fh, $sepInfo, $sepUnit, $sepSent, $sepSect, $sepTermComp, $fields);
	

	$self->getTimer->endsLapByCategory('document0');
    }
    # close FILEINPUT;
    $self->getTimer->_printTimeByCategory(0);
    $self->getTimer->_printTimesBySteps;
    warn "[LOG] done\n";
}

sub _makeOneTaggedSentenceRec {
    my ($self, $document, $fh, $sepInfo, $sepUnit, $sepSent, $sepSect, $sepTermComp, $fields) = @_;

#    warn "in _makeOneTaggedSentence $sepInfo, $sepUnit\n";

    if (!defined $fh) {
	$fh = *STDOUT;
    }
    if (!defined $fields) {
	$fields = {"IF" => 1, 
		   "POSTAG" => 2, 
		   "LM" => 3,
		   "ID" => 4, 
		   "DOCID" => 5, 
		   "SEMTAG" => 6, 
		   "OFFSET" => 7,
	};
    }
    my $doc_idx;
    my $token;
    my $word;
    my $lemma;
    my $MS_features;
    my $SemUnit;
    my $semForm;
    my @corpus_in_t;
    my $canonical_form;
    my $taggedSentence;
    my $id;
    my $lineNb = 0;
    my $semf;
    my $wordform;
    my $lang;
    my $terms = [];
    my $inSentence = 0;
    my $endSentToken;

    if (!defined $sepSect) {
	$sepSect = "";
    }

    $self->getTimer->startsLap("making tagged sentences");
    warn "[LOG] printing Tagged Sentences\n";

    $self->getTimer->startsLapByCategory('document');
    $id = $document->getId;
    $lang = $document->getAnnotations->getLanguage;

    $self->getTimer->startsLapByCategory('token');

    $token = $document->getAnnotations->getTokenLevel->getElements->[0];

    $self->getTimer->endsLapByCategory('token');
    while(defined $token) {
	$self->getTimer->startsLapByCategory('token2');
	warn "\n";
	# warn "token: " . $token->getContent . " (" . $token->getId . ")\n";
	if ($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_start_token", $token->getId)) {
	    $inSentence = 1;
#	    warn $document->getAnnotations->getSentenceLevel->getElementFromIndex("refid_start_token", $token->getId) . "\n";
	    $endSentToken = $document->getAnnotations->getSentenceLevel->getElementFromIndex("refid_start_token", $token->getId)->[0]->end_token;
	    @corpus_in_t = ();
	}
	$self->_makeTaggedTokenRec($document, $fh, $token, $inSentence, \@corpus_in_t, \$lineNb, $sepInfo, $sepUnit, $sepSent, $sepSect, $sepTermComp, $fields);
	# # to check $inSentence, @corpus_in_t, $lineNb
	# # to modify
	if ($inSentence) {
	    $token = $endSentToken;
	    $inSentence = 0;
	}
	if ($document->getAnnotations->getSectionLevel->existsElementFromIndex("to", $token->getId)) {
	    print $fh $sepSect;
	}
	$token = $token->next;
	$self->getTimer->endsLapByCategory('token2');
	warn "-----\n";
    }
    $self->getTimer->endsLapByCategory('token');

    $self->getTimer->endsLapByCategory('document');
    $self->getTimer->_printTimeByCategory(0);
    $self->getTimer->_printTimesBySteps;
    warn "[LOG] done\n";
}

sub _makeTaggedTokenRec {
    my ($self, $document, $fh, $curToken, $inSentence, $corpusInT, $lineNb, $sepInfo, $sepUnit, $sepSent, $sepSect, $sepTermComp, $fields) = @_;
    my $terms = [];
    my $token = $curToken;
    my $semForm;
    my $wordform;
    my @corpus_in_t; #  = @$corpusInT;
    my $id;
    my $lang;
    # my $lineNb = $$lineNbRec;
    my $word;
    my $lemma;
    my $SemUnit;
    my $MS_features;
    my $canonical_form;
    my $semf;
    
    $id = $document->getId;
    $lang = $document->getAnnotations->getLanguage;
    if (!defined $token) {
	return;
    }
#    warn "token => " . $token->getContent . " ($inSentence)\n";

#    $terms = $document->getAnnotations->getSemanticUnitLevel->getElementByToken($token);
    $terms = $document->getAnnotations->getSemanticUnitLevel->getElementsByStartToken($token);
    if (scalar(@$terms) > 0) {
	$self->getTimer->startsLapByCategory('semUnit');

	# $self->getTimer->startsLapByCategory('LargerSemUnit');
	# $SemUnit = $self->_getLargerTerm($terms);
	# $self->getTimer->endsLapByCategory('LargerSemUnit');

	foreach $SemUnit (@$terms) {
#	    warn "SemUnit form: " . $SemUnit->getForm . "\n";
	    @corpus_in_t = @$corpusInT;

	    if ($SemUnit->isNamedEntity) {
		$semForm = $SemUnit->getForm;
		$canonical_form = $self->_getCanonicalForm($SemUnit, $document);
		if ($sepTermComp ne "") {
		    $semForm =~ s/ /$sepTermComp/g;
		    $canonical_form =~ s/ /$sepTermComp/g;
		}
		$self->_addInfosUnit($lang, $lineNb, \@corpus_in_t, {"IF" => $semForm, 
								      "ID" => "S". $SemUnit->getId, 
								      "POSTAG" => "named_entity", 
								      "LM" => $canonical_form, 
								      "SEMTAG" => $SemUnit->NEtype,
								      "DOCID" => $id,
								      "OFFSET" => $SemUnit->start_token->getFrom,
				     }, $fields);
	    } elsif ($SemUnit->isTerm) {
		$semf = $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $SemUnit->getId)->[0];
		if (defined $semf) {
		    $semForm = $SemUnit->getForm;
		    $canonical_form = $self->_getCanonicalForm($SemUnit, $document);
		    if ($sepTermComp ne "") {
			$semForm =~ s/ /$sepTermComp/g;
			$canonical_form =~ s/ /$sepTermComp/g;
		    }
		    $self->_addInfosUnit($lang, $lineNb, \@corpus_in_t, {"IF" => $semForm, 
									  "ID" => "S". $SemUnit->getId, 
									  "POSTAG" => "term", 
									  "LM" => $canonical_form, 
									  "SEMTAG" => $semf->first_node_first_semantic_category,
									  "DOCID" => $id,
									  "OFFSET" => $SemUnit->start_token->getFrom,
					 }, $fields);
		} else {
		    $semForm = $SemUnit->getForm;
		    $canonical_form = $self->_getCanonicalForm($SemUnit, $document);
		    if ($sepTermComp ne "") {
			$semForm =~ s/ /$sepTermComp/g;
			$canonical_form =~ s/ /$sepTermComp/g;
		    }
		    $self->_addInfosUnit($lang, $lineNb, \@corpus_in_t, {"IF" => $semForm, 
									  "ID" => "S". $SemUnit->getId, 
									  "POSTAG" => "term", 
									  "LM" => $canonical_form, 
									  "SEMTAG" => "",
									  "DOCID" => $id,
									  "OFFSET" => $SemUnit->start_token->getFrom,
					 }, $fields);
		}
	    }
	    $token = $SemUnit->end_token;
	    $self->_endOfTaggedSentenceRec($document, $fh, $token, $inSentence, \@corpus_in_t, $lineNb, $sepInfo, $sepUnit, $sepSent, $sepSect, $sepTermComp, $fields);
	}
	$self->getTimer->endsLapByCategory('semUnit');
    } elsif ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
	$self->getTimer->startsLapByCategory('word');
	@corpus_in_t = @$corpusInT;
	$word = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];
	$lemma = $document->getAnnotations->getLemmaLevel->getElementFromIndex("refid_word", $word->getId)->[0];
	$MS_features = $document->getAnnotations->getMorphosyntacticFeaturesLevel->getElementFromIndex("refid_word", $word->getId)->[0];
	$wordform = $word->getForm;
	$wordform =~ s/[\t\n]/ /gos;
	$wordform =~ s/  +/ /gos;

	$self->_addInfosUnit($lang, $lineNb, \@corpus_in_t, {"IF" => $wordform, 
							      "ID" => "W". $word->getId, 
							      "POSTAG" => $MS_features->syntactic_category, 
							      "LM" => $lemma->canonical_form, 
							      "SEMTAG" => "",
							      "DOCID" => $id,
							      "OFFSET" => $word->start_token->getFrom,
			     }, $fields);

	$token = $word->end_token;
	$self->getTimer->endsLapByCategory('word');
	$self->_endOfTaggedSentenceRec($document, $fh, $token, $inSentence, \@corpus_in_t, $lineNb, $sepInfo, $sepUnit, $sepSent, $sepSect, $sepTermComp, $fields);
    } else {
	$self->getTimer->startsLapByCategory('separator');
	@corpus_in_t = @$corpusInT;
	if ((!($token->isSep)) && (!($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId)))){
	    $self->_addInfosUnit($lang, $lineNb, \@corpus_in_t, {"IF" => $token->getContent, 
								  "ID" => "T". $token->getId, 
								  "POSTAG" => $token->getContent, 
								  "LM" => $token->getContent, 
								  "SEMTAG" => "",
								  "DOCID" => $id,
								  "OFFSET" => $token->getFrom,
				 }, $fields);
	} elsif (($token->isSep) && ($inSentence) && ($sepUnit eq "")) {
	    $self->_addInfosUnit($lang, $lineNb, \@corpus_in_t, {"TYPE" => "SEP", 
								  "CONTENT" => $token->getContent, 
				 }, $fields);
	}
	$self->getTimer->endsLapByCategory('separator');
	$self->_endOfTaggedSentenceRec($document, $fh, $token, $inSentence, \@corpus_in_t, $lineNb, $sepInfo, $sepUnit, $sepSent, $sepSect, $sepTermComp, $fields);
    }

}


sub _endOfTaggedSentenceRec {
    my ($self, $document, $fh, $curToken, $inSentence, $corpusInT, $lineNb, $sepInfo, $sepUnit, $sepSent, $sepSect, $sepTermComp, $fields) = @_;

    my $token = $curToken;
    my $semForm;
    my $wordform;
    my @corpus_in_t = @$corpusInT;
    my $id;
    my $lang;
    # my $lineNb = $$lineNbRec;
    my $word;
    my $lemma;
    my $SemUnit;
    my $MS_features;
    my $canonical_form;
    my $semf;
    
    $id = $document->getId;
    $lang = $document->getAnnotations->getLanguage;
    if (!defined $token) {
	return;
    }
    # warn "token => " . $token->getContent . " ($inSentence - end)\n";

    $self->getTimer->startsLapByCategory('end sentence');
    if ($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId)) {
	if ($token->isSymb) {
	    if (!($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId))) {
		$self->_addInfosUnit($lang, $lineNb, \@corpus_in_t, {"IF" => $token->getContent, 
								      "ID" => "T" . $token->getId,
								      "POSTAG" => "SENT", 
								      "LM" => $token->getContent, 
								      "SEMTAG" => "",
								      "DOCID" => $id,
								      "OFFSET" => $token->getFrom,
				     }, $fields);
		# $self->_printTaggedSentence($fh, \@corpus_in_t, $sepInfo, $sepUnit, $sepSent, $fields);
	    } else {
		$self->_addInfosUnit($lang, $lineNb, \@corpus_in_t, {"IF" => $token->getContent, 
								      "ID" => "T" . $token->getId, 
								      "POSTAG" => "SENT", 
								      "LM" => $token->getContent, 
								      "SEMTAG" => "",
								      "DOCID" => $id,
								      "OFFSET" => $token->getFrom,
				     }, $fields);
		# $self->_printTaggedSentence($fh, \@corpus_in_t, $sepInfo, $sepUnit, $sepSent, $fields);
	    } 
	} else {
	    $self->_addInfosUnit($lang, $lineNb, \@corpus_in_t, {"IF" => ".", 
								  "ID" => "T" . $token->getId, 
								  "POSTAG" => "SENT", 
								  "LM" => ".", 
								  "SEMTAG" => "",
								  "DOCID" => $id,
								  "OFFSET" => $token->getFrom,
				 }, $fields);
	    # $self->_printTaggedSentence($fh, \@corpus_in_t, $sepInfo, $sepUnit, $sepSent, $fields);
	}
	$self->_printTaggedSentence($fh, \@corpus_in_t, $sepInfo, $sepUnit, $sepSent, $fields);
	if ($document->getAnnotations->getSectionLevel->existsElementFromIndex("to", $token->getId)) {
	    print $fh $sepSect;
	}
	@corpus_in_t = ();
	$inSentence = 0;
	$self->getTimer->endsLapByCategory('end sentence');
    } elsif ($inSentence) {
	$self->_makeTaggedTokenRec($document, $fh, $token->next, $inSentence, \@corpus_in_t, $lineNb, $sepInfo, $sepUnit, $sepSent, $sepSect, $sepTermComp, $fields);
    }

}

sub _makeTaggedSentences2 {
    my ($self, $sentences, $fh, $sepInfo, $sepUnit, $fields) = @_;

    if (!defined $fh) {
	$fh = *STDOUT;
    }
    # my $printDocId = shift;
    if (!defined $fields) {
	$fields = {"IF" => 1, 
		   "POSTAG" => 2, 
		   "LM" => 3,
		   "ID" => 4, 
		   "DOCID" => 5, 
		   "SEMTAG" => 6, 
		   "OFFSET" => 7,
	};
    }
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
    my $lineNb = 0;
    my $semf;
    my $wordform;
    my $lang;
    my $terms = [];

    $self->getTimer->startsLap("making tagged sentences");
    warn "[LOG] printing Tagged Sentences\n";

    # warn "open " . $self->_input_filename . "(1)\n";

    # open FILEINPUT, ">:utf8", $self->_input_filename or die "No such file " . $self->_input_filename;

    for ($i = 0; $i < scalar(@{$self->_documentSet}); $i++) {
	$self->getTimer->startsLapByCategory('document');

	$document = $self->_documentSet->[$i];
	$lang = $document->getAnnotations->getLanguage;

	$self->getTimer->startsLapByCategory('token');

	$token = $document->getAnnotations->getTokenLevel->getElements->[0];

	$self->getTimer->endsLapByCategory('token');
	while(defined ($token)) {
	    $self->getTimer->startsLapByCategory('token2');
	    if ((exists $fields->{"SEMTAG"}) && ($fields->{"SEMTAG"} > 0)) {
		$terms = $document->getAnnotations->getSemanticUnitLevel->getElementByToken($token);
	    } else {
		$terms = [];
	    }

	    if (scalar(@$terms) > 0) {
		$self->getTimer->startsLapByCategory('semUnit');

		$self->getTimer->startsLapByCategory('LargerSemUnit');
		$SemUnit = $self->_getLargerTerm($terms);
		$self->getTimer->endsLapByCategory('LargerSemUnit');

		# warn "OK\n";
		if ($SemUnit->isNamedEntity) {
		    $canonical_form = $self->_getCanonicalForm($SemUnit, $document);
		    # if (!defined $SemUnit->canonical_form) {
		    # 	$canonical_form = "";
		    # } else {
		    # 	$canonical_form = $SemUnit->canonical_form;
		    # }
		    # warn "OK1";
		    $self->_addInfosUnit($lang, \$lineNb, \@corpus_in_t, {"IF" => $SemUnit->getForm, 
									  "ID" => $SemUnit->getId, 
									  "POSTAG" => "named_entity", 
									  "LM" => $canonical_form, 
									  "SEMTAG" => $SemUnit->NEtype,
									  "DOCID" => $i,
									  "OFFSET" => $SemUnit->start_token->getFrom,
					 }, $fields);
		    
		} elsif ($SemUnit->isTerm) {
		    $semf = $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $SemUnit->getId)->[0];
		    # warn "OK2";
		    if (defined $semf) {
		    # warn "OK2b";
			$canonical_form = $self->_getCanonicalForm($SemUnit, $document);
			# if (!defined $SemUnit->canonical_form) {
			#     $canonical_form = "";
			# } else {
			#     $canonical_form = $SemUnit->canonical_form;
			# }
			$self->_addInfosUnit($lang, \$lineNb, \@corpus_in_t, {"IF" => $SemUnit->getForm, 
									      "ID" => $SemUnit->getId, 
									      "POSTAG" => "term", 
									      "LM" => $canonical_form, 
									      "SEMTAG" => $semf->first_node_first_semantic_category,
									      "DOCID" => $i,
									      "OFFSET" => $SemUnit->start_token->getFrom,
					     }, $fields);
		    } else {
		    # warn "OK2c";
			$canonical_form = $self->_getCanonicalForm($SemUnit, $document);
			# if (!defined $SemUnit->canonical_form) {
			#     $canonical_form = "";
			# } else {
			#     $canonical_form = $SemUnit->canonical_form;
			# }
			# warn "OK\n";
			$self->_addInfosUnit($lang, \$lineNb, \@corpus_in_t, {"IF" => $SemUnit->getForm, 
									      "ID" => $SemUnit->getId, 
									      "POSTAG" => "term", 
									      "LM" => $canonical_form, 
									      "SEMTAG" => "",
									      "DOCID" => $i,
									      "OFFSET" => $SemUnit->start_token->getFrom,
					     }, $fields);
		    }
		}
		$token = $SemUnit->end_token;
		$self->getTimer->endsLapByCategory('semUnit');
	    } elsif ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
		$self->getTimer->startsLapByCategory('word');
		$word = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];
		$lemma = $document->getAnnotations->getLemmaLevel->getElementFromIndex("refid_word", $word->getId)->[0];
		$MS_features = $document->getAnnotations->getMorphosyntacticFeaturesLevel->getElementFromIndex("refid_word", $word->getId)->[0];
		$wordform = $word->getForm;
		$wordform =~ s/[\t\n]/ /gos;
		$wordform =~ s/  +/ /gos;
		
		$self->_addInfosUnit($lang, \$lineNb, \@corpus_in_t, {"IF" => $wordform, 
								      "ID" => $word->getId, 
								      "POSTAG" => $MS_features->syntactic_category, 
								      "LM" => $lemma->canonical_form, 
								      "SEMTAG" => "",
								      "DOCID" => $i,
								      "OFFSET" => $word->start_token->getFrom,
					     }, $fields);

		$token = $word->end_token;
		
		$self->getTimer->endsLapByCategory('word');
	    } else {
		$self->getTimer->startsLapByCategory('separator');
		if ((!($token->isSep)) && (!($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId)))){
		    $self->_addInfosUnit($lang, \$lineNb, \@corpus_in_t, {"IF" => $token->getContent, 
									  "ID" => $token->getId, 
									  "POSTAG" => $token->getContent, 
									  "LM" => $token->getContent, 
									  "SEMTAG" => "",
									  "DOCID" => $i,
									  "OFFSET" => $token->getFrom,
					 }, $fields);
		}
		$self->getTimer->endsLapByCategory('separator');
	    }
	    $self->getTimer->startsLapByCategory('end sentence');
	    if ($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId)) {
		if ($token->isSymb) {
		    if (!($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId))) {
			$self->_addInfosUnit($lang, \$lineNb, \@corpus_in_t, {"IF" => $token->getContent, 
									      "ID" => $token->getId,
									      "POSTAG" => "SENT", 
									      "LM" => $token->getContent, 
									      "SEMTAG" => "",
									      "DOCID" => $i,
									      "OFFSET" => $token->getFrom,
					     }, $fields);
			$self->_printTaggedSentence($fh, \@corpus_in_t, $sepInfo, $sepUnit);
			@corpus_in_t = ();
		    } else {
			$self->_addInfosUnit($lang, \$lineNb, \@corpus_in_t, {"IF" => $token->getContent, 
									      "ID" => $token->getId, 
									      "POSTAG" => "SENT", 
									      "LM" => $token->getContent, 
									      "SEMTAG" => "",
									      "DOCID" => $i,
									      "OFFSET" => $token->getFrom,
					     }, $fields);
			$self->_printTaggedSentence($fh, \@corpus_in_t, $sepInfo, $sepUnit);
			@corpus_in_t = ();
		    } 
		} else {
		    # my @tmp = (".", $token->getId, "SENT", ".");
		    # push @corpus_in_t, \@tmp;
		    $self->_addInfosUnit($lang, \$lineNb, \@corpus_in_t, {"IF" => ".", 
									  "ID" => $token->getId, 
									  "POSTAG" => "SENT", 
									  "LM" => ".", 
									  "SEMTAG" => "",
									  "DOCID" => $i,
									  "OFFSET" => $token->getFrom,
					     }, $fields);
		    $self->_printTaggedSentence($fh, \@corpus_in_t, $sepInfo, $sepUnit);
		    @corpus_in_t = ();
		}
		$self->getTimer->endsLapByCategory('end sentence');
	    }
	    $token = $token->next;
	    $self->getTimer->endsLapByCategory('token2');
	}
	$self->getTimer->endsLapByCategory('token');

	$self->getTimer->endsLapByCategory('document');
    }
    # close FILEINPUT;
    $self->getTimer->_printTimeByCategory(0);
    $self->getTimer->_printTimesBySteps;
    warn "[LOG] done\n";
}



sub _addInfosUnit {
    my ($self, $lang, $lineNb, $corpus, $infoUnit, $fields) = @_;

    $self->getTimer->startsLapByCategory('infoUnit');
    my $field;
    my @tabinfos;

    # warn join('//', keys(%$fields)) . "\n";

    $$lineNb++;

    if (exists $infoUnit->{'TYPE'}) {
	push @tabinfos, $infoUnit->{'CONTENT'}
    } else {
	foreach $field (sort {$fields->{$a} <=> $fields->{$b}} keys %$fields) {
	    # warn ">>$field\n";
	    if (($fields->{$field} > 0) && (exists $infoUnit->{$field})) {
		if (ref($infoUnit->{$field}) eq "ARRAY") {
		    push @tabinfos, @{$infoUnit->{$field}};
		} else {
		    # $self->_deft2arff($self->_arff2deft(
		    if ((defined $self->{"JoinComplexTerm"}->{$lang}) && ($self->{"JoinComplexTerm"}->{$lang} == 1)) {
			push @tabinfos, $self->_deft2arff($infoUnit->{$field});
		    } else {
			# warn "\t>> " . $infoUnit->{$field} . "\n";
			push @tabinfos, $infoUnit->{$field};
		    }
		}
	    }
	}
    }
    push @{$corpus}, \@tabinfos;

    $self->getTimer->endsLapByCategory('infoUnit');
}


sub _printTaggedSentence {
    my ($self, $fh, $corpus_in_t, $sepInfo, $sepUnit, $sepSent, $fields) = @_;
    my $encoding = "no";
    my $print = 0;
#    warn "in _printTaggedSentence $sepInfo, $sepUnit\n";

    if (!defined $sepSent) {
	$sepSent = "\n";
    }

    $self->getTimer->startsLapByCategory('print Tagged Sentence');
    my $taggedSentence = "";
    my $word_ref;
    foreach $word_ref (@$corpus_in_t) {
	
	if ((!defined $encoding) || (uc($encoding) eq "UTF-8")) {
	    $print = 0;
 	    $taggedSentence .= Encode::encode("UTF-8", join($sepInfo, @$word_ref)); # . "\n";
	} else {
	    $print = 0;
	    if ((defined $encoding) && (uc($encoding) eq "LATIN1")) {
		$taggedSentence .= Encode::encode("iso-8859-1", join($sepInfo, @$word_ref)); # . "\n";
	    } else {
		# warn "[WRAPPER LOG] Unknown enconding charset\n";
		$taggedSentence .= join($sepInfo, @$word_ref); # . "\n";
	    }
	}
	if (scalar(keys %$fields) > 1) {
	    $taggedSentence .= $sepInfo;
	}
	if ((defined $word_ref->[1]) && ($word_ref->[1] eq "SENT")) {
	    print $fh "$taggedSentence$sepUnit$sepSent";
	    $print = 1;
	    $taggedSentence = "";
	} else {
	    $taggedSentence .= $sepUnit;
	}
    }
    if (!$print) {
	print $fh "$taggedSentence$sepUnit";
    }
    $self->getTimer->endsLapByCategory('print Tagged Sentence');
}

sub addResourceSemRel {
    my ($self, $lang, $lang2, $type) = @_;

    my $terminologyFilename;
    my $DistribThesaurusFilename;
    my $exceptionFilename;

    $self->{"Resources"}->{$lang2}->{$type} = [];

    # warn "==>  $self / $lang / type\n";
    # warn $self->_config->configuration->{'RESOURCE'}->{$lang}->{$type} . "\n";
    if ($type eq "DISTRIBTHESAURUS") {
	if (ref($self->_config->configuration->{'RESOURCE'}->{$lang}->{$type}) eq "ARRAY") {
	    foreach $DistribThesaurusFilename (@{$self->_config->configuration->{'RESOURCE'}->{$lang}->{$type}}) {
		warn "Adding (1) " . $DistribThesaurusFilename . "\n";
		my %DistThesaurus;
		my %DistThesaurusIdx;
		push @{$self->{"Resources"}->{$lang2}->{$type}}, {'filename' => $DistribThesaurusFilename,
								 'type' => $type,
								 'thesaurus' => \%DistThesaurus,
								 'thesaurusIdx' => \%DistThesaurusIdx,
		};
		$self->_loadThesaurus($DistribThesaurusFilename, \%DistThesaurus, \%DistThesaurusIdx);
	    }
	} else {
	    $DistribThesaurusFilename = $self->_config->configuration->{'RESOURCE'}->{$lang}->{$type};
	    warn "Adding (2) " . $DistribThesaurusFilename . "\n";
	    my %DistThesaurus;
	    my %DistThesaurusIdx;
	    push @{$self->{"Resources"}->{$lang2}->{$type}}, {'filename' => $DistribThesaurusFilename,
							     'type' => $type,
							     'thesaurus' => \%DistThesaurus,
							     'thesaurusIdx' => \%DistThesaurusIdx,
	    };
	    $self->_loadThesaurus($DistribThesaurusFilename, \%DistThesaurus, \%DistThesaurusIdx);
	}
	# $self->loadResource($lang, $name, $type);
    }

    if ($type eq "EXCEPTIONLIST") {
	if (ref($self->_config->configuration->{'RESOURCE'}->{$lang}->{$type}) eq "ARRAY") {
	    foreach $exceptionFilename (@{$self->_config->configuration->{'RESOURCE'}->{$lang}->{$type}}) {
		$self->_loadException($exceptionFilename, $lang2, 'exceptions');
	    }
	} else {
	    $self->_loadException($self->_config->configuration->{'RESOURCE'}->{$lang}->{$type}, $lang2, 'exceptions');
	}
    }

    if ($type eq "TERMINOLOGY") {
	if (ref($self->_config->configuration->{'RESOURCE'}->{$lang}->{$type}) eq "ARRAY") {
	    foreach $terminologyFilename (@{$self->_config->configuration->{'RESOURCE'}->{$lang}->{$type}}) {
		warn "Adding (1) " . $terminologyFilename . "\n";
		my %Terminology;
		my %TerminologyIdx;
		push @{$self->{"Resources"}->{$lang2}->{$type}}, {'filename' => $terminologyFilename,
								 'type' => $type,
								 'terminology' => \%Terminology,
								 'terminologyIdx' => \%TerminologyIdx,
		};
		$self->_loadTerminology($terminologyFilename, \%Terminology, \%TerminologyIdx);
	    }
	} else {
	    $terminologyFilename = $self->_config->configuration->{'RESOURCE'}->{$lang}->{$type};
	    warn "Adding (2) " . $terminologyFilename . "\n";
	    my %Terminology;
	    my %TerminologyIdx;
	    push @{$self->{"Resources"}->{$lang2}->{$type}}, {'filename' => $terminologyFilename,
							     'type' => $type,
							     'terminology' => \%Terminology,
							     'terminologyIdx' => \%TerminologyIdx,
	    };
	    $self->_loadTerminology($terminologyFilename, \%Terminology, \%TerminologyIdx);
	}
    }

    if ($type eq "SYNONYMY") {
	if (ref($self->_config->configuration->{'RESOURCE'}->{$lang}->{$type}) eq "ARRAY") {
	    foreach $terminologyFilename (@{$self->_config->configuration->{'RESOURCE'}->{$lang}->{$type}}) {
		warn "Adding (1) " . $terminologyFilename . "\n";
		my %Terminology;
		push @{$self->{"Resources"}->{$lang2}->{$type}}, {'filename' => $terminologyFilename,
								 'type' => $type,
								 'synonymy' => \%Terminology,
								 # 'synonymyIdx' => \%TerminologyIdx,
		};
		$self->_loadSynonymy($terminologyFilename, \%Terminology);
	    }
	} else {
	    $terminologyFilename = $self->_config->configuration->{'RESOURCE'}->{$lang}->{$type};
	    warn "Adding (2) " . $terminologyFilename . "\n";
	    my %Terminology;
	    push @{$self->{"Resources"}->{$lang2}->{$type}}, {'filename' => $terminologyFilename,
							      'type' => $type,
							     'synonymy' => \%Terminology,
							     # 'synonymyIdx' => \%TerminologyIdx,
	    };
	    $self->_loadSynonymy($terminologyFilename, \%Terminology);
	}

    }
    if ($type eq "VDLMDIR") {
	my $vdlmDir = $self->_config->configuration->{'RESOURCE'}->{$lang}->{$type};
	warn "Adding (2) " . $vdlmDir . "\n";
	my %DistThesaurus;
	my %DistThesaurusIdx;
	push @{$self->{"Resources"}->{$lang2}->{$type}}, {'filename' => $vdlmDir,
							  'type' => $type,
							  'thesaurus' => \%DistThesaurus,
							  'thesaurusIdx' => \%DistThesaurusIdx,
	};
	$self->_loadVDLM($vdlmDir, \%DistThesaurus, \%DistThesaurusIdx);
    }
    if ($type eq "VDWDIR") {
	my $vdwDir = $self->_config->configuration->{'RESOURCE'}->{$lang}->{$type};
	warn "Adding (2) " . $vdwDir . "\n";
	my %DistThesaurus;
	my %DistThesaurusIdx;
	push @{$self->{"Resources"}->{$lang2}->{$type}}, {'filename' => $vdwDir,
							  'type' => $type,
							  'thesaurus' => \%DistThesaurus,
							  'thesaurusIdx' => \%DistThesaurusIdx,
	};
	$self->_loadVDLM($vdwDir, \%DistThesaurus, \%DistThesaurusIdx);
    }
    if ($type eq "SEMANTIC_RELATIONS_WITH_TYPE") {
	if (ref($self->_config->configuration->{'RESOURCE'}->{$lang}->{$type}) eq "ARRAY") {
	    foreach $terminologyFilename (@{$self->_config->configuration->{'RESOURCE'}->{$lang}->{$type}}) {
		warn "Adding (1) " . $terminologyFilename . "\n";
		my %Terminology;
		my %TerminologyIdx;
		push @{$self->{"Resources"}->{$lang2}->{$type}}, {'filename' => $terminologyFilename,
								 'type' => $type,
								 'thesaurus' => \%Terminology,
								 'thesaurusIdx' => \%TerminologyIdx,
		};
		$self->_loadSemanticRelationsWithType($terminologyFilename, \%Terminology, \%TerminologyIdx);
	    }
	} else {
	    $terminologyFilename = $self->_config->configuration->{'RESOURCE'}->{$lang}->{$type};
	    warn "Adding (2) " . $terminologyFilename . "\n";
	    my %Terminology;
	    my %TerminologyIdx;
	    push @{$self->{"Resources"}->{$lang2}->{$type}}, {'filename' => $terminologyFilename,
							      'type' => $type,
							     'thesaurus' => \%Terminology,
							     'thesaurusIdx' => \%TerminologyIdx,
	    };
	    $self->_loadSemanticRelationsWithType($terminologyFilename, \%Terminology, \%TerminologyIdx);
	}
    }
    warn "Done\n";
}



sub _loadVDLM {
    my ($self, $vdlmDir, $DistThesaurus, $DistThesaurusIdx) = @_;

    my @wordsInfos;
    my $wordInfo;
    my $word;
    my $dist;
    my $wordDist;

    my $line;
    my %lemmaSet;

    my $postag;
    my $id;
    my $lemma;
    my $rel;
    my $n;
    my $freq;
    my $nbNeighbour;
    my $nbcl;
    my $lid1;
    my $lid2;
    my $n1;
    my $n2;
    my $jacc;
    my $lin;
    my $j1;
    my $j2;

    warn "Load lemma ($vdlmDir/upery-lemme.txt)\n";
    open LEMMA, $vdlmDir . "/upery-lemme.txt" or die "no such file $vdlmDir/upery-lemme.txt\n";
    $line = <LEMMA>;
    while($line = <LEMMA>) {
	chomp $line;
	($id, $postag, $lemma, $rel, $n, $freq, $nbNeighbour, $nbcl) = split /\t/, $line;

	$lemmaSet{$id} = {'lemma' => $lemma,
			  'postag' => $postag,
			  'freq' => $freq,
	};
    }
    close LEMMA;

    warn "load Prox ($vdlmDir/upery-prox.txt)\n";

    open PROX, $vdlmDir . "/upery-prox.txt" or die "no such file $vdlmDir/upery-prox.txt\n";
    $line = <PROX>;
    while($line = <PROX>) {
	chomp $line;

	($lid1, $lid2, $n1, $n2, $a, $jacc, $lin, $j1, $j2) = split /\t/, $line;

	$dist = $jacc;
	@wordsInfos = ();
	push @wordsInfos, [$lemmaSet{$lid2}->{'lemma'}, $lemmaSet{$lid2}->{'postag'}, $dist];

	$self->_addWord2Thesaurus($lemmaSet{$lid1}->{'lemma'}, $lemmaSet{$lid1}->{'postag'}, $lemmaSet{$lid1}->{'postag'} . "|" . $lemmaSet{$lid1}->{'lemma'}, $DistThesaurus, $DistThesaurusIdx, \@wordsInfos);

    }    
    close PROX;
}

sub _addWord2Thesaurus {
    my ($self, $word, $postag, $wordInfo, $DistThesaurus, $DistThesaurusIdx, $wordsInfos) = @_;

    my $wordInfoElt;

    # warn "add $wordInfo ($word)\n";

    if (!exists $DistThesaurusIdx->{$word}) {
	$DistThesaurusIdx->{$word} = [];
    }
    push @{$DistThesaurusIdx->{$word}}, $wordInfo;

    if (!exists $DistThesaurus->{$wordInfo}) {
	$DistThesaurus->{$wordInfo} = { 'word' => $word,
					'postag' => $postag,
					'neighbour' => [],
	};
    }
    
    foreach $wordInfoElt (@$wordsInfos) {
	push @{$DistThesaurus->{$wordInfo}->{'neighbour'}}, {'word' => $wordInfoElt->[0],
							     'postag' => $wordInfoElt->[1],
							     'dist' => $wordInfoElt->[2],
							     'type' => $wordInfoElt->[3],
							     'measure_name' => $wordInfoElt->[4],
	}
    }
}

sub _loadSemanticRelationsWithType {
    my ($self, $semanticRelationsFilename, $semanticRelations, $semanticRelationsIdx) = @_;

    my $line;
    my $T1IF;
    my $T2IF;
    my $T1LM;
    my $T2LM;
    my $postag;
    my $postag2;
    my $type;
    my $weight;
    my $measure_name;
    my @infos;
    my @wordsInfos2;
    my $i;
    my $j;

    # warn "open $semanticRelationsFilename\n";
    open SEMREL, "<:utf8", $semanticRelationsFilename or die "no such file $semanticRelationsFilename\n";

    while($line = <SEMREL>) {
	chomp $line;
	if (($line !~ /^\s*#/) && ($line !~ /^\s*$/) && ($line !~ /^\s*\-/)) {
	    # warn "$line\n";
	    # ($T1IF, $T1LM, $T2IF, $T2LM, $type, $weight, $measure_name) = split / *[\|:] */, $line;
	    @infos = split / *[\|:] */, $line;
	    $postag = substr($infos[1], 0, 1);
	    $postag2 = substr($infos[4], 0, 1);
	    $type = $infos[6];
	    $measure_name = $infos[8];
	    $weight = $infos[7];

	    for($i=0;$i < 3; $i+=2) {
		if ($infos[$i] !~ /^\s*$/) {
		    for($j=3;$j < 6; $j+=2) {
			if ($infos[$j] !~ /^\s*$/) {
			    @wordsInfos2 = ();
			    push @wordsInfos2, [$infos[$j], $postag2, $weight, $type, $measure_name];
			    
			    $self->_addWord2Thesaurus($infos[$i], $postag, "$postag|". $infos[$i], $semanticRelations, $semanticRelationsIdx, \@wordsInfos2);

			    push @wordsInfos2, [$infos[$i], $postag, $weight, $type, $measure_name];
			    
			    $self->_addWord2Thesaurus($infos[$j], $postag2, "$postag2|". $infos[$j], $semanticRelations, $semanticRelationsIdx, \@wordsInfos2);
			    # if (!exists $semanticRelations->{$infos[$i]}) {
			    # 	$semanticRelations->{$infos[$i]} = [];
			    # }
			    # push @{$semanticRelations->{$infos[$i]}}, {'term' => $infos[$j], 'type' => $type, 
			    # 					       'weight'=> $weight, 'measure' => $measure_name};
			    # if (!exists $semanticRelations->{$infos[$j]}) {
			    # 	$semanticRelations->{$infos[$j]} = [];
			    # }
			    # push @{$semanticRelations->{$infos[$j]}}, {'term' => $infos[$i], 'type' => $type . "_inv", 
			    # 					       'weight'=> $weight, 'measure' => $measure_name};
			}
		    }
		}
	    }
	}
    }
    close SEMREL
}


sub _loadSemanticRelationsWithType2 {
    my ($self, $semanticRelationsFilename, $semanticRelations) = @_;

    my $line;
    my $T1IF;
    my $T2IF;
    my $T1LM;
    my $T2LM;
    my $type;
    my $weight;
    my $measure_name;
    my @infos;
    my $i;
    my $j;

    # warn "open $semanticRelationsFilename\n";
    open SEMREL, "<:utf8", $semanticRelationsFilename or die "no such file $semanticRelationsFilename\n";

    while($line = <SEMREL>) {
	chomp $line;
	if (($line !~ /^\s*#/) && ($line !~ /^\s*$/) && ($line !~ /^\s*\-/)) {
	    # warn "$line\n";
	    # ($T1IF, $T1LM, $T2IF, $T2LM, $type, $weight, $measure_name) = split / *[\|:] */, $line;
	    @infos = split / *[\|:] */, $line;

	    for($i=0;$i < 2; $i++) {
		if ($infos[$i] !~ /^\s*$/) {
		    for($j=2;$j < 4; $j++) {
			if ($infos[$j] !~ /^\s*$/) {
			    if (!exists $semanticRelations->{$infos[$i]}) {
				$semanticRelations->{$infos[$i]} = [];
			    }
			    push @{$semanticRelations->{$infos[$i]}}, {'term' => $infos[$j], 'type' => $type, 
								       'weight'=> $weight, 'measure' => $measure_name};
			    if (!exists $semanticRelations->{$infos[$j]}) {
				$semanticRelations->{$infos[$j]} = [];
			    }
			    push @{$semanticRelations->{$infos[$j]}}, {'term' => $infos[$i], 'type' => $type . "_inv", 
								       'weight'=> $weight, 'measure' => $measure_name};
			}
		    }
		}
	    }
	}
    }
    close SEMREL
}



sub _loadSynonymy {
    my ($self, $synonymyFilename, $synonymy) = @_;

    my $line;
    my $T1;
    my $T2;

    # warn "open $synonymyFilename\n";
    open SYNO, "<:utf8", $synonymyFilename or die "no such file $synonymyFilename\n";

    while($line = <SYNO>) {
	chomp $line;
	if (($line !~ /^\s*#/) && ($line !~ /^\s*$/) && ($line !~ /^\s*\-/)) {
	    # warn "$line\n";
	    $line =~ s/__...=?//go;
	    ($T1, $T2) = split / *[\|:] */, $line;
	    if (!exists $synonymy->{$T1}) {
		$synonymy->{$T1} = [];
	    }
	    push @{$synonymy->{$T1}}, $T2;
	    if (!exists $synonymy->{$T2}) {
		$synonymy->{$T2} = [];
	    }
	    push @{$synonymy->{$T2}}, $T1;
	}
    }
    close SYNO
}

sub _loadException {
    my ($self, $resource, $lang, $type) = @_;

    return($self->_loadWordList($resource, $lang, $type));
}

sub _loadWordList {
    my ($self, $resource, $lang, $type) = @_;
    my $line;
    my $filename;

    if (defined $resource) {
	$self->{$type}->{$lang} = {};
	if (ref($resource) eq "ARRAY") {
	    foreach $filename (@$resource) {
		open EXCEPTION, "<:utf8", $filename or die "no such file $filename\n";
		warn "read $filename\n";
		while($line = <EXCEPTION>) {
		    chomp $line;
		    if (($line !~ /^\s*$/o) && ($line !~ /^\s*\#$/o)){
			$self->{$type}->{$lang}->{$line}++;
		    }
		}
		close EXCEPTION;
	    }
	} else {
	    $filename = $resource;
	    open EXCEPTION, "<:utf8", $filename or die "no such file $filename\n";
	    warn "read $filename\n";
	    while($line = <EXCEPTION>) {
		chomp $line;
		if (($line !~ /^\s*$/o) && ($line !~ /^\s*\#$/o)){
		    $self->{$type}->{$lang}->{$line}++;
		}
	    }
	    close EXCEPTION;
	}
    }
}

sub _loadCorrespondanceList {
    my ($self, $resource, $lang, $type) = @_;
    my $line;
    my $filename;
    my $val1;
    my $val2;

    if (defined $resource) {
	$self->{$type}->{$lang} = {};
	if (ref($resource) eq "ARRAY") {
	    foreach $filename (@$resource) {
		open EXCEPTION, "<:utf8", $filename or die "no such file $filename\n";
		while($line = <EXCEPTION>) {
		    chomp $line;
		    if (($line !~ /^\s*$/o) && ($line !~ /^\s*\#$/o)){
			($val1, $val2) = split /\s*:\s*/, $line;
			$self->{$type}->{$lang}->{$val1} = $val2;
		    }
		}
		close EXCEPTION;
	    }
	} else {
	    $filename = $resource;
	    open EXCEPTION, "<:utf8", $filename or die "no such file $filename\n";
	    while($line = <EXCEPTION>) {
		chomp $line;
		if (($line !~ /^\s*$/o) && ($line !~ /^\s*\#$/o)){
		    ($val1, $val2) = split /\s*:\s*/, $line;
		    warn "$val1\n";
		    $self->{$type}->{$lang}->{$val1} = $val2;
		}
	    }
	    close EXCEPTION;
	}
    }
}

sub _loadTerminology {
    my ($self, $terminologyFilename, $terminology, $terminologyIdx) = @_;
    my $line;
    my @termInfos;
    my @semCats;
    my $semCat;

    
    open TERMINO, "<:utf8", $terminologyFilename or die "no such file $terminologyFilename\n";
    while($line = <TERMINO>) {
	chomp $line;
	if (($line !~ /^\s*#/) && ($line !~ /^\s*$/)) {
	    @termInfos = split / ?[:|] ?/, $line;

	    if ((defined $termInfos[2]) && ($termInfos[2] ne "")) {
		@semCats = split /\//, $termInfos[2];
		# if ($terminologyIdx->{$termInfos[0]}) {
		#     $terminologyIdx->{$termInfos[0]} = [];
		# }
		# push @{$terminologyIdx->{$termInfos[0]}}, $termInfos[2];
		$terminologyIdx->{$termInfos[0]}->{lc($termInfos[2])}++;
		$terminology->{lc($termInfos[2])}->{$termInfos[0]}++;

		for $semCat (@semCats) {
		    $terminologyIdx->{$termInfos[0]}->{lc($semCat)}++;
		    $terminology->{lc($semCat)}->{$termInfos[0]}++;
		}
	    } else {
		warn "Empty semantic category\n";
	    }
	}
    }
    close TERMINO;
}

sub _selectTermInfos {
    my ($self, $termToSelect, $terminology, $terminologyIdx, $selectedTermsInTerminology) = @_;

    my $semCat;

    %$selectedTermsInTerminology = ();
    if (exists $terminologyIdx->{$termToSelect}) {
	foreach $semCat (keys %{$terminologyIdx->{$termToSelect}}) {
	    $selectedTermsInTerminology->{$semCat} = $terminology->{$semCat};
	}
    }
}

sub _selectSynonyms {
    my ($self, $termToSelect, $synonymy, $selectedSynonyms) = @_;

    my $synonym;

    @$selectedSynonyms = ();
    if (exists $synonymy->{$termToSelect}) {
	# warn ".. found\n";
#	foreach $synonym (@{$synonymy->{$termToSelect}}) {
	push @$selectedSynonyms, @{$synonymy->{$termToSelect}};
#	}
    }
}



sub _loadThesaurus {
    my ($self, $freDistThesaurusFilename, $freDistThesaurus, $freDistThesaurusIdx) = @_;

    my @wordsInfos;
    my @wordsInfos2;
    my $wordInfo;
    my $wordInfoElt;
    my $postag;
    my $word;
    my $dist;
    my $postag2;
    my $word2;
    my $dist2;
    my $wordDist;
    my $line;

    open THESAURUS, '<:utf8', $freDistThesaurusFilename or die "no such file $freDistThesaurusFilename\n";

    while($line = <THESAURUS>) {
	chomp $line;

	@wordsInfos = split /\t/, $line;

	$wordInfo = shift @wordsInfos;
	($postag, $word) = split /\|/, $wordInfo;

	@wordsInfos2 = ();
	foreach $wordInfoElt (@wordsInfos) {
	    ($postag2, $wordDist) = split /\|/, $wordInfoElt;
	    ($word2, $dist2) = split /:/, $wordDist; # /
	    # push @{$freDistThesaurus->{$wordInfo}->{'neighbour'}}, {'word' => $word,
	    # 							    'postag' => $postag,
	    # 							    'dist' => $dist,
	    # }
	    push @wordsInfos2, [$word2, $postag2, $dist2];
	}

	$self->_addWord2Thesaurus($word, $postag, $wordInfo, $freDistThesaurus, $freDistThesaurusIdx, \@wordsInfos2);
    }
    close THESAURUS;
}

sub _selectWordInfos {
    my ($self, $wordToSelect, $withPOStag, $freDistThesaurus, $freDistThesaurusIdx, $selectedWordsInThesaurus) = @_;

    my $wordInfo;

    %$selectedWordsInThesaurus = ();
    if (!$withPOStag) {
	if (exists $freDistThesaurusIdx->{$wordToSelect}) {
	    foreach $wordInfo (@{$freDistThesaurusIdx->{$wordToSelect}}) {
		$selectedWordsInThesaurus->{$wordInfo} = $freDistThesaurus->{$wordInfo};
	    }
	}
    } else {
	# warn "$wordToSelect\n";
	if (exists $freDistThesaurus->{$wordToSelect}) {
	    $selectedWordsInThesaurus->{$wordToSelect} = $freDistThesaurus->{$wordToSelect};
	}
    }
}


sub _mergeTerms {
    my ($self, $document) = @_;

    my $term;
    my $token;
    my $semf;
    my $tmpSemf;
    my $nextSemf;

    my $tmpTerm;
    my $end_form;
    my @endTokens;
    my $type;
    my @tmpTermList;
    my %tmpTermListH;
    my $lang = $document->getAnnotations->getLanguage;

    my %medsep = ("," => 1);

    my @termlist = @{$document->getAnnotations->getSemanticUnitLevel->getElements};

    warn "[LOG] Merge Terms\n";

    foreach $term (@termlist) {
	# warn "termForm: " . $term->getForm . "\n";
 	if ($document->getAnnotations->getSemanticUnitLevel->existsElement($term->getId)) {
	    # nested Term ?
	    $type = $term->type;
	    $semf = "";
	    # test exists semantic tag ?
	    if (($term->isTerm) && 
		($document->getAnnotations->getSemanticFeaturesLevel->existsElementFromIndex("refid_semantic_unit", $term->getId)) && 
		(defined($document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $term->getId)->[0]))) {
		if (!defined($document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $term->getId)->[0])) {
		    warn $term->getForm . ": no defined semantic features\n";
		}
		$semf = $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $term->getId)->[0]->first_node_first_semantic_category;
	    } elsif ($term->isNamedEntity) {
		$semf = $term->NEtype;
	    } else {
		$semf = "NA";
	    }
	    my $termToken = $term->start_token;
	    @tmpTermList = ();
	    %tmpTermListH = ();
	    
	    foreach $tmpTerm (@{$document->getAnnotations->getSemanticUnitLevel->getElementByOffset($termToken->getFrom)}) {
		if ((!$tmpTerm->equals($term)) && ($tmpTerm->type eq $term->type)  && 
		    ((($type eq "term") && (($semf eq "NA") || 
					    ($tmpTerm->SemanticFeatureFCEquals($document, $term->getSemanticFeatureFC($document))))) || 
		     (($type eq "named_entity") && ($tmpTerm->NEtype eq $term->NEtype)))
		    ){
		    $tmpTermListH{$tmpTerm->getId} = $tmpTerm;
		}
	    }
	    while(!$termToken->equals($term->end_token)) {
		$termToken = $termToken->next;
		foreach $tmpTerm (@{$document->getAnnotations->getSemanticUnitLevel->getElementByOffset($termToken->getFrom)}) {
		    if ((!$tmpTerm->equals($term)) && ($tmpTerm->type eq $term->type) && 
			((($type eq "term") && (($semf eq "NA") || 
						($tmpTerm->SemanticFeatureFCEquals($document, $term->getSemanticFeatureFC($document))))) || 
			 (($type eq "named_entity") && ($tmpTerm->NEtype eq $term->NEtype)))
			) {
			$tmpTermListH{$tmpTerm->getId} = $tmpTerm;
		    }
		}
	    }	
	    foreach $tmpTerm (values %tmpTermListH) {
		# warn "==> " . $tmpTerm->getForm . "(" . $tmpTerm->getId . " -- $type / " . $tmpTerm->type . ")\n";
		if (($document->getAnnotations->getSemanticUnitLevel->existsElement($term->getId)) &&
		    ($document->getAnnotations->getSemanticUnitLevel->existsElement($tmpTerm->getId)) &&
		    ($tmpTerm->type eq $type)
		    ) {
		    if (defined $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $tmpTerm->getId)->[0]) {
			$tmpSemf = $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $tmpTerm->getId)->[0]->first_node_first_semantic_category;
		    } else {
			$tmpSemf = "";
		    }
		    # warn "    $semf / $tmpSemf\n";
		    if ($term->start_token->getFrom <= $tmpTerm->start_token->getFrom) {
			if ($tmpTerm->end_token->getTo <= $term->end_token->getTo) {
			    if ($tmpSemf eq $semf) { # TO change to compare categories
				if ((defined $tmpTerm->canonical_form) && (!defined ($term->canonical_form))) {
				    $term->canonical_form($tmpTerm->canonical_form);
				}
				$document->getAnnotations->delSemanticUnit($tmpTerm);
#				    $document->getAnnotations->delSemanticFeaturesFromTermId($tmpTerm);
			    }
			} else {
			    # Merge Term if same type
			    if ($tmpSemf eq $semf) { # TO change to compare categories
				$end_form = undef;
				@endTokens = ();
				# expansion
				if ($self->{"EXPAND_TERMS"}->{$lang} == 1) {
				    if (index($tmpTerm->getForm, "(") > -1) {
					$self->_getEndForm($tmpTerm, $document, \$end_form, \@endTokens);
				    }
				}

				push @termlist, $self->_semanticUnitMerging($document, $term, $tmpTerm, undef, undef, $end_form, \@endTokens);
			    }
			}
		    } else {
			if (!defined $tmpSemf) {
			    warn "tmpSemf not defined for " . $term->getForm . " / " . $tmpTerm->getForm . "\n";
			}
# 				if ($tmpSemf eq $semf) { # TO change to compare categories
#  				    $document->getAnnotations->delSemanticUnit($tmpTerm);
# #				    $document->getAnnotations->delSemanticFeaturesFromTermId($tmpTerm);
# 				}
			if ($tmpTerm->end_token->getTo <= $term->end_token->getTo) {
			    # Merge Term if same type
			    if ($tmpSemf eq $semf) { # TO change to compare categories
				$end_form = undef;
				@endTokens = ();
				# expansion
				if ($self->{"EXPAND_TERMS"}->{$lang} == 1) {
				    if (index($term->getForm, "(") > -1) {
					$self->_getEndForm($term, $document, \$end_form, \@endTokens);
				    }
				}
				push @termlist, $self->_semanticUnitMerging($document, $tmpTerm, $term, undef, undef, $end_form, \@endTokens);
			    }
			} else {
			    if ($tmpSemf eq $semf) { # TO change to compare categories
				if ((!defined $tmpTerm->canonical_form) && (defined ($term->canonical_form))) {
				    $tmpTerm->canonical_form($term->canonical_form);
				}
				$document->getAnnotations->delSemanticUnit($term);
#				    $document->getAnnotations->delSemanticFeaturesFromTermId($term);
			    }
			}
			
		    }
		}
	    }

	    if ($self->{"EXPAND_TERMS"}->{$lang} == 1) {

		if ($document->getAnnotations->getSemanticUnitLevel->existsElement($term->getId)) {
		    # expansion
		    # following NEs with or without separators
		    my @sepTokens;
		    my $sep_form;
		    $token = $term->end_token;
		    while ((defined $token->next) &&
			   (($token->next->isSep) || ($token->next->isSymb)) &&
			   (!exists($medsep{$token->next->getContent})) &&
			   (!$document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId))
			){
			$token = $token->next;
			push @sepTokens, $token;
			$sep_form .= $token->getContent;
		    }
		    # expansion
		    if ((((defined $sep_form) && (index ($sep_form , "(") > -1 )) || (index ($term->getForm , "(") > -1 ))
			&& (index ($term->getForm , ")") == -1 )) {
			$end_form = "";
			@endTokens = ();

			# expansion
			while ((defined $token->next) &&
			       (index($token->next->getContent, ")") == -1) &&
			       (!$document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId))
			    ) {
			    $token = $token->next;
			    push @endTokens, $token;
			    $end_form .= $token->getContent;
			}
			# expansion
			if ((index($token->next->getContent, ")") > -1)) {
			    $token = $token->next;
			    push @endTokens, $token;
			    $end_form .= $token->getContent;
			    
			} else {
			    $end_form = "";
			}
			if ($end_form eq "") {
			    $end_form = undef;
			}

			if (defined $end_form) {
			    push @termlist,  $self->_semanticUnitMerging($document, $term, undef, $sep_form, \@sepTokens, $end_form, \@endTokens);
			}
		    } else {
			if (!$document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId)) {
			    foreach my $nextTerm (@{$document->getAnnotations->getSemanticUnitLevel->getElementByOffset($token->next->getFrom)}) {
				if (($nextTerm->type eq $type) && ($document->getAnnotations->getSemanticUnitLevel->existsElement($term->getId))) {
				    if (defined $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $nextTerm->getId)->[0]) {
					$nextSemf = $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $nextTerm->getId)->[0]->first_node_first_semantic_category;
				    } else {
					$nextSemf = "";
				    }
				    # expansion
				    if (($nextTerm->start_token->getTo >= $term->start_token->getFrom) && (
					    (!defined $semf) || (!defined $nextSemf) || ($nextSemf eq $semf))) {
					# TODO  if the sepform contains (, going to )
					$end_form = undef;
					@endTokens = ();
					if ((defined $sep_form) && (index ($sep_form , "(") > -1 ) || (index ($term->getForm , "(") > -1 ) || (index ($nextTerm->getForm , "(") > -1 )) {
					    $self->_getEndForm($nextTerm, $document, \$end_form, \@endTokens);

					}
					push @termlist,  $self->_semanticUnitMerging($document, $term, $nextTerm, $sep_form, \@sepTokens, $end_form, \@endTokens);
				    }
				}
			    }
			}
		    }
		}
	    }
	}
    }
}

sub _printVocabulary {
    my ($self) = @_;

    my $word;
    my $lemma;
    my $document;

    my %vocabulary;

    foreach $document (@{$self->_documentSet}) {
	foreach $word (@{$document->getAnnotations->getWordLevel->getElements}) {
	    $vocabulary{$word->getForm}++;
	    $vocabulary{$word->getLemma($document)->canonical_form}++;
	}
	print lc(join("\n", keys(%vocabulary))) . "\n";
    }
}

sub _printVocabulary_FF {
    my ($self) = @_;

    my $word;
    my $lemma;
    my $document;

    my %vocabulary;

    foreach $document (@{$self->_documentSet}) {
	foreach $word (@{$document->getAnnotations->getWordLevel->getElements}) {
	    $vocabulary{$word->getForm}++;
	}
	print join("\n", keys(%vocabulary)) . "\n";
    }
}

sub _printVocabulary_LM {
    my ($self) = @_;

    my $word;
    my $lemma;
    my $document;

    my %vocabulary;

    foreach $document (@{$self->_documentSet}) {
	foreach $word (@{$document->getAnnotations->getWordLevel->getElements}) {
	    $vocabulary{$word->getLemma($document)->canonical_form}++;
	}
	print join("\n", keys(%vocabulary)) . "\n";
    }
}

sub _printTagSet {
    my ($self) = @_;

    my $word;
    my $lemma;
    my $document;

    my %Tagset;

    foreach $document (@{$self->_documentSet}) {
	foreach $word (@{$document->getAnnotations->getWordLevel->getElements}) {
	    $Tagset{$word->getMorphoSyntacticFeatures($document)->syntactic_category}++;
	}
	print join("\n", keys(%Tagset)) . "\n";
    }
}

sub _convert2ascii {
    my($self, $str, $sep) = @_;

    if (!defined $sep) {
	$sep = "_";
    }

    $str =~ tr/è/e/;
    $str =~ tr/ÁÂÀÅÃÄÇÉÊÈËÍÎÌÏÑÓÔÓØÕÖÚÛÙÜÝáâàåãäçéêèëíîìïñóôòøõöúûùüý/AAAAAACEEEEIIIINOOOOOOUUUUYaaaaaaceeeeiiiinoooooouuuuy/;

    $str =~ s/æ/ae/g;
    $str =~ s/Æ/AE/g;
    $str =~ s/œ/oe/g;
    $str =~ s/Œ/OE/g;

    return(lc($str));
}


sub _convertHTML {
    my($self, $str, $sep) = @_;

    if (!defined $sep) {
	$sep = "_";
    }

    $str =~ s/&amp;/\&/go;
    $str =~ s/&quot;/\"/og;
    $str =~ s/&apos;/\'/og;
    $str =~ s/&lt;/</og;
    $str =~ s/&gt;/>/og;

    return(lc($str));
}

sub _convertChar {
    my($self, $str, $sep) = @_;

    if (!defined $sep) {
	$sep = "_";
    }

    $str =~ s/\//$sep/g;
    $str =~ s/ +/$sep/g;
    $str =~ s/:/$sep/g;
    $str =~ s/!/$sep/g;
    $str =~ s/\?/$sep/g;
    $str =~ s/\&/$sep/g;
    $str =~ s/\'/$sep/g;
    $str =~ s/$sep+/$sep/g;
#    $str =~ s/\.+$//g;
    return(lc($str));
}

sub findNamedEntityAfter {
    my ($self, $semantic_unit, $categories, $semanticFeatures, $document, $windowLimits, $wordLimit) = @_;

    my $token;
    my $term;
    my @relatedNE;

    my %words;
    my $reachedLimit = 0;

    $token = $semantic_unit->end_token;
    $token = $token->next;

    # warn "Limit: " . $windowLimits->{'after'} . "\n";

     while((defined $token) && ($token->getFrom <= $windowLimits->{'after'}) && ($reachedLimit == 0) && ((!defined $wordLimit) || (scalar(keys %words) < $wordLimit))) {
	 # warn ">token: " . $token->getContent . " (" . $token->getFrom . ")\n";
	my @words = @{$document->getAnnotations->getWordLevel->getElementByToken($token)}; 
	if (scalar(@words) > 0) {
	    $words{$words[0]->getId}++;
	}
	 foreach $term (@{$document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)}) {
		# warn "\t=> " . $term->getForm . "?\n";
	     if ($term->isNamedEntity) {
		    # warn "named entity: " . $term->getForm . "\n";
		 if (exists $categories->{$term->NEtype}) {
			# warn "===\n";
		     push @relatedNE, $term;
		     $token = $term->end_token;
		 }
	     } elsif ((!$term->equals($semantic_unit)) && ($term->isTerm)#  && 
		 # ($document->getAnnotations->getSemanticUnitLevel->existsElement($term->getId))
		 ) {
		 if ((defined $semanticFeatures) && (scalar(keys %$semanticFeatures) > 0)) {
		     if ($document->getAnnotations->getSemanticFeaturesLevel->existsElementFromIndex("refid_semantic_unit", $term->getId)) {
			 my $semf = $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $term->getId)->[0];
			 if ((defined $semf) && ($semanticFeatures->{$semf->first_node_first_semantic_category})) {
			     $reachedLimit = 1;
			 }
		     }
		 } else {
		     $reachedLimit = 1;
		 }
	     }
	 }
	if ($token->isNum) {
	    if (!$document->getAnnotations->getSemanticUnitLevel->existsElementFromIndex("list_refid_token",$token->getId)) {
		warn "add numeric as quantities\n";
		my $namedEntity = Lingua::Ogmios::Annotations::SemanticUnit->newNamedEntity(
		    {'form' => $token->getContent,
		     'named_entity_type' => 'numeric_internal',
		     'list_refid_token' => [$token],
		     'canonical_form' => $token->getContent,
		    });
		$document->getAnnotations->addSemanticUnit($namedEntity);
		push @relatedNE, $namedEntity;
	    }
	}
	 $token = $token->next;
	 # warn ">next token: " . $token->getContent . " (" . $token->getFrom . ") ($reachedLimit)\n";
    };
    # warn "OUT\n";
    return(\@relatedNE);
}


sub findNamedEntityBefore {
    my ($self, $semantic_unit, $categories, $semanticFeatures, $document, $windowLimits, $wordLimit) = @_;

    my $token;
    my $term;
    my @relatedNE;

    my $category = "modeadm";
    my %words;
    my $reachedLimit = 0;

    $token = $semantic_unit->start_token;
    $token = $token->previous;
    %words = ();

    # warn "Limit: " . $windowLimits->{'before'} . "\n";

    # warn "Semantic_unit: " . $semantic_unit->getForm . "\n";
     while((defined $token) && ($token->getFrom >= $windowLimits->{'before'}) && ($reachedLimit == 0) && ((!defined $wordLimit) || (scalar(keys %words) < $wordLimit))) {
	 # warn ">token: " . $token->getContent . " (" . $token->getFrom . ")\n";
	my @words = @{$document->getAnnotations->getWordLevel->getElementByToken($token)}; 
	if (scalar(@words) > 0) {
	    $words{$words[0]->getId}++;
	}
	# if (!$reachedLimit) {
	foreach $term (@{$document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)}) {
	    # warn "\t=> " . $term->getForm . "?\n";
	    if ($term->isNamedEntity) {
		# warn "named entity: " . $term->getForm . "\n";
		if ((!defined $categories) || (exists $categories->{$term->NEtype})) {
		    # warn "===\n";
		    push @relatedNE, $term;
		    $token = $term->start_token;
		}
	    } elsif ((!$term->equals($semantic_unit)) && ($term->isTerm)) {
		if ((defined $semanticFeatures) && (scalar(keys %$semanticFeatures) > 0)) {
		    if ($document->getAnnotations->getSemanticFeaturesLevel->existsElementFromIndex("refid_semantic_unit", $term->getId)) {
			my $semf = $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $term->getId)->[0];
			if ((defined $semf) && ($semanticFeatures->{$semf->first_node_first_semantic_category})) {
			    $reachedLimit = 1;
			}
		    }
		} else {
		    $reachedLimit = 1;
		}
	    }
	    # }
	}
	if ($token->isNum) {
	    if (!$document->getAnnotations->getSemanticUnitLevel->existsElementFromIndex("list_refid_token",$token->getId)) {
		warn "add numeric as quantities\n";
		my $namedEntity = Lingua::Ogmios::Annotations::SemanticUnit->newNamedEntity(
		    {'form' => $token->getContent,
		     'named_entity_type' => 'numeric_internal',
		     'list_refid_token' => [$token],
		     'canonical_form' => $token->getContent,
		    });
		$document->getAnnotations->addSemanticUnit($namedEntity);
		push @relatedNE, $namedEntity;
	    }
	}
 	$token = $token->previous;
	 # warn ">prevtoken: " . $token->getContent . " (" . $token->getFrom . ") ($reachedLimit)\n";
    };
    # warn "OUT\n";
    return(\@relatedNE);
}

sub getWindowLimits {
    my ($self, $semantic_unit, $document, $semanticFeatures, $goThroughtList, $additionalLimits) = @_;

    my $limitBeforeOffset;
    my $limitAfterOffset;

    my $token;
    # my $limitLine;

    # my $line = $termIdx->{$semantic_unit->type . $semantic_unit->getId}->{info_e}->[0];
    # my $E_char = $termIdx->{$semantic_unit->type . $semantic_unit->getId}->{info_e}->[1];

    # # warn "\nSearch Window limits for " . $semantic_unit->getForm . " from $line / $E_char (" . $semantic_unit->start_token->getFrom . ")\n";

    # # comput before limit
    # my $shift = 0;
    # do {
    # 	$limitLine = $line - 2 - $shift;
    # 	if ($limitLine < 1) {
    # 	    $limitLine = 1;
    # 	}
    # 	$shift++;
    # } while(!exists($documentIndex->{"I2O"}->{"$limitLine:0"}));
    # $limitBeforeOffset = $documentIndex->{"I2O"}->{"$limitLine:0"}->[2];
    

    # comput after limit
    # $limitLine = $line + 2;
    # if ($limitLine > $documentIndex->{"I2OMaxLine"}) {
    # 	$limitLine = $documentIndex->{"I2OMaxLine"};
    # }
    # $limitLine++; 
    # $limitAfterOffset = $documentIndex->{"I2O"}->{"$limitLine:0"}->[2];

    my $regex;
    my $continue = 1;
    my $nexttoken;
    my $semf;
    my $term;
    my $word;

    my $lang = $document->getAnnotations->getLanguage;
    $token = $semantic_unit->end_token;
    # warn $semantic_unit->getId . "\n";
    # warn $semantic_unit->getForm . "\n";
    do {
	if ((!$document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId)) && 
	    (!$document->getAnnotations->getSectionLevel->existsElementFromIndex("to", $token->getId)) && 
	    ((!defined $additionalLimits) || (!defined $additionalLimits->{'afterLimit'}) || ($token->getFrom < $additionalLimits->{'afterLimit'}))) {

	    $token = $token->next;
	    # warn $token->getContent . "\n";
	    foreach $term (@{$document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)}) {
		if ($term->isTerm) {
		    $semf = $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $term->getId)->[0];
		    if ((defined $semf) && (exists $semanticFeatures->{$semf->first_node_first_semantic_category})) {
			$continue = 0;
			$token = $token->previous;
			last;
		    }
		}
	    }
	    if ($continue) {
		foreach $word (@{$document->getAnnotations->getWordLevel->getElementByToken($token)}) {
		    if (exists($self->{'lexicon_limit_after'}->{$lang}->{$word->getForm})) {
			# warn "find and\n";
			$continue = 0;
			$token = $word->start_token->previous;
			last;
		    }
		}
	    }
	    # punctuation ?
            # Taking into account list ?
	    $regex = $additionalLimits->{'afterRegex'};
	    # warn "regex: $regex\n";
	    if ((defined $regex) && ($token->getContent =~ /$regex/)) {
		$continue = 0; #by default
		
		if ($goThroughtList > 0) {
		    # warn "this part of the code has not been checked\n";
		    $nexttoken = $token;
		    $token = $token->previous;
		    do {
			$nexttoken = $nexttoken->next;
		    } while(($nexttoken->isSep) &&
			    (!$document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $nexttoken->getId)) && 
			    (!$document->getAnnotations->getSectionLevel->existsElementFromIndex("to", $nexttoken->getId)) && 
			    ((!defined $additionalLimits) || ($nexttoken->getFrom < $additionalLimits->{'afterLimit'}))
			);
		    
		    foreach my $term (@{$document->getAnnotations->getSemanticUnitLevel->getElementByToken($nexttoken)}) {
			if ($term->isNamedEntity) {
			    # warn "find a named Entity: " . $document->getAnnotations->getSemanticUnitLevel->getElementByToken($nexttoken)->[0]->getForm
			    # . "\n";
			    $continue = 1;
			    $token = $term->end_token;
			    last;
			}
		    }	
		    if (!$continue) {
			foreach $word (@{$document->getAnnotations->getWordLevel->getElementByToken($token)}) {
			    if ($word->getForm eq "and") {
				# warn "find and\n";
				$continue = 1;
				$token = $word->end_token;
				last
			    }
			}
		    }
		}
	    }
	    # warn "continue : $continue\n";
	}
    } while ((!$document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId)) && 
	     (!$document->getAnnotations->getSectionLevel->existsElementFromIndex("to", $token->getId)) && 
	     ((!defined $additionalLimits) || (!defined $additionalLimits->{'afterLimit'}) || ($token->getFrom < $additionalLimits->{'afterLimit'})) &&
	     ($continue)
	);

    $limitAfterOffset = $token->getFrom;

    # warn "Limit\n";
    # warn "\tAfter: " . $token->getContent . " (" . $token->getId . ")\n";


    # warn "search restricted window before\n";
    $token = $semantic_unit->start_token;
    $continue = 1;
    while ((!$document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_start_token", $token->getId)) && 
	   (!$document->getAnnotations->getSectionLevel->existsElementFromIndex("from", $token->getId)) && 
	   ((!defined $additionalLimits) || (!defined $additionalLimits->{'beforeLimit'}) || ($token->getFrom < $additionalLimits->{'beforeLimit'})) &&
	   ($continue)
	) {
	$token = $token->previous;
	foreach $term (@{$document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)}) {
	    if ($term->isTerm) {
		$semf = $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $term->getId)->[0];
		if ((defined $semf) && (exists $semanticFeatures->{$semf->first_node_first_semantic_category})) {
		    $continue = 0;
		    $token = $token->next;
		    last;
		}
	    }
	}
	if ($continue) {
	    foreach $word (@{$document->getAnnotations->getWordLevel->getElementByToken($token)}) {
		if (exists($self->{'lexicon_limit_after'}->{$lang}->{$word->getForm})) {
		    # warn "find and\n";
		    $continue = 0;
			$token = $word->start_token->previous;
		    last;
		}
	    }
	}
	$regex = $additionalLimits->{'beforeRegex'};
	# warn "regex: $regex\n";
	if ((defined $regex) && ($token->getContent =~ /$regex/)) {
	    $continue = 0; #by default
	    $token = $token->next;
	} else {
	    # warn "OK\n";
	}
    } ;
    $limitBeforeOffset = $token->getFrom;
    # warn "\tBefore: " . $token->getContent . "\n";

    return($limitBeforeOffset, $limitAfterOffset);
}

sub _addRelation_NE_Term {
    my ($self, $document, $semantic_feature_list, $additionalLimits, $correspondanceList) = @_;

    my 	$lang = $document->getAnnotations->getLanguage;
    my $term;
    my $semcat;
    my $semf;
    my $termlist;
    my @named_entities;
    my %limits;
    my $named_entity;

    foreach $term (@{$document->getAnnotations->getSemanticUnitLevel->getElements}) {
	if (($term->isTerm) && (defined $term->getSemanticFeatureFC($document))) {
	    foreach $semf (@{$document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $term->getId)}) {
		$termlist = 0;
		foreach $semcat (@{$semf->semantic_category}) {
		    if (!defined $semantic_feature_list) {
			$termlist++;
		    } elsif (exists($semantic_feature_list->{$semcat->[0]})) {
			$termlist++;
		    }
		}
	    }
	    if ($termlist > 0) {
		# warn "find named entities for " . $term->getForm . "(" . $term->getFrom . ")\n";
		@named_entities = ();
		($limits{'before'}, $limits{'after'}) = $self->getWindowLimits($term, $document, undef, 0, $additionalLimits);
		push @named_entities, @{$self->findNamedEntityBefore($term, $self->{'named_entity_categories'}->{$lang}, undef, $document, \%limits, undef)};
		# warn "\tfound " . scalar(@named_entities) . " named entities (before)\n";
		push @named_entities, @{$self->findNamedEntityAfter($term, $self->{'named_entity_categories'}->{$lang}, undef, $document, \%limits, undef)};
		# warn "\tfound " . scalar(@named_entities) . " named entities (after)\n";
		foreach $named_entity (@named_entities) {
		    if ($named_entity->NEtype eq 'numeric_internal') {
			if ((defined $correspondanceList) && (exists $correspondanceList->{$term->getSemanticFeatureFC($document)})) {
			    # warn "change NE type in " . $corresondanceList->{$term->getSemanticFeatureFC($document)} . "\n";
			    $named_entity->NEtype($correspondanceList->{$term->getSemanticFeatureFC($document)});
			    $term->incr_weight('quantified', 1);
			}
		    } else {
			$term->incr_weight('quantified', 1);
		    }
		    # warn "add relation between " . $term->getForm . " (" . $term->getId . ") and " . $named_entity->getForm . "\n";
		    $document->getAnnotations->addDomainSpecificRelation(
			Lingua::Ogmios::Annotations::DomainSpecificRelation->new(
			    {'domain_specific_relation_type' => "has_quantity",
			     'list_refid_semantic_unit' => [$term, $named_entity]
			    })
			);
		}
		if (scalar(@named_entities) == 0 ) {
		    if (!$term->existsWeight('quantified')) {
			$term->weight('quantified', 0);
		    }
		}
	    } else {
		if (!$term->existsWeight('quantified')) {
		    $term->weight('quantified', 0);
		}
		
	    }
	}
    }
}

sub _arff2deft {
    my ($self, $value) = @_;
#[A-Z]
# [a-z]
    $value =~ tr/ÁÂÀÅÃÄÇÉÊÈËÍÎÌÏÑÓÔÓØÕÖÚÛÙÜÝáâàåãäçéêèëíîìïñóôòøõöúûùüý[A-Z]/AAAAAACEEEEIIIINOOOOOOUUUUYaaaaaaceeeeiiiinoooooouuuuy[a-z]/;
#    $value =~ tr/ÁÂÀÅÃÄÇÉÊÈËÍÎÌÏÑÓÔÓØÕÖÚÛÙÜÝáâàåãäçéêèëíîìïñóôòøõöúûùüý/AAAAAACEEEEIIIINOOOOOOUUUUYaaaaaaceeeeiiiinoooooouuuuy/;
    # $value =~ tr/é[A-Z]/e[a-z]/;
#    $value = lc($value);
    # $str =~ $value =~ tr/ÁÂÀÅÃÄ/AAAAAA/;
    # $str =~ $value =~ tr/ÇÉÊÈËÍÎÌÏÑÓÔÓØÕÖÚÛÙÜÝ/CEEEEIIIINOOOOOOUUUUY/;
    # $str =~ $value =~ tr/áâàåãäçéêèëíîìïñóôòøõöúûùüý/aaaaaaceeeeiiiinoooooouuuuy/;
    # $str =~ $value =~ tr/[A-Z]/[a-z]/;
    # $str =~ s/é/e/g;
    # $str =~
    # 	$value =~ tr/ÁÂÀÅÃÄÇÉÊÈËÍÎÌÏÑÓÔÓØÕÖÚÛÙÜÝáâàåãäçéêèëíîìïñóôòøõöúûùüý[A-Z]/AAAAAACEEEEIIIINOOOOOOUUUUYaaaaaaceeeeiiiinoooooouuuuy[a-z]/;
    # $str =~
    # 	$value =~ tr/ÁÂÀÅÃÄÇÉÊÈËÍÎÌÏÑÓÔÓØÕÖÚÛÙÜÝáâàåãäçéêèëíîìïñóôòøõöúûùüý[A-Z]/AAAAAACEEEEIIIINOOOOOOUUUUYaaaaaaceeeeiiiinoooooouuuuy[a-z]/;
    # $str =~
    # 	$value =~ tr/ÁÂÀÅÃÄÇÉÊÈËÍÎÌÏÑÓÔÓØÕÖÚÛÙÜÝáâàåãäçéêèëíîìïñóôòøõöúûùüý[A-Z]/AAAAAACEEEEIIIINOOOOOOUUUUYaaaaaaceeeeiiiinoooooouuuuy[a-z]/;
    $value =~ s/æ/ae/g;
    $value =~ s/Æ/AE/g;
    $value =~ s/œ/oe/g;
    $value =~ s/Œ/OE/g;
    $value =~ s/&amp;/\&/go;
    $value =~ s/&quot;/\"/og;
    $value =~ s/&apos;/\'/og;
    $value =~ s/&lt;/</og;
    $value =~ s/&gt;/>/og;
    $value =~ s//oe/og;
    $value =~ s/\//_/g;
    $value =~ s/ +/_/g;
    $value =~ s/:/_/g;
    $value =~ s/!/_/g;
    $value =~ s/\?/_/g;
    $value =~ s/\&/_/g;
    $value =~ s/\'/_/g;
    $value =~ s/_+/_/g;
    $value =~ s/_/ /go;
    $value =~ s/\n/ /go;
    $value =~ s/ +$//go;
    $value =~ s/^ +//go;
    $value =~ s/ /-/go;
    # warn "=====> $value\n";

    return($value);
}

sub char_norm {
    my ($self, $str) = @_;

    $str =~ s/œ/oe/go;
    $str =~ s/ / /go;
    $str =~ s/’/'/go;
    $str =~ s/´/'/go;
    $str =~ s/•/-/go;
    $str =~ s/`/'/go;
    $str =~ s/“/ /go;
    $str =~ s/”/ /go;
    $str =~ s/‘/'/go;
    $str =~ s//oe/og;
    $str =~ s/……/....../go;
    $str =~ s/þ//go;
    $str =~ s/([\.:;,?!])([A-Za-z])/$1 $2/go;

    return($str);
}

sub _deft2arff {
    my ($self, $value) = @_;

    $value =~ s/ /_/go;

    return($value);
}

sub _makeHeader {
    my ($self, $lang, $relation, $property, $classes) = @_;

    my $attr;
    my $LDS;
    my $type;

    $LDS = Lingua::Ogmios::LearningDataSet->new();
    $LDS->relation($relation);
    $LDS->classes($classes);
    if (defined $self->{"attribute_file"}->{$lang}) {
	warn "read from filelist\n";
	$self->_readAttributeList($lang, $relation, $property, $classes, $LDS);
    } else {
	warn "read from lists\n";
	foreach $attr (sort {$a->{ORDER} <=> $b->{ORDER}} values %{$self->{ATTRIBUTES}->{$lang}}) {
	    if (defined $attr->{FILE}) {
		# warn "==>" . $attr->{FILE} . "\n";
		$self->_load_attribute_file($attr->{FILE}, $attr->{TYPE}, $attr->{PREFIX}, $LDS);
	    } else {
		if (defined $attr->{VALUE}) {
		    # warn $attr->{VALUE} ."\n";
		    my @typeValue = split /,/,$self->_deft2arff($attr->{TYPE});

		    if (scalar(@typeValue) > 1) {
			$type = \@typeValue;
		    } else {
			$type = $self->_deft2arff($attr->{TYPE});
		    }
		    my $attribute = Lingua::Ogmios::LearningDataSet::Attribute->new(    
			{"name" => $attr->{PREFIX} . "_" . $attr->{VALUE},
			 "type" => $type,
			 "prefix" => $attr->{PREFIX},
			 "value" => $attr->{VALUE},
			}
			);
		    # my $idx = 
		    $LDS->addAttribute($attribute);
		    # warn "\t$idx\n";
		    # $attribute = Lingua::Ogmios::LearningDataSet::Attribute->new(    
		    # 	{"name" => $attr->{PREFIX} . "_" . $attr->{VALUE},
		    # 	 "type" => [split /,/, $self->_deft2arff($attr->{TYPE})],
		    # 	}
		    # 	);
		    # $LDS->addAttribute($attribute);
		}
	    }
	}
    }
    if (defined $self->{ATTRIBUTES}->{$lang}->{DOCUMENTFREQUENCY}->{FILE}) {
	$self->{"attr2df"}->{$lang} = {};
	$self->_load_df_values($self->{ATTRIBUTES}->{$lang}->{DOCUMENTFREQUENCY}->{FILE}, $self->{"attr2df"}->{$lang});
    }
    
    return($LDS);
}

sub _load_attribute_file {
    my ($self,$file, $type, $prefix, $LDS) = @_;
    my $line;
    my $attr;
    my $attr_str;
    my $freq;

    warn "Loading $file ($type : $prefix)\n";
    open FILE, $file or die "No such file $file\n";
    binmode(FILE, ':utf8');
    while($line = <FILE>) {
	chomp $line;

	if ($line !~ /^\s*#/) {
	    ($attr_str, $freq) = split /\t/, $line;
	    my $attr = Lingua::Ogmios::LearningDataSet::Attribute->new(    
		{"name" => $prefix . "_" . $self->_deft2arff($self->_arff2deft($attr_str)),
		 "type" => uc($type),
		 "prefix" => $prefix,
		 "value" => $attr_str,

		}
		);
	    $LDS->addAttribute($attr);

	}
    }
    close FILE;
}


sub _load_df_values {
    my ($self,$file, $attr2freq) = @_;

    my $line;
    my $attr_str;
    my $freq;

    warn "Loading $file (document frequency)\n";
    open FILE, $file or die "No such file $file\n";
    binmode(FILE, ':utf8');
    while($line = <FILE>) {
	chomp $line;

	if ($line !~ /^\s*#/) {
	    ($attr_str, $freq) = split /\t/, $line;
	    if (defined $attr2freq) {
		$attr2freq->{$self->_deft2arff($self->_arff2deft($attr_str))} = $freq;
	    }
	}
    }
    close FILE;
}


sub _readAttributeList {
    my ($self, $lang, $relation, $property, $classes, $LDS) = @_;

    my $section;
    my $attr;
    my $string;
    my $attr_str;
    my $attr_str_wprefix;
    my $type;
    my $line;
    my $order;
    my $prefix;

    warn "readAttributeList ($relation - $property)\n";

    warn "Open " . $self->{"attribute_file"}->{$lang} . "\n";
    open FILE, $self->{"attribute_file"}->{$lang} or die "No such file ". $self->{"attribute_file"}->{$lang};
    binmode(FILE, ":utf8");
    while($line = <FILE>) {
	chomp $line;

	if ($line !~ /^\s*#/) {
	    $prefix = undef;
	    ($attr_str, $attr_str_wprefix, $type, $prefix) = split /\t/, $line;
	    if (!exists $self->{ATTRIBUTES}->{$lang}->{uc($attr_str)}) {
		if (!defined $prefix) {
		    ($prefix, ) = split /_/, $attr_str_wprefix;
		}
		$self->{ATTRIBUTES}->{$lang}->{uc($prefix)}->{PREFIX} = $prefix;
		$self->{ATTRIBUTES}->{$lang}->{uc($prefix)}->{TYPE} = $type;
	    }
	    my $attr = Lingua::Ogmios::LearningDataSet::Attribute->new(    
		{"name" => $self->_deft2arff($attr_str_wprefix),
		 "type" => $self->_deft2arff($type),
		 "prefix" => $prefix,
		 "value" => $attr_str,
		}
		);
	    $LDS->addAttribute($attr);
	}
    }
    close FILE;

###

    # foreach $document (@{$self->_documentSet}) {
    # 	foreach $word (@{$document->getAnnotations->getWordLevel->getElements}) {
    # 	    $self->_postag_attribute($document, $LDS, $data, $word);
    # 	    $self->_word_attribute($document, $LDS, $data, $word);
    # 	    $self->_lemma_attribute($document, $LDS, $data, $word);
    # 	}
    # 	$self->_semtag_attribute($document, $LDS, $data);
    # }
    # $self->LDS($lang, $LDS);
    warn "done\n";
}

sub _printLearningSet {
    my ($self, $lang, $output, $fh, $printHeader) = @_;

    my $LDS = $self->LDS($lang);

     if ($output eq "ARFF+SVM") {
	print $fh "ARFF|";
	print $fh $LDS->getARFFData;
	print $fh "SVM|";
	print $fh $LDS->getSVM;
    }
    if ($output eq "ARFF") {
	if ($printHeader == 1) {
	    print $fh $LDS->getARFFHeader;
	    print $fh '@DATA' . "\n";
	}
	print $fh $LDS->getARFFData;
    }
    if ($output eq "SVM") {
	print $fh $LDS->getSVM;
    }
}

sub LDS {
    my $self = shift;
    my $lang = shift;

    if (@_) {
	$self->{'LDS'} = shift;
    }
    return($self->{'LDS'});
}


sub _termWeight_attribute {
    my ($self, $document, $LDS, $data, $term) = @_;

    my $lang =  $document->getAnnotations->getLanguage;
    my $string;
    my $weight;
    my @weights;

    if (defined $self->{ATTRIBUTES}->{$lang}->{WEIGHT}->{PREFIX}) {
	my $prefix = $self->{ATTRIBUTES}->{$lang}->{WEIGHT}->{PREFIX};
	# warn "=> $prefix\n";
	foreach $weight (keys %{$term->weights}) {
	    # warn "====> $weight\n";
	    # $string = $prefix . "_" . $self->_deft2arff($self->_arff2deft($weight));
	    $string = $prefix . "_" . $self->_deft2arff($weight);
	    # warn "$string\n";
	    if ($LDS->existsAttribute($string)) {
		$data->value($LDS->getAttributeIndex($string), $term->weight($weight));
		# $data->incr_value($LDS->getAttributeIndex($string));
	    }
	}
	if ($LDS->existsAttribute($prefix . "_position")) {
	    # warn "====> position\n";
	    $data->value($LDS->getAttributeIndex($prefix . "_position"), $term->start_token->getFrom);
	}
	if ($LDS->existsAttribute($prefix . "_wordLength")) {
	    # warn "====> position\n";
	    $data->value($LDS->getAttributeIndex($prefix . "_wordLength"), $term->getReferenceWordSize);
	}
	
    }
}

sub _termWeight_attribute_v2 {
    my ($self, $document, $LDS, $data, $term) = @_;

    my $lang =  $document->getAnnotations->getLanguage;
    my $string;
    my $attr;
    my $weight;

    if (defined $self->{ATTRIBUTES}->{$lang}->{WEIGHT}->{PREFIX}) {
	my $prefix = $self->{ATTRIBUTES}->{$lang}->{WEIGHT}->{PREFIX};
	foreach $attr (keys %{$LDS->attributes}) {
	    if ($attr->prefix eq "weight") {
		$weight = $attr->value;
		# $string = $prefix . "_" . $self->_deft2arff($self->_arff2deft($term->weight($weight)));
		$string = $prefix . "_" . $self->_deft2arff($term->weight($weight));
		# warn "$string\n";
		if ($term->existsWeight($weight)) {
		    $data->value($LDS->getAttributeIndex($string), $term->weight($weight));
		} elsif ($weight eq "position") {
		    $data->value($LDS->getAttributeIndex($string), $term->start_token->getFrom);
		}

	    }
	}
    }
}

sub _parseWekaEvalOutput {
    my ($self, $property) = @_;

    my $line;
    my $instnb;
    my $actual_nb_class;
    my $predicted_nb_class;
    my $actual_Class;
    my $predicted_Class;
    my $actual_classNb;
    my $predicted_classNb;
    my $error;
    my @distribution;
    my $document;
    my %results;

    open FILE, $self->_output_filename or die "No such file " . $self->_output_filename;
    binmode(FILE, ":utf8");
    while($line = <FILE>){
	if ($line =~ /^inst\#/o) {
	    last;
	}
    };

    while($line = <FILE>) {
    	chomp $line;

	if ($line ne "") {
	    warn "$line\n";
	    ($instnb, $actual_nb_class, $predicted_nb_class, $error, @distribution) = split /\t/, $line;
	    ($actual_classNb, $actual_Class) = split /:/, $actual_nb_class;
	    ($predicted_classNb, $predicted_Class) = split /:/, $predicted_nb_class;
	    # $document = $self->_documentSet->[$instnb - 1];
	    # warn "$property,$predicted_Class\n";
	    # $document->getAnnotations->replaceProperty($property,$predicted_Class);
	    # warn $document->getAnnotations->getProperty($property) . "\n";;
	}
    }

    close FILE;
	
}

sub _createSemanticFeaturesFromString {
    my ($self, $semtags, $termUnitId) = @_;

    my $semtag;
    my $semFeatures;
    my @list_semtags;

    if (defined $semtags) {
	foreach $semtag (split /;/, $semtags) {
	    # warn "\t$semtag\n";
	    my @semtags = split /\//, $semtag;
	    push @list_semtags, \@semtags;
	    # TODO Check if the semtag already exists in order to avoid to create one another?
	    $semFeatures = Lingua::Ogmios::Annotations::SemanticFeatures->new(
		{ 'semantic_category' => \@list_semtags,
		  'refid_semantic_unit' => $termUnitId,
		});
	}
    }
    return($semFeatures);
}

sub getTermsFromSpan {
    my ($self, $document, $ref_start_token, $ref_end_token) = @_;

    my $word;
    # my $lemma;

    # my $sentLemma = "";;
    my $token = $ref_start_token;

    # my $token_prec = 0;
    my @terms = ();
    my @semfs;
    my $semf;

    if (defined $token) {
	do {
	    warn $token->getId . " : " . $token->getContent . "\n";
	    if ($document->getAnnotations->getSemanticUnitLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
		warn $token->getContent . "\n";
		@semfs = @{$document->getAnnotations->getSemanticUnitLevel->getElementFromIndex("list_refid_token", $token->getId)};
		# $lemma = $document->getAnnotations->getLemmaLevel->getElementFromIndex("refid_word", $word->getId)->[0];
		foreach $semf (@semfs) {
		    if ($semf->isTerm) {
			push @terms, $semf;
		    }
		}
	    }
	    $token = $token->next;
	} while((defined $token) && (defined $token->previous) && (!($token->previous->equals($ref_end_token))));
    }
    return(\@terms);
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

