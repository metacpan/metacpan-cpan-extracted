package Lingua::Ogmios::NLPWrappers::BasicWordSegmentizer;


our $VERSION='0.1';


use Lingua::Ogmios::NLPWrappers::Wrapper;

use strict;
use warnings;

our @ISA = qw(Lingua::Ogmios::NLPWrappers::Wrapper);

sub new {
    my ($class, $config, $tmpfile_prefix, $logfile, $position, $no_standard_output) = @_;

    my $lang;
    my $lang2;

    warn "[LOG]    Creating a wrapper of the BasicWordSegmentizer\n";

    my $BasicWordSegmentizer = $class->SUPER::new($config, $tmpfile_prefix, $logfile, $position, $no_standard_output);

    if (defined $BasicWordSegmentizer->_config->configuration->{'CONFIG'}) {
	foreach $lang (keys %{$BasicWordSegmentizer->_config->configuration->{'CONFIG'}}) {
	    if ($lang =~ /language=([\w]+)/io) {
		$lang2 = $1;

		if (defined $BasicWordSegmentizer->_config->configuration->{'CONFIG'}->{$lang}->{"OPTION"}) {
		    $BasicWordSegmentizer->{'parameter'}->{$lang2} = $BasicWordSegmentizer->_config->configuration->{'CONFIG'}->{$lang}->{"OPTION"};
		} else {
		    $BasicWordSegmentizer->{'parameter'}->{"FR"} = "?.!";
		    $BasicWordSegmentizer->{'parameter'}->{"EN"} = "?.!";
		    warn "*** OPTION is not set ***\n";
		}
	    } else {
		$BasicWordSegmentizer->{'parameter'}->{"FR"} = "?.!";
		$BasicWordSegmentizer->{'parameter'}->{"EN"} = "?.!";
		warn "*** OPTION is not set ***\n";
	    }
	}
    } else {
	$BasicWordSegmentizer->{'parameter'}->{"FR"} = "?.!";
	$BasicWordSegmentizer->{'parameter'}->{"EN"} = "?.!";	
    }


    $BasicWordSegmentizer->_input_filename($tmpfile_prefix . ".BasicWordSegmentizer.in");
    $BasicWordSegmentizer->_output_filename($tmpfile_prefix . ".BasicWordSegmentizer.out");

    return($BasicWordSegmentizer);

}

sub _processBasicWordSegmentizer {
    my ($self, $lang) = @_;

    warn "[LOG] BasicWordSegmentizer\n";

    $lang = $self->_documentSet->[0]->getAnnotations->getLanguage;

    return($self->_exec_command($self->_defineCommandLine($self->_config->commands($lang)->{BasicWordSegmentizer_CMD} . " < " . $self->_input_filename . ">" . $self->_output_filename)));

    warn "[LOG]\n";
}

sub _inputBasicWordSegmentizer {
    my ($self) = @_;

    warn "[LOG] making BasicWordSegmentizer input\n";
    
    warn "[LOG] done\n";
}


sub _outputBasicWordSegmentizer {
    my ($self) = @_;

    my $token;
    my $section;
    my @corpus_in;
    my $document;

    my $word_form = "";
    my @Word2tokens = ();
    my $IsNE = 0;
    my $isInNE;
    my $word;

    warn "[LOG] . Parsing " . $self->_output_filename . "\n";

    foreach $document (@{$self->_documentSet}) {
	foreach $token (@{$document->getAnnotations->getTokenLevel->getElements}) {
 	    # warn "token: " .  $token->getContent . "\n";
	    if ((($token->isSep) || ($document->getAnnotations->getSectionLevel->existsElementFromIndex("to", $token->getId))) && (!$isInNE))  {
		if ((!$token->isSep) && (!$token->isSymb)) {
		    # warn "+\n";
		    push @Word2tokens, $token;
		    $word_form .= $token->getContent;
		    $isInNE = $document->getAnnotations->getSemanticUnitLevel->existsElementFromIndex("list_refid_token", $token->getId);
		    $IsNE ||= $isInNE;
		}
		if (scalar(@Word2tokens) > 0) {
		    # warn "add $word_form;\n";
		    # warn "    " . scalar(@Word2tokens) . "\n";
		    $word = Lingua::Ogmios::Annotations::Word->new(
			{'form' => $word_form,
			 'list_refid_token' => \@Word2tokens,
			 'isNE' => $IsNE,
			});
		    $document->getAnnotations->addWord($word);
		    $word_form = "";
		    @Word2tokens = ();
		    $IsNE = 0;
		    $isInNE = 0;
		}
	    } else {
		$word_form .= $token->getContent;
		push @Word2tokens, $token;
		$isInNE = $document->getAnnotations->getSemanticUnitLevel->existsElementFromIndex("list_refid_token", $token->getId);
		$IsNE ||= $isInNE;
	    }

# #	warn "$token: " . $token->getContent . ";\n";
# 	    $corpus_in .= $token->getContent;
# 	    if ($document->getAnnotations->getSectionLevel->existsElementFromIndex("to", $token->getId)) {
# 		$corpus_in .= "\n";
	}
    }
    warn "[LOG] done\n";
}

sub run {
    my ($self, $documentSet) = @_;

    # Set variables according the the configuration

    $self->_documentSet($documentSet);

    warn "[LOG] " . $self->_config->comments . " ...     \n";

#    $self->_inputBasicWordSegmentizer;

    my $command_line = "";

#     if ($self->_position eq "last") {
# 	# TODO
    if (($self->_position eq "last") && ($self->_no_standard_output)) {
	warn "print no standard output\n";
    } else {
	$self->_outputBasicWordSegmentizer;
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

