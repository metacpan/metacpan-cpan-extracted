=head1 NAME - EEDB::EdgeSource

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

my $__riken_gsc_edgesource_global_should_cache = 1;
my $__riken_gsc_edgesource_global_id_cache = {};
my $__riken_gsc_edgesource_global_name_cache = {};

$VERSION = 0.953;

package EEDB::EdgeSource;

use strict;
use Time::HiRes qw(time gettimeofday tv_interval);
use EEDB::Feature;
use EEDB::Peer;

use MQdb::MappedQuery;
our @ISA = qw(MQdb::MappedQuery);

#################################################
# Class methods
#################################################

sub class { return "EdgeSource"; }

sub set_cache_behaviour {
  my $class = shift;
  my $mode = shift;
  
  $__riken_gsc_edgesource_global_should_cache = $mode;
  
  if(defined($mode) and ($mode eq '0')) {
    #if turning off caching, then flush the caches
    $__riken_gsc_edgesource_global_id_cache = {};
    $__riken_gsc_edgesource_global_name_cache = {};
  }
}

sub create_from_name {
  #if $db parameter is supplied then it will check the database first
  #otherwise it will create one and store it (if $db is provided)
  my $class     = shift;
  my $esrc_name = shift;
  my $db        = shift; #optional
  
  if(!$esrc_name) { return undef; }
  
  my $category = undef;
  if($esrc_name =~ /(\w+)\:\:(.+)/) {
    $category = $1;
    $esrc_name = $2;
  }
  my $esrc = EEDB::EdgeSource->fetch_by_name($db, $esrc_name) if($db);
  unless($esrc){
    $esrc = new EEDB::EdgeSource;
    $esrc->name($esrc_name);
    $esrc->category($category);
    $esrc->store($db) if($db);
  }
  return $esrc;
}


#################################################
# Instance methods
#################################################

sub init {
  my $self = shift;
  $self->SUPER::init;
  return $self;
}

sub name {
  my $self = shift;
  return $self->{'name'} = shift if(@_);
  $self->{'name'}='' unless(defined($self->{'name'}));
  return $self->{'name'};
}

sub display_name {
  my $self = shift;
  return $self->{'display_name'} = shift if(@_);
  if(!defined($self->{'display_name'}) and defined($self->{'name'})) {
    return $self->{'name'};
  } else {
    return $self->{'display_name'};
  }
}

sub category {
  #like 'class', basically a high level controlled vocabulary of types
  #but not implemented as any constraint in the database.  Up to the data
  #user to control the vocabular prior to data import.  Not the DB's job to
  #babysit the vocabular checks
  my $self = shift;
  return $self->{'category'} = shift if(@_);
  $self->{'category'}='' unless(defined($self->{'category'}));
  return $self->{'category'};
}

sub uqname {
  my $self = shift;
  return sprintf("%s(%s)", $self->name, $self->id);
}

sub classification {
  my $self = shift;
  return $self->{'classification'} = shift if(@_);
  $self->{'classification'}='' unless(defined($self->{'classification'}));
  return $self->{'classification'};
}

sub create_date {
  my $self = shift;
  return $self->{'create_date'} = shift if(@_);
  $self->{'create_date'}='' unless(defined($self->{'create_date'}));
  return $self->{'create_date'};
}

sub is_active {
  my $self = shift;
  return $self->{'is_active'} = shift if(@_);
  $self->{'is_active'}='' unless(defined($self->{'is_active'}));
  return $self->{'is_active'};
}

sub is_visible {
  my $self = shift;
  return $self->{'is_visible'} = shift if(@_);
  $self->{'is_visible'}='' unless(defined($self->{'is_visible'}));
  return $self->{'is_visible'};
}

sub comments {
  my $self = shift;
  return $self->{'comments'} = shift if(@_);
  $self->{'comments'}='' unless(defined($self->{'comments'}));
  return $self->{'comments'};
}

################

sub db1_is_external {
  my $self = shift;  
  if(defined($self->{'_f1_ext_peer'})) { return 1;} else { return 0; }
}

sub db2_is_external {
  my $self = shift;  
  if(defined($self->{'_f2_ext_peer'})) { return 1;} else { return 0; }
}

sub peer1 {
  my $self = shift;
  my $peer = shift;
  
  if($peer) {
    unless(defined($peer) && $peer->isa('EEDB::Peer')) {
      die('peer1 param must be a EEDB::Peer');
    }
    $self->{'_peer1'} = $peer;
  }

  if(defined($self->{'_f1_ext_peer'})) { 
    if(!defined($self->{'_peer1'})) {
      $self->{'_peer1'} = EEDB::Peer->fetch_by_name($self->database, $self->{'_f1_ext_peer'});
    }
  }
  return $self->{'_peer1'};
}

sub peer2 {
  my $self = shift;
  my $peer = shift;
  
  if($peer) {
    unless(defined($peer) && $peer->isa('EEDB::Peer')) {
      die('peer2 param must be a EEDB::Peer');
    }
    $self->{'_peer2'} = $peer;
  }
  
  if(defined($self->{'_f2_ext_peer'})) { 
    if(!defined($self->{'_peer2'})) {
      $self->{'_peer2'} = EEDB::Peer->fetch_by_name($self->database, $self->{'_f2_ext_peer'});
    }
  }
  return $self->{'_peer2'};
}


sub database1 {
  my $self = shift;
  if($self->peer1) { return $self->peer1->peer_database; }
  else { return $self->database; }
}

sub database2 {
  my $self = shift;
  if($self->peer2) { return $self->peer2->peer_database; }
  else { return $self->database; }
}

################

sub get_edge_count {
  my $self = shift;
  
  if(!defined($self->database)) { return 0; }
  if(!defined($self->{'_edge_count'})) {
    my $sql = "SELECT count(*) FROM edge WHERE edge_source_id=?";
    $self->{'_edge_count'} = $self->fetch_col_value($self->database, $sql, $self->id);
  }
  return $self->{'_edge_count'};
}

################

sub metadataset {
  my $self = shift;
  
  if(!defined($self->{'metadataset'})) {
    $self->{'metadataset'} = new EEDB::MetadataSet;

    if($self->database) {
      my $symbols = EEDB::Symbol->fetch_all_by_edge_source_id($self->database, $self->id);
      $self->{'metadataset'}->add_metadata(@$symbols);

      my $mdata = EEDB::Metadata->fetch_all_by_edge_source_id($self->database, $self->id);
      $self->{'metadataset'}->add_metadata(@$mdata);
    }
  }
  return $self->{'metadataset'};
}

################

sub display_desc {
  my $self = shift;
  my $str = sprintf("EdgeSource(%s) %s : %s : %s",
           $self->id, 
           $self->name,
           $self->category,
           $self->classification
           );  
  return $str;
}

sub display_contents {
  my $self = shift;

  my $str = $self->display_desc;
  $str .= "\n". $self->metadataset->display_contents;   
  return $str;
}

sub xml {
  my $self = shift;
  my $str = $self->xml_start;
  $str .= "\n". $self->metadataset->xml;
  $str .= $self->xml_end;
  return $str;
}

sub xml_start {
  my $self = shift;
  my $str = sprintf("<edgesource id=\"%s\" name=\"%s\" classification=\"%s\" create_date=\"%s\" count=\"%d\"",
           $self->id, 
           $self->name,
           $self->classification,
           $self->create_date,
           $self->get_edge_count
           );
  $str .= sprintf(" category=\"%s\"", $self->category) if($self->category); 
  $str .= sprintf(" f1_federated=\"%s\"", $self->peer1->alias) if($self->db1_is_external); 
  $str .= sprintf(" f2_federated=\"%s\"", $self->peer2->alias) if($self->db2_is_external); 
  $str .= " >";
  return $str;
}

sub xml_end {
  my $self = shift;
  return "</edgesource>\n";
}

#################################################
#
# DBObject override methods
#
#################################################

sub check_exists_db {
  my $self = shift;
  my $db   = shift;
  
  unless($db) { return undef; }
  if(defined($self->primary_id)) { return $self; }
  
  #check if it is already in the database
  my $dbID = $db->fetch_col_value("SELECT edge_source_id FROM edge_source where name=?", $self->name);
  if($dbID) {
    $self->primary_id($dbID);
    $self->database($db);
    return $self;
  } else {
    return undef;
  }
}

sub store {
  my $self = shift;
  my $db   = shift;
  
  unless($db) { return undef; }  
  if($self->check_exists_db($db)) { return $self; }
  
  my $peer1_name = undef;
  my $peer2_name = undef;
  
  if($self->peer1) { $peer1_name = $self->peer1->alias; }
  if($self->peer2) { $peer2_name = $self->peer2->alias; }
  
  $db->execute_sql("INSERT ignore INTO edge_source ".
                   "(create_date, is_active, is_visible, name, display_name, category, classification, f1_ext_peer, f2_ext_peer) ".
                   "VALUES(NOW(),?,?,?,?,?,?,?,?)",
                    $self->is_active,
                    $self->is_visible,
                    $self->name,
                    $self->display_name,
                    $self->category,
                    $self->classification,
                    $peer1_name,
                    $peer2_name
                    );
                    
  $self->check_exists_db($db);  #checks the database and sets the primary_id

  #now do the symbols and metadata  
  $self->store_metadata;
                    
  return $self; 
}

sub store_metadata {
  my $self = shift;
  die("error no database to store metadata\n") unless($self->database);

  my $mdata_list = $self->metadataset->metadata_list;
  foreach my $mdata (@$mdata_list) {
    if(!defined($mdata->primary_id)) { 
      $mdata->store($self->database);
      $mdata->store_link_to_edge_source($self);
    }
  }
}

##### DBObject instance override methods #####

sub mapRow {
  my $self = shift;
  my $rowHash = shift;
  my $dbh = shift;
  
  $self->primary_id($rowHash->{'edge_source_id'});
  $self->name($rowHash->{'name'});
  $self->display_name($rowHash->{'display_name'});
  $self->category($rowHash->{'category'});
  $self->classification($rowHash->{'classification'});
  $self->create_date($rowHash->{'create_date'});
  $self->is_active($rowHash->{'is_active'});
  $self->is_visible($rowHash->{'is_visible'});
  
  $self->{'_f1_ext_peer'} = $rowHash->{'f1_ext_peer'};
  $self->{'_f2_ext_peer'} = $rowHash->{'f2_ext_peer'};
  

  if($__riken_gsc_edgesource_global_should_cache != 0) {
    if(defined($__riken_gsc_edgesource_global_id_cache->{$self->database() . $self->id})) {
      $self =  $__riken_gsc_edgesource_global_id_cache->{$self->database() . $self->id};
    } else {
      $__riken_gsc_edgesource_global_id_cache->{$self->database() . $self->id} = $self;
      $__riken_gsc_edgesource_global_name_cache->{$self->database() . $self->name} = $self;
    }
  }
  return $self;
}


##### public class methods for fetching by utilizing DBObject framework methods #####

sub fetch_all {
  my $class = shift;
  my $db = shift;
  my $sql = "SELECT * FROM edge_source";
  return $class->fetch_multiple($db, $sql);
}

sub fetch_by_id {
  my $class = shift;
  my $db = shift;
  my $id = shift;

  if($__riken_gsc_edgesource_global_should_cache != 0) {
    my $obj = $__riken_gsc_edgesource_global_id_cache->{$db . $id};
    if(defined($obj)) { return $obj; }
  }

  my $sql = "SELECT * FROM edge_source WHERE edge_source_id=?";
  return $class->fetch_single($db, $sql, $id);
}

sub fetch_by_name {
  my $class = shift;
  my $db = shift;
  my $name = shift;

  if($__riken_gsc_edgesource_global_should_cache != 0) {
    my $obj = $__riken_gsc_edgesource_global_name_cache->{$db . $name};
    if(defined($obj)) { return $obj; }
  }
  
  my $sql = "SELECT * FROM edge_source WHERE name=?";
  return $class->fetch_single($db, $sql, $name);
}

sub fetch_all_by_category {
  my $class = shift;
  my $db = shift;
  my $category = shift;

  my $sql = "SELECT * FROM edge_source WHERE category=?";
  return $class->fetch_multiple($db, $sql, $category);
}

1;

