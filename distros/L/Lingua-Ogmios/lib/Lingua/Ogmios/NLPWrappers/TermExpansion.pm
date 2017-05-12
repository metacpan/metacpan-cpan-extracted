package Lingua::Ogmios::NLPWrappers::TermExpansion;


our $VERSION='0.1';


use Lingua::Ogmios::NLPWrappers::Wrapper;

use strict;
use warnings;

our @ISA = qw(Lingua::Ogmios::NLPWrappers::Wrapper);

sub new {
    my ($class, $config, $tmpfile_prefix, $logfile, $position, $no_standard_output) = @_;

    my $lang;
    my $lang2;
    my $resourcename;

    warn "[LOG]    Creating a wrapper of the TermExpansion\n";

    my $TermExpansion = $class->SUPER::new($config, $tmpfile_prefix, $logfile, $position, $no_standard_output);

    foreach $lang (keys %{$TermExpansion->_config->configuration->{'RESOURCE'}}) {
	if ($lang =~ /language=([\w]+)/io) {
	    $lang2 = $1;
	    foreach $resourcename (keys %{$TermExpansion->_config->configuration->{'RESOURCE'}->{$lang}}) {
		warn "*** $resourcename\n";
		if ($resourcename eq "VOCABULARY") {
		    $TermExpansion->loadVocabulary($lang, $lang2, $resourcename);
		} else {
		    $TermExpansion->addResourceSemRel($lang, $lang2, $resourcename);
		}
		# , $TermExpansion->_config->configuration->{'RESOURCE'}->{$lang}->{$resourcename});
	    }
	}
    }


    if (defined $TermExpansion->_config->configuration->{'CONFIG'}) {
	foreach $lang (keys %{$TermExpansion->_config->configuration->{'CONFIG'}}) {
	    if ($lang =~ /language=([\w]+)/io) {
		$lang2 = $1;

		$TermExpansion->_setOption($lang2, "TERMS", "TERMS", 0);
		$TermExpansion->_setOption($lang2, "EXPAND_SYNONYMY", "expand_synonymy", 0);
	    }
	}
    }

    $TermExpansion->_input_filename($tmpfile_prefix . ".TermExpansion.in");
    $TermExpansion->_output_filename($tmpfile_prefix . ".TermExpansion.out");

    return($TermExpansion);

}

sub _processTermExpansion {
    my ($self, $lang) = @_;

    warn "[LOG] TermExpansion\n";

    my $expandedSents;
    my @sents;
    my $i;
    my $semanticFeature;
    my $token;
    my $word;
    my $term;
    my $lemma;
    my $postag;
    my $document;
    my $terminology;
    my $neighbour;
    my $j = 0;
    my @selectedSynonyms;
    
    $lang = $self->_documentSet->[0]->getAnnotations->getLanguage;

    # return($self->_exec_command($self->_defineCommandLine($self->_config->commands($lang)->{TermExpansion_CMD} . " < " . $self->_input_filename . ">" . $self->_output_filename)));

    foreach $document (@{$self->_documentSet}) {
	$lang = $document->getAnnotations->getLanguage;

	@sents = @{$document->getAnnotations->getSentenceLevel->getElements};
	for($i=0; $i < scalar(@sents); $i+=2) {
	    # warn "i (sent) = $i\n";
	    # warn ">> " . $sents[$i]->getForm . "\n";
	    $semanticFeature = $sents[$i]->next->getForm;
	    $token = $sents[$i]->refid_start_token;

	    # add initialisation of the expanded sentence
	    $expandedSents = { "units" => [],
			       "expanded_forms" => [],
			       "sent_forms" => [""],
			       'semanticFeature' => $semanticFeature,
			       'initial_form' => $sents[$i]->getForm,
	    };


	    $j = 0;
	    do {
		if (($self->{"TERMS"}->{$lang}) && 
		    ($document->getAnnotations->getSemanticUnitLevel->existsElementByToken($token))) {
		    $term = $self->_getLargerTerm($document->getAnnotations->getSemanticUnitLevel->getElementByToken($token));
		    warn $term->getForm . "\n";
		    $lemma = $term->canonical_form;
		    push @{$expandedSents->{'units'}}, $term;
		    push @{$expandedSents->{'expanded_forms'}}, [$term->getForm];
########################################################################

		    if ($self->{'expand_synonymy'}->{$lang}) {
			# warn "j = $j\n";
			foreach $terminology (@{$self->{"Resources"}->{$lang}->{'SYNONYMY'}}) {
			    $self->_selectSynonyms($term->getForm, $terminology->{'synonymy'}, \@selectedSynonyms);
			    foreach $neighbour (@selectedSynonyms) {
				# warn "---> $neighbour ($i)\n";
				push @{$expandedSents->{'expanded_forms'}->[$j]}, $neighbour;
			    }
			    $self->_selectSynonyms($lemma, $terminology->{'synonymy'}, \@selectedSynonyms);
			    foreach $neighbour (@selectedSynonyms) {
				# warn "---> $neighbour ($i)\n";
				push @{$expandedSents->{'expanded_forms'}->[$j]}, $neighbour;
			    }
			}
		    }
		    $token = $term->end_token;
########################################################################
		} elsif ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
		    $word = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];
		    $lemma = $word->getLemma($document)->canonical_form; 
		    $postag = $word->getMorphoSyntacticFeatures($document)->syntactic_category; 
		    push @{$expandedSents->{'units'}}, $word;
		    push @{$expandedSents->{'expanded_forms'}}, [$word->getForm];
		    
########################################################################

		    if ($self->{'expand_synonymy'}->{$lang}) {
			# warn "j = $j\n";
			foreach $terminology (@{$self->{"Resources"}->{$lang}->{'SYNONYMY'}}) {
			    $self->_selectSynonyms($word->getForm, $terminology->{'synonymy'}, \@selectedSynonyms);
			    foreach $neighbour (@selectedSynonyms) {
				# warn "---> $neighbour ($i)\n";
				if (exists $self->{"vocabulary"}->{$neighbour}) {
				    push @{$expandedSents->{'expanded_forms'}->[$j]}, $neighbour;
				}
			    }
			    $self->_selectSynonyms($lemma, $terminology->{'synonymy'}, \@selectedSynonyms);
			    foreach $neighbour (@selectedSynonyms) {
				# warn "---> $neighbour ($i)\n";
				if (exists $self->{"vocabulary"}->{$neighbour}) {
				    push @{$expandedSents->{'expanded_forms'}->[$j]}, $neighbour;
				}
			    }
			}
		    }
		    $token = $word->end_token;
########################################################################
		} else {
		    # put in the sets
		    push @{$expandedSents->{'units'}}, $token;
		    push @{$expandedSents->{'expanded_forms'}}, [$token->getContent];
		}
		$j++;
		$token = $token->next;
		# }
	    } while((defined $token) && (!$token->previous->equals($sents[$i]->refid_end_token)));
	    # Generate Sentence Form
	    $self->_sentenceFormGeneration($expandedSents);
	    $self->_printExpandedSentences($expandedSents);
	}

    }
    warn "[LOG]\n";
}

sub _sentenceFormGeneration {
    my ($self, $expandedSents) = @_;

    warn "Generation of the Sentence Forms\n";
    my $j = 0;
    my $i = 0;
    
    # for($j=0;$j < scalar(@{$expandedSents});$j++) {    
	# warn "sentence $j\n";
    # warn ">> " . $expandedSents->{'initial_form'} . "\n";
	$i = 0;
    # ->[$j]
 	$self->_recursiveGen($expandedSents, $i);
    # }
}

sub _recursiveGen {
    my ($self, $expandedSent, $i) = @_;

    my @new_forms;
    my $expandedForm;
    my $sentForm;

    # warn "i: $i\n";
    # warn "max: " . scalar(@{$expandedSent->{'expanded_forms'}}) . "\n";

    if ($i < scalar(@{$expandedSent->{'expanded_forms'}})) {

	# warn "\tmax$i: " . scalar(@{$expandedSent->{'expanded_forms'}->[$i]}) . "\n";
	foreach $expandedForm (@{$expandedSent->{'expanded_forms'}->[$i]}) {
	    # warn "$expandedForm\n";
	    foreach $sentForm (@{$expandedSent->{'sent_forms'}}) {
		# warn "$sentForm\n";
		push @new_forms, $sentForm . $expandedForm;
	    }
	}
	@{$expandedSent->{'sent_forms'}} = @new_forms;
	# warn "==\n";
	# warn join("\n", @{$expandedSent->{'sent_forms'}}) . "\n";
	$self->_recursiveGen($expandedSent, $i+1);
    }
}

sub _printExpandedSentences {
    my ($self, $expandedSents) = @_;

    my $i;
    my $j;

#    for($i=0;$i < scalar(@{$expandedSents});$i++) {    
	# warn "sentence $j\n";
	# warn ">> " . $expandedSents->[$j]->{'initial_form'} . "\n";
	# $i = 0;
	foreach($j=0;$j < scalar(@{$expandedSents->{'sent_forms'}}); $j++) {
	    print $expandedSents->{'sent_forms'}->[$j] . " : : " . $expandedSents->{'semanticFeature'} . " : \n";
	}
#    }
}


sub _inputTermExpansion {
    my ($self) = @_;

    warn "[LOG] making TermExpansion input\n";
    
    warn "[LOG] done\n";
}


sub _outputTermExpansion {
    my ($self) = @_;

    warn "[LOG] . Parsing " . $self->_output_filename . "\n";

    warn "[LOG] done\n";
}

sub run {
    my ($self, $documentSet) = @_;

    # Set variables according the the configuration

    $self->_documentSet($documentSet);

    warn "[LOG] " . $self->_config->comments . " ...     \n";

    $self->_inputTermExpansion;

    my $command_line = $self->_processTermExpansion;

#     if ($self->_position eq "last") {
# 	# TODO
    if (($self->_position eq "last") && ($self->_no_standard_output)) {
	warn "print no standard output\n";
    } else {
	$self->_outputTermExpansion;
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

sub loadVocabulary {
    my ($self, $lang, $lang2, $type) = @_;

    my $exceptionFilename;
    if (ref($self->_config->configuration->{'RESOURCE'}->{$lang}->{$type}) eq "ARRAY") {
	foreach $exceptionFilename (@{$self->_config->configuration->{'RESOURCE'}->{$lang}->{$type}}) {
	    $self->_loadException($exceptionFilename, $lang2,"vocabulary");
	}
    } else {
	$self->_loadException($self->_config->configuration->{'RESOURCE'}->{$lang}->{$type}, $lang2, "vocabulary");
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

