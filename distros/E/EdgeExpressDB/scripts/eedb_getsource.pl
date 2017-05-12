#!/usr/local/bin/perl -w 

=head1 NAME - eedb_getsource.pl

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

use Time::HiRes;
my $launch_time = time();

use Getopt::Long;
use Data::Dumper;
use Switch;
use File::Temp;

use MQdb::Database;
use MQdb::MappedQuery;
use EEDB::Feature;
use EEDB::Expression;
use EEDB::Edge;
use EEDB::EdgeSource;

no warnings 'redefine';
$| = 1;

my $help;
my $passwd = '';
my $url = undef;
my $id = undef;
my $format = 'content';
my $format_xml = undef;
my $filter = undef;

my $mode = '';
my $mode_feature = undef;
my $mode_edge = undef;
my $mode_experiment = undef;

GetOptions( 
            'url:s'      =>  \$url,
            'id:s'       =>  \$id,
            'feature'    =>  \$mode_feature,
            'edge'       =>  \$mode_edge,
            'experiment' =>  \$mode_experiment,
            'xml'        =>  \$format_xml,
            'filter:s'   =>  \$filter,
            'help'       =>  \$help
            );

if ($help) { usage(); }

my $eeDB = undef;
if($url) {
  $eeDB = MQdb::Database->new_from_url($url);
}

if($format_xml) {$format = 'xml';}

if($mode_feature) {$mode = 'feature';}
if($mode_edge) {$mode = 'edge';}
if($mode_experiment) {$mode = 'experiment';}

my $time1 = Time::HiRes::time();

if(defined($filter)) {
  filter_search_source();
} else {
  fetch_source();
}
printf("process time :: %1.3f secs\n", (Time::HiRes::time() - $time1));
printf("real time :: %d secs\n", (time() - $launch_time));


exit(1);
#########################################################################################

sub usage {
  print "eedb_getsource.pl [options]\n";
  print "  -help              : print this help\n";
  print "  -url <url>         : URL to database\n";
  print "  -id <int>          : dbID of the source to fetch\n";
  print "  -feature           : fetch a FeatureSource\n";
  print "  -edge              : fetch an EdgeSource\n";
  print "  -experiment        : fetch an Experiment\n";
  print "  -xml               : display feature in XML format\n";
  print "eedb_getsource.pl v1.0\n";
  
  exit(1);  
}

sub fetch_source {
  
  my $source = undef;
  if($mode eq 'feature')    { $source = EEDB::FeatureSource->fetch_by_id($eeDB, $id); }
  if($mode eq 'edge')       { $source = EEDB::EdgeSource->fetch_by_id($eeDB, $id); }
  if($mode eq 'experiment') { $source = EEDB::Experiment->fetch_by_id($eeDB, $id); }
  return unless($source);
  
  if($format eq 'xml') { printf("====== XML =====\n"); }
  else { printf("\n====== contents =====\n"); }
  
  if($format eq 'xml') { print($source->xml); }
  else { print($source->display_contents,"\n"); }
}


sub filter_search_source {
  printf("filter :: %s\n", $filter);
  #my $symbols = EEDB::Symbol->fetch_all_by_filter_search($eeDB, $filter);
  #foreach my $mdata (@$symbols) { $mdata->display_info; }

  my $sources = EEDB::Experiment->fetch_all_by_filter_search($eeDB, $filter);
  foreach my $source (@$sources) { 
    $source->display_info; 
  }
  return 1;
  
  my $source = undef;
  return unless($source);
  
  if($format eq 'xml') { printf("====== XML =====\n"); }
  else { printf("\n====== contents =====\n"); }
  
  if($format eq 'xml') { print($source->xml); }
  else { print($source->display_contents,"\n"); }
}

