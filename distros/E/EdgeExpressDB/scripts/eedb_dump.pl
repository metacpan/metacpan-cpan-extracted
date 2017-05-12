#!/usr/local/bin/perl -w 

=head1 NAME - eedb_dump.pl

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
use Time::HiRes qw(time gettimeofday tv_interval);

use Bio::SeqIO;
use Bio::SimpleAlign;
use Bio::AlignIO;
use File::Temp;

use MQdb::Database;
use EEDB::Feature;
use EEDB::Edge;
use EEDB::EdgeSource;

no warnings 'redefine';
$| = 1;

my $help;
my $passwd = '';
my $source_id = undef;
my $source_name = undef;
my $url = undef;
my $limit = undef;
my $nowrite = undef;
my $show_mdata = undef;
my $edgeMode = undef;
my $format = "gff";
my $use_bed=0;

my $self = {'format' => 'tsv'};

GetOptions( 
            'url:s'       =>  \$url,
            'source_id:s' =>  \$source_id,
            'source:s'    =>  \$source_name,
            'nowrite'     =>  \$nowrite,
            'metadata'    =>  \$show_mdata,
            'edge'        =>  \$edgeMode,            
            'limit:s'     =>  \$limit,
            'bed'         =>  \$use_bed,
            'format:s'    =>  \$format,
            'help'        =>  \$help
            );
if($use_bed) { $format="bed"; }

if ($help) { usage(); }

my $eeDB = undef;
if($url) {
  $eeDB = MQdb::Database->new_from_url($url);
}
unless($eeDB) { 
  printf("NO databases specified\n\n"); 
  usage(); 
}

EEDB::Feature->set_cache_behaviour(0);
EEDB::Edge->set_cache_behaviour(0);

#these are always cached in memory so just preload them
EEDB::Chrom->fetch_all($eeDB);
EEDB::FeatureSource->fetch_all($eeDB);
EEDB::EdgeSource->fetch_all($eeDB);


my $source = undef;
if($source_id) {
  if($edgeMode) {
    $source = EEDB::EdgeSource->fetch_by_id($eeDB, $source_id);
  } else {
    $source = EEDB::FeatureSource->fetch_by_id($eeDB, $source_id);
  }
} elsif($source_name) {
  if($edgeMode) {
    $source = EEDB::EdgeSource->fetch_by_name($eeDB, $source_name);
  } else {
    $source = EEDB::FeatureSource->fetch_by_name($eeDB, $source_name);
  }
}


unless($source) {
  print("ERROR:: unable to fetch source\n\n");
  usage();
}
  
$source->display_info;

if($edgeMode) {
  EEDB::Feature->set_cache_behaviour(1);
  dump_edge_source($self, $source);
} else {
  fetch_features($source);
}



exit(1);
#########################################################################################

sub usage {
  print "eedb_dump.pl [options]\n";
  print "  -help               : print this help\n";
  print "  -url <url>          : URL to database\n";
  print "  -source_id <id>     : feature_source_id\n";
  print "  -source <name>      : name of FeatureSource\n";
  print "  -bed                : output in bed format\n";
  print "  -gff                : output in gff3 format\n";
  print "  -format <type>      : available formats are 'gff'YPYP and 'bed'\n";
  print "  -metadata           : include full metadata as attributes\n";
  print "  -limit <num>        : for testing, only dump <num> objects\n";
  print "eedb_dump.pl v1.1\n";
  
  exit(1);  
}


sub fetch_features {
  my $fsource = shift;
 
  my $filename = $fsource->name . ".gff";
  if($format eq "bed") { $filename = $fsource->name . ".bed"; }
 
  open(OUTFILE, ">$filename")
    or die("Error opening ($filename) for write");
 
  if($format eq "bed") {
    printf(OUTFILE "track name=\"%s\"\n", $fsource->name);
  } else {
    printf(OUTFILE "##gff-version 3\n");
    printf(OUTFILE "#%s\n", $fsource->display_desc);
  }

  my $stream = EEDB::Feature->stream_all_by_source($fsource);
  while(my $feature = $stream->next_in_stream) {
    unless(defined($nowrite)) { 
      if($format eq "bed") {
        printf(OUTFILE "%s\n", $feature->bed_description); 
      }
      else {
        printf(OUTFILE "%s\n", $feature->gff_description($show_mdata)); 
      }
    }
    if(defined($limit)) {
      $limit--;
      if($limit <=0) { last; }
    }
  }
  
  close(OUTFILE);
}


sub dump_edge_source {
  my $self = shift;
  my $source = shift;

  return unless($source);
  return unless($source->is_active);
  return unless($source->is_visible);

  my $filename = $source->name . ".edgesource." . $self->{'format'};
  
  open(OUTFILE, ">$filename")
  or die("Error opening ($filename) for write");

  my $starttime = time()*1000;

  if($self->{'format'} eq 'xml') {
    printf(OUTFILE "<\?xml version=\"1.0\" encoding=\"UTF-8\"\?>\n");
    printf(OUTFILE "<edges>\n");
  } else {
    printf(OUTFILE "edge_id\t");
    printf(OUTFILE "edge_source\t");
    printf(OUTFILE "feature1\t");
    printf(OUTFILE "feature2\t");
    printf(OUTFILE "feature1_id\t");
    printf(OUTFILE "feature2_id\t");
    printf(OUTFILE "edge_weight\t");
    printf(OUTFILE "dir\t");
    printf(OUTFILE "edge_annotation\t");
    printf(OUTFILE "f1_annotation\t");
    printf(OUTFILE "f2_annotation\t");
    printf(OUTFILE "\n");
  }

  if($self->{'format'} eq 'xml') {
    printf(OUTFILE "%s\n", $source->xml);
  }

  my $stream = EEDB::Edge->stream_all_by_source($source);
  my $edge = $stream->next_in_stream;
  while($edge) {
    if($self->{'format'} eq 'xml') {
      printf("%s\n", $edge->simple_xml);
    } else {
      printf(OUTFILE "%s\t", $edge->id);
      printf(OUTFILE "%s\t", $edge->edge_source->uqname);
      printf(OUTFILE "%s\t", $edge->feature1->primary_name);
      printf(OUTFILE "%s\t", $edge->feature2->primary_name);
      printf(OUTFILE "%s\t", $edge->feature1_id);
      printf(OUTFILE "%s\t", $edge->feature2_id);
      printf(OUTFILE "%s\t", $edge->weight);
      printf(OUTFILE "%s\t", $edge->direction);
      printf(OUTFILE "%s\t", $edge->metadataset->gff_description);
      printf(OUTFILE "%s\t", $edge->feature1->metadataset->gff_description);
      printf(OUTFILE "%s\t", $edge->feature2->metadataset->gff_description);
      printf(OUTFILE "\n");
    }
    $edge = $stream->next_in_stream;
  }

  if($self->{'format'} eq 'xml') {
    my $total_time = (time()*1000) - $starttime;
    printf(OUTFILE "<process_summary processtime_sec=\"%1.3f\" />\n", $total_time/1000.0);
    printf(OUTFILE "</edges>\n");
  }

  close(OUTFILE);
}
