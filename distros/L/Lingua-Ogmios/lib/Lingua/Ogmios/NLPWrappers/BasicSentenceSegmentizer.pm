package Lingua::Ogmios::NLPWrappers::BasicSentenceSegmentizer;


our $VERSION='0.1';


use Data::Dumper;

use Lingua::Ogmios::NLPWrappers::Wrapper;

use Lingua::Ogmios::Annotations::Sentence;

# use Lingua::Identify qw(:language_identification);

use Lingua::Identify qw/langof set_active_languages/;

# qw/langof set_active_languages/

use strict;
use warnings;

our @ISA = qw(Lingua::Ogmios::NLPWrappers::Wrapper);

sub new {
    my ($class, $config, $tmpfile_prefix, $logfile, $position, $no_standard_output) = @_;
    my $lang;
    my $lang2;

    warn "[LOG]    Creating a wrapper of the basic sentence segmentizer\n";

    my $SentenceSeg = $class->SUPER::new($config, $tmpfile_prefix, $logfile, $position, $no_standard_output);

    # if (scalar(keys %{$SentenceSeg->_config->configuration}) > 0) {
    # 	$SentenceSeg->{'sentenceSeparatorCharList'}->{"FR"} = "?.!";
    # 	$SentenceSeg->{'sentenceSeparatorCharList'}->{"EN"} = "?.!";
    # 	warn "*** SENTENCESEPARATORCHARLIST is not set ***\n";
    # }
    if (defined $SentenceSeg->_config->configuration->{'CONFIG'}) {
	foreach $lang (keys %{$SentenceSeg->_config->configuration->{'CONFIG'}}) {
	    if ($lang =~ /language=([\w]+)/io) {
		$lang2 = $1;

		$SentenceSeg->_setOption($lang2, "LANG_LIST", "lang_list", "en,fr,de,es,it");
		# warn "$lang2: " . $SentenceSeg->{"lang_list"}->{$lang2} . "\n";
		$SentenceSeg->{"lang_list"}->{$lang2} = [split /[, ]/, $SentenceSeg->{"lang_list"}->{$lang2}];
		# warn "$lang2: " . join('/', @{$SentenceSeg->{"lang_list"}->{$lang2}}) . "\n";

		if (exists $SentenceSeg->_config->configuration->{'CONFIG'}->{$lang}->{LANGID_METHODS}) {
		    $SentenceSeg->{'lang_methods'}->{$lang2} = {'method' => $SentenceSeg->_config->configuration->{'CONFIG'}->{$lang}->{LANGID_METHODS}};
		    # warn Dumper($SentenceSeg->{'lang_methods'}->{$lang2});
		} else {
		    $SentenceSeg->{'lang_methods'}->{$lang2} = {'method' => {
			smallwords => 1,
			prefixes1  => 0,
			prefixes2  => 0,
			prefixes3  => 0,
			prefixes4  => 0,
			suffixes1  => 1,
			suffixes2  => 1,
			suffixes3  => 1,
			suffixes4  => 0,
			ngrams1    => 1,
			ngrams2    => 1.5,
			ngrams3    => 0,
			ngrams4    => 0,
								},
		    };
		    # warn Dumper($SentenceSeg->{'lang_methods'}->{$lang2});
		}


		if (defined $SentenceSeg->_config->configuration->{'CONFIG'}->{$lang}->{"SENTENCESEPARATORCHARLIST"}) {
		    $SentenceSeg->{'sentenceSeparatorCharList'}->{$lang2} = $SentenceSeg->_config->configuration->{'CONFIG'}->{$lang}->{"SENTENCESEPARATORCHARLIST"};
		} else {
		    $SentenceSeg->{'sentenceSeparatorCharList'}->{"FR"} = "?.!";
		    $SentenceSeg->{'sentenceSeparatorCharList'}->{"EN"} = "?.!";
		    warn "*** SENTENCESEPARATORCHARLIST is not set ***\n";
		}
	    } else {
		$SentenceSeg->{'sentenceSeparatorCharList'}->{"FR"} = "?.!";
		$SentenceSeg->{'sentenceSeparatorCharList'}->{"EN"} = "?.!";
		warn "*** SENTENCESEPARATORCHARLIST is not set ***\n";
	    }
	}
    } else {
	$SentenceSeg->{'sentenceSeparatorCharList'}->{"FR"} = "?.!";
	$SentenceSeg->{'lang_methods'}->{'FR'} = "en,fr,de,es,it";
	$SentenceSeg->{'sentenceSeparatorCharList'}->{"EN"} = "?.!";	
	$SentenceSeg->{'lang_methods'}->{'EN'} = "en,fr,de,es,it";
    }
#     $SentenceSeg->_input_filename($tmpfile_prefix . ".SentSeg.in");
#     $SentenceSeg->_output_filename($tmpfile_prefix . ".SentSeg.out");

    return($SentenceSeg);

}

sub run {
    my ($self, $documentSet) = @_;

    my $sentence;
    my $document;
    my $sentForm;

    # Set variables according the the configuration
    $self->_documentSet($documentSet);

    if ($documentSet->[0]->getAnnotations->existsSentenceLevel) {
	warn "sentences exist in the first document\n";
	warn "  Assuming that no sentence segmentation is required for the current document set\n";
#	return(0);
    } else {
	warn "[LOG] Sentence segmentizer...     \n";

	$self->_segmentation;

	# Put log information 
	my $information = { 'software_name' => 'basic internal sentence segmentizer',
			    'comments' => 'Sentence Segmentation\n',
			    'command_line' => "",
			    'list_modified_level' => ['sentence_level'],
	};
	$self->_log($information);
	foreach $document (@{$documentSet}) {
	    $document->getAnnotations->addLogProcessing(
		Lingua::Ogmios::Annotations::LogProcessing->new(
		    { 'comments' => 'Found ' . $document->getAnnotations->getSentenceLevel->getSize . ' sentences\n',
		    }
		)
		);
	}    
    }

    if ($self->_position eq "last") {
	if ($self->_no_standard_output eq "SENT") {
	    warn "print no standard output\n";
	    
	    foreach $document (@{$documentSet}) {
		foreach $sentence (@{$document->getAnnotations->getSentenceLevel->getElements}) {
		    $sentForm = $sentence->getForm;
		    print $sentForm;
		    if ($sentForm !~ /\n$/) {
			print "\n";
		    }
		}
	    }
	}
	if ($self->_no_standard_output eq "SENTLANG") {
	    warn "print no standard output\n";
	    
	    foreach $document (@{$documentSet}) {
		foreach $sentence (@{$document->getAnnotations->getSentenceLevel->getElements}) {
		    $sentForm = $sentence->getForm;
		    $sentForm =~ s/\n/ /g;
#		    print $sentence->lang . "\t:\t" . $sentForm;
		    if (!defined $sentence->lang) {
			print "INT";
		    } else {
			print $sentence->lang;
		    }
		    print "\t:\t" . $sentForm;
		    if ($sentForm !~ /\n$/) {
			print "\n";
		    }
		}
	    }
	}
	if ($self->_no_standard_output eq "SENT+INFO") {
	    warn "print no standard output\n";
	    print "# detected language\t:\tsentence form\t:\tnb of chars (v1 -- length(form))\t:\tnb of chars (v2 -- offset diff)\t:\tnb of words\n";
	    foreach $document (@{$documentSet}) {
		foreach $sentence (@{$document->getAnnotations->getSentenceLevel->getElements}) {
		    $sentForm = $sentence->getForm;
		    $sentForm =~ s/\n/ /g;
#		    print $sentence->lang . "\t:\t" . $sentForm;
		    if (!defined $sentence->lang) {
			print "INT";
		    } else {
			print $sentence->lang;
		    }
		    my $sentNbChar1 = length($sentForm);
		    my $sentNbChar2 = $sentence->end_token->getTo - $sentence->start_token->getFrom + 1;
		    my $sentNbWord = scalar(@{$sentence->getWordsFromSentence($document)}); 
		    chomp $sentForm;
		    print "\t:\t" . $sentForm;
		    print "\t:\t" . $sentNbChar1;
		    print "\t:\t" . $sentNbChar2;
		    print "\t:\t" . $sentNbWord;

		    if ($sentForm !~ /\n$/) {
			print "\n";
		    }
		}
	    }
	}
    }

    $self->getTimer->_printTimesInLine($self->_config->name);
    warn "[LOG] done\n";
}

sub isSentenceEnd {
    my ($self, $token, $lang, $doc_idx, $sent_form, $tokensTail, $document) = @_;
    
    my $endSent;
    my $currenttoken;
    my $i;

    if (!defined $lang) {
	warn "language not defined, default is EN\n";
	$lang = 'EN';
    }
    # warn "$lang\n";
    # warn $self->{'sentenceSeparatorCharList'}->{$lang} . "\n";
    # warn $$token->getContent . "\n";

    if (index($self->{'sentenceSeparatorCharList'}->{$lang}, $$token->getContent) != -1) {
	$endSent = 1;
    } else {
	$endSent = 0;
    }
    # warn "$endSent\n";

    if ($endSent == 1) {
	# warn "ckeck dots\n";
	$endSent = $self->_dots($token, $lang, $doc_idx, $sent_form, $tokensTail, $document);

	# warn "ckeck acronyms\n";
	$endSent &&= $self->_acronyms($$token, $lang, $doc_idx, $sent_form, $tokensTail, $document);

	# inside word
	if ($document->getAnnotations->getWordLevel->existsElementFromIndex('list_refid_token', $$token->getId)) {
	    # warn " " . $self->currentDocument->getAnnotations->getWordLevel->getElementByToken($$token)->[0]->end_token->getContent . "\n";
	    $endSent &&= $self->currentDocument->getAnnotations->getWordLevel->getElementByToken($$token)->[0]->end_token->equals($$token);
	    # warn "==> $endSent\n";
	}
	# warn "$endSent\n";
	# # case ... 
	# $i=0;
	# $currenttoken = $$token;
	# while(($i < 3) && ($currenttoken->getContent eq ".") && (defined $currenttoken->next)) {
	#     warn $currenttoken->getContent . "\n";
	#     $i++;
	#     $currenttoken = $currenttoken->next;
	# }
	# if (($i >= 3) && (defined $currenttoken)) {
	#     warn "No\n";
	#     $endSent = 0;

	#     while(($currenttoken->isSep) && (defined $currenttoken->next)) {
	#         $currenttoken = $currenttoken->next;
	#     }
	#     if (defined $currenttoken) {
	# 	warn $currenttoken->isAlpha . " : " . substr($currenttoken->getContent,0,1) . "\n";
	#         if ($currenttoken->getContent eq ')') {
	# 	    $endSent = 0;
	# 	    # $$doc_idx += 2;
	# 	    # if (defined $sent_form) {
	# 	    # 	$$sent_form .= $$token->getContent;
	# 	    # 	$$sent_form .= $$token->next->getContent;
	# 	    # 	$$token = $$token->next->next;
	# 	    # }
	# 	    # if (defined $tokensTail) {
	# 	    # 	push @$tokensTail, $$token;
	# 	    # 	push @$tokensTail, $$token->next;
	# 	    # }
	#         } elsif (($currenttoken->isAlpha) && (substr($currenttoken->getContent,0,1) eq uc(substr($currenttoken->getContent,0,1)) )) {
	# 	    $endSent = 1;
	#         } else {
	# 	    $endSent = 0;
	# 	}
	# 	    $$doc_idx += 2;
	# 	    if (defined $sent_form) {
	# 		$$sent_form .= $$token->getContent;
	# 		$$sent_form .= $$token->next->getContent;
	# 		$$token = $$token->next->next;
	# 	    }
	# 	    if (defined $tokensTail) {
	# 		push @$tokensTail, $$token;
	# 		push @$tokensTail, $$token->next;
	# 	    }
	#     }
	# } else {
	#     $endSent = 1;
	# }
    }
    # warn "-> $endSent\n";
    return($endSent);

}

sub _acronyms {
    my ($self, $token, $lang, $doc_idx, $sent_form, $tokensTail, $document) = @_;

    my %acronyms = ("etc" => 1, "etc." => 1,
		    "e.g." => 1, "e.g" => 1,
		    "i.e." => 1, "i.e" => 1,
	);
    my @words;
    my $word;
    my $i;
    my $endSent = 1;
    my $nextToken;

    $nextToken = $token->next;
    while((defined $nextToken) && ($nextToken->isSep)) {
	$nextToken = $nextToken->next;	
    }

    # warn "===" . $token->getContent . "\n";
    if ((defined $nextToken) && (defined $token->previous)) {
	# warn "   " . $nextToken->getContent . "\n";
	# warn "   " . $token->previous->getContent . "\n";
	if ($document->getAnnotations->getSemanticUnitLevel->existsElementFromIndex("list_refid_token", $nextToken->getId)) {
		$endSent = 0;
	} else {
	@words = @{$self->currentDocument->getAnnotations->getWordLevel->getElementByToken($token->previous)};
	# if (scalar(@words) > 0) {
	$i = 0;
	# foreach $word (@words) {
	#     warn $word->getForm . "\n";
	# }
	while(($i < scalar(@words)) && 
	      (!(exists($acronyms{$words[$i]->getForm}) || (exists($acronyms{$words[$i]->getForm}))))) {
	    # warn "=> " . $words[$i]->getForm . "\n";
	    $i++;
	}
	if ($i < scalar(@words)) {
	    # warn "OK: " . $nextToken->getContent . " " . substr($nextToken->getContent,0,1) . "\n";
	    if (($nextToken->isAlpha) && (substr($nextToken->getContent,0,1) eq uc(substr($nextToken->getContent,0,1)) )) {
	    # warn "OK2\n";
		$endSent = 1;
	    } else {
		$endSent = 0;
	    }	    
	}
	}
    }
    # warn "-> $endSent\n";
    return($endSent);
}

sub _dots {
    my ($self, $token, $lang, $doc_idx, $sent_form, $tokensTail, $document) = @_;

    my $endSent;
    my $currenttoken;
    my $i;

    # case ... 
    $i=0;
    $currenttoken = $$token;
    while(($i < 3) && ($currenttoken->getContent eq ".") && (defined $currenttoken->next)) {
	# warn $currenttoken->getContent . "\n";
	$i++;
	$currenttoken = $currenttoken->next;
    }
    if (($i >= 3) && (defined $currenttoken) && 
	(!$document->getAnnotations->getSectionLevel->existsElementFromIndex("to", $currenttoken->getId))) {
	# warn "No\n";
	$endSent = 0;

	while(($currenttoken->isSep) && (defined $currenttoken->next) && 
	      (!$document->getAnnotations->getSectionLevel->existsElementFromIndex("to", $currenttoken->getId))) {
	    $currenttoken = $currenttoken->next;
	}
	if (defined $currenttoken) {
	    # warn $currenttoken->isAlpha . " : " . substr($currenttoken->getContent,0,1) . "\n";
	    if (($currenttoken->getContent eq ')') || 
		($document->getAnnotations->getSemanticUnitLevel->existsElementFromIndex("list_refid_token", $currenttoken->getId))) {
		$endSent = 0;
		# $$doc_idx += 2;
		# if (defined $sent_form) {
		# 	$$sent_form .= $$token->getContent;
		# 	$$sent_form .= $$token->next->getContent;
		# 	$$token = $$token->next->next;
		# }
		# if (defined $tokensTail) {
		# 	push @$tokensTail, $$token;
		# 	push @$tokensTail, $$token->next;
		# }
	    } elsif (($currenttoken->isAlpha) && (substr($currenttoken->getContent,0,1) eq uc(substr($currenttoken->getContent,0,1)) )) {
		$endSent = 1;
	    } elsif (!$document->getAnnotations->getSectionLevel->existsElementFromIndex("to", $currenttoken->getId)) {
		$endSent = 1;
	    } else {
		$endSent = 0;
	    }
	    $$doc_idx += 2;
	    if (defined $sent_form) {
		$$sent_form .= $$token->getContent;
		$$sent_form .= $$token->next->getContent;
		$$token = $$token->next->next;
	    }
	    if (defined $tokensTail) {
		push @$tokensTail, $$token;
		push @$tokensTail, $$token->next;
	    }
	}
    } else {
	$endSent = 1;
    }
    return($endSent);
}

sub _segmentation {
    my ($self) = @_;

    my $start_token;    
    my $end_token;    

    my $document;
    my $doc_idx;
    my $lang;
    my $token;
    my $isNE;
    my $isWord;

    my $beginSection;
    my $endSection;

    my $sentence;
    my $sentence_form;

    foreach $document (@{$self->_documentSet}) {
	$lang = $document->getAnnotations->getLanguage;
	$self->currentDocument($document);

	$doc_idx = 0;
	$start_token = undef; # $document->getAnnotations->getSectionLevel->getElements->[0];
	$end_token = undef;

# 	warn "Processing document " . $document ->getId . "\n";	

	for($doc_idx = 0; $doc_idx < scalar(@{$document->getAnnotations->getTokenLevel->getElements});$doc_idx++) {
	    do {
		$token = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];
 		$doc_idx++;
	    } while(($doc_idx < scalar(@{$document->getAnnotations->getTokenLevel->getElements})) && ($token->isSep));
	    $doc_idx--;
	    $start_token = $token;
	    $sentence_form = "";
#	    warn $self->isSentenceEnd(\$token, $lang, \$doc_idx, \$sentence_form, undef, $document) . "\n";

	    # TODO take into account a NE follown by a capitalized word (which is not a NE)
	    # while(($doc_idx < scalar(@{$document->getAnnotations->getTokenLevel->getElements})) && 
	    # 	  ((!($self->isSentenceEnd(\$token, $lang, \$doc_idx, \$sentence_form, undef))) || 
	    # 	   ($document->getAnnotations->getSemanticUnitLevel->existsElementFromIndex("list_refid_token", $token->getId)) || 
	    # 	   ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId))) && 
	    # 	  (!$document->getAnnotations->getSectionLevel->existsElementFromIndex("to", $token->getId))) {
	    while(($doc_idx < scalar(@{$document->getAnnotations->getTokenLevel->getElements}))  && 
		  (!$document->getAnnotations->getSectionLevel->existsElementFromIndex("to", $token->getId)) && 
		  (!$self->isSentenceEnd(\$token, $lang, \$doc_idx, \$sentence_form, undef, $document)) #&& 
		  # (
		  #  # ($document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId)) 
#		   || ($document->getAnnotations->getSemanticUnitLevel->existsElementFromIndex("list_refid_token", $token->getId)))
		  #  )
		) {
		$sentence_form .= $token->getContent;
		# warn $token->getContent. "\n";
		# warn $document->getAnnotations->getSemanticUnitLevel->existsElementFromIndex("list_refid_token", $token->getId) . "\n";
		# warn $document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId) . "\n";
		# warn "$sentence_form (1)\n";
		$end_token = $token;
		$doc_idx++;
		$token = $document->getAnnotations->getTokenLevel->getElements->[$doc_idx];
		# warn $self->isSentenceEnd(\$token, $lang, \$doc_idx, \$sentence_form, undef, $document) . "\n";
	    }
	    # warn "$sentence_form (1b)\n";
	    if ($doc_idx < scalar(@{$document->getAnnotations->getTokenLevel->getElements})) {
		$sentence_form .= $token->getContent;
		# warn "$sentence_form (2)\n";
		$end_token = $token;
		if (!$document->getAnnotations->getSectionLevel->existsElementFromIndex("to", $token->getId)) {
		    my $end_token_tail = $token;
		    my $sentence_form_tail = "";
		    my @tokensTail;
		    my $tail = 0;
		    do {
			
			$end_token_tail = $end_token_tail->next;
			if (defined $end_token_tail) {
			    $tail ||= $self->isSentenceEnd(\$end_token_tail, $lang, \$doc_idx, \$sentence_form_tail, \@tokensTail, $document);
			    push @tokensTail, $end_token_tail;
			    $sentence_form_tail .= $end_token_tail->getContent;
			    # warn "$sentence_form_tail (3)\n";
			}
			$doc_idx++;
		    } while (($doc_idx < scalar(@{$document->getAnnotations->getTokenLevel->getElements})) 
			     && (!$document->getAnnotations->getSectionLevel->existsElementFromIndex("to", $end_token_tail->getId))
			     && (($end_token_tail->isSep) || ($self->isSentenceEnd(\$end_token_tail, $lang, \$doc_idx, undef, undef, $document))));
		    $doc_idx--;
		    if ($tail) {
			pop @tokensTail;
			while((scalar(@tokensTail) > 0) && ($tokensTail[$#tokensTail]->isSep)) {
			    pop @tokensTail;
			}
			if (scalar(@tokensTail) > 0) {
			    foreach my $tk (@tokensTail) {
				$sentence_form .= $tk->getContent; 				
				# warn "$sentence_form (4)\n";
			    }
			    $end_token = $tokensTail[$#tokensTail];
			}
		    }
		}
	    }

	    if ((defined $start_token) && 
		((($document->getAnnotations->getSectionLevel->existsElementFromIndex("to", $start_token->getId) == 1) 
		  && ((! $start_token->equals($end_token)) || (!$start_token->isSep)))
		 || ((defined $end_token) && (! $start_token->equals($end_token))))) {

		if (!defined ($end_token)) {$end_token = $start_token;};

		# my $method = {'method' => {
		#     smallwords => 1,
		#     prefixes1  => 0,
		#     prefixes2  => 0,
		#     prefixes3  => 0,
		#     prefixes4  => 0,
		#     suffixes1  => 1,
		#     suffixes2  => 1,
		#     suffixes3  => 1,
		#     suffixes4  => 0,
		#     ngrams1    => 1,
		#     ngrams2    => 1.5,
		#     ngrams3    => 0,
		#     ngrams4    => 0,
		# 	      },
		# };

		# warn Dumper($method);

#		'active-languages' => [ 'en', 'de', 'fr'],
#			      'max-size' => 50,
#		warn "$lang: " . join('/', @{$self->{"lang_list"}->{$lang}}) . "\n";
		set_active_languages(@{$self->{"lang_list"}->{$lang}}); # qw/en fr de es it/); #
#		warn "lang of the sentence $sentence_form : " . langof($method, $sentence_form) . "\n";
#   		warn "start sentence at " . $start_token->getId . "\n";
#   		warn "end sentence at " . $end_token->getId . "\n";
# 		warn "Sentence: $sentence_form\n";
		my $sentence = Lingua::Ogmios::Annotations::Sentence->new(
		    {'form' => $sentence_form,
		     'refid_start_token' => $start_token,
		     'refid_end_token' => $end_token,
		    });
		$sentence->lang(langof($self->{'lang_methods'}->{$lang}, $sentence_form)); # 

		$document->getAnnotations->addSentence($sentence);
	    }
	    

# 	    $isNE = $document->getAnnotations->getSemantic_UnitLevel->existsElementFromIndex("list_refid_token", $token->getId);
# 	    $isWord = $document->getAnnotations->getWordLevel->existsElementFromIndex("list_refid_token", $token->getId);

# 	    $beginSection = $document->getAnnotations->getSectionLevel->existsElementFromIndex("from", $token->getId);

# 	    $endSection = $document->getAnnotations->getSectionLevel->existsElementFromIndex("to", $token->getId);

	    

# 	    warn "Token(" . $token->getType . "): " . $token->getId . " , " . ($isNE * 1) . " ,  " . ($isWord * 1) . " , " . ($beginSection * 1) . " , " . ($endSection * 1) . "\n";

	    

# 	    if ($token->isSep) {
# 	    warn "Token(" . $token->getType . "): " . $token->getId . " , " . ($isNE * 1) . " ,  " . ($isWord * 1) . " , " . ($beginSection * 1) . " , " . ($endSection * 1) . "\n";
		
# 	    }

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

