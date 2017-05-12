=head1 NAME - EEDB::Tools::PSLLoader

=head1 SYNOPSIS

=head1 DESCRIPTION

This is a processing class.  Take two FeatureSource with features on chromosomes, streams both of them
and does a merge-sort-like comparison.  Uses a call-out function to allow the user to 'do things' 
with the feature pairs.

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

package EEDB::Tools::PSLLoader;

use strict;
use EEDB::FeatureSource;
use EEDB::Feature;
use EEDB::Tools::MultiLoader;

use Time::HiRes qw(time gettimeofday tv_interval);
use Compress::Zlib;

use MQdb::DBObject;
our @ISA = qw(MQdb::DBObject);

#################################################
# Class methods
#################################################

sub class { return "EEDB::Tools::PSLLoader"; }

#################################################
# Instance methods
#################################################

sub init {
  my $self = shift;
  $self->SUPER::init;
  
  $self->{'assembly'} = undef;
  $self->{'category'} = "";
  $self->{'store'} = 0;
  $self->{'debug'} = 0;
  $self->{"import_blocks"} = 0;
  $self->{'display_interval'} = 250; 
  $self->{'create_chroms'} = 0;

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
      die("ERROR using multiple databases on one PSLLoader is not allowed");
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
  }
  return $self->{'assembly'};
}

sub source_name {
  my $self = shift;
  my $name = shift;
  
  $self->{"category"} = "";
  $self->{"src_name"} = $name;
  if($name =~ /(\w+)\:\:(.+)/) {
    $self->{"category"} = $1;
    $self->{"src_name"} = $2;
  }
  return $self->{"src_name"};
}

sub do_store {
  my $self = shift;
  return $self->{'store'} = shift if(@_);
  $self->{'store'}=1 unless(defined($self->{'store'}));
  return $self->{'store'};
}

sub debug {
  my $self = shift;
  return $self->{'debug'} = shift if(@_);
  return $self->{'debug'};
}

sub import_blocks {
  my $self = shift;
  return $self->{'import_blocks'} = shift if(@_);
  return $self->{'import_blocks'};
}

sub create_chroms {
  my $self = shift;
  return $self->{'create_chroms'} = shift if(@_);
  return $self->{'create_chroms'};
}

sub display_interval {
  my $self = shift;
  return $self->{'display_interval'} = shift if(@_);
  return $self->{'display_interval'};
}

###########

sub display_desc {
  #override superclass method
  my $self = shift;
  return sprintf("PSLLoader:: ");
}

sub display_contents {
  my $self = shift;
}


###############################################################
# dynamic fetch/creation of sources as needed
#

sub feature_source {
  my $self = shift;
  if(!defined($self->{"fsrc"})) {
    if($self->{"category"}) {
      $self->{"fsrc"} = EEDB::FeatureSource->fetch_by_category_name($self->database, $self->{"category"}, $self->{"src_name"});
    } else {
      $self->{"fsrc"} = EEDB::FeatureSource->fetch_by_name($self->database, $self->{"src_name"});
    }
    unless($self->{"fsrc"}){
      $self->{"fsrc"} = new EEDB::FeatureSource;
      $self->{"fsrc"}->name($self->{"src_name"});
      $self->{"fsrc"}->category($self->{"category"});
      $self->{"fsrc"}->import_source(""); 
      $self->{"fsrc"}->store($self->database) if($self->{'store'});
      printf("Needed to create:: ");
    }
    $self->{"fsrc"}->display_info;
  }
  return $self->{"fsrc"};
}

sub block_source {
  my $self = shift;
  if(!defined($self->{"block_fsrc"})) {
    my $block_name = $self->{"src_name"} . "_block";
    $self->{"block_fsrc"} = EEDB::FeatureSource->fetch_by_category_name($self->database, "block", $block_name);
    unless($self->{"block_fsrc"}){
      $self->{"block_fsrc"} = new EEDB::FeatureSource;
      $self->{"block_fsrc"}->category("block");
      $self->{"block_fsrc"}->name($block_name);
      $self->{"block_fsrc"}->import_source(""); 
      $self->{"block_fsrc"}->store($self->database) if($self->{'store'});
      printf("Needed to create:: ");
    }
    $self->{"block_fsrc"}->display_info;
  }
  return $self->{"block_fsrc"};
}

sub sublink_source {
  my $self = shift;
  if(!defined($self->{'subfeature_lsrc'})) {
    my $link_name = $self->{"src_name"} . "_subfeature";
    $self->{'subfeature_lsrc'} = EEDB::EdgeSource->fetch_by_name($self->database, $link_name);
    unless($self->{'subfeature_lsrc'}){
      $self->{'subfeature_lsrc'} = new EEDB::EdgeSource;
      $self->{'subfeature_lsrc'}->category("subfeature");
      $self->{'subfeature_lsrc'}->name($link_name);
      $self->{'subfeature_lsrc'}->store($self->database) if($self->{'store'});
      printf("Needed to create:: ");
    }
    $self->{'subfeature_lsrc'}->display_info;
  }
  return $self->{'subfeature_lsrc'};
}


#########################################################################################

sub load_features {
  my $self = shift;
  my $file = shift;
  
  printf("\n==============\n");
  my $starttime = time();
  my $linecount=0;
  
  my $multiLoad = new EEDB::Tools::MultiLoader;
  $multiLoad->database($self->database);
  $multiLoad->do_store($self->{'store'});

  my $gz = gzopen($file, "rb") ;
  my $line;
  while(my $bytesread = $gz->gzreadline($line)) {
    chomp($line);
    next if($line =~ /^\#/);
    next if($line =~ /^track/);
    $linecount++;
    $line =~ s/\r//g;
    printf("LINE: $line\n") if($self->debug>1);

    # PSL format columns. here we assume that the PSL is mapping some query to a 'target' genome
    #
    #0. matches - Number of bases that match that aren't repeats
    #1. misMatches - Number of bases that don't match
    #2. repMatches - Number of bases that match but are part of repeats
    #3. nCount - Number of 'N' bases
    #4. qNumInsert - Number of inserts in query
    #5. qBaseInsert - Number of bases inserted in query
    #6. tNumInsert - Number of inserts in target
    #7. tBaseInsert - Number of bases inserted in target
    #8. strand - '+' or '-' for query strand. For translated alignments, second '+'or '-' is for genomic strand
    #9. qName - Query sequence name
    #10. qSize - Query sequence size
    #11. qStart - Alignment start position in query
    #12. qEnd - Alignment end position in query
    #13. tName - Target sequence name
    #14. tSize - Target sequence size
    #15. tStart - Alignment start position in target
    #16. tEnd - Alignment end position in target
    #17. blockCount - Number of blocks in the alignment (a block contains no gaps)
    #18. blockSizes - Comma-separated list of sizes of each block
    #19. qStarts - Comma-separated list of starting positions of each block in query
    #20. tStarts - Comma-separated list of starting positions of each block in target (in target coords not offset)
  
    my @columns = split(/\t/, $line);
    my $strand      = $columns[8];
    my $name        = $columns[9];
    my $chrname     = $columns[13];
    my $start       = $columns[15];
    my $end         = $columns[16];
    my $blockCount  = $columns[17];
    my $blockSizes  = $columns[18];
    my $blockStarts = $columns[20];
    
    my @block_size_array = split(/,/, $blockSizes) if($blockCount);
    my @block_start_array = split(/,/, $blockStarts) if($blockCount);
    
    if($start>$end) {
      my $t=$start;
      $start = $end;
      $end = $t;
    }
    #PSL format is 0 reference and eeDB is 1 referenced
    #because PSL is not-inclusive, but eeDB is inclusive I do not need to +1 to the end
    $start += 1;
            
    my $chrom = EEDB::Chrom->fetch_by_assembly_chrname($self->assembly, $chrname);
    if(!$chrom and $self->{'create_chroms'}) { #create the chromosome;
      $chrom = new EEDB::Chrom;
      $chrom->chrom_name($chrname);
      $chrom->assembly($self->assembly);
      $chrom->chrom_type('chromosome');
      $chrom->store($self->database) if($self->{'store'});
      printf("need to create chromosome :: %s\n", $chrom->display_desc);
    }
    if(!$chrom) { next; }
    
    my $feature = new EEDB::Feature;
    $feature->feature_source($self->feature_source);
    $feature->chrom($chrom);
    $feature->chrom_start($start);
    $feature->chrom_end($end);
    #optional columns now
    if($strand) { $feature->strand($strand); }
    if($name) {
      $feature->primary_name($name);
      $feature->metadataset->add_tag_symbol($self->feature_source->category, $name);
    }

    $multiLoad->store_feature($feature);
    $feature->display_info if($self->debug);
    
    if($blockCount and $self->{"import_blocks"}) {
      for(my $i=0;  $i<$blockCount; $i++) {
        my $bstart = $block_start_array[$i] + 1;
        my $bsize  = $block_size_array[$i];
        
        my $subfeat = new EEDB::Feature;
        $subfeat->feature_source($self->block_source);
        $subfeat->primary_name($name . "_block". ($i+1));
        $subfeat->chrom($chrom);
        $subfeat->chrom_start($bstart);
        $subfeat->chrom_end($bstart + $bsize - 1); #eedb is inclusive to must -1 (1234..1234 is size=1)
        $subfeat->strand($strand);
        $multiLoad->store_feature($subfeat);
        printf("  %s\n", $subfeat->display_desc) if($self->debug); 

        my $edge = new EEDB::Edge;
        $edge->edge_source($self->sublink_source);
        $edge->feature1($subfeat);
        $edge->feature2($feature);        
        $multiLoad->store_edge($edge);
        printf("          %s\n", $edge->display_desc) if($self->debug>2);
      } 
    }


    if($linecount % $self->{"display_interval"} == 0) { 
      my $rate = $linecount / (time() - $starttime);
      printf("%10d (%1.2f x/sec): %s\n", $linecount, $rate, $feature->display_desc); 
    }
    #last;
  }
  $gz->gzclose();
  
  #to flush the MultiLoader buffers 
  $multiLoad->store_feature();
  $multiLoad->store_edge();

  my $total_time = time() - $starttime;
  my $rate = $linecount / $total_time;
  printf("TOTAL: %10d :: %1.3f min :: %1.2f x/sec\n", $linecount, $total_time/60.0, $rate);

}


1;

