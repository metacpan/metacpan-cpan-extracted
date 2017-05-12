#!/usr/local/bin/perl -w 

=head1 NAME - eedb_load_affychip.pl

=head1 SYNOPSIS

=head1 DESCRIPTION

This script is still a bit under development.  If used carefully and working
one file at a time and checking the loading, it should load a reference 
Affymetrix chip desccription.  It does not load expression from a chip
experiment yet.  It has only been tested on the Rat Genome 230 2.0 Array chip.

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
use Bio::Tools::dpAlign;

use File::Temp;
use Compress::Zlib;
use Time::HiRes qw(time gettimeofday tv_interval);


use MQdb::Database;
use MQdb::MappedQuery;

use EEDB::FeatureSource;
use EEDB::EdgeSource;
use EEDB::Feature;
use EEDB::Edge;
use EEDB::Chrom;
use EEDB::Experiment;
use EEDB::Expression;
use EEDB::Tools::MultiLoader;
use EEDB::Tools::BEDLoader;
use EEDB::Tools::PSLLoader;
    
no warnings 'redefine';
$| = 1;

my $help;
my $passwd = '';

my $dir = undef;
my $url = undef;
my $store = 0;
my $debug=0;
my $csv=0;

my $fsrc = undef;
my $fsrc_name = undef;
my $description = undef;
my $display_interval = 100;

my @data_column_types = ();
my $primary_datatype = undef;
my $data_col_count = 0;
my $assembly_name=undef;

GetOptions( 
            'url:s'        =>  \$url,
            'dir:s'        =>  \$dir,
            'fsrc:s'       =>  \$fsrc_name,
            'desc:s'       =>  \$description,
            'assembly:s'   =>  \$assembly_name,
            'asm:s'        =>  \$assembly_name,
            'csv'          =>  \$csv,
            'store'        =>  \$store,
            'v'            =>  \$debug,
            'debug:s'      =>  \$debug,
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

if(!defined($fsrc_name)) {
  printf("ERROR must specify -fsrc param\n\n");
  usage();
}

unless(defined($assembly_name)) {
  printf("ERROR: must supply -assembly parameter\n\n");
  usage();
}
my $assembly = EEDB::Assembly->fetch_by_name($eeDB, $assembly_name);
unless(defined($assembly)) {
  printf("ERROR: assembly [%s] not in database\n\n", $assembly_name);
  usage();
}
$assembly->display_info;

if(!$dir or !(-e $dir) or !(-d $dir)) { 
  printf("ERROR: must specify -dir path to directory of Affy GeneChip files\n\n");
  usage(); 
}

my $storeDB = $eeDB if($store);

###
# probe source

my $probe_source = undef;
my $category = "GeneChip";
if($fsrc_name =~ /(\w+)\:\:(.+)/) {
  #$category = $1;
  $fsrc_name = $2;
} 

######
$probe_source = EEDB::FeatureSource->fetch_by_category_name($eeDB, $category, $fsrc_name."_probeset");
unless($probe_source){
  $probe_source = new EEDB::FeatureSource;
  $probe_source->name($fsrc_name."_probeset");
  $probe_source->category($category);
  $probe_source->import_source(""); 
  $probe_source->store($eeDB) if($store);
  printf("Needed to create:: ");
}
$probe_source->display_info;

######
my $probeloc_source = EEDB::FeatureSource->fetch_by_category_name($eeDB, "GeneChip_probeloc", $fsrc_name."_probeloc");
if(!$probeloc_source) {
  $probeloc_source = EEDB::FeatureSource->create_from_name("GeneChip_probeloc::". $fsrc_name . "_probeloc", $storeDB);
}
$probeloc_source->display_info;
 
######
my $block_source = EEDB::FeatureSource->fetch_by_category_name($eeDB, "block", $fsrc_name."_probeloc_block");
if(!$block_source) {
  $block_source = EEDB::FeatureSource->create_from_name("block::". $fsrc_name . "_probeloc_block", $storeDB);
}
$block_source->display_info;

######
my $link_name = $fsrc_name . "_probeloc_subfeature";
my $block_edgesource = EEDB::EdgeSource->fetch_by_name($eeDB, $link_name);
unless($block_edgesource){
  $block_edgesource = new EEDB::EdgeSource;
  $block_edgesource->category("subfeature");
  $block_edgesource->name($link_name);
  $block_edgesource->store($eeDB) if($store);
}
$block_edgesource->display_info;

######
my $probe2loc_name = $fsrc_name . "_probe-to-loc";
my $probe2loc_edgesource = EEDB::EdgeSource->fetch_by_name($eeDB, $probe2loc_name);
unless($probe2loc_edgesource){
  $probe2loc_edgesource = new EEDB::EdgeSource;
  $probe2loc_edgesource->category("probe-to-loc");
  $probe2loc_edgesource->name($probe2loc_name);
  $probe2loc_edgesource->store($eeDB) if($store);
}
$probe2loc_edgesource->display_info;

#########################
 
 
opendir(DIR, $dir);
my @files= readdir(DIR); 

my $csv_meta_file = undef;
my $probe_fasta_file = undef;
my $psl_file = undef;
my $cdf_file = undef;


#must load the probe and metadata first
foreach my $file (@files) {
  if($file =~ /\.csv$/)  { $csv_meta_file = $dir."/".$file; }
  if($file =~ /probe_fasta$/) { $probe_fasta_file = $dir."/".$file; }
  if($file =~ /link\.psl$/)   { $psl_file = $dir."/".$file; }
  if($file =~ /\.cdf$/)       { $cdf_file = $dir."/".$file; }
}

if($csv_meta_file) { load_probeset_metadata($csv_meta_file); }

if($probe_fasta_file) { load_probeseq($probe_fasta_file); } 

if($psl_file) { realign_probes_from_psl($psl_file); }

link_probe_to_location();

if($cdf_file) { load_cdf_file($cdf_file); }

closedir(DIR);

exit(1);

#########################################################################################

sub usage {
  print "eedb_load_affychip.pl [options]\n";
  print "  -help               : print this help\n";
  print "  -url <url>          : URL to database\n";
  print "  -fsrc <name>        : name of the FeatureSource for column 1 data\n";
  print "  -file <path>        : path to a tsv file with expression data\n";
  print "eedb_load_affychip.pl v1.0\n";
  
  exit(1);  
}

#########################################################################################


sub load_probeset_metadata {
  my $file = shift;

  printf("load probe metadata:: %s\n", $file);

  my $multiLoad = new EEDB::Tools::MultiLoader;
  $multiLoad->database($eeDB);
  $multiLoad->do_store($store);

  my $error_path = $file . ".errors";
  open(ERRORFILE, ">>", $error_path);

  printf("==============\n");
  my $starttime = time();

  my $linecount=0;
  my $gz = gzopen($file, "rb") ;
  my $line;
  while(my $bytesread = $gz->gzreadline($line)) {
    chomp($line);
    next if($line =~ /^\#/);
    $linecount++;
    $line =~ s/\r//g;
    printf("LINE: $line\n") if($debug>1);
    
    #first column is the primaryID used for looking up unique entries

    my ($primaryID, @datacolumns);
    ($primaryID, @datacolumns) = split(/\"\,\"/, $line); 
    
    $primaryID =~ s/^\"//; #"
    $primaryID =~ s/\"$//; #"

    if($linecount == 1) {
      $primary_datatype = $primaryID;
      $primary_datatype =~ s/\s/_/g;
      @data_column_types = @datacolumns;
      $data_col_count = scalar(@data_column_types);
      next;
    }
    
    my $feature = undef;
    #my ($feature, $other) = @{EEDB::Feature->fetch_all_by_source_symbol($eeDB, $probe_source, $primaryID, $primary_datatype)};
    #if(defined($other)) { 
    #  printf(ERRORFILE "ERROR LINE: %s\n  feature [%s] in database more than once for FeatureSource [%s]", $line, $primaryID, $probe_source->name); 
    #}
    unless($feature) { 
      $feature = new EEDB::Feature;
      $feature->feature_source($probe_source);      
      $feature->primary_name($primaryID);
      $feature->metadataset->add_tag_symbol($primary_datatype, $primaryID);
      #$feature->store($eeDB) if($store);
      #$multiLoad->store_feature($feature);
    }
    
    for(my $x=0; $x<$data_col_count; $x++) {
      my $datatype = $data_column_types[$x];
      my $value    = $datacolumns[$x];
      
      $datatype =~ s/^\"//; #"
      $datatype =~ s/\"$//; #"
      $datatype =~ s/\s/_/g;
      
      $value =~ s/^\"//; #"
      $value =~ s/\"$//; #"
      $value =~ s/\s*\/+\s*/,/g;
      
      next if(!$value);
      next if($value eq "");
      next if($value eq "---");
      
      printf("tag[%20s] :: [%s]\n", $datatype, $value) if($debug>1);

      if($datatype eq "seqname") {
        my $chrom = EEDB::Chrom->fetch_by_assembly_chrname($assembly, $value);
        if($chrom) { $feature->chrom($chrom); }
      }
      if($datatype eq "start") {
        $feature->chrom_start($value);
      }
      if($datatype eq "stop") {
        $feature->chrom_end($value);
      }
      if($datatype eq "strand") {
        $feature->strand($value);
      }

      if(($value =~ /\s/) or ($value =~ /\,/) or (length($value)>64)) {
        #if has whitespace or it is long then this is Metadata
        $feature->metadataset->add_tag_data($datatype, $value);
      } else {
        $feature->metadataset->add_tag_symbol($datatype, $value);
      }
    }
    $feature->metadataset->remove_duplicates;
    #$feature->store_metadata() if($store);
    $multiLoad->store_feature($feature);
    #$feature->store($eeDB) if($store);

    if($debug) { print($feature->display_contents()); }

    if($linecount % $display_interval == 0) { 
      my $rate = $linecount / (time() - $starttime);
      printf("%10d (%1.2f x/sec): %s\n", $linecount, $rate, $feature->simple_display_desc); 
    }
  }
  $gz->gzclose();
  close(ERRORFILE);
  $multiLoad->flush_buffers();


  my $total_time = time() - $starttime;
  my $rate = $linecount / $total_time;
  printf("TOTAL: %10d :: %1.3f min :: %1.2f x/sec\n", $linecount, $total_time/60.0, $rate);
}


sub load_probeseq {
  my $file = shift;
  
  my $error_path = $file . ".errors";
  open(ERRORFILE, ">>", $error_path);

  printf("load probe FASTA:: %s\n", $file);
  
  my $starttime = time();
  my $linecount=0;
  my $feature = undef;
  my $in_seq = Bio::SeqIO->new( -file=>$file, -format => 'fasta');
  while (my $seq = $in_seq->next_seq()) {
    my $name = $seq->id;
    $name =~ s/\;$//g;
    if($name =~ /(.+)\:(.+)/) {
      $name = $2;
    }
    if(!$feature or ($feature->primary_name ne $name)) {
      if($feature) {
        $feature->metadataset->remove_duplicates;
        $feature->store_metadata() if($store);
        if($debug) { print($feature->display_contents); }
      }
      
      ($feature) = @{EEDB::Feature->fetch_all_by_source_symbol($eeDB, $probe_source, $name)};
      #if($feature) { print($feature->simple_display_desc, "\n"); }
      if(!$feature) {
        printf(ERRORFILE "ERROR LINE: probe [%s] not in database", $name); 
        next;
      }
      $linecount++;
      if($linecount % $display_interval == 0) { 
        my $rate = $linecount / (time() - $starttime);
        printf("%10d (%1.2f x/sec): %s\n", $linecount, $rate, $feature->simple_display_desc); 
      }
    }
    $feature->metadataset->add_tag_data("probeseq", $seq->seq);
  }
  close(ERRORFILE);

  my $total_time = time() - $starttime;
  my $rate = $linecount / $total_time;
  printf("TOTAL: %10d :: %1.3f min :: %1.2f x/sec\n", $linecount, $total_time/60.0, $rate);
}


sub load_probeloc {
  my $file = shift;
  
  if(!$file or !(-e $file)) { return; }
  
  printf("load probeloc:: %s\n", $file);

  my $loader = new EEDB::Tools::PSLLoader;
  $loader->database($eeDB);
  $loader->assembly($assembly);
  $loader->do_store($store);
  $loader->debug($debug);
  $loader->import_blocks(1);
  $loader->source_name("GeneChip_probeloc::". $fsrc_name . "_probeloc");

  if(!($loader->feature_source)) {
    printf("ERROR must specify -fsrc param\n\n");
    usage();
  }

  $loader->load_features($file);
}


sub realign_probes_from_psl {
  my $file = shift;
  
  my $error_path = $file . ".errors";
  open(ERRORFILE, ">>", $error_path);

  printf("\n==============\n");
  my $starttime = time();
  my $linecount=0;
  
  my $multiLoad = new EEDB::Tools::MultiLoader;
  $multiLoad->database($eeDB);
  $multiLoad->do_store($store);

  my $corePeer = EEDB::Peer->fetch_by_name($eeDB, "eeDB_core");
  my $core_assembly = EEDB::Assembly->fetch_by_name($corePeer->peer_database, $assembly->ucsc_name);

  # create a dpAlign object
  # to do local alignment, specify DPALIGN_LOCAL_MILLER_MYERS
  # to do global alignment, specify DPALIGN_GLOBAL_MILLER_MYERS
  # to do ends-free alignment, specify DPALIGN_ENDSFREE_MILLER_MYERS
  my $dpfactory = new Bio::Tools::dpAlign(-match => 3,
                                          -mismatch => -1,
                                          -gap => 3,
                                          -ext => 1,
                                          -alg => Bio::Tools::dpAlign::DPALIGN_LOCAL_MILLER_MYERS);
  my $seqio_debug = Bio::SeqIO->new( -fh =>\*STDOUT, -format => 'fasta');
  my $alnout_debug = Bio::AlignIO->new(-format=>"pfam", -fh=> \*STDOUT);

  #######################
  
  my $gz = gzopen($file, "rb") ;
  my $line;
  my $trackcount=0;
  while(my $bytesread = $gz->gzreadline($line)) {
    chomp($line);
    next if($line =~ /^\#/);
    if($line =~ /^track/) {
      $trackcount++;
      if($trackcount>1) { last;}
      next;
    }
    $linecount++;
    $line =~ s/\r//g;
    printf("LINE: $line\n") if($debug>2);

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
    
    if($start>$end) {
      my $t=$start;
      $start = $end;
      $end = $t;
    }
    #PSL format is 0 reference and eeDB is 1 referenced
    #because PSL is not-inclusive, but eeDB is inclusive I do not need to +1 to the end
    $start += 1;
    
    if($linecount % ($display_interval/5) == 0) { 
      my $rate = $linecount / (time() - $starttime);
      printf("%10d (%1.2f x/sec)\n", $linecount, $rate); 
      #printf("  chrom cache size: %d\n", EEDB::Chrom::get_cache_size);
    }
            
    my $chrom = EEDB::Chrom->fetch_by_assembly_chrname($assembly, $chrname);
    if(!$chrom) { next; }

    my $coreChrom = EEDB::Chrom->fetch_by_assembly_chrname($core_assembly, $chrname);
    if(!$coreChrom) { next; }

    my $primaryID = $name;
    $primaryID =~ s/\;$//g;
    if($primaryID =~ /(.+)\:(.+)/) { $primaryID = $2; }

    my ($probe) = @{EEDB::Feature->fetch_all_by_source_symbol($eeDB, $probe_source, $primaryID)};
    if(!$probe) { next; }
    
    printf("==============\n") if($debug);

    print($probe->simple_display_desc,"\n") if($debug==1);
    print($probe->display_contents) if($debug>1);
    
    my $probeloc = new EEDB::Feature;
    $probeloc->feature_source($probeloc_source);
    $probeloc->chrom($chrom);
    $probeloc->chrom_start($start);
    $probeloc->chrom_end($end);
    $probeloc->strand($strand); 
    $probeloc->primary_name($primaryID);
    $probeloc->metadataset->add_tag_symbol($probeloc_source->category, $primaryID);
    $multiLoad->store_feature($probeloc);
    print($probeloc->display_contents) if($debug);
    
    printf("fetch sequence region[%d]: %s:%d..%d%s\n", ($end-$start+1), $chrname, $start, $end, $strand) if($debug);
    my $targetseq = $coreChrom->get_subsequence($start, $end);
    if(!$targetseq) { next; }
    print($targetseq->seq,"\n") if($debug>3);
    
    #ok I have the reference genome sequence region of this transcript
    #now directly map the probes to this region of genome using smithwaterman
    #Bio::Tools::pSW;
    my $probecount=0;
    my $probe_mdata_array = $probe->metadataset->find_all_metadata_like("probeseq");
    foreach my $mdata (@$probe_mdata_array) {
      $probecount++;
      my $probeseq = Bio::Seq->new(-id=>("probeseq".$probecount), -seq=>$mdata->data);

      # probes are always anti-sense, but want to keep chromosome seq always on + strand
      # so need to revcom the probe if the target is on the - strand
      if($strand eq '-') { $probeseq = $probeseq->revcom; }

      printf("====probeseq: %s\n", $probeseq->seq) if($debug);

      my $align = $dpfactory->pairwise_alignment($probeseq, $targetseq);
      if($debug>1) { $alnout_debug->write_aln($align); }
      
      foreach my $aseq ( $align->each_seq() ) {
        next unless($aseq->id eq $targetseq->id);
        my $bstart = $start + $aseq->start;
        my $bend   = $start + $aseq->end;
        printf("  maploc:[%d..%d] %d..%d\n", $aseq->start, $aseq->end, $bstart, $bend) if($debug>1);
        
        my $subfeat = new EEDB::Feature;
        $subfeat->feature_source($block_source);
        $subfeat->primary_name($name . "_block". $probecount);
        $subfeat->chrom($chrom);
        $subfeat->chrom_start($bstart);
        $subfeat->chrom_end($bend);
        $subfeat->strand($strand);
        $multiLoad->store_feature($subfeat);
        printf("  %s\n", $subfeat->display_desc) if($debug); 

        my $edge = new EEDB::Edge;
        $edge->edge_source($block_edgesource);
        $edge->feature1($subfeat);
        $edge->feature2($probeloc);        
        $multiLoad->store_edge($edge);
        printf("          %s\n", $edge->display_desc) if($debug>2);
        
      }
    }
    
    #if($linecount>2) { last; }
  }
  close(ERRORFILE);

  #to flush the MultiLoader buffers 
  $multiLoad->store_feature();
  $multiLoad->store_edge();

  my $total_time = time() - $starttime;
  my $rate = $linecount / $total_time;
  printf("TOTAL: %10d :: %1.3f min :: %1.2f x/sec\n", $linecount, $total_time/60.0, $rate);
}


sub check_feature_exists {
  my $feature = shift;
  #probably move to Feature class eventually
  #basic idea is given name,source,position is there one == to this already in database
  
}


sub link_probe_to_location {
  printf("\n==============\n");
  my $starttime = time();
  my $linecount=0;
  
  my $multiLoad = new EEDB::Tools::MultiLoader;
  $multiLoad->database($eeDB);
  $multiLoad->do_store($store);

  my $corePeer = EEDB::Peer->fetch_by_name($eeDB, "eeDB_core");
  my $core_assembly = EEDB::Assembly->fetch_by_name($corePeer->peer_database, $assembly->ucsc_name);

  my $probe_stream = EEDB::Feature->stream_all_by_source($probe_source);
  while(my $probe = $probe_stream->next_in_stream) {
    $linecount++;
    my $probeloc_array = EEDB::Feature->fetch_all_by_source_symbol($eeDB, $probeloc_source, $probe->primary_name);
    
    printf("==============\n") if($debug);
    print($probe->simple_display_desc,"\n") if($debug==1);
    print($probe->display_contents) if($debug>1);

    foreach my $probeloc (@$probeloc_array) {
      print($probeloc->simple_display_desc,"\n") if($debug==1);
      print($probeloc->display_contents) if($debug>1);
    
      my $edge = new EEDB::Edge;
      $edge->edge_source($probe2loc_edgesource);
      $edge->feature1($probe);
      $edge->feature2($probeloc);        
      $multiLoad->store_edge($edge);
      printf("          %s\n", $edge->display_desc) if($debug>2);
    }

    if($linecount % 500 == 0) { 
      my $rate = $linecount / (time() - $starttime);
      printf("%10d (%1.2f x/sec)\n", $linecount, $rate); 
      #printf("  chrom cache size: %d\n", EEDB::Chrom::get_cache_size);
    }
  }

  #to flush the MultiLoader buffers 
  $multiLoad->store_feature();
  $multiLoad->store_edge();

  my $total_time = time() - $starttime;
  my $rate = $linecount / $total_time;
  printf("TOTAL: %10d :: %1.3f min :: %1.2f x/sec\n", $linecount, $total_time/60.0, $rate);
}


sub load_cdf_file {
  my $file = shift;

  printf("\n==============\n");
  my $probecount=0;
  my $starttime = time();

  my $multiLoad = new EEDB::Tools::MultiLoader;
  $multiLoad->database($eeDB);
  $multiLoad->do_store($store);
  
  printf("loading CDF file [%s]\n", $file);
  
  my $gz = gzopen($file, "rb") ;
  my $line;
  my $probeset_count=0;
  my $current_unit = undef;
  my $probe_feature = undef;
  while(my $bytesread = $gz->gzreadline($line)) {
    chomp($line);
    next if($line =~ /^\#/);
    $line =~ s/\r//g;
    printf("LINE: $line\n") if($debug>2);
    
    if($line =~ /^\[Unit(\d+)\]/) {
      #[Unit33041]
      $probeset_count++;
      $current_unit = $1;
      next;
    }
    unless($current_unit) { next; }

    unless($line =~ /^Cell(\d+)\=(\d+)/) { next; }
    my $probe_idx = $1;
    my $cellX = $2;

    $probecount++;

    my @columns = split(/\t/, $line);
    my $probeID     = $columns[4];
    my $cellY       = $columns[1];
    my $expos       = $columns[5];
   
    if($probe_feature and (lc($probe_feature->primary_name) ne lc($probeID))) {
      #changed so store old one
      $probe_feature->metadataset->remove_duplicates;
      $multiLoad->update_feature_metadata($probe_feature);
      print($probe_feature->display_contents) if($debug>1);
      if($debug>3) { last; }

      if($probeset_count % 100 == 0) { 
        my $rate = $probeset_count / (time() - $starttime);
        printf("%10d (%1.2f x/sec) :: %s\n", $probeset_count, $rate, $probe_feature->simple_display_desc); 
        #printf("  chrom cache size: %d\n", EEDB::Chrom::get_cache_size);
      }
      $probe_feature = undef;
    }

    if(!$probe_feature or (lc($probe_feature->primary_name) ne lc($probeID))) {
      ($probe_feature) = @{EEDB::Feature->fetch_all_by_source_symbol($eeDB, $probe_source, $probeID)};
      if($debug>1) { print("\n=====\n"); }
      printf("probeset[%s] %s \n", $current_unit, $probeID) if($debug);
    }
    if(!$probe_feature) { next; }
    if(lc($probe_feature->primary_name) ne lc($probeID)) { next; }

    if($debug>1) {
      printf("     probe[%d.%d] : %d,%d\n", $expos, $probe_idx, $cellX, $cellY);
    }
    $probe_feature->metadataset->add_tag_symbol("GeneChip_cell_coord",  ($cellX .",". $cellY));  
  }
  
  if($probe_feature) {
    $probe_feature->metadataset->remove_duplicates;
    $multiLoad->update_feature_metadata($probe_feature);
    print($probe_feature->display_contents) if($debug>1);
  }
  
  #to flush the MultiLoader buffers 
  $multiLoad->update_feature_metadata();
  
  my $total_time = time() - $starttime;
  my $rate = $probecount / $total_time;
  printf("TOTAL: %10d :: %1.3f min :: %1.2f x/sec\n", $probecount, $total_time/60.0, $rate);
  printf("   %d probesets\n", $probeset_count);
}


