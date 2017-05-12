# $Id: DBObject.pm,v 1.13 2009/06/03 06:47:32 severin Exp $
=head1 NAME

MQdb::DBObject - DESCRIPTION of Object

=head1 SYNOPSIS

Root class for all objects in MappedQuery toolkit

=head1 DESCRIPTION

Root object for toolkit and all derived subclasses. 
All objects in the MappedQuery structure are designed to 
be persisted in a database. Here database is a more broad
term and can be considered any object persistance systems.
Currently the toolkit works with SQL based systems but 
object databases or custom storage engines are possible.
Provides base common methods used by all objects. 

=head1 AUTHOR

Contact Jessica Severin: jessica.severin@gmail.com

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

The rest of the documentation details each of the object methods. 
Internal methods are usually preceded with a _

=cut

$VERSION=0.954;

package MQdb::DBObject;

use strict;
use MQdb::Database;

#################################################
# Factory methods
#################################################

=head2 new

  Description: instance creation method
  Returntype : instance of this Class (subclass)
  Exceptions : none

=cut

sub new {
  my ($class, @args) = @_;
  my $self = {};
  bless $self,$class;
  $self->init(@args);
  
  #my $idx = rindex $class, "::";
  #$self->{'_class'} = substr($class, $idx+2);
  return $self;
}

=head2 init

  Description: initialization method which subclasses can extend
  Returntype : $self
  Exceptions : subclass dependent

=cut

sub init {
  my $self = shift;
  #internal variables minimal allocation
  $self->{'_primary_db_id'} = undef;  
  $self->{'_database'} = undef;
  return $self;
}

=head2 copy

  Description: Shallow copy which copies all base attributes of object 
               to new instance of same class
  Returntype : same as calling instance
  Exceptions : subclass dependent

=cut

sub copy {
  my $self = shift;
  my $class = ref($self);
  my $copy = $class->new;
  foreach my $key (keys %{$self}) {
    $copy->{$key} = $self->{$key};
  }
  #print('self = ', $self, "\n");
  #print('copy = ', $copy, "\n");

  return $copy;
}

sub DESTROY {
  my $self = shift;
  #If I need to do any cleanup - do it here
  $self->SUPER::DESTROY if $self->can("SUPER::DESTROY");
}

#################################################
# Instance methods
#################################################

=head2 class

  Description: fixed string symbol for this class. Must be implemented 
               for each subclass and each subclass within toolkit 
               should return a unique name. used by global  methods.
  Returntype : string
  Exceptions : error if subclass does not redefine

=cut

sub class {
  my $self = shift;
  printf("ERROR:: DBObject subclass needs to implement class() method\n");
  die();
}

=head2 database

  Description: the MQdb::Database where this object is permanently persisted to.
               Here database is any object persistance system.
  Returntype : MQdb::Database
  Exceptions : die if invalid setter value type is provided 

=cut

sub database {
  my $self = shift;
  if(@_) {
    my $db = shift;
    $self->{'_database'} = $db;
  }
  return $self->{'_database'};
}

=head2 primary_id

  Description: the unique identifier for this object within database.
  Returntype : scalar or UNDEF
  Exceptions : none

=cut

sub primary_id {
  my $self = shift;
  $self->{'_primary_db_id'} = shift if @_;
  return $self->{'_primary_db_id'};
}

=head2 id

  Description: the unique identifier for this object within database.
               Returns empty string if not persisted.
  Returntype : scalar or ''
  Exceptions : none

=cut

sub id {
  my $self = shift;
  $self->{'_primary_db_id'} = shift if @_;
  if(!defined($self->{'_primary_db_id'})) { return ''; }
  return $self->{'_primary_db_id'}; 
}

=head2 db_id

  Description: the worldwide unique identifier for this object.
               A URL-like combination of database, class, and id
  Returntype : string or undef if database is not defined
  Exceptions : none

=cut

sub db_id {
  my $self = shift;
  return $self->{'_db_id'} if(defined($self->{'_db_id'}));
  return undef unless($self->database);
  if($self->database->uuid) {
    $self->{'_db_id'} = $self->database->uuid . "::" . $self->primary_id . ":::" . $self->class;
  } else {
    $self->{'_db_id'} = 
      sprintf("%s://%s:%s/%s/%s?id=%d",
               $self->database->driver, 
               $self->database->host, 
               $self->database->port, 
               $self->database->dbname,
               $self->class,
               $self->primary_id);
  }
  return $self->{'_db_id'};
}


=head2 display_desc

  Description: general purpose debugging method that returns a nice
               human readable description of the object instance contents.
               Each subclass should implement and return a nice string.
  Returntype : string scalar 
  Exceptions : none

=cut

sub display_desc {
  my $self = shift;
  return $self;  #return object identifier for printing
}

=head2 display_info

  Description: convenience method which prints the display_desc string
               with a carriage return to STDOUT. useful for debugging.
  Returntype : none
  Exceptions : none

=cut

sub display_info {
  my $self = shift;
  printf("%s\n", $self->display_desc);
}

=head2 xml

  Description: every object in system should be persistable in XML format.
               returns an XML description of the object and all child objects.
               Each subclass must implement and return a proper XML string.
               Best if one implements xml_start() and xml_end() and use here.
  Returntype : string scalar 
  Exceptions : none 
  Default    : default is a simple xml_start + xml_end 

=cut

sub xml {
  my $self = shift;
  return $self->xml_start() . $self->xml_end();
}

=head2 xml_start

  Description: every object in system should be persistable in XML format.
               returns an XML description of the object and all child objects.
               Each subclass should OVERRIDE this method and return a proper XML string.
               xml_start is the primary XML start tag
  Example    : return sprintf("<feature id='%d' name='%d' ..... >", $id, $name....);
  Returntype : string scalar 
  Exceptions : none 

=cut

sub xml_start {
  my $self = shift;
  return '';
}


=head2 xml_end

  Description: every object in system should be persistable in XML format.
               returns an XML description of the object and all child objects.
               Each subclass should OVERRIDE this method and return a proper XML string.
               xml_end is the primary XML end tag 
  Example    : return "</feature>";
  Returntype : string scalar 
  Exceptions : none 

=cut

sub xml_end {
  my $self = shift;
  return '';
}

=head2 simple_xml

  Description: short hand for xml_start() . xml_end()
               Can be used when only the primary XML start tag and attributes are needed
               No need to override if xml_start() and xml_end() are implemented
  Returntype : string scalar 
  Exceptions : none

=cut

sub simple_xml {
  my $self = shift;
  return $self->xml_start() . $self->xml_end();
}

1;




