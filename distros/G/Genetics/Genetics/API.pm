# GenPerl module 
#

# POD documentation - main docs before the code

=head1 NAME

Genetics::API

=head1 SYNOPSIS

  use Genetics::API ;

  $api = new Genetics::API(DSN => {driver => "mysql",
				   host => $Host,
				   database => $Database},
                           user => $UserName,
                           password => $Password) ;

  $sv = $api->getObject({NAME => "Aff"}) ;

  @affSubjects = $api->getSubjectsByPhenotype($sv, 2) ;
  $affCluster = $api->createCluster("HT Affecteds", \@affSubjects) ;
  $api->insertCluster($affCluster) ;
  @unaffSubjects = $api->getSubjectsByPhenotype($sv, 1) ;
  $unaffCluster = $api->createCluster("Normals", \@unaffSubjects) ;
  $api->insertCluster($unaffCluster) ;

  $marker = $api->getObject({TYPE => "Marker", NAME => "agtT174M"}) ;

  $api->chiSquareAssocTest(
			   MARKER => $marker, 
			   SC1 => $affCluster,
			   SC2 => $unaffCluster,
			   ALLELETYPE => "Nucleotide", 
			  ) ;

See also the GenPerl Tutorial document.

=head1 DESCRIPTION

This module provides an API for interfacing with genperl objects.

An instance of Genetics::API must be instantiated in order to interact with 
GenPerl objects in a database (or to access any other API methods, for that 
matter). The parameters passed to the Genetics::API constructor are the database 
connection parameters. These parameters are passed directly to DBI->connect for 
the creation of a database handle. 

The GenPerl API functionality is separated into the following packages. 

The Genetics::API package contains general API methods that do not fit anywhere 
else right now. This is the only package that needs to be imported into your 
programs. 

Teh Genetics::API::DB::*  packages contain methods for managing the persistance 
of GenPerl objects in a relational database. 

The Genetics::API::Analysis package contains methods for the analysis of data 
contained in GenPerl objects. 

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

package Genetics::API ;

BEGIN {
    $ID = "Genetics::API" ;
    #$DEBUG = $main::DEBUG ;
    $DEBUG = 0 ;
    $DEBUG and $| = 1 ;
    $DEBUG and warn "Debugging in $ID is on" ;
}

=head1 Imported Packages

  strict		Just to be anal
  vars		        Global variables
  Carp		        Error reporting
  DBI                   Database interface
  Genetics::API::Insert 
  Genetics::API::Read   
  Genetics::API::Update
  Genetics::API::DB::Query ;
  Genetics::API::Delete 
  Genetics::API::Analysis  Analysis functions
  Genetics::API::Analysis::Linkage  Linkage analysis functions
  Genetics::Object      GenPerl object modules

=cut

use strict ;
use vars qw(@ISA @EXPORT @EXPORT_OK $ID $DEBUG) ;
use Carp ;
use Exporter ;

use DBI ;

use Genetics::API::DB::Insert ;
use Genetics::API::DB::Read ;
use Genetics::API::DB::Update ;
use Genetics::API::DB::Delete ;
use Genetics::API::DB::Query ;
use Genetics::API::Analysis ;
use Genetics::API::Analysis::Linkage ;

use Genetics::Object ;

require		5.004 ;

@ISA = qw(Exporter AutoLoader) ;
@EXPORT = qw() ;
@EXPORT_OK = qw();

=head1 Public Methods

=head2 new

  Function  : Object constructor
  Arguments : Class name and hash array containing initialization arguments.
  Returns   : Blessed hash
  Scope     : Public
  Called by : Main
  Comments  : Creates an empty hash, blesses it into the class name and calls
              _initialize with the arguments passed

=cut

sub new {
    my($pkg, %args) = @_ ;

    my($self) = {} ;
    bless $self, ref($pkg) || $pkg ;

    $DEBUG and carp "\n==>Creating new $ID object: $self" ;

    $self->_initialize(%args) or croak "FATAL ERROR: $ID new() failed to initialize object: $self" ;

    $DEBUG and carp "==>Successfully created new $ID object: $self" ;

    return($self) ;
}

=head2 getDBH

  Function  : Return the DBI database handle associated with an instance 
              of Genetics::API.
  Arguments : Genetics::API instance.
  Returns   : DBI database handle object.
  Scope     : Public
  Called by : Main
  Comments  : 

=cut

sub getDBH {
    my($self) = @_ ;

    return $self->{dbh} ;
}

=head2 today

 Function  : Generate a date string, corresponding to the current date-time, 
             suitable for the dateCreated created field.
 Arguments : N/A
 Returns   : String
 Example   : today()
 Scope     : Public class method
 Comments  : The format of the date string generated is YYYY-MM-DD

=cut

sub today {
  my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time) ;
  $year += 1900 ;
  $mon++ ;
  ($mon < 10) and ($mon = "0" . $mon) ;
  ($mday < 10) and ($mday = "0" . $mday) ;

  return("$year-$mon-$mday") ;
}

=head2 getTypeByID

  Function  : Return the object type corresponding to a database ID. 
  Arguments : A database id.
  Returns   : 1 on success or undef if an object witht he input id was not 
              successfully deleted.
  Scope     : Public
  Comments  : Only objects saved in a GenPerl database should have an id.

=cut

sub getTypeByID {
  my($self, $id) = @_ ;
  my($type) ;
  my $dbh = $self->{dbh} ;

  ( $type ) = $dbh->selectrow_array("select objType from Object 
                                     where id = $id") ;
  defined($type) ? return($type) 
                 : return(undef) ;
}

=head2 getImportID

  Function  : Return the ImportID associated with an object. 
  Arguments : A Genetics::Object object.
  Returns   : Scalar containing the ImportID associated with the object, or 
              undef if one does not exist.
  Scope     : Public
  Comments  : ImportIDs are stored as Keywords with keywordTypeID 1.  ImportID 
              Keywords are created automatically (by _saveObjectData()) when a 
              new object is created.

=cut

sub getImportID {
  my($self, $obj) = @_ ;
  my($id, $importID) ;
  my $dbh = $self->{dbh} ;
  
  $id = $obj->field("id") ;
  ( $importID ) = $dbh->selectrow_array( "select stringValue from Keyword 
                                          where keywordTypeID = 1 
                                          and objID = $id" ) ;

  unless ( defined($importID) and $importID ne "" ) {
    carp " ->[getImportID] Can't find an ImportID associated with $obj!" ;
    return(undef) ;
  }

  return($importID) ;
}

=head2 getKwTypesByObjectType

 Function  : For a given object type, return the list of distinct KeywordType 
             names for which there are corresponding Keyword values in the 
             database.
 Arguments : Scalar containing an object type.
 Returns   : Array of scalar text strings.
 Scope     : Public
 Comments  : 

=cut

sub getKwTypesByObjectType {
  my($self, $type) = @_ ;
  my $dbh = $self->{dbh} ;
  my $query = "select distinct kwt.name 
               from Object obj, Keyword kw, KeywordType kwt
               where obj.objType = '$type' and 
               kwt.keywordTypeID = kw.keywordTypeID and 
               obj.id = kw.objID" ;
  my($aroar, $arrRef, @kwTypes) ;

  $aroar = $dbh->selectall_arrayref($query) ;
  foreach $arrRef (@$aroar) {
    push @kwTypes, $$arrRef[0] ;
  }

  return(@kwTypes) ;
}

=head2 createCluster

  Function  : Create a Genetics::Object::Cluster
  Arguments : A string containing a name for the Cluster and an array 
              reference to a list of Genetics::Object objects.
  Returns   : A Genetics::Object::Cluster object.
  Scope     : Public
  Comments  : This method only creates a Cluster; it does not save it.

=cut

sub createCluster {
  my($self, $name, $objListPtr) = @_ ;
  my($obj, $type, %types, @contents, $today, $cluster) ;

  foreach $obj (@$objListPtr) {
    $type = ref $obj ;
    $type =~ s/^.*::// ;
    $types{$type}++ ;
    push(@contents, {name => $obj->name(), id => $obj->id()}) ;
  }

  scalar(keys(%types)) > 1 and $type = "Mixed" ;
  $today = today() ;

  $cluster = new Genetics::Cluster(name => $name,
				   importID => $$,
				   dateCreated => $today, 
				   clusterType => $type, 
				   Contents=> [ @contents ]
				  ) ;
  
  return($cluster) ;
}

=head2 writeMultiXML

  Function  : Write a list of objects out in well-formed GnomML XML format.
  Argument  : Array reference to a list of Genetics::Object objects.
  Returns   : N/A
  Scope     : Public
  Called by : 

=cut

sub writeMultiXML {
    my($pkg, $objListPtr) = @_ ;
    my($writer, $gnom, $class, $name, $id) ;

    $writer = new XML::Writer(DATA_MODE => 1,
			      DATA_INDENT => 1) ;
    $writer->xmlDecl("UTF-8") ;
    $writer->doctype('GNOMObjects', "-//Genomica Corp.//Genetic and genomic data objects//EN", "http://admin.genomica.com/mathias/xml/GnomML.dtd") ;
    $writer->startTag('GNOMObjects') ;
    $writer->dataElement('Version', "0.4") ;
    foreach $gnom (@$objListPtr) {
	#$gnom->print ;
	$gnom->writeXML($writer) ;
    }
    $writer->endTag('GNOMObjects') ;
    $writer->end() ;

    return(1) ;
}

=head2 DESTROY

  Function  : Deallocate object storage
  Argument  : N/A
  Returns   : N/A
  Scope     : Public
  Called by : Called automatically when the object goes out of scope 
              (ie the internal reference count in the symbol table is 
              zero).  Can be called explicitly.

=cut

sub DESTROY {
    my($self) = shift ; 
    my $dbh = $self->{dbh} ;

    defined $dbh and $dbh->disconnect() ;

    $DEBUG and carp "\n==>Destroyed $ID object: $self" ;
}

=head1 Private methods

=head2 _initialize

  Function  : Initialize object
  Arguments : Hash array of attributes/values passed to new
  Returns   : N/A
  Scope     : Private
  Called by : 
  Comments  : 

=cut

sub _initialize {
  my ($self, %args) = @_;
  my ($dsnPtr, $driver, $db, $host, $port, $socket, $dataSourceStr, $dbh) ;

  if ( defined($dsnPtr = $args{DSN}) ) {
    #defined($driver = $$dsnPtr{driver}) or $driver = "mysql" ;
    $driver = "mysql" ;
    defined($db = $$dsnPtr{database}) or $db = "gp" ;
    defined($host = $$dsnPtr{host}) or $host = "localhost" ;
    defined($port = $$dsnPtr{port}) or $port = 3306 ;
    defined($socket = $$dsnPtr{socket}) or $socket = "/tmp/mysql.sock" ;
    $dataSourceStr = "DBI:$driver:database=$db;host=$host;port=$port;mysql_socket=$socket" ;
    $dbh = DBI->connect($dataSourceStr, 
			$args{user}, 
			$args{password}, 
			{PrintError => 0, # Don't report errors via warn()
			 RaiseError => 1} # Do report errors via die()
		       ) or carp "Can't connect to database: $DBI::errstr" ;
    $self->{dbh} = $dbh ;
  }

  $DEBUG and carp "==>Completed initialization of object: $self" ;

  return(1) ;
}

=head2 _getIDByImportID

  Function  : Return an Object ID based on an ImportID Keyword. 
  Arguments : Scalar containing an ImportID.
  Returns   : Scalar containing an Object ID or undef if one does 
              not exist.
  Scope     : Private
  Comments  : ImportID Keywords are created by _saveObjectData().

=cut

sub _getIDByImportID {
  my($self, $importID) = @_ ;
  my($sth, $id, $extra) ;
  my $dbh = $self->{dbh} ;
  
  if ( ! defined($importID) ) {
    carp " ->[_getIDByImportID] No ImportID!" ;
    return(undef) ;
  }
  $sth = $dbh->prepare("select objID from Keyword 
                        where keywordTypeID = 1 
                        and stringValue = ?") ;
  $sth->execute($importID) ;
  ( $id ) = $sth->fetchrow_array() ;
  if (defined $id) {
    ( $extra ) = $sth->fetchrow_array() ; # Check for duplicates
    if (defined $extra) {
      carp " ->[_getIDByImportID] There are multiple objects with Keyword ImportID = $importID!" ;
      $sth->finish() ;
      return(undef) ;
    }
  } else {
    $sth->finish() ;
    return(undef) ;
  }

  return($id) ;
}

=head2 _getOrganismID

  Function  : Return an Organism ID.   
  Arguments : Hash reference to a hash containing Organism data.
  Returns   : Scalar containing an Organism ID.
  Scope     : Private
  Called by : saveSubject(), saveMarker(), saveSNP, saveMap(), updateSubject(), 
              updateMarker(), updateSNP, updateMap().
  Comments  : A new Organism is created if one matching the data in %$orgPtr 
              does not exist.

=cut

sub _getOrganismID {
  my($self, $orgPtr) = @_ ;
  my($sth, $orgID) ;
  my $dbh = $self->{dbh} ;
  
  if (defined $$orgPtr{subspecies}) {
    if (defined$$orgPtr{strain}) {
      $sth = $dbh->prepare( "select organismID from Organism 
                             where genusSpecies = ? 
                             and subspecies = ?  
                             and strain = ?" ) ;
      $sth->execute($$orgPtr{genusSpecies}, $$orgPtr{subspecies}, $$orgPtr{strain}) ;
      ( $orgID ) = $sth->fetchrow_array() ;
      $sth->finish() ;
    } else {
      $sth = $dbh->prepare( "select organismID from Organism 
                             where genusSpecies = ? 
                             and subspecies = ?" ) ;
      $sth->execute($$orgPtr{genusSpecies}, $$orgPtr{subspecies}) ;
      ( $orgID ) = $sth->fetchrow_array() ;
      $sth->finish() ;
    }
  } else {
    $sth = $dbh->prepare( "select organismID from Organism 
                           where genusSpecies = ?" ) ;
    $sth->execute($$orgPtr{genusSpecies}) ;
    ( $orgID ) = $sth->fetchrow_array() ;
    $sth->finish() ;
  }
  if ( ! defined $orgID) {
    # Create new Organism...
    $sth = $dbh->prepare( "insert into Organism 
                           (organismID, genusSpecies, subspecies, strain) 
                           values (?, ?, ?, ?)" ) ;
    $sth->execute(undef, $$orgPtr{genusSpecies}, $$orgPtr{subspecies}, $$orgPtr{strain}) ;
    $orgID = $sth->{'mysql_insertid'} ;
    $sth->finish() ;
  }

  return($orgID) ;
}

1;

__END__

