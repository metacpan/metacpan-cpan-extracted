#!/usr/local/bin/perl -w 

=head1 NAME - eedb_mirror_source.pl

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

my $url = undef;
my $url2 = undef;
my $store = 0;
my $debug=0;

my $db1ext=0;
my $db2ext=0;

my $no_meta=0;
my $create_edge=0;

my $fid = undef;
my $fsrc = undef;
my $fsrc_name = undef;
my $esrc = undef;
my $esrc_name = undef;

my $display_interval = 100;

GetOptions( 
            'url:s'        =>  \$url,
            'url2:s'       =>  \$url2,
            'fsrc:s'       =>  \$fsrc_name,
            'id:s'         =>  \$fid,
            'esrc:s'       =>  \$esrc_name,
            'f1ext'        =>  \$db1ext,
            'f2ext'        =>  \$db2ext,
            'nometa'       =>  \$no_meta,
            'store'        =>  \$store,
            'createedge'   =>  \$create_edge,
            'v'            =>  \$debug,
            'debug:s'      =>  \$debug,
            'help'         =>  \$help
            );


if ($help) { usage(); }

my $eeDB1 = MQdb::Database->new_from_url($url) if($url);
if(!$eeDB1) { 
  printf("ERROR: connecting to database -url\n\n");
  usage(); 
}

my $eeDB2 = MQdb::Database->new_from_url($url2) if($url2);
if(!$eeDB2) { 
  printf("ERROR: connecting to database -url2\n\n");
  usage(); 
}

#make sure the database we are mirroring into has a selfPeer
EEDB::Peer->create_self_peer_for_db($eeDB2);

my $primary_peer = mirror_primary_db_as_peer(); #the peer for $eeDB1 copied into $eeDB2

printf("\n==============\n");

if(defined($fsrc_name)) {
  my $category = undef;
  if($fsrc_name =~ /(\w+)\:\:(.+)/) {
    $category = $1;
    $fsrc_name = $2;
    $fsrc = EEDB::FeatureSource->fetch_by_category_name($eeDB1, $1, $2);
  } else {
    $fsrc = EEDB::FeatureSource->fetch_by_name($eeDB1, $fsrc_name);
  }
} 

if(defined($esrc_name)) {
  $esrc = EEDB::EdgeSource->fetch_by_name($eeDB1, $esrc_name);
} 

if($fsrc) {
  mirror_feature_data();
} 

if($esrc) {
  mirror_edge_source();
} 

if(!$fsrc and !$esrc) {
  printf("ERROR must specify either -esrc or -fsrc parameter\n\n");
  usage();
}


exit(1);

#########################################################################################

sub usage {
  print "eedb_mirror_source.pl [options]\n";
  print "  -help               : print this help\n";
  print "  -url <url>          : URL to source database\n";
  print "  -url2 <url>         : URL of target database (to be copied into)\n";
  print "  -fsrc <name>        : name of the FeatureSource to be mirrored\n";
  print "  -esrc <name>        : name of the EdgeSource to be mirrored\n";
  print "    -db1ext           : when loading edges, don't mirror feature1 but keep it remote with a peer\n";
  print "    -db2ext           : when loading edges, don't mirror feature2 but keep it remote with a peer\n";
  print "  -nometa             : do not mirror metadata. will include the primary_name as symbol\n";
  print "  -createedge         : when mirroring a FeatureSource, create a new EdgeSource connecting the\n";
  print "                        mirrored feature to it orginal\n";
  print "eedb_mirror_source.pl v1.0\n";
  
  exit(1);  
}

#########################################################################################

sub mirror_primary_db_as_peer {
  #in $eeDB2 create a peer entry for $eeDB1
  
  my $peer = EEDB::Peer->fetch_by_alias($eeDB1, $eeDB1->dbname); #should return the self Peer
  $peer->display_info;
  unless($peer) { return; }
  
  $peer->store($eeDB2) if($store);
  return $peer;
}

sub mirror_feature_data {

  my $multiLoad = new EEDB::Tools::MultiLoader;
  $multiLoad->database($eeDB2);
  $multiLoad->do_store($store);
  $multiLoad->mirror(1);
  
  my $mirror_source = $fsrc->copy;
  $mirror_source->primary_id(undef);
  $mirror_source->database(undef);
  if($store) { $mirror_source->store($eeDB2); }
  else { $mirror_source->primary_id(-1); }

  
  my $featmirror_esrc = undef;
  if($create_edge) {
    my $mirroredge_name = $fsrc->name . "_to-orginal-mirror";
    $featmirror_esrc = EEDB::EdgeSource->fetch_by_name($eeDB2, $mirroredge_name);
    unless($featmirror_esrc){
      $featmirror_esrc = new EEDB::EdgeSource;
      $featmirror_esrc->category("mirror");
      $featmirror_esrc->name($mirroredge_name);
      $featmirror_esrc->peer2($primary_peer);
      $featmirror_esrc->is_active('y');
      $featmirror_esrc->is_visible('y');
      $featmirror_esrc->store($eeDB2) if($store);
      printf("Needed to create:: ");
    }
    $featmirror_esrc->display_info;
  }
  
  printf("========  mirror ======\n");
  printf("FROM: %s ::: %s\n", $fsrc->display_desc, $eeDB1->url);
  printf("TO  : %s ::: %s\n", $mirror_source->display_desc, $eeDB2->url);
  
  my $starttime = time();
  my $linecount=0;

  my $stream = EEDB::Feature->stream_all_by_source($fsrc);
  
  while(my $orig_feature = $stream->next_in_stream) {
    $linecount++;
    if(defined($fid) and ($orig_feature->primary_id ne $fid)) { next; }

    if($debug) { print($orig_feature->display_contents()); }

    $orig_feature->metadataset; #lazy load and check
    
    my $feature = $orig_feature->copy; #shallow copy
    $feature->feature_source($mirror_source);
    if($no_meta) { 
      $feature->metadataset->init; 
      $feature->metadataset->add_tag_symbol("keyword", $feature->primary_name);
    }
    #make sure metadata is properly sorted into Symbols and Metadata
    $feature->metadataset->convert_bad_symbols; 

    #when mirroring features, make sure we keep the original federate ID
    #by storing it in the metadata
    my $eeID = $primary_peer->uuid . "::" . $orig_feature->id;
    $feature->metadataset->add_tag_symbol("eedb_id", $eeID);

    $feature->primary_id(undef);
    $multiLoad->store_feature($feature);
    
    if($create_edge) {
      my $edge = new EEDB::Edge;
      $edge->edge_source($featmirror_esrc);
      $edge->feature1($feature);
      $edge->feature2($orig_feature);        
      $multiLoad->store_edge($edge);
      #printf("          %s\n", $edge->display_desc) if($debug>2);
    }
    
    if($linecount % $display_interval == 0) { 
      my $rate = $linecount / (time() - $starttime);
      printf("%10d (%1.2f x/sec): %s\n", $linecount, $rate, $feature->simple_display_desc); 
    }
  }

  #to flush the MultiLoader buffers 
  $multiLoad->store_feature();
  $multiLoad->store_edge();

  my $total_time = time() - $starttime;
  my $rate = $linecount / $total_time;
  printf("TOTAL: %10d :: %1.3f min :: %1.2f x/sec\n", $linecount, $total_time/60.0, $rate);
}


sub mirror_edge_source {

  my $multiLoad = new EEDB::Tools::MultiLoader;
  $multiLoad->database($eeDB2);
  $multiLoad->do_store($store);
  $multiLoad->mirror(1);
  
  my $edgesource_mirror = $esrc->copy;
  $edgesource_mirror->primary_id(undef);
  $edgesource_mirror->database(undef);
  if($db1ext) { $edgesource_mirror->peer1($primary_peer); }
  if($db2ext) { $edgesource_mirror->peer2($primary_peer); }
  
  $edgesource_mirror->store($eeDB2) if($store);
  
  printf("========  mirror ======\n");
  printf("FROM: %s ::: %s\n", $esrc->display_desc, $eeDB1->url);
  printf("TO  : %s ::: %s\n", $edgesource_mirror->display_desc, $eeDB2->url);
  
  my $starttime = time();
  my $linecount=0;

  my $stream = EEDB::Edge->stream_all_by_source($esrc);
  
  while(my $edge = $stream->next_in_stream) {
    $linecount++;

    $edge->metadataset; #lazy load
    $edge->feature1;
    $edge->feature2;
    $edge->edge_source($edgesource_mirror);
    
    if(!$db1ext) {
      #need to copy the feature over too
      my $f1src = $edge->feature1->feature_source;
      my $f1src_db2 = EEDB::FeatureSource->fetch_by_category_name($eeDB2, $f1src->category, $f1src->name);
      #fetch_by_category_name uses cache so this is pretty fast
      if(!$f1src_db2) {
        $f1src->primary_id(undef);
        $f1src->database(undef);
        $f1src->store($eeDB2) if($store);
        $f1src_db2 = $f1src;
      }
      
      #copy feature2 over, first create symbol for original primary id as fedID
      my $f1 = $edge->feature1;
      my $eeID = $primary_peer->uuid . "::" . $f1->id;
      $f1->metadataset->add_tag_symbol("eedb_id", $eeID);
      
      #then check it does not already exist in eeDB2
      ($f1) = @{EEDB::Feature->fetch_all_by_source_symbol($eeDB2, $f1src_db2, $eeID, "eedb_id")};
      if($f1) { $edge->feature1($f1); }
      else {
        #nope, go ahead and mirror it, unfortunately I need to do this right now, no multiload.. this is slow.
        #  The better overall strategy would be to make sure the FeatureSource is mirrored first
        #  the to mirror the edges since the above "fetch" code would return the feature which is much faster
        my $f1 = $edge->feature1;
        $f1->feature_source($f1src_db2);
        $f1->store($eeDB2) if($store);
      }
    }

    if(!$db2ext) {
      #need to copy the feature over too
      my $f2src = $edge->feature2->feature_source;
      my $f2src_db2 = EEDB::FeatureSource->fetch_by_category_name($eeDB2, $f2src->category, $f2src->name);
      #fetch_by_category_name uses cache so this is pretty fast
      if(!$f2src_db2) {
        $f2src->primary_id(undef);
        $f2src->database(undef);
        $f2src->store($eeDB2) if($store);
        $f2src_db2 = $f2src;
      }
      
      #copy feature2 over, first create symbol for original primary id as fedID
      my $f2 = $edge->feature2;
      my $eeID = $primary_peer->uuid . "::" . $f2->id;
      $f2->metadataset->add_tag_symbol("eedb_id", $eeID);
      
      #then check it does not already exist in eeDB2
      ($f2) = @{EEDB::Feature->fetch_all_by_source_symbol($eeDB2, $f2src_db2, $eeID, "eedb_id")};
      if($f2) { $edge->feature2($f2); }
      else {
        #nope, go ahead and mirror it, unfortunately I need to do this right now, no multiload.. this is slow.
        #  The better overall strategy would be to make sure the FeatureSource is mirrored first
        #  the to mirror the edges since the above "fetch" code would return the feature which is much faster
        my $f2 = $edge->feature2;
        $f2->feature_source($f2src_db2);
        $f2->store($eeDB2) if($store);
      }
    }
   
    #now the edge is ready
    $edge->primary_id(undef);
    $multiLoad->store_edge($edge);

    if($debug) { print($edge->display_contents()); }
    
    if($linecount % $display_interval == 0) { 
      my $rate = $linecount / (time() - $starttime);
      printf("%10d (%1.2f x/sec): %s\n", $linecount, $rate, $edge->display_desc); 
    }
  }

  #to flush the MultiLoader buffers 
  $multiLoad->store_feature();
  $multiLoad->store_edge();

  my $total_time = time() - $starttime;
  my $rate = $linecount / $total_time;
  printf("TOTAL: %10d :: %1.3f min :: %1.2f x/sec\n", $linecount, $total_time/60.0, $rate);
}
