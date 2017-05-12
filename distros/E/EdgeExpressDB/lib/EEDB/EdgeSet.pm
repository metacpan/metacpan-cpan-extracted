=head1 NAME - EEDB::EdgeSet

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

my $__riken_EEDB_linkset_global_counter = 1;

$VERSION = 0.953;

package EEDB::EdgeSet;

use strict;
use Time::HiRes qw(time gettimeofday tv_interval);

use EEDB::Feature;
use EEDB::Edge;
use EEDB::FeatureSet;

use MQdb::MappedQuery;
our @ISA = qw(MQdb::MappedQuery);

#################################################
# Class methods
#################################################

sub class { return "EdgeSet"; }

#################################################
# Instance methods
#################################################

sub init {
  my $self = shift;
  my %args = @_;
  $self->SUPER::init(@_);
  
  $self->{'edges'} = {};
  $self->{'count'} = undef;
  $self->{'_feature1_hash'} = {};
  $self->{'_feature2_hash'} = {};

  $self->{'_links_sort1'} = [];
  $self->{'_links_sort2'} = [];
  $self->{'_links_sort1_count'} = undef;
  $self->{'_links_sort2_count'} = undef;

  $self->primary_id($__riken_EEDB_linkset_global_counter++);
  
  if($args{'larray'}) { 
    $self->add_edges($args{'larray'}); 
  }
  
  if($args{'linksource'}) {
    my $lsrc = $args{'linksource'};
    my $links = EEDB::Edge->fetch_all_by_source($lsrc->database, $lsrc);
    $self->add_edges($links);
  } elsif($args{'db'}) {
    if($args{'lsname'}) {
      my $ls = EEDB::EdgeSource->fetch_by_name($args{'db'}, $args{'lsname'});
      my $links = EEDB::Edge->fetch_all_by_source($args{'db'}, $ls);
      $self->add_edges($links);
      $self->name($ls->name);
    }
    if($args{'ls_id'}) {
      my $ls = EEDB::EdgeSource->fetch_by_id($args{'db'}, $args{'ls_id'});
      my $links = EEDB::Edge->fetch_all_by_source($args{'db'}, $ls);
      $self->add_edges($links);
      $self->name($ls->name);
    }
    if($args{'subnet_fset'}) {
      my $id_list = $args{'subnet_fset'}->id_list;
      my $links = EEDB::Edge->fetch_all_visible_with_feature_id_list($args{'db'}, $id_list);
      $self->add_edges($links);
    }
  }  
  return $self;
}

sub copy {
  my $self = shift;
 
  my $copy = $self->SUPER::copy();
  
  $copy->primary_id($__riken_EEDB_linkset_global_counter++);

  #don't want to share a pointer to the internal feature hash
  #so create new hash and fill it.
  $copy->{'edges'} = {};
  $copy->add_edges($self->edges);
  return $copy;
}

##################
sub name {
  my $self = shift;
  return $self->{'name'} = shift if(@_);
  $self->{'name'}='' unless(defined($self->{'name'}));
  return $self->{'name'};
}

sub description {
  my $self = shift;
  return $self->{'description'} = shift if(@_);
  $self->{'description'}='' unless(defined($self->{'description'}));
  return $self->{'description'};
}

##################

sub clear_all_links {
  my $self = shift;
  $self->{'edges'} = {};
  $self->{'count'} = undef;
  $self->{'_feature1_hash'} = {};
  $self->{'_feature2_hash'} = {};
  $self->{'_links_sort1'} = [];
  $self->{'_links_sort2'} = [];
  $self->{'_links_sort1_count'} = undef;
  $self->{'_links_sort2_count'} = undef;
}

sub add_edges {
  my $self = shift;
  my $larray = shift;
  
  return unless($larray);
  
  foreach my $edge (@$larray) {
    next unless(defined($edge) && $edge->isa('EEDB::Edge'));
    $self->{'edges'}->{$edge->db_id} = $edge;
  }
  $self->{'count'} = undef;
  $self->{'_links_sort1'} = [];
  $self->{'_links_sort2'} = [];
  $self->{'_links_sort1_count'} = undef;
  $self->{'_links_sort2_count'} = undef;
}

sub add_edge {
  my $self = shift;
  my $edge = shift;
  
  return unless($edge);
  return unless(defined($edge) && $edge->isa('EEDB::Edge'));
  $self->{'edges'}->{$edge->db_id} = $edge;
  $self->{'count'} = undef;
  $self->{'_links_sort1'} = [];
  $self->{'_links_sort2'} = [];
  $self->{'_links_sort1_count'} = undef;
  $self->{'_links_sort2_count'} = undef;
}

sub add_link_to_internal_leftright_hash {
  my $self = shift;
  my $edge = shift;
  
  my $lset = $self->{'_feature1_hash'}->{$edge->feature1->db_id};
  if(!defined($lset)) {
    $lset = new EEDB::EdgeSet;
    $self->{'_feature1_hash'}->{$edge->feature1->db_id} = $lset;
  }
  $lset->add_edge($edge);
  
  $lset = $self->{'_feature2_hash'}->{$edge->feature2->db_id};
  if(!defined($lset)) {
    $lset = new EEDB::EdgeSet;
    $self->{'_feature2_hash'}->{$edge->feature2->db_id} = $lset;
  }
  $lset->add_edge($edge);
}

sub count {
  my $self = shift;
  if(!defined($self->{'count'})) {
    $self->{'count'} = scalar(keys(%{$self->{'edges'}}));
  }
  return $self->{'count'};
}

sub edges {
  my $self = shift;
  my @edges = values(%{$self->{'edges'}});
  return \@edges;
}

#returns a FeatureSet object of unique nodes in this set of edges
sub feature_set {
  my $self = shift;
  
  my $fset = new EEDB::FeatureSet;
  foreach my $edge (@{$self->edges}) {
    $fset->add_feature($edge->feature1);
    $fset->add_feature($edge->feature2);
  }
  return $fset;
}

sub feature1_set {
  my $self = shift;
  
  my $fset = new EEDB::FeatureSet;
  foreach my $edge (@{$self->edges}) {
    $fset->add_feature($edge->feature1);
  }
  return $fset;
}

sub feature2_set {
  my $self = shift;
  
  my $fset = new EEDB::FeatureSet;
  foreach my $edge (@{$self->edges}) {
    $fset->add_feature($edge->feature2);
  }
  return $fset;
}

###########################
# Set manipulation routines
#
sub remove_edgesource {
  #this method will create new EdgeSet removing edges of specified source and returning all others
  my $self = shift;
  my $edge_source = shift;  #EEDB::EdgeSource
  
  my $lset = new EEDB::EdgeSet;
  foreach my $edge (@{$self->edges}) {
    next if(defined($edge_source) and ($edge->edge_source->id == $edge_source->id));
    $lset->add_edge($edge);
  }
  return $lset;
}

sub extract_edgesource {
  #this method will create new EdgeSet with only those edges of specified source
  my $self = shift;
  my $edge_source = shift;  #EEDB::EdgeSource
  
  my $lset = new EEDB::EdgeSet;
  if(!defined($edge_source) or !($edge_source->isa('EEDB::EdgeSource'))) { return $lset; }
  
  foreach my $edge (@{$self->edges}) {
    next if($edge->edge_source->id != $edge_source->id);
    $lset->add_edge($edge);
  }
  return $lset;
}

sub extract_category {
  #this method will create new EdgeSet with only those edge sources of the specified category
  my $self = shift;
  my $category = shift;
  
  my $lset = new EEDB::EdgeSet;
  
  foreach my $edge (@{$self->edges}) {
    next unless($edge->edge_source->category eq $category);
    $lset->add_edge($edge);
  }
  return $lset;
}

sub remove_local_leaves {
  my $self = shift;
  
  # OK this is where I will do the leaf filter step (on the edges)
  # then the remaining code will work just fine...
  # feature_hash has not been built yet...
  my $intnodes = {};
  foreach my $edge (@{$self->edges})  {
    if($edge->direction eq "=") {
      $intnodes->{$edge->feature1_id} = 1;
      $intnodes->{$edge->feature2_id} = 1;
    } else {
      $intnodes->{$edge->feature1_id} = 1;
    }
  }
  my $lset = new EEDB::EdgeSet;
  foreach my $edge (@{$self->edges}) {
    if($edge->direction eq "=") { 
      $lset->add_edge($edge); 
    }
    elsif($intnodes->{$edge->feature1_id} and $intnodes->{$edge->feature2_id}) {
      $lset->add_edge($edge);
    }
  }
  return $lset;
}

sub find_edges_with_feature1_hash_based {
  my $self = shift;
  my $feature1 = shift;  #EEDB::Feature
  
  my $lset = $self->{'_feature1_hash'}->{$feature1->db_id};
  if(!defined($lset)) {
    $lset = new EEDB::EdgeSet;
    foreach my $edge (@{$self->edges}) {
      if($edge->feature1_id == $feature1->id) { $lset->add_edge($edge); }
    }
    $self->{'_feature1_hash'}->{$feature1->db_id} = $lset;
  }
  return $lset;
}

sub find_edges_with_feature2_hash_based {
  my $self = shift;
  my $feature2 = shift;  #EEDB::Feature
  
  my $lset = $self->{'_feature2_hash'}->{$feature2->db_id};
  if(!defined($lset)) {
    $lset = new EEDB::EdgeSet;
    foreach my $edge (@{$self->edges}) {
      if($edge->feature2_id == $feature2->id) { $lset->add_edge($edge); }
    }
    $self->{'_feature2_hash'}->{$feature2->db_id} = $lset;
  }
  return $lset;
}

sub find_linksource_name {
  my $self = shift;
  my $edge_source_name = shift;
  
  my $lset = new EEDB::EdgeSet;
  foreach my $edge (@{$self->edges}) {
    if($edge->edge_source->name eq $edge_source_name) { $lset->add_edge($edge); }
  }
  return $lset;
}

sub _build_sorted_lists {
  my $self = shift;
  
  return if(defined($self->{'_links_sort1_count'}));
  my $time2 = time();

  my @slist1 = sort {($a->feature1_id <=> $b->feature1_id)} values(%{$self->{'edges'}});
  $self->{'_links_sort1'} = \@slist1;

  my @slist2 = sort {($a->feature2_id <=> $b->feature2_id)} values(%{$self->{'edges'}});
  $self->{'_links_sort2'} = \@slist2;

  $self->{'_links_sort1_count'} = scalar(@slist1);
  $self->{'_links_sort2_count'} = scalar(@slist2);
  
  #printf("_build_sorted_lists %1.3f secs\n", (time() - $time2));
}


sub find_edges_with_feature1 {
  my $self = shift;
  my $feature1 = shift;  #EEDB::Feature
  
  #printf("search for %s\n", $feature1->simple_display_desc);
  my $lset = new EEDB::EdgeSet;
  $self->_build_sorted_lists();
  return $lset unless($self->{'_links_sort1_count'}>0);
  
  my $idx1 = 0;
  my $idx2 = $self->{'_links_sort1_count'} - 1;
  my $search = 1;

  while($search == 1) {
    my $idx = int(($idx1 + $idx2) / 2);
    my $search_link = $self->{'_links_sort1'}->[$idx];
    #printf("  %d [%d..%d] :: f1_id %d\n", $idx, $idx1, $idx2, $search_link->feature1_id);

    if($search_link->feature1_id == $feature1->id) { 
      $idx2 = $idx;
    } elsif(($idx==$idx1) and ($idx1 == $idx2-1)) { 
      $idx1++;
    } elsif($feature1->id < $search_link->feature1_id) {
      $idx2 = $idx;
    } elsif($feature1->id > $search_link->feature1_id) {
      $idx1 = $idx;
    }
    if(($idx<0) or ($idx>$self->{'_links_sort1_count'})) { $search = -1; }
    if($idx1 == $idx2) { $search= 0; }
  }
  
  return $lset unless($search == 0);
  
  my $search_link = $self->{'_links_sort1'}->[$idx1++];
  while(defined($search_link) and ($search_link->feature1_id == $feature1->id)) {
    $lset->add_edge($search_link);
    #printf("  found %s\n", $search_link->display_desc);
    $search_link = $self->{'_links_sort1'}->[$idx1++];
  }
 
  return $lset;
}

sub find_edges_with_feature2 {
  my $self = shift;
  my $feature2 = shift;  #EEDB::Feature
  
  #printf("search for %s\n", $feature2->simple_display_desc);
  my $lset = new EEDB::EdgeSet;
  $self->_build_sorted_lists();
  return $lset unless($self->{'_links_sort2_count'}>0);
  
  my $idx1 = 0;
  my $idx2 = $self->{'_links_sort2_count'} - 1;
  my $search = 1;

  while($search == 1) {
    my $idx = int(($idx1 + $idx2) / 2);
    my $search_link = $self->{'_links_sort2'}->[$idx];
    #printf("  %d [%d..%d] :: f2_id %d\n", $idx, $idx1, $idx2, $search_link->feature2_id);

    if($search_link->feature2_id == $feature2->id) { 
      $idx2 = $idx;
    } elsif(($idx==$idx1) and ($idx1 == $idx2-1)) { 
      $idx1++;
    } elsif($feature2->id < $search_link->feature2_id) {
      $idx2 = $idx;
    } elsif($feature2->id > $search_link->feature2_id) {
      $idx1 = $idx;
    }
    if(($idx<0) or ($idx>$self->{'_links_sort2_count'})) { $search = -1; }
    if($idx1 == $idx2) { $search= 0; }
  }
  
  return $lset unless($search == 0);
  
  my $search_link = $self->{'_links_sort2'}->[$idx1++];
  while(defined($search_link) and ($search_link->feature2_id == $feature2->id)) {
    $lset->add_edge($search_link);
    #printf("  found %s\n", $search_link->display_desc);
    $search_link = $self->{'_links_sort2'}->[$idx1++];
  }
 
  return $lset;
}

################

sub display_desc {
  my $self = shift;
  my $str = sprintf("EdgeSet(%s) %s :: %d edges",
           $self->id, 
           $self->name,
           $self->count
           );  
  return $str;
}

sub simple_xml {
  my $self = shift;
  my $str = sprintf("<EdgeSet name=\"%s\" count=\"%d\" />\n", $self->name,  $self->count);  
  return $str;
}

sub display_contents {
  my $self = shift;
  my $str = $self->display_desc . "\n";
  foreach my $edge (@{$self->edges}) {
    $str .= "   " . $edge->display_desc . "\n";
  }
  return $str;
}

1;

