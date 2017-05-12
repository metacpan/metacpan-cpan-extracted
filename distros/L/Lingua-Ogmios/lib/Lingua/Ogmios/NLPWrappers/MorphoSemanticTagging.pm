package Lingua::Ogmios::NLPWrappers::MorphoSemanticTagging;

# Authors: Amandine Périnet, Natalia Grabar, Thierry Hamon

our $VERSION='0.1';


use Lingua::Ogmios::NLPWrappers::Wrapper;

use strict;
use warnings;

our @ISA = qw(Lingua::Ogmios::NLPWrappers::Wrapper);

sub new {
    my ($class, $config, $tmpfile_prefix, $logfile, $position, $no_standard_output) = @_;

    warn "[LOG]    Creating a wrapper of the TreeTagger\n";

    my $MorphoSemanticTagging = $class->SUPER::new($config, $tmpfile_prefix, $logfile, $position, $no_standard_output);

    $MorphoSemanticTagging->_input_filename($tmpfile_prefix . ".MorphoSemanticTagging.in");
    $MorphoSemanticTagging->_output_filename($tmpfile_prefix . ".MorphoSemanticTagging.out");

    return($MorphoSemanticTagging);

}

sub _inputMorphoSemanticTagging {
    my ($self) = @_;

    warn "[LOG] making Decision MorphoSemanticTagging input\n";

    my @fields = ("WEIGHTS", "SEMANTICTYPES", "WORD_FIELDS");

    $self->_loadRCFile($self->_config->configuration->{'CONFIG'}->{"language=EN"}->{"CONFIGFILE"}, \@fields);

    $self->LoadMorphoSemanticMarkResource("SEMANTICTYPES");

    warn "[LOG] done\n";
}

sub determineSemanticType4Word {
    my ($affixList, $term, $word, $acroType) = @_;

    my $semanticType;
    my $affix;

    my @semanticTypes;

    foreach $affix (keys %$affixList) {
	if ((($affixList->{$affix} eq "m") && ($word =~ /$affix/)) ||
	    (($affixList->{$affix} eq "m-s") && ($word =~ /$affix$/)) ||
	    (($affixList->{$affix} eq "m-p") && ($word =~ /^$affix/))) {
	    $semanticType = $acroType;# $affixList->{$affix};
	    push @semanticTypes, {"semanticType" => $semanticType,
				  "originType" => "morphological",
				  "origin" => $affixList->{$affix}, # . " / $affix",
	    };
	}
    }
    return(@semanticTypes);
}

sub addSemanticType {
    my ($self, $semanticTypeStruct, $semanticTypes) = @_;

    # semanticTypeStruct => (semanticType, origin, originType, nboccurrences)
    # semanticType => @origins,@ originType, @nboccurrences)
    my $semanticType = $semanticTypeStruct->{"semanticType"};

    if (!defined $semanticTypes->{$semanticType}->{"originType"}) {
	my @tmp;
	$semanticTypes->{$semanticType}->{"originType"} = \@tmp;
    }
    push @{$semanticTypes->{$semanticType}->{"originType"}}, $semanticTypeStruct->{"originType"};
    $semanticTypes->{$semanticType}->{$semanticTypeStruct->{"originType"}}++;

    if (!defined $semanticTypes->{$semanticType}->{"origin"}) {
	my @tmp;
	$semanticTypes->{$semanticType}->{"origin"} = \@tmp;
    }
#     warn "semanticType: " . $semanticType . "\n";
#     warn "OriginType: " . $semanticTypeStruct->{"originType"} . "\n";
#     warn "Origin:: " . $semanticTypeStruct->{"origin"} . "\n";
    push @{$semanticTypes->{$semanticType}->{"origin"}}, $semanticTypeStruct->{"origin"};
    $semanticTypes->{$semanticType}->{$semanticTypeStruct->{"origin"}}++;

    $semanticTypes->{$semanticType}->{"nboccurrences"}++;

    
}

sub selectSemanticType {
    my ($self, $semanticTypes, $term) = @_;

    my @concurrentSemanticTypes = keys %$semanticTypes;

    my $semanticType;
    my @a;
    my @r;
    my $scores_hash;

    if (scalar(@concurrentSemanticTypes) == 0) {
	$semanticType = undef;
    } elsif (scalar(@concurrentSemanticTypes) == 1) {
	$semanticType = $concurrentSemanticTypes[0];
    } else {
	@r = sort { $semanticTypes->{$a}->{"nboccurrences"} <=> $semanticTypes->{$a}->{"nboccurrences"}} @concurrentSemanticTypes;
	if ($semanticTypes->{$r[0]}->{"nboccurrences"} != $semanticTypes->{$r[$#r]}->{"nboccurrences"}) {
	    return ($r[$#r]);
	} else {
	    $scores_hash = $self->computeScores($semanticTypes);
	    @r = sort { $scores_hash->{$a} <=> $scores_hash->{$b} } keys %$scores_hash;
	    return($r[$#r]);
	}
    }
 
    return($semanticType);
}

sub computeScores {
    my ($self, $semanticTypes) = @_;

    my $semanticType;
    my %scores;
    my $score = 0;
    my $originType;
    my $origin;

    foreach $semanticType (keys %$semanticTypes) {
	foreach $originType (@{$semanticTypes->{$semanticType}->{"originType"}}) {
	    if ($originType eq "morphological") {
		foreach $origin (@{$semanticTypes->{$semanticType}->{"origin"}}) {
# 		    warn "origin: $origin\n";
# 		    warn "semanticType: $semanticType\n";
# 		    warn $self->{"WEIGHTS"}->{$origin} . "\n";
# 		    warn $semanticTypes->{$semanticType}->{$origin} . "\n";
		    $score += ($self->{"WEIGHTS"}->{$origin} * $semanticTypes->{$semanticType}->{$origin});
		}
	    } else {
		$score += ($self->{"WEIGHTS"}->{$originType} * $semanticTypes->{$semanticType}->{$originType});
	    }
	}
	$scores{$semanticType} = $score;
    }
    return(\%scores);
}


sub determineSemanticType4Term {
    my ($self, $term) = @_;

    my $word;
    my @words = split (/ /, $term);

    my $semanticType;

    my %semanticTypes; # semanticType => (origin, nboccurrences)
    my @semanticTypeList;

    my $field;
    my $type;

    foreach $word (@words) {
	foreach $semanticType (keys %{$self->{"SEMANTICTYPES"}}) {
 	    foreach $field (@{$self->{"WORD_FIELDS"}->{"field"}}) {
		if (exists $self->{"RESOURCES"}->{$semanticType . "_$field"}->{$word}) {
		    $self->addSemanticType({"semanticType" => $semanticType,
					    "originType" => $field,
					    "origin" => $field,
					   }, \%semanticTypes);
		}
 	    }
	}
	foreach $semanticType (keys %{$self->{"SEMANTICTYPES"}}) {		
	    @semanticTypeList = &determineSemanticType4Word($self->{"RESOURCES"}->{$semanticType . "_morphological"}, $term, $word, $semanticType);
	    if (scalar(@semanticTypeList) > 0) {
		$field = "morphological";
		foreach $type (@semanticTypeList) {
		    $self->addSemanticType($type, \%semanticTypes);
		}
	    }
	}
    }
    $semanticType = $self->selectSemanticType(\%semanticTypes, $term);

    return($semanticType);
}


sub _processMorphoSemanticTagging {
    my ($self, $lang) = @_;

    warn "[LOG] MorphoSemantic Tagging\n";

    $lang = $self->_documentSet->[0]->getAnnotations->getLanguage;

    my $document;
    my $term;
    my $semanticType;

    foreach $document (@{$self->_documentSet}) {
 	foreach $term (@{$document->getAnnotations->getSemanticUnitLevel->getElements}) {
#  	    warn "------------------------------------------------------------------------\n";
#     	    warn "Process " . $term->getForm . "\n";
	    if (!$document->getAnnotations->getSemanticFeaturesLevel->existsElementFromIndex("refid_semantic_unit", $term->getId)) {
		$semanticType = $self->determineSemanticType4Term($term->getForm);
		if (defined $semanticType) {
		    $self->_addSemanticFeature($term, $semanticType, $document);
		}

	    }
	}
    }
    warn "[LOG]\n";
}

sub _outputMorphoSemanticTagging {
    my ($self) = @_;

    warn "[LOG] . Parsing " . $self->_output_filename . "\n";

    warn "[LOG] done\n";
}

sub run {
    my ($self, $documentSet) = @_;

    # Set variables according the the configuration

    $self->_documentSet($documentSet);

    warn "[LOG] " . $self->_config->comments . " ...     \n";

    $self->_inputMorphoSemanticTagging;

    my $command_line = $self->_processMorphoSemanticTagging;

#     if ($self->_position eq "last") {
# 	# TODO
    if (($self->_position eq "last") && ($self->_no_standard_output)) {
	warn "print no standard output\n";
    } else {
	$self->_outputMorphoSemanticTagging;
    }
#     $self->_outputParsing;


    # Put log information 

    my $information = { 'software_name' => $self->_config->name,
			'comments' => $self->_config->comments,
			'command_line' => $command_line,
			'list_modified_level' => ['semantic_features_level'],
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

