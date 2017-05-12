package Lingua::Ogmios::NLPWrappers::TermMeasures;


our $VERSION='0.1';


use Lingua::Ogmios::NLPWrappers::Wrapper;

use Math::Trig;
use strict;
use warnings;

our @ISA = qw(Lingua::Ogmios::NLPWrappers::Wrapper);

sub new {
    my ($class, $config, $tmpfile_prefix, $logfile, $position, $no_standard_output) = @_;

    my $lang;
    my $lang2;

    warn "[LOG]    Creating a wrapper of the TermMeasures\n";

    my $TermMeasures = $class->SUPER::new($config, $tmpfile_prefix, $logfile, $position, $no_standard_output);

    # if (defined $TermMeasures->_config->configuration->{'CONFIG'}) {
    # 	foreach $lang (keys %{$TermMeasures->_config->configuration->{'CONFIG'}}) {
    # 	    if ($lang =~ /language=([\w]+)/io) {
    # 		$lang2 = $1;

    # 		if (defined $TermMeasures->_config->configuration->{'CONFIG'}->{$lang}->{"OPTION"}) {
    # 		    $TermMeasures->{'parameter'}->{$lang2} = $TermMeasures->_config->configuration->{'CONFIG'}->{$lang}->{"OPTION"};
    # 		} else {
    # 		    $TermMeasures->{'parameter'}->{"FR"} = "?.!";
    # 		    $TermMeasures->{'parameter'}->{"EN"} = "?.!";
    # 		    warn "*** OPTION is not set ***\n";
    # 		}
    # 	    } else {
    # 		$TermMeasures->{'parameter'}->{"FR"} = "?.!";
    # 		$TermMeasures->{'parameter'}->{"EN"} = "?.!";
    # 		warn "*** OPTION is not set ***\n";
    # 	    }
    # 	}
    # } else {
    # 	$TermMeasures->{'parameter'}->{"FR"} = "?.!";
    # 	$TermMeasures->{'parameter'}->{"EN"} = "?.!";	
    # }


    $TermMeasures->_input_filename($tmpfile_prefix . ".TermMeasures.in");
    $TermMeasures->_output_filename($tmpfile_prefix . ".TermMeasures.out");

    return($TermMeasures);

}

sub _processTermMeasures {
    my ($self, $lang) = @_;

    warn "[LOG] TermMeasures\n";

    my $document;
    my $term;
    my $termCur;
    my %term2CanFreq;
    my %term2Freq;
    my %term2Doc;
    my %termDoc;
    my %maxFreq;
    # my %termDocCan;
    my $termForm;
    my $D;

    $lang = $self->_documentSet->[0]->getAnnotations->getLanguage;

    # return($self->_exec_command($self->_defineCommandLine($self->_config->commands($lang)->{TermMeasures_CMD} . " < " . $self->_input_filename . ">" . $self->_output_filename)));

    foreach $document (@{$self->_documentSet}) {
	# $termCur = undef;
	$maxFreq{$document->getId} = 0;
	foreach $term (@{$document->getAnnotations->getSemanticUnitLevel->getElements}) {
	    # warn $term->getForm . "\n";
	    if ($term->isTerm) {
		# warn "\tOK\n";
		$self->_computeTermFreq($term, $document);
		$self->_computeTermPositionCos($term, $document);
		$self->_computeTermPositionDistMid($term, $document);
		$termDoc{$term->getForm} = $term->weight('tf');
		if ($maxFreq{$document->getId} < $term->weight('tf')) {
		    $maxFreq{$document->getId} = $term->weight('tf');
		}
#		$termDocCan{$self->getCanonicalForm($term)} = $term->weight('cantf', $document);
		# $termCur = $term;
	    }
	}
	foreach $termForm (keys %termDoc) {
	    $term2Doc{$termForm}++;
	    $term2Freq{$termForm} += $termDoc{$termForm};
#	    $term2CanFreq{$self->getCanonicalForm($term)} += $termDocCan{$self->getCanonicalForm($term, $document)};
	}

	# if (defined $termCur) {
	#     warn "$termCur\n";
	# }
    }
    $D = scalar(@{$self->_documentSet});
    foreach $document (@{$self->_documentSet}) {
	$self->_computeTermCanFreq($document, \%term2CanFreq);
	$self->_computeTermNormFreq($document, $maxFreq{$document->getId});
    }
    foreach $document (@{$self->_documentSet}) {
	$self->_computeFreqAndDocFreqAndTfIdf(\%term2Freq, \%term2Doc, $document, $D, \%term2CanFreq) ;
    }    

    warn "[LOG]\n";
}

# TODO
#      canFreq -> TO CHECK
#      NormFreq (freq / maxFreq)
#      iLong (Freq / length(term)

#     CValue*
#     ilnc*
#     iTer


sub _computeFreqAndDocFreqAndTfIdf {
    my ($self, $term2Freq, $term2Doc, $document, $D, $termCan2canFreq) = @_;

    my $freq;
    my $term;
    my $termForm;
    my $ref;

    foreach $termForm (keys %$term2Freq) {
	$ref = $document->getAnnotations->getSemanticUnitLevel->getElementFromIndex("form", $termForm);
	if (defined $ref) {
	    foreach $term (@$ref) {
		if (!defined $term->weight('Freq')) {
		    $term->weight('Freq', $term2Freq->{$termForm});
		}
		if (!defined $term->weight('idf')) {
		    $term->weight('idf', $D / $term2Doc->{$termForm});
		}
		if (!defined $term->weight('tf-idf')) {
		    $term->weight('tf-idf', $term->weight('Freq') * $term->weight('idf'));
		}
		if (!defined $term->weight('canFreq')) {
		    $term->weight('canFreq', $termCan2canFreq->{$self->_getCanonicalForm($term, $document)});
		}
	    }
	}
    }
}

# sub _computeDocFreq {
#     my ($self, $term, $document) = @_;

    
# }

sub _computeTermFreq {
    my ($self, $term, $document) = @_;

    my $freq;
    my $ref;

    if (!defined $term->weight('tf')) {
	$ref = $document->getAnnotations->getSemanticUnitLevel->getElementFromIndex("form", $term->getForm);
	if (defined $ref) {
	    $freq = scalar(@{$ref});
#	    warn $term->getForm . " : $freq\n";
	    $term->weight('tf', $freq);
	}
    }
}

sub _computeTermNormFreq {
    my ($self, $document, $maxFreq) = @_;

    my $term;

    foreach $term (@{$document->getAnnotations->getSemanticUnitLevel->getElements}) {
	if ($term->isTerm) {
	    $term->weight('NormFreq', $term->weight('tf') / $maxFreq);
	}
    }
}

sub _computeTermCanFreq {
    my ($self, $document, $termCan2canFreq) = @_;

    my %termCanForm;
    my %termForm;
    my $elmt;
    my $term;
    my $canForm;

    foreach $term (@{$document->getAnnotations->getSemanticUnitLevel->getElements}) {
	if ($term->isTerm) {
	    $canForm = $self->_getCanonicalForm($term, $document);
	    # warn $term->getForm . " : $canForm\n";
	    if (!defined $termCanForm{$canForm}) {
		$termCanForm{$canForm} = [];
	    }
	    push @{$termCanForm{$canForm}}, $term;
	    # warn $term->getForm . " ($canForm)\n";
	    if (!exists $termForm{$term->getForm . "_" . $canForm}) {
		$termForm{$term->getForm . "_" . $canForm}++;
		# warn $term->getForm . "\n";
		$termCan2canFreq->{$canForm} += $term->weight('tf');
	    }
	}
    }
    # warn "====\n";
    foreach $canForm (keys %termCanForm) {
	foreach $term (@{$termCanForm{$canForm}}) {
	    $term->weight('cantf', $termCan2canFreq->{$canForm});
	    # warn $term->getForm . "($canForm) : " . $term->weight('cantf') . "\n";
	}
    }
}

sub _computeTermCanFreq1 {
    my ($self, $term, $document) = @_;

    my $freq;
    my $ref;

    if (!defined $term->weight('cantf')) {
	$ref = $document->getAnnotations->getSemanticUnitLevel->getElementFromIndex("canonical_form", $term->getForm);
	if (defined $ref) {
	    $freq = scalar(@{$ref});
	    $term->weight('cantf', $freq);
	}
    }
}

sub _computeTermPositionCos {
    my ($self, $term, $document) = @_;

    my $freq;
    my $ref;
    my $last_token_addr = $document->getAnnotations->getTokenLevel->getLastElement->getFrom;

    if (!defined $term->weight('positionCos')) {
	$term->weight('positionCos', abs(cos(deg2rad($term->start_token->getFrom / $last_token_addr * 180))));
    }
}

sub _computeTermPositionDistMid {
    my ($self, $term, $document) = @_;

    my $freq;
    my $ref;
    my $last_token_addr = $document->getAnnotations->getTokenLevel->getLastElement->getFrom;


    if (!defined $term->weight('positionDistMid')) {
#	($last_token_addr/2) - 
	$term->weight('positionDistMid', (abs($last_token_addr/2 - $term->start_token->getFrom)));
    }
}

sub _inputTermMeasures {
    my ($self) = @_;

    warn "[LOG] making TermMeasures input\n";
    
    warn "[LOG] done\n";
}


sub _outputTermMeasures {
    my ($self) = @_;

    warn "[LOG] . Parsing " . $self->_output_filename . "\n";

    warn "[LOG] done\n";
}

sub run {
    my ($self, $documentSet) = @_;

    # Set variables according the the configuration

    $self->_documentSet($documentSet);

    warn "[LOG] " . $self->_config->comments . " ...     \n";

#    $self->_inputTermMeasures;

    my $command_line = $self->_processTermMeasures;

#     if ($self->_position eq "last") {
# 	# TODO
    if (($self->_position eq "last") && ($self->_no_standard_output)) {
	warn "print no standard output\n";
    } else {
	# $self->_outputTermMeasures;
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

