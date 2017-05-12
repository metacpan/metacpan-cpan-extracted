package Lingua::Ogmios::NLPWrappers::MarkerDetection;


our $VERSION='0.1';


use Lingua::Ogmios::NLPWrappers::Wrapper;

use strict;
use warnings;

our @ISA = qw(Lingua::Ogmios::NLPWrappers::Wrapper);

sub new {
    my ($class, $config, $tmpfile_prefix, $logfile, $position, $no_standard_output) = @_;

    warn "[LOG]    Creating a wrapper of the MarkerDetection\n";


    my $MarkerDetection = $class->SUPER::new($config, $tmpfile_prefix, $logfile, $position, $no_standard_output);

    $MarkerDetection->_input_filename($tmpfile_prefix . ".MarkerDetection.in");
    $MarkerDetection->_output_filename($tmpfile_prefix . ".MarkerDetection.out");

    return($MarkerDetection);

}

sub _processMarkerDetection {
    my ($self, $lang) = @_;

    warn "[LOG] POS tagger\n";

    $lang = $self->_documentSet->[0]->getAnnotations->getLanguage;

    return($self->_exec_command($self->_defineCommandLine($self->_config->commands($lang)->{MarkerDetection_CMD} . " < " . $self->_input_filename . ">" . $self->_output_filename)));

    warn "[LOG]\n";
}

sub _inputMarkerDetection {
    my ($self) = @_;

    warn "[LOG] making MarkerDetection input\n";
    
    warn "[LOG] done\n";
}


sub _outputMarkerDetection {
    my ($self) = @_;

    warn "[LOG] . Parsing " . $self->_output_filename . "\n";

    warn "[LOG] done\n";
}

sub run {
    my ($self, $documentSet) = @_;

    # Set variables according the the configuration

    $self->_documentSet($documentSet);

    warn "[LOG] " . $self->_config->comments . " ...     \n";

    $self->_inputMarkerDetection;

    my $command_line = $self->_processMarkerDetection;

#     if ($self->_position eq "last") {
# 	# TODO
    if (($self->_position eq "last") && ($self->_no_standard_output)) {
	warn "print no standard output\n";
    } else {
	$self->_outputMarkerDetection;
    }
#     $self->_outputParsing;


    # Put log information 

    my $information = { 'software_name' => $self->_config->name,
			'comments' => $self->_config->comments,
			'command_line' => $command_line,
    };
    $self->_log($information);


#     die "You call the 'rum' method of the wrapper class base\n
#          You should define a 'run' method for your wrapper\n";
    warn "[LOG] done\n";
}


sub checkMarkerFromTagSuffix {
    my ($self, $term, $tagSuffix, $document, $windowLimitFrom, $windowLimitTo, $wordLimit) = @_;

    return($self->checkMarkerInContext($term, $tagSuffix, $document, $windowLimitFrom, $windowLimitTo, $wordLimit));
}

sub checkMarkerInContext {

    my ($self, $term, $tagSuffix, $document, $windowLimitFrom, $windowLimitTo, $wordLimit) = @_;

    my $token;
    my $tmpTerm;

#     my @windowLimits = $self->getWindowLimits($term, $lineIdx, $tmpTermIdx, $document);

    my %words;

    $token = $term->start_token;

    my $markerInContext = 0;

#     warn "Search $tagSuffix around " . $token->getContent . "\n";
    # check after\n";

     while(($token->getFrom <= $windowLimitTo->getTo) && (scalar(keys %words) <= $wordLimit)) {
	my @words = @{$document->getAnnotations->getWordLevel->getElementByToken($token)}; 
	if (scalar(@words) > 0) {
	    $words{$words[0]->getId}++;
	}
	foreach $tmpTerm (@{$document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)}) {
#   		warn "\t" . $tmpTerm->getForm . "\n";
	    if ($tmpTerm->isTerm) {
#    		warn "\t" . $tmpTerm->getForm . " : " . $tmpTerm->start_token->getFrom . "\n";
		my $semf = $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $tmpTerm->getId)->[0];
# 		warn "$semf\n";
		    if ((defined $semf) && ($semf->first_node_first_semantic_category eq "post-$tagSuffix")) {
 			warn "find post-$tagSuffix (a) : " . $tmpTerm->getForm . "(" . $tmpTerm->start_token->getFrom . ")\n";
			$markerInContext = 1;
# 			push @reasons, $tmpTerm;
			$token = $tmpTerm->end_token;
		    }
		}
	    }
# 	}
 	$token = $token->next;
     } 

    $token = $term->start_token;
    %words = ();
     while(($token->getTo >= $windowLimitFrom->getFrom) && (scalar(keys %words) <= $wordLimit)) {
#  	warn "token: " . $token->getContent . "(" . $token->getTo . ")\n";
	my @words = @{$document->getAnnotations->getWordLevel->getElementByToken($token)}; 
# 	warn "words: " . scalar(@words) . "\n";
	if (scalar(@words) > 0) {
	    $words{$words[0]->getId}++;
	}
 	foreach $tmpTerm (@{$document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)}) {
 	    if ($tmpTerm->isTerm) {
#    		warn "\t" . $tmpTerm->getForm . " : " . $tmpTerm->start_token->getFrom . "\n";
 		my $semf = $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $tmpTerm->getId)->[0];
# # 		warn "$semf\n";
 		    if ((defined $semf) && ($semf->first_node_first_semantic_category eq "pre-$tagSuffix")) {
 			warn "find pre-$tagSuffix (b) : " . $tmpTerm->getForm . "(" . $tmpTerm->start_token->getFrom . ")\n";
# 			push @reasons, $tmpTerm;
			$markerInContext = 1;
 			$token = $tmpTerm->start_token;
 		    }
	    }
	}
 	$token = $token->previous;
     } ;

    return($markerInContext)
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

