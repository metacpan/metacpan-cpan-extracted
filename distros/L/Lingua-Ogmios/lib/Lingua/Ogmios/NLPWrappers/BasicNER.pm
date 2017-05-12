package Lingua::Ogmios::NLPWrappers::BasicNER;


our $VERSION='0.1';


use Lingua::Ogmios::NLPWrappers::Wrapper;
use Lingua::Ogmios::Annotations::SemanticUnit;

use strict;
use warnings;

our @ISA = qw(Lingua::Ogmios::NLPWrappers::Wrapper);

sub new {
    my ($class, $config, $tmpfile_prefix, $logfile, $position, $no_standard_output) = @_;

    warn "[LOG]    Creating a wrapper of the BasicNER\n";


    my $BasicNER = $class->SUPER::new($config, $tmpfile_prefix, $logfile, $position, $no_standard_output);

    return($BasicNER);

}

sub BasicNER {
    my ($self) = @_;

    my $sentence;
    my $document;

    my $datere = q([0-9]{1,2}\/[0-9]{1,2}\/[0-9]{2,4});

    my $daytime = q([0-2][0-4]:[0-5][0-9]:[0-5][0-9]);

    my $age = q(([0-9]{1,3}[ \-](year[ \-]old|yo\b)|age [0-9]{1,3}));

    my $percent = q(([+\-])?[0-9]+(\.)?[0-9]* ?%);

    my $number = q((([0-9]+( , |,)?[0-9]{3})(?!%)|[0-9]+([.][0-9]+)?));

    my $unit = q( ?(?i)(mg|kg|g)(?=\b));

    my $dosage = "$number $unit";

    my $bloodpressure = "(?<ctxtbp2a>(?<ctxtbp1a>blood pressure". '(\\b[^\.]*?))'. "(?<bp1>$number/$number))" . '((?<ctxtbp2b>\\b[^\.]*?)'. "(?<bp2>$number/$number))?";
    
    my $pulse = "(pulse \\K$number|$number(?= beats))";

    my $cardinal = q((1st|2nd|3rd|[4-9]th|first|second|third|fourth|fifth|sixth|seventh|eighth|nineth));

    my $letterrednumber = q((one|two|three|four|five|six|seven|eight|nine|ten));
    my $times = "($letterrednumber|$number|$number-$number|$letterrednumber to $letterrednumber) (minutes|hours|days?|weeks?)";

    my $sentenceForm;

    foreach $document (@{$self->_documentSet}) {
	foreach $sentence (@{$document->getAnnotations->getSentenceLevel->getElements}) {
	    $sentenceForm = $sentence->getForm;
	    
	    while ($sentenceForm =~ /$datere/gos) {
		warn "=> $& (date - from " . length($`) . " to " . (length($`) + length($&)) . ")\n";

		$self->addSemanticEntity($&, 
					 $sentence->refid_start_token->getFrom + length($`),
					 $sentence->refid_start_token->getFrom + length($`) + length($&), 
					 "date",
					 $sentence->refid_start_token,
					 $document
		    );
	    }
	    while ($sentenceForm =~ /$daytime/gos) {
		warn "=> $& (daytime - from " . length($`) . " to " . (length($`) + length($&)) . ")\n";
		$self->addSemanticEntity($&, 
					 $sentence->refid_start_token->getFrom + length($`),
					 $sentence->refid_start_token->getFrom + length($`) + length($&), 
					 "daytime",
					 $sentence->refid_start_token,
					 $document
		    );
	    }
    
	    while ($sentenceForm =~ /$age/ogs) {
		warn "=> $& (age - from " . length($`) . " to " . (length($`) + length($&)) . ")\n";
		$self->addSemanticEntity($&, 
					 $sentence->refid_start_token->getFrom + length($`),
					 $sentence->refid_start_token->getFrom + length($`) + length($&), 
					 "age",
					 $sentence->refid_start_token,
					 $document
		    );
		
	    }
	    
	    while ($sentenceForm =~ /$percent/gos) {
		warn "=> $& (percent - from " . length($`) . " to " . (length($`) + length($&)) . ")\n";
		$self->addSemanticEntity($&, 
					 $sentence->refid_start_token->getFrom + length($`),
					 $sentence->refid_start_token->getFrom + length($`) + length($&), 
					 "percent",
					 $sentence->refid_start_token,
					 $document
		    );
		
	    }
	    
	    while ($sentenceForm =~ /$number/ogs) {
		warn "=> $& (number - from " . length($`) . " to " . (length($`) + length($&)) . ")\n";
		$self->addSemanticEntity($&, 
					 $sentence->refid_start_token->getFrom + length($`),
					 $sentence->refid_start_token->getFrom + length($`) + length($&), 
					 "number",
					 $sentence->refid_start_token,
					 $document
		    );
		
	    }
	    while ($sentenceForm =~ /$dosage/ogs) {
		warn "=> $& (dosage - from " . length($`) . " to " . (length($`) + length($&)) . ")\n";
		
		$self->addSemanticEntity($&, 
					 $sentence->refid_start_token->getFrom + length($`),
					 $sentence->refid_start_token->getFrom + length($`) + length($&), 
					 "dosage",
					 $sentence->refid_start_token,
					 $document
		    );
	    }
	    
	    while ($sentenceForm =~ m{$bloodpressure}ogs) {
 		warn "=> " . $+{bp1} . " " . $+{bp2} . " (blood pressure - from " . length($`) . " to " . (length($`) + length($+{bp1})) . " and from " . (length($`) + length($+{ctxtbp2a}) + length($+{ctxtbp2b})) . " to " . (length($`) + length($+{ctxtbp2a}) + length($+{ctxtbp2b}) + length($+{bp2})) . ")\n";

		$self->addSemanticEntity($+{bp1}, 
					 $sentence->refid_start_token->getFrom + length($`) + length($+{ctxtbp1a}),
					 $sentence->refid_start_token->getFrom + length($`) + length($+{ctxtbp1a}) + length($+{bp1}), 
					 "blood pressure",
					 $sentence->refid_start_token,
					 $document
		    );
		$self->addSemanticEntity($+{bp2}, 
					 $sentence->refid_start_token->getFrom + (length($`) + length($+{ctxtbp2a}) + length($+{ctxtbp2b})),
					 $sentence->refid_start_token->getFrom + (length($`) + length($+{ctxtbp2a}) + length($+{ctxtbp2b}) + length($+{bp2})), 
					 "blood pressure",
					 $sentence->refid_start_token,
					 $document
		    );

		
	    }
	    while ($sentenceForm =~ m{$pulse}ogs) {
		warn "=> $& (pulse - from " . length($`) . " to " . (length($`) + length($&)) . ")\n";
		
		$self->addSemanticEntity($&, 
					 $sentence->refid_start_token->getFrom + length($`),
					 $sentence->refid_start_token->getFrom + length($`) + length($&), 
					 "pulse",
					 $sentence->refid_start_token,
					 $document
		    );
	    }
	    while ($sentenceForm =~ m{$times}ogs) {
		warn "=> $& (times - from " . length($`) . " to " . (length($`) + length($&)) . ")\n";
		$self->addSemanticEntity($&, 
					 $sentence->refid_start_token->getFrom + length($`),
					 $sentence->refid_start_token->getFrom + length($`) + length($&), 
					 "times",
					 $sentence->refid_start_token,
					 $document
		    );
	    }

	    while ($sentenceForm =~ m{$cardinal}ogs) {
		warn "=> $& (cardinal - from " . length($`) . " to " . (length($`) + length($&)) . ")\n";
		$self->addSemanticEntity($&, 
					 $sentence->refid_start_token->getFrom + length($`),
					 $sentence->refid_start_token->getFrom + length($`) + length($&), 
					 "cardinal",
					 $sentence->refid_start_token,
					 $document
		    );
		
	    }

	}
    }
#     exit;

}


sub addSemanticEntity {
    my $self = shift;
    my $NE_form = shift;
    my $from = shift;
    my $to = shift;
    my $type = shift;
    my $token = shift;
    my $document = shift;

    my @NE2tokens;
    
# 		my $from = $sentence->refid_start_token->getFrom + length($`);
# 		my $to = $sentence->refid_start_token->getFrom + length($`) + length($&);
#    $NE_form = $&;
#    $type = "date";
    my $refid_start_token;
    
    while($token->getFrom != $from) {
	$token = $token->next;
    }

#		@NE2tokens = ();
    do {
#	print " " . $token->getContent . "\n";
	push @NE2tokens, $token;
	$token = $token->next;
    } while($token->getFrom < $to);
    
    my $namedEntity = Lingua::Ogmios::Annotations::SemanticUnit->newNamedEntity(
	{'form' => $NE_form,
	 'named_entity_type' => $type,
	 'list_refid_token' => \@NE2tokens,
	});
    

    return($document->getAnnotations->addSemanticUnit($namedEntity));
}


# sub _processBasicNER {
#     my ($self, $lang) = @_;

#      warn "[LOG] POS tagger\n";

# #     $lang = $self->_documentSet->[0]->getAnnotations->getLanguage;

# #     return($self->_exec_command($self->_defineCommandLine($self->_config->commands($lang)->{TreeTagger_CMD} . " < " . $self->_input_filename . ">" . $self->_output_filename)));

#     warn "[LOG]\n";
# }

# sub _inputBasicNER {
#     my ($self) = @_;

#     warn "[LOG] making input\n";
    
#     warn "[LOG] done\n";
# }


# sub _outputParsing {
#     my ($self) = @_;

#     warn "[LOG] . Parsing " . $self->_output_filename . "\n";

#     warn "[LOG] done\n";
# }

sub run {
    my ($self, $documentSet) = @_;

    # Set variables according the the configuration
    $self->_documentSet($documentSet);

    warn "*** TODO: check if the level exists\n";

    warn "[LOG] " . $self->_config->comments . " ...     \n";

    $self->BasicNER;

#     my $command_line = $self->_processBasicNER;

#     if ($self->_position eq "last") {
# 	# TODO
    if (($self->_position eq "last") && ($self->_no_standard_output)) {
	warn "print no standard output\n";
    } else {
# 	$self->_outputParsing;
    }
#     $self->_outputParsing;


    # Put log information 

    my $information = { 'software_name' => $self->_config->name,
			'comments' => $self->_config->comments,
			'command_line' => "",
			'list_modified_level' => ['semantic_unit_level'],
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

