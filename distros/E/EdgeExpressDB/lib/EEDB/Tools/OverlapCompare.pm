=head1 NAME - EEDB::Tools::OverlapCompare

=head1 SYNOPSIS

=head1 DESCRIPTION

This is a general purpose processing tool designed to do genome spatial comparisons.
It is configured with a set of feature sources and parameters and call-back functions.
It is then fed a stream of features sorted by chromsome location. given the overlaps it will
then call the functions which the user can defined to "do things".
It is based on a modified merge-sort-like comparison algorithm.

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

package EEDB::Tools::OverlapCompare;

use strict;
use EEDB::FeatureSource;
use EEDB::Feature;
use Time::HiRes qw(time gettimeofday tv_interval);

use MQdb::DBObject;
our @ISA = qw(MQdb::DBObject);

#################################################
# Class methods
#################################################

sub class { return "EEDB::Tools::OverlapCompare"; }

#################################################
# Instance methods
#################################################

sub init {
  my $self = shift;
  $self->SUPER::init;
  
  $self->{'compare_mode'} = 'overlap';  #other is 'within'
  $self->{'upstream_distance'} = 0;
  $self->{'downstream_distance'} = 0;

  $self->{'assembly'} = undef;
  $self->{'feature_source_array'} = [];
  $self->{'experiment_array'} = [];
  $self->{'expression_mode_type_array'} = undef;
  
  $self->{'current_chrom_name'}= undef;
  $self->{'current_stream'}= undef;
  $self->{'feature_buffer'}= [];
  
  $self->{'debug'} = 0;
  
  return $self;
}


##########################
#
# getter/setter methods of data which is stored in database
#
##########################

sub database {
  #overide
  my $self = shift;
  my $db = shift;
  if(defined($db)) {
    if(!($db->isa('MQdb::Database'))) { die("$db is not a MQdb::Database"); }
    if($self->{'_database'} and ($db ne $self->{'_database'})) {
      die("ERROR using multiple databases on one OverlapCompare is not allowed");
    }
    $self->{'_database'} = $db;
  }
  return $self->{'_database'};
}

sub assembly {
  my ($self, $assembly) = @_;
  if($assembly) {
    unless(defined($assembly) && $assembly->isa('EEDB::Assembly')) {
      die('assembly param must be a EEDB::Assembly');
    }
    $self->{'assembly'} = $assembly;
    $self->database($assembly->database);
  }
  return $self->{'assembly'};
}

sub add_experiment {
  my ($self, $experiment) = @_;
  unless(defined($experiment) && $experiment->isa('EEDB::Experiment')) {
    die('add_experiment param must be a EEDB::Experiment');
  }
  push @{$self->{'experiment_array'}}, $experiment;
  $self->database($experiment->database);
  return $self;
}

sub add_feature_source {
  my ($self, $source) = @_;
  unless(defined($source) && $source->isa('EEDB::FeatureSource')) {
    die('add_feature_source param must be a EEDB::FeatureSource');
  }
  push @{$self->{'feature_source_array'}}, $source;
  $self->database($source->database);
  return $self;
}  

sub expression_mode_type {
  my $self = shift;
  return $self->{'expression_mode_type'} = shift if(@_);
  return $self->{'expression_mode_type'};
}

sub upstream_distance {
  my $self = shift;
  return $self->{'upstream_distance'} = shift if(@_);
  return $self->{'upstream_distance'};
}

sub downstream_distance {
  my $self = shift;
  return $self->{'downstream_distance'} = shift if(@_);
  return $self->{'downstream_distance'};
}


## to set an external function like sub my_func { .... }
## do call_out_function(\&my_func);
sub overlap_function {
  my $self = shift;
  if(@_) { $self->{'overlap_function'} = shift; }
  return $self->{'overlap_function'};
}

sub between_function {
  my $self = shift;
  if(@_) { $self->{'between_function'} = shift; }
  return $self->{'between_function'};
}


sub display_desc {
  #override superclass method
  my $self = shift;
  return sprintf("OverlapCompare:: ");
}

sub display_contents {
  my $self = shift;
}


###############################################################

# The input feature is expected to come in as a chrom_start sorted list
# all on the same chromosome, when the input stream changes chrom
# then the processing stream will also change
sub stream_process_feature {
  my $self = shift;
  my $feature1 = shift;
  
  my $f2db = $self->database;
  
  return undef unless($feature1->chrom);
  printf("\nFEATURE: %s [%s]\n", $feature1->chrom_location, $feature1->primary_name) if($self->{'debug'}>1);

  if(!defined($self->{'current_chrom_name'}) or ($feature1->chrom_name ne $self->{'current_chrom_name'})) {
    #change the chrom and refresh the buffers
    my $assembly2 = EEDB::Assembly->fetch_by_name($f2db, $feature1->chrom->assembly->ucsc_name);
    my $chrom2    = EEDB::Chrom->fetch_by_name_assembly_id($f2db, $feature1->chrom_name, $assembly2->id);
    return undef unless($chrom2);

    my $stream2;
    if(!defined($self->expression_mode_type)) {
      my @sources = @{$self->{'feature_source_array'}};
      $stream2   = EEDB::Feature->stream_by_chrom($chrom2, sources=>\@sources);
    } else {
      my $type = $self->expression_mode_type;
      if($type eq "all") { $type = undef; }
      my @sources = @{$self->{'feature_source_array'}};
      my @exps = @{$self->{'experiment_array'}};
      $stream2   = EEDB::Expression->stream_by_chrom($chrom2, datatypes=>[$type], sources=>\@sources, experiments=>\@exps);
    }
    
    $self->{'current_chrom_name'}= $feature1->chrom_name;
    $self->{'current_stream'}= $stream2;
    if($self->{'debug'}) {
      printf("+++++++++   %s  ++++++\n", $feature1->chrom_name);
      $assembly2->display_info;
      $chrom2->display_info;
    }

    #
    # first scan up stream2 until we get to around $feature1
    #
    my $feature2a = $stream2->next_in_stream;
    my $feature2b = $stream2->next_in_stream;
    printf("  F2: %s [%s] :: preload\n", $feature2a->chrom_location, $feature2a->primary_name) if($feature2a and $self->{'debug'}>1);
    printf("  F2: %s [%s] :: preload\n", $feature2b->chrom_location, $feature2b->primary_name) if($feature2b and $self->{'debug'}>1);

    while($self->overlap_check($feature1, $feature2b) == 1) {
      #F1 is past the end of the buffer so move the buffer forward (f1>f2)
      printf("  F2: %s [%s] :: upstream, move stream2 forward\n", $feature2b->chrom_location, $feature2b->primary_name) if($self->{'debug'}>1);
      $feature2a = $feature2b;
      $feature2b = $stream2->next_in_stream;
    }
    printf("  F2: %s [%s] :: init buffer\n", $feature2a->chrom_location, $feature2a->primary_name) if($feature2a and $self->{'debug'}>1);
    printf("  F2: %s [%s] :: init buffer\n", $feature2b->chrom_location, $feature2b->primary_name) if($feature2b and $self->{'debug'}>1);
    $self->{'f2_buffer'}= [$feature2a, $feature2b];
  }
  
  my $f2_buffer = $self->{'f2_buffer'};
  my $stream2   = $self->{'current_stream'};  
 
  #
  # first do work on the end of the buffer, in order to properly capture 'betweeen' events we 
  # need to make sure buffer goes beyond the current $feature1
  #
  my $feature2  = undef;
  if(@$f2_buffer) { $feature2 = $f2_buffer->[scalar(@$f2_buffer)-1]; }
  while($feature2 and ($self->overlap_check($feature1, $feature2) != -1)) {
    #keep going
    $feature2 = $stream2->next_in_stream;
    if($feature2) {
      printf("  F2: %s [%s] :: buffer tail extend\n", $feature2->chrom_location, $feature2->primary_name) if($self->{'debug'}>1);
      push @$f2_buffer, $feature2;
    }
  }

  #
  # then do work on the head of the buffer
  #
  my $feature2a = $f2_buffer->[0];
  my $feature2b = $f2_buffer->[1];
  while($feature2b and ($self->overlap_check($feature1, $feature2b) == 1)) {
    #F1 past is past both f2a and f2b so trim the head
    printf("  F2: %s [%s] :: buffer head trim\n", $feature2a->chrom_location, $feature2a->primary_name) if($self->{'debug'}>1);
    shift @$f2_buffer;
    $feature2a = $feature2b;
    $feature2b = $f2_buffer->[1];
  }

  if($self->{'debug'}>1) {
    printf(" F1: %s [%s]\n", $feature1->chrom_location, $feature1->primary_name);
    foreach my $f2 (@$f2_buffer) {
      next unless(defined($f2));
      printf("      buffer F2: %s [%s]\n", $f2->chrom_location, $f2->primary_name);
    }
  }

  my $does_overlap =0;
  foreach $feature2 (@$f2_buffer) {
    next unless(defined($feature2));
    if($self->overlap_check($feature1, $feature2) == 0) {
      #OK real overlap here
      printf(" overlap_check F2: %s [%s] :: OK do call out\n", $feature2->chrom_location, $feature2->primary_name) if($self->{'debug'}>1);
      $does_overlap=1;
      #call out here
      if($self->overlap_function) {
        $self->overlap_function->($feature1, $feature2);
      }

    } else {
      printf(" overlap_check F2: %s [%s] :: nope\n", $feature2->chrom_location, $feature2->primary_name) if($self->{'debug'}>1);
    }
  }
  
  #OK now the buffer should be setup so that the first feature2 is < feature1
  #and the last feature2 > feature1
  
  if(!$does_overlap and $self->between_function and (scalar(@$f2_buffer) < 3)) {
    #if less than  3 feature2 in buffer then there is good chance of a between
    my $f2a = $f2_buffer->[0];
    my $f2b = $f2_buffer->[1];
    if($self->overlap_check($feature1, $f2a) == -1) {  
      # f1 < f2a so between end and f2a
      printf(" BEFORE [%s] %s\n", $f2a->primary_name, $f2a->chrom_location) if($self->{'debug'}>1);
      $self->between_function->($feature1, undef, $f2a);
    } 
    elsif(($self->overlap_check($feature1, $f2a) == 1) and !defined($f2b)) {  
      # >f2a and no f2b then and the end
      printf(" AFTER [%s] %s\n", $f2a->primary_name, $f2a->chrom_location) if($self->{'debug'}>1);
      $self->between_function->($feature1, $f2a, undef);
    } 
    elsif(($self->overlap_check($feature1, $f2a) == 1) and ($self->overlap_check($feature1, $f2b) == -1)) { 
      # after f2a but before f2b, a real between
      printf(" BETWEEN [%s] %s <=> [%s] %s\n", 
           $f2_buffer->[0]->primary_name, 
           $f2_buffer->[0]->chrom_location, 
           $f2_buffer->[1]->primary_name, 
           $f2_buffer->[1]->chrom_location) if($self->{'debug'}>1);
      $self->between_function->($feature1, $f2_buffer->[0], $f2_buffer->[1]);
    }
  }


}



sub overlap_check {
  my $self = shift;
  my $feature1 = shift;
  my $feature2 = shift;

  return -999 unless($feature1 and $feature2); #stop
  
  # -1 means feature2 stream has not caught up to feature1 yet
  #  1 means feature2 stream has gone past feature1
  #  0 means overlapping
  
  my $mod_start = $feature2->chrom_start;
  my $mod_end   = $feature2->chrom_end;
  
  if($feature2->strand eq '+') { 
    $mod_start -= $self->upstream_distance;
    $mod_end   += $self->downstream_distance;
  } else {
    $mod_start -= $self->downstream_distance;
    $mod_end   += $self->upstream_distance;
  }
  
  if($feature1->chrom_start > $mod_end)   { return  1; } #f1 starts AFTER f2 ends   (f1>f2)
  if($feature1->chrom_end   < $mod_start) { return  -1; } #f1 ends before f2 starts (f1<g2)
  
  if(($mod_start <= $feature1->chrom_end) and
     ($mod_end   >= $feature1->chrom_start)) { 
    return 0;
  }
  return -999;  #hmm something is off
}


1;

