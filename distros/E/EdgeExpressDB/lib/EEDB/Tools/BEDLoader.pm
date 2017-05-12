=head1 NAME - EEDB::Tools::BEDLoader

=head1 SYNOPSIS

=head1 DESCRIPTION

This is a simple class to wrap the functionality of BED file parsing and 
conversion into eeDB objects into a nice modular component.

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

package EEDB::Tools::BEDLoader;

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

sub class { return "EEDB::Tools::BEDLoader"; }

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
  $self->{'create_chroms'} = 1;

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
      die("ERROR using multiple databases on one BEDLoader is not allowed");
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
  return sprintf("BEDLoader:: ");
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
      $self->{"fsrc"}->is_active("y"); 
      $self->{"fsrc"}->is_visible("y"); 
      $self->{"fsrc"}->store($self->database) if($self->{'store'});
      printf("Needed to create:: ");
    }
    $self->{"fsrc"}->display_info;
  }
  return $self->{"fsrc"};
}

sub exon_source {
  my $self = shift;
  if(!defined($self->{"exon_fsrc"})) {
    my $exon_name = $self->{"src_name"} . "_exon";
    $self->{"exon_fsrc"} = EEDB::FeatureSource->fetch_by_category_name($self->database, "exon", $exon_name);
    unless($self->{"exon_fsrc"}){
      $self->{"exon_fsrc"} = new EEDB::FeatureSource;
      $self->{"exon_fsrc"}->category("exon");
      $self->{"exon_fsrc"}->name($exon_name);
      $self->{"exon_fsrc"}->import_source(""); 
      $self->{"exon_fsrc"}->is_active("y"); 
      $self->{"exon_fsrc"}->is_visible("y"); 
      $self->{"exon_fsrc"}->store($self->database) if($self->{'store'});
      printf("Needed to create:: ");
    }
    $self->{"exon_fsrc"}->display_info;
  }
  return $self->{"exon_fsrc"};
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
      $self->{"subfeature_lsrc"}->is_active("y"); 
      $self->{"subfeature_lsrc"}->is_visible("y"); 
      $self->{'subfeature_lsrc'}->store($self->database) if($self->{'store'});
      printf("Needed to create:: ");
    }
    $self->{'subfeature_lsrc'}->display_info;
  }
  return $self->{'subfeature_lsrc'};
}

sub utr3_source {
  my $self = shift;
  if(!defined($self->{"utr3_fsrc"})) {
    my $utr3_name = $self->{"src_name"} . "_3utr";
    $self->{"utr3_fsrc"} = EEDB::FeatureSource->fetch_by_category_name($self->database, "3utr", $utr3_name);
    unless($self->{"utr3_fsrc"}){
      $self->{"utr3_fsrc"} = new EEDB::FeatureSource;
      $self->{"utr3_fsrc"}->category("3utr");
      $self->{"utr3_fsrc"}->name($utr3_name);
      $self->{"utr3_fsrc"}->import_source(""); 
      $self->{"utr3_fsrc"}->is_active("y"); 
      $self->{"utr3_fsrc"}->is_visible("y"); 
      $self->{"utr3_fsrc"}->store($self->database) if($self->{'store'});
      printf("Needed to create:: ");
    }
    $self->{"utr3_fsrc"}->display_info;
  }
  return $self->{"utr3_fsrc"};
}

sub utr5_source {
  my $self = shift;
  if(!defined($self->{"utr5_fsrc"})) {
    my $utr5_name = $self->{"src_name"} . "_5utr";
    $self->{"utr5_fsrc"} = EEDB::FeatureSource->fetch_by_category_name($self->database, "5utr", $utr5_name);
    unless($self->{"utr5_fsrc"}){
      $self->{"utr5_fsrc"} = new EEDB::FeatureSource;
      $self->{"utr5_fsrc"}->category("5utr");
      $self->{"utr5_fsrc"}->name($utr5_name);
      $self->{"utr5_fsrc"}->import_source(""); 
      $self->{"utr5_fsrc"}->is_active("y"); 
      $self->{"utr5_fsrc"}->is_visible("y"); 
      $self->{"utr5_fsrc"}->store($self->database) if($self->{'store'});
      printf("Needed to create:: ");
    }
    $self->{"utr5_fsrc"}->display_info;
  }
  return $self->{"utr5_fsrc"};
}

sub sync_importdates {
  my $self = shift;
  
  if(defined($self->{"fsrc"}))      { $self->{"fsrc"}->sync_importdate_to_features; }
  if(defined($self->{"exon_fsrc"})) { $self->{"exon_fsrc"}->sync_importdate_to_features; }
  if(defined($self->{"utr3_fsrc"})) { $self->{"utr3_fsrc"}->sync_importdate_to_features; }
  if(defined($self->{"utr5_fsrc"})) { $self->{"utr5_fsrc"}->sync_importdate_to_features; }
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
    $linecount++;
    $line =~ s/\r//g;
    printf("LINE: $line\n") if($self->debug>1);

    #chr1    134212714       134230065       NM_028778       0       +       134212806       134228958       0       7       335,121,152,66,120,133,2168,    0,8815,11559,11993,13820,14421,15183,

    #1. chrom - The name of the chromosome (e.g. chr3, chrY, chr2_random) or scaffold (e.g. scaffold10671).
    #2. chromStart - The starting position of the feature in the chromosome or scaffold. The first base in a chromosome is numbered 0.
    #3. chromEnd - The ending position of the feature in the chromosome or scaffold. The chromEnd base is not included in the display of the feature. For example, the first 100 bases of a chromosome are defined as chromStart=0, chromEnd=100, and span the bases numbered 0-99. 
    #4. name - Defines the name of the BED line. This label is displayed to the left of the BED line in the Genome Browser window when the track is open to full display mode or directly to the left of the item in pack mode.
    #5. score - A score between 0 and 1000. If the track line useScore attribute is set to 1 for this annotation data set, the score value will determine the level of gray in which this feature is displayed (higher numbers = darker gray).
    #6. strand - Defines the strand - either '+' or '-'.
    #7. thickStart - The starting position at which the feature is drawn thickly (for example, the start codon in gene displays).
    #8. thickEnd - The ending position at which the feature is drawn thickly (for example, the stop codon in gene displays).
    #9. itemRgb - An RGB value of the form R,G,B (e.g. 255,0,0). If the track line itemRgb attribute is set to "On", this RBG value will determine the display color of the data contained in this BED line. NOTE: It is recommended that a simple color scheme (eight colors or less) be used with this attribute to avoid overwhelming the color resources of the Genome Browser and your Internet browser.
    #10. blockCount - The number of blocks (exons) in the BED line.
    #11. blockSizes - A comma-separated list of the block sizes. The number of items in this list should correspond to blockCount.
    #12. blockStarts - A comma-separated list of block starts. All of the blockStart positions should be calculated relative to chromStart. The number of items in this list should correspond to blockCount. 

    my ($chrname, $start, $end, $name, $score, $strand, $thickStart, $thickEnd, $rgb, $blockCount, $blockSizes, $blockStarts) = split(/\t/, $line);
    
    my @block_size_array = split(/,/, $blockSizes) if($blockCount);
    my @block_start_array = split(/,/, $blockStarts) if($blockCount);
    
    if($start>$end) {
      my $t=$start;
      $start = $end;
      $end = $t;
    }
    #bed format is 0 reference and eeDB is 1 referenced
    #because bed is not-inclusive, but eeDB is inclusive I do not need to +1 to the end
    $start += 1;
    $thickStart += 1;
            
    my $chrom = EEDB::Chrom->fetch_by_assembly_chrname($self->assembly, $chrname);
    unless($chrom and $self->{'create_chroms'}) { #create the chromosome;
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
    if($score and ($score ne '.')) { $feature->significance($score); }
    if($name) {
      $feature->primary_name($name);
      $feature->metadataset->add_tag_symbol($self->feature_source->category, $name);
    }

    $multiLoad->store_feature($feature);
    $feature->display_info if($self->debug);
    
    if($blockCount and $self->{"import_blocks"}) {
      for(my $i=0;  $i<$blockCount; $i++) {
        my $bstart = $block_start_array[$i];
        my $bsize  = $block_size_array[$i];
        
        my $subfeat = new EEDB::Feature;
        $subfeat->feature_source($self->exon_source);
        $subfeat->primary_name($name . "_block". ($i+1));
        $subfeat->chrom($chrom);
        $subfeat->chrom_start($start + $bstart);
        $subfeat->chrom_end($start + $bstart + $bsize - 1);
        $subfeat->strand($strand);
        $multiLoad->store_feature($subfeat);
        printf("  %s\n", $subfeat->display_desc) if($self->debug); 

        my $edge = new EEDB::Edge;
        $edge->edge_source($self->sublink_source);
        $edge->feature1($subfeat);
        $edge->feature2($feature);        
        $multiLoad->store_edge($edge);
        printf("          %s\n", $edge->display_desc) if($self->debug>2);
        
        if(($thickStart > $start) and ($thickStart >= $subfeat->chrom_start)) {
          my $uend = $subfeat->chrom_end;
          if($thickStart < $uend) { $uend = $thickStart; }

          my $utr = new EEDB::Feature;
          $utr->chrom($chrom);
          $utr->chrom_start($subfeat->chrom_start);
          $utr->chrom_end($uend);
          $utr->strand($strand) if($strand);
          if($strand eq '-') { 
            $utr->feature_source($self->utr3_source); 
            $utr->primary_name($name . "_3utr") if($name);
          } else { 
            $utr->feature_source($self->utr5_source); 
            $utr->primary_name($name . "_5utr") if($name);
          }
          $multiLoad->store_feature($utr);
          printf("  %s\n", $utr->display_desc) if($self->debug); 
          
          my $edge = new EEDB::Edge;
          $edge->edge_source($self->sublink_source);
          $edge->feature1($utr);
          $edge->feature2($feature);        
          $multiLoad->store_edge($edge);
          printf("          %s\n", $edge->display_desc) if($self->debug>2);        
        }
        if(($thickEnd < $end) and ($thickEnd <= $subfeat->chrom_end)) {
          my $ustart = $subfeat->chrom_start;
          if($thickEnd > $ustart) { $ustart = $thickEnd; }

          my $utr = new EEDB::Feature;
          $utr->chrom($chrom);
          $utr->chrom_start($ustart);
          $utr->chrom_end($subfeat->chrom_end);
          $utr->strand($strand) if($strand);
          if($strand eq '-') { 
            $utr->feature_source($self->utr5_source); 
            $utr->primary_name($name . "_5utr") if($name);
          } else { 
            $utr->feature_source($self->utr3_source); 
            $utr->primary_name($name . "_3utr") if($name);
          }
          $multiLoad->store_feature($utr);
          printf("  %s\n", $utr->display_desc) if($self->debug); 

          my $edge = new EEDB::Edge;
          $edge->edge_source($self->sublink_source);
          $edge->feature1($utr);
          $edge->feature2($feature);        
          $multiLoad->store_edge($edge);
          printf("          %s\n", $edge->display_desc) if($self->debug>2);        
        }    
        
      } 
    }


    if($linecount % $self->{"display_interval"} == 0) { 
      my $rate = $linecount / (time() - $starttime);
      printf("%10d (%1.2f x/sec): %s\n", $linecount, $rate, $feature->display_desc); 
    }
    #last;
  }
  $gz->gzclose();
  
  $multiLoad->flush_buffers();
  
  $self->sync_importdates;

  my $total_time = time() - $starttime;
  my $rate = $linecount / $total_time;
  printf("TOTAL: %10d :: %1.3f min :: %1.2f x/sec\n", $linecount, $total_time/60.0, $rate);

}


1;

