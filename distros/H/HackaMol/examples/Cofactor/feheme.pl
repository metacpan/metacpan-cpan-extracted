#!/usr/bin/env perl
#
# DMR 4-15-2014
# simple script to help get started analyzing cofactors/metals in proteins 
#
# wget http://pdb.org/pdb/files/1C7D.pdb
#
# run:
# perl feheme.pl 1C7D.pdb 
#
use Modern::Perl;
use HackaMol;
use Statistics::Descriptive;

my $hack  = HackaMol->new ;
# load all atoms into an array
my @atoms = $hack->read_file_atoms(shift);

#pull out iron atoms
my @Fes   = grep {$_->symbol eq "Fe"} @atoms;

#pull out hemes, no iron
my @hemes = grep {
                  $_->resname eq "HEM" and
                  $_->symbol  ne "Fe"
                 } @atoms;

# find the bonds to fe foreach wrt hemes, print out lengths
foreach my $fe (@Fes){
  my @fe_bonds  = $hack ->find_bonds_brute(
                          bond_atoms => [$fe],
                          candidates => [@hemes],
#
#                         candidates => [grep {$_->symbol eq "N"} @hemes],
#
                          fudge      => 0.45,
                          max_bonds  => 6,
  );
  foreach my $bond (@fe_bonds){
    my @sym = map{ $_->symbol } $bond->all_atoms;
    printf ("%4s %4s %10.3f\n", @sym, $bond->bond_length); 
  }
  
  my $stat = Statistics::Descriptive::Full->new();
  $stat->add_data(map {$_->bond_length} @fe_bonds);
  printf ("Avg: %.3f Stdev: %.4f \n", $stat->mean, $stat->standard_deviation); 
  
}

# give all protein atoms within 5 angstroms of the cofactors
# not the most efficient... exercise: make faster
say "slowly carving 5.0 angstroms around the hemes for printing";
my %atom_bin;
foreach my $hemat (@hemes){
  my @iaround = grep{$hemat->distance($atoms[$_]) <= 5.0 } 0 .. $#atoms;
  $atom_bin{$_}++ foreach @iaround;
}

my @iats = sort{$a <=> $b} keys %atom_bin;

my $mol = HackaMol::Molecule->new(atoms=>[@atoms[@iats]]);
$mol->print_pdb;







