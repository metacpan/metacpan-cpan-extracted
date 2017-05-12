package Lingua::Ogmios::NLPWrappers::GeniaTagger;


our $VERSION='0.1';


use Lingua::Ogmios::NLPWrappers::Wrapper;

use Lingua::Ogmios::Annotations::MorphosyntacticFeatures;
use Lingua::Ogmios::Annotations::Lemma;

use Encode qw(:fallbacks);;


use strict;
use warnings;

our @ISA = qw(Lingua::Ogmios::NLPWrappers::Wrapper);

sub new {
    my ($class, $config, $tmpfile_prefix, $logfile, $position, $no_standard_output) = @_;

    warn "[LOG]    Creating a wrapper of the GeniaTagger\n";


    my $GeniaTagger = $class->SUPER::new($config, $tmpfile_prefix, $logfile, $position, $no_standard_output);

    $GeniaTagger->_input_filename($tmpfile_prefix . ".GeniaTagger.in");
    $GeniaTagger->_output_filename($tmpfile_prefix . ".GeniaTagger.out");

    unlink($GeniaTagger->_input_filename);
    unlink($GeniaTagger->_output_filename);

    return($GeniaTagger);

}

sub _processGeniaTagger {
    my ($self, $lang) = @_;

    warn "[LOG] POS tagger\n";

    $lang = $self->_documentSet->[0]->getAnnotations->getLanguage;

    return($self->_exec_command($self->_defineCommandLine($self->_config->commands($lang)->{GeniaTagger_CMD} . " < " . $self->_input_filename . ">" . $self->_output_filename)));

    warn "[LOG]\n";
}

sub _inputGeniaTagger {
    my ($self) = @_;

    my $token;
    my $next_token;
#     my $corpus_in = "";
    my $document;
    my $doc_idx;

    my @corpus_in_t;
    my $wordform;

    my $word;
    warn "[LOG] making GeniaTagger input\n";
    
    foreach $document (@{$self->_documentSet}) {
	for($doc_idx = 0; $doc_idx < scalar(@{$document->getAnnotations->getTokenLevel->getElements});$doc_idx++) {
	    $token = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];
#  	    warn "Current tokent (1): " . $token->getId . "\n";
	    if ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
		$word = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];
# 		$corpus_in .= $word->getForm . "\n";
		$wordform = $word->getForm;
# 		warn "$wordform\n";
		$wordform =~ s/[\t\n]/ /gos;
		$wordform =~ s/ +/___/gos;
# 		warn "$wordform\n";
		push @corpus_in_t, $wordform;

		$doc_idx += $word->getReferenceSize - 1;
 		$token = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];
#  		warn "Current tokent (2w): " . $token->getId . "\n";

# 		if ($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId)) {
# 		    warn "Current tokent (3s): " . $token->getId . "\n";
		    
# 		    if ($token->isSymb) {
# 			$corpus_in .= $token->getContent . "\tSENT\n";
# 		    } else {
# 			$corpus_in .= ".\tSENT\n";
# 		    }
# 		}

	    } else {
		if (!($token->isSep)) {
# 		    warn "Current tokent (2s): " . $token->getId . "\n";		    
# 		    if ($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId)) {
# 			warn "Current tokent (3s): " . $token->getId . "\n";

# 			$corpus_in .= ".\tSENT\n";

# 		    }
# 		} else {
# 		    if ($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId)) {
# 			warn "Current tokent (3s): " . $token->getId . "\n";
# 			$corpus_in .= $token->getContent . "\tSENT\n";
# 		    } else {
# 			$corpus_in .= $token->getContent;
		        $wordform = $token->getContent;
			$wordform =~ s/[\t\n]/ /gos;
			$wordform =~ s/ +/___/go;
			push @corpus_in_t, $wordform;
# 		    }
		}
	    }
	    if ($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId)) {
		if ($token->isSymb) {
		    if (!($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId))) {
# 			$corpus_in .= "\tSENT\n";
#			$corpus_in_t[$#corpus_in_t] .= "\tSENT";
		    } else {
# 			$corpus_in .= $token->getContent . "\tSENT\n";
		        $wordform = $token->getContent;
			$wordform =~ s/[\t\n]/ /gos;
			$wordform =~ s/ +/___/go;
			push @corpus_in_t, $wordform; #. "\tSENT";
		    }
		} else {
#  		    $corpus_in .= ".\tSENT\n";
		    push @corpus_in_t, ".\n";#\tSENT";

		}
# 	    } else {
# 		if ((!($token->isSep)) && (!($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)))) {
# 		    $corpus_in .= "\n";
# 		}
	    }

	}
# 	foreach $token (@{$document->getAnnotations->getTokenLevel->getElements}) {
# #	warn "$token: " . $token->getContent . ";\n";
# 	    $corpus_in .= $token->getContent . "\n";
# 	}
    }

     open FILE_IN, ">" . $self->_input_filename;
    

#      print FILE_IN Encode::encode("iso-8859-1", $corpus_in, Encode::FB_DEFAULT); #$corpus_in;
     print FILE_IN Encode::encode("iso-8859-1", join(" ",@corpus_in_t), Encode::FB_DEFAULT); #$corpus_in;
#    print FILE_IN "\n";
     close FILE_IN;
    
    warn "[LOG] done\n";


}


sub _outputParsing {
    my ($self) = @_;

    my $line;
    my @GeniaTaggerOutput;

    my $doc_idx;
    my $word_idx;
    my $document;

    my $word;
    my $token;

    my $posInWord;
    my $posInLemma;

    my $substringBefore;
    my $substringAfter;

    my $defaultPOS = "NN";
    my $defaultLemma;

    warn "[LOG] . Parsing " . $self->_output_filename . "\n";

    open FILE_OUT, $self->_output_filename or warn "Can't open the file " . $self->_output_filename;;
#     binmode(FILE_OUT, ":utf8");

    while($line = <FILE_OUT>) {
	chomp $line;
	if ($line ne "") {
	    $line =~ s/___/ /go;
	    my @tmp;
	    ($tmp[0], $tmp[2], $tmp[1]) = split /\t/, $line;
	    # work around some strange tagging 
	    if ((!defined $tmp[1]) || ($tmp[1] eq "")){
		$tmp[1] = "SYM";
	    }
	    if ((!defined $tmp[2]) || ($tmp[2] eq "")){
		$tmp[2] = $tmp[0];
	    }
	    push @GeniaTaggerOutput, \@tmp;
	}

    }
    close FILE_OUT;

#     warn "TT output size: " . scalar(@GeniaTaggerOutput) . "\n";

    my $GeniaTaggerOutput_idx = 0;

    foreach $document (@{$self->_documentSet}) {
	for($doc_idx = 0; $doc_idx < scalar(@{$document->getAnnotations->getTokenLevel->getElements});$doc_idx++) {
	    $token = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];
	    if ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
		$word = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];

   		# warn $word->getForm . " (" . $word->getId . ") " . $GeniaTaggerOutput[$GeniaTaggerOutput_idx]->[0] . "\n";

		# Correct POSTag if it's named entity

		if ($word->isNE) {
		    $GeniaTaggerOutput[$GeniaTaggerOutput_idx]->[1] = "NP";
		    # $GeniaTaggerOutput[$GeniaTaggerOutput_idx]->[1] = "named_entity";
 		    # warn "Remove _ if it's a complex word i.e. a named entity\n";

		# Remove _ if it's a complex word i.e. a named entity

		    $posInLemma = 0;
		    do {
			if ((($posInLemma = index($GeniaTaggerOutput[$GeniaTaggerOutput_idx]->[2], "_"), $posInLemma) != -1) &&
			    ((($posInWord = index($GeniaTaggerOutput[$GeniaTaggerOutput_idx]->[0], "_", $posInLemma)) == -1) || 
			     ($posInLemma != $posInWord))) {
#  			    warn "lemma to correct : " . $GeniaTaggerOutput[$GeniaTaggerOutput_idx]->[2] . "\n";
			    $substringBefore = substr($GeniaTaggerOutput[$GeniaTaggerOutput_idx]->[2], 0, $posInLemma);
			    $substringAfter = substr($GeniaTaggerOutput[$GeniaTaggerOutput_idx]->[2], $posInLemma + 1);
			    
#  			    warn "New lemma : $substringBefore $substringAfter ($posInLemma)\n";
			    $GeniaTaggerOutput[$GeniaTaggerOutput_idx]->[2] = "$substringBefore $substringAfter";
			    $posInLemma++;
			}
		    } while (($posInLemma != -1) && ($posInLemma != $posInWord) && ($posInLemma < length($GeniaTaggerOutput[$GeniaTaggerOutput_idx]->[2])));
		}

		# work around some strange tagging 
# 		warn "GeniaTaggerOutput_idx: $GeniaTaggerOutput_idx\n";
		if ($GeniaTaggerOutput[$GeniaTaggerOutput_idx]->[1] eq "SENT") {
		    $GeniaTaggerOutput[$GeniaTaggerOutput_idx]->[1] = "named_entity";
		}



		my $MSFeatures = Lingua::Ogmios::Annotations::MorphosyntacticFeatures->new(
		    {'refid_word' => $word,
		     'syntactic_category' => $GeniaTaggerOutput[$GeniaTaggerOutput_idx]->[1],
		    });
		$document->getAnnotations->addMorphosyntacticFeatures($MSFeatures);
		

		my $Lemma = Lingua::Ogmios::Annotations::Lemma->new(
		    {'refid_word' => $word,
		     'canonical_form' => $GeniaTaggerOutput[$GeniaTaggerOutput_idx]->[2],
		    });
		$document->getAnnotations->addLemma($Lemma);

		$GeniaTaggerOutput_idx++;

		$doc_idx += $word->getReferenceSize - 1;
 		$token = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];

	    } else {
		if (!($token->isSep)) {
		    $GeniaTaggerOutput_idx++;
# 		    warn $token->getContent . " (" . $token->getId . ") " . $GeniaTaggerOutput[$GeniaTaggerOutput_idx]->[0] . "\n";
		}
	    }
	    if ($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId)) {
		if ($token->isSymb) {
		    if ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
			
# 		    } else {
			$GeniaTaggerOutput_idx++;
# 			warn $token->getContent . " (" . $token->getId . ") " . $GeniaTaggerOutput[$GeniaTaggerOutput_idx]->[0] . " 0 \n";
		    }
		} else {
		    $GeniaTaggerOutput_idx++;
# 		    warn ". ( 000 ) " . $GeniaTaggerOutput[$GeniaTaggerOutput_idx++]->[0] . "\n";
		}
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
	    $self->_inputGeniaTagger;

	    my $command_line = $self->_processGeniaTagger;

	    $self->_outputParsing;

	    # Put log information 
	    my $information = { 'software_name' => 'GeniaTagger',
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
	if ($self->_no_standard_output eq "IFPOSLMGT") {
	    warn "print Genia output\n";
	    open FILE_OUT, $self->_output_filename or warn "Can't open the file " . $self->_output_filename;;
	    
	    while($line = <FILE_OUT>) {
		print $line;	    
	    }
	    close FILE_OUT;
	} elsif ($self->_no_standard_output eq "VOCABULARY") {
	    $self->_printVocabulary;
	} elsif ($self->_no_standard_output eq "VOCABULARY_ALL") {
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
	} elsif ($self->_no_standard_output eq "TAGSET") {
	    $self->_printTagSet;
	} elsif ($self->_no_standard_output eq "IFPOSLM") {
# 		$self->_outputParsing;
	    $self->_printTreeTaggerFormatOutput("stdout");
	}
    } else {
    }

#     die "You call the 'rum' method of the wrapper class base\n
#          You should define a 'run' method for your wrapper\n";
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

