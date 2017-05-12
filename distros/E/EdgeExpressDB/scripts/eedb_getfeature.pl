#!/usr/local/bin/perl -w 

=head1 NAME - eedb_getfeature.pl

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
my $feature_id = undef;
my $assembly = 'hg18';
my $url = undef;
my $show_express=undef;
my $format = 'content';
my $format_xml = undef;
my $format_gff = undef;
my $format_das = undef;
my $show_full_mdata = undef;
my $region_loc = undef;

GetOptions( 
            'url:s'    =>  \$url,
            'id:s'     =>  \$feature_id,
            'express'  =>  \$show_express,
            'xml'      =>  \$format_xml,
            'gff'      =>  \$format_gff,
            'das'      =>  \$format_das,
            'mdata'    =>  \$show_full_mdata,
            'loc:s'    =>  \$region_loc,
            'help'     =>  \$help
            );

if ($help) { usage(); }

my $eeDB = undef;
if($url) {
  $eeDB = MQdb::Database->new_from_url($url);
}
unless($eeDB) { printf("ERROR: must specify database URL\n\n"); usage(); }

EEDB::Feature->set_cache_behaviour(1);

if($format_xml) {$format = 'xml';}
if($format_gff) {$format = 'gff';}
if($format_das) {$format = 'das';}

my $time1 = Time::HiRes::time();

if(defined($region_loc) and $show_express) { fetch_express_region(); } 
else { fetch_features(); }

printf("process time :: %1.3f secs\n", (Time::HiRes::time() - $time1));
printf("real time :: %d secs\n", (time() - $launch_time));


exit(1);
#########################################################################################

sub usage {
  print "eedb_getfeature.pl [options]\n";
  print "  -help              : print this help\n";
  print "  -url <url>         : URL to database\n";
  print "  -id <int>          : dbID of the feature to fetch\n";
  print "  -loc <region>      : fetch all features within region\n";
  print "  -das               : display feature in DAS xml format\n";
  print "  -gff               : display feature in expanded GFF format\n";
  print "  -mdata             : in GFF also show all symbol metadata\n";
  print "  -xml               : display feature in XML format\n";
  print "  -express           : in XML format also display expression for feature(s)\n";
  print "eedb_getfeature.pl v1.0\n";
  
  exit(1);  
}

sub fetch_features {
  my $features = [];
  
  if($feature_id) {
    my $feature = EEDB::Feature->fetch_by_id($eeDB, $feature_id);
    $features = [$feature];
  } elsif($region_loc) {
    printf("region :: %s\n", $region_loc);
    my $chrom_name ='';
    my $start = 0;
    my $end = 0;
    if($region_loc =~ /(.*)\:(.*)\.\.(.*)/) {
      $chrom_name = $1;
      $start = $2;
      $end = $3;
      if($chrom_name =~ /\[(.*)\](.*)/) {
        $assembly = $1;
        $chrom_name = $2;
      }
    }
    printf("%s %s : %d .. %d\n", $assembly, $chrom_name, $start, $end);
    $features = EEDB::Feature->fetch_all_named_region($eeDB, $assembly, $chrom_name, $start, $end);
  }

  if($format eq 'xml') { printf("====== XML =====\n"); }
  elsif($format eq 'gff') { printf("\n====== GFF =====\n"); }
  elsif($format eq 'das') { printf("\n====== DAS =====\n"); }
  else { printf("\n====== contents =====\n"); }
  
  foreach my $feature (@$features) {
    $feature->metadataset->convert_bad_symbols;
    if($format eq 'xml') {
      if($show_express) {
        show_feature_expression_xml($feature);
      } else {
        print(xml_full_feature($feature));
      }
    }
    elsif($format eq 'gff') {
      print($feature->gff_description($show_full_mdata),"\n");
    }
    elsif($format eq 'das') {
      my ($chunk) = @{EEDB::ChromChunk->fetch_all_for_feature($eeDB, $feature)};
      printf("<?xml version=\"1.0\" standalone=\"no\"?>\n");
      printf("<!DOCTYPE DASGFF SYSTEM \"http://www.biodas.org/dtd/dasgff.dtd\">\n");
      printf("<DASGFF>\n");
      printf("<GFF version=\"1.0\" href=\"url\">\n");
      printf("<SEGMENT id=\"%d\" start=\"%d\" stop=\"%d\" type=\"%s\" version=\"%s\" label=\"%s\">\n",
             $chunk->id, 
             $chunk->chrom_start, 
             $chunk->chrom_end, 
             $chunk->chrom->chrom_type,
             $chunk->chrom->assembly->ucsc_name, 
             $chunk->chrom->chrom_name);

      print($feature->dasgff_xml,"\n");

      printf("</SEGMENT>\n");
      printf("</GFF>\n");
      printf("</DASGFF>\n");      
    }
    else {
      print($feature->display_contents);
      if($show_express) {
        my $express = EEDB::Expression->fetch_all_by_feature($feature);
        foreach my $fexp (sort {($a->experiment->id <=> $b->experiment->id) || ($a->type cmp $b->type)} @$express) {
          printf("   %s\n", $fexp->display_desc);
        }
      }
    }
  }
}

sub xml_full_feature {
  my $feature = shift;

  my $edges = EEDB::Edge->fetch_all_with_feature2($feature, 'category'=>"subfeature");
  print($feature->xml_start,"\n");

  # display max_expression section if data is available
  my $maxexpress = $feature->max_expression();
  if(defined($maxexpress)) {
    print("  <max_expression>\n");
    foreach my $express (@$maxexpress) {
      printf("  <express platform=\'%s\'  maxvalue=\'%1.2f\'/>", $express->[0], $express->[1]);
    }
    print("  </max_expression>\n");
  }

  my $mdata_list = $feature->metadataset->metadata_list;
  foreach my $mdata (sort {($b->class cmp $a->class) or ($a->type cmp $b->type)} @$mdata_list) {
    print("  " . $mdata->xml);
  }
  
  
  if(scalar(@$edges)) {
    print("\n  <subfeatures>\n");
    foreach my $edge (sort {(($a->feature1->chrom_start <=> $b->feature1->chrom_start) ||
                              ($a->feature1->chrom_end <=> $b->feature1->chrom_end))
                            } @{$edges}) {
      print("    ", $edge->feature1->simple_xml);
    }
    print("  </subfeatures>\n");
  }
  print($feature->xml_end);
}


sub show_feature_expression_xml {
  my $feature = shift;
  my $edge = shift;

  return undef unless($feature);
  my $express = EEDB::Expression->fetch_all_by_feature($feature);
  return undef unless(scalar(@$express)>0);

  print("<feature_express>\n");
  if($edge) { print($edge->simple_xml); }
 
  xml_full_feature($feature);

  foreach my $fexp (sort {$a->experiment->id <=> $b->experiment->id} @$express) {
    print($fexp->simple_xml);
  }
  print("</feature_express>\n");
  return 1;
}


sub fetch_express_region {
  printf("region_express :: %s\n", $region_loc);
  my $chrom_name ='';
  my $start = 0;
  my $end = 0;
  if($region_loc =~ /(.*)\:(.*)\.\.(.*)/) {
    $chrom_name = $1;
    $start = $2;
    $end = $3;
    if($chrom_name =~ /\[(.*)\](.*)/) {
      $assembly = $1;
      $chrom_name = $2;
    }
  }
  printf("%s %s : %d .. %d\n", $assembly, $chrom_name, $start, $end);

  if($format eq 'xml') { printf("====== XML =====\n"); }
  else { printf("\n====== contents =====\n"); }

  my $express_array = EEDB::Expression->fetch_all_feature_expression_by_named_region($eeDB, $assembly, $chrom_name, $start, $end, "tpm");
  printf("returned %d\n", scalar(@$express_array));
  foreach my $express (@{$express_array}) {
    next unless($express->experiment->is_active eq "y");
    if($format eq 'xml') { print($express->xml); }
    else { $express->display_info; }
  }
}


