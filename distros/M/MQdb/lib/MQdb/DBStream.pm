# $Id: DBStream.pm,v 1.15 2009/06/03 06:47:32 severin Exp $
=head1 NAME

MQdb::DBStream - DESCRIPTION of Object

=head1 SYNOPSIS

A simplified object to manage a collection of information related to streaming data from
a database.  at least with MYSQL, the perl driver does odd caching so to stream one
needs to create a new database connection in order to stream

=head1 DESCRIPTION

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

The rest of the documentation details each of the object methods. Internal methods are labeled.

=cut

my $__mqdb_dbstream_should_use_result = undef;

$VERSION=0.954;

package MQdb::DBStream;

use strict;
use MQdb::DBObject;
our @ISA = qw(MQdb::DBObject);


#################################################
# Class methods
#################################################

sub class { return "DBStream"; }

=head2 set_stream_useresult_behaviour

  Description  : sets a global behaviour for all DBStreams.  
                 setting use_result to "on" will leave the results on the database and
                 will keep the database connection open durring streaming.  
                 Both methods have similar speed performance, but keeping the results 
                 on the database server means the client uses essentially no memory.
                 The risk of turning this on is that the the database connection remains open
                 and there is risk of it timing out if processing takes a long time to stream all data.
                 When turned off, the entire result set is transfered in bulk to the driver (DBD::mysql)
                 and streaming happens from the underlying driver code and the perl code layer.
                 Default is "off" since this is safer but one risks needing lots of memory on the client.
  Parameter[1] : 1 or "y" or "on" turns the use_result on and keeps the database connection open
  Returntype   : none
  Exceptions   : none
  Example      : MQdb::DBStream->set_stream_useresult_behaviour(1);

=cut

sub set_stream_useresult_behaviour {
  my $class = shift;
  my $mode = shift;
  
  if(defined($mode) and (($mode == 1) or ($mode eq "y") or ($mode eq "on"))) {
    $__mqdb_dbstream_should_use_result = 1;
  } else {
    $__mqdb_dbstream_should_use_result = undef;
  }
  return $__mqdb_dbstream_should_use_result;
}

#################################################
# user API stream access methods
#################################################

=head2 next_in_stream

  Description: gets the next object in the stream. If the stream is empty it return undef.
  Returntype : instance of the defined DBStream::stream_class, or undef
  Exceptions : none
  Example    :  
                my $stream = WorldKit::Person->stream_all_by_country_region($db, "USA", "wisconsin");
                while(my $person = $stream->next_in_stream) { 
                  #do something
                }

=cut

sub next_in_stream {
  my $self = shift;
  
  return undef unless(defined($self->sth));
  
  my $class = $self->stream_class;
  my $sth = $self->sth;

  if(my $row_hash = $sth->fetchrow_hashref) {

    my $obj = $class->new();
    $obj = $obj->mapRow($row_hash);  #required by subclass
    $obj->database($self->database) if($obj);

    return $obj;
  }
  $sth->finish;
  $self->{'_stream_sth'} = undef;
  return undef;
}

=head2 as_array

  Description: instantiates all remaining instances in the stream and returns them as an array
  Returntype : reference to array of instances of the defined class of this stream
  Exceptions : none
  Example    :  
                my $stream = WorldKit::Person->stream_all_by_country_region($db, "USA", "wisconsin");
                my $all_people = $stream->as_array;  #because I have a large memory machine and need them all in memory
                foreach my $person (@$all_people) { 
                  #do something
                }

=cut

sub as_array {
  my $self = shift;
  my @array;
  while(my $obj = $self->next_in_stream) {
    push @array, $obj;
  }
  return \@array;
}


#################################################
# attribute methods
#################################################

sub init {
  my $self = shift;
  my %args = @_;
  $self->SUPER::init(@_);
  
  if($args{'db'}) { $self->database($args{'db'}); }
  if($args{'class'}) { $self->stream_class($args{'class'}); }
}

=head2 stream_database

  Description: this is an internal system method.  
               Needs to have two database connections open, one for the active
               stream handle, and one for lazy-loading additional data on the returned 
               objects.  This is used to set the database which is the one streaming objects
  Arg (1)    : $database (MQdb::Database) for setting
  Returntype : MQdb::Database
  Exceptions : none
  Callers    :  MQdb::MappedQuery

=cut


sub stream_database {
  my $self = shift;
  if($self->database and !defined($self->{'_stream_database'})) {
    $self->{'_stream_database'} = MQdb::Database->new_from_url($self->database->full_url); 
  }
  return $self->{'_stream_database'};
}

=head2 stream_class

  Description: this is an internal system method.  
               Set/get the class used for creation of objects on this stream.
               The class must be a subclass of MQdb::MappedQuery
  Arg (1)    : $class (must be subclass of MQdb::MappedQuery) for setting
  Returntype : a class which is a subclass of  MQdb::MappedQuery
  Exceptions : none
  Callers    :  MQdb::MappedQuery

=cut

sub stream_class {
  my $self = shift;
  return $self->{'_stream_class'} = shift if(@_);
  return $self->{'_stream_class'};
}

sub sth {
  my $self = shift;
  return $self->{'_stream_sth'};
}

#################################################
# stream prepare and access methods
#################################################

=head2 prepare

  Description: this is an internal system method.  It is used to set the SQL query used
               to stream objects out of a database.  Must be have stream_class() set
               to a subclass of MappedQuery which implements the mapRow() method.
  Returntype : $self
  Exceptions : none
  Callers    :  MQdb::MappedQuery

=cut

sub prepare {
  my $self = shift;
  my $sql = shift;
  my @params = @_;

  throw("no database defined\n") unless($self->stream_database);  
  my $dbc = $self->stream_database->get_connection;
  if($__mqdb_dbstream_should_use_result) {
    #keeps sth open and streams results from server
    $self->{'_stream_sth'} = $dbc->prepare($sql, { "mysql_use_result" => 1 });
  } else {
    #bulk transfers result to mysql driver and streams from driver cache 
    $self->{'_stream_sth'} = $dbc->prepare($sql); 
  }
  $self->{'_stream_sth'}->execute(@params);
  return $self;
}


1;





