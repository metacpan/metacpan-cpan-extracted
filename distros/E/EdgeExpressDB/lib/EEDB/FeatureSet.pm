=head1 NAME - EEDB::FeatureSet

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

my $__riken_EEDB_featureset_global_counter = 1;

$VERSION = 0.953;

package EEDB::FeatureSet;

use strict;
use Time::HiRes qw(time gettimeofday tv_interval);
use EEDB::Feature;

use MQdb::MappedQuery;
our @ISA = qw(MQdb::MappedQuery);

#################################################
# Class methods
#################################################

sub class { return "FeatureSet"; }

#################################################
# Instance methods
#################################################

sub init {
  my $self = shift;
  my %args = @_;
  $self->SUPER::init(@_);
  
  $self->{'features'} = {};
  $self->{'count'} = undef;
  $self->primary_id($__riken_EEDB_featureset_global_counter++);
  
  if($args{'farray'}) { $self->add_features($args{'farray'}); }
    
  if($args{'db'}) {
    if($args{'fsrc'}) {
      my $fsrc = EEDB::FeatureSource->fetch_by_name($args{'db'}, $args{'fsrc'});
      my $features = EEDB::Feature->fetch_all_by_source($args{'db'}, $fsrc);
      $self->add_features($features);
      $self->name($fsrc->name);
    }
    if($args{'fsrc_id'}) {
      my $fsrc = EEDB::FeatureSource->fetch_by_id($args{'db'}, $args{'fsrc_id'});
      my $features = EEDB::Edge->fetch_all_by_source($args{'db'}, $fsrc);
      $self->add_features($features);
      $self->name($fsrc->name);
    }
  }  
  return $self;
}


sub copy {
  my $self = shift;
 
  my $copy = $self->SUPER::copy();
  
  $copy->primary_id($__riken_EEDB_featureset_global_counter++);

  #don't want to share a pointer to the internal feature hash
  #so create new hash and fill it.
  $copy->{'features'} = {};
  $copy->add_features($self->features);
  return $copy;
}

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

sub add_features {
  my $self = shift;
  my $farray = shift;
  
  return unless($farray);
  
  foreach my $feature (@$farray) {
    next unless(defined($feature) && $feature->isa('EEDB::Feature'));
    $self->{'features'}->{$feature->db_id} = $feature;
  }
  $self->{'count'} = undef;
}

sub add_feature {
  my $self = shift;
  my @feature_list = @_;

  return unless(@feature_list);
  foreach my $feature (@feature_list) {  
    next unless(defined($feature) && $feature->isa('EEDB::Feature'));
    $self->{'features'}->{$feature->db_id} = $feature;
  }
  $self->{'count'} = undef;
}

sub count {
  my $self = shift;
  if(!defined($self->{'count'})) {
    $self->{'count'} = scalar(keys(%{$self->{'features'}}));
  }
  return $self->{'count'};
}

sub features {
  my $self = shift;
  my $fsrc = shift; #optional FeatureSource;
  
  my @feats = values(%{$self->{'features'}});
  if($fsrc and $fsrc->isa('EEDB::FeatureSource')) {
    my @f2s;
    foreach my $feature (@feats) {
      next unless($feature and $feature->feature_source eq $fsrc);
      push @f2s, $feature;
    } 
    @feats = @f2s;
  }
  return \@feats;
}

sub has_feature {
  my $self = shift;
  my $feature = shift;

  return 0 unless(defined($feature) && $feature->isa('EEDB::Feature'));
  return 1 if($self->{'features'}->{$feature->db_id});
  return 0;
}


# id_list returns a string of ids which can be used as input to Edge::fetch_all_visible_with_feature_id_list
sub id_list {
  my $self = shift;
  my @ids;
  foreach my $feature (@{$self->features}) {
    push @ids, $feature->id;
  }
  my $id_list = join(',', @ids);
  return $id_list;  
}

#name_list returns a string of names white space separated, can be used in web display
sub name_list {
  my $self = shift;
  my @names;
  foreach my $feature (@{$self->features}) {
    push @names, $feature->primary_name;
  }
  return join(' ', @names);;  
}

################

sub display_desc {
  my $self = shift;
  my $str = sprintf("FeatureSet(%s) %d features", $self->id, $self->count);
  $str .= " :".$self->name if($self->name);
  $str .= sprintf(" [%s]", $self->description) if($self->description);
  return $str;
}

sub simple_xml {
  my $self = shift;
  my $str = sprintf("<featureset name=\"%s\" count=\"%d\" />\n", $self->name,  $self->count);  
  return $str;
}

sub display_contents {
  my $self = shift;
  my $str =  $self->display_desc . "\n";
  foreach my $feature (sort {($a->id <=> $b->id)}  @{$self->features}) {
    $str .= "   " . $feature->simple_display_desc . "\n";
  }
  return $str;
}


1;

