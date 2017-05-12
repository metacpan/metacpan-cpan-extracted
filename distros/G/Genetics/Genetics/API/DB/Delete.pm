# GenPerl module 
#

# POD documentation - main docs before the code

=head1 NAME

Genetics::API::DB::Delete

=head1 SYNOPSIS

  use Genetics::API ;

  $api = new Genetics::API(DSN => {driver => "mysql",
				   host => $Host,
				   database => $Database},
                           user => $UserName,
                           password => $Password) ;

  foreach $id (@badGenotypeIDs ) {
    $rv = $api->deleteGenotype($id) ;
    defined $rv or print "Error deleting Genotype w/ ID $id\n" ;
  }

=head1 DESCRIPTION

The Genetics::API::DB packages provide an interface for the manipulation of 
GenPerl objects in a relational database.  This package contains the methods 
for deleting objects from the database.

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

package Genetics::API::DB::Delete ;

BEGIN {
  $ID = "Genetics::API::DB::Delete" ;
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
use vars qw(@ISA @EXPORT @EXPORT_OK $ID $VERSION $DEBUG) ;
use Carp ;
use Exporter ;

=head1 Inheritance

 Exporter           Make methods available to importing packages

=cut

@ISA = qw(Exporter) ;

@EXPORT = qw(deleteCluster deleteSubject deleteKindred deleteMarker deleteSNP 
	     deleteGenotype deleteStudyVariable deletePhenotype deleteFrequencySource 
             deleteHtMarkerCollection deleteHaplotype deleteDNASample deleteTissueSample 
             deleteMap _deleteObjectData _deleteAssayAttrs) ;
@EXPORT_OK = qw();

=head1 Public Methods

=head2 deleteCluster

  Function  : Delete a Genetics::Object::Cluster object from the database.
  Argument  : The id of the object to be deleted.
  Returns   : 1 on success, undef otherwise.
  Scope     : Public
  Comments  : 

=cut

sub deleteCluster {
  my($self, $id) = @_ ;
  my($actualType) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[deleteCluster] $id." ;

  ( $actualType ) = $dbh->selectrow_array("select objType from Object 
                                           where id = $id") ;
  if ( $actualType ne "Cluster") {
    carp " ->[deleteCluster] Object with ID = $id is not a Cluster!" ;
    return(undef) ;
  }

  # Object data
  $self->_deleteObjectData($id) ;
  # Cluster fields
  $dbh->do( "delete from Cluster 
             where clusterID = $id" ) ;
  # ClusterContents fields
  $dbh->do( "delete from ClusterContents 
             where clusterID = $id" ) ;
  
  $DEBUG and carp " ->[deleteCluster] End." ;
  
  return(1) ;
}

=head2 deleteSubject

  Function  : Delete a Genetics::Object::Subject object from the database.
  Argument  : The id of the object to be deleted.
  Returns   : 1 on success, undef otherwise.
  Scope     : Public

=cut

sub deleteSubject {
  my($self, $id) = @_ ;
  my($actualType) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[deleteSubject] $id." ;

  ( $actualType ) = $dbh->selectrow_array("select objType from Object 
                                           where id = $id") ;
  if ( $actualType ne "Subject") {
    carp " ->[deleteSubject] Object with ID = $id is not a Subject!" ;
    return(undef) ;
  }

  # Object 
  $self->_deleteObjectData($id) ;
  # Subject 
  $dbh->do( "delete from Subject 
             where subjectID = $id" ) ;
  # KindredSubject
  $dbh->do( "delete from KindredSubject 
             where subjectID = $id" ) ;

  $DEBUG and carp " ->[deleteSubject] End." ;

  return(1) ;
}

=head2 deleteKindred

  Function  : Delete a Genetics::Object::Kindred object from the database.
  Argument  : The id of the object to be deleted.
  Returns   : 1 on success, undef otherwise.
  Scope     : Public
  Comments  : 

=cut

sub deleteKindred {
  my($self, $id) = @_ ;
  my($actualType) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[deleteKindred] $id." ;

  ( $actualType ) = $dbh->selectrow_array("select objType from Object 
                                           where id = $id") ;
  if ( $actualType ne "Kindred") {
    carp " ->[deleteKindred] Object with ID = $id is not a Kindred!" ;
    return(undef) ;
  }

  # Object 
  $self->_deleteObjectData($id) ;
  # Kindred
  $dbh->do( "delete from Kindred 
             where kindredID = $id" ) ;
  # KindredSubject
  $dbh->do( "delete from KindredSubject 
             where subjectID = $id" ) ;
    
  $DEBUG and carp " ->[deleteKindred] End." ;

  return(1) ;
}

=head2 deleteMarker

  Function  : Delete a Genetics::Object::Marker object from the database.
  Argument  : The id of the object to be deleted.
  Returns   : 1 on success, undef otherwise.
  Scope     : Public
  Comments  : 

=cut

sub deleteMarker {
  my($self, $id) = @_ ;
  my($actualType, $seqID, $sth, $arrRef) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[deleteMarker] $id." ;

  ( $actualType ) = $dbh->selectrow_array("select objType from Object 
                                           where id = $id") ;
  if ( $actualType ne "Marker") {
    carp " ->[deleteMarker] Object with ID = $id is not a Marker!" ;
    return(undef) ;
  }

  # Object 
  $self->_deleteObjectData($id) ;
  # Sequence
  ( $seqID ) = $dbh->selectrow_array( "select sequenceID from SequenceObject 
                                       where seqObjectID = $id" ) ;
  if ( defined $seqID ) {
    $dbh->do( "delete from Sequence 
               where sequenceID = $seqID" ) ;
  }
  # SequenceObject
  $dbh->do( "delete from SequenceObject 
             where seqObjectID = $id" ) ;
  # ISCNMapLocation data
  $sth = $dbh->prepare( "select iscnMapLocID from SeqObjISCN 
                         where seqObjectID = $id" ) ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    $dbh->do( "delete from ISCNMapLocation 
               where iscnMapLocID = $$arrRef[0]" ) ;
  }
  $dbh->do( "delete from SeqObjISCN 
             where seqObjectID = $id" ) ;
  # Marker
  $dbh->do( "delete from Marker 
             where markerID = $id" ) ;
  # Allele
  $dbh->do( "delete from Allele 
             where poID = $id" ) ;
    
  $DEBUG and carp " ->[deleteMarker] End." ;
  
  return(1) ;
}

=head2 deleteSNP

  Function  : Delete a Genetics::Object::SNP object from the database.
  Argument  : The id of the object to be deleted.
  Returns   : 1 on success, undef otherwise.
  Scope     : Public
  Comments  : 

=cut

sub deleteSNP {
  my($self, $id) = @_ ;
  my($actualType, $seqID, $sth, $arrRef) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[deleteSNP] $id." ;

  ( $actualType ) = $dbh->selectrow_array("select objType from Object 
                                           where id = $id") ;
  if ( $actualType ne "SNP") {
    carp " ->[deleteMarker] Object with ID = $id is not a SNP!" ;
    return(undef) ;
  }

  # Object 
  $self->_deleteObjectData($id) ;
  # Sequence
  ( $seqID ) = $dbh->selectrow_array( "select sequenceID from SequenceObject 
                                       where seqObjectID = $id" ) ;
  if ( defined $seqID ) {
    $dbh->do( "delete from Sequence 
               where sequenceID = $seqID" ) ;
  }
  # SequenceObject
  $dbh->do( "delete from SequenceObject 
             where seqObjectID = $id" ) ;
  # ISCNMapLocation data
  $sth = $dbh->prepare( "select iscnMapLocID from SeqObjISCN 
                         where seqObjectID = $id" ) ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    $dbh->do( "delete from ISCNMapLocation 
               where iscnMapLocID = $$arrRef[0]" ) ;
  }
  $dbh->do( "delete from SeqObjISCN 
             where seqObjectID = $id" ) ;
  # SNP fields
  $dbh->do( "delete from SNP 
             where snpID = $id" ) ;
  # Allele
  $dbh->do( "delete from Allele 
             where poID = $id" ) ;
    
  $DEBUG and carp " ->[deleteSNP] End." ;

  return(1) ;
}

=head2 deleteGenotype

  Function  : Delete a Genetics::Object::Genotype object from the database.
  Argument  : The id of the object to be deleted.
  Returns   : 1 on success, undef otherwise.
  Scope     : Public
  Comments  : 

=cut

sub deleteGenotype {
  my($self, $id) = @_ ;
  my($actualType, $sth, $arrRef) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[deleteGenotype] $id." ;

  ( $actualType ) = $dbh->selectrow_array("select objType from Object 
                                           where id = $id") ;
  if ( $actualType ne "Genotype") {
    carp " ->[deleteGenotype] Object with ID = $id is not a Genotype!" ;
    return(undef) ;
  }

  # Object 
  $self->_deleteObjectData($id) ;
  # Genotype
  $dbh->do( "delete from Genotype 
             where gtID = $id" ) ;
  # Genotype AssayAttributes
  $dbh->do( "delete from AttributeValue 
             where objID = $id" ) ;
  # AlleleCall and AlleleCall AssayAttributes
  $sth = $dbh->prepare( "select alleleCallID from AlleleCall 
                         where gtID = $id" ) ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    $dbh->do( "delete from AttributeValue 
               where alleleCallID = $$arrRef[0]" ) ;
  }
  $dbh->do( "delete from AlleleCall 
             where gtID = $id" ) ;

  $DEBUG and carp " ->[deleteGenotype] End." ;

  return(1) ;
}

=head2 deleteStudyVariable

  Function  : Delete a Genetics::Object::StudyVariable object from the database.
  Argument  : The id of the object to be deleted.
  Returns   : 1 on success, undef otherwise.
  Scope     : Public
  Comments  : 

=cut

sub deleteStudyVariable {
  my($self, $id) = @_ ;
  my($actualType, $sth, $arrRef) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[deleteStudyVariable] $id." ;

  ( $actualType ) = $dbh->selectrow_array("select objType from Object 
                                           where id = $id") ;
  if ( $actualType ne "StudyVariable") {
    carp " ->[deleteStudyVariable] Object with ID = $id is not a StudyVariable!" ;
    return(undef) ;
  }

  # Object 
  $self->_deleteObjectData($id) ;
  # StudyVariable
  $dbh->do( "delete from StudyVariable 
             where studyVariableID = $id" ) ;
  # CodeDerivation and StaticLCPenetrance data
  $sth = $dbh->prepare(" select codeDerivationID from CodeDerivation 
                         where studyVariableID = $id" ) ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    $dbh->do( "delete from  StaticLCPenetrance
               where cdID = $$arrRef[0]" ) ;
  }
  $dbh->do( "delete from CodeDerivation 
             where studyVariableID = $id" ) ;
  # AffectionStatus data
  $sth = $dbh->prepare(" select asDefID from AffectionStatusDefinition 
                         where studyVariableID = $id" ) ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    $dbh->do( "delete from AffectionStatusElement 
               where asDefID = $$arrRef[0]" ) ;
  }
  $dbh->do( "delete from AffectionStatusDefinition 
             where studyVariableID = $id" ) ;
  # LiabilityClass data
  $sth = $dbh->prepare( "select lcDefID from LiabilityClassDefinition 
                         where studyVariableID = $id" ) ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    $dbh->do( "delete from LiabilityClass 
               where lcDefID = $$arrRef[0]" ) ;
  }
  $dbh->do( "delete from LiabilityClassDefinition 
             where studyVariableID = $id" ) ;

  $DEBUG and carp " ->[deleteStudyVariable] End." ;

  return(1) ;
}

=head2 deletePhenotype

  Function  : Delete a Genetics::Object::Phenotype object from the database.
  Argument  : The id of the object to be deleted.
  Returns   : 1 on success, undef otherwise.
  Scope     : Public
  Comments  : 

=cut

sub deletePhenotype {
  my($self, $id) = @_ ;
  my($actualType) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[deletePhenotype] $id." ;

  ( $actualType ) = $dbh->selectrow_array("select objType from Object 
                                           where id = $id") ;
  if ( $actualType ne "Phenotype") {
    carp " ->[deletePhenotype] Object with ID = $id is not a Phenotype!" ;
    return(undef) ;
  }

  # Object 
  $self->_deleteObjectData($id) ;
  # Phenotype
  $dbh->do( "delete from Phenotype 
             where ptID = $id" ) ;
  # Phenotype AssayAttributes
  $dbh->do( "delete from AttributeValue 
             where objID = $id" ) ;
  
  $DEBUG and carp " ->[deletePhenotype] End." ;

  return(1) ;
}

=head2 deleteFrequencySource

  Function  : Delete a Genetics::Object::FrequencySource object from the database.
  Argument  : The id of the object to be deleted.
  Returns   : 1 on success, undef otherwise.
  Scope     : Public
  Comments  : 

=cut

sub deleteFrequencySource {
  my($self, $id) = @_ ;
  my($actualType, $sth, $arrRef) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[deleteFrequencySource] $id." ;

  ( $actualType ) = $dbh->selectrow_array("select objType from Object 
                                           where id = $id") ;
  if ( $actualType ne "FrequencySource") {
    carp " ->[deleteFrequencySource] Object with ID = $id is not a FrequencySource!" ;
    return(undef) ;
  }

  # Object 
  $self->_deleteObjectData($id) ;
  # ObsFrequency data
  $sth = $dbh->prepare( "select obsFreqID from FreqSourceObsFrequency 
                         where freqSourceID = $id" ) ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    $dbh->do( "delete from ObsFrequency 
               where obsFreqID = $$arrRef[0]" ) ;
  }
  $dbh->do( "delete from FreqSourceObsFrequency 
             where freqSourceID = $id" ) ;

  $DEBUG and carp " ->[deleteFrequencySource] End." ;

  return(1) ;
}

=head2 deleteHtMarkerCollection

  Function  : Delete a Genetics::Object::HtMarkerCollection object from the database.
  Argument  : The id of the object to be deleted.
  Returns   : 1 on success, undef otherwise.
  Scope     : Public
  Comments  : 

=cut

sub deleteHtMarkerCollection {
  my($self, $id) = @_ ;
  my($actualType) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[deleteHtMarkerCollection] $id." ;

  ( $actualType ) = $dbh->selectrow_array("select objType from Object 
                                           where id = $id") ;
  if ( $actualType ne "HtMarkerCollection") {
    carp " ->[deleteHtMarkerCollection] Object with ID = $id is not a HtMarkerCollection!" ;
    return(undef) ;
  }

  # Object 
  $self->_deleteObjectData($id) ;
  # HtMarkerCollection
  $dbh->do( "delete from HtMarkerCollection 
             where hmcID = $id" ) ;
  # HMCPolyObj
  $dbh->do( "delete from HMCPolyObj 
             where hmcID = $id" ) ;

  $DEBUG and carp " ->[deleteHtMarkerCollection] End." ;

  return(1) ;
}

=head2 deleteHaplotype

  Function  : Delete a Genetics::Object::Haplotype object from the database.
  Argument  : The id of the object to be deleted.
  Returns   : 1 on success, undef otherwise.
  Scope     : Public
  Comments  : 

=cut

sub deleteHaplotype {
  my($self, $id) = @_ ;
  my($actualType) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[deleteHaplotype] $id." ;

  ( $actualType ) = $dbh->selectrow_array("select objType from Object 
                                           where id = $id") ;
  if ( $actualType ne "Haplotype") {
    carp " ->[deleteHaplotype] Object with ID = $id is not a Haplotype!" ;
    return(undef) ;
  }

  # Object 
  $self->_deleteObjectData($id) ;
  # Haplotype
  $dbh->do( "delete from Haplotype 
             where haplotypeID = $id" ) ;
  # HaplotypeAllele
  $dbh->do( "delete from HaplotypeAllele 
             where haplotypeID = $id" ) ;

  $DEBUG and carp " ->[deleteHaplotype] End." ;

  return(1) ;
}

=head2 deleteDNASample

  Function  : Delete a Genetics::Object::DNASample object from the database.
  Argument  : The id of the object to be deleted.
  Returns   : 1 on success, undef otherwise.
  Scope     : Public
  Comments  : 

=cut

sub deleteDNASample {
  my($self, $id) = @_ ;
  my($actualType) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[deleteDNASample] $id." ;

  ( $actualType ) = $dbh->selectrow_array("select objType from Object 
                                           where id = $id") ;
  if ( $actualType ne "DNASample") {
    carp " ->[deleteDNASample] Object with ID = $id is not a DNASample!" ;
    return(undef) ;
  }

  # Object 
  $self->_deleteObjectData($id) ;
  # Sample
  $dbh->do( "delete from Sample 
             where sampleID = $id" ) ;
  # DNASample
  $dbh->do( "delete from DNASample 
             where dnaSampleID = $id" ) ;
  # SubjectSample
  $dbh->do( "delete from SubjectSample 
             where sampleID = $id" ) ;
  # SampleGenotype data
  $dbh->do( "delete from SampleGenotype 
             where sampleID = $id" ) ;
  # TissueDNASample
  $dbh->do( "delete from TissueDNASample 
             where dnaSampleID = $id" ) ;

  $DEBUG and carp " ->[deleteDNASample] End." ;

  return(1) ;
}

=head2 deleteTissueSample

  Function  : Delete a Genetics::Object::TissueSample object from the database.
  Argument  : The id of the object to be deleted.
  Returns   : 1 on success, undef otherwise.
  Scope     : Public
  Comments  : 

=cut

sub deleteTissueSample {
  my($self, $id) = @_ ;
  my($actualType) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[deleteTissueSample] $id." ;

  ( $actualType ) = $dbh->selectrow_array("select objType from Object 
                                           where id = $id") ;
  if ( $actualType ne "TissueSample") {
    carp " ->[deleteTissueSample] Object with ID = $id is not a TissueSample!" ;
    return(undef) ;
  }

  # Object 
  $self->_deleteObjectData($id) ;
  # Sample
  $dbh->do( "delete from Sample 
             where sampleID = $id" ) ;
  # TissueSample
  $dbh->do( "delete from TissueSample 
             where tissueSampleID = $id" ) ;
  # SampleSubject
  $dbh->do( "delete from SampleSubject 
             where sampleID = $id" ) ;
  # SampleGenotype
  $dbh->do( "delete from SampleGenotype 
             where sampleID = $id" ) ;
  # TissueDNASample
  $dbh->do( "delete from TissueDNASample 
             where tissueSampleID = $id" ) ;

  $DEBUG and carp " ->[deleteTissueSample] End." ;

  return(1) ;
}

=head2 deleteMap

  Function  : Delete a Genetics::Object::Map object from the database.
  Argument  : The id of the object to be deleted.
  Returns   : 1 on success, undef otherwise.
  Scope     : Public
  Comments  : 

=cut

sub deleteMap {
  my($self, $id) = @_ ;
  my($actualType) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[deleteMap] $id." ;

  ( $actualType ) = $dbh->selectrow_array("select objType from Object 
                                           where id = $id") ;
  if ( $actualType ne "Map") {
    carp " ->[deleteMap] Object with ID = $id is not a Map!" ;
    return(undef) ;
  }

  # Object 
  $self->_deleteObjectData($id) ;
  # Map
  $dbh->do( "delete from Map 
             where mapID = $id" ) ;
  # OrderedMapElement
  $dbh->do( "delete from OrderedMapElement 
             where mapID = $id" ) ;

  $DEBUG and carp " ->[deleteMap] End." ;

  return(1) ;
}

=head1 Private methods

=head2 _deleteObjectData

  Function  : Delete data common to all Genetics::Object objects to the database.
  Argument  : A Genetics::Object ID.
  Returns   : 1 on success, undef otherwise.
  Scope     : Private
  Called by : The various deleteObjectSubClass methods.

=cut

sub _deleteObjectData {
  my($self, $id) = @_ ;
  my($rv) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[_deleteObjectData] $id" ;

  # Delete from Object
  $rv = $dbh->do( "delete from Object 
                   where id = $id" ) ;
  if ( ! defined $rv ) {
    carp " ->[_deleteObjectData] Delete from Object failed for ID $id" ;
    return(undef) ;
  }
  # Delete from NameAlias
  $dbh->do( "delete from NameAlias 
             where objID = $id" ) ;
  # Delete from DBXReference
  $dbh->do( "delete from DBXReference 
             where objID = $id" ) ;
  # Delete from Keyword
  $dbh->do( "delete from Keyword 
             where objID = $id" ) ;

  $DEBUG and carp " ->[_deleteObjectData] End" ;

  return(1) ;
}

1;

