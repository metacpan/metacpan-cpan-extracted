package Lingua::Ogmios::NLPWrappers::SmileyRecognition;


our $VERSION='0.1';


use Lingua::Ogmios::NLPWrappers::Wrapper;

use strict;
use warnings;

our @ISA = qw(Lingua::Ogmios::NLPWrappers::Wrapper);

sub new {
    my ($class, $config, $tmpfile_prefix, $logfile, $position, $no_standard_output) = @_;

    my $lang;
    my $lang2;

    warn "[LOG]    Creating a wrapper of the SmileyRecognition\n";

    my $SmileyRecognition = $class->SUPER::new($config, $tmpfile_prefix, $logfile, $position, $no_standard_output);

    if (defined $SmileyRecognition->_config->configuration->{'CONFIG'}) {
	foreach $lang (keys %{$SmileyRecognition->_config->configuration->{'CONFIG'}}) {
	    if ($lang =~ /language=([\w]+)/io) {
		$lang2 = $1;

		# $SmileyRecognition->_setOption($lang2, "MODE", "mode", "eval");
		# if (defined $SmileyRecognition->_config->configuration->{'CONFIG'}->{$lang}->{"OPTION"}) {
		#     $SmileyRecognition->{'parameter'}->{$lang2} = $SmileyRecognition->_config->configuration->{'CONFIG'}->{$lang}->{"OPTION"};
		# } else {
		#     $SmileyRecognition->{'parameter'}->{"FR"} = "?.!";
		#     $SmileyRecognition->{'parameter'}->{"EN"} = "?.!";
		#     warn "*** OPTION is not set ***\n";
		# }
	    # } else {
	    # 	$SmileyRecognition->{'parameter'}->{"FR"} = "?.!";
	    # 	$SmileyRecognition->{'parameter'}->{"EN"} = "?.!";
	    # 	warn "*** OPTION is not set ***\n";
		$SmileyRecognition->_setOption($lang2, "EXCEPTIONS", "exceptions", undef);
	    }
	}
    # } else {
    # 	$SmileyRecognition->{'parameter'}->{"FR"} = "?.!";
    # 	$SmileyRecognition->{'parameter'}->{"EN"} = "?.!";	
    }


    $SmileyRecognition->_input_filename($tmpfile_prefix . ".SmileyRecognition.in");
    $SmileyRecognition->_output_filename($tmpfile_prefix . ".SmileyRecognition.out");

    return($SmileyRecognition);

}

sub _inputSmileyRecognition {
    my ($self) = @_;

    my $token;
    my $corpus_in = "";
    my $document;
    my $docOffset = 0;

    $self->{'documentLastOffset'} = [];

    warn "[LOG] making SmileyRecognition input\n";

    foreach $document (@{$self->_documentSet}) {
	$docOffset += $document->getAnnotations->getTokenLevel->getLastElement->getTo;
	push @{$self->{'documentLastOffset'}}, [$docOffset, $document, $document->getAnnotations->getTokenLevel->getLastElement->getTo];

	# warn scalar(@{$self->{'documentLastOffset'}}) . " / $docOffset\n";
	foreach $token (@{$document->getAnnotations->getTokenLevel->getElements}) {
#	warn "$token: " . $token->getContent . ";\n";
	    $corpus_in .= $token->getContent;
	    if ($document->getAnnotations->getSectionLevel->existsElementFromIndex("to", $token->getId)) {
		# $corpus_in .= "\n";
	    }
	}
    }
    # $corpus_in =~ s/[\x{A0}\x{2000}-\x{200B}]/ /go;
    # $corpus_in =~ s/\x{0153}/oe/go;
    # $corpus_in =~ s/\x{0152}/OE/go;
    # $corpus_in =~ s/[\x{2019}\x{2032}]/\'/go;
    
    warn "[LOG] Write in " . $self->_input_filename . "\n";

##XXX TH    
    open(FILE_IN, ">:utf8", $self->_input_filename)  or die "No such file " . $self->_output_filename . "\n";


#    print FILE_IN Encode::encode("iso-8859-1", $corpus_in, Encode::FB_DEFAULT); #$corpus_in;

    print FILE_IN $corpus_in;

    close FILE_IN;
    
    warn "[LOG] done\n";
}

sub _processSmileyRecognition {
    my ($self, $lang) = @_;

    warn "[LOG] SmileyRecognition\n";

    $lang = $self->_documentSet->[0]->getAnnotations->getLanguage;

    return($self->_exec_command($self->_defineCommandLine($self->_config->commands($lang)->{SmileyRecognition_CMD} . " " . $self->{'exceptions'}->{$lang} . " " . $self->_input_filename . ">" . $self->_output_filename)));

    warn "[LOG]\n";
}


sub _outputSmileyRecognition {
    my ($self) = @_;

    my $line;
    my $file;
    my $start;
    my $end;
    my $start2;
    my $end2;
    my $string;
    my $semtags;
    my $semtag;
    my $document;
    my $startToken;
    my $endToken;
    my @tokenList;
    my $token;
    my $semFeatures;
    my $i;
    my $termUnit;
    warn "[LOG] . Parsing " . $self->_output_filename . "\n";


    open(FILE_OUT, "<:utf8", $self->_output_filename) or die "No such file " . $self->_output_filename . "\n";
    while($line = <FILE_OUT>) {
	# warn $line;
	chomp $line;
	if ($line !~ /\#EXCEPT/o) {
	    ($file, $start, $end, $string, $semtags) = split /\|/, $line;
	    # warn "************************\n";
	    # warn "string: $string\n";
	    # warn "\tstart (a): $start\n";
	    # warn "\tend (a): $end\n";
	    # warn "\tsemf: $semtags\n";
	    # get document 
	    $i = 0;
	    $start2 = $start;
	    $end2 = $end;
	    while(($i < scalar(@{$self->{'documentLastOffset'}})) && ($start > $self->{'documentLastOffset'}->[$i]->[0])) {
		# warn "\n\tstart (c): $start\n";
		# warn "\tend (c): $end\n";
		# warn "\tstart2 (c): $start2\n";
		# warn "\tend2 (c): $end2\n";
		# warn "\ti = $i\n";
		# warn "\t    " . $self->{'documentLastOffset'}->[$i]->[0] . "\n";
		# warn "\t    " . $self->{'documentLastOffset'}->[$i]->[2] . "\n";
		$start2 -= $self->{'documentLastOffset'}->[$i]->[2] + 1;
		$end2 -= $self->{'documentLastOffset'}->[$i]->[2] + 1;
		# warn "\tstart2 (d): $start2\n";
		# warn "\tend2 (d): $end2\n";
		$i++;
	    }
	    if ($i < scalar(@{$self->{'documentLastOffset'}})) {
		$document = $self->{'documentLastOffset'}->[$i]->[1];
		# warn "found\n";
		# warn "\t" . $document->getId . "\n";
	    }
	    # warn "\tstart (b): $start\n";
	    # warn "\tend (b): $end\n";
	    # warn "\tstart2 (b): $start2\n";
	    # warn "\tend2 (b): $end2\n";
	    # warn "\ti = $i\n";
	    # $self->{'documentLastOffset'}

	    if ($document->getAnnotations->getTokenLevel->existsElementFromIndex("from", $start2 )) {
		$startToken = $document->getAnnotations->getTokenLevel->getElementFromIndex("from", $start2 )->[0];
		if ($document->getAnnotations->getTokenLevel->existsElementFromIndex("to", $end2 )) {
		    $endToken = $document->getAnnotations->getTokenLevel->getElementFromIndex("to", $end2 )->[0];
		    # warn "\t" . $startToken->getId . "\n";
		    # warn "\t" . $endToken->getId . "\n";
		    $token = $startToken;
		    @tokenList = ();
		    push @tokenList, $token;
		    while(!$token->equals($endToken)) {
			$token = $token->next;
			push @tokenList, $token;
		    };
		    $termUnit = $self->_createTerm($document, \@tokenList, $string);
		    
		    if (defined $termUnit) {
			$document->getAnnotations->addSemanticUnit($termUnit);
		    }

		    if (defined $semtags) {
			$semFeatures = $self->_createSemanticFeaturesFromString($semtags, $termUnit->getId);
			if (defined $semFeatures) {
			    $document->getAnnotations->addSemanticFeatures($semFeatures);
			}
		    }
		}	


	    }	
	}

    }
    close FILE_OUT;

    warn "[LOG] done\n";
}

sub run {
    my ($self, $documentSet) = @_;

    # Set variables according the the configuration

    $self->_documentSet($documentSet);

    warn "[LOG] " . $self->_config->comments . " ...     \n";

    $self->_inputSmileyRecognition;

    my $command_line = $self->_processSmileyRecognition;

#     if ($self->_position eq "last") {
# 	# TODO
    $self->_outputSmileyRecognition;
    if (($self->_position eq "last") && ($self->_no_standard_output)) {
	warn "print no standard output\n";
	if ($self->_no_standard_output eq "HTML") {
            warn "print HTML output\n";
	    $self->HTMLoutput;
	}
	if ($self->_no_standard_output eq "TXT") {
             warn "print TXT output\n";
	     $self->_TXToutput;
	}
	# if ($self->_no_standard_output eq "TXTwSectionTitle") {
        #     warn "print TXT output\n";
	#     $self->_TXToutputWithSectionTitle;
	# }

	if ($self->_no_standard_output eq "TAGGEDSENT") {
            warn "print Tagged Sentence output (TAGGEDSENT)\n";
	    $self->_makeTaggedSentences({}, \*STDOUT, "/", " ");
	}

	# if ($self->_no_standard_output eq "CRFINPUT") {
        #     warn "print Tagged Sentence output (CRFINPUT)\n";
	#     $self->_makeTaggedSentences([], \*STDOUT, "\t", "\n");
	# }
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

sub _TXToutput {
    my ($self) = @_;

    my $i;
    my $semUnit;
    my $semf;
    my $document;

    # for ($i = 0; $i < scalar(@{$self->_documentSet}); $i++) {
    foreach $document (@{$self->_documentSet}) {
	foreach $semUnit (@{$document->getAnnotations->getSemanticUnitLevel->getElements}) {
	    print $semUnit->getId . "\t" . $semUnit->getForm . "\t";
	    if ($document->getAnnotations->getSemanticFeaturesLevel->existsElementFromIndex("refid_semantic_unit", $semUnit->getId)) {
		$semf = $document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $semUnit->getId)->[0];
		if (defined $semf) {
		    print $semf->toString;
		}
	    }
	    print "\n";
	    
	}
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

