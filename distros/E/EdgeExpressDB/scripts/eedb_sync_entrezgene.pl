#!/usr/local/bin/perl -w

=head1 NAME - eedb_sync_entrezgene.pl 

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
use File::Temp;

use XML::TreePP;

use MQdb::Database;
use MQdb::MappedQuery;

use EEDB::Feature;
use EEDB::FeatureSource;
use EEDB::Edge;
use EEDB::EdgeSource;
use EEDB::Assembly;
use EEDB::Chrom;
use EEDB::Expression;
use EEDB::MetadataSet;
use EEDB::Tools::MultiLoader;

no warnings 'redefine';
$| = 1;

my $help;
my $passwd = '';

my $assembly_name = undef;
my $url = undef;
my $deprecateOK = undef;
my $skip_update = undef;
my $fsrc_name = undef;
my $debug = 0;
my $store = 1;

my $genecount=0;
my $locmove_count=0;
my $entrez_id=undef;

GetOptions( 
    'url:s'        =>  \$url,
    'entrezID:s'   =>  \$entrez_id,
    'debug:s'      =>  \$debug,
    'v'            =>  \$debug,
    'assembly:s'   =>  \$assembly_name,
    'asm:s'        =>  \$assembly_name,
    'deprecate'    =>  \$deprecateOK,
    'skip_update'  =>  \$skip_update,
    'pass:s'       =>  \$passwd,
    'nostore'      =>  \$store,
    'help'         =>  \$help
    );


if ($help) { usage(); }
#unless($gff_file and (-e $gff_file)) { usage(); }

my $eeDB = undef;
if($url) { $eeDB = MQdb::Database->new_from_url($url); } 
unless($eeDB) {
  printf("ERROR: connection to database\n\n");
  usage(); 
}

my $assembly = EEDB::Assembly->fetch_by_name($eeDB, $assembly_name);
unless($assembly) { printf("error fetching assembly [%s]\n\n", $assembly_name); usage(); }

$fsrc_name = "Entrez_gene_" . $assembly->ucsc_name;
my $entrez_source = EEDB::FeatureSource->fetch_by_category_name($eeDB, "gene", $fsrc_name);
unless($entrez_source) {
  $entrez_source = new EEDB::FeatureSource;
  $entrez_source->category("gene");
  $entrez_source->name($fsrc_name);
  $entrez_source->import_source("NCBI Entrez Gene");
  $entrez_source->url("http://www.ncbi.nlm.nih.gov/sites/entrez?db=gene");
  $entrez_source->store($eeDB);
  printf("Needed to create:: %s\n", $entrez_source->display_desc);
}
unless($entrez_source) { printf("error Entrez feature_source [%s]\n\n", $fsrc_name); usage(); }

my $deprecate_source = EEDB::FeatureSource->fetch_by_category_name($eeDB, "gene", "deprecated_entrez_gene");
unless($deprecate_source) {
  $deprecate_source = new EEDB::FeatureSource;
  $deprecate_source->category("gene");
  $deprecate_source->name("deprecated_entrez_gene");
  $deprecate_source->import_source("NCBI Entrez Gene");
  $deprecate_source->url("http://www.ncbi.nlm.nih.gov/sites/entrez?db=gene");
  $deprecate_source->store($eeDB);
  printf("Needed to create:: %s\n", $deprecate_source->display_desc);
}
unless($deprecate_source) { printf("error making [deprecated_entrez_gene] feature_source\n\n"); usage(); }


printf("============\n");
printf("eeDB:: %s\n", $eeDB->url);
$assembly->display_info;
$entrez_source->display_info;
$deprecate_source->display_info;
printf("============\n");

if(defined($entrez_id)) {
  fetch_gene_from_webservice($entrez_id);
} else {
  update_from_webservice();
}
#fetch_gene_from_webservice(100128520); #19
#100128520

fetch_gene_from_webservice();#flush

printf("MOVED stats : %d / %d = %1.2f%%\n", $locmove_count, $genecount, 100.0*$locmove_count/$genecount);

exit(1);

#########################################################################################

sub usage {
  print "eedb_sync_entrezgene.pl [options]\n";
  print "  -help              : print this help\n";
  print "  -url <url>         : URL to database\n";
  print "  -assembly <name>   : name of species/assembly (eg hg18 or mm9)\n";
  print "  -entrezID <id>     : synchronize specific entrez gene\n";
  print "eedb_sync_entrezgene.pl v1.0\n";

  exit(1);
}


##################################################################
#
# new XML webservice based mathods
#
##################################################################

sub update_from_webservice {
  my $url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?".
            "db=gene&retmax=100000";
  $url .= sprintf("&term=%d[taxid]%%20AND%%20gene_all[filter]", $assembly->taxon_id);
  printf("URL: %s\n", $url);
  my $tpp = XML::TreePP->new();
  my $tree = $tpp->parsehttp( GET => $url );
  #print $tree, "\n";

  my $search_count = $tree->{'eSearchResult'}->{'Count'};
  printf("search returned %d genes\n", $search_count);
  my $id_list = $tree->{'eSearchResult'}->{'IdList'}->{'Id'};
  #printf("idList %s\n", $id_list);

  my $geneIDs =[];
  if($id_list =~ /ARRAY/) { $geneIDs = $id_list; } 
  else { $geneIDs = [$id_list]; }

  #should maybe do something here to filter the list 
  #into:: new, deprecated, and update
  my $sql = "select sym_value from symbol join feature_2_symbol using (symbol_id) ".
     "JOIN feature using(feature_id) ".
     "WHERE sym_type='EntrezID' AND feature_source_id=?";
  my $loadedEntrezIDs = MQdb::MappedQuery->fetch_col_array($eeDB, $sql, $entrez_source->id);
  my $eIDhash = {};
  my $newCount=0;
  my $updateCount=0; 
  my $deprecateCount=0;

  foreach my $geneID (@$loadedEntrezIDs) { $eIDhash->{$geneID}='dbonly'; }
  foreach my $geneID (@$id_list) {
    if($eIDhash->{$geneID} and ($eIDhash->{$geneID} eq 'dbonly')) { 
      $updateCount++; 
      $eIDhash->{$geneID}='update'; 
    }
    else { $newCount++; $eIDhash->{$geneID}='new'; }
  }
  for my $geneID (keys(%$eIDhash)) {
    $deprecateCount++ if($eIDhash->{$geneID} eq 'dbonly');
  }
  printf("%d new genes to add\n", $newCount);
  printf("%d genes to update check\n", $updateCount);
  printf("%d genes to deprecate\n", $deprecateCount);
  sleep(5);

  #first add new genes
  for my $geneID (keys(%$eIDhash)) {
    next unless($eIDhash->{$geneID} eq 'new');
    fetch_gene_from_webservice($geneID);
  }
  fetch_gene_from_webservice();  #flushes the buffer

  #then the deprecates
  for my $geneID (keys(%$eIDhash)) {
    next unless($eIDhash->{$geneID} eq 'dbonly');
    deprecate_geneID($geneID);
  }

  #then the updates
  unless($skip_update) {
    for my $geneID (keys(%$eIDhash)) {
      next unless($eIDhash->{$geneID} eq 'update');
      fetch_gene_from_webservice($geneID);
    }
  }
  
  
  #flushes the buffer just in case
  fetch_gene_from_webservice();
}


my @gene_id_buffer;
sub fetch_gene_from_webservice {
  my $geneID = shift;
  if(defined($geneID)) { 
    $genecount++;
    #printf("geneID: %d\n", $geneID);
    push @gene_id_buffer, $geneID; 
    return if(scalar(@gene_id_buffer) < 300);
  }
  return unless(scalar(@gene_id_buffer) >0);
  printf("go to NCBI and get %d genes\n", scalar(@gene_id_buffer));

  my $url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?".
             "db=gene&retmode=text";
  $url .= sprintf("&id=%s", join(",", @gene_id_buffer));
  printf("URL: %s\n", $url);
  my $tpp = XML::TreePP->new();
  my $tree = $tpp->parsehttp( GET => $url );

  my $summaries = $tree->{'eSummaryResult'}->{'DocSum'};
  #printf("summaries %s\n", $summaries);

  if($eeDB->driver eq "sqlite") { $eeDB->do_sql("BEGIN"); }
  if($summaries =~ /ARRAY/) { 
    foreach my $summaryXML (@$summaries) {
      extract_gene_summaryXML($summaryXML);
    }
  } else {
    extract_gene_summaryXML($summaries);
  }
  if($eeDB->driver eq "sqlite") { $eeDB->do_sql("COMMIT"); }

  #done now so clear out the buffer
  @gene_id_buffer = ();
}

sub extract_gene_summaryXML {
  my $summaryXML = shift;

  #first create a new feature for this data
  #then compare it to the database and do diffs/updates
  #and record the changes

  my $geneID = $summaryXML->{"Id"};
  my $items = $summaryXML->{"Item"};

  my $new_feature = new EEDB::Feature;
  $new_feature->feature_source($entrez_source);
  $new_feature->significance(0.0);
  my $mdataset = $new_feature->metadataset;
  $mdataset->add_tag_symbol("EntrezID", $geneID);
  
  #need to combine the description and organism name into a nice description
  my $desc = undef;
  my $organism =undef;
  
  foreach my $item (@$items) {
    next unless($item->{"#text"} or $item->{"Item"});

    my $type  = $item->{"-Name"}; #atrribute so need - prefix
    my $value = $item->{"#text"};
    #printf("type[%s] %s\n", $type, $value);
    #print("==\n");
    #foreach my $key(keys(%$item)) { printf("key[%s] %s\n", $key, $item->{$key}); }
    if($type eq "Name") {
      $new_feature->primary_name($value);
      $mdataset->add_tag_symbol('EntrezGene', $value); 
    } 
    elsif($type eq "Description") {
      #$mdataset->add_tag_data("description", $value);
      $desc = $value;
    }
    elsif($type eq "Orgname") {
      #$mdataset->add_tag_data("description", $value);
      $organism = $value;
    }
    elsif($type eq "Chromosome") {
      my $chrom = EEDB::Chrom->fetch_by_name_assembly_id($eeDB,"chr".$value,$assembly->id);
      unless($chrom) { #create the chromosome;
        $chrom = new EEDB::Chrom;
        $chrom->chrom_name("chr".$value);
        $chrom->assembly($assembly);
        $chrom->chrom_type('chromosome');
        $chrom->store($eeDB);
        $chrom = EEDB::Chrom->fetch_by_name_assembly_id($eeDB,"chr".$value,$assembly->id);
        printf("need to create chromosome :: %s\n", $chrom->display_desc);
      }
      $new_feature->chrom($chrom);
    }
    elsif($type eq "MapLocation") {
      $mdataset->add_tag_symbol('GeneticLoc', $value); 
    }
    elsif($type eq "Summary") {
      my $mdata = $mdataset->add_tag_data('Summary', $value);
      $mdataset->merge_metadataset($mdata->extract_keywords);
    }
    elsif($type eq "Mim" and defined($item->{'Item'})) {
      my $mims = $item->{"Item"};
      if($mims =~ /ARRAY/) {
        foreach my $mim(@$mims) {
          $mdataset->add_tag_symbol('OMIM', $mim->{"#text"});
        }
      } else {
        #foreach my $key(keys(%$mims)) { printf("key[%s] %s\n", $key, $mims->{$key}); }
        $mdataset->add_tag_symbol('OMIM', $mims->{"#text"});
      }
    }
    elsif($type eq "OtherAliases") {
      my @aliases = split /,/, $value;
      foreach my $alias (@aliases) {
        $alias =~ s/^\s*//g; #remove any leading space
        $mdataset->add_tag_symbol('Entrez_synonym', $alias); 
      }
    }
    elsif($type eq "OtherDesignations") {
      my @aliases = split /\|/, $value;
      foreach my $alias (@aliases) {
        $alias =~ s/^\s*//g; #remove any leading space
        my $mdata = $mdataset->add_tag_data('alt_description', $alias); 
        $mdataset->merge_metadataset($mdata->extract_keywords);
      }
    }
    elsif($type eq "GenomicInfo") {
      my $locs = $item->{"Item"};
      if($locs =~ /ARRAY/) {
        foreach my $locXML (@$locs) {
          add_locationXML_to_feature($new_feature, $locXML);
        }
      } else {
        add_locationXML_to_feature($new_feature, $locs);
      }
    }
    elsif($type =~ /^Nomenclature/) {
      $mdataset->add_tag_symbol($type, $value);
    }
  }
  if($desc) { #there should only be one description for a gene
    if($organism) { $desc .= " [" . $organism . "]"; } 
    my $mdata = $mdataset->add_tag_data("description", $desc);
    $mdataset->merge_metadataset($mdata->extract_keywords);
  }
  $new_feature = dbcompare_update_newfeature($new_feature);
}


sub add_locationXML_to_feature {
  my $feature = shift;
  my $locXML = shift;
  return undef unless($locXML and ($locXML->{"-Name"} eq "GenomicInfoType"));
  #print("add_loc==\n");
  my $items = $locXML->{"Item"};
  my $accVer = "";
  my $chrName = "";
  foreach my $item (@$items) {
    #foreach my $key(keys(%$item)) { printf("key[%s] %s\n", $key, $item->{$key}); }
    my $name  = $item->{"-Name"};
    my $value = $item->{"#text"};
    if($name eq "ChrLoc") { $chrName = $value; }
    if($name eq "ChrStart") { $feature->chrom_start($value); }
    if($name eq "ChrStop") { $feature->chrom_end($value); }
    if($name eq "ChrAccVer") { $accVer = $value; }
  }
  $feature->strand("+");

  my $chrom = EEDB::Chrom->fetch_by_name_assembly_id($eeDB,"chr".$chrName,$assembly->id);
  unless($chrom) { #create the chromosome;
    $chrom = new EEDB::Chrom;
    $chrom->chrom_name("chr".$chrName);
    $chrom->assembly($assembly);
    $chrom->chrom_type('chromosome');
    $chrom->store($eeDB);
    printf("need to create chromosome :: %s\n", $chrom->display_desc);
  }
  $feature->chrom($chrom);

  my $complement="";
  if($feature->chrom_start > $feature->chrom_end) {
    my $t = $feature->chrom_start;
    $feature->chrom_start($feature->chrom_end);
    $feature->chrom_end($t);
    $feature->strand("-");
    $complement = ", complement";
  }

  my $full_loc = sprintf("Chromosome %s, %s (%d..%d%s)", 
                        $chrName,
                        $accVer,
                        $feature->chrom_start,
                        $feature->chrom_end,
                        $complement);
  $feature->metadataset->add_tag_data('entrez_location', $full_loc);
}


sub dbcompare_update_newfeature {
  my $new_feature = shift;
  $new_feature->metadataset->remove_duplicates;
  my $changed=0;

  my $entrezID = $new_feature->metadataset->find_metadata('EntrezID');

  my ($entrez_feature) = @{EEDB::Feature->fetch_all_by_source_symbol($eeDB,
                             $entrez_source, $entrezID->data, 'EntrezID')};
  unless($entrez_feature) {
    $new_feature->store($eeDB);
    $changed=1;
    printf("[%s] NEW:: %s\n", $entrezID->data, $new_feature->simple_display_desc);
    return $new_feature;
  }

  if($debug>2) { 
    print("=== old feature before update check ===\n"); 
    printf("%s", $entrez_feature->display_contents); 
  }
  
  #
  # do the name checks 
  #
  if($entrez_feature->primary_name ne $new_feature->primary_name) {
    printf("[%s] NAME CHANGE:: %s => %s\n", $entrezID->data,
            $entrez_feature->primary_name,
            $new_feature->primary_name);
    $changed=1;
    #change the old name in the symbol set (remove EntrezGene, add Entrez_synonym)
    my $syms = $entrez_feature->metadataset->find_all_metadata_like('EntrezGene');
    foreach my $nameSym (@$syms) { 
      if($new_feature->primary_name ne $nameSym->data) {
        printf("[%s] UNLINK MDATA:: %s\n", $entrezID->data, $nameSym->display_contents);
        $nameSym->unlink_from_feature($entrez_feature); 
      }
    }
    $entrez_feature->metadataset->add_tag_symbol('Entrez_synonym', $entrez_feature->primary_name);
    #then change primary_name.  additional metadata will happen below
    $entrez_feature->primary_name($new_feature->primary_name);
  }

  #
  # do the location checks now
  #
  if($entrez_feature->chrom_location ne $new_feature->chrom_location) {
    if(($entrez_feature->strand eq $new_feature->strand) and 
       $entrez_feature->check_overlap($new_feature)) {
      printf("[%s] MAP WIGGLE::  %s => %s\n", $entrezID->data, 
             $entrez_feature->simple_display_desc, $new_feature->chrom_location);
      $entrez_feature->chrom_start($new_feature->chrom_start);
      $entrez_feature->chrom_end($new_feature->chrom_end);
      $locmove_count++;
      $changed=1;
    } elsif(!defined($entrez_feature->chrom) or ($entrez_feature->chrom_start eq -1)) {
      printf("[%s] NEW MAP::  %s => %s\n", $entrezID->data, 
             $entrez_feature->simple_display_desc, $new_feature->chrom_location);
      $entrez_feature->chrom($new_feature->chrom);
      $entrez_feature->chrom_start($new_feature->chrom_start);
      $entrez_feature->chrom_end($new_feature->chrom_end);
      $entrez_feature->strand($new_feature->strand);
      $locmove_count++;
      $changed=1;
    } else {
      my $move_desc = sprintf("%s [%s] MAP BIG MOVE::  %s => %s", localtime(time()),
             $entrezID->data, 
             $entrez_feature->chrom_location, $new_feature->chrom_location);
      printf("%s :: %s\n", $move_desc, $entrez_feature->display_desc);
      $entrez_feature->metadataset->add_tag_data('big_move', $move_desc);

      $entrez_feature->chrom($new_feature->chrom);
      $entrez_feature->chrom_start($new_feature->chrom_start);
      $entrez_feature->chrom_end($new_feature->chrom_end);
      $entrez_feature->strand($new_feature->strand);
      $locmove_count++;
      $changed=1;
    }
  }

  if($changed) { #primary_name or location has changed
    $entrez_feature->update_location();
  }

  #
  # do the metadata check, merge in the new metadata into existing set
  #
  my $mds = $entrez_feature->metadataset;

  #special processing of description and entrez_location metadata since there should only be one of each
  my $mdata = $new_feature->metadataset->find_metadata('description');
  unique_metadata_by_type($entrez_feature, $mdata);

  $mdata = $new_feature->metadataset->find_metadata('entrez_location');
  unique_metadata_by_type($entrez_feature, $mdata);

  #my $newmd = $new_feature->metadataset->find_metadata('description');
  #my $old_desc_array = $mds->find_all_metadata_like('description');
  #foreach my $mdata (@$old_desc_array) {
  #  if(($mdata->type eq $newmd->type) and ($mdata->data ne $newmd->data)) {
  #    printf("[%s] UNLINK OLD MDATA:: %s -> %s\n", $entrezID->data,
  #          $entrez_feature->primary_name,
  #          $mdata->display_contents);
  #    $mds->add_tag_data("alt_description", $mdata->data);
  #    $mds->remove_metadata($mdata);
  #    $mdata->unlink_from_feature($entrez_feature);
  #  }
  #}
  
  #the rest can be standard procedure
  $mds->add_metadata(@{$new_feature->metadataset->metadata_list});
  $mds->remove_duplicates;
  my $mdata_list = $entrez_feature->metadataset->metadata_list;
  foreach my $mdata (@$mdata_list) {
    if(!defined($mdata->primary_id)) { 
      # this is a newly loaded metadata so it needs storage and linking
      if(!$mdata->check_exists_db($eeDB)) { #not turned on by default but what this behaviour here
        $mdata->store($eeDB);
      }
      $mdata->store_link_to_feature($entrez_feature);
      $changed=1;
      printf("[%s] ADD MDATA:: %s -> %s\n", $entrezID->data,
            $entrez_feature->primary_name,
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
      printf("%s", $entrez_feature->display_contents);
      printf("===========================\n");
    } else {
      printf("[%s] OK::  %s\n", $entrezID->data, $entrez_feature->simple_display_desc) if($debug>1);
    }
  }
  return $entrez_feature;
}


sub unique_metadata_by_type {
  my $feature   = shift; #Feature object
  my $new_mdata = shift; #Metadata object

  return unless($new_mdata);
  
  my $mds      = $feature->metadataset;
  my $entrezID = $mds->find_metadata('EntrezID');
  my $alt_type = "alt_" . $new_mdata->type;

  my $old_mdata_array = $mds->find_all_metadata_like($new_mdata->type);
  foreach my $mdata (@$old_mdata_array) {
    if(($mdata->type eq $new_mdata->type) and ($mdata->data ne $new_mdata->data)) {
      printf("[%s] UNLINK OLD MDATA:: %s -> %s\n", $entrezID->data,
            $feature->primary_name,
            $mdata->display_contents);
      $mds->add_tag_data($alt_type, $mdata->data);  #put the data back but with new alt type            
      $mds->remove_metadata($mdata);
      $mdata->unlink_from_feature($feature);
    }
  }
}


sub deprecate_geneID {
  my $geneID = shift;

  return unless($deprecateOK);

  my ($feature) = @{EEDB::Feature->fetch_all_by_source_symbol($eeDB,
                  $entrez_source, $geneID, 'EntrezID')};
  return unless($feature);
  printf("DEPRECATE ::  %s\n", $feature->simple_display_desc);
  $eeDB->execute_sql("UPDATE feature SET feature_source_id=? WHERE feature_id=?",
                     $deprecate_source->id, $feature->id);

  #this is just to check it
  $feature = EEDB::Feature->fetch_by_id($eeDB, $feature->id);
  printf("    %s\n", $feature->simple_display_desc);  
}

