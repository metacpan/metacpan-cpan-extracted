#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Moose;
use Math::Vector::Real;
use HackaMol::Atom;
use HackaMol::Angle;

my @attributes = qw(
  atoms ang_eq ang_fc
);
my @methods = qw(
  ang_deg ang_rad ang_normvec angle_energy clear_ang_eq clear_ang_fc has_ang_eq has_ang_fc
);

my @roles = qw(HackaMol::Roles::AtomGroupRole);

map has_attribute_ok( 'HackaMol::Angle', $_ ), @attributes;
map can_ok( 'HackaMol::Angle', $_ ), @methods;
map does_ok( 'HackaMol::Angle', $_ ), @roles;

my $atom1 = HackaMol::Atom->new(
    name    => 'Hg',
    charges => [ 2, 2, 2, 2, 2, 2, 2, 2, 2, 2 ],
    coords  => [
        V( 0.0, 0.0, 0.0 ),
        V( 0.0, 1.0, 0.0 ),
        V( 0.0, 2.0, 0.0 ),
        V( 0.0, 3.0, 0.0 ),
        V( 0.0, 4.0, 0.0 ),
        V( 0.0, 5.0, 0.0 ),
        V( 0.0, 6.0, 0.0 ),
        V( 0.0, 7.0, 0.0 ),
        V( 0.0, 8.0, 0.0 ),
        V( 0.0, 9.0, 0.0 ),
    ],
    Z => 80
);
my $atom2 = HackaMol::Atom->new(
    name    => 'C1',
    charges => [ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    coords  => [
        V( 1.0, 0.0, 0.0 ),
        V( 1.0, 1.0, 0.0 ),
        V( 2.0, 2.0, 0.0 ),
        V( 3.0, 3.0, 0.0 ),
        V( 4.0, 4.0, 0.0 ),
        V( 5.0, 5.0, 0.0 ),
        V( 6.0, 6.0, 0.0 ),
        V( 7.0, 7.0, 0.0 ),
        V( 8.0, 8.0, 0.0 ),
        V( 9.0, 9.0, 0.0 ),
    ],
    Z => 6,
);

my $atom3 = HackaMol::Atom->new(
    name    => 'C3',
    charges => [ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    coords  => [
        V( -1.0, 0.0, 0.0 ),
        V( -1.0, 1.0, 0.0 ),
        V( -2.0, 2.0, 0.0 ),
        V( -3.0, 3.0, 0.0 ),
        V( -4.0, 4.0, 0.0 ),
        V( -5.0, 5.0, 0.0 ),
        V( -6.0, 6.0, 0.0 ),
        V( -7.0, 7.0, 0.0 ),
        V( -8.0, 8.0, 0.0 ),
        V( -9.0, 9.0, 0.0 ),
    ],
    Z => 6,
);

my $atom4 = HackaMol::Atom->new(
    name    => 'C2',
    charges => [ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    coords  => [
        V( 0.0, 0.0, 1.0 ),
        V( 0.0, 1.0, 1.0 ),
        V( 0.0, 2.0, 2.0 ),
        V( 0.0, 3.0, 3.0 ),
        V( 0.0, 4.0, 4.0 ),
        V( 0.0, 5.0, 5.0 ),
        V( 0.0, 6.0, 6.0 ),
        V( 0.0, 7.0, 7.0 ),
        V( 0.0, 8.0, 8.0 ),
        V( 0.0, 9.0, 9.0 ),
    ],
    Z => 6,
);

my $atom5 = HackaMol::Atom->new(
    name    => 'C3',
    charges => [ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    coords  => [
        V( 0.0,  0.0, 0.0 ),
        V( -1.0, 1.0, 1.0 ),
        V( -2.0, 2.0, 2.0 ),
        V( -3.0, 3.0, 3.0 ),
        V( -4.0, 4.0, 4.0 ),
        V( -5.0, 5.0, 5.0 ),
        V( -6.0, 6.0, 6.0 ),
        V( -7.0, 7.0, 7.0 ),
        V( -8.0, 8.0, 8.0 ),
        V( -9.0, 9.0, 9.0 ),
    ],
    Z => 6,
);

my $angle1 = HackaMol::Angle->new( atoms => [ $atom2, $atom1, $atom3 ] );
my $angle2 = HackaMol::Angle->new( atoms => [ $atom2, $atom1, $atom4 ] );
my $angle3 = HackaMol::Angle->new( atoms => [ $atom2, $atom1, $atom5 ] );
my $angle4 = HackaMol::Angle->new( atoms => [ $atom2, $atom1, $atom2 ] );

foreach my $t ( 0 .. 9 ) {
    $angle1->do_forall( 't', $t );
    $angle2->do_forall( 't', $t );
    cmp_ok( abs( $angle1->ang_deg - 180 ),
        '<', 1E-7, "antiparallel t dependent angle_deg: 180" );
    cmp_ok( abs( 3.14159265359 - $angle1->ang_rad ),
        '<', 1E-7, "antiparallel t dependent angle_rad: pi" );
    cmp_ok( abs( $angle2->ang_deg - 90 ), '<', 1E-7, "xz t dependent ang: 90" );
    is_deeply(
        $angle1->ang_normvec,
        V( 0, 0, 0 ),
        "antiparallel t dependent ang_normvec: V (0, 0, 0)"
    );
    is_deeply(
        $angle4->ang_normvec,
        V( 0, 0, 0 ),
        "parallel t dependent ang_normvec: V (0, 0, 0)"
    );
    is_deeply( $angle1->COM, $atom1->get_coords($t), "antiparallel COM at Hg" );
    is_deeply(
        $angle2->ang_normvec,
        V( 0, -1, 0 ),
        "xz t dependent ang_normvec: V (0, 1, 0)"
    );
}

$angle1->ang_eq( $angle1->ang_deg - 0.5 );

$angle1->ang_fc(0.0);
cmp_ok( abs( 0.0 - $angle1->angle_energy ),
    '<', 1E-7, 'no force constant -> energy 0' );

$angle1->ang_fc(1.0);
cmp_ok( abs( 0.25 - $angle1->angle_energy ),
    '<', 1E-7, 'simple angle energy test' );

$angle1->angle_efunc(
    sub {
        my $a   = shift;
        my $sum = 0;
        $sum += $_ * $a->ang_deg foreach (@_);
        return ($sum);
    }
);

cmp_ok( abs( $angle1->angle_energy( 1, 2, 3, 4 ) - 10 * $angle1->ang_deg ),
    '<', 1E-7, 'new nonsense energy' );

#bisector test
{
    my $angle = HackaMol::Angle->new(
        atoms => [
            HackaMol::Atom->new( Z => 1, coords => [ V( 1, 0, 0 ) ] ),
            HackaMol::Atom->new( Z => 1, coords => [ V( 0, 0, 0 ) ] ),
            HackaMol::Atom->new( Z => 1, coords => [ V( 0, 1, 0 ) ] ),
        ],
    );

    is_deeply( $angle->ang_normvec, V( 0, 0, 1 ), "ang_normvec: V (0, 0, 1)" );
    is_deeply( $angle->bisector, V( 1, 1, 0 )->versor, "bisector simple test" );
    my @atoms = $angle->all_atoms;
    my $atom = HackaMol::Atom->new( Z => 1, coords => [ $angle->bisector ] );
    my $ang1 = sprintf( "%10.7f", $atoms[1]->angle_deg( $atoms[0], $atom ) ); 
    my $ang2 = sprintf( "%10.7f", $atoms[1]->angle_deg( $atoms[2], $atom ) ); 

    cmp_ok(
        sprintf( "%10.7f", $ang1 ),
        '==', sprintf( "%10.7f", $ang2 ),
        "test the angle to bisecting vector test"
    );

    $atoms[2]->set_coords( 0, V( 1, 0, 0 ) );
    is_deeply( $angle->bisector, V( 0, 0, 0 ),
        "bisector simple parallel test" );
    $atoms[2]->set_coords( 0, V( -1, 0, 0 ) );
    is_deeply(
        $angle->bisector,
        V( 0, 0, 0 ),
        "bisector simple antiparallel test"
    );
    $atoms[2]->set_coords( 0, V( 0, 0, 0 ) );
    is_deeply(
        $angle->bisector,
        V( 0, 0, 0 ),
        "bisector simple zeroes"
    );

}

done_testing();
