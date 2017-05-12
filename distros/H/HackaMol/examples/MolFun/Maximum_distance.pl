#!/usr/bin/env perl

use Modern::Perl;
use Math::Vector::Real::Farthest;
use HackaMol;

my $hack = HackaMol->new(data=>"local_pdbs");

my @pdbs = $hack -> data -> children ( qr/\.pdb/ );

foreach my $pdb ( @pdbs ){

  my @xyzs = map{$_->xyz} $hack->read_file_atoms($pdbqt);
  my ($d2, $v0, $v1) = Math::Vector::Real::Farthest->find(@xyzs);
  printf ("%20s %10.3f\n", $pdb, sqrt($d2));

}

