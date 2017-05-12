package Lingua::Ogmios::NLPWrappers::HeidelTime;


our $VERSION='0.1';

use Lingua::Ogmios::NLPWrappers::Wrapper;

# use XML::LibXML;

use strict;
use warnings;

our @ISA = qw(Lingua::Ogmios::NLPWrappers::Wrapper);

sub new {
    my ($class, $config, $tmpfile_prefix, $logfile, $position, $no_standard_output) = @_;

    my $lang;
    my $lang2;

    warn "[LOG]    Creating a wrapper of the HeidelTime\n";

    my $HeidelTime = $class->SUPER::new($config, $tmpfile_prefix, $logfile, $position, $no_standard_output);

    if (defined $HeidelTime->_config->configuration->{'CONFIG'}) {
	foreach $lang (keys %{$HeidelTime->_config->configuration->{'CONFIG'}}) {
	    if ($lang =~ /language=([\w]+)/io) {
		$lang2 = $1;
		$HeidelTime->_setOption($lang2, "EXPAND_TERMS", "EXPAND_TERMS", 0);
		$HeidelTime->_setOption($lang2, "MERGE_TERMS", "MERGE_TERMS", 0);
		$HeidelTime->_setOption($lang2, "USE_DCT", "use_dct", 0);
		$HeidelTime->_setOption($lang2, "ROOTSEMF", "root_semf", undef);
		# $HeidelTime->_setOption($lang2, "CASE_SENSITIVE", "CaseSensitive", -1);
	    }
	}
    }

    $HeidelTime->_input_filename($tmpfile_prefix . ".HeidelTime.in");
    $HeidelTime->_output_filename($tmpfile_prefix . ".HeidelTime.out");

    return($HeidelTime);

}

sub _processHeidelTime {
    my ($self, $lang) = @_;

    warn "[LOG] HeidelTime\n";

    $lang = $self->_documentSet->[0]->getAnnotations->getLanguage;

    warn "[LOG] *** for the moment, ONLY for ONE document - the first ;-)\n";

    my $command_line = $self->_config->commands($lang)->{HeidelTime_CMD} . " " . $self->_input_filename . " " . $self->_config->commands($lang)->{HeidelTime_OPT};
    if (((!(defined($self->{"use_dct"}->{$lang}))) || ($self->{"use_dct"}->{$lang} == 1)) &&
	(defined $self->_documentSet->[0]->getAnnotations->getProperty("AdmissionDate"))) {
#	warn "use dct\n";
	$command_line .= " " . $self->_config->commands($lang)->{HeidelTime_DCTSWITCH} . " " . $self->_documentSet->[0]->getAnnotations->getProperty("AdmissionDate");
    }
    if (defined $self->_config->commands($lang)) {
	return($self->_exec_command($self->_defineCommandLine($command_line, undef, $self->_output_filename)));
    } else {
	warn "Heideltime not defined for $lang\n";
    return(undef);
    }

    warn "[LOG]\n";
}

sub _inputHeidelTime {
    my ($self) = @_;

    my $sentence;
    my $corpus_in = "";
    my $document;

    warn "[LOG] making HeidelTime input\n";

    foreach $document (@{$self->_documentSet}) {
	foreach $sentence (@{$document->getAnnotations->getSentenceLevel->getElements}) {
	# foreach $token (@{$document->getAnnotations->getTokenLevel->getElements}) {
	    $corpus_in .= $sentence->getForm;
	    # if ($document->getAnnotations->getSectionLevel->existsElementFromIndex("to", $token->getId)) {
	    $corpus_in .= "\n";
	#     }
	}
    }
    $corpus_in =~ s/[\x{A0}\x{2000}-\x{200B}]/ /go;
    $corpus_in =~ s/[\x{2019}\x{2032}]/\'/go;

    $corpus_in =~ s/\n\n+/\n/go;
    open FILE_IN, ">:utf8", $self->_input_filename;
    print FILE_IN $corpus_in;
    close FILE_IN;
    
    warn "[LOG] done\n";
}


sub _outputHeidelTime {
    my ($self) = @_;

    my $lang = $self->_documentSet->[0]->getAnnotations->getLanguage;
    warn "[LOG] . Parsing " . $self->_output_filename . "\n";

    warn "[LOG] *** for the moment, ONLY for ONE document - the first ;-)\n";

    my $document;
    my $line;
    my $i;

    open FILE, $self->_output_filename or die "no such file " . $self->_output_filename . "\n";
    binmode(FILE, ":utf8");
    while($line = <FILE>) {
	if ($line =~ /^<TimeML>/) {
	    last
	};
    }
    $line = <FILE>;
    $i = 0;

    my $tokenStart;
    my $tokenEnd;
    my $offset=0;
    my $term;
    my $start_sentence_offset;
    my $semFeatures;
    my $type;
    my $mod;
    my %weights;
    my $lineold;
    my $value;
    my @semfTab;

    my @undefinedRef;

# <TIMEX3 tid="t0" type="DATE" value="2000-02-01">02/01/2000</TIMEX3>

#    my @sentences = $document->getAnnotations->getSentenceLevel->getElements;
    $document = $self->_documentSet->[0];

    while($line = <FILE>) {
	if ($line =~ /<\/TimeML>/) {
	    last;
	} else {
	    # warn "i= $i\n";
# Signed electronically by : DR. Bernice Jenkins on : FRI <TIMEX3 tid="t42" type="TIME" value="2011-10-07T4:01">2011-10-07 <TIM</TIMEX3>EX3 tid="t44" type="TIME" value="2011-10-07T16:01">4:01 PM</TIMEX3>
#	    $line =~ s///g;
#	$start_sentence = $document->getAnnotations->getSentenceLevel->getElements->[$i]->start_token;
	    $start_sentence_offset = $document->getAnnotations->getSentenceLevel->getElements->[$i]->start_token->getFrom;
	    while ($line =~ /<TIMEX3 tid=\"(?<tid>[^"]+)\" type=\"(?<type>[^"]+)\" value=\"(?<value>[^"]+)\"( mod=\"(?<mod>[^"]+)\")?( quant=\"(?<quant>[^"]+)\")?( freq=\"(?<freq>[^"]+)\")?>(?<timex>.*?)<\/TIMEX3>/) {
	    # while ($line =~ /<TIMEX3 tid=\"(?<tid>[^"]+)\" type=\"(?<type>[^"]+)\" value=\"(?<value>[^"]+)\"( mod=\"(?<mod>[^"]+)\")?( quant=\"(?<quant>[^"]+)\")?>(?<timex>.*?)<( freq=\"(?<freq>[^"]+)\")?\/TIMEX3>/) {
		# warn "$line\n";
		$lineold = $line;
		$line = $'; #'
		    $offset = length($`);
		# $+{tid}
		$type = lc($+{type});
		$mod=$+{mod};
		$value=uc($+{value});
		# warn "type: $type\n";
		if ($type eq "set") {
		    $type = "frequency";
		}
		# if ($value eq "present_ref") {
		#     $value = "";
		# }
		$start_sentence_offset += $offset;
		# $start_sentence_offset--;
		$tokenStart = $document->getAnnotations->getTokenLevel->getElementFromIndex('from', $start_sentence_offset)->[0];
		$tokenEnd = $document->getAnnotations->getTokenLevel->getElementFromIndex('to', $start_sentence_offset + length($+{timex}) - 1)->[0];
		if ((defined $tokenStart) && (defined $tokenEnd)) {
		    my $oldTerm = $document->getAnnotations->getSemanticUnitLevel->getElementByStartEndTokens($tokenStart, $tokenEnd);
		    if (defined $oldTerm) {
			if ($oldTerm->isNamedEntity) {
			    $document->getAnnotations->delSemanticUnit($oldTerm);
			    $term = $self->_createTermFromStartEndTokens($document, $tokenStart,$tokenEnd);
			} else {
			    $term = $oldTerm;
			}
		    } else {
			$term = $self->_createTermFromStartEndTokens($document, $tokenStart,$tokenEnd);
		    }
		    if (defined $term) {
			# warn "\tAdd " . $term->getForm . " ($type - $mod - $value)\n";
			# warn "\tAdd " . $term->getForm . " ($type - $value)\n";
			%weights = ('relevance' => 2);
			if ((defined $mod) && ($mod ne "")) {
			    # warn "add modality $mod - " . $term->type . "\n";
			    $weights{'modality'} = $mod;
			    # warn join(":", %weights) . "\n";
			}
			$self->_processValue(\$value, $term, \@undefinedRef);

			$term->canonical_form($value);
			
			$term->weights(\%weights);
			$document->getAnnotations->addSemanticUnit($term);
			if ((defined $self->{"root_semf"}->{$lang}) && ($self->{"root_semf"}->{$lang} ne "")) {
			    @semfTab = ('TIMEX3', $type);
			} else {
			    @semfTab = ($type);
			}
			$semFeatures = Lingua::Ogmios::Annotations::SemanticFeatures->new(
			    { 'semantic_category' => [[@semfTab]],
			      'refid_semantic_unit' => $term->getId,
			    });
			$document->getAnnotations->addSemanticFeatures($semFeatures);
		    } else {
			warn "*** " . $+{timex} . "not found\n";
		    }
		} else {
		    if (!defined $tokenStart) {
			warn "*** tokenStart not defined (" . $document->getAnnotations->getSentenceLevel->getElements->[$i]->start_token->getFrom . " - $start_sentence_offset - " . length($+{timex}) . ")\n";
		    }
		    if (!defined $tokenEnd) {
			warn "*** tokenEnd not defined (" . $document->getAnnotations->getSentenceLevel->getElements->[$i]->start_token->getFrom . " - $start_sentence_offset - " . length($+{timex}) . ")\n";
		    }
		    warn "\tline: $lineold\n";
		    warn "\t" . $document->getAnnotations->getSentenceLevel->getElements->[$i]->getForm . " ($i)\n";
		}
		$start_sentence_offset += length($+{timex});
		# $start_sentence_offset--;
	    }
	}
	$i++;
    }

    close FILE;

    if ((!(defined($self->{"MERGE_TERMS"}->{$lang}))) || ($self->{"MERGE_TERMS"}->{$lang} == 1)) {
	# warn "Merge term\n";
	$self->_mergeTerms($document);
	# TO REMOVe WHEN index deleting is OK
	$document->getAnnotations->getSemanticUnitLevel->rebuildIndex;
	$document->getAnnotations->getPhraseLevel->rebuildIndex;
	$document->getAnnotations->getSemanticUnitLevel->rebuildIndex;
    }

    # eval {
    # 	$document=$Parser->parse_file($self->_output_filename);
    # };
    # if ($@){
    # 	warn "Parsing the doc failed: $@. Trying to get the IDs..\n";
    # } else {
    #  	if ($document) {
    # # 	    $self->_parseDocumentCollection($document, $lingAnalysisLoad);

    # 	    my $root=$document->documentElement();
    # 	    for $documentHT ($root->getChildrenByTagName('TimeML')) {
		
    # 	    }

    #  	} else {
    #  	    warn "Parsing the doc failed. Doc " . $self->_output_filename . ")\n";
    #  	}
    # }

    warn "[LOG] done\n";
}

sub run {
    my ($self, $documentSet) = @_;

    # Set variables according the the configuration

    $self->_documentSet($documentSet);

    warn "[LOG] " . $self->_config->comments . " ...     \n";

    $self->_inputHeidelTime;

    my $command_line = $self->_processHeidelTime;

#     if ($self->_position eq "last") {
# 	# TODO
    if (($self->_position eq "last") && ($self->_no_standard_output)) {
	warn "print no standard output\n";
    } else {
	$self->_outputHeidelTime;
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

sub _processValue {
    my ($self, $valueRef, $term, $undefinedRef, $document) = @_;

    my $value = $$valueRef;
    my $valnum = 0;
    my $repl;

    # warn "value: $value\n";
    my %correspUnit = (
	'D' => { 'value' => 24,
		 'norm' => "H",
		 'norm2' => 'T',
               },
        'H' => { 'value' => 60,
		 'norm' => "M",
		 'norm2' => 'T',
               },
        'W' => { 'value' => 7,
		 'norm' => "D",
		 'norm2' => '',
               },
        'M' => { 'value' => 30,
		 'norm' => "D",
		 'norm2' => '',
               },
	'Q' => { 'value' => 4,
		 'norm' => "M",
		 'norm2' => '',
               },
	'Y' => { 'value' => 12,
		 'norm' => "M",
		 'norm2' => '',
               },
	);

    if ($value =~ /^RP(?<unit>[^\/]+)\/(?<denum>\d+)/o) {
    	if (exists $correspUnit{$+{unit}}) {
#    	    $valnum = sprintf("%0.2f", $correspUnit{$+{unit}}->{'value'} / $correspUnit{$+{denum}});
    	    $valnum = sprintf("%0.2f", $correspUnit{$+{unit}}->{'value'} / $+{denum});
#	    warn "valnum: $valnum\n";
    	    $value = "RP" . $correspUnit{$+{unit}}->{'norm2'} . $valnum . $correspUnit{$+{unit}}->{'norm'};
    	}
    } elsif ($value eq '@NOW@') {
    	# if ($term->start_token->getFrom < ($document->getAnnotations->getTokenLevel->getLastElement->getFrom/2)) {
    	    $self->_searchDataFromTheBeginning($term, $document);
    	# } else {
#    	    $self->_searchDataFromTheEnd($term, $document);
    	# }
    	push @$undefinedRef, $term;
    } elsif ($value =~ /SUB(?<unit>[A-Z])/) {
	# warn "$value" . " : " . $+{unit} . "\n";
	$repl = $correspUnit{$+{unit}}->{'norm'};
	$value =~ s/SUB[A-Z]/$repl/;
	# warn "$value\n";
	$value =~ s/([A-Z])0([0-9])/$1$2/;
	# warn "$value\n";
    } elsif ($value =~ /(?<unit0>[0-9]+)(?<unit>[A-Z])(?<unit1>[0-9]+)DIV(?<unit2>[0-9]+)/) {
	$valnum = sprintf("%4.1f", $+{unit0}+($+{unit1} / $+{unit2}));
	# warn "valnum: $valnum\n";
	$value =~ s/(?<unit0>[0-9]+)(?<unit>[A-Z])(?<unit1>[0-9]+)DIV(?<unit2>[0-9]+)/$valnum$+{unit}/;
    # TO UNCOMMENT AT THE END
    # } elsif ($value =~ /UNDEF/) {
    # 	$value="";
    }
    $$valueRef=$value;
    # warn "value: $$valueRef\n";
}

sub _searchDataFromTheBeginning {
    my ($self, $term, $document) = @_;

    my $currentTerm;
    my $token;
    my @terms;
    my $type;
    # 
    $token = $document->getAnnotations->getTokenLevel->getFirstElement;
    while(defined ($token->next)) {
	if ($document->getAnnotations->getSemanticUnitLevel->existsElementByToken($token)) {
	    @terms = $document->getAnnotations->getSemanticUnitLevel->getElementByToken($token);
	    if ((scalar(@terms) > 0) &&
		(defined $terms[0]->getSemanticFeatureFC($document))) {
		$type = lc($terms[0]->getSemanticFeatureFC($document));
		if (($type eq "date") && ($terms[0]->canonical_form =~ /\d{4}-\d{2}-\d{2}/)) {
		    return($terms[0]->canonical_form);
		}
	    }
	}
	$token = $token->next;
    }
    # if (!defined  $term->getSemanticFeatureFC($document)) {
    return("");
}

# sub _checkTermDate {
#     my ($self, $term, $document, $token) = @_;

#     my $token;
#     my @terms;

#     if ($document->getAnnotations->getSemanticUnitLevel->existsElementByToken($token)) {
# 	@terms = $document->getAnnotations->getSemanticUnitLevel->getElementByToken($token);
# 	if ((scalar(@terms) > 0) &&
# 	    (defined $terms[0]->getSemanticFeatureFC($document))) {
# 	    $type = lc($terms[0]->getSemanticFeatureFC($document));
# 	    if (($type eq "date") && ($terms[0]->canonical_form =~ /\d{4}-\d{2}-\d{2}/)) {
# 		return($terms[0]->canonical_form);
# 	    }
# 	}
#     }
# }

sub _searchDataFromTheEnd {
    my ($self, $term, $document) = @_;

    my $currentTerm;
    my $token;
    my @terms;
    my $type;

    $token = $document->getAnnotations->getTokenLevel->getLastElement;
    while(defined ($token->previous)) {
	if ($document->getAnnotations->getSemanticUnitLevel->existsElementByToken($token)) {
	    @terms = $document->getAnnotations->getSemanticUnitLevel->getElementByToken($token);
	    if ((scalar(@terms) > 0) &&
		(defined $terms[0]->getSemanticFeatureFC($document))) {
		$type = lc($terms[0]->getSemanticFeatureFC($document));
		if (($type eq "date") && ($terms[0]->canonical_form =~ /\d{4}-\d{2}-\d{2}/)) {
		    return($terms[0]->canonical_form);
		}
	    }
	}
	$token = $token->next;
    }
    # $document->getAnnotations->getTokenLevel->getLastElement
    return("");
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

