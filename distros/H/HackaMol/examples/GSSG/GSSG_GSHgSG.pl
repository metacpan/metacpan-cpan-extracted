#!/usr/bin/env perl
# Demian Riccardi, May 27, 2014
#
# This script will add an Hg across the disulfide in GSSG
#
# use GSSG_3DK4.pl first to set up
use Modern::Perl;
use HackaMol;

my $hack = new HackaMol;

my @atoms = $hack->read_file_atoms("structures/GSSG.pdb");

my ($ss) = $hack->find_disulfide_bonds( @atoms );
my $mol = HackaMol::Molecule->new( atoms => [@atoms] );

my $bl = $ss->bond_length;
my $tl = 4.7;
$mol->bond_stretch_atoms( $ss, $tl - $bl, @atoms[ 20 .. 39 ] );

$mol->push_atoms(
    HackaMol::Atom->new(
        name    => 'HG',
        resname => 'HG2',
        symbol  => 'Hg',
        coords  => [ $ss->COM ]
    )
);

$mol->fix_serial(1);

$mol->print_pdb("structures/GSHgSG.pdb");

