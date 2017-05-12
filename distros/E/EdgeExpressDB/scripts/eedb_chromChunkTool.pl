#!/usr/local/bin/perl -w 

=head1 NAME - eedb_chromChunkTool.pl

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

use MQdb::Database;
use MQdb::MappedQuery;

use EEDB::Assembly;
use EEDB::Chrom;
use EEDB::ChromChunk;

no warnings 'redefine';
$| = 1;

my $help;
my $passwd = '';

my $chunk_size    = 505000; #ie 505 kbase
my $chunk_overlap =   5000; #ie 5 kbase
my $block_size    =    100; #group 100 chunks into sets for output into fasta
my $assembly_name = '';
my $dirpath = undef;
my $dumpdir = "./";
#my $dirpath       = "/Users/jessica/src/riken_gsc/SGEblast/tmp/hg18/"; #directory of chromsome fasta
my $url = undef;
my $store = 0;
my $withseq =0;

my $chunk_id = undef;
my $dump     = undef;
my $create_chunks = undef;
my $kmer = undef;
my $fasta_file = undef;

GetOptions( 
            'url:s'         =>  \$url,
            'fetch:s'       =>  \$chunk_id,
            'dump'          =>  \$dump,
            'dumpdir:s'     =>  \$dumpdir,
            'create'        =>  \$create_chunks,
            'store'         =>  \$store,
            'withseq'       =>  \$withseq,
            'chunk_size:s'  =>  \$chunk_size,
            'block_size:s'  =>  \$block_size,
            'overlap:s'     =>  \$chunk_overlap,
            'assembly:s'    =>  \$assembly_name,
            'seqdir:s'      =>  \$dirpath,
            'fasta:s'       =>  \$fasta_file,
            'help'          =>  \$help
            );


if ($help) { usage(); }


my $eeDB = undef;
if($url) {
  $eeDB = MQdb::Database->new_from_url($url);
} 

unless($eeDB) { 
  printf("NO databases specified\n\n"); 
  usage(); 
}

my $assembly;
if($assembly_name) {
  $assembly = EEDB::Assembly->fetch_by_name($eeDB, $assembly_name);
  unless($assembly) {
    printf("unable to find assembly : %s\n\n", $assembly_name);
    usage();
  }
  $assembly->display_info;
}

if($fasta_file) { chromosome_chunk_fasta($fasta_file); exit(1); }

if($kmer) { kmer_chromosomes(); exit(1); }

if(defined($chunk_id)) { test_chunk_fetch($chunk_id); exit(1); }

if($create_chunks) { create_chromosome_chunking(); exit(1); }

if($assembly and $dump) { dump_chunks(); exit(1); }

#falls through so show usage
usage();

exit(1);

#########################################################################################

sub usage {
  print "chromChunkTool.pl [options]\n";
  print "  -help                  : print this help\n";
  print "  -fasta <path>          : fasta file of chromosome sequence\n";
  print "  -fetch <id>            : fetch ChromChunk from database by ID\n";
  print "  -create                : CREATE new set of chromosome chunks\n";
  print "  -chunk_size <num>      :   creation maximum chunk size base pairs\n";
  print "  -overlap <num>         :   creation chunk overlap base pairs\n";
  print "  -assembly <name>       :   assembly name (UCSC or NCBI name) for creation\n";
  print "  -seqdir <path>         :   path for directory of whole genome fasta sequences\n";
  print "  -dump                  : dump fetched ChromChunk(s) into a local fasta file\n";
  print "  -chunk_size <num>      :   creation maximum chunk size base pairs\n";

  print "chromChunkTool.pl v1.0\n";
  
  exit(1);  
}

sub create_chromosome_chunking {
  printf("\ncreating new set of genome chunks\n");
  printf("   genome_dir : %s\n", $dirpath);
  printf("   assembly   : %s\n", $assembly->display_desc);
  printf("   chunk_size : %s\n", $chunk_size);
  printf("   overlap    : %s\n", $chunk_overlap);
  printf("---------------\n");

  opendir(SEQDIR, $dirpath) or die "Cannot open directory: $!";
  foreach my $file (readdir(SEQDIR)) {
    next unless(($file =~ /\.fa$/) or ($file =~ /\.fa.gz$/));
    $file = $dirpath ."/". $file;
    chromosome_chunk_fasta($file);
  } #loop on files
}


sub chromosome_chunk_fasta {
  my $file = shift;
  printf("\nfasta = $file\n");

  my $gz = gzopen($file, "rb") ;
  my $name = '';
  my @filetoks = split (/\//, $file);
  my $filename = pop @filetoks;
  if($filename =~ /(.*).fa(.*)/) {
    $name = $1;
    printf("  name => $name\n");
  }
  
  my $chrom = EEDB::Chrom->fetch_by_assembly_chrname($assembly, $name);  
  if(!defined($chrom)) {
    #create the chromosome;
    $chrom = new EEDB::Chrom;
    $chrom->chrom_name($name);
    $chrom->assembly($assembly);
    $chrom->store($eeDB) if($store);
    printf("need to create chromosome ::");
  }
  printf("  %s\n", $chrom->display_desc);
  
  my $description = '';
  my $seq = '';
  my $seq_len =0;
  my $chrom_start = 1; #chromosomes are referenced starting at '1'
  my $chrom_len =0;
  my $line;
  while(my $bytesread = $gz->gzreadline($line)) {
    chomp($line);
    if($line =~ /^>(.*)/) { #title line
      if($seq_len > 0) {
        create_chunk($chrom, $description, $seq, $chrom_start, $chrom_start+$seq_len-1);
      }
      $description = $1;
      printf("  desc => $description\n");
      $chrom->description($description);
      $seq = '';
      $seq_len =0;
      my $chrom_start = 1; #chromosomes are referenced starting at '1'
      my $chrom_len =0;
    } else {
      if($seq_len >= $chunk_size) {
        #chunk
        create_chunk($chrom, $description, $seq, $chrom_start, $chrom_start+$seq_len-1);
        $seq = substr($seq, -$chunk_overlap); #grab last '$chunk_overlap' bases for overlap region
        $chrom_start += $seq_len - $chunk_overlap;
        $seq_len = $chunk_overlap;
      }
      #$line =~ s/\s*//g;
      $seq .= $line;
      my $tlen = length($line);
      $seq_len += $tlen;
      $chrom_len += $tlen;
      #printf("%d : %d : %d\n", $tlen, $seq_len, $chrom_start);
    }
    
  } #while(..gzreadline..)
  $gz->gzclose();

  #if sequence left un-chunked then need to chunk it
  if($seq_len > 0) {
    #chunk
    create_chunk($chrom, $description, $seq, $chrom_start, $chrom_start+$seq_len-1);
  }
  printf("  chrom_len = %d\n", $chrom_len);
  $chrom->chrom_length($chrom_len);
  $chrom->update();
  $chrom->display_info;
}


sub create_chunk {
  my $chrom       = shift;
  my $description = shift;
  my $seq         = shift;
  my $chr_start   = shift;
  my $chr_end     = shift;

  my $chunk = new EEDB::ChromChunk();
  $chunk->chrom($chrom);
  #$chunk->chrom_name($name);
  $chunk->chrom_start($chr_start);
  $chunk->chrom_end($chr_end);
  
  if($withseq) {
    my $bioseq = Bio::Seq->new(-id=>$chrom->chrom_name, -seq=>$seq);
    $chunk->sequence($bioseq);
  }
  $chunk->check_exists_db($eeDB);
  
  $chunk->store($eeDB) if($store);
  $chunk->display_info;
}


sub test_chunk_fetch {
  my $id = shift;
  
  my $chunk1 = EEDB::ChromChunk->fetch_by_id($eeDB, $id);
  $chunk1->display_info;
  if($dump) { $chunk1->dump_to_fasta_file; }
}


sub kmer_chromosomes {
  my $kmer_size = 7;

  printf("\nkmer the chromsomes\n");
  printf("   genome_dir : %s\n", $dirpath);
  printf("   kmer_size  : %s\n", $kmer_size);
  printf("---------------\n");

  my $kmer_counts = {};
  
  opendir(SEQDIR, $dirpath) or die "Cannot open directory: $!";
  foreach my $file (readdir(SEQDIR)) {
    next if ($file !~ /\.fa$/);
    $file = $dirpath . $file;
    printf("\nfasta = $file\n");
    open(FASTA, $file) or die "Cannot open file: $!";
    my @seq_buffer = ();
    my @kmer = ();
    my $line_num=1;
    #each is a chromosome
  
    while(my $line = <FASTA>) {
      chomp($line);
      $line = uc($line);
      next if($line =~ /^>(.*)\s*(.*)/); #title line
      $line_num++;
      if($line_num % 100000 == 0) { printf("line %d\n", $line_num); }
      push @seq_buffer, split(//, $line);
      #printf("line : %s\n", $line);

      if(scalar(@kmer) < $kmer_size) {
        #first time so need to prime the kmer
        while(scalar(@kmer) < $kmer_size) {
          my $tbase = shift @seq_buffer;
          push @kmer, $tbase;
          #my $kmer_str = join('',@kmer);
          #printf("   %s\n", $kmer_str);
        }
        my $kmer_str = join('',@kmer);
        my $seq_str = join('',@seq_buffer);
        count_kmer($kmer_counts, $kmer_str, $seq_str);
      }
      
      while(scalar(@seq_buffer) > 0) {
        my $tbase = shift @seq_buffer;
        shift @kmer;
        push @kmer, $tbase;
        my $kmer_str = join('',@kmer);
        my $seq_str = join('',@seq_buffer);
        count_kmer($kmer_counts, $kmer_str, $seq_str);
      }
    } #while($line <FASTA>)
  } #loop on files
  
  printf("\n====== kmer summary =====\n");
  foreach my $kmer (keys(%{$kmer_counts})) {
    printf("INSERT into kmer_counts(kmer_seq, count) VALUES ('%s', %d);\n", $kmer, $kmer_counts->{$kmer});
  }
}

sub count_kmer {
  my $kmer_counts = shift;
  my $kmer_str = shift;
  my $seq_str = shift;
  
  #printf("   %s : %s\n", $kmer_str, $seq_str);
  if(!defined($kmer_counts->{$kmer_str})) {
    $kmer_counts->{$kmer_str} = 1;
  } else {
    $kmer_counts->{$kmer_str}++;
  }
}


sub raw_chromosomes {
  my $kmer_size = 7;

  printf("\nkmer the chromsomes\n");
  printf("   genome_dir : %s\n", $dirpath);
  printf("   kmer_size  : %s\n", $kmer_size);
  printf("---------------\n");

  my $kmer_counts = {};
  
  opendir(SEQDIR, $dirpath) or die "Cannot open directory: $!";
  foreach my $file (readdir(SEQDIR)) {
    next if (($file !~ /\.fa$/) or ($file !~ /\.fa.gz$/));
    $file = $dirpath . $file;
    printf("\nfasta = $file\n");
    if ($file !~ /\.fa$/) {
      open(FASTA, $file) or die "Cannot open file: $!";
    } else {
      open(FASTA, "|zcat $file") or die "Cannot open file: $!";
    }
    my @seq_buffer = ();
    my @kmer = ();
    my $line_num=1;
    #each is a chromosome
  
    while(my $line = <FASTA>) {
      chomp($line);
      $line = uc($line);
      next if($line =~ /^>(.*)\s*(.*)/); #title line
      $line_num++;
      if($line_num % 100000 == 0) { printf("line %d\n", $line_num); }
    } #while($line <FASTA>)
    last;
  } #loop on files  
}

#########################################################################################
#
# dumping in prepartion of "file" based pipelines
#

sub dump_chunks {
  
  printf("dump chunk\n");
  
  my $dirpath = $dumpdir .'/'. $assembly->ucsc_name . "_chromchunksets/";
  mkdir($dirpath);

  my $chrom_list = EEDB::Chrom->fetch_all_by_assembly_id($eeDB, $assembly->id);
  foreach my $chrom (@$chrom_list) {
    $chrom->display_info;
    my $chunk_list = EEDB::ChromChunk->fetch_all_by_chrom($chrom);
    
    my $blockcount =1;
    my $chunkcount =0;
    my $fastafile = $dirpath. $assembly->ucsc_name .'_'. $chrom->chrom_name .'_set'. $blockcount++ .".fa";
    open(OUTSEQ, ">$fastafile") or die("Error opening $fastafile for write");

    foreach my $chunk (@$chunk_list) {
      printf("  "); $chunk->display_info;
      
      if($chunkcount >= $block_size) {
        close OUTSEQ;
        $fastafile = $dirpath. $assembly->ucsc_name .'_'. $chrom->chrom_name .'_set'. $blockcount++ .".fa";
        open(OUTSEQ, ">$fastafile") or die("Error opening $fastafile for write");
        $chunkcount = 0;
      }
      $chunkcount++;
      
      my $name = $chunk->chunk_name;
      my $seq = $chunk->sequence->seq;
      $seq =~ s/(.{72})/$1\n/g;
      chomp $seq;
      printf OUTSEQ ">$name\n$seq\n";
    } #loop the ChromChunk
    close OUTSEQ;
  } #loop the Chrom

}


