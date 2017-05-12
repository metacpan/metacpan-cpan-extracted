package Lingua::Ogmios::NLPWrappers::PorterStemmer;


our $VERSION='0.1';

use Lingua::Ogmios::NLPWrappers::Wrapper;

use Lingua::Ogmios::Annotations::Stem;

use strict;
use warnings;

our @ISA = qw(Lingua::Ogmios::NLPWrappers::Wrapper);

sub new {
    my ($class, $config, $tmpfile_prefix, $logfile, $position, $no_standard_output) = @_;

    warn "[LOG]    Creating a wrapper of the " .  $config->comments . "\n";


    my $PorterStemmer = $class->SUPER::new($config, $tmpfile_prefix, $logfile, $position, $no_standard_output);

    my @tmpin;
#    my @tmpout;

    $PorterStemmer->_input_array(\@tmpin);
#    $PorterStemmer->_output_array(\@tmpout);

    return($PorterStemmer);

}

sub _processPorterStemmer {
    my ($self, $lang) = @_;

    warn "[LOG] " . $self->_config->comments . "\n";

    $lang = $self->_documentSet->[0]->getAnnotations->getLanguage;

    my $perlModule = $self->_config->commands($lang)->{PerlModule};

    eval "require $perlModule";
    if ($@) {
	warn $@ . "\n";
	die "Problem while loading perlModule $perlModule - Abort\n\n";
    } else {
	warn "Run Module $perlModule\n";

	my $stemmer = Lingua::Stem->new(-locale => $lang);
	$stemmer->stem_caching({ -level => 2 });
	my $tmparray = $stemmer->stem(@{$self->_input_array});
	$self->_output_array($tmparray);

# 	foreach my $stem (@$tmparray) {
# 	    warn "$stem\n";
# 	}

    }
    warn "[LOG]\n";
    return($perlModule);
}

sub _inputPorterStemmer {
    my ($self) = @_;

    my $token;
    my $next_token;
    my $document;
    my $doc_idx;

    my @corpus_in_t;

    my $word;
    warn "[LOG] making input\n";
    
    foreach $document (@{$self->_documentSet}) {
	for($doc_idx = 0; $doc_idx < scalar(@{$document->getAnnotations->getTokenLevel->getElements});$doc_idx++) {
	    $token = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];
	    if ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
		$word = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];
		push @corpus_in_t, $word->getForm;

		$doc_idx += $word->getReferenceSize - 1;
 		$token = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];
	    } else {
		if (!($token->isSep)) {
			push @corpus_in_t, $token->getContent;
		}
	    }
	    if ($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId)) {
		if ($token->isSymb) {
		    if (!($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId))) {
			$corpus_in_t[$#corpus_in_t] .= "\tSENT";
		    } else {
			push @corpus_in_t, $token->getContent . "\tSENT";
		    }
		} else {
		    push @corpus_in_t, ".\tSENT";
		}
	    }
	}
    }

    push @{$self->_input_array}, @corpus_in_t;
    
    warn "[LOG] done\n";
}


sub _outputParsing {
    my ($self) = @_;

    my $line;

    my $stems;

    my $doc_idx;
    my $word_idx;
    my $document;

    my $word;
    my $token;

    my $posInWord;
    my $posInLemma;

    my $substringBefore;
    my $substringAfter;

    warn "[LOG] . Parsing Output Array\n";

    $stems = $self->_output_array;

    my $StemOutput_idx = 0;

    foreach $document (@{$self->_documentSet}) {
	for($doc_idx = 0; $doc_idx < scalar(@{$document->getAnnotations->getTokenLevel->getElements});$doc_idx++) {
	    $token = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];
	    if ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
		$word = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];
		# Correct POSTag if it's named entity
		my $Stem = Lingua::Ogmios::Annotations::Stem->new(
		    {'refid_word' => $word,
		     'stem_form' => $stems->[$StemOutput_idx],
		    });
		$document->getAnnotations->addStem($Stem);

		$StemOutput_idx++;

		$doc_idx += $word->getReferenceSize - 1;
 		$token = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];

	    } else {
		if (!($token->isSep)) {
		    $StemOutput_idx++;
		}
	    }
	    if ($document->getAnnotations->getSentenceLevel->existsElementFromIndex("refid_end_token", $token->getId)) {
		if ($token->isSymb) {
		    if ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
			$StemOutput_idx++;
		    }
		} else {
		    $StemOutput_idx++;
		}
	    }
	}
    }
    warn "[LOG] done\n";
}

sub run {
    my ($self, $documentSet) = @_;

    # Set variables according the the configuration
    $self->_documentSet($documentSet);

    if ($documentSet->[0]->getAnnotations->existsStemLevel) {
	warn "stems exist in the first document\n";
	warn "  Assuming that no stem idenfication is required for the current document set\n";
#	return(0);
    } else {
	warn "[LOG] " . $self->_config->comments . " ...     \n";
	
	$self->_inputPorterStemmer;
	
	my $command_line = $self->_processPorterStemmer;
	$self->_outputParsing;

	# Put log information 
	my $information = { 'software_name' => $self->_config->name,
			    'comments' => $self->_config->comments,
			    'command_line' => $command_line,
			    'list_modified_level' => ['stem_level'],
	};
    
	$self->_log($information);

	my $document;
	foreach $document (@{$documentSet}) {
	    $document->getAnnotations->addLogProcessing(
		Lingua::Ogmios::Annotations::LogProcessing->new(
		    { 'comments' => 'Found ' . $document->getAnnotations->getStemLevel->getSize . ' stem\n',
		    }
		)
		);
	    # basic check 
	    if ($document->getAnnotations->getStemLevel->getSize != $document->getAnnotations->getWordLevel->getSize) {
		warn "Document " . $document->getId . ": there is difference between word and stem size\n";
	    }
	}    
    }	
    if (($self->_position eq "last") && ($self->_no_standard_output)) {
	warn "print no standard output\n";
    }
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

