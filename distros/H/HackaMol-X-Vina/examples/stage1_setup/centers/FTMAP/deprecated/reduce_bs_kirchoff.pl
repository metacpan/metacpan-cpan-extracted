#!/usr/bin/env perl
# Demian Riccardi 03/10/2014
# available on github
#
# reduces the number of nodes using kirchoff matrix 
#
# the clusters generated using pull_bs_ftmap.pl were often overlapping to 
# some degree.  This script will collapse them down using a kirchoff matrix:
#   1. load up molecule from xyz file
#   2. calculate the kirchoff
#   3. sort by diagonal (big to small) 
#   4. delete biggest cluster (all those connected to the biggest node)
#   ... repeat 2 .. 4 until the molecule has no atoms 
#

use Modern::Perl;
use HackaMol;

my $hack  = HackaMol->new;
my $mol   = $hack->read_file_mol(shift);
my $cut   = 10;
my $cut2  = $cut*$cut;

my @mols;

while ($mol->count_atoms){
  my @atoms = $mol->all_atoms;
  my @coords   = map {$_->xyz} @atoms;
  my $kirchoff = calc_kirchoff(@coords);
  my %kirchoff = %$kirchoff;
#pull the diagonal
  my @diag = map {$kirchoff{$_}{$_}} 0 .. $#coords;
  my @bigsmall = sort{ $diag[$b] <=> $diag[$a] } 0 .. $#coords;
#printf ("%5i %5i\n", $_ , $diag[$_]) foreach @bigsmall; 
  my $iatom  = shift @bigsmall;
  my @idelat = sort{$b <=> $a} keys $kirchoff{$iatom};
#  say $mol->count_atoms ," ", scalar (@idelat), " ", $kirchoff{$iatom}{$iatom};
  push @mols, HackaMol::Molecule->new(name=>"atom_$iatom", atoms=>[@atoms[@idelat]]);
  $mol->delete_atoms($_) foreach @idelat;
} 

print scalar(@mols). "\n\n";
printf ("Hg %10.3f %10.3f %10.3f\n", @{$_->COM}) foreach @mols;

exit;

sub calc_kirchoff{
  my @coords = @_;

  my %kirchoff ;
  $kirchoff{$_}{$_} = 0 foreach (0 .. $#coords);

  #calculate upper diagonal of kirchoff matrix
  foreach my $i (0 .. $#coords){
    my $ci = $coords[$i];
    foreach my $j ($i+1 .. $#coords) {
      my $cj = $coords[$j];
      my $dij2 = $cj->dist2($ci);
      if ($dij2 < $cut2){
        $kirchoff{$i}{$i}++;
        $kirchoff{$j}{$j}++;
        $kirchoff{$i}{$j}--;
        $kirchoff{$j}{$i}--;
      }
      else {
        next;
      }
    }
  }
  return (\%kirchoff);
}
