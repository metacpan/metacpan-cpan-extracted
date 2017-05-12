package Lingua::Ogmios::NLPWrappers::NegEx;


our $VERSION='0.1';

# use Lingua::NegEx qw( negation_scope );
use Lingua::Ogmios::NLPWrappers::Wrapper;

use strict;
use warnings;

our @ISA = qw(Lingua::Ogmios::NLPWrappers::Wrapper);

sub new {
    my ($class, $config, $tmpfile_prefix, $logfile, $position, $no_standard_output, $out_stream) = @_;

    my $lang;
    my $lang2;

    warn "[LOG]    Creating a wrapper of the NegEx\n";

    my $NegEx = $class->SUPER::new($config, $tmpfile_prefix, $logfile, $position, $no_standard_output, $out_stream);

    if (defined $NegEx->_config->configuration->{'CONFIG'}) {
	foreach $lang (keys %{$NegEx->_config->configuration->{'CONFIG'}}) {
	    if ($lang =~ /language=([\w]+)/io) {
		$lang2 = $1;

		# $NegEx->_setOption($lang2, "MODE", "mode", "eval");
		# if (defined $NegEx->_config->configuration->{'CONFIG'}->{$lang}->{"OPTION"}) {
		#     $NegEx->{'parameter'}->{$lang2} = $NegEx->_config->configuration->{'CONFIG'}->{$lang}->{"OPTION"};
		# } else {
		#     $NegEx->{'parameter'}->{"FR"} = "?.!";
		#     $NegEx->{'parameter'}->{"EN"} = "?.!";
		#     warn "*** OPTION is not set ***\n";
		# }
	    # } else {
	    # 	$NegEx->{'parameter'}->{"FR"} = "?.!";
	    # 	$NegEx->{'parameter'}->{"EN"} = "?.!";
	    # 	warn "*** OPTION is not set ***\n";
	    }
	}
    # } else {
    # 	$NegEx->{'parameter'}->{"FR"} = "?.!";
    # 	$NegEx->{'parameter'}->{"EN"} = "?.!";	
    }


    $NegEx->_input_filename($tmpfile_prefix . ".NegEx.in");
    $NegEx->_output_filename($tmpfile_prefix . ".NegEx.out");

    return($NegEx);

}

sub _processNegEx {
    my ($self, $lang) = @_;

    warn "[LOG] NegEx\n";

    $lang = $self->_documentSet->[0]->getAnnotations->getLanguage;

    my $document;
    my $sentence;
    my $scope;
    my @terms;
    my $words;
    my $i;

    my $perlModule = $self->_config->commands($lang)->{PerlModule};

    eval "require $perlModule"; # qw( negation_scope )";
#    eval "require Lingua::NegEx qw( negation_scope )";
    if ($@) {
 	warn $@ . "\n";
 	die "Problem while loading perlModule $perlModule - Abort\n\n";
    } else {
	$perlModule->import(qw( negation_scope ));
	foreach $document (@{$self->_documentSet}) {
	    foreach $sentence (@{$document->getAnnotations->getSentenceLevel->getElements}) {
		$scope = negation_scope($sentence->getForm);
		# print STDERR $sentence->getForm . "\n";
		if ($scope != 0) {
		    # print STDERR join(', ', @$scope) . "\n"; 
		    $words = $sentence->getWordsFromSentence($document);
		    # print STDERR "\t";
		    @terms = $document->getAnnotations->getSemanticUnitLevel->getElementsBetweenStartEndTokens($words->[$scope->[0]]->start_token, $words->[$scope->[1]]->end_token);

		    for($i=0;$i < scalar(@terms);$i++) {
			$terms[$i]->negation(1);
		    }  
#		    print STDERR "\n";
		}
# 		# $corpus_in .= $sentence->getForm;
# 		# $corpus_in .= "\n";
 	    }
 	}
    }

    warn "[LOG]\n";
    return($perlModule);
}

sub _inputNegEx {
    my ($self) = @_;

    warn "[LOG] making NegEx input\n";
    
    warn "[LOG] done\n";
}


sub _outputNegEx {
    my ($self) = @_;

    warn "[LOG] . Parsing " . $self->_output_filename . "\n";

    warn "[LOG] done\n";
}

sub run {
    my ($self, $documentSet) = @_;

    # Set variables according the the configuration

    $self->_documentSet($documentSet);

    warn "[LOG] " . $self->_config->comments . " ...     \n";

    $self->_inputNegEx;

    my $command_line = $self->_processNegEx;

#     if ($self->_position eq "last") {
# 	# TODO
    if (($self->_position eq "last") && ($self->_no_standard_output)) {
	warn "print no standard output\n";
	if ($self->_no_standard_output eq "QALD") {
	    warn "print Tagged Sentence output (QALD)\n";
	    warn $self->_out_stream . "\n";
	    $self->_QALDoutput;
	}
    } else {
	$self->_outputNegEx;
    }
#     $self->_outputParsing;


    # Put log information 

    my $information = { 'software_name' => $self->_config->name,
			'comments' => $self->_config->comments,
			'command_line' => $command_line,
			'list_modified_level' => [''],
    };
    $self->_log($information);


    $self->getTimer->_printTimes;
    $self->getTimer->_printTimesInLine($self->_config->name);

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

