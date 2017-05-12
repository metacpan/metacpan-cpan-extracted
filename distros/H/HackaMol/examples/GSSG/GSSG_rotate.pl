#!/usr/bin/env perl
# Demian Riccardi, May 27, 2014
#
# This script will rotate atoms about the disulfide bond in GSSG 
#
# use GSSG_3DK4.pl first to set up
use Modern::Perl;
use HackaMol;

my $tang = shift || 90;

my $hack = new HackaMol;

my @atoms = $hack->read_file_atoms("structures/GSSG.pdb");
my ($dihe) = $hack->build_dihedrals( @atoms[ 13, 14, 34, 33 ] );

my $mol = HackaMol::Molecule->new( atoms => [@atoms] );

my $dang = $dihe->dihe_deg;
printf( "Dihedral: %10.4f\n", $dang );
$mol->dihedral_rotate_atoms( $dihe, -( $tang - $dang ), @atoms[ 20 .. 39 ] );
printf( "Dihedral: %10.4f\n", $dihe->dihe_deg );

$mol->print_pdb("structures/GSSG_$tang.pdb");

