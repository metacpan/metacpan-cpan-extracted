#! /usr/local/bin/perl

BEGIN {
    $ENV{ALDIR}="data";
}

use Lingua::AlignmentSet 1.1;
#################################################################################
# remove ¿?¡!. signs from the Blinker reference corpus and save it as Naacl file:
#################################################################################

# 1 remove from target side of the corpus:
	$answer = Lingua::AlignmentSet->new([[$ENV{ALDIR}."/answer/spanish-english","BLINKER"]]);
	# need to add the target words file because we remove from that side:
	$answer->setTargetFile($ENV{ALDIR}."/answer/english.blinker");

	#define output location:
	$newLocation = {"target"=>$ENV{ALDIR}."/english-without.naacl",
			"sourceToTarget"=>$ENV{ALDIR}."/spanish-english-interm.naacl"};

	my $output = $answer->processAlignment(["Lingua::Alignment::eliminateWord",'\.|\?|¿|!|¡',"target"],$newLocation);

# 2 Remove now from source side:
	# we take as input alignment the previous one (already removed in target side).
	# however, to remove from source, we need to add the source words:
	$output->setSourceFile($ENV{ALDIR}."/spanish.naacl");

	#define output location:
	$newLocation = {"source"=>$ENV{ALDIR}."/spanish-without.naacl",
			"sourceToTarget"=>$ENV{ALDIR}."/spanish-english-without.naacl"};

    $output = $output->processAlignment(["Lingua::Alignment::eliminateWord",'\.|\?|¿|!|¡',"source"],$newLocation);
