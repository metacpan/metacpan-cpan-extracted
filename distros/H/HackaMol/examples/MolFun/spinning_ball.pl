#!/usr/bin/env perl
# Demian Riccardi
# This script loads 1L2Y.pdb and then generates xyz coordinates for the molecule spinning across the screen
# to run:
#   perl spinning_ball.pl > spinning_ball.xyz
# 
# then load into your favorite GUI.  I use VMD
use Modern::Perl;
use HackaMol;
use Math::Vector::Real;

my $bld = HackaMol->new( name => "build" );
my $mol = $bld->pdbid_mol('1l2y');

$mol->translate( -$mol->COM );
$mol->translate( V( 90, 0, 0 ) );

foreach ( 1 .. 360 ) {
    $mol->translate( V( -0.5, 0, 0 ) );
    $mol->rotate( V( 1, 1, 1 ), 10, $mol->COM );
    $mol->print_xyz;
}

