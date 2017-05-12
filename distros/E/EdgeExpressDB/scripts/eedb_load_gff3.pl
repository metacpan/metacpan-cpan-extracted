#!/usr/local/bin/perl -w 

=head1 NAME - eedb_load_gff3.pl

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
use EEDB::Feature;
use EEDB::Assembly;
use EEDB::Chrom;
use EEDB::Experiment;


no warnings 'redefine';
$| = 1;

my $help;
my $passwd = '';

my $file = undef;
my $assembly_name = undef;
my $url = undef;
my $format = 'gff3';
my $gff2=undef;
my $store = undef;
my $debug = 0;

GetOptions( 
    'url:s'        =>  \$url,
    'file:s'       =>  \$file,
    'gff2'         =>  \$gff2,
    'pass:s'       =>  \$passwd,
    'asm:s'        =>  \$assembly_name,
    'store'        =>  \$store,
    'debug:s'      =>  \$debug,
    '-v'           =>  \$debug,
    'help'         =>  \$help
    );

if ($help) { usage(); }
if($gff2) { $format = 'gff2'; }

my $eeDB = undef;
if($url) {
  $eeDB = MQdb::Database->new_from_url($url);
} 
unless($eeDB) { 
  printf("ERROR: connection to database\n\n");
  usage(); 
}
my $coreDB = get_coredb();

unless(defined($assembly_name)) {
  printf("ERROR: must supply -assembly parameter\n\n");
  usage();
}
my $assembly = EEDB::Assembly->fetch_by_name($coreDB, $assembly_name);
unless(defined($assembly)) {
  printf("ERROR: assembly [%s] not in database\n\n", $assembly_name);
  usage();
}
$assembly->display_info;

if($file and (-e $file)) { 

  load_features();

} else {
  printf("ERROR: must specify gff3 file for data loading\n\n");
  usage(); 
}


exit(1);

#########################################################################################

sub usage {
  print "eedb_load_gff3.pl [options]\n";
  print "  -help                  : print this help\n";
  print "  -url <url>             : URL to database\n";
  print "  -asm <name>            : name of species/assembly (eg hg18 or mm9)\n";
  print "  -file <path>           : path to gff3 file for feature loading\n";
  print "  -gff2                  : file is in GFF2 format\n";
  print "  -v                     : simple debugging output\n";
  print "eedb_load_gff3.pl v1.0\n";
  
  exit(1);  
}

sub get_coredb {
  my $self = shift;
  
  my ($core_mdata) = @{EEDB::Metadata->fetch_all_by_type($eeDB, "eeDB_core_url", 1)};
  unless($core_mdata) {
    #printf("ERROR: eeDB not properly setup, no reference to eeDB_core\n\n");
    #sage();
    return $eeDB;
  }
  my $core_db = MQdb::Database->new_from_url($core_mdata->data);
  return $core_db;
}

#########################################################################################

sub load_features {
  printf("\n==============\n");
  my $starttime = time();
  my $linecount=0;
  my $gz = gzopen($file, "rb") ;
  my $line;
  while(my $bytesread = $gz->gzreadline($line)) {
    chomp($line);
    $linecount++;
    $line =~ s/\r//g;

    #TFh0001 chr13   31870545        31870687   +
    my ($chrname, $source, $category, $start, $end, $score, $strand, $frame, $attributes) = split(/\t/, $line);
    #printf("LINE: $line\n");
    #my $strand = '';

    if($start>$end) {
      my $t=$start;
      $start = $end;
      $end = $t;
    }
    my $chrom = EEDB::Chrom->fetch_by_assembly_chrname($assembly, $chrname);
    my $fsrc = EEDB::FeatureSource->fetch_by_category_name($eeDB, $category, $source);
    unless($fsrc) {
      $fsrc = new EEDB::FeatureSource;
      $fsrc->name($source);
      $fsrc->category($category);
      $fsrc->import_source(""); 
      $fsrc->store($eeDB) if($store);
      printf("Needed to create:: ");
      $fsrc->display_info;
    }
    
    my $feature = new EEDB::Feature;
    $feature->feature_source($fsrc);
    $feature->chrom($chrom);
    $feature->chrom_start($start);
    $feature->chrom_end($end);
    $feature->strand($strand);
    if($score ne '.') { $feature->significance($score); }
    
    parse_attributes($feature, $attributes);

    $feature->store($eeDB) if($store);
    
    if($debug) {
      $feature->display_info;
    } 
    if($linecount % 500 == 0) { 
      my $rate = $linecount / (time() - $starttime);
      printf("%10d (%1.2f x/sec): %s\n", $linecount, $rate, $feature->display_desc); 
    }
    #last;
  }
  $gz->gzclose();

  my $total_time = time() - $starttime;
  my $rate = $linecount / $total_time;
  printf("TOTAL: %10d :: %1.3f min :: %1.2f x/sec\n", $linecount, $total_time/60.0, $rate);

}


sub parse_attributes {
  my $feature = shift;
  my $attributes = shift;
  
  #OK first version is very simple, it will be a regex parser
  #it assumes that the ';' character is reserved ONLY for delimiting and
  #  is never used in "quoted" data
  
  my @toks = split (/;/, $attributes);
  foreach my $tok (@toks) {
    my $key = undef;
    my $data = undef;
    if(($format eq 'gff2') and ($tok =~ /(\w+)\s+(.*)/)) {
      $key = $1;
      $data = $2;
    }
    if(($format eq 'gff3') and ($tok =~ /(\w+)\=(.*)/)) {
      $key = $1;
      $data = $2;
    }
    next unless(defined($key) and defined($data));
    
    #printf("   atrb:  %s\n", $tok);
    if(($key eq "Name") or ($key eq "ID")) {
      $feature->primary_name($data);
      my $category = $feature->feature_source->category;
      $feature->metadataset->add_tag_symbol($category, $data);
    } else {
      $feature->metadataset->add_tag_data($key, $data);    
    }
  }
}
