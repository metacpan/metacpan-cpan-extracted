package Lingua::Ogmios::NLPWrappers::Distribution;


our $VERSION='0.1';


use Lingua::Ogmios::NLPWrappers::Wrapper;

use strict;
use warnings;

our @ISA = qw(Lingua::Ogmios::NLPWrappers::Wrapper);

sub new {
    my ($class, $config, $tmpfile_prefix, $logfile, $position, $no_standard_output) = @_;

    my $lang;
    my $lang2;

    warn "[LOG]    Creating a wrapper of the Distribution\n";

    my $Distribution = $class->SUPER::new($config, $tmpfile_prefix, $logfile, $position, $no_standard_output);

    if (defined $Distribution->_config->configuration->{'CONFIG'}) {
	foreach $lang (keys %{$Distribution->_config->configuration->{'CONFIG'}}) {
	    if ($lang =~ /language=([\w]+)/io) {
		$lang2 = $1;
		if (defined $Distribution->_config->configuration->{'CONFIG'}->{$lang}->{"PRINTTERM"}) {
		    $Distribution->{'printTerm'}->{$lang2} = $Distribution->_config->configuration->{'CONFIG'}->{$lang}->{"PRINTTERM"};
		}
		if (defined $Distribution->_config->configuration->{'CONFIG'}->{$lang}->{"ALLTAGS"}) {
		    $Distribution->{'allTags'}->{$lang2} = $Distribution->_config->configuration->{'CONFIG'}->{$lang}->{"ALLTAGS"};
		} else {
		    $Distribution->{'allTags'}->{$lang2} = 1;
		}
		if (defined $Distribution->_config->configuration->{'CONFIG'}->{$lang}->{"ALLTAGSCTXT"}) {
		    $Distribution->{'allTagsCtxt'}->{$lang2} = $Distribution->_config->configuration->{'CONFIG'}->{$lang}->{"ALLTAGSCTXT"};
		} else {
		    $Distribution->{'allTagsCtxt'}->{$lang2} = 1;
		}
		if (defined $Distribution->_config->configuration->{'CONFIG'}->{$lang}->{"ALLWORDCOUNT"}) {
		    $Distribution->{'allWordCount'}->{$lang2} = $Distribution->_config->configuration->{'CONFIG'}->{$lang}->{"ALLWORDCOUNT"};
		} else {
		    $Distribution->{'allWordCount'}->{$lang2} = 1;
		}
		if (defined $Distribution->_config->configuration->{'CONFIG'}->{$lang}->{"BEFOREWINDOWSIZE"}) {
		    $Distribution->{'BeforeWindowSize'}->{$lang2} = $Distribution->_config->configuration->{'CONFIG'}->{$lang}->{"BEFOREWINDOWSIZE"};
		}
		if (defined $Distribution->_config->configuration->{'CONFIG'}->{$lang}->{"AFTERWINDOWSIZE"}) {
		    $Distribution->{'AfterWindowSize'}->{$lang2} = $Distribution->_config->configuration->{'CONFIG'}->{$lang}->{"AFTERWINDOWSIZE"};
		}
		if (defined $Distribution->_config->configuration->{'CONFIG'}->{$lang}->{"TERMINCONTEXT"}) {
		    $Distribution->{'termInContext'}->{$lang2} = $Distribution->_config->configuration->{'CONFIG'}->{$lang}->{"TERMINCONTEXT"};
		}
		if ((defined $Distribution->_config->configuration->{'CONFIG'}->{$lang}->{"POSTAGLIST"}) &&
		    (defined $Distribution->_config->configuration->{'CONFIG'}->{$lang}->{"POSTAGLIST"}->{'POSTAG'})) {
		    if (ref($Distribution->_config->configuration->{'CONFIG'}->{$lang}->{"POSTAGLIST"}->{'POSTAG'}) eq "ARRAY") {
			$Distribution->{'POSTAGS'}->{$lang2} = [];
			push @{$Distribution->{'POSTAGS'}->{$lang2}}, @{$Distribution->_config->configuration->{'CONFIG'}->{$lang}->{"POSTAGLIST"}->{'POSTAG'}};
		    } else {
			push @{$Distribution->{'POSTAGS'}->{$lang2}}, $Distribution->_config->configuration->{'CONFIG'}->{$lang}->{"POSTAGLIST"}->{'POSTAG'};
		    }
		} else {
		    $Distribution->{'allTags'}->{$lang2} = 1;
		}

		if ((defined $Distribution->_config->configuration->{'CONFIG'}->{$lang}->{"POSTAGCTXTLIST"}) &&
		    (defined $Distribution->_config->configuration->{'CONFIG'}->{$lang}->{"POSTAGCTXTLIST"}->{'POSTAG'})) {
		    if (ref($Distribution->_config->configuration->{'CONFIG'}->{$lang}->{"POSTAGCTXTLIST"}->{'POSTAG'}) eq "ARRAY") {
			$Distribution->{'POSTAGCTXT'}->{$lang2} = [];
			push @{$Distribution->{'POSTAGCTXT'}->{$lang2}}, @{$Distribution->_config->configuration->{'CONFIG'}->{$lang}->{"POSTAGCTXTLIST"}->{'POSTAG'}};
		    } else {
			push @{$Distribution->{'POSTAGCTXT'}->{$lang2}}, $Distribution->_config->configuration->{'CONFIG'}->{$lang}->{"POSTAGCTXTLIST"}->{'POSTAG'};
		    }
		} else {
		    $Distribution->{'allTagsCtxt'}->{$lang2} = 1;
		}
	    }
	}
    # } else {
    # 	$Distribution->{'sentenceSeparatorCharList'}->{"FR"} = "?.!";
    # 	$Distribution->{'sentenceSeparatorCharList'}->{"EN"} = "?.!";	
    }

    $Distribution->_input_filename($tmpfile_prefix . ".Distribution.in");
    $Distribution->_output_filename($tmpfile_prefix . ".Distribution.out");


    return($Distribution);

}

sub _processDistribution {
    my ($self, $lang) = @_;

    warn "[LOG] Distribution\n";

    $lang = $self->_documentSet->[0]->getAnnotations->getLanguage;

    return($self->_exec_command($self->_defineCommandLine($self->_config->commands($lang)->{Distribution_CMD} . " < " . $self->_input_filename . ">" . $self->_output_filename)));

    warn "[LOG]\n";
}

sub _inputDistribution {
    my ($self) = @_;

    warn "[LOG] making Distribution input\n";
    
    warn "[LOG] done\n";
}


sub _outputDistribution {
    my ($self) = @_;

    warn "[LOG] . Parsing " . $self->_output_filename . "\n";

    warn "[LOG] done\n";
}

sub run {
    my ($self, $documentSet) = @_;

    # Set variables according the the configuration

    $self->_documentSet($documentSet);

    warn "[LOG] " . $self->_config->comments . " ...     \n";

#    $self->_inputDistribution;

    my $command_line = "";
#    my $command_line = $self->_processDistribution;

#     if ($self->_position eq "last") {
# 	# TODO
    if (($self->_position eq "last") && ($self->_no_standard_output)) {
	warn "print no standard output\n";
	if ($self->_no_standard_output eq "GW") {
	    $self->graphicalWindow();
	}
    } else {
#	$self->_outputDistribution;
    }
#     $self->_outputParsing;


    # Put log information 

    my $information = { 'software_name' => $self->_config->name,
			'comments' => $self->_config->comments,
			'command_line' => $command_line,
			'list_modified_level' => [''],
    };
    $self->_log($information);


#     die "You call the 'rum' method of the wrapper class base\n
#          You should define a 'run' method for your wrapper\n";
    warn "[LOG] done\n";
}

sub graphicalWindow {
    my ($self) = @_;

    my $token;
    my $currentToken;
    my $document;
#    my $doc_idx;
    my @context;
    my $word;
    my $semanticUnit;
    my $currentUnit;
    my $i;
    my $type;
    my $canonical_form;
    my $postag;
    my $form;
    my $lang;

    foreach $document (@{$self->_documentSet}) {
	$lang  = $document->getAnnotations->getLanguage;
	$currentToken = $document->getAnnotations->getTokenLevel->getElements->[0];
	while(defined $currentToken) {
	# for($doc_idx = 0; $doc_idx < scalar(@{$document->getAnnotations->getTokenLevel->getElements});$doc_idx++) {
#	    $currentToken = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];
	    if (($self->_printTerm($lang)) && ($document->getAnnotations->getSemanticUnitLevel->existsElementByToken($currentToken))) {
		$currentUnit = $self->_getLargerTerm($document->getAnnotations->getSemanticUnitLevel->getElementByToken($currentToken));
		$token = $currentUnit->end_token;
		$type = "TERM";
		$canonical_form = $self->_getCanonicalForm($currentUnit, $document);
		# if (!defined $currentUnit->canonical_form) {
		#     $canonical_form = "";
		# } else {
		#     $canonical_form = $currentUnit->canonical_form;
		# }
		if ($currentUnit->isNamedEntity) {
		    $postag = "named_entity";		    
		} else {
		    $postag = "term";
		}
	    } elsif ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $currentToken->getId)) {
		$currentUnit = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $currentToken->getId)->[0];
#		$doc_idx += $currentUnit->getReferenceSize - 1;
		$token = $currentUnit->end_token;
		$type = "WORD";
		$canonical_form = $document->getAnnotations->getLemmaLevel->getElementFromIndex("refid_word", $currentUnit->getId)->[0]->canonical_form;
		$postag = $document->getAnnotations->getMorphosyntacticFeaturesLevel->getElementFromIndex("refid_word", $currentUnit->getId)->[0]->syntactic_category;
		if (!($self->_selectedPOSTAG($lang, $postag))) {
		    $currentUnit = undef;
		    $token = $currentToken;
		}
	    } else {
		$token = $currentToken;
	    }
	    if (defined $currentUnit) {
		@context = @{$self->getContextBefore($document, $currentToken)};
		for($i = 0; $i < scalar(@context) ; $i++) {
		    print $currentUnit->getForm . "\t$postag\t$canonical_form\t" .  join("\t", @{$context[$i]}) . "\tBefore\t" . ($i+1). "\t$type\n" 
		}
#		@context = @{$self->getContextAfter($document, $currentToken)};
		@context = @{$self->getContextAfter($document, $currentUnit->end_token)};
		for($i = 0; $i < scalar(@context) ; $i++) {
			print $currentUnit->getForm . "\t$postag\t$canonical_form\t" .  join("\t", @{$context[$i]}) . "\tAfter\t" . ($i+1). "\t$type\n" 
		}
		print "\n";
		$currentUnit = undef;
	    }
	    $currentToken = $token->next;
	}
    }

}

sub getContextBefore {
    my ($self, $document, $currentToken) = @_;

    my $token;
    my @context;
    my $size = 0;
    my $currentUnit;
    my $postag;
    my $canonical_form;
    my $lang  = $document->getAnnotations->getLanguage;
    my $windowSize = $self->{'BeforeWindowSize'}->{$lang};

    $token = $currentToken;
    while((defined $token->previous) && 
	  ($size < $windowSize) &&
	  (!$document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_start_token", $token->getId))
	  ){
	do {
	    $token = $token->previous;
	    
	} while((defined $token->previous) &&
		# ($token->isSep) &&
		(!$document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) &&
		(!(($self->_termInContext($lang)) && ($document->getAnnotations->getSemanticUnitLevel->existsElementByToken($token)))) &&
		(!$document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_start_token", $token->getId))
	    );

# ->getElementByToken($token)

	if (defined $token->previous) {
	    if (($self->_termInContext($lang)) && ($document->getAnnotations->getSemanticUnitLevel->existsElementByToken($token))) {
		$currentUnit = $self->_getLargerTerm($document->getAnnotations->getSemanticUnitLevel->getElementByToken($token));

		if ($currentUnit->isNamedEntity) {
		    $postag = "named_entity";		    
		    $canonical_form = $self->_getCanonicalForm($currentUnit, $document);
		    # $canonical_form = $currentUnit->getForm;
		} else {
		    $postag = "term";
		    $canonical_form = $self->_getCanonicalForm($currentUnit, $document);
		    # $canonical_form = $currentUnit->canonical_form;
		}
		push @context, [$currentUnit->getForm, $postag, $canonical_form];

		$size++;
		$token = $currentUnit->start_token;		
	    } elsif ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
		# warn "$size\n";
		$currentUnit = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];
		$postag = $document->getAnnotations->getMorphosyntacticFeaturesLevel->getElementFromIndex("refid_word", $currentUnit->getId)->[0]->syntactic_category;
		if ($self->_selectedPOSTAGCTXT($lang, $postag)) {
		    push @context, [$currentUnit->getForm, 
				    $postag,
				    $document->getAnnotations->getLemmaLevel->getElementFromIndex("refid_word", $currentUnit->getId)->[0]->canonical_form];
		    if ($self->{'allWordCount'}->{$lang} == 0) {$size++;}
		}
		if ($self->{'allWordCount'}->{$lang} == 1) {$size++;}
		$token = $currentUnit->start_token;
	    }
	}
    }

    return(\@context);
}

sub getContextAfter {
    my ($self, $document, $currentToken) = @_;

    my $token;
    my @context;
    my $size = 0;
    my $currentUnit;
    my $postag;
    my $canonical_form;
    my $lang  = $document->getAnnotations->getLanguage;
    my $windowSize = $self->{'AfterWindowSize'}->{$lang};

    $token = $currentToken;
    while((defined $token->next) && 
	  ($size < $windowSize) &&
	  (!$document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId))
	) {
	do {
	    $token = $token->next;
	    # print $token->getContent;
	} while((defined $token->next) &&
		# ($token->isSep) &&
		(!$document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) &&
		((!($self->_termInContext($lang)) && ($document->getAnnotations->getSemanticUnitLevel->existsElementByToken($token)))) &&
		(!$document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId))
		
	    );
	if (defined $token->next) {
	    if (($self->_termInContext($lang)) && ($document->getAnnotations->getSemanticUnitLevel->existsElementByToken($token))) {
		$currentUnit = $self->_getLargerTerm($document->getAnnotations->getSemanticUnitLevel->getElementByToken($token));
		if ($currentUnit->isNamedEntity) {
		    $postag = "named_entity";		    
		    $canonical_form = $self->_getCanonicalForm($currentUnit, $document);
		    # $canonical_form = $currentUnit->getForm;
		} else {
		    $postag = "term";
		    $canonical_form = $self->_getCanonicalForm($currentUnit, $document);
		    # $canonical_form = $currentUnit->canonical_form;
		}
		push @context, [$currentUnit->getForm, $postag, $canonical_form];

		$size++;
		$token = $currentUnit->end_token;		
	    } elsif ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
		# print " $size ";
		# warn "$size\n";
		$currentUnit = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];
		$postag = $document->getAnnotations->getMorphosyntacticFeaturesLevel->getElementFromIndex("refid_word", $currentUnit->getId)->[0]->syntactic_category;
		if ($self->_selectedPOSTAGCTXT($lang, $postag)) {
		    push @context, [$currentUnit->getForm, 
				    $postag,
				    $document->getAnnotations->getLemmaLevel->getElementFromIndex("refid_word", $currentUnit->getId)->[0]->canonical_form];
		    
		    if ($self->{'allWordCount'}->{$lang} == 0) {$size++;}
		}
		if ($self->{'allWordCount'}->{$lang} == 1) {$size++;}
		$token = $currentUnit->end_token;

	    }
	}
    }
    # print "\n";
    return(\@context);
}

sub _printTerm {
    my ($self, $lang) = @_;

    if (exists $self->{'printTerm'}->{$lang}) {
	return($self->{'printTerm'}->{$lang});
    } else {
	return(0);
    }
}

sub _termInContext {
    my ($self, $lang) = @_;

    if (exists $self->{'termInContext'}->{$lang}) {
	return($self->{'termInContext'}->{$lang});
    } else {
	return(0);
    }
}

sub _selectedPOSTAG {
    my ($self, $lang, $postag) = @_;

    my $postagRE;

    if ((!defined($self->{'allTags'}->{$lang})) || ($self->{'allTags'}->{$lang} == 1)) {
	return(1);
    } else {
	foreach $postagRE (@{$self->{'POSTAGS'}->{$lang}}) {
	    if ($postag =~ /^$postagRE$/) {
		return(1);
	    }
	}
    }
    return(0);
}

sub _selectedPOSTAGCTXT {
    my ($self, $lang, $postag) = @_;

    my $postagRE;

    if ((!defined($self->{'allTagsCtxt'}->{$lang})) || ($self->{'allTagsCtxt'}->{$lang} == 1)) {
	return(1);
    } else {
	foreach $postagRE (@{$self->{'POSTAGCTXT'}->{$lang}}) {
	    if ($postag =~ /^$postagRE$/) {
		return(1);
	    }
	}
    }
    return(0);
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

