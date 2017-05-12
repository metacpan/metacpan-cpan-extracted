#!/usr/local/bin/perl -w 

=head1 NAME - eedb_load_metadata.pl

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
my $url = undef;
my $store = 0;
my $debug=0;
my $csv=0;

my $mode = "feature";

my $fsrc = undef;
my $fsrc_name = undef;
my $display_interval = 100;

my @data_column_types = ();
my $primary_datatype = undef;
my $data_col_count = 0;

GetOptions( 
            'url:s'        =>  \$url,
            'file:s'       =>  \$file,
            'fsrc:s'       =>  \$fsrc_name,
            'csv'          =>  \$csv,
            'mode'         =>  \$mode,
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

if(($mode ne "feature") and ($mode ne "experiment")) {
  printf("ERROR: unknown mode[%s]\n\n", $mode);
  usage(); 
}

printf("\n==============\n");

if(defined($fsrc_name)) {
  my $category = undef;
  if($fsrc_name =~ /(\w+)\:\:(.+)/) {
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
    $fsrc->import_source(""); 
    $fsrc->store($eeDB) if($store);
    printf("Needed to create:: ");
  }
  $fsrc->display_info;
} else {
  printf("ERROR must specify -fsrc param\n\n");
  usage();
}


if($file and (-e $file)) { 
  my $error_path = $file . ".errors";
  open(ERRORFILE, ">>", $error_path);
  load_metadata();
  close(ERRORFILE);
} else {
  printf("ERROR: must specify tsv edge file for data loading\n\n");
  usage(); 
}

exit(1);

#########################################################################################

sub usage {
  print "eedb_load_metadata.pl [options]\n";
  print "  -help               : print this help\n";
  print "  -url <url>          : URL to database\n";
  print "  -fsrc <name>        : name of the FeatureSource for column 1 data\n";
  print "  -file <path>        : path to a tsv file with expression data\n";
  print "eedb_load_metadata.pl v1.0\n";
  
  exit(1);  
}

#########################################################################################


sub load_metadata {

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
    
    #first column is the primaryID used for looking up unique entries

    my ($primaryID, @datacolumns);
    if($csv) { ($primaryID, @datacolumns) = split(/,/, $line); } 
    else { ($primaryID, @datacolumns) = split(/\t/, $line); }
    
    $primaryID =~ s/^\"//; #"
    $primaryID =~ s/\"$//; #"

    if($linecount == 1) {
      $primary_datatype = $primaryID;
      $primary_datatype =~ s/\s/_/g;
      @data_column_types = @datacolumns;
      $data_col_count = scalar(@data_column_types);
      next;
    }
    
    my ($feature, $other) = @{EEDB::Feature->fetch_all_by_source_symbol($eeDB, $fsrc, $primaryID, $primary_datatype)};
    if(defined($other)) { 
      printf(ERRORFILE "ERROR LINE: %s\n  feature [%s] in database more than once for FeatureSource [%s]", $line, $primaryID, $fsrc->name); 
    }
    unless($feature) { 
      $feature = new EEDB::Feature;
      $feature->feature_source($fsrc);      
      $feature->primary_name($primaryID);
      $feature->metadataset->add_tag_symbol($primary_datatype, $primaryID);
      $feature->store($eeDB) if($store);
    }
    
    for(my $x=0; $x<$data_col_count; $x++) {
      my $datatype = $data_column_types[$x];
      my $value    = $datacolumns[$x];
      
      $datatype =~ s/^\"//; #"
      $datatype =~ s/\"$//; #"
      $datatype =~ s/\s/_/g;
      $value =~ s/^\"//; #"
      $value =~ s/\"$//; #"
      
      next if(!$value);
      next if($value eq "");
      next if($value eq "---");
      
      printf("tag[%s]  value[%s]\n", $datatype, $value) if($debug>1);
      
      if(($value =~ /\s/) or (length($value)>64)) {
        #if has whitespace or it is long then this is Metadata
        $feature->metadataset->add_tag_data($datatype, $value);
      } else {
        $feature->metadataset->add_tag_symbol($datatype, $value);
      }
    }
    $feature->metadataset->remove_duplicates;
    $feature->store_metadata() if($store);
    
    if($debug) { print($feature->display_contents()); }

    if($linecount % $display_interval == 0) { 
      my $rate = $linecount / (time() - $starttime);
      printf("%10d (%1.2f x/sec): %s\n", $linecount, $rate, $feature->simple_display_desc); 
    }
  }
  $gz->gzclose();

  my $total_time = time() - $starttime;
  my $rate = $linecount / $total_time;
  printf("TOTAL: %10d :: %1.3f min :: %1.2f x/sec\n", $linecount, $total_time/60.0, $rate);
}

