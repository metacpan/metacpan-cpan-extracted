#!/usr/local/bin/perl -w 

=head1 NAME - eedb_load_swissprot.pl

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
use Time::HiRes qw(time gettimeofday tv_interval);

use MQdb::Database;
use MQdb::MappedQuery;

use EEDB::FeatureSource;
use EEDB::Feature;
use EEDB::Assembly;
use EEDB::Chrom;
use EEDB::Experiment;

use SWISS::Entry;
use SWISS::KW;

no warnings 'redefine';
$| = 1;

my $help;
my $passwd = '';
my $store = undef;
my $debug=0;

my $file = undef;
my $url = undef;

my $swiss_source = undef;
my $fsrc_name = '';

my $display_interval = 250;

GetOptions( 
    'url:s'        =>  \$url,
    'file:s'       =>  \$file,
    'pass:s'       =>  \$passwd,
    'fsrc:s'       =>  \$fsrc_name,
    'store'        =>  \$store,
    'debug:s'      =>  \$debug,
    '-v'           =>  \$debug,
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
my $coreDB = get_coredb();

###

unless($file and (-e $file)) { 
  printf("ERROR: must specify .bed file for data loading\n\n");
  usage(); 
}

###
printf("\n============\n");

if(defined($fsrc_name)) {
  if($fsrc_name =~ /(\w+)\:\:(\w+)/) {
    $swiss_source = EEDB::FeatureSource->fetch_by_category_name($eeDB, $1, $2);
  } else {
    $swiss_source = EEDB::FeatureSource->fetch_by_name($eeDB, $fsrc_name);
  }
}
unless($swiss_source) {
  $swiss_source = new EEDB::FeatureSource;
  $swiss_source->name($fsrc_name);
  $swiss_source->category('swissprot');
  $swiss_source->import_source($file); 
  $swiss_source->store($eeDB) if($store);
  printf("Needed to create:: ");
}
$swiss_source->display_info;

my $swiss_to_entrez_lsrc = EEDB::EdgeSource->fetch_by_name($eeDB, "Swissprot_to_Entrez");
my $entrez_source = EEDB::FeatureSource->fetch_by_name($eeDB, "Entrez_gene");
if($entrez_source) {
  $entrez_source->display_info;
  unless($swiss_to_entrez_lsrc) {
    $swiss_to_entrez_lsrc = new EEDB::EdgeSource;
    $swiss_to_entrez_lsrc->name("Swissprot_to_Entrez");
    $swiss_to_entrez_lsrc->store($eeDB) if($store);
  }
  $swiss_to_entrez_lsrc->display_info;
}

###

load_swissprot();

exit(1);

#########################################################################################

sub usage {
  print "eedb_load_swissprot.pl [options]\n";
  print "  -help                  : print this help\n";
  print "  -url <url>             : URL to database\n";
  print "  -fsrc <name>           : name of the primary FeatureSource for the data\n";
  print "  -file <path>           : path to swissprot file for feature loading\n";
  print "  -store                 : actually perform store into database\n";
  print "eedb_load_swissprot.pl v1.0\n";
  
  exit(1);  
}

sub get_coredb {
  my $self = shift;
  
  my ($core_mdata) = @{EEDB::Metadata->fetch_all_by_type($eeDB, "eeDB_core_url", 1)};
  unless($core_mdata) {
    #printf("ERROR: eeDB not properly setup, no reference to eeDB_core\n\n");
    #usage();
    return $eeDB;
  }
  my $core_db = MQdb::Database->new_from_url($core_mdata->data);
  return $core_db;
}

#########################################################################################


sub load_swissprot {

  printf("==============\n");
  my $starttime = time();
  my $linecount=0;

  # Read an entire record at a time
  local $/ = "\n//\n";

  my $record_count=0;
  open FILE, $file;
  while (<FILE>){
    # Read the entry
    my $entry = SWISS::Entry->fromText($_);
    $record_count++;

    my $feature = new EEDB::Feature;
    $feature->significance(0);
    $feature->feature_source($swiss_source);

    # Print the primary accession number of each entry.
    printf("\nRECORD[%7d]  %s\n", $record_count, $entry->AC) if($debug);
    
    #ACs    
    my $acs = $entry->ACs->list;
    if(scalar(@$acs)) {
      $feature->add_symbol("SwissProt", $acs->[0]);
      $feature->primary_name($acs->[0]);
      for(my $x=1; $x<scalar(@$acs); $x++) {
        $feature->add_symbol("SwissProt_secondaryAC", $acs->[$x]);
      }
    }
    
    #IDs
    my $ids = $entry->IDs->list;
    if(scalar(@$ids)) {
      $feature->add_symbol("SwissProtID", $ids->[0]);
      for(my $x=1; $x<scalar(@$ids); $x++) {
        $feature->add_symbol("SwissProtID_secondary", $ids->[$x]);
      }
    }
    
    my $gns = $entry->GNs->list;
    foreach my $gnobj (@$gns){ 
      next unless($gnobj->Name);
      printf("GN:%s\n", $gnobj->Name->text) if($debug>1);
      $feature->add_symbol("EntrezGene", $gnobj->Name->text);
      foreach my $syn ($gnobj->Synonyms) {
        printf("GN:%s\n", $syn->text) if($debug>1);
        $feature->add_symbol("Entrez_synonym", $syn->text);
      }
    }

    # If the entry has a GeneID
    if($entry->DRs->get('GeneID')) {
      my $obj = $entry->DRs->getObject('GeneID')->list->[0];
      printf("%s -> %s\n", $obj->[0], $obj->[1]) if($debug>1);
      $feature->add_symbol("EntrezID", $obj->[1]);
    }

    
    # Print all keywords
    print "KEYWORD:" if($debug>1);
    foreach my $kw ($entry->KWs->elements) {
      print $kw->text, ", " if($debug>1);
      $feature->add_symbol("keyword", $kw->text);
    }
    print "\n" if($debug>1);

    #get the Taxons of this protein
    foreach my $taxid ($entry->OXs->NCBI_TaxID()->elements()) {
      #print $taxid->text, "\n";
      $feature->add_symbol("NCBI_TaxID", $taxid->text);
    }
    
    
    #print("about to do the references now\n");
    # Print number and Comments for all references
    # (courtesy of Dan Bolser)
    $entry->Refs;
    #print("ok\n");
    foreach my $ref ($entry->Refs->elements){
      my $rn = $ref->RN;      # Reference Number
      print "RN:\t$rn\n" if($debug>1);

      my $rc = $ref->RC;      # Reference Comment(s)
      foreach my $type (keys %$rc){ # Comment type
        next unless($type eq "TISSUE");
        foreach my $value (@{$rc->{$type}}){  # Comment text
          printf("RC:%s => %s\n", $type, $value->text) if($debug>1);
          $feature->add_symbol(lc($type), $value->text);
        }
      }
      my $rx = $ref->RX;      # publications
      foreach my $type (keys %$rx){ # Comment type
        foreach my $value (@{$rx->{$type}}){
          printf("RX:%s => %s\n", $type, $value) if($debug>1);
          $feature->add_symbol($type, $value);
        }
      }

    }
    print($feature->display_contents) if($debug);
    #printf("          %s\n", $feature->simple_display_desc);
    
    ##do compare/store/update
    dbcompare_update_newfeature($feature);
    create_edge_to_entrez($feature);
  }
  print("yeah made to the end, did not crash\n");
}


sub dbcompare_update_newfeature {
  my $new_feature = shift;
  $new_feature->metadataset->remove_duplicates;
  my $changed=0;

  my $swissID = $new_feature->metadataset->find_metadata('SwissProt');

  my ($swiss_feature) = @{EEDB::Feature->fetch_all_by_source_symbol($eeDB,
                             $swiss_source, $swissID->data, 'SwissProt')};
  unless($swiss_feature) {
    $new_feature->store($eeDB) if($store);
    $changed=1;
    printf("[%s] NEW:: %s\n", $swissID->data, $new_feature->simple_display_desc);
    return $new_feature;
  }

  if($debug>2) { 
    print("=== old feature before update check ===\n"); 
    printf("%s", $swiss_feature->display_contents); 
  }
  
  #do the metadata check, merge in the new metadata into existing set
  my $mds = $swiss_feature->metadataset;
  $mds->add_metadata(@{$new_feature->metadataset->metadata_list});
  $mds->remove_duplicates;
  my $mdata_list = $swiss_feature->metadataset->metadata_list;
  foreach my $mdata (@$mdata_list) {
    if(!defined($mdata->primary_id)) { 
      # this is a newly loaded metadata so it needs storage and linking
      $mdata->store($eeDB) if($store);
      $mdata->store_link_to_feature($swiss_feature);
      $changed=1;
      printf("[%s] ADD MDATA:: %s -> %s\n", $swissID->data,
            $swiss_feature->primary_name,
            $mdata->display_contents);
    }
  }
  #maybe I should also deprecate metadata too.
  #the problem is that if any other source adds metadata to EntrezGene
  #then that data will be flushed here.
  #depends on how strict we want to be about "mirroring data" from unique providers

  if($debug) {
    if($changed) {
      printf("=== after UPDATE change ===\n");
      printf("%s", $swiss_feature->display_contents);
      printf("===========================\n");
    } else {
      printf("[%s] OK::  %s\n", $swissID->data, $swiss_feature->simple_display_desc) if($debug>1);
    }
  }
  return $swiss_feature;
}


sub create_edge_to_entrez {
  my $swiss_feature = shift;
  
  return unless($entrez_source);
  
  my $entrezID = $swiss_feature->metadataset->find_metadata('EntrezID');
  return unless($entrezID);
  
  my ($entrez_feature) = @{EEDB::Feature->fetch_all_by_source_symbol($eeDB, $entrez_source, $entrezID->symbol, 'EntrezID')};
  return unless($entrez_feature);
  
  my $newedge = new EEDB::Edge;
  $newedge->feature1($swiss_feature);
  $newedge->feature2($entrez_feature);
  $newedge->edge_source($swiss_to_entrez_lsrc);
  $newedge->weight(1);
  $newedge->store($eeDB) if($store);
  $newedge->display_info if($debug);
}

