#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Warn;
use Test::Moose;
use Math::Vector::Real;
use HackaMol::Atom;
use HackaMol::Bond;


my @attributes = qw(
atoms bond_order
);
my @methods = qw(
bond_length bond_vector 
);

my @roles = qw(HackaMol::Roles::AtomGroupRole);

map has_attribute_ok( 'HackaMol::Bond', $_ ), @attributes;
map can_ok( 'HackaMol::Bond', $_ ), @methods;
map does_ok( 'HackaMol::Bond', $_ ), @roles;

my $atom1 = HackaMol::Atom->new(
    name    => 'Hg',
    charges => [2,2,2,2,2,2,2,2,2,2],
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
    symbol  => 'HG'
);

my $atom2 = HackaMol::Atom->new(
    name    => 'C1',
    charges => [-1,-1,-1,-1,-1,-1,-1,-1,-1,-1],
    coords  => [ 
                V( 0.0, 0.0, 0.0 ), 
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
    Z       => 6
);

my $atom3 = HackaMol::Atom->new(
    name    => 'C2',
    charges => [-1,-1,-1,-1,-1,-1,-1,-1,-1,-1],
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


my $bond1 = HackaMol::Bond->new(atoms => [$atom1,$atom2]);
my $bond2 = HackaMol::Bond->new(atoms => [$atom1,$atom3]);

foreach my $t (0 .. 9){
  $bond1->gt($t);
  cmp_ok(abs($bond1->bond_length-$t),'<', 1E-7, "t dependent bond length: $t");
  is_deeply($bond1->bond_vector, V($t,0,0), "t dependent bond vector: V ($t, 0, 0)");
}

$atom1->set_coords($_, V(0,0,0)) foreach 0 .. 9;

foreach my $t (0 .. 9){
  $bond1->gt($t);
  cmp_ok(abs($bond1->bond_length - sqrt(2)*$t),'<', 0.000001, "t dependent bond length $t");
  is_deeply($bond1->bond_vector, V($t,$t,0), "t dependent bond vector: V ($t, 0, 0)");
}

is($bond1->bond_order, 1, "bond order default");
$bond1->bond_order(1.5);

is($bond1->bond_order, 1.5, "bond order set to num");


$bond1->bond_length_eq($bond1->bond_length - 0.5);

$bond1->bond_fc(0.0);
cmp_ok (abs(0.0-$bond1->bond_energy),'<',1E-7, ' force constant 0 returns energy of 0') ;
$bond1->bond_fc(1.0);
cmp_ok (abs(0.25-$bond1->bond_energy),'<',1E-7, 'simple bond energy test') ;

$bond1->bond_efunc(
                          sub { 
                               my $b = shift; 
                               my $sum = 0;
                               $sum += $_*$b->bond_length foreach (@_);
                               return($sum);
                              }
                        );

cmp_ok ( 
        abs($bond1->bond_energy(1,2,3,4) - 10*$bond1->bond_length), 
        '<', 1E-7, 'new nonsense energy'
       );

done_testing();

