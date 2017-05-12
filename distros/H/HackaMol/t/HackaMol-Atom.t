#!/usr/bin/env perl

use strict;
use warnings;
use Test::Moose;
use Test::More;
use Test::Fatal qw(dies_ok);
use Test::Warn;
use Math::Vector::Real;
use HackaMol::Atom;

my @attributes = qw( name t mass xyzfree is_fixed
                     is_dirty symbol Z vdw_radius covalent_radius
                   );
my @methods = qw(
  _build_mass _build_symbol _build_Z _build_covalent_radius _build_vdw_radius
  change_Z  change_symbol _clean_atom
  distance 
);

my @pdb_attributes = qw(
record_name
serial    
occ       
bfact     
resname   
chain     
altloc    
resid     
iatom     
icode     
pdbid     
segid     
);

my @qm_attributes = qw(
basis
ecp
basis_geom
dummy
);
#todo add tests for storage!

my @roles = qw(
              HackaMol::Roles::PdbRole 
              HackaMol::Roles::QmAtomRole 
              HackaMol::Roles::PhysVecMVRRole
);

map has_attribute_ok( 'HackaMol::Atom', $_ ), @attributes;
map can_ok( 'HackaMol::Atom', $_ ), @methods;
map does_ok( 'HackaMol::Atom', $_ ), @roles;
map has_attribute_ok( 'HackaMol::Atom', $_ ), @pdb_attributes;
map has_attribute_ok( 'HackaMol::Atom', $_ ), @qm_attributes;

my $atom1 = HackaMol::Atom->new(
    name    => 'C',
    charges => [-1],
    coords  => [ V( 3.12618, -0.06060, 0.05453 ) ],
    Z       => 6
);
my $atom2 = HackaMol::Atom->new(
    name    => 'Hg',
    charges => [2],
    coords  => [ V( 1.04508, -0.06088, 0.05456 ) ],
    symbol  => 'HG'
);
my $atom3 = HackaMol::Atom->new(
    name    => 'H1',
    charges => [0],
    coords  => [ V( 3.50249, 0.04320, -0.98659 ) ],
    symbol  => 'H'
);
my $atom4 = HackaMol::Atom->new(
    name    => 'H2',
    charges => [0],
    coords  => [ V( 3.50252, 0.78899, 0.66517 ) ],
    Z       => 1
);
my $atom5 = HackaMol::Atom->new(
    name    => 'H3',
    charges => [0],
    coords  => [ V( 3.50247, -1.01438, 0.48514 ) ],
    Z       => 1
);

my @atoms = ( $atom1, $atom2, $atom3, $atom4, $atom5 );

is( $atom1->symbol, 'C',  'Z      =>  6 generates symbol C ' );
is( $atom2->symbol, 'Hg', 'symbol => HG generates symbol Hg' );
is( $atom2->Z,      80,   'symbol => HG generates Z      80' );
is( $atom3->Z,      1,    'symbol => H  generates Z      1 ' );
is( sprintf( "%.2f", $atom1->distance($atom2) ),
    2.08, 'MeHg+ : C to Hg distance' );
is( sprintf( "%.2f", $atom1->distance($atom3) ),
    1.11, 'MeHg+ : C to H distance' );
is( sprintf( "%.2f", $atom1->distance($atom4) ),
    1.11, 'MeHg+ : C to H distance' );
is( sprintf( "%.2f", $atom1->distance($atom5) ),
    1.11, 'MeHg+ : C to H distance' );
is( sprintf( "%.2f", $atom3->distance($atom4) ),
    1.81, 'MeHg+ : H to H distance' );
is( sprintf( "%.2f", $atom3->distance($atom5) ),
    1.81, 'MeHg+ : H to H distance' );
is( sprintf( "%.3f", $atom1->angle_deg($atom2,$atom3)), 109.783, "angle atom2-atom1-atom3");
is( sprintf( "%.3f", $atom1->angle_deg($atom2,$atom4)), 109.789, "angle atom2-atom1-atom4");
is( sprintf( "%.3f", $atom1->angle_deg($atom2,$atom5)), '109.770', "angle atom2-atom1-atom5");
is( sprintf( "%.3f", $atom2->angle_deg($atom3,$atom5)), 39.665, "angle atom3-atom2-atom5");
is( sprintf( "%.3f", $atom3->dihedral_deg($atom2,$atom1,$atom4)),  120.018, "dihedral angle atom3-atom2-atom1-atom4");
is( sprintf( "%.3f", $atom3->dihedral_deg($atom1,$atom2,$atom4)), -120.018, "dihedral angle atom3-atom1-atom2-atom4");
is( sprintf( "%.3f", $atom4->dihedral_deg($atom1,$atom2,$atom3)),  120.018, "dihedral angle atom4-atom1-atom2-atom3");
is( sprintf( "%.3f", $atom4->dihedral_deg($atom2,$atom1,$atom3)), -120.018, "dihedral angle atom4-atom2-atom1-atom3");

my ( $bin, $elname ) = bin_atoms( \@atoms );
is( $elname, 'C1H3Hg1',
"name sorted by symbol constructed from binned atom symbols (C1H3Hg1) as expected"
);

my ( $prnts, $sum_mass ) = elemental_analysis( $bin, $elname );

is( sprintf( "%.2f", $sum_mass ), 215.63, "mass of MeHg+ sums as expected" );
is(
    $prnts->[0],
    " H     1.0079     3   1.40\n",
    "H  in elemental analysis as expected"
);
is(
    $prnts->[1],
    " C    12.0107     1   5.57\n",
    "C  in elemental analysis as expected"
);
is(
    $prnts->[2],
    "Hg   200.5920     1  93.03\n",
    "Hg in elemental analysis as expected"
);
ok( !$atom2->is_dirty, "atom 2 is clean" );
warning_is { $atom2->change_Z(22) }
"cleaning atom attributes for in place change. setting atom->is_dirty",
  "warning from changing Z";

warning_is { $atom2->change_symbol("Zn") }
"cleaning atom attributes for in place change. setting atom->is_dirty",
  "warning from changing symbol";

dies_ok {HackaMol::Atom->new(name=>"noZ noSymbol")} "Croak unless Z or symbol passed";

is( $atom2->symbol, 'Zn', "atom 2 changed from Hg to Zn" );
is( sprintf("%.2f", $atom2->mass), 65.38 , "atom 2 mass changed from Hg to Zn" );
is( sprintf("%.2f", $atom2->covalent_radius), 1.18 , "Zn atom covalent radius" );
is( sprintf("%.2f", $atom2->vdw_radius), 1.39 , "Zn atom vdw radius" );
ok( $atom2->is_dirty, "atom 2 is now dirty" );


dies_ok {$atom2->change_symbol} "croak if no argument passed to change_symbol";
dies_ok {$atom2->change_Z}      "croak if no argument passed to change_Z";

( $bin, $elname ) = bin_atoms( \@atoms );
( $prnts, $sum_mass ) = elemental_analysis( $bin, $elname );
is( $elname, 'C1H3Zn1',
"name sorted by symbol constructed from binned atom symbols (C1H3Zn1) as expected"
);
is( sprintf( "%.2f", $sum_mass ), 80.42, "mass of MeHg+ sums as expected" );
is(
    $prnts->[0],
    " H     1.0079     3   3.76\n",
    "H  in elemental analysis as expected"
);
is(
    $prnts->[1],
    " C    12.0107     1  14.94\n",
    "C  in elemental analysis as expected"
);
is(
    $prnts->[2],
    "Zn    65.3820     1  81.30\n",
    "Zn in elemental analysis as expected"
);


done_testing();

sub bin_atoms {
    my $atoms = shift;
    my %bin;
    $bin{ $_->symbol }++ foreach @{$atoms};
    my $elname;
    $elname .= $_ . $bin{$_} foreach ( sort keys %bin );
    return ( \%bin, $elname );
}

sub elemental_analysis {
    my $atom_bin = shift;
    my $label    = shift;
    my @atoms =
      map { HackaMol::Atom->new( symbol => $_, iatom => $atom_bin->{$_} ) }
      keys %{$atom_bin};

    @atoms = sort { $a->mass <=> $b->mass } @atoms;
    my $mass_sum = 0;
    $mass_sum += $_->iatom * $_->mass foreach @atoms;
    my @prnts = map {
        sprintf( "%2s %10.4f %5i %6.2f\n",
            $_->symbol, $_->mass, $_->iatom,
            100 * $_->iatom * $_->mass / $mass_sum )
    } @atoms;

    return ( \@prnts, $mass_sum );
}
