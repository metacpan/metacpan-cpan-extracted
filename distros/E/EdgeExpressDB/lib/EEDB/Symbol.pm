=head1 NAME - EEDB::Symbol

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

package EEDB::Symbol;

use strict;

use EEDB::Metadata;
our @ISA = qw(EEDB::Metadata);

#################################################
# Class methods
#################################################

sub class { return "Symbol"; }

#################################################
# Instance methods
#################################################

##########################
#
# getter/setter methods of data which is stored in database
#
##########################

sub symbol {
  my $self = shift;
  return $self->SUPER::data(@_);
}

sub display_desc {
  #override superclass method
  my $self = shift;
  return sprintf("Symbol(%s) %s:%s", 
    $self->id,
    $self->type,
    $self->symbol);
}

sub display_contents {
  #override superclass method
  my $self = shift;
  return $self->display_desc;
}

sub xml {
  my $self = shift;
  my $value = $self->symbol;
  $value =~ s/&/&amp;/g;
  $value =~ s/</&lt;/g;
  $value =~ s/>/&gt;/g;
  $value =~ s/"/&quot;/g; #"
  my $str = sprintf("<symbol type=\"%s\" value=\"%s\" />\n", $self->type, $value);
  return $str;
}

#################################################
#
# DBObject override methods : storage methods
#
#################################################

sub store {
  my $self = shift;
  my $db   = shift;
  
  unless($db) { return undef; }  
  if($self->check_exists_db($db)) { return $self; }
  
  $db->execute_sql("INSERT ignore INTO symbol (sym_type, sym_value) VALUES(?,?)", 
                   $self->type, $self->symbol);
  return $self->check_exists_db($db);  #checks the database and sets the id
}


sub check_exists_db {
  my $self = shift;
  my $db   = shift;
  
  unless($db) { return undef; }
  if(defined($self->primary_id)) { return $self; }
  
  #check if it is already in the database
  my $dbID = $db->fetch_col_value("SELECT symbol_id FROM symbol where sym_type=? and sym_value=?",
                                  $self->type, $self->data);
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
    printf("ERROR:: %s has no database to link Symbol\n", $feature->simple_display_desc);
    die();
  }
  $feature->database->execute_sql(  
      "INSERT ignore INTO feature_2_symbol (feature_id, symbol_id) VALUES(?,?)",
      $feature->id, $self->id);
}

sub unlink_from_feature { 
  my $self = shift;
  my $feature = shift;
  
  unless($self->database) { printf("ERROR:: no database\n"); die(); }
  unless($self->primary_id) { printf("ERROR:: undef symbol_id\n"); die(); }
  unless($feature->primary_id) { printf("ERROR:: undef feature_id\n"); die(); }

  #then link
  my $sql = sprintf("DELETE from feature_2_symbol where feature_id=%s and symbol_id=%s", $feature->id, $self->id);
  #printf("%s\n", $sql);
  $feature->database->do_sql($sql);
}


sub store_link_to_feature_link { 
  my $self = shift;
  my $edge = shift;
  
  unless($edge->database) {
    printf("ERROR:: %s has no database to link Symbol\n", $edge->display_desc);
    die();
  }
  $edge->database->execute_sql( 
      "INSERT ignore INTO edge_2_symbol (edge_id, symbol_id) VALUES(?,?)",
      $edge->id, $self->id);
}


sub store_link_to_experiment { 
  my $self = shift;
  my $experiment = shift;
  
  unless($experiment->database) {
    printf("ERROR:: %s has no database to link Symbol\n", $experiment->display_desc);
    die();
  }
  $experiment->database->execute_sql(
      "INSERT ignore INTO experiment_2_symbol (experiment_id, symbol_id) VALUES(?,?)",
      $experiment->id, $self->id);
}


sub store_link_to_feature_source { 
  my $self = shift;
  my $fsrc = shift;
  
  unless($fsrc->database) {
    printf("ERROR:: %s has no database to link Symbol\n", $fsrc->display_desc);
    die();
  }
  $fsrc->database->execute_sql(  
      "INSERT ignore INTO feature_source_2_symbol (feature_source_id, symbol_id) VALUES(?,?)",
      $fsrc->id, $self->id);
}


sub store_link_to_edge_source { 
  my $self = shift;
  my $edge_source = shift;
  
  unless($edge_source->database) {
    printf("ERROR:: %s has no database to link Symbol\n", $edge_source->display_desc);
    die();
  }
  $edge_source->database->execute_sql(  
      "INSERT ignore INTO edge_source_2_symbol (edge_source_id, symbol_id) VALUES(?,?)",
      $edge_source->id, $self->id);
}


##### DBObject instance override methods #####

sub mapRow {
  my $self = shift;
  my $rowHash = shift;
  my $dbh = shift;

  $self->primary_id($rowHash->{'symbol_id'});
  $self->type($rowHash->{'sym_type'});
  $self->symbol($rowHash->{'sym_value'});

  return $self;
}


##### public class methods for fetching by utilizing DBObject framework methods #####

sub fetch_by_id {
  my $class = shift;
  my $db = shift;
  my $id = shift;

  my $sql = "SELECT * FROM symbol WHERE symbol_id=?";
  return $class->fetch_single($db, $sql, $id);
}

sub fetch_by_type_name {
  my $class = shift;
  my $db = shift;
  my $sym_type = shift; 
  my $sym_value = shift; 
  
  my $sql = "SELECT * FROM symbol WHERE sym_value = ? AND sym_type=?";
  return $class->fetch_single($db, $sql, $sym_value, $sym_type);
}

sub stream_all {
  my $class = shift;
  my $db = shift;

  my $sql = "SELECT * FROM symbol";
  return $class->stream_multiple($db, $sql);
}

sub fetch_all_by_feature_id {
  my $class = shift;
  my $db = shift;
  my $id = shift; 

  my $sql = "SELECT * FROM feature_2_symbol join symbol using(symbol_id) where feature_id = ?";
  return $class->fetch_multiple($db, $sql, $id);
}

sub fetch_all_by_edge_id {
  my $class = shift;
  my $db = shift;
  my $id = shift; 

  my $sql = "SELECT * FROM edge_2_symbol join symbol using(symbol_id) where edge_id = ?";
  return $class->fetch_multiple($db, $sql, $id);
}

sub fetch_all_by_experiment_id {
  my $class = shift;
  my $db = shift;
  my $id = shift; 

  my $sql = "SELECT * FROM experiment_2_symbol join symbol using(symbol_id) where experiment_id = ?";
  return $class->fetch_multiple($db, $sql, $id);
}

sub fetch_all_by_feature_source_id {
  my $class = shift;
  my $db = shift;
  my $id = shift; 

  my $sql = "SELECT s.* FROM symbol s join feature_source_2_symbol using(symbol_id) where feature_source_id = ?";
  return $class->fetch_multiple($db, $sql, $id);
}

sub fetch_all_by_edge_source_id {
  my $class = shift;
  my $db = shift;
  my $id = shift; 

  my $sql = "SELECT s.* FROM symbol s join edge_source_2_symbol using(symbol_id) where edge_source_id = ?";
  return $class->fetch_multiple($db, $sql, $id);
}


sub fetch_all_by_name {
  my $class = shift;
  my $db = shift;
  my $sym_value = shift; 
  my $sym_type = shift; #optional
  my $response_limit = shift; #optional
  
  my $sql = sprintf("SELECT * FROM symbol WHERE sym_value = '%s'", $sym_value);
  if(defined($sym_type)) {
    $sql .= sprintf(" AND sym_type='%s'", $sym_type);
  }
  if($response_limit) {
    $sql .= sprintf(" LIMIT %d", $response_limit);
  }

  #print($sql, "\n", );
  return $class->fetch_multiple($db, $sql);
}


sub fetch_all_symbol_search {
  my $class = shift;
  my $db = shift;
  my $sym_value = shift; 
  my $sym_type = shift; #optional
  my $response_limit = shift; #optional
  
  $sym_value =~ s/_/\\_/g;
  $sym_value =~ s/\"/\\\"/g; 
  $sym_value =~ s/\'/\\\'/g;  #'

  my $sql = sprintf("SELECT * FROM symbol WHERE sym_value like '%s%%'", $sym_value);
  if(defined($sym_type)) {
    $sql .= sprintf(" AND sym_type='%s'", $sym_type);
  }
  #print($sql, "\n", );      
  return $class->fetch_multiple($db, $sql);
}


sub fetch_all_by_type_numerical_range {
  my $class = shift;
  my $db = shift;
  my $sym_type = shift;
  my $low_value = shift; 
  my $upper_value = shift; 
  my $response_limit = shift; #optional
  
  return [] unless(defined($low_value) and defined($sym_type));
  
  my $sql = sprintf("SELECT * FROM symbol WHERE sym_type='%s' ", $sym_type);
  if(defined($low_value) and defined($upper_value) and ($low_value == $upper_value)) {
    #doing an equals
    $sql .= sprintf("AND (sym_value+0)=%s ", $low_value);
  } else {
    $sql .= sprintf("AND (sym_value+0)>=%s ", $low_value);
    $sql .= sprintf("AND (sym_value+0)<=%s ", $upper_value) if(defined($upper_value));
  }

  if($response_limit) {
    $sql .= sprintf(" LIMIT %d", $response_limit);
  }

  #print($sql, "\n", );
  return $class->fetch_multiple($db, $sql);
}


sub get_count_symbol_search {
  my $class = shift;
  my $db = shift;
  my $sym_value = shift; 
  my $sym_type = shift; #optional
  
  $sym_value =~ s/_/\\_/g;

  my $sql = sprintf("select count(distinct symbol_id) from symbol WHERE sym_value like '%s'", $sym_value);
  if(defined($sym_type)) {
    $sql .= sprintf(" AND sym_type='%s'", $sym_type);
  }
  return $class->fetch_col_value($db, $sql);
}

1;

