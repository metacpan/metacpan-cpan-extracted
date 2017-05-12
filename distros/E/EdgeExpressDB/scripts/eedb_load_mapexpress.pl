#!/usr/local/bin/perl -w 

=head1 NAME - eedb_load_mapexpress.pl

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
my ($library_id, $sequencing_id);
my $platform = '';
my $sym_type = undef;
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

unless($file and (-e $file)) { 
  printf("ERROR: must specify _results.txt.gz file for data loading\n\n");
  usage(); 
}

unless($platform) { 
  printf("ERROR: must specify -platform\n\n");
  usage(); 
}

if(!$exp_prefix and ($file =~ /(.+)(\w)_result.txt.gz/)) {
  $exp_prefix = $1 . $2;
  $library_id = $1;
  $sequencing_id = $exp_prefix;
  if(!defined($fsrc_name)) {
    $fsrc_name= "tagmap::" . $platform . "_tagmap_".$exp_prefix;
  }
  if($debug) {
    printf("  expID: %s\n", $exp_prefix);
    printf("  libID: %s\n", $library_id);
    printf("  seqID: %s\n", $sequencing_id);
    printf("  fsrc : %s\n", $fsrc_name);
  }
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
    if($store) { $fsrc->store($eeDB); }
    else { $fsrc->primary_id(-1); }
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
  if($store) { $tagseq_source->store($eeDB); }
  else { $tagseq_source->primary_id(-1); }
  printf("Needed to create:: ");
}
$tagseq_source->display_info;

my $seqtag_2_map = EEDB::EdgeSource->create_from_name("seq2map::seqtag_2_tagmap");
if($store) { $seqtag_2_map->store($eeDB); }
else { $seqtag_2_map->primary_id(-1); }
$seqtag_2_map->display_info;

#
# OK ready to process now
#

my $error_path = $file . ".errors";
open(ERRORFILE, ">>", $error_path);

read_header();
calc_exp_total_express();

load_seqtags() unless($debug>2);
load_mapexpress();

close(ERRORFILE);

exit(1);

#########################################################################################

sub usage {
  print "eedb_load_mapexpress.pl [options]\n";
  print "  -help               : print this help\n";
  print "  -url <url>          : URL to database\n";
  print "  -fsrc <name>        : name of the FeatureSource for column 1 data\n";
  print "  -file <path>        : path to a tsv file with expression data\n";
  print "eedb_load_mapexpress.pl v1.0\n";
  
  exit(1);  
}

#########################################################################################


# First routine loops through the file creating a unique set of seqtag metadata
# this should work in a parallel load environment, but there is a very very small
# probabilty of multiple inserts. But on the second pass 
sub load_seqtags {
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
  my $gz = gzopen($file, "rb") ;
  while(my $bytesread = $gz->gzreadline($line)) {
    chomp($line);
    next if($line =~ /^\#/);
    next if($line eq "");
    $linecount++;
    $line =~ s/\r//g;
    
    #sequence        subject strand  start   end     edit    subject_sequence        map_position    A       E       P3      P5      P7      P9      P12     P18     P28     total
    #AAAAAAAAAAAAACTTTCTCAAGAA       chr12   -       26364765        26364789        M0AG    gaaaaaaaaaaaactttctcaagaa       1       0       1       0       0       0       0       0       0       0       1
    printf("LINE: %s\n", $line) if($debug>1);
    my ($seqtag)  = split(/\t/, $line);
    
    if($seqtag ne $last_seqtag) {      
      my ($feature, $other) = @{EEDB::Feature->fetch_all_by_primary_name($eeDB, $seqtag, $tagseq_source)};
      unless($feature) {        
        $feature = new EEDB::Feature;
        $feature->feature_source($tagseq_source);
        $feature->primary_name($seqtag);
        $multiLoad->store_feature($feature);
        $unique_tag_count++;
      }
    } 
    $last_seqtag = $seqtag;
 
    if($linecount % $display_interval == 0) { 
      my $rate = $linecount / (time() - $starttime);
      printf("seqtag %10d (new uniq %d) (%1.2f x/sec)\n", $linecount, $unique_tag_count, $rate); 
    }
  }
  $multiLoad->flush_buffers;
  $gz->gzclose;

  my $total_time = time() - $starttime;
  my $rate = $linecount / $total_time;
  printf("TOTAL: %10d (new uniq %d) :: %1.3f min :: %1.2f x/sec\n", $linecount, $unique_tag_count, $total_time/60.0, $rate);
}     



sub load_mapexpress {
  return if($skip_tagmap);
  printf("============== load_mapexpress ==============\n");
  my $linecount=0;
  my $line;
  my $multiLoad = new EEDB::Tools::MultiLoader;
  $multiLoad->database($eeDB);
  $multiLoad->do_store($store);
 
  my $starttime = time();
    
  my $gz = gzopen($file, "rb") ;
  while(my $bytesread = $gz->gzreadline($line)) {
    chomp($line);
    next if($line =~ /^\#/);
    next if($line eq "");
    last if(($debug>2) and ($linecount>10));
    $line =~ s/\r//g;
    
    #sequence        subject strand  start   end     edit    subject_sequence        map_position    A       E       P3      P5      P7      P9      P12     P18     P28     total
    #AAAAAAAAAAAAACTTTCTCAAGAA       chr12   -       26364765        26364789        M0AG    gaaaaaaaaaaaactttctcaagaa       1       0       1       0       0       0       0       0       0       0       1

    printf("LINE: %s\n", $line) if($debug>1);
    my ($fname, $seqtag, @expression);
    my ($chrname, $start, $end, $strand, $edit, $subj_seq);
    my ($feature, $other);
    
    ($seqtag, $chrname, $strand, $start, $end, $edit, $subj_seq, @expression)  = split(/\t/, $line);
    next if($strand eq "strand"); #a header line

    $linecount++;
    
    if($strand eq "-") { $fname = "map_" . join("_", $chrname, $strand, $end); }
    else { $fname = "map_" . join("_", $chrname, $strand, $start); }
      
    #
    # create the mapping feature with expression
    #
    if($update) {
      ($feature, $other) = @{EEDB::Feature->fetch_all_by_primary_name($eeDB, $fname, $fsrc)};
      if(defined($other)) { 
        printf(ERRORFILE "ERROR LINE: %s\n  feature [%s] in database more than once for FeatureSource [%s]", $line, $fname, $fsrc->name); 
      }
    }

    #
    # get the seqtag if it is loaded
    #
    my $seqtag_feature=undef;
    if(!$skip_tagseq) {
      ($seqtag_feature) = @{EEDB::Feature->fetch_all_by_primary_name($eeDB, $seqtag, $tagseq_source)};
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
    if($skip_tagseq) {
      $feature->metadataset->add_tag_data("seqtag", $seqtag);
    }

    if($debug and ($debug <2)) { $feature->display_info; }
    if($debug and ($debug >= 2)) { print($feature->display_contents); }

    #
    # first store the mapcount
    #    
    my $mapcount      = $expression[0];
    my $expobj        = $exp_column_types[0];
    my $experiment    = $expobj->{'experiment'};
    $feature->add_expression_data($experiment, "mapcount", $mapcount);

    #
    # now do the expressions
    #    
    for(my $x=1; $x<$exp_col_count; $x++) {
      my $expobj          = $exp_column_types[$x];
      my $experiment      = $expobj->{'experiment'};
      my $datatype        = $expobj->{'type'};
      my $colname         = $expobj->{'colname'};
      my $total_express   = $expobj->{'total'};
      my $singlemap_total = $expobj->{'singlemap_total'};
      
      my $value = $expression[$x];
      if($sparse and ($value == 0.0)) { next; }
      
      if($debug>2) {
        printf("\ncolnum   : %d\n", $x);
        printf("colname  : %s\n", $colname);
        printf("exp      : %s\n", $experiment);
        printf("expid    : %s\n", $experiment->id);
        printf("type     : %s\n", $datatype);
        printf("value    : %s\n", $value);
      }
      
      if($mapcount == 1) {
        $feature->add_expression_data($experiment, "singlemap_tagcnt", $value);
        $feature->add_expression_data($experiment, "singlemap_tpm", $value * 1000000.0 / $singlemap_total);
      }
      
      $feature->add_expression_data($experiment, "mapnorm_tagcnt", $value / $mapcount);
      $feature->add_expression_data($experiment, "mapnorm_tpm", $value / $mapcount * 1000000.0 / $total_express);
    }
    
    if($debug>1) {
      foreach my $express (sort {$a->experiment->id <=> $b->experiment->id} @{$feature->get_expression_array}) {
        printf("   %s\n", $express->display_desc);
      }
    }
    $multiLoad->store_feature($feature);    

    #
    # create edge to the seqtag if it is loaded
    #
    if($seqtag_feature) {
      my $edge = new EEDB::Edge;
      $edge->edge_source($seqtag_2_map);
      $edge->feature1($seqtag_feature);
      $edge->feature2($feature);
      $multiLoad->store_edge($edge);    
    }

    if($linecount % $display_interval == 0) { 
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


###################################
#
# experiment related section
#
###################################

sub read_header {  
  if(!$exp_prefix and ($file =~ /(.+)(\w)_result.txt.gz/)) {
    $exp_prefix = $1 . $2;
    $library_id = $1;
    $sequencing_id = $exp_prefix;
  }
  
  my $linecount=0;
  my $line;
  my $gz = gzopen($file, "rb") ;
  while(my $bytesread = $gz->gzreadline($line)) {
    chomp($line);
    next if(($line =~ /^\#/) and !($line =~/^\# sequence/));
    $linecount++;
    $line =~ s/\r//g;
    
    #sequence        subject strand  start   end     edit    subject_sequence        map_position    A       E       P3      P5      P7      P9      P12     P18     P28     total
    #AAAAAAAAAAAAACTTTCTCAAGAA       chr12   -       26364765        26364789        M0AG    gaaaaaaaaaaaactttctcaagaa       1       0       1       0       0       0       0       0       0       0       1

    printf("LINE: %s\n", $line) if($debug>1);
    my ($fname, $seqtag, @expression);
    my ($chrname, $start, $end, $strand, $edit, $subj_seq);
    my ($feature);
    
    ($seqtag, $chrname, $strand, $start, $end, $edit, $subj_seq, @expression)  = split(/\t/, $line);
    
    if($linecount == 1) {
      create_experiments(@expression);
      last;
    }
  }
  $gz->gzclose;
}

# simple routine loops through the file calculating the total tag counts
# to be used in TPM calculations
sub calc_exp_total_express {  
  printf("============== calc_exp_total_express ==============\n");
  my $starttime = time();
  my $linecount=0;
  my $line;  
  my $gz = gzopen($file, "rb") ;
  while(my $bytesread = $gz->gzreadline($line)) {
    chomp($line);
    next if($line =~ /^\#/);
    next if($line eq "");
    $linecount++;
    $line =~ s/\r//g;
    
    #sequence        subject strand  start   end     edit    subject_sequence        map_position    A       E       P3      P5      P7      P9      P12     P18     P28     total
    #AAAAAAAAAAAAACTTTCTCAAGAA       chr12   -       26364765        26364789        M0AG    gaaaaaaaaaaaactttctcaagaa       1       0       1       0       0       0       0       0       0       0       1
    my ($seqtag, $chrname, $strand, $start, $end, $edit, $subj_seq, @expression)  = split(/\t/, $line);
    
    my $mapcount = $expression[0];
    unless($mapcount) {  printf("error: %s\n", $line); }
    for(my $x=1; $x<$exp_col_count; $x++) {
      my $expobj = $exp_column_types[$x];      
      $expobj->{'total'} += $expression[$x] / $mapcount ;
      if($mapcount == 1) {
        $expobj->{'singlemap_total'} += $expression[$x];
      }
    }
 
    if($linecount % 50000 == 0) { 
      my $rate = $linecount / (time() - $starttime);
      printf("totalcalc %10d (%1.2f x/sec)\n", $linecount, $rate); 
    }
  }
  $gz->gzclose;
  
  for(my $x=1; $x<$exp_col_count; $x++) {
    my $expobj = $exp_column_types[$x];      
    my $experiment = $expobj->{'experiment'};
    
    my $total = sprintf("%1.2f", $expobj->{'total'});
    $expobj->{'total'} = $total; #rounds to 2 decimal places
    
    my $mdata = $experiment->metadataset->add_tag_data("total_tag_count", $total);
    unless($mdata->check_exists_db($eeDB)) {
      $experiment->store_metadata if($store);
    }
    $mdata = $experiment->metadataset->add_tag_data("total_singlemap_tag_count", $expobj->{"singlemap_total"});
    unless($mdata->check_exists_db($eeDB)) {
      $experiment->store_metadata if($store);
    }

    $experiment->display_info;
    printf("    %1.2f total tag count\n", $total);
    printf("    %1.2f total singlemap tag count\n", $expobj->{"singlemap_total"});
    printf("  %1.3f%% singlemap\n", 100* $expobj->{"singlemap_total"}/ $total);
  }

  my $total_time = time() - $starttime;
  my $rate = $linecount / $total_time;
  printf("TOTAL: %10d :: %1.3f min :: %1.2f x/sec\n", $linecount, $total_time/60.0, $rate);
}     


sub create_experiments {
  my @column_names_list = @_;
  
  if(@exp_column_types) { return; } #if I have already read the header then return
  
  printf("====== create experiments ======\n");
  #Detection.xxxx  or   Raw.xxxx or Norm.xxxx, if no prefix defaults to "raw"
    
  my $expname_hash = {};  #for debugging before store
  @exp_column_types = ();
  $exp_col_count = 0;
  
  foreach my $colname (@column_names_list) {
    #printf("== %s\n", $colname);
    my $datatype = 'raw';
    my $exp_name = $colname;
    
    if($colname eq "map_position") { $exp_name = "mapcount"; }
    if($colname eq "total") { next; }
    
    $exp_name =~ s/\s/_/g;
    my $fullname = $exp_name;
    if($exp_prefix) { $fullname = $exp_prefix .'_'. $exp_name; }
    
    my $experiment = $expname_hash->{$fullname};
    
    unless($experiment) {
      $experiment = EEDB::Experiment->fetch_by_exp_accession($eeDB, $fullname);
      $expname_hash->{$fullname} = $experiment;
    }
    unless($experiment) {      
      $experiment = new EEDB::Experiment;
      $experiment->exp_accession($fullname);
      $experiment->series_name($exp_prefix);
      $experiment->series_point($exp_col_count);
      $experiment->platform($platform);
      $experiment->metadataset->add_tag_symbol("osc_libID", $library_id) if($library_id);
      $experiment->metadataset->add_tag_symbol("osc_sequencingID", $sequencing_id) if($sequencing_id);
      
      my @keywords = split(/_/, $fullname);
      foreach my $keyw (@keywords) {
        $experiment->metadataset->add_tag_symbol('keyword', $keyw);
      }

      if($store) { $experiment->store($eeDB); }
      else {$experiment->primary_id($exp_col_count); } #for debugging and certain tools

      #$experiment->display_info if($debug);
      $expname_hash->{$fullname} = $experiment;
    }
    my $expobj = {'colname'=>$colname, 
                  'type'=>$datatype, 
                  'expname'=>$fullname, 
                  'total'=>0, 
                  'singlemap_total'=>0, 
                  'experiment'=>$experiment};
    printf("== %25s  %10s    %s\n", $colname, $datatype, $experiment->display_desc);
    push @exp_column_types, $expobj;
    $exp_col_count++;
  }
  
  printf("loaded %d exp columns\n", scalar(@exp_column_types));
}

