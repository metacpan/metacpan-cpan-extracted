package Lingua::Ogmios::NLPWrappers::StanfordParser;


our $VERSION='0.1';


use Lingua::Ogmios::NLPWrappers::Wrapper;
use Lingua::Ogmios::Annotations::SyntacticRelation;

use strict;
use warnings;

our @ISA = qw(Lingua::Ogmios::NLPWrappers::Wrapper Lingua::Ogmios::Annotations::SyntacticRelation);

sub new {
    my ($class, $config, $tmpfile_prefix, $logfile, $position, $no_standard_output) = @_;

    warn "[LOG]    Creating a wrapper of the StanfordParser\n";


    my $StanfordParser = $class->SUPER::new($config, $tmpfile_prefix, $logfile, $position, $no_standard_output);

    $StanfordParser->_input_filename($tmpfile_prefix . ".StanfordParser.in");
    $StanfordParser->_output_filename($tmpfile_prefix . ".StanfordParser.out");

    return($StanfordParser);

}

sub _processStanfordParser {
    my ($self, $lang) = @_;

    warn "[LOG] StanfordParser\n";

    $lang = $self->_documentSet->[0]->getAnnotations->getLanguage;

    return($self->_exec_command($self->_defineCommandLine($self->_config->commands($lang)->{STANFORDPARSER_CMD} . $self->_input_filename . ">" . $self->_output_filename)));

    warn "[LOG]\n";
}

sub _inputStanfordParser {
    my ($self) = @_;

    warn "[LOG] making StanfordParser input\n";

    $self->_printStanfordParserFormatInput2($self->_input_filename);
    
    warn "[LOG] done\n";
}


sub _outputStanfordParser {
    my ($self) = @_;

    warn "[LOG] . Parsing " . $self->_output_filename . "\n";

# $self->{"ELTSBYSENT"}

    my $s;
    my $r;
    my $w1;
    my $w2;
    my $refW1;
    my $refW2;


    my $syntacticRelation;

    my $docId;
    my $parsedDocs = $self->_parseSentences;

    foreach $docId (keys %$parsedDocs) {
	my $parsedSentences = $parsedDocs->{$docId};
	for($s = 0; $s < scalar(@$parsedSentences); $s++) {
#  	warn "s: $s\n";
	    for($r = 0; $r < scalar(@{$parsedSentences->[$s]}); $r++) {
# 	    warn "r: $r\n";
# 	    warn "rel: " . $parsedSentences->[$s]->[$r]->[0] . "\n";

		$w1 = $self->{"ELTSBYSENT"}->{$docId}->[$s]->[$parsedSentences->[$s]->[$r]->[1] - 1];
		$w2 = $self->{"ELTSBYSENT"}->{$docId}->[$s]->[$parsedSentences->[$s]->[$r]->[2] - 1];

# 		if ((ref($w1) eq "Lingua::Ogmios::Annotations::Word") && (ref($w2) eq "Lingua::Ogmios::Annotations::Word")) {
# # 		warn "add a syntactic relation between " . $w1->getForm . " and " . $w2->getForm . "(" . $parsedSentences->[$s]->[$r]->[0] . ")\n";
# 		    $syntacticRelation = Lingua::Ogmios::Annotations::SyntacticRelation->new(
# 			{ 'syntactic_relation_type' => $parsedSentences->[$s]->[$r]->[0], 
# 			  'refid_word_head' => $w1,
# 			  'refid_word_modifier' => $w2,
# 			}
# 			);
# 		    $self->getDocumentFromDocId($docId)->getAnnotations->addSyntacticRelation($syntacticRelation);
# # 		    warn "Syntactic Relation: " . $syntacticRelation->getId . "\n";
		
# 		}
		$refW1 = undef;
		$refW2 = undef;
		if (ref($w1) eq "Lingua::Ogmios::Annotations::Word") { 
		    $refW1 = "refid_word_head";
		} else {
		    if (ref($w1) eq "Lingua::Ogmios::Annotations::SemanticUnit") {
			if (($w1->reference_name eq "refid_word") || 
			    ($w1->reference_name eq "refid_phrase")) {
			    $refW1 = $w1->reference_name . "_head";
			    $w1 = $w1->reference;
			} elsif ($self->getDocumentFromDocId($docId)->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $w1->start_token->getId)) {
			    $refW1 = "refid_word_head";
			    $w1 = $self->getDocumentFromDocId($docId)->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $w1->start_token->getId)->[0];
			}
		    }
		}
		if (ref($w2) eq "Lingua::Ogmios::Annotations::Word") { 
		    $refW2 = "refid_word_modifier";
		} else {
		    if (ref($w2) eq "Lingua::Ogmios::Annotations::SemanticUnit") {
			if (($w2->reference_name eq "refid_word") || 
			    ($w2->reference_name eq "refid_phrase")) {
			    $refW2 = $w2->reference_name . "_modifier";
			    $w2 = $w2->reference;
			} elsif ($self->getDocumentFromDocId($docId)->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $w2->start_token->getId)) {
			    $refW2 = "refid_word_modifier";
			    $w2 = $self->getDocumentFromDocId($docId)->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $w2->start_token->getId)->[0];
			}
		    }
		}

		if ((defined $refW1) && (defined $refW2)) {
# 		warn "add a syntactic relation between " . $w1->getForm . " and " . $w2->getForm . "(" . $parsedSentences->[$s]->[$r]->[0] . ")\n";
		    $syntacticRelation = Lingua::Ogmios::Annotations::SyntacticRelation->new(
			{ 'syntactic_relation_type' => $parsedSentences->[$s]->[$r]->[0], 
			  $refW1 => $w1,
			  $refW2 => $w2,
			}
			);
		    $self->getDocumentFromDocId($docId)->getAnnotations->addSyntacticRelation($syntacticRelation);
# 		    warn "Syntactic Relation: " . $syntacticRelation->getId . "\n";
		}
	    }
	}
    }
    
    warn "[LOG] done\n";
}

sub _parseSentences {
    my ($self) = @_;

    my %documents;

    my $line;
    my @sentences;

    my $doc_id = undef;;
    my $posDoc;
    my $posComma;

    open FILE_OUT, $self->_output_filename or warn "Can't open the file " . $self->_output_filename;;
#     binmode(FILE_OUT, ":utf8");

    my @sentenceTMP;

    while($line = <FILE_OUT>) {
	chomp $line;

	if (($posDoc = index($line, "-DOCUMENT")) > 0) {
	    if (defined $doc_id) {
		my @sents;
		push @sents, @sentences;
		$documents{$doc_id} = \@sents;
		@sentences = ();
	    }
	    $posComma = rindex($line, ', ', $posDoc);
	    $doc_id = substr($line, $posComma + 2, $posDoc - $posComma - 2 );
	    warn "doc_id: $doc_id\n";
	    <FILE_OUT>;
	} elsif ($line eq "") {
	    my @sentence;
	    push @sentence, @sentenceTMP;
	    push @sentences, \@sentence;
	    @sentenceTMP = ();
	} else {
#	    push @sentenceTMP, $line;
	    push @sentenceTMP, $self->_parseLine($line);
	}
    }
    if (defined $doc_id) {
	warn "doc_id : $doc_id\n";
	my @sents;
	push @sents, @sentences;
	$documents{$doc_id} = \@sents;
    }

    close FILE_OUT;

    return(\%documents);

}

sub _parseLine {
    my ($self, $line) = @_;

    my $posPar;
    my $posComma;
    my $posDash;

    my $synRel;
    my $word1Num;
    my $word2Num;
    my $posQuote;

    my $shift = 0;
    my @rel;

#     warn "$line\n";

    # find first (
    $posPar = index($line, '(');
    $synRel = substr($line, 0, $posPar);
#     warn "$synRel\n";
    push @rel, $synRel;

    # find Comma
    $posComma = index($line, ', ', $posPar + 1);
    $posDash = rindex($line, '-', $posComma);
    $shift = 0;
#     warn "(1) dash: $posDash\n";
    if ((($posQuote = index($line, "'", $posDash)) > -1) && ($posQuote < $posComma)) {
	$shift = 1;
    }
#     warn "(1) shift: $shift ($posQuote / $posComma)\n";
#     warn "(2) dash: $posDash\n";
#     warn "(1) search for " . ($posDash + 1) . " and " .  ($posComma - $posDash - 1 - $shift) . "\n";
    $word1Num = substr($line, $posDash + 1, $posComma - $posDash - 1 - $shift);
#     warn ($word1Num - 1 + 1) . "\n";
#     warn "$word1Num\n";
    push @rel, $word1Num;

    # find )
    $posPar = length($line) - 1;
    $posDash = rindex($line, '-', $posPar);
    $shift = 0;
#     warn "(3) dash: $posDash\n";
    if ((($posQuote = index($line, "'", $posDash)) > -1) && ($posQuote < $posPar)) {
	$shift = 1;
    }
#     warn "(2) shift: $shift ($posQuote / $posComma)\n";
#     warn "(4) dash: $posDash\n";
#     warn "(2) search for " . ($posDash + 1) . " and " .  ($posPar - $posDash - 1 - $shift) . "\n";

    $word2Num = substr($line, $posDash + 1, $posPar - $posDash - 1 - $shift);
#     warn ($word2Num - 1 + 1) . "\n";
#     warn "$word2Num\n";
    push @rel, $word2Num;

#      warn "\n";
    return(\@rel);
}

sub run {
    my ($self, $documentSet) = @_;

    warn "*** TODO: check if the level exists\n";
    # Set variables according the the configuration

    $self->_documentSet($documentSet);

    warn "[LOG] " . $self->_config->comments . " ...     \n";

    $self->_inputStanfordParser;

    my $command_line = $self->_processStanfordParser;

    $self->_outputStanfordParser;
#     if ($self->_position eq "last") {
# 	# TODO

    # Put log information 
    my $information = { 'software_name' => $self->_config->name,
			'comments' => $self->_config->comments,
			'command_line' => $command_line,
			'list_modified_level' => ['syntactic_relation_level'],
    };
    $self->_log($information);

    if (($self->_position eq "last") && ($self->_no_standard_output)) {
	warn "print no standard output\n";
#	$self->_outputStanfordParser;
    }

    warn "[LOG] done\n";
}

sub _printStanfordParserFormatInput {
    my $self = shift;
    my $filename = shift;
    my $encoding = shift;

    my $document;
    my $doc_idx;
    my $token;
    my $word;
    my $lemma;
    my $MS_features;
    my @corpus_in_t;

    my @sentElt;

    my %corpusDocuments;


    warn "[LOG] printing TreeTagger Like Output\n";

    foreach $document (@{$self->_documentSet}) {

	my @corpus_inRefElementSent;
	$corpusDocuments{$document->getId} = \@corpus_inRefElementSent;
	my @tmp = ($document->getId . "-DOCUMENT/NNP :", ".\n"); # , $document->getId
	push @corpus_in_t, \@tmp;
	
	for($doc_idx = 0; $doc_idx < scalar(@{$document->getAnnotations->getTokenLevel->getElements});$doc_idx++) {
	    $token = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];
	    if ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
		$word = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];
		$MS_features = $document->getAnnotations->getMorphosyntacticFeaturesLevel->getElementFromIndex("refid_word", $word->getId)->[0];
		my $wordform = $word->getForm;
		$wordform =~ s/[\t\n]/ /gos;
		$wordform =~ s/ +/_/gos;

		my $MS_f = $MS_features->syntactic_category;
		if ($MS_f eq "NE") {
		    $MS_f = "NN";
		}		
		my @tmp  = ($wordform, $MS_f); # , $lemma->canonical_form

		push @corpus_in_t, \@tmp;

		push @sentElt, $word;

		$doc_idx += $word->getReferenceSize - 1;
 		$token = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];
		
	    } else {
		if (!($token->isSep)) {
		    my @tmp = ($token->getContent, $token->getContent); # , $token->getContent
		    push @corpus_in_t, \@tmp;
		    push @sentElt, $token;
		}
	    }
	    if ($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId)) {
		if ($token->isSymb) {
		    if (!($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId))) {
			my @tmp = ($corpus_in_t[$#corpus_in_t]->[0] , ".\n"); # , $corpus_in_t[$#corpus_in_t]->[0]
			$corpus_in_t[$#corpus_in_t] = \@tmp;
		    } else {
			my @tmp = ($token->getContent, ".\n"); # , $token->getContent
			push @corpus_in_t, \@tmp;
			push @sentElt, $token;
		    }
		} else {
		    my @tmp = (".", ".\n"); # , "."
		    push @corpus_in_t, \@tmp;
		    push @sentElt, "";
		}
		my @senttmp;
		push @senttmp, @sentElt;
		push @corpus_inRefElementSent, \@senttmp;
		@sentElt = ();
	    }
	}
    }

    $self->{"ELTSBYSENT"} = \%corpusDocuments;

    warn "\tOpenning " . $filename . "\n";

    open FILE_IN, ">" . $filename or die "can't open " . $filename . "\n";

    my $str_out;

    my $word_ref;
    foreach $word_ref (@corpus_in_t) {
	if (scalar(@$word_ref) == 2) {
# Encode::encode("iso-8859-1", join("\n",@corpus_in_t), Encode::FB_DEFAULT);
	    if ((!defined $encoding) || (uc($encoding) eq "UTF-8")) {
		 $str_out = Encode::encode("UTF-8", join("/",@$word_ref)) . " ";
		 $str_out =~ s/\n /\n/o;

		 print FILE_IN $str_out;
	    } else {
		if ((defined $encoding) && (uc($encoding) eq "LATIN1")) {
# 	print FILE_IN Encode::encode("iso-8859-1", join("\t",@$word_ref), Encode::FB_DEFAULT) . "\n";
		    $str_out =  Encode::encode("iso-8859-1", join("/",@$word_ref)) . " ";
		    $str_out =~ s/\n /\n/o;

		    print FILE_IN $str_out;
		} else {
		    warn "[WRAPPER LOG] Unknown enconding charset\n";
		}
	    }
	}
    }

    close FILE_IN;
    warn "[LOG] done\n";
}

sub _printStanfordParserFormatInput2 {
    my $self = shift;
    my $filename = shift;
    my $encoding = shift;

    my $document;
    my $doc_idx;
    my $token;
    my $word;
    my $lemma;
    my $MS_features;
    my @corpus_in_t;

    my @sentElt;

    my %corpusDocuments;

    my $terms;

    warn "[LOG] printing TreeTagger Like Output\n";

    foreach $document (@{$self->_documentSet}) {

	my @corpus_inRefElementSent;
	$corpusDocuments{$document->getId} = \@corpus_inRefElementSent;
	my @tmp = ($document->getId . "-DOCUMENT/NNP :", ".\n"); # , $document->getId
	push @corpus_in_t, \@tmp;
	
	for($doc_idx = 0; $doc_idx < scalar(@{$document->getAnnotations->getTokenLevel->getElements});$doc_idx++) {
	    $token = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];
	    $terms = $document->getAnnotations->getSemanticUnitLevel->getElementByToken($token);
	    if (scalar(@{$terms}) > 0) {
		my $termform = $terms->[0]->getForm;
		$termform =~ s/[\t\n]/ /gos;
		$termform =~ s/ +/_/gos;
		
		my @tmp  = ($termform, "NN"); # , $lemma->canonical_form

		push @corpus_in_t, \@tmp;
		push @sentElt, $terms->[0];

# 		warn "$termform" . $terms->[0]->getReference .  "\n";

		$doc_idx += $terms->[0]->getReferenceTokenSize - 1;
 		$token = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];
	    } elsif ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
		$word = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];
		$MS_features = $document->getAnnotations->getMorphosyntacticFeaturesLevel->getElementFromIndex("refid_word", $word->getId)->[0];
		my $wordform = $word->getForm;
		$wordform =~ s/[\t\n]/ /gos;
		$wordform =~ s/ +/_/gos;

		my $MS_f = $MS_features->syntactic_category;
		if ($MS_f eq "NE") {
		    $MS_f = "NN";
		}
		my @tmp  = ($wordform, $MS_f); # , $lemma->canonical_form

		push @corpus_in_t, \@tmp;
		push @sentElt, $word;

		$doc_idx += $word->getReferenceSize - 1;
 		$token = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];
		
	    } else {
		if (!($token->isSep)) {
		    my @tmp = ($token->getContent, $token->getContent); # , $token->getContent
		    push @corpus_in_t, \@tmp;
		    push @sentElt, $token;
		}
	    }
#	    warn "doc_idx $doc_idx / " . scalar(@{$document->getAnnotations->getTokenLevel->getElements}) . "\n";
	    if ($doc_idx < scalar(@{$document->getAnnotations->getTokenLevel->getElements})) {
		if ($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId)) {
		    if ($token->isSymb) {
			if (!($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId))) {
			    my @tmp = ($corpus_in_t[$#corpus_in_t]->[0] , ".\n"); # , $corpus_in_t[$#corpus_in_t]->[0]
			    $corpus_in_t[$#corpus_in_t] = \@tmp;
			} else {
			    my @tmp = ($token->getContent, ".\n"); # , $token->getContent
			    push @corpus_in_t, \@tmp;
			    push @sentElt, $token;
			}
		    } else {
			my @tmp = (".", ".\n"); # , "."
			push @corpus_in_t, \@tmp;
			push @sentElt, "";
		    }

		    my @senttmp;
		    push @senttmp, @sentElt;
		    push @corpus_inRefElementSent, \@senttmp;
		    @sentElt = ();
		}
	    } else {
		my @tmp = (".", ".\n"); # , "."
		push @corpus_in_t, \@tmp;
		push @sentElt, "";
		
		my @senttmp;
		push @senttmp, @sentElt;
		push @corpus_inRefElementSent, \@senttmp;
		@sentElt = ();
	    }
	}
    }

    $self->{"ELTSBYSENT"} = \%corpusDocuments;

    warn "\tOpenning " . $filename . "\n";

    open FILE_IN, ">" . $filename or die "can't open " . $filename . "\n";

    my $str_out;

    my $word_ref;
    foreach $word_ref (@corpus_in_t) {
	if (scalar(@$word_ref) == 2) {
# Encode::encode("iso-8859-1", join("\n",@corpus_in_t), Encode::FB_DEFAULT);
	    if ((!defined $encoding) || (uc($encoding) eq "UTF-8")) {
		 $str_out = Encode::encode("UTF-8", join("/",@$word_ref)) . " ";
		 $str_out =~ s/\n /\n/o;

		 print FILE_IN $str_out;
	    } else {
		if ((defined $encoding) && (uc($encoding) eq "LATIN1")) {
# 	print FILE_IN Encode::encode("iso-8859-1", join("\t",@$word_ref), Encode::FB_DEFAULT) . "\n";
		    $str_out =  Encode::encode("iso-8859-1", join("/",@$word_ref)) . " ";
		    $str_out =~ s/\n /\n/o;

		    print FILE_IN $str_out;
		} else {
		    warn "[WRAPPER LOG] Unknown enconding charset\n";
		}
	    }
	}
    }

    close FILE_IN;
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

