#!/usr/local/bin/perl -w 

=head1 NAME - eedb_load_edges.pl

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

use EEDB::FeatureSource;
use EEDB::EdgeSource;
use EEDB::Edge;
use EEDB::Feature;
use EEDB::Assembly;
use EEDB::Chrom;


no warnings 'redefine';
$| = 1;

my $help;
my $passwd = '';

my $file = undef;
my $assembly_name = undef;
my $url = undef;

my $lsrc = undef;
my $fsrc1 = undef;
my $fsrc2 = undef;
my $lsrc_name = '';
my $fsrc1_name = '';
my $fsrc2_name = '';

GetOptions( 
            'url:s'      =>  \$url,
            'file:s'     =>  \$file,
            'assembly:s' =>  \$assembly_name,
            'lsrc:s'     =>  \$lsrc_name,
            'fsrc1:s'    =>  \$fsrc1_name,
            'fsrc2:s'    =>  \$fsrc2_name,
            'help'       =>  \$help
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
my $coreDB = get_coredb();

printf("\n==============\n");


if(defined($fsrc1_name) and ($fsrc1_name =~ /(\w+)\:\:(\w+)/)) {
  $fsrc1 = EEDB::FeatureSource->fetch_by_category_name($eeDB, $1, $2);
}
unless($fsrc1){
  printf("ERROR -fsrc1 param ::  FeatureSource1 [%s] not in database\n\n", $fsrc1_name);
  usage();
}
$fsrc1->display_info;


if(defined($fsrc2_name) and ($fsrc2_name =~ /(\w+)\:\:(\w+)/)) {
  $fsrc2 = EEDB::FeatureSource->fetch_by_category_name($eeDB, $1, $2);
}
unless($fsrc2){
  printf("ERROR -fsrc2 param :: FeatureSource2 [%s] not in database\n\n", $fsrc2_name);
  usage();
}
$fsrc2->display_info;


$lsrc = EEDB::EdgeSource->fetch_by_name($eeDB, $lsrc_name);
unless($lsrc){
  printf("ERROR -lsrc param :: FeatureLinkSource [%s] not in database\n\n", $lsrc_name);
  usage();
}
$lsrc->display_info;


if($file and (-e $file)) { 
  load_links();
} else {
  printf("ERROR: must specify tsv edge file for data loading\n\n");
  usage(); 
}

exit(1);

#########################################################################################

sub usage {
  print "eedb_load_edges.pl [options]\n";
  print "  -help               : print this help\n";
  print "  -url <url>          : URL to database\n";
  print "  -lsrc <name>        : name of the FeatureLinkSource to load into\n";
  print "  -fsrc1 <name>       : name of the FeatureSource 1 for column 1 data\n";
  print "  -fsrc2 <name>       : name of the FeatureSource 2 for column 2 data\n";
  print "  -file <path>        : path to a tsv file with edge data\n";
  print "eedb_load_edges.pl v1.0\n";
  
  exit(1);  
}

sub get_coredb {
  my $self = shift;
  
  my ($core_mdata) = @{EEDB::Metadata->fetch_all_by_type($eeDB, "eeDB_core_url", 1)};
  unless($core_mdata) {
    printf("ERROR: eeDB not properly setup, no reference to eeDB_core\n\n");
    usage();
  }
  my $core_db = MQdb::Database->new_from_url($core_mdata->data);
  return $core_db;
}

#########################################################################################

sub load_links {
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

    #print("====LINE :: ", $line, "\n"); 
    ## ENTREZID        Level3  Zscore  Direction       Type    Evidence
    ## 468     L3_chr1_+_9330329       -13.987204      1       PD      Predicted

    my ($f1name, $f2name, $weight, $dir, $type)  = split(/\t/, $line);
    my ($feature1, $feature2, $other);
    
    ($feature1, $other) = @{EEDB::Feature->fetch_all_by_primary_name($eeDB, $f1name, $fsrc1)};
    if(defined($other)) { 
      printf("ERROR LINE: %s\n  feature [%s] in database more than once for FeatureSource [%s]", $line, $f1name, $fsrc1->name); 
      die; 
    }
    unless($feature1) { printf("ERROR LINE: $line ::: failed to load feature [%s]", $f1name); die; }
    #printf("%s\n", $probe_feature->simple_display_desc);


    ($feature2, $other) = @{EEDB::Feature->fetch_all_by_primary_name($eeDB, $f2name, $fsrc2)};
    if(defined($other)) { 
      printf("ERROR LINE: %s\n  feature [%s] in database more than once for FeatureSource [%s]", $line, $f2name, $fsrc2->name); 
      die; 
    }
    unless($feature2) { printf("ERROR LINE: $line ::: failed to load feature [%s]", $f2name); die; }
    #printf("%s\n", $probe_feature->simple_display_desc);


    my $link = new EEDB::Edge;
    $link->feature1($feature1);
    $link->feature2($feature2);
    $link->edge_source($lsrc);

    $link->direction($dir) if(defined($dir)); 
    $link->sub_type($type) if(defined($type));
    $link->weight($weight) if(defined($weight));

    $link->store($eeDB);
    
    if($linecount % 500 == 0) { 
      my $rate = $linecount / (time() - $starttime);
      printf("%10d (%1.2f x/sec): %s\n", $linecount, $rate, $link->display_desc); 
    }
  }
  $gz->gzclose();

  my $total_time = time() - $starttime;
  my $rate = $linecount / $total_time;
  printf("TOTAL: %10d :: %1.3f min :: %1.2f x/sec\n", $linecount, $total_time/60.0, $rate);
  
}

