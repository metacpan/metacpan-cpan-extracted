########################################################################
# Author:  Patrik Lambert (lambert@talp.ucp.es)
# Description: Tools library to manage an Alignment Sets, i.e. a set of 
#              sentences aligned at the word (or phrase) level.
#-----------------------------------------------------------------------
#  Copyright 2004 by Patrik Lambert
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
########################################################################

package Lingua::AlignmentSet;
use 5.005;
use vars qw($VERSION);
use strict;
$VERSION = 1.1;
use Lingua::AlSetLib 1.1;
use Lingua::Alignment 1.1;
use Lingua::WriteLatexFile;
use Lingua::AlignmentEval;

use Dumpvalue;
use IO::File;

my $dumper=new Dumpvalue;
my $true = 1;
my $false = 0;

sub new {
	my ($pkg,$refToFileSets) = @_;
    my $refToLocation = readLocation($refToFileSets->[0][0]);
    my $format =  $refToFileSets->[0][1];
    my $range = $refToFileSets->[0][2];
    my $alSet = {};
   	#default values:
   	if (!defined($format)){$format="TALP"}
   	else {$format = uc $format};
	if (!defined($range)){$range="1-"};
	if ($format eq "BLINKER"){
   		#for future ease we save detailed infos contained in the source sample path
		completeBlinkerLocation($refToLocation);
	}
		
	$alSet->{location}=$refToLocation;
	$alSet->{format}=$format;
	    
	setRange($alSet,$range);
	
    #checking the data:
    if ($format eq "GIZA"){
#    	if ($ambiguity || $confidence){die "GIZA format not compatible with ambiguity or confidence features"}
    } elsif ($format eq "BLINKER"){
    } elsif ($format eq "NAACL"){
    } elsif ($format eq "TALP"){
    } else {
    	die "Unknown format $format. Can't create alignment set object";	
    }
    return bless $alSet,$pkg;    
}

# create a new AlignmentSet that contains the same data of an already existing alignment set (without copying the addresses)
sub copy {
	my $alSet = shift;

	my $cloneLocation={};
	my ($field,$value);
	while (($field,$value)=each (%{$alSet->{location}})){
		$cloneLocation->{$field}=$value;
	}
	return Lingua::AlignmentSet->new([[$cloneLocation,$alSet->{format},$alSet->{firstSentPair}."-".$alSet->{lastSentPair}]]);
}

sub setWordFiles{
	my ($alSet,$sourcePath,$targetPath) = @_;
	
	$alSet->{location}->{source}=$sourcePath;
	$alSet->{location}->{target}=$targetPath;	
}
sub setSourceFile{
	my ($alSet,$sourcePath) = @_;
	
	$alSet->{location}->{source}=$sourcePath;
}
sub setTargetFile{
	my ($alSet,$targetPath) = @_;
	
	$alSet->{location}->{target}=$targetPath;	
}

sub setTargetToSourceFile{
	my ($alSet,$targetToSourcePath) = @_;
	
	$alSet->{location}->{targetToSource}=$targetToSourcePath;
}

sub chFormat {
	my ($alSet,$newLocation,$newFormat,$alignMode)=@_;

	$alSet->convert($newLocation,$newFormat,$alignMode);
}


# Won't work if the sentence files are not specified
sub visualise {
    my ($alSet,$representation,$format,$outputFH,$mark,$alignMode,$maxRows,$maxCols)=@_;
    $representation = lc $representation;
    $format = lc $format;
    if (!defined($outputFH)){$outputFH=*STDOUT}
    if ($representation eq "matrix"){
	if (!defined($mark)){$mark = "cross"}
	if (!defined($maxRows)){$maxRows = 53}	#default maxRows value
	if (!defined($maxCols)){$maxCols = 35}	#default maxRows value
	$format="latex";
    }
    my $latex = Lingua::Latex->new;
    if ($format eq "latex"){
	print $outputFH $latex->startFile;
	print $outputFH $latex->setTabcolsep("0.5mm");
    }
    my $output = "";
    my $inputSentPairNum = $alSet->{firstSentPair};
    my $i;
    my ($al,$alSetChunk);
    my $FH = $alSet->openFiles();
    if (($alSet->{format} ne "GIZA") && (!$FH->{source} || !$FH->{target})){
	die "To use the 'visualise' function, you must specify the sentence (words) files.\n";
    }
    while ($alSetChunk = $alSet->loadChunk($FH,$inputSentPairNum,$alignMode)){	# returns 0 if eof or last sentence pair
	$output = "";
	for ($i=0;$i<@$alSetChunk;$i++){
	    $al = $$alSetChunk[$i];
#			print main::Dumper($al);
	    if ($representation eq "matrix"){
		$output.= "\n$inputSentPairNum\n".$al->displayAsMatrix($latex,$mark,$maxRows,$maxCols);
	    }elsif ($representation eq "enumlinks"){
		$output.= "\n$inputSentPairNum\n".$al->displayAsLinkEnumeration($format,$latex);
	    } #elsif
	}#for
	    print $outputFH $output;
	$inputSentPairNum++;
    }
    if ($format eq "latex"){print $outputFH $latex->endFile};
}

#only work if the text files are given (not only the alignment files).
sub getSize {
	my $alSet = shift;
	my ($file,$factor);
	my $size;
	
	if ($alSet->{format} eq "GIZA"){
		$file = $alSet->{location}->{sourceToTarget};
		$factor = 3;
	}elsif ($alSet->{format} eq "NAACL" || $alSet->{format} eq "BLINKER" || $alSet->{format} eq "TALP"){
		if (!$alSet->{location}->{source}){
			die "One of the functions your are using requires you specify the sentence files (source and target)\n";	
		}
		$file = $alSet->{location}->{source};
		$factor = 1;
	}
	open (FILE,"<$file");
	$size += tr/\n/\n/ while sysread(FILE, $_, 2 ** 16);
	close(FILE);
	$size = $size / $factor;
	return $size;
}

# returns a list (in random order) of lineNumbers
# to sort this list, do:	my @sortedSelection = sort { $a <=> $b; } @selection;

sub chooseSubsets {
	#TO DO: possibility of percentage input for the size
	my	($alSet,$seed,$size) = @_;
	my $alSetSize = $alSet->getSize();
	my $count;
	my @selected=();
	my @notSelected = ();
	my ($ind,$elt);

	for ($count=1;$count<$alSetSize;$count++){
		push @notSelected,$count;	
	}
	srand $seed;
	for ($count=0;$count<$size;$count++){
		$ind = rand @notSelected;
		$elt = $notSelected[$ind];
		splice @notSelected, $ind, 1;
		push @selected,$elt;
	}	
	return \@selected;
}
###################################################################
###   EVALUATION                                                ###
###################################################################

#code adapted from Rada Mihalcea's wa_eval_align.pl, rada@cs.unt.edu
# Evaluation is performed using: 
#  - Standard Precision, Recall, F-measure, separate for S (Sure) and P (Possible) cases
#  - AER measure, defined as 
#    AER = 1 - ( |A & S| + |A & P| ) / ( |A| + |S| )
#    [where A represents the alignment, S and P represent the S (Sure) and P (Possible) gold standard alignments]

sub evaluate {
    my ($submissionAlSet,$answerAlSet,$alignMode,$weighted)=@_;
    if (!defined($weighted)){$weighted=0}
    my ($line,$alignment);
    my ($FH,$alSetChunk,$i,$al,$fhPos);
    my ($inputSentPairNum,$internalSentPairNum,$sentPairNum);
    my ($sureMatch,$possibleMatch,$possibleMatchSure);
    my ($surePrecision,$sureRecall,$possiblePrecision,$possibleRecall,$sureFMeasure,$possibleFMeasure,$AER);
# 1	READ ANSWER AND SUBMISSION FILES
# (in the case of NAACL format file it's more efficient to treat it directly, otherwise load to internal structure)
    # answer file
    my %sureAnswer;
    my %possibleAnswer;
    my $INFINITY = 9999999999;
    $inputSentPairNum = $answerAlSet->{firstSentPair};
    $internalSentPairNum = 1;
    if ( $answerAlSet->{format} eq "NAACL" && $alignMode eq "as-is" && $answerAlSet->{firstSentPair} == 1){
	my $answerFH = IO::File->new("<".$answerAlSet->{location}{sourceToTarget}) or die "Answer alignment file opening error:$!";				
	#go to first sentence pair:
	$fhPos = $answerFH->getpos; 
	while ($answerFH->getline() !~ m/^0*$inputSentPairNum .*/o && !$answerFH->eof()) {
	    $fhPos = $answerFH->getpos; 
	}
	if ($answerFH->eof()){
	    die "First sentence pair of range not found in ".$answerAlSet->{location}{sourceToTarget}; 	
	}
	$answerFH->setpos($fhPos); #if we changed sentences, we read the first line of next sentence=>go back one line
	
	#read file:
	if ($answerAlSet->{lastSentPair} eq "eof"){
	    $inputSentPairNum = $INFINITY;
	}else{
	    $inputSentPairNum = $answerAlSet->{lastSentPair}+1;
	}
	while(!$answerFH->eof() && ( ($line=$answerFH->getline()) !~ m/^0*$inputSentPairNum .*/o )) {
	    chomp $line;
	    $line =~ s/^\s+|\s+$//g;
	    identifySurePossible($line,\%sureAnswer,\%possibleAnswer);
	}	
	$answerFH->close();
    }else{
	$FH = $answerAlSet->openFiles();
	while ($alSetChunk = $answerAlSet->loadChunk($FH,$inputSentPairNum,$alignMode)){	# returns 0 if eof or last sentence pair
	    for ($i=0;$i<@$alSetChunk;$i++){
		$al = $$alSetChunk[$i];
#				print "EVALUATE: answer al:\n";
#				print main::Dumper($al);
		foreach $line (@{$al->writeToBlinker()}){
		    $line = "$internalSentPairNum ".$line;
		    identifySurePossible($line,\%sureAnswer,\%possibleAnswer);	
		}
	    }
	    $inputSentPairNum++;
	    $internalSentPairNum++;
	}
	closeFiles($FH,$answerAlSet->{format});
    }# if format - else
	
    # submission file
    my %sureSubmission;
    my %possibleSubmission;	
    $inputSentPairNum = $submissionAlSet->{firstSentPair};
    $internalSentPairNum = 1;

    if ($submissionAlSet->{format} eq "NAACL" && $alignMode eq "as-is" && $submissionAlSet->{firstSentPair}==1){
	my $submissionFH = IO::File->new("<".$submissionAlSet->{location}{sourceToTarget}) or die "Submission alignment file opening error:$!";				

	#go to first sentence pair:
	$fhPos = $submissionFH->getpos; 
	while ($submissionFH->getline() !~ m/^0*$inputSentPairNum .*/o && !$submissionFH->eof()) {
	    $fhPos = $submissionFH->getpos; 
	}
	if ($submissionFH->eof()){
	    die "First sentence pair of range not found in ".$submissionAlSet->{location}{sourceToTarget}; 	
	}
	$submissionFH->setpos($fhPos); #if we changed sentences, we read the first line of next sentence=>go back one line
	
	#read file:
	if ($submissionAlSet->{lastSentPair} eq "eof"){
	    $inputSentPairNum = $INFINITY;
	}else{
	    $inputSentPairNum = $submissionAlSet->{lastSentPair}+1;
	}
	while(!$submissionFH->eof() && (($line = $submissionFH->getline()) !~ m/^0*$inputSentPairNum .*/o )) {
	    chomp $line;
	    $line =~ s/^\s+|\s+$//g;
	    identifySurePossible($line,\%sureSubmission,\%possibleSubmission);
	}	
	$submissionFH->close();
    }else{
	$FH = $submissionAlSet->openFiles();
	while ($alSetChunk = $submissionAlSet->loadChunk($FH,$inputSentPairNum,$alignMode)){	# returns 0 if eof or last sentence pair
	    for ($i=0;$i<@$alSetChunk;$i++){
		$al = $$alSetChunk[$i];
		# print "submission al:\n";
		# $dumper->dumpValue($al);
		foreach $line (@{$al->writeToBlinker()}){
		    $line = "$internalSentPairNum ".$line;					
		    identifySurePossible($line,\%sureSubmission,\%possibleSubmission);	
		}
	    }
	    $inputSentPairNum++;
	    $internalSentPairNum++;
	}
	closeFiles($FH,$submissionAlSet->{format});
    }# if format=NAACL else
	
	
#	print "weighted:$weighted\n";
#	print "SA:".join("-",keys %sureAnswer),"\nSS:".join(" - ",keys %sureSubmission),"\nPA:".join(" - ",keys %possibleAnswer),"\nPS:".join(" - ",keys %possibleSubmission)."\n";

# 2 WEIGHT LINKS
# It is a kind of "normalization" of multiple links: each link (j i) is weighted according to 
# the number of links in which j and i are involved: weight(j,i)=0.5*(1/numLinks(j)+1/numLinks(i)). 

	my ($link,$j,$hash,$value);
	my %weightsSure;
	my %linksSure;
	my @linksSureInSentence;
	my %linksPossible;
	my @linksPossibleInSentence;
	my %weightsPossible;

	if ($weighted){
	# When only sure links are considered (calculation of Ps and Rs), they are weighted with respect to the union of both sure sets
		# take union
		foreach $hash ( \%sureSubmission, \%sureAnswer ) {
		    while (($link, $value) = each %$hash) {
		    	($sentPairNum,$j,$i)=split(" ",$link);
		        $linksSure{$sentPairNum}{"$j $i"} = $value;
		    }
		}
		# calculate weight of each link
		foreach  $sentPairNum (keys %linksSure){
			@linksSureInSentence =keys %{$linksSure{$sentPairNum}}; 
			foreach $link (@linksSureInSentence){
				($j,$i)=split(" ",$link);
				$weightsSure{"$sentPairNum $link"}=0.5*( 1/grep(/^$j /,@linksSureInSentence)+1/grep(/ $i$/,@linksSureInSentence) );
			}
		}

	# When all links are considered (calculation of Pp and Rp, AER), possible AND sure links are weighted with respect to the union of all sets.
		%linksPossible=%linksSure;
		# add union of possible links
		foreach $hash (\%possibleSubmission, \%possibleAnswer ) {
		    while (($link, $value) = each %$hash) {
		    	($sentPairNum,$j,$i)=split(" ",$link);
		        $linksPossible{$sentPairNum}{"$j $i"} = $value;
		    }
		}
		# calculate weight of each link
		foreach  $sentPairNum (keys %linksPossible){
			@linksPossibleInSentence =keys %{$linksPossible{$sentPairNum}}; 
			foreach $link (@linksPossibleInSentence){
				($j,$i)=split(" ",$link);
				$weightsPossible{"$sentPairNum $link"}=0.5*( 1/grep(/^$j /,@linksPossibleInSentence)+1/grep(/ $i$/,@linksPossibleInSentence) );
			}
		}
	}
	
# 3 SUM UP LINKS
	# in case of weights distinct from 1: sum of %possibleAnswer and %possibleSubmission is always with %weightsPossible.
	# however the sum of %sureAnswer and %sureSubmission is with %weightsSure to calculate Ps and Rs, %weightsPossible for Pp, Rp and AER.
	my ($totalPossibleAnswer,$totalPossibleSubmission)=(0,0);
	my ($totalSureAnswer_weightsSure,$totalSureSubmission_weightsSure,$totalSureAnswer_weightsPossible,$totalSureSubmission_weightsPossible)=(0,0,0,0);
	if ($weighted){
		foreach $link (keys %sureAnswer){
			$totalSureAnswer_weightsSure+=$weightsSure{$link};	
			$totalSureAnswer_weightsPossible+=$weightsPossible{$link};	
		}		
		foreach $link (keys %sureSubmission){
			$totalSureSubmission_weightsSure+=$weightsSure{$link};	
			$totalSureSubmission_weightsPossible+=$weightsPossible{$link};	
		}		
		foreach $link (keys %possibleAnswer){
			$totalPossibleAnswer+=$weightsPossible{$link};	
		}		
		foreach $link (keys %possibleSubmission){
			$totalPossibleSubmission+=$weightsPossible{$link};	
		}		
	}else{ #every link has a weight 1
		$totalSureAnswer_weightsSure=scalar(keys %sureAnswer);
		$totalSureAnswer_weightsPossible= $totalSureAnswer_weightsSure;
		$totalSureSubmission_weightsSure=scalar(keys %sureSubmission);
		$totalSureSubmission_weightsPossible=$totalSureSubmission_weightsSure;
		$totalPossibleAnswer=scalar(keys %possibleAnswer);
		$totalPossibleSubmission=scalar(keys %possibleSubmission);
	}
	
# 4 COUNT MATCHES

#	print "sureSubmission:",join("|",keys %sureSubmission),"\n";
#	print "possibleSubmission:",join("|",keys %possibleSubmission),"\n";
#	print "sureAnswer:",join("|",keys %sureAnswer),"\n";
#	print "possibleAnswer:",join("|",keys %possibleAnswer),"\n";
#   print "\n";
	# now determine the S[ure] matches 
	$sureMatch = 0;
	foreach $alignment (keys %sureSubmission) {
	    if(defined($sureAnswer{$alignment})) {
			if (!$weighted){$sureMatch++}
			else {$sureMatch += $weightsSure{$alignment}}
	    }
	}
	# and the [P]robable matches 
	# these are checked against both S[ure] and P[robable] correct alignments
	$possibleMatch = 0;
	foreach $alignment (keys %possibleSubmission, keys %sureSubmission) {
	    if(defined($sureAnswer{$alignment}) || defined($possibleAnswer{$alignment})) {
			if (!$weighted){$possibleMatch++}
	    	else{$possibleMatch += $weightsPossible{$alignment}}
	    }
	}
	# and also the intersection between all submitted alignments 
	# and the S [Sure] correct alignments -- as needed by AER
	$possibleMatchSure = 0;
	foreach $alignment (keys %possibleSubmission, keys %sureSubmission) {
	    if(defined($sureAnswer{$alignment})) {
	    	if (!$weighted){$possibleMatchSure++}
	    	else{$possibleMatchSure+= $weightsPossible{$alignment}}
	    }
	}
#	print "sureMatch:$sureMatch possibleMatch:$possibleMatch possibleMatchSure:$possibleMatchSure\n";

# 5 COMPUTE EVALUATION MEASURES
	# now determine the precision, recall, and F-measure for [S]ure alignments
	if(scalar(keys %sureSubmission) != 0) {
	    $surePrecision = $sureMatch / $totalSureSubmission_weightsSure;
	}else {
	    $surePrecision = 0;
	}
	if(scalar(keys %sureAnswer) != 0) {
	    $sureRecall = $sureMatch / $totalSureAnswer_weightsSure;
	}else {
	    $sureRecall = 0;
	}
	if($sureRecall != 0 && $surePrecision != 0) {
	    $sureFMeasure = 2 * $sureRecall * $surePrecision / ($sureRecall + $surePrecision);
	}else {
	    $sureFMeasure = 0;
	}


	# and now determine the precision, recall, and F-measure for [P]robable alignments
	if(scalar(keys %sureSubmission) + scalar(keys %possibleSubmission) != 0) {
	    $possiblePrecision = $possibleMatch / ($totalSureSubmission_weightsPossible+$totalPossibleSubmission);
	}else {
	    $possiblePrecision = 0;
	}
	if(scalar(keys %sureAnswer) + scalar(keys %possibleAnswer)!= 0) {
	    $possibleRecall = $possibleMatch / ($totalSureAnswer_weightsPossible+$totalPossibleAnswer);
	}else {
	    $possibleRecall = 0;
	}
	if($possibleRecall != 0 && $possiblePrecision != 0) {
	    $possibleFMeasure = 2 * $possibleRecall * $possiblePrecision / ($possibleRecall + $possiblePrecision);
	}else {
	    $possibleFMeasure = 0;
	}

	# and determine the AER
	if(scalar(keys %sureSubmission) + scalar(keys %possibleSubmission) != 0) {
	    $AER = 1 - ($possibleMatchSure + $possibleMatch) / ($totalSureSubmission_weightsPossible+$totalPossibleSubmission+$totalSureAnswer_weightsPossible);
	}else {
	    $AER = 0;
	}
	return Lingua::AlignmentEval->new($surePrecision,$sureRecall,$sureFMeasure,$possiblePrecision,$possibleRecall,$possibleFMeasure,$AER);
}
###################################################################
###   PROCESSING                                                ###
###################################################################

sub processAlignment{
    my ($alSet,$AlignmentSub,$newLocation,$newFormat,$alignMode)=@_;
    my $newAlSet = $alSet->copy;
    if (ref($AlignmentSub) eq 'ARRAY'){
	if ($AlignmentSub->[0] eq "Lingua::Alignment::eliminateWord"){
	    if (@$AlignmentSub<3){die "Missing parameters for Lingua::Alignment::eliminateWord\n"}
	    else{
		my $side = lc $AlignmentSub->[2];
		if (!$alSet->{location}{$side} || !$newLocation->{$side}){die "Missing $side file for Lingua::Alignment::eliminateWord\n"}
	    }
	}	
    }
    $newAlSet->convert($newLocation,$newFormat,$alignMode,$AlignmentSub);
    return $newAlSet;
}

sub symmetrize {
    my ($alSet,$newLocation,$newFormat,$ENV,$selectSubgroups,$alignMode,$globals)=@_;
    #defaults
    if (!defined($selectSubgroups)){$selectSubgroups=0}	
    if (!defined($alignMode)){$alignMode="no-null-align"}
    if (!defined($globals->{"minPhraseFrequency"})){$globals->{"minPhraseFrequency"}=2};
    if (!defined($globals->{"extendGroups"})){$globals->{"extendGroups"}=0};
    if (!defined($globals->{"onlyGroups"})){$globals->{"onlyGroups"}=1};
    if (!defined($globals->{"defaultActionGrouping"})){$globals->{"defaultActionGrouping"}="Lingua::Alignment::getUnion"};
    if (!defined($globals->{"defaultActionGeneral"})){$globals->{"defaultActionGeneral"}="Lingua::Alignment::intersect"};
    if (!defined($globals->{"verbose"})){$globals->{"verbose"}="0"};
    my $verbose = $globals->{"verbose"};
    my $al; # reference alignment- remains unchanged
    my $modAl; #reference alignment modified with the successive aplication of symRules
    #load in memory a chunk of the alignment set as a list
    #of references to (internal representation) alignment objects:
    my ($k,$alSetChunk);
    my $FH = $alSet->openFiles();
    my $newFH;
    if ($selectSubgroups==0){
	$newFH = openLocation($newLocation,$newFormat,">",$alSet->{location});
    }
    my $internalSentPairNum = 1;	
    my ($sentenceNum,$ruleApplied) = ($alSet->{firstSentPair},0);

    my $grSentPairNum=1;

    my ($j,$i);
    my ($lines,$line);
    my $groups = {};
    my $groupsCurrentSentence = {};
    my $groupKeys = [];
    my $subGroups={};
    my $subGroupsCurrentSentence = {};
    my $subGroupKeys=[];
    my ($candidate,$count);

    if (!$selectSubgroups){	#load subgroup hash and array:
	open(GROUPS,"<$ENV/groups");
	while (<GROUPS>){
	    push @$groupKeys,$_;
	    @$line = split " | ",$_,2;
	    $groups->{$line->[1]}=$line->[0];	
	}
	if ($globals->{onlyGroups}==0){
	    open(SUBGROUPS,"<$ENV/subGroups");
	    while (<SUBGROUPS>){
		push @$subGroupKeys,$_;
		@$line = split " | ",$_,2;
		$subGroups->{$line->[1]}=$line->[0];	
	    }
	}
    }
	
    my %anchors;
    my %sourcePerturbed={};
    my %targetPerturbed={};	# Perturbations must be distinct so we keep track of the already detected "Perturbed" $j's
    my ($perturbation,$perturbationNoMod);
    my ($lastAnchorSource,$lastAnchorTarget,$newAnchorSource,$newAnchorTarget);
    my ($ind,$newPerturbationDetected,$anchorsInTarget);
    my ($countPertubs,$countGrouping,$countOneToMany,$countElse,$countNoGroup)=(0,0,0,0,0);
    while ($alSetChunk = $alSet->loadChunk($FH,$sentenceNum,$alignMode)){	# returns 0 if eof or last sentence pair
	for ($k=0;$k<@$alSetChunk;$k++){
#			print "\nsentence pair $sentenceNum\n";
	    $ruleApplied=0; 
	    $al = $$alSetChunk[$k];
	    if ($verbose >0){
		print $sentenceNum."\n";
		print $al->sourceSentence."\n";
		print $al->targetSentence."\n";
	    }
	    $modAl = $al->clone();
	    ($lastAnchorSource,$lastAnchorTarget)=(0,0);
	    %sourcePerturbed=();
	    %targetPerturbed=();
	    $j = 1;
	    #detect "perturbations" in the anchor diagonal looping only over $j (to have less repeated zones). We can only miss those where $i is aligned only to NULL
	    while ($j<@{$al->{sourceAl}}){
		while ( !$al->isAnchor($j,"source") && $j<(@{$al->{sourceAl}})){
		    $j++;
		}
		if ($j<=@{$al->{sourceAl}}){ 
		    if ($j==@{$al->{sourceAl}}){
			($newAnchorSource,$newAnchorTarget) = ($j,scalar(@{$al->{targetAl}}));
		    }else{
			($newAnchorSource,$newAnchorTarget) = ($j,$al->{sourceAl}[$j][0]);
		    }
		    $newPerturbationDetected=0;
		    if (($newAnchorSource-$lastAnchorSource)!=1 && !$sourcePerturbed{$lastAnchorSource+1}){
			$newPerturbationDetected = 1;	
		    } elsif (($newAnchorTarget-$lastAnchorTarget)!=1 && !$targetPerturbed{$lastAnchorTarget+1}){
			$anchorsInTarget=1;
			for ($i=$lastAnchorTarget+1;$i<$newAnchorTarget;$i++){
			    if (!$al->isAnchor($i,"target")){$anchorsInTarget=0}
			}
			if (!$anchorsInTarget){$newPerturbationDetected=1};
		    }
		    if ( $newPerturbationDetected ){
			$countPertubs++;
#						print "\n($lastAnchorSource,$lastAnchorTarget,$newAnchorSource,$newAnchorTarget)\n";
			
			$perturbation = $al->cut($lastAnchorSource,$lastAnchorTarget,$newAnchorSource,$newAnchorTarget);
			$perturbationNoMod = $al->cut($lastAnchorSource,$lastAnchorTarget,$newAnchorSource,$newAnchorTarget);

			# PRINT PERTURBATION TO FILE
			#if (exists($newFH->{source})){
			#    $newFH->{source}->print("<s snum=$grSentPairNum> ".join(" ",@{$perturbation->{sourceWords}})." </s>\n");
			#}
			#if (exists($newFH->{target})){
			#    $newFH->{target}->print("<s snum=$grSentPairNum> ".join(" ",@{$perturbation->{targetWords}})." </s>\n");
			#}
			#$perturbation->getUnion;
			#$lines = $perturbation->writeToBlinker;
			#foreach $line (@$lines){
			#    $newFH->{sourceToTarget}->print("$grSentPairNum $line\n");
			#}
			#$grSentPairNum++;

			#END PRINT PERTURBATION TO FILE
			if ($selectSubgroups){
			    $perturbation->selectSubgroups($groupsCurrentSentence,$subGroupsCurrentSentence,$globals);
			}else{
			    if (1==0){
#			    if ($ruleApplied=$perturbation->applyOneToMany_2()){	
				$countOneToMany++;
			    }elsif (($ruleApplied=$perturbation->applyGrouping($groupKeys,$subGroupKeys,$globals))>0){
				$countGrouping++;
			    }else{
				my $defaultActionGen = $globals->{defaultActionGeneral};
				$perturbation->$defaultActionGen();
				if ($ruleApplied==-1){
				    $countNoGroup++;
				}else{
				    $perturbation->processNull();
				    $countElse++;	
				}
			    }
			    $perturbation->paste($modAl);
			}
#						print "\ns indices:",join (" ",keys %{$perturbation->{sourceIndices}}),"\n";
#						print "t indices:",join (" ",keys %{$perturbation->{targetIndices}}),"\n";
			foreach $ind (keys %{$perturbation->{sourceIndices}}){
			    if ($ind>0){
				$sourcePerturbed{$ind+$perturbation->{zeroSource}}=1;
			    }
			}					
			foreach $ind (keys %{$perturbation->{targetIndices}}){
			    if ($ind>0){
				$targetPerturbed{$ind+$perturbation->{zeroTarget}}=1;
			    }
			}
#						print "s perturbed:",join (" ",keys %sourcePerturbed),"\n";
#						print "t perturbed:",join (" ",keys %targetPerturbed),"\n";
		    }	#if perturbation 
															
		    $anchors{"$newAnchorSource $newAnchorTarget"}=1;
		    ($lastAnchorSource,$lastAnchorTarget) = ($newAnchorSource,$newAnchorTarget);	
		    $j++;
		}
	    } #while j...
	    if ($newFormat eq "NAACL" && !$selectSubgroups){
		if (exists($newFH->{source})){
		    $newFH->{source}->print("<s snum=$internalSentPairNum> ".join(" ",@{$modAl->{sourceWords}})." </s>\n");
		}
		if (exists($newFH->{target})){
		    $newFH->{target}->print("<s snum=$internalSentPairNum> ".join(" ",@{$modAl->{targetWords}})." </s>\n");
		}
		$al->intersect();
		$lines = $modAl->writeToBlinker;
		foreach $line (@$lines){
		    $newFH->{sourceToTarget}->print("$internalSentPairNum $line\n");
		}
	    }
	    if (($internalSentPairNum % 1000)==0){print STDERR $internalSentPairNum}
	    elsif (($internalSentPairNum % 100)==0){print STDERR "."}
	    $sentenceNum++;
	    $internalSentPairNum++;
	    if ($verbose > 0){print "Candidates:\n";}
	    if ($selectSubgroups){
		foreach $candidate (keys %$groupsCurrentSentence){
		    if ($verbose > 0){print "$candidate\n";}
		    $groups->{$candidate}=$groups->{$candidate}+1;
		}
		%$groupsCurrentSentence=();
		if ($globals->{onlyGroups}==0){
		    foreach $candidate (keys %$subGroupsCurrentSentence){
			$subGroups->{$candidate}=$subGroups->{$candidate}+1;
		    }
		    %$subGroupsCurrentSentence=();
		}
	    }
	}#for k<@alSetChunk
	} #while alsetchunk
    print STDERR "\n";
    if ($selectSubgroups==0){
	closeFiles($newFH,$newFormat);
    }
    closeFiles($FH,$alSet->{format});
    if ($selectSubgroups){
	if ($verbose>0){print "\ngroups:",scalar(keys(%$groups))," - subgroups:",scalar(keys(%$subGroups)),"\n";}
	open(GROUPS, ">$ENV/groups") or die "File opening error:$!";;
	while (($candidate,$count)=each(%$groups)){
#				print "groups $count | $candidate\n";	
	    if ($count >= $globals->{minPhraseFrequency}){
		print GROUPS "$count | $candidate\n";	
	    }
	}
	if ($globals->{onlyGroups}==0){
	    open(SUBGROUPS, ">$ENV/subGroups") or die "File opening error:$!";;
	    while (($candidate,$count)=each(%$subGroups)){
#				print "SUBGROUPS $count | $candidate\n";	
		if ($count >= $globals->{minPhraseFrequency}){
		    print SUBGROUPS "$count | $candidate\n";	
		}
	    }
	}
    }else{
	print STDERR "perturbations:$countPertubs (oneToMany:$countOneToMany grouped:$countGrouping not grouped:$countNoGroup others:$countElse)\n";
	$alSet->{location}=$newLocation;
	$alSet->{format}=$newFormat;
	$alSet->{firstSentPair}=1;
	$alSet->{lastSentPair}="eof";		
    }
}

sub orderAsBilCorpus {
    my ($alSet,$newLocation,$newFormat,$alignMode,$corpSrc,$corpTrg,$verbose)=@_;
    if (!defined($newFormat)){$newFormat="TALP"}
    else {$newFormat = uc $newFormat}
    $newLocation = readLocation($newLocation);
    my $FH = $alSet->openFiles();
    my $newFH = openLocation($newLocation,$newFormat,">",$alSet->{location});
    my $inputSentPairNum=$alSet->{firstSentPair};
    my $internalSentPairNum = 1;	
    if ($verbose >0){
	select STDOUT; $| = 1;         # enable autoflush (desactivate buffering)
    }
    open(CS,"<$corpSrc") || die "$corpSrc file opening error !";
    open(CT,"<$corpTrg") || die "$corpTrg file opening error !";

    # LOAD BILINGUAL CORPUS IN HASH
    my %newcorp;
    my $cntCorp=0;
    while (my $s=<CS>) {
	chomp $s;
	my $t=<CT>;
	chomp $t;
	$newcorp{"$s ||| $t"}=1;
	$cntCorp++;
    }
    if ($verbose > 0){
	print "Number of different sentence pairs in new  corpus:".scalar(keys %newcorp)."\n";
    }
    
    # PARSE AL SET
    my $cntToFind=$cntCorp;
    my %found;
    while (my $alSetChunk = $alSet->loadChunk($FH,$inputSentPairNum,"as-is")){	# returns 0 if eof or last sentence pair
	for (my $i=0;$i<@$alSetChunk;$i++){
	    my $al = $$alSetChunk[$i];
	    my $pair=$al->sourceSentence." ||| ".$al->targetSentence;
	    if ($newcorp{$pair}){
		$found{$pair}=$al;
		$cntToFind--;
	    }
	} #for
	if ($cntToFind==0){
	    if ($verbose>0){print STDERR "Leaving loop of giza file at line:$inputSentPairNum\n";}
	    last;
	}
	$inputSentPairNum++;
	if ($verbose>0){
	    if ($inputSentPairNum % 100000 ==0){print $inputSentPairNum;}
	    if ($inputSentPairNum % 10000 ==0){print ".";}
	}
    } #while	
    if ($verbose>0){print "\n";}
    # REORDER AL SET 
    print "reordering Alignment set...\n";
    seek CS,0,0; #go back to beginning of file
    seek CT,0,0;
    while (my $s=<CS>) {
	chomp $s;
	my $t=<CT>;
	chomp $t;
	if (exists($found{"$s ||| $t"})){
	    my $al= $found{"$s ||| $t"};
	    $al->output($FH,$newFormat,$newFH,$newLocation,$internalSentPairNum);
	}else{
	    die "ERROR: not found sentence pair $internalSentPairNum in Alignment Set\n";
	}
	$internalSentPairNum++;
    }
    closeFiles($newFH,$newFormat);
    closeFiles($FH,$alSet->{format});
    $alSet->updateObject($newFormat,$newLocation,$internalSentPairNum-1);
}

sub adaptToBilCorpus {
    my ($alSet,$newLocation,$newFormat,$alignMode,$corpSrc,$corpTrg,$restrictions,$verbose)=@_;
    my $pdiff=$restrictions->{allowedPercentWordDiff};
    my $mindiff=$restrictions->{minAllowedNumWordDiff};
    my $maxdiff=$restrictions->{maxAllowedNumWordDiff};
    my $nfirst=$restrictions->{numWordsConsideredFirst};
    my $dumper = new Dumpvalue;

    if (!defined($newFormat)){$newFormat="TALP"}
    else {$newFormat = uc $newFormat}
    $newLocation = readLocation($newLocation);
    my $FH = $alSet->openFiles();
    my $newFH = openLocation($newLocation,$newFormat,">",$alSet->{location});
    my $inputSentPairNum=$alSet->{firstSentPair};
    my $internalSentPairNum = 1;	
    select STDOUT; $| = 1;         # enable autoflush (desactivate buffering)
    open(CS,"<$corpSrc") || die "$corpSrc file opening error !";
    open(CT,"<$corpTrg") || die "$corpTrg file opening error !";

    # DETECT ALSET SENTENCES THAT ARE IN THE CORPUS
    my %newcorp;
    while (my $s=<CS>) {
	chomp $s;
	my $t=<CT>;
	chomp $t;
	$newcorp{"$s ||| $t"}=1;
    }
    if ($verbose > 0){
	print "Number of different sentence pairs in new  corpus:".scalar(keys %newcorp)."\n";
    }
    my $count=0;
    while (my $alSetChunk = $alSet->loadChunk($FH,$inputSentPairNum,$alignMode)){
        # print $inputSentPairNum."\n";
	for (my $i=0;$i<@$alSetChunk;$i++){
	    my $al = $$alSetChunk[$i];
	    my $s = $al->sourceSentence;
	    my $t = $al->targetSentence;
	    my @ws=split / /,$s;
	    my @wt=split / /,$t;
	    my ($nums,$numt)=(scalar(@ws),scalar(@wt));
	    if (!$newcorp{"$s ||| $t"}){
		# DETECT CLOSEST SENTENCES IN NEW CORPUS AND MODIFY ALIGNMENT SET
		# calculate values for length test (to, later, skip lcs calculation)
		my $sAllowedDiff = Lingua::AlSetLib::max(Lingua::AlSetLib::min($nums*$pdiff/100,$maxdiff),$mindiff);
		my $tAllowedDiff = Lingua::AlSetLib::max(Lingua::AlSetLib::min($numt*$pdiff/100,$maxdiff),$mindiff);
		my $sMin=$nums-$sAllowedDiff;
		my $sMax=$nums+$sAllowedDiff;
		my $tMin=$numt-$tAllowedDiff;
		my $tMax=$numt+$tAllowedDiff;
		if ($verbose > 0){
		    print $s."\n";
		    print $t."\n";
		    print "ns:$nums nt:$numt allowed length diff: s:$sAllowedDiff t:$tAllowedDiff;\n\n";
		}
		my $bestLcs = 0;
		my @bestSrc;
		my @bestTrg;
		my ($cntGoodLength,$cntPassedFirstLCS,$cnt2)=(0,0,0);
		# parse new corpus
		foreach my $pair (keys %newcorp){
		    my ($cs,$ct)=split / \|\|\| /,$pair;
		    my @wcs = split / /,$cs;
		    my @wct = split / /,$ct;
		    my ($numcs,$numct)=(scalar(@wcs),scalar(@wct));

		    if ($verbose >2){print "ncs:$numcs nct:$numct\n";}
		    if ($verbose >2){print "CORPUS:\n$cs\n$ct\n";}		  
		    #length test:
		    if ($numcs<$sMin || $numcs>$sMax || $numct<$tMin || $numct>$tMax){
			# skip lcs ratio calculation
		    }else{
			$cntGoodLength++;
			#calculate LCS, but first looking at the nfirst first words
			my @fws;
			my @fwt;
			my @fwcs;
			my @fwct;
			for (my $i=0;$i<$nfirst;$i++){
			    push @fws,$ws[$i];
			    push @fwt,$wt[$i];
			    push @fwcs,$wcs[$i];
			    push @fwct,$wct[$i];
			}
			my $sLcs = Lingua::AlSetLib::LCS_ratio(\@fws,\@fwcs);
			my $tLcs = Lingua::AlSetLib::LCS_ratio(\@fwt,\@fwct);
			# first words LCS test:
			if ($sLcs == 0 || $tLcs == 0){
			    # skip lcs ratio calculation
			}else{
			    $cntPassedFirstLCS++;
			    my $sLcs = Lingua::AlSetLib::LCS_ratio(\@ws,\@wcs);
			    my $tLcs = Lingua::AlSetLib::LCS_ratio(\@wt,\@wct);
			    if ($verbose >1){
				print "ncs:$numcs nct:$numct\n";
				print "CORPUS:\n$cs\n$ct\n";
				print "chars src lcsr: $sLcs\t trg lcsr:$tLcs\n";
			    }  
			    my $lcs = $sLcs+$tLcs;
			    if ($lcs > $bestLcs){
				$bestLcs = $lcs;
				@bestSrc = ($cs);
				@bestTrg = ($ct);
			    }elsif($lcs == $bestLcs){
				push @bestSrc,$cs;
				push @bestTrg,$ct;
			    }
			}
		    } # if length test
		    if ($verbose >1){
			if ($cnt2>0 && ($cnt2 % 100000)==0){print "$cnt2";}
			elsif ($cnt2>0 && ($cnt2 % 1000)==0){print ".";}
		    }
		    $cnt2++;
		} # for each sent pair in corpus
		my $uniqBestSrc;
		my $uniqBestTrg;
		my $cntCharLevel=scalar(@bestSrc);
		if ($cntCharLevel>1){ 
		    my $bestLcs = 0;
		    # calculate LCS at character level
		    for (my $i=0;$i<$cntCharLevel;$i++){
			my $cs=$bestSrc[$i];
			my $ct=$bestTrg[$i];
			$cntCharLevel++;
			my @chars = split //,$s;
			my @charcs = split //,$cs;
			my $sLcs = Lingua::AlSetLib::LCS_ratio(\@chars,\@charcs);
			my @chart = split //,$t;
			my @charct = split //,$ct;
			my $tLcs = Lingua::AlSetLib::LCS_ratio(\@chart,\@charct);
			my $lcs = $sLcs+$tLcs;
			if ($lcs > $bestLcs){
			    $bestLcs = $lcs;
			    $uniqBestSrc = $cs;
			    $uniqBestTrg = $ct;
			}
		    }
		}else{
		    $uniqBestSrc = $bestSrc[0];
		    $uniqBestTrg = $bestTrg[0];
		}
		if ($cntGoodLength == 0){
		    print "WARNING: sentence pair $inputSentPairNum not found in corpus\n";
		}else{
		    if ($verbose >0){
			my $numCorp=scalar(keys %newcorp);
			print "Passed length test: $cntGoodLength / $numCorp\n";
			print "Passed first words LCS test: $cntPassedFirstLCS\n";
			print "LCS calculated at character level: "; if ($cntCharLevel==1){print "0"}else{print $cntCharLevel}; print "\n";
			print "\nbest lcsr: $bestLcs, best pair:\n$uniqBestSrc\n$uniqBestTrg\n";
		    }
		    # detect edits to pass from alset sent pair to corpus sent pair
		    my @bs=split / /,$uniqBestSrc;
		    my @diffs = Lingua::AlSetLib::diff( \@ws, \@bs );
		    if ($verbose>2){print $dumper->dumpValue(\@diffs);}

		    # parse output of diff function
		    my @updatedPosi; #array: orig posis -> updated posis
		    my %reversePosi; #hash: updated posis -> orig posis
		    for (my $i=0;$i<=$nums;$i++){
			$updatedPosi[$i]=$i;
			$reversePosi{$i}=$i;
		    }

		    foreach my $hunk (@diffs){
			my @delPosi;
			my @del;
			my @addPosi;
			my @add;
			foreach my $change (@$hunk) {
			    if ($change->[0] eq '-'){
				push @delPosi,$change->[1]+1;
				push @del,$change->[2];
			    }else{
				push @addPosi,$change->[1]+1;
				push @add,$change->[2];
			    }
			}
			# del posis are relative to first array (@ws) => update posis
			# add posis are relative to second array (@bs) => don't update posis
			my $numDel=scalar(@delPosi);
			my $numAdd=scalar(@addPosi);
			if ($numDel==0){ #insertion
			    $al->splice("source",$addPosi[0],0,\@add);
			    print "insert '",join(" ",@add),"' at position { ",$addPosi[0]," }\n";
			    #update updatedPosi array
			    for (my $i=$reversePosi{"$addPosi[0]"};$i<=$nums;$i++){
				$updatedPosi[$i]+=$numAdd;
				$reversePosi{"$updatedPosi[$i]"}=$i;
			    }
			}else{ # substitution or deletion
			    $al->splice("source",$updatedPosi[$delPosi[0]],$numDel,\@add);
			    print "substitute '",join(" ",@del),"' at positions { ",join(" ",@delPosi)," } by '",join(" ",@add),"'\n";
			    #update updatedPosi array
			    for (my $i=$delPosi[0]+$numDel;$i<=$nums;$i++){
				$updatedPosi[$i]+=$numAdd-$numDel;
				$reversePosi{"$updatedPosi[$i]"}=$i;
			    }
			}
		    }
		    #target
		    my @bt=split / /,$uniqBestTrg;
		    my @diffs = Lingua::AlSetLib::diff( \@wt, \@bt );
		    if ($verbose>2){print $dumper->dumpValue(\@diffs);}
		    # parse output of diff function
		    @updatedPosi=();
		    %reversePosi=();
		    for (my $i=0;$i<=$numt;$i++){
			$updatedPosi[$i]=$i;
			$reversePosi{$i}=$i;
		    }
		    foreach my $hunk (@diffs){
			my @delPosi;
			my @del;
			my @add;
			my @addPosi;
			foreach my $change (@$hunk) {
			    if ($change->[0] eq '-'){
				push @delPosi,$change->[1]+1;
				push @del,$change->[2];
			    }else{
				push @addPosi,$change->[1]+1;
				push @add,$change->[2];
			    }
			}
			#update updatedPosi array
			my $numDel=scalar(@delPosi);
			my $numAdd=scalar(@addPosi);
			if ($numDel==0){ #insertion
			    $al->splice("target",$addPosi[0],0,\@add);
			    print "insert '",join(" ",@add),"' at position { ",$addPosi[0]," }\n";
			    #update updatedPosi array
			    for (my $i=$reversePosi{"$addPosi[0]"};$i<=$numt;$i++){
				$updatedPosi[$i]+=$numAdd;
				$reversePosi{"$updatedPosi[$i]"}=$i;
			    }
			}else{ # substitution or deletion
			    $al->splice("target",$updatedPosi[$delPosi[0]],$numDel,\@add);
			    print "substitute '",join(" ",@del),"' at positions { ",join(" ",@delPosi)," } by '",join(" ",@add),"'\n";
			    #update updatedPosi array
			    for (my $i=$delPosi[0]+$numDel;$i<=$numt;$i++){
				$updatedPosi[$i]+=$numAdd-$numDel;
				$reversePosi{"$updatedPosi[$i]"}=$i;
			    }
			}
		    }
		    if ($verbose>0){print "--------------------------------------------------------------\n";}
		}
	    }else{
		# sentence pair is in corpus: don't modify anything
	    }
	    $al->output($FH,$newFormat,$newFH,$newLocation,$internalSentPairNum);
	    $count++;
	}
	$inputSentPairNum++;
	$internalSentPairNum++;
    } #while
    print "$count sentence pairs parsed in alignment set\n";
    closeFiles($newFH,$newFormat);
    closeFiles($FH,$alSet->{format});
    $alSet->updateObject($newFormat,$newLocation,$internalSentPairNum-1);
}

######################################################################
###	PRIVATE SUBS
######################################################################

sub readLocation{
	my $location = shift;
	
	if (!ref($location)){ #if it is a path, put it in a location hash
		$location = {"sourceToTarget"=>$location}
	}
	return $location;	
}

sub setRange {
    my ($alSet,$range) = @_;
	
    my @limits = split /-/, $range;
    my $numLimits = scalar(@limits);
    if ($numLimits == 0 || $numLimits >2){
	die "Invalid Range:$range\n";
    }elsif ($numLimits == 1){
	$limits[1]="";	
    }
    $limits[0] =~ s/^\s+|\s+$//g;
    $limits[1] =~ s/^\s+|\s+$//g;
    if ($limits[0] !~ /\d+/ || $limits[0] == 0){
	$alSet->{firstSentPair}="1";
    }else{
	$alSet->{firstSentPair}=$limits[0];
    }
    if ($limits[1] !~ /\d+/ || $limits[1] == 0){
	$alSet->{lastSentPair}="eof";
    }else{
	$alSet->{lastSentPair}=$limits[1];
    }
}

#for future ease we save detailed infos contained in the source sample path
#input: sourceToTarget dir (not optional), targetToSource dir (if exists), source path (optional) and target path (if necessary)
#output: target (if not specified in input), sampleNum (sample number)
sub completeBlinkerLocation{
	my $refToLocation = shift;
	my ($sourceLang,$targetLang);

	if ($refToLocation->{source}){
		my ($sourceDir,$sourceFileName)=split /\/([^\/]+)$/,$refToLocation->{source};
		if ($sourceFileName =~ /^(EN|FR)\.sample.\d+$/){
			#extract the sample number and target file:
			my ($sourceLang,$nothing,$sampleNum) = split /\./,$sourceFileName;
			$refToLocation->{sampleNum} = $sampleNum;
		}
	}
	if (!$refToLocation->{sampleNum}){
		$refToLocation->{sampleNum} = 1;
	}
}

# open (for read or write) the files contained in a "location" hash (ex. at the {location} key of the alignment set hash)
# if opens for write needs old location hash to check you won't delete the old format files
# returns a ref to a hash containing the filehandle variables (hash with same keys as "location" except for Blinker format)
sub openLocation {
    my ($location,$format,$openMode,$oldLocation) = @_;		#oldLocation: optional parameter
    my %FH;

    if ($openMode eq ">"){
	if ($format eq "BLINKER"){
	    completeBlinkerLocation($location);
	}
	# check that your new files are different to prevent from deleting the old ones
	my %oldFiles = reverse %$oldLocation;
	my ($key,$newFile);
	while (($key, $newFile)=each %$location){
	    if ($oldFiles{$newFile} && $key ne "sampleNum"){
		die "Convert function: you are opening for write one of the old format file: $newFile\n";	
	    }
	}
	#end of check
	
	# create directory structure where to create the file/directory if it doesn't exist, create it 
	my $type;
	if ($format eq "BLINKER"){$type = "dir"}
	else {$type = "file"}
	createDirStructure($location->{sourceToTarget},$type);
	if ($location->{targetToSource}){
	    createDirStructure($location->{targetToSource},$type);
	}
	if ($location->{source}){
	    createDirStructure($location->{source},"file");
	}
	if ($location->{target}){
	    createDirStructure($location->{target},"file");
	}
	#end create directory structure
    }
	
    if ($format eq "GIZA"){
	$FH{sourceToTarget} = IO::File->new($openMode.$location->{sourceToTarget}) or die "GIZA file (".$location->{sourceToTarget}.") opening error:$!";
	if ($location->{targetToSource}){
	    $FH{targetToSource} = IO::File->new($openMode.$location->{targetToSource}) or die "GIZA file (".$location->{targetToSource}.") opening error:$!"; 
	}
    } elsif ($format eq "NAACL" || $format eq "TALP"){
	if ($location->{source}){
	    $FH{source} = IO::File->new($openMode.$location->{source}) or die "Source file (".$location->{source}.")  opening error:$!";
	}
	if ($location->{target}){
	    $FH{target} = IO::File->new($openMode.$location->{target}) or die "Target file (".$location->{target}.")  opening error:$!";
	}
	$FH{sourceToTarget} = IO::File->new($openMode.$location->{sourceToTarget}) or die "Alignment file (".$location->{sourceToTarget}.") opening error:$!";				
	if ($location->{targetToSource}){
	    $FH{targetToSource} = IO::File->new($openMode.$location->{targetToSource}) or  die "Alignment file (".$location->{targetToSource}.") opening error:$!";
	}
    } elsif ($format eq "BLINKER"){
	if ($location->{source}){
	    $FH{source} = IO::File->new($openMode.$location->{source}) or die "BLINKER source file (".$location->{source}.") opening error:$!";
	}
	if ($location->{target}){
	    $FH{target} = IO::File->new($openMode.$location->{target}) or die "BLINKER source file (".$location->{target}.") opening error:$!";
	}
    }
    return (\%FH);
}


# if you want to create a file of path "directory_structure/file", makes "directory_structure" if necessary.
# if you want to create a directory of path "directory_structure", makes it if it doesn't exist
# type is "dir" (if you want to create a directory) or "file" (a file) 
sub createDirStructure {
    my ($path,$type)=@_;
    
    if ($type eq "dir"){
	unless(-e $path && -d _){
	    system('mkdir -p '.$path); 
	}	
    }elsif ($type eq "file"){
	$path =~ s/\/$//;
	if ($path =~ /\//){
	    my ($dir,$file)=split /\/[^\/]+$/,$path;
	    unless (-e $dir){
		system('mkdir -p '.$dir);	
	    }
	}
    }
}

# open files of an alignment set for read and go to first sentence pair
sub openFiles {
    my $alSet = shift;
    my %FH = %{openLocation($alSet->{location},$alSet->{format},"<")};
    my $fhPos;
    my $lineNb;

    # go to first Sentence pair:
    if ($alSet->{format} eq "TALP"){
	for ($lineNb=$alSet->{firstSentPair}-1;$lineNb>0;$lineNb--){ #go to first Sentence pair
	    if ($FH{source}){
		$FH{source}->getline();	
	    }
	    if ($FH{target}){
		$FH{target}->getline();	
	    }
	    if ($FH{sourceToTarget}){
		$FH{sourceToTarget}->getline();	
	    }
	    if ($FH{targetToSource}){
		$FH{targetToSource}->getline();	
	    }
	}
    }elsif ($alSet->{format} eq "GIZA"){
	for ($lineNb=$alSet->{firstSentPair}-1;$lineNb>0;$lineNb--){ #go to first Sentence pair
	    $FH{sourceToTarget}->getline();	
	    $FH{sourceToTarget}->getline();	
	    $FH{sourceToTarget}->getline();	
	    if ($FH{targetToSource}){
		$FH{targetToSource}->getline();	
		$FH{targetToSource}->getline();	
		$FH{targetToSource}->getline();	
	    }
	}
    } elsif ($alSet->{format} eq "NAACL"){
	for ($lineNb=$alSet->{firstSentPair}-1;$lineNb>0;$lineNb--){ 
	    if ($FH{source}){
		$FH{source}->getline();	
	    }
	    if ($FH{target}){
		$FH{target}->getline();	
	    }
	    $fhPos = $FH{sourceToTarget}->getpos;
	    while ($FH{sourceToTarget}->getline() !~ m/^0*$alSet->{firstSentPair} .*/ && !$FH{sourceToTarget}->eof()) {
		$fhPos = $FH{sourceToTarget}->getpos;
	    }
	    if ($FH{sourceToTarget}->eof()){
		die "First sentence pair of range (number ".$alSet->{firstSentPair}.") not found in ".$alSet->{location}{sourceToTarget}; 	
	    }
	    $FH{sourceToTarget}->setpos($fhPos); #if we changed sentences, we read the first line of next sentence=>go back one line
	    if ($FH{targetToSource}){
		$fhPos = $FH{targetToSource}->getpos;
		while ($FH{targetToSource}->getline() !~ m/^0*$alSet->{firstSentPair} .*/ && !$FH{targetToSource}->eof()) {
		    $fhPos = $FH{targetToSource}->getpos;
		}
		if ($FH{targetToSource}->eof()){
		    die "First sentence pair of range (number ".$alSet->{firstSentPair}.") not found in ".$alSet->{location}{targetToSource}; 	
		}
		$FH{targetToSource}->setpos($fhPos);
	    }
	}
    } elsif ($alSet->{format} eq "BLINKER"){
	if ($FH{source}){
	    for ($lineNb=$alSet->{firstSentPair}-1;$lineNb>0;$lineNb--){ 
		$FH{source}->getline();	
	    }
	}
	if ($FH{target}){
	    for ($lineNb=$alSet->{firstSentPair}-1;$lineNb>0;$lineNb--){ 
		$FH{target}->getline();	
	    }
	}
    }
    return (\%FH);
}

# close the files contained in the hash at the {location} key of the alignment set hash
sub closeFiles {
    my ($FH,$format) = @_;
    
    if ($format eq "GIZA"){
	$FH->{sourceToTarget}->close();
	if ($$FH{targetToSource}){
	    $FH->{targetToSource}->close();
	}
    } elsif ($format eq "NAACL" || $format eq "TALP"){
	if ($FH->{source}){
	    $FH->{source}->close();
	}
	if ($FH->{target}){
	    $FH->{target}->close();
	}
	if ($FH->{sourceToTarget}){
	    $FH->{sourceToTarget}->close();
	}
	if ($FH->{targetToSource}){
	    $FH->{targetToSource}->close();
	}
    } elsif ($format eq "BLINKER"){
	if ($FH->{source}){
	    $FH->{source}->close();
	}
	if ($FH->{target}){
	    $FH->{target}->close();		
	}
    }
}

# convert a chunk of alignment set file to an array of references to simple (1 sentence) alignment objects
# returns 0 if the file is at eof
sub loadChunk {
    my ($alSet,$alFH,$sentPairNum,$alignMode) = @_;
    my ($sourceString,$targetString,$alString,$reverseAlString);
    my $st_alignments=[];
    my $ts_alignments=[];
    my $al;
    my $theEnd;
    
    if (!defined($alignMode) || $alignMode =~ /^as.?is$/i){
	$alignMode = "as-is";		
    }elsif ($alignMode =~ /^null.?align$/i){
	$alignMode = "null-align";
    }elsif ($alignMode =~ /^no.?null.?align$/i){
	$alignMode = "no-null-align";
    }else{
	die 'Incorrect alignment mode. Correct modes are "as-is","null-align" or "no-null-align".'."\n";
    }
    if ($alSet->{format} eq "TALP"){
	if ($alSet->{lastSentPair} eq "eof"){
	    $theEnd = $$alFH{sourceToTarget}->eof();
	}else{
	    $theEnd = ($$alFH{sourceToTarget}->eof() || $sentPairNum > $alSet->{lastSentPair});
	}
	if ($theEnd){
	    return 0;	
	}else{
	    if ($alFH->{source}){	
		$sourceString = $alFH->{source}->getline();
	    }
	    if ($alFH->{target}){	
		$targetString = $alFH->{target}->getline();
	    }
	    if ($alFH->{sourceToTarget}){
		$alString = $alFH->{sourceToTarget}->getline();
	    }
	    if ($alFH->{targetToSource}){
		$reverseAlString = $alFH->{targetToSource}->getline();
	    }
	    $al = Lingua::Alignment->new;
	    $al->loadFromTalp($alString,$reverseAlString,$sourceString,$targetString);
	}
    }elsif ($alSet->{format} eq "GIZA"){
	if ($alSet->{lastSentPair} eq "eof"){
	    $theEnd = $$alFH{sourceToTarget}->eof();
	}else{
	    $theEnd = ($$alFH{sourceToTarget}->eof() || $sentPairNum > $alSet->{lastSentPair});
	}
	if ($theEnd){
	    return 0;	
	}else{
	    $$alFH{sourceToTarget}->getline();
	    $targetString = $$alFH{sourceToTarget}->getline();
	    $alString = $$alFH{sourceToTarget}->getline();
	    if ($$alFH{targetToSource}){
		$$alFH{targetToSource}->getline();
		$$alFH{targetToSource}->getline();
		$reverseAlString  = $$alFH{targetToSource}->getline();
	    }
	    $al = Lingua::Alignment->new;
	    $al->loadFromGiza($alString,$targetString,$reverseAlString);		
	}
    } elsif ($alSet->{format} eq "NAACL"){
	my $fhPos;
	if ($alSet->{lastSentPair} eq "eof"){
	    $theEnd = $$alFH{sourceToTarget}->eof();
	}else{
	    $theEnd = ($$alFH{sourceToTarget}->eof() || $sentPairNum > $alSet->{lastSentPair});
	}
	if ($theEnd){
	    return 0;	
	}else{
	    if ($$alFH{source}){
		$sourceString = $$alFH{source}->getline();
		#strip tags and memorize snum:
		$sourceString =~ s/<s snum=\d+>(.*)<\/s>/$1/;
	    }
	    if ($$alFH{target}){
		$targetString = $$alFH{target}->getline();
		#strip tags and memorize snum:
		$targetString =~ s/<s snum=(\d+)>(.*)<\/s>/$2/;
	    }
	    $fhPos = $$alFH{sourceToTarget}->getpos;
	    $alString = $$alFH{sourceToTarget}->getline();
	    my ($num,$theRest)=split " ",$alString,2;
	    if ($num==$sentPairNum){	#skip if there is no link for this sentence pair
		$fhPos = $$alFH{sourceToTarget}->getpos;
		push @$st_alignments,$theRest;
		while ($$alFH{sourceToTarget}->getline() =~ m/^$sentPairNum (.*)$/) {
		    push @$st_alignments,$1;
		    $fhPos = $$alFH{sourceToTarget}->getpos;
		}
	    }
	    $$alFH{sourceToTarget}->setpos($fhPos); #if we changed sentences, we read the first line of next sentence=>go back one line
	    if ($$alFH{targetToSource}){
		$fhPos = $$alFH{targetToSource}->getpos; 
		$alString = $$alFH{targetToSource}->getline();
		my ($num,$theRest)=split " ",$alString,2;
		if ($num==$sentPairNum){	#skip if there is no link for this sentence pair
		    $fhPos = $$alFH{targetToSource}->getpos; 
		    push @$ts_alignments,$theRest;
		    while ($$alFH{targetToSource}->getline() =~ m/^$sentPairNum (.*)$/) {
			push @$ts_alignments,$1;
			$fhPos = $$alFH{targetToSource}->getpos; 
		    }
		}
		$$alFH{targetToSource}->setpos($fhPos); #if we changed sentences, we read the first line of next sentence=>go back one line
	    }
	    $al = Lingua::Alignment->new;
	    $al->loadFromBlinker($st_alignments,$ts_alignments,$sourceString,$targetString);
	}		
    } elsif ($alSet->{format} eq "BLINKER"){		
	if ($alSet->{lastSentPair} eq "eof"){
	    $theEnd = !(-e $alSet->{location}->{sourceToTarget}."/samp".$alSet->{location}->{sampleNum}.".SentPair".($sentPairNum-1));
	}else{
	    $theEnd = !(-e $alSet->{location}->{sourceToTarget}."/samp".$alSet->{location}->{sampleNum}.".SentPair".($sentPairNum-1)) || $sentPairNum > $alSet->{lastSentPair};
	}
	if ($theEnd){	
	    return 0;	
	}else{
	    if ($alFH->{source}){	
		$sourceString = $alFH->{source}->getline();
	    }
	    if ($alFH->{target}){	
		$targetString = $alFH->{target}->getline();
	    }
	    open(AL,"< ".$alSet->{location}->{sourceToTarget}."/samp".$alSet->{location}->{sampleNum}.".SentPair".($sentPairNum-1));
	    @$st_alignments = <AL>;			
	    close(AL);
	    if ($alSet->{location}->{targetToSource}){
		open(AL,"< ".$alSet->{location}->{targetToSource}."/samp".$alSet->{location}->{sampleNum}.".SentPair".($sentPairNum-1));
		@$ts_alignments = <AL>;			
		close(AL);
	    }
	    $al = Lingua::Alignment->new;
	    $al->loadFromBlinker($st_alignments,$ts_alignments,$sourceString,$targetString);		
	}
    } 
    if ($alignMode eq "null-align"){
	$al->forceNullAlign();
    }elsif ($alignMode eq "no-null-align"){
	$al->forceNoNullAlign();
    }
    return [$al];
}


sub updateObject {
    my ($alSet,$newFormat,$newLocation,$lastSentPairNum)=@_;
    $alSet->{location}->{sourceToTarget}=$newLocation->{sourceToTarget};	
    $alSet->{location}->{targetToSource}=$newLocation->{targetToSource};
    if ($newLocation->{source}){
	$alSet->{location}->{source}=$newLocation->{source};
    }else{
	if ($alSet->{firstSentPair} != 1 || $alSet->{format} ne $newFormat){ 
	    # in this case the numeration of the converted alignment file and that of the (not converted) source file will not correspond
	    delete($alSet->{location}->{source});
#			warn "After converting into ",$newLocation->{sourceToTarget},", the numeration of the source words file",
#			" didn't correspond any more to that of the alignment file. So the 'source' entry has been removed from the location hash.";
	}
    }
    if ($newLocation->{target}){
	$alSet->{location}->{target}=$newLocation->{target};
    }else{
	if ($alSet->{firstSentPair} != 1 || $alSet->{format} ne $newFormat){
	    # in this case the numeration of the converted alignment file and that of the (not converted) source file will not correspond
	    delete($alSet->{location}->{target});	
#			warn "After converting into ",$newLocation->{sourceToTarget},", the numeration of the target words file ",
#			"didn't correspond any more to that of the alignment file. So the 'target' entry has been removed from the location hash.";
	}
    }
    $alSet->{format}=$newFormat;
    if ($newFormat eq "BLINKER"){
	$alSet->{location}->{sampleNum}=$newLocation->{sampleNum};	
    }elsif(exists($alSet->{location}->{sampleNum})){
	delete($alSet->{location}->{sampleNum});
    }
    $alSet->{firstSentPair}=1;
    $alSet->{lastSentPair}=$lastSentPairNum;
}

# returns the alignment set, with a unique new file set that has the required location,format and range values.
# TO DO: conversion to Giza++ format
sub convert {
    my ($alSet,$newLocation,$newFormat,$alignMode,$AlignmentSub)=@_;
    if (!defined($newFormat)){$newFormat="TALP"}
    else {$newFormat = uc $newFormat}
    $newLocation = readLocation($newLocation);
    my $FH = $alSet->openFiles();
    my $newFH = openLocation($newLocation,$newFormat,">",$alSet->{location});
    my ($i,$al,$alSetChunk,$line,$lines);
    my $inputSentPairNum=$alSet->{firstSentPair};
    my $internalSentPairNum = 1;	
    while ($alSetChunk = $alSet->loadChunk($FH,$inputSentPairNum,$alignMode)){	# returns 0 if eof or last sentence pair
#	    print $inputSentPairNum."\n";
	for ($i=0;$i<@$alSetChunk;$i++){
	    $al = $$alSetChunk[$i];
	    if (defined($AlignmentSub)){
		#look if $AlignmentSub is a ref to an Array or a subroutine
		if (ref($AlignmentSub) eq "ARRAY"){
		    my ($sub,@params) = @$AlignmentSub;
		    $al->$sub(@params);	
		}else{
		    $al->$AlignmentSub();	
		}
	    }
	    $al->output($FH,$newFormat,$newFH,$newLocation,$internalSentPairNum);
	} #for
	$inputSentPairNum++;
	$internalSentPairNum++;
    } #while	
    closeFiles($newFH,$newFormat);
    closeFiles($FH,$alSet->{format});
    $alSet->updateObject($newFormat,$newLocation,$internalSentPairNum-1);
}


# returns the alignment set, with only manyToMany links (source and target words file don't change)
# at the moment, only works for sourceToTarget alignment (sourceAl)
sub printManyToMany {
    my ($alSet,$newLocation,$newFormat)=@_;
    if (!defined($newFormat)){$newFormat="TALP"}
    else {$newFormat = uc $newFormat}
    $newLocation = readLocation($newLocation);
    my $dumper=new Dumpvalue;
    my $FH = $alSet->openFiles();
    my $newFH = openLocation($newLocation,$newFormat,">",$alSet->{location});
    my ($i,$al,$alSetChunk,$line,$lines);
    my $inputSentPairNum=$alSet->{firstSentPair};
    my $internalSentPairNum = 1;	
    
    while ($alSetChunk = $alSet->loadChunk($FH,$inputSentPairNum,"no-null-align")){	# returns 0 if eof or last sentence pair
	for ($i=0;$i<@$alSetChunk;$i++){
	    $al = $$alSetChunk[$i];
	    my $clone = $al->clone;
	    # look for manyToMany links
	    my $clusters = $al->getAlClusters;
	    $al->{sourceAl}=[];
#	    print $dumper->dumpValue($clusters);
	    for (my $c=0;$c<@$clusters;$c++){
		if ( @{$clusters->[$c]{source}}>1 || @{$clusters->[$c]{target}}>1 ){
		    # this is a many to many alignment
		    foreach my $j (@{$clusters->[$c]{source}}){
			foreach my $k (@{$clusters->[$c]{target}}){
			    if ($clone->isIn("sourceAl",$j,$k)){
				push @{$al->{sourceAl}[$j]},$k;
			    }
			}
		    }
		}
	    }
	    $al->output($FH,$newFormat,$newFH,$newLocation,$internalSentPairNum);
	} #for
	$inputSentPairNum++;
	$internalSentPairNum++;
    } #while	
    closeFiles($newFH,$newFormat);
    closeFiles($FH,$alSet->{format});
    $alSet->updateObject($newFormat,$newLocation,$internalSentPairNum-1);
}


# identifies a link as sure or possible
# input: a Naacl-file line containing the link and refs to sure and possible hashes
# action: add to the relevant hash a key corresponding to this link
sub identifySurePossible{
	my ($line,$sure,$possible)=@_;
	my @components;
	my $alignment;
	
#	print "line:$line\n";
	
	#code adapted from Rada Mihalcea's wa_eval_align.pl, rada@cs.unt.edu
    # get all line components: format should be
    # sentence_no position_L1 position_L2 [S|P] [confidence]
    @components = split /\s+/, $line;
    
    if(scalar(@components) < 3) {
		print STDERR "Incorrect format in answer file\n";
	exit;
    }
    
    $alignment = $components[0]." ".$components[1]." ".$components[2];
    
    # identify the S[ure] alignments
    if( scalar (@components) == 3 || (scalar (@components) == 4 && ($components[3] =~ /^[\d\.]+$/ || $components[3] eq 'S')) ||
	(scalar (@components) == 5 && ($components[3] eq 'S' || $components[4] eq 'S'))) {
		$sure->{$alignment} = 1; 
    }
    
    # identify the P[robable] alignments
    if( (scalar (@components) == 4 && $components[3] eq 'P') || (scalar (@components) == 5 && 
    ($components[3] eq 'P' || $components[4] eq 'P'))) {
		$possible->{$alignment} = 1;
    }
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Lingua::AlignmentSet - Tools library to manage an Alignment Sets, i.e. a set of sentences aligned at the word (or phrase) level.

=head1 SYNOPSIS

  use Lingua::AlignmentSet;

  See the synopsis of  method calls in doc/reference.pdf

=head1 ABSTRACT

    This module is a Tools Library to manage an Alignment Set, i.e. a set of sentences aligned at the word (or phrase) level. It provides methods to display the links, to apply a function to each alignment of the set, to evaluate the alignments against a reference, and more. One of the objectives of the module is to allow the user to perform all these operations without bothering with the particular physical format of the Alignment Set. Anyway it also provides format conversion methods.

=head1 DESCRIPTION

See doc/reference.pdf for a description.

=head1 SEE ALSO

The reference file (doc/reference.pdf)

=head1 AUTHOR

Patrick Lambert, E<lt>lambert@lsi.upc.esE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Patrick Lambert

This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

=cut
