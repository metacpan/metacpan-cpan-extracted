#!/usr/bin/env perl

use strict;
use warnings;
use Test::Moose;
use Test::More;
use Test::Warn;
use Test::Fatal qw(dies_ok);
use Math::Vector::Real;
use Math::Vector::Real::Random;
use Math::Trig;
use HackaMol;

my @attributes = qw(
  groups bonds angles dihedrals atoms mass name
);
my @methods = qw(
  push_groups set_groups get_groups all_groups clear_groups
  select_groups map_groups
  sort_groups
  insert_groups
  delete_groups count_groups all_bonds_atoms all_angles_atoms
  all_dihedrals_atoms dihedral_rotate_atoms
);
my @roles = qw(
              HackaMol::Roles::PhysVecMVRRole 
              HackaMol::Roles::BondsAnglesDihedralsRole 
              HackaMol::Roles::AtomGroupRole);

map has_attribute_ok( 'HackaMol::Molecule', $_ ), @attributes;
map can_ok( 'HackaMol::Molecule', $_ ), @methods;
map does_ok( 'HackaMol::Molecule', $_ ), @roles;

my $hack  = HackaMol->new(name => "hackitup");
my @atoms = $hack->read_file_atoms("t/lib/2LL5_mod123.pdb"); 

my $max_t = $atoms[0]->count_coords - 1;

my $mol = HackaMol::Molecule->new( name => 'trp-cage', atoms => [@atoms] );

is( $mol->charge, 0, 'molecule with no charge gives 0 charge' );
$mol->push_charges(-1);
is( $mol->charge, -1, 'molecule charge from charges' );
$mol->charge(1);
is( $mol->charge, 1, 'set molecule charge' );
is( $mol->count_atoms, 283, 'number of atoms: 283' );
# check mass of molecule.  Have not checked whether the number
# for 2ll5 is actually correct.
cmp_ok(abs(2124.20656-$mol->mass),'<', 1E-7, "mass of the molecule" );
#dubious test, Rgs COMs generated from HackaMol, double check
my @Rgt =
  qw(7.19251198554957 7.15700534761354 7.14685267470545 7.00573838170868 7.21240816173855 7.18269096506165 7.090359584332 7.15239515247956 7.16336404927373 7.21275609325176 7.19505186699334 7.10928755300199 7.11941832497372 7.21511627204864 7.3088703725112 7.19876994990288 7.25732589008288 7.23532446379484 7.1890879967172 7.13373953831758 7.12469776280913 6.95147600134586 7.09343947318801 7.25038296705691 7.16489832835357 7.0962667805229 7.05103784479553 7.04501594915213 7.16973657632147 7.12776512790071 7.19457930266239 7.1262398705025 7.21766853448075);

my @COMs = (
    [ 29.132, 0.299, 0.412 ],
    [ 29.135, 0.259, 0.422 ],
    [ 29.236, 0.088, 0.452 ],
    [ 29.137, 0.298, 0.481 ],
    [ 29.122, 0.284, 0.504 ],
    [ 29.085, 0.210, 0.419 ],
    [ 29.081, 0.316, 0.455 ],
    [ 29.116, 0.176, 0.385 ],
    [ 29.111, 0.315, 0.454 ],
    [ 29.175, 0.168, 0.443 ],
    [ 29.117, 0.280, 0.393 ],
    [ 29.243, 0.256, 0.432 ],
    [ 29.082, 0.300, 0.403 ],
    [ 29.117, 0.168, 0.447 ],
    [ 29.169, 0.269, 0.477 ],
    [ 29.256, 0.250, 0.503 ],
    [ 29.181, 0.216, 0.445 ],
    [ 29.119, 0.180, 0.473 ],
    [ 29.126, 0.186, 0.459 ],
    [ 29.137, 0.287, 0.434 ],
    [ 29.171, 0.228, 0.517 ],
    [ 29.078, 0.128, 0.481 ],
    [ 29.222, 0.125, 0.476 ],
    [ 29.186, 0.108, 0.372 ],
    [ 29.084, 0.345, 0.415 ],
    [ 29.077, 0.162, 0.464 ],
    [ 29.240, 0.254, 0.445 ],
    [ 29.149, 0.204, 0.452 ],
    [ 29.079, 0.203, 0.457 ],
    [ 29.044, 0.193, 0.350 ],
    [ 29.074, 0.256, 0.482 ],
    [ 29.134, 0.125, 0.523 ],
    [ 29.101, 0.268, 0.427 ],
);

foreach my $t ( 0 .. $max_t ) {
    $mol->t($t);
    my $ocom = sprintf( "%8.3f %8.3f %8.3f\n", @{ $mol->COM } );
    my $ecom = sprintf( "%8.3f %8.3f %8.3f\n", @{ $COMs[$t] } );
    is( $ocom, $ecom, "COM at $t" );
    cmp_ok( abs( $mol->Rg - $Rgt[$t] ), '<', 1E-7, "Rg at $t" );
}

my @bonds =
  map {HackaMol::Bond->new( atoms => [ $atoms[0], $atoms[$_] ] ) } 1 .. $#atoms;
$mol->push_bonds(@bonds);
is( $atoms[0]->bond_count, $#atoms, "bond count of atom[0]" );

my $bond_count = 0;
$bond_count += $_->bond_count foreach $mol->all_atoms;
is( $bond_count, 2 * $#atoms, "total double-counted bond count" );

$mol->t(0);
my @ncord =
  grep { $_->bond_length < 5.0 and $_->bond_length > 0.0 } $mol->all_bonds;
foreach my $bond (@ncord) {
    is( $bond->get_atoms(0)->t,
        $mol->t, "atoms in bond time and mol time are same" );
}

is( scalar(@ncord), 21, "21 atoms within 5 angstroms of first atom" );

$mol->clear_bonds;
$bond_count = 0;
$bond_count += $_->bond_count foreach $mol->all_atoms;
is( $bond_count, 0, "bond count is 0 after mol->clear_bonds" );

#push in a bunch of bonds, angles and dihedrals and do some rotations
#using backbone and ignoring the circular sequence of 2ll5
my @bbatoms = grep { $_->name eq 'N' or $_->name eq 'CA' or $_->name eq 'C' }
  $mol->all_atoms;

#reset iatom
$bbatoms[$_]->iatom($_) foreach 0 .. $#bbatoms;
my $mol2 = HackaMol::Molecule->new( name => 'trp-cage', atoms => [@bbatoms] );
$mol2->t(0);

my @bbangles;
my @bbbonds;
my @bbdihedrals;

# build the bonds, angles, dihedrals
my $k = 0;
while ( $k + 3 <= $#bbatoms ) {
    push @bbbonds,
      HackaMol::Bond->new( name => "Bond-" . $k, atoms => [ @bbatoms[ $k, $k + 1 ] ] );
    push @bbangles,
      HackaMol::Angle->new( name => "Angl-" . $k, atoms => [ @bbatoms[ $k .. $k + 2 ] ] );
    push @bbdihedrals,
      HackaMol::Dihedral->new(
        name  => "Dihe-" . $k,
        atoms => [ @bbatoms[ $k .. $k + 3 ] ]
      );
    $k++;
}
push @bbbonds,
  HackaMol::Bond->new( name => "Bond-" . $k, atoms => [ @bbatoms[ $k, $k + 1 ] ] );
push @bbangles,
  HackaMol::Angle->new( name => "Angl-" . $k, atoms => [ @bbatoms[ $k .. $k + 2 ] ] );
$k++;
push @bbbonds,
  HackaMol::Bond->new( name => "Bond-" . $k, atoms => [ @bbatoms[ $k, $k + 1 ] ] );

$mol2->push_bonds(@bbbonds);
$mol2->push_angles(@bbangles);
$mol2->push_dihedrals(@bbdihedrals);

is( $bbatoms[0]->bond_count,  1, "bond count on atom 0 is 1" );
is( $bbatoms[-1]->bond_count, 1, "bond count on last atom is 1" );

my @bonds10 = $mol2->all_bonds_atoms( $mol2->get_atoms(10) );
is( $bonds10[0]->get_atoms(0)->iatom,
    9, "atom9 bonded to atom 10 via all_bonds_atoms(atom10)" );
is( $bonds10[1]->get_atoms(1)->iatom,
    11, "atom11 bonded to atom 10 via all_bonds_atoms(atom10)" );

my @bonds1011 =
  $mol2->all_bonds_atoms( $mol2->get_atoms(10), $mol2->get_atoms(11) );
is( $bonds1011[0]->get_atoms(0)->iatom,
    9, "atom9 bonded to atom 10 via all_bonds_atoms(atom10,atom11)" );
is( $bonds1011[1]->get_atoms(1)->iatom,
    11, "atom11 bonded to atom 10 via all_bonds_atoms(atom10,atom11)" );
is( $bonds1011[2]->get_atoms(0)->iatom,
    10, "atom10 bonded to atom 11 via all_bonds_atoms(atom10,atom11)" );
is( $bonds1011[3]->get_atoms(1)->iatom,
    12, "atom12 bonded to atom 11 via all_bonds_atoms(atom10,atom11)" );

my @angles10 = $mol2->all_angles_atoms( $mol2->get_atoms(10) );
is_deeply(
    [ map { $angles10[0]->get_atoms($_)->iatom } 0 .. 2 ],
    [ 8, 9, 10 ],
    "angle 8_9_10 via all_angles_atoms(atom10)"
);
is_deeply(
    [ map { $angles10[1]->get_atoms($_)->iatom } 0 .. 2 ],
    [ 9, 10, 11 ],
    "angle 9_10_11 via all_angles_atoms(atom10)"
);
is_deeply(
    [ map { $angles10[2]->get_atoms($_)->iatom } 0 .. 2 ],
    [ 10, 11, 12 ],
    "angle 10_11_12 via all_angles_atoms(atom10)"
);

my @angles1011 = $mol2->all_angles_atoms( $mol2->get_atoms(10),$mol2->get_atoms(11) );
is_deeply(
    [ map { $angles1011[0]->get_atoms($_)->iatom } 0 .. 2 ],
    [ 8, 9, 10 ],
    "angle 8_9_10 via all_angles_atoms(atom10,atom11)"
);
is_deeply(
    [ map { $angles1011[1]->get_atoms($_)->iatom } 0 .. 2 ],
    [ 9, 10, 11 ],
    "angle 9_10_11 via all_angles_atoms(atom10,atom11)"
);
is_deeply(
    [ map { $angles1011[2]->get_atoms($_)->iatom } 0 .. 2 ],
    [ 9, 10, 11 ],
    "angle 9_10_11 via all_angles_atoms(atom10,atom11)"
);
is_deeply(
    [ map { $angles1011[3]->get_atoms($_)->iatom } 0 .. 2 ],
    [ 10, 11, 12 ],
    "angle 10_11_12 via all_angles_atoms(atom10,atom11)"
);
is_deeply(
    [ map { $angles1011[4]->get_atoms($_)->iatom } 0 .. 2 ],
    [ 10, 11, 12 ],
    "angle 10_11_12 via all_angles_atoms(atom10,atom11)"
);
is_deeply(
    [ map { $angles1011[5]->get_atoms($_)->iatom } 0 .. 2 ],
    [ 11, 12, 13 ],
    "angle 11_12_13 via all_angles_atoms(atom10,atom11)"
);

my @dihedrals1011 = $mol2->all_dihedrals_atoms( $mol2->get_atoms(10),$mol2->get_atoms(11) );
is_deeply(
    [ map { $dihedrals1011[0]->get_atoms($_)->iatom } 0 .. 3 ],
    [ 7, 8, 9, 10 ],
    "dihedral 7_8_9_10 via all_dihedrals_atoms(atom10,atom11)"
);
is_deeply(
    [ map { $dihedrals1011[1]->get_atoms($_)->iatom } 0 .. 3 ],
    [ 8, 9, 10, 11 ],
    "dihedral 8_9_10_11 via all_dihedrals_atoms(atom10,atom11)"
);
is_deeply(
    [ map { $dihedrals1011[3]->get_atoms($_)->iatom } 0 .. 3 ],
    [ 9, 10, 11,12 ],
    "dihedral 9_10_11_12 via all_dihedrals_atoms(atom10,atom11)"
);
is_deeply(
    [ map { $dihedrals1011[5]->get_atoms($_)->iatom } 0 .. 3 ],
    [ 10, 11, 12,13 ],
    "dihedral 10_11_12_13 via all_dihedrals_atoms(atom10,atom11)"
);


$bond_count = 0;
$bond_count += $_->bond_count foreach $mol2->all_atoms;
is(
    $bond_count,
    2 * scalar(@bbatoms) - 2,
    "double-counted bond count for backbone"
);
$mol2->delete_bonds(0);
$bond_count = 0;
$bond_count += $_->bond_count foreach $mol2->all_atoms;
is( $bond_count, 2 * scalar(@bbatoms) - 4, "delete first bond for backbone" );
$mol2->delete_bonds(10);
$bond_count = 0;
$bond_count += $_->bond_count foreach $mol2->all_atoms;
is( $bond_count, 2 * scalar(@bbatoms) - 6, "delete 10th bond for backbone" );
my $end_bond = $mol2->delete_bonds(-1);
$bond_count = 0;
$bond_count += $_->bond_count foreach $mol2->all_atoms;
is( $bond_count, 2 * scalar(@bbatoms) - 8, "delete last bond for backbone" );
$mol2->set_bonds( 10, $end_bond );
is(
    $bond_count,
    2 * scalar(@bbatoms) - 8,
    "count for set_bonds (removes and adds 2-2=0)"
);

my @bond_lengths = map { $_->bond_length } $mol2->all_bonds;
my @angs         = map { $_->ang_deg } $mol2->all_angles;

my @iatoms = map { $_->iatom } @bbatoms;
my $natoms = $mol2->count_atoms;

foreach my $dihe (@bbdihedrals) {

    my $ratom1 = $dihe->get_atoms(1);
    my $ratom2 = $dihe->get_atoms(2);

    # atoms from nterm to ratom1 and from ratom2 to cterm
    my @nterm = 0 .. $ratom1->iatom - 1;
    my @cterm = $ratom2->iatom + 1 .. $natoms - 1;

    # use the smaller list for rotation
    my $r_these = \@nterm;
    $r_these = \@cterm if ( @nterm > @cterm );

    #set angle to rotate
    my $rang = -1 * ( $dihe->dihe_deg + 180 );

    #switch nterm to cterm switches sign on angle
    $rang *= -1 if ( @nterm > @cterm );
    my @slice = @bbatoms[ @{$r_these} ];

    #ready to rotate!
    $mol2->dihedral_rotate_atoms( $dihe, $rang, @slice );

}

my @bond_lengths_n = map { $_->bond_length } $mol2->all_bonds;
my @angs_n         = map { $_->ang_deg } $mol2->all_angles;

foreach my $i ( 0 .. $#bond_lengths ) {
    cmp_ok( abs( $bond_lengths[$i] - $bond_lengths_n[$i] ),
        '<', 1E-6, "bond_length $i unchanged after 180 rotation" );
}

foreach my $i ( 0 .. $#angs ) {
    cmp_ok( abs( $angs[$i] - $angs_n[$i] ),
        '<', 1E-6, "angle $i unchanged after 180 rotation" );
}

foreach my $i ( 0 .. $#bbdihedrals ) {
    my $dihe = $bbdihedrals[$i];
    cmp_ok( abs( abs( $dihe->dihe_deg ) - 180 ),
        '<', 1E-6, "dihedral $i rotated to 180" );
}

#lets stretch a bond
my $bond3      = $mol2->get_bonds(2);
my @all_atoms  = $mol2->all_atoms;
my @slice = @all_atoms[$bond3->get_atoms(1)->iatom .. $#all_atoms];

my $group = HackaMol::AtomGroup->new(atoms=>[@slice]);

#$mol2->print_xyz;
my $bi = $bond3->bond_length;
$mol2->bond_stretch_groups($bond3,10,$group);
dies_ok{$mol2->bond_stretch_groups($bond3,0)} "bond_stretch_groups dies <3 args";
dies_ok{$mol2->bond_stretch_atoms($bond3,0)} "bond_stretch_atoms dies <3 args";
my $bf = $bond3->bond_length;
cmp_ok(abs($bf-$bi - 10), '<', 1E-6, "bond stretch +10 groups");
$mol2->bond_stretch_atoms($bond3,-10,@slice);
$bf = $bond3->bond_length;

cmp_ok(abs($bf-$bi), '<', 1E-6, "bond stretch -10 atoms");

my $new_angle = HackaMol::Angle->new(name=>'quick', atoms=>[
                                 $all_atoms[$bond3->get_atoms(0)->iatom-1],
                                 $bond3->all_atoms,
                                                 ]);

my $angi = $new_angle->ang_deg;
$mol2->angle_bend_groups($new_angle,-50,$group);
dies_ok{$mol2->angle_bend_groups($new_angle,-50)} "angle_bend_groups dies <3 args";
dies_ok{$mol2->angle_bend_atoms($new_angle,-50)} "angle_bend_atoms dies <3 args";
my $angf = $new_angle->ang_deg;
cmp_ok(abs($angf-$angi+50), '<', 1E-6, "angle bend -50 group");
$mol2->angle_bend_groups($new_angle,+50,$group);
$angf = $new_angle->ang_deg;
cmp_ok(abs($angf-$angi), '<', 1E-6, "angle bend +50 group");

$mol2->angle_bend_atoms($new_angle,-50,@slice);
$angf = $new_angle->ang_deg;
cmp_ok(abs($angf-$angi+50), '<', 1E-6, "angle bend -50 atoms");

my $new_dihe = HackaMol::Dihedral->new(name=>'quick', atoms =>[
                                 $all_atoms[$bond3->get_atoms(0)->iatom-2],
                                  $new_angle->all_atoms,
                                                    ]);

my $dihei = $new_dihe->dihe_deg;
$mol2->dihedral_rotate_groups($new_dihe,360,$group);
dies_ok{$mol2->dihedral_rotate_groups($new_angle,-50)} "dihedral_rotate_groups dies <3 args";
dies_ok{$mol2->dihedral_rotate_atoms($new_angle,-50)} "dihedral_rotate_atoms dies <3 args";
my $dihef = $new_dihe->dihe_deg;

cmp_ok(abs($dihef-$dihei), '<', 1E-6, "dihedral rotate 360 group");


# using groups to create and adjust molecules
{

my $c6h6_xyz =
'  C        0.00000        1.40272        0.00000
  C       -1.21479        0.70136        0.00000
  C       -1.21479       -0.70136        0.00000
  C        0.00000       -1.40272        0.00000
  C        1.21479       -0.70136        0.00000
  C        1.21479        0.70136        0.00000
  H        0.00000        2.49029        0.00000
  H       -2.15666        1.24515        0.00000
  H       -2.15666       -1.24515        0.00000
  H        0.00000       -2.49029        0.00000
  H        2.15666       -1.24515        0.00000
  H        2.15666        1.24515        0.00000
'; 

my $mol = $hack->read_string_mol($c6h6_xyz,'xyz');
my $newmol  = HackaMol::Molecule->new(groups => [$mol]); 
my $newmol2 = HackaMol::Molecule->new;
$newmol2->push_groups($mol);


is($newmol->count_atoms, $mol->count_atoms, 'creating a molecule by passing a molecule in through groups has_atoms');
is($newmol2->count_atoms, $mol->count_atoms, 'creating a molecule, and then pushing a molecule through groups has_atoms');

my $atomgroup = HackaMol::AtomGroup->new(atoms=>[$mol->get_atoms(0), $mol->get_atoms(3)]);
$newmol->push_groups($atomgroup);

is($newmol->count_atoms, $mol->count_atoms, 'pushing a group of atoms already within the molecule does not push more atoms into the molecule');

}

done_testing();

