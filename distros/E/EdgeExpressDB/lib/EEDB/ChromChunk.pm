=head1 NAME - EEDB::ChromChunk

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

my $__riken_gsc_chromchunk_global_should_cache = 0;
my $__riken_gsc_chromchunk_global_id_cache = {};

$VERSION = 0.953;

package EEDB::ChromChunk;

use strict;
use Time::HiRes qw(time gettimeofday tv_interval);

use MQdb::MappedQuery;
our @ISA = qw(MQdb::MappedQuery);

#################################################
# Class methods
#################################################

sub class { return "ChromChunk"; }

sub set_cache_behaviour {
  my $class = shift;
  my $mode = shift;
  
  $__riken_gsc_chromchunk_global_should_cache = $mode;
  
  if(defined($mode) and ($mode eq '0')) {
    #if turning off caching, then flush the caches
    $__riken_gsc_chromchunk_global_id_cache = {};
  }
}

#################################################
# Instance methods
#################################################

sub init {
  my $self = shift;
  $self->SUPER::init;
  
  $self->{'chrom'} = undef;  
  $self->{'assembly_name'} = undef;  
  $self->{'chrom_name'} = undef;
  $self->{'chrom_start'} = undef;
  $self->{'chrom_end'} = undef;
  $self->{'_sequence'} = undef; #Bio::Seq object
  
  return $self;
}


##########################
#
# getter/setter methods of data which is stored in database
#
##########################

sub chrom {
  my ($self, $chrom) = @_;
  if($chrom) {
    unless(defined($chrom) && $chrom->isa('EEDB::Chrom')) {
      die('chrom param must be a EEDB::Chrom');
    }
    $self->{'chrom'} = $chrom;
  }
  
  #lazy load from database if possible
  if(!defined($self->{'chrom'}) and 
     defined($self->database) and 
     defined($self->{'chrom_id'}))
  {
    #printf("LAZY LOAD chrom_id=%d\n", $self->{'_chrom_id'});
    my $chrom = EEDB::Chrom->fetch_by_id($self->database, $self->{'chrom_id'});
    if(defined($chrom)) { $self->{'chrom'} = $chrom; }
  }
  return $self->{'chrom'};
}


sub assembly_name {
  my $self = shift;
  return $self->{'assembly_name'} = shift if(@_);
  $self->{'assembly_name'}='' unless(defined($self->{'assembly_name'}));
  if($self->chrom) { 
    return $self->chrom->assembly->ucsc_name;
  } else { 
    return $self->{'assembly_name'};
  }
}

sub chrom_name {
  my $self = shift;
  return $self->{'chrom_name'} = shift if(@_);
  $self->{'chrom_name'}='' unless(defined($self->{'chrom_name'}));
  if($self->chrom) { 
    return $self->chrom->chrom_name;
  } else { 
    return $self->{'chrom_name'}; 
  }
}

sub chrom_id {
  my $self = shift;
  return $self->{'chrom_id'} = shift if(@_);
  $self->{'chrom_id'}='' unless(defined($self->{'chrom_id'}));
  if($self->chrom) { 
    return $self->chrom->id;
  } else { 
    return $self->{'chrom_id'};
  }
}

sub chrom_start {
  my $self = shift;
  return $self->{'chrom_start'} = shift if(@_);
  $self->{'chrom_start'}=0 unless(defined($self->{'chrom_start'}));
  return $self->{'chrom_start'};
}

sub chrom_end {
  my $self = shift;
  return $self->{'chrom_end'} = shift if(@_);
  $self->{'chrom_end'}=0 unless(defined($self->{'chrom_end'}));
  return $self->{'chrom_end'};
}

sub seq_length {
  my $self = shift;
  return $self->chrom_end - $self->chrom_start + 1;
}

sub chunk_name {
  my $self = shift;
  return sprintf("chunk%d-%s_%s:%d..%d", $self->id, $self->assembly_name, $self->chrom_name, $self->chrom_start, $self->chrom_end);
}

=head2 sequence

  Args       : none
  Example    : my $bioseq = $chunk->sequence;
  Description: returns named sequence as a Bio::Seq object
  Returntype : Bio::Seq object
  Exceptions : none
  Caller     : general

=cut

sub sequence {
  my $self = shift;
  if(@_) {
    my $seq = shift;
    unless(defined($seq) && $seq->isa('Bio::Seq')) {
      die('sequence argument must be a Bio::Seq');
    }
    $self->{'_sequence'} = $seq;
  }
  return $self->{'_sequence'} if(defined($self->{'_sequence'}));

  #lazy load the sequence if sequence_id is set
  if(!defined($self->{'_sequence'}) and defined($self->database())) {
    $self->_fetch_sequence();
  }
  return $self->{'_sequence'};
}


sub get_subsequence {
  my $self = shift;
  my $chrom_start = shift;
  my $chrom_end = shift;
  my $strand = shift;
  
  $strand = "+" unless(defined($strand));
  
  my $offset = $chrom_start - $self->chrom_start + 1;
  my $length = $chrom_end - $chrom_start + 1;
  my $seq = $self->_fetch_sub_sequence($offset, $length);
  my $name = sprintf("chunk%d_%s_%s:%d..%d%s", $self->id, $self->assembly_name, $self->chrom_name, $chrom_start, $chrom_end, $strand);
  my $bioseq = Bio::Seq->new(-id=>$name, -seq=>$seq);
  if($strand eq '-') { $bioseq = $bioseq->revcom; }
  return $bioseq;
}


sub display_desc {
  my $self = shift;
  return sprintf("ChromChunk(db %s ) %s %s : %d - %d", 
    $self->id,
	  $self->assembly_name,
    $self->chrom_name,
    $self->chrom_start, $self->chrom_end);
}


sub xml {
  my $self = shift;
  my $str = sprintf("<chrom_chunk id=\"%d\" assembly=\"%s\" chr=\"%s\" start=\"%d\" end=\"%d\" />\n",
                     $self->id,
                     $self->assembly_name,
                     $self->chrom_name,
                     $self->chrom_start, 
                     $self->chrom_end);
  return $str;
}


sub dump_to_fasta_file {
  my $self = shift;
  my $fastafile = shift;
  
  my $bioseq = $self->sequence;
  unless(defined($fastafile)) {
    $fastafile = $bioseq->id . ".fa";
  }

  #printf("  writing chunk %s\n", $self->display_id);
  open(OUTSEQ, ">$fastafile")
    or $self->die("Error opening $fastafile for write");
  my $output_seq = Bio::SeqIO->new( -fh =>\*OUTSEQ, -format => 'fasta');
  $output_seq->write_seq($bioseq);
  close OUTSEQ;

  return $self;
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

  if(!defined($self->chrom_id)) {
    $self->_fetch_chrom_id_for_store();
  }
  return undef unless($self->chrom_id);
    
  my $dbh = $self->database->get_connection;  
  my $sql = "INSERT ignore INTO chrom_chunk (
                chrom_id,
                chrom_start,
                chrom_end,
                chunk_len)
             VALUES(?,?,?,?)";
  my $sth = $dbh->prepare($sql);
  $sth->execute($self->chrom_id,
                $self->chrom_start,
                $self->chrom_end,
                $self->seq_length);

  my $dbID = $sth->{'mysql_insertid'};
  $sth->finish;
  unless($dbID) {
    $sql = "select chrom_chunk_id from chrom_chunk where chrom_id=? and chrom_start=? and chrom_end=?";
    $dbID = $self->fetch_col_value($self->database, 
                                   $sql, 
                                   $self->chrom_id, 
                                   $self->chrom_start,
                                   $self->chrom_end);
  }
  $self->primary_id($dbID);
  
  #now store the sequence
  $self->store_seq();
}


sub check_exists_db {
  my $self = shift;
  my $db   = shift;
  
  return undef unless($db);
  my $sql = "select chrom_chunk_id from chrom_chunk where chrom_id=? and chrom_start=? and chrom_end=?";
  my $dbID = $db->fetch_col_value($sql, $self->chrom_id, $self->chrom_start, $self->chrom_end);
  if($dbID) {
    $self->primary_id($dbID);
    $self->database($db);
    return $self;
  } else {
    return undef;
  }
}

sub store_seq {
  my $self = shift;
  
  return unless(defined($self->{'_sequence'}));

  my $dbh = $self->database->get_connection;  
  my $sql = "INSERT ignore INTO chrom_chunk_seq (chrom_chunk_id, sequence) VALUES(?,?)";
  my $sth = $dbh->prepare($sql);
  $sth->execute($self->primary_id, $self->sequence->seq);
  $sth->finish;
}

##### DBObject instance override methods #####

sub mapRow {
  my $self = shift;
  my $rowHash = shift;
  my $dbh = shift;

  $self->primary_id($rowHash->{'chrom_chunk_id'});
  $self->assembly_name($rowHash->{'ucsc_name'});
  $self->chrom_id($rowHash->{'chrom_id'});
  $self->chrom_name($rowHash->{'chrom_name'});
  $self->chrom_start($rowHash->{'chrom_start'});
  $self->chrom_end($rowHash->{'chrom_end'});
    
  if($__riken_gsc_chromchunk_global_should_cache != 0) {
    $__riken_gsc_chromchunk_global_id_cache->{$self->database() . $self->id} = $self;
    #printf("@@@@@ caching ChromChunk for %d\n", $self->id);
  }
      
  return $self;
}


##### public class methods for fetching by utilizing DBObject framework methods #####

sub fetch_by_id {
  my $class = shift;
  my $db = shift;
  my $id = shift;

  if($__riken_gsc_chromchunk_global_should_cache != 0) {
    my $chunk = $__riken_gsc_chromchunk_global_id_cache->{$db . $id};
    if(defined($chunk)) {
      #printf("##### YEAH using the chromchunk cache for %d\n", $id);
      return $chunk;
    }
  }
  
  my $sql = "SELECT * FROM chrom_chunk join chrom using(chrom_id) join assembly using(assembly_id) WHERE chrom_chunk_id=?";
  return $class->fetch_single($db, $sql, $id);
}

sub fetch_all {
  my $class = shift;
  my $db = shift;
  
  my $sql = "SELECT * FROM chrom_chunk join chrom using(chrom_id) join assembly using(assembly_id)";
  return $class->fetch_multiple($db, $sql);
}

sub fetch_all_for_feature {
  my $class = shift;
  my $db = shift;
  my $feature = shift; #Feature object
  
  my $sql = "SELECT * FROM feature_2_chunk JOIN chrom_chunk using(chrom_chunk_id) ".
            "JOIN chrom using(chrom_id) JOIN assembly using(assembly_id) ".
            "WHERE feature_id=?";
  return $class->fetch_multiple($db, $sql, $feature->id);
}

sub fetch_by_id_range {
  my $class = shift;
  my $db = shift;
  my $id_range = shift;  #ruby style Range but as string "(1..800)" which needs parsing
  
  $id_range =~ /\((\d+)\.\.(\d+)\)/;
  my($start, $end) = ($1, $2);
  #printf("fetch_by_id_range : %s : %d %d\n", $id_range, $start, $end);
  my $sql = "SELECT * FROM chrom_chunk JOIN chrom USING(chrom_id) JOIN assembly USING(assembly_id) ".
            "WHERE chrom_chunk_id>=? AND chrom_chunk_id<=? ORDER BY chrom_chunk_id";
  return $class->fetch_multiple($db, $sql, $start, $end);
}

sub fetch_all_by_assembly_name {
  my $class = shift;
  my $db = shift;
  my $assembly_name = shift;
 
   my $sql = "SELECT * FROM chrom_chunk ".
             "JOIN chrom USING(chrom_id) ".
             "JOIN assembly USING(assembly_id) ".
             "WHERE (ncbi_version=? or ucsc_name=?) ORDER BY chrom_chunk_id";
  return $class->fetch_multiple($db, $sql, $assembly_name, $assembly_name);
}

sub fetch_all_named_region {
  my $class = shift;
  my $db = shift;
  my $assembly_name = shift;
  my $chrom_name = shift;
  my $chrom_start = shift;
  my $chrom_end = shift;
 
   my $sql = "SELECT * FROM chrom_chunk ".
             "JOIN chrom USING(chrom_id) ".
             "JOIN assembly USING(assembly_id) ".
             "WHERE (ncbi_version=? or ucsc_name=?) ".
             "AND chrom_name = ? AND chrom_start <= ? AND chrom_end >= ? ".
             "ORDER BY chrom_start";
  return $class->fetch_multiple($db, $sql, $assembly_name, $assembly_name, $chrom_name, $chrom_end, $chrom_start);
}

sub fetch_all_by_chrom {
  my $class = shift;
  my $chrom = shift; #Chrom object
 
   my $sql = "SELECT * FROM chrom_chunk WHERE chrom_id=? ".
             "ORDER BY chrom_start";
  return $class->fetch_multiple($chrom->database, $sql, $chrom->id);
}

sub fetch_all_by_chrom_range {
  my $class = shift;
  my $chrom = shift; #Chrom object, also source of database
  my $chrom_start = shift;
  my $chrom_end = shift;
 
   my $sql = "SELECT * FROM chrom_chunk ".
             "WHERE chrom_id = ? AND chrom_start <= ? AND chrom_end >= ? ".
             "ORDER BY chrom_start";
  return $class->fetch_multiple($chrom->database, $sql, $chrom->id, $chrom_end, $chrom_start);
}


####### internal DB methods #######

sub _fetch_sequence {
  my $self = shift;

  my $sql = "SELECT sequence FROM chrom_chunk_seq WHERE chrom_chunk_id=?";
  my $seq = $self->fetch_col_value($self->database, $sql, $self->primary_id);
  return unless(defined($seq));
  my $name = sprintf("chunk%d-%s-%s-%d", $self->id, $self->assembly_name, $self->chrom_name, $self->chrom_start);
  my $bioseq = Bio::Seq->new(-id=>$name, -seq=>$seq);
  $self->sequence($bioseq); 
}

sub _fetch_sub_sequence {
  my $self = shift;
  my $offset = shift;
  my $length = shift;

  my $sql = sprintf("SELECT substr(sequence, %s, %s) FROM chrom_chunk_seq WHERE chrom_chunk_id=?", $offset, $length);
  my $seq = $self->fetch_col_value($self->database, $sql, $self->primary_id);
  return $seq;
}

sub _fetch_chrom_id_for_store {
  my $self = shift;

  my $sql = "SELECT chrom_id FROM chrom join assembly using(assembly_id) WHERE chrom_name=? and (ncbi_version=? or ucsc_name=?)";
  my $chrom_id = $self->fetch_col_value($self->database, $sql, $self->chrom_name, $self->assembly_name, $self->assembly_name);
  $self->chrom_id($chrom_id);
}

1;

