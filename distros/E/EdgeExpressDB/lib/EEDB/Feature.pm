=head1 NAME - EEDB::Feature

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

my $__riken_EEDB_feature_global_should_cache = 0;
my $__riken_EEDB_feature_global_id_cache = {};

$VERSION = 0.953;

package EEDB::Feature;

use strict;
use Time::HiRes qw(time gettimeofday tv_interval);
use EEDB::Chrom;
use EEDB::ChromChunk;
use EEDB::FeatureSource;
use EEDB::MetadataSet;
use EEDB::Edge;
use EEDB::EdgeSet;
use EEDB::Expression;

use MQdb::MappedQuery;
our @ISA = qw(MQdb::MappedQuery);


#################################################
# Class methods
#################################################

sub class { return "Feature"; }

sub set_cache_behaviour {
  my $class = shift;
  my $mode = shift;
  
  $__riken_EEDB_feature_global_should_cache = $mode;
  
  if(defined($mode) and ($mode eq '0')) {
    #if turning off caching, then flush the caches
    foreach my $feature (values(%{$__riken_EEDB_feature_global_id_cache})) {
      $feature->clear_edges;
    }
    $__riken_EEDB_feature_global_id_cache = {};
  }
}

sub get_cache_size {
  return scalar(keys(%$__riken_EEDB_feature_global_id_cache));
}


#################################################
# Instance methods
#################################################

sub init {
  my $self = shift;
  $self->SUPER::init;
  
  $self->{'chrom_name'} = undef;  
  $self->{'assembly'} = undef;
  $self->{'chrom_length'} = undef;
  #$self->{'metadataset'} = new EEDB::MetadataSet;
  $self->{'strand'} = '';
  $self->{'primary_name'} = '';
  
  return $self;
}


##########################
#
# getter/setter methods of data which is stored in database
#
##########################

sub feature_source {
  my ($self, $source) = @_;
  if($source) {
    unless(defined($source) && $source->isa('EEDB::FeatureSource')) {
      die('feature_source param must be a EEDB::FeatureSource');
    }
    $self->{'feature_source'} = $source;
  }
  
  #lazy load from database if possible
  if(!defined($self->{'feature_source'}) and 
     defined($self->database) and 
     defined($self->{'_feature_source_id'}))
  {
    my $source = EEDB::FeatureSource->fetch_by_id($self->database, $self->{'_feature_source_id'});
    if(defined($source)) {
      $self->{'feature_source'} = $source;
    }
  }
  return $self->{'feature_source'};
}


sub chrom {
  my $self = shift;
  
  if(@_) { 
    my $chrom = shift;
    if(defined($chrom) && !$chrom->isa('EEDB::Chrom')) {
      die('chrom param must be a EEDB::Chrom');
    }
    $self->{'chrom'} = $chrom;
    $self->{'_chrom_id'} = undef;
    if($chrom) { $self->{'_chrom_id'} = $chrom->id; }
  }
  
  #lazy load from database if possible
  if(!defined($self->{'chrom'}) and 
     defined($self->database) and 
     defined($self->{'_chrom_id'}))
  {
    my $chrom = EEDB::Chrom->fetch_by_id($self->database, $self->{'_chrom_id'});
    if(defined($chrom)) {
      $self->{'chrom'} = $chrom;
    }
  }
  return $self->{'chrom'};
}

#####

sub chrom_name {
  my $self = shift;
  return $self->{'chrom_name'} = shift if(@_);
  if(defined($self->{'chrom_name'})) {
    return $self->{'chrom_name'}; 
  } elsif($self->chrom) { 
    return $self->chrom->chrom_name;
  } else { 
    return '';
  }
}

sub chrom_id {
  my $self = shift;
  return $self->{'_chrom_id'} = shift if(@_);
  if(defined($self->{'_chrom_id'})) {
    return $self->{'_chrom_id'};
  } elsif($self->chrom) { 
    return $self->chrom->id;
  } else { 
    return '';
  }
}

sub chrom_start {
  my $self = shift;
  return $self->{'chrom_start'} = shift if(@_);
  $self->{'chrom_start'}=-1 unless(defined($self->{'chrom_start'}));
  return $self->{'chrom_start'};
}

sub chrom_end {
  my $self = shift;
  return $self->{'chrom_end'} = shift if(@_);
  $self->{'chrom_end'}=-1 unless(defined($self->{'chrom_end'}));
  return $self->{'chrom_end'};
}

sub strand {
  #either '-' or '+'
  my $self = shift;
  my $strand = shift;
  if(defined($strand)) {
    if(($strand eq '-') or ($strand eq '+')) {
      $self->{'strand'} = $strand;
    } elsif($strand eq '1') {
      $self->{'strand'} = '+';
    } elsif($strand eq '-1') {
      $self->{'strand'} = '-';
    }
  }
  return $self->{'strand'};
}

sub chrom_location {
  my $self = shift;
  my $str = sprintf("%s:%d..%d%s", 
           $self->chrom_name,
           $self->chrom_start,
           $self->chrom_end,
           $self->strand);
  return $str;
}

sub primary_name {
  my $self = shift;
  return $self->{'primary_name'} = shift if(@_);
  $self->{'primary_name'}='' unless(defined($self->{'primary_name'}));
  return $self->{'primary_name'};
}

sub significance {
  my $self = shift;
  return $self->{'significance'} = shift if(@_);
  $self->{'significance'}=0 unless(defined($self->{'significance'}));
  return $self->{'significance'};
}

#
#################################################
#

sub metadataset {
  my $self = shift;
  $self->_load_metadata; #return if already loaded
  return $self->{'metadataset'};
}

sub add_symbol {
  my $self = shift;
  my $tag = shift;
  my $value = shift;
  $self->metadataset->add_tag_symbol($tag, $value);
}

sub add_data {
  my $self = shift;
  my $tag = shift;
  my $value = shift;
  $self->metadataset->add_tag_data($tag, $value);
}

sub find_symbol {
  my $self = shift;
  my $tag = shift;
  my $value = shift;
  return $self->metadataset->find_metadata($tag, $value);
}


#
#################################################
#

sub max_expression {
  my $self = shift;

  if(!defined($self->{'max_express'}) and ($self->database)) {
    $self->_get_max_expression();
  }
  return $self->{'max_express'};
}

sub sum_expression {
  my $self = shift;

  if(!defined($self->{'sum_express'}) and ($self->database)) {
    $self->_get_sum_expression();
  }
  return $self->{'sum_express'};
}

sub expression_cache {
  my $self = shift;
  if(!defined($self->{'expression_cache'})) {
    $self->{'expression_cache'}={};
    if($self->database) {
      my $express_array = EEDB::Expression->fetch_all_by_feature($self);
      foreach my $express (@$express_array) {
        $self->{'expression_cache'}->{$express->type . $express->experiment->id} = $express;
      }
    }
  }
  return $self->{'expression_cache'};
}

sub empty_expression_cache {
  my $self = shift;
  $self->{'expression_cache'} = undef;
  return 1;
}

#used for bulk storage system
sub add_expression {
  my $self = shift;
  my $express = shift;
  
  unless(defined($express) && $express->isa('EEDB::Expression')) {
    die('add_expression() param must be a EEDB::Expression');
  }
  $self->{'expression_cache'}->{$express->type . $express->experiment->id} = $express;
}

sub get_expression {
  my $self = shift;
  my $experiment = shift;  #EEDB::Experiment object
  my $type = shift;
  
  unless(defined($experiment) && $experiment->isa('EEDB::Experiment')) {
    die('get_expression() param 1 must be a EEDB::Experiment');
  }
  if(!defined($type)) { $type = ''; }
  return $self->expression_cache->{$type . $experiment->id};
}


sub find_expression {
  my $self = shift;
  my %options = @_; #like datatypes=>["tpm","raw"], experiments=>[$exp1, $exp2,$exp3]
    
  my $type_hash;
  my $exp_hash;
  
  if($options{'datatypes'}) {
    my @types = @{$options{'datatypes'}};
    foreach my $type (@types) { $type_hash->{$type} = 1; }
  }
  if($options{'experiments'}) {
    my @experiments = @{$options{'experiments'}};
    foreach my $exp (@experiments) { $exp_hash->{$exp->id} = 1; }
  }

  my @express_array = values %{$self->expression_cache};
  my @filter_express;
  foreach my $express (@express_array) {
    if($type_hash and $type_hash->{$express->type}) { push @filter_express, $express; }
    if($exp_hash  and $exp_hash->{$express->experiment->id}) { push @filter_express, $express; }
  }    
  return \@filter_express;
}


sub get_expression_array {
  my $self = shift;
  if(!defined($self->{'expression_cache'})) { return []; }
  my @exps = values %{$self->{'expression_cache'}};
  return \@exps;
}

sub add_expression_data {
  my $self = shift;
  my $experiment = shift;  #EEDB::Experiment object
  my $type = shift;
  my $value = shift;
  
  my $expression = $self->get_expression($experiment, $type);
  unless($expression) {
    $expression = new EEDB::Expression;
    $expression->feature($self);
    $expression->experiment($experiment);
    $expression->sig_error(0.0); #default
  }
  $expression->type($type);
  $expression->value($value);
  $self->add_expression($expression);
  return $expression;
}

#
#################################################
#

sub simple_display_desc {
  my $self = shift;
  
  my $str = sprintf("Feature(%s)", $self->id);
  if($self->feature_source) {
    $str .= sprintf(" %s", $self->feature_source->name);
  }
  if($self->chrom) {
    $str .= sprintf(" %s %s:%d..%d%s", 
           $self->chrom->assembly->ucsc_name,
           $self->chrom_name,
           $self->chrom_start,
           $self->chrom_end,
           $self->strand);
  }
  $str .= sprintf(" : %s", $self->primary_name);
  if($self->significance > 0.0) { $str .= sprintf(" sig:%1.2f", $self->significance); }
  return $str;
}

sub display_desc {
  my $self = shift;
  
  my $str = $self->simple_display_desc;
  
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
  my $fsrc = '';
  my $str = sprintf("Feature(%s)", $self->id);
  if($self->feature_source) {
    $str .= sprintf(" %s", $fsrc = $self->feature_source->name);
  }
  if($self->chrom) {
    $str .= sprintf(" %s %s:%d..%d%s", 
           $self->chrom->assembly->ucsc_name,
           $self->chrom_name,
           $self->chrom_start,
           $self->chrom_end,
           $self->strand);
  }
  $str .= sprintf(" : %s", $self->primary_name);
  
  if($self->significance > 0.0) { $str .= sprintf(" sig:%1.2f", $self->significance); }
  $str .= "\n". $self->metadataset->display_contents;   

  my $expr_array = $self->get_expression_array();
  foreach my $express (@$expr_array) {
    $str .= "  ". $express->display_desc ."\n";   
  }

  return $str;
}

sub xml {
  my $self = shift;
  
  my $str = $self->xml_start;

  $str .= "\n";
  $str .= "  " . $self->feature_source->xml if($self->feature_source);
  $str .= "  " . $self->chrom->assembly->xml if($self->chrom);
  $str .= $self->metadataset->xml;

  # display max_expression section if data is available
  my $maxexpress = $self->max_expression();
  if(defined($maxexpress)) {
    $str .= "  <max_expression>\n";
    foreach my $express (@$maxexpress) {
      $str .= sprintf("  <express platform=\'%s\'  maxvalue=\'%1.2f\'/>", $express->[0], $express->[1]);
    }
    $str .= "  </max_expression>\n";
  }           

  $str .= $self->xml_end;
  return $str;
}

sub xml_start {
  my $self = shift;
  
  my $str = sprintf("<feature id=\"%s\" desc=\"%s\" ", $self->id, $self->primary_name);
  if($self->database and $self->database->alias) { 
    $str .= sprintf("peer=\"%s\" ", $self->database->alias);
  }

  if($self->feature_source) {
    $str .= sprintf("fsrc=\"%s\" category=\"%s\" ",
                      $self->feature_source->name,
                       $self->feature_source->category);
  }
  if(defined($self->chrom)) {
    my $assembly = $self->chrom->assembly;
    $str .= sprintf(" taxon_id=\"%s\" ncbi_asm=\"%s\" asm=\"%s\" chr=\"%s\" start=\"%d\" end=\"%d\" strand=\"%s\" ",
                    $assembly->taxon_id,
                    $assembly->ncbi_version,
                    $assembly->ucsc_name,
                    $self->chrom_name,
                    $self->chrom_start,
                    $self->chrom_end,
                    $self->strand);
  }
  $str .= ">";
  return $str;
}

sub xml_end {
  my $self = shift;
  return "</feature>\n"; 
}

sub gff_description {
  my $self = shift;
  my $show_metadata = shift;
  
  my $str = sprintf("%s\t%s\t%s\t%d\t%d\t.\t%s\t.\t",
                    $self->chrom_name,
                    $self->feature_source->name,
                    $self->feature_source->category,
                    $self->chrom_start,
                    $self->chrom_end,
                    $self->strand);
                    
  my $metadata = sprintf("ID=\"%d\";Name=\"%s\";asm=\"%s\"", $self->id, $self->primary_name, $self->chrom->assembly->ucsc_name);
  if($show_metadata) {
    $metadata .= ";" . $self->metadataset->gff_description;
    unless($metadata) { $metadata = '.'; }
  }
  $str .= $metadata;
  
  return $str;
}

sub bed_description {
  my $self = shift;

  my $str = sprintf("%s\t%d\t%d\t%s\t%1.3f\t%s",
                    $self->chrom_name,
                    $self->chrom_start,
                    $self->chrom_end,
                    $self->primary_name,
                    $self->significance,
                    $self->strand);
  return $str;
}

sub dasgff_xml {
  my $self = shift;

#<FEATURE id="id" label="label">
#<TYPE id="id" category="category" reference="yes|no">type label</TYPE>
#<METHOD id="id"> method label </METHOD>
#<START> start </START>
#<END> end </END>
#<SCORE> [X.XX|-] </SCORE>
#<ORIENTATION> [0|-|+] </ORIENTATION>
#<PHASE> [0|1|2|-]</PHASE>
#<NOTE> note text </NOTE>
#<LINK href="url"> link text </LINK>
#<TARGET id="id" start="x" stop="y">target name</TARGET>
#<GROUP id="id" label="label" type="type">
#<NOTE> note text </NOTE>
#<LINK href="url"> link text </LINK>
#<TARGET id="id" start="x" stop="y">target name</TARGET>
#</GROUP>
#</FEATURE>

  my $str = sprintf("<FEATURE id=\"%d\" label=\"%s\">\n",
                    $self->id,
                    $self->primary_name);
  $str .= sprintf("<TYPE id=\"%d\" category=\"%s\" reference=\"no\">%s</TYPE>\n",
                    $self->feature_source->id,
                    $self->feature_source->category,
                    $self->feature_source->name);
  $str .= sprintf("<START>%d</START>\n", $self->chrom_start);
  $str .= sprintf("<END>%d</END>\n", $self->chrom_end);
  
  my $strand = $self->strand;
  if(($strand eq '') or !defined($strand)) { $strand = '0'; }
  $str .= sprintf("<ORIENTATION>%s</ORIENTATION>\n", $strand);

  $str .= sprintf("<PHASE>-</PHASE>\n");
  $str .= sprintf("<SCORE>%1.5f</SCORE>\n", $self->significance);
                    
  $str .= "</FEATURE>\n";
  return $str;
}



#
#################################################
#

sub check_overlap {
  my $self  = shift;
  my $other = shift;
  my $distance = shift;
  
  unless($other) { return 0; }
  if($other->chrom_id ne $self->chrom_id) { return 0; }
  unless($distance) { $distance = 0; }
  
  if(($self->chrom_start - $distance <= $other->chrom_end) and
     ($self->chrom_end + $distance >= $other->chrom_start)) { 
    return 1;
  }
  return 0;
}

sub overlap_expand {
  my $self  = shift;
  my $other = shift;
  
  if($self->check_overlap($other)) {
    if($other->chrom_start < $self->chrom_start) {
      $self->chrom_start($other->chrom_start);
    }
    if($other->chrom_end > $self->chrom_end) {
      $self->chrom_end($other->chrom_end);
    }
    return 1;
  }
  return 0;
}

#################################################
#
# pure object-oriented edge management system
# created double references so perl's memory
# management system will not auto-release memory
# user must make explicit call clear_edges() 
# before unref-ing the object
#
#################################################

sub clear_edges {
  my $self = shift;
  $self->{'_left_links'} = undef;
  $self->{'_right_links'} = undef;  
}

sub left_edges {
  my $self = shift;
  
  if(!defined($self->{'_left_links'})) {
    my $edges = EEDB::Edge->fetch_all_to_feature_id($self->database, $self->id);
    $self->{'_left_links'} = EEDB::EdgeSet->new('larray' => $edges);
  }
  return $self->{'_left_links'};
}

sub right_edges {
  my $self = shift;
  
  if(!defined($self->{'_right_links'})) {
    my $edges = EEDB::Edge->fetch_all_from_feature_id($self->database, $self->id);
    $self->{'_right_links'} = EEDB::EdgeSet->new('larray' => $edges);
  }
  return $self->{'_right_links'};
}

sub all_edges {
  my $self = shift;
  
  my $lset = new EEDB::EdgeSet;
  $lset->add_edges($self->left_edges->edges);
  $lset->add_edges($self->right_edges->edges);
  return $lset;
}

#################################################
#
# routine to combine sequences from multiple chunks 
# if the requested region is >5kb overlap on 
# the ChromChunks
#
#################################################

sub get_bioseq {
  my $self = shift;
  my $seqdb = shift;
  my $downstream = shift; ## optional
  my $upstream = shift; ## optional

  ## no bioseq if no seqdb
  die "EEDB::Feature::get_bioseq : not a valid seqdb\n" unless(defined($seqdb) && $seqdb->isa('MQdb::Database'));

  ## no bioseq if no coordinates
  die "EEDB::Feature::get_bioseq : no bioseq retrievable without coordinates\n" unless ((defined $self->chrom) and ($self->chrom_start >0) and ($self->chrom_end >0));

  ## get the end points of the seq to be retrieved
  ## ... check that downstream and upstream args do not violate chrom boundaries (rmk: as dedfined in the feature db, not the seqdb)
  my $asm_name =  $self->chrom->assembly->ucsc_name;
  my $chrom_name = $self->chrom->chrom_name;
  my $chrom_start = ($downstream) ? $self->chrom_start - $downstream : $self->chrom_start;
  my $chrom_end   = ($upstream)   ? $self->chrom_end   + $upstream   : $self->chrom_end;
  my $strand = $self->strand;
  die "EEDB::Feature::get_bioseq : downstream arg violates chrom boundaries, max downstream possible is ", $self->chrom_start -1,"\n" if ($chrom_start < 1); ## check with Jess for 1-base / 0-base coord
  die "EEDB::Feature::get_bioseq : upstream arg violates chrom boundaries, max upstream possible is ", $self->chrom->chrom_length - $self->chrom_end, "\n" if ($chrom_end > $self->chrom->chrom_length);


  ## compose a name based on feature information
  my $bioseq_name = sprintf("feature_%d_%s_%s:%d..%d%s", ($self->id)?$self->id:'0', ($self->primary_name)?$self->primary_name:'', $chrom_name, $chrom_start, $chrom_end, $strand);
  my $bioseq = Bio::Seq->new(-id => $bioseq_name);

  ## get the chunks (in seqdb)
  my @chunks = @{EEDB::ChromChunk->fetch_all_named_region($seqdb, $asm_name, $chrom_name, $chrom_start, $chrom_end)};

  ## die if no chunk
  ## this should only happened if something is utterly wrong with the db
  if    (scalar @chunks == 0){
    die "EEDB::Feature::get_bioseq : no chunks for \n\t", join("\n\t", $seqdb->url, $asm_name, $chrom_name, $chrom_start, $chrom_end),"\n";
  }

  ## get the seq from EEDB::ChromChunk::get_subsequence and assign it to the bioseq to be returned
  ## EEDB::ChromChunk::get_subsequence uses BioSeq to effectively return the revcomp when minus strand
  elsif (scalar @chunks == 1){
    $bioseq->seq($chunks[0]->get_subsequence($chrom_start, $chrom_end, $strand)->seq);
  }

  ## more than one chunk requires to concat subsequences of all the chunks
  ## concat the plus strand subsequnces from `feature_start`/`chunk_start` to `next_chunk_start -1`/`feature_end`
  ## use bioseq->revcomp if feature_strand is minus
  else                       {
    my $seq;
    @chunks = sort {$a->chrom_start <=> $b->chrom_start} @chunks;
    for (my $i = 0; $i < scalar @chunks; $i++){
      my $start = ($chrom_start >= $chunks[$i]->chrom_start) ?  $chrom_start : $chunks[$i]->chrom_start;
      my $end   = ($chunks[$i+1]) ? ($chrom_end > $chunks[$i+1]->chrom_start) ? $chunks[$i+1]->chrom_start -1 : $chrom_end : $chrom_end;
      $seq .= $chunks[$i]->get_subsequence($start, $end)->seq if ($end > $start);
    }
    $bioseq->seq($seq);
    $bioseq = $bioseq->revcom if ($strand eq '-');
  }
  return $bioseq;
}

#################################################
#
# MappedQuery override methods - storage
#
#################################################

sub store {
  my $self = shift;
  my $db   = shift;
  
  if($db) { $self->database($db); }
  my $dbh = $self->database->get_connection;  
  
  my $chrom_id = $self->chrom_id;
  if($chrom_id eq '') { $chrom_id = undef; }
  
  my $sql = "INSERT INTO feature (
                feature_source_id,
                chrom_id,                
                chrom_start,
                chrom_end,
                strand,
                significance,
                primary_name)
             VALUES(?,?,?,?,?,?,?)";
  my $sth = $dbh->prepare($sql);
  $sth->execute($self->feature_source->id,
                $chrom_id,
                $self->chrom_start,
                $self->chrom_end,
                $self->strand,
                $self->significance,
                $self->primary_name);

  my $dbID = $dbh->last_insert_id(undef, undef, qw(feature feature_id));
  $sth->finish;
  return undef unless($dbID);
  $self->primary_id($dbID);
  
  #now do the symbols and metadata  
  $self->store_metadata;

  #link to chunk system
  $self->link_2_chunk();
  
  return $self;
}

sub store_metadata {
  my $self = shift;
  die("error no database to store metadata\n") unless($self->database);
  return unless($self->{'metadataset'}); #if not created then don't lazy load
  
  my $mdata_list = $self->metadataset->metadata_list;
  foreach my $mdata (@$mdata_list) {
    if(!defined($mdata->primary_id)) {
      $mdata->store($self->database);
      $mdata->store_link_to_feature($self);
    }
  }
}

sub create_link_to_feature {
  my $self = shift;
  my $feature = shift;
  my $link_type = shift;
  my $dir = shift;
  my $weight = shift;

  die("error no database to store symbol\n") unless($self->database);

  #first do insert ignore to make sure symbol is in the database
  my $dbc = $self->database->get_connection;  
  my $sql = "INSERT ignore INTO edge ".
            "(feature1_id, feature2_id, direction, sub_type, weight, edge_source_id) VALUES(?,?,?,?,?,0)";
  my $sth = $dbc->prepare($sql);
  $sth->execute($self->id, $feature->id, $dir, $link_type, $weight);
  $sth->finish;
}

sub update_location {
  my $self = shift;

  die("error no database set\n") unless($self->database);
  dies("Feature with undef id") unless(defined($self->primary_id));
  
  my $chrom_id = undef;
  if($self->chrom) { $chrom_id = $self->chrom_id; }

  my $sql = "UPDATE feature SET primary_name=?, chrom_id=?, chrom_start=?, chrom_end=?, strand=? WHERE feature_id=?";
  $self->database->execute_sql($sql,
                $self->primary_name,
                $chrom_id,
                $self->chrom_start,
                $self->chrom_end,
                $self->strand,
                $self->id);
  $self->link_2_chunk();
}


#################################################
#
# MappedQuery override methods - fetching
#
#################################################


sub mapRow {
  my $self = shift;
  my $rowHash = shift;
  my $dbh = shift;

  my $dbID = $rowHash->{'feature_id'};
  if(($__riken_EEDB_feature_global_should_cache != 0) and ($self->database())) {
    my $cached_self = $__riken_EEDB_feature_global_id_cache->{$self->database() . $dbID};
    if(defined($cached_self)) { 
      #printf("link already loaded in cache, reuse\n");
      #$cached_self->display_info;
      #printf("   db_id :: %s\n", $cached_self->db_id);
      return $cached_self; 
    }
  }

  $self->{'_primary_db_id'} = $rowHash->{'feature_id'};
  $self->{'chrom_name'}     = $rowHash->{'chrom_name'};
  $self->{'chrom_start'}    = $rowHash->{'chrom_start'};
  $self->{'chrom_end'}      = $rowHash->{'chrom_end'};
  $self->{'strand'}         = $rowHash->{'strand'};
  $self->{'primary_name'}   = $rowHash->{'primary_name'};
  $self->{'significance'}   = $rowHash->{'significance'};

  $self->{'_chrom_id'} = $rowHash->{'chrom_id'};
  $self->{'_feature_source_id'} = $rowHash->{'feature_source_id'};

  if($rowHash->{'symbol_count'}) {
    if($self->{'significance'}) {
      $self->{'significance'} = $self->{'significance'} * $rowHash->{'symbol_count'};
    } else {
      $self->{'significance'} = $rowHash->{'symbol_count'};
    }
  }
  
  if(($__riken_EEDB_feature_global_should_cache != 0) and ($self->database())) {
    $__riken_EEDB_feature_global_id_cache->{$self->database() . $self->id} = $self;
  }

  return $self;
}

###############################################################################################
#
# object fetch API section
#
###############################################################################################

sub fetch_by_id {
  my $class = shift;
  my $db = shift;
  my $id = shift;

  if($__riken_EEDB_feature_global_should_cache != 0) {
    my $feature = $__riken_EEDB_feature_global_id_cache->{$db . $id};
    if(defined($feature)) { return $feature; }
  }
  my $sql = "SELECT f.* FROM feature f WHERE feature_id=?";
  return $class->fetch_single($db, $sql, $id);
}


sub fetch_all_by_id_list {
  my $class = shift;
  my $db = shift;
  my $id_list = shift;

  my $sql = sprintf("SELECT * FROM feature WHERE feature_id in(%s)", $id_list);
  return $class->fetch_multiple($db, $sql);
}


sub fetch_all_neighbors {
  my $class = shift;
  my $db = shift;
  my $id = shift;
  
  my $sql = "SELECT f.* FROM feature f JOIN ".
            " (SELECT feature2_id feature_id FROM edge WHERE feature1_id =?
               UNION SELECT feature1_id feature_id FROM edge where feature2_id =?)t using(feature_id)";
  return $class->fetch_multiple($db, $sql, $id);
}

=head2 fetch_all_by_chrom

  Description     : uses an EEDB::Chrom object to stream all features in sorted order by chrom start,end
  Parameter[1]    : EEDB::Chrom object with database connection 
  Parameter[2...] : optional EEDB::FeatureSource(s) to limit the feature stream
  Returntype      : array reference of EEDB::Feature objects 
  Exceptions      : die if anything other than EEDB::FeatureSource(s) are passed in the optional parameter list

=cut

sub fetch_all_by_chrom {
  my $class = shift;
  my $chrom = shift; #Chrom object
  my @sources = @_; #(optional) FeatureSource object(s)

  if(!defined($chrom) or !defined($chrom->database)) { return []; }
  if(!($chrom->isa('EEDB::Chrom'))) {
    die('fetch_all_by_chrom: param1 must be a EEDB::Chrom');
  }
  
  my @fsrc_ids;
  foreach my $fsrc (@sources) {
    next unless(defined($fsrc));
    if(!($fsrc->isa('EEDB::FeatureSource'))) {
      die('[source] must be a EEDB::FeatureSource');
    }
    push @fsrc_ids, $fsrc->id; 
  }  
  
  my $sql = sprintf("SELECT * FROM feature WHERE chrom_id=%d ", $chrom->id);
  $sql .= "AND feature_source_id in(" . join(',', @fsrc_ids) . ") " if(@fsrc_ids);
  $sql .= "ORDER BY chrom_start, chrom_end";  
  return $class->fetch_multiple($chrom->database, $sql);
}


sub fetch_all_by_chrom_chunk_id {
  my $class = shift;
  my $db = shift;
  my $id = shift;
  
  my $sql = "SELECT * FROM feature ".
            "JOIN feature_source using(feature_source_id) ".
            "JOIN chrom using(chrom_id) ".
            "JOIN feature_2_chunk using(feature_id) ".
            "WHERE chrom_chunk_id = ? ORDER BY chrom_start";
  return $class->fetch_multiple($db, $sql, $id);
}


sub fetch_all_within_region {
  #does a search for features completely contained within the specified region
  my $class = shift;
  my $db = shift;
  my $chrom_chunk_id = shift;
  my $chrom_start = shift;
  my $chrom_end = shift;
  
  my $sql = "SELECT * FROM feature JOIN feature_source using(feature_source_id) JOIN chrom using(chrom_id) JOIN feature_2_chunk using(feature_id) ".
            "WHERE chrom_chunk_id = ? AND chrom_start >= ? AND chrom_end <= ? ".
            "ORDER BY chrom_start";
  return $class->fetch_multiple($db, $sql, $chrom_chunk_id, $chrom_start, $chrom_end);
}


sub fetch_all_overlapping_region {
  #does a search for features which overlap with the specified region
  my $class = shift;
  my $db = shift;
  my $chrom_chunk_id = shift;
  my $chrom_start = shift;
  my $chrom_end = shift;
  
  my $sql = "SELECT * FROM feature JOIN feature_source using(feature_source_id) JOIN chrom using(chrom_id) JOIN feature_2_chunk using(feature_id) ".
            "WHERE chrom_chunk_id = ? AND chrom_start <= ? AND chrom_end >= ? ".
            "ORDER BY chrom_start";
  return $class->fetch_multiple($db, $sql, $chrom_chunk_id, $chrom_end, $chrom_start);
}


sub fetch_all_named_region {
  my $class = shift;
  my $db = shift;
  my $assembly_name = shift;
  my $chrom_name = shift;
  my $chrom_start = shift;
  my $chrom_end = shift;
  my @sources = @_; #(optional) FeatureSource(s) objects

  #printf("fetch_all_named_region %s : %d .. %d\n", $chrom_name, $chrom_start, $chrom_end);
  my $chunks = EEDB::ChromChunk->fetch_all_named_region($db, $assembly_name, $chrom_name, $chrom_start, $chrom_end);
  return [] unless(defined($chunks) and scalar(@$chunks)>0);

  my @chunk_ids;
  foreach my $chunk (@$chunks) { push @chunk_ids, $chunk->id; }
    
  my @fsrc_ids;
  foreach my $fsrc (@sources) {
    next unless(defined($fsrc));
    if(!($fsrc->isa('EEDB::FeatureSource'))) {
      die('[source] must be a EEDB::FeatureSource');
    }
    push @fsrc_ids, $fsrc->id; 
  }
  
  my $sql = "SELECT f.* FROM feature f JOIN ".
            "(select distinct feature_id FROM feature_2_chunk ".
            " WHERE chrom_chunk_id in (". join(",", @chunk_ids). ")".
            ")fc using(feature_id)".
            "WHERE chrom_start <= " .$chrom_end. " AND chrom_end >= " .$chrom_start. " ";
  $sql .=   "AND feature_source_id in(" . join(',', @fsrc_ids) . ") " if(@fsrc_ids);
  $sql .=   "ORDER BY chrom_start, chrom_end, f.feature_id";
  
  #print($sql, "\n");
  return $class->fetch_multiple($db, $sql);
}


sub fetch_all_chrom_region {
  my $class = shift;
  my $db = shift;
  my $chrom = shift; #Chrom object
  my $chrom_start = shift;
  my $chrom_end = shift;

  my $sql = "SELECT f.* FROM feature f ".
            "JOIN feature_source using(feature_source_id) ".
            "WHERE chrom_id =? ".
            "AND chrom_start <= ? AND chrom_end >= ? ".
            "ORDER BY chrom_start";
  return $class->fetch_multiple($db, $sql, $chrom->id, $chrom_end, $chrom_start);
}


sub fetch_all_by_source {
  my $class = shift;
  my $db = shift;
  my $source = shift; #FeatureSource object

  my $sql = "SELECT * FROM feature WHERE feature_source_id=? ";
  return $class->fetch_multiple($db, $sql, $source->id);
}


sub fetch_all_by_primary_name {
  my $class = shift;
  my $db = shift;
  my $primary_name = shift; 
  my $source = shift; #FeatureSource object / optional
  
  my $sql = "SELECT * FROM feature WHERE primary_name=? ";
  if(defined($source)) {
    $sql .= sprintf("AND feature_source_id=%d", $source->id);
  }  
  #"WHERE feature_source_id=? and primary_name like '\%". $primary_name ."\%' ORDER BY chrom_start";
  #print($sql, "\n");            
  return $class->fetch_multiple($db, $sql, $primary_name);
}

sub fetch_all_by_source_symbol {
  my $class = shift;
  my $db = shift;
  my $source = shift; #FeatureSource object
  my $sym_value = shift; 
  my $sym_type = shift; #optional
  my $response_limit = shift; #optional
  
  return [] unless(defined($sym_value));
  
  $sym_value =~ s/\"/\\\"/g; 
  $sym_value =~ s/\'/\\\'/g;  #'

  my $sql = sprintf("SELECT * from ".
                    "(SELECT f.* FROM feature f ".
                    "JOIN feature_2_symbol using(feature_id)  ".
                    "JOIN symbol using(symbol_id) ".
                    "WHERE sym_value = \"%s\"", 
                    $sym_value);
  if(defined($sym_type)) {
    $sql .= sprintf(" AND sym_type='%s'", $sym_type);
  }
  $sql .= " )t ";
  if(defined($source)) {
    $sql .= sprintf(" WHERE feature_source_id=%d", $source->id);
  }
  $sql .= sprintf(" GROUP BY feature_id");
  if($response_limit) {
    $sql .= sprintf(" LIMIT %d", $response_limit);
  }

  #print($sql, "\n", );
  return $class->fetch_multiple($db, $sql);
}


sub fetch_all_symbol_search {
  my $class = shift;
  my $db = shift;
  my $source = shift; #FeatureSource object
  my $sym_value = shift; 
  my $sym_type = shift; #optional
  my $response_limit = shift; #optional
  
  if(defined($source) && !($source->isa('EEDB::FeatureSource'))) {
    die('second parameter [source] must be a EEDB::FeatureSource');
  }

  $sym_value =~ s/\"/\\\"/g; 
  $sym_value =~ s/\'/\\\'/g;  #'

  my $sql = sprintf("SELECT * from ".
                    "(SELECT f.* FROM feature f ".
                    "JOIN feature_2_symbol using(feature_id)  ".
                    "JOIN symbol using(symbol_id) ".
                    "WHERE sym_value like \"%s%%\"", 
                    $sym_value);
  if(defined($sym_type)) {
    $sql .= sprintf(" AND sym_type='%s'", $sym_type);
  }
  $sql .= " )t ";
  if(defined($source)) {
    $sql .= sprintf(" WHERE feature_source_id=%d", $source->id);
  }
  $sql .= sprintf(" GROUP BY feature_id");

  #print($sql, "\n", );      
  return $class->fetch_multiple($db, $sql);
}


sub fetch_all_keyword_search {
  my $class = shift;
  my $db = shift;
  my $keywords = shift;
  my $response_limit = shift; #optional
  my @sources = @_; #(optional) FeatureSource(s) objects
    
  my @fsrc_ids;
  foreach my $fsrc (@sources) {
    next unless(defined($fsrc));
    if(!($fsrc->isa('EEDB::FeatureSource'))) {
      die('[source] must be a EEDB::FeatureSource');
    }
    push @fsrc_ids, $fsrc->id; 
  }

  my @where_clauses;
  my @keyword_array = split (/\s+/, $keywords);
  foreach my $tok (@keyword_array) {
    $tok =~ s/^\s+//g;
    $tok =~ s/\s+$//g;
    if(length($tok) < 3) { next; }
    
    $tok =~ s/_/\\_/g;
    $tok =~ s/\"/\\\"/g; 
    $tok =~ s/\'/\\\'/g;  #'
    push @where_clauses, sprintf("sym_value like \"%s%%\"", $tok); 
  }
  if(scalar(@where_clauses) == 0) { return []; }
  
  my $sql = "SELECT f.*, count(*) symbol_count FROM ".
            "feature_source join feature f using(feature_source_id) ".
            "JOIN feature_2_symbol using(feature_id)  ".
            "JOIN symbol using(symbol_id) WHERE is_active='y' and (";
  $sql .= join(" or ", @where_clauses) . ") ";
  $sql .=  "AND feature_source_id in(" . join(',', @fsrc_ids) . ") " if(@fsrc_ids);
  $sql .= " GROUP BY f.feature_id";
  $sql .= " ORDER BY symbol_count desc";
  if($response_limit) { $sql .= sprintf(" LIMIT %d", $response_limit); }

  print($sql, "\n", );      
  return $class->fetch_multiple($db, $sql);
}


sub get_count_symbol_search {
  my $class = shift;
  my $db = shift;
  my $sym_value = shift; 
  my $sym_type = shift; #optional
  
  $sym_value =~ s/\"/\\\"/g; 
  $sym_value =~ s/\'/\\\'/g;  #'

  my $sql = sprintf("select count(distinct feature_id) from symbol join feature_2_symbol using(symbol_id) WHERE sym_value like '%s'", $sym_value);
  if(defined($sym_type)) {
    $sql .= sprintf(" AND sym_type='%s'", $sym_type);
  }
  return $class->fetch_col_value($db, $sql);
}

sub fetch_all_with_data {
  my $class = shift;
  my $db = shift;
  my $data = shift; #metadata.data
  my $data_type = shift; #optional
  my $source = shift; #optional FeatureSource object

  my $sql = "SELECT f.* from metadata m JOIN feature_2_metadata using(metadata_id) ".
            "JOIN feature f using(feature_id) ".
            "WHERE m.data=?";
  if(defined($data_type)) {
    $sql .= sprintf(" AND m.data_type='%s'", $data_type);
  }
  if(defined($source)) {
    $sql .= sprintf("AND feature_source_id=%d", $source->id);
  }
  #print($sql, "\n", );      
  return $class->fetch_multiple($db, $sql, $data);
}


sub fetch_all_with_metadata {
  my $class = shift;
  my $source = shift; #FeatureSource object uses database of source for fetching
  my @mdata_array = @_; #Metadata objects
  
  if(defined($source) && !($source->isa('EEDB::FeatureSource'))) {
    die('second parameter [source] must be a EEDB::FeatureSource');
  }
  
  if(!defined($source->database) or !defined($source->primary_id)) { return []; }
  
  my @mdata_ids;
  foreach my $mdata (@mdata_array) {
    unless(defined($mdata) && $mdata->isa('EEDB::Metadata')) {
      die("$mdata is not a EEDB::Metadata");
    }
    if(defined($mdata->primary_id)) {push @mdata_ids, $mdata->id; }
  }
  if(scalar(@mdata_ids) == 0) { return []; } #if mdata objects not stored then return []
    
  my $sql = sprintf("SELECT f.* FROM feature f JOIN feature_2_metadata using(feature_id) WHERE metadata_id in(%s) ",
                   join(',', @mdata_ids));
  $sql .= sprintf(" AND feature_source_id=%d", $source->id);

  #print($sql, "\n", );
  return $class->fetch_multiple($source->database, $sql);
}

sub fetch_all_with_symbol {
  my $class = shift;
  my $db = shift;
  my $source = shift; #FeatureSource object
  my $symbol = shift; #Symbol object
  my $response_limit = shift; #optional
  
  unless(defined($source) && $source->isa('EEDB::FeatureSource')) {
    die('second parameter [source] must be a EEDB::FeatureSource');
  }
  unless(defined($symbol) && $symbol->isa('EEDB::Symbol')) {
    die('third parameter [symbol] must be a EEDB::Symbol');
  }

  my $sql = sprintf("SELECT f.* FROM feature f ".
                    "JOIN feature_2_symbol using(feature_id)  ".
                    "WHERE symbol_id = %d ", 
                    $symbol->id);
  if(defined($source)) {
    $sql .= sprintf("AND feature_source_id=%d", $source->id);
  }
  $sql .= sprintf(" GROUP BY feature_id");
  if($response_limit) {
    $sql .= sprintf(" LIMIT %d", $response_limit);
  }

  #print($sql, "\n", );
  return $class->fetch_multiple($db, $sql);
}


#does a multi-symbol search, all symbols must be linked to the feature
sub fetch_all_with_symbols {
  my $class = shift;
  my $db = shift;
  my $source = shift; #FeatureSource object
  my @symbols = @_; #Symbol objects
  
  if(defined($source) && !($source->isa('EEDB::FeatureSource'))) {
    die('second parameter [source] must be a EEDB::FeatureSource');
  }
  
  my @symbol_ids;
  foreach my $symbol (@symbols) {
    unless(defined($symbol) && $symbol->isa('EEDB::Symbol')) {
      die("$symbol is not a EEDB::Symbol");
    }
    push @symbol_ids, $symbol->id;
  }
    
  my $sql = sprintf("SELECT f.* FROM feature f, ".
                    "(select feature_id, count(*) cnt from feature_2_symbol where symbol_id in(%s) ".
                    " group by feature_id)t where cnt=%d and f.feature_id = t.feature_id ", 
                   join(',', @symbol_ids),
                   scalar(@symbol_ids)
                   );
  if(defined($source)) {
    $sql .= sprintf(" AND feature_source_id=%d", $source->id);
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

  Description: stream all features out of database with a given set of source filters
  Arg (1)    : $database (MQdb::Database)
  Arg (2...) : hash named filter parameters. 
                 sources=>[$fsrc1, $fsrc2,$fsrc3],  instances of EEDB::FeatureSource
  Returntype : a DBStream instance
  Exceptions : none 

=cut

sub stream_all {
  my $class = shift;
  my $db = shift;  #database
  my %options = @_;  #like sources=>[$fsrc1, $fsrc2,$fsrc3]
    
  return [] unless($db);

  my @sources = @{$options{'sources'}} if($options{'sources'});
  
  my @fsrc_ids;
  foreach my $source (@sources) {
    next unless($source);
    if($source->class eq 'FeatureSource') { push @fsrc_ids, $source->id; }
  }
 
  my $sql = "SELECT * FROM feature f WHERE 1=1 ";
  if(@fsrc_ids) { $sql .= sprintf(" AND feature_source_id in(%s) ", join(',', @fsrc_ids)); }
  $sql .= " ORDER BY chrom_id, chrom_start, chrom_end, feature_id";
  #print($sql, "\n");
  return $class->stream_multiple($db, $sql);
}


=head2 stream_by_chrom

  Description     : uses an EEDB::Chrom object to stream all features in sorted order by chrom start,end
                    Useful for feeding features into EEDB::Tools::OverlapCompare2
  Arg [1]         : EEDB::Chrom object with database connection 
  Arg (2...)      : hash named filter parameters. 
                      sources=>[$fsrc1, $fsrc2,$fsrc3],  instances of EEDB::FeatureSource
  Returntype      : MQdb::DBStream object 
  Exceptions      : die if anything other than EEDB::FeatureSource(s) are passed in the optional parameter list
  Example         :   
                    my $chroms = EEDB::Chrom->fetch_all_by_assembly($assembly);
                    foreach my $chrom (@$chroms) {
                      my $stream  = EEDB::Feature->stream_by_chrom($chrom, sources=>[$fsrc1, $fsrc2]);
                      my $feature1 = $stream1->next_in_stream;
                      while($feature1) {
                        #do something
                        $feature1 = $stream1->next_in_stream;
                      }
                    }

=cut

sub stream_by_chrom {
  my $class = shift;
  my $chrom = shift;  #Chrom object with database
  my %options = @_;   #like sources=>[$fsrc1, $fsrc2,$fsrc3]
  
  return undef unless($chrom and $chrom->database);
  my $db = $chrom->database;
  
  my @sources = @{$options{'sources'}} if($options{'sources'});
  
  my @fsrc_ids;
  foreach my $source (@sources) {
    next unless($source);
    if($source->class eq 'FeatureSource') { push @fsrc_ids, $source->id; }
  }
  
  my $sql = sprintf("SELECT * FROM feature f WHERE chrom_id=%d", $chrom->id);
  if(@fsrc_ids) { $sql .= sprintf(" AND feature_source_id in(%s) ", join(',', @fsrc_ids)); }
  $sql .= " ORDER BY chrom_start, chrom_end, feature_id";
  #print($sql, "\n");
  return $class->stream_multiple($db, $sql);
}


=head2 stream_by_named_region

  Description: stream all features from a specific region on a genome
               with a given set of source filters
  Arg (1)    : $database (MQdb::Database)
  Arg (2)    : $assembly_name (string)
  Arg (3)    : $chrom_name (string)
  Arg (4)    : $chrom_start (integer)
  Arg (5)    : $chrom_end (integer)
  Arg (6...) : hash named filter parameters. 
                 sources=>[$fsrc1, $fsrc2,$fsrc3],  instances of EEDB::FeatureSource
  Returntype : a DBStream instance
  Exceptions : none 

=cut

sub stream_by_named_region {
  #returns an array of Expression objects, but the Feature object has been prebuilt, 
  #so a lazy-load does not need to occur
  my $class = shift;
  my $db = shift;
  my $assembly_name = shift;
  my $chrom_name = shift;
  my $chrom_start = shift;
  my $chrom_end = shift;
  my %options = @_;  #like sources=>[$fsrc1, $fsrc2,$fsrc3]

  my @sources = @{$options{'sources'}} if($options{'sources'});
  
  my @fsrc_ids;
  foreach my $source (@sources) {
    next unless($source);
    if($source->class eq 'FeatureSource') { push @fsrc_ids, $source->id; }
  }

  #printf("fetch_all_named_region %s : %d .. %d\n", $chrom_name, $chrom_start, $chrom_end);
  my $chrom = EEDB::Chrom->fetch_by_name($db, $assembly_name, $chrom_name);
  if(defined($chrom_start) and defined($chrom_end)) {
    my $chunks = EEDB::ChromChunk->fetch_all_named_region($db, $assembly_name, $chrom_name, $chrom_start, $chrom_end);
    return [] unless(defined($chunks) and scalar(@$chunks)>0);
    my @chunk_ids;
    foreach my $chunk (@$chunks) { push @chunk_ids, $chunk->id; }  

    my $sql="";
    if(scalar(@$chunks) < 10) {
      $sql = "SELECT * from ";
      $sql .=  "(SELECT f.* FROM feature f JOIN ".
                  "(select distinct feature_id FROM feature_2_chunk ".
                  " WHERE chrom_chunk_id in (". join(",", @chunk_ids). ")".
                  ")fc using(feature_id)".
                  "WHERE chrom_start <= ". $chrom_end ." AND chrom_end >= ". $chrom_start . " ";
      $sql .=     "AND feature_source_id in(" . join(',', @fsrc_ids) . ") " if(@fsrc_ids);
      $sql .=  ")f ";
      $sql .=  "WHERE 1=1";
      if(@fsrc_ids) { $sql .= sprintf(" AND feature_source_id in(%s) ", join(',', @fsrc_ids)); }
      $sql .= " ORDER BY chrom_start, chrom_end, f.feature_id";
      return $class->stream_multiple($db, $sql);
    }
  }
  
  my $sql = "SELECT * from feature f WHERE chrom_id =" . $chrom->id;
  if(defined($chrom_start) and defined($chrom_end)) { 
    $sql .= " AND chrom_start <= ". $chrom_end ." AND chrom_end >= ". $chrom_start; 
  }
  if(@fsrc_ids) { $sql .= " AND feature_source_id in(" . join(',', @fsrc_ids) . ") "; }
  $sql .= " ORDER BY chrom_start, chrom_end, f.feature_id";
  
  #print($sql, "\n");
  return $class->stream_multiple($db, $sql);
}

=head2 stream_all_by_source

  Description: stream all features from a single FeatureSource
  Arg (1)    : $sourcedatabase (EEDB::FeatureSource with database)
  Returntype : a DBStream instance
  Exceptions : none 
  Comments   : this is an older API method and despite being simple and fast
               the stream_all() method now replaces this call.  It may be 
               deprecated in the near future.

=cut

sub stream_all_by_source {
  my $class = shift;
  my $source = shift; #FeatureSource object with database connection
  
  return undef unless($source and $source->database);

  my $sql = "SELECT * FROM feature WHERE feature_source_id=? ";
  return $class->stream_multiple($source->database, $sql, $source->id);
}


###############################################################################################
#
# internal methods
#
###############################################################################################

sub _load_metadata {
  my $self = shift;
  
  return if(defined($self->{'metadataset'}));
  $self->{'metadataset'} = new EEDB::MetadataSet;

  return unless($self->database); #not connected yet so can't load
  my $symbols = EEDB::Symbol->fetch_all_by_feature_id($self->database, $self->id);
  $self->{'metadataset'}->add_metadata(@$symbols);

  my $mdata = EEDB::Metadata->fetch_all_by_feature($self);
  $self->{'metadataset'}->add_metadata(@$mdata);
}


sub link_2_chunk {
  my $self = shift;
  return undef if(($self->chrom_start == -1) or ($self->chrom_end == -1));
  my $sql ="INSERT ignore into feature_2_chunk ".
           "SELECT feature_id, chrom_chunk_id from chrom_chunk c, feature f ".
           "WHERE f.chrom_id=c.chrom_id and c.chrom_start<=f.chrom_end and c.chrom_end>=f.chrom_start and f.feature_id=?";
  $self->database->execute_sql($sql, $self->id);           
}

sub _get_max_expression {
  my $self = shift;
  
  my $sql ="SELECT platform, max(express)  FROM (".
           "SELECT platform, max(value) express ".
           "FROM experiment ".
           "JOIN expression using (experiment_id) ".
           "JOIN expression_datatype using(datatype_id) ".
           "WHERE feature_id = ? and sig_error >=0.99 and datatype='norm' group by platform ".
           "UNION ".
           "SELECT platform, max(value) express ".
           "FROM edge ".
           "JOIN edge_source fls using(edge_source_id) ".
           "JOIN expression on(feature_id=feature1_id) ".
           "JOIN experiment e using (experiment_id) ".
           "JOIN expression_datatype on(expression.datatype_id = expression_datatype.datatype_id) ".
           "WHERE feature2_id = ? and sig_error >=0.99 and datatype='norm' and e.is_active='y' and fls.is_active='y' group by platform ".
           ")t group by platform";

  my $dbc = $self->database->get_connection;
  my $sth = $dbc->prepare($sql);
  $sth->execute($self->primary_id, $self->primary_id);
  while(my ($platform, $max_express) = $sth->fetchrow_array) {
    if(!defined($self->{'max_express'})) { $self->{'max_express'} = []; }
    push @{$self->{'max_express'}}, [$platform, $max_express];
  }
}

sub _get_sum_expression {
  my $self = shift;
  
  my $sql ="SELECT platform, max(express)  FROM (".
           "SELECT platform, sum(value) express ".
           "FROM edge ".
           "JOIN edge_source fls using(edge_source_id) ".           
           "JOIN expression on(feature_id=feature1_id) ".
           "JOIN experiment e using (experiment_id) ".
           "WHERE feature2_id = ? and sig_error >=0.99 and e.is_active='y' and fls.is_active='y' group by platform ".
           "UNION ".
           "SELECT platform, sum(value) express ".
           "FROM expression ".
           "JOIN experiment using (experiment_id) ".
           "WHERE feature_id = ? and sig_error >=0.99 group by platform ".
           ")t group by platform";

  my $dbc = $self->database->get_connection;
  my $sth = $dbc->prepare($sql);
  $sth->execute($self->primary_id, $self->primary_id);
  while(my ($platform, $sum_express) = $sth->fetchrow_array) {
    if(!defined($self->{'sum_express'})) { $self->{'sum_express'} = []; }
    push @{$self->{'sum_express'}}, [$platform, $sum_express];
  }
}

1;

