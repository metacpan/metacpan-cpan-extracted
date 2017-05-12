
########################################################################
# Author:  Patrik Lambert (lambert@talp.ucp.es)
# Description: Provides method to cut and process a part of an alignment
#   in a sentence pair.
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

package Lingua::AlignmentSlice;
@ISA = ("Lingua::Alignment"); # Inherits from Alignment

use strict;
use Lingua::AlSetLib;
use Dumpvalue;

#a slice or fraction of an Alignment object:
#inherits from an Alignment object
#zero is the point where to insert the slice in the father alignment
#indices are the token indices that really contain information in the slice. Only paste those ones.
#sub new2 {
#	my ($pkg,$al) = @_;
#	my $this = $pkg->Lingua::Alignment::new();

#	$this->{father}=$al;
#	$this->{zeroSource}=0;
#	$this->{zeroTarget}=0;
#	$this->{sourceIndices}={};
#	$this->{targetIndices}={};
#    return $this;    
#}

sub new {
	my ($pkg,$al) = @_;
	my $this = Lingua::Alignment->new();

	$this->{father}=$al;
	$this->{zeroSource}=0;
	$this->{zeroTarget}=0;
	$this->{sourceIndices}={};
	$this->{targetIndices}={};
    return bless $this,$pkg;    
}

sub setZero {
	my ($this,$zeroSource,$zeroTarget)=@_;
	$this->{zeroSource}=$zeroSource;
	$this->{zeroTarget}=$zeroTarget;
}

sub paste {
	my ($this,$al)=@_;
	if (!defined($al)){$al=$this->{father}}
	my %side=("source"=>"target","target"=>"source");
	my ($j,$i,$idx);
	my ($al_j,$al_i);
	my ($length,$side,$Side,$reverseSide,$ReverseSide);
	my @nullNotIn;
	my @nullIn;

#	print "slice to paste:\n";
#	main::dumpValue($this);
	while (($side,$reverseSide)= each(%side)){		
#		print "PASTE:$side\n";
#		print "ANTES DE PROCESAR NULL:\n";
#		main::dumpValue($al->{$side."Al"});
#		print "PROCESS NULL...\n";
		$Side=ucfirst($side);
		$ReverseSide=ucfirst($reverseSide);
	# 1 process NULL links
		if ($this->{$side."Indices"}{0}){
			$length=@{$al->{$side."Al"}[0]};
			#list links to null of the indices not included in perturbation
			@nullNotIn=();
			@nullIn=();
			foreach $i (@{$al->{$side."Al"}[0]}){
#				print "zero $ReverseSide:".$this->{"zero".$ReverseSide}."  i:$i\n";
				if (!$this->{$reverseSide."Indices"}{$i-$this->{"zero".$ReverseSide}}){
					push @nullNotIn,$i;
				}
			}
			#replace the other ones (those included in the perturbation) by their alignemnent in the perturbation
			@{$al->{$side."Al"}[0]}=@nullNotIn;
			foreach $i (@{$this->{$side."Al"}[0]}){
				push @{$al->{$side."Al"}[0]},$i+$this->{"zero".$ReverseSide};	
			}
#			print "null not in:",join(" ",@nullNotIn),"\n";
		}
#		print "DESPUÉS DE PROCESAR NULL:\n";
#		main::dumpValue($al->{$side."Al"});
#		print "PROCESS NO NULL...\n";

	# 2 process NO-null links
		foreach $j (keys %{$this->{$side."Indices"}}){
			if ($j>0){
				$al_j = $j+$this->{"zero".$Side};
				# if $j is in the perturbation all indices linked to it are also, 
				# so we can replace the entire array by that of the perturation:
				$al->{$side."Al"}[$al_j]=[]; 
				foreach $i (@{$this->{$side."Al"}[$j]}){
					if ($i>0){
						$al_i = $i+$this->{"zero".$ReverseSide};
					}else{
						$al_i = 0;	
					}
#					print "j i:$j $i->push $side.Al[$al_j],$al_i\n"; 
					push @{$al->{$side."Al"}[$al_j]},$al_i;	
				}
			}
		} #foreach $j...	
#		print "DESPUÉS DE PROCESAR NO NULL:\n";
#		main::dumpValue($al->{$side."Al"});
	} #while
}

sub clone {
	my $this = shift;
	my $clone = $this->Lingua::Alignment::clone();

	$clone->{father}=$this->{father};
	$clone->{zeroSource}=$this->{zeroSource};
	$clone->{zeroTarget}=$this->{zeroTarget};
	$clone->{sourceIndices}=$this->{sourceIndices};
	$clone->{targetIndices}=$this->{targetIndices};
	
	return bless $clone,"Lingua::AlignmentSlice";
}
##############################################################################
### SYMMETRIZATION SUBS (make sense only for GIZA type alignments)         ###
##############################################################################                        

sub sparse{
	my ($alSlice,$side) = @_;
	
	return ( (@{$alSlice->{$side."Words"}}-scalar(keys %{$alSlice->{$side."Indices"}}))>3 );
}
# SYMMETRIZATION RULE FUNCTION:	
# input: AlignmentSlice object (modAl)
# action: modAl is corrected by application of the rule, to symAl are added new symmetric links and al remains unchanged
# returns the number of applications of the rule in alignment
sub applyOneToMany_1 {
	my ($alSlice) = @_;
	my %side=("source","target","target","source");
	my ($source,$target);
	my ($j,$i,$k);
	my $ruleApplicationNb=0;
	my %candidate;
	my $failed = 0;

	for (($source,$target)= each (%side)){	
		for ($j=0; $j<@{$alSlice->{$source."Al"}};$j++){
			#select the $j's linked to various $i's
			if (defined($j)){
				if (@{$alSlice->{$source."Al"}[$j]}>1){
					($failed,$k) = (0,0);
					%candidate=();
					# for each $i linked to $j we look if the reverse link exists in targetAl and if $i is not linked to another source word
					while (!$failed && $k<@{$alSlice->{$source."Al"}[$j]}){
						$i = $alSlice->{$source."Al"}->[$j][$k];
						if (@{$alSlice->{$target."Al"}[$i]}==1 && $alSlice->{$target."Al"}->[$i][0]==$j){
							$candidate{$i} = 1;	
						}elsif (@{$alSlice->{$target."Al"}[$i]}>=1){	#$i is linked to some $j', $j' different from $j
							$failed = 1;
						}
						$k++;	
					}
					# if the conditions are present, we apply the rule
					if (!$failed && %candidate>0){
						foreach $i (@{$alSlice->{$source."Al"}[$j]}){
							#indicate modified word:
	#						${$modAl->{$target."Words"}}[$i]='#'.${$modAl->{$target."Words"}}[$i].'#';	
	#						${$symAl->{$target."Words"}}[$i]='#'.${$symAl->{$target."Words"}}[$i].'#';	
							if (! $candidate{$i}){
	#							push @{$modAl->{$target."Al"}[$i]},$j;
	#							push @{$symAl->{$target."Al"}[$i]},$j; 	
	#							push @{$symAl->{$source."Al"}[$j]},$i; 	
							}else{
								$ruleApplicationNb++;	
								#indicate modified word:
	#							${$modAl->{$source."Words"}}[$j]='#'.${$modAl->{$source."Words"}}[$j].'#';	
	#							${$symAl->{$source."Words"}}[$j]='#'.${$symAl->{$source."Words"}}[$j].'#';	
							}
						}	
					}
				} #if
			}
		} #for
	}	#for source,target
	return $ruleApplicationNb;		
}

#look for source|target tokens aligned with every target|source index in the slice
sub applyOneToMany_2 {
	my ($alSlice) = @_;
	my %side=("source"=>"target","target"=>"source");
	my ($source,$target);
	my ($j,$i,$k);
	my $ruleApplicationNb=0;
	my @candidate;
	my $failed;
	my @toModify = ();

	while (($source,$target)= each %side){
#		print "\n$source $target :\n";
		if (@toModify==0){
			#1 select the $j's linked to all $i's
			#  we want only one $j in this situation so sourceAl==2
			#  we eliminate situations where $j is linked to two $i's situated very far apart (ie: indices<<words)
			if (@{$alSlice->{$source."Al"}}==2 && @{$alSlice->{$source."Al"}[0]}==0 && (@{$alSlice->{$target."Words"}}-scalar(keys %{$alSlice->{$target."Indices"}}))<4){
				$j=1;
#				print "al:",join(" ",@{$alSlice->{$source."Al"}[$j]})." indices:",join(" ",keys %{$alSlice->{$target."Indices"}}),"\n";
				if ( @{$alSlice->{$source."Al"}[$j]}==scalar(keys %{$alSlice->{$target."Indices"}}) ){
					#2 check there is one $i with reverse link to $j (from Giza constraint there can be only one) and no $i linked to other word
					@candidate=();
					$failed=0;
					while (!$failed && $k<@{$alSlice->{$source."Al"}[$j]}){
						$i = $alSlice->{$source."Al"}->[$j][$k];
						# $i can only be aligned to $j or not linked
						if (@{$alSlice->{$target."Al"}[$i]}==1 && $alSlice->{$target."Al"}->[$i][0]==$j){
#							print "	1st class\n";
							$candidate[0]=$i;	
						}else{	#$i is linked to nothing
#							print "	modify $i\n";
							push @toModify,$i;
						}
						$k++;	
					}
				}	# if
			} 	#for $j...
			if (@candidate>0){	
				foreach $i (@toModify){
					push @{$alSlice->{$target."Al"}[$i]},$j;
					$ruleApplicationNb=1;	
				}
			}
		} #if @toModify==0
	} #while source,target
	return $ruleApplicationNb;		
}

sub selectSubgroups {
    my ($alSlice,$groups,$subGroups,$globals) = @_;
    my $sourceSize = @{$alSlice->{sourceWords}}-1;
    my $targetSize = @{$alSlice->{targetWords}}-1;
    my ($side,$k,$minK,$j,$i,$group,$subGroup,$count,$numWords);
    my ($sourceCandidate,$targetCandidate);
    my %candidates = ("source",[],"target",[]);
    my %subCandidates = ("source",[],"target",[]);
    my @allWords;
    my @words;
    my $dumper=new Dumpvalue;
    if ($sourceSize >0 && $targetSize >0 && ($sourceSize>1 || $targetSize>1) && !$alSlice->sparse("source") && !$alSlice->sparse("target")){
	#select frases contains in the group
	foreach $side (("source","target")){
	    # push group candidates	
	    @allWords = @{$alSlice->{$side."Words"}};
	    shift @allWords;
	    #prepare group to be splitted between punctuation, for subGroups hash
	    $group=join(" ",@allWords)." ";			
	    $group =~ s/([¡¿!\?\.,;:] )+/$1/g;
	    @allWords = split /[¡¿!\?\.,;:] /g,$group;
	    # remove puntuation to put it in group hash:
	    $group =~ s/[¡¿!\?\.,;:] //g;
	    $group =~ s/\s+$//g;
	    
	    push @{$candidates{$side}},$group;

	    if ($globals->{onlyGroups}==0){
		foreach $group (@allWords){
		    $group =~ s/\s+$//;
#				print "group:$group:\n";
		    @words = split / /,$group;
		    $numWords = scalar(@words);
		    #push subgroup candidates
		    if ($numWords<3){$minK=1}
		    elsif($numWords<5){$minK=2}
		    else{$minK=2};
#				print "minK:$minK numWords:$numWords\n";
		    for ($k=$minK;$k<=$numWords;$k++){
			for ($j=0;$j<$numWords-$k+1;$j++){
			    @words = split / /,$group;
			    $subGroup = join(" ",splice @words,$j,$k);
			    push @{$subCandidates{$side}},$subGroup;
#						print "	subGroup:$subGroup\n";
			}
		    }
		} #foreach $candidate (@allWords)
		foreach $sourceCandidate (@{$subCandidates{source}}){
		    foreach $targetCandidate (@{$subCandidates{target}}){
#				print "$sourceCandidate -- $targetCandidate\n";
			$subGroups->{"$sourceCandidate | $targetCandidate"}=1;
		    }
		}
	    }		
	    foreach $sourceCandidate (@{$candidates{source}}){
		foreach $targetCandidate (@{$candidates{target}}){
		    # number of words may change after filtering punctuation:
		    $sourceSize=scalar(split / /,$sourceCandidate);
		    $targetSize=scalar(split / /,$targetCandidate);
		    if ($sourceSize >0 && $targetSize >0 && ($sourceSize>1 || $targetSize>1)){
			$groups->{"$sourceCandidate | $targetCandidate"}=1;
		    }
		}
	    }
	}
    }
    return ($groups,$subGroups);
}

sub applyGrouping {
    my ($alSlice,$groupKeys,$subGroupKeys,$globals) = @_;
    my $myGroupKeys=$groupKeys;
    my $sourceSize = @{$alSlice->{sourceWords}};
    my $targetSize = @{$alSlice->{targetWords}};
    my ($side,$reverseSide,$k,$minK,$j,$i,$idx,$interPunctuationIdx,$pushed,$candidate,$refToCand,$word);
    my %side=("source"=>"target","target"=>"source");
    my ($refToSourceCand,$sourceCandidate,$refToTargetCand,$targetCandidate,$bestMatch);
    my %candidates;
    my %cands;
    my %targetCands;
    my @allWords;
    my @words;
    my ($regExp,$num,$match,$numMatches);
    my @matches;
    my ($nscan,$modifications,$modified)=(0,1,0);
    my %toProcess;
    my ($numSourceIndicesToProcess,$numTargetIndicesToProcess);
    my ($first_j,$first_i); 
    my @sourceCandidateTokens;
    my @targetCandidateTokens;
    my %crossLinksPatterns;
    my $clone=$alSlice->clone();
    my $lastChance=0;
    my @grepMatch;
    my %grepMatches;
    my $dumper = new Dumpvalue;
    my $verbose = $globals->{verbose};

    if ($sourceSize >1 && $targetSize >1 && !$alSlice->sparse("source") && !$alSlice->sparse("target")){
	my $defaultActionGrouping=$globals->{defaultActionGrouping};
	$alSlice->$defaultActionGrouping();
	#once you have the intersection, it's easy to list the reciprocal links
	$clone->intersect();
	for ($j=0;$j<@{$clone->{sourceAl}};$j++){
	    if (defined($clone->{sourceAl}[$j])){
		foreach $i (@{$clone->{sourceAl}[$j]}){
		    $crossLinksPatterns{$clone->{sourceWords}[$j].'.*\|.*'.$clone->{targetWords}[$i]}=1;	
		}
	    }	
	}
	if ($verbose > 1){
	    print $alSlice->sourceSentence." | ".$alSlice->targetSentence."\n";
	    if ($verbose > 2){
		print "recip links:\n";
		print $dumper->dumpValue(\%crossLinksPatterns);
	    }
	}
	$toProcess{sourceIndices}={%{$alSlice->{sourceIndices}}};
	$toProcess{targetIndices}={%{$alSlice->{targetIndices}}};
	delete($toProcess{sourceIndices}{0});
	delete($toProcess{targetIndices}{0});
	$toProcess{sourceWords}=[@{$alSlice->{sourceWords}}];
	$toProcess{targetWords}=[@{$alSlice->{targetWords}}];
	shift @{$toProcess{sourceWords}};	#remove NULL word
	shift @{$toProcess{targetWords}};
	$toProcess{sourceWordPos}=[1..scalar(@{$toProcess{sourceWords}})];
	$toProcess{targetWordPos}=[1..scalar(@{$toProcess{targetWords}})];		
	$numSourceIndicesToProcess = scalar(keys %{$toProcess{sourceIndices}});
	$numTargetIndicesToProcess = scalar(keys %{$toProcess{targetIndices}});
	
	while ( $numSourceIndicesToProcess>0 && $numTargetIndicesToProcess>0 ){
#	    print "s words:",join(" ",@{$toProcess{sourceWords}})," - t words:",join(" ",@{$toProcess{targetWords}}),"\n";
#	    print "ind to process s:",join(" ",keys %{$toProcess{sourceIndices}})," - target:",join(" ",keys %{$toProcess{targetIndices}}),"\n";
		# IF FAILED RETURN	
	    if (!$lastChance && !$modifications){
		$lastChance=1;
		if ($globals->{onlyGroups}==1){
		    return -1;
		}
	    }
	    %grepMatches=();
#			print "$nscan: myGroupKeys:$myGroupKeys lastChance:$lastChance\n";
	    %candidates = ("source",[],"target",[]);
	    
	    # SELECT FRASES CONTAINED IN THE GROUP (if the number of indices is different (ie modifications==1)
	    if ($nscan==0 || $modifications){
		while (($side,$reverseSide)=each %side){
		    #target words
		    $targetCands{$side} = " |".join("|",@{$toProcess{$reverseSide."Words"}});
		    $targetCands{$side} =~ s/\|[\(\)\?¿!¡\.,]//g;	#remove punctuation marks
		    $targetCands{$side} =~ s/([\\\(\)\[\{\^\$\*\+\?\.])/\\$1/g; #escape special characters
		    if ($verbose > 2){print "targetCands $side:$targetCands{$side}\n";}
		    #source group candidates
		    @allWords=();
		    @{$allWords[0]}=();
		    $interPunctuationIdx = 0;
		    for ($idx=0;$idx<@{$toProcess{$side."Words"}};$idx++){
			if ($toProcess{$side."Words"}[$idx]=~/[\(\)\?¿!¡\.,]/ || !$alSlice->{$side."Indices"}{$toProcess{$side."WordPos"}[$idx]}){
#						if ($toProcess{$side."Words"}[$idx]=~/[\(\)\?¿!¡\.,]/){
			    unless ($idx==0 ||$idx==@{$toProcess{$side."Words"}}-1 || $pushed==0){
				$interPunctuationIdx++;
				$pushed=0;
			    }
			}else{
			    push @{$allWords[$interPunctuationIdx]},{"pos" => $toProcess{$side."WordPos"}[$idx],"txt" => $toProcess{$side."Words"}[$idx]};
			    $pushed=1;
			}
		    }
		    @{$cands{$side}}=();
		    for ($interPunctuationIdx=0;$interPunctuationIdx<@allWords;$interPunctuationIdx++){
			if (scalar(keys %{$toProcess{$side."Indices"}})<4){$minK=1}
			elsif(scalar(keys %{$toProcess{$side."Indices"}})<5){$minK=2}
			else{$minK=3};
			#select subgroups for grouping candidates
			for ($k=$minK;$k<=@{$allWords[$interPunctuationIdx]} && $k<7;$k++){
			    for ($j=0;$j<=@{$allWords[$interPunctuationIdx]}-$k;$j++){
				@words=@{$allWords[$interPunctuationIdx]};
				# substitute words not in slice indices by "blank" (ie '[^ ]?')
#				for ($idx=0;$idx<@words;$idx++){
#			            if (!$alSlice->{$side."Indices"}{$words[$idx]->{pos}}){
#				       $words[$idx]->{txt} ='[^ ]+';
#				    }  
#				}
				push @{$cands{$side}},[splice @words,$j,$k];
#								print " -j:$j -k:$k -s words to process:",@{$toProcess{$side."Words"}}-$k,"\n";
								#if split 3 in 1-2 or 5 in 2-3 for instance put left-over as candidate:
				if (@words>0 && @words<$minK && ( $j==0 || $j==@{$allWords[$interPunctuationIdx]}-$k)){
				    push @{$cands{$side}},[@words];
				}
			    }
			}
		    }
		}#foreach side
		}#if modifications
			
#			print "targetCands source:",$targetCands{source},"\n";
#			print "targetCands target:",$targetCands{target},"\n";
			
		# FILTER POSSIBLE CANDIDATES
		foreach $side (("source","target")){
		    foreach $refToCand (@{$cands{$side}}){
			$candidate = printGroup($refToCand);
			if ($candidate !~ /^(\[\^ \]\+ ?)+$/){
			    $candidate =~ s/(\[\^ \]\+ )/\($1\){0,1}/g;
			    $candidate =~ s/( \[\^ \]\+)/\($1\){0,1}/g;
			    $candidate =~ s/([\\\(\)\[\{\^\$\*\+\?\.])/\\$1/g; #escape special characters 
			    
			    if ($verbose>2){
				print "cand: $candidate\n";
			    }
			    if ($side eq "source"){
				if (!$lastChance){
				    $regExp = '^\d+ \| '.$candidate.' \| ('.$targetCands{$side}.')+$';
				}else{
				    $regExp = $candidate.'.*\|.*('.$targetCands{$side}.')+';	
					}
			    }else{
				if (!$lastChance){
				    $regExp = '^\d+ \| ('.$targetCands{$side}.')+ \| '.$candidate.'$';
				}else{
				    $regExp = '('.$targetCands{$side}.')+.*\|.*'.$candidate;	
				}
			    }
			    $regExp =~ s/\?/\\\?/g;
			    if ($verbose > 2){print "$regExp\n";}
			    @grepMatch = grep(/$regExp/,@$myGroupKeys); 
			    if (@grepMatch>0){
				push @{$candidates{$side}},$refToCand;
				foreach $match (@grepMatch){
					    $grepMatches{$match}=1;
					}
			    }
			}
		    } #foreach @cands
			    
		    foreach $refToCand (@{$candidates{$side}}){
			$candidate= printGroup($refToCand);
#					print "	",$candidate."\n";
		    }
		} #foreach $side
	    @matches=();
	    
	    # CROSS POSSIBLE CANDIDATES AND IF THEY MATCH PUSH INTO @MATCHES
	    foreach $refToSourceCand (@{$candidates{source}}){
		foreach $refToTargetCand (@{$candidates{target}}){
		    $sourceCandidate=printGroup($refToSourceCand);
		    $targetCandidate=printGroup($refToTargetCand);
		    if ($verbose > 2){
			print "s t:$sourceCandidate - $targetCandidate		indices: s $numSourceIndicesToProcess -t $numTargetIndicesToProcess\n";
		    }
		    # for subGroupKeys, eliminate candidates with one word each side, except if they are the only words to process
		    if (!$lastChance){
			$regExp = '^\d+ \| '.$sourceCandidate.' \| '.$targetCandidate.'$';
		    }else{
			$regExp = ' '.$sourceCandidate.' .*\|.* '.$targetCandidate;
		    }				
#					print "$regExp\n";
		    @grepMatch= grep(/$regExp/,keys %grepMatches);						
		    if (@grepMatch>0){
			$numMatches=0;
			foreach $match (@grepMatch){
#								print "		$match\n";
			    ($num)=split(" \\| ",$match);
			    $numMatches+=$num;
			}
#							print "numMatches:$numMatches\n";
			push @matches, [$numMatches,[@$refToSourceCand],[@$refToTargetCand]];
		    }
		}
	    }
	    if ($verbose>2){
		print "MATCHES:\n";
		print $dumper->dumpValue(\@matches);
	    }
		# ANALYSE AND COMBINES MATCHES TO SELECT THE BEST MATCH
	    if (@matches ==0){
		$modifications=0;
		if ($lastChance){
		    if ($modified){return $modified}
		    else {return -1};	
		}
	    }else{
		$modifications=1;
		if (@matches ==1){
		    $bestMatch=@matches[0];	
		}else {
		    if ($lastChance){
			$bestMatch=searchBestSubGroupMatch(\@matches,\%crossLinksPatterns);	
		    }else{
			$bestMatch=searchBestGroupMatch(\@matches,$verbose);	
		    }
		} #if @matches==1
		($num,$refToSourceCand,$refToTargetCand)=@$bestMatch;
		if ($verbose>0){
		    print "***bestMatch:",printGroup($refToSourceCand),"--",printGroup($refToTargetCand),"\n";
		}
		#apply grouping:
		#see if there is something left to process for the next step:
		for ($j=0;$j<@{$toProcess{sourceWordPos}};$j++){
		    if ($toProcess{sourceWordPos}[$j]==$refToSourceCand->[0]{pos}){
			$first_j=$j;
			last;
		    }
		}
		for ($i=0;$i<@{$toProcess{targetWordPos}};$i++){
		    if ($toProcess{targetWordPos}[$i]==$refToTargetCand->[0]{pos}){
			$first_i=$i;
			last;
		    }
		}
		
#				print "sourceWords:",join(" ",@{$toProcess{sourceWords}})," -splice: ",$first_j,",",scalar(@$refToSourceCand),"\n";
#				print "targetWords:",join(" ",@{$toProcess{targetWords}})," -splice: ",$first_i,",",scalar(@$refToTargetCand),"\n";
		splice @{$toProcess{sourceWords}},$first_j,scalar(@$refToSourceCand);
		splice @{$toProcess{sourceWordPos}},$first_j,scalar(@$refToSourceCand);
		splice @{$toProcess{targetWords}},$first_i,scalar(@$refToTargetCand);
		splice @{$toProcess{targetWordPos}},$first_i,scalar(@$refToTargetCand);
#				print "s wordPos:",join(" ",@{$toProcess{sourceWordPos}}),"\n";
#				print "t wordPos:",join(" ",@{$toProcess{targetWordPos}}),"\n";
		for ($j=$refToSourceCand->[0]{pos};$j<=$refToSourceCand->[@$refToSourceCand-1]{pos};$j++){
		    delete $toProcess{sourceIndices}{$j};
		}
#				print "\nsourceWords 2:",join(" ",@{$toProcess{sourceWords}}),"\n";
		for ($i=$refToTargetCand->[0]{pos};$i<=$refToTargetCand->[@$refToTargetCand-1]{pos};$i++){
		    delete $toProcess{targetIndices}{$i};
		}
#				print "targetWords 2:",join(" ",@{$toProcess{targetWords}}),"\n";
		$numSourceIndicesToProcess = scalar(keys %{$toProcess{sourceIndices}});
		$numTargetIndicesToProcess = scalar(keys %{$toProcess{targetIndices}});

		$alSlice->group($refToSourceCand,$refToTargetCand,$globals->{extendGroups});
#				print "modifs:".$modifications."\n";
		if ($modifications>0){
		    $modified=1;	
		}
	    } #if @matches==0 else
	    $nscan++;
#			print "modif:$modifications\n";
#			print "sourceInd:",scalar(keys %{$toProcess{sourceIndices}}),"\n";
#			print "targetInd:",scalar(keys %{$toProcess{targetIndices}}),"\n";
			
	} #while no changes and areas to cover
	return 1;				
    } 	#general if
    return 0;
}

sub printGroup{
    my $refToGroup = shift;
    my $candidate="";
    my $word;
    foreach $word (@$refToGroup){
	$candidate=$candidate." ".$word->{txt};
    }
    $candidate =~ s/^ //;
    return $candidate;	
}

sub searchBestGroupMatch{
    my $matches = shift;
    my $verbose = shift;
    my @matchNums = ();
    my ($match,$idx,$length);
    my ($minMatch,$maxMatch);
    my @bestCandidates;
    my %maxLength;
    
    foreach $match (@$matches){
	if ($verbose>1){
	    print $match->[0];
	}
	push @matchNums,$match->[0];	
    }
    ($minMatch,$maxMatch) = Lingua::AlSetLib::minmax( \@matchNums );
    @bestCandidates = ();
    foreach $match (@$matches){
	if ($match->[0]==$maxMatch){
	    push @bestCandidates,$match;
	}	
    }
    if (@bestCandidates>1){
	$maxLength{"length"}=0;
	for ($idx=0;$idx<@bestCandidates;$idx++){
	    $length = @{$bestCandidates[$idx]->[1]}+@{$bestCandidates[$idx]->[2]};
#			print "len:$length\n";
	    if ($length>$maxLength{"length"}){
		$maxLength{"idx"}=$idx;
		$maxLength{"length"}=$length;
	    }
	}
	$bestCandidates[0]=$bestCandidates[$maxLength{"idx"}];	
    }
    return $bestCandidates[0];	
}

sub searchBestSubGroupMatch{
    my ($matches,$crossLinkedWords) = @_;
    my %matchNums = ();
    my @sortedMatchNums;
    my ($match,$idx,$k,$length,$maxMatch);
    my $thisOneWithCross=0;
    
    my @bestCandidates;
    my @finalBest;
    my @candsWithoutCrossLink;
    my @candsWithCrossLink;
    my @currentWithoutCrossLink;
    my $regExp;
    
    # sort all matchcounts retrieved:
    foreach $match (@$matches){
	$matchNums{$match->[0]}=1;	
    }
    @sortedMatchNums=reverse (sort { $a <=> $b; } keys %matchNums);
#	print "\nMATCHNUMS: ",join(" ",@sortedMatchNums),"\n\n";	

    for ($idx=0;$idx<@sortedMatchNums && $idx<2;$idx++){
	#list matches of current matchcount
	@bestCandidates = ();
	@currentWithoutCrossLink=();
	foreach $match (@$matches){
	    if ($match->[0]==$sortedMatchNums[$idx]){
		push @bestCandidates,$match;
	    }	
	}
	foreach $match (@bestCandidates){
#			print "		$match:",printGroup($match->[1]),"--",printGroup($match->[2]),"\n";
	    #look if contains cross link
	    $thisOneWithCross=0;
	    foreach $regExp (keys %$crossLinkedWords){
		if ((printGroup($match->[1]).' | '.printGroup($match->[2]))=~/$regExp/){
#					print "$regExp --> $match\n";
		    $thisOneWithCross++;	
		    last;	
		}	
	    }
	    if ($thisOneWithCross){
		push @candsWithCrossLink,$match;
	    }else{
		push @currentWithoutCrossLink,$match;
	    }
	}
	if (@candsWithCrossLink>0){
	    last;
	}else{
	    push @{$candsWithoutCrossLink[$idx]},@currentWithoutCrossLink;
	}
    }
    for ($idx=0;$idx<@candsWithoutCrossLink;$idx++){
	foreach $match (@{$candsWithoutCrossLink[$idx]}){
#			print "$idx without		match:",printGroup($match->[1]),"--",printGroup($match->[2]),"\n";
	}	
    }
    foreach $match (@candsWithCrossLink){
#		print "with		match:",printGroup($match->[1]),"--",printGroup($match->[2]),"\n";
    }	
    if (@candsWithCrossLink>0){
	push @finalBest,clusterGroups(\@candsWithCrossLink);
	if ($idx>0 && @candsWithoutCrossLink>0){
	    push @finalBest,clusterGroups($candsWithoutCrossLink[0]);
	}		
    }else{
	for ($k=0;$k<@candsWithoutCrossLink;$k++){
	    push @finalBest,clusterGroups($candsWithoutCrossLink[$k]);
	}
    }
#	print "num finals:",scalar(@finalBest),"\n";
    return clusterGroups(\@finalBest); 		
}

sub clusterGroups{
    my $groups = shift;
    my ($match,$group,$word,$k,$idx,$l);
    my %clusterPositions;
    my %isInCluster;
    my %cluster;
    my @right;
    
    #1.Search positions included in cluster, in each side. Start with first match in group.
    foreach $k (1,2){
	foreach $word (@{$groups->[0][$k]}){
	    $clusterPositions{$k}{$word->{pos}}=1;			
	}
    }
    for ($idx=1;$idx<@$groups;$idx++){
	%isInCluster=();
	foreach $k (1,2){
	    foreach $word (@{$groups->[$idx][$k]}){
		if ($clusterPositions{$k}{$word->{pos}}){
		    $isInCluster{$k}=1;
		    last;
		}	
	    }
	}
	if ( $isInCluster{1} || $isInCluster{2} ){
	    foreach $k (1,2){
		foreach $word (@{$groups->[$idx][$k]}){
		    $clusterPositions{$k}{$word->{pos}}=1;
		}
	    }
	}
    } #for $idx
    
    #2. Build cluster
    foreach $k (1,2){
	foreach $word (@{$groups->[0][$k]}){ #we started with first match in group.
	    push @{$cluster{$k}},$word;
	    delete($clusterPositions{$k}->{$word->{pos}});	
	}
	for ($idx=1;$idx<@$groups && scalar(keys %{$clusterPositions{$k}})>0;$idx++){
	    $group=$groups->[$idx][$k];
	    foreach $word (@$group){
		if ($clusterPositions{$k}{$word->{pos}}){
		    #insert in cluster
		    for ($l=0;$l<@{$cluster{$k}};$l++){
			if ($cluster{$k}->[$l]{pos}>$word->{pos}){
			    last;	
			}
		    }
		    @right=splice @{$cluster{$k}},$l;
		    @{$cluster{$k}}=(@{$cluster{$k}},$word,@right);
		    #delete key
		    delete($clusterPositions{$k}->{$word->{pos}});	
		}	
	    }
	} #for each group to cluster
    } #foreach $k (source,target)
    return [$groups->[0][0],$cluster{1},$cluster{2}];
}

sub group{
    my ($alSlice,$refToSourceCand,$refToTargetCand,$extendGroup) = @_;
    my ($j,$i);
    my $nLinks=0;
    my $first_j=$refToSourceCand->[0]{pos};
    my $last_j=$first_j+@$refToSourceCand-1;
    my $first_i=$refToTargetCand->[0]{pos};
    my $last_i=$first_i+@$refToTargetCand-1;
    my @sourceExtensions;
    my @targetExtensions;
    my ($minMatch,$maxMatch);
    
    if ($extendGroup==1){
	#first we extend the group to cross links aligned with some member of the group
	for ($j=1;$j<@{$alSlice->{sourceAl}};$j++){
	    if (defined($alSlice->{sourceAl}[$j]) && @{$alSlice->{sourceAl}[$j]}>0 && ($j<$first_j || $j>$last_j)){
		for ($i=$first_i;$i<=$last_i;$i++){
		    if ($alSlice->isCrossLink($j,$i)){
			if ($j<$first_j){$first_j=$j}
			if ($j>$last_j){$last_j=$j}
		    }
		}
	    }
	}
	for ($i=1;$i<@{$alSlice->{targetAl}};$i++){
	    if (defined($alSlice->{targetAl}[$i]) && @{$alSlice->{targetAl}[$i]}>0 && ($i<$first_i || $i>$last_i)){
		for ($j=$first_j;$j<=$last_j;$j++){
		    if ($alSlice->isCrossLink($j,$i)){
			if ($i<$first_i){$first_i=$i}
			if ($i>$last_i){$last_i=$i}
		    }
		}
	    }
	}
    }
    #then we group
    for ($j=$first_j;$j<=$last_j;$j++){
	for ($i=$first_i;$i<=$last_i;$i++){
	    if ($alSlice->{sourceIndices}->{$j} && $alSlice->{targetIndices}->{$i}){
		if (!$alSlice->isIn("sourceAl",$j,$i)){
		    push @{$alSlice->{sourceAl}[$j]},$i;	
		    $nLinks++;
		}	
		if (!$alSlice->isIn("targetAl",$i,$j)){
		    push @{$alSlice->{targetAl}[$i]},$j;	
		    $nLinks++;
		}
	    } 	
	} #for
    } #for
    return $nLinks;
}

sub processNull {
	my $this=shift;
	
		
}
1;
