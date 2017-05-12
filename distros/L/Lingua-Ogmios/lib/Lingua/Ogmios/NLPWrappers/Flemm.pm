package Lingua::Ogmios::NLPWrappers::Flemm;


our $VERSION='0.1';


use Lingua::Ogmios::NLPWrappers::Wrapper;

use strict;
use warnings;

our @ISA = qw(Lingua::Ogmios::NLPWrappers::Wrapper);

sub new {
    my ($class, $config, $tmpfile_prefix, $logfile, $position, $no_standard_output) = @_;

    warn "[LOG]    Creating a wrapper of the Flemm\n";


    my $Flemm = $class->SUPER::new($config, $tmpfile_prefix, $logfile, $position, $no_standard_output);

    $Flemm->_input_filename($tmpfile_prefix . ".Flemm.in");
    $Flemm->_output_filename($tmpfile_prefix . ".Flemm.out");

    return($Flemm);

}

sub _processFlemm {
    my ($self, $lang) = @_;

    warn "[LOG] Flemm\n";

    $lang = $self->_documentSet->[0]->getAnnotations->getLanguage;

    my $perlModule = $self->_config->commands($lang)->{PerlModule};

    eval "require $perlModule";

    return($self->_exec_command($self->_defineCommandLine($self->_config->commands($lang)->{FLEMM_CMD} . " " . $self->_config->commands($lang)->{FLEMM_IN_PARAMETERS} . " " . $self->_input_filename . " " . $self->_config->commands($lang)->{FLEMM_OUT_PARAMETERS} . " "  . $self->_output_filename)));

    warn "[LOG]\n";
}

sub _inputFlemm {
    my ($self) = @_;

    warn "[LOG] making Flemm input\n";

    $self->_printTreeTaggerFormatOutput($self->_input_filename, 'LATIN1');
    
    warn "[LOG] done\n";
}


sub _outputFlemm {
    my ($self) = @_;


    warn "[LOG] . Parsing " . $self->_output_filename . "\n";

    $self->_parseTreeTaggerFormatOutput($self->_output_filename, 1);

    warn "[LOG] done\n";
}

sub run {
    my ($self, $documentSet) = @_;

    # Set variables according the the configuration

    $self->_documentSet($documentSet);

    warn "[LOG] " . $self->_config->comments . " ...     \n";

    $self->_inputFlemm;

    my $command_line = $self->_processFlemm;

#     if ($self->_position eq "last") {
# 	# TODO

    $self->_outputFlemm;
    # Put log information 

    my $information = { 'software_name' => $self->_config->name,
			'comments' => $self->_config->comments,
			'command_line' => $command_line,
			'list_modified_level' => ['morphosyntactic_features_level', 'lemma_level'],
    };
    $self->_log($information);


    if (($self->_position eq "last") && ($self->_no_standard_output)) {
	if ($self->_no_standard_output eq "IFPOSLM") {
	    $self->_printTreeTaggerFormatOutput('stdout', 'LATIN1',0);
	    warn "print no standard output\n";
	    # my $document;
	    # my $word;
	    # my $MS_features;
	    # foreach $document (@{$documentSet}) {
	    # 	foreach $word (@{$document->getAnnotations->getWordLevel->getElements}) {
	    # 	print $word->getForm . "\t";
	    # 	print $document->getAnnotations->getLemmaLevel->getElementFromIndex("refid_word", $word->getId)->[0]->canonical_form;
	    # 	if (($self->_no_standard_output == 2) || ($self->_no_standard_output == 3)) {
	    # 	    print "\t" . $document->getAnnotations->getMorphosyntacticFeaturesLevel->getElementFromIndex("refid_word", $word->getId)->[0]->syntactic_category;
	    # 	}
	    # 	print "\n";
	    # 	}
	    # }
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
		    do {
		    if ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) {
			$word = $document->getAnnotations->getWordLevel->getElementFromIndex("list_refid_token", $token->getId)->[0];
			$lemma = $document->getAnnotations->getLemmaLevel->getElementFromIndex("refid_word", $word->getId)->[0];
			$MS_features = $document->getAnnotations->getMorphosyntacticFeaturesLevel->getElementFromIndex("refid_word", $word->getId)->[0];
			push @word_set, $word->getForm;
			push @MS_features_set, $MS_features->syntactic_category;
			push @lemma_set, $lemma->canonical_form;
			$token = $word->end_token;
		    }
		    if (!$token->equals($token_end)) {
			$token = $token->next;
		    }
		    } while (!$token->equals($token_end));
# 		    foreach $word (@{$document->getAnnotations->getWordLevel->getElements}) {
		    # print $word->getForm . "\t";
		    # print $document->getAnnotations->getLemmaLevel->getElementFromIndex("refid_word", $word->getId)->[0]->canonical_form;
		    # if (($self->_no_standard_output == 2) || ($self->_no_standard_output == 3) || ($self->_no_standard_output eq "IFLMPOS")) {
		    # 	print "\t" . $document->getAnnotations->getMorphosyntacticFeaturesLevel->getElementFromIndex("refid_word", $word->getId)->[0]->syntactic_category;
		    # }
		    print join(" ", @word_set);
		    print "\t";
		    print join(" ", @MS_features_set);
		    print "\t";
		    print join(" ", @lemma_set);
		    print "\n";
		}
	    }

	}
#    } else {
    }
#     $self->_outputParsing;


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

