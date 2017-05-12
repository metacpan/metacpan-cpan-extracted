#!/usr/local/bin/perl -w 

=head1 NAME - eedb_getchunk.pl

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

use MQdb::Database;

use EEDB::ChromChunk;
use EEDB::Chrom;

no warnings 'redefine';
$| = 1;

my $help;
my $passwd = '';
my $id=1;
my $all=undef;
my $url = undef;
my $assembly = 'hg18';
my $chr_name;
my $start = undef;
my $end = undef;
my $strand = '+';
my $loc = undef;
my $loc_file = undef;
my $verbose = 0;
my $fasta = undef;

GetOptions( 
      'url:s'       =>  \$url,
      'id:s'        =>  \$id,
      'assembly:s'  =>  \$assembly,
      'chr:s'       =>  \$chr_name,
      'start:s'     =>  \$start,
      'end:s'       =>  \$end,
      'strand:s'    =>  \$strand,
      'loc:s'       =>  \$loc,
      'loc_file:s'  =>  \$loc_file,
      'fasta'       =>  \$fasta,
      'all'         =>  \$all,
      'v'           =>  \$verbose,
      'help'        =>  \$help
      );

if ($help) { usage(); }

my $tagsDB = undef;
if($url) {
  $tagsDB = MQdb::Database->new_from_url($url);
} 
unless($tagsDB) { printf("ERROR: must specify database URL\n\n"); usage(); }

if(defined($loc)) {  
  if($loc =~ /(.*)\:(\d+)\.\.(\d+)(\D*)/) {
    $chr_name = $1;
    $start = $2;
    $end = $3;
    $strand = $4 if(defined($4));
    #printf("%s %s %s %s\n", $chr_name, $start, $end, $strand);
  }
}

if($loc_file) {
  load_loc_file();
}
elsif(defined($all)) {
  dumpChunkToWorkdir();
} else {
  my $chrObj; #both Chrom and ChromChunk have almost same interface so can be interchanged for most things
  if(defined($chr_name) and $start and $end) {
    $chrObj = EEDB::Chrom->fetch_by_name($tagsDB, $assembly, $chr_name);
    #($chrObj) = @{EEDB::ChromChunk->fetch_all_named_region($tagsDB, $assembly, $chr_name, $start, $end)};
  } elsif(defined($id)) {
    $chrObj = EEDB::ChromChunk->fetch_by_id($tagsDB, $id);
  }
  if(!defined($chrObj)) { printf("error fetching chrom/chunk\n\n"); usage(); }
  
  $chrObj->display_info if($verbose);
  if($start and $end) {
    my $bioseq = $chrObj->get_subsequence($start, $end, $strand);
    if($fasta) {
      my $output_seq = Bio::SeqIO->new( -fh =>\*STDOUT, -format => 'fasta');
      $output_seq->write_seq($bioseq);
    } else {
      printf(">%s\n%s\n", $bioseq->id, $bioseq->seq);
    }
  } else {
    $chrObj->dump_to_fasta_file;
  }
}

exit(1);


############################################
sub usage {
  print "eedb_getchunk.pl [options]\n";
  print "  -url <url>           : URL to database\n";
  print "  -help                : print this help\n";
  print "  -all                 : dump all chrom_chunks to fasta\n";
  print "  -id <chunk_id>       : dump whole chrom_chunk via chrom_chunk_id to fasta\n";
  print "  -assembly <name>     : assembly name (UCSC or NCBI name)\n";
  print "  -loc <location>      : chromosome location in chr12:123100..123900 style\n";
  print "  -chr <name>          : chromosome name\n";
  print "  -start <num>         : chromosome start\n";
  print "  -end <num>           : chromosome end\n";
  print "  -strand <dir>        : strand as + or -\n";
  print "eedb_getchunk.pl v1.0\n";
  
  exit(1);  
}


sub dumpChunkToWorkdir
{
  my $chunk_list = EEDB::ChromChunk->fetch_all($tagsDB);
  my $fastafile = "chunk_range_all.fasta";
  printf("fetched %d chunks\n", scalar(@$chunk_list));

  $fastafile =~ s/\/\//\//g;  # converts any // in path to /
  print("fastafile = '$fastafile'\n");

  open(OUTSEQ, ">$fastafile");
  
  my $chunk = shift @$chunk_list;
  while($chunk) {
    printf("write chunk %d\n", $chunk->id);
    my $name = sprintf("chunk_%d", $chunk->id);
    my $seq = $chunk->sequence->seq;
    $seq =~ s/(.{72})/$1\n/g;
    chomp $seq;
    printf OUTSEQ ">$name\n$seq\n";
    $chunk = shift @$chunk_list;
  }
  close OUTSEQ;

  printf("running xdformat\n");
  system("xdformat -n $fastafile 2>&1 > /dev/null");

  return $fastafile;
}


sub load_loc_file {
  open FILE, $loc_file;
  foreach my $line (<FILE>) {
    chomp($line);
    $line =~ s/\r//g;
    my $loc = $line;
    
    if($loc =~ /(.*)\:(\d+)\.\.(\d+)(\D*)/) {
      $chr_name = $1;
      $start = $2;
      $end = $3;
      $strand = $4 if(defined($4));
      #printf("%s %s %s %s\n", $chr_name, $start, $end, $strand);

      my $chunk1;
      if(defined($chr_name)) {
        ($chunk1) = @{EEDB::ChromChunk->fetch_all_named_region($tagsDB, $assembly, $chr_name, $start, $end)};
      }
      my $subseq = $chunk1->get_subsequence($start, $end, $strand);
      printf(">%s\n%s\n", $subseq->id, $subseq->seq);
    } else {
      printf(">$loc\nERROR parsing the location $loc\n");
    }
  }

}
