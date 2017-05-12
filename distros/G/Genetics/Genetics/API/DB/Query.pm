# GenPerl module 
#

# POD documentation - main docs before the code

=head1 NAME

Genetics::API::DB::Query

=head1 SYNOPSIS

  use Genetics::API ;

  $api = new Genetics::API(DSN => {driver => "mysql",
				   host => $Host,
				   database => $Database},
                           user => $UserName,
                           password => $Password) ;

  $sv = $api->getObject({TYPE => "StudyVariable", 
			 NAME => "Aff", 
			 FULL => 1}) ;

  @affSubjects = $api->getSubjectsByPhenotype($sv, 2) ;

  @kindreds = $api->getObjects({TYPE => "Kindred"}) ;

  @d1s = $api->getObjects({TYPE => "Marker", Name => "D1S*"}) ;

=head1 DESCRIPTION

The Genetics::API::DB packages provide an interface for the manipulation of 
Genperl objects in a realtional database.  This package contains methods to 
query for and return objects based on attributes/relationships other than id 
(for methods to do that, see Genetics::API::DB::Read).

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

package Genetics::API::DB::Query ;

BEGIN {
  $ID = "Genetics::API::Query" ;
  #$DEBUG = $main::DEBUG ;
  $DEBUG = 0 ;
  $DEBUG and warn "Debugging in $ID is on" ;
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

@EXPORT = qw(getObject getObjects countObjects
	     getClusterContents getClustersByType 
	     getSubjectsByPhenotype getSiblings getSubjectsByKindred 
	     getFounders getPOsByChromosome 
	     getPhenotypesBySubject getGenotypesBySubject 
	     getAllelesByType getPOAllelesByType 
	     getAlleleCounts getAlleleFreqs getSNPGtCounts 
	     getGtAlleles getGtAllelesByGt 
	     getPtValue 
	     _generateSQL) ;
@EXPORT_OK = qw();

=head1 Public Methods

=head2 getObject

  Function  : Get and return Genetics::Object object(s) based on a set of query 
              parameters.. 
  Arguments : A reference to a hash containing the query parameters:
                %query = (
                          ID => integer
                          TYPE => Object type
                          NAME => text
			  WHERE => SQL where clause
			  FULL => Boolean
                         )
              If $query{FULL} is false (the default) mini objects returned.
  Returns   : A Genetics::Object object, or undef there are zero or more than 
              one that satisfy the query parameters.
  Scope     : Public
  Comments  : This is experimental and the interface may change.
              If the NAME parameter contains Perl wildcard characters * or ?, 
              these are converted to the SQL wildcards % and _.  This hopefully 
              results in the expected behavior.

=cut

sub getObject {
  my($self, $qPtr) = @_ ;
  my($sql, $sth, $arrayRef, $returnCount, $row, $id, $type, 
     $methodName, $methodRef, $obj) ;
  my $dbh = $self->{dbh} ;
  
  $sql = $self->_generateSQL($qPtr) or 
               croak "ERROR [getObject]: Could not process query parameters!" ;

  $sth = $dbh->prepare( "$sql" ) ;
  $sth->execute() ;
  $arrayRef = $sth->fetchall_arrayref() ;  
  $returnCount = scalar(@$arrayRef) ;
  if ( $returnCount == 0 ) {
    carp "WARNING [getObject]: No object matching query:\n$sql\n" ;
    return(undef) ;
  } elsif ( $returnCount > 1) {
    croak "ERROR [getObject]: Query:\n$sql\nfound $returnCount objects!" ;
  } 
  $row = shift(@$arrayRef) ;
  ( $id, $type ) = @$row ;

  $$qPtr{FULL} ? ($methodName = "Genetics::API::get" . $type) 
               : ($methodName = "Genetics::API::getMini" . $type) ;
  $methodRef = \&$methodName ;
  $DEBUG and carp " ->[getObject] calling $methodName($id)" ;
  $obj = &$methodRef($self, $id) ;

  return($obj) ;
}

=head2 getObjects

  Function  : Get and return Genetics::Object object(s) based on a set of query 
              parameters.. 
  Arguments : A reference to a hash containing the query parameters:
                %query = (
                          TYPE => Object type
                          NAME => text
			  KW => {KeywordType.name => Keyword.value}
                          WHERE => SQL where clause
			  FULL => Boolean
                         )
              If $query{FULL} is false (the default) mini objects returned.
  Returns   : An array of Genetics::Object object(s) which satisfy the query 
              parameters, or undef if there are none.
  Scope     : Public
  Comments  : This is experimental and the interface may change.
              If the NAME parameter contains Perl wildcard characters * or ?, 
              these are converted to the SQL wildcards % and _.  This hopefully 
              results in the expected behavior.

=cut

sub getObjects {
  my($self, $qPtr) = @_ ;
  my($sql, $sth, $arrayRef, $row, $id, $type, $methodName, $methodRef, 
     $obj, @objects) ;
  my $dbh = $self->{dbh} ;

  $sql = $self->_generateSQL($qPtr) or 
              croak "ERROR [getObjects]: Could not process query parameters!" ;

  $sth = $dbh->prepare( "$sql" ) ;
  $sth->execute() ;
  $arrayRef = $sth->fetchall_arrayref() ;

  if (scalar(@$arrayRef) == 0) {
    carp "WARNING [getObjects]: No objects matching query:\n$sql\n" ;
    return(undef) ;
  }

  foreach $row (@$arrayRef) {
    ( $id, $type ) = @$row ;
    $$qPtr{FULL} ? ($methodName = "Genetics::API::get" . $type) 
                 : ($methodName = "Genetics::API::getMini" . $type) ;
    $methodRef = \&$methodName ;
    $DEBUG and carp " ->[getObjects] calling $methodName($id)" ;
    $obj = &$methodRef($self, $id) ;
    push(@objects, $obj) ;
  }

  return(@objects) ;
}

=head2 countObjects

  Function  : Return the count of Genetics::Object object(s) that match a set 
              of query parameters.
  Arguments : A reference to a hash containing the query parameters:
                %query = (
                          TYPE => Object type
                          NAME => text
                          WHERE => SQL where clause
                         )
  Returns   : Scalar
  Scope     : Public
  Comments  : 

=cut

sub countObjects {
  my($self, $qPtr) = @_ ;
  my($sql, $arrayRef) ;
  my $dbh = $self->{dbh} ;

  $sql = $self->_generateSQL($qPtr) or 
              croak "ERROR [getObjects]: Could not process query parameters!" ;

  $arrayRef = $dbh->selectall_arrayref( "$sql" ) ;

  return(scalar(@$arrayRef)) ;
}

=head2 getClusterContents

  Function  : Get the objects referenced by a Cluster.
  Argument  : A Genetics::Cluster object
  Returns   : A list of Genetics::Object objects.
  Scope     : Public
  Comments  : 

=cut

sub getClusterContents {
  my($self, $cluster, $miniFlag) = @_ ;
  my($contentsListPtr, $type, $methodName, $methodRef, $ptr, $obj, @contents) ;
  my $dbh = $self->{dbh} ;

  defined($miniFlag) or $miniFlag = 0 ;

  $contentsListPtr = $cluster->field("Contents") ;
  $type = $cluster->field("clusterType") ;
  $type eq "Mixed" and croak "ERROR [getClusterContents]: Mixed Clusters not supported." ;
  $miniFlag == 1 ? ($methodName = "Genetics::API::getMini" . $type) 
                 : ($methodName = "Genetics::API::get" . $type) ;
  $methodRef = \&$methodName ;

  foreach $ptr (@$contentsListPtr) {
    $obj = &$methodRef($self, $$ptr{id}) ;
    push(@contents, $obj) ;
  }

  return(@contents) ;
}

=head2 getClustersByType

 Function  : 
 Arguments : 
 Returns   : 
 Example   : getClustersByType()
 Scope     : 
 Comments  : 

=cut

sub getClustersByType {
  my($self, $clusterType) = @_ ;
  my($sth, $arrRef, @clusters) ;
  my $dbh = $self->{dbh} ;
  
  $sth = $dbh->prepare("select id from Object, Cluster 
                        where clusterType = '$clusterType' and 
                        id = clusterID") ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    push(@clusters, $self->getCluster($$arrRef[0])) ;
  }

  return(@clusters) ;
}

=head2 getFounders

  Function  : Query for and return the founders (Subjects without parents) in a 
              Kindred.
  Argument  : A Genetics::Kindred object.
  Returns   : A list of Genetics::Subject objects.
              
  Scope     : Public
  Comments  : 

=cut

sub getFounders {
  my($self, $kindred) = @_ ;
  my(@subjects, $subject, @founders) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[getFounders] $kindred" ;

  @subjects = $self->getSubjectsByKindred($kindred) ;
  foreach $subject (@subjects) {
    #$DEBUG and carp " ->[getFounders] Checking $subject" ;
    if ( ! $subject->hasParents()) {
      push(@founders, $subject) ;
    }
  }

  return(@founders) ;
}

=head2 getSubjectsByPhenotype

  Function  : Query for Subjects based on their associated Phenotype values.
  Argument  : A Genetics::Object::StudyVariable object and a phenotype value.
  Returns   : Genetics::Object::Subject objects that have associated Phenotypes 
              with the query value.
  Scope     : Public
  Comments  : 

=cut

sub getSubjectsByPhenotype {
  my($self, $sv, $queryValue) = @_ ;
  my($format, $valueFieldName, $sth, $arrRef, @subjects) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[getSubjectsByPhenotype] Start" ;

  $format = $sv->field("format") ;
  $valueFieldName = lc($format) . "Value" ;
  
  $sth = $dbh->prepare("select subjectID from Phenotype 
                        where $valueFieldName = '$queryValue'") ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    push(@subjects, $self->getSubject($$arrRef[0])) ;
  }
  
  return(@subjects) ;
}

=head2 getPhenotypesBySubject

  Function  : Query for Phenotypes based on their associated Subject.
  Argument  : A Genetics::Object::Subject object.
  Returns   : Genetics::Object::Phenotype objects.
  Scope     : Public
  Comments  : Returns only active Phenotypes.

=cut

sub getPhenotypesBySubject {
  my($self, $subject) = @_ ;
  my($format, $subjID, $sth, $arrRef, @pts) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[getPhenotypesBySubject] Start" ;

  $subjID = $subject->id() ;
  $sth = $dbh->prepare("select ptID from Phenotype 
                        where subjectID = $subjID") ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    push(@pts, $self->getPhenotype($$arrRef[0])) ;
  }
  
  return(@pts) ;
}

=head2 getGenotypesBySubject

  Function  : Query for Genotypes based on their associated Subject.
  Argument  : A Genetics::Object::Subject object.
  Returns   : An array of Genetics::Object::Genotype objects.
  Scope     : Public
  Comments  : Returns only the active Genotypes.

=cut

sub getGenotypesBySubject {
  my($self, $subject) = @_ ;
  my($format, $subjID, $sth, $arrRef, @gts) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[getGenotypesBySubject] Start" ;

  $subjID = $subject->id() ;
  $sth = $dbh->prepare("select gtID from Genotype 
                        where subjectID = $subjID") ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    push(@gts, $self->getGenotype($$arrRef[0])) ;
  }
  
  return(@gts) ;
}

=head2 getSubjectsByKindred

  Function  : Query for and return all the Subjects in a Kindred.
  Argument  : A Kindred object
  Returns   : A list of Subject objects
  Scope     : Public
  Comments  : 

=cut

sub getSubjectsByKindred {
  my($self, $kindred) = @_ ;
  my($kindredID, $sth, $arrRef, @subjects) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[getSubjectsByKindred] Start" ;

  $kindredID = $kindred->field("id") ;
  
  $sth = $dbh->prepare("select subjectID from KindredSubject 
                        where kindredID = $kindredID") ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    push(@subjects, $self->getSubject($$arrRef[0])) ;
  }
  
  return(@subjects) ;
}

=head2 getSiblings

  Function  : Query for and return all the siblings of a Subject.
  Argument  : A Subject object
  Returns   : A list of Subject objects
  Scope     : Public
  Comments  : 

=cut

sub getSiblings {
  my($self, $subject) = @_ ;
  my($subjectID, $momID, $dadID, $sth, $arrRef, @siblings) ;
  my $dbh = $self->{dbh} ;

  $subjectID = $subject->field("id") ;

  ($momID, $dadID) = $dbh->selectrow_array( "select motherID, fatherID 
                                             from Subject 
                                             where subjectID = $subjectID" ) ;

  $sth = $dbh->prepare( "select subjectID from Subject 
                         where motherID = $momID 
                         and fatherID = $dadID
                         and subjectID != $subjectID" ) ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    
    push(@siblings, $self->getSubject($$arrRef[0])) ;
  }

  return(@siblings) ;
}

=head2 getPOsByChromosome

 Function  : 
 Arguments : 
 Returns   : 
 Example   : getPOsByChromosome()
 Scope     : 
 Comments  : Right now this returns all SequenceObject types.  This works 
             because all SequenceObject types are also PolymorphicObjects.  
             It will have to be modified if new SequenceObject types are 
             introduced that are not also PolymorphicObjects.

=cut

sub getPOsByChromosome {
  my($self, $chr) = @_ ;
  my($sth, $arrRef, @markers) ;
  my $dbh = $self->{dbh} ;
  
  $sth = $dbh->prepare("select id from Object, SequenceObject 
                        where id = seqObjectID and chromosome = '$chr'") ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    push(@markers, $self->getMarker($$arrRef[0])) ;
  }

  return(@markers) ;
}

=head2 getAllelesByType

  Function  : Query for and return a Markers allele names, by type.
  Argument  : A Marker or SNP object and a string containing an allele type.
  Returns   : An array of allele names.
  Scope     : Public
  Comments  : The returned allele names are sorted, first numerically then 
              alphabetically.

=cut

sub getAllelesByType {
  my($self, $po, $alleleType) = @_ ;
  my($poID, $sth, $aoaRef, $row, @alleleNames, @sortedAlleleNames, ) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[getAllelesByType] $po, $alleleType" ;

  $poID = $po->field("id") ;

  $sth = $dbh->prepare( "select name from Allele
                         where poID = $poID 
                         and type = '$alleleType'" ) ;
  $sth->execute() ;
  $aoaRef = $sth->fetchall_arrayref() ;
  foreach $row (@$aoaRef) {
    push(@alleleNames, $$row[0]) ;
  }

  if ($alleleType =~ /^(Code|Size|RepeatNumber)$/) {
    @sortedAlleleNames = sort { $a <=> $b} @alleleNames ;
  } else {
    @sortedAlleleNames = sort @alleleNames ;
  }

  return(@sortedAlleleNames) ;
}

=head2 getPOAllelesByType

  Function  : Query for and return a Markers alleles by type.
  Argument  : A Marker or SNP object and a string containing an allele type.
  Returns   : An array of allele names.
  Scope     : Public
  Comments  : The returned allele names are sorted, first numerically then 
              alphabetically.

=cut

sub getPOAllelesByType {
  my($self, $po, $alleleType) = @_ ;
  my($poID, $sth, $aoaRef, $row, @alleleNames, @sortedAlleleNames, ) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[getPOAllelesByType] $po, $alleleType" ;

  $poID = $po->field("id") ;

  $sth = $dbh->prepare( "select name, alleleID from Allele
                         where poID = $poID 
                         and type = '$alleleType'" ) ;
  $sth->execute() ;
  $aoaRef = $sth->fetchall_arrayref() ;
  foreach $row (@$aoaRef) {
    push(@alleleNames, $$row[0]) ;
  }

  @sortedAlleleNames = sort { $a <=> $b or $a cmp $b } @alleleNames ;
  
  return(@sortedAlleleNames) ;
}

=head2 getAlleleCounts

  Function  : Query for and return raw allele counts.
  Argument  : A Marker or SNP object, a string containing an allele type, and 
              a Subject Cluster object.
  Returns   : Hash pointer.  The hash structure is:
                     $count{AlleleName} = $number
  Scope     : Public
  Comments  : 

=cut

sub getAlleleCounts {
  my($self, $marker, $alleleType, $sc) = @_ ;
  my($markerID, $sth, $aoaRef, $row, %alleleName2ID, @alleleNames, 
     $contentsListPtr, $subjPtr, $gtID, $alleleName, %count) ;
  my $dbh = $self->{dbh} ;

  $markerID = $marker->field("id") ;

  $sth = $dbh->prepare( "select name, alleleID from Allele
                         where poID = $markerID 
                         and type = '$alleleType'" ) ;
  $sth->execute() ;
  $aoaRef = $sth->fetchall_arrayref() ;
  foreach $row (@$aoaRef) {
    push(@alleleNames, $$row[0]) ;
    $alleleName2ID{$$row[0]} = $$row[1] ;
  }

  $sth = $dbh->prepare( "select alleleCallID from AlleleCall 
                         where gtID = ? 
                         and alleleID = ?" ) ;

  $contentsListPtr = $sc->field("Contents") ;
  foreach $subjPtr (@$contentsListPtr) {
    # foreach Subject, get the active Genotype for this Marker...
    ($gtID) = $dbh->selectrow_array( "select gtID from Genotype 
                                      where isActive = 1 
                                      and subjectID = $$subjPtr{id} 
                                      and poID = $markerID" ) ;
    defined($gtID) or next ;

    # ...then get the count of each Allele in that Genotype...
    foreach $alleleName (@alleleNames) {
      $sth->execute($gtID, $alleleName2ID{$alleleName}) ;
      $aoaRef = $sth->fetchall_arrayref() ;
      # ...and add it to the total for that allele in this cluster
      $count{$alleleName} += scalar(@$aoaRef) ;
    }
  }
  $sth->finish() ;

  return( { %count } ) ;
}

=head2 getAlleleFreqs

  Function  : Query for and return the allele frequencies for a group of Subjects.
  Argument  : A Marker object, a string containing an allele type, and one of 
              the following defining the Subject group:
                - a Subject Cluster object 
                - an array reference to a list of Subject objects
                - a Kindred Cluster object 
                - an array reference to a list of Kindred objects
  Returns   : Hash reference to a hash with the following structure:
                $freqs{AlleleName} = $number
  Scope     : Public
  Comments  : 

=cut

sub getAlleleFreqs {
  my($self, $marker, $alleleType, $sg) = @_ ;
  my($markerID, $markerName, $sth, $aoaRef, $row, %alleleName2ID, @alleleNames, 
     $type, $obj, $contentsListPtr, $ptr, $kindred, $subject, @subjects, 
     @subjIDs, $subjID, $gtID, $alleleName, %count, $totalAlleleCounts, %freqs, 
     $freq) ;
  my $dbh = $self->{dbh} ;

  defined($alleleType) or $alleleType = "Code" ;

  $DEBUG and carp " ->[getAlleleFreqs] $marker, $alleleType, $sg" ;

  $markerID = $marker->field("id") ;

  $sth = $dbh->prepare( "select name, alleleID from Allele
                         where poID = $markerID 
                         and type = '$alleleType'" ) ;
  $sth->execute() ;
  $aoaRef = $sth->fetchall_arrayref() ;
  foreach $row (@$aoaRef) {
    next if ($alleleType eq "Nucleotide" and $$row[0] eq "N") ;
    push(@alleleNames, $$row[0]) ;
    $alleleName2ID{$$row[0]} = $$row[1] ;
  }

  if (ref($sg) eq "Genetics::Cluster") {
    $type = $sg->field("clusterType") ;
    $contentsListPtr = $sg->field("Contents") ;
    if ($type eq "Subject") {
      foreach $ptr (@$contentsListPtr) {
	push @subjIDs, $$ptr{id} ;
      }
    } elsif ($type eq "Kindred") {
      foreach $ptr (@$contentsListPtr) {
	$kindred = $self->getKindred($$ptr{id}) ;
	@subjects = $self->getSubjectsByKindred($kindred) ;
	foreach $subject (@subjects) {
	  push @subjIDs, $subject->field("id") ;
	}
      }
    } else {
      croak "ERROR [getAlleleFreqs]: Invalid Cluster $sg." ;
    }
  } elsif (ref($sg) eq "ARRAY") {
    foreach $obj (@$sg) {
      if (ref($obj) eq "Genetics::Subject") {
	push @subjIDs, $obj->field("id") ;
      } elsif (ref($obj) eq "Genetics::Kindred") {
	@subjects = $self->getSubjectsByKindred($obj) ;
	foreach $subject (@subjects) {
	  push @subjIDs, $subject->field("id") ;
	}
      } else {
	carp "WARNING [getAlleleFreqs]: Skipping invalid object $obj in Cluster $sg" ;
      }
    }
  } else {
    croak "ERROR [getAlleleFreqs]: Unsupported subject sample type: $sg" ;
  }
  
  $sth = $dbh->prepare( "select alleleCallID from AlleleCall 
                         where gtID = ? 
                         and alleleID = ?" ) ;

  foreach $subjID (@subjIDs) {
    # foreach Subject, get the active Genotype for this Marker...
    ($gtID) = $dbh->selectrow_array( "select gtID from Genotype 
                                      where isActive = 1 
                                      and subjectID = $subjID 
                                      and poID = $markerID" ) ;
    defined($gtID) or next ;
    # ...then get the count of each Allele in that Genotype...
    foreach $alleleName (@alleleNames) {
      $sth->execute($gtID, $alleleName2ID{$alleleName}) ;
      $aoaRef = $sth->fetchall_arrayref() ;
      # ...and add it to the total for that allele in this cluster
      $count{$alleleName} += scalar(@$aoaRef) ;
      $totalAlleleCounts += scalar(@$aoaRef) ;
    }
  }
  $sth->finish() ;

  foreach $alleleName (@alleleNames) {
    $freq = $count{$alleleName} / $totalAlleleCounts ;
    $freqs{$alleleName} = &_formatFloat($freq) ;
  }

  return( \%freqs ) ;
}

=head2 getGtAlleles

  Function  : For a given Subject and Marker, query for and return the allele 
              names from the active Genotype.
  Argument  : A Subject object and a Marker object
  Returns   : An array containing the allele names or undef if there is not an 
              active Genotype associated with the input Subject and Marker.
  Scope     : Public
  Comments  : 

=cut

sub getGtAlleles {
  my($self, $subject, $marker) = @_ ;
  my($sth, $subjectID, $markerID, $gtID, $alleleID, $alleleName, @alleles) ;
  my $dbh = $self->{dbh} ;

  $sth = $dbh->prepare( "select alleleID from AlleleCall 
                           where gtID = ?" ) ; 
  
  $subjectID = $subject->field("id") ;
  $markerID = $marker->field("id") ;
  ($gtID) = $dbh->selectrow_array( "select gtID from Genotype
                                    where isActive = 1 
                                    and subjectID =  $subjectID
                                    and poID = $markerID" ) ;
  defined($gtID) or return(undef) ; 
  $sth->execute($gtID) ;
  while ( ($alleleID) = $sth->fetchrow_array() ) {
    ($alleleName) = $dbh->selectrow_array( "select name from Allele 
                                            where alleleID = $alleleID" ) ;
    push(@alleles, $alleleName) ;
  }

  return(@alleles) ;
}

=head2 getSNPGtCounts

 Function  : 
 Arguments : 
 Returns   : 
 Example   : getSNPGtCounts()
 Scope     : 
 Comments  : 

=cut

sub getSNPGtCounts {
  my($self, $snp, $sc) = @_ ;
  my($snpID, $snpName, $clusterName, $cListPtr, $subjPtr, $gtID, $allelesStr, 
     %allCounts, %noNCounts, @alleles, $i, $gt1, $gt2, $gt3, ) ;
  my $dbh = $self->{dbh} ;

  if ( ref($snp) ne "Genetics::SNP" ) {
    croak "ERROR [getSNPGtCounts]: Invalid input SNP $snp." ;
  }
  $snpID = $snp->id() ;
  $snpName = $snp->name() ;
  if ( ref($sc) ne "Genetics::Cluster" ) {
    croak "ERROR [calculateHW]: Invalid input Cluster $sc." ;
    if ( $sc->clusterType() ne "Subject" ) {
      croak "ERROR [getSNPGtCounts]: Invalid input Cluster type." ;
    }
  }
  $clusterName = $sc->name() ;
  $cListPtr = $sc->Contents() ;
  foreach $subjPtr (@$cListPtr) {
    ($gtID) = $dbh->selectrow_array( "select gtID from Genotype 
                                      where isActive = 1 
                                      and subjectID = $$subjPtr{id} 
                                      and poID = $snpID" ) ;
    next unless defined($gtID) ;
    $allelesStr = join "", $self->getGtAllelesByGt($gtID) ;
    $allCounts{$allelesStr}++ ; # %allCounts includes gts w/ Ns
  }
  @alleles = $self->getAllelesByType($snp, "Nucleotide") ;
  for ($i=0 ; $i<=$#alleles ; $i++) {
    splice(@alleles, $i, 1) if $alleles[$i] eq "N" ;
  }
  $gt1 = $alleles[0] . $alleles[0] ;
  $noNCounts{$gt1} = $allCounts{$gt1} || 0 ;
  $gt2 = $alleles[0] . $alleles[1] ;
  $noNCounts{$gt2} = $allCounts{$gt2} || 0 ;
  $gt3 = $alleles[1] . $alleles[1] ;
  $noNCounts{$gt3} = $allCounts{$gt3} || 0 ;

  return( {%noNCounts} ) ;
}

=head2 getGtAllelesByGt

  Function  : For a given genotype, query for and return the allele names.
  Argument  : A Genotype object or id.
  Returns   : An array containing the allele names or undef if there is not an 
              active Genotype associated with the input Subject and Marker.
  Scope     : Public
  Comments  : 

=cut

sub getGtAllelesByGt {
  my($self, $arg) = @_ ;
  my($gtID, $sth, $alleleID, $alleleName, @alleles, ) ;
  my $dbh = $self->{dbh} ;

  ref($arg) eq "Genetics::Genotype" ? ($gtID = $arg->id())
				    : ($gtID = $arg) ;

  $sth = $dbh->prepare( "select alleleID from AlleleCall 
                         where gtID = ?" ) ;
  $sth->execute($gtID) ;
  while ( ($alleleID) = $sth->fetchrow_array() ) {
    ($alleleName) = $dbh->selectrow_array( "select name from Allele 
                                            where alleleID = $alleleID" ) ;
    push(@alleles, $alleleName) ;
  }

  return(@alleles) ;
}

=head2 getPtValue

  Function  : For a given Subject and StudyVariable, query for and return the 
              associated Phenotype value for the active Phenotype.
  Argument  : A Subject object and a StudyVariable object
  Returns   : An scalar containing the Phenotype value or undef if there is not 
              an active Phenotype associated with the input Subject and 
              StudyVariable.
  Scope     : Public
  Comments  : 

=cut

sub getPtValue {
  my($self, $subject, $sv) = @_ ;
  my($subjectID, $svID, $format, $valueFieldName, $value) ;
  my $dbh = $self->{dbh} ;

  $subjectID = $subject->field("id") ;
  $svID = $sv->field("id") ;
  $format = $sv->field("format") ;
  $valueFieldName = lc($format) . "Value" ;
  
  ($value) = $dbh->selectrow_array( "select $valueFieldName from Phenotype
                                     where isActive = 1 
                                     and subjectID =  $subjectID
                                     and svID = $svID" ) ;
  defined($value) or return(undef) ; 

  return($value) ;
}

=head1 Private Methods

=head2 _generateSQL

  Function  : Generate SQL based on a hash reference of query parameters.
  Arguments : A reference to a hash containing the query parameters:
                %query = (
                          ID => integer
                          TYPE => Object type
                          NAME => text
			  KW => KeywordType.name=Keyword.value
			  WHERE => SQL where clause
                         )
  Returns   : A string containing the SQL.
  Scope     : Private instance method
  Called by : getObject() and getObjects()
  Comments  : If the NAME parameter contains Perl wildcard characters * or ?, 
              these are converted to the SQL wildcards % and _.  This hopefully 
              results in the expected behavior.
              NB. KW can only be used by itself or combined with TYPE

=cut

sub _generateSQL {
  my($self, $qPtr) = @_ ;
  my $dbh = $self->{dbh} ;
  my($sql, $id, $type, $name, $likeFlag, $where, $kwQStr, 
     $kwtName, $kwValue, $kwtID, $dataType, $kwvFieldName) ;

  # Construct the SQL.  Probably there is a more clever way to do this.
  defined($id = $$qPtr{ID}) or $id = 0 ;
  defined($type = $$qPtr{TYPE}) or $type = 0 ;
  if ( defined($name = $$qPtr{NAME}) ) {
    $likeFlag = $name =~ tr/*?/%_/ ;
  } else {
    $name = 0 ;
  }
  if ( defined($where = $$qPtr{WHERE}) ) {
    $where =~ s/^\s*where\s+//i ;
  } else {
    $where = 0 ;
  }
  if ( defined($kwQStr = $$qPtr{KW}) ) {
    ($kwtName, $kwValue) = $kwQStr =~ /^([\w ]+)=([\w ]+)/ ;
    ($kwtID, $dataType) = $dbh->selectrow_array( "select keywordTypeID, dataType 
                                                  from KeywordType 
                                                  where name = '$kwtName'" ) ;
    $kwvFieldName = "kw." . lc($dataType) . "Value" ;
  } else {
    $kwQStr = 0 ;
  }

  if ($id) {
    # Query by id only
    $sql = "select id, objType from Object where id = $id" ;
  } else {
    $sql = "select id, objType from Object " ;
    if ($type) {
      if ($name) {
	if ($where) {
	  # Query by type, name and input where clause
	  $likeFlag ? ($sql .= "where objType = '$type' and name like '$name' and $where") 
	            : ($sql .= "where objType = '$type' and name = '$name' and $where") ;
	} elsif ($kwQStr) {
	  # Query by type, name and keyword
	  return(undef) ;
	} else {
	  # Query by type and name
	  $likeFlag ? ($sql .= "where objType = '$type' and name like '$name'") 
                    : ($sql .= "where objType = '$type' and name = '$name'") ;
	}
      } else {
	if ($where) {
	  # Query by type and input where clause
	  $sql .= "where objType = '$type' and $where" ;
	} elsif ($kwQStr) {
	  # Query by type and keyword
	  $sql = "select obj.id, obj.objType from Object obj, Keyword kw 
                  where objType = '$type' and 
                  kw.keywordTypeID = $kwtID and 
                  $kwvFieldName = '$kwValue' and 
                  obj.id = kw.objID" ;
	} else {
	  # Query by type only.
	  $sql .= "where objType = '$type'" ;
	}
      }
    } elsif ($name) {
      if ($where) {
	# Query by name and input where clause
	$likeFlag ? ($sql .= "where name like '$name' and $where")
                  : ($sql .= "where name = '$name' and $where") ;
      } elsif ($kwQStr) {
	# Query by name and keyword
	return(undef) ;
      } else {
	# Query by name only
	$likeFlag ? ($sql .= "where name like '$name'")
                  : ($sql .= "where name = '$name'") ;
      }
    } elsif ($where) {
      # Query by input where clause only
      return(undef) if $kwQStr ;
      $sql .= "where $where" ;
    } elsif ($kwQStr) {
      # Query by keyword only
      $sql = "select obj.id, obj.objType from Object obj, Keyword kw 
              where kw.keywordTypeID = $kwtID and 
              $kwvFieldName = '$kwValue' and 
              obj.id = kw.objID" ;
    } else {
      carp "WARNING [_generateSQL]: Insufficient query criteria!" ;
      return(undef) ;
    }
  }
  #print " ->[_generateSQL] SQL: $sql\n" ;
  $DEBUG and carp " ->[_generateSQL] SQL: $sql" ;

  return($sql) ;
}

sub _formatFloat {
  my($f) = @_;
  my($g) ;

  if ( $f =~ /(0.\d{3})(\d)(\d)/ ) {
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

1;
