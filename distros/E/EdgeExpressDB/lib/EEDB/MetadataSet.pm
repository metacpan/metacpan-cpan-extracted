=head1 NAME - EEDB::MetadataSet

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

my $__riken_EEDB_metadataset_global_counter = 1;
my $__riken_EEDB_metadataset_global_localcount = 1;

$VERSION = 0.953;

package EEDB::MetadataSet;

use strict;
use Time::HiRes qw(time gettimeofday tv_interval);

use EEDB::Metadata;
use EEDB::Symbol;

use MQdb::MappedQuery;
our @ISA = qw(MQdb::MappedQuery);

#################################################
# Class methods
#################################################

sub class { return "MetadataSet"; }

#################################################
# Instance methods
#################################################

sub init {
  my $self = shift;
  my %args = @_;
  $self->SUPER::init(@_);
  
  $self->{'metadata'} = [];
  #$self->primary_id($__riken_EEDB_metadataset_global_counter++);
  
  if($args{'metadata'}) { $self->add_metadata(@{$args{'metadata'}}); }
  
  return $self;
}

sub copy {
  my $self = shift;
 
  my $copy = $self->SUPER::copy();
  
  $copy->primary_id($__riken_EEDB_metadataset_global_counter++);

  #don't want to share a pointer to the internal symbol hash
  #so create new hash and fill it.
  $copy->{'metadata'} = [];
  $copy->add_metadata(@{$self->metadata_list});
  return $copy;
}

sub name {
  my $self = shift;
  return $self->{'name'} = shift if(@_);
  return $self->{'name'};
}

sub description {
  my $self = shift;
  return $self->{'description'} = shift if(@_);
  return $self->{'description'};
}

##################

sub merge_metadataset {
  #merges the contents of the external set into this one
  #also performs a 'remove_duplicates' after the merge
  my $self = shift;
  my $mdataset = shift;
  
  return unless($mdataset);
  $self->add_metadata(@{$mdataset->metadata_list});
  $self->remove_duplicates;
}

sub add_metadata {
  my $self = shift;
  my @mdata_list = @_;
  
  return unless(@mdata_list);
  foreach my $mdata (@mdata_list) {
    next unless(defined($mdata) && $mdata->isa('EEDB::Metadata'));
    push @{$self->{'metadata'}}, $mdata;
  }
}

sub remove_metadata {
  my $self = shift;
  my @mdata_list = @_;
  
  return unless(@mdata_list);
  my @new_list;
  foreach my $mdata1 (@{$self->{'metadata'}}) {
    my $match=0;
    foreach my $mdata2 (@mdata_list) {
      next unless(defined($mdata2) && $mdata2->isa('EEDB::Metadata'));
      if($mdata1->equals($mdata2)) { $match=1; }
    }
    if(!$match) { push @new_list, $mdata1};
  }
  $self->{'metadata'} = \@new_list;
}

sub add_tag_symbol {
  #create new Symbol from tag/value
  my $self = shift;
  my $tag = shift;
  my $value = shift;

  my $symbol = EEDB::Symbol->new($tag, $value);
  push @{$self->{'metadata'}}, $symbol;
  return $symbol;
}

sub add_tag_data {
  #create new Metadata from tag/value
  my $self = shift;
  my $tag = shift;
  my $data = shift;

  my $mdata = EEDB::Metadata->new($tag, $data);
  push @{$self->{'metadata'}}, $mdata;
  return $mdata;
}

sub remove_duplicates {
  my $self = shift;
  
  my @newlist;
  my $last = undef;
  foreach my $mdata (sort {($b->class cmp $a->class) or 
                           (lc($a->type) cmp lc($b->type)) or 
                           (lc($a->data) cmp lc($b->data)) or
                           ($b->id cmp $a->id)}  @{$self->metadata_list}) {
    if(!defined($last)) { 
      $last = $mdata;
      push @newlist, $mdata;
    } else {
      unless(($last->class eq $mdata->class) and 
             (lc($last->type) eq lc($mdata->type)) and 
             (lc($mdata->data) eq lc($last->data))) {
        $last = $mdata;
        push @newlist, $mdata;
      }
    }                           
  } 
  $self->{'metadata'} = \@newlist;
}

=head2 convert_bad_symbols

  Description  : Symbol is a special subclass of metadata which is supposed to be keyword-like
                 Symbols should have no whitespace and should be short enough to fit in the table
                 This method will double check the metadata and any improper Symbol is 
                 converted into EEDB::Metadata and unlinked from database.
                 This is useful when mirroring data or prior to bulk loading.
  Returntype   : $self
  Exceptions   : none

=cut

sub convert_bad_symbols {
  my $self = shift;
  #since Symbol is a special subclass of Metadata and uses the same
  #instance variables, I can just recast if there is a problem
  
  foreach my $mdata (@{$self->metadata_list}) {
    my $value = $mdata->data;
    if (($mdata->class eq "Symbol") and (($value =~ /\s/) or (length($value)>120))) {
      #if has whitespace or it is too long then this is Metadata
      bless $mdata, "EEDB::Metadata";
      $mdata->primary_id(undef);
      $mdata->database(undef);
    }
  }
  return $self;
}

################################################
#
# list access methods
#
################################################

sub count {
  my $self = shift;
  return scalar(@{$self->{'metadata'}});
}

sub metadata_list {
  my $self = shift;
  return $self->{'metadata'};
}

sub id_list {
  my $self = shift;
  my @ids;
  foreach my $mdata (@{$self->metadata_list}) {
    push @ids, $mdata->id;
  }
  my $id_list = join(',', @ids);
  return $id_list;  
}

#name_list returns a string of names white space separated, can be used in web display
sub value_list {
  my $self = shift;
  my @names;
  foreach my $mdata (@{$self->metadata_list}) {
    push @names, $mdata->data;
  }
  return join(' ', @names);;  
}

sub tag_data_list {
  my $self = shift;
  my @symlist;
  foreach my $mdata (@{$self->metadata_list}) {
    push @symlist, [$mdata->type, $mdata->data];
  }
  return \@symlist;
}

################################################
#
# search methods
#
################################################

sub find_metadata {
  #returns first occurance matching search pattern
  my $self = shift;
  my $tag = shift;
  my $value = shift;
  
  return undef unless(defined($tag) or defined($value));
  foreach my $mdata (@{$self->metadata_list}) {
    if(defined($tag) and defined($value)) {
      if(($mdata->type eq $tag) and ($mdata->data eq $value)) { return $mdata; }
    } else { 
      if(defined($tag) and ($mdata->type eq $tag)) { return $mdata; }
      if(defined($value) and ($mdata->data eq $value)) { return $mdata; }
    }
  } 
  return undef;
}


sub find_all_metadata_like {
  #returns simple array reference of mdata
  #finds all occurance matching search pattern
  #tag (if specified) must match exactly, but value(if specified) is allowed to be a 'prefix'
  my $self = shift;
  my $tag = shift; # can be undef
  my $value = shift; #optional
  
  my @rtn_mdata;
  
  return undef unless(defined($tag) or defined($value));
  foreach my $mdata (@{$self->metadata_list}) {
    if(defined($tag) and defined($value)) {
      if(($mdata->type eq $tag) and ($mdata->data =~ /^$value/)) { push @rtn_mdata, $mdata; }
    } else { 
      if(defined($tag) and ($mdata->type eq $tag)) { push @rtn_mdata, $mdata; }
      if(defined($value) and ($mdata->data =~ /^$value/)) { push @rtn_mdata, $mdata; }
    }
  } 
  return \@rtn_mdata;
}

################

sub display_desc {
  my $self = shift;
  my $str = sprintf("MetadataSet(%s) %d symbols", $self->id, $self->count);
  $str .= " :".$self->name if($self->name);
  $str .= sprintf(" [%s]", $self->description) if($self->description);
  return $str;
}

sub display_contents {
  my $self = shift;
  my $str = "";
  foreach my $mdata (sort {($b->class cmp $a->class) or ($a->type cmp $b->type) or ($a->data cmp $b->data)}  @{$self->metadata_list}) {
    $str .= "   " . $mdata->display_contents . "\n";
  }
  return $str;
}

sub xml {
  my $self = shift;
  my $str = "";
  my $mdata_list = $self->metadata_list;
  foreach my $mdata (sort {($b->class cmp $a->class) or ($a->type cmp $b->type)} @$mdata_list) {
    next if($mdata->type eq 'keyword');  #always hide the 'keywords' from the xml output
    $str .= "  " . $mdata->xml;
  }
  return $str;
}

sub gff_description {
  #the GFF2 format is not very robust so some metadata can not be outputed in this format
  #instead of manipulating the data, this data is skipped in the gff output
  my $self = shift;
  
  my $str ='';                  
  my $sym_hash ={};
  foreach my $mdata (sort {($b->class cmp $a->class) or ($a->type cmp $b->type) or ($a->data cmp $b->data)} @{$self->metadata_list}) {
    next unless($mdata->class eq 'Symbol');
    next if($mdata->type eq 'keyword');  #always hide the 'keywords' from the gff metadata output
    next if($mdata->data =~ /[\s\"\",]/);
    next if($mdata->data =~ /,/);
    #my $data = $mdata->data;
    #$data =~ s/\"/\\\"/g;
    #$str .= sprintf("%s=\"%s\"", $mdata->type, $data);
    my $data = $sym_hash->{$mdata->type};
    if(defined($data)) { $data .= ","; }
    $data .= $mdata->data;  
    $sym_hash->{$mdata->type} = $data;
  }


  my $first=1;
  foreach my $key (sort keys(%$sym_hash)) {
    unless($first) { $str .= ";"; }
    $first=0;
    my $data = $sym_hash->{$key};
    $str .= sprintf("_%s=\"%s\"", $key, $data);
  }
  return $str;
}


################################

sub store {
  #just makes sure the Metadata/Symbols are stored/synched with database
  #used prior to doing linkage
  my $self = shift;
  my $db   = shift;
  
  unless($db) { return undef; }  
  foreach my $mdata (@{$self->metadata_list}) {
    if($mdata->id eq '') { $mdata->store($db); }
  }
}


1;

