#!/usr/bin/env perl
use Modern::Perl;
use HackaMol;

my $bldr = HackaMol->new( name => "builder", hush_read=>1 );
my @atoms = $bldr->read_file_atoms("t/lib/test.pdbqt");

# all coordinates from NMR ensemble are loaded into atoms
my $mol = HackaMol::Molecule->new(
    name  => 'somedrug',
    atoms => [@atoms]
);

foreach my $t (0 .. $mol->tmax){
  $mol->gt($t);
  $mol->print_pdb;
}

