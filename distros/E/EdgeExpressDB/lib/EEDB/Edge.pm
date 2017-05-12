=head1 NAME - EEDB::Edge

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

my $__riken_EEDB_edge_global_should_cache = 0;
my $__riken_EEDB_edge_global_id_cache = {};
my $__riken_EEDB_edge_global_featureid_cache = {};

$VERSION = 0.953;

package EEDB::Edge;

use strict;
use Time::HiRes qw(time gettimeofday tv_interval);
use EEDB::Feature;
use EEDB::EdgeSource;
use EEDB::MetadataSet;

use MQdb::MappedQuery;
our @ISA = qw(MQdb::MappedQuery);

#################################################
# Class methods
#################################################

sub class { return "Edge"; }

sub set_cache_behaviour {
  my $class = shift;
  my $mode = shift;
  
  $__riken_EEDB_edge_global_should_cache = $mode;
  
  if(defined($mode) and ($mode eq '0')) {
    #if turning off caching, then flush the caches
    $__riken_EEDB_edge_global_id_cache = {};
    $__riken_EEDB_edge_global_featureid_cache = {};
  }
}

sub get_cache_size {
  return scalar(keys(%$__riken_EEDB_edge_global_id_cache));
}


#################################################
# Instance methods
#################################################

sub init {
  my $self = shift;
  $self->SUPER::init;
  
  return $self;
}

sub feature1_id {
  my $self = shift;
  return $self->{'feature1_id'};
}
sub feature2_id {
  my $self = shift;
  return $self->{'feature2_id'};
}

sub fed_feature1_id {
  my $self = shift;
  my $fid = $self->feature1_id;
  if($self->edge_source->db1_is_external) { $fid = $self->edge_source->peer1->alias . "::" . $self->feature1_id;  }
  return $fid;
}

sub fed_feature2_id {
  my $self = shift;
  my $fid = $self->feature2_id;
  if($self->edge_source->db2_is_external) { $fid = $self->edge_source->peer2->alias . "::" . $self->feature2_id;  }
  return $fid;
}

sub feature1 {
  my ($self, $feature) = @_;
  if($feature) {
    unless(defined($feature) && $feature->isa('EEDB::Feature')) {
      die('feature1 param must be a EEDB::Feature');
    }
    $self->{'feature1'} = $feature;
    $self->{'feature1_id'} = $feature->id;
  }
  
  #lazy load from database if possible
  if(!defined($self->{'feature1'}) and 
     defined($self->database) and 
     defined($self->{'feature1_id'}))
  {
    #printf("LAZY LOAD chrom_id=%d\n", $self->{'_chrom_id'});
    my $feature = EEDB::Feature->fetch_by_id($self->edge_source->database1, $self->{'feature1_id'});
    if(defined($feature)) { $self->{'feature1'} = $feature; }
  }
  return $self->{'feature1'};
}


sub feature2 {
  my ($self, $feature) = @_;
  if($feature) {
    unless(defined($feature) && $feature->isa('EEDB::Feature')) {
      die('feature2 param must be a EEDB::Feature');
    }
    $self->{'feature2'} = $feature;
    $self->{'feature2_id'} = $feature->id;
  }
  
  #lazy load from database if possible
  if(!defined($self->{'feature2'}) and 
     defined($self->database) and 
     defined($self->{'feature2_id'}))
  {
    #printf("LAZY LOAD chrom_id=%d\n", $self->{'_chrom_id'});
    my $feature = EEDB::Feature->fetch_by_id($self->edge_source->database2, $self->{'feature2_id'});
    if(defined($feature)) { $self->{'feature2'} = $feature; }
  }
  return $self->{'feature2'};
}


sub edge_source {
  my ($self, $source) = @_;
  if($source) {
    unless(defined($source) && $source->isa('EEDB::EdgeSource')) {
      die('edge_source param must be a EEDB::EdgeSource');
    }
    $self->{'edge_source'} = $source;
  }
  
  #lazy load from database if possible
  if(!defined($self->{'edge_source'}) and 
     defined($self->database) and 
     defined($self->{'edge_source_id'}))
  {
    #printf("LAZY LOAD chrom_id=%d\n", $self->{'_chrom_id'});
    my $source = EEDB::EdgeSource->fetch_by_id($self->database, $self->{'edge_source_id'});
    if(defined($source)) { 
      $self->{'edge_source'} = $source; 
      $self->{'edge_source_id'} = undef; 
    }
  }
  return $self->{'edge_source'};
}


sub sub_type {
  my $self = shift;
  return $self->{'sub_type'} = shift if(@_);
  $self->{'sub_type'}='' unless(defined($self->{'sub_type'}));
  return $self->{'sub_type'};
}

sub direction {
  my $self = shift;
  return $self->{'direction'} = shift if(@_);
  $self->{'direction'}='' unless(defined($self->{'direction'}));
  return $self->{'direction'};
}

sub weight {
  my $self = shift;
  return $self->{'weight'} = shift if(@_);
  $self->{'weight'}=0.0 unless(defined($self->{'weight'}));
  return $self->{'weight'};
}
##################

sub metadataset {
  my $self = shift;
  
  if(!defined($self->{'metadataset'})) {
    $self->{'metadataset'} = new EEDB::MetadataSet;

    if($self->database) {
      my $symbols = EEDB::Symbol->fetch_all_by_edge_id($self->database, $self->id);
      $self->{'metadataset'}->add_metadata(@$symbols);

      my $mdata = EEDB::Metadata->fetch_all_by_edge_id($self->database, $self->id);
      $self->{'metadataset'}->add_metadata(@$mdata);
    }
  }
  return $self->{'metadataset'};
}

################

sub display_desc {
  my $self = shift;
  my $str = sprintf("Edge(%s) %s(%s) => %s(%s) : %f %s",
           $self->id, 
           $self->feature1->primary_name,
           $self->feature1->id,
           $self->feature2->primary_name,
           $self->feature2->id,
           $self->weight,
           $self->edge_source->uqname
           );  
  my $mdata_list = $self->metadataset->metadata_list;
  my $first=1;
  if(defined($mdata_list) and (scalar(@$mdata_list))) {
    $str .= ' (';
    foreach my $mdata (@$mdata_list) {
      if($first) { $first=0; }
      else { $str .= ','; }
      $str .= sprintf("(%s,\"%s\")", $mdata->type, $mdata->data);
    }
    $str .= ')';
  }  
  return $str;
}


sub display_contents {
  my $self = shift;
  my $str = sprintf("Edge(%s) %s(%s) => %s(%s) : %f %s",
           $self->id, 
           $self->feature1->primary_name,
           $self->feature1->id,
           $self->feature2->primary_name,
           $self->feature2->id,
           $self->weight,
           $self->edge_source->uqname
           );  
  $str .= "\n". $self->metadataset->display_contents;   
  return $str;
}


sub xml {
  my $self = shift;
  
  my $str = sprintf("<edge source=\"%s\" weight=\"%f\" dir=\"%s\" eid=\"%s\">\n",
           $self->edge_source->uqname,
           $self->weight,
           $self->direction,
           $self->id
           );
           
  my $feature1 = $self->feature1;
  $str .= sprintf("  <feature1 id=\"%s\" name=\"%s\" source=\"%s\" category=\"%s\" ",
                    $self->fed_feature1_id,
                    $feature1->primary_name,
                    $feature1->feature_source->name,
                    $feature1->feature_source->category);
  if($feature1->chrom) { $str .= sprintf("loc=\"%s\" ", $feature1->chrom_location); }
  $str .= "/>\n";
  
  my $feature2 = $self->feature2;
  $str .= sprintf("  <feature2 id=\"%s\" name=\"%s\" source=\"%s\" category=\"%s\" ",
                    $self->fed_feature2_id,
                    $feature2->primary_name,
                    $feature2->feature_source->name,
                    $feature2->feature_source->category);
  if($feature2->chrom) { $str .= sprintf("loc=\"%s\" ", $feature2->chrom_location); }
  $str .= "/>\n";

  $str .= $self->metadataset->xml;
           
  $str .= "</edge>\n";
  return $str;
}

sub simple_xml {
  my $self = shift;
  my $str = sprintf("<edge source=\"%s\" f1id=\"%d\" f2id=\"%d\" name1=\"%s\" name2=\"%s\" weight=\"%f\" dir=\"%s\" edge_id=\"%s\" />",
           $self->edge_source->uqname,
           $self->feature1_id,
           $self->feature2_id,
           $self->feature1->primary_name,
           $self->feature2->primary_name,
           $self->weight,
           $self->direction,
           $self->id
           );
  return $str;
}

#######################

sub get_neighbor {
  my $self = shift;
  my $feature = shift;

  my $dir = "";
  my $neighbor = undef;

  if($self->feature1_id == $feature->id) {
    $dir = "link_to";
    $neighbor = $self->feature2;
  } elsif($self->feature2_id == $feature->id) {
    $dir = "link_from";
    $neighbor = $self->feature1;
  } elsif($self->feature1_id == $self->feature2_id) {
    $dir = "link_self";
    $neighbor = $self->feature1;
  }
  return ($dir, $neighbor);
}


#################################################
#
# DBObject override methods
#
#################################################

sub store {
  my $self = shift;
  my $db   = shift;
  
  if($db) { $self->database($db); }
  my $dbh = $self->database->get_connection;  
  my $sql = "INSERT ignore INTO edge (
                feature1_id,
                feature2_id,
                sub_type,
                direction,
                edge_source_id,
                weight
                )
             VALUES(?,?,?,?,?,?)";
  my $sth = $dbh->prepare($sql);
  $sth->execute($self->feature1->id,
                $self->feature2->id,
                $self->sub_type,
                $self->direction,
                $self->edge_source->id,
                $self->weight);

  my $dbID = $sth->{'mysql_insertid'};
  #my $dbID = $dbh->last_insert_id(undef, undef, qw(edge edge_id));
  $sth->finish;
  $self->primary_id($dbID);

  return $self;
}

sub store_metadata {
  my $self = shift;
  die("error no database to store metadata\n") unless($self->database);

  my $mdata_list = $self->metadataset->metadata_list;
  foreach my $mdata (@$mdata_list) {
    if(!defined($mdata->primary_id)) { 
      $mdata->store($self->database);
      $mdata->store_link_to_feature_link($self);
    }
  }
}

sub check_exists_db {
  my $self = shift;
  
  unless($self->edge_source) { return undef; }
  unless($self->edge_source->database) { return undef; }
  if(defined($self->primary_id)) { return $self; }
  
  #check if it is already in the database
  my $dbc = $self->edge_source->database->get_connection;  
  my $sth = $dbc->prepare("SELECT edge_id FROM edge where feature1_id=? and feature2_id=? and edge_source_id=?");
  $sth->execute($self->feature1->id, $self->feature2->id, $self->edge_source->id);
  my ($edge_id) = $sth->fetchrow_array();
  $sth->finish;
  
  if($edge_id) {
    $self->primary_id($edge_id);
    $self->database($self->edge_source->database);
    return $self;
  } else {
    return undef;
  }
}

##### DBObject instance override methods #####

sub mapRow {
  my $self = shift;
  my $rowHash = shift;
  my $dbh = shift;

  my $dbID = $rowHash->{'edge_id'};
  if($__riken_EEDB_edge_global_should_cache != 0) {
    my $cached_self = $__riken_EEDB_edge_global_id_cache->{$self->database() . $dbID};
    if(defined($cached_self)) { 
      #printf("link already loaded in cache, reuse\n");
      #$cached_self->display_info;
      #printf("   db_id :: %s\n", $cached_self->db_id);
      return $cached_self; 
    }
  }

  $self->primary_id($rowHash->{'edge_id'});
  $self->direction($rowHash->{'direction'});
  $self->sub_type($rowHash->{'sub_type'});
  $self->weight($rowHash->{'weight'});

  $self->{'feature1_id'} = $rowHash->{'feature1_id'};
  $self->{'feature2_id'} = $rowHash->{'feature2_id'};
  $self->{'edge_source_id'} = $rowHash->{'edge_source_id'};

  if($__riken_EEDB_edge_global_should_cache != 0) {
    #first do the edge_id caching
    $__riken_EEDB_edge_global_id_cache->{$self->database() . $self->id} = $self;

    #then do the feature->[array of edges] caching
    my $center_id = $rowHash->{'center_id'};
    if(defined($center_id)) {
      my $link_hash = $__riken_EEDB_edge_global_featureid_cache;
      
      if(!defined($link_hash->{$self->database() . $center_id})) { 
        $link_hash->{$self->database() . $center_id} = {$self->id => $self};
      } else {
        $link_hash->{$self->database() . $center_id}->{$self->id} = $self;
      }
    }
  }

  return $self;
}


##### public class methods for fetching by utilizing DBObject framework methods #####

sub fetch_by_id {
  my $class = shift;
  my $db = shift;
  my $id = shift;

  if($__riken_EEDB_edge_global_should_cache != 0) {
    my $edge = $__riken_EEDB_edge_global_id_cache->{$db . $id};
    if(defined($edge)) { return $edge; }
  }

  my $sql = "SELECT * FROM edge WHERE edge_id=?";
  return $class->fetch_single($db, $sql, $id);
}

sub fetch_all_by_source {
  my $class = shift;
  my $db = shift;
  my $link_source = shift; #EdgeSource object

  my $sql = "SELECT * FROM edge WHERE edge_source_id=?";
  return $class->fetch_multiple($db, $sql, $link_source->id);
}

sub stream_all_by_source {
  my $class = shift;
  my $source = shift; #EdgeSource object with database connection
  my $sort = shift; #optional flag for sorting
  
  return undef unless($source and $source->database);

  my $sql = "SELECT * FROM edge WHERE edge_source_id=? ";
  if(defined($sort) and ($sort eq 'f1')) { $sql .= "ORDER by feature1_id "; }
  if(defined($sort) and ($sort eq 'f2')) { $sql .= "ORDER by feature2_id "; }
  return $class->stream_multiple($source->database, $sql, $source->id);
}

sub fetch_all_from_sourceid_list {
  my $class = shift;
  my $db = shift;
  my $source_ids = shift;

  my $sql = sprintf("SELECT * FROM edge WHERE edge_source_id in (%s)", $source_ids);
  return $class->fetch_multiple($db, $sql);
}

sub fetch_all_from_feature_id {
  my $class = shift;
  my $db = shift;
  my $id = shift;
  my $edge_source_ids = shift; #optional
  
  my $sql = sprintf("SELECT * FROM edge fl JOIN edge_source using(edge_source_id) WHERE is_active='y' AND feature1_id='%s' ", $id);
  if(defined($edge_source_ids)) {
    $sql .= sprintf("AND fl.edge_source_id in(%s)", $edge_source_ids);
  }  
  return $class->fetch_multiple($db, $sql);
}

sub fetch_all_to_feature_id {
  my $class = shift;
  my $db = shift;
  my $id = shift;
  my $edge_source_ids = shift; #optional

  my $sql = sprintf("SELECT fl.* FROM edge fl JOIN edge_source using(edge_source_id) WHERE is_active='y' AND feature2_id='%s' ", $id);
  if(defined($edge_source_ids)) {
    $sql .= sprintf("AND fl.edge_source_id in(%s)", $edge_source_ids);
  }  
  return $class->fetch_multiple($db, $sql);
}

sub fetch_all_with_feature {
  my $class = shift;
  my $feature = shift;
  my %options = @_; #like category=>"subfeature", sources=>[$esrc1, $esrc2,$esrc3]
  
  unless(defined($feature) && $feature->isa('EEDB::Feature')) {
    die('fetch_all_with_feature param1 must be a EEDB::Feature');
  }
  my $list1 = $class->fetch_all_with_feature1($feature, %options);
  my $list2 = $class->fetch_all_with_feature2($feature, %options);
  my @rtnlist = (@$list1, @$list2);
  return \@rtnlist;
}

sub fetch_all_with_feature1 {
  my $class = shift;
  my $feature1 = shift;
  my %options = @_; #like category=>"subfeature", sources=>[$esrc1, $esrc2,$esrc3]
  
  unless(defined($feature1) && $feature1->isa('EEDB::Feature')) {
    die('fetch_all_with_feature1 param1 must be a EEDB::Feature');
  }
  
  my $sql = "SELECT * FROM edge fl JOIN edge_source using(edge_source_id) WHERE feature1_id=? ";
  if(%options) {
    if($options{'category'}) {
      $sql .= sprintf(" AND category='%s'", $options{'category'});
    }
    if($options{'sources'}) {
      my @lsrc_ids;
      foreach my $lsrc (@{$options{'sources'}}) { push @lsrc_ids, $lsrc->id; }
      $sql .= sprintf(" AND fl.edge_source_id in(%s)", join(',', @lsrc_ids));
    }
  }  
  return $class->fetch_multiple($feature1->database, $sql, $feature1->id);
}

sub fetch_all_with_feature2 {
  my $class = shift;
  my $feature2 = shift;
  my %options = @_; #like category=>"subfeature", sources=>[$esrc1, $esrc2,$esrc3]
  
  unless(defined($feature2) && $feature2->isa('EEDB::Feature')) {
    die('fetch_all_with_feature2 param1 must be a EEDB::Feature');
  }

  my $sql = "SELECT * FROM edge fl JOIN edge_source using(edge_source_id) WHERE feature2_id= ?";
  if(%options) {
    if($options{'category'}) {
      $sql .= sprintf(" AND category='%s'", $options{'category'});
    }
    if($options{'sources'}) {
      my @lsrc_ids;
      foreach my $lsrc (@{$options{'sources'}}) { push @lsrc_ids, $lsrc->id; }
      $sql .= sprintf(" AND fl.edge_source_id in(%s)", join(',', @lsrc_ids));
    }
  }  
  return $class->fetch_multiple($feature2->database, $sql, $feature2->id);
}

sub fetch_all_with_feature_id {
  my $class = shift;
  my $db = shift;
  my $id = shift;
  my $edge_source_ids = shift; #optional

  my $sql = sprintf("SELECT %s center_id, fl.* FROM edge fl WHERE (feature1_id='%s' OR feature2_id='%s') ", $id, $id, $id);
  if(defined($edge_source_ids)) {
    $sql .= sprintf("AND fl.edge_source_id in (%s)", $edge_source_ids);
  }
  return $class->fetch_multiple($db, $sql);
}

sub fetch_all_visible_with_feature_id {
  my $class = shift;
  my $db = shift;
  my $id = shift;
  my $edge_source_ids = shift; #optional

  if($__riken_EEDB_edge_global_should_cache != 0) {
    my $edge_hash = $__riken_EEDB_edge_global_featureid_cache->{$db . $id};
    if(defined($edge_hash)) { 
      my @edges = values(%$edge_hash);
      return \@edges; 
    }
  }

  my $sql = sprintf("SELECT %s center_id, fl.* FROM edge fl JOIN edge_source using(edge_source_id) WHERE is_visible ='y' AND(feature1_id='%s' OR feature2_id='%s') ", $id, $id, $id);
  if(defined($edge_source_ids)) {
    $sql .= sprintf("AND fl.edge_source_id in (%s)", $edge_source_ids);
  }
  return $class->fetch_multiple($db, $sql);
}

sub fetch_all_active_with_feature_id {
  my $class = shift;
  my $db = shift;
  my $id = shift;

  my $sql = sprintf("SELECT fl.* FROM edge fl JOIN edge_source using(edge_source_id) ".
                    "WHERE is_active ='y' AND(feature1_id='%s' OR feature2_id='%s') ", $id, $id);
  return $class->fetch_multiple($db, $sql);
}

sub fetch_all_visible_with_feature_id_list {
  my $class = shift;
  my $db = shift;
  my $id_list = shift;

  my $sql = sprintf("SELECT fl.* FROM edge fl JOIN edge_source using(edge_source_id) ".
                    "WHERE is_visible ='y' AND feature1_id in(%s) AND feature2_id in(%s)", $id_list, $id_list);
  return $class->fetch_multiple($db, $sql);
}

sub fetch_all_active_with_feature_id_list {
  my $class = shift;
  my $db = shift;
  my $id_list = shift;

  my $sql = sprintf("SELECT fl.* FROM edge fl JOIN edge_source using(edge_source_id) ".
                    "WHERE is_active ='y' AND feature1_id in(%s) AND feature2_id in(%s)", $id_list, $id_list);
  return $class->fetch_multiple($db, $sql);
}

sub fetch_all_visible_between_feature_id_list {
  my $class = shift;
  my $db = shift;
  my $id_list = shift;

  my $sql = sprintf("SELECT fl.* FROM edge fl JOIN edge_source using(edge_source_id) ".
                    "WHERE is_visible ='y' AND feature1_id in(%s) AND feature2_id in(%s)", $id_list, $id_list);
  return $class->fetch_multiple($db, $sql);
}

sub fetch_all_active_between_feature_id_list {
  my $class = shift;
  my $db = shift;
  my $id_list = shift;

  my $sql = sprintf("SELECT fl.* FROM edge fl JOIN edge_source using(edge_source_id) ".
                    "WHERE is_active ='y' AND feature1_id in(%s) AND feature2_id in(%s)", $id_list, $id_list);
  return $class->fetch_multiple($db, $sql);
}

sub fetch_all_active_expand_from_feature_id_list {
  my $class = shift;
  my $db = shift;
  my $id_list = shift;

  my $sql = sprintf("SELECT fl.* FROM edge fl JOIN edge_source using(edge_source_id) ".
                    "WHERE is_active ='y' AND feature1_id in(%s) OR feature2_id in(%s)", $id_list, $id_list);
  return $class->fetch_multiple($db, $sql);
}

sub fetch_all_visible {
  my $class = shift;
  my $db = shift;

  my $sql = sprintf("SELECT * FROM edge JOIN edge_source using(edge_source_id) WHERE is_visible ='y' ");
  return $class->fetch_multiple($db, $sql);
}

sub stream_all_visible {
  my $class = shift;
  my $db = shift;

  my $sql = sprintf("SELECT * FROM edge JOIN edge_source using(edge_source_id) WHERE is_visible ='y' ");
  return $class->stream_multiple($db, $sql);
}

sub fetch_all_like_link {
  my $class = shift;
  my $db = shift;
  my $link = shift; #Edge object
  
  #'like' means same feature1, feature2, and source

  my $sql = "SELECT * FROM edge ".
             "WHERE feature1_id=? and feature2_id=? and edge_source_id=?";
  return $class->fetch_multiple($db, $sql, $link->feature1_id, $link->feature2_id, $link->edge_source->id);
}


sub fetch_all_with_metadata {
  my $class = shift;
  my $source = shift; #EdgeSource object uses database of source for fetching
  my @mdata_array = @_; #Metadata object(s)
  
  if(defined($source) && !($source->isa('EEDB::EdgeSource'))) {
    die('second parameter [source] must be a EEDB::EdgeSource');
  }
  
  if(!defined($source->database) or !defined($source->primary_id)) { return []; }
  
  my @mdata_ids;
  foreach my $mdata (@mdata_array) {
    unless(defined($mdata) && ($mdata->class eq 'Metadata')) {
      die("$mdata is not a EEDB::Metadata");
    }
    if(defined($mdata->primary_id)) {push @mdata_ids, $mdata->id; }
  }
  if(scalar(@mdata_ids) == 0) { return []; } #if mdata objects not stored then return []
    
  my $sql = sprintf("SELECT e.* FROM edge e JOIN edge_2_metadata using(edge_id) WHERE metadata_id in(%s) ",
                   join(',', @mdata_ids));
  $sql .= sprintf(" AND edge_source_id=%d", $source->id);
  $sql .= sprintf(" GROUP BY e.edge_id");

  #print($sql, "\n", );
  return $class->fetch_multiple($source->database, $sql);
}

sub fetch_all_with_symbol {
  my $class = shift;
  my $db = shift;
  my $source = shift; #EdgeSource object
  my $symbol = shift; #Symbol object
  my $response_limit = shift; #optional
  
  unless(defined($source) && $source->isa('EEDB::EdgeSource')) {
    die('second parameter [source] must be a EEDB::EdgeSource');
  }
  unless(defined($symbol) && ($symbol->class eq 'Symbol')) {
    die('third parameter [symbol] must be a EEDB::Symbol');
  }

  my $sql = sprintf("SELECT e.* FROM edge f ".
                    "JOIN edge_2_symbol using(edge_id)  ".
                    "WHERE symbol_id = %d ", 
                    $symbol->id);
  if(defined($source)) {
    $sql .= sprintf("AND edge_source_id=%d", $source->id);
  }
  $sql .= sprintf(" GROUP BY e.edge_id"); #to make sure the edge is not sent more than once
  if($response_limit) {
    $sql .= sprintf(" LIMIT %d", $response_limit);
  }

  #print($sql, "\n", );
  return $class->fetch_multiple($db, $sql);
}


###############################################################################################
#
# streaming API section
#
###############################################################################################


=head2 stream_all

  Description: stream all edges out of database with a given set of source filters
  Arg (1)    : $database (MQdb::Database)
  Arg (2...) : hash named filter parameters. 
                 sources=>[$fsrc1, $fsrc2,$fsrc3],  instances of EEDB::FeatureSource
  Returntype : a DBStream instance
  Exceptions : none 

=cut

sub stream_all {
  my $class = shift;
  my $db = shift;  #database
  my %options = @_;  #like sources=>[$esrc1, $esrc2,$esrc3]
    
  return [] unless($db);

  my $sql = "SELECT * FROM edge e ";
  if(%options and $options{'visible'} eq 'y') { 
    $sql .= "JOIN edge_source es on(e.edge_source_id = es.edge_source_id and es.is_visible='y') ";
  }
  $sql .= "WHERE 1=1 ";

  if(%options and $options{'sources'}) {
    my @esrc_ids;
    foreach my $source (@{$options{'sources'}}) { 
      if($source->class eq 'EdgeSource') { push @esrc_ids, $source->id; }
    }
    $sql .= sprintf("AND e.edge_source_id in(%s) ", join(',', @esrc_ids)) if(@esrc_ids);
  }  
  if(%options and $options{'feature1'} and ($options{'feature1'}->class eq "Feature")) {
    $sql .= sprintf("AND feature1_id=%s ", $options{'feature1'}->id);
  }
  if(%options and $options{'feature2'} and ($options{'feature2'}->class eq "Feature")) {
    $sql .= sprintf("AND feature2_id=%s ", $options{'feature2'}->id);
  }

  $sql .= "ORDER by e.edge_source_id, weight desc";
  if(%options and $options{'end'} eq 'f2') { $sql .= ",feature2_id, feature1_id "; }
  else { $sql .= ",feature1_id, feature2_id "; }

  #printf("<sql>%s</sql>\n", $sql);
  return $class->stream_multiple($db, $sql);
}


sub stream_all_with_feature { #used by EEDB::Tools::EdgeCompare (experimental approach)
  my $class = shift;
  my $db = shift;
  my $feature = shift;
  my %options = @_; #optional
  
  my $id = $feature->id;
  my $sql = "SELECT * FROM edge e ";
  if(%options and $options{'visible'} eq 'y') { 
    $sql .= " JOIN edge_source es on(e.edge_source_id = es.edge_source_id and es.is_visible='y') ";
  }

  $sql .= sprintf("WHERE (feature1_id='%s' OR feature2_id='%s') ", $id, $id);
    
  if(%options and $options{'sources'}) {
    my @lsrc_ids;
    foreach my $lsrc (@{$options{'sources'}}) { push @lsrc_ids, $lsrc->id; }
    $sql .= sprintf("AND e.edge_source_id in(%s) ", join(',', @lsrc_ids));
  }  
  
  $sql .= "ORDER by weight desc";
  if(%options and $options{'end'} eq 'f1') { $sql .= ",feature1_id, feature2_id "; }
  if(%options and $options{'end'} eq 'f2') { $sql .= ",feature2_id, feature1_id "; }

  #printf("<sql>%s</sql>\n", $sql);
  return $class->stream_multiple($db, $sql);
}



1;

