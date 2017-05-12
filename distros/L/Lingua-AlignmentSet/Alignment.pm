
########################################################################
# Author:  Patrik Lambert (lambert@talp.ucp.es)
#          Contributions from Adria de Gispert (agispert@gps.tsc.upc.es)
#						 and Josep Maria Crego (jmcrego@gps.tsc.upc.es)
# Description: Library of tools to process a set of links between the
#   words of two sentences.
#
#-----------------------------------------------------------------------
#
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

package Lingua::Alignment;
$VERSION=1.1;
use strict;
use Lingua::AlignmentSlice;
use Lingua::AlSetLib 1.1;
use Dumpvalue;

#an alignment is a hash with 4 components:
#   {sourceAl} ref to source position array, each position containing the array of aligned target positions.
#              Each linked target token is indicated with the array: (position,S(sure)/P(possible),confidence score)
#   {targetAl} same as sourceAl but reversed
#	{sourceWords} and {targetWords}: array of corresponding words
#   {sourceLinks}: hash (indexed by the source token position $j and target $i in the link: {$j $i} of arrays giving
#	{targetLinks}: same as sourceLinks, for target alignment
#				  more information about the link: ( S(sure) or P(possible) , confidence )
sub new {
    my $pkg = shift;
    my $al = {};
    
    $al->{sourceAl}=[];
    $al->{targetAl}=[];
    $al->{sourceWords} = [];
    $al->{targetWords} = [];
    $al->{sourceLinks} = {};
    $al->{targetLinks} = {};
    return bless $al,$pkg;
}

sub loadFromGiza {
    my ($al,$alignmentString,$targetString,$reverseAlignmentString) = @_;   
    my ($i,$elem,$positionsString);
    
    #TARGET
    $targetString =~ s/^\s+//;	#trim
    $targetString =~ s/\s+$//;	#trim
    $targetString =~ s/\s{2,}/ /g;	#remove multiple spaces
    if ($targetString !~ /^NULL /){
	$al->{targetWords}=["NULL"]; #we keep a place for the NULL word of the other direction
    }
    push @{$al->{targetWords}},split(/ /,$targetString);

    $alignmentString =~ s/\s{2,}/ /g;   #remove multiple spaces

    #SOURCE
    my $srcString = $alignmentString; 
    $srcString =~ s/ \(\{[^\}]+\}\)//g;
    $srcString =~ s/^\s+//; $srcString =~ s/\s+$//; 
    @{$al->{sourceWords}}=split / /,$srcString;

    #S2T LINKS
    #  here you can't use a hash because you would loose the order
    $_ = $alignmentString;
    my @correspondances =  /\(\{(.+?)\}\)/g; #take what is between parentesis ie links
    foreach my $positionsString (@correspondances){
	$positionsString =~ s/^\s+//; #trim
	$positionsString =~ s/\s+$//; #trim
	push @{$al->{sourceAl}}, [split / /,$positionsString];
    }

    #REVERSE ALIGNMENT
    if (length($reverseAlignmentString)>0){
	$reverseAlignmentString =~ s/\(\{ \}\)/\(\{   \}\)/g; #insert blanks in unlinked words
	$reverseAlignmentString =~ s/\}\)\s*$//g;	#rtrim
	
	@correspondances = split /\(\{\s|\}\)\s/, $reverseAlignmentString;
	for ($i=0;$i<@correspondances;$i+=2) { 
	    $positionsString = $correspondances[$i+1];
	    $positionsString =~ s/^\s+|\s+$//g; #trim
	    $positionsString =~ s/\s{2,}/ /g;	#remove multiple spaces
	    push @{$al->{targetAl}}, [split / /,$positionsString];
	}
    }
}

#input: $refToAlignedPairs_ts (target to source),$sourceSentence and $targetSentence are optional
sub loadFromBlinker{
    my ($al,$refToAlignedPairs_st,$refToAlignedPairs_ts,$sourceSentence,$targetSentence)=@_;
    my $i;
    my $pairStr;
    my @pair;
    my @pairs;

#LOAD SENTENCES (if applicable)
    if (defined($sourceSentence)){
	$sourceSentence =~ s/^\s+|\s+$//g; 	#trim
	$sourceSentence =~ s/\s{2,}/ /g;	#remove multiple space
	
	if ($sourceSentence !~ /^NULL /){
	    $al->{sourceWords}=["NULL"];
	}
	push @{$al->{sourceWords}},split(/ /,$sourceSentence);
    }
    if (defined($targetSentence)){
	$targetSentence =~ s/^\s+|\s+$//g;
	$targetSentence =~ s/\s{2,}/ /g;
	
	if ($targetSentence !~ /^NULL /){
	    $al->{targetWords}=["NULL"];
	}
	push @{$al->{targetWords}},split(/ /,$targetSentence);
    }
		
#LOAD SOURCE TO TARGET ALIGNMENT:
    #read alignment data
    foreach $pairStr (@$refToAlignedPairs_st){
	$pairStr =~ s/^\s+|\s+$//g;	#trim
	$pairStr =~ s/\s{2,}/ /g;	#remove multiple space		
	@pair = split / /,$pairStr;
	push @{$pairs[$pair[0]]},$pair[1];
	#load extra information (like S/P, confidence)
	if (@pair > 2){
	    $al->{sourceLinks}->{$pair[0]." ".$pair[1]}=[splice(@pair,2)] ; 
	}
    }
    # take into account unaligned words to have no undef entry in array:
    # Since we really want to think in terms of alignment and not words, we don't base ourself on the number of words
    for ($i=0;$i<@pairs;$i++){
	if (defined($pairs[$i])){
	    push @{$al->{sourceAl}},$pairs[$i];
	}else{
	    push @{$al->{sourceAl}},[];	
	}
    }
#	print main::Dumper($refToAlignedPairs_st,$al->{sourceAl});

#LOAD TARGET TO SOURCE ALIGNMENT:
    if (defined($refToAlignedPairs_ts)){
	if (@$refToAlignedPairs_ts>0){
	    @pairs=();
	    #read alignment data
	    foreach $pairStr (@$refToAlignedPairs_ts){
		$pairStr =~ s/^\s+|\s+$//g;	#trim
		$pairStr =~ s/\s{2,}/ /g;	#remove multiple space		
		@pair = split / /,$pairStr;
		push @{$pairs[$pair[0]]},$pair[1];
		#load extra information (like S/P, confidence)
		if (@pair > 2){
		    $al->{targetLinks}->{$pair[0]." ".$pair[1]}=[splice(@pair,2)] ; 
		}
	    }
	    # take into account unaligned words to have no undef entry in array:
	    for ($i=0;$i<@pairs;$i++){
		if (defined($pairs[$i])){
		    push @{$al->{targetAl}},$pairs[$i];
		}else{
		    push @{$al->{targetAl}},[];	
		}
	    }
	}
    }
#	print main::Dumper($refToAlignedPairs_ts,$al->{targetAl});
}

sub loadFromTalp{
    my ($al,$st_string,$ts_string,$sourceSentence,$targetSentence)=@_;

#LOAD SENTENCES (if applicable)
    if (defined($sourceSentence)){
	$sourceSentence =~ s/^\s+//g; 	#trim
	$sourceSentence =~ s/\s+$//g; 	#trim
	$sourceSentence =~ s/\s{2,}/ /g;	#remove multiple space
	if ($sourceSentence !~ /^NULL /){
	    $al->{sourceWords}=["NULL"];
	}
	push @{$al->{sourceWords}},split(/ /,$sourceSentence);
    }
    if (defined($targetSentence)){
	$targetSentence =~ s/^\s+//g;
	$targetSentence =~ s/\s+$//g;
	$targetSentence =~ s/\s{2,}/ /g;
	if ($targetSentence !~ /^NULL /){
	    $al->{targetWords}=["NULL"];
	}
	push @{$al->{targetWords}},split(/ /,$targetSentence);
    }
		
#LOAD SOURCE TO TARGET ALIGNMENT:
    if ($st_string ne ""){
	my @pairs;
	$st_string =~ s/\s{2,}/ /g;	#remove multiple space		
	$st_string =~ s/^\s+//g; #trim
	$st_string =~ s/\s+$//g; #trim
	#read alignment data
	my @lnks=split (/ /,$st_string);
	foreach my $pairStr (@lnks){
	    my @info = split /:/,$pairStr;
	    my ($src,$sep,$trg) = split /([^\d])/,$info[0];
	    push @{$pairs[$src]},$trg;
	    #load extra information (like S/P, confidence)
	    if ($sep eq "s"){
		$al->{sourceLinks}->{$src." ".$trg}=["S"]; 
	    }elsif ($sep eq "p" ){
		$al->{sourceLinks}->{$src." ".$trg}=["P"]; 
	    }
	    for (my $i=1;$i<@info;$i++){
		push @{$al->{sourceLinks}->{$src." ".$trg}},$info[$i];
	    }
	}
	# take into account unaligned words to have no undef entry in array:
	# Since we really want to think in terms of alignment and not words, we don't base ourself on the number of words
	for (my $i=0;$i<@pairs;$i++){
	    if (defined($pairs[$i])){
		push @{$al->{sourceAl}},$pairs[$i];
	    }else{
		push @{$al->{sourceAl}},[];	
	    }
	}
    }
#	print main::Dumper($refToAlignedPairs_st,$al->{sourceAl});
    my $refToAlignedPairs_ts;
    my $pairStr;
    my @pair;
#LOAD TARGET TO SOURCE ALIGNMENT:
    if ($ts_string ne ""){
	$ts_string =~ s/^\s+|\s+$//g;	#trim
	$ts_string =~ s/\s{2,}/ /g;	#remove multiple space		
	my @pairs=();
	#read alignment data
	my @lnks=split (/ /,$ts_string);
	foreach my $pairStr (@lnks){
	    my @info = split /:/,$pairStr;
	    my ($src,$sep,$trg) = split /([^\d])/,$info[0];
	    push @{$pairs[$src]},$trg;
	    #load extra information (like S/P, confidence)
	    if ($sep eq "s"){
		$al->{targetLinks}->{$src." ".$trg}=["S"]; 
	    }elsif ($sep eq "p" ){
		$al->{targetLinks}->{$src." ".$trg}=["P"]; 
	    }
	    for (my $i=1;$i<@info;$i++){
		push @{$al->{targetLinks}->{$src." ".$trg}},$info[$i];
	    }
	}
	# take into account unaligned words to have no undef entry in array:
	for (my $i=0;$i<@pairs;$i++){
	    if (defined($pairs[$i])){
		push @{$al->{targetAl}},$pairs[$i];
	    }else{
		push @{$al->{targetAl}},[];	
	    }
	}
    }
#	print main::Dumper($refToAlignedPairs_ts,$al->{targetAl});
}

# sourceSentence: returns the target sentence tokens without NULL word (separated by " "), by parsing the alignment object
sub sourceSentence {
	my $al = shift;
	my @sentence=@{$al->{sourceWords}};
	shift @sentence;
	return join " ",@sentence;
}

# TargetSentence: returns the target sentence tokens without NULL word (separated by " "), by parsing the alignment object
sub targetSentence {
	my $al = shift;
	my @sentence=@{$al->{targetWords}};
	shift @sentence;
	return join " ",@sentence;
}

# Remove links to NULL. 
# Note: to do this we need the alignment to be loaded so we do it in a separate function 
sub forceNoNullAlign {
    my $al = shift;
    my ($j,$i);
    my $continue;
    my $source;
    my @sides=("source","target");
    
    foreach $source (@sides){
	$al->{$source."Al"}[0]=[];
	for ($j=1;$j<@{$al->{$source."Al"}};$j++){
	    if ($al->isIn($source."Al",$j,0)){
		$continue=1;
		for ($i=0;$i<@{$al->{$source."Al"}[$j]} && $continue;$i++){
		    if ($al->{$source."Al"}[$j][$i]==0){
			splice(@{$al->{$source."Al"}[$j]}, $i, 1);
			$continue=0;
		    }
		}
	    }
	}
    } #foreach
}

# Link to NULL with a P (Possible) alignment all words that are not linked to anything
sub forceNullAlign {
    my $al = shift;
    my ($j,$i);
    my @reverseAl;
    my $source;
    my @sides=("source","target");
    
    foreach $source (@sides){
	@reverseAl = ();
	for ($j=1;$j<@{$al->{$source."Al"}};$j++){
	    if (@{$al->{$source."Al"}[$j]}==0){
		push @{$al->{$source."Al"}[$j]},0;
		$al->{$source."Links"}->{"$j 0"}= ["P"];
	    }else{
		foreach $i (@{$al->{$source."Al"}[$j]}){
		    push @{$reverseAl[$i]},$j; 	
		}
	    }
	}
	for ($i=1;$i<@reverseAl;$i++){
	    if (!defined($reverseAl[$i]) || @{$reverseAl[$i]}==0){
		if (!$al->isIn($source."Al",0,$i)){
		    push @{$al->{$source."Al"}[0]},$i;
		    $al->{$source."Links"}->{"0 $i"}= ["P"];
		}
	    }	
	}
    } #foreach
}

sub writeToBlinker{
    my $al = shift;
    my $side = shift; #optional; default:"source";
    if (!defined($side)){$side="source"}
    my @lines = ();
    my ($i,$j);

    for ($j=0;$j<@{$al->{$side."Al"}};$j++){
	foreach $i (@{$al->{$side."Al"}[$j]}){
	    if (${$al->{$side."Links"}}{"$j $i"}){
		push @lines,"$j $i ".join(" ",@{$al->{$side."Links"}{"$j $i"}});
	    }else{
		push @lines,"$j $i";	
	    }
	}
    }		
    return \@lines;
}

sub writeToGiza{
    my $al = shift;
    my $side = shift; #optional; default:"source";

    # first line
    my @lines = ();
    push @lines,"#\n";

    # second line
    my $invSide;
    if (!defined($side)){$side="source"}
    if ($side eq "source"){
	$invSide="target";
	push @lines,$al->targetSentence."\n";
    }else{
	$invSide="source";
	push @lines,$al->sourceSentence."\n";
    }
    
    # third line
    my $linksStr="";
    for (my $j=0;$j<@{$al->{$side."Words"}};$j++){
	$linksStr.=$al->{$side."Words"}->[$j].' ({ ';
	foreach my $i (@{$al->{$side."Al"}[$j]}){
	    $linksStr.="$i ";
	}
	$linksStr.='}) ';
    }
    $linksStr =~ s/\s+$//;
    $linksStr.="\n";
    push @lines,$linksStr;
#    print "GIZA OUTPUT:\n",join("\n",@lines);
    return join("",@lines);
}

sub writeToTalp{
    my $al = shift;
    my $side = shift; #optional; default:"source";
    if (!defined($side)){$side="source"}
    my @lines = ();
    my ($i,$j);
   
    for ($j=0;$j<@{$al->{$side."Al"}};$j++){
	foreach $i (@{$al->{$side."Al"}[$j]}){
	    if (${$al->{$side."Links"}}{"$j $i"}){
		my $lk="$j".lc(${$al->{$side."Links"}{"$j $i"}}[0])."$i";
		for (my $k=1;$k<@{$al->{$side."Links"}{"$j $i"}};$k++){
		    $lk.=":".${$al->{$side."Links"}{"$j $i"}}[$k];
		}
		push @lines,$lk;
	    }else{
		push @lines,$j."-".$i;	
	    }
	}
    }		
    return join(" ",@lines);
}

sub output {
    my ($al,$FH,$newFormat,$newFH,$newLocation,$internalSentPairNum)=@_;
    my $dumper = new Dumpvalue;
   if ($newFormat eq "TALP"){
	if ($newFH->{source}){
	    $newFH->{source}->print($al->sourceSentence."\n");
	}
	if ($newFH->{target}){
	    $newFH->{target}->print($al->targetSentence."\n");
	}
	if ($newFH->{sourceToTarget}){
	    $newFH->{sourceToTarget}->print($al->writeToTalp("source")."\n");
	}
	if ($newFH->{targetToSource}){
	    $newFH->{targetToSource}->print($al->writeToTalp("target")."\n");
	}
    }elsif ($newFormat eq "NAACL"){
	if ($newFH->{source}){
	    $newFH->{source}->print("<s snum=$internalSentPairNum> ".$al->sourceSentence." </s>\n");
	}
	if ($newFH->{target}){
	    $newFH->{target}->print("<s snum=$internalSentPairNum> ".$al->targetSentence." </s>\n");
	}
	my $lines = $al->writeToBlinker("source");
	foreach my $line (@$lines){
	    $newFH->{sourceToTarget}->print("$internalSentPairNum $line\n");
	}
	if ($newFH->{targetToSource}){
	    $lines = $al->writeToBlinker("target");
	    foreach my $line (@$lines){
		$newFH->{targetToSource}->print("$internalSentPairNum $line\n");
	    }
	}
    }elsif ($newFormat eq "GIZA"){
	if (exists($newFH->{sourceToTarget})){
	    $newFH->{sourceToTarget}->print("".$al->writeToGiza("source"));
	}
	if (exists($newFH->{targetToSource})){
	    $newFH->{targetToSource}->print("".$al->writeToGiza("target"));
	}
    }elsif ($newFormat eq "BLINKER"){
	if ($newFH->{source}){
	    $newFH->{source}->print($al->sourceSentence."\n");
	}
	if ($newFH->{target}){
	    $newFH->{target}->print($al->targetSentence."\n");
	}
	my $blinkerFile = $newLocation->{sourceToTarget}."/samp".$newLocation->{sampleNum}.".SentPair".($internalSentPairNum-1);
	open BLINKER, ">$blinkerFile" || die "Blinker file $blinkerFile opening problem:$!";
	my $lines = $al->writeToBlinker("source");
	foreach my $line (@$lines){
	    print BLINKER "$line\n";
	}
	close BLINKER;
	if ($newLocation->{targetToSource}){
	    $blinkerFile = $newLocation->{targetToSource}."/samp".$newLocation->{sampleNum}.".SentPair".($internalSentPairNum-1);
	    open BLINKER, ">$blinkerFile" || die "Blinker file $blinkerFile opening problem:$!";
	    my $lines = $al->writeToBlinker("target");
	    foreach my $line (@$lines){
		print BLINKER "$line\n";
	    }
	    close BLINKER;
	}
    }else {
	die "Output to format $newFormat is not implemented yet.";
    }
}

sub displayAsLinkEnumeration {
    my ($al,$format,$latex) = @_;
    my $lines="";
    
	
    if ($format eq "text"){
	my ($correspPosition,$wordPosition);
	
	$lines.= join(" ",@{$al->{sourceWords}})."\n"; 
	$lines.= join(" ",@{$al->{targetWords}})."\n\n"; 
	
	for ($wordPosition=0;$wordPosition<@{$al->{sourceWords}};$wordPosition++){
	    $lines.= @{$al->{sourceWords}}[$wordPosition]." <- ";
	    foreach $correspPosition (@{$al->{sourceAl}[$wordPosition]}){
		$lines.= $al->{targetWords}[$correspPosition]." ";
	    }
	    $lines.= "\n";
	}
	$lines.="\n\n";			
    }elsif ($format eq "latex"){
	my $numRowTokens = @{$al->{sourceWords}};
	my $numColTokens = @{$al->{targetWords}};
	my ($i,$j,$elt);
	my ($j_partOf_Bi,$i_partOf_Bj);
	my ($targetWord,$sourceWord);
	
	$lines.= $latex->fromText("\n".join(" ",@{$al->{sourceWords}})."\n"); 
	$lines.= $latex->fromText(join(" ",@{$al->{targetWords}})."\n\n").'\vspace{5mm}'."\n"; 
		
	for ($j=0; $j<$numRowTokens;$j++){
	    for ($i=0;$i<$numColTokens;$i++){
		$targetWord = $latex->fromText($al->{targetWords}[$i]);
		$sourceWord = $latex->fromText($al->{sourceWords}[$j]);
		$i_partOf_Bj = $al->isIn("sourceAl",$j,$i);
		$j_partOf_Bi = $al->isIn("targetAl",$i,$j);
		if ($i_partOf_Bj > 0) {    #ie i=aj
		    if ($j_partOf_Bi > 0){ 
			$lines.= $sourceWord.' \boldmath $\leftrightarrow$ '.$targetWord." \n\n";
		    }else{		  
			$lines.= $sourceWord.' \boldmath $\leftarrow$ '.$targetWord." \n\n";
		    }
		}else{
		    if ($j_partOf_Bi > 0){
			$lines.= $sourceWord.' \boldmath $\rightarrow$ '.$targetWord." \n\n";
		    }else{
		    }
		} 
	    }
	}
	$lines.= "\n\n".'\vspace{7mm}';
    } #elsif $format eq latex	
    return $lines;
}

sub displayAsMatrix {
    my ($al,$latex,$mark,$maxRows,$maxCols)= @_;
    my $matrix = "";
    my ($mark_ji,$mark_ij);
    my $mark_ji_cross='\boldmath $-$';
    my $numRowTokens = @{$al->{sourceWords}};
    my $numColTokens = @{$al->{targetWords}};
    my ($i,$j,$elt);
    my ($j_partOf_Bi,$i_partOf_Bj);
    my $offset;

    if ($numRowTokens>$maxRows){return $al->displayAsLinkEnumeration("latex",$latex)}
    
    $matrix.= $latex->fromText("\n".join(" ",@{$al->{sourceWords}})."\n"); 
    $matrix.= $latex->fromText(join(" ",@{$al->{targetWords}})."\n\n").'\vspace{5mm}'; 	

    for ($offset=0;$offset<$numColTokens;$offset+=$maxCols){
	$matrix.= "\n".'\begin{tabular}{l'."c" x $numColTokens.'}';
	for ($j=$numRowTokens-1;$j>=0;$j--){
	    $matrix.= "\n".$latex->fromText($al->{sourceWords}[$j]);
	    for ($i=$offset;$i<$numColTokens && $i<($offset+$maxCols);$i++){
		$i_partOf_Bj = $al->isIn("sourceAl",$j,$i);
		$j_partOf_Bi = $al->isIn("targetAl",$i,$j);
		if ($mark eq "cross"){$mark_ji=$mark_ji_cross}
		elsif ($mark eq "ambiguity"){
		    if (length($al->{sourceLinks}->{"$j $i"}[0])>0){$mark_ji=$al->{sourceLinks}->{"$j $i"}[0]}
		    else {$mark_ji = $mark_ji_cross}
		}	
		elsif ($mark eq "confidence"){
		    if (length($al->{sourceLinks}->{"$j $i"}[1])>0){$mark_ji=$al->{sourceLinks}->{"$j $i"}[1]}
		    else {$mark_ji = $mark_ji_cross}
		}
		else {$mark_ji = $mark}
		if ($mark eq "ambiguity"){
		    if (length($al->{targetLinks}->{"$i $j"}[0])>0){$mark_ij='\ver{'.$al->{targetLinks}->{"$i $j"}[0].'}'}
		    else {$mark_ij = '\ver{'.$mark_ji_cross.'}'}
		}elsif ($mark eq "confidence"){
		    if (length($al->{targetLinks}->{"$i $j"}[1])>0){$mark_ij='\ver{'.$al->{targetLinks}->{"$i $j"}[1].'}'}
		    else {$mark_ij = '\ver{'.$mark_ji_cross.'}'}
		}else{$mark_ij = '\ver{'.$mark_ji.'}'}
		
		$matrix.= "&";
		if ($i_partOf_Bj > 0) {    #ie i=aj
		    if ($j_partOf_Bi > 0){ 
			if ($mark_ji eq '\boldmath $-$' && $mark_ij eq '\ver{\boldmath $-$}'){
			    $matrix.= ' \boldmath ${+}$ ';
			}else{
			    $matrix.= " $mark_ji$mark_ij ";
			}
		    }else{		  
			$matrix.= " $mark_ji ";
		    }
		}else{
		    if ($j_partOf_Bi > 0){
			$matrix.= " $mark_ij ";
		    }else{
			$matrix.= ' . ';					
		    }
		}
	    } #for j=...
	    $matrix.= ' \\\\';
	}	#for i=...
	# last line
	$matrix.= "\n ";
	for ($i=$offset;$i<$numColTokens && $i<($offset+$maxCols);$i++){
	    $matrix.= ' & '.'\ver{'.$latex->fromText($al->{targetWords}[$i]).'}';
	}
	$matrix.= ' \\\\';
	$matrix.= "\n".'\end{tabular}'."\n\n".'\vspace{7mm}';
    } # loop on number of matrices
    
    return $matrix;
}


# prohibits situations of the type: if linked(e,f) and linked(e',f) and linked(e',f') but not linked(e,f')
# in this case the function links e and f'.
sub forceGroupConsistency {
    my ($al,$mode,$lex1,$lex2) = @_;
    #defaults:
    if (!defined($mode)){$mode=""}	
    my $dumper = new Dumpvalue;
    my $cloneAl = {};
    foreach my $source (("source","target")){
	# SELECT ONLY S LINKS
	my $sal = $al->SLinks();
	#first we divide the alignment in clusters of positions linked between each other
	my $groups=$sal->getAlClusters($source);
	
        #delete alignment
        if (defined($sal->{$source."Al"}) && @{$sal->{$source."Al"}}>0){
            for (my $j=0;$j<@{$sal->{$source."Al"}};$j++){
                $sal->{$source."Al"}[$j]=[];
            }
        }

#	print "BEFORE alignment:\n";
#	print $dumper->dumpValue($al->{$source."Al"});
#	print "CLUSTERS:\n";
#	print $dumper->dumpValue($groups);
	
	#then we check that all the links within each cluster exist, and create them if they don't
	my $g;
	for ($g=0;$g<@$groups;$g++){
	    if ($mode eq "contiguous"){
		my $sContiguousSeqs=Lingua::AlSetLib::getContiguousSequences ($groups->[$g]{source});
		my $tContiguousSeqs=Lingua::AlSetLib::getContiguousSequences ($groups->[$g]{target});
		if (@$sContiguousSeqs > 1 || @$tContiguousSeqs > 1){
#		print "CLUSTER:\n";
#		print $dumper->dumpValue($groups->[$g]);
		    my ($bestIbm1Prob,$bestSourceSeq,$bestTargetSeq)=(0,0,0);
		    for (my $sc=0;$sc<@$sContiguousSeqs;$sc++){
			my $sPhrase = $sal->printPhrase("source",$sContiguousSeqs->[$sc]);
			for (my $tc=0;$tc<@$tContiguousSeqs;$tc++){
			    my $tPhrase = $sal->printPhrase("target",$tContiguousSeqs->[$tc]);
			    my $ibm1t_s = Lingua::AlSetLib::ibm1Prob ($sPhrase,$tPhrase,$lex1);
			    my $ibm1s_t;
			    if (defined($lex2)){
				$ibm1s_t = Lingua::AlSetLib::ibm1Prob ($tPhrase,$sPhrase,$lex2);
			    }else{
				$ibm1s_t = $ibm1t_s;
			    }
			    my $ibm1 = 0.5*($ibm1t_s+$ibm1s_t);
#			    print "$sPhrase ||| $tPhrase ||| $ibm1t_s -- $ibm1s_t ==> $ibm1\n";
			    if ($ibm1 > $bestIbm1Prob){
				$bestIbm1Prob=$ibm1;
				$bestSourceSeq=$sc;
				$bestTargetSeq=$tc;
			    }
			}
		    }

		    @{$groups->[$g]{source}}=@{$sContiguousSeqs->[$bestSourceSeq]};
		    @{$groups->[$g]{target}}=@{$tContiguousSeqs->[$bestTargetSeq]};

#		    print " contiguous CLUSTER:\n";
#		    print $dumper->dumpValue($groups->[$g]);
#		    print "best: ".$al->printPhrase('source',$groups->[$g]{source})." | ".$al->printPhrase('target',$groups->[$g]{target})."\n";
		}
	    }
	    foreach my $j (@{$groups->[$g]{source}}){
		foreach my $i (@{$groups->[$g]{target}}){
		    if (!$al->isIn($source."Al",$j,$i)){
			push @{$al->{$source."Al"}[$j]},$i;	
		    }else{  # move from P to S links
			@{$al->{$source."Links"}->{"$j $i"}}[0]="";
		    }	
		}	
	    }
	}
#	print "CLUSTERS after:\n";
#	print $dumper->dumpValue($groups);
#	print "alignment AFTER:\n";
#	print $dumper->dumpValue($al->{$source."Al"});
    } #foreach $side
}

#####################################################
### SYMMETRIZATION SUBS                           ###
#####################################################                        
# input: alignment object
# output: intersection of source and target alignments of this object
sub intersect {
    my $al = shift;
    my $intersectSourceAl=[];
    my $intersectTargetAl=[];
    my ($i,$j,$ind);
    
    if (@{$al->{targetAl}}>0 && @{$al->{sourceAl}}>0){
	#for each link in sourceAl, look if it's present in targetAl
	for ($j=0;$j<@{$al->{sourceAl}};$j++){
	    if (defined($al->{sourceAl}[$j])){
		foreach $i (@{$al->{sourceAl}[$j]}){
		    if ($al->isIn("targetAl",$i,$j)){
			push @{$intersectSourceAl->[$j]},$i;
			push @{$intersectTargetAl->[$i]},$j;
		    }	
		}	
	    } #if defined
	}
    } #if targetAl is an empty array, then from the intersection sourceAl remains empty
    @{$al->{sourceAl}}=@{$intersectSourceAl};
    @{$al->{targetAl}}=@{$intersectTargetAl};
}

# input: alignment object
# output: union of source and target alignments of this object
sub getUnion {
    my $al=shift;
    my %union;
    $union{sourceAl}=[];
    $union{targetAl}=[];
    my ($j,$i,$ind);
    my %side=("source"=>"target","target"=>"source");
    my ($source,$target);
    
    if (@{$al->{targetAl}}>0 && @{$al->{sourceAl}}>0){
	while (($source,$target)= each(%side)){
	    for ($j=0;$j<@{$al->{$source."Al"}};$j++){
		if (defined($al->{$source."Al"}[$j])){
		    foreach $i (@{$al->{$source."Al"}[$j]}){
			push @{$union{$source."Al"}->[$j]},$i;
			if (!$al->isIn($target."Al",$i,$j)){
			    push @{$union{$target."Al"}->[$i]},$j;
			}	
		    } #foreach
		} 			
	    } #for
	}
    }elsif (@{$al->{sourceAl}}>0){
	@{$union{sourceAl}}=@{$al->{sourceAl}};	
    }else{
	@{$union{targetAl}}=@{$al->{targetAl}};	
    }
    @{$al->{sourceAl}}=@{$union{sourceAl}};
    @{$al->{targetAl}}=@{$union{targetAl}};
}

# input: alignment object
# output: this object where only the links of the side (source or target) with most links are selected
sub selectSideWithLinks{
	my ($al,$criterion,$dontCountNull)=@_;
	#defaults
	if (!defined($criterion)){$criterion="most"}
	if (!defined($dontCountNull)){$dontCountNull=1}
	my ($j,$i,$firstInd);
	my ($numSource,$numTarget)=(0,0);
	my $sourceAl=[];
	my $targetAl=[];
	
	if ($dontCountNull){$firstInd=1}
	else {$firstInd=0}
	#count links
	for ($j=$firstInd;$j<@{$al->{sourceAl}};$j++){
		if (defined($al->{sourceAl}[$j])){
			if (!$dontCountNull){
				$numSource+=@{$al->{sourceAl}[$j]};
			}else{
				foreach $i (@{$al->{sourceAl}[$j]}){
					if ($i!=0){$numSource++}	
				}
			}
		} 			
	} 
	for ($i=$firstInd;$i<@{$al->{targetAl}};$i++){
		if (defined($al->{targetAl}[$i])){
			if (!$dontCountNull){
				$numTarget+=@{$al->{targetAl}[$i]};
			}else{
				foreach $j (@{$al->{targetAl}[$i]}){
					if ($j!=0){$numTarget++}	
				}
			}
		} 			
	}
	#select side with (most,least) links
	if ( ($numSource>=$numTarget && $criterion eq "most") || ($numSource<$numTarget && $criterion ne "most")){ #select sourceAl
		for ($j=0;$j<@{$al->{sourceAl}};$j++){
			if (defined($al->{sourceAl}[$j])){
				foreach $i (@{$al->{sourceAl}[$j]}){
					push @{$sourceAl->[$j]},$i;
					push @{$targetAl->[$i]},$j;
				}
			} 			
		} 		
	}else{	#select targetAl
		for ($i=0;$i<@{$al->{targetAl}};$i++){
			if (defined($al->{targetAl}[$i])){
				foreach $j (@{$al->{targetAl}[$i]}){
					push @{$sourceAl->[$j]},$i;
					push @{$targetAl->[$i]},$j;
				}
			} 			
		}
	}
	@{$al->{sourceAl}}=@$sourceAl;
	@{$al->{targetAl}}=@$targetAl;
}

sub selectSideWithMostLinks{
	my $al=shift;
	return $al->selectSideWithLinks("most");	
}
sub selectSideWithLeastLinks{
	my $al=shift;
	return $al->selectSideWithLinks("least");	
}

# input: alignment object
# output: alignment object where source and target have been swapped
sub swapSourceTarget{
    my $al=shift;
    my ($link,$ref,$j,$i,$source);
    my @st;
    my @sides=("source","target");
    my $swappedAl={ "sourceAl"=>[],
		    "targetAl"=>[],
		    "sourceWords"=>$al->{targetWords},
		    "targetWords"=>$al->{sourceWords},
		    "sourceLinks"=>{},
		    "targetLinks"=>{}};
    
    foreach $source (@sides){
	for ($j=0;$j<@{$al->{$source."Al"}};$j++){
	    foreach $i (@{$al->{$source."Al"}[$j]}){
		push @{$swappedAl->{$source."Al"}[$i]},$j;	
	    }
	}
	#insert ref to empty array instead of undef entries
	for ($j=0;$j<@{$swappedAl->{$source."Al"}};$j++){
	    if (!defined($swappedAl->{$source."Al"}[$j])){
		$swappedAl->{$source."Al"}[$j]=[];
	    }	
	}
	# and now the sourceLinks
	while (($link,$ref)=each(%{$al->{$source."Links"}})){
	    @st=split(" ",$link);
	    $swappedAl->{$source."Links"}{"$st[1] $st[0]"}=$ref;	
	}
    }
    %$al=%$swappedAl;
}



# input: al object, offset, length, side (src or trg), ref to word list to be added, ref to a list of positions of the other side (to which all added words will be linked).
# output: Alignment object where given positions are sustituted by the words 
#
# notes: 1) in case of deleting various words:
#          - all added words are linked to all positions to which deleted words were linked (except if you provided a list of positions of the other side, in which case all added words are linked to those positions). 
#          - $al->{sourceLinks} information can be lost for these words.
#        2) Does not work for targetAl alignment
#        3) more efficient in "source" side than in "target"

sub splice {
    my ($al,$side,$offset,$length,$refToWordsToAdd,$refToOtherSidePosi)=@_;
    my $dumper = new Dumpvalue;
    
    if (!defined($refToWordsToAdd)){$refToWordsToAdd=[];}
    if (!defined($refToOtherSidePosi)){$refToOtherSidePosi=[];}
    my $numToDelete=$length;
    my $firstPos=$offset;
    my $lastPos=$offset+$length-1;
    my $numList = scalar(@$refToOtherSidePosi);
#    print $al->displayAsLinkEnumeration("text");
#    print "splice $side off:$offset len:$length add:",join(" ",@$refToWordsToAdd),"\n";
#    print "before:",join(" ",@{$al->{$side."Words"}}),"\n";

    # MODIFY WORDS ARRAY
    splice(@{$al->{$side."Words"}},$offset,$length,@$refToWordsToAdd);
#    print "after:",join(" ",@{$al->{$side."Words"}}),"\n";
    
    # MODIFY LINKS
    my $numToAdd=scalar(@$refToWordsToAdd);
    my $diff=$numToAdd-$numToDelete;
    my @modified;
    my %modifs;
    my %links;

    if ($side eq "target"){
	$al->swapSourceTarget;
    }
    #initialize modified array
    for (my $j=0;$j<@{$al->{sourceAl}}+$diff;$j++){
	push @modified,[];
    }
    #print "ANTES:\n";
    #print $al->displayAsLinkEnumeration("text");
    
    #fill modified array with existing links
    for (my $j=0;$j<@{$al->{sourceAl}};$j++){
	if (defined($al->{sourceAl}[$j])){
	    foreach my $i (@{$al->{sourceAl}[$j]}){
		#print "i $i j  $j firstPos $firstPos\n";
		if ($j<$firstPos){
		    push @{$modified[$j]},$i;
		    $links{"$j $i"}=$al->{sourceLinks}{"$j $i"};
		}elsif ($j>=$firstPos && $j<=$lastPos){
		    if ($numList==0){
			#link added words to positions to which were linked the deleted words
			for (my $p=$firstPos;$p<$firstPos+$numToAdd;$p++){
			    if (!exists($modifs{$p}{$i})){
				push @{$modified[$p]},$i;
				$links{"$p $i"}=$al->{sourceLinks}{"$j $i"};
				$modifs{$p}{$i}=1;
			    }
			}
		    }
		}else{
		    push @{$modified[$j+$diff]},$i;
		    $links{($j+$diff)." $i"}=$al->{sourceLinks}{"$j $i"};
		}
	    }	
	} #if defined
    }
    # insert provided links
    for (my $p=$firstPos;$p<$firstPos+$numToAdd;$p++){
	foreach my $i (@$refToOtherSidePosi){
	    push @{$modified[$p]},$i;
	}
    }
    
    @{$al->{sourceAl}}=@modified;
    if ($side eq "target"){
	$al->swapSourceTarget;
    }
    #print "DESPUES:\n";
    #print $al->displayAsLinkEnumeration("text");
}


# INPUT: string (regexp) to be replaced, string (regexp) to replace it, side ("source" or "target")
# NOTES: 1) in case of deleting various words, all added words are linked to all positions to which deleted words were linked. $al->{sourceLinks} information can be lost for replaced words.
#        2) Does not work for targetAl alignment
#        3) more efficient in "source" side than in "target"
sub regexpReplace {
    my ($al,$regToDelete,$regToReplace,$side)=@_;
    my $dumper=new Dumpvalue;
    #print STDERR "s/$regToDelete/$regToReplace/\n";
    my $sentence;
    if ($side eq "source"){$sentence=$al->sourceSentence;}
    else {$sentence=$al->targetSentence;}
    my $newSentence=$sentence;
    $newSentence =~ s/$regToDelete/$regToReplace/og;
    #print $al->sourceSentence."\n";
    #print $al->targetSentence."\n";
    #print $newSentence."\n";
    my @words = split / /,$sentence;
    my $nums = scalar(@words);
    my @newWords = split / /,$newSentence;
    my @diffs    = Lingua::AlSetLib::diff( \@words, \@newWords );
    
    # parse output of diff function
    my @updatedPosi; #array: orig posis -> updated posis
    my %reversePosi; #hash: updated posis -> orig posis
    for (my $i=0;$i<=$nums;$i++){
	$updatedPosi[$i]=$i;
	$reversePosi{$i}=$i;
    }
    
    #$dumper->dumpValue(\@diffs);
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
	my $numDel=scalar(@delPosi);
	my $numAdd=scalar(@addPosi);

	# del posis are relative to first array (@words) => update posis
	# add posis are relative to second array (@newWords) => don't update posis
	if ($numDel==0){ #insertion
	    $al->splice("$side",$addPosi[0],0,\@add);
	    #print "insert '",join(" ",@add),"' at position { ",$addPosi[0]," }\n";
	    #update updatedPosi array
	    for (my $i=$reversePosi{"$addPosi[0]"};$i<=$nums;$i++){
		$updatedPosi[$i]+=$numAdd;
		$reversePosi{"$updatedPosi[$i]"}=$i;
	    }
	}else{ # substitution or deletion
	    $al->splice("$side",$updatedPosi[$delPosi[0]],$numDel,\@add);
	    #print "substitute '",join(" ",@del),"' at positions { ",join(" ",@delPosi)," } by '",join(" ",@add),"'\n";
	    #update updatedPosi array
	    for (my $i=$delPosi[0]+$numDel;$i<=$nums;$i++){
		$updatedPosi[$i]+=$numAdd-$numDel;
		$reversePosi{"$updatedPosi[$i]"}=$i;
	    }
	}
    }
}

# eliminates any given WORD from the source or target file corpus and updates the alignment
# input: $al (current Alignment object),$word (word RegExp to eliminate), $wordSide (from which side: source or target)
# kept for compatibility with previous versions (regexpReplace or replaceWords should be used instead)
sub eliminateWord {
    my ($al,$word,$wordSide)= @_;
    return $al->replaceWords($word,'',$wordSide);
}

# INPUT: string to be replaced, string to replace it, side ("source" or "target")
# NOTES: 1) in case of deleting various words, all added words are linked to all positions to which deleted words were linked. $al->{sourceLinks} information can be lost for replaced words.
#        2) Does not work for targetAl alignment
#        3) more efficient in "source" side than in "target"
sub replaceWords {
    my ($al,$stToDelete,$stToReplace,$side)=@_;
    my $dumper=new Dumpvalue;
    $stToDelete =~ s/(^\s|\s$)//g;  
    $stToDelete =~ s/\s+/ /g;
    $stToReplace =~ s/(^\s|\s$)//g;
    $stToReplace =~ s/\s+/ /g;
		      
    my @wToDel=split / /,$stToDelete;
    my $numToDel = scalar(@wToDel);
    my @toAdd=split(/ /,$stToReplace);
    my $numToAdd=scalar(@toAdd);
    my $diff=$numToAdd-$numToDel;
#    print $al->displayAsLinkEnumeration("text"),"\n";
    #list of positions where string to be deleted starts in @sourceWords (or target) array
    my @startToDelInAl=Lingua::AlSetLib::findArrayInAnother(\@wToDel,$al->{$side."Words"});
    my $offset=0; 
    foreach my $startPosi (@startToDelInAl){
	my @posis;
	for (my $i=0;$i<$numToDel;$i++){
	    push @posis,$startPosi+$i+$offset;
	}
	#print "positions:",join(" ",@posis),"\n";
	#$al->substitutePositions(\@posis,$side,$stToReplace);
	$al->splice($side,$posis[0],scalar(@posis),\@toAdd);
	$offset+=$diff;
    }
 #   print $al->displayAsLinkEnumeration("text"),"\n";
}


# introduces underscore between links of many-to-many groups in source to target alignment
# WARNING: THIS SUB FOR NOW ONLY CHANGES WORDS FILES, NOT THE LINKS FILE
sub manyToMany2joined {
    my $al=shift;
    my $new;
    @{$new->{source}} = @{$al->{sourceWords}};
    @{$new->{target}} = @{$al->{targetWords}};
 
    my @sides=("source","target");
    

    # group many-to-many linked phrases in clusters
    my $clusters=$al->getAlClusters;
    my $dumper = new Dumpvalue;
#    print "\n";
#    print $al->sourceSentence."\n";
#    print $al->targetSentence."\n";

#    print "CLUSTERS:\n";
#    print $dumper->dumpValue($clusters);
    foreach my $source (@sides){
	#sort clusters
	my %firstClustPos;
	for (my $c=0;$c<@$clusters;$c++){
	    @{$clusters->[$c]{$source}} = sort { $a <=> $b; } @{$clusters->[$c]{$source}};
	}
	@$clusters =  sort {$a->{$source}[0] <=> $b->{$source}[0]} @$clusters;
	
	my $offset=0;
	foreach my $clust (@$clusters){
	    if ( @{$clust->{$source}} >1 ){
		#check that cluster is contiguous
		my $contiguous=1;
		for (my $c=1;$c<@{$clust->{$source}};$c++){
		    if ($clust->{$source}[$c] != ($clust->{$source}[$c-1]+1) ){
			$contiguous=0;
			last;
		    }
		}
		if ($contiguous){
		    # introduce underscore
		    my $numWords = @{$clust->{$source}};
		    my $newWord=$al->{$source."Words"}[$clust->{$source}[0]];
		    for (my $c=1;$c<$numWords;$c++){
			$newWord=$newWord."_".$al->{$source."Words"}[$clust->{$source}[$c]];
		    }
#		    print "new word: $newWord\n";
		    splice(@{$new->{$source}},$clust->{$source}[0]-$offset,$numWords,$newWord);

		    $offset+=$numWords-1;
		}else{
		    print STDERR "not contiguous\n";
		}
	    } #if
	}
#    print "\n";
    } #foreach $source
#    print "new source:",join(" ",@{$new->{source}}),"\n";
#    print "new target:",join(" ",@{$new->{target}}),"\n";
    @{$al->{sourceWords}}=@{$new->{source}};
    @{$al->{targetWords}}=@{$new->{target}};
}


# recreates links of words linked by underscore and removes underscores
# ONLY WORKS WITH SOURCE2TARGET AlIGNMENT
sub joined2ManyToMany {
    my $al=shift;
#    print $al->sourceSentence."\n";
#    print $al->targetSentence."\n";

    my @sides=("source","target");
    foreach my $source (@sides){
	my %joined;
	for (my $j=1;$j<@{$al->{$source."Words"}};$j++){
	    if ($al->{$source."Words"}[$j] =~ /@@@/){
		$joined{$j}=1;
	    }
	}
	my @sortedJoined = sort { $a <=> $b } keys(%joined);
	my $offset=0;
	foreach my $pos (@sortedJoined){
	    # insert new words
	    my $joinedWords = $al->{$source."Words"}[$pos+$offset];
	    my @newWords = split(/@@@/,$joinedWords);
	    my $firstWord = shift @newWords;
	    $al->{$source."Words"}[$pos+$offset]=$firstWord;

	    # insert new words to alignment, all linked to the same target words as the old (joined) token
	    if ($source eq "source"){
		$al->splice($source,$pos+1+$offset,0,\@newWords,$al->{sourceAl}[$pos+$offset]);
	    }else{
		# look for links aligned to $pos+$offset
		my @alignedPos;
#		print "pos offset:".($pos+$offset)."\n";
		for (my $j=0;$j<@{$al->{sourceAl}};$j++){
		    foreach my $i (@{$al->{sourceAl}[$j]}){
			if ($i == ($pos+$offset)){
			    push @alignedPos,$j;	
			}
		    }
		}
		$al->splice($source,$pos+1+$offset,0,\@newWords,\@alignedPos);
	    }
	    $offset += @newWords;
	}
    }
}

#input: (source,target) link
#output: true if the link is reciprocal (or "cross link"), false otherwise
sub isCrossLink {
	my ($al,$j,$i)=@_;
#	print "s $j $i:",$al->isIn("sourceAl",$j,$i)," t $i $j:",$al->isIn("targetAl",$i,$j),"\n";
	return ( $al->isIn("sourceAl",$j,$i) && $al->isIn("targetAl",$i,$j) );	
}

sub isAnchor{
	my ($al,$j,$side)=@_;
	my ($reverseSide,$i);

	if ($side eq "source"){$reverseSide="target"}
	else {$reverseSide = "source"}
	if (defined($al->{$side."Al"}[$j])){
		if (@{$al->{$side."Al"}[$j]}==1){
			$i = $al->{$side."Al"}[$j][0];
			if (defined($al->{$reverseSide."Al"}[$i])){
				if (@{$al->{$reverseSide."Al"}[$i]}==1 && $al->{$reverseSide."Al"}[$i][0]==$j){
					return 1;
				}
			}
		}
	}
	return 0;
}

#mode: 	"noAnchors" cuts zones between 2 anchors and cannot include an anchor point
#		"anchors" cuts zone established by coordinates and doesn't look more
sub cut {
	my ($al,$startPointSource,$startPointTarget,$endPointSource,$endPointTarget,$mode)=@_;
	if (!defined($mode)){$mode="noAnchors"} 
	my ($j,$i,$ind);
	my %sourceInGap=();
	my %targetInGap=();
	my @sortedSourceInGap=();
	my @sortedTargetInGap=();
	my %sourceToNull=();
	my %targetToNull=();
	my $gap = Lingua::AlignmentSlice->new($al);
	my @linked=();
	my ($zeroSource,$zeroTarget,$numSource,$numTarget);
	my ($oldNumInGap,$newNumInGap);
	for ($j=$startPointSource+1;$j<$endPointSource;$j++){
		$sourceInGap{$j}=1;
	}
	for ($i=$startPointTarget+1;$i<$endPointTarget;$i++){
		if ($mode eq "noAnchors"){
			if (!$al->isAnchor($i,"target")){
				$targetInGap{$i}=1;	
			}
		}else{
			$targetInGap{$i}=1;	
		}
	}
#	print "\n($startPointSource,$startPointTarget,$endPointSource,$endPointTarget)\n";
#	print "source in gap 1:".join(" ",keys %sourceInGap)."\n";
#	print "target in gap 1:".join(" ",keys %targetInGap)."\n";
	
	#look at linked words situated outside the gap square:	
	$oldNumInGap=0;
	$newNumInGap=scalar(keys %sourceInGap)+scalar(keys %targetInGap);
	while ($oldNumInGap != $newNumInGap){
		foreach $i (keys %targetInGap){
			foreach $j (@{$al->{targetAl}[$i]}){
				if ($j!=0){
					$sourceInGap{$j}=1;
				}
				else {$targetToNull{$i}=1};	
			}
			for ($j=1;$j<@{$al->{sourceAl}};$j++){
				if 	($al->isIn("sourceAl",$j,$i)){
					$sourceInGap{$j}=1;
				}
			}
		}
		foreach $j (keys %sourceInGap){
			foreach $i (@{$al->{sourceAl}[$j]}){
				if ($i!=0){
					$targetInGap{$i}=1;
				}
				else {$sourceToNull{$j}=1};	
			}
			for ($i=1;$i<@{$al->{targetAl}};$i++){
				if 	($al->isIn("targetAl",$i,$j)){
					$targetInGap{$i}=1;
				}
			}
		}
		$oldNumInGap=$newNumInGap;
		$newNumInGap=scalar(keys %sourceInGap)+scalar(keys %targetInGap);
	}
	foreach $i (@{$al->{sourceAl}[0]}){
		if ($targetInGap{$i}){$targetToNull{$i}=1}
	}
	foreach $j (@{$al->{targetAl}[0]}){
		if ($sourceInGap{$j}){$sourceToNull{$j}=1}
	}

	@sortedSourceInGap = sort { $a <=> $b; } keys %sourceInGap;
	@sortedTargetInGap = sort { $a <=> $b; } keys %targetInGap;

#	print "source in gap 2:",join(" ",keys %sourceInGap)."\n";
#	print "target in gap 2:",join(" ",keys %targetInGap)."\n";
#	print "source sorted:",join(" ",@sortedSourceInGap)."\n";
#	print "target sorted:",join(" ",@sortedTargetInGap)."\n";
#	print "target to null:",join(" ",keys %targetToNull)."\n";
#	print "source to null:",join(" ",keys %sourceToNull)."\n";

	if (@sortedSourceInGap==0){
		$zeroSource=0;
		$numSource=0;
	}else{
		$zeroSource=$sortedSourceInGap[0]-1;
		$numSource=$sortedSourceInGap[@sortedSourceInGap-1]-$sortedSourceInGap[0]+1;
	}
	if (@sortedTargetInGap==0){
		$zeroTarget=0;
		$numTarget=0;
	}else{
		$zeroTarget=$sortedTargetInGap[0]-1;
		$numTarget=$sortedTargetInGap[@sortedTargetInGap-1]-$sortedTargetInGap[0]+1;
	}
	
	#Actualize AlignmentSlice attributes
	$gap->setZero($zeroSource,$zeroTarget);
	foreach $j (keys %sourceInGap){
		$gap->{sourceIndices}{$j-$zeroSource}=1;
	}
	if (scalar (keys %targetToNull)>0){$gap->{sourceIndices}{0}=1};	
	foreach $i (keys %targetInGap){
		$gap->{targetIndices}{$i-$zeroTarget}=1;	
	}
	if (scalar (keys %sourceToNull)>0){$gap->{targetIndices}{0}=1};	
	
#	print "zero s t:",$zeroSource," ",$zeroTarget,"\n";
#	print "num s t:",$numSource," ",$numTarget,"\n";

	## LOAD GAP
	# 1. insert NULL word and select only words linked to NULL that belong to the gap
	push @{$gap->{sourceWords}},'NULL';
	foreach $i (keys %targetToNull){push @linked,$i-$gap->{zeroTarget}}
	push @{$gap->{sourceAl}},[@linked];
	push @{$gap->{targetWords}},'NULL';
	@linked=();
	foreach $j (keys %sourceToNull){push @linked,$j-$gap->{zeroSource}}
	push @{$gap->{targetAl}},[@linked];
	# 2. Add non-NULL words and alignments
	for ($ind=1;$ind<=$numSource;$ind++){
		$j=$ind+$gap->{zeroSource};
		$gap->{sourceWords}[$ind]=$al->{sourceWords}[$j];
		if ($sourceInGap{$j}){
			@linked=();
			foreach $i (@{$al->{sourceAl}[$j]}){
				#if ($targetInGap{$i}){		#useless:de facto included in the zone
					push @linked,$i-$gap->{zeroTarget}
				#}
			}
			$gap->{sourceAl}[$ind]=[@linked];
		}
	}
	for ($ind=1;$ind<=$numTarget;$ind++){
		$i = $ind+$gap->{zeroTarget};
		$gap->{targetWords}[$ind]=$al->{targetWords}[$i];
		if ($targetInGap{$i}){
			@linked=();
			foreach $j (@{$al->{targetAl}[$i]}){
				#if ($sourceInGap{$j}) {	#useless:de facto included in the zone
					push @linked,$j-$gap->{zeroSource}
				#}
			}
			$gap->{targetAl}[$ind]=[@linked];
		}
	}
	return $gap;		
}

#####################################################
### PRIVATE SUBS                                  ###
#####################################################

# Returns the number of times the link ($ind1,$ind2) is present in the $side alignment
sub isIn {
	my ($al,$side,$ind1,$ind2) = @_;
	if ($side eq "sourceAl"){
		# returns >0 if the link (j,i) is present in sourceAl (ie if i_partOf_Bj), 0 otherwise
		my ($j,$i) = ($ind1,$ind2);
		my $i_partOf_Bj=grep /^$i$/, @{$al->{sourceAl}[$j]};
		return $i_partOf_Bj;
	}else{
		# returns >0 if the link (i,j) is present in targetAl (ie if j_partOf_Bi), 0 otherwise
		my ($i,$j)=($ind1,$ind2);
		my $j_partOf_Bi = grep /^$j$/, @{$al->{targetAl}[$i]};
		return $j_partOf_Bi;	
	}
}

# returns an object with same content as the input object
sub clone {
	my $al = shift;
	my $clone = Lingua::Alignment->new;	
	my ($i,$j);
	@{$clone->{sourceWords}}=@{$al->{sourceWords}};
	@{$clone->{targetWords}}=@{$al->{targetWords}};
	for ($j=0;$j<@{$al->{sourceAl}};$j++){
		if (defined($al->{sourceAl}[$j])){
			push @{$clone->{sourceAl}},[@{$al->{sourceAl}[$j]}];
		}
	}
	for ($i=0;$i<@{$al->{targetAl}};$i++){
		if (defined($al->{targetAl}[$i])){
			push @{$clone->{targetAl}},[@{$al->{targetAl}[$i]}];
		}
	}
	%{$clone->{sourceLinks}}=%{$al->{sourceLinks}};
	%{$clone->{targetLinks}}=%{$al->{targetLinks}};

	return $clone;
}
sub clear {
	my $al = shift;
	my ($i,$j);
	for ($j=0;$j<@{$al->{sourceAl}};$j++){
		if (defined($al->{sourceAl}[$j])){
			@{$al->{sourceAl}[$j]} = ();
		}
	}
	for ($i=0;$i<@{$al->{targetAl}};$i++){
		if (defined($al->{targetAl}[$i])){
			@{$al->{targetAl}[$i]} = ();
		}
	}
	%{$al->{sourceLinks}} = ();
	%{$al->{targetLinks}} = ();
}


# gets the alignment as clusters of positions aligned together
# input: $al, $direction ("source" for "sourceAl" or "target" for "targetAl")
sub getAlClusters {
    my ($al,$direction)=@_;
    #default:
    if (!defined($direction)){$direction="source"}	

    my $dumper = new Dumpvalue;
    # group many-to-many linked phrased in clusters
    my %scomp;  #stores in which cluster is each source word position
    my %tcomp;  
    my @clusters;
    my $alClusters={};
    my $numClusters=0;
    
    for (my $j=1;$j<@{$al->{$direction."Al"}};$j++){
	if (defined($al->{$direction."Al"}[$j])){
	    foreach my $i (@{$al->{$direction."Al"}[$j]}){
		if ($i>0){
#		print "j: $j i: $i\n";
		    if (exists($scomp{$j}) || exists($tcomp{$i})){
			my ($clustIndex1,$clustIndex2);
			if (exists($scomp{$j}) && exists($tcomp{$i})){
			    if ($tcomp{$i} != $scomp{$j}){
				# merge clusters:
				if ($scomp{$j}<$tcomp{$i}){
				    $clustIndex1=$scomp{$j};
				    $clustIndex2=$tcomp{$i};
				}else{
				    $clustIndex1=$tcomp{$i};
				    $clustIndex2=$scomp{$j};
				}
				#	    print "clusters: $clustIndex1 $clustIndex2 :\n";
				push @{$clusters[$clustIndex1]->{source}},@{$clusters[$clustIndex2]->{source}};
				push @{$clusters[$clustIndex1]->{target}},@{$clusters[$clustIndex2]->{target}};
				
				while ( my ($key,$val)=each (%scomp) ){
				    if ($val == $clustIndex2){$scomp{$key}=$clustIndex1;}
				    if ($val > $clustIndex2) {$scomp{$key}=$scomp{$key}-1;}
				}
				while ( my ($key,$val)=each (%tcomp) ){
				    if ($val == $clustIndex2){$tcomp{$key}=$clustIndex1;}
				    if ($val > $clustIndex2) {$tcomp{$key}=$tcomp{$key}-1;}
				}
				splice @clusters,$clustIndex2,1;
				$numClusters--;
			    }
			}elsif (exists($scomp{$j})){
			    $clustIndex1=$scomp{$j};
			    $tcomp{$i}=$clustIndex1;
			    push @{$clusters[$clustIndex1]->{target}},$i;
			}elsif (exists($tcomp{$i})){
			    $clustIndex1=$tcomp{$i};
			    $scomp{$j}=$clustIndex1;
			    push @{$clusters[$clustIndex1]->{source}},$j;
			}
		    }else{
			push @clusters,{source=>[$j],target=>[$i]};
			$scomp{$j}=$numClusters;
			$tcomp{$i}=$numClusters;
			$numClusters++;
		    }
		} #if $i>0
#		print "scomp:\n";
#	    print $dumper->dumpValue(\%scomp);
#		print "tcomp:\n";
#	    print $dumper->dumpValue(\%tcomp);
	    
#	    print $dumper->dumpValue(\@clusters);
	    }
	}
    }
    return \@clusters;
}

# prints a phrase given the side of alignment (source or target) and an array of positions of the phrase words
sub printPhrase {
    my ($al,$source,$posArray)=@_;
    my @words;
    foreach my $pos (@$posArray){
	push @words,$al->{$source."Words"}[$pos];
    }
    return join(" ",@words);
}

# SELECT ONLY S LINKS
sub SLinks {
    my $al=shift;
    my $sal = Lingua::Alignment->new;	
    @{$sal->{sourceWords}}=@{$al->{sourceWords}};
    @{$sal->{targetWords}}=@{$al->{targetWords}};

    my %side=("source"=>"target","target"=>"source");
    while (my ($source,$target)= each(%side)){
	for (my $j=0;$j<@{$al->{$source."Al"}};$j++){
	    push @{$sal->{$source."Al"}},[];
	    if (defined($al->{$source."Al"}[$j])){
		foreach my $i (@{$al->{$source."Al"}[$j]}){
		    if ($al->{$source."Links"}->{$j." ".$i}[0] ne "p" && $al->{$source."Links"}->{$j." ".$i}[0] ne "P"){
			push @{$sal->{$source."Al"}[$j]},$i;
		    }
		}
	    }
	}
    }
    return $sal;
}


1;
