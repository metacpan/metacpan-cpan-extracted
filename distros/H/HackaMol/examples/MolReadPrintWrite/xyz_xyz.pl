#!/usr/bin/env perl
# Demian Riccardi
#  rewrites xyz files in the xyzs directory (change it to suit needs) with 
#  xyz.tdy extension
#
#  reads xyx with either atomic symbols or atomic number.
#  the print_xyz method prints the xyz lines with atomic symbols.
#  
use Modern::Perl;
use HackaMol;

my $hack = HackaMol -> new (data => "xyzs");

foreach my $xyz ( $hack->data->children (qr/\.xyz/) ) 
{

  HackaMol::Molecule -> new (
      atoms=>[
              $hack->read_file_atoms($xyz)
             ]
  ) -> print_xyz("$xyz.tdy");

}

