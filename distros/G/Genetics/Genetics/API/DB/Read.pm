# GenPerl module 
#

# POD documentation - main docs before the code

=head1 NAME

Genetics::API::DB::Read

=head1 SYNOPSIS

  use Genetics::API ;

  $api = new Genetics::API(DSN => {driver => "mysql",
				   host => $Host,
				   database => $Database},
                           user => $UserName,
                           password => $Password) ;

  $id = 123456 ;
  $subject = $api->getSubject($id) ;

=head1 DESCRIPTION

The Genetics::API::DB packages provide an interface for the manipulation of
Genperl objects in a relationa; database.  This package contains the methods
for retrieving objects from a database by id.  To retrieve objects using more
complex criteria, see Genetics::API::DB::Query.

Two versions of get methods are provided for most object types.  One returns
"full" objects containing all the data in the database associated with an
object id; the other returns "mini" objects containing only a subset of the
data associated with an object.  Generally, the getMini methods do not return
any of the general object annotation fields (ie. things like Keywords,
DBXReferences, etc. are not returned with "mini" objects).  In some cases,
certain class-specific data is also left out of "mini" objects.  See the
individual getMini method descriptions for details on this.

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

package Genetics::API::DB::Read ;

BEGIN {
  $ID = "Genetics::API::DB::Read" ;
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

@EXPORT = qw(getCluster getSubject getKindred getMarker getSNP getGenotype 
             getStudyVariable getPhenotype getFrequencySource 
             getHtMarkerCollection getHaplotype getDNASample getTissueSample 
             getMap _getObjAssocData 
	     getMiniCluster getMiniSubject getMiniKindred getMiniMarker 
	     getMiniSNP getMiniGenotype getMiniPhenotype getMiniStudyVariable
             getMiniMap getMiniMarkerByName getMiniFrequencySource ) ;
@EXPORT_OK = qw();

=head1 Public Methods

=head2 getCluster

  Function  : Get (read) a Genetics::Object::Cluster object from the database.
  Argument  : The Object ID of the Cluster to be returned.
  Returns   : A Genetics::Object::Cluster object.
  Scope     : Public

=cut

sub getCluster {
  my($self, $id) = @_ ;
  my($cluster, %param, $sth, $arrRef, $clusterType, $objName, $contentsListPtr) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[getCluster] $id" ;

  $self->_getObjAssocData($id, \%param) ;

  ( $clusterType ) = $dbh->selectrow_array("select clusterType 
                                            from Cluster 
                                            where clusterID = $id") ;
  defined $clusterType or return(undef) ;
  $param{clusterType} = $clusterType ;
  # Contents
  $sth = $dbh->prepare("select objID from ClusterContents 
                        where clusterID = $id") ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    ( $objName ) = $dbh->selectrow_array("select name from Object 
                                           where id = $$arrRef[0]") ;
    push(@$contentsListPtr, {name => $objName, id => $$arrRef[0]}) ;
  }
  $param{Contents} = $contentsListPtr ;
  
  $cluster = new Genetics::Cluster(%param) ;
    
  $DEBUG and carp " ->[getCluster] $cluster" ;

  return($cluster) ;
}

=head2 getMiniCluster

  Function  : Get a "light" version of a Genetics::Object::Cluster object 
              from the database.
  Argument  : The Object ID of the Cluster to be returned.
  Returns   : A Genetics::Object::Cluster object.
  Scope     : Public
  Comments  : "Light" version means that the object has only the name and id 
              fields from Object, and it does not contain any associated NameAlias, 
              Contact, DBXReference or Keyword data.

=cut

sub getMiniCluster {
  my($self, $id) = @_ ;
  my($cluster, $sth, $arrRef, %param, $objName, $contentsListPtr) ;
  my $dbh = $self->{dbh} ;

  $DEBUG and carp " ->[getMiniCluster] $id" ;

  $sth = $dbh->prepare("select name, id, dateCreated, dateModified, comment, clusterType 
                        from Object, Cluster 
                        where id = $id 
                        and id = clusterID") ;
  $sth->execute() ;
  $arrRef = $sth->fetchrow_arrayref() ;
  $sth->finish() ;
  defined $arrRef or return(undef) ;

  $param{name} = $$arrRef[0] ;
  $param{id} = $$arrRef[1] ;
  $param{dateCreated} = $$arrRef[2] ;
  $param{dateModified} = $$arrRef[3] ;
  $param{comment} = $$arrRef[4] ;
  $param{clusterType} = $$arrRef[5] ;
  # Contents
  $sth = $dbh->prepare("select objID from ClusterContents 
                        where clusterID = $id") ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    ( $objName ) = $dbh->selectrow_array("select name from Object 
                                          where id = $$arrRef[0]") ;
    push(@$contentsListPtr, {name => $objName, id => $$arrRef[0]}) ;
  }
  $param{Contents} = $contentsListPtr ;
  
  $cluster = new Genetics::Cluster(%param) ;
    
  $DEBUG and carp " ->[getMiniCluster] $cluster" ;

  return($cluster) ;
}

=head2 getSubject

  Function  : Get (read) a Genetics::Object::Subject object from the database.
  Argument  : The Object ID of the Subject to be returned.
  Returns   : A Genetics::Object::Subject object.
  Scope     : Public

=cut

sub getSubject {
  my($self, $id) = @_ ;
  my($subject, $sth, $arrRef, %param, $kindredID, $kindredName, $motherID, 
     $motherName, $fatherID, $fatherName, $orgID, %init) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[getSubject] Start" ;

  $sth = $dbh->prepare("select organismID, kindredID, motherID, fatherID, 
                               gender, dateOfBirth, dateOfDeath, isProband 
                        from Subject 
                        where subjectID = $id") ;
  $sth->execute() ;
  $arrRef = $sth->fetchrow_arrayref() ;
  defined $arrRef or return(undef) ;
  $sth->finish() ;

  $self->_getObjAssocData($id, \%param) ;

  $param{gender} = $$arrRef[4] ;
  defined $$arrRef[5] and $param{dateOfBirth} = $$arrRef[5] ;
  defined $$arrRef[6] and $param{dateOfDeath} = $$arrRef[6] ;
  $param{isProband} = $$arrRef[7] ;
  if ( defined ($kindredID = $$arrRef[1]) ) {
    ( $kindredName) = $dbh->selectrow_array("select name from Object
                                             where id = $kindredID") ;
    $param{Kindred} = { name => $kindredName, 
			id => $kindredID } ;
  }
  if ( defined ($motherID = $$arrRef[2]) ) {
    ( $motherName) = $dbh->selectrow_array("select name from Object
                                             where id = $motherID") ;
    $param{Mother} = { name => $motherName, 
		       id => $motherID } ;
  }
  if ( defined ($fatherID = $$arrRef[3]) ) {
    ( $fatherName) = $dbh->selectrow_array("select name from Object
                                             where id = $fatherID") ;
    $param{Father} = { name => $fatherName, 
		       id => $fatherID } ;
  }
  if ( defined ($orgID = $$arrRef[0]) ) {
    $sth = $dbh->prepare("select genusSpecies, subspecies, strain 
                          from Organism 
                          where organismID = $orgID") ;
    $sth->execute() ;
    $arrRef = $sth->fetchrow_arrayref() ;
    $init{genusSpecies} = $$arrRef[0] ;
    defined $$arrRef[1] and $init{subspecies} = $$arrRef[1] ;
    defined $$arrRef[2] and $init{strain} = $$arrRef[2] ;
    $param{Organism} = { %init } ;
    $sth->finish() ;
  }

  $subject = new Genetics::Subject(%param) ;
  
  $DEBUG and carp " ->[getSubject] $subject" ;

  return($subject) ;
}

=head2 getMiniSubject

  Function  : Get a "light" version of a Genetics::Object::Subject object from 
              the database, by id.
  Argument  : The Object ID of the Subject to be returned.
  Returns   : A Genetics::Object::Subject object.
  Scope     : Public
  Comments  : "Light" version means that the object has only the name and id 
              fields from Object, and it does not contain any associated NameAlias, 
              Contact, DBXReference or Keyword data.  It also has a sub-set of 
              Subject-specific fields.

=cut

sub getMiniSubject {
  my($self, $id) = @_ ;
  my($subject, $sth, $arrRef, %param, $kindredID, $kindredName, $motherID, 
     $motherName, $fatherID, $fatherName, $orgID, %init) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[getMiniSubject] $id" ;

  $sth = $dbh->prepare("select name, id, dateCreated, dateModified, comment, 
                               kindredID, motherID, fatherID, gender, isProband 
                        from Object, Subject 
                        where id = subjectID 
                        and subjectID = $id") ;
  $sth->execute() ;
  $arrRef = $sth->fetchrow_arrayref() ;
  $sth->finish() ;
  defined $arrRef or return(undef) ;

  $param{name} = $$arrRef[0] ;
  $param{id} = $$arrRef[1] ;
  $param{dateCreated} = $$arrRef[2] ;
  $param{dateModified} = $$arrRef[3] ;
  $param{comment} = $$arrRef[4] ;
  $param{gender} = $$arrRef[8] ;
  $param{isProband} = $$arrRef[9] ;
  if ( defined ($kindredID = $$arrRef[5]) ) {
    ( $kindredName) = $dbh->selectrow_array("select name from Object
                                             where id = $kindredID") ;
    $param{Kindred} = { name => $kindredName, 
			id => $kindredID } ;
  }
  if ( defined ($motherID = $$arrRef[6]) ) {
    ( $motherName) = $dbh->selectrow_array("select name from Object
                                             where id = $motherID") ;
    $param{Mother} = { name => $motherName, 
		       id => $motherID } ;
  }
  if ( defined ($fatherID = $$arrRef[7]) ) {
    ( $fatherName) = $dbh->selectrow_array("select name from Object
                                             where id = $fatherID") ;
    $param{Father} = { name => $fatherName, 
		       id => $fatherID } ;
  }

  $subject = new Genetics::Subject(%param) ;
  
  $DEBUG and carp " ->[getMiniSubject] $subject" ;

  return($subject) ;
}

=head2 getKindred

  Function  : Get (read) a Genetics::Object::Kindred object from the database.
  Argument  : The Object ID of the Kindred to be returned.
  Returns   : A Genetics::Object::Kindred object.
  Scope     : Public

=cut

sub getKindred {
  my($self, $id) = @_ ;
  my($kindred, %param, $sth, $arrRef, $parentID, $parentName, $subjName, $subjListPtr) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[getKindred] $id" ;

  $sth = $dbh->prepare("select isDerived, parentID
                        from Kindred 
                        where kindredID = $id") ;
  $sth->execute() ;
  $arrRef = $sth->fetchrow_arrayref() ;
  $sth->finish() ;
  defined $arrRef or return(undef) ;
  
  $self->_getObjAssocData($id, \%param) ;

  $param{isDerived} = $$arrRef[0] ;
  if ( defined($parentID = $$arrRef[1]) ) {
    ( $parentName) = $dbh->selectrow_array("select name from Object
                                            where id = $parentID") ;
    $param{DerivedFrom} = { name => $parentName, 
			    id => $parentID } ;
  }

  $sth = $dbh->prepare("select subjectID from KindredSubject 
                        where kindredID = $id") ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    ( $subjName) = $dbh->selectrow_array("select name from Object
                                          where id = $$arrRef[0]") ;
    push( @$subjListPtr, {name => $subjName, id => $$arrRef[0]} ) ;
  }
  defined $subjListPtr and $param{Subjects} = $subjListPtr ;

  $kindred = new Genetics::Kindred(%param) ;
  
  $DEBUG and carp " ->[getKindred] $kindred" ;

  return($kindred) ;
}

=head2 getMiniKindred

  Function  : Get a "light" version of a Genetics::Object::Kindred object from 
              the database.
  Argument  : The Object ID of the Kindred to be returned.
  Returns   : A Genetics::Object::Kindred object.
  Scope     : Public
  Comments  : "Light" version means that the object has only the name and id 
              fields from Object, and it does not contain any associated NameAlias, 
              Contact, DBXReference or Keyword data.

=cut

sub getMiniKindred {
  my($self, $id) = @_ ;
  my($kindred, %param, $sth, $arrRef, $parentID, $parentName, $subjName, $subjListPtr) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[getMiniKindred] $id" ;

  $sth = $dbh->prepare("select name, id, dateCreated, dateModified, comment, 
                               isDerived, parentID
                        from Object, Kindred 
                        where id = kindredID 
                        and kindredID = $id") ;
  $sth->execute() ;
  $arrRef = $sth->fetchrow_arrayref() ;
  $sth->finish() ;
  defined $arrRef or return(undef) ;
  
  $param{name} = $$arrRef[0] ;
  $param{id} = $$arrRef[1] ;
  $param{dateCreated} = $$arrRef[2] ;
  $param{dateModified} = $$arrRef[3] ;
  $param{comment} = $$arrRef[4] ;
  $param{isDerived} = $$arrRef[5] ;
  if ( defined($parentID = $$arrRef[6]) ) {
    ( $parentName) = $dbh->selectrow_array("select name from Object
                                            where id = $parentID") ;
    $param{DerivedFrom} = { name => $parentName, 
			    id => $parentID } ;
  }

  $sth = $dbh->prepare("select subjectID from KindredSubject 
                        where kindredID = $id") ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    ( $subjName) = $dbh->selectrow_array("select name from Object
                                          where id = $$arrRef[0]") ;
    push( @$subjListPtr, {name => $subjName, id => $$arrRef[0]} ) ;
  }
  defined $subjListPtr and $param{Subjects} = $subjListPtr ;

  $kindred = new Genetics::Kindred(%param) ;
  
  $DEBUG and carp " ->[getMiniKindred] $kindred" ;

  return($kindred) ;
}

=head2 getMarker

  Function  : Get (read) a Genetics::Object::Marker object from the database.
  Argument  : The Object ID of the Marker to be returned.
  Returns   : A Genetics::Object::Marker object.
  Scope     : Public

=cut

sub getMarker {
  my($self, $id) = @_ ;
  my($marker, %param, $sth, $sth2, $arrRef, $arrRef1, $arrRef2, %init, $orgID, 
     $alleleListPtr, $iscnListPtr, $seqID, $seq, $len, $units) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[getMarker] $id" ;

  $self->_getObjAssocData($id, \%param) ;

  # SequenceObject and Marker data
  $sth = $dbh->prepare("select chromosome, organismID, sequenceID, malePloidy, 
                               femalePloidy, polymorphismType, polymorphismIndex1, 
                               polymorphismIndex2, repeatSequence 
                        from SequenceObject, Marker 
                        where markerID = $id 
                        and markerID = seqObjectID") ;
  $sth->execute() ;
  $arrRef = $sth->fetchrow_arrayref() ;
  defined $$arrRef[0] and $param{chromosome} = $$arrRef[0] ;
  defined $$arrRef[3] and $param{malePloidy} = $$arrRef[3] ;
  defined $$arrRef[4] and $param{femalePloidy} = $$arrRef[4] ;
  defined $$arrRef[5] and $param{polymorphismType} = $$arrRef[5] ;
  defined $$arrRef[6] and $param{polymorphismIndex1} = $$arrRef[6] ;
  defined $$arrRef[7] and $param{polymorphismIndex2} = $$arrRef[7] ;
  defined $$arrRef[8] and $param{repeatSequence} = $$arrRef[8] ;
  $sth->finish() ;
  # Organism data
  if ( defined ($orgID = $$arrRef[1]) ) {
    $sth = $dbh->prepare("select genusSpecies, subspecies, strain 
                          from Organism 
                          where organismID = $orgID") ;
    $sth->execute() ;
    $arrRef1 = $sth->fetchrow_arrayref() ;
    $init{genusSpecies} = $$arrRef1[0] ;
    defined $$arrRef1[1] and $init{subspecies} = $$arrRef1[1] ;
    defined $$arrRef1[2] and $init{strain} = $$arrRef1[2] ;
    $param{Organism} = { %init } ;
    $sth->finish() ;
  }
  # Allele data
  $sth = $dbh->prepare("select name, type 
                        from Allele 
                        where poID = $id") ;
  $sth->execute() ;
  while ($arrRef1 = $sth->fetchrow_arrayref()) {
    push( @$alleleListPtr, {name => $$arrRef1[0], type => $$arrRef1[1]} ) ;
  }
  defined $alleleListPtr and $param{Alleles} = $alleleListPtr ;
  # ISCNMapLocation data
  $sth = $dbh->prepare("select iscnMapLocID 
                        from SeqObjISCN 
                        where seqObjectID = $id") ;
  $sth->execute() ;
  while ($arrRef1 = $sth->fetchrow_arrayref()) {
    $sth2 = $dbh->prepare("select chrNumber, chrArm, band, bandingMethod 
                           from ISCNMapLocation 
                           where iscnMapLocID = $$arrRef1[0]") ;
    $sth2->execute() ;
    while ($arrRef2 = $sth2->fetchrow_arrayref()) {
      %init = () ;
      $init{chrNumber} = $$arrRef2[0] ;
      defined $$arrRef2[1] and $init{chrArm} = $$arrRef2[1] ;
      defined $$arrRef2[2] and $init{band} = $$arrRef2[2] ;
      defined $$arrRef2[3] and $init{bandingMethod} = $$arrRef2[3] ;
      push( @$iscnListPtr, { %init } ) ;
    }
  }
  defined $iscnListPtr and $param{ISCNMapLocations} = $iscnListPtr ;
  # Sequence data
  if ( defined($seqID = $$arrRef[2]) ) {
    ( $seq, $len, $units ) = $dbh->selectrow_array("select sequence, length, lengthUnits 
                                                    from Sequence 
                                                    where sequenceID = $seqID") ;
    if (defined $seq) {
      %init = () ;
      $init{sequence} = $seq ;
      defined $len and $init{length} = $len ;
      defined $units and $init{lengthUnits} = $units ;
      $param{Sequence} = { %init } ;
    }
  }

  $marker = new Genetics::Marker(%param) ;
  
  $DEBUG and carp " ->[getMarker] $marker" ;
  return($marker) ;
}

=head2 getMiniMarker

  Function  : Get a "light" version of a Genetics::Object::Marker object from the 
              database.
  Argument  : The Object ID of the Marker to be returned.
  Returns   : A Genetics::Object::Marker object.
  Scope     : Public
  Comments  : "Light" version means that the object has only the name and id 
              fields from Object, and it does not contain any associated NameAlias, 
              Contact, DBXReference or Keyword data.  It also has a sub-set of 
              Marker-specific fields.

=cut

sub getMiniMarker {
  my($self, $id) = @_ ;
  my($marker, %param, $sth, $arrRef, $alleleListPtr) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[getMiniMarker] $id" ;

  $sth = $dbh->prepare("select name, id, dateCreated, dateModified, comment, 
                               chromosome, malePloidy, femalePloidy, 
                               polymorphismType, repeatSequence 
                        from Object, SequenceObject, Marker 
                        where id = $id 
                        and id = markerID 
                        and markerID = seqObjectID") ;
  $sth->execute() ;
  $arrRef = $sth->fetchrow_arrayref() ;
  $sth->finish() ;
  defined $arrRef or return(undef) ;

  $param{name} = $$arrRef[0] ;
  $param{id} = $$arrRef[1] ;
  $param{dateCreated} = $$arrRef[2] ;
  $param{dateModified} = $$arrRef[3] ;
  $param{comment} = $$arrRef[4] ;
  defined $$arrRef[5] and $param{chromosome} = $$arrRef[5] ;
  defined $$arrRef[6] and $param{malePloidy} = $$arrRef[6] ;
  defined $$arrRef[7] and $param{femalePloidy} = $$arrRef[7] ;
  defined $$arrRef[8]  and $param{polymorphismType} = $$arrRef[8] ;
  defined $$arrRef[9] and $param{repeatSequence} = $$arrRef[9] ;
  # Allele data
  $sth = $dbh->prepare("select name, type 
                        from Allele 
                        where poID = $param{id}") ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    push @$alleleListPtr, {name => $$arrRef[0], type => $$arrRef[1]} ;
  }
  defined($alleleListPtr) and $param{Alleles} = $alleleListPtr ;

  $marker = new Genetics::Marker(%param) ;
  
  $DEBUG and carp " ->[getMiniMarker] $marker" ;

  return($marker) ;
}

=head2 getMiniMarkerByName

  Function  : Get a "light" version of a Genetics::Object::Marker object from the 
              database, by name.
  Argument  : The name of the Marker to be returned.
  Returns   : A Genetics::Object::Marker object.
  Scope     : Public
  Comments  : If there is more than one Marker object with the same name, this
              will only return ONE of them.  Which one?  Good question.  Caveat 
              Programmor!
              "Light" version means that the object has only the name and id 
              fields from Object, and it does not contain any associated NameAlias, 
              Contact, DBXReference or Keyword data.

=cut

sub getMiniMarkerByName {
  my($self, $name) = @_ ;
  my($marker, %param, $sth, $arrRef, $alleleListPtr) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[getMiniMarkerByName] $name" ;

  $sth = $dbh->prepare("select name, id, dateCreated, dateModified, comment, 
                               chromosome, malePloidy, femalePloidy, 
                               polymorphismType, repeatSequence 
                        from Object, SequenceObject, Marker 
                        where name = '$name' 
                        and id = markerID 
                        and markerID = seqObjectID") ;
  $sth->execute() ;
  $arrRef = $sth->fetchrow_arrayref() ;
  $sth->finish() ;
  defined $arrRef or return(undef) ;

  $param{name} = $$arrRef[0] ;
  $param{id} = $$arrRef[1] ;
  $param{dateCreated} = $$arrRef[2] ;
  $param{dateModified} = $$arrRef[3] ;
  $param{comment} = $$arrRef[4] ;
  defined $$arrRef[5] and $param{chromosome} = $$arrRef[5] ;
  defined $$arrRef[6] and $param{malePloidy} = $$arrRef[6] ;
  defined $$arrRef[7] and $param{femalePloidy} = $$arrRef[7] ;
  defined $$arrRef[8]  and $param{polymorphismType} = $$arrRef[8] ;
  defined $$arrRef[9] and $param{repeatSequence} = $$arrRef[9] ;
  # Allele data
  $sth = $dbh->prepare("select name, type 
                        from Allele 
                        where poID = $param{id}") ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    push @$alleleListPtr, {name => $$arrRef[0], type => $$arrRef[1]} ;
  }
  defined($alleleListPtr) and $param{Alleles} = $alleleListPtr ;

  $marker = new Genetics::Marker(%param) ;
  
  $DEBUG and carp " ->[getMiniMarkerByName] $marker" ;

  return($marker) ;
}

=head2 getSNP

  Function  : Get (read) a Genetics::Object::SNP object from the database.
  Argument  : The Object ID of the SNP to be returned.
  Returns   : A Genetics::Object::SNP object.
  Scope     : Public

=cut

sub getSNP {
  my($self, $id) = @_ ;
  my($snp, %param, $sth, $sth2, $arrRef, $arrRef1, $arrRef2, %init, $orgID, 
     $alleleListPtr, $iscnListPtr, $seqID, $seq, $len, $units) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[getSNP] $id" ;

  $self->_getObjAssocData($id, \%param) ;

  # SequenceObject and SNP data
  $sth = $dbh->prepare("select chromosome, organismID, sequenceID, malePloidy, 
                               femalePloidy, snpType, functionClass, 
                               snpIndex, isConfirmed, confirmMethod
                        from SequenceObject, SNP 
                        where snpID = $id 
                        and snpID = seqObjectID") ;
  $sth->execute() ;
  $arrRef = $sth->fetchrow_arrayref() ;
  defined $$arrRef[0] and $param{chromosome} = $$arrRef[0] ;
  defined $$arrRef[3] and $param{malePloidy} = $$arrRef[3] ;
  defined $$arrRef[4] and $param{femalePloidy} = $$arrRef[4] ;
  defined $$arrRef[5] and $param{snpType} = $$arrRef[5] ;
  defined $$arrRef[6] and $param{functionClass} = $$arrRef[6] ;
  defined $$arrRef[7] and $param{snpIndex} = $$arrRef[7] ;
  defined $$arrRef[8] and $param{isConfirmed} = $$arrRef[8] ;
  defined $$arrRef[9] and $param{confirmMethod} = $$arrRef[9] ;
  $sth->finish() ;
  # Organism data
  if ( defined ($orgID = $$arrRef[1]) ) {
    $sth = $dbh->prepare("select genusSpecies, subspecies, strain 
                          from Organism 
                          where organismID = $orgID") ;
    $sth->execute() ;
    $arrRef1 = $sth->fetchrow_arrayref() ;
    $init{genusSpecies} = $$arrRef1[0] ;
    defined $$arrRef1[1] and $init{subspecies} = $$arrRef1[1] ;
    defined $$arrRef1[2] and $init{strain} = $$arrRef1[2] ;
    $param{Organism} = { %init } ;
    $sth->finish() ;
  }
  # Allele data
  $sth = $dbh->prepare("select name, type 
                        from Allele 
                        where poID = $id") ;
  $sth->execute() ;
  while ($arrRef1 = $sth->fetchrow_arrayref()) {
    push( @$alleleListPtr, {name => $$arrRef1[0], type => $$arrRef1[1]} ) ;
  }
  defined $alleleListPtr and $param{Alleles} = $alleleListPtr ;
  # ISCNMapLocation data
  $sth = $dbh->prepare("select iscnMapLocID 
                        from SeqObjISCN 
                        where seqObjectID = $id") ;
  $sth->execute() ;
  while ($arrRef1 = $sth->fetchrow_arrayref()) {
    $sth2 = $dbh->prepare("select chrNumber, chrArm, band, bandingMethod 
                           from ISCNMapLocation 
                           where iscnMapLocID = $$arrRef1[0]") ;
    $sth2->execute() ;
    while ($arrRef2 = $sth2->fetchrow_arrayref()) {
      %init = () ;
      $init{chrNumber} = $$arrRef2[0] ;
      defined $$arrRef2[1] and $init{chrArm} = $$arrRef2[1] ;
      defined $$arrRef2[2] and $init{band} = $$arrRef2[2] ;
      defined $$arrRef2[3] and $init{bandingMethod} = $$arrRef2[3] ;
      push( @$iscnListPtr, { %init } ) ;
    }
  }
  defined $iscnListPtr and $param{ISCNMapLocations} = $iscnListPtr ;
  # Sequence data
  if ( defined($seqID = $$arrRef[2]) ) {
    ( $seq, $len, $units ) = $dbh->selectrow_array("select sequence, length, lengthUnits 
                                                    from Sequence 
                                                    where sequenceID = $seqID") ;
    if (defined $seq) {
      %init = () ;
      $init{sequence} = $seq ;
      defined $len and $init{length} = $len ;
      defined $units and $init{lengthUnits} = $units ;
      $param{Sequence} = { %init } ;
    }
  }

  $snp = new Genetics::SNP(%param) ;
  
  $DEBUG and carp " ->[getSNP] $snp" ;
  return($snp) ;
}

=head2 getMiniSNP

  Function  : Get a "light" version of a Genetics::Object::SNP object from the 
              database.
  Argument  : The Object ID of the SNP to be returned.
  Returns   : A Genetics::Object::SNP object.
  Scope     : Public
  Comments  : "Light" version means that the object has only the name and id 
              fields from Object, and it does not contain any associated NameAlias, 
              Contact, DBXReference or Keyword data.  It also has a sub-set of 
              SNP-specific fields.

=cut

sub getMiniSNP {
  my($self, $id) = @_ ;
  my($snp, %param, $sth, $arrRef, $alleleListPtr) ;
  my $dbh = $self->{dbh} ;
  
  $DEBUG and carp " ->[getMiniSNP] $id" ;
  
  # SequenceObject and SNP data
  $sth = $dbh->prepare("select name, id, dateCreated, dateModified, comment, 
                               chromosome, malePloidy, femalePloidy, snpType, 
                               functionClass, isConfirmed, confirmMethod
                        from Object, SequenceObject, SNP 
                        where id = $id 
                        and id = snpID 
                        and snpID = seqObjectID") ;
  $sth->execute() ;
  $arrRef = $sth->fetchrow_arrayref() ;
  $sth->finish() ;
  defined $arrRef or return(undef) ;

  $param{name} = $$arrRef[0] ;
  $param{id} = $$arrRef[1] ;
  $param{dateCreated} = $$arrRef[2] ;
  $param{dateModified} = $$arrRef[3] ;
  $param{comment} = $$arrRef[4] ;
  defined $$arrRef[5] and $param{chromosome} = $$arrRef[5] ;
  defined $$arrRef[6] and $param{malePloidy} = $$arrRef[6] ;
  defined $$arrRef[7] and $param{femalePloidy} = $$arrRef[7] ;
  defined $$arrRef[8] and $param{snpType} = $$arrRef[8] ;
  defined $$arrRef[9] and $param{functionClass} = $$arrRef[9] ;
  defined $$arrRef[10] and $param{isConfirmed} = $$arrRef[10] ;
  defined $$arrRef[11] and $param{confirmMethod} = $$arrRef[11] ;
  # Allele data
  $sth = $dbh->prepare("select name, type 
                        from Allele 
                        where poID = $id") ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    push( @$alleleListPtr, {name => $$arrRef[0], type => $$arrRef[1]} ) ;
  }
  defined $alleleListPtr and $param{Alleles} = $alleleListPtr ;
  
  $snp = new Genetics::SNP(%param) ;
  
  $DEBUG and carp " ->[getMiniSNP] $snp" ;

  return($snp) ;
}

=head2 getGenotype

  Function  : Get (read) a Genetics::Object::Genotype object from the database.
  Argument  : The Object ID of the Genotype to be returned.
  Returns   : A Genetics::Object::Genotype object.
  Scope     : Public

=cut

sub getGenotype {
  my($self, $id) = @_ ;
  my($gt, %param, $sth, $arrRef, $sth1, $arrRef1, $subjName, $poName, 
     %acInit, $alleleName, $type, @acList, @aaList, $aaName, $dataType, $value) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[getGenotype] $id" ;

  $self->_getObjAssocData($id, \%param) ;

  # Genotype data
  $sth = $dbh->prepare("select subjectID, poID, isActive, icResult, dateCollected 
                        from Genotype 
                        where gtID = $id") ;
  $sth->execute() ;
  $arrRef = $sth->fetchrow_arrayref() ;
  ( $subjName ) = $dbh->selectrow_array("select name from Object 
                                         where id = $$arrRef[0]") ;
  $param{Subject} = {name => $subjName, id => $$arrRef[0]} ;
  ( $poName ) = $dbh->selectrow_array("select name from Object 
                                       where id = $$arrRef[1]") ;
  $param{Marker} = {name => $poName, id => $$arrRef[1]} ;
  $param{isActive} = $$arrRef[2] ;
  defined $$arrRef[3] and $param{icResult} = $$arrRef[3] ;
  defined $$arrRef[4] and $param{dateCollected} = $$arrRef[4] ;
  $sth->finish() ;
  # Genotype AssayAttrs
  $sth = $dbh->prepare("select objID, attrID, stringValue, numberValue, 
                               dateValue, booleanValue
                        from AttributeValue 
                        where objID = $id") ;
  $sth->execute() ;
  @aaList = () ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    ($aaName, $dataType) = $dbh->selectrow_array("select name, dataType 
                                                  from AssayAttribute 
                                                  where attrID = $$arrRef[1]") ;
    $value = $$arrRef[2] || $$arrRef[3] || $$arrRef[4] || $$arrRef[5] ;
    push(@aaList, {name => $aaName,
		   dataType => $dataType,
		   value => $value }) ;
  }
  defined $aaList[0] and $param{AssayAttrs} = [ @aaList ] ;
  
  # AlleleCall data
  $sth = $dbh->prepare("select alleleCallID, alleleID, sortOrder, phase 
                        from AlleleCall 
                        where gtID = $id 
                        order by sortOrder") ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    %acInit = () ;
    ($alleleName, $type) = $dbh->selectrow_array("select name, type 
                                                  from Allele 
                                                  where alleleID = $$arrRef[1]") ;
    %acInit = (alleleName => $alleleName, 
	       alleleType => $type, 
	       phase => $$arrRef[3]) ;
    # AlleleCall AssayAttrs
    $sth1 = $dbh->prepare("select alleleCallID, attrID, stringValue, numberValue, 
                                  dateValue, booleanValue
                           from AttributeValue 
                           where alleleCallID = $$arrRef[0]") ;
    $sth1->execute() ;
    @aaList = () ;
    while ($arrRef1 = $sth1->fetchrow_arrayref()) {
      ($aaName, $dataType) = $dbh->selectrow_array("select name, dataType 
                                                    from AssayAttribute 
                                                    where attrID = $$arrRef1[1]") ;
      $value = $$arrRef1[2] || $$arrRef1[3] || $$arrRef1[4] || $$arrRef1[5] ;   
      push(@aaList, {name => $aaName,
		     dataType => $dataType,
		     value => $value }) ;
    }
    defined $aaList[0] and $acInit{AssayAttrs} = [ @aaList ] ;
    push( @acList, { %acInit } ) ;
  }
  $param{AlleleCalls} = \@acList ;

  $gt = new Genetics::Genotype(%param) ;
  
  $DEBUG and carp " ->[getGenotype] $gt" ;

  return($gt) ;
}

=head2 getMiniGenotype

  Function  : Get a "light" version of a Genetics::Object::Genotype object from 
              the database.
  Argument  : The Object ID of the Genotype to be returned.
  Returns   : A Genetics::Object::Genotype object.
  Scope     : Public
  Comments  : "Light" version means that the object has only the name and id 
              fields from Object, and it does not contain any associated NameAlias, 
              Contact, DBXReference or Keyword data.  It also has a sub-set of 
              Genotype-specific fields.

=cut

sub getMiniGenotype {
  my($self, $id) = @_ ;
  my($gt, %param, $sth, $arrRef, $subjName, $poName, $alleleName, $type, 
     %acInit, @acList) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[getMiniGenotype] $id" ;

  # Genotype data
  $sth = $dbh->prepare("select name, id, dateCreated, dateModified, comment, 
                               subjectID, poID, isActive, icResult 
                        from Object, Genotype 
                        where id = $id 
                        and id = gtID") ;
  $sth->execute() ;
  $arrRef = $sth->fetchrow_arrayref() ;
  $sth->finish() ;
  defined $arrRef or return(undef) ;

  $param{name} = $$arrRef[0] ;
  $param{id} = $$arrRef[1] ;
  $param{dateCreated} = $$arrRef[2] ;
  $param{dateModified} = $$arrRef[3] ;
  $param{comment} = $$arrRef[4] ;
  ( $subjName ) = $dbh->selectrow_array("select name from Object 
                                         where id = $$arrRef[5]") ;
  $param{Subject} = {name => $subjName, id => $$arrRef[5]} ;
  ( $poName ) = $dbh->selectrow_array("select name from Object 
                                       where id = $$arrRef[6]") ;
  $param{Marker} = {name => $poName, id => $$arrRef[6]} ;
  $param{isActive} = $$arrRef[7] ;
  defined $$arrRef[8] and $param{icResult} = $$arrRef[8] ;
  # AlleleCall data
  $sth = $dbh->prepare("select alleleCallID, alleleID, sortOrder, phase 
                        from AlleleCall 
                        where gtID = $id 
                        order by sortOrder") ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    %acInit = () ;
    ($alleleName, $type) = $dbh->selectrow_array("select name, type 
                                                  from Allele 
                                                  where alleleID = $$arrRef[1]") ;
    %acInit = (alleleName => $alleleName, 
	       alleleType => $type, 
	       phase => $$arrRef[3]) ;
    push( @acList, { %acInit } ) ;
  }
  $param{AlleleCalls} = \@acList ;

  $gt = new Genetics::Genotype(%param) ;
  
  $DEBUG and carp " ->[getMiniGenotype] $gt" ;

  return($gt) ;
}

=head2 getStudyVariable

  Function  : Get (read) a Genetics::Object::StudyVariable object from the database.
  Argument  : The Object ID of the StudyVariable to be returned.
  Returns   : A Genetics::Object::StudyVariable object.
  Scope     : Public

=cut

sub getStudyVariable {
  my($self, $id) = @_ ;
  my($sv, %param, $sth, $sth1, $arrRef, $arrRef1, %init, %init1, $category, 
     $format, @codesList, @aseList, @lcList, $p11, $p12, $p22, $mp1, $mp2) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[getStudyVariable] $id" ;

  $self->_getObjAssocData($id, \%param) ;

  # StudyVariable data
  $sth = $dbh->prepare("select category, format, isXLinked, description, 
                               numberLowerBound, numberUpperBound, 
                               dateLowerBound, dateUpperBound 
                        from StudyVariable 
                        where studyVariableID = $id") ;
  $sth->execute() ;
  $arrRef = $sth->fetchrow_arrayref() ;
  $category = $param{category} = $$arrRef[0] ;
  $format = $param{format} = $$arrRef[1] ;
  $param{isXLinked} = $$arrRef[2] ;
  defined $$arrRef[3] and $param{description} = $$arrRef[3] ;
  defined $$arrRef[4] and $param{lowerBound} = $$arrRef[4] ;
  defined $$arrRef[5] and $param{upperBound} = $$arrRef[5] ;
  defined $$arrRef[6] and $param{lowerBound} = $$arrRef[6] ;
  defined $$arrRef[7] and $param{upperBound} = $$arrRef[7] ;
  $sth->finish() ;
  # CodeDerivation data
  if ($format eq "Code") {
    if ($category eq "StaticLiabilityClass") {
      $sth = $dbh->prepare("select codeDerivationID, code, description, formula 
                          from CodeDerivation 
                          where studyVariableID = $id") ;
      $sth->execute() ;
      $sth1 = $dbh->prepare("select pen11, pen12, pen22, malePen1, malePen2 
                             from StaticLCPenetrance 
                             where cdID = ?") ;
      while ($arrRef = $sth->fetchrow_arrayref()) {
	%init = () ;
	$sth1->execute($$arrRef[0]) ;
	($p11, $p12, $p22, $mp1, $mp2) = $sth1->fetchrow_array() ;
	$init{code} = $$arrRef[1] ;
	$init{pen11} = $p11 ;
	$init{pen12} = $p12 ;
	$init{pen22} = $p22 ;
	defined $mp1 and $init{malePen1} = $mp1 ;
	defined $mp2 and $init{malePen2} = $mp2 ;
	defined $$arrRef[2] and $init{description} = $$arrRef[2] ;
	defined $$arrRef[3] and $init{formula} = $$arrRef[3] ;
	push(@codesList, { %init }) ;
      }
    } else {
      $sth = $dbh->prepare("select code, description, formula 
                            from CodeDerivation 
                            where studyVariableID = $id") ;
      $sth->execute() ;
      while ($arrRef = $sth->fetchrow_arrayref()) {
	%init = () ;
	$init{code} = $$arrRef[0] ;
	defined $$arrRef[1] and $init{description} = $$arrRef[1] ;
	defined $$arrRef[2] and $init{formula} = $$arrRef[2] ;
	push(@codesList, { %init }) ;
      }
    }
  }
  defined $codesList[0] and $param{Codes} = \@codesList ;
  
  if ($category =~ /AffectionStatus$/) {
    # AffectionStatus data
    $sth = $dbh->prepare("select name, diseaseAlleleFreq, pen11, pen12, 
                                 pen22, malePen1, malePen2, asDefID 
                          from AffectionStatusDefinition 
                          where studyVariableID = $id") ;
    $sth->execute() ;
    if ( defined ($arrRef = $sth->fetchrow_arrayref()) ) {
      %init = () ;
      $init{name} = $$arrRef[0] ;
      $init{diseaseAlleleFreq} = $$arrRef[1] ;
      $init{pen11} = $$arrRef[2] ;
      $init{pen12} = $$arrRef[3] ;
      $init{pen22} = $$arrRef[4] ;
      defined $$arrRef[5] and $init{malePen1} = $$arrRef[5] ;
      defined $$arrRef[6] and $init{malePen2} = $$arrRef[6] ;
      # Elements
      $sth1 = $dbh->prepare("select code, type, formula 
                             from AffectionStatusElement 
                             where asDefID = $$arrRef[7]") ;
      $sth1->execute() ;
      while ($arrRef1 = $sth1->fetchrow_arrayref()) {
	push(@aseList, {code => $$arrRef1[0],
			type => $$arrRef1[1],
			formula => $$arrRef1[2]}) ;
      }
      if (defined($aseList[0])) {
	$init{AffStatElements} = \@aseList ;
      }
      $param{AffStatDef} = { %init } ;
      # LiabilityClass data
      # This is for dynamic LCs
      $sth = $dbh->prepare("select name, lcDefID 
                            from LiabilityClassDefinition 
                            where studyVariableID = $id") ;
      $sth->execute() ;
      if ( defined($arrRef = $sth->fetchrow_arrayref()) ) {
	%init = () ;
	$init{name} = $$arrRef[0] ;
	# Classes
	$sth1 = $dbh->prepare("select code, description, pen11, pen12, pen22, 
                               malePen1, malePen2, formula 
                               from LiabilityClass 
                               where lcDefID = $$arrRef[1]") ;
	$sth1->execute() ;
	while ($arrRef1 = $sth1->fetchrow_arrayref()) {
	  %init1 = () ;
	  $init1{code} = $$arrRef1[0] ;
	  defined $$arrRef1[1] and $init1{description} = $$arrRef1[1] ;
	  $init1{pen11} = $$arrRef1[2] ;
	  $init1{pen12} = $$arrRef1[3] ;
	  $init1{pen22} = $$arrRef1[4] ;
	  defined $$arrRef1[5] and $init1{malePen1} = $$arrRef1[5] ;
	  defined $$arrRef1[6] and $init1{malePen2} = $$arrRef1[6] ;
	  $init1{formula} = $$arrRef1[7] ;
	  push(@lcList, { %init1 }) ;
	}
	$init{LiabilityClasses} = \@lcList ;
	$param{LCDef} = { %init } ;
      }
    }
  }

  $sv = new Genetics::StudyVariable(%param) ;
  
  $DEBUG and carp " ->[getStudyVariable] $sv" ;

  return($sv) ;
}

=head2 getMiniStudyVariable

  Function  : Get a "light" version of a Genetics::Object::StudyVariable object 
              from the database.
  Argument  : The Object ID of the StudyVariable to be returned.
  Returns   : A Genetics::Object::StudyVariable object.
  Scope     : Public
  Comments  : "Light" version means that the object has only the name and id 
              fields from Object, and it does not contain any associated NameAlias, 
              Contact, DBXReference or Keyword data.  It also has a sub-set of 
              StudyVariable-specific fields.
=cut

sub getMiniStudyVariable {
  my($self, $id) = @_ ;
  my($sv, %param, $sth, $sth1, $arrRef, $arrRef1, %init, %init1, $category, 
     $format, @codesList, @aseList, @lcList, $p11, $p12, $p22, $mp1, $mp2) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[getMiniStudyVariable] $id" ;

  # StudyVariable data
  $sth = $dbh->prepare("select name, id, dateCreated, dateModified, comment, 
                               category, format, isXLinked, description 
                        from Object, StudyVariable 
                        where id = $id 
                        and id = studyVariableID") ;
  $sth->execute() ;
  $arrRef = $sth->fetchrow_arrayref() ;
  $sth->finish() ;
  defined $arrRef or return(undef) ;

  $param{name} = $$arrRef[0] ;
  $param{id} = $$arrRef[1] ;
  $param{dateCreated} = $$arrRef[2] ;
  $param{dateModified} = $$arrRef[3] ;
  $param{comment} = $$arrRef[4] ;
  $category = $param{category} = $$arrRef[5] ;
  $format = $param{format} = $$arrRef[6] ;
  $param{isXLinked} = $$arrRef[7] ;
  defined $$arrRef[8] and $param{description} = $$arrRef[8] ;
  # CodeDerivation data
  if ($format eq "Code") {
    if ($category eq "StaticLiabilityClass") {
      $sth = $dbh->prepare("select codeDerivationID, code, description, formula 
                          from CodeDerivation 
                          where studyVariableID = $id") ;
      $sth->execute() ;
      $sth1 = $dbh->prepare("select pen11, pen12, pen22, malePen1, malePen2 
                             from StaticLCPenetrance 
                             where cdID = ?") ;
      while ($arrRef = $sth->fetchrow_arrayref()) {
	%init = () ;
	$sth1->execute($$arrRef[0]) ;
	($p11, $p12, $p22, $mp1, $mp2) = $sth1->fetchrow_array() ;
	$init{code} = $$arrRef[1] ;
	$init{pen11} = $p11 ;
	$init{pen12} = $p12 ;
	$init{pen22} = $p22 ;
	defined $mp1 and $init{malePen1} = $mp1 ;
	defined $mp2 and $init{malePen2} = $mp2 ;
	defined $$arrRef[2] and $init{description} = $$arrRef[2] ;
	defined $$arrRef[3] and $init{formula} = $$arrRef[3] ;
	push(@codesList, { %init }) ;
      }
    } else {
      $sth = $dbh->prepare("select code, description, formula 
                            from CodeDerivation 
                            where studyVariableID = $id") ;
      $sth->execute() ;
      while ($arrRef = $sth->fetchrow_arrayref()) {
	%init = () ;
	$init{code} = $$arrRef[0] ;
	defined $$arrRef[1] and $init{description} = $$arrRef[1] ;
	defined $$arrRef[2] and $init{formula} = $$arrRef[2] ;
	push(@codesList, { %init }) ;
      }
    }
  }
  defined $codesList[0] and $param{Codes} = \@codesList ;
  
  if ($category =~ /AffectionStatus$/) {
    # AffectionStatus data
    $sth = $dbh->prepare("select name, diseaseAlleleFreq, pen11, pen12, 
                                 pen22, malePen1, malePen2, asDefID 
                          from AffectionStatusDefinition 
                          where studyVariableID = $id") ;
    $sth->execute() ;
    if ( defined ($arrRef = $sth->fetchrow_arrayref()) ) {
      %init = () ;
      $init{name} = $$arrRef[0] ;
      $init{diseaseAlleleFreq} = $$arrRef[1] ;
      $init{pen11} = $$arrRef[2] ;
      $init{pen12} = $$arrRef[3] ;
      $init{pen22} = $$arrRef[4] ;
      defined $$arrRef[5] and $init{malePen1} = $$arrRef[5] ;
      defined $$arrRef[6] and $init{malePen2} = $$arrRef[6] ;
      # Elements
      $sth1 = $dbh->prepare("select code, type, formula 
                             from AffectionStatusElement 
                             where asDefID = $$arrRef[7]") ;
      $sth1->execute() ;
      while ($arrRef1 = $sth1->fetchrow_arrayref()) {
	push(@aseList, {code => $$arrRef1[0],
			type => $$arrRef1[1],
			formula => $$arrRef1[2]}) ;
      }
      $init{AffStatElements} = \@aseList ;
      $param{AffStatDef} = { %init } ;
    }
  }

  $sv = new Genetics::StudyVariable(%param) ;
  
  $DEBUG and carp " ->[getMiniStudyVariable] $sv" ;

  return($sv) ;
}

=head2 getPhenotype

  Function  : Get (read) a Genetics::Object::Phenotype object from the database.
  Argument  : The Object ID of the Phenotype to be returned.
  Returns   : A Genetics::Object::Phenotype object.
  Scope     : Public

=cut

sub getPhenotype {
  my($self, $id) = @_ ;
  my($pt, %param, $sth, $arrRef, $sth1, $arrRef1, $subjName, $svName, 
     @aaList, $aaName, $dataType, $value) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[getPhenotype] $id" ;

  $self->_getObjAssocData($id, \%param) ;

  # Phenotype data
  $sth = $dbh->prepare("select subjectID, svID, numberValue, codeValue, 
                               dateValue, isActive, dateCollected 
                        from Phenotype 
                        where ptID = $id") ;
  $sth->execute() ;
  $arrRef = $sth->fetchrow_arrayref() ;
  ( $subjName ) = $dbh->selectrow_array("select name from Object 
                                         where id = $$arrRef[0]") ;
  $param{Subject} = {name => $subjName, id => $$arrRef[0]} ;
  ( $svName ) = $dbh->selectrow_array("select name from Object 
                                       where id = $$arrRef[1]") ;
  $param{StudyVariable} = {name => $svName, id => $$arrRef[1]} ;
  $value = $$arrRef[2] || $$arrRef[3] || $$arrRef[4] ;
  $param{value} = $value || 0 ; # the 'or 0' here is for cases where the number 
                                # or code value is 0, in which case the above 
                                # statement sets value to false.  I think this 
                                # is ok, since there has to be a value.
  $param{isActive} = $$arrRef[5] ;
  defined $$arrRef[6] and $param{dateCollected} = $$arrRef[6] ;
  $sth->finish() ;
  # Phenotype AssayAttrs
  $sth = $dbh->prepare("select objID, attrID, stringValue, numberValue, 
                               dateValue, booleanValue
                        from AttributeValue 
                        where objID = $id") ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    ($aaName, $dataType) = $dbh->selectrow_array("select name, dataType 
                                                  from AssayAttribute 
                                                  where attrID = $$arrRef[1]") ;
    $value = $$arrRef[2] || $$arrRef[3] || $$arrRef[4] || $$arrRef[5] ;
    push(@aaList, {name => $aaName,
		   dataType => $dataType,
		   value => $value }) ;
  }
  defined $aaList[0] and $param{AssayAttrs} = [ @aaList ] ;
  
  $pt = new Genetics::Phenotype(%param) ;
  
  $DEBUG and carp " ->[getPhenotype] $pt" ;

  return($pt) ;
}

=head2 getMiniPhenotype

  Function  : Get a "light" version of a Genetics::Object::Phenotype object from 
              the database.
  Argument  : The Object ID of the Phenotype to be returned.
  Returns   : A Genetics::Object::Phenotype object.
  Scope     : Public
  Comments  : "Light" version means that the object has only the name and id 
              fields from Object, and it does not contain any associated NameAlias, 
              Contact, DBXReference or Keyword data.  It also has a sub-set of 
              Phenotype-specific fields.

=cut

sub getMiniPhenotype {
  my($self, $id) = @_ ;
  my($pt, %param, $sth, $arrRef, $subjName, $svName, $value) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[getMiniPhenotype] $id" ;

  # Phenotype data
  $sth = $dbh->prepare("select name, id, dateCreated, dateModified, comment, 
                               subjectID, svID, numberValue, codeValue, 
                               dateValue, isActive 
                        from Object, Phenotype 
                        where id = $id 
                        and id = ptID") ;
  $sth->execute() ;
  $arrRef = $sth->fetchrow_arrayref() ;
  $sth->finish() ;
  defined $arrRef or return(undef) ;

  $param{name} = $$arrRef[0] ;
  $param{id} = $$arrRef[1] ;
  $param{dateCreated} = $$arrRef[2] ;
  $param{dateModified} = $$arrRef[3] ;
  $param{comment} = $$arrRef[4] ;
  ( $subjName ) = $dbh->selectrow_array("select name from Object 
                                         where id = $$arrRef[5]") ;
  $param{Subject} = {name => $subjName, id => $$arrRef[5]} ;
  ( $svName ) = $dbh->selectrow_array("select name from Object 
                                       where id = $$arrRef[6]") ;
  $param{StudyVariable} = {name => $svName, id => $$arrRef[6]} ;
  $value = $$arrRef[7] || $$arrRef[8] || $$arrRef[9] ; 
  $param{value} = $value || 0 ; # the 'or 0' here is for cases where the number 
                                # or code value is 0, in which case the above 
                                # statement sets value to false.  I think this 
                                # is ok, since there has to be a value.
  $param{isActive} = $$arrRef[10] ;
  
  $pt = new Genetics::Phenotype(%param) ;
  
  $DEBUG and carp " ->[getMiniPhenotype] $pt" ;

  return($pt) ;
}

=head2 getFrequencySource

  Function  : Get (read) a Genetics::Object::FrequencySource object from the database.
  Argument  : The Object ID of the FrequencySource to be returned.
  Returns   : A Genetics::Object::FrequencySource object.
  Scope     : Public

=cut

sub getFrequencySource {
  my($self, $id) = @_ ;
  my($fs, %param, $sth, $arrRef, $sth1, $arrRef1, $obsFreqID, %init, $alleleName, 
     $alleleType, $poID, $poName, @oafList, $htName, @ohfList) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[getFrequencySource] $id" ;

  $self->_getObjAssocData($id, \%param) ;

  # FrequencySource data
  $sth = $dbh->prepare("select obsFreqID 
                        from FreqSourceObsFrequency
                        where freqSourceID = $id") ;
  $sth->execute() ;
  $sth1 = $dbh->prepare("select type, alleleID, htID, frequency
                         from ObsFrequency
                         where obsFreqID = ?") ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    $obsFreqID = $$arrRef[0] ;
    $sth1->bind_param( 1, $obsFreqID ) ;
    $sth1->execute() ;
    while ($arrRef1 = $sth1->fetchrow_arrayref()) {
      %init = () ;
      if ($$arrRef1[0] eq "Allele") {
	( $alleleName, $alleleType, $poID ) = 
                                 $dbh->selectrow_array("select name, type, poID 
                                                        from Allele 
                                                        where alleleID = $$arrRef1[1]") ;
	( $poName ) = $dbh->selectrow_array("select name from Object 
                                             where id = $poID") ;
	$init{name} = $alleleName ;
	$init{type} = $alleleType ;
	$init{Marker} = { name => $poName, id => $poID } ;
	push(@oafList, { Allele => { %init }, 
			 frequency => $$arrRef1[3] }) ;
      } elsif ($$arrRef1[0] eq "Ht") {
	( $htName ) = $dbh->selectrow_array("select name from Object 
                                             where id = $$arrRef1[2]") ;
	$init{name} = $htName ;
	$init{id} = $$arrRef1[2] ;
	push(@ohfList, { Haplotype => { %init }, 
			 frequency => $$arrRef1[3] }) ;
      }
    }
  }
  defined $oafList[0] and $param{ObsAlleleFrequencies} = \@oafList ;
  defined $ohfList[0] and $param{ObsHtFrequencies} = \@ohfList ;

  $fs = new Genetics::FrequencySource(%param) ;
  
  $DEBUG and carp " ->[getFrequencySource] $fs" ;

  return($fs) ;
}

=head2 getMiniFrequencySource

  Function  : Get (read) a Genetics::Object::FrequencySource object from the database.
  Argument  : The Object ID of the FrequencySource to be returned.
  Returns   : A Genetics::Object::FrequencySource object.
  Scope     : Public

=cut

sub getMiniFrequencySource {
  my($self, $id) = @_ ;
  my($fs, %param, $sth, $arrRef, $sth1, $arrRef1, $obsFreqID, %init, $alleleName, 
     $alleleType, $poID, $poName, @oafList, $htName, @ohfList) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[getMiniFrequencySource] $id" ;

  $sth = $dbh->prepare("select name, id dateCreated, dateModified, comment, 
                        from Object 
                        where id = $id") ;
  $sth->execute() ;
  $arrRef = $sth->fetchrow_arrayref() ;
  $sth->finish() ;
  defined $arrRef or return(undef) ;

  $param{name} = $$arrRef[0] ;
  $param{id} = $$arrRef[1] ;
  $param{dateCreated} = $$arrRef[2] ;
  $param{dateModified} = $$arrRef[3] ;
  $param{comment} = $$arrRef[4] ;
  
  # FrequencySource data
  $sth = $dbh->prepare("select obsFreqID 
                        from FreqSourceObsFrequency
                        where freqSourceID = $id") ;
  $sth->execute() ;
  $sth1 = $dbh->prepare("select type, alleleID, htID, frequency
                         from ObsFrequency
                         where obsFreqID = ?") ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    $obsFreqID = $$arrRef[0] ;
    $sth1->bind_param( 1, $obsFreqID ) ;
    $sth1->execute() ;
    while ($arrRef1 = $sth1->fetchrow_arrayref()) {
      %init = () ;
      if ($$arrRef1[0] eq "Allele") {
	( $alleleName, $alleleType, $poID ) = 
                       $dbh->selectrow_array("select name, type, poID 
                                              from Allele 
                                              where alleleID = $$arrRef1[1]") ;
	( $poName ) = $dbh->selectrow_array("select name from Object 
                                             where id = $poID") ;
	$init{name} = $alleleName ;
	$init{type} = $alleleType ;
	$init{Marker} = { name => $poName, id => $poID } ;
	push(@oafList, { Allele => { %init }, 
			 frequency => $$arrRef1[3] }) ;
      } elsif ($$arrRef1[0] eq "Ht") {
	( $htName ) = $dbh->selectrow_array("select name from Object 
                                             where id = $$arrRef1[2]") ;
	$init{name} = $htName ;
	$init{id} = $$arrRef1[2] ;
	push(@ohfList, { Haplotype => { %init }, 
			 frequency => $$arrRef1[3] }) ;
      }
    }
  }
  defined $oafList[0] and $param{ObsAlleleFrequencies} = \@oafList ;
  defined $ohfList[0] and $param{ObsHtFrequencies} = \@ohfList ;

  $fs = new Genetics::FrequencySource(%param) ;
  
  $DEBUG and carp " ->[getMiniFrequencySource] $fs" ;

  return($fs) ;
}

=head2 getHtMarkerCollection

  Function  : Get (read) a Genetics::Object::HtMarkerCollection object from the database.
  Argument  : The Object ID of the HtMarkerCollection to be returned.
  Returns   : A Genetics::Object::HtMarkerCollection object.
  Scope     : Public

=cut

sub getHtMarkerCollection {
  my($self, $id) = @_ ;
  my($hmc, %param, $sth, $arrRef, %init, $poName, @markersList) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[getHtMarkerCollection] $id" ;

  $self->_getObjAssocData($id, \%param) ;

  # HtMarkerCollection data
  $sth = $dbh->prepare("select distanceUnits
                        from HtMarkerCollection 
                        where hmcID = $id") ;
  $sth->execute() ;
  if ( defined ($arrRef = $sth->fetchrow_arrayref()) ) {
    $param{distanceUnits} = $$arrRef[0] ;
  } else {
    return(undef) ;
  }
  $sth->finish() ;
  $sth = $dbh->prepare("select poID, sortOrder, distance 
                        from HMCPolyObj 
                        where hmcID = $id 
                        order by sortOrder") ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    %init = () ;
    ( $poName ) = $dbh->selectrow_array("select name from Object 
                                         where id = $$arrRef[0]") ;
    $init{name} = $poName ;
    $init{id} = $$arrRef[0] ;
    defined $$arrRef[2] and $init{distance} = $$arrRef[2] ;
    push(@markersList, { %init }) ;
  }
  $param{Markers} = \@markersList ;

  $hmc = new Genetics::HtMarkerCollection(%param) ;
  
  $DEBUG and carp " ->[getHtMarkerCollection] $hmc" ;
  return($hmc) ;
}

=head2 getHaplotype

  Function  : Get (read) a Genetics::Object::Haplotype object from the database.
  Argument  : The Object ID of the Haplotype to be returned.
  Returns   : A Genetics::Object::Haplotype object.
  Scope     : Public

=cut

sub getHaplotype {
  my($self, $id) = @_ ;
  my($ht, %param, $sth, $arrRef, $hmcID, $hmcName, %init, $name, $type, @alleleList) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[getHaplotype] $id" ;

  $self->_getObjAssocData($id, \%param) ;

  # Haplotype data
  ( $hmcID ) = $dbh->selectrow_array("select hmcID 
                                      from Haplotype 
                                      where haplotypeID = $id") ;
  ( $hmcName ) = $dbh->selectrow_array("select name  
                                      from Object 
                                      where id = $hmcID") ;
  $param{MarkerCollection} = { name => $hmcName, 
			       id => $hmcID } ;
  $sth = $dbh->prepare("select alleleID, sortOrder
                        from HaplotypeAllele 
                        where haplotypeID = $id
                        order by sortOrder") ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    %init = () ;
    ( $name, $type ) = $dbh->selectrow_array("select name, type 
                                              from Allele 
                                              where alleleID = $$arrRef[0]") ;
    push(@alleleList, { name => $name, type => $type}) ;
  }
  $param{Alleles} = \@alleleList ;
  
  $ht = new Genetics::Haplotype(%param) ;
  
  $DEBUG and carp " ->[getHaplotype] $ht" ;

  return($ht) ;
}

=head2 getMiniHaplotype

  Function  : Get a "light" version of a Genetics::Object::Haplotype object 
              from the database.
  Argument  : The Object ID of the Haplotype to be returned.
  Returns   : A Genetics::Object::Haplotype object.
  Scope     : Public
  Comments  : "Light" version means that the object has only the name and id 
              fields from Object, and it does not contain any associated NameAlias, 
              Contact, DBXReference or Keyword data.

=cut

sub getMiniHaplotype {
  my($self, $id) = @_ ;
  my($ht, %param, $htName, $sth, $arrRef, $hmcID, $hmcName, %init, $name, $type, 
     @alleleList) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[getMiniHaplotype] $id" ;

  # Haplotype data
  $sth = $dbh->prepare("select name, id, dateCreated, dateModified, comment, hmcID 
                        from Object, Haplotype 
                        where id = $id 
                        and id = haplotypeID") ;
  $sth->execute() ;
  $arrRef = $sth->fetchrow_arrayref() ;
  $sth->finish() ;
  defined $name or return(undef) ;

  $param{name} = $$arrRef[0] ;
  $param{id} = $$arrRef[1] ;
  $param{dateCreated} = $$arrRef[2] ;
  $param{dateModified} = $$arrRef[3] ;
  $param{comment} = $$arrRef[4] ;
  $hmcID = $$arrRef[5] ;

  ( $hmcName ) = $dbh->selectrow_array("select name  
                                      from Object 
                                      where id = $hmcID") ;
  
  $param{MarkerCollection} = { name => $hmcName, 
			       id => $hmcID } ;
  $sth = $dbh->prepare("select alleleID, sortOrder
                        from HaplotypeAllele 
                        where haplotypeID = $id
                        order by sortOrder") ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    %init = () ;
    ( $name, $type ) = $dbh->selectrow_array("select name, type 
                                              from Allele 
                                              where alleleID = $$arrRef[0]") ;
    push(@alleleList, { name => $name, type => $type}) ;
  }
  $param{Alleles} = \@alleleList ;
  
  $ht = new Genetics::Haplotype(%param) ;
  
  $DEBUG and carp " ->[getMiniHaplotype] $ht" ;

  return($ht) ;
}

=head2 getDNASample

  Function  : Get (read) a Genetics::Object::DNASample object from the database.
  Argument  : The Object ID of the DNASample to be returned.
  Returns   : A Genetics::Object::DNASample object.
  Scope     : Public

=cut

sub getDNASample {
  my($self, $id) = @_ ;
  my($sample, %param, $sth, $arrRef, $subjID, $subjName, $gtName, @gtList) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[getDNASample] $id" ;

  $self->_getObjAssocData($id, \%param) ;

  # DNASample data
  $sth = $dbh->prepare("select dateCollected, amount, amountUnits, 
                               concentration, concUnits
                        from Sample, DNASample 
                        where sampleID = $id 
                        and sampleID = dnaSampleID") ;
  $sth->execute() ;
  $arrRef = $sth->fetchrow_arrayref() ;
  defined $$arrRef[0] and $param{dateCollected} = $$arrRef[0] ;
  defined $$arrRef[1] and $param{amount} = $$arrRef[1] ;
  defined $$arrRef[2] and $param{amountUnits} = $$arrRef[2] ;
  defined $$arrRef[3] and $param{concentration} = $$arrRef[3] ;
  defined $$arrRef[4] and $param{concUnits} = $$arrRef[4] ;
  $sth->finish() ;
  # Subject
  ( $subjID ) = $dbh->selectrow_array( "select subjectID 
                                        from SubjectSample 
                                        where sampleID = $id" ) ;
  if (defined $subjID) {
    ( $subjName ) = $dbh->selectrow_array( "select name 
                                            from Object 
                                            where id = $subjID" ) ;
    $param{Subject} = {name => $subjName, id => $subjID} ;
  }
  # Genotypes
  $sth = $dbh->prepare( "select gtID 
                         from SampleGenotype 
                         where sampleID = $id" ) ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    ( $gtName ) = $dbh->selectrow_array( "select name 
                                          from Object 
                                          where id = $subjID" ) ;
    push(@gtList, {name => $gtName, id => $$arrRef[0]}) ;
  }
  if (defined $gtList[0]) {
    $param{Genotypes} = \@gtList ;
  }

  $sample = new Genetics::DNASample(%param) ;
  
  $DEBUG and carp " ->[getDNASample] $sample" ;

  return($sample) ;
}

=head2 getTissueSample

  Function  : Get (read) a Genetics::Object::TissueSample object from the database.
  Argument  : The Object ID of the TissueSample to be returned.
  Returns   : A Genetics::Object::TissueSample object.
  Scope     : Public

=cut

sub getTissueSample {
  my($self, $id) = @_ ;
  my($sample, %param, $sth, $arrRef, $subjID, $subjName, $dsName, @dsList) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[getTissueSample] $id" ;

  $self->_getObjAssocData($id, \%param) ;

  # TissueSample data
  $sth = $dbh->prepare("select dateCollected, tissue, amount, amountUnits 
                        from Sample, TissueSample 
                        where sampleID = $id 
                        and sampleID = tissueSampleID") ;
  $sth->execute() ;
  $arrRef = $sth->fetchrow_arrayref() ;
  defined $$arrRef[0] and $param{dateCollected} = $$arrRef[0] ;
  defined $$arrRef[1] and $param{tissue} = $$arrRef[1] ;
  defined $$arrRef[2] and $param{amount} = $$arrRef[2] ;
  defined $$arrRef[3] and $param{amountUnits} = $$arrRef[3] ;
  $sth->finish() ;
  # Subject
  ( $subjID ) = $dbh->selectrow_array( "select subjectID 
                                        from SubjectSample 
                                        where sampleID = $id" ) ;
  if (defined $subjID) {
    ( $subjName ) = $dbh->selectrow_array( "select name 
                                            from Object 
                                            where id = $subjID" ) ;
    $param{Subject} = {name => $subjName, id => $subjID} ;
  }
  # DNASamples
  $sth = $dbh->prepare( "select dnaSampleID
                         from TissueDNASample 
                         where tissueSampleID = $id" ) ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    ( $dsName ) = $dbh->selectrow_array( "select name 
                                          from Object 
                                          where id = $subjID" ) ;
    push(@dsList, {name => $dsName, id => $$arrRef[0]}) ;
  }
  if (defined $dsList[0]) {
    $param{DNASAmples} = \@dsList ;
  }

  $sample = new Genetics::TissueSample(%param) ;
  
  $DEBUG and carp " ->[getTissueSample] $sample" ;

  return($sample) ;
}

=head2 getMap

  Function  : Get (read) a Genetics::Object::Map object from the database.
  Argument  : The Object ID of the Map to be returned.
  Returns   : A Genetics::Object::Map object.
  Scope     : Public

=cut

sub getMap {
  my($self, $id) = @_ ;
  my($map, %param, $sth, $arrRef, $orgID, %init, $soName, @omeList) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[getMap] $id" ;

  $self->_getObjAssocData($id, \%param) ;

  # Map data
  $sth = $dbh->prepare("select chromosome, organismID, 
                               orderingMethod, distanceUnits
                        from Map 
                        where mapiD = $id") ;
  $sth->execute() ;
  $arrRef = $sth->fetchrow_arrayref() ;
  defined $$arrRef[0] and $param{chromosome} = $$arrRef[0] ;
  defined $$arrRef[2] and $param{orderingMethod} = $$arrRef[2] ;
  defined $$arrRef[3] and $param{distanceUnits} = $$arrRef[3] ;
  $sth->finish() ;
  # Organism data
  if ( defined ($orgID = $$arrRef[1]) ) {
    $sth = $dbh->prepare("select genusSpecies, subspecies, strain 
                          from Organism 
                          where organismID = $orgID") ;
    $sth->execute() ;
    $arrRef = $sth->fetchrow_arrayref() ;
    $init{genusSpecies} = $$arrRef[0] ;
    defined $$arrRef[1] and $init{subspecies} = $$arrRef[1] ;
    defined $$arrRef[2] and $init{strain} = $$arrRef[2] ;
    $param{Organism} = { %init } ;
    $sth->finish() ;
  }
  # OrderedMapElement data
  $sth = $dbh->prepare("select soID, sortOrder, name, distance, comment 
                        from OrderedMapElement 
                        where mapID = $id
                        order by sortOrder") ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    %init = () ;
    ( $soName ) = $dbh->selectrow_array("select name from Object 
                                         where id = $$arrRef[0]") ;
    $init{SeqObj} = {name => $soName, id => $$arrRef[0]} ;
    $init{name} = $$arrRef[2] ;
    defined $$arrRef[3] and $init{distance} = $$arrRef[3] ;
    defined $$arrRef[4] and $init{comment} = $$arrRef[4] ;
    push(@omeList, { %init }) ;
  }
  $param{OrderedMapElements} = \@omeList ;

  $map = new Genetics::Map(%param) ;
  
  $DEBUG and carp " ->[getMap] $map" ;

  return($map) ;
}

=head2 getMiniMap

  Function  : Get "light" version of a Genetics::Object::Map object from 
              the database.
  Argument  : The Object ID of the Map to be returned.
  Returns   : A Genetics::Object::Map object.
  Scope     : Public
  Comments  : "Light" version means that the object has only the name and id 
              fields from Object, and it does not contain any associated NameAlias, 
              Contact, DBXReference or Keyword data.  It also has a sub-set of 
              Map-specific fields.

=cut

sub getMiniMap {
  my($self, $id) = @_ ;
  my($map, %param, $sth, $arrRef, %init, $soName, @omeList) ;
  my $dbh = $self->{dbh} ;
    
  $DEBUG and carp " ->[getMiniMap] $id" ;

  $self->_getObjAssocData($id, \%param) ;

  # Map data
  $sth = $dbh->prepare("select name, id, dateCreated, dateModified, comment, 
                               chromosome, orderingMethod, distanceUnits 
                        from Object, Map 
                        where id = $id 
                        and id = mapiD") ;
  $sth->execute() ;
  $arrRef = $sth->fetchrow_arrayref() ;
  $sth->finish() ;
  defined $arrRef or return(undef) ;

  $param{name} = $$arrRef[0] ;
  $param{id} = $$arrRef[1] ;
  $param{dateCreated} = $$arrRef[2] ;
  $param{dateModified} = $$arrRef[3] ;
  $param{comment} = $$arrRef[4] ;
  defined $$arrRef[5] and $param{chromosome} = $$arrRef[5] ;
  defined $$arrRef[6] and $param{orderingMethod} = $$arrRef[6] ;
  defined $$arrRef[7] and $param{distanceUnits} = $$arrRef[7] ;

  # OrderedMapElement data
  $sth = $dbh->prepare("select soID, sortOrder, name, distance, comment 
                        from OrderedMapElement 
                        where mapID = $id
                        order by sortOrder") ;
  $sth->execute() ;
  while ($arrRef = $sth->fetchrow_arrayref()) {
    %init = () ;
    ( $soName ) = $dbh->selectrow_array("select name from Object 
                                         where id = $$arrRef[0]") ;
    $init{SeqObj} = {name => $soName, id => $$arrRef[0]} ;
    $init{name} = $$arrRef[2] ;
    defined $$arrRef[3] and $init{distance} = $$arrRef[3] ;
    defined $$arrRef[4] and $init{comment} = $$arrRef[4] ;
    push(@omeList, { %init }) ;
  }
  $param{OrderedMapElements} = \@omeList ;

  $map = new Genetics::Map(%param) ;
  
  $DEBUG and carp " ->[getMiniMap] $map" ;

  return($map) ;
}

=head1 Private methods

=head2 _getObjAssocData

  Function  : get (read) data from and associated with the Object table/object.
  Arguments : Scalar containing an Object.id and a reference to a hash which 
              will be populated with the data.
  Returns   : N/A
  Scope     : Private
  Called by : The various getObjectSubClass methods.
  Comments  : The format of the data structure created by this method is 
              identical to that passed to Object::new().

=cut

sub _getObjAssocData {
  my($self, $id, $paramPtr) = @_ ;
  my($sth, $arrRef1, $arrRef2, %init, $contactName, $contactID, $naListPtr, $contactPtr, 
     $xRefListPtr, $kwListPtr) ;
  my $dbh = $self->{dbh} ;

  $sth = $dbh->prepare("select name, id, dateCreated, dateModified, comment, 
                               url, contactID
                        from Object 
                        where Object.id = $id") ;
  $sth->execute() ;
  $arrRef1 = $sth->fetchrow_arrayref() ;
  defined $arrRef1 or return(undef) ;
  $sth->finish() ;

  $$paramPtr{name} = $$arrRef1[0] ;
  $$paramPtr{id} = $$arrRef1[1] ;
  $$paramPtr{dateCreated} = $$arrRef1[2] ;
  defined $$arrRef1[3] and $$paramPtr{dateModified} = $$arrRef1[3] ;
  defined $$arrRef1[4] and $$paramPtr{comment} = $$arrRef1[4] ;
  defined $$arrRef1[5] and $$paramPtr{url} = $$arrRef1[5] ;

  # NameAliases
  $sth = $dbh->prepare("select name, contactID 
                        from NameAlias 
                        where objID = $id") ;
  $sth->execute() ;
  while ($arrRef2 = $sth->fetchrow_arrayref()) {
    %init = () ;
    $init{name} = $$arrRef2[0] ;
    if ( defined($contactID = $$arrRef2[1]) ) {
      ( $contactName ) = $dbh->selectrow_array("select name from Contact 
                                                where contactID = $contactID") ;
      defined $contactName and $init{contactName} = $contactName ;
    }
    push(@$naListPtr, { %init }) ;
  }
  defined $naListPtr and $$paramPtr{NameAliases} = $naListPtr ;
  # Contact
  if ( defined ($contactID = $$arrRef1[6]) ) {
    $sth = $dbh->prepare("select addressID, name, organization, comment 
                          from Contact 
                          where contactID = $contactID") ;
    $sth->execute() ;
    $arrRef2 = $sth->fetchrow_arrayref() ;
    $sth->finish() ;
    %init = () ;
    $init{name} = $$arrRef2[1] ;
    defined $$arrRef2[2] and $init{organization} = $$arrRef2[2] ;
    defined $$arrRef2[3] and $init{comment} = $$arrRef2[3] ;
    $$paramPtr{Contact} = { %init } ;
  }
  # DBXReferences
  $sth = $dbh->prepare("select accessionNumber, databaseName, schemaName, comment 
                        from DBXReference 
                        where objID = $id") ;
  $sth->execute() ;
  while ($arrRef2 = $sth->fetchrow_arrayref()) {
    %init = (accessionNumber => $$arrRef2[0],
	     databaseName => $$arrRef2[1]) ;
    defined $$arrRef2[2] and $init{schemaName} = $$arrRef2[2] ;
    defined $$arrRef2[3] and $init{comment} = $$arrRef2[3] ;
    push(@$xRefListPtr, { %init }) ;
  }
  defined $xRefListPtr and $$paramPtr{DBXReferences} = $xRefListPtr ;
  # Keywords
  $sth = $dbh->prepare("select name, dataType, description, stringValue, 
                               numberValue, dateValue, booleanValue 
                        from KeywordType, Keyword  
                        where Keyword.objID = $id 
                        and Keyword.keywordTypeID = KeywordType.keywordTypeID") ;
  $sth->execute() ;
  while ($arrRef2 = $sth->fetchrow_arrayref()) {
    %init = () ;
    $init{name} = $$arrRef2[0] ;
    $init{dataType} = $$arrRef2[1] ;
    defined $$arrRef2[2] and $init{description} = $$arrRef2[2] ;
    $$arrRef2[1] eq "String" and $init{value} = $$arrRef2[3] ;
    $$arrRef2[1] eq "Number" and $init{value} = $$arrRef2[4] ;
    $$arrRef2[1] eq "Date" and $init{value} = $$arrRef2[5] ;
    $$arrRef2[1] eq "Boolean" and $init{value} = $$arrRef2[6] ;
    push(@$kwListPtr, { %init }) ;
  }
  defined $kwListPtr and $$paramPtr{Keywords} = $kwListPtr ;

  return(1) ;
}

1;

