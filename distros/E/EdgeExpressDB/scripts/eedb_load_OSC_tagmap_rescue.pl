#!/usr/local/bin/perl -w 

=head1 NAME - eedb_load_OSC_tagmap_rescue.pl

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

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use Switch;

use Bio::SeqIO;
use Bio::SimpleAlign;
use Bio::AlignIO;
use File::Temp;
use Compress::Zlib;
use Time::HiRes qw(time gettimeofday tv_interval);

use MQdb::Database;
use MQdb::MappedQuery;

use EEDB::FeatureSource;
use EEDB::EdgeSource;
use EEDB::Feature;
use EEDB::Edge;
use EEDB::Experiment;
use EEDB::Expression;
use EEDB::Tools::MultiLoader;

no warnings 'redefine';
$| = 1;

my $help;
my $passwd = '';

my $file = undef;
my $assembly_name = '';
my $url = undef;
my $update = 0;
my $store = 0;
my $debug=0;
my $sparse =0;

my $fsrc = undef;
my $fsrc_name = undef;
my $display_interval = 1000;
my $exp_prefix = undef;
my $library_id = undef;
my $sequencing_id = undef;
my $platform = '';
my $sym_type = undef;
my $use_multiloader = 1;
my $skip_tagseq = 0;
my $skip_tagmap = 0;

my @exp_column_types = ();
my $exp_col_count = 0;

GetOptions( 
            'url:s'        =>  \$url,
            'file:s'       =>  \$file,
            'assembly:s'   =>  \$assembly_name,
            'asm:s'        =>  \$assembly_name,
            'fsrc:s'       =>  \$fsrc_name,
            'exp_prefix:s' =>  \$exp_prefix,
            'symtype:s'    =>  \$sym_type,
            'platform:s'   =>  \$platform,
            'update'       =>  \$update,
            'store'        =>  \$store,
            'sparse'       =>  \$sparse,
            'skiptagseq'   =>  \$skip_tagseq,
            'skiptagmap'   =>  \$skip_tagmap,
            'debug:s'      =>  \$debug,
            'v'            =>  \$debug,
            'help'         =>  \$help
            );


if ($help) { usage(); }

my $eeDB = undef;
if($url) {
  $eeDB = MQdb::Database->new_from_url($url);
} 
unless($eeDB) { 
  printf("ERROR: connection to database\n\n");
  usage(); 
}

printf("\n==============\n");
printf("eeDB:: %s\n", $eeDB->url);

my $assembly = EEDB::Assembly->fetch_by_name($eeDB, $assembly_name);
unless($assembly) { printf("error fetching assembly [%s]\n\n", $assembly_name); usage(); }
$assembly->display_info;

unless($platform) {
  printf("ERROR: must specify -platform parameter\n\n");
  usage(); 
}

unless($file and (-e $file)) { 
  printf("ERROR: must specify _weighted_rescued.txt.gz file for data loading\n\n");
  usage(); 
}

if($file =~ /(.+)_weighted_rescued.txt.gz/) {
  $library_id = $1;
  if(!defined($fsrc_name)) {
    $fsrc_name= "tagmap::" . $platform . "_tagmap_".$library_id;
    $fsrc_name .= "_" . $exp_prefix if($exp_prefix);
  }
}
  
if($debug) {
  printf("== experiment config ==\n");
  printf("  expID: %s\n", $exp_prefix) if($exp_prefix);
  printf("  libID: %s\n", $library_id) if($library_id);
  printf("  seqID: %s\n", $sequencing_id) if($sequencing_id);
  printf("  fsrc : %s\n", $fsrc_name) if($fsrc_name);
}

if(defined($fsrc_name)) {
  my $category = undef;
  if($fsrc_name =~ /(.+)\:\:(.+)/) {
    $category = $1;
    $fsrc_name = $2;
    $fsrc = EEDB::FeatureSource->fetch_by_category_name($eeDB, $1, $2);
  } else {
    $fsrc = EEDB::FeatureSource->fetch_by_name($eeDB, $fsrc_name);
  }
  unless($fsrc){
    $fsrc = new EEDB::FeatureSource;
    $fsrc->name($fsrc_name);
    $fsrc->category($category);
    $fsrc->import_source($file);
    $fsrc->store($eeDB) if($store);
    printf("Needed to create:: ");
  }
  $fsrc->display_info;
} else {
  printf("ERROR must specify -fsrc param\n\n");
  usage();
}

#
# the general purpose seqtag feature source
#

my $tagseq_source = EEDB::FeatureSource->fetch_by_category_name($eeDB, "seqtag", $platform . "_seqtag");
unless($tagseq_source){
  $tagseq_source = new EEDB::FeatureSource;
  $tagseq_source->category("seqtag");
  $tagseq_source->name($platform . "_seqtag");
  $tagseq_source->import_source("");
  $tagseq_source->store($eeDB) if($store);
  printf("Needed to create:: ");
}
$tagseq_source->display_info;

#
# OK ready to process now
#

if($debug>2) { $skip_tagseq=1; }

my $error_path = $file . ".errors";
open(ERRORFILE, ">>", $error_path);

load_seqtags($file);
load_mapexpress($file);

close(ERRORFILE);

exit(1);

#########################################################################################

sub usage {
  print "eedb_load_tagmap_rescue.pl [options]\n";
  print "  -help               : print this help\n";
  print "  -url <url>          : URL to database\n";
  print "  -fsrc <name>        : name of the FeatureSource for column 1 data\n";
  print "  -file <path>        : path to a tsv file with expression data\n";
  print "  -platform <name>    : name of the experimental platform (eg nanoCAGE, 454CAGE, RNAseq..)\n";
  print "eedb_load_tagmap_rescue.pl v1.0\n";
  
  exit(1);  
}

#########################################################################################


# First routine loops through the file creating a unique set of seqtag metadata
# this should work in a parallel load environment, but there is a very very small
# probabilty of multiple inserts. But on the second pass it will only grab the 
# first occurance and do all linking to only one.  If needed a third pass through
# the database can remove the duplicated/unlinked sequence tags
sub load_seqtags {
  my $file = shift;

  return if($skip_tagseq);
    
  printf("============== load_seqtags ==============\n");
  my $starttime = time();
  my $linecount=0;
  my $line;
  my $multiLoad = new EEDB::Tools::MultiLoader;
  $multiLoad->database($eeDB);
  $multiLoad->do_store($store);
  
  my $last_seqtag='';
  my $unique_tag_count=0;
  my $new_feature_count = 0;
  my $gz = gzopen($file, "rb") ;
  while(my $bytesread = $gz->gzreadline($line)) {
    chomp($line);
    next if($line =~ /^\#/);
    $linecount++;
    $line =~ s/\r//g;
    
    #sequence        subject strand  start   end     edit    subject_sequence        map_position    A       E       P3      P5      P7      P9      P12     P18     P28     total
    #AAAAAAAAAAAAACTTTCTCAAGAA       chr12   -       26364765        26364789        M0AG    gaaaaaaaaaaaactttctcaagaa       1       0       1       0       0       0       0       0       0       0       1
    printf("LINE: %s\n", $line) if($debug>1);
    my ($seqtag)  = split(/\t/, $line);
    
    if($seqtag ne $last_seqtag) {
      #printf("newtag: %s\n", $seqtag);
      
      my $feature = undef;
      my $mdata = EEDB::Metadata->new('seqtag', $seqtag);
      if($mdata->check_exists_db($eeDB)) {
        #now check for feature
        ($feature) = @{EEDB::Feature->fetch_all_with_metadata($tagseq_source, $mdata)};      
      } else {
        #no metadata so create new feature with metadata
        $unique_tag_count++;
        $feature = undef;
      }

      unless($feature) {        
        $feature = new EEDB::Feature;
        $feature->feature_source($tagseq_source);
        $feature->chrom(undef);
        $feature->primary_name("seqtag");
        $feature->metadataset->add_metadata($mdata);
        $multiLoad->store_feature($feature);
        $new_feature_count++;
      }
    }
    $last_seqtag = $seqtag;
 
    if($linecount % $display_interval == 0) { 
      my $rate = $linecount / (time() - $starttime);
      printf("seqtag %10d (new uniq %d; new feature %d) (%1.2f x/sec)\n", $linecount, $unique_tag_count, $new_feature_count, $rate); 
    }
  }
  $gz->gzclose;

  $multiLoad->flush_buffers;  

  my $total_time = time() - $starttime;
  my $rate = $linecount / $total_time;
  printf("TOTAL: %10d (new uniq %d) :: %1.3f min :: %1.2f x/sec\n", $linecount, $unique_tag_count, $total_time/60.0, $rate);
}     



sub load_mapexpress {
  my $file = shift;

  return if($skip_tagmap);
  printf("============== load_mapexpress ==============\n");
  my $linecount=0;
  my $line;
  my $multiLoad = new EEDB::Tools::MultiLoader;
  $multiLoad->database($eeDB);
  $multiLoad->do_store($store);
 
  my $starttime = time();
  my $expname_hash = {};  #for debugging before store
    
  my $gz = gzopen($file, "rb") ;
  while(my $bytesread = $gz->gzreadline($line)) {
    chomp($line);
    next if($line =~ /^\#/);
    last if(($debug>2) and ($linecount>30));
    $line =~ s/\r//g;
    
    #sequence        subject strand  start   end     edit    subject_sequence        map_position    A       E       P3      P5      P7      P9      P12     P18     P28     total
    #AAAAAAAAAAAAACTTTCTCAAGAA       chr12   -       26364765        26364789        M0AG    gaaaaaaaaaaaactttctcaagaa       1       0       1       0       0       0       0       0       0       0       1

    printf("\n===LINE: %s\n", $line) if($debug>1);
    my ($fname,);
    my ($feature, $seq_mdata, $other);
    
    my @columns = split(/\t/, $line);

    my $seqtag = $columns[0]; #   1. uniq_tag_sequence - unique CAGE tag sequences
    my $tag_count_library = $columns[1]; #   2. tag_count_library - total tag counts in library. SUM( tag_count_timecourse ) = tag_count_library
    my $edit = $columns[2]; #   3. edit_string - what type of editing was performed on tag sequence when mapping to chromosome
    my $chrname     = $columns[3]; #   4. chr - chromosome
    my $strand = $columns[4]; #   5. strand - tag direction
    my $start = $columns[5]; #   6. start - starting position
    my $end = $columns[6]; #   7. end - ending position
    my $percmatch = $columns[7]; #   8. percentage - percent match (always 100)
    my $map_count = $columns[8]; #   9. map_pos - number of locations this tag mapped to the chromosome
    my $ribo_flag = $columns[9]; #  10. ribo_flag - tag mapped to ribosome equal or better than chromosome?
    my $refseq_flag = $columns[10]; #  11. refseq_flag - tag mapped to refseq better than chromosome?
    my $time_course = $columns[11]; #  12. time_course - time course which tag appeared
    my $tag_count_timecourse = $columns[12]; #  13. tag_count_timecourse - number of tags with specified timecourse
    my $tpm_in_ribo = $columns[13]; #  14. tpm_in_ribo - tag per million per timecourse including ribosome flagged tags
    my $tpm_ex_ribo = $columns[14]; #  15. tpm_ex_ribo - tag per million per timecourse excluding ribosome_flagged tags
    my $weight = $columns[15]; #  16. weight - weight of expression. This is just internal value, and please ignore this column for  subsequent analysis
    my $rescue_weight = $columns[16]; #  17. rescue_weight - weight from "guilt-by-association" rescue

    $linecount++;
    
    #if($ribo_flag) {
    #  print("  skip RIBOSOME\n") if($debug>1);
    #  next;
    #}
    
    if($strand eq "-") { $fname = "map_" . join("_", $chrname, $strand, $end); }
    else { $fname = "map_" . join("_", $chrname, $strand, $start); }
   
    #
    # first create the unique seqtag metadata element
    #
    ($seq_mdata, $other) = @{EEDB::Metadata->fetch_all_by_data($eeDB, $seqtag, 'seqtag')};
    if(defined($other)) { 
      printf(ERRORFILE "WARNING seqtag [%s] in database more than once\n", $seqtag); 
    }
    unless($seq_mdata) { 
      #printf("create new mdata '%s'\n", $seqtag);
      $seq_mdata = EEDB::Metadata->new('seqtag', $seqtag);
      $seq_mdata->store($eeDB) if($store);
    }
    #$seq_mdata->display_info;
   
    #
    # next create the mapping feature
    #
    if($update) {
      ($feature, $other) = @{EEDB::Feature->fetch_all_by_primary_name($eeDB, $fname, $fsrc)};
      if(defined($other)) { 
        printf(ERRORFILE "ERROR LINE: %s\n  feature [%s] in database more than once for FeatureSource [%s]", $line, $fname, $fsrc->name); 
      }
    }
    
    unless($feature) { 
      my $chrom = EEDB::Chrom->fetch_by_name_assembly_id($eeDB, $chrname, $assembly->id);
      unless($chrom) { #create the chromosome;
        $chrom = new EEDB::Chrom;
        $chrom->chrom_name($chrname);
        $chrom->assembly($assembly);
        $chrom->chrom_type('chromosome');
        $chrom->store($eeDB) if($store);
        printf("need to create chromosome :: %s\n", $chrom->display_desc);
      }
     
      $feature = new EEDB::Feature;
      $feature->feature_source($fsrc);
      $feature->primary_name($fname);
      $feature->chrom($chrom);
      $feature->chrom_start($start);
      $feature->chrom_end($end);
      $feature->strand($strand);
      #$feature->add_symbol($fsrc->category, $fname);
    }
    $feature->metadataset->add_metadata($seq_mdata);

    $feature->metadataset->add_tag_symbol("edit", $edit);
    $feature->metadataset->add_tag_symbol("ribo_flag", $ribo_flag) if($ribo_flag);
    $feature->metadataset->add_tag_symbol("refseq_flag", $refseq_flag) if($refseq_flag);

    $feature->metadataset->convert_bad_symbols;    
    $feature->metadataset->remove_duplicates;

    if($debug and ($debug <2)) { $feature->display_info; }
    if($debug and ($debug >= 2)) { print($feature->display_contents); }


    #
    # get experiment
    #
    my $expname = $time_course ."_". $library_id;
    if($exp_prefix) { $expname = $exp_prefix . '_'. $expname; }
    $expname =~ s/\s+/_/g;
    
    my $experiment = $expname_hash->{$expname};    
    unless($experiment) {
      $experiment = EEDB::Experiment->fetch_by_exp_accession($eeDB, $expname);
      $expname_hash->{$expname} = $experiment;
    }
    unless($experiment) {      
      $experiment = new EEDB::Experiment;
      $experiment->exp_accession($expname);
      $experiment->series_name($time_course);
      $experiment->series_point(1);
      $experiment->platform($platform);
      $experiment->metadataset->add_tag_symbol("osc_libID", $library_id) if($library_id);
      $experiment->metadataset->add_tag_symbol("osc_sequencingID", $sequencing_id) if($sequencing_id);

      my $mdata = $experiment->metadataset->add_tag_data("series_name", $time_course);
      $mdata->check_exists_db($eeDB);
      $experiment->metadataset->merge_metadataset($mdata->extract_keywords);

      $experiment->store($eeDB);# if($store);

      print($experiment->display_contents) if($debug);
      $expname_hash->{$expname} = $experiment;
    }
    if($debug>1) { printf("   %s\n", $experiment->display_desc); }


    #
    # now do the expressions
    #
    $feature->add_expression_data($experiment, "tagcnt_lib", $tag_count_library);
    $feature->add_expression_data($experiment, "tagcnt_series", $tag_count_timecourse);
    $feature->add_expression_data($experiment, "multimap_cnt", $map_count);
    $feature->add_expression_data($experiment, "tpm_in_ribo", $tpm_in_ribo);
    $feature->add_expression_data($experiment, "tpm_ex_ribo", $tpm_ex_ribo);
    $feature->add_expression_data($experiment, "weight", $weight);
    $feature->add_expression_data($experiment, "rescue_weight", $rescue_weight);
    

    if($debug>1) {
      foreach my $express (sort {$a->experiment->id <=> $b->experiment->id} @{$feature->get_expression_array}) {
        printf("   %s\n", $express->display_desc);
      }
    }
    
    $multiLoad->store_feature($feature);

    if($linecount % 200 == 0) { 
      my $rate = $linecount / (time() - $starttime);
      printf("%10d (%1.2f x/sec): %s\n", $linecount, $rate, $feature->display_desc); 
    }
  }
  $gz->gzclose;
  
  $multiLoad->flush_buffers;
  
  my $total_time = time() - $starttime;
  my $rate = $linecount / $total_time;
  printf("TOTAL: %10d :: %1.3f min :: %1.2f x/sec\n", $linecount, $total_time/60.0, $rate);
}


