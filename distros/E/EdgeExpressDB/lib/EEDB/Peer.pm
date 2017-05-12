=head1 NAME - EEDB::Peer

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONTACT

Jessica Severin <severin@gsc.riken.jp>

=head1 LICENSE

 * Software License Agreement (BSD License)
 * EdgeExpressDB [eeDB] system
 * copyright (c) 2007-2009 Jessica Severin RIKEN OSC
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Jessica Severin RIKEN OSC nor the
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

my $__riken_EEDB_peer_global_should_cache = 1;
my $__riken_EEDB_peer_global_id_cache = {};

$VERSION = 0.953;

package EEDB::Peer;

use strict;
use Time::HiRes qw(time gettimeofday tv_interval);
use Data::UUID;

use MQdb::MappedQuery;
our @ISA = qw(MQdb::MappedQuery);

#################################################
# Class methods
#################################################

sub class { return "Peer"; }

sub set_cache_behaviour {
  my $class = shift;
  my $mode = shift;
  
  $__riken_EEDB_peer_global_should_cache = $mode;
  
  if(defined($mode) and ($mode eq '0')) {
    #if turning off caching, then flush the caches
    $__riken_EEDB_peer_global_id_cache = {};
  }
}

=head2 create_self_peer_for_db

  Description: used when creating a new instance of an eeDB database
  Returntype : EEDB::Peer
  Exceptions : none

=cut

sub create_self_peer_for_db {
  #used as part of new EEDB instance creation process.
  #each EEDB instance will have a peer entry for itself, this way when
  #other EEDB databases need to externally link to features they can use copy 
  #this self-peer entry to the remote database
  
  my $class = shift;
  my $db = shift; #required
  my $web_url = shift; #optional
  
  return undef unless($db);
  
  my $self = EEDB::Peer->fetch_by_alias($db, $db->dbname); #should return the self Peer
  if(!$self) {
    $self = new EEDB::Peer;
    $self->create_uuid;
    $self->alias($db->dbname);
    $self->db_url(sprintf("%s://read:read@%s:%s/%s", 
               $db->driver, 
               $db->host, 
               $db->port, 
               $db->dbname));
    if($web_url) { $self->web_url($web_url); }               
    $self->store($db);
    $db->execute_sql("UPDATE peer SET is_self=1 WHERE uuid=?", $self->id);
  }
  return $self;
}

#################################################
# Instance methods
#################################################

sub init {
  my $self = shift;
  my @args = @_;
  $self->SUPER::init(@args);
  return $self;
}

sub create_uuid {
  my $self = shift;
  
  my $ug    = new Data::UUID;
  my $uuid  = $ug->create();
  $self->primary_id($ug->to_string($uuid));
}


##########################
#
# getter/setter methods of data which is stored in database
#
##########################

sub uuid {
  my $self = shift;
  return $self->primary_id;
}

sub alias {
  my $self = shift;
  return $self->{'alias'} = shift if(@_);
  return $self->{'alias'};
}

sub db_url {
  my $self = shift;
  return $self->{'db_url'} = shift if(@_);
  return $self->{'db_url'};
}

sub web_url {
  my $self = shift;
  return $self->{'web_url'} = shift if(@_);
  return $self->{'web_url'};
}

sub display_desc {
  my $self = shift;
  my $str = sprintf("Peer(%s) %s ", $self->id, $self->alias);
  $str .= sprintf(" db::%s", $self->db_url) if($self->db_url);
  $str .= sprintf(" web::%s", $self->web_url) if($self->web_url);
}

sub xml {
  my $self = shift;
  my $str = sprintf("<peer uuid=\"%s\"  alias=\"%s\"", $self->id, $self->alias);
  $str .= sprintf(" db_url=\"%s\"", $self->db_url) if($self->db_url);
  $str .= sprintf(" web_url=\"%s\"", $self->web_url) if($self->web_url);
  
  $str .= " />\n";
  return $str;
}

##### URL follow section ##########


sub peer_database {
  my $self = shift;
  
  if(defined($self->db_url)) { 
    if(!defined($self->{'_peer_external_database'})) {
      my $db = MQdb::Database->new_from_url($self->db_url);
      $db->alias($self->alias);
      $db->uuid($self->uuid);
      $self->{'_peer_external_database'} = $db;
    }
    return $self->{'_peer_external_database'};
  }
  return $self->database; 
}


#################################################
#
# DBObject override methods
#
#################################################


sub mapRow {
  my $self = shift;
  my $rowHash = shift;
  my $dbc = shift;

  my $dbID = $rowHash->{'uuid'};
  if(($__riken_EEDB_peer_global_should_cache != 0) and ($self->database())) {
    my $cached_self = $__riken_EEDB_peer_global_id_cache->{$self->database() . $dbID};
    if(defined($cached_self)) { 
      #printf("link already loaded in cache, reuse\n");
      #$cached_self->display_info;
      #printf("   db_id :: %s\n", $cached_self->db_id);
      return $cached_self; 
    }
  }

  $self->primary_id($rowHash->{'uuid'});
  $self->alias($rowHash->{'alias'});
  $self->db_url($rowHash->{'db_url'}) if($rowHash->{'db_url'});
  $self->web_url($rowHash->{'web_url'}) if($rowHash->{'web_url'});
  
  if(($__riken_EEDB_peer_global_should_cache != 0) and ($self->database())) {
    $__riken_EEDB_peer_global_id_cache->{$self->database() . $self->id} = $self;
    $__riken_EEDB_peer_global_id_cache->{$self->database() . $self->alias} = $self;
  }

  return $self;
}

##### storage/update #####

sub store {
  my $self = shift;
  my $db   = shift;
  
  unless($db) { return undef; }  
  if(!defined($self->primary_id)) { $self->create_uuid; }
  
  $db->execute_sql("INSERT ignore INTO peer (uuid, alias, db_url, web_url) VALUES(?,?,?,?)",
                   $self->id, $self->alias, $self->db_url, $self->web_url);
  $self->database($db);
  return $self;
}



##### public class methods for fetching by utilizing DBObject framework methods #####

sub fetch_self_from_url {
  my $class = shift;
  my $url = shift;
  
  my $db = MQdb::Database->new_from_url($url);
  unless($db) { return undef; }
  
  my $sql = "SELECT * FROM peer WHERE is_self=1 and alias=?";
  return $class->fetch_single($db, $sql, $db->dbname);
}

sub fetch_by_uuid {
  my $class = shift;
  my $db = shift;
  my $id = shift;

  my $sql = "SELECT * FROM peer WHERE uuid=?";
  return $class->fetch_single($db, $sql, $id);
}

sub fetch_all {
  my $class = shift;
  my $db = shift;

  my $sql = "SELECT * FROM peer";
  return $class->fetch_multiple($db, $sql);
}

sub fetch_by_name {
  #a fuzzy method which allows either the UUID or alias to be 
  #used for access
  my $class = shift;
  my $db = shift;
  my $name = shift;

  my $sql = "SELECT * FROM peer WHERE uuid=? or alias=?";
  return $class->fetch_single($db, $sql, $name, $name);
}

sub fetch_by_alias {
  my $class = shift;
  my $db = shift;
  my $alias = shift;

  my $sql = "SELECT * FROM peer WHERE alias=?";
  return $class->fetch_single($db, $sql, $alias);
}



1;

