#!/usr/bin/env perl
use Modern::Perl;
use HackaMol;
use Math::Vector::Real;

my $hack = HackaMol->new( name => 'hackitup' );

my @atoms1 = $hack->read_file_atoms("t/lib/1L2Y.pdb");
my $mol1 = HackaMol::Molecule->new( name => 'trp-cage', atoms => [@atoms1] );

my @atoms2 = $hack->read_file_atoms("t/lib/2cba.pdb");
my $mol2 = HackaMol::Molecule->new( name => 'CAII', atoms => [@atoms2] );

my $mol3 =
  HackaMol::Molecule->new( name => 'both', atoms => [ @atoms1, @atoms2 ] );

$mol1->translate( -$mol1->COM );
$mol2->translate( -$mol2->COM + V( 30, 0, 0 ) );
$mol3->print_xyz;
foreach ( 1 .. 36 ) {
    $mol1->rotate( V( 1, 1, 1 ), 10, $mol2->COM );
    $mol1->rotate( V( 1, 1, 1 ), 10, $mol1->COM );
    $mol3->print_xyz;
}

