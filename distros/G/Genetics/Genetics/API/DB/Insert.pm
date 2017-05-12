# GenPerl module 
#

# POD documentation - main docs before the code

=head1 NAME

Genetics::API::DB::Insert

=head1 SYNOPSIS

  use Genetics::API ;

  $api = new Genetics::API(DSN => {driver => "mysql",
				   host => $Host,
				   database => $Database},
                           user => $UserName,
                           password => $Password) ;

  $snp = new Genetics::SNP( %init ) ;

  $id = $api->insertSNP($snp) ;

=head1 DESCRIPTION

The Genetics::API::DB packages provide an interface for the manipulation of
Genperl objects in a relational database.  This package contains the methods
for saving new objects (i.e. objects that have not been previously saved to
the database).  To update objects that have already been saved in the
database, see Genetics::API::DB::Update.  A better name for this package would
probably be Genetics::API::DB::Insert.

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

package Genetics::API::DB::Insert ;

BEGIN {
  $ID = "Genetics::API::DB::Insert" ;
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

@EXPORT = qw(insertCluster insertSubject insertKindred setSubjectSubjectReferences
             setSubjectKindredReferences setKindredSubjectReferences insertMarker 
             insertSNP insertGenotype insertStudyVariable insertPhenotype 
	     insertFrequencySource insertHtMarkerCollection insertHaplotype 
	     insertDNASample insertTissueSample insertMap 
	     _insertObjectData _insertAssayAttrs) ;
@EXPORT_OK = qw();

=head1 Public Methods

=head2 insertCluster

  Function  : Insert (create) a Genetics::Object::Cluster object to the database.
  Argument  : A Genetics::Object::Cluster object.
  Returns   : The id of the inserted object.
  Scope     : Public
  Comments  : Objects must be inserted before Clusters or this method will not be 
              able to set references to the Objects in a Cluster.

=cut

sub insertCluster {
    my($self, $cluster) = @_ ;
    my($id, $sth, $listPtr, $ref, $objectID) ;
    my $dbh = $self->{dbh} ;

    $DEBUG and carp " ->[insertCluster] $cluster." ;

    # Object data
    $id = $self->_insertObjectData($cluster) ;
    # Cluster fields
    $sth = $dbh->prepare( "insert into Cluster 
                           (clusterID, clusterType) 
                           values (?, ?)" ) ;
    $sth->execute($id, $cluster->field("clusterType")) ;
    $sth->finish() ;
    # ClusterContents fields
    if ( defined ($listPtr = $cluster->field("Contents")) ) {
      $sth = $dbh->prepare( "insert into ClusterContents 
                             (clusterID, objID) 
                             values (?, ?)" ) ;
      foreach $ref (@$listPtr) {
	# First, get the id of each object...
	if ( defined($$ref{id}) ) {
	  $objectID = $$ref{id} ;
	} else {
	  $objectID = $self->_getIDByImportID($$ref{importID}) ;
	}
	if ( defined $objectID) {
	  # ...then add the row to ClusterContents
	  $sth->execute($id, $objectID) ;
	} else {
	  carp " ->[insertCluster] Can't find an ID for Cluster item." ;
	}
      }
      $sth->finish() ;
    }
    
    $DEBUG and carp " ->[insertCluster] End." ;

    return($id) ;
  }

=head2 insertSubject

  Function  : Insert (create) a Genetics::Object::Subject object to the database.
  Argument  : A Genetics::Object::Subject object.
  Returns   : The id of the inserted object.
  Scope     : Public

=cut

sub insertSubject {
  my($self, $subj) = @_ ;
  my($id, $sth, $orgPtr, $orgID, $genusSpecies, $newOrgID, $kindredPtr, 
     $kindredID, $momPtr, $dadPtr, $subjID, $htListPtr, $htpPtr, $htID) ;
  my %sql = (
  InsertImportIDKeyword => "insert into Keyword 
                            (keywordID, objID, keywordTypeID, stringValue)
                            values (?, ?, ?, ?) ",
	    ) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[insertSubject] $subj." ;
  # Object data
  $id = $self->_insertObjectData($subj) ;
  # Subject fields
  $sth = $dbh->prepare( "insert into Subject 
                         (subjectID, organismID, kindredID, motherID, fatherID, 
                          gender, dateOfBirth, dateOfDeath, isProband) 
                         values (?, ?, ?, ?, ?, ?, ?, ?, ?)" ) ;
  $sth->execute($id, undef, undef, undef, undef, $subj->field("gender"), $subj->field("dateOfBirth"), $subj->field("dateOfDeath"), $subj->field("isProband")) ;
  $sth->finish() ;
  # Organism data
  if (defined ($orgPtr = $subj->field("Organism")) ) {
    $orgID = $self->_getOrganismID($orgPtr) ;
    $sth = $dbh->prepare( "update Subject 
                           set organismID = ?
                           where subjectID = ?" ) ;
    $sth->execute($orgID, $id) ;
    $sth->finish() ;
  }
  # Deal with Kindred, Mother and Father references
  # In some cases, these will only be inserted as ImportID Keywords which 
  # means that the real references must be set by calling the appropriate 
  # set**References() method.
  if ( defined($kindredPtr = $subj->field("Kindred")) ) {
    $sth = $dbh->prepare( "update Subject 
                           set kindredID = ?
                           where subjectID = ?" ) ;
    if ( defined($kindredID = $$kindredPtr{id}) ) {
      $sth->execute($kindredID, $id) ;
      $sth->finish() ;
    } elsif ( defined($$kindredPtr{importID}) ) {
      if ( defined($kindredID = $self->_getIDByImportID($$kindredPtr{importID})) ) {
	$sth->execute($kindredID, $id) ;
	$sth->finish() ;
      } else {
	$sth = $dbh->prepare( $sql{InsertImportIDKeyword} ) ;
	$sth->execute(undef, $id, 2, $$kindredPtr{importID}) ;
	$sth->finish() ;
      }
    }
  }
  if ( defined($momPtr = $subj->field("Mother")) ) {
    $sth = $dbh->prepare( "update Subject 
                           set motherID = ?
                           where subjectID = ?" ) ;
    if ( defined($subjID = $$momPtr{id}) ) {
      $sth->execute($subjID, $id) ;
      $sth->finish() ;
    } elsif ( defined($$momPtr{importID}) ) {
      if ( defined($subjID = $self->_getIDByImportID($$momPtr{importID})) ) {
	$sth->execute($subjID, $id) ;
	$sth->finish() ;
      } else {
	$sth = $dbh->prepare( $sql{InsertImportIDKeyword} ) ;
	$sth->execute(undef, $id, 3, $$momPtr{importID}) ;
	$sth->finish() ;
      }
    }
  }
  if ( defined($dadPtr = $subj->field("Father")) ) {
    $sth = $dbh->prepare( "update Subject 
                           set fatherID = ?
                           where subjectID = ?" ) ;
    if ( defined($subjID = $$dadPtr{id}) ) {
      $sth->execute($subjID, $id) ;
      $sth->finish() ;
    } elsif ( defined($$dadPtr{importID}) ) {
      if ( defined($subjID = $self->_getIDByImportID($$dadPtr{importID})) ) {
	$sth->execute($subjID, $id) ;
	$sth->finish() ;
      } else {
	$sth = $dbh->prepare( $sql{InsertImportIDKeyword} ) ;
	$sth->execute(undef, $id, 4, $$dadPtr{importID}) ;
	$sth->finish() ;
      }
    }
  }
  # Haplotype assignments
  if (defined ($htListPtr = $subj->field("Haplotypes")) ) {
    
    $sth = $dbh->prepare( "insert into SubjectHaplotype  
                           (haplotypeID, subjectID, phase)
                           values (?, ?, ?)" ) ;
    foreach $htpPtr (@$htListPtr) {
      if ( defined($htID = $htpPtr->{Haplotype}->{id}) ) {
	$sth->execute($htID, $id, $$htpPtr{phase}) ;
      } elsif ( defined($htID = $self->_getIDByImportID($htpPtr->{Haplotype}->{importID})) ) {
	$sth->execute($htID, $id, $$htpPtr{phase}) ;
      }
    }
    $sth->finish() ;
  }

  $DEBUG and carp " ->[insertSubject] End." ;

  return($id) ;
}

=head2 insertKindred

  Function  : Insert (create) a Genetics::Object::Kindred object to the database.
  Argument  : A Genetics::Object::Kindred object.
  Returns   : The id of the inserted object.
  Scope     : Public
  Comments  : Subjects must be inserted before Kindreds or this method will not be 
              able to set references to the Subjects in a Kindred.

=cut

sub insertKindred {
  my($self, $kindred) = @_ ;
  my($id, $sth, $kindredPtr, $parentID, $subjListPtr, $subjPtr, $subjID, 
     $sthS, $sthKS) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[insertKindred] $kindred." ;

  # Object data
  $id = $self->_insertObjectData($kindred) ;
  # Kindred fields
  $sth = $dbh->prepare( "insert into Kindred 
                         (kindredID, isDerived, parentID) 
                         values (?, ?, ?)" ) ;
  if ($kindred->isDerived == 1) {
    $kindredPtr = $kindred->DerivedFrom ;
    if ( defined($$kindredPtr{id}) ) {
      $parentID = $$kindredPtr{id} ;
    } else {
      $parentID = $self->_getIDByImportID($$kindredPtr{importID}) ;
    }
    $sth->execute($id, 1, $parentID) ;
    
  } else {
    $sth->execute($id, 0, undef) ;
  }
  $sth->finish() ;
  # KindredSubject
  if ( defined($subjListPtr = $kindred->field("Subjects")) ) {
    $sthKS = $dbh->prepare( "insert into KindredSubject 
                             (kindredID, subjectID) 
                             values (?, ?)" ) ;
    $sthS = $dbh->prepare( "update Subject 
                            set kindredID = ? 
                            where subjectID = ?" ) ;
    foreach $subjPtr (@$subjListPtr) {
      # Get the Subject ID...
      if ( defined($$subjPtr{id}) ) {
	$subjID = $$subjPtr{id} ;
      } else {
	$subjID = $self->_getIDByImportID($$subjPtr{importID}) ;
      }
      if (defined $subjID) {
	# ...add a row to KindredSubject...
	# This is not working with derived Kindreds when called from dns2gp.pl
	# I'm not sure where the problem is.  The print line is so the rows can
	# be added to KindredSubject manually.
	$kindred->isDerived == 1 and print "insert into KindredSubject (kindredID, subjectID) values ($id, $subjID);\n" ;
	$sthKS->execute($id, $subjID) ;
	# ...and if its not a derived Kindred, add a reference to the Subject table
	$kindred->isDerived == 0 and $sthS->execute($id, $subjID) ;
      }
    }
    $sthKS->finish() ;
    $sthS->finish() ;
  }

  $DEBUG and carp " ->[insertKindred] End." ;

  return($id) ;
}

=head2 setSubjectSubjectReferences

  Function  : Sets mother/father references between Subjects based on the 
              'Mother ImportID' and 'Father ImportID' Keywords associated 
              with the Subjects.
  Argument  : An array reference to a list of Subject IDs.
  Returns   : N/A
  Scope     : Public
  Comments  : The fields that are updated by this method are:
                   Subject.motherID
                   Subject.fatherID

=cut

sub setSubjectSubjectReferences {
  my($self, $idListPtr) = @_ ;
  my($sthM, $sthF, $sthS2, $sthS3, $id, $momImportID, $momID, $dadImportID, $dadID) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[setSubjectSubjectReferences]" ;

  $sthM = $dbh->prepare("select stringValue from Keyword where keywordTypeID = 3 and objID = ?") ;
  $sthF = $dbh->prepare("select stringValue from Keyword where keywordTypeID = 4 and objID = ?") ;
  $sthS2 = $dbh->prepare("update Subject set motherID=? where subjectID = ?") ;
  $sthS3 = $dbh->prepare("update Subject set fatherID=? where subjectID = ?") ;
  
  foreach $id (@$idListPtr) {
    # Mother refs
    # First see if this Subject has a 'Mother PreImportID' Keyword...
    $sthM->execute($id) ;
    ( $momImportID ) = $sthM->fetchrow_array() ;
    if (defined $momImportID) {
      # ...if so, find the Object.id of that Subject...
      $momID = $self->_getIDByImportID($momImportID) ;
      if (defined $momID) {
	# ...and then add the reference to the Subject table
	$sthS2->execute($momID, $id) ;
      }
    }
    # Father refs:
    # First see if this Subject has a 'Father PreImportID' Keyword...
    $sthF->execute($id) ;
    ( $dadImportID ) = $sthF->fetchrow_array() ;
    if (defined $dadImportID) {
      # ...if so, find the Object.id of that Subject
      $dadID = $self->_getIDByImportID($dadImportID) ;
      if (defined $dadID) {
	# ...and then add the reference to the Subject table
	$sthS3->execute($dadID, $id) ;
      }
    }
  }

  $sthM->finish() ;
  $sthF->finish() ;
  $sthS2->finish() ;
  $sthS3->finish() ;

  return(1) ;
}

=head2 setSubjectKindredReferences

  Function  : Sets references between Subjects and Kindreds based on the 
              'Kindred ImportID' Keywords associated with the Subjects.
  Argument  : An array reference to a list of Subject IDs.
  Returns   : N/A
  Scope     : Public
  Comments  : A Subject can get its Kindred reference in two possible ways:
              from Subject->field('Kindred') or
              from Kindred->field('Subjects').  This method sets references 
              based on the former.  To set references based on the latter, 
              use setKindredSubjectReferences.

              The fields that are updated by this method are:
                   Subject.kindredID
                   KindredSubject.kindredID
                   KindredSubject.SubjectID

=cut

sub setSubjectKindredReferences {
  my($self, $idListPtr) = @_ ;
  my($id, $sthK, $sthS1, $sthKS, $kindredImportID, $kindredID) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[setSubjectKindredReferences]" ;

  $sthK = $dbh->prepare("select stringValue from Keyword where keywordTypeID = 2 and objID = ?") ;
  $sthS1 = $dbh->prepare("update Subject set kindredID=? where subjectID = ?") ;
  $sthKS = $dbh->prepare("insert into KindredSubject (kindredID, subjectID) values (?, ?)") ;

  foreach $id (@$idListPtr) {
    # First see if this Subject has a 'Kindred ImportID' Keyword...
    $sthK->execute($id) ;
    ( $kindredImportID ) = $sthK->fetchrow_array() ;
    if (defined $kindredImportID) {
      # ...if so, find the Object.id of that Kindred...
      $kindredID = $self->_getIDByImportID($kindredImportID) ;
      # ...and then add the reference to the Subject table
      $sthS1->execute($kindredID, $id) ;
      # and add a corresponding row to KindredSubject
      $sthKS->execute($kindredID, $id) ;
    }
  }
  
  $sthK->finish() ;
  $sthS1->finish() ;
  $sthKS->finish() ;

  return(1) ;
}

=head2 setKindredSubjectReferences

  Function  : Sets references between Subjects and Kindreds based on the 
              'Subjects ImportID' Keywords associated with the Kindreds.
  Argument  : An array reference to a list of Kindred IDs.
  Returns   : N/A
  Scope     : Public
  Comments  : A Subject can get its Kindred reference in two possible ways:
              from Subject->field('Kindred') or
              from Kindred->field('Subjects').  This method sets references 
              based on the latter.  To set references based on the former, use 
              setSubjectKindredReferences.

              The fields that are updated by this method are:
                   Subject.kindredID
                   KindredSubject.kindredID
                   KindredSubject.SubjectID

=cut

sub setKindredSubjectReferences {
  my($self, $idListPtr) = @_ ;
  my($id, $sthK, $sthS1, $sthKS, $subjImportID, $subjID) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[setKindredSubjectReferences]" ;
  
  $sthK = $dbh->prepare("select stringValue from Keyword where keywordTypeID = 5 and objID = ?") ;
  $sthS1 = $dbh->prepare("update Subject set kindredID=? where subjectID = ?") ;
  $sthKS = $dbh->prepare("insert into KindredSubject (kindredID, subjectID) values (?, ?)") ;

  foreach $id (@$idListPtr) {
    # First see if the Kindred has any 'Subjects PreImportID' Keywords...
    $sthK->execute($id) ;
    while ( ($subjImportID) = $sthK->fetchrow_array() ) {
      #  ...if so, find the Object.id of each Subject...
      $subjID = $self->_getIDByImportID($subjImportID) ;
      if (defined $subjID) {
	# ...and then add the reference to the Subject table
	$sthS1->execute($id, $subjID) ;
	# and add a corresponding row to KindredSubject
	$sthKS->execute($id, $subjID) ;
      }
    }
  }
    
  $sthK->finish() ;
  $sthS1->finish() ;
  $sthKS->finish() ;

  return(1) ;
}

=head2 insertMarker

  Function  : Insert (create) a Genetics::Object::Marker object to the database.
  Argument  : A Genetics::Object::Marker object.
  Returns   : The id of the inserted object.
  Scope     : Public
  Comments  : 

=cut

sub insertMarker {
  my($self, $marker) = @_ ;
  my($id, $sth, $sth2, $orgPtr, $genusSpecies, $orgID, $newOrgID, $seqPtr, $seqID, $iscnListPtr, 
     $iscnPtr, $iscnID, $alleleListPtr, $allelePtr, $alleleID) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[insertMarker] $marker." ;

  # Object data
  $id = $self->_insertObjectData($marker) ;
  # SequenceObject fields
  $sth = $dbh->prepare( "insert into SequenceObject 
                         (seqObjectID, chromosome, organismID, 
                          sequenceID, malePloidy, femalePloidy)
                         values (?, ?, ?, ?, ?, ?)" ) ;
  $sth->execute($id, $marker->field("chromosome"), undef, undef, 
		$marker->field("malePloidy"), $marker->field("femalePloidy")) ;
  $sth->finish() ;
  # Organism data
  if (defined ($orgPtr = $marker->field("Organism")) ) {
    $orgID = $self->_getOrganismID($orgPtr) ;
    $sth = $dbh->prepare( "update SequenceObject 
                           set organismID = ? 
                           where seqObjectID = ?" ) ;
    $sth->execute($orgID, $id) ;
    $sth->finish() ;
  }
  # Sequence data
  if ( defined ($seqPtr = $marker->field("Sequence")) ) {
    # Insert the new Sequence...
    $sth = $dbh->prepare( "insert into Sequence 
                           (sequenceID, sequence, length, lengthUnits)
                           values (?, ?, ?, ?)" ) ;
    $sth->execute(undef, $$seqPtr{sequence}, $$seqPtr{length}, $$seqPtr{lengthUnits}) ;
    $seqID = $sth->{'mysql_insertid'} ;
    $sth->finish() ;
    # Add sequenceID to SequenceObject
    $sth = $dbh->prepare( "update SequenceObject 
                           set sequenceID = ? 
                           where seqObjectID = ?" ) ;
    $sth->execute($seqID, $id) ;
    $sth->finish() ;
  }
  # ISCNMapLocation data
  if ( defined ($iscnListPtr = $marker->field("ISCNMapLocations")) ) {
    $sth = $dbh->prepare( "insert into ISCNMapLocation 
                           (iscnMapLocID, chrNumber, chrArm, band, bandingMethod)
                           values (?, ?, ?, ?, ?)" ) ;
    $sth2 = $dbh->prepare( "insert into SeqObjISCN 
                            (seqObjectID, iscnMapLocID)
                            values (?, ?)" ) ;
    foreach $iscnPtr (@$iscnListPtr) {
      # Insert the new ISCNMapLocation
      $sth->execute(undef, $$iscnPtr{chrNumber}, $$iscnPtr{chrArm}, 
		    $$iscnPtr{band}, $$iscnPtr{bandingMethod}) ;
      $iscnID = $sth->{'mysql_insertid'} ;
      # Add a row to SeqObjISCN
      $sth2->execute($id, $iscnID) ;
    }
    $sth->finish() ;
    $sth2->finish() ;
  }
  # Marker fields
  $sth = $dbh->prepare( "insert into Marker 
                         (markerID, polymorphismType, polymorphismIndex1, 
                          polymorphismIndex2, repeatSequence) 
                         values (?, ?, ?, ?, ?)" ) ;
  $sth->execute($id, $marker->field("polymorphismType"), $marker->field("polymorphismIndex1"), 
		$marker->field("polymorphismIndex2"), $marker->field("repeatSequence") ) ;
  $sth->finish() ;
  # Allele fields
  if ( defined ($alleleListPtr = $marker->field("Alleles")) ) {
    $sth = $dbh->prepare( "insert into Allele 
                           (alleleID, poID, name, type)
                           values (?, ?, ?, ?)" ) ;
    foreach $allelePtr (@$alleleListPtr) {
      # Check if the Marker already has an Allele w/ the same name and type...
      ( $alleleID ) = $dbh->selectrow_array( "select alleleID from Allele 
                                              where poID = '$id' and 
                                              name = '$$allelePtr{name}' and 
                                              type = '$$allelePtr{type}'" ) ;
      if ( ! defined $alleleID) {
	# ...if not, create a new Allele
	$sth->execute(undef, $id, $$allelePtr{name}, $$allelePtr{type}) ;
      }
    }
    $sth->finish() ;
  }
    
  $DEBUG and carp " ->[insertMarker] End." ;
  
  return($id) ;
}

=head2 insertSNP

  Function  : Insert (create) a Genetics::Object::SNP object to the database.
  Argument  : A Genetics::Object::SNP object.
  Returns   : The id of the inserted object.
  Scope     : Public
  Comments  : 

=cut

sub insertSNP {
  my($self, $snp) = @_ ;
  my($id, $sth, $sth2, $orgPtr, $genusSpecies, $orgID, $newOrgID, $seqPtr, $seqID, $iscnListPtr, 
     $iscnPtr, $iscnID, $alleleListPtr, $allelePtr, $alleleID) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[insertSNP] $snp." ;

  # Object data
  $id = $self->_insertObjectData($snp) ;
  # SequenceObject fields
  $sth = $dbh->prepare( "insert into SequenceObject 
                         (seqObjectID, chromosome, organismID, 
                          sequenceID, malePloidy, femalePloidy)
                         values (?, ?, ?, ?, ?, ?)" ) ;
  $sth->execute($id, $snp->field("chromosome"), undef, undef, 
		$snp->field("malePloidy"), $snp->field("femalePloidy")) ;
  $sth->finish() ;
  # Organism data
  if (defined ($orgPtr = $snp->field("Organism")) ) {
    $orgID = $self->_getOrganismID($orgPtr) ;
    $sth = $dbh->prepare( "update SequenceObject 
                           set organismID = ? 
                           where seqObjectID = ?" ) ;
    $sth->execute($orgID, $id) ;
    $sth->finish() ;
  }
  # Sequence data
  if ( defined ($seqPtr = $snp->field("Sequence")) ) {
    # Insert the new Sequence...
    $sth = $dbh->prepare( "insert into Sequence 
                           (sequenceID, sequence, length, lengthUnits)
                           values (?, ?, ?, ?)" ) ;
    $sth->execute(undef, $$seqPtr{sequence}, $$seqPtr{length}, $$seqPtr{lengthUnits}) ;
    $seqID = $sth->{'mysql_insertid'} ;
    $sth->finish() ;
    # Add sequenceID to SequenceObject
    $sth = $dbh->prepare( "update SequenceObject 
                           set sequenceID = ? 
                           where seqObjectID = ?" ) ;
    $sth->execute($seqID, $id) ;
    $sth->finish() ;
  }
  # ISCNMapLocation data
  if ( defined ($iscnListPtr = $snp->field("ISCNMapLocations")) ) {
    $sth = $dbh->prepare( "insert into ISCNMapLocation 
                           (iscnMapLocID, chrNumber, chrArm, band, bandingMethod)
                           values (?, ?, ?, ?, ?)" ) ;
    $sth2 = $dbh->prepare( "insert into SeqObjISCN 
                            (seqObjectID, iscnMapLocID)
                            values (?, ?)" ) ;
    foreach $iscnPtr (@$iscnListPtr) {
      # Insert the new ISCNMapLocation
      $sth->execute(undef, $$iscnPtr{chrNumber}, $$iscnPtr{chrArm}, 
		    $$iscnPtr{band}, $$iscnPtr{bandingMethod}) ;
      $iscnID = $sth->{'mysql_insertid'} ;
      # Add a row to SeqObjISCN
      $sth2->execute($id, $iscnID) ;
    }
    $sth->finish() ;
    $sth2->finish() ;
  }
  # SNP fields
  $sth = $dbh->prepare( "insert into SNP 
                         (snpID, snpType, functionClass, snpIndex, 
                          isConfirmed, confirmMethod) 
                         values (?, ?, ?, ?, ?, ?)" ) ;
  $sth->execute($id, $snp->field("snpType"), $snp->field("functionClass"), $snp->field("snpIndex"), 
		$snp->field("isConfirmed"), $snp->field("confirmMethod")) ;
  $sth->finish() ;
  # Allele fields
  if ( defined ($alleleListPtr = $snp->field("Alleles")) ) {
    $sth = $dbh->prepare( "insert into Allele 
                           (alleleID, poID, name, type)
                           values (?, ?, ?, ?)" ) ;
    foreach $allelePtr (@$alleleListPtr) {
      # Check if the Marker already has an Allele w/ the same name and type...
      ( $alleleID ) = $dbh->selectrow_array( "select alleleID from Allele 
                                              where poID = '$id' and 
                                              name = '$$allelePtr{name}' and 
                                              type = '$$allelePtr{type}'" ) ;
      if ( ! defined $alleleID) {
	# ...if not, create a new Allele
	$sth->execute(undef, $id, $$allelePtr{name}, $$allelePtr{type}) ;
      }
    }
    $sth->finish() ;
  }
    
  $DEBUG and carp " ->[insertSNP] End." ;

  return($id) ;
}

=head2 insertGenotype

  Function  : Insert (create) a Genetics::Object::Genotype object to the database.
  Argument  : A Genetics::Object::Genotype object.
  Returns   : The id of the inserted object.
  Scope     : Public
  Comments  : 

=cut

sub insertGenotype {
  my($self, $gt) = @_ ;
  my($id, $sth, $subjPtr, $subjectID, $markerPtr, $markerID, $sortOrder, $sthA, 
     $sthAC, $alleleCallListPtr, $alleleCallPtr, $alleleID, $alleleCallID, $aaListPtr) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[insertGenotype] $gt." ;

  # Object data
  $id = $self->_insertObjectData($gt) ;
  # Get Subject ID
  $subjPtr = $gt->field("Subject") ;
  if ( defined($$subjPtr{id}) ) {
    $subjectID = $$subjPtr{id} ;
  } else {
    $subjectID = $self->_getIDByImportID($$subjPtr{importID}) ;
  }
  if ( ! defined $subjectID) {
    carp " ->[insertGenotype] Can't insert Genotype $gt. Can't find Subject.id!" ;
    return(undef) ;
  }
  # Get Marker ID
  $markerPtr = $gt->field("Marker") ;
  if ( defined($$markerPtr{id}) ) {
    $markerID = $$markerPtr{id} ;
  } else {
    $markerID = $self->_getIDByImportID($$markerPtr{importID}) ;
  }
  if ( ! defined $markerID) {
    carp " ->[insertGenotype] Can't insert Genotype $gt. Can't find Marker.id!" ;
    return(undef) ;
  }
  # Genotype fields
  $sth = $dbh->prepare( "insert into Genotype 
                         (gtID, subjectID, poID, isActive, icResult, dateCollected) 
                         values (?, ?, ?, ?, ?, ?)" ) ;
  $sth->execute($id, $subjectID, $markerID, $gt->field("isActive"), $gt->field("icResult"), 
		$gt->field("dateCollected")) ;
  $sth->finish() ;
  # Genotype AssayAttributes
  if ( defined ($aaListPtr = $gt->field("AssayAttrs")) ) {
    $self->_insertAssayAttrs($aaListPtr, "Genotype", $id) ;
  }
  # AlleleCall data
  $sortOrder = 1 ;
  $sthA = $dbh->prepare( "insert into Allele 
                          (alleleID, poID, name, type)
                          values (?, ?, ?, ?)" ) ;
  $sthAC = $dbh->prepare( "insert into AlleleCall 
                           (alleleCallID, gtID, alleleID, sortOrder, phase) 
                           values (?, ?, ?, ?, ?)" ) ;
  $alleleCallListPtr = $gt->field("AlleleCalls") ;
  foreach $alleleCallPtr (@$alleleCallListPtr) {
    # Check if the Marker already has an Allele w/ the same name and type...
    ( $alleleID ) = $dbh->selectrow_array( "select alleleID from Allele 
                                            where poID = '$markerID' and 
                                            name = '$$alleleCallPtr{alleleName}' and 
                                            type = '$$alleleCallPtr{alleleType}'" ) ;
    if ( ! defined $alleleID) {
      # ...if not, create a new Allele
      $sthA->execute(undef, $markerID, $$alleleCallPtr{alleleName}, $$alleleCallPtr{alleleType}) ;
      $alleleID = $sthA->{'mysql_insertid'} ;
    }
    $sthAC->execute(undef, $id, $alleleID, $sortOrder, $$alleleCallPtr{phase}) ;
    $alleleCallID = $sthAC->{'mysql_insertid'} ;
    $sortOrder++ ;
    # AlleleCall AssayAttributes
    if ( defined ($aaListPtr = $$alleleCallPtr{AssayAttrs}) ) {
      $self->_insertAssayAttrs($aaListPtr, "AlleleCall", $alleleCallID) ;
    }
  }
  $sthA->finish() ;
  $sthAC->finish() ;

  $DEBUG and carp " ->[insertGenotype] End." ;

  return($id) ;
}

=head2 insertStudyVariable

  Function  : Insert (create) a Genetics::Object::StudyVariable object to the database.
  Argument  : A Genetics::Object::StudyVariable object.
  Returns   : The id of the inserted object.
  Scope     : Public
  Comments  : 

=cut

sub insertStudyVariable {
  my($self, $sv) = @_ ;
  my($id, $svFormat, $svCategory, $sth, $codesListPtr, $codePtr, $cdID, $asdPtr, 
     $asdID, $aseListPtr, $asePtr, $sth1, $lcDefPtr, $lcdID, $lcListPtr, $lcPtr) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[insertStudyVariable] $sv." ;

  # Object data
  $id = $self->_insertObjectData($sv) ;
  # StudyVariable fields
  $svFormat = $sv->field("format") ;
  $svCategory = $sv->field("category") ;
  $sth = $dbh->prepare( "insert into StudyVariable 
                         (studyVariableID, category, format, isXLinked, 
                          description, numberLowerBound, numberUpperBound, 
                          dateLowerBound, dateUpperBound)
                         values (?, ?, ?, ?, ?, ?, ?, ?, ?)" ) ;
  if ( $svFormat eq "Number") {
    $sth->execute($id, $svCategory, $svFormat, $sv->field("isXLinked"), $sv->field("description"), $sv->field("lowerBound"), $sv->field("upperBound"), undef, undef) ;
  } elsif ( $svFormat eq "Date") {
    $sth->execute($id, $svCategory, $svFormat, $sv->field("isXLinked"), $sv->field("description"), undef, undef, $sv->field("lowerBound"), $sv->field("upperBound")) ;
  } else {
    $sth->execute($id, $svCategory, $svFormat, $sv->field("isXLinked"), $sv->field("description"), undef, undef, undef, undef) ;
  }
  $sth->finish() ;
  # Code data
  if ( $svFormat eq "Code" ) {
    $sth = $dbh->prepare( "insert into CodeDerivation 
                           (codeDerivationID, studyVariableID, code, 
                            description, formula) 
                           values (?, ?, ?, ?, ?)" ) ;
    if ($svCategory eq "StaticLiabilityClass") {
      $sth1 = $dbh->prepare( "insert into StaticLCPenetrance 
                              (cdID, pen11, pen12, pen22, malePen1, malePen2)
                              values (?, ?, ?, ?, ?, ?)" ) ;
    }
    $codesListPtr = $sv->field("Codes") ;
    foreach $codePtr (@$codesListPtr) {
      $sth->execute(undef, $id, $$codePtr{code}, $$codePtr{description}, undef) ;
      $cdID = $sth->{'mysql_insertid'} ;
      if ($svCategory eq "StaticLiabilityClass") {
	$sth1->execute($cdID, $$codePtr{pen11}, $$codePtr{pen12}, $$codePtr{pen22}, $$codePtr{malePen1}, $$codePtr{malePen2}) ;
      }
    }
  }
  # AffectionStatus data
  if ( $svCategory =~ /AffectionStatus$/ ) {
    $asdPtr = $sv->field("AffStatDef") ;
    $sth = $dbh->prepare( "insert into AffectionStatusDefinition 
                           (asDefID, studyVariableID, name, diseaseAlleleFreq, 
                            pen11, pen12, pen22, malePen1, malePen2) 
                           values (?, ?, ?, ?, ?, ?, ?, ?, ?)" ) ;
    $sth->execute(undef, $id, $$asdPtr{name}, $$asdPtr{diseaseAlleleFreq}, $$asdPtr{pen11}, $$asdPtr{pen12}, $$asdPtr{pen22}, $$asdPtr{malePen1}, $$asdPtr{malePen2}) ;
    $asdID = $sth->{'mysql_insertid'} ;
    $sth->finish() ;
    # AffectionStatusElement fields
    if ( defined($aseListPtr = $$asdPtr{AffStatElements}) ) {
      $sth = $dbh->prepare( "insert into AffectionStatusElement 
                             (asElementID, asDefID, code, type, formula) 
                             values (?, ?, ?, ?, ?)" ) ;
      foreach $asePtr (@$aseListPtr) {
	$sth->execute(undef, $asdID, $$asePtr{code}, $$asePtr{type}, $$asePtr{formula}) ;
      }
      $sth->finish() ;
    }
    # LiabilityClass data
    # NB: these are dynamic LCs; if the SV is of category StaticLiabilityClass,
    # the penetrance values are handled with the Codes and are stored in the 
    # StaticLCPenetrance table
    if ( defined($lcDefPtr = $sv->field("LCDef")) ) {
      $sth = $dbh->prepare( "insert into LiabilityClassDefinition 
                             (lcDefID, studyVariableID, name) 
                             values (?, ?, ?)" ) ;
      $sth->execute(undef, $id, $$lcDefPtr{name}) ;
      $lcdID = $sth->{'mysql_insertid'} ;
      $sth->finish() ;
      # LiabilityClass fields
      $lcListPtr = $$lcDefPtr{LiabilityClasses} ;
      $sth = $dbh->prepare( "insert into LiabilityClass 
                             (lcID, lcDefID, code, description, pen11, pen12, 
                             pen22, malePen1, malePen2, formula) 
                             values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)" ) ;
      foreach $lcPtr (@$lcListPtr) {
	$sth->execute(undef, $lcdID, $$lcPtr{code}, $$lcPtr{description}, $$lcPtr{pen11}, $$lcPtr{pen12}, $$lcPtr{pen22}, $$lcPtr{malePen1}, $$lcPtr{malePen2}, $$lcPtr{formula}) ;
      }
      $sth->finish() ;
    }
  }
  
  $DEBUG and carp " ->[insertStudyVariable] End." ;

  return($id) ;
}

=head2 insertPhenotype

  Function  : Insert (create) a Genetics::Object::Phenotype object to the database.
  Argument  : A Genetics::Object::Phenotype object.
  Returns   : The id of the inserted object.
  Scope     : Public
  Comments  : 

=cut

sub insertPhenotype {
  my($self, $pt) = @_ ;
  my($id, $sth, $subjPtr, $subjectID, $studyVarPtr, $studyVarID, $svFormat, $aaListPtr) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[insertPhenotype] $pt." ;

  # Object data
  $id = $self->_insertObjectData($pt) ;
  # Get Subject ID
  $subjPtr = $pt->field("Subject") ;
  if ( defined($$subjPtr{id}) ) {
    $subjectID = $$subjPtr{id} ;
  } else {
    $subjectID = $self->_getIDByImportID($$subjPtr{importID}) ;
  }
  if ( ! defined $subjectID) {
    carp " ->[insertPhenotype] Can't insert Phenotype $pt. Can't find Subject.id!" ;
    return(undef) ;
  }
  # Get StudyVariable ID
  $studyVarPtr = $pt->field("StudyVariable") ;
  if ( defined($$studyVarPtr{id}) ) {
    $studyVarID = $$studyVarPtr{id} ;
  } else {
    $studyVarID = $self->_getIDByImportID($$studyVarPtr{importID}) ;
  }
  if ( ! defined $studyVarID) {
    carp " ->[insertPhenotype] Can't insert Phenotype $pt. Can't find StudyVariable.id!" ;
    return(undef) ;
  }
  # Phenotype fields
  # First, find out what the format of the value is:
  ( $svFormat ) = $dbh->selectrow_array( "select format from StudyVariable
                                          where studyVariableID = '$studyVarID'" ) ;
  $sth = $dbh->prepare( "insert into Phenotype 
                         (ptID, subjectID, svID, numberValue, codeValue, 
                          dateValue, isActive, dateCollected) 
                         values (?, ?, ?, ?, ?, ?, ?, ?)" ) ;
  if ($svFormat eq "Number") {
    $sth->execute($id, $subjectID, $studyVarID, $pt->field("value"), undef, undef, $pt->field("isActive"), $pt->field("dateCollected")) ;
  } elsif ($svFormat eq "Code") {
    $sth->execute($id, $subjectID, $studyVarID, undef, $pt->field("value"), undef, $pt->field("isActive"), $pt->field("dateCollected")) ;
  } elsif ($svFormat eq "Date") {
    $sth->execute($id, $subjectID, $studyVarID, undef, undef, $pt->field("value"), $pt->field("isActive"), $pt->field("dateCollected")) ;
  } else {
    carp " ->[insertPhenotype] Can't insert Phenotype $pt. Unknown StudyVariable format!" ;
    return(undef) ;
  }
  $sth->finish() ;
  # Phenotype AssayAttributes
  if ( defined ($aaListPtr = $pt->field("AssayAttrs")) ) {
    $self->_insertAssayAttrs($aaListPtr, "Phenotype", $id) ;
  }
  
  $DEBUG and carp " ->[insertPhenotype] End." ;

  return($id) ;
}

=head2 insertFrequencySource

  Function  : Insert (create) a Genetics::Object::FrequencySource object to the database.
  Argument  : A Genetics::Object::FrequencySource object.
  Returns   : The id of the inserted object.
  Scope     : Public
  Comments  : 

=cut

sub insertFrequencySource {
  my($self, $fs) = @_ ;
  my($sthA, $sthOF, $sthFSOF, $id, $listPtr, $oafPtr, $allelePtr, $markerPtr, $markerID, 
     $alleleID, $obsFreqID, $ohfPtr, $htPtr, $htID) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[insertFrequencySource] $fs." ;

  $sthA = $dbh->prepare( "insert into Allele 
                          (alleleID, poID, name, type)
                          values (?, ?, ?, ?)"  ) ;
  $sthOF = $dbh->prepare( "insert into ObsFrequency 
                           (obsFreqID, type, alleleID, htID, frequency) 
                           values (?, ?, ?, ?, ?)" ) ;
  $sthFSOF = $dbh->prepare( "insert into FreqSourceObsFrequency 
                             (freqSourceID, obsFreqID)
                             values (?, ?)" ) ;

  # Object data
  $id = $self->_insertObjectData($fs) ;
  # ObsFrequency data
  # Alleles
  if ( defined ($listPtr = $fs->field("ObsAlleleFrequencies")) ) {
    foreach $oafPtr (@$listPtr) {
      # Figure out what Allele we're talking about.  First find the Marker ID...
      $allelePtr = $$oafPtr{Allele} ;
      $markerPtr = $$allelePtr{Marker} ;
      if ( defined($$markerPtr{id}) ) {
	$markerID = $$markerPtr{id} ;
      } else {
	$markerID = $self->_getIDByImportID($$markerPtr{importID}) ;
      }
      if ( ! defined $markerID) {
	carp " ->[insertFrequencySource] Can't find an ID for Marker $$markerPtr{name}" ;
	return(undef) ;
      }
      # ...then see if the Marker already has an Allele w/ the same name and type...
      ( $alleleID ) = $dbh->selectrow_array( "select alleleID from Allele 
                                              where poID = '$markerID' and 
                                              name = '$$allelePtr{name}' and 
                                              type = '$$allelePtr{type}'" ) ;
      if ( ! defined $alleleID) {
	# ...if not, create a new Allele
	$sthA->execute(undef, $markerID, $$allelePtr{name}, $$allelePtr{type}) ;
	$alleleID = $sthA->{'mysql_insertid'} ;
      }
      # Insert the ObsFrequency
      $sthOF->execute(undef, "Allele", $alleleID, undef, $$oafPtr{frequency}) ;
      $obsFreqID = $sthOF->{'mysql_insertid'} ;
      # Add row to FreqSourceObsFrequency
      $sthFSOF->execute($id, $obsFreqID) ;
    }
  }
  $sthA->finish() ;
  # Haplotypes
  if ( defined ($listPtr = $fs->field("ObsHtFrequencies")) ) {
    foreach $ohfPtr (@$listPtr) {
      # Figure out what Haplotype we're talking about.
      $htPtr = $$ohfPtr{Haplotype} ;
      if ( defined($$htPtr{id}) ) {
	$htID = $$htPtr{id} ;
      } else {
	$htID = $self->_getIDByImportID($$htPtr{importID}) ;
      }
      if ( ! defined $htID) {
	carp " ->[insertFrequencySource] Can't find an ID for Haplotype $$htPtr{name}" ;
	return(undef) ;
      }
      # Insert the ObsFrequency
      $sthOF->execute(undef, "Ht", undef, $htID, $$ohfPtr{frequency}) ;
      $obsFreqID = $sthOF->{'mysql_insertid'} ;
      # Add row to FreqSourceObsFrequency
      $sthFSOF->execute($id, $obsFreqID) ;
    }
  }
  $sthOF->finish() ;
  $sthFSOF->finish() ;

  $DEBUG and carp " ->[insertFrequencySource] End." ;

  return($id) ;
}

=head2 insertHtMarkerCollection

  Function  : Insert (create) a Genetics::Object::HtMarkerCollection object to the database.
  Argument  : A Genetics::Object::HtMarkerCollection object.
  Returns   : The id of the inserted object.
  Scope     : Public
  Comments  : 

=cut

sub insertHtMarkerCollection {
  my($self, $hmc) = @_ ;
  my($id, $sth, $sortOrder, $poListPtr, $poPtr, $poID) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[insertHtMarkerCollection] $hmc." ;

  # Object data
  $id = $self->_insertObjectData($hmc) ;
  # HtMarkerCollection fields
  $sth = $dbh->prepare( "insert into HtMarkerCollection 
                         (hmcID, distanceUnits)
                         values (?, ?)" ) ;
  $sth->execute($id, $hmc->field("distanceUnits")) ;
  $sth->finish() ;
  # HMCPolyObj fields
  $sortOrder = 1 ;
  $poListPtr = $hmc->field("Markers") ;
  $sth = $dbh->prepare( "insert into HMCPolyObj 
                         (hmcID, poID, sortOrder, distance) 
                         values (?, ?, ?, ?)" ) ;
  foreach $poPtr (@$poListPtr) {
    if ( defined($$poPtr{id}) ) {
      $poID = $$poPtr{id} ;
    } else {
      $poID = $self->_getIDByImportID($$poPtr{importID}) ;
    }
    if ( ! defined $poID) {
      carp " ->[insertHtMarkerCollection] Can't find an ID for Marker $$poPtr{name}" ;
      return(undef) ;
    }
    $sth->execute($id, $poID, $sortOrder, $$poPtr{distToNext}) ;
    $sortOrder++ ;
  }
  $sth->finish() ;

  $DEBUG and carp " ->[insertHtMarkerCollection] End." ;

  return($id) ;
}

=head2 insertHaplotype

  Function  : Insert (create) a Genetics::Object::Haplotype object to the database.
  Argument  : A Genetics::Object::Haplotype object.
  Returns   : The id of the inserted object.
  Scope     : Public
  Comments  : 

=cut

sub insertHaplotype {
  my($self, $ht) = @_ ;
  my($id, $sth, $sthA, $hmcPtr, $hmcID, $sortOrder, $alleleListPtr, $allelePtr, $poID, $alleleID) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[insertHaplotype] $ht." ;

  # Object data
  $id = $self->_insertObjectData($ht) ;
  # Haplotype fields
  $sth = $dbh->prepare( "insert into Haplotype 
                         (haplotypeID, hmcID)
                         values (?, ?)" ) ;
  $hmcPtr = $ht->field("MarkerCollection") ;
  if ( defined($$hmcPtr{id}) ) {
    $hmcID = $$hmcPtr{id} ;
  } else {
    $hmcID = $self->_getIDByImportID($$hmcPtr{importID}) ;
  }
  if ( ! defined $hmcID) {
    carp " ->[insertHaplotype] Can't find ID for HtMarkerCollection $$hmcPtr{name}" ;
    return(undef) ;
  }
  $sth->execute($id, $hmcID) ;
  $sth->finish() ;
  # HaplotypeAllele fields
  $sortOrder = 1 ;
  $alleleListPtr = $ht->field("Alleles") ;
  $sth = $dbh->prepare( "insert into HaplotypeAllele 
                         (haplotypeID, alleleID, sortOrder) 
                         values (?, ?, ?)" ) ;
  $sthA = $dbh->prepare( "insert into Allele 
                          (alleleID, poID, name, type)
                          values (?, ?, ?, ?)" ) ;
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

  $DEBUG and carp " ->[insertHaplotype] $ht." ;

  return($id) ;
}

=head2 insertDNASample

  Function  : Insert (create) a Genetics::Object::DNASample object to the database.
  Argument  : A Genetics::Object::DNASample object.
  Returns   : The id of the inserted object.
  Scope     : Public
  Comments  : 

=cut

sub insertDNASample {
  my($self, $sample) = @_ ;
  my($id, $sth, $subjPtr, $subjID, $gtListPtr, $gtPtr, $gtID) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[insertDNASample] $sample." ;

  # Object data
  $id = $self->_insertObjectData($sample) ;
  # Sample fields
  $sth = $dbh->prepare( "insert into Sample 
                         (sampleID, type, dateCollected)
                         values (?, ?, ?)" ) ;
  $sth->execute($id, "DNA", $sample->field("dateCollected")) ;
  $sth->finish() ;
  $sth = $dbh->prepare( "insert into DNASample 
                         (dnaSampleID, amount, amountUnits, 
                          concentration, concUnits) 
                         values (?, ?, ?, ?, ?)" ) ;
  $sth->execute($id, $sample->field("amount"), $sample->field("amountUnits"), $sample->field("concentration"), $sample->field("concUnits")) ;
  $sth->finish() ;
  # SubjectSample data
  if ( defined ($subjPtr = $sample->field("Subject")) ) {
    if ( defined($$subjPtr{id}) ) {
      $subjID = $$subjPtr{id} ;
    } else {
      $subjID = $self->_getIDByImportID($$subjPtr{importID}) ;
    }
    if (defined $subjID) {
      $sth = $dbh->prepare( "insert into SubjectSample 
                             (subjectID, sampleID) 
                             values (?, ?)" ) ;
      $sth->execute($subjID, $id) ;
      $sth->finish() ;
    }
  }
  # SampleGenotype data
  if ( defined ($gtListPtr = $sample->field("Genotypes")) ) {
    foreach $gtPtr (@$gtListPtr) {
      if ( defined($$gtPtr{id}) ) {
	$gtID = $$gtPtr{id} ;
      } else {
	$gtID = $self->_getIDByImportID($$gtPtr{importID}) ;
      }
      if (defined $gtID) {
	$sth = $dbh->prepare( "insert into SampleGenotype 
                               (sampleID, gtID) 
                               values (?, ?)" ) ;
	$sth->execute($id, $gtID) ;
	$sth->finish() ;
      }
    }
  }

  $DEBUG and carp " ->[insertDNASample] End." ;

  return($id) ;
}

=head2 insertTissueSample

  Function  : Insert (create) a Genetics::Object::TissueSample object to the database.
  Argument  : A Genetics::Object::TissueSample object.
  Returns   : The id of the inserted object.
  Scope     : Public
  Comments  : 

=cut

sub insertTissueSample {
  my($self, $sample) = @_ ;
  my($id, $sth, $dsListPtr, $dsPtr, $dsID, $subjPtr, $subjID, $gtListPtr, $gtPtr, $gtID) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[insertTissueSample] $sample." ;

  # Object data
  $id = $self->_insertObjectData($sample) ;
  # Sample fields
  $sth = $dbh->prepare( "insert into Sample 
                         (sampleID, type, dateCollected)
	                 values (?, ?, ?)" ) ;
  $sth->execute($id, "Tissue", $sample->field("dateCollected")) ;
  $sth->finish() ;
  $sth = $dbh->prepare( "insert into TissueSample 
                         (tissueSampleID, tissue, amount, amountUnits) 
                         values (?, ?, ?, ?)" ) ;
  $sth->execute($id, $sample->field("tissue"), $sample->field("amount"), $sample->field("amountUnits")) ;
  $sth->finish() ;
  # TissueDNASample data
  if ( defined ($dsListPtr = $sample->field("DNASamples")) ) {
    foreach $dsPtr (@$dsListPtr) {
      if ( defined($$dsPtr{id}) ) {
	$dsID = $$dsPtr{id} ;
      } else {
	$dsID = $self->_getIDByImportID($$dsPtr{importID}) ;
      }
      if (defined $dsID) {
	$sth = $dbh->prepare( "insert into TissueDNASample 
                               (tissueSampleID, dnaSampleID)
                               values (?, ?)" ) ;
	$sth->execute($id, $dsID) ;
	$sth->finish() ;
      }
    }
  }
  # SampleSubject data
  if ( defined ($subjPtr = $sample->field("Subject")) ) {
    if ( defined($$subjPtr{id}) ) {
      $subjID = $$subjPtr{id} ;
    } else {
      $subjID = $self->_getIDByImportID($$subjPtr{importID}) ;
    }
    if (defined $subjID) {
      $sth = $dbh->prepare( "insert into SubjectSample 
                             (subjectID, sampleID) 
                             values (?, ?)" ) ;
      $sth->execute($subjID, $id) ;
      $sth->finish() ;
    }
  }
  # SampleGenotype data
  if ( defined ($gtListPtr = $sample->field("Genotypes")) ) {
    foreach $gtPtr (@$gtListPtr) {
      if ( defined($$gtPtr{id}) ) {
	$gtID = $$gtPtr{id} ;
      } else {
	$gtID = $self->_getIDByImportID($$gtPtr{importID}) ;
      }
      if (defined $gtID) {
	$sth = $dbh->prepare( "insert into SampleGenotype 
                               (sampleID, gtID) 
                               values (?, ?)" ) ;
	$sth->execute($id, $gtID) ;
	$sth->finish() ;
      }
    }
  }

  $DEBUG and carp " ->[insertTissueSample] End." ;

  return($id) ;
}

=head2 insertMap

  Function  : Insert (create) a Genetics::Object::Map object to the database.
  Argument  : A Genetics::Object::Map object.
  Returns   : The id of the inserted object.
  Scope     : Public
  Comments  : 

=cut

sub insertMap {
  my($self, $map) = @_ ;
  my($id, $sth, $sortOrder, $omeListPtr, $omePtr, $soPtr, $soID, $omeName, $orgPtr, 
     $genusSpecies, $orgID) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[insertMap] $map." ;

  # Object data
  $id = $self->_insertObjectData($map) ;
  # Map fields
  $sth = $dbh->prepare( "insert into Map 
                         (mapID, chromosome, organismID, orderingMethod, distanceUnits) 
                         values (?, ?, ?, ?, ?)" ) ;
  $sth->execute($id, $map->field("chromosome"), undef, $map->field("orderingMethod"), 
		$map->field("distanceUnits")) ;
  $sth->finish() ;
  # OrderedMapElement fields
  $sortOrder = 1 ;
  $sth = $dbh->prepare( "insert into OrderedMapElement 
                         (omeID, mapID, soID, sortOrder,name, distance, comment) 
                         values (?, ?, ?, ?, ?, ?, ?)" ) ;
  $omeListPtr = $map->field("OrderedMapElements") ;
  foreach $omePtr (@$omeListPtr) {
    $soPtr = $$omePtr{SeqObj} ;
    if ( defined($$soPtr{id}) ) {
      $soID = $$soPtr{id} ;
    } else {
      $soID = $self->_getIDByImportID($$soPtr{importID}) ;
    }
    if (defined $soID) {
      if ( ! defined ($omeName = $$soPtr{name}) ) {
	( $omeName ) = $dbh->selectrow_array( "select name from Object 
                                               where id = $soID" )
      }
      $sth->execute(undef, $id, $soID, $sortOrder, $omeName, $$omePtr{distance}, $$omePtr{comment}) ;
      $sortOrder++ ;
    } else {
      carp " ->[insertMap] Can't find an ID for SequenceObject $$soPtr{name}" ;
      return(undef) ;
    }
  }
  $sth->finish() ;
  # Organism data
  if (defined ($orgPtr = $map->field("Organism")) ) {
    $orgID = $self->_getOrganismID($orgPtr) ;
    $sth = $dbh->prepare( "update Map 
                           set organismID = ? 
                           where mapID = ?" ) ;
    $sth->execute($orgID, $id) ;
    $sth->finish() ;
  }

  $DEBUG and carp " ->[insertMap] End." ;

  return($id) ;
}

=head1 Private methods

=head2 _insertObjectData

  Function  : Insert data common to all Genetics::Object objects to the database.
  Argument  : A GNOM-API object and a Genetics::Object object.
  Returns   : The Object.id of the row inserted into the Object table.
  Scope     : Private
  Called by : The various insertObjectSubClass methods.

=cut

sub _insertObjectData {
  my($self, $obj) = @_ ;
  my($sth, $sth2, $name, $importID, $id, $objType, $date, $comment, $url, $naListPtr, $naPtr, 
     $contactName, $contactID, $newContactID, $contactPtr, $xRefListPtr, $xRefPtr, 
     $kwListPtr, $kwvPtr, $kwtName, $dataType, $descr, $value, $valueFieldName, 
     $kwtID, $newKwtID) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[_insertObjectData] $obj" ;

  $name = $obj->field("name") ;
  # We are saving a new object, so the id is generated by the database.  Insert 
  # the existing id as a Keyword.
  $importID = $obj->field("importID") ;
  $objType = ref $obj ;
  $objType =~ s/.*::// ;
  $date = $obj->field("dateCreated") ;
  $comment = $obj->field("comment") ;
  $url = $obj->field("url") ;
  # Insert Object fields
  $sth = $dbh->prepare( "insert into Object 
                         (name, id, objType, dateCreated, dateModified, 
                          comment, url, contactID) 
                         values (?, ?, ?, ?, ?, ?, ?, ?)" ) ;
  $sth->execute($name, undef, $objType, $date, undef, $comment, $url, undef) ;
  $id = $sth->{'mysql_insertid'} ;
  $sth->finish() ;
  # Insert NameAlias fields
  if ( defined ($naListPtr = $obj->field("NameAliases")) ) {
    $sth = $dbh->prepare( "insert into NameAlias 
                           (objID, name, contactID) 
                           values (?, ?, ?) " ) ;
    $sth2 = $dbh->prepare( "insert into Contact 
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
	  $sth2->execute(undef, $contactName) ;
	  $newContactID = $sth2->{'mysql_insertid'} ;
	  # ...then insert NameAlias referencing the new Contact
	  $sth->execute($id, $$naPtr{name}, $newContactID) ;
	}
      } else {
	# Insert a NameAlias w/o a Contact reference
	$sth->execute($id, $$naPtr{name}, undef) ;
      }
    }
    $sth->finish() ;
    $sth2->finish() ;
  }
  # Insert Contact fields
  if ( defined ($contactPtr = $obj->field("Contact")) ) {
    # Need to check for an Address and insert it if there is one
    $contactName = $$contactPtr{name} ;
    # See if there is already a Contact with the same name
    ( $contactID ) = $dbh->selectrow_array( "select contactID from Contact
                                             where name = '$contactName'" ) ;
    if ( defined ($contactID) ) {
      # If so, just add the contactID to Object
      $sth = $dbh->prepare( "update Object 
                             set contactID = ? 
                             where id = ?" ) ;
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
                             where id = ?"  ) ;
      $sth->execute($newContactID, $id) ;
      $sth->finish() ;
    }
  }
  # Insert DBXReferences fields
  if ( defined ($xRefListPtr = $obj->field("DBXReferences")) ) {
    $sth = $dbh->prepare( "insert into DBXReference 
                           (dbXRefID, objID, accessionNumber, databaseName, 
                            schemaName, comment) 
                           values (?, ?, ?, ?, ?, ?)" ) ;
    foreach $xRefPtr (@$xRefListPtr) {
      $sth->execute(undef, $id, $$xRefPtr{accessionNumber}, $$xRefPtr{databaseName}, $$xRefPtr{schemaName}, $$xRefPtr{comment}) ;
    }
    $sth->finish() ;
  }
  # Insert Keyword and KeywordType fields
  # First insert the ImportID Keyword
  $sth = $dbh->prepare( "insert into Keyword 
                         (keywordID, objID, keywordTypeID, stringValue)
                         values (?, ?, ?, ?) " ) ;
  $sth->execute(undef, $id, 1, $importID) ;
  $sth->finish() ;
  # Insert other Keywords
  if ( defined ($kwListPtr = $obj->field("Keywords")) ) {
    foreach $kwvPtr (@$kwListPtr) {
      $kwtName = $$kwvPtr{name} ;
      $dataType = $$kwvPtr{dataType} ;
      $descr = $$kwvPtr{description} ;
      $value = $$kwvPtr{value} ;
      # Need to do this b/c there is only 1 value but there are 4 possible columns in
      # which to put it:
      $valueFieldName = (lc $dataType) . "Value" ;
      ( $kwtID ) = $dbh->selectrow_array( "select keywordTypeID from KeywordType 
                                           where name = '$kwtName' 
                                           and dataType = '$dataType'" ) ;
      if (defined $kwtID) {
	# Just add the value to Keyword
	$sth = $dbh->prepare( "insert into Keyword 
                               (keywordID, objID, keywordTypeID, $valueFieldName) 
                               values (?, ?, ?, ?)" ) ;
	$sth->execute(undef, $id, $kwtID, $value) ;
	$sth->finish() ;
      } else {
	# Insert new KeywordType...
	$sth = $dbh->prepare( "insert into KeywordType 
                               (keywordTypeID, name, dataType, description) 
                               values (?, ?, ?, ?)" ) ;
	$sth->execute(undef, $kwtName, $dataType, $descr) ;
	$newKwtID = $sth->{'mysql_insertid'} ;
	$sth->finish() ;
	# then add the value to Keyword, referencing the new KeywordType
	$sth = $dbh->prepare( "insert into Keyword 
                               (keywordID, objID, keywordTypeID, $valueFieldName) 
                               values (?, ?, ?, ?)" ) ;
	$sth->execute(undef, $id, $newKwtID, $value) ;
	$sth->finish() ;
      }
    }
  }

  $DEBUG and carp " ->[_insertObjectData] End. ID is $id." ;

  return($id) ;
}

=head2 _insertAssayAttrs

  Function  : Insert AssayAttributes associated with a Genotype, AlleleCall or 
              Phenotype.
  Arguments : Array reference to the list of AssayAttributes, scalar 
              containing the type of object with which the AssayAttributes 
              are associated, and another scalar containing the id of that 
              object.
  Returns   : N/A
  Scope     : Private
  Called by : 
  Comments  : 

=cut

sub _insertAssayAttrs {
  my($self, $aaListPtr, $type, $id) = @_ ;
  my($sth, $aaPtr, $aaName, $dataType, $descr, $value, $aaID, 
     $linkFieldName, $valueFieldName) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[_insertAssayAttrs] Start ($type)." ;

  foreach $aaPtr (@$aaListPtr) {
    $aaName = $$aaPtr{name} ;
    $dataType = $$aaPtr{dataType} ;
    $descr = $$aaPtr{description} ;
    $value = $$aaPtr{value} ;
    
    ( $aaID ) = $dbh->selectrow_array( "select attrID from AssayAttribute 
                                        where name = '$aaName' 
                                        and dataType = '$dataType'" ) ;
    if ( ! defined $aaID) {
      # Insert new AssayAttribute...
      $sth = $dbh->prepare( "insert into AssayAttribute 
                             (attrID, name, dataType, description) 
                             values (?, ?, ?, ?)" ) ;
      $sth->execute(undef, $aaName, $dataType, $descr) ;
      $aaID = $sth->{'mysql_insertid'} ;
      $sth->finish() ;
    }
    # Add the AttributeValue
    # Need to derive $linkFieldName: AttributeValues can be 
    # associated with Gts/Pts or with AlleleCalls
    if ($type eq "AlleleCall") {
      $linkFieldName = "alleleCallID" ;
    } else {
      $linkFieldName = "objID" ;
    }
    # Need to derive $valueFieldName: there is only 1 value,
    # but there are 4 possible columns in which to put it:
    $valueFieldName = (lc $dataType) . "Value" ;
    $sth = $dbh->prepare( "insert into AttributeValue 
                           (attrValueID, $linkFieldName, attrID, $valueFieldName) 
                           values (?, ?, ?, ?)" ) ;
    $sth->execute(undef, $id, $aaID, $value) ;
    $sth->finish() ;
  }
  
  $DEBUG and carp " ->[_insertAssayAttrs] End." ;

  return(1) ;
}

1;

