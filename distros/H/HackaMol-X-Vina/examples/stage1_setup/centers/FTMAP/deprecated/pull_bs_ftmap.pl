#!/usr/bin/env perl
# Demian Riccardi 03/09/2014
# available on github
# print out COM of the binding sites predicted by FTMap
#
# The clusters of small molecule probes begin with HEADER: 
#   HEADER crosscluster.\d+.\d+.pdb 
#   
# This dum script will: 
#
#   1. write them all out into temporary xyz files 
#   2. read them in and print out the COM of the cluster
#   3. unlink the temporary xyz file
#
# need to use xyz file, because FTMap does not write a proper PDB 
# may need a dirty pdb reader
#
use Modern::Perl;
use HackaMol;
use File::Temp qw/ tempfile tempdir mkstemps/;
use File::chdir;
use FileHandle;
use Data::Dumper;

die "pass file (Str)  [cluster size cutoff (Int)]\n" unless @ARGV ;
my $file  = shift;
my $nclst = shift || 0;

my $fh   = FileHandle->new("< $file");

my @CLUSTERS;

my $i = 0;
while (<$fh>){
  if (/HEADER crosscluster/../REMARK/ ){
    if (/ATOM\s+\d+/){
      my ($symbol, $xyz) = unpack "x13A1x16A24", $_;
      push @{$CLUSTERS[$i]}, "$symbol $xyz\n";
    }
    $i++ if (/REMARK/); 
  }
}

my @lines ;
my $dir = tempdir( CLEANUP=>1 );

my $hack = HackaMol->new();
foreach my $clust (@CLUSTERS){
  my $ncluster = scalar(@{$clust});
  next unless ($ncluster >= $nclst);
  my ($fh, $filename) = mkstemps( "hackXXXX",'.xyz');
  #write xyz file
  print $fh "$ncluster\n\n";
  print $fh $_ foreach @{$clust};
  close($fh);
  #read in xyz and print COM
  my $mol = $hack->read_file_mol($filename);
  push @lines, sprintf("Hg %10.3f %10.3f %10.3f $ncluster\n", @{$mol->COM});
  unlink($filename);
}

print scalar (@lines) . "\n\n";
print foreach @lines;


