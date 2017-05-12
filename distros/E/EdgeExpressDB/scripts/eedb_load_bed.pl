#!/usr/local/bin/perl -w 

=head1 NAME - eedb_load_bed.pl

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
use Switch;

use MQdb::Database;
use EEDB::Assembly;
use EEDB::Tools::BEDLoader;

no warnings 'redefine';
$| = 1;

my $help;
my $passwd = '';

my $file = undef;
my $assembly_name = undef;
my $url = undef;
my $debug = 0;
my $store = 0;

my $import_blocks = undef;

my $fsrc_name = undef;

my $fsrc = undef;
my $exon_fsrc = undef;
my $utr3_fsrc = undef;
my $utr5_fsrc = undef;
my $subfeature_lsrc = undef;

my $display_interval = 250;

GetOptions( 
    'url:s'        =>  \$url,
    'file:s'       =>  \$file,
    'pass:s'       =>  \$passwd,
    'assembly:s'   =>  \$assembly_name,
    'asm:s'        =>  \$assembly_name,
    'fsrc:s'       =>  \$fsrc_name,
    'blocks'       =>  \$import_blocks,
    'debug:s'      =>  \$debug,
    'v'            =>  \$debug,
    'store'        =>  \$store,
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

my $bedloader = new EEDB::Tools::BEDLoader;
###

unless(defined($assembly_name)) {
  printf("ERROR: must supply -assembly parameter\n\n");
  usage();
}
my $assembly = EEDB::Assembly->fetch_by_name($eeDB, $assembly_name);
unless(defined($assembly)) {
  printf("ERROR: assembly [%s] not in database\n\n", $assembly_name);
  usage();
}
$assembly->display_info;

unless(defined($fsrc_name)) {
  printf("ERROR: must supply -fsrc parameter\n\n");
  usage();
}

###

$bedloader->database($eeDB);
$bedloader->assembly($assembly);
$bedloader->do_store($store);
$bedloader->debug($debug);
$bedloader->import_blocks($import_blocks);
$bedloader->source_name($fsrc_name);

###

if(!($bedloader->feature_source)) {
  printf("ERROR must specify -fsrc param\n\n");
  usage();
}

###

if($file and (-e $file)) { 

  $bedloader->load_features($file);

} else {
  printf("ERROR: must specify .bed file for data loading\n\n");
  usage(); 
}


exit(1);

#########################################################################################

sub usage {
  print "eedb_load_bed.pl [options]\n";
  print "  -help                  : print this help\n";
  print "  -url <url>             : URL to database\n";
  print "  -assembly <name>       : name of species/assembly (eg hg18 or mm9)\n";
  print "  -lsrc <name>           : name of the FeatureLinkSource to use for linking features to sub-features\n";
  print "  -fsrc <name>           : name of the primary FeatureSource for the data\n";
  print "  -block                 : turn on import of block subfeatures\n";
  print "  -file <path>           : path to .bed file for feature loading\n";
  print "eedb_load_bed.pl v1.0\n";
  
  exit(1);  
}

