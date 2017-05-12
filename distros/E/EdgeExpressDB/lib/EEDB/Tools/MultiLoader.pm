=head1 NAME - EEDB::Tools::MultiLoader

=head1 DESCRIPTION

MultiLoader is a single class which wraps up database specific
optimizations for speeding up bulk loading. Since eeDB is primarily
a data-mining system, most of the data is loaded in bulk. This loader
augments the class specific ->store() functions. 
Currently eeDB supports sqlite and mysql databases and there are
specific optimizations here for these two database engines.

=head1 AUTHOR

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

package EEDB::Tools::MultiLoader;

use strict;
use Time::HiRes qw(time gettimeofday tv_interval);

use EEDB::Feature;
use EEDB::Edge;

use MQdb::DBObject;
our @ISA = qw(MQdb::DBObject);

#################################################
# Class methods
#################################################

sub class { return "MultiLoader"; }

#################################################
# Instance methods
#################################################

sub init {
  my $self = shift;
  my %args = @_;
  $self->SUPER::init(@_);
  
  $self->{'feature_buffer'} = [];
  $self->{'feature_mdata_buffer'} = [];  
  $self->{'edge_buffer'} = [];
  $self->{'express_buffer'} = [];
  $self->{'metadata_buffer'} = [];
  $self->{'symbol_buffer'} = [];
  $self->{'do_store'} = 1;

  return $self;
}


##################

sub do_store {
  my $self = shift;
  return $self->{'do_store'} = shift if(@_);
  $self->{'do_store'}=1 unless(defined($self->{'do_store'}));
  return $self->{'do_store'};
}

sub mirror { #forces load and ignores checks if the data has some previous DB id
  my $self = shift;
  return $self->{'mirror'} = shift if(@_);
  $self->{'mirror'}=0 unless(defined($self->{'mirror'}));
  return $self->{'mirror'};
}

###############################################

=head2 flush_buffers

  Description  : MultiLoader uses internal FIFO buffers for speed. 
                 After all loading these buffers must be flushed to ensure they are empty
                 and all objects have been written
  Returntype   : none
  Exceptions   : none
  Example      :      my $multiLoad = new EEDB::Tools::MultiLoader;
                      $multiLoad->database($eeDB);
                      $multiLoad->do_store(1);
                      foreach my $mydata (@data_array) {
                        my $feature = new EEDB::Feature;
                        # do something with $mydata and $feature to create the feature
                        $multiLoad->store_feature($feature);
                      }
                      #after all store_xxxx methods, must flush any remaining objects from buffers
                      #usually the last thing we do in a script
                      $multiLoad->flush_buffers();
                      exit(1);
                      
=cut

sub flush_buffers {
  my $self = shift;
  
  $self->store_metadata();
  $self->store_symbol();
  $self->store_feature();
  $self->store_edge();
  $self->store_express(); #must be last since it relies on all features having ids

  if($self->database->driver eq "sqlite") { $self->_sqlite_transaction("FLUSH"); }
  return $self;
}


#############
#
# Features
#
#############

=head2 store_feature

  Description  : MultiLoader uses internal FIFO buffers for speed. 
                 This method queues up a Feature into MultiLoader. When the buffer is full
                 it will do a bulk load, otherwise it will return directly.  If called
                 with no $feature parameter it will force a buffer flush and write.
  Parameter[1] : feature [EEDB::Feature] or undef to flush
  Returntype   : none
  Exceptions   : none
  Example      :      my $multiLoad = new EEDB::Tools::MultiLoader;
                      $multiLoad->database($eeDB);
                      $multiLoad->do_store(1);
                      foreach my $feature (@feature_array) {
                        $multiLoad->store_feature($feature);
                      }
                      $multiLoad->store_feature(); #no parameter so empties buffers
                      exit(1);
                      
=cut

sub store_feature {
  my $self = shift;
  my $feature = shift;
    
  if(defined($feature)) { 
  
    #first queue up the metadata (and make sure it is loaded if doing as copy)
    my $mdata_list = $feature->metadataset->metadata_list;
    
    #now we can reset the primary_id and disconnect from previous database if it was
    $feature->primary_id(undef);
    
    foreach my $mdata (@$mdata_list) {
      if($self->mirror or !defined($mdata->primary_id)) {
        $mdata->primary_id(undef); #to make sure it really does store and link properly
        if($mdata->class eq 'Metadata') { $self->store_metadata($mdata); }
        if($mdata->class eq 'Symbol')   { $self->store_symbol($mdata); }
      }
    }
        
    #last queue up the feature
    push @{$self->{'feature_buffer'}}, $feature; 
    return if(scalar(@{$self->{'feature_buffer'}}) < 200);
  }
  return unless(scalar(@{$self->{'feature_buffer'}}) >0);
  #printf("store feature buffer [%d]\n", scalar(@{$self->{'feature_buffer'}}));

  #
  # 1st flush the metadata since I need to have the data in the database before I can link
  #
  $self->store_metadata();
  $self->store_symbol();

  #
  # do feature bulk store here
  #
  if($self->database->driver eq "sqlite") { 
    $self->_sqlite_transaction("BEGIN"); 
  } else {
    $self->database->do_sql("LOCK TABLE feature WRITE, feature AS f1 READ");
  }
  my $fid = $self->database->fetch_col_value("select max(feature_id) from feature AS f1;");
  if($fid) { $fid += 1; } else { $fid = 1; }
  my $sql = "INSERT ignore INTO feature (feature_id, feature_source_id, chrom_id, chrom_start, ".
            "chrom_end, strand, significance, primary_name) VALUES ";
  my $first=1;
  foreach my $feat (@{$self->{'feature_buffer'}}) {
    $feat->primary_id($fid++);
    my $chrom_id = $feat->chrom_id;
    if($chrom_id eq '') { $chrom_id = "NULL"; }
    else { $chrom_id = "\"" . $chrom_id . "\"" };

    my $values = sprintf("(%s,%s,%s,%d,%d,\"%s\",%s,\"%s\")",
                $feat->id,
                $feat->feature_source->id,
                $chrom_id,
                $feat->chrom_start,
                $feat->chrom_end,
                $feat->strand,
                $feat->significance,
                $feat->primary_name);
    if($self->database->driver eq "sqlite") {
      $self->database->execute_sql($sql . $values) if($self->do_store);
    } else {
      if($first) { $first=0; } else { $sql .= ","; }
      $sql .= $values;
    }
  }
  #printf("%s\n", $sql);
  if($self->database->driver eq "sqlite") {
    $self->_sqlite_transaction("COMMIT");
  } else {
    $self->database->execute_sql($sql) if($self->do_store);
    $self->database->do_sql("UNLOCK TABLES");
  }
  
  #
  # now do the expression
  #
  foreach my $feat (@{$self->{'feature_buffer'}}) {
    my $expr_array = $feat->get_expression_array;
    foreach my $express (@$expr_array) {
      if($self->mirror or !defined($express->primary_id)) {
        $express->primary_id(undef);
        $self->store_express($express);
      }
    }
  }  
  $self->store_express();
  #printf("flush the expression buffer\n");

  #
  # do the symbol/metadata linkage now
  #
  $self->build_feature_symbol_links();
  $self->build_feature_metadata_links();
  
  #
  # then do the chunk edges
  #
  $self->build_chunk_links();


  #done now do cleanup and clear out the buffer
  foreach $feature (@{$self->{'feature_buffer'}}) {
    $feature->empty_expression_cache;
  }
  $self->{'feature_buffer'} = [];
}


=head2 update_feature_metadata

  Description  : this method will take a feature which was fetched from a database
                 and which may have new metadata/symbols and it will store that new
                 metadata/symbols and link them to the feature.
  Parameter[1] : feature [EEDB::Feature]
  Returntype   : none
  Exceptions   : none
  Example      :      my $multiLoad = new EEDB::Tools::MultiLoader;
                      $multiLoad->database($eeDB);
                      $multiLoad->do_store(1);
                      foreach my $feature (@feature_array) {
                         #
                         # do some metadata additions here
                         #
                         $multiLoad->update_feature_metadata($feature);
                      }
                      $multiLoad->update_feature_metadata(); #to flush the queues
                      
=cut

sub update_feature_metadata {
  my $self = shift;
  my $feature = shift;
    
  if(defined($feature)) {
    if($feature->database->url ne $self->database->url) { return; }
  
    #first queue up the metadata 
    my $mdata_list = $feature->metadataset->metadata_list;
    my $mdata_count = 0;
    foreach my $mdata (@$mdata_list) {
      if(!defined($mdata->primary_id)) {
        $mdata_count++;
        if($mdata->class eq 'Metadata') { $self->store_metadata($mdata); }
        if($mdata->class eq 'Symbol')   { $self->store_symbol($mdata); }
      }
    }
    if($mdata_count == 0) { return; }
    
    #OK this feature has new mdata, so queue it up for linking
    push @{$self->{'feature_mdata_buffer'}}, $feature; 
    if(scalar(@{$self->{'feature_mdata_buffer'}}) < 500) { return; }
  }
  if(scalar(@{$self->{'feature_mdata_buffer'}}) == 0) { return; }

  # 1st flush the metadata since I need to have the data in the database before I can link
  $self->store_metadata();
  $self->store_symbol();

  # do the symbol/metadata linkage now
  $self->build_feature_symbol_links();
  $self->build_feature_metadata_links();
  
  #done so clear out the buffer
  $self->{'feature_mdata_buffer'} = [];
}


sub build_chunk_links {
  my $self = shift;

  if($self->database->driver eq "sqlite") { return; }

  my $sql = "INSERT ignore INTO feature_2_chunk (feature_id, chrom_chunk_id) VALUES ";
  my $first=1;
  foreach my $feature (@{$self->{'feature_buffer'}}) {
    next unless($feature->chrom and ($feature->chrom_start>0) and ($feature->chrom_end>0));
    my $chunks = EEDB::ChromChunk->fetch_all_by_chrom_range($feature->chrom, $feature->chrom_start, $feature->chrom_end);
    foreach my $chunk (@{$chunks}) {
      if($first) { $first=0; } else { $sql .= ","; }
      $sql .= sprintf("(%s,%s)", $feature->id, $chunk->id);
    }
  }
  if($first) { return; } #no chunks to link
  
  #printf("%s\n", $sql);
  $self->database->execute_sql($sql) if($self->do_store);
  #printf("done\n");
}


sub build_source_chunk_links {
  my $self = shift;
  my $source = shift; #FeatureSource

  my $chroms = EEDB::Chrom->fetch_all_by_feature_source($source);
  foreach my $chrom (@$chroms) {
    $chrom->display_info;
    my $chunks = EEDB::ChromChunk->fetch_all_by_chrom($chrom);
    foreach my $chunk (@$chunks) {
      printf("  "); $chunk->display_info;
      #
      # do OverlapCompare against the FeatureSource
      #
    }
  }
}

#######################################
#
# Edges
#
#######################################

sub store_edge {
  my $self = shift;
  my $edge = shift;
  
  if(defined($edge)) { 
    #first queue up the metadata
    my $mdata_list = $edge->metadataset->metadata_list;
    foreach my $mdata (@$mdata_list) {
      if($self->mirror or !defined($mdata->primary_id)) {
        if($mdata->class eq 'Metadata') { $self->store_metadata($mdata); }
        if($mdata->class eq 'Symbol')   { $self->store_symbol($mdata); }
      }
    }
        
    #then queue up the edge
    push @{$self->{'edge_buffer'}}, $edge; 
    return if(scalar(@{$self->{'edge_buffer'}}) < 1000);
  }
  return unless(scalar(@{$self->{'edge_buffer'}}) >0);
  #printf("store edge buffer\n");

  #
  # 1st flush the metadata and features since I need to have the data and ids in the database before I can link
  #
  $self->store_metadata();
  $self->store_symbol();
  $self->store_feature();

  #
  # do Edge bulk store here
  #
  if($self->database->driver eq "sqlite") { $self->_sqlite_transaction("BEGIN"); } 
  else { $self->database->do_sql("LOCK TABLE edge WRITE, edge AS e1 READ;") if($self->do_store); }
  my $eid = $self->database->fetch_col_value("select max(edge_id) from edge AS e1;");
  if($eid) { $eid += 1; } else { $eid = 1; }
  my $sql = "INSERT ignore INTO edge ".
             "(edge_id, edge_source_id, feature1_id, feature2_id, sub_type, direction, weight) VALUES ";
  my $first=1;
  foreach $edge (@{$self->{'edge_buffer'}}) {
    $edge->primary_id($eid++);
    my $values = sprintf("(%s,%s,%s,%s,'%s','%s',%f)",
                $edge->id,
                $edge->edge_source->id,
                $edge->feature1->id,
                $edge->feature2->id,
                $edge->sub_type,
                $edge->direction,
                $edge->weight);
    if($self->database->driver eq "sqlite") {
      $self->database->execute_sql($sql . $values) if($self->do_store);
    } else {
      if($first) { $first=0; } else { $sql .= ","; }
      $sql .= $values;
    }
  }
  #printf("%s\n", $sql);
  if($self->database->driver eq "sqlite") {
    $self->_sqlite_transaction("COMMIT");
  } else {
    $self->database->execute_sql($sql) if($self->do_store);
    $self->database->do_sql("UNLOCK TABLES") if($self->do_store);
  }
  
  #
  # now I need to link the edge to metadata
  #
  # TODO
  #
  
  #done now so clear out the buffer
  $self->{'edge_buffer'} = [];
}

#######################################
#
# Expression
#
#######################################

sub store_express {
  #this should be called after features have been stored
  #so that feature_id is available
  my $self = shift;
  my $express = shift;
  
  if(defined($express)) { 
    push @{$self->{'express_buffer'}}, $express; 
    return if(scalar(@{$self->{'express_buffer'}}) < 500);
  }
  return unless(scalar(@{$self->{'express_buffer'}}) >0);
  #printf("store express buffer [%d]\n", scalar(@{$self->{'express_buffer'}}));
  
  #
  # do expression bulk store here
  #
  my $sql = "INSERT ignore INTO expression ".
             "(experiment_id, feature_id, datatype_id, value, sig_error) VALUES ";
  my $first=1;
  foreach $express (@{$self->{'express_buffer'}}) {
    if($first) { $first=0; } else { $sql .= ","; }
    my $datatype_id = EEDB::Expression->_storeget_expression_datatype_id($self->database, $express->type);
    $sql .= sprintf("(%s,%d,%d,%s,%s)",
                $express->experiment->id,
                $express->feature->id,
                $datatype_id,
                $express->value,
                $express->sig_error);
  }
  #printf("%s\n", $sql);
  $self->database->execute_sql($sql) if($self->do_store);
  #printf("done\n");
  
  #done now so clear out the buffer
  $self->{'express_buffer'} = [];
}

#######################################
#
# Metadata and Symbols
#
#######################################

sub store_metadata {
  my $self = shift;
  my $mdata = shift;
  
  if(defined($mdata)) { 
    #return unless($mdata->class eq 'Metadata');
    push @{$self->{'metadata_buffer'}}, $mdata; 
    return if(scalar(@{$self->{'metadata_buffer'}}) < 500);
  }
  return unless(scalar(@{$self->{'metadata_buffer'}}) >0);
  #printf("store metadata buffer [%d]\n", scalar(@{$self->{'metadata_buffer'}}));

  #
  # do bulk store here
  #
  if($self->database->driver eq "sqlite") { $self->_sqlite_transaction("BEGIN"); }
  my $sql  =  "INSERT ignore INTO metadata (data_type, data) VALUES ";
  my $first=1;
  foreach $mdata (@{$self->{'metadata_buffer'}}) {
    if($self->database->driver eq "sqlite") { 
      $mdata->store($self->database) if($self->do_store);
    } else {
      my $data = $mdata->data;
      $data =~ s/\\/\\\\/g;
      $data =~ s/\"/\\\"/g; 
      $data =~ s/\'/\\\'/g;  #'
      if($first) { $first=0; } else { $sql .= ","; }
      $sql .= sprintf("(\"%s\",\"%s\")", $mdata->type, $data);
    }
  }
  #printf("%s\n", $sql);
  if($self->database->driver eq "sqlite") { 
    $self->_sqlite_transaction("COMMIT");
  } else {
    $self->database->execute_sql($sql) if($self->do_store);
  }
  #printf("done\n");

  #done now so clear out the buffer
  $self->{'metadata_buffer'} = [];
}


sub store_symbol {
  my $self = shift;
  my $symbol = shift;
  
  if(defined($symbol)) { 
    #if($symbol->check_exists_db($self->database)) { return; }
    #return unless($symbol->class eq 'Symbol');
    push @{$self->{'symbol_buffer'}}, $symbol; 
    return if(scalar(@{$self->{'symbol_buffer'}}) < 500);
  }
  return unless(scalar(@{$self->{'symbol_buffer'}}) >0);
  #printf("store symbol buffer [%d]\n", scalar(@{$self->{'symbol_buffer'}}));

  #
  # do bulk store here
  #  
  if($self->database->driver eq "sqlite") { $self->_sqlite_transaction("BEGIN"); }
  my $sql =  "INSERT ignore INTO symbol (sym_type, sym_value) VALUES ";
  my $first=1;
  foreach $symbol (@{$self->{'symbol_buffer'}}) {
    if($self->database->driver eq "sqlite") { 
      $symbol->store($self->database) if($self->do_store);
    } else {
      my $data = $symbol->data;
      $data =~ s/\\/\\\\/g;
      $data =~ s/\"/\\\"/g; 
      $data =~ s/\'/\\\'/g;  #'
      if($first) { $first=0; } else { $sql .= ","; }
      $sql .= sprintf("(\"%s\",\"%s\")", $symbol->type, $data);
    }
  }
  #printf("%s\n", $sql);
  if($self->database->driver eq "sqlite") { 
    $self->_sqlite_transaction("COMMIT");
  } else {
    $self->database->execute_sql($sql) if($self->do_store);
  }
  #printf("done\n");
  

  #done now so clear out the buffer
  $self->{'symbol_buffer'} = [];
}


sub build_feature_symbol_links {
  my $self = shift;

  if($self->database->driver eq "sqlite") { $self->_sqlite_transaction("BEGIN"); } 
  my $sql = "INSERT ignore INTO feature_2_symbol (feature_id, symbol_id) VALUES ";
  my $insert_count=0;
  my $first =1; 
  foreach my $feature (@{$self->{'feature_buffer'}}, @{$self->{'feature_mdata_buffer'}}) {
    my $mdata_list = $feature->metadataset->metadata_list;
    foreach my $mdata (@$mdata_list) {
      next unless($mdata->class eq 'Symbol');
      if($self->do_store) {
        ##triple check code here, by this time all $mdata should be store and with ID
        if(!defined($mdata->primary_id) and !$mdata->check_exists_db($self->database)) {
          #something happened with the bulk database store, so try again with a direct store
          #this should not happen, something unexpected happened
          $mdata->store($self->database) if($self->do_store);
          printf(STDERR "WARN: symbol direct store needed before linking : %s\n", $mdata->display_desc);
        }
        if(!defined($mdata->primary_id)) { 
          printf(STDERR "ERROR: mdata did not store : %s\n", $mdata->display_desc);
          next; 
        }
      }
      
      $insert_count++;
      my $values = sprintf("(%s,%s)", $feature->id, $mdata->id);
      if($self->database->driver eq "sqlite") { 
        $self->database->execute_sql($sql . $values) if($self->do_store);
      } else {
        if($first) { $first=0; } else { $sql .= ","; }
        $sql .= $values;
      }
    }
  }
  return if($insert_count == 0);
  if($self->database->driver eq "sqlite") { 
    $self->_sqlite_transaction("COMMIT");
  } else {
    $self->database->execute_sql($sql) if($self->do_store);
  }
}


sub build_feature_metadata_links {
  my $self = shift;

  if($self->database->driver eq "sqlite") { $self->_sqlite_transaction("BEGIN"); } 
  my $sql = "INSERT ignore INTO feature_2_metadata (feature_id, metadata_id) VALUES ";
  my $insert_count=0;
  my $first =1; 
  foreach my $feature (@{$self->{'feature_buffer'}}, @{$self->{'feature_mdata_buffer'}}) {
    my $mdata_list = $feature->metadataset->metadata_list;
    foreach my $mdata (@$mdata_list) {
      next unless($mdata->class eq 'Metadata');
      if($self->do_store) {
        ##triple check code here, by this time all $mdata should be store and with ID
        if(!defined($mdata->primary_id) and !$mdata->check_exists_db($self->database)) {
          #something happened with the bulk database store, so try again with a direct store
          $mdata->store($self->database) if($self->do_store);
          printf(STDERR "WARN: mdata direct store needed before linking : %s\n", $mdata->display_desc);
        }
        if(!defined($mdata->primary_id) and ($self->do_store)) { 
          printf(STDERR "ERROR: mdata did not store : %s\n", $mdata->display_desc);
          next; 
        }
      }

      $insert_count++;
      my $values = sprintf("(%s,%s)", $feature->id, $mdata->id);
      if($self->database->driver eq "sqlite") { 
        $self->database->execute_sql($sql . $values) if($self->do_store);
      } else {
        if($first) { $first=0; } else { $sql .= ","; }
        $sql .= $values;
      }
    }
  }
  return if($insert_count == 0);
  #print($sql,"\n");
  if($self->database->driver eq "sqlite") { 
    $self->_sqlite_transaction("COMMIT");
  } else {
    $self->database->execute_sql($sql) if($self->do_store);
  }
}


sub _sqlite_transaction {
  my $self = shift;
  my $state = shift;
  
  if($state eq "BEGIN") {
    $self->{"_sqlite_transaction_count"}++;
    if($self->{"_sqlite_transaction_count"} == 1) {
      $self->database->execute_sql("BEGIN TRANSACTION");
    }
  } 
  if($state eq "COMMIT") {
    if($self->{"_sqlite_transaction_count"} == 1) {
      $self->database->execute_sql("COMMIT"); 
      $self->{"_sqlite_transaction_count"} = 0;
    }
    if($self->{"_sqlite_transaction_count"} > 1) {
      $self->{"_sqlite_transaction_count"}--;
    }
  }
  if($state eq "FLUSH") {
    if($self->{"_sqlite_transaction_count"} >= 1) {
      $self->database->execute_sql("COMMIT"); 
      $self->{"_sqlite_transaction_count"} = 0;
    }
  }
}

1;

