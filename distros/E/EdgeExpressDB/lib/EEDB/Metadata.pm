=head1 NAME - EEDB::Metadata

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

$VERSION = 0.953;

package EEDB::Metadata;

use strict;
use Time::HiRes qw(time gettimeofday tv_interval);

use MQdb::MappedQuery;
our @ISA = qw(MQdb::MappedQuery);

#################################################
# Class methods
#################################################

sub class { return "Metadata"; }

#################################################
# Instance methods
#################################################

sub init {
  my $self = shift;
  my @args = @_;
  $self->SUPER::init(@args);

  if(@args and (scalar(@args)==2)) {
    $self->type($args[0]);
    $self->data($args[1]);
  }    
  return $self;
}

sub equals {
  my $self = shift;
  my $other = shift;
  return undef unless(defined($other));
  if(($self->type eq $other->type) and ($self->data eq $other->data)) { return 1; }
  return undef;
}


##########################
#
# getter/setter methods of data which is stored in database
#
##########################


sub type {
  my $self = shift;
  return $self->{'type'} = shift if(@_);
  $self->{'type'}='' unless(defined($self->{'type'}));
  return $self->{'type'};
}

sub data {
  my $self = shift;
  return $self->{'data'} = shift if(@_);
  return $self->{'data'};
}

sub data_size {
  my $self = shift;
  if(defined($self->{'data'})) { $self->{'data_size'} = length($self->{'data'}); }
  $self->{'data_size'}='' unless(defined($self->{'data_size'}));
  return $self->{'data_size'};
}


sub display_desc {
  my $self = shift;
  return sprintf("Metadata(%s) %s (%d bytes)", 
    $self->id,
    $self->type,
    $self->data_size
    );
}

sub display_contents {
  my $self = shift;
  return sprintf("Metadata(%s) %s:\"%s\"", 
    $self->id,
    $self->type,
    $self->data);
}

sub xml {
  my $self = shift;
  my $data = $self->data;
  $data =~ s/\&/&amp;/g;
  $data =~ s/\"/&quot;/g; #\"
  $data =~ s/\</&lt;/g;
  $data =~ s/\>/&gt;/g;

  my $str = sprintf("<mdata type=\"%s\">%s</mdata>\n",
                    $self->type,
                    $data);
  return $str;
}

#################################################
#
# keyword analysis
#
#################################################

sub extract_keywords {
  my $self = shift;

  my $valid_keywords = new EEDB::MetadataSet;
  
  #split keywords on , ( ) [ ] : ; or whitespace
  #my $desc = lc($self->data);
  my $desc = $self->data;
  my @keywords = split /[\,\(\)\[\]\:\;\s]/, $desc;
  foreach my $keyword (@keywords) {
    next unless($keyword);
    next unless(length($keyword) > 1);
    
    #remove an ending . (period)
    if($keyword =~ /\.$/) { chop($keyword); } 
    
    #capitalization test
    my $tkey = $keyword;
    if(!($tkey =~ /\d/) and ($tkey =~ s/^([A-Z])/lc($1)/e) and ($tkey eq lc($keyword))) {
      #printf("'%s' is capitalized\n", $keyword);
      $keyword = lc($keyword);
    }

    next if($keyword eq 'the');
    next if($keyword eq 'and');
    next if($keyword eq 'or');
    next if($keyword eq 'with');

    #printf("   '%s'\n", $keyword);
    $valid_keywords->add_tag_symbol("keyword", $keyword);
    
    #sub-keyword tests
    my @sub_keywords = split /[\-\/]/, $keyword;
    if(scalar(@sub_keywords)>1) {
      foreach my $keyw (@sub_keywords) {
        next unless($keyw);
        next unless(length($keyw) > 2);
        $valid_keywords->add_tag_symbol("keyword", $keyw);
      }
    }
  }
  $valid_keywords->remove_duplicates;
  return $valid_keywords;
}


#################################################
#
# DBObject override methods
#
#################################################

sub store {
  my $self = shift;
  my $db   = shift;
  
  unless($db) { return undef; }
  #if($self->check_exists_db($db)) { return $self; }
  
  my $dbc = $db->get_connection;  
  my $sql = "INSERT INTO metadata (data_type, data) VALUES(?,?)";
  my $sth = $dbc->prepare($sql);
  $sth->execute($self->type, $self->data);
  my $dbID = $dbc->last_insert_id(undef, undef, qw(metadata metadata_id));
  $sth->finish;
  if($dbID) {
    $self->primary_id($dbID);
    $self->database($db);
    return $self;
  } else {
    return undef;
  }
}

sub update {
  #use with extreme caution!!!! I should not even include it
  my $self = shift;
  my $sql = "UPDATE metadata set data_type=?, data=? where metadata_id=?";
  $self->database->execute_sql($sql, $self->type, $self->data, $self->id);
}

sub check_exists_db {
  my $self = shift;
  my $db   = shift;
  
  return undef unless($db);
  my $dbc = $db->get_connection;  

  #first do check if it is already in the database
  my $sth = $dbc->prepare("SELECT metadata_id FROM metadata where data_type=? and data=?");
  $sth->execute($self->type, $self->data);
  my ($dbID) = $sth->fetchrow_array();
  $sth->finish;
  if($dbID) {
    $self->primary_id($dbID);
    $self->database($db);
    return $self;
  } else {
    return undef;
  }
}


sub store_link_to_feature { 
  my $self = shift;
  my $feature = shift;
  
  unless($feature->database) {
    printf("ERROR:: %s has no database to link Metadata\n", $feature->simple_display_desc);
    die();
  }
  $feature->database->execute_sql(
      "INSERT ignore INTO feature_2_metadata (feature_id, metadata_id) VALUES(?,?)",
      $feature->id, $self->id);
}

sub unlink_from_feature { 
  my $self = shift;
  my $feature = shift;
  
  unless($feature->database) {
    printf("ERROR:: %s has no database to link Metadata\n", $feature->simple_display_desc);
    die();
  }
  $feature->database->execute_sql(
      "DELETE from feature_2_metadata where feature_id=? and metadata_id=?",
      $feature->id, $self->id);
}


sub store_link_to_feature_link { 
  my $self = shift;
  my $edge = shift;
  
  unless($edge->database) {
    printf("ERROR:: %s has no database to link Metadata\n", $edge->display_desc);
    die();
  }
  $edge->database->execute_sql(  
      "INSERT ignore INTO edge_2_metadata (edge_id, metadata_id) VALUES(?,?)",
      $edge->id, $self->id);
}


sub store_link_to_experiment { 
  my $self = shift;
  my $experiment = shift;
  
  unless($experiment->database) {
    printf("ERROR:: %s has no database to link Metadata\n", $experiment->display_desc);
    die();
  }
  $experiment->database->execute_sql(  
      "INSERT ignore INTO experiment_2_metadata (experiment_id, metadata_id) VALUES(?,?)",
      $experiment->id, $self->id);
}


sub store_link_to_feature_source { 
  my $self = shift;
  my $fsrc = shift;
  
  unless($fsrc->database) {
    printf("ERROR:: %s has no database to link Metadata\n", $fsrc->display_desc);
    die();
  }
  $fsrc->database->execute_sql(  
      "INSERT ignore INTO feature_source_2_metadata (feature_source_id, metadata_id) VALUES(?,?)",
      $fsrc->id, $self->id);
}


sub store_link_to_edge_source { 
  my $self = shift;
  my $edge_source = shift;
  
  unless($edge_source->database) {
    printf("ERROR:: %s has no database to link Metadata\n", $edge_source->display_desc);
    die();
  }
  $edge_source->database->execute_sql(  
      "INSERT ignore INTO edge_source_2_metadata (edge_source_id, metadata_id) VALUES(?,?)",
      $edge_source->id, $self->id);
}


##### DBObject instance override methods #####

sub mapRow {
  my $self = shift;
  my $rowHash = shift;
  my $dbc = shift;

  $self->primary_id($rowHash->{'metadata_id'});
  $self->type($rowHash->{'data_type'});
  $self->data($rowHash->{'data'});
         
  return $self;
}


##### public class methods for fetching by utilizing DBObject framework methods #####

sub fetch_by_id {
  my $class = shift;
  my $db = shift;
  my $id = shift;

  my $sql = "SELECT * FROM metadata WHERE metadata_id=?";
  return $class->fetch_single($db, $sql, $id);
}

sub stream_all {
  my $class = shift;
  my $db = shift;

  my $sql = "SELECT * FROM metadata";
  return $class->stream_multiple($db, $sql);
}

sub fetch_all_by_data {
  my $class = shift;
  my $db = shift;
  my $data = shift; 
  my $data_type = shift; #optional
  my $response_limit = shift; #optional
  
  my $sql = sprintf("SELECT * FROM metadata WHERE data = ?");
  if(defined($data_type)) {
    $sql .= sprintf(" AND data_type='%s'", $data_type);
  }
  if($response_limit) {
    $sql .= sprintf(" LIMIT %d", $response_limit);
  }
  return $class->fetch_multiple($db, $sql, $data);
}

sub fetch_all_by_type {
  my $class = shift;
  my $db = shift;
  my $data_type = shift;
  my $response_limit = shift; #optional
  
  my $sql = sprintf("SELECT * FROM metadata WHERE data_type='%s'", $data_type);
  if($response_limit) {
    $sql .= sprintf(" ORDER BY metadata_id LIMIT %d", $response_limit);
  }
  return $class->fetch_multiple($db, $sql);
}

##

sub fetch_all_by_feature {
  my $class = shift;
  my $feature = shift;
  my %options = @_;  #like types=>['authors','title']

  my @types = @{$options{'types'}} if($options{'types'});

  my $sql = "SELECT m.* FROM metadata m join feature_2_metadata using(metadata_id) WHERE feature_id=?";
  $sql .= " AND data_type in (?)" if(@types);
  if(@types) {
    return $class->fetch_multiple($feature->database, $sql, $feature->id, join(',', @types));
  } else {
    return $class->fetch_multiple($feature->database, $sql, $feature->id);
  }
}

sub fetch_all_by_feature_id {
  my $class = shift;
  my $db = shift;
  my $id = shift;
  my $type = shift;

  my $sql = "SELECT m.* FROM metadata m join feature_2_metadata using(metadata_id) WHERE feature_id=?";
  $sql .= sprintf(" AND data_type=\"%s\"", $type) if($type);
  return $class->fetch_multiple($db, $sql, $id);
}

sub fetch_all_by_edge_id {
  my $class = shift;
  my $db = shift;
  my $id = shift;

  my $sql = "SELECT m.* FROM metadata m join edge_2_metadata using(metadata_id) WHERE edge_id=?";
  return $class->fetch_multiple($db, $sql, $id);
}

sub fetch_all_by_experiment_id {
  my $class = shift;
  my $db = shift;
  my $id = shift;

  my $sql = "SELECT m.* FROM metadata m join experiment_2_metadata using(metadata_id) WHERE experiment_id=?";
  return $class->fetch_multiple($db, $sql, $id);
}

sub fetch_all_by_feature_source_id {
  my $class = shift;
  my $db = shift;
  my $id = shift; 

  my $sql = "SELECT m.* FROM metadata m join feature_source_2_metadata using(metadata_id) where feature_source_id = ?";
  return $class->fetch_multiple($db, $sql, $id);
}

sub fetch_all_by_edge_source_id {
  my $class = shift;
  my $db = shift;
  my $id = shift; 

  my $sql = "SELECT m.* FROM metadata m join edge_source_2_metadata using(metadata_id) where edge_source_id = ?";
  return $class->fetch_multiple($db, $sql, $id);
}

1;

