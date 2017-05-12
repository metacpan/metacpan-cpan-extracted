# GenPerl module 
#

# POD documentation - main docs before the code

=head1 NAME

Genetics::API::DB::Update

=head1 SYNOPSIS

  use Genetics::API ;

  $api = new Genetics::API(DSN => {driver => "mysql",
				   host => $Host,
				   database => $Database},
                           user => $UserName,
                           password => $Password) ;

  $subject = $api->getSubject(3) ;
  $subject->name("Elvis") ;
  $api->updateSubject($subject) ;

=head1 DESCRIPTION

The Genetics::API::DB packages provide an interface for the manipulation of
Genperl objects in a relational database.  This package contains the methods
for updating objects that have previously been saved to the database.  To save
new objects, see Genetics::API::DB::Create.

The following describes the update behavior implemented by the methods in 
this package:
  - The data in each object field will completely replace the data in the 
    database for that field.
  - Data for fields not present in an object will not be affected.
  - In order to delete data for a particular field, the value of that field 
    should be set to "DELETE".
  - In order to add to existing data for a particular field, use an appropriate 
    method in Genetics::API or handle it manually.

Examples:

  To completely replace a SNPs set of Alleles:
     @alleles = ( {name => "A", type => "Nucleotide"},
		   name => "C", type => "Nucleotide"} ) ;
     $snp = $api->getSNP(11) ;
     $snp->Alleles(\@alleles) ;
     $api->updateSNP($snp) ;

  To add an Allele to a SNP:
     $snp = $api->getSNP(11) ;
     $alleleListptr = $snp->Alleles ;
     push( @$alleleListptr, {name => "A", type => "Nucleotide"} ) ;
     $snp->Alleles($alleleListptr) ;
     $api->updateSNP($snp) ;

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

package Genetics::API::DB::Update ;

BEGIN {
  $ID = "Genetics::API::DB::Update" ;
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

@EXPORT = qw(updateCluster updateSubject updateKindred updateMarker 
	     updateSNP updateGenotype updateStudyVariable 
	     updatePhenotype updateFrequencySource updateHtMarkerCollection 
	     updateHaplotype updateDNASample updateTissueSample updateMap 
	     _updateObjAssocData _updateSubjectKindredRefs 
	     _updateKindredSubjectRefs _updateAssayAttrs) ;
@EXPORT_OK = qw();

=head1 Public Methods

=head2 updateCluster

  Function  : Update a Genetics::Object::Cluster object in the database.
  Argument  : The Genetics::Object::Cluster object to be updated.
  Returns   : 1 on success, undef otherwise. 
  Scope     : Public
  Comments  : Cluster.clusterType cannot be modified, so this method does 
              not touch the Cluster table.

=cut

sub updateCluster {
  my($self, $cluster) = @_ ;
  my($id, $actualType, $sth, $listPtr, $objRef) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[updateCluster] $cluster." ;

  $id = $cluster->field("id") ;
  ( $actualType ) = $dbh->selectrow_array("select objType from Object 
                                           where id = $id") ;
  if ( $actualType ne "Cluster") {
    carp " ->[updateCluster] Object with ID = $id is not a Cluster!" ;
    return(undef) ;
  }
  # Object
  $self->_updateObjAssocData($cluster) ;
  # Contents
  if ( defined ($listPtr = $cluster->field("Contents")) ) {
    $dbh->do( "delete from ClusterContents 
               where clusterID = $id" ) ;
    $sth = $dbh->prepare( "insert into ClusterContents 
                           (clusterID, objID) 
                           values (?, ?)" ) ;
    foreach $objRef (@$listPtr) {
      $sth->execute($id, $$objRef{id}) ;
    }
    $sth->finish() ;
  }

  $DEBUG and carp " ->[updateCluster] End." ;

  return(1) ;
}

=head2 updateSubject

  Function  : Update a Genetics::Object::Subject object in the database.
  Argument  : The Genetics::Object::Subject object to be updated.
  Returns   : 1 on success, undef otherwise. 
  Scope     : Public
  Comments  : If Subject.kindredID is modified, the approprate updates are also 
              made to KindredSubject.  In other words, the reciprocal 
              relationships Kindred->Subjects and Subject->Kindred are kept in 
              synch.

=cut

sub updateSubject {
  my($self, $subject) = @_ ;
  my($id, $actualType, $sth, $sth1, $orgPtr, $orgID, $kindredRef, 
     $momRef, $dadRef, $sex, $date, $isProband) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[updateSubject] $subject." ;

  $id = $subject->field("id") ;
  ( $actualType ) = $dbh->selectrow_array("select objType from Object 
                                           where id = $id") ;
  if ( $actualType ne "Subject") {
    carp " ->[updateSubject] Object with ID = $id is not a Subject!" ;
    return(undef) ;
  }
  # Object
  $self->_updateObjAssocData($subject) ;
  # Subject fields
  if ( defined($orgPtr = $subject->field("Organism")) ) {
    $sth = $dbh->prepare( "update Subject 
                           set organismID = ? 
                           where subjectID = ?" ) ;
    if ( ref($orgPtr) eq "HASH" ) {
      $orgID = $self->_getOrganismID($orgPtr) ;
      $sth->execute($orgID, $id) ;
    } elsif ( ! ref($orgPtr) and ($orgPtr eq "DELETE") ) {
      $sth->execute(undef, $id) ;
    } else {
      carp " ->[_updateSubject] Inappropriate Organism value in $subject." ;
    }
    $sth->finish() ;
  }
  if ( defined($kindredRef = $subject->field("Kindred")) ) {
    $sth = $dbh->prepare( "update Subject 
                           set kindredID = ? 
                           where subjectID = ?" ) ;
    if ( ref($kindredRef) eq "HASH" ) {
      $sth->execute($$kindredRef{id}, $id) ;
      $self->_updateSubjectKindredRefs($id, $$kindredRef{id}) ;
    } elsif ( ! ref($kindredRef) and ($kindredRef eq "DELETE") ) {
      $sth->execute(undef, $id) ;
      $self->_updateSubjectKindredRefs($id, undef) ;
    } else {
      carp " ->[_updateSubject] Inappropriate Kindred value in $subject." ;
    }
    $sth->finish() ;
  }
  if ( defined($momRef = $subject->field("Mother")) ) {
    $sth = $dbh->prepare( "update Subject 
                           set motherID = ? 
                           where subjectID = ?" ) ;
    if ( ref($momRef) eq "HASH" ) {
      $sth->execute($$momRef{id}, $id) ;
    } elsif ( ! ref($momRef) and ($momRef eq "DELETE") ) {
      $sth->execute(undef, $id) ;
    } else {
      carp " ->[_updateSubject] Inappropriate Mother value in $subject." ;
    }
    $sth->finish() ;
  }
  if ( defined($dadRef = $subject->field("Father")) ) {
    $sth = $dbh->prepare( "update Subject 
                           set fatherID = ? 
                           where subjectID = ?" ) ;
    if ( ref($dadRef) eq "HASH" ) {
      $sth->execute($$dadRef{id}, $id) ;
    } elsif ( ! ref($dadRef) and ($dadRef eq "DELETE") ) {
      $sth->execute(undef, $id) ;
    } else {
      carp " ->[_updateSubject] Inappropriate Father value in $subject." ;
    }
    $sth->finish() ;
  }
  $sex = $subject->field("gender") ;
  $sth = $dbh->prepare( "update Subject 
                         set gender = ? 
                         where subjectID = ?" ) ;
  $sth->execute($sex, $id) ;
  $sth->finish() ;
  if ( defined($date = $subject->field("dateOfBirth")) ) {
    $sth = $dbh->prepare( "update Subject 
                           set dateOfBirth = ? 
                           where subjectID = ?" ) ;
    if ($date eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($date, $id) ;
    }
    $sth->finish() ;
  }
  if ( defined($date = $subject->field("dateOfDeath")) ) {
    $sth = $dbh->prepare( "update Subject 
                           set dateOfDeath = ? 
                           where subjectID = ?" ) ;
    if ($date eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($date, $id) ;
    }
    $sth->finish() ;
  }
  $isProband = $subject->field("isProband") ;
  $sth = $dbh->prepare( "update Subject 
                         set isProband = ? 
                         where subjectID = ?" ) ;
  $sth->execute($isProband, $id) ;
  $sth->finish() ;
  
  $DEBUG and carp " ->[updateSubject] End." ;

  return(1) ;
}

=head2 updateKindred

  Function  : Update a Genetics::Object::Kindred object in the database.
  Argument  : The Genetics::Object::Kindred object to be updated.
  Returns   : 1 on success, undef otherwise. 
  Scope     : Public
  Comments  : If the set of Subjects contained in a Kindred is modified, 
              the approprate updates are also made to the Subject.kindredID 
              field of each of the Subjects.  In other words, the reciprocal 
              relationships Kindred->Subjects and Subject->Kindred are kept 
              in synch.  This only applies to primary Kindreds, of course.

=cut

sub updateKindred {
  my($self, $kindred) = @_ ;
  my($id, $actualType, $sth, $kindredRef, $subjRef, $subjListPtr, @subjIDs) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[updateKindred] $kindred." ;
  
  $id = $kindred->field("id") ;
  ( $actualType ) = $dbh->selectrow_array("select objType from Object 
                                           where id = $id") ;
  if ( $actualType ne "Kindred") {
    carp " ->[updateKindred] Object with ID = $id is not a Kindred!" ;
    return(undef) ;
  }
  # Object
  $self->_updateObjAssocData($kindred) ;
  # Kindred
  # Can't update isDerived
  if ( defined($kindredRef = $kindred->field("DerivedFrom")) ) {
    $sth = $dbh->prepare( "update Kindred 
                           set parentID = ? 
                           where kindredID = ?" ) ;
    if ( ref($kindredRef) eq "HASH" ) {
      $sth->execute($$kindredRef{id}, $id) ;
    } elsif ( ! ref($kindredRef) and ($kindredRef eq "DELETE") ) {
      $sth->execute(undef, $id) ;
    } else {
      carp " ->[_updateKindred] Inappropriate DerivedFrom value in $kindred." ;
    }
    $sth->finish() ;
  }  
  # KindredSubject
  if ( defined($subjListPtr = $kindred->field("Subjects")) ) {
    $sth = $dbh->prepare( "update Subject 
                           set kindredID = ? 
                           where subjectID = ?" ) ;
    if ( ref($subjListPtr) eq "ARRAY" ) {
      foreach $subjRef (@$subjListPtr) {
	push(@subjIDs, $$subjRef{id}) ;
	$sth->execute($id, $$subjRef{id}) ;
      }
      $self->_updateKindredSubjectRefs($id, \@subjIDs) ;
    } elsif ( ! ref($subjListPtr) and ($subjListPtr eq "DELETE") ) {
      foreach $subjRef (@$subjListPtr) {
	push(@subjIDs, $$subjRef{id}) ;
	$sth->execute(undef, $$subjRef{id}) ;
      }
      $self->_updateKindredSubjectRefs(undef, \@subjIDs) ;
    } else {
      carp " ->[_updateKindred] Inappropriate Subjects value in $kindred." ;
    }
    $sth->finish() ;
  }
  
  $DEBUG and carp " ->[updateKindred] End." ;

  return(1) ;
}

=head2 updateMarker

  Function  : Update a Genetics::Object::Marker object in the database.
  Argument  : The Genetics::Object::Marker object to be updated.
  Returns   : 1 on success, undef otherwise. 
  Scope     : Public

=cut

sub updateMarker {
  my($self, $marker) = @_ ;
  my($id, $actualType, $sth, $sth1, $chr, $orgPtr, $orgID, $seqPtr, $oldSeqID, 
     $newSeqID, $ploidy, $polyType, $idx, $seq, $alleleListPtr, $allelePtr, 
     $iscnListPtr, $iscnMapLocID, $iscnPtr, $iscnID) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[updateMarker] $marker" ;

  $id = $marker->field("id") ;
  ( $actualType ) = $dbh->selectrow_array("select objType from Object 
                                           where id = $id") ;
  if ( $actualType ne "Marker") {
    carp " ->[updateMarker] Object with ID = $id is not a Marker!" ;
    return(undef) ;
  }
  # Object
  $self->_updateObjAssocData($marker) ;
  # SequenceObject
  if ( defined($chr = $marker->field("chromosome")) ) {
    $sth = $dbh->prepare( "update SequenceObject 
                           set chromosome = ? 
                           where seqObjectID = ?" ) ;
    if ($chr eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($chr, $id) ;
    }
    $sth->finish() ;
  }
  if ( defined($orgPtr = $marker->field("Organism")) ) {
    $sth = $dbh->prepare( "update SequenceObject 
                           set organismID = ? 
                           where seqObjectID = ?" ) ;
    if ( ref($orgPtr) eq "HASH" ) {
      $orgID = $self->_getOrganismID($orgPtr) ;
      $sth->execute($orgID, $id) ;
    } elsif ( ! ref($orgPtr) and ($orgPtr eq "DELETE") ) {
      $sth->execute(undef, $id) ;
    } else {
      carp " ->[_updateMarker] Inappropriate Organism value in $marker." ;
    }
    $sth->finish() ;
  }
  if ( defined($seqPtr = $marker->field("Sequence")) ) {
    $sth = $dbh->prepare( "insert into Sequence 
                           (sequenceID, sequence, length, lengthUnits) 
                           values (?, ?, ?, ?)" ) ;
    $sth1 = $dbh->prepare( "update SequenceObject 
                            set sequenceID = ? 
                            where seqObjectID = ?" ) ;
    if ( ref($seqPtr) eq "HASH" ) {
      ( $oldSeqID ) = $dbh->selectrow_array( "select sequenceID 
                                              from SequenceObject 
                                              where seqObjectID = $id" ) ;
      if ( defined($oldSeqID) ) {
	$dbh->do( "delete from Sequence 
                   where sequenceID = $oldSeqID" ) ;
      }
      $sth->execute(undef, $$seqPtr{sequence}, $$seqPtr{length}, $$seqPtr{lengthUnits}) ;
      $newSeqID = $sth->{'mysql_insertid'} ;
      $sth1->execute($newSeqID, $id) ;
    } elsif ( ! ref($seqPtr) and ($seqPtr eq "DELETE") ) {
      ( $oldSeqID ) = $dbh->selectrow_array( "select sequenceID 
                                              from SequenceObject 
                                              where seqObjectID = $id" ) ;
      if ( defined($oldSeqID) ) {
	$dbh->do( "delete from Sequence 
                   where sequenceID = $oldSeqID" ) ;
      }
      $sth1->execute(undef, $id) ;
    } else {
      carp " ->[_updateMarker] Inappropriate Sequence value in $marker." ;
    }
    $sth->finish() ;
    $sth1->finish() ;
  }
  if ( defined($ploidy = $marker->field("malePloidy")) ) {
    $sth = $dbh->prepare( "update SequenceObject 
                           set malePloidy = ? 
                           where seqObjectID = ?" ) ;
    if ($ploidy eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($ploidy, $id) ;
    }
    $sth->finish() ;
  }
  if ( defined($ploidy = $marker->field("femalePloidy")) ) {
    $sth = $dbh->prepare( "update SequenceObject 
                           set femalePloidy = ? 
                           where seqObjectID = ?" ) ;
    if ($ploidy eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($ploidy, $id) ;
    }
    $sth->finish() ;
  }
  # Marker
  if ( defined($polyType = $marker->field("polymorphismType")) ) {
    $sth = $dbh->prepare( "update Marker 
                           set polymorphismType = ? 
                           where markerID = ?" ) ;
    if ($polyType eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($polyType, $id) ;
    }
    $sth->finish() ;
  }
  if ( defined($idx = $marker->field("polymorphismIndex1")) ) {
    $sth = $dbh->prepare( "update Marker 
                           set polymorphismIndex1 = ? 
                           where markerID = ?" ) ;
    if ($idx eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($idx, $id) ;
    }
    $sth->finish() ;
  }
  if ( defined($idx = $marker->field("polymorphismIndex2")) ) {
    $sth = $dbh->prepare( "update Marker 
                           set polymorphismIndex2 = ? 
                           where markerID = ?" ) ;
    if ($idx eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($idx, $id) ;
    }
    $sth->finish() ;
  }
  if ( defined($seq = $marker->field("repeatSequence")) ) {
    $sth = $dbh->prepare( "update Marker 
                           set repeatSequence = ? 
                           where markerID = ?" ) ;
    if ($seq eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($seq, $id) ;
    }
    $sth->finish() ;
  }
  # Allele data
  if ( defined($alleleListPtr = $marker->field("Alleles")) ) {
    if ( ref($alleleListPtr) eq "ARRAY" ) {
      $dbh->do( "delete from Allele 
                 where poID = $id" ) ;
      $sth = $dbh->prepare( "insert into Allele 
                             (alleleID, poID, name, type)
                             values (?, ?, ?, ?)" ) ;
      foreach $allelePtr (@$alleleListPtr) {
	$sth->execute(undef, $id, $$allelePtr{name}, $$allelePtr{type}) ;
      }
      $sth->finish() ;
    } elsif ( ! ref($alleleListPtr) and ($alleleListPtr eq "DELETE") ) {
      $dbh->do( "delete from Allele 
                 where poID = $id" ) ;
    } else {
      carp " ->[_updateMarker] Inappropriate Alleles value in $marker." ;
    }
  }
  # ISCNMapLocation data
  if ( defined($iscnListPtr = $marker->field("ISCNMapLocations")) ) {
    $sth = $dbh->prepare( "select iscnMapLocID 
                           from SeqObjISCN 
                           where seqObjectID = $id" ) ;
    if ( ref($iscnListPtr) eq "ARRAY" ) {
      $sth->execute() ;
      while ( ($iscnMapLocID) = $sth->fetchrow_array() ) {
	$dbh->do( "delete from ISCNMapLocation 
                   where iscnMapLocID = $iscnMapLocID" ) ;
      }
      $sth->finish() ;
      $dbh->do( "delete from SeqObjISCN
                 where seqObjectID = $id" ) ;
      $sth = $dbh->prepare( "insert into ISCNMapLocation 
                             (iscnMapLocID, chrNumber, chrArm, band, bandingMethod) 
                             values (?, ?, ?, ?, ?)" ) ;
      $sth1 = $dbh->prepare( "insert into SeqObjISCN 
                              (seqObjectID, iscnMapLocID)
                              values (?, ?)" ) ;
      foreach $iscnPtr (@$iscnListPtr) {
	$sth->execute(undef, $$iscnPtr{chrNumber}, $$iscnPtr{chrArm}, $$iscnPtr{band}, 
		      $$iscnPtr{bandingMethod}) ;
      $iscnID = $sth->{'mysql_insertid'} ;
      $sth1->execute($id, $iscnID) ;
      }
    } elsif ( ! ref($iscnListPtr) and ($iscnListPtr eq "DELETE") ) {
      $sth->execute() ;
      while ( ($iscnMapLocID) = $sth->fetchrow_array() ) {
	$dbh->do( "delete from ISCNMapLocation 
                   where iscnMapLocID = $iscnMapLocID" ) ;
      }
      $sth->finish() ;
      $dbh->do( "delete from SeqObjISCN
                 where seqObjectID = $id" ) ;
    } else {
      carp " ->[_updateMarker] Inappropriate ISCNMapLocations value in $marker." ;
    }
  }
  
  $DEBUG and carp " ->[updateMarker] End." ;

  return(1) ;
}

=head2 updateSNP

  Function  : Update a Genetics::Object::SNP object in the database.
  Argument  : The Genetics::Object::SNP object to be updated.
  Returns   : 1 on success, undef otherwise. 
  Scope     : Public

=cut

sub updateSNP {
  my($self, $snp) = @_ ;
  my($id, $actualType, $sth, $sth1, $chr, $orgPtr, $orgID, $seqPtr, $oldSeqID, 
     $newSeqID, $ploidy, $type, $class, $idx, $conf, $method, $alleleListPtr, 
     $allelePtr, $iscnListPtr, $iscnMapLocID, $iscnPtr, $iscnID) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[updateSNP] $snp" ;

  $id = $snp->field("id") ;
  ( $actualType ) = $dbh->selectrow_array("select objType from Object 
                                           where id = $id") ;
  if ( $actualType ne "SNP") {
    carp " ->[updateSNP] Object with ID = $id is not a SNP!" ;
    return(undef) ;
  }
  # Object
  $self->_updateObjAssocData($snp) ;
  # SequenceObject
  if ( defined($chr = $snp->field("chromosome")) ) {
    $sth = $dbh->prepare( "update SequenceObject 
                           set chromosome = ? 
                           where seqObjectID = ?" ) ;
    if ($chr eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($chr, $id) ;
    }
    $sth->finish() ;
  }
  if ( defined($orgPtr = $snp->field("Organism")) ) {
    $sth = $dbh->prepare( "update SequenceObject 
                           set organismID = ? 
                           where seqObjectID = ?" ) ;
    if ( ref($orgPtr) eq "HASH" ) {
      $orgID = $self->_getOrganismID($orgPtr) ;
      $sth->execute($orgID, $id) ;
    } elsif ( ! ref($orgPtr) and ($orgPtr eq "DELETE") ) {
      $sth->execute(undef, $id) ;
    } else {
      carp " ->[_updateSNP] Inappropriate Organism value in $snp." ;
    }
    $sth->finish() ;
  }
  if ( defined($seqPtr = $snp->field("Sequence")) ) {
    $sth = $dbh->prepare( "insert into Sequence 
                           (sequenceID, sequence, length, lengthUnits) 
                           values (?, ?, ?, ?)" ) ;
    $sth1 = $dbh->prepare( "update SequenceObject 
                            set sequenceID = ? 
                            where seqObjectID = ?" ) ;
    if ( ref($seqPtr) eq "HASH" ) {
      ( $oldSeqID ) = $dbh->selectrow_array( "select sequenceID 
                                              from SequenceObject 
                                              where seqObjectID = $id" ) ;
      if ( defined($oldSeqID) ) {
	$dbh->do( "delete from Sequence 
                   where sequenceID = $oldSeqID" ) ;
      }
      $sth->execute(undef, $$seqPtr{sequence}, $$seqPtr{length}, $$seqPtr{lengthUnits}) ;
      $newSeqID = $sth->{'mysql_insertid'} ;
      $sth1->execute($newSeqID, $id) ;
    } elsif ( ! ref($seqPtr) and ($seqPtr eq "DELETE") ) {
      ( $oldSeqID ) = $dbh->selectrow_array( "select sequenceID 
                                              from SequenceObject 
                                              where seqObjectID = $id" ) ;
      if ( defined($oldSeqID) ) {
	$dbh->do( "delete from Sequence 
                   where sequenceID = $oldSeqID" ) ;
      }
      $sth1->execute(undef, $id) ;
    } else {
      carp " ->[updateSNP] Inappropriate Sequence value in $snp." ;
    }
    $sth->finish() ;
    $sth1->finish() ;
  }
  if ( defined($ploidy = $snp->field("malePloidy")) ) {
    $sth = $dbh->prepare( "update SequenceObject 
                           set malePloidy = ? 
                           where seqObjectID = ?" ) ;
    if ($ploidy eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($ploidy, $id) ;
    }
    $sth->finish() ;
  }
  if ( defined($ploidy = $snp->field("femalePloidy")) ) {
    $sth = $dbh->prepare( "update SequenceObject 
                           set femalePloidy = ? 
                           where seqObjectID = ?" ) ;
    if ($ploidy eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($ploidy, $id) ;
    }
    $sth->finish() ;
  }
  # SNP
  if ( defined($type = $snp->field("snpType")) ) {
    $sth = $dbh->prepare( "update SNP 
                           set snpType = ? 
                           where snpID = ?" ) ;
    if ($type eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($type, $id) ;
    }
    $sth->finish() ;
  }
  if ( defined($class = $snp->field("functionClass")) ) {
    $sth = $dbh->prepare( "update SNP 
                           set functionClass = ? 
                           where snpID = ?" ) ;
    if ($class eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($class, $id) ;
    }
    $sth->finish() ;
  }
  if ( defined($idx = $snp->field("snpIndex")) ) {
    $sth = $dbh->prepare( "update SNP 
                           set snpIndex = ? 
                           where snpID = ?" ) ;
    if ($idx eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($idx, $id) ;
    }
    $sth->finish() ;
  }
  if ( defined($conf = $snp->field("isConfirmed")) ) {
    $sth = $dbh->prepare( "update SNP 
                           set isConfirmed = ? 
                           where snpID = ?" ) ;
    if ($conf eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($conf, $id) ;
    }
    $sth->finish() ;
  }
  if ( defined($method = $snp->field("confirmMethod")) ) {
    $sth = $dbh->prepare( "update SNP 
                           set confirmMethod = ? 
                           where snpID = ?" ) ;
    if ($method eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($method, $id) ;
    }
    $sth->finish() ;
  }
  # Allele data
  if ( defined($alleleListPtr = $snp->field("Alleles")) ) {
    if ( ref($alleleListPtr) eq "ARRAY" ) {
      $dbh->do( "delete from Allele 
                 where poID = $id" ) ;
      $sth = $dbh->prepare( "insert into Allele 
                             (alleleID, poID, name, type)
                             values (?, ?, ?, ?)" ) ;
      foreach $allelePtr (@$alleleListPtr) {
	$sth->execute(undef, $id, $$allelePtr{name}, $$allelePtr{type}) ;
      }
      $sth->finish() ;
    } elsif ( ! ref($alleleListPtr) and ($alleleListPtr eq "DELETE") ) {
      $dbh->do( "delete from Allele 
                 where poID = $id" ) ;
    } else {
      carp " ->[_updateSNP] Inappropriate Alleles value in $snp." ;
    }
  }
  # ISCNMapLocation data
  if ( defined($iscnListPtr = $snp->field("ISCNMapLocations")) ) {
    $sth = $dbh->prepare( "select iscnMapLocID 
                           from SeqObjISCN 
                           where seqObjectID = $id" ) ;
    if ( ref($iscnListPtr) eq "ARRAY" ) {
      $sth->execute() ;
      while ( ($iscnMapLocID) = $sth->fetchrow_array() ) {
	$dbh->do( "delete from ISCNMapLocation 
                   where iscnMapLocID = $iscnMapLocID" ) ;
      }
      $sth->finish() ;
      $dbh->do( "delete from SeqObjISCN
                 where seqObjectID = $id" ) ;
      $sth = $dbh->prepare( "insert into ISCNMapLocation 
                             (iscnMapLocID, chrNumber, chrArm, band, bandingMethod) 
                             values (?, ?, ?, ?, ?)" ) ;
      $sth1 = $dbh->prepare( "insert into SeqObjISCN 
                              (seqObjectID, iscnMapLocID)
                              values (?, ?)" ) ;
      foreach $iscnPtr (@$iscnListPtr) {
	$sth->execute(undef, $$iscnPtr{chrNumber}, $$iscnPtr{chrArm}, $$iscnPtr{band}, 
		      $$iscnPtr{bandingMethod}) ;
      $iscnID = $sth->{'mysql_insertid'} ;
      $sth1->execute($id, $iscnID) ;
      }
    } elsif ( ! ref($iscnListPtr) and ($iscnListPtr eq "DELETE") ) {
      $sth->execute() ;
      while ( ($iscnMapLocID) = $sth->fetchrow_array() ) {
	$dbh->do( "delete from ISCNMapLocation 
                   where iscnMapLocID = $iscnMapLocID" ) ;
      }
      $sth->finish() ;
      $dbh->do( "delete from SeqObjISCN
                 where seqObjectID = $id" ) ;
    } else {
      carp " ->[_updateSNP] Inappropriate ISCNMapLocations value in $snp." ;
    }
  }
  
  $DEBUG and carp " ->[updateSNP] End." ;

  return(1) ;
}

=head2 updateGenotype

  Function  : Update a Genetics::Object::Genotype object in the database.
  Argument  : The Genetics::Object::Genotype object to be updated.
  Returns   : 1 on success, undef otherwise.
  Scope     : Public

=cut

sub updateGenotype {
  my($self, $gt) = @_ ;
  my($id, $actualType, $sth, $active, $icResult, $date, $acListPtr, 
     $poID, $sthAC, $sthA, $sortOrder, $acPtr, $alleleID, $aaListPtr, 
     $alleleCallID) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[updateGenotype] $gt" ;

  $id = $gt->field("id") ;
  ( $actualType ) = $dbh->selectrow_array("select objType from Object 
                                           where id = $id") ;
  if ( $actualType ne "Genotype") {
    carp " ->[updateGenotype] Object with ID = $id is not a Genotype!" ;
    return(undef) ;
  }
  # Object
  $self->_updateObjAssocData($gt) ;
  # Genotype
  if ( defined($active = $gt->field("isActive")) ) {
    $sth = $dbh->prepare( "update Genotype 
                           set isActive = ? 
                           where gtID = ?" ) ;
    $sth->execute($active, $id) ;
    $sth->finish() ;
  }
  if ( defined($icResult = $gt->field("icResult")) ) {
    $sth = $dbh->prepare( "update Genotype 
                           set icResult = ? 
                           where gtID = ?" ) ;
    if ($icResult eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($icResult, $id) ;
    }
    $sth->finish() ;
  }
  if ( defined($date = $gt->field("dateCollected")) ) {
    $sth = $dbh->prepare( "update Genotype 
                           set dateCollected = ? 
                           where gtID = ?" ) ;
    if ($date eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($date, $id) ;
    }
    $sth->finish() ;
  }
  if ( defined($acListPtr = $gt->field("AlleleCalls")) ) {
    ( $poID ) = $dbh->selectrow_array( "select poID 
                                        from Genotype 
                                        where gtID = $id" ) ;
    if ( ref($acListPtr) eq "ARRAY" ) {
      $dbh->do( "delete from AlleleCall 
                 where gtID = $id" ) ;
      $sthAC = $dbh->prepare( "insert into AlleleCall 
                               (alleleCallID, gtID, alleleID, sortOrder, phase)
                               values (?, ?, ?, ?, ?)" ) ;
      $sthA = $dbh->prepare( "insert into Allele 
                              (alleleID, poID, name, type)
                              values (?, ?, ?, ?)" ) ;
      $sortOrder = 1 ;
      foreach $acPtr (@$acListPtr) {
	# Check if the Marker already has an Allele w/ the same name and type...
	( $alleleID ) = $dbh->selectrow_array( "select alleleID from Allele 
                                                where poID = $poID and 
                                                name = '$$acPtr{alleleName}' and 
                                                type = '$$acPtr{alleleType}'" ) ;
	if ( ! defined $alleleID) {
	  # ...if not, create a new Allele
	  $sthA->execute(undef, $poID, $$acPtr{alleleName}, $$acPtr{alleleType}) ;
	  $alleleID = $sthA->{'mysql_insertid'} ;
	}
	$sthAC->execute(undef, $id, $alleleID, $sortOrder, $$acPtr{phase}) ;
	$alleleCallID = $sthAC->{'mysql_insertid'} ;
	$sortOrder++ ;
	# AlleleCall AssayAttributes
	if ( defined ($aaListPtr = $$acPtr{AssayAttrs}) ) {
	  $self->_updateAssayAttrs($aaListPtr, "AlleleCall", $alleleCallID) ;
	}
      }
      $sthAC->finish() ;
      $sthA->finish() ;
    }
  } else {
    carp " ->[_updateGenotype] Inappropriate AlleleCalls value in $gt." ;
  }
  # Genotype AssayAttributes
  if ( defined ($aaListPtr = $gt->field("AssayAttrs")) ) {
    $self->_updateAssayAttrs($aaListPtr, "Genotype", $id) ;
  }
  
  $DEBUG and carp " ->[updateGenotype] End." ;

  return(1) ;
}

=head2 updateStudyVariable

  Function  : Update a Genetics::Object::StudyVariable object in the database.
  Argument  : The Genetics::Object::StudyVariable object to be updated.
  Returns   : 1 on success, undef otherwise.
  Scope     : Public
  Comments  : StudyVariable.format cannot be modified.

=cut

sub updateStudyVariable {
  my($self, $sv) = @_ ;
  my($id, $format, $category, $actualType, $sth, $isX, $desc, $bound, 
     $codesListPtr, $codePtr, $arrRef, $sth1, $cdID, $oldAsdID, $asdPtr, $asdID, $aseListPtr, 
     $asePtr, $oldLcdID, $lcDefPtr, $lcdID, $lcListPtr, $lcPtr) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[updateStudyVariable] $sv" ;

  $id = $sv->field("id") ;
  $format = $sv->field("format") ;
  $category = $sv->field("category") ;
  ( $actualType ) = $dbh->selectrow_array("select objType from Object 
                                           where id = $id") ;
  if ( $actualType ne "StudyVariable") {
    carp " ->[updateStudyVariable] Object with ID = $id is not a StudyVariable!" ;
    return(undef) ;
  }
  # Object
  $self->_updateObjAssocData($sv) ;
  # StudyVariable data
  $sth = $dbh->prepare( "update StudyVariable 
                         set category = ? 
                         where studyVariableID = ?" ) ;
  $sth->execute($category, $id) ;
  $sth->finish() ;
  if ( defined($isX = $sv->field("isXLinked")) ) {
    $sth = $dbh->prepare( "update StudyVariable 
                           set isXLinked = ? 
                           where studyVariableID = ?" ) ;
    $sth->execute($isX, $id) ;
    $sth->finish() ;
  }
  if ( defined($desc = $sv->field("description")) ) {
    $sth = $dbh->prepare( "update StudyVariable 
                           set description = ? 
                           where studyVariableID = ?" ) ;
    if ($desc eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($desc, $id) ;
    }
    $sth->finish() ;
  }
  if ($format eq "Number") {
    if ( defined($bound = $sv->field("lowerBound")) ) {
      $sth = $dbh->prepare( "update StudyVariable 
                           set numberLowerBound = ? 
                           where studyVariableID = ?" ) ;
    if ($bound eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($bound, $id) ;
    }
    $sth->finish() ;
    }
    if ( defined($bound = $sv->field("upperBound")) ) {
      $sth = $dbh->prepare( "update StudyVariable 
                           set numberUpperBound = ? 
                           where studyVariableID = ?" ) ;
    if ($bound eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($bound, $id) ;
    }
    $sth->finish() ;
    }
  }
  if ($format eq "Date") {
    if ( defined($bound = $sv->field("lowerBound")) ) {
      $sth = $dbh->prepare( "update StudyVariable 
                           set dateLowerBound = ? 
                           where studyVariableID = ?" ) ;
    if ($bound eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($bound, $id) ;
    }
    $sth->finish() ;
    }
    if ( defined($bound = $sv->field("upperBound")) ) {
      $sth = $dbh->prepare( "update StudyVariable 
                           set dateUpperBound = ? 
                           where studyVariableID = ?" ) ;
    if ($bound eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($bound, $id) ;
    }
    $sth->finish() ;
    }
  }
  if ($format eq "Code") {
    if ( defined($codesListPtr = $sv->field("Codes")) ) {
      $sth = $dbh->prepare(" select codeDerivationID from CodeDerivation 
                             where studyVariableID = $id" ) ;
      $sth->execute() ;
      while ($arrRef = $sth->fetchrow_arrayref()) {
	$dbh->do( "delete from  StaticLCPenetrance
                   where cdID = $$arrRef[0]" ) ;
      }
      $dbh->do( "delete from CodeDerivation 
                 where studyVariableID = $id" ) ;
      
      $sth = $dbh->prepare( "insert into CodeDerivation 
                             (codeDerivationID, studyVariableID, code, description, formula) 
                             values (?, ?, ?, ?, ?)" ) ;
      if ($category eq "StaticLiabilityClass") {
	$sth1 = $dbh->prepare( "insert into StaticLCPenetrance 
                                (cdID, pen11, pen12, pen22, malePen1, malePen2)
                                values (?, ?, ?, ?, ?, ?)" ) ;
      }
      foreach $codePtr (@$codesListPtr) {
	$sth->execute(undef, $id, $$codePtr{code}, $$codePtr{description}, undef) ;
	$cdID = $sth->{'mysql_insertid'} ;
	if ($category eq "StaticLiabilityClass") {
	  $sth1->execute($cdID, $$codePtr{pen11}, $$codePtr{pen12}, $$codePtr{pen22}, $$codePtr{malePen1}, $$codePtr{malePen2}) ;
	}
      }
      $sth->finish() ;
    }
  }
  if ($category =~ /AffectionStatus$/) {
    ( $oldAsdID ) = $dbh->selectrow_array( "select asDefID from AffectionStatusDefinition 
                                            where studyVariableID = $id" ) ;
    if ( defined($asdPtr = $sv->field("AffStatDef")) ) {
      $dbh->do( "delete from AffectionStatusDefinition 
                 where studyVariableID = $id" ) ;
      $sth = $dbh->prepare( "insert into AffectionStatusDefinition 
                             (asDefID, studyVariableID, name, diseaseAlleleFreq, 
                              pen11, pen12, pen22, malePen1, malePen2) 
                             values (?, ?, ?, ?, ?, ?, ?, ?, ?)" ) ;
      $sth->execute(undef, $id, $$asdPtr{name}, $$asdPtr{diseaseAlleleFreq}, $$asdPtr{pen11}, $$asdPtr{pen12}, $$asdPtr{pen22}, $$asdPtr{malePen1}, $$asdPtr{malePen2}) ;
      $asdID = $sth->{'mysql_insertid'} ;
      $sth->finish() ;
      if ( defined($aseListPtr = $$asdPtr{AffStatElements}) ) {
	if (defined $oldAsdID) {
	  $dbh->do( "delete from AffectionStatusElement
                     where asDefID = $oldAsdID" ) ;
	}
	$sth = $dbh->prepare( "insert into AffectionStatusElement 
                               (asElementID, asDefID, code, type, formula) 
                               values (?, ?, ?, ?, ?)" ) ;
	foreach $asePtr (@$aseListPtr) {
	  $sth->execute(undef, $asdID, $$asePtr{code}, $$asePtr{type}, $$asePtr{formula}) ;	  
	}
	$sth->finish() ;
      }
    }
    if ( defined($lcDefPtr = $sv->field("LCDef")) ) {
      ( $oldLcdID ) = $dbh->selectrow_array( "select lcDefID from LiabilityClassDefinition 
                                            where studyVariableID = $id" ) ;
      $dbh->do( "delete from LiabilityClassDefinition 
                 where studyVariableID = $id" ) ;
      $sth = $dbh->prepare( "insert into LiabilityClassDefinition 
                             (lcDefID, studyVariableID, name) 
                             values (?, ?, ?)" ) ;
      $sth->execute(undef, $id, $$lcDefPtr{name}) ;
      $lcdID = $sth->{'mysql_insertid'} ;
      $sth->finish() ;
      if ( defined($lcListPtr = $$lcDefPtr{LiabilityClasses}) ) {
	$dbh->do( "delete from LiabilityClass 
                   where lcDefID = $oldLcdID" ) ;
	$sth = $dbh->prepare( "insert into LiabilityClass 
                               (lcID, lcDefID, code, description, pen11, 
                                pen12, pen22, malePen1, malePen2, formula) 
                               values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)" ) ;
	foreach $lcPtr (@$lcListPtr) {
	  $sth->execute(undef, $lcdID, $$lcPtr{code}, $$lcPtr{description}, $$lcPtr{pen11}, $$lcPtr{pen12}, $$lcPtr{pen22}, $$lcPtr{malePen1}, $$lcPtr{malePen2}, $$lcPtr{formula}) ;
	}
	$sth->finish() ;
      }
    }
  }

  $DEBUG and carp " ->[updateStudyVariable] End." ;
  
  return(1) ;
}

=head2 updatePhenotype

  Function  : Update a Genetics::Object::Phenotype object in the database.
  Argument  : The Genetics::Object::Phenotype object to be updated.
  Returns   : 1 on success, undef otherwise.
  Scope     : Public
  Comments  : 
              
=cut

sub updatePhenotype {
  my($self, $pt) = @_ ;
  my($id, $actualType, $sth, $active, $date, $svFormat, $valueFieldName, $aaListPtr) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[updatePhenotype] $pt" ;

  $id = $pt->field("id") ;
  ( $actualType ) = $dbh->selectrow_array("select objType from Object 
                                           where id = $id") ;
  if ( $actualType ne "Phenotype") {
    carp " ->[updatePhenotype] Object with ID = $id is not a Phenotype!" ;
    return(undef) ;
  }
  # Object
  $self->_updateObjAssocData($pt) ;
  # Phenotype
  if ( defined($active = $pt->field("isActive")) ) {
    $sth = $dbh->prepare( "update Phenotype 
                           set isActive = ? 
                           where ptID = ?" ) ;
    $sth->execute($active, $id) ;
    $sth->finish() ;
  }
  if ( defined($date = $pt->field("dateCollected")) ) {
    $sth = $dbh->prepare( "update Phenotype 
                           set dateCollected = ? 
                           where ptID = ?" ) ;
    if ($date eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($date, $id) ;
    }
    $sth->finish() ;
  }
  ( $svFormat ) = $dbh->selectrow_array( "select format from StudyVariable, Phenotype 
                                          where ptID = $id 
                                          and Phenotype.svID = StudyVariable.studyVariableID" ) ;
  $valueFieldName = lc($svFormat) . "Value" ;
  $sth = $dbh->prepare( "update Phenotype 
                         set $valueFieldName = ? 
                         where ptID = ?" ) ;
  $sth->execute($pt->field("value"), $id) ;
  $sth->finish() ;
  # Phenotype AssayAttributes
  if ( defined ($aaListPtr = $pt->field("AssayAttrs")) ) {
    $self->_updateAssayAttrs($aaListPtr, "Phenotype", $id) ;
  }
  
  $DEBUG and carp " ->[updatePhenotype] End." ;

  return(1) ;
}

=head2 updateFrequencySource

  Function  : Update a Genetics::Object::FrequencySource object in the database.
  Argument  : The Genetics::Object::FrequencySource object to be updated.
  Returns   : 1 on success, undef otherwise.
  Scope     : Public

=cut

sub updateFrequencySource {
  my($self, $fs) = @_ ;
  my($id, $actualType, $sth, $sthA, $sthOF, $sthFSOF, $listPtr, $arrRef, 
     $oafPtr, $allelePtr, $poID, $alleleID, $obsFreqID, $ohfPtr, $htID) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[updateFrequencySource] $fs" ;

  $id = $fs->field("id") ;
  ( $actualType ) = $dbh->selectrow_array("select objType from Object 
                                           where id = $id") ;
  if ( $actualType ne "FrequencySource") {
    carp " ->[updateFrequencySource] Object with ID = $id is not a FrequencySource!" ;
    return(undef) ;
  }

  # Object
  $self->_updateObjAssocData($fs) ;
  # FrequencySource data
  $sthOF = $dbh->prepare( "insert into ObsFrequency 
                           (obsFreqID, type, alleleID, htID, frequency) 
                           values (?, ?, ?, ?, ?)" ) ;
  $sthFSOF = $dbh->prepare( "insert into FreqSourceObsFrequency 
                             (freqSourceID, obsFreqID)
                             values (?, ?)" ) ;  
  # Allele Freqs
  if ( defined ($listPtr = $fs->field("ObsAlleleFrequencies")) ) {
    if ( ref($listPtr) eq "ARRAY") {
      # Get rid of old allele freqs...
      $sth = $dbh->prepare( "select FreqSourceObsFrequency.obsFreqID 
                             from ObsFrequency, FreqSourceObsFrequency 
                             where freqSourceID = $id 
                             and ObsFrequency.obsFreqID = FreqSourceObsFrequency.obsFreqID 
                             and ObsFrequency.type = 'Allele'" ) ;
      $sth->execute() ;
      while ($arrRef = $sth->fetchrow_arrayref()) {
	$dbh->do( "delete from ObsFrequency 
                   where obsFreqID = $$arrRef[0]" ) ;
	$dbh->do( "delete from FreqSourceObsFrequency 
                   where obsFreqID = $$arrRef[0]" ) ;
      }
      # ...the add new ones
      $sthA = $dbh->prepare( "insert into Allele 
                              (alleleID, poID, name, type)
                              values (?, ?, ?, ?)" ) ;
      foreach $oafPtr (@$listPtr) {
	# Figure out what Allele we're talking about.  First find the Marker ID...
	$allelePtr = $$oafPtr{Allele} ;
	$poID = $allelePtr->{Marker}->{id} ;
	# ...then see if the Marker already has an Allele w/ the same name and type...
	( $alleleID ) = $dbh->selectrow_array( "select alleleID from Allele 
                                                where poID = '$poID' and 
                                                name = '$$allelePtr{name}' and 
                                                type = '$$allelePtr{type}'" ) ;
	if ( ! defined $alleleID) {
	  # ...if not, create a new Allele
	  $sthA->execute(undef, $poID, $$allelePtr{name}, $$allelePtr{type}) ;
	  $alleleID = $sthA->{'mysql_insertid'} ;
	}
	# Create the ObsFrequency
	$sthOF->execute(undef, "Allele", $alleleID, undef, $$oafPtr{frequency}) ;
	$obsFreqID = $sthOF->{'mysql_insertid'} ;
	# Add row to FreqSourceObsFrequency
	$sthFSOF->execute($id, $obsFreqID) ;
      }
    }
    $sthA->finish() ;
  } elsif ( ! ref($listPtr) and ($listPtr eq "DELETE") ) {
    $sth = $dbh->prepare( "select FreqSourceObsFrequency.obsFreqID 
                           from ObsFrequency, FreqSourceObsFrequency 
                           where freqSourceID = $id 
                           and ObsFrequency.obsFreqID = FreqSourceObsFrequency.obsFreqID 
                           and ObsFrequency.type = 'Allele'" ) ;
    $sth->execute() ;
    while ($arrRef = $sth->fetchrow_arrayref()) {
      $dbh->do( "delete from ObsFrequency 
                 where obsFreqID = $$arrRef[0]" ) ;
      $dbh->do( "delete from FreqSourceObsFrequency 
                   where obsFreqID = $$arrRef[0]" ) ;
    }
  } else {
    carp " ->[_updateFrequencySource] Inappropriate ObsAlleleFrequencies value in $fs." ;
  }
  # Haplotype Freqs
  if ( defined ($listPtr = $fs->field("ObsHtFrequencies")) ) {
    if ( ref($listPtr) eq "ARRAY") {
      # Get rid of old ht freqs...
      $sth = $dbh->prepare( "select FreqSourceObsFrequency.obsFreqID 
                             from ObsFrequency, FreqSourceObsFrequency 
                             where freqSourceID = $id 
                             and ObsFrequency.obsFreqID = FreqSourceObsFrequency.obsFreqID 
                             and ObsFrequency.type = 'Ht'" ) ;
      $sth->execute() ;
      while ($arrRef = $sth->fetchrow_arrayref()) {
	$dbh->do( "delete from ObsFrequency 
                   where obsFreqID = $$arrRef[0]" ) ;
	$dbh->do( "delete from FreqSourceObsFrequency 
                   where obsFreqID = $$arrRef[0]" ) ;
      }
      # ...then add new ones
      foreach $ohfPtr (@$listPtr) {
	# Figure out what Haplotype we're talking about.
	$htID = $ohfPtr->{Haplotype}->{id} ;
	# Create the ObsFrequency
	$sthOF->execute(undef, "Ht", undef, $htID, $$ohfPtr{frequency}) ;
	$obsFreqID = $sthOF->{'mysql_insertid'} ;
	# Add row to FreqSourceObsFrequency
	$sthFSOF->execute($id, $obsFreqID) ;
      }
    } elsif ( ! ref($listPtr) and ($listPtr eq "DELETE") ) {
      $sth = $dbh->prepare( "select FreqSourceObsFrequency.obsFreqID 
                             from ObsFrequency, FreqSourceObsFrequency 
                             where freqSourceID = $id 
                             and ObsFrequency.obsFreqID = FreqSourceObsFrequency.obsFreqID 
                             and ObsFrequency.type = 'Ht'" ) ;
      $sth->execute() ;
      while ($arrRef = $sth->fetchrow_arrayref()) {
	$dbh->do( "delete from ObsFrequency 
                   where obsFreqID = $$arrRef[0]" ) ;
	$dbh->do( "delete from FreqSourceObsFrequency 
                   where obsFreqID = $$arrRef[0]" ) ;
      }
    } else {
      carp " ->[_updateFrequencySource] Inappropriate ObsHtFrequencies value in $fs." ;
    }
  }
  $sthOF->finish() ;
  $sthFSOF->finish() ;
  
  $DEBUG and carp " ->[updateFrequencySource] End." ;

  return(1) ;
}

=head2 updateHtMarkerCollection

  Function  : Update a Genetics::Object::HtMarkerCollection object in the database.
  Argument  : The Genetics::Object::HtMarkerCollection object to be updated.
  Returns   : 1 on success, undef otherwise.
  Scope     : Public

=cut

sub updateHtMarkerCollection {
  my($self, $hmc) = @_ ;
  my($id, $actualType, $sth, $units, $poListPtr, $sortOrder, $poPtr) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[updateHtMarkerCollection] $hmc" ;

  $id = $hmc->field("id") ;
  ( $actualType ) = $dbh->selectrow_array("select objType from Object 
                                           where id = $id") ;
  if ( $actualType ne "HtMarkerCollection") {
    carp " ->[updateHtMarkerCollection] Object with ID = $id is not a HtMarkerCollection!" ;
    return(undef) ;
  }

  # Object
  $self->_updateObjAssocData($hmc) ;
  # HtMarkerCollection data
  if ( defined($units = $hmc->field("distanceUnits")) ) {
    $sth = $dbh->prepare( "update HtMarkerCollection 
                           set distanceUnits = ? 
                           where hmcID = ?" ) ;
    $sth->execute($units, $id) ;
    $sth->finish() ;
  }
  if ( defined($poListPtr = $hmc->field("Markers")) ) {
    $dbh->do( "delete from HMCPolyObj 
               where hmcID = $id" ) ;
    $sth = $dbh->prepare( "insert into HMCPolyObj 
                           (hmcID, poID, sortOrder, distance) 
                           values (?, ?, ?, ?)" ) ;
    $sortOrder = 1 ;
    foreach $poPtr (@$poListPtr) {
      $sth->execute($id, $$poPtr{id}, $sortOrder, $$poPtr{distToNext}) ;
      $sortOrder++ ;
    }
    $sth->finish() ;
  }
  
  $DEBUG and carp " ->[updateHtMarkerCollection] End." ;
  
  return(1) ;
}

=head2 updateHaplotype

  Function  : Update a Genetics::Object::Haplotype object in the database.
  Argument  : The Genetics::Object::Haplotype object to be updated.
  Returns   : 1 on success, undef otherwise.
  Scope     : Public

=cut

sub updateHaplotype {
  my($self, $ht) = @_ ;
  my($id, $actualType, $sth, $sthA, $hmcPtr, $hmcID, $alleleListPtr, 
     $sortOrder, $allelePtr, $poID, $alleleID) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[updateHaplotype] $ht" ;

  $id = $ht->field("id") ;
  ( $actualType ) = $dbh->selectrow_array("select objType from Object 
                                           where id = $id") ;
  if ( $actualType ne "Haplotype") {
    carp " ->[updateHaplotype] Object with ID = $id is not a Haplotype!" ;
    return(undef) ;
  }

  # Object
  $self->_updateObjAssocData($ht) ;
  # Haplotype 
  $hmcPtr = $ht->field("MarkerCollection") ;
  $hmcID = $$hmcPtr{id} ;
  $sth = $dbh->prepare( "update Haplotype 
                         set hmcID = ? 
                         where haplotypeID = ?" ) ;
  $sth->execute($hmcID, $id) ;
  $sth->finish() ;
  # HaplotypeAllele
  $dbh->do( "delete from HaplotypeAllele 
             where haplotypeID = $id" ) ;
  $alleleListPtr = $ht->field("Alleles") ;
  $sth = $dbh->prepare( "insert into HaplotypeAllele 
                         (haplotypeID, alleleID, sortOrder) 
                         values (?, ?, ?)" ) ;
  $sthA = $dbh->prepare( "insert into Allele 
                          (alleleID, poID, name, type)
                          values (?, ?, ?, ?)" ) ;
  $sortOrder = 1 ;
  foreach $allelePtr (@$alleleListPtr) {
    # First find the Marker ID...
    ( $poID ) = $dbh->selectrow_array( "select poID from HMCPolyObj 
                                        where hmcID = '$hmcID' and 
                                        sortOrder = '$sortOrder'") ;
    # ...then see if the Marker already has an Allele w/ the same name and type...
    ( $alleleID ) = $dbh->selectrow_array( "select alleleID from Allele 
                                            where poID = '$poID' and 
                                            name = '$$allelePtr{name}' and 
                                            type = '$$allelePtr{type}'" ) ;
    if ( ! defined $alleleID) {
      # ...if not, create a new Allele
      $sthA->execute(undef, $poID, $$allelePtr{name}, $$allelePtr{type}) ;
      $alleleID = $sthA->{'mysql_insertid'} ;
    }
    $sth->execute($id, $alleleID, $sortOrder) ;
    $sortOrder++ ;
  }
  $sth->finish() ;
  $sthA->finish() ;

  $DEBUG and carp " ->[updateHaplotype] End." ;

  return(1) ;
}

=head2 updateDNASample

  Function  : Update a Genetics::Object::DNASample object in the database.
  Argument  : The Genetics::Object::DNASample object to be updated.
  Returns   : 1 on success, undef otherwise.
  Scope     : Public

=cut

sub updateDNASample {
  my($self, $sample) = @_ ;
  my($id, $actualType, $sth, $date, $amt, $units, $conc, $subjPtr, 
     $gtListPtr, $gtPtr) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[updateDNASample] $sample" ;

  $id = $sample->field("id") ;
  ( $actualType ) = $dbh->selectrow_array("select objType from Object 
                                           where id = $id") ;
  if ( $actualType ne "DNASample") {
    carp " ->[updateDNASample] Object with ID = $id is not a DNASample!" ;
    return(undef) ;
  }

  # Object
  $self->_updateObjAssocData($sample) ;

  # Sample
  if ( defined($date = $sample->field("dateCollected")) ) {
    $sth = $dbh->prepare( "update Sample 
                           set dateCollected = ? 
                           where sampleID = ?" ) ;
    if ($date eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($date, $id) ;
    }
    $sth->finish() ;
  }
  # DNASample
  if ( defined($amt = $sample->field("amount")) ) {
    $sth = $dbh->prepare( "update DNASample 
                           set amount = ? 
                           where dnaSampleID = ?" ) ;
    if ($amt eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($amt, $id) ;
    }
    $sth->finish() ;
  }
  if ( defined($units = $sample->field("amountUnits")) ) {
    $sth = $dbh->prepare( "update DNASample 
                           set amountUnits = ? 
                           where dnaSampleID = ?" ) ;
    if ($units eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($units, $id) ;
    }
    $sth->finish() ;
  }
  if ( defined($conc = $sample->field("concentration")) ) {
    $sth = $dbh->prepare( "update DNASample 
                           set concentration = ? 
                           where dnaSampleID = ?" ) ;
    if ($conc eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($conc, $id) ;
    }
    $sth->finish() ;
  }
  if ( defined($units = $sample->field("concUnits")) ) {
    $sth = $dbh->prepare( "update DNASample 
                           set concUnits = ? 
                           where dnaSampleID = ?" ) ;
    if ($units eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($units, $id) ;
    }
    $sth->finish() ;
  }
  # SubjectSample
  if ( defined($subjPtr = $sample->field("Subject")) ) {
    $sth = $dbh->prepare( "insert into SubjectSample 
                           (subjectID, sampleID)
                           values (?, ?)" ) ;
    if ( ref($subjPtr) eq "HASH" ) {
      $dbh->do( "delete from SubjectSample 
                 where sampleID = $id" ) ;
      $sth->execute($$subjPtr{id}, $id) ;
    } elsif ( ! ref($subjPtr) and ($subjPtr eq "DELETE") ) {
      $dbh->do( "delete from SubjectSample 
                 where sampleID = $id" ) ;
      $sth->execute(undef, $id) ;
    } else {
      carp " ->[updateDNASample] Inappropriate Subject value in $sample." ;
    }
    $sth->finish() ;
  }
  # SampleGenotype
  if ( defined($gtListPtr = $sample->field("Genotypes")) ) {
    $sth = $dbh->prepare( "insert into SampleGenotype 
                           (sampleID, gtID)
                           values (?, ?)" ) ;
    if ( ref($gtListPtr) eq "ARRAY" ) {
      $dbh->do( "delete from SampleGenotype 
                 where sampleID = $id" ) ;
      foreach $gtPtr (@$gtListPtr) {
	$sth->execute($id, $$gtPtr{id}) ;
      }
    } elsif ( ! ref($gtListPtr) and ($gtListPtr eq "DELETE") ) {
      $dbh->do( "delete from SampleGenotype 
                 where sampleID = $id" ) ;
    } else {
      carp " ->[updateDNASample] Inappropriate Genotypes value in $sample." ;
    }
    $sth->finish() ;
  }
  
  $DEBUG and carp " ->[updateDNASample] End." ;

  return(1) ;
}

=head2 updateTissueSample

  Function  : Update a Genetics::Object::TissueSample object in the database.
  Argument  : The Genetics::Object::TissueSample object to be updated.
  Returns   : 1 on success, undef otherwise.
  Scope     : Public

=cut

sub updateTissueSample {
  my($self, $sample) = @_ ;
  my($id, $actualType, $sth, $date, $tissue, $amt, $units, $subjPtr, 
     $dsListPtr, $dsPtr) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[updateTissueSample] $sample" ;

  $id = $sample->field("id") ;
  ( $actualType ) = $dbh->selectrow_array("select objType from Object 
                                           where id = $id") ;
  if ( $actualType ne "TissueSample") {
    carp " ->[updateTissueSample] Object with ID = $id is not a TissueSample!" ;
    return(undef) ;
  }

  # Object
  $self->_updateObjAssocData($sample) ;

  # Sample
  if ( defined($date = $sample->field("dateCollected")) ) {
    $sth = $dbh->prepare( "update Sample 
                           set dateCollected = ? 
                           where sampleID = ?" ) ;
    if ($date eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($date, $id) ;
    }
    $sth->finish() ;
  }
  # TissueSample
  $tissue = $sample->field("tissue") ;
  $dbh->do( "update TissueSample 
             set tissue = '$tissue' 
             where tissueSampleID = $id" ) ;
  if ( defined($amt = $sample->field("amount")) ) {
    $sth = $dbh->prepare( "update TissueSample 
                           set amount = ? 
                           where tissueSampleID = ?" ) ;
    if ($amt eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($amt, $id) ;
    }
    $sth->finish() ;
  }
  if ( defined($units = $sample->field("amountUnits")) ) {
    $sth = $dbh->prepare( "update TissueSample 
                           set amountUnits = ? 
                           where tissueSampleID = ?" ) ;
    if ($units eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($units, $id) ;
    }
    $sth->finish() ;
  }
  # SubjectSample
  if ( defined($subjPtr = $sample->field("Subject")) ) {
    $sth = $dbh->prepare( "insert into SubjectSample 
                           (subjectID, sampleID)
                           values (?, ?)" ) ;
    if ( ref($subjPtr) eq "HASH" ) {
      $dbh->do( "delete from SubjectSample 
                 where sampleID = $id" ) ;
      $sth->execute($$subjPtr{id}, $id) ;
    } elsif ( ! ref($subjPtr) and ($subjPtr eq "DELETE") ) {
      $dbh->do( "delete from SubjectSample 
                 where sampleID = $id" ) ;
      $sth->execute(undef, $id) ;
    } else {
      carp " ->[updateTissueSample] Inappropriate Subject value in $sample." ;
    }
    $sth->finish() ;
  }
  # TissueDNASample
  if ( defined($dsListPtr = $sample->field("DNASamples")) ) {
    $sth = $dbh->prepare( "insert into TissueDNASample 
                           (tissueSampleID, dnaSampleID)
                           values (?, ?)" ) ;
    if ( ref($dsListPtr) eq "ARRAY" ) {
      $dbh->do( "delete from TissueDNASample 
                 where tissueSampleID = $id" ) ;
      foreach $dsPtr (@$dsListPtr) {
	$sth->execute($id, $$dsPtr{id}) ;
      }
    } elsif ( ! ref($dsListPtr) and ($dsListPtr eq "DELETE") ) {
      $dbh->do( "delete from TissueDNASample 
                 where tissueSampleID = $id" ) ;
    } else {
      carp " ->[updateTissueSample] Inappropriate DNASamples value in $sample." ;
    }
    $sth->finish() ;
  }
  
  $DEBUG and carp " ->[updateTissueSample] End." ;

  return(1) ;
}

=head2 updateMap

  Function  : Update a Genetics::Object::Map object in the database.
  Argument  : The Genetics::Object::Map object to be updated.
  Returns   : 1 on success, undef otherwise.
  Scope     : Public

=cut

sub updateMap {
  my($self, $map) = @_ ;
  my($id, $actualType, $sth, $method, $units, $chr, $orgPtr, $orgID, $sortOrder, 
     $omeListPtr, $omePtr, $soPtr, $soID, $omeName) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[updateMap] $map" ;

  $id = $map->field("id") ;
  ( $actualType ) = $dbh->selectrow_array("select objType from Object 
                                           where id = $id") ;
  if ( $actualType ne "Map") {
    carp " ->[updateMap] Object with ID = $id is not a Map!" ;
    return(undef) ;
  }

  # Object
  $self->_updateObjAssocData($map) ;
  # Map data
  $method = $map->field("orderingMethod") ;
  $units = $map->field("distanceUnits") ;
  $dbh->do( "update Map 
             set orderingMethod = '$method', 
             distanceUnits = '$units' 
             where mapID = $id" ) ;
  if ( defined($chr = $map->field("chromosome")) ) {
    $sth = $dbh->prepare( "update Map 
                           set chromosome = ? 
                           where mapID = ?" ) ;
    if ($chr eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($chr, $id) ;
    }
    $sth->finish() ;
  }
  if ( defined($orgPtr = $map->field("Organism")) ) {
    $sth = $dbh->prepare( "update Map 
                           set organismID = ? 
                           where mapID = ?" ) ;
    if ( ref($orgPtr) eq "HASH" ) {
      $orgID = $self->_getOrganismID($orgPtr) ;
      $sth->execute($orgID, $id) ;
    } elsif ( ! ref($orgPtr) and ($orgPtr eq "DELETE") ) {
      $sth->execute(undef, $id) ;
    } else {
      carp " ->[_updateMap] Inappropriate Organism value in $map." ;
    }
    $sth->finish() ;
  }
  # OME
  $sortOrder = 1 ;
  $omeListPtr = $map->field("OrderedMapElements") ;
  $dbh->do( "delete from OrderedMapElement 
             where mapID = $id" ) ;
  $sth = $dbh->prepare( "insert into OrderedMapElement 
                         (omeID, mapID, soID, sortOrder, 
                          name, distance, comment) 
                         values (?, ?, ?, ?, ?, ?, ?)" ) ;
  foreach $omePtr (@$omeListPtr) {
    $soPtr = $$omePtr{SeqObj} ;
    $soID = $$soPtr{id} ;
    if ( ! defined ($omeName = $$soPtr{name}) ) {
      ( $omeName ) = $dbh->selectrow_array( "select name from Object 
                                             where id = $soID" )
    }
    $sth->execute(undef, $id, $soID, $sortOrder, $omeName, $$omePtr{distance}, $$omePtr{comment}) ;
    $sortOrder++ ;
  }
  $sth->finish() ;

  $DEBUG and carp " ->[updateMap] End." ;

  return(1) ;
}

=head1 Private methods

=head2 _updateObjAssocData

  Function  : Update data in, and associated with, the Object table/object.
  Argument  : The Genetics::Object object to be updated.
  Returns   : 1 on success, undef otherwise.
  Scope     : Private
  Called by : The various updateObjectSubClass methods.
  Comments  : The following Object fields cannot be modified: id, objType, 
              dateModified.

=cut

sub _updateObjAssocData {
  my($self, $obj) = @_ ;
  my($sth, $sth1, $id, $name, $date, $comment, $url, $naListPtr, $naPtr, 
     $contactName, $contactID, $newContactID, $contactPtr, $xRefListPtr, $xRefPtr, 
     $kwListPtr, $kwvPtr, $kwtName, $dataType, $descr, $value, $valueFieldName, 
     $kwtID, $newKwtID) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[_updateObjAssocData] $obj." ;

  $id = $obj->field("id") ;
  # Object fields
  if ( defined($name = $obj->field("name")) ) {
    $sth = $dbh->prepare( "update Object 
                           set name = ? 
                           where id = ?" ) ;
    $sth->execute($name, $id) ;
    $sth->finish() ;
  }
  if ( defined($date = $obj->field("dateCreated")) ) {
    $sth = $dbh->prepare( "update Object 
                           set dateCreated = ? 
                           where id = ?" ) ;
    $sth->execute($date, $id) ;
    $sth->finish() ;
  }
  if ( defined($comment = $obj->field("comment")) ) {
    $sth = $dbh->prepare( "update Object 
                           set comment = ? 
                           where id = ?" ) ;
    if ($comment eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($comment, $id) ;
    }
    $sth->finish() ;
  }
  if ( defined($url = $obj->field("url")) ) {
    $sth = $dbh->prepare( "update Object 
                           set url = ? 
                           where id = ?" ) ;
    if ($url eq "DELETE") {
      $sth->execute(undef, $id) ;
    } else {
      $sth->execute($url, $id) ;
    }
    $sth->finish() ;
  }
  # NameAlias
  if ( defined ($naListPtr = $obj->field("NameAliases")) ) {
    if ( ref($naListPtr) eq "ARRAY" ) {
      $dbh->do( "delete from NameAlias 
                 where objID = $id" ) ;
      $sth = $dbh->prepare( "insert into NameAlias 
                             (objID, name, contactID) 
                             values (?, ?, ?)" ) ;
      $sth1 = $dbh->prepare( "insert into Contact 
                              (contactID, name) 
                              values (?, ?)" ) ;
      foreach $naPtr (@$naListPtr) {
	if ( defined ($contactName = $$naPtr{contactName}) ) {
	  # See if there is already a Contact with the same name...
	  ( $contactID ) = $dbh->selectrow_array( "select contactID from Contact
                                                   where name = '$contactName'" ) ;
	  if ( defined ($contactID) ) {
	    # ...if so, insert a NamesAlias referencing the existing Contact
	    $sth->execute($id, $$naPtr{name}, $contactID) ;
	  } else {
	    # ...if not, create a new Contact...
	    $sth1->execute(undef, $contactName) ;
	    $newContactID = $sth1->{'mysql_insertid'} ;
	    # ...then insert NameAlias referencing the new Contact
	    $sth->execute($id, $$naPtr{name}, $newContactID) ;
	  }
	} else {
	  # Insert a NameAlias w/o a Contact reference
	  $sth->execute($id, $$naPtr{name}, undef) ;
	}
      }
      $sth->finish() ;
      $sth1->finish() ;
    } elsif ( ! ref($naListPtr) and ($naListPtr eq "DELETE") ) {
      $dbh->do( "delete from NameAlias 
                 where objID = $id" ) ;
    } else {
      carp " ->[_updateObjAssocData] Inappropriate NameAliases value in $obj." ;
    }
  }
  # Contact
  if ( defined ($contactPtr = $obj->field("Contact")) ) {
    if ( ref($contactPtr) eq "HASH" ) {
      # Don't delete Contacts, just delete references from Object to Contact
      # Need to check for an Address and deal with it if there is one
      $contactName = $$contactPtr{name} ;
      # See if there is already a Contact with the same name
      ( $contactID ) = $dbh->selectrow_array( "select contactID from Contact
                                               where name = '$contactName'" ) ;
      if ( defined ($contactID) ) {
	# If so, just add the contactID to Object
	$sth = $dbh->prepare( "update Object 
                               set contactID = ? 
                               where id = ? " ) ;
	$sth->execute($contactID, $id) ;
	$sth->finish() ;
      } else {
	# If not, create a new Contact...
	$sth = $dbh->prepare( "insert into Contact 
                               (contactID, addressID, name, organization, comment) 
                               values (?, ?, ?, ?, ?)" ) ;
	$sth->execute(undef, undef, $contactName, $$contactPtr{organization}, $$contactPtr{comment}) ;
	$newContactID = $sth->{'mysql_insertid'} ;
	$sth->finish() ;
	# then add the contactID to Object
	$sth = $dbh->prepare( "update Object 
                               set contactID = ? 
                               where id = ? " ) ;
	$sth->execute($newContactID, $id) ;
	$sth->finish() ;
      }
    } elsif ( ! ref($contactPtr) and ($contactPtr eq "DELETE")) {
      $sth = $dbh->prepare( "update Object 
                             set contactID = ? 
                             where id = ? " ) ;
	$sth->execute(undef, $id) ;
	$sth->finish() ;
    } else {
      carp " ->[_updateObjAssocData] Inappropriate Contact value in $obj." ;
    }
  }
  # DBXReferences
  if ( defined ($xRefListPtr = $obj->field("DBXReferences")) ) {
    if ( ref($xRefListPtr) eq "ARRAY" ) {
      $dbh->do( "delete from DBXReference 
                 where objID = $id" ) ;
      $sth = $dbh->prepare( "insert into DBXReference 
                             (dbXRefID, objID, accessionNumber, databaseName, 
                              schemaName, comment) 
                              values (?, ?, ?, ?, ?, ?)" ) ;
      foreach $xRefPtr (@$xRefListPtr) {
	$sth->execute(undef, $id, $$xRefPtr{accessionNumber}, $$xRefPtr{databaseName}, $$xRefPtr{schemaName}, $$xRefPtr{comment}) ;
      }
      $sth->finish() ;
    } elsif ( ! ref($xRefListPtr) and ($xRefListPtr eq "DELETE") ) {
      $dbh->do( "delete from DBXReference 
                 where objID = $id" ) ;
    } else {
      carp " ->[_updateObjAssocData] Inappropriate DBXReferences value in $obj." ;
    }
  }
  # Keywords
  if ( defined ($kwListPtr = $obj->field("Keywords")) ) {
    if ( ref($kwListPtr) eq "ARRAY" ) {
      $dbh->do( "delete from Keyword 
                 where objID = $id" ) ;
      foreach $kwvPtr (@$kwListPtr) {
	$kwtName = $$kwvPtr{name} ;
	$dataType = $$kwvPtr{dataType} ;
	$descr = $$kwvPtr{description} ;
	$value = $$kwvPtr{value} ;
	# Need to do this b/c there is only 1 value but there are 4 possible 
	# columns in which to put it:
	$valueFieldName = (lc $dataType) . "Value" ;
	( $kwtID ) = $dbh->selectrow_array( "select keywordTypeID from KeywordType 
                                             where name = '$kwtName' 
                                             and dataType = '$dataType'" ) ;
	if (defined $kwtID) {
	  # Just add the value to Keyword
	  $sth = $dbh->prepare( "insert into Keyword 
                                 (keywordID, objID, keywordTypeID, $valueFieldName) 
                                 values (?, ?, ?, ?) " ) ;
	  $sth->execute(undef, $id, $kwtID, $value) ;
	  $sth->finish() ;
	} else {
	  # Create new KeywordType...
	  $sth = $dbh->prepare( "insert into KeywordType 
                                 (keywordTypeID, name, dataType, description) 
                                 values (?, ?, ?, ?)" ) ;
	  $sth->execute(undef, $kwtName, $dataType, $descr) ;
	  $newKwtID = $sth->{'mysql_insertid'} ;
	  $sth->finish() ;
	  # then add the value to Keyword, referencing the new KeywordType
	  $sth = $dbh->prepare( "insert into Keyword 
                                 (keywordID, objID, keywordTypeID, $valueFieldName) 
                                 values (?, ?, ?, ?) " ) ;
	  $sth->execute(undef, $id, $newKwtID, $value) ;
	  $sth->finish() ;
	}
      }
    } elsif ( ! ref($kwListPtr) and ($kwListPtr eq "DELETE") ) {
      $dbh->do( "delete from Keyword 
                 where objID = $id" ) ;
    } else {
      carp " ->[_updateObjAssocData] Inappropriate Keywords value in $obj." ;
    }
  }

  $DEBUG and carp " ->[_updateObjAssocData] End." ;

  return(1) ;
}

=head2 _updateSubjectKindredRefs

  Function  : Updates references between Subjects and Kindreds.
  Argument  : A Subject ID and a Kindred ID (can be undef).
  Returns   : N/A
  Scope     : Private
  Called By : updateSubject() when Subject.kindredID is modified.
  Comments  : This method updates the KindredSubject table based on 
              a change to a Subject.kindredID field.

=cut

sub _updateSubjectKindredRefs {
  my($self, $subjID, $kindredID) = @_ ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[_updateSubjectKindredRefs]" ;

  $dbh->do( "delete from KindredSubject 
             where subjectID = $subjID" ) ;

  $dbh->do( "insert into KindredSubject 
             (kindredID, subjectID) 
             values ($kindredID, $subjID)" ) ;

  return(1) ;
}

=head2 _updateKindredSubjectRefs

  Function  : Updates references between Kindreds and Subjects.
  Argument  : A Kindred ID and an array reference to a list of Subject IDs.
  Returns   : N/A
  Scope     : Private
  Called By : updateSubject() and updateKindred().
  Comments  : This method updates the KindredSubject table based on a changes 
              made to a Kindred->Subjects field.
              This method also updates the Subject.kindredID field of each of 
              the relevant Subjects.

=cut

sub _updateKindredSubjectRefs {
  my($self, $kindredID, $subjIDListPtr) = @_ ;
  my($subjID) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[_updateKindredSubjectRefs]" ;

  $dbh->do( "delete from KindredSubject 
             where kindredID = $kindredID" ) ;

  foreach $subjID (@$subjIDListPtr) {
    $dbh->do( "insert into KindredSubject 
               (kindredID, subjectID) 
               values ($kindredID, $subjID)" ) ;
    $dbh->do( "update Subject 
               set kindredID = $kindredID 
               where subjectID = $subjID" ) ;
  }

  return(1) ;
}

=head2 _updateAssayAttrs

  Function  : Update AssayAttributes associated with a Genotype, AlleleCall 
              or Phenotype.
  Arguments : Array reference to the list of AssayAttributes, scalar 
              containing the type of object with which the AssayAttributes 
              are associated, and another scalar containing the id of that 
              object.
  Returns   : N/A
  Scope     : Private
  Called by : updateGenotype(), updatePhenotype().
  Comments  : 

=cut

sub _updateAssayAttrs {
  my($self, $aaListPtr, $type, $id) = @_ ;
  my($linkFieldName, $sthAA, $sthAV, $aaPtr, $aaName, $dataType, 
     $descr, $value, $valueFieldName, $aaID) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[_updateAssayAttrs] Start ($type)." ;

  # Need to derive $linkFieldName: AttributeValues can be 
  # associated with Gts/Pts or with AlleleCalls
  if ($type eq "AlleleCall") {
    $linkFieldName = "alleleCallID" ;
  } else {
    $linkFieldName = "objID" ;
  }
  
  if ( ref($aaListPtr) eq "ARRAY" ) {
    # Delete old AttributeValues...
    $dbh->do( "delete from AttributeValue 
               where $linkFieldName = $id" ) ;
    # ...then create the new ones.
    $sthAA = $dbh->prepare( "insert into AssayAttribute 
                             (attrID, name, dataType, description) 
                             values (?, ?, ?, ?)" ) ;
    foreach $aaPtr (@$aaListPtr) {
      $aaName = $$aaPtr{name} ;
      $dataType = $$aaPtr{dataType} ;
      $descr = $$aaPtr{description} ;
      $value = $$aaPtr{value} ;
      # Need to derive $valueFieldName: there is only 1 value,
      # but there are 4 possible columns in which to put it:
      $valueFieldName = (lc $dataType) . "Value" ;
      $sthAV = $dbh->prepare( "insert into AttributeValue 
                               (attrValueID, $linkFieldName, attrID, $valueFieldName) 
                               values (?, ?, ?, ?) ") ;
      # Get the AssayAttribute ID
      ( $aaID ) = $dbh->selectrow_array( "select attrID from AssayAttribute 
                                          where name = '$aaName' 
                                          and dataType = '$dataType'" ) ;
      if ( ! defined $aaID) {
	$sthAA->execute(undef, $aaName, $dataType, $descr) ;
	$aaID = $sthAA->{'mysql_insertid'} ;
      }
      $sthAV->execute(undef, $id, $aaID, $value) ;
      $sthAV->finish() ;
    }
    $sthAA->finish() ;
  } elsif ( ! ref($aaListPtr) and ($aaListPtr eq "DELETE") ) {
    # Delete the old AttributeValues
    $dbh->do( "delete from AttributeValue 
               where $linkFieldName = $id" ) ;
  } else {
    carp " ->[_updateAssayAttrs] Inappropriate AssayAttrs value." ;
  }
  
  $DEBUG and carp " ->[_updateAssayAttrs] End." ;

  return(1) ;
}

1;

