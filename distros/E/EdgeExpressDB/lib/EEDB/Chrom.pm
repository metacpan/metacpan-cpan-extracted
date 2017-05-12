=head1 NAME - EEDB::Chrom

=head1 SYNOPSIS

An object to encapsulate a Chromosome within an Assembly.

=head1 DESCRIPTION

An object that corresponds to specific chromosomes within an assembly.  Because Chrom is tied to a specific
assembly, an instance of a Chrom identifies not only the chromosome, but also the assembly and species

As with all objects in EEDB, Chrom interits from MQdb::DBObject and MQdb::MappedQuery.
Please refer to these documents for all superclass methods

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

my $__riken_gsc_chrom_global_should_cache = 1;
my $__riken_gsc_chrom_global_id_cache = {};
my $__riken_gsc_chrom_global_nameasm_cache = {};

$VERSION = 0.953;

package EEDB::Chrom;

use strict;
use Time::HiRes qw(time gettimeofday tv_interval);

use EEDB::Assembly;

use MQdb::MappedQuery;
our @ISA = qw(MQdb::MappedQuery);

#################################################
# Class methods
#################################################

sub class { return "Chrom"; }

=head2 set_cache_behaviour

  Description  : class level method to turn on/off global caching of Chromsome objects
                 since these are very small and used heavily, it is on my default 
                 and it is recommended to not turn it off.
  Parameter[1] : scalar 0/1 to turn the caching off/on
  Returntype   : none
  Exceptions   : none

=cut

sub set_cache_behaviour {
  my $class = shift;
  my $mode = shift;
  
  $__riken_gsc_chrom_global_should_cache = $mode;
  
  if(defined($mode) and ($mode eq '0')) {
    #if turning off caching, then flush the caches
    $__riken_gsc_chrom_global_id_cache = {};
    $__riken_gsc_chrom_global_nameasm_cache = {};
  }
}

=head2 get_cache_size

  Description : get count of Chroms currently in the memory cache
  Returntype  : scalar count
  Exceptions  : none

=cut

sub get_cache_size {
  return scalar(keys(%{$__riken_gsc_chrom_global_nameasm_cache}));
}

#################################################
# Instance methods
#################################################

=head2 init

  Description: initialize a new instance of this object.
               generally not needed for users to call this method
  Returntype : $self
  Exceptions : none

=cut

sub init {
  my $self = shift;
  $self->SUPER::init;
  
  $self->{'chrom_name'} = undef;  
  $self->{'assembly'} = undef;
  $self->{'chrom_length'} = undef;
  $self->{'chrom_type'} = '';
  
  return $self;
}


##########################
#
# getter/setter methods of data which is stored in database
#
##########################

=head2 chrom_name

  Description  : simple getter/setter method for the chromosome name
  Parameter[1] : <optional> if specififed it will set the chromsome name
  Returntype   : string
  Exceptions   : none

=cut

sub chrom_name {
  my $self = shift;
  return $self->{'chrom_name'} = shift if(@_);
  $self->{'chrom_name'}='' unless(defined($self->{'chrom_name'}));
  return $self->{'chrom_name'};
}

=head2 chrom_type

  Description  : simple getter/setter method for the chromosome type
  Parameter[1] : <optional> if specififed it will set the chromsome type
  Returntype   : string
  Exceptions   : none

=cut

sub chrom_type {
  my $self = shift;
  return $self->{'chrom_type'} = shift if(@_);
  $self->{'chrom_type'}='' unless(defined($self->{'chrom_type'}));
  return $self->{'chrom_type'};
}

=head2 description

  Description  : simple getter/setter method for the chromosome description
  Parameter[1] : <optional> if specififed it will set the chromsome description
  Returntype   : string
  Exceptions   : none

=cut

sub description {
  my $self = shift;
  return $self->{'description'} = shift if(@_);
  $self->{'description'}='' unless(defined($self->{'description'}));
  return $self->{'description'};
}

=head2 assembly

  Description  : simple getter/setter method for the Assembly of this Chrom
  Parameter[1] : <optional> of type EEDB::Assembly. if specififed it will set the assembly
  Returntype   : EEDB::Assembly instance
  Exceptions   : none

=cut

sub assembly {
  my $self = shift;
  if(@_) {
    my $assembly = shift;
    if(defined($assembly) && !($assembly->isa('EEDB::Assembly'))) {
      die('assembly param must be a EEDB::Assembly');
    }
    return $self->{'assembly'} = $assembly;
  }
  return $self->{'assembly'};
}

=head2 chrom_length

  Description  : simple getter/setter method for the chromosome length
  Parameter[1] : <optional scalar> if specififed it will set the chromsome length
  Returntype   : scalar
  Exceptions   : none

=cut

sub chrom_length {
  my $self = shift;
  return $self->{'chrom_length'} = shift if(@_);
  $self->{'chrom_length'}=-1 unless(defined($self->{'chrom_length'}));
  return $self->{'chrom_length'};
}

=head2 display_desc

  Description  : overrides the superclass method.  
                 returns a debugging description of this instance.
                 calling display_info() will print this display_desc to STDOUT
  Returntype   : string
  Exceptions   : none

=cut

sub display_desc {
  my $self = shift;
  return sprintf("Chrom(db %s ) %s %s %s : len %d :: %s", 
    $self->id,
    $self->assembly->ucsc_name,
    $self->chrom_type,
	  $self->chrom_name,
    $self->chrom_length,
    $self->description
    );
}

=head2 xml_start

  Description  : overrides the superclass method.  
                 returns the start of the XML description of this instance
  Returntype   : string
  Exceptions   : none

=cut

sub xml_start {
  my $self = shift;
  
  my $str = sprintf("<chrom id=\"%s\" peer=\"%s\" chr=\"%s\" length=\"%d\" ",
                    $self->id,
                    $self->database->alias,
                    $self->chrom_name,
                    $self->chrom_length);
  my $assembly = $self->assembly;
  $str .= sprintf(" taxon_id=\"%s\" ncbi_asm=\"%s\" asm=\"%s\" ",
                  $assembly->taxon_id,
                  $assembly->ncbi_version,
                  $assembly->ucsc_name);
  $str .= ">";
  return $str;
}

=head2 xml_end

  Description  : overrides the superclass method.  
                 returns the end tag of the XML description of this instance
  Returntype   : string
  Exceptions   : none

=cut

sub xml_end {
  my $self = shift;
  return "</chrom>\n"; 
}

=head2 xml

  Description  : overrides the superclass method.  
                 returns the complete XML description of this instance
  Returntype   : string
  Exceptions   : none

=cut

sub xml {
  my $self = shift;
  return $self->simple_xml;
}

=head2 get_subsequence

  Description  : uses ChromChunk objects and the sequence in the database to 
                 return the actual sequence in this region. Since the
                 Chrom is assigned to a specific Assembly one only needs to specify
                 the start/end and an optional strand to fetch the sequence.
  Parameter[1] : chrom_start 
                 the chromosome start of the region to fetch
  Parameter[2] : chrom_end  
                 the chromosome end of the region to fetch
  Parameter[3] : strand <optional> as "-" or "+"
                 the strand of the sequence. if "-" then it will return the sequence 
                 on the reverse strand by reverse complementing the sequence
  Returntype   : Bio::Seq instance or undef if a data error happens
  Errors       : if the region is not valid or if data is not present it will return undef
  Exceptions   : none

=cut

sub get_subsequence {
  my $self   = shift;
  my $start  = shift;
  my $end    = shift;
  my $strand = shift; #optional
  
  #must provide valid coordinates
  if(!defined($start) or !defined($end)) { return undef; }
  if($start < 0) { return undef; }
  if($end < 0) { return undef; }
  if($end > $self->chrom_length) { return undef; }
  if($start > $end) { return undef; }
  
  if(!defined($strand)) { $strand = "+"; }
  my $asm_name =  $self->assembly->ucsc_name;

  #fetch_all_named_region returns chunks in sorted order by chrom_start
  my @chunks = @{EEDB::ChromChunk->fetch_all_named_region($self->database, $asm_name, $self->chrom_name, $start, $end)};
  if(scalar(@chunks) == 0) { return undef; }

  my $name = sprintf("seq_%s::%s:%d..%d%s", $asm_name, $self->chrom_name, $start, $end, $strand);

  #first see if region fits entirely inside one chunk
  #coord compare is much faster than string concats
  for(my $i=0; $i<scalar(@chunks); $i++) {
    my $chunk = $chunks[$i];
    if(($start >= $chunk->chrom_start) and ($end <= $chunk->chrom_end)) {
      my $bioseq = $chunk->get_subsequence($start, $end, $strand);
      $bioseq->id($name);
      return $bioseq;
    }
  }

  ## more than one chunk required to cover entire region so concat
  ## keep track of how much has already been concatonated by $ts and loop
  ## then do reverse complement at end
  my $seq = "";
  my $ts = $start; #keep running track of position
  for(my $i=0; $i<scalar(@chunks); $i++) {
    my $chunk = $chunks[$i];
    my $te = $chunk->chrom_end;
    if($end<$te) { $te = $end; }
    $seq .= $chunk->get_subsequence($ts, $te)->seq;
    $ts = $te+1;
    if($ts > $end) { last; } #we are done
  }

  my $bioseq = Bio::Seq->new(-id=>$name, -seq=>$seq);
  if($strand eq '-') { $bioseq = $bioseq->revcom; }
  return $bioseq;
}


#################################################
#
# DBObject override methods
#
#################################################

=head2 store

  Description  : store this instance into an EEDB database
                 on return the instance will have the primary_id() set.
  Parameter[1] : a MQdb::Database to store into
  Returntype   : $self or undef if a problem occurred
  Exceptions   : none

=cut

sub store {
  my $self = shift;
  my $db   = shift;
  
  if($db) { $self->database($db); }
  my $dbh = $self->database->get_connection;  
  my $sql = "INSERT ignore INTO chrom (
                chrom_name,
                chrom_type,
                assembly_id,
                chrom_length)
             VALUES(?,?,?,?)";
  my $sth = $dbh->prepare($sql);
  $sth->execute($self->chrom_name,
                $self->chrom_type,
                $self->assembly->id,
                $self->chrom_length);

  my $dbID = $sth->{'mysql_insertid'};
  $sth->finish;
  return undef unless($dbID);
  $self->primary_id($dbID);
  return $self;
}

=head2 update

  Description  : updates the data of this instance. require the Chrom to have been
                 fetched from database. It must have database() and primary_id()
  Returntype   : $self
  Exceptions   : none

=cut

sub update {
  my $self = shift;
  
  return undef unless($self->database and $self->id);
  
  my $dbh = $self->database->get_connection;  
  my $sql = "UPDATE chrom set chrom_length=?, description=?, chrom_type=? where chrom_id=?";
  my $sth = $dbh->prepare($sql);
  $sth->execute($self->chrom_length, 
                $self->description,
                $self->chrom_type,
                $self->id);
  return $self;
}

##### DBObject instance override methods #####

#mapRow is an internal method used by the MappedQuery template machinery
sub mapRow {
  my $self = shift;
  my $rowHash = shift;
  my $dbh = shift;

  $self->primary_id($rowHash->{'chrom_id'});
  $self->chrom_name($rowHash->{'chrom_name'});
  $self->chrom_length($rowHash->{'chrom_length'});
  $self->chrom_type($rowHash->{'chrom_type'});
  
  my $assembly = EEDB::Assembly->fetch_by_id($self->database, $rowHash->{'assembly_id'});
  $self->assembly($assembly);
    
  if($__riken_gsc_chrom_global_should_cache != 0) {
    $__riken_gsc_chrom_global_id_cache->{$self->database() . $self->id} = $self;
    $__riken_gsc_chrom_global_nameasm_cache->{$self->database() . $self->chrom_name. $rowHash->{'assembly_id'}} = $self;
  }
      
  return $self;
}


##### public class methods for fetching by utilizing DBObject framework methods #####

sub fetch_by_id {
  my $class = shift;
  my $db = shift;
  my $id = shift;

  if($__riken_gsc_chrom_global_should_cache != 0) {
    my $chrom = $__riken_gsc_chrom_global_id_cache->{$db . $id};
    if(defined($chrom)) { return $chrom; }
  }
  my $sql = "SELECT * FROM chrom WHERE chrom_id=?";
  return $class->fetch_single($db, $sql, $id);
}

sub fetch_all {
  my $class = shift;
  my $db = shift;
  
  my $sql = "SELECT * FROM chrom";
  return $class->fetch_multiple($db, $sql);
}

sub fetch_all_by_assembly {
  my $class = shift;
  my $assembly = shift; #Assembly object

  unless(defined($assembly) && $assembly->isa('EEDB::Assembly')) {
    print('ERROR fetch_all_by_assembly() param must be a EEDB::Assembly');
    return undef;
  }
  return undef unless($assembly->database);
  my $sql = "SELECT * FROM chrom WHERE assembly_id=?";
  return $class->fetch_multiple($assembly->database, $sql, $assembly->id);
}

sub fetch_all_by_assembly_id {
  my $class = shift;
  my $db = shift;
  my $assembly_id = shift;

  my $sql = "SELECT * FROM chrom WHERE assembly_id=?";
  return $class->fetch_multiple($db, $sql, $assembly_id);
}

sub fetch_all_by_assembly_name {
  my $class = shift;
  my $db = shift;
  my $assembly_name = shift;

   my $sql = "SELECT * FROM chrom JOIN assembly USING(assembly_id) ".
             "WHERE (ncbi_version=? or ucsc_name=?) ORDER BY chrom_length";
  return $class->fetch_multiple($db, $sql, $assembly_name, $assembly_name);
}

sub fetch_by_assembly_chrname {
  my $class = shift;
  my $assembly = shift; #Assembly object
  my $chrname = shift;

  if(!defined($assembly) or  !($assembly->isa('EEDB::Assembly'))) {
    print('fetch_by_assembly_chrname() param must be a EEDB::Assembly');
    return undef;
  }

  my $db = $assembly->database;
  if($__riken_gsc_chrom_global_should_cache != 0) {
    my $chrom = $__riken_gsc_chrom_global_nameasm_cache->{$db . $chrname . $assembly->id};
    if(defined($chrom)) { return $chrom; }
  }

  my $sql = "SELECT * FROM chrom WHERE chrom_name=? and assembly_id=?";
  return $class->fetch_single($db, $sql, $chrname, $assembly->id);
}

sub fetch_by_name_assembly_id {
  my $class = shift;
  my $db = shift;
  my $name = shift;
  my $assembly_id = shift;

  if($__riken_gsc_chrom_global_should_cache != 0) {
    my $chrom = $__riken_gsc_chrom_global_nameasm_cache->{$db . $name . $assembly_id};
    if(defined($chrom)) { return $chrom; }
  }

  my $sql = "SELECT * FROM chrom WHERE chrom_name=? and assembly_id=?";
  return $class->fetch_single($db, $sql, $name, $assembly_id);
}

sub fetch_by_name {
  my $class = shift;
  my $db = shift;
  my $assembly_name = shift;
  my $chrom_name = shift;

   my $sql = "SELECT * FROM chrom JOIN assembly USING(assembly_id) ".
             "WHERE chrom_name=? and (ncbi_version=? or ucsc_name=?)";
  return $class->fetch_single($db, $sql, $chrom_name, $assembly_name, $assembly_name);
}

sub fetch_all_by_feature_source {
  my $class = shift;
  my $fsource = shift;

  my $chrom_hash = {};
  my $stream = EEDB::Feature->stream_all_by_source($fsource);
  while(my $feature = $stream->next_in_stream) {
    #no need to worry about federated IDs here since the source must be on one database
    my $chrom = $feature->chrom;
    $chrom_hash->{$chrom->id} = $chrom;
  }
  my @chroms = values(%{$chrom_hash});
  return \@chroms;
}


1;


