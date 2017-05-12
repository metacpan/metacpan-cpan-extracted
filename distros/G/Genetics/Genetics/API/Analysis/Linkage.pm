# GenPerl module 
#

# POD documentation - main docs before the code

=head1 NAME

Genetics::API::Analysis::Linkage

=head1 SYNOPSIS

  # The following code runs a full Genehunter genome scan using two different 
  # disease models:
  use Genetics::API ;

  $api = new Genetics::API(DSN => {driver => "mysql",
				   host => $Host,
				   database => $Database},
                           user => $UserName,
                           password => $Password) ;

  # Kindreds
  $kindredCluster = $api->getObject({TYPE => "Cluster", 
	         		     NAME => "Bpall two generations"}) ;
  @kindreds = $api->getClusterContents($kindredCluster, 1) ;
  # Allele FrequencySource:
  $bpall = $api->getObject({TYPE => "Cluster", NAME => "Bpall"}) ;
  # StudyVariables:
  $bp = $api->getObject({TYPE => "StudyVariable", NAME => "BP"}) ;
  $bpup = $api->getObject({TYPE => "StudyVariable", NAME => "BPUP"}) ;
  @studyVars = ($bp, $bpup) ;
  $lcd = $api->getObject({TYPE => "StudyVariable", NAME => "AoO Dom LC"}) ;

  @chromosomes = qw(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 XY) ;
  foreach $chr (@chromosomes) {
    $markerCluster = $api->getObject({TYPE => "Cluster", 
	 			      NAME => "Chr$chr Markers"}) ;
    @markers = $api->getClusterContents($markerCluster, 1) ;
    $map = $api->getObject({TYPE => "Map", 
			    NAME => "Marshfield Chr$chr Map"}) ;
  
    foreach $sv (@studyVars) {
      $svName = $sv->name() ;
      $runName = $chr . $svName ;
      $api->runGenehunter(
		  	KINDREDS => \@kindreds, 
			MARKERS => \@markers, 
			MAP => $map,
			ALLELETYPE => "Size", 
			AFS => $bpall, 
			TRAIT => $sv, 
			LC => $lcd,
			SETUPFILENAME => "$runName.setup", 
			PHOTOFILENAME => "$runName.out", 
			DATFILENAME => "$runName.dat", 
			PEDFILENAME => "$runName.pre", 
			ANALYSIS => "BOTH", 
			SINGLEPOINT => "off", 
			OFFEND => "5.0",
			INCREMENT => "step 3",
			MAXBITS => 18,
		       ) ;
    }
  }  

=head1 DESCRIPTION

This package contains methods relating to the use of data contained in GenPerl 
objects in genetic linkage analyses.  Generally speaking, this means reading 
and writing linkage format pedigree and locus files, and/or running programs 
such as genehunter, etc.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 FEEDBACK

Currently, all feedback should be sent directly to the author.

=head1 AUTHOR - Steve Mathias

Email: mathias@genomica.com

Phone: (720) 565-4029

Address: Genomica Corporation 
         1745 38th Street
         Boulder, CO 80301

=head1 DETAILS

The rest of the documentation describes each of the methods. The names of 
internal variables and methods are preceded with an underscore (_).

=cut

##################
#                #
# Begin the code #
#                #
##################

package Genetics::API::Analysis::Linkage ;

BEGIN {
  $ID = "Genetics::API::Analysis::Linkage" ;
  #$DEBUG = $main::DEBUG ;
  $DEBUG = 0 ;
  $DEBUG and warn "Debugging in $ID (v$VERSION) is on" ;
}

=head1 Imported Packages

 strict		    Just to be anal
 vars		    Global variables
 Carp		    Error reporting

=cut

use strict ;
use vars qw(@ISA @EXPORT @EXPORT_OK $ID $DEBUG) ;
use Carp ;
use Exporter ;

=head1 Inheritance

 Exporter           Make methods available to importing packages

=cut

@ISA = qw(Exporter) ;

@EXPORT = qw(writeLinkageFiles runGenehunter 
             writeKEMFiles runKEM processKemResults 
	     printProcessedKemResults htmlizeKemResults  
	     orderMarkersWithMap _renumberAlleles) ;
@EXPORT_OK = qw();


=head1 Public Methods

=head2 writeLinkageFiles

  Function  : Write LINKAGE format pedigree and locus files.
  Arguments : A hash of parameters as follows
              KINDREDS => Array pointer to a list of Kindred objects.
                          These define the Subjects being analyzed.
                          Required, for obvious reasons.
              MARKERS => Array pointer to a list of Marker objects.
                         These define the Markers being analyzed.
                         Required, for obvious reasons.
              ALLELETYPE => String containing the allele type of the alleles 
                            to be used.
                            Optional.  Default value is Code.
              AFS => Array pointer to a list of Subject or Kindred objects, or 
                     a single Cluster (Kindred or Subject) object.
                     The source for allele frequencies.
                     Optional.  If not provided, the input Kindreds will be used
              EXTAFS => A FrequencySource object.
                        The source for allele frequencies.
                        Optional.  If not provided, the input Kindreds will be used
              TRAIT => A StudyVariable object.
                       The trait locus being analyzed.  The category of this 
                       StudyVariable must be DynamicAffectionStatus or 
                       StaticAffectionStatus.
                       Optional.
              LC => A StudyVariable object.
                    This StudyVariable defines the liability classes to be used 
                    with the trait locus being analyzed.  The category of this 
                    StudyVariable must be StaticLiabilityClass.
                    Optional.
              QTLS => Array pointer to a list of StudyVariable objects.
                      QTLs to be analyzed.
                      Optional.
              MAP => A Map object.
                     This Map will be used to order the markers.  Also, the distances 
                     will be used.  Right now, every input Marker MUST be on the Map 
                     and there MUST NOT be any markers on the map that are not being 
                     analyzed.
                     Optional.  
              DATFILE => Filehandle reference.
                         The filehandle to which the locus file will be written.
                         Optional.  If not provided, STDOUT will be used.
              PEDFILE => Filehandle reference.
                         The filehandle to which the pedigree file will be 
                         written.
                         Optional.  If not provided, STDOUT will be used.
              MARKERDELIM => Scalar containint the string to be used to 
                             delimit marker names in the locus file.
                             Optional.  If not provided, # is used.
              RENUMBER => Boolean.
                          Optional.  If not provided, alleles are NOT re-
                          numbered.
  Returns   : N/A
  Scope     : Public
  Called by : 
  Comments  : To Do: support for X-linked data
                     support for dynamic trait loci
                     support for dynamic liability classes
                     support for QTLs

=cut

sub writeLinkageFiles {
  my($self, %param) = @_ ;
  my($kListPtr, $mListPtr, $alleleType, $afsPtr, $fs, $extAFSFlag, $traitSV, 
     $traitFlag, $lcSV, $lcFlag, $qtlListPtr, $qtlFlag, $datFh, $pedFh, $mdStr, 
     $rnFlag, $map, $mapFlag, @orderedMarkers, @unorderedMarkers, @distances, 
     $locusCount, $locusStr, $mapStr, $i, $asdPtr, $allelesStr, $codesListPtr, 
     $lcCount, $codePtr, $marker, $markerName, %renum, $freqsPtr, $alleleCount, 
     $freq, $freqsStr, $allele, $kindred, $kindredName, @subjects, $subject, 
     $subjectName, @subjNames, $momName, $dadName, $sex, $code, @alleles, $a1, 
     $a2, $c1, $c2, 
    ) ;
  
  defined($kListPtr = $param{KINDREDS}) or 
                          croak "ERROR [writeLinkageFiles]: No Kindreds!" ;
  defined($mListPtr = $param{MARKERS}) or 
                           croak "ERROR [writeLinkageFiles]: No Markers!" ;
  defined($alleleType = $param{ALLELETYPE}) or $alleleType = "Code" ;
  if ( defined($afsPtr = $param{AFS}) ) {
    $extAFSFlag = 0 ;
  } elsif ( defined($fs = $param{EXTAFS}) ) {
    $extAFSFlag = 1 ;
  } else {
    $afsPtr = $kListPtr ;
    $extAFSFlag = 0 ;
  }
  defined($traitSV = $param{TRAIT}) or $traitSV = undef ;
  _validateTraitInput($traitSV, \$traitFlag, \$lcFlag) or 
    croak "ERROR [writeLinkageFiles]: Invalid trait locus StudyVariable!" ;
  defined($lcSV = $param{LC}) or $lcSV = undef ;
  _validateLCInput($lcSV, \$lcFlag) or 
    croak "ERROR [writeLinkageFiles]: Invalid liability class StudyVariable!" ;
  $qtlListPtr = undef ; # QTLs not supported
#    defined($qtlListPtr = $param{QTLS}) or $qtlListPtr = undef ;
#    _validateQTLInput($qtlListPtr, \$qtlFlag) or 
#           croak "ERROR [writeLinkageFiles]: Invalid QTL StudyVariable(s)!" ;
  defined($datFh = $param{DATFILE}) or $datFh = \*STDOUT ;
  defined($pedFh = $param{PEDFILE}) or $pedFh = \*STDOUT ;
  defined($mdStr = $param{MARKERDELIM}) or $mdStr = "#" ;
  defined($rnFlag = $param{RENUMBER}) or $rnFlag = 0 ;

  defined($map = $param{MAP}) or $map = undef ;
  _processMarkersAndMap($mListPtr, $map, \$mapFlag, \@orderedMarkers, 
			\@unorderedMarkers, \@distances) or croak "ERROR [writeLinkageFiles]: Input marker set and Map are not compatible!" ;

  # Locus file
  $locusCount = scalar(@$mListPtr) ;
  $traitFlag and $locusCount++ ;  
  $qtlFlag and $locusCount += scalar(@$qtlListPtr) ;
  $mapStr = " " ;
  print $datFh "$locusCount 0 0 5\n" ;
  print $datFh "0 0.0 0.0 0\n" ;
  $locusStr = " " ;
  $i = 1 ;
  while ($i <= $locusCount) {
    $locusStr .= "$i " ;
    $i++ ;
  }
  print $datFh "$locusStr\n" ;
  if ($traitFlag) {
    $asdPtr = $traitSV->field("AffStatDef") ;
    print $datFh "1 2  << affection status\n" ;
    $allelesStr = (1 - $$asdPtr{diseaseAlleleFreq}) ;
    $allelesStr .= " $$asdPtr{diseaseAlleleFreq}  << allele frequencies" ;
    print $datFh "$allelesStr\n" ;
    if ($lcFlag == 2) {
      # using dynamic liability classes
      
    } elsif ($lcFlag == 1) {
      # using static liability classes
      $codesListPtr = $lcSV->field("Codes") ;
      $lcCount = scalar(@$codesListPtr) ;
      print $datFh "$lcCount << number of liability classes\n" ;
      foreach $codePtr (@$codesListPtr) {
	print $datFh "$$codePtr{pen11} $$codePtr{pen12} $$codePtr{pen22}  << penetrance values\n" ;
      }
    } else {
      # use the default liability classes
      print $datFh "1 << number of liability classes\n" ;
      print $datFh "$$asdPtr{pen11} $$asdPtr{pen12} $$asdPtr{pen22}  << penetrance values\n" ;
    }
    $mapStr .= "0.100 " ;
  }

  foreach $marker (@orderedMarkers, @unorderedMarkers) {
    $markerName = $marker->field("name") ;
    if ($rnFlag) {
      $renum{$markerName} = $self->_renumberAlleles($marker, $alleleType) ;
    }
    if ($extAFSFlag) {
      $freqsPtr = $fs->getAlleleFreqsByMarkerName($markerName, $alleleType) ;
    } else {
      $freqsPtr = $self->getAlleleFreqs($marker, $alleleType, $afsPtr) ;
    }
    $alleleCount = scalar(keys %$freqsPtr) ;
    print $datFh "3 $alleleCount $mdStr $markerName\n" ;
    $freqsStr = "" ;
    foreach $allele ($self->getAllelesByType($marker, $alleleType)) {
      # alleles are sorted numerically, then alphabetically
      $freq = $$freqsPtr{$allele} ;
      $freq = 0.0001 if $freq eq "0" ;
      $freq = 0.0001 if $freq == 0 ;
      $freqsStr .= "$freq " ;
    }
    $mapStr .= shift @distances ;
    print $datFh "$freqsStr << allele frequencies\n" ;
  }
  #$mapStr =~ s/0.1 $// ; # markers - 1 distances
  print $datFh "0 0\n" ;
  print $datFh "$mapStr << map\n" ;
  print $datFh "1 0.10000 0.45000\n" ;

  # Pedigree file
  foreach $kindred (@$kListPtr) {
    $kindredName = $kindred->field("name") ;
    @subjects = $self->getSubjectsByKindred($kindred) ;
    @subjNames = map { $_->name } @subjects ;
    foreach $subject (@subjects) {
      $allelesStr = $code = "" ;
      $subjectName = $subject->field("name") ;
      # Particularly when using derived Kindreds, mom and dad may be defined 
      # from a Subject's point of view, but not be in the Kindred that is 
      # being analyzed.
      if ( defined($momName = $subject->getMotherName()) ) {
	grep /$momName/, @subjNames or $momName = "0" ;
      } else {
	$momName = "0" ;
      }
      if ( defined($dadName = $subject->getFatherName()) ) {
	grep /$dadName/, @subjNames or $dadName = "0" ;
      } else {
	$dadName = "0" ;
      }
      $sex = $subject->field("gender") ;
      $sex eq "Male" and $sex = 1 ;
      $sex eq "Female" and $sex = 2 ;
      if ($traitFlag) {
	$code = $self->getPtValue($subject, $traitSV) ;
	$allelesStr .= "$code " ;
	if ($lcFlag == 1) {
	  # static liability class assignments
	  $code = $self->getPtValue($subject, $lcSV) ;
	  $allelesStr .= "$code  " ;
	} elsif ($lcFlag == 2) {
	  # dynamic liability class assignments
	} else {
	  # no liability class assignments
	  $allelesStr .= " " ;
	}
      }
      foreach $marker (@orderedMarkers, @unorderedMarkers) {
	$markerName = $marker->field("name") ;
	@alleles = $self->getGtAlleles($subject, $marker) ;
	if ( defined($alleles[0]) ) {
	  $alleleCount = scalar(@alleles) ;
	  if ($alleleCount == 2) {
	    if ($rnFlag) {
	      $a1 = $alleles[0] ;
	      $a2 = $alleles[1] ;
	      $c1 = ${renum{$markerName}}{$a1} ; # renumbered code corresponding to allele1
	      $c2 = ${renum{$markerName}}{$a2} ; # renumbered code corresponding to allele2
	      unless (defined($c1) and defined($c2)) {
		print "\nWARNING: Allele renumbering problem for marker $markerName:\n" ;
		print "\tAlleles: $a1, $a2  => " ;
		print "\tCodes: $c1, $c2\n" ;
	      }
	      $allelesStr .= "$c1 $c2  " ;
	    } else {
	      $allelesStr .= "$alleles[0] $alleles[1]  " ;
	    }
          } elsif ($alleleCount == 1) {
	    $allelesStr .= "$alleles[0] $alleles[0]  " ;
	  } else {
	    $allelesStr .= "$alleles[0] $alleles[1]  " ;
	    print STDERR "WARNING: More then two alleles found for $subjectName/$markerName" ;
	  }
	} else {
	  $allelesStr .= "0 0  " ;
	}
      }
      if ($qtlFlag) {
	# Get QTL Pts
      }
      print $pedFh "$kindredName $subjectName $dadName $momName $sex $allelesStr\n" ;
    }
  }
  #close PRE ;

  return(1) ;
}

=head2 runGenehunter

  Function  : Run a Genehunter analysis
  Arguments : A hash of parameters as follows
              KINDREDS => Array pointer to a list of Kindred objects.
                          These define the Subjects being analyzed.
                          Required, for obvious reasons.
              MARKERS => Array pointer to a list of Marker objects.
                         These define the Markers being analyzed.
                         Required, for obvious reasons.
              AFS => Array pointer to a list of Subject or Kindred objects, or 
                     a single Cluster (Kindred or Subject) object.
                     The source for allele frequencies.
                     Optional.  If not provided, the input Kindreds will be used
              EXTAFS => A FrequencySource object.
                        The source for allele frequencies.
                        Optional.  If not provided, the input Kindreds will be used
              TRAIT => A StudyVariable object.
                       The trait locus being analyzed.  The category of this 
                       StudyVariable must be AffectionStatus or StaticAffectionStatus.
                       Optional.
              LC => A StudyVariable object.
                    This StudyVariable defines the liability classes to be used 
                    with the trait locus being analyzed.  The category of this 
                    StudyVariable must be StaticLiabilityClass.
                    Optional.
              DATFILENAME => A name to be used for the locus file.
                             Required.
              PEDFILENAME => A name to be used for the pedigree file.
                             Required.
              PHOTOFILENAME => A name to be used for the photo file.
                               Optional.
              FILESONLY => Boolean.  If true, only write files.
                           Optional, defaults to false.
  Returns   : N/A
  Scope     : Public
  Comments  : 

=cut

sub runGenehunter {
  my($self, %param) = @_ ;
  my($setup, $analysis, $score, $singlePt, $ht, $countRecs, $offEnd, $incr, 
     $mapFunc, $units, $maxBits, $discard, $skipLarge, $totalStat, 
     $setupFileName, $gh) ;

  open(DAT, "> $param{DATFILENAME}") or 
                    croak "ERROR [runGenehunter]: Can't write locus file: $!" ;
  open(PRE, "> $param{PEDFILENAME}") or 
                 croak "ERROR [runGenehunter]: Can't write pedigree file: $!" ;

  $self->writeLinkageFiles(KINDREDS => $param{KINDREDS}, 
			   MARKERS => $param{MARKERS}, 
			   ALLELETYPE => $param{ALLELETYPE}, 
			   AFS => $param{AFS}, 
			   TRAIT => $param{TRAIT}, 
			   LC => $param{LC}, 
			   MAP => $param{MAP}, 
			   RENUMBER => 1,
			   DATFILE => \*DAT,
			   PEDFILE => \*PRE) ;
  close DAT ;
  close PRE ;

  if (defined $param{PHOTOFILENAME}) {
    $setup = "photo $param{PHOTOFILENAME}\n" ;
    $setup .= "load markers $param{DATFILENAME}\n" ;
  } else {
    $setup = "load markers $param{DATFILENAME}\n" ;
  }
  defined($analysis = $param{ANALYSIS}) or $analysis = "BOTH" ;
  $setup .= "analysis $analysis\n" ;
  defined($score = $param{SCORE}) or $score = "ALL" ;
  $setup .= "score $score\n" ;
  defined($singlePt = $param{SINGLEPOINT}) or $singlePt = "off" ;
  $setup .= "single point $singlePt\n" ;
  if ($singlePt eq "off") {
    defined($offEnd = $param{OFFEND}) or $offEnd = "0.0" ;
    $setup .= "off end $offEnd\n" ;
    defined($incr = $param{INCREMENT}) or $incr = "step 5" ;
    $setup .= "increment $incr\n" ;
  }
  defined($ht = $param{HAPLOTYPE}) or $ht = "off" ;
  $setup .= "haplotype $ht\n" ;
  defined($countRecs = $param{COUNTRECS}) or $countRecs = "off" ;
  $setup .= "count recs $countRecs\n" ;
  defined($mapFunc = $param{MAPFUNCTION}) or $mapFunc = "kosambi" ;
  $setup .= "map function $mapFunc\n" ;
  defined($units = $param{UNITS}) or $units = "cM" ;
  $setup .= "units $units\n" ;
  defined($maxBits = $param{MAXBITS}) or $maxBits = "20" ;
  $setup .= "max bits $maxBits\n" ;
  defined($discard = $param{DISCARD}) or $discard = "on" ;
  $setup .= "discard $discard\n" ;
  defined($skipLarge = $param{SKIPLARGE}) or $skipLarge = "off" ;
  $setup .= "skip large $skipLarge\n" ;
  $setup .= "scan pedigrees $param{PEDFILENAME}\n" ;
  defined $param{PS} and $setup .= "ps $param{PS}\n" ;
  defined $param{DS} and $setup .= "ds $param{DS}\n" ;
  if (defined($totalStat = $param{TOTALSTAT})) {
    $totalStat = "total stat $totalStat" ;
  } else {
    $totalStat = "total stat" ;
  }
  $setup .= "$totalStat\n" ;

  defined($setupFileName = $param{SETUPFILENAME}) or 
                                          $setupFileName = "/tmp/gh.$$.setup" ;
  open(SETUP, "> $setupFileName") or 
                    croak "ERROR [runGenehunter]: Can't write setup file: $!" ;
  print SETUP $setup ;
  close SETUP ;

  unless ($param{FILESONLY}) {
    defined $param{PATHTOGH} ? $gh = $param{PATHTOGH} 
                             : $gh = "gh" ;
    system("cat $setupFileName | $gh") == 0 or 
                croak "ERROR [runGenehunter]: Problem running genehunter: $?" ;
#    system("cat $setupFileName") == 0 or 
#                  croak "ERROR [runGenehunter]: Problem: $?" ;
  }

  return(1) ;
}

=head2 writeKEMFiles

  Function  : Write "LINKAGE format" pedigree and locus files for use by KEM.
  Arguments : A hash of parameters as follows
              SUBJECTS => Array pointer to a list of Kindred objects.
                          These define the Subjects being analyzed.
                          Required, for obvious reasons.
              MARKERS => Array pointer to a list of Marker objects.
                         These define the Markers being analyzed.
                         Required, for obvious reasons.
              DISTANCES => Array pointer to a list of distances bewtween the 
                           Markers.
              ALLELETYPE => String containing the allele type of the alleles 
                            to be used.
                            Optional.  Default value is Code.
              DATFILE => Filehandle reference.
                         The filehandle to which the locus file will be written.
                         Optional.  If not provided, STDOUT will be used.
              PEDFILE => Filehandle reference.
                         The filehandle to which the pedigree file will be 
                         written.
                         Optional.  If not provided, STDOUT will be used.
  Returns   : A hash, keyed on marker names that maps the codes (used in the 
	      output files) to the allele names of the markers.  The hash has 
              the following structure:
                 markerNames => code2alleleName hash references
  Scope     : Public
  Called by : 
  Comments  : Alleles have to be re-numbered for KEM.
              Markers and distances are used in their input order.

=cut

sub writeKEMFiles {
  my($self, %param) = @_ ;
  my($sListPtr, $mListPtr, $dListPtr, $alleleType, $datFh, $pedFh, 
     $locusCount, $mapStr, $marker, $markerName, $alleleCount, %renum, 
     @subjects, $subject, $subjectName, $sex, @fullyGtdSubjects, 
     $allelesStr, @alleles, $a1, $a2, $c1, $c2, 
    ) ;
  
  defined($sListPtr = $param{SUBJECTS}) or 
                          croak "ERROR [writeKEMFiles]: No Subjects!" ;
  defined($mListPtr = $param{MARKERS}) or 
                           croak "ERROR [writeKEMFiles]: No Markers!" ;
  defined($dListPtr = $param{DISTANCES}) or 
                           croak "ERROR [writeKEMFiles]: No Distances!" ;
  defined($alleleType = $param{ALLELETYPE}) or $alleleType = "Code" ;
  defined($datFh = $param{DATFILE}) or $datFh = \*STDOUT ;
  defined($pedFh = $param{PEDFILE}) or $pedFh = \*STDOUT ;

  # Marker file
  $locusCount = scalar(@$mListPtr) ;
  print $datFh "$locusCount\n\n\n" ;
  $mapStr = " " ;

  foreach $marker (@$mListPtr) {
    $markerName = $marker->name() ;
    $renum{$markerName} = $self->_renumberAlleles($marker, $alleleType) ;
    $alleleCount = scalar(keys %{$renum{$markerName}}) ;
    print $datFh "3 $alleleCount # $markerName\n" ;
    if (@$dListPtr) {
      $mapStr .= shift(@$dListPtr) ;
      $mapStr .= " " ;
    }
    print $datFh "\n" ;
  }
  print $datFh "\n$mapStr << map\n\n" ;

  # Pedigree file
  foreach $subject (@$sListPtr) {
    $subjectName = $subject->name() ;
    $sex = $subject->gender() ;
    $sex eq "Male" and $sex = "M" ;
    $sex eq "Female" and $sex = "F" ;
    
    $allelesStr = "" ;
    foreach $marker (@$mListPtr) {
      $markerName = $marker->name() ;
      @alleles = $self->getGtAlleles($subject, $marker) ;
      if ( defined($alleles[0]) ) {
	$alleleCount = scalar(@alleles) ;
	if ($alleleCount == 2) {
	  $a1 = $alleles[0] ;
	  $a2 = $alleles[1] ;
	  $c1 = ${renum{$markerName}}{$a1} ; # renumbered code corresponding to allele1
	  $c2 = ${renum{$markerName}}{$a2} ; # renumbered code corresponding to allele2
	  unless (defined($c1) and defined($c2)) {
	    print "\nWARNING: Allele renumbering problem for marker $markerName:\n" ;
	    print "\tAlleles: $a1, $a2  => " ;
	    print "\tCodes: $c1, $c2\n" ;
	  }
	  $allelesStr .= "$c1 $c2  " ;
	} elsif ($alleleCount == 1) {
	  $a1 = $alleles[0] ;
	  $c1 = ${renum{$markerName}}{$a1} ; # renumbered code corresponding to allele1
          $allelesStr .= "$c1 $c1  " ;
	} else {
	  $a1 = $alleles[0] ;
	  $a2 = $alleles[1] ;
	  $c1 = ${renum{$markerName}}{$a1} ; # renumbered code corresponding to allele1
	  $c2 = ${renum{$markerName}}{$a2} ; # renumbered code corresponding to allele2
	  $allelesStr .= "$c1 $c2  " ;
	  print STDERR "WARNING: More then two alleles found for $subjectName/$markerName" ;
	}
      } else {
	$allelesStr .= "0 0  " ;
      }
    }
    print $pedFh "X $subjectName X X $sex $allelesStr\n" ;
  }

  return( _reverseRenum(%renum) ) ;
}

=head2 processKemResults

 Function  : Process K-EM output, as descibed below.
 Arguments : A file handle reference to a K-EM output file, an array reference 
             to the list of markers used in the analysis, and a hash reference 
             to the hash mapping allele codes to names (as returned by 
             writeKEMFiles()).
 Returns   : An array.  the first element is a scalar containing the best log 
             liklihood of the K-EM run.  The rest of the elements are hash 
             pointers containing processed results.  The structure of the 
             referenced hashes is:
               $htResult{name} = Ht number
               $htResult{freq} = float
               $htResult{ht}   = array reference to a list of allele names
 Example   : @kemResults = processKemResults(\@snps, \%poNameCode2Allele) ;
 Scope     : Public Class Method
 Comments  : Converts codes in K-EM output file back into allele names

=cut

sub processKemResults {
  my($fh, $poListPtr, $renumPtr) = @_ ;
  my($getHtFlag, $line, $htAlleleStr, $freq, @htAlleles, %kemResults, 
     @poNames, $i, $htNum, @htCodes, $htStr, $c2aPtr, %htResult, 
     @processedKemResults) ;
  
  $getHtFlag = 0 ;
  while (defined($line = <$fh>)) {
    if ($line =~ /^Best log\(likelihood\) = (\S+)/) {
      push @processedKemResults, $1 ; # First element of processed results
    }
    if ($line =~ /^Haplotype m1/) {
      $getHtFlag = 1 ;
      next ;
    }
    next unless $getHtFlag == 1 ;
    #last if $line =~ /^Total CPU/ ; # C++
    last if $line =~ /^[0-9:\.]+ KEM complete/ ; # Java

    ($htNum, $htAlleleStr, $freq) = $line =~ /^\s+(\d+)\s+(.+)\s+([0-9\.eE-]+)$/ ;
    $htAlleleStr =~ s/^\s*// ;
    $htAlleleStr =~ s/\s*$// ;
    @htAlleles = split(/\s+/, $htAlleleStr) ;
    $kemResults{$htNum}{freq} = $freq ;
    $kemResults{$htNum}{ht} = [ @htAlleles ] ;
  }

  # Generate a list of marker names corresponding to the marker order 
  # in the haplotypes
  for (@$poListPtr) {
    push @poNames, $_->name() ;
  }

  foreach $htNum (sort { $kemResults{$b}->{freq} <=> $kemResults{$a}->{freq} } keys %kemResults) {
    $htStr = "" ;
    @htCodes = @{$kemResults{$htNum}{ht}} ;
    for ($i=0 ; $i<=$#htCodes ; $i++) {
      $c2aPtr = $$renumPtr{$poNames[$i]} ;
      $htStr .= "$$c2aPtr{$htCodes[$i]} " ; 
    }
    $htResult{name} = $htNum ;
    $htResult{freq} = $kemResults{$htNum}{freq} ;
    $htResult{ht} = $htStr ;
    push @processedKemResults, { %htResult } ;
  }

  return(@processedKemResults) ;
}

=head2 printProcessedKemResults

 Function  : 
 Arguments : 
 Returns   : 
 Example   : printProcessedKemResults(%kemResults)
 Scope     : Public Class Method
 Comments  : 

=cut

sub printProcessedKemResults {
  my(@kemResults) = @_ ;
  my($logLik, $htResultPtr) ;

  $logLik = shift @kemResults ;
  print "\nBest Log Liklihood: $logLik\nHaplotypes:\n" ;
  foreach $htResultPtr (@kemResults) {
    printf "%10s %1.6f  ", $$htResultPtr{name}, $$htResultPtr{freq} ;
    print "$$htResultPtr{ht}\n" ;
  }

  return(1) ;
}


=head2 htmlizeKemResults

 Function  : Format processed K-EM results as HTML
 Arguments : An array of hash references as returned by processKemResults()
 Returns   : Scalar text string containing HTML
 Example   : $html = htmlizeKemResults(@processedKemResults)
 Scope     : Public Class Method
 Comments  : 

=cut

sub htmlizeKemResults {
  my(@kemResults) = @_ ;
  my($html, $logLik, $htResultPtr) ;

  $logLik = shift @kemResults ;
  $html = "" ;
  $html .= "<table border=\"1\" cellspacing=\"2\" cellpadding=\"5\">\n" ;
  $html .= "<tr><th colspan=\"3\">Best Log Liklihood: $logLik</th></tr>\n" ;
  $html .= "<tr><th>#</th><th>Freq.</th><th>Haplotype</th></tr>\n" ;
  foreach $htResultPtr (@kemResults) {
    $html .= "<tr><td><b>$$htResultPtr{name}</b></td>" ;
    $html .= "<td>$$htResultPtr{freq}</td>" ;
    $html .= "<td>$$htResultPtr{ht}</td></tr>\n" ;
  }
  $html .= "</table>\n" ;

  return($html) ;
}

=head2 orderMarkersWithMap

 Function  : Order markers and generate distances based on a Map object.
 Arguments : An array reference to a list of input Markers/SNPs, a Map, and two 
             array reference to be populated with the ordered markers and 
             distances, respecitvely.
 Returns   : N/A
 Example   : $api->orderMarkersWithMap(\@snps, undef, \@orderedSnps, \@distances) ;
 Scope     : Public Instance Method
 Comments  : This is used inconjunction with runKEM().
             This is basically a stub method right now.  It populates to 
             ordered list with a copy of the input list and populates the 
             distance list with 0.1s.

=cut

sub orderMarkersWithMap {
  my($self, $mListPtr, $map, $omListPtr, $dListPtr) = @_ ;
  my($i) ;

  @$omListPtr = @$mListPtr ;
  $i = 1 ;
  while ($i < scalar(@$mListPtr)) {
    push @$dListPtr, 0.1 ;
    $i++ ;
  }

  return(1) ;
}

=head1 Private Methods

=head2 _renumberAlleles

  Function  : Renumber alleles into consecutive integers
  Arguments : A Marker or SNP object and a string containing an allele type.
  Returns   : A reference to a hash with the following structure:
                %hash = (alleleName => code)
  Scope     : Private instance method
  Called by : writeLinkageFiles().
  Comments  : 

=cut

sub _renumberAlleles {
  my($self, $marker, $alleleType) = @_ ;
  my($markerName, @alleleNames, %alleleName2Code, $i) ;
  my $dbh = $self->{dbh} ;

  $markerName = $marker->field("name") ;
  print STDERR "MESSAGE [_renumberAlleles]: $markerName  " ;

  @alleleNames = $self->getAllelesByType($marker, $alleleType) ;

  for ($i=0 ; $i<=$#alleleNames ; $i++) {
    $alleleName2Code{$alleleNames[$i]} = $i+1 ;
    print STDERR "$alleleNames[$i] -> $alleleName2Code{$alleleNames[$i]}, " ;
  }
  print STDERR "\n" ;

  return(\%alleleName2Code) ;
}

=head2 _reverseRenum

 Function  : See below
 Arguments : A hash of with the following structure:
                 markerNames => alleleName2code hash references
 Returns   : A hash of with the following structure:
                 markerNames => code2alleleName hash references
 Example   : %poName_c2a = _reverseRenum(%poName_a2c)
 Scope     : Private Class Method
 Comments  : This is needed because the linkage file writing routines 
             need to keep track of allele->code mapping, but they need 
             to return code->allele mappings.

=cut

sub _reverseRenum {
  my(%renum) = @_ ;
  my($poName, $a2cPtr, %c2a, %poName_c2a) ;
  
  while ( ($poName, $a2cPtr) = each %renum ) {
    %c2a = reverse %$a2cPtr ;
    $poName_c2a{$poName} = { %c2a } ;
  }

  return(%poName_c2a) ;
}

=head2 _validateTraitInput

  Function  : Verify that a StudyVariable may be used as a trait locus.
  Arguments : A StudyVariable object and two pointers to flag variables used 
              in writeLinkageFiles().
  Returns   : N/A
  Scope     : Private class method
  Called by : writeLinkageFiles()
  Comments  : The fisrt flag pointer is to the trait flag; it is set to 1 if 
              the input StudyVariable may be used for static liability class 
              definition and assignments.  The second flag pointer is to 
              the liability class flag.  It is set to 2 if the input 
              StudyVariable may be used for dynamic liability class definition 
              and assignments.

=cut

sub _validateTraitInput {
  my($sv, $traitFlagPtr, $lcFlagPtr) = @_ ;

  if (defined $sv) {
    if ($sv->field("category") eq "StaticAffectionStatus") {
      $$traitFlagPtr = 1 ;
    } elsif ($sv->field("category") eq "DynamicAffectionStatus") {
      $$traitFlagPtr = 1 ;
      $$lcFlagPtr = 2 ;
    } else {
      $$traitFlagPtr = 0 ;
      carp "WARNING [_validateTraitInput]: Can't use StudyVariable $sv as a trait locus!" ;
    }
  } else {
    $$traitFlagPtr = 0 ;
  }

  return(1) ;
}

=head2 _validateLCInput

  Function  : Verify that a StudyVariable may be used for static liability 
              class definition and assignments.
  Arguments : A StudyVariable object a pointer to a flag variable used 
              in writeLinkageFiles().
  Returns   : 
  Scope     : Private class method
  Called by : writeLinkageFiles()
  Comments  : The flag pointer is to the the liability class flag.  It is set 
              to 1 if the input StudyVariable may be used for static liability 
              class definition and assignments.

=cut

sub _validateLCInput {
  my($sv, $flagPtr) = @_ ;

  # NB. There is no check for dynamic liability classes here, as that is done 
  # by _validateTraitInput().
  if (defined $sv) {
    if ($sv->field("category") eq "StaticLiabilityClass") {
      $$flagPtr = 1 ;
    } else {
      carp "WARNING [_validateLCInput]: Can't use StudyVariable $sv for liability classes!" ;
      return(undef) ;
    }
  } else {
    $$flagPtr = 0 ;
  }
  
  return(1) ;
}

=head2 _validateQTLInput

  Function  : Verify that StudyVariable(s) may be used as QTL varibales in a 
              linkage analysis.
  Arguments : N/A
  Returns   : N/A
  Scope     : Private class method
  Called by : writeLinkageFiles()
  Comments  : Not implemented.
              

=cut

sub _validateQTLInput {
  my($inListPtr, $qtlListPtr, $flagPtr) = @_ ;
  my($sv) ;

  if (defined $inListPtr) {
    foreach $sv (@$inListPtr) {
      $sv->field("format") eq "Number" and push(@$qtlListPtr, $sv) ;
    }
    defined($$qtlListPtr[0]) ? $$flagPtr = 1 : $$flagPtr = 0 ;
  } else {
    $$flagPtr = 0 ;
  }
  
  return(1) ;
}

=head2 _processMarkersAndMap

  Function  : Order markers and generate distances for linkage analysis.
  Arguments : An array reference to a list of input Markers/SNPs, a Map 
  Returns   : N/A
  Scope     : Private class method
  Called by : writeLinkageFiles()
  Comments  : There does not have to be a Map object.  If there is not the 
              marker order used is that of the input list and all distances are 
              set to 0.1.  If there are input Markers/SNPs that are not on the 
              Map, they are included in the analysis after the ordered 
              Markers/SNPs with all distances are set to 0.1.

              NB. This does not yet deal with the following:
                - markers on the map that are not in the input set
                - global map order (it may never do this)
                - map distance units other than Theta or cM (it may never do this)

=cut

sub _processMarkersAndMap {
  my($mListPtr, $map, $flagPtr, $omListPtr, $uomListPtr, $dListPtr) = @_ ;
  my($markerCount, $units, $omeListPtr, @soNames, $omePtr, $marker, $markerName, 
     @toBeOrdered, $mID, $soID, $i, $j, %order, $cM2ThetaFlag, $dist) ;

  $markerCount = scalar(@$mListPtr) ;
  if (defined $map) {
    # Use a map to order the markers
    unless ($map->field("orderingMethod") eq "Relative") {
      carp "WARNING [_processMarkersAndMap]: Inappropriate Map ordering method!" ;
      return(undef) ;
    }
    $units = $map->distanceUnits() ;
    if ($units eq "cM") {
      $cM2ThetaFlag = 1 ;
    } elsif ($units eq "Theta") {
      $cM2ThetaFlag = 0 ;
    } else {
      carp "WARNING [_processMarkersAndMap]: Invalid Map.distanceUnits: $units!" ;
      return(undef) ;
    }
    $omeListPtr = $map->field("OrderedMapElements") ;
    if (scalar(@$omeListPtr) > scalar(@$mListPtr)) {
      carp "WARNING [_processMarkersAndMap]: There are Markers/SNPs on the map that are not in the input set!" ;
      return(undef) ;
    }
    
    # NB. input markers and markers on the map are verified by name - probably 
    # not the most bomb-proof way to do this.
    # First, generate a list of all element names on the map...
    foreach $omePtr (@$omeListPtr) {
      push @soNames, $$omePtr{SeqObj}->{name} ;
    }
    # ...then, check to make sure each input marker's name is in that list...
    foreach $marker (@$mListPtr) {
      $markerName = $marker->field("name") ;
      if (grep {$markerName eq $_} @soNames) {
	# ...if so, add it to list of markers to be ordered...
	push @toBeOrdered, $marker ;
      } else {
	# ...if not, add it to unordered markers list and give a warning
	push @$uomListPtr, $marker ;
	carp "WARNING [_processMarkersAndMap]: Marker $markerName is not on the Map!" ;
      }
    }
    # If we get to here everything is ok, so set the flag...
    $$flagPtr = 1 ;
    # ...and order the markers
    # There HAS to be a better way to do this, but this works
    foreach $marker (@toBeOrdered) {
      $mID = $marker->field("id") ;
      $i = 1 ;
      foreach $omePtr (@$omeListPtr) {
	$soID = $$omePtr{SeqObj}->{id} ;
	if ($mID == $soID) {
	  $order{$i} = $marker ;
	  next ;
	}
	$i++ ;
      }
    }
    $j = 0 ;
    # The sort on the following line is where the markers are actually ordered
    foreach $i ( sort {$a <=> $b} keys(%order) ) {
      push @$omListPtr, $order{$i} ;
      $omePtr = $$omeListPtr[$j] ;
      # If the ordered markers include the last marker on the map, the distance 
      # will be undefined for that marker
      if (defined $$omePtr{distance}) {
	if ($cM2ThetaFlag) {
	  $dist = _cM2theta($$omePtr{distance}) ;
	} else {
	  $dist = $$omePtr{distance} ;
	}
	push @$dListPtr, "$dist " ;
      } else {
	push @$dListPtr, "" ;
      }
      $j++ ;
    }
    # Add distances for the unordered markers
    $i = 0 ;
    while ($i < scalar(@$uomListPtr)) {
      push @$dListPtr, "0.1 " ;
      $i++ ;
    }
  } else {
    # There is no input map.  Markers are ordered as they were input.  All 
    # distances are set to 0.1
    $$flagPtr = 0 ;
    while (scalar(@$dListPtr) < $markerCount) { 
      push @$dListPtr, "0.1 " ;
    }
    @$omListPtr = @$mListPtr ;
    @$uomListPtr = () ;
  }
  
  return(1) ;
}

sub _theta2cM {
  my $theta = shift ;
  my $M = 0.25 * log( ((1 + $theta*2) / (1 - $theta*2)) ) ;
  my $cM = $M * 100 ;
  return sprintf("%.2f", $cM);
}

sub _cM2theta {
  my $cM = shift ;
  my $M = $cM / 100 ;
  my $e4x = 2.7182818285 ** (4*$M) ; 
  my $theta = 0.5 * (($e4x -1) / ($e4x + 1)) ;
  return sprintf("%.4f", $theta);
}

1;
