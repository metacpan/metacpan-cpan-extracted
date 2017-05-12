#!/usr/bin/env perl
# This script will: 
#  1. pull down pdbid 3DK4 from the PDB
#  2. extract the GSSG
#  3. write out a new pdb containing only the GSSG 
#
# pubchem id can also be used to fetch
# @ids = qw/65359/;
#
use Modern::Perl;
use HackaMol;

my $hack = HackaMol->new(scratch=>'structures');
$hack->scratch->mkpath unless $hack->scratch->exists;

unless ( -e "structures/3DK4.pdb" ){
  system("wget http://pdb.org/pdb/files/3DK4.pdb");
  system("mv 3DK4.pdb structures/3DK4.pdb");
} 


my @atoms = $hack->read_file_atoms("structures/3DK4.pdb");

my $hetmol = HackaMol::Molecule->new(
    atoms => [
        grep { $_->resname eq 'GSH' } @atoms,
    ]
);
$hetmol->fix_serial(1);
$hetmol->print_pdb("structures/GSSG.pdb");

