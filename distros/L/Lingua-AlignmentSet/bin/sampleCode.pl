#! /usr/local/bin/perl

BEGIN {
    $ENV{ALDIR}="data";
}

use Lingua::AlignmentSet 1.1;

############################
# *** NEW FUNCTION SAMPLES #
############################

# alternative 1
	$location1 = {"source"=>$ENV{ALDIR}."/spanish.naacl",
				"target"=>$ENV{ALDIR}."/english.naacl",
				"sourceToTarget"=>$ENV{ALDIR}."/spanish-english.naacl"};
	$fileSet1 = [$location1,"NAACL","1-10"];
	$fileSets = [$fileSet1]; 
	$alSet =  Lingua::AlignmentSet->new($fileSets);

# alternative 2
	$alSet = Lingua::AlignmentSet->new([[$location1,"NAACL","1-10"]]);

# alternative 3
	$alSet = Lingua::AlignmentSet->new([[$ENV{ALDIR}."/spanish-english.naacl","NAACL","1-10"]]);
	$alSet->setWordFiles($ENV{ALDIR}."/spanish.naacl",$ENV{ALDIR}."/english.naacl");
#################################
# *** VISUALISE FUNCTION SAMPLE #
#################################
open(MAT,">".$ENV{ALDIR}."/spanish-english-matrix.tex");
$alSet->visualise("matrix","latex",*MAT,"ambiguity");
close(MAT);
open(LINK,">".$ENV{ALDIR}."/spanish-english-enumLinks.tex");
$alSet->visualise("enumLinks","latex",*LINK);
close(LINK);

################################
# *** CHFORMAT FUNCTION SAMPLE #
################################

$newLocation = {"sourceToTarget"=>$ENV{ALDIR}."/spanish-english"};
$alSet->chFormat($ENV{ALDIR}."/spanish-english","BLINKER");

########################################
# *** PROCESSALIGNMENT FUNCTION SAMPLE #
########################################

my $alSet_swapped = $alSet->processAlignment("Lingua::Alignment::swapSourceTarget",$ENV{ALDIR}."/english-spanish.naacl");

#################################
# *** EVALUATE FUNCTION SAMPLE  #
#################################
$gsLoc = {"sourceToTarget"=>$ENV{ALDIR}."/answer/spanish-english"};
$goldStandard = Lingua::AlignmentSet->new([[$gsLoc,"BLINKER"]]);


push @evaluation,[$alSet->evaluate($goldStandard,"no-null-align"),"Spanish to english"];
Lingua::AlignmentEval::compare(\@evaluation,"Alignment evaluation",\*STDOUT,"text");
print "\n";
