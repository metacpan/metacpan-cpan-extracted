#!/usr/local/bin/perl -w 

=head1 NAME - eedb_create_instance.pl

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
my $store = 0;
my $debug=0;

my $eedb_webdir   = $ENV{EEDB_WEBDIR};
my $eedb_webroot  = $ENV{EEDB_WEBROOT};
my $eedb_registry = $ENV{EEDB_REGISTRY};


GetOptions( 
            'url:s'        =>  \$url,
            'webroot:s'    =>  \$eedb_webroot,
            'registry:s'   =>  \$eedb_registry,
            'v'            =>  \$debug,
            'debug:s'      =>  \$debug,
            'help'         =>  \$help
            );


if ($help) { usage(); }

if(!$url) {
  printf("ERROR: must specify -url for the eeDB instance to be created\n\n");
  usage(); 
}

my $eeDB = MQdb::Database->new_from_url($url);
my $dbc=undef;
eval { $dbc = $eeDB->get_connection; };
if($dbc) { 
  printf("WARNING: eeDB instance [%s] already exists!!\n\n", $url);
} else {
  $eeDB = create_new_instance();
}

if($eeDB) {
  my $weburl = create_webservice();

  printf("\n==============\n");
  my $peer = EEDB::Peer->create_self_peer_for_db($eeDB, $weburl);
  print($peer->xml, "\n");
  
  #now register into eedb_registry
  if($eedb_registry) {
    my $eeREG = MQdb::Database->new_from_url($eedb_registry, $eeDB->password);
    my $reg_peer = $peer->copy;
    $reg_peer->primary_id(undef);
    $reg_peer->database(undef);
    $reg_peer->store($eeREG);
  }
}

exit(1);

#########################################################################################

sub usage {
  print "eedb_create_instance.pl [options]\n";
  print "  -help               : print this help\n";
  print "  -url <url>          : URL to source database\n";
  print "  -v                  : simple debugging output\n";
  print "  -debug <level>      : extended debugging output (eg -debug 3)\n";
  print "eedb_create_instance.pl v1.0\n";
  
  exit(1);  
}

#########################################################################################


sub create_new_instance {

  my $new_dbname = $eeDB->dbname;

  printf("target URL : %s\n", $eeDB->full_url);
  printf("new database [%s]\n", $new_dbname);
  
  my $mysqlDB = MQdb::Database->new_from_url($url);
  $mysqlDB->{'_database'} = "mysql";
  printf("root eedb : %s\n", $mysqlDB->full_url);
  my $dbc2=undef;
  eval { $dbc2 = $mysqlDB->get_connection; };
  if(!$dbc2) { 
    printf("ERROR: connecting to MYSQL database\n\n");
    usage(); 
  }
  
  printf("create new database [%s]\n", $new_dbname);
  $mysqlDB->do_sql("create database ". $new_dbname);
  
  my $mysqlcmd = sprintf("mysql -h %s -P %s -u%s -p%s %s ", 
                    $eeDB->host,
                    $eeDB->port,
                    $eeDB->user,
                    $eeDB->password,
                    $eeDB->dbname);
  my $cmd1 = $mysqlcmd . " < /usr/local/EdgeExpressDB/sql/schema.sql\n";
  my $cmd2 = $mysqlcmd . " < /usr/local/EdgeExpressDB/sql/assembly_chrom_data.sql\n";

  print($cmd1);
  system($cmd1);
  
  print($cmd2);
  system($cmd2);
                           
  return $eeDB;
}


sub create_webservice {
  return undef unless($eedb_webdir and -e $eedb_webdir);
  my $webdir = $eedb_webdir . "/" . $eeDB->dbname;
  printf("ok make the webservice :: %s\n", $webdir);
  
  my $cmd = "cp -rp /usr/local/EdgeExpressDB/www/edgeexpress " . $webdir;
  print($cmd, "\n");
  system($cmd);
  
  #create the cgi/eedb_server.conf file
  my $conf_file = $webdir."/cgi/eedb_server.conf";
  open(CONF, ">$conf_file");
  printf(CONF "[ { TYPE  => 'EEDB_URL',\n");
  my $pub_url = sprintf("%s://read:read\\\@%s:%s/%s", 
                    $eeDB->driver, 
                    $eeDB->host, 
                    $eeDB->port, 
                    $eeDB->dbname);
  printf(CONF " 'url' => \"%s\"\n", $pub_url);
  printf(CONF "}, { TYPE => 'END' } ]\n");
  close(CONF);
  printf("write conf :: %s\n", $conf_file);

  my $weburl = $eedb_webroot . "/" . $eeDB->dbname;
  return $weburl;
}
  
1;
