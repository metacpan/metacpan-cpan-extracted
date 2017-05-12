# GenPerl module 
#

# POD documentation - main docs before the code

=head1 NAME

Genetics::API::Analysis

=head1 SYNOPSIS

  # The following code will produce a graph of allele frequencies in two 
  # different Subject Clusters

  $affCluster = $api->getObject({TYPE => "Cluster", NAME => "HT Affecteds"}) ;
  $unaffCluster = $api->getObject({TYPE => "Cluster", NAME => "Normals"}) ;

  $marker = $api->getObject({TYPE => "Marker", NAME => "agtT174M"}) ;

  $api->graphAlleleFreqs(
			 MARKER => $marker, 
			 FREQSOURCES => [ $affCluster, $unaffCluster ],
			 ALLELETYPE => "Nucleotide"
			) ;

  # The following code will perform a chi-square test on this same data

  $api->chiSquareAssocTest(
			   MARKER => $marker, 
			   SC1 => $affCluster,
			   SC2 => $unaffCluster,
			   ALLELETYPE => "Nucleotide", 
			  ) ;

=head1 DESCRIPTION

This package contains methods for the analysis of data contained in GenPerl
objects.  Also see Genetics::API::Analysis::Linkage for methods relating to
genetic linkage analyses.

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

The rest of the documentation describes each of the object variables and 
methods. The names of internal variables and methods are preceded with an
underscore (_).

=cut

##################
#                #
# Begin the code #
#                #
##################

package Genetics::API::Analysis ;

BEGIN {
  $ID = "Genetics::API::Analysis" ;
  #$DEBUG = $main::DEBUG ;
  $DEBUG = 0 ;
  $DEBUG and warn "Debugging in $ID is on" ;
}

=head1 Imported Packages

 strict		    Just to be anal
 vars		    Global variables
 Carp		    Error reporting
 GD::Graph::bars    Graphing allele frequencies
 GD::Graph::colour  Graphing allele frequencies
 GD::Graph::Data    Graphing allele frequencies

=cut

use strict ;
use vars qw(@ISA @EXPORT @EXPORT_OK $ID $DEBUG) ;
use Carp ;
use Exporter ;
#use GD::Graph::bars ;   # Comment this out for distribution.
#use GD::Graph::colour ; # Comment this out for distribution.
#use GD::Graph::Data ;   # Comment this out for distribution.

=head1 Inheritance

 Exporter           Make methods available to importing packages

=cut

@ISA = qw(Exporter) ;

@EXPORT = qw(test calculateHet calculateSnpHW 
	     chiSquareAssocTest graphAlleleFreqs 
	    ) ;
@EXPORT_OK = qw();


=head1 Public Methods

sub test {
  my($self) = @_ ;
  my($sth, $aoaRef) ;
  my $dbh = $self->{dbh} ;

  $sth = $dbh->prepare( "select alleleCallID from AlleleCall 
                   where gtID = 4009 
                   and alleleID = 26" ) ;
  $sth->execute() ;
  $aoaRef = $sth->fetchall_arrayref() ;
  print scalar(@$aoaRef), "\n" ;

  return(1) ;
}

=head2 chiSquareAssocTest

  Function  : Perform a simple chi-square association test.
  Arguments : A Marker object, a string containing an allele type and two 
              Subject Cluster objects.
  Returns   : N/A
  Scope     : Public
  Called by : 
  Comments  : 

=cut

sub chiSquareAssocTest {
  my($self, %param) = @_ ;
  my($marker, $alleleType, $sc1, $sc2, $clusterName, $alleleName, %counts, 
     %alleleNames, %totals, $total, $chiSquare, $obs, $exp, $part, $dof, 
     $i, $level, $names, $countsStr, @counts, $markerName) ;
  my %ChiSquareDist = (
 level => [0.95, 0.9, 0.8, 0.7, 0.5, 0.3, 0.2, 0.1, 0.05, 0.01, 0.001], 
 1 => [0.004, 0.02, 0.06, 0.15 , 0.46, 1.07, 1.64 , 2.71, 3.84, 6.64 , 10.83], 
 2 => [0.10, 0.21, 0.45, 0.71 , 1.39, 2.41, 3.22 , 4.60, 5.99, 9.21 , 13.82], 
 3 => [0.35, 0.58, 1.01, 1.42 , 2.37, 3.66, 4.64 , 6.25, 7.82, 11.34 , 16.27], 
 4 => [0.71, 1.06, 1.65, 2.20 , 3.36, 4.88, 5.99 , 7.78, 9.49, 13.28 , 18.47], 
 5 => [1.14, 1.61, 2.34, 3.00 , 4.35, 6.06, 7.29 , 9.24, 11.07, 15.09 , 20.52], 
 6 => [1.63, 2.20, 3.07, 3.83 , 5.35, 7.23, 8.56 , 10.64, 12.59, 16.81 , 22.46], 
 7 => [2.17, 2.83, 3.82, 4.67 , 6.35, 8.38, 9.80 , 12.02, 14.07, 18.48 , 24.32], 
 8 => [2.73, 3.49, 4.59, 5.53 , 7.34, 9.52, 11.03 , 13.36, 15.51, 20.09 , 26.12], 
 9 => [3.32, 4.17, 5.38, 6.39 , 8.34, 10.66, 12.24 , 14.68, 16.92, 21.67 , 27.88], 
 10 => [3.94, 4.86, 6.18, 7.27 , 9.34, 11.78, 13.44 , 15.99, 18.31, 23.21 , 29.59]
		      ) ;

  defined($marker = $param{MARKER}) or 
                              croak "ERROR [chiSquareAssocTest]: No Marker!" ;
  $markerName = $marker->name ;
  
  defined($sc1 = $param{SC1}) or 
    croak "ERROR [chiSquareAssocTest]: No source(s) for allele frequencies!" ;
  defined($sc2 = $param{SC2}) or 
    croak "ERROR [chiSquareAssocTest]: No source(s) for allele frequencies!" ;
  defined($alleleType = $param{ALLELETYPE}) or $alleleType = "Code" ;
  
  $clusterName = $sc1->name ;
  $clusterName =~ s/\s+/_/g ;
  $counts{$clusterName} = $self->getAlleleCounts($marker, $alleleType, $sc1) ;
  $clusterName = $sc2->name ;
  $clusterName =~ s/\s+/_/g ;
  $counts{$clusterName} = $self->getAlleleCounts($marker, $alleleType, $sc2) ;

  # generate the totals
  foreach $clusterName (keys %counts) {
    foreach $alleleName (keys %{$counts{$clusterName}}) {
      $alleleNames{$alleleName}++ ; # keep track of all allele names seen
      $totals{$clusterName} += $counts{$clusterName}->{$alleleName} ;
      $totals{$alleleName} += $counts{$clusterName}->{$alleleName} ;
    }
    $total += $totals{$clusterName} ;
  } 
  
#    # see the counts
#    foreach $clusterName (keys %counts) {
#      print "Cluster: $clusterName\n" ;
#      foreach $alleleName (sort keys %{$counts{$clusterName}}) {
#        print "\t$alleleName -> $counts{$clusterName}->{$alleleName}\n" ;
#      }
#    }
#    # see the totals
#    foreach my $x (keys %totals) {
#      print "Total for $x -> $totals{$x}\n" ;
#    }
#    print "Total: $total\n" ;

  # Calculate chisquare
  print "Allele counts: \n\n" ;
  print "\t\t", join( "\t", sort(keys(%alleleNames)) ), "\n" ;
  foreach $clusterName (keys %counts) {
    $countsStr = "" ;
    @counts = () ;
    foreach $alleleName ( sort(keys(%alleleNames)) ) {
      push(@counts, $counts{$clusterName}->{$alleleName}) ;
      $obs = $counts{$clusterName}->{$alleleName} ;
      $exp = $totals{$clusterName} * $totals{$alleleName} / $total ;
      $part = (($obs - $exp)**2)/$exp ;
      $chiSquare += (($obs - $exp)**2)/$exp ;
      #print "$clusterName $alleleName\n" ;
      #print "(($obs - $exp)**2)/$exp = $part\n" ;
    }
    $countsStr = join("\t", @counts) ;
    write ;
  }
  # Determine significance level
  $dof = scalar(keys(%alleleNames)) - 1 ;
  for ($i=0 ; $i<=10 ; $i++) {
    #print "$i  $chiSquare ? ", $ChiSquareDist{$dof}->[$i], "\n" ;
    last if ($chiSquare <= $ChiSquareDist{$dof}->[$i]) ;
  }
  $level = $ChiSquareDist{level}->[$i-1] ;

  print "\nThe Chi-Square value is $chiSquare, with $dof degrees of freedom\n" ;
  $names = join(" and ", keys(%counts)) ;
  $markerName = $marker->field("name") ;
  print "\nThe probability that the differences in allele distributions between Subject Clusters $names at marker $markerName is due to chance is less than $level.\n\n" ;

format STDOUT =
@<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$clusterName,   $countsStr
.

  return(1) ;
}

=head2 graphAlleleFreqs

  Function  : Graph the allele frequencies for a Marker in a group of Subjects.
  Arguments : A hash of parameters as follows
              MARKER => The Marker object whose allele frequencies are to be graphed.
                        Required, for obvious reasons.
              FREQSOURCES => Array pointer to a list of Cluster (Kindred or Subject) 
                             and/or FrequencySource objects.
                             The source(s) for allele frequencies.
                             Required, for obvious reasons.
              ALLELETYPE => The type of alleles whose frequencies are to be graphed.
                            Optional, the default value is "Code".
  Returns   : N/A
  Scope     : Public
  Comments  : Calls xv to display the graphic.

=cut

sub graphAlleleFreqs {
  my($self, %param) = @_ ;
  my($marker, $sourceListPtr, $alleleType, $markerName, @alleleNames, @data, 
     @sourceNames, $source, $alleleName, $freqsPtr, @freqs, $graph, $fileName) ;
  
  # Get the input parameters and check a few things
  defined($marker = $param{MARKER}) or 
                                 croak "ERROR [graphAlleleFreqs]: No Marker!" ;
  $markerName = $marker->field("name") ;
  defined($sourceListPtr = $param{FREQSOURCES}) or 
    croak "ERROR [graphAlleleFreqs]: No source(s) for allele frequencies!" ;
  defined($alleleType = $param{ALLELETYPE}) or $alleleType = "Code" ;

  # Get the frequencies
  @alleleNames = $self->getAllelesByType($marker, $alleleType) ;
  push @data, [ @alleleNames ] ;
  foreach $source (@$sourceListPtr) {
    if ( ref($source) eq "Genetics::FrequencySource" ) {
      $freqsPtr = $source->getAlleleFreqsByMarkerName($markerName, $alleleType) ;
    } elsif ( ref($source) eq "Genetics::Cluster" ) {
      $freqsPtr = $self->getAlleleFreqs($marker, $alleleType, $source) ;
    } else {
      carp "WARNING [graphAlleleFreqs]: $source is an invalid source for allele frequencies!" ;
      next ;
    }
    @freqs = () ;
    push @sourceNames, $source->field("name") ;
    foreach $alleleName (@alleleNames) {
      push @freqs, $$freqsPtr{$alleleName} ;
    }
    push @data, [ @freqs ] ;
  }
  defined($data[1]) or croak "ERROR [graphAlleleFreqs]: No valid allele frequency data!" ;

  # Create and display the graph
  $graph = GD::Graph::bars->new() ;
  $graph->set( 
	      x_label         => 'Allele',
	      y_label         => 'Frequency',
	      title           => "$markerName Allele Frequencies",
	      long_ticks      => 1,
	      y_max_value     => 1.0,
	      y_tick_number   => 20,
	      y_label_skip    => 2,
	      bar_spacing     => 3,
#	      shadow_depth    => 2,
#	      shadowclr       => 'black',
	      transparent     => 0,
	     ) or carp "WARNING [graphAlleleFreqs]: " . $graph->error ;
  $graph->set_legend( @sourceNames );
  $graph->plot( \@data ) or croak "ERROR [graphAlleleFreqs]: " . $graph->error ;
  $fileName = "/tmp/$$.png" ;
  &_saveGraphToFile($graph, $fileName) ;
  system("xv $fileName &") == 0 or 
         croak "ERROR [graphAlleleFreqs]: system xv $fileName & failed: $?" ;

  return(1) ;
}

=head2 calculateHet

 Function  : Calculate the heterozygosity for a Marker or SNP.
 Arguments : A Marker object, a string containing an allele type, and one of 
              the following defining the Subject group:
                - a Subject Cluster object 
                - an array reference to a list of Subject objects
                - a Kindred Cluster object 
                - an array reference to a list of Kindred objects
 Returns   : A scalar float
 Scope     : Public
 Comments  : Arguments are passed directly to API::DB::Query::getAlleleFreqs()

=cut

sub calculateHet {
  my($self, $marker, $alleleType, $subjGroup) = @_ ;
  my($freqsPtr, $allele, $sumFreqsSquared, $het) ;

  # Parameter checking, to the extent that it happens at all, is taken 
  # care of by API::DB::Query::getAlleleFreqs()
  # Get the allele frequencies
  $freqsPtr = $self->getAlleleFreqs($marker, $alleleType, $subjGroup) ;
  # Calculate heterozygosity
  foreach $allele (sort keys %$freqsPtr) {
    next if ($alleleType eq "Nucleotide" and $allele eq "N") ;
    $sumFreqsSquared += ($$freqsPtr{$allele})**2 ;
  }
  $het = 1 - $sumFreqsSquared ;

  return( _formatFloat($het) ) ;
}

=head2 calculateSnpHW

 Function  : 
 Arguments : 
 Returns   : 
 Example   : calculateHW()
 Scope     : 
 Comments  : 

=cut

sub calculateSnpHW {
  my($self, $po, $sc) = @_ ;
  my($gtCountsPtr, $alleleCountsPtr, @alleles, $i, @allelePairs, 
     $n11, $n12, $n22, $n, $obs, $exp, $chiSquare) ;

  if ( ref($po) !~ /^Genetics::(Marker|SNP)$/ ) {
    croak "ERROR [calculateHW]: Invalid input Marker/SNP $po." ;
  }
  if ( ref($sc) ne "Genetics::Cluster" ) {
    croak "ERROR [calculateHW]: Invalid input Cluster $sc." ;
    if ( $sc->clusterType() ne "Subject" ) {
      croak "ERROR [calculateHW]: Invalid input Cluster type." ;
    }
  }

  # Genotype counts 
  $gtCountsPtr = $self->getSNPGtCounts($po, $sc) ;
  # Allele counts
  $alleleCountsPtr = $self->getAlleleCounts($po, "Nucleotide", $sc) ;

  @alleles = $self->getAllelesByType($po, "Nucleotide") ;
  for ($i=0 ; $i<=$#alleles ; $i++) {
    splice(@alleles, $i, 1) if $alleles[$i] eq "N" ;
  }
  push @allelePairs, "$alleles[0]$alleles[0]" ;
  push @allelePairs, "$alleles[0]$alleles[1]" ;
  push @allelePairs, "$alleles[1]$alleles[1]" ;

  # observed genotype counts
  $n11 = $$gtCountsPtr{$allelePairs[0]} ;
  $n12 = $$gtCountsPtr{$allelePairs[1]} ;
  $n22 = $$gtCountsPtr{$allelePairs[2]} ;
  $n = $n11 + $n12 + $n22 ;
  return("0.0000") if ( ($n11 == 0 or $n22 == 0) and ($n12 == 0) ) ;
  $chiSquare = 0 ;
  # allele pair 1
  $obs = $n11 ;
  $exp = ( (((2*$n11) + $n12)**2) / (4*$n) ) ;
  #print "AllelePair: $allelePairs[0]  obs: $obs, exp: $exp   X2: $chiSquare\n" ;
  $chiSquare = ((($obs - $exp)**2) / $exp) ;
  # allele pair 2
  $obs = $n12 ;
  $exp = ( (((2*$n11) + $n12) * ((2*$n22) + $n12)) / (2*$n) ) ;
  #print "AllelePair: $allelePairs[1]  obs: $obs, exp: $exp   X2: $chiSquare\n" ;
  $chiSquare += ((($obs - $exp)**2) / $exp) ;
  # allele pair 3
  $obs = $n22 ;
  $exp = ( (((2*$n22) + $n12)**2) / (4*$n) ) ;
  #print "AllelePair: $allelePairs[2]  obs: $obs, exp: $exp   X2: $chiSquare\n" ;
  $chiSquare += ((($obs - $exp)**2) / $exp) ;

  $chiSquare < 0.0001 ? return("0.0000") 
                      : return( &_formatFloat($chiSquare) ) ;
}


sub _formatFloat {
  my($f) = @_;
  my($g) ;

  if ( $f =~ /(\d.\d{3})(\d)(\d)/ ) {
    if ($3 >= 5) {
      $g = "$1" . ($2 + 1) ;
    } else {
      $g = $1 . $2 ;
    }
  } else {
    $g = $f ;
  }

  return($g) ;
}

sub _saveGraphToFile {
  my $graph = shift or carp "ERROR [_saveGraphToFile]: Need a chart!" ;
  my $fileName = shift or carp "ERROR [_saveGraphToFile]: Need a file name!" ;
  
  local(*OUT) ;
  my $extn = $graph->export_format() ;
  
  open(OUT, "> $fileName") or 
       carp "ERROR [_saveGraphToFile]: Can't write file $fileName.$extn: $!" ;
  binmode OUT ;
  print OUT $graph->gd->$extn() ;
  close OUT ;
  print STDERR "MESSAGE [_saveGraphToFile]: Wrote file $fileName\n" ;
  return(1) ;
}


1;
