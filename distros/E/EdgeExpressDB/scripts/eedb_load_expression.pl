#!/usr/local/bin/perl -w 

=head1 NAME - eedb_load_expression.pl

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
use EEDB::Experiment;
use EEDB::Expression;


no warnings 'redefine';
$| = 1;

my $help;
my $passwd = '';

my $file = undef;
my $assembly_name = undef;
my $url = undef;

my $fsrc = undef;
my $fsrc_name = '';
my $display_interval = 1000;

GetOptions( 
            'url:s'      =>  \$url,
            'file:s'     =>  \$file,
            'assembly:s' =>  \$assembly_name,
            'fsrc:s'     =>  \$fsrc_name,
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


if(defined($fsrc_name) and ($fsrc_name =~ /(\w+)\:\:(\w+)/)) {
  $fsrc = EEDB::FeatureSource->fetch_by_category_name($eeDB, $1, $2);
}
unless($fsrc){
  printf("ERROR -fsrc param ::  FeatureSource [%s] not in database\n\n", $fsrc_name);
  usage();
}
$fsrc->display_info;


if($file and (-e $file)) { 
  load_expression();
} else {
  printf("ERROR: must specify tsv edge file for data loading\n\n");
  usage(); 
}

exit(1);

#########################################################################################

sub usage {
  print "eedb_load_expression.pl [options]\n";
  print "  -help               : print this help\n";
  print "  -url <url>          : URL to database\n";
  print "  -fsrc <name>        : name of the FeatureSource for column 1 data\n";
  print "  -file <path>        : path to a tsv file with expression data\n";
  print "eedb_load_expression.pl v1.0\n";
  
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

sub load_expression {
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

    #featureName    raw     norm    detection       experimentName
    #L2_chr1_+_3017066       1.000000        0.000000        1.000000        mixNT

    my ($fname, $raw, $norm, $detection, $expname)  = split(/\t/, $line);
    
    my ($feature, $other) = @{EEDB::Feature->fetch_all_by_primary_name($eeDB, $fname, $fsrc)};
    if(defined($other)) { 
      printf("ERROR LINE: %s\n  feature [%s] in database more than once for FeatureSource [%s]", $line, $fname, $fsrc->name); 
      die; 
    }
    unless($feature) { printf("ERROR LINE: $line ::: failed to find feature [%s]", $fname); die; }


    my $experiment = EEDB::Experiment->fetch_by_exp_accession($eeDB, $expname);
    unless($experiment) { printf("ERROR LINE: $line ::: failed to load experiment [%s]", $expname); die; }


    my $fexpress = new EEDB::Expression;
    $fexpress->feature($feature);
    $fexpress->experiment($experiment);
    $fexpress->raw_express($raw);
    $fexpress->value($norm);
    $fexpress->sig_error($detection);

    $fexpress->store($eeDB);

    if($linecount % $display_interval == 0) { 
      my $rate = $linecount / (time() - $starttime);
      printf("%10d (%1.2f x/sec): %s\n", $linecount, $rate, $fexpress->display_desc); 
    }
  }
  $gz->gzclose();

  my $total_time = time() - $starttime;
  my $rate = $linecount / $total_time;
  printf("TOTAL: %10d :: %1.3f min :: %1.2f x/sec\n", $linecount, $total_time/60.0, $rate);
  
}

