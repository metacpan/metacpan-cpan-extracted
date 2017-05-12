#!/usr/bin/env perl

use strict;
use warnings;
use Test::Moose;
use Test::More;
use Test::Fatal qw(lives_ok dies_ok);
use Test::Warn;
use HackaMol::Atom;                # v0.001;#To test for version availability
use Math::Vector::Real;           
use Scalar::Util qw(refaddr);
use Time::HiRes qw(time);

#PhysVecMVRRole specific
my @attributes = qw( t mass xyzfree is_fixed coords forces charges);
my @methods = qw(
  push_charges get_charges set_charges all_charges clear_charges
  push_coords get_coords set_coords all_coords clear_coords
  push_forces get_forces set_forces all_forces clear_forces
  has_charges
  distance 
  intra_dcoords intra_dforces intra_dcharges
  inter_dcoords inter_dforces inter_dcharges
  mean_coords mean_forces mean_charges
  msd_coords msd_forces msd_charges
  charge xyz force
);

map has_attribute_ok( 'HackaMol::Atom', $_ ), @attributes;
map can_ok( 'HackaMol::Atom', $_ ), @methods;

my ( $obj1, $obj2, $obj3 );

lives_ok {
    $obj1 = HackaMol::Atom->new( Z => 1, t => 1 );
}
'Test creation of an Atom obj1';


is($obj1->charge, 0, "an atom with no charges returns 0 charge");
is($obj1->t, 1, "t set ok");
$obj1->t(0);
is($obj1->t, 0, "t change ok");
my $t = 1;
$obj1->t(\$t);
is_deeply($obj1->t, \$t, "set to scalar reference");
$obj1->t(3);

is_deeply($obj1->xyzfree, [1,1,1], "xyzfree by default");
is($obj1->is_fixed, 0, "not fixed");
$obj1->xyzfree([0,1,1]);
is_deeply($obj1->xyzfree, [0,1,1], "x fixed");
is($obj1->is_fixed, 1, "atom is now fixed");
$obj1->is_fixed(0);
is_deeply($obj1->xyzfree, [0,1,1], "xyzfree does not depend on is_fixed");

$obj1->xyzfree([1,1,0]);
is_deeply($obj1->xyzfree, [1,1,0], "z now fixed");
is($obj1->is_fixed, 1, "atom is now fixed");

$obj1->clear_xyzfree;
$obj1->xyzfree([1,1,1]);
is_deeply($obj1->xyzfree, [1,1,1], "xyzfree again");
is($obj1->is_fixed, 0, "atom is now free");

is_deeply($obj1->origin, V(0,0,0), "origin defaults to 0 0 0");


$obj1->push_charges($_) foreach ( 0.3, 0.2, 0.1, -0.1, -0.2, -0.36 );
cmp_ok( $obj1->count_charges, '==', 6, 'pushed 6 _tcharges and we have 6' );

my $sum_charges = 0;
$sum_charges += $_ foreach $obj1->all_charges;
cmp_ok( abs($sum_charges+0.06), '<', 1E-7, 'sum of charges as expected' );

cmp_ok( $obj1->get_charges(4), '==', -0.2, '5th _tcharges as expected' );

$obj1->set_charges( 4, 1.0 );
cmp_ok( $obj1->get_charges(4),
    '==', 1.0, '5th _tcharges set to 1.0 and get_charges as expected' );

lives_ok {
    $obj2 = HackaMol::Atom->new(Z => 1, t => 0 );
}
'Test creation of an obj2';

$obj1->set_coords( $obj1->t, V( 1, 0, 0 ) );
$obj2->set_coords( $obj2->t, V( 0, 1, 0 ) );
warning_is { $obj1->distance($obj2) }
"comparing objects with different times",
  "carp warning about obj1 and obj2 distance with different t";

$obj1->t(0);
$obj1->set_coords( $obj1->t, V( 1, 0, 0 ) );

my $sqrt_2 =
  sprintf( "%.10f", 1.4142135623730951 );    # double precision from fortran 90

cmp_ok( sprintf( "%.10f", $obj1->distance($obj2) ),
    '==',
    $sqrt_2, "distance between 100 and 010 to 10 decimal places: $sqrt_2" );

cmp_ok( sprintf( "%.10f", $obj2->distance($obj1) ),
    '==',
    $sqrt_2,
    "default obj2 distance between 100 and 010 to 10 decimal places: $sqrt_2" );

my $dq = $obj1->get_charges(1) - $obj1->get_charges(0);

cmp_ok( $obj1->intra_dcharges( 0, 1 ),
    '==', $dq, "change in charges between t = 0 and t = 1: $dq" );

$obj1->set_coords( 0, V( 0.0011,     -0.98458734, 1.0003984 ) );
$obj1->set_coords( 1, V( 1.00130011, 1.1,         2.0342 ) );
my $vec0 = $obj1->get_coords(0);
my $vec1 = $obj1->get_coords(1);
my @vec  = map { $vec1->[$_] - $vec0->[$_] } 0 .. 2;

is_deeply( $obj1->intra_dcoords( 0, 1 ), V(@vec), 'intra_dcoords' );

$obj1->push_forces( V( 0.0011,     -0.98458734, 1.0003984 ) );
$obj1->push_forces( V( 1.00130011, 1.1,         2.0342 ) );

$vec0 = $obj1->get_coords(0);
$vec1 = $obj1->get_coords(1);
@vec  = map { $vec1->[$_] - $vec0->[$_] } 0 .. 2;

is_deeply( $obj1->intra_dforces( 0, 1 ), V(@vec), 'intra_dforces' );

lives_ok {
    $obj3 = HackaMol::Atom->new( Z=>1,
        t       => 0,
        charges => [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 ],
        coords  => [
           V( 0, 0, 0 ),
           V( 1, 1, 1 ),
           V( 2, 2, 2 ),
           V( 3, 3, 3 ),
           V( 4, 4, 4 ),
           V( 5, 5, 5 ),
           V( 6, 6, 6 ),
           V( 7, 7, 7 ),
           V( 8, 8, 8 ),
           V( 9, 9, 9 ),
        ],
        forces => [
           V( 0, 0, 0 ),
           V( 1, 1, 1 ),
           V( 2, 2, 2 ),
           V( 3, 3, 3 ),
           V( 4, 4, 4 ),
           V( 5, 5, 5 ),
           V( 6, 6, 6 ),
           V( 7, 7, 7 ),
           V( 8, 8, 8 ),
           V( 9, 9, 9 ),
        ]
    );
}
'Test creation of an obj3';

is_deeply( $obj3->intra_dcoords( 0, 1 ), V( 1, 1, 1 ), 'intra_dcoords' );
is( $obj3->intra_dcharges( 0, 9 ), 9, 'intra_dcharges' );
dies_ok{$obj3->intra_dcharges} "intra_dcharges dies with 0 arg";
dies_ok{$obj3->intra_dcharges(0)} "intra_dcharges dies with 1 arg";
dies_ok{$obj3->intra_dcharges(0,1,3)} "intra_dcharges dies with 3 arg";

dies_ok{$obj3->intra_dcoords} "intra_dcoords dies with 0 arg";
dies_ok{$obj3->intra_dcoords(0)} "intra_dcoords dies with 1 arg";
dies_ok{$obj3->intra_dcoords(0,1,3)} "intra_dcoords dies with 3 arg";

dies_ok{$obj3->intra_dforces} "intra_dforces dies with 0 arg";
dies_ok{$obj3->intra_dforces(0)} "intra_dforces dies with 1 arg";
dies_ok{$obj3->intra_dforces(0,1,3)} "intra_dforces dies with 3 arg";

$obj3->t(9);
$obj1->set_charges(9,8);
$obj1->t(0);
dies_ok{$obj3->inter_dcoords} "inter_dcoords dies with 0 arg";
warning_is { $obj3->inter_dcoords($obj1) }
"comparing objects with different times",
  "carp warning about obj1 and obj2 distance with different t";

dies_ok{$obj3->inter_dforces} "inter_dforces dies with 0 arg";
warning_is { $obj3->inter_dforces($obj1) }
"comparing objects with different times",
  "carp warning about obj1 and obj2 distance with different t";

dies_ok{$obj3->inter_dcharges} "inter_dcharges dies with 0 arg";
warning_is { $obj3->inter_dcharges($obj1) }
"comparing objects with different times",
  "carp warning about obj1 and obj2 distance with different t";

warning_is { $obj3->charge(0) }
"charge> takes no arguments. returns get_charges(t)",
  "charge method get_charge(t) not setter";

warning_is { $obj3->xyz(V(0,0,0)) }
"xyz> takes no arguments. returns get_coords(t)",
  "xyz method get_coords(t) not setter";

warning_is { $obj3->force(V(0,0,0)) }
"force> takes no arguments. returns get_forces(t)",
  "force method get_forces(t) not setter";

dies_ok{$obj3->copy_ref_from_t1_through_t2} "copy_ref_from_t1_through_t2 dies with 0 arg";
dies_ok{$obj3->copy_ref_from_t1_through_t2('charges')} "copy_ref_from_t1_through_t2 dies with 1 arg";
dies_ok{$obj3->copy_ref_from_t1_through_t2('charges',0)} "copy_ref_from_t1_through_t2 dies with 2 arg";

$obj1->t(9);

cmp_ok( abs($obj3->inter_dcharges($obj1) + 1),'<', 1E-7, 'inter_dcharges'); 
$obj1->set_forces(9,V(10,10,10));
cmp_ok( abs($obj3->inter_dforces($obj1) - V(1,1,1)),'<', 1E-7, 'inter_dforces'); 

for my $t ( 0 .. $obj3->count_coords - 1 ) {
    $obj3->t($t);
    is(
        $obj3->charge,
        $obj3->get_charges($t),
        "obj->charge returns get_charges($t)"
    );
    is_deeply(
        $obj3->xyz,
        $obj3->get_coords($t),
        "obj->xyz    returns get_coords($t)"
    );
    is_deeply(
        $obj3->force,
        $obj3->get_forces($t),
        "obj->force  returns get_forces($t)"
    );
}

is_deeply($obj3->mean_coords, V(4.5,4.5,4.5), "average coordinates");
is($obj3->msd_coords, 24.75, "mean square deviation forces");
is_deeply($obj3->mean_forces, V(4.5,4.5,4.5), "average coordinates");
is($obj3->msd_forces, 24.75, "mean square deviation forces");
is($obj3->mean_charges, 4.5, "average charges");
is($obj3->msd_charges, 8.25, "mean square deviation charges");



my $obj4;
lives_ok {
    $obj4 = HackaMol::Atom->new(Z=>1, t => 0, coords => [ V(1,2,3.0) ]  );
}
'Test creation of an obj1';

$obj4->copy_ref_from_t1_through_t2('coords', 0, 10);

cmp_ok(refaddr($obj4->get_coords(0)) , '==' , refaddr($obj4->get_coords($_)),
"copy_ref_from_t1_through_t2(coords, 0 , 10): $_") foreach 1 .. 10;

my @objs = ($obj1,$obj2,$obj3,$obj4);
$_->t(0) foreach (@objs);

$_->clear_coords  foreach @objs;
$_->clear_forces  foreach @objs;
$_->clear_charges foreach @objs;
$obj1->push_coords(V(1,1,0));
$obj2->push_coords(V(1,0,0));
$obj3->push_coords(V(0,0,0));
$obj4->push_coords(V(0,-1,0));

dies_ok{$obj1->distance} "distance dies with 0 arg";
dies_ok{$obj1->angle_deg} "angle_deg dies with 0 arg";
dies_ok{$obj1->angle_deg($obj1)} "angle_deg dies with 1 arg";
dies_ok{$obj1->dihedral_deg} "dihedral dies with 0 arg";
dies_ok{$obj1->dihedral_deg($obj2)} "dihedral dies with 1 arg";
dies_ok{$obj1->dihedral_deg($obj2,$obj3)} "dihedral dies with 2 arg";
dies_ok{$obj1->dihedral_deg($obj2,$obj3,$obj4,$obj1)} "dihedral dies with 4 arg";
cmp_ok(abs(1.0 - $obj1->distance($obj2)),'<',1E-7, "distance " );
cmp_ok(abs(90.0 - $obj2->angle_deg($obj1,$obj3)),'<',1E-7, "angle" );
cmp_ok(abs(180.0 - $obj1->dihedral_deg($obj2,$obj3,$obj4)),'<',1E-7, "dihedral" );

#test cloning of coordinates and forces

$obj4->push_coords(V(1,-1,0));
foreach my $t (0,1){
  $obj4->t($t);
  my $mvrc1= $obj4->clone_xyz;
  my $mvrc2= $obj4->clone_xyz($t);
  is_deeply($mvrc1,$obj4->get_coords($t), "clone_xyz test noarg t$t");
  is_deeply($mvrc2,$mvrc1, "clone_xyz test arg t$t");
  cmp_ok(refaddr($mvrc1),'!=',refaddr($obj4->get_coords($t)), "refs not same");
  cmp_ok(refaddr($mvrc1),'!=',refaddr($mvrc2), "refs not same");
}

$obj4->push_forces(V(1,1,0));
$obj4->push_forces(V(-1,1,0));

foreach my $t (0,1){
  $obj4->t($t);
  my $mvrc1= $obj4->clone_force;
  my $mvrc2= $obj4->clone_force($t);
  is_deeply($mvrc1,$obj4->get_forces($t), "clone_force test noarg t$t");
  is_deeply($mvrc2,$mvrc1, "clone_force test arg t$t");
  cmp_ok(refaddr($mvrc1),'!=',refaddr($obj4->get_forces($t)), "refs not same");
  cmp_ok(refaddr($mvrc1),'!=',refaddr($mvrc2), "refs not same");
};

$obj1->set_coords(0, V(1,0,0));
cmp_ok(abs(0.0 - $obj2->angle_deg($obj1,$obj3)),'<',1E-7, "return zero if a vector length in angle calc is zero" );
$obj1->set_coords(0, V(1,1,0));
$obj3->set_coords(0, V(1,0,0));
cmp_ok(abs(0.0 - $obj2->angle_deg($obj1,$obj3)),'<',1E-7, "return zero if a vector length in angle calc is zero" );
$obj1->set_coords(0, V(1,1,0));


done_testing();

