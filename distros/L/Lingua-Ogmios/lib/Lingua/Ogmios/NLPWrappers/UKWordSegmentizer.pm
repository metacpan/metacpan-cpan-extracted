package Lingua::Ogmios::NLPWrappers::UKWordSegmentizer;


our $VERSION='0.1';


use Lingua::Ogmios::NLPWrappers::Wrapper;

use Lingua::Ogmios::Annotations::Word;

use Encode qw(:fallbacks);;

use strict;
use warnings;

our @ISA = qw(Lingua::Ogmios::NLPWrappers::Wrapper);

sub new {
    my ($class, $config, $tmpfile_prefix, $logfile, $position, $no_standard_output) = @_;

    warn "[LOG]    Creating a wrapper of the UK Word segmentizer\n";


    my $UKWordseg = $class->SUPER::new($config, $tmpfile_prefix, $logfile, $position, $no_standard_output);

    $UKWordseg->_input_filename($tmpfile_prefix . ".ukWSeg.in");
    $UKWordseg->_output_filename($tmpfile_prefix . ".ukWSeg.out");

    return($UKWordseg);

}

sub _inputUKWS {
    my ($self) = @_;

    my $token;
    my $corpus_in = "";
    my $document;

    warn "[LOG] making UK Word segmentizer input\n";

    foreach $document (@{$self->_documentSet}) {
	foreach $token (@{$document->getAnnotations->getTokenLevel->getElements}) {
#	warn "$token: " . $token->getContent . ";\n";
	    $corpus_in .= $token->getContent;
	}
    }
    $corpus_in =~ s/\x{A0}/ /go;
    

    open FILE_IN, ">" . $self->_input_filename;
    

    print FILE_IN Encode::encode("UTF-8", $corpus_in, Encode::FB_DEFAULT); #$corpus_in;

    close FILE_IN;

    warn "[LOG] done\n";
}


sub _processUKSW {
    my ($self, $lang) = @_;

    warn "[LOG] wordsegmentation with a uk\n";

#     warn "\tLanguage for the documentSet: " .  $self->_documentSet->[0]->getAnnotations->getLanguage . "\n";
    $lang = $self->_documentSet->[0]->getAnnotations->getLanguage;

    if (defined $self->_config->commands($lang)) {
#     warn $self->_config->commands($lang)->{WSSegmentizer_CMD} . "\n";;

    return($self->_exec_command($self->_defineCommandLine($self->_config->commands($lang)->{WordSegmentizer_CMD} . " < " . $self->_input_filename . ">" . $self->_output_filename)));
    } else {
	warn "No segmentizer defined for $lang\n";
    return(undef);
    }
    warn "[LOG]\n";
}

sub _outputParsing {
    my ($self) = @_;

    my $line;
    my @words;
    my $token;

    my $doc_idx;
    my $word_shift;
    my $word_idx;
    my $full_idx;
    my $full;

    my $isInNE;
    my $IsNE;

    my $word_start = 0;
    my $word_end = 0;

    my $word;

    my @Word2tokens;
    my $word_type;

    my $document;

    my $word_form;

    warn "[LOG] . Parsing " . $self->_output_filename . "\n";

    open FILE_OUT, $self->_output_filename or warn "Can't open the file " . $self->_output_filename;;
#    binmode(FILE_OUT, ":utf8");

    while($line = <FILE_OUT>) {
	chomp $line;
	if ($line ne "") {
	    push @words, $line;
	}

    }
    close FILE_OUT;

    $word_type = 0;
    $word_idx = 0;
    $word_shift = 0;
    $isInNE = 0;
    $IsNE = 0;

    my $token_content;

    foreach $document (@{$self->_documentSet}) {
	$doc_idx = 0;

# 	warn "Processing document " . $document ->getId . "\n";

	@Word2tokens = ();
	$word_shift = 0;
	$word_form = "";
	$word_type = 0;
	for($doc_idx = 0; $doc_idx < scalar(@{$document->getAnnotations->getTokenLevel->getElements});$doc_idx++) {
# 	    warn "\n";
	    $token = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];
	    $token_content = Encode::encode("iso-8859-1", $token->getContent, Encode::FB_DEFAULT);
	    $isInNE = $document->getAnnotations->getSemanticUnitLevel->existsElementFromIndex("list_refid_token", $token->getId);
#   	    warn "(0) -- " . ($isInNE*1) . " " .  $token->getContent . " / $token_content (word $word_idx / token $doc_idx)\n";

	    if ((!$isInNE) && (scalar(@Word2tokens) != 0)) {
#  		warn "(b) Add word \"$word_form\" ($word_type)\n";
		$word = Lingua::Ogmios::Annotations::Word->new(
		    {'form' => $word_form,
		     'list_refid_token' => \@Word2tokens,
		     'isNE' => $IsNE,
		    });
		$document->getAnnotations->addWord($word);
		@Word2tokens = ();
		$IsNE = 0;
		$word_shift = 0;
		$word_form = "";
		$word_type = 0;
		$isInNE = 0;
	    }
# 	    if ($word_idx < scalar(@words)) {
# 		warn "(0b) " . $words[$word_idx] . ", " . $token->getContent . " / $token_content\n";
# 	    }
	    
	    if (($word_idx < scalar(@words)) && (index($words[$word_idx], $token_content) == 0)) {
#  		warn "in if\n";
		push @Word2tokens, $token;
		$IsNE ||= $isInNE;

		$word_start = $token->getId;
		$word_form .= $token->getContent;
		$word_type ||= (($token->getType ne "sep") && ($token->getType ne "symb"));
		$word_shift = length($token_content);
		$doc_idx++;
		if ($doc_idx >= scalar(@{$document->getAnnotations->getTokenLevel->getElements})) {
#  		    warn "out\n";
 		    $word_end = $token->previous->getId;
#		    next;
		} else {

		    $token = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];
		    $token_content = Encode::encode("iso-8859-1", $token->getContent, Encode::FB_DEFAULT);
		    $isInNE = $document->getAnnotations->getSemanticUnitLevel->existsElementFromIndex("list_refid_token", $token->getId);
		    $word_end = $token->getId;
#  		    warn "    (1) -- $isInNE " .  $token->getContent . "(word $word_idx / token $doc_idx)\n";
		    while(index($words[$word_idx], $token_content, $word_shift) == $word_shift) {
# 			warn $token->getContent . "\n";
			push @Word2tokens, $token;
			$IsNE ||= $isInNE;
			$word_form .= $token->getContent;
			$word_type ||= (($token->getType ne "sep") && ($token->getType ne "symb"));
			$word_shift += length($token_content);
			$doc_idx++;
			if ($doc_idx >= scalar(@{$document->getAnnotations->getTokenLevel->getElements})) {
# 			warn "out\n";
			    $word_end = $token->previous->getId;
			    next;
			}
			$token = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];
			$token_content = Encode::encode("iso-8859-1", $token->getContent, Encode::FB_DEFAULT);
			$isInNE = $document->getAnnotations->getSemanticUnitLevel->existsElementFromIndex("list_refid_token", $token->getId);
			$word_end = $token->getId;
			
#   			warn "\t(2a) -- $isInNE " . $token->getContent . "(word $word_idx / token $doc_idx)\n";
		    }
		}
		$doc_idx--;
#   		warn "(3) -- $isInNE " . $words[$word_idx] . " / " . $token->getContent . "(word $word_idx / token $doc_idx)\n";

		if (!$isInNE) {
		    if ($word_type != 0) {
#  			warn "Add word \"$word_form\" ($word_type)" . "(word $word_idx / token $doc_idx)\n";
			$word = Lingua::Ogmios::Annotations::Word->new(
			    {'form' => $word_form,
			     'list_refid_token' => \@Word2tokens,
			     'isNE' => $IsNE,
			    });
			$document->getAnnotations->addWord($word);
		    } else {
# 			warn "Go here\n";
			# TODO XXXX
		    }
		    @Word2tokens = ();
		    $IsNE = 0;
		    $word_shift = 0;
		    $word_form = "";
		    $word_type = 0;

		    $isInNE = 0;
		}
#   		warn "(4a) -- $isInNE " . $words[$word_idx] . " / " . $token->getContent . "(word $word_idx / token $doc_idx)\n";
		while(($doc_idx + 1< scalar(@{$document->getAnnotations->getTokenLevel->getElements})) &&
		      ($document->getAnnotations->getTokenLevel->getElements->[$doc_idx+1]->isSep)) {
		    $doc_idx++;
		}
#		do {
		    $word_idx++;
#		    warn "(W) " .  $words[$word_idx] . "\n";
#		} while(($word_idx < scalar(@words)) && (Encode::decode("iso-8859-1", $words[$word_idx], Encode::FB_DEFAULT) =~ /^\s+$/o));

#   		warn "(4b) -- $isInNE " . $words[$word_idx] . " / " . $token->getContent . "(word $word_idx / token $doc_idx)\n";
	    } else {
#  		warn "Check special cases\n";
		if (($word_idx < scalar(@words)) && (index($token_content, $words[$word_idx]) == 0) 
		    && ($token->next->getContent eq "'")) {
		    # probably a elision
#   		    warn "probably a elision\n";
		    push @Word2tokens, $token;
		    $IsNE ||= $isInNE;

		    $word_start = $token->getId;
		    $word_form = $words[$word_idx];
		    $word_type ||= (($token->getType ne "sep") && ($token->getType ne "symb"));
		    $word_shift = length($token_content);

		    if (($self->_documentSet->[0]->getAnnotations->getLanguage eq "EN") &&
			(lc($word_form) eq "ca")){
			$word_form .= "n";
# 			warn "correction ca + n't as can + n't\n";
		    }

		    $word = Lingua::Ogmios::Annotations::Word->new(
			{'form' => $word_form,
			 'list_refid_token' => \@Word2tokens,
			 'isNE' => $IsNE,
			});
		    $document->getAnnotations->addWord($word);
#  		    warn "(b) Add word \"$word_form\" ($word_type)\n";
		    @Word2tokens = ();
		    $IsNE = 0;
		    $word_form = "";
		    $word_type = 0;

		    push @Word2tokens, $token;
		    if ($token_content ne $words[$word_idx]) {
			$word_form = substr($token->getContent, length($words[$word_idx]));
		    }
		    $word_idx++;
#  		    warn "word_form: $word_form\n";
		    $doc_idx++;
		    while($word_form ne $words[$word_idx]) {
			$token = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];
			$token_content = Encode::encode("iso-8859-1", $token->getContent, Encode::FB_DEFAULT);
			$isInNE ||= $document->getAnnotations->getSemanticUnitLevel->existsElementFromIndex("list_refid_token", $token->getId);
			push @Word2tokens, $token;
			$word_form .= $token->getContent;
#  			warn "word_form: $word_form\n";
			$doc_idx++;
		    }
		    $word = Lingua::Ogmios::Annotations::Word->new(
			{'form' => $word_form,
			 'list_refid_token' => \@Word2tokens,
			 'isNE' => $IsNE,
			});
		    $document->getAnnotations->addWord($word);
#   			    warn "(b) Add word \"$word_form\" ($word_type)\n";
		    @Word2tokens = ();
		    $IsNE = 0;
		    $word_form = "";
		    $word_type = 0;
		    $word_idx++;
		    if (!$document->getAnnotations->getTokenLevel->getElements->[$doc_idx]->isSep) {
			$doc_idx--;
		    }
# 		    warn "End of probably elision\n";
		} else {
		    if ($isInNE) {
# 			warn "Named Entity\n";
			push @Word2tokens, $token;
			$IsNE ||= $isInNE;
			$word_form .= $token->getContent;
			$word_type ||= (($token->getType ne "sep") && ($token->getType ne "symb"));
			$word_shift += length($token_content);
		    }  else {
#  			warn "word_type: $word_type\n";
			if ($word_type != 0) {
# 			    warn "(b) Add word \"$word_form\" ($word_type)\n";
			    $word = Lingua::Ogmios::Annotations::Word->new(
				{'form' => $word_form,
				 'list_refid_token' => \@Word2tokens,
				 'isNE' => $IsNE,
				});
			    $document->getAnnotations->addWord($word);
			} else {
			    my $simple_word_form = "";
			    if (($word_idx < scalar(@words)) && (index($token_content, $words[$word_idx]) == 0)) {
#  				warn "Seg word is inside current token\n";
#  				warn "Usually it's foreign words\n";
				do {
				    $simple_word_form .= $words[$word_idx];
				    $word_idx++;
				} while(($word_idx < scalar(@words)) && ($token_content ne $simple_word_form));
# 			    } else {
# 				warn "(5aa) -- $isInNE " . $words[$word_idx] . " / " . $token->getContent . " / " . $token->getType . " (word $word_idx / token $doc_idx)\n";
# 				if (($word_idx < scalar(@words)) && (index($words[$word_idx], $token_content))) {
# 				    warn "current token is inside Seg word\n";
# 				    warn scalar(@Word2tokens) . "\n";
# # 				    if ($document->getAnnotations->getTokenLevel->getElements->[$doc_idx]->isSep) {
# # 					$word_form = $token->getContent;
# # 					$word_type ||= (($token->getType ne "sep") && ($token->getType ne "symb"));
# # 					$word_start = $token->getId;
# # 					push @Word2tokens, $token;
# # 					$word_idx++;
# # 				    }
# #				    warn "Usually it's foreign words\n";
# 				}

# 				warn "(5a) -- $isInNE " . $words[$word_idx] . " / " . $token->getContent . " / " . $token->getType . " (word $word_idx / token $doc_idx)\n";
# 				while(($doc_idx < scalar(@{$document->getAnnotations->getTokenLevel->getElements})) &&
# 				      ($document->getAnnotations->getTokenLevel->getElements->[$doc_idx]->isSep)) {
# 				    $doc_idx++;
# 				}
# 				if (Encode::decode("iso-8859-1", $words[$word_idx], Encode::FB_DEFAULT) =~ /^\s+$/o) {
# 		while(($doc_idx < scalar(@{$document->getAnnotations->getTokenLevel->getElements})) &&
# 		      (!$document->getAnnotations->getTokenLevel->getElements->[$doc_idx]->isSep)) {
# 		    $doc_idx++;
# 				warn "(5b) -- $isInNE " . $words[$word_idx] . " / " . $token->getContent . " / " . $token->getType . " (word $word_idx / token $doc_idx)\n";
# 		}
#				    $word_idx++;
# 				}
# 				warn "(5c) -- $isInNE " . $words[$word_idx] . " / " . $token->getContent . " / " . $token->getType . " (word $word_idx / token $doc_idx)\n";
			    }
			}
# 			warn "out\n";
			@Word2tokens = ();
			$IsNE = 0;
			$word_shift = 0;
			$word_form = "";
			$word_type = 0;

			$isInNE = 0;

		    }
		}
	    }
	}
    }    


}

sub run {
    my ($self, $documentSet) = @_;

    # Set variables according the the configuration
    $self->_documentSet($documentSet);

    warn "[LOG] UK Word segmentizer...     \n";

    warn "*** TODO: check if the level exists\n";

    # Generating the input for one document
    $self->_inputUKWS;

    # Running the uk segmentizer
    my $command_line = $self->_processUKSW;

    if (defined $command_line) {
	# Parsing the output
	$self->_outputParsing;

	# Put log information 
	my $information = { 'software_name' => 'uk word segmentizer',
			    'comments' => 'Word Segmentation\n',
			    'command_line' => "$command_line",
			    'list_modified_level' => ['word_level'],
	};
	
	$self->_log($information);

	my $document;
	foreach $document (@{$documentSet}) {
	    $document->getAnnotations->addLogProcessing(
		Lingua::Ogmios::Annotations::LogProcessing->new(
		    { 'comments' => 'Found ' . $document->getAnnotations->getWordLevel->getSize . ' words \n',
		    }
		)
		);
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

