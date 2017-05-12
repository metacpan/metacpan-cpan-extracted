# $Id: MappedQuery.pm,v 1.23 2009/06/03 06:47:32 severin Exp $
=head1 NAME

MQdb::MappedQuery - DESCRIPTION of Object

=head1 SYNOPSIS

An Object_relational_mapping (ORM) design pattern based on mapping 
named_column results from any query into attributes of an object.
As long as the column_names are parsable into attributes, any query is ok.
This is an evolution of several ideas I have either used or created over 
the last 15 years of coding.  This is a variation on the ActiveRecord design 
pattern but it trades more  flexibility, power and control for slightly 
less automation.  It still provides a development speed/ease advange 
over many ORM patterns.

=head1 DESCRIPTION

MappedQuery is an abstract superclass that is a variation on the
ActiveRecord design pattern.  Instead of actively mapping
a table into an object, this will actively map the result of
a query into an object.  The query is standardized for a subclass
of this object, and the columns returned by the query define
the attributes of the object.  This gives much more flexibility 
than the standard implementation of ActiveRecord.  Since this
design pattern is based around mapping a query (from potentially a
multiple table join) to a single class object, this pattern is
called MappedQuery.

In this particular implementation of this design pattern
(mainly due to some limitations in perl) several aspects
must be hand coded as part of the implementation of a 
subclass.  Subclasses must handcode
- all accessor methods
- override the mapRow method 
- APIs for all explicit fetch methods 
  (by using the superclass fetch_single and fetch_multiple)
- the store methods are coded by general DBI code (no framework assistance)

Individual MQdb::Database handle objects are assigned at an instance level
for each object. This is different from some ActiveRecord implementations 
which place database handles into a global context or at the Class level.
By placing it with each instance, this allows creation of instances of the
same class pulled from two different databases, but with similar schemas.
This is very useful when building certain types of data analysis systems.

The only restriction is that the database handle must be able run the 
queries that the object requires for it to work.

Future implementations could do more automatic code generation
but this version already speeds development time by 2x-3x
without imposing any limitations and retains all the flexibility
of handcoding with DBI.

=head1 CONTACT

Jessica Severin <jessica.severin@gmail.com>

=head1 LICENSE

 * Software License Agreement (BSD License)
 * MappedQueryDB [MQdb] toolkit
 * copyright (c) 2006-2009 Jessica Severin
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Jessica Severin nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ''AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut

$VERSION=0.954;

package MQdb::MappedQuery;

use strict;
use MQdb::Database;
use MQdb::DBStream;

use MQdb::DBObject;
our @ISA = qw(MQdb::DBObject);


#################################################
# Subclass must override these methods
#################################################

=head2 mapRow

  Description: This method must be overridden by subclasses to do the mapping of columns 
               from the query response into attributes of the object.  This is part of the
               internal factory machinery. The instance of the class is created before this method is
               called and the default init() method has already been called.  The purpose of this
               method is to initialize the rest of the state of the instance based on the $row_hash
  Arg (1)    : $row_hash perl hash 
  Arg (2)    : optional $dbc DBI connection (not generally used by most sublcasses)
  Returntype : $self
  Exceptions : none
  Caller     : only called by internal factory methods
  Example    :
                  sub mapRow {
                      my $self = shift;
                      my $rowHash = shift;
                      
                      $self->primary_id($rowHash->{'symbol_id'});
                      $self->type($rowHash->{'sym_type'});
                      $self->symbol($rowHash->{'sym_value'});
                      return $self;
                  }

=cut

sub mapRow {
  my $self = shift;
  my $row_hash = shift;
  my $dbc = shift; #optional 
  
  die("mapRow must be implemented by subclasses");
  #should by implemented by subclass to map columns into instance variables

  return $self;
}

=head2 store

  Description: This method is just an empty template as part of the API definition.
               How it is defined, and how parameters are handled are completely up to each
               subclass.  Each subclass should override and implement.
  Returntype : $self
  Exceptions : none
  Caller     : general loader scripts

=cut

sub store {
  my $self = shift;
  die("store must be implemented by subclass");
}

#################################################
# Factory methods
#################################################

=head2 fetch_single

  Description: General purpose template method for fetching a single instance
               of this class(subclass) using the mapRow method to convert
               a row of data into an object.
  Arg (1)    : $database (MQdb::Database)
  Arg (2)    : $sql (string of SQL statement with place holders)
  Arg (3...) : optional parameters to map to the placehodlers within the SQL
  Returntype : instance of this Class (subclass)
  Exceptions : none
  Caller     : subclasses (not public methods)
  Example    : 
                  sub fetch_by_id {
                      my $class = shift;
                      my $db = shift;
                      my $id = shift;
                      my $sql = "SELECT * FROM symbol WHERE symbol_id=?";
                      return $class->fetch_single($db, $sql, $id);
                  }


=cut

sub fetch_single {
  my $class = shift;
  my $db = shift;
  my $sql = shift;
  my @params = @_;

  die("no database defined\n") unless($db);
  my $dbc = $db->get_connection;
  my $sth = $dbc->prepare($sql, { ora_auto_lob => 0 });
  $sth->execute(@params);
  
  my $obj = undef;
  my $row_hash = $sth->fetchrow_hashref;
  if($row_hash) {
    $obj = $class->new();
    $obj->database($db);
    $obj = $obj->mapRow($row_hash, $dbc);  #required by subclass
  }
  
  $sth->finish;
  return $obj;
}


=head2 fetch_multiple

  Description: General purpose template method for fetching an array of instance
               of this class(subclass) using the mapRow method to convert
               a row of data into an object.
  Arg (1)    : $database (MQdb::Database)
  Arg (2)    : $sql (string of SQL statement with place holders)
  Arg (3...) : optional parameters to map to the placehodlers within the SQL
  Returntype : array of all instances of this Class (subclass) which match the query
  Exceptions : none
  Caller     : subclasses (not public methods)
  Example    : 
                  sub fetch_all_by_value {
                      my $class = shift;
                      my $db = shift;
                      my $name = shift;
                      my $sql = "SELECT * FROM symbol WHERE sym_value=?";
                      return $class->fetch_multiple($db, $sql, $name);
                  }

=cut

sub fetch_multiple {
  my $class = shift;
  my $db = shift;
  my $sql = shift;
  my @params = @_;

  die("no database defined\n") unless($db);
  my $obj_list = [];
  
  my $dbc = $db->get_connection;  
  my $sth = $dbc->prepare($sql, { ora_auto_lob => 0 });
  eval { $sth->execute(@params); };
  if($@) {
    printf("ERROR with query: %s\n", $sql);
    printf("          params: ");
    foreach my $param (@params) {
      print("'%s'  ", $param);
    }
    print("\n");
    die;
  }

  while(my $row_hash = $sth->fetchrow_hashref) {

    my $obj = $class->new();
    $obj->database($db);
    $obj = $obj->mapRow($row_hash, $dbc);  #required by subclass

    push @$obj_list, $obj;
  }
  $sth->finish;
  return $obj_list;
}


=head2 stream_multiple

  Description: General purpose template method for fetching multiple instance
               of this class(subclass) using the mapRow method to convert
               a row of data into an object. Instead of instantiating all
               instance at once and returning as array, this method returns
               a DBStream instance which then creates each instance from an
               open handle on each $stream->next_in_stream() call.
  Arg (1)    : $database (MQdb::Database)
  Arg (2)    : $sql (string of SQL statement with place holders)
  Arg (3...) : optional parameters to map to the placehodlers within the SQL
  Returntype : DBStream object
  Exceptions : none
  Caller     : subclasses use this internally when creating new API stream_by....() methods
  Example    :
                  sub stream_by_value {
                      my $class = shift;
                      my $db = shift;
                      my $name = shift;
                      my $sql = "SELECT * FROM symbol WHERE sym_value=?";
                      return $class->stream_multiple($db, $sql, $name);
                  }
                  
=cut

sub stream_multiple {
  my $class = shift;
  my $db = shift;
  my $sql = shift;
  my @params = @_;

  die("no database defined\n") unless($db);
  
  my $stream = new MQdb::DBStream(db=>$db, class=>$class);
  $stream->prepare($sql, @params);
  return $stream;
}


=head2 fetch_col_value

  Description: General purpose function to allow fetching of a single column from a single row.
  Arg (1)    : $sql (string of SQL statement with place holders)
  Arg (2...) : optional parameters to map to the placehodlers within the SQL
  Example    : $value = $self->fetch_col_value($db, 
                                               "select symbol_id from symbol where sym_type=? and sym_value=?", 
                                               $type,$value);
  Returntype : scalar value
  Exceptions : none
  Caller     : within subclasses to easy development

=cut

sub fetch_col_value {
  my $class = shift;
  my $db = shift;
  my $sql = shift;
  my @params = @_;

  die("no database defined\n") unless($db);
  my $dbc = $db->get_connection;
  my $sth = $dbc->prepare($sql);
  $sth->execute(@params);
  my ($value) = $sth->fetchrow_array();
  $sth->finish;
  return $value;
}


=head2 fetch_col_array

  Description: General purpose function to allow fetching of a single column from many rows into a simple array.
  Arg (1)    : $sql (string of SQL statement with place holders)
  Arg (2...) : optional parameters to map to the placehodlers within the SQL
  Example    : $array_ref = $self->fetch_col_array($db, "select some_column from my_table where source_id=?", $id);
  Returntype : array reference of scalar values
  Exceptions : none
  Caller     : within subclasses to easy development

=cut

sub fetch_col_array {
  my $class = shift;
  my $db = shift;
  my $sql = shift;
  my @params = @_;

  my @col_array=();
  
  die("no database defined\n") unless($db);
  my $dbc = $db->get_connection;
  my $sth = $dbc->prepare($sql);
  $sth->execute(@params);
  
  while(my ($value) = $sth->fetchrow_array()) {
    push @col_array, $value;
  }
  $sth->finish;
  return \@col_array;
}


=head2 next_sequence_id

  Description: Convenience method for working with SEQUENCES in ORACLE databases.
  Arg (1)    : $sequenceName
  Returntype : scalar of the nextval in the sequence
  Exceptions : none

=cut

sub next_sequence_id {
  my $self = shift;
  my $sequenceName = shift;
  
  my $dbh = $self->database->get_connection;
  
  my $sql = 'select '. $sequenceName . '.nextval from sys.dual';  
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  my ($dbID) = $sth->fetchrow_array();
  $sth->finish;
  #printf("incremented sequence $sequenceName id:%d\n", $dbID);
  
  return $dbID;
}




1;





