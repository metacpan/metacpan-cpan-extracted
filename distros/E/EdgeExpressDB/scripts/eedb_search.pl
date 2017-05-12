#!/usr/local/bin/perl -w

=head1 NAME - eedb_search.pl

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

use File::Temp;

use MQdb::Database;
use EEDB::Feature;

my $name = undef;
my $format = 'xml';
my $limit = 200;
my $ensfilter = 1;
my $format_xml = undef;
my $format_gff = undef;
my $url = undef;
my $help = undef;
my $keywords = undef;

GetOptions( 
            'url:s'      =>  \$url,
            'limit:i'    =>  \$limit,
            'xml'        =>  \$format_xml,
            'gff'        =>  \$format_gff,
            'symbol:s'   =>  \$name,
            'keywords:s' =>  \$keywords,
            'help'       =>  \$help
            );

if ($help) { usage(); }

my $eeDB = MQdb::Database->new_from_url($url) if($url);
unless($eeDB) {
  printf("ERROR: connection to database\n\n");
  usage(); 
}

if(!defined($name) and !defined($keywords)) {
  printf("ERROR: must specify search symbol\n\n");
  usage(); 
}

$limit=200 unless(defined($limit));
$format='xml' unless(defined($format));
$ensfilter=1 unless(defined($ensfilter));

EEDB::Feature->set_cache_behaviour(1);

if($format_xml) {$format = 'xml';}
if($format_gff) {$format = 'gff';}

my $time1 = time();

if($keywords) { keyword_search(); } 
else { search_features(); }

exit(1);
#########################################################################################

sub usage {
  print "eedb_search.pl [options]\n";
  print "  -help              : print this help\n";
  print "  -url <url>         : URL to database\n";
  print "  -symbol <text>     : symbol to use for the database search\n";
  print "  -gff               : display feature in expanded GFF format\n";
  print "  -xml               : display feature in XML format\n";
  print "  -limit <num>       : maximum return limit\n";
  print "eedb_search.pl v1.0\n";
  
  exit(1);  
}

#############################################

sub keyword_search {
  my $starttime = time();
  my $feature_list= EEDB::Feature->fetch_all_keyword_search($eeDB, $keywords, 20);
  foreach my $feature (@$feature_list) {
    my $desc = $feature->simple_display_desc;
    if($feature->significance > 0.0) { $desc .= sprintf(" sig:%1.2f", $feature->significance); }
    print($desc, "\n");
  }
  my $total_time = time() - $starttime;
  printf("TOTAL: %d :: %1.3f sec\n", scalar(@$feature_list), $total_time);
}

sub search_features {

  printf("<\?xml version=\"1.0\" encoding=\"UTF-8\"\?>\n");

  my $feature_list =[];
  my $result_count = -1;  #undefined
  my $like_count = -1;  #undefined
  my $exact_count = -1;  #undefined
  my $search_method = "exact";

  printf("<results>\n");
  if(defined($name)) { printf("<query value=\"%s\" />\n", $name); }

  if(!defined($name) or (length($name)<2)) {
    $result_count = -1;
    $search_method = "error";
  } else {
    $like_count = EEDB::Feature->get_count_symbol_search($eeDB, $name ."%");
    $exact_count = EEDB::Feature->get_count_symbol_search($eeDB, $name);
    $search_method = "count_like";
    if($like_count<$limit) {
      $feature_list= EEDB::Feature->fetch_all_symbol_search($eeDB, undef, $name, undef, 100);
      $result_count = scalar(@$feature_list);
      $search_method = "like";
    } else {
      $search_method = "exact_count";
      $result_count = $exact_count;
      if($exact_count>0 and $exact_count<$limit) {
        $feature_list= EEDB::Feature->fetch_all_by_source_symbol($eeDB, undef, $name);
        $result_count = scalar(@$feature_list);
        $search_method = "exact";
      } else {
        $result_count = $like_count;
        $search_method = "count_like";
      }
    }
  }
  my $filter_count=0;
  foreach my $feature (sort {($a->primary_name cmp $b->primary_name)} @$feature_list) {
    next if($ensfilter and ($feature->feature_source->name =~ /Ensembl/));
    next if($feature->feature_source->is_active ne 'y');
    next if($feature->feature_source->is_visible ne 'y');
    printf("  <match feature_id=\"%s\" desc=\"%s\" type=\"%s\" fsrc=\"%s\" ",
            $feature->id, 
            $feature->primary_name, 
            $feature->feature_source->category,
            $feature->feature_source->name
            );
    printf("asm=\"%s\" chr=\"%s\"/>\n", 
            $feature->chrom->assembly->ucsc_name,
            $feature->chrom->chrom_name) if($feature->chrom);
    print("/>\n");
    $filter_count++;
  }
  if($filter_count == 0) {
    foreach my $feature (sort {($a->primary_name cmp $b->primary_name)} @$feature_list) {
    printf("  <match feature_id=\"%s\" desc=\"%s\" type=\"%s\" fsrc=\"%s\" ", 
            $feature->id, 
            $feature->primary_name, 
            $feature->feature_source->category,
            $feature->feature_source->name
            );
      printf("asm=\"%s\" chr=\"%s\"/>\n", 
              $feature->chrom->assembly->ucsc_name,
              $feature->chrom->chrom_name) if($feature->chrom);
      print("/>\n");
    }
  }
  printf("<result_count method=\"%s\" exact_count=\"%d\" like_count=\"%d\" total=\"%s\" filtered=\"%s\" />\n", $search_method, $exact_count, $like_count, $result_count, $filter_count);
  printf("</results>\n");
}


