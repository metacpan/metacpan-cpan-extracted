#!/usr/local/bin/perl -w 

=head1 NAME - eedb_getedge.pl

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
use MQdb::MappedQuery;
use EEDB::Feature;
use EEDB::Expression;
use EEDB::Edge;
use EEDB::EdgeSource;

no warnings 'redefine';
$| = 1;

my $help;
my $passwd = '';
my $edge_id = undef;
my $url = undef;


GetOptions( 
            'url:s'    =>  \$url,
            'id:s'     =>  \$edge_id,
            'help'     =>  \$help
            );

if ($help) { usage(); }

my $rnaDB = undef;
if($url) {
  $rnaDB = MQdb::Database->new_from_url($url);
}

EEDB::Feature->set_cache_behaviour(1);

my $time1 = time();

fetch_edge();

printf("total time :: %1.3f secs\n", (time() - $time1));

exit(1);
#########################################################################################

sub usage {
  print "eedb_getedge.pl [options]\n";
  print "  -help              : print this help\n";
  print "  -url <url>         : URL to database\n";
  print "  -id <int>          : dbID of the Edge to fetch\n";
  print "eedb_getedge.pl v1.0\n";
  
  exit(1);  
}

sub fetch_edge {
  my $edges = [];
  
  if($edge_id) {
    my $edge = EEDB::Edge->fetch_by_id($rnaDB, $edge_id);
    print($edge, "\n");
    $edges = [$edge];
  } else {
    #$features = EEDB::Feature->fetch_all_named_region($rnaDB, 'hg18', 'chr9', 501000, 502000);
  }
  foreach my $edge (@$edges) {
    printf("====== XML =====\n");
    printf($edge->xml);

    printf("\n====== display_contents =====\n");
    print($edge->display_contents,"\n");
  }
}





